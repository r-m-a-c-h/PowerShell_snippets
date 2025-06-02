### List virtual machines Get-VM

# All available properties of VMs
#Get-VM | Format-List *

# List all available VM properties 
#Get-VM -Name "vm-01" | Format-List *

# List properties and methods of Get-VM
#Get-VM | Get-Member


# Collect extended info about VMs and export to csv
$allVMs = Get-VM
$vmInfo = @()
foreach ($vm in $allVMs) {
    $vmHost = Get-VMHost -VM $vm
    $vmDisk = $vm | Get-HardDisk
    $vmInfo += [PSCustomObject]@{
        Name               = $vm.Name
        PowerState         = $vm.PowerState
        NumCPU             = $vm.NumCpu
        MemoryMB           = $vm.MemoryMB
        GuestOS            = $vm.Guest.OSFullName
        IPAddress          = ($vm.Guest.IPAddress)
        Cluster            = ($vm | Get-Cluster).Name
        Datastore          = ($vm | Get-Datastore).Name
        Host               = $vmHost.Name
        ProvisionedSpaceGB = [Math]::Round(((($vmDisk.CapacityGB | Measure-Object -Sum).Sum)),2)
    }
}
$vmInfo | Export-Csv -Path "D:\VMware\VM_Info.csv" -NoTypeInformation

Write-Output $vmInfo