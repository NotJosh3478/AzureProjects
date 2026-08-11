targetScope = 'resourceGroup'

type subnetConfiguration = {
  name: string
  addressPrefix: string
}

param hubSubnets subnetConfiguration[] = [
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.255.0.0/26'
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.255.0.64/26'
  }
  {
    name: 'GatewaySubnet'
    addressPrefix: '10.255.0.128/27'
  }
  {
    name: 'shared-services-subnet'
    addressPrefix: '10.255.1.0/24'
  }
]




resource hubnetwork 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: 'hub-virtual-network'
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.255.0.0/16']
    }
  }
}

resource virtualhubsubnets 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = [
  for subnet in hubSubnets: { 
    parent: hubnetwork
    name: subnet.name
    properties: {addressPrefix: subnet.addressPrefix}

  }
]

output hubSubnetIds array = [
  for (subnet, index) in hubSubnets: {
    name: subnet.name
    id: virtualhubsubnets[index].id
  }
]
