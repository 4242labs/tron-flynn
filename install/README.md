# TRON-flynn install kit

One-time, per machine + per project.

1. **Launcher** (per machine): copy `tron-command.md` to `~/.claude/commands/tron.md` → `/tron` becomes available in every project.
2. **PULSE guard + worktree config** (per project): merge `settings-snippet.json` into the target project's `.claude/settings.json`. Claude Code will ask you to approve the hook once. The hook is a no-op unless a flynn run is active (`.tron-flynn-active` flag present), so other agents in the project are untouched. The `"worktree": {"bgIsolation": "none"}` key is mandatory for fleet runs — without it, background worker sessions auto-isolate into duplicate worktrees and break the parallel-engineer contract.
3. Run `/tron` in the target project. Boot handles the rest; run end removes the flag and the guard goes dormant.
