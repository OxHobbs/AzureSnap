function Get-DesiredSnapshotName 
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [PSObject[]]
        $Snapshots
    )

    # $Snapshots = $Snapshots | Sort-Object -Property TimeCreated -Descending

    # Format-Table -InputObject $Snapshots
        
    do 
    {
        $choice = Read-Host "`nEnter the number that corresponds to the desired snapshot for restoration"
    }
    Until ($choice -in (1..$snapshots.Count))

    Write-Verbose "User chose number $choice"
    $snapshotName = ($snapshots | Where-Object Number -eq $choice).Name
    Write-Verbose "Snapshot name is $snapshotName"
    
    return $snapshotName    
}
