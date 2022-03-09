@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Name of the virtual machine.')
param name string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string

param imageReference object = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

param osDisk object = {
  createOption: 'fromImage'
  diskSizeGB: '128'
  managedDisk: {
    storageAccountType: 'Premium_LRS'
  }
}

@description('Size of the virtual machine.')
param vmSize string

@description('Subnet Id')
param subnetId string

@description('Location for all resources.')
param location string = resourceGroup().location

// @description('Allow ipv4 address prefix list for RDP.')
// param allowAddressPrefixList array = []

@description('Tags')
param tags object

@allowed([
  '1'
  '2'
  '3'
  ''
])
param zone string = ''

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${name}-pip-01'
  location: location
  sku: {
    name: zone == '' ? 'Basic' : 'Standard'
  }
  properties: {
    publicIPAllocationMethod: zone == '' ? 'Dynamic' : 'Static'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
  zones: zone == '' ? null : [
    zone
  ]
  tags: union(tags, {})
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${name}-nic-01'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
  tags: union(tags, {})
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${name}-disk-os-01'
        createOption: osDisk.createOption
        diskSizeGB: osDisk.diskSizeGB
        managedDisk: osDisk.managedDisk
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  zones: zone == '' ? null : [
    zone
  ]
  tags: union(tags, {})
}

output hostname string = pip.properties.dnsSettings.fqdn
