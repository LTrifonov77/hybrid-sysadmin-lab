# Verified build record

This document records completed work and points to sanitized evidence. It does not contain credentials, recovery secrets, product keys, or private network information outside the lab.

## Network and identity

| Component | Verified result | Evidence |
|---|---|---|
| `LAB-NAT` | Active NAT prefix `10.20.30.0/24` | Host verification |
| `DC01` | `corp.example.test` domain controller and DNS server | `screenshots/01-domain-controller/` |
| Active Directory | Department OUs, global security groups, and test users | `screenshots/02-active-directory/` |
| `CLIENT01` | Domain joined; domain-user sign-in verified | `screenshots/03-client-domain-join/` |
| Group Policy | Scoped GPO applied and confirmed with `gpresult` | `screenshots/04-group-policy/` |

## File services and least privilege

`FS01` is a domain-joined Windows Server Core machine at `10.20.30.40`. Company data is stored on a separate NTFS volume mounted as `F:`.

Access follows AGDLP:

```text
Account -> Global group -> Domain Local group -> Permission
```

Example:

```text
ivan.petrov -> GG_IT_Users -> DL_FS01_IT_RW -> Modify on \\FS01\IT$
```

The shortened group name `DL_FS01_Mgmt_RW` is intentional. It remains within the legacy 20-character `sAMAccountName` interoperability limit.

| Share | Assigned domain-local group | Intended access |
|---|---|---|
| `Finance$` | `DL_FS01_Finance_RW` | Finance modify |
| `Sales$` | `DL_FS01_Sales_RW` | Sales modify |
| `Management$` | `DL_FS01_Mgmt_RW` | Management modify |
| `IT$` | `DL_FS01_IT_RW` | IT modify |
| `Public` | `DL_FS01_Public_RW` | All employees modify |

The test account `CORP\ivan.petrov` could access and write to `IT$` and `Public`, while access to `Finance$` was denied. Evidence is stored in `screenshots/05-file-server/`.

## Backup and recovery

Windows Server Backup writes the `F:` data volume to the separate `FS01-BACKUP.vhdx` disk mounted as `G:`. A purpose-created file was backed up, deleted, and restored to its original path. Content, SHA-256 hash, and ACL were checked after recovery.

Evidence is stored in `screenshots/06-backup-restore/`.

### Limitation

The backup virtual disk and VM disks are on the same physical `D:` drive. This proves the recovery workflow but does not protect against physical-disk loss. A production design would use the 3-2-1 rule: three copies, two media types, and one off-site copy.

## Linux administration and monitoring

`MON01` runs Ubuntu Server 24.04.4 LTS at `10.20.30.30`. Forward and reverse AD-integrated DNS records resolve correctly.

Security controls:

- SSH key authentication is enabled.
- Direct root and SSH password authentication are disabled.
- UFW denies unsolicited inbound traffic by default.
- SSH and Zabbix ports are restricted to the lab subnet.

Zabbix 7.4.14 monitors `MON01`, `DC01`, `CLIENT01`, and `FS01` with Linux and Windows Agent 2 templates. Direct `zabbix_get` checks returned `agent.ping=1` and the correct hostname for every Windows system.

A controlled incident stopped only the Zabbix Agent 2 service on `FS01`. Zabbix raised `Windows: Zabbix agent is not available (for 3m)` and recorded a successful recovery after the service was restarted. Evidence is stored in `screenshots/07-monitoring/`.

### Alert tuning

The inherited Windows service-discovery exclusions were preserved and extended at host level. `AppXSvc` was excluded on `CLIENT01`, `DC01`, and `FS01`; `InventorySvc` was additionally excluded on `DC01`. Low-level discovery was executed manually, and the expected service alerts cleared without disabling the Windows monitoring template or other service checks.

## Centralized Windows security events

`DC01` sends selected Security log events to Zabbix through an active Agent 2 item. A controlled authentication attempt with the nonexistent account `CORP\zbx-invalid` produced Event ID `4625`, which appeared in Zabbix with its source, severity, account, and failure reason. A threshold of three failures within five minutes successfully raised a Warning trigger, which automatically recovered after the quiet period. Evidence is stored in `screenshots/08-centralized-logging/` and the configuration is recorded in `docs/04-centralized-logging.md`.

## Administration automation

`scripts/Test-LabHealth.ps1` checks forward DNS, ICMP reachability, and role-specific TCP services from `CLIENT01`. It writes timestamped CSV and HTML reports and returns a nonzero exit code when attention is required. The first verified run reported all four lab systems as healthy. `scripts/Register-LabHealthTask.ps1` schedules the report daily at 18:30 as `SYSTEM`; an unattended run created both output files and returned result code `0`. Evidence is stored in `screenshots/09-automation/` and implementation details are in `docs/05-automation.md`.

## Portfolio readiness

The public repository contains only documentation, sanitized evidence, and selected administration scripts. VM disks, installation media, backup media, credentials, and private keys remain local and are excluded through `.gitignore`.
