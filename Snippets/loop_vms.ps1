$vms = Get-VM
$vms | ForEach-Object {
    Write-Output "VM Name: $($_.Name)"
}

foreach ($vm in $vms) {
    Write-Output "Processing VM: $($vm)"
}
