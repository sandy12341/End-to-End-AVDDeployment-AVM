using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IReportManifestReader
{
    Task<OperationalSummaryReportManifest?> GetLatestAsync(string hostPoolResourceId, CancellationToken cancellationToken);
}