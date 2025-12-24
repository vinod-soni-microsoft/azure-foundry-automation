#Requires -Version 7.0

<#
.SYNOPSIS
    Automated deployment and validation script for Azure AI Foundry infrastructure

.DESCRIPTION
    This script deploys Azure AI Foundry infrastructure to dev, stg, and prod environments
    using Azure Developer CLI (azd) and validates the deployments.

.PARAMETER Environments
    Environments to deploy (default: dev, stg, prod)

.PARAMETER SkipDeployment
    Skip deployment and only validate existing resources

.PARAMETER ValidateOnly
    Only validate Bicep templates without deploying

.EXAMPLE
    .\Deploy-AllEnvironments.ps1
    Deploy to all environments

.EXAMPLE
    .\Deploy-AllEnvironments.ps1 -Environments dev,stg
    Deploy to dev and stg only

.EXAMPLE
    .\Deploy-AllEnvironments.ps1 -ValidateOnly
    Validate templates without deploying
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('dev', 'stg', 'prod')]
    [string[]]$Environments = @('dev', 'stg', 'prod'),
    
    [Parameter()]
    [switch]$SkipDeployment,
    
    [Parameter()]
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Configuration
$script:Config = @{
    Dev = @{
        Name = 'dev'
        SubscriptionId = '4aa3a068-9553-4d3b-be35-5f6660a6253b'
        SubscriptionName = 'ME-MngEnvMCAP797853-vinodsoni-1'
        Location = 'eastus'
        ResourceGroupPrefix = 'dev-aif-foundry'
    }
    Stg = @{
        Name = 'stg'
        SubscriptionId = '0f0883b9-dc02-4643-8c63-e0e06bd83582'
        SubscriptionName = 'ME-MngEnvMCAP797853-vinodsoni-2'
        Location = 'eastus'
        ResourceGroupPrefix = 'stg-aif-foundry'
    }
    Prod = @{
        Name = 'prod'
        SubscriptionId = '46f152a6-fff5-4d68-a8ae-cf0d69857e6a'
        SubscriptionName = 'ME-MngEnvMCAP797853-vinodsoni-3'
        Location = 'eastus'
        ResourceGroupPrefix = 'prod-aif-foundry'
    }
}

$script:DeploymentResults = @{}
$script:StartTime = Get-Date

#region Helper Functions

function Write-Banner {
    param([string]$Message, [string]$Color = 'Cyan')
    
    $line = "═" * 80
    Write-Host "`n╔$line╗" -ForegroundColor $Color
    Write-Host "║" -ForegroundColor $Color -NoNewline
    Write-Host (" " + $Message.PadRight(80) + " ") -ForegroundColor White -NoNewline
    Write-Host "║" -ForegroundColor $Color
    Write-Host "╚$line╝`n" -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-Host "▶ $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check Azure CLI
    try {
        $azVersion = az version --query '\"azure-cli\"' -o tsv 2>$null
        Write-Success "Azure CLI installed: $azVersion"
    }
    catch {
        Write-Error "Azure CLI not installed. Install from: https://aka.ms/installazurecli"
        return $false
    }
    
    # Check azd
    try {
        $azdVersion = azd version 2>$null | Select-String -Pattern 'azd version (\S+)' | ForEach-Object { $_.Matches.Groups[1].Value }
        Write-Success "Azure Developer CLI (azd) installed: $azdVersion"
    }
    catch {
        Write-Error "Azure Developer CLI not installed. Install with: winget install microsoft.azd"
        return $false
    }
    
    # Check Bicep
    try {
        $bicepVersion = bicep --version 2>$null
        Write-Success "Bicep CLI installed: $bicepVersion"
    }
    catch {
        Write-Error "Bicep CLI not found. Installing..."
        az bicep install
        Write-Success "Bicep CLI installed"
    }
    
    # Check if logged in
    try {
        $account = az account show 2>$null | ConvertFrom-Json
        Write-Success "Logged in as: $($account.user.name)"
    }
    catch {
        Write-Error "Not logged into Azure. Running 'az login'..."
        az login
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to login to Azure"
            return $false
        }
    }
    
    return $true
}

