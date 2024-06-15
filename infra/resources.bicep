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

resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${prefix}-plan'
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
    size: 'FC'
    family: 'FC'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2023-12-01' = {
  name: '${prefix}-function-app'
  location: location
  tags: union(tags, {
    'azd-service-name': 'api'
   })
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}deploymentpackage'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 2048
        maximumInstanceCount: 100
      }
      runtime: {
        name: 'python'
        version: '3.11'
      }
    }
  }


  resource configAppSettings 'config' = {
    name: 'appsettings'
    properties: {
        AzureWebJobsStorage__accountName: storageAccount.name
        APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
        FUNCTIONS_EXTENSION_VERSION: '~4'
    }
  }
}


var storageBlobDataOwnerRoleDefinitionId  = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' //Storage Blob Data Owner
var storageAccountDataContributorRoleDefinitionId  = '17d1049b-9a84-46fb-8f53-869881c3d3ab' //Storage Account Contributor
var storageQueueDataContributorRoleDefinitionId  = '974c5e8b-45b9-4653-ba55-5f855dd0fb88' //Storage Queue Data Contributor

resource role1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id,
             principalId, storageBlobDataOwnerRoleDefinitionId)
  properties: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',
      storageBlobDataOwnerRoleDefinitionId)
  }
}

resource role2 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id,
             principalId, storageAccountDataContributorRoleDefinitionId)
  properties: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',
    storageAccountDataContributorRoleDefinitionId)
  }
}

resource role3 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id,
             principalId, storageQueueDataContributorRoleDefinitionId)
  properties: {
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',
    storageQueueDataContributorRoleDefinitionId)
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
