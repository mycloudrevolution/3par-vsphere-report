# Start of Settings 
# Show also empty (no VVs) 3PAR CPGs?
$ShowAll = $false
# End of Settings

$MyCollection3 =  New-Object System.Collections.ArrayList

if ($ShowAll -eq $false){
	$CPGs = Get-3parCPG | Where {$_.VVs -gt 0 } | Sort Name
	}
	Else {
	$CPGs = Get-3parCPG |  Sort Name
	}

ForEach ($CPG in $CPGs){
    $CPGTotal = New-object PSObject
    $CPGTotal | Add-Member -Name CPG-Name -Value $CPG.Name -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-VVs -Value $CPG.VVs -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UserSpaceGB -Value ([math]::Round(($CPG."Usr_ Total(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UserSpaceUsedGB -Value ([math]::Round(($CPG."User_Used(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-SnapSpaceGB -Value ([math]::Round(($CPG."snp_Total(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-SnapSpaceUsedGB -Value ([math]::Round(($CPG."snp_Used(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-AdminSpaceGB -Value ([math]::Round(($CPG."Adm_Total(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-AdminSpaceUsedGB -Value ([math]::Round(($CPG."Adm_Used(MB)" / 1024),2)) -Membertype NoteProperty
    $MyCollection3 += $CPGTotal
}

$MyCollection3

$Title = "3Par Total CPG Space allocation"
$Header = "3Par Total CPG Space allocation"
$Comments = "Only CPGs with VVs are listed."
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.2
$PluginCategory = "vSphere"