function Test-BicepTemplates {
    Write-Step "Validating Bicep templates..."
    
    $templates = Get-ChildItem -Path "$PSScriptRoot\infra" -Filter "*.bicep" -Recurse
    $allValid = $true
    
    foreach ($template in $templates) {
        Write-Host "  Checking $($template.Name)..." -NoNewline
        
        try {
            $result = bicep build $template.FullName 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓" -ForegroundColor Green
            }
            else {
                Write-Host " ✗" -ForegroundColor Red
                Write-Host "    Error: $result" -ForegroundColor Red
                $allValid = $false
            }
        }
        catch {
            Write-Host " ✗" -ForegroundColor Red
            Write-Host "    Error: $_" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    if ($allValid) {
        Write-Success "All Bicep templates are valid"
    }
    else {
        Write-Error "Some Bicep templates have errors"
    }
    
    return $allValid
}

function Test-SubscriptionAccess {
    param([hashtable]$EnvConfig)
    
    Write-Step "Testing access to subscription: $($EnvConfig.SubscriptionName)"
    
    try {
        az account set --subscription $EnvConfig.SubscriptionId 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Cannot access subscription: $($EnvConfig.SubscriptionName)"
            return $false
        }
        
        $subscription = az account show | ConvertFrom-Json
        Write-Success "Access confirmed: $($subscription.name) ($($subscription.id))"
        
        # Check permissions
        $permissions = az role assignment list --assignee (az account show --query user.name -o tsv) --subscription $EnvConfig.SubscriptionId | ConvertFrom-Json
        
        $hasContributor = $permissions | Where-Object { $_.roleDefinitionName -eq 'Contributor' }
        $hasOwner = $permissions | Where-Object { $_.roleDefinitionName -eq 'Owner' }
        
        if ($hasContributor -or $hasOwner) {
            Write-Success "Sufficient permissions found"
            return $true
        }
        else {
            Write-Error "Insufficient permissions. Need Contributor or Owner role."
            return $false
        }
    }
    catch {
        Write-Error "Failed to access subscription: $_"
        return $false
    }
}

