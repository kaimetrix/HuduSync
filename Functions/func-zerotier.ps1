function GetZTNets() {
    $ztnets=(Invoke-Restmethod -Uri "$zerotierurl/network" -Headers $zerotierheads)
    return $ztnets
    }
