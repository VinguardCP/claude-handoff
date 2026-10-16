<#
.SYNOPSIS
  Moves a Claude Code (terminal) session into Claude Desktop, on the tab and account you choose.
  In Chat and Cowork the whole conversation goes along, exported message by message.

.PARAMETER Target
  code     Same session, in the Code tab (full history, native to Desktop).
  chat     New chat; small transcripts are prefilled, large ones use the clipboard fallback.
  cowork   New Cowork task, with the transcript attached and the project folder.
  export   Only writes the transcript file.
  accounts Lists the accounts in config.json (alias: contas).
  help     Shows usage, accounts, detail levels and note behavior (alias: ajuda).
  test     Checks the installation and opens a test chat on the chosen account.

.EXAMPLE
  .\handoff.ps1 -Target chat -Account work
.EXAMPLE
  .\handoff.ps1 -Target cowork -SessionId 1b2c... -Detail full
.EXAMPLE
  .\handoff.ps1 -Target code -Account work -DryRun
.EXAMPLE
  .\handoff.ps1 -Target test -Account work
#>
[CmdletBinding()]
param(
    [ValidateSet('code', 'chat', 'cowork', 'export', 'accounts', 'contas', 'help', 'ajuda', 'test')]
    [string]$Target = 'code',
    [string]$Account,
    [string]$SessionId,
    [ValidateSet('', 'full', 'normal', 'compact')]
    [string]$Detail = '',
    [int]$MaxChars = -1,
    [string]$NoteFile,
    [string[]]$Folder,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false) } catch { }

$lib = Join-Path $PSScriptRoot 'lib'
foreach ($m in 'I18n', 'Config', 'Desktop', 'Session', 'Transcript') { . (Join-Path $lib "$m.ps1") }

$config = Get-HandoffConfig $PSScriptRoot
Set-HandoffLanguage ([string](Get-Setting $config 'language' 'auto'))

# Localized aliases are accepted by the script too; /handoff --help maps to `help` in SKILL.md.
if ($Target -eq 'contas') { $Target = 'accounts' }
if ($Target -eq 'ajuda') { $Target = 'help' }

# ------------------------------------------------------------------ export

function New-HandoffFileName([string]$Title, [string]$Id) {
    $plain = $Title.Normalize([Text.NormalizationForm]::FormD)
    $plain = -join ($plain.ToCharArray() | Where-Object {
            [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark })
    $slug = ($plain.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).Trim('-') }
    if (-not $slug) { $slug = T 'file.fallback' }
    $short = $Id.Substring(0, [Math]::Min(8, $Id.Length))
    return ('{0}-{1}-{2}.md' -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $slug, $short)
}

function Invoke-Export([string]$Kind) {
    $file = Find-SessionFile $SessionId
    $session = Read-SessionFile $file.FullName

    $level = $Detail
    if (-not $level) { $level = [string](Get-Setting $config "export.$Kind.detail" 'normal') }
    $max = $MaxChars
    if ($max -lt 0) { $max = [int](Get-Setting $config "export.$Kind.maxChars" 0) }
    $redact = [bool](Get-Setting $config 'redactSecrets' $true)

    $note = $null
    if ($NoteFile -and (Test-Path -LiteralPath $NoteFile)) {
        $note = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $NoteFile).Path, [Text.Encoding]::UTF8)
    }

    $doc = ConvertTo-HandoffMarkdown -Session $session -Level $level -MaxChars $max -Note $note -Redact $redact
    $path = Join-Path (Get-HandoffsDir $config) (New-HandoffFileName $doc.Title $session.SessionId)
    [IO.File]::WriteAllText($path, $doc.Markdown, (New-Object Text.UTF8Encoding($false)))

    # The note is temporary: it now lives inside the transcript.
    if ($note -and -not $DryRun) { Remove-Item -LiteralPath $NoteFile -Force -ErrorAction SilentlyContinue }

    $info = T 'out.info' $doc.Turns $doc.Markdown.Length $doc.Level
    if ($doc.Reduced) { $info += T 'out.infoReduced' }
    if ($doc.Omitted -gt 0) { $info += T 'out.infoOmitted' $doc.Omitted }
    if ($doc.Redacted -gt 0) { $info += T 'out.infoRedacted' $doc.Redacted }

    return [pscustomobject]@{ Path = $path; Doc = $doc; Session = $session; Info = (T 'out.transcript' $path $info) }
}

function Write-Opened($Result, [string]$Message) {
    if ($Result) { Write-Output $Result } else { Write-Output $Message }
}

