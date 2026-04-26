@description('Azure region')
param location string

@description('Log Analytics workspace name')
param workspaceName string = ''

@description('Existing Log Analytics workspace resource ID to reuse instead of creating a new workspace.')
param existingWorkspaceResourceId string = ''

@description('Retention in days')
param retentionDays int = 30

@description('Data Collection Rule name for guest telemetry')
param dataCollectionRuleName string = 'dcr-avd-monitoring'

@description('Guest telemetry preset for the Azure Virtual Desktop operations baseline.')
@allowed(['Standard', 'Enhanced'])
param monitoringPreset string = 'Enhanced'

@description('Tags for all resources')
param tags object = {}

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = if (empty(existingWorkspaceResourceId)) {
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

var effectiveWorkspaceId = empty(existingWorkspaceResourceId) ? logAnalytics!.outputs.resourceId : existingWorkspaceResourceId
var isEnhancedPreset = monitoringPreset == 'Enhanced'

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: dataCollectionRuleName
  location: location
  tags: tags
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          name: 'vmInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
            'Microsoft-Perf'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: isEnhancedPreset ? [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\System\\Processor Queue Length'
            '\\Memory\\Available MBytes'
            '\\Memory\\% Committed Bytes In Use'
            '\\Memory\\Pages/sec'
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Read'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Write'
            '\\LogicalDisk(_Total)\\Disk Bytes/sec'
            '\\LogicalDisk(_Total)\\Disk Transfers/sec'
            '\\LogicalDisk(_Total)\\Current Disk Queue Length'
            '\\LogicalDisk(*)\\% Free Space'
            '\\Network Interface(*)\\Bytes Total/sec'
            '\\Network Interface(*)\\Output Queue Length'
            '\\Network Interface(*)\\Packets Outbound Errors'
            '\\Network Interface(*)\\Packets Received Errors'
          ] : [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\System\\Processor Queue Length'
            '\\Memory\\Available MBytes'
            '\\Memory\\% Committed Bytes In Use'
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer'
            '\\LogicalDisk(_Total)\\Disk Transfers/sec'
            '\\Network Interface(*)\\Bytes Total/sec'
          ]
        }
      ]
      windowsEventLogs: [
        {
          name: 'vmInsightsWindowsEvents'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: isEnhancedPreset ? [
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
            'Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
            'Microsoft-Windows-User Profile Service/Operational!*[System[(Level=1 or Level=2 or Level=3 or Level=4)]]'
          ] : [
            'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
            'System!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-FSLogix-Apps/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
            'Microsoft-Windows-User Profile Service/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'logAnalyticsDestination'
          workspaceResourceId: effectiveWorkspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'logAnalyticsDestination'
        ]
      }
      {
        streams: [
          'Microsoft-Perf'
        ]
        destinations: [
          'logAnalyticsDestination'
        ]
      }
      {
        streams: [
          'Microsoft-Event'
        ]
        destinations: [
          'logAnalyticsDestination'
        ]
      }
    ]
  }
}

output workspaceId string = effectiveWorkspaceId
output workspaceName string = empty(existingWorkspaceResourceId) ? logAnalytics!.outputs.name : last(split(existingWorkspaceResourceId, '/'))
output dataCollectionRuleId string = dataCollectionRule.id
output dataCollectionRuleName string = dataCollectionRule.name
