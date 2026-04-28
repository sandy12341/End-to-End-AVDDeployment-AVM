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

@description('Name of the dedicated add-session-hosts managed application definition')
param addSessionHostsDefinitionName string = 'avd-add-session-hosts-avm'

@description('Display name shown in the Azure service catalog for the dedicated add-session-hosts entrypoint')
param addSessionHostsDefinitionDisplayName string = 'Add Session Hosts - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the dedicated add-session-hosts entrypoint')
param addSessionHostsDefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for expanding an existing host pool with additional session hosts using an existing VNet and subnet.'

@description('URI of the managed application package zip file for the dedicated add-session-hosts entrypoint')
param addSessionHostsPackageFileUri string

@description('Name of the dedicated scaling-plan managed application definition')
param scalingDefinitionName string = 'avd-configure-scaling-avm'

@description('Display name shown in the Azure service catalog for the dedicated scaling-plan entrypoint')
param scalingDefinitionDisplayName string = 'Configure Scaling Plan - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the dedicated scaling-plan entrypoint')
param scalingDefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for creating or updating a scaling plan attachment on an existing pooled host pool.'

@description('URI of the managed application package zip file for the dedicated scaling-plan entrypoint')
param scalingPackageFileUri string

@description('Name of the dedicated monitoring-alignment managed application definition')
param monitoringDefinitionName string = 'avd-align-monitoring-avm'

@description('Display name shown in the Azure service catalog for the dedicated monitoring-alignment entrypoint')
param monitoringDefinitionDisplayName string = 'Align Monitoring Posture - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the dedicated monitoring-alignment entrypoint')
param monitoringDefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for aligning control-plane and optional guest monitoring posture on an existing host pool.'

@description('URI of the managed application package zip file for the dedicated monitoring-alignment entrypoint')
param monitoringPackageFileUri string

@description('Name of the dedicated operational-summary managed application definition')
param summaryDefinitionName string = 'avd-operational-summary-avm'

@description('Display name shown in the Azure service catalog for the dedicated operational-summary entrypoint')
param summaryDefinitionDisplayName string = 'Generate Operational Summary - Azure Virtual Desktop + ALZ (AVM)'

@description('Description shown in the Azure service catalog for the dedicated operational-summary entrypoint')
param summaryDefinitionDescription string = 'Azure Virtual Desktop AVM managed application entrypoint for a read-only operational summary against an existing host pool, with optional FSLogix posture enrichment.'

@description('URI of the managed application package zip file for the dedicated operational-summary entrypoint')
param summaryPackageFileUri string

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

module addSessionHostsDefinition './deployDefinition.bicep' = {
  name: 'addSessionHostsDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: addSessionHostsDefinitionName
    definitionDisplayName: addSessionHostsDefinitionDisplayName
    definitionDescription: addSessionHostsDefinitionDescription
    packageFileUri: addSessionHostsPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

module scalingDefinition './deployDefinition.bicep' = {
  name: 'scalingDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: scalingDefinitionName
    definitionDisplayName: scalingDefinitionDisplayName
    definitionDescription: scalingDefinitionDescription
    packageFileUri: scalingPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

module monitoringDefinition './deployDefinition.bicep' = {
  name: 'monitoringDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: monitoringDefinitionName
    definitionDisplayName: monitoringDefinitionDisplayName
    definitionDescription: monitoringDefinitionDescription
    packageFileUri: monitoringPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

module summaryDefinition './deployDefinition.bicep' = {
  name: 'summaryDefinition'
  params: {
    location: location
    managedApplicationDefinitionName: summaryDefinitionName
    definitionDisplayName: summaryDefinitionDisplayName
    definitionDescription: summaryDefinitionDescription
    packageFileUri: summaryPackageFileUri
    principalId: principalId
    roleDefinitionId: roleDefinitionId
    lockLevel: lockLevel
  }
}

output newEnvironmentDefinitionId string = newEnvironmentDefinition.outputs.managedApplicationDefinitionId
output existingEnvironmentDefinitionId string = existingEnvironmentDefinition.outputs.managedApplicationDefinitionId
output day2DefinitionId string = day2Definition.outputs.managedApplicationDefinitionId
output addSessionHostsDefinitionId string = addSessionHostsDefinition.outputs.managedApplicationDefinitionId
output scalingDefinitionId string = scalingDefinition.outputs.managedApplicationDefinitionId
output monitoringDefinitionId string = monitoringDefinition.outputs.managedApplicationDefinitionId
output summaryDefinitionId string = summaryDefinition.outputs.managedApplicationDefinitionId
