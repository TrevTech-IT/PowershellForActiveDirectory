#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory Basics - OUs, Users & Groups
    Companion script for TrevTech-IT YouTube | EP2: PowerShell for AD

.DESCRIPTION
    Replicates everything shown in the GUI demo:
      - Create Organisational Units (IT, Workstations)
      - Create a user (Bruce Wayne / bwayne)
      - Create a security group (IT-Admins)
      - Add the user to the group
      - Verify everything looks right

.NOTES
    Run on:  Domain Controller  OR  domain-joined machine with RSAT installed
    Domain:  Change the $Domain and $DomainDN variables below to match your environment
    Lab:     trevtech.lab
    CHANGES: user is now Bruce Wayne (bwayne); password is prompted, not hardcoded.
#>

# VARIABLES - Change these to match your environment before running
$Domain   = "trevtech.lab"
$DomainDN = "DC=trevtech,DC=lab"          # Distinguished Name of your domain root

# HELPER - show what we're about to do in the same style as the video
function Show-Step { param($n, $text)
    Write-Host "`n[$n] $text" -ForegroundColor Cyan
}
function Show-OK   { param($text)
    Write-Host "    OK  $text" -ForegroundColor Green
}
function Show-Skip { param($text)
    Write-Host "    --  $text (already exists, skipping)" -ForegroundColor Yellow
}


# SECTION 1 - ORGANISATIONAL UNITS
# GUI: Open ADUC -> right-click the domain name -> New -> Organisational Unit
#      Type the name -> tick "Protect from accidental deletion" -> OK

Show-Step "1/4" "Creating Organisational Units"

$OUs = @("IT", "Workstations")

foreach ($ouName in $OUs) {
    $exists = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $DomainDN -SearchScope OneLevel -ErrorAction SilentlyContinue

    if ($exists) {
        Show-Skip "OU: $ouName"
    } else {
        New-ADOrganizationalUnit -Name $ouName -Path $DomainDN -ProtectedFromAccidentalDeletion $true
        Show-OK "Created OU: $ouName"
    }
}

# Verify - list all top-level OUs
Write-Host "`n    Top-level OUs in $Domain :" -ForegroundColor DarkGray
Get-ADOrganizationalUnit -Filter * -SearchBase $DomainDN -SearchScope OneLevel |
    Select-Object Name, DistinguishedName |
    Format-Table -AutoSize


# SECTION 2 - CREATE A USER
# GUI: In ADUC, expand the IT OU -> right-click -> New -> User
#      Fill in: First name, Last name, User logon name (bwayne)
#      Next -> set password -> tick "User must change password at next logon" -> Finish

Show-Step "2/4" "Creating user - Bruce Wayne (bwayne)"

$OUPath_IT = "OU=IT,$DomainDN"

if (Get-ADUser -Filter "SamAccountName -eq 'bwayne'" -ErrorAction SilentlyContinue) {
    Show-Skip "User: bwayne"
} else {
    # Prompt for the initial password instead of hardcoding it
    $InitialPassword = Read-Host -Prompt "Enter an initial password for bwayne" -AsSecureString

    $NewUserParams = @{
        GivenName             = "Bruce"
        Surname               = "Wayne"
        Name                  = "Bruce Wayne"
        DisplayName           = "Bruce Wayne"
        SamAccountName        = "bwayne"
        UserPrincipalName     = "bwayne@$Domain"
        Path                  = $OUPath_IT
        AccountPassword       = $InitialPassword
        ChangePasswordAtLogon = $true      # forces reset on first login
        Enabled               = $true
        Description           = "IT Administrator"
    }
    New-ADUser @NewUserParams
    Show-OK "Created user: bwayne  (bwayne@$Domain)"
}

# Verify
Write-Host "`n    User details:" -ForegroundColor DarkGray
Get-ADUser -Identity "bwayne" -Properties DisplayName, UserPrincipalName, Enabled |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, DistinguishedName |
    Format-List


# SECTION 3 - CREATE A SECURITY GROUP
# GUI: Right-click the IT OU -> New -> Group
#      Name: IT-Admins | Group scope: Global | Group type: Security -> OK

Show-Step "3/4" "Creating security group - IT-Admins"

if (Get-ADGroup -Filter "Name -eq 'IT-Admins'" -ErrorAction SilentlyContinue) {
    Show-Skip "Group: IT-Admins"
} else {
    New-ADGroup -Name "IT-Admins" -GroupScope Global -GroupCategory Security -Path $OUPath_IT -Description "IT Administrators - full admin access"
    Show-OK "Created group: IT-Admins (Global Security)"
}


# SECTION 4 - ADD USER TO GROUP
# GUI: Double-click IT-Admins -> Members tab -> Add -> type bwayne
#      -> Check Names -> OK -> Apply

Show-Step "4/4" "Adding bwayne to IT-Admins"

$members = Get-ADGroupMember -Identity "IT-Admins" -ErrorAction SilentlyContinue |
           Where-Object { $_.SamAccountName -eq "bwayne" }

if ($members) {
    Show-Skip "bwayne is already a member of IT-Admins"
} else {
    Add-ADGroupMember -Identity "IT-Admins" -Members "bwayne"
    Show-OK "bwayne added to IT-Admins"
}

# Verify group membership
Write-Host "`n    Members of IT-Admins:" -ForegroundColor DarkGray
Get-ADGroupMember -Identity "IT-Admins" |
    Select-Object Name, SamAccountName, ObjectClass |
    Format-Table -AutoSize

# Also useful - see all groups a user belongs to
Write-Host "    Groups bwayne belongs to:" -ForegroundColor DarkGray
Get-ADPrincipalGroupMembership -Identity "bwayne" |
    Select-Object Name, GroupCategory, GroupScope |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host "`nScript complete.`n" -ForegroundColor Cyan
