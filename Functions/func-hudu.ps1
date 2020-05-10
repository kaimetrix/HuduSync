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
        $newassets=(Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets?page=$i" -Headers $huduheads).assets
        if ($newassets.count -eq 0) {
            $newassets=((Invoke-Restmethod -UseBasicParsing -Uri "$($huduurl)/companies/$($company.id)/assets?page=$i" -Headers $huduheads) -creplace "CrashPlan","BADCRASHPLAN" | ConvertFrom-Json).assets
        }
        $assets += $newassets
        if ($newassets.count -lt 25) {
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
                #Write-Host "Updating $name"
                (Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets/$($oldassets.id)" -Method PUT -Headers $huduheads -Body $body).data
                #(Invoke-Restmethod -Uri "$($huduurl)/companies/$($company.id)/assets/$($oldassets.id)/unarchive" -Method PUT -Headers $huduheads).data
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
