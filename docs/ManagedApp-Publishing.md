# Managed Application Publishing

This runbook publishes the managed application entrypoints used by this repo:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`
4. `Configure Scaling Plan`
5. `Align Monitoring Posture`
6. `Add Session Hosts`

It assumes the build artifacts already come from [infra/scripts/Build-DeploymentArtifacts.ps1](../infra/scripts/Build-DeploymentArtifacts.ps1) and the definitions are published through [infra/scripts/Publish-ManagedAppDefinitions.ps1](../infra/scripts/Publish-ManagedAppDefinitions.ps1).

## Launch From This Repo

Use these links when you want to launch directly from repository documentation instead of searching in Azure Portal.

| Entry point | Launch surface | Launch link | Notes |
|---|---|---|---|
| Internal validation lane | Raw-template custom deployment | [Deploy to Azure](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsandy12341%2FEnd-to-End-AVDDeployment-AVM%2Fmaster%2Finfra%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fsandy12341%2FEnd-to-End-AVDDeployment-AVM%2Fmaster%2Finfra%2FcreateUiDefinition.validation.v2.json) | Engineering validation only. Use this for parity testing and break-glass troubleshooting. |
| Deploy New Environment | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm/overview) | Greenfield managed-app deployment. From the blade, select `Deploy from definition`. |
| Add Session Hosts | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm/overview) | Brownfield host-pool expansion. |
| Configure Scaling Plan | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm/overview) | Pooled host-pool scaling alignment. |
| Align Monitoring Posture | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm/overview) | Control-plane and optional guest-monitoring alignment. |
| Manage Existing AVD Deployment | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm/overview) | Legacy compatibility wrapper. |
| Launch Day-2 Operations | Managed app definition | [Open in Azure Portal](https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm/overview) | Legacy compatibility wrapper. |

The live launch inventory in [README.md](../README.md) should stay aligned with this table.

## Package URI Map

Use one immutable HTTPS URI per package artifact. The recommended path is the storage account static website endpoint, backed by a dedicated package storage account managed through Bicep.

The publish script uploads packages with a short SHA-256 hash in the blob name, for example `app-monitoring-<hash>.zip`. This keeps package URLs durable for each version and forces `Microsoft.Solutions/applicationDefinitions` to ingest a fresh artifact when package content changes.

| Entry point | Definition name | Local artifact | Placeholder URI |
|---|---|---|---|
| Deploy New Environment | `avd-new-environment-avm` | `infra/managedapp/dist/app-new.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-new-<hash>.zip` |
| Manage Existing AVD Deployment | `avd-manage-existing-avm` | `infra/managedapp/dist/app-existing.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-existing-<hash>.zip` |
| Launch Day-2 Operations | `avd-day2-operations-avm` | `infra/managedapp/dist/app-day2.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-day2-<hash>.zip` |
| Add Session Hosts | `avd-add-session-hosts-avm` | `infra/managedapp/dist/app-addhosts.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-addhosts-<hash>.zip` |
| Configure Scaling Plan | `avd-configure-scaling-avm` | `infra/managedapp/dist/app-scaling.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-scaling-<hash>.zip` |
| Align Monitoring Posture | `avd-align-monitoring-avm` | `infra/managedapp/dist/app-monitoring.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-monitoring-<hash>.zip` |

The storage account keeps `allowBlobPublicAccess = false`. Public package retrieval comes from the static website endpoint, while uploads continue to use Microsoft Entra authentication.

## Recommended Publish Inputs

The default publish flow derives package URLs from a storage account and container instead of requiring caller-supplied URIs.

```powershell
$DefinitionResourceGroup = 'rg-avd-managedapp-def-avm'
$Location = 'westus3'
$StorageAccountName = '<storage-account-name>'
$PackageStorageResourceGroup = '<package-storage-resource-group>'
$ContainerName = 'managedapp-packages'
$PrincipalId = '<entra-object-id>'
```

If needed, [infra/scripts/Publish-ManagedAppDefinitions.ps1](../infra/scripts/Publish-ManagedAppDefinitions.ps1) still supports the legacy explicit-URI path, but that is now the escape hatch rather than the primary workflow.

## Current Environment Starter Block

The values below match the current Azure CLI context on this workstation at the time this runbook was updated.

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
```

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
- `infra/managedapp/dist/deployDefinitions.json`

