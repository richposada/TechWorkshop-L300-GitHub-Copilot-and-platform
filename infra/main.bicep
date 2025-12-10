targetScope = 'subscription'

@description('Application name')
@minLength(3)
@maxLength(10)
param appName string = 'zavastore'

@description('Environment name')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Primary location for all resources')
param location string = 'westus3'

@description('Docker image name and tag')
param dockerImageTag string = 'latest'

@description('Container Registry SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('AI Services SKU')
param aiServicesSku string = 'S0'

// Generate resource names following naming convention
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'
var acrName = '${replace(appName, '-', '')}${environmentName}${uniqueString(subscription().subscriptionId, resourceGroupName)}'
var appServicePlanName = 'asp-${appName}-${environmentName}-${location}'
var webAppName = 'app-${appName}-${environmentName}-${location}'
var logAnalyticsName = 'log-${appName}-${environmentName}-${location}'
var appInsightsName = 'appi-${appName}-${environmentName}-${location}'
var aiHubName = 'ai-${appName}-${environmentName}-${location}'

// Tags to apply to all resources
var tags = {
  Environment: environmentName
  Application: appName
  ManagedBy: 'Bicep'
}

// AcrPull role definition ID (built-in Azure role)
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Log Analytics Workspace
module logAnalytics 'modules/logAnalyticsWorkspace.bicep' = {
  name: 'logAnalytics-deployment'
  scope: resourceGroup
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/applicationInsights.bicep' = {
  name: 'appInsights-deployment'
  scope: resourceGroup
  params: {
    name: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

// Deploy Container Registry
module containerRegistry 'modules/containerRegistry.bicep' = {
  name: 'acr-deployment'
  scope: resourceGroup
  params: {
    name: acrName
    location: location
    sku: acrSku
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan-deployment'
  scope: resourceGroup
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
    tags: tags
  }
}

// Deploy Web App
module webApp 'modules/webApp.bicep' = {
  name: 'webApp-deployment'
  scope: resourceGroup
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    dockerImageName: '${appName}:${dockerImageTag}'
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Deploy AI Hub (Microsoft Foundry)
module aiHub 'modules/aiHub.bicep' = {
  name: 'aiHub-deployment'
  scope: resourceGroup
  params: {
    name: aiHubName
    location: location
    sku: aiServicesSku
    tags: tags
  }
}

// Assign AcrPull role to Web App managed identity
module acrPullRoleAssignment 'modules/roleAssignment.bicep' = {
  name: 'acrPull-roleAssignment'
  scope: resourceGroup
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: acrPullRoleId
    containerRegistryName: containerRegistry.outputs.name
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output acrName string = containerRegistry.outputs.name
output acrLoginServer string = containerRegistry.outputs.loginServer
output webAppName string = webApp.outputs.name
output webAppUrl string = 'https://${webApp.outputs.defaultHostName}'
output appInsightsName string = appInsights.outputs.name
output aiHubName string = aiHub.outputs.name
output aiHubEndpoint string = aiHub.outputs.endpoint
