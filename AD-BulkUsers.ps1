<#
    .SYNOPSIS
    Simple script that can be used to create bulk Active Directory accounts. I find this helpful for testing Active Directory management in my labs.

    .DESCRIPTION



    .PARAMETER 

    .EXAMPLE

 
    .NOTES
    Created by: KaijuLogic
    Contact Info: 
    Created Date: 05.07.2025
    Last Modified Date: 06.02.2025
    Last Modified By: KaijuLogic
    Contact Info: 
    Version: 1.0


    .DISCLAIMER
    By using this content you agree to the following: This script may be used for legal purposes only. Users take full responsibility 
    for any actions performed using this script. The author accepts no liability for any damage caused by this script.  

       
#>

####################### SCRIPT PARAMETERS #######################
[CmdletBinding(SupportsShouldProcess)]
Param(
	[Parameter(Mandatory=$False)]
	[String]$givennames = "$PSScriptRoot\given-names.txt",

	[Parameter(Mandatory=$False)]
	[String]$familynames = "$PSScriptRoot/family-names.txt",

    [Parameter(Mandatory=$False)]
	[String]$roles = "$PSScriptRoot/roles.txt",

    [Parameter(Mandatory=$False)]
	[String]$DestinationOUList = "$PSScriptRoot/Dest-OUs.txt",

    [Parameter(Mandatory=$False)]
	[String]$DepartmentList = "$PSScriptRoot/DepartmentList.txt",

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 100)]
	[Int]$UserCount = 10
)
################################## Import Modules #################################

try{
	Import-Module ActiveDirectory
}
catch{
	Throw "Failed to import ActiveDirectory module, are you sure this is running on a system with AD or RSAT tools installed."
}

#################################### SET COMMON VARIABLES ###################################
$CurrentDate = Get-Date
$CurrentPath = split-path -Parent $PSCommandPath

# Establish our paths for log creation and results
$LogDateDir = $CurrentDate.ToString("yyyy-MM")
$LogFileNameTime = $CurrentDate.ToString("yyyy-MM-dd_HH.mm.ss")
$RunLogDir = Join-Path -Path $CurrentPath -ChildPath "BulkUsersLogs\RunLogs\$LogDateDir"
$RunLogOutput = Join-Path -Path $RunLogDir -ChildPath "BulkUsers_RunLog_$LogFileNameTime.txt"

#Used to trasck how long the script took to process
$sw = [Diagnostics.Stopwatch]::StartNew()

#################################### FUNCTIONS #######################################
#Function to create folders and path if they do not already exist to allow for logs to be created. 
Function Set-NewFolder{
    param(
        [Parameter(Mandatory=$true)]
        [string[]] $FolderPaths
    )
    ##Tests for and creates necessary folders and files for the script to run and log appropriatel
	foreach ($Path in $FolderPaths){
	    if (!(Test-Path $Path)){
	        Write-Verbose "$Path does not exist, creating path"
	        Try{
	            New-Item -Path $Path -ItemType "directory" | out-null
	        }
	        Catch{
	            Throw "Error creating path: $Path. Error provided: $($_.ErrorDetails.Message)"
	        }
        }
	}
}

Function Write-Log{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info","WARN","ERROR","FATAL","DEBUG")]
        [string]$level = "INFO",

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$logfile
    )

    $Stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    $Line = "$Stamp | $Level | $Message"
    
    #To make our cli output look ~pretty~
    $ColorDitcionary = @{"INFO" = "Cyan"; "WARN" = "Yellow"; "ERROR" = "Red"}
    Write-Host $Line -ForegroundColor $ColorDitcionary[$Level]

    Add-content $logfile -Value $Line -Force
}

Function Get-RandomPassword{
    param(
        [int]$Length = 16
    )
    #Create the character pool
    $uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $lowercase = "abcdefghijklmnopqrstuvwxyz"
    $numbers = "0123456789"
    $specialChars = "!@#$%^&*()_+-=[]{}|;:,.<>?"

    if ($Length -le 0) {
        throw "Password length must be greater than 0"
    }
    
    $chars = $uppercase + $lowercase + $numbers + $specialChars
    $password = ""
    $i = 0
    while ($i -lt $Length) {
        $randomIndex = Get-Random -Minimum 0 -Maximum $chars.Length
        $password += $chars[$randomIndex]
        $i++
    }
    
    return $password

}

Function Start-BulkUsersCreation{
    $RandomPassword = get-RandomPassword
    $UserFirstName = $FirstList | Get-Random
    $UserLastName = $LastList | Get-Random
    $UserName = $UserFirstName + '.' + $UserLastName
    $UserRole = $RolesList| get-random
    $Department = $DepList | Get-Random
    $DestinationOU = $OUList | Get-Random


    $UserParams = @{
        SamAccountName = $UserName
        UserPrincipalName = "$Username@$($DomainInfo.DNSRoot)"
        Name = "$UserFirstName $UserLastName" 
        GivenName = $UserFirstName
        Surname = $UserLastName 
        Enabled = $True 
        Description = "User created with AD-BulkUser Script $($CurrentDate.ToString("yyyy-MM-dd"))" 
        DisplayName = "$UserFirstName $UserLastName"
        Department = $Department 
        Path = $DestinationOU
        AccountPassword = (convertto-securestring $RandomPassword -AsPlainText -Force)
        ChangePasswordAtLogon = $True  
    }
    try{
        New-ADUser @UserParams
        add-adgroupmember -Identity $UserRole -members $UserName
        write-log -level INFO -Message "[$UserFirstName $UserLastName] created in $DestinationOU, with the role $UserRole" -logfile $RunLogOutput
    }
    Catch{
        write-log -level ERROR -Message "Something went wrong $_" -logfile $RunLogOutput
    }
}



#################################### EXECUTION #######################################
Set-NewFolder $RunLogDir
 Try{
    $FirstList = Get-Content $givennames -ErrorAction Stop
    $LastList = Get-Content $familynames -ErrorAction Stop
    $RolesList = Get-Content $roles -ErrorAction Stop
    $OUList = Get-Content $DestinationOUList -ErrorAction Stop
    $DepList = Get-Content $DepartmentList -ErrorAction Stop
    $DomainInfo = Get-ADDomain -ErrorAction Stop
 }
 catch{
    write-log -level ERROR -Message "Something went wrong reading a file $_" -logfile $RunLogOutput
    Throw "Something went wrong reading a file $_"
 }


$UCount = 1

While($UCount -le $UserCount){
    Start-BulkUsersCreation
    $UCount++
}