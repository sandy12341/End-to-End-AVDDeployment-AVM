[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string]$PrincipalId,

    [Parameter(Mandatory)]
    [string]$NewEnvironmentPackageFileUri,

    [Parameter(Mandatory)]
    [string]$ExistingEnvironmentPackageFileUri,

    [Parameter(Mandatory)]
    [string]$Day2PackageFileUri,

    [string]$NewEnvironmentDefinitionName = 'avd-new-environment-avm',
    [string]$ExistingEnvironmentDefinitionName = 'avd-manage-existing-avm',
    [string]$Day2DefinitionName = 'avd-day2-operations-avm',
    [string]$RoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635',
    [string]$LockLevel = 'ReadOnly',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$templateFile = Join-Path $repoRoot 'infra\managedapp\deployDefinitions.bicep'

az group create --name $ResourceGroupName --location $Location | Out-Null

$deploymentName = 'managedapp-definitions'
$arguments = @(
    'deployment', 'group',
    $(if ($WhatIf) { 'what-if' } else { 'create' }),
    '--name', $deploymentName,
    '--resource-group', $ResourceGroupName,
    '--template-file', $templateFile,
    '--parameters',
    "location=$Location",
    "principalId=$PrincipalId",
    "roleDefinitionId=$RoleDefinitionId",
    "lockLevel=$LockLevel",
    "newEnvironmentDefinitionName=$NewEnvironmentDefinitionName",
    "newEnvironmentPackageFileUri=$NewEnvironmentPackageFileUri",
    "existingEnvironmentDefinitionName=$ExistingEnvironmentDefinitionName",
    "existingEnvironmentPackageFileUri=$ExistingEnvironmentPackageFileUri",
    "day2DefinitionName=$Day2DefinitionName",
    "day2PackageFileUri=$Day2PackageFileUri"
)

Write-Host ("Running: az {0}" -f ($arguments -join ' '))
& az @arguments