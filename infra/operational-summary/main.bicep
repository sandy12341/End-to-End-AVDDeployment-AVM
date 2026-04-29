targetScope = 'resourceGroup'

@description('Azure region for the Operational Summary collector resources.')
param location string = resourceGroup().location

@description('Short workload name used as a prefix for collector resources.')
@minLength(3)
param workloadName string = 'avd-ops-summary'

@description('Report container name in the private report storage account.')
param reportContainerName string = 'operational-summaries'

@description('Virtual folder prefix for generated report artifacts.')
param reportPathPrefix string = 'operational-summary'

@description('Existing user-assigned managed identity resource ID for the collector. Leave empty to create a dedicated collector identity.')
param existingCollectorIdentityResourceId string = ''

@description('Client ID of the existing collector managed identity. Required when existingCollectorIdentityResourceId is provided.')
param existingCollectorIdentityClientId string = ''

@description('Principal ID of the existing collector managed identity. Required when existingCollectorIdentityResourceId is provided so storage role assignments can be created.')
param existingCollectorIdentityPrincipalId string = ''

@description('Enable an Event Grid webhook subscription that invokes the collector when Microsoft.Solutions/applications write events occur in this subscription.')
param enableManagedAppEventGridTrigger bool = false

@description('Event Grid system topic name used for managed application resource events when Event Grid trigger is enabled.')
param managedAppEventGridSystemTopicName string = ''

@description('Event Grid subscription name used for managed application resource events when Event Grid trigger is enabled.')
param managedAppEventSubscriptionName string = ''

@description('Tags applied to collector resources.')
param tags object = {
  Project: 'AVD-Landing-Zone'
  Workload: 'OperationalSummaryCollector'
}

var suffix = take(uniqueString(resourceGroup().id, workloadName), 8)
var identityName = 'id-${workloadName}-${suffix}'
var storageName = 'stops${suffix}'
var workspaceName = 'law-${workloadName}-${suffix}'
var appInsightsName = 'appi-${workloadName}-${suffix}'
var planName = 'asp-${workloadName}-${suffix}'
var functionAppName = 'func-${workloadName}-${suffix}'
var managedAppEventWebhookFunctionResourceId = resourceId('Microsoft.Web/sites/functions', functionAppName, 'GenerateOperationalSummaryFromManagedAppEvent')
var managedAppEventWebhookFunctionApiVersion = '2024-04-01'
var resolvedManagedAppEventGridSystemTopicName = empty(managedAppEventGridSystemTopicName) ? 'egst-${workloadName}-${suffix}' : managedAppEventGridSystemTopicName
var resolvedManagedAppEventSubscriptionName = empty(managedAppEventSubscriptionName) ? 'evs-${workloadName}-${suffix}' : managedAppEventSubscriptionName
var useExistingCollectorIdentity = !empty(existingCollectorIdentityResourceId)
var collectorIdentityResourceId = useExistingCollectorIdentity ? existingCollectorIdentityResourceId : collectorIdentity.id
var collectorIdentityClientId = useExistingCollectorIdentity ? existingCollectorIdentityClientId : collectorIdentity!.properties.clientId
var collectorIdentityPrincipalId = useExistingCollectorIdentity ? existingCollectorIdentityPrincipalId : collectorIdentity!.properties.principalId
var collectorIdentityDisplayName = useExistingCollectorIdentity ? last(split(existingCollectorIdentityResourceId, '/')) : collectorIdentity.name

var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var storageQueueDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
var storageTableDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')

resource collectorIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if (!useExistingCollectorIdentity) {
  name: identityName
  location: location
  tags: tags
}

resource reportStorage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: reportStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource reportContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: reportContainerName
  properties: {
    publicAccess: 'None'
  }
}

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
    DisableLocalAuth: true
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-11-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${collectorIdentityResourceId}': {}
    }
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: reportStorage.name
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: collectorIdentityClientId
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'ReportStorageAccountName'
          value: reportStorage.name
        }
        {
          name: 'ReportContainerName'
          value: reportContainer.name
        }
        {
          name: 'OPERATIONAL_SUMMARY_REPORT_CONTAINER_URI'
          value: '${reportStorage.properties.primaryEndpoints.blob}${reportContainer.name}'
        }
        {
          name: 'OPERATIONAL_SUMMARY_REPORT_PATH_PREFIX'
          value: reportPathPrefix
        }
      ]
    }
  }
}

resource storageBlobDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(reportStorage.id, collectorIdentityResourceId, 'Storage Blob Data Contributor')
  scope: reportStorage
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: collectorIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageQueueDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(reportStorage.id, collectorIdentityResourceId, 'Storage Queue Data Contributor')
  scope: reportStorage
  properties: {
    roleDefinitionId: storageQueueDataContributorRoleId
    principalId: collectorIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource storageTableDataContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(reportStorage.id, collectorIdentityResourceId, 'Storage Table Data Contributor')
  scope: reportStorage
  properties: {
    roleDefinitionId: storageTableDataContributorRoleId
    principalId: collectorIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource managedAppSystemTopic 'Microsoft.EventGrid/systemTopics@2025-02-15' = if (enableManagedAppEventGridTrigger) {
  name: resolvedManagedAppEventGridSystemTopicName
  location: 'global'
  tags: tags
  properties: {
    source: subscription().id
    topicType: 'Microsoft.Resources.Subscriptions'
  }
}

resource managedAppEventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2025-02-15' = if (enableManagedAppEventGridTrigger) {
  parent: managedAppSystemTopic
  name: resolvedManagedAppEventSubscriptionName
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: 'https://${functionApp.properties.defaultHostName}/api/operational-summary/managed-app-events?code=${listKeys(managedAppEventWebhookFunctionResourceId, managedAppEventWebhookFunctionApiVersion).default}'
        maxEventsPerBatch: 1
        preferredBatchSizeInKilobytes: 64
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      includedEventTypes: [
        'Microsoft.Resources.ResourceWriteSuccess'
      ]
      subjectBeginsWith: '${subscription().id}/resourceGroups/'
      advancedFilters: [
        {
          operatorType: 'StringIn'
          key: 'data.operationName'
          values: [
            'Microsoft.Solutions/applications/write'
          ]
        }
      ]
    }
    retryPolicy: {
      maxDeliveryAttempts: 12
      eventTimeToLiveInMinutes: 1440
    }
  }
}

output functionAppName string = functionApp.name
output functionAppResourceId string = functionApp.id
output collectorIdentityName string = collectorIdentityDisplayName
output collectorIdentityClientId string = collectorIdentityClientId
output collectorIdentityPrincipalId string = collectorIdentityPrincipalId
output collectorIdentityResourceId string = collectorIdentityResourceId
output reportStorageAccountName string = reportStorage.name
output reportContainerName string = reportContainer.name
output managedAppEventGridSystemTopicId string = enableManagedAppEventGridTrigger ? managedAppSystemTopic!.id : ''
output managedAppEventSubscriptionId string = enableManagedAppEventGridTrigger ? managedAppEventSubscription!.id : ''
output targetDiscoveryRoleGuidance string = 'Assign Reader plus roleAssignments/read-capable access, such as Reader with Microsoft.Authorization/roleAssignments/read or an approved custom role, at the target AVD resource group or subscription scope.'
output graphGroupValidationGuidance string = 'Grant the collector managed identity approved Microsoft Graph application permission Group.Read.All to validate assigned group principals. Without it, reports mark group validation as NotReadable instead of NotFound.'
