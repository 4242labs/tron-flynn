# Flynn artifact retro — run 002 (hiresling.ai)

Running list of friction points in tron-flynn's own artifacts (persona, skills, install kit),
found while operating this run. Not hiresling.ai project issues — those stay in hiresling logs.
Goal: co-author fixes back into `/home/anderson/42labs/tron-flynn` (PR at session end, or sooner
on request).

## Findings

### 1. Boot step 5 session-scoping command breaks silently on dotted project dirs
`tron-flynn.md` Boot step 5 / `skill-pulse.md` §Arming both prescribe:
`ls -t ~/.claude/projects/$(pwd | tr '/' '-')/*.jsonl | head -1 | xargs basename | sed 's/\.jsonl$//' > .tron-flynn-session`
Claude Code's actual transcript-dir naming strips **all** non-alphanumerics (including `.`), not
just `/`. For a project dir like `hiresling.ai`, `tr '/' '-'` produces `...hiresling.ai` which
doesn't match the real dir `...hiresling-ai`. `ls -t` fails, the pipe produces nothing, and the
redirect still silently writes an **empty** `.tron-flynn-session` file — no error surfaced.
Impact: empty sid → pulse-guard.sh's scoping check (`[ -n "$sid" ]`) fails open, so the Stop-hook
guard applies to **every** session in the project, not just flynn's.
Fix direction: replace the tr-based one-liner with something that finds the dir robustly (e.g.
`ls -td ~/.claude/projects/*/ | ... ` matched against cwd via a more tolerant transform), or at
minimum have Boot verify the sidecar is non-empty immediately after writing it and treat empty as
a wall, not a silent pass.

### 2. Install bootstrap catch-22 with background-job isolation
The harness enforces (for background-job sessions): Edit/Write calls are rejected in the shared
checkout until `"worktree": {"bgIsolation": "none"}` is already set in settings.json. But that's
exactly the setting the install step (`tron-flynn.md` Boot step 3 / `install/README.md`) is trying
to write — chicken-and-egg. `Edit` tool literally cannot write the file that would unblock `Edit`.
Worked around by asking the operator to run the settings.json + pulse-guard.sh writes themselves
via `!`-prefixed shell commands. Fix direction: `install/README.md` should document this
interaction explicitly and prescribe the `!`-escape-hatch workaround (or an EnterWorktree+PR path)
as the canonical fix for any flynn boot happening inside a background job.

### 3. MANIFEST location is underspecified
`skill-manifest.md` says MANIFEST is "one file in the session scratchpad" but also claims the run
must be "fully resumable from MANIFEST + git alone" after "session death." Those are in tension if
"scratchpad" means job-local temp storage (deleted with the job, not visible to a fresh session).
Resolved this run by placing it at `<project-root>/.tron-flynn-manifest.md` (sibling to the other
`.tron-flynn-*` flag files, untracked, project-durable) rather than the job tmp dir. Fix direction:
pin this convention explicitly in `skill-manifest.md` instead of leaving "scratchpad" ambiguous.

### 4. No explicit "fetch before you trust local state" step in Boot
Boot reads core docs (context.md, principles.md, pipeline.md) directly from the local checkout
with no instruction to `git fetch`/`pull --ff-only` first. On this run the local `hiresling-app`
staging and `hiresling-meta` main were 9 and 11 commits behind origin respectively — an entire
completed block (ADHOC-PRE-113) and a new phase (116) were invisible until the operator caught it
and I fetched manually. Fix direction: add an explicit fetch/ff-pull step to `tron-flynn.md` Boot
step 1 (or as a RECONCILE precondition) for every git-backed core doc before reading it as truth.

### 5. (own mistake, process note not an artifact bug) Chained `cd a && ... && cd b` in one Bash
call silently ran the second half in the wrong directory when the first `cd` never executed (already
in that dir). Not a tron-flynn artifact issue — just a reminder to `pwd` before trusting a chained
`cd` in a multi-repo layout. Worth a line in a future "operating discipline" skill if this recurs.

