targetScope = 'resourceGroup'

@description('Azure region for the managed application package storage account.')
param location string = resourceGroup().location

@description('Globally unique storage account name for hosting managed application package zip files.')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Virtual path prefix under the static website endpoint used to hold the managed application package zip files.')
@minLength(3)
@maxLength(63)
param containerName string = 'managedapp-packages'

@description('Storage account SKU for managed application package hosting.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
param storageSku string = 'Standard_LRS'

@description('Allow package retrieval over the public network. Keep enabled so Azure can fetch stable package URIs from the storage static website endpoint.')
param publicNetworkAccess string = 'Enabled'

resource packageStorage 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-08-01' = {
  parent: packageStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    isVersioningEnabled: true
    staticWebsite: {
      enabled: true
      indexDocument: 'index.html'
      errorDocument404Path: '404.html'
    }
  }
}

output storageAccountId string = packageStorage.id
output storageAccountName string = packageStorage.name
output blobEndpoint string = packageStorage.properties.primaryEndpoints.blob
output containerName string = '$web'
output containerUri string = '${packageStorage.properties.primaryEndpoints.web}${containerName}'
