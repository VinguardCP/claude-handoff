# claude-handoff tests. No dependencies; run with
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Handoff.ps1
#
# Output follows the Windows display language, like the rest of the project.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$lib = Join-Path (Join-Path $root 'handoff') 'lib'
foreach ($m in 'I18n', 'Config', 'Desktop', 'Session', 'Transcript') { . (Join-Path $lib "$m.ps1") }

$script:displayLang = Resolve-HandoffLanguage 'auto'
$script:failures = 0
$script:passed = 0

function Section([string]$En, [string]$Pt) {
    if ($script:displayLang -eq 'pt-BR') { Write-Host $Pt } else { Write-Host $En }
}
function Assert([bool]$Condition, [string]$En, [string]$Pt) {
    $name = $En
    if ($script:displayLang -eq 'pt-BR') { $name = $Pt }
    if ($Condition) { $script:passed++; Write-Host "  ok   $name" }
    else {
        $script:failures++
        $label = 'FAILED'
        if ($script:displayLang -eq 'pt-BR') { $label = 'FALHOU' }
        Write-Host "  $label $name" -ForegroundColor Red
    }
}

$sid = '1b2c3d4e-0000-4000-8000-aaaaaaaaaaaa'
$fixture = Join-Path (Join-Path $PSScriptRoot 'fixtures') "$sid.jsonl"
$session = Read-SessionFile $fixture

Section 'Reading the session' 'Leitura da sessão'
Assert ($session.SessionId -eq $sid) 'session id' 'id da sessão'
Assert ($session.Title -eq 'Corrigir login do portal') 'custom title wins' 'título personalizado tem prioridade'
Assert ($session.Cwd -eq 'C:\repos\portal') 'working folder' 'pasta de trabalho'
Assert ($session.Skipped -eq 0) 'every line read' 'todas as linhas lidas'

Section 'Active conversation' 'Conversa ativa'
$ids = @(Get-ActiveChain $session.Entries | ForEach-Object { $_.uuid })
Assert ($ids -notcontains 'x1') 'branch discarded by /rewind is left out' 'ramo abandonado pelo /rewind fica de fora'
Assert ($ids -contains 'u1') 'history from before /compact is recovered' 'histórico de antes do /compact é recuperado'
Assert ($ids -notcontains 'sa1') 'subagent is left out' 'subagente fica de fora'

Set-HandoffLanguage 'en'
Section 'Transcript (normal)' 'Transcrição (normal)'
$doc = ConvertTo-HandoffMarkdown -Session $session -Level normal -MaxChars 0 -Note 'Stopped at the review.' -Redact $true
$md = $doc.Markdown
Assert ($md.Contains('Quero corrigir o login do portal')) 'first message present' 'primeira mensagem presente'
Assert ($md.Contains('Corrigi a comparação estrita')) "Claude's reply present" 'resposta do Claude presente'
Assert ($md.Contains('npm test')) 'Bash command present' 'comando Bash presente'
Assert ($md.Contains('expected true, got false')) 'tool error present' 'erro da ferramenta presente'
Assert ($md.Contains('+ if (a === b)')) 'edit shown as diff' 'edição aparece como diff'
Assert ($md.Contains('- [x] Corrigir comparação')) 'to-do list rendered' 'lista de tarefas renderizada'
Assert ($md.Contains('Command: `/handoff chat work`')) 'readable slash command' 'slash command legível'
Assert ($md.Contains('[1 image(s) attached]')) 'image flagged' 'imagem sinalizada'
Assert ($md.Contains('## Handoff note')) 'handoff note included' 'nota de passagem incluída'
Assert ($md.Contains('compacted here')) '/compact marker' 'marcador do /compact'
Assert (-not $md.Contains('RESUMO DO COMPACT')) '/compact summary skipped when history exists' 'resumo do /compact omitido quando há histórico'
Assert (-not $md.Contains('MENSAGEM ABANDONADA')) 'no discarded branch' 'sem ramo abandonado'
Assert (-not $md.Contains('SUBAGENTE')) 'no subagent' 'sem subagente'
Assert (-not $md.Contains('PENSAMENTO INTERNO')) 'no internal reasoning' 'sem raciocínio interno'
Assert (-not $md.Contains('caveat interno')) 'no system messages' 'sem mensagens de sistema'
Assert (-not $md.Contains('SKILL EXPANDIDA')) 'no expanded skill content' 'sem conteúdo expandido da skill'
Assert (-not $md.Contains('No response requested')) 'no synthetic message' 'sem mensagem sintética'
Assert (-not $md.Contains('CONTEUDO DO ARQUIVO LIDO')) 'Read content left out at normal' 'conteúdo de Read fica de fora no normal'
Assert ($md.Contains('````markdown')) 'longer fence when content has ```' 'cerca maior quando o conteúdo tem ```'

