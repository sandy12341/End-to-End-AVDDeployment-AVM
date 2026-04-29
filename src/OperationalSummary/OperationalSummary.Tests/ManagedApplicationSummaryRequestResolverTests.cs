using System.Text.Json;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class ManagedApplicationSummaryRequestResolverTests
{
    private const string ManagedApplicationId = "/subscriptions/sub1/resourceGroups/rg-launch/providers/Microsoft.Solutions/applications/summary-app";

    [Fact]
    public void TryCreateRequestFromManagedApplicationBuildsRequestFromSummaryParameters()
    {
        using var document = JsonDocument.Parse("""
        {
          "name": "summary-app",
          "properties": {
            "parameters": {
              "hostPoolName": { "value": "hp1" },
              "existingHostPoolResourceGroupName": { "value": "rg-avd" },
              "existingWorkspaceNames": { "value": [ "ws1" ] },
              "brownfieldDetectedRelatedApplicationGroupIds": {
                "value": [
                  "/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/applicationGroups/dag1",
                  "/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/applicationGroups/rag1"
                ]
              }
            }
          }
        }
        """);

        var created = ArmManagedApplicationSummaryRequestResolver.TryCreateRequestFromManagedApplication(
            ManagedApplicationId,
            document.RootElement,
            "event-1",
            out var request);

        Assert.True(created);
        Assert.NotNull(request);
        Assert.Equal("/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/hostPools/hp1", request!.HostPoolResourceId);
        Assert.Equal(2, request.ApplicationGroupResourceIds.Count);
        Assert.Equal("/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/workspaces/ws1", request.WorkspaceResourceId);
        Assert.Equal(ManagedApplicationId, request.ManagedApplicationResourceId);
        Assert.Equal("event-1", request.CorrelationId);
    }

    [Fact]
    public void TryCreateRequestFromManagedApplicationAcceptsExplicitHostPoolResourceId()
    {
        using var document = JsonDocument.Parse("""
        {
          "properties": {
            "parameters": {
              "hostPoolResourceId": "/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/hostPools/hp1",
              "applicationGroupResourceIds": [
                "/subscriptions/sub1/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/applicationGroups/dag1"
              ]
            }
          }
        }
        """);

        var created = ArmManagedApplicationSummaryRequestResolver.TryCreateRequestFromManagedApplication(
            ManagedApplicationId,
            document.RootElement,
            null,
            out var request);

        Assert.True(created);
        Assert.Single(request!.ApplicationGroupResourceIds);
    }

    [Fact]
    public void TryCreateRequestFromManagedApplicationReturnsFalseWhenHostPoolCannotBeResolved()
    {
        using var document = JsonDocument.Parse("""
        {
          "properties": {
            "parameters": {
              "existingHostPoolResourceGroupName": { "value": "rg-avd" }
            }
          }
        }
        """);

        var created = ArmManagedApplicationSummaryRequestResolver.TryCreateRequestFromManagedApplication(
            ManagedApplicationId,
            document.RootElement,
            null,
            out var request);

        Assert.False(created);
        Assert.Null(request);
    }
}