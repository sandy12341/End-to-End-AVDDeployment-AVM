@description('Existing application group name that should receive AVD user role assignments.')
param applicationGroupName string

@description('Typed access assignments for the application group. Each item must include principalId and principalType.')
param accessAssignments array = []

var avdUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' existing = {
  name: applicationGroupName
}

resource accessRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for assignment in accessAssignments: if (!empty(string(assignment.principalId))) {
  name: guid(resourceGroup().id, applicationGroupName, string(assignment.principalType), string(assignment.principalId), '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63')
  scope: applicationGroup
  properties: {
    principalId: string(assignment.principalId)
    roleDefinitionId: avdUserRoleDefinitionId
    principalType: string(assignment.principalType)
  }
}]

output assignmentCount int = length(accessAssignments)
