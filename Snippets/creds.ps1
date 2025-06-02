
# Install the CredentialManager module if not already installed
#Install-Module -Name CredentialManager -Force -Scope CurrentUser

# Import the CredentialManager module
Import-Module CredentialManager

# Retrieve the stored credential
$credential = Get-StoredCredential -Target "creds"

# Check if the credential was retrieved successfully
if ($credential -ne $null) {
    # Print the username to the console
    Write-Output "Username: $($credential.UserName)"
    # Print the password to the console (for demonstration purposes)
    Write-Output "Password: $($credential.GetNetworkCredential().Password)"
} else {
    Write-Output "Credential not found."
}

# Retrieve all credentials using cmdkey
$cmdkeyOutput = cmdkey /list

# Example parsing logic to find the credential
if ($cmdkeyOutput -match "creds") {
    Write-Output "Credential 'creds' found."
    # Extract the line containing the credential details
    $credentialDetails = $cmdkeyOutput -split "`n" | Where-Object { $_ -match "creds" }

    # Extract and print the username
    $usernameLine = $credentialDetails -split "`r" | Where-Object { $_ -match "User" }
    $username = $usernameLine -replace ".*User: ", ""
    Write-Output "Username: $username"
} else {
    Write-Output "Credential 'creds' not found."
}

