using Azure.Identity;
using Azure.ResourceManager;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class ArmAvdDiscoveryClient : IAvdDiscoveryClient
{
    private readonly ArmClient armClient;

    public ArmAvdDiscoveryClient()
    {
        armClient = new ArmClient(new DefaultAzureCredential());
    }

    public Task<DiscoverySnapshot> DiscoverAsync(OperationalSummaryRequest request, CancellationToken cancellationToken)
    {
        _ = armClient;

        var errors = new[]
        {
            "ARM RBAC discovery is scaffolded but not enabled in this slice. The collector is intentionally returning NotAuthorized instead of making a missing-assignment claim."
        };

        return Task.FromResult(new DiscoverySnapshot(
            request.ApplicationGroupResourceIds,
            Array.Empty<RoleAssignmentEvidence>(),
            WasAuthorized: false,
            Errors: errors));
    }
}
