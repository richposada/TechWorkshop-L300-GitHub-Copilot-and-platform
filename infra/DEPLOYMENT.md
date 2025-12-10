# Deployment Guide for ZavaStorefront Azure Infrastructure

This guide provides step-by-step instructions for deploying the ZavaStorefront application infrastructure to Azure.

## Prerequisites Checklist

Before starting the deployment, ensure you have:

- [ ] Azure subscription with appropriate permissions
- [ ] Azure CLI installed (version 2.50.0 or later)
- [ ] Azure Developer CLI (azd) installed
- [ ] Git installed
- [ ] Access to the GitHub repository
- [ ] Verified westus3 region availability for your subscription

## Deployment Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/richposada/TechWorkshop-L300-GitHub-Copilot-and-platform.git
cd TechWorkshop-L300-GitHub-Copilot-and-platform
```

### Step 2: Login to Azure

```bash
# Login to Azure CLI
az login

# Set your subscription (if you have multiple)
az account set --subscription "<your-subscription-id>"

# Verify your subscription
az account show

# Login to Azure Developer CLI
azd auth login
```

### Step 3: Initialize Azure Developer CLI Environment

```bash
# Initialize the environment
azd init

# Or if already initialized, select your environment
azd env select
```

When prompted:
- **Environment name**: Enter `dev` (or your preferred name)
- **Azure location**: Enter `westus3`
- **Subscription**: Select your Azure subscription

### Step 4: Provision Infrastructure

```bash
# Provision all Azure resources
azd provision
```

This command will:
1. Create the resource group `rg-zavastore-dev-westus3`
2. Deploy all Bicep templates
3. Create ACR, App Service, Application Insights, etc.
4. Configure managed identity and role assignments
5. Build and push the Docker image to ACR (postprovision hook)

**Expected Duration**: 5-10 minutes

### Step 5: Verify Deployment

```bash
# Get deployment outputs
azd env get-values

# Check resource group
az group show --name rg-zavastore-dev-westus3

# List all resources
az resource list --resource-group rg-zavastore-dev-westus3 --output table
```

### Step 6: Access the Application

```bash
# Get the web app URL
WEBAPP_URL=$(azd env get-value WEBAPP_URL)
echo "Application URL: $WEBAPP_URL"

# Open in browser
open $WEBAPP_URL  # macOS
start $WEBAPP_URL # Windows
xdg-open $WEBAPP_URL # Linux
```

### Step 7: Configure GitHub Actions (Optional)

For CI/CD with GitHub Actions:

1. **Create a Service Principal with Federated Credentials**:

```bash
# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-zavastore-dev-westus3 \
  --sdk-auth
```

2. **Configure GitHub Secrets**:

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

- `AZURE_CLIENT_ID`: Client ID from service principal
- `AZURE_TENANT_ID`: Tenant ID from Azure
- `AZURE_SUBSCRIPTION_ID`: Your subscription ID
- `ACR_NAME`: Value from `azd env get-value ACR_NAME`
- `WEBAPP_NAME`: Value from `azd env get-value WEBAPP_NAME`
- `RESOURCE_GROUP_NAME`: `rg-zavastore-dev-westus3`

3. **Test the Workflow**:

```bash
# Make a change to the application
# Commit and push to main branch
git add .
git commit -m "Test deployment"
git push origin main

# Watch the workflow in GitHub Actions
```

## Post-Deployment Configuration

### Configure Application Settings

Add any application-specific settings:

```bash
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)

az webapp config appsettings set \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --settings \
    "MyCustomSetting=Value" \
    "AnotherSetting=AnotherValue"
```

### Enable Diagnostic Logging

```bash
# Enable application logging
az webapp log config \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --application-logging filesystem \
  --level information

