using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IReportArtifactWriter
{
    Task<IReadOnlyList<ReportArtifact>> WriteAsync(
        OperationalSummaryReport report,
        string htmlReport,
        CancellationToken cancellationToken);
}