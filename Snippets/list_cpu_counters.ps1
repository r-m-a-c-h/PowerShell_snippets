Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU -Descending | Format-Table Name, Id, CPU

Get-Counter '\Process(*)\% Processor Time' | 
    Select-Object -ExpandProperty CounterSamples | 
    Where-Object { $_.CookedValue -gt 1 } | 
    Sort-Object CookedValue -Descending | 
    Format-Table InstanceName, CookedValue
