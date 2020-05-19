#HUDU
[string]$huduurl = "https://XXXXXXXXXXXXX/api/v1"  # Your hudu URL goes here with /api/v1 on the end ie: "https://hudu.domain.com/api/v1"

$huduheads = @{
  'x-api-key' = 'XXXXXXXXXXXXXXXXX'  # Your HUDU API Key, destructive isn't required but the autocorrecter for duplicate assets won't work if it's not set
  'Content-Type' = 'application/json'
  }

$templates = @{
  "asset_layout" = @{
    "name" = "Networks"
    "icon" = "fas fa-network-wired"
    "color" = "#a7db11"
    "icon_color" = "#0f0d0d"
    "active" = "true"
    "include_passwords" = "true"
    "include_comments" = "true"
    "include_files" = "true"
    "fields" = @{
    "label" = "Location"
    "field_type" = "Text"
      },@{
      "label" = "Purpose"
      "field_type" = "Text"
      },@{
      "label" = "VLAN ID"
      "field_type" = "Number"
      },@{
      "label" = "DHCP Server"
      "field_type" = "Text"
      },@{
      "label" = "DHCP Scope"
      "field_type" = "Text"
      },@{
      "label" = "DNS Servers"
      "field_type" = "RichText"
      },@{
      "label" = "Gateway"
      "field_type" = "Text"
      },@{
      "label" = "IP Address (CIDR)"
      "field_type" = "Text"
      },@{
      "label" = "Description"
      "field_type" = "RichText"
      },@{
      "label" = "Switches"
      "field_type" = "AssetLink"
      },@{
      "label" = "Management URL"
      "field_type" = "Website"
      },@{
      "label" = "Routers"
      "field_type" = "AssetLink"
      },@{
      "label" = "Sync Source"
      "field_type" = "Text"
      }
    }
  },@{
    "asset_layout" = @{  
      "name" = "Network Devices"
      "icon" = "fas fa-network-wired"
      "color" = "#fc4200"
      "icon_color" = "#FFFFFF"
      "active" = "true"
      "include_passwords" = "true"
      "include_comments" = "true"
      "include_files" = "true"
      "fields" = @{
          "label" = "Role"
          "field_type" = "Text"
        },@{
          "label" = "Location"
          "field_type" = "Text"
        },@{
          "label" = "Manufacturer"
          "field_type" = "Text"
        },@{
          "label" = "Model"
          "field_type" = "Text"
        },@{
          "label" = "IP Address"
          "field_type" = "Text"
        },@{
          "label" = "MAC Address"
          "field_type" = "Text"
        },@{
          "label" = "Configuration"
          "field_type" = "RichText"
        },@{
          "label" = "Notes"
          "field_type" = "RichText"
        },@{
          "label" = "Installation Date"
          "field_type" = "Date"
        },@{
          "label" = "Management URL"
          "field_type" = "Website"
        },@{
          "label" = "Firmware Version"
          "field_type" = "Text"
        },@{
          "label" = "Serial Number"
          "field_type" = "Text"
        },@{
          "label" = "Uplink Port"
          "field_type" = "Text"
        },@{
          "label" = "Uplink Device"
          "field_type" = "AssetLink"
        },@{
          "label" = "Performance Statistics"
          "field_type" = "Website"
        },@{
          "label" = "Switch Statistics"
          "field_type" = "Website"
        },@{
          "label" = "Sync Source"
          "field_type" = "Text"
        }
    }
  },@{
    "asset_layout" = @{
      "name" = "Wireless"
      "icon" = "fas fa-wifi"
      "color" = "#00e2eb"
      "icon_color" = "#293b75"
      "active" = "true"
      "include_passwords" = "true"
      "include_comments" = "true"
      "include_files" = "true"
      "fields" = @{
          "label" = "Network SSID"
          "field_type" = "Text"
          "required" = "true"
        },@{
          "label" = "Hidden Network?"
          "field_type" = "CheckBox"
        },@{
          "label" = "Guest Network?"
          "field_type" = "CheckBox"
        },@{
          "label" = "Security Mode"
          "field_type" = "Text"
        },@{
          "label" = "WPA Mode"
          "field_type" = "Text"
        },@{
          "label" = "WPA Encryption"
          "field_type" = "Text"
        },@{
          "label" = "Passphrase / Network Key"
          "field_type" = "Password"
        },@{
          "label" = "Description/Notes"
          "field_type" = "RichText"
        },@{
          "label" = "VLAN"
          "field_type" = "Text"
        },@{
          "label" = "Schedule"
          "field_type" = "RichText"
        },@{
          "label" = "Associated Access Points"
          "field_type" = "AssetLink"
        },@{
          "label" = "Location"
          "field_type" = "Text"
        },@{
          "label" = "Management URL"
          "field_type" = "Website"
        },@{
          "label" = "Networks"
          "field_type" = "AssetLink"
        },@{
          "label" = "Sync Source"
        }
    }
  },@{
    "asset_layout" = @{
      "name" = "Internet"
      "icon" = "fas fa-circle"
      "color" = "#f2c218"
      "icon_color" = "#FFFFFF"
      "active" = "true"
      "include_passwords" = "true"
      "include_comments" = "true"
      "include_files" = "true"
      "password_types" = "Active Directory\r\nApplication\r\nBackup\r\nBank Processor (Gateway)\r\nCamera System\r\nCloud\r\nContent Filter\r\nDomain/DNS\r\nEmail\r\nEnable(Cisco)\r\nFirewall\r\niLO\r\nKey/Physical Access\r\nMicrosoft365\r\nOther\r\nScanner\r\nSOP\r\nStatus(WatchGuard)\r\nSwitch\r\nSystem\r\nTelnet\r\nVendor\r\nVirtualization\r\nVPN\r\nWeb/FTP\r\nWireless"
      "fields" = @{
          "label" = "IPv4"
          "field_type" = "Heading"
        },@{
          "label" = "Address Type (v4)"
          "field_type" = "Text"
        },@{
          "label" = "IP Address (v4)"
          "field_type" = "Text"
        },@{
          "label" = "Subnet Mask (v4)"
          "field_type" = "Text"
        },@{
          "label" = "Gateway (v4)"
          "field_type" = "Text"
        },@{
          "label" = "IPv6"
          "field_type" = "Heading"
        },@{
          "label" = "IP Address (v6)"
          "field_type" = "Text"
        },@{
          "label" = "Subnet Mask (v6)"
          "field_type" = "Text"
        },@{
          "label" = "Gateway (v6)"
          "field_type" = "Text"
        },@{
          "label" = "VLAN"
          "field_type" = "Number"
        },@{
          "label" = "Info"
          "field_type" = "Heading"
        },@{
          "label" = "Provider"
          "field_type" = "Text"
        },@{
          "label" = "Speed"
          "field_type" = "Text"
        },@{
          "label" = "Account Number"
          "field_type" = "Text"
        },@{
          "label" = "Router"
          "field_type" = "AssetLink"
        },@{
          "label" = "Location"
          "field_type" = "Text"
        },@{
          "label" = "Management URL"
          "field_type" = "Website"
        },@{
          "label" = "Port"
          "field_type" = "Text"
        },@{
          "label" = "Latest Speed Test Result"
          "field_type" = "RichText"
        },@{
          "label" = "Speed Test History"
          "field_type" = "Website"
        },@{
          "label" = "Sync Source"
          "field_type" = "Text"
        }
    }
  },@{
    "asset_layout" = @{
      "name" = "VPNs"
      "icon" = "fas fa-network-wired"
      "color" = "#d710da"
      "icon_color" = "#0f0d0d"
      "active" = "true"
      "include_passwords" = "true"
      "include_comments" = "true"
      "include_files" = "true"
      "password_types" = "Active Directory\r\nApplication\r\nBackup\r\nBank Processor (Gateway)\r\nCamera System\r\nCloud\r\nContent Filter\r\nDomain/DNS\r\nEmail\r\nEnable(Cisco)\r\nFirewall\r\niLO\r\nKey/Physical Access\r\nMicrosoft365\r\nOther\r\nScanner\r\nSOP\r\nStatus(WatchGuard)\r\nSwitch\r\nSystem\r\nTelnet\r\nVendor\r\nVirtualization\r\nVPN\r\nWeb/FTP\r\nWireless"
      "fields" = @{
          "label" = "Location"
          "field_type" = "Text"
        },@{
          "label" = "Remote Endpoint"
          "field_type" = "Text"
        },@{
          "label" = "Local Endpoint"
          "field_type" = "Text"
        },@{
          "label" = "Remote Network(s)"
          "field_type" = "RichText"
        },@{
          "label" = "IKE Version"
          "field_type" = "Text"
        },@{
          "label" = "Encryption"
          "field_type" = "Text"
        },@{
          "label" = "Hash"
          "field_type" = "Text"
        },@{
          "label" = "PFS"
          "field_type" = "CheckBox"
        },@{
          "label" = "VTI?"
          "field_type" = "CheckBox"
        },@{
          "label" = "DH Group (Phase 1)"
          "field_type" = "Text"
        },@{
          "label" = "DH Group (Phase 2)"
          "field_type" = "Text"
        },@{
          "label" = "Description"
          "field_type" = "RichText"
        },@{
          "label" = "Devices Associated"
          "field_type" = "AssetLink"
        },@{
          "label" = "Management URL"
          "field_type" = "Website"
        },@{
          "label" = "Pre-Shared Key"
          "field_type" = "Password"
        },@{
          "label" = "Network ID"
          "field_type" = "Text"
        },@{
          "label" = "Routes"
          "field_type" = "RichText"
        },@{
          "label" = "Rules"
          "field_type" = "RichText"
        },@{
          "label" = "Sync Source"
          "field_type" = "Text"
        }
    }
  },@{
    "asset_layout" = @{
      "name" = "Firewall"
      "icon" = "fas fa-user-shield"
      "color" = "#f21818"
      "icon_color" = "#FFFFFF"
      "active" = "true"
      "include_passwords" = "false"
      "include_comments" = "true"
      "include_files" = "false"
      "password_types" = "Active Directory\r\nApplication\r\nBackup\r\nBank Processor (Gateway)\r\nCamera System\r\nCloud\r\nContent Filter\r\nDomain/DNS\r\nEmail\r\nEnable(Cisco)\r\nFirewall\r\niLO\r\nKey/Physical Access\r\nMicrosoft365\r\nOther\r\nScanner\r\nSOP\r\nStatus(WatchGuard)\r\nSwitch\r\nSystem\r\nTelnet\r\nVendor\r\nVirtualization\r\nVPN\r\nWeb/FTP\r\nWireless"
      "fields" = @{
          "label" = "Port Forwards"
          "field_type" = "RichText"
        },@{
          "label" = "Modules"
          "field_type" = "RichText"
        },@{
          "label" = "Location"
          "field_type" = "Text"
        },@{
          "label" = "Router"
          "field_type" = "AssetLink"
        },@{
          "label" = "Internet Connection"
          "field_type" = "AssetLink"
        },@{
          "label" = "Firewall Rules"
          "field_type" = "RichText"
        },@{
          "label" = "Management URL"
          "field_type" = "Website"
        },@{
          "label" = "Sync Source"
          "field_type" = "Text"
        }
      }
  }
  $Layouts = (Invoke-Restmethod -Uri "$($huduurl)/asset_layouts" -Headers $huduheads).asset_layouts
  foreach ($template in $templates) {
    if ($null -ne ($Layouts | Where-Object {$_.name -eq $template.asset_layout.name})) {
      Write-Host "Layout Exists updating"
      Invoke-Restmethod -Uri "$($huduurl)/asset_layouts/$($_.id)" -Method PUT -Headers $huduheads -Body $($template | ConvertTo-Json -depth 6)
    } else {
      Write-Host "Layout not found, creating."
      Invoke-Restmethod -Uri "$($huduurl)/asset_layouts" -Method POST -Headers $huduheads -Body $($template | ConvertTo-Json -depth 6)
    }
  }
