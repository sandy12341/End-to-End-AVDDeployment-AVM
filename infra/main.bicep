targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Deployment prefix used for naming')
@maxLength(6)
param deploymentPrefix string = 'avd1'

@description('Deployment scenario selected by the entrypoint. NewDeployment preserves the current create flow while brownfield operation paths are introduced incrementally.')
@allowed(['NewDeployment', 'ExpandExistingDeployment', 'Day2Operations'])
param deploymentScenario string = 'NewDeployment'

@description('Environment name')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Selected brownfield expansion action.')
@allowed(['', 'AddSessionHosts', 'AlignMonitoringPosture', 'RemediateVmImageBaseline'])
param expandOperation string = ''

@description('Selected brownfield day-2 action.')
@allowed(['', 'ConfigureScalingPlan', 'AlignMonitoringPosture', 'UpdateAccessAssignments', 'ReconcileFsLogixPrivateConnectivity', 'GenerateOperationalSummary'])
param day2Operation string = ''

@description('Number of session host VMs')
@minValue(1)
@maxValue(10)
param sessionHostCount int = 1

@description('VM size for session hosts')
param vmSize string = 'Standard_D2ads_v5'

@description('Image source for the session host OS image.')
@allowed(['Marketplace', 'AzureComputeGallery'])
param imageSource string = 'Marketplace'

@description('Marketplace image publisher for session hosts when imageSource is Marketplace.')
param marketplaceImagePublisher string = 'microsoftwindowsdesktop'

@description('Marketplace image offer for session hosts when imageSource is Marketplace.')
param marketplaceImageOffer string = 'windows-11'

@description('Marketplace image SKU for session hosts when imageSource is Marketplace.')
param marketplaceImageSku string = 'win11-24h2-avd'

@description('Marketplace image version for session hosts when imageSource is Marketplace.')
param marketplaceImageVersion string = 'latest'

@description('Azure Compute Gallery subscription ID for session hosts when imageSource is AzureComputeGallery.')
param galleryImageSubscriptionId string = subscription().subscriptionId

@description('Azure Compute Gallery resource group name for session hosts when imageSource is AzureComputeGallery.')
param galleryImageResourceGroupName string = ''

@description('Azure Compute Gallery name for session hosts when imageSource is AzureComputeGallery.')
param galleryName string = ''

@description('Azure Compute Gallery image definition name for session hosts when imageSource is AzureComputeGallery.')
param galleryImageDefinitionName string = ''

@description('Azure Compute Gallery image version for session hosts when imageSource is AzureComputeGallery.')
param galleryImageVersion string = 'latest'

@description('Session host security type. Auto uses Trusted Launch for Azure Compute Gallery images and Standard for Marketplace images.')
@allowed(['Auto', 'Standard', 'TrustedLaunch'])
param sessionHostSecurityType string = 'Auto'

@description('Preferred AVD delivery mode. Leave empty to preserve the legacy desktop-only behavior driven by hostPoolType.')
@allowed(['', 'PersonalDesktop', 'PooledRemoteApp', 'PooledDesktopAndRemoteApp'])
param avdMode string = ''

@description('Host pool type')
@allowed(['Personal', 'Pooled'])
param hostPoolType string = 'Pooled'

@description('Authentication type for session host sign-in and join flow')
@allowed(['EntraID', 'HybridJoin'])
param authenticationType string = 'EntraID'

@description('Active Directory domain FQDN (required for HybridJoin)')
param domainFqdn string = ''

@description('Domain join service account in DOMAIN\\username or username@domain format (required for HybridJoin)')
param domainJoinUsername string = ''

@description('Domain join service account password (required for HybridJoin)')
@secure()
param domainJoinPassword string = ''

@description('Optional OU path where computer accounts should be created for HybridJoin (for example OU=AVD,DC=contoso,DC=com)')
param domainJoinOuPath string = ''

@description('Local admin username for session hosts')
param adminUsername string

@description('Local admin password for session hosts')
@secure()
param adminPassword string

@description('Deploy FSLogix profile storage')
param deployFSLogix bool = true

@description('Storage account name for FSLogix profiles (must be globally unique, 3-24 chars, lowercase/numbers only)')
@maxLength(24)
param storageAccountName string = ''

@description('Deploy monitoring (Log Analytics)')
param deployMonitoring bool = true

@description('Deploy a private endpoint for the FSLogix storage account and disable public network access. Requires a private endpoint subnet (created automatically in Greenfield mode).')
param deployFSLogixPrivateEndpoint bool = false

@description('Choose whether to use an existing VNet or create a new spoke VNet for the deployment.')
@allowed(['UseExistingVnet', 'CreateNewVnet'])
param networkMode string = 'UseExistingVnet'

@description('Name of the existing virtual network to use')
param existingVnetName string = ''

@description('Resource group name that contains the existing virtual network')
param existingVnetResourceGroupName string = resourceGroup().name

@description('Name of the existing subnet for session hosts')
param sessionHostSubnetName string = ''

@description('Name of the existing subnet reserved for private endpoints')
param privateEndpointSubnetName string = ''

@description('Name of the new spoke virtual network to create when networkMode is CreateNewVnet.')
param newVnetName string = ''

@description('Address prefix for the new spoke virtual network when networkMode is CreateNewVnet.')
param newVnetAddressPrefix string = '10.20.0.0/16'

@description('Name of the session host subnet to create when networkMode is CreateNewVnet.')
param newSessionHostSubnetName string = 'snet-avd-sessionhosts'

@description('Address prefix for the session host subnet when networkMode is CreateNewVnet.')
param newSessionHostSubnetPrefix string = '10.20.1.0/24'

@description('Name of the private endpoint subnet to create when networkMode is CreateNewVnet.')
param newPrivateEndpointSubnetName string = 'snet-avd-privateendpoints'

@description('Address prefix for the private endpoint subnet when networkMode is CreateNewVnet.')
param newPrivateEndpointSubnetPrefix string = '10.20.2.0/24'

@description('Resource ID of the existing hub virtual network to peer with when networkMode is CreateNewVnet.')
param hubVnetResourceId string = ''

@description('Host pool name')
param hostPoolName string = ''

@description('Resource group name that contains the existing host pool targeted by a brownfield action.')
param existingHostPoolResourceGroupName string = ''

@description('Existing workspaces related to the selected host pool.')
param existingWorkspaceNames array = []

@description('Existing application groups related to the selected host pool.')
param relatedApplicationGroupNames array = []

@description('Existing desktop application groups related to the selected host pool.')
param relatedDesktopApplicationGroupNames array = []

@description('Existing RemoteApp application groups related to the selected host pool.')
param relatedRemoteAppApplicationGroupNames array = []

@description('Detected load balancer type for the selected brownfield host pool.')
param brownfieldDetectedLoadBalancerType string = ''

@description('Detected preferred application group type for the selected brownfield host pool.')
param brownfieldDetectedPreferredAppGroupType string = ''

@description('Detected authentication posture for the selected brownfield host pool.')
param brownfieldDetectedAuthenticationType string = ''

