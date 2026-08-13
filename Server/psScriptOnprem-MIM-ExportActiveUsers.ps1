<#
.SYNOPSIS
Exports active users from MIM and validates first name and last name length.

.DESCRIPTION
This script connects to MIM, exports active users to a pipe-delimited CSV file,
truncates FirstName to 20 characters and LastName to 30 characters, and creates
separate validation files for names that exceed the allowed length.

.REQUIREMENTS
- PowerShell 5.1
- LithnetRMA module
- Access to MIM Service
#>

#----------------------------------- Settings ------------------------------------------

$ErrorActionPreference = "Stop"

$DateStamp = Get-Date -Format "yyyyMMdd"
$LogDateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

$MIMBaseAddress = "http://localhost:5725"
$EmailDomain = "@lab.local"

$MaxFirstNameLength = 20
$MaxLastNameLength = 30

$CompanyName = "CompanyName"
$LegalEntityName = "LegalEntityName"

$LogFolder = Join-Path $PSScriptRoot "Logs"
$ExportFolder = Join-Path $PSScriptRoot "Exports"
$ValidationFolder = Join-Path $PSScriptRoot "Validation"

$FromMim = Join-Path $ExportFolder "RootFileFromMim_$DateStamp.csv"
$FirstNameValidationFile = Join-Path $ValidationFolder "TruncatedFirstNames_$DateStamp.csv"
$LastNameValidationFile = Join-Path $ValidationFolder "TruncatedLastNames_$DateStamp.csv"

$TranscriptFile = Join-Path $LogFolder "$ScriptName-$LogDateStamp.log"

#----------------------------------- Create folders ------------------------------------------

foreach ($Folder in @($LogFolder, $ExportFolder, $ValidationFolder)) {
    if (-not (Test-Path $Folder)) { New-Item -Path $Folder -ItemType Directory -Force | Out-Null }
}

#----------------------------------- Transcript ------------------------------------------

Start-Transcript -Path $TranscriptFile -Force

try {
    Write-Host "Starting script: $ScriptName" -ForegroundColor Cyan

    #----------------------------------- Modules ------------------------------------------

    $requiredModules = @(
        "LithnetRMA"
    )

    foreach ($module in $requiredModules) {
        Write-Host "`nChecking module: $module" -ForegroundColor Cyan

        if (Get-Module -ListAvailable -Name $module) {
            Write-Host "- Module found - Importing..." -ForegroundColor Green
            Import-Module $module -ErrorAction SilentlyContinue
        }
        else {
            Write-Host "- Module not found! - Installing..." -ForegroundColor Yellow
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
            Import-Module $module -Verbose
        }
    }

    Write-Host "`nAll modules are ready!" -ForegroundColor Green

    #----------------------------------- Clean old files ------------------------------------------

    foreach ($File in @($FromMim, $FirstNameValidationFile, $LastNameValidationFile)) {
        if (Test-Path $File) {
            Write-Host "Removing old file: $File" -ForegroundColor Yellow
            Remove-Item -Path $File -Force
        }
    }

    #----------------------------------- Connect to MIM ------------------------------------------

    Write-Host "`nConnecting to MIM: $MIMBaseAddress" -ForegroundColor Cyan
    Set-ResourceManagementClient -BaseAddress $MIMBaseAddress

    #----------------------------------- Query MIM ------------------------------------------

    Write-Host "`nQuerying active users from MIM..." -ForegroundColor Cyan

    $XPath = "/Person[
        (starts-with(QualityAssuredFirstName, '%')) and
        (starts-with(QualityAssuredLastName, '%')) and
        (ends-with(Email, '$EmailDomain')) and
        (AccountStatus != 'Terminated') and
        (starts-with(QualityAssuredGender, '%'))
    ]"

    $Persons = Search-Resources -XPath $XPath -AttributesToGet @(
        "AccountName",
        "Department",
        "MobilePhone",
        "EmployeeID",
        "OfficePhone",
        "Email",
        "AccountStatus",
        "QualityAssuredGender",
        "QualityAssuredMiddleName",
        "QualityAssuredLastName",
        "QualityAssuredFirstNames",
        "QualityAssuredFirstName"
    )

    #----------------------------------- Helper functions ------------------------------------------

    function Get-SafeSubstring {
        param(
            [AllowNull()]
            [string]$Value,

            [Parameter(Mandatory = $true)]
            [int]$MaxLength
        )
        if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
        if ($Value.Length -le $MaxLength) { return $Value }
        return $Value.Substring(0, $MaxLength)
    }

    function Get-TitleFromGender {
        param(
            [AllowNull()]
            [string]$Gender
        )

        switch ($Gender) {
            "K" { return "ms" }
            "M" { return "mr" }
            default { return "" }
        }
    }

    function Format-MobilePhone {
        param(
            [AllowNull()]
            [string]$MobilePhone
        )

        if ([string]::IsNullOrWhiteSpace($MobilePhone)) {
            return ""
        }

        return ($MobilePhone -replace "-", "")
    }

    #----------------------------------- Build export ------------------------------------------

    Write-Host "`nBuilding export file..." -ForegroundColor Cyan

    $ExportRows = foreach ($Person in $Persons) {
        $OriginalFirstName = [string]$Person.QualityAssuredFirstNames
        $OriginalLastName  = [string]$Person.QualityAssuredLastName

        $TruncatedFirstName = Get-SafeSubstring -Value $OriginalFirstName -MaxLength $MaxFirstNameLength
        $TruncatedLastName  = Get-SafeSubstring -Value $OriginalLastName -MaxLength $MaxLastNameLength

        if ($OriginalFirstName.Length -gt $MaxFirstNameLength) {
            [PSCustomObject]@{
                UniqueID          = $Person.AccountName
                OriginalFirstName = $OriginalFirstName
                TruncatedValue    = $TruncatedFirstName
                Length            = $OriginalFirstName.Length
            } | Export-Csv -Path $FirstNameValidationFile -Delimiter ";" -NoTypeInformation -Encoding UTF8 -Append
        }

        if ($OriginalLastName.Length -gt $MaxLastNameLength) {
            [PSCustomObject]@{
                UniqueID         = $Person.AccountName
                OriginalLastName = $OriginalLastName
                TruncatedValue   = $TruncatedLastName
                Length           = $OriginalLastName.Length
            } | Export-Csv -Path $LastNameValidationFile -Delimiter ";" -NoTypeInformation -Encoding UTF8 -Append
        }

        [PSCustomObject]@{
            Company     = $CompanyName
            LegalEntity = $LegalEntityName
            UniqueID    = $Person.AccountName
            FirstName   = $TruncatedFirstName
            LastName    = $TruncatedLastName
            EmailAdress = $Person.Email
            Title       = Get-TitleFromGender -Gender $Person.QualityAssuredGender
            PhoneMobile = Format-MobilePhone -MobilePhone $Person.MobilePhone
        }
    }

    #----------------------------------- Export CSV ------------------------------------------

    $ExportRows | Export-Csv -Path $FromMim -Delimiter "|" -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "`nExport completed successfully." -ForegroundColor Green
    Write-Host "Users exported: $($ExportRows.Count)" -ForegroundColor Green
    Write-Host "Export file: $FromMim" -ForegroundColor Cyan

    if (Test-Path $FirstNameValidationFile) { Write-Host "First name validation file: $FirstNameValidationFile" -ForegroundColor Yellow }
    if (Test-Path $LastNameValidationFile) { Write-Host "Last name validation file: $LastNameValidationFile" -ForegroundColor Yellow }
}
catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red }
finally { Stop-Transcript }