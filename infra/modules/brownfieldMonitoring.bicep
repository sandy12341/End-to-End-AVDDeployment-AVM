@description('Azure region')
param location string

@description('Existing host pool name')
param hostPoolName string

@description('Optional existing workspace names related to the selected host pool.')
param workspaceNames array = []

@description('Optional existing application group names related to the selected host pool.')
param applicationGroupNames array = []

@description('Whether to create a new Log Analytics workspace in the target resource group.')
param createWorkspace bool = true

@description('Log Analytics workspace name to create when createWorkspace is true.')
param workspaceName string = ''

@description('Existing Log Analytics workspace resource ID to use when createWorkspace is false.')
param existingWorkspaceResourceId string = ''

@description('Retention in days for a newly created Log Analytics workspace.')
param retentionDays int = 30

@description('Whether to enable host pool diagnostic settings.')
param enableHostPoolDiagnostics bool = true

@description('Whether to enable workspace diagnostic settings.')
param enableWorkspaceDiagnostics bool = true

@description('Whether to enable application group diagnostic settings.')
param enableApplicationGroupDiagnostics bool = true

@description('Tags for created resources.')
param tags object = {}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = if (createWorkspace) {
  name: take('avm.res.operational-insights.workspace.${workspaceName}', 64)
  params: {
    name: workspaceName
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: retentionDays
    enableTelemetry: false
  }
}

var useCreatedWorkspace = createWorkspace && !empty(workspaceName)
var useExistingWorkspace = !createWorkspace && !empty(existingWorkspaceResourceId)
var effectiveWorkspaceId = useCreatedWorkspace ? logAnalytics!.outputs.resourceId : existingWorkspaceResourceId

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = {
  name: hostPoolName
}

resource workspaces 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' existing = [for workspaceNameItem in workspaceNames: {
  name: workspaceNameItem
}]

resource applicationGroups 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' existing = [for applicationGroupName in applicationGroupNames: {
  name: applicationGroupName
}]

#disable-next-line use-recent-api-versions
resource hostPoolDiagnosticsCreatedWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableHostPoolDiagnostics && useCreatedWorkspace) {
  name: 'diag-hostpool-to-law'
  scope: hostPool
  properties: {
    workspaceId: logAnalytics!.outputs.resourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions
resource hostPoolDiagnosticsExistingWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableHostPoolDiagnostics && useExistingWorkspace) {
  name: 'diag-hostpool-to-law'
  scope: hostPool
  properties: {
    workspaceId: existingWorkspaceResourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions
resource workspaceDiagnosticsCreatedWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (workspaceNameItem, index) in workspaceNames: if (enableWorkspaceDiagnostics && useCreatedWorkspace) {
  name: 'diag-workspace-to-law'
  scope: workspaces[index]
  properties: {
    workspaceId: logAnalytics!.outputs.resourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

#disable-next-line use-recent-api-versions
resource workspaceDiagnosticsExistingWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (workspaceNameItem, index) in workspaceNames: if (enableWorkspaceDiagnostics && useExistingWorkspace) {
  name: 'diag-workspace-to-law'
  scope: workspaces[index]
  properties: {
    workspaceId: existingWorkspaceResourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

#disable-next-line use-recent-api-versions
resource applicationGroupDiagnosticsCreatedWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (applicationGroupName, index) in applicationGroupNames: if (enableApplicationGroupDiagnostics && useCreatedWorkspace) {
  name: 'diag-appgroup-to-law'
  scope: applicationGroups[index]
  properties: {
    workspaceId: logAnalytics!.outputs.resourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

#disable-next-line use-recent-api-versions
resource applicationGroupDiagnosticsExistingWorkspace 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (applicationGroupName, index) in applicationGroupNames: if (enableApplicationGroupDiagnostics && useExistingWorkspace) {
  name: 'diag-appgroup-to-law'
  scope: applicationGroups[index]
  properties: {
    workspaceId: existingWorkspaceResourceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}]

output workspaceId string = effectiveWorkspaceId
output workspaceName string = useCreatedWorkspace ? logAnalytics!.outputs.name : last(split(existingWorkspaceResourceId, '/'))
output hostPoolDiagnosticsEnabled bool = enableHostPoolDiagnostics && (useCreatedWorkspace || useExistingWorkspace)
output monitoredWorkspaceCount int = enableWorkspaceDiagnostics && (useCreatedWorkspace || useExistingWorkspace) ? length(workspaceNames) : 0
output monitoredApplicationGroupCount int = enableApplicationGroupDiagnostics && (useCreatedWorkspace || useExistingWorkspace) ? length(applicationGroupNames) : 0
