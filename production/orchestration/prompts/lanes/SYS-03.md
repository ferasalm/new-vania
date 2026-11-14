<!--
Lane: SYS-03
Branch: docs/sys03-save-serialization
Worktree: ../new-vania-sys03-save-serialization
Version: 1.0.0
Model: cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017
Hash: 8fbc08eec5c0
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

## SYS-03 — Save & Serialization (the persistence bottleneck)

**Mission**: author `design/gdd/save-serialization.md` — the one save contract
every persistent system consumes. This is the bottleneck: SYS-05, SYS-10, SYS-15,
SYS-20 and SYS-25 all wait on it.

**Branch**: `docs/sys03-save-serialization` · **Worktree**:
`../new-vania-sys03-save-serialization`

**Read order**: `design/gdd/room-world-structure.md` TR-RWS-025 (the five source
families; store sources, derive targets; MetSys's save Dictionary is a written
derived target, never an independent path) · `design/gdd/dual-reality-state.md`
TR-DR-015/E4 (the save-policy law) · `design/gdd/world-mutation-epochs.md`
TR-WME-006 + F-WME-01 (the reconciliation contract; pending derived at load, no
field) · `design/gdd/input-control-mapping.md` (the save-adjacent input laws, if
any) · `design/registry/entities.yaml` (the registered save families) ·
`design/gdd/systems-index.md` SYS-03 row.

**Obligations**:
1. **The five source families** — `doors_opened`, `truth_flags`, `truth_epoch`,
   `memories_collected`, `cells_discovered`. Store the sources; derive the
   targets. The MetSys save Dictionary is a written derived target. No sixth
   family without a contract revision.
2. **`schema_version` + migration** — the version field, the migration policy
   (forward-only, one-step migrations, unknown-version refusal), the downgrade
   policy, and the migration test fixtures.
3. **The E4 save law** — saves inside the flip window queue to the first unfrozen
   tick and capture the post-flip state; a mid-choreography snapshot is never
   written; a deferral-gap save persists `{epoch A, flag set}` and the flip
   re-fires deterministically at the first post-load tick.
4. **The reconciliation contract** — no pending-flip field; the pending condition
   is derived at load; the absent-key-unset default; out-of-range epochs hand off
   to SYS-03's refusal path (the explicit failure, never a silent clamp).
5. **The real-file round-trip twin** — a real-file save/load round-trip test twin
   (not a mock) is the authoring gate: write, close, reload, compare the state
   hash. The twin covers a pre-flip save, a deferral-gap save, a post-flip save,
   and a corrupted file.
6. **The save surface** — atomic write (temp + rename), the corruption/backup
   path, the platform path policy, the slot model, the autosave/manual split, the
   save-during-freeze queue, and the telemetry.
7. **The consumers** — SYS-05's flow, SYS-15's cache/designation, SYS-20's
   memories, SYS-25's `cells_discovered`. Name the owner and the missing-input
   failure path for each.

**Hard constraints**: SYS-02's five families are consumed verbatim; SYS-09's E4
law is consumed verbatim; SYS-10's pending-derived answer is consumed verbatim;
no save field for tells, pending-flip, or freeze state; the save never blocks the
game thread; no encryption/anti-cheat design at MVP unless the security audit
requests it.

**DoD**: the full GDD (all sections) + CD gate + three seats + qa-lead spot-check
+ final micro-check + sync request + PR + one CodeRabbit pass + merge. The
real-file round-trip twin's verdict is part of the GDD's gate record.
