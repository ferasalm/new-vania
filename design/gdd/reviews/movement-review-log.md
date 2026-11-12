# Review Log — Movement & Platforming (SYS-06)

> Falsifiability note: each entry records the verdict, blocking items, and scope signal at review time, so re-reviews can verify what was addressed.

## Review — 2026-11-12 — Verdict: NEEDS REVISION

Scope signal: **M** (targeted repair; no design re-open; two ADR notes: facing cadence, body phase)
Specialists: **game-designer** (real) · **systems-designer** (stand-in, disclosed) · **qa-lead** (stand-in, disclosed) · **gameplay-programmer** (stand-in, disclosed). Review lead: independent synthesis. The authoring session was not the reviewer; all four seats read `design/gdd/movement.md` against ADR-0001, SYS-01, the concept and the prototype.
Blocking items: **16** | Recommended: **12** | Notes: 4
Summary: The doctrine and structure held — the stride ruler, drop-when-busy, the hop's facing, the crouch stance, the 1200 ms body-busy contract and the ADR-0001 ownership boundaries are the right bones. The failures are **arithmetic, contract-edge and AC-layer**: a core air formula contradicted its own no-friction law; `body_busy` omitted KNOCKBACK and the declared 1200 ms arc was under-covered by legal knob values; `grounded` ownership was reversed against ADR-0001; continuous-time arc numbers were asserted as tick-exact; the facing schema could not express a no-value-change HOP cause and re-asserted on the wrong clock; a slow back flick turned before the arming zone; the crouch handoff left the hurtbox authority undefined; the state table ended locks at walls; the hit-stop invariant had an idle-body gap; joint-extreme ranges and units were wrong; the AC layer had arithmetic, coverage and falsifiability defects. No seat proposed a redesign.

### Blocking items at review time (for the re-review to verify)

