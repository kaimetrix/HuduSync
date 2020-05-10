function GetSites() {
    $Sites = (Invoke-Restmethod -Uri "$($controller)/api/self/sites" -WebSession $myWebSession).data
    return $Sites
    }

function UniFiLogin() {
    try {
        Invoke-Restmethod -Uri "$($controller)/api/login" -method post -body $credential -ContentType "application/json; charset=utf-8"  -SessionVariable myWebSession | Out-Null
    }
    catch {
        Write-Host $_.Exception.Message
    }
    return $myWebSession
}

function GetPortForwards() {
    $pforwards = (Invoke-Restmethod -Uri "$($controller)/api/s/$($site.name)/stat/portforward" -WebSession $myWebSession).data
    $forwards = New-Object System.Collections.Generic.List[System.Object]

    foreach ($pforward in $pforwards) {
        $forwards += "<b>Rule</b>: $($pforward.name) : Forwarding $($pforward.src):$($pforward.dst_port) to $($pforward.fwd):$($pforward.fwd_port) using $($pforward.proto) currently $(if ($pforward.enabled -eq $true) {"Enabled"} else {"Disabled"})<br>"
    }
    return "$forwards"
}

function GetTicket() {
    return ""
}

function GetSpeedTest() {
    $test = New-Object System.Collections.Generic.List[System.Object]
    $end      = [Math]::Floor(1000 * (Get-Date ([datetime]::UtcNow) -UFormat %s))
    $start    = [Math]::Floor($end - 86400000)
    $body  = @{
        attrs = 'xput_download','xput_upload','latency','time'
        start = $start
        end = $end
    } | convertTo-Json
    $test = (Invoke-Restmethod -Uri "$($controller)/api/s/$($site.name)/stat/report/archive.speedtest" -WebSession $myWebSession -Method POST -ContentType "application/json" -Body $body).data[0]
    if ($test.xput_download -gt 1) {
        $stest = "DL $([math]::Round($test.xput_download,2)) Mbps / UL $([math]::Round($test.xput_upload,2)) Mbps<br>Latency $($test.latency) ms<br>Performed: $($(Get-Date -Day 1 -Month 1 -Year 1970).AddMilliseconds($test.time))"
    }  else {
        $stest = "No recent test available."
    }
    return "$stest"
}
