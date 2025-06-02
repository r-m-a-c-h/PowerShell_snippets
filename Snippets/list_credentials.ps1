#Get-Variable | Where-Object { $_.Value -is [System.Management.Automation.PSCredential] }

# Depenedency on credentials manager
# Install-Module -Name CredentialManager -Force
Get-StoredCredential | Format-Table Target, UserName, Password


#Invoke-Command -ComputerName Server01 -Credential $cred -ScriptBlock { whoami }
$Cred = Get-Credential

# Export
$Cred | Export-Clixml -Path "C:\tmp\mycred.xml"

# Import
$Cred = Import-Clixml -Path "C:\tmp\mycred.xml"
