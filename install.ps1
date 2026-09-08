<#
.SYNOPSIS
  Installs this repo's GlazeWM config on the current PC.

.DESCRIPTION
  Links (or copies) config.yaml to %USERPROFILE%\.glzr\glazewm\config.yaml,
  backing up whatever was there before.

  If machines\$env:COMPUTERNAME\config.yaml exists, that file is installed
  instead of the shared config.yaml — see machines\README.md.

  A symlink is used by default so that `git pull` updates the live config
  with no reinstall. Creating symlinks on Windows requires either Developer
  Mode (Settings > System > For developers) or an elevated shell; if the
  symlink fails, the script falls back to copying the file.

.PARAMETER Copy
  Copy the config instead of symlinking it. Changes pulled later won't apply
  until you re-run this script.

.PARAMETER ConfigPath
  Install a specific config file instead of the auto-detected one.

.PARAMETER NoBackup
  Don't back up the existing config before replacing it.

.PARAMETER NoReload
  Don't tell a running GlazeWM to reload its config afterwards.

.PARAMETER Autostart
  Also add GlazeWM to this user's startup folder so it runs at login.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Copy -Autostart
#>
[CmdletBinding()]
param(
  [switch] $Copy,
  [string] $ConfigPath,
  [switch] $NoBackup,
  [switch] $NoReload,
  [switch] $Autostart
)

$ErrorActionPreference = 'Stop'

function Write-Step  { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "    $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "    $m" -ForegroundColor Yellow }

# --- Work out which config file to install ---------------------------------

$repoRoot = $PSScriptRoot
$machineConfig = Join-Path (Join-Path (Join-Path $repoRoot 'machines') $env:COMPUTERNAME) 'config.yaml'

if ($ConfigPath) {
  $source = (Resolve-Path -LiteralPath $ConfigPath).Path
  Write-Step "Using config from -ConfigPath"
}
elseif (Test-Path -LiteralPath $machineConfig) {
  $source = (Resolve-Path -LiteralPath $machineConfig).Path
  Write-Step "Using machine-specific config for $env:COMPUTERNAME"
}
else {
  $source = Join-Path $repoRoot 'config.yaml'
  if (-not (Test-Path -LiteralPath $source)) {
    throw "Can't find config.yaml in $repoRoot."
  }
  $source = (Resolve-Path -LiteralPath $source).Path
  Write-Step "Using shared config.yaml"
}
Write-Ok $source

# --- Replace the live config -----------------------------------------------

$targetDir = Join-Path (Join-Path $env:USERPROFILE '.glzr') 'glazewm'
$target    = Join-Path $targetDir 'config.yaml'

if (-not (Test-Path -LiteralPath $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  Write-Ok "Created $targetDir"
}

$existing = Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
if ($existing) {
  $isLink = [bool]($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)

  if ($isLink) {
    Write-Step "Removing existing symlink"
  }
  elseif ($NoBackup) {
    Write-Step "Removing existing config (no backup requested)"
  }
  else {
    $backup = "$target.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item -LiteralPath $target -Destination $backup -Force
    Write-Step "Backed up existing config"
    Write-Ok $backup
  }

  Remove-Item -LiteralPath $target -Force
}

$linked = $false
if (-not $Copy) {
  try {
    New-Item -ItemType SymbolicLink -Path $target -Value $source -Force | Out-Null
    $linked = $true
    Write-Step "Symlinked config"
    Write-Ok "$target -> $source"
  }
  catch {
    Write-Warn2 "Couldn't create a symlink ($($_.Exception.Message.Trim()))."
    Write-Warn2 "Enable Developer Mode or run as administrator to symlink. Copying instead."
  }
}

if (-not $linked) {
  Copy-Item -LiteralPath $source -Destination $target -Force
  Write-Step "Copied config"
  Write-Ok $target
  Write-Warn2 "Re-run this script after pulling changes to update the live config."
}

# --- Locate GlazeWM ---------------------------------------------------------

$glazewm = $null
$command = Get-Command 'glazewm.exe' -ErrorAction SilentlyContinue
if ($command) {
  $glazewm = $command.Source
}
else {
  $candidates = @()
  foreach ($pair in @(
    @($env:LOCALAPPDATA, 'Programs\glzr.io\GlazeWM\glazewm.exe'),
    @($env:ProgramFiles,  'glzr.io\GlazeWM\glazewm.exe')
  )) {
    if ($pair[0]) { $candidates += (Join-Path $pair[0] $pair[1]) }
  }
  $glazewm = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $glazewm) {
  Write-Step "GlazeWM not found on this PC"
  Write-Warn2 "Install it with:  winget install GlazeWM"
  Write-Warn2 "The config is in place and will be picked up once GlazeWM is installed."
}

# --- Optional: run at login -------------------------------------------------

if ($Autostart) {
  if (-not $glazewm) {
    Write-Warn2 "Skipping -Autostart: GlazeWM isn't installed yet."
  }
  else {
    $startup  = [Environment]::GetFolderPath('Startup')
    $shortcut = Join-Path $startup 'GlazeWM.lnk'

    $shell = New-Object -ComObject WScript.Shell
    $link  = $shell.CreateShortcut($shortcut)
    $link.TargetPath       = $glazewm
    $link.WorkingDirectory = Split-Path -Parent $glazewm
    $link.Description      = 'GlazeWM tiling window manager'
    $link.Save()

    Write-Step "Added GlazeWM to startup"
    Write-Ok $shortcut
  }
}

# --- Reload a running instance ---------------------------------------------

if (-not $NoReload -and $glazewm) {
  if (Get-Process -Name 'glazewm' -ErrorAction SilentlyContinue) {
    try {
      & $glazewm command wm-reload-config | Out-Null
      Write-Step "Reloaded the running GlazeWM"
    }
    catch {
      Write-Warn2 "Couldn't reload automatically — press alt+shift+r instead."
    }
  }
  else {
    Write-Step "GlazeWM isn't running — start it to pick up the config"
  }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
