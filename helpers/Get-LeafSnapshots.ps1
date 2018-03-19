function Get-LeafSnapshots
{
    [CmdletBinding()]

    param
    (
        # [Parameter(Mandatory)]
        # [String]
        # $ResourceGroupName,

        [Parameter(Mandatory)]
        [String]
        $OSDiskResourceID
    )

    $snaps = Get-AzureRmSnapshot | Where-Object { $_.CreationData.SourceResourceId -eq $OSDiskResourceID }

    Write-Verbose "Found $($snaps.Count) snapshots spawned from parent disk -> $OSDiskResourceID"
    
    return $snaps
}
