using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class RoleAssignmentClassifier
{
    public IReadOnlyList<ApplicationGroupAccessResult> Classify(
        IReadOnlyList<string> applicationGroupResourceIds,
        IReadOnlyList<RoleAssignmentEvidence> assignments,
        bool wasAuthorized)
    {
        if (!wasAuthorized)
        {
            return applicationGroupResourceIds
                .Select(id => new ApplicationGroupAccessResult(id, "NotAuthorized", 0, 0))
                .ToArray();
        }

        return applicationGroupResourceIds
            .Select(id => ClassifyApplicationGroup(id, assignments))
            .ToArray();
    }

    private static ApplicationGroupAccessResult ClassifyApplicationGroup(
        string applicationGroupResourceId,
        IReadOnlyList<RoleAssignmentEvidence> assignments)
    {
        var directAssignments = assignments.Count(assignment => ScopesEqual(assignment.Scope, applicationGroupResourceId));
        var inheritedAssignments = assignments.Count(assignment => IsInheritedScope(applicationGroupResourceId, assignment.Scope));
        var state = directAssignments > 0
            ? "DirectAssignmentsDetected"
            : inheritedAssignments > 0
                ? "InheritedAssignmentsDetected"
                : "Missing";

        return new ApplicationGroupAccessResult(applicationGroupResourceId, state, directAssignments, inheritedAssignments);
    }

    private static bool ScopesEqual(string left, string right) =>
        string.Equals(NormalizeScope(left), NormalizeScope(right), StringComparison.OrdinalIgnoreCase);

    private static bool IsInheritedScope(string resourceId, string assignmentScope)
    {
        var normalizedResourceId = NormalizeScope(resourceId);
        var normalizedScope = NormalizeScope(assignmentScope);

        return normalizedResourceId.StartsWith(normalizedScope + "/", StringComparison.OrdinalIgnoreCase);
    }

    private static string NormalizeScope(string scope) => scope.Trim().TrimEnd('/');
}
