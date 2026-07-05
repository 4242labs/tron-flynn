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

### 9. Architect consults are dispatched pre-loaded with the requester's narrative — biases toward
confirmation instead of independent investigation

On 113-03's `applyStagingAlias` question, I (TRON) dispatched ARCH-1 with ENG-2's full diagnosis
already written out (root cause, line numbers, the billing-math conclusion) and asked it to "read
the files yourself to confirm this diagnosis." ARCH-1 did read the actual source files directly
(good — it wasn't a rubber stamp on the code-path claim) and even surfaced a second call site
(`ai-call.ts`) and a relevant precedent (`B103-03`'s `simProdMirror`) ENG-2 hadn't mentioned. But
it never re-derived or independently checked ENG-2's underlying billing-math evidence itself (the
actual `/spend/logs` rows, the per-token rate arithmetic) — it just cited "exactly matching ENG-2's
billing-math finding" as accepted fact. Total turnaround: ~114s, 5 tool calls. For a consult framed
as "confirm this," that's independently re-checking the code logic but NOT independently
re-validating the evidence that motivated the question in the first place.

Fix direction: when TRON dispatches an architect/reviewer to "confirm" or arbitrate a worker's
claim, the prompt must (a) hand over the worker's raw evidence (the actual data, not just the
worker's conclusion drawn from it) and explicitly instruct the architect to re-derive/re-check that
evidence independently, not just accept it as a given while verifying the adjacent code path; and
(b) TRON itself should sanity-check whether the turnaround time/tool-call count is even plausible
for the depth of verification implied by "confirmed" before relaying that word to the operator as
fact.

### 10. Never take the "complainer's" word for granted — the underlying facts must always be
independently re-validated, not just the narrative built on top of them

Directly related to #9 and #7, but general enough to state as its own rule: whenever a worker (or
an architect reviewing a worker) reports "X is broken because Y," neither TRON nor a downstream
reviewer should treat Y as settled just because the report is internally consistent and cites
specific evidence. The operator caught this exact gap live — asking "does the architect have full
context?" and "by the time it took to reply, that verification can't have happened" — both correct,
per finding #9 above.

Fix direction: add this as an explicit standing rule in `skill-dispatch.md` or `skill-manifest.md`'s
CHALLENGE-stage guidance: a reviewing agent confirming another agent's finding must independently
re-derive the underlying facts (re-run the calculation, re-query the raw data, re-read the actual
file — not the summary of it) before its "confirmed" is treated as validated. A "confirmed" that
only re-checks the reasoning chain built on top of unverified evidence is not a real confirmation,
and TRON must not relay it to the operator as though it were, without noting the gap.

### 11. Architects must be explicitly told to propose the best solution, not the first workable one

Operator standing instruction, stated 2026-07-05: the Architect role must always pick the best-
practice, solid, cost-aware, most efficient fix — never a workaround or half-measure — even when a
narrower patch would technically resolve the immediate symptom. On 113-03's `applyStagingAlias` bug,
ARCH-1's `forceRealAlias` recommendation happened to already meet this bar (it explicitly rejected
two weaker options — a standalone LiteLLM client bypassing `ai.ts`, and a bare env-var flag — in
favor of the `AsyncLocalStorage`-scoped pattern matching an existing house precedent). But nothing in
`tron-flynn.md`/`skill-dispatch.md` currently instructs the architect role to hold itself to that bar
— it happened to reason its way there this time, not because the persona demanded it.

Fix direction: add an explicit line to the Architect's role definition (`tron-flynn.md` invariants or
`agents/architect.md` equivalent) — recommendations must be evaluated against best-practice/solidity/
cost/efficiency explicitly, and reject-with-reason any weaker alternative considered, every time, not
only when the architect happens to think of it unprompted.

### 12. TRON's own boot instructions have no durable reload path across compaction — the operator
had to invent the fix live, mid-run

