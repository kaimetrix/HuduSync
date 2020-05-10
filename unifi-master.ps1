Clear-Host
Write-Host "`nSync started at $(Get-Date)"
Write-Host "`nStarting Unifi Update"
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    . ("$ScriptDirectory\Secrets\secrets.ps1")
    . ("$ScriptDirectory\Functions\functions.ps1")
    . ("$ScriptDirectory\Functions\func-unifi.ps1")
    . ("$ScriptDirectory\Functions\func-hudu.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}

$Companies=GetCompanies
$myWebSession=UniFiLogin
$Sites=GetSites

foreach ($site in $Sites) {  
    $company = ($Companies | Where-Object { $($site.desc) -like "*$($_.name)*" })
    if ($company) {
        #Write-Host "Match Found for $($site.desc)"
        ################ Devices ######################
        $archiveassets=$false
        $assets = GetAssets
        [int]$templateid=3
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/stat/device" -WebSession $myWebSession).data | Where-Object { $_.adopted -eq $true }
        foreach ($device in $devices) {
            $location = SetLocation
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = 17
                        value                 = if ($device.type -eq "usw") {"Switch"} elseif ($device.type -eq "uap") {"Wireless"} elseif ($device.type -eq "ugw") {"Router"} else { "$($device.type)" }
                        },@{
                        asset_layout_field_id = 94
                        value                 = 'Ubiquiti'
                        },@{
                        asset_layout_field_id = 93
                        value                 = "$($device.model)"
                        },@{
                        asset_layout_field_id = 18
                        value                 = "$($device.ip)"
                        },@{
                        asset_layout_field_id = 92
                        value                 = "$($device.mac)"
                        },@{
                        asset_layout_field_id = 95
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = 129
                        value                 = "$($device.version)"
                        },@{
                        asset_layout_field_id = 130
                        value                 = "$($device.serial)"
                        },@{
                        asset_layout_field_id = 126
                        value                 = "$($controller)/manage/site/$($site.name)/devices/list/1/100"
                        },@{
                        asset_layout_field_id = 147
                        value                 = if ($device.uplink.num_port -and $device.type -ne "ugw") {"Connected from Port #$($device.uplink.num_port) to " + $(if ($device.uplink.uplink_remote_port){"Port #$($device.uplink.uplink_remote_port)"} else {"Router"})} else { ""}
                        },@{
                        asset_layout_field_id = 157
                        value                 = if ($device.uplink.uplink_mac) {GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "3" -and $_.fields.value -eq $device.uplink.uplink_mac } ))} else { ""}
                        },@{
                        asset_layout_field_id = 204
                        value                 = "$($controller)/manage/site/$($site.name)/statistics/performance/$($device.mac)"
                        },@{
                        asset_layout_field_id = 204
                        value                 = if ($device.type -eq "usw") {"$($controller)/manage/site/$($site.name)/statistics/switch/$($device.mac)"} else {""}
                        },@{
                        asset_layout_field_id = 215
                        value                 = "UniFi Powershell Script"
                        }
                    }
                } -Depth 6
            $oldassets = ($assets | Where-Object { $_.asset_layout_id -eq $templateid -and $_.fields.value -match $device.mac })
            WriteAssets
            $archiveassets=CreateArchiveList
        }
        ArchiveOldAssets
        $archiveassets=$false
        ################ Networks ######################
        [int]$templateid=2
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -ne "WAN" -and $_.Purpose -ne "site-vpn" }
        foreach ($device in $devices) {
            $location = SetLocation
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = 12
                        value                 = "$($device.ip_subnet -replace '(\/\d{2})','')"
                        },@{
                        asset_layout_field_id = 13
                        value                 = if ($device.dhcpd_start) {"$($device.dhcpd_start) - $($device.dhcpd_stop)"} else { "" }
                        },@{
                        asset_layout_field_id = 14
                        value                 = "$($device.dhcpd_dns_1)" + (&{if ($device.dhcpd_dns_2) {", $($device.dhcpd_dns_2)"}}) + (&{if ($device.dhcpd_dns_3) {", $($device.dhcpd_dns_3)"}}) + (&{if ($device.dhcpd_dns_4) {", $($device.dhcpd_dns_4)"}})
                        },@{
                        asset_layout_field_id = 15
                        value                 = "$($device.ip_subnet -replace '(\/\d{2})','')"
                        },@{
                        asset_layout_field_id = 16
                        value                 = "$($device.ip_subnet)"
                        },@{
                        asset_layout_field_id = 9
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = 106
                        value                 = "$($device.purpose)"
                        },@{
                        asset_layout_field_id = 107
                        value                 = if ($device.vlan) { "$($device.vlan)" } else { '0' }
                        },@{
                        asset_layout_field_id = 125
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.fields.value -eq "Switch" -and $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location }))
                        },@{
                        asset_layout_field_id = 142
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = 148
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                        },@{
                        asset_layout_field_id = 216
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
        [int]$templateid=9
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/wlanconf/" -WebSession $myWebSession).data
        foreach ($device in $devices) {
            $location = SetLocation
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = 58
                        value                 = "$($device.name)"
                        },@{
                        asset_layout_field_id = 102
                        value                 = if ($device.hide_ssid) { "$($device.hide_ssid)" } else { "" }
                        },@{
                        asset_layout_field_id = 105
                        value                 = if ($device.is_guest) { "$($device.is_guest)" } else { "" }
                        },@{
                        asset_layout_field_id = 59
                        value                 = "$($device.security)"
                        },@{
                        asset_layout_field_id = 101
                        value                 = "$($device.wpa_mode)"
                        },@{
                        asset_layout_field_id = 103
                        value                 = "$($device.wpa_enc)"
                        },@{
                        asset_layout_field_id = 99
                        value                 = ""
                        },@{
                        asset_layout_field_id = 123
                        value                 = if ($device.vlan_enabled) { "$($device.vlan)" } else { "" }
                        },@{
                        asset_layout_field_id = 124
                        value                 = if ($device.schedule) { "$($device.schedule -join '<br>')" } else { "" }
                        },@{
                        asset_layout_field_id = 100
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.fields.value -eq "Wireless" -and $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location }))
                        },@{
                        asset_layout_field_id = 127
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = 131
                        value                 = "$($controller)/manage/site/$($site.name)/settings/wlans/$($device.wlangroup_id)/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = 145
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "2" -and $_.fields.value -eq $location -and $_.fields.value -eq $device.vlan }))
                        },@{
                        asset_layout_field_id = 99
                        value                 = "$($device.x_passphrase)"
                        },@{
                        asset_layout_field_id = 224
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
        [int]$templateid=13
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -eq "WAN" }
        foreach ($device in $devices) {
            $location = SetLocation
            $name = SetName
            $router = ($assets | Where-Object { $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" })
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
                        asset_layout_field_id = 108
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_ip)" } else { "$routerip" }
                        },@{
                        asset_layout_field_id = 109
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_netmask)" } else { "" }
                        },@{
                        asset_layout_field_id = 111
                        value                 = if ($device.wan_type -match 'static') { "$($device.wan_gateway)" } else { "" }
                        },@{
                        asset_layout_field_id = 110
                        value                 = "$($inetinfo)"
                        },@{
                        asset_layout_field_id = 114
                        value                 = if (($device.wan_type -match 'static') -and ($device.wan_vlan_enabled -eq $true)) {"$($device.wan_vlan)"} else { "" }
                        },@{
                        asset_layout_field_id = 115
                        value                 = "$($device.wan_type)"
                        },@{
                        asset_layout_field_id = 122
                        value                 = "$($router.id)"
                        },@{
                        asset_layout_field_id = 128
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = 143
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = 146
                        value                 = "$($device.wan_networkgroup)"
                        },@{
                        asset_layout_field_id = 192
                        value                 = GetSpeedTest
                        },@{
                        asset_layout_field_id = 203
                        value                 = "$($controller)/manage/site/$($site.name)/statistics/speedtest/last_week"
                        },@{
                        asset_layout_field_id = 213
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
        [int]$templateid=14
        $devices = (Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/networkconf/" -WebSession $myWebSession).data | Where-Object { $_.Purpose -eq "site-vpn" }
        foreach ($device in $devices) {
            $location = SetLocation
            $name = SetName
            $body = ConvertTo-Json @{
                asset = @{
                    asset_layout_id  = $templateid
                    name             = $name
                    fields           = @{
                        asset_layout_field_id = 132
                        value                 = if ($device.ipsec_peer_ip) { "$($device.ipsec_peer_ip)" } else { "" }
                        },@{
                        asset_layout_field_id = 134
                        value                 = if ($device.ipsec_local_ip) { "$($device.ipsec_local_ip)" } else { "" }
                        },@{
                        asset_layout_field_id = 135
                        value                 = if ($device.remote_vpn_subnets) { "$($device.remote_vpn_subnets -join '<br>')" } else { "" }
                        },@{
                        asset_layout_field_id = 137
                        value                 = if ($device.ipsec_key_exchange) {"$($device.ipsec_key_exchange)"} else { "" }
                        },@{
                        asset_layout_field_id = 141
                        value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                        },@{
                        asset_layout_field_id = 138
                        value                 = "$($location)"
                        },@{
                        asset_layout_field_id = 144
                        value                 = "$($controller)/manage/site/$($site.name)/settings/networks/edit/$($device._id)"
                        },@{
                        asset_layout_field_id = 150
                        value                 = if ($device.ipsec_encryption) { "$($device.ipsec_encryption)" } else { "" }
                        },@{
                        asset_layout_field_id = 151
                        value                 = if ($device.ipsec_hash) { "$($device.ipsec_hash)" } else { "" }
                        },@{
                        asset_layout_field_id = 152
                        value                 = if ($device.ipsec_pfs) { "$($device.ipsec_pfs)" } else { "" }
                        },@{
                        asset_layout_field_id = 153
                        value                 = if ($device.ipsec_dynamic_routing) { "$($device.ipsec_dynamic_routing)" } else { "" }
                        },@{
                        asset_layout_field_id = 154
                        value                 = if ($device.ipsec_ike_dh_group) { "$($device.ipsec_ike_dh_group)" } else { "" }
                        },@{
                        asset_layout_field_id = 155
                        value                 = if ($device.ipsec_esp_dh_group) { "$($device.ipsec_esp_dh_group)" } else { "" }
                        },@{
                        asset_layout_field_id = 156
                        value                 = if ($device.x_ipsec_pre_shared_key) {"$($device.x_ipsec_pre_shared_key)"} else { "" }
                        },@{
                        asset_layout_field_id = 223
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
        [int]$templateid=20
        $location = SetLocation
        $body = ConvertTo-Json @{
            asset = @{
                asset_layout_id  = $templateid
                name             = $location
                fields           = @{
                    asset_layout_field_id = 185
                    value                 = GetPortForwards
                    },@{
                    asset_layout_field_id = 186
                    value                 = "$(foreach ($rule in $((Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/get/setting/usg" -WebSession $myWebSession).data)) {$rule.PSObject.properties.remove('_id');$rule.PSObject.properties.remove('site_id');(($rule | Convertto-Json -depth 5) -replace ',','<br>&nbsp;&nbsp;&nbsp;&nbsp;' -replace '{','{<br>&nbsp;&nbsp;&nbsp;&nbsp;'-replace '}','<br>}<br>') })"
                    },@{
                    asset_layout_field_id = 187
                    value                 = "$($location)"
                    },@{
                    asset_layout_field_id = 188
                    value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "3" -and $_.fields.value -eq $location -and $_.fields.value -eq "Router" }))
                    },@{
                    asset_layout_field_id = 189
                    value                 = GetAttachedAssets($($assets | Where-Object { $_.asset_layout_id -eq "13" -and $_.fields.value -eq $location}))
                    },@{
                    asset_layout_field_id = 190
                    value                 = "$(foreach ($rule in $((Invoke-Restmethod -Uri "$controller/api/s/$($site.name)/rest/firewallrule" -WebSession $myWebSession).data)) {$rule.PSObject.properties.remove('_id');$rule.PSObject.properties.remove('site_id');(($rule | Convertto-Json -depth 5) -replace ',','<br>&nbsp;&nbsp;&nbsp;&nbsp;' -replace '{','{<br>&nbsp;&nbsp;&nbsp;&nbsp;'-replace '}','<br>}<br>') })"
                    },@{
                    asset_layout_field_id = 191
                    value                 = "$($controller)/manage/site/$($site.name)/settings/routing/list"
                    },@{
                    asset_layout_field_id = 212
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
