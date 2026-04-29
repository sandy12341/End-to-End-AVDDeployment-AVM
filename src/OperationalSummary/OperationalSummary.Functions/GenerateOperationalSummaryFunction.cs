using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;

namespace OperationalSummary.Functions;

public sealed class GenerateOperationalSummaryFunction
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private readonly IOperationalSummaryCollector collector;
    private readonly ILogger<GenerateOperationalSummaryFunction> logger;

    public GenerateOperationalSummaryFunction(
        IOperationalSummaryCollector collector,
        ILogger<GenerateOperationalSummaryFunction> logger)
    {
        this.collector = collector;
        this.logger = logger;
    }

    [Function("GenerateOperationalSummary")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "operational-summary")] HttpRequest request,
        CancellationToken cancellationToken)
    {
        var summaryRequest = await JsonSerializer.DeserializeAsync<OperationalSummaryRequest>(
            request.Body,
            JsonOptions,
            cancellationToken);

        if (summaryRequest is null || string.IsNullOrWhiteSpace(summaryRequest.HostPoolResourceId))
        {
            return new BadRequestObjectResult(new { error = "hostPoolResourceId is required." });
        }

        logger.LogInformation(
            "Generating operational summary for host pool {HostPoolResourceId} with {ApplicationGroupCount} application group(s).",
            summaryRequest.HostPoolResourceId,
            summaryRequest.ApplicationGroupResourceIds.Count);

        var report = await collector.CollectAsync(summaryRequest, cancellationToken);
        return new OkObjectResult(report);
    }
}
