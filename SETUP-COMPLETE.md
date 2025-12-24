# 🎉 Azure AI Foundry - Multi-Subscription Deployment Setup Complete!

## ✅ What's Been Configured

Your solution now supports **interactive multi-subscription deployments** using Azure Developer CLI (azd).

### 📦 Files Added

1. **`azure.yaml`** - azd project configuration
   - Defines infrastructure provider (Bicep)
   - Configures deployment hooks
   - Sets up multi-environment support

2. **`.azure/dev/.env`** - Dev environment configuration
3. **`.azure/stg/.env`** - Staging environment configuration
4. **`.azure/prod/.env`** - Production environment configuration
5. **`.azure/config.json`** - azd global settings (default env: dev)

6. **`AZD-DEPLOYMENT-GUIDE.md`** - Complete deployment documentation
   - Installation instructions
   - Step-by-step deployment guide
   - Multi-subscription workflow examples
   - Troubleshooting guide

7. **`AZD-QUICK-REFERENCE.md`** - Command quick reference
   - Common azd commands
   - Quick deployment scenarios
   - Configuration examples

8. **`.gitignore`** - Updated to track `.env` files but ignore azd artifacts

---

## 🚀 How to Deploy

### Interactive Deployment (Prompts for Subscription)

```powershell
# 1. Login to Azure
az login

# 2. Deploy to Development
azd env select dev
azd up

# When prompted, enter:
# - Dev Subscription ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# - Azure Location: eastus
# - Resource Group: rg-dev-foundry

# 3. Deploy to Staging (Different Subscription)
azd env select stg
azd up

# When prompted, enter:
# - Staging Subscription ID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
# - Azure Location: eastus
# - Resource Group: rg-stg-foundry

# 4. Deploy to Production (Different Subscription)
azd env select prod
azd up

# When prompted, enter:
# - Production Subscription ID: zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
# - Azure Location: westus2
# - Resource Group: rg-prod-foundry
```

### Pre-configured Deployment (No Prompts)

```powershell
# Configure dev environment
azd env select dev
azd env set AZURE_SUBSCRIPTION_ID "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azd env set AZURE_LOCATION "eastus"
azd env set AZURE_RESOURCE_GROUP "rg-dev-foundry"

# Deploy without prompts
azd up --no-prompt

# Repeat for stg and prod with different subscription IDs
```

---

## 🏗️ Architecture

Each `azd up` deploys to a **separate Azure subscription**:

```
Dev Subscription (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
└── rg-dev-foundry
    ├── AI Foundry Hub (dev-aif-foundry-hub)
    ├── AI Services (dev-aiservices)
    │   ├── GPT-4o deployment
    │   └── text-embedding-ada-002 deployment
    ├── Key Vault (dev-kv-foundry)
    ├── Storage Account (devstfoundry)
    │   ├── data container
    │   ├── models container
    │   └── artifacts container
    └── Application Insights (dev-appinsights)

Staging Subscription (yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy)
└── rg-stg-foundry
    └── [Same resources with stg- prefix]

Production Subscription (zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz)
└── rg-prod-foundry
    └── [Same resources with prod- prefix]
```

**Complete isolation at both subscription AND resource group levels!**

---

## 📊 What azd Does

### During `azd up`:

1. **Prompts for Configuration** (if not set)
   - Azure Subscription ID
   - Azure Location
   - Resource Group Name

2. **Saves Configuration** to `.azure/<env>/.env`
   - Settings persist for future deployments
   - No need to re-enter on subsequent runs

