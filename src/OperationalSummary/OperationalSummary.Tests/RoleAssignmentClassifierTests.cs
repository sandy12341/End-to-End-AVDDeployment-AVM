using OperationalSummary.Functions.Models;
using OperationalSummary.Functions.Services;
using Xunit;

namespace OperationalSummary.Tests;

public sealed class RoleAssignmentClassifierTests
{
    private const string ApplicationGroupId = "/subscriptions/sub1/resourceGroups/rg1/providers/Microsoft.DesktopVirtualization/applicationGroups/dag1";

    [Fact]
    public void ClassifyReturnsDirectAssignmentWhenScopeMatchesApplicationGroup()
    {
        var classifier = new RoleAssignmentClassifier();
        var assignments = new[]
        {
            new RoleAssignmentEvidence(ApplicationGroupId, "principal1", "Group", "role1")
        };

        var result = classifier.Classify(new[] { ApplicationGroupId }, assignments, wasAuthorized: true).Single();

        Assert.Equal("DirectAssignmentsDetected", result.State);
        Assert.Equal(1, result.DirectAssignmentCount);
        Assert.Equal(0, result.InheritedAssignmentCount);
    }

    [Fact]
    public void ClassifyReturnsInheritedAssignmentWhenScopeIsResourceGroup()
    {
        var classifier = new RoleAssignmentClassifier();
        var assignments = new[]
        {
            new RoleAssignmentEvidence("/subscriptions/sub1/resourceGroups/rg1", "principal1", "Group", "role1")
        };

        var result = classifier.Classify(new[] { ApplicationGroupId }, assignments, wasAuthorized: true).Single();

        Assert.Equal("InheritedAssignmentsDetected", result.State);
        Assert.Equal(0, result.DirectAssignmentCount);
        Assert.Equal(1, result.InheritedAssignmentCount);
    }

    [Fact]
    public void ClassifyReturnsMissingOnlyWhenAuthorizedAndNoApplicableAssignmentsExist()
    {
        var classifier = new RoleAssignmentClassifier();

        var result = classifier.Classify(new[] { ApplicationGroupId }, Array.Empty<RoleAssignmentEvidence>(), wasAuthorized: true).Single();

        Assert.Equal("Missing", result.State);
    }

    [Fact]
    public void ClassifyReturnsNotAuthorizedBeforeMakingMissingClaim()
    {
        var classifier = new RoleAssignmentClassifier();

        var result = classifier.Classify(new[] { ApplicationGroupId }, Array.Empty<RoleAssignmentEvidence>(), wasAuthorized: false).Single();

        Assert.Equal("NotAuthorized", result.State);
    }
}
