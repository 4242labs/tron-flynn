# TRON-flynn install kit

One-time, per machine + per project. Clone this repo anywhere — nothing assumes a fixed location.

1. **Machine install**: clone the repo, then
   - `echo "<clone path>" > ~/.claude/tron-flynn.path` — the pointer every boot resolves the flynn root from (missing → Boot asks once and writes it);
   - copy `tron-command.md` to `~/.claude/commands/tron.md` → `/tron` becomes available in every project.
2. **PULSE guard + worktree config** (per project, one-time): on first `/tron` boot in a project, TRON proposes the install — `pulse-guard.sh` copied to the project's `.claude/tron-flynn-pulse-guard.sh` (project-local, so `settings.json` never references a machine-specific path) plus a minimal `settings.json` merge: the Stop hook via `"$CLAUDE_PROJECT_DIR"/.claude/tron-flynn-pulse-guard.sh` (a no-op unless a flynn run is active, so other agents in the project are untouched) and `"worktree": {"bgIsolation": "none"}` (mandatory for fleet runs — without it, background worker sessions auto-isolate into duplicate worktrees and break the parallel-engineer contract). It shows the diff and waits for a one-time go-ahead before writing anything. You can also apply `settings-snippet.json` + the script copy yourself ahead of time. Anthropic's config trust boundary sits at the folder-trust prompt, not per-hook, so committing both files to version control (rather than leaving them untracked) is the recommended safety net — and makes the project install portable across machines for free.
3. **Telegram** (optional): one bot, one channel per project. `tg-send.sh` reads `TELEGRAM_BOT_TOKEN` (+ optional default `TELEGRAM_CHAT_ID`) from `.env` at this repo's root, and lets `TELEGRAM_CHAT_ID` in `<project>/.tron-flynn.env` override per project — both gitignored. Anything missing → Boot asks and writes the right file. Message formats live in `skills/skill-operator-comms.md`.
4. Run `/tron` in the target project. Boot handles the rest; run end removes the flags and the guard goes dormant.

Optional, scroll-proof pending-items display: `.tron-flynn-attention` in the project root always holds the live operator queue — `tail -f` it in a side pane, or point a statusline script at it.
