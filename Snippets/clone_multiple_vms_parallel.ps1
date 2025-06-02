# ./clone_multiple_vms_parallel.ps1 -SourceVMName "vmw-ubuntu.24.4-template" -CsvPath "clone_list.csv" -vCenter "192.168.31.83" -CredsPath "D:\VMware\vsphere.xml"

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceVMName,
    [Parameter(Mandatory=$true)]
    [string]$CsvPath,
    [Parameter(Mandatory=$true)]
    [string]$vCenter,
    [Parameter(Mandatory=$true)]
    [securestring]$CredsPath
)

# Get script directory for full path resolution
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import CSV
$cloneList = Import-Csv -Path $CsvPath

# Define connection parameters
$credential = Import-Clixml -Path $credsPath 

# Clone multiple VMs with parallel jobs
$jobs = foreach ($vm in $cloneList) {
    $params = @{
        SourceVMName    = $SourceVMName
        TargetVMName    = $vm.TargetVMName
        NewIPAddress    = $vm.NewIPAddress
        SubnetMask      = $vm.SubnetMask
        Gateway         = $vm.Gateway
    }
    
    Start-Job -ScriptBlock {
        param($scriptPath, $params)
        & $scriptPath @params
        Import-Module VMware.PowerCLI -ErrorAction Stop
        Connect-VIServer -Server $vCenter -Credential $credential -ErrorAction Stop
    } -ArgumentList "$scriptDir\clone_vm.ps1", $params
}

# Monitor and report
$results = $jobs | Wait-Job -Timeout 3600 | Receive-Job -ErrorVariable jobErrors

# Output results
$results | Format-Table

# Handle errors
if ($jobErrors) {
    Write-Warning "[⚠] Errors occurred during cloning:"
    $jobErrors | Format-List *
}
