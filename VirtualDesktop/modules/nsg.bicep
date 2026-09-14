targetScope = 'resourceGroup'

param nsgName string
param commonTags object = {}
type securityRuleConfiguration = {
  name: string
  description: string
  priority: int
  direction: 'Inbound' | 'Outbound'
  access: 'Allow' | 'Deny'
  protocol: string
  sourceAddressPrefix: string
  sourcePortRange: string
  destinationAddressPrefix: string
  destinationPortRange: string
  sourceAddress: string
}

param securityRules securityRuleConfiguration[] = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-09-01' = {
  name: nsgName
  location:resourceGroup().location
  tags: union(commonTags, {component: 'network-security'})
  properties: {
    securityRules: [
      for rule in securityRules: {
        name: rule.name
        properties: {
          description: rule.description
          priority: rule.priority
          direction: rule.direction
          access: rule.access
          protocol: rule.protocol
          sourceAddressPrefix: rule.sourceAddressPrefix
          sourcePortRange: rule.sourcePortRange
          destinationAddressPrefix: rule.destinationAddressPrefix
          destinationPortRange: rule.destinationPortRange
        }
      }
    ]
  }
}

output nsgId string = nsg.id
