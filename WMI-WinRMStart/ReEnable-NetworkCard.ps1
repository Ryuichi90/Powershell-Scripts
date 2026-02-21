$computer = ""
$cred = Get-Credential

$service = Get-WmiObject -Computer "$computer" -Credential $credential -Class Win32_Service -Filter "Name='winrm'"
        $originalStartType = $service.StartMode
        $originalStatus = $service.State
        $service.ChangeStartMode("Automatic") | Out-Null
        $service.StartService() | Out-Null

      
        Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {           
			
			
			Get-NetConnectionProfile | Where-Object {$_.Name -contains "ad.harman.com"} | ForEach-Object {
            $index = $_.InterfaceIndex
			$adapter = Get-NetAdapter | Where-Object {$_.InterfaceIndex -eq $index}
			Disable-NetAdapter -Name $adapter.Name -Confirm:$false
			Start-Sleep -Seconds 5
			Enable-NetAdapter -Name $adapter.Name -Confirm:$false
			}
        }
		
		$service.ChangeStartMode("$originalStartType") | Out-Null
		if ($originalStatus -eq "Stopped"){
			$service.StopService() | Out-Null
		}
