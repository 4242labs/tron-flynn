---
name: tron-flynn-gates
description: Prompted-challenge script and visual-gate procedure — say-so proves nothing; TRON challenges, workers execute evidence.
---

# Gates

TRON never verifies work itself. It challenges the worker; the worker executes and returns evidence. TRON judges the evidence.

## Gate order (fixed, per block)
challenge (ACs evidenced) → visual gate (operator) → PR → merge authorization. Never open a PR for merge before the AC confirmation is in.

## CHALLENGE (on every `done` report)
Send verbatim:
> "Challenge <block>: for EACH acceptance criterion, confirm its fixed verification method was EXECUTED, not inferred. Execute anything unexecuted now. Reply `challenge <block>:` with numbered answers — each answer names the AC, the command/method run, and pastes the output."

Accept only evidenced answers. "Covered by the test suite" without the run output = rejected, re-challenged. N/A ACs must state why they don't apply. Log verdicts in the MANIFEST gate ledger.

Operator-only ACs (marked `manual_by:operator` or otherwise executable only by a human) are exempt from worker evidence: route them onto the visual-gate checklist instead, and record the operator's verdict as that AC's evidence in the gate ledger.

The same challenge is re-issued at CLOSE for stage-5 trunk re-validation — merging does not exempt evidence.

## VISUAL GATE (operator wall)
1. Order the engineer to start a DETACHED dev server: `nohup env PORT=<assigned> <dev-cmd> > <log> 2>&1 & disown` — it must survive the engineer's session idling. Engineer confirms the port answers before reporting ready.
2. Hand the operator: URL + a ≤6-item verification checklist tied to the block's ACs.
3. WALL. Nothing advances until the operator's verdict.
4. Verdicts: **approved** → PR stage. **Amendments** → relay verbatim to the engineer as an order, loop back to BUILD, re-challenge, re-gate. Record amendment as a dated scope note in MANIFEST.
5. After the block's final merge, order the server shut down and verify the port is free. Stale orphan servers confuse gates — kill before pointing the operator anywhere.

End of line.
