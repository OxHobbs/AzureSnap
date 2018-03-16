function Restore-AzureVMSnapshot
{
    [CmdletBinding()]

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
    $vmOsDiskId = Get-VMOSDiskResourceID -ResourceGroupName $VMResourceGroupName -VMName $VMName

    $snapshots = Get-LeafSnapshots -OSDiskResourceID $vmOsDiskId -ResourceGroupName $SnapshotResourceGroupName

    if ($SnapshotName)
    {
        $snapshot = $snapshots | Where-Object { $_.Name -eq $SnapshotName }
    }
    else
    {
        # Need to inquire from the user what Snapshot to use        
        $snapshot = Get-DesiredSnapshot -Snapshots $snapshots
    }

    if (-not $snapshot) { throw "Snapshot not found or selected" }
    

}