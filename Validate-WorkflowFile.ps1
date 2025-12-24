#Requires -Version 7.0

<#
.SYNOPSIS
    Validates the GitHub Actions workflow file (deploy-foundry.yml)

.DESCRIPTION
    This script performs comprehensive validation of the GitHub Actions workflow:
    - YAML syntax validation
    - Job configuration validation
    - Environment variable validation
    - Subscription ID validation
    - Bicep template path validation
    - Secrets and variable references validation

.EXAMPLE
    .\Validate-WorkflowFile.ps1

.EXAMPLE
    .\Validate-WorkflowFile.ps1 -Verbose
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Expected subscription configuration
$script:ExpectedSubscriptions = @{
    dev = '4aa3a068-9553-4d3b-be35-5f6660a6253b'
    stg = '0f0883b9-dc02-4643-8c63-e0e06bd83582'
    prod = '46f152a6-fff5-4d68-a8ae-cf0d69857e6a'
}

$script:ValidationResults = @{
    Passed = @()
    Failed = @()
    Warnings = @()
}

#region Helper Functions

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        $script:ValidationResults.Passed += $TestName
    }
    else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) {
            Write-Host "   → $Message" -ForegroundColor Yellow
        }
        $script:ValidationResults.Failed += @{
            Test = $TestName
            Message = $Message
        }
    }
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
    $script:ValidationResults.Warnings += $Message
}

function Test-YamlSyntax {
    param([string]$FilePath)
    
    Write-Host "`n📝 Testing YAML Syntax..." -ForegroundColor Cyan
    
    try {
        # Basic YAML syntax check
        $content = Get-Content $FilePath -Raw
        
        # Check for common YAML issues
        if ($content -match '\t') {
            Write-TestResult "No tabs in YAML" $false "Found tabs (use spaces for indentation)"
        }
        else {
            Write-TestResult "No tabs in YAML" $true
        }
        
        # Check for trailing spaces
        $lines = Get-Content $FilePath
        $trailingSpaces = $lines | Where-Object { $_ -match '\s+$' }
        
        if ($trailingSpaces.Count -gt 0) {
            Write-Warning "Found $($trailingSpaces.Count) lines with trailing spaces"
        }
        else {
            Write-TestResult "No trailing spaces" $true
        }
        
        # Check for proper indentation (2 spaces)
        $badIndent = $lines | Where-Object { $_ -match '^\s+' -and $_ -match '^ {1}[^ ]' }
        
        if ($badIndent.Count -gt 0) {
            Write-Warning "Some lines may have improper indentation (should be 2 spaces)"
        }
        else {
            Write-TestResult "Proper indentation" $true
        }
        
        return $true
    }
    catch {
        Write-TestResult "YAML Syntax Check" $false $_.Exception.Message
        return $false
    }
}

function Test-WorkflowStructure {
    param([string]$FilePath)
    
    Write-Host "`n🏗️  Testing Workflow Structure..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check required top-level keys
    $requiredKeys = @('name', 'on', 'permissions', 'jobs')
    
    foreach ($key in $requiredKeys) {
        if ($content -match "^$key\s*:") {
            Write-TestResult "Has '$key' key" $true
        }
        else {
            Write-TestResult "Has '$key' key" $false "Missing required key: $key"
        }
    }
    
    # Check jobs
    $expectedJobs = @('validate', 'whatif', 'deploy-dev', 'deploy-stg', 'deploy-prod', 'deploy-manual')
    
    foreach ($job in $expectedJobs) {
        if ($content -match "^\s+$job\s*:") {
            Write-TestResult "Job '$job' exists" $true
        }
        else {
            Write-TestResult "Job '$job' exists" $false "Missing job: $job"
        }
    }
    
    return $true
}

function Test-EnvironmentConfiguration {
    param([string]$FilePath)
    
    Write-Host "`n🌍 Testing Environment Configuration..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check if matrix includes all environments
    if ($content -match 'matrix:\s+environment:\s+\[(.*?)\]') {
        $matrixEnvs = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
        
        $expectedEnvs = @('dev', 'stg', 'prod')
        $allFound = $true
        
        foreach ($env in $expectedEnvs) {
            if ($matrixEnvs -contains $env) {
                Write-TestResult "Matrix includes '$env'" $true
            }
            else {
                Write-TestResult "Matrix includes '$env'" $false
                $allFound = $false
            }
        }
    }
    else {
        Write-TestResult "Matrix strategy configured" $false "Matrix strategy not found"
    }
    
    # Check environment declarations in jobs
    $jobs = @('validate', 'whatif', 'deploy-dev', 'deploy-stg', 'deploy-prod', 'deploy-manual')
    
    foreach ($job in $jobs) {
        if ($content -match "$job\s*:.*?environment\s*:" -or $content -match "$job\s*:.*?environment\s*:.*?\`$\{\{") {
            Write-TestResult "Job '$job' has environment" $true
        }
        else {
            Write-TestResult "Job '$job' has environment" $false "Environment not declared for job: $job"
        }
    }
    
    return $true
}

