<#
.SYNOPSIS
    Install a specific OpenCode v2 CLI build side-by-side and optionally switch the launcher shim.

.DESCRIPTION
    The repo's CLI is a pinned side-by-side install:

        ~/.local/opt/opencode-<version>/opencode.exe
        ~/.local/bin/opencode.cmd        (shim that hard-codes one of them)

    `opencode upgrade` does not maintain that layout: it installs to its own
    directory and leaves the shim pointing at the old build. This script
    reproduces the official v2 installer's asset resolution
    (https://opencode.ai/v2/install) while keeping every version on disk.

    Installs are additive. Nothing is deleted, so rollback is a one-line shim
    edit. The shim is only replaced with -Switch, and the previous shim is
    backed up first.

.PARAMETER Version
    Version to install, with or without a leading v. Example: 2.2.7

.PARAMETER Switch
    Point ~/.local/bin/opencode.cmd at the newly installed build.

.EXAMPLE
    powershell -File tools/install-opencode-cli.ps1 2.2.7
    powershell -File tools/install-opencode-cli.ps1 2.2.7 -Switch
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version,

    [switch]$Switch,

    [string]$OptRoot = (Join-Path $env:USERPROFILE '.local\opt'),
    [string]$BinDir = (Join-Path $env:USERPROFILE '.local\bin')
)

$ErrorActionPreference = 'Stop'

$Version = $Version.TrimStart('v')
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must look like 2.2.7 (got '$Version')."
}

# A relative -OptRoot would leak into the generated shim and break it outside
# this directory, so resolve both roots before anything uses them.
$OptRoot = [System.IO.Path]::GetFullPath($OptRoot)
$BinDir  = [System.IO.Path]::GetFullPath($BinDir)

$package   = '@opencode/cli-windows-x64'
$tarball   = "https://registry.npmjs.org/$package/-/cli-windows-x64-$Version.tgz"
$targetDir = Join-Path $OptRoot "opencode-$Version"
$targetExe = Join-Path $targetDir 'opencode.exe'

Write-Host "Target: $targetExe"

function Get-ReportedVersion {
    param([string]$Text)
    if ($Text -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    return $null
}

# A binary that prints the right version and then exits nonzero is not a
# usable install, so the exit status is part of the check.
function Get-InstalledVersion {
    param([string]$Exe)
    $text = (& $Exe --version) 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return (Get-ReportedVersion $text)
}

$needsDownload = $true
if (Test-Path $targetExe) {
    $haveVersion = Get-InstalledVersion $targetExe
    if ($haveVersion -eq $Version) {
        Write-Host "Already installed: opencode v$haveVersion"
        $needsDownload = $false
    }
    else {
        Write-Host "Existing binary reports 'v$haveVersion'; reinstalling."
    }
}

if ($needsDownload) {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('opencode-install-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    try {
        $tgz = Join-Path $tmp 'cli.tgz'
        Write-Host "Downloading $tarball"
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            & curl.exe -fL --silent --show-error -o $tgz $tarball
            if ($LASTEXITCODE -ne 0) { throw "curl failed with exit code $LASTEXITCODE" }
        }
        else {
            Invoke-WebRequest -Uri $tarball -OutFile $tgz -UseBasicParsing
        }

        $extract = Join-Path $tmp 'x'
        New-Item -ItemType Directory -Path $extract -Force | Out-Null
        & tar.exe -xzf $tgz -C $extract
        if ($LASTEXITCODE -ne 0) { throw "tar failed with exit code $LASTEXITCODE" }

        $bin = Join-Path $extract 'package\bin\opencode.exe'
        if (-not (Test-Path $bin)) { throw "Unexpected archive layout: $bin missing." }

        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Copy-Item $bin $targetExe -Force
    }
    finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$reportedVersion = Get-InstalledVersion $targetExe
if ($reportedVersion -ne $Version) {
    throw "Installed binary reports 'v$reportedVersion', expected $Version."
}
Write-Host "Verified: opencode v$reportedVersion"

if ($Switch) {
    if (-not (Test-Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }
    $shim = Join-Path $BinDir 'opencode.cmd'
    if (Test-Path $shim) {
        $backup = "$shim.bak-" + (Get-Date -Format 'yyyyMMddHHmmss')
        Copy-Item $shim $backup
        Write-Host "Backed up shim -> $backup"
    }

    # cmd.exe expands %NAME% even inside quotes, so a literal percent in the
    # path must be doubled. %* stays unescaped so launcher arguments forward.
    $shimExe  = $targetExe -replace '%', '%%'
    $shimLine = '"' + $shimExe + '" %*'
    $content  = "@echo off`r`n" +
                "rem Pinned opencode v$Version (side-by-side install; previous versions kept under .local\opt).`r`n" +
                "$shimLine`r`n"

    # ASCII would replace non-ASCII path characters with '?', producing a shim
    # that cannot launch the binary it just verified. Write in the console's
    # OEM code page, which cmd.exe reads correctly on this machine.
    $oem = [System.Text.Encoding]::GetEncoding(
        [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.OEMCodePage)
    [System.IO.File]::WriteAllText($shim, $content, $oem)

    Write-Host "Shim now launches v$Version : $shim"
}

Write-Host ''
Write-Host 'Installed builds:'
Get-ChildItem $OptRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'opencode-*' } |
    ForEach-Object { '  ' + $_.Name }

Write-Host ''
Write-Host "Rollback: set $BinDir\opencode.cmd back to an earlier build, for example"
Write-Host '  "%USERPROFILE%\.local\opt\opencode-2.2.2\opencode.exe" %*'
