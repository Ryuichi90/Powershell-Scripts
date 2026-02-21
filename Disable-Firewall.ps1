$computer = ""
$credential = Get-Credential

Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c netsh advfirewall set allprofiles state off" -ComputerName $computer -Credential $credential
