function Confirm-DiskAndSnapshot
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSSnapshotList]
        $Snapshot,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSDisk]
        $OSDisk
    )

    function Add-Check
    {
        param ($Check, $Result)
        return New-Object -TypeName PSObject -Property @{ Check = $Check; Result = $Result }
    }

    $objs = @()

    Write-Verbose "Validating storage tier"
    $storageTier = $Snapshot.Sku.Tier -eq $OSDisk.Sku.Tier
    Write-Verbose "Storage Tier validation: $storageTier"
    $objs += Add-Check -Check 'StorageTier' -Result $storageTier

    $objs.Result -notcontains $false
}