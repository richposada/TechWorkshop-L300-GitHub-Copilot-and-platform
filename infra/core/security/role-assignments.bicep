// RBAC Role Assignments
// Assigns necessary roles to the managed identity for accessing Azure resources

param identityPrincipalId string
param acrName string
param openAIName string
param aiProjectName string

// AcrPull role definition ID (built-in Azure role)
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// Cognitive Services User role definition ID (built-in Azure role)
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

// Azure AI Developer role definition ID (built-in Azure role)
var azureAIDeveloperRoleId = '64702f94-c441-49e6-a78b-ef80e0188fee'

// Reference existing resources
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAIName
}

resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' existing = {
  name: aiProjectName
}

// Role Assignment: AcrPull on Container Registry
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, identityPrincipalId, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Cognitive Services User on Azure OpenAI
resource cognitiveServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAI.id, identityPrincipalId, cognitiveServicesUserRoleId)
  scope: openAI
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Role Assignment: Azure AI Developer on AI Project
resource aiDeveloperRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiProject.id, identityPrincipalId, azureAIDeveloperRoleId)
  scope: aiProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAIDeveloperRoleId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output acrPullRoleAssignmentId string = acrPullRoleAssignment.id
output cognitiveServicesRoleAssignmentId string = cognitiveServicesRoleAssignment.id
output aiDeveloperRoleAssignmentId string = aiDeveloperRoleAssignment.id
