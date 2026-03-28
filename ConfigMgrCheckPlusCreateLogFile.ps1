$hostname = (Get-WmiObject Win32_ComputerSystem).Name
$logFile = "C:\temp\" + "$hostname" + "_ConfigMgrEvalCheck.txt"

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "OK", "ERROR", "WARNING")]
        [string]$Level = "INFO",

        [Parameter(Mandatory=$true)]
        [string]$LogFile
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $logEntry = "[{0}] [{1}] {2}" -f $Level, $timestamp, $Message

    Add-Content -Path $logFile -Value $logEntry
}


Add-Content -Path $logFile -Value "############# Basic Informations #############`n"

# Domain
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
Write-Log -Message "Domain: $domain" -Level "INFO" -LogFile $logFile

# AD Site
$adSite = Get-WMIObject Win32_NTDomain | Select -ExpandProperty ClientSiteName
Write-Log -Message "AD Site: $adSite" -Level "INFO" -LogFile $logFile

# Hostname
Write-Log -Message "Hostname: $hostname" -Level "INFO" -LogFile $logFile

# Get Site Code
$sms = new-object -comobject 'Microsoft.SMS.Client'
$siteCode = $sms.GetAssignedSite()
Write-Log -Message "Site Code: $siteCode" -Level "INFO" -LogFile $logFile

# CCM Client
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class "CCM_Client" | select *
$clientID = $ccmClient.ClientID
$previousGUID = $ccmClient.PreviousClientId
$GUIDChangeDate = $ccmClient.ClientIdChangeDate

Write-Log -Message "ClientID: $clientID" -Level "INFO" -LogFile $logFile
Write-Log -Message "Previous clientID: $previousGUID" -Level "INFO" -LogFile $logFile
Write-Log -Message "Last clientID change date: $GUIDChangeDate" -Level "INFO" -LogFile $logFile

# Client Version
try {
            if ($PowerShellVersion -ge 6) { $clientVersion = (Get-CimInstance -Namespace root/ccm SMS_Client).ClientVersion }
            else { $clientVersion = (Get-WmiObject -Namespace root/ccm SMS_Client).ClientVersion }
    }catch { $obj = $false }

Write-Log -Message "Client Version: $clientVersion" -Level "INFO" -LogFile $logFile

