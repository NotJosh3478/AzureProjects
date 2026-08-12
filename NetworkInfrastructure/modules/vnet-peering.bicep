targetScope = 'resourceGroup'

param localVnetName string
param remoteVnetId string
param peeringName string
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource localVnet 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-07-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

