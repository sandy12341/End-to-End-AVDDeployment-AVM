# Managed Application Publishing

This runbook publishes the managed application entrypoints used by this repo:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`
4. `Configure Scaling Plan`
5. `Align Monitoring Posture`
6. `Generate Operational Summary`
7. `Add Session Hosts`

It assumes the build artifacts already come from [infra/scripts/Build-DeploymentArtifacts.ps1](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/scripts/Build-DeploymentArtifacts.ps1) and the definitions are published through [infra/scripts/Publish-ManagedAppDefinitions.ps1](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/scripts/Publish-ManagedAppDefinitions.ps1).

## Launch From This Repo

Use these links when you want to launch directly from the repository documentation instead of searching in Azure Portal.

| Entry point | Launch surface | Launch link | Notes |
|---|---|---|---|
| Internal validation lane | Raw-template custom deployment | [Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsandy12341%2FEnd-to-End-AVDDeployment-AVM%2Fmaster%2Finfra%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fsandy12341%2FEnd-to-End-AVDDeployment-AVM%2Fmaster%2Finfra%2FcreateUiDefinition.validation.v2.json) | Engineering validation only. Use this for parity testing and break-glass troubleshooting. |
| Deploy New Environment | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm/overview) | Greenfield managed-app deployment. From the blade, select `Deploy from definition`. |
| Add Session Hosts | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm/overview) | Brownfield host-pool expansion. |
| Configure Scaling Plan | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm/overview) | Pooled host-pool scaling alignment. |
| Align Monitoring Posture | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm/overview) | Control-plane and optional guest-monitoring alignment. |
| Generate Operational Summary | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-operational-summary-avm/overview) | Read-only brownfield posture review. |
| Manage Existing AVD Deployment | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm/overview) | Legacy compatibility wrapper. |
| Launch Day-2 Operations | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm/overview) | Legacy compatibility wrapper. |

The live launch inventory in [README.md](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/README.md) should stay aligned with this table.

## Package URI Map

Use one stable HTTPS URI per package artifact.

| Entry point | Definition name | Local artifact | Placeholder URI |
|---|---|---|---|
| Deploy New Environment | `avd-new-environment-avm` | `infra/managedapp/dist/app-new.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-new.zip?<sas>` |
| Manage Existing AVD Deployment | `avd-manage-existing-avm` | `infra/managedapp/dist/app-existing.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-existing.zip?<sas>` |
| Launch Day-2 Operations | `avd-day2-operations-avm` | `infra/managedapp/dist/app-day2.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-day2.zip?<sas>` |
| Add Session Hosts | `avd-add-session-hosts-avm` | `infra/managedapp/dist/app-addhosts.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-addhosts.zip?<sas>` |
| Configure Scaling Plan | `avd-configure-scaling-avm` | `infra/managedapp/dist/app-scaling.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-scaling.zip?<sas>` |
| Align Monitoring Posture | `avd-align-monitoring-avm` | `infra/managedapp/dist/app-monitoring.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-monitoring.zip?<sas>` |
| Generate Operational Summary | `avd-operational-summary-avm` | `infra/managedapp/dist/app-summary.zip` | `https://<storage-account>.blob.core.windows.net/<container>/app-summary.zip?<sas>` |

If you prefer GitHub Releases instead of Blob Storage, map the same seven files to seven immutable release asset URLs.

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
$AddSessionHostsPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-addhosts.zip?<sas>'
$ScalingPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-scaling.zip?<sas>'
$MonitoringPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-monitoring.zip?<sas>'
$SummaryPackageFileUri = 'https://<storage-account>.blob.core.windows.net/<container>/app-summary.zip?<sas>'
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
$AddSessionHostsDefinitionName = 'avd-add-session-hosts-avm'
$ScalingDefinitionName = 'avd-configure-scaling-avm'
$MonitoringDefinitionName = 'avd-align-monitoring-avm'
$SummaryDefinitionName = 'avd-operational-summary-avm'
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

- `infra/managedapp/dist/app-new.zip`
- `infra/managedapp/dist/app-existing.zip`
- `infra/managedapp/dist/app-day2.zip`
- `infra/managedapp/dist/app-addhosts.zip`
- `infra/managedapp/dist/app-scaling.zip`
- `infra/managedapp/dist/app-monitoring.zip`
- `infra/managedapp/dist/app-summary.zip`
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

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-addhosts.zip \
  --file infra/managedapp/dist/app-addhosts.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-scaling.zip \
  --file infra/managedapp/dist/app-scaling.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-monitoring.zip \
  --file infra/managedapp/dist/app-monitoring.zip \
  --overwrite true \
  --auth-mode login

