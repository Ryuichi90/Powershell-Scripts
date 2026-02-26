$ComputerName = ""
$cred = Get-Credential
Enter-PSSession -ComputerName $ComputerName -Credential $cred
