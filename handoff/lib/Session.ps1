# Claude Code sessions: find the .jsonl, read it and rebuild the active conversation.
#
# Each .jsonl line is a record with uuid and parentUuid. /rewind creates branches, so the "real"
# conversation is the path that starts at the last message and walks up through the parents.
# After /compact, the compact_boundary marker has no parent but points to the earlier history in
# logicalParentUuid; following it brings back the conversation from before compaction.

function Get-ProjectsDir { return (Join-Path (Get-ClaudeConfigDir) 'projects') }

function Find-SessionFile([string]$SessionId) {
    $projects = Get-ProjectsDir
    if (-not (Test-Path -LiteralPath $projects)) { throw (T 'err.projectsMissing' $projects) }

    if ($SessionId) {
        $hit = Get-ChildItem -LiteralPath $projects -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Join-Path $_.FullName "$SessionId.jsonl"
            if (Test-Path -LiteralPath $p) { Get-Item -LiteralPath $p }
        } | Select-Object -First 1
        if (-not $hit) { throw (T 'err.sessionMissing' $SessionId $projects) }
        return $hit
    }

    # No ID: the most recent session of the current folder (same folder name Claude Code uses),
    # or else the most recent session of any project.
    $slug = (Get-Location).Path -replace '[^a-zA-Z0-9]', '-'
    $files = @()
    $dir = Join-Path $projects $slug
    if (Test-Path -LiteralPath $dir) { $files = @(Get-ChildItem -LiteralPath $dir -Filter '*.jsonl' -File) }
    if ($files.Count -eq 0) {
        $files = @(Get-ChildItem -LiteralPath $projects -Directory | ForEach-Object {
                Get-ChildItem -LiteralPath $_.FullName -Filter '*.jsonl' -File -ErrorAction SilentlyContinue
            })
    }
    $f = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $f) { throw (T 'err.noSessions') }
    return $f
}

function Read-SessionFile([string]$Path) {
    $entries = New-Object System.Collections.Generic.List[object]
    $skipped = 0
    # Shared mode: Claude Code may be writing to the session right now.
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
    $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            if ($line.Trim().Length -eq 0) { continue }
            try { $entries.Add(($line | ConvertFrom-Json)) } catch { $skipped++ }
        }
    } finally {
        $reader.Dispose()
    }

    $title = $null; $aiTitle = $null; $cwd = $null; $branch = $null; $sessionId = $null
    foreach ($e in $entries) {
        if ($e.type -eq 'custom-title' -and $e.customTitle) { $title = [string]$e.customTitle }
        if ($e.type -eq 'ai-title' -and $e.aiTitle) { $aiTitle = [string]$e.aiTitle }
        if ($e.cwd) { $cwd = [string]$e.cwd }
        if ($e.gitBranch) { $branch = [string]$e.gitBranch }
        if ($e.sessionId -and -not $sessionId) { $sessionId = [string]$e.sessionId }
    }
    if (-not $title) { $title = $aiTitle }
    if (-not $sessionId) { $sessionId = [IO.Path]::GetFileNameWithoutExtension($Path) }

    return [pscustomobject]@{
        Path      = $Path
        SessionId = $sessionId
        Entries   = $entries
        Skipped   = $skipped
        Title     = $title
        Cwd       = $cwd
        Branch    = $branch
    }
}

function Get-ActiveChain($Entries) {
    $byId = @{}
    $leaf = $null
    $main = 0
    foreach ($e in $Entries) {
        if ($e.uuid) { $byId[[string]$e.uuid] = $e }
        if (($e.type -eq 'user' -or $e.type -eq 'assistant') -and -not $e.isSidechain) { $leaf = $e; $main++ }
    }
    if (-not $leaf) { return @() }

    $chain = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $cur = $leaf
    while ($null -ne $cur) {
        $id = [string]$cur.uuid
        if ($id) {
            if ($seen.ContainsKey($id)) { break }
            $seen[$id] = $true
        }
        $chain.Add($cur)
        $next = $null
        if ($cur.parentUuid) { $next = $byId[[string]$cur.parentUuid] }
        elseif ($cur.logicalParentUuid) { $next = $byId[[string]$cur.logicalParentUuid] }
        $cur = $next
    }
    $chain.Reverse()

    # Broken chain (missing record): fall back to file order.
    $hasUserText = $false
    foreach ($e in $chain) { if ($e.type -eq 'user' -and -not $e.isMeta) { $hasUserText = $true; break } }
    if (-not $hasUserText -and $main -gt $chain.Count) {
        return @($Entries | Where-Object { -not $_.isSidechain })
    }
    return $chain.ToArray()
}
