# Domain
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
Write-Host "Domain: $domain"

# AD Site
$adSite = Get-WMIObject Win32_NTDomain | Select -ExpandProperty ClientSiteName
Write-Host "AD Site: $adSite"

# Hostname
$hostname = (Get-WmiObject Win32_ComputerSystem).Name
Write-Host "Hostname: $hostname"

# Get Site Code
$sms = new-object -comobject 'Microsoft.SMS.Client'
$siteCode = $sms.GetAssignedSite()
Write-Host "Site Code: $siteCode"

$configMgrGUID = Get-CimInstance -Namespace root\ccm -ClassName CCM_Client | Select-Object -ExpandProperty ClientId
Write-Host "$configMgrGUID"

# Client Version
try {
            if ($PowerShellVersion -ge 6) { $clientVersion = (Get-CimInstance -Namespace root/ccm SMS_Client).ClientVersion }
            else { $clientVersion = (Get-WmiObject -Namespace root/ccm SMS_Client).ClientVersion }
    }catch { $obj = $false }
Write-Host "Client Version: $clientVersion"

# Client Cache in ConfigMgr Client
$clientCacheSize = (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize
Write-Host "Client Cache Size: $clientCacheSize"

# Client Max Log Size
$logMaxSize = [Math]::Round(((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxSize) / 1000)
Write-Host "Client Max Log Size: $logMaxSize"

# Client Max Log History
$logMaxHistory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxHistory
Write-Host "Client Max Log History: $logMaxHistory"

# Log Directory
$logDirectory =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
Write-Host "Log Directory: $logDirectory"

# CCM Directory
$logdir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
$ccmDirectory = $logdir.replace("\Logs", "")
Write-Host "ConfigMgr Client Directory: $ccmDirectory"

# last update informations
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()
$lastUpdate = $Searcher.QueryHistory(0, $HistoryCount) | select Date, Title  | Where-Object {$_.Title -like "*Cumulative*"} | sort Date -Descending | select -First 2

Write-Host "The latest 2 updates on the PC installed:"
$counter = 0
foreach($update in $lastUpdate){
    $date = $lastUpdate[$counter].Date.ToString("yyyy-MM-dd HH:mm:ss")
    $title = $lastUpdate[$counter].Title
    Write-Host "$date - $title"
    $counter = $counter + 1
}

# checking the count of the SDF files (local database files) in the directory 
$files = @(Get-ChildItem "$ccmDirectory\*.sdf" -ErrorAction SilentlyContinue)
if ($files.Count -lt 7) { Write-Host "ConfigMgr Client database is corrupt (SDF local database files). ConfigMgr Client reinstallation is needed." -ForegroundColor Red }
else { Write-Host "SDF files test: OK" -ForegroundColor Green }

# checking ccmsqlce log file
$logFile = "$logdir\CcmSQLCE.log"
$logLevel = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').logLevel
if ( (Test-Path -Path $logFile) -and ($logLevel -ne 0) ) {
            $LastWriteTime = (Get-ChildItem $logFile).LastWriteTime
            $CreationTime = (Get-ChildItem $logFile).CreationTime
            $FileDate = Get-Date($LastWriteTime)
            $FileCreated = Get-Date($CreationTime)

            $now = Get-Date
            if ( (($now - $FileDate).Days -lt 7) -and ((($now - $FileCreated).Days) -gt 7) ) {
                Write-Host "CM client not in debug mode and CcmSQLCE.log exists. Reinstalling ConfigMgr Client is needed" -ForegroundColor Red              
                }
            else { Write-Host "CcmSQLCE.log has not been updated for two days" -ForegroundColor Yellow }
        }
else { Write-Host "CcmSQLCE.log check passed" -ForegroundColor Green }

# checking certificate
$logFile1 = "$logdir\ClientIDManagerStartup.log"
$error1 = 'Failed to find the certificate in the store'
$error2 = '[RegTask] - Server rejected registration 3'
$content = Get-Content -Path $logFile1
$ok = $true

if ($content -match $error1) {
     Write-Host 'ConfigMgr Client Certificate: Error failed to find the certificate in store.' -ForegroundColor Red
     $ok = $false}

if ($content -match $error2) {
     Write-Host 'ConfigMgr Client Certificate: Error! Server rejected client registration. Client Certificate not valid.' -ForegroundColor Red
     $ok = $false}

 if ($ok -eq $true) {Write-Host 'ConfigMgr Client Certificate: OK' -ForegroundColor Green}

 # BITS check
$Errors = Get-BitsTransfer -AllUsers | Where-Object { ($_.JobState -like "TransientError") -or ($_.JobState -like "Transient_Error") -or ($_.JobState -like "Error") }
if ($Errors) {Write-Host "Errors in the BITS transfers" -ForegroundColor Red}
else {Write-Host "BITS transfer: OK" -ForegroundColor Green}

# Checking Client Settings
$ClientSettingsConfig = @(Get-WmiObject -Namespace "root\ccm\Policy\DefaultMachine\RequestedConfig" -Class CCM_ClientAgentConfig -ErrorAction SilentlyContinue | Where-Object {$_.PolicySource -eq "CcmTaskSequence"})
if ($ClientSettingsConfig.Count -gt 0) {Write-Host "Error in the Client Settings Configuration" -ForegroundColor Red}
else {Write-host "Client Settings Configuration: OK" -ForegroundColor Green}

# Checking Pending Reboot
$pendingReboot = $false
$key = Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
if ($null -ne $key) { Write-Host "Pending reboot reason: CBS" -ForegroundColor Red
                      $pendingReboot = $true}
$key = Get-Item 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
if ($null -ne $key) { Write-Host "Pending reboot reason: Windows Update" -ForegroundColor Red
                      $pendingReboot = $true}
$util = [wmiclass]'\\.\root\ccm\clientsdk:CCM_ClientUtilities'
$status = $util.DetermineIfRebootPending()
if(($null -ne $status) -and $status.RebootPending){ Write-Host "Pending reboot reason: Configuration Manager" -ForegroundColor Red
                                                    $pendingReboot = $true}
 if ($pendingReboot -eq $false) {Write-Host 'Pending reboot: OK' -ForegroundColor Green}

 # check Provisioning Mode
 $registryPath = 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec'
 $provisioningMode = (Get-ItemProperty -Path $registryPath).ProvisioningMode
 if ($provisioningMode -eq 'true') { Write-Host "The ConfigMgr is in the provisioning mode" -ForegroundColor Red }
 else { Write-Host "Provisioning mode: OK" -ForegroundColor Green }

 # Free space
$driveC = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | Select-Object FreeSpace, Size
$freeSpace = $driveC.FreeSpace / 1024 / 1024 /1024
$freeSpaceRounded = ([math]::Round($freeSpace,2))
if ($freeSpaceRounded -lt 10 -and $freeSpaceRounded -gt 5) {Write-Host "Free space on the disk: $freeSpaceRounded" -ForegroundColor Yellow}
if ($freeSpaceRounded -lt 5) {Write-Host "Free space on the disk: $freeSpaceRounded" -ForegroundColor Red}
if ($freeSpaceRounded -gt 10) {Write-Host "Free space on the disk: $freeSpaceRounded" -ForegroundColor Green}

# Last Boot Time
$wmi = Get-WmiObject Win32_OperatingSystem 
$obj = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
$days = (New-TimeSpan -Start $obj -End (Get-Date)).Days
if ($days -gt 7 -and $days -lt 14) {Write-Host "No restart since $days. Last restart: $obj" -ForegroundColor Yellow}
if($days -gt 14){Write-Host "No restart since $days. Last restart: $obj" -ForegroundColor Red}
if ($days -lt 7) {Write-Host "Restarted in the last 7 days (running since $days day): OK " -ForegroundColor Green}

# DNS check
$fqdn = [System.Net.Dns]::GetHostEntry([string]"localhost").HostName
$localIPs = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -Match "True"} |  Select-Object -ExpandProperty IPAddress
$dnscheck = [System.Net.DNS]::GetHostByName($fqdn)
try {
                $ActiveAdapters = (get-netadapter | Where-Object {$_.Status -like "Up"}).Name
                $dnsServers = Get-DnsClientServerAddress | Where-Object {$ActiveAdapters -contains $_.InterfaceAlias} | Where-Object {$_.AddressFamily -eq 2} | Select-Object -ExpandProperty ServerAddresses
                $dnsAddressList = Resolve-DnsName -Name $fqdn -Server ($dnsServers | Select-Object -First 1) -Type A -DnsOnly | Select-Object -ExpandProperty IPAddress
            }
catch {
                $dnsAddressList = $dnscheck.AddressList | Select-Object -ExpandProperty IPAddressToString
                $dnsAddressList = $dnsAddressList -replace("%(.*)", "")
            }
       
if ($dnscheck.HostName -like $fqdn) {
            foreach ($dnsIP in $dnsAddressList) {
                #Write-Host "Testing if IP address: $dnsIP published in DNS exist in local IP configuration."
                ##if ($dnsIP -notin $localIPs) { ## Requires PowerShell 3. Works fine :(
                if ($localIPs -notcontains $dnsIP) {
                   Write-Host "IP '$dnsIP' in DNS record do not exist locally" -ForegroundColor Red
                } else {Write-Host "DNS check: OK" -ForegroundColor Green}
            }
}

# checking %USERPROFILE%\AppData\Roaming value
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
$correctValue = '%USERPROFILE%\AppData\Roaming'
$currentValue = (Get-Item 'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\').GetValue('AppData', $null, 'DoNotExpandEnvironmentNames')
if ($currentValue -ne $correctValue) { Write-Host 'The User Shell Folders - AppData registry value is not correct' -ForegroundColor Red}
else{Write-Host 'User Shell Folders check: OK' -ForegroundColor Green}

# SMS Agent Host service
if (Get-Service -Name ccmexec -ErrorAction SilentlyContinue) {
      Write-Host "Configuration Manager Client installation: OK" -ForegroundColor Green

            # Reinstall if we are unable to start the CM client
      if ($CCMService.Status -eq "Stopped") {
              Write-Host "The SMS Agent Host service is not running" -ForegroundColor Red
                  if ($CCMService.StartType -ne "Automatic") {
                       Write-Host "The StartupType of SMS Agent Host is not Automatic" -ForegroundColor Red
                    }
                }
       else{Write-Host "SMS Agent Host service: OK" -ForegroundColor Green }
   }
else{Write-Host "The ConfigMgr is not installed properly. It has to be reinstalled" -ForegroundColor Red}

# connect to SMS_Client WMI class
 Try {$WMI = Get-WmiObject -Namespace root/ccm -Class SMS_Client -ErrorAction Stop 
      Write-Host "WMI connection to root/ccm namespace: OK" -ForegroundColor Green
      } 
 Catch {Write-Host "Failed to connect to WMI namespace root/ccm class SMS_Client. Clearing WMI and reinstalling ConfigMgr is needed" -ForegroundColor Red}
 # Clearing WMI
 #Get-WmiObject -Query "Select * from __Namespace WHERE Name='CCM'" -Namespace root | Remove-WmiObject

# other WMI check
$result = winmgmt /verifyrepository
switch -wildcard ($result) {
            "*inconsistent*" { Write-Host "The WMI repository is inconsistent" -ForegroundColor Red } 
            "*not consistent*"  { Write-Host "The WMI repository is inconsistent" -ForegroundColor Red }
            "*WMI repository is consistent*"  { Write-Host "WMI repository consistent: OK" -ForegroundColor Green }
}

Try {$WMI = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop} 
Catch {Write-Host "Failed to connect to WMI class Win32_ComputerSystem. WMI corrupted" -ForegroundColor Red}


# triggering the update actions - updatestore.log
Try {$SCCMUpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore -ErrorAction Stop
     $SCCMUpdatesStore.RefreshServerComplianceState()
     Write-Host "Triggering the Windows Update cycles: OK" -ForegroundColor Green
      } 
Catch {Write-Host "The Windows Update cycles couldn't be triggered" -ForegroundColor Red}
 
# checking the communication to the MP
$logfile = "$logdir\StateMessage.log"
$StateMessage = Get-Content($logfile)
if ($StateMessage -match 'Successfully forwarded State Messages to the MP') {
            Write-Host "Forwarding messages to the MP: OK" -ForegroundColor Green
        }
else {Write-Host "Based on the StateMessage.log there could be an issue with the communication to the MP" -ForegroundColor Red }

$MP = Get-WmiObject -Namespace root\ccm -Class SMS_Authority | select -ExpandProperty CurrentManagementPoint

# DNS test to the MP
try {
    $dns = Resolve-DnsName $MP -ErrorAction Stop
    Write-Host "DNS lookup to the Manamenet Poin ($MP): OK" -ForegroundColor Green
}
catch {
    Write-Host "DNS lookup FAILED to MP ($MP)" -ForegroundColor Red}

# Port test to the MP
try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($MP,80)
        $tcp.Close()
        Write-Host "Port 80 test to the Management Point: OK" -ForegroundColor Green
    }
catch {
        Write-Host "Port 80 FAILED to the Management Point" -ForegroundColor Red
    }

# MP cert endpoint
$url1 = "http://$MP/SMS_MP/.sms_aut?mpcert"
try {
    $r = Invoke-WebRequest -Uri $url1 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Write-Host "Request to the MPCERT endpoint: OK" -ForegroundColor Green
    }
}
catch {
    Write-Host "Request to the MPCERT endpoint FAILED" -ForegroundColor Red
}

