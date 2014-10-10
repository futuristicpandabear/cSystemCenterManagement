#######################################################################
# ICG_SCOMImportMP DSC Resource
# DSC Resource to import management packs into SCOM 2012
# 201401127 - Joe Thompson, Infront Consulting Group
#######################################################################

function Get-TargetResource
{
	param
    (
       	[ValidateSet("Present", "Absent")]
       	[String] $Ensure = "Present",
       	[parameter(Mandatory)]
       	[String] $MPName,
	    [parameter(Mandatory)]
       	[String] $MPSourcePath
    )

 	$OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"

    If (!($OMReg))
    {
        Throw "Cannot locate Operations Manager PowerShell Module!"
    }
    Else
    {
        $OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
        If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }
    
    	$mp = (Get-SCOMManagementPack -Name $MPName -ErrorAction SilentlyContinue)

    	if ($mp -ne $null)
    	{
        	$returnValue = @{
                    Ensure = $Ensure
	            	MPName = $mp.Name
            		MPSourcePath = $MPSourcePath
        	}
    	}
    	else
    	{
        	$returnValue = @{
                Ensure = $Ensure
            	MPName    = $null
	    		MPSourcePath = $null
            }
        }
    }
	$returnValue
}

function Set-TargetResource
{    
    param
    (
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [parameter(Mandatory)]
        [String] $MPName,

        [parameter(Mandatory)]
        [String] $MPSourcePath
    )

    # Make sure we can get to OperationsManager PS Module
    
    $OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"
    
    If (!($OMReg))
    {
        Throw "Cannot locate Operations Manager PowerShell Module!"
    }
    Else
    {    
        $OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
        If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }

        $mp = (Get-SCOMManagementPack -Name $MPName -ErrorAction SilentlyContinue)

        if ($Ensure -eq 'Present')
        {
            Write-Verbose "Ensure -eq 'Present'"
            if ($mp -eq $null)
            {
                if (Test-Path $MPSourcePath)
                {
                    Write-Verbose -Message "Importing Management Pack $MPName ..."
                    Import-SCOMManagementPack $MPSourcePath
                }
                Else
                {
                    Throw "Unable to import Management Pack from source $MPSourcePath"
                }
            }
        }
        elseif($Ensure -eq 'Absent')
        {
            Write-Verbose "Ensure -eq 'Absent'"
            if ($mp -ne $null)
            {
                Write-Verbose "Management Pack is Present, so removing it: $MPName"
                Get-SCOMManagementPack $MPName -ErrorAction SilentlyContinue | Remove-SCOMManagementPack 
            }
        }
    }
}

function Test-TargetResource
{
    param
    (
        [ValidateSet("Present", "Absent")]
        [String] $Ensure = "Present",

        [parameter(Mandatory)]
        [String] $MPName,

        [parameter(Mandatory)]
        [String] $MPSourcePath
    )

    $returnValue = $true
    
    $OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"

    If (!($OMReg))
    {
        Throw "Cannot find Operations Manager PowerShell module path!"
    }
    Else
    {
        $OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
        If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }

        $mp = (Get-SCOMManagementPack -Name $MPName -ErrorAction SilentlyContinue)

        if ($Ensure -eq 'Present')
        {
            if ($mp -eq $null)
            {
                Write-Verbose -Message "Management pack should exist but it is not installed"
                $returnValue = $false
            }
            else
            {
                Write-Verbose -Message "Management pack is already installed!"
                $returnValue = $true
            }
        }
        elseif($Ensure -eq 'Absent')
        {
            if ($mp -ne $null)
            {
                Write-Verbose -Message "Management pack is installed, but Ensure value -eq $Ensure"
                $returnValue = $false
            }
            else
            {
                Write-Verbose -Message "Management pack is not installed which matches Ensure value"
                $returnValue = $true
            }
        }

        if (Test-Path $MPSourcePath)
        {
            Write-Verbose -Message "Source management pack files exist for comparison!"
            #$returnValue = $true
        }
        Else
        {
            Write-Verbose -Message "Cannot find source management pack files for comparison at $MPSourcePath !"
            #$returnValue = $false
        }
    }

    $returnValue;
}



