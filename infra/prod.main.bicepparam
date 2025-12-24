using './main.bicep'

param namePrefix = 'prod-aif'
param location = 'eastus'

param tags = {
  env: 'production'
  owner: 'ai-team@contoso.com'
  costCenter: 'CC-AI-PROD'
}

param projects = [
  {
    name: 'chatbot'
    description: 'Production chatbot AI project'
  }
  {
    name: 'analytics'
    description: 'Production analytics AI project'
  }
  {
    name: 'recommendations'
    description: 'Production recommendations AI project'
  }
]

param kvName = 'prodaifkv001'
param storageName = 'prodaifstorage001'
param resourceGroupName = 'prod-aif-foundry-rg'

// AI Services Configuration
param aiServicesName = 'prodaifaiservices001'
param aiServicesSubdomain = 'prodaifaiservices001'
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
      capacity: 50
    }
  }
  {
    name: 'gpt-4o-mini'
    model: {
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    sku: {
      name: 'GlobalStandard'
      capacity: 50
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
      capacity: 50
    }
  }
]

// Application Insights
param appInsightsName = 'prodaifappinsights001'
