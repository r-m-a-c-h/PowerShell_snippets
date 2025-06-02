# Get the list of datastores
$datastores = Get-Datastore

# Display detailed information about each datastore
$datastores | ForEach-Object {
    Write-Output "Datastore Name: $($_.Name)"
    Write-Output "Capacity: $($_.CapacityGB) GB"
    Write-Output "Free Space: $($_.FreeSpaceGB) GB"
    Write-Output "Type: $($_.Type)"
    Write-Output "-----------------------------"
}

$locationCSV = "C:\tmp\datastores_$vCenterServer.csv"

# Export the datastore information to a CSV file
$datastoreInfo | Export-Csv -Path $locationCSV -NoTypeInformation

Write-Output "Datastore information exported successfully to $locationCSV"