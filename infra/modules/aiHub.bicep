@description('Name of the AI Hub')
param name string

@description('Location for the AI Hub')
param location string

@description('SKU for the AI Hub')
param sku string = 'S0'

@description('Tags to apply to the resource')
param tags object = {}

resource aiHub 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

output id string = aiHub.id
output name string = aiHub.name
output endpoint string = aiHub.properties.endpoint
