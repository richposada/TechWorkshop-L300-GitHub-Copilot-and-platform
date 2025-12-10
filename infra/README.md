# ZavaStorefront Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying the ZavaStorefront application to Azure using Bicep and Azure Developer CLI (azd).

## Architecture Overview

The infrastructure provisions the following Azure resources in westus3:

- **Resource Group**: `rg-zavastore-dev-westus3`
- **Azure Container Registry (ACR)**: Stores Docker container images (Basic SKU)
- **App Service Plan**: Linux-based plan for hosting containers (B1 SKU)
- **Web App (App Service)**: Web App for Containers that runs the .NET application
- **Application Insights**: Application monitoring and telemetry
- **Log Analytics Workspace**: Backend for Application Insights logs
- **AI Hub (Microsoft Foundry)**: Azure AI Services for GPT-4 and Phi models
- **Role Assignment**: AcrPull role for Web App managed identity to pull images from ACR

## Security Architecture

- **No Passwords**: Web App uses system-assigned managed identity to pull images from ACR
- **RBAC-based Access**: AcrPull role assignment enables secure container image pulls
- **HTTPS Only**: Web App enforces HTTPS for all traffic
- **TLS 1.2+**: Minimum TLS version enforced

## Resource Naming Convention

Resources follow the pattern: `<prefix>-<appName>-<environment>-<region>`

Examples:
- `rg-zavastore-dev-westus3` (Resource Group)
- `asp-zavastore-dev-westus3` (App Service Plan)
- `app-zavastore-dev-westus3` (Web App)
- `appi-zavastore-dev-westus3` (Application Insights)
- `ai-zavastore-dev-westus3` (AI Hub)

**Note**: ACR names must be alphanumeric only, so they follow a different pattern:
- `zavastoredev<unique-suffix>` (Container Registry)

## Directory Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── main.parameters.json            # Parameter values for deployment
├── modules/                        # Modular Bicep templates
│   ├── containerRegistry.bicep     # Azure Container Registry
│   ├── appServicePlan.bicep        # App Service Plan
│   ├── webApp.bicep                # Web App with managed identity
│   ├── applicationInsights.bicep   # Application Insights
│   ├── logAnalyticsWorkspace.bicep # Log Analytics Workspace
│   ├── aiHub.bicep                 # AI Hub (Microsoft Foundry)
│   └── roleAssignment.bicep        # RBAC role assignment
└── README.md                       # This file
```

## Prerequisites

1. **Azure CLI**: Install from https://aka.ms/azure-cli
2. **Azure Developer CLI (azd)**: Install from https://aka.ms/azd-install
3. **Azure Subscription**: Active subscription with Contributor access
4. **GitHub Account**: For CI/CD workflows (optional)

## Deployment Instructions

### Option 1: Deploy with Azure Developer CLI (Recommended)

1. **Login to Azure**:
   ```bash
   azd auth login
   ```

2. **Initialize the environment** (first time only):
   ```bash
   azd init
   ```

3. **Provision infrastructure**:
   ```bash
   azd provision
   ```
   
   This will:
   - Deploy all Azure resources defined in `main.bicep`
   - Create the resource group in westus3
   - Set up managed identity and role assignments
   - Output deployment details

4. **View deployment outputs**:
   ```bash
   azd env get-values
   ```

### Option 2: Deploy with Azure CLI

1. **Login to Azure**:
   ```bash
   az login
   ```

2. **Set your subscription** (if you have multiple):
   ```bash
   az account set --subscription <subscription-id>
   ```

3. **Deploy the Bicep template**:
   ```bash
   az deployment sub create \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

4. **View deployment outputs**:
   ```bash
   az deployment sub show \
     --name main \
     --query properties.outputs
   ```

## Building and Pushing Container Images

### Option 1: Using Azure CLI (Cloud-based Build)

No local Docker installation required! Use Azure Container Registry to build images in the cloud:

```bash
# Get your ACR name
ACR_NAME=$(az acr list --resource-group rg-zavastore-dev-westus3 --query "[0].name" -o tsv)

# Build and push image using ACR
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file Dockerfile \
  .
```

### Option 2: Using GitHub Actions (Automated)

