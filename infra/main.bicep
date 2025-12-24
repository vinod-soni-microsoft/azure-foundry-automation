// Main Bicep Orchestrator - Azure AI Foundry Deployment
targetScope = 'subscription'

@description('Name prefix for resources')
@minLength(2)
@maxLength(10)
param namePrefix string

@description('Azure region for resources')
param location string

@description('Environment tags')
param tags object = {}

@description('Array of projects to create')
param projects array = []

@description('Key Vault name')
param kvName string

@description('Storage account name')
param storageName string

@description('AI Services account name')
param aiServicesName string

@description('AI Services custom subdomain')
param aiServicesSubdomain string = ''

@description('AI Services model deployments')
param aiServicesDeployments array = []

@description('Application Insights name')
param appInsightsName string = ''

@description('Connection authentication type for AI Services')
@allowed([
  'ApiKey'
  'AAD'
])
param connectionAuthType string = 'AAD'

@description('Resource group name')
param resourceGroupName string = '${namePrefix}-foundry-rg'

// Variables
var foundryHubName = '${namePrefix}-foundry-hub'
var mergedTags = union(
  {
    deployedBy: 'Bicep'
    iac: 'bicep'
  },
  tags
)

// Create Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: mergedTags
}

// Deploy Application Insights (if name provided)
module appInsights 'modules/appinsights.bicep' = if (!empty(appInsightsName)) {
  name: 'deploy-appinsights-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    appInsightsName: appInsightsName
    location: location
    tags: mergedTags
  }
}

// Deploy Key Vault
module keyVault 'modules/kv.bicep' = {
  name: 'deploy-keyvault-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    kvName: kvName
    location: location
    tags: mergedTags
    enableRbacAuthorization: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
  }
}

// Deploy Storage Account
module storage 'modules/storage.bicep' = {
  name: 'deploy-storage-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    storageName: storageName
    location: location
    tags: mergedTags
    skuName: 'Standard_LRS'
    enableHierarchicalNamespace: false
  }
}

// Deploy AI Services
module aiServices 'modules/aiservices.bicep' = {
  name: 'deploy-aiservices-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    aiServicesName: aiServicesName
    location: location
    tags: mergedTags
    customSubDomainName: !empty(aiServicesSubdomain) ? aiServicesSubdomain : aiServicesName
    disableLocalAuth: connectionAuthType == 'AAD'
    deployments: aiServicesDeployments
  }
}

// Deploy Foundry Hub
module foundryHub 'modules/foundry.bicep' = {
  name: 'deploy-foundry-hub-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    foundryName: foundryHubName
    location: location
    tags: mergedTags
    keyVaultId: keyVault.outputs.id
    storageAccountId: storage.outputs.id
    applicationInsightsId: appInsights.?outputs.?id ?? ''
    aiServicesName: aiServices.outputs.name
    aiServicesId: aiServices.outputs.id
    aiServicesEndpoint: aiServices.outputs.endpoint
    connectionAuthType: connectionAuthType
    friendlyName: '${namePrefix} AI Foundry Hub'
    hubDescription: 'Azure AI Foundry Hub for ${namePrefix} environment'
  }
}

// Grant Foundry Hub access to Key Vault (Key Vault Secrets User)
module kvRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'assign-kv-role-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    principalId: foundryHub.outputs.principalId
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    principalType: 'ServicePrincipal'
    resourceId: keyVault.outputs.id
  }
}

// Grant Foundry Hub access to Storage (Storage Blob Data Contributor)
module storageRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'assign-storage-role-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    principalId: foundryHub.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
    principalType: 'ServicePrincipal'
    resourceId: storage.outputs.id
  }
}

// Grant AI Services access to Foundry Hub (Cognitive Services OpenAI User)
module aiServicesRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'assign-aiservices-role-${uniqueString(rg.id)}'
  scope: resourceGroup(rg.name)
  params: {
    principalId: foundryHub.outputs.principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd' // Cognitive Services OpenAI User
    principalType: 'ServicePrincipal'
    resourceId: aiServices.outputs.id
  }
}

// Deploy Projects
module foundryProjects 'modules/project.bicep' = [for (project, index) in projects: {
  name: 'deploy-project-${project.name}-${uniqueString(rg.id, string(index))}'
  scope: resourceGroup(rg.name)
  params: {
    projectName: '${namePrefix}-${project.name}'
    location: location
    tags: mergedTags
    hubId: foundryHub.outputs.id
    friendlyName: project.name
    projectDescription: project.description
  }
}]

// Outputs
@description('Resource Group name')
output resourceGroupName string = rg.name

@description('Foundry Hub ID')
output foundryHubId string = foundryHub.outputs.id

@description('Foundry Hub name')
output foundryHubName string = foundryHub.outputs.name

@description('Foundry Hub principal ID')
output foundryHubPrincipalId string = foundryHub.outputs.principalId

@description('AI Services ID')
output aiServicesId string = aiServices.outputs.id

@description('AI Services name')
output aiServicesName string = aiServices.outputs.name

@description('AI Services endpoint')
output aiServicesEndpoint string = aiServices.outputs.endpoint

@description('Application Insights ID')
output appInsightsId string = appInsights.?outputs.?id ?? ''

@description('Key Vault ID')
output keyVaultId string = keyVault.outputs.id

@description('Storage Account ID')
output storageAccountId string = storage.outputs.id

@description('Project IDs')
output projectIds array = [for (project, index) in projects: foundryProjects[index].outputs.id]

@description('Project names')
output projectNames array = [for (project, index) in projects: foundryProjects[index].outputs.name]
