targetScope = 'resourceGroup'


// Create the production spoke vnet
resource prodspokevnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: 'production-spoke-vnet'
  location: resourceGroup().location
  properties: {
    addressSpace: {addressPrefixes: ['10.0.0.0/16']}
  }
}

// Set the parent: to prodspokevnet so the resource understands where to live

resource prodwebSubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'prodwebsubnet'
  parent: prodspokevnet
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
}

resource prodweb2SubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'prodwebsubnet2'
  parent: prodspokevnet
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

resource prodweb3SubNet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  name: 'prodwebsubnet3'
  parent: prodspokevnet
  properties: {
    addressPrefix: '10.0.3.0/24'
  }
}

output prodVnetName string = prodspokevnet.name
output prodVnetId string = prodspokevnet.id
