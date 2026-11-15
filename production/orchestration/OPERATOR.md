# Operator card — the one-page TL;DR

> You are the **operator**. You do three things: **paste, approve, decide**.
> Everything else is the machine's job. This card is the quick reference — the
> live truth is always `STATE.md`.

## The loop (your entire job)

1. **Restart OpenCode** if plugins/config changed (DCP reads config at startup).
2. **Open a fresh chat at the repo root** — not a worktree.
3. **Paste `prompts/NEXT.md`** whole, including the HTML header comment. That
   chat becomes the orchestrator.
4. Optional, same message: **pre-answer decisions** and/or the **unattended
   block** (below).
5. **Approve** section drafts in the lane chats: `Approved — write it.`
6. **Decide** the batch when presented — one message, `ID: choice` lines.
7. At **~250k** in the orchestrator chat: paste `NEXT.md` into a **fresh chat**.
   Never `/clear` and never compact the orchestrator chat.

## Where everything lives

| Need | File |
|---|---|
| Live state, blockers, next actions | `production/orchestration/STATE.md` |
| Your decision queue (read before answering) | `production/orchestration/decisions.md` |
| The paste | `production/orchestration/prompts/NEXT.md` |
| WIP, gates, git rules | `production/orchestration/README.md` |
| Context budget + handoff modes | `production/orchestration/CONTEXT-POLICY.md` |
| Modules, plugins, how-to | `production/orchestration/TOOLING.md` |
| Lane source of truth | `production/orchestration/manifest.yaml` |
| Review / sync ledger | `production/orchestration/review-queue.md` |

## Pre-answering decisions

Open decisions live in `decisions.md` ("Open decisions" — each entry has the
question, the options, and a recommendation). Answer in the paste message, one
line per decision:

```text
D-ORCH-01: B
D-ORCH-02: approve as proposed
D-ORCH-03: hold
```

The orchestrator records each answer in `decisions.md` and unblocks whatever it
unblocks. Unanswered decisions are presented as a batch at the next natural
boundary — that is a stop — so pre-answering keeps an unattended run moving.

## Unattended run (paste after NEXT.md)

```text
UNATTENDED RUN AUTHORIZATION (this run only):
1. Pre-approve section drafts inside the lane prompt's scope, touching no
   frozen contract (SYS-01/02/06/07/08/09/10/11/13/29/32 + game concept).
2. Never idle: a lane blocked on me goes PAUSED + a decisions.md entry with
   options + your recommendation; start the next unblocked lane within WIP.
3. Hard stops: contract revisions, art-bible direction, edits to
   world-mutation-epochs.md / dual-reality-state.md, required-review refusal,
   CI red, 350k.
4. Checkpoint-commit + push lane branches at every section boundary.
5. End state: update STATE.md + NEXT.md, write the handoff, stop with a
   one-line summary of what waits for me.
```

## WIP limits (global — not per chat)

| Resource | Limit |
|---|---|
| GDDs in three-seat review | 2 |
| CodeRabbit passes in flight | 1 |
| Shared-file writers (sync lane) | 1 |
| Authored-queued lanes | 3 |
| Active lane runners | 3 |

## Context + model quick facts

- Soft **250k** → finish the atomic step, write the handoff, stop starting work.
- Hard **350k** → stop. DCP `compress` buys room mid-session; it is **not** a
  handoff.
- Routing: creative → **GLM-5.3-flash**; technical → **DS v4.1-flash**.
- Spawn failures: up to **4 attempts** on server-side errors, then a technical
  (DS) lane may fall back to GLM; a creative (GLM) lane **never** falls back to
  DS — it is parked `PAUSED` and the decision comes to you.

## The three rules

1. The orchestrator chat **never authors** — say: `You are authoring. Launch a
   lane instead.`
2. **Never paste a stale `NEXT.md`** — run
   `node tools/orchestration/render-prompts.mjs --check` first.
3. **Never bypass the WIP limits** — they are the throughput mechanism, not a
   brake.
