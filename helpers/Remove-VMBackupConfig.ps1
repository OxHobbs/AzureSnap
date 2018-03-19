function Remove-VMBackupConfig 
{
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $VM
    )

    $backupPath = "$PSScriptRoot\..\backup\$($VM.Name).json"

    Write-Verbose "Cleaning up"

    $backupFileExists = Test-Path $backupPath

    try
    {
        if ($backupFileExists)
        {
            Write-Verbose "Removing backup file from $backupPath"
            $null = Remove-Item -Path $backupPath -Force 
        }
        else
        {
            Write-Verbose "Backup file is not found, no clean up necessary"
        }        
    }
    catch
    {
        Write-Warning "There was a problem cleaning up the file -> $backupPath"
    }
}
