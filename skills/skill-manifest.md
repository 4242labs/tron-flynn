---
name: tron-flynn-manifest
description: MANIFEST format and update triggers — the run-state file that survives context loss and enables succession.
---

# MANIFEST

One file in the session scratchpad. It is run-state truth: after any context loss (compaction, session death), the run must be fully resumable from MANIFEST + git alone. Git is read-only truth for code; MANIFEST is truth for everything git can't hold.

## Sections (in order)
```markdown
# TRON MANIFEST — run <name> (started <date>) — <run status>

## Config
Scope, fleet (slots + models), gates, PULSE cadence, dependency map (e.g. 02-01 ⊣ {02-02, 02-03}).

## Workers
| ID | Role | Model | Block | State |
State includes worktree path + branch while active; DEAD rows keep cause + successor.

## Block states
| Block | State |
Stage machine position + evidence pointers (commit SHAs, PR numbers, session-log paths).

## Port map
Assigned ports per purpose/worker.

## Parallel rules
Architect's file-ownership + merge-order rules, verbatim, while a parallel run is live.

## Gate ledger
One line per gate verdict: block, gate, date, verdict, evidence pointer.

## Deviations log
Anything a worker did off-blueprint with justification — feed for the phase reviewer.

## Scope notes
Dated operator amendments, verbatim.

## Operator click queue
Every pending operator action (merges, gates) — repeated in reports until cleared.
```

## Update triggers (write immediately, not batched)
- Any worker state change (spawn, stage advance, wall, death, release).
- Any gate verdict, operator amendment, deviation, click cleared.
- Quiet PULSE ticks do NOT touch the file.

## Discipline
- Facts with evidence pointers (SHA, PR#, path) — no narrative.
- Never delete history within a run; supersede (strike or annotate).
- On run completion: final header line with end state, then stop writing.

End of line.
