# Start of Settings 
# Do not report on any Datastores that are defined here (3PAR VVs Report Plugin)
$DatastoreIgnore = "local"
# End of Settings

$MyCollection =  New-Object System.Collections.ArrayList
$CapacityGB_SUM = 0
$UsedGB_SUM = 0
$AdminGB_SUM  = 0
$UserGB_SUM = 0


if ($DatastoreIgnore){
    $OutputDatastoresUnsorted = @($Datastores | Where-Object {$_.Name -notmatch $DatastoreIgnore} | Select-Object Name, Type, @{N="CapacityGB";E={[math]::Round($_.CapacityGB,2)}}, @{N="FreeSpaceGB";E={[math]::Round($_.FreeSpaceGB,2)}}, @{N="UsedSpaceGB";E={[math]::Round($_.CapacityGB - $_.FreeSpaceGB,2)}})
}
else {
    $OutputDatastoresUnsorted = @($Datastores | Select-Object Name, Type, @{N="CapacityGB";E={[math]::Round($_.CapacityGB,2)}}, @{N="FreeSpaceGB";E={[math]::Round($_.FreeSpaceGB,2)}}, @{N="UsedSpaceGB";E={[math]::Round($_.CapacityGB - $_.FreeSpaceGB,2)}})
}

$OutputDatastores = $OutputDatastoresUnsorted | Select *, @{N="NumCPGs";E={@((Get-3parVV -vvName $_.Name).count)}} | Sort-Object -Descending NumCPGs, Name

ForEach ($OutputDatastore in $OutputDatastores){
  $Details = New-object PSObject
  $Details | Add-Member -Name Name -Value $OutputDatastore.name -Membertype NoteProperty
  $Details | Add-Member -Name vSphere-ProvisionedCapacityGB -Value $OutputDatastore.CapacityGB -Membertype NoteProperty
  $Details | Add-Member -Name vSphere-UsedSpaceGB -Value $OutputDatastore.UsedSpaceGB -Membertype NoteProperty
  $Percentage = [Math]::round((($OutputDatastore.UsedSpaceGB / $OutputDatastore.CapacityGB) * 100),2)
  $Details | Add-Member -Name vSphere-PercentUsed -Value $Percentage -Membertype NoteProperty
  $VVUsrTotal = [Math]::round(((get-3parVVList -vvName $OutputDatastore.Name).Usr / 1024),2)
  $VVAdmTotal = [Math]::round(((get-3parVVList -vvName $OutputDatastore.Name).Adm / 1024),2)
  $Details | Add-Member -Name 3PAR-Total-UserSpaceGB -Value $VVUsrTotal -Membertype NoteProperty
  $Details | Add-Member -Name 3PAR-Total-AdminSpaceGB -Value $VVAdmTotal -Membertype NoteProperty
  $VVnum = 0
  $VVs = Get-3parVV -vvName $OutputDatastore.Name
  ForEach ($VV in $VVs){
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-CPG -Value $VV.CPG -Membertype NoteProperty
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-UserSpaceGB -Value ([math]::Round(($VV."Usr(MB)" / 1024),2)) -Membertype NoteProperty
    $Percentage = [Math]::round(((([math]::Round($VV."Usr(MB)" / 1024) / $OutputDatastore.CapacityGB) * 100)),2)
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-PercentUsed -Value $Percentage -Membertype NoteProperty
    $VVnum++
    }
  $MyCollection += $Details
  $CapacityGB_SUM += $OutputDatastore.CapacityGB
  $UsedGB_SUM += $OutputDatastore.UsedSpaceGB
  $UserGB_SUM += $VVUsrTotal
  $AdminGB_SUM += $VVAdmTotal
}

$MyCollection

$Title = "3Par VVs to vSphere Datastores Collection"
$Header = "3Par VVs to vSphere Datastores"
$Comments = "All PercentUsed is Realted to vSphere ProvisionedCapacityGB."
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.2
$PluginCategory = "vSphere"
