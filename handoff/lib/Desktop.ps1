# Claude Desktop: find the app, build claude:// links and open them in the right instance.
#
# The main instance receives links through the protocol registered in Windows (that's what the
# native /desktop does). Other instances only receive them when claude.exe is started with the
# same --user-data-dir; Electron forwards the link to the window already open with that folder.

function Find-ClaudeExe($Config) {
    $custom = Expand-ConfigPath ([string](Get-Setting $Config 'claudeExe' ''))
    if ($custom) {
        if (Test-Path -LiteralPath $custom) { return $custom }
        throw (T 'err.exeInvalid' $custom)
    }

    # 1) MSIX package (official download and Microsoft Store). Keeps up with updates by itself.
    if (Get-Command Get-AppxPackage -ErrorAction SilentlyContinue) {
        $pkg = Get-AppxPackage -Name 'Claude' -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $pkg) {
            $pkg = Get-AppxPackage -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like '*Claude*' } | Select-Object -First 1
        }
        if ($pkg) {
            $exe = Join-Path (Join-Path $pkg.InstallLocation 'app') 'claude.exe'
            if (Test-Path -LiteralPath $exe) { return $exe }
        }
    }

    # 2) Older install in %LOCALAPPDATA%\AnthropicClaude\app-x.y.z
    if ($env:LOCALAPPDATA) {
        $root = Join-Path $env:LOCALAPPDATA 'AnthropicClaude'
        if (Test-Path -LiteralPath $root) {
            $latest = Get-ChildItem -LiteralPath $root -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
                Sort-Object { try { [version]($_.Name.Substring(4)) } catch { [version]'0.0' } } -Descending |
                Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'claude.exe') } |
                Select-Object -First 1
            if ($latest) { return (Join-Path $latest.FullName 'claude.exe') }
        }
    }

    throw (T 'err.exeMissing')
}

# Returns the value passed to --user-data-dir in a Windows process command line.
# Supports --user-data-dir="C:\path", --user-data-dir "C:\path" and unquoted values.
function Get-UserDataDirFromCommandLine([string]$CommandLine) {
    if (-not $CommandLine) { return $null }
    $pattern = '(?i)(?:^|\s)--user-data-dir(?:=|\s+)(?:"([^"]+)"|''([^'']+)''|([^\s"]+))'
    $m = [regex]::Match($CommandLine, $pattern)
    if (-not $m.Success) { return $null }
    foreach ($i in 1..3) {
        if ($m.Groups[$i].Success -and $m.Groups[$i].Value) { return $m.Groups[$i].Value }
    }
    return $null
}

function Normalize-HandoffPath([string]$Path) {
    if (-not $Path) { return $null }
    $expanded = [Environment]::ExpandEnvironmentVariables($Path).Trim().Trim('"')
    try { $expanded = [IO.Path]::GetFullPath($expanded) } catch { }
    return $expanded.TrimEnd('\', '/')
}

# Looks at the command lines of the Claude processes that are running right now.
# This lets `-Target accounts` verify the profile folder instead of only trusting config.json.
function Get-RunningClaudeInstances {
    try {
        if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
            $processes = @(Get-CimInstance Win32_Process -Filter "Name='claude.exe'" -ErrorAction Stop)
        } elseif (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
            $processes = @(Get-WmiObject Win32_Process -Filter "Name='claude.exe'" -ErrorAction Stop)
        } else {
            throw 'Win32_Process is unavailable.'
        }
    } catch {
        return [pscustomobject]@{ CanInspect = $false; Error = [string]$_.Exception.Message; Instances = @() }
    }

    $seen = @{}
    $instances = foreach ($p in $processes) {
        $cmd = [string]$p.CommandLine
        if (-not $cmd) { continue }
        # Ignore renderer/GPU/utility children. Only the browser process identifies an instance.
        if ($cmd -match '(?i)(?:^|\s)--type(?:=|\s+)') { continue }

        $dir = Get-UserDataDirFromCommandLine $cmd
        $key = '__main__'
        if ($dir) { $key = (Normalize-HandoffPath $dir).ToLowerInvariant() }
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        [pscustomobject]@{
            UserDataDir = if ($dir) { Normalize-HandoffPath $dir } else { $null }
            ProcessId   = $p.ProcessId
        }
    }
    return [pscustomobject]@{ CanInspect = $true; Error = ''; Instances = @($instances) }
}

