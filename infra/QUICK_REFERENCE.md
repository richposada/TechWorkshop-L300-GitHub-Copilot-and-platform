# Quick Reference Guide - ZavaStorefront Azure Infrastructure

## Essential Commands

### Initial Setup

```bash
# Login to Azure
az login
azd auth login

# Set subscription
az account set --subscription "<subscription-id>"

# Initialize environment
azd init
```

### Deployment

```bash
# Full deployment (provision + deploy)
azd up

# Provision infrastructure only
azd provision

# Deploy application only
azd deploy

# View deployment status
azd show
```

### Get Environment Values

```bash
# Show all environment variables
azd env get-values

# Get specific values
azd env get-value ACR_NAME
azd env get-value WEBAPP_NAME
azd env get-value WEBAPP_URL
azd env get-value RESOURCE_GROUP_NAME
```

### Application Management

```bash
# Restart web app
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)
az webapp restart --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3

# View live logs
az webapp log tail --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3

# Get web app URL
az webapp show --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3 --query defaultHostName -o tsv
```

### Container Management

```bash
# Build and push image
ACR_NAME=$(azd env get-value ACR_NAME)
az acr build --registry $ACR_NAME --image zavastorefrontapp:latest --file ./Dockerfile ./src

# List images
az acr repository show-tags --name $ACR_NAME --repository zavastorefrontapp --output table

# Delete old images
az acr repository delete --name $ACR_NAME --image zavastorefrontapp:<tag> --yes
```

### Monitoring

```bash
# View Application Insights
az monitor app-insights component show --app appi-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3

# Query logs
az monitor app-insights query \
  --app appi-zavastore-dev-westus3 \
  --analytics-query "requests | take 10" \
  --resource-group rg-zavastore-dev-westus3
```

### Resource Management

```bash
# List all resources
az resource list --resource-group rg-zavastore-dev-westus3 --output table

# Show resource group
az group show --name rg-zavastore-dev-westus3

# Export resource group template
az group export --name rg-zavastore-dev-westus3 > exported-template.json
```

### Bicep Operations

```bash
# Validate Bicep template
az bicep build --file infra/main.bicep

# What-if analysis
az deployment group what-if \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json

# Deploy Bicep directly
az deployment group create \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

### Troubleshooting

```bash
# Check deployment errors
az deployment group show \
  --resource-group rg-zavastore-dev-westus3 \
  --name main \
  --query properties.error

# Get web app diagnostic logs
az webapp log download --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3

# Check managed identity
az webapp identity show --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3

# Verify role assignments
PRINCIPAL_ID=$(az webapp identity show --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3 --query principalId -o tsv)
az role assignment list --assignee $PRINCIPAL_ID
```

### AI Services

```bash
# Get AI Services endpoint
az cognitiveservices account show \
  --name ai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query properties.endpoint -o tsv

# List AI Services keys
az cognitiveservices account keys list \
  --name ai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3

# List deployments
az cognitiveservices account deployment list \
  --name ai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --output table
```

### Cost Management

```bash
# Get cost analysis
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --query "[?contains(instanceId, 'rg-zavastore-dev-westus3')]"

# Set budget alert (via portal or ARM template)
```

### Cleanup

```bash
# Delete everything
azd down

# Or delete resource group
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## Resource Naming Convention

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| Resource Group | `rg-{app}-{env}-{region}` | `rg-zavastore-dev-westus3` |
| Container Registry | `acr{app}{env}{region}` | `acrzavastoredevwestus3` |
| App Service Plan | `asp-{app}-{env}-{region}` | `asp-zavastore-dev-westus3` |
| Web App | `app-{app}-{env}-{region}` | `app-zavastore-dev-westus3` |
| Application Insights | `appi-{app}-{env}-{region}` | `appi-zavastore-dev-westus3` |
| Log Analytics | `log-{app}-{env}-{region}` | `log-zavastore-dev-westus3` |
| AI Services | `ai-{app}-{env}-{region}` | `ai-zavastore-dev-westus3` |

## Default SKUs (Dev Environment)

| Service | SKU | Monthly Cost (Approx) |
|---------|-----|----------------------|
| App Service Plan | B1 (Basic) | ~$13 |
| Container Registry | Basic | ~$5 |
| Application Insights | Pay-as-you-go | ~$2-10 |
| Log Analytics | PerGB2018 | ~$2-5 |
| AI Services | S0 | Per usage |

## Important URLs

- Azure Portal: https://portal.azure.com
- Application Insights: https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/overview
- Container Registry: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ContainerRegistry%2Fregistries
- Azure Developer CLI Docs: https://learn.microsoft.com/azure/developer/azure-developer-cli/

## Environment Variables

Key environment variables set by `azd`:

- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
- `AZURE_LOCATION` - Deployment region (westus3)
- `AZURE_RESOURCE_GROUP` - Resource group name
- `ACR_NAME` - Container registry name
- `WEBAPP_NAME` - Web app name
- `WEBAPP_URL` - Web app URL
- `APP_INSIGHTS_NAME` - Application Insights name
- `AI_SERVICES_ENDPOINT` - AI Services endpoint

## Security Best Practices

1. ✅ Use managed identities (no passwords)
2. ✅ Enable HTTPS only
3. ✅ Disable ACR admin user
4. ✅ Use Azure RBAC for access control
5. ⚠️ Store secrets in Azure Key Vault (not implemented yet)
6. ⚠️ Configure network restrictions for production
7. ⚠️ Enable Azure Defender for Cloud
8. ⚠️ Implement custom domain with SSL

## Common Workflows

### Deploy Code Changes

```bash
# 1. Commit your changes
git add .
git commit -m "Your changes"
git push

# 2. Build and deploy
ACR_NAME=$(azd env get-value ACR_NAME)
az acr build --registry $ACR_NAME --image zavastorefrontapp:latest --file ./Dockerfile ./src

# 3. Restart app
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)
az webapp restart --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3
```

### Update Infrastructure

```bash
# 1. Modify Bicep files
# 2. Validate changes
az bicep build --file infra/main.bicep

# 3. Preview changes
az deployment group what-if \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json

# 4. Apply changes
azd provision
```

### View Application Logs

```bash
# Real-time logs
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)
az webapp log tail --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3

# Download logs
az webapp log download --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3 --log-file logs.zip
```

## Keyboard Shortcuts (Azure Portal)

- `G + N` - Notifications
- `G + /` - Search
- `G + D` - Dashboard
- `/` - Search focus

## Additional Resources

- [Full Documentation](./README.md)
- [Deployment Guide](./DEPLOYMENT.md)
- [Bicep Language Docs](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
