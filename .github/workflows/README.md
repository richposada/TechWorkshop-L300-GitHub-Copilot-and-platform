# GitHub Actions Deployment Setup

This guide explains how to configure GitHub for automated deployment of the ZavaStorefront application to Azure App Service.

## Prerequisites

- Azure infrastructure already deployed (via `azd up` or manual deployment)
- GitHub repository with the application code
- Azure CLI installed locally (for initial setup)

## Configuration Steps

### 1. Create Azure Service Principal

Run this command in your terminal (replace `<subscription-id>` and `<resource-group-name>` with your values):

```bash
az ad sp create-for-rbac --name "github-actions-zavasf" \
  --role contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group-name> \
  --json-auth
```

**Example:**
```bash
az ad sp create-for-rbac --name "github-actions-zavasf" \
  --role contributor \
  --scopes /subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/rg-zavasf-dev \
  --json-auth
```

Copy the entire JSON output. It will look like:
```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

### 2. Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Add Secret:

1. Click **"New repository secret"**
2. Name: `AZURE_CREDENTIALS`
3. Value: Paste the entire JSON output from step 1
4. Click **"Add secret"**

### 3. Configure GitHub Variables

In the same location (**Settings** → **Secrets and variables** → **Actions** → **Variables** tab):

#### Add Variables:

1. **AZURE_CONTAINER_REGISTRY_NAME**
   - Click **"New repository variable"**
   - Name: `AZURE_CONTAINER_REGISTRY_NAME`
   - Value: Your ACR name (e.g., `azacr1a2b3c4d5e6f`)
   - Click **"Add variable"**

2. **AZURE_APP_SERVICE_NAME**
   - Click **"New repository variable"**
   - Name: `AZURE_APP_SERVICE_NAME`
   - Value: Your App Service name (e.g., `azapp1a2b3c4d5e6f`)
   - Click **"Add variable"**

### 4. Find Your Resource Names

If you deployed with `azd up`, get the resource names with:

```bash
azd env get-values
```

Or find them in the Azure Portal:
- **Container Registry**: Navigate to your resource group → Copy the ACR name
- **App Service**: Navigate to your resource group → Copy the App Service name

## Workflow Behavior

The GitHub Actions workflow (`.github/workflows/deploy.yml`) will:

1. **Trigger on:**
   - Push to `main` branch
   - Manual trigger via "Actions" tab

2. **Build and Deploy:**
   - Build .NET 8.0 application
   - Create Docker container image
   - Push image to Azure Container Registry
   - Deploy to Azure App Service

## Manual Deployment Trigger

To manually trigger a deployment:

1. Go to your GitHub repository
2. Click **"Actions"** tab
3. Select **"Build and Deploy to Azure App Service"**
4. Click **"Run workflow"**
5. Select branch and click **"Run workflow"**

## Verify Deployment

After the workflow completes:

1. Check the **Actions** tab for workflow status (green checkmark = success)
2. Visit your App Service URL: `https://<your-app-service-name>.azurewebsites.net`
3. View logs in Azure Portal → App Service → Log stream

## Troubleshooting

**If deployment fails:**

1. **Check Service Principal Permissions:**
   - Ensure the service principal has `Contributor` role on the resource group
   - Verify the JSON in `AZURE_CREDENTIALS` is complete and valid

2. **Check Resource Names:**
   - Verify `AZURE_CONTAINER_REGISTRY_NAME` matches your ACR name exactly
   - Verify `AZURE_APP_SERVICE_NAME` matches your App Service name exactly
   - No `.azurecr.io` suffix needed in the registry name variable

3. **Check Docker Build:**
   - Ensure `src/Dockerfile` exists and is valid
   - Verify the .NET version matches your project (currently 8.0)

4. **View Detailed Logs:**
   - Click on the failed workflow run in GitHub Actions
   - Expand each step to see detailed error messages

## Security Notes

- The `AZURE_CREDENTIALS` secret contains sensitive authentication information - never commit it to your repository
- Service principal has contributor access only to the specified resource group
- Container Registry uses Azure RBAC authentication (no admin passwords)
- GitHub automatically masks secrets in workflow logs

## Cost Considerations

This workflow builds containers on GitHub-hosted runners (free for public repos, included minutes for private repos). Alternatively, you can use ACR Tasks to build in Azure by modifying the workflow to use `az acr build` command.
