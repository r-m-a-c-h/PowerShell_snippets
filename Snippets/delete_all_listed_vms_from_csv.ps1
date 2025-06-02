Import-Csv vmlist.csv | ForEach-Object {
    $vm = Get-VM -Name $_.Name -ErrorAction SilentlyContinue
    if ($vm) {
        if ($vm.PowerState -eq "PoweredOn") {
            Stop-VM -VM $vm -Confirm:$false -ErrorAction SilentlyContinue
            #Write-Host "[✔] Stopped VM: $vm"
        }
        Remove-VM -VM $vm -DeletePermanently -Confirm:$false
        Write-Host "[✔] Removed VM: $vm"
    }
}
