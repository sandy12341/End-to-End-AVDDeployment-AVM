namespace OperationalSummary.Functions.Models;

public sealed record RoleAssignmentEvidence(
    string Scope,
    string PrincipalId,
    string PrincipalType,
    string RoleDefinitionId);

public sealed record ApplicationGroupAccessResult(
    string ApplicationGroupResourceId,
    string State,
    int DirectAssignmentCount,
    int InheritedAssignmentCount);
