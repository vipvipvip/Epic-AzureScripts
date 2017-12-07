function Si3-New-Subnet {
    # Create-Subnet ('MySubnet-FrontEnd', '10.0.1.0/24')
    param(
        [string] $Name,
        [string] $AddressPrefix
    )
       
        if ($Name -eq ""  -or $AddressPrefix -eq "")
        {
            throw 'Si3-Create-Subne() - One or more parameters to create the subnet were not provided.'
        }
    
        return New-AzureRmVirtualNetworkSubnetConfig -Name $Name -AddressPrefix $AddressPrefix
}

function Si3-New-Rule {

    param(
        [string] $Name,
        [string] $Description,
        [int] $Priority,
        [string] $SourceAddressPrefix,
        [string] $DestinationPortRange
    )
    if ($Name -eq ""  -or $Description -eq "" -or $DestinationPortRange -eq "")
    {
        throw 'Si3-Create-Rule() - One or more parameters to create the rule were not provided.'
    }

    return New-AzureRmNetworkSecurityRuleConfig -Name $Name -Description $Description `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority $Priority `
    -SourceAddressPrefix $SourceAddressPrefix -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $DestinationPortRange
}

function Si3-New-Vnet {
    
        param(
            [string] $ResourceGroupName,
            [string] $Name,
            [string] $AddressPrefix,
            [string] $location,
            [Microsoft.Azure.Commands.Network.Models.PSSubnet[]] $Subnet
        )
        if ($ResourceGroupName -eq "" -or $Name -eq ""  -or $AddressPrefix -eq "" -or $location -eq "" -or $Subnet.Length -lt 0)
        {
            throw 'Si3-Create-Vnet() - One or more parameters to create the vnet were not provided.'
        }
    
        return New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $Name -AddressPrefix $AddressPrefix `
        -Location $location -Subnet $Subnet
}

function Si3-New-NSG {
    
        param(
            [string] $ResourceGroupName,
            [string] $location,
            [string] $Name,
            [Microsoft.Azure.Commands.Network.Models.PSSecurityRule[]] $Rule
        )
        if ($ResourceGroupName -eq "" -or $Name -eq ""  -or $AddressPrefix -eq "" -or $location -eq "" -or $Subnet.Length -lt 0)
        {
            throw 'Si3-Create-Vnet() - One or more parameters to create the vnet were not provided.'
        }
        
        return New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $location `
              -Name $Name -SecurityRules $Rule
}
