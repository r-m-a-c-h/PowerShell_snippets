### Unzip all zip files in subdirectories 

# Set the root directory where the search should begin
$rootPath = "C:\tmp\"

# Find all .zip files in the directory and subdirectories
Get-ChildItem -Path $rootPath -Recurse -Filter *.zip | ForEach-Object {
    $zipFile = $_.FullName
    $destination = Join-Path -Path $_.DirectoryName -ChildPath ($_.BaseName)

    # Create the destination folder if it doesn't exist
    if (-not (Test-Path -Path $destination)) {
        New-Item -ItemType Directory -Path $destination | Out-Null
    }

    # Extract the zip file
    Expand-Archive -Path $zipFile -DestinationPath $destination -Force
    Write-Host "Extracted: $zipFile to $destination"
}
