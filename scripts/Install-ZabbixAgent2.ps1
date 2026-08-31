[CmdletBinding()]
param(
    [string]$ZabbixServer = "10.20.30.30",
    [string]$MsiUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.4/7.4.14/zabbix_agent2-7.4.14-windows-amd64-openssl.msi",
    [string]$ExpectedSha256 = "6C95C51D347492598D5E1E5EE39C45C93D978F85AE1282B8F688EF3E9EF314FB"
)

$ErrorActionPreference = "Stop"
$MsiPath = Join-Path $env:TEMP "zabbix-agent2-7.4.14.msi"
$LogPath = Join-Path $env:TEMP "zabbix-agent2-install.log"
$AgentPath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe"
$ConfigPath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
$FirewallName = "Zabbix Agent 2 from MON01"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Downloading the official Zabbix Agent 2 MSI..."
Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiPath -UseBasicParsing

$DownloadedSha256 = (Get-FileHash -LiteralPath $MsiPath -Algorithm SHA256).Hash
if ($DownloadedSha256 -ne $ExpectedSha256) {
    Remove-Item -LiteralPath $MsiPath -Force -ErrorAction SilentlyContinue
    throw "MSI SHA-256 mismatch. Expected $ExpectedSha256, received $DownloadedSha256."
}

Write-Host "MSI SHA-256 verified: $DownloadedSha256"

$Arguments = @(
    "/i"
    $MsiPath
    "/qn"
    "/norestart"
    "/l*v"
    $LogPath
    "SERVER=$ZabbixServer"
    "SERVERACTIVE=$ZabbixServer"
    "HOSTNAME=$env:COMPUTERNAME"
    "STARTUPTYPE=automatic"
    "ENABLEPATH=1"
    "SKIP=fw"
)

$Process = Start-Process msiexec.exe -ArgumentList $Arguments -Wait -PassThru
if ($Process.ExitCode -notin 0, 3010) {
    throw "MSI installation failed with exit code $($Process.ExitCode). See $LogPath"
}

$ExistingRule = Get-NetFirewallRule -DisplayName $FirewallName -ErrorAction SilentlyContinue
if ($ExistingRule) {
    $ExistingRule | Remove-NetFirewallRule
}

New-NetFirewallRule `
    -DisplayName $FirewallName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort 10050 `
    -RemoteAddress $ZabbixServer `
    -Program $AgentPath | Out-Null

Set-Service -Name "Zabbix Agent 2" -StartupType Automatic
Restart-Service -Name "Zabbix Agent 2"

Get-Service -Name "Zabbix Agent 2" |
    Select-Object Name, Status, StartType

Get-NetFirewallRule -DisplayName $FirewallName |
    Get-NetFirewallAddressFilter |
    Select-Object RemoteAddress

& $AgentPath -t agent.ping -c $ConfigPath
Test-NetConnection -ComputerName $ZabbixServer -Port 10051 -InformationLevel Detailed |
    Select-Object ComputerName, RemotePort, TcpTestSucceeded
