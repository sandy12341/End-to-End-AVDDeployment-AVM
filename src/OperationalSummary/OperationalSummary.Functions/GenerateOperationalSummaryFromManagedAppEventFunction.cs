using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using OperationalSummary.Functions.Services;

namespace OperationalSummary.Functions;

public sealed class GenerateOperationalSummaryFromManagedAppEventFunction
{
    private const string ResourceWriteSuccessEventType = "Microsoft.Resources.ResourceWriteSuccess";
    private const string ManagedApplicationWriteOperationName = "Microsoft.Solutions/applications/write";
    private const string SubscriptionValidationEventType = "Microsoft.EventGrid.SubscriptionValidationEvent";

    private readonly IManagedApplicationSummaryRequestResolver requestResolver;
    private readonly IOperationalSummaryCollector collector;
    private readonly ILogger<GenerateOperationalSummaryFromManagedAppEventFunction> logger;

    public GenerateOperationalSummaryFromManagedAppEventFunction(
        IManagedApplicationSummaryRequestResolver requestResolver,
        IOperationalSummaryCollector collector,
        ILogger<GenerateOperationalSummaryFromManagedAppEventFunction> logger)
    {
        this.requestResolver = requestResolver;
        this.collector = collector;
        this.logger = logger;
    }

    [Function("GenerateOperationalSummaryFromManagedAppEvent")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "operational-summary/managed-app-events")] HttpRequest request,
        CancellationToken cancellationToken)
    {
        using var document = await JsonDocument.ParseAsync(request.Body, cancellationToken: cancellationToken);
        if (document.RootElement.ValueKind != JsonValueKind.Array)
        {
            return new BadRequestObjectResult(new { error = "Expected an Event Grid event array." });
        }

        var processedEvents = 0;
        var ignoredEvents = 0;
        foreach (var eventGridEvent in document.RootElement.EnumerateArray())
        {
            if (TryGetSubscriptionValidationCode(eventGridEvent, out var validationCode))
            {
                return new OkObjectResult(new { validationResponse = validationCode });
            }

            if (!TryGetManagedApplicationResourceId(eventGridEvent, out var eventId, out var managedApplicationResourceId))
            {
                ignoredEvents++;
                logger.LogInformation(
                    "Ignoring Event Grid event {EventId}; no managed application resource ID was found.",
                    eventId);
                continue;
            }

            var summaryRequest = await requestResolver.ResolveAsync(
                managedApplicationResourceId,
                eventId,
                cancellationToken);

            if (summaryRequest is null)
            {
                ignoredEvents++;
                logger.LogWarning(
                    "Managed application event {EventId} did not resolve to an operational summary request for {ManagedApplicationResourceId}.",
                    eventId,
                    managedApplicationResourceId);
                continue;
            }

            logger.LogInformation(
                "Generating operational summary from managed application event {EventId} for {ManagedApplicationResourceId}.",
                eventId,
                managedApplicationResourceId);

            await collector.CollectAsync(summaryRequest, cancellationToken);
            processedEvents++;
        }

        return new OkObjectResult(new { processedEvents, ignoredEvents });
    }

    public static bool TryGetManagedApplicationResourceId(JsonElement eventGridEvent, out string eventId, out string managedApplicationResourceId)
    {
        eventId = TryGetString(eventGridEvent, "id", out var id) ? id : string.Empty;
        managedApplicationResourceId = string.Empty;
        if (!TryGetString(eventGridEvent, "eventType", out var eventType) ||
            !string.Equals(eventType, ResourceWriteSuccessEventType, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (!eventGridEvent.TryGetProperty("data", out var data) || data.ValueKind != JsonValueKind.Object)
        {
            return false;
        }

        if (data.TryGetProperty("operationName", out var operationName) &&
            operationName.ValueKind == JsonValueKind.String &&
            !string.Equals(operationName.GetString(), ManagedApplicationWriteOperationName, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        if (TryGetString(data, "resourceUri", out var resourceUri) && IsManagedApplicationResourceId(resourceUri))
        {
            managedApplicationResourceId = resourceUri;
            return true;
        }

        if (TryGetString(eventGridEvent, "subject", out var subject) && IsManagedApplicationResourceId(subject))
        {
            managedApplicationResourceId = subject;
            return true;
        }

        return false;
    }

    private static bool TryGetSubscriptionValidationCode(JsonElement eventGridEvent, out string validationCode)
    {
        validationCode = string.Empty;
        if (!TryGetString(eventGridEvent, "eventType", out var eventType) ||
            !string.Equals(eventType, SubscriptionValidationEventType, StringComparison.OrdinalIgnoreCase) ||
            !eventGridEvent.TryGetProperty("data", out var data))
        {
            return false;
        }

        return TryGetString(data, "validationCode", out validationCode);
    }

    private static bool TryGetString(JsonElement element, string propertyName, out string value)
    {
        value = string.Empty;
        if (!element.TryGetProperty(propertyName, out var property) || property.ValueKind != JsonValueKind.String)
        {
            return false;
        }

        value = property.GetString() ?? string.Empty;
        return !string.IsNullOrWhiteSpace(value);
    }

    private static bool IsManagedApplicationResourceId(string resourceId) =>
        resourceId.Contains("/providers/Microsoft.Solutions/applications/", StringComparison.OrdinalIgnoreCase);
}