using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IAvdDiscoveryClient
{
    Task<DiscoverySnapshot> DiscoverAsync(OperationalSummaryRequest request, CancellationToken cancellationToken);
}
