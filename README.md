# claude-handoff

**English** · [Português (Brasil)](README.pt-BR.md)

Moves a **Claude Code (terminal)** session into the **Claude Desktop** app: into the Code tab, Chat or Cowork, and into the account you choose, including a second account open at the same time.

```
/handoff                  same session, in Desktop's Code tab (default)
/handoff chat             the whole conversation in a new chat
/handoff cowork work      the whole conversation attached to a Cowork task on the "work" account
/handoff export           just writes the conversation file, with no size limit
/handoff accounts         shows the accounts you can use (also: /handoff contas)
/handoff --help           shows all commands, parameters and examples
```

> Community project, not affiliated with Anthropic. Windows only. Speaks English and Brazilian Portuguese, following your Windows display language.

## Why it exists

Claude Code already has a `/desktop` command that moves the terminal session into the app. But it has two limits:

- it only opens in the **Code tab**, never in Chat or Cowork;
- it only opens in the app's **main instance**. If you run a second account at the same time (for example with [claude-desktop-multi-account-windows](https://github.com/VinguardCP/claude-desktop-multi-account-windows)), you can't send the session to it.

`/handoff` solves both. In Chat and Cowork it carries the **real conversation, message by message**, not a summary.

## Contents

- [Requirements](#requirements)
- [Install and first test](#install-and-first-test)
- [Troubleshooting](#troubleshooting)
- [What arrives at each destination](#what-arrives-at-each-destination)
- [Usage](#usage)
- [Configuration](#configuration)
- [Privacy and security](#privacy-and-security)
- [Update and uninstall](#update-and-uninstall)
- [How it works](#how-it-works)
- [Limitations](#limitations)
- [Project structure](#project-structure)
- [Contributing](#contributing)

## Requirements

- **Windows 10 or 11.** Windows PowerShell 5.1 ships with Windows; nothing else to install.
- **Claude Desktop**, up to date ([download](https://claude.com/download)).
- **Claude Code** installed natively on Windows (not inside WSL), up to date (`claude update`), signed in and used at least once. The project was built against Claude Code 2.1.301.
- A **Claude plan that includes Claude Code**. The `cowork` destination only works if your plan also includes Cowork.
- **Optional:** a second Desktop instance with another account, created with [multi-account](https://github.com/VinguardCP/claude-desktop-multi-account-windows). Without it, everything works on the main account.

## Install and first test

It takes about 10 minutes. Nothing here deletes or changes your files: the project only writes to the skill folder (`~/.claude/skills/handoff`) and the transcripts folder (`~/.claude/handoffs`).

### 1. Download

On this repository's page, click **Code**, then **Download ZIP**. Extract it (right-click → **Extract All**). Windows usually creates a folder inside another: go in until you reach the folder that contains `install.ps1`.

If you use git, you can clone the repository instead of downloading the ZIP.

### 2. Open PowerShell in that folder

- **Windows 11:** right-click an empty area of the folder and choose **Open in Terminal**.
- **Windows 10:** hold **Shift**, right-click an empty area and choose **Open PowerShell window here**.

> Use PowerShell, not Command Prompt: some commands use PowerShell variables such as `$HOME`. Every command calls `powershell -ExecutionPolicy Bypass` on purpose, so it runs without changing your Windows execution policy.

### 3. Run the automated tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-Handoff.ps1
```

This checks that the code works on your Windows. The last line should be:

```
62 passed, 0 failed
```

If your Windows is in Portuguese, everything shows up in Portuguese instead (`62 passaram, 0 falharam`); see [Configuration](#configuration) to pick the language. If any test fails, stop here and see [Troubleshooting](#troubleshooting).

### 4. Install

Stay in **the same PowerShell window from step 2**, still inside the extracted project folder that contains `install.ps1`. If you want to verify your location first:

```powershell
Test-Path .\install.ps1
```

It must return `True`. Then run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

You run the installer **from the project folder**; it copies the skill to `C:\Users\<you>\.claude\skills\handoff`. The output should include `Installed in C:\Users\<you>\.claude\skills\handoff`.

### 5. Set up and verify the accounts

- **If you use a single account:** you do not need to edit anything. The `work` account in the sample file is only used when you ask for it.
- **If you use a second instance:** open the installed configuration file:

  ```powershell
  notepad "$HOME\.claude\skills\handoff\config.json"
  ```

  The `userDataDir` of the `work` account must be **exactly the same folder** used by the `--user-data-dir` in the second instance's shortcut. The default `%USERPROFILE%\Claude-Work` becomes, for example, `C:\Users\YourName\Claude-Work`. In JSON, backslashes you type manually must be doubled (`\\`).

To verify it instead of just eyeballing the file, leave the Claude windows you want to use open and run:

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target accounts
```

For a correctly configured second account, you should see something like:

```text
Configured accounts
  main (default): Main account -> app default folder
  [ok]    Main Claude instance is running now
  work: Claude Work -> C:\Users\YourName\Claude-Work
  [ok]    Data folder exists: C:\Users\YourName\Claude-Work
  [ok]    Claude instance is running now with this userDataDir
```

This checks two separate things: the configured folder **exists**, and a Claude instance is **running right now with exactly that `userDataDir`**. If you get `[warn]`, open the intended window and run the command again; if it still does not match, check `--user-data-dir` in the shortcut properties. If `config.json` contains invalid JSON, the command reports the file and the syntax error clearly.

Once the skill is installed, you do not need to remember the PowerShell command: inside Claude Code, **`/handoff accounts`** or **`/handoff contas`** shows the same list and reminds you how to use the keys (`main`, `work`, etc.).

### 6. Test opening the Desktop app

Leave Claude Desktop open (and the second instance, if you have one) and run:

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target test
```

If you have the second instance, also run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target test -Account work
```

Each command prints a diagnosis and opens a test chat. The diagnosis should be all `[ok]`, roughly like this:

```
claude-handoff diagnostics
  [ok]    PowerShell 5.1.22621.4391
  [ok]    config.json read, 2 account(s), language en
  [ok]    12 Claude Code session(s) in C:\Users\<you>\.claude\projects
  [ok]    claude:// protocol registered in Windows
  [ok]    claude.exe: C:\Program Files\WindowsApps\Claude_...\app\claude.exe
  [ok]    Data folder for account 'work': C:\Users\<you>\Claude-Work
Sent the request to open a test chat in: Claude Work. ...
```

Check that each test chat showed up **in the right window**, with the test sentence in the message field. If so, the hard part is validated.

### 7. Test it in Claude Code

Open a **new** Claude Code session in any project folder and ask for something simple, like "list the files in this folder". Then test in this order (add the account name at the end to use the second instance, for example `/handoff chat work`):

| Command | Expected |
|---|---|
| `/handoff accounts` | Lists configured accounts, marks the default and checks the running instances. `/handoff contas` does the same |
| `/handoff --help` | Shows destinations, accounts, detail levels, the handoff note and usage examples |
| `/handoff export` | Claude prints the path of a `.md` file in `~/.claude/handoffs`. Open it and check the conversation is there |
| `/handoff chat` | If the transcript safely fits in the link, the chat opens **already filled in** and you only press **Enter**. If it is large, the script says it used the clipboard: then press **Ctrl+V** and **Enter** |
| `/handoff cowork` | Opens a Cowork task with the conversation file attached. Desktop asks you to confirm the project folder |
| `/handoff` or `/handoff code` | Opens the same session in Desktop's Code tab. Then type `/exit` in the terminal |

The first time, Claude Code may ask permission to write a file (the handoff note) and to run `powershell`. That's expected: approve it.

## Troubleshooting

| What happened | Likely cause | What to do |
|---|---|---|
| "running scripts is disabled on this system" | Command run without `-ExecutionPolicy Bypass` | Use the commands exactly as written here |
| Error mentioning `$h` or `$HOME` | Command run in Command Prompt | Run it in PowerShell (step 2) |
| A test failed in step 3 | Something different in your machine's PowerShell | Open an issue in this repository with the full test output |
| `[error] Couldn't find Claude Desktop's claude.exe` | App installed in a non-standard place | In Task Manager, right-click a Claude process, choose **Open file location** and put the path to `claude.exe` in `claudeExe` in `config.json` |
| `[error] claude:// protocol not registered` | Claude Desktop not installed, or a broken install | Reinstall Claude Desktop |
| `[error] Data folder for account 'work' doesn't exist` | `userDataDir` doesn't match your second instance, or it was never opened | Copy the `--user-data-dir` path from the instance's shortcut into `userDataDir` |
| The `work` test chat opened in the main window | `userDataDir` points to another folder | Same fix as the previous row |
| `Unable to move the cache`, `Unable to create cache`, or `Gpu Cache Creation failed` appears, but the chat opens in the correct window | Electron started a short-lived process to forward the link to the already-running instance and wrote cache diagnostics to PowerShell | If the correct window opened and Claude works normally, those lines are noise and do not indicate a handoff failure. For the `work` account, the helper process tries to hide that `stderr`; for the main account, the script prioritizes reliable `claude://` protocol opening, so some Claude/Windows versions may still print those lines. Do not replace this with `rundll32`: on MSIX installs it can return without opening Claude. |
| `/handoff` doesn't show up in Claude Code | The session was opened before installing | Open a new session. Check that `~/.claude/skills/handoff/SKILL.md` exists |
| `chat` asked for Ctrl+V instead of arriving prefilled | The transcript was too large for the safe link limit | This is the normal fallback: click the field, press **Ctrl+V**, then **Enter** |
| Ctrl+V in the fallback pasted nothing | The message field wasn't focused | Click the field and paste again. Or drag into the chat the `.md` file whose path Claude printed |
| With `code`, the Code tab couldn't find the session | The session lives in a folder Desktop doesn't read | See [Limitations](#limitations) |

## What arrives at each destination

| Destination | How it arrives | What arrives |
|---|---|---|
| `code` | `claude://resume` link | The session itself, with its full history |
| `chat` | New chat. Small transcripts are prefilled automatically; large transcripts use the clipboard fallback | Conversation transcript |
| `cowork` | New task with the transcript attached and the project folder | Conversation transcript |
| `export` | File in `~/.claude/handoffs/` | Transcript with no size limit |

> **Why can `chat` still ask for Ctrl+V?** The Chat deep link only exposes the `q` parameter, and Claude itself truncates that text at roughly 14,000 characters. Handoff measures the **decoded prompt text before URL encoding** and concatenates instruction + transcript directly into `q` whenever the total is at most ~13,000 characters. Above the real `q` limit, the clipboard fallback remains necessary so the transcript is not silently cut. Official reference: <https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link>.

### What the transcript contains

It's the real conversation, message by message, organized in turns:

- your messages and Claude's replies;
- every tool used: commands with their output, edits as diffs, files created, the to-do list;
- tool errors;
- the slash commands you ran;
- a marker where `/compact` happened, with the history from **before** compaction recovered;
- at the top, a table with session, folder, branch and time range, plus a short **handoff note** written by Claude (where it stopped, next step, things to watch out for).

Left out: the model's internal reasoning, system messages, subagents and branches discarded by `/rewind`.

### When the conversation is large

Each destination has a character limit (configurable). When it's exceeded, cuts happen in this order, from what matters least to what matters most:

1. older turns lose detail (only the actions stay, without output);
2. older turns in the middle are omitted;
3. the 8 most recent turns lose detail;
4. the rest of the middle is omitted.

The first turn (which usually states the goal) and the last one always stay. Everything that was cut is noted at the top of the file. For the whole conversation with no cuts, use `/handoff export`.

## Usage

General form:

```
/handoff [destination] [account] [detail] [no note]
```

With no arguments, **`/handoff` is still the same as `/handoff code`**.

| Argument | Values | Default |
|---|---|---|
| destination | `code`, `chat`, `cowork`, `export` | `code` |
| account | a key from `config.json`, such as `main` or `work` | `defaultAccount` |
| detail | `full`/`completo`, `normal`, `compact`/`enxuto` | the destination's value in `config.json` |
| `no note` / `sem nota` | removes the short handoff note | with note |

### Discover accounts and get help

You do not need to remember the account names:

```text
/handoff accounts
/handoff contas
```

Both commands list the **keys you can use in other commands**, show which one is the default, and check the matching folder/running instance. Example: if it shows `work: Claude Work`, the key is `work`, so `/handoff chat work` and `/handoff code work` are valid.

For the complete reference without opening the README:

```text
/handoff --help
```

`/handoff -h`, `/handoff help` and `/handoff ajuda` work too. Help shows destinations, configured accounts, current detail defaults, handoff-note behavior and ready-to-copy examples.

### What `detail` means

`detail` controls **how much content goes into the generated transcript** for `chat`, `cowork` and `export`. It has **no effect on `code`**, because `code` resumes the native session instead of generating a transcript. It also does not apply to `accounts` or `help`.

| Level | User/Claude messages | Tool output | Writes/edits | Read-file contents |
|---|---:|---:|---:|---:|
| `full` / `completo` | no per-message cut | up to 6,000 chars | up to 6,000 | up to 2,000 |
| `normal` | up to 20,000 chars each | up to 1,200 | up to 1,500 | omitted |
| `compact` / `enxuto` | up to 3,000 chars each | omitted; errors remain as one line | contents omitted | omitted |

Even in `compact`, actions remain visible: for example, that a command ran, a file was edited, or a tool failed. What disappears is the heavy content of those actions.

If you **do not specify** a level, `config.json` decides. In the default file: `chat=normal`, `cowork=full`, `export=full`.

Examples:

```text
/handoff chat work full
/handoff cowork compact
/handoff export completo
```

### What `no note` / `sem nota` means

By default, `chat`, `cowork` and `export` put a **handoff note of at most 10 lines** at the top of the transcript. It is a quick orientation generated from the current session, in a form like:

```text
Where we stopped: implementation is complete and tests passed.
Next step: validate the flow in Desktop.
Watch out for: the work account must be open with the correct userDataDir.
```

The real conversation follows after that note according to the selected detail level. So `no note` **does not remove the conversation**; it removes only this introduction.

```text
/handoff chat work no note
/handoff cowork sem nota
/handoff export no note
```

This option does not apply to `code`, `accounts` or `help`.

### Quick examples

```text
/handoff                         # same session in Code on the default account
/handoff code work               # same session in Code on the work account
/handoff chat work               # new Chat on work
/handoff chat work full          # Chat on work with a more detailed transcript
/handoff cowork work no note     # Cowork on work, without a handoff note
/handoff export compact          # only write a compact transcript
/handoff accounts                # show available accounts
/handoff --help                  # show full help
```

Natural language works too: `/handoff send it to the work chat, full detail`.

After `code`, type `/exit` in the terminal. The native `/desktop` closes the terminal session on its own; this doesn't, and two windows writing to the same session causes trouble.

### Straight from PowerShell, without Claude Code

```powershell
$h = "$HOME\.claude\skills\handoff\handoff.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target help
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target accounts
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target export
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target chat -Account work -SessionId <id>
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target cowork -Account work -Detail full
powershell -NoProfile -ExecutionPolicy Bypass -File $h -Target code -SessionId <id> -DryRun
```

The script also accepts `-Target contas` and `-Target ajuda`. Without `-SessionId`, it uses the most recent session in the folder the terminal is in. `-DryRun` prints the link without opening anything. The session ID is the `.jsonl` filename in `~/.claude/projects/<folder>/`.

## Configuration

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

| Field | Purpose |
|---|---|
| `language` | `auto` follows the Windows display language (Portuguese on Portuguese systems, English otherwise). Use `en` or `pt-BR` to pin it. Applies to messages, tests and transcripts |
| `defaultAccount` | Account used when you don't name one |
| `claudeExe` | Path to `claude.exe`. Empty = found automatically (MSIX package or older install), which keeps up with app updates |
| `handoffsDir` | Where transcripts are saved. Empty = `~/.claude/handoffs` |
| `redactSecrets` | Turns secret masking on or off |
| `export.<destination>.detail` | `full`, `normal` or `compact` |
| `export.<destination>.maxChars` | Character limit; `0` = no limit |
| `accounts.<name>.label` | Name shown in messages. Optional |
| `accounts.<name>.userDataDir` | The instance's data folder. Without it, the main instance opens |

You can have as many accounts as you like. Since the file is JSON, backslashes in paths are doubled (`\\`).

The detail levels are explained with examples in [Usage](#what-detail-means). In short, they control content **inside each turn**, while `maxChars` limits the **total transcript size** after that. `code` uses neither because it resumes the native session.

The default total transcript limit is 300,000 characters for Chat, 600,000 for Cowork, and `0` (unlimited) for `export`. Those limits do not mean all that text fits in the Chat field through `claude://`: Chat autofill uses a separate safety rule and automatically switches to the clipboard fallback when the URL would be too large.

## Privacy and security

- **The script never goes online.** It reads Claude Code sessions from your disk, writes local files and opens `claude://` links in the app. The conversation only leaves your computer when you send the message in Desktop, like any conversation with Claude.
- **Transcripts are kept** in `~/.claude/handoffs`, with the content of your conversations. Delete the ones you no longer need.
- **Secrets are masked.** Before writing, the script replaces anything that looks like a secret with `[hidden]` (`[oculto]` in Portuguese): API keys (Anthropic, OpenAI, GitHub, AWS, Google, Slack), JWT and Bearer tokens, private keys, `.env` variables with KEY/TOKEN/SECRET/PASSWORD/SENHA in the name, and `Password=` in connection strings. The count appears at the top of the file. This is best-effort protection, not a guarantee: take a look before sending.
- **Be careful when switching accounts.** Sending a conversation from a work account to a personal one (or the other way around) copies that content into the other account. Make sure you're allowed to.
- **The code is short and readable.** It all lives in `handoff/`. Read it before installing, if you like.

## Update and uninstall

- **Update:** download the new version and run `install.ps1` again. Your `config.json` is kept.
- **Coming from the first version:** the installer moves your accounts from `accounts.json` into `config.json` and keeps the old file as `accounts.json.bak`.
- **Uninstall:**

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
  ```

  Transcripts you already generated stay in `~/.claude/handoffs`; delete that folder if you no longer want them.

## How it works

**`claude://` links.** Claude Desktop has [official links](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link) to open a chat (`claude://claude.ai/new?q=`) and Cowork (`claude://cowork/new?q=&file=&folder=`). The session resume link (`claude://resume?session=`) is what the native `/desktop` uses internally (seen in Claude Code 2.1.301). That one is undocumented and may change.

**Choosing the instance.** Windows always delivers `claude://` links to the main instance, because the protocol is registered only once. For another instance, the script runs `claude.exe` with that instance's `--user-data-dir` and passes the link as an argument. Electron forwards it to the window already open with that folder.

**Why Chat has two modes.** `claude://claude.ai/new?q=` can prefill the Chat field, but Claude documents that `q` is truncated at roughly **14,000 decoded prompt characters**. The script therefore concatenates the starter instruction + transcript directly into `q` up to **13,000 characters** of decoded text, with a second 30,000-character guard on the encoded URL for Windows. Above that, it opens the starter message and puts the full transcript on the clipboard for **Ctrl+V + Enter** instead of silently losing the tail. Cowork accepts a file in the link, so its transcript stays attached directly.

**Reading the session.** Sessions live in `~/.claude/projects/<folder>/<id>.jsonl`, one line per record, each pointing to the previous record. The script starts from the last message and walks up the chain, which leaves out branches discarded by `/rewind`. After a `/compact`, it follows the pointer to the earlier history. The file is opened in shared mode, so it works while the session is open.

## Limitations

- **Windows only.** The same idea would work on macOS, but the script hasn't been adapted.
- **Chat and Cowork receive a transcript, not the session.** Claude there reads everything, but doesn't have Claude Code's internal state (permissions, loaded tools, cached files).
- **The session is billed to the destination account from then on.** Sending it to the other account means using that account's plan from that point.
- **The other instance's Code tab must be able to see the session.** If you use `CLAUDE_CONFIG_DIR` to separate accounts in the terminal, the session lives in another folder and Desktop may not find it.
- **Cowork asks you to confirm the folder.** That's a Desktop rule for folders that arrive through a link.
- **Huge sessions take a few seconds.** A 9 MB session takes about 7 seconds in PowerShell 7; Windows PowerShell 5.1 may take longer.
- **Relies on undocumented behavior** (the `claude://resume` link and the app's `--user-data-dir` option). A Claude update may require adjustments.

## Project structure

```
claude-handoff/
├── install.ps1             installs, updates, migrates and uninstalls
├── handoff/                copied to ~/.claude/skills/handoff
│   ├── SKILL.md            the /handoff command
│   ├── config.json         accounts and limits
│   ├── handoff.ps1         entry point: reads parameters and orchestrates
│   └── lib/
│       ├── I18n.ps1        every message, in English and Portuguese
│       ├── Config.ps1      config.json, accounts, folders
│       ├── Desktop.ps1     finds claude.exe, builds and opens links
│       ├── Session.ps1     finds and reads the .jsonl, rebuilds the active conversation
│       └── Transcript.ps1  writes the Markdown: levels, limit, secrets
└── tests/
    ├── Test-Handoff.ps1    62 checks, no dependencies
    └── fixtures/           sample session with rewind, compact and secrets
```

## Contributing

Issues and pull requests are welcome. Before opening a PR:

- run the tests (`.\tests\Test-Handoff.ps1`) and make sure they all pass;
- keep the code compatible with Windows PowerShell 5.1: no PowerShell 7-only syntax such as `??`, `?.` or the ternary operator;
- save `.ps1` files as UTF-8 **with BOM**. Without the BOM, Windows PowerShell 5.1 misreads accented characters;
- put new user-facing text in `handoff/lib/I18n.ps1`, in both languages (a test checks that none is missing).

## License

[MIT](LICENSE)
