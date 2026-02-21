$computer = ""
$credential = Get-Credential

Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c gpupdate /force /boot" -ComputerName $computer -Credential $credential
				
