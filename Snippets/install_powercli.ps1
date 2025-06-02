### PowerCLI module 

# Install
Install-Module -Name VMware.PowerCLI -Force

# Resolve invalid certificate
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
