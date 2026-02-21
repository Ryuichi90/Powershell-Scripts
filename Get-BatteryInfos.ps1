$designedCapacity = (Get-WmiObject -Class BatteryStaticData -Namespace ROOT\WMI).DesignedCapacity
$fullChargedCapacity = (Get-WmiObject -Class BatteryFullChargedCapacity -Namespace ROOT\WMI).FullChargedCapacity

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Battery informations:" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "DesignedCapacity: " -ForegroundColor Yellow -NoNewline; $designedCapacity
Write-Host "FullChargedCapacity: " -ForegroundColor Yellow -NoNewline; $fullChargedCapacity