# Client Cache in ConfigMgr Client
$clientCacheSize = (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize / 1024
Write-Log -Message "Client Cache Size: $clientCacheSize GB" -Level "INFO" -LogFile $logFile

# Folder count in ccmcache and size of the ccmcache
$path = "C:\Windows\ccmcache"
if (Test-Path $path) {
    $size = (Get-ChildItem -Path $path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $sizeGB = [math]::Round($size / 1GB, 2)
    Write-Log -Message "CCMCache current size: $sizeGB GB" -Level "INFO" -LogFile $logFile
    
    $folders = Get-ChildItem -Path $path -Directory
    $count = $folders.Count
    Write-Log -Message "Folder count in ccmcache: $count" -Level "INFO" -LogFile $logFile

} else {
    Write-Log -Message "The CCMCache folder doesn't exist" -Level "ERROR" -LogFile $logFile
}

# Client Max Log Size
$logMaxSize = [Math]::Round(((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxSize) / 1000)
Write-Log -Message "Client Max Log Size: $logMaxSize" -Level "INFO" -LogFile $logFile

# Client Max Log History
$logMaxHistory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxHistory
Write-Log -Message "Client Max Log History: $logMaxHistory" -Level "INFO" -LogFile $logFile

# Log Directory
$logDirectory =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
Write-Log -Message "Log Directory: $logDirectory" -Level "INFO" -LogFile $logFile

# CCM Directory
$ccmDirectory = $logDirectory.replace("\Logs", "")
Write-Log -Message "ConfigMgr Client Directory: $ccmDirectory" -Level "INFO" -LogFile $logFile


# Last Update Informations
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()
$lastUpdate = $Searcher.QueryHistory(0, $HistoryCount) | select Date, Title  | Where-Object {$_.Title -like "*Cumulative*"} | sort Date -Descending | select -First 2

Write-Log -Message "The latest 2 updates on the PC installed:" -Level "INFO" -LogFile $logFile

$counter = 0
foreach($update in $lastUpdate){
    $date = $lastUpdate[$counter].Date.ToString("yyyy-MM-dd HH:mm:ss")
    $title = $lastUpdate[$counter].Title
    Add-Content -Path $logFile -Value "$date - $title"
    $counter = $counter + 1
}

# Update errors in the event log
$updateInstallErrors = Get-WinEvent -LogName System -FilterXPath "*[System[(EventID=20 or EventID=25 or EventID=31)]]" | where {$_.LevelDisplayName -eq "Error"} | select TimeCreated,Message

if($updateInstallErrors){
    Write-Log -Message "Update errors found in the event log:" -Level "ERROR" -LogFile $logFile
    foreach($updateInstallError in $updateInstallErrors){
    $time = $updateInstallError.TimeCreated
    $message = $updateInstallError.Message
    Add-Content -Path $logFile -Value "$time : $message"

    }
}else{Write-Log -Message "No update errors in the event log" -Level "INFO" -LogFile $logFile}

# Missing Updates
$missingUpdates = get-wmiobject -query "SELECT * FROM CCM_UpdateStatus" -namespace "root\ccm\SoftwareUpdates\UpdatesStore" | where {$_.title -like "*Cumulative*" -and $_.status -eq "Missing"} | select title

if($missingUpdates){
    Write-Log -Message "Missing Updates:" -Level "INFO" -LogFile $logFile
    foreach($missingUpdate in $missingUpdates){
        $missingUpdateTitle = $missingUpdate.title
        Add-Content -Path $logFile -Value $missingUpdateTitle
    }
}else{Write-Log -Message "The client can not recognize any missing update" -Level "WARNING" -LogFile $logFile}


# Start Client Health Evaluation Task
try{[datetime]$LastRun = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\CCM\CcmEval").LastEvalTime}
    catch{$LastRun=[datetime]::MinValue}
    Write-Log -Message "Last Client Health Evaluation Time: $($LastRun)" -Level "INFO" -LogFile $logFile


Add-Content -Path $logFile -Value "`n`n############# Searching for issues #############`n"


# Maintanance Windows
$serviceWindow = Get-WmiObject -Namespace "root\ccm\clientsdk" -Class CCM_ServiceWindow | Select-Object Name,StartTime,Duration
if ($serviceWindow) {
    Write-Log -Message "Maintanance Window Check" -Level "OK" -LogFile $logFile
} else {
    Write-Log -Message "No Maintenance Windows configured"  -Level "WARNING" -LogFile $logFile
}

# Checking if the metered connection is enabled
[void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
$cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost()
$isMeteredConnectionEnabled = $cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted -or ($cost.NetworkCostType -ne "Unrestricted")

if($isMeteredConnectionEnabled -eq $false){Write-Log -Message "Metered Connection Check" -Level "OK" -LogFile $logFile}
else{Write-Log -Message "Metered Connection Check: it is turned on and has to be turned off!"  -Level "ERROR" -LogFile $logFile}

# WSUS server
$wuServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate').WUServer
$wsusWithoutPort = $wuServer -replace '^https?://','' -replace ':\d+$',''
$port = ($wuServer -split ':')[-1]
$wuStatusServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate').WUStatusServer
$useWUServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU').UseWUServer

if($useWUServer -ne 1){Write-Log -Message "UseWUServer check: the registry value is not 1"  -Level "ERROR" -LogFile $logFile }
else{Write-Log -Message "UseWUServer Registry Check" -Level "OK" -LogFile $logFile}

#DNS check to the WSUS
try {
    $dns = Resolve-DnsName $wsusWithoutPort -ErrorAction Stop
    Write-Log -Message "WSUS Server Check ($wsusWithoutPort) - DNS Lookup Check" -Level "OK" -LogFile $logFile
}
catch {
    Write-Log -Message "WSUS Server Check ($wsusWithoutPort) - DNS Lookup FAILED"  -Level "ERROR" -LogFile $logFile
}

#Port Check to the WSUS
try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($wsusWithoutPort,$port)
        $tcp.Close()
        Write-Log -Message "WSUS Server Check ($wsusWithoutPort) - Port $port Connection Check" -Level "OK" -LogFile $logFile
    }
catch {
        Write-Log -Message "WSUS Server Check ($wsusWithoutPort) - Port $port Connection FAILED"  -Level "ERROR" -LogFile $logFile
    }


# Checking the Count of the SDF Files (Local ConfigMgr Database Files)
$files = @(Get-ChildItem "$ccmDirectory\*.sdf" -ErrorAction SilentlyContinue)
if ($files.Count -lt 7) {Write-Log -Message "ConfigMgr Client database is corrupt (SDF local database files). ConfigMgr Client reinstallation is needed." -Level "ERROR" -LogFile $logFile}
else {Write-Log -Message "SDF Files Check" -Level "OK" -LogFile $logFile}

# Checking the Actions (13)
$neededTriggers = @{
"{00000000-0000-0000-0000-000000000021}" = "Machine policy retrieval & evaluation cycle"
"{00000000-0000-0000-0000-000000000022}" = "Machine policy evaluation cycle"
"{00000000-0000-0000-0000-000000000001}" = "Hardware inventory cycle"
"{00000000-0000-0000-0000-000000000003}" = "Discovery data collection cycle"
"{00000000-0000-0000-0000-000000000113}" = "Software updates scan cycle"
"{00000000-0000-0000-0000-000000000114}" = "Software updates deployment evaluation cycle"
"{00000000-0000-0000-0000-000000000031}" = "Software metering usage report cycle"
"{00000000-0000-0000-0000-000000000121}" = "Application deployment evaluation cycle"
"{00000000-0000-0000-0000-000000000032}" = "Windows installer source list update cycle"
}

$triggers = Get-WmiObject -Namespace "root\ccm\scheduler" -Class "CCM_Scheduler_History" | select ScheduleID, LastTriggerTime
$SMSClient = Get-WMIObject -Namespace "root\ccm" -Class SMS_Client -list

$result = foreach ($id in $neededTriggers.Keys) {

    $match = $triggers | Where-Object { $_.ScheduleID -eq $id }

    [PSCustomObject]@{
        ScheduleID      = $id
        ActionName      = $neededTriggers[$id]
        Exists          = [bool]$match
        LastTriggerTime = $match.LastTriggerTime
    }

    try{
        $SMSClient.TriggerSchedule($id) | Out-Null
    
    }
    
    catch{
    $actionName = $neededTriggers[$id]
    Write-Log -Message "$actionName couldn't be triggered" -Level "ERROR" -LogFile $logFile

    
    }
}

$actionCount = ($result | Where-Object {$_.Exists }).Count
$missingActions = $result | Where-Object { -not $_.Exists } | select ActionName

if($missingActions){
    foreach($missingAction in $missingActions){
        $actionName = $missingAction.ActionName
        Write-Log -Message "Missing actions in the Scheduler namespace: $actionName" -Level "ERROR" -LogFile $logFile
    }
    Write-Log -Message "ConfigMgr client reinstallation is needed" -Level "ERROR" -LogFile $logFile
} else{Write-Log -Message "Scheduler Namespace / Actions Check" -Level "OK" -LogFile $logFile}

# Count of the Installed Components
$installedComponents = (Get-WmiObject -Namespace "root\ccm" -Class "CCM_InstalledComponent").Count
if($installedComponents -eq 18){Write-Log -Message "Installed ConfigMgr Components Count Check" -Level "OK" -LogFile $logFile}
else{Write-Log -Message "Count of the installed components should be 18 but it's $installedComponents so the ConfigMgr has to be reinstalled" -Level "ERROR" -LogFile $logFile}

# Checking the Software Center Path
$existsSWCenter = Test-Path "C:\Windows\CCM\ClientUX\SCClient.exe"
if($existsSWCenter){Write-Log -Message "Software Center Path Check" -Level "OK" -LogFile $logFile}
else{Write-Log -Message "Softare Center could not find" -Level "ERROR" -LogFile $logFile}

# Checking ccmsqlce Log File
$logFileCcmSQLCE = "$logDirectory\CcmSQLCE.log"
$logLevel = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').logLevel

if ( (Test-Path -Path $logFileCcmSQLCE) -and ($logLevel -ne 0) ) {
            $LastWriteTime = (Get-ChildItem $logFileCcmSQLCE).LastWriteTime
            $CreationTime = (Get-ChildItem $logFileCcmSQLCE).CreationTime
            $FileDate = Get-Date($LastWriteTime)
            $FileCreated = Get-Date($CreationTime)

            $now = Get-Date
            if ( ($now - $FileDate).Days -eq 0) {
                Write-Log -Message "CcmSQLCE.log Update Time Check" -Level "OK" -LogFile $logFile             
                }
            else {Write-Log -Message "CcmSQLCE.log has no update today" -Level "WARNING" -LogFile $logFile 
            }
        }
else { Write-Log -Message "CcmSQLCE.log doesn't exist" -Level "ERROR" -LogFile $logFile}


$CcmSQLCEErrors = Select-String -Path $logFileCcmSQLCE -Pattern "error","fail","corrupt","locked","timeout"
if($CcmSQLCEErrors){
    Write-Log -Message "CcmSQLCE.log contains the following errors:" -Level "ERROR" -LogFile $logFile
    foreach($CcmSQLCEError in $CcmSQLCEErrors) {
        $errorLine = $CcmSQLCEError -replace '.*<!\[LOG\[','' -replace '\]LOG\].*',''
        Add-Content -Path $logFile -Value $errorLine
    }
} else{Write-Log -Message "CcmSQLCE.log Content Check" -Level "OK" -LogFile $logFile}


# Checking Certificate
$certificatesForConfigMgr = Get-ChildItem Cert:\LocalMachine\SMS
if($certificatesForConfigMgr.Count -eq 2){
    Write-Log -Message "Certificate Count Check" -Level "OK" -LogFile $logFile
    foreach($cert in $certificatesForConfigMgr){
        $friendlyName = $cert.FriendlyName
        $notAfterInDays = ($cert.NotAfter - (Get-Date)).Days
    
        if($notAfterInDays -gt 0){
            Write-Log -Message "$friendlyName Expiration Date Check" -Level "OK" -LogFile $logFile
        }else{Write-Log -Message "$friendlyName is expired" -Level "Error" -LogFile $logFile}
    
    }
}else{Write-Log -Message "Missing certificates in the Cert:\LocalMachine\SMS store" -Level "Error" -LogFile $logFile}


$logFileForClientIDManagerStartup = "$logDirectory\ClientIDManagerStartup.log"
$error1 = 'Failed to find the certificate in the store'
$error2 = '[RegTask] - Server rejected registration 3'
$content = Get-Content -Path $logFileForClientIDManagerStartup
$ok = $true

if ($content -match $error1) {
     Write-Log -Message 'ConfigMgr Client Certificate: Error failed to find the certificate in store.' -Level "Error" -LogFile $logFile
     $ok = $false}

if ($content -match $error2) {
     Write-Log -Message 'ConfigMgr Client Certificate: Error! Server rejected client registration. Client Certificate not valid.' -Level "Error" -LogFile $logFile
     $ok = $false}

# BITS Check
$Errors = Get-BitsTransfer -AllUsers | Where-Object { ($_.JobState -like "TransientError") -or ($_.JobState -like "Transient_Error") -or ($_.JobState -like "Error") }
if ($Errors) {Write-Log -Message "Errors in the BITS transfers" -Level "Error" -LogFile $logFile}
else {Write-Log -Message "BITS Transfer Check" -Level "OK" -LogFile $logFile}

# Checking Client Settings
$ClientSettingsConfig = @(Get-WmiObject -Namespace "root\ccm\Policy\DefaultMachine\RequestedConfig" -Class CCM_ClientAgentConfig -ErrorAction SilentlyContinue | Where-Object {$_.PolicySource -eq "CcmTaskSequence"})
if ($ClientSettingsConfig.Count -gt 0) {Write-Log -Message "Error in the Client Settings Configuration" -Level "Error" -LogFile $logFile}
else {Write-Log -Message "Client Settings Configuration Check" -Level "OK" -LogFile $logFile}

# Checking Pending Reboot
$pendingReboot = $false

$key = Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
if ($null -ne $key) {Write-Log -Message "Pending reboot reason: CBS" -Level "WARNING" -LogFile $logFile
                     $pendingReboot = $true}

$key = Get-Item 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
if ($null -ne $key) {Write-Log -Message "Pending reboot reason: Windows Update" -Level "WARNING" -LogFile $logFile
                     $pendingReboot = $true}
$util = [wmiclass]'\\.\root\ccm\clientsdk:CCM_ClientUtilities'
$status = $util.DetermineIfRebootPending()

if(($null -ne $status) -and $status.RebootPending){Write-Log -Message "Pending reboot reason: Configuration Manager" -Level "WARNING" -LogFile $logFile
                                                   $pendingReboot = $true}
if ($pendingReboot -eq $false) {Write-Log -Message "Pending Reboot Check" -Level "OK" -LogFile $logFile}

# Check Provisioning Mode
$registryPath = 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec'
$provisioningMode = (Get-ItemProperty -Path $registryPath).ProvisioningMode
if ($provisioningMode -eq 'true') {Write-Log -Message "The ConfigMgr is in Provisioning Mode" -Level "ERROR" -LogFile $logFile}
else {Write-Log -Message "Provisioning Mode Check" -Level "OK" -LogFile $logFile}

# Free Space
$driveC = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | Select-Object FreeSpace, Size
$freeSpace = $driveC.FreeSpace / 1024 / 1024 /1024
$freeSpaceRounded = ([math]::Round($freeSpace,2))
if ($freeSpaceRounded -lt 10 -and $freeSpaceRounded -gt 5) {Write-Log -Message "Free space on the disk: $freeSpaceRounded" -Level "WARNING" -LogFile $logFile}
if ($freeSpaceRounded -lt 5) {Write-Log -Message "Free space on the disk: $freeSpaceRounded" -Level "ERROR" -LogFile $logFile}
if ($freeSpaceRounded -gt 10) {Write-Log -Message "Free Disk Space Check" -Level "OK" -LogFile $logFile}

# Last Boot Time
$wmi = Get-WmiObject Win32_OperatingSystem 
$obj = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
$days = (New-TimeSpan -Start $obj -End (Get-Date)).Days
if($days -gt 7 -and $days -lt 21) {Write-Log -Message "No restart since $days. Last restart: $obj" -Level "WARNING" -LogFile $logFile}
if($days -gt 21){Write-Log -Message "No restart since $days. Last restart: $obj" -Level "ERROR" -LogFile $logFile}
if($days -lt 7) {Write-Log -Message "Restart Within The Last 7 Days Check" -Level "OK" -LogFile $logFile}

# DNS check
$fqdn = [System.Net.Dns]::GetHostEntry([string]"localhost").HostName
$localIPs = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -Match "True"} |  Select-Object -ExpandProperty IPAddress
$dnscheck = [System.Net.DNS]::GetHostByName($fqdn)

try {$ActiveAdapters = (get-netadapter | Where-Object {$_.Status -like "Up"}).Name
     $dnsServers = Get-DnsClientServerAddress | Where-Object {$ActiveAdapters -contains $_.InterfaceAlias} | Where-Object {$_.AddressFamily -eq 2} | Select-Object -ExpandProperty ServerAddresses
     $dnsAddressList = Resolve-DnsName -Name $fqdn -Server ($dnsServers | Select-Object -First 1) -Type A -DnsOnly | Select-Object -ExpandProperty IPAddress
}
catch {$dnsAddressList = $dnscheck.AddressList | Select-Object -ExpandProperty IPAddressToString
       $dnsAddressList = $dnsAddressList -replace("%(.*)", "")
}
       
if ($dnscheck.HostName -like $fqdn) {
            foreach ($dnsIP in $dnsAddressList) {
                if ($localIPs -notcontains $dnsIP) {
                   Write-Log -Message "IP '$dnsIP' in DNS record do not exist locally" -Level "ERROR" -LogFile $logFile
                } else {Write-Log -Message "Client DNS Check" -Level "OK" -LogFile $logFile}
            }
}

# Checking %USERPROFILE%\AppData\Roaming value
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
$correctValue = '%USERPROFILE%\AppData\Roaming'
$currentValue = (Get-Item 'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\').GetValue('AppData', $null, 'DoNotExpandEnvironmentNames')
if ($currentValue -ne $correctValue) {Write-Log -Message "The User Shell Folders - AppData registry value is not correct" -Level "ERROR" -LogFile $logFile}
else{Write-Log -Message "User Shell Folders Check" -Level "OK" -LogFile $logFile}

# SMS Agent Host service
$CCMService = Get-Service -Name ccmexec -ErrorAction SilentlyContinue
if ($CCMService) {
      Write-Log -Message "SMS Agent Host Service Present Check" -Level "OK" -LogFile $logFile
      
      if ($CCMService.Status -eq "Stopped") {
              Write-Log -Message "The SMS Agent Host service is not running" -Level "ERROR" -LogFile $logFile
                  if ($CCMService.StartType -ne "Automatic") {
                       Write-Log -Message "The StartupType of SMS Agent Host service is not Automatic" -Level "ERROR" -LogFile $logFile
                       }
                }
       else{Write-Log -Message "SMS Agent Host Service Status Check" -Level "OK" -LogFile $logFile}
   }
 else{Write-Log -Message "The SMS Agent Host service not present on the machine. ConfigMgr has to be reinstalled" -Level "ERROR" -LogFile $logFile}


# Connect to SMS_Client WMI Class
Try {$WMI = Get-WmiObject -Namespace root/ccm -Class SMS_Client -ErrorAction Stop 
      Write-Log -Message "WMI Connection Check to CCM Namespace" -Level "OK" -LogFile $logFile} 
Catch {Write-Log -Message "Failed to connect to WMI namespace root/ccm class SMS_Client. Clearing WMI and reinstalling ConfigMgr is needed" -Level "ERROR" -LogFile $logFile}

# Other WMI Check
$result = winmgmt /verifyrepository
switch -wildcard ($result) {
            "*inconsistent*" {Write-Log -Message "The WMI repository is inconsistent" -Level "ERROR" -LogFile $logFile} 
            "*not consistent*"  {Write-Log -Message "The WMI repository is inconsistent" -Level "ERROR" -LogFile $logFile}
            "*WMI repository is consistent*"  {Write-Log -Message "WMI Repository Consistency Check" -Level "OK" -LogFile $logFile}
}
Try {$WMI = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop} 
Catch {Write-Log -Message "Failed to connect to WMI class Win32_ComputerSystem. WMI is corrupt" -Level "ERROR" -LogFile $logFile}

# Triggering the Update Actions - updatestore.log
Try {$SCCMUpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore -ErrorAction Stop
     $SCCMUpdatesStore.RefreshServerComplianceState()
     Write-Log -Message "Refresh Update Store Compliance Check" -Level "OK" -LogFile $logFile} 
Catch {Write-Log -Message "The Update Store Compliance couldn't be refreshed" -Level "ERROR" -LogFile $logFile}
 
# Checking the Communication to the MP in the Log file
$logfileStateMessage = "$logDirectory\StateMessage.log"
$StateMessage = Get-Content($logfileStateMessage)
if ($StateMessage -match 'Successfully forwarded State Messages to the MP') {Write-Log -Message "Forwarding Messages to the MP Based on StateMessage.log Check" -Level "OK" -LogFile $logFile}
else {Write-Log -Message "Based on the StateMessage.log there could be an issue with the communication to the MP" -Level "WARNING" -LogFile $logFile}

# DNS Check to the MP
$MP = Get-WmiObject -Namespace root\ccm -Class SMS_Authority | select -ExpandProperty CurrentManagementPoint
try {
    $dns = Resolve-DnsName $MP -ErrorAction Stop
    Write-Log -Message "DNS Lookup to the MP ($MP) Check" -Level "OK" -LogFile $logFile
}
catch {Write-Log -Message "DNS lookup FAILED to MP ($MP)" -Level "ERROR" -LogFile $logFile}

# Port Check to the MP
try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($MP,80)
        $tcp.Close()
        Write-Log -Message "Port 80 to MP ($MP) Connection Check" -Level "OK" -LogFile $logFile}
catch {Write-Log -Message "Connect to port 80 FAILED to the Management Point ($MP)" -Level "ERROR" -LogFile $logFile}

# MP Cert Endpoint
$url1 = "http://$MP/SMS_MP/.sms_aut?mpcert"
try {
    $r = Invoke-WebRequest -Uri $url1 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Write-Log -Message "Request MPCERT Check" -Level "OK" -LogFile $logFile}
}
catch {Write-Log -Message "Request MPCERT Failed" -Level "ERROR" -LogFile $logFile}

# MP List Endpoint
$url2 = "http://$MP/SMS_MP/.sms_aut?mplist"
try {
    $r = Invoke-WebRequest -Uri $url2 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Write-Log -Message "Request MPLIST Check" -Level "OK" -LogFile $logFile
    }
}
catch {Write-Log -Message "Request MPCERT failed" -Level "ERROR" -LogFile $logFile}

# Checking registry.pol File
$MachineRegistryFile = "$($env:WinDir)\System32\GroupPolicy\Machine\registry.pol"
$file = Get-ChildItem -Path $MachineRegistryFile -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LastWriteTime
$regPolDate = Get-Date($file)
$now = Get-Date
if (($now - $regPolDate).Days -ne 0) {Write-Log -Message "Machine registry.pol file is older than 1 day. Gpupdate should be executed." -Level "WARNING" -LogFile $logFile}
else{Write-Log -Message "Machine registry.pol File Age Check" -Level "OK" -LogFile $logFile}          

# Orphaned Cache Folders
$CCMCache = (New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().Location
if ($null -eq $CCMCache) { $CCMCache = "$env:SystemDrive\Windows\ccmcache" }
$ValidCachedFolders = (New-Object -ComObject "UIResource.UIResourceMgr").GetCacheInfo().GetCacheElements() | ForEach-Object {$_.Location}
$AllCachedFolders = (Get-ChildItem -Path $CCMCache) | Select-Object Fullname -ExpandProperty Fullname

$counterForOrphFolders = 0
ForEach ($CachedFolder in $AllCachedFolders) {
                If ($ValidCachedFolders -notcontains $CachedFolder) {
                    if ((Get-ItemProperty $CachedFolder).LastWriteTime -le (get-date).AddDays(-30)) {
                       $counterForOrphFolders = $counterForOrphFolders + 1
                    }
                }
            }
If ($counterForOrphFolders -eq 0) {Write-Log -Message "Orphan Folder Check ($counterForOrphFolders folder(s))" -Level "OK" -LogFile $logFile} 
else {Write-Log -Message "Number of the orphaned folders in ccmcache: $counterForOrphFolders" -Level "WARNING" -LogFile $logFile}

# Checking Services
$services = @("BITS", "winmgmt", "wuauserv", "lanmanserver", "RpcSs", "W32Time", "ccmexec")
foreach ($service in $services) {

    $obj = Get-Service -Name $service
    $serviceName = $obj.DisplayName

    if ($obj.Status -ne "Running") {
        Write-Log -Message "$serviceName service is not running" -Level "ERROR" -LogFile $logFile
     }
    else{Write-Log -Message "Service $serviceName State Check" -Level "OK" -LogFile $logFile}
}

# Checking Admin Share and C: Share
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'ADMIN$'}
if ($share.Name -contains 'ADMIN$') {Write-Log -Message "Share for C:\Windows Check" -Level "OK" -LogFile $logFile}
else {Write-Log -Message "Issue with the C:\Windows root share" -Level "ERROR" -LogFile $logFile}
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'C$'}
if ($share.Name -contains "C$") {Write-Log -Message "Share for C:\ Root Check" -Level "OK" -LogFile $logFile}
else {Write-Log -Message "Issue with the C:\ root share" -Level "ERROR" -LogFile $logFile}

