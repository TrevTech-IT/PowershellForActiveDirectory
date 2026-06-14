# TrevTech-IT — Active Directory PowerShell Scripts

> Companion scripts for the **TrevTech Homelab Series** on YouTube.  
> Every script mirrors a GUI demo from the video — same steps, just automated.  
> Copy, paste, swap the domain name, and follow along.

📺 **EP1 — Active Directory From Scratch** → [youtube.com/c/TrevTech-IT](#) *(link coming soon)*  
📺 **EP2 — PowerShell for AD** → [youtube.com/c/TrevTech-IT](#) *(link coming soon)*  
🌐 **Blog** → [trevtech.blog](https://trevtech.blog)

---

## Scripts

Run them in this order on a fresh Windows Server 2022 VM:

| # | File | What it does | Video |
|---|---|---|---|
| 1 | `00-Rename-And-Static-IP.ps1` | Rename server to DC01, set static IP + DNS → reboots | EP2 — Setup |
| 2 | `00-Install-ADDS.ps1` | Install AD DS role + promote DC (new forest) → reboots | EP1 — Segment 2 |
| 3 | `01-OUs-Users-Groups.ps1` | Create OUs, users, security groups, add members | EP2 — 3:30–6:30 |
| 4 | `02-Group-Policy.ps1` | Create a GPO, link it to an OU, configure settings | EP2 — 6:30–9:30 |
| 5 | `03-Apply-And-Verify.ps1` | gpupdate, gpresult, GPO inheritance, repadmin, FSMO | EP2 — 9:30–13:00 |
| 6 | `04-Bonus-Queries.ps1` | Stale accounts, group audits, help desk day-to-day commands | EP2 — Bonus |

---

## Quick start

**Step 1 — One-time setup**

```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Step 2 — Update the domain variables at the top of each script**

```powershell
# Change these two lines to match your lab:
$Domain   = "trevtech.lab"        # e.g. trevtech.lab, corp.contoso.com
$DomainDN = "DC=trevtech,DC=lab"  # e.g. DC=trevtech,DC=lab
```

**Step 3 — Run the script**

```powershell
.\01-OUs-Users-Groups.ps1
```

Or step through it line by line in VS Code (F8) or the PowerShell ISE — better for learning.

Every command is written on a single line, so you can also copy any one line straight into a PowerShell terminal and run it on its own.

---

## Requirements

- Windows Server 2022 **or** Windows 10/11 with RSAT installed
- Run PowerShell **as Administrator**
- Machine must be **domain-joined** (or run directly on the DC)
- RSAT modules: `ActiveDirectory`, `GroupPolicy`

**Install RSAT on Windows 10/11 if needed:**

```powershell
# ActiveDirectory module
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"

# Group Policy module + GPMC
Add-WindowsCapability -Online -Name "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
```

---

## DN format cheat sheet

| Domain FQDN | DomainDN |
|---|---|
| `lab.local` | `DC=lab,DC=local` |
| `trevtech.lab` | `DC=trevtech,DC=lab` |
| `corp.contoso.com` | `DC=corp,DC=contoso,DC=com` |

---

## Lab setup (what the videos are recorded on)

| | |
|---|---|
| **Hardware** | Dell PowerEdge R730 (~$400 on eBay) |
| **Hypervisor** | Proxmox VE |
| **Domain controller** | Windows Server 2022 VM — `DC01` |
| **Domain** | `trevtech.lab` |
| **Network** | `192.168.10.0/24` |

This isn't a cloud VM or a nested virtualisation demo. It's a real server running real enterprise software — the same stack you'd find in a small business.

---

## Notes on Script 04

`04-Bonus-Queries.ps1` is **read-only by default** — safe to run without modifying anything.

The write operations at the bottom (unlock, reset password, disable, move, bulk ops) are wrapped in `<# ... #>` comment blocks. Uncomment only what you need.

---

## More from TrevTech

- 🖥 Homelab Build — Dell R730 for under $500
- 🔐 Active Directory From Scratch (EP1)
- ⚙️ PowerShell for AD (EP2) ← you are here
- 🚀 SCCM / Intune — coming soon
- 🌐 Networking basics — coming soon

---

*I broke it. Fixed it. Now I'm showing you how.*
