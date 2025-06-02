$credsPath = "C:\tmp\credential.xml"
$username = "YourUsername"
$password = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)
$credential | Export-Clixml -Path $credsPath

$credential = Import-Clixml -Path $credsPath
