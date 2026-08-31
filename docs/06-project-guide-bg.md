# Пълно ръководство за Hybrid System Administration Lab

## 1. Какво представлява проектът

Това е практическа лаборатория, която симулира инфраструктурата на малка фирма. Целта не е просто да има няколко виртуални машини, а да се покаже цял работен процес на системен администратор:

- планиране на мрежа и роли;
- централизирано управление на потребители и компютри;
- DNS и Group Policy;
- файлови ресурси с ограничен достъп;
- архивиране и реално възстановяване;
- Linux администрация и защитен SSH;
- наблюдение, security събития и аларми;
- автоматизирани проверки и документиране на резултатите.

Фирменият сценарий използва измислената организация **Northstar Services** и домейна `corp.example.test`. Всички адреси, потребители и събития са лабораторни.

## 2. Как е построена мрежата

Лабораторията работи върху Hyper-V на Windows 11 Pro.

| Компонент | Предназначение |
|---|---|
| `LAB-SWITCH` | Internal Hyper-V switch, който свързва host машината и лабораторните VM-и |
| `LAB-NAT` | Осигурява интернет достъп без директно свързване на VM-ите към домашната/офис мрежата |
| `10.20.30.0/24` | Частната лабораторна мрежа |
| `10.20.30.1` | Gateway/NAT адрес върху Hyper-V host-а |
| `10.20.30.10` | `DC01` и основен DNS за домейн машините |

Изолацията е важна: лабораторните DNS, Active Directory и тестови политики не могат да влияят на реалната локална мрежа.

## 3. Роля на всяка машина

### `DC01` — идентичност, DNS и политики

`DC01` е Windows Server 2025 с адрес `10.20.30.10`.

Използва се за:

- **Active Directory Domain Services** — централизирани потребители, групи, компютри и удостоверяване;
- **DNS** — превежда имена като `fs01.corp.example.test` към IP адреси;
- **Group Policy** — прилага настройки към правилните потребители и компютри;
- организиране на обектите в OU структура за IT, Management, Finance и Sales.

Домейнът позволява един служебен акаунт да получава достъп според групите си, вместо на всеки сървър да се създават отделни локални потребители.

### `CLIENT01` — домейн работна станция и административна проверка

`CLIENT01` е Windows 11 с адрес `10.20.30.20`.

Използва се за:

- проверка на domain join и вход с домейн потребител;
- потвърждаване на Group Policy чрез `gpresult`;
- реални тестове за разрешен и забранен достъп до файловите shares;
- изпълнение на автоматизирания health report;
- доказване, че потребителското преживяване отговаря на зададените политики.

Това е по-реалистично от тестване само с Administrator директно на сървърите.

### `FS01` — файлов сървър и възстановяване

`FS01` е Windows Server Core с адрес `10.20.30.40`. Server Core намалява графичните компоненти и насърчава отдалечено/PowerShell администриране.

Данните се намират на отделен `F:` virtual disk. Създадени са shares:

| Share | Предназначение |
|---|---|
| `Finance$` | Финансов отдел |
| `Sales$` | Търговски отдел |
| `Management$` | Ръководство |
| `IT$` | IT отдел |
| `Public` | Общ фирмен ресурс |

Знакът `$` скрива share-а от обикновено мрежово разглеждане, но не е механизъм за сигурност. Реалната защита идва от SMB и NTFS permissions.

Достъпът следва **AGDLP**:

```text
Account -> Global Group -> Domain Local Group -> Permission
```

Пример:

```text
ivan.petrov -> GG_IT_Users -> DL_FS01_IT_RW -> Modify on \\FS01\IT$
```

Този модел отделя организационната принадлежност от разрешението върху конкретен ресурс. Така достъпът се управлява чрез членство в групи, а не с индивидуални ACL записи за всеки човек.

### `MON01` — Linux администрация и наблюдение

`MON01` е Ubuntu Server 24.04 LTS с адрес `10.20.30.30`.

Използва се за Zabbix server/web frontend, MySQL, Nginx, PHP-FPM, Agent 2 за самонаблюдение и упражнения по Linux networking, systemd, firewall и SSH.

Машината има DNS A/PTR записи, но умишлено не е присъединена към Active Directory. Това запазва monitoring сървъра независимо администриран и демонстрира Linux локална идентичност.

