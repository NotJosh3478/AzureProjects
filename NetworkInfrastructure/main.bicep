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
module devWebNsg './modules/nsgs.bicep' = {
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




// Create Prod network and subnets
module prodSpokeNetwork 'modules/spoke-network.bicep' = {
  name: 'deploy-production-spoke-network'
  scope: productionresourcegroup
  params: {
    vnetName: 'production-spoke-vnet'
    addressPrefixes: ['10.0.0.0/16']  
    subnets: [
      {
        name: 'prodwebsubnet1'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'prodwebsubnet2'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'prodwebsubnet3'
        addressPrefix: '10.0.3.0/24'
      }
    ]
    nsgId: prodWebNsg.outputs.nsgId
    tags: union(commonTags, {environment: 'production'})
  }
}

// Create Dev network and subnets
module devSpokeNetwork 'modules/spoke-network.bicep' = {
  name: 'deploy-development-spoke-network'
  scope: developmentresourcegroup
  params: {
    vnetName: 'production-spoke-vnet'
    addressPrefixes: ['10.1.0.0/16']  
    subnets: [
      {
        name: 'devwebsubnet1'
        addressPrefix: '10.1.1.0/24'
      }
      {
        name: 'devwebsubnet2'
        addressPrefix: '10.1.2.0/24'
      }
      {
        name: 'devwebsubnet3'
        addressPrefix: '10.1.3.0/24'
      }
    ]
    nsgId: prodWebNsg.outputs.nsgId
    tags: union(commonTags, {environment: 'development'})
  }
}



// Create Hub network and subnets
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
    remoteVnetId: prodSpokeNetwork.outputs.vnetId
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
    localVnetName: prodSpokeNetwork.outputs.vnetName
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
    remoteVnetId: devSpokeNetwork.outputs.vnetId
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
    localVnetName: devSpokeNetwork.outputs.vnetName
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
