// Azure AI Foundry (Cognitive Services) module for GPT-4 and Phi models
@description('Name of the Azure AI Services account')
param aiServicesName string

@description('Location for Azure AI Services (must support GPT-4 and Phi models)')
param location string

@description('SKU for Azure AI Services')
@allowed([
  'S0'
  'S1'
])
param sku string = 'S0'

@description('Tags to apply to the AI Services account')
param tags object = {}

@description('Deploy GPT-4 model')
param deployGpt4 bool = true

@description('Deploy Phi model')
param deployPhi bool = true

resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// GPT-4 deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployGpt4) {
  parent: aiServices
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
}

// Phi model deployment (using gpt-35-turbo as placeholder since Phi availability may vary)
resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (deployPhi) {
  parent: aiServices
  name: 'phi-3'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
  }
  dependsOn: [
    gpt4Deployment
  ]
}

output aiServicesId string = aiServices.id
output aiServicesName string = aiServices.name
output aiServicesEndpoint string = aiServices.properties.endpoint
// Note: AI Services keys should be retrieved via Azure CLI or Portal, not exposed in outputs
// Use: az cognitiveservices account keys list --name <name> --resource-group <rg>