# Check CcmEval.log file
if (Select-String -Path "C:\Windows\CCM\Logs\CcmEval.log" -Pattern "failed" -Quiet) { 
    Write-Log -Message "The Client Health maybe UNHEALTHY. The following errors are in the CcmEval.log:" -Level "WARNING" -LogFile $logFile
        $errorsInCcmEval = Select-String -Path "C:\Windows\CCM\Logs\CcmEval.log" -Pattern "failed"
        foreach($errorInCcmEval in $errorsInCcmEval) {
            if(($errorInCcmEval -replace '.*<!\[LOG\[','' -replace '\]LOG\].*','') -ne "Failed to get SOFTWARE\Policies\Microsoft\Microsoft Antimalware\Real-Time Protection\DisableIntrusionPreventionSystem"){
                $logLine = ($errorInCcmEval -replace '.*<!\[LOG\[','' -replace '\]LOG\].*','')
                Add-Content -Path $logFile -Value $logLine
            }
            
        }
    } 
else {Write-Log -Message "Client Health Check Based On CcmEval.log" -Level "OK" -LogFile $logFile}

# Checking Hardware Inventory Scan
$wmi = Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus | Where-Object {$_.InventoryActionID -eq '{00000000-0000-0000-0000-000000000001}'} | Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}} 
$HWScanDate = $wmi | Select-Object -ExpandProperty HWSCAN
$minDate = (Get-Date).AddHours(-6)
if ($HWScanDate -gt $minDate) {Write-Log -Message "Hardware Inventory Scan Check (last 6 hours)" -Level "OK" -LogFile $logFile}
else {Write-Log -Message "There was no Hardware Inventory sync in the last 6 hours" -Level "WARNING" -LogFile $logFile}

