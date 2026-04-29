using System.Net;
using Azure.Core;
using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class ArmAvdDiscoveryClientTests
{
    private const string HostPoolId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1";
    private const string ApplicationGroupId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/applicationGroups/dag1";
    private const string DesktopVirtualizationUserRoleId = "/subscriptions/sub1/providers/Microsoft.Authorization/roleDefinitions/1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63";

    [Fact]
    public async Task DiscoverAsyncReadsDesktopVirtualizationUserAssignmentsOnly()
    {
        var handler = new QueueMessageHandler(
            Json(HttpStatusCode.OK, "{}"),
            Json(HttpStatusCode.OK, "{}"),
            Json(HttpStatusCode.OK, $$"""
            {
              "value": [
                {
                  "properties": {
                    "scope": "{{ApplicationGroupId}}",
                    "principalId": "group1",
                    "principalType": "Group",
                    "roleDefinitionId": "{{DesktopVirtualizationUserRoleId}}"
                  }
                },
                {
                  "properties": {
                    "scope": "{{ApplicationGroupId}}",
                    "principalId": "reader1",
                    "principalType": "Group",
                    "roleDefinitionId": "/subscriptions/sub1/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
                  }
                }
              ]
            }
            """),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"));
        var client = CreateClient(handler);

        var snapshot = await client.DiscoverAsync(new OperationalSummaryRequest(HostPoolId, new[] { ApplicationGroupId }), CancellationToken.None);

        Assert.True(snapshot.WasAuthorized);
        Assert.Single(snapshot.RoleAssignments);
        Assert.Equal("group1", snapshot.RoleAssignments.Single().PrincipalId);
    }

    [Fact]
    public async Task DiscoverAsyncCanDiscoverRelatedApplicationGroupsWhenNoneAreProvided()
    {
        var handler = new QueueMessageHandler(
            Json(HttpStatusCode.OK, "{}"),
            Json(HttpStatusCode.OK, $$"""
            {
              "value": [
                {
                  "id": "{{ApplicationGroupId}}",
                  "properties": {
                    "hostPoolArmPath": "{{HostPoolId}}"
                  }
                }
              ]
            }
            """),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"));
        var client = CreateClient(handler);

        var snapshot = await client.DiscoverAsync(new OperationalSummaryRequest(HostPoolId, Array.Empty<string>()), CancellationToken.None);

        Assert.True(snapshot.WasAuthorized);
        Assert.Equal(ApplicationGroupId, snapshot.ApplicationGroupResourceIds.Single(), ignoreCase: true);
    }

    [Fact]
    public async Task DiscoverAsyncMarksSnapshotNotAuthorizedWhenRoleAssignmentsCannotBeRead()
    {
        var handler = new QueueMessageHandler(
            Json(HttpStatusCode.OK, "{}"),
            Json(HttpStatusCode.OK, "{}"),
            Json(HttpStatusCode.Forbidden, "{}"),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"),
            Json(HttpStatusCode.OK, "{ \"value\": [] }"));
        var client = CreateClient(handler);

        var snapshot = await client.DiscoverAsync(new OperationalSummaryRequest(HostPoolId, new[] { ApplicationGroupId }), CancellationToken.None);

        Assert.False(snapshot.WasAuthorized);
        Assert.Contains(snapshot.Errors, error => error.Contains("not authorized", StringComparison.OrdinalIgnoreCase));
    }

    private static ArmAvdDiscoveryClient CreateClient(HttpMessageHandler handler) =>
        new(new HttpClient(handler), new StaticTokenCredential());

    private static HttpResponseMessage Json(HttpStatusCode statusCode, string content) =>
        new(statusCode)
        {
            Content = new StringContent(content)
        };

    private sealed class QueueMessageHandler : HttpMessageHandler
    {
        private readonly Queue<HttpResponseMessage> responses;

        public QueueMessageHandler(params HttpResponseMessage[] responses)
        {
            this.responses = new Queue<HttpResponseMessage>(responses);
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (responses.Count == 0)
            {
                throw new InvalidOperationException($"No fake ARM response is queued for {request.RequestUri}.");
            }

            return Task.FromResult(responses.Dequeue());
        }
    }

    private sealed class StaticTokenCredential : TokenCredential
    {
        public override AccessToken GetToken(TokenRequestContext requestContext, CancellationToken cancellationToken) =>
            new("token", DateTimeOffset.UtcNow.AddHours(1));

        public override ValueTask<AccessToken> GetTokenAsync(TokenRequestContext requestContext, CancellationToken cancellationToken) =>
            ValueTask.FromResult(GetToken(requestContext, cancellationToken));
    }
}