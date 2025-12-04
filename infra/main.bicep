targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Name of the App Service')
param appServiceName string = ''

@description('Name of the App Service Plan')
param appServicePlanName string = ''

@description('Name of the Container Registry')
param containerRegistryName string = ''

@description('Name of the Application Insights')
param applicationInsightsName string = ''

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string = ''

@description('Name of the AI Foundry Hub')
param aiFoundryHubName string = ''

@description('Name of the AI Foundry Project')
param aiFoundryProjectName string = ''

@description('Container image name')
param containerImageName string = 'zavastorefont'

@description('Container image tag')
param containerImageTag string = 'latest'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics 'core/monitoring/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights 'core/monitoring/app-insights.bicep' = {
  name: 'app-insights'
  scope: rg
  params: {
    name: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Container Registry
module containerRegistry 'app/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service
module appService 'app/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    appServiceName: !empty(appServiceName) ? appServiceName : '${abbrs.webSitesAppService}${resourceToken}'
    appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    containerRegistryName: containerRegistry.outputs.name
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    applicationInsightsConnectionString: appInsights.outputs.connectionString
  }
}

// Assign AcrPull role to App Service managed identity
module acrPullRole 'app/acr-role-assignment.bicep' = {
  name: 'acr-pull-role'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// AI Foundry Hub and Project
module aiFoundry 'ai/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    hubName: !empty(aiFoundryHubName) ? aiFoundryHubName : '${abbrs.cognitiveServicesAccounts}hub-${resourceToken}'
    projectName: !empty(aiFoundryProjectName) ? aiFoundryProjectName : '${abbrs.cognitiveServicesAccounts}proj-${resourceToken}'
    location: location
    tags: tags
    applicationInsightsId: appInsights.outputs.id
    containerRegistryId: containerRegistry.outputs.id
    appServicePrincipalId: appService.outputs.identityPrincipalId
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output APP_SERVICE_NAME string = appService.outputs.name
output APP_SERVICE_HOSTNAME string = appService.outputs.hostname
output AI_FOUNDRY_HUB_NAME string = aiFoundry.outputs.hubName
output AI_FOUNDRY_PROJECT_NAME string = aiFoundry.outputs.projectName
output AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
