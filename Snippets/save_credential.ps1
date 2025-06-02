$credsPath = "C:\tmp\credential.xml"

$credential = Get-Credential

$credential | Export-Clixml -Path $credsPath
