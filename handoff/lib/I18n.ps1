# Language: every user-facing message, in English and Brazilian Portuguese.
#
# "auto" follows the Windows display language: Portuguese for pt-* systems, English otherwise.
# Set "language" in config.json to "en" or "pt-BR" to pin it.

$script:HandoffStrings = @{
    'en'    = @{
        'tag.ok'               = 'ok'
        'tag.warn'             = 'warn'
        'tag.error'            = 'error'
        'fmt.time'             = 'yyyy-MM-dd HH:mm'
        'fmt.date'             = 'yyyy-MM-dd HH:mm'

        'err.configMissing'    = 'config.json not found in {0}. Run install.ps1 again.'
        'err.configInvalid'    = 'config.json is not valid JSON: {0}. Check commas, quotes and doubled backslashes in Windows paths. Detail: {1}'
        'err.accountMissing'   = "Account '{0}' doesn't exist in config.json. Available accounts: {1}"
        'err.exeInvalid'       = "claudeExe set in config.json doesn't exist: {0}"
        'err.exeMissing'       = "Couldn't find Claude Desktop's claude.exe. Set 'claudeExe' in config.json."
        'err.dataDirMissing'   = "The data folder for account '{0}' doesn't exist: {1}. Check userDataDir in config.json (it must be the same folder as that instance's shortcut), or open the instance once first."
        'err.projectsMissing'  = 'Claude Code sessions folder not found: {0}'
        'err.sessionMissing'   = 'Session {0} not found in {1}'
        'err.noSessions'       = 'No Claude Code session found.'
        'err.badLevel'         = 'Invalid detail level: {0} (use full, normal or compact)'

        'acc.mainLabel'        = 'Main account'
        'acc.defaultFolder'    = 'app default folder'
        'acc.defaultMark'      = ' (default)'
        'acc.title'            = 'Configured accounts'
        'acc.folderOk'         = "Data folder exists: {0}"
        'acc.folderMissing'    = "Data folder DOES NOT exist: {0}"
        'acc.runningMain'      = 'Main Claude instance is running now'
        'acc.runningProfile'   = 'Claude instance is running now with this userDataDir'
        'acc.notRunningMain'   = 'Main Claude instance was not detected as running now'
        'acc.notRunningProfile'= 'No running Claude instance was detected with this userDataDir'
        'acc.processUnknown'   = "Couldn't inspect running Claude processes: {0}"
        'acc.hintOpen'         = 'Open the intended Claude window and run this command again. If it still does not match, compare userDataDir with --user-data-dir in the shortcut.'
        'acc.usageHint'        = 'Use one of these account keys after the destination, for example: /handoff chat work. For all options: /handoff --help'
        'dry.protocol'         = '[dry-run] Windows default protocol -> {0}'

        'md.title'             = '# Claude Code session: {0}'
        'md.untitled'          = 'Untitled session'
        'md.row.session'       = 'Session'
        'md.row.folder'        = 'Folder'
        'md.row.branch'        = 'Branch'
        'md.row.period'        = 'Period'
        'md.row.periodValue'   = '{0} to {1}'
        'md.row.turns'         = 'Turns'
        'md.row.detail'        = 'Detail'
        'md.note.exported'     = "Exported by claude-handoff on {0}. This is the real conversation, message by message, with the tools used and their results. The model's internal reasoning is not included."
        'md.note.reducedOld'   = 'To fit the limit, the oldest turns appear with less detail (only the actions, without output).'
        'md.note.reducedRecent' = 'The recent turns were also reduced to fit the limit.'
        'md.note.skipped'      = '{0} session record(s) could not be read.'
        'md.note.redacted'     = '{0} possible secret(s) were masked as {1}.'
        'md.note.noSecrets'    = 'No known secret was found.'
        'md.handoffNote'       = '## Handoff note'
        'md.conversation'      = '## Conversation'
        'md.you'               = '### {0}. You · {1}'
        'md.claude'            = '**Claude**'
        'md.claudeCont'        = '### {0}. Claude (continued)'
        'md.summaryTitle'      = '### {0}. Automatic /compact summary'
        'md.summaryNote'       = '_The history before this point was no longer available in the session._'
        'md.compacted'         = '> _The conversation was compacted here (/compact). The original history is above._'
        'md.omittedTurns'      = '> _[... {0} turn(s) omitted here to fit the limit. The full transcript can be generated with /handoff export ...]_'
        'md.omittedChars'      = '[... {0} characters omitted ...]'
        'md.command'           = 'Command: `{0}`'
        'md.images'            = '[{0} image(s) attached]'
        'md.image'             = '[image]'
        'md.todoItems'         = '{0} items'
        'md.inProgress'        = ' (in progress)'
        'md.noResult'          = '_(no result recorded)_'
        'md.emptyOutput'       = '_(empty output)_'
        'md.error'             = '**Error:**'
        'md.result'            = 'Result:'
        'md.status.ok'         = 'ok'
        'md.status.none'       = 'no result'
        'md.status.error'      = 'error: {0}'
        'md.mask'              = '[hidden]'
        'md.maskKey'           = '[private key hidden]'

        'file.fallback'        = 'session'
        'out.transcript'       = 'Transcript: {0} ({1})'
        'out.info'             = '{0} turns, {1:N0} characters, detail {2}'
        'out.infoReduced'      = ', older turns reduced'
        'out.infoOmitted'      = ', {0} turn(s) omitted'
        'out.infoRedacted'     = ', {0} secret(s) masked'

        'code.opened'          = 'Requested session {0} to open in the Code tab of: {1}. Check Desktop to confirm it arrived.'
        'code.exit'            = 'Close this session in the terminal (/exit) before sending a message in Desktop.'
        'chat.prompt'          = "Continuing here a Claude Code (terminal) session. Read the full transcript, tell me in a few lines where we stopped and what's left, and wait for my instructions."
        'chat.openedAuto'      = 'Requested a new chat in: {0}, with the transcript already filled in. If it appeared in the correct window, review it and press Enter.'
        'chat.openedClipboard' = 'Requested a new chat in: {0}. The complete text would be {1:N0} characters; Claude truncates the deep-link q prompt at about 14,000, so the full transcript is on the clipboard: press Ctrl+V and then Enter.'
        'cowork.prompt'        = "Continuing here a Claude Code (terminal) session. The full transcript is in the attached file ({0}). Read all of it, tell me in a few lines where we stopped and what's left, and wait for my instructions."
        'cowork.opened'        = 'Requested a Cowork task in: {0}, with the transcript attached. Check Desktop and confirm the folder when asked.'

        'help.title'           = 'claude-handoff help'
        'help.usage'           = 'Usage: /handoff [destination] [account] [detail] [no note]'
        'help.default'         = 'With no arguments, /handoff is the same as /handoff code.'
        'help.destinations'    = 'Destinations:'
        'help.code'            = '  code      Same native session in Desktop Code. Detail and handoff-note options do not apply.'
        'help.chat'            = '  chat      New Chat with the transcript. Up to ~13,000 prompt characters are prefilled; larger handoffs use the clipboard so nothing is silently truncated.'
        'help.cowork'          = '  cowork    New Cowork task with the transcript file attached and the project folder.'
        'help.export'          = '  export    Only writes the transcript file; it does not open Desktop.'
        'help.accounts'        = '  accounts  Lists configured account keys, the default account, folders and which instances are running. Alias: contas.'
        'help.accountLine'     = 'Configured account keys: {0}'
        'help.detailTitle'     = 'Detail (chat/cowork/export only):'
        'help.detailFull'      = '  full      No per-message text cut; tool output up to 6,000 chars; writes/edits up to 6,000; reads up to 2,000.'
        'help.detailNormal'    = '  normal    Messages up to 20,000 chars each; tool output up to 1,200; writes/edits up to 1,500; read contents omitted.'
        'help.detailCompact'   = '  compact   Messages up to 3,000 chars each; tool output and file contents omitted; tool errors stay as one line.'
        'help.detailApplies'   = 'The detail level changes only the generated transcript. It has no effect on code, accounts or help.'
        'help.defaultsLine'    = 'Current detail defaults: chat={0}, cowork={1}, export={2}.'
        'help.maxCharsLine'    = 'Current total maxChars: chat={0}, cowork={1}, export={2} (0 = unlimited).'
        'help.noteTitle'       = 'Handoff note:'
        'help.noteLine'        = 'For chat/cowork/export, a short orientation note is included by default. Add "no note" or "sem nota" to remove only that note; the conversation remains.'
        'help.noteExample'     = 'The note says, in up to 10 lines: where we stopped, the next step, and anything to watch out for.'
        'help.aliases'         = 'Aliases: accounts/contas, help/ajuda, full/completo, compact/enxuto, no note/sem nota. Use /handoff --help, /handoff help or /handoff ajuda for this screen.'
        'help.examples'        = 'Examples:'

        'test.title'           = 'claude-handoff diagnostics'
        'test.ps'              = 'PowerShell {0}'
        'test.config'          = 'config.json read, {0} account(s), language {1}'
        'test.sessions'        = '{0} Claude Code session(s) in {1}'
        'test.noSessions'      = 'Sessions folder not found: {0} (use Claude Code once first)'
        'test.protoOk'         = 'claude:// protocol registered in Windows'
        'test.protoMissing'    = 'claude:// protocol not registered: is Claude Desktop installed?'
        'test.protoUnknown'    = "Couldn't check the claude:// protocol on this system"
        'test.exe'             = 'claude.exe: {0}'
        'test.exeOnlyNeeded'   = '{0} Only needed for accounts with userDataDir.'
        'test.dataDirOk'       = "Data folder for account '{0}': {1}"
        'test.dataDirMissing'  = "Data folder for account '{0}' doesn't exist: {1}"
        'test.mainInstance'    = "Account '{0}' opens in the main instance"
        'test.stopDataDir'     = "Test stopped: check userDataDir in config.json (it must be the same folder as the instance's shortcut)."
        'test.stopExe'         = "Test stopped: without claude.exe this account can't be opened."
        'test.prompt'          = "claude-handoff test: this chat should be on account '{0}' ({1})."
        'test.opened'          = 'Sent the request to open a test chat in: {0}. Confirm that it actually appeared in the right window, with the test sentence in the message field.'

        'inst.removed'         = 'Skill removed from {0}'
        'inst.keptTranscripts' = 'Transcripts in {0} were kept.'
        'inst.migrated'        = 'Your accounts from accounts.json were moved to config.json.'
        'inst.updated'         = 'Updated in {0} (your config.json was kept).'
        'inst.installed'       = 'Installed in {0}'
        'inst.next'            = 'Open a new Claude Code session and type /handoff'

        'tests.failed'         = 'FAILED'
        'tests.summary'        = '{0} passed, {1} failed'
    }

    'pt-BR' = @{
        'tag.ok'               = 'ok'
        'tag.warn'             = 'aviso'
        'tag.error'            = 'erro'
        'fmt.time'             = 'dd/MM HH:mm'
        'fmt.date'             = 'dd/MM/yyyy HH:mm'

        'err.configMissing'    = 'config.json não encontrado em {0}. Rode o install.ps1 de novo.'
        'err.configInvalid'    = 'O config.json não é um JSON válido: {0}. Confira vírgulas, aspas e barras invertidas duplicadas nos caminhos do Windows. Detalhe: {1}'
        'err.accountMissing'   = "Conta '{0}' não existe no config.json. Contas disponíveis: {1}"
        'err.exeInvalid'       = 'claudeExe definido no config.json não existe: {0}'
        'err.exeMissing'       = "Não encontrei o claude.exe do Claude Desktop. Defina 'claudeExe' no config.json."
        'err.dataDirMissing'   = "A pasta de dados da conta '{0}' não existe: {1}. Confira o userDataDir no config.json (precisa ser a mesma pasta do atalho dessa instância) ou abra a instância uma vez antes."
        'err.projectsMissing'  = 'Pasta de sessões do Claude Code não encontrada: {0}'
        'err.sessionMissing'   = 'Sessão {0} não encontrada em {1}'
        'err.noSessions'       = 'Nenhuma sessão do Claude Code encontrada.'
        'err.badLevel'         = 'Nível de detalhe inválido: {0} (use full, normal ou compact)'

        'acc.mainLabel'        = 'Conta principal'
        'acc.defaultFolder'    = 'pasta padrão do app'
        'acc.defaultMark'      = ' (padrão)'
        'acc.title'            = 'Contas configuradas'
        'acc.folderOk'         = 'Pasta de dados existe: {0}'
        'acc.folderMissing'    = 'Pasta de dados NÃO existe: {0}'
        'acc.runningMain'      = 'A instância principal do Claude está rodando agora'
        'acc.runningProfile'   = 'Há uma instância do Claude rodando agora com este userDataDir'
        'acc.notRunningMain'   = 'A instância principal do Claude não foi detectada em execução agora'
        'acc.notRunningProfile'= 'Nenhuma instância do Claude em execução foi detectada com este userDataDir'
        'acc.processUnknown'   = 'Não foi possível inspecionar os processos do Claude em execução: {0}'
        'acc.hintOpen'         = 'Abra a janela do Claude que você quer usar e rode este comando de novo. Se ainda não bater, compare o userDataDir com o --user-data-dir do atalho.'
        'acc.usageHint'        = 'Use uma destas chaves de conta depois do destino, por exemplo: /handoff chat work. Para ver todas as opções: /handoff --help'
        'dry.protocol'         = '[dry-run] protocolo padrão do Windows -> {0}'

        'md.title'             = '# Sessão do Claude Code: {0}'
        'md.untitled'          = 'Sessão sem título'
        'md.row.session'       = 'Sessão'
        'md.row.folder'        = 'Pasta'
        'md.row.branch'        = 'Branch'
        'md.row.period'        = 'Período'
        'md.row.periodValue'   = '{0} até {1}'
        'md.row.turns'         = 'Turnos'
        'md.row.detail'        = 'Detalhe'
        'md.note.exported'     = 'Exportado pelo claude-handoff em {0}. Esta é a conversa real, mensagem por mensagem, com as ferramentas usadas e seus resultados. O raciocínio interno do modelo não é incluído.'
        'md.note.reducedOld'   = 'Para caber no limite, os turnos mais antigos aparecem com menos detalhe (só as ações, sem as saídas).'
        'md.note.reducedRecent' = 'Os turnos recentes também foram reduzidos para caber no limite.'
        'md.note.skipped'      = '{0} registro(s) da sessão não puderam ser lidos.'
        'md.note.redacted'     = '{0} possível(is) segredo(s) foram mascarados como {1}.'
        'md.note.noSecrets'    = 'Nenhum segredo conhecido foi encontrado.'
        'md.handoffNote'       = '## Nota de passagem'
        'md.conversation'      = '## Conversa'
        'md.you'               = '### {0}. Você · {1}'
        'md.claude'            = '**Claude**'
        'md.claudeCont'        = '### {0}. Claude (continuação)'
        'md.summaryTitle'      = '### {0}. Resumo automático do /compact'
        'md.summaryNote'       = '_O histórico anterior a este ponto não estava mais disponível na sessão._'
        'md.compacted'         = '> _A conversa foi compactada neste ponto (/compact). O histórico original está acima._'
        'md.omittedTurns'      = '> _[... {0} turno(s) omitido(s) aqui para caber no limite. A transcrição completa pode ser gerada com /handoff export ...]_'
        'md.omittedChars'      = '[... {0} caracteres omitidos ...]'
        'md.command'           = 'Comando: `{0}`'
        'md.images'            = '[{0} imagem(ns) anexada(s)]'
        'md.image'             = '[imagem]'
        'md.todoItems'         = '{0} itens'
        'md.inProgress'        = ' (em andamento)'
        'md.noResult'          = '_(sem resultado registrado)_'
        'md.emptyOutput'       = '_(saída vazia)_'
        'md.error'             = '**Erro:**'
        'md.result'            = 'Resultado:'
        'md.status.ok'         = 'ok'
        'md.status.none'       = 'sem resultado'
        'md.status.error'      = 'erro: {0}'
        'md.mask'              = '[oculto]'
        'md.maskKey'           = '[chave privada oculta]'

        'file.fallback'        = 'sessao'
        'out.transcript'       = 'Transcrição: {0} ({1})'
        'out.info'             = '{0} turnos, {1:N0} caracteres, detalhe {2}'
        'out.infoReduced'      = ', turnos antigos reduzidos'
        'out.infoOmitted'      = ', {0} turno(s) omitido(s)'
        'out.infoRedacted'     = ', {0} segredo(s) mascarado(s)'

        'code.opened'          = 'Solicitei a abertura da sessão {0} na aba Code de: {1}. Confira no Desktop se ela realmente apareceu.'
        'code.exit'            = 'Encerre esta sessão no terminal (/exit) antes de mandar mensagem no Desktop.'
        'chat.prompt'          = 'Continuando aqui uma sessão do Claude Code (terminal). Leia a transcrição completa, me diga em poucas linhas onde paramos e o que falta, e espere minhas instruções.'
        'chat.openedAuto'      = 'Solicitei a abertura de um chat novo em: {0}, com a transcrição já preenchida. Se ele apareceu na janela certa, confira e pressione Enter.'
        'chat.openedClipboard' = 'Solicitei a abertura de um chat novo em: {0}. O texto completo teria {1:N0} caracteres; o Claude trunca o prompt q do deep link por volta de 14.000, então a transcrição completa ficou na área de transferência: pressione Ctrl+V e depois Enter.'
        'cowork.prompt'        = 'Continuando aqui uma sessão do Claude Code (terminal). A transcrição completa está no arquivo anexado ({0}). Leia tudo, me diga em poucas linhas onde paramos e o que falta, e espere minhas instruções.'
        'cowork.opened'        = 'Solicitei uma tarefa do Cowork em: {0}, com a transcrição anexada. Confira no Desktop e confirme a pasta quando ele pedir.'

        'help.title'           = 'Ajuda do claude-handoff'
        'help.usage'           = 'Uso: /handoff [destino] [conta] [detalhe] [sem nota]'
        'help.default'         = 'Sem argumentos, /handoff é igual a /handoff code.'
        'help.destinations'    = 'Destinos:'
        'help.code'            = '  code      A mesma sessão nativa na aba Code do Desktop. Detalhe e nota de passagem não se aplicam.'
        'help.chat'            = '  chat      Novo Chat com a transcrição. Até ~13.000 caracteres de prompt vão preenchidos; acima disso usa a área de transferência para não truncar nada.'
        'help.cowork'          = '  cowork    Nova tarefa do Cowork com o arquivo da transcrição anexado e a pasta do projeto.'
        'help.export'          = '  export    Só grava o arquivo da transcrição; não abre o Desktop.'
        'help.accounts'        = '  accounts  Lista as chaves das contas, a conta padrão, as pastas e quais instâncias estão abertas. Alias: contas.'
        'help.accountLine'     = 'Chaves de conta configuradas: {0}'
        'help.detailTitle'     = 'Detalhe (somente chat/cowork/export):'
        'help.detailFull'      = '  full      Sem corte individual no texto das mensagens; saída de ferramentas até 6.000 caracteres; escritas/edições até 6.000; leituras até 2.000.'
        'help.detailNormal'    = '  normal    Mensagens até 20.000 caracteres cada; saída de ferramentas até 1.200; escritas/edições até 1.500; conteúdo lido omitido.'
        'help.detailCompact'   = '  compact   Mensagens até 3.000 caracteres cada; saídas e conteúdos de arquivo omitidos; erros de ferramentas ficam em uma linha.'
        'help.detailApplies'   = 'O nível de detalhe muda apenas a transcrição gerada. Não tem efeito em code, accounts ou help.'
        'help.defaultsLine'    = 'Padrões atuais de detalhe: chat={0}, cowork={1}, export={2}.'
        'help.maxCharsLine'    = 'maxChars total atual: chat={0}, cowork={1}, export={2} (0 = sem limite).'
        'help.noteTitle'       = 'Nota de passagem:'
        'help.noteLine'        = 'Em chat/cowork/export, uma nota curta de orientação entra por padrão. Acrescente "no note" ou "sem nota" para retirar só essa nota; a conversa continua inteira.'
        'help.noteExample'     = 'A nota diz, em até 10 linhas: onde paramos, qual é o próximo passo e algum cuidado importante, se houver.'
        'help.aliases'         = 'Aliases: accounts/contas, help/ajuda, full/completo, compact/enxuto, no note/sem nota. Use /handoff --help, /handoff help ou /handoff ajuda para ver esta tela.'
        'help.examples'        = 'Exemplos:'

        'test.title'           = 'Diagnóstico do claude-handoff'
        'test.ps'              = 'PowerShell {0}'
        'test.config'          = 'config.json lido, {0} conta(s), idioma {1}'
        'test.sessions'        = '{0} sessão(ões) do Claude Code em {1}'
        'test.noSessions'      = 'Pasta de sessões não encontrada: {0} (use o Claude Code uma vez antes)'
        'test.protoOk'         = 'Protocolo claude:// registrado no Windows'
        'test.protoMissing'    = 'Protocolo claude:// não registrado: o Claude Desktop está instalado?'
        'test.protoUnknown'    = 'Não deu para verificar o protocolo claude:// neste sistema'
        'test.exe'             = 'claude.exe: {0}'
        'test.exeOnlyNeeded'   = '{0} Só é necessário para contas com userDataDir.'
        'test.dataDirOk'       = "Pasta de dados da conta '{0}': {1}"
        'test.dataDirMissing'  = "Pasta de dados da conta '{0}' não existe: {1}"
        'test.mainInstance'    = "Conta '{0}' abre na instância principal"
        'test.stopDataDir'     = 'Teste interrompido: confira o userDataDir no config.json (precisa ser a mesma pasta do atalho da instância).'
        'test.stopExe'         = 'Teste interrompido: sem o claude.exe não dá para abrir essa conta.'
        'test.prompt'          = "Teste do claude-handoff: este chat deveria estar na conta '{0}' ({1})."
        'test.opened'          = 'Enviei a solicitação para abrir um chat de teste em: {0}. Confirme se ele realmente apareceu na janela certa, com a frase de teste no campo de mensagem.'

        'inst.removed'         = 'Skill removida de {0}'
        'inst.keptTranscripts' = 'As transcrições em {0} foram mantidas.'
        'inst.migrated'        = 'Suas contas do accounts.json foram levadas para o config.json.'
        'inst.updated'         = 'Atualizada em {0} (seu config.json foi mantido).'
        'inst.installed'       = 'Instalada em {0}'
        'inst.next'            = 'Abra uma sessão nova do Claude Code e digite /handoff'

        'tests.failed'         = 'FALHOU'
        'tests.summary'        = '{0} passaram, {1} falharam'
    }
}

