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

Use one immutable HTTPS URI per package artifact. The recommended path is the storage account static website endpoint, backed by a dedicated package storage account managed through Bicep.

The publish script uploads packages with a short SHA-256 hash in the blob name, for example `app-summary-<hash>.zip`. This keeps package URLs durable for each version and forces `Microsoft.Solutions/applicationDefinitions` to ingest a fresh artifact when package content changes.

| Entry point | Definition name | Local artifact | Placeholder URI |
|---|---|---|---|
| Deploy New Environment | `avd-new-environment-avm` | `infra/managedapp/dist/app-new.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-new-<hash>.zip` |
| Manage Existing AVD Deployment | `avd-manage-existing-avm` | `infra/managedapp/dist/app-existing.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-existing-<hash>.zip` |
| Launch Day-2 Operations | `avd-day2-operations-avm` | `infra/managedapp/dist/app-day2.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-day2-<hash>.zip` |
| Add Session Hosts | `avd-add-session-hosts-avm` | `infra/managedapp/dist/app-addhosts.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-addhosts-<hash>.zip` |
| Configure Scaling Plan | `avd-configure-scaling-avm` | `infra/managedapp/dist/app-scaling.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-scaling-<hash>.zip` |
| Align Monitoring Posture | `avd-align-monitoring-avm` | `infra/managedapp/dist/app-monitoring.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-monitoring-<hash>.zip` |
| Generate Operational Summary | `avd-operational-summary-avm` | `infra/managedapp/dist/app-summary.zip` | `https://<storage-account>.<web-zone>.web.core.windows.net/<path-prefix>/app-summary-<hash>.zip` |

The storage account keeps `allowBlobPublicAccess = false`. Public package retrieval comes from the static website endpoint instead, while uploads continue to use Microsoft Entra authentication.

## Recommended Publish Inputs

The default publish flow now derives package URLs from a storage account and container instead of requiring seven caller-supplied URIs.

```powershell
$DefinitionResourceGroup = 'rg-avd-managedapp-def-avm'
$Location = 'westus3'
$StorageAccountName = '<storage-account-name>'
$PackageStorageResourceGroup = '<package-storage-resource-group>'
$ContainerName = 'managedapp-packages'
$PrincipalId = '<entra-object-id>'
```

If needed, [infra/scripts/Publish-ManagedAppDefinitions.ps1](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/scripts/Publish-ManagedAppDefinitions.ps1) still supports the legacy explicit-URI path, but that is now the escape hatch rather than the primary workflow.

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

- keep blob public access disabled at the account level
- enable the static website endpoint for durable package fetches
- publish package blobs under the `$web` container with the configured path prefix
- disable shared key access
- allow HTTPS-only access
- keep public network access enabled so Azure can fetch package URIs directly

Because shared key access is disabled, uploads should use Microsoft Entra authentication plus data-plane RBAC on the storage account. At minimum, the publishing identity needs `Storage Blob Data Owner` or `Storage Blob Data Contributor` scoped to the package storage account.

## Step 2: Upload The Packages And Resolve Durable URIs

The default path is to let the publish script provision or reconcile the package storage account through Bicep, upload the seven zip files with Entra-authenticated data-plane access, and then publish the managed application definitions using content-addressed blob URLs.

The package URL pattern is:

```powershell
$WebEndpoint = az storage account show \
  --name $StorageAccountName \
  --resource-group $PackageStorageResourceGroup \
  --query primaryEndpoints.web \
  -o tsv

"$WebEndpoint$ContainerName/<package-name>-<hash>.zip"
```

## Step 3: Preview The Definition Deployment

Run `what-if` before publishing:

```powershell
pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -PackageStorageAccountName $StorageAccountName \
  -PackageStorageResourceGroup $PackageStorageResourceGroup \
  -PackageContainerName $ContainerName \
  -WhatIf
```

## Step 4: Publish The Definitions

```powershell
pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -PackageStorageAccountName $StorageAccountName \
  -PackageStorageResourceGroup $PackageStorageResourceGroup \
  -PackageContainerName $ContainerName
```

This publishes seven managed application definitions through [infra/managedapp/deployDefinitions.bicep](c:/Users/raavisandeep/OneDrive%20-%20Microsoft/Documents/Personal%20Labs/E2EAVDDeployment-AVM/infra/managedapp/deployDefinitions.bicep).

If you need to publish from pre-existing immutable URLs outside Azure Blob Storage, pass the seven explicit `*PackageFileUri` parameters instead.

If the Generate Operational Summary definition must ingest a new `mainTemplate.json` shape, add `-RecreateSummaryDefinition`. Azure can report a successful update to `packageFileUri` while retaining the previously ingested `ApplicationResourceTemplate`; recreating only `avd-operational-summary-avm` forces a fresh package ingestion without changing the other managed app definitions.

## Operational Summary Assignment Discovery

The `Generate Operational Summary` managed app uses `CreateUiDefinition` ARM API calls to detect application-group role assignments. Do not use `Microsoft.Resources/deploymentScripts` for this read-only discovery path in this environment: Azure Deployment Scripts requires backing storage access that uses storage account keys, and this subscription blocks key-based storage authentication by policy.

After changing summary assignment discovery logic, rebuild the artifacts and publish with `-RecreateSummaryDefinition` so the managed app definition ingests the new package contents:

```powershell
pwsh ./infra/scripts/Build-DeploymentArtifacts.ps1 -SkipDirectTemplate

pwsh ./infra/scripts/Publish-ManagedAppDefinitions.ps1 \
  -ResourceGroupName $DefinitionResourceGroup \
  -Location $Location \
  -PrincipalId $PrincipalId \
  -PackageStorageAccountName $StorageAccountName \
  -PackageStorageResourceGroup $PackageStorageResourceGroup \
  -PackageContainerName $ContainerName \
  -RecreateSummaryDefinition
```

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

## Operational Summary Outputs

For `Generate Operational Summary`, the useful outputs are on the managed application deployment inside the managed resource group, not on the application definition resource in `rg-avd-managedapp-def-avm`.

After an operator runs the definition:

1. Open the managed application instance.
2. Open the linked managed resource group.
3. Open `Deployments`.
4. Open the inner deployment created for the selected host pool.
5. Open `Outputs`.

The output keys to look for are:

- `operationalSummaryHtml`: the rendered HTML report body with the summary table, recommendations, and findings.
- `operationalSummaryHtmlDataUri`: a `data:text/html;base64,...` URI for opening the same report directly in a browser or another viewer that accepts data URIs.

If the outer deployment under `rg-avd-managedapp-def-avm` shows empty outputs, that is expected. The actual report outputs live on the nested deployment in the managed resource group.

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
- `Configure Scaling Plan`: expected stepper is `Basics`, `Existing AVD target`, `Scaling plan`, `Review`.
- `Align Monitoring Posture`: expected stepper is `Basics`, `Existing AVD target`, `Monitoring posture`, `Review`.
- `Generate Operational Summary`: expected stepper is `Basics`, `Existing AVD target`, `Optional FSLogix enrichment`, `Review`.

Operational notes:

- package hosting now uses Azure Storage static website URLs rooted at `https://stavdmapkg830ef64901.z1.web.core.windows.net/managedapp-packages/`
- uploads still use Microsoft Entra authentication; shared key access remains disabled
- package ingestion succeeded through the managed application definition deployment even though `az resource show` does not surface `properties.packageFileUri` after publication
- the add-session-hosts definition was published successfully at `2026-04-27T22:25:21.830974+00:00`