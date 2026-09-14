targetScope = 'subscription'

param rgName string = 'az-Virtual-Desktop-RG'
param prefix string = 'avd'
@allowed([
  'prod'
  'dev'
])
param environment string = 'prod'

param adminUsernameSecretUri string
param adminPasswordSecretUri string

var vNetName = '${prefix}-vnet-${environment}'
var sessionHostSubnetName = '${prefix}-snet-${environment}-sessionhosts'
var hostPoolName = '${prefix}-hp-${environment}'
var sessionHostsName = '${prefix}-shosts-${environment}'

resource avdResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: rgName
}

resource existingVnet 'Microsoft.Network/virtualNetworks@2025-09-01' existing = {
  scope: avdResourceGroup
  name: vNetName
}

resource existingSessionHostSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: existingVnet
  name: sessionHostSubnetName
}

module sessionHosts 'modules/sessionHost.bicep' = {
  scope: avdResourceGroup
  name: sessionHostsName
  params: {
    vdiHostPoolName: hostPoolName
    subnetId: existingSessionHostSubnet.id
    environment: environment
    prefix: prefix
    adminUsernameSecretUri: adminUsernameSecretUri
    adminPasswordSecretUri: adminPasswordSecretUri
  }
}
