### List all vSphere connections

# List memebrs properties and methods
#$global:DefaultVIServers | Select-Object | Get-Member

$global:DefaultVIServers | Select-Object -Property Name, User, ServiceUri, Port, Version