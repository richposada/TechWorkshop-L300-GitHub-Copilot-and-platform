// Main Bicep orchestration file for ZavaStorefront Azure infrastructure
// Deploys all resources following AZD best practices

targetScope = 'subscription'

// Required parameters for AZD
@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Service name for the web application')
param serviceName string = 'web'

// Tags that should be applied to all resources
var tags = {
  'azd-env-name': environmentName
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Deploy User-Assigned Managed Identity
module identity 'core/security/user-assigned-identity.bicep' = {
  scope: rg
  name: 'identity-deployment'
  params: {
    location: location
    environmentName: environmentName
  }
}

// Deploy Container Registry
module containerRegistry 'core/host/container-registry.bicep' = {
  scope: rg
  name: 'acr-deployment'
  params: {
    location: location
    environmentName: environmentName
  }
}

// Deploy Monitoring (Log Analytics + Application Insights)
module monitoring 'core/monitor/application-insights.bicep' = {
  scope: rg
  name: 'monitoring-deployment'
  params: {
    location: location
    environmentName: environmentName
  }
}

// Deploy Azure OpenAI with GPT-4
module openAI 'ai/openai.bicep' = {
  scope: rg
  name: 'openai-deployment'
  params: {
    location: 'westus3' // Fixed region for model availability
    environmentName: environmentName
  }
}

// Deploy AI Foundry Hub and Project
module aiFoundry 'ai/ai-foundry.bicep' = {
  scope: rg
  name: 'ai-foundry-deployment'
  params: {
    location: 'westus3' // Fixed region for model availability
    environmentName: environmentName
  }
}

// Deploy App Service
module appService 'core/host/app-service.bicep' = {
  scope: rg
  name: 'app-service-deployment'
  params: {
    location: location
    environmentName: environmentName
    acrLoginServer: containerRegistry.outputs.acrLoginServer
    userAssignedIdentityId: identity.outputs.identityId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    serviceName: serviceName
  }
}

// Deploy Role Assignments
module roleAssignments 'core/security/role-assignments.bicep' = {
  scope: rg
  name: 'role-assignments-deployment'
  params: {
    identityPrincipalId: identity.outputs.identityPrincipalId
    acrName: containerRegistry.outputs.acrName
    openAIName: openAI.outputs.openAIName
    aiProjectName: aiFoundry.outputs.aiProjectName
  }
}

// Outputs required by AZD
@description('Resource Group ID')
output RESOURCE_GROUP_ID string = rg.id

@description('App Service name')
output AZURE_APP_SERVICE_NAME string = appService.outputs.appServiceName

@description('App Service URL')
output SERVICE_WEB_URI string = appService.outputs.appServiceUrl

@description('Container Registry name')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.acrName

@description('Container Registry login server')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.acrLoginServer

@description('Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString

@description('Azure OpenAI endpoint')
output AZURE_OPENAI_ENDPOINT string = openAI.outputs.openAIEndpoint

@description('Azure OpenAI deployment name for GPT-4')
output AZURE_OPENAI_GPT4_DEPLOYMENT string = openAI.outputs.gpt4DeploymentName

@description('AI Foundry project name')
output AZURE_AI_PROJECT_NAME string = aiFoundry.outputs.aiProjectName

@description('Managed Identity Client ID')
output AZURE_CLIENT_ID string = identity.outputs.identityClientId
