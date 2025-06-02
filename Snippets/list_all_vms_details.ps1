# Get the VM objects
$vms = Get-VM

# Collect VM details in an array
$vmDetailsList = $vms | ForEach-Object {
    $datastores = ($_ | Get-Datastore | Select-Object -ExpandProperty Name) -join ', '
    $ipAddress  = if ($_.Guest.IPAddress) { $_.Guest.IPAddress -join ', ' } else { '' }
    $macAddress = ($_ | Get-NetworkAdapter | Select-Object -ExpandProperty MacAddress) -join ', '
    $guestOS    = if ($_.Guest.OSFullName) { $_.Guest.OSFullName } else { '' }
    $hostName   = if ($_.VMHost.Name) { $_.VMHost.Name } else { '' }
    $computerName = if ($_.Guest.HostName) { $_.Guest.HostName } else { '' }
    $vmTools    = if ($_.ExtensionData.Guest.ToolsVersionStatus2) { $_.ExtensionData.Guest.ToolsVersionStatus2 } else { '' }

    [PSCustomObject]@{
        Name         = $_.Name
        PowerState   = $_.PowerState
        VMHost       = $_.VMHost
        Datastore    = $datastores
        GuestOS      = $guestOS
        IPAddress    = $ipAddress
        MacAddress   = $macAddress
        HostName     = $hostName
        ComputerName = $computerName
        VMTools      = $vmTools
    }
}

# Output the details
$vmDetailsList | Format-List
