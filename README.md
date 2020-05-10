"# HuduSync"<br>
In order to run these you'll need a secrets file Under a ./Secrets/Secrets.ps1 directory.<br>
As of now you'll need to define these:<br>

\[string\]$controller = "https://unifiurl:8443"<br>
\[string\]$credential = "\`{\`"username\`":\`"unifiusername\`",\`"password\`":\`"unifipassword\`"\`}"<br>

[string]$huduurl = "https://huduurl/api/v1"<br>
$huduheads = @\{<br>
    'x-api-key' = 'apikey'<br>
    'Content-Type' = 'application/json'<br>
    \}<br>