$script:HandoffLang = 'en'

function Resolve-HandoffLanguage([string]$Setting) {
    $lang = $Setting
    if (-not $lang -or $lang -eq 'auto') {
        $ui = ''
        try { $ui = [Globalization.CultureInfo]::CurrentUICulture.Name } catch { }
        if ($ui -like 'pt*') { $lang = 'pt-BR' } else { $lang = 'en' }
    }
    if ($lang -like 'pt*') { $lang = 'pt-BR' }
    if (-not $script:HandoffStrings.ContainsKey($lang)) { $lang = 'en' }
    return $lang
}

function Set-HandoffLanguage([string]$Setting) {
    $script:HandoffLang = Resolve-HandoffLanguage $Setting
}

function Get-HandoffLanguage { return $script:HandoffLang }

# Translated message; extra arguments fill {0}, {1}...
function T {
    param([string]$Key)
    $table = $script:HandoffStrings[$script:HandoffLang]
    $text = $table[$Key]
    if ($null -eq $text) { $text = $script:HandoffStrings['en'][$Key] }
    if ($null -eq $text) { $text = $Key }
    if ($args.Count -gt 0) { return ($text -f $args) }
    return $text
}

# "[ok]    ", "[warn]  ", "[erro]  ": tags padded to the same width.
function Format-Tag([string]$Kind) {
    return ('[' + (T "tag.$Kind") + ']').PadRight(8)
}

Set-HandoffLanguage 'auto'
