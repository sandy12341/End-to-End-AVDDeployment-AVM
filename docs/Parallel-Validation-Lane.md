# Parallel Validation Lane

This repo is the modernization lane for Azure Virtual Desktop + Landing Zone.

## Purpose

Use this repo to validate AVM-focused modernization end to end without changing the current production lane hosted by the stable `E2EAVDDeployment` repo.

## Separation Rules

- Do not overwrite the stable repo's raw GitHub Deploy-to-Azure links.
- Do not overwrite the stable managed app package URI.
- Do not overwrite the stable managed app definition name.
- Use separate Azure validation resource groups and naming prefixes.

## Recommended Branch

- `avm-modernization-v1`

## Direct Template Portal Pattern

Use a branch-specific Deploy-to-Azure link after this repo is published to GitHub.

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

## Rollback Rule

If validation fails, stop using this lane and continue using the stable `E2EAVDDeployment` repo unchanged.
