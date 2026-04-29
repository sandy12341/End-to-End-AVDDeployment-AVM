using System.Text.Json;
using OperationalSummary.Functions;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class ManagedApplicationEventGridFunctionTests
{
    private const string ManagedApplicationId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.Solutions/applications/summary-app";

    [Fact]
    public void TryGetManagedApplicationResourceIdAcceptsManagedApplicationWriteSuccess()
    {
        using var document = JsonDocument.Parse($$"""
            {
              "id": "event-1",
              "subject": "{{ManagedApplicationId}}",
              "eventType": "Microsoft.Resources.ResourceWriteSuccess",
              "data": {
                "resourceUri": "{{ManagedApplicationId}}",
                "operationName": "Microsoft.Solutions/applications/write"
              }
            }
            """);

        var accepted = GenerateOperationalSummaryFromManagedAppEventFunction.TryGetManagedApplicationResourceId(
            document.RootElement,
            out var eventId,
            out var resourceId);

        Assert.True(accepted);
        Assert.Equal("event-1", eventId);
        Assert.Equal(ManagedApplicationId, resourceId);
    }

    [Fact]
    public void TryGetManagedApplicationResourceIdRejectsNonManagedApplicationEvents()
    {
        using var document = JsonDocument.Parse("""
            {
              "id": "event-2",
              "subject": "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/st1",
              "eventType": "Microsoft.Resources.ResourceWriteSuccess",
              "data": {
                "resourceUri": "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.Storage/storageAccounts/st1",
                "operationName": "Microsoft.Storage/storageAccounts/write"
              }
            }
            """);

        var accepted = GenerateOperationalSummaryFromManagedAppEventFunction.TryGetManagedApplicationResourceId(
            document.RootElement,
            out _,
            out _);

        Assert.False(accepted);
    }
}