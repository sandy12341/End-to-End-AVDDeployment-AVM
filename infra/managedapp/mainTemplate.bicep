// Thin managed-app wrapper over the shared solution core.

targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Deployment prefix used for naming')
@maxLength(6)
param deploymentPrefix string = 'avd1'

@description('Deployment scenario selected in the managed app wizard. NewDeployment preserves the current create flow while brownfield operation paths are wired in.')
@allowed(['NewDeployment', 'ExpandExistingDeployment', 'Day2Operations'])
param deploymentScenario string = 'NewDeployment'

@description('Environment name')
@allowed(['dev', 'test', 'prod'])
param environment string = 'dev'

@description('Selected brownfield expansion action.')
@allowed(['', 'AddSessionHosts', 'AlignMonitoringPosture', 'RemediateVmImageBaseline'])
param expandOperation string = ''

@description('Selected brownfield day-2 action.')
@allowed(['', 'ConfigureScalingPlan', 'AlignMonitoringPosture', 'UpdateAccessAssignments', 'ReconcileFsLogixPrivateConnectivity'])
param day2Operation string = ''

@description('Existing workspaces related to the selected host pool.')
param existingWorkspaceNames array = []

@description('Existing application groups related to the selected host pool.')
param relatedApplicationGroupNames array = []

@description('Existing desktop application groups related to the selected host pool.')
param relatedDesktopApplicationGroupNames array = []

@description('Existing RemoteApp application groups related to the selected host pool.')
param relatedRemoteAppApplicationGroupNames array = []

@description('Detected related application group resource IDs for the selected host pool.')
param brownfieldDetectedRelatedApplicationGroupIds array = []

@description('Detected related desktop application group resource IDs for the selected host pool.')
param brownfieldDetectedRelatedDesktopApplicationGroupIds array = []

@description('Detected related RemoteApp application group resource IDs for the selected host pool.')
param brownfieldDetectedRelatedRemoteAppApplicationGroupIds array = []

@description('Detected load balancer type for the selected brownfield host pool.')
param brownfieldDetectedLoadBalancerType string = ''

@description('Detected preferred application group type for the selected brownfield host pool.')
param brownfieldDetectedPreferredAppGroupType string = ''

@description('Detected authentication posture for the selected brownfield host pool.')
param brownfieldDetectedAuthenticationType string = ''

@description('Detected max session limit for the selected brownfield host pool.')
param brownfieldDetectedMaxSessionLimit int = 0

@description('Detected Start VM on Connect state for the selected brownfield host pool.')
param brownfieldDetectedStartVmOnConnect bool = false

@description('Detected validation-environment flag for the selected brownfield host pool.')
param brownfieldDetectedValidationEnvironment bool = false

@description('Detected diagnostic setting names already attached to the selected brownfield host pool.')
param brownfieldDetectedHostPoolDiagnosticSettingNames array = []

@description('Workspace names that already have at least one diagnostic setting detected in the selected brownfield host pool resource group.')
param brownfieldDetectedWorkspacesWithDiagnostics array = []

@description('Whether the managed app UI was able to evaluate workspace diagnostic coverage directly.')
param brownfieldDetectedWorkspaceDiagnosticsCoverageEvaluated bool = false

@description('Application group names that already have at least one diagnostic setting detected in the selected brownfield host pool resource group.')
param brownfieldDetectedApplicationGroupsWithDiagnostics array = []

@description('Whether the managed app UI was able to evaluate application group diagnostic coverage directly.')
param brownfieldDetectedApplicationGroupDiagnosticsCoverageEvaluated bool = false

@description('Detected scaling plan names already attached to the selected brownfield host pool.')
param brownfieldDetectedScalingPlanNames array = []

@description('Detected session host VM names currently registered to the selected brownfield host pool.')
param brownfieldDetectedSessionHostVmNames array = []

@description('Detected session host VM names that appear to have Azure Monitor Agent installed in the selected host pool resource group.')
param brownfieldDetectedSessionHostsWithAma array = []

