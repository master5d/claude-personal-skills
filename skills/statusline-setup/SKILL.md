---
name: statusline-setup
description: Set up, fix, or update the Claude Code footer status bar (statusline). Use this skill whenever the user mentions "status line", "statusline", "status bar", "footer bar", "fix my statusline", "set up status line", "context bar", or wants to see token/model info in the Claude Code footer. Covers initial setup, wiring settings.json, dependency checks (jq), and updating the statusline script.
---

# Claude Code Statusline Setup

A custom statusline showing model info, context usage, session tokens, and weekly token tracking in the Claude Code footer.

## Layout (5 lines)

```
Sonnet 4.6 (200k)  ●●●○○○○○○○○○○○○○○○○○  | ✏  12% | MyProject |
session  ●●○○○○○○○○  12%  7kin · 3kout  🕐20:51
weekly   ~18k est  🕐Tue 25 Mar
🎁 2× off-peak  → std in 2h 15m  ·  3d left   ← (promo lines, time-limited)
►► bypass permissions on (shift+tab to cycle)  ← (only when bypass active)
```

## Setup Steps

### 1. Check dependency: `jq`

```bash
jq --version
```

If missing on Windows/Scoop:
```bash
scoop install jq
```

The `settings.json` command must explicitly add jq to PATH since Claude Code doesn't inherit the full shell PATH:
```json
"PATH=\"/c/Users/sasha/scoop/apps/jq/1.8.1:$PATH\" bash \"$HOME/.claude/statusline-command.sh\""
```
Adjust the path to match where scoop installed jq (`scoop which jq`).

### 2. Write the script

Copy `references/statusline-command.sh` to `~/.claude/statusline-command.sh` (make executable on Unix/WSL: `chmod +x`).

### 3. Wire settings.json

Edit `~/.claude/settings.json` — add/update the `statusLine` block:

```json
{
  "statusLine": {
    "type": "command",
    "command": "PATH=\"/c/Users/sasha/scoop/apps/jq/1.8.1:$PATH\" bash \"$HOME/.claude/statusline-command.sh\""
  }
}
```

If jq is on PATH already (Linux/macOS), simplify to:
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$HOME/.claude/statusline-command.sh\""
  }
}
```

## State file

Token tracking persists to `~/.claude/statusline-weekly.json`. Safe to delete to reset weekly counter.

## Common issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Status bar empty / blank | `jq` not found | Add jq to PATH in the command |
| All zeros / nulls | Old jq version | `scoop update jq` |
| Weekly count wrong | State file corrupt | Delete `~/.claude/statusline-weekly.json` |
| Math errors in output | Bash arithmetic overflow | Verify `$(( ))` used (not `bc`) |
| Promo section still showing | Date check hardcoded | Edit `PROMO_END_NUM` in script |

## Updating the script

When updating:
- Read `~/.claude/statusline-command.sh` first
- Make targeted edits — don't overwrite the whole file unless replacing entirely
- The script receives Claude Code's status JSON on stdin — all data comes from there
- Test with: `echo '{"model":{"display_name":"Claude Sonnet 4.6"},"context_window":{"context_window_size":200000,"used_percentage":15,"total_input_tokens":7000,"total_output_tokens":3000},"workspace":{"project_dir":"/test/project"}}' | bash ~/.claude/statusline-command.sh`

## Reference implementation

See `references/statusline-command.sh` for the full script. Read it before modifying.
