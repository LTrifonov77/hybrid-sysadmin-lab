# Phase 1 — Planning and prerequisites

## 1. Host computer prerequisites

Record the following before installing any virtualization software:

| Check | Value |
|---|---|
| Windows edition and version | Windows 11 Pro, build 26100 |
| CPU model | AMD Ryzen 7 6800H, 16 logical processors |
| Hardware virtualization enabled | Yes |
| Installed RAM | 31.2 GB usable |
| Free disk space | C: 21.5 GB; D: 122.5 GB; E: 25 GB |
| Existing virtualization platform | Hyper-V installed; management service running |

The processor and memory are sufficient for the planned four-VM lab when only the systems required for the current exercise are running. Store all virtual-machine files on `D:` because `C:` and `E:` do not have enough free space. Use dynamically expanding virtual disks and keep at least 20–25 GB free on `D:`.

Proposed resource budget:

| Virtual machine | vCPU | Startup RAM | Maximum disk size |
|---|---:|---:|---:|
| `DC01` | 2 | 4 GB | 40 GB dynamic |
| `CLIENT01` | 2 | 6 GB | 50 GB dynamic |
| `FS01` | 2 | 4 GB | 35 GB OS + 20 GB data dynamic |
| `MON01` | 2 | 4 GB | 40 GB dynamic |

Do not run every VM when it is not required. This reduces memory pressure and prevents all dynamic disks from growing at the same time.

## 2. Proposed lab design

Working domain name: `corp.example.test`

Working subnet: `10.20.30.0/24`

| Hostname | Operating system | Role | Proposed address |
|---|---|---|---|
| `DC01` | Windows Server | AD DS and DNS | `10.20.30.10` |
| `CLIENT01` | Windows 11 | Domain workstation | `10.20.30.20` |
| `MON01` | Ubuntu Server LTS | Monitoring and logging | `10.20.30.30` |
| `FS01` | Windows Server Core | File services and backup | `10.20.30.40` |

The lab uses the internal Hyper-V switch `LAB-SWITCH` and the active NAT network `LAB-NAT` for `10.20.30.0/24`. The virtual machines are not bridged directly onto the home or office LAN. Their default gateway is `10.20.30.1`, and domain members use `10.20.30.10` for DNS.

## 3. Planned organization structure

Departments:

- IT
- Management
- Finance
- Sales

Initial Active Directory structure:

```text
corp.example.test
├── Company
│   ├── Users
│   │   ├── IT
│   │   ├── Management
│   │   ├── Finance
│   │   └── Sales
│   ├── Computers
│   ├── Servers
│   └── Groups
└── Service Accounts
```

## 4. Architecture decisions to confirm

- Virtualization: Hyper-V is the preferred choice for this Windows 11 Pro host
- Windows Server 2025 Evaluation and Windows 11 Enterprise Evaluation are in use
- Ubuntu Server 24.04 LTS is selected for compatibility with the stable Zabbix 7.4 packages
- Monitoring stack: Zabbix server, frontend, database, and agent on `MON01`
- Static addressing is used for infrastructure systems; DHCP can be added as a later exercise
- Repository documentation is English; guided learning notes may be Bulgarian

## 5. Phase 1 completion criteria

- [x] Host specifications recorded
- [x] Virtualization platform selected: Hyper-V
- [x] Lab resource budget defined
- [x] Network remains isolated from the home/office LAN during initial setup
- [x] Naming and addressing plan approved
- [x] Installation media sources documented

## 6. Installation media

Large ISO files remain local and are excluded by `.gitignore`.

| Media | Local use | Source |
|---|---|---|
| Windows Server 2025 Evaluation | `DC01`, `FS01` | Microsoft Evaluation Center |
| Windows 11 Enterprise Evaluation | `CLIENT01` | Microsoft Evaluation Center |
| Ubuntu Server 24.04.4 LTS amd64 | `MON01` | `https://releases.ubuntu.com/noble/` |

Expected SHA-256 for `ubuntu-24.04.4-live-server-amd64.iso`:

```text
e907d92eeec9df64163a7e454cbc8d7755e8ddc7ed42f99dbc80c40f1a138433
```
