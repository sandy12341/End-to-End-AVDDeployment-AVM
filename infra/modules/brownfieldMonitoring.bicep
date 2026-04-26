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

@description('Monitoring posture scope for brownfield alignment.')
@allowed(['ControlPlaneOnly', 'FullMonitoringPosture'])
param monitoringScope string = 'ControlPlaneOnly'

@description('Resource group name that contains the existing session host VMs to onboard for guest monitoring.')
param sessionHostVmResourceGroupName string = ''

@description('Session host VM names discovered from the selected host pool and targeted for guest monitoring onboarding.')
param sessionHostVmNames array = []

@description('Data Collection Rule name used when full monitoring posture is selected.')
param dataCollectionRuleName string = 'dcr-avd-brownfield'

@description('Guest telemetry preset used when full monitoring posture is selected.')
@allowed(['Standard', 'Enhanced'])
param monitoringPreset string = 'Enhanced'

@description('Whether to enable host pool diagnostic settings.')
param enableHostPoolDiagnostics bool = true

@description('Whether to enable workspace diagnostic settings.')
param enableWorkspaceDiagnostics bool = true

@description('Whether to enable application group diagnostic settings.')
param enableApplicationGroupDiagnostics bool = true

@description('Tags for created resources.')
param tags object = {}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = if (createWorkspace && monitoringScope == 'ControlPlaneOnly') {
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
var enableGuestMonitoring = monitoringScope == 'FullMonitoringPosture' && (useCreatedWorkspace || useExistingWorkspace)
var effectiveSessionHostVmResourceGroupName = empty(sessionHostVmResourceGroupName) ? resourceGroup().name : sessionHostVmResourceGroupName
var guestMonitoringIndexes = enableGuestMonitoring ? range(0, length(sessionHostVmNames)) : []

module guestMonitoringWorkspace './monitoring.bicep' = if (enableGuestMonitoring) {
  name: take('brownfield-guest-monitoring-${hostPoolName}', 64)
  params: {
    location: location
    workspaceName: workspaceName
    existingWorkspaceResourceId: existingWorkspaceResourceId
    retentionDays: retentionDays
    dataCollectionRuleName: dataCollectionRuleName
    monitoringPreset: monitoringPreset
    tags: tags
  }
}

#disable-next-line BCP318
var effectiveWorkspaceId = enableGuestMonitoring ? guestMonitoringWorkspace!.outputs.workspaceId : (useCreatedWorkspace ? logAnalytics!.outputs.resourceId : existingWorkspaceResourceId)

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = {
  name: hostPoolName
}

resource workspaces 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' existing = [for workspaceNameItem in workspaceNames: {
  name: workspaceNameItem
}]

resource applicationGroups 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' existing = [for applicationGroupName in applicationGroupNames: {
  name: applicationGroupName
}]

module guestMonitoringAssociation './existingVmMonitoringAssociation.bicep' = [for index in guestMonitoringIndexes: {
  name: take('existing-vm-monitoring-${sessionHostVmNames[index]}', 64)
  scope: resourceGroup(effectiveSessionHostVmResourceGroupName)
  params: {
    location: location
    vmName: sessionHostVmNames[index]
    #disable-next-line BCP318
    dataCollectionRuleId: guestMonitoringWorkspace!.outputs.dataCollectionRuleId
    tags: tags
  }
}]

#disable-next-line use-recent-api-versions
resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableHostPoolDiagnostics && (useCreatedWorkspace || useExistingWorkspace)) {
  name: 'diag-hostpool-to-law'
  scope: hostPool
  properties: {
    workspaceId: effectiveWorkspaceId
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
resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (workspaceNameItem, index) in workspaceNames: if (enableWorkspaceDiagnostics && (useCreatedWorkspace || useExistingWorkspace)) {
  name: 'diag-workspace-to-law'
  scope: workspaces[index]
  properties: {
    workspaceId: effectiveWorkspaceId
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
resource applicationGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [for (applicationGroupName, index) in applicationGroupNames: if (enableApplicationGroupDiagnostics && (useCreatedWorkspace || useExistingWorkspace)) {
  name: 'diag-appgroup-to-law'
  scope: applicationGroups[index]
  properties: {
    workspaceId: effectiveWorkspaceId
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
#disable-next-line BCP318
output workspaceName string = enableGuestMonitoring ? guestMonitoringWorkspace!.outputs.workspaceName : (useCreatedWorkspace ? logAnalytics!.outputs.name : last(split(existingWorkspaceResourceId, '/')))
output hostPoolDiagnosticsEnabled bool = enableHostPoolDiagnostics && (useCreatedWorkspace || useExistingWorkspace)
output monitoredWorkspaceCount int = enableWorkspaceDiagnostics && (useCreatedWorkspace || useExistingWorkspace) ? length(workspaceNames) : 0
output monitoredApplicationGroupCount int = enableApplicationGroupDiagnostics && (useCreatedWorkspace || useExistingWorkspace) ? length(applicationGroupNames) : 0
output guestMonitoringEnabled bool = enableGuestMonitoring
output guestMonitoringSessionHostCount int = enableGuestMonitoring ? length(sessionHostVmNames) : 0
#disable-next-line BCP318
output dataCollectionRuleId string = enableGuestMonitoring ? guestMonitoringWorkspace!.outputs.dataCollectionRuleId : 'N/A'
