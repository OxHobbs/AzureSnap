<#
.SYNOPSIS
Create a Snapshot based off of the OS disk of a specified VM.

.DESCRIPTION
This cmdlet will create a Snapshot based off of the OS disk of the specified VM.  It is assumed that the snapshot will be 
stored on the same tier of storage as the current disk and the same resource group.  This snapshot can be restored quickly
with the Restore-AzureVMSnapshot cmdlet.  Common parameters are supported (Verbose, Confirm, etc.)

.PARAMETER ResourceGroupName
[Required] Specify the name of the resource group in which the VM exists.

.PARAMETER VMName
[Required] Specify the name of the VM of which to create a snapshot.

.PARAMETER SnapshotName
[Optional] Specify the name of the snapshot that will be created.  If no snapshot name is provided then one will be generated using the 
Name of the VM, a time stamp and a randomly generated string to protect against collisions.

.EXAMPLE
The below example will create a Snapshot based off the OS disk for VM MYSQLDBVM01.  This snapshot will be named something similar to
MYSQLDBVM01-20180322-d4lsO

New-AzureVMSnapshot -ResourceGroupName MyRG -VMName MYSQLDBVM01

.EXAMPLE
The below example will create a Snapshot based off the OS disk for VM MYFS01. The snapshot will be named MYFS01-Snapshot1

New-AzureVMSnapshot -ResourceGroupName MyRG -VMName MYFS01 -SnapshotName MYFS01-Snapshot1
#>
function New-AzureVMSnapshot
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $VMName,

        [Parameter()]
        [String]
        $SnapshotName = ($VMName + "-" + (Get-Date -Format yyyyMMdd).ToString() + "-" + $((65..90) + (97..122) | Get-Random -Count 5 | % { [char]$_ })).Replace(' ', '') 

    )

    Write-Verbose "Looking for the VM ($VMName) in resource group ($ResourceGroupName)"
    $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop
    Write-Verbose "Found VM ($($vm.Name)) in region ($($vm.Location))"
    
    try
    {
        $osDiskName = $vm.StorageProfile.OsDisk.Name
        Write-Verbose "Looking for the OS Disk in the VM Resource group"
        $osDisk = Get-AzureRmDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $osDiskName -ErrorAction Stop
        Write-Verbose "Found the OS Disk in the same resource group as VM"
    }
    catch
    {
        Write-Verbose "Unable to find the OS Disk in the VM resource group"
        Write-Verbose "Attempting to locate OS Disk through the resource and filtering"
        $osDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id
        $osDiskResource = Get-AzureRmResource -ResourceId $osDiskId
        $osDisk = Get-AzureRmDisk -DiskName $osDiskName -ResourceGroupName $osDiskResource.ResourceGroupName -ErrorAction Stop
        Write-Verbose "Found the disk through filtering resource"
    }

    try
    {
        Write-Verbose "Creating a snapshot configuration with name $snapshotName"
        $snapshotConfig = New-AzureRmSnapshotConfig -SourceUri $osDisk.Id -SkuName $osDisk.Sku.Name -OsType $osDisk.OsType -Location $osDisk.Location -CreateOption Copy
        Write-Verbose "Created snapshot config"
        if ($pscmdlet.ShouldProcess($vm.Name, 'create snapshot'))
        {
            Write-Verbose "Creating snapshot"
            $snapshot = New-AzureRmSnapshot -ResourceGroupName $osDisk.ResourceGroupName -SnapshotName $SnapshotName -Snapshot $snapshotConfig
            Write-Verbose "Snapshot ($SnapshotName) created"
            $snapshot
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}