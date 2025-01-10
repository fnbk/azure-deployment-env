//
// Parameters
//

@minLength(1)
@maxLength(64)
@description('Name of the the environment.')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Id of the user or app to assign application roles')
param userOrAppId string = ''

@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string = ''

@secure()
@description('Application user password')
param appUserPassword string = ''

//
// Variables
//

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

//
// KeyVault
//

// Create keyvault
module keyVault './core/security/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: 'kv-${resourceToken}'
    location: location
    tags: tags
  }
}

// Give user access to KeyVault (if the user ID is provided)
module userKeyVaultAccess './core/security/keyvault-access.bicep' = if (!empty(userOrAppId)) {
  name: 'user-keyvault-access'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: userOrAppId
  }
}

// Give the WebApp access to KeyVault
module apiKeyVaultAccess './core/security/keyvault-access.bicep' = {
  name: 'api-keyvault-access'
  params: {
    keyVaultName: keyVault.outputs.name
    principalId: web.outputs.SERVICE_WEB_IDENTITY_PRINCIPAL_ID
  }
}

//
// Database
//

// Create database
module sqlServer './app/db.bicep' = {
  name: 'sql'
  params: {
    name: 'sql-${resourceToken}'
    location: location
    tags: tags
    databaseName: 'GreekWineContext'
    sqlAdminPassword: sqlAdminPassword
    appUserPassword: appUserPassword
    keyVaultName: keyVault.outputs.name
  }
}

//
// App
//

// Create an App Service Plan to host Web Application
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  params: {
    name: 'plan-${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B2'
    }
  }
}

// Create a Web Application hosted on App Service Plan
module web './app/web.bicep' = {
  name: 'web'
  params: {
    name: 'app-web-${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    keyVaultName: keyVault.outputs.name
    appSettings: {
      AZURE_SQL_CONNECTION_STRING_KEY: sqlServer.outputs.connectionStringKey
    }
  }
}

//
// Outputs
//

output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_LOCATION string = location
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_SQL_CONNECTION_STRING_KEY string = sqlServer.outputs.connectionStringKey