# MP list endpoint
$url2 = "http://$MP/SMS_MP/.sms_aut?mplist"
try {
    $r = Invoke-WebRequest -Uri $url2 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Write-Host "Request to the MPLIST endpoint: OK" -ForegroundColor Green
    }
}
catch {
    Write-Host "equest to the MPLIST endpoint FAILED" -ForegroundColor Red
}




# checking WuaHandler.log
$logfile = "$logdir\WUAHandler.log"
$logFileContent = Get-Content($logfile)
if ($logFileContent -match '0x80004005' -or $logFileContent -match '0x87d00692') {
            Write-Host "0x87d00692 or 0x80004005 error in the WUAHandler.log. Reinstallation of the ConfigMgr is needed" -ForegroundColor Red
        }
            Write-Verbose "Check machine registry file to see if it's older than $($Days) days."

# checking registry.pol file
$MachineRegistryFile = "$($env:WinDir)\System32\GroupPolicy\Machine\registry.pol"
$file = Get-ChildItem -Path $MachineRegistryFile -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LastWriteTime
$regPolDate = Get-Date($file)
$now = Get-Date
if (($now - $regPolDate).Days -ge 0) {Write-Host "Machine registry.pol file is older than 1 day" -ForegroundColor Red}
else{Write-Host "Machine registry.pol file age: OK" -ForegroundColor Green}          

