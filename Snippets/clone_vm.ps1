# ./

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceVMName,

    [Parameter(Mandatory=$true)]
    [string]$TargetVMName,

    [string]$NewIPAddress,  # Only required for static IP
    [string]$SubnetMask,    # Only required for static IP
    [string]$Gateway,       # Only required for static IP

    [Parameter(Mandatory=$true)]
    [pscredential]$LinuxPasswordFile = "Passw0rd!",
    [Parameter(Mandatory=$true)]
    [pscredential]$WindowsPasswordFile = "pass"
)

# Sanitize hostname for OS (replace dots with dashes)
$SafeTargetVMName = $TargetVMName -replace '\.', '-'

# Check if source is a VM or template
$sourceVM = Get-VM -Name $SourceVMName -ErrorAction SilentlyContinue
$sourceTemplate = Get-Template -Name $SourceVMName -ErrorAction SilentlyContinue

if (-not $sourceVM -and -not $sourceTemplate) {
    Write-Error "[❌] Source '$SourceVMName' not found as VM or template"
    exit
}

# Check source VM is powered off
if ($sourceVM) {
    if ($sourceVM.PowerState -ne "PoweredOff") {
        Write-Error "[❌] Source VM must be powered off. Current state: $($sourceVM.PowerState)"
        exit
    }
    $cloneType = "VM"
    Write-Host "[✔] VM $sourceVM : exists"
} else {
    if (-not $sourceTemplate) {
        Write-Error "[❌] Template '$SourceVMName' not found"
        exit
    }
    $cloneType = "Template"
    Write-Host "[✔] Template $sourceTemplate : exists"
}

# Check target VM doesn't exist
if (Get-VM -Name $TargetVMName -ErrorAction SilentlyContinue) {
    Write-Error "[❌] Target VM '$TargetVMName' already exists"
    exit
} else {
    Write-Host "[✔] Target VM '$TargetVMName' Does not exist"
}

# Get source configuration
try {
    if ($cloneType -eq "VM") {
        $folder = Get-Folder -Id $sourceVM.FolderId
        $resourcePool = Get-ResourcePool -Id $sourceVM.ResourcePoolId
        $datastore = $sourceVM | Get-Datastore
    } else {
        # Template configuration
        $hostMoid = $sourceTemplate.ExtensionData.Runtime.Host.Value
        $vmHost = Get-VMHost -Id "HostSystem-$hostMoid"
        $folder = Get-Folder -Name "VM"  # Default VM folder
        $resourcePool = $vmHost.Parent
        $datastore = Get-Datastore -VMHost $vmHost | Select-Object -First 1
    }
}

catch {
    Write-Error "[❌] Failed to get source configuration: $_"
    exit
}

