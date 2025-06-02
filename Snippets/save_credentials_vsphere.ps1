### Save crypted credentials

# Get credentials interactively 
$credential = Get-Credential

$credsPath = "D:\VMware\vsphere.xml"

$credential | Export-Clixml -Path $credsPath