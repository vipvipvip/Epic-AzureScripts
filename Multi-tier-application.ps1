﻿# Login-AzureRmAccount
Import-Module "$PSScriptRoot\SubscriptionManagement" -Force
Import-Module "$PSScriptRoot\EpicConfig" -Force
Import-Module "$PSScriptRoot\UserConfig" -Force
Import-Module "$PSScriptRoot\VMConfig" -Force
Import-Module "$PSScriptRoot\Helpers-Network" -Force

# Get Azure credentials if not already logged on,  Use -Force to select a different subscription 
Initialize-Subscription -Verbose

# Get the resource group and user names used when the application was deployed  
#$Si3User = Get-UserConfig

# Get the Si3 app configuration
$Si3Config = Get-Configuration

$SQLVMConfig = Get-SQLVMConfiguration

# Variables for common values
$rgName = $Si3Config.ResourceGroupName
$location = $Si3Config.Location

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group.
New-AzureRmResourceGroup -Name $rgName -Location $location

$fesubnet = Si3-New-Subnet "MySubnet-FrontEnd" "10.0.1.0/24"
$besubnet = Si3-New-Subnet "MySubnet-BackEnd" "10.0.2.0/24"
$vnet = Si3-New-Vnet $rgName 'MyVnet' '10.0.0.0/16' $location  @($fesubnet, $besubnet)

# Create a virtual network with a front-end subnet and back-end subnet.
# $fesubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'MySubnet-FrontEnd' -AddressPrefix '10.0.1.0/24'
# $besubnet = New-AzureRmVirtualNetworkSubnetConfig -Name 'MySubnet-BackEnd' -AddressPrefix '10.0.2.0/24'
# $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgName -Name 'MyVnet' -AddressPrefix '10.0.0.0/16' `
#   -Location $location -Subnet $fesubnet, $besubnet

# Create an NSG rule to allow HTTP traffic in from the Internet to the front-end subnet.
$rule1 = Si3-New-Rule 'Allow-HTTP-All' 'Allow HTTP' 100 '80'
# $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-HTTP-All' -Description 'Allow HTTP' `
#   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
#   -SourceAddressPrefix Internet -SourcePortRange * `
#   -DestinationAddressPrefix * -DestinationPortRange 80

# Create an NSG rule to allow RDP traffic from the Internet to the front-end subnet.
$rule2 = Si3-New-Rule 'Allow-RDP-All' 'Allow RDP' 200 '3389'
# $rule2 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
#   -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
#   -SourceAddressPrefix Internet -SourcePortRange * `
#   -DestinationAddressPrefix * -DestinationPortRange 3389


# Create a network security group for the front-end subnet.
$nsgfe = Si3-New-NSG $rgName $location 'MyNsg-FrontEnd' @($rule1, $rule2)
# $nsgfe = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
#   -Name 'MyNsg-FrontEnd' -SecurityRules $rule1,$rule2

# Associate the front-end NSG to the front-end subnet.
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-FrontEnd' `
  -AddressPrefix '10.0.1.0/24' -NetworkSecurityGroup $nsgfe

# Create an NSG rule to allow SQL traffic from the front-end subnet to the back-end subnet.
$rule1 = Si3-New-Rule 'Allow-SQL-FrontEnd' 'Allow SQL' 100 '1433'
# $rule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-SQL-FrontEnd' -Description "Allow SQL" `
#   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
#   -SourceAddressPrefix '10.0.1.0/24' -SourcePortRange * `
#   -DestinationAddressPrefix * -DestinationPortRange 1433

# Create an NSG rule to allow RDP traffic from the Internet to the back-end subnet.
$rule2 = Si3-New-Rule 'Allow-RDP-All' 'Allow RDP' 200 '3389'
# $rule2 = New-AzureRmNetworkSecurityRuleConfig -Name 'Allow-RDP-All' -Description "Allow RDP" `
#   -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
#   -SourceAddressPrefix Internet -SourcePortRange * `
#   -DestinationAddressPrefix * -DestinationPortRange 3389

# Create a network security group for back-end subnet.
$nsgbe = Si3-New-NSG $rgName $location 'MyNsg-BackEnd' @($rule1, $rule2)
# $nsgbe = New-AzureRmNetworkSecurityGroup -ResourceGroupName $RgName -Location $location `
#   -Name "MyNsg-BackEnd" -SecurityRules $rule1,$rule2

# Associate the back-end NSG to the back-end subnet
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name 'MySubnet-BackEnd' `
  -AddressPrefix '10.0.2.0/24' -NetworkSecurityGroup $nsgbe

# Create a public IP address for the web server VM.
$publicipvm1 = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name 'MyPublicIp-Web' `
  -location $location -AllocationMethod Dynamic

# Create a NIC for the web server VM.
$nicVMweb = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name 'MyNic-Web' -PublicIpAddress $publicipvm1 -NetworkSecurityGroup $nsgfe -Subnet $vnet.Subnets[0]

# Create a Web Server VM in the front-end subnet
$vmConfig = New-AzureRmVMConfig -VMName 'MyVm-Web' -VMSize 'Standard_A2' | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName 'MyVm-Web' -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
  -Skus '2008-R2-SP1' -Version latest | Add-AzureRmVMNetworkInterface -Id $nicVMweb.Id

$vmweb = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Create a public IP address for the SQL VM.
$publicipvm2 = New-AzureRmPublicIpAddress -ResourceGroupName $rgName -Name MyPublicIP-Sql `
  -location $location -AllocationMethod Dynamic

# Create a NIC for the SQL VM.
$nicVMsql = New-AzureRmNetworkInterface -ResourceGroupName $rgName -Location $location `
  -Name MyNic-Sql -PublicIpAddress $publicipvm2 -NetworkSecurityGroup $nsgbe -Subnet $vnet.Subnets[1] 

# Create a SQL VM in the back-end subnet.
$vmConfig = New-AzureRmVMConfig -VMName $SQLVMConfig.VMName -VMSize $SQLVMConfig.VMSize | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName $SQLVMConfig.VMName -Credential $cred | `
  Set-AzureRmVMSourceImage -PublisherName $SQLVMConfig.PublisherName -Offer $SQLVMConfig.Offer `
  -Skus $SQLVMConfig.Skus -Version $SQLVMConfig.Version | Add-AzureRmVMNetworkInterface -Id $nicVMsql.Id

$vmsql = New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vmConfig

# Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (must be done after VM creation)
$rule3 = Si3-New-Rule 'Deny-Internet-All' 'Deny Internet All' 300 "*"
# $rule3 = New-AzureRmNetworkSecurityRuleConfig -Name 'Deny-Internet-All' -Description "Deny Internet All" `
#   -Access Deny -Protocol Tcp -Direction Outbound -Priority 300 `
#   -SourceAddressPrefix * -SourcePortRange * `
#   -DestinationAddressPrefix Internet -DestinationPortRange *

# Add NSG rule to Back-end NSG
$nsgbe.SecurityRules.add($rule3)

Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsgbe

# Clean up deployment
#Remove-AzureRmResourceGroup -Name myResourceGroup