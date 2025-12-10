#!/bin/bash
# Cleanup script for ZavaStorefront Azure infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-zavastore-dev-westus3}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}ZavaStorefront Infrastructure Cleanup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check prerequisites
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo -e "${RED}Not logged in to Azure${NC}"
    exit 1
fi

# Display current subscription
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${YELLOW}Current subscription: ${SUBSCRIPTION_NAME}${NC}"
echo ""

# Check if resource group exists
if ! az group exists --name "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}Resource group $RESOURCE_GROUP does not exist${NC}"
    exit 0
fi

# List resources to be deleted
echo -e "${YELLOW}Resources in $RESOURCE_GROUP:${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --output table
echo ""

# Warning
echo -e "${RED}WARNING: This will delete ALL resources in the resource group!${NC}"
echo -e "${RED}This action cannot be undone.${NC}"
echo ""

# Ask for confirmation
read -p "Are you sure you want to delete resource group $RESOURCE_GROUP? (yes/no) " -r
echo
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo -e "${GREEN}Cleanup cancelled${NC}"
    exit 0
fi

# Double confirmation
read -p "Type the resource group name to confirm: " -r
echo
if [[ ! $REPLY == "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}Resource group name doesn't match. Cleanup cancelled${NC}"
    exit 1
fi

# Delete resource group
echo -e "${YELLOW}Deleting resource group $RESOURCE_GROUP...${NC}"
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Cleanup initiated successfully!${NC}"
echo -e "${GREEN}Deletion is running in the background.${NC}"
echo -e "${GREEN}Check Azure Portal for progress.${NC}"
echo -e "${GREEN}========================================${NC}"
