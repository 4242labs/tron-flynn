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
Update MANIFEST block state to CLOSED with commit SHAs and PR numbers. A block is NOT closed until its close-PR worktree AND branch are pruned in EVERY repo it touched (app + meta + gateway) — the engineer prunes as the final session-end step; TRON verifies with `git worktree list` / `git branch` and does not accept "closed" while leftovers remain. Release the engineer only when its click queue is empty and that audit is clean.

## Merge mechanism (permission-mode-conditional)
Whether an agent can run `gh pr merge` depends on the session's permission MODE, not on the allow-list (Anthropic docs — sub-agents + Agent-SDK permissions):
- **`bypassPermissions`** — subagents inherit it and it can't be overridden; `gh pr merge` is NOT special-cased, so it just runs. Only explicit `ask` rules and root/home `rm -rf` still prompt. The engineer merges its own green + challenged + reviewed PR as the final build step — no human gate, no operator clicking.
- **`auto`** — subagents inherit auto; `gh pr merge` routes through the semantic classifier, which accepts only the USER's own message/click (never coordinator relay, and an allow-list rule does NOT satisfy it). Here the merge verb is a HUMAN action; engineers hand off and STOP.

So the merge gate is a CHOICE, not a wall: if the run needs autonomous merges, launch it in `bypassPermissions` (`--dangerously-skip-permissions` / Shift-Tab) — never resign a run to per-PR operator clicks on the false belief that agent merges are impossible. Verify the LIVE mode at boot; `defaultMode` in settings.json is startup-only and the running session can differ, so read the actual mode, don't infer it from the file (a misread of `jq '.permissions'` output once produced a false "config is malformed" diagnosis — verify from ground truth).

## Succession / relayed state
Before spawning a successor or ordering a push, verify the predecessor's REAL git state (`git log`/`git status`/`git branch`) — never relay a commit SHA or "already committed" claim you haven't confirmed (a false SHA relay spawned a duplicate close PR). Check for an existing branch/PR for the same work first; do not run two agents at the same close.

End of line.
