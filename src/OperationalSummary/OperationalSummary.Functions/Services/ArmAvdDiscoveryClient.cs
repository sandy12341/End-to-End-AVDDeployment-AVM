using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class ArmAvdDiscoveryClient : IAvdDiscoveryClient
{
    private const string ManagementScope = "https://management.azure.com/.default";
    private const string DesktopVirtualizationApiVersion = "2024-04-03";
    private const string AuthorizationApiVersion = "2022-04-01";
    private const string DesktopVirtualizationUserRoleId = "1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63";

    private readonly HttpClient httpClient;
    private readonly TokenCredential credential;

    public ArmAvdDiscoveryClient()
        : this(new HttpClient(), new DefaultAzureCredential())
    {
    }

    public ArmAvdDiscoveryClient(HttpClient httpClient, TokenCredential credential)
    {
        this.httpClient = httpClient;
        this.credential = credential;
    }

    public async Task<DiscoverySnapshot> DiscoverAsync(OperationalSummaryRequest request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var applicationGroupIds = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var roleAssignments = new List<RoleAssignmentEvidence>();

        var hostPool = ResourceIdParts.TryParse(request.HostPoolResourceId);
        if (hostPool is null)
        {
            return new DiscoverySnapshot(
                request.ApplicationGroupResourceIds,
                Array.Empty<RoleAssignmentEvidence>(),
                WasAuthorized: false,
                Errors: new[] { $"Host pool resource ID is not valid: {request.HostPoolResourceId}" });
        }

        var hostPoolState = await CheckResourceAsync(request.HostPoolResourceId, DesktopVirtualizationApiVersion, cancellationToken);
        if (hostPoolState == ResourceReadState.NotFound)
        {
            errors.Add($"Host pool was not found: {request.HostPoolResourceId}");
            return new DiscoverySnapshot(request.ApplicationGroupResourceIds, Array.Empty<RoleAssignmentEvidence>(), false, errors);
        }

        if (hostPoolState == ResourceReadState.NotAuthorized)
        {
            errors.Add($"Collector identity is not authorized to read host pool: {request.HostPoolResourceId}");
            return new DiscoverySnapshot(request.ApplicationGroupResourceIds, Array.Empty<RoleAssignmentEvidence>(), false, errors);
        }

        foreach (var applicationGroupId in request.ApplicationGroupResourceIds)
        {
            var state = await CheckResourceAsync(applicationGroupId, DesktopVirtualizationApiVersion, cancellationToken);
            if (state == ResourceReadState.Found)
            {
                applicationGroupIds.Add(NormalizeScope(applicationGroupId));
            }
            else if (state == ResourceReadState.NotFound)
            {
                errors.Add($"Application group was not found: {applicationGroupId}");
            }
            else
            {
                errors.Add($"Collector identity is not authorized to read application group: {applicationGroupId}");
            }
        }

        if (applicationGroupIds.Count == 0)
        {
            foreach (var relatedApplicationGroupId in await DiscoverRelatedApplicationGroupsAsync(hostPool, request.HostPoolResourceId, errors, cancellationToken))
            {
                applicationGroupIds.Add(relatedApplicationGroupId);
            }
        }

        if (applicationGroupIds.Count == 0)
        {
            errors.Add("No related application groups could be validated or discovered for the host pool.");
            return new DiscoverySnapshot(Array.Empty<string>(), Array.Empty<RoleAssignmentEvidence>(), false, errors);
        }

        var roleScopes = BuildRoleAssignmentQueryScopes(hostPool, applicationGroupIds);
        var wasAuthorized = true;
        foreach (var scope in roleScopes)
        {
            var readResult = await ReadRoleAssignmentsAsync(scope, applicationGroupIds, cancellationToken);
            roleAssignments.AddRange(readResult.Assignments);

            if (!readResult.WasAuthorized)
            {
                wasAuthorized = false;
                errors.Add($"Collector identity is not authorized to read role assignments at scope: {scope}");
            }

            errors.AddRange(readResult.Errors);
        }

        return new DiscoverySnapshot(
            applicationGroupIds.Order(StringComparer.OrdinalIgnoreCase).ToArray(),
            roleAssignments.DistinctBy(assignment => $"{assignment.Scope}|{assignment.PrincipalId}|{assignment.RoleDefinitionId}").ToArray(),
            wasAuthorized,
                Errors: errors);
    }

    private async Task<ResourceReadState> CheckResourceAsync(string resourceId, string apiVersion, CancellationToken cancellationToken)
    {
        using var response = await SendArmAsync($"{NormalizeScope(resourceId)}?api-version={apiVersion}", cancellationToken);

        return response.StatusCode switch
        {
            HttpStatusCode.OK => ResourceReadState.Found,
            HttpStatusCode.NotFound => ResourceReadState.NotFound,
            HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized => ResourceReadState.NotAuthorized,
            _ => response.IsSuccessStatusCode ? ResourceReadState.Found : ResourceReadState.NotAuthorized
        };
    }

    private async Task<IReadOnlyList<string>> DiscoverRelatedApplicationGroupsAsync(
        ResourceIdParts hostPool,
        string hostPoolResourceId,
        List<string> errors,
        CancellationToken cancellationToken)
    {
        var requestPath = $"/subscriptions/{hostPool.SubscriptionId}/resourceGroups/{hostPool.ResourceGroupName}/providers/Microsoft.DesktopVirtualization/applicationGroups?api-version={DesktopVirtualizationApiVersion}";
        var relatedApplicationGroups = new List<string>();
        var nextLink = requestPath;

        while (!string.IsNullOrWhiteSpace(nextLink))
        {
            using var response = await SendArmAsync(nextLink, cancellationToken);
            if (response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized)
            {
                errors.Add($"Collector identity is not authorized to list application groups in resource group: {hostPool.ResourceGroupName}");
                break;
            }

            if (!response.IsSuccessStatusCode)
            {
                errors.Add($"Unable to list application groups in resource group {hostPool.ResourceGroupName}. ARM returned {(int)response.StatusCode}.");
                break;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            if (document.RootElement.TryGetProperty("value", out var values))
            {
                foreach (var value in values.EnumerateArray())
                {
                    if (!TryGetString(value, "id", out var id) || !value.TryGetProperty("properties", out var properties))
                    {
                        continue;
                    }

                    if (TryGetString(properties, "hostPoolArmPath", out var appGroupHostPoolPath) && ScopesEqual(appGroupHostPoolPath, hostPoolResourceId))
                    {
                        relatedApplicationGroups.Add(NormalizeScope(id));
                    }
                }
            }

            nextLink = TryGetString(document.RootElement, "nextLink", out var parsedNextLink) ? parsedNextLink : string.Empty;
        }

        return relatedApplicationGroups;
    }

    private async Task<RoleAssignmentReadResult> ReadRoleAssignmentsAsync(
        string scope,
        IReadOnlyCollection<string> applicationGroupIds,
        CancellationToken cancellationToken)
    {
        var assignments = new List<RoleAssignmentEvidence>();
        var errors = new List<string>();
        var nextLink = $"{NormalizeScope(scope)}/providers/Microsoft.Authorization/roleAssignments?api-version={AuthorizationApiVersion}";

        while (!string.IsNullOrWhiteSpace(nextLink))
        {
            using var response = await SendArmAsync(nextLink, cancellationToken);
            if (response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized)
            {
                return new RoleAssignmentReadResult(assignments, WasAuthorized: false, errors);
            }

            if (!response.IsSuccessStatusCode)
            {
                errors.Add($"Unable to read role assignments at scope {scope}. ARM returned {(int)response.StatusCode}.");
                break;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            if (document.RootElement.TryGetProperty("value", out var values))
            {
                foreach (var assignment in values.EnumerateArray())
                {
                    if (TryParseRoleAssignment(assignment, applicationGroupIds, out var evidence))
                    {
                        assignments.Add(evidence);
                    }
                }
            }

            nextLink = TryGetString(document.RootElement, "nextLink", out var parsedNextLink) ? parsedNextLink : string.Empty;
        }

        return new RoleAssignmentReadResult(assignments, WasAuthorized: true, errors);
    }

    private static bool TryParseRoleAssignment(
        JsonElement assignment,
        IReadOnlyCollection<string> applicationGroupIds,
        out RoleAssignmentEvidence evidence)
    {
        evidence = default!;
        if (!assignment.TryGetProperty("properties", out var properties) ||
            !TryGetString(properties, "scope", out var scope) ||
            !TryGetString(properties, "principalId", out var principalId) ||
            !TryGetString(properties, "roleDefinitionId", out var roleDefinitionId))
        {
            return false;
        }

        if (!roleDefinitionId.Contains(DesktopVirtualizationUserRoleId, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (!applicationGroupIds.Any(applicationGroupId => ScopesEqual(scope, applicationGroupId) || IsInheritedScope(applicationGroupId, scope)))
        {
            return false;
        }

        var principalType = TryGetString(properties, "principalType", out var parsedPrincipalType)
            ? parsedPrincipalType
            : "Unknown";

        evidence = new RoleAssignmentEvidence(NormalizeScope(scope), principalId, principalType, roleDefinitionId);
        return true;
    }

    private static IReadOnlyList<string> BuildRoleAssignmentQueryScopes(ResourceIdParts hostPool, IReadOnlyCollection<string> applicationGroupIds)
    {
        var scopes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            $"/subscriptions/{hostPool.SubscriptionId}",
            $"/subscriptions/{hostPool.SubscriptionId}/resourceGroups/{hostPool.ResourceGroupName}"
        };

        foreach (var applicationGroupId in applicationGroupIds)
        {
            scopes.Add(applicationGroupId);
        }

        return scopes.ToArray();
    }

    private async Task<HttpResponseMessage> SendArmAsync(string pathOrUrl, CancellationToken cancellationToken)
    {
        var accessToken = await credential.GetTokenAsync(new TokenRequestContext(new[] { ManagementScope }), cancellationToken);
        var uri = pathOrUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
            ? new Uri(pathOrUrl)
            : new Uri($"https://management.azure.com{pathOrUrl}");
        var request = new HttpRequestMessage(HttpMethod.Get, uri);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken.Token);

        return await httpClient.SendAsync(request, cancellationToken);
    }

    private static bool TryGetString(JsonElement element, string propertyName, out string value)
    {
        value = string.Empty;
        if (!element.TryGetProperty(propertyName, out var property) || property.ValueKind != JsonValueKind.String)
        {
            return false;
        }

        value = property.GetString() ?? string.Empty;
        return !string.IsNullOrWhiteSpace(value);
    }

    private static bool ScopesEqual(string left, string right) =>
        string.Equals(NormalizeScope(left), NormalizeScope(right), StringComparison.OrdinalIgnoreCase);

    private static bool IsInheritedScope(string resourceId, string assignmentScope)
    {
        var normalizedResourceId = NormalizeScope(resourceId);
        var normalizedScope = NormalizeScope(assignmentScope);

        return normalizedResourceId.StartsWith(normalizedScope + "/", StringComparison.OrdinalIgnoreCase);
    }

    private static string NormalizeScope(string scope) => scope.Trim().TrimEnd('/');

    private enum ResourceReadState
    {
        Found,
        NotFound,
        NotAuthorized
    }

    private sealed record RoleAssignmentReadResult(
        IReadOnlyList<RoleAssignmentEvidence> Assignments,
        bool WasAuthorized,
        IReadOnlyList<string> Errors);

    private sealed record ResourceIdParts(string SubscriptionId, string ResourceGroupName)
    {
        public static ResourceIdParts? TryParse(string resourceId)
        {
            var segments = resourceId.Trim('/').Split('/', StringSplitOptions.RemoveEmptyEntries);
            var subscriptionIndex = Array.FindIndex(segments, segment => string.Equals(segment, "subscriptions", StringComparison.OrdinalIgnoreCase));
            var resourceGroupIndex = Array.FindIndex(segments, segment => string.Equals(segment, "resourceGroups", StringComparison.OrdinalIgnoreCase));

            if (subscriptionIndex < 0 || subscriptionIndex + 1 >= segments.Length || resourceGroupIndex < 0 || resourceGroupIndex + 1 >= segments.Length)
            {
                return null;
            }

            return new ResourceIdParts(segments[subscriptionIndex + 1], segments[resourceGroupIndex + 1]);
        }
    }
}
