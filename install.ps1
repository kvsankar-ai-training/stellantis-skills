#Requires -Version 5.1
<#
.SYNOPSIS
    Installs (or uninstalls) Stellantis Copilot skills from this repository into the
    current user's GitHub Copilot skills directory on Windows.

.DESCRIPTION
    Skills live under .\skills\<skill-name>\SKILL.md in this repository. This script
    copies one or all of them into "$env:USERPROFILE\.copilot\skills\<skill-name>\",
    which is where GitHub Copilot (VS Code) discovers user-level skills.

    For skills that ship a requirements.txt, this script also provisions a private
    Python virtual environment inside the installed skill folder and installs the
    dependencies into it, so no manual "pip install" is needed before first use.
    For skills that ship a .env.example, a .env is seeded from it on first install
    (and preserved across re-installs/updates) so credentials only need to be set
    once, in one place, regardless of which project workspace the skill is used from.

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
            if (Test-Path (Join-Path $targetPath '.env')) {
                Write-Warning "'$($skillDir.Name)' has a .env file with credentials that will be deleted."
            }
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

    # Preserve an existing .env (user credentials) across re-installs/updates.
    $existingEnvPath = Join-Path $targetPath '.env'
    $preservedEnvContent = $null
    if (Test-Path $existingEnvPath) {
        $preservedEnvContent = Get-Content -Path $existingEnvPath -Raw
    }

    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
    }
    Copy-Item -Path $skillDir.FullName -Destination $targetPath -Recurse -Force
    Write-Host "Installed skill '$($skillDir.Name)' -> $targetPath" -ForegroundColor Green

    $envPath = Join-Path $targetPath '.env'
    $envExamplePath = Join-Path $targetPath '.env.example'
    if ($preservedEnvContent) {
        Set-Content -Path $envPath -Value $preservedEnvContent -NoNewline
        Write-Host "  Preserved existing .env" -ForegroundColor DarkGray
    }
    elseif (Test-Path $envExamplePath) {
        Copy-Item -Path $envExamplePath -Destination $envPath -Force
        Write-Host "  Seeded .env from .env.example -- edit $envPath with your credentials" -ForegroundColor Yellow
    }

    $requirementsPath = Join-Path $targetPath 'requirements.txt'
    if (Test-Path $requirementsPath) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonCmd) {
            Write-Warning "  python not found on PATH; skipping automatic dependency install for '$($skillDir.Name)'. Run 'pip install -r requirements.txt' in $targetPath manually."
        }
        else {
            $venvPath = Join-Path $targetPath '.venv'
            $venvPython = Join-Path $venvPath 'Scripts\python.exe'
            try {
                if (-not (Test-Path $venvPython)) {
                    Write-Host "  Creating virtual environment..." -ForegroundColor DarkGray
                    & $pythonCmd.Source -m venv $venvPath
                }
                Write-Host "  Installing dependencies into private virtual environment..." -ForegroundColor DarkGray
                & $venvPython -m pip install --quiet --upgrade pip
                & $venvPython -m pip install --quiet -r $requirementsPath
                Write-Host "  Dependencies ready at $venvPython" -ForegroundColor DarkGray
            }
            catch {
                Write-Warning "  Failed to provision virtual environment for '$($skillDir.Name)': $_"
            }
        }
    }
}

Write-Host "`nDone. Restart VS Code (or reload the window) for GitHub Copilot to pick up new/updated skills." -ForegroundColor Cyan
