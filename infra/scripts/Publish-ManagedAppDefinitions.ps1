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

    [Parameter(Mandatory)]
    [string]$AddSessionHostsPackageFileUri,

    [Parameter(Mandatory)]
    [string]$ScalingPackageFileUri,

    [Parameter(Mandatory)]
    [string]$MonitoringPackageFileUri,

    [Parameter(Mandatory)]
    [string]$SummaryPackageFileUri,

    [string]$NewEnvironmentDefinitionName = 'avd-new-environment-avm',
    [string]$ExistingEnvironmentDefinitionName = 'avd-manage-existing-avm',
    [string]$Day2DefinitionName = 'avd-day2-operations-avm',
    [string]$AddSessionHostsDefinitionName = 'avd-add-session-hosts-avm',
    [string]$ScalingDefinitionName = 'avd-configure-scaling-avm',
    [string]$MonitoringDefinitionName = 'avd-align-monitoring-avm',
    [string]$SummaryDefinitionName = 'avd-operational-summary-avm',
    [string]$RoleDefinitionId = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635',
    [string]$LockLevel = 'ReadOnly',
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$templateFile = Join-Path $repoRoot 'infra\managedapp\deployDefinitions.bicep'
$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) ('managedapp-definitions.{0}.parameters.json' -f ([guid]::NewGuid().ToString('N')))

az group create --name $ResourceGroupName --location $Location | Out-Null

$deploymentName = 'managedapp-definitions'
$parametersPayload = @{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = @{
        location = @{ value = $Location }
        principalId = @{ value = $PrincipalId }
        roleDefinitionId = @{ value = $RoleDefinitionId }
        lockLevel = @{ value = $LockLevel }
        newEnvironmentDefinitionName = @{ value = $NewEnvironmentDefinitionName }
        newEnvironmentPackageFileUri = @{ value = $NewEnvironmentPackageFileUri }
        existingEnvironmentDefinitionName = @{ value = $ExistingEnvironmentDefinitionName }
        existingEnvironmentPackageFileUri = @{ value = $ExistingEnvironmentPackageFileUri }
        day2DefinitionName = @{ value = $Day2DefinitionName }
        day2PackageFileUri = @{ value = $Day2PackageFileUri }
        addSessionHostsDefinitionName = @{ value = $AddSessionHostsDefinitionName }
        addSessionHostsPackageFileUri = @{ value = $AddSessionHostsPackageFileUri }
        scalingDefinitionName = @{ value = $ScalingDefinitionName }
        scalingPackageFileUri = @{ value = $ScalingPackageFileUri }
        monitoringDefinitionName = @{ value = $MonitoringDefinitionName }
        monitoringPackageFileUri = @{ value = $MonitoringPackageFileUri }
        summaryDefinitionName = @{ value = $SummaryDefinitionName }
        summaryPackageFileUri = @{ value = $SummaryPackageFileUri }
    }
}

$parametersPayload | ConvertTo-Json -Depth 6 | Set-Content -Path $parametersFile -Encoding utf8

try {
    $arguments = @(
        'deployment', 'group',
        $(if ($WhatIf) { 'what-if' } else { 'create' }),
        '--name', $deploymentName,
        '--resource-group', $ResourceGroupName,
        '--template-file', $templateFile,
        '--parameters', "@$parametersFile"
    )

    Write-Host ("Running: az {0}" -f ($arguments -join ' '))
    & az @arguments
}
finally {
    if (Test-Path $parametersFile) {
        Remove-Item -Path $parametersFile -Force
    }
}