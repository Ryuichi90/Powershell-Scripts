$UpdatePath = ""
$Updates = Get-ChildItem -Path $UpdatePath | Where-Object {$_.Name -like "*.msu"}

ForEach ($Update in $Updates) {

    $UpdateFilePath = $Update.FullName
    Start-Process -Wait wusa -ArgumentList "/update $UpdateFilePath", "/quiet", "/norestart"

}