function Test-ClaudeInstanceRunning($Snapshot, [string]$UserDataDir) {
    if (-not $Snapshot -or -not $Snapshot.CanInspect) { return $null }
    $wanted = Normalize-HandoffPath $UserDataDir
    foreach ($i in @($Snapshot.Instances)) {
        if (-not $wanted -and -not $i.UserDataDir) { return $true }
        if ($wanted -and $i.UserDataDir -and ((Normalize-HandoffPath $i.UserDataDir) -ieq $wanted)) { return $true }
    }
    return $false
}

# Opens a registered Windows protocol through PowerShell's normal ShellExecute path.
#
# Do not replace this with rundll32 url.dll,FileProtocolHandler: on some Windows/MSIX
# Claude installs that call can return successfully without actually dispatching claude://.
# Start-Process $Url is the same reliable path used by the original implementation.
function Open-WindowsProtocolUrl([string]$Url) {
    Start-Process -FilePath $Url -ErrorAction Stop
}

# Key/value pairs; the same key may repeat (file=..&file=..).
function New-DesktopUrl([string]$Base, [object[]]$Pairs) {
    $parts = foreach ($p in $Pairs) {
        if ($null -ne $p[1] -and [string]$p[1] -ne '') {
            '{0}={1}' -f $p[0], [Uri]::EscapeDataString([string]$p[1])
        }
    }
    $query = (@($parts) -join '&')
    if ($query) { return "$Base`?$query" }
    return $Base
}

# Claude documents that text passed in the chat deep-link `q` parameter is truncated at
# roughly 14,000 characters. That limit applies to the decoded prompt text, not to the
# percent-encoded URL length. Keep a little headroom and also guard the Windows command-line
# size after encoding. This lets short/medium transcripts autofill much more often without
# risking silent truncation of the handoff.
$script:ChatAutoFillMaxPromptChars = 13000
$script:ChatAutoFillMaxUrlChars = 30000

function New-ChatOpenPlan(
    [string]$Prompt,
    [string]$Transcript,
    [int]$MaxPromptChars = 13000,
    [int]$MaxUrlChars = 30000
) {
    $base = 'claude://claude.ai/new'
    $combined = ($Prompt.TrimEnd() + "`r`n`r`n---`r`n`r`n" + $Transcript)

    # Decide first by the decoded q text length so URL encoding expansion does not
    # trigger the clipboard fallback before Claude's actual q limit.
    if ($combined.Length -le $MaxPromptChars) {
        $autoUrl = New-DesktopUrl $base @(, @('q', $combined))
        if ($autoUrl.Length -le $MaxUrlChars) {
            return [pscustomobject]@{
                Url = $autoUrl
                AutoFill = $true
                UrlLength = $autoUrl.Length
                PromptLength = $combined.Length
                FallbackReason = ''
            }
        }
        $reason = 'encoded-url'
    } else {
        $reason = 'prompt-limit'
    }

    $fallbackUrl = New-DesktopUrl $base @(, @('q', $Prompt))
    return [pscustomobject]@{
        Url = $fallbackUrl
        AutoFill = $false
        UrlLength = $fallbackUrl.Length
        PromptLength = $combined.Length
        FallbackReason = $reason
    }
}

function Open-DesktopUrl([string]$Url, $Account, $Config, [switch]$DryRun) {
    if (-not $Account.UserDataDir) {
        if ($DryRun) { return (T 'dry.protocol' $Url) }
        Open-WindowsProtocolUrl $Url
        return $null
    }

    $exe = Find-ClaudeExe $Config
    $argLine = '--user-data-dir="{0}" "{1}"' -f $Account.UserDataDir, $Url
    if ($DryRun) { return "[dry-run] `"$exe`" $argLine" }
    if (-not (Test-Path -LiteralPath $Account.UserDataDir)) {
        throw (T 'err.dataDirMissing' $Account.Name $Account.UserDataDir)
    }
    # Electron can print harmless disk-cache access errors while a short-lived second
    # process forwards the URL to an already-running profile. Keep those child-process
    # diagnostics out of the caller's PowerShell; Start-Process failures still throw.
    try {
        Start-Process -FilePath $exe -ArgumentList $argLine -RedirectStandardError 'NUL' -ErrorAction Stop
    } catch {
        # Very old/restricted PowerShell environments can reject standard-error redirection.
        # Opening the Desktop is more important than hiding the cosmetic Chromium messages.
        Start-Process -FilePath $exe -ArgumentList $argLine -ErrorAction Stop
    }
    return $null
}
