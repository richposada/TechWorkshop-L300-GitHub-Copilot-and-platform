# ZavaStorefront Azure Infrastructure Deployment Checklist

Use this checklist to ensure a successful deployment of the ZavaStorefront application to Azure.

## Pre-Deployment Checklist

### Azure Prerequisites
- [ ] Azure subscription with required permissions
- [ ] Sufficient quota in westus3 region for:
  - [ ] App Service Plan (Basic tier)
  - [ ] Azure Container Registry
  - [ ] Azure AI Services (for GPT-4 and Phi models)
- [ ] Verified westus3 region supports required AI models

### Local Environment
- [ ] Azure CLI installed (version 2.50.0+)
- [ ] Azure Developer CLI (azd) installed
- [ ] Git installed and configured
- [ ] Access to GitHub repository
- [ ] Text editor or IDE installed

### Repository Setup
- [ ] Repository cloned locally
- [ ] On correct branch
- [ ] Latest changes pulled

## Deployment Checklist

### Step 1: Authentication
- [ ] Logged in to Azure CLI (`az login`)
- [ ] Correct subscription selected
- [ ] Logged in to Azure Developer CLI (`azd auth login`)
- [ ] Verified account permissions

### Step 2: Template Validation
- [ ] Run validation script: `./infra/scripts/validate.sh`
- [ ] All Bicep templates validated successfully
- [ ] No linting errors or warnings
- [ ] Parameters file reviewed and confirmed

### Step 3: Initial Deployment
- [ ] Initialize azd environment (`azd init`)
- [ ] Environment name configured (e.g., `dev`)
- [ ] Location set to `westus3`
- [ ] Run `azd provision`
- [ ] Infrastructure provisioned successfully
- [ ] All outputs displayed correctly

### Step 4: Application Deployment
- [ ] Docker image built successfully
- [ ] Image pushed to ACR
- [ ] Web App restarted
- [ ] Application accessible at provided URL

### Step 5: Configuration Verification
- [ ] Web App running and healthy
- [ ] ACR integration working (managed identity)
- [ ] Application Insights receiving telemetry
- [ ] AI Services deployed and accessible
- [ ] All role assignments configured correctly

## Post-Deployment Checklist

### Basic Functionality
- [ ] Application loads in browser
- [ ] HTTPS redirect working
- [ ] Static files serving correctly
- [ ] No console errors in browser

### Monitoring and Observability
- [ ] Application Insights dashboard accessible
- [ ] Live metrics showing data
- [ ] Application Map displaying components
- [ ] Log Analytics workspace receiving logs
- [ ] Custom queries working

### Security Configuration
- [ ] System-assigned managed identity enabled
- [ ] AcrPull role assigned to managed identity
- [ ] ACR admin user disabled
- [ ] HTTPS enforced on Web App
- [ ] No secrets in source code or outputs

### AI Services
- [ ] AI Services account created
- [ ] GPT-4 deployment successful
- [ ] Phi model deployment successful
- [ ] API endpoint accessible
- [ ] Authentication keys secured

### Documentation
- [ ] README.md updated with deployment info
- [ ] Environment variables documented
- [ ] Troubleshooting steps documented
- [ ] Team members informed of deployment

## CI/CD Setup Checklist (Optional)

### GitHub Actions Configuration
- [ ] Service principal created
- [ ] Federated credentials configured
- [ ] GitHub secrets added:
  - [ ] `AZURE_CLIENT_ID`
  - [ ] `AZURE_TENANT_ID`
  - [ ] `AZURE_SUBSCRIPTION_ID`
  - [ ] `ACR_NAME`
  - [ ] `WEBAPP_NAME`
  - [ ] `RESOURCE_GROUP_NAME`
- [ ] Workflow file reviewed
- [ ] Test workflow run successful

### Workflow Verification
- [ ] Code push triggers workflow
- [ ] Image builds successfully in cloud
- [ ] Image pushes to ACR
- [ ] Web App restarts automatically
- [ ] Application updates deployed

