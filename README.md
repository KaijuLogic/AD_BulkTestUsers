# AD_BulkTestUsers

## Description
This PowerShell script automates the creation of bulk user accounts within an Active Directory lab environment. It generates users with random attributes selected from provided lists, including first and last names, Organizational Units (OUs), security groups, and departments.

**The script is intended strictly for testing and lab environments to simulate user population and management.**

## FEATURES
* Can easily create up to 100 users in a single run. 
* Logs are created so you can go back and see which users were created, what role they were given, and what OU they were placed in.
* Supports -whatif
* The script will attempt to automatically query your domain information and fill it in where needed (e.g., UserPrincipalName)

## Prerequisites
* **Active Directory PowerShell Module** (RSAT) must be installed or this should be run on a server with AD installed.
* Permissions to create users and modify group memberships in the target Active Directory domain.

## Configuration Files
The script is bundled with several text files to generate random user data. By default, the script looks for these files in the same directory as the script execution.

* `given-names.txt`: A list of 300 given (first) names.
* `family-names.txt`: A list of 300 family (last) names.
* `roles.txt`: A list of existing Security Groups to add users to.
* `Dest-OUs.txt`: List of target Distinguished Names for a pool of OUs to use (e.g., OU=TestUsers,DC=testnet,DC=lab).
* `DepartmentList.txt`: A list of department names.

You can also provide custom paths to these files using script parameters if they are not located in the script root directory.

## Usage

### Parameters
* `-UserCount` (Integer): The number of users to create (Default: 10, Range: 1-100).
* `-GivenNames` (String): Path to the given names file.
* `-FamilyNames` (String): Path to the family names file.
* `-Roles` (String): Path to the roles/groups file.
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

## Logging

The script will also generate run logs that you can review later.

* **Location**: `\BulkUsersLogs\RunLogs\YYYY-MM\` within the script directory.
* **Format**: `BulkUsers_RunLog_YYYY-MM-dd_HH.mm.ss.txt`.
### Log Example
```powershell
2025-12-16 08:33:24 | INFO | [Aditya Gill] created in OU=MelbourneBranch,DC=testnet,DC=lab, with the role IT-Users.
2025-12-16 08:33:24 | INFO | [Yui Patel] created in OU=AdelaideBranch,DC=testnet,DC=lab, with the role Server Operators.
2025-12-16 08:33:24 | INFO | [Sofia Sidhu] created in OU=TestUsers,DC=testnet,DC=lab, with the role Account Operators.
2025-12-16 08:33:24 | INFO | [Evelyn Kim] created in OU=SydneyBranch,DC=testnet,DC=lab, with the role Backup Operators.
2025-12-16 08:33:24 | INFO | [Vihaan Rivera] created in OU=SydneyBranch,DC=testnet,DC=lab, with the role IT-Users.
2025-12-16 08:33:24 | INFO | [Enchen Bailey] created in OU=MelbourneBranch,DC=testnet,DC=lab, with the role Administrators.
2025-12-16 08:33:24 | INFO | [Louise Fowler] created in OU=AdelaideBranch,DC=testnet,DC=lab, with the role HR-Users.
```


## Disclaimer

This script is provided for educational and testing purposes only. The user assumes full responsibility for any actions performed using this script. The author accepts no liability for any damage caused to production environments or data.