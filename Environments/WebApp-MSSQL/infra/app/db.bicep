param name string
param location string = resourceGroup().location
param tags object = {}
param databaseName string
param keyVaultName string

@secure()
param sqlAdminPassword string = ''

@secure()
param appUserPassword string = ''

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// generate random keyvault secrets
module keyvaultSecretsGenerator './keyvault-secrets-generator.bicep' = {
  name: 'secretsGeneration'
  params: {
    keyVaultName: keyVaultName
    secretNames: [
      'sqlAdminPassword'
      'appUserPassword'
    ]
    location: location
  }
}

module sqlServer '../core/database/sqlserver/sqlserver.bicep' = {
  name: 'sqlserver'
  params: {
    name: name
    location: location
    tags: tags
    databaseName: databaseName
    keyVaultName: keyVaultName
    sqlAdminPassword: !empty(sqlAdminPassword) ? sqlAdminPassword: keyVault.getSecret(keyvaultSecretsGenerator.outputs.results.sqlAdminPassword)
    appUserPassword: !empty(appUserPassword) ? appUserPassword: keyVault.getSecret(keyvaultSecretsGenerator.outputs.results.appUserPassword)
  }
}

output connectionStringKey string = sqlServer.outputs.connectionStringKey
output databaseName string = sqlServer.outputs.databaseName