## Step 2: Provision Dedicated Package Storage

Provision package hosting with [infra/managedapp/packageStorage.bicep](../infra/managedapp/packageStorage.bicep):

```powershell
$PackageStorageResourceGroup = 'rg-avd-managedapp-packages-avm'

az group create \
  --name $PackageStorageResourceGroup \
  --location $Location

az deployment group create \
  --name managedapp-package-storage \
  --resource-group $PackageStorageResourceGroup \
  --template-file infra/managedapp/packageStorage.bicep \
  --parameters \
    location=$Location \
    storageAccountName=$StorageAccountName \
    containerName=$ContainerName
```

## Step 3: Publish Definitions

```powershell
pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -PackageStorageAccountName $StorageAccountName \
  -PackageStorageResourceGroup $PackageStorageResourceGroup \
  -PackageContainerName $ContainerName
```

This publishes six managed application definitions through [infra/managedapp/deployDefinitions.bicep](../infra/managedapp/deployDefinitions.bicep).

If you need to publish from pre-existing immutable URLs outside Azure Blob Storage, pass the six explicit `*PackageFileUri` parameters instead.

## Step 4: Verify The Published Definitions

```powershell
$NewEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm"
$ExistingEnvironmentDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm"
$Day2DefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm"
$AddSessionHostsDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm"
$ScalingDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm"
$MonitoringDefinitionId = "/subscriptions/<definition-subscription>/resourceGroups/$DefinitionResourceGroup/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm"

az resource show --ids $NewEnvironmentDefinitionId
az resource show --ids $ExistingEnvironmentDefinitionId
az resource show --ids $Day2DefinitionId
az resource show --ids $AddSessionHostsDefinitionId
az resource show --ids $ScalingDefinitionId
az resource show --ids $MonitoringDefinitionId
```

## Step 5: Publish Repo-Facing Portal Links

After the definitions exist, update the repo docs with the real operator-facing launch URLs for:

1. `Deploy New Environment`
2. `Manage Existing AVD Deployment`
3. `Launch Day-2 Operations`
4. `Configure Scaling Plan`
5. `Add Session Hosts`
6. `Align Monitoring Posture`

Do not publish placeholder URLs in the repo before the definitions are live.

## Current Published State

Active package hosting:

- Azure Storage static website endpoint `https://stavdmapkg830ef64901.z1.web.core.windows.net/`
- Path prefix `managedapp-packages`

Package artifacts in active use:

- `app-new.zip`
- `app-existing.zip`
- `app-day2.zip`
- `app-addhosts.zip`
- `app-scaling.zip`
- `app-monitoring.zip`

Published definition IDs:

- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm`
- `/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm`

Operator-facing portal links:

- Deploy New Environment: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-new-environment-avm/overview`
- Manage Existing AVD Deployment: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-manage-existing-avm/overview`
- Launch Day-2 Operations: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-day2-operations-avm/overview`
- Add Session Hosts: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-add-session-hosts-avm/overview`
- Configure Scaling Plan: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-configure-scaling-avm/overview`
- Align Monitoring Posture: `https://portal.azure.com/#@1c9feb84-3b85-4498-a8c7-f096754e118d/resource/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-avd-managedapp-def-avm/providers/Microsoft.Solutions/applicationDefinitions/avd-align-monitoring-avm/overview`

Focused wizard runtime checklist:

- `Add Session Hosts`: expected stepper is `Basics`, `Existing AVD target`, `Instance details`, `Networking`, `Local admin`, `Authentication`, `Review`.
- `Configure Scaling Plan`: expected stepper is `Basics`, `Existing AVD target`, `Scaling plan`, `Review`.
- `Align Monitoring Posture`: expected stepper is `Basics`, `Existing AVD target`, `Monitoring posture`, `Review`.

Operational notes:

- package hosting uses Azure Storage static website URLs rooted at `https://stavdmapkg830ef64901.z1.web.core.windows.net/managedapp-packages/`
- uploads use Microsoft Entra authentication; shared key access remains disabled
- package ingestion succeeds through managed application definition deployment even though `az resource show` does not surface `properties.packageFileUri` after publication
