targetScope = 'resourceGroup'

@description('Azure region for the VM extension deployment.')
param location string

@description('Existing virtual machine name to onboard to guest monitoring.')
param vmName string

@description('Data Collection Rule resource ID to associate with the VM.')
param dataCollectionRuleId string

@description('Tags applied to the VM extension resources.')
param tags object = {}

resource existingVm 'Microsoft.Compute/virtualMachines@2024-07-01' existing = {
  name: vmName
}

resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: existingVm
  name: 'AzureMonitorWindowsAgent'
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource monitoringRuleAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2024-03-11' = {
  scope: existingVm
  name: 'vm-monitoring-association'
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
    description: 'Associates the session host with the brownfield monitoring rule.'
  }
  dependsOn: [
    azureMonitorAgent
  ]
}