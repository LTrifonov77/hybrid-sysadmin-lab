# Administration automation

## Lab health report

`scripts/Test-LabHealth.ps1` performs a repeatable health check from the administration workstation `CLIENT01`.

It verifies:

- forward DNS resolution through `DC01`;
- basic ICMP reachability;
- AD DNS, Kerberos, and LDAP ports on `DC01`;
- SSH, HTTP, and the Zabbix server port on `MON01`;
- SMB access on `FS01`.

The script does not test the Windows Zabbix Agent port from `CLIENT01`. The host firewall intentionally allows TCP 10050 only from `MON01`; agent availability remains a Zabbix responsibility.

## Output

Each run writes timestamped CSV and HTML reports to:

```text
C:\ProgramData\SysadminLab\Reports
```

It also returns exit code `0` when every check passes and exit code `1` when any target needs attention, making it suitable for Task Scheduler and other automation systems.

## Verification

A manual run from `CLIENT01` reported `DC01`, `CLIENT01`, `MON01`, and `FS01` as `HEALTHY`. Evidence: `screenshots/09-automation/01-lab-health-report-console.png`.

## Scheduled execution

`scripts/Register-LabHealthTask.ps1` creates the `SYSADMIN Lab Health Report` task on `CLIENT01`. It runs daily at 18:30 as `SYSTEM`, starts when available, prevents overlapping runs, and limits execution to ten minutes.

Because the task runs with high privileges, `C:\Admin\Test-LabHealth.ps1` must remain writable only by `SYSTEM` and local Administrators. This is an operational prerequisite, not a reason to place credentials in the script.

An unattended test produced new timestamped CSV and HTML files. Task Scheduler reported `LastTaskResult: 0` and a valid next-run time.

Evidence:

- `screenshots/09-automation/02-scheduled-report-output.png`
- `screenshots/09-automation/03-scheduled-task-success.png`
