targetScope = 'resourceGroup'

// Azure region for the network security group
param location string = resourceGroup().location
param nsgName string

// Tags applied to the network security group
param tags object = {}

// Security rule protocols
type securityRuleProtocol = '*' | 'Ah' | 'Esp' | 'Icmp' | 'Tcp' | 'Udp'


type securityRuleConfiguration = {
  name: string
  description: string
  priority: int
  direction: 'Inbound' | 'Outbound'
  access: 'Allow' | 'Deny'
  protocol: securityRuleProtocol
  sourceAddressPrefix: string
  sourcePortRange: string
  destinationAddressPrefix: string
  destinationPortRange: string
}

param securityRules securityRuleConfiguration[] = []

resource nsg 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgName
  location: location
  tags: tags
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
output nsgName string = nsg.name

