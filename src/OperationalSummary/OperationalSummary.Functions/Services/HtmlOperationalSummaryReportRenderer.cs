using System.Net;
using System.Text;
using OperationalSummary.Functions.Models;

namespace OperationalSummary.Functions.Services;

public sealed class HtmlOperationalSummaryReportRenderer : IOperationalSummaryReportRenderer
{
    public string RenderHtml(OperationalSummaryReport report)
    {
        var html = new StringBuilder();

        html.Append("<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">");
        html.Append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">");
        html.Append("<title>AVD Operational Summary</title>");
        html.Append("<style>");
        html.Append("body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:#f6f8fa;color:#1f2328}main{max-width:1180px;margin:0 auto;padding:32px}section{background:#fff;border:1px solid #d0d7de;border-radius:8px;margin:16px 0;padding:20px}h1,h2,h3{margin:0 0 12px}table{width:100%;border-collapse:collapse}th,td{border-bottom:1px solid #d8dee4;text-align:left;padding:8px;vertical-align:top}.meta{color:#57606a}.pill{display:inline-block;border-radius:999px;padding:2px 10px;background:#ddf4ff;color:#0969da}.High{background:#ffebe9;color:#cf222e}.Medium{background:#fff8c5;color:#9a6700}.Low{background:#dafbe1;color:#1a7f37}.Informational{background:#ddf4ff;color:#0969da}ul{padding-left:20px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.card{border:1px solid #d8dee4;border-radius:6px;padding:12px;background:#fbfcfd}");
        html.Append("</style></head><body><main>");

        html.Append("<h1>AVD Operational Summary</h1>");
        html.Append("<p class=\"meta\">Generated ").Append(E(report.GeneratedAt.UtcDateTime.ToString("u"))).Append(" | Run ").Append(E(report.RunId)).Append("</p>");

        html.Append("<section><h2>Executive Summary</h2>");
        html.Append("<p><span class=\"pill\">").Append(E(report.Overview.OverallStatus)).Append("</span></p>");
        html.Append("<p>").Append(E(report.Overview.SummaryText)).Append("</p>");
        AppendList(html, "Top Recommendations", report.Overview.TopRecommendations);
        html.Append("</section>");

        html.Append("<section><h2>Target</h2><div class=\"grid\">");
        AppendCard(html, "Host Pool", report.Target.HostPoolResourceId);
        AppendCard(html, "Workspace", report.Target.WorkspaceResourceId ?? "Not provided");
        AppendCard(html, "Application Groups", report.Target.ApplicationGroupResourceIds.Count.ToString());
        AppendCard(html, "Discovery Confidence", report.DiscoveryConfidence);
        html.Append("</div></section>");

        html.Append("<section><h2>Persona Views</h2>");
        foreach (var view in report.PersonaViews)
        {
            html.Append("<h3>").Append(E(view.Persona)).Append("</h3>");
            html.Append("<p>").Append(E(view.Summary)).Append("</p>");
            AppendList(html, "Key Signals", view.KeySignals);
            AppendList(html, "Recommended Actions", view.RecommendedActions);
        }
        html.Append("</section>");

        html.Append("<section><h2>Findings</h2><table><thead><tr><th>Severity</th><th>Code</th><th>Category</th><th>Observed State</th><th>Recommendation</th></tr></thead><tbody>");
        foreach (var finding in report.Findings)
        {
            html.Append("<tr><td><span class=\"pill ").Append(E(finding.Severity)).Append("\">").Append(E(finding.Severity)).Append("</span></td>");
            html.Append("<td>").Append(E(finding.Code)).Append("</td>");
            html.Append("<td>").Append(E(finding.Category)).Append("</td>");
            html.Append("<td>").Append(E(finding.ObservedState)).Append("</td>");
            html.Append("<td>").Append(E(finding.Recommendation)).Append("</td></tr>");
        }
        html.Append("</tbody></table></section>");

        html.Append("<section><h2>Role Assignment Evidence</h2><table><thead><tr><th>Scope</th><th>Principal</th><th>Type</th><th>Role Definition</th></tr></thead><tbody>");
        foreach (var assignment in report.RoleAssignmentEvidence)
        {
            html.Append("<tr><td>").Append(E(assignment.Scope)).Append("</td>");
            html.Append("<td>").Append(E(assignment.PrincipalId)).Append("</td>");
            html.Append("<td>").Append(E(assignment.PrincipalType)).Append("</td>");
            html.Append("<td>").Append(E(assignment.RoleDefinitionId)).Append("</td></tr>");
        }
        html.Append("</tbody></table></section>");

        if (report.DiscoveryMessages.Count > 0)
        {
            html.Append("<section><h2>Discovery Messages</h2><table><thead><tr><th>Severity</th><th>Source</th><th>Message</th></tr></thead><tbody>");
            foreach (var message in report.DiscoveryMessages)
            {
                html.Append("<tr><td>").Append(E(message.Severity)).Append("</td><td>").Append(E(message.Source)).Append("</td><td>").Append(E(message.Message)).Append("</td></tr>");
            }
            html.Append("</tbody></table></section>");
        }

        html.Append("</main></body></html>");
        return html.ToString();
    }

    private static void AppendCard(StringBuilder html, string label, string value)
    {
        html.Append("<div class=\"card\"><strong>").Append(E(label)).Append("</strong><p>").Append(E(value)).Append("</p></div>");
    }

    private static void AppendList(StringBuilder html, string label, IReadOnlyList<string> values)
    {
        if (values.Count == 0)
        {
            return;
        }

        html.Append("<strong>").Append(E(label)).Append("</strong><ul>");
        foreach (var value in values)
        {
            html.Append("<li>").Append(E(value)).Append("</li>");
        }
        html.Append("</ul>");
    }

    private static string E(string value) => WebUtility.HtmlEncode(value);
}