targetScope = 'subscription'

// Location for the production resource group
param prodlocation string

// Location for the development resource group
param devlocation string

param productionresourcegroupname string = 'production-resourcegroup'

param developmentresourcegroupname string = 'development-resourcegroup'

param hubnetworkresourcegroupname string = 'hubnetwork-resourcegroup'

resource productionresourcegroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: productionresourcegroupname
  location: prodlocation
}

resource developmentresourcegroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: developmentresourcegroupname
  location: devlocation
}

resource hubnetworkresourcegroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: hubnetworkresourcegroupname
  location: prodlocation
}

module prodspokenetwork './modules/spoke-networkprod.bicep' = {
  name: 'deploy-production-spoke-network'
  scope: productionresourcegroup
}

module devspokenetwork 'modules/spoke-networkdev.bicep' = {
  name: 'deploy-development-spoke-network'
  scope: developmentresourcegroup
}

module hubnetwork 'modules/hub-network.bicep' = {
  name: 'deploy-hub-network'
  scope: hubnetworkresourcegroup
}
