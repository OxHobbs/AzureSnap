function Get-VMOSDiskResourceID
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $VMName
    )

    $vm = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName
    $osDiskName = $vm.StorageProfile.OsDisk.Name
    $resource = Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName $osDiskName
    return $resource.ResourceId
}