function Write-Check([string]$Kind, [string]$Text) {
    Write-Output ('  ' + (Format-Tag $Kind) + $Text)
}

function Write-HandoffHelp {
    $default = [string](Get-Setting $config 'defaultAccount' 'main')
    $accountNames = @($config.accounts.PSObject.Properties | ForEach-Object {
        $name = $_.Name
        if ($name -ieq $default) { $name + (T 'acc.defaultMark') }
        else { $name }
    })
    $chatDetail = [string](Get-Setting $config 'export.chat.detail' 'normal')
    $coworkDetail = [string](Get-Setting $config 'export.cowork.detail' 'full')
    $exportDetail = [string](Get-Setting $config 'export.export.detail' 'full')
    $chatMax = [int](Get-Setting $config 'export.chat.maxChars' 300000)
    $coworkMax = [int](Get-Setting $config 'export.cowork.maxChars' 600000)
    $exportMax = [int](Get-Setting $config 'export.export.maxChars' 0)

    Write-Output (T 'help.title')
    Write-Output (T 'help.usage')
    Write-Output (T 'help.default')
    Write-Output ''
    Write-Output (T 'help.destinations')
    Write-Output (T 'help.code')
    Write-Output (T 'help.chat')
    Write-Output (T 'help.cowork')
    Write-Output (T 'help.export')
    Write-Output (T 'help.accounts')
    Write-Output ''
    Write-Output (T 'help.accountLine' ($accountNames -join ', '))
    Write-Output ''
    Write-Output (T 'help.detailTitle')
    Write-Output (T 'help.detailFull')
    Write-Output (T 'help.detailNormal')
    Write-Output (T 'help.detailCompact')
    Write-Output (T 'help.detailApplies')
    Write-Output (T 'help.defaultsLine' $chatDetail $coworkDetail $exportDetail)
    Write-Output (T 'help.maxCharsLine' $chatMax $coworkMax $exportMax)
    Write-Output ''
    Write-Output (T 'help.noteTitle')
    Write-Output (T 'help.noteLine')
    Write-Output (T 'help.noteExample')
    Write-Output ''
    Write-Output (T 'help.aliases')
    Write-Output (T 'help.examples')
    Write-Output '  /handoff'
    Write-Output '  /handoff accounts'
    Write-Output '  /handoff chat work full'
    Write-Output '  /handoff cowork work sem nota'
    Write-Output '  /handoff export compact no note'
}

# ------------------------------------------------------------------ destinations

