@description('Name of the AI Hub')
param aiHubName string

@description('Name of the AI Project')
param aiProjectName string

@description('Location for resources')
param location string = resourceGroup().location

@description('Tags for the resources')
param tags object = {}

@description('Log Analytics Workspace ID for diagnostics')
param logAnalyticsWorkspaceId string

@description('Application Insights ID for monitoring')
param applicationInsightsId string

// Storage Account for AI Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${uniqueString(resourceGroup().id)}ai'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Key Vault for AI Hub secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

// Azure AI Services Account (for model deployments)
resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: '${aiHubName}-aiservices'
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${aiHubName}-aiservices'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Azure AI Hub (Machine Learning Workspace - Hub kind)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiHubName
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: applicationInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

// Azure AI Project (Machine Learning Workspace - Project kind)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-01-01-preview' = {
  name: aiProjectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    friendlyName: aiProjectName
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

// AI Services Connection for AI Hub
resource aiServicesConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-01-01-preview' = {
  parent: aiHub
  name: 'aiservices-connection'
  properties: {
    category: 'AIServices'
    target: aiServicesAccount.properties.endpoint
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: aiServicesAccount.id
    }
  }
}

// Diagnostic settings for AI Hub
resource aiHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: aiHub
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output aiHubName string = aiHub.name
output aiHubId string = aiHub.id
output aiProjectName string = aiProject.name
output aiProjectId string = aiProject.id
output aiServicesEndpoint string = aiServicesAccount.properties.endpoint
output storageAccountName string = storageAccount.name
output keyVaultName string = keyVault.name