Security настройките включват key-only SSH, забранен директен root вход, забранена SSH password authentication след проверка на ключа и UFW default deny с разрешени само необходимите лабораторни портове.

## 4. Как работят основните услуги

### Active Directory и DNS

Active Directory управлява идентичността. DNS е критична част от AD, защото клиентите откриват domain controller, Kerberos и LDAP услуги чрез DNS записи. Затова domain машините използват `10.20.30.10` като DNS, а не публичен DNS директно.

### Group Policy

Group Policy позволява една настройка да бъде приложена централизирано към подходящ OU scope. Резултатът се проверява от клиента с `gpresult`, вместо да се приема, че GPO е приложена само защото е създадена.

### SMB и NTFS permissions

Share permissions ограничават достъпа през мрежата, а NTFS permissions защитават файловата система. Ефективният достъп е комбинация от двете. Проектът използва явни групови разрешения и Access-Based Enumeration, така че потребителите виждат само ресурсите, до които имат достъп.

### Backup и restore

Windows Server Backup записва data volume към отделен backup virtual disk. Тестов файл е създаден и хеширан, архивиран, умишлено изтрит, възстановен и проверен за съдържание, SHA-256 hash и ACL. Това доказва възстановяване, а не само успешно приключил backup job.

### Zabbix monitoring

Zabbix Agent 2 работи на Windows машините, а `MON01` събира health данните. Windows Firewall допуска Agent 2 порт `10050` само от `MON01`.

Контролиран тест със спиране на Agent 2 върху `FS01` създаде аларма и последващо recovery събитие. Очаквано спиращите Windows услуги `AppXSvc` и `InventorySvc` са изключени на засегнатите hosts, без да се премахва основният template или останалите service проверки.

### Windows Security events

`DC01` изпраща нови Event ID `4625` записи към Zabbix чрез active agent item:

```text
eventlog[Security,,,,4625,,skip]
```

`skip` предотвратява първоначално импортиране на цялата стара Security log история.

Алармата се активира след три неуспешни входа за пет минути:

```text
count(/DC01/eventlog[Security,,,,4625,,skip],5m)>=3 and nodata(/DC01/eventlog[Security,,,,4625,,skip],5m)=0
```

`nodata()` осигурява периодично преизчисляване и автоматично recovery след тих период. Това е целево operational security monitoring, а не пълна SIEM платформа.

## 5. Автоматизация

### Health report

`scripts/Test-LabHealth.ps1` се изпълнява от `CLIENT01` и проверява DNS A records, ICMP reachability, DNS/Kerberos/LDAP на `DC01`, SSH/HTTP/Zabbix server на `MON01` и SMB на `FS01`.

Резултатите се записват като CSV и HTML в:

```text
C:\ProgramData\SysadminLab\Reports
```

Exit code `0` означава, че всички проверки са успешни; exit code `1` означава, че поне една система изисква внимание.

Скриптът не проверява Windows Agent 2 порт `10050` от `CLIENT01`, защото firewall правилно разрешава този порт само от `MON01`. Zabbix носи отговорност за agent availability.

### Scheduled Task

`scripts/Register-LabHealthTask.ps1` регистрира задачата `SYSADMIN Lab Health Report`: всеки ден в 18:30, като `SYSTEM`, с `StartWhenAvailable`, без паралелни копия и с максимум десет минути изпълнение.

Тестово unattended изпълнение създаде CSV/HTML файлове и върна `LastTaskResult: 0`.

## 6. Как се използва лабораторията

Препоръчителен ред за стартиране:

1. `DC01` — необходим за DNS и домейн удостоверяване;
2. `MON01` — monitoring и web интерфейс;
3. `FS01` — файлови ресурси;
4. `CLIENT01` — потребителски и административни тестове.

Основни адреси и ресурси:

```text
Zabbix:       http://10.20.30.30
IT share:     \\FS01\IT$
Public share: \\FS01\Public
Health task:  SYSADMIN Lab Health Report
Reports:      C:\ProgramData\SysadminLab\Reports
```

След стартиране се проверяват DNS resolution към четирите FQDN имена, зелен ZBX status, правилният SMB достъп и последният health report/`LastTaskResult`.

## 7. Скриптове и къде се изпълняват

