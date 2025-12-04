@description('Name of the Container Registry')
param name string

@description('Location for the Container Registry')
param location string

@description('Tags for the Container Registry')
param tags object = {}

// Container Registry with RBAC - no admin account
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false // Using RBAC only, no admin credentials
    publicNetworkAccess: 'Enabled'
    policies: {
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
  }
}

output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
