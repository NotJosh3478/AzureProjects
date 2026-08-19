targetScope = 'resourceGroup'

type subnetConfiguration = {
  name: string
  addressPrefix: string
}

param vnetName string
param addressPrefixes string[]
param subnets subnetConfiguration[]
param location string = resourceGroup().location
param tags object = {}



param nsgId string

resource spokeVnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {addressPrefixes:addressPrefixes}
  }
}

resource spokeSubnets 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = [
  for subnet in subnets: {
    parent: spokeVnet
    name: subnet.name
    properties: {
      addressPrefix: subnet.addressPrefix
      networkSecurityGroup: {id: nsgId}
    }
  }
]

output vnetName string = spokeVnet.name
output vnetId string = spokeVnet.id

output subnetIds array = [
  for (subnet, index) in subnets: {
    name: subnet.name
    id: spokeSubnets[index].id
  }
]
