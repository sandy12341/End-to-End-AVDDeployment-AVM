@description('Existing desktop application group names that should receive AVD user role assignments.')
param desktopApplicationGroupNames array = []

@description('Existing RemoteApp application group names that should receive AVD user role assignments.')
param remoteAppApplicationGroupNames array = []

@description('Typed access assignments for desktop application groups. Each item must include principalId and principalType.')
param desktopAccessAssignments array = []

@description('Typed access assignments for RemoteApp application groups. Each item must include principalId and principalType.')
param remoteAppAccessAssignments array = []

module desktopAssignments 'brownfieldAppGroupAssignments.bicep' = [for appGroupName in desktopApplicationGroupNames: {
  name: 'desktop-${uniqueString(appGroupName)}'
  params: {
    applicationGroupName: appGroupName
    accessAssignments: desktopAccessAssignments
  }
}]

module remoteAssignments 'brownfieldAppGroupAssignments.bicep' = [for appGroupName in remoteAppApplicationGroupNames: {
  name: 'remote-${uniqueString(appGroupName)}'
  params: {
    applicationGroupName: appGroupName
    accessAssignments: remoteAppAccessAssignments
  }
}]

output desktopAssignmentCount int = length(desktopApplicationGroupNames) * length(desktopAccessAssignments)
output remoteAppAssignmentCount int = length(remoteAppApplicationGroupNames) * length(remoteAppAccessAssignments)