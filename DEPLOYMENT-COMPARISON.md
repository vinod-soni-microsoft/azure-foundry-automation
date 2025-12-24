# Deployment Methods Comparison

## Overview

This solution supports **two deployment methods** - choose based on your needs or use both!

---

## 🆚 Quick Comparison

| Feature | Azure Developer CLI (azd) | GitHub Actions |
|---------|---------------------------|----------------|
| **Deployment Trigger** | Manual command | Git push / PR |
| **Subscription Selection** | Interactive prompt at runtime | Pre-configured in GitHub secrets |
| **Best For** | Local dev, testing, quick deploys | CI/CD, production automation |
| **Setup Complexity** | ⭐ Simple (install azd) | ⭐⭐⭐ Moderate (OIDC setup) |
| **Multi-Subscription** | ✅ Prompts per environment | ✅ Environment secrets |
| **What-If Analysis** | `azd provision --preview` | Automatic on PR |
| **Approval Gates** | Manual decision | Configured per environment |
| **Deployment Speed** | 🚀 Fast (local) | 🐢 Slower (CI/CD runner) |
| **Requires** | azd + Azure CLI | GitHub repo + OIDC |
| **Environment Switch** | `azd env select <env>` | Pipeline picks based on trigger |
| **Configuration Storage** | `.azure/<env>/.env` | GitHub environment secrets |
| **Rollback** | `azd down` + `azd up` | Re-run pipeline with previous commit |

---

## 📋 Detailed Comparison

### Azure Developer CLI (azd)

**✅ Pros:**
- Quick to get started (just install azd)
- Interactive prompts for subscription/resource group
- No GitHub/OIDC setup required
- Fast local deployments
- Great for development and testing
- Easy to switch between environments
- Configuration persists in `.azure/<env>/.env`
- Preview changes with `--preview` flag
- Direct Azure connection (no CI/CD overhead)

**❌ Cons:**
- Manual deployment process
- No automatic PR validation
- No approval gates (manual decision-making)
- Requires local setup on each developer machine
- Not suitable for automated production deployments
- No audit trail (unless manually logged)

**🎯 Use Cases:**
- Local development and testing
- Quick infrastructure updates
- Dev environment deployments
- Manual production hotfixes
- Infrastructure troubleshooting
- Testing Bicep changes before PR

**📦 Setup Steps:**
1. Install azd: `winget install microsoft.azd`
2. Login: `az login`
3. Deploy: `azd env select dev && azd up`

**⏱️ Time to First Deployment:** ~5 minutes

---

### GitHub Actions

**✅ Pros:**
- Fully automated CI/CD pipeline
- Automatic PR validation with What-If
- Approval gates for staging/production
- Sequential deployments (dev → stg → prod)
- Complete audit trail in GitHub
- No local setup required (runs in cloud)
- GitOps workflow
- Environment-specific secrets per subscription
- Multi-environment validation on every PR
- Consistent deployment process

**❌ Cons:**
- Requires OIDC setup (one-time, but complex)
- Slower than local deployment (CI/CD overhead)
- Requires GitHub repository
- Need to configure environment secrets
- Less flexible for ad-hoc testing
- Debugging can be harder (CI/CD logs)

**🎯 Use Cases:**
- Production deployments with approval
- Automated dev/stg deployments on git push
- PR validation before merge
- Team collaboration with GitOps
- Compliance/audit requirements
- Automated testing pipeline

**📦 Setup Steps:**
1. Create Azure AD app registration
2. Configure OIDC federated credentials
3. Set up GitHub environment secrets
4. Configure approval gates
5. Push to GitHub → Automatic deployment

**⏱️ Time to First Deployment:** ~30-60 minutes (setup) + deployment time

---

## 🎨 Usage Scenarios

### Scenario 1: Solo Developer / Quick Testing

**Recommendation:** Use **azd**

```powershell
# Quick dev deployment
azd env select dev
azd up

# Test changes
azd provision --preview  # See what will change
azd up                   # Apply changes

# Clean up
azd down
```

**Why?**
- No setup overhead
- Fast iteration
- No need for GitHub/OIDC

---

### Scenario 2: Team Collaboration / Production Deployments

**Recommendation:** Use **GitHub Actions**

```bash
# Developer workflow
git checkout -b feature/new-model
# Make changes to Bicep files
git commit -m "Add new AI model"
git push

# Create PR → Automatic What-If for all environments
# Review What-If results
# Merge PR → Automatic deployment: dev → stg → prod
```

**Why?**
- Team visibility (PR reviews)
- Approval gates for production
- Audit trail
- Consistent deployment process

---

### Scenario 3: Hybrid Approach (Recommended!)

**Use both methods:**