# Calculate required disk space (source VM/template size + 20% buffer)
if ($cloneType -eq "VM") {
    $requiredSpaceGB = ($sourceVM | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum
} else {
    $requiredSpaceGB = ($sourceTemplate | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum
}
$requiredSpaceGB = [math]::Round($requiredSpaceGB * 1.2, 2)  # Add 20% buffer

# Verify datastore has enough free space
<#
if ($datastore.FreeSpaceGB -lt $requiredSpaceGB) {
    Write-Error "[❌] Insufficient space in datastore '$($datastore.Name)'. Required: ${requiredSpaceGB}GB, Available: $($datastore.FreeSpaceGB)GB"
    exit
} else {
    Write-Host "[✔] Datastore '$($datastore.Name)' has sufficient space (${requiredSpaceGB}GB required, $($datastore.FreeSpaceGB)GB available)"
}
#>

# Find datastore with most free space if current is insufficient
#<#
if ($datastore.FreeSpaceGB -lt $requiredSpaceGB) {
    Write-Host "[⚠] Low space in '$($datastore.Name)', searching alternate datastores..."
    $altDatastore = Get-Datastore -VMHost $vmHost | 
        Where-Object {$_.FreeSpaceGB -gt $requiredSpaceGB} |
        Sort-Object -Property FreeSpaceGB -Descending | 
        Select-Object -First 1
    
    if (-not $altDatastore) {
        Write-Error "[❌] No datastore found with ${requiredSpaceGB}GB free space"
        exit
    }
    Write-Host "[✔] Switching to datastore '$($altDatastore.Name)' with $($altDatastore.FreeSpaceGB)GB free space"
    $datastore = $altDatastore
}
##>

# Clone VM
try {
    if ($cloneType -eq "VM") {
        $newVM = New-VM -Name $TargetVMName `
            -VM $sourceVM `
            -Location $folder `
            -ResourcePool $resourcePool `
            -Datastore $datastore `
            -DiskStorageFormat Thin `
            -ErrorAction Stop
    } else {
        $newVM = New-VM -Name $TargetVMName `
            -Template $sourceTemplate `
            -Location $folder `
            -ResourcePool $resourcePool `
            -Datastore $datastore `
            -DiskStorageFormat Thin `
            -ErrorAction Stop
    }
    Write-Host "[✔] Successfully cloned from $cloneType : $SourceVMName → $TargetVMName"
}
catch {
    Write-Error "[❌] Cloning failed: $_"
    exit
}

# Configure networking if static IP required (Windows only)
if ($NewIPAddress -and $SubnetMask -and $Gateway) {
    try {
        $scriptText = "netsh interface ipv4 set address name='Ethernet0' static $NewIPAddress $SubnetMask $Gateway 1"
        Invoke-VMScript -VM $newVM -ScriptText $scriptText -ScriptType Bat -GuestUser $WindowsUser -GuestPassword $WindowsPassword -ErrorAction Stop
        Write-Host "[✔] Static IP configured: $NewIPAddress"
    }
    catch {
        Write-Warning "[❌] Failed to configure static IP: $_"
    }
}

# Ensure the new VM is powered on before renaming
if ($newVM.PowerState -ne "PoweredOn") {
    Write-Host "[✔] Powering on VM '$($newVM.Name)' before renaming hostname..."
    Start-VM -VM $newVM | Out-Null

    # Wait for VM to be fully powered on
    do {
        Start-Sleep -Seconds 5
        $newVM = Get-VM -Id $newVM.Id
    } while ($newVM.PowerState -ne "PoweredOn")
    Write-Host "[✔] VM '$($newVM.Name)' is now powered on."
}

# Wait for VMware Tools and OS info
$timeout = 300 # seconds
$elapsed = 0
$interval = 5

do {
    Start-Sleep -Seconds $interval
    $elapsed += $interval
    $newVM = Get-VM -Id $newVM.Id
    $guestState = $newVM.ExtensionData.Guest.ToolsStatus
    $osName = $newVM.Guest.OSFullName
    Write-Host "Waiting for VMware Tools... Status: $guestState, OS: $osName"
} while ( 
    ($guestState -ne "toolsOk" -and $guestState -ne "toolsOld") -or 
    [string]::IsNullOrWhiteSpace($osName) -and 
    $elapsed -lt $timeout
)
    
if ([string]::IsNullOrWhiteSpace($newVM.Guest.OSFullName)) {
    Write-Error "[❌] VMware Tools did not become ready or OS info unavailable after $timeout seconds."
    exit
}

# Change hostname
try {
    # Set VMware display name (optional, for vCenter inventory)
    $newVM | Set-VM -Name $TargetVMName -Confirm:$false

    # OS-specific configuration
    Write-Host "[✔] Detected guest OS: $($newVM.Guest.OSFullName)"

    if ($newVM.Guest.OSFullName -match "Linux") {
        Write-Host "Configuring Linux hostname..."

        $linuxCmd = @"
echo '$LinuxPassword' | sudo -S hostnamectl set-hostname $SafeTargetVMName
echo '$LinuxPassword' | sudo -S sed -i.bak 's/^127.0.1.1.*/127.0.1.1\t$SafeTargetVMName/' /etc/hosts
"@
        $secPassword = ConvertTo-SecureString $LinuxPassword -AsPlainText -Force
        $guestCreds = New-Object System.Management.Automation.PSCredential($LinuxUser, $secPassword)

        $maxRetries = 3
        $retryCount = 0
        do {
            try {
                $result = Invoke-VMScript -VM $newVM `
                    -ScriptText $linuxCmd `
                    -ScriptType Bash `
                    -GuestCredential $guestCreds `
                    -ErrorAction Stop

                if ($result.ExitCode -ne 0) {
                    throw "Linux command failed. Exit code: $($result.ExitCode). Output: $($result.ScriptOutput)"
                }
                Write-Host "[✔] Linux hostname updated to $SafeTargetVMName"
                break
            }
            catch {
                $retryCount++
                Write-Warning "[❌] Attempt $retryCount failed: $_"
                if ($retryCount -ge $maxRetries) {
                    throw "Failed to update Linux hostname after $maxRetries attempts."
                }
                Start-Sleep -Seconds 5
            }
        } while ($true)
    }
    else {
        Write-Host "Configuring Windows hostname..."
        $renameScript = @"
wmic computersystem where name='%computername%' call rename name='$SafeTargetVMName'
shutdown /r /t 0
"@
        Invoke-VMScript -VM $newVM `
            -ScriptText $renameScript `
            -ScriptType Bat `
            -GuestUser $WindowsUser `
            -GuestPassword $WindowsPassword `
            -ErrorAction Stop
        Write-Host "[✔] Windows hostname updated to $SafeTargetVMName (VM will reboot)"
    }

    Write-Host "[✔] Hostname update complete for OS type: $($newVM.Guest.OSFullName)"
}
catch {
    Write-Warning "[❌] Failed to rename computer: $_"
}