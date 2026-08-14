#Requires -Version 5.1
<#
.SYNOPSIS
    Installs (or uninstalls) Stellantis Copilot skills from this repository into the
    current user's GitHub Copilot skills directory on Windows.

.DESCRIPTION
    Skills live under .\skills\<skill-name>\SKILL.md in this repository. This script
    copies one or all of them into "$env:USERPROFILE\.copilot\skills\<skill-name>\",
    which is where GitHub Copilot (VS Code) discovers user-level skills.

.PARAMETER SkillName
    Name of a single skill folder under .\skills to install/uninstall (e.g.
    "stellantis-srs-create"). If omitted, all skills in the repo are processed.

.PARAMETER Uninstall
    Remove the skill(s) from the installed skills directory instead of installing them.

.EXAMPLE
    .\install.ps1
    Installs every skill in this repo for the current user.

.EXAMPLE
    .\install.ps1 -SkillName stellantis-srs-create
    Installs only the stellantis-srs-create skill.

.EXAMPLE
    .\install.ps1 -SkillName stellantis-srs-create -Uninstall
    Removes the installed stellantis-srs-create skill.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SkillName,

    [Parameter(Mandatory = $false)]
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

$repoSkillsRoot = Join-Path $PSScriptRoot 'skills'
$targetSkillsRoot = Join-Path $env:USERPROFILE '.copilot\skills'

if (-not (Test-Path $repoSkillsRoot)) {
    throw "No 'skills' folder found next to this script at: $repoSkillsRoot"
}

if ($SkillName) {
    $sourceSkillDirs = Get-ChildItem -Path $repoSkillsRoot -Directory | Where-Object { $_.Name -eq $SkillName }
    if (-not $sourceSkillDirs) {
        throw "Skill '$SkillName' not found under $repoSkillsRoot"
    }
}
else {
    $sourceSkillDirs = Get-ChildItem -Path $repoSkillsRoot -Directory
}

if (-not $sourceSkillDirs) {
    Write-Warning "No skills found to process under $repoSkillsRoot"
    return
}

if ($Uninstall) {
    foreach ($skillDir in $sourceSkillDirs) {
        $targetPath = Join-Path $targetSkillsRoot $skillDir.Name
        if (Test-Path $targetPath) {
            Remove-Item -Path $targetPath -Recurse -Force
            Write-Host "Removed skill '$($skillDir.Name)' from $targetPath" -ForegroundColor Yellow
        }
        else {
            Write-Host "Skill '$($skillDir.Name)' was not installed at $targetPath (nothing to remove)" -ForegroundColor DarkYellow
        }
    }
    return
}

if (-not (Test-Path $targetSkillsRoot)) {
    New-Item -Path $targetSkillsRoot -ItemType Directory -Force | Out-Null
}

foreach ($skillDir in $sourceSkillDirs) {
    $skillManifest = Join-Path $skillDir.FullName 'SKILL.md'
    if (-not (Test-Path $skillManifest)) {
        Write-Warning "Skipping '$($skillDir.Name)': no SKILL.md found"
        continue
    }

    $targetPath = Join-Path $targetSkillsRoot $skillDir.Name
    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
    }
    Copy-Item -Path $skillDir.FullName -Destination $targetPath -Recurse -Force
    Write-Host "Installed skill '$($skillDir.Name)' -> $targetPath" -ForegroundColor Green
}

Write-Host "`nDone. Restart VS Code (or reload the window) for GitHub Copilot to pick up new/updated skills." -ForegroundColor Cyan
