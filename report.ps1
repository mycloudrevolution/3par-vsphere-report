## Preparation
# Load SnapIn
if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	add-pssnapin VMware.VimAutomation.Core
}

$MyCollection =  New-Object System.Collections.ArrayList
$MyCollection2 =  New-Object System.Collections.ArrayList
$MyCollection3 =  New-Object System.Collections.ArrayList
$CapacityGB_SUM = 0
$UsedGB_SUM = 0
$AdminGB_SUM  = 0
$UserGB_SUM = 0
$3ParArray = "myArray"
$vCenter = "myvCenter"

# Connect to VBC vCenter
$trash = Connect-VIServer $vCenter

# Connect to 3Par
$trash = New-SANConnection -SANIPAddress $3ParArray -SANUserName 3paradm

$Datastores = Get-Datastore | Where {$_.Name -notlike "*local*" -and $_.Name -notlike "*s54esx01*"}

$OutputDatastoresUnsorted = @($Datastores | Select-Object Name, Type, @{N="CapacityGB";E={[math]::Round($_.CapacityGB,2)}}, @{N="FreeSpaceGB";E={[math]::Round($_.FreeSpaceGB,2)}}, @{N="UsedSpaceGB";E={[math]::Round($_.CapacityGB - $_.FreeSpaceGB,2)}})

$OutputDatastores = $OutputDatastoresUnsorted | Select *, @{N="NumCPGs";E={@((Get-3parVV -vvName $_.Name).count)}} | Sort-Object -Descending NumCPGs, Name

ForEach ($OutputDatastore in $OutputDatastores){
  $Details = New-object PSObject
  $Details | Add-Member -Name Name -Value $OutputDatastore.name -Membertype NoteProperty
  $Details | Add-Member -Name vSphere-ProvisionedCapacityGB -Value $OutputDatastore.CapacityGB -Membertype NoteProperty
  $Details | Add-Member -Name vSphere-UsedSpaceGB -Value $OutputDatastore.UsedSpaceGB -Membertype NoteProperty
  $Percentage = [Math]::round((($OutputDatastore.UsedSpaceGB / $OutputDatastore.CapacityGB) * 100),2)
  $Details | Add-Member -Name vSphere-PercentUsed -Value $Percentage -Membertype NoteProperty
  $VVnum = 0
  $VVs = Get-3parVV -vvName $OutputDatastore.Name
  ForEach ($VV in $VVs){
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-CPG -Value $VV.CPG -Membertype NoteProperty
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-UserSpaceGB -Value ([math]::Round(($VV."Usr(MB)" / 1024),2)) -Membertype NoteProperty
    $Percentage = [Math]::round(((([math]::Round($VV."Usr(MB)" / 1024) / $OutputDatastore.CapacityGB) * 100)),2)
    $Details | Add-Member -Name 3PAR-VV$($VVnum)-PercentUsed -Value $Percentage -Membertype NoteProperty
    $UserGB_SUM += [math]::Round(($VV."Usr(MB)" / 1024),2)
    $AdminGB_SUM += [math]::Round(($VV."Adm(MB)" / 1024),2)
    $VVnum++
    }
  $MyCollection += $Details
  $CapacityGB_SUM += $OutputDatastore.CapacityGB
  $UsedGB_SUM += $OutputDatastore.UsedSpaceGB
}
Write-Host "Total Capacity per Datastore:" -ForegroundColor Yellow
$MyCollection | ft -AutoSize

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
$Summary | Add-Member -Name 3PAR-TotalPercentUsed -Value $Percentage -Membertype NoteProperty
$MyCollection2 += $Summary
Write-Host "Total Capacity on Array:" -ForegroundColor Yellow
$MyCollection2 | ft -AutoSize

Write-Host "Total Capacity per CPG:" -ForegroundColor Yellow
$CPGs = Get-3parCPG | Where {$_.VVs -gt 0 } | Sort Name
ForEach ($CPG in $CPGs){
    $CPGTotal = New-object PSObject
    $CPGTotal | Add-Member -Name CPG-Name -Value $CPG.Name -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-VVs -Value $CPG.VVs -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UserSpaceGB -Value ([math]::Round(($CPG."Usr_ Total(MB)" / 1024),2)) -Membertype NoteProperty
    $CPGTotal | Add-Member -Name CPG-UsedSpaceGB -Value ([math]::Round(($CPG."User_Used(MB)" / 1024),2)) -Membertype NoteProperty
    $MyCollection3 += $CPGTotal
}
$MyCollection3 | ft -AutoSize