# Context Budget & Handoff Policy

> **Status**: adopted 2026-11-15. Applies to **every** chat in this project:
> orchestrator, lane runner, seat, sync, support, and ops.
> **Owner**: producer / orchestrator. **Enforced by**: the operator + DCP nudges.

## 1. Why a cap below the window

The model window is **1,048,576 tokens**. The cap is **not** a capacity limit — it
is a **quality, cost, and latency** guard:

- Long contexts degrade retrieval: the model starts missing the file it read an
  hour ago and re-derives decisions already made.
- Cost and latency grow with every token re-sent on every turn.
- The most reliable memory in this project is **the file on disk**, not the
  transcript. `STATE.md`, `manifest.yaml`, lane reports, and GDDs survive
  compaction, crashes, and new chats. The transcript does not.

**Rule of thumb**: a session that needs more than ~250k of live context is
usually doing two jobs at once. Split it.

## 2. Triggers

| Trigger | At | What to do |
|---|---|---|
| **Soft** | **250k** | Update `STATE.md` + `active.md`, write the handoff, **finish the atomic step**, stop starting new work. |
| **Hard** | **350k** | **Stop.** Write the handoff and end the session. Do not start another lane, review, or repair. |
| **Emergency** | ~898k | Harness auto-compaction (OpenCode `compaction.buffer: 150000`). Never a normal operating mode. |

"Atomic step" means the smallest unit that leaves the repo consistent: one
section written, one commit made, one review returned. Never stop mid-edit.

At the soft trigger you may still **complete** what is open. You may not **open**
anything new.

## 3. Handoff modes

| Mode | When | Requirements |
|---|---|---|
| **(a) Fresh chat** — default | Creative, design, architecture, GDD authoring, art bible, any lane that reasons over long documents | `STATE.md` + `active.md` + the lane report are current; the new chat reads them. |
| **(b) `/clear` in the same session** | Technical/ops: a setup, a sync, a mechanical fix, a verification pass | The transcript is saved (session export or the report), and the cleared context is **verifiably empty** — confirm the new context starts with only the system prompt + the handoff. |
| **(c) Compaction** — last resort | Mechanical work only: repetitive edits, a long test-fix loop, no design judgement left | Only with the clause below. |

**The compaction clause** — paste it into the handoff whenever mode (c) is used:

> The compaction summary is an **index, not the source of truth**. Re-read
> `STATE.md`, `manifest.yaml`, the lane report, and any file you are about to
> edit. If the summary and the file disagree, the file wins.

Compaction is never used for a lane that is authoring a GDD, a seat that is
reviewing one, or an orchestrator that is deciding what to launch. Those are
mode (a).

## 4. DCP's compress is a tool, not a handoff

`compress` (DCP) replaces closed conversation spans with technical summaries
**inside a live session**. It buys room; it does not transfer ownership.

- Use it to shed **closed** work: a finished exploration, a landed lane, a
  superseded investigation.
- Never use it to "get under the cap" and keep working past 350k. That defeats
  the point: the summary is lossy and the session keeps its accumulated bias.
- DCP is configured to nudge at **250k** and push hard at **350k**, matching this
  policy (`.opencode/dcp.jsonc`). The nudges are the reminder; this document is
  the rule.

## 5. What the handoff must contain

Every handoff — any mode — answers these seven questions. The template is
`prompts/handoff.md`; the paste source for the next orchestrator chat is
`prompts/NEXT.md`.

1. **Current task** — what this chat was doing, in one paragraph.
2. **State files** — the exact paths to read, in order.
3. **Next action** — the single next step, with the command or the lane ID.
4. **Constraints** — frozen contracts, WIP limits, model routing, files not to
   touch.
5. **Model routing** — which model the next chat and each lane must use.
6. **WIP limits** — what may run in parallel right now.
7. **Paste-check** — `node tools/orchestration/render-prompts.mjs --check` and
   the manifest hash.

Plus the standing clause:

> **Re-read the files.** The handoff is a pointer, not a summary of record. Read
> `STATE.md`, `manifest.yaml`, and the lane report before acting; if this prompt
> and the files disagree, the files win.

## 6. Harness behaviour (measured, 2026-11-15)

| Mechanism | Setting | Actual trigger |
|---|---|---|
| OpenCode auto-compaction | `compaction.auto: true`, `compaction.buffer: 150000` (project `opencode.json`) | ~**898,576** tokens (1,048,576 − 150,000), i.e. 86% of the window. Emergency backstop only. |
| DCP compress nudges | `minContextLimit: 250000`, `maxContextLimit: 350000` (`.opencode/dcp.jsonc`) | Reminders from 250k; strong "MAX CONTEXT LIMIT" nudge from 350k. |
| DCP deduplication / purge-errors | enabled | Recalculated when the compress tool runs. |
| OCGS pre/post-compact hooks | `ccgs-hooks.ts` | Fire on the harness's `experimental.session.compacting` events. |

**Config is read at session start.** Editing `.opencode/dcp.jsonc` or the
`compaction` block does not affect a running session; restart OpenCode. A session
that started before the config landed still nudges at DCP's default 100k.

## 7. Per-role application

| Role | Budget | Mode | Notes |
|---|---|---|---|
| Orchestrator | 350k hard | (a) fresh chat each loop | Reads only STATE/manifest/queues/reports. Never full GDDs. |
| Lane runner (GDD) | 250k soft | (a) fresh chat per lane | One document per worktree; the report is the handoff. |
| Seat (review) | 250k soft | (a) fresh chat per review | One document, blockers only, then stop. |
| Sync lane | 350k hard | (b) `/clear` acceptable | Serial, mechanical; transcript saved in the PR. |
| Ops/setup (this kind of chat) | 350k hard | (b) `/clear` acceptable | Land the change, update STATE, write NEXT, stop. |
| Prototype/implementation | 250k soft | (a) or (b) | Superpowers TDD loop; the plan file is the handoff. |

## 8. Failure modes this prevents

- **The long tail**: a 700k session that "remembers" a superseded decision and
  re-litigates it. The file is the tiebreaker.
- **The silent compaction**: a GDD authored after a compaction that lost the
  frozen contract it was supposed to respect. Mode (a) prevents it.
- **The expensive resume**: paying to re-send 600k of closed exploration every
  turn. The handoff is ~2k.
- **The lost lane**: a lane whose only record is a transcript that was cleared.
  The lane report is mandatory for this reason.
