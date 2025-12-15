# AD_BulkTestUsers

## Description
This PowerShell script automates the creation of bulk user accounts within an Active Directory lab environment. It generates users with random attributes selected from provided lists, including first and last names, Organizational Units (OUs), security groups, and departments.

The script is intended strictly for testing and lab environments to simulate user population and management.

## Prerequisites
* Windows PowerShell 5.1 or later.
* **Active Directory PowerShell Module** (RSAT) must be installed and available.
* The account running the script must have permissions to create users and modify group memberships in the target Active Directory domain.

## Configuration Files
The script relies on five text files to generate random user data. By default, the script looks for these files in the same directory as the script execution.

* `given-names.txt`: A list of given (first) names.
* `family-names.txt`: A list of family (last) names.
* `roles.txt`: A list of existing Security Groups to assign to users.
* `Dest-OUs.txt`: A list of target Distinguished Names (DN) for OUs (e.g., `OU=TestUsers,DC=testnet,DC=lab`).
* `DepartmentList.txt`: A list of department names.

You may provide custom paths to these files using script parameters if they are not located in the script root.

## Usage

### Parameters
* `-UserCount` (Integer): The number of users to create (Default: 10, Range: 1-1000).
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
Create 100 users using the default source files
```powershell
AD-BulkTestUsers.ps1 -usercount 100
```
This would use the default files and create 100 users
- It will automatically target the file names defined within the folder the script is run in.

```powershell
AD-BulkTestUsers.ps1 -usercount 100 -DestinationOUList C:\Script\Your-OU-List.txt -roles C:\Script\Your-roles-List.txt
```
This would use the default Given and family names, default department names and create 100 users
- The script with gather the roles and destination OUs from the provided paths.