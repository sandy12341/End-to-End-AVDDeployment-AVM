using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class OperationalSummaryReportRendererTests
{
    [Fact]
    public void RenderHtmlEscapesDynamicValues()
    {
        var renderer = new HtmlOperationalSummaryReportRenderer();
        var report = new OperationalSummaryReport(
            SchemaVersion: "test",
            RunId: "run-1",
            GeneratedAt: DateTimeOffset.Parse("2026-04-29T00:00:00Z"),
            Target: new OperationalSummaryTarget("/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/hostPools/<hp>", Array.Empty<string>(), null),
            CollectionMode: "AuthoritativeCollector",
            DiscoveryConfidence: "Authoritative",
            Findings: new[]
            {
                new OperationalSummaryFinding("FINDING_<script>", "High", "Access", "Observed <bad>", "Fix > now")
            },
            RoleAssignmentEvidence: Array.Empty<RoleAssignmentEvidence>(),
            PrincipalValidationEvidence: new[]
            {
                new PrincipalValidationEvidence("group<script>", "Group", "Exists", "Name <unsafe>", "Message > unsafe")
            },
            Overview: new OperationalSummaryOverview("NeedsAttention", "Summary <unsafe>", new Dictionary<string, int> { ["High"] = 1 }, new[] { "Fix <this>" }),
            PersonaViews: Array.Empty<OperationalPersonaView>(),
            DiscoveryMessages: Array.Empty<DiscoveryMessage>(),
            ReportArtifacts: Array.Empty<ReportArtifact>());

        var html = renderer.RenderHtml(report);

        Assert.Contains("&lt;unsafe&gt;", html);
        Assert.Contains("FINDING_&lt;script&gt;", html);
        Assert.Contains("group&lt;script&gt;", html);
        Assert.DoesNotContain("Summary <unsafe>", html);
    }
}