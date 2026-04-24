@description('Azure region')
param location string

@description('Storage account name for FSLogix profiles')
param storageAccountName string

@description('File share name')
param fileShareName string = 'fslogix-profiles'

@description('File share quota in GB')
param fileShareQuotaGiB int = 100

@description('Tags for all resources')
param tags object = {}

@description('Session host subnet ID for VNet service endpoint access (used when deployPrivateEndpoint is false)')
param sessionHostSubnetId string = ''

@description('When true, disables public network access on the storage account. A private endpoint must be deployed separately.')
param deployPrivateEndpoint bool = false

// When using a private endpoint, public access is fully disabled and VNet rules are not needed.
// When using a service endpoint, the session host subnet is whitelisted via virtualNetworkRules.
var storageNetworkAcls = deployPrivateEndpoint
  ? {
      defaultAction: 'Deny'
      bypass: 'None'
      virtualNetworkRules: []
    }
  : {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: !empty(sessionHostSubnetId)
        ? [
            {
              id: sessionHostSubnetId
              action: 'Allow'
            }
          ]
        : []
    }

module storageAccount 'br/public:avm/res/storage/storage-account:0.29.0' = {
  name: take('avm.res.storage.storage-account.${storageAccountName}', 64)
  params: {
    name: storageAccountName
    location: location
    tags: tags
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: deployPrivateEndpoint ? 'Disabled' : 'Enabled'
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'AADKERB'
    }
    networkAcls: storageNetworkAcls
    blobServices: {}
    fileServices: {
      shares: [
        {
          name: fileShareName
          enabledProtocols: 'SMB'
          shareQuota: fileShareQuotaGiB
        }
      ]
    }
    enableTelemetry: false
  }
}

output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
output fileShareName string = fileShareName
