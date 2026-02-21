$computer = ""
$credential = Get-Credential

Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList "cmd.exe /c net user Administrator /active:yes && net user Administrator Windows2024@ || (net user Administrator Windows2024@ /add && net localgroup Administrators Administrator /add) && net user Administrator /active:yes && net user Administrator Windows2024@" -ComputerName $computer -Credential $credential
