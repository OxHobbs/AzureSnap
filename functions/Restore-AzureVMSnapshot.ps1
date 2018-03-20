<#
.SYNOPSIS
Restore a VM to a previously captured snapshot.

.DESCRIPTION
This cmdlet will restore a VM to a previously created snapshot.  It will restore the original data disks and NICs to the VM as they were
at the time the cmdlet is being executed.  This is done by removing the VM and re-creating it with the Snapshot disk and then attaching
data disks and NICs.

.PARAMETER VMResourceGroupName
[Required] The name of the resource group in which the VM exists.

.PARAMETER VMName
[Required] The name of the VM to be restored.

.PARAMETER SnapshotName
[Optional] The name of the desired snapshot to use for restoration. If no Snapshot name is specified then the
user will be provided a list of Snapshots from which to choose.  By default, only snapshots that are spawned off
of the OS disk will be presented for selection.

.PARAMETER IncludeAllSnapshots
[Optional] Switch this on to include all Snapshots for possible restoration, not just spawned Snapshots.  This may be useful
when it is desired to restore to a Snapshot that is no longer a child of the currently attached OS disk.

.PARAMETER Clobber
[Optional] Switch this to allow the module to over-write a previously captured JSON representation of a VM.  This is done for
safety reasons in case a VM was removed and creation failed.  If this happens, this JSON file provides the capability to rebuild
the VM if needed.

.EXAMPLE
The below example restores a Snapshot to a VM allowing the user to select a Snapshot from a presented list.

Restore-AzureVMSnapshot -VMResourceGroupName frontend -VMName myfe01

Number Name                        DateCreated          ResourceGroup StorageTier
------ ----                        -----------          ------------- -----------
     1 myfe01-snapshot2            3/20/2018 2:32:15 PM frontend       Premium
     2 myfe01-20180320-GIyHx       3/20/2018 2:31:18 PM frontend       Premium
     3 myfe01-20171211-CcfGv       3/20/2018 2:30:19 PM frontend       Premium

Enter the number that corresponds to the desired snapshot for restoration: 1

.EXAMPLE 
This example restores a Snapshot to specified snapshot.  It also does not ask for confirmation.

Restore-AzureVMSnapshot -VMResourceGroupName frontend -VMName myfe01 -SnapshotName myfe01-snapshot2 -Confirm:$false

.EXAMPLE
This example shows how to be provided a list of all Snapshots in the subscription as an option for restoration.

Restore-AzureVMSnapshot -VMResourceGroupName frontend -VMName myfe01 -SnapshotName myfe01-snapshot2 -IncludeAllSnapshots

Number Name                        DateCreated          ResourceGroup StorageTier
------ ----                        -----------          ------------- -----------
     1 myfe01-snapshot2            1/24/2018 2:32:15 PM frontend       Premium
     2 myfe01-20180320-GIyHx       3/20/2018 2:31:18 PM frontend       Premium
     3 myfe01-20170111-CcfGv       1/11/2017 2:30:19 PM frontend       Premium
     4 myfe02-20180123-Wdaef       2/3/2018  7:30:30 PM bozo           Premium

Enter the number that corresponds to the desired snapshot for restoration: 1
#>
function Restore-AzureVMSnapshot
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]

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
        $SnapshotName,

        [Parameter()]
        [Switch]
        $IncludeAllSnapshots,

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
    $osDisk = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $vm.StorageProfile.OsDisk.Name    

    $snapshots = if ($IncludeAllSnapshots)
    {
        Get-AzureRmSnapshot | Where-Object { $_.Location -eq $vm.Location -and $_.Sku.Name -eq $osDisk.Sku.Name } 
    }
    else
    {
        Get-LeafSnapshots -OSDiskResourceID $vmOsDiskId 
    }
    Write-Verbose "Grabbed $($snapshots.Count) snapshots"

    if (-not $snapshots) { throw "No Snapshots found for vm ($($VM.Name))" }
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
            $out = New-AzureRmVM -VM $newVM -ResourceGroupName $vm.ResourceGroupName -Location $snapshot.location -ErrorAction Stop        
            Write-Verbose "Created the Virtual Machine"
            $out

            Remove-VMBackupConfig -VM $vm
        }
        catch
        {
            # Write-Error $error[0].Exception.ToString()
            Write-Error "$($_.Exception.Message)"
        }
    }
}
