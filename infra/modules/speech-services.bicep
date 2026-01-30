// Azure Speech Services Module
// Deploys a Speech Services resource with Voice Live API support
targetScope = 'resourceGroup'

@description('Name of the Speech Services resource')
param speechServicesName string

@description('Azure region for the Speech Services')
param location string

@description('Resource tags')
param tags object = {}

@description('SKU name for the Speech Services')
@allowed([
  'F0'
  'S0'
])
param skuName string = 'S0'

@description('Custom subdomain name for token-based authentication (required for Voice Live API)')
param customSubDomainName string = ''

@description('Enable public network access')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Disable local authentication (API key) - use AAD only')
param disableLocalAuth bool = false

@description('Enable dynamic throttling')
param dynamicThrottlingEnabled bool = false

@description('Network ACLs default action')
@allowed([
  'Allow'
  'Deny'
])
param networkAclsDefaultAction string = 'Allow'

@description('List of allowed IP rules (CIDR notation)')
param ipRules array = []

// Deploy the Speech Services resource
resource speechServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: speechServicesName
  location: location
  tags: tags
  kind: 'SpeechServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: !empty(customSubDomainName) ? customSubDomainName : speechServicesName
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
    dynamicThrottlingEnabled: dynamicThrottlingEnabled
    networkAcls: {
      defaultAction: networkAclsDefaultAction
      ipRules: [for ip in ipRules: {
        value: ip
      }]
    }
  }
}

@description('Speech Services resource ID')
output id string = speechServices.id

@description('Speech Services resource name')
output name string = speechServices.name

@description('Speech Services endpoint')
output endpoint string = speechServices.properties.endpoint

@description('Speech Services endpoints (all)')
output endpoints object = speechServices.properties.endpoints

@description('System-assigned managed identity principal ID')
output principalId string = speechServices.identity.principalId

@description('Speech Services region')
output region string = location
