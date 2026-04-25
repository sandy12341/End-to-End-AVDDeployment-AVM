# Managed Application Publishing

This runbook publishes the three managed application entrypoints used by this repo:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`

It assumes the build artifacts already come from [infra/scripts/Build-DeploymentArtifacts.ps1](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/scripts/Build-DeploymentArtifacts.ps1) and the definitions are published through [infra/scripts/Publish-ManagedAppDefinitions.ps1](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/scripts/Publish-ManagedAppDefinitions.ps1).

## Package URI Map

Use one stable HTTPS URI per package artifact.

| Entry point | Definition name | Local artifact | Placeholder URI |
|---|---|---|---|
| Deploy New Environment | `avd-new-environment-avm` | `infra/managedapp/dist/app-new.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-new.zip?<sas>` |
| Manage Existing AVD Deployment | `avd-manage-existing-avm` | `infra/managedapp/dist/app-existing.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-existing.zip?<sas>` |
| Launch Day-2 Operations | `avd-day2-operations-avm` | `infra/managedapp/dist/app-day2.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-day2.zip?<sas>` |

If you prefer GitHub Releases instead of Blob Storage, map the same three files to three immutable release asset URLs.

## Recommended Publish Inputs

Use these placeholders consistently:

```powershell
$DefinitionResourceGroup = 'rg-avd-managedapp-def-avm'
$Location = 'westus3'
$StorageAccountName = '<storage-account-name>'
$ContainerName = 'managedapp-packages'
$PrincipalId = '<entra-object-id>'

$NewEnvironmentPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-new.zip?<sas>'
$ExistingEnvironmentPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-existing.zip?<sas>'
$Day2PackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-day2.zip?<sas>'
```

## Current Environment Starter Block

The values below match the current Azure CLI context on this workstation at the time this runbook was updated.

Important:
- Azure extension authentication context and Azure CLI authentication context are separate systems.
- The commands in this runbook use Azure CLI.
- At update time, both contexts pointed to the same subscription.

```powershell
az account set --subscription '830ef649-535d-4642-9436-356f9619c2e4'

$SubscriptionId = '830ef649-535d-4642-9436-356f9619c2e4'
$TenantId = '1c9feb84-3b85-4498-a8c7-f096754e118d'
$DefinitionResourceGroup = 'rg-avd-managedapp-def-avm'
$Location = 'westus3'
$PrincipalId = '752798db-778e-4e03-949f-e3f717df5447'
$PackageStorageResourceGroup = 'rg-avd-managedapp-packages-avm'

$StorageAccountName = 'stavdmapkg830ef64901'
$ContainerName = 'managedapp-packages'

$NewEnvironmentDefinitionName = 'avd-new-environment-avm'
$ExistingEnvironmentDefinitionName = 'avd-manage-existing-avm'
$Day2DefinitionName = 'avd-day2-operations-avm'
```

At update time, `stavdmapkg830ef64901` passed `az storage account check-name` in the current tenant and subscription context.

The only required edits before upload and publish are:

1. keep or change `$StorageAccountName`
2. optionally change `$ContainerName`
3. keep or override the default definition names if needed

## Step 1: Build The Artifacts

```powershell
pwsh ./infra/scripts/Build-DeploymentArtifacts.ps1
```

Expected outputs:

- `infra/managedapp/dist/app.zip`
- `infra/managedapp/dist/app-new.zip`
- `infra/managedapp/dist/app-existing.zip`
- `infra/managedapp/dist/app-day2.zip`
- `infra/managedapp/dist/deployDefinitions.json`

## Step 1.5: Provision Dedicated Package Storage

The current subscription snapshot used during planning did not show an existing `rg-avd-managedapp-def-avm`, and the visible storage accounts had `publicNetworkAccess = Disabled`. For managed application package hosting, prefer a dedicated storage account created specifically for package publication.

Provision it with [infra/managedapp/packageStorage.bicep](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/managedapp/packageStorage.bicep):

```powershell
$PackageStorageResourceGroup = 'rg-avd-managedapp-packages-avm'