function Deploy-Environment {
    param([hashtable]$EnvConfig)
    
    $envName = $EnvConfig.Name
    
    Write-Banner "Deploying to $($envName.ToUpper()) Environment" "Yellow"
    
    Write-Info "Environment: $envName"
    Write-Info "Subscription: $($EnvConfig.SubscriptionName)"
    Write-Info "Subscription ID: $($EnvConfig.SubscriptionId)"
    Write-Info "Location: $($EnvConfig.Location)"
    
    # Set subscription
    Write-Step "Setting Azure subscription..."
    az account set --subscription $EnvConfig.SubscriptionId
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to set subscription"
        return @{ Success = $false; Error = "Failed to set subscription" }
    }
    
    # Select azd environment
    Write-Step "Selecting azd environment: $envName"
    azd env select $envName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to select azd environment"
        return @{ Success = $false; Error = "Failed to select azd environment" }
    }
    
    # Verify environment variables
    Write-Step "Verifying environment configuration..."
    $envVars = azd env get-values | Out-String
    Write-Host $envVars -ForegroundColor Gray
    
    # Deploy with azd
    Write-Step "Deploying infrastructure with azd up..."
    Write-Info "This may take 10-15 minutes..."
    
    $deployStartTime = Get-Date
    
    try {
        # Run azd up with output capture
        $output = azd up --no-prompt 2>&1 | Tee-Object -Variable azdOutput
        
        $deployEndTime = Get-Date
        $duration = $deployEndTime - $deployStartTime
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Deployment completed successfully in $([math]::Round($duration.TotalMinutes, 2)) minutes"
            
            # Get deployment outputs
            $outputs = Get-DeploymentOutputs -EnvConfig $EnvConfig
            
            return @{
                Success = $true
                Duration = $duration
                Outputs = $outputs
                StartTime = $deployStartTime
                EndTime = $deployEndTime
            }
        }
        else {
            Write-Error "Deployment failed"
            Write-Host $output -ForegroundColor Red
            
            return @{
                Success = $false
                Error = "Deployment failed with exit code $LASTEXITCODE"
                Output = $output
                Duration = $duration
            }
        }
    }
    catch {
        Write-Error "Deployment failed with exception: $_"
        
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-DeploymentOutputs {
    param([hashtable]$EnvConfig)
    
    Write-Step "Retrieving deployment outputs..."
    
    az account set --subscription $EnvConfig.SubscriptionId | Out-Null
    
    # Find resource group
    $resourceGroups = az group list --query "[?starts_with(name, '$($EnvConfig.ResourceGroupPrefix)')].name" -o tsv
    
    if (-not $resourceGroups) {
        Write-Error "Resource group not found"
        return $null
    }
    
    $rgName = $resourceGroups | Select-Object -First 1
    Write-Info "Found resource group: $rgName"
    
    # Get resources
    $resources = az resource list --resource-group $rgName | ConvertFrom-Json
    
    $outputs = @{
        ResourceGroup = $rgName
        Resources = @{}
    }
    
    foreach ($resource in $resources) {
        $resourceType = $resource.type.Split('/')[-1]
        $outputs.Resources[$resourceType] = @{
            Name = $resource.name
            Type = $resource.type
            Location = $resource.location
            Id = $resource.id
        }
    }
    
    return $outputs
}

function Test-Deployment {
    param([hashtable]$EnvConfig, [hashtable]$Outputs)
    
    Write-Step "Validating deployment..."
    
    az account set --subscription $EnvConfig.SubscriptionId | Out-Null
    
    $rgName = $Outputs.ResourceGroup
    $allValid = $true
    
    # Expected resources
    $expectedResources = @(
        'Microsoft.MachineLearningServices/workspaces',  # AI Foundry Hub
        'Microsoft.CognitiveServices/accounts',          # AI Services
        'Microsoft.KeyVault/vaults',                     # Key Vault
        'Microsoft.Storage/storageAccounts',             # Storage Account
        'Microsoft.Insights/components'                   # Application Insights
    )
    
    foreach ($expectedType in $expectedResources) {
        $resourceExists = az resource list --resource-group $rgName --resource-type $expectedType --query "[0]" -o json | ConvertFrom-Json
        
        if ($resourceExists) {
            Write-Success "✓ Found: $expectedType - $($resourceExists.name)"
        }
        else {
            Write-Error "✗ Missing: $expectedType"
            $allValid = $false
        }
    }
    
    # Check AI Services deployment models
    $aiServices = az resource list --resource-group $rgName --resource-type 'Microsoft.CognitiveServices/accounts' --query "[0]" -o json | ConvertFrom-Json
    
    if ($aiServices) {
        Write-Step "Checking AI Services deployments..."
        
        $deployments = az cognitiveservices account deployment list `
            --name $aiServices.name `
            --resource-group $rgName `
            --query "[].{name:name, model:properties.model.name, capacity:sku.capacity}" `
            -o json | ConvertFrom-Json
        
        if ($deployments) {
            foreach ($deployment in $deployments) {
                Write-Success "  Model: $($deployment.model) (capacity: $($deployment.capacity))"
            }
        }
    }
    
    return $allValid
}

function New-DeploymentReport {
    Write-Banner "Deployment Summary Report" "Green"
    
    $totalDuration = (Get-Date) - $script:StartTime
    
    Write-Host "Total Execution Time: $([math]::Round($totalDuration.TotalMinutes, 2)) minutes`n" -ForegroundColor Cyan
    
    $successCount = ($script:DeploymentResults.Values | Where-Object { $_.Success }).Count
    $failCount = ($script:DeploymentResults.Values | Where-Object { -not $_.Success }).Count
    
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "  ✅ Successful: $successCount" -ForegroundColor Green
    Write-Host "  ❌ Failed: $failCount" -ForegroundColor Red
    Write-Host ""
    
    foreach ($env in $script:DeploymentResults.Keys | Sort-Object) {
        $result = $script:DeploymentResults[$env]
        $config = $script:Config[$env]
        
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        Write-Host "$($env.ToUpper()) Environment" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
        
        Write-Host "  Subscription: $($config.SubscriptionName)" -ForegroundColor White
        Write-Host "  Subscription ID: $($config.SubscriptionId)" -ForegroundColor Gray
        Write-Host "  Status: $(if ($result.Success) { '✅ Success' } else { '❌ Failed' })" -ForegroundColor $(if ($result.Success) { 'Green' } else { 'Red' })
        
        if ($result.Duration) {
            Write-Host "  Duration: $([math]::Round($result.Duration.TotalMinutes, 2)) minutes" -ForegroundColor Cyan
        }
        
        if ($result.Success -and $result.Outputs) {
            Write-Host "  Resource Group: $($result.Outputs.ResourceGroup)" -ForegroundColor White
            Write-Host "  Resources Deployed: $($result.Outputs.Resources.Count)" -ForegroundColor Cyan
            
            if ($result.Outputs.Resources.Count -gt 0) {
                Write-Host "`n  Deployed Resources:" -ForegroundColor Yellow
                foreach ($resourceType in $result.Outputs.Resources.Keys) {
                    $resource = $result.Outputs.Resources[$resourceType]
                    Write-Host "    • $($resource.Name) ($resourceType)" -ForegroundColor Gray
                }
            }
        }
        
        if (-not $result.Success -and $result.Error) {
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
    
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    # Save report to file
    $reportPath = "$PSScriptRoot\deployment-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    $script:DeploymentResults | ConvertTo-Json -Depth 10 | Out-File $reportPath
    Write-Info "Detailed report saved to: $reportPath"
}

#endregion

#region Main Script

try {
    Write-Banner "Azure AI Foundry - Multi-Subscription Deployment" "Cyan"
    
    Write-Host "Deployment Configuration:" -ForegroundColor Yellow
    Write-Host "  Environments: $($Environments -join ', ')" -ForegroundColor White
    Write-Host "  Validate Only: $ValidateOnly" -ForegroundColor White
    Write-Host "  Skip Deployment: $SkipDeployment" -ForegroundColor White
    Write-Host ""
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Error "Prerequisites check failed. Please install required tools."
        exit 1
    }
    
    Write-Success "All prerequisites met"
    
    # Validate Bicep templates
    if (-not (Test-BicepTemplates)) {
        Write-Error "Bicep template validation failed"
        exit 1
    }
    
    if ($ValidateOnly) {
        Write-Success "Validation complete. Exiting (ValidateOnly mode)."
        exit 0
    }
    
    # Test subscription access for all environments
    Write-Banner "Testing Subscription Access" "Cyan"
    
    foreach ($envName in $Environments) {
        $envConfig = $script:Config[$envName]
        
        if (-not (Test-SubscriptionAccess -EnvConfig $envConfig)) {
            Write-Error "Cannot access subscription for $envName. Exiting."
            exit 1
        }
    }
    
    Write-Success "Access confirmed for all subscriptions"
    
    if ($SkipDeployment) {
        Write-Info "Skipping deployment (SkipDeployment flag set)"
        exit 0
    }
    
    # Deploy to each environment
    foreach ($envName in $Environments) {
        $envConfig = $script:Config[$envName]
        
        $result = Deploy-Environment -EnvConfig $envConfig
        $script:DeploymentResults[$envName] = $result
        
        if ($result.Success) {
            # Validate deployment
            $validationResult = Test-Deployment -EnvConfig $envConfig -Outputs $result.Outputs
            $result.ValidationPassed = $validationResult
            
            if ($validationResult) {
                Write-Success "Deployment validated successfully for $($envName.ToUpper())"
            }
            else {
                Write-Error "Deployment validation failed for $($envName.ToUpper())"
            }
        }
        else {
            Write-Error "Deployment failed for $($envName.ToUpper())"
        }
        
        Write-Host "`n"
    }
    
    # Generate final report
    New-DeploymentReport
    
    # Exit with appropriate code
    $failedCount = ($script:DeploymentResults.Values | Where-Object { -not $_.Success }).Count
    
    if ($failedCount -eq 0) {
        Write-Success "All deployments completed successfully! 🎉"
        exit 0
    }
    else {
        Write-Error "$failedCount deployment(s) failed"
        exit 1
    }
}
catch {
    Write-Error "Script execution failed: $_"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