switch ($Target) {
    'help' {
        Write-HandoffHelp
    }

    'accounts' {
        $default = [string](Get-Setting $config 'defaultAccount' 'main')
        $running = Get-RunningClaudeInstances
        Write-Output (T 'acc.title')
        foreach ($p in $config.accounts.PSObject.Properties) {
            $acct = Resolve-HandoffAccount $config $p.Name
            $dir = T 'acc.defaultFolder'
            if ($acct.UserDataDir) { $dir = $acct.UserDataDir }
            $mark = ''
            if ($p.Name -ieq $default) { $mark = T 'acc.defaultMark' }
            Write-Output ('  {0}{1}: {2} -> {3}' -f $p.Name, $mark, $acct.Label, $dir)

            if ($acct.UserDataDir) {
                if (Test-Path -LiteralPath $acct.UserDataDir) { Write-Check 'ok' (T 'acc.folderOk' $acct.UserDataDir) }
                else { Write-Check 'error' (T 'acc.folderMissing' $acct.UserDataDir) }
            }

            if (-not $running.CanInspect) {
                Write-Check 'warn' (T 'acc.processUnknown' $running.Error)
                continue
            }

            $isRunning = Test-ClaudeInstanceRunning $running $acct.UserDataDir
            if ($acct.UserDataDir) {
                if ($isRunning) { Write-Check 'ok' (T 'acc.runningProfile') }
                else {
                    Write-Check 'warn' (T 'acc.notRunningProfile')
                    Write-Output ('          ' + (T 'acc.hintOpen'))
                }
            } else {
                if ($isRunning) { Write-Check 'ok' (T 'acc.runningMain') }
                else { Write-Check 'warn' (T 'acc.notRunningMain') }
            }
        }
        Write-Output ''
        Write-Output (T 'acc.usageHint')
    }

    'test' {
        $acct = Resolve-HandoffAccount $config $Account
        Write-Output (T 'test.title')
        Write-Check 'ok' (T 'test.ps' $PSVersionTable.PSVersion)
        Write-Check 'ok' (T 'test.config' @($config.accounts.PSObject.Properties).Count (Get-HandoffLanguage))

        $projects = Get-ProjectsDir
        if (Test-Path -LiteralPath $projects) {
            $count = @(Get-ChildItem -LiteralPath $projects -Filter '*.jsonl' -File -Recurse -Depth 1 -ErrorAction SilentlyContinue).Count
            Write-Check 'ok' (T 'test.sessions' $count $projects)
        } else {
            Write-Check 'warn' (T 'test.noSessions' $projects)
        }

        $proto = $null
        try { $proto = Test-Path -LiteralPath 'Registry::HKEY_CLASSES_ROOT\claude' -ErrorAction Stop } catch { }
        if ($proto -eq $true) { Write-Check 'ok' (T 'test.protoOk') }
        elseif ($proto -eq $false) { Write-Check 'error' (T 'test.protoMissing') }
        else { Write-Check 'warn' (T 'test.protoUnknown') }

        $exe = $null
        try { $exe = Find-ClaudeExe $config; Write-Check 'ok' (T 'test.exe' $exe) }
        catch {
            # Only needed for accounts with userDataDir; the main one opens through the protocol.
            if ($acct.UserDataDir) { Write-Check 'error' $_.Exception.Message }
            else { Write-Check 'warn' (T 'test.exeOnlyNeeded' $_.Exception.Message) }
        }

        if ($acct.UserDataDir) {
            if (Test-Path -LiteralPath $acct.UserDataDir) { Write-Check 'ok' (T 'test.dataDirOk' $acct.Name $acct.UserDataDir) }
            else {
                Write-Check 'error' (T 'test.dataDirMissing' $acct.Name $acct.UserDataDir)
                Write-Output (T 'test.stopDataDir')
                break
            }
            if (-not $exe) { Write-Output (T 'test.stopExe'); break }
        } else {
            Write-Check 'ok' (T 'test.mainInstance' $acct.Name)
        }

        $url = New-DesktopUrl 'claude://claude.ai/new' @(, @('q', (T 'test.prompt' $acct.Name $acct.Label)))
        $r = Open-DesktopUrl $url $acct $config -DryRun:$DryRun
        Write-Opened $r (T 'test.opened' $acct.Label)
    }

    'export' {
        $x = Invoke-Export 'export'
        Write-Output $x.Info
    }

    'code' {
        $acct = Resolve-HandoffAccount $config $Account
        if (-not $SessionId) { $SessionId = [IO.Path]::GetFileNameWithoutExtension((Find-SessionFile '').Name) }
        $url = New-DesktopUrl 'claude://resume' @(, @('session', $SessionId))
        $r = Open-DesktopUrl $url $acct $config -DryRun:$DryRun
        Write-Opened $r (T 'code.opened' $SessionId $acct.Label)
        Write-Output (T 'code.exit')
    }

    'chat' {
        $acct = Resolve-HandoffAccount $config $Account
        $x = Invoke-Export 'chat'
        Write-Output $x.Info

        $plan = New-ChatOpenPlan -Prompt (T 'chat.prompt') -Transcript $x.Doc.Markdown -MaxPromptChars $script:ChatAutoFillMaxPromptChars -MaxUrlChars $script:ChatAutoFillMaxUrlChars
        if (-not $plan.AutoFill -and -not $DryRun) { Set-Clipboard -Value $x.Doc.Markdown }

        $r = Open-DesktopUrl $plan.Url $acct $config -DryRun:$DryRun
        if ($r) { Write-Output $r }
        elseif ($plan.AutoFill) { Write-Output (T 'chat.openedAuto' $acct.Label) }
        else { Write-Output (T 'chat.openedClipboard' $acct.Label $plan.PromptLength) }
    }

    'cowork' {
        $acct = Resolve-HandoffAccount $config $Account
        $x = Invoke-Export 'cowork'
        Write-Output $x.Info
        $pairs = @(, @('q', (T 'cowork.prompt' (Split-Path -Leaf $x.Path))))
        $pairs += , @('file', $x.Path)
        $folders = @($Folder | Where-Object { $_ })
        if ($folders.Count -eq 0 -and $x.Session.Cwd) { $folders = @($x.Session.Cwd) }
        foreach ($f in $folders) {
            if (Test-Path -LiteralPath $f) { $pairs += , @('folder', (Resolve-Path -LiteralPath $f).Path) }
        }
        $url = New-DesktopUrl 'claude://cowork/new' $pairs
        $r = Open-DesktopUrl $url $acct $config -DryRun:$DryRun
        Write-Opened $r (T 'cowork.opened' $acct.Label)
    }
}
