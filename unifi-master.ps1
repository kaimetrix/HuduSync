Clear-Host
# Make sure you define these:
#Unifi
[string]$controller = "https://XXXXXXXXXXXXXXXXXXXX:8443"  #Your Unifi URL goes here with the port number ie "https://unifi.domain.com:8443"
[string]$credential = "`{`"username`":`"XXXXXXXXXXXXX`",`"password`":`"XXXXXXXXXXXXXXXXXXXX`"`}"  #Your Unifi username and password go here in the fields with the XXXXX, has to be an Admin account or it can't see PSKs for Wifi or VPNs

#HUDU
[string]$huduurl = "https://XXXXXXXXXXXXXXXX/api/v1"  # Your hudu URL goes here with /api/v1 on the end ie: "https://hudu.domain.com/api/v1"

$huduheads = @{
    'x-api-key' = 'XXXXXXXXXXXXXXXXXXXXXX'  # Your HUDU API Key, destructive isn't required but the autocorrecter for duplicate assets won't work if it's not set
    'Content-Type' = 'application/json'
    }

#IP Info
[string]$ipinfotoken = 'XXXXXXXXXXXXXXXX'  #This isn't required but i recommend signing up for a token at https://ipinfo.io/ i use it to decipher the ISP from the WAN IP, not strictly necessary since you can ping it without a key but the API limit is tiny.

$regex = ‘\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b’ #RegEx to Get IP Address results

Write-Host "`nSync started at $(Get-Date)"
Write-Host "`nStarting Unifi Update"

#Region Functions
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

function GetCompanies() {
    $i=1
    $Companies = New-Object System.Collections.Generic.List[System.Object]
    while ($i -lt 9999) {
        $newcomps=((Invoke-Restmethod -Uri "$($huduurl)/companies?page=$i" -Headers $huduheads).companies)
        $i++
        if ($newcomps.count -eq 0) {
            break
        }
        $Companies += $newcomps
    }
    return $Companies
}

