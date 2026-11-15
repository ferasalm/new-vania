# Lane SYS-14 — report

- **Status**: PR_OPEN — **PR #82 at the final head `2007f20`: mergeState CLEAN · 0 unresolved CodeRabbit threads · 6/6 checks green (5 CI + CodeRabbit)**. Awaiting the orchestrator: the sync application → the merge (the required-reviewer rule is the only recorded blocker; the admin-merge fallback is pre-authorized per the lane contract §5.4 — bind the head with `--match-head-commit`).
- **Branch / worktree / PR**: `docs/sys14-grief-boss-framework` / `../new-vania-sys14-grief-boss-framework` / **PR #82** (https://github.com/ferasalm/new-vania/pull/82, `--base Main`, opened on `9aff9e8`; the final head `268398e`)
- **Prompt**: v1.0.0 / `a6ae5fbdfe32` (matches manifest: **yes** — verified by `node tools/orchestration/render-prompts.mjs --check` → ✔; the lane ran on the manifest model GLM — a creative lane on GLM, as required)
- **Base SHA**: `b99171429273271db2c0867b3c0a805469ad7888` (ancestry verified: `git merge-base --is-ancestor` → OK)
- **Gate trail**: CD CONCERNS (3 blockers, all repaired) → **CD APPROVED** (round 2, 0 blockers) · creative **NEEDS REVISION (2)** → repaired · technical **NEEDS REVISION (5)** → repaired · QA **NEEDS REVISION (6)** → repaired · spot-check #1 FAIL (5 residues) → #2 FAIL (1) → #3 FAIL (2) → **#4 PASS** · final micro-check **PASS** (zero blockers). Review record: `design/gdd/reviews/sys14-grief-boss-framework-review-log.md`.
- **Counts (final, verified by the seats + the spot-checks)**: 24 TR-GBF · 6 F-GBF · 11 V-GBF · 30 ACs (smoke 24 = 22 GUT + 2 LINT · device 2 · lock 4 · VS 0) · 4 playtest codes · 9 OQs. Partition reproduces: 24 + 2 + 4 + 0 = 30.
- **Blockers (hard)**: none. **Soft**: the shared-file lock was held by SYNC-LANE at launch (the riders mini sync) — a read-only condition for this lane; no wait was incurred (the lock's PRs #78/#80 are ancestors of this branch base). The user decision D-ORCH-14 (the feasibility brief + the four design calls, approved autonomously under the away-directive) is recorded in `decisions.md`; revisit-on-return noted.
- **Contract-revision requests (batched, never silent)**: none against frozen GDDs. One **batched VS revision request** rides OQ-GBF-4: the boss-defeated save family (a SYS-02/SYS-03 five-family-law amendment at VS — recorded in this report's sync request as a note, never an edit).

## Sync request (the exact entries and rows — for the sync lane to apply on a fresh `origin/Main`)

### A. `design/registry/entities.yaml` — 6 new entries + 4 updates

**A1. NEW `grief_boss_rig_contract`** (kind: published_contract) — place in `entities:` (alphabetical position by name):

```yaml
  - name: grief_boss_rig_contract
    status: active
    source: design/gdd/grief-boss-framework.md
    referenced_by:
      - design/gdd/grief-boss-framework.md
      - design/gdd/enemy-ai-telegraphs.md
      - design/gdd/health-damage.md
      - design/gdd/camera-framing.md
      - design/gdd/room-world-structure.md
      - design/gdd/dual-reality-state.md
      - design/gdd/cache-stations-death.md
    kind: published_contract
    attributes:
      grief_states: "DENIAL | ANGER | BARGAINING | DEPRESSION | ACCEPTANCE (one rig, five truths)"
      authored_at_mvp: "DENIAL only (V-GBF-01: exactly one authored BossRig row; the other four are gated placeholders with zero values)"
      boss_archetype: "grief_denial — tier boss, hp_max 60, soul_class HUMAN, poise telegraph_active, death_scripted TRUE"
      interaction_rule: "Denial: the lie holds — hp_floor 20 in LIE_WHOLE (the death edge cannot fire), cracked by 3 unanswered ring sweeps (the whiff counter), the crack beat releases the floor to 0 (the FloorReleaseRequest — SYS-07 executes the write)"
      arena: "arena_hold {zone_id: denial_arena, active} — idempotent level, room-entry keyed; the staging band x [3296, 3744] x y [65, 287]; the drop seal (authored geometry, never a mutation set); the scripted exit arc at the death script's tail"
      knowledge_route: "IP-10: the crack route — the scuff + the halo hairlines + the bar's stall; no new interactable (RM-06's set = empty), no tell (V-DR-01)"
      added: "2026-11-15"
```

**A2. NEW `arena_hold_level`** (kind: published_contract):

```yaml
  - name: arena_hold_level
    status: active
    source: design/gdd/grief-boss-framework.md
    referenced_by:
      - design/gdd/grief-boss-framework.md
      - design/gdd/camera-framing.md
      - design/gdd/room-world-structure.md
      - design/gdd/dual-reality-state.md
    kind: published_contract
    attributes:
      shape: "arena_hold {zone_id, active} — published every physics tick, idempotent (the TR-MOV-022 level pattern)"
      keying: "room-entry keyed: active = (the player's current room == RM-06); the rise at the entry swap, the fall at the room swap or the death script's tail"
      intro_mask: "INTRO_BEAT_MS 600 >= HOLD_EASE_MS 400 (the OQ-RWS-8 rider) — the approach hides under the intro"
      exit: "the scripted exit arc ARENA_EXIT_MS 700 at the death script's tail — the swap at the arc's midpoint (F-RWS-03's law), the re-anchor at RM-05's anchor behind the door frame"
      notes: "SYS-32 owns the hold law (TR-CAM-012); SYS-14 publishes the level and keeps the fight in the staging band; ARENA_FOLLOW_FALLBACK stays off"
      added: "2026-11-15"
```

**A3. NEW `staging_band_denial`** (kind: contract, a ratified constant set):

```yaml
  - name: staging_band_denial
    status: active
    source: design/gdd/camera-framing.md
    referenced_by:
      - design/gdd/camera-framing.md
      - design/gdd/grief-boss-framework.md
      - design/gdd/room-world-structure.md
    kind: contract
    attributes:
      band: "x [3296, 3744] (448 px) x y [65, 287] (222 px) — 16 px horizontal / 24 px vertical interior margin"
      duty: "every fight participant and threat effect (both fighters, the strikes, the ring return, the beat); the player's reachable space sealed to the band (the walkable-tile check)"
      ratification: "ratified at SYS-14 authoring (OQ-CAM-3, 2026-11-15) — SYS-14 + level-designer author to it; the validator's live check runs at the arena story (AC-CAM-11b)"
      added: "2026-11-15"
```

**A4. NEW `boss_crack_route`** (kind: published_contract):

```yaml
  - name: boss_crack_route
    status: active
    source: design/gdd/grief-boss-framework.md
    referenced_by:
      - design/gdd/grief-boss-framework.md
      - design/gdd/health-damage.md
      - design/gdd/enemy-ai-telegraphs.md
    kind: published_contract
    attributes:
      floor_gate: "LIE_WHOLE: hp_floor 20 (the lie's armor — the death edge cannot fire while floor > 0, TR-HD-021/F-HD-05 verbatim); damage applies; the boss bar stalls at 1/3"
      crack: "3 unanswered ring sweeps (the whiff counter; a contact publication — application rejected or not — denies the whiff) fire the crack beat (CRACK_BEAT_MS 2000): the decisions suspend, the floor releases to 0, the halo breaks"
      cues: "crack_stage = clamp(whiff_count, 0, 3) — the derived view (the counter's, never the beat's); value-only hairlines; no HUD counter"
      knowledge_route: "IP-10's answer — the grind route walls at the floor; the route past the grind is behavioral (the reads), taught by the scuff + the cues + the stall"
      added: "2026-11-15"
```

**A5. NEW `boss_death_script`** (kind: published_contract):

```yaml
  - name: boss_death_script
    status: active
    source: design/gdd/grief-boss-framework.md
    referenced_by:
      - design/gdd/grief-boss-framework.md
      - design/gdd/juice-feedback.md
      - design/gdd/audio-core.md
      - design/gdd/cache-stations-death.md
      - design/gdd/camera-framing.md
    kind: published_contract
    attributes:
      flag: "death_scripted TRUE on the boss's HealthProfile — the defeat publishes once with the scripted flag; SYS-14 owns the transition"
      beats: "death_script_start -> the recognition beat (RECOGNITION_BEAT_MS 2500: the ring falls, the crack spreads, she looks — the fight's first and only acknowledgment) -> the dissolve (DISSOLVE_MS 1500) -> script_end -> the exit arc (ARENA_EXIT_MS 700, the swap at the arc's midpoint per F-RWS-03)"
      edge_discipline: "SYS-14 authors the beats and publishes the edge list — no VFX values, no audio dB (SYS-29/SYS-04 design against the edges)"
      award: "XP_BOSS 40 on the DefeatEvent (SYS-07's knob)"
      persistence: "no boss-defeated save family at MVP — the denial repeats on re-entry (the VS family is a batched SYS-02/SYS-03 revision request, OQ-GBF-4)"
      added: "2026-11-15"
```

**A6. NEW `boss_hp_pool`** (kind: constant):

```yaml
  - name: boss_hp_pool
    status: active
    source: design/gdd/health-damage.md
    referenced_by:
      - design/gdd/health-damage.md
      - design/gdd/grief-boss-framework.md
      - design/gdd/enemy-ai-telegraphs.md
    kind: constant
    value: 60
    range: "40-80 (SYS-07's BOSS_HP knob; <40: the boss is a room, >80: a slog)"
    notes: "SYS-07 owns the range (TR-HD-011); SYS-14 ratifies 60 at its authored default (the OQ-HD-10 answer, 2026-11-15). The systems-index SYS-14 bullet's stale '300 HP' is corrected to 60 by this sync (the pre-rework value)."
    added: "2026-11-15"
```

**A7. UPDATE `boss_kill_award`** — NEW constant (if the sync lane prefers one entry for both award facts, fold into A6's notes; otherwise):

```yaml
  - name: boss_kill_award
    status: active
    source: design/gdd/health-damage.md
    referenced_by:
      - design/gdd/health-damage.md
      - design/gdd/grief-boss-framework.md
    kind: constant
    value: 40
    range: "20-60 (SYS-07's XP_BOSS knob)"
    notes: "SYS-07 owns the range (TR-HD-007); SYS-14 ratifies 40. The award rides the DefeatEvent. The re-fight re-grant (no boss-defeated persistence at MVP) is OQ-GBF-9's economy rider at the QA-plan sync."
    added: "2026-11-15"
```

**A8. UPDATE `six_system_perf_envelope`** — append `design/gdd/grief-boss-framework.md` to `referenced_by`; append to `notes`: "SYS-14 explicitly does NOT join (the boss layer executes inside SYS-13's 0.25/0.75 allocation — the not-join and the re-open condition are printed in its GDD's TR-GBF-024: a layer share > 0.05 ms of SYS-13's budget fires the eighth-allocation request to the QA-plan sync; recorded 2026-11-15)."

**A9. UPDATE `enemy_strike_contract`** — append `design/gdd/grief-boss-framework.md` to `referenced_by` (the boss's strikes publish the schema; the denied-lean rider exercised).

**A10. UPDATE `system_offline_contract` and `designation_counter`** — append `design/gdd/grief-boss-framework.md` to each `referenced_by` (the mid-fight handshake: revive = the fight continues; reconstruct = the reset).

**A11. UPDATE `room_bounds_contract`** — append `design/gdd/grief-boss-framework.md` to `referenced_by` (RM-06's bounds/anchor/framing consumed; the drop seal authored inside the shipped rect).

**A12. BATCHED RIDER (the frozen-contract revision request — never applied by this lane):** SYS-15's GDD (`design/gdd/cache-stations-death.md`) — its "Explicit non-dependencies" line reads "SYS-12/14 (VS)" while SYS-14's GDD consumes the offline/revive contracts at MVP (the mid-fight handshake). The rider: the non-dependency list becomes "SYS-12 (VS); SYS-14 (the mid-fight handshake — the revive continues the fight mid-phase, the reconstruct resets it)" + the Interactions table gains a SYS-14 row. **This is a frozen-doc edit → the batched user-decision path** (recorded here; the CodeRabbit thread's disposition names it). Routed with the OQ-GBF-4 estate.

### B. `design/gdd/systems-index.md` — the row + the design order + the bullet + the 6 neighbor notes

**B1. The enumeration row's Dependencies cell (SYS-14):**
`SYS-13, SYS-08, SYS-32` → `SYS-13, SYS-08, SYS-32 + the consumed SYS-07 (the hooks), SYS-02 (the room data), SYS-09 (the presentation), SYS-15 (the handshake)`

**B2. The dependency-map bullet (SYS-14, § Core) — replace the existing bullet with:**

```markdown
- SYS-14 Grief-Boss Framework → depends on SYS-13, SYS-08, SYS-32 (one rig, five states, interaction rule per state; boss-arena camera locks) + the consumed SYS-07 (the hooks), SYS-02 (the room data), SYS-09 (the presentation), SYS-15 (the handshake). **GDD `design/gdd/grief-boss-framework.md` — APPROVED (2026-11-15, lane SYS-14):** one rig, five grief states on a shared skeleton (`BossRig` — the VS states land as data rows, V-GBF-01's singular law); **the Denial state authored at MVP** (the lie holds: hp_floor 20 — she cannot die while the lie is whole; cracked by 3 unanswered ring sweeps — the crack beat releases the floor via the `FloorReleaseRequest` SYS-07 executes; the boss bar's stall at 1/3 is the lie made legible); the four placeholders (Anger/Bargaining/Depression at VS — Depression's join-resolution is a batched SYS-07 rider; Acceptance at Alpha) with named gates and zero values; the roster on SYS-13's schemas (the ring sweep — the inherited denied lean, unclashable; the lifted ring — the counter's key, 21 ≥ 18; the clasped thrust — the lose cause; the ring jab — the punish, F-ENM-03's window re-derived; the ring return — the deflectable projectile with the despawn-at-band law and the ≥ 224 coverage bound); the arena contract (`arena_hold {zone_id, active}` idempotent room-entry keyed; the staging band x [3296, 3744] × y [65, 287] ratified — OQ-CAM-3; the drop seal authored geometry, never a mutation set — V-RWS-07; the scripted exit arc at the goodbye's tail, the swap at the arc's midpoint per F-RWS-03); the knowledge route (IP-10: the crack route past the grind — the scuff + the halo hairlines + the bar's stall; no new interactable, no tell — V-DR-01/AC-DR-14 honored); the death/defeat contract (the recognition beat — she looks; the dissolve; the exit; the three options verbatim — the revive continues the fight mid-phase, the reconstruct resets it; no boss-defeated save family at MVP — the denial repeats); the perf not-join (inside SYS-13's 0.25/0.75; the re-open condition at > 0.05 ms); 24 TR-GBF / 6 F-GBF / 11 V-GBF / 30 ACs (gate 24 + 2 + 4 + 0 = 30) / 9 OQs; **OQ-ENM-8 (SYS-13), OQ-HD-10 (SYS-07), OQ-CAM-3 + the OQ-RWS-8 riders (SYS-32), OQ-RWS-8's gate (SYS-02), IP-10 (the audit) all closed here**; the review record `design/gdd/reviews/sys14-grief-boss-framework-review-log.md`
```

**B3. The design-order row 14:** `14. SYS-14 Grief-Boss Framework` → `14. SYS-14 Grief-Boss Framework *(APPROVED)*`

**B4. The Progress Tracker's SYS-14 row:** status → **APPROVED (2026-11-15 — lane SYS-14):** the gate trail summary (CD CONCERNS → APPROVED; the seats 2+5+6 repaired; the spot-checks FAIL×3 → PASS; the micro-check PASS; the counts 24/6/11/30; the review record path); GDD path `design/gdd/grief-boss-framework.md`.

**B5. The neighbor notes (one line each, appended to the named rows' existing notes):**
- **SYS-13's row**: "**OQ-ENM-8 closed 2026-11-15** (SYS-14's GDD): the boss-facing extension authored — the archetype/strike/telegraph machinery consumed; the denied-lean rider exercised (the ring sweep); the boss's values are SYS-14's."
- **SYS-07's row**: "**OQ-HD-10 answered 2026-11-15** (SYS-14's GDD): the boss values authored (HP 60, the cap ∞, the phase floors {20, 0}, the immune kinds ∅, the scripted death); the floor release is the `FloorReleaseRequest` SYS-07 executes (the single-writer law)."
- **SYS-32's row**: "**OQ-CAM-3 ratified 2026-11-15** (SYS-14's GDD): the staging band x [3296, 3744] × y [65, 287]; the validator's live check scheduled at the arena story. **The OQ-RWS-8 riders accepted** (the intro mask ≥ 400; the magnitudes reviewed at playtest; the victory pricing — the glide killed by the exit swap)."
- **SYS-02's row**: "**OQ-RWS-8's gate recorded 2026-11-15** (SYS-14's GDD): the drop seal authored as geometry (never a mutation set — V-RWS-07); the VS persistence request (the boss-defeated family) batched to SYS-02/SYS-03."
- **SYS-09's row**: "**The pre-flip intent accepted 2026-11-15** (SYS-14's GDD): the early visitor fights the same fight; the post-flip punch is the denial repeating (the empty-basin payoff is the VS estate)."
- **SYS-15's row**: "**The mid-fight continuation ruled 2026-11-15** (SYS-14's GDD): a revive in the arena continues the fight mid-phase (the room-local survival); a reconstruct resets it."

### C. Diff summary

`design/registry/entities.yaml`: +6 entries, +1 constant (A7; optional fold), 4 referenced_by/note updates (A8–A11). `design/gdd/systems-index.md`: the SYS-14 row (the cell + the bullet + the order mark + the tracker row) + 6 one-line neighbor notes. No other file. The registry's count: 88 → 95 (or 94 if A7 folds into A6).

## CodeRabbit

## CodeRabbit

**One pass + one confirm pass — 10 threads, 10/10 resolved (required-conversation-resolution satisfied). The fix commits: 779ea03 (the 9-thread batch) + f18d3da (the confirm's CR-10).**

| # | Thread | Disposition |
|---|---|---|
| CR-1 (Minor, 93) | The coverage bound counted only the horizontal half-width — vertical separation and the re-center's range could leave a dead zone. | **APPLIED** — the bound restated in Euclidean form from the anchor (`ceil(√(224² + anchor_rise²))` — the printed datum 284 px; the arena-story fixture computes the exact value); the defaults re-derived (lifetime 1450 [900, 1500] → 200 × 1.45 = 290 ≥ 284); the displacement term recorded (the re-center restores toward the anchor; nothing at MVP displaces her; a VS displacement source re-derives the bound — the re-open note); the fixtures updated (TR-GBF-008, F-GBF-05, V-GBF-09, AC-GBF-07/17). |
| CR-2 (Minor, 109) | `CRACK_WHIFFS_REQUIRED` 2–4 broke the three-stage ladder (at 2 the break never appears; at 4 it appears early). | **APPLIED** — the knob pinned at 3 (the range 3–3): the stage ladder's three authored hairline states bind the count; a threshold change is an art-ladder re-author, not a tuning knob. |
| CR-3 (Major, 115) | The hold's room-entry keying (`active = room == RM-06`) contradicted the `script_end` fall. | **APPLIED** — the predicate is one condition with two terms: `active = (room == RM-06) ∧ (the fight not resolved)` — the resolved term falls the hold at `script_end` while the room term governs the entry; the ≤ 21 ticks of fresh-FOLLOW in the basin are named (the glide killed by the midpoint swap); the resolved-term fixture added (AC-GBF-16). |
| CR-4 (Minor, 226) | The formulas' structure vs the framework template's guideline (the variable tables, "Detailed Rules", the GWT playtest form). | **PARTIALLY APPLIED, PARTIALLY REBUTTED** — F-GBF-01's missing Variables line added (the valid half). The structural rename/rewrite REBUTTED with the house precedent: every APPROVED GDD in the corpus (SYS-13 `enemy-ai-telegraphs.md`, SYS-07 `health-damage.md`, SYS-32 `camera-framing.md`, SYS-15) uses this exact prose-formula format ("Core Rules", "If [condition] → [exact outcome]", the elicitor + coding-table playtest form) — the format IS the template's evolved house form, verified by the three-seat panel and the spot-checks; reformatting would diverge from every landed GDD. |
| CR-5 (Minor, 255) | The eleven-chain result lacked its precondition (the crack can fire at 60 HP — the floor releases at 60 and the flat 10 chains govern). | **APPLIED** — F-GBF-04 states the floored envelope's precondition (the crack at or below the floor) and the **early-crack case** (three whiffs at 60 HP → the floor releases at 60 → the flat 10 chains — the skilled route's shorter fight); AC-GBF-26 asserts both shapes. |
| CR-6 (Major, 455) | AC-GBF-01's "no damage field on any attack" would fail the projectile's required `damage: 2`. | **APPLIED** — the prohibition scoped to the strike side ("no damage field on any strike"; the projectile's damage is SYS-13's own schema data, TR-GBF-002's recorded scope); the knockback/i-frame/soul_class prohibitions unchanged. |
| CR-7 (Minor, 488) | B1's zero-tolerance tokens could pass under the general majority rule (one "buggy" transcript + three positives). | **APPLIED** — B1's zero-tolerance precedence authored: any breakage token in any eligible transcript fails B1 outright before the majority rule; the majority rule governs B2/B3/B4. |
| CR-8 (Minor, the lane prompt's 300 HP) | The rendered lane prompt still carries the stale 300-HP value. | **REBUTTED (recorded)** — the lane prompt is the manifest-pinned rendered launch contract (`a6ae5fbdfe32`); editing it mid-lane would invalidate the fail-closed precondition and the gate trail's provenance. The authoritative sources carry 60 (TR-GBF-006; the registry request A6; the index correction B1/B2). The master prompt source's correction routes to the **orchestrator's next render pass** (the next-action below). |
| CR-9 (Minor, the report's SYS-15 row) | SYS-15's GDD lists SYS-14 as a VS non-dependency while SYS-14 consumes the offline/revive contracts at MVP. | **ROUTED as a batched rider (recorded)** — SYS-15's GDD is frozen; the rider (the non-dependency list's correction + the Interactions row) is batched in the sync request's A12 for the user-approved path. The systems-index's SYS-15 note (B5) carries the ruling in the meantime. |
| CR-10 (Minor, 483 — the confirm pass on the fix batch) | AC-GBF-26's [46, 139] band on `duration_ticks` was unfalsifiable for player telemetry (a valid clean win can exceed it via the player-chosen repositioning). | **APPLIED in f18d3da** — the band's scope stated: the fixture scope (the scripted fight, the reposition fixed at 30 s) is the pass/fail bar; the telemetry scope is a non-gating tuning target (never a gate). Thread resolved. |
| CR-11 (Minor, the confirm pass's second round) | The [46, 139] band's lower bound assumed chain 6 — at the chain-10 extreme the fixture would compute ≈ 42.7 s and fail a valid configuration. | **APPLIED in 0c2fc80** — the fixture scope states its knob setting: the band runs the DEFAULTS' knob set (chain 6, the reposition fixed at 30 s); the extremes' recomputation is the arithmetic check, not the band's input. Thread resolved. |

## Landing receipt

Not merged (the merge stays with the orchestrator).

## Next action

1. The orchestrator queues this sync request; the sync lane applies it on a fresh `origin/Main` (the lock's discipline).
2. The CodeRabbit passes are done (11/11 threads resolved); the CI checks are green (5/5 on the final head); **mergeState CLEAN**.
3. The **required-review blocker** is the branch protection's reviewer rule (reviewDecision null; the threads are all resolved) — per the lane contract §5.4, if that is the only blocker at merge time, the admin merge is pre-authorized: bind the head with `--match-head-commit` (re-verify the head immediately before merging).
4. **The orchestrator's next render pass** corrects the master prompt source's stale 300-HP value (CR-8's disposition) at the next lane boundary — the authoritative sources already carry 60.
