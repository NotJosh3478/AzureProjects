targetScope = 'resourceGroup'

param principalId string
param hostPoolName string

var desktopVirtualizationVmContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'a959dbd1-f747-45e3-8ba6-dd80f235f97c'
)

resource vmContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(
    resourceGroup().id,
    hostPoolName,
    desktopVirtualizationVmContributorRoleId
    //Remove hostPoolName and replace with principalId during actual deployment
  )

  properties: {
    principalId: principalId
    roleDefinitionId: desktopVirtualizationVmContributorRoleId
    principalType: 'ServicePrincipal'
  }
}
