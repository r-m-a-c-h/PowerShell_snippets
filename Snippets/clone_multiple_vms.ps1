# ./clone_multiple_vms.ps1 -SourceVMName "vmw-ubuntu.24.4-template" -CsvPath "clone_list.csv"

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceVMName,

    [Parameter(Mandatory=$true)]
    [string]$CsvPath,


    [Parameter(Mandatory=$true)]
    [pscredential]$LinuxCredential,
    [Parameter(Mandatory=$true)]
    [pscredential]$WindowsCredential
)

$LinuxCredential = Import-Clixml -Path "C:\creds\linux_cred.xml"
$WindowsCredential = Import-Clixml -Path "C:\creds\windows_cred.xml"

# Import CSV
$cloneList = Import-Csv -Path $CsvPath
Write-Host "[✔] CSV loaded $CsvPath"

# Pre-Clone Validation
Write-Host "`n[=== Pre-Clone Validation ===]"
$existingVMs = Get-VM -Name ($cloneList.TargetVMName) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
$existingCloneVMs = @()
$newCloneVMs = @()

foreach ($vm in $cloneList) {
    if ($existingVMs -contains $vm.TargetVMName) {
        $existingCloneVMs += $vm.TargetVMName
    } else {
        $newCloneVMs += $vm.TargetVMName
    }
}

Write-Host "`n[VM Status Report]"
Write-Host "Total VMs in CSV    : $($cloneList.Count)"
Write-Host "Already exist       : $($existingCloneVMs.Count)"
Write-Host "Will be cloned      : $($newCloneVMs.Count)"

if ($existingCloneVMs.Count -gt 0) {
    Write-Host "`n[Existing VMs]"
    $existingCloneVMs | ForEach-Object { Write-Host "- $_" }
}

if ($newCloneVMs.Count -eq 0) {
    Write-Error "`n[❌] No new VMs to clone. Exiting."
    exit
}

Write-Host "`n[New VMs to Clone]"
$newCloneVMs | ForEach-Object { Write-Host "- $_" }

$confirmation = Read-Host "`nProceed with cloning? (Y/N)"
if ($confirmation -ne "Y") {
    Write-Host "Aborted by user."
    exit
}

$cloneListToProcess = $cloneList | Where-Object { $newCloneVMs -contains $_.TargetVMName }


# Check if source is a VM or template
$sourceVM = Get-VM -Name $SourceVMName -ErrorAction SilentlyContinue
$sourceTemplate = Get-Template -Name $SourceVMName -ErrorAction SilentlyContinue

if (-not $sourceVM -and -not $sourceTemplate) {
    Write-Error "[❌] Source '$SourceVMName' not found as VM or template"
    exit
}

if ($sourceVM) {
    if ($sourceVM.PowerState -ne "PoweredOff") {
        Write-Error "[❌] Source VM must be powered off. Current state: $($sourceVM.PowerState)"
        exit
    }
    $cloneType = "VM"
    Write-Host "[✔] VM $SourceVMName : exists"
} else {
    $cloneType = "Template"
    Write-Host "[✔] Template $SourceVMName : exists"
}

# Get source configuration for all clones
try {
    if ($cloneType -eq "VM") {
        $folder = Get-Folder -Id $sourceVM.FolderId
        $resourcePool = Get-ResourcePool -Id $sourceVM.ResourcePoolId
        $datastore = $sourceVM | Get-Datastore
    } else {
        $hostMoid = $sourceTemplate.ExtensionData.Runtime.Host.Value
        $vmHost = Get-VMHost -Id "HostSystem-$hostMoid"
        $folder = Get-Folder -Name "VM"
        $resourcePool = $vmHost.Parent
        $datastore = Get-Datastore -VMHost $vmHost | Sort-Object FreeSpaceGB -Descending | Select-Object -First 1
    }
} catch {
    Write-Error "[❌] Failed to get source configuration: $_"
    exit
}

