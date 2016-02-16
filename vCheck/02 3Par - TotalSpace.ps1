# Start of Settings 
# End of Settings
$MyCollection2 =  New-Object System.Collections.ArrayList

$Summary = New-object PSObject
$Summary | Add-Member -Name vSphere-ProvisionedCapacityGB -Value ([math]::Round($CapacityGB_SUM ,2)) -Membertype NoteProperty
$Summary | Add-Member -Name vSphere-UsedSpaceGB -Value ([math]::Round($UsedGB_SUM ,2)) -Membertype NoteProperty
$Summary | Add-Member -Name 3PAR-UserSpaceGB -Value ([math]::Round($UserGB_SUM,2)) -Membertype NoteProperty
$Summary | Add-Member -Name 3PAR-AdminSpaceGB -Value ([math]::Round($AdminGB_SUM,2)) -Membertype NoteProperty
$3ParTotal = [Math]::round($UserGB_SUM + $AdminGB_SUM,2)
$Summary | Add-Member -Name 3PAR-TotalSpaceGB -Value $3ParTotal -Membertype NoteProperty
$Percentage = [Math]::round((($UsedGB_SUM/$CapacityGB_SUM) * 100),2)
$Summary | Add-Member -Name vSphere-PercentUsed -Value $Percentage -Membertype NoteProperty
$Percentage = [Math]::round((($3ParTotal/$CapacityGB_SUM) * 100),2)
$Summary | Add-Member -Name 3PAR-PercentUsed -Value $Percentage -Membertype NoteProperty
$MyCollection2 += $Summary

$MyCollection2

$Title = "3Par Total vSphere Space allocation"
$Header = "3Par Total vSphere Space allocation"
$Comments = "All PercentUsed is Realted to vSphere ProvisionedCapacityGB."
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.2
$PluginCategory = "vSphere"