# Check if Domain Admins in the Local Admins Group
$group = "Domain Admins"
$admins = Get-LocalGroupMember -Group "Administrators" | select -ExpandProperty Name
if ($admins -match "Domain Admins") {
    Write-Log -Message "Local Admin Group for Domain Admins Check" -Level "OK" -LogFile $logFile}
else{Write-Log -Message "Domain Admins is not member of the local admins group" -Level "ERROR" -LogFile $logFile}

Add-Content -Path $logFile -Value "`n############# ConfigMgr Cleint Log Analysis #############`n"

$logPath    = "C:\Windows\CCM\Logs"

# check these logs
$includedLogs = @(
    "ClientIDManagerStartup.log",
    "ClientLocation.log",
    "LocationServices.log",
    "PolicyAgent.log",
    "CcmMessaging.log",
    "CcmEval.log",
    "CcmExec.log",
    "ExecMgr.log",
    "InventoryAgent.log",
    "WUAHandler.log",
    "UpdatesDeployment.log",
    "UpdatesHandler.log",
    "UpdatesStore.log",
    "ScanAgent.log",
    "CAS.log",
    "ContentTransferManager.log",
    "DataTransferService.log"
)

# regex for error searching
$regexError = '(?i)\b(error|failed|failure|fatal|exception|missing|0x[0-9a-f]{4,8})\b'

