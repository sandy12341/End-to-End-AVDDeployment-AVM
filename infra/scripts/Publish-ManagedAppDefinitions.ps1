[CmdletBinding(DefaultParameterSetName = 'PackageStorage')]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$Location,

    [Parameter(Mandatory)]
    [string]$PrincipalId,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$NewEnvironmentPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$ExistingEnvironmentPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$Day2PackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$AddSessionHostsPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$ScalingPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$MonitoringPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'ExplicitUris')]
    [string]$SummaryPackageFileUri,

    [Parameter(Mandatory, ParameterSetName = 'PackageStorage')]
    [string]$PackageStorageAccountName,

    [Parameter(Mandatory, ParameterSetName = 'PackageStorage')]
    [string]$PackageStorageResourceGroup,

    [Parameter(ParameterSetName = 'PackageStorage')]
    [string]$PackageContainerName = 'managedapp-packages',

    [Parameter(ParameterSetName = 'PackageStorage')]
    [string]$PackageStorageLocation = $Location,

    [Parameter(ParameterSetName = 'PackageStorage')]
    [string]$PackageArtifactDirectory,

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
$packageStorageTemplateFile = Join-Path $repoRoot 'infra\managedapp\packageStorage.bicep'
$parametersFile = Join-Path ([System.IO.Path]::GetTempPath()) ('managedapp-definitions.{0}.parameters.json' -f ([guid]::NewGuid().ToString('N')))

$packageDefinitions = @(
    @{ UriParameter = 'newEnvironmentPackageFileUri'; FileName = 'app-new.zip' }
    @{ UriParameter = 'existingEnvironmentPackageFileUri'; FileName = 'app-existing.zip' }
    @{ UriParameter = 'day2PackageFileUri'; FileName = 'app-day2.zip' }
    @{ UriParameter = 'addSessionHostsPackageFileUri'; FileName = 'app-addhosts.zip' }
    @{ UriParameter = 'scalingPackageFileUri'; FileName = 'app-scaling.zip' }
    @{ UriParameter = 'monitoringPackageFileUri'; FileName = 'app-monitoring.zip' }
    @{ UriParameter = 'summaryPackageFileUri'; FileName = 'app-summary.zip' }
)

function Invoke-AzCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Azure CLI command failed: az {0}" -f ($Arguments -join ' '))
    }
}

function Invoke-AzCommandCapture {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $output = & az @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw ("Azure CLI command failed: az {0}" -f ($Arguments -join ' '))
    }

    return $output
}

function Resolve-PackageUris {
    $resolvedUris = @{}

    if ($PSCmdlet.ParameterSetName -eq 'ExplicitUris') {
        $resolvedUris.newEnvironmentPackageFileUri = $NewEnvironmentPackageFileUri
        $resolvedUris.existingEnvironmentPackageFileUri = $ExistingEnvironmentPackageFileUri
        $resolvedUris.day2PackageFileUri = $Day2PackageFileUri
        $resolvedUris.addSessionHostsPackageFileUri = $AddSessionHostsPackageFileUri
        $resolvedUris.scalingPackageFileUri = $ScalingPackageFileUri
        $resolvedUris.monitoringPackageFileUri = $MonitoringPackageFileUri
        $resolvedUris.summaryPackageFileUri = $SummaryPackageFileUri

        return $resolvedUris
    }

    $artifactRoot = if ($PackageArtifactDirectory) {
        Resolve-Path $PackageArtifactDirectory
    }
    else {
        Resolve-Path (Join-Path $repoRoot 'infra\managedapp\dist')
    }

    if ($PackageStorageResourceGroup) {
        Invoke-AzCommand -Arguments @('group', 'create', '--name', $PackageStorageResourceGroup, '--location', $PackageStorageLocation, '--output', 'none')
        $packageStorageDeploymentVerb = if ($WhatIf) { 'what-if' } else { 'create' }
        Invoke-AzCommand -Arguments @(
            'deployment', 'group', $packageStorageDeploymentVerb,
            '--name', 'managedapp-package-storage',
            '--resource-group', $PackageStorageResourceGroup,
            '--template-file', $packageStorageTemplateFile,
            '--parameters',
            "location=$PackageStorageLocation",
            "storageAccountName=$PackageStorageAccountName",
            "containerName=$PackageContainerName",
            '--output', 'none'
        )
    }

    $websiteEndpoint = ((Invoke-AzCommandCapture -Arguments @(
        'storage', 'account', 'show',
        '--name', $PackageStorageAccountName,
        '--resource-group', $PackageStorageResourceGroup,
        '--query', 'primaryEndpoints.web',
        '-o', 'tsv'
    )) | Out-String).Trim()

    if ([string]::IsNullOrWhiteSpace($websiteEndpoint)) {
        throw ("Unable to resolve static website endpoint for storage account {0}" -f $PackageStorageAccountName)
    }

    foreach ($packageDefinition in $packageDefinitions) {
        $packagePath = Join-Path $artifactRoot $packageDefinition.FileName
        if (-not (Test-Path $packagePath)) {
            throw ("Package artifact not found: {0}" -f $packagePath)
        }

        if (-not $WhatIf) {
            Invoke-AzCommand -Arguments @(
                'storage', 'blob', 'upload',
                '--account-name', $PackageStorageAccountName,
                '--container-name', '$web',
                '--name', ("{0}/{1}" -f $PackageContainerName, $packageDefinition.FileName),
                '--file', $packagePath,
                '--overwrite', 'true',
                '--auth-mode', 'login',
                '--output', 'none'
            )
        }

        $resolvedUris[$packageDefinition.UriParameter] = "{0}{1}/{2}" -f $websiteEndpoint, $PackageContainerName, $packageDefinition.FileName
    }

    return $resolvedUris
}

$packageUris = Resolve-PackageUris

Invoke-AzCommand -Arguments @('group', 'create', '--name', $ResourceGroupName, '--location', $Location, '--output', 'none')

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
        newEnvironmentPackageFileUri = @{ value = $packageUris.newEnvironmentPackageFileUri }
        existingEnvironmentDefinitionName = @{ value = $ExistingEnvironmentDefinitionName }
        existingEnvironmentPackageFileUri = @{ value = $packageUris.existingEnvironmentPackageFileUri }
        day2DefinitionName = @{ value = $Day2DefinitionName }
        day2PackageFileUri = @{ value = $packageUris.day2PackageFileUri }
        addSessionHostsDefinitionName = @{ value = $AddSessionHostsDefinitionName }
        addSessionHostsPackageFileUri = @{ value = $packageUris.addSessionHostsPackageFileUri }
        scalingDefinitionName = @{ value = $ScalingDefinitionName }
        scalingPackageFileUri = @{ value = $packageUris.scalingPackageFileUri }
        monitoringDefinitionName = @{ value = $MonitoringDefinitionName }
        monitoringPackageFileUri = @{ value = $packageUris.monitoringPackageFileUri }
        summaryDefinitionName = @{ value = $SummaryDefinitionName }
        summaryPackageFileUri = @{ value = $packageUris.summaryPackageFileUri }
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