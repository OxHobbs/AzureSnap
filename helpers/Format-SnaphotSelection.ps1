function Format-SnapshotSelection
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSSnapshotList[]]
        $Snapshots
    )

    $objs = @()
    $count = 1

    $Snapshots = $Snapshots | Sort-Object -Property TimeCreated -Descending

    foreach ($snapshot in $snapshots)
    {
        $props = [Ordered]@{
            Number = $count
            Name = $snapshot.Name
            DateCreated = $snapshot.TimeCreated
            StorageTier = $snapshot.Sku.Tier
        }
        $objs += New-Object -TypeName PSObject -Property $props
        $count++
    }
    # Format-Table -InputObject $objs
    return $objs
}