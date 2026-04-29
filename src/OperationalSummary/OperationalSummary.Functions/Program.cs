using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OperationalSummary.Functions.Services;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Services
    .AddApplicationInsightsTelemetryWorkerService()
    .ConfigureFunctionsApplicationInsights();

builder.Services.AddSingleton<RoleAssignmentClassifier>();
builder.Services.AddSingleton<IOperationalSummaryReportRenderer, HtmlOperationalSummaryReportRenderer>();
builder.Services.AddSingleton<BlobReportArtifactWriter>();
builder.Services.AddSingleton<IReportArtifactWriter>(provider => provider.GetRequiredService<BlobReportArtifactWriter>());
builder.Services.AddSingleton<IReportManifestReader>(provider => provider.GetRequiredService<BlobReportArtifactWriter>());
builder.Services.AddSingleton<IPrincipalValidator, GraphGroupPrincipalValidator>();
builder.Services.AddSingleton<IAvdDiscoveryClient, ArmAvdDiscoveryClient>();
builder.Services.AddSingleton<IManagedApplicationSummaryRequestResolver, ArmManagedApplicationSummaryRequestResolver>();
builder.Services.AddSingleton<IOperationalSummaryCollector, OperationalSummaryCollector>();

builder.Build().Run();
