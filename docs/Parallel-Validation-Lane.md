# Parallel Validation Lane

This repo is the modernization lane for Azure Virtual Desktop + Landing Zone.

## Purpose

Use this repo to validate AVM-focused modernization end to end without changing the current production lane hosted by the stable `E2EAVDDeployment` repo.

This lane is now explicitly the internal validation path. The public customer deployment path should be the Azure Managed Application published from this repo.

## Separation Rules

- Do not advertise raw GitHub template deployment as the public customer path.
- Do not overwrite the stable repo's raw GitHub Deploy-to-Azure links.
- Do not overwrite the stable managed app package URI.
- Do not overwrite the stable managed app definition name.
- Use separate Azure validation resource groups and naming prefixes.

## Supported Entry Points

- Public/customer path: Azure Managed Application published from `infra/managedapp/`
- Internal engineering path: direct template deployment from `infra/main.bicep` and `infra/azuredeploy.json`
- Parity requirement: both entrypoints must resolve to the same shared solution logic

Current split-entrypoint model:
- Deploy New Environment: raw-template validation lane plus optional managed-app greenfield definition
- Manage Existing AVD Deployment: managed-app existing-environment definition
- Launch Day-2 Operations: managed-app day-2 definition

## Recommended Branch

- `master`

## AVM Boundary Snapshot

Completed AVM adoption in this lane:

- Log Analytics workspace
- FSLogix storage account and file share
- Session host and private endpoint NSGs
- Spoke VNet and subnets
- NAT public IP and NAT gateway
- FSLogix private endpoint and private DNS zone

Reviewed and intentionally retained:

- Private DNS mode branching in the FSLogix private-endpoint module
- Monitoring Data Collection Rule composition
- Cross-scope hub peering implementation
- AVD control-plane and session-host orchestration modules

## Internal Direct Template Portal Pattern

Use a branch-specific Deploy-to-Azure link only for internal validation after this repo is published to GitHub.

```text
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F<owner>%2FE2EAVDDeployment-AVM%2F<branch>%2Finfra%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F<owner>%2FE2EAVDDeployment-AVM%2F<branch>%2Finfra%2FcreateUiDefinition.json
```

## Managed App Validation Lane

Recommended definition settings for the AVM lane:

- Definition resource group: `rg-avd-managedapp-def-avm`
- Definition names:
- `avd-new-environment-avm`
- `avd-manage-existing-avm`
- `avd-day2-operations-avm`
- Package URIs: separate from the stable lane and versioned independently

## Validation Matrix

| Entry point | Launch surface | Artifact | Primary scenario | Current status | Required next validation |
|---|---|---|---|---|---|
| Deploy New Environment | Raw-template validation button | `infra/createUiDefinition.validation.v2.json` | greenfield deployment and networking validation | ready for portal validation | portal launch, review screen, one end-to-end deployment |
| Deploy New Environment | Managed app definition | `infra/managedapp/dist/app-new.zip` | managed-app greenfield deployment | definition published in `rg-avd-managedapp-def-avm` and republished with dedicated new-environment wrapper | portal launch, review screen, one end-to-end deployment |
| Manage Existing AVD Deployment | Managed app definition | `infra/managedapp/dist/app-existing.zip` | brownfield expansion and alignment | definition published in `rg-avd-managedapp-def-avm` | portal launch, one add-session-hosts or monitoring validation |
| Launch Day-2 Operations | Managed app definition | `infra/managedapp/dist/app-day2.zip` | day-2 operator workflows | definition published in `rg-avd-managedapp-def-avm` | portal launch, one pooled scaling-plan validation |

## Local Validation Evidence

- `infra/managedapp/createUiDefinition.existing.json` parses as valid JSON
- `infra/managedapp/createUiDefinition.day2.json` parses as valid JSON
- `infra/managedapp/createUiDefinition.new.json` created as the dedicated greenfield wrapper
- `pwsh ./infra/scripts/Build-DeploymentArtifacts.ps1 -SkipDirectTemplate` succeeds
- `infra/managedapp/dist/app.zip`, `infra/managedapp/dist/app-new.zip`, `infra/managedapp/dist/app-existing.zip`, and `infra/managedapp/dist/app-day2.zip` are emitted
- `infra/managedapp/deployDefinitions.bicep` compiles successfully through the artifact build
- GitHub release `managedapp-packages-20260425` hosts `app-new.zip`, `app-existing.zip`, and `app-day2.zip`
- Managed application definitions `avd-new-environment-avm`, `avd-manage-existing-avm`, and `avd-day2-operations-avm` are published in `rg-avd-managedapp-def-avm`

## Validation Resource Groups

Recommended pattern:

- `AVD-AVM-Greenfield-<date>`
- `AVD-AVM-Brownfield-<date>`
- `AVD-AVM-Monitoring-<date>`
- `AVD-AVM-FSLogixPE-<date>`

## Promotion Rule

Promote this lane only after all of the following pass:

- Bicep build
- Azure `what-if`
- Direct-template portal deployment for the new-environment validation lane
- Managed-app portal deployment for each published operator entrypoint
- Packaged artifact parity
- Scenario validation for the touched slice

Promotion means publishing or updating the managed application package and definition. Direct-template validation remains a gating parity check, not the customer-facing deployment model.

## Rollback Rule

If validation fails, stop using this lane and continue using the stable `E2EAVDDeployment` repo unchanged.