@description('Whether the managed app UI was able to evaluate Azure Monitor Agent coverage directly.')
param brownfieldDetectedSessionHostAmaCoverageEvaluated bool = false

@description('Detected session host VM names that appear to have data collection rule associations in the selected host pool resource group.')
param brownfieldDetectedSessionHostsWithDcrAssociation array = []

@description('Whether the managed app UI was able to evaluate session host data collection rule association coverage directly.')
param brownfieldDetectedSessionHostDcrAssociationCoverageEvaluated bool = false

@description('Detected data collection rule names in the selected host pool resource group.')
param brownfieldDetectedDataCollectionRuleNames array = []

@description('Detected scaling plan names that already have diagnostic settings in the selected host pool resource group.')
param brownfieldDetectedScalingPlansWithDiagnostics array = []

@description('Whether the managed app UI was able to evaluate scaling plan diagnostic coverage directly.')
param brownfieldDetectedScalingPlanDiagnosticsCoverageEvaluated bool = false

@description('Whether the managed app UI was able to evaluate application group access assignment coverage directly.')
param brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated bool = false

@description('Detected subscription-scope Desktop Virtualization Power On Off Contributor assignments in the current subscription.')
param brownfieldDetectedSubscriptionPowerOnOffContributorAssignmentCount int = 0

@description('Detected application-group-scoped role assignments in the current subscription.')
param brownfieldDetectedSubscriptionApplicationGroupAssignments array = []

@description('Detected role assignment count across related desktop application groups.')
param brownfieldDetectedDesktopAssignmentCount int = 0

@description('Detected role assignment count across related RemoteApp application groups.')
param brownfieldDetectedRemoteAppAssignmentCount int = 0

@description('Detected direct user assignment count across related application groups.')
param brownfieldDetectedDirectUserAssignmentCount int = 0

@description('Detected group-based assignment count across related application groups.')
param brownfieldDetectedGroupAssignmentCount int = 0

@description('Detected FSLogix storage account name provided for brownfield FSLogix network posture assessment.')
param brownfieldDetectedFslogixStorageAccountName string = ''

@description('Detected FSLogix storage account resource ID provided for brownfield FSLogix network posture assessment.')
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
param adminUsername string = ''

@description('Local admin password for session hosts')
@secure()
param adminPassword string = ''

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

