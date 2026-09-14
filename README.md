# PowerShell_snippets
Collection of useful snippets for day to day usage in PoweShell and PowerCLI.

# Basic PowerCLI workflow:
 - ### Save and load credentials securely.
 - ### Connect to desired vSphere instance(s). 
 - ### Gather details about: 
> clusters, hosts, vms, connections, datastores...
 - ### Process actions such as: 
> clone(template/vm)/delete/snapshot/revert/start/stop/reset...
 - ### Process post actions such as:
> network configuration, IP, hostname, DNS...
 - ### Disconnecct from connected vSphere instance(s).


# Useful commands:
```
# List all commands
Get-Command

# List and filter by module 
Get-Command -Module Hyper-V

# List and filter by type
Get-Command -CommandType Cmdlet

# List by keyword
Get-Command *Disk*
```

```
# Filter service by status
Get-Service | Where-Object Status -eq 'Running'

# Select by property
Get-Process | Select-Object Name, CPU, WorkingSet

# Sorting process by first N
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Get properties and methods of an object
Get-Service | Get-Member

# Iteration over object
Get-Service | ForEach-Object { $_.Name.ToUpper() }
```
```

# Loop for each
$vms = "VM1", "VM2", "VM3"
foreach ($vm in $vms) {
    Write-Host "Processing: $vm"
}

# Loop for
for ($i = 1; $i -le 3; $i++) {
    Write-Host "Attempt: $i"
}

# Loop while 
$counter = 1
while ($counter -le 3) {
    Write-Host "Counting: $counter"
    $counter++
}
```
```
# Conditions. Is process running?
$service = Get-Service -Name "W3SVC"
if ($service.Status -eq 'Running') {
    Write-Host "Service is running."
} else {
    Write-Host "Service is stopped."
}

# Get cmdlet help
Get-Help Get-VM -Detailed

# Command time duration measure
Measure-Command { Get-ChildItem C:\ -Recurse -ErrorAction SilentlyContinue }

# Write to file
Get-Process | Out-File "processes.txt"
Get-Content "processes.txt"
```

# Example: 
Allow GPU-P in Hyper-V VM 
```
PS C:\Windows\system32> Get-VM

Name            State CPUUsage(%) MemoryAssigned(M) Uptime   Status             Version
----            ----- ----------- ----------------- ------   ------             -------
Windows_Hyper_V Off   0           0                 00:00:00 Operating normally 9.0

PS C:\Windows\system32> Add-VMGpuPartitionAdapter -VMName "Windows_Hyper_V"
PS C:\Windows\system32> Set-VMGpuPartitionAdapter -VMName "Windows_Hyper_V" -MinPartitionVRAM 512 -MaxPartitionVRAM 4096 -OptimalPartitionVRAM 2048
```
