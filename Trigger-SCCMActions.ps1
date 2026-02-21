Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000121}" -ErrorAction Stop #Discovery Data Collection Cycle	
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000003}" -ErrorAction Stop #Application Deployment Evaluation Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000010}" -ErrorAction Stop #File Collection Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000001}" -ErrorAction Stop #Hardware Inventory Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000021}" -ErrorAction Stop #Machine Policy Retrieval Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000022}" -ErrorAction Stop #Machine Policy Evaluation Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000002}" -ErrorAction Stop #Software Inventory Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000031}" -ErrorAction Stop #Software Metering Usage Report Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000114}" -ErrorAction Stop #Software Update Deployment Evaluation Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" -ErrorAction Stop #Software Update Scan Cycle
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000032}" -ErrorAction Stop #Windows Installers Source List Update Cycle
						
