#!/bin/bash
# Deployment script for ZavaStorefront Azure infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-zavastore-dev-westus3}"
LOCATION="${LOCATION:-westus3}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}ZavaStorefront Infrastructure Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

if ! command -v azd &> /dev/null; then
    echo -e "${YELLOW}Warning: Azure Developer CLI (azd) is not installed${NC}"
    echo -e "${YELLOW}Falling back to Azure CLI deployment${NC}"
    USE_AZD=false
else
    USE_AZD=true
fi

# Check if logged in
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}Not logged in to Azure. Logging in...${NC}"
    az login
fi

# Display current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}Current subscription: ${SUBSCRIPTION_NAME}${NC}"
echo ""

# Ask for confirmation
read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

# Deployment
if [ "$USE_AZD" = true ]; then
    echo -e "${GREEN}Deploying using Azure Developer CLI...${NC}"
    
    # Check if already initialized
    if [ ! -f ".azure/$ENVIRONMENT/.env" ]; then
        echo -e "${YELLOW}Initializing azd environment...${NC}"
        azd init
    fi
    
    echo -e "${GREEN}Provisioning infrastructure...${NC}"
    azd provision
    
    echo -e "${GREEN}Deploying application...${NC}"
    azd deploy
    
else
    echo -e "${GREEN}Deploying using Azure CLI...${NC}"
    
    # Create resource group
    echo -e "${YELLOW}Creating resource group...${NC}"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    
    # Deploy Bicep template
    echo -e "${YELLOW}Deploying Bicep template...${NC}"
    DEPLOYMENT_OUTPUT=$(az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --template-file infra/main.bicep \
        --parameters infra/main.parameters.json \
        --query properties.outputs \
        --output json)
    
    # Extract outputs
    ACR_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.acrName.value')
    WEBAPP_NAME=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppName.value')
    WEBAPP_URL=$(echo $DEPLOYMENT_OUTPUT | jq -r '.webAppUrl.value')
    
    # Build and push Docker image
    echo -e "${YELLOW}Building and pushing Docker image...${NC}"
    az acr build \
        --registry "$ACR_NAME" \
        --image zavastorefrontapp:latest \
        --file ./Dockerfile \
        ./src
    
    # Restart web app
    echo -e "${YELLOW}Restarting web app...${NC}"
    az webapp restart --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP"
    
    echo -e "${GREEN}Application URL: ${WEBAPP_URL}${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
