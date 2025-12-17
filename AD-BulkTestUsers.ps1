<#
    .SYNOPSIS
    Simple script that can be used to create bulk Active Directory accounts. I find this helpful for testing Active Directory management in my labs.

    .DESCRIPTION
    This PowerShell script automates the creation of bulk test user accounts within an Active Directory lab environment.
    It generates users with random attributes selected from provided lists, including first and last names, Organizational Units (OUs),
    security groups, and departments.

    Several files are provided:
    - given-names.txt :  A list of 300 given (first) names.
    - family-names.txt : A list of 300 family (last) names.
    - roles.txt : A list of existing Security Groups to add users to.
    - Dest-OUs.txt : List of target Distinguished Names for OUs (e.g., OU=TestUsers,DC=testnet,DC=lab).
    - DepartmentList.txt : A list of department names.

    The script is intended strictly for testing and lab environments to simulate user population and management. PLEASE DO NOT USE THIS IN A LIVE ENVIRONMENT

    .PARAMETER givennames
    Provide a path to a list of given names you would like to use. If no list is given the default list provided (given-names.txt) will be used.

    .PARAMETER familynames
    Provide a path to a list of family names you would like to use. If no list is given the default list provided (family-names.txt) will be used.

    .PARAMETER roles
    Provide a path to a list of roles you want to be randomly assigned to test users. If no list is given the default list provided (roles.txt) will be used.

    .PARAMETER DestinationOUList
    Provide a path to a list of AD OUs you want test users to be randomly created in. If no list is given the default list provided (Dest-OUs.txt) will be used.

    .PARAMETER DepartmentList
    Provide a path to a list of Departments you want test users to be randomly assigned to. If no list is given the default list provided (DepartmentList.txt) will be used.

    .PARAMETER UserCount
    Provide a number of users to create between 1-100. The default is 10

    .EXAMPLE
    AD-BulkTestUsers.ps1

    This would use all the default settings
        - It will automatically target the file names defined within the folder the script is run in.
        - Create 10 users

    .EXAMPLE
    AD-BulkTestUsers.ps1 -usercount 100

    This would use the default files and create 100 users
        - It will automatically target the file names defined within the folder the script is run in.

    .EXAMPLE
    AD-BulkTestUsers.ps1 -usercount 100 -DestinationOUList C:\Script\Your-OU-List.txt -roles C:\Script\Your-roles-List.txt

    This would use the default Given and family names, default department names and create 100 users
        - The script with gather the roles and destination OUs from the provided paths.

    .NOTES
        Created by: KaijuLogic
        Created Date: 15.12.2025
        Last Modified Date: 15.12.2025
        Last Modified By: KaijuLogic
        Repository URL:   https://github.com/KaijuLogic/AD_BulkTestUsers

    REQUIREMENTS
    * Active Directory PowerShell Module (RSAT)
    * User account with permissions to create AD Users and modify Groups

    CHANGE LOG
    Initial commit

    TO-DO:
        - Randomly pick how many security groups a user should be added to

    .DISCLAIMER
    This script is provided for educational and testing purposes only and may be used for legal purposes only.
    The user assumes full responsibility for any actions performed using this script. The author accepts no liability for any damage caused to production environments or data.
#>