# orphaned cache folders
$CCMCache = (New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().Location
if ($null -eq $CCMCache) { $CCMCache = "$env:SystemDrive\Windows\ccmcache" }
$ValidCachedFolders = (New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().GetCacheElements() | ForEach-Object {$_.Location}
$AllCachedFolders = (Get-ChildItem -Path $CCMCache) | Select-Object Fullname -ExpandProperty Fullname

ForEach ($CachedFolder in $AllCachedFolders) {
                If ($ValidCachedFolders -notcontains $CachedFolder) {
                    if ((Get-ItemProperty $CachedFolder).LastWriteTime -le (get-date).AddDays(-30)) {
                        Write-Host "Orphaned folder in ccmcache: $CachedFolder" -ForegroundColor Red
                    }
                }
            }

# checking services
$services = @("BITS", "winmgmt", "wuauserv", "lanmanserver", "RpcSs", "W32Time", "ccmexec")
foreach ($service in $services) {

    $obj = Get-Service -Name $service
    $serviceName = $obj.DisplayName

    if ($obj.Status -ne "Running") {

        Write-Host "$serviceName service is not running" -ForegroundColor Red
        
        Start-Service $service
        
        (Get-Service $service).WaitForStatus('Running','00:00:30')

        Write-Host "$serviceName started" -ForegroundColor Green
    }
    else{Write-Host "$serviceName service is running" -ForegroundColor Green}
}

# checking admin share and C: share
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'ADMIN$'}
if ($share.Name -contains 'ADMIN$') {Write-Host "Share for C:\Windows: OK" -ForegroundColor Green}
else { Write-Host "Issue with the share C:\Windows" -ForegroundColor Red}
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'C$'}
if ($share.Name -contains "C$") {Write-Host "Share for C root: OK" -ForegroundColor Green}
else { Write-Host "Issue with the share C:\" -ForegroundColor Red }

# start client health evaluation task
$RegistryKey = "HKLM:\Software\ConfigMgrClientHealth"
$registryValueName = "RefreshServerComplianceState"
try{[datetime]$LastRun = Get-RegistryValue -Path $RegistryKey -Name $registryValueName}
    catch{$LastRun=[datetime]::MinValue}
    Write-Host "Client Health Evaluation RefreshServerComplianceState date: $($LastRun)"
Try {
     Start-ScheduledTask -TaskName "Configuration Manager Health Evaluation" -TaskPath "\Microsoft\Configuration Manager\" -ErrorAction Stop
     Write-Host "Client Health Evaluation Triggered: OK" -ForegroundColor Green
      } 
Catch {Write-Host "The Client Health Evaluation couldn't be triggered" -ForegroundColor Red}

# checking hardware inventory scan
$wmi = Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus | Where-Object {$_.InventoryActionID -eq '{00000000-0000-0000-0000-000000000001}'} | Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}} 
$HWScanDate = $wmi | Select-Object -ExpandProperty HWSCAN
$minDate = (Get-Date).AddHours(-6)
if ($HWScanDate -gt $minDate) {        
                Write-Host "Hardware Inventory scan within 6 hours ($HWScanDate): OK" -ForegroundColor Green
            }
