// ─────────────────────────────────────────────────────────────────────────────
// FSLogix Private Endpoint + Private DNS
//
// Deploys:
//   1. Private endpoint for the FSLogix storage account (file sub-resource)
//      placed in the private endpoint subnet.
//   2. Private DNS zone: privatelink.file.core.windows.net
//   3. VNet link — links the DNS zone to the spoke VNet so session hosts
//      resolve the storage account FQDN to its private IP automatically.
//   4. DNS zone group on the private endpoint — auto-registers the A record
//      in the zone when the endpoint is provisioned.
//
// Scope: Greenfield and isolated Brownfield (CreateNew DNS mode).
// Enterprise hub-spoke DNS: set privateDnsZoneMode = 'Skip' and register
// the A record in your central zone manually or via policy.
// ─────────────────────────────────────────────────────────────────────────────

@description('Azure region')
param location string

@description('Resource ID of the FSLogix storage account')
param storageAccountId string

@description('Resource ID of the private endpoint subnet (snet-avd-privateendpoints)')
param privateEndpointSubnetId string

@description('Resource ID of the spoke VNet — used to link the private DNS zone')
param vnetId string

@description('DNS zone management mode. CreateNew creates and links the zone. Skip deploys the PE only.')
@allowed(['CreateNew', 'Skip'])
param privateDnsZoneMode string = 'CreateNew'

@description('Tags for all resources')
param tags object = {}

var storageAccountName = last(split(storageAccountId, '/'))
var privateEndpointName = 'pe-${storageAccountName}-file'
// Use environment() to stay compatible with sovereign clouds (Azure Government, China, etc.)
var privateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = if (privateDnsZoneMode == 'CreateNew') {
  name: take('avm.res.network.private-dns-zone.${storageAccountName}.file', 64)
  params: {
    name: privateDnsZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: 'link-${last(split(vnetId, '/'))}'
        virtualNetworkResourceId: vnetId
        registrationEnabled: false
      }
    ]
    enableTelemetry: false
  }
}

module privateEndpoint 'br/public:avm/res/network/private-endpoint:0.11.0' = {
  name: take('avm.res.network.private-endpoint.${privateEndpointName}', 64)
  params: {
    name: privateEndpointName
    location: location
    subnetResourceId: privateEndpointSubnetId
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'file'
          ]
        }
      }
    ]
    privateDnsZoneGroup: privateDnsZoneMode == 'CreateNew'
      ? {
          name: 'fslogix-dns-group'
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsZone!.outputs.resourceId
            }
          ]
        }
      : null
    tags: tags
    enableTelemetry: false
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output privateEndpointId string = privateEndpoint.outputs.resourceId
output privateEndpointName string = privateEndpoint.outputs.name
// Private IP is assigned by Azure after provisioning — not directly available
// as a Bicep compile-time value. Retrieve post-deployment via:
//   az network private-endpoint show -n <name> -g <rg> --query 'customDnsConfigs[0].ipAddresses[0]'
