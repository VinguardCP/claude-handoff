# Transcript: turns the active conversation into Markdown another Claude can read.
#
# Included: your messages, Claude's replies, every tool used (command, file, edit) with its
# result, and /compact markers. Left out: the model's internal reasoning, system messages and
# subagents.
#
# Detail levels (each turn may drop a level to fit the limit):
#   full    - long outputs and contents, cut only when very large
#   normal  - outputs and contents trimmed to their beginning and end
#   compact - only what was done, no output (errors on one line)

$script:Levels = @('full', 'normal', 'compact')

$script:LevelSpec = @{
    full    = @{ Text = 0;     Result = 6000; Content = 6000; Read = 2000 }
    normal  = @{ Text = 20000; Result = 1200; Content = 1500; Read = 0 }
    compact = @{ Text = 3000;  Result = 0;    Content = 0;    Read = 0 }
}

$script:RecentTurns = 8

# {MASK} and {KEY} are replaced by the mask text of the current language.
$script:AlreadyMasked = '(?!\[(?:oculto|hidden)\])'
$script:SecretRules = @(
    @{ P = '-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'; R = '{KEY}' }
    @{ P = '\bsk-ant-[A-Za-z0-9_\-]{20,}'; R = '{MASK}' }
    @{ P = '\bsk-[A-Za-z0-9_\-]{20,}'; R = '{MASK}' }
    @{ P = '\bgh[pousr]_[A-Za-z0-9]{30,}'; R = '{MASK}' }
    @{ P = '\bgithub_pat_[A-Za-z0-9_]{30,}'; R = '{MASK}' }
    @{ P = '\bAKIA[0-9A-Z]{16}\b'; R = '{MASK}' }
    @{ P = '\bxox[abprs]-[A-Za-z0-9\-]{10,}'; R = '{MASK}' }
    @{ P = '\bAIza[0-9A-Za-z_\-]{35}\b'; R = '{MASK}' }
    @{ P = '\beyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}'; R = '{MASK}' }
    @{ P = '(?i)(\bbearer\s+)[A-Za-z0-9._\-~+/]{16,}=*'; R = '$1{MASK}' }
    # .env lines: NAME_WITH_KEY/TOKEN/SECRET/PASSWORD/SENHA=value
    @{ P = '(?m)^(\s*(?:export\s+)?[A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASSWD|PWD|SENHA)[A-Z0-9_]*\s*=\s*)' + $script:AlreadyMasked + '\S+'; R = '$1{MASK}' }
    # Connection strings: Password=...; Pwd=...; Senha=...
    @{ P = '(?i)(\b(?:password|pwd|senha)\s*=\s*)' + $script:AlreadyMasked + '[^;\s"''<>]+'; R = '$1{MASK}' }
)

# ------------------------------------------------------------------ text helpers

function Protect-Secrets([string]$Text, [ref]$Count) {
    if (-not $Text) { return $Text }
    $mask = T 'md.mask'
    $keyMask = T 'md.maskKey'
    foreach ($rule in $script:SecretRules) {
        $n = [regex]::Matches($Text, $rule.P).Count
        if ($n -gt 0) {
            $Count.Value += $n
            $Text = [regex]::Replace($Text, $rule.P, $rule.R.Replace('{MASK}', $mask).Replace('{KEY}', $keyMask))
        }
    }
    return $Text
}

function Limit-Text([string]$Text, [int]$Max) {
    if ($null -eq $Text) { return '' }
    if ($Max -le 0 -or $Text.Length -le $Max) { return $Text }
    $head = [int]($Max * 0.6)
    $tail = $Max - $head
    $omit = $Text.Length - $Max
    return $Text.Substring(0, $head) + "`n" + (T 'md.omittedChars' $omit) + "`n" + $Text.Substring($Text.Length - $tail)
}

function Format-Fence([string]$Text, [string]$Lang = '') {
    $longest = 0
    foreach ($m in [regex]::Matches($Text, '`+')) { if ($m.Length -gt $longest) { $longest = $m.Length } }
    $fence = '`' * [Math]::Max(3, $longest + 1)
    return "$fence$Lang`n$($Text.TrimEnd())`n$fence"
}

