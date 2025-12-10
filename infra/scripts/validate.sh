#!/bin/bash
# Validation script for ZavaStorefront Bicep templates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Bicep Template Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    exit 1
fi

# Navigate to repository root
cd "$(dirname "$0")/../.."

# Validate main template
echo -e "${YELLOW}Validating main.bicep...${NC}"
if az bicep build --file infra/main.bicep --stdout > /dev/null 2>&1; then
    echo -e "${GREEN}✓ main.bicep is valid${NC}"
else
    echo -e "${RED}✗ main.bicep has errors${NC}"
    az bicep build --file infra/main.bicep
    exit 1
fi

# Validate individual modules
echo ""
echo -e "${YELLOW}Validating modules...${NC}"

MODULES=(
    "infra/modules/acr.bicep"
    "infra/modules/appServicePlan.bicep"
    "infra/modules/webApp.bicep"
    "infra/modules/appInsights.bicep"
    "infra/modules/logAnalytics.bicep"
    "infra/modules/roleAssignment.bicep"
    "infra/modules/aiFoundry.bicep"
)

for module in "${MODULES[@]}"; do
    if [ -f "$module" ]; then
        MODULE_NAME=$(basename "$module")
        if az bicep build --file "$module" --stdout > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $MODULE_NAME is valid${NC}"
        else
            echo -e "${RED}✗ $MODULE_NAME has errors${NC}"
            az bicep build --file "$module"
            exit 1
        fi
    else
        echo -e "${RED}✗ $module not found${NC}"
        exit 1
    fi
done

# Check for linting issues
echo ""
echo -e "${YELLOW}Running linter checks...${NC}"
az bicep build --file infra/main.bicep 2>&1 | grep -i "warning" && \
    echo -e "${YELLOW}⚠ Warnings found (see above)${NC}" || \
    echo -e "${GREEN}✓ No linting warnings${NC}"

# What-if analysis (if resource group exists)
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-zavastore-dev-westus3}"
if az group exists --name "$RESOURCE_GROUP" &> /dev/null; then
    echo ""
    echo -e "${YELLOW}Running what-if analysis...${NC}"
    
    if az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file infra/main.bicep \
        --parameters @infra/main.parameters.json \
        --no-pretty-print 2>&1 | head -30; then
        echo -e "${GREEN}✓ What-if analysis completed${NC}"
    else
        echo -e "${YELLOW}⚠ What-if analysis failed (resource group may not exist yet)${NC}"
    fi
else
    echo ""
    echo -e "${YELLOW}⚠ Resource group $RESOURCE_GROUP does not exist${NC}"
    echo -e "${YELLOW}  Skipping what-if analysis${NC}"
fi

# Check for common issues
echo ""
echo -e "${YELLOW}Checking for common issues...${NC}"

# Check if parameters file exists
if [ ! -f "infra/main.parameters.json" ]; then
    echo -e "${RED}✗ main.parameters.json not found${NC}"
    exit 1
else
    echo -e "${GREEN}✓ main.parameters.json exists${NC}"
fi

# Check if azure.yaml exists
if [ ! -f "azure.yaml" ]; then
    echo -e "${YELLOW}⚠ azure.yaml not found${NC}"
else
    echo -e "${GREEN}✓ azure.yaml exists${NC}"
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo -e "${RED}✗ Dockerfile not found${NC}"
else
    echo -e "${GREEN}✓ Dockerfile exists${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Validation completed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
