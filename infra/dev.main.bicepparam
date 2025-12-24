using './main.bicep'

param namePrefix = 'dev-aif'
param location = 'eastus'

param tags = {
  env: 'dev'
  owner: 'ai-team@contoso.com'
  costCenter: 'CC-AI-DEV'
}

param projects = [
  {
    name: 'chatbot'
    description: 'Development chatbot AI project'
  }
  {
    name: 'analytics'
    description: 'Development analytics AI project'
  }
]

param kvName = 'devaifkv001'
param storageName = 'devaifstorage001'
param resourceGroupName = 'dev-aif-foundry-rg'

// AI Services Configuration
param aiServicesName = 'devaifaiservices001'
param aiServicesSubdomain = 'devaifaiservices001'
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
      capacity: 10
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
      capacity: 10
    }
  }
]

// Application Insights
param appInsightsName = 'devaifappinsights001'
