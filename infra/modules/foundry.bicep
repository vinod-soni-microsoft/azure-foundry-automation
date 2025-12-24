// Azure AI Foundry Hub Module
targetScope = 'resourceGroup'

@description('Foundry hub name')
param foundryName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Key Vault resource ID')
param keyVaultId string

@description('Storage account resource ID')
param storageAccountId string

@description('Application Insights resource ID (optional)')
param applicationInsightsId string = ''

@description('Container Registry resource ID (optional)')
param containerRegistryId string = ''

@description('AI Services account name for connection')
param aiServicesName string

@description('AI Services resource ID')
param aiServicesId string

@description('AI Services endpoint')
param aiServicesEndpoint string

@description('Connection authentication type')
@allowed([
  'ApiKey'
  'AAD'
])
param connectionAuthType string = 'AAD'

@description('Friendly name for the hub')
param friendlyName string = ''

@description('Description of the hub')
param hubDescription string = ''

// Reference to existing AI Services
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: aiServicesName
}

resource foundryHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: foundryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'Hub'
  properties: {
    friendlyName: !empty(friendlyName) ? friendlyName : foundryName
    description: hubDescription
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: !empty(applicationInsightsId) ? applicationInsightsId : null
    containerRegistry: !empty(containerRegistryId) ? containerRegistryId : null
    publicNetworkAccess: 'Enabled' // Change to 'Disabled' for private endpoints
    managedNetwork: {
      isolationMode: 'Disabled' // Options: 'Disabled', 'AllowInternetOutbound', 'AllowOnlyApprovedOutbound'
    }
  }

  // AI Services Connection (child resource)
  resource aiServicesConnection 'connections@2024-04-01-preview' = {
    name: toLower('${aiServicesName}-connection')
    properties: {
      category: 'AIServices'
      target: aiServicesEndpoint
      authType: connectionAuthType
      isSharedToAll: true
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
      }
      credentials: connectionAuthType == 'ApiKey' ? {
        key: aiServices.listKeys().key1
      } : null
    }
  }
}

@description('Foundry hub resource ID')
output id string = foundryHub.id

@description('Foundry hub name')
output name string = foundryHub.name

@description('System-assigned managed identity principal ID')
output principalId string = foundryHub.identity.principalId

@description('Foundry hub discovery URL')
output discoveryUrl string = foundryHub.properties.discoveryUrl
