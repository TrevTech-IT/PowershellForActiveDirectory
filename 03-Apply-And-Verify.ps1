#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory Basics - Apply & Verify
    Companion script for TrevTech-IT YouTube | EP2: PowerShell for AD

.DESCRIPTION
    Replicates the verification steps from the video:
      - Force Group Policy refresh (local and remote)
      - Pull a GPResult report
      - Verify which GPOs applied to a user/computer
      - Check AD replication health across DCs

.NOTES
    Run on:  Domain-joined machine or Domain Controller
    Domain:  trevtech.lab  ->  change $Domain and $DomainDN below
#>

# VARIABLES - Change these to match your environment before running
$Domain         = "trevtech.lab"
$DomainDN       = "DC=trevtech,DC=lab"
$TargetComputer = "DESKTOP-01"          # change to a real hostname in your lab
$TargetUser     = "bwayne"
$ReportPath     = "$env:TEMP\GPReport"


# SECTION 1 - FORCE GROUP POLICY REFRESH
# GUI: Open Command Prompt -> type: gpupdate /force -> press Enter
#      Watch for "User Policy update has completed successfully."

Write-Host "`n[1/3] Group Policy refresh" -ForegroundColor Cyan

# Option A: local machine (run this ON the workstation itself)
Write-Host "    Refreshing policy on THIS machine..." -ForegroundColor DarkGray
gpupdate /force
# Note: /force re-applies all settings even if unchanged.
# Without /force it only applies settings that have changed since last refresh.

Write-Host ""

# Option B: push to a REMOTE machine over the network
#    Requires: WinRM enabled on target + appropriate firewall rules
#    To enable WinRM on the remote machine first:  Enable-PSRemoting -Force
<#
Write-Host "    Pushing policy refresh to $TargetComputer..." -ForegroundColor DarkGray
Invoke-GPUpdate -Computer $TargetComputer -Force -RandomDelayInMinutes 0   # 0 = no delay, immediate push
Write-Host "    OK  Policy refreshed on $TargetComputer" -ForegroundColor Green
#>


# SECTION 2 - GPRESULT - What policies actually applied?
# GUI: Command Prompt -> gpresult /h report.html -> open report.html in browser
# This is how you debug "why isn't my GPO applying?" situations

Write-Host "`n[2/3] Generating GP result report" -ForegroundColor Cyan

# Option A: quick text summary in the console
Write-Host "    Text summary (current user + computer):" -ForegroundColor DarkGray
gpresult /r
# /r = summary for current user and computer
# Add /scope user  to see only user-side policies
# Add /scope computer to see only computer-side policies

Write-Host ""

# Option B: full HTML report - most useful for debugging
$HtmlReport = "$ReportPath-local.html"
gpresult /h $HtmlReport /f          # /f = overwrite if exists
Write-Host "    OK  HTML report saved to: $HtmlReport" -ForegroundColor Green
Start-Process $HtmlReport           # opens in default browser

# Option C: pull report for a REMOTE user on a REMOTE computer
#    Requires GroupPolicy module + appropriate permissions
<#
$RemoteReport = "$ReportPath-remote.html"
Get-GPResultantSetOfPolicy -ReportType Html -Path $RemoteReport -Computer $TargetComputer -User "$Domain\$TargetUser"
Start-Process $RemoteReport
Write-Host "    OK  Remote RSoP report: $RemoteReport" -ForegroundColor Green
#>


# SECTION 3 - VERIFY GPO LINKS & INHERITANCE
# GUI: GPMC -> click an OU -> "Group Policy Inheritance" tab
# Shows which GPOs are applied, in what order, and whether any are blocked

Write-Host "`n[3/3] GPO inheritance check" -ForegroundColor Cyan

# Check what GPOs are applied to the IT OU (with inheritance)
$OUPath = "OU=IT,$DomainDN"
Write-Host "    GPOs applying to IT OU (including inherited):" -ForegroundColor DarkGray
(Get-GPInheritance -Target $OUPath).InheritedGpoLinks |
    Select-Object DisplayName, Enabled, Enforced, Order, GpoDomainName |
    Sort-Object Order |
    Format-Table -AutoSize

# Check GPOs directly linked to the IT OU
Write-Host "    GPOs directly linked to IT OU:" -ForegroundColor DarkGray
(Get-GPInheritance -Target $OUPath).GpoLinks |
    Select-Object DisplayName, Enabled, Enforced, Order |
    Format-Table -AutoSize


# SECTION 4 - AD REPLICATION HEALTH
# GUI: None - there's no built-in GUI for this. Command-line only.
# Run this on a DC whenever logins behave inconsistently across the domain.

Write-Host "`nBonus: AD replication status" -ForegroundColor Cyan

# Show full replication summary
Write-Host "    Running repadmin /showrepl ..." -ForegroundColor DarkGray
repadmin /showrepl

# Errors only - much cleaner in healthy environments
Write-Host "`n    Errors only (blank = healthy):" -ForegroundColor DarkGray
repadmin /showrepl /errorsonly

# Summary view - good for multi-DC environments
repadmin /replsummary


# SECTION 5 - USEFUL AD STATUS CHECKS

Write-Host "`nBonus: AD status checks" -ForegroundColor Cyan

# Who are my Domain Controllers?
Write-Host "    Domain Controllers in $Domain :" -ForegroundColor DarkGray
Get-ADDomainController -Filter * |
    Select-Object Name, IPv4Address, Site, IsGlobalCatalog, OperationMasterRoles |
    Format-Table -AutoSize

# Which DC holds the FSMO roles?
Write-Host "    FSMO role holders:" -ForegroundColor DarkGray
$domain = Get-ADDomain
$forest = Get-ADForest
[PSCustomObject]@{
    PDCEmulator          = $domain.PDCEmulator
    RIDMaster            = $domain.RIDMaster
    InfrastructureMaster = $domain.InfrastructureMaster
    SchemaMaster         = $forest.SchemaMaster
    DomainNamingMaster   = $forest.DomainNamingMaster
} | Format-List

# Is the AD Recycle Bin enabled?
Write-Host "    AD Recycle Bin status:" -ForegroundColor DarkGray
$recycleBin = Get-ADOptionalFeature -Filter "Name -like 'Recycle Bin*'"
if ($recycleBin.EnabledScopes.Count -gt 0) {
    Write-Host "    OK  AD Recycle Bin is ENABLED" -ForegroundColor Green
} else {
    Write-Host "    !!  AD Recycle Bin is DISABLED - enable it with:" -ForegroundColor Red
    Write-Host "        Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target '$Domain'" -ForegroundColor Yellow
}

Write-Host "`nScript complete.`n" -ForegroundColor Cyan
