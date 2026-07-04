---
name: tron-flynn-operator-comms
description: Operator attention channels — attention file, blocking questions, Telegram, notification hook, voice. When each fires; no operator-relevant message may live only in the transcript.
---

# Operator comms

The transcript is noise: sweeps, orders, worker chatter. An operator-relevant message that
exists ONLY there is considered LOST. Every such message goes out on the channels below —
the transcript copy is a record, never the signal.

## The one rule

**A blocking question (AskUserQuestion) fires exactly when waiting-on-operator is the
system's only remaining state. Everything else signals without stopping.**

Blocking while a worker is still building would freeze supervision of the whole fleet on a
question about one block. Blocking when the fleet is stopped anyway costs nothing — and makes
"idle, waiting on you" a state that cannot render as silence.

## Channels

| Channel | What | When |
|:--------|:-----|:-----|
| Attention file | `.tron-flynn-attention` in project root | rewritten on every attention-state change |
| AskUserQuestion | blocking terminal prompt; flips Agent View to "Needs input" | only-remaining-state moments (below) |
| Telegram | `install/tg-send.sh` via templates (below) | the moment any operator item is CREATED |
| Notification hook + voice | Agent View `agent_needs_input` fires the host's notification path; 42voices speaks if the operator activated it at boot | rides along automatically |

## Attention file

`.tron-flynn-attention` — the operator's clean feed, derived from the MANIFEST click queue
(which stays truth). One line per open item, newest last; empty file = nothing pending.
Format: `<WALL|CLICK|GATE|Q> <block|-> — <one line> [CASE-<n>]`. Rewritten (not appended)
on every change so `cat`/`tail -f`/a statusline script always shows the live state, scroll-proof.
Deleted at run end with the flags (skill-session-end owns it).

## Blocking moments (AskUserQuestion)

- Boot: run config, settings-seed approval, TG/voice channel config.
- Run end proposal.
- **Fleet idle + anything pending**: no worker building, no gate mid-flight, click queue or
  walls non-empty → convert the OLDEST pending item into a blocking question. One question
  at a time; its answer usually restarts the fleet, and the rest stay queued on the other channels.
- A wall raised while other workers are live is NOT blocking — it goes out on the other
  channels immediately and ESCALATES into a blocking question when the fleet drains.

## Telegram

Send via `~/42labs/tron-flynn/install/tg-send.sh "<message>"` — reads
`TELEGRAM_BOT_TOKEN` + `TELEGRAM_CHAT_ID` from `~/42labs/tron-flynn/.env` (gitignored,
never committed). At boot, if TG is wanted and `.env` is absent/incomplete, ask the operator
for the two values — never hunt other projects' env files for credentials.

Templates — seed copy, formats iterate on operator feedback after first-run samples; the
operator owns the copy. `{case}` ids match the MANIFEST click queue:

- **wall** — `TRON ▸ WALL [{case}] {worker} on {block}: {detail}. Fleet still building; queued for your call.`
- **checkpoint** — `TRON ▸ HOLD [{case}] {worker} holding on {block}: {detail}. Won't move until you say so.`
- **merge gate** — `TRON ▸ GATE [{case}] {block} ready to merge — PR {pr}, CI green. Your click.`
- **visual gate** — `TRON ▸ GATE [{case}] {block} up at {url} — checklist in session. Your eyes.`
- **fleet idle** — `TRON ▸ IDLE fleet drained, {count} item(s) pending. Terminal has the question.`
- **run end** — `TRON ▸ END {project}: {count} blocks through the loop. Log written. End of line.`

Routine progress NEVER goes to TG. If a send fails (nonzero exit), note it in the next
session report and keep the item alive on the remaining channels — TG is a channel, not truth.

## Repetition law (unchanged)

Pending operator items are repeated in EVERY session report until cleared — the attention
file and TG do not replace that; they are how the operator hears about it away from the scroll.

End of line.
