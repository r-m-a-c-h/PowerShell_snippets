$locationCSV = "C:\tmp\vms_$vCenterServer.csv"

# Export the datastore information to a CSV file
$vmDetails | Export-Csv -Path $locationCSV -NoTypeInformation