# View logs
az webapp log tail \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3
```

### Configure Custom Domain (Optional)

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --hostname "www.yourdomain.com"

# Bind SSL certificate
az webapp config ssl bind \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

## Updating the Deployment

### Update Infrastructure

If you modify Bicep templates:

```bash
# Re-provision infrastructure
azd provision
```

### Update Application Code

```bash
# Build and deploy new version
azd deploy

# Or manually build and push to ACR
ACR_NAME=$(azd env get-value ACR_NAME)
az acr build \
  --registry $ACR_NAME \
  --image zavastorefrontapp:latest \
  --file ./Dockerfile \
  ./src

# Restart web app
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)
az webapp restart \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3
```

## Monitoring and Diagnostics

### Application Insights

```bash
# Get Application Insights details
APP_INSIGHTS_NAME=$(azd env get-value APP_INSIGHTS_NAME)

# View live metrics in portal
az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group rg-zavastore-dev-westus3
```

Navigate to Azure Portal → Application Insights → $APP_INSIGHTS_NAME to view:
- Live Metrics
- Application Map
- Performance
- Failures
- Metrics

### Log Analytics Queries

Sample queries for Log Analytics:

```kusto
// Recent application logs
AppServiceConsoleLogs
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
| take 100

// Failed requests
requests
| where success == false
| order by timestamp desc
| take 100

// Performance metrics
requests
| summarize avg(duration), percentile(duration, 95) by bin(timestamp, 5m)
| order by timestamp desc
```

## Rollback Procedures

### Rollback Application

```bash
# List ACR images
ACR_NAME=$(azd env get-value ACR_NAME)
az acr repository show-tags \
  --name $ACR_NAME \
  --repository zavastorefrontapp \
  --output table

# Update web app to use specific tag
WEBAPP_NAME=$(azd env get-value WEBAPP_NAME)
az webapp config container set \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-custom-image-name "$ACR_NAME.azurecr.io/zavastorefrontapp:<previous-tag>"

# Restart web app
az webapp restart \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3
```

### Rollback Infrastructure

Use Azure Deployment History:

```bash
# List deployments
az deployment group list \
  --resource-group rg-zavastore-dev-westus3 \
  --output table

# Get specific deployment template
az deployment group show \
  --resource-group rg-zavastore-dev-westus3 \
  --name <deployment-name>

# Redeploy previous version
az deployment group create \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

## Cleanup

### Remove All Resources

```bash
# Using azd (recommended)
azd down

# Or using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

### Remove Service Principal (if created)

```bash
# List service principals
az ad sp list --display-name "github-actions-zavastore" --output table

# Delete service principal
az ad sp delete --id <object-id>
```

## Common Issues and Solutions

### Issue: Bicep deployment fails

**Solution**: Check deployment logs
```bash
az deployment group show \
  --resource-group rg-zavastore-dev-westus3 \
  --name main \
  --query properties.error
```

### Issue: Web app shows "Application Error"

**Solution**: Check container logs
```bash
az webapp log tail --name $WEBAPP_NAME --resource-group rg-zavastore-dev-westus3
```

### Issue: ACR pull fails

**Solution**: Verify managed identity and role assignment
```bash
# Get web app principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name $WEBAPP_NAME \
  --resource-group rg-zavastore-dev-westus3 \
  --query principalId -o tsv)

# Check role assignments
az role assignment list \
  --assignee $PRINCIPAL_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-zavastore-dev-westus3
```

## Next Steps

- [ ] Configure custom domain
- [ ] Set up SSL certificate
- [ ] Configure Azure Front Door or CDN
- [ ] Set up staging slots
- [ ] Configure auto-scaling rules
- [ ] Set up alerts and notifications
- [ ] Implement backup strategy
- [ ] Configure Azure Key Vault for secrets
- [ ] Set up Azure AD authentication
- [ ] Implement disaster recovery plan

## Support

For issues or questions:
- Review [infra/README.md](./README.md)
- Check Azure Portal deployment logs
- Review Application Insights for errors
- Contact your Azure administrator
