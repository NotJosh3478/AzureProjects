targetScope = 'subscription'

@allowed ([
  'dev'
  'prod'
])
param environment string = 'prod'
param prefix string = 'avd'

var hostPoolName = '${prefix}-hp-${environment}'
var workspaceName = '${prefix}-ws-${environment}'
var applicationGroupName = '${prefix}-dag-${environment}'
var vNetName = '${prefix}-vnet-${environment}'
var kVRbacName = '${prefix}-kv-rbac-${environment}'


// Original var keyVaultName = '${prefix}-kv-${environment}-${uniqueString(subscription().id)}' created a name longer than 24 characters and caused errors this now takes the first 12 characters
var keyVaultName = '${prefix}-kv-${environment}-${take(uniqueString(subscription().id), 12)}'


@description('Set the location for the resource group and all resources, default is westus2')
@allowed([
  'westus2'
  'eastus'
])
param location string = 'westus2'
@description('Name for Virtual Desktop resource group')
param rgName string = 'az-Virtual-Desktop-RG'

@description('Common tags')
var commonTags = {
  project: 'azure-virtual-desktop'
  managedBy: 'Bicep'
  workload: 'avd'
  purpose: 'virtual-desktop'
  environment: environment
}

@description('Set the max session limits for each vm create 8 = each vm can have 8 users connected')
param maxSessionLimit int = 8

