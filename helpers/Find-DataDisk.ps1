function Find-DataDisk
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $DiskName,

        [Parameter(Mandatory)]
        [String]
        $VMResourceGroup
    )

    try 
    {
        Write-Verbose "Looking for disk ($diskName) in VM Resource Group ($VMResourceGroup)"
        $dataDisk = Get-AzureRmDisk -ResourceGroupName $VMResourceGroup -DiskName $DiskName -ErrorAction Stop
        Write-Verbose "Found disk ($($dataDisk.Name) in Resource Group ($VMResourceGroup)"
        return $dataDisk
    }
    catch 
    {
        Write-Verbose "Did not find the data disk in the VM Resource Group"
        Write-Verbose "Looking in all disks and filtering on name"
        $dataDisk = Get-AzureRmDisk | Where-Object { $_.Name -eq $DiskName }
    
        if (-not $dataDisk)
        {
            throw "Unable to find data disk ($($DiskName))"
        }
        elseif ($dataDisk.Count -gt 1)
        {
            throw "Found too many disks named $DiskName -> $($dataDisk.Count) found"
        }
    
        Write-Verbose "Found disk by filter"
        return $dataDisk 
    }
}