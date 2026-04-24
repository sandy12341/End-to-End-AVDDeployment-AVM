# Enhancement Roadmap

## Purpose

This roadmap sequences the enhancement work in E2EAVDDeployment so the project can evolve from the validated baseline without losing deployability.

## Current Status Snapshot

Completed in this modernization lane:

- Image source foundation
- Typed desktop and RemoteApp access assignments
- Shared Bicep solution core with managed-app-first deployment model
- AVM adoption for workspace monitoring foundation, FSLogix storage, spoke networking, NAT, and FSLogix private endpoint/private DNS

Reviewed and intentionally retained:

- Private DNS mode branching in the FSLogix private-endpoint module
- Monitoring DCR composition
- Cross-scope hub peering logic
- AVD control-plane and session-host orchestration logic

## Phase Order

### Phase 1: Image Source Foundation

Scope:
- Extend `infra/main.bicep` and `infra/modules/sessionhosts.bicep` with image-source parameters.
- Update both portal definitions to support marketplace and gallery selection.
- Add validation and sample parameter files.

Exit criteria:
- Baseline marketplace path still deploys successfully.
- Gallery image path validates and deploys successfully in at least one scenario.

### Phase 2: Identity and Assignment Refactor

Scope:
- Generalize assignment inputs from raw user IDs to typed principal assignments.
- Add support for groups and separate desktop versus RemoteApp audiences.
- Remove obsolete resolver-era parameters and helper artifacts from the baseline.

Exit criteria:
- User assignment and group assignment both work.
- The baseline no longer ships unsupported resolver parameters or scripts.

### Phase 3: Expanded Auth Models

Scope:
- Introduce broader identity modes aligned to enterprise AVD patterns.
- Add Intune enrollment toggle and conditional validation.
- Normalize naming so auth and identity terms are consistent.

Exit criteria:
- Entra-based and domain-based flows both validate cleanly.
- Wizard only shows relevant inputs for the selected identity mode.

### Phase 4: Host Pool UX Improvements

Scope:
- Expose load balancing, max sessions, personal assignment type, Start VM on Connect, and RDP property presets.
- Replace raw RemoteApp JSON entry with a structured authoring experience.

Exit criteria:
- Desktop, RemoteApp, and combined modes remain functional.
- Structured RemoteApp input produces the same template outputs as manual definitions.

### Phase 5: Network and Security Posture

Scope:
- Add create-new-network option.
- Add host pool and workspace public access controls.
- Add private endpoint and private DNS options.
- Add VM security type controls.

Exit criteria:
- Existing-network path still works.
- At least one private connectivity deployment path is validated.

Status:

- create-new-network is complete
- FSLogix private endpoint and private DNS support are complete
- VM security type controls are complete
- host pool and workspace public access posture remains a possible future extension

### Phase 6: Operations and Day-2 Tooling

Scope:
- Add scaling plans and schedule UX.
- Add brownfield helper templates or scripts.
- Improve monitoring presets and deployment summaries.

Exit criteria:
- At least one brownfield scenario is documented and validated.
- Scaling plan deployment path is tested for pooled mode.

## Verification Model

For every phase:
- Run template validation for direct Bicep/ARM deployment.
- Validate both direct template and managed-app portal surfaces if affected.
- Record at least one end-to-end deployment scenario in docs.
- Keep backward-compatible defaults wherever practical.

## Repo Strategy

- Keep this repo as the active enhancement workspace.
- Treat the original E2EAVDDeployment repo as the stable reference baseline.
- Back-port only after a feature is validated and intentionally selected for promotion.

### Phase 6.1: Brownfield AVD Operations Wizard

Purpose:
- Extend the managed application experience so brownfield means more than existing-network deployment.
- Add an operator-focused flow for expanding and managing existing AVD environments after initial deployment.

Recommended wizard model:

1. Scenario
- New AVD deployment
- Expand or update existing AVD deployment
- Day-2 operations for existing AVD deployment

2. New AVD deployment
- Preserve the current deployment-centric wizard flow.
- Rename the current Brownfield/Greenfield network selector to:
  - Create new network
  - Use existing network

3. Expand or update existing AVD deployment
- Add a branch that selects an existing AVD workspace and host pool.
- Detect current host pool type, delivery mode, auth model, scaling-plan attachment, and monitoring posture.
- Support low-blast-radius changes such as:
  - add session hosts
  - update VM/image baseline
  - align FSLogix private connectivity
  - align monitoring posture
  - adjust app and access assignments

4. Day-2 operations for existing AVD deployment
- Make this branch task-oriented rather than deployment-oriented.
- Present a choose-operation page with actions such as:
  - configure scaling plan
  - update monitoring posture
  - add session hosts
  - reconcile FSLogix private connectivity
  - review access assignments
  - generate operational summary

5. Scaling plan experience
- Add a dedicated scaling-plan operation page for pooled host pools.
- Capture:
  - selected host pool
  - existing plan attached or not
  - weekday and weekend schedules
  - ramp-up, peak, ramp-down, and off-peak settings
  - time zone
  - drain mode and forced logoff behavior
  - minimum host capacity and thresholds
- Review page should clearly show whether the action creates, updates, or attaches a scaling plan and should state that session hosts are not recreated.

6. Brownfield day-2 categories
- Capacity
  - scaling plans
  - add/remove hosts
  - VM size and image drift review
- Observability
  - monitoring baseline
  - diagnostics enablement
  - workspace reuse or alignment
- Connectivity
  - FSLogix private endpoint posture
  - DNS readiness
  - subnet suitability checks
- Access
  - desktop assignments
  - RemoteApp assignments
  - publishing summary

Design principles:
- Do not overload Brownfield to mean both existing-network deployment and existing-AVD operations.
- Keep network reuse as a network decision only.
- Make existing-AVD operations a first-class scenario in the wizard.
- Prefer task-based day-2 workflows over forcing operators through the full create flow.

Exit criteria:
- Wizard supports a distinct scenario selection for new deployment versus existing-environment operations.
- At least one pooled host pool can be onboarded to a scaling-plan flow without recreating session hosts.
- At least one brownfield operational workflow is documented end to end.
- Day-2 review screens clearly show scope of change and blast radius.