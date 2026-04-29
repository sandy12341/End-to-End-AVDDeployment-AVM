using System.Net;
using Azure.Core;
using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class GraphGroupPrincipalValidatorTests
{
    [Fact]
    public async Task ValidateAsyncMapsSuccessfulGroupReadToExists()
    {
        var validator = CreateValidator(Json(HttpStatusCode.OK, "{ \"id\": \"group1\", \"displayName\": \"AVD Users\" }"));

        var evidence = await validator.ValidateAsync(new[]
        {
            new RoleAssignmentEvidence("scope1", "group1", "Group", "role1")
        }, CancellationToken.None);

        var result = Assert.Single(evidence);
        Assert.Equal("Exists", result.ValidationState);
        Assert.Equal("AVD Users", result.DisplayName);
    }

    [Fact]
    public async Task ValidateAsyncMapsNotFoundToNotFound()
    {
        var validator = CreateValidator(Json(HttpStatusCode.NotFound, "{}"));

        var evidence = await validator.ValidateAsync(new[]
        {
            new RoleAssignmentEvidence("scope1", "group1", "Group", "role1")
        }, CancellationToken.None);

        Assert.Equal("NotFound", Assert.Single(evidence).ValidationState);
    }

    [Fact]
    public async Task ValidateAsyncMapsForbiddenToNotReadable()
    {
        var validator = CreateValidator(Json(HttpStatusCode.Forbidden, "{}"));

        var evidence = await validator.ValidateAsync(new[]
        {
            new RoleAssignmentEvidence("scope1", "group1", "Group", "role1")
        }, CancellationToken.None);

        Assert.Equal("NotReadable", Assert.Single(evidence).ValidationState);
    }

    [Fact]
    public async Task ValidateAsyncOnlyValidatesDistinctGroupPrincipals()
    {
        var handler = new QueueMessageHandler(Json(HttpStatusCode.OK, "{ \"displayName\": \"AVD Users\" }"));
        var validator = new GraphGroupPrincipalValidator(new HttpClient(handler), new StaticTokenCredential());

        var evidence = await validator.ValidateAsync(new[]
        {
            new RoleAssignmentEvidence("scope1", "group1", "Group", "role1"),
            new RoleAssignmentEvidence("scope2", "GROUP1", "Group", "role1"),
            new RoleAssignmentEvidence("scope3", "user1", "User", "role1")
        }, CancellationToken.None);

        Assert.Single(evidence);
        Assert.Equal(0, handler.RemainingResponses);
    }

    private static GraphGroupPrincipalValidator CreateValidator(HttpResponseMessage response) =>
        new(new HttpClient(new QueueMessageHandler(response)), new StaticTokenCredential());

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

        public int RemainingResponses => responses.Count;

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (responses.Count == 0)
            {
                throw new InvalidOperationException($"No fake Graph response is queued for {request.RequestUri}.");
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