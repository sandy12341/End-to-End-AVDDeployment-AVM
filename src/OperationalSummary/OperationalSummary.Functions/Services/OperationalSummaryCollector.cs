using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class OperationalSummaryCollector : IOperationalSummaryCollector
{
    private readonly IAvdDiscoveryClient discoveryClient;
    private readonly RoleAssignmentClassifier classifier;

    public OperationalSummaryCollector(IAvdDiscoveryClient discoveryClient, RoleAssignmentClassifier classifier)
    {
        this.discoveryClient = discoveryClient;
        this.classifier = classifier;
    }

    public async Task<OperationalSummaryReport> CollectAsync(OperationalSummaryRequest request, CancellationToken cancellationToken)
    {
        var snapshot = await discoveryClient.DiscoverAsync(request, cancellationToken);
        var accessResults = classifier.Classify(snapshot.ApplicationGroupResourceIds, snapshot.RoleAssignments, snapshot.WasAuthorized);
        var findings = BuildFindings(accessResults, snapshot).ToArray();

        return new OperationalSummaryReport(
            SchemaVersion: "2026-04-collector-preview-1",
            GeneratedAt: DateTimeOffset.UtcNow,
            Target: new OperationalSummaryTarget(request.HostPoolResourceId, snapshot.ApplicationGroupResourceIds, request.WorkspaceResourceId),
            CollectionMode: "AuthoritativeCollector",
            DiscoveryConfidence: snapshot.WasAuthorized ? "Authoritative" : "NotAuthorized",
            Findings: findings,
            RoleAssignmentEvidence: snapshot.RoleAssignments);
    }

    private static IEnumerable<OperationalSummaryFinding> BuildFindings(
        IReadOnlyList<ApplicationGroupAccessResult> accessResults,
        DiscoverySnapshot snapshot)
    {
        if (!snapshot.WasAuthorized)
        {
            yield return new OperationalSummaryFinding(
                "APPLICATION_GROUP_ASSIGNMENTS_NOT_EVALUATED",
                "Informational",
                "Access",
                "The collector did not have enough discovery evidence to evaluate application group assignments.",
                "Grant the collector managed identity read access to the target scope, including role assignment read permissions, then rerun collection.");

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
                "Assign users or groups to the affected application groups, preferably through group-based RBAC.");
        }
    }
}