$results = New-Object System.Collections.Generic.HashSet[string]

Get-ChildItem -Path $logPath -Filter *.log |
Where-Object { $includedLogs -contains $_.Name } |
ForEach-Object {

    $logName = $_.Name

    Get-Content -Path $_.FullName -ErrorAction SilentlyContinue |
    ForEach-Object {

        if ($_ -match '<!\[LOG\[(.*?)\]LOG\]!>') {

            $logMessage = $matches[1]

            if ($logMessage -match $regexError) {
                $results.Add("$logName : $logMessage") | Out-Null
            }
        }
    }
}

$results |
Sort-Object |
Add-Content -Path $logFile -Encoding UTF8

Add-Content -Path $logFile -Value "`n############# Installed Updates #############`n"

$allUpdates = Get-WmiObject -Namespace "root\ccm\SoftwareUpdates\UpdatesStore" -Class CCM_UpdateStatus -ErrorAction Stop

if ($allUpdates) {
        $installeddUpdates = $allUpdates | Where-Object { $_.Status -match "Installed" }
        foreach($update in $installeddUpdates){
            $title = $update.Title
            $status = $update.Status
            Add-Content -Path $logFile -Value "$title : $status"
        }
        
        }


Add-Content -Path $logFile -Value "`n############# Pending, Failed and Missing Updates #############`n"

