# Sample Workbook

## Purpose

This document provides a copy-paste workbook-style query pack for validating Azure Virtual Desktop monitoring in the Log Analytics workspace created by the repo deployment flow.

Current workspace reference:

- Workspace name: `log-avd-avd1-dev`
- Expected guest telemetry tables: `Event`, `Perf`, `InsightsMetrics`
- Expected control-plane diagnostics: Azure Virtual Desktop host pool, workspace, and application group diagnostic settings
- Expected FSLogix diagnostics: Azure Files `fileServices/default` logs

## How To Use

- Paste each section into its own Azure Monitor Workbook query tile.
- Start with sections 1 through 5 to verify the baseline is wired correctly.
- Use sections 6 through 10 for deeper AVD, host, and FSLogix verification.
- Replace `vm-avd-avd1-dev-0` if your session host name differs.

---

## 1. Workspace Ingestion Overview

Purpose:
- Confirm the workspace is receiving data.
- Identify which tables are active in the last two hours.

Expected:
- `Event`, `Perf`, and `InsightsMetrics`
- One or more resource-specific AVD or storage diagnostic tables

```kusto
search *
| where TimeGenerated > ago(2h)
| summarize Rows=count(), Latest=max(TimeGenerated) by $table
| order by Rows desc
```

---

## 2. Session Host Guest Telemetry Presence

Purpose:
- Verify the session host is sending guest telemetry through AMA and the Data Collection Rule.

Expected:
- The session host should appear in `Event`, `Perf`, and usually `InsightsMetrics`.

```kusto
union isfuzzy=true Event, Perf, InsightsMetrics
| where TimeGenerated > ago(2h)
| summarize Rows=count(), Latest=max(TimeGenerated) by Computer, $table
| order by Latest desc
```

---

## 3. Single Host End-To-End Sanity

Purpose:
- Verify that one specific session host is sending telemetry.

Expected:
- Recent rows in `Event` and `Perf` at minimum.

```kusto
union isfuzzy=true Event, Perf, InsightsMetrics
| where TimeGenerated > ago(2h)
| where Computer =~ "vm-avd-avd1-dev-0"
| summarize Rows=count(), Latest=max(TimeGenerated) by $table
| order by Latest desc
```

---

## 4. AVD Control Plane Diagnostics

Purpose:
- Confirm host pool, workspace, and application group diagnostics are arriving.

Expected:
- Resource IDs containing `Microsoft.DesktopVirtualization`

```kusto
search *
| where TimeGenerated > ago(2h)
| where _ResourceId has "Microsoft.DesktopVirtualization"
| summarize Rows=count(), Latest=max(TimeGenerated) by $table, _ResourceId
| order by Latest desc
```

---

## 5. FSLogix / Azure Files Diagnostics Discovery

Purpose:
- Confirm Azure Files diagnostics from the FSLogix backend are arriving from the `fileServices/default` subresource.

Expected:
- One or more rows for a storage log table such as `StorageFileLogs`

```kusto
search *
| where TimeGenerated > ago(2h)
| where _ResourceId has "/Microsoft.Storage/storageAccounts/"
| where _ResourceId has "/fileServices/default"
| summarize Rows=count(), Latest=max(TimeGenerated) by $table, _ResourceId
| order by Latest desc
```

---

## 6. FSLogix Host-Side Event Review

Purpose:
- Review FSLogix application events written by the session host.

Expected:
- Operational entries, with warnings and errors reviewed closely.

```kusto
Event
| where TimeGenerated > ago(4h)
| where Computer =~ "vm-avd-avd1-dev-0"
| where Source == "Microsoft-FSLogix-Apps/Operational"
| project TimeGenerated, Computer, EventLevelName, EventID, RenderedDescription
| order by TimeGenerated desc
```

---

## 7. RDP / Session Broker Health Signals

Purpose:
- Review Remote Desktop and session lifecycle event channels.

Expected:
- Mostly informational entries.
- Warnings and errors should be investigated.

```kusto
Event
| where TimeGenerated > ago(4h)
| where Computer =~ "vm-avd-avd1-dev-0"
| where Source in (
    "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational",
    "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational",
    "Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational"
)
| summarize Events=count(),
            Errors=countif(EventLevelName in ("Error", "Critical")),
            Warnings=countif(EventLevelName == "Warning")
          by Source
| order by Errors desc, Warnings desc
```

---

## 8. Session Host Performance Health

Purpose:
- Validate that the session host is reporting the key performance counters expected by the monitoring rule.

Expected:
- Regular samples for CPU, memory, disk, and network counters.

```kusto
Perf
| where TimeGenerated > ago(2h)
| where Computer =~ "vm-avd-avd1-dev-0"
| where CounterName in (
    "% Processor Time",
    "Available MBytes",
    "% Free Space",
    "Disk Transfers/sec",
    "Bytes Total/sec"
)
| summarize AvgValue=avg(CounterValue), MaxValue=max(CounterValue)
          by ObjectName, CounterName, bin(TimeGenerated, 15m)
| order by TimeGenerated desc
```

---

## 9. Storage File Activity Validation

Purpose:
- Confirm Azure Files activity for the FSLogix backend using the fixed file-service diagnostic scope.

Expected:
- Read and write activity after connections begin.

Note:
- If `StorageFileLogs` does not exist in the workspace yet, run section 5 first and substitute the actual table name returned there.

```kusto
StorageFileLogs
| where TimeGenerated > ago(4h)
| where _ResourceId has "/fileServices/default"
| summarize Reads=countif(OperationName has "Read"),
            Writes=countif(OperationName has "Write"),
            Deletes=countif(OperationName has "Delete"),
            Failures=countif(StatusCode !in ("Success", "Succeeded", "200", "201", "202", "204")),
            Latest=max(TimeGenerated)
          by _ResourceId
| order by Latest desc
```

---

## 10. Final Pass / Fail Summary View

Purpose:
- Provide one quick operator summary showing whether the major monitoring data families are present.

Expected:
- Non-zero rows for guest telemetry plus evidence of AVD control-plane and FSLogix Azure Files diagnostics.

```kusto
let GuestTables =
    union isfuzzy=true Event, Perf, InsightsMetrics
    | where TimeGenerated > ago(2h)
    | summarize Rows=count() by TableName=$table;
let AvdDiag =
    search *
    | where TimeGenerated > ago(2h)
    | where _ResourceId has "Microsoft.DesktopVirtualization"
    | summarize Rows=count()
    | project TableName="AVD_ControlPlane_Diagnostics", Rows;
let StorageDiag =
    search *
    | where TimeGenerated > ago(2h)
    | where _ResourceId has "/fileServices/default"
    | summarize Rows=count()
    | project TableName="FSLogix_AzureFiles_Diagnostics", Rows;
union GuestTables, AvdDiag, StorageDiag
| order by TableName asc
```

## Reading The Results

Healthy baseline indicators:

- `Event`, `Perf`, and `InsightsMetrics` all show recent rows.
- The session host appears in guest telemetry tables.
- AVD control-plane resource IDs appear in diagnostic output.
- The Azure Files `fileServices/default` resource appears in storage diagnostic output.

Potential gaps:

- `Event` and `Perf` are empty for the session host.
- `InsightsMetrics` exists but the VM has no `Event` rows.
- No `Microsoft.DesktopVirtualization` resources appear in the workspace.
- No `fileServices/default` resource appears in storage diagnostics.