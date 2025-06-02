$vmNames = @("vmw-ubuntu.24.4-06", "vmw-ubuntu.24.4-05", "vmw-ubuntu.24.4-07", "vmw-ubuntu.24.4-09", "vmw-ubuntu.24.4-10")

foreach ($name in $vmNames) {
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if ($vm) {
        if ($vm.PowerState -eq "PoweredOn") {
            Stop-VM -VM $vm -Confirm:$false -ErrorAction SilentlyContinue
        }
        Remove-VM -VM $vm -DeletePermanently -Confirm:$false
        Write-Host "Deleted VM: $name"
    } else {
        Write-Warning "VM '$name' not found."
    }
}