# Calculate required disk space (source VM/template size + 20% buffer)
if ($cloneType -eq "VM") {
    $requiredSpaceGB = ($sourceVM | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum
} else {
    $requiredSpaceGB = ($sourceTemplate | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum
}
$requiredSpaceGB = [math]::Round($requiredSpaceGB * 1.2 * $cloneListToProcess.Count, 2)

# Verify datastore has enough free space
if ($datastore.FreeSpaceGB -lt $requiredSpaceGB) {
    Write-Error "[❌] Insufficient space in datastore '$($datastore.Name)'. Required: ${requiredSpaceGB}GB, Available: $($datastore.FreeSpaceGB)GB"
    exit
} else {
    Write-Host "[✔] Datastore '$($datastore.Name)' has sufficient space (${requiredSpaceGB}GB required, $($datastore.FreeSpaceGB)GB available)"
}

# Find datastore with most free space if current is insufficient
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

# Clone all VMs using -RunAsync, then wait for all to finish
$tasks = @()
foreach ($vm in $cloneListToProcess) {
    $TargetVMName = $vm.TargetVMName
    # Check if target VM already exists
    if (Get-VM -Name $TargetVMName -ErrorAction SilentlyContinue) {
        Write-Warning "[⚠] Target VM '$TargetVMName' already exists, skipping"
        continue
    }
    if ($cloneType -eq "VM") {
        $task = New-VM -Name $TargetVMName `
            -VM $sourceVM `
            -Location $folder `
            -ResourcePool $resourcePool `
            -Datastore $datastore `
            -DiskStorageFormat Thin `
            -RunAsync
    } else {
        $task = New-VM -Name $TargetVMName `
            -Template $sourceTemplate `
            -Location $folder `
            -ResourcePool $resourcePool `
            -Datastore $datastore `
            -DiskStorageFormat Thin `
            -RunAsync
    }
    Write-Host "[✔] Started cloning $TargetVMName..."
    $tasks += $task
}

# Wait for all clone tasks to finish
if ($tasks.Count -gt 0) {
    Write-Host "[...] Waiting for all clone tasks to complete..."
    $tasks | Wait-Task
    Write-Host "[✔] All clones completed."
} else {
    Write-Host "[!] No VMs to clone."
    exit
}

# Post-clone customization (hostname, networking)
foreach ($vm in $cloneListToProcess) {
    $TargetVMName = $vm.TargetVMName
    $NewIPAddress = $vm.NewIPAddress
    $SubnetMask   = $vm.SubnetMask
    $Gateway      = $vm.Gateway
    $SafeTargetVMName = $TargetVMName -replace '\.', '-'

    $newVM = Get-VM -Name $TargetVMName -ErrorAction SilentlyContinue
    if (-not $newVM) {
        Write-Warning "[⚠] Could not find cloned VM '$TargetVMName', skipping customization."
        continue
    }

    # Ensure the new VM is powered on before renaming
    if ($newVM.PowerState -ne "PoweredOn") {
        Write-Host "[✔] Powering on VM '$($newVM.Name)' before customization..."
        Start-VM -VM $newVM | Out-Null
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
        Write-Host "[$TargetVMName] Waiting for VMware Tools... Status: $guestState, OS: $osName"
    } while (
        ($guestState -ne "toolsOk" -and $guestState -ne "toolsOld") -or
        [string]::IsNullOrWhiteSpace($osName) -and
        $elapsed -lt $timeout
    )
    if ([string]::IsNullOrWhiteSpace($newVM.Guest.OSFullName)) {
        Write-Warning "[⚠] VMware Tools did not become ready or OS info unavailable after $timeout seconds for $TargetVMName."
        continue
    }

    # Change hostname
    try {
        $newVM | Set-VM -Name $TargetVMName -Confirm:$false
        Write-Host "[✔] Detected guest OS: $($newVM.Guest.OSFullName)"
        if ($newVM.Guest.OSFullName -match "Linux") {
            Write-Host "Configuring Linux hostname for $TargetVMName..."
            $linuxCmd = @"
echo '$LinuxPassword' | sudo -S hostnamectl set-hostname $SafeTargetVMName
echo '$LinuxPassword' | sudo -S sed -i.bak 's/^127.0.1.1.*/127.0.1.1`t$SafeTargetVMName/' /etc/hosts
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
                    Write-Warning "[⚠] Attempt $retryCount failed: $_"
                    if ($retryCount -ge $maxRetries) {
                        throw "Failed to update Linux hostname after $maxRetries attempts."
                    }
                    Start-Sleep -Seconds 5
                }
            } while ($true)
        } else {
            Write-Host "Configuring Windows hostname for $TargetVMName..."
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
    } catch {
        Write-Warning "[⚠] Failed to rename computer for $TargetVMName : $_"
        continue
    }

    # Configure networking if static IP required (Windows only)
    if ($NewIPAddress -and $SubnetMask -and $Gateway) {
        try {
            $scriptText = "netsh interface ipv4 set address name='Ethernet0' static $NewIPAddress $SubnetMask $Gateway 1"
            Invoke-VMScript -VM $newVM -ScriptText $scriptText -ScriptType Bat -GuestUser $WindowsUser -GuestPassword $WindowsPassword -ErrorAction Stop
            Write-Host "[✔] Static IP configured: $NewIPAddress"
        }
        catch {
            Write-Warning "[⚠] Failed to configure static IP for $TargetVMName : $_"
        }
    }
}

Write-Host "[✔] All requested clones and customizations complete."
