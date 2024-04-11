param name string
param location string = resourceGroup().location
param resourceToken string
param tags object
param principalId string

var prefix = '${name}-${resourceToken}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${prefix}-logworkspace'
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: '${prefix}-appinsights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

var validStoragePrefix = take(replace(prefix, '-', ''), 17)

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${validStoragePrefix}storage'
  location: location
  kind: 'StorageV2'
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2020-10-01' = {
  name: '${prefix}-plan'
  location: location
  tags: tags
  kind: 'functionapp'
  properties: {
    reserved: true
  }
  sku: {
    name: 'Y1'
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-managed-identity'
  location: location
}

resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: '${prefix}-function-app'
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
   })
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${managedIdentity.id}': {} }
  }
  properties: {
    httpsOnly: true
    serverFarmId: hostingPlan.id
    clientAffinityEnabled: false
    siteConfig: {
      minTlsVersion: '1.2'
      linuxFxVersion: 'Python|3.9'
      appSettings: [
        {
           name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
           value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: managedIdentity.properties.clientId
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}


resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id,
             principalId, 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  properties: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',
                                 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  }
}

module diagnostics 'app-diagnostics.bicep' = {
  name: 'function-diagnostics'
  params: {
    appName: functionApp.name
    kind: 'functionapp'
    diagnosticWorkspaceId: logAnalytics.id
  }
}


module apiManagementResources 'apimanagement.bicep' = {
  name: 'applicationinsights-resources'
  params: {
    prefix: prefix
    location: location
    tags: tags
    functionAppName: functionApp.name
    appInsightsName: appInsights.name
    appInsightsId: appInsights.id
    appInsightsKey: appInsights.properties.InstrumentationKey
  }
}


resource functionAppProperties 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  kind: 'string'
  parent: functionApp
  properties: {
      apiManagementConfig: {
        id: '${apiManagementResources.outputs.apimServiceID}/apis/model-prediction-api'
      }
  }
  dependsOn: [
    apiManagementResources
  ]
}
