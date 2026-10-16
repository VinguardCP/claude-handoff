# Configuration: config.json, accounts and Claude Code folders.

function Get-ClaudeConfigDir {
    if ($env:CLAUDE_CONFIG_DIR) { return $env:CLAUDE_CONFIG_DIR }
    return (Join-Path $HOME '.claude')
}

function Get-HandoffConfig([string]$SkillDir) {
    $path = Join-Path $SkillDir 'config.json'
    if (-not (Test-Path -LiteralPath $path)) {
        throw (T 'err.configMissing' $SkillDir)
    }
    try {
        return ([IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json -ErrorAction Stop)
    } catch {
        $detail = [string]$_.Exception.Message
        if ($detail) { $detail = ($detail -replace '[\r\n]+', ' ').Trim() }
        throw (T 'err.configInvalid' $path $detail)
    }
}

# Reads a nested value ("export.chat.maxChars"), with a default when missing.
function Get-Setting($Object, [string]$Path, $Default) {
    $cur = $Object
    foreach ($part in $Path.Split('.')) {
        if ($null -eq $cur) { return $Default }
        $prop = $cur.PSObject.Properties[$part]
        if ($null -eq $prop) { return $Default }
        $cur = $prop.Value
    }
    if ($null -eq $cur) { return $Default }
    if ($cur -is [string] -and $cur -eq '') { return $Default }
    return $cur
}

function Expand-ConfigPath([string]$Path) {
    if (-not $Path) { return $null }
    return [Environment]::ExpandEnvironmentVariables($Path)
}

function Resolve-HandoffAccount($Config, [string]$Name) {
    if (-not $Name) { $Name = [string](Get-Setting $Config 'defaultAccount' 'main') }

    $names = @($Config.accounts.PSObject.Properties | ForEach-Object { $_.Name })
    $match = $names | Where-Object { $_ -ieq $Name } | Select-Object -First 1
    if (-not $match) {
        throw (T 'err.accountMissing' $Name ($names -join ', '))
    }

    $entry = $Config.accounts.$match
    $dir = Expand-ConfigPath ([string](Get-Setting $entry 'userDataDir' ''))
    # Without a label: the main instance gets a friendly name, the others use their key.
    $fallback = $match
    if (-not $dir) { $fallback = T 'acc.mainLabel' }
    return [pscustomobject]@{
        Name        = $match
        Label       = [string](Get-Setting $entry 'label' $fallback)
        UserDataDir = $dir
    }
}

function Get-HandoffsDir($Config) {
    $dir = Expand-ConfigPath ([string](Get-Setting $Config 'handoffsDir' ''))
    if (-not $dir) { $dir = Join-Path (Get-ClaudeConfigDir) 'handoffs' }
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}
