[CmdletBinding()]
param(
    [string]$HealthScriptPath = "C:\Admin\Test-LabHealth.ps1",

    [ValidatePattern("^([01]\d|2[0-3]):[0-5]\d$")]
    [string]$DailyAt = "18:30"
)

$ErrorActionPreference = "Stop"
$TaskName = "SYSADMIN Lab Health Report"

if (-not (Test-Path -LiteralPath $HealthScriptPath -PathType Leaf)) {
    throw "Health-check script not found: $HealthScriptPath"
}

$TimeParts = $DailyAt.Split(":")
$RunAt = (Get-Date).Date.AddHours([int]$TimeParts[0]).AddMinutes([int]$TimeParts[1])

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$HealthScriptPath`""

$Trigger = New-ScheduledTaskTrigger -Daily -At $RunAt

$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -MultipleInstances IgnoreNew

Register-ScheduledTask `
    -TaskName $TaskName `
    -Description "Creates daily CSV and HTML health reports for the SYSADMIN lab." `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -User "SYSTEM" `
    -RunLevel Highest `
    -Force | Out-Null

Get-ScheduledTask -TaskName $TaskName |
    Select-Object TaskName, State, @{Name = "RunAs"; Expression = { $_.Principal.UserId } }

Get-ScheduledTaskInfo -TaskName $TaskName |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
