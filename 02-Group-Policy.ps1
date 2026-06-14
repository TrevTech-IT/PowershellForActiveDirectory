#Requires -Modules GroupPolicy
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory Basics - Group Policy
    Companion script for TrevTech-IT YouTube | EP2: PowerShell for AD

.DESCRIPTION
    Replicates the GPO demo from the video:
      - Create a new GPO
      - Link it to the IT OU
      - Configure the Desktop Wallpaper setting
      - Additional examples: map a drive, enforce password policy settings

.NOTES
    Run on:  Domain Controller  OR  machine with GPMC + GroupPolicy module (RSAT)
    Domain:  Change variables below to match your environment
    Lab:     trevtech.lab

    For the wallpaper setting to work you need a .jpg file at the UNC path.
    In a lab: copy any wallpaper.jpg to \\trevtech.lab\netlogon\wallpaper.jpg
#>

# VARIABLES - Change these to match your environment before running
$Domain      = "trevtech.lab"
$DomainDN    = "DC=trevtech,DC=lab"
$OUPath_IT   = "OU=IT,$DomainDN"
$GPOName     = "IT - Desktop Wallpaper"
$WallpaperUNC = "\\$Domain\netlogon\wallpaper.jpg"   # place a .jpg here first


# STEP 1 - CREATE THE GPO
# GUI: GPMC -> Group Policy Objects -> right-click -> New
#      Name: "IT - Desktop Wallpaper" -> OK

Write-Host "`n[1/3] Creating GPO: $GPOName" -ForegroundColor Cyan

if (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue) {
    Write-Host "    -- GPO already exists, skipping creation" -ForegroundColor Yellow
} else {
    New-GPO -Name $GPOName -Comment "Sets corporate desktop wallpaper for IT OU users"
    Write-Host "    OK  GPO created" -ForegroundColor Green
}


# STEP 2 - LINK THE GPO TO THE IT OU
# GUI: GPMC -> right-click the IT OU -> "Create a GPO in this domain and Link it here"
#      (or drag-drop an existing GPO onto the OU)

Write-Host "`n[2/3] Linking GPO to IT OU" -ForegroundColor Cyan

# Check if already linked
$existingLinks = (Get-GPInheritance -Target $OUPath_IT).GpoLinks |
                 Where-Object { $_.DisplayName -eq $GPOName }

if ($existingLinks) {
    Write-Host "    -- GPO already linked to IT OU, skipping" -ForegroundColor Yellow
} else {
    New-GPLink -Name $GPOName -Target $OUPath_IT -LinkEnabled Yes
    Write-Host "    OK  GPO linked to: $OUPath_IT" -ForegroundColor Green
}


# STEP 3 - CONFIGURE SETTINGS INSIDE THE GPO
# GUI: Right-click GPO -> Edit -> opens Group Policy Management Editor
#      Navigate: User Configuration -> Policies -> Administrative Templates
#                -> Desktop -> Desktop -> Desktop Wallpaper
#      Set: Enabled | Wallpaper Name: \\trevtech.lab\netlogon\wallpaper.jpg
#           Wallpaper Style: Fill

Write-Host "`n[3/3] Configuring Desktop Wallpaper setting" -ForegroundColor Cyan

# Registry key that the ADMX template writes to
$RegKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System"

# Set the wallpaper path
Set-GPRegistryValue -Name $GPOName -Key $RegKey -ValueName "Wallpaper" -Type String -Value $WallpaperUNC
Write-Host "    OK  Wallpaper path: $WallpaperUNC" -ForegroundColor Green

# Set the wallpaper display style
# 0 = Centre | 1 = Tile | 2 = Stretch | 6 = Fit | 10 = Fill
Set-GPRegistryValue -Name $GPOName -Key $RegKey -ValueName "WallpaperStyle" -Type String -Value "10"
Write-Host "    OK  Wallpaper style: Fill (10)" -ForegroundColor Green


# BONUS - OTHER COMMON GPO SETTINGS
# These are commented out - uncomment to use. Each one matches a
# common GUI action in the Group Policy Management Editor.

# MAP A NETWORK DRIVE (User Configuration)
# GUI: User Config -> Preferences -> Windows Settings -> Drive Maps -> New
# Note: Drive preferences use XML, not registry - easier done in GPMC GUI
# PowerShell alternative: use a logon script or Intune PowerShell policy

# BLOCK REMOVABLE STORAGE (USB drives)
# GUI: Computer Config -> Admin Templates -> System -> Removable Storage Access
#      -> "All Removable Storage classes: Deny all access" -> Enabled
<#
Set-GPRegistryValue -Name "IT - Security Baseline" -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" -ValueName "Deny_All" -Type DWord -Value 1
#>

# DISABLE CONTROL PANEL FOR STANDARD USERS
# GUI: User Config -> Admin Templates -> Control Panel -> Prohibit access -> Enabled
<#
Set-GPRegistryValue -Name "IT - User Restrictions" -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoControlPanel" -Type DWord -Value 1
#>

# SET LOCK SCREEN TIMEOUT (seconds)
<#
Set-GPRegistryValue -Name "IT - Security Baseline" -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "InactivityTimeoutSecs" -Type DWord -Value 600   # 10 minutes
#>


# VERIFY - Show GPO summary
Write-Host "`nGPO summary:" -ForegroundColor Cyan
Get-GPO -Name $GPOName |
    Select-Object DisplayName, GpoStatus, CreationTime, ModificationTime |
    Format-List

Write-Host "GPO links on IT OU:" -ForegroundColor Cyan
(Get-GPInheritance -Target $OUPath_IT).GpoLinks |
    Select-Object DisplayName, Enabled, Enforced, Order |
    Format-Table -AutoSize

Write-Host "Script complete.`n" -ForegroundColor Cyan
