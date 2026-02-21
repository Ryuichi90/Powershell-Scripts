Install-PackageProvider -Name NuGet -Force -Confirm:$False
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$serialNumber = (Get-WmiObject win32_bios | select -ExpandProperty Serialnumber)
$fileName = $serialNumber + "_AutopilotHWID.csv"
Set-Location -Path "HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -Name Get-WindowsAutopilotInfo -Force -Confirm:$False
Get-WindowsAutopilotInfo -OutputFile $fileName -GroupTag "Autopilot-Provisioning"