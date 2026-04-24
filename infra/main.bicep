// Thin engineering wrapper over the shared solution core.

targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Deployment prefix used for naming')
@maxLength(6)
param deploymentPrefix string = 'avd1'

@description('Environment name')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Number of session host VMs')
@minValue(1)
@maxValue(10)
param sessionHostCount int = 1

@description('VM size for session hosts')
param vmSize string = 'Standard_D2ads_v5'

@description('Image source for the session host OS image.')
@allowed(['Marketplace', 'AzureComputeGallery'])
param imageSource string = 'Marketplace'

@description('Marketplace image publisher for session hosts when imageSource is Marketplace.')
param marketplaceImagePublisher string = 'microsoftwindowsdesktop'

@description('Marketplace image offer for session hosts when imageSource is Marketplace.')
param marketplaceImageOffer string = 'windows-11'

@description('Marketplace image SKU for session hosts when imageSource is Marketplace.')
param marketplaceImageSku string = 'win11-24h2-avd'

@description('Marketplace image version for session hosts when imageSource is Marketplace.')
param marketplaceImageVersion string = 'latest'

@description('Azure Compute Gallery subscription ID for session hosts when imageSource is AzureComputeGallery.')
param galleryImageSubscriptionId string = subscription().subscriptionId

@description('Azure Compute Gallery resource group name for session hosts when imageSource is AzureComputeGallery.')
param galleryImageResourceGroupName string = ''

@description('Azure Compute Gallery name for session hosts when imageSource is AzureComputeGallery.')
param galleryName string = ''

@description('Azure Compute Gallery image definition name for session hosts when imageSource is AzureComputeGallery.')
param galleryImageDefinitionName string = ''

@description('Azure Compute Gallery image version for session hosts when imageSource is AzureComputeGallery.')
param galleryImageVersion string = 'latest'

@description('Session host security type. Auto uses Trusted Launch for Azure Compute Gallery images and Standard for Marketplace images.')
@allowed(['Auto', 'Standard', 'TrustedLaunch'])
param sessionHostSecurityType string = 'Auto'

@description('Preferred AVD delivery mode. Leave empty to preserve the legacy desktop-only behavior driven by hostPoolType.')
@allowed(['', 'PersonalDesktop', 'PooledRemoteApp', 'PooledDesktopAndRemoteApp'])
param avdMode string = ''

@description('Host pool type')
@allowed(['Personal', 'Pooled'])
param hostPoolType string = 'Pooled'

@description('Authentication type for session host sign-in and join flow')
@allowed(['EntraID', 'HybridJoin'])
param authenticationType string = 'EntraID'

@description('Active Directory domain FQDN (required for HybridJoin)')
param domainFqdn string = ''

@description('Domain join service account in DOMAIN\\username or username@domain format (required for HybridJoin)')
param domainJoinUsername string = ''

@description('Domain join service account password (required for HybridJoin)')
@secure()
param domainJoinPassword string = ''

@description('Optional OU path where computer accounts should be created for HybridJoin (for example OU=AVD,DC=contoso,DC=com)')
param domainJoinOuPath string = ''

@description('Local admin username for session hosts')
param adminUsername string

@description('Local admin password for session hosts')
@secure()
param adminPassword string

@description('Deploy FSLogix profile storage')
param deployFSLogix bool = true

@description('Storage account name for FSLogix profiles (must be globally unique, 3-24 chars, lowercase/numbers only)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Deploy monitoring (Log Analytics)')
param deployMonitoring bool = true

@description('Deploy a private endpoint for the FSLogix storage account and disable public network access. Requires a private endpoint subnet (created automatically in Greenfield mode).')
param deployFSLogixPrivateEndpoint bool = false

@description('Choose whether to use an existing VNet or create a new spoke VNet for the deployment.')
@allowed(['UseExistingVnet', 'CreateNewVnet'])
param networkMode string = 'UseExistingVnet'

@description('Name of the existing virtual network to use')
param existingVnetName string = ''

@description('Resource group name that contains the existing virtual network')
param existingVnetResourceGroupName string = resourceGroup().name

@description('Name of the existing subnet for session hosts')
param sessionHostSubnetName string = ''

@description('Name of the existing subnet reserved for private endpoints')
param privateEndpointSubnetName string = ''

@description('Name of the new spoke virtual network to create when networkMode is CreateNewVnet.')
param newVnetName string = ''

@description('Address prefix for the new spoke virtual network when networkMode is CreateNewVnet.')
param newVnetAddressPrefix string = '10.20.0.0/16'

@description('Name of the session host subnet to create when networkMode is CreateNewVnet.')
param newSessionHostSubnetName string = 'snet-avd-sessionhosts'

