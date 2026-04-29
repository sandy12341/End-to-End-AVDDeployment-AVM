using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class OperationalSummaryCollector : IOperationalSummaryCollector
{
    private readonly IAvdDiscoveryClient discoveryClient;
    private readonly RoleAssignmentClassifier classifier;
    private readonly IOperationalSummaryReportRenderer renderer;
    private readonly IReportArtifactWriter artifactWriter;
    private readonly IPrincipalValidator principalValidator;

    public OperationalSummaryCollector(
        IAvdDiscoveryClient discoveryClient,
        RoleAssignmentClassifier classifier,
        IOperationalSummaryReportRenderer renderer,
        IReportArtifactWriter artifactWriter,
        IPrincipalValidator principalValidator)
    {
        this.discoveryClient = discoveryClient;
        this.classifier = classifier;
        this.renderer = renderer;
        this.artifactWriter = artifactWriter;
        this.principalValidator = principalValidator;
    }

    public async Task<OperationalSummaryReport> CollectAsync(OperationalSummaryRequest request, CancellationToken cancellationToken)
    {
        var snapshot = await discoveryClient.DiscoverAsync(request, cancellationToken);
        var accessResults = classifier.Classify(snapshot.ApplicationGroupResourceIds, snapshot.RoleAssignments, snapshot.WasAuthorized);
        var principalValidation = await principalValidator.ValidateAsync(snapshot.RoleAssignments, cancellationToken);
        var findings = BuildFindings(accessResults, snapshot, principalValidation).ToArray();
        var discoveryMessages = snapshot.Errors
            .Select(error => new DiscoveryMessage("Warning", "ARM", error))
            .ToArray();
        var overview = BuildOverview(findings, snapshot.WasAuthorized);
        var personaViews = BuildPersonaViews(findings, accessResults, snapshot, principalValidation).ToArray();
        var runId = CreateRunId(request);

        var report = new OperationalSummaryReport(
            SchemaVersion: "2026-04-collector-preview-1",
            RunId: runId,
            GeneratedAt: DateTimeOffset.UtcNow,
            Target: new OperationalSummaryTarget(
                request.HostPoolResourceId,
                snapshot.ApplicationGroupResourceIds,
                request.WorkspaceResourceId,
                request.ManagedApplicationResourceId,
                request.CorrelationId),
            CollectionMode: "AuthoritativeCollector",
            DiscoveryConfidence: snapshot.WasAuthorized ? "Authoritative" : "NotAuthorized",
            Findings: findings,
            RoleAssignmentEvidence: snapshot.RoleAssignments,
            PrincipalValidationEvidence: principalValidation,
            Overview: overview,
            PersonaViews: personaViews,
            DiscoveryMessages: discoveryMessages,
            ReportArtifacts: Array.Empty<ReportArtifact>());

        var html = renderer.RenderHtml(report);
        var artifacts = await artifactWriter.WriteAsync(report, html, cancellationToken);

        return report with { ReportArtifacts = artifacts };
    }

    private static string CreateRunId(OperationalSummaryRequest request)
    {
        if (!string.IsNullOrWhiteSpace(request.ReportName))
        {
            return SanitizeRunId(request.ReportName);
        }

        return $"run-{DateTimeOffset.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid():N}";
    }

    private static string SanitizeRunId(string value)
    {
        var safe = new string(value
            .Select(character => char.IsLetterOrDigit(character) || character is '-' or '_' ? character : '-')
            .ToArray());

        return string.IsNullOrWhiteSpace(safe) ? $"run-{Guid.NewGuid():N}" : safe;
    }

    private static OperationalSummaryOverview BuildOverview(
        IReadOnlyList<OperationalSummaryFinding> findings,
        bool wasAuthorized)
    {
        var counts = findings
            .GroupBy(finding => finding.Severity)
            .ToDictionary(group => group.Key, group => group.Count(), StringComparer.OrdinalIgnoreCase);
        var overallStatus = counts.ContainsKey("High") || counts.ContainsKey("Critical")
            ? "NeedsAttention"
            : counts.ContainsKey("Medium")
                ? "Monitor"
                : wasAuthorized
                    ? "Healthy"
                    : "DiscoveryIncomplete";
        var recommendations = findings
            .Where(finding => !string.Equals(finding.Severity, "Informational", StringComparison.OrdinalIgnoreCase))
            .Select(finding => finding.Recommendation)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(5)
            .ToArray();

        var summaryText = wasAuthorized
            ? "The collector completed authorized discovery for the requested AVD target and generated an evidence-backed summary."
            : "The collector generated a report, but authoritative discovery is incomplete because the runtime could not confirm required ARM/RBAC access.";

        return new OperationalSummaryOverview(overallStatus, summaryText, counts, recommendations);
    }

    private static IEnumerable<OperationalPersonaView> BuildPersonaViews(
        IReadOnlyList<OperationalSummaryFinding> findings,
        IReadOnlyList<ApplicationGroupAccessResult> accessResults,
        DiscoverySnapshot snapshot,
        IReadOnlyList<PrincipalValidationEvidence> principalValidation)
    {
        var missingAccessCount = accessResults.Count(result => result.State == "Missing");
        var directAssignmentCount = accessResults.Sum(result => result.DirectAssignmentCount);
        var inheritedAssignmentCount = accessResults.Sum(result => result.InheritedAssignmentCount);
        var missingGroupCount = principalValidation.Count(evidence => evidence.ValidationState == "NotFound");
        var unreadableGroupCount = principalValidation.Count(evidence => evidence.ValidationState == "NotReadable");

        yield return new OperationalPersonaView(
            "SysAdmin",
            "Operational view focused on target inventory, discovery coverage, and follow-up actions for the AVD platform.",
            new[]
            {
                $"Application groups evaluated: {snapshot.ApplicationGroupResourceIds.Count}",
                $"Discovery confidence: {(snapshot.WasAuthorized ? "Authoritative" : "NotAuthorized")}",
                $"Findings requiring attention: {findings.Count(finding => finding.Severity is "High" or "Medium")}"
            },
            new[]
            {
                "Review discovery coverage before operational changes.",
                "Use the report evidence to prioritize host pool and application group follow-up."
            },
            findings.Select(finding => finding.Code).ToArray());

        yield return new OperationalPersonaView(
            "SecurityAdmin",
            "Access and audit view focused on application group RBAC evidence and assignment hygiene.",
            new[]
            {
                $"Direct app group assignments detected: {directAssignmentCount}",
                $"Inherited app group assignments detected: {inheritedAssignmentCount}",
                $"Application groups missing confirmed assignments: {missingAccessCount}",
                $"Assigned groups not found: {missingGroupCount}",
                $"Assigned groups not readable: {unreadableGroupCount}"
            },
            new[]
            {
                "Validate group-based access for each application group.",
                "Investigate not-authorized discovery before declaring access missing.",
                "Review missing or unreadable group principals before closing access findings."
            },
            findings.Where(finding => finding.Category == "Access").Select(finding => finding.Code).ToArray());

        yield return new OperationalPersonaView(
            "HelpdeskAdmin",
            "Support view focused on whether users are likely to have application group access and what evidence should be escalated.",
            new[]
            {
                $"Application groups available for user access review: {snapshot.ApplicationGroupResourceIds.Count}",
                $"Access evidence records collected: {snapshot.RoleAssignments.Count}",
                $"Assigned groups validated: {principalValidation.Count(evidence => evidence.ValidationState == "Exists")}"
            },
            new[]
            {
                "If users cannot launch desktops or apps, include this access evidence in escalation notes.",
                "Escalate missing or unevaluated access findings to the AVD operations or security owner."
            },
            findings.Where(finding => finding.Category == "Access").Select(finding => finding.Code).ToArray());
    }

    private static IEnumerable<OperationalSummaryFinding> BuildFindings(
        IReadOnlyList<ApplicationGroupAccessResult> accessResults,
        DiscoverySnapshot snapshot,
        IReadOnlyList<PrincipalValidationEvidence> principalValidation)
    {
        if (!snapshot.WasAuthorized)
        {
            yield return new OperationalSummaryFinding(
                "APPLICATION_GROUP_ASSIGNMENTS_NOT_EVALUATED",
                "Informational",
                "Access",
                "The collector did not have enough discovery evidence to evaluate application group assignments.",
                "Grant the collector managed identity read access to the target scope, including role assignment read permissions, then rerun collection.",
                "SecurityAdmin");

            yield break;
        }

        var missingCount = accessResults.Count(result => result.State == "Missing");
        if (missingCount > 0)
        {
            yield return new OperationalSummaryFinding(
                "APPLICATION_GROUP_ASSIGNMENTS_MISSING",
                "High",
                "Access",
                $"{missingCount} application group resource(s) have no direct or inherited role assignments in authoritative collector evidence.",
                "Assign users or groups to the affected application groups, preferably through group-based RBAC.",
                "SecurityAdmin",
                accessResults.Where(result => result.State == "Missing").Select(result => result.ApplicationGroupResourceId).ToArray());
        }

        var missingGroups = principalValidation
            .Where(evidence => evidence.ValidationState == "NotFound")
            .ToArray();
        if (missingGroups.Length > 0)
        {
            yield return new OperationalSummaryFinding(
                "GROUP_PRINCIPAL_NOT_FOUND",
                "Medium",
                "Access",
                $"{missingGroups.Length} assigned group principal(s) could not be found in Microsoft Graph.",
                "Review the affected application group role assignments and replace stale or deleted group principals.",
                "SecurityAdmin",
                missingGroups.Select(group => group.PrincipalId).ToArray());
        }

        var unreadableGroups = principalValidation
            .Where(evidence => evidence.ValidationState == "NotReadable")
            .ToArray();
        if (unreadableGroups.Length > 0)
        {
            yield return new OperationalSummaryFinding(
                "GROUP_PRINCIPAL_NOT_READABLE",
                "Informational",
                "Access",
                $"{unreadableGroups.Length} assigned group principal(s) could not be validated because Microsoft Graph read access is unavailable.",
                "Grant the collector approved Microsoft Graph group read permission, then rerun collection to validate assigned groups.",
                "SecurityAdmin",
                unreadableGroups.Select(group => group.PrincipalId).ToArray());
        }
    }
}
