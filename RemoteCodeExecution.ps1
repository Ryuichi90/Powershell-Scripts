# setting variables
$hostname = "client1"
$localAdmin = "labadmin"
$localADminPasswd = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ($localAdmin, $localADminPasswd)

# getting the original state of the WinRM and setting it to auto and starting it
$service = Get-WmiObject -Computer $hostname -Credential $credential -Class Win32_Service -Filter "Name='winrm'"
$originalStartType = $service.StartMode
$originalStatus = $service.State
$service.ChangeStartMode("Automatic") | Out-Null
$service.StartService() | Out-Null


$PSSessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer
$RemoteSession = New-PSSession $hostname -Credential $credential -SessionOption $PSSessionOption

# script block
Invoke-Command -Session $RemoteSession {
					param($credential)
					$destination = "\\CM1\TS Reports"
					New-PSDrive  -name "MyNewDrive" -root $destination -PSProvider "FileSystem" -Credential $credential | out-null
                    
                    #command execution part
                    $hostname = $env:COMPUTERNAME
                    $basePath = "\\CM1\TS Reports"
                    $gpresultPath = "\\CM1\TS Reports\" + $hostname + "_gpresult.html"
                    

                    gpresult /h $gpresultPath /f

                    $logs = @("System","Application","Security")
                    foreach ($log in $logs) {
                        wevtutil epl $log "$basePath\$log.evtx"
                    }

                    Get-WindowsUpdateLog -LogPath "$basePath\WindowsUpdate.log"

					Remove-PSDrive "MyNewDrive" -Force
				} -ArgumentList $credential

Remove-PSSession $RemoteSession

# setting back the original state of the WinRM on the computer
$service.ChangeStartMode("$originalStartType") | Out-Null
if ($originalStatus -eq "Stopped"){
			$service.StopService() | Out-Null
}