The repository includes a GitHub Actions workflow (`.github/workflows/acr-build-push.yml`) that automatically:
1. Builds the Docker image in the cloud using `az acr build`
2. Pushes the image to ACR
3. Updates the Web App to use the new image
4. Restarts the Web App

**Setup Steps**:

1. Set up Azure credentials in GitHub:
   - Create a service principal: 
     ```bash
     az ad sp create-for-rbac --name "gh-zavastore-sp" --role contributor \
       --scopes /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3 \
       --sdk-auth
     ```
   - Add GitHub secrets:
     - `AZURE_CLIENT_ID`
     - `AZURE_TENANT_ID`
     - `AZURE_SUBSCRIPTION_ID`

2. Push code to trigger the workflow:
   ```bash
   git push origin main
   ```

## Updating the Web App

After pushing a new image to ACR, update the Web App:

```bash
# Get resource names
ACR_NAME=$(az acr list --resource-group rg-zavastore-dev-westus3 --query "[0].name" -o tsv)
WEBAPP_NAME="app-zavastore-dev-westus3"

# Update Web App container image
az webapp config container set \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-custom-image-name $ACR_NAME.azurecr.io/zavastore:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Restart Web App
az webapp restart \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3
```

## Monitoring and Observability

### Application Insights

Application Insights is automatically configured for the Web App. View telemetry:

1. **Azure Portal**: Navigate to Application Insights resource
2. **Azure CLI**:
   ```bash
   az monitor app-insights component show \
     --app appi-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3
   ```

### Log Analytics

Query logs using Kusto Query Language (KQL):

```bash
az monitor log-analytics query \
  --workspace log-zavastore-dev-westus3 \
  --analytics-query "requests | take 10"
```

## AI Services (Microsoft Foundry)

The AI Hub is provisioned for GPT-4 and Phi model access in westus3.

**Get AI Hub details**:
```bash
az cognitiveservices account show \
  --name ai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

**Get API keys** (for application integration):
```bash
az cognitiveservices account keys list \
  --name ai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

## Cost Optimization

This infrastructure uses minimal-cost SKUs appropriate for development:

- **ACR**: Basic SKU (~$5/month)
- **App Service Plan**: B1 (Basic, ~$13/month)
- **Application Insights**: Pay-as-you-go (first 5GB free monthly)
- **Log Analytics**: Pay-as-you-go (first 5GB free monthly)
- **AI Services**: S0 SKU (pay per API call)

**Estimated Monthly Cost**: ~$20-30 USD (excluding AI API usage)

### Cost Reduction Tips

1. **Stop App Service Plan when not in use**:
   ```bash
   az appservice plan update \
     --name asp-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3 \
     --number-of-workers 0
   ```

2. **Delete all resources** when not needed:
   ```bash
   az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
   ```

## Troubleshooting

### Web App not starting

1. **Check logs**:
   ```bash
   az webapp log tail \
     --name app-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3
   ```

2. **Check container logs**:
   ```bash
   az webapp log download \
     --name app-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3 \
     --log-file logs.zip
   ```

3. **Verify image pull**:
   - Check that Web App managed identity has AcrPull role on ACR
   - Verify image exists in ACR: `az acr repository list --name <acr-name>`

### Deployment failures

1. **Check deployment logs**:
   ```bash
   az deployment sub show \
     --name main \
     --query properties.error
   ```

2. **Validate Bicep template**:
   ```bash
   az deployment sub validate \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

### Role assignment issues

If the Web App can't pull images from ACR:

1. **Verify role assignment**:
   ```bash
   az role assignment list \
     --assignee <web-app-principal-id> \
     --scope /subscriptions/<sub-id>/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/<acr-name>
   ```

2. **Manually assign role** (if needed):
   ```bash
   WEBAPP_ID=$(az webapp identity show \
     --name app-zavastore-dev-westus3 \
     --resource-group rg-zavastore-dev-westus3 \
     --query principalId -o tsv)
   
   ACR_ID=$(az acr show \
     --name <acr-name> \
     --query id -o tsv)
   
   az role assignment create \
     --assignee $WEBAPP_ID \
     --role AcrPull \
     --scope $ACR_ID
   ```

## Clean Up

To delete all resources:

```bash
# Using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait

# Using azd
azd down
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Azure App Service](https://learn.microsoft.com/azure/app-service/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Services](https://learn.microsoft.com/azure/ai-services/)
