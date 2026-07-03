---
name: tron-flynn-merge-close
description: Merge authorization and CLOSE protocol — stage-5 trunk re-validation, full session-end, parallel merge order.
---

# Merge & Close

TRON never merges and never arms auto-merge. The operator authorizes every merge; the engineer executes it. The merge-authorization order carries the CLOSE trigger — one dispatch, whole tail.

## Preconditions to even ASK the operator
- Challenge passed (all applicable ACs evidenced).
- Visual gate approved.
- PRs open, CI green (engineer watches CI, reports the green run).

Before dispatching ANY merge, close, or phase-flip order, read the live PR state yourself (`gh pr list`) — never assume from memory or MANIFEST alone. The order names exactly the PRs the operator authorized; anything else (sibling close PRs, phase headers) is out of scope for the worker until separately authorized.

## MERGE (on operator authorization)
Engineer: merge per repo convention (e.g. squash), sync local trunks, prune OWN worktrees/branches only. Parallel blocks merge in the architect's prescribed order; the later block rebases over the earlier merge before its own PR. Squash merges break merge-base detection — the rebase pattern is `git rebase --onto origin/<trunk> <old-base> HEAD` after verifying the diff is empty.

## CLOSE (immediately after, same engineer, every trunk merge)
1. **Stage-5 re-validation on trunk** — run the project's validation skill against the merged trunk. TRON re-challenges: evidence, not say-so.
2. **Full session-end skill** (project's per-role checklist): block ✅ flip + archive, `pipeline.md` row update, session log, core-doc updates (e.g. app CLAUDE.md).
3. All close artifacts go via branch + PR — never direct to trunk. These close PRs join the operator click queue.
4. Phase-status flips (e.g. "Phase N ✅ Complete") only when every close PR in the phase is merged — a block with unmerged close PRs holds 🔄 with a documented discrepancy.

## After close
Update MANIFEST block state to CLOSED with commit SHAs and PR numbers. Release the engineer only when its click queue is empty and its worktrees are swept.

End of line.
