param location string = resourceGroup().location

resource vnet1 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties:{
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgdefault.id
          }
        }
      }
    ]
  }
}

resource nsgdefault 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-default'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAnyRDPInbound'
        properties: {
          description: 'Allow inbound RDP traffic to all VMs from Internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource VM1PIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'VM1-PIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource VM1NIC1 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'VM1-NIC1'
  location: location
  properties: {
          ipConfigurations: [
            {
              name: 'VM1-NIC1-IPConfig1'
              properties: {
                privateIPAllocationMethod: 'Dynamic'
                publicIPAddress: {
                  id: VM1PIP.id
                }
                subnet: {
                  id: vnet1.properties.subnets[0].id
                }
              }
            }
          ]
  }
}

resource VM1 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'VM1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'VM1'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'VM1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: VM1NIC1.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource VM1CSE 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: VM1
  name: 'VM1-CSE'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/2%20-%20Migrate%20Terraform%20State%20to%20Terraform%20Cloud%20for%20Azure/Set-Workstation.ps1'
      ]
      commandToExecute: 'powershell.exe -ExecutionPolicy Bypass -File Set-Workstation.ps1 -ResourceGroupName "${resourceGroup().name}" -ResourceGroupLocation "${resourceGroup().location}"'
    }
  }
}
