$regex = ‘\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b’

function SearchResult($searchitem) {
    foreach-object { 
        foreach ($property in $_.PSObject.Properties) {
            if ($property.value -like "*$($searchitem)*") {
                $result = $_
            }
        }
    }
    return $result
}