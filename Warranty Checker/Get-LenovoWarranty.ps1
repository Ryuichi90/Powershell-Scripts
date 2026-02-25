
    $SerialNumber = ""

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
