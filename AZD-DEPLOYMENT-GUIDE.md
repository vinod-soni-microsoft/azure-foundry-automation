# Azure Developer CLI (azd) Deployment Guide

## 🚀 Overview

This guide shows you how to deploy Azure AI Foundry infrastructure to **three separate subscriptions** for dev, staging, and production environments using **Azure Developer CLI (azd)**.

**Key Features:**
- ✅ **Interactive prompts** - azd asks for subscription and resource group at runtime
- ✅ **Multi-subscription support** - Deploy each environment to a different subscription
- ✅ **Environment isolation** - Each environment has its own configuration
- ✅ **Simplified workflow** - One command to deploy everything
- ✅ **Configuration persistence** - Settings saved per environment in `.azure/<env>/.env`

---

## 📋 Prerequisites

### 1. Install Azure Developer CLI

**Windows (PowerShell):**
```powershell
winget install microsoft.azd
```

**macOS:**
```bash
brew tap azure/azd && brew install azd
```

**Linux:**
```bash
curl -fsSL https://aka.ms/install-azd.sh | bash
```

**Verify Installation:**
```bash
azd version
```

### 2. Install Azure CLI

```bash
# Windows
winget install Microsoft.AzureCLI

# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 3. Login to Azure

```bash
# Login with your Azure account
az login

# List your subscriptions
az account list --output table
```

**Note the Subscription IDs for:**
- Dev environment
- Staging environment
- Production environment

---

## 🎯 Quick Start

### Deploy to Development Environment

```bash
# Initialize and select environment
azd init
azd env select dev

# Deploy (will prompt for subscription, location, resource group)
azd up
```

**During `azd up`, you'll be prompted for:**
1. **Azure Subscription** - Select or enter your Dev subscription ID
2. **Azure Location** - Choose a region (e.g., eastus, westus2)
3. **Resource Group** - Enter a name or let azd auto-generate

### Deploy to Staging Environment

```bash
# Switch to staging environment
azd env select stg

# Deploy to staging subscription
azd up
```

**You'll be prompted for staging-specific:**
1. **Azure Subscription** - Enter your Staging subscription ID (different from dev)
2. **Azure Location** - Choose a region
3. **Resource Group** - Enter staging resource group name

### Deploy to Production Environment

```bash
# Switch to production environment
azd env select prod

# Deploy to production subscription
azd up
```

**You'll be prompted for production-specific:**
1. **Azure Subscription** - Enter your Production subscription ID (different from dev/stg)
2. **Azure Location** - Choose a region
3. **Resource Group** - Enter production resource group name

---

## 📁 Configuration Files

### Environment Configuration (`.azure/<env>/.env`)

After the first deployment, azd saves your settings in `.azure/<env>/.env`:

**`.azure/dev/.env` Example:**
```bash
AZURE_ENV_NAME="dev"
AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_LOCATION="eastus"
AZURE_RESOURCE_GROUP="rg-dev-foundry"
```

**`.azure/stg/.env` Example:**
```bash
AZURE_ENV_NAME="stg"
AZURE_SUBSCRIPTION_ID="yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"  # Different subscription
AZURE_LOCATION="eastus"
AZURE_RESOURCE_GROUP="rg-stg-foundry"
```

**`.azure/prod/.env` Example:**
```bash
AZURE_ENV_NAME="prod"
AZURE_SUBSCRIPTION_ID="zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"  # Different subscription
AZURE_LOCATION="westus2"
AZURE_RESOURCE_GROUP="rg-prod-foundry"
```

### Project Configuration (`azure.yaml`)

The `azure.yaml` file defines:
- Infrastructure provider (Bicep)
- Deployment hooks (pre/post deployment messages)
- Environment settings

---

## 🔄 Common azd Commands

### Environment Management

```bash
# List all environments
azd env list

# Select an environment
azd env select <env-name>

# Create a new environment
azd env new <env-name>

# View current environment variables
azd env get-values

# Set a specific value
azd env set AZURE_LOCATION eastus2

# Refresh environment from .env file
azd env refresh
```

### Deployment Commands

```bash
# Full deployment (provision + deploy)
azd up

# Provision infrastructure only
azd provision

