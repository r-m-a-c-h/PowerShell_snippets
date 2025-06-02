$vmDetails = Get-VM | Select-Object @(
    @{Name="Name"; Expression={$_.Name}},
    @{Name="PowerState"; Expression={$_.PowerState}},
    @{Name="NumCPU"; Expression={$_.NumCpu}},
    @{Name="MemoryMB"; Expression={[math]::Round($_.MemoryGB * 1024)}},
    @{Name="GuestOS"; Expression={$_.Guest.OSFullName}},
    @{Name="IPAddress"; Expression={$_.Guest.IPAddress -join "; "}},
    @{Name="Cluster"; Expression={($_.VMHost.Parent).Name}},
    @{Name="Datastore"; Expression={($_.Datastore.Name -join "; ")}},
    @{Name="Host"; Expression={$_.VMHost.Name}},
    @{Name="ProvisionedSpaceGB"; Expression={
        [math]::Round(($_.HardDisks | Measure-Object -Property CapacityGB -Sum).Sum, 2)
    }},
    @{Name="FolderPath"; Expression={
        $folder = $_.Folder
        $path = $folder.Name
        while ($folder.ParentId -and $folder.ParentId -notlike "Datacenters*") {
            $folder = Get-Folder -Id $folder.ParentId
            $path = "$($folder.Name)\$path"
        }
        $path
    }}
) 

$vmDetails | ForEach-Object {
    Write-Host $_.
}

$vmDetails | Export-Csv -Path "VM_Inventory_Detailed.csv" -NoTypeInformation
