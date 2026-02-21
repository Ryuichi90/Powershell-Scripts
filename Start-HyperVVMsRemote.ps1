$vmNames = @("HYD-DC1", "HYD-CM1", "HYD-CLIENT1")
$remoteMachine = "RemotePC"

$securePasswordforUser = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("Administrator", $securePasswordforUser)

foreach ($vm in $vmNames) {
    $result = Invoke-Command -ComputerName $remoteMachine -Credential $credential -ScriptBlock {
        param($vmName)
        try {
            $vmState = (Get-VM -Name $vmName).State
            if ($vmState -eq "Running") {
                "$vmName is already running."
            } else {
                Start-VM -Name $vmName -ErrorAction Stop
				"$vmName started successfully."
                
            }
        } catch {
            "Failed to start $vmName - $_"
        }
    } -ArgumentList $vm

    Write-Host $result
}
Write-Host "The VMs have been started"
Read-Host