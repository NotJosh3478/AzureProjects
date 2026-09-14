targetScope = 'resourceGroup'

param keyVaultName string
param principalId string
param hostPoolName string

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, hostPoolName, 'KeyVaultSecretsUser')
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '4633458b-17de-408a-b874-0445c86b69e6'
    )
    principalType: 'ServicePrincipal'
  }
}
