// Main Bicep template for ZavaStorefront infrastructure
targetScope = 'resourceGroup'

@description('Environment name (e.g., dev, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = 'westus3'

@description('Base name for all resources')
param baseName string = 'zavastore'

@description('Docker image name and tag')
param dockerImageAndTag string = 'zavastorefrontapp:latest'

// Generate resource names
var resourceGroupName = 'rg-${baseName}-${environmentName}-${location}'
var acrName = replace('acr${baseName}${environmentName}${location}', '-', '')
var appServicePlanName = 'asp-${baseName}-${environmentName}-${location}'
var webAppName = 'app-${baseName}-${environmentName}-${location}'
var logAnalyticsName = 'log-${baseName}-${environmentName}-${location}'
var appInsightsName = 'appi-${baseName}-${environmentName}-${location}'
var aiServicesName = 'ai-${baseName}-${environmentName}-${location}'

// Common tags
var tags = {
  Environment: environmentName
  Application: 'ZavaStorefront'
  ManagedBy: 'Bicep'
  CostCenter: 'Development'
}

// Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeploy'
  params: {
    workspaceName: logAnalyticsName
    location: location
    sku: 'PerGB2018'
    tags: tags
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeploy'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// App Service Plan (Linux)
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeploy'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
    tags: tags
  }
}

// Web App for Containers
module webApp 'modules/webApp.bicep' = {
  name: 'webAppDeploy'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.acrLoginServer
    dockerImageAndTag: dockerImageAndTag
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    tags: tags
  }
}

// Role Assignment: Grant Web App AcrPull access to ACR
module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignmentDeploy'
  params: {
    principalId: webApp.outputs.webAppPrincipalId
    acrId: acr.outputs.acrId
  }
}

// Azure AI Foundry (Cognitive Services) for GPT-4 and Phi models
module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'aiFoundryDeploy'
  params: {
    aiServicesName: aiServicesName
    location: location
    sku: 'S0'
    deployGpt4: true
    deployPhi: true
    tags: tags
  }
}

// Outputs
output resourceGroupName string = resourceGroupName
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output webAppName string = webApp.outputs.webAppName
output webAppUrl string = 'https://${webApp.outputs.webAppHostName}'
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString
output aiServicesEndpoint string = aiFoundry.outputs.aiServicesEndpoint
output aiServicesName string = aiFoundry.outputs.aiServicesName
