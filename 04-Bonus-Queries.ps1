<#
.SYNOPSIS
    Active Directory Basics - Bonus Queries
    Companion script for TrevTech-IT YouTube | EP2: PowerShell for AD

.DESCRIPTION
    Read-only queries and common day-to-day admin tasks.
    Nothing in this script modifies AD until the clearly marked
    "WRITE OPERATIONS" section at the bottom.

    Great for:
      - Help desk - finding and unlocking users fast
      - Auditing - stale accounts, empty groups, unused computers
      - Interview prep - know these cold

.NOTES
    Run on:  Domain-joined machine with AD module (RSAT)
    Domain:  trevtech.lab  ->  change $DomainDN below
    Safe:    Read-only sections will not modify anything
#>

# VARIABLES - Change these to match your environment before running
$DomainDN = "DC=trevtech,DC=lab"
$Domain   = "trevtech.lab"


# USER QUERIES

# All users in the domain
Get-ADUser -Filter * -Properties DisplayName, LastLogonDate, PasswordLastSet |
    Select-Object Name, SamAccountName, Enabled, LastLogonDate, PasswordLastSet |
    Sort-Object Name |
    Format-Table -AutoSize

# All DISABLED accounts
# GUI: ADUC -> View -> check "Advanced Features" is on
#      -> search saved queries or manually scan OUs
Get-ADUser -Filter { Enabled -eq $false } |
    Select-Object Name, SamAccountName, DistinguishedName |
    Format-Table -AutoSize

# Users who haven't logged in for 90 days - candidates for disabling
# GUI: No built-in GUI view for this - PowerShell is the right tool
$Cutoff = (Get-Date).AddDays(-90)
Get-ADUser -Filter { LastLogonDate -lt $Cutoff -and Enabled -eq $true } -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate |
    Sort-Object LastLogonDate |
    Format-Table -AutoSize

# Find a user by partial name (most-used help desk command)
# GUI: ADUC -> Action -> Find -> type partial name
Get-ADUser -Filter { Name -like "*wayne*" } |
    Select-Object Name, SamAccountName, DistinguishedName

# Accounts with passwords that never expire (often a security risk)
Get-ADUser -Filter { PasswordNeverExpires -eq $true -and Enabled -eq $true } |
    Select-Object Name, SamAccountName |
    Format-Table -AutoSize

# Accounts with expired passwords
Get-ADUser -Filter { PasswordExpired -eq $true -and Enabled -eq $true } |
    Select-Object Name, SamAccountName |
    Format-Table -AutoSize


# GROUP QUERIES

# All groups in the IT OU
# GUI: ADUC -> navigate to IT OU -> see groups listed
Get-ADGroup -Filter * -SearchBase "OU=IT,$DomainDN" |
    Select-Object Name, GroupScope, GroupCategory, DistinguishedName |
    Format-Table -AutoSize

# What groups is a specific user in?
# GUI: ADUC -> open user -> Member Of tab
Get-ADPrincipalGroupMembership -Identity "bwayne" |
    Select-Object Name, GroupCategory, GroupScope |
    Sort-Object Name |
    Format-Table -AutoSize

# Who is in a specific group?
# GUI: ADUC -> open group -> Members tab
Get-ADGroupMember -Identity "IT-Admins" -Recursive |
    Select-Object Name, SamAccountName, ObjectClass |
    Format-Table -AutoSize

# Empty groups (groups with no members - good for auditing/cleanup)
Get-ADGroup -Filter * -Properties Members |
    Where-Object { $_.Members.Count -eq 0 } |
    Select-Object Name, GroupScope, GroupCategory |
    Format-Table -AutoSize


# COMPUTER QUERIES

# All computers in the Workstations OU
# GUI: ADUC -> Workstations OU -> see computers listed
Get-ADComputer -Filter * -SearchBase "OU=Workstations,$DomainDN" -Properties LastLogonDate, OperatingSystem |
    Select-Object Name, Enabled, OperatingSystem, LastLogonDate |
    Format-Table -AutoSize

# Computers that haven't checked in for 90 days (stale computer accounts)
$Cutoff = (Get-Date).AddDays(-90)
Get-ADComputer -Filter { LastLogonDate -lt $Cutoff -and Enabled -eq $true } -Properties LastLogonDate |
    Select-Object Name, LastLogonDate, DistinguishedName |
    Sort-Object LastLogonDate |
    Format-Table -AutoSize


# OU / STRUCTURE QUERIES

# All OUs in the domain (full tree)
# GUI: ADUC -> expand the domain node
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name, DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize

# Top-level OUs only
Get-ADOrganizationalUnit -Filter * -SearchBase $DomainDN -SearchScope OneLevel |
    Select-Object Name, DistinguishedName |
    Format-Table -AutoSize


# WRITE OPERATIONS  -  WARNING: These modify AD - read comments before running

# UNLOCK A USER ACCOUNT
# GUI: ADUC -> right-click user -> Unlock Account
# When to use: user locked out after too many bad password attempts
<#
Unlock-ADAccount -Identity "bwayne"
Write-Host "bwayne unlocked" -ForegroundColor Green
#>

# RESET A PASSWORD AND FORCE CHANGE AT NEXT LOGIN
# GUI: ADUC -> right-click user -> Reset Password
<#
$NewPassword = Read-Host -Prompt "Enter new password for bwayne" -AsSecureString
Set-ADAccountPassword -Identity "bwayne" -NewPassword $NewPassword -Reset
Set-ADUser            -Identity "bwayne" -ChangePasswordAtLogon $true
Write-Host "Password reset for bwayne. They must change it at next login." -ForegroundColor Green
#>

# DISABLE A USER (offboarding - never delete, always disable first)
# GUI: ADUC -> right-click user -> Disable Account
<#
Disable-ADAccount -Identity "bwayne"
Write-Host "bwayne disabled" -ForegroundColor Yellow
#>

# MOVE A USER TO A DIFFERENT OU
# GUI: ADUC -> right-click user -> Move -> pick destination OU
<#
Move-ADObject -Identity "CN=Bruce Wayne,OU=IT,$DomainDN" -TargetPath "OU=Workstations,$DomainDN"
Write-Host "Bruce Wayne moved to Workstations OU" -ForegroundColor Green
#>

# REMOVE A USER FROM A GROUP
# GUI: Open group -> Members tab -> select user -> Remove
<#
Remove-ADGroupMember -Identity "IT-Admins" -Members "bwayne" -Confirm:$false
Write-Host "bwayne removed from IT-Admins" -ForegroundColor Yellow
#>

# BULK DISABLE - disable all users in the IT OU at once
# WARNING: Run the Get-ADUser line first to preview before uncommenting Disable-ADAccount
<#
Get-ADUser -Filter { Enabled -eq $true } -SearchBase "OU=IT,$DomainDN" |
    ForEach-Object {
        Write-Host "  Would disable: $($_.SamAccountName)"
        # Disable-ADAccount -Identity $_.SamAccountName
    }
#>

Write-Host "`nBonus queries complete.`n" -ForegroundColor Cyan
