<!--
Lane: SYS-04
Branch: docs/sys04-audio-core
Worktree: ../new-vania-sys04-audio-core
Version: 1.0.0
Hash: 4e689924ac17
Source: production/orchestration/lane-kickoff-master.md
Generated: 2026-11-14
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

## SYS-04 — Audio Core (the flip's sound, the no-duck law)

**Mission**: author `design/gdd/audio-core.md` — the audio architecture and the
sound-design contract for the flip, the arena, the combat edges, and the mix.

**Branch**: `docs/sys04-audio-core` · **Worktree**: `../new-vania-sys04-audio-core`

**Read order**: `design/gdd/dual-reality-state.md` TR-DR-004 (the E1–E7
Flip-Trigger Contract, the guarantees), TR-DR-011 (the arena's steel-hum
expectation), TR-DR-012 (the liminal wing), the audio interaction row ·
`design/gdd/world-mutation-epochs.md` (E3b's publisher note; the abort case) ·
`design/gdd/juice-feedback.md` TR-JCE-027 (the closed audio edge list + the single
death-duck request) · `design/gdd/seam-borders.md` AR-SMB-01..04 (zero audio
publications; the no-duck ruling; M4's chime is not the seam's) ·
`design/gdd/combat.md`/`health-damage.md` (the combat/heal/death edges) ·
`design/gdd/systems-index.md` SYS-04 row.

**Obligations**:
1. **The E1–E7 Flip-Trigger Contract** — consume it verbatim. `ambient_shift`
   (E3b) is pinned to `epoch_swap`'s tick; the arriving bed's first audible
   component is no earlier than the release boundary (receding-first); the tear
   hook is beat-aligned at τ0; `freeze_open`/`freeze_close` are the stillness
   brackets; `flip_complete` is the resume. Do not add, remove, or re-time an
   edge; a change is a contract-revision request.
2. **The receding-first `ambient_shift`** — the target set is the non-arena rooms
   exactly; zero arena-bed orders across the window; the bed turns over under the
   tear, never before it; the abort case leaves the bed put (`freeze_open` fires,
   E3/E3b/E4 never do).
3. **The freeze brackets** — the audio holds its breath across
   `[freeze_open, freeze_close]`; no new one-shot, no loop restart, no snapshot
   change that reads as a beat; the freeze is not a duck.
4. **The arena steel hum** — the arena's ambient bed remains the steel hum
   post-flip; the arena is epoch-invariant in audio as it is in render.
5. **The no-duck ruling** — the only duck is the death beat (TR-JCE-027,
   provisional −6 dB, held to the offline exit). No hit-stop duck, no flip duck,
   no seam duck, no reveal-hold duck, no pause duck. The static audit must find
   exactly one duck request family.
6. **The closed edge list** — the ten SYS-29 edges (damage tick, clash pair,
   deflect tick, heal chime, death power-down, revive boot, level-up print, memory
   chime, jump-2 tick, defeat tick) + the flip edges. No per-press popups, no
   "ORDER RECEIVED" voice.
7. **The audio architecture** — buses, snapshots, voice limits, loop points,
   import settings, the mobile budget (the reference SKU), the duck request
   schema `{bus, dB, hold}`, the telemetry, and the missing-input failure paths.
8. **The mix** — the death-duck value ratification (OQ-J7), the bus layout, the
   priority/steal rules, the ambient bed layers, and the accessibility options
   (mono, captions for non-speech cues if in scope).

**Hard constraints**: SYS-09 owns the flip's choreography; SYS-04 owns all sound
content; SYS-10 owns E3b's emission; SYS-29 owns the edge list; SYS-11 issues zero
audio publications; no new audio edge at MVP without a contract revision.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