az storage blob upload \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-summary.zip \
  --file infra/managedapp/dist/app-summary.zip \
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

$AddSessionHostsSas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-addhosts.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$ScalingSas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-scaling.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$MonitoringSas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-monitoring.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$SummarySas = az storage blob generate-sas \
  --as-user \
  --account-name $StorageAccountName \
  --container-name $ContainerName \
  --name app-summary.zip \
  --permissions r \
  --expiry $Expiry \
  --https-only \
  --auth-mode login \
  -o tsv

$NewEnvironmentPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-new.zip?$NewEnvironmentSas"
$ExistingEnvironmentPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-existing.zip?$ExistingEnvironmentSas"
$Day2PackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-day2.zip?$Day2Sas"
$AddSessionHostsPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-addhosts.zip?$AddSessionHostsSas"
$ScalingPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-scaling.zip?$ScalingSas"
$MonitoringPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-monitoring.zip?$MonitoringSas"
$SummaryPackageFileUri = "https://$StorageAccountName.blob.core.windows.net/$ContainerName/app-summary.zip?$SummarySas"
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
  -AddSessionHostsPackageFileUri $AddSessionHostsPackageFileUri \
  -ScalingPackageFileUri $ScalingPackageFileUri \
  -MonitoringPackageFileUri $MonitoringPackageFileUri \
  -SummaryPackageFileUri $SummaryPackageFileUri \
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
  -Day2PackageFileUri $Day2PackageFileUri \
  -AddSessionHostsPackageFileUri $AddSessionHostsPackageFileUri \
  -ScalingPackageFileUri $ScalingPackageFileUri \
  -MonitoringPackageFileUri $MonitoringPackageFileUri \
  -SummaryPackageFileUri $SummaryPackageFileUri
```

This publishes seven managed application definitions through [infra/managedapp/deployDefinitions.bicep](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/managedapp/deployDefinitions.bicep).

## Step 5: Verify The Published Definitions

```powershell
$NewEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm"
$ExistingEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm"
$Day2DefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm"
$AddSessionHostsDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm"
$ScalingDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm"
$MonitoringDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm"
$SummaryDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-operational-summary-avm"

az resource show --ids $NewEnvironmentDefinitionId
az resource show --ids $ExistingEnvironmentDefinitionId
az resource show --ids $Day2DefinitionId
az resource show --ids $AddSessionHostsDefinitionId
az resource show --ids $ScalingDefinitionId
az resource show --ids $MonitoringDefinitionId
az resource show --ids $SummaryDefinitionId
```

## Step 6: Publish Repo-Facing Portal Links

After the definitions exist, update the repo docs with the real operator-facing launch URLs for:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`
4. `Configure Scaling Plan`
5. `Add Session Hosts`
6. `Align Monitoring Posture`
7. `Generate Operational Summary`

Do not publish placeholder URLs in the repo before the definitions are live.

## Current Published State

Active package hosting:

- Azure Blob Storage account `stavdmapkg830ef64901`, container `managedapp-packages`

Package artifacts in active use:

- `app-new.zip`
- `app-existing.zip`
- `app-day2.zip`
- `app-addhosts.zip`
- `app-scaling.zip`
- `app-monitoring.zip`
- `app-summary.zip`

Published definition IDs:

- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-operational-summary-avm`

Operator-facing portal links:

- Deploy New Environment: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm/overview`
- Manage Existing AVD Deployment: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm/overview`
- Launch Day-2 Operations: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm/overview`
- Add Session Hosts: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm/overview`
- Configure Scaling Plan: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm/overview`
- Align Monitoring Posture: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm/overview`
- Generate Operational Summary: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-operational-summary-avm/overview`

Focused wizard runtime checklist:

- `Add Session Hosts`: expected stepper is `Basics`, `Existing AVD target`, `Instance details`, `Networking`, `Local admin`, `Authentication`, `Review`.
- `Configure Scaling Plan`: expected stepper is `Basics`, `Existing AVD target`, `Eligibility check`, `Scaling plan`, `Review`.
- `Align Monitoring Posture`: expected stepper is `Basics`, `Existing AVD target`, `Monitoring posture`, `Review`.
- `Generate Operational Summary`: expected stepper is `Basics`, `Existing AVD target`, `Optional FSLogix enrichment`, `Review`.

Operational notes:

- package hosting now uses Azure Blob Storage with user-delegation SAS URIs during publication
- package ingestion succeeded through the managed application definition deployment even though `az resource show` does not surface `properties.packageFileUri` after publication
- the add-session-hosts definition was published successfully at `2026-04-27T22:25:21.830974+00:00`