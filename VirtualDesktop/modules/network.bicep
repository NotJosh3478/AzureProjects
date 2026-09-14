targetScope = 'resourceGroup'

type subnetConfiguration = {
  name: string
  addressPrefix: string
  nsgId: string
}

param vNetName string
param addressPrefixes string[]
param subnets subnetConfiguration[]
param commonTags object = {}

resource vdiNetwork 'Microsoft.Network/virtualNetworks@2025-09-01' = {
  name: vNetName
  location: resourceGroup().location
  tags: union(commonTags, {component: 'networking'})
  properties: {
    addressSpace: {
      addressPrefixes:addressPrefixes
    }
  }
}

resource vdiNetworkSubnets 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = [for (subnet, index) in subnets: {
  parent: vdiNetwork
  name: subnet.name
  properties: {
    addressPrefix: subnet.addressPrefix
    networkSecurityGroup: {
      id: subnet.nsgId
    }
  }
}]

output vnetName string = vdiNetwork.name
output vnetId string = vdiNetwork.id

output subnetIds array = [
  for (subnet, index) in subnets: {
    name: subnet.name
    id: vdiNetworkSubnets[index].id
  }
]

