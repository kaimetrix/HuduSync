function GetBWToken() {
    $body = "grant_type=client_credentials&scope=api.organization&client_id=$($bwcid)&client_secret=$($bwcs)"
    $bwtoken = (Invoke-Restmethod -Uri "https://identity.bitwarden.com/connect/token" -Method POST -ContentType "application/x-www-form-urlencoded" -Body $body).access_token
    $bwheads = @{
        'Authorization' = "Bearer $($bwtoken)"
    }
    return $bwheads;
}

function GetBWCollections() {
    $Collections = (Invoke-Restmethod -Uri "https://api.bitwarden.com/public/collections" -Headers $bwheads)
}