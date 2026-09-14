targetScope = 'resourceGroup'

param subnetId string
param environment string
param prefix string


@description('Set the admin username and password')
param adminUsernameSecretUri string
param adminPasswordSecretUri string

param vdiHostPoolName string

@description('Set the limit for sessions created in the session host pool')
@allowed([
  1, 2, 3, 4
])
param sessionHostCount int = 1

// Output created from hostPool.bicep to connect the sessions to the host pool
resource hostpoolref 'Microsoft.DesktopVirtualization/hostPools@2025-10-10' existing = {
  name: vdiHostPoolName
}

resource sessionHosts 'Microsoft.DesktopVirtualization/hostPools/sessionHostConfigurations@2026-04-01-preview' = {
  name: 'default'
  parent: hostpoolref
  properties: {
    diskInfo: {managedDisk: {type: 'StandardSSD_LRS'}}
    domainInfo: {
      joinType: 'AzureActiveDirectory'
    }
    imageInfo: {
      type: 'Marketplace'
      // Marketplace image definitions require publisher, offer, and sku
      marketplaceInfo: {
        sku: 'win11-24H2-avd'
        exactVersion: '26100.9445.260908'
        offer: 'Windows-11'
        publisher: 'MicrosoftWindowsDesktop'
      }
    }
    networkInfo: {
      subnetId: subnetId
    }
    vmAdminCredentials: {
      passwordKeyVaultSecretUri: adminPasswordSecretUri
      usernameKeyVaultSecretUri: adminUsernameSecretUri
    }
    vmNamePrefix: '${prefix}sh${environment}'
    //2 vCPUs 8 GiB RAM
    vmSizeId: 'Standard_D2as_v6'
  }
}

resource sessionHostManagement 'Microsoft.DesktopVirtualization/hostPools/sessionHostManagements@2026-04-01-preview' = {
  parent: hostpoolref
  name: 'default'
  properties: {
    scheduledDateTimeZone: 'UTC'
    provisioning: {
      instanceCount: sessionHostCount
      setDrainMode: false
      canaryPolicy: 'Never'
    } 
    update: {
      deleteOriginalVm: false
      logOffDelayMinutes: 5
      maxVmsRemoved: 1
      logOffMessage: 'Your session will be logged off for scheduled host maintenance.'
    }
  }
}



