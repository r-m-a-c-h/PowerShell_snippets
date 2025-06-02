# Get the list of hosts
$hosts = Get-VMHost

# Display the hosts
$hosts | ForEach-Object {
    Write-Output "Host Name: $($_.Name)"
}

$locationCSV = "C:\tmp\hosts_$vCenterServer.csv"

# Export the datastore information to a CSV file
$vmDetails | Export-Csv -Path $locationCSV -NoTypeInformation