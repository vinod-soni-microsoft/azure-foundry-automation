using './main.bicep'

param namePrefix = 'stg-aif'
param location = 'eastus'

param tags = {
  env: 'staging'
  owner: 'ai-team@contoso.com'
  costCenter: 'CC-AI-STG'
}

param projects = [
  {
    name: 'chatbot'
    description: 'Staging chatbot AI project for pre-production testing'
  }
  {
    name: 'analytics'
    description: 'Staging analytics AI project for pre-production testing'
  }
]

param kvName = 'stgaifkv001'
param storageName = 'stgaifstorage001'
param resourceGroupName = 'stg-aif-foundry-rg'

// AI Services Configuration
param aiServicesName = 'stgaifaiservices001'
param aiServicesSubdomain = 'stgaifaiservices001'
param connectionAuthType = 'AAD'

// OpenAI Model Deployments
param aiServicesDeployments = [
  {
    name: 'gpt-4o'
    model: {
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    sku: {
      name: 'GlobalStandard'
      capacity: 20
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: {
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 20
    }
  }
]

// Application Insights
param appInsightsName = 'stgaifappinsights001'
