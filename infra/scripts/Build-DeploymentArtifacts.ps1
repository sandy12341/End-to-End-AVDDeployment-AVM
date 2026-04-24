[CmdletBinding()]
param(
    [switch]$SkipDirectTemplate,
    [switch]$SkipManagedApp,
    [switch]$SkipPackage
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$infraRoot = Join-Path $repoRoot 'infra'
$managedAppRoot = Join-Path $infraRoot 'managedapp'
$managedAppDistRoot = Join-Path $managedAppRoot 'dist'
$managedAppPackageRoot = Join-Path $managedAppDistRoot 'package'

function Invoke-BicepBuild {
    param(
        [Parameter(Mandatory)]
        [string]$SourceFile,
        [Parameter(Mandatory)]
        [string]$OutputFile
    )

    Write-Host "Building $SourceFile -> $OutputFile"
    az bicep build --file $SourceFile --outfile $OutputFile | Out-Null
}

New-Item -ItemType Directory -Force -Path $managedAppDistRoot | Out-Null

if (-not $SkipDirectTemplate) {
    Invoke-BicepBuild -SourceFile (Join-Path $infraRoot 'main.bicep') -OutputFile (Join-Path $infraRoot 'azuredeploy.json')
}

if (-not $SkipManagedApp) {
    Invoke-BicepBuild -SourceFile (Join-Path $managedAppRoot 'mainTemplate.bicep') -OutputFile (Join-Path $managedAppDistRoot 'mainTemplate.json')
    Invoke-BicepBuild -SourceFile (Join-Path $managedAppRoot 'deployDefinition.bicep') -OutputFile (Join-Path $managedAppDistRoot 'deployDefinition.json')
}

if (-not $SkipPackage) {
    if (Test-Path $managedAppPackageRoot) {
        Remove-Item -Recurse -Force $managedAppPackageRoot
    }

    New-Item -ItemType Directory -Force -Path $managedAppPackageRoot | Out-Null

    Copy-Item -Force (Join-Path $managedAppDistRoot 'mainTemplate.json') (Join-Path $managedAppPackageRoot 'mainTemplate.json')
    Copy-Item -Force (Join-Path $managedAppRoot 'createUiDefinition.json') (Join-Path $managedAppPackageRoot 'createUiDefinition.json')

    $packageZipPath = Join-Path $managedAppDistRoot 'app.zip'
    if (Test-Path $packageZipPath) {
        Remove-Item -Force $packageZipPath
    }

    Compress-Archive -Path (Join-Path $managedAppPackageRoot '*') -DestinationPath $packageZipPath
}

Write-Host 'Deployment artifact build complete.'