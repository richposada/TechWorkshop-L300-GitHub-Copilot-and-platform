# Infrastructure as Code

This directory contains Azure Bicep templates for deploying the ZavaStorefront application infrastructure using Azure Developer CLI (azd).

## Directory Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Parameter file for deployment
├── abbreviations.json            # Resource naming abbreviations
├── app/
│   ├── app-service.bicep         # App Service and App Service Plan
│   ├── container-registry.bicep  # Azure Container Registry
│   └── acr-role-assignment.bicep # RBAC for App Service to pull from ACR
├── core/
│   └── monitoring/
│       ├── app-insights.bicep    # Application Insights
│       └── log-analytics.bicep   # Log Analytics Workspace
└── ai/
    └── ai-foundry.bicep          # Azure AI Foundry Hub, Project, and OpenAI
```

## Resources Deployed

| Resource | Description |
|----------|-------------|
| **Resource Group** | Container for all resources |
| **App Service Plan** | Linux P1v2 plan for container hosting |
| **App Service** | Linux container web app with managed identity |
| **Container Registry** | Standard tier ACR with RBAC (no admin access) |
| **Log Analytics Workspace** | Centralized logging with 30-day retention |
| **Application Insights** | Workspace-based APM for .NET monitoring |
| **AI Foundry Hub** | Azure AI Hub for model management |
| **AI Foundry Project** | AI Project linked to the Hub |
| **Azure OpenAI** | OpenAI service with GPT-4 deployment |
| **Storage Account** | Storage for AI Foundry |
| **Key Vault** | Secrets management for AI Foundry |

## Security Features

- **Managed Identity**: App Service uses system-assigned managed identity
- **RBAC Only**: Container Registry uses RBAC instead of admin credentials
- **AcrPull Role**: App Service identity has AcrPull role on Container Registry
- **Cognitive Services User**: App Service can access Azure OpenAI
- **No Passwords**: No hardcoded credentials or passwords

## Naming Conventions

Resources use the following naming pattern:
- `{abbreviation}{unique-token}` for most resources
- Unique token is generated from subscription ID, environment name, and location

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `environmentName` | Name of the environment (e.g., dev, prod) | Required |
| `location` | Azure region for deployment | Required |
| `resourceGroupName` | Custom resource group name | Auto-generated |
| `containerImageName` | Docker image name | `zavastorefont` |
| `containerImageTag` | Docker image tag | `latest` |

## Outputs

The deployment exports the following values:
- `AZURE_CONTAINER_REGISTRY_ENDPOINT` - ACR login server URL
- `AZURE_CONTAINER_REGISTRY_NAME` - ACR name
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - App Insights connection string
- `APP_SERVICE_NAME` - App Service name
- `APP_SERVICE_HOSTNAME` - App Service default hostname
- `AI_FOUNDRY_HUB_NAME` - AI Foundry Hub name
- `AI_FOUNDRY_PROJECT_NAME` - AI Foundry Project name
- `AI_FOUNDRY_ENDPOINT` - Azure OpenAI endpoint

## Deployment

See [deployment documentation](../docs/deployment.md) for full instructions.

Quick start:
```bash
# Login to Azure
azd auth login

# Deploy infrastructure and application
azd up

# View deployed resources
az group list --query "[?starts_with(name, 'rg-')].{Name:name, Location:location}" -o table
```

## Cleanup

```bash
# Remove all resources
azd down --force --purge
```

The `--purge` flag ensures soft-deleted resources (like Key Vault) are permanently deleted.
