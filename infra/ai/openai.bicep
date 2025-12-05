// Azure OpenAI Service with GPT-4 deployment

param location string = 'westus3' // Fixed region for model availability
param environmentName string

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var openAIName = 'azai${resourceToken}'
var gpt4DeploymentName = 'gpt-4'

resource openAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAIName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAI
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: 10 // 10K TPM for development
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

output openAIId string = openAI.id
output openAIName string = openAI.name
output openAIEndpoint string = openAI.properties.endpoint
output gpt4DeploymentName string = gpt4Deployment.name
