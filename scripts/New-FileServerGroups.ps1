[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GroupOU = "OU=Groups,OU=Company,DC=corp,DC=example,DC=test"
)

$ErrorActionPreference = "Stop"
Import-Module ActiveDirectory

Get-ADOrganizationalUnit -Identity $GroupOU | Out-Null

$Mappings = [ordered]@{
    "DL_FS01_Finance_RW" = "GG_Finance_Users"
    "DL_FS01_Sales_RW"   = "GG_Sales_Users"
    "DL_FS01_Mgmt_RW"    = "GG_Management_Users"
    "DL_FS01_IT_RW"      = "GG_IT_Users"
    "DL_FS01_Public_RW"  = "GG_All_Employees"
}

foreach ($GroupName in $Mappings.Keys) {
    $MemberName = $Mappings[$GroupName]
    $Group = Get-ADGroup -Filter "SamAccountName -eq '$GroupName'" -SearchBase $GroupOU

    if (-not $Group -and $PSCmdlet.ShouldProcess($GroupName, "Create domain-local security group")) {
        $Group = New-ADGroup `
            -Name $GroupName `
            -SamAccountName $GroupName `
            -GroupScope DomainLocal `
            -GroupCategory Security `
            -Path $GroupOU `
            -PassThru
    }

    # With -WhatIf a missing group is intentionally not created. Skip dependent
    # membership operations instead of passing a null identity to AD cmdlets.
    if (-not $Group) {
        continue
    }

    $Member = Get-ADGroup -Identity $MemberName
    $AlreadyMember = Get-ADGroupMember -Identity $Group |
        Where-Object DistinguishedName -eq $Member.DistinguishedName

    if (-not $AlreadyMember -and $PSCmdlet.ShouldProcess($GroupName, "Add $MemberName")) {
        Add-ADGroupMember -Identity $Group -Members $Member
    }
}

$Mappings.Keys | ForEach-Object {
    Get-ADGroup -Identity $_ -Properties Members -ErrorAction SilentlyContinue |
        Select-Object Name, GroupScope, GroupCategory, Members
}
