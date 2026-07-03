---
name: tron-flynn-dispatch
description: Worker dispatch orders — PMT template per stage, fixed reply formats, port map, parallel-run rules.
---

# Dispatch

Every order a worker receives is complete, bounded, and demands a fixed-format reply. Workers who lack an order do nothing; workers who hit a wall STOP and report — never improvise.

## PMT template (every dispatch carries all of it)
1. **Persona** — which agent file they embody + binding docs to read first (project `principles.md`, relevant skills).
2. **Mission** — the block file is dispatch truth; quote the block ID and path. Architect guidance forwarded VERBATIM (never paraphrased) — but guidance is guidance, block ACs are truth: if guidance contradicts observed behavior, the worker reports it as a deviation, never silently follows it.
3. **Terms** — hard rules:
   - Work in an assigned git worktree, assigned branch name (`feat/<block>-<slug>`).
   - Assigned ports only (see port map). No collisions.
   - Stage boundaries: no push / no PR / no merge unless the order grants it explicitly.
   - Stuck → `wall`, never improvise. Operator amendments relayed by TRON are law.
4. **Reply format** (exact, no prose around it):
   - `done <block> — <stage>:` + evidence (commands run + outputs)
   - `wall <block> — <reason>:` + what was tried + what would unblock
   - `challenge <block>:` + numbered answers, each with executed output

## Port map
TRON assigns at boot, records in MANIFEST: one operator-facing gate port per block (e.g. 3001, 3002), separate per-engineer e2e ports. Workers never pick their own. The operator's own port(s) (asked at boot, typically :3000 for their review server) are RESERVED — never assigned, never killed.

## Parallel runs
Architect prescribes file-ownership rules before two engineers run concurrently (RECONCILE output). Dispatch them verbatim: owned files, read-only files, contested files with a merge-order rule (who merges first, who rebases). Both rebase if a visual-gate amendment mutates an already-merged block.

After any rebase, full-suite green trumps the ownership list: a sibling block's merged code may break tests the worker doesn't own (e.g. a new provider requirement in a shared component). Fixing those sibling tests is in-scope — logged as a deviation, not walled.

## Succession dispatch
A successor's order additionally carries: predecessor ID, worktree path, branch, last known state from MANIFEST, and the instruction to verify inherited state (`git log`, `git status`, open PRs) before continuing.

End of line.
