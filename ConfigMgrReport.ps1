$checksNumber = 0
$successCount = 0
$warningCount = 0
$errorCount = 0

function Add-HtmlErrorFinding {

    param(
        [string]$Title,
        [string]$Recommendation
    )

    $script:errorCount += 1

    $script:htmlContent += @"
<div class="finding error">
    <div class="finding-title">
        <span>$Title</span>
        <span class="pill error">ERROR</span>
    </div>
    <div class="section small" style="margin-bottom:10px;">
        $Recommendation
    </div>
</div>

"@
}

function Add-HtmlWarningFinding {

    param(
        [string]$Title,
        [string]$Recommendation
    )

    $script:warningCount += 1

    $script:htmlContent += @"
<div class="finding warning">
    <div class="finding-title">
        <span>$Title</span>
        <span class="pill warning">WARNING</span>
    </div>
    <div class="section small" style="margin-bottom:10px;">
        $Recommendation
    </div>
</div>

"@
}

function Add-HtmlOkFinding {

    param(
        [string]$Title
    )

    $script:successCount += 1

    $script:htmlContent += @"
<div class="finding ok">
    <div class="finding-title">
        <span>$Title</span>
        <span class="pill ok">SUCCESS</span>
    </div>
</div>

"@
}


# HTML style
$htmlContent = @"
<!DOCTYPE html>
<html lang="hu">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>ConfigMgr Troubleshooting Report</title>
<style>
:root {
  --bg: #0b1020;
  --panel: #121933;
  --panel-2: #0f1530;
  --card: rgba(255,255,255,.06);
  --text: #ecf1ff;
  --muted: #a8b3d1;
  --line: rgba(255,255,255,.10);
  --ok: #1dbf73;
  --warn: #f5b700;
  --err: #ef4444;
  --info: #4f8cff;
  --accent: #6d7cff;
  --shadow: 0 14px 40px rgba(0,0,0,.28);
}
* { box-sizing: border-box; }
body {
  margin: 0;
  font-family: "Segoe UI", Roboto, Arial, sans-serif;
  background:
    radial-gradient(circle at top right, rgba(109,124,255,.22), transparent 28%),
    radial-gradient(circle at top left, rgba(29,191,115,.14), transparent 25%),
    linear-gradient(180deg, #0a1022 0%, #0b1020 100%);
  color: var(--text);
}
.wrapper { max-width: 1600px; margin: 0 auto; padding: 28px; }
.hero {
  background: linear-gradient(135deg, rgba(109,124,255,.22), rgba(255,255,255,.04));
  border: 1px solid var(--line);
  border-radius: 24px;
  padding: 28px;
  box-shadow: var(--shadow);
  display: grid;
  gap: 24px;
}
.hero h1 { margin: 0 0 10px; font-size: 34px; letter-spacing: .2px; }
.subtitle { color: var(--muted); font-size: 15px; line-height: 1.55; }
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-top: 24px;
}
.kpi {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 18px;
  padding: 18px;
  backdrop-filter: blur(6px);
}
.kpi .label { color: var(--muted); font-size: 12px; text-transform: uppercase; letter-spacing: .12em; white-space: nowrap;}
.kpi .value { margin-top: 8px; font-size: 28px; font-weight: 700; white-space: nowrap;}
.kpi .sub { margin-top: 4px; color: var(--muted); font-size: 13px; }
.scorecard {
  background: linear-gradient(180deg, rgba(255,255,255,.07), rgba(255,255,255,.04));
  border: 1px solid var(--line);
  border-radius: 22px;
  padding: 24px;
}
.status-ring {
  width: 132px; height: 132px; border-radius: 50%;
  margin: 4px auto 18px;
  display: grid; place-items: center;
  background:
    radial-gradient(circle at center, var(--panel) 52%, transparent 53%),
    conic-gradient(var(--err) 0 100%);
  box-shadow: inset 0 0 28px rgba(255,255,255,.07);
}
.status-ring .inner {
  width: 94px; height: 94px; border-radius: 50%;
  background: var(--panel);
  display: grid; place-items: center;
  border: 1px solid var(--line);
}
.score-title { text-align: center; font-size: 15px; color: var(--muted); }
.score-value { text-align: center; font-size: 26px; font-weight: 700; margin-top: 4px; }
.pill {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 7px 12px; border-radius: 999px;
  font-size: 12px; font-weight: 700; letter-spacing: .05em;
  border: 1px solid transparent; text-transform: uppercase;
}
.pill.ok { background: rgba(29,191,115,.14); color: #86efac; border-color: rgba(29,191,115,.34); }
.pill.warning { background: rgba(245,183,0,.12); color: #fde68a; border-color: rgba(245,183,0,.28); }
.pill.error { background: rgba(239,68,68,.12); color: #fca5a5; border-color: rgba(239,68,68,.28); }
.pill.info { background: rgba(79,140,255,.12); color: #93c5fd; border-color: rgba(79,140,255,.28); }
.grid-2 { display: grid; grid-template-columns: 1.05fr .95fr; gap: 20px; margin-top: 22px; }
.card {
  background: rgba(255,255,255,.045);
  border: 1px solid var(--line);
  border-radius: 22px;
  padding: 22px;
  box-shadow: var(--shadow);
}
.card h2 { margin: 0 0 18px; font-size: 20px; }
.info-table {
  width: 100%; border-collapse: collapse; font-size: 14px;
}
.info-table tr { border-bottom: 1px solid rgba(255,255,255,.08); }
.info-table tr:last-child { border-bottom: none; }
.info-table td { padding: 10px 0; vertical-align: top; }
.info-table td:first-child { color: var(--muted); width: 38%; }
.finding {
  border: 1px solid var(--line);
  border-left-width: 5px;
  border-radius: 16px;
  padding: 14px 16px;
  background: rgba(255,255,255,.03);
  margin-bottom: 12px;
}
.finding.error { border-left-color: var(--err); }
.finding.warning { border-left-color: var(--warn); }
.finding.ok { border-left-color: var(--ok); }
.finding-title {
  display:flex; justify-content:space-between; gap:10px; align-items:flex-start;
  font-weight: 600; margin-bottom: 8px;
}
.finding ul { margin: 8px 0 0 18px; color: var(--muted); }
.finding li { margin: 4px 0; }
.small { color: var(--muted); font-size: 13px; }
.section { margin-top: 22px; }
.cols-3 { display:grid; grid-template-columns: repeat(3, 1fr); gap:16px; }
.mini-card {
  background: var(--card); border: 1px solid var(--line); border-radius: 16px; padding:16px;
}
.mini-card h3 { margin:0 0 8px; font-size:14px; color: var(--muted); text-transform: uppercase; letter-spacing: .1em; }
.mini-card .big { font-size: 24px; font-weight: 700; }
.list {
  margin: 0; padding-left: 18px; color: var(--muted); font-size: 14px;
}
.footer {
  color: var(--muted); font-size: 12px; text-align: center; margin: 22px 0 10px;
}
code {
  background: rgba(255,255,255,.06); padding: 2px 6px; border-radius: 6px; color: #dbeafe;
}
@media (max-width: 1024px) {
  .hero, .grid-2, .cols-3 { grid-template-columns: 1fr; }
  .kpi-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 640px) {
  .wrapper { padding: 14px; }
  .kpi-grid { grid-template-columns: 1fr; }
}
</style>
</head>
<body>
"@

$domain = (Get-WmiObject Win32_ComputerSystem).Domain
$adSite = Get-WMIObject Win32_NTDomain | Select -ExpandProperty ClientSiteName
$hostname = $env:computername

$os = Get-CimInstance Win32_OperatingSystem
$osName = $os.Caption
$osVersion = $os.Version

$sms = new-object -comobject 'Microsoft.SMS.Client'
$siteCode = $sms.GetAssignedSite()


# CCM Client
$ccmClient = Get-WmiObject -Namespace "root\ccm" -Class "CCM_Client" | select *
$clientID = $ccmClient.ClientID
$previousGUID = $ccmClient.PreviousClientId
$GUIDChangeDate = $ccmClient.ClientIdChangeDate

# Client Version
try {
            if ($PowerShellVersion -ge 6) { $clientVersion = (Get-CimInstance -Namespace root/ccm SMS_Client).ClientVersion }
            else { $clientVersion = (Get-WmiObject -Namespace root/ccm SMS_Client).ClientVersion }
    }catch { $obj = $false }

$clientCacheSize = (New-Object -ComObject UIResource.UIResourceMgr).GetCacheInfo().TotalSize / 1024

# Folder count in ccmcache and size of the ccmcache
$path = "C:\Windows\ccmcache"
if (Test-Path $path) {
    $size = (Get-ChildItem -Path $path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $sizeGB = [math]::Round($size / 1GB, 2)

    $folders = Get-ChildItem -Path $path -Directory
    $folderCount = $folders.Count

} else {
    Write-Log -Message "The CCMCache folder doesn't exist" -Level "ERROR" -LogFile $logFile
}

# Client Max Log Size
$logMaxSize = [Math]::Round(((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxSize) / 1000)
# Client Max Log History
$logMaxHistory = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogMaxHistory
# Log Directory
$logDirectory =  (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
# CCM Directory
$ccmDirectory = $logDirectory.replace("\Logs", "")
# Last Client Health Evaluation
try{[datetime]$lastClientHealthRun = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\CCM\CcmEval").LastEvalTime}
    catch{$lastClientHealthRun=[datetime]::MinValue}

$actionmap = @{
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

$schedulerHistory = Get-WmiObject -Namespace "root\ccm\Scheduler" -Class CCM_Scheduler_History

$lastTriggerForActionsHtml = ""

foreach($trigger in $schedulerHistory){
    $actionName = $actionMap[$trigger.ScheduleID]

    if(-not $actionName){
        $actionName = "Unknown action"
    }

    if($trigger.LastTriggerTime -and $actionName -ne "Unknown action"){
        $lastTriggerDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($trigger.LastTriggerTime)
        $formattedDate = $lastTriggerDate.ToString("yyyy-MM-dd HH:mm")
	    $lastTriggerForActionsHtml += "$actionName - $formattedDate <br>"
    }
    else{
        $formattedDate = "No trigger time"
    }

    
}



# Last Update Informations
$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$HistoryCount = $Searcher.GetTotalHistoryCount()
$lastUpdates = $Searcher.QueryHistory(0, $HistoryCount) | select Date, Title  | Where-Object {$_.Title -like "*Cumulative*"} | sort Date -Descending

$stringForHTMLInstalledCumulativeUpdates = ""

if($lastUpdates){
    foreach($lastUpdate in $lastUpdates){
    $date = $lastUpdate.Date
    $title = $lastUpdate.Title
    $stringForHTMLInstalledCumulativeUpdates += "$date - $title <br><br>"

    }
}else{$stringForHTMLInstalledCumulativeUpdates = "Couldn't find any installed cumulative update in the update history"}


# All installed Updates
$stringForHTMLAllInstalledUpdates = ""
$allInstalledUpdates = $Searcher.QueryHistory(0, $HistoryCount) | select Date, Title 

if($allInstalledUpdates){
    foreach($allInstalledUpdate in $allInstalledUpdates){
    $date = $allInstalledUpdate.Date
    $title = $allInstalledUpdate.Title
    $stringForHTMLAllInstalledUpdates += "$date - $title <br><br>"

    }
}else{$stringForHTMLAllInstalledUpdates = "Couldn't find any update history"}


# Update errors in the event log
$updateInstallErrors = Get-WinEvent -LogName System -FilterXPath "*[System[(EventID=20 or EventID=25 or EventID=31)]]" | where {$_.LevelDisplayName -eq "Error"} | select TimeCreated,Message

$stringForHTMLInstallError = ""

if($updateInstallErrors){
    foreach($updateInstallError in $updateInstallErrors){
    $time = $updateInstallError.TimeCreated
    $message = $updateInstallError.Message
    $stringForHTMLInstallError += "$time - $message <br><br>"

    }
}else{$stringForHTMLInstallError = "There's no update error in the Event logs for the 20, 25, 31 EventIDs"}

# Missing Updates
$missingUpdates = get-wmiobject -query "SELECT * FROM CCM_UpdateStatus" -namespace "root\ccm\SoftwareUpdates\UpdatesStore" | where {$_.title -like "*Cumulative*" -and $_.status -eq "Missing"} | select title

$stringForHTMLMissingUpdate = ""

if($missingUpdates){
    foreach($missingUpdate in $missingUpdates){
    $date = $missingUpdate.Date
    $title = $missingUpdate.Title
    $stringForHTMLMissingUpdate += "$date - $title <br><br>"

    }
}else{$stringForHTMLMissingUpdate = "The client can not recognize that any updates are deployed but not installed"}

# Hardware Informations
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$cpu  = Get-CimInstance Win32_Processor
$mb   = Get-CimInstance Win32_BaseBoard

$diskSize = [math]::Round($disk.Size/1GB,2)
$freediskSize = [math]::Round($disk.FreeSpace/1GB,2)
$diskInfo = "$freediskSize GB is free (Total size: $diskSize GB)"

$totalRamBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
$totalRAM = [math]::Round($totalRamBytes / 1GB, 2)
$ramInfo = "$totalRAM GB"

$cpuInfo = $cpu.Name

$mbProduct = $mb.Product
$mbManufacturer = $mb.Manufacturer
$mbInfo = "$mbProduct (Manufacturer: $mbManufacturer)"

$bios = Get-CimInstance Win32_BIOS
$serialNumber = $bios.SerialNumber


# Network Informations
$networkInfoHTML = ""

Get-NetIPConfiguration | ForEach-Object {
    $adapter = Get-NetAdapter -InterfaceIndex $_.InterfaceIndex
    $adapterName = $_.InterfaceAlias
    $adaptermac = $adapter.MacAddress
    $adapterip = $_.IPv4Address.IPAddress
    $adaptergateway = $_.IPv4DefaultGateway.NextHop
    $dhcpEnabled = $_.IPv4Address.PrefixOrigin -eq "Dhcp"

    $networkInfoHTML += "$adapterName &nbsp;&nbsp;&nbsp;&nbsp; $adaptermac &nbsp;&nbsp;&nbsp;&nbsp; $adapterip &nbsp;&nbsp;&nbsp;&nbsp; $adaptergateway &nbsp;&nbsp;&nbsp;&nbsp; DHCP: $dhcpEnabled<br>"
}


$htmlContent += @"
<div class="wrapper">
  <section class="hero">
    <div>
      <h1>ConfigMgr Troubleshooting Report</h1>
      <div class="subtitle">
        Visual status report for the $hostname client machine.<br>
        The report highlights the overall ConfigMgr Client health of the device and try to help you with the recommended troubleshooting steps.
      </div>
      <div class="kpi-grid">
        <div class="kpi"><div class="label">Hostname</div><div class="value" style="font-size:22px">$hostname</div><div class="sub">$domain</div></div>
        <div class="kpi"><div class="label">Site Code</div><div class="value" style="font-size:22px">$siteCode</div></div>
        <div class="kpi"><div class="label">AD Site</div><div class="value" style="font-size:22px">$adSite</div></div>
        <div class="kpi"><div class="label">Client version</div><div class="value" style="font-size:22px">$clientVersion</div></div>
        <div class="kpi"><div class="label">Cache</div><div class="value" style="font-size:22px">$sizeGB GB / $clientCacheSize GB</div></div>
        </div>
    </div>

  </section>

  <div class="grid-2">
    <section class="card">
      <h2>Detailes</h2>

      <table class="info-table">
        <tr><td>Domain</td><td>$domain</td></tr>
        <tr><td>AD Site</td><td>$adSite</td></tr>
        <tr><td>Hostname</td><td>$hostname</td></tr>
        <tr><td>Client ID</td><td><code>$clientID</code></td></tr>
        <tr><td>Previous Client ID</td><td><code>$previousGUID</code></td></tr>
        <tr><td>Last Client ID Change</td><td>$GUIDChangeDate</td></tr>
        <tr><td>Log Directory</td><td>$logDirectory</td></tr>
        <tr><td>CCM Client Directory</td><td>$ccmDirectory</td></tr>
        <tr><td>Maximum Log Size</td><td>$logMaxSize</td></tr>
        <tr><td>Maximum Log History</td><td>$logMaxHistory</td></tr>
        <tr><td>Cache Size</td><td>$clientCacheSize GB</td></tr>
        <tr><td>Cache Current Size</td><td>$sizeGB GB</td></tr>
        <tr><td>Folder Count in CCMCache</td><td>$folderCount</td></tr>
        <tr><td>Last Client Health Evaluation</td><td>$lastClientHealthRun</td></tr>
        <tr><td>Operating System</td><td>$osName</td></tr>
        <tr><td>Operating System Version</td><td>$osVersion</td></tr>

      </table>
    </section>

    <section class="card">
      <h2>Hardware Informations</h2>

      <table class="info-table">
        <tr><td>Disk</td><td>$diskInfo</td></tr>
        <tr><td>CPU</td><td>$cpuInfo</td></tr>
        <tr><td>Memory</td><td>$ramInfo</td></tr>
        <tr><td>Motherboard</td><td>$mbInfo</td></tr>
        <tr><td>Serialnumber</td><td>$serialNumber</td></tr>
      </table>
      <br>
      <h2 style="margin-top:20px;">Network Informations</h2>
      <div class="section small" style="margin-bottom:10px;">$networkInfoHTML</div>
      <br>
      <h2 style="margin-top:20px;">Last Trigger Time of the Actions</h2>
      <div class="section small" style="margin-bottom:10px;">$lastTriggerForActionsHtml</div>
    </section>

    
  </div>

  <div class="grid-2">
    <section class="card">
      <h2>Recent Update State</h2>
      <div class="small" style="margin-bottom:10px; font-weight: bold; color: white">The Installed Cumulative Updates:</div>
      <div class="section small" style="margin-bottom:10px;">$stringForHTMLInstalledCumulativeUpdates</div>

      <div class="small" style="margin-bottom:10px; font-weight: bold; color: white">Missing Updates:</div>
      <div class="section small" style="margin-bottom:10px;">$stringForHTMLMissingUpdate</div>
      
      <div class="section" style="margin-bottom:10px; font-weight: bold; color: white">Update Failures in the Event Log:</div>
      <div class="section small" style="margin-bottom:10px;">$stringForHTMLInstallError</div>
    </section>

    <section class="card">
        <h2>Installed Updates Snapshot</h2>
        <div class="small" style="margin-bottom:10px;">$stringForHTMLAllInstalledUpdates</div>
    </section>

  </div>
    <div class="section">
    <section class="card section">
    <h2>Issue Check Overview</h2>

"@

# Stating the checks hier

# Checking ccmsetup.log file
$checksNumber += 1
$ccmSetupLogPath = "C:\Windows\CCMSetup\Logs\ccmsetup.log"
$resultsForCcmSetup = ""

if (Test-Path $ccmSetupLogPath) {

    $lastLine = Get-Content -Path $ccmSetupLogPath -Tail 1 -ErrorAction SilentlyContinue

    if ($lastLine -match 'CcmSetup is exiting with return code 0') {
        Add-HtmlOkFinding -Title "Ccmsetup.log Check"
    }
    else {
        Add-HtmlErrorFinding -Title "Ccmsetup.log Check" -Recommendation "Based on the ccmsetup.log the ConfigMgr client is not installed properly, it has to be reinstalled."
            }
}
else {
    Add-HtmlErrorFinding -Title "Ccmsetup.log Check" -Recommendation "The ccmsetup.log file doesn't exist."
}

# Assigned Site validation
$checksNumber += 1
if ([string]::IsNullOrWhiteSpace($siteCode) -or $siteCode.Length -ne 3) {
    Add-HtmlErrorFinding -Title "Assigned Site Check" -Recommendation "The client has no valid assigned site code. Check client push/install parameters, boundaries, and site assignment."
}
else {
    Add-HtmlOkFinding -Title "Assigned Site Check"
}



# Maintanance Windows
$checksNumber += 1
$serviceWindow = Get-WmiObject -Namespace "root\ccm\clientsdk" -Class CCM_ServiceWindow | Select-Object Name,StartTime,Duration
if ($serviceWindow) {
    Add-HtmlOkFinding -Title "Maintanance Window Check"
} else {
    Add-HtmlWarningFinding -Title "Maintanance Window Check" -Recommendation "There's no definied Maintanance Windows. Check the collection memberships if the device is targeted by any Update collections. Trigger the Machine Policy Retrieval & Evaluation Cycle"
}

# Checking if the metered connection is enabled
$checksNumber += 1
[void][Windows.Networking.Connectivity.NetworkInformation, Windows, ContentType = WindowsRuntime]
$cost = [Windows.Networking.Connectivity.NetworkInformation]::GetInternetConnectionProfile().GetConnectionCost()
$isMeteredConnectionEnabled = $cost.ApproachingDataLimit -or $cost.OverDataLimit -or $cost.Roaming -or $cost.BackgroundDataUsageRestricted -or ($cost.NetworkCostType -ne "Unrestricted")

if($isMeteredConnectionEnabled -eq $false){
        Add-HtmlOkFinding -Title "Metered Connection Check"
    
}else{
        Add-HtmlErrorFinding -Title "Metered Connection Check" -Recommendation "The Metered Connection setting is enabled on the LAN adapter, which may prevent updates from being installed or even block the reinstallation of the ConfigMgr client. Disable this setting in the network adapter properties."
}

# WSUS server check
$checksNumber += 1
$wuServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate').WUServer
$wsusWithoutPort = $wuServer -replace '^https?://','' -replace ':\d+$',''
$port = ($wuServer -split ':')[-1]
$wuStatusServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate').WUStatusServer
$useWUServer = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU').UseWUServer

if($useWUServer -ne 1){
        Add-HtmlErrorFinding -Title "UseWUServer Registry Check" -Recommendation "Check the settings in HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU. The value of the UseWUServer key has to be 1."    
}
else{
        Add-HtmlOkFinding -Title "UseWUServer Registry Check"
}

#DNS check to the WSUS
$checksNumber += 1
try {
    $dns = Resolve-DnsName $wsusWithoutPort -ErrorAction Stop
    Add-HtmlOkFinding -Title "WSUS Server Check ($wsusWithoutPort) - DNS Lookup Check"

}
catch {
    Add-HtmlErrorFinding -Title "WSUS Server Check ($wsusWithoutPort) - DNS Lookup Check" -Recommendation "Check if you can resolve the $wsusWithoutPort hostname. Clear the DNS cache: ipconfig /flushdns"
    
}

#Port Check to the WSUS
$checksNumber += 1
try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($wsusWithoutPort,$port)
        $tcp.Close()
        Add-HtmlOkFinding -Title "WSUS Server Check ($wsusWithoutPort) - Port $port Connection Check"

     }
catch {
        Add-HtmlErrorFinding -Title "WSUS Server Check ($wsusWithoutPort) - Port $port Connection Check" -Recommendation "The client can not connect to the WSUS port. Test it with Test-NetConnection $wsusWithoutPort -Port $port <br> Check the client firewall settings and other clients in the same VLAN if they can connect to the WSUS."
  }


# Checking the Count of the SDF Files (Local ConfigMgr Database Files)
$checksNumber += 1
$files = @(Get-ChildItem "$ccmDirectory\*.sdf" -ErrorAction SilentlyContinue)

if ($files.Count -lt 7) {
    Add-HtmlErrorFinding -Title "SDF Files Check" -Recommendation "ConfigMgr Client database is corrupt (SDF local database files). ConfigMgr Client reinstallation is needed."
}
else {
Add-HtmlOkFinding -Title "SDF Files Check"}


# Checking the Actions (9)
$checksNumber += 1
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

$success = $true
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
    $success = $false
     
    }

    

}

if ($success) {
    Add-HtmlOkFinding -Title "Action Trigger Check"}
else{
    Add-HtmlErrorFinding -Title "Action Trigger Check" -Recommendation "Not all of the actions could be triggered in the ConfigMgr. Reastart the PC, wait 5 minutes and try to trigger the actions manually.<br> If it fails: the ConfigMgr Client has to be reinstalled."
    }

# Checking missing actions
$checksNumber += 1
$actionCount = ($result | Where-Object {$_.Exists }).Count
$missingActions = $result | Where-Object { -not $_.Exists } | select ActionName
$missingActionNamesForHTML = ""

if($missingActions){
    foreach($missingAction in $missingActions){
        $actionName = $missingAction.ActionName
        $missingActionNamesForHTML += "$actionName <br>"
    }
    Add-HtmlErrorFinding -Title "Missing Actions Check" -Recommendation "Missing actions in the Scheduler namespace:<br> $missingActionNamesForHTML <br><br> The ConfigMgr Client has to be reinstalled."
} else{Add-HtmlOkFinding -Title "Missing Actions Check"}





# Count of the Installed Components
$checksNumber += 1
$installedComponents = (Get-WmiObject -Namespace "root\ccm" -Class "CCM_InstalledComponent").Count
if($installedComponents -eq 18) {
    Add-HtmlOkFinding -Title "Installed ConfigMgr Components Count Check"
}
else{
    Add-HtmlErrorFinding -Title "Installed ConfigMgr Components Count Check" -Recommendation "Count of the installed components should be 18 but it's $installedComponents so the ConfigMgr has to be reinstalled"
}
# Checking the Software Center Path
$checksNumber += 1
$existsSWCenter = Test-Path "C:\Windows\CCM\ClientUX\SCClient.exe"
if($existsSWCenter){
    Add-HtmlOkFinding -Title "Software Center Path Check"
}
else{
    Add-HtmlErrorFinding -Title "Software Center Path Check" -Recommendation "C:\Windows\CCM\ClientUX\SCClient.exe can not be found. The ConfigMgr Client reinstallation maybe needed"
}


# Checking ccmsqlce Log File
$checksNumber += 1
$logFileCcmSQLCE = "$logDirectory\CcmSQLCE.log"
$logLevel = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').logLevel

if ( (Test-Path -Path $logFileCcmSQLCE) -and ($logLevel -ne 0) ) {
            $LastWriteTime = (Get-ChildItem $logFileCcmSQLCE).LastWriteTime
            $CreationTime = (Get-ChildItem $logFileCcmSQLCE).CreationTime
            $FileDate = Get-Date($LastWriteTime)
            $FileCreated = Get-Date($CreationTime)

            $now = Get-Date
            if ( ($now - $FileDate).Days -eq 0) {
                Add-HtmlOkFinding -Title "CcmSQLCE.log Update Time Check" 
                }
            else {
                Add-HtmlWarningFinding -Title "CcmSQLCE.log Update Time Check" -Recommendation "CcmSQLCE.log has no update today.<br> Recommendation: trigger all of the actions in the ConfigMgr, wait 10 minutes and check again. If the log file date doesn't change the ConfigMgr client should be reinstalled."
            }

                    # CcmSQLCE.log content check
        $checksNumber += 1
        $CcmSQLCEErrors = Select-String -Path $logFileCcmSQLCE -Pattern "error","fail","corrupt","locked","timeout"
        $ccmSQLCEHTMLString = ""
        if($CcmSQLCEErrors){
            foreach($CcmSQLCEError in $CcmSQLCEErrors) {
                $errorLine = $CcmSQLCEError -replace '.*<!\[LOG\[','' -replace '\]LOG\].*',''
                $ccmSQLCEHTMLString += "$errorLine <br>"
            }
            Add-HtmlWarningFinding -Title "CcmSQLCE.log Content Check" -Recommendation "Errors: <br>$ccmSQLCEHTMLString<br><br>Recommendation: search for the error code if there's any"
        } else{
            Add-HtmlOkFinding -Title "CcmSQLCE.log Content Check"
        }

        }




else {
    Add-HtmlErrorFinding -Title "CcmSQLCE.log Update Time Check" -Recommendation "The CcmSQLCE.log doesn't exist it can mean that the ConfigMgr client isn't working properly and has to be reinstalled."
 }



# Checking Certificate
$checksNumber += 1
$certificatesForConfigMgr = Get-ChildItem Cert:\LocalMachine\SMS
if($certificatesForConfigMgr.Count -eq 2){
    Add-HtmlOkFinding -Title "Certificate Count Check"
    foreach($cert in $certificatesForConfigMgr){
        $checksNumber += 1
        $friendlyName = $cert.FriendlyName
        $notAfterInDays = ($cert.NotAfter - (Get-Date)).Days
        if($notAfterInDays -gt 0){
            Add-HtmlOkFinding -Title "$friendlyName Expiration Date Check"            
        }else{ 
            Add-HtmlErrorFinding -Title "$friendlyName is expired" -Recommendation "$friendlyName certificate is expired. <br> Recommendation: Stop the SMS Agent Host service, open certlm.msc as administrator, delete the certificates in the SMS store and start the SMS Agent Host. <br> The Certificates will be regenerated."
       }
       $checksNumber += 1
       if($cert.HasPrivateKey){
            Add-HtmlOkFinding -Title "$friendlyName Private Key Check" 
       }else{Add-HtmlErrorFinding -Title "$friendlyName Private Key Check" -Recommendation "The $friendlyName has no private key. Recommendation: Stop the SMS Agent Host service, open certlm.msc as administrator, delete the certificates in the SMS store and start the SMS Agent Host. <br> The Certificates will be regenerated."}
    
    }
}else{
    Add-HtmlErrorFinding -Title "Certificate Count Check" -Recommendation "Missing certificates in the Cert:\LocalMachine\SMS store. The reinstallation of the ConfigMgr client is needed."
}

# BITS Check
$checksNumber += 1
$Errors = Get-BitsTransfer -AllUsers | Where-Object { ($_.JobState -like "TransientError") -or ($_.JobState -like "Transient_Error") -or ($_.JobState -like "Error") }
if ($Errors) {
    Add-HtmlErrorFinding "BITS Transfer Check" -Recommendation "Execute the bitsadmin /list /allusers command in CMD as administrator and check what exectly can not be downloaded.<br>The qmgr files can be deleted in the follwoing folder: $env:allusersprofile\Application Data\Microsoft\Network\Downloader\"
}
else {
    Add-HtmlOkFinding -Title "BITS Transfer Check"
}

# Checking Client Settings
$checksNumber += 1
try{
    $clientConfig = Get-WmiObject -Namespace "root\ccm\Policy\DefaultMachine\RequestedConfig" -Class CCM_ClientAgentConfig -ErrorAction Stop
    $ClientSettingsConfig = @(Get-WmiObject -Namespace "root\ccm\Policy\DefaultMachine\RequestedConfig" -Class CCM_ClientAgentConfig -ErrorAction SilentlyContinue | Where-Object {$_.PolicySource -eq "CcmTaskSequence"})
    if ($ClientSettingsConfig.Count -gt 0) {
        Add-HtmlErrorFinding "Client Settings Configuration Check" -Recommendation "The ConfigMgr Client has to be reinstalled."
    }
    else {
        Add-HtmlOkFinding "Client Settings Configuration Check"
    }
}
catch{
    Add-HtmlErrorFinding "Client Settings Configuration Check" -Recommendation "The ConfigMgr Client has to be reinstalled."
}


# Checking Pending Reboot
$checksNumber += 1
$pendingReboot = $false
$rebootReason = ""

$key = Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
if ($null -ne $key) {
                    $rebootReason = "Pending reboot reason: CBS"
                    $pendingReboot = $true
}

$key = Get-Item 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue
if ($null -ne $key) {
                     $rebootReason = "Pending reboot reason: Windows Update"
                     $pendingReboot = $true
}

$util = [wmiclass]'\\.\root\ccm\clientsdk:CCM_ClientUtilities'
$status = $util.DetermineIfRebootPending()

if(($null -ne $status) -and $status.RebootPending){
                            $rebootReason = "Pending reboot reason: Configuration Manager"
                            $pendingReboot = $true
 }
if ($pendingReboot -eq $false) {
                    Add-HtmlOkFinding -Title "Pending Reboot Check"
}else{
    Add-HtmlErrorFinding -Title "Pending Reboot Check" -Recommendation "$rebootReason <br>Recommendation: Restart the machine"

}

# Check Provisioning Mode
$checksNumber += 1
$registryPath = 'HKLM:\SOFTWARE\Microsoft\CCM\CcmExec'
$provisioningMode = (Get-ItemProperty -Path $registryPath).ProvisioningMode
if ($provisioningMode -eq 'true') {
    Add-HtmlErrorFinding -Title "Provisioning Mode Check" -Recommendation "Recommendation: execute the command: Invoke-WmiMethod -Namespace root\CCM -Class SMS_Client -Name SetClientProvisioningMode -ArgumentList $false"
}
else {
    Add-HtmlOkFinding -Title "Provisioning Mode Check"
}

# Free Space
$checksNumber += 1
$driveC = Get-WmiObject -Class Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"} | Select-Object FreeSpace, Size
$freeSpace = $driveC.FreeSpace / 1024 / 1024 /1024
$freeSpaceRounded = ([math]::Round($freeSpace,2))
if ($freeSpaceRounded -lt 10 -and $freeSpaceRounded -gt 5) {Add-HtmlWarningFinding -Title "Free Disk Space Check" -Recommendation "Free space on the disk: $freeSpaceRounded"}
if ($freeSpaceRounded -lt 5) {Add-HtmlErrorFinding -Title "Free Disk Space Check" -Recommendation "Free space on the disk: $freeSpaceRounded"}
if ($freeSpaceRounded -gt 10) {Add-HtmlOkFinding -Title "Free Disk Space Check"}



# DNS check
$checksNumber += 1
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
                   Add-HtmlErrorFinding -Title "Client DNS Check" -Recommendation "IP '$dnsIP' in DNS record do not exist locally.<br>Check the DNS server for corrupt record. Execute ipconfig -flushdns"
                   
                } else {
                    Add-HtmlOkFinding -Title "Client DNS Check"
                }
            }
}


# Checking %USERPROFILE%\AppData\Roaming value
$checksNumber += 1
New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
$correctValue = '%USERPROFILE%\AppData\Roaming'
$currentValue = (Get-Item 'HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\').GetValue('AppData', $null, 'DoNotExpandEnvironmentNames')
if ($currentValue -ne $correctValue) {
        Add-HtmlErrorFinding -Title "User Shell Folder Check" -Recommendation "AppData registry value is not correct in HKU:\S-1-5-18\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\"
}
else{
    Add-HtmlOkFinding -Title "User Shell Folder Check"
}

# SMS Agent Host service
$checksNumber += 1
$CCMService = Get-Service -Name ccmexec -ErrorAction SilentlyContinue
if ($CCMService) {
      Add-HtmlOkFinding -Title "SMS Agent Host Service Present Check"
      $checksNumber += 1
      if ($CCMService.Status -eq "Stopped" -or $CCMService.StartType -ne "Automatic") {
              Add-HtmlErrorFinding -Title "SMS Agent Host Service Status Check" -Recommendation "The SMS Agent Host service is not running. It has to be started and the Startype has to be automatic"
                }
       else{
              Add-HtmlOkFinding -Title "SMS Agent Host Service Status Check"
       }
   }
 else{
        Add-HtmlErrorFinding -Title "SMS Agent Host Service Present Check" -Recommendation "The SMS Agent Host service not present on the machine. ConfigMgr has to be reinstalled"
}

# check if the log file has been updated in the last 24 hours
function Test-LogFreshness {
    param(
        [string]$LogPath,
        [int]$MaxAgeHours = 24,
        [string]$Title
    )

    $script:checksNumber += 1

    if (-not (Test-Path $LogPath)) {
        Add-HtmlErrorFinding -Title $Title -Recommendation "Log file not found: $LogPath"
        return
    }

    $lastWrite = (Get-Item $LogPath).LastWriteTime
    $ageHours = [math]::Round(((Get-Date) - $lastWrite).TotalHours, 1)

    if ($ageHours -le $MaxAgeHours) {
        Add-HtmlOkFinding -Title $Title
    }
    elseif ($ageHours -le ($MaxAgeHours * 3)) {
        Add-HtmlWarningFinding -Title $Title -Recommendation "Log is stale. Last modified $ageHours hours ago."
    }
    else {
        Add-HtmlErrorFinding -Title $Title -Recommendation "Log is too old. Last modified $ageHours hours ago."
    }
}

Test-LogFreshness -LogPath "$logDirectory\PolicyAgent.log" -MaxAgeHours 24 -Title "PolicyAgent.log Freshness Check"
Test-LogFreshness -LogPath "$logDirectory\PolicyEvaluator.log" -MaxAgeHours 24 -Title "PolicyEvaluator.log Freshness Check"


# function for checking the log files content
function Test-LogFile {
    param(
        [string]$Title,
        [string]$LogPath,
        [string[]]$Patterns,
        [string]$Recommendation
    )

    $script:checksNumber += 1

    if (-not (Test-Path $LogPath)) {
        Add-HtmlWarningFinding -Title $Title -Recommendation "Log file not found: $LogPath"
        return
    }
    # in the -notmatch section specific error codes can be ignored
    $matches = Get-Content $LogPath -Tail 300 | Select-String -Pattern $Patterns | Where-Object { ($_ -notmatch "0x00000001") -and ($_ -notmatch "0x0000000a") -and ($_ -notmatch "0x0") } 

    if ($matches) {
        Add-HtmlWarningFinding -Title $Title -Recommendation "$Recommendation Check the <b><i>Highlighted errors in the ConfigMgr logs </i></b> section for more details and do the troubleshooting based on the error codes."
    }
    else {
        Add-HtmlOkFinding -Title $Title
    }
}

Test-LogFile -Title "LocationServices.log Check" -LogPath "$logDirectory\LocationServices.log" -Patterns @("error","failed","unable","no locations found") -Recommendation "Possible issues with the DNS, Management Point, BoundaryGroups (IP range + AD Site) - it has to be checked.<br>Try to trigger the Machine Policy Retrieval & Evaluation Cycle."
Test-LogFile -Title "CAS.log Check" -LogPath "$logDirectory\CAS.log" -Patterns @("error","failed","hash","corrupt") -Recommendation "There could be an issue with the ccmcache. Maybe it helps to clear the content of the ccmcache and force the ConfigMgr to download the content again."
Test-LogFile -Title "ContentTransferManager.log Check" -LogPath "$logDirectory\ContentTransferManager.log" -Patterns @("error","failed","timeout") -Recommendation "Possible issues with the DNS, Distribution Point, BoundaryGroups. <br>Check the connection to the DP and the BITS (Get-BitsTransfer -AllUsers)."
Test-LogFile -Title "DataTransferService.log Check" -LogPath "$logDirectory\DataTransferService.log" -Patterns @("error","failed","0x802000","0x80072","0x800700") -Recommendation "Possible issue with the downloading of the content. <br>If the downloading process stucked in the Software Center: check the firewall, disk space, restart the BITS service.<br>If nothing helps reset the BITS queue: Get-BitsTransfer -AllUsers | Remove-BitsTransfer"
Test-LogFile -Title "WUAHandler.log Check" -LogPath "$logDirectory\WUAHandler.log" -Patterns @("error","failed","scan failed","0x") -Recommendation "Possible issue to connect to the WSUS. If no updates in the Software Center: <br>check the HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate registry keys<br> check if the DualScan is enabled which is causing the issue <br> trigger the update related actions in the ConfigMgr"
Test-LogFile -Title "ScanAgent.log Check" -LogPath "$logDirectory\ScanAgent.log" -Patterns @("error","failed","scan failed","0x") -Recommendation "Possible issue with the scan. Trigger the update related actions in the ConfigMgr again"
Test-LogFile -Title "UpdatesDeployment.log Check" -LogPath "$logDirectory\UpdatesDeployment.log" -Patterns @("error","failed","deadline","not targeted","0x") -Recommendation "Possible issue with the update deployment. Check <br>if the machine is in the right collection<br>if the deployment is active in MCM<br>if the maintanance window is not blocking<br>trigger the Machine Policy Retrieval & Evaluation Cycle"
Test-LogFile -Title "UpdatesHandler.log Check" -LogPath "$logDirectory\UpdatesHandler.log" -Patterns @("error","failed","0x") -Recommendation "Possible issue with the update installation. Check the CBS.log, pending reboot, disk space."




# ConfigMgr namespace health
$namespaces = @(
    "root\ccm",
    "root\ccm\policy",
    "root\ccm\clientsdk",
    "root\ccm\SoftwareUpdates\UpdatesStore"
)

foreach ($ns in $namespaces) {
    $checksNumber += 1
    try {
        Get-WmiObject -Namespace $ns -List -ErrorAction Stop | Out-Null
        Add-HtmlOkFinding -Title "Namespace Check ($ns)"
    }
    catch {
        Add-HtmlErrorFinding -Title "Namespace Check ($ns)" -Recommendation "The namespace cannot be accessed. WMI/ConfigMgr client repair or reinstall may be needed."
    }
}

# General WMI Check
$checksNumber += 1
$result = winmgmt /verifyrepository
switch -wildcard ($result) {
            "*inconsistent*" {Add-HtmlErrorFinding -Title "WMI Repository Consistency Check" -Recommendation "The WMI repository is inconsistent"} 
            "*not consistent*"  {Add-HtmlErrorFinding -Title "WMI Repository Consistency Check" -Recommendation "The WMI repository is inconsistent"}
            "*WMI repository is consistent*"  {Add-HtmlOkFinding -Title "WMI Repository Consistency Check"}
}

$checksNumber += 1
Try {
    $WMI = Get-WmiObject Win32_ComputerSystem -ErrorAction Stop
    Add-HtmlOkFinding -Title "WMI Connection Check to Win32_ComputerSystem"
} 
Catch {
    Add-HtmlErrorFinding -Title "WMI Repository Consistency Check" -Recommendation "Failed to connect to WMI class Win32_ComputerSystem. WMI is corrupt."
}

# Triggering the Update Actions - updatestore.log
$checksNumber += 1
Try {$SCCMUpdatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore -ErrorAction Stop
     $SCCMUpdatesStore.RefreshServerComplianceState()
     Add-HtmlOkFinding -Title "Refresh Update Store Compliance Check"
} 
Catch {
    Add-HtmlErrorFinding -Title "Refresh Update Store Compliance Check" -Recommendation "Restart the machine and check again. If the issue still occurs reinstall the ConfigMgr Client"
}
 
# Checking the Communication to the MP in the Log file
$checksNumber += 1
$logfileStateMessage = "C:\Windows\CCM\Logs\StateMessage.log"
if (Test-Path $logfileStateMessage) {
    $StateMessage = Get-Content($logfileStateMessage)
    if ($StateMessage -match 'Successfully forwarded State Messages to the MP') {
            Add-HtmlOkFinding -Title "Forwarding Messages to the MP Based on StateMessage.log Check"
    }
    else {
            Add-HtmlWarningFinding -Title "Forwarding Messages to the MP Based on StateMessage.log Check" -Recommendation "Based on the StateMessage.log there could be an issue with the communication to the MP.<br>Check the network and friewall related settings."
    }
}
else{
    Add-HtmlErrorFinding -Title "Forwarding Messages to the MP Based on StateMessage.log Check" -Recommendation "The StateMessage.log can not be found. Maybe the ConfigMgr Client is not installed."
}


# DNS Check to the MP
$checksNumber += 1
$MP = Get-WmiObject -Namespace root\ccm -Class SMS_Authority | select -ExpandProperty CurrentManagementPoint
try {
    $dns = Resolve-DnsName $MP -ErrorAction Stop
    Add-HtmlOkFinding -Title "DNS Lookup to the MP ($MP) Check"
}
catch {
    Add-HtmlErrorFinding -Title "DNS Lookup to the MP ($MP) Check" -Recommendation "Recommendation: check the network and firewall related settings. Try to resolve the $MP host with nslookup." 
}

# Port Check to the MP
$checksNumber += 1
try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.Connect($MP,80)
        $tcp.Close()
        Add-HtmlOkFinding -Title "Port 80 to MP ($MP) Connection Check"
}
catch {
        Add-HtmlErrorFinding -Title "Port 80 to MP ($MP) Connection Check" -Recommendation "Connect to port 80 FAILED to the Management Point ($MP) which is caused by a network or firewall related issue. Recommendation: Test-NetConnection $MP -Port 80"
}

# MP Cert Endpoint
$checksNumber += 1
$url1 = "http://$MP/SMS_MP/.sms_aut?mpcert"
try {
    $r = Invoke-WebRequest -Uri $url1 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Add-HtmlOkFinding -Title "Request MPCERT Check"
        }
}
catch {
        Add-HtmlErrorFinding -Title "Request MPCERT Check" -Recommendation "Recommendation: check the network and firewall related settings. Try to open the http://$MP/SMS_MP/.sms_aut?mpcert URL in a browser."
}

# MP List Endpoint
$checksNumber += 1
$url2 = "http://$MP/SMS_MP/.sms_aut?mplist"
try {
    $r = Invoke-WebRequest -Uri $url2 -UseBasicParsing -TimeoutSec 10
    if ($r.StatusCode -eq 200) {
        Add-HtmlOkFinding -Title "Request MPLIST Check"
    }
}
catch {
        Add-HtmlErrorFinding -Title "Request MPLIST Check" -Recommendation "Recommendation: check the network and firewall related settings. Try to open the http://$MP/SMS_MP/.sms_aut?mplist URL in a browser."
}

# Checking registry.pol File
$checksNumber += 1
$MachineRegistryFile = "$($env:WinDir)\System32\GroupPolicy\Machine\registry.pol"
$file = Get-ChildItem -Path $MachineRegistryFile -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty LastWriteTime
$regPolDate = Get-Date($file)
$now = Get-Date
if (($now - $regPolDate).Days -ne 0) {
        Add-HtmlWarningFinding -Title "Machine registry.pol File Age Check" -Recommendation "Machine registry.pol file is older than 1 day. Gpupdate should be executed."
}
else{Add-HtmlOkFinding -Title "Machine registry.pol File Age Check"}          


# Orphaned Cache Folders
$checksNumber += 1
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
If ($counterForOrphFolders -eq 0) {
    Add-HtmlOkFinding -Title "Orphan Folder Check"
} 
else {
    Add-HtmlErrorFinding -Title "Orphan Folder Check" -Recommendation "Number of the orphaned folders in ccmcache: $counterForOrphFolders. These folders are more than 30 days old so they could be deleted in the ccmcache."
}


# Checking Services
$checksNumber += 1
$services = @("BITS", "winmgmt", "wuauserv", "lanmanserver", "RpcSs", "W32Time", "ccmexec", "CryptSvc")
$notRunningServices = ""
foreach ($service in $services) {

    $obj = Get-Service -Name $service
    $serviceName = $obj.DisplayName

    if ($obj.Status -ne "Running") {
        $notRunningServices += $serviceName
     }
}

if($notRunningServices -eq ""){
    Add-HtmlOkFinding -Title "Service State Check"
}else{
    Add-HtmlErrorFinding -Title "Service State Check" -Recommendation "The following services are not running: $notRunningServices <br>Please check and start the affected services."
}

# Checking Admin Share and C: Share
$checksNumber += 1
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'ADMIN$'}
if ($share.Name -contains 'ADMIN$') {
    Add-HtmlOkFinding -Title "Share for C:\Windows Check"
}
else {
    Add-HtmlErrorFinding -Title "Share for C:\Windows Check" -Recommendation "The C:\Windows folder is not shared and it has to be for MCM."
}

$checksNumber += 1
$share = Get-WmiObject Win32_Share | Where-Object {$_.Name -like 'C$'}
if ($share.Name -contains "C$") {
    Add-HtmlOkFinding -Title "Share for C:\ Root Check"
}
else {
    Add-HtmlErrorFinding -Title "Share for C:\ Root Check" -Recommendation "The C:\ root folder is not shared and it has to be for MCM."
}

# Check CcmEval.log file
$checksNumber += 1
$clientHealthForHTML = ""
if (Select-String -Path "C:\Windows\CCM\Logs\CcmEval.log" -Pattern "failed" -Quiet) {    
        $errorsInCcmEval = Select-String -Path "C:\Windows\CCM\Logs\CcmEval.log" -Pattern "failed"
        foreach($errorInCcmEval in $errorsInCcmEval) {
            if(($errorInCcmEval -replace '.*<!\[LOG\[','' -replace '\]LOG\].*','') -ne "Failed to get SOFTWARE\Policies\Microsoft\Microsoft Antimalware\Real-Time Protection\DisableIntrusionPreventionSystem"){
                $logLine = ($errorInCcmEval -replace '.*<!\[LOG\[','' -replace '\]LOG\].*','')
                if (-not $clientHealthForHTML.Contains("$logLine <br>") -and $logLine -ne "Can't determine whether previous sent succeed, assume sent failed") {

                    $clientHealthForHTML += "$logLine <br>"
                }
                
            }
            
        }
        
    } 


if($clientHealthForHTML){
    Add-HtmlWarningFinding -Title "Client Health Check Based On CcmEval.log" -Recommendation "Errors:<br>$clientHealthForHTML"
}
else {
    Add-HtmlOkFinding -Title "Client Health Check Based On CcmEval.log"
}
# Checking Hardware Inventory Scan
$checksNumber += 1
$wmi = Get-WmiObject -Namespace root\ccm\invagt -Class InventoryActionStatus | Where-Object {$_.InventoryActionID -eq '{00000000-0000-0000-0000-000000000001}'} | Select-Object @{label='HWSCAN';expression={$_.ConvertToDateTime($_.LastCycleStartedDate)}} 
$HWScanDate = $wmi | Select-Object -ExpandProperty HWSCAN
$minDate = (Get-Date).AddHours(-6)

if ($HWScanDate -gt $minDate) {
    Add-HtmlOkFinding -Title "Hardware Inventory Scan Check (last 6 hours)"
}
else {
    Add-HtmlWarningFinding -Title "Hardware Inventory Scan Check (last 6 hours)" -Recommendation "There was no Hardware Inventory sync in the last 6 hours.<br>Recommendation: trigger the Hardware Inventory action in the ConfigMgr Client"
}

# Check if Domain Admins in the Local Admins Group
$checksNumber += 1
$group = "Domain Admins"
$admins = Get-LocalGroupMember -Group "Administrators" | select -ExpandProperty Name
if ($admins -match "Domain Admins") {
    Add-HtmlOkFinding -Title "Local Admin Group for Domain Admins Check"
}
else{
    Add-HtmlErrorFinding -Title "Local Admin Group for Domain Admins Check" -Recommendation "Domain Admins is not member of the local administrators group on the PC"
}










$htmlContent += @"

    <div class="cols-3">
      <div class="mini-card"><h3>All Checks</h3><div class="big">$checksNumber</div></div>
      
      <div class="mini-card" style="background: rgba(29,191,115,.14); color: #86efac; border-color: rgba(29,191,115,.34);"><h3>Success</h3><div class="big">$successCount</div></div>
      <div class="mini-card" style="background: rgba(245,183,0,.12); color: #fde68a; border-color: rgba(245,183,0,.28);"><h3>Warning</h3><div class="big">$warningCount</div></div>
      <div class="mini-card" style="background: rgba(239,68,68,.12); color: #fca5a5; border-color: rgba(239,68,68,.28);"><h3>Error</h3><div class="big">$errorCount</div></div>
    </div>

</div>

    
    <div class="section">
    <section class="card section">
    <h2>Highlighted errors in the ConfigMgr logs</h2>
"@


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

$resultsFromLogs = ""

Get-ChildItem -Path "C:\Windows\CCM\Logs" -Filter *.log |
Where-Object { $includedLogs -contains $_.Name } |
ForEach-Object {

    $logName = $_.Name

    Get-Content -Path $_.FullName -ErrorAction SilentlyContinue |
    ForEach-Object {

        if ($_ -match '<!\[LOG\[(.*?)\]LOG\]!>') {

            $logMessage = $matches[1]

            if ($logMessage -match $regexError) {
                $textForAppend = "<b>$logName</b> : $logMessage <br>"
                if (-not $resultsFromLogs.Contains($textForAppend)) {
                    $resultsFromLogs += $textForAppend
                }
            }
        }
    }
}


# regex for error codes translation
$regexError = '(?i)\b(0x[0-9a-f]{4,8})\b'

$resultsForErrorCodesFromLogs = ""

Get-ChildItem -Path "C:\Windows\CCM\Logs" -Filter *.log |
Where-Object { $includedLogs -contains $_.Name } |
ForEach-Object {

    $logName = $_.Name

    Get-Content -Path $_.FullName -ErrorAction SilentlyContinue |
    ForEach-Object {

        if ($_ -match '<!\[LOG\[(.*?)\]LOG\]!>') {

            $logMessage = $matches[1]

            # Összes hibakód kinyerése a sorból
            $errorMatches = [regex]::Matches($logMessage, $regexError)

            foreach ($match in $errorMatches) {
                $errorCode = $match.Groups[1].Value

                 $num = if ($code -match "^0x") { [Convert]::ToInt32($code, 16) } else { [int]"$errorCode" }
                 $msg = (New-Object ComponentModel.Win32Exception($num)).Message

                $textForAppend = "<b>$errorCode</b> : $msg <br>"

                if (-not $resultsForErrorCodesFromLogs.Contains($textForAppend)) {
                    $resultsForErrorCodesFromLogs += $textForAppend
                }
            }
        }
    }
}


# dism and cbs log analysis
$regexError = '(?i)\b0x[0-9a-f]{4,8}\b'

$logFiles = @(
    "C:\Windows\Logs\DISM\dism.log",
    "C:\Windows\Logs\CBS\CBS.log"
)

$uniqueErrors = [System.Collections.Generic.HashSet[string]]::new()

$resultsForDismAndCbs = ""

foreach ($logFile in $logFiles) {
    if (Test-Path $logFile) {

        $logName = Split-Path $logFile -Leaf

        Get-Content -Path $logFile -ErrorAction SilentlyContinue |
        ForEach-Object {

            $errorMatches = [regex]::Matches($_, $regexError)

            foreach ($match in $errorMatches) {
                $errorCode = $match.Value.ToLower()

                if ($uniqueErrors.Add("$logName|$errorCode")) {

                    try {
                        $errorNumber = [Convert]::ToInt32($errorCode, 16)
                        $errorMessage = (New-Object ComponentModel.Win32Exception($errorNumber)).Message
                    }
                    catch {
                        $errorMessage = "Unknown error code"
                    }

                    # HTML kimenet
                    $resultsForDismAndCbs += "<b>$logName</b> : $errorCode - $errorMessage <br>"
                }
            }
        }
    }
}



$htmlContent += @"

<div class="section" style="margin-bottom:10px;"$resultsFromLogs</div>
<h2>Error code translation for ConfigMgr logs</h2>
<div class="section" style="margin-bottom:10px;"$resultsForErrorCodesFromLogs</div>
<h2>Error code translation for DISM and CBS logs</h2>
<div class="section" style="margin-bottom:10px;"$resultsForDismAndCbs</div>

"@


$htmlContent += @"
    </div>
    </section>

    </div>




  </section>



</div>
</body>
</html>
"@



$hostname = $env:COMPUTERNAME
$outputPath = "C:\Temp\" + $hostname + "_ConfigMgr_TS_Report.html"

$htmlContent | Out-File -FilePath $outputPath -Encoding UTF8

