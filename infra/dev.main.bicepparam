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

param kvName = 'devaifkv2026c'
param storageName = 'devaifstor2026c'
param resourceGroupName = 'dev-aif-foundry-rg'

// AI Services Configuration
param aiServicesName = 'devaifaisvc2026c'
param aiServicesSubdomain = 'devaifaisvc2026c'
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
param appInsightsName = 'devaifappins2026c'

// Speech Services with Voice Live API
param deploySpeechServices = true
param speechServicesName = 'devaifspeech2026c'
param speechServicesSubdomain = 'devaifspeech2026c'

// NOTE: AI Agents use Basic Agent Setup (Microsoft-managed infrastructure)
// Create agents via Azure AI Foundry portal or SDK - no Bicep deployment needed
// Microsoft automatically manages Cosmos DB, AI Search, and Storage for agents
// See: https://learn.microsoft.com/en-us/azure/ai-foundry/agents/concepts/capability-hosts
