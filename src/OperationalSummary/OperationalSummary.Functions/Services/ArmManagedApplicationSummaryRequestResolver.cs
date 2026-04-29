using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class ArmManagedApplicationSummaryRequestResolver : IManagedApplicationSummaryRequestResolver
{
    private const string ManagementScope = "https://management.azure.com/.default";
    private const string ManagedApplicationApiVersion = "2021-07-01";

    private readonly HttpClient httpClient;
    private readonly TokenCredential credential;

    public ArmManagedApplicationSummaryRequestResolver()
        : this(new HttpClient(), new DefaultAzureCredential())
    {
    }

    public ArmManagedApplicationSummaryRequestResolver(HttpClient httpClient, TokenCredential credential)
    {
        this.httpClient = httpClient;
        this.credential = credential;
    }

    public async Task<OperationalSummaryRequest?> ResolveAsync(
        string managedApplicationResourceId,
        string? correlationId,
        CancellationToken cancellationToken)
    {
        var accessToken = await credential.GetTokenAsync(new TokenRequestContext(new[] { ManagementScope }), cancellationToken);
        var request = new HttpRequestMessage(
            HttpMethod.Get,
            new Uri($"https://management.azure.com{NormalizeResourceId(managedApplicationResourceId)}?api-version={ManagedApplicationApiVersion}"));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken.Token);

        using var response = await httpClient.SendAsync(request, cancellationToken);
        if (response.StatusCode == HttpStatusCode.NotFound || response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized)
        {
            return null;
        }

        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

        return TryCreateRequestFromManagedApplication(
            managedApplicationResourceId,
            document.RootElement,
            correlationId,
            out var summaryRequest)
            ? summaryRequest
            : null;
    }

    public static bool TryCreateRequestFromManagedApplication(
        string managedApplicationResourceId,
        JsonElement managedApplication,
        string? correlationId,
        out OperationalSummaryRequest? summaryRequest)
    {
        summaryRequest = null;
        if (!managedApplication.TryGetProperty("properties", out var properties) ||
            !properties.TryGetProperty("parameters", out var parameters))
        {
            return false;
        }

        var hostPoolResourceId = GetStringParameter(parameters, "hostPoolResourceId");
        if (string.IsNullOrWhiteSpace(hostPoolResourceId))
        {
            var subscriptionId = TryParseSubscriptionId(managedApplicationResourceId);
            var hostPoolResourceGroupName = GetStringParameter(parameters, "existingHostPoolResourceGroupName");
            var hostPoolName = GetStringParameter(parameters, "hostPoolName");
            if (!string.IsNullOrWhiteSpace(subscriptionId) &&
                !string.IsNullOrWhiteSpace(hostPoolResourceGroupName) &&
                !string.IsNullOrWhiteSpace(hostPoolName))
            {
                hostPoolResourceId = $"/subscriptions/{subscriptionId}/resourceGroups/{hostPoolResourceGroupName}/providers/Microsoft.DesktopVirtualization/hostPools/{hostPoolName}";
            }
        }

        if (string.IsNullOrWhiteSpace(hostPoolResourceId))
        {
            return false;
        }

        var applicationGroupIds = GetStringArrayParameter(parameters, "applicationGroupResourceIds")
            .Concat(GetStringArrayParameter(parameters, "brownfieldDetectedRelatedApplicationGroupIds"))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        var workspaceResourceId = GetStringParameter(parameters, "workspaceResourceId");
        if (string.IsNullOrWhiteSpace(workspaceResourceId))
        {
            var subscriptionId = TryParseSubscriptionId(hostPoolResourceId);
            var hostPoolResourceGroupName = GetStringParameter(parameters, "existingHostPoolResourceGroupName");
            var workspaceName = GetStringArrayParameter(parameters, "existingWorkspaceNames").FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(subscriptionId) &&
                !string.IsNullOrWhiteSpace(hostPoolResourceGroupName) &&
                !string.IsNullOrWhiteSpace(workspaceName))
            {
                workspaceResourceId = $"/subscriptions/{subscriptionId}/resourceGroups/{hostPoolResourceGroupName}/providers/Microsoft.DesktopVirtualization/workspaces/{workspaceName}";
            }
        }

        var reportName = GetStringParameter(parameters, "reportName");
        if (string.IsNullOrWhiteSpace(reportName) && managedApplication.TryGetProperty("name", out var nameElement) && nameElement.ValueKind == JsonValueKind.String)
        {
            reportName = $"managedapp-{nameElement.GetString()}";
        }

        summaryRequest = new OperationalSummaryRequest(
            HostPoolResourceId: hostPoolResourceId,
            ApplicationGroupResourceIds: applicationGroupIds,
            WorkspaceResourceId: string.IsNullOrWhiteSpace(workspaceResourceId) ? null : workspaceResourceId,
            ReportName: reportName,
            ManagedApplicationResourceId: NormalizeResourceId(managedApplicationResourceId),
            CorrelationId: correlationId);

        return true;
    }

    private static string? GetStringParameter(JsonElement parameters, string name)
    {
        if (!parameters.TryGetProperty(name, out var parameter))
        {
            return null;
        }

        var value = UnwrapParameterValue(parameter);
        return value.ValueKind == JsonValueKind.String ? value.GetString() : null;
    }

    private static IReadOnlyList<string> GetStringArrayParameter(JsonElement parameters, string name)
    {
        if (!parameters.TryGetProperty(name, out var parameter))
        {
            return Array.Empty<string>();
        }

        var value = UnwrapParameterValue(parameter);
        if (value.ValueKind != JsonValueKind.Array)
        {
            return Array.Empty<string>();
        }

        return value.EnumerateArray()
            .Where(item => item.ValueKind == JsonValueKind.String)
            .Select(item => item.GetString())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Select(item => item!)
            .ToArray();
    }

    private static JsonElement UnwrapParameterValue(JsonElement parameter)
    {
        if (parameter.ValueKind == JsonValueKind.Object && parameter.TryGetProperty("value", out var value))
        {
            return value;
        }

        return parameter;
    }

    private static string? TryParseSubscriptionId(string resourceId)
    {
        var segments = resourceId.Trim('/').Split('/', StringSplitOptions.RemoveEmptyEntries);
        for (var index = 0; index < segments.Length - 1; index++)
        {
            if (string.Equals(segments[index], "subscriptions", StringComparison.OrdinalIgnoreCase))
            {
                return segments[index + 1];
            }
        }

        return null;
    }

    private static string NormalizeResourceId(string resourceId) => resourceId.Trim().TrimEnd('/');
}