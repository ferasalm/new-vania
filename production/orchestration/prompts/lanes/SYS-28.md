<!--
Lane: SYS-28
Branch: docs/sys28-narrative-presentation
Worktree: ../new-vania-sys28-narrative-presentation
Version: 1.0.0
Model: cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash
Hash: e2e9a0f20532
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

## SYS-28 — Narrative Presentation

**Mission**: author `design/gdd/narrative-presentation.md` — the text-only
narrative surfaces: logs, briefings, reports, terminal copy, and the telegraph
text.

**Branch**: `docs/sys28-narrative-presentation` · **Worktree**:
`../new-vania-sys28-narrative-presentation`

**Read order**: `design/gdd/systems-index.md` SYS-28 row · `design/gdd/dual-reality-state.md`
TR-DR-007/TR-DR-010 (the tell registry + the semantic linkage) ·
`design/gdd/world-mutation-epochs.md` TR-WME-008 (the telegraph-text requirements)
· `design/gdd/seam-borders.md` (the M4/reveal text surface) ·
`design/gdd/game-flow-session.md` (if landed) · `design/gdd/game-concept.md`
(voice, micro-copy budget).

**Obligations**:
1. **The text-only law** — logs, briefings, reports, terminal copy; no voice, no
   cutscenes, no camera, no gameplay effect.
2. **The micro-copy budget** — ≤ 3 short lines per terminal/log/memory beat;
   diegetic android-diagnostics framing (IP-8).
3. **The telegraph-text law** — SYS-10's TR-WME-008: the L2 threshold log may
   dramatize the truth in the house's own voice but never inventories the tells,
   names their surfaces, or confirms noticing; the text is epoch-invariant.
4. **Out-of-order discovery** — the alternate log states for out-of-order
   discovery (IP-8); the state model, the fallback, and the no-spoiler rule.
5. **The Reading context** — SYS-09's close ≡ completion input (OQ-DR-1); ratify
   or amend at authoring; the text length budget against the Reading context.
6. **The surfaces** — the Sanctum log, the terminal, the briefing, the report, the
   memory text, the cache text, the death/revive text. Name the owner and the
   missing-input failure path for each.

**Hard constraints**: SYS-05 owns the flow; SYS-10 owns the telegraph
requirements; SYS-09 owns the tell registry; SYS-28 owns the text. Never confirm
the player noticed a tell. No new gameplay effect from text.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
