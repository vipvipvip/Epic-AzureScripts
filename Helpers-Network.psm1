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
        [int] $DestinationPortRange
    )
    if ($Name -eq ""  -or $Description -eq "" -or $DestinationPortRange -le 0)
    {
        throw 'Si3-Create-Rule() - One or more parameters to create the rule were not provided.'
    }

    return New-AzureRmNetworkSecurityRuleConfig -Name $Name -Description $Description `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority $Priority `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $DestinationPortRange
}