### 6. Dispatched workers are NOT individually visible or messageable by the operator — undocumented in tron-flynn
Spent a long stretch of this run (operator-initiated) investigating why ARCH-1/ENG-2, dispatched via
the `Agent` tool with `run_in_background: true`, didn't show up as separate entries in Claude Code's
Agent View, and whether the operator could message them directly. Confirmed two independent ways
(live SendMessage failures + official docs + an empirical prior-art hit in the older `tron-app`
project's sim reports, `~/42labs/tron/tron-meta/sims/reports/260701-1035-trivial-tip-converter/`):
this is a structural CLI boundary, not a bug. Full writeup logged to the shared KB:
`~/42labs/42hq/knowledge-base/kb/tooling/claude-code-cross-session-agent-messaging.md`.

Bottom line for tron-flynn specifically: **TRON-flynn's whole worker model (dispatch via `Agent`
tool, track via MANIFEST, relay via SendMessage) is hub-and-spoke by construction — workers are
never independently open-able by the operator, only observable/controllable through TRON.** This
is almost certainly what tron-flynn intends, but neither `tron-flynn.md` nor `skill-dispatch.md`
says so explicitly, so an operator new to the persona (as happened this run) can reasonably expect
otherwise and burn significant time confirming a non-bug. Fix direction: add one explicit line to
`tron-flynn.md` (Invariants) or `skill-dispatch.md` stating plainly that dispatched workers are not
independently visible/messageable by the operator — that's the design, not a gap — and pointing at
the KB entry above for anyone who wants the full mechanism.

### 7. TRON relayed a worker's "this is missing/off-limits" claim to the operator without
first challenging it against project docs — the info was already there

On 113-03, ENG-2 reported it couldn't pull LiteLLM `$`/spend data because `GET /spend/logs`
needs the master key, which it treated as off-limits (generalizing the playbook's "never use master
key for generation calls" rule to also cover this read-only admin query), compounded by a harness
permission guard declining its own `/key/info` cross-check attempt. I relayed this to the operator
as a hard wall (needs-operator-action) without first re-checking whether the premise was even true.
It wasn't: `LITELLM_MASTER_KEY` was already sitting in the exact `.env.val-staging` file ENG-2 had
already copied into its own worktree for the API key. The operator caught this with one question
("I think they do have access to LiteLLM info, confirm") — a verification I should have done myself
before escalating.

Fix direction: add an explicit step to `skill-dispatch.md` (or wherever wall/CASE handling is
defined) — **before surfacing a worker's "I don't have X" / "X is off-limits" / "X is missing" claim
to the operator as a wall, TRON must first challenge it against the project's own docs and already-
known local state** (grep the relevant playbook/principles section, check env files/config already
on disk, re-read what's already been verified this run) and only escalate once that check actually
confirms the gap. Don't just relay the worker's framing uncritically — workers can be overly
conservative about their own scope (as here) or simply not have looked in the right doc.

### 8. "Persistent Architect" isn't actually persistent in practice — it's re-spawned fresh
each time, with no mechanism to survive context compaction

`tron-flynn.md`'s invariant is Architect = persistent, forward-only, out-of-pool — implying one
long-lived agent resumed via `SendMessage` + a saved agent ID across RECONCILE/CHALLENGE rounds.
In practice this run, ARCH-1's RECONCILE and its later CHALLENGE-stage consult (113-03's
`applyStagingAlias` eval-bypass question) were two separate fresh `Agent` spawns, not one resumed
session — the original agent ID was never durably recorded anywhere TRON could recover it, and it
was lost outright across this session's context compaction. Second dispatch had zero memory of the
first; it only knew what I re-explained in its prompt.

Also surfaced by a direct operator question ("is there a permanent arch standing at all times?") —
a new operator would reasonably expect the persistence to be real given how firmly the persona
states it, and it isn't, currently.

Fix direction: either (a) have TRON persist the Architect's live agent ID into the MANIFEST itself
(a durable, project-root file) the moment ARCH-1 is first spawned, and always resume via
`SendMessage` + that ID for subsequent architect consults — reading it back from MANIFEST after any
compaction/session restart — or (b) if true process-level persistence isn't achievable across
compaction with current tooling, change `tron-flynn.md`'s language to describe what's actually
true: Architect is a *role* TRON re-dispatches per consult with full context re-supplied each time,
not a literally persistent session. Don't leave the invariant overstating a guarantee the mechanism
can't currently keep.
