# 🏢 Enterprise Active Directory Home Lab

> A fully simulated enterprise IT environment built on VMware, featuring Windows Server 2022 domain infrastructure, automated user lifecycle management via PowerShell, and security-hardened Group Policy baselines — designed to mirror real-world Tier 1/2 Sysadmin operations.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Lab Architecture](#lab-architecture)
- [Technologies Used](#technologies-used)
- [What I Built & Configured](#what-i-built--configured)
- [Challenges & Troubleshooting](#challenges--troubleshooting)
- [Scripts Included](#scripts-included)
- [Key Takeaways](#key-takeaways)
- [Related Projects](#related-projects)

---

## Overview

This lab was built to simulate the kind of enterprise Active Directory environment you'd find at a mid-sized organization — the type of environment I support daily as an IT professional. Rather than just reading about AD administration, I wanted hands-on experience with the full lifecycle: building the domain from scratch, managing identities at scale, enforcing security policy, and automating repetitive Tier 1 tasks that eat up help desk time.

**Goal:** Build a production-realistic AD environment and prove I can operate in it — not just describe it.

---

## Lab Architecture

```
VMware Workstation (Host)
│
├── DC01 — Windows Server 2022 (Primary Domain Controller)
│     ├── AD DS (Active Directory Domain Services)
│     ├── DNS Server
│     ├── DHCP Server
│     └── FSMO Roles: PDC Emulator, RID Master, Infrastructure Master
│
├── DC02 — Windows Server 2022 (Secondary Domain Controller)
│     ├── AD DS Replica
│     ├── DNS Secondary
│     └── FSMO Roles: Schema Master, Domain Naming Master
│
├── WRK01 — Windows 11 Pro (Domain-Joined Workstation)
│     └── Simulated end-user environment for GPO testing
│
└── WRK02 — Windows 10 Pro (Domain-Joined Workstation)
      └── Simulated legacy endpoint for compatibility testing
```

**Domain:** `corp.jallow.local`
**IP Scheme:** `192.168.10.0/24`

---

## Technologies Used

| Category | Tools / Platforms |
|---|---|
| Virtualization | VMware Workstation |
| Server OS | Windows Server 2022 |
| Client OS | Windows 10/11 Pro |
| Directory Services | Active Directory Domain Services (AD DS) |
| DNS & DHCP | Windows Server DNS / DHCP roles |
| Automation | PowerShell 5.1 |
| Policy Management | Group Policy Objects (GPO) |
| Identity Management | Active Directory Users & Computers (ADUC), RSAT |

---

## What I Built & Configured

### 1. Domain Infrastructure
- Promoted DC01 as the **primary domain controller** for `corp.jallow.local`
- Installed and configured **AD DS, DNS, and DHCP roles** on DC01
- Promoted DC02 as a **replica domain controller** for redundancy and FSMO role distribution
- Configured **DNS zones** (forward and reverse lookup) and **DHCP scopes** with reservations for servers

### 2. Organizational Unit (OU) Structure
Designed a scalable OU hierarchy modeled after real enterprise environments:

```
corp.jallow.local
├── _Workstations
│   ├── Laptops
│   └── Desktops
├── _Servers
├── _Users
│   ├── IT
│   ├── HR
│   ├── Finance
│   └── Contractors
├── _Groups
│   ├── Security Groups
│   └── Distribution Groups
└── _ServiceAccounts
```

### 3. Group Policy Objects (GPOs)
Configured and linked the following GPOs to enforce security and desktop standards:

| GPO Name | Scope | Purpose |
|---|---|---|
| `Password-Policy-Baseline` | Domain | Min 12 char, complexity, 90-day expiry |
| `Account-Lockout-Policy` | Domain | 5 failed attempts, 30-min lockout |
| `Desktop-Restrictions` | _Users OU | Disable Control Panel, restrict USB |
| `Software-Deployment` | _Workstations OU | Map network drives, deploy shortcuts |
| `Contractors-Limited-Access` | Contractors OU | Restrict logon hours, no local admin |

### 4. Workstation Domain Joins
- Domain-joined WRK01 (Windows 11) and WRK02 (Windows 10) to `corp.jallow.local`
- Verified GPO application using `gpresult /r` and `gpupdate /force`
- Tested user logins, mapped drives, and policy enforcement across both workstations

### 5. PowerShell Automation
Automated the highest-volume Tier 1 tasks a help desk handles daily:
- **Bulk user provisioning** from CSV — creates users, sets attributes, assigns to correct OU and groups
- **Stale account detection** — flags accounts inactive for 90+ days, exports report, disables on confirmation
- **Password reset automation** — resets and forces change on next login with logging
- **AD audit export** — pulls all users, last logon, group memberships, account status to CSV/JSON

*(See `/scripts` folder for full documented scripts)*

---

## Challenges & Troubleshooting

### FSMO Role Conflicts & Replication Issues

The most complex challenge in this build was getting **AD replication working correctly between DC01 and DC02**, specifically around FSMO role distribution.

**Problem:** After promoting DC02, I noticed replication errors in `repadmin /showrepl` — objects created on DC01 were not consistently syncing to DC02. Additionally, when I attempted to seize certain FSMO roles for testing, DC02 showed inconsistent role recognition.

**Root Cause:** During the initial DC02 promotion, I had a misconfigured DNS setting — DC02 was pointing to its own IP for primary DNS instead of DC01. This caused it to not properly locate the existing domain's DNS zones, which broke the replication topology from the start.

**Resolution:**
1. Corrected DC02's primary DNS to point to DC01 (`192.168.10.10`) before re-running replication
2. Ran `repadmin /syncall /AdeP` to force a full sync
3. Used `netdom query fsmo` to verify all 5 FSMO roles were correctly assigned
4. Validated replication health with `repadmin /replsummary` — all partitions showed clean

**Lesson:** DNS is the backbone of Active Directory. A misconfigured DNS pointer during DC promotion will silently break replication in ways that aren't immediately obvious. Always verify DNS resolution *before* promoting a replica DC.

---

## Scripts Included

| Script | Description |
|---|---|
| `scripts/New-BulkADUsers.ps1` | Creates AD users from CSV with OU placement, group assignment, and forced password reset |
| `scripts/Get-StaleAccounts.ps1` | Detects inactive accounts 90+ days, exports report, disables accounts *(coming soon)* |
| `scripts/Reset-UserPassword.ps1` | Resets password and forces change at next logon with audit log *(coming soon)* |
| `scripts/Export-ADUserReport.ps1` | Exports all AD user data to CSV and JSON *(coming soon)* |

## Sample Files

| File | Description |
|---|---|
| `samples/new-users.csv` | Example CSV input for New-BulkADUsers.ps1 |

---

## Key Takeaways

- **DNS is everything in AD.** Most domain join failures, replication issues, and authentication errors trace back to DNS. Learned to always check DNS first.
- **GPO troubleshooting requires patience.** `gpresult`, `rsop.msc`, and event logs are your best friends when policy isn't applying as expected.
- **PowerShell at scale changes everything.** Provisioning 50 users manually vs. a 10-second CSV import — automation isn't optional in a real environment, it's expected.
- **FSMO roles matter more than most courses tell you.** Understanding which DC holds which role, and what breaks if that DC goes offline, is critical knowledge for any Sysadmin.
- **Documentation is a skill.** Built and maintained internal runbooks throughout this lab as if I was onboarding a colleague — a habit that directly mirrors professional IT operations.

---

## Related Projects

- 🔗 [PowerShell Sysadmin Toolkit](../powershell-sysadmin-toolkit) — Reusable AD automation scripts
- 🔗 [Small Office Network Lab](../small-office-network-lab) — Cisco-based networking project covering VLAN segmentation, DHCP, and wireless AP deployment
- 🔗 [IT Support Runbooks](../it-support-runbooks) — Real-world troubleshooting documentation from volunteer IT work

---

## About

**Ebrima Jallow** — IT Support Specialist | Sysadmin | Worcester, MA
- [LinkedIn](https://www.linkedin.com/in/ebrima-jallow1/)
- B.Tech Computer Engineering, Delhi Technological University
- SANS GFACT (In Progress) | CompTIA A+ (Studying)
