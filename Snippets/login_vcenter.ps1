### Login to vCenter

Import-Module VMware.PowerCLI

$vCenterServer = "192.168.31.83"

Connect-VIServer -Server $vCenterServer -Credential $credential