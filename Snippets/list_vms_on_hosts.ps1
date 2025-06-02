# List vms on host

Get-VMHost -Location "192.168.31.82" | ForEach-Object { 
    Write-Output "Host: $($_.Name)"
    #Get-VM -Location $_ | Select Name HideTableHeaders
    Get-Datastore -RelatedObject $_ | Select-Object Name, FreeSpaceGB, CapacityGB

    Write-Output (Get-VM -Location $_).Count

    Get-VM -Location $_ | Select-Object -ExpandProperty Name

    Write-Output ""
}