targetScope = 'subscription'

// Switch for Gateway and Public IP creation
param deployVPNGateway bool = false

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

// Create production spoke network and subnets
module prodspokenetwork './modules/spoke-networkprod.bicep' = {
  name: 'deploy-production-spoke-network'
  scope: productionresourcegroup
}
// Create development spoke network and subnets
module devspokenetwork 'modules/spoke-networkdev.bicep' = {
  name: 'deploy-development-spoke-network'
  scope: developmentresourcegroup
}
// Create hub network and subnets
module hubnetwork 'modules/hub-network.bicep' = {
  name: 'deploy-hub-network'
  scope: hubnetworkresourcegroup
}

// Hub connection to production
module hubToProdPeering 'modules/vnet-peering.bicep' = {
  name: 'peer-hub-to-production'
  scope: hubnetworkresourcegroup
  params: {
    localVnetName: hubnetwork.outputs.hubVnetName
    remoteVnetId: prodspokenetwork.outputs.prodVnetId
    peeringName: 'hub-to-production'
    allowGatewayTransit: deployVPNGateway
    useRemoteGateways: false
  }
  dependsOn: [
    hubVpnGateway
  ]
}

// Production connection to hub
module prodToHubPeering 'modules/vnet-peering.bicep' = {
  name: 'peer-production-to-hub'
  scope: productionresourcegroup
  params: {
    localVnetName: prodspokenetwork.outputs.prodVnetName
    remoteVnetId: hubnetwork.outputs.hubVnetId
    peeringName: 'production-to-hub'
    allowGatewayTransit: false
    useRemoteGateways: deployVPNGateway
  }
  dependsOn: [
    hubToProdPeering
  ]
}

// Hub connection to development
module hubToDevPeering 'modules/vnet-peering.bicep' = {
  name: 'peer-hub-to-development'
  scope: hubnetworkresourcegroup
  params: {
    localVnetName: hubnetwork.outputs.hubVnetName
    remoteVnetId: devspokenetwork.outputs.devVnetId
    peeringName: 'hub-to-development'
    allowGatewayTransit: deployVPNGateway
    useRemoteGateways: false
  }
  dependsOn: [
    hubVpnGateway
  ]
}

// Development connection to hub
module devToHubPeering 'modules/vnet-peering.bicep' = {
  name: 'peer-dev-to-hub'
  scope: developmentresourcegroup
  params: {
    localVnetName: devspokenetwork.outputs.devVnetName
    remoteVnetId: hubnetwork.outputs.hubVnetId
    peeringName: 'dev-to-hub'
    allowGatewayTransit: false
    useRemoteGateways: deployVPNGateway
  }
  dependsOn: [
    hubToDevPeering
  ]
}

// Gateway creation
module hubVpnGateway 'modules/gateway.bicep' = if (deployVPNGateway) {
  name: 'deploy-hub-vpn-gateway'
  scope: hubnetworkresourcegroup
  params: {
    gatewaySubnetId: hubnetwork.outputs.gatewaySubnetId
    gatewayName: 'hub-vpn-gateway'
    publicIPName: 'hub-vpn-gateway-pip'
    gatewaySKU: 'VpnGw1AZ'
  }
}