Section 'Secrets' 'Segredos'
Assert (-not $md.Contains('SuperSecreta123')) 'connection string password masked' 'senha de connection string mascarada'
Assert (-not $md.Contains('sk-ant-abcdef')) 'API key masked' 'chave de API mascarada'
Assert (-not $md.Contains('hunter2')) '.env variable masked' 'variável de .env mascarada'
Assert (-not $md.Contains('abcdefghijklmnopqrstuvwxyz0123')) 'Bearer token masked' 'token Bearer mascarado'
Assert ($md.Contains('APP_NAME=portal')) 'ordinary variable kept' 'variável comum preservada'
Assert ($md.Contains('[hidden]')) 'mask uses the current language' 'máscara usa o idioma atual'
Assert ($doc.Redacted -ge 4) 'secret count' 'contagem de segredos'

Section 'Levels and limit' 'Níveis e limite'
$full = (ConvertTo-HandoffMarkdown -Session $session -Level full -MaxChars 0 -Redact $true).Markdown
Assert ($full.Contains('CONTEUDO DO ARQUIVO LIDO')) 'full includes read content' 'full inclui conteúdo lido'
$compact = (ConvertTo-HandoffMarkdown -Session $session -Level compact -MaxChars 0 -Redact $true).Markdown
Assert (-not $compact.Contains('Result:')) 'compact has no output' 'compact sem saídas'
Assert ($compact.Contains('-> error: FAIL auth.test.js')) 'compact shows errors on one line' 'compact mostra erro em uma linha'
$small = ConvertTo-HandoffMarkdown -Session $session -Level full -MaxChars 3200 -Redact $true
Assert ($small.Markdown.Length -lt $full.Length) 'limit reduces the size' 'limite reduz o tamanho'
Assert ($small.Reduced -or $small.Omitted -gt 0) 'limit reports the reduction' 'limite sinaliza redução'
Assert ($small.Markdown.Contains('Quero corrigir o login do portal')) 'first message survives the limit' 'primeira mensagem sobrevive ao limite'

Section 'Languages' 'Idiomas'
Set-HandoffLanguage 'pt-BR'
$pt = (ConvertTo-HandoffMarkdown -Session $session -Level normal -MaxChars 0 -Note 'Parei na revisão.' -Redact $true).Markdown
Assert ($pt.Contains('Você ·') -and $pt.Contains('## Nota de passagem') -and $pt.Contains('Comando: `/handoff')) 'Portuguese transcript' 'transcrição em português'
Assert ($pt.Contains('[oculto]') -and -not $pt.Contains('[hidden]')) 'Portuguese mask' 'máscara em português'
Assert ((Resolve-HandoffLanguage 'pt') -eq 'pt-BR') '"pt" means pt-BR' '"pt" vira pt-BR'
Assert ((Resolve-HandoffLanguage 'xx') -eq 'en') 'unknown language falls back to English' 'idioma desconhecido cai no inglês'
Assert (@('en', 'pt-BR') -contains (Resolve-HandoffLanguage 'auto')) '"auto" picks a supported language' '"auto" escolhe um idioma suportado'
$enKeys = @($script:HandoffStrings['en'].Keys)
$ptKeys = @($script:HandoffStrings['pt-BR'].Keys)
$missing = @($enKeys | Where-Object { $ptKeys -notcontains $_ }) + @($ptKeys | Where-Object { $enKeys -notcontains $_ })
$gap = ''
if ($missing.Count -gt 0) { $gap = ': ' + ($missing -join ', ') }
Assert ($missing.Count -eq 0) "every message exists in both languages$gap" "toda mensagem existe nos dois idiomas$gap"

