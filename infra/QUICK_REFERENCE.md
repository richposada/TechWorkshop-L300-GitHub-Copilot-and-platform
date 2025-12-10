# Infrastructure Quick Reference

## Resource Names (Dev Environment)

| Resource Type | Name | Description |
|--------------|------|-------------|
| Resource Group | `rg-zavastore-dev-westus3` | Container for all resources |
| Container Registry | `zavastoredev<unique>` | Stores Docker images |
| App Service Plan | `asp-zavastore-dev-westus3` | Hosting plan for Web App |
| Web App | `app-zavastore-dev-westus3` | Containerized web application |
| Application Insights | `appi-zavastore-dev-westus3` | Application monitoring |
| Log Analytics | `log-zavastore-dev-westus3` | Log storage and queries |
| AI Hub | `ai-zavastore-dev-westus3` | Azure AI Services |

## Common Commands

### Provision Infrastructure

```bash
# Using azd
azd provision

# Using Azure CLI
az deployment sub create \
  --location westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Build and Push Image

```bash
# Get ACR name
ACR_NAME=$(az acr list --resource-group rg-zavastore-dev-westus3 --query "[0].name" -o tsv)

# Cloud-based build (no Docker required)
az acr build --registry $ACR_NAME --image zavastore:latest --file Dockerfile .
```

### Update Web App

```bash
# Update container image
az webapp config container set \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-custom-image-name $ACR_NAME.azurecr.io/zavastore:latest \
  --docker-registry-server-url https://$ACR_NAME.azurecr.io

# Restart
az webapp restart \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

### View Logs

```bash
# Live tail
az webapp log tail --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3

# Download logs
az webapp log download \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --log-file logs.zip
```

### Get URLs

```bash
# Web App URL
az webapp show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query defaultHostName -o tsv

# Application Insights
az monitor app-insights component show \
  --app appi-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query appId -o tsv
```

## SKU Details

### Development Environment
- **ACR**: Basic
- **App Service Plan**: B1 (Basic, 1 core, 1.75 GB RAM)
- **Application Insights**: Pay-as-you-go
- **Log Analytics**: Pay-as-you-go
- **AI Services**: S0 (pay-per-call)

### Production Considerations
For production, consider upgrading to:
- **ACR**: Standard or Premium (for geo-replication)
- **App Service Plan**: P1V2 or higher
- **Enable**: Private endpoints, VNet integration, firewall rules

## Role Assignments

| Identity | Role | Scope | Purpose |
|----------|------|-------|---------|
| Web App (System-Assigned) | AcrPull | Container Registry | Pull images from ACR |

## Environment Variables (Web App)

| Variable | Value | Purpose |
|----------|-------|---------|
| `WEBSITES_ENABLE_APP_SERVICE_STORAGE` | false | Use container filesystem |
| `DOCKER_REGISTRY_SERVER_URL` | https://[acr].azurecr.io | ACR endpoint |
| `DOCKER_ENABLE_CI` | true | Enable continuous deployment |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | [connection-string] | App Insights integration |
| `ApplicationInsightsAgent_EXTENSION_VERSION` | ~3 | App Insights agent |

## Naming Convention

Pattern: `<prefix>-<appName>-<environment>-<region>`

Prefixes:
- `rg-`: Resource Group
- `asp-`: App Service Plan
- `app-`: Web App
- `appi-`: Application Insights
- `log-`: Log Analytics Workspace
- `ai-`: AI Services

**Exception**: ACR uses alphanumeric only: `<appName><environment><unique-suffix>`

## Security Features

✅ System-Assigned Managed Identity (no passwords)
✅ RBAC-based ACR access (AcrPull role)
✅ HTTPS enforced
✅ TLS 1.2+ minimum
✅ Admin user disabled on ACR
✅ Application Insights for security monitoring

## Cleanup

```bash
# Delete everything
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait

# Or with azd
azd down
```

## Bicep Module Structure

```
infra/
├── main.bicep                      # Orchestration template
├── main.parameters.json            # Parameter values
└── modules/
    ├── containerRegistry.bicep     # ACR
    ├── appServicePlan.bicep        # App Service Plan
    ├── webApp.bicep                # Web App + Managed Identity
    ├── applicationInsights.bicep   # App Insights
    ├── logAnalyticsWorkspace.bicep # Log Analytics
    ├── aiHub.bicep                 # AI Services
    └── roleAssignment.bicep        # RBAC assignments
```

## GitHub Actions Workflow

File: `.github/workflows/acr-build-push.yml`

Triggers:
- Push to `main` or `develop` branches
- Changes in `src/`, `Dockerfile`, or workflow file
- Manual workflow dispatch

Actions:
1. Checkout code
2. Azure login (federated credentials)
3. Get ACR name from Azure
4. Build and push image with `az acr build`
5. Update Web App container config
6. Restart Web App

## Useful Links

- [Main Infrastructure README](README.md)
- [Deployment Guide](../DEPLOYMENT.md)
- [Application README](../src/README.md)
