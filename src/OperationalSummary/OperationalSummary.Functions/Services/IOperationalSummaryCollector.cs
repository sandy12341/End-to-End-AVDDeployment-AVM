using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IOperationalSummaryCollector
{
    Task<OperationalSummaryReport> CollectAsync(OperationalSummaryRequest request, CancellationToken cancellationToken);
}
