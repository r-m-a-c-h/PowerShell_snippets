# List hosts on clusters
Get-Cluster | ForEach-Object {
    Write-Output "Cluster: $($_.Name)"
    Get-VMHost -Location $_ | Select-Object Name
    Write-Output ""
}