@description('Subnet creation?')
var subnetsConfigs =  [
      {
        name: '${prefix}-snet-${environment}-sessionhosts'
        addressPrefix: '10.0.1.0/24'
        nsgName: '${prefix}-nsg-${environment}-sessionhosts'
        securityRules: [
  {
      name: 'Deny-Internet-RDP'
      description: 'Deny inbound RDP directly from the Internet'
      priority: 100
      direction: 'Inbound'
      access: 'Deny'
      protocol: 'Tcp'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  {
      name: 'Allow-AVD-HTTPS'
      description: 'Allow AVD service traffic over HTTPS'
      priority: 200
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'WindowsVirtualDesktop'
      destinationPortRange: '443'
    }
  {
      name: 'Allow-AVD-UDP-Relay'
      description: 'Allow AVD relayed RDP connectivity'
      priority: 210
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Udp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'WindowsVirtualDesktop'
      destinationPortRange: '3478'
    }
  {
      name: 'Allow-Entra-ID'
      description: 'Allow Microsoft Entra ID authentication'
      priority: 220
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'AzureActiveDirectory'
      destinationPortRange: '443'
    }
  {
      name: 'Allow-Azure-Monitor'
      description: 'Allow Azure Monitor and AVD agent monitoring traffic'
      priority: 230
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'AzureMonitor'
      destinationPortRange: '443'
    }
  {
      name: 'Allow-Windows-Activation'
      description: 'Allow Windows activation through Azure KMS'
      priority: 240
      direction: 'Outbound'
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: 'Internet'
      destinationPortRange: '1688'
    }
  
// {
//      name: 'Allow-FSLogix-SMB'
//      description: 'Allow SMB access to FSLogix profile storage'
//      priority: 250
//      direction: 'Outbound'
//      access: 'Allow'
//      protocol: 'Tcp'
//      sourceAddressPrefix: 'VirtualNetwork'
//      sourcePortRange: '*'
//      destinationAddressPrefix: '<FSLogix-private-endpoint-IP>'
//      destinationPortRange: '445'
    //}
]
      }
      {
        name: '${prefix}-snet-${environment}-private-endpoints'
        addressPrefix: '10.0.2.0/28'
        nsgName: '${prefix}-nsg-${environment}-private-endpoints'
        securityRules: [
          {      
      name: 'Allow-FSLogix-SMB'
      description: 'Allow SMB access to FSLogix profile storage'       
      priority: 100    
      direction: 'Inbound' 
      access: 'Allow'
      protocol: 'Tcp'
      sourceAddressPrefix: '10.0.1.0/24'
      sourcePortRange: '*'
      destinationAddressPrefix: '10.0.2.0/28'
      destinationPortRange: '445'
            }
            
          
          {     
      name: 'Deny-Vnet-Workloads'
      description: 'Prevent other VNet workloads reaching private endpoints'       
      priority: 900    
      direction: 'Inbound' 
      access: 'Deny'
      protocol: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
        ]
      }
      {
        name: '${prefix}-snet-${environment}-management'
        addressPrefix: '10.0.2.16/28'
        nsgName: '${prefix}-nsg-${environment}-management'
        securityRules: [

        ]
      }
    ]





@description('Create azVirtualDesktopRG')
resource azVirtualDesktopRG 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: rgName
  location: location
  tags: commonTags
}


@description('Create VDI network')
module vdiNetwork 'modules/network.bicep' = {
  scope: azVirtualDesktopRG
  name: vNetName
  params: {
    vNetName: vNetName
    commonTags: commonTags
    addressPrefixes: ['10.0.0.0/20']
    subnets: [for (subnet, index) in subnetsConfigs: {
      name: subnet.name
      addressPrefix: subnet.addressPrefix
      nsgId: subnetNsg[index].outputs.nsgId
    }]
  }
}

module subnetNsg 'modules/nsg.bicep' = [for (subnet, index) in subnetsConfigs: {
  scope: azVirtualDesktopRG
  name: '${subnet.nsgName}-deployment'
  params: {
    nsgName: subnet.nsgName
    commonTags: commonTags
    securityRules: subnet.securityRules
  }
}]



@description('Create hostPool')
module vdiHostPool 'modules/hostPool.bicep' = {
  scope: azVirtualDesktopRG
  name: hostPoolName
  params: {
    commonTags: commonTags
    hostPoolName: hostPoolName
    maxSessionLimit: maxSessionLimit
  }
}

@description('Create applicationGroup')
module applicationGroup 'modules/applicationGroup.bicep' = {
  scope: azVirtualDesktopRG
  name: applicationGroupName
  params: {
    commonTags: commonTags
    vdiHostPoolId: vdiHostPool.outputs.vdiHostPoolId
    applicationGroupName: applicationGroupName
  }
}

@description('Create workspace')
module workspace 'modules/workspace.bicep' = {
  scope: azVirtualDesktopRG
  name: workspaceName
  params: {
    commonTags: commonTags
    vdiApplicationGroupId: applicationGroup.outputs.vdiApplicationGroupId
    workspaceName: workspaceName
  }
}
@description('Create keyvault')
module keyVault 'modules/keyVault.bicep' = {
  scope: azVirtualDesktopRG
  name: '${prefix}-keyvault-${environment}-deployment'
  params: {
    keyVaultName: keyVaultName
    commonTags: commonTags
  }
}

module keyVaultRoleAssignment 'modules/keyVaultRoleAssignment.bicep' = {
  scope: azVirtualDesktopRG
  name: kVRbacName
  params: {
    hostPoolName: hostPoolName // REMOVE HOSTPOOL FROM KEYVAULTROLEASSIGNMENT AND ROLEASSIGNMENT DURING ACTUAL DEPLOYMENT
    keyVaultName: keyVaultName
    principalId: vdiHostPool.outputs.hostPoolPrincipalId
  }
  dependsOn: [
    keyVault
  ]
}

@description('Give host pool identity permission to manage session host VMs')
module hostPoolVmRoleAssignment 'modules/roleAssignment.bicep' = {
  scope: azVirtualDesktopRG
  name: '${prefix}-vm-rbac-${environment}'

  params: {
    hostPoolName: hostPoolName // REMOVE HOSTPOOL FROM KEYVAULTROLEASSIGNMENT AND ROLEASSIGNMENT DURING ACTUAL DEPLOYMENT
    principalId: vdiHostPool.outputs.hostPoolPrincipalId
  }
}
