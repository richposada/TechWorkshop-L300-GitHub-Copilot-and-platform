// Role Assignment module for ACR Pull
@description('Principal ID that needs ACR access')
param principalId string

@description('ACR Resource ID')
param acrId string

@description('Role Definition ID for AcrPull role')
param roleDefinitionId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull built-in role

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
