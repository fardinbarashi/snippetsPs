<#
.SYNOPSIS
Exports active MIM users and maps their manager to AD UserPrincipalName.

.DESCRIPTION
The script:
1. Connects to MIM.
2. Exports active users from MIM.
3. Exports active users from Active Directory.
4. Combines the data and adds the manager UserPrincipalName from AD.

.REQUIREMENTS
- PowerShell 5.1
- ActiveDirectory module
- LithnetRMA module
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ADSearchBase,

    [Parameter(Mandatory = $false)]
    [string]$MIMBaseAddress = "http://localhost:5725",

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludedAccounts = @("XXX", "ZZZ", "OOO")
)

#----------------------------------- Settings ------------------------------------------

$ErrorActionPreference = "Stop"

$DateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

$LogFolder = Join-Path $PSScriptRoot "Logs"
$CsvRoot = Join-Path $PSScriptRoot "CsvFiles"

$FromMimFolder = Join-Path $CsvRoot "FromMim"
$FromADFolder = Join-Path $CsvRoot "FromAD"
$CombinedFolder = Join-Path $CsvRoot "CombinedCsv"

$FromMim = Join-Path $FromMimFolder "FromMim.csv"
$FromAD = Join-Path $FromADFolder "FromAD.csv"
$CombinedCsv = Join-Path $CombinedFolder "AllUsers.csv"

$TranscriptFile = Join-Path $LogFolder "$ScriptName-$DateStamp.log"

#----------------------------------- Prepare folders ------------------------------------------

$Folders = @(
    $LogFolder,
    $FromMimFolder,
    $FromADFolder,
    $CombinedFolder
)

foreach ($Folder in $Folders) {
    if (-not (Test-Path $Folder)) {
        New-Item -Path $Folder -ItemType Directory -Force | Out-Null
    }
}

#----------------------------------- Start logging ------------------------------------------

Start-Transcript -Path $TranscriptFile -Force

try {
    Write-Host "Starting script: $ScriptName" -ForegroundColor Cyan

    #----------------------------------- Modules ------------------------------------------

    $RequiredModules = @(
        "ActiveDirectory",
        "LithnetRMA"
    )

    foreach ($Module in $RequiredModules) {
        Write-Host "Checking module: $Module" -ForegroundColor Cyan

        if (-not (Get-Module -ListAvailable -Name $Module)) {
            Write-Host "Module not found. Installing: $Module" -ForegroundColor Yellow
            Install-Module -Name $Module -Scope CurrentUser -Force -AllowClobber
        }

        Import-Module $Module -ErrorAction Stop
    }

    #----------------------------------- Connect to MIM ------------------------------------------

    Write-Host "Connecting to MIM: $MIMBaseAddress" -ForegroundColor Cyan
    Set-ResourceManagementClient -BaseAddress $MIMBaseAddress

    #----------------------------------- Get MIM users ------------------------------------------

    Write-Host "Querying MIM users..." -ForegroundColor Cyan

    $XPath = "/Person[starts-with(EmployeeID,'%')]"

    $MIMUsers = Search-Resources -XPath $XPath -AttributesToGet @(
        "FirstName",
        "LastName",
        "AccountName",
        "ManagerAccountName"
    ) |
    Where-Object {
        $_.AccountName -and
        $_.AccountName -notin $ExcludedAccounts
    } |
    Select-Object `
        @{Name = "FirstName"; Expression = { $_.FirstName } },
        @{Name = "LastName"; Expression = { $_.LastName } },
        @{Name = "Username"; Expression = { $_.AccountName } },
        @{Name = "MimManager"; Expression = { $_.ManagerAccountName } }

    $MIMUsers |
        Export-Csv -Path $FromMim -NoTypeInformation -Encoding UTF8 -Delimiter ";" -Force

    Write-Host "MIM users exported: $($MIMUsers.Count)" -ForegroundColor Green

    #----------------------------------- Get AD users ------------------------------------------

    Write-Host "Querying AD users..." -ForegroundColor Cyan

    $ADUsers = Get-ADUser `
        -SearchBase $ADSearchBase `
        -Filter "Enabled -eq 'True'" `
        -Properties SamAccountName, UserPrincipalName, Manager |
    Where-Object {
        $_.SamAccountName -notin $ExcludedAccounts
    } |
    Select-Object `
        SamAccountName,
        UserPrincipalName,
        Manager

    # Create lookup table for AD users by DistinguishedName
    $ADUserByDN = @{}

    foreach ($User in $ADUsers) {
        if ($User.DistinguishedName) {
            $ADUserByDN[$User.DistinguishedName] = $User
        }
    }

    # Create manager lookup by SamAccountName
    $ManagerLookup = @{}

    foreach ($User in $ADUsers) {
        if ($User.Manager -and $ADUserByDN.ContainsKey($User.Manager)) {
            $Manager = $ADUserByDN[$User.Manager]

            $ManagerLookup[$Manager.SamAccountName] = [PSCustomObject]@{
                ADManager         = $Manager.SamAccountName
                UserPrincipalName = $Manager.UserPrincipalName
            }
        }
    }

    $ManagerLookup.Values |
        Sort-Object ADManager |
        Export-Csv -Path $FromAD -NoTypeInformation -Encoding UTF8 -Delimiter ";" -Force

    Write-Host "AD manager records exported: $($ManagerLookup.Count)" -ForegroundColor Green

    #----------------------------------- Combine MIM and AD data ------------------------------------------

    Write-Host "Combining MIM and AD data..." -ForegroundColor Cyan

    $CombinedResult = foreach ($MIMUser in $MIMUsers) {
        if ($MIMUser.MimManager -and $ManagerLookup.ContainsKey($MIMUser.MimManager)) {
            [PSCustomObject]@{
                FirstName             = $MIMUser.FirstName
                LastName              = $MIMUser.LastName
                Username              = $MIMUser.Username
                MimManager            = $MIMUser.MimManager
                ManagerUserPrincipalName = $ManagerLookup[$MIMUser.MimManager].UserPrincipalName
            }
        }
        else {
            [PSCustomObject]@{
                FirstName             = $MIMUser.FirstName
                LastName              = $MIMUser.LastName
                Username              = $MIMUser.Username
                MimManager            = $MIMUser.MimManager
                ManagerUserPrincipalName = ""
            }
        }
    }

    $CombinedResult |
        Sort-Object Username |
        Export-Csv -Path $CombinedCsv -NoTypeInformation -Encoding UTF8 -Delimiter ";" -Force

    Write-Host "Combined CSV created: $CombinedCsv" -ForegroundColor Green
    Write-Host "Total combined users: $($CombinedResult.Count)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Stop-Transcript
}