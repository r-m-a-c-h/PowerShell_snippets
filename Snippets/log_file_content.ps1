# Define the file path
$filePath = ".node_repl_history"

# Read all lines into an array
$lines = Get-Content $filePath

$lines

# Count the number of lines
$lineCount = $lines.Count
Write-Host "Total number of lines: $lineCount"

# Print the first and last line
Write-Host "First line: $($lines[0])"
Write-Host "Last line: $($lines[-1])"

# Edit the second line (index 1)
$lines[1] = "This is the new second line."

# Save the updated content back to the file
$lines | Set-Content $filePath

Write-Host "Second line updated successfully."

"First line$([Environment]::NewLine)Second line" | Set-Content "test_file.txt"
