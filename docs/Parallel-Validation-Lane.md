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

Current entrypoint model:
- Internal validation lane: raw-template deployment button backed by `infra/createUiDefinition.validation.v2.json`
- Preferred managed-app operator definitions: deploy new environment, add session hosts, configure scaling plan, and align monitoring posture
- Retained compatibility wrappers: manage existing AVD deployment and launch day-2 operations

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
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F<owner>%2FE2EAVDDeployment-AVM%2F<branch>%2Finfra%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2F<owner>%2FE2EAVDDeployment-AVM%2F<branch>%2Finfra%2FcreateUiDefinition.validation.v2.json
```

## Managed App Validation Lane

Recommended definition settings for the AVM lane:

- Definition resource group: `rg-avd-managedapp-def-avm`
- Definition names:
- `avd-new-environment-avm`
- `avd-add-session-hosts-avm`
- `avd-configure-scaling-avm`
- `avd-align-monitoring-avm`
- `avd-manage-existing-avm`
- `avd-day2-operations-avm`
- Package URIs: separate from the stable lane and versioned independently

## Validation Matrix

| Entry point | Launch surface | Artifact | Primary scenario | Current status | Required next validation |
|---|---|---|---|---|---|
| Deploy New Environment | Raw-template validation button | `infra/createUiDefinition.validation.v2.json` | greenfield deployment and networking validation | Build-ready; portal validation pending | portal launch, review screen, one end-to-end deployment |
| Deploy New Environment | Managed app definition | `infra/managedapp/dist/app-new.zip` | managed-app greenfield deployment | Package built and definition published; portal validation pending | portal launch, review screen, one end-to-end deployment |
| Add Session Hosts | Managed app definition | `infra/managedapp/dist/app-addhosts.zip` | brownfield host-pool expansion | Package built and definition published; portal validation pending | portal launch, stepper review, one brownfield host-add validation |
| Configure Scaling Plan | Managed app definition | `infra/managedapp/dist/app-scaling.zip` | pooled host-pool scaling alignment | Package built and definition published; portal validation pending | portal launch, stepper review, one pooled scaling-plan validation |
| Align Monitoring Posture | Managed app definition | `infra/managedapp/dist/app-monitoring.zip` | brownfield control-plane and guest-monitoring alignment | Package built and definition published; portal validation pending | portal launch, stepper review, one monitoring-alignment validation |
| Manage Existing AVD Deployment | Managed app definition | `infra/managedapp/dist/app-existing.zip` | broad brownfield wrapper retained for compatibility | Package built and definition published; compatibility validation pending | portal launch, confirm legacy wrapper is still intentionally available |
| Launch Day-2 Operations | Managed app definition | `infra/managedapp/dist/app-day2.zip` | broad day-2 wrapper retained for compatibility | Package built and definition published; compatibility validation pending | portal launch, confirm legacy wrapper is still intentionally available |

## Local Validation Evidence

- `infra/managedapp/createUiDefinition.existing.json` parses as valid JSON
- `infra/managedapp/createUiDefinition.day2.json` parses as valid JSON
- `infra/managedapp/createUiDefinition.new.json` created as the dedicated greenfield wrapper
- `pwsh ./infra/scripts/Build-DeploymentArtifacts.ps1 -SkipDirectTemplate` succeeds
- `infra/managedapp/dist/app-new.zip`, `infra/managedapp/dist/app-existing.zip`, `infra/managedapp/dist/app-day2.zip`, `infra/managedapp/dist/app-addhosts.zip`, `infra/managedapp/dist/app-scaling.zip`, and `infra/managedapp/dist/app-monitoring.zip` are emitted
- `infra/managedapp/deployDefinitions.bicep` compiles successfully through the artifact build
- Azure Blob package hosting is used for publication instead of the earlier GitHub release flow
- Managed application definitions `avd-new-environment-avm`, `avd-add-session-hosts-avm`, `avd-configure-scaling-avm`, `avd-align-monitoring-avm`, `avd-manage-existing-avm`, and `avd-day2-operations-avm` are published in `rg-avd-managedapp-def-avm`

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