az group create \
  --name $PackageStorageResourceGroup \
  --location $Location

az deployment group create \
  --resource-group $PackageStorageResourceGroup \
  --template-file infra/managedapp/packageStorage.bicep \
  --parameters \
    location=$Location \
    storageAccountName=$StorageAccountName \
    containerName=$ContainerName
```

This storage account is configured to:

- keep blob containers private
- disable anonymous blob access
- disable shared key access
- allow HTTPS-only access
- keep public network access enabled so Azure can fetch package URIs via SAS

Because shared key access is disabled, uploads and SAS generation should use Microsoft Entra authentication plus data-plane RBAC on the storage account. At minimum, the publishing identity needs `Storage Blob Data Owner` or `Storage Blob Data Contributor` scoped to the package storage account.

## Step 2: Upload The Packages

The simplest repeatable option is Azure Blob Storage with Entra-authenticated upload.

Create the container if needed:

```powershell
az storage container create \
  --name $ContainerName \
  --account-name $StorageAccountName \
  --auth-mode login
```

Upload each package:

```powershell
az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-new.zip \
  --file infra/managedapp/dist/app-new.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app.zip \
  --file infra/managedapp/dist/app.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-existing.zip \
  --file infra/managedapp/dist/app-existing.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-day2.zip \
  --file infra/managedapp/dist/app-day2.zip \
  --overwrite true \
  --auth-mode login
```

Generate read-only user-delegation SAS tokens if the package URIs should not rely on public blob access:

```powershell
$Expiry = (Get-Date).ToUniversalTime().AddDays(7).ToString('yyyy-MM-ddTHH:mmZ')

$NewEnvironmentSas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-new.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$ExistingEnvironmentSas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-existing.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$Day2Sas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-day2.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$NewEnvironmentPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-new.zip?$NewEnvironmentSas"
$ExistingEnvironmentPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-existing.zip?$ExistingEnvironmentSas"
$Day2PackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-day2.zip?$Day2Sas"
```

## Step 3: Preview The Definition Deployment

Run `what-if` before publishing:

```powershell
pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -NewEnvironmentPackageFileUri $NewEnvironmentPackageFileUri \
  -ExistingEnvironmentPackageFileUri $ExistingEnvironmentPackageFileUri \
  -Day2PackageFileUri $Day2PackageFileUri \
  -WhatIf
```

## Step 4: Publish The Definitions

```powershell
pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -NewEnvironmentPackageFileUri $NewEnvironmentPackageFileUri \
  -ExistingEnvironmentPackageFileUri $ExistingEnvironmentPackageFileUri \
  -Day2PackageFileUri $Day2PackageFileUri
```

This publishes three managed application definitions through [infra/managedapp/deployDefinitions.bicep](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/managedapp/deployDefinitions.bicep).

## Step 5: Verify The Published Definitions

```powershell
$NewEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm"
$ExistingEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm"
$Day2DefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm"

az resource show --ids $NewEnvironmentDefinitionId
az resource show --ids $ExistingEnvironmentDefinitionId
az resource show --ids $Day2DefinitionId
```

## Step 6: Publish Repo-Facing Portal Links

After the definitions exist, update the repo docs with the real operator-facing launch URLs for:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`

Do not publish placeholder URLs in the repo before the definitions are live.

## Current Published State

Package release:

- `https://github.com/sandy12341/End-to-End-AVDDeployment-AVM/releases/tag/managedapp-packages-20260425`

Release assets in active use:

- `app-new.zip`
- `app-existing.zip`
- `app-day2.zip`

Published definition IDs:

- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm`

Operational notes:

- package hosting currently uses GitHub release assets rather than Azure Blob Storage because the dedicated storage account path was blocked by data-plane RBAC propagation during publication
- package ingestion succeeded through the managed application definition deployment even though `az resource show` does not surface `properties.packageFileUri` after publication
- the greenfield managed-app definition was republished to use `app-new.zip` so it no longer relies on the generic `app.zip` package