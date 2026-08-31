# Centralized Windows event monitoring

## Objective

Collect selected security-relevant Windows events centrally on `MON01` through Zabbix, while avoiding unnecessary ingestion of the entire Windows event log.

## Initial implementation

`DC01` uses Zabbix Agent 2 active checks to send failed-logon events from the Windows Security log to the Zabbix server at `10.20.30.30:10051`.

| Setting | Value |
|---|---|
| Host | `DC01` |
| Item name | `Security log: failed logon events` |
| Item type | Zabbix agent (active) |
| Item key | `eventlog[Security,,,,4625,,skip]` |
| Information type | Log |
| Windows event | `4625` — failed logon |

The `skip` mode starts collection from newly generated events instead of importing the existing Security log history.

## Verification

A controlled failed logon used the deliberately nonexistent account `CORP\zbx-invalid`. Zabbix received Event ID `4625` from `Microsoft-Windows-Security-Auditing` and displayed the failure reason `Unknown user name or bad password`.

Evidence: `screenshots/08-centralized-logging/01-dc01-failed-logon-event.png`.

## Alert threshold

The trigger `DC01: Multiple failed logon attempts` uses the following expression:

```text
count(/DC01/eventlog[Security,,,,4625,,skip],5m)>=3 and nodata(/DC01/eventlog[Security,,,,4625,,skip],5m)=0
```

It raises a Warning only after three failed logons within five minutes, reducing noise from an isolated mistyped password. The `nodata()` condition causes periodic reevaluation when no new log records arrive. Three controlled attempts with the nonexistent test account successfully raised the trigger, and it automatically recovered after the quiet period. Evidence: `screenshots/08-centralized-logging/02-multiple-failed-logons-alert.png` and `03-failed-logons-recovery.png`.

## Next steps

- Add selected account-lockout and privileged-group-change events.
- Define retention and document the distinction between monitoring and a full SIEM platform.
