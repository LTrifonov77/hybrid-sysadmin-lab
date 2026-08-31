# MON01 — Ubuntu and Zabbix implementation record

## Objective

Create a small Linux monitoring server that demonstrates Ubuntu administration, SSH hardening, service management, firewall configuration, DNS integration, monitoring, and incident verification.

## Selected platform

- Operating system: Ubuntu Server 24.04.4 LTS amd64
- Monitoring: Zabbix 7.4 stable
- Hostname: `MON01`
- Address: `10.20.30.30/24`
- Gateway: `10.20.30.1`
- DNS: `10.20.30.10`
- Hyper-V: Generation 2, 2 vCPU, 4 GB startup RAM, dynamic memory, 40 GB dynamic VHDX
- Network: `LAB-SWITCH`
- Secure Boot template: Microsoft UEFI Certificate Authority

Ubuntu 24.04 LTS is used instead of the newer 26.04 LTS because the stable Zabbix 7.4 repository publishes packages for Ubuntu 24.04. This favors a stable monitoring stack over the newest operating-system release.

## Verified implementation sequence

1. [x] Download the official Ubuntu ISO and verify its SHA-256 hash.
2. [x] Create and install the `MON01` Hyper-V VM.
3. [x] Configure static networking and an AD DNS record.
4. [x] Apply updates and verify time synchronization.
5. [x] Create a named administrator account with `sudo`; disable direct root SSH access.
6. [x] Configure SSH key authentication, then disable SSH password authentication after verification.
7. [x] Enable UFW with only required lab ports.
8. [x] Install Zabbix server, web frontend, database, and local agent.
9. [x] Add Windows agents to `DC01`, `FS01`, and `CLIENT01`.
10. [x] Verify dashboards, availability, service alerts, and one controlled incident.

The reusable Windows installer script pins Zabbix Agent 2 `7.4.14` and validates the downloaded MSI against its recorded SHA-256 hash before installation.

## Firewall exposure

| Port | Protocol | Purpose | Source |
|---:|---|---|---|
| 22 | TCP | SSH administration | `10.20.30.0/24` |
| 80 | TCP | Zabbix web interface | `10.20.30.0/24` |
| 10050 | TCP | Zabbix agent | `10.20.30.0/24` |
| 10051 | TCP | Zabbix server/trapper | `10.20.30.0/24` |

## Evidence checklist

- `screenshots/07-monitoring/01-mon01-install-and-network.png`
- `screenshots/07-monitoring/02-ssh-hardening.png`
- `screenshots/07-monitoring/03-zabbix-services.png`
- `screenshots/07-monitoring/04-agent-connectivity.png`
- `screenshots/07-monitoring/04-hosts-available.png`
- `screenshots/07-monitoring/05-agent-alert.png`
- `screenshots/07-monitoring/06-agent-recovery.png`

## Acceptance checks

- [x] `hostnamectl` reports `MON01`.
- [x] Forward and reverse DNS resolve between Windows and Linux.
- [x] `MON01` reaches the internet through `LAB-NAT` without being bridged to the physical LAN.
- [x] SSH key login works before password authentication is disabled.
- [x] Zabbix reports all four lab systems as available.
- [x] A stopped test service produces an alert and a recovery event after restart.
