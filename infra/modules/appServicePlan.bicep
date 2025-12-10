@description('Name of the App Service Plan')
param name string

@description('Location for the App Service Plan')
param location string

@description('SKU name for the App Service Plan')
param skuName string = 'B1'

@description('Tags to apply to the resource')
param tags object = {}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

output id string = appServicePlan.id
output name string = appServicePlan.name