@description('Detected diagnostic setting names already attached to the selected brownfield host pool.')
param brownfieldDetectedHostPoolDiagnosticSettingNames array = []

@description('Workspace names that already have at least one diagnostic setting detected in the selected brownfield host pool resource group.')
param brownfieldDetectedWorkspacesWithDiagnostics array = []

@description('Application group names that already have at least one diagnostic setting detected in the selected brownfield host pool resource group.')
param brownfieldDetectedApplicationGroupsWithDiagnostics array = []

@description('Detected scaling plan names already attached to the selected brownfield host pool.')
param brownfieldDetectedScalingPlanNames array = []

@description('Detected session host VM names currently registered to the selected brownfield host pool.')
param brownfieldDetectedSessionHostVmNames array = []

@description('Whether application group access assignment coverage was evaluated directly by the invoking workflow.')
param brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated bool = false

@description('Detected role assignment count across related desktop application groups.')
param brownfieldDetectedDesktopAssignmentCount int = 0

@description('Detected role assignment count across related RemoteApp application groups.')
param brownfieldDetectedRemoteAppAssignmentCount int = 0

@description('Detected direct user assignment count across related application groups.')
param brownfieldDetectedDirectUserAssignmentCount int = 0

@description('Detected group-based assignment count across related application groups.')
param brownfieldDetectedGroupAssignmentCount int = 0

@description('Detected FSLogix storage account name provided for operational summary assessment.')
param brownfieldDetectedFslogixStorageAccountName string = ''

@description('Detected FSLogix storage account resource ID provided for operational summary assessment.')
param brownfieldDetectedFslogixStorageAccountResourceId string = ''

@description('Detected public network access state for the FSLogix storage account under assessment.')
param brownfieldDetectedFslogixPublicNetworkAccess string = 'NotAssessed'

@description('Detected private endpoint connection count for the FSLogix storage account under assessment.')
param brownfieldDetectedFslogixPrivateEndpointCount int = 0

@description('Detected private DNS link state for the FSLogix storage assessment. Expected values are Linked, Missing, or NotAssessed.')
param brownfieldDetectedFslogixPrivateDnsLinkState string = 'NotAssessed'

@description('Detected VNet name used for the brownfield network posture assessment.')
param brownfieldDetectedNetworkVnetName string = ''

@description('Monitoring workspace mode for brownfield monitoring alignment.')
@allowed(['CreateNew', 'UseExisting'])
param brownfieldMonitoringWorkspaceMode string = 'CreateNew'

@description('Monitoring scope for brownfield monitoring alignment.')
@allowed(['ControlPlaneOnly', 'FullMonitoringPosture'])
param brownfieldMonitoringScope string = 'ControlPlaneOnly'

@description('Guest telemetry preset for brownfield full monitoring posture.')
@allowed(['Standard', 'Enhanced'])
param brownfieldMonitoringPreset string = 'Standard'

@description('Name of the Log Analytics workspace to create for brownfield monitoring alignment.')
param brownfieldMonitoringWorkspaceName string = ''

@description('Existing Log Analytics workspace resource ID to use for brownfield monitoring alignment.')
param brownfieldMonitoringExistingWorkspaceResourceId string = ''

@description('Retention in days for a newly created Log Analytics workspace used by brownfield monitoring alignment.')
@minValue(30)
@maxValue(730)
param brownfieldMonitoringRetentionDays int = 30

@description('Resource group name that contains existing session host VMs to onboard for brownfield full monitoring posture.')
param brownfieldMonitoringSessionHostVmResourceGroupName string = ''

@description('Existing session host VM names derived from the selected brownfield host pool and targeted for guest monitoring onboarding.')
param brownfieldMonitoringSessionHostVmNames array = []

@description('Resource ID of the existing FSLogix storage account targeted by brownfield reconciliation.')
param brownfieldFslogixStorageAccountResourceId string = ''

@description('DNS zone management mode for brownfield FSLogix reconciliation.')
@allowed(['CreateNew', 'Skip'])
param brownfieldFslogixPrivateDnsZoneMode string = 'CreateNew'

@description('Scaling plan name for brownfield scaling plan management.')
param scalingPlanName string = ''

@description('Friendly name for the brownfield scaling plan.')
param scalingPlanFriendlyName string = ''

@description('Description for the brownfield scaling plan.')
param scalingPlanDescription string = ''

@description('Time zone for brownfield scaling plan schedules.')
param scalingPlanTimeZone string = 'UTC'

@description('Optional exclusion tag for the brownfield scaling plan.')
param scalingPlanExclusionTag string = ''

@description('Weekday ramp-up start time in HH:mm format.')
param weekdayRampUpStartTime string = '06:00'

@description('Weekday peak start time in HH:mm format.')
param weekdayPeakStartTime string = '09:00'

@description('Weekday ramp-down start time in HH:mm format.')
param weekdayRampDownStartTime string = '17:00'

@description('Weekday off-peak start time in HH:mm format.')
param weekdayOffPeakStartTime string = '20:00'

@description('Weekend ramp-up start time in HH:mm format.')
param weekendRampUpStartTime string = '08:00'

@description('Weekend peak start time in HH:mm format.')
param weekendPeakStartTime string = '10:00'

@description('Weekend ramp-down start time in HH:mm format.')
param weekendRampDownStartTime string = '15:00'

@description('Weekend off-peak start time in HH:mm format.')
param weekendOffPeakStartTime string = '18:00'

@description('Load-balancing algorithm used during ramp-up.')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampUpLoadBalancingAlgorithm string = 'BreadthFirst'

@description('Load-balancing algorithm used during peak.')
@allowed(['BreadthFirst', 'DepthFirst'])
param peakLoadBalancingAlgorithm string = 'BreadthFirst'

@description('Load-balancing algorithm used during ramp-down.')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampDownLoadBalancingAlgorithm string = 'DepthFirst'

@description('Load-balancing algorithm used during off-peak.')
@allowed(['BreadthFirst', 'DepthFirst'])
param offPeakLoadBalancingAlgorithm string = 'DepthFirst'

@description('Minimum percentage of session hosts to keep running during ramp-up and off-peak periods.')
@minValue(0)
@maxValue(100)
param minimumHostsPct int = 20

@description('Capacity threshold percentage that triggers ramp-up and ramp-down transitions.')
@minValue(1)
@maxValue(100)
param capacityThresholdPct int = 75

@description('How long to wait before stopping hosts during ramp-down.')
@minValue(0)
param rampDownWaitTimeMinutes int = 30

@description('When a host can be stopped during ramp-down.')
@allowed(['ZeroSessions', 'ZeroActiveSessions'])
param rampDownStopHostsWhen string = 'ZeroSessions'

@description('Whether users should be forced off during ramp-down.')
param rampDownForceLogoffUsers bool = false

@description('Notification shown to users before forced logoff during ramp-down.')
param rampDownNotificationMessage string = 'This session host will be stopped by the Azure Virtual Desktop scaling plan.'

