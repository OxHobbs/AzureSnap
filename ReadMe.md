# AzureSnap PowerShell Module

## Description

This is a PowerShell module that provides the capability to quickly create and restore snapshots to Azure Virtual Machines in the Azure Resource Manager version of Azure.  This is a standard PowerShell module so detailed information about the cmdlets can be viewed with the _Get-Help_ cmdlet.  Examples and additional information can be seen using the _-Examples_, _-Detailed_ and _-Full_ switches on the _Get-Help_ cmdlet.

## Instructions

* Copy the AzureSnap folder into the _c:/Program Files/WindowsPowerShell/Modules_ directory.
* Open a fresh PowerShell Console and run

```PowerShell
Import-Module AzureSnap 
```

* Run the following command to see a list of available commands in the module

```PowerShell
Get-Command -Module AzureSnap
```

* Run the help commands to learn more about the cmdlets; such as, what information is required and examples of how to run the cmdlets.

```PowerShell
Get-Help Restore-AzureVMSnapshot -Full
```
## Cmdlets

### New-AzureVMSnapshot

Creates a new Snapshot based on of the OS disk of the specified VM. You may choose a name for the Snapshot or let the cmdlet generate a timestamped name.  The snapshot will be created to match the same tier and location of the OS disk.
This cmdlet only creates a snapshot of the OS disk, not data disks.  However, all disks will be attached to the VM in the restore process.

### Restore-AzureVMSnapshot

Restores an Azure Virtual Machine's OS disk to a previously created snapshot.  This process will handle removing the VM and re-creating it with the same data disk and network card configuration by reattaching the disks and NICs.