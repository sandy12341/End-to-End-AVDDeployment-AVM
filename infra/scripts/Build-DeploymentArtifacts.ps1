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

function New-ManagedAppPackage {
    param(
        [Parameter(Mandatory)]
        [string]$UiDefinitionFileName,
        [Parameter(Mandatory)]
        [string]$PackageDirectoryName,
        [Parameter(Mandatory)]
        [string]$ZipFileName
    )

    $packageRoot = Join-Path $managedAppDistRoot $PackageDirectoryName

    if (Test-Path $packageRoot) {
        Remove-Item -Recurse -Force $packageRoot
    }

    New-Item -ItemType Directory -Force -Path $packageRoot | Out-Null

    Copy-Item -Force (Join-Path $managedAppDistRoot 'mainTemplate.json') (Join-Path $packageRoot 'mainTemplate.json')
    Copy-Item -Force (Join-Path $managedAppRoot $UiDefinitionFileName) (Join-Path $packageRoot 'createUiDefinition.json')

    $packageZipPath = Join-Path $managedAppDistRoot $ZipFileName
    if (Test-Path $packageZipPath) {
        Remove-Item -Force $packageZipPath
    }

    Compress-Archive -Path (Join-Path $packageRoot '*') -DestinationPath $packageZipPath
}

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
    Invoke-BicepBuild -SourceFile (Join-Path $managedAppRoot 'deployDefinitions.bicep') -OutputFile (Join-Path $managedAppDistRoot 'deployDefinitions.json')
}

if (-not $SkipPackage) {
    New-ManagedAppPackage -UiDefinitionFileName 'createUiDefinition.json' -PackageDirectoryName 'package' -ZipFileName 'app.zip'
    New-ManagedAppPackage -UiDefinitionFileName 'createUiDefinition.new.json' -PackageDirectoryName 'package-new' -ZipFileName 'app-new.zip'
    New-ManagedAppPackage -UiDefinitionFileName 'createUiDefinition.existing.json' -PackageDirectoryName 'package-existing' -ZipFileName 'app-existing.zip'
    New-ManagedAppPackage -UiDefinitionFileName 'createUiDefinition.day2.json' -PackageDirectoryName 'package-day2' -ZipFileName 'app-day2.zip'
}

Write-Host 'Deployment artifact build complete.'