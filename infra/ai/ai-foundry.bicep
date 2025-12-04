@description('Name of the AI Foundry Hub')
param hubName string

@description('Name of the AI Foundry Project')
param projectName string

@description('Location for AI Foundry resources')
param location string

@description('Tags for AI Foundry resources')
param tags object = {}

@description('Application Insights resource ID')
param applicationInsightsId string

@description('Container Registry resource ID')
param containerRegistryId string

@description('App Service principal ID for RBAC')
param appServicePrincipalId string

// Storage account for AI Foundry
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${uniqueString(resourceGroup().id, hubName)}'
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
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Key Vault for AI Foundry
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${uniqueString(resourceGroup().id, hubName)}'
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
    enablePurgeProtection: false // Set to false for dev environment easy cleanup
    publicNetworkAccess: 'Enabled'
  }
}

// AI Foundry Hub (Azure Machine Learning workspace configured as AI Hub)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: hubName
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Foundry Hub'
    description: 'Azure AI Foundry Hub for ZavaStorefront'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    publicNetworkAccess: 'Enabled'
  }
}

// AI Foundry Project (child workspace)
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  tags: tags
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Project'
    description: 'AI Project for ZavaStorefront application'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

// Azure OpenAI account for GPT-4 and Phi models
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: 'oai-${uniqueString(resourceGroup().id, hubName)}'
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: 'oai-${uniqueString(resourceGroup().id, hubName)}'
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4 model deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: openAIAccount
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10 // TPM capacity in thousands for dev environment
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

// Phi model deployment (using Azure AI Foundry serverless)
// Note: Phi models are typically deployed via Azure AI model catalog in AI Foundry
// For Bicep deployment, we'll use the Azure AI model registry approach

// Cognitive Services User role for App Service
var cognitiveServicesUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

resource openAIRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAIAccount.id, appServicePrincipalId, cognitiveServicesUserRoleId)
  scope: openAIAccount
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleId
    principalId: appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
}

// AI Hub connection to Azure OpenAI
resource aiHubOpenAIConnection 'Microsoft.MachineLearningServices/workspaces/connections@2024-04-01' = {
  parent: aiHub
  name: 'azure-openai-connection'
  properties: {
    category: 'AzureOpenAI'
    target: openAIAccount.properties.endpoint
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: openAIAccount.id
    }
  }
}

output hubId string = aiHub.id
output hubName string = aiHub.name
output projectId string = aiProject.id
output projectName string = aiProject.name
output endpoint string = openAIAccount.properties.endpoint
output openAIAccountName string = openAIAccount.name
