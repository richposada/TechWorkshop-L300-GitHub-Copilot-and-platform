# ZavaStorefront Azure Deployment Guide

This guide provides step-by-step instructions for deploying the ZavaStorefront application to Azure using Azure Developer CLI (azd).

## Prerequisites

### Required Tools

1. **Azure CLI** (version 2.50 or later)
   ```bash
   # Install on macOS
   brew install azure-cli
   
   # Install on Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Install on Windows
   winget install Microsoft.AzureCLI
   
   # Verify installation
   az --version
   ```

2. **Azure Developer CLI (azd)** (version 1.5 or later)
   ```bash
   # Install on macOS
   brew install azure-dev
   
   # Install on Ubuntu/Debian
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Install on Windows
   winget install Microsoft.Azd
   
   # Verify installation
   azd version
   ```

3. **Git** (for version control)
   ```bash
   git --version
   ```

### Azure Requirements

- Active Azure subscription with appropriate permissions
- Contributor or Owner role on the subscription
- Ability to create service principals and role assignments

> **Note**: Docker is **NOT** required locally. Container images are built in Azure using ACR Tasks.

## Deployment Steps

### 1. Authenticate with Azure

```bash
# Login to Azure Developer CLI
azd auth login

# Login to Azure CLI (if not already logged in)
az login
```

### 2. Initialize Environment (First Time Only)

```bash
# Navigate to repository root
cd TechWorkshop-L300-GitHub-Copilot-and-platform

# Initialize azd environment
azd init

# When prompted:
# - Environment name: dev (or your preferred name)
```

### 3. Configure Environment

```bash
# Set the Azure region (westus3 for AI model availability)
azd env set AZURE_LOCATION westus3
```

### 4. Deploy Infrastructure and Application

```bash
# Deploy everything with a single command
azd up
```

This command will:
1. Create the Azure resource group
2. Deploy all infrastructure (App Service, ACR, AI Foundry, etc.)
3. Build the container image in ACR (no local Docker needed)
4. Deploy the application to App Service

### 5. Verify Deployment

```bash
# Get the deployed application URL
azd show

# Or check specific outputs
az webapp show --name <app-service-name> --resource-group <resource-group-name> --query defaultHostName -o tsv
```

## Environment Variables

The following environment variables are automatically configured:

| Variable | Description |
|----------|-------------|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string |
| `ASPNETCORE_ENVIRONMENT` | Set to `Production` |
| `DOCKER_REGISTRY_SERVER_URL` | ACR login server URL |
| `WEBSITES_PORT` | Application port (8080) |

## Additional Commands

### View Logs

```bash
# Stream App Service logs
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

### Redeploy Application Only

```bash
# Deploy just the application (not infrastructure)
azd deploy
```

### Update Infrastructure Only

```bash
# Provision infrastructure without deploying application
azd provision
```

### View All Resources

```bash
# List resources in the resource group
az resource list --resource-group <resource-group-name> -o table
```

## AI Foundry Configuration

After deployment, the following AI resources are available:

- **Azure OpenAI** with GPT-4 model deployment
- **AI Foundry Hub** for model management
- **AI Foundry Project** for application integration

### Access AI Services

```bash
# Get OpenAI endpoint
az cognitiveservices account show --name <openai-account-name> --resource-group <resource-group-name> --query properties.endpoint -o tsv

# Test GPT-4 deployment
az cognitiveservices account deployment list --name <openai-account-name> --resource-group <resource-group-name> -o table
```

## Troubleshooting

### Issue: ACR Build Fails

**Symptom**: `az acr build` command fails during deployment

**Solution**:
1. Verify you have Contributor role on the subscription
2. Ensure the Dockerfile is valid:
   ```bash
   # Validate Dockerfile syntax
   docker build --no-cache -f src/Dockerfile src/
   ```
3. Check ACR logs:
   ```bash
   az acr task list-runs --registry <acr-name> -o table
   ```

### Issue: App Service Cannot Pull Image

**Symptom**: App Service shows container pull errors

**Solution**:
1. Verify managed identity is enabled:
   ```bash
   az webapp identity show --name <app-name> --resource-group <rg-name>
   ```
2. Check AcrPull role assignment:
   ```bash
   az role assignment list --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<acr> --query "[?roleDefinitionName=='AcrPull']"
   ```
3. Restart the App Service:
   ```bash
   az webapp restart --name <app-name> --resource-group <rg-name>
   ```

### Issue: Application Insights Not Receiving Data

**Symptom**: No telemetry in Application Insights

**Solution**:
1. Verify connection string is set:
   ```bash
   az webapp config appsettings list --name <app-name> --resource-group <rg-name> --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
   ```
2. Check application logs for connection errors
3. Wait 5-10 minutes for initial data to appear

### Issue: AI Foundry Resources Not Accessible

**Symptom**: Cannot access Azure OpenAI endpoint

**Solution**:
1. Verify RBAC assignment:
   ```bash
   az role assignment list --assignee <app-identity-id> --query "[?roleDefinitionName=='Cognitive Services User']"
   ```
2. Check network configuration allows access
3. Verify model deployment is active:
   ```bash
   az cognitiveservices account deployment show --name <openai-name> --resource-group <rg-name> --deployment-name gpt-4
   ```

## Cleanup

To remove all deployed resources:

```bash
# Delete all resources (with confirmation)
azd down

# Delete without confirmation and purge soft-deleted resources
azd down --force --purge
```

> **Note**: The `--purge` flag is important to permanently delete Key Vault, which uses soft-delete by default.

## Cost Optimization

The development configuration uses cost-effective SKUs:

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|----------------------|
| App Service Plan | P1v2 | ~$74 |
| Container Registry | Standard | ~$20 |
| Application Insights | Pay-per-GB | ~$2-10 |
| Log Analytics | Per-GB (1GB cap) | ~$2-5 |
| Azure OpenAI | Pay-per-token | Usage-based |
| Storage Account | Standard LRS | ~$2 |
| Key Vault | Standard | ~$0.03/10K operations |

**Tips for reducing costs**:
- Delete resources when not in use
- Use `azd down` to remove everything after testing
- Monitor Azure Cost Management for actual spending
