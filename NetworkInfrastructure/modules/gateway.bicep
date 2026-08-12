targetScope = 'resourceGroup'

param gatewaySubnetId string
param gatewayName string = 'hub-vpn-gateway'
param publicIPName string = 'hub-vpn-gateway-pip'

param gatewaySKU string = 'VpnGw1AZ'

resource gatewayPublicIP 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: publicIPName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2025-07-01' = {
  name: gatewayName
  location: resourceGroup().location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'

    activeActive: false
    enableBgp: false
    enablePrivateIpAddress: false

    sku: {
      name: gatewaySKU
      tier: gatewaySKU
    }
    ipConfigurations: [
      {
        name: 'gateway-ip-configuration'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayPublicIP.id
          }
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
  }


}

output gatewayId string = vpnGateway.id
output publicIPId string = gatewayPublicIP.id
output publicIPAddress string = gatewayPublicIP.properties.ipAddress
