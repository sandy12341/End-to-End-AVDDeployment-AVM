namespace OperationalSummary.Functions.Models;

public sealed record OperationalSummaryReport(
    string SchemaVersion,
    string RunId,
    DateTimeOffset GeneratedAt,
    OperationalSummaryTarget Target,
    string CollectionMode,
    string DiscoveryConfidence,
    IReadOnlyList<OperationalSummaryFinding> Findings,
    IReadOnlyList<RoleAssignmentEvidence> RoleAssignmentEvidence,
    IReadOnlyList<PrincipalValidationEvidence> PrincipalValidationEvidence,
    OperationalSummaryOverview Overview,
    IReadOnlyList<OperationalPersonaView> PersonaViews,
    IReadOnlyList<DiscoveryMessage> DiscoveryMessages,
    IReadOnlyList<ReportArtifact> ReportArtifacts);

public sealed record OperationalSummaryTarget(
    string HostPoolResourceId,
    IReadOnlyList<string> ApplicationGroupResourceIds,
    string? WorkspaceResourceId,
    string? ManagedApplicationResourceId = null,
    string? CorrelationId = null);

public sealed record OperationalSummaryFinding(
    string Code,
    string Severity,
    string Category,
    string ObservedState,
    string Recommendation,
    string Persona = "Operations",
    IReadOnlyList<string>? AffectedResourceIds = null);

public sealed record OperationalSummaryOverview(
    string OverallStatus,
    string SummaryText,
    IReadOnlyDictionary<string, int> FindingCountsBySeverity,
    IReadOnlyList<string> TopRecommendations);

public sealed record OperationalPersonaView(
    string Persona,
    string Summary,
    IReadOnlyList<string> KeySignals,
    IReadOnlyList<string> RecommendedActions,
    IReadOnlyList<string> FindingCodes);

public sealed record DiscoveryMessage(
    string Severity,
    string Source,
    string Message);

public sealed record ReportArtifact(
    string Kind,
    string ContentType,
    string Name,
    string? BlobUri,
    string? PortalUri);

public sealed record OperationalSummaryReportManifest(
    string SchemaVersion,
    string HostPoolResourceId,
    string? WorkspaceResourceId,
    string? ManagedApplicationResourceId,
    string RunId,
    DateTimeOffset GeneratedAt,
    string OverallStatus,
    string DiscoveryConfidence,
    IReadOnlyList<ReportArtifact> ReportArtifacts);

public sealed record PrincipalValidationEvidence(
    string PrincipalId,
    string PrincipalType,
    string ValidationState,
    string? DisplayName,
    string? Message);
