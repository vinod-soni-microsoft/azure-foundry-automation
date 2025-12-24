# Multi-Subscription Deployment Setup Guide

## Overview

The solution is now configured to support **separate Azure subscriptions per environment**, providing complete isolation at both the subscription and resource group levels.

---

## 🏗️ Architecture

### Current Multi-Subscription Setup

```
Dev Subscription (Sub-1)
└── dev-aif-foundry-rg
    └── All Dev Resources (Hub, Projects, AI Services, KV, Storage)

Staging Subscription (Sub-2)
└── stg-aif-foundry-rg
    └── All Staging Resources (Hub, Projects, AI Services, KV, Storage)

Production Subscription (Sub-3)
└── prod-aif-foundry-rg
    └── All Production Resources (Hub, Projects, AI Services, KV, Storage)
```

**Complete Isolation:**
- ✅ Subscription-level isolation
- ✅ Resource group-level isolation
- ✅ Separate billing per environment
- ✅ Independent RBAC and policies

---

## 🔧 Configuration Steps

### Step 1: Create or Identify Azure Subscriptions

You need **three separate Azure subscriptions**:

```bash
# List your subscriptions
az account list --output table

# Note down the Subscription IDs:
# - Dev Subscription ID:     xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# - Staging Subscription ID: yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy
# - Prod Subscription ID:    zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz
```

---

### Step 2: Set Up OIDC for Each Subscription

You need to create **one Azure AD App Registration per subscription** (or reuse one if you prefer shared identity).

#### Option A: Single App Registration (Shared Identity)

**Create one app registration with access to all three subscriptions:**

```bash
# Create App Registration
az ad app create --display-name "GitHub-OIDC-AzureFoundry-MultiSub"

# Get Application (Client) ID
appId=$(az ad app list --display-name "GitHub-OIDC-AzureFoundry-MultiSub" --query "[0].appId" -o tsv)
echo "Client ID: $appId"

# Create Service Principal
az ad sp create --id $appId

# Assign roles to Dev Subscription
az role assignment create \
  --assignee $appId \
  --role "Contributor" \
  --scope "/subscriptions/<DEV-SUBSCRIPTION-ID>"

az role assignment create \
  --assignee $appId \
  --role "User Access Administrator" \
  --scope "/subscriptions/<DEV-SUBSCRIPTION-ID>"

# Assign roles to Staging Subscription
az role assignment create \
  --assignee $appId \
  --role "Contributor" \
  --scope "/subscriptions/<STAGING-SUBSCRIPTION-ID>"

az role assignment create \
  --assignee $appId \
  --role "User Access Administrator" \
  --scope "/subscriptions/<STAGING-SUBSCRIPTION-ID>"

# Assign roles to Production Subscription
az role assignment create \
  --assignee $appId \
  --role "Contributor" \
  --scope "/subscriptions/<PROD-SUBSCRIPTION-ID>"

az role assignment create \
  --assignee $appId \
  --role "User Access Administrator" \
  --scope "/subscriptions/<PROD-SUBSCRIPTION-ID>"
```

#### Option B: Separate App Registrations (Recommended for Production)

Create separate app registrations for better security isolation:

```bash
# Dev App
az ad app create --display-name "GitHub-OIDC-Foundry-Dev"
devAppId=$(az ad app list --display-name "GitHub-OIDC-Foundry-Dev" --query "[0].appId" -o tsv)

# Staging App
az ad app create --display-name "GitHub-OIDC-Foundry-Stg"
stgAppId=$(az ad app list --display-name "GitHub-OIDC-Foundry-Stg" --query "[0].appId" -o tsv)

# Production App
az ad app create --display-name "GitHub-OIDC-Foundry-Prod"
prodAppId=$(az ad app list --display-name "GitHub-OIDC-Foundry-Prod" --query "[0].appId" -o tsv)

# Then assign roles for each (similar to Option A but per app)
```

---

### Step 3: Configure Federated Credentials (OIDC)

For **each environment**, add federated credentials:

```bash
# Get the Object ID of your app
objectId=$(az ad app list --display-name "GitHub-OIDC-AzureFoundry-MultiSub" --query "[0].id" -o tsv)

# Create federated credential for Dev environment
az ad app federated-credential create \
  --id $objectId \
  --parameters '{
    "name": "GitHub-Foundry-Dev",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR-GITHUB-ORG>/<YOUR-REPO>:environment:dev",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for Staging environment
az ad app federated-credential create \
  --id $objectId \
  --parameters '{
    "name": "GitHub-Foundry-Stg",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR-GITHUB-ORG>/<YOUR-REPO>:environment:stg",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Create federated credential for Production environment
az ad app federated-credential create \
  --id $objectId \
  --parameters '{
    "name": "GitHub-Foundry-Prod",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR-GITHUB-ORG>/<YOUR-REPO>:environment:prod",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Replace:**
- `<YOUR-GITHUB-ORG>` with your GitHub organization name
- `<YOUR-REPO>` with your repository name

---

### Step 4: Configure GitHub Environments and Secrets

#### 4.1 Create GitHub Environments

Go to: **Repository → Settings → Environments**

Create three environments:
- `dev`
- `stg`
- `prod`

#### 4.2 Configure Environment Secrets

For **each environment**, add these secrets:

**Dev Environment Secrets:**
```
Name: AZURE_CLIENT_ID
Value: <app-id-from-step-2>

Name: AZURE_TENANT_ID
Value: <your-tenant-id>

Name: AZURE_SUBSCRIPTION_ID
Value: <dev-subscription-id>
```

**Staging Environment Secrets:**
```
Name: AZURE_CLIENT_ID
Value: <app-id-from-step-2>  (same or different based on Option A/B)

Name: AZURE_TENANT_ID
Value: <your-tenant-id>

