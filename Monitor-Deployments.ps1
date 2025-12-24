#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitor multi-subscription Azure deployments
.DESCRIPTION
    Monitors deployment progress across DEV, STG, and PROD subscriptions
#>

param(
    [int]$RefreshSeconds = 30,
    [switch]$Continuous
)

$ErrorActionPreference = "Stop"

# Subscription IDs
$subscriptions = @{
    DEV  = "4aa3a068-9553-4d3b-be35-5f6660a6253b"
    STG  = "0f0883b9-dc02-4643-8c63-e0e06bd83582"
    PROD = "46f152a6-fff5-4d68-a8ae-cf0d69857e6a"
}

# Deployment names (update these)
$deployments = @{
    DEV  = "dev-foundry-20251224-121943"
    STG  = "stg-foundry-20251224-123943"
    PROD = "prod-foundry-20251224-124030"
}

function Get-DeploymentStatus {
    param($Environment, $SubscriptionId, $DeploymentName)
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "  $Environment Environment" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    
    az account set --subscription $SubscriptionId 2>$null
    
    # Check deployment status
    $deployment = az deployment sub show --name $DeploymentName --query "{State:properties.provisioningState, Duration:properties.duration, Timestamp:properties.timestamp}" 2>$null | ConvertFrom-Json
    
    if ($deployment) {
        $stateColor = switch ($deployment.State) {
            "Succeeded" { "Green" }
            "Running" { "Yellow" }
            "Failed" { "Red" }
            default { "White" }
        }
        
        Write-Host "  📋 Deployment: " -NoNewline -ForegroundColor White
        Write-Host $DeploymentName -ForegroundColor Gray
        Write-Host "  🔄 State:      " -NoNewline -ForegroundColor White
        Write-Host $deployment.State -ForegroundColor $stateColor
        Write-Host "  ⏱️  Duration:   " -NoNewline -ForegroundColor White
        Write-Host $deployment.Duration -ForegroundColor White
    }
    else {
        Write-Host "  ❌ Deployment not found: $DeploymentName" -ForegroundColor Red
    }
    
    # Check resource group
    $rgPrefix = $Environment.ToLower() + "-aif"
    $rg = az group list --query "[?starts_with(name, '$rgPrefix')].{Name:name, State:properties.provisioningState}" 2>$null | ConvertFrom-Json
    
    if ($rg) {
        Write-Host "  📦 Resource Group: " -NoNewline -ForegroundColor White
        Write-Host "$($rg.Name) ($($rg.State))" -ForegroundColor Green
        
        # Count resources
        $resources = az resource list --resource-group $rg.Name 2>$null | ConvertFrom-Json
        if ($resources) {
            Write-Host "  🔧 Resources:      " -NoNewline -ForegroundColor White
            Write-Host "$($resources.Count) deployed" -ForegroundColor Green
            
            # Show key resources
            $hub = $resources | Where-Object { $_.type -eq "Microsoft.MachineLearningServices/workspaces" -and $_.kind -eq "Hub" }
            $projects = $resources | Where-Object { $_.type -eq "Microsoft.MachineLearningServices/workspaces" -and $_.kind -eq "Project" }
            $aiServices = $resources | Where-Object { $_.type -eq "Microsoft.CognitiveServices/accounts" }
            
            if ($hub) {
                Write-Host "    ✅ AI Foundry Hub: $($hub.name)" -ForegroundColor Gray
            }
            if ($projects) {
                Write-Host "    ✅ Projects: $($projects.Count)" -ForegroundColor Gray
            }
            if ($aiServices) {
                Write-Host "    ✅ AI Services: $($aiServices.name)" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "  ⏳ Resource group not yet created" -ForegroundColor Yellow
    }
}

function Show-Summary {
    Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Multi-Subscription Deployment Monitor          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    
    foreach ($env in @("DEV", "STG", "PROD")) {
        Get-DeploymentStatus -Environment $env -SubscriptionId $subscriptions[$env] -DeploymentName $deployments[$env]
    }
    
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
if ($Continuous) {
    Write-Host "🔄 Continuous monitoring mode (Ctrl+C to stop)" -ForegroundColor Yellow
    Write-Host "   Refresh interval: $RefreshSeconds seconds`n" -ForegroundColor Gray
    
    while ($true) {
        Clear-Host
        Show-Summary
        Write-Host "⏳ Refreshing in $RefreshSeconds seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds $RefreshSeconds
    }
}
else {
    Show-Summary
    Write-Host "💡 Tip: Run with -Continuous flag for auto-refresh" -ForegroundColor Gray
    Write-Host "   Example: .\Monitor-Deployments.ps1 -Continuous -RefreshSeconds 30`n" -ForegroundColor Gray
}
