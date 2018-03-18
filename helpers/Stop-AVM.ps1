function Stop-AVM
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    
    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $VM
    )

    $vmStatus = Get-VMStatus -VM $VM
    if ($vmStatus -notmatch 'running|deallocated')
    {
        throw "VM is in an unexpected state, must be running or deallocated."
    }

    if ($vmStatus -eq 'running') 
    {
        Write-Verbose "VM, $($vm.Name), is running"        
        if ($PSCmdlet.ShouldProcess($vm.Name, "Stop and Deallocate VM"))
        {
            try 
            {
                Write-Verbose "Stopping and deallocating VM"
                Stop-AzureRmVm -Name $vm.Name -Force -ResourceGroupName $vm.ResourceGroupName -ErrorAction stop
                Write-Verbose "VM ($($vm.Name)) has been stopped and deallocated"             
            }
            catch 
            {
                Write-Verbose "Error thrown stopping and deallocating"
                Write-Error $error[0].Exception.ToString()
            }

        }
    }

    if ($vmStatus -eq 'deallocated')
    {
        Write-Verbose "VM, ($($vm.Name) is already stopped and deallocated"
    }
}
