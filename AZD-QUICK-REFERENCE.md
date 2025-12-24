# Azure Developer CLI (azd) - Quick Reference

## 🚀 Quick Deploy

```bash
# Install azd
winget install microsoft.azd

# Login to Azure
az login

# Deploy to dev
azd env select dev
azd up

# Deploy to staging
azd env select stg
azd up

# Deploy to production
azd env select prod
azd up
```

Each `azd up` will prompt you for:
1. **Subscription ID** (different for each environment)
2. **Location** (e.g., eastus, westus2)
3. **Resource Group** (e.g., rg-dev-foundry)

---

## 📋 Common Commands

### Environment Management
```bash
azd env list                  # List all environments
azd env select <env>          # Switch to environment (dev/stg/prod)
azd env new <env>             # Create new environment
azd env get-values            # Show current environment variables
azd env set KEY value         # Set environment variable
azd env delete <env>          # Delete environment config
```

### Deployment
```bash
azd up                        # Full deployment (provision + deploy)
azd provision                 # Provision infrastructure only
azd provision --preview       # Show what-if analysis
azd up --no-prompt            # Deploy without prompting
azd down                      # Delete all resources
```

### Monitoring
```bash
azd show                      # Show deployed resources
azd monitor                   # Monitor deployment logs
azd show --output portal      # Open Azure Portal
```

---

## 🎯 Multi-Subscription Workflow

### Scenario 1: First-Time Deployment

```bash
# Dev
azd env select dev
azd up
# Enter: Dev subscription ID, eastus, rg-dev-foundry

# Staging
azd env select stg
azd up
# Enter: Staging subscription ID, eastus, rg-stg-foundry

# Production
azd env select prod
azd up
# Enter: Production subscription ID, westus2, rg-prod-foundry
```

### Scenario 2: Update Existing Infrastructure

```bash
# Make changes to Bicep files

# Preview changes
azd env select dev
azd provision --preview

# Apply changes
azd up

# Repeat for stg and prod
```

### Scenario 3: Pre-configure and Deploy

```bash
# Configure dev
azd env select dev
azd env set AZURE_SUBSCRIPTION_ID "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
azd env set AZURE_LOCATION "eastus"
azd env set AZURE_RESOURCE_GROUP "rg-dev-foundry"

# Deploy without prompts
azd up --no-prompt
```

---

## 📁 Configuration Files

After first deployment, settings are saved in:

```
.azure/
├── config.json           # Default environment
├── dev/.env              # Dev subscription & settings
├── stg/.env              # Staging subscription & settings
└── prod/.env             # Production subscription & settings
```

**Example `.azure/dev/.env`:**
```bash
AZURE_ENV_NAME="dev"
AZURE_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
AZURE_LOCATION="eastus"
AZURE_RESOURCE_GROUP="rg-dev-foundry"
```

---

## 🔍 What Gets Deployed

Each `azd up` creates:

✅ **Resource Group** (auto-created or specified)
✅ **AI Foundry Hub** with managed identity
✅ **AI Services** with OpenAI models (GPT-4o, embeddings)
✅ **Key Vault** with RBAC and purge protection
✅ **Storage Account** with blob containers
✅ **Application Insights** for monitoring
✅ **RBAC Role Assignments** for managed identities

---

## 🆘 Troubleshooting

### "Subscription not found"
```bash
az login                      # Re-login
az account list --output table # Verify subscriptions
azd env set AZURE_SUBSCRIPTION_ID "<correct-id>"
```

### "Authorization failed"
- Ensure you have **Contributor** + **User Access Administrator** roles
- Contact subscription admin for permissions

### "Resource already exists"
```bash
azd up                        # azd will update existing resources
# OR
az group delete --name rg-dev-foundry --yes
azd up                        # Fresh deployment
```

### Check current environment
```bash
azd env list                  # Shows current environment with *
azd env get-values            # Shows all variables
```

---

## 🔄 Comparison: azd vs GitHub Actions

| Feature | azd (Local) | GitHub Actions |
|---------|-------------|----------------|
| **Deployment trigger** | Manual command | Git push |
| **Subscription selection** | Interactive prompt | Environment secrets |
| **Best for** | Dev/testing | CI/CD automation |
| **Approval gates** | Manual | Configured |
| **What-If** | `--preview` flag | Automatic on PR |
| **Multi-environment** | Switch with `env select` | Sequential pipeline |

**Use both!**
- azd for local dev/testing
- GitHub Actions for production automation

---

## 📚 Resources

- **[Complete azd Deployment Guide](AZD-DEPLOYMENT-GUIDE.md)** - Full documentation with examples
- **[azd Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)** - Official Microsoft docs
- **[azd Commands Reference](https://learn.microsoft.com/azure/developer/azure-developer-cli/reference)** - All commands

---

## ✅ Quick Checklist

Before deploying:
- [ ] Azure CLI installed (`az --version`)
- [ ] azd installed (`azd version`)
- [ ] Logged into Azure (`az login`)
- [ ] Subscription IDs ready for each environment
- [ ] Parameter files configured (`infra/*.bicepparam`)

Deploy:
- [ ] `azd env select dev` → `azd up` (enter dev subscription)
- [ ] `azd env select stg` → `azd up` (enter stg subscription)
- [ ] `azd env select prod` → `azd up` (enter prod subscription)

Verify:
- [ ] Check Azure Portal for resources
- [ ] Verify each subscription has correct resources
- [ ] Test AI Foundry Hub and projects

🎉 **Done!** Your multi-subscription Azure AI Foundry is deployed!
