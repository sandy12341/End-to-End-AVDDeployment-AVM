# Current Gaps vs AVD Accelerator

This document compares the repo's current modernization state to the broader Azure Virtual Desktop Accelerator experience.

The key distinction is intentional: this repo is now a managed-app-first, AVM-forward AVD landing-zone implementation, but it is still narrower and more opinionated than the accelerator in a few enterprise-facing areas.

## Current-State Summary

Already implemented in this repo:

- Managed-app-first deployment model with a shared Bicep solution core
- AVM adoption for Log Analytics, FSLogix storage, NSGs, spoke VNet/subnets, NAT public IP and NAT gateway, and FSLogix private endpoint/private DNS
- Brownfield and greenfield networking paths
- Marketplace and Azure Compute Gallery image selection
- Typed desktop and RemoteApp access assignments alongside legacy compatibility inputs
- Trusted Launch and monitoring foundations

Still intentionally narrower than the accelerator:

- Identity-service breadth remains focused on `EntraID` and `HybridJoin`
- RemoteApp authoring is still JSON-first in portal flows
- Host-pool and workspace exposure is intentionally conservative rather than fully policy-driven
- Day-2 operational breadth is lighter than the accelerator's broader platform surface

## Gap Matrix

### 1. Image Selection

Current state:

- Implemented.
- The repo now supports marketplace images and Azure Compute Gallery images.
- This closes the earlier baseline gap around image-source choice.

Remaining difference vs accelerator:

- The UX is still narrower than a full accelerator-style discovery experience.
- There is not yet a richer browse-and-validate flow for gallery images or purchase-plan-aware marketplace handling in the portal experience.

### 2. Identity Service Breadth

Current state:

- Partially aligned.
- The deployment surface supports `EntraID` and `HybridJoin`.
- That covers the primary flows this repo currently targets.

Remaining gap vs accelerator:

- The accelerator-style breadth across identity-service patterns is still wider.
- There is no broader abstraction yet for patterns such as AD DS, Entra Domain Services, Entra Kerberos variants, or Intune-oriented join/enrollment options.

### 3. Assignment Model

Current state:

- Implemented for the intended scope.
- Typed `desktopAccessAssignments` and `remoteAppAccessAssignments` are now available.
- The older `avdUserObjectIds` shortcut remains as a compatibility path rather than the primary model.

Remaining difference vs accelerator:

- The repo now covers most of the earlier assignment gap, but the surrounding UX is still simpler.
- There is no richer guided audience-builder experience in the portal; the model is flexible, but still more operator-oriented than accelerator-style workflow UX.

### 4. Host Pool Controls

Current state:

- Partially aligned.
- The repo exposes the core controls needed for the supported scenarios and keeps the delivery-mode model explicit.

Remaining gap vs accelerator:

- The accelerator typically exposes a broader set of host-pool tuning controls.
- This repo still keeps several knobs intentionally narrower, especially around fully surfaced load-balancing choices, max-session tuning, personal assignment behavior, broader public-access posture, and scaling-plan UX.

### 5. Networking Options

Current state:

- Strongly aligned for the targeted scope.
- Existing-VNet and create-new-spoke-VNet paths are both supported.
- FSLogix private endpoint and private DNS are supported.
- AVM adoption now covers the core spoke-networking primitives.

Remaining gap vs accelerator:

- The remaining gap is no longer about basic brownfield/greenfield networking or FSLogix private access.
- The difference is now in breadth: the accelerator can support a wider set of enterprise network posture controls and more expansive public-access decision surfaces for AVD resources.

### 6. RemoteApp Authoring UX

Current state:

- Still narrower.
- RemoteApps are authored through JSON input rather than a richer structured editor.

Remaining gap vs accelerator:

- This is still one of the clearest current UX gaps.
- A more guided authoring experience, repeatable form-based entry, or curated app catalog would move the repo closer to accelerator-style usability.

### 7. Security and Operations

Current state:

- Partially aligned.
- The repo includes monitoring foundations, hardened AVD registration flow, secure FSLogix defaults, Trusted Launch support, NAT-based outbound posture, and optional FSLogix private connectivity.

Remaining gap vs accelerator:

- The repo is still lighter on operational breadth.
- There is no full scaling-plan experience yet.
- Monitoring is intentionally effective but opinionated, rather than offering broad preset selection and wider day-2 operational helpers.

## Highest-Value Remaining Gaps

The most meaningful current gaps, relative to today's state, are:

- Broader identity-service modeling beyond `EntraID` and `HybridJoin`
- Structured RemoteApp authoring instead of JSON-first UX
- Expanded host-pool tuning and public-access posture controls
- Scaling-plan and broader day-2 operations experience

## Non-Gaps To Avoid Reopening

These should no longer be described as open accelerator gaps in this repo:

- Image source selection
- Typed access assignments
- Create-new-network support
- FSLogix private endpoint support
- FSLogix private DNS support

## Recommendation

When discussing this repo relative to the AVD Accelerator, position it as:

- feature-complete for its targeted managed-app-first AVD landing-zone scope
- materially modernized through AVM adoption and shared-solution Bicep structure
- still intentionally narrower than the accelerator in identity breadth, richer UX surfaces, and day-2 operational depth