try {
    $allUpdates = Get-WmiObject -Namespace "root\ccm\SoftwareUpdates\UpdatesStore" -Class CCM_UpdateStatus -ErrorAction Stop

    if ($allUpdates) {

        $failedUpdates = $allUpdates | Where-Object { $_.Status -match "Failed" }
        $missingUpdates = $allUpdates | Where-Object { $_.Status -eq "Missing" }
        $pendingUpdates = $allUpdates | Where-Object { $_.Status -match "Pending" }

        if ($failedUpdates.Count -gt 0) {
            $failedUpdates | Select-Object | ForEach-Object {
                Add-Content -Path $logFile -Value ("FAILED UPDATE: " + $_.Title)
            }
        }

        if ($missingUpdates.Count -gt 0) {
            $missingUpdates | Select-Object | ForEach-Object {
                Add-Content -Path $logFile -Value ("MISSING UPDATE: " + $_.Title)
            }
        }

        if ($pendingUpdates.Count -gt 0) {
            $pendingUpdates | Select-Object | ForEach-Object {
                Add-Content -Path $logFile -Value ("PENDING UPDATE: " + $_.Title)
            }}
    }
    else {Write-Log -Message "The CCM_UpdateStatus WMI Class is empty" -Level "WARNING" -LogFile $logFile}
}
catch {
    Write-Log -Message "Query the CCM_UpdateStatus WMI Class failed" -Level "ERROR" -LogFile $logFile
}


