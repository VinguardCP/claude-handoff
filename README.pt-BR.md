# claude-handoff

[English](README.md) · **Português (Brasil)**

Leva uma sessão do **Claude Code (terminal)** para o **Claude Desktop**: na aba Code, no Chat ou no Cowork, e na conta que você escolher, inclusive numa segunda conta aberta ao mesmo tempo.

```
/handoff                  mesma sessão, na aba Code do Desktop (padrão)
/handoff chat             a conversa inteira num chat novo
/handoff cowork work      a conversa inteira anexada numa tarefa do Cowork da conta "work"
/handoff export           só gera o arquivo da conversa, sem limite de tamanho
/handoff accounts         mostra as contas que você pode usar (também: /handoff contas)
/handoff --help           mostra todos os comandos, parâmetros e exemplos
```

> Projeto da comunidade, sem vínculo com a Anthropic. Só para Windows. Fala português e inglês, seguindo o idioma do seu Windows.

## Por que existe

O Claude Code já tem o comando `/desktop`, que leva a sessão do terminal para o app. Mas ele tem dois limites:

- só abre na **aba Code**, nunca no Chat ou no Cowork;
- só abre na **instância principal** do app. Quem roda uma segunda conta ao mesmo tempo (por exemplo, com o [claude-desktop-multi-account-windows](https://github.com/VinguardCP/claude-desktop-multi-account-windows)) não consegue mandar a sessão para ela.

O `/handoff` resolve os dois. No Chat e no Cowork, ele leva a **conversa real, mensagem por mensagem**, e não um resumo.

## Índice

- [Requisitos](#requisitos)
- [Instalação e primeiro teste](#instalação-e-primeiro-teste)
- [Se algo der errado](#se-algo-der-errado)
- [O que chega em cada destino](#o-que-chega-em-cada-destino)
- [Uso](#uso)
- [Configuração](#configuração)
- [Privacidade e segurança](#privacidade-e-segurança)
- [Atualizar e remover](#atualizar-e-remover)
- [Como funciona](#como-funciona)
- [Limitações](#limitações)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Contribuindo](#contribuindo)

## Requisitos

- **Windows 10 ou 11.** O Windows PowerShell 5.1 já vem no Windows; não precisa instalar mais nada.
- **Claude Desktop** atualizado ([download](https://claude.com/download)).
- **Claude Code** instalado direto no Windows (não dentro do WSL), atualizado (`claude update`), com login feito e usado pelo menos uma vez. O projeto foi feito com base no Claude Code 2.1.301.
- Um **plano do Claude que inclua o Claude Code**. O destino `cowork` só funciona se o seu plano também tiver o Cowork.
- **Opcional:** uma segunda instância do Desktop com outra conta, criada com o [multi-account](https://github.com/VinguardCP/claude-desktop-multi-account-windows). Sem ela, tudo funciona na conta principal.

## Instalação e primeiro teste

Leva uns 10 minutos. Nada aqui apaga ou altera seus arquivos: o projeto só escreve na pasta da skill (`~/.claude/skills/handoff`) e na pasta das transcrições (`~/.claude/handoffs`).

### 1. Baixar

Nesta página do repositório, clique em **Code** e depois em **Download ZIP**. Extraia o arquivo (botão direito → **Extrair tudo**). O Windows costuma criar uma pasta dentro da outra: entre até chegar na pasta onde está o `install.ps1`.

Se você usa git, pode clonar o repositório em vez de baixar o zip.

### 2. Abrir o PowerShell nessa pasta

- **Windows 11:** clique com o botão direito num espaço vazio da pasta e escolha **Abrir no Terminal**.
- **Windows 10:** segure **Shift**, clique com o botão direito num espaço vazio e escolha **Abrir janela do PowerShell aqui**.

> Use o PowerShell, não o Prompt de Comando: alguns comandos usam variáveis do PowerShell, como `$HOME`. Todos os comandos chamam `powershell -ExecutionPolicy Bypass` de propósito, para rodar sem mudar a política de execução do Windows.

### 3. Rodar os testes automáticos

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Handoff.ps1
```

Isso confere se o código funciona no seu Windows. A última linha deve ser:

```
62 passaram, 0 falharam
```

Se o seu Windows estiver em inglês, tudo aparece em inglês (`62 passed, 0 failed`); veja em [Configuração](#configuração) como escolher o idioma. Se algum teste falhar, pare aqui e veja [Se algo der errado](#se-algo-der-errado).

### 4. Instalar

Continue **na mesma janela do PowerShell do passo 2**, ainda dentro da pasta extraída que contém o `install.ps1`. Se quiser conferir antes de instalar:

```powershell
Test-Path .\install.ps1
```

O resultado precisa ser `True`. Então rode:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

Você roda o instalador **a partir da pasta do projeto**; ele copia a skill para `C:\Users\<você>\.claude\skills\handoff`. A saída deve mostrar `Instalada em C:\Users\<você>\.claude\skills\handoff`.

### 5. Configurar e conferir as contas

- **Se você usa uma conta só:** não precisa editar nada. A conta `work` do arquivo de exemplo só é usada quando você pede por ela.
- **Se você usa uma segunda instância:** abra o arquivo de configuração instalado:

  ```powershell
  notepad "$HOME\.claude\skills\handoff\config.json"
  ```

  O `userDataDir` da conta `work` precisa ser **exatamente a mesma pasta** usada no `--user-data-dir` do atalho da segunda instância. O padrão `%USERPROFILE%\Claude-Work` vira, por exemplo, `C:\Users\SeuNome\Claude-Work`. Em JSON, barras invertidas escritas manualmente precisam aparecer duplicadas (`\\`).

Para não precisar "confiar no olho", deixe abertas as janelas do Claude que você pretende usar e rode:

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target accounts
```

Para uma segunda conta configurada corretamente, você deve ver algo parecido com:

```text
Contas configuradas
  main (padrão): Conta principal -> pasta padrão do app
  [ok]    A instância principal do Claude está rodando agora
  work: Claude Work -> C:\Users\SeuNome\Claude-Work
  [ok]    Pasta de dados existe: C:\Users\SeuNome\Claude-Work
  [ok]    Há uma instância do Claude rodando agora com este userDataDir
```

Isso verifica duas coisas separadas: a pasta configurada **existe** e há uma instância do Claude **rodando agora com exatamente aquele `userDataDir`**. Se aparecer `[aviso]`, abra a janela correspondente e rode de novo; se continuar sem bater, confira o `--user-data-dir` nas propriedades do atalho. Se o `config.json` estiver com JSON inválido, o comando informa claramente o arquivo e o erro de sintaxe.

Depois de instalada a skill, você não precisa decorar o PowerShell: dentro do Claude Code, **`/handoff accounts`** ou **`/handoff contas`** mostra a mesma lista e ainda lembra como usar as chaves (`main`, `work`, etc.).

### 6. Testar a abertura no Desktop

Deixe o Claude Desktop aberto (e a segunda instância, se tiver) e rode:

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target test
```

Se tiver a segunda instância, rode também:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target test -Account work
```

Cada comando mostra um diagnóstico e abre um chat de teste. O diagnóstico deve vir todo com `[ok]`, mais ou menos assim:

```
Diagnóstico do claude-handoff
  [ok]    PowerShell 5.1.22621.4391
  [ok]    config.json lido, 2 conta(s), idioma pt-BR
  [ok]    12 sessão(ões) do Claude Code em C:\Users\<você>\.claude\projects
  [ok]    Protocolo claude:// registrado no Windows
  [ok]    claude.exe: C:\Program Files\WindowsApps\Claude_...\app\claude.exe
  [ok]    Pasta de dados da conta 'work': C:\Users\<você>\Claude-Work
Enviei a solicitação para abrir um chat de teste em: Claude Work. ...
```

Confira se cada chat de teste apareceu **na janela certa**, com a frase de teste no campo de mensagem. Se sim, a parte difícil está validada.

### 7. Testar no Claude Code

Abra uma sessão **nova** do Claude Code em qualquer pasta de projeto e peça algo simples, como "liste os arquivos desta pasta". Depois teste nesta ordem (acrescente o nome da conta no fim para usar a segunda instância, por exemplo `/handoff chat work`):

| Comando | O esperado |
|---|---|
| `/handoff accounts` | Lista as contas configuradas, marca a padrão e confere as instâncias abertas. `/handoff contas` faz a mesma coisa |
| `/handoff --help` | Mostra destinos, contas, níveis de detalhe, nota de passagem e exemplos de uso |
| `/handoff export` | O Claude mostra o caminho de um arquivo `.md` em `~/.claude/handoffs`. Abra e veja se a conversa está lá |
| `/handoff chat` | Se o texto completo do campo tiver até cerca de **13.000 caracteres**, o chat abre **já preenchido** e basta pressionar **Enter**. Acima disso, o script usa a área de transferência: **Ctrl+V** e **Enter**, preservando a transcrição inteira |
| `/handoff cowork` | Abre uma tarefa do Cowork com o arquivo da conversa anexado. O Desktop pede para confirmar a pasta do projeto |
| `/handoff` ou `/handoff code` | Abre a mesma sessão na aba Code do Desktop. Depois digite `/exit` no terminal |

Na primeira vez, o Claude Code pode pedir permissão para gravar um arquivo (a nota de passagem) e para rodar o `powershell`. É esperado: pode aprovar.

## Se algo der errado

| O que aconteceu | Causa provável | O que fazer |
|---|---|---|
| "a execução de scripts foi desabilitada neste sistema" | Comando rodado sem `-ExecutionPolicy Bypass` | Use os comandos exatamente como estão aqui |
| Erro com `$h` ou `$HOME` | Comando rodado no Prompt de Comando | Rode no PowerShell (passo 2) |
| Algum teste falhou no passo 3 | Diferença no PowerShell da sua máquina | Abra uma issue neste repositório com a saída completa do teste |
| `[erro] Não encontrei o claude.exe` | App instalado num lugar fora do padrão | No Gerenciador de Tarefas, clique com o botão direito num processo do Claude, escolha **Abrir local do arquivo** e coloque o caminho do `claude.exe` em `claudeExe` no `config.json` |
| `[erro] Protocolo claude:// não registrado` | Claude Desktop não instalado, ou instalação com problema | Reinstale o Claude Desktop |
| `[erro] Pasta de dados da conta 'work' não existe` | O `userDataDir` não bate com o da sua segunda instância, ou ela nunca foi aberta | Copie o caminho do `--user-data-dir` do atalho da instância para o `userDataDir` |
| O chat de teste da `work` abriu na janela principal | O `userDataDir` aponta para outra pasta | Mesma solução da linha anterior |
| Aparecem linhas `Unable to move the cache`, `Unable to create cache` ou `Gpu Cache Creation failed`, mas o chat abre na janela certa | O Electron iniciou um processo curto para encaminhar o link à instância já aberta e escreveu diagnósticos de cache no PowerShell | Se a janela certa abriu e o Claude funciona normalmente, essas linhas são ruído e não indicam falha do handoff. Na conta `work`, o processo auxiliar tenta ocultar esse `stderr`; na conta principal, o script prioriza a abertura confiável pelo protocolo `claude://`, então algumas versões do Claude/Windows ainda podem mostrar essas linhas. Não troque essa abertura por `rundll32`: em instalações MSIX ele pode retornar sem abrir o Claude. |
| `/handoff` não aparece no Claude Code | A sessão foi aberta antes da instalação | Abra uma sessão nova. Confira se existe `~/.claude/skills/handoff/SKILL.md` |
| O `chat` pediu Ctrl+V em vez de vir preenchido | O texto completo passou do limite seguro do parâmetro `q` | O Claude trunca `q` por volta de 14.000 caracteres. O handoff usa ~13.000 como margem; acima disso o fallback preserva tudo: **Ctrl+V** e **Enter** |
| O Ctrl+V do fallback não colou nada | O campo de mensagem não estava selecionado | Clique no campo e cole de novo. Ou arraste para o chat o arquivo `.md` cujo caminho o Claude mostrou |
| No `code`, a aba Code não achou a sessão | A sessão está numa pasta que o Desktop não lê | Veja [Limitações](#limitações) |

## O que chega em cada destino

| Destino | Como chega | O que chega |
|---|---|---|
| `code` | Link `claude://resume` | A própria sessão, com todo o histórico |
| `chat` | Chat novo. Até ~13.000 caracteres de prompt vão preenchidos automaticamente; acima disso cai no fallback da área de transferência | Transcrição da conversa |
| `cowork` | Tarefa nova com a transcrição anexada e a pasta do projeto | Transcrição da conversa |
| `export` | Arquivo em `~/.claude/handoffs/` | Transcrição sem limite de tamanho |

> **Por que o `chat` ainda pode pedir Ctrl+V?** O deep link de Chat só oferece o parâmetro `q`, e o próprio Claude trunca esse texto por volta de 14.000 caracteres. O handoff mede o **texto real antes da codificação da URL** e concatena instrução + transcrição diretamente em `q` sempre que o total fica em até ~13.000 caracteres. Para conversas acima do limite real de `q`, o clipboard continua necessário para não cortar a transcrição silenciosamente. Referência oficial: <https://support.claude.com/pt/articles/14729294-abrir-claude-desktop-com-um-link>.

### O que a transcrição contém

É a conversa real, mensagem por mensagem, organizada em turnos:

- suas mensagens e as respostas do Claude;
- cada ferramenta usada: comandos com a saída, edições como diff, arquivos criados, lista de tarefas;
- erros das ferramentas;
- os slash commands que você rodou;
- marcação de onde houve `/compact`, com o histórico **de antes** da compactação recuperado;
- no topo, uma tabela com sessão, pasta, branch e período, e uma **nota de passagem** curta escrita pelo Claude (onde parou, próximo passo, cuidados).

Fica de fora: raciocínio interno do modelo, mensagens de sistema, subagentes e ramos descartados por `/rewind`.

### Quando a conversa é grande

Cada destino tem um limite de caracteres (configurável). Se passar, o corte segue esta ordem, do que menos faz falta ao que mais faz:

1. turnos antigos perdem detalhe (ficam só as ações, sem as saídas);
2. turnos antigos do meio são omitidos;
3. os 8 turnos mais recentes perdem detalhe;
4. o resto do meio é omitido.

O primeiro turno (que costuma ter o objetivo) e o último ficam sempre. Tudo que foi cortado é avisado no topo do arquivo. Para ter a conversa inteira sem corte, use `/handoff export`.

## Uso

A forma geral é:

```
/handoff [destino] [conta] [detalhe] [sem nota]
```

Sem argumento nenhum, **`/handoff` continua sendo igual a `/handoff code`**.

| Argumento | Valores | Padrão |
|---|---|---|
| destino | `code`, `chat`, `cowork`, `export` | `code` |
| conta | uma chave do `config.json`, como `main` ou `work` | `defaultAccount` |
| detalhe | `full`/`completo`, `normal`, `compact`/`enxuto` | o do destino no `config.json` |
| `no note` / `sem nota` | retira a nota curta de passagem | com nota |

### Descobrir contas e pedir ajuda

Você não precisa lembrar o nome das contas:

```text
/handoff accounts
/handoff contas
```

Os dois comandos listam as **chaves que podem ser usadas nos outros comandos**, mostram qual é a padrão e conferem a pasta/instância correspondente. Exemplo: se aparecer `work: Claude Work`, a chave é `work`, então você pode usar `/handoff chat work` ou `/handoff code work`.

Para ver a referência completa sem abrir o README:

```text
/handoff --help
```

Também funcionam `/handoff -h`, `/handoff help` e `/handoff ajuda`. A ajuda mostra os destinos, as contas configuradas, os padrões atuais de detalhe, o significado da nota e exemplos prontos.

### O que significa `detail`

`detail` controla **quanto conteúdo entra na transcrição gerada** por `chat`, `cowork` e `export`. Ele **não tem efeito em `code`**, porque `code` retoma a própria sessão nativa, sem gerar uma transcrição. Também não se aplica a `accounts` nem a `help`.

| Nível | Mensagens do usuário/Claude | Saídas de ferramentas | Escritas/edições | Conteúdo de arquivos lidos |
|---|---:|---:|---:|---:|
| `full` / `completo` | sem corte individual | até 6.000 caracteres | até 6.000 | até 2.000 |
| `normal` | até 20.000 caracteres cada | até 1.200 | até 1.500 | omitido |
| `compact` / `enxuto` | até 3.000 caracteres cada | omitidas; erros ficam em uma linha | conteúdo omitido | omitido |

Mesmo no `compact`, as ações continuam aparecendo: por exemplo, que um comando foi executado, que um arquivo foi editado ou que uma ferramenta deu erro. O que some é o conteúdo pesado dessas ações.

Se você **não informar** o detalhe, vale o `config.json`. No arquivo padrão: `chat=normal`, `cowork=full` e `export=full`.

Exemplos:

```text
/handoff chat work full
/handoff cowork compact
/handoff export completo
```

### O que significa `no note` / `sem nota`

Por padrão, `chat`, `cowork` e `export` colocam no topo da transcrição uma **nota de passagem de até 10 linhas**, escrita a partir da sessão atual. Ela serve como orientação rápida e contém algo neste formato:

```text
Onde paramos: implementação concluída e testes executados.
Próximo passo: validar o fluxo no Desktop.
Cuidado: a conta work precisa estar aberta com o userDataDir correto.
```

Depois dessa nota vem a conversa real completa conforme o nível de detalhe escolhido. Portanto, `sem nota` **não remove a conversa**; remove somente essa introdução.

```text
/handoff chat work sem nota
/handoff cowork no note
/handoff export sem nota
```

Em `code`, `accounts` e `help`, esse parâmetro não se aplica.

### Exemplos rápidos

```text
/handoff                         # mesma sessão no Code da conta padrão
/handoff code work               # mesma sessão no Code da conta work
/handoff chat work               # novo Chat na work
/handoff chat work full          # Chat na work com transcrição mais detalhada
/handoff cowork work sem nota    # Cowork na work, sem nota de passagem
/handoff export compact          # só grava uma transcrição enxuta
/handoff accounts                # mostra as contas disponíveis
/handoff --help                  # mostra a ajuda completa
```

Linguagem natural também funciona: `/handoff manda pro chat da work bem completo`.

Depois do `code`, digite `/exit` no terminal. O `/desktop` nativo fecha o terminal sozinho; aqui não, e duas janelas escrevendo na mesma sessão dá problema.

### Direto no PowerShell, sem o Claude Code

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target help
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target accounts
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target export
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target chat -Account work -SessionId <id>
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target cowork -Account work -Detail full
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target code -SessionId <id> -DryRun
```

O script também aceita `-Target contas` e `-Target ajuda`. Sem `-SessionId`, ele usa a sessão mais recente da pasta onde o terminal está. `-DryRun` mostra o link sem abrir nada. O ID da sessão é o nome do arquivo `.jsonl` em `~/.claude/projects/<pasta>/`.

## Configuração

`~/.claude/skills/handoff/config.json`:

```json
{
  "language": "auto",
  "defaultAccount": "main",
  "claudeExe": "",
  "handoffsDir": "",
  "redactSecrets": true,
  "export": {
    "chat":   { "detail": "normal", "maxChars": 300000 },
    "cowork": { "detail": "full",   "maxChars": 600000 },
    "export": { "detail": "full",   "maxChars": 0 }
  },
  "accounts": {
    "main": {},
    "work": { "label": "Claude Work", "userDataDir": "%USERPROFILE%\\Claude-Work" }
  }
}
```

| Campo | Para que serve |
|---|---|
| `language` | `auto` segue o idioma do Windows (português em sistemas em português, inglês nos outros). Use `pt-BR` ou `en` para fixar. Vale para mensagens, testes e transcrições |
| `defaultAccount` | Conta usada quando você não informa uma |
| `claudeExe` | Caminho do `claude.exe`. Vazio = procura sozinho (pacote MSIX ou instalação antiga), o que acompanha as atualizações do app |
| `handoffsDir` | Onde salvar as transcrições. Vazio = `~/.claude/handoffs` |
| `redactSecrets` | Liga ou desliga a máscara de segredos |
| `export.<destino>.detail` | `full`, `normal` ou `compact` |
| `export.<destino>.maxChars` | Limite de caracteres; `0` = sem limite |
| `accounts.<nome>.label` | Nome que aparece nas mensagens. Opcional |
| `accounts.<nome>.userDataDir` | Pasta de dados da instância. Sem ela, abre na instância principal |

Pode ter quantas contas quiser. Como o arquivo é JSON, as barras invertidas dos caminhos vão dobradas (`\\`).

Os níveis de detalhe estão explicados com exemplos em [Uso](#o-que-significa-detail). Em resumo, eles controlam o conteúdo **dentro de cada turno**; já `maxChars` limita o tamanho **total** da transcrição depois disso. `code` não usa nenhum dos dois porque retoma a sessão nativa.

O limite padrão da transcrição do chat é 300 mil caracteres; do Cowork, 600 mil; e `export` usa `0`, isto é, sem limite total. Esses limites não significam que todo esse texto cabe no campo do Chat por `claude://`: a abertura automática do Chat usa uma regra separada e, quando a URL ficaria grande demais, troca sozinha para o fallback da área de transferência.

## Privacidade e segurança

- **O script não acessa a internet.** Ele lê as sessões do Claude Code no seu disco, grava arquivos locais e abre links `claude://` no app. A conversa só sai do seu computador quando você envia a mensagem no Desktop, como qualquer conversa com o Claude.
- **As transcrições ficam salvas** em `~/.claude/handoffs`, com o conteúdo das suas conversas. Apague as que não precisar mais.
- **Segredos são mascarados.** Antes de gravar, o script troca por `[oculto]` (`[hidden]` em inglês) o que parece segredo: chaves de API (Anthropic, OpenAI, GitHub, AWS, Google, Slack), tokens JWT e Bearer, chaves privadas, variáveis de `.env` com KEY/TOKEN/SECRET/PASSWORD/SENHA no nome e `Password=` em connection strings. A contagem aparece no topo do arquivo. É uma proteção de melhor esforço, não uma garantia: dê uma olhada antes de mandar.
- **Cuidado ao trocar de conta.** Mandar uma conversa da conta do trabalho para a pessoal (ou o contrário) copia aquele conteúdo para a outra conta. Confira se você pode fazer isso.
- **O código é curto e legível.** Está todo em `handoff/`. Leia antes de instalar, se quiser.

## Atualizar e remover

- **Atualizar:** baixe a versão nova e rode o `install.ps1` de novo. Seu `config.json` é mantido.
- **Vindo da primeira versão:** o instalador leva suas contas do `accounts.json` para o `config.json` e guarda o antigo como `accounts.json.bak`.
- **Remover:**

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
  ```

  As transcrições já geradas continuam em `~/.claude/handoffs`; apague a pasta se não quiser mais.

## Como funciona

**Links `claude://`.** O Claude Desktop tem [links oficiais](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link) para abrir chat (`claude://claude.ai/new?q=`) e Cowork (`claude://cowork/new?q=&file=&folder=`). O link de retomar sessão (`claude://resume?session=`) é o que o `/desktop` nativo usa por dentro (visto no Claude Code 2.1.301). Esse não é documentado e pode mudar.

**Escolha da instância.** O Windows entrega links `claude://` sempre para a instância principal, porque o protocolo é registrado uma vez só. Para outra instância, o script chama o `claude.exe` com o mesmo `--user-data-dir` dela e passa o link como argumento. O Electron repassa para a janela que já está aberta com aquela pasta.

**Por que o Chat usa dois modos.** O `claude://claude.ai/new?q=` consegue preencher o campo do Chat, mas o Claude documenta que `q` é truncado por volta de **14.000 caracteres do prompt já decodificado**. Por isso, o script concatena a instrução inicial + a transcrição diretamente em `q` até **13.000 caracteres** de texto real, com uma segunda proteção de 30.000 caracteres na URL codificada para o Windows. Acima disso, ele abre a mensagem inicial e coloca a transcrição completa na área de transferência para **Ctrl+V + Enter**, em vez de perder silenciosamente o final. O Cowork aceita arquivo no link, por isso nele a transcrição continua indo anexada diretamente.

**Leitura da sessão.** As sessões ficam em `~/.claude/projects/<pasta>/<id>.jsonl`, uma linha por registro, cada uma apontando para o registro anterior. O script parte da última mensagem e sobe pela cadeia, o que deixa de fora os ramos de `/rewind`. Depois de um `/compact`, segue o ponteiro para o histórico de antes. O arquivo é lido em modo compartilhado, então funciona com a sessão aberta.

## Limitações

- **Só Windows.** No macOS, o princípio é o mesmo, mas o script não foi adaptado.
- **Chat e Cowork recebem uma transcrição, não a sessão.** O Claude de lá lê tudo, mas não tem o estado interno do Claude Code (permissões, ferramentas carregadas, arquivos em cache).
- **A sessão passa a contar na conta de destino.** Mandar para a outra conta significa usar o plano dela dali em diante.
- **O Code da outra instância precisa enxergar a sessão.** Se você usa `CLAUDE_CONFIG_DIR` para separar contas no terminal, a sessão fica em outra pasta e o Desktop pode não achar.
- **Cowork pede confirmação da pasta.** É regra do Desktop para pasta que chega por link.
- **Sessões enormes demoram alguns segundos.** Uma sessão de 9 MB leva uns 7 segundos no PowerShell 7; no Windows PowerShell 5.1 pode levar mais.
- **Depende de comportamentos não documentados** (o link `claude://resume` e a opção `--user-data-dir` do app). Uma atualização do Claude pode exigir ajustes.

## Estrutura do projeto

```
claude-handoff/
├── install.ps1             instala, atualiza, migra e remove
├── handoff/                vai para ~/.claude/skills/handoff
│   ├── SKILL.md            o comando /handoff
│   ├── config.json         contas e limites
│   ├── handoff.ps1         entrada: lê os parâmetros e orquestra
│   └── lib/
│       ├── I18n.ps1        todas as mensagens, em português e inglês
│       ├── Config.ps1      config.json, contas, pastas
│       ├── Desktop.ps1     acha o claude.exe, monta e abre os links
│       ├── Session.ps1     acha e lê o .jsonl, reconstrói a conversa ativa
│       └── Transcript.ps1  gera o Markdown, níveis, limite e segredos
└── tests/
    ├── Test-Handoff.ps1    62 verificações, sem dependências
    └── fixtures/           sessão de exemplo com rewind, compact e segredos
```

## Contribuindo

Issues e pull requests são bem-vindos. Antes de abrir um PR:

- rode os testes (`.\tests\Test-Handoff.ps1`) e confira que todos passam;
- mantenha o código compatível com o Windows PowerShell 5.1: nada de sintaxe exclusiva do PowerShell 7, como `??`, `?.` ou o operador ternário;
- salve os `.ps1` em UTF-8 **com BOM**. Sem o BOM, o Windows PowerShell 5.1 lê os acentos errado;
- coloque todo texto novo que aparece para o usuário em `handoff/lib/I18n.ps1`, nos dois idiomas (um teste confere se falta algum).

## Licença

[MIT](LICENSE)