@description('Comma or newline separated Entra Object IDs to grant AVD access. Leave empty to skip role assignments.')
param avdUserObjectIds string = ''

@description('Typed access assignments for the desktop application group. Each item must include principalId and principalType.')
param desktopAccessAssignments array = []

@description('Typed access assignments for the RemoteApp application group. Each item must include principalId and principalType.')
param remoteAppAccessAssignments array = []

@description('RemoteApp definitions used when avdMode publishes RemoteApps. Each item must include name and filePath and can optionally include friendlyName, description, commandLineSetting, and commandLineArguments.')
param remoteApps array = []

@description('Per-deployment seed used to keep session host computer names unique across redeployments in the same resource group.')
param deploymentInstanceSeed string = utcNow('u')

var namingPrefix = '${deploymentPrefix}-${environment}'
var isExpandAddSessionHosts = deploymentScenario == 'ExpandExistingDeployment' && expandOperation == 'AddSessionHosts'
var isExpandAlignMonitoring = deploymentScenario == 'ExpandExistingDeployment' && expandOperation == 'AlignMonitoringPosture'
var isExpandVmBaselineRemediation = deploymentScenario == 'ExpandExistingDeployment' && expandOperation == 'RemediateVmImageBaseline'
var isDay2ScalingPlan = deploymentScenario == 'Day2Operations' && day2Operation == 'ConfigureScalingPlan'
var isDay2AlignMonitoring = deploymentScenario == 'Day2Operations' && day2Operation == 'AlignMonitoringPosture'
var isDay2UpdateAccessAssignments = deploymentScenario == 'Day2Operations' && day2Operation == 'UpdateAccessAssignments'
var isDay2ReconcileFsLogixPrivateConnectivity = deploymentScenario == 'Day2Operations' && day2Operation == 'ReconcileFsLogixPrivateConnectivity'
var isDay2GenerateOperationalSummary = deploymentScenario == 'Day2Operations' && day2Operation == 'GenerateOperationalSummary'
var isBrownfieldMonitoringAlignment = isExpandAlignMonitoring || isDay2AlignMonitoring
var isBrownfieldSessionHostReplacement = isExpandAddSessionHosts || isExpandVmBaselineRemediation
var isNewDeployment = deploymentScenario == 'NewDeployment'
var effectiveAvdMode = empty(avdMode) ? (hostPoolType == 'Personal' ? 'PersonalDesktop' : 'PooledDesktop') : avdMode
var effectiveHostPoolType = effectiveAvdMode == 'PersonalDesktop' ? 'Personal' : 'Pooled'
var publishDesktop = effectiveAvdMode == 'PersonalDesktop' || effectiveAvdMode == 'PooledDesktop' || effectiveAvdMode == 'PooledDesktopAndRemoteApp'
var publishRemoteApps = effectiveAvdMode == 'PooledRemoteApp' || effectiveAvdMode == 'PooledDesktopAndRemoteApp'
var effectiveExistingVnetResourceGroupName = empty(existingVnetResourceGroupName) ? resourceGroup().name : existingVnetResourceGroupName
var effectiveExistingHostPoolResourceGroupName = empty(existingHostPoolResourceGroupName) ? resourceGroup().name : existingHostPoolResourceGroupName
var desktopAppGroupName = 'dag-avd-${namingPrefix}'
var remoteAppGroupName = 'rag-avd-${namingPrefix}'
var newDeploymentSessionHostVmNames = [for i in range(0, sessionHostCount): 'vm-avd-${namingPrefix}-${i}']
var existingVnetId = resourceId(effectiveExistingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks', existingVnetName)
var normalizedAvdUserObjectIds = [for oid in split(replace(replace(avdUserObjectIds, '\r\n', ','), '\n', ','), ','): trim(oid)]
var legacyAccessAssignments = [for oid in normalizedAvdUserObjectIds: {
  principalId: oid
  principalType: 'User'
}]
var desktopEffectiveAssignments = union(desktopAccessAssignments, publishDesktop ? legacyAccessAssignments : [])
var remoteAppEffectiveAssignments = union(remoteAppAccessAssignments, publishRemoteApps ? legacyAccessAssignments : [])
var vmLoginEffectiveAssignments = union(desktopEffectiveAssignments, remoteAppEffectiveAssignments)
var effectiveSessionHostSecurityType = sessionHostSecurityType == 'TrustedLaunch' || (sessionHostSecurityType == 'Auto' && imageSource == 'AzureComputeGallery')
  ? 'TrustedLaunch'
  : 'Standard'
var sessionHostImageReference = imageSource == 'AzureComputeGallery'
  ? {
      id: resourceId(galleryImageSubscriptionId, galleryImageResourceGroupName, 'Microsoft.Compute/galleries/images/versions', galleryName, galleryImageDefinitionName, galleryImageVersion)
    }
  : {
      publisher: marketplaceImagePublisher
      offer: marketplaceImageOffer
      sku: marketplaceImageSku
      version: marketplaceImageVersion
    }
var tags = {
  Environment: environment
  Project: 'AVD-Landing-Zone'
  DeployedBy: 'Bicep'
}
var operationalSummaryLoadBalancerType = empty(brownfieldDetectedLoadBalancerType) ? 'Unknown' : brownfieldDetectedLoadBalancerType
var operationalSummaryPreferredAppGroupType = empty(brownfieldDetectedPreferredAppGroupType) ? 'Unknown' : brownfieldDetectedPreferredAppGroupType
var operationalSummaryAuthenticationType = empty(brownfieldDetectedAuthenticationType) ? 'Unknown' : brownfieldDetectedAuthenticationType
var operationalSummaryFslogixAssessmentProvided = !empty(brownfieldDetectedFslogixStorageAccountResourceId)
var operationalSummaryFindings = concat(
  isDay2GenerateOperationalSummary && length(brownfieldDetectedHostPoolDiagnosticSettingNames) == 0 ? [
    {
      code: 'HOSTPOOL_DIAGNOSTICS_MISSING'
      severity: 'High'
      category: 'Monitoring'
      bestPractice: 'Enable diagnostic settings for the host pool and related AVD control-plane resources.'
      observedState: 'No host pool diagnostic settings were detected for the selected brownfield host pool.'
      impact: 'Control-plane troubleshooting, auditing, and change correlation are reduced.'
      recommendedAction: 'Run AlignMonitoringPosture to enable control-plane diagnostics.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'AlignMonitoringPosture'
    }
  ] : [],
  isDay2GenerateOperationalSummary && effectiveHostPoolType == 'Pooled' && length(brownfieldDetectedScalingPlanNames) == 0 ? [
    {
      code: 'SCALING_PLAN_MISSING'
      severity: 'Medium'
      category: 'Resilience'
      bestPractice: 'Use a scaling plan for pooled host pools to control cost and operational readiness.'
      observedState: 'No scaling plan attachment was detected for the selected pooled host pool.'
      impact: 'Session host capacity and cost posture may drift because start/stop behavior is unmanaged.'
      recommendedAction: 'Run ConfigureScalingPlan to create or attach a scaling plan.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'ConfigureScalingPlan'
    }
  ] : [],
  isDay2GenerateOperationalSummary && length(existingWorkspaceNames) == 0 ? [
    {
      code: 'WORKSPACE_LINK_MISSING'
      severity: 'High'
      category: 'Governance'
      bestPractice: 'Ensure each published application group is linked to a workspace so resources are consumable and discoverable.'
      observedState: 'No related workspaces were detected for the selected host pool.'
      impact: 'Users may not see the intended desktop or RemoteApp publications, and operator intent is unclear.'
      recommendedAction: 'Review workspace linkage for the host pool application groups.'
      canBeMitigatedBySolutionAction: false
      recommendedActionName: 'ManualFollowUp'
    }
  ] : [],
  isDay2GenerateOperationalSummary && length(relatedApplicationGroupNames) == 0 ? [
    {
      code: 'APPLICATION_GROUPS_MISSING'
      severity: 'High'
      category: 'Governance'
      bestPractice: 'Maintain application groups for published desktops or RemoteApps and keep them linked to the target host pool.'
      observedState: 'No related application groups were detected for the selected host pool.'
      impact: 'The host pool may not expose user-facing resources, or the environment may have drifted from the intended design.'
      recommendedAction: 'Review application group linkage and publication design for the selected host pool.'
      canBeMitigatedBySolutionAction: false
      recommendedActionName: 'ManualFollowUp'
    }
  ] : [],
  isDay2GenerateOperationalSummary && length(brownfieldDetectedSessionHostVmNames) == 0 ? [
    {
      code: 'SESSION_HOSTS_MISSING'
      severity: 'High'
      category: 'Resilience'
      bestPractice: 'Maintain at least one healthy registered session host for active host pools.'
      observedState: 'No registered session hosts were detected for the selected host pool.'
      impact: 'User connectivity and maintenance readiness are at risk because no serving capacity is visible.'
      recommendedAction: 'Investigate session host registration and add or repair session hosts if required.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'AddSessionHosts'
    }
  ] : [],
  isDay2GenerateOperationalSummary && operationalSummaryAuthenticationType != 'EntraID' ? [
    {
      code: 'HYBRID_JOIN_POSTURE_DETECTED'
      severity: 'Informational'
      category: 'Identity'
      bestPractice: 'Prefer a clearly documented identity posture with least privilege and validated network dependencies.'
      observedState: 'The selected host pool appears to use a HybridJoin posture instead of Entra ID joined session hosts.'
      impact: 'Operational dependencies on line-of-sight identity services, DNS, and NSG rules remain important for day-2 support.'
      recommendedAction: 'Review HybridJoin network, DNS, and identity dependencies as part of day-2 operations.'
      canBeMitigatedBySolutionAction: false
      recommendedActionName: 'ManualFollowUp'
    }
  ] : [],
  isDay2GenerateOperationalSummary && length(existingWorkspaceNames) > 0 && length(brownfieldDetectedWorkspacesWithDiagnostics) < length(existingWorkspaceNames) ? [
    {
      code: 'WORKSPACE_DIAGNOSTICS_PARTIAL_OR_MISSING'
      severity: 'Medium'
      category: 'Monitoring'
      bestPractice: 'Enable diagnostic settings on all related AVD workspaces so workspace-level operations and publication flow are observable.'
      observedState: 'One or more related workspaces do not appear to have diagnostic settings in the selected host pool resource group.'
      impact: 'Workspace-level operational gaps can delay troubleshooting and reduce audit visibility.'
      recommendedAction: 'Run AlignMonitoringPosture and verify workspace diagnostics coverage for every related workspace.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'AlignMonitoringPosture'
    }
  ] : [],
  isDay2GenerateOperationalSummary && length(relatedApplicationGroupNames) > 0 && length(brownfieldDetectedApplicationGroupsWithDiagnostics) < length(relatedApplicationGroupNames) ? [
    {
      code: 'APPLICATION_GROUP_DIAGNOSTICS_PARTIAL_OR_MISSING'
      severity: 'Medium'
      category: 'Monitoring'
      bestPractice: 'Enable diagnostic settings on every related application group to capture publication and connection-plane events consistently.'
      observedState: 'One or more related application groups do not appear to have diagnostic settings in the selected host pool resource group.'
      impact: 'Operational visibility is inconsistent across published desktops and RemoteApps.'
      recommendedAction: 'Run AlignMonitoringPosture and verify application group diagnostics coverage.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'AlignMonitoringPosture'
    }
  ] : [],
  isDay2GenerateOperationalSummary && brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated && (brownfieldDetectedDesktopAssignmentCount + brownfieldDetectedRemoteAppAssignmentCount) == 0 && length(relatedApplicationGroupNames) > 0 ? [
    {
      code: 'APPLICATION_GROUP_ASSIGNMENTS_NOT_CONFIRMED'
      severity: 'Informational'
      category: 'Access'
      bestPractice: 'Validate application group access with the authoritative collector before declaring missing access assignments.'
      observedState: 'The managed app portal preview did not confirm role assignments across the related application groups. This preview can miss inherited, paged, or scope-specific RBAC evidence.'
      impact: 'Portal preview evidence is incomplete; use the collector-backed operational summary before treating access as missing.'
      recommendedAction: 'Review the collector-backed summary report or rerun operational summary collection with the managed identity that has target-scope role assignment read access.'
      canBeMitigatedBySolutionAction: false
      recommendedActionName: 'ReviewCollectorReport'
    }
  ] : [],
  isDay2GenerateOperationalSummary && brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated && brownfieldDetectedDirectUserAssignmentCount > 0 ? [
    {
      code: 'DIRECT_USER_ASSIGNMENTS_DETECTED'
      severity: 'Low'
      category: 'Access'
      bestPractice: 'Prefer group-based application group access over direct-user assignments for cleaner lifecycle management and access reviews.'
      observedState: 'Direct-user assignments were detected across one or more related application groups.'
      impact: 'Access reviews and identity lifecycle hygiene become harder as direct assignments accumulate.'
      recommendedAction: 'Review whether direct-user assignments can be consolidated into group-based access.'
      canBeMitigatedBySolutionAction: false
      recommendedActionName: 'ManualFollowUp'
    }
  ] : [],
  isDay2GenerateOperationalSummary && operationalSummaryFslogixAssessmentProvided && brownfieldDetectedFslogixPublicNetworkAccess != 'Disabled' ? [
    {
      code: 'FSLOGIX_STORAGE_PUBLIC_NETWORK_ENABLED'
      severity: 'High'
      category: 'Security'
      bestPractice: 'Disable public network access on FSLogix profile storage when private connectivity is the intended posture.'
      observedState: 'The assessed FSLogix storage account does not report public network access as Disabled.'
      impact: 'Profile storage may be more exposed than intended and can drift from the hardened private-access design.'
      recommendedAction: 'Review FSLogix storage network exposure and reconcile private connectivity if needed.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'ReconcileFsLogixPrivateConnectivity'
    }
  ] : [],
  isDay2GenerateOperationalSummary && operationalSummaryFslogixAssessmentProvided && brownfieldDetectedFslogixPrivateEndpointCount == 0 ? [
    {
      code: 'FSLOGIX_PRIVATE_ENDPOINT_MISSING'
      severity: 'High'
      category: 'Network'
      bestPractice: 'Use a private endpoint for FSLogix profile storage in private-access AVD topologies.'
      observedState: 'No private endpoint connections were detected for the assessed FSLogix storage account.'
      impact: 'Profile connectivity may rely on broader network exposure and is less aligned with private connectivity guidance.'
      recommendedAction: 'Run ReconcileFsLogixPrivateConnectivity to create a private endpoint for the FSLogix storage account.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'ReconcileFsLogixPrivateConnectivity'
    }
  ] : [],
  isDay2GenerateOperationalSummary && operationalSummaryFslogixAssessmentProvided && brownfieldDetectedFslogixPrivateDnsLinkState == 'Missing' ? [
    {
      code: 'FSLOGIX_PRIVATE_DNS_LINK_MISSING'
      severity: 'Medium'
      category: 'Network'
      bestPractice: 'Link the private DNS zone used by the FSLogix file endpoint to the session host VNet when private endpoints are in use.'
      observedState: 'The assessed private DNS zone does not appear linked to the selected VNet.'
      impact: 'Name resolution for the private file endpoint may fail or require manual overrides.'
      recommendedAction: 'Review private DNS linkage for the assessed FSLogix storage endpoint and VNet.'
      canBeMitigatedBySolutionAction: true
      recommendedActionName: 'ReconcileFsLogixPrivateConnectivity'
    }
  ] : []
)
var operationalSummaryCriticalCount = length(filter(operationalSummaryFindings, (finding) => finding.severity == 'Critical'))
var operationalSummaryHighCount = length(filter(operationalSummaryFindings, (finding) => finding.severity == 'High'))
var operationalSummaryMediumCount = length(filter(operationalSummaryFindings, (finding) => finding.severity == 'Medium'))
var operationalSummaryLowCount = length(filter(operationalSummaryFindings, (finding) => finding.severity == 'Low'))
var operationalSummaryInformationalCount = length(filter(operationalSummaryFindings, (finding) => finding.severity == 'Informational'))
var operationalSummaryOverallStatus = operationalSummaryCriticalCount > 0
  ? 'HighRisk'
  : (operationalSummaryHighCount > 0
    ? 'NeedsAttention'
    : (operationalSummaryMediumCount > 0
      ? 'Monitor'
      : 'Healthy'))
var operationalSummaryTopRecommendations = take(map(filter(operationalSummaryFindings, (finding) => finding.severity != 'Informational'), (finding) => {
  priority: finding.severity
  action: finding.recommendedAction
  actionName: finding.recommendedActionName
  category: finding.category
  canBeMitigatedBySolutionAction: finding.canBeMitigatedBySolutionAction
}), 5)
var operationalSummaryObject = isDay2GenerateOperationalSummary
  ? {
      reportMetadata: {
        reportVersion: '1.0'
        generatedAtUtc: deploymentInstanceSeed
        scope: {
          deploymentScenario: deploymentScenario
          day2Operation: day2Operation
          location: location
          resourceGroupName: effectiveExistingHostPoolResourceGroupName
          hostPoolName: hostPoolName
        }
      }
      executiveSummary: {
        overallStatus: operationalSummaryOverallStatus
        findingCounts: {
          critical: operationalSummaryCriticalCount
          high: operationalSummaryHighCount
          medium: operationalSummaryMediumCount
          low: operationalSummaryLowCount
          informational: operationalSummaryInformationalCount
        }
        topRecommendations: operationalSummaryTopRecommendations
        confidence: 'Medium'
        summaryText: 'Read-only day-2 posture summary generated from host pool, application group, workspace, scaling plan, session host, and host pool diagnostic discovery.'
      }
      targetSummary: {
        hostPoolName: hostPoolName
        resourceGroupName: effectiveExistingHostPoolResourceGroupName
        location: location
        hostPoolType: effectiveHostPoolType
        loadBalancerType: operationalSummaryLoadBalancerType
        preferredAppGroupType: operationalSummaryPreferredAppGroupType
        authenticationType: operationalSummaryAuthenticationType
      }
      relatedResources: {
        applicationGroupCount: length(relatedApplicationGroupNames)
        applicationGroups: relatedApplicationGroupNames
        workspaceCount: length(existingWorkspaceNames)
        workspaces: existingWorkspaceNames
        sessionHostCount: length(brownfieldDetectedSessionHostVmNames)
        sessionHostNames: brownfieldDetectedSessionHostVmNames
      }
      monitoringPosture: {
        hostPoolDiagnosticSettingNames: brownfieldDetectedHostPoolDiagnosticSettingNames
        hostPoolDiagnosticsState: length(brownfieldDetectedHostPoolDiagnosticSettingNames) > 0 ? 'Present' : 'Missing'
        workspaceDiagnosticsCoverage: {
          relatedWorkspaceCount: length(existingWorkspaceNames)
          workspacesWithDiagnostics: brownfieldDetectedWorkspacesWithDiagnostics
          coverageState: length(existingWorkspaceNames) == 0
            ? 'NotApplicable'
            : (length(brownfieldDetectedWorkspacesWithDiagnostics) == length(existingWorkspaceNames) ? 'Complete' : 'PartialOrMissing')
        }
        applicationGroupDiagnosticsCoverage: {
          relatedApplicationGroupCount: length(relatedApplicationGroupNames)
          applicationGroupsWithDiagnostics: brownfieldDetectedApplicationGroupsWithDiagnostics
          coverageState: length(relatedApplicationGroupNames) == 0
            ? 'NotApplicable'
            : (length(brownfieldDetectedApplicationGroupsWithDiagnostics) == length(relatedApplicationGroupNames) ? 'Complete' : 'PartialOrMissing')
        }
        controlPlaneCoverage: length(brownfieldDetectedHostPoolDiagnosticSettingNames) > 0 ? 'HostPoolDetected' : 'NoneDetected'
        guestMonitoringState: 'NotAssessedByCurrentDiscovery'
      }
      identityPosture: {
        authenticationType: operationalSummaryAuthenticationType
        desktopAssignmentCount: brownfieldDetectedDesktopAssignmentCount
        remoteAppAssignmentCount: brownfieldDetectedRemoteAppAssignmentCount
        directUserAssignmentCount: brownfieldDetectedDirectUserAssignmentCount
        groupAssignmentCount: brownfieldDetectedGroupAssignmentCount
        accessAssignmentsCoverageEvaluated: brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated
        accessAssignmentsState: !brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated
          ? 'NotEvaluatedInPortal'
          : ((brownfieldDetectedDesktopAssignmentCount + brownfieldDetectedRemoteAppAssignmentCount) > 0 ? 'Detected' : 'NotConfirmedByPortalPreview')
      }
      fslogixPosture: {
        assessmentState: operationalSummaryFslogixAssessmentProvided ? 'Assessed' : 'NotAssessed'
        storageAccountName: brownfieldDetectedFslogixStorageAccountName
        storageAccountResourceId: brownfieldDetectedFslogixStorageAccountResourceId
        publicNetworkAccess: brownfieldDetectedFslogixPublicNetworkAccess
        privateEndpointConnectionCount: brownfieldDetectedFslogixPrivateEndpointCount
        privateDnsLinkState: brownfieldDetectedFslogixPrivateDnsLinkState
      }
      networkPosture: {
        assessmentState: !empty(brownfieldDetectedNetworkVnetName) ? 'AssessedFromSelectedVnet' : 'NotAssessedByCurrentDiscovery'
        selectedVnetName: brownfieldDetectedNetworkVnetName
        notes: [
          operationalSummaryFslogixAssessmentProvided ? 'FSLogix network posture was assessed from the selected storage account and optional VNet and private DNS selections in the managed app UI.' : 'Provide an FSLogix storage account and optional VNet/private DNS zone selection in the summary workflow to assess private connectivity posture.'
        ]
      }
      resiliencePosture: {
        scalingPlanNames: brownfieldDetectedScalingPlanNames
        scalingPlanState: effectiveHostPoolType == 'Pooled'
          ? (length(brownfieldDetectedScalingPlanNames) > 0 ? 'Present' : 'Missing')
          : 'NotApplicable'
        sessionHostCount: length(brownfieldDetectedSessionHostVmNames)
        readiness: length(brownfieldDetectedSessionHostVmNames) > 0 ? 'CapacityDetected' : 'NoCapacityDetected'
      }
      governanceAndDrift: {
        workspaceLinkageState: length(existingWorkspaceNames) > 0 ? 'Linked' : 'Missing'
        applicationGroupState: length(relatedApplicationGroupNames) > 0 ? 'Present' : 'Missing'
      }
      bestPracticeGapRegister: operationalSummaryFindings
      recommendations: operationalSummaryTopRecommendations
      discoveryCoverage: {
        assessed: [
          'Host pool control-plane properties'
          'Related application groups'
          'Related workspaces'
          'Host pool diagnostic settings'
          'Workspace diagnostic coverage derived from resource-group resource discovery'
          'Application group diagnostic coverage derived from resource-group resource discovery'
          'Scaling plan attachments'
          'Registered session host names'
          'Application group access assignment counts derived from role assignment discovery'
          'FSLogix storage public network access and private endpoint count when a storage account is provided'
        ]
        notAssessed: [
          'Guest AMA and DCR coverage'
          'NSG rule posture'
          'Subnet route and firewall posture'
          'Guest OS configuration drift'
        ]
      }
    }
  : {
      reportMetadata: {
        reportVersion: '1.0'
      }
      executiveSummary: {
        overallStatus: 'NotRequested'
      }
    }

module network './modules/network.bicep' = if (isNewDeployment && networkMode == 'CreateNewVnet') {
  name: 'deploy-network'
  params: {
    location: location
    vnetName: newVnetName
    vnetAddressPrefix: newVnetAddressPrefix
    sessionHostSubnetName: newSessionHostSubnetName
    sessionHostSubnetPrefix: newSessionHostSubnetPrefix
    privateEndpointSubnetName: newPrivateEndpointSubnetName
    privateEndpointSubnetPrefix: newPrivateEndpointSubnetPrefix
    hubVnetResourceId: hubVnetResourceId
    removeStorageServiceEndpoint: deployFSLogixPrivateEndpoint
    tags: tags
  }
}

var vnetId = networkMode == 'CreateNewVnet' ? network!.outputs.vnetId : existingVnetId
var sessionHostSubnetId = networkMode == 'CreateNewVnet'
  ? network!.outputs.sessionHostSubnetId
  : resourceId(effectiveExistingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, sessionHostSubnetName)
var privateEndpointSubnetId = isNewDeployment ? (networkMode == 'CreateNewVnet'
  ? network!.outputs.privateEndpointSubnetId
  : resourceId(effectiveExistingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, privateEndpointSubnetName)) : 'N/A'

module hostPool './modules/hostpool.bicep' = if (isNewDeployment) {
  name: 'deploy-hostpool'
  dependsOn: [
    network
  ]
  params: {
    location: location
    hostPoolName: hostPoolName
    hostPoolType: effectiveHostPoolType
    workspaceName: 'ws-avd-${namingPrefix}'
    desktopAppGroupName: desktopAppGroupName
    remoteAppGroupName: remoteAppGroupName
    publishDesktop: publishDesktop
    publishRemoteApps: publishRemoteApps
    authenticationType: authenticationType
    remoteApps: remoteApps
    tags: tags
  }
}

module sessionHosts './modules/sessionhosts.bicep' = if (isNewDeployment) {
  name: 'deploy-sessionhosts'
  params: {
    location: location
    sessionHostCount: sessionHostCount
    vmSize: vmSize
    sessionHostSecurityType: effectiveSessionHostSecurityType
    imageReference: sessionHostImageReference
    subnetId: sessionHostSubnetId
    hostPoolName: isExpandAddSessionHosts ? hostPoolName : hostPool!.outputs.hostPoolName
    adminUsername: adminUsername
    adminPassword: adminPassword
    authenticationType: authenticationType
    domainFqdn: domainFqdn
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    domainJoinOuPath: domainJoinOuPath
    deploymentInstanceSeed: deploymentInstanceSeed
    vmNamePrefix: 'vm-avd-${namingPrefix}'
    tags: tags
  }
}

module expandedSessionHosts './modules/sessionhosts.bicep' = if (isBrownfieldSessionHostReplacement) {
  name: 'expand-sessionhosts'
  scope: resourceGroup(effectiveExistingHostPoolResourceGroupName)
  params: {
    location: location
    sessionHostCount: sessionHostCount
    vmSize: vmSize
    sessionHostSecurityType: effectiveSessionHostSecurityType
    imageReference: sessionHostImageReference
    subnetId: sessionHostSubnetId
    hostPoolName: hostPoolName
    adminUsername: adminUsername
    adminPassword: adminPassword
    authenticationType: authenticationType
    domainFqdn: domainFqdn
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    domainJoinOuPath: domainJoinOuPath
    deploymentInstanceSeed: deploymentInstanceSeed
    vmNamePrefix: 'vm-avd-${namingPrefix}'
    tags: tags
  }
}

module brownfieldAccessAssignments './modules/brownfieldAccessAssignments.bicep' = if (isDay2UpdateAccessAssignments) {
  name: 'update-brownfield-access'
  scope: resourceGroup(effectiveExistingHostPoolResourceGroupName)
  params: {
    desktopApplicationGroupNames: relatedDesktopApplicationGroupNames
    remoteAppApplicationGroupNames: relatedRemoteAppApplicationGroupNames
    desktopAccessAssignments: desktopAccessAssignments
    remoteAppAccessAssignments: remoteAppAccessAssignments
  }
}

module fslogix './modules/fslogix.bicep' = if (isNewDeployment && deployFSLogix) {
  name: 'deploy-fslogix'
  params: {
    location: location
    storageAccountName: storageAccountName
    sessionHostSubnetId: sessionHostSubnetId
    deployPrivateEndpoint: deployFSLogixPrivateEndpoint
    tags: tags
  }
}

module fslogixDns './modules/fslogixPrivateDns.bicep' = if (isNewDeployment && deployFSLogix && deployFSLogixPrivateEndpoint) {
  name: 'deploy-fslogix-pe'
  params: {
    location: location
    storageAccountId: deployFSLogix ? fslogix!.outputs.storageAccountId : ''
    privateEndpointSubnetId: privateEndpointSubnetId
    vnetId: vnetId
    tags: tags
  }
}

module monitoring './modules/monitoring.bicep' = if (isNewDeployment && deployMonitoring) {
  name: 'deploy-monitoring'
  dependsOn: [
    network
  ]
  params: {
    location: location
    workspaceName: 'log-avd-${namingPrefix}'
    dataCollectionRuleName: 'dcr-avd-${namingPrefix}'
    monitoringPreset: 'Enhanced'
    tags: tags
  }
}

module sessionHostMonitoringAssociation './modules/existingVmMonitoringAssociation.bicep' = [for vmName in (isNewDeployment && deployMonitoring ? newDeploymentSessionHostVmNames : []): {
  name: 'associate-monitoring-${take(vmName, 40)}'
  params: {
    location: location
    vmName: vmName
    dataCollectionRuleId: monitoring!.outputs.dataCollectionRuleId
    tags: tags
  }
}]

module scalingPlan './modules/scalingPlan.bicep' = if (isDay2ScalingPlan) {
  name: 'configure-scaling-plan'
  scope: resourceGroup(effectiveExistingHostPoolResourceGroupName)
  params: {
    location: location
    hostPoolName: hostPoolName
    hostPoolResourceGroupName: effectiveExistingHostPoolResourceGroupName
    scalingPlanName: scalingPlanName
    scalingPlanFriendlyName: scalingPlanFriendlyName
    scalingPlanDescription: scalingPlanDescription
    scalingPlanTimeZone: scalingPlanTimeZone
    scalingPlanExclusionTag: scalingPlanExclusionTag
    weekdayRampUpStartTime: weekdayRampUpStartTime
    weekdayPeakStartTime: weekdayPeakStartTime
    weekdayRampDownStartTime: weekdayRampDownStartTime
    weekdayOffPeakStartTime: weekdayOffPeakStartTime
    weekendRampUpStartTime: weekendRampUpStartTime
    weekendPeakStartTime: weekendPeakStartTime
    weekendRampDownStartTime: weekendRampDownStartTime
    weekendOffPeakStartTime: weekendOffPeakStartTime
    rampUpLoadBalancingAlgorithm: rampUpLoadBalancingAlgorithm
    peakLoadBalancingAlgorithm: peakLoadBalancingAlgorithm
    rampDownLoadBalancingAlgorithm: rampDownLoadBalancingAlgorithm
    offPeakLoadBalancingAlgorithm: offPeakLoadBalancingAlgorithm
    minimumHostsPct: minimumHostsPct
    capacityThresholdPct: capacityThresholdPct
    rampDownWaitTimeMinutes: rampDownWaitTimeMinutes
    rampDownStopHostsWhen: rampDownStopHostsWhen
    rampDownForceLogoffUsers: rampDownForceLogoffUsers
    rampDownNotificationMessage: rampDownNotificationMessage
    tags: tags
  }
}

module brownfieldMonitoring './modules/brownfieldMonitoring.bicep' = if (isBrownfieldMonitoringAlignment) {
  name: 'align-brownfield-monitoring'
  scope: resourceGroup(effectiveExistingHostPoolResourceGroupName)
  params: {
    location: location
    hostPoolName: hostPoolName
    workspaceNames: existingWorkspaceNames
    applicationGroupNames: relatedApplicationGroupNames
    createWorkspace: brownfieldMonitoringWorkspaceMode == 'CreateNew'
    monitoringScope: brownfieldMonitoringScope
    monitoringPreset: brownfieldMonitoringPreset
    workspaceName: brownfieldMonitoringWorkspaceName
    existingWorkspaceResourceId: brownfieldMonitoringExistingWorkspaceResourceId
    retentionDays: brownfieldMonitoringRetentionDays
    sessionHostVmResourceGroupName: brownfieldMonitoringSessionHostVmResourceGroupName
    sessionHostVmNames: brownfieldMonitoringSessionHostVmNames
    enableHostPoolDiagnostics: true
    enableWorkspaceDiagnostics: true
    enableApplicationGroupDiagnostics: true
    tags: tags
  }
}

module brownfieldFslogixPrivateDns './modules/fslogixPrivateDns.bicep' = if (isDay2ReconcileFsLogixPrivateConnectivity) {
  name: 'reconcile-brownfield-fslogix'
  scope: resourceGroup(last(take(split(brownfieldFslogixStorageAccountResourceId, '/'), 5)))
  params: {
    location: location
    storageAccountId: brownfieldFslogixStorageAccountResourceId
    privateEndpointSubnetId: resourceId(effectiveExistingVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', existingVnetName, privateEndpointSubnetName)
    vnetId: existingVnetId
    privateDnsZoneMode: brownfieldFslogixPrivateDnsZoneMode
    tags: tags
  }
}

resource monitoredHostPool 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = if (isNewDeployment && deployMonitoring) {
  name: hostPoolName
}

resource monitoredWorkspace 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' existing = if (isNewDeployment && deployMonitoring) {
  name: 'ws-avd-${namingPrefix}'
}

resource monitoredFslogixStorage 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (isNewDeployment && deployFSLogix && deployMonitoring) {
  name: storageAccountName
}

resource monitoredFslogixFileService 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' existing = if (isNewDeployment && deployFSLogix && deployMonitoring) {
  parent: monitoredFslogixStorage
  name: 'default'
}

