# Start of Settings 
# End of Settings

# Import Default 3Par PS Modules
Import-Module "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\HP3PARPSToolkit\Logger.psm1"
Import-Module "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\HP3PARPSToolkit\VS-Functions.psm1"

########################################################################################################
## FUNCTION Get-3parSpace
########################################################################################################
Function Get-3parSpace
{
<#
  .SYNOPSIS
    Get 3PAR physical Space
  
  .DESCRIPTION
    Get 3PAR physical Space
        
  .EXAMPLE
    Get-3parSpace
	Get All 3PAR physical Space

  .EXAMPLE	
    Get-3parSpace -devtype FC
	Get All FC 3PAR physical Space

  .PARAMETER -devtype FC 
    Specify the Disk Type 
	(FC | SSD | NL). 	

  .PARAMETER SANConnection 
    Specify the SAN Connection object created with new-SANConnection
	
  .Notes
    NAME:  Get-3parSpace
    LASTEDIT: 02/16/2016
    VERSION: 1.0
    KEYWORDS: Get-3parSpace
   
  .Link
     https://mycloudrevolution.wordpress.com/
 
 #Requires PS -Version 2.0

 #>
[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$false)]
		[System.String]
		$devtype,
	
		[Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)]
        $SANConnection = $global:SANConnection 
       
	)		
	
	Write-DebugLog "Start: In Get-3parSpace - validating input values" $Debug 

	#check if connection object contents are null/empty
	if(!$SANConnection)
	{	
			
		#check if connection object contents are null/empty
		$Validate1 = Test-ConnectionObject $SANConnection
		if($Validate1 -eq "Failed")
		{
			#check if global connection object contents are null/empty
			$Validate2 = Test-ConnectionObject $global:SANConnection
			if($Validate2 -eq "Failed")
			{
				Write-DebugLog "Connection object is null/empty or Connection object username,password,IPAaddress are null/empty. Create a valid connection object using New-SANConnection" "ERR:"
				Write-DebugLog "Stop: Exiting Get-3parSpaceList since SAN connection object values are null/empty" $Debug
				return "FAILURE : Exiting Get-3parSpaceList since SAN connection object values are null/empty"
			}
		}
	}
	$plinkresult1 = Test-Plink

	if(($plinkresult1 -match "FAILURE :"))
	{
		write-debuglog "$plinkresult1" "ERR:" 
		return $plinkresult1
	}
	$GetSpaceCmd = "showsys -space"


	if ($devtype)
	{
		$GetSpaceCmd += " -devtype $devtype"
	}
	

	$Result = invoke-plinkcmd -Connection $SANConnection -cmds  $GetSpaceCmd
	write-debuglog "Get physical space" "INFO:" 
	
	$tempFile = [IO.Path]::GetTempFileName()
	
	if ( $Result.Count -gt 1)
	{
		$tempFile = [IO.Path]::GetTempFileName()
		$LastItem = $Result.Count -3  
		foreach ($s in  $Result[0..$LastItem] )
		{
            $s= [regex]::Replace($s,"  +","")
            $s= [regex]::Replace($s,":",",")
            $s= [regex]::Replace($s,"-+","")
            $s= [regex]::Replace($s," Syste","Type")
            $s= [regex]::Replace($s,"m ",",")
            $s= [regex]::Replace($s,"Capacity Efficiency","")
           
			Add-Content -Path $tempfile -Value $s
		}
		
		
		$Values = Import-Csv $tempFile
        $Details = New-object PSObject
        if ($devtype) { 
            $Details | Add-Member -Name "Device Type" -Value $devtype -Membertype NoteProperty 
            }
        else {
            $Details | Add-Member -Name "Device Type" -Value "Global" -Membertype NoteProperty 
            }


        foreach ($Value in $Values) {
            if ($Value.Type -eq "Total Capacity"){
                $Details | Add-Member -Name "Total Capacity (MB)" -Value $Value."Capacity (MB) " -Membertype NoteProperty
                }
            if ($Value.Type -eq "Volumes"){
                $Details | Add-Member -Name "Volumes Used (MB)" -Value $Value."Capacity (MB) " -Membertype NoteProperty
                }
            if ($Value.Type -eq "System"){
                $Details | Add-Member -Name "System Used (MB)" -Value $Value."Capacity (MB) " -Membertype NoteProperty
                }
            if ($Value.Type -eq "Free"){
                $Details | Add-Member -Name "Free Capacity (MB)" -Value $Value."Capacity (MB) " -Membertype NoteProperty
                }
            }
       $Details
		
		del $tempFile
	}	
	else
	{
		Write-DebugLog $result "INFO:"
		return "FAILURE : No Capacity Output found"
	}
	

} # END Get-3parSpace

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

$MyCollection4

$Title = "3Par physical Disk Usage"
$Header = "3Par physical Disk Usage"
$Comments = "Usage hy Device Type."
$Display = "Table"
$Author = "Markus Kraus"
$PluginVersion = 1.0
$PluginCategory = "vSphere"
