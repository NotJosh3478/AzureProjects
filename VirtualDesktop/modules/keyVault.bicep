targetScope = 'resourceGroup'
param keyVaultName string

param commonTags object = {}
param tenantId string = tenant().tenantId



resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' = {
  name: keyVaultName
  location: resourceGroup().location
  tags: union(commonTags, {component: 'key-vault'})
  properties: {
    tenantId: tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    // Security and Access Control Configuration
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
    
    // Deployment Permissions
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri

