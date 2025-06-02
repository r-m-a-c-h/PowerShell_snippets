### Save crypted credentials

# Get credentials interactively 
$credential = Get-Credential

$credsPath = "D:\VMware\esxi.xml"

$credential | Export-Clixml -Path $credsPath