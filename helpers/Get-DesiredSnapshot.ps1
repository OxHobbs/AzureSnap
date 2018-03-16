function Get-DesiredSnapshot 
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSSnapshotList[]]
        $Snapshots
    )

    $Snapshots = $Snapshots | Sort-Object -Property TimeCreated -Descending

    # $snapName = Read-Host -Prompt $Snapshots

    
}
