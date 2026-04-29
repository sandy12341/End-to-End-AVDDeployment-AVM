using './main.bicep'

param location = 'westus3'
param workloadName = 'avd-ops-summary'
param reportContainerName = 'operational-summaries'
param reportPathPrefix = 'operational-summary/manual-validation'

param existingCollectorIdentityResourceId = '/subscriptions/830ef649-535d-4642-9436-356f9619c2e4/resourceGroups/rg-cloudaigeek-hubspoke-cus-01/providers/Microsoft.ManagedIdentity/userAssignedIdentities/avd-rbac-discovery'
param existingCollectorIdentityClientId = '5375da98-7830-42d1-9ed5-b64fce1f74d8'
param existingCollectorIdentityPrincipalId = '20914105-3a6c-4faa-9783-a787a7b58844'

param enableManagedAppEventGridTrigger = false

param tags = {
  Project: 'AVD-Landing-Zone'
  Workload: 'OperationalSummaryCollector'
  ValidationMode: 'ManualHttpFirst'
}