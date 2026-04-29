using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class OperationalSummaryCollectorTests
{
    private const string ApplicationGroupId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/applicationGroups/dag1";

    [Fact]
    public async Task CollectAsyncRendersAndReturnsReportArtifacts()
    {
        var discoveryClient = new FakeDiscoveryClient(new DiscoverySnapshot(
            new[] { ApplicationGroupId },
            new[] { new RoleAssignmentEvidence(ApplicationGroupId, "group1", "Group", "role1") },
            WasAuthorized: true,
            Array.Empty<string>()));
        var writer = new CapturingArtifactWriter();
        var collector = new OperationalSummaryCollector(
            discoveryClient,
            new RoleAssignmentClassifier(),
            new HtmlOperationalSummaryReportRenderer(),
            writer,
            new FakePrincipalValidator(new[] { new PrincipalValidationEvidence("group1", "Group", "Exists", "AVD Users", null) }));
        var request = new OperationalSummaryRequest(
            "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1",
            new[] { ApplicationGroupId },
            ReportName: "test-run");

        var report = await collector.CollectAsync(request, CancellationToken.None);

        Assert.Equal("test-run", report.RunId);
        Assert.Equal("Authoritative", report.DiscoveryConfidence);
        Assert.Empty(report.Findings);
        Assert.Single(report.PrincipalValidationEvidence);
        Assert.Single(report.ReportArtifacts);
        Assert.Contains("AVD Operational Summary", writer.HtmlReport);
    }

    [Fact]
    public async Task CollectAsyncKeepsMissingAssignmentFindingBehindAuthorizedEvidence()
    {
        var discoveryClient = new FakeDiscoveryClient(new DiscoverySnapshot(
            new[] { ApplicationGroupId },
            Array.Empty<RoleAssignmentEvidence>(),
            WasAuthorized: false,
            new[] { "not authorized" }));
        var collector = new OperationalSummaryCollector(
            discoveryClient,
            new RoleAssignmentClassifier(),
            new HtmlOperationalSummaryReportRenderer(),
            new CapturingArtifactWriter(),
            new FakePrincipalValidator(Array.Empty<PrincipalValidationEvidence>()));
        var request = new OperationalSummaryRequest(
            "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1",
            new[] { ApplicationGroupId });

        var report = await collector.CollectAsync(request, CancellationToken.None);

        Assert.Contains(report.Findings, finding => finding.Code == "APPLICATION_GROUP_ASSIGNMENTS_NOT_EVALUATED");
        Assert.DoesNotContain(report.Findings, finding => finding.Code == "APPLICATION_GROUP_ASSIGNMENTS_MISSING");
        Assert.Equal("DiscoveryIncomplete", report.Overview.OverallStatus);
    }

    [Fact]
    public async Task CollectAsyncEmitsFindingWhenAssignedGroupIsNotFound()
    {
        var discoveryClient = new FakeDiscoveryClient(new DiscoverySnapshot(
            new[] { ApplicationGroupId },
            new[] { new RoleAssignmentEvidence(ApplicationGroupId, "group1", "Group", "role1") },
            WasAuthorized: true,
            Array.Empty<string>()));
        var collector = new OperationalSummaryCollector(
            discoveryClient,
            new RoleAssignmentClassifier(),
            new HtmlOperationalSummaryReportRenderer(),
            new CapturingArtifactWriter(),
            new FakePrincipalValidator(new[] { new PrincipalValidationEvidence("group1", "Group", "NotFound", null, "missing") }));
        var request = new OperationalSummaryRequest(
            "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1",
            new[] { ApplicationGroupId });

        var report = await collector.CollectAsync(request, CancellationToken.None);

        Assert.Contains(report.Findings, finding => finding.Code == "GROUP_PRINCIPAL_NOT_FOUND");
    }

    [Fact]
    public async Task CollectAsyncDoesNotClaimGroupMissingWhenGraphIsNotReadable()
    {
        var discoveryClient = new FakeDiscoveryClient(new DiscoverySnapshot(
            new[] { ApplicationGroupId },
            new[] { new RoleAssignmentEvidence(ApplicationGroupId, "group1", "Group", "role1") },
            WasAuthorized: true,
            Array.Empty<string>()));
        var collector = new OperationalSummaryCollector(
            discoveryClient,
            new RoleAssignmentClassifier(),
            new HtmlOperationalSummaryReportRenderer(),
            new CapturingArtifactWriter(),
            new FakePrincipalValidator(new[] { new PrincipalValidationEvidence("group1", "Group", "NotReadable", null, "not authorized") }));
        var request = new OperationalSummaryRequest(
            "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/hp1",
            new[] { ApplicationGroupId });

        var report = await collector.CollectAsync(request, CancellationToken.None);

        Assert.Contains(report.Findings, finding => finding.Code == "GROUP_PRINCIPAL_NOT_READABLE");
        Assert.DoesNotContain(report.Findings, finding => finding.Code == "GROUP_PRINCIPAL_NOT_FOUND");
    }

    private sealed class FakeDiscoveryClient : IAvdDiscoveryClient
    {
        private readonly DiscoverySnapshot snapshot;

        public FakeDiscoveryClient(DiscoverySnapshot snapshot)
        {
            this.snapshot = snapshot;
        }

        public Task<DiscoverySnapshot> DiscoverAsync(OperationalSummaryRequest request, CancellationToken cancellationToken) =>
            Task.FromResult(snapshot);
    }

    private sealed class CapturingArtifactWriter : IReportArtifactWriter
    {
        public string HtmlReport { get; private set; } = string.Empty;

        public Task<IReadOnlyList<ReportArtifact>> WriteAsync(
            OperationalSummaryReport report,
            string htmlReport,
            CancellationToken cancellationToken)
        {
            HtmlReport = htmlReport;
            IReadOnlyList<ReportArtifact> artifacts = new[]
            {
                new ReportArtifact("Html", "text/html", $"{report.RunId}/summary.html", null, null)
            };

            return Task.FromResult(artifacts);
        }
    }

    private sealed class FakePrincipalValidator : IPrincipalValidator
    {
        private readonly IReadOnlyList<PrincipalValidationEvidence> evidence;

        public FakePrincipalValidator(IReadOnlyList<PrincipalValidationEvidence> evidence)
        {
            this.evidence = evidence;
        }

        public Task<IReadOnlyList<PrincipalValidationEvidence>> ValidateAsync(
            IReadOnlyList<RoleAssignmentEvidence> roleAssignments,
            CancellationToken cancellationToken) =>
            Task.FromResult(evidence);
    }
}