---
name: handoff
description: Moves this terminal session into Claude Desktop (Code tab, Chat or Cowork) on any configured account, including instances opened with --user-data-dir. In Chat and Cowork the whole conversation goes along, exported message by message.
argument-hint: "[code|chat|cowork|export|accounts|contas|--help] [account] [full|normal|compact] [no note]"
disable-model-invocation: true
allowed-tools: Write, Bash(powershell *), PowerShell(powershell *)
---

# /handoff

Arguments: `$ARGUMENTS`

Every step runs this command in the terminal (the Bash or PowerShell tool, whichever is available), adding the parameters shown:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/handoff.ps1" -SessionId ${CLAUDE_SESSION_ID}
```

Reply to the user in the language of this conversation.

## 1. Read the arguments

| Argument | Values | Parameter |
|---|---|---|
| destination | `code` (default), `chat`, `cowork`, `export` | `-Target` |
| accounts | `accounts` / `contas` | `-Target accounts` |
| help | `--help`, `-h`, `help`, `ajuda` | `-Target help` |
| account | a name from config.json; with none, the script uses the default | `-Account` |
| detail | `full` / `completo`, `normal`, `compact` / `enxuto` | `-Detail full`, `normal`, `compact` |
| `no note` / `sem nota` | skips the handoff note for chat/cowork/export | |

- No arguments means `code`, exactly as before.
- `accounts` / `contas` and help commands are informational: run them immediately and stop. Do not create a note.
- Accept natural language in any language: "send it to the work chat, full detail" or "manda pro chat da work bem completo" both mean `-Target chat -Account work -Detail full`.
- `detail` applies only to `chat`, `cowork` and `export`; ignore it for `code`, `accounts` and `help`.
- `no note` / `sem nota` applies only to `chat`, `cowork` and `export`; it removes only the short orientation note, never the transcript itself.
- If no detail is given, don't pass `-Detail`: config.json already sets each destination's default.
- If the account doesn't exist, run with `-Target accounts`, show the options and stop.
- If the arguments are clear, don't ask anything: run it.

## 2. Informational commands

For `/handoff accounts` or `/handoff contas`, run with `-Target accounts` and return the script output. It lists the usable account keys, default account, folders and running-instance checks.

For `/handoff --help`, `/handoff -h`, `/handoff help` or `/handoff ajuda`, run with `-Target help` and return the script output. It explains destinations, accounts, detail levels, note behavior and examples.

## 3. Destination `code`

Run with `-Target code -Account <account>`. Then say, in one line, to close this session in the terminal (`/exit`) before sending a message in Desktop.

## 4. Destinations `chat`, `cowork` and `export`

The script exports the real conversation of this session (the user's messages, your replies, commands, edits and results). You don't summarize the conversation. The only text you write is a short note that orients whoever picks it up.

**a) Handoff note** (skip it if the user said `no note` / `sem nota`). Write it with Write to `${CLAUDE_SKILL_DIR}/note-${CLAUDE_SESSION_ID}.md`, at most 10 lines, in the language of this conversation, in this format (translate the labels):

```markdown
**Where we stopped:** <exact state of the work right now, in 1 or 2 sentences>
**Next step:** <the next concrete action>
**Watch out for:** <a pitfall, pending decision or easy-to-miss detail; omit if there is none>
```

- Only what you know from this session. Anything not verified goes in "Watch out for" as an open question.
- Never include secrets (tokens, passwords, keys, connection strings).

**b) Export and open:** run with `-Target <destination> -Account <account> -NoteFile "${CLAUDE_SKILL_DIR}/note-${CLAUDE_SESSION_ID}.md"` (plus `-Detail` if asked). Without a note, leave out `-NoteFile`.

**c) Reply** in at most 3 lines, based on the script's output:

- `chat`: concatenate the instruction and transcript directly into the deep-link `q` field whenever the complete decoded prompt is within the safe limit (~13,000 characters). If the script says it was prefilled, the user only reviews it and presses Enter. If the complete prompt is larger, use the clipboard fallback so the transcript is not truncated; the user presses Ctrl+V and Enter.
- `cowork`: the task opened with the transcript attached; confirm the folder when Desktop asks.
- `export`: the path of the generated file.
- If the output mentions reduced or omitted turns, say so, and that `/handoff export` produces the version with no limit.
