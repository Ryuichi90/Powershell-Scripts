# setting variables
$scriptPath = "C:\Temp\Script.ps1"
$hostname = "client1"
$localAdmin = "labadmin"
$localADminPasswd = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force

$scriptContent = Get-Content $scriptPath -Raw		
$credential = New-Object System.Management.Automation.PSCredential ($localAdmin, $localADminPasswd)
$PSSessionOption = New-PSSessionOption -ProxyAccessType NoProxyServer
$RemoteSession = New-PSSession $hostname -Credential $credential -SessionOption $PSSessionOption

# getting the original state of the WinRM and setting it to auto and starting it
$service = Get-WmiObject -Computer $hostname -Credential $credential -Class Win32_Service -Filter "Name='winrm'"
$originalStartType = $service.StartMode
$originalStatus = $service.State
$service.ChangeStartMode("Automatic") | Out-Null
$service.StartService() | Out-Null

# script block
Invoke-Command -Session $RemoteSession {
					param($credential, $scriptContent)
					$destination = "\\CM1\TS Reports"
					New-PSDrive  -name "MyNewDrive" -root $destination -PSProvider "FileSystem" -Credential $credential | out-null
                    Invoke-Expression $scriptContent
					Remove-PSDrive "MyNewDrive" -Force
				} -ArgumentList $credential, $scriptContent

Remove-PSSession $RemoteSession


# setting back the original state of the WinRM on the computer
$service.ChangeStartMode("$originalStartType") | Out-Null
if ($originalStatus -eq "Stopped"){
			$service.StopService() | Out-Null
}

