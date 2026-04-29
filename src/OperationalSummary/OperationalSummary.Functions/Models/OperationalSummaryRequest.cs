namespace OperationalSummary.Functions.Models;

public sealed record OperationalSummaryRequest(
    string HostPoolResourceId,
    IReadOnlyList<string> ApplicationGroupResourceIds,
    string? WorkspaceResourceId = null,
    string? ReportName = null);
