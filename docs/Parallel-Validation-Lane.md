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
- Definition name: `avd-existing-network-avm`
- Display name: `Azure Virtual Desktop + ALZ (AVM)`
- Package URI: separate from the stable lane

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
- Direct-template portal deployment
- Managed-app portal deployment
- Packaged artifact parity
- Scenario validation for the touched slice

Promotion means publishing or updating the managed application package and definition. Direct-template validation remains a gating parity check, not the customer-facing deployment model.

## Rollback Rule

If validation fails, stop using this lane and continue using the stable `E2EAVDDeployment` repo unchanged.
