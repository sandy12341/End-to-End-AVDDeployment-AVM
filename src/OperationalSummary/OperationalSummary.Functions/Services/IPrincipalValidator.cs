using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IPrincipalValidator
{
    Task<IReadOnlyList<PrincipalValidationEvidence>> ValidateAsync(
        IReadOnlyList<RoleAssignmentEvidence> roleAssignments,
        CancellationToken cancellationToken);
}