# Show what will be deployed (What-If)
azd provision --preview

# Deploy without prompting
azd up --no-prompt

# Deploy to specific subscription
azd up --subscription <subscription-id>
```

### Monitoring & Management

```bash
# Show deployed resources
azd show

# Monitor deployment logs
azd monitor

# Open Azure Portal for current environment
azd show --output portal

# Clean up all resources
azd down
```

---

## 🎭 Multi-Environment Workflow

### Scenario 1: First-Time Deployment to All Environments

```bash
# Step 1: Deploy to Dev
azd env select dev
azd up
# Enter Dev subscription ID when prompted
# Enter Dev resource group name: rg-dev-foundry

# Step 2: Deploy to Staging
azd env select stg
azd up
# Enter Staging subscription ID when prompted
# Enter Staging resource group name: rg-stg-foundry

# Step 3: Deploy to Production
azd env select prod
azd up
# Enter Production subscription ID when prompted
# Enter Production resource group name: rg-prod-foundry
```

### Scenario 2: Update Existing Deployment

```bash
# Modify infrastructure (e.g., update main.bicep or parameters)

# Update dev environment
azd env select dev
azd provision --preview  # Preview changes
azd up                   # Apply changes

# Update staging (after dev validation)
azd env select stg
azd up

# Update production (after staging validation)
azd env select prod
azd up
```

### Scenario 3: Deploy from Scratch with Pre-configured Settings

**Option A: Set environment variables before deployment**

```bash
# Configure dev environment
azd env select dev
azd env set AZURE_SUBSCRIPTION_ID "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azd env set AZURE_LOCATION "eastus"
azd env set AZURE_RESOURCE_GROUP "rg-dev-foundry"

# Deploy without prompts
azd up --no-prompt
```

**Option B: Edit `.azure/dev/.env` directly**

```bash
# Edit the file
code .azure/dev/.env

# Add your values
AZURE_ENV_NAME="dev"
AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_LOCATION="eastus"
AZURE_RESOURCE_GROUP="rg-dev-foundry"

# Deploy
azd env select dev
azd up --no-prompt
```

---

## 🔍 What Happens During Deployment

### 1. Pre-provision Hook
- Displays banner message
- Shows deployment information

### 2. Provision Phase
- Compiles Bicep templates
- Validates parameters
- Creates/updates Azure resources:
  - Resource Group
  - AI Foundry Hub
  - AI Services (with OpenAI models)
  - Key Vault
  - Storage Account
  - Application Insights
  - RBAC role assignments

### 3. Post-provision Hook
- Shows deployment summary
- Displays resource information

---

## 📊 Deployment Architecture

```
Dev Subscription (Sub-1)
├── azd env: dev
├── .azure/dev/.env (stores Sub-1 ID)
└── Deploys to: rg-dev-foundry
    ├── AI Foundry Hub (dev-aif-foundry-hub)
    ├── AI Services (dev-aiservices)
    ├── Key Vault (dev-kv-foundry)
    ├── Storage (devstfoundry)
    └── App Insights (dev-appinsights)

Staging Subscription (Sub-2)
├── azd env: stg
├── .azure/stg/.env (stores Sub-2 ID)
└── Deploys to: rg-stg-foundry
    └── [Same resources with stg- prefix]

Production Subscription (Sub-3)
├── azd env: prod
├── .azure/prod/.env (stores Sub-3 ID)
└── Deploys to: rg-prod-foundry
    └── [Same resources with prod- prefix]
```

---

## 🔐 Authentication

### Interactive Login (Default)

```bash
# Login to Azure
az login

# azd will use your Azure CLI credentials
azd up
```

### Service Principal (CI/CD)

```bash
# Set service principal credentials
azd auth login \
  --client-id <client-id> \
  --client-secret <client-secret> \
  --tenant-id <tenant-id>

# Deploy
azd up
```

### Managed Identity (Azure VMs)

```bash
# azd automatically uses managed identity when running on Azure VMs
azd up
```

---

## 🧪 Validation and Testing

### Preview Changes Before Deployment

```bash
# What-If analysis
azd provision --preview

