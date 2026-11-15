<!--
Lane: SYS-14
Branch: docs/sys14-grief-boss-framework
Worktree: ../new-vania-sys14-grief-boss-framework
Version: 1.0.0
Model: cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash
Hash: a6ae5fbdfe32
Source: production/orchestration/lane-kickoff-master.md
Generated: 2026-11-15
-->

## Shared contract — every lane

### Mission discipline

You are one lane runner. You author **one document** (or one support package) to
its definition of done. You do not author other lanes, you do not edit shared
files, and you do not merge anything except your own lane PR.

### Workspace

- Work **only** in the lane worktree named in the header. Never edit files in the
  main checkout or another lane's worktree.
- The branch was created from `origin/Main` by `npm run task:new -- <branch>`.
  Confirm `git log --oneline -1` and `git status --short` before writing.
- Run `npm install` once in the worktree if the hooks/tests need it.
- Commit with Conventional Commits (header ≤ 100 chars, body wrapped at 100,
  reference the lane ID and the design doc). Never commit on `Main`.
- Push the branch and open a PR with `--base Main`. Never force-push.

### Read order (once, in this order)

1. `production/orchestration/STATE.md` — the live lane state and blockers.
2. `production/orchestration/manifest.yaml` — your row, dependencies, review state.
3. Your lane prompt (`production/orchestration/prompts/lanes/<ID>.md`).
4. The consumed GDDs and registry entries named in your lane block.
5. `design/gdd/systems-index.md` — your row and the dependency map.
6. `docs/framework/technical-preferences.md` and `docs/engine-reference/godot/VERSION.md`.

Do not read the whole design corpus. Read the named contracts once.

### Frozen contracts

The landed GDDs are frozen: SYS-01, SYS-02, SYS-06, SYS-07, SYS-08, SYS-09,
SYS-10, SYS-11, SYS-13, SYS-29, SYS-32, and the game concept. A change to one of
their contracts is a **contract-revision request** in
`production/orchestration/decisions.md` — batched for the user, never a silent
edit. A **recorded, user-approved** revision (the decision ID in `decisions.md`)
is the only way a lane edits a frozen document; the commit names the decision
ID. No approval = no edit. Record the request in your lane report and continue
on the parts that do not depend on it.

Never touch `design/gdd/world-mutation-epochs.md`,
`design/gdd/dual-reality-state.md`, their review logs, or `docs/sys10-world-mutation`.

### Shared files — single-writer law

`design/registry/entities.yaml` and `design/gdd/systems-index.md` are written
**only** by the sync lane. You prepare a sync request (the exact entries/rows and
the diff) in your lane report; the orchestrator queues it; the sync lane applies
it serially on a fresh `origin/Main`. Do not edit either file yourself. The only
exception is the **SYNC-LANE**, which is the designated writer and applies the
queued diffs.

### The authoring loop (GDD lanes)

1. **Context + feasibility brief** — present the consumed contracts, the open
   questions, and the proposed section plan. Wait for the user's approval before
   authoring sections.
2. **Author section by section** with `/design-system` discipline: Question →
   Options → Decision → Draft → Approval. Write each approved section to file
   immediately. Cross-check new entities/formulas against the registry as you go.
