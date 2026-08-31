[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DataRoot = "F:\Shares"
)

$ErrorActionPreference = "Stop"

$Shares = [ordered]@{
    "Finance$"    = @{ Folder = "Finance";    Group = "CORP\DL_FS01_Finance_RW" }
    "Sales$"      = @{ Folder = "Sales";      Group = "CORP\DL_FS01_Sales_RW" }
    "Management$" = @{ Folder = "Management"; Group = "CORP\DL_FS01_Mgmt_RW" }
    "IT$"         = @{ Folder = "IT";         Group = "CORP\DL_FS01_IT_RW" }
    "Public"      = @{ Folder = "Public";     Group = "CORP\DL_FS01_Public_RW" }
}

foreach ($ShareName in $Shares.Keys) {
    $Config = $Shares[$ShareName]
    $Path = Join-Path $DataRoot $Config.Folder

    if ($PSCmdlet.ShouldProcess($Path, "Create folder and apply NTFS permissions")) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        & icacls.exe $Path /inheritance:r | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to disable permission inheritance on $Path (icacls exit code $LASTEXITCODE)."
        }

        & icacls.exe $Path /grant:r `
            "SYSTEM:(OI)(CI)(F)" `
            "BUILTIN\Administrators:(OI)(CI)(F)" `
            "$($Config.Group):(OI)(CI)(M)" | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to apply NTFS permissions on $Path (icacls exit code $LASTEXITCODE)."
        }
    }

    $ExistingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
    if (-not $ExistingShare -and $PSCmdlet.ShouldProcess($ShareName, "Create SMB share")) {
        New-SmbShare `
            -Name $ShareName `
            -Path $Path `
            -FullAccess "CORP\Domain Admins" `
            -ChangeAccess $Config.Group `
            -FolderEnumerationMode AccessBased `
            -CachingMode None | Out-Null
    }

    if ($ExistingShare) {
        if ([System.IO.Path]::GetFullPath($ExistingShare.Path) -ne [System.IO.Path]::GetFullPath($Path)) {
            throw "Existing share $ShareName points to $($ExistingShare.Path), expected $Path."
        }

        if ($PSCmdlet.ShouldProcess($ShareName, "Reconcile SMB share settings and required access")) {
            Set-SmbShare `
                -Name $ShareName `
                -FolderEnumerationMode AccessBased `
                -CachingMode None `
                -Force | Out-Null

            Grant-SmbShareAccess `
                -Name $ShareName `
                -AccountName "CORP\Domain Admins" `
                -AccessRight Full `
                -Force | Out-Null

            Grant-SmbShareAccess `
                -Name $ShareName `
                -AccountName $Config.Group `
                -AccessRight Change `
                -Force | Out-Null
        }
    }
}

Get-SmbShare |
    Where-Object Name -in $Shares.Keys |
    Select-Object Name, Path, FolderEnumerationMode
