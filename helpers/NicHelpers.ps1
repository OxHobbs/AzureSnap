function Get-NicFromId
{
    param
    (
        [Parameter(Mandatory)]
        [String]
        $NicId
    )

    $nicResource = Get-AzureRmResource -ResourceId $NicId
    $nic = Get-AzureRmNetworkInterface -Name $nicResource.Name -ResourceGroupName $nicResource.ResourceGroupName
    return $nic
}

function Get-VnetFromNic
{
    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Network.Models.PSNetworkInterface]
        $Nic
    )

    $vnetName = $nic.IpConfigurations[0].Subnet.Id.Split('/')[8]
    $vnetRg = $nic.IpConfigurations[0].Subnet.id.split('/')[4]
    $vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRg
    return $vnet
}

function Get-SubnetFromNic
{
    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Network.Models.PSNetworkInterface]
        $Nic
    )

    $vnet = Get-VnetFromNic -Nic $nic
    $subnetName = $nic.IpConfigurations[0].Subnet.Id.Split('/')[-1]
    $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
    return $subnet
}

function Get-NSGFromId
{
    param
    (
        [Parameter()]
        [String]
        $nsgId
    )

    $nsg = $null

    if ($nsgId)
    {
        $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgId.Split('/')[-1] -ResourceGroupName $nsgId.Split('/')[4]
    }

    return $nsg
}