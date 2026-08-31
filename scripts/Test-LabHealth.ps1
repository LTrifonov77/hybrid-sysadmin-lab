[CmdletBinding()]
param(
    [string]$OutputDirectory = (Join-Path $env:ProgramData "SysadminLab\Reports")
)

$ErrorActionPreference = "Stop"

$Targets = @(
    [pscustomobject]@{
        Name  = "DC01"
        Fqdn  = "dc01.corp.example.test"
        IP    = "10.20.30.10"
        Ports = [ordered]@{ DNS = 53; Kerberos = 88; LDAP = 389 }
    }
    [pscustomobject]@{
        Name  = "CLIENT01"
        Fqdn  = "client01.corp.example.test"
        IP    = "10.20.30.20"
        Ports = [ordered]@{}
    }
    [pscustomobject]@{
        Name  = "MON01"
        Fqdn  = "mon01.corp.example.test"
        IP    = "10.20.30.30"
        Ports = [ordered]@{ SSH = 22; ZabbixWeb = 80; ZabbixServer = 10051 }
    }
    [pscustomobject]@{
        Name  = "FS01"
        Fqdn  = "fs01.corp.example.test"
        IP    = "10.20.30.40"
        Ports = [ordered]@{ SMB = 445 }
    }
)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$Timestamp = Get-Date
$Rows = foreach ($Target in $Targets) {
    $ResolvedAddresses = @(
        Resolve-DnsName -Name $Target.Fqdn -Server "10.20.30.10" -Type A -DnsOnly -ErrorAction SilentlyContinue |
            Where-Object Type -eq "A" |
            Select-Object -ExpandProperty IPAddress
    )

    $DnsOK = $Target.IP -in $ResolvedAddresses
    $PingOK = Test-Connection -ComputerName $Target.IP -Count 1 -Quiet -ErrorAction SilentlyContinue

    $PortResults = foreach ($Entry in $Target.Ports.GetEnumerator()) {
        $Open = Test-NetConnection `
            -ComputerName $Target.IP `
            -Port $Entry.Value `
            -InformationLevel Quiet `
            -WarningAction SilentlyContinue

        [pscustomobject]@{
            Service = $Entry.Key
            Port    = $Entry.Value
            Open    = [bool]$Open
        }
    }

    $PortsOK = @($PortResults | Where-Object Open -eq $false).Count -eq 0

    [pscustomobject]@{
        CheckedAt    = $Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
        Host         = $Target.Name
        Address      = $Target.IP
        DNS          = if ($DnsOK) { "PASS" } else { "FAIL" }
        Ping         = if ($PingOK) { "PASS" } else { "FAIL" }
        RequiredPorts = ($PortResults | ForEach-Object {
            "{0}:{1}={2}" -f $_.Service, $_.Port, $(if ($_.Open) { "PASS" } else { "FAIL" })
        }) -join "; "
        Overall      = if ($DnsOK -and $PingOK -and $PortsOK) { "HEALTHY" } else { "ATTENTION" }
    }
}

$FileStamp = $Timestamp.ToString("yyyyMMdd-HHmmss")
$CsvPath = Join-Path $OutputDirectory "LabHealth-$FileStamp.csv"
$HtmlPath = Join-Path $OutputDirectory "LabHealth-$FileStamp.html"

$Rows | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8

$Style = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 32px; color: #1f2937; }
h1 { margin-bottom: 4px; }
p { color: #4b5563; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th, td { border: 1px solid #d1d5db; padding: 8px 10px; text-align: left; }
th { background: #1f4e78; color: white; }
tr:nth-child(even) { background: #f3f4f6; }
</style>
"@

$Rows |
    ConvertTo-Html `
        -Title "SYSADMIN Lab Health Report" `
        -Head $Style `
        -PreContent "<h1>SYSADMIN Lab Health Report</h1><p>Generated $($Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))</p>" |
    Set-Content -Path $HtmlPath -Encoding UTF8

$Rows | Format-Table -AutoSize
Write-Host ""
Write-Host "CSV report:  $CsvPath"
Write-Host "HTML report: $HtmlPath"

if (@($Rows | Where-Object Overall -ne "HEALTHY").Count -gt 0) {
    exit 1
}

exit 0
