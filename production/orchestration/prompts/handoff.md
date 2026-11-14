# Handoff Template — the mode-agnostic handoff

> **Use**: at the 250k soft trigger (prepare) or the 350k hard trigger (stop), and
> at the end of every chat. Copy this file, fill every section, and either paste
> it into a fresh chat, use it after `/clear`, or attach it to a compaction.
>
> **Policy**: `production/orchestration/CONTEXT-POLICY.md`.
> **Generated orchestrator handoff**: `prompts/NEXT.md` (do not hand-edit).

---

## 0. Re-read the files (standing clause)

> The handoff is a **pointer, not a summary of record**. Re-read `STATE.md`,
> `manifest.yaml`, the lane report, and any file you are about to edit. If this
> handoff and the files disagree, **the files win**.

## 1. Current task

- **Role**: orchestrator | lane runner | seat | sync | ops
- **Lane / branch**: `<ID>` · `<branch>`
- **Worktree**: `<path>`
- **What this chat did**: <one paragraph, past tense>
- **Where it stopped**: <phase: AUTHORING / CD GATE / SEATS / REPAIRS / SPOT-CHECK / SYNC / PR / CODERABBIT / MERGED>

## 2. State files (read in this order)

1. `production/orchestration/STATE.md` — live state, blockers, lock, landings.
2. `production/orchestration/manifest.yaml` — lanes, statuses, prompt hashes.
3. `production/orchestration/review-queue.md` — review/sync/CodeRabbit queues.
4. `production/orchestration/decisions.md` — open user decisions.
5. `production/session-state/active.md` — session checkpoint.
6. `<lane report>` — `production/session-state/lane-<ID>-report.md` (in the worktree).

## 3. Next action (exactly one)

- **Do**: <the single next step>
- **Command**: `<exact command>`
- **Expected result**: <what "done" looks like>
- **If it fails**: <the fallback, or "stop and report">

## 4. Constraints (do not violate)

- **Frozen contracts**: SYS-01/02/06/07/08/09/10/11/13/29/32 + the game concept.
  A change is a user-approved contract revision in `decisions.md`.
- **Never touch**: `design/gdd/world-mutation-epochs.md`,
  `design/gdd/dual-reality-state.md`, their review logs,
  `docs/sys10-world-mutation`.
- **Git**: no commits on `Main`; branch + PR `--base Main`; squash-merge; no
  force-push. Conventional Commits, header ≤ 100 chars.
- **Do not start**: `/create-architecture`, `/create-control-manifest`,
  `/create-epics`, `/create-stories`, `/create-sprint-plan` before the MVP GDD set
  is complete.
- **Blocked lanes**: SYS-16/SYS-17 stay `BLOCKED` until SYS-07-REWORK lands.

## 5. Model routing (hard rule)

| Division | Model |
|---|---|
| Creative — art, audio, narrative, world/level, UX/UI, game design, memory, inventory | `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` |
| Technical — save/serialization, progression/economy math, ADRs, QA, sync, engineering | `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017` |

A creative lane that ran on DS is rerun on GLM. The lane runner's model is the
manifest `model`; the seats' models are set per their briefs.

## 6. WIP limits (current)

| Resource | Limit |
|---|---|
| GDDs in three-seat review | 2 |
| CodeRabbit passes in flight | 1 |
| Shared-file writers | 1 (the sync lane) |
| Authored-queued lanes | 3 |
| Active lane runners | 3 |

Pull continuously; do not schedule by day.

## 7. Context budget

- **Soft 250k** → update `STATE.md`, write this handoff, finish the atomic step,
  stop starting new work.
- **Hard 350k** → stop and hand off. Do not start another lane or review.
- **Mode**: (a) fresh chat · (b) `/clear` (transcript saved, context verifiably
  empty) · (c) compaction (mechanical only, with the clause).
- If mode (c): *"The compaction summary is an index, not the source of truth."*

## 8. Paste-check

1. `node tools/orchestration/render-prompts.mjs --check` → must print
   `✔ orchestration prompts verified`.
2. The header in `prompts/NEXT.md` must match the manifest `next:` block:
   `Version` + `Hash`.
3. If they differ: **stop**, run `node tools/orchestration/render-prompts.mjs`,
   and re-check. Never hand-edit a generated prompt.

## 9. Open questions / decisions pending

- <D-ORCH-NN> — <question> — owner <agent> — blocks <lane?>.
- If none: "None. All decisions are batched and recorded."

## 10. The prompt to paste

- **Orchestrator**: `production/orchestration/prompts/NEXT.md`
- **Lane**: `production/orchestration/prompts/lanes/<ID>.md` + `prompts/lane-runner.md`
- **Sync**: `production/orchestration/prompts/sync-lane.md`
