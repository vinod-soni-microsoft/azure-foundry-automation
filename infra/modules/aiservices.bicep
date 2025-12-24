// Azure AI Services Module - OpenAI and Cognitive Services
targetScope = 'resourceGroup'

@description('AI Services account name')
param aiServicesName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('SKU for AI Services')
@allowed([
  'S0'
])
param skuName string = 'S0'

@description('Custom subdomain name for the AI Services endpoint')
param customSubDomainName string = ''

@description('Disable local authentication (use managed identity)')
param disableLocalAuth bool = false

@description('Public network access setting')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Array of OpenAI model deployments')
param deployments array = []

// Azure AI Services resource
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: aiServicesName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: !empty(customSubDomainName) ? customSubDomainName : aiServicesName
    disableLocalAuth: disableLocalAuth
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow' // Change to 'Deny' with ipRules for production
      bypass: 'AzureServices'
    }
  }
}

// Deploy OpenAI models
@batchSize(1)
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = [for deployment in deployments: {
  name: deployment.name
  parent: aiServices
  sku: {
    capacity: deployment.sku.capacity
    name: deployment.sku.name
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.model.name
      version: deployment.model.version
    }
  }
}]

@description('AI Services resource ID')
output id string = aiServices.id

@description('AI Services name')
output name string = aiServices.name

@description('AI Services endpoint')
output endpoint string = aiServices.properties.endpoint

@description('System-assigned managed identity principal ID')
output principalId string = aiServices.identity.principalId

@description('AI Services primary key (for legacy scenarios - use Azure AD when possible)')
output primaryKey string = aiServices.listKeys().key1
