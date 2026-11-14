# Lane Kickoff Master — the per-system authoring blocks

> **Status**: MVO master, 2026-11-14. Source of truth for `prompts/lanes/*.md`.
> Regenerate lane prompts with `node tools/orchestration/render-prompts.mjs --all`.
> Never hand-edit a generated lane prompt; edit this master and re-render.

The master is split into a **shared contract** (below) and **lane blocks** (marked
`<!-- LANE:ID -->` … `<!-- /LANE:ID -->`). The renderer prepends the shared
contract to every lane prompt and hashes `shared + block` so a change to either
invalidates every lane hash.

<!-- SHARED -->
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
<!-- /SHARED -->

---

<!-- LANE:ART-BIBLE -->
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
<!-- /LANE:ART-BIBLE -->

<!-- LANE:SYS-03 -->
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
<!-- /LANE:SYS-03 -->

<!-- LANE:SYS-04 -->
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
<!-- /LANE:SYS-04 -->

<!-- LANE:SYS-15 -->
## SYS-15 — Cache Stations & Death-as-Story

**Mission**: author `design/gdd/cache-stations-death.md` — the cache/checkpoint
stations, the death-as-story loop, the System Offline contract, and the
designation increment.

**Branch**: `docs/sys15-cache-stations-death` · **Worktree**:
`../new-vania-sys15-cache-stations-death`