3. **Provisions Infrastructure**
   - Compiles Bicep templates
   - Creates resource group (if doesn't exist)
   - Deploys all Azure resources
   - Configures RBAC role assignments

4. **Shows Deployment Summary**
   - Environment name
   - Subscription ID
   - Resource group
   - Location

---

## 🎯 Key Features

### ✅ Interactive Subscription Selection
- Prompts for subscription ID at runtime
- No hardcoded subscription IDs in code
- Each environment can use different subscription

### ✅ Configuration Persistence
- First deployment saves settings to `.azure/<env>/.env`
- Subsequent deployments use saved settings (unless you want to change them)
- Easy to switch between environments

### ✅ Multi-Environment Support
```powershell
azd env list
# NAME      DEFAULT   LOCAL     REMOTE
# dev       true      true      false
# prod      false     true      false
# stg       false     true      false
```

### ✅ Easy Environment Switching
```powershell
azd env select dev    # Switch to dev
azd env select stg    # Switch to staging
azd env select prod   # Switch to production
```

---

## 🔄 Deployment Options

You now have **TWO** deployment methods:

### Option 1: Azure Developer CLI (azd) ⭐ NEW!

**Use for:**
- Local development and testing
- Quick deployments to any environment
- Interactive subscription selection
- Manual production deployments

**Commands:**
```powershell
azd env select <env>
azd up
```

### Option 2: GitHub Actions

**Use for:**
- Automated CI/CD pipeline
- PR validation with What-If
- Sequential deployments (dev → stg → prod)
- Approval gates for production

**Trigger:**
- Push to main → Automated deployment
- Pull request → What-If analysis

---

## 📋 Next Steps

### 1. Prepare Subscription Information

Get your Azure subscription IDs:
```powershell
az login
az account list --output table
```

Note down:
- Dev Subscription ID
- Staging Subscription ID (if different)
- Production Subscription ID (if different)

### 2. Review Parameter Files

Verify these files have correct values for your organization:
- `infra/dev.main.bicepparam`
- `infra/stg.main.bicepparam`
- `infra/prod.main.bicepparam`

### 3. Deploy to Development

```powershell
# Ensure you're logged in
az login

# Deploy
azd env select dev
azd up

# Enter your Dev subscription ID when prompted
```

### 4. Verify Deployment

```powershell
# Show deployed resources
azd show

# Open Azure Portal
azd show --output portal

# Check environment variables
azd env get-values
```

### 5. Deploy to Other Environments

```powershell
# Staging
azd env select stg
azd up  # Enter Staging subscription ID

# Production
azd env select prod
azd up  # Enter Production subscription ID
```

---

## 📚 Documentation

- **[AZD-DEPLOYMENT-GUIDE.md](AZD-DEPLOYMENT-GUIDE.md)** - Complete deployment guide with:
  - Installation instructions
  - Step-by-step walkthrough
  - Multi-subscription workflow examples
  - Authentication methods
  - Troubleshooting guide
  - Cleanup instructions

- **[AZD-QUICK-REFERENCE.md](AZD-QUICK-REFERENCE.md)** - Quick command reference:
  - Common azd commands
  - Multi-subscription workflows
  - Configuration examples
  - Troubleshooting tips

- **[MULTI-SUBSCRIPTION-SETUP.md](MULTI-SUBSCRIPTION-SETUP.md)** - GitHub Actions setup:
  - OIDC authentication configuration
  - GitHub environment secrets
  - CI/CD pipeline explanation

---

## 🆘 Quick Troubleshooting

### Issue: azd not installed
```powershell
# Install azd
winget install microsoft.azd

# Verify
azd version
```

### Issue: "Subscription not found"
```powershell
# Login again
az login

# List subscriptions
az account list --output table

# Set correct subscription
azd env set AZURE_SUBSCRIPTION_ID "<subscription-id>"
```

### Issue: Need to change subscription for environment
```powershell
azd env select dev
azd env set AZURE_SUBSCRIPTION_ID "<new-subscription-id>"
azd up
```

### Issue: Want to see what will be deployed
```powershell
azd provision --preview
```

---

## ✨ Example Workflow

### First-Time Deployment to All Environments

```powershell
# Login to Azure
az login

# Deploy to Dev (Subscription A)
azd env select dev
azd up
# Enter: Subscription A ID, eastus, rg-dev-foundry
# ✅ Dev deployed to Subscription A

# Deploy to Staging (Subscription B)
azd env select stg
azd up
# Enter: Subscription B ID, eastus, rg-stg-foundry
# ✅ Staging deployed to Subscription B

# Deploy to Production (Subscription C)
azd env select prod
azd up
# Enter: Subscription C ID, westus2, rg-prod-foundry
# ✅ Production deployed to Subscription C
```

### Update Existing Infrastructure

```powershell
# Make changes to Bicep files (e.g., add new project)

# Preview changes in dev
azd env select dev
azd provision --preview

# Apply changes to dev
azd up

# If successful, promote to staging
azd env select stg
azd up

# If successful, promote to production
azd env select prod
azd up
```

---

## 🎉 Summary

Your Azure AI Foundry solution now supports:

✅ **Multi-subscription deployment** - Each environment in separate subscription
✅ **Interactive prompts** - azd asks for subscription/RG at runtime
✅ **Configuration persistence** - Settings saved in `.azure/<env>/.env`
✅ **Easy environment switching** - `azd env select <env>`
✅ **Preview changes** - `azd provision --preview` before deployment
✅ **Dual deployment methods** - Choose azd (local) or GitHub Actions (CI/CD)
✅ **Complete documentation** - Comprehensive guides and quick references

**Ready to deploy!** 🚀

```powershell
azd env select dev
azd up
```
