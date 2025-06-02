### Filter by VM Name

# Get a specific VM by name
Get-VM -Name "MyVM"

# Get VMs with names matching a pattern
Get-VM -Name "Web*"

# Get multiple specific VMs
Get-VM -Name "VM1", "VM2", "VM3"

### Filter by Power State

# Get all powered on VMs
Get-VM | Where-Object {$_.PowerState -eq "PoweredOn"}

# Get all powered off VMs
Get-VM | Where-Object {$_.PowerState -eq "PoweredOff"}


### Filter by Location

# Get VMs from a specific cluster
$cluster = Get-Cluster -Name "MyCluster"
Get-VM -Location $cluster

# Get VMs from a specific folder
$folder = Get-Folder -Name "TestFolder"
Get-VM -Location $folder

# Get VMs from a specific datacenter
$datacenter = Get-Datacenter -Name "MyDatacenter"
Get-VM -Location $datacenter

### Filter by Datastore

# Get VMs from a specific datastore
$datastore = Get-Datastore -Name "MyDatastore"
Get-VM -Datastore $datastore

### Customizing VM Information Display

# Display VM name, power state, CPU count and memory in GB
Get-VM | Select-Object Name, PowerState, NumCPU, @{N="MemoryGB";E={$_.MemoryMB/1024}}

# Display VMs with their host and cluster
Get-VM | Select-Object Name, @{N="Host";E={$_.VMHost}}, @{N="Cluster";E={$_.VMHost.Parent.Name}}

# Format as an auto-sized table for better readability
Get-VM | Format-Table -AutoSize

### Export VM details

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

### Working with Multiple vCenters

# Connect to multiple vCenters
Connect-VIServer -Server "vcenter1.example.com", "vcenter2.example.com"

# List all VMs from all connected vCenters
Get-VM

# List VMs from a specific vCenter
Get-VM -Server "vcenter1.example.com"

### Snapshots Information

# Get all VMs with snapshots and details
Get-VM | Get-Snapshot | Select-Object VM, Name, Description, Created, SizeGB