Add-Content -Path $logFile -Value "`n############# CBS Log Analysis #############`n"

$cbsLogPath = "$env:windir\Logs\CBS\CBS.log"

if (Test-Path $cbsLogPath) {
    $cbsAge = (Get-Date) - (Get-Item $cbsLogPath).LastWriteTime
    Write-Log -Message "CBS.log found, last modified $([int]$cbsAge.TotalHours) hour(s) ago" -Level "INFO" -LogFile $logFile

    $cbsPatterns = @(
        "error",
        "failed",
        "corrupt",
        "cannot repair",
        "repair failed",
        "missing file",
        "store corruption",
        "0x800f",
        "0x8007",
        "0x8024",
        "rollback",
        "reboot required",
        "mark store corruption flag",
        "exec: processing complete"
    )

    $cbsLines = Get-Content -Path $cbsLogPath -Tail 8000 -ErrorAction SilentlyContinue
    $cbsHits = $cbsLines | Where-Object {
        $line = $_.ToLower()
        $match = $false
        foreach ($pattern in $cbsPatterns) {
            if ($line.Contains($pattern.ToLower())) {
                $match = $true
                Add-Content -Path $logFile -Value $line
            }
        }
     }
}


Add-Content -Path $logFile -Value "`n############# DISM Log Analysis #############`n"

$dismLogPath = "$env:windir\Logs\DISM\dism.log"

if (Test-Path $dismLogPath) {
    $dismHits = Get-Content -Path $dismLogPath -Tail 8000 -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '(?i)\b(0x[0-9a-f]{4,8})\b' } |
        Select-Object -Unique

    if ($dismHits) {
        Write-Log -Message "DISM.log contains suspicious entries" -Level "WARNING" -LogFile $logFile
        foreach ($line in $dismHits) {
            Add-Content -Path $logFile -Value ("  - " + $line)
            }

            
        }
    }