####################### SCRIPT PARAMETERS #######################
[CmdletBinding(SupportsShouldProcess)]
Param(
	[Parameter(Mandatory=$False)]
	[String]$GivenNames = ".\Resources\given-names.txt",

	[Parameter(Mandatory=$False)]
	[String]$FamilyNames = ".\Resources\family-names.txt",

    [Parameter(Mandatory=$False)]
	[String]$Roles = ".\Resources\roles.txt",

    [Parameter(Mandatory=$False)]
	[String]$DestinationOUList = ".\Resources\Dest-OUs.txt",

    [Parameter(Mandatory=$False)]
	[String]$DepartmentList = ".\Resources\DepartmentList.txt",

    [Parameter(Mandatory=$False)]
	[String]$Domaininfo,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 100)]
	[Int]$UserCount = 10
)
################################## Import Modules #################################
try{
	Import-Module ActiveDirectory -ErrorAction Stop
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
    [CmdletBinding(SupportsShouldProcess=$True)]
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

Function Write-ScriptLog{
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
    #To make our cli output look pretty
    $ColorDitcionary = @{
        "INFO" = "Cyan";
        "WARN" = "Yellow";
        "ERROR" = "Red"
    }

    Write-Host $Line -ForegroundColor $ColorDitcionary[$Level]

    Add-content $logfile -Value $Line -Force
}

Function Get-RandomPassword{
    #Please note that this (using get-random)is not a cryptographically secure way to generate a password.
    #As mentioned before, please only use this for lab type settings.
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
    [CmdletBinding(SupportsShouldProcess=$True)]
    param()
    $RandomPassword = get-RandomPassword
    $UserFirstName = $FirstList | Get-Random
    $UserLastName = $LastList | Get-Random
    $UserName = "$UserFirstName.$UserLastName"
    $UserRole = $RolesList| get-random
    $Department = $DepList | Get-Random
    $DestinationOU = $OUList | Get-Random
    $DisplayName = "$UserFirstName $UserLastName"

    # Increments the user name if there happens to be a repeat.
    $Count = 1
    while (Get-ADUser -Filter "SamAccountName -eq '$UserName'" -ErrorAction SilentlyContinue) {
        Write-ScriptLog -level WARN -Message "User $UserName exists, incrementing ID." -logfile $RunLogOutput
        Write-Verbose "User $UserName exists, incrementing ID."
        $UserName = "$UserName.$Count"
        $DisplayName = "$DisplayName.$Count"
        $Count++
    }

    $UserParams = @{
        SamAccountName = $UserName
        UserPrincipalName = "$UserName@$($DomainInfo)"
        Name = $DisplayName
        GivenName = $UserFirstName
        Surname = $UserLastName
        Enabled = $True
        Description = "User created with AD-BulkUser Script $($CurrentDate.ToString("yyyy-MM-dd"))."
        DisplayName = $DisplayName
        Department = $Department
        Path = $DestinationOU
        AccountPassword = (convertto-securestring $RandomPassword -AsPlainText -Force)
        ChangePasswordAtLogon = $True
    }
    Write-verbose "Creating $UserName"
    if ($PSCmdlet.ShouldProcess("User creation operation for $UserName @ $DestinationOU, dept:$Department, role:$UserRole.")) {
        try{
            New-ADUser @UserParams
            Write-ScriptLog -level INFO -Message "[$UserFirstName $UserLastName] created in $DestinationOU, with the role $UserRole." -logfile $RunLogOutput
        }
        Catch{
            Write-ScriptLog -level ERROR -Message "Something went wrong creating $UserName : $_." -logfile $RunLogOutput
        }
        try{
            Write-verbose "Adding $UserName to $UserRole"
            add-adgroupmember -Identity $UserRole -members $UserName
        }
        catch{
            Write-ScriptLog -level ERROR -Message "Something went wrong adding $UserName to $UserRole $_." -logfile $RunLogOutput

        }
    }
}



#################################### EXECUTION #######################################
Set-NewFolder $RunLogDir

Write-ScriptLog -level INFO -message "Bulk test user creation run by $ENV:UserName on $ENV:ComputerName." -logfile $RunLogOutput
Write-ScriptLog -level INFO -message "$UserCount random users will be created on this run." -logfile $RunLogOutput

$CheckFiles = $GivenNames,$FamilyNames,$Roles,$DestinationOUList,$DepartmentList
#Make sure all resource files can be found
foreach ($file in $CheckFiles){
    if (-not(Test-Path $file -PathType leaf)){
        Write-ScriptLog -level ERROR -message "$file not found, please verify the path and file exists: $_." -logfile $RunLogOutput
        Throw "$file not found, please verify the path and file exists: $_."
    }
}

#If the user does not provide custom domain/upn information then attempt to automnatically grab it.
if(-not($DomainInfo)){
    try{
        $DomainInfo = $(Get-ADDomain -ErrorAction Stop).DNSRoot
        Write-ScriptLog -level INFO -message "Domain information gathered automatically, using: $DomainInfo" -logfile $RunLogOutput
    }
    catch{
        Write-ScriptLog -level ERROR -message "Could not gather domain information: $_" -logfile $RunLogOutput
    }
}
else {
    Write-ScriptLog -level WARN -message "Custom domain info provided : $DomainInfo" -logfile $RunLogOutput
}

Try{
    Write-Verbose "Reading required files...."
    $FirstList = Get-Content $GivenNames -ErrorAction Stop
    $LastList = Get-Content $FamilyNames -ErrorAction Stop
    $RolesList = Get-Content $Roles -ErrorAction Stop
    $OUList = Get-Content $DestinationOUList -ErrorAction Stop
    $DepList = Get-Content $DepartmentList -ErrorAction Stop
    #Grab domain information for creating our accounts.
    
    Write-Verbose "Files read successfully."
}
catch{
    Write-ScriptLog -level ERROR -Message "Something went wrong reading the file $_." -logfile $RunLogOutput
    Throw "Something went wrong reading a file $_."
}


$UCount = 1
While($UCount -le $UserCount){
    Start-BulkUsersCreation
    $UCount++
}

$sw.stop()

Write-ScriptLog -level INFO -message  "Bulk test user creation ran for: $($sw.elapsed)" -logfile $RunLogOutput