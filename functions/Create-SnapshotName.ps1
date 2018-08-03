function New-SubjectDiskName
{
    param
    (
        [Parameter(Mandatory)]
        [String]
        $VMName,

        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName
    )

    $OsDiskId = Get-VMOSDiskResourceId -ResourceGroupName $ResourceGroupName -VMName $VMName
    $diskResource = Get-AzureRmResource -ResourceId $OsDiskId

    return "$($diskResource.Name)_subject_$(Get-RandomLowerString)"
}