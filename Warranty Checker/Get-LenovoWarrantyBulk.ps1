$InputFile  = "C:\Temp\serials.txt"
$OutputFile = "C:\Temp\Lenovo_Warranty_Result.csv"

$SerialNumbers = Get-Content $InputFile

$Results = @()

foreach ($SerialNumber in $SerialNumbers) {

    Write-Host "Processing $SerialNumber ..." -ForegroundColor Cyan

    try {

        $data = @{"serialNumber"="$($SerialNumber)"; "country"="us"; "language"="en" }
        $json = $data | ConvertTo-Json

          $Response = Invoke-WebRequest -Uri "https://pcsupport.lenovo.com/us/en/api/v4/upsell/redport/getIbaseInfo" `
                -Method Post `
                -Headers @{
                    "User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0";
                    "Accept"="application/json, text/plain, */*";
                    "Accept-Language"="en-US,en;q=0.5";
                    "Content-Type"="application/json"} `
                -Body $json | Select-Object -ExpandProperty Content

    $WarrantyStart = $Response | ConvertFrom-Json | Select-Object -ExpandProperty Data | Select-Object -ExpandProperty currentWarranty | Select-Object -ExpandProperty startDate
    $WarrantyEnd = $Response | ConvertFrom-Json | Select-Object -ExpandProperty Data | Select-Object -ExpandProperty currentWarranty | Select-Object -ExpandProperty EndDate
    $Product = $Response | ConvertFrom-Json | Select-Object -ExpandProperty Data | Select-Object -ExpandProperty machineInfo | Select-Object -ExpandProperty product
    $Model = $Response | ConvertFrom-Json | Select-Object -ExpandProperty Data | Select-Object -ExpandProperty machineInfo | Select-Object -ExpandProperty model

        $Results += [PSCustomObject]@{
            SerialNumber  = $SerialNumber
            Product       = $Product
            Model         = $Model
            WarrantyStart = $WarrantyStart
            WarrantyEnd   = $WarrantyEnd
        }

        Start-Sleep -Milliseconds 500

    }
    catch {
        Write-Host "Failed: $SerialNumber" -ForegroundColor Red

        $Results += [PSCustomObject]@{
            SerialNumber  = $SerialNumber
            Product       = "ERROR"
            Model         = "ERROR"
            WarrantyStart = "ERROR"
            WarrantyEnd   = "ERROR"
        }
    }
}

$Results | Export-Csv $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"
Write-Host "Finished. Output saved to $OutputFile" -ForegroundColor Green
