using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using Azure.Core;
using Azure.Identity;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class GraphGroupPrincipalValidator : IPrincipalValidator
{
    private const string GraphScope = "https://graph.microsoft.com/.default";

    private readonly HttpClient httpClient;
    private readonly TokenCredential credential;

    public GraphGroupPrincipalValidator()
        : this(new HttpClient(), new DefaultAzureCredential())
    {
    }

    public GraphGroupPrincipalValidator(HttpClient httpClient, TokenCredential credential)
    {
        this.httpClient = httpClient;
        this.credential = credential;
    }

    public async Task<IReadOnlyList<PrincipalValidationEvidence>> ValidateAsync(
        IReadOnlyList<RoleAssignmentEvidence> roleAssignments,
        CancellationToken cancellationToken)
    {
        var groupPrincipalIds = roleAssignments
            .Where(assignment => string.Equals(assignment.PrincipalType, "Group", StringComparison.OrdinalIgnoreCase))
            .Select(assignment => assignment.PrincipalId)
            .Where(principalId => !string.IsNullOrWhiteSpace(principalId))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Order(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        var results = new List<PrincipalValidationEvidence>();
        foreach (var principalId in groupPrincipalIds)
        {
            results.Add(await ValidateGroupAsync(principalId, cancellationToken));
        }

        return results;
    }

    private async Task<PrincipalValidationEvidence> ValidateGroupAsync(string principalId, CancellationToken cancellationToken)
    {
        HttpResponseMessage response;
        try
        {
            response = await SendGraphAsync($"https://graph.microsoft.com/v1.0/groups/{principalId}?$select=id,displayName", cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            return new PrincipalValidationEvidence(
                principalId,
                "Group",
                "NotEvaluated",
                null,
                $"Microsoft Graph validation failed before a response was received: {ex.Message}");
        }

        using (response)
        {
            if (response.StatusCode == HttpStatusCode.NotFound)
            {
                return new PrincipalValidationEvidence(
                    principalId,
                    "Group",
                    "NotFound",
                    null,
                    "Microsoft Graph did not find this assigned group principal.");
            }

            if (response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.Unauthorized)
            {
                return new PrincipalValidationEvidence(
                    principalId,
                    "Group",
                    "NotReadable",
                    null,
                    "Collector identity is not authorized to read group objects in Microsoft Graph.");
            }

            if (!response.IsSuccessStatusCode)
            {
                return new PrincipalValidationEvidence(
                    principalId,
                    "Group",
                    "NotEvaluated",
                    null,
                    $"Microsoft Graph returned {(int)response.StatusCode} while validating this group principal.");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var displayName = document.RootElement.TryGetProperty("displayName", out var displayNameElement) && displayNameElement.ValueKind == JsonValueKind.String
                ? displayNameElement.GetString()
                : null;

            return new PrincipalValidationEvidence(
                principalId,
                "Group",
                "Exists",
                displayName,
                null);
        }
    }

    private async Task<HttpResponseMessage> SendGraphAsync(string url, CancellationToken cancellationToken)
    {
        var accessToken = await credential.GetTokenAsync(new TokenRequestContext(new[] { GraphScope }), cancellationToken);
        var request = new HttpRequestMessage(HttpMethod.Get, new Uri(url));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken.Token);

        return await httpClient.SendAsync(request, cancellationToken);
    }
}