namespace OperationalSummary.Functions.Models;

public sealed record OperationalSummaryReport(
    string SchemaVersion,
    DateTimeOffset GeneratedAt,
    OperationalSummaryTarget Target,
    string CollectionMode,
    string DiscoveryConfidence,
    IReadOnlyList<OperationalSummaryFinding> Findings,
    IReadOnlyList<RoleAssignmentEvidence> RoleAssignmentEvidence);

public sealed record OperationalSummaryTarget(
    string HostPoolResourceId,
    IReadOnlyList<string> ApplicationGroupResourceIds,
    string? WorkspaceResourceId);

public sealed record OperationalSummaryFinding(
    string Code,
    string Severity,
    string Category,
    string ObservedState,
    string Recommendation);