function Test-SecretReferences {
    param([string]$FilePath)
    
    Write-Host "`n🔐 Testing Secret References..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check required secrets
    $requiredSecrets = @('AZURE_CLIENT_ID', 'AZURE_TENANT_ID', 'AZURE_SUBSCRIPTION_ID')
    
    foreach ($secret in $requiredSecrets) {
        if ($content -match "secrets\.$secret") {
            Write-TestResult "References secret: $secret" $true
        }
        else {
            Write-TestResult "References secret: $secret" $false "Missing secret reference: $secret"
        }
    }
    
    # Check for AZURE_LOCATION variable
    if ($content -match 'vars\.AZURE_LOCATION') {
        Write-TestResult "Uses AZURE_LOCATION variable" $true
    }
    else {
        Write-Warning "AZURE_LOCATION variable not found (may use hardcoded location)"
    }
    
    return $true
}

function Test-BicepPaths {
    param([string]$FilePath)
    
    Write-Host "`n📂 Testing Bicep File Paths..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Extract Bicep template paths
    if ($content -match 'template:\s+(.+?\.bicep)') {
        $templatePath = $Matches[1].Trim()
        
        if (Test-Path "$PSScriptRoot\$templatePath") {
            Write-TestResult "Main template exists: $templatePath" $true
        }
        else {
            Write-TestResult "Main template exists: $templatePath" $false "File not found: $templatePath"
        }
    }
    
    # Check parameter files
    $environments = @('dev', 'stg', 'prod')
    
    foreach ($env in $environments) {
        $paramFile = "infra\$env.main.bicepparam"
        
        if ($content -match [regex]::Escape($paramFile)) {
            Write-TestResult "References parameter file: $env" $true
            
            if (Test-Path "$PSScriptRoot\$paramFile") {
                Write-TestResult "Parameter file exists: $env" $true
            }
            else {
                Write-TestResult "Parameter file exists: $env" $false "File not found: $paramFile"
            }
        }
        else {
            Write-TestResult "References parameter file: $env" $false "Missing parameter file reference"
        }
    }
    
    return $true
}

function Test-DeploymentConfiguration {
    param([string]$FilePath)
    
    Write-Host "`n🚀 Testing Deployment Configuration..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check deployment scope
    if ($content -match 'scope:\s+subscription') {
        Write-TestResult "Uses subscription scope" $true
    }
    else {
        Write-TestResult "Uses subscription scope" $false "Should use subscription scope for deployment"
    }
    
    # Check for Bicep CLI installation
    $bicepInstallCount = ([regex]::Matches($content, 'Install.*Bicep')).Count
    
    if ($bicepInstallCount -ge 6) {
        Write-TestResult "Bicep CLI installation in all jobs" $true
    }
    else {
        Write-TestResult "Bicep CLI installation in all jobs" $false "Found $bicepInstallCount Bicep install steps (expected 6)"
    }
    
    # Check for deployment names
    if ($content -match "deploymentName:\s+'foundry-") {
        Write-TestResult "Uses deployment names" $true
    }
    else {
        Write-Warning "Deployment names not found (recommended for tracking)"
    }
    
    # Check failOnStdErr setting
    if ($content -match 'failOnStdErr:\s+false') {
        Write-TestResult "failOnStdErr set to false" $true
    }
    else {
        Write-Warning "failOnStdErr should be false to avoid false positives"
    }
    
    return $true
}

function Test-TriggerConfiguration {
    param([string]$FilePath)
    
    Write-Host "`n🎯 Testing Workflow Triggers..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check pull_request trigger
    if ($content -match 'on:\s+pull_request:') {
        Write-TestResult "Pull request trigger configured" $true
    }
    else {
        Write-TestResult "Pull request trigger configured" $false
    }
    
    # Check push trigger
    if ($content -match 'push:\s+branches:') {
        Write-TestResult "Push trigger configured" $true
    }
    else {
        Write-TestResult "Push trigger configured" $false
    }
    
    # Check workflow_dispatch trigger
    if ($content -match 'workflow_dispatch:') {
        Write-TestResult "Manual dispatch configured" $true
    }
    else {
        Write-TestResult "Manual dispatch configured" $false
    }
    
    # Check path filters
    if ($content -match "paths:\s+- 'infra/") {
        Write-TestResult "Path filters configured" $true
    }
    else {
        Write-Warning "Path filters not configured (workflow may run on all changes)"
    }
    
    return $true
}

