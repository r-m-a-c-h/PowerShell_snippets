# Get credentials interactively 
$Cred = Get-Credential

# Export
$Cred | Export-Clixml -Path "C:\tmp\mycred.xml"

# Import
#$Cred = Import-Clixml -Path "C:\tmp\mycred.xml"
