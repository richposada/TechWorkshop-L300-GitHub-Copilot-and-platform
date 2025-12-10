# ZavaStorefront Azure Infrastructure

This directory contains Bicep templates and configuration for deploying the ZavaStorefront web application to Azure.

## Architecture Overview

The infrastructure includes:
- **Azure Container Registry (ACR)** - Stores Docker container images
- **App Service Plan (Linux)** - Hosts the web application
- **Web App for Containers** - Runs the containerized .NET application
- **Application Insights** - Monitors application performance and telemetry
- **Log Analytics Workspace** - Centralized logging and analytics
- **Azure AI Services (Foundry)** - Provides GPT-4 and Phi model access
- **Managed Identity** - Secure, password-less ACR authentication with AcrPull role

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)** - [Install azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Azure Subscription** - With permissions to create resources
4. **Bicep CLI** - Included with Azure CLI

## Cost Estimates (Dev Environment)

Approximate monthly costs for development environment in West US 3:

| Resource | SKU/Tier | Estimated Cost |
|----------|----------|----------------|
| App Service Plan | B1 (Basic) | ~$13/month |
| Azure Container Registry | Basic | ~$5/month |
| Application Insights | Pay-as-you-go | ~$2-10/month |
| Log Analytics Workspace | Pay-as-you-go | ~$2-5/month |
| Azure AI Services | S0 | ~$1/1K tokens |
| **Total** | | **~$25-35/month** |

*Note: Costs vary based on usage. Review [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for detailed estimates.*

## Deployment Instructions

### Option 1: Using Azure Developer CLI (azd) - Recommended

1. **Initialize the environment**:
   ```bash
   azd init
   ```

2. **Login to Azure**:
   ```bash
   azd auth login
   ```

3. **Provision infrastructure**:
   ```bash
   azd provision
   ```
   
   This will:
   - Create the resource group `rg-zavastore-dev-westus3`
   - Deploy all Azure resources
   - Build and push the Docker image to ACR using cloud build
   - Configure the Web App to pull from ACR using managed identity

4. **Deploy the application**:
   ```bash
   azd deploy
   ```

5. **View the deployed application**:
   ```bash
   azd show
   ```

### Option 2: Using Azure CLI Directly

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

2. **Create the resource group**:
   ```bash
   az group create --name rg-zavastore-dev-westus3 --location westus3
   ```

3. **Deploy the Bicep template**:
   ```bash
   az deployment group create \
     --resource-group rg-zavastore-dev-westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

4. **Build and push Docker image to ACR**:
   ```bash
   # Get ACR name from deployment outputs
   ACR_NAME=$(az deployment group show \
     --resource-group rg-zavastore-dev-westus3 \
     --name main \
     --query properties.outputs.acrName.value -o tsv)
   
   # Build and push using ACR cloud build (no local Docker required)
   az acr build \
     --registry $ACR_NAME \
     --image zavastorefrontapp:latest \
     --file ./Dockerfile \
     ./src
   ```

5. **Restart the Web App to pull the new image**:
   ```bash
   WEBAPP_NAME=$(az deployment group show \
     --resource-group rg-zavastore-dev-westus3 \
     --name main \
     --query properties.outputs.webAppName.value -o tsv)
   
   az webapp restart \
     --name $WEBAPP_NAME \
     --resource-group rg-zavastore-dev-westus3
   ```

## Infrastructure Modules

The infrastructure is organized into modular Bicep files:

- **`main.bicep`** - Main orchestration template
- **`modules/acr.bicep`** - Azure Container Registry
- **`modules/appServicePlan.bicep`** - Linux App Service Plan
- **`modules/webApp.bicep`** - Web App for Containers
- **`modules/appInsights.bicep`** - Application Insights
- **`modules/logAnalytics.bicep`** - Log Analytics Workspace
- **`modules/roleAssignment.bicep`** - RBAC role assignments
- **`modules/aiFoundry.bicep`** - Azure AI Services

## Configuration

### Resource Naming

Resources follow Azure naming conventions:
- Resource Group: `rg-zavastore-dev-westus3`
- ACR: `acrzavastoredevwestus3` (alphanumeric only)
- App Service Plan: `asp-zavastore-dev-westus3`
- Web App: `app-zavastore-dev-westus3`
- App Insights: `appi-zavastore-dev-westus3`
- Log Analytics: `log-zavastore-dev-westus3`
- AI Services: `ai-zavastore-dev-westus3`

### Managed Identity and Security

- Web App uses **System-Assigned Managed Identity**
- Managed Identity has **AcrPull** role on ACR
- No password-based authentication for ACR
- ACR admin user is disabled
- HTTPS enforced on Web App

### Application Insights Integration

Application Insights is configured via environment variables:
- `APPLICATIONINSIGHTS_CONNECTION_STRING`
- `APPINSIGHTS_INSTRUMENTATIONKEY`
- `ApplicationInsightsAgent_EXTENSION_VERSION`

## CI/CD with GitHub Actions

### Setup GitHub Actions Workflow

1. **Create a service principal with federated credentials**:
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-zavastore" \
     --role contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3 \
     --sdk-auth
   ```

2. **Configure GitHub Secrets**:
   - `AZURE_CLIENT_ID` - Service principal client ID
   - `AZURE_TENANT_ID` - Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID` - Azure subscription ID
   - `ACR_NAME` - ACR name (e.g., `acrzavastoredevwestus3`)
   - `WEBAPP_NAME` - Web App name (e.g., `app-zavastore-dev-westus3`)
   - `RESOURCE_GROUP_NAME` - Resource group name

3. **Workflow triggers**:
   - Pushes to `main` branch affecting `src/**` or `Dockerfile`
   - Manual workflow dispatch

The workflow uses `az acr build` to build the Docker image in the cloud, eliminating the need for local Docker.

## Validation and Testing

### Validate Bicep Templates

```bash
# Validate main template
az deployment group validate \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json

# What-if analysis (preview changes)
az deployment group what-if \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Smoke Test

1. **Access the Web App**:
   ```bash
   WEBAPP_URL=$(az deployment group show \
     --resource-group rg-zavastore-dev-westus3 \
     --name main \
     --query properties.outputs.webAppUrl.value -o tsv)
   
   echo "Application URL: $WEBAPP_URL"
   curl -I $WEBAPP_URL
   ```

2. **Check Application Insights**:
   - Navigate to Azure Portal
   - Open Application Insights resource
   - View Live Metrics and Application Map

3. **Verify ACR Integration**:
   ```bash
   # Check Web App configuration
   az webapp config show \
     --name $WEBAPP_NAME \
     --resource-group rg-zavastore-dev-westus3 \
     --query "linuxFxVersion"
   ```

4. **Test AI Services**:
   ```bash
   AI_ENDPOINT=$(az deployment group show \
     --resource-group rg-zavastore-dev-westus3 \
     --name main \
     --query properties.outputs.aiServicesEndpoint.value -o tsv)
   
   echo "AI Services Endpoint: $AI_ENDPOINT"
   ```

## Monitoring and Observability

### Application Insights

Access Application Insights to monitor:
- Request rates and response times
- Failed requests and exceptions
- Dependencies and performance
- Custom telemetry

### Log Analytics

Query logs using KQL:
```kusto
// Recent application logs
AppServiceConsoleLogs
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc

// Failed requests
requests
| where success == false
| order by timestamp desc
```

## Troubleshooting

### Web App not pulling from ACR

1. Verify managed identity has AcrPull role:
   ```bash
   az role assignment list \
     --assignee <webapp-principal-id> \
     --scope /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/<acr-name>
   ```

2. Check Web App logs:
   ```bash
   az webapp log tail \
     --name $WEBAPP_NAME \
     --resource-group rg-zavastore-dev-westus3
   ```

### Image build fails

1. Check ACR build logs:
   ```bash
   az acr task logs --registry $ACR_NAME
   ```

2. Verify Dockerfile path and context

### AI Services quota issues

Check regional availability and quotas for GPT-4 and Phi models in westus3:
```bash
az cognitiveservices account list-skus \
  --kind AIServices \
  --location westus3
```

## Clean Up

To delete all resources:

```bash
# Using azd
azd down

# Or using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## Additional Resources

- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [App Service for Containers](https://docs.microsoft.com/azure/app-service/containers/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Services](https://learn.microsoft.com/azure/ai-services/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
