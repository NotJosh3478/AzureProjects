targetScope = 'resourceGroup'

param vdiHostPoolId string
param applicationGroupName string
param commonTags object = {}

resource vdiApplicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2025-10-10' = {
  name: applicationGroupName
  location: resourceGroup().location
  tags: union(commonTags, {component: 'vdi-application-group'})
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: vdiHostPoolId
  }
}

output vdiApplicationGroupId string = vdiApplicationGroup.id
