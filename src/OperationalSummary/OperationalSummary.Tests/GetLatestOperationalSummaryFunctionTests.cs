using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using OperationalSummary.Functions;
using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class GetLatestOperationalSummaryFunctionTests
{
    private const string HostPoolResourceId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1";

    [Fact]
    public async Task RunRequiresHostPoolResourceId()
    {
        var function = new GetLatestOperationalSummaryFunction(new FakeManifestReader(null));
        var context = new DefaultHttpContext();

        var result = await function.Run(context.Request, CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
    }

    [Fact]
    public async Task RunReturnsNotFoundWhenNoLatestReportExists()
    {
        var function = new GetLatestOperationalSummaryFunction(new FakeManifestReader(null));
        var context = CreateRequestContext();

        var result = await function.Run(context.Request, CancellationToken.None);

        Assert.IsType<NotFoundObjectResult>(result);
    }

    [Fact]
    public async Task RunReturnsLatestManifest()
    {
        var manifest = new OperationalSummaryReportManifest(
            SchemaVersion: "2026-04-report-manifest-1",
            HostPoolResourceId: HostPoolResourceId,
            WorkspaceResourceId: null,
            ManagedApplicationResourceId: null,
            RunId: "run-1",
            GeneratedAt: DateTimeOffset.UtcNow,
            OverallStatus: "Healthy",
            DiscoveryConfidence: "Authoritative",
            ReportArtifacts: new[] { new ReportArtifact("Html", "text/html", "summary.html", null, null) });
        var function = new GetLatestOperationalSummaryFunction(new FakeManifestReader(manifest));
        var context = CreateRequestContext();

        var result = await function.Run(context.Request, CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result);
        Assert.Same(manifest, ok.Value);
    }

    private static DefaultHttpContext CreateRequestContext()
    {
        var context = new DefaultHttpContext();
        context.Request.QueryString = QueryString.Create("hostPoolResourceId", HostPoolResourceId);
        return context;
    }

    private sealed class FakeManifestReader : IReportManifestReader
    {
        private readonly OperationalSummaryReportManifest? manifest;

        public FakeManifestReader(OperationalSummaryReportManifest? manifest)
        {
            this.manifest = manifest;
        }

        public Task<OperationalSummaryReportManifest?> GetLatestAsync(string hostPoolResourceId, CancellationToken cancellationToken) =>
            Task.FromResult(manifest);
    }
}