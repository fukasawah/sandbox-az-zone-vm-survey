var baseName = 'ftest'

var unique = substring(uniqueString(resourceGroup().id), 0, 4)

var zones = [
  '1'
  '2'
  '3'
]

var commonTags = {}

@secure()
param vmUsername string

@secure()
@minLength(12)
@description('VMの接続パスワード')
param vmPassword string

@secure()
@description('Ping送信元のIPアドレス(cidr)')
param sourceAddressPrefix string

var location = resourceGroup().location

var vmSize = 'Standard_D2s_v4' // 'Standard_B1s'

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'nsg-${baseName}-for-vm'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: sourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '10.0.0.0/24'
          destinationPortRange: '22'
          priority: 1000
          description: 'Maintenance RDP'
        }
      }

      {
        name: 'AllowICMP'
        properties: {
          direction: 'Inbound'
          protocol: 'Icmp'
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          priority: 1010
          description: 'Ping'
        }
      }
    ]
  }

  tags: union(commonTags, {})
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-${baseName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet-vm-${baseName}'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
  tags: union(commonTags, {})
}

module vm './modules/virtualMachine.bicep' = [for zone in zones: {
  name: 'vm-${baseName}-${zone}'
  params: {
    name: 'vm${baseName}${zone}'
    location: location
    adminUsername: vmUsername
    adminPassword: vmPassword
    vmSize: vmSize

    imageReference: {
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '18.04-LTS'
      version: 'latest'
    }
    /*{
      publisher: 'MicrosoftWindowsServer'
      offer: 'WindowsServer'
      sku: '2019-Datacenter-smalldisk'
      version: 'latest'
    }*/
    osDisk: {
      createOption: 'fromImage'
      diskSizeGB: '32'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    subnetId: virtualNetwork.properties.subnets[0].id
    dnsLabelPrefix: 'vm${baseName}${zone}-${unique}'
    zone: zone

    tags: union(commonTags, {})
  }
}]

output hostnames array = [
  vm[0].outputs.hostname
  vm[1].outputs.hostname
  vm[2].outputs.hostname
]
