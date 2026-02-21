$computer = ""
$credential = Get-Credential

function Show-Section {
    param(
        [string]$Title,
        [object]$Data
    )

    Write-Host "#########################################" -ForegroundColor DarkYellow
    Write-Host $Title -ForegroundColor DarkYellow
    Write-Host "#########################################" -ForegroundColor DarkYellow

    $Data | ForEach-Object {
        foreach ($property in $_.PSObject.Properties) {
            if (-not [string]::IsNullOrWhiteSpace($property.Value)) {
                Write-Host "$($property.Name): $($property.Value)"
            }
        }
    }

    Write-Host ""
}


# Get OS informations
$baseboard = Get-WmiObject -Class Win32_BaseBoard -ComputerName $computer -Credential $credential | select Manufacturer,Model,Name,SerialNumber,Product
$bios = Get-WmiObject -Class Win32_BIOS -ComputerName $computer -Credential $credential | select PSComputerName,SMBIOSBIOSVersion,Manufacturer,Name,SerialNumber,Version
$system = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer -Credential $credential | Select-Object Domain,PSComputerName,Manufacturer, SystemFamily, Model, Name, PartOfDomain, PrimaryOwnerName, UserName, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory / 1GB, 2)}}

Show-Section -Title "Motherboard" -Data $baseboard
Show-Section -Title "BIOS" -Data $bios
Show-Section -Title "Computer System" -Data $system

# Get HW informations
$cpuInfo = Get-WmiObject -Class Win32_Processor -ComputerName $computer -Credential $credential | select Caption,Manufacturer,Name,MaxClockSpeed,NumberOfCores,NumberOfLogicalProcessors
$csProductInfo = Get-WmiObject -Class Win32_ComputerSystemProduct -ComputerName $computer -Credential $credential | select IdentifyingNumber,Name,Vendor,Version,Caption
$diskDriveInfo = Get-WmiObject -Class Win32_DiskDrive -ComputerName $computer -Credential $credential | select Model,Caption,Status,@{Name='SizeGB'; Expression={[math]::Round($_.Size / 1GB, 2)}}
$logicalDiskInfo = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computer -Credential $credential | select DeviceID,Name,DriveType,@{Name='FreeSpaceGB'; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},@{Name='SizeGB'; Expression={[math]::Round($_.Size / 1GB, 2)}},VolumeName,FileSystem
$partitionInfo = Get-WmiObject -Class Win32_DiskPartition -ComputerName $computer -Credential $credential | select Name,BootPartition,PrimaryPartition,@{Name='SizeGB'; Expression={[math]::Round($_.Size / 1GB, 2)}}
$volumeInfo = Get-WmiObject -Class Win32_Volume -ComputerName $computer -Credential $credential | select DriveLetter,FileSystem,@{Name='FreeSpaceGB'; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},Label
$memoryInfo = Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $computer -Credential $credential | select Caption,Name,Manufacturer,Capacity

Show-Section -Title "Processor" -Data $cpuInfo
Show-Section -Title "CSProduct" -Data $csProductInfo
Show-Section -Title "Disk" -Data $diskDriveInfo
Show-Section -Title "Logical Disk System" -Data $logicalDiskInfo
Show-Section -Title "Partition" -Data $partitionInfo
Show-Section -Title "Volume" -Data $volumeInfo
Show-Section -Title "RAM" -Data $memoryInfo

# Get Network informations
$networkDrives = Get-WmiObject -Class Win32_NetworkConnection -ComputerName $computer -Credential $credential | select Name,AccessMask,Path,LocalName,RemoteName,Persistent,ConnectionState,Status
$networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $computer -Credential $credential | Select-Object Description,Manufacturer,NetConnectionSID,NetEnabled,Name, ProductName, AdapterType, MACAddress
$networkConfig = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computer -Credential $credential | select Description,DHCPEnabled,DHCPServer,DNSDomain,DNSServerSearchOrder,DefaultIPGateway,IPAddress,IPSubnet,MACAddress

Show-Section -Title "Network Drives" -Data $networkDrives
Show-Section -Title "Network Adapters" -Data $networkAdapters
Show-Section -Title "Network Configuration" -Data $networkConfig

# Get OS informations
$osInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer -Credential $credential | select Name,Caption,BuildNumber,Version,FreePhysicalMemory,InstallDate,LastBootUpTime,LocalDateTime,NumberOfUsers,RegisteredUser,SystemDrive
Show-Section -Title "Operating System" -Data $osInfo

# Get User and Group informations
$group = Get-WmiObject -Class Win32_Group -ComputerName $computer -Credential $credential | Select-Object Name
$adminUsers = Get-WmiObject -Class Win32_GroupUser -ComputerName $computer -Credential $credential | Where-Object { $_.GroupComponent -match "Administrators|Rendszergazdák" } | Select-Object PartComponent, GroupComponent
$allUsers = Get-WmiObject -Class Win32_UserAccount -ComputerName $computer -Credential $credential | Select-Object Name,SID,Domain

Show-Section -Title "Group" -Data $group
Show-Section -Title "Administrator Users" -Data $adminUsers
Show-Section -Title "All Users" -Data $allUsers

# Get Processes
$processes = Get-WmiObject -Class Win32_Process -ComputerName $computer -Credential $credential  | Select-Object Name,Caption,ExecutablePath,ProcessId | Sort-Object Name
Show-Section -Title "Processes" -Data $processes

# Get Services
$services = Get-WmiObject -Class Win32_Service  -ComputerName $computer -Credential $credential | Select-Object DisplayName,Name,Status,PathName,StartMode,State | Sort-Object DisplayName
Show-Section -Title "Services" -Data $services

# Get Installed Programes and Updates

$installedApps = Get-WmiObject -Class Win32_Product -ComputerName $computer -Credential $credential | Select-Object Name,Version,Vendor,InstallDate | Sort-Object Name 
$updates = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $computer -Credential $credential | Select-Object Description, HotFixID, InstalledOn

Show-Section -Title "Installed Programes" -Data $installedApps
Show-Section -Title "Windows Updates" -Data $updates











