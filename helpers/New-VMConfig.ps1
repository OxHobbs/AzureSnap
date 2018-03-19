function New-VMConfig
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $VM,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSSnapshotList]
        $Snapshot,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSDisk]
        $OSDisk
    )

    $oldVMProps = @{
        Name = $vm.Name
        ResourceGroupName = $vm.ResourceGroupName
        Size = $vm.HardwareProfile.VmSize
        OsDiskName = $vm.StorageProfile.OsDisk.Name
        SnapshotName = $snapshot.Name
        StorageTier = $osDisk.Sku.Tier
        OsType = $osDisk.OsType 
    }
    
    $newId = (Get-Random -Minimum 10000 -Maximum 99999).ToString()
    $newOSDiskName = $oldVMProps.OSDiskName + "_$newId"
    Write-Verbose "Generated new name of OS disk -> $newOSDiskName"
    $diskConfig = New-AzureRmDiskConfig -SkuName $oldVMProps.StorageTier -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy

    Write-Verbose "Creating a new disk based off of the snapshot"
    $disk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $oldVMProps.resourceGroupName -DiskName $newOSDiskName -ErrorAction Stop

    Write-Verbose "Creating the Azure VM Configuration"
    $newVM = New-AzureRmVMConfig -VMName $vm.Name -VMSize $oldVMProps.Size
    if ($oldVMProps.OsType -eq 'Linux')
    {
        Write-Verbose "Configuring the OS Disk to Linux"
        $newVM = Set-AzureRmVMOSDisk -VM $newVM -ManagedDiskId $disk.Id -Linux -CreateOption Attach    
    }
    elseif ($oldVMProps.OsType -eq 'Windows')
    {
        Write-Verbose "Configuring the OS disk to Windows"
        $newVM = Set-AzureRmVMOSDisk -VM $newVM -ManagedDiskId $disk.Id -Windows -CreateOption Attach          
    }

    $nics = $vm.NetworkProfile.NetworkInterfaces
    foreach ($nic in $nics)
    {
        $nicName = $nic.id.split('/')[-1]
        # $nicObj = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vm.ResourceGroupName
        $nicObj = Find-NIC -NicName $nicName -VMResourceGroup $vm.ResourceGroupName
        Write-Verbose "Adding NIC -> $nicName"
        Write-Verbose "NIC ID -> $($nicObj.Id)"

        $null = Add-AzureRmVMNetworkInterface -VM $newVM -Id $nicObj.Id -Primary

    }   
    
    $dataDisks = $vm.StorageProfile.DataDisks
    foreach ($dataDisk in $dataDisks)
    {
        # $dataDiskObj = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name
        $dataDiskObj = Find-DataDisk -DiskName $dataDisk.Name -VMResourceGroup $vm.ResourceGroupName
        Write-Verbose "Adding data disk -> $($dataDisk.Name)"
        Write-Verbose "Disk ID -> $($dataDiskObj.id)"
        $null = Add-AzureRmVMDataDisk -ManagedDiskId $dataDiskObj.Id -VM $newVM -CreateOption Attach -Lun $dataDisk.Lun
    }

    return $newVM
}