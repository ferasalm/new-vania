<!--
Lane: ART-BIBLE
Branch: docs/art-bible
Worktree: ../new-vania-art-bible
Version: 1.0.0
Hash: a8bd12d12f2c
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
edit. Record the request in your lane report and continue on the parts that do
not depend on it.

Never touch `design/gdd/world-mutation-epochs.md`,
`design/gdd/dual-reality-state.md`, their review logs, or `docs/sys10-world-mutation`.

### Shared files — single-writer law

`design/registry/entities.yaml` and `design/gdd/systems-index.md` are written
**only** by the sync lane. You prepare a sync request (the exact entries/rows and
the diff) in your lane report; the orchestrator queues it; the sync lane applies
it serially on a fresh `origin/Main`. Do not edit either file yourself.

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

## ART-BIBLE — the visual identity specification

**Mission**: author `design/art/art-bible.md` — the visual identity spec that
gates all asset production — and resolve the SYS-11 OQ-1 purple-bridge question as
its first item.

**Branch**: `docs/art-bible` · **Worktree**: `../new-vania-art-bible`

**Read order**: `design/gdd/game-concept.md` (pillars, visual anchor, anti-pillars)
· `design/art/concepts/REVIEW.md` + `PROMPT-PACK.md` (the concept art direction)
· `design/gdd/dual-reality-state.md` TR-DR-002/TR-DR-012 (the A/B/liminal tables,
the purple admission test) · `design/gdd/seam-borders.md` OQ-1..7 and the
`PROV_LIM_*` derivation · `design/gdd/room-world-structure.md` Player Fantasy line
36 (the "purple bridge" line) · `design/gdd/systems-index.md` SYS-02/SYS-09/SYS-11
rows · `.agents/skills/art-bible/SKILL.md` (the 9-section workflow).

**Obligations**:
1. **SYS-11 OQ-1 first** — decide the purple bridge: (a) ratify the purple as a
   gated depth tint over the liminal ramp against the liminal-grey reservation,
   with the P1–P5+G admission test; or (b) amend SYS-02's Player Fantasy line 36
   and qualify the SYS-11 index row (the OQ-M1 pattern). The grey `PROV_LIM_*`
   default ships either way. Bring the decision package to the user; the art
   bible records the ruling.
2. **Palette pins** — the A/B packs and the liminal ramp: four `PROV_LIM_*` L
   values with `gap_R ≥ 0.09`; the grief tint's C/L and hue band [330, 20]; the
   `PROV_GLITCH_ACCENT`; `PROV_SIGIL_RED` stays reserved, not a member. Every
   entry carries `{hex, status: PLACEHOLDER|PINNED, source}`.
3. **The ramp/grief pins** (SYS-11 OQ-4) — if the L gaps are < 0.09, the D-gap
   clause relaxes to ≥ 0.01 or the tint closes; record which.
4. **The 9 sections** per the art-bible skill: Visual Identity Statement, Color
   Palette, Lighting & Atmosphere, Character Art Direction, Environment & Level
   Art, UI Visual Language, VFX & Particle Style, Asset Standards, Style
   Prohibitions. Section-by-section user approval.
5. **Asset-spec handoffs** — produce the handoff list for `/asset-spec`: the
   palette tables, the style prohibitions, the silhouette/read rules, the
   placeholder-to-PINNED upgrade path.
6. **SYS-11 OQ-4 + the purple admission test** are the art bible's first
   deliverables; the rest of the bible may follow in the same lane.

**Hard constraints**: one geometry, two palettes; the liminal ramp is
epoch-invariant; the arena's pristine lie keeps its `epoch_pin: 0`; the greys
read quiet, not corrupted; the purple is never on the threshold band, the north
row, the fill, fixtures, or M4; no new MVP prompt/VFX/audio is authorized by the
bible.

**DoD**: art-director draft + creative-director review + **user approval** of the
visual identity + the palette pins + the SYS-11 OQ-1 ruling recorded + the
asset-spec handoff list. The bible is `design/art/art-bible.md`; commit + push +
PR `--base Main`; no CodeRabbit gate for the art bible unless the PR touches code.
