$computer = ""
$credential = Get-Credential
$service = Get-WmiObject -Computer "$computer" -Credential $credential -Class Win32_Service -Filter "Name='winrm'"

$originalStartType = $service.StartMode
$originalStatus = $service.State
$service.ChangeStartMode("Automatic") | Out-Null
$service.StartService() | Out-Null
$service.ChangeStartMode("$originalStartType") | Out-Null

Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {
             Restart-Computer -Force
             }
		
$service.ChangeStartMode("$originalStartType") | Out-Null

if ($originalStatus -eq "Stopped"){
			$service.StopService() | Out-Null
		}
