#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Pre-AD Setup - Rename Server & Set Static IP
    Companion script for TrevTech-IT YouTube | EP2: PowerShell for AD

.NOTES
    Run this BEFORE 00-Install-ADDS.ps1
    WARNING: Server will REBOOT at the end - save any open work first.
    WARNING: After reboot, run 00-Install-ADDS.ps1 next.

    GUI equivalent:
      Rename    -> Server Manager -> Local Server -> Computer Name -> Change
      Static IP -> Control Panel -> Network Connections -> Ethernet -> IPv4 Properties
#>


# Set static IP address - change to match your network
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.10.10" -PrefixLength 24 -DefaultGateway "192.168.10.1"

# Point DNS at itself - required before AD DS promotion
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1"

# Rename the server and reboot - log back in as DC01\Administrator
Rename-Computer -NewName "DC01" -Restart -Force
