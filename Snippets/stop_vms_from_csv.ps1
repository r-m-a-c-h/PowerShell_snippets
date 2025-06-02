# Stop listed VM's

# Stop (power off) all VMs in the list
Import-Csv vmlist.csv | ForEach-Object {
    $vm = Get-VM -Name $_.Name -ErrorAction SilentlyContinue
    if ($vm -and $vm.PowerState -eq "PoweredOn") {
        Stop-VM -VM $vm -Confirm:$false
        Write-Host "Stopped VM: $($_.Name)"
    }
}