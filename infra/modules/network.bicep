@description('Azure region for the VNet')
param location string

@description('Name of the VNet')
param vnetName string

@description('VNet address prefix')
param vnetAddressPrefix string = '10.20.0.0/16'

@description('Session hosts subnet name')
param sessionHostSubnetName string = 'snet-avd-sessionhosts'

@description('Session hosts subnet prefix')
param sessionHostSubnetPrefix string = '10.20.1.0/24'

@description('Private endpoints subnet name')
param privateEndpointSubnetName string = 'snet-avd-privateendpoints'

@description('Private endpoints subnet prefix')
param privateEndpointSubnetPrefix string = '10.20.2.0/24'

@description('Optional resource ID of the hub virtual network to peer with the new spoke VNet.')
param hubVnetResourceId string = ''

@description('When true, omits the Microsoft.Storage service endpoint from the session host subnet. Set to true when a private endpoint is used for FSLogix storage.')
param removeStorageServiceEndpoint bool = false

@description('Tags for all resources')
param tags object = {}

var hubVnetSegments = split(hubVnetResourceId, '/')
var hubVnetResourceGroupName = !empty(hubVnetResourceId) ? hubVnetSegments[4] : ''
var hubVnetName = !empty(hubVnetResourceId) ? hubVnetSegments[8] : ''

module natGatewayPublicIp 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  name: take('avm.res.network.public-ip-address.${vnetName}.natgw', 64)
  params: {
    name: '${vnetName}-natgw-pip'
    location: location
    tags: tags
    skuName: 'Standard'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    enableTelemetry: false
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:1.4.0' = {
  name: take('avm.res.network.nat-gateway.${vnetName}', 64)
  params: {
    name: '${vnetName}-natgw'
    location: location
    availabilityZone: -1
    publicIpResourceIds: [
      natGatewayPublicIp.outputs.resourceId
    ]
    idleTimeoutInMinutes: 4
    tags: tags
    enableTelemetry: false
  }
}

var subnets = [
  {
    name: sessionHostSubnetName
    addressPrefixes: [
      sessionHostSubnetPrefix
    ]
    networkSecurityGroupResourceId: nsgSessionHosts.outputs.resourceId
    natGatewayResourceId: natGateway.outputs.resourceId
    serviceEndpoints: removeStorageServiceEndpoint ? [] : [
      'Microsoft.Storage'
    ]
  }
  {
    name: privateEndpointSubnetName
    addressPrefixes: [
      privateEndpointSubnetPrefix
    ]
    networkSecurityGroupResourceId: nsgPrivateEndpoints.outputs.resourceId
  }
]

module nsgPrivateEndpoints 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: take('avm.res.network.network-security-group.nsg-avd-privateendpoints.${vnetName}', 64)
  params: {
    name: 'nsg-avd-privateendpoints'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
    enableTelemetry: false
  }
}

module nsgSessionHosts 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: take('avm.res.network.network-security-group.nsg-avd-sessionhosts.${vnetName}', 64)
  params: {
    name: 'nsg-avd-sessionhosts'
    location: location
    tags: tags
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
    enableTelemetry: false
  }
}

module vnet 'br/public:avm/res/network/virtual-network:0.7.2' = {
  name: take('avm.res.network.virtual-network.${vnetName}', 64)
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: subnets
    tags: tags
    enableTelemetry: false
  }
}

resource vnetResource 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = if (!empty(hubVnetResourceId)) {
  parent: vnetResource
  name: '${vnet.name}-to-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetResourceId
    }
  }
}

module hubPeering './hubPeering.bicep' = if (!empty(hubVnetResourceId)) {
  name: '${vnetName}-hub-peering'
  scope: resourceGroup(hubVnetResourceGroupName)
  params: {
    hubVnetName: hubVnetName
    spokeVnetName: vnet.outputs.name
    spokeVnetResourceId: vnet.outputs.resourceId
  }
}

output vnetId string = vnet.outputs.resourceId
output sessionHostSubnetId string = vnet.outputs.subnetResourceIds[0]
output privateEndpointSubnetId string = vnet.outputs.subnetResourceIds[1]
