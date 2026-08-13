<#
.SYNOPSIS
Exports all AD groups and their members from a specific OU to a CSV file.

.DESCRIPTION
This script searches for all Active Directory groups in a specified OU,
retrieves their members, and exports the result to a CSV file.

.REQUIREMENTS
- PowerShell 5.1 or later
- ActiveDirectory module
- Permissions to read AD groups and group members
#>

#----------------------------------- Settings ------------------------------------------

$ErrorActionPreference = "Stop"

$SourceOU = "" # Example: "OU=Groups,DC=domain,DC=local"

$OutputFolder = Join-Path $PSScriptRoot "Files\CsvFiles"
$LogFolder    = Join-Path $PSScriptRoot "Logs"

$DateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ScriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)

$OutputFile = Join-Path $OutputFolder "ADGroupMembersFromOU-$DateStamp.csv"
$TranscriptFile = Join-Path $LogFolder "$ScriptName-$DateStamp.log"

# Modules
$requiredModules = @(
    "ActiveDirectory"
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

#----------------------------------- Prepare folders ------------------------------------------

foreach ($Folder in @($OutputFolder, $LogFolder)) { if (-not (Test-Path $Folder)) { New-Item -Path $Folder -ItemType Directory -Force | Out-Null }}

#----------------------------------- Start logging ------------------------------------------

Start-Transcript -Path $TranscriptFile -Force

try {
    Write-Host "Starting export of AD group members..." -ForegroundColor Cyan
    if ([string]::IsNullOrWhiteSpace($SourceOU)) { throw "SourceOU is empty. Please specify an OU distinguished name."}

    $Groups = Get-ADGroup -Filter * -SearchBase $SourceOU -Properties Description, DistinguishedName
    if (-not $Groups) {
        Write-Host "No groups found in the specified OU." -ForegroundColor Yellow
        return
    }

    $GroupMembers = foreach ($Group in $Groups) {
        Write-Host "Processing group: $($Group.Name)" -ForegroundColor Green
        $Members = Get-ADGroupMember -Identity $Group.DistinguishedName -ErrorAction SilentlyContinue
        if (-not $Members) {
            [PSCustomObject]@{
                GroupName          = $Group.Name
                GroupDescription   = $Group.Description
                GroupDistinguishedName = $Group.DistinguishedName
                MemberName         = ""
                MemberSamAccountName = ""
                MemberObjectClass  = ""
                MemberDistinguishedName = ""
            }
        }
        else {
            foreach ($Member in $Members) {
                [PSCustomObject]@{
                    GroupName              = $Group.Name
                    GroupDescription       = $Group.Description
                    GroupDistinguishedName = $Group.DistinguishedName
                    MemberName             = $Member.Name
                    MemberSamAccountName   = $Member.SamAccountName
                    MemberObjectClass      = $Member.ObjectClass
                    MemberDistinguishedName = $Member.DistinguishedName
                }
            }
        }
    }

    $GroupMembers | Sort-Object GroupName, MemberName | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8 -Delimiter ";" -Force

    Write-Host "Export completed successfully." -ForegroundColor Green
    Write-Host "CSV file: $OutputFile" -ForegroundColor Cyan
}
catch { Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red }
finally { Stop-Transcript }