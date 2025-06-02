# Start listed VM's

# Start (power on) all VMs in the list
Import-Csv vmlist.csv | ForEach-Object {
    $vm = Get-VM -Name $_.Name -ErrorAction SilentlyContinue
    if ($vm -and $vm.PowerState -eq "PoweredOff") {
        Start-VM -VM $vm -Confirm:$false
        Write-Host "[✔] Started VM: $($_.Name)"
    }
}