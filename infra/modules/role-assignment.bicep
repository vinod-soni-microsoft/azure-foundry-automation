// Role Assignment Module - Assigns RBAC roles
targetScope = 'resourceGroup'

@description('Principal (object) ID to assign the role to')
param principalId string

@description('Role definition ID (GUID)')
param roleDefinitionId string

@description('Principal type')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

@description('Resource ID to assign the role at')
param resourceId string

// Extract resource type and name from resourceId
var resourceIdParts = split(resourceId, '/')
var resourceType = '${resourceIdParts[6]}/${resourceIdParts[7]}'
var resourceName = resourceIdParts[8]

resource targetResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (resourceType == 'Microsoft.KeyVault/vaults') {
  name: resourceName
}

resource targetStorageResource 'Microsoft.Storage/storageAccounts@2023-05-01' existing = if (resourceType == 'Microsoft.Storage/storageAccounts') {
  name: resourceName
}

resource targetAiServicesResource 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = if (resourceType == 'Microsoft.CognitiveServices/accounts') {
  name: resourceName
}

resource roleAssignmentKv 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (resourceType == 'Microsoft.KeyVault/vaults') {
  scope: targetResource
  name: guid(resourceId, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

resource roleAssignmentStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (resourceType == 'Microsoft.Storage/storageAccounts') {
  scope: targetStorageResource
  name: guid(resourceId, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

resource roleAssignmentAiServices 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (resourceType == 'Microsoft.CognitiveServices/accounts') {
  scope: targetAiServicesResource
  name: guid(resourceId, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('Role assignment ID')
output id string = resourceType == 'Microsoft.KeyVault/vaults' ? roleAssignmentKv.id : roleAssignmentStorage.id