module sharedSolution '../solution/avdDeploymentCore.bicep' = {
  name: 'avd-solution'
  params: {
    location: location
    deploymentPrefix: deploymentPrefix
    deploymentScenario: deploymentScenario
    environment: environment
    expandOperation: expandOperation
    day2Operation: day2Operation
    sessionHostCount: sessionHostCount
    vmSize: vmSize
    imageSource: imageSource
    marketplaceImagePublisher: marketplaceImagePublisher
    marketplaceImageOffer: marketplaceImageOffer
    marketplaceImageSku: marketplaceImageSku
    marketplaceImageVersion: marketplaceImageVersion
    galleryImageSubscriptionId: galleryImageSubscriptionId
    galleryImageResourceGroupName: galleryImageResourceGroupName
    galleryName: galleryName
    galleryImageDefinitionName: galleryImageDefinitionName
    galleryImageVersion: galleryImageVersion
    sessionHostSecurityType: sessionHostSecurityType
    avdMode: avdMode
    hostPoolType: hostPoolType
    authenticationType: authenticationType
    domainFqdn: domainFqdn
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
    domainJoinOuPath: domainJoinOuPath
    adminUsername: adminUsername
    adminPassword: adminPassword
    deployFSLogix: deployFSLogix
    storageAccountName: storageAccountName
    deployMonitoring: deployMonitoring
    deployFSLogixPrivateEndpoint: deployFSLogixPrivateEndpoint
    networkMode: networkMode
    existingVnetName: existingVnetName
    existingVnetResourceGroupName: existingVnetResourceGroupName
    sessionHostSubnetName: sessionHostSubnetName
    privateEndpointSubnetName: privateEndpointSubnetName
    newVnetName: newVnetName
    newVnetAddressPrefix: newVnetAddressPrefix
    newSessionHostSubnetName: newSessionHostSubnetName
    newSessionHostSubnetPrefix: newSessionHostSubnetPrefix
    newPrivateEndpointSubnetName: newPrivateEndpointSubnetName
    newPrivateEndpointSubnetPrefix: newPrivateEndpointSubnetPrefix
    hubVnetResourceId: hubVnetResourceId
    hostPoolName: hostPoolName
    existingHostPoolResourceGroupName: existingHostPoolResourceGroupName
    existingWorkspaceNames: existingWorkspaceNames
    relatedApplicationGroupNames: relatedApplicationGroupNames
    relatedDesktopApplicationGroupNames: relatedDesktopApplicationGroupNames
    relatedRemoteAppApplicationGroupNames: relatedRemoteAppApplicationGroupNames
    brownfieldDetectedRelatedApplicationGroupIds: brownfieldDetectedRelatedApplicationGroupIds
    brownfieldDetectedRelatedDesktopApplicationGroupIds: brownfieldDetectedRelatedDesktopApplicationGroupIds
    brownfieldDetectedRelatedRemoteAppApplicationGroupIds: brownfieldDetectedRelatedRemoteAppApplicationGroupIds
    brownfieldDetectedLoadBalancerType: brownfieldDetectedLoadBalancerType
    brownfieldDetectedPreferredAppGroupType: brownfieldDetectedPreferredAppGroupType
    brownfieldDetectedAuthenticationType: brownfieldDetectedAuthenticationType
    brownfieldDetectedMaxSessionLimit: brownfieldDetectedMaxSessionLimit
    brownfieldDetectedStartVmOnConnect: brownfieldDetectedStartVmOnConnect
    brownfieldDetectedValidationEnvironment: brownfieldDetectedValidationEnvironment
    brownfieldDetectedHostPoolDiagnosticSettingNames: brownfieldDetectedHostPoolDiagnosticSettingNames
    brownfieldDetectedWorkspacesWithDiagnostics: brownfieldDetectedWorkspacesWithDiagnostics
    brownfieldDetectedWorkspaceDiagnosticsCoverageEvaluated: brownfieldDetectedWorkspaceDiagnosticsCoverageEvaluated
    brownfieldDetectedApplicationGroupsWithDiagnostics: brownfieldDetectedApplicationGroupsWithDiagnostics
    brownfieldDetectedApplicationGroupDiagnosticsCoverageEvaluated: brownfieldDetectedApplicationGroupDiagnosticsCoverageEvaluated
    brownfieldDetectedScalingPlanNames: brownfieldDetectedScalingPlanNames
    brownfieldDetectedSessionHostVmNames: brownfieldDetectedSessionHostVmNames
    brownfieldDetectedSessionHostsWithAma: brownfieldDetectedSessionHostsWithAma
    brownfieldDetectedSessionHostAmaCoverageEvaluated: brownfieldDetectedSessionHostAmaCoverageEvaluated
    brownfieldDetectedSessionHostsWithDcrAssociation: brownfieldDetectedSessionHostsWithDcrAssociation
    brownfieldDetectedSessionHostDcrAssociationCoverageEvaluated: brownfieldDetectedSessionHostDcrAssociationCoverageEvaluated
    brownfieldDetectedDataCollectionRuleNames: brownfieldDetectedDataCollectionRuleNames
    brownfieldDetectedScalingPlansWithDiagnostics: brownfieldDetectedScalingPlansWithDiagnostics
    brownfieldDetectedScalingPlanDiagnosticsCoverageEvaluated: brownfieldDetectedScalingPlanDiagnosticsCoverageEvaluated
    brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated: brownfieldDetectedApplicationGroupAssignmentCoverageEvaluated
    brownfieldDetectedSubscriptionPowerOnOffContributorAssignmentCount: brownfieldDetectedSubscriptionPowerOnOffContributorAssignmentCount
    brownfieldDetectedSubscriptionApplicationGroupAssignments: brownfieldDetectedSubscriptionApplicationGroupAssignments
    brownfieldDetectedDesktopAssignmentCount: brownfieldDetectedDesktopAssignmentCount
    brownfieldDetectedRemoteAppAssignmentCount: brownfieldDetectedRemoteAppAssignmentCount
    brownfieldDetectedDirectUserAssignmentCount: brownfieldDetectedDirectUserAssignmentCount
    brownfieldDetectedGroupAssignmentCount: brownfieldDetectedGroupAssignmentCount
    brownfieldDetectedFslogixStorageAccountName: brownfieldDetectedFslogixStorageAccountName
    brownfieldDetectedFslogixStorageAccountResourceId: brownfieldDetectedFslogixStorageAccountResourceId
    brownfieldDetectedFslogixPublicNetworkAccess: brownfieldDetectedFslogixPublicNetworkAccess
    brownfieldDetectedFslogixPrivateEndpointCount: brownfieldDetectedFslogixPrivateEndpointCount
    brownfieldDetectedFslogixPrivateDnsLinkState: brownfieldDetectedFslogixPrivateDnsLinkState
    brownfieldDetectedNetworkVnetName: brownfieldDetectedNetworkVnetName
    brownfieldMonitoringWorkspaceMode: brownfieldMonitoringWorkspaceMode
    brownfieldMonitoringScope: brownfieldMonitoringScope
    brownfieldMonitoringPreset: brownfieldMonitoringPreset
    brownfieldMonitoringWorkspaceName: brownfieldMonitoringWorkspaceName
    brownfieldMonitoringExistingWorkspaceResourceId: brownfieldMonitoringExistingWorkspaceResourceId
    brownfieldMonitoringRetentionDays: brownfieldMonitoringRetentionDays
    brownfieldMonitoringSessionHostVmResourceGroupName: brownfieldMonitoringSessionHostVmResourceGroupName
    brownfieldMonitoringSessionHostVmNames: brownfieldMonitoringSessionHostVmNames
    brownfieldFslogixStorageAccountResourceId: brownfieldFslogixStorageAccountResourceId
    brownfieldFslogixPrivateDnsZoneMode: brownfieldFslogixPrivateDnsZoneMode
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
    avdUserObjectIds: avdUserObjectIds
    desktopAccessAssignments: desktopAccessAssignments
    remoteAppAccessAssignments: remoteAppAccessAssignments
    remoteApps: remoteApps
    deploymentInstanceSeed: deploymentInstanceSeed
  }
}

