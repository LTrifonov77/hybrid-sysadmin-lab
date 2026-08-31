# Centralized logging evidence

- `01-dc01-failed-logon-event.png` — Zabbix history showing a controlled Windows Security Event ID 4625 received from `DC01` for the nonexistent test account `CORP\zbx-invalid`.
- `02-multiple-failed-logons-alert.png` — Warning trigger raised after three controlled failed logons within five minutes.
- `03-failed-logons-recovery.png` — the failed-logon Warning automatically returned to `RESOLVED` after the quiet period.

The test account is intentionally nonexistent. No passwords or production identities are included.
