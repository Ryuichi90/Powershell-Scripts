$computer = ""
$credential = Get-Credential

$hostnames = Get-Content "C:\temp\computerlist.txt"

$Jobs = @()              
                        
foreach ($hostname in $hostnames) {
		$Jobs += Start-Job -ScriptBlock {
			Write-Host "##################################################" -ForegroundColor Yellow        
			if (Test-Connection -ComputerName $using:hostname -Count 2 -Quiet){
				Write-Host "$using:hostname - The PC can be reached over the network" -ForegroundColor Green
				
				$global:service = Get-WmiObject -Computer "$using:hostname" -Credential $using:credential -Class Win32_Service -Filter "Name='winrm'"
				$global:originalStartType = $service.StartMode
				$global:originalStatus = $service.State
				$service.ChangeStartMode("Automatic") | Out-Null
				$service.StartService() | Out-Null

				Write-Host "$using:hostname - " -NoNewline
				Invoke-Command -ComputerName $using:hostname -Credential $using:credential -ScriptBlock {
					$logPath = "C:\Windows\ccmsetup\Logs\ccmsetup.log"

					if (Test-Path $logPath) {
						$lastLine = Get-Content -Path $logPath -Tail 1
						Write-Host $lastLine
					} else {
						Write-Host "The ccmsetup.log can not be found"
					}
				} 
				
				$service.ChangeStartMode("$originalStartType") | Out-Null
				if ($originalStatus -eq "Stopped"){
					$service.StopService() | Out-Null
				}
			}else {Write-Host "$using:hostname - The PC can not be reached over the network" -ForegroundColor Red}

			Write-Host "##################################################" -ForegroundColor Yellow
		}
        
    }
	
	$Jobs | ForEach-Object {
                    Receive-Job -Job $_ -Wait
                    Remove-Job -Job $_
                }
	
