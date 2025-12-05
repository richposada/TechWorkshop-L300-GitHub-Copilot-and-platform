// Azure App Service (Linux) with Docker Container deployment
// Includes App Service Plan and Site Extension (required by AZD)

param location string
param environmentName string
param acrLoginServer string
param userAssignedIdentityId string
param appInsightsConnectionString string
param serviceName string = 'web'

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var appServicePlanName = 'azasp${resourceToken}'
var appServiceName = 'azapp${resourceToken}'

// App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// App Service
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': serviceName // Required by AZD
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavasf/web:latest'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userAssignedIdentityId
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

// Site Extension (Required by AZD for App Service deployments)
resource siteExtension 'Microsoft.Web/sites/siteextensions@2023-01-01' = {
  parent: appService
  name: 'Microsoft.ApplicationInsights.AzureWebSites'
}

output appServiceId string = appService.id
output appServiceName string = appService.name
output appServiceHostName string = appService.properties.defaultHostName
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