@description('Address prefix for the session host subnet when networkMode is CreateNewVnet.')
param newSessionHostSubnetPrefix string = '10.20.1.0/24'

@description('Name of the private endpoint subnet to create when networkMode is CreateNewVnet.')
param newPrivateEndpointSubnetName string = 'snet-avd-privateendpoints'

@description('Address prefix for the private endpoint subnet when networkMode is CreateNewVnet.')
param newPrivateEndpointSubnetPrefix string = '10.20.2.0/24'

@description('Resource ID of the existing hub virtual network to peer with when networkMode is CreateNewVnet.')
param hubVnetResourceId string = ''

@description('Host pool name')
param hostPoolName string

@description('Comma or newline separated Entra Object IDs to grant AVD access. Leave empty to skip role assignments.')
param avdUserObjectIds string = ''

@description('Typed access assignments for the desktop application group. Each item must include principalId and principalType.')
param desktopAccessAssignments array = []

@description('Typed access assignments for the RemoteApp application group. Each item must include principalId and principalType.')
param remoteAppAccessAssignments array = []

@description('RemoteApp definitions used when avdMode publishes RemoteApps. Each item must include name and filePath and can optionally include friendlyName, description, commandLineSetting, and commandLineArguments.')
param remoteApps array = []

@description('Per-deployment seed used to keep session host computer names unique across redeployments in the same resource group.')
param deploymentInstanceSeed string = utcNow('u')

module sharedSolution './solution/avdDeploymentCore.bicep' = {
  name: 'avd-solution'
  params: {
    location: location
    deploymentPrefix: deploymentPrefix
    environment: environment
    sessionHostCount: sessionHostCount
    vmSize: vmSize
    imageSource: imageSource
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImageSku: marketplaceImageSku
    marketplaceImageVersion: marketplaceImageVersion
    galleryImageSubscriptionId: galleryImageSubscriptionId
    galleryImageResourceGroupName: galleryImageResourceGroupName
    galleryName: galleryName
    galleryImageDefinitionName: galleryImageDefinitionName
    galleryImageVersion: galleryImageVersion
    sessionHostSecurityType: sessionHostSecurityType
    avdMode: avdMode
    hostPoolType: hostPoolType
    authenticationType: authenticationType
    domainFqdn: domainFqdn
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    domainJoinOuPath: domainJoinOuPath
    adminUsername: adminUsername
    adminPassword: adminPassword
    deployFSLogix: deployFSLogix
    storageAccountName: storageAccountName
    deployMonitoring: deployMonitoring
    deployFSLogixPrivateEndpoint: deployFSLogixPrivateEndpoint
    networkMode: networkMode
    existingVnetName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    sessionHostSubnetName: sessionHostSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
    newVnetName: newVnetName
    newVnetAddressPrefix: newVnetAddressPrefix
    newSessionHostSubnetName: newSessionHostSubnetName
    newSessionHostSubnetPrefix: newSessionHostSubnetPrefix
    newPrivateEndpointSubnetName: newPrivateEndpointSubnetName
    newPrivateEndpointSubnetPrefix: newPrivateEndpointSubnetPrefix
    hubVnetResourceId: hubVnetResourceId
    hostPoolName: hostPoolName
    avdUserObjectIds: avdUserObjectIds
    desktopAccessAssignments: desktopAccessAssignments
    remoteAppAccessAssignments: remoteAppAccessAssignments
    remoteApps: remoteApps
    deploymentInstanceSeed: deploymentInstanceSeed
  }
}

output hostPoolName string = sharedSolution.outputs.hostPoolName
output workspaceId string = sharedSolution.outputs.workspaceId
output desktopAppGroupId string = sharedSolution.outputs.desktopAppGroupId
output remoteAppGroupId string = sharedSolution.outputs.remoteAppGroupId
output publishedAppGroupIds array = sharedSolution.outputs.publishedAppGroupIds
output vnetId string = sharedSolution.outputs.vnetId
output privateEndpointSubnetId string = sharedSolution.outputs.privateEndpointSubnetId
output sessionHostVmNames array = sharedSolution.outputs.sessionHostVmNames
output fslogixStorageAccount string = sharedSolution.outputs.fslogixStorageAccount
output fslogixPrivateEndpointId string = sharedSolution.outputs.fslogixPrivateEndpointId
output logAnalyticsWorkspace string = sharedSolution.outputs.logAnalyticsWorkspace
output logAnalyticsWorkspaceId string = sharedSolution.outputs.logAnalyticsWorkspaceId
output monitoringDataCollectionRuleId string = sharedSolution.outputs.monitoringDataCollectionRuleId
output effectiveAvdMode string = sharedSolution.outputs.effectiveAvdMode
output avdRolesAssigned bool = sharedSolution.outputs.avdRolesAssigned
