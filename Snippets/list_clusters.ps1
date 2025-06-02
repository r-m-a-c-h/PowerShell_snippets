# Define vCenter server name (add this missing variable)
$vCenterServer = "192.168.31.83"

# Create output directory if missing
$outputDir = "C:\tmp"
if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force }

# Single pipeline operation for better efficiency
Get-Cluster | Select-Object Name, HAEnabled, DRSAutomationLevel | 
    Export-Csv -Path "$outputDir\clusters_$vCenterServer.csv" -NoTypeInformation
