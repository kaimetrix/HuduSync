function GetVoicemailLink() {
    return "Voicemail Link"
}

function GetCallTranscript() {
    $incomingtranscript = Invoke-Restmethod -Uri "https://dialpad.com/api/v2/transcripts/$($call.call_id)?apikey=$($dialpadkey)" -ContentType "application/json"
    $transcript = New-Object System.Collections.Generic.List[System.Object]

    foreach ($line in $incomingtranscript.lines) {
        $transcript += "$($line.name) : $($line.content)<br>"
    }
    return "$transcript"
}
