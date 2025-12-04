@description('Name of the App Service Plan')
param appServicePlanName string

@description('Name of the App Service')
param appServiceName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags for the resources')
param tags object = {}

@description('SKU for App Service Plan')
param appServicePlanSku string = 'B1'

@description('Name of the Container Registry')
param containerRegistryName string

@description('Application Insights Connection String')
param applicationInsightsConnectionString string

@description('Application Insights Instrumentation Key')
param applicationInsightsInstrumentationKey string

// Reference existing Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// App Service Plan - Linux
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// App Service - Linux Container
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  tags: union(tags, { 'azd-service-name': 'zavastorefront' })
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/dotnet/aspnet:10.0-preview'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.properties.loginServer}'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsInstrumentationKey
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
    }
    httpsOnly: true
  }
}

// Role assignment for AcrPull - allows App Service to pull images from ACR
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, appService.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output name string = appService.name
output url string = 'https://${appService.properties.defaultHostName}'
output principalId string = appService.identity.principalId
