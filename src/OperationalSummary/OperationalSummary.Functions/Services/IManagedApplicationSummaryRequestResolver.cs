using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IManagedApplicationSummaryRequestResolver
{
    Task<OperationalSummaryRequest?> ResolveAsync(
        string managedApplicationResourceId,
        string? correlationId,
        CancellationToken cancellationToken);
}