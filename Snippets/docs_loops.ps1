for ($i = 0; $i -lt 5; $i++) {
    Write-Output "Iteration $i"
}

$array = 1..5
foreach ($item in $array) {
    Write-Output "Item: $item"
}

$i = 0
while ($i -lt 5) {
    Write-Output "Iteration $i"
    $i++
}

$i = 0
do {
    Write-Output "Iteration $i"
    $i++
} while ($i -lt 5)

1..5 | ForEach-Object {
    Write-Output "Item: $_"
}
