# Azure Infrastructure Deployment Guide

This guide provides instructions for deploying the ZavaStorefront web application to Azure using Azure Developer CLI (azd) and Bicep templates.

## Prerequisites

Before deploying, ensure you have the following installed:

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   # Install Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Verify installation
   az --version
   ```

2. **Azure Developer CLI (azd)** (version 1.5.0 or later)
   ```bash
   # Install azd on Linux/macOS
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Install azd on Windows (PowerShell)
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # Verify installation
   azd version
   ```

3. **Azure Subscription** with appropriate permissions to create resources

## Architecture Overview

The deployment creates the following Azure resources in the `westus3` region:

| Resource | Description |
|----------|-------------|
| Resource Group | Container for all resources |
| Azure Container Registry | Stores Docker container images |
| App Service Plan (Linux) | Hosts the web application |
| App Service | Linux container-based web app with managed identity |
| Log Analytics Workspace | Centralized logging |
| Application Insights | Application performance monitoring |
| Azure AI Hub | AI Foundry hub for model management |
| Azure AI Project | AI project for GPT-4 and Phi models |
| Azure AI Services | Cognitive services for AI capabilities |
| Key Vault | Secure secrets storage |
| Storage Account | Storage for AI services |

## Deployment Steps

### 1. Authenticate with Azure

```bash
# Login to Azure
az login

# Login to Azure Developer CLI
azd auth login
```

### 2. Initialize the Environment

```bash
# Navigate to the repository root
cd TechWorkshop-L300-GitHub-Copilot-and-platform

# Initialize azd environment (replace 'dev' with your environment name)
azd init -e dev
```

### 3. Configure Environment Variables (Optional)

You can customize the deployment by setting environment variables:

```bash
# Set the Azure location (default: westus3)
azd env set AZURE_LOCATION westus3

# Set custom resource names (optional)
azd env set AZURE_RESOURCE_GROUP_NAME rg-zavastorefront-dev
```

### 4. Deploy Infrastructure and Application

```bash
# Deploy everything with a single command
azd up
```

This command will:
1. Provision all Azure infrastructure using Bicep templates
2. Build the Docker container image using ACR Tasks (no local Docker needed)
3. Deploy the container to Azure App Service
4. Configure Application Insights integration

### 5. Verify Deployment

After deployment completes, you'll see output similar to:

```
Deploying services (azd deploy)

  (✓) Done: Deploying service zavastorefront
  - Endpoint: https://app-xxxxxxxxxx.azurewebsites.net

SUCCESS: Your application was provisioned and deployed to Azure.
```

Open the provided URL in a browser to verify the application is running.

## Deployment Commands Reference

| Command | Description |
|---------|-------------|
| `azd up` | Provision infrastructure and deploy application |
| `azd provision` | Provision infrastructure only |
| `azd deploy` | Deploy application only (infrastructure must exist) |
| `azd down` | Delete all Azure resources |
| `azd env list` | List all environments |
| `azd env get-values` | Show environment variables |

## Environment Variables

The following environment variables are automatically set after deployment:

| Variable | Description |
|----------|-------------|
| `AZURE_LOCATION` | Azure region (westus3) |
| `AZURE_RESOURCE_GROUP` | Resource group name |
| `AZURE_CONTAINER_REGISTRY_NAME` | Container Registry name |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | Container Registry login server |
| `AZURE_APP_SERVICE_NAME` | App Service name |
| `AZURE_APP_SERVICE_URL` | Application URL |
| `AZURE_APPLICATION_INSIGHTS_CONNECTION_STRING` | App Insights connection string |
| `AZURE_AI_HUB_NAME` | AI Hub name |
| `AZURE_AI_PROJECT_NAME` | AI Project name |

## Security Configuration

### Managed Identity

The App Service uses a **system-assigned managed identity** to securely pull container images from Azure Container Registry without storing credentials:

- No admin credentials or passwords are stored
- `AcrPull` role is automatically assigned to the App Service identity
- Images are pulled using Azure RBAC authentication

### Network Security

- HTTPS is enforced on the App Service
- TLS 1.2 minimum version is required
- FTPS is disabled
- Public network access is enabled for development

## Troubleshooting

### Common Issues

1. **Container image not pulling**
   ```bash
   # Verify the role assignment
   az role assignment list --scope /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name} --query "[?principalType=='ServicePrincipal']"
   ```

2. **Application Insights not receiving data**
   ```bash
   # Check App Service configuration
   az webapp config appsettings list --name {app-service-name} --resource-group {rg-name} --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
   ```

3. **Deployment failures**
   ```bash
   # View deployment logs
   azd deploy --debug
   
   # Check Azure activity logs
   az monitor activity-log list --resource-group {rg-name} --status Failed
   ```

4. **ACR build failures**
   ```bash
   # View ACR build logs
   az acr task logs --registry {acr-name}
   ```

### Reset Environment

If you encounter persistent issues:

```bash
# Delete all resources
azd down --force --purge

# Re-initialize and deploy
azd init -e dev
azd up
```

## Cleanup

To remove all Azure resources created by this deployment:

```bash
# Delete all resources (with confirmation)
azd down

# Delete all resources without confirmation and purge Key Vault
azd down --force --purge
```

## Cost Considerations

For development environments, the following SKUs are used to minimize costs:

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|------------------------|
| App Service Plan | B1 | ~$13 |
| Container Registry | Basic | ~$5 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| AI Services | S0 | Pay-per-use |

**Tip:** Use `azd down` to delete resources when not in use to avoid unnecessary charges.

## Next Steps

1. **Configure CI/CD**: See the GitHub Actions workflow in `.github/workflows/`
2. **Add custom domain**: Use Azure CLI or Portal to add a custom domain
3. **Scale the application**: Upgrade the App Service Plan SKU for production
4. **Enable staging slots**: Add deployment slots for zero-downtime deployments
