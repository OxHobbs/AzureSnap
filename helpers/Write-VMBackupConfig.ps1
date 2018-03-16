function Write-VMBackupConfig 
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $VM,

        [Parameter()]
        [Switch]
        $Clobber
    )

    $backupPath = "$PSScriptRoot\..\backup\$($VM.Name).json"
    $json = ConvertTo-Json -InputObject $VM

    $backupFileExists = Test-Path $backupPath

    if (($Clobber -and $backupFileExists) -or (-not $backupFileExists))
    {
        $json | Out-File -FilePath $backupPath -Force 
    }
    else
    {
        throw "A state file already exists for $($vm.Name).  Use the Clobber switch if you wish to override"
    }
}
