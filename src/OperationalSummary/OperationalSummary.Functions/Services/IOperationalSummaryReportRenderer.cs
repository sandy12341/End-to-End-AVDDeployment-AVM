using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public interface IOperationalSummaryReportRenderer
{
    string RenderHtml(OperationalSummaryReport report);
}