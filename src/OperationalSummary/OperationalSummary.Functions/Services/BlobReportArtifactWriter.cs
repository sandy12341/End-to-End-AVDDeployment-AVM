using System.Text;
using System.Text.Json;
using Azure.Identity;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class BlobReportArtifactWriter : IReportArtifactWriter
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

        var jsonReport = JsonSerializer.Serialize(report with { ReportArtifacts = Array.Empty<ReportArtifact>() }, JsonOptions);
        await UploadTextAsync(jsonBlobName, jsonReport, "application/json", cancellationToken);
        await UploadTextAsync(htmlBlobName, htmlReport, "text/html", cancellationToken);

        return new[]
        {
            CreateArtifact("Json", "application/json", jsonBlobName),
            CreateArtifact("Html", "text/html", htmlBlobName)
        };
    }

    private async Task UploadTextAsync(string blobName, string content, string contentType, CancellationToken cancellationToken)
    {
        var blobClient = containerClient!.GetBlobClient(blobName);
        await using var stream = new MemoryStream(Encoding.UTF8.GetBytes(content));
        await blobClient.UploadAsync(
            stream,
            new BlobUploadOptions
            {
                HttpHeaders = new BlobHttpHeaders { ContentType = contentType }
            },
            cancellationToken);
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

    private string BuildReportPath(OperationalSummaryReport report)
    {
        var hostPoolResourceId = report.Target.HostPoolResourceId.Trim('/');
        var safeScope = hostPoolResourceId.Replace('/', '-').Replace(':', '-');
        var basePath = string.IsNullOrWhiteSpace(pathPrefix) ? string.Empty : pathPrefix.Trim('/');

        return string.IsNullOrWhiteSpace(basePath)
            ? $"{safeScope}/{report.RunId}"
            : $"{basePath}/{safeScope}/{report.RunId}";
    }
}