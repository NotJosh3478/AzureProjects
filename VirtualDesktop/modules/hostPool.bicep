targetScope = 'resourceGroup'

param commonTags object = {}
param hostPoolName string
param maxSessionLimit int

@description('Originally used a stable branch for hostpool but the newer 2026-04-01-preview allows for auto management with session host configuration')
resource vdiHostPool 'Microsoft.DesktopVirtualization/hostPools@2026-04-01-preview' = {
  name: hostPoolName
  location: resourceGroup().location
  tags: union(commonTags, {component: 'hostpool'})
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: maxSessionLimit
    managementType: 'Automated'
    //This set SSO through Entra authentication when connecting to the VMs
    customRdpProperty: 'enablerdsaadauth:i:1;'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output vdiHostPoolId string = vdiHostPool.id
output vdiHostPoolName string = vdiHostPool.name
output hostPoolPrincipalId string = vdiHostPool.identity.principalId
