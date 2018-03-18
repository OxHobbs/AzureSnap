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
    
    $newId = (Get-Random -Minimum 1000 -Maximum 99999).ToString()
    $newOSDiskName = $oldVMProps.OSDiskName + "_$newId"
    $diskConfig = New-AzureRmDiskConfig -SkuName $oldVMProps.StorageTier -Location $snapshot.Location -SourceResourceId $snapshot.Id -CreateOption Copy
    $disk = New-AzureRmDisk -Disk $diskConfig -ResourceGroupName $oldVMProps.resourceGroupName -DiskName $newOSDiskName -ErrorAction Stop
    $newVM = New-AzureRmVMConfig -VMName $vm.Name -VMSize $oldVMProps.Size
    if ($oldVMProps.OsType -eq 'Linux')
    {
        $newVM = Set-AzureRmVMOSDisk -VM $newVM -ManagedDiskId $disk.Id -Linux -CreateOption Attach    
    }
    elseif ($oldVMProps.OsType -eq 'Windows')
    {
        $newVM = Set-AzureRmVMOSDisk -VM $newVM -ManagedDiskId $disk.Id -Windows -CreateOption Attach          
    }

    $nics = $vm.NetworkProfile.NetworkInterfaces
    foreach ($nic in $nics)
    {
        $nicName = $nic.id.split('/')[-1]
        $nicObj = Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vm.ResourceGroupName
        $null = Add-AzureRmVMNetworkInterface -VM $newVM -NetworkInterface $nicObj
    }   
    
    $dataDisks = $vm.StorageProfile.DataDisks
    foreach ($dataDisk in $dataDisks)
    {
        $dataDiskObj = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $dataDisk.Name
        $null = Add-AzureRmVMDataDisk -ManagedDiskId $dataDiskObj.Id -VM $newVM -CreateOption Attach -Lun $dataDisk.Lun
    }

    return $newVM
}