## Smoke Testing Checklist

### Application Testing
- [ ] Home page loads
- [ ] Product listing displays
- [ ] Shopping cart functions
- [ ] Session management works
- [ ] All routes accessible

### Performance Testing
- [ ] Response times acceptable (<3s)
- [ ] No memory leaks detected
- [ ] CPU usage within limits
- [ ] No bottlenecks identified

### Monitoring Testing
- [ ] Request telemetry captured
- [ ] Error tracking functional
- [ ] Dependencies tracked
- [ ] Custom events logged (if applicable)

## Cost Management Checklist

### Budget Setup
- [ ] Cost alerts configured
- [ ] Budget threshold set (e.g., $50/month)
- [ ] Notification email configured
- [ ] Cost analysis dashboard reviewed

### Cost Optimization
- [ ] Right-sized SKUs for development
- [ ] Auto-scaling disabled for dev (if applicable)
- [ ] Unused resources identified
- [ ] Scheduled shutdown configured (optional)

## Backup and Recovery Checklist

### Backup Configuration
- [ ] Resource group export template saved
- [ ] Parameter values documented
- [ ] ACR images tagged appropriately
- [ ] Critical configurations backed up

### Recovery Planning
- [ ] Rollback procedure documented
- [ ] Restore test performed (optional)
- [ ] Recovery time objective (RTO) defined
- [ ] Recovery point objective (RPO) defined

## Production Readiness Checklist

### High Availability
- [ ] Evaluate upgrade to Standard+ tier
- [ ] Consider multiple regions (future)
- [ ] Implement health checks
- [ ] Configure auto-healing rules

### Security Hardening
- [ ] Implement Azure Key Vault for secrets
- [ ] Configure VNet integration
- [ ] Enable Azure Defender
- [ ] Implement WAF (if using App Gateway)
- [ ] Enable audit logging

### Performance Optimization
- [ ] Configure CDN (if needed)
- [ ] Implement caching strategy
- [ ] Optimize container image size
- [ ] Configure connection pooling

### Compliance and Governance
- [ ] Apply required tags to all resources
- [ ] Implement Azure Policy
- [ ] Configure compliance reporting
- [ ] Document compliance status

## Troubleshooting Checklist

If deployment fails, check:

- [ ] Azure CLI version is current
- [ ] Correct subscription selected
- [ ] Sufficient permissions in subscription
- [ ] Quotas not exceeded in region
- [ ] No naming conflicts with existing resources
- [ ] Parameters file format correct
- [ ] Network connectivity to Azure
- [ ] No transient Azure service issues

## Cleanup Checklist

When decommissioning:

- [ ] Data backed up if needed
- [ ] Dependencies identified and handled
- [ ] Team notified of decommission
- [ ] Run cleanup script: `./infra/scripts/cleanup.sh`
- [ ] Verify resource group deleted
- [ ] Service principal removed (if created)
- [ ] GitHub secrets removed (if configured)
- [ ] Documentation updated

## Sign-Off

### Deployment Completed By
- Name: ___________________________
- Date: ___________________________
- Role: ___________________________

### Verified By
- Name: ___________________________
- Date: ___________________________
- Role: ___________________________

### Notes
```
[Space for deployment notes, issues encountered, or special configurations]







```

---

## Reference Information

**Resource Group**: rg-zavastore-dev-westus3  
**Location**: westus3  
**Environment**: dev  
**Estimated Monthly Cost**: $25-35

**Key Resources**:
- ACR: acrzavastoredevwestus3
- Web App: app-zavastore-dev-westus3
- App Insights: appi-zavastore-dev-westus3
- AI Services: ai-zavastore-dev-westus3

**Documentation**:
- [README](./README.md)
- [Deployment Guide](./DEPLOYMENT.md)
- [Quick Reference](./QUICK_REFERENCE.md)
