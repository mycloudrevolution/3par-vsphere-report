#############################################################################  
# 3Par Reporting 
# Written by Markus Kraus
# Version 1.2 
#  
# https://mycloudrevolution.wordpress.com/ 
#  
# Changelog:  
# 2016.01 ver 1.0 Base Release  
# 2016.02 ver 1.1 Added more CPG Details / Changed VV Space Calculation 
# 2016.02 ver 1.2 Added phiscal Disk Calculation 
#  
#  
##############################################################################  

## Preparation
# Import Modules
Import-Module "C:\Scripts\Functions\get-3parSpace.ps1"

# Load SnapIn
if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	add-pssnapin VMware.VimAutomation.Core
}

# Global Definitions
$MyCollection =  New-Object System.Collections.ArrayList
$MyCollection2 =  New-Object System.Collections.ArrayList
$MyCollection3 =  New-Object System.Collections.ArrayList
$CapacityGB_SUM = 0
$UsedGB_SUM = 0
$AdminGB_SUM  = 0
$UserGB_SUM = 0
$3ParArray = "MyArrayIP"
$ViServer = "MyvCenter"

# Start vCenter Connection
Write-Host "Starting to Process vCenter Connection to " $VIServer " ..."-ForegroundColor Magenta
$OpenConnection = $global:DefaultVIServers | where { $_.Name -eq $VIServer }
if($OpenConnection.IsConnected) {
	Write-Host "vCenter is Already Connected..." -ForegroundColor Yellow
	$VIConnection = $OpenConnection
} else {
	Write-Host "Connecting vCenter..."
	$VIConnection = Connect-VIServer -Server $VIServer
}

if (-not $VIConnection.IsConnected) {
	Write-Error "Error: vCenter Connection Failed"
    Exit
}
# End vCenter Connection

# Connect to 3Par
Write-Host "Starting to Process 3Par Connection to " $3ParArray " ..."-ForegroundColor Magenta
$SANConnection = New-SANConnection -SANIPAddress $3ParArray -SANUserName 3paradm

If (($SANConnection).GetType().Name -ne "_SANConnection"){
    Write-Error "SANConnError - Unable to Connect to 3PAR System"
    }

Write-Host "Starting to Process all vSphere Datastores..." -ForegroundColor Magenta
$Datastores = Get-Datastore | Where {$_.Name -notlike "*local*"}
$OutputDatastoresUnsorted = @($Datastores | Select-Object Name, Type, @{N="CapacityGB";E={[math]::Round($_.CapacityGB,2)}}, @{N="FreeSpaceGB";E={[math]::Round($_.FreeSpaceGB,2)}}, @{N="UsedSpaceGB";E={[math]::Round($_.CapacityGB - $_.FreeSpaceGB,2)}})
$OutputDatastores = $OutputDatastoresUnsorted | Select *, @{N="NumCPGs";E={@((Get-3parVV -vvName $_.Name).count)}} | Sort-Object -Descending NumCPGs, Name

Write-Host "Starting to Match all 3Par VVs to Datastores..." -ForegroundColor Magenta
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
Write-Host "Total Capacity per Datastore:" -ForegroundColor Yellow
$MyCollection | ft -AutoSize

Write-Host "Starting to calculate Total 3PAR VV Usage..." -ForegroundColor Magenta
$Summary = New-object PSObject
$Summary | Add-Member -Name vSphere-ProvCapacityGB -Value ([math]::Round($CapacityGB_SUM ,2)) -Membertype NoteProperty
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
Write-Host "Total Capacity on Array:" -ForegroundColor Yellow
$MyCollection2 | ft -AutoSize

Write-Host "Starting to calculate Total 3PAR CPG Usage..." -ForegroundColor Magenta
$CPGs = Get-3parCPG | Where {$_.VVs -gt 0 } | Sort Name
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
$MyCollection3 | ft -AutoSize

Write-Host "Starting to calculate Total 3PAR physical Disk Usage..." -ForegroundColor Magenta
$DiskTypes = New-Object System.Collections.ArrayList
$MyCollection4 =  New-Object System.Collections.ArrayList
$DiskTypes = @("FC","NL","SSD")
ForEach ($DiskType in $DiskTypes){
    $Space = Get-3parSpace -devtype $DiskType
    $TotalUsedMB = 0
    $Total = New-object PSObject
    $Total | Add-Member -Name "Device Type" -Value $Space."Device Type" -Membertype NoteProperty
    $Total | Add-Member -Name "Total Capacity (GB)" -Value ([math]::Round(($Space."Total Capacity (MB)" / 1024),2))  -Membertype NoteProperty
    $Total | Add-Member -Name "System Used (GB)" -Value ([math]::Round(($Space."System Used (MB)" / 1024),2))  -Membertype NoteProperty
    $Total | Add-Member -Name "Volumes Used (GB)" -Value ([math]::Round(($Space."Volumes Used (MB)" / 1024),2))  -Membertype NoteProperty
    $TotalUsedGB = [math]::Round((([int]$Space."System Used (MB)" + [int]$Space."Volumes Used (MB)") / 1024),2)
    $Total | Add-Member -Name "Total Used (GB)" -Value $TotalUsedGB -Membertype NoteProperty
    $Total | Add-Member -Name "Free Capacity (GB)" -Value ([math]::Round(($Space."Free Capacity (MB)" / 1024),2))  -Membertype NoteProperty
    $Percentage = [Math]::round((($TotalUsedGB / ($Space."Total Capacity (MB)" / 1024)) * 100),2)
    $Total | Add-Member -Name "Percent Used" -Value $Percentage -Membertype NoteProperty
    $MyCollection4 += $Total
}
$MyCollection4 | ft -AutoSize