else {Write-Host "There was no Hardware Inventory sync in the last 6 hours" -ForegroundColor Yellow
      Try {
        Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" -ErrorAction Stop| Out-Null
        Write-Host "Hardware Inventory cycle has been triggered" -ForegroundColor Green
      } 
      Catch {Write-Host "Hardware Inventory cycle couldn't be triggered" -ForegroundColor Red}
}

# check if Domain Admins in the local admins group
$group = "Domain Admins"
$admins = Get-LocalGroupMember -Group "Administrators" | select -ExpandProperty Name
if ($admins -match "Domain Admins") {
     Write-Host 'Domain Admins in the local admins group: OK' -ForegroundColor Green
     }
else{Write-Host 'Domain Admins is not member of the local admins group' -ForegroundColor Red}

$input = Read-Host "Do you want to execute extended Windows Update troubleshooting? (yes or no)"
if($input -eq "yes" -or $input -eq "y"){

Write-Host "1. Stopping Windows Update Services..." 
Stop-Service -Name BITS 
Stop-Service -Name wuauserv 
Stop-Service -Name appidsvc 
Stop-Service -Name cryptsvc 
 
Write-Host "2. Remove QMGR Data file..." 
Remove-Item "$env:allusersprofile\Application Data\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue 
 
Write-Host "3. Renaming the Software Distribution and CatRoot Folder..." 
Remove-Item $env:systemroot\SoftwareDistribution -ErrorAction SilentlyContinue -recurse
Remove-Item $env:systemroot\System32\Catroot2 -ErrorAction SilentlyContinue -recurse
Remove-item "C:\ProgramData\application data\Microsoft\Network\Downloader.old" -ErrorAction SilentlyContinue
rename-item "C:\ProgramData\application data\Microsoft\Network\Downloader" downloader.old

Write-Host "4. Removing old Windows Update log..." 
Remove-Item $env:systemroot\WindowsUpdate.log -ErrorAction SilentlyContinue 
 
Write-Host "5. Resetting the Windows Update Services to defualt settings..." 
sc.exe sdset bits "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
sc.exe sdset wuauserv "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" 
 
Set-Location $env:systemroot\system32 
 
Write-Host "6. Registering some DLLs..." 
regsvr32.exe /s atl.dll 
regsvr32.exe /s urlmon.dll 
regsvr32.exe /s mshtml.dll 
regsvr32.exe /s shdocvw.dll 
regsvr32.exe /s browseui.dll 
regsvr32.exe /s jscript.dll 
regsvr32.exe /s vbscript.dll 
regsvr32.exe /s scrrun.dll 
regsvr32.exe /s msxml.dll 
regsvr32.exe /s msxml3.dll 
regsvr32.exe /s msxml6.dll 
regsvr32.exe /s actxprxy.dll 
regsvr32.exe /s softpub.dll 
regsvr32.exe /s wintrust.dll 
regsvr32.exe /s dssenh.dll 
regsvr32.exe /s rsaenh.dll 
regsvr32.exe /s gpkcsp.dll 
regsvr32.exe /s sccbase.dll 
regsvr32.exe /s slbcsp.dll 
regsvr32.exe /s cryptdlg.dll 
regsvr32.exe /s oleaut32.dll 
regsvr32.exe /s ole32.dll 
regsvr32.exe /s shell32.dll 
regsvr32.exe /s initpki.dll 
regsvr32.exe /s wuapi.dll 
regsvr32.exe /s wuaueng.dll 
regsvr32.exe /s wuaueng1.dll 
regsvr32.exe /s wucltui.dll 
regsvr32.exe /s wups.dll 
regsvr32.exe /s wups2.dll 
regsvr32.exe /s wuweb.dll 
regsvr32.exe /s qmgr.dll 
regsvr32.exe /s qmgrprxy.dll 
regsvr32.exe /s wucltux.dll 
regsvr32.exe /s muweb.dll 
regsvr32.exe /s wuwebv.dll 
 

Write-Host "7) Resetting the WinSock..." 
netsh winsock reset 
netsh winhttp reset proxy 
 
Write-Host "8) Delete all BITS jobs..." 
import-module bitstransfer
Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like 'TransientError' } | Remove-BitsTransfer
Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value '*' -force
Get-BitsTransfer -AllUsers | Where-Object { $_.JobState -like 'SUSPENDED' } | Resume-BitsTransfer
Write-Host "9) Reset branchcache..." 
netsh branchcache reset 
netsh branchcache set service mode=DISTRIBUTED
Write-Host "10) Execute gpupdate /force..." 
gpupdate.exe /Force
Write-Host "11) Starting Windows Update Services..." 
Start-Service -Name BITS 
Start-Service -Name wuauserv 
Start-Service -Name appidsvc 
Start-Service -Name cryptsvc 

Write-Host "12) Forcing discovery..." 
wuauclt.exe /ResetAuthorization /DetectNow
wuauclt /reportnow

([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000021}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000108}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000024}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000023}')
(New-Object -ComObject Microsoft.CCM.UpdatesStore).RefreshServerComplianceState()
    
Write-Host "13) Removing Software Update Lock..."
$query = "select * from CCM_PrePostActions"; gwmi -Namespace ROOT\ccm\Policy\Machine\RequestedConfig -Query $query | rwmi; gwmi -Namespace ROOT\ccm\Policy\Machine\ActualConfig -Query $query | rwmi

Write-Host "14) Executing Built-in Windows Update Troubleshooter..."
Get-TroubleshootingPack -Path "C:\Windows\diagnostics\system\WindowsUpdate" | Invoke-TroubleshootingPack -Unattended
Restart-Service 'wuauserv'
	#location refresh
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000012}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000024}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000023}')

	#MP Refreash
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000021}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000022}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000042}')

([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000113}')
([wmiclass]'ROOT\ccm:SMS_Client').TriggerSchedule('{00000000-0000-0000-0000-000000000108}')

}

