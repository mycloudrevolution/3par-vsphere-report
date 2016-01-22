$MyCollection3 =  New-Object System.Collections.ArrayList

$CPGs = Get-3parCPG | Where {$_.VVs -gt 0 } | Sort Name
ForEach ($CPG in $CPGs){
    $CPGTotal = New-object PSObject
    $CPGTotal | Add-Member -Name CPG-Name -Value $CPG.Name -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-VVs -Value $CPG.VVs -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UserSpaceGB -Value ([math]::Round(($CPG."Usr_ Total(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UsedSpaceGB -Value ([math]::Round(($CPG."User_Used(MB)" / 1024),2)) -Membertype NoteProperty
    $MyCollection3 += $CPGTotal
}

$MyCollection3


$Title = "3Par Total CPG Space allocation"
$Header = "3Par Total CPG Space allocation"
$Comments = "Only CPGs with VVs are listed."
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.0
$PluginCategory = "vSphere"