| Скрипт | Изпълнява се на | Какво прави |
|---|---|---|
| `New-FileServerGroups.ps1` | `DC01` | Създава domain-local AGDLP групите и nesting-а |
| `Configure-FS01Shares.ps1` | `FS01` | Създава папки, ACL и SMB shares |
| `Test-FS01Access.ps1` | `CLIENT01` като тестов domain user | Проверява разрешен и забранен достъп |
| `Install-ZabbixAgent2.ps1` | Всеки Windows host като Administrator | Инсталира Agent 2 и ограничена firewall rule |
| `Test-LabHealth.ps1` | `CLIENT01` | Създава health report |
| `Register-LabHealthTask.ps1` | `CLIENT01` като Administrator | Регистрира ежедневната задача |

Преди повторно изпълнение трябва да се прегледат parameter defaults. Скриптовете не съдържат пароли и не трябва да се допълват с реални credentials.

Installer скриптът е фиксиран към тестваната Agent 2 версия `7.4.14` и проверява SHA-256 на MSI файла преди инсталация. Това намалява риска бъдещо изпълнение да изтегли различен `latest` пакет.

## 8. Какво доказват тестовете

| Тест | Практическо доказателство |
|---|---|
| `gpresult` | GPO достига правилния клиент и scope |
| Разрешен/забранен SMB достъп | Least privilege и AGDLP работят реално |
| File restore с hash и ACL | Backup-ът може да възстанови използваеми данни |
| Agent outage и recovery | Monitoring открива прекъсване и връщане на услуга |
| Event 4625 threshold | Централно security-event наблюдение без alert при единична грешка |
| Scheduled Task result `0` | Автоматизацията работи unattended |

## 9. Troubleshooting примери

- Липсващият DNS A record за `CLIENT01` е открит от health report и добавен в AD DNS.
- Очакваните `AppXSvc`/`InventorySvc` alerts са намалени чрез запазване и разширяване на template exclusions, а не чрез изключване на monitoring-а.
- Контролираното спиране на Agent 2 върху `FS01` потвърди alert и recovery пътя.
- Първоначалният failed-logon trigger остана в `PROBLEM`, защото `count()` няма нов log value за преизчисляване; добавянето на `nodata()` осигури timer evaluation и recovery.
- Health report първоначално тестваше Agent 2 порт от `CLIENT01`; проверката беше премахната, защото firewall правилно разрешава порта само от `MON01`.

## 10. Security решения

- Изолирана Hyper-V мрежа вместо external bridge.
- Статични адреси за инфраструктурните системи.
- AD групи вместо индивидуални permissions.
- Server Core за файловия сървър.
- Key-only SSH и забранен root/password SSH.
- UFW и Windows Firewall правила само за необходимите източници и портове.
- Никакви пароли, private keys, product keys, ISO/VM дискове или backup media в Git.
- Контролирани тестови акаунти и умишлено несъществуващият `zbx-invalid` за failed-logon теста.

## 11. Ограничения и production подобрения

- Backup virtual disk е на същия физически диск като VM storage. В production трябва 3-2-1 backup и off-site копие.
- Има един domain controller; production среда обикновено изисква поне два.
- Няма висока наличност за Zabbix/MySQL.
- Event monitoring е селективен и не заменя SIEM, дългосрочен log archive или SOC процес.
- Evaluation операционните системи са подходящи само за лаборатория.
- Имената, IP адресите и пътищата в скриптовете са специфични за този lab.

## 12. Къде са доказателствата

- `screenshots/01-domain-controller` — домейн и DNS
- `screenshots/02-active-directory` — OU, групи и потребители
- `screenshots/03-client-domain-join` — client и domain login
- `screenshots/04-group-policy` — GPO scope и `gpresult`
- `screenshots/05-file-server` — shares, permissions и access test
- `screenshots/06-backup-restore` — backup и restore
- `screenshots/07-monitoring` — Zabbix hosts, outage и recovery
- `screenshots/08-centralized-logging` — Event 4625, trigger и recovery
- `screenshots/09-automation` — health report и Scheduled Task

## 13. Какво показва проектът пред работодател

Проектът показва, че кандидатът може да свърже отделни технологии в работеща инфраструктура, да приложи least privilege, да провери резултата с негативни и recovery тестове, да автоматизира повтарящи се проверки и да документира ограниченията честно. Това е по-силно доказателство от списък с инсталирани продукти без тестове и evidence.