3. **CD gate** — spawn the `cd-gate` seat with `seat-briefs/cd-gate.md` (creative/
   CD routing: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash`). CONCERNS or
   REJECT → revise in-session and re-run.
4. **Three-seat review** — spawn `creative`, `technical`, `qa` as nested
   subagents with the neutral briefs. Creative → GLM-5.3-Flash; technical and QA →
   `cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017`. Each seat
   returns a verdict + numbered blockers + capped recommendations. Blockers only;
   no praise, no restating the document.
5. **Repairs** — apply every valid blocker in-session. A blocker you believe is
   invalid gets a written rebuttal in the review log, never a silent skip.
6. **qa-lead spot-check** — mandatory on repaired text (`qa-spot-check` brief,
   deepseek routing). FAIL → repair → re-run. PASS → record it.
7. **Final micro-check** — diff-scoped fresh-seat check on the last repair delta,
   blockers only. Hard bar: zero blockers. Then stop; do not reopen the document.
8. **Sync handoff** — prepare the registry entries and the systems-index row/diff;
   send them to the orchestrator. The sync lane applies them on a fresh Main.
9. **PR + CodeRabbit** — push, open the PR `--base Main`, run **one** CodeRabbit
   pass. Triage every finding in one batch → one fix commit → resolve threads
   manually with recorded dispositions. A confirm pass only for a Major-class fix
   batch.
10. **Merge** — squash-merge after the sync lands and all required checks are
    green. Record the landing receipt in the lane report and in
    `production/orchestration/STATE.md` (the orchestrator writes STATE).

### Seat spawning rules

- Spawn each seat with a **neutral brief** and the document path; do not tell the
  seat what verdict you want.
- The seat reads the document once, in full, and returns the brief's output
  format. The lane runner does not re-read the whole document to judge the seat;
  it judges the blockers.
- Cap recommendations: at most 10 per seat, non-blocking, each one line. The
  review budget is a WIP limit, not a quota.
- If a nested subagent tool is unavailable, run the seat pass yourself in a
  separate pass with the same brief and record the fallback in the review log.

### Blocker taxonomy

- **Hard** — missing dependency/contract, contract conflict, user decision,
  required approval, failing required CI, unresolved Major thread. Stop the lane,
  write the blocker in the lane report, switch to another lane. The orchestrator
  batches the user decision.
- **Soft** — review queue wait, shared-file lock wait, stale prompt, a seat
  recommendation you can defer. Switch lanes; never idle.

### Report format (write to `production/session-state/lane-<ID>-report.md`)

```markdown
# Lane <ID> — report
- Status: <state machine value>
- Branch / worktree / PR:
- Prompt: <version> / <hash> (matches manifest: yes/no)
- Gate trail: CD <verdict> · creative <verdict> · technical <verdict> · QA <verdict> · spot-check <PASS/FAIL> · micro-check <PASS/FAIL>
- Blockers (hard): <numbered, with owner + decision needed>
- Sync request: <entries/rows + exact diff summary>
- CodeRabbit: <threads / dispositions>
- Landing receipt: <hash or "not merged">
- Next action:
```

### Quality bar

Every formula: variables with types + ranges, an Output clause, worked examples.
ms is the contract; ticks derive by the never-stingy ceil at the active rate.
Every cross-boundary contract: named owners, missing-input failure paths,
bidirectional registry + index entries. No placeholders in a landed GDD. Counts
must reproduce (TR / formulas / V-invariants / ACs / gate partition).

## SYS-14 — Grief-Boss Framework (Denial state only)

**Mission**: author `design/gdd/grief-boss-framework.md` — one boss rig, five
grief states, the Denial state at MVP, and the arena contract.

**Branch**: `docs/sys14-grief-boss-framework` · **Worktree**:
`../new-vania-sys14-grief-boss-framework`

**Read order**: `design/gdd/systems-index.md` SYS-14 row ·
`design/gdd/enemy-ai-telegraphs.md` (the archetype/strike/telegraph contract;
the unclashable strikes + the denied-lean rider) · `design/gdd/combat.md` (the
exchange) · `design/gdd/health-damage.md` (the boss's HP/caps/floors/immune
kinds/scripted death) · `design/gdd/camera-framing.md` (the `arena_hold` level,
the staging band, the holds) · `design/gdd/room-world-structure.md` (the arena's
`epoch_pin: 0` + the arena room) · `design/gdd/dual-reality-state.md` TR-DR-011
(the arena's pinned presentation).

**Obligations**:
1. **One rig, five states** — the state machine, the shared skeleton, the
   per-state interaction rule, and the silhouette test. Only **Denial** is MVP;
   the other four are VS/Alpha placeholders with named gates.
2. **The strike/telegraph contract** — consume SYS-13's archetype/strike contract;
   the boss's unclashable strikes inherit the denied-lean rider; the boss's own
   values (300 HP, caps, floors, immune kinds, scripted death) are SYS-14's.
3. **The arena contract** — `arena_hold {zone_id, active}` (idempotent), the
   staging band x [3296, 3744] × y [65, 287], the camera locks, the `epoch_pin: 0`
   pristine lie, and the reveal-lease non-overlap.
4. **The knowledge route** — each grief boss exposes at least one
   log/environment-teachable weak point (IP-10); the knowledge route past the
   grind; the no-new-interactables-post-flip law.
5. **The death/defeat contract** — the scripted death, the defeat edge, the
   revive/offline handshake, and the telemetry.
6. **The five-state frame** — the shared rig's data model so the VS states can
   land without a rewrite.

**Hard constraints**: SYS-13 owns the enemy machinery; SYS-08 owns the exchange;
SYS-32 owns the camera; SYS-02 owns the room data; SYS-14 consumes them. The
arena renders epoch 0 through the entire flip. No new camera mode.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