function Get-FirstLine([string]$Text, [int]$Max = 160) {
    if (-not $Text) { return '' }
    $line = ($Text.Trim() -split "`r?`n")[0]
    if ($line.Length -gt $Max) { $line = $line.Substring(0, $Max) + '...' }
    return $line
}

function Get-FenceLang([string]$Path) {
    if (-not $Path) { return '' }
    $ext = [IO.Path]::GetExtension($Path).TrimStart('.').ToLowerInvariant()
    $map = @{ ps1 = 'powershell'; psm1 = 'powershell'; py = 'python'; js = 'javascript'; ts = 'typescript'
        tsx = 'tsx'; jsx = 'jsx'; cs = 'csharp'; sql = 'sql'; php = 'php'; json = 'json'; md = 'markdown'
        html = 'html'; css = 'css'; xml = 'xml'; yml = 'yaml'; yaml = 'yaml'; sh = 'bash'; bat = 'bat' }
    if ($map.ContainsKey($ext)) { return $map[$ext] }
    return $ext
}

function ConvertTo-LocalTime($Value) {
    if ($null -eq $Value) { return $null }
    try {
        if ($Value -is [datetime]) { $dt = $Value }
        else {
            $dt = [datetime]::Parse([string]$Value, [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::RoundtripKind)
        }
        if ($dt.Kind -ne [DateTimeKind]::Local) { $dt = $dt.ToLocalTime() }
        return $dt
    } catch { return $null }
}

function Format-Time($Dt) {
    if ($null -eq $Dt) { return '' }
    return $Dt.ToString((T 'fmt.time'))
}

# Removes the noise Claude Code injects into user messages.
function Get-CleanUserText([string]$Text) {
    if (-not $Text) { return '' }
    $t = [regex]::Replace($Text, '(?s)<system-reminder>.*?</system-reminder>', '')
    $cmd = [regex]::Match($t, '(?s)<command-name>(.*?)</command-name>')
    if ($cmd.Success) {
        $cmdArgs = [regex]::Match($t, '(?s)<command-args>(.*?)</command-args>').Groups[1].Value.Trim()
        return (T 'md.command' ($cmd.Groups[1].Value.Trim() + ' ' + $cmdArgs).Trim())
    }
    $t = [regex]::Replace($t, '(?s)<local-command-(stdout|stderr)>.*?</local-command-\1>', '')
    $t = [regex]::Replace($t, '(?s)<command-message>.*?</command-message>', '')
    return $t.Trim()
}

function Get-ResultText($Result) {
    if ($null -eq $Result) { return $null }
    $c = $Result.content
    if ($null -eq $c) { return '' }
    if ($c -is [string]) { return $c }
    $parts = foreach ($x in @($c)) {
        if ($x.type -eq 'text') { [string]$x.text }
        elseif ($x.type -eq 'image') { T 'md.image' }
    }
    return (@($parts) -join "`n")
}

# ------------------------------------------------------------------ building turns

# A turn starts at each of your messages and runs until the next one.
function Get-TranscriptTurns($Chain) {
    $results = @{}
    $hasEarlierTurns = $false
    foreach ($e in $Chain) {
        if ($e.type -eq 'user' -and $e.message -and $e.message.content -isnot [string]) {
            foreach ($b in @($e.message.content)) {
                if ($b.type -eq 'tool_result' -and $b.tool_use_id) { $results[[string]$b.tool_use_id] = $b }
            }
        }
    }

    $turns = New-Object System.Collections.Generic.List[object]
    $current = $null

    foreach ($e in $Chain) {
        if ($e.isSidechain) { continue }
        $ts = ConvertTo-LocalTime $e.timestamp

        if ($e.type -eq 'system') {
            if ($e.subtype -eq 'compact_boundary') {
                if ($null -ne $current) { $current.Blocks.Add(@{ Kind = 'compact' }) }
                $hasEarlierTurns = ($turns.Count -gt 0)
            }
            continue
        }
        if ($e.type -ne 'user' -and $e.type -ne 'assistant') { continue }
        if ($e.isMeta) { continue }

        if ($e.type -eq 'user') {
            if ($e.isCompactSummary) {
                # With the original history available, the /compact summary is redundant.
                if (-not $hasEarlierTurns) {
                    $current = @{ Start = $ts; Blocks = (New-Object System.Collections.Generic.List[object]); Summary = $true }
                    $turns.Add($current)
                    $current.Blocks.Add(@{ Kind = 'summary'; Text = (Get-CleanUserText ([string]$e.message.content)) })
                }
                continue
            }
            if ($e.isVisibleInTranscriptOnly) { continue }

            $texts = New-Object System.Collections.Generic.List[string]
            $images = 0
            $content = $e.message.content
            if ($content -is [string]) { $texts.Add($content) }
            else {
                foreach ($b in @($content)) {
                    if ($b.type -eq 'text') { $texts.Add([string]$b.text) }
                    elseif ($b.type -eq 'image') { $images++ }
                }
            }
            $clean = (@($texts | ForEach-Object { Get-CleanUserText $_ }) | Where-Object { $_ }) -join "`n`n"
            if ($images -gt 0) { $clean = ($clean + "`n`n" + (T 'md.images' $images)).Trim() }
            if ($clean) {
                $current = @{ Start = $ts; Blocks = (New-Object System.Collections.Generic.List[object]); Summary = $false }
                $turns.Add($current)
                $current.Blocks.Add(@{ Kind = 'user'; Text = $clean; Time = $ts })
            }
            continue
        }

        # assistant
        if ($e.message.model -eq '<synthetic>') { continue }
        if ($null -eq $current) {
            $current = @{ Start = $ts; Blocks = (New-Object System.Collections.Generic.List[object]); Summary = $false }
            $turns.Add($current)
        }
        $content = $e.message.content
        if ($content -is [string]) { $content = @(@{ type = 'text'; text = $content }) }
        foreach ($b in @($content)) {
            if ($b.type -eq 'text' -and ([string]$b.text).Trim()) {
                $current.Blocks.Add(@{ Kind = 'assistant'; Text = ([string]$b.text).Trim() })
            } elseif ($b.type -eq 'tool_use') {
                $current.Blocks.Add(@{ Kind = 'tool'; Name = [string]$b.name; Input = $b.input; Result = $results[[string]$b.id] })
            }
        }
    }
    return , $turns
}

# ------------------------------------------------------------------ tools

function Get-ToolTarget([string]$Name, $In) {
    if ($null -eq $In) { return '' }
    switch -Regex ($Name) {
        '^(Bash|PowerShell)$' { return (Get-FirstLine ([string]$In.command)) }
        '^(Read|Write|Edit|MultiEdit)$' { return [string]$In.file_path }
        '^NotebookEdit$' { return [string]$In.notebook_path }
        '^Glob$' { return ('{0} {1}' -f $In.pattern, $In.path).Trim() }
        '^Grep$' { return ('"{0}" {1}' -f $In.pattern, $In.path).Trim() }
        '^WebFetch$' { return [string]$In.url }
        '^WebSearch$' { return [string]$In.query }
        '^(Task|Agent)$' { return [string]$In.description }
        '^TodoWrite$' { return (T 'md.todoItems' @($In.todos).Count) }
        '^Skill$' { return ([string]$In.skill + ' ' + [string]$In.command).Trim() }
        default { return (Get-FirstLine (($In | ConvertTo-Json -Depth 4 -Compress)) 160) }
    }
}

function Format-ToolBody([string]$Name, $In, $Spec) {
    $max = $Spec.Content
    switch -Regex ($Name) {
        '^Bash$' { return (Format-Fence (Limit-Text ([string]$In.command) ([Math]::Max($max, 600))) 'bash') }
        '^PowerShell$' { return (Format-Fence (Limit-Text ([string]$In.command) ([Math]::Max($max, 600))) 'powershell') }
        '^Write$' {
            if ($max -le 0) { return '' }
            return (Format-Fence (Limit-Text ([string]$In.content) $max) (Get-FenceLang ([string]$In.file_path)))
        }
        '^Edit$' {
            if ($max -le 0) { return '' }
            return (Format-Fence (Limit-Text (Format-Diff $In.old_string $In.new_string) $max) 'diff')
        }
        '^MultiEdit$' {
            if ($max -le 0) { return '' }
            $d = (@($In.edits) | ForEach-Object { Format-Diff $_.old_string $_.new_string }) -join "`n...`n"
            return (Format-Fence (Limit-Text $d $max) 'diff')
        }
        '^TodoWrite$' {
            $lines = foreach ($t in @($In.todos)) {
                $mark = ' '
                if ($t.status -eq 'completed') { $mark = 'x' }
                $suffix = ''
                if ($t.status -eq 'in_progress') { $suffix = T 'md.inProgress' }
                "- [$mark] $($t.content)$suffix"
            }
            return (@($lines) -join "`n")
        }
        '^(Task|Agent)$' {
            if ($max -le 0) { return '' }
            return (Format-Fence (Limit-Text ([string]$In.prompt) $max) '')
        }
        '^(Read|Glob|Grep|WebFetch|WebSearch|Skill|NotebookEdit)$' { return '' }
        default {
            if ($max -le 0) { return '' }
            return (Format-Fence (Limit-Text (($In | ConvertTo-Json -Depth 6)) $max) 'json')
        }
    }
}

function Format-Diff($Old, $New) {
    $o = @(([string]$Old) -split "`r?`n" | ForEach-Object { "- $_" })
    $n = @(([string]$New) -split "`r?`n" | ForEach-Object { "+ $_" })
    return (($o + $n) -join "`n")
}

function Format-ToolResult([string]$Name, $Result, $Spec) {
    if ($null -eq $Result) { return (T 'md.noResult') }
    $text = Get-ResultText $Result
    $isError = [bool]$Result.is_error

    if ($isError) { return ((T 'md.error') + "`n" + (Format-Fence (Limit-Text $text ([Math]::Max($Spec.Result, 400))) 'text')) }

    # Results that only repeat what is already on disk or in the call itself.
    if ($Name -match '^(Write|Edit|MultiEdit|NotebookEdit|TodoWrite)$') { return '' }
    $max = $Spec.Result
    if ($Name -eq 'Read') { $max = $Spec.Read }
    if ($max -le 0) { return '' }
    if (-not $text -or -not $text.Trim()) { return (T 'md.emptyOutput') }
    return ((T 'md.result') + "`n" + (Format-Fence (Limit-Text $text $max) 'text'))
}

# ------------------------------------------------------------------ rendering

function Format-Turn($Turn, [int]$Number, [string]$Level) {
    $spec = $script:LevelSpec[$Level]
    $sb = New-Object System.Text.StringBuilder
    $claudeOpen = $false

    foreach ($b in $Turn.Blocks) {
        switch ($b.Kind) {
            'user' {
                [void]$sb.AppendLine((T 'md.you' $Number (Format-Time $b.Time))).AppendLine()
                [void]$sb.AppendLine((Limit-Text $b.Text $spec.Text)).AppendLine()
                $claudeOpen = $false
            }
            'summary' {
                [void]$sb.AppendLine((T 'md.summaryTitle' $Number)).AppendLine()
                [void]$sb.AppendLine((T 'md.summaryNote')).AppendLine()
                [void]$sb.AppendLine((Limit-Text $b.Text $spec.Text)).AppendLine()
            }
            'compact' {
                [void]$sb.AppendLine((T 'md.compacted')).AppendLine()
            }
            'assistant' {
                if (-not $claudeOpen) {
                    if ($sb.Length -eq 0) { [void]$sb.AppendLine((T 'md.claudeCont' $Number)).AppendLine() }
                    else { [void]$sb.AppendLine((T 'md.claude')).AppendLine() }
                    $claudeOpen = $true
                }
                [void]$sb.AppendLine((Limit-Text $b.Text $spec.Text)).AppendLine()
            }
            'tool' {
                if (-not $claudeOpen) {
                    if ($sb.Length -eq 0) { [void]$sb.AppendLine((T 'md.claudeCont' $Number)).AppendLine() }
                    else { [void]$sb.AppendLine((T 'md.claude')).AppendLine() }
                    $claudeOpen = $true
                }
                $target = Get-ToolTarget $b.Name $b.Input
                if ($Level -eq 'compact') {
                    $status = T 'md.status.ok'
                    if ($null -eq $b.Result) { $status = T 'md.status.none' }
                    elseif ($b.Result.is_error) { $status = T 'md.status.error' (Get-FirstLine (Get-ResultText $b.Result) 200) }
                    [void]$sb.AppendLine(('- `{0}` {1} -> {2}' -f $b.Name, $target, $status))
                    continue
                }
                $label = ('`{0}`' -f $b.Name)
                $desc = ''
                if ($b.Input -and $b.Input.description -and $b.Name -match '^(Bash|PowerShell)$') { $desc = [string]$b.Input.description }
                if ($b.Name -match '^(Bash|PowerShell)$') {
                    if ($desc) { [void]$sb.AppendLine("$label $desc") } else { [void]$sb.AppendLine($label) }
                } else {
                    [void]$sb.AppendLine("$label $target")
                }
                $body = Format-ToolBody $b.Name $b.Input $spec
                if ($body) { [void]$sb.AppendLine($body) }
                $res = Format-ToolResult $b.Name $b.Result $spec
                if ($res) { [void]$sb.AppendLine().AppendLine($res) }
                [void]$sb.AppendLine()
            }
        }
    }
    if ($Level -eq 'compact') { [void]$sb.AppendLine() }
    return $sb.ToString()
}

function ConvertTo-HandoffMarkdown {
    param(
        [Parameter(Mandatory)] $Session,
        [string]$Level = 'normal',
        [int]$MaxChars = 0,
        [string]$Note,
        [bool]$Redact = $true
    )

    $chain = Get-ActiveChain $Session.Entries
    $turns = Get-TranscriptTurns $chain
    $n = $turns.Count
    $startLevel = [Array]::IndexOf($script:Levels, $Level)
    if ($startLevel -lt 0) { throw (T 'err.badLevel' $Level) }

    # Renders on demand and caches each turn at each level.
    $cache = @{}
    $redacted = 0
    $render = {
        param([int]$i, [int]$lvl)
        $key = "$i|$lvl"
        if (-not $cache.ContainsKey($key)) {
            $count = 0
            $text = Format-Turn $turns[$i] ($i + 1) $script:Levels[$lvl]
            if ($Redact) { $text = Protect-Secrets $text ([ref]$count) }
            $cache[$key] = @{ Text = $text; Redacted = $count }
        }
        return $cache[$key]
    }

    $plan = New-Object int[] $n
    $size = New-Object int[] $n
    $omitted = New-Object bool[] $n
    $sum = 2500
    if ($Note) { $sum += $Note.Length }
    for ($i = 0; $i -lt $n; $i++) {
        $plan[$i] = $startLevel
        $size[$i] = (& $render $i $startLevel).Text.Length
        $sum += $size[$i]
    }

    $degradedOld = $false; $degradedRecent = $false; $omitCount = 0
    if ($MaxChars -gt 0 -and $sum -gt $MaxChars) {
        # What gets sacrificed, from what matters least for continuing the work to what matters most:
        #   1) older turns lose detail   2) older turns in the middle are dropped
        #   3) the 8 recent turns lose detail   4) the rest of the middle is dropped
        # The first turn (which usually states the goal) and the last one always stay.
        $cut = [Math]::Max(1, $n - $script:RecentTurns)
        $steps = @(
            @{ Kind = 'reduce'; From = 0; To = $cut },
            @{ Kind = 'omit'; From = 1; To = $cut },
            @{ Kind = 'reduce'; From = $cut; To = $n },
            @{ Kind = 'omit'; From = $cut; To = ($n - 1) }
        )
        foreach ($step in $steps) {
            if ($sum -le $MaxChars) { break }
            if ($step.Kind -eq 'reduce') {
                for ($lvl = $startLevel + 1; $lvl -lt $script:Levels.Count -and $sum -gt $MaxChars; $lvl++) {
                    for ($i = $step.From; $i -lt $step.To -and $sum -gt $MaxChars; $i++) {
                        if ($omitted[$i] -or $plan[$i] -ge $lvl) { continue }
                        $len = (& $render $i $lvl).Text.Length
                        $sum += $len - $size[$i]
                        $size[$i] = $len
                        $plan[$i] = $lvl
                        if ($step.From -eq 0) { $degradedOld = $true } else { $degradedRecent = $true }
                    }
                }
            } else {
                for ($i = [Math]::Max(1, $step.From); $i -lt $step.To -and $sum -gt $MaxChars; $i++) {
                    if ($omitted[$i]) { continue }
                    $omitted[$i] = $true
                    $omitCount++
                    $sum -= $size[$i]
                }
            }
        }
    }

    # ---- header
    $first = $null; $last = $null
    foreach ($t in $turns) { if ($t.Start) { if (-not $first) { $first = $t.Start }; $last = $t.Start } }
    $title = $Session.Title
    if (-not $title) {
        foreach ($t in $turns) {
            $u = $t.Blocks | Where-Object { $_.Kind -eq 'user' } | Select-Object -First 1
            if ($u) { $title = Get-FirstLine $u.Text 80; break }
        }
    }
    if (-not $title) { $title = T 'md.untitled' }

    $body = New-Object System.Text.StringBuilder
    $omitMarked = $false
    for ($i = 0; $i -lt $n; $i++) {
        if ($omitted[$i]) {
            if (-not $omitMarked) {
                [void]$body.AppendLine((T 'md.omittedTurns' $omitCount)).AppendLine()
                $omitMarked = $true
            }
            continue
        }
        $r = & $render $i $plan[$i]
        $redacted += $r.Redacted
        [void]$body.Append($r.Text)
        [void]$body.AppendLine('---').AppendLine()
    }

    $noteText = $null
    if ($Note) {
        $noteCount = 0
        $noteText = $Note.Trim()
        if ($Redact) { $noteText = Protect-Secrets $noteText ([ref]$noteCount); $redacted += $noteCount }
    }

    $h = New-Object System.Text.StringBuilder
    [void]$h.AppendLine((T 'md.title' $title)).AppendLine()
    [void]$h.AppendLine('| | |').AppendLine('|---|---|')
    [void]$h.AppendLine(('| {0} | `{1}` |' -f (T 'md.row.session'), $Session.SessionId))
    if ($Session.Cwd) { [void]$h.AppendLine(('| {0} | `{1}` |' -f (T 'md.row.folder'), $Session.Cwd)) }
    if ($Session.Branch) { [void]$h.AppendLine(('| {0} | `{1}` |' -f (T 'md.row.branch'), $Session.Branch)) }
    if ($first) { [void]$h.AppendLine(('| {0} | {1} |' -f (T 'md.row.period'), (T 'md.row.periodValue' (Format-Time $first) (Format-Time $last)))) }
    [void]$h.AppendLine(('| {0} | {1} |' -f (T 'md.row.turns'), $n))
    [void]$h.AppendLine(('| {0} | {1} |' -f (T 'md.row.detail'), $Level)).AppendLine()

    $notes = New-Object System.Collections.Generic.List[string]
    $notes.Add((T 'md.note.exported' (Get-Date -Format (T 'fmt.date'))))
    if ($degradedOld) { $notes.Add((T 'md.note.reducedOld')) }
    if ($degradedRecent) { $notes.Add((T 'md.note.reducedRecent')) }
    if ($Session.Skipped -gt 0) { $notes.Add((T 'md.note.skipped' $Session.Skipped)) }
    if ($Redact) {
        if ($redacted -gt 0) { $notes.Add((T 'md.note.redacted' $redacted (T 'md.mask'))) }
        else { $notes.Add((T 'md.note.noSecrets')) }
    }
    [void]$h.AppendLine(((@($notes) | ForEach-Object { "> $_" }) -join "`n>`n")).AppendLine()

    if ($noteText) {
        [void]$h.AppendLine((T 'md.handoffNote')).AppendLine()
        [void]$h.AppendLine($noteText).AppendLine()
    }
    [void]$h.AppendLine((T 'md.conversation')).AppendLine()

    return [pscustomobject]@{
        Markdown = $h.ToString() + $body.ToString()
        Title    = $title
        Turns    = $n
        Omitted  = $omitCount
        Reduced  = ($degradedOld -or $degradedRecent)
        Redacted = $redacted
        Level    = $Level
    }
}
