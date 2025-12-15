# AD_BulkTestUsers

## Description
This PowerShell script automates the creation of bulk user accounts within an Active Directory lab environment. It generates users with random attributes selected from provided lists, including first and last names, Organizational Units (OUs), security groups, and departments.

**The script is intended strictly for testing and lab environments to simulate user population and management.**

## Prerequisites
* **Active Directory PowerShell Module** (RSAT) must be installed or this should be run on a server with AD installed.
* Permissions to create users and modify group memberships in the target Active Directory domain.

## Configuration Files
The script is bundled with several text files to generate random user data. By default, the script looks for these files in the same directory as the script execution.

* `given-names.txt`: A list of 300 given (first) names.
* `family-names.txt`: A list of 300 family (last) names.
* `roles.txt`: A list of existing Security Groups to add users to.
* `Dest-OUs.txt`: List of target Distinguished Names for OUs (e.g., OU=TestUsers,DC=testnet,DC=lab).
* `DepartmentList.txt`: A list of department names.

You may provide custom paths to these files using script parameters if they are not located in the script root.

## Usage

### Parameters
* `-UserCount` (Integer): The number of users to create (Default: 10, Range: 1-100).
* `-givennames` (String): Path to the given names file.
* `-familynames` (String): Path to the family names file.
* `-roles` (String): Path to the roles/groups file.
* `-DestinationOUList` (String): Path to the OU list file.
* `-DepartmentList` (String): Path to the department list file.

### Examples

**Default Run**
Creates 10 users using the default text files located in the script directory.
```powershell
.\AD-BulkTestUsers.ps1
```
**Create 100 Users**
Create 100 users using the default source files
```powershell
AD-BulkTestUsers.ps1 -usercount 100
```
**Use different source files**
Create 50 users using using custom lists. 
```powershell
AD-BulkTestUsers.ps1 -usercount 50 -DestinationOUList C:\Script\Your-OU-List.txt -roles C:\Script\Your-roles-List.txt
```

### Logging

The script automatically generates execution logs.

* `Location`: \BulkUsersLogs\RunLogs\YYYY-MM\ within the script directory.
* `Format`: BulkUsers_RunLog_YYYY-MM-dd_HH.mm.ss.txt.

Logs distinguish between INFO, WARN, and ERROR levels to assist with troubleshooting failed account creations or duplicate user handling.

## Disclaimer

This script is provided for educational and testing purposes only. The user assumes full responsibility for any actions performed using this script. The author accepts no liability for any damage caused to production environments or data.