# This will show:
# - Resources to be created
# - Resources to be modified
# - Resources to be deleted
```

### Validate Bicep Templates

```bash
# Validate templates without deploying
az deployment sub validate \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/dev.main.bicepparam
```

### Test Deployment to Dev First

```bash
# Always test in dev before promoting
azd env select dev
azd up

# Validate resources in Azure Portal
azd show --output portal

# If successful, deploy to staging
azd env select stg
azd up
```

---

## 🗑️ Cleanup

### Delete Single Environment

```bash
# Select environment to delete
azd env select dev

# Delete all resources
azd down

# Confirm deletion
# This will:
# 1. Delete all Azure resources in the resource group
# 2. Delete the resource group
# 3. Keep the .azure/dev/.env for future deployments
```

### Delete All Environments

```bash
# Delete dev
azd env select dev
azd down

# Delete staging
azd env select stg
azd down

# Delete production
azd env select prod
azd down
```

### Remove Environment Configuration

```bash
# Delete environment configuration (not Azure resources)
azd env delete dev

# This removes .azure/dev/ directory
# Does NOT delete Azure resources (use azd down first)
```

---

## 🆘 Troubleshooting

### Issue: "Subscription not found"

**Cause:** Not logged in or subscription ID incorrect

**Fix:**
```bash
# Login
az login

# List subscriptions
az account list --output table

# Set correct subscription
azd env set AZURE_SUBSCRIPTION_ID "<correct-subscription-id>"
```

### Issue: "Authorization failed"

**Cause:** Insufficient permissions in subscription

**Fix:**
- Ensure you have **Contributor** + **User Access Administrator** roles
- Contact subscription administrator to grant permissions

### Issue: "Resource group already exists"

**Cause:** Resource group from previous deployment exists

**Fix:**
```bash
# Option 1: Use existing resource group
azd up  # azd will update existing resources

# Option 2: Use different resource group
azd env set AZURE_RESOURCE_GROUP "rg-dev-foundry-new"
azd up

# Option 3: Delete existing and recreate
az group delete --name rg-dev-foundry --yes
azd up
```

### Issue: "Parameter file not found"

**Cause:** Environment-specific parameter file missing

**Fix:**
```bash
# Ensure parameter files exist for each environment:
# - infra/dev.main.bicepparam
# - infra/stg.main.bicepparam
# - infra/prod.main.bicepparam

# Verify files
ls infra/*.bicepparam
```

### Issue: Environment confusion

**Cause:** Not sure which environment is active

**Fix:**
```bash
# Check current environment
azd env list

# Current environment is marked with * (asterisk)
# Switch if needed
azd env select <correct-env>

# Verify settings
azd env get-values
```

---

## 🔄 Integration with GitHub Actions

You can use **both** azd and GitHub Actions:

- **azd**: For local/manual deployments with interactive prompts
- **GitHub Actions**: For automated CI/CD with OIDC authentication

Both methods use the same Bicep templates and parameter files.

**When to use azd:**
- Local development and testing
- Quick deployments to dev
- Ad-hoc production deployments
- When you need interactive subscription selection

**When to use GitHub Actions:**
- Automated deployments on git push
- PR validation with What-If
- Production deployments with approval gates
- When you want GitOps workflow

---

## 📚 Additional Resources

### Azure Developer CLI Documentation
- [azd Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [azd Commands Reference](https://learn.microsoft.com/azure/developer/azure-developer-cli/reference)
- [Environment Variables](https://learn.microsoft.com/azure/developer/azure-developer-cli/manage-environment-variables)

### Bicep Documentation
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Parameters](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameters)

### Azure AI Foundry
- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)

---

## ✅ Summary

**Deploy to Dev:**
```bash
azd env select dev
azd up  # Enter Dev subscription ID when prompted
```

**Deploy to Staging:**
```bash
azd env select stg
azd up  # Enter Staging subscription ID when prompted
```

**Deploy to Production:**
```bash
azd env select prod
azd up  # Enter Production subscription ID when prompted
```

**Each environment:**
- ✅ Prompts for subscription at runtime
- ✅ Saves configuration in `.azure/<env>/.env`
- ✅ Deploys to separate subscription
- ✅ Complete resource isolation

🎉 **You now have a complete multi-subscription deployment solution with azd!**
