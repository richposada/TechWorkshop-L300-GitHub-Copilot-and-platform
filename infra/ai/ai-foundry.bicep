// Azure AI Foundry Hub and Project with Phi model deployment

param location string = 'westus3' // Fixed region for model availability
param environmentName string

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var aiHubName = 'azhub${resourceToken}'
var aiProjectName = 'azproj${resourceToken}'
var storageAccountName = 'azst${resourceToken}'
var keyVaultName = 'azkv${resourceToken}'

// Storage Account for AI Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false // Required: Disable public blob access
    allowSharedKeyAccess: false // Required: Disable local auth (key access)
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Key Vault for AI Hub
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
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

// AI Hub
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiHubName
  location: location
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Hub'
    description: 'AI Hub for ZavaStorefront application'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    publicNetworkAccess: 'Enabled'
  }
}

// AI Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: aiProjectName
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'ZavaStorefront AI Project'
    description: 'AI Project for ZavaStorefront with Phi model'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
}

output aiHubId string = aiHub.id
output aiHubName string = aiHub.name
output aiProjectId string = aiProject.id
output aiProjectName string = aiProject.name
output storageAccountId string = storageAccount.id
output keyVaultId string = keyVault.id
