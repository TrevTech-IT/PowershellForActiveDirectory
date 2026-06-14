#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Active Directory - Install AD DS & Promote the Domain Controller
    Companion script for TrevTech-IT YouTube | EP1: Active Directory From Scratch

.NOTES
    Run on a FRESH Windows Server 2022 VM.
    WARNING: The server will REBOOT automatically after Step 2.
    WARNING: You will be prompted for a DSRM password - write it down, you'll
             need it if AD ever breaks badly. (No longer hardcoded in this script.)

    GUI equivalent:
      Step 1 -> Server Manager -> Add Roles and Features -> Active Directory Domain Services
      Step 2 -> yellow flag notification -> "Promote this server to a domain controller"
                -> Add a new forest -> set DSRM password -> Install

    Lab used in the TrevTech videos:
      Hardware   : Dell PowerEdge R730
      Hypervisor : Proxmox VE
      VM         : Windows Server 2022  (hostname: DC01, static IP: 192.168.10.10)
      Domain     : trevtech.lab
#>


# STEP 1 - Install the AD DS and DNS roles
# IncludeManagementTools adds ADUC, DNS Manager, and GPMC
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools


# STEP 2 - Promote to Domain Controller (new forest)
# This creates your domain. The server reboots automatically when it finishes.
# After reboot, log in as: TREVTECH\Administrator  (or your NetBIOS name)
# Then run scripts 01-04 to build out OUs, users, groups, and GPOs.

# Prompt for the DSRM password instead of hardcoding it (never commit secrets)
$DSRMPassword = Read-Host -Prompt "Enter a DSRM (Directory Services Restore Mode) password" -AsSecureString

# Initial Forest and Domain setup
Install-ADDSForest -DomainName "trevtech.lab" -ForestMode WinThreshold -DomainMode WinThreshold -DomainNetbiosName TREVTECH -InstallDNS -SafeModeAdministratorPassword $DSRMPassword
