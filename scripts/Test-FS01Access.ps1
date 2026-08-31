[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$TestId = Get-Date -Format "yyyyMMdd-HHmmss"
$ITPath = "\\FS01\IT$\access-test-$TestId.txt"
$PublicPath = "\\FS01\Public\access-test-$TestId.txt"
$FinancePath = "\\FS01\Finance$\unauthorized-$TestId.txt"
$CreatedFiles = [System.Collections.Generic.List[string]]::new()

$Identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$ITAccessible = Test-Path "\\FS01\IT$"
$PublicAccessible = Test-Path "\\FS01\Public"
$FinanceWriteDenied = $false

try {
    if (-not $ITAccessible) {
        throw "Expected access to \\FS01\IT$ for $Identity, but the share is unavailable."
    }

    if (-not $PublicAccessible) {
        throw "Expected access to \\FS01\Public for $Identity, but the share is unavailable."
    }

    New-Item -Path $ITPath -ItemType File | Out-Null
    $CreatedFiles.Add($ITPath)

    New-Item -Path $PublicPath -ItemType File | Out-Null
    $CreatedFiles.Add($PublicPath)

    try {
        New-Item -Path $FinancePath -ItemType File -ErrorAction Stop | Out-Null
        $CreatedFiles.Add($FinancePath)
    }
    catch [System.UnauthorizedAccessException] {
        $FinanceWriteDenied = $true
    }
    catch {
        if ($_.Exception.Message -match "Access is denied|UnauthorizedAccess") {
            $FinanceWriteDenied = $true
        }
        else {
            throw
        }
    }

    if (-not $FinanceWriteDenied) {
        throw "Security test failed: $Identity could write to \\FS01\Finance$."
    }

    [pscustomobject]@{
        Identity           = $Identity
        ITWrite            = "PASS"
        PublicWrite        = "PASS"
        FinanceWriteDenied = "PASS"
        Overall            = "PASS"
    } | Format-List
}
finally {
    foreach ($File in $CreatedFiles) {
        Remove-Item -LiteralPath $File -Force -ErrorAction SilentlyContinue
    }
}
