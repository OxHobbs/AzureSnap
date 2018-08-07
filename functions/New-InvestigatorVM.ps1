function New-InvestigatorVM
{
    [CmdletBinding(SupportsShouldProcess = $true)]

    param
    (
        [Parameter(Mandatory)]
        [String]
        $VMName,

        [Parameter(Mandatory)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory)]
        [PSCredential]
        $Credentials,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]
        $SuspectVM,

        [Parameter(Mandatory)]
        [Microsoft.Azure.Commands.Compute.Automation.Models.PSDisk]
        $DataDisk,

        [Parameter(Mandatory)]
        [String]
        $StorageAccountName,

        [Parameter()]
        [String]
        $StorageAccountResourceGroup = $ResourceGroupName,

        [Parameter()]
        [String]
        $VMSize = 'Standard_B1s',

        [Parameter()]
        [ValidateScript(
            { 'Publisher' -in $_.Keys -and
               'Offer' -in $_.Keys -and
               'Skus' -in $_.Keys }
        )]
        [Hashtable]
        $ImageOffer = @{
            Publisher = 'OpenLogic'
            Offer     = 'CentOS'
            Skus      = '7.5'
        },

        [Parameter()]
        [String]
        $VnetResourceGroupName,

        [Parameter()]
        [String]
        $VnetName,

        [Parameter()]
        [String]
        $SubnetName
    )


    $nicId = $SuspectVM.NetworkProfile.NetworkInterfaces[0].Id
    $subjectNic = Get-NicFromId -NicId $nicId

    if ($VnetName -and $SubnetName -and $VnetResourceGroupName)
    {
        Write-Verbose "Querying the VNet info with user supplied Vnet Info"
        $vnet = Get-AzureRmVirtualNetwork -Name $VnetName -ResourceGroupName $VnetResourceGroupName
        $subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet
    }
    elseif (-not ($VnetName -or $SubnetName -or $VnetResourceGroupName))
    {
        Write-Verbose "Pulling Vnet info from subject NIC"
        $vnet = Get-VnetFromNic -Nic $subjectNic
        $subnet = Get-SubnetFromNic -Nic $subjectNic
    }
    else
    {
        throw "New-InvestigatorVM -> If VnetName, SubnetName or VnetResourceGroup is specified, then all 3 must be specified"
    }

    $nicParams = @{
        Name = "$VMName-nic"
        ResourceGroupName = $ResourceGroupName
        Location = $vnet.Location
        SubnetId = $subnet.Id
    }

    $nsg = Get-NsgFromId -NsgId $nic.NetworkSecurityGroup.Id

    if ($nsg)
    {
        Write-Verbose "Found an NSG and will add to the new NIC"
        $nicParams.Add('NetworkSecurityGroupId', $nsg.Id)
    }

    $saKey = (Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $StorageAccountResourceGroup)[0].Value

    if ($PSCmdlet.ShouldProcess($VMName, "Create investigator VM"))
    {
        try
        {
            $Location = $vnet.Location

            Write-Verbose "Creating a new NIC -> $($nicParams['Name'])"
            $InvestigatorNic = New-AzureRmNetworkInterface @nicParams

            Write-Verbose "Building VM configuration object"
            $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize -Tags @{Investigator = "of$($suspectVM.Name)"}
            $null = Set-AzureRmVMOperatingSystem -Linux -ComputerName $VMName -VM $vmConfig -Credential $Credentials
            $null = Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $ImageOffer.Publisher -Offer $ImageOffer.Offer -Skus $ImageOffer.Skus -Version Latest
            $null = Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $InvestigatorNic
            $null = Add-AzureRmVMDataDisk -VM $vmConfig -CreateOption Attach -ManagedDiskId $DataDisk.Id -Lun 0 -StorageAccountType $DataDisk.Sku.Name
            $null = Set-AzureRmVMBootDiagnostics -Disable -VM $vmConfig

            Write-Verbose "Creating new VM with new VM Configuration object -> $($vmConfig)"
            New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location  -VM $vmConfig

            $CustomScriptProps = @{
                fileUris = @(
                    'https://raw.githubusercontent.com/OxHobbs/investigate/master/investigate.py',
                    'https://raw.githubusercontent.com/OxHobbs/investigate/master/requirements.txt'
                )
                commandToExecute = "curl 'https://bootstrap.pypa.io/get-pip.py' -o 'get-pip.py' && python get-pip.py && pip install -r requirements.txt && python investigate.py -a '$StorageAccountName' -k '$sakey' -c 'AzureUSGovernment' -v"
            }

            Set-AzureRmVMExtension -Publisher Microsoft.Azure.Extensions -Version 2.0 -Name CustomScript -Settings $CustomScriptProps -Type CustomScript -ResourceGroupName $ResourceGroupName -VMName $VMName -Location $vnet.Location
        }
        catch
        {
            Write-Error $_.Exception
            break
        }
    }
}

