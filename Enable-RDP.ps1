Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices -Computer $computer -Authentication 6).SetAllowTSConnections(1,1)
mstsc /v:"$computer"
