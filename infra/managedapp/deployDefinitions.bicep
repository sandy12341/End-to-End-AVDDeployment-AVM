targetScope = 'resourceGroup'

@description('Azure region for the managed application definitions')
param location string = resourceGroup().location

@description('Principal ID that receives access to the managed resource group')
param principalId string

@description('Role definition ID granted to the managing principal')
param roleDefinitionId string = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'

@description('Managed resource group lock level')
@allowed(['ReadOnly'])
param lockLevel string = 'ReadOnly'

@description('Name of the greenfield managed application definition')
param newEnvironmentDefinitionName string = 'avd-new-environment-avm'

@description('Display name shown in the Azure service catalog for the greenfield entrypoint')
param newEnvironmentDefinitionDisplayName string = 'Deploy New Environment - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the greenfield entrypoint')
param newEnvironmentDefinitionDescription string = 'Azure Virtual Desktop AVM modernization deployment for new environment creation and engineering-aligned greenfield validation.'

@description('URI of the managed application package zip file for the greenfield entrypoint')
param newEnvironmentPackageFileUri string

@description('Name of the existing-environment managed application definition')
param existingEnvironmentDefinitionName string = 'avd-manage-existing-avm'

@description('Display name shown in the Azure service catalog for the existing-environment entrypoint')
param existingEnvironmentDefinitionDisplayName string = 'Manage Existing AVD - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the existing-environment entrypoint')
param existingEnvironmentDefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for brownfield expansion and alignment actions against an existing host pool.'

@description('URI of the managed application package zip file for the existing-environment entrypoint')
param existingEnvironmentPackageFileUri string

@description('Name of the day-2 managed application definition')
param day2DefinitionName string = 'avd-day2-operations-avm'

@description('Display name shown in the Azure service catalog for the day-2 entrypoint')
param day2DefinitionDisplayName string = 'Day-2 Operations - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the day-2 entrypoint')
param day2DefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for scoped day-2 operational workflows against an existing host pool.'

@description('URI of the managed application package zip file for the day-2 entrypoint')
param day2PackageFileUri string

module newEnvironmentDefinition './deployDefinition.bicep' = {
  name: 'newEnvironmentDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: newEnvironmentDefinitionName
    definitionDisplayName: newEnvironmentDefinitionDisplayName
    definitionDescription: newEnvironmentDefinitionDescription
    packageFileUri: newEnvironmentPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

module existingEnvironmentDefinition './deployDefinition.bicep' = {
  name: 'existingEnvironmentDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: existingEnvironmentDefinitionName
    definitionDisplayName: existingEnvironmentDefinitionDisplayName
    definitionDescription: existingEnvironmentDefinitionDescription
    packageFileUri: existingEnvironmentPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

module day2Definition './deployDefinition.bicep' = {
  name: 'day2Definition'
  params: {
    location: location
    managedApplicationDefinitionName: day2DefinitionName
    definitionDisplayName: day2DefinitionDisplayName
    definitionDescription: day2DefinitionDescription
    packageFileUri: day2PackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

output newEnvironmentDefinitionId string = newEnvironmentDefinition.outputs.managedApplicationDefinitionId
output existingEnvironmentDefinitionId string = existingEnvironmentDefinition.outputs.managedApplicationDefinitionId
output day2DefinitionId string = day2Definition.outputs.managedApplicationDefinitionId