output hostPoolName string = sharedSolution.outputs.hostPoolName
output workspaceId string = sharedSolution.outputs.workspaceId
output desktopAppGroupId string = sharedSolution.outputs.desktopAppGroupId
output remoteAppGroupId string = sharedSolution.outputs.remoteAppGroupId
output publishedAppGroupIds array = sharedSolution.outputs.publishedAppGroupIds
output vnetId string = sharedSolution.outputs.vnetId
output privateEndpointSubnetId string = sharedSolution.outputs.privateEndpointSubnetId
output sessionHostVmNames array = sharedSolution.outputs.sessionHostVmNames
output expandOperation string = sharedSolution.outputs.expandOperation
output day2Operation string = sharedSolution.outputs.day2Operation
output fslogixStorageAccount string = sharedSolution.outputs.fslogixStorageAccount
output fslogixPrivateEndpointId string = sharedSolution.outputs.fslogixPrivateEndpointId
output logAnalyticsWorkspace string = sharedSolution.outputs.logAnalyticsWorkspace
output logAnalyticsWorkspaceId string = sharedSolution.outputs.logAnalyticsWorkspaceId
output monitoringDataCollectionRuleId string = sharedSolution.outputs.monitoringDataCollectionRuleId
output scalingPlanName string = sharedSolution.outputs.scalingPlanName
output scalingPlanId string = sharedSolution.outputs.scalingPlanId
output brownfieldOperationSummary string = sharedSolution.outputs.brownfieldOperationSummary
output effectiveAvdMode string = sharedSolution.outputs.effectiveAvdMode
output avdRolesAssigned bool = sharedSolution.outputs.avdRolesAssigned
