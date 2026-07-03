# TRON-flynn install kit

One-time, per machine + per project.

1. **Launcher** (per machine): copy `tron-command.md` to `~/.claude/commands/tron.md` → `/tron` becomes available in every project.
2. **PULSE guard + worktree config** (per project, one-time): on first `/tron` boot in a project with a missing or incomplete `.claude/settings.json`, TRON proposes a minimal merge — the Stop hook (a no-op unless a flynn run is active, so other agents in the project are untouched) plus `"worktree": {"bgIsolation": "none"}` (mandatory for fleet runs — without it, background worker sessions auto-isolate into duplicate worktrees and break the parallel-engineer contract). It shows the diff and waits for a one-time go-ahead before writing anything. You can also merge `settings-snippet.json` yourself ahead of time if you'd rather review it outside a run. Anthropic's config trust boundary sits at the folder-trust prompt, not per-hook, so committing the resulting `settings.json` to version control (rather than leaving it untracked) is the recommended safety net.
3. Run `/tron` in the target project. Boot handles the rest; run end removes the flag and the guard goes dormant.
