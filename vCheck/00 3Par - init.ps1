$3ParArray = "myArray"
$3ParUser = "3paradm"
$3ParPassword = "Passw0rd!"

# Connect to 3Par
$trash = New-SANConnection -SANIPAddress $3ParArray -SANUserName $3ParUser -SANPassword $3ParPassword

$Title = "3Par Enviroment Init"
$Header = "3Par Enviroment Init"
$Comments = "3Par Enviroment Init"
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.0
$PluginCategory = "vSphere"