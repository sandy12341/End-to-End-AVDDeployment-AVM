using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class BlobReportArtifactWriter : IReportArtifactWriter, IReportManifestReader
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        WriteIndented = true
    };

    private readonly BlobContainerClient? containerClient;
    private readonly string pathPrefix;

    public BlobReportArtifactWriter()
    {
        var containerUri = Environment.GetEnvironmentVariable("OPERATIONAL_SUMMARY_REPORT_CONTAINER_URI");
        pathPrefix = Environment.GetEnvironmentVariable("OPERATIONAL_SUMMARY_REPORT_PATH_PREFIX") ?? string.Empty;

        if (!string.IsNullOrWhiteSpace(containerUri))
        {
            containerClient = new BlobContainerClient(new Uri(containerUri), new DefaultAzureCredential());
        }
    }

    public async Task<IReadOnlyList<ReportArtifact>> WriteAsync(
        OperationalSummaryReport report,
        string htmlReport,
        CancellationToken cancellationToken)
    {
        if (containerClient is null)
        {
            return Array.Empty<ReportArtifact>();
        }

        var reportPath = BuildReportPath(report);
        var jsonBlobName = $"{reportPath}/summary.json";
        var htmlBlobName = $"{reportPath}/summary.html";
        var latestManifestBlobName = BuildLatestManifestBlobName(report.Target.HostPoolResourceId);

        var artifacts = new[]
        {
            CreateArtifact("Json", "application/json", jsonBlobName),
            CreateArtifact("Html", "text/html", htmlBlobName),
            CreateArtifact("LatestManifest", "application/json", latestManifestBlobName)
        };

        var reportWithArtifacts = report with { ReportArtifacts = artifacts };
        var manifest = CreateManifest(reportWithArtifacts);
        var jsonReport = JsonSerializer.Serialize(reportWithArtifacts, JsonOptions);
        var manifestJson = JsonSerializer.Serialize(manifest, JsonOptions);
        await UploadTextAsync(jsonBlobName, jsonReport, "application/json", cancellationToken);
        await UploadTextAsync(htmlBlobName, htmlReport, "text/html", cancellationToken);
        await UploadTextAsync(latestManifestBlobName, manifestJson, "application/json", cancellationToken);

        return artifacts;
    }

    public async Task<OperationalSummaryReportManifest?> GetLatestAsync(string hostPoolResourceId, CancellationToken cancellationToken)
    {
        if (containerClient is null || string.IsNullOrWhiteSpace(hostPoolResourceId))
        {
            return null;
        }

        var blobClient = containerClient.GetBlobClient(BuildLatestManifestBlobName(hostPoolResourceId));
        if (!await blobClient.ExistsAsync(cancellationToken))
        {
            return null;
        }

        var response = await blobClient.DownloadContentAsync(cancellationToken);
        return response.Value.Content.ToObjectFromJson<OperationalSummaryReportManifest>(JsonOptions);
    }

    private async Task UploadTextAsync(string blobName, string content, string contentType, CancellationToken cancellationToken)
    {
        var blobClient = containerClient!.GetBlobClient(blobName);
        await using var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));
        await blobClient.UploadAsync(stream, overwrite: true, cancellationToken);
        await blobClient.SetHttpHeadersAsync(new BlobHttpHeaders { ContentType = contentType }, cancellationToken: cancellationToken);
    }

    private ReportArtifact CreateArtifact(string kind, string contentType, string blobName)
    {
        var blobUri = containerClient!.GetBlobClient(blobName).Uri.ToString();

        return new ReportArtifact(
            kind,
            contentType,
            blobName,
            blobUri,
            null);
    }

    private static OperationalSummaryReportManifest CreateManifest(OperationalSummaryReport report) =>
        new(
            SchemaVersion: "2026-04-report-manifest-1",
            HostPoolResourceId: report.Target.HostPoolResourceId,
            WorkspaceResourceId: report.Target.WorkspaceResourceId,
            ManagedApplicationResourceId: report.Target.ManagedApplicationResourceId,
            RunId: report.RunId,
            GeneratedAt: report.GeneratedAt,
            OverallStatus: report.Overview.OverallStatus,
            DiscoveryConfidence: report.DiscoveryConfidence,
            ReportArtifacts: report.ReportArtifacts);

    private string BuildReportPath(OperationalSummaryReport report)
    {
        var safeScope = BuildSafeScope(report.Target.HostPoolResourceId);
        var basePath = string.IsNullOrWhiteSpace(pathPrefix) ? string.Empty : pathPrefix.Trim('/');

        return string.IsNullOrWhiteSpace(basePath)
            ? $"{safeScope}/{report.RunId}"
            : $"{basePath}/{safeScope}/{report.RunId}";
    }

    private string BuildLatestManifestBlobName(string hostPoolResourceId)
    {
        var safeScope = BuildSafeScope(hostPoolResourceId);
        var basePath = string.IsNullOrWhiteSpace(pathPrefix) ? string.Empty : pathPrefix.Trim('/');

        return string.IsNullOrWhiteSpace(basePath)
            ? $"{safeScope}/latest.json"
            : $"{basePath}/{safeScope}/latest.json";
    }

    private static string BuildSafeScope(string hostPoolResourceId) =>
        hostPoolResourceId.Trim('/').Replace('/', '-').Replace(':', '-');
}