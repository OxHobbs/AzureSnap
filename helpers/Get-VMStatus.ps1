function Get-VMStatus
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $VM
    )

    $vmStatus = Get-AzureRmVm -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
    $vmPowerState = $vmStatus.Statuses | where-object { $_.Code -match 'PowerState' }
    return $vmPowerState.Code.Split('/')[1]
}