function GetAssets() {
    $i=1
    $assets = New-Object System.Collections.Generic.List[System.Object]
    while ($i -lt 9999) {
        try {
            $newassets = (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets?page=$i" -Headers $huduheads)
            if ($newassets.assets.count -eq 0 -and $newassets -ne $null) {
                $newassets = $newassets | ConvertFrom-Json -AsHashTable
            }
        }
        catch {
            $newassets > $null
        }
        $assets += $newassets.assets
        if ($($newassets.assets).count -lt 25) {
            break
        }
        $i++
    }
    return $assets
}

function WriteAssets() {
    if ($name -notmatch "element-") {
        if ($oldassets.count -gt 1) {
            foreach ($oldasset in $oldassets) {
                try {
                    (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets/$($oldasset.id)" -Method DELETE -Headers $huduheads).data                           
                }
                catch {
                    $_.Exception.Message
                    "$($huduurl)/companies/$($company.id)/assets/$($oldasset.id)"
                }
            }
            try {
                Write-Host "Re-Creating $name"
                (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets" -Method POST -Headers $huduheads -Body $body).data
            }
            catch {
                $_.Exception.Message
                "$($huduurl)/companies/$($company.id)/assets"
                $body
            }
        } elseif ($oldassets) {
            try {
                Write-Host "Updating $name"
                (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets/$($oldassets.id)" -Method PUT -Headers $huduheads -Body $body).data
            }
            catch {
                $_.Exception.Message
                "$($huduurl)/companies/$($company.id)/assets/$($oldassets.id)"
                $body
            }
        } else {
            try {
                Write-Host "Creating $name"
                (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets" -Method POST -Headers $huduheads -Body $body).data
            }
            catch {
                $_.Exception.Message
                "$($huduurl)/companies/$($company.id)/assets"
                $body
            }
        }
    }
}
function GetAttachedAssets($netassets) {
    if ($netassets) {
        $attachedassets = New-Object System.Collections.Generic.List[System.Object]
        foreach ($asset in $netassets) {
            $attachedassets.Add(@{name  = $asset.name
                                    id  = $asset.id
                                    url = $asset.url
                                    })
        }
        $attachedassets.Add(@{})
        $attachedassets = ($attachedassets | ConvertTo-Json) -replace '\r\n','' -replace '  ',''
    } else {
        $attachedassets = ""
        }
    return $attachedassets
}

function SetName() {
    $name = $location + " - " + $device.name
    return $name
}
function SetLocation() {
    $location = ($site.desc -replace $company.name,"" -replace '([\)\(]| \- )','').Trim()
    if ($location.Length -lt 2 ) {
        $location = $company.city
        }
    return $location
}
function ArchiveOldAssets() {
    if ($archiveassets.count -ne 0) {
        foreach ($archiveasset in $archiveassets) {
            if ($null -ne $archiveasset.id) {
                try {
                    Write-Host "Archiving old asset $($archiveasset.name)"
                    (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets/$($archiveasset.id)/archive" -Method PUT -Headers $huduheads).data                           
                }
                catch {
                    $_.Exception.Message
                    "$($huduurl)/companies/$($company.id)/assets/$($archiveasset.id)/archive"
                }
            }
        }
    }
}

function CreateArchiveList() {
    if ($oldassets.count -eq 0) {
        $oldassets=@{
            id=999999999
            }
        }
    foreach ($oldasset in $oldassets) {
        if ($archiveassets -ne $false) {
            $archiveassets = $archiveassets | Where-Object { $_.id -ne $oldasset.id }
        } else {
            $archiveassets = $assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $location -and $_.fields.value -match "Powershell Script" -and $_.id -ne $oldasset.id }
        }
    }
    return $archiveassets
}
function GetTemplateId($templatename) {
    [int]$templateid = ($Layouts | Where-Object {$_.name -eq $templatename}).id
    return $templateid
}
function GetFieldId($fieldname) {
    [int]$fieldid = (($Layouts | Where-Object {$_.id -eq $templateid }).fields | Where-Object { $_.label -eq $fieldname}).id
    return $fieldid
}
#EndRegion Functions

# Fill Global Dynamic Variables
$Companies=GetCompanies
$myWebSession=UniFiLogin
$Sites=GetSites | Sort-Object -Property desc
$Layouts = (Invoke-Restmethod -Uri "$($huduurl)/asset_layouts" -Headers $huduheads).asset_layouts


#Begin the FUN!?!?!?
foreach ($site in $Sites) {  
    $company = ($Companies | Where-Object { $($site.desc) -like "*$($_.name)*" })
    if ($company) {
        $location = SetLocation
        Write-Host "Match Found for UNIFI: $($site.desc) to HUDU:$($company.name) LOCATION:$($location)"
        ################ Devices ######################
        $archiveassets=$false
        $assets = GetAssets
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/stat/device" -WebSession $myWebSession).data | Where-Object { $_.adopted -eq $true }
        foreach ($device in $devices) {
            $templateid = GetTemplateId("Network Devices")
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = GetFieldId('Role')
                        value                 = if ($device.type -eq "usw") {"Switch"} elseif ($device.type -eq "uap") {"Wireless"} elseif ($device.type -eq "ugw") {"Router"} else { "$($device.type)" }
                        },@{
                        asset_layout_field_id = GetFieldId('Manufacturer')
                        value                 = 'Ubiquiti'
                        },@{
                        asset_layout_field_id = GetFieldId('Model')
                        value                 = "$($device.model)"
                        },@{
                        asset_layout_field_id = GetFieldId('IP Address')
                        value                 = "$($device.ip)"
                        },@{
                        asset_layout_field_id = GetFieldId('MAC Address')
                        value                 = "$($device.mac)"
                        },@{
                        asset_layout_field_id = GetFieldId('Location')
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = GetFieldId('Firmware Version')
                        value                 = "$($device.version)"
                        },@{
                        asset_layout_field_id = GetFieldId('Serial Number')
                        value                 = "$($device.serial)"
                        },@{
                        asset_layout_field_id = GetFieldId('Management URL')
                        value                 = "$($controller)/manage/site/$($site.name)/devices/list/1/100"
                        },@{
                        asset_layout_field_id = GetFieldId('Uplink Port')
                        value                 = if ($device.uplink.num_port -and $device.type -ne "ugw") {"Connected from Port #$($device.uplink.num_port) to " + $(if ($device.uplink.uplink_remote_port){"Port #$($device.uplink.uplink_remote_port)"} else {"Router"})} else { ""}
                        },@{
                        asset_layout_field_id = GetFieldId('Uplink Device')
                        value                 = if ($device.uplink.uplink_mac) {GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $device.uplink.uplink_mac } ))} else { ""}
                        },@{
                        asset_layout_field_id = GetFieldId('Performance Statistics')
                        value                 = "$($controller)/manage/site/$($site.name)/statistics/performance/$($device.mac)"
                        },@{
                        asset_layout_field_id = GetFieldId('Switch Statistics')
                        value                 = if ($device.type -eq "usw") {"$($controller)/manage/site/$($site.name)/statistics/switch/$($device.mac)"} else {""}
                        },@{
                        asset_layout_field_id = GetFieldId('Sync Source')
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device.serial })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ Networks ######################
        $templateid = GetTemplateId("Networks")
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -ne "WAN" -and $_.Purpose -ne "site-vpn" }
        foreach ($device in $devices) {
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = GetFieldId('DHCP Server')
                        value                 = "$($device.ip_subnet -replace '(\/\d{2})','')"
                        },@{
                        asset_layout_field_id = GetFieldId('DHCP Scope')
                        value                 = if ($device.dhcpd_start) {"$($device.dhcpd_start) - $($device.dhcpd_stop)"} else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('DNS Servers')
                        value                 = "$($device.dhcpd_dns_1)" + (&{if ($device.dhcpd_dns_2) {", $($device.dhcpd_dns_2)"}}) + (&{if ($device.dhcpd_dns_3) {", $($device.dhcpd_dns_3)"}}) + (&{if ($device.dhcpd_dns_4) {", $($device.dhcpd_dns_4)"}})
                        },@{
                        asset_layout_field_id = GetFieldId('Gateway')
                        value                 = "$($device.ip_subnet -replace '(\/\d{2})','')"
                        },@{
                        asset_layout_field_id = GetFieldId('IP Address (CIDR)')
                        value                 = "$($device.ip_subnet)"
                        },@{
                        asset_layout_field_id = GetFieldId('Location')
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = GetFieldId('Purpose')
                        value                 = "$($device.purpose)"
                        },@{
                        asset_layout_field_id = GetFieldId('VLAN ID')
                        value                 = if ($device.vlan) { "$($device.vlan)" } else { '0' }
                        },@{
                        asset_layout_field_id = GetFieldId('Switches')
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.fields.value -eq "Switch" -and $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location }))
                        },@{
                        asset_layout_field_id = GetFieldId('Management URL')
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = GetFieldId('Routers')
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                        },@{
                        asset_layout_field_id = GetFieldId('Sync Source')
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device._id })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ WiFi ######################
        $templateid = GetTemplateId("Wireless")
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/wlanconf/" -WebSession $myWebSession).data
        foreach ($device in $devices) {
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = GetFieldId('Network SSID')
                        value                 = "$($device.name)"
                        },@{
                        asset_layout_field_id = GetFieldId('Hidden Network?')
                        value                 = if ($device.hide_ssid) { "$($device.hide_ssid)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Guest Network?')
                        value                 = if ($device.is_guest) { "$($device.is_guest)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Security Mode')
                        value                 = "$($device.security)"
                        },@{
                        asset_layout_field_id = GetFieldId('WPA Mode')
                        value                 = "$($device.wpa_mode)"
                        },@{
                        asset_layout_field_id = GetFieldId('WPA Encryption')
                        value                 = "$($device.wpa_enc)"
                        },@{
                        asset_layout_field_id = GetFieldId('Passphrase / Network Key')
                        value                 = "$($device.x_passphrase)"
                        },@{
                        asset_layout_field_id = GetFieldId('VLAN')
                        value                 = if ($device.vlan_enabled) { "$($device.vlan)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Schedule')
                        value                 = if ($device.schedule) { "$($device.schedule -join '<br>')" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Associated Access Points')
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.fields.value -eq "Wireless" -and $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location }))
                        },@{
                        asset_layout_field_id = GetFieldId('Location')
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = GetFieldId('Management URL')
                        value                 = "$($controller)/manage/site/$($site.name)/settings/wlans/$($device.wlangroup_id)/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = GetFieldId('Networks')
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Networks")) -and $_.fields.value -eq $location -and $_.fields.value -eq $device.vlan }))
                        },@{
                        asset_layout_field_id = GetFieldId('Sync Source')
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device._id })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ Internet ######################
        $templateid = GetTemplateId("Internet")
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -eq "WAN" }
        foreach ($device in $devices) {
            $name = SetName
            $router = ($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" })
            $routerip = ($router | ConvertTo-Json | select-string -Pattern $regex | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value })
            if ($device.wan_type -match 'static') {
                $inetinfo = ((Invoke-Restmethod -Uri "http://ipinfo.io/$($device.wan_ip)?token=$ipinfotoken").org -replace '(^[\S\d]{1,12} )','')
            } elseif ($routerip) {
                $inetinfo = ((Invoke-Restmethod -Uri "http://ipinfo.io/$($routerip)?token=$ipinfotoken").org -replace '(^[\S\d]{1,12} )','')
            } else {
                $inetinfo = "Unknown"
            }
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = GetFieldId('IP Address (v4)')
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_ip)" } else { "$routerip" }
                        },@{
                        asset_layout_field_id = GetFieldId('Subnet Mask (v4)')
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_netmask)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Gateway (v4)')
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_gateway)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Provider')
                        value                 = "$($inetinfo)"
                        },@{
                        asset_layout_field_id = GetFieldId('VLAN')
                        value                 = if (($device.wan_type -match 'static') -and ($device.wan_vlan_enabled -eq $true)) {"$($device.wan_vlan)"} else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Address Type (v4)')
                        value                 = "$($device.wan_type)"
                        },@{
                        asset_layout_field_id = GetFieldId('Router')
                        value                 = "$($router.id)"
                        },@{
                        asset_layout_field_id = GetFieldId('Location')
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = GetFieldId('Management URL')
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = GetFieldId('Port')
                        value                 = "$($device.wan_networkgroup)"
                        },@{
                        asset_layout_field_id = GetFieldId('Latest Speed Test Result')
                        value                 = GetSpeedTest
                        },@{
                        asset_layout_field_id = GetFieldId('Speed Test History')
                        value                 = "$($controller)/manage/site/$($site.name)/statistics/speedtest/last_week"
                        },@{
                        asset_layout_field_id = GetFieldId('Sync Source')
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device._id })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ VPN ######################
        $templateid = GetTemplateId("VPNs")
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -eq "site-vpn" }
        foreach ($device in $devices) {
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = GetFieldId('Remote Endpoint')
                        value                 = if ($device.ipsec_peer_ip) { "$($device.ipsec_peer_ip)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Local Endpoint')
                        value                 = if ($device.ipsec_local_ip) { "$($device.ipsec_local_ip)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Remote Network(s)')
                        value                 = if ($device.remote_vpn_subnets) { "$($device.remote_vpn_subnets -join '<br>')" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('IKE Version')
                        value                 = if ($device.ipsec_key_exchange) {"$($device.ipsec_key_exchange)"} else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Devices Associated')
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                        },@{
                        asset_layout_field_id = GetFieldId('Location')
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = GetFieldId('Management URL')
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = GetFieldId('Encryption')
                        value                 = if ($device.ipsec_encryption) { "$($device.ipsec_encryption)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Hash')
                        value                 = if ($device.ipsec_hash) { "$($device.ipsec_hash)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('PFS')
                        value                 = if ($device.ipsec_pfs) { "$($device.ipsec_pfs)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('VTI?')
                        value                 = if ($device.ipsec_dynamic_routing) { "$($device.ipsec_dynamic_routing)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('DH Group (Phase 1)')
                        value                 = if ($device.ipsec_ike_dh_group) { "$($device.ipsec_ike_dh_group)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('DH Group (Phase 2)')
                        value                 = if ($device.ipsec_esp_dh_group) { "$($device.ipsec_esp_dh_group)" } else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Pre-Shared Key')
                        value                 = if ($device.x_ipsec_pre_shared_key) {"$($device.x_ipsec_pre_shared_key)"} else { "" }
                        },@{
                        asset_layout_field_id = GetFieldId('Sync Source')
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device._id })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ Firewall ######################
        [int]$templateid = GetTemplateId("Firewall")
        $body = ConvertTo-Json @{
            asset = @{
                asset_layout_id  = $templateid
                name             = $location
                fields           = @{
                    asset_layout_field_id = GetFieldId('Port Forwards')
                    value                 = GetPortForwards
                    },@{
                    asset_layout_field_id = GetFieldId('Modules')
                    value                 = "$(foreach ($rule in $((Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/get/setting/usg" -WebSession $myWebSession).data)) {$rule.PSObject.properties.remove('_id');$rule.PSObject.properties.remove('site_id');(($rule | Convertto-Json -depth 5) -replace ',','<br>&nbsp;&nbsp;&nbsp;&nbsp;' -replace '{','{<br>&nbsp;&nbsp;&nbsp;&nbsp;'-replace '}','<br>}<br>') })"
                    },@{
                    asset_layout_field_id = GetFieldId('Location')
                    value                 = "$($location)"
                    },@{
                    asset_layout_field_id = GetFieldId('Router')
                    value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Network Devices")) -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                    },@{
                    asset_layout_field_id = GetFieldId('Internet Connection')
                    value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq $(GetTemplateId("Internet")) -and $_.fields.value -eq $location}))
                    },@{
                    asset_layout_field_id = GetFieldId('Firewall Rules')
                    value                 = "$(foreach ($rule in $((Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/firewallrule" -WebSession $myWebSession).data)) {$rule.PSObject.properties.remove('_id');$rule.PSObject.properties.remove('site_id');(($rule | Convertto-Json -depth 5) -replace ',','<br>&nbsp;&nbsp;&nbsp;&nbsp;' -replace '{','{<br>&nbsp;&nbsp;&nbsp;&nbsp;'-replace '}','<br>}<br>') })"
                    },@{
                    asset_layout_field_id = GetFieldId('Management URL')
                    value                 = "$($controller)/manage/site/$($site.name)/settings/routing/list"
                    },@{
                    asset_layout_field_id = GetFieldId('Sync Source')
                    value                 = "UniFi Powershell Script"
                    }
                }
            } -Depth 6
        $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $site.name })
        WriteAssets
    } else {
            Write-Host "`nMatch NOT Found for $($site.desc)"
    }
}
Write-Host "`nSync ended at $(Get-Date)"