**azd for:**
- Dev environment deployments
- Testing infrastructure changes
- Quick hotfixes
- Local validation before PR

**GitHub Actions for:**
- Staging deployments
- Production deployments
- PR validation
- Automated rollouts

**Example Workflow:**
```powershell
# 1. Develop and test locally with azd
azd env select dev
azd provision --preview  # Preview changes
azd up                   # Deploy to dev

# 2. Verify in dev, then create PR
git checkout -b feature/update
git commit -m "Update AI Services config"
git push

# 3. GitHub Actions validates changes (What-If)
# 4. Review and merge PR
# 5. GitHub Actions deploys to stg → prod
```

**Why?**
- Fast local development (azd)
- Automated production deployments (GitHub Actions)
- Best of both worlds

---

## 🔄 Migration Path

### Starting with azd, Moving to GitHub Actions

1. **Phase 1: Development (azd)**
   ```powershell
   azd env select dev
   azd up
   ```

2. **Phase 2: Add CI/CD (GitHub Actions)**
   - Set up OIDC (one-time)
   - Configure GitHub environments
   - Add approval gates for prod
   - Keep using azd for dev

3. **Phase 3: Full Automation**
   - All environments via GitHub Actions
   - azd for emergency hotfixes only

---

## 💰 Cost Comparison

| Aspect | azd | GitHub Actions |
|--------|-----|----------------|
| **Tooling Cost** | Free | Free (public repos) |
| **Compute Cost** | Your machine | GitHub-hosted runner (free for public, 2000 min/month private) |
| **Azure Costs** | Same | Same |
| **Time Cost** | Lower (faster) | Higher (CI/CD overhead) |

**Verdict:** Similar costs, azd slightly faster for small teams

---

## 🔒 Security Comparison

| Security Aspect | azd | GitHub Actions |
|----------------|-----|----------------|
| **Authentication** | Your Azure credentials | OIDC (no stored secrets) |
| **Secret Storage** | Local `.azure/` folder | GitHub environment secrets |
| **Audit Trail** | No (unless manually logged) | Yes (GitHub Actions logs) |
| **Approval Gates** | Manual decision | Configured approvers |
| **Access Control** | Your Azure RBAC | GitHub + Azure RBAC |

**Verdict:** GitHub Actions more secure for production (OIDC, audit, approvals)

---

## 📊 Decision Matrix

| Your Situation | Recommended Method |
|----------------|-------------------|
| Solo developer, quick testing | **azd** |
| Small team, < 5 people | **azd** |
| Large team, > 5 people | **GitHub Actions** |
| Need approval gates | **GitHub Actions** |
| Need audit trail | **GitHub Actions** |
| Fast iteration needed | **azd** |
| Production deployments | **GitHub Actions** |
| Dev/test deployments | **azd** |
| GitOps workflow required | **GitHub Actions** |
| No GitHub account | **azd** |
| Compliance requirements | **GitHub Actions** |
| Emergency hotfixes | **azd** |

---

## 🎯 Recommended Setup

### For Most Teams:

**Use BOTH methods:**

1. **Set up azd first** (5 minutes)
   - Quick to start
   - Use for dev environment
   - Fast feedback loop

2. **Add GitHub Actions later** (1 hour)
   - Set up OIDC
   - Use for stg and prod
   - Approval gates for production

### Commands:

**Development (azd):**
```powershell
azd env select dev
azd up
```

**Staging/Production (GitHub Actions):**
```bash
git push origin main
# Automatic deployment via GitHub Actions
```

---

## 📚 Documentation Links

### Azure Developer CLI (azd)
- **[AZD-DEPLOYMENT-GUIDE.md](AZD-DEPLOYMENT-GUIDE.md)** - Complete guide
- **[AZD-QUICK-REFERENCE.md](AZD-QUICK-REFERENCE.md)** - Command reference
- **[SETUP-COMPLETE.md](SETUP-COMPLETE.md)** - Setup overview

### GitHub Actions
- **[MULTI-SUBSCRIPTION-SETUP.md](MULTI-SUBSCRIPTION-SETUP.md)** - OIDC setup
- **[.github/workflows/deploy-foundry.yml](.github/workflows/deploy-foundry.yml)** - Pipeline config

---

## ✅ Summary

| Method | Best For | Setup Time | Deployment Time |
|--------|----------|-----------|----------------|
| **azd** | Dev/Testing | 5 min | 10-15 min |
| **GitHub Actions** | Prod/Automation | 60 min | 20-30 min |
| **Both** | Enterprise | 65 min | Varies |

**Recommendation:** Start with **azd** for quick wins, add **GitHub Actions** for production governance.

🎉 **You have both options ready to use!**