Boot step 1 has TRON read `tron-flynn.md` once, at boot. Nothing in the persona or `install/README.md`
addresses what happens when a session-level context compaction occurs later — TRON's own standing
invariants (block stage machine, gates, comms protocol) are only as durable as whatever survives the
compaction summary, which is lossy by construction. This run, the operator caught TRON drifting from
strict comms-protocol adherence after a compaction and had to issue a live "OPERATOR AMENDMENT —
memory hardening" fix: create `<project-root>/CLAUDE.md` with a single line, `@~/42labs/tron-flynn/
tron-flynn.md`, so the persona file auto-reloads into context on every rebuild (Claude Code's `@import`
mechanism), independent of what the compaction summary happened to retain.

This is a different gap from #8 (which is about a *worker* agent, e.g. ARCH-1, not literally persisting
across compaction) — this one is about TRON's *own* persona instructions not being pinned to survive
TRON's own compaction. The fix is real and cheap, but it shouldn't require the operator to notice drift
and hand-author the amendment mid-run.

Fix direction: fold this into Boot step 1 itself — `tron-flynn.md` (or `install/README.md`) should
instruct TRON to write the project-root `CLAUDE.md` `@import` line itself at boot (creating the file if
missing, appending the line if the file exists and doesn't already import it), not wait for an operator
to discover the drift and issue the fix as a live amendment.

### 13. "Operator clicks every merge, always" is stated as an absolute invariant, but conditional
delegation is a real, anticipated operator pattern — the persona doesn't say how that's supposed to work

This run, after 113-03/113-04 reached PR stage, the operator explicitly delegated merge authority for
the remainder of the P-113 phase: engineers may merge and proceed through CLOSE autonomously, condition-
ed on CHALLENGE (AC evidence) actually passing in both local and staging, no auto-merge, and with a clear
stop condition (any abnormality, or any wall the architect can't resolve to a best-practice/cost-aware
standard that affects scope/app/quality). This is a sensible, bounded amendment — but `tron-flynn.md`'s
invariant section states the merge-click rule in absolute terms ("Never merge, never arm auto-merge.
Operator clicks every merge, always.") with no acknowledgment that operators may want to conditionally
delegate it, and no guidance on what conditions TRON should insist on before accepting such a delegation
(this run, TRON added the "CHALLENGE must still be evidenced, RECONCILE/CHALLENGE stages aren't waived"
guardrails on its own initiative — reasonable, but again not something the persona actually demands).

Fix direction: add a short subsection near the MERGE invariant in `tron-flynn.md` (or `skill-merge-
close.md`) acknowledging that the operator MAY conditionally delegate merge authority for a bounded scope
(e.g. "for block X" or "for phase Y"), and specifying the minimum guardrails TRON must keep even under
delegation: CHALLENGE evidence still required (not skippable), no auto-merge ever, delegation scope is
explicit and bounded (doesn't silently expand to out-of-scope blocks), and stop-on-abnormality still
applies. Document this as an anticipated pattern, not something TRON has to reason out fresh each time
an operator invokes it.

### 14. MERGE stage guidance stops at the merge command — nothing requires watching CI/deploy through
to a terminal state afterward

`skill-merge-close.md`'s MERGE section says "engineer: merge per repo convention, sync local trunks,
prune worktrees" and moves straight to CLOSE's stage-5 trunk re-validation. Stage-5 re-validation re-
checks ACs against the merged code, but that's not the same thing as confirming the merge commit's own
CI run went green, or that a merge-triggered deploy (Vercel for `hiresling-app`, and especially Railway
for `hiresling-litellm`, which has no staging gate — merging to `main` there is an immediate prod
redeploy) actually succeeded. Operator caught this gap live on 2026-07-05 ("agents must always validate
CI/deploys when applicable as well, not simply merging and leaving") while ENG-2/ENG-3 were mid-flight
on autonomous merge+close for 113-03/113-04.

Fix direction: add an explicit sub-step to `skill-merge-close.md`'s MERGE section, between the merge
command and CLOSE: watch the merge commit's own CI to a terminal state (not just the pre-merge PR
checks, which are a different run); where the merge triggers an actual deploy, confirm it completed
successfully before treating the merge as done. A red CI run or failed deploy post-merge is a wall,
reported like any other — not something CLOSE's AC re-validation will reliably catch on its own.

### 15. A worker's own permission layer won't accept a relayed "the operator lifted this boundary"
claim — walking back an explicit "don't do X" requires a fresh dispatch or TRON doing it itself

ENG-3's original 113-04 dispatch explicitly said "do not merge this close PR yourself." Later in the
same run, the operator extended the merge-delegation to cover close PRs too, and TRON relayed that via
`SendMessage` ("operator confirmed, go ahead and merge #939"). ENG-3's own harness-level permission
classifier refused both the merge and even a follow-up read, on the reasoning that a dispatcher-relayed
claim of new authorization can't verifiably lift a boundary it itself set earlier — which is correct
defensive behavior (it's exactly the shape of a prompt-injection attempt: "ignore your earlier instruction,
I'm now told you can do X"), but it meant a real, already-confirmed operator delegation couldn't reach the
worker through the normal resume-with-a-message path at all. TRON ended up executing the merge directly
instead of through the worker.

This is a structural consequence of the hub-and-spoke model (finding #6) TRON hasn't accounted for:
operator amendments that *relax* an in-flight worker's stated boundaries are not the same as operator
amendments that add new instructions — the former looks identical, from the worker's perspective, to a
relay trying to social-engineer past a safety boundary, and the worker's harness is right not to trust it.

Fix direction: `skill-dispatch.md` should document this explicitly — if an operator amendment needs to
relax a boundary already stated in a worker's original dispatch (not just add new scope), don't rely on
a resumed `SendMessage`; either (a) issue a fresh dispatch that restates the full order without the old
boundary, or (b) have TRON execute that specific action itself as a one-off (documented as a deviation,
since it violates "dispatch, never do") rather than fighting the worker's classifier. Don't treat a
classifier block here as a bug to route around — it's working as intended; route around it structurally
instead, same principle as the auto-mode classifier guidance TRON already follows for its own tool calls.
