$computer = ""
$credential = Get-Credential

$global:service = Get-WmiObject -Computer $computer -Credential $credential -Class Win32_Service -Filter "Name='winrm'"
$global:originalStartType = $service.StartMode
$global:originalStatus = $service.State
$service.ChangeStartMode("Automatic") | Out-Null
$service.StartService() | Out-Null

Write-Host "$computer - Dameware will be installed..."
	Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {
			$username = $env:USERNAME
			Copy-Item -Path "\\servername\Departments\IT\00_Public\Dameware" -Destination "C:\Users\$username\Desktop" -Recurse -Force
			$installerPath = "C:\Users\$username\Desktop\Dameware\Deploy-Application.ps1"
			powershell -ExecutionPolicy Bypass -File $installerPath | Out-Null
			Start-Sleep -Seconds 2
			Remove-Item -Recurse -Force "C:\Users\$username\Desktop\Dameware"
	}
		
$service.ChangeStartMode("$originalStartType") | Out-Null
	if ($originalStatus -eq "Stopped"){
			$service.StopService() | Out-Null
	}
