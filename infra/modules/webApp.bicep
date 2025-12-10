// Web App for Containers module
@description('Name of the Web App')
param webAppName string

@description('Location for the Web App')
param location string

@description('App Service Plan ID')
param appServicePlanId string

@description('ACR Login Server')
param acrLoginServer string

@description('Docker image name and tag')
param dockerImageAndTag string = 'zavastorefrontapp:latest'

@description('Application Insights Connection String')
param appInsightsConnectionString string = ''

@description('Application Insights Instrumentation Key')
param appInsightsInstrumentationKey string = ''

@description('Tags to apply to the Web App')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageAndTag}'
      alwaysOn: false
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
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
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
      ]
      acrUseManagedIdentityCreds: true
    }
    httpsOnly: true
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppPrincipalId string = webApp.identity.principalId
output webAppHostName string = webApp.properties.defaultHostName