1. **B1 — Air formula contradicted its own no-friction law** [systems-designer]. At neutral, `air_target = 0` made the guard false and the fallback decelerated at `AIR_ACCEL`; releasing the stick stopped a walk jump in ~209 ms. Fixed: `air_target = 0` preserves `v_x`.
2. **B2 — `body_busy` omitted KNOCKBACK; 1200 vs legal 1600 ms; SCRIPTED unbounded; knockdown path ambiguous** [systems-designer, qa-lead, gameplay-programmer]. Fixed: KNOCKBACK added to the lock set; a knockdown hit enters KNOCKDOWN on the hit tick (no KNOCKBACK phase); `worst_case_arc_ms` is the derived max (1200 at defaults); V-MOV-15/17 bound every lock; `SCRIPTED_MAX_MS` added; `freeze_hold` added.
3. **B3 — `grounded` ownership reversed** [systems-designer]. Fixed: Movement publishes `grounded`; SYS-01 consumes it; dependency and interactions tables aligned; AC-MOV-34 injects orders, not the stick.
4. **B4 — Continuous-time arcs vs tick integration; F-MOV-10 had no distance/decay** [systems-designer, gameplay-programmer]. Fixed: TR-MOV-032 integrator law (semi-implicit Euler); discrete 60-tps fixtures (70.4 px apex, 41–42 ticks, 98 px hop, 84 px dash, ≈82.3 px wall jump); `KNOCKBACK_DECEL` + `d_kb`; `lock_ms`/`lock_ticks` naming.
5. **B5 — Facing schema** [systems-designer, gameplay-programmer]. Fixed: re-assert every `physics_tick`; value/epoch on `logic_tick`; `asserted_tick`; cause re-assertion with unchanged epoch; initial epoch 0; hop-exit turn suppressed for the full lock; KNOCKBACK value rule; OQ-M2 records the ADR §10 cadence erratum.
6. **B6 — Slow back flick turned before the arming zone** [systems-designer]. Fixed as a recorded cross-contract item: OQ-M1 requires SYS-01's press1 to be the first back-direction **creep** entry; AC-MOV-42 is the xfail trace until the amendment lands.
7. **B7 — Crouch handoff** [game-designer, systems-designer, gameplay-programmer]. Fixed: posture applies at the first **grounded** body-free tick; **posture-carry** for a commitment pulled while raw crouch is true; `crouch_effective` published for Combat's hurtbox/overlap; `posture_pending` cue; air crouch queued to grounded; no-headroom hop/dash is a Movement-side `move_refused`; commitment-entry stands exempt from the body-free law.
8. **B8 — State table ended DASH/KNOCKBACK at a wall; law 2 vs the knockback chain; DROP_THROUGH missing** [systems-designer]. Fixed: wall removed from the exit columns; law 2 reworded (no interruption; the KNOCKBACK→KNOCKDOWN→GETUP chain is one arc); DROP_THROUGH row added.
9. **B9 — Hit-stop invariant gap for non-Combat freezes** [systems-designer]. Fixed: `freeze_hold` zero-motion lock for any `logic_running == false` interval with no other lock.
10. **B10 — Ranges/examples/units** [systems-designer, game-designer]. Fixed: range convention ("at defaults"); joint-extreme values stated where material; crouch example 30 px; high-attack band `(26.4, 44] px`; `t_stop` ms units; `deg_to_rad`; horizontal `v_x` bound; gap 9 tiles inside / 10 past; hybrid cut stated as r² (0.5 quarters, √0.5 halves).
11. **B11 — Knob/ledger hygiene** [systems-designer]. Fixed: SYS-08 values moved to a "cross-system inputs" block with validation; derived `worst_case_arc_ms`; V-MOV-16/17 added; F-MOV-02 branch order (committed first); rule cells corrected; duplicate symbols aliased; `WALL_JUMP_REARM_MS`, `KNOCKBACK_DECEL`, `SCRIPTED_MAX_MS` added.
12. **B12 — AC layer** [qa-lead]. Fixed: AC-MOV-01 split into three clause-units; AC-05 r²; AC-22 knockdown path + `d_kb`; AC-30 split GUT static + DEVICE benchmark (W11, QA plan §5.1); AC-32 split body-free/busy + DEVICE; AC-14 consumes a 1-tick true; AC-13 read-phase tick; AC-19 dev trace not publication; AC-20 static no-i-frame-field; AC-23 level semantics; AC-31 mock-record; AC-34 order injection; AC-35/36 Q5–Q10, N=5×30, two facilitators/kappa; AC-37…49 added for the traceability holes.
13. **B13 — Dash had no direction and no distinct job** [game-designer, gameplay-programmer]. Fixed: direction = published facing at pull (same-tick turn first; neutral uses facing); **dash-jump** preserves dash horizontal velocity; AC-MOV-45.
14. **B14 — Knockdown could chain** [game-designer]. Fixed: no re-knockdown during KNOCKDOWN/GETUP; damage applies, no new lock; Combat may grant getup i-frames; AC-MOV-46.
15. **B15 — One-way drop armed by an air-held crouch** [game-designer]. Fixed: the drop is armed only by a crouch whose engage edge occurred while grounded; air-held landing jumps normally; the drop does not change posture; AC-MOV-46.
16. **B16 — No body phase in the ADR pipeline; pure-core seam; Godot slope/wall classification** [gameplay-programmer]. Fixed: TR-MOV-034 body phase (hop pulled at T moves at T); `MotionCore` + `BodyPort` split; floor-normal classification; the Movement ADR brief (OQ#1) carries the CharacterBody2D settings, one-way layer scheme and body-phase placement.

### Recommended items (recorded, not all applied)

R1 `AIR_ACCEL` reversal in ~0.37 s — playtest the air-commitment feel. R2 crouch-pending visibility (now `posture_pending`, AC-MOV-43 + OQ-M3). R3 dash-jump gap budget (OQ-M4). R4 the `posture_pending` HUD cue (OQ-M3). R5 the single-wall re-arm at 150–400 ms — playtest. R6 the `SCRIPTED` gate-vs-lock choice. R7 the knockback decay curve. R8 the AC-MOV-35/36 cohort size. R9 the high-attack band with SYS-13. R10 the `freeze_hold` publication cadence. R11 the `BodyPort` fake's fidelity. R12 the `TURN_MIN_ORDER` coupling to `CREEP_RATIO`.

### Revision applied in-session

All 16 blockers were revised in `design/gdd/movement.md` on 2026-11-12. The GDD is **In Review** (not Approved); a **diff-scoped re-review** is the next gate. Counts after revision: **34 TR-MOV rules** (31 + TR-MOV-032/033/034), **14 formulas**, **36 knobs + 5 cross-system inputs**, **49 ACs** (36 original + AC-MOV-37…49), **14 open questions** (10 original + OQ-M1…M4).

### Sequencing after this review

**Diff-scoped re-review in a fresh session** (the changed sections + the arithmetic/AC fixtures; qa-lead spot-check mandatory) → then the SYS-08 Combat GDD, which must consume the fixed contracts: `KnockbackOrder {dir, power}`, `crouch_effective` + posture-carry, the derived `worst_case_arc_ms` (1200), the `move_refused` edge, and the `freeze_hold` invariant. The SYS-01 press1-creep amendment (OQ-M1) is a one-clause SYS-01 edit before the first SYS-06 implementation story; it does not re-open the SYS-01 review loop.

### Process notes

- The OpenCode shell tool is broken machine-wide; the review and landing ran through the documented throwaway Godot OS.execute bridge (untracked; in no commit). The bridge's output capture was fixed this session: `OS.execute`'s output parameter must be an untyped `Array`, not a `PackedStringArray`.
- The four review seats ran as fresh-context subagents; the `systems-designer`, `qa-lead` and `gameplay-programmer` seats are disclosed stand-ins (the OCGS agent types are not registered as subagents in this harness). The `game-designer` seat is real.

## Re-review — 2026-11-12 — Verdict: APPROVED (diff-scoped)

Scope signal: **S** (diff-scoped verification of the revision; no design re-open).
Seats: technical seat + qa-lead spot-check (single-session synthesis; the four-seat panel was the original review). Method: the 16 blockers verified one by one against the changed text; arithmetic re-check at 30/60/120; AC traceability census; a 15-site qa-lead spot-check (claim → target → verdict).

**Result: 16/16 blockers PASS.** The doctrine and the repaired text survived verification; no seat found a new blocker.

**Arithmetic fixtures reproduce.** Jump apex **70.4 px**, air time **41–42 ticks**, reach **157–161 px**; hop **98 px** (14 × 7), **17-tick lock** (283.3 ms), **9-tick i-frames** (150 ms), **8-tick exposure**; dash **84 px** (12 × 7); wall jump **≈82.3 px** horizontal (continuous 83.2 px); knockback **16.9 px** @ power 1 / **67.6 px** @ power 2; crouch top **17.6 px**; derived max **1200 ms**; V-MOV-16 corner **280 ÷ 1200 × 1000 = 233.3 ≤ 250**; F-01 rate table 140 ms → 5@30 / 9@60 / 17@120.

**AC traceability.** 34 TR-MOV rules · 14 formulas · 49 ACs; every TR and formula has an AC or a recorded guidance note (TR-MOV-034 → OQ#1; TR-MOV-033 exercised by AC-MOV-13); zero duplicate IDs; zero `[To be designed]`.

**qa-lead spot-check — 15 sites: 12 PASS, 2 PASS-with-note, 1 note.**

- **R1 (recommended, non-blocking) — AC-MOV-05 hybrid-cut values are continuous-derived.** The 60-tps semi-implicit fixture is **≈16.7 px** at `r = 0.5` and **≈34.5 px** at `r = √0.5`; the AC asserts 18.5 ± 1 / 37.0 ± 1. `JUMP_CUT_RATIO = 1.0` fixed at MVP, so the MVP path is unaffected. Fix before the hybrid knob ships: label the values continuous (design intent) or add the discrete fixtures.
- **R2 (note) — AC-MOV-11's "64 px vertically" is the continuous apex;** the 60-tps fixture is **≈60.7 px**. Label it with the same continuous/discrete convention.
- **N1 (note) — traceability bookkeeping:** TR-MOV-034 has no dedicated AC; OQ#1 carries the ADR brief. TR-MOV-033 is exercised by AC-MOV-13 but not cited by ID.

**Verdict: APPROVED.** The GDD is Approved; the review loop is closed. R1/R2/N1 are one-clause bookkeeping items for the Movement ADR authoring — not re-open triggers, not blockers.

### Process notes (re-review)

- The re-review ran in the same session as the SYS-08 Combat authoring kickoff. The OpenCode shell remains broken machine-wide; git/gh ran through the documented throwaway Godot OS.execute bridge (untracked; in no commit).
- The creative seat for SYS-08 ran as a GLM-5.3-Flash subagent (`game-designer`) with excerpts only; it returned a memo and wrote no files.

### Post-approval CodeRabbit findings (PR #22) — resolved

- **CR-1 — posture-carry vs commitment-entry stands.** The finding was valid: TR-MOV-016's posture-carry was unscoped and could be read as applying to a crouch-held dash/jump/hop, contradicting the commitment-entry stand. Fixed as a one-clause scoping edit: **posture-carry applies to attack commitments only**; dash, jump and hop use the commitment-entry stand (they stand her up). The Combat GDD's TR-CMB-006 was aligned in the same pass. No design re-open; the re-review verdict stands.
- **CR-2 — body-free tick vs lock interval.** TR-MOV-033/AC-MOV-13 now use the lock's `end_tick` (the level is true through `end_tick−1`) as the tick-open body-free boundary; a lock whose last busy tick is T applies at T+1.
- **CR-3 — dash-jump vs transition law 2 / DASH row.** Transition law 2 gained the dash-jump exception; the DASH row gained the jump exit; TR-MOV-019 states the dash `body_busy` lock ends at the jump tick.
- **CR-4 — mid-rise jump cut.** TR-MOV-011 now states the cut scales the **remaining** velocity; a mid-rise cut follows `h_total = h_gained + (v_remaining × r)² ÷ (2 × GRAVITY)`; only a jump-tick cut scales the total apex by r².
- **CR-5 — wall-normal direction.** The `BodyPort` contract now defines `wall_normal` as pointing **away from the wall** (Godot's `get_wall_normal()` convention); F-MOV-08 uses `+wall_normal_x`.
- **CR-6 — entity registry.** `STAND_HEIGHT`, `CROUCH_HURTBOX_RATIO`, `KNOCKDOWN_POWER`, `BACKDASH_IFRAME_MS`, the two `worst_case_arc_ms` declarations and `ATTACK_WINDOW_MS` are registered in `design/registry/entities.yaml` under their owning systems; the GDDs reference the registry facts.
- **CR-7 — AC-MOV-05 discrete values.** The AC now asserts the 60-tps semi-implicit apexes **16.7 px ± 1** (r = 0.5) and **34.5 px ± 1** (r = √0.5), with the continuous intents 18.5/37.0 px labelled.
- **CR-8 — AC-MOV-14 one-tick crouch.** The AC now distinguishes a one-tick value that flips back before application (no change) from a one-tick value on a grounded body-free tick (applies); the 90 ms guard is the cone-entry path's, bypassed by keyboard/latch.
- **CR-9 — systems-index consistency.** The SYS-06 enumeration row now lists SYS-01, SYS-02, SYS-16 and SYS-05; the SYS-24 row now includes SYS-32.
- **CR-10 — AC-MOV-11 vertical (new).** The vertical wall-jump height is **≈60.7 px ± 1** at 60 tps (continuous 64 px), matching the horizontal convention.
- **CR-11 — SYS-06 facing cadence (new).** The SYS-06 entry states the facing cadence follows R3/§8 (re-asserted every `physics_tick`) and records the §10 erratum as pending under OQ-M2.
