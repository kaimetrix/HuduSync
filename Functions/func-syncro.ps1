function GetCompany() {
    $results = ((Invoke-Restmethod -Uri "$($syncrourl)/search?api_key=$($syncrokey)&query=$($call.external_number -replace '(\+1)','')" -ContentType "application/json").results)
        if ($results.count -ne 0) {
            $result = ($results | Where-Object { $_.table._type -eq "customer" } | Select-Object -First 1)
            if ($result.count -eq 0) {
                $result = ($results | Where-Object { $_.table._type -eq "contact" } | Select-Object -First 1)
                $Company = ($Companies | Where-Object { $_.name -match $($result.table._source.table.business_name) })
            } else {
                $Company = ($Companies | Where-Object { $_.name -match $($result.table._source.table.business_name) })
            }
        } else {
           $Company = $null
        } 
    return $Company
}

function GetContact() {
    $results = ((Invoke-Restmethod -Uri "$($syncrourl)/search?api_key=$($syncrokey)&query=$($call.external_number -replace '(\+1)','')" -ContentType "application/json").results)
        if ($results.count -ne 0) {
            $result = ($results | Where-Object { $_.table._type -eq "contact" } | Select-Object -First 1)
            if ($result.count -eq 0) {
                $result = ($results | Where-Object { $_.table._type -eq "customer" } | Select-Object -First 1)
                $contact = "$($results[0].table._source.table.business_name)"
            } else {
                $contact = "$($results[0].table._source.table.firstname) $($result.table._source.table.lastname)"
            }
        } else {
            $contact = $null
        }
    return $contact
}
