# ZavaStorefront - Azure Deployment Guide

This guide provides instructions for deploying the ZavaStorefront application to Azure.

## Application Overview

**ZavaStorefront** is a .NET 6 ASP.NET MVC e-commerce storefront application that can be deployed as a containerized application to Azure App Service.

## Architecture

- **Application**: .NET 6 ASP.NET MVC web application
- **Hosting**: Azure App Service (Web App for Containers)
- **Container Registry**: Azure Container Registry (ACR)
- **Monitoring**: Application Insights + Log Analytics
- **AI Services**: Microsoft Foundry (Azure AI Services) for GPT-4 and Phi models
- **Region**: westus3
- **Security**: Managed Identity with RBAC for secure ACR access (no passwords)

All resources are provisioned in a single resource group: `rg-zavastore-dev-westus3`

## Prerequisites

1. **Azure CLI**: Install from https://aka.ms/azure-cli
2. **Azure Developer CLI (azd)**: Install from https://aka.ms/azd-install
3. **Azure Subscription**: Active subscription with Contributor access
4. **.NET 6 SDK** (for local development): https://dotnet.microsoft.com/download

## Quick Start - Local Development

Run the application locally without Docker:

```bash
cd src
dotnet restore
dotnet run
```

Then navigate to `https://localhost:5001` in your browser.

## Deploy to Azure

### Step 1: Login to Azure

```bash
azd auth login
```

### Step 2: Provision Infrastructure

This will create all Azure resources defined in the `infra/` directory:

```bash
azd provision
```

The provisioning will create:
- Resource Group: `rg-zavastore-dev-westus3`
- Azure Container Registry (ACR)
- App Service Plan (Linux)
- Web App with System-Assigned Managed Identity
- Application Insights
- Log Analytics Workspace
- AI Hub (Microsoft Foundry)
- Role Assignment (AcrPull for Web App)

### Step 3: Build and Push Docker Image

Use Azure Container Registry's cloud-based build (no local Docker required):

```bash
# Get ACR name
ACR_NAME=$(az acr list --resource-group rg-zavastore-dev-westus3 --query "[0].name" -o tsv)

# Build and push image to ACR
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file Dockerfile \
  .
```

### Step 4: Update Web App

Update the Web App to use the newly built image:

```bash
# Update Web App container configuration
az webapp config container set \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-custom-image-name $ACR_NAME.azurecr.io/zavastore:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Restart Web App
az webapp restart \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

### Step 5: Access Your Application

Get the Web App URL:

```bash
az webapp show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query defaultHostName -o tsv
```

Navigate to `https://<hostname>` in your browser.

## Continuous Deployment with GitHub Actions

The repository includes a GitHub Actions workflow for automated builds and deployments.

### Setup GitHub Actions

1. Create a service principal for GitHub:
   ```bash
   az ad sp create-for-rbac \
     --name "gh-zavastore-sp" \
     --role contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3 \
     --sdk-auth
   ```

2. Add the following secrets to your GitHub repository:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. Push code to the `main` or `develop` branch to trigger the workflow.

The workflow will:
1. Build the Docker image using `az acr build` (cloud-based)
2. Push the image to ACR
3. Update the Web App to use the new image
4. Restart the Web App

## Monitoring

### Application Insights

View application telemetry in the Azure Portal or using Azure CLI:

```bash
# Get Application Insights details
az monitor app-insights component show \
  --app appi-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

### Live Logs

Stream live logs from your Web App:

```bash
az webapp log tail \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

## Cost Estimates

Development environment with minimal SKUs:

- **ACR Basic**: ~$5/month
- **App Service Plan B1**: ~$13/month
- **Application Insights**: Pay-as-you-go (first 5GB free)
- **Log Analytics**: Pay-as-you-go (first 5GB free)
- **AI Services**: Pay-per-use (S0 SKU)

**Estimated Total**: ~$20-30 USD/month (excluding AI API usage)

## Cleanup

To delete all resources and stop incurring costs:

```bash
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## Troubleshooting

### Web App not starting

Check logs:
```bash
az webapp log tail --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
```

### Image pull errors

Verify the managed identity has AcrPull permissions:
```bash
# Get Web App principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query principalId -o tsv)

# Verify role assignment
az role assignment list --assignee $PRINCIPAL_ID
```

## Additional Resources

- [Detailed Infrastructure Documentation](infra/README.md)
- [Application Source Code](src/README.md)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
