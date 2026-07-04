---
name: tron-flynn-pulse
description: PULSE timer mechanics — arming, filesystem liveness forensics, escalation ladder, operator report cadence.
---

# PULSE

The heartbeat. Event wake-ups (worker completions) are supplements — the timer is the guarantee.

## Arming
- Background `sleep 180` (Bash, `run_in_background: true`) fired at boot and RE-ARMED at the end of every turn, no exceptions. If a tick fires mid-work, finish the action, sweep, re-arm.
- On EVERY arm, refresh the guard flag: `echo $(( $(date +%s) + 240 )) > .tron-flynn-active` (project root). The Stop hook blocks any turn that ends with a lapsed flag — memory backed by mechanism.
- If you discover the timer lapsed (e.g. after a session resume), sweep immediately, then re-arm.
- At boot (once), scope the guard to YOUR session: write your session id to `.tron-flynn-session` (project root). Your own transcript is the most recently written one at boot: `ls -t ~/.claude/projects/$(pwd | tr '/' '-')/*.jsonl | head -1 | xargs basename | sed 's/\.jsonl$//' > .tron-flynn-session`. Without it, the Stop hook fires in EVERY session of the project.
- Run end: `skill-session-end` owns the teardown — run log first, THEN delete `.tron-flynn-active` and `.tron-flynn-session`. Never delete the flags outside that skill.

## Tick sweep (each tick, per active worker)
Read the filesystem, never the worker's transcript (transcripts overflow context):
- `git -C <worktree> log --oneline -3` — new commits since last tick?
- `git -C <worktree> status --porcelain | wc -l` — dirty-file count moving?
- Artifact mtimes (test reports, logs, MANIFEST-adjacent files).
Record the sweep result mentally; write MANIFEST only on state change.

## Escalation ladder
1. No progress ~2 ticks (≈6 min) → deep sweep (branch list, PR state, ports).
2. Still silent → ping the worker (SendMessage): "status <block> — reply in fixed format."
3. Ping fails / unresumable ("No transcript found") → declare dead → `skill-succession`.

Thrash is a separate signal: a worker that is ACTIVE but looping — 3+ failed attempts at the same gate, or repeated revert commits on the same files — is walled to the operator, not left to grind. Silence ≠ stuck, and activity ≠ progress.

## Operator cadence
- Status report every ≤10 min: one line per worker or a short block-state table. Lead with state changes.
- Quiet ticks: one line ("PULSE quiet — ENG-1 building, 4 commits, no walls.").
- Pending operator clicks (merges, gates) are repeated in EVERY report until cleared.

End of line.
