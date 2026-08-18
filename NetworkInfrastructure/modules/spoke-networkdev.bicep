targetScope = 'resourceGroup'

// Create dev virtual network

//
param devWebNsgId string 

resource devspokevnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: 'development-spoke-vnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {addressPrefixes: ['10.1.0.0/16']}
  }
}

// Set the parent: to prodspokevnet so the resource understands where to live

resource devwebSubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'devwebsubnet1'
  parent: devspokevnet
  properties: {
    addressPrefix: '10.1.1.0/24'
    networkSecurityGroup: {id: devWebNsgId}
  }
}

resource devweb2SubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'devwebsubnet2'
  parent: devspokevnet
  properties: {
    addressPrefix: '10.1.2.0/24'
    networkSecurityGroup: {id: devWebNsgId}
  }
}

resource devweb3SubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'devwebsubnet3'
  parent: devspokevnet
  properties: {
    addressPrefix: '10.1.3.0/24'
    networkSecurityGroup: {id: devWebNsgId}
  }
}

output devVnetName string = devspokevnet.name
output devVnetId string = devspokevnet.id
