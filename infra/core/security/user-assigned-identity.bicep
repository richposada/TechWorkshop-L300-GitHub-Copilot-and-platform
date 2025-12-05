// User-Assigned Managed Identity
// This identity is used by App Service to authenticate to Azure resources using RBAC

param location string
param environmentName string

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var identityName = 'id-${resourceToken}'

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output identityId string = userAssignedIdentity.id
output identityPrincipalId string = userAssignedIdentity.properties.principalId
output identityClientId string = userAssignedIdentity.properties.clientId
output identityName string = userAssignedIdentity.name
