targetScope = 'resourceGroup'

param vdiApplicationGroupId string
param workspaceName string
param commonTags object = {}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2025-10-10' = {
  name: workspaceName
  location: resourceGroup().location
  tags: union(commonTags, {component: 'workspace'})
  properties: {applicationGroupReferences: [vdiApplicationGroupId]}
}