**Read order**: `design/gdd/systems-index.md` SYS-15 row · `design/gdd/health-damage.md`
(the death/offline/revive surfaces SYS-07 owns) · `design/gdd/game-flow-session.md`
(if landed; otherwise SYS-05's index row) · `design/gdd/save-serialization.md`
(if landed; otherwise SYS-03's contract) · `design/gdd/room-world-structure.md`
(the room graph + the cache placements) · `design/gdd/juice-feedback.md`
TR-JCE-027 (the death duck + power-down/revive edges) · `design/gdd/narrative-presentation.md`
(if landed).

**Obligations**:
1. **MEMORY CACHED** — the cache station's interaction, the checkpoint semantics,
   the respawn point, the designation increment, and the save trigger.
2. **Death-as-story** — the death loop's fiction, the reconstruction beat, the
   System Offline contract to SYS-07, the training-point surface, and the
   no-punishment law (what persists, what resets).
3. **The cache-adjacency doctrine** — terminals at epoch-shift thresholds and boss
   gates as the map scales (IP-6).
4. **The fast-travel OQ** — Full-Vision only; record the decision, do not build it
   into the MVP.
5. **The save/flow contract** — cache → SYS-03's save; cache → SYS-05's flow; the
   death → offline → revive handshake; the missing-input failure paths.

**Hard constraints**: SYS-03 owns the save; SYS-05 owns the flow; SYS-07 owns the
death/offline state; SYS-15 consumes them. The death beat's audio is SYS-04's;
the duck is TR-JCE-027's. No new save family.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
<!-- /LANE:SYS-15 -->

<!-- LANE:SYS-28 -->
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
<!-- /LANE:SYS-28 -->

<!-- LANE:SYS-14 -->
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
<!-- /LANE:SYS-14 -->

<!-- LANE:SYS-05 -->
## SYS-05 — Game Flow & Session Structure (linear stub)

**Mission**: author `design/gdd/game-flow-session.md` — the context state
machine, the hub → briefing → dive → report → contract → spend loop, and the
save/load/death flow.

**Branch**: `docs/sys05-game-flow-session` · **Worktree**:
`../new-vania-sys05-game-flow-session`

**Read order**: `design/gdd/systems-index.md` SYS-05 row ·
`design/gdd/save-serialization.md` (if landed; otherwise SYS-03's index row) ·
`design/gdd/dual-reality-state.md` (the Reading close ≡ completion input,
OQ-DR-1) · `design/gdd/world-mutation-epochs.md` (the reconcile chain publishes
the flip request before the load-complete gate) · `design/gdd/room-world-structure.md`
(the Reading contexts' non-ack row; the room transition is not a gate; the
TRANSITION fallback) · `design/gdd/input-control-mapping.md` (the context gates).

**Obligations**:
1. **The context state machine** — the contexts (Gameplay, Reading, Pause,
   TRANSITION fallback, Offline, Menus), the entry/exit conditions, the input
   gates, and the no-double-gate law.
2. **The loop** — hub → briefing → dive → report → contract → spend; the linear
   stub at MVP; the VS/full loop's named gates.
3. **The save/load flow** — load-complete gate, the reconcile chain, the
   flip-request ordering, the save queue, and the failure paths.
4. **The death/revive flow** — offline entry/exit, the cache handshake, the
   System Offline contract, and the return-to-gameplay edge.
5. **The Reading context** — close ≡ completion at MVP (no dismiss affordance);
   ratify or amend SYS-09's input; the text-length budget.
6. **The transition law** — the room transition is not a gate; the
   ack-sourced door row; the TRANSITION context is the non-resident-load fallback
   and is never entered at MVP.

**Hard constraints**: SYS-03 owns the save; SYS-09/10 own the flip; SYS-02 owns
the room data; SYS-05 owns the context machine. The pause is not a freeze; the
freeze is not a gate. No new input verb.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
<!-- /LANE:SYS-05 -->

<!-- LANE:SYS-24 -->
## SYS-24 — HUD (minimal, live-publication consumer)

**Mission**: author `design/gdd/hud.md` — the minimal MVP HUD, the touch
dispatcher/hit-rect registration, the z-order law, and the live 9-field
publication consumption.

**Branch**: `docs/sys24-hud` · **Worktree**: `../new-vania-sys24-hud`

**Read order**: `design/gdd/systems-index.md` SYS-24 row ·
`design/gdd/camera-framing.md` TR-CAM-015 (the 9-field publication: `player_screen_px`,
`on_screen`, `view_rect_px`, `bounds_generation`; the hold-mode contract) ·
`design/gdd/health-damage.md` (HP, the bar, the damage-number ownership) ·
`design/gdd/combat.md` (the combat state) · `design/gdd/input-control-mapping.md`
(the touch dispatcher, the hit-rect registration, the safe areas) ·
`design/gdd/juice-feedback.md` (the print geometry, the damage-number render law)
· `design/art/concepts/REVIEW.md` (red discipline, thumb coverage).

**Obligations**:
1. **The minimal HUD** — HP, the memory counter, the quick-slot/gear readout, the
   interaction prompt, the pause affordance, and the System Offline surface. No
   more than the MVP set.
2. **The 9-field publication** — consume `player_screen_px`, `on_screen`,
   `view_rect_px`, `bounds_generation` live every physics tick from activation;
   never cache (world-still ≠ screen-still during a hold pan); the hold-mode
   anchor rule; the missing-input failure path.
3. **The touch dispatcher** — the hit-rect registration, the z-order law, the
   thumb-coverage caps, the safe-area floors, and the landscape-primary layout.
4. **The red discipline** — the HUD's use of red, the REVIEW.md constraints, and
   the colorblind-safe encoding.
5. **The settings surface** — the settings the HUD owns (per SYS-29's note), the
   accessibility toggles, and the persistence handoff to SYS-03.
6. **The no-touch-geometry law** — the HUD reads combat/movement state; it never
   authors touch geometry for the world.

**Hard constraints**: SYS-32 owns the camera publication; SYS-07 owns the HP
pool; SYS-29 owns the damage numbers/prints; SYS-01 owns input. SYS-24 consumes
them read-only. No new gameplay state.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
<!-- /LANE:SYS-24 -->

<!-- LANE:SYS-12 -->
## SYS-12 — Motion Input / Stinger Gesture (demon-granted)

**Mission**: author `design/gdd/motion-input-stinger.md` — the quarter-spin
Stinger gesture, the buffering across touch/KB/gamepad, and the demon-granted MVP
ability.

**Branch**: `docs/sys12-motion-input-stinger` · **Worktree**:
`../new-vania-sys12-motion-input-stinger`

**Read order**: `design/gdd/systems-index.md` SYS-12 row ·
`design/gdd/input-control-mapping.md` (the gesture reservation policy, the
input contracts) · `design/gdd/combat.md` (the exchange SYS-12 feeds) ·
`design/gdd/health-damage.md` (the mana mapping — the VS consumer question) ·
`design/gdd/game-concept.md` (D-3's MVP promotion) ·
`design/gdd/game-flow-session.md` (the grant moment, if landed).

**Obligations**:
1. **The SYS-01 gesture-reservation amendment** — the current policy says
   "Reserved-VS socket only, no consuming code in MVP"; SYS-12's first obligation
   is the amendment that admits the demon-granted Stinger at MVP. A contract
   revision: prepare it, batch it, do not silently edit SYS-01.
2. **The gesture** — the quarter-spin + Attack, the tolerance window, the
   buffer, the cross-device parity (touch/KB/gamepad), the failure/neutral paths,
   and the accessibility alternative.
3. **The demon grant** — the grant moment in SYS-05, the fiction, the UI/tell
   surface, and the no-permanent-upgrade law.
4. **The combat integration** — SYS-08's exchange consumption, the commitment
   shape, the cancel windows, and the no-new-verb boundary.
5. **The mana reconciliation** — SYS-07's TR-HD-008/009 map mana → the Stinger as
   a VS consumer; either keep the MVP Stinger mana-free (the VS mapping stands)
   or give mana an MVP consumer (re-routes to the SYS-07 baseline-rework session,
   IP-17). Record the decision in `decisions.md`.

**Hard constraints**: SYS-01 owns input; SYS-08 owns the exchange; SYS-05 owns the
grant moment; SYS-07 owns mana. SYS-12 consumes them. No new input verb beyond
the Stinger; no touch gesture that conflicts with the core scheme.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge. The SYS-01
amendment is a separate contract-revision decision, not a silent edit.
<!-- /LANE:SYS-12 -->

<!-- LANE:SYS-20 -->
## SYS-20 — Memory Fragments (3–4 pickups + counter)

**Mission**: author `design/gdd/memory-fragments.md` — the 3–4 MVP memory
pickups, the counter, the M4 payload, and the gallery hook.

**Branch**: `docs/sys20-memory-fragments` · **Worktree**:
`../new-vania-sys20-memory-fragments`

**Read order**: `design/gdd/systems-index.md` SYS-20 row ·
`design/gdd/save-serialization.md` (the `memories_collected` family) ·
`design/gdd/room-world-structure.md` (the rooms + the M4 placement in the Cold
Corridor) · `design/gdd/dual-reality-state.md` TR-DR-012 (the grief tint on M4;
the wing) · `design/gdd/world-mutation-epochs.md` (the reveal) ·
`design/gdd/juice-feedback.md` TR-JCE-021 (the memory chime) ·
`design/gdd/narrative-presentation.md` (if landed).

**Obligations**:
1. **The 3–4 pickups** — the count, the placements, the collection interaction,
   the counter, and the completion state.
2. **The M4 payload** — the Cold Corridor's last memory, the grief tint, the
   reveal's emotional landing, and the no-new-mechanic law.
3. **The save contract** — `memories_collected` as a source family; the
   collected/uncollected state; the load/restore behavior; no tell state.
4. **The chime/feedback** — TR-JCE-021's memory chime edge; no new audio edge.
5. **The gallery hook** — the VS Memory Gallery (SYS-27) reads the collection;
   define the data contract now, not the UI.
6. **The out-of-order discovery** — the alternate states with SYS-28 (IP-8).

**Hard constraints**: SYS-03 owns the save family; SYS-02 owns the room data;
SYS-09/10 own the wing/reveal; SYS-29 owns the chime. SYS-20 consumes them. The
memories are the player's truth, not the world's; no tell/flag.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge.
<!-- /LANE:SYS-20 -->

<!-- LANE:SYS-25 -->
## SYS-25 — Map / Minimap / Fog-of-War (pause room-grid)

**Mission**: author `design/gdd/map-minimap-fog.md` — the MVP pause room-grid
(discovered cells + unexplored-doorway ticks), the full map/minimap/fog VS frame,
and the save round-trip.

**Branch**: `docs/sys25-map-minimap-fog` · **Worktree**:
`../new-vania-sys25-map-minimap-fog`

**Read order**: `design/gdd/systems-index.md` SYS-25 row ·
`design/gdd/room-world-structure.md` (the room graph, the borders, the cells) ·
`design/gdd/save-serialization.md` (the `cells_discovered` family + the
round-trip) · `design/gdd/world-mutation-epochs.md` (the epoch scoping) ·
`design/gdd/input-control-mapping.md` (the `open_map` reservation, the touch
pause-tab) · `design/gdd/camera-framing.md` (the pause surface publication, if
any) · `design/gdd/hud.md` (the published pause surface to SYS-24 — the
first-pass review scope).

**Obligations**:
1. **The pause room-grid** — discovered cells, unexplored-doorway ticks, the
   current-room marker, the legend, and the no-spoiler rule.
2. **The `cells_discovered` save family** — the store source, the load/restore,
   the round-trip with SYS-03, and the no-double-count law.
3. **The `open_map` reservation** — activate SYS-01's Reserved-VS touch
   pause-tab and its knob row at authoring; the input contract.
4. **The full map/minimap/fog VS frame** — the named gates, the data model, and
   the MVP carve-out.
5. **The pause surface to SYS-24** — the published contract; the first-pass
   review scope (review-doctrine condition 4).
6. **The epoch scoping** — whether the map shows one truth or both; the
   no-spoiler law; the reveal's map effect.

**Hard constraints**: SYS-02 owns the room graph; SYS-03 owns the save; SYS-10
owns the epoch; SYS-25 consumes them. The MVP map is the pause room-grid only; no
minimap, no fog-of-war, no fast travel.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge. The first-pass
review may be diff-scoped per the review doctrine (leaf node), with the
pending-obligation ledger read in.
<!-- /LANE:SYS-25 -->

<!-- LANE:SYS-07-REWORK -->
## SYS-07-REWORK — the IP-17 baseline contract-revision package

**Mission**: prepare the SYS-07 low-stat baseline rework package (IP-17) that
gates SYS-16 and SYS-17. This is a **contract-revision lane**, not a new GDD.

**Branch**: `docs/sys07-baseline-rework` · **Worktree**:
`../new-vania-sys07-baseline-rework`

**Read order**: `design/gdd/health-damage.md` (the approved baseline, the
`StatBlock` identity law, TR-HD-006, TR-HD-008/009) ·
`design/reviews/metroidvania-benchmark-audit.md` (IP-17 + D-1) ·
`design/gdd/game-concept.md` (the amended MVP Definition) ·
`design/gdd/systems-index.md` SYS-07/SYS-16/SYS-17 rows ·
`design/registry/entities.yaml` (the stat/gear entries).

**Obligations**:
1. **The low-stat baseline** — the reworked baseline numbers, the parity target,
   the level 1–5 curve, and the worked examples.
2. **The `TR-HD-006` correction** — the "MVP has no gear" clause's one-clause
   correction (the OQ-M1 rider pattern).
3. **The mana reconciliation input** — the SYS-12 decision (keep the Stinger
   mana-free or give mana an MVP consumer); record the decision's consequence.
4. **The ±10% parity situational-break OQ** — the input SYS-16 needs; the
   playtest question and the guardrails.
5. **The rework package** — the exact diff, the affected ACs, the registry
   updates, and the review route. **Do not edit the approved GDD** until the
   contract revision is approved in `decisions.md`; prepare the package and wait.

**Hard constraints**: SYS-07 is a frozen contract; the rework is a contract
revision. No silent edits, no scope creep beyond IP-17/D-1. The `StatBlock`
identity law holds.

**DoD**: the package + the user's contract-revision approval + the applied diff +
the qa-lead spot-check + the sync request + PR + merge. SYS-16/SYS-17 unblock on
the landing receipt.
<!-- /LANE:SYS-07-REWORK -->

<!-- LANE:SYS-16 -->
## SYS-16 — Progression (level 1–5 + the gear layer)

**Mission**: author `design/gdd/progression.md` — the MVP-minimal level 1–5
progression, the gear layer, and the ability unlock ladder.

**Branch**: `docs/sys16-progression` · **Worktree**: `../new-vania-sys16-progression`

**Read order**: `design/gdd/systems-index.md` SYS-16 row ·
`design/gdd/health-damage.md` (the reworked baseline; the `StatBlock` identity
law) · `design/gdd/combat.md`/`enemy-ai-telegraphs.md` (the XP sources, the
tier/HP) · `design/gdd/input-control-mapping.md` (the ability gates: Dash
action-level, Wall Jump/Double Jump behavior-level on Jump, TR-INP-057) ·
`design/reviews/metroidvania-benchmark-audit.md` (D-1) ·
`design/gdd/systems-index.md` SYS-06's gate contract.

**Obligations**:
1. **Level 1–5** — the XP curve, the points-only data, the stat growth, the
   worked examples, and the no-full-sheet law.
2. **The gear layer** — deterministic named modules (build modifier + 2-line
   lore), the two-slot loadout, the guaranteed Warden-tier drop behind the
   post-flip partition, and the ±10% parity guardrail.
3. **The ability ladder** — Dash → Wall Jump → Double Jump; the grants flow
   SYS-16 → SYS-06's gates; the unlock moments and the no-softlock check.
4. **The `TR-HD-006` correction** — consume the reworked clause; no contradiction.
5. **The save/UI contracts** — the progression state's save family (via SYS-03),
   the HUD readout (SYS-24), and the inventory handoff (SYS-17).

**Hard constraints**: SYS-07 owns the stats; SYS-06 owns the movement gates;
SYS-08/SYS-13 own the combat/economy sources; SYS-16 consumes them. The gear
layer is MVP; the full sheet is VS. No new stat without the identity law.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge. Blocked until
SYS-07-REWORK lands.
<!-- /LANE:SYS-16 -->

<!-- LANE:SYS-17 -->
## SYS-17 — Inventory & Items (MVP carve-out + gear loadout)

**Mission**: author `design/gdd/inventory-items.md` — the MVP carve-out (Suture,
fixed quick slot, restore module) plus the gear layer (named modules, two-slot
loadout).

**Branch**: `docs/sys17-inventory-items` · **Worktree**:
`../new-vania-sys17-inventory-items`

**Read order**: `design/gdd/systems-index.md` SYS-17 row ·
`design/gdd/health-damage.md` (the Suture/quick slot/restore module; the reworked
baseline) · `design/gdd/progression.md` (the gear layer, if landed) ·
`design/gdd/hud.md` (the quick-slot readout) · `design/gdd/game-flow-session.md`
(the pause/menus) · `design/gdd/game-concept.md` (the amended anti-pillars) ·
`design/reviews/metroidvania-benchmark-audit.md` (D-1/D-2).

**Obligations**:
1. **The MVP carve-out** — the Suture, the fixed quick slot, the restore module,
   the use/heal flow, and the no-inventory-screen law.
2. **The gear layer** — the named modules, the two-slot loadout, the build
   modifier, the 2-line lore, and the acquisition/drop path.
3. **The stat presentation** — lean-but-accessible; the anti-pillar wording
   amended 2026-11-14; no spreadsheet.
4. **The save/UI contracts** — the inventory state's save family (via SYS-03),
   the HUD readout (SYS-24), the pause surface (SYS-05).
5. **The item taxonomy** — the MVP item classes, the IDs, the icons (art-bible
   handoff), and the no-VS-items law.

**Hard constraints**: SYS-07 owns the consumables/heal; SYS-16 owns the gear
stats; SYS-24 owns the HUD; SYS-05 owns the pause. SYS-17 consumes them. The full
inventory is VS.

**DoD**: the full GDD + CD gate + three seats + qa-lead spot-check + final
micro-check + sync request + PR + one CodeRabbit pass + merge. Blocked until
SYS-07-REWORK and SYS-16 land.
<!-- /LANE:SYS-17 -->

<!-- LANE:ADR-DRAFT -->
## ADR-DRAFT — parallel architecture decisions (no /create-architecture)

**Mission**: draft the ADRs the landed and in-flight GDDs need, in parallel with
authoring. This lane never runs `/create-architecture`,
`/create-control-manifest`, `/create-epics`, `/create-stories`, or `/sprint-plan`
before the MVP GDD set is complete.

**Branch**: `docs/adr-draft` · **Worktree**: `../new-vania-adr-draft`

**Read order**: `docs/architecture/` (existing ADRs — ADR-0001 is the pattern) ·
`docs/framework/templates/adr.md` (or the ADR template in the framework) ·
the landed GDDs' "Architecture" / "Interactions" sections ·
`docs/engine-reference/godot/VERSION.md`.

**Obligations**:
1. **The ADR backlog** — identify the decisions the landed GDDs require (save
   format, audio bus/engine integration, context state machine, HUD layer,
   map data, narrative data, boss rig, gesture input, memory data, progression
   data). Each ADR: context, decision, alternatives, consequences, status.
2. **Draft in parallel** — one ADR per decision, `Status: Proposed`; no Accepted
   without the architecture review.
3. **The architecture review** — run the `/architecture-review` gate on each
   draft; record the verdict.
4. **The contract links** — every ADR names the GDD TR-IDs it governs and the
   registry entries it touches.
5. **The no-implementation law** — ADRs are decisions, not code. No stories, no
   epics, no control manifest.

**Hard constraints**: no `/create-architecture` etc. before the MVP GDD set is
complete. The landed GDDs are frozen; an ADR that requires a contract change is a
contract-revision request.

**DoD**: each ADR `Accepted` + the architecture-review verdict + the traceability
links. PR `--base Main`; the normal PR gate applies.
<!-- /LANE:ADR-DRAFT -->

<!-- LANE:QA-PLAN -->
## QA-PLAN — the probe registers and the AC→gate ledgers

**Mission**: assemble the QA plan support package: the S1-007 probe pass, the
PR-DR/PR-CAM/PR-SMB registers, the AC→gate ledgers, and the harness plan. This is
a support lane; it does not author GDDs.

**Branch**: `docs/qa-plan-support` · **Worktree**: `../new-vania-qa-plan-support`

**Read order**: `design/gdd/dual-reality-state.md` (the PR-DR-01..07 register) ·
`design/gdd/camera-framing.md` (the PR-CAM-01..08 register) ·
`design/gdd/seam-borders.md` (the PR-SMB/AC admission harness) ·
`design/gdd/systems-index.md` (the QA/gate rows) ·
`production/sprints/` (the current sprint's QA needs) ·
`docs/framework/director-gates.md`.

**Obligations**:
1. **The S1-007 probe pass** — the shift-shader probe that gates SYS-09's
   APPROVED verdict; the harness, the reference SKU, the capture protocol, the
   verdict record.
2. **The PR-DR register** — the seven probes, their instruments, their pass
   thresholds, and the tooling story.
3. **The PR-CAM register** — the eight probes, the device thresholds, the
   motion-parity caps, the soak workload.
4. **The PR-SMB/admission harness** — the OKLCH conversion, the
   desaturate/saturate stress, the band capture.
5. **The AC→gate ledgers** — the smoke/device/lock/VS partition per GDD; the
   exact counts; the no-headless-device law.
6. **The QA plan** — the sprint's test plan, the manual cases, the smoke scope,
   the playtest sign-off.

**Hard constraints**: the QA plan does not change a GDD; a probe failure is a
finding, not an edit. The reference SKU is pinned before the probes run. No
`/sprint-plan`.

**DoD**: the QA plan + the probe harness plan + the ledgers + the qa-lead
sign-off. PR `--base Main`; the normal PR gate applies.
<!-- /LANE:QA-PLAN -->

<!-- LANE:SYNC-LANE -->
## SYNC-LANE — the single shared-file writer

**Mission**: be the only writer of `design/registry/entities.yaml` and
`design/gdd/systems-index.md`. Apply queued lane sync requests serially on a fresh
`origin/Main`.

**Branch**: `chore/sync-shared-files` · **Worktree**:
`../new-vania-sync-shared-files`

**Read order**: `production/orchestration/prompts/sync-lane.md` (the full
protocol) · `production/orchestration/STATE.md` (the lock + the queue) ·
`production/orchestration/manifest.yaml` (the lane rows) · the lane reports in
`production/session-state/lane-*-report.md`.

**Obligations**:
1. **Acquire the lock** — record `shared_file_lock: SYNC-LANE` in STATE.md.
2. **Rebase on origin/Main immediately before the edit** — `git fetch origin`,
   `git rebase origin/Main`; never force-push.
3. **Apply serially** — one lane's registry entries + index row at a time; the
   exact diff from the lane report; no invented entries.
4. **Validate** — YAML parse, duplicate-name scan, source/referenced_by
   consistency, the index row's counts, the design-order row, the status.
5. **Commit + push** — one conventional commit per lane sync (or one batched
   commit if the queue is small), referencing the lane ID.
6. **Update the manifest + STATE** — the lane's `review_state` and `next_action`;
   release the lock; record the sync receipt.

**Hard constraints**: only the sync lane edits the two shared files; every other
lane hands off a diff. Never force-push. Never edit a GDD. Never invent a
registry entry.

**DoD**: the shared files validate + the lane's sync receipt + the manifest
update + the lock released. PR `--base Main`; the normal PR gate applies.
<!-- /LANE:SYNC-LANE -->