resource desktopAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' existing = if (isNewDeployment && publishDesktop) {
  name: desktopAppGroupName
}

resource remoteAppGroup 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' existing = if (isNewDeployment && publishRemoteApps) {
  name: remoteAppGroupName
}

#disable-next-line use-recent-api-versions // The linter currently suggests 2016-09-01 for diagnosticSettings, which is older than the working API surface used here.
resource hostPoolDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (isNewDeployment && deployMonitoring) {
  name: 'diag-hostpool-to-law'
  scope: monitoredHostPool
  properties: {
    workspaceId: monitoring!.outputs.workspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions // The linter currently suggests 2016-09-01 for diagnosticSettings, which is older than the working API surface used here.
resource avdWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (isNewDeployment && deployMonitoring) {
  name: 'diag-workspace-to-law'
  scope: monitoredWorkspace
  properties: {
    workspaceId: monitoring!.outputs.workspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions // The linter currently suggests 2016-09-01 for diagnosticSettings, which is older than the working API surface used here.
resource desktopAppGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (isNewDeployment && deployMonitoring && publishDesktop) {
  name: 'diag-desktop-appgroup-to-law'
  scope: desktopAppGroup
  properties: {
    workspaceId: monitoring!.outputs.workspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions // The linter currently suggests 2016-09-01 for diagnosticSettings, which is older than the working API surface used here.
resource remoteAppGroupDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (isNewDeployment && deployMonitoring && publishRemoteApps) {
  name: 'diag-remoteapp-appgroup-to-law'
  scope: remoteAppGroup
  properties: {
    workspaceId: monitoring!.outputs.workspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

#disable-next-line use-recent-api-versions // The linter currently suggests 2016-09-01 for diagnosticSettings, which is older than the working API surface used here.
resource fslogixStorageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (isNewDeployment && deployFSLogix && deployMonitoring) {
  name: 'diag-fslogix-storage-to-law'
  scope: monitoredFslogixFileService
  properties: {
    workspaceId: monitoring!.outputs.workspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
  }
}

resource desktopAvdUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in desktopEffectiveAssignments: if (isNewDeployment && publishDesktop && !empty(string(assignment.principalId))) {
  name: guid(resourceGroup().id, desktopAppGroupName, string(assignment.principalType), string(assignment.principalId), '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
  scope: desktopAppGroup
  dependsOn: [
    hostPool
  ]
  properties: {
    principalId: string(assignment.principalId)
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalType: string(assignment.principalType)
  }
}]

resource remoteAppAvdUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in remoteAppEffectiveAssignments: if (isNewDeployment && publishRemoteApps && !empty(string(assignment.principalId))) {
  name: guid(resourceGroup().id, remoteAppGroupName, string(assignment.principalType), string(assignment.principalId), '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
  scope: remoteAppGroup
  dependsOn: [
    hostPool
  ]
  properties: {
    principalId: string(assignment.principalId)
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
    principalType: string(assignment.principalType)
  }
}]

resource vmLoginRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in vmLoginEffectiveAssignments: if (isNewDeployment && authenticationType == 'EntraID' && !empty(string(assignment.principalId)) && string(assignment.principalType) != 'ServicePrincipal') {
  name: guid(resourceGroup().id, string(assignment.principalType), string(assignment.principalId), 'fb879df8-f326-4884-b1cf-06f3ad86be52')
  properties: {
    principalId: string(assignment.principalId)
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
    principalType: string(assignment.principalType)
  }
}]

output hostPoolName string = isNewDeployment ? hostPool!.outputs.hostPoolName : hostPoolName
output workspaceId string = isNewDeployment ? hostPool!.outputs.workspaceId : 'N/A'
output desktopAppGroupId string = isNewDeployment ? hostPool!.outputs.desktopAppGroupId : 'N/A'
output remoteAppGroupId string = isNewDeployment ? hostPool!.outputs.remoteAppGroupId : 'N/A'
output publishedAppGroupIds array = isNewDeployment ? hostPool!.outputs.publishedAppGroupIds : []
output vnetId string = (isNewDeployment && networkMode == 'CreateNewVnet') ? vnetId : existingVnetId
output privateEndpointSubnetId string = isNewDeployment ? privateEndpointSubnetId : 'N/A'
output sessionHostVmNames array = isNewDeployment ? sessionHosts!.outputs.vmNames : (isBrownfieldSessionHostReplacement ? expandedSessionHosts!.outputs.vmNames : [])
output expandOperation string = expandOperation
output day2Operation string = day2Operation
output fslogixStorageAccount string = isNewDeployment ? (deployFSLogix ? fslogix!.outputs.storageAccountName : 'N/A') : 'N/A'
output fslogixPrivateEndpointId string = isNewDeployment ? ((deployFSLogix && deployFSLogixPrivateEndpoint) ? fslogixDns!.outputs.privateEndpointId : 'N/A') : (isDay2ReconcileFsLogixPrivateConnectivity ? brownfieldFslogixPrivateDns!.outputs.privateEndpointId : 'N/A')
output logAnalyticsWorkspace string = isNewDeployment ? (deployMonitoring ? monitoring!.outputs.workspaceName : 'N/A') : (isBrownfieldMonitoringAlignment ? brownfieldMonitoring!.outputs.workspaceName : 'N/A')
output logAnalyticsWorkspaceId string = isNewDeployment ? (deployMonitoring ? monitoring!.outputs.workspaceId : 'N/A') : (isBrownfieldMonitoringAlignment ? brownfieldMonitoring!.outputs.workspaceId : 'N/A')
output monitoringDataCollectionRuleId string = isNewDeployment ? (deployMonitoring ? monitoring!.outputs.dataCollectionRuleId : 'N/A') : (isBrownfieldMonitoringAlignment ? brownfieldMonitoring!.outputs.dataCollectionRuleId : 'N/A')
output scalingPlanName string = isDay2ScalingPlan ? scalingPlan!.outputs.scalingPlanName : 'N/A'
output scalingPlanId string = isDay2ScalingPlan ? scalingPlan!.outputs.scalingPlanId : 'N/A'
output deploymentScenario string = deploymentScenario
output effectiveAvdMode string = effectiveAvdMode
output avdRolesAssigned bool = isNewDeployment ? (length(desktopEffectiveAssignments) > 0 || length(remoteAppEffectiveAssignments) > 0) : isDay2UpdateAccessAssignments
output operationalSummary object = operationalSummaryObject
output operationalGapRegister array = isDay2GenerateOperationalSummary ? operationalSummaryFindings : []
output brownfieldOperationSummary string = isExpandAddSessionHosts
  ? 'AddSessionHosts will create new session host VMs in the selected host pool resource group and register them against the existing host pool.'
  : (isExpandVmBaselineRemediation
    ? 'RemediateVmImageBaseline will stage replacement session hosts with the requested VM size and image baseline in the selected host pool. Existing hosts are not removed automatically.'
  : (isBrownfieldMonitoringAlignment
    ? 'AlignMonitoringPosture will enable control-plane diagnostic settings for the selected host pool, related workspaces, and related application groups.'
    : (isDay2ScalingPlan
      ? 'ConfigureScalingPlan will create or update the scaling plan attachment for the selected pooled host pool without recreating session hosts.'
      : (isDay2UpdateAccessAssignments
        ? 'UpdateAccessAssignments will apply AVD user role assignments across the discovered desktop and RemoteApp application groups.'
        : (isDay2ReconcileFsLogixPrivateConnectivity
          ? 'ReconcileFsLogixPrivateConnectivity will create a private endpoint for the selected FSLogix storage account and optionally create and link the private DNS zone to the selected VNet.'
          : (isDay2GenerateOperationalSummary
            ? 'GenerateOperationalSummary is a read-only brownfield posture assessment that emits best-practice findings, discovery coverage, and recommended follow-up actions for the selected host pool.'
            : 'NewDeployment will create a new end-to-end Azure Virtual Desktop environment.'))))))
