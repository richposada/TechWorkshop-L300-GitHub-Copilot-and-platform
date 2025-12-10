@description('Principal ID to assign the role to')
param principalId string

@description('Role Definition ID (GUID)')
param roleDefinitionId string

@description('Target resource ID for the role assignment')
param targetResourceId string

@description('Principal type')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId, targetResourceId)
  scope: resourceId('Microsoft.ContainerRegistry/registries', last(split(targetResourceId, '/')))
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

output id string = roleAssignment.id
output name string = roleAssignment.name