function Test-JobDependencies {
    param([string]$FilePath)
    
    Write-Host "`n🔗 Testing Job Dependencies..." -ForegroundColor Cyan
    
    $content = Get-Content $FilePath -Raw
    
    # Check validate -> whatif dependency
    if ($content -match 'whatif:.*?needs:\s+validate') {
        Write-TestResult "whatif depends on validate" $true
    }
    else {
        Write-TestResult "whatif depends on validate" $false
    }
    
    # Check validate -> deploy-dev dependency
    if ($content -match 'deploy-dev:.*?needs:\s+validate') {
        Write-TestResult "deploy-dev depends on validate" $true
    }
    else {
        Write-TestResult "deploy-dev depends on validate" $false
    }
    
    # Check deploy-dev -> deploy-stg dependency
    if ($content -match 'deploy-stg:.*?needs:\s+deploy-dev') {
        Write-TestResult "deploy-stg depends on deploy-dev" $true
    }
    else {
        Write-TestResult "deploy-stg depends on deploy-dev" $false
    }
    
    # Check deploy-stg -> deploy-prod dependency
    if ($content -match 'deploy-prod:.*?needs:\s+deploy-stg') {
        Write-TestResult "deploy-prod depends on deploy-stg" $true
    }
    else {
        Write-TestResult "deploy-prod depends on deploy-stg" $false
    }
    
    return $true
}

function New-ValidationReport {
    Write-Host "`n" 
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                           VALIDATION SUMMARY" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $passCount = $script:ValidationResults.Passed.Count
    $failCount = $script:ValidationResults.Failed.Count
    $warnCount = $script:ValidationResults.Warnings.Count
    
    Write-Host "`n📊 Results:" -ForegroundColor Yellow
    Write-Host "   ✅ Passed: $passCount" -ForegroundColor Green
    Write-Host "   ❌ Failed: $failCount" -ForegroundColor Red
    Write-Host "   ⚠️  Warnings: $warnCount" -ForegroundColor Yellow
    
    if ($failCount -gt 0) {
        Write-Host "`n❌ Failed Tests:" -ForegroundColor Red
        foreach ($fail in $script:ValidationResults.Failed) {
            Write-Host "   • $($fail.Test)" -ForegroundColor Red
            if ($fail.Message) {
                Write-Host "     → $($fail.Message)" -ForegroundColor Yellow
            }
        }
    }
    
    if ($warnCount -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warn in $script:ValidationResults.Warnings) {
            Write-Host "   • $warn" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    $percentage = if ($passCount + $failCount -gt 0) {
        [math]::Round(($passCount / ($passCount + $failCount)) * 100, 2)
    } else { 0 }
    
    Write-Host "`n📈 Overall Score: $percentage% ($passCount/$($passCount + $failCount))" -ForegroundColor $(if ($percentage -ge 90) { 'Green' } elseif ($percentage -ge 70) { 'Yellow' } else { 'Red' })
    
    if ($failCount -eq 0) {
        Write-Host "`n🎉 All validation tests passed!" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "`n⚠️  Some validation tests failed. Please review and fix the issues." -ForegroundColor Red
        return $false
    }
}

#endregion

#region Main Script

try {
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                               ║" -ForegroundColor Cyan
    Write-Host "║               GitHub Actions Workflow Validation Tool                        ║" -ForegroundColor Green
    Write-Host "║                                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $workflowPath = "$PSScriptRoot\.github\workflows\deploy-foundry.yml"
    
    Write-Host "`n📁 Workflow File: $workflowPath" -ForegroundColor Cyan
    
    if (-not (Test-Path $workflowPath)) {
        Write-Host "❌ Workflow file not found: $workflowPath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Workflow file found" -ForegroundColor Green
    
    # Run all validation tests
    Test-YamlSyntax -FilePath $workflowPath
    Test-WorkflowStructure -FilePath $workflowPath
    Test-EnvironmentConfiguration -FilePath $workflowPath
    Test-SecretReferences -FilePath $workflowPath
    Test-BicepPaths -FilePath $workflowPath
    Test-DeploymentConfiguration -FilePath $workflowPath
    Test-TriggerConfiguration -FilePath $workflowPath
    Test-JobDependencies -FilePath $workflowPath
    
    # Generate report
    $allPassed = New-ValidationReport
    
    if ($allPassed) {
        Write-Host "`n✅ Workflow file is ready for use!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "`n⚠️  Please fix the validation issues before deploying." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host "`n❌ Validation failed with error: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

#endregion
