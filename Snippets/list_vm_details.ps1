$listVMs = @("vmw-ubuntu.24.4-ansible-host")

$listVMs | ForEach-Object {
    $vm = Get-VM -Name $_

    $vmDetails = [PSCustomObject]@{
        Name         = $vm.Name
        PowerState   = $vm.PowerState
        VMHost       = $vm.VMHost
        Datastore    = ($vm | Get-Datastore | Select-Object -ExpandProperty Name) -join ', '
        GuestOS      = $vm.Guest.OSFullName
        IPAddress    = $vm.Guest.IPAddress -join ', '
        MacAddress   = ($vm | Get-NetworkAdapter | Select-Object -ExpandProperty MacAddress) -join ', '
        HostName     = $vm.VMHost.Name
        ComputerName = $vm.Guest.HostName
        
        VMTools      = $vm.ExtensionData.Guest.ToolsVersionStatus2
    }
    $vmDetails | Format-List
}


