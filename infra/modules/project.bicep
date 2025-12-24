// Azure AI Foundry Project Module
targetScope = 'resourceGroup'

@description('Project name')
param projectName string

@description('Azure region')
param location string

@description('Resource tags')
param tags object = {}

@description('Foundry hub resource ID')
param hubId string

@description('Friendly name for the project')
param friendlyName string = ''

@description('Description of the project')
param projectDescription string = ''

resource foundryProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01-preview' = {
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'Project'
  properties: {
    friendlyName: !empty(friendlyName) ? friendlyName : projectName
    description: projectDescription
    hubResourceId: hubId
    publicNetworkAccess: 'Enabled' // Inherits from hub in most cases
  }
}

@description('Project resource ID')
output id string = foundryProject.id

@description('Project name')
output name string = foundryProject.name

@description('System-assigned managed identity principal ID')
output principalId string = foundryProject.identity.principalId

@description('Project discovery URL')
output discoveryUrl string = foundryProject.properties.discoveryUrl
