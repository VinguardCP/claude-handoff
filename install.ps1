# Installs, updates or removes the /handoff skill for Claude Code.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'handoff'
. (Join-Path (Join-Path $src 'lib') 'I18n.ps1')

$configDir = $env:CLAUDE_CONFIG_DIR
if (-not $configDir) { $configDir = Join-Path $HOME '.claude' }
$dest = Join-Path (Join-Path $configDir 'skills') 'handoff'
$destConfig = Join-Path $dest 'config.json'

# Speak the language already chosen in the installed config.json, if there is one.
if (Test-Path -LiteralPath $destConfig) {
    try {
        $current = [IO.File]::ReadAllText($destConfig, [Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($current.language) { Set-HandoffLanguage ([string]$current.language) }
    } catch { }
}

if ($Uninstall) {
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    Write-Host (T 'inst.removed' $dest)
    Write-Host (T 'inst.keptTranscripts' (Join-Path $configDir 'handoffs'))
    return
}

$hadConfig = Test-Path -LiteralPath $destConfig
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Copies everything, keeping the config.json of anyone who already has one.
Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length).TrimStart('\', '/')
    $target = Join-Path $dest $rel
    if ($rel -eq 'config.json' -and $hadConfig) { return }
    $parent = Split-Path -Parent $target
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
}

# Migration from the first version (accounts.json) to config.json.
$oldAccounts = Join-Path $dest 'accounts.json'
if (-not $hadConfig -and (Test-Path -LiteralPath $oldAccounts)) {
    $old = [IO.File]::ReadAllText($oldAccounts, [Text.Encoding]::UTF8) | ConvertFrom-Json
    $cfg = [IO.File]::ReadAllText($destConfig, [Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($old.accounts) { $cfg.accounts = $old.accounts }
    if ($old.default) { $cfg.defaultAccount = $old.default }
    if ($old.claudeExe) { $cfg.claudeExe = $old.claudeExe }
    [IO.File]::WriteAllText($destConfig, ($cfg | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $oldAccounts -Destination "$oldAccounts.bak" -Force
    Write-Host (T 'inst.migrated')
}

if ($hadConfig) { Write-Host (T 'inst.updated' $dest) }
else { Write-Host (T 'inst.installed' $dest) }
Write-Host (T 'inst.next')
