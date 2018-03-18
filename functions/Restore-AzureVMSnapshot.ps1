function Restore-AzureVMSnapshot
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $VMResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $VMName,

        [Parameter()]
        [String]
        $SnapshotResourceGroupName = $VMResourceGroupName,

        [Parameter()]
        [String]
        $SnapshotName,

        [Parameter()]
        [Switch]
        $Clobber
    )

    Write-Verbose "Retrieving the VM $($VMName) in Resource Group $($ResourceGroupName)"
    $vm = Get-AzureRmVm -ResourceGroupName $VMResourceGroupName -Name $VMName -ErrorAction Stop

    $backupConfigParams = @{
        VM = $VM
        Clobber = $false
    }

    if ($Clobber) { $backupConfigParams['Clobber'] = $true }
    Write-Verbose "Calling WriteBackupConfig"
    Write-VMBackupConfig @backupConfigParams

    Write-Verbose "Calling Get-VMOSDiskResourceID to obtain the ID of the OS disk on $($vm.Name)"
    # $vmOsDiskId = Get-VMOSDiskResourceID -ResourceGroupName $VMResourceGroupName -VMName $VMName
    $vmOsDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id

    $snapshots = Get-LeafSnapshots -OSDiskResourceID $vmOsDiskId -ResourceGroupName $SnapshotResourceGroupName
    if (-not $snapshots) { throw "No Snapshots found in resource group ($($SnapshotResourceGroupName)) for vm ($($VM.Name))" }
    else { $snapshots = $snapshots | Sort-Object -Property TimeCreated -Descending }

    if ($SnapshotName)
    {
        Write-Verbose "Filtering for snapshot named -> $SnapshotName"
        $snapshot = $snapshots | Where-Object { $_.Name -eq $SnapshotName }
    }
    else
    {
        # Need to inquire from the user what Snapshot to use
        $snapSelection = Format-SnapshotSelection -Snapshots $snapshots   
        Format-Table -InputObject $snapSelection
        $snapshotName = Get-DesiredSnapshotName -Snapshots $snapSelection
        $snapshot = $snapshots | Where-Object { $_.Name -eq $snapshotName }
    }

    if (-not $snapshot) { throw "Error selecting snapshot" }
    Write-Verbose "Moving forward with snapshot, $($snapshot.Name)"

    Write-Verbose "Validating that the disk and the snapshot are of similar configuration"
    $osDisk = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name
    if (-not (Confirm-DiskAndSnapshot -Snapshot $snapshot -OSDisk $osDisk))
    {
        throw 'validation error between disk and snapshot'
    }
    Write-Verbose "Validation passed"

    if ($PSCmdlet.ShouldProcess($vm.Name, 'Stop, Remove and Create from a VM based on Snapshot'))
    {
        try
        {
            $null = Stop-AVM -VM $vm -ErrorAction Stop
            Write-Verbose "Removing the VM ($($vm.Name))"
            $null = Remove-AzureRmVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Force -ErrorAction Stop
            Write-Verbose "Removed the VM ($($vm.Name))"
            Write-Verbose "Creating the VM Configuration"
            $newVM = New-VMConfig -VM $vm -Snapshot $snapshot -OSDisk $osDisk -ErrorAction Stop
            Write-Verbose "Creating the VM..."
            New-AzureRmVM -VM $newVM -ResourceGroupName $vm.ResourceGroupName -Location $snapshot.location -ErrorAction Stop        
            Write-Verbose "Created the Virtual Machine"
        }
        catch
        {
            # Write-Error $error[0].Exception.ToString()
            Write-Error "$($_.Exception.Message)"
        }
    }
}
