using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed record DiscoverySnapshot(
    IReadOnlyList<string> ApplicationGroupResourceIds,
    IReadOnlyList<RoleAssignmentEvidence> RoleAssignments,
    bool WasAuthorized,
    IReadOnlyList<string> Errors);
