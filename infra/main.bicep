targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Name of the App Service Plan')
param appServicePlanName string = ''

@description('Name of the App Service')
param appServiceName string = ''

@description('Name of the Container Registry')
param containerRegistryName string = ''

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceName string = ''

@description('Name of the Application Insights')
param applicationInsightsName string = ''

@description('Name of the AI Hub')
param aiHubName string = ''

@description('Name of the AI Project')
param aiProjectName string = ''

@description('SKU for App Service Plan')
param appServicePlanSku string = 'B1'

@description('SKU for Container Registry')
param containerRegistrySku string = 'Basic'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container Registry
module containerRegistry './container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    sku: containerRegistrySku
  }
}

// Log Analytics Workspace and Application Insights
module appInsights './app-insights.bicep' = {
  name: 'app-insights'
  scope: rg
  params: {
    logAnalyticsWorkspaceName: !empty(logAnalyticsWorkspaceName) ? logAnalyticsWorkspaceName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service
module appService './app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    appServiceName: !empty(appServiceName) ? appServiceName : '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    tags: tags
    appServicePlanSku: appServicePlanSku
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: appInsights.outputs.applicationInsightsConnectionString
    applicationInsightsInstrumentationKey: appInsights.outputs.applicationInsightsInstrumentationKey
  }
}

// AI Foundry
module aiFoundry './ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    aiHubName: !empty(aiHubName) ? aiHubName : '${abbrs.cognitiveServicesAccounts}hub-${resourceToken}'
    aiProjectName: !empty(aiProjectName) ? aiProjectName : '${abbrs.cognitiveServicesAccounts}proj-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
    applicationInsightsId: appInsights.outputs.applicationInsightsId
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_APP_SERVICE_NAME string = appService.outputs.name
output AZURE_APP_SERVICE_URL string = appService.outputs.url
output AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.applicationInsightsConnectionString
output AZURE_AI_HUB_NAME string = aiFoundry.outputs.aiHubName
output AZURE_AI_PROJECT_NAME string = aiFoundry.outputs.aiProjectName
