function New-DiskFromSnapshot
{
    param
    (
        [Parameter(Mandatory)]
        [String]
        $DiskName,

        [Parameter(Mandatory)]
        [String]
        $DiskResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $SnapshotId,

        [Parameter(Mandatory)]
        [String]
        $Location,

        [Parameter()]
        [Int]
        $DiskSizeGB = 127,

        [Parameter()]
        [String]
        $SkuName = 'Premium_LRS',

        [Parameter()]
        [ValidateSet('Windows', 'Linux')]
        [String]
        $OsType = 'Linux'
    )

    try
    {
        $diskConfig = New-AzureRmDiskConfig -SourceResourceId $SnapshotId -CreateOption Copy -SkuName $SkuName -OsType $OsType -DiskSizeGB $DiskSizeGB -Location $Location
        $disk = New-AzureRmDisk -ResourceGroupName $DiskResourceGroupName -DiskName $DiskName -Disk $diskConfig
    }
    catch
    {
        Write-Error "Error creating disk"
        Write-Error $_.Exception.ToString()
    }

}