Name: AZURE_SUBSCRIPTION_ID
Value: <staging-subscription-id>  ⚠️ DIFFERENT from Dev
```

**Production Environment Secrets:**
```
Name: AZURE_CLIENT_ID
Value: <app-id-from-step-2>  (same or different based on Option A/B)

Name: AZURE_TENANT_ID
Value: <your-tenant-id>

Name: AZURE_SUBSCRIPTION_ID
Value: <prod-subscription-id>  ⚠️ DIFFERENT from Dev & Staging
```

#### 4.3 Add Environment Protection Rules

For **Staging** and **Production** environments:

1. Go to environment settings
2. Enable **"Required reviewers"**
3. Add reviewers who must approve deployments
4. Optional: Add **"Wait timer"** for additional safety

---

### Step 5: Configure Repository Variables

Go to: **Repository → Settings → Secrets and variables → Actions → Variables**

Add:
```
Name: AZURE_LOCATION
Value: eastus  (or your preferred region)
```

This can be shared across environments or you can make it environment-specific if needed.

---

## 🚀 How It Works

### Workflow Behavior

**On Pull Request:**
```
1. Validate job runs for all 3 environments (matrix)
   - Uses environment-specific subscription for each
2. What-If job runs for all 3 environments (matrix)
   - Shows changes for each subscription separately
3. Results posted as PR comments
```

**On Push to Main:**
```
1. Deploy to Dev → Uses Dev subscription
2. Deploy to Staging → Uses Staging subscription (requires approval if configured)
3. Deploy to Production → Uses Prod subscription (requires approval if configured)
```

**Manual Deployment:**
```
1. Select environment (dev/stg/prod)
2. Deploys to that environment's subscription
```

### What Changed in the Workflow

✅ **validate** and **whatif** jobs now include `environment: ${{ matrix.environment }}`
- This ensures each matrix job uses the correct environment-specific secrets

✅ **All deployment steps** show the subscription ID in outputs
- Makes it clear which subscription was used

✅ **Each environment job** uses its own `environment:` declaration
- `deploy-dev` uses `environment: dev` → Dev subscription secrets
- `deploy-stg` uses `environment: stg` → Staging subscription secrets
- `deploy-prod` uses `environment: prod` → Production subscription secrets

---

## 🧪 Testing the Setup

### Test 1: Verify Secrets Configuration

```bash
# Manually trigger workflow and check logs for subscription IDs
# Go to: Actions → Deploy Azure AI Foundry → Run workflow → Select "dev"
# Check the "Output deployment results" step
```

### Test 2: Create a Test PR

```bash
git checkout -b test-multi-sub
# Make a small change to any param file
git add .
git commit -m "Test: Multi-subscription validation"
git push origin test-multi-sub
# Create PR on GitHub
```

Expected behavior:
- 3 validation jobs (one per environment/subscription)
- 3 what-if jobs (one per environment/subscription)
- Each shows resources in its respective subscription

### Test 3: Deploy to Dev

```bash
# Merge PR or push to main
git checkout main
git merge test-multi-sub
git push origin main
```

Expected behavior:
- Deploys to Dev subscription only
- Creates `dev-aif-foundry-rg` in Dev subscription

---

## 📊 Verification Checklist

After setup, verify:

- [ ] Three GitHub environments created (dev, stg, prod)
- [ ] Each environment has 3 secrets (CLIENT_ID, TENANT_ID, SUBSCRIPTION_ID)
- [ ] Subscription IDs are different for each environment
- [ ] OIDC federated credentials created for all three environments
- [ ] Service principal has Contributor + User Access Administrator on all subscriptions
- [ ] Protection rules configured for stg and prod environments
- [ ] AZURE_LOCATION repository variable set
- [ ] Test PR shows validation for all three subscriptions
- [ ] Dev deployment creates resources in correct subscription

---

## 🔒 Security Benefits

**Subscription-level isolation provides:**

1. **Billing Separation** - Each environment has its own billing
2. **Policy Isolation** - Apply different Azure Policies per environment
3. **RBAC Isolation** - Completely separate access control
4. **Quota Isolation** - Each subscription has its own resource quotas
5. **Blast Radius Reduction** - Issues in one environment don't affect others
6. **Compliance** - Easier to meet compliance requirements with isolated environments

---

## 🆘 Troubleshooting

### Issue: "Subscription not found"

**Cause:** Environment secrets not configured correctly

**Fix:**
1. Verify subscription IDs in GitHub environment secrets
2. Ensure no typos in subscription GUID
3. Check you're logged into correct tenant

### Issue: "Authorization failed"

**Cause:** Service principal doesn't have permission in subscription

**Fix:**
```bash
# Verify role assignments
az role assignment list --assignee <app-id> --all

# If missing, add roles
az role assignment create \
  --assignee <app-id> \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"
```

### Issue: "Federated credential validation failed"

**Cause:** OIDC federated credential not configured for environment

**Fix:**
1. Go to Azure Portal → Azure AD → App Registrations → Your App
2. Go to "Certificates & secrets" → "Federated credentials"
3. Verify credentials exist for all three environments
4. Check subject matches: `repo:org/repo:environment:dev` (or stg/prod)

---

## 📝 Summary

Your solution now supports:

✅ **3 separate Azure subscriptions** (dev, stg, prod)
✅ **Dedicated resource group per subscription** (isolation)
✅ **Environment-specific secrets** in GitHub
✅ **OIDC authentication** (no stored credentials)
✅ **Matrix validation** (validates all subscriptions on PR)
✅ **Sequential deployment** (dev → stg → prod)
✅ **Manual deployment** to any environment
✅ **Approval gates** for stg and prod

All resources are now **completely isolated** at both subscription and resource group levels!
