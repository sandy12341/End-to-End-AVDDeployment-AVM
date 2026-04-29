using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using OperationalSummary.Functions.Services;

namespace OperationalSummary.Functions;

public sealed class GetLatestOperationalSummaryFunction
{
    private readonly IReportManifestReader manifestReader;

    public GetLatestOperationalSummaryFunction(IReportManifestReader manifestReader)
    {
        this.manifestReader = manifestReader;
    }

    [Function("GetLatestOperationalSummary")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", Route = "operational-summary/latest")] HttpRequest request,
        CancellationToken cancellationToken)
    {
        var hostPoolResourceId = request.Query["hostPoolResourceId"].FirstOrDefault();
        if (string.IsNullOrWhiteSpace(hostPoolResourceId))
        {
            return new BadRequestObjectResult(new { error = "hostPoolResourceId query parameter is required." });
        }

        var manifest = await manifestReader.GetLatestAsync(hostPoolResourceId, cancellationToken);
        if (manifest is null)
        {
            return new NotFoundObjectResult(new { error = "No operational summary report was found for the requested host pool." });
        }

        return new OkObjectResult(manifest);
    }
}