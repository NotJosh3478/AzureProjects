targetScope = 'subscription'

// Switch for Gateway and Public IP creation
param deployVPNGateway bool = false

// Location for the production resource group
param prodlocation string

// Location for the development resource group
param devlocation string

// Create resource groups [production-resourcegroup, development-resourcegroup, hubnetwork-resourcegroup]
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

// Create reusable tag variables
var commonTags = {
  project: 'hub-spoke-network'
  managedBy: 'Bicep'
}

// Create NSGs
module prodWebNsg './modules/nsgs.bicep' = {
  name: 'deploy-production-web-nsg'
  scope: productionresourcegroup
  params: {
    nsgName: 'production-web-nsg'
    tags: union(commonTags, {
      environment: 'production'
    })
    securityRules: [
      {
        name: 'Allow-Https-From-Internet'
        description: 'Allow HTTPS traffic to the web tier'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '443'
      }
    ]
  }
}

// Create NSGs
module devdWebNsg './modules/nsgs.bicep' = {
  name: 'deploy-development-web-nsg'
  scope: developmentresourcegroup
  params: {
    nsgName: 'development-web-nsg'
    tags: union(commonTags, {
      environment: 'development'
    })
    securityRules: [
      {
        name: 'Allow-Https-From-Internet'
        description: 'Allow HTTPS traffic to the web tier'
        priority: 100
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourceAddressPrefix: 'Internet'
        sourcePortRange: '*'
        destinationAddressPrefix: '*'
        destinationPortRange: '443'
      }
    ]
  }
}




// Create production spoke network and subnets
module prodspokenetwork './modules/spoke-networkprod.bicep' = {
  name: 'deploy-production-spoke-network'
  scope: productionresourcegroup
  params: {prodWebNsgId: prodWebNsg.outputs.nsgId}
}
// Create development spoke network and subnets
module devspokenetwork 'modules/spoke-networkdev.bicep' = {
  name: 'deploy-development-spoke-network'
  scope: developmentresourcegroup
  params: {devWebNsgId: devdWebNsg.outputs.nsgId}
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
