targetScope = 'subscription'

// ========== //
// Parameters //
// ========== //

@description('Optional. The name of the resource group to deploy for testing purposes.')
@maxLength(90)
param resourceGroupName string = 'dep-${namePrefix}-kubernetesconfiguration.fluxconfigurations-${serviceShort}-rg'

@description('Optional. The location to deploy resources to.')
param location string = deployment().location

@description('Optional. A short identifier for the kind of deployment. Should be kept short to not run into resource-name length-constraints.')
param serviceShort string = 'kcfcwaf'

@description('Optional. Enable telemetry via a Globally Unique Identifier (GUID).')
param enableTelemetry bool = true

@description('Optional. A token to inject into the name of each resource.')
param namePrefix string = '#_namePrefix_#'

// ============ //
// Dependencies //
// ============ //

// General resources
// =================
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module nestedDependencies 'dependencies.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-nestedDependencies'
  params: {
    clusterName: 'dep-${namePrefix}-aks-${serviceShort}'
    clusterExtensionName: '${namePrefix}${serviceShort}001'
    clusterNodeResourceGroupName: 'dep-${namePrefix}-aks-${serviceShort}-rg'
    location: location
  }
}

// ============== //
// Test Execution //
// ============== //

module testDeployment '../../../main.bicep' = {
  scope: resourceGroup
  name: '${uniqueString(deployment().name, location)}-test-${serviceShort}'
  params: {
    enableTelemetry: enableTelemetry
    name: '${namePrefix}${serviceShort}001'
    clusterName: nestedDependencies.outputs.clusterName
    namespace: 'flux-system'
    location: location
    scope: 'cluster'
    sourceKind: 'GitRepository'
    gitRepository: {
      repositoryRef: {
        branch: 'main'
      }
      sshKnownHosts: ''
      syncIntervalInSeconds: 300
      timeoutInSeconds: 180
      url: 'https://github.com/mspnp/aks-baseline'
    }
    kustomizations: {
      unified: {
        dependsOn: []
        force: false
        path: './cluster-manifests'
        prune: true
        syncIntervalInSeconds: 300
        timeoutInSeconds: 300
      }
    }
    // Workaround for PSRule
    bucket: null
    configurationProtectedSettings: null
  }
}
