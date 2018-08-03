param
(
    [Parameter(Mandatory)]
    [String]
    $ResourceGroupName,

    [Parameter(Mandatory)]
    [String]
    $VMName,

    [Parameter(Mandatory)]
    [String]
    $StorageAccountName,

    [Parameter(Mandatory)]
    [PSCredential]
    $InvestigatorVMCredential,

    [Parameter()]
    [String]
    $StorageAccountResourceGroup = $ResourceGroupName,

    [Parameter()]
    [String]
    $VnetResourceGroup,

    [Parameter()]
    [String]
    $VnetName,

    [Parameter()]
    [String]
    $SubnetName
)

$conn = Get-AutomationConnection -Name AzureRunAsConnection
$account = Add-AzureRMAccount -ServicePrincipal -Tenant $conn.TenantID -ApplicationID $conn.ApplicationID -CertificateThumbprint $conn.CertificateThumbprint -EnvironmentName AzureUSGovernment


$params = @{
    ResourceGroupName = $ResourceGroupName
    VMName = $VMName
}

if ($SnapshotName)
{
    $params.Add('SnapshotName', $SnapshotName)
}

$Snapshot = New-AzureVMSnapshot @params

Write-Output $snapshot

$SubjectDiskName = New-SubjectDiskName -VMName $VMName -ResourceGroupName $ResourceGroupName
Write-Output $SubjectDiskName


$SubjectDataDiskRes = New-DiskFromSnapshot -DiskName $subjectDiskName -DiskResourceGroupName $Snapshot.ResourceGroupName -SnapshotId $Snapshot.Id -Location $Snapshot.Location -SkuName $Snapshot.Sku.Name -Ostype $Snapshot.Ostype 
$SubjectDataDisk = Get-AzureRmDisk -DiskName $SubjectDiskName -ResourceGroupName $Snapshot.ResourceGroupName

$GatorVMName = "$VMName-gator"
$suspectVM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName

$gatorParams = @{
    VMName = $GatorVMName
    Credentials = $InvestigatorVMCredential
    DataDisk = $SubjectDataDisk
    ResourceGroupName = $ResourceGroupName
    StorageAccountName = $StorageAccountName
    StorageAccountResourceGroup = $StorageAccountResourceGroup
    SuspectVM = $suspectVM
}

if ($VnetName)
{
    $gatorParams.Add('VnetName', $VnetName)
    $gatorParams.Add('SubnetName', $SubnetName)
    $gatorParams.Add('VnetResourceGroup', $VnetResourceGroup)
}

New-InvestigatorVM @gatorParams
