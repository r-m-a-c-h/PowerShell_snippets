# Create a custom object for each datastore with the required properties
$datastoreInfo = $datastores | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.Name
        Capacity    = $_.CapacityGB
        FreeSpaceGB = $_.FreeSpaceGB
        Type        = $_.Type
    }
}

$locationCSV = "C:\tmp\datastores_$vCenterServer.csv"

# Export the datastore information to a CSV file
$datastoreInfo | Export-Csv -Path $locationCSV -NoTypeInformation

Write-Output "Datastore information exported successfully to $locationCSV"
