function Find-NIC
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $NicName,

        [Parameter(Mandatory)]
        [String]
        $VMResourceGroup
    )

    try 
    {
        Write-Verbose "Looking for NIC ($NicName) in VM Resource Group ($VMResourceGroup)"
        $nic = Get-AzureRmNetworkInterface -ResourceGroupName $VMResourceGroup -NicName $NicName -ErrorAction Stop
        Write-Verbose "Found NIC ($($nic.Name) in Resource Group ($VMResourceGroup)"
        return $nic
    }
    catch 
    {
        Write-Verbose "Did not find the NIC in the VM Resource Group"
        Write-Verbose "Looking at all NICs and filtering on name"
        $nic = Get-AzureRmNetworkInterface | Where-Object { $_.Name -eq $NicName }
    
        if (-not $nic)
        {
            throw "Unable to find NIC ($($NicName))"
        }
        elseif ($dataDisk.Count -gt 1)
        {
            throw "Found too many NICs named $NicName -> $($nic.Count) found"
        }
    
        Write-Verbose "Found NIC by filter"
        return $nic 
    }
}