Set-HandoffLanguage 'en'
Section 'Helpers' 'Utilitários'
Assert ((Limit-Text ('a' * 100) 10).Contains('90 characters omitted')) 'cut with notice' 'corte com aviso'
$url = New-DesktopUrl 'claude://cowork/new' @(@('q', 'olá & tchau'), @('file', 'C:\a b.md'), @('file', 'C:\c.md'))
Assert ($url -eq 'claude://cowork/new?q=ol%C3%A1%20%26%20tchau&file=C%3A%5Ca%20b.md&file=C%3A%5Cc.md') 'link with repeated parameters' 'link com parâmetros repetidos'
$smallChat = New-ChatOpenPlan -Prompt 'continue' -Transcript 'small transcript' -MaxPromptChars 13000 -MaxUrlChars 30000
Assert ($smallChat.AutoFill) 'small chat transcript is prefilled' 'transcrição pequena do chat é preenchida automaticamente'
Assert ($smallChat.Url.Contains('small%20transcript')) 'prefilled chat link contains the transcript' 'link preenchido do chat contém a transcrição'
# URL encoding can expand the link substantially while the decoded q text is still safely
# below Claude's ~14k prompt limit. It should still autofill instead of falling back.
$mediumChat = New-ChatOpenPlan -Prompt 'continue' -Transcript (('palavra com espaço ' * 450)) -MaxPromptChars 13000 -MaxUrlChars 30000
Assert ($mediumChat.PromptLength -lt 13000) 'medium chat stays below the decoded prompt limit' 'chat médio fica abaixo do limite do prompt decodificado'
Assert ($mediumChat.UrlLength -gt 12000) 'medium chat exercises substantial URL encoding expansion' 'chat médio exercita expansão substancial da URL codificada'
Assert ($mediumChat.AutoFill) 'medium chat is still prefilled despite URL encoding expansion' 'chat médio ainda é preenchido apesar da expansão da URL'
$largeChat = New-ChatOpenPlan -Prompt 'continue' -Transcript ('x' * 300000) -MaxPromptChars 13000 -MaxUrlChars 30000
Assert (-not $largeChat.AutoFill) 'large chat transcript uses clipboard fallback' 'transcrição grande do chat usa fallback da área de transferência'
Assert ($largeChat.FallbackReason -eq 'prompt-limit') 'large chat reports the q prompt limit as fallback reason' 'chat grande informa limite do prompt q como motivo do fallback'
Assert ($largeChat.Url.Length -lt 30000) 'fallback link stays below the encoded URL guard' 'link de fallback fica abaixo da proteção da URL codificada'


Section 'Account profile detection' 'Detecção do perfil das contas'
Assert ((Get-UserDataDirFromCommandLine '"C:\Program Files\Claude\claude.exe" --user-data-dir="C:\Users\Ana\Claude-Work"') -eq 'C:\Users\Ana\Claude-Work') 'reads --user-data-dir= with quotes' 'lê --user-data-dir= com aspas'
Assert ((Get-UserDataDirFromCommandLine 'claude.exe --user-data-dir "C:\Users\Ana Silva\Claude Work"') -eq 'C:\Users\Ana Silva\Claude Work') 'reads --user-data-dir followed by a quoted path' 'lê --user-data-dir seguido de caminho com aspas'
Assert ((Get-UserDataDirFromCommandLine 'claude.exe --user-data-dir=C:\Claude-Work') -eq 'C:\Claude-Work') 'reads unquoted --user-data-dir' 'lê --user-data-dir sem aspas'
Assert ($null -eq (Get-UserDataDirFromCommandLine 'claude.exe --type=renderer')) 'no profile flag means main instance' 'sem flag de perfil significa instância principal'
$fakeRunning = [pscustomobject]@{ CanInspect = $true; Instances = @([pscustomobject]@{ UserDataDir = $null }, [pscustomobject]@{ UserDataDir = 'C:\Users\Ana\Claude-Work\' }) }
Assert (Test-ClaudeInstanceRunning $fakeRunning '') 'detects running main instance' 'detecta instância principal em execução'
Assert (Test-ClaudeInstanceRunning $fakeRunning 'C:\Users\Ana\Claude-Work') 'matches profile paths ignoring trailing slash' 'compara perfil ignorando barra final'

Section 'Files' 'Arquivos'
$noBom = @(Get-ChildItem -LiteralPath $root -Recurse -Filter '*.ps1' -File | Where-Object {
        $bytes = [IO.File]::ReadAllBytes($_.FullName)
        -not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    } | ForEach-Object { $_.Name })
$gap = ''
if ($noBom.Count -gt 0) { $gap = ': ' + ($noBom -join ', ') }
Assert ($noBom.Count -eq 0) "every .ps1 is UTF-8 with BOM$gap" "todo .ps1 está em UTF-8 com BOM$gap"

Set-HandoffLanguage $script:displayLang
Write-Host ''
Write-Host (T 'tests.summary' $script:passed $script:failures)
if ($script:failures -gt 0) { exit 1 }
