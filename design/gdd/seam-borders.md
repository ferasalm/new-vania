# Seam Borders

> **Status**: APPROVED (2026-11-14 — the review loop's trail below)
> **Author**: game-designer + technical-artist (agent-authored, user-directed)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14
> **Implements Pillar**: "One World, Two Truths" (the seam is the third thing that proves the two truths are constructed) · "Five Goodbyes" (M4's grief tint is the one admitted color) · "SotN, Not Hollow Knight" (material texture over twitch)
> **Contracts**: SYS-02 `design/gdd/room-world-structure.md` (APPROVED 2026-11-13) — the seam placement data (the zone-gate partition's material sides, the Cold Corridor wing `Rect2(1312,176,160,96)`, the `reveal_cistern` framing zone) consumed verbatim · SYS-09 `design/gdd/dual-reality-state.md` (landed 2026-11-14) — the `PROV_LIM_*` ramp as the shared source of truth and TR-DR-012's sharpened purple admission test consumed verbatim · SYS-10 `design/gdd/world-mutation-epochs.md` (APPROVED 2026-11-14) — the epoch store, the `REVEAL_CISTERN` allocation, and the tell-free wing/M4 deltas · SYS-32 `design/gdd/camera-framing.md` (APPROVED 2026-11-14) — the 9-field publication and the reveal hold, read-only (SYS-11 issues zero camera commands and does not act on `active_hold`)
> **Creative Director Review (CD-GDD-ALIGN)**: CONCERNS (2026-11-14) → REVISED in-session (R1/R2 + the two advisories applied)
> **Review trail**: CD-GDD-ALIGN CONCERNS → REVISED · three-seat fresh-seat review (creative / technical / QA) → NEEDS REVISION (3 + 8 + 8 blockers) → all valid blockers repaired in-session · qa-lead spot-check #1 FAIL (3 blockers) → repaired · spot-check #2 FAIL (2 blockers + 3 notes) → repaired · final micro-check **PASS** (no findings). Counts: 12 TR-SMB / 7 F-SMB / 7 V-SMB / 32 ACs (25 smoke = 19 GUT + 6 LINT · 3 device · 4 playtest) / 4 playtest codes / 7 OQs.

## Overview

Seam Borders owns the material language of the one place in the MVP that belongs to neither truth: the Cold Corridor's border set in RM-03. It is a derived, read-only presentation system. It consumes SYS-02's placement data (the zone-gate partition row and the wing rect), SYS-09's `PROV_LIM_*` liminal ramp, SYS-10's epoch store, and SYS-32's hold publication as context only; it publishes the `seam_border_contract` — the seam segments, the 1-tile frame's ramp-step assignment, the optional purple depth tint and its admission test, and the visibility predicate. SYS-09's renderer applies the recipe; SYS-11 never draws, never prompts, never emits VFX or audio, never commands the camera, and never writes the epoch, tile data, or save. At epoch 0 the seam is the sealed partition and the wing renders the hall's A-wall — no grey, no tell. From E4 onward the threshold band and the wing's north/west/east frame render the liminal ramp, epoch-invariant; the interior fill remains SYS-09's. The pure grey ramp is the shipped default; the purple bridge is a gated proposal that must pass TR-DR-012's sharpened admission test and the art bible's liminal-grey reservation, with an automatic fallback. The player experiences the seam as the one honest place between the two truths: the corridor the flip never touched, the held frame where the world stops arguing, and the fourth memory at its end.

## Player Fantasy

**The Honest Joint.** *I went back to where the world had changed its mind — and found the one place where it never did.*

The fantasy begins before the corridor. The player reads the Sanctum log; the flip lands; the world is amber. Nothing tells them to return. They remember the sealed strip in the Cistern — SYS-25's unexplored-doorway tick, not a seam mark — so they walk back to RM-03 on their own deduction, SotN-style. The partition row is now a band of the same grey as the corridor beyond it. They step on it. Nothing announces anything: no prompt, no sound, no glint. The camera holds. The corridor is simply there — ten tiles of grey that belong to neither the machine's word nor the candle's, its material steady while the world on either side has just finished swapping colors. At the far end, the fourth memory waits, its grief tint the one warm thing the grey admits; the HUD still says 3/4. The corridor is the fixed point that makes every later two-truth crossing legible: the place where the two lies were sewn together, and the seam held.

What the player should feel: the quiet vertigo of standing on the canvas under both paintings; the recognition that the corridor is older than the argument between the truths; the small, private pride of having found it without being told. Not wonder, not horror — **the honesty of a place that never pretended to be either world.**

What the system must never do: point at itself. No prompt, no VFX, no audio, no tell, no HUD mark, no camera order, no color that reads as a fifth palette. The seam's only semantics are material: the grey ramp, the frame's edge, and M4's one admitted hue. If the corridor reads as a door, a portal, a loading screen, or an unfinished room, the fantasy has failed — the material continuity (the band is the same ramp as the fill, no distinct edge) is the mitigation, and the held frame is the invitation.

Pillar ties: "One World, Two Truths" — the seam is the third thing that proves the two are constructed; "Five Goodbyes" — M4's grief tint is the player's truth in a place that belongs to the world's; "SotN, Not Hollow Knight" — the unprompted backtrack is the deliberation pillar, and the reward is a place, not a power.

The creative seat's note (GLM-5.3-Flash): the proposed purple tint helps none of these framings; a distinct color on a former gate line is door/trigger grammar — and the admitted form already forbids the band/north row (TR-SMB-005/P3), so the argument binds the placement the design has closed. The pure-grey default is the fantasy-correct preference on record; the frame-tint judgment — does a sub-perceptual, static, neither-truth hue on the frame columns serve the liminal material language, or does the joint's honesty require the absence of color? — is deferred to OQ-1 unprejudiced.

## Detailed Design

### Core Rules

**Rule IDs (`TR-SMB-*`) are stable requirement proposals — each carries a falsifiable test.** No Input reads; no collision writes; no prompt/VFX/audio/HUD; no camera commands; no epoch/tile/save writes; no tell entries.

- **TR-SMB-001 — The seam contract (data, boot-validated, zero collision).** SYS-11 publishes `SeamBorderContract` as a versioned data resource: `{schema_version, wing_zone_id, wing_rect_tiles, threshold{rect, step}, frame{north{rect, step}, west{rect, step_by_row[]}, east{rect, step_by_row[]}}, depth_field{origin_row, span_intervals}, fixtures[], visible_at_epoch_gte (derived), tint: null | {kind, tint_by_step[4], alpha_by_row[], mask_cells, admission_record{ramp_hash, grief_hash, placement_hash, constants_hash}}}`. `visible_at_epoch_gte` is **derived at boot** (F-SMB-03) and written into the contract; a hand-authored value must equal the derivation, mismatch → boot failure. **Zero collision fields** (shape/layer/mask/one-way/`set_collision_*`). The band's collision is SYS-02's `gate_open(rm03_partition, epoch)` only; the seam adds and removes nothing. *Test: collision probe at both epochs identical with the contract present vs. deleted; static audit finds zero collision symbols in seam code.*
- **TR-SMB-002 — The placement consumption (band + frame; non-overlapping rects).** Derived by F-RWS-01 from SYS-02's tile-space fields: `threshold.rect_px = Rect2(room_origin_px + partition_rect.position × TILE_PX, partition_rect.size × TILE_PX)` → `Rect2(1312,160,160,16)`; the wing's px rect `Rect2(1312,176,160,96)` (SYS-02's printed form). The frame's non-overlapping rects: N `(1312,176,160,16)` · W `(1312,192,16,80)` · E `(1456,192,16,80)`; the fill `(1328,192,128,80)` stays SYS-09's. The band **clips to `opening_rect`** if the opening is narrower — only after the alignment/subset guards pass; never quantize. The still-solid remainder renders the hall's material — never liminal over a sealed cell. All rects grid-aligned. *Test: the placement fixture; the clip fixture; the grid/overlap audit; the malformed-opening negatives (non-tile-aligned, not a subset, zero-area while open) → boot failure naming `rm03_partition`.*
- **TR-SMB-003 — The visibility law (per-segment effect binding; derived, never stored).** The band keys on `GATE_OPEN(rm03_partition)`; the frame keys on `ZONE_MATERIALIZE(cold_corridor)` — bind by **effect**, not the literal epoch. At MVP both ⟺ epoch ≥ 1; the boot check asserts `gate_open ⟺ zone_materialized` for `REVEAL_CISTERN`, and a synthetic desync fails the boot. `visible_at_epoch_gte` is **derived at boot** as `min{e : both predicates true}`; null (never true) → boot failure. No stored seam state, no `reveal_happened`. *Test: the desync negative; the epoch-0/epoch-1 fixtures.*
- **TR-SMB-004 — The depth field and the step map (a sampling rule, not a new material_rule).** `d = clamp((row_y − 11) ÷ 5, 0, 1)`; `fill_step(d) = 1 + clamp(floor(d × 3), 0, 2)` over the index order `0=DEEP, 1=MID, 2=PALE, 3=LIGHT`; `frame_step(d) = clamp(fill_step(d) + SEAM_SIDE_OFFSET, 0, 3)`. The north row = **MID**; the band = **MID**; the fill is SYS-09's (its row sampling is a proposed SYS-09 rider, OQ-7; SYS-11 does not assert it). The contract carries **step indices 0..3, never hexes**. No new `material_rule`, no SYS-02 sub-zone split. `origin_row` and `span_intervals` are contract operands, not literals — the MVP's 11/5 is a fixture; `len(step_by_row) == span_intervals` (the W/E rows 12–16 = 5), `len(alpha_by_row) == span_intervals`; the north pin is `frame.north.step` (separate); the validator recomputes the row table for the room's domain. *Test: the printed row table reproduces exactly; step indices in range; no hex literal in the contract; the room-reuse span/array-length negative.*
- **TR-SMB-005 — The purple admission (gated proposal; frame-only; static; fail-closed).** The wing's fixtures are `[]` at MVP; the contract carries the field explicitly. The proposal is named the purple bridge; its admitted form is a **static depth tint on the wing frame's west/east columns** — never the threshold band (outside the wing; TR-DR-012's absolute bound), never the north row, never the fill, never fixtures, never M4. `tint` is **null** (the grey default) unless the P1–P5 admission predicate (F-SMB-05, with F-SMB-06's alpha quantization and F-SMB-07's feasibility diagnostic) passes **and** the art bible ratifies the liminal-grey reservation. A present-but-unratified tint is a boot failure, never a silent fallback. The admission record carries content hashes of the ramp, grief tint, placement mask, and P1–P5 constants (F-SMB-04); a mismatch is a boot failure. P3 rejects an all-zero alpha array (`max ≥ 1/255`). Static: no time uniform, no animated dither, epoch-invariant. *Test: the P1–P5 pass/fail fixtures; the static audit; the fallback fixture; the stale-record negative.*
- **TR-SMB-006 — The no-pointing law (no tell, no prompt, no VFX, no audio, no HUD, no camera).** SYS-11 publishes **zero tell entries** — the seam is not a `novelty_ref`, not a tell anchor, not a `STATE_DELTA`. The seam step map composites **before** SYS-09's tell pass, so RM-03's conduit tell renders on top. The seam's composite is a material resolve, not a tell entry: the records are bit-identical with the tell pass enabled, disabled, or zero-entry. Pre-arm hold detection is SYS-32's TR-CAM-013 dev assert (SYS-02's TR-RWS-009 precondition); SYS-11 renders the epoch's truth and reads no hold. The band's epoch-0 record is **absent** (zero seam keys); at epoch ≥1 the band is the tell's payoff surface, with no unique hue, edge, or pulse. Zero prompts/VFX/audio/HUD; zero camera commands; hold-blind. *Test: the tell-registry membership count; the band epoch-0 absence; the render-order fixture; the static audits.*
- **TR-SMB-007 — The render application seam (SYS-09 applies; no new port; preloaded).** SYS-09's renderer consumes the contract at its existing resolve points (room entry, τ0). **No `SeamPort`, no new `RealityCore` surface.** The contract is preloaded at boot; the flip does no load/parse/validate; the band and frame are in the re-material set; the step indices resolve through **one ramp-table fetch per resolved zone** (the four members come from that single counter-visible lookup), preserving AC-DR-01's counter; the fixture asserts the counter delta equals SYS-09's resolve count. A missing/malformed step map is a dev assert + telemetry, not a silent fill fallback. *Test: the resolve-counter fixture; the preload fixture; the malformed-step negative.*
- **TR-SMB-008 — The purity seam and the port list.** The boot validator is a pure function over injected data: `TruthPort` (epoch + the two effect predicates), `RoomDataPort` (partition/opening, wing rect, framing rect, M4 anchor), outbound `SeamContractPort`. No `RenderPort`, no `CameraPort`, no `Input`/`SceneTree`/`Time`/`RenderingServer`. Missing/invalid placement → boot failure **naming the segment**. *Test: the purity audit; the missing-input negatives.*
- **TR-SMB-009 — The persistence abstention.** No seam save field; the seam re-derives from the epoch; M4 taken-ness is orthogonal (`memories_collected`); the post-M4 record equals pre-M4 except M4's grief tint; no `reveal_happened`; an epoch-1 restore's first frame is materialized with zero intermediate A/grey frames. An epoch-0 restore mirrors it: the first frame renders the save's epoch (band absent, wing A-wall); a same-room load that skips the re-resolve is a dev assert + telemetry. *Test: the save round-trip; the post-M4 fixture; the epoch-0 load mirror.*
- **TR-SMB-010 — The performance ruling (not-join; boot/event budgets).** SYS-11 does **not** join the seven-system gameplay-tick envelope (the SYS-02/09/10 precedent): no per-tick loop; boot load + validation ≤ 1 ms; epoch-change incremental ≤ 0.1 ms inside SYS-09's 100 ms `REMATERIALIZE_BUDGET_MS`; steady state 0 ms / 0 lookups; the admission test is CI-only. **These are wall-clock dev asserts; F-01's ms→tick ceil does not apply.** The boot assert covers contract parse + validation + step-map derivation only, not the CI admission test; the 0.1 ms assert uses the nearest-rank estimator with n ≥ 1,000 (SYS-01 QA §5.3). Re-open condition: a combined soak that attributes an unallocated per-tick delta to SYS-11. *Test: the boot/incremental dev asserts; the zero-lookup fixture.*
- **TR-SMB-011 — The not-do list.** No collision; no prompt; no VFX; no audio; no tell; no HUD; no camera; no fade/wipe/dissolve; no animation; no fifth palette; no seam interactable; no `reveal_happened`; no save field; no hex literals; no new `material_rule`; no SYS-02 zone split. *Test: the static audits.*
- **TR-SMB-012 — Degenerate reads, named and shut down.** *Door/trigger:* no distinct edge, adjacent-step delta ≤ 1, no animation. *Fifth palette:* tint only on the frame columns, never the band/north/fill/fixtures/M4; the chroma cap; desaturate/saturate tests. *Loading screen/unfinished room:* authored coursing, sourceless pale light, no flat fill; SYS-09's F3 anti-code fails the build on "buggy / didn't load / looks broken." *Fetch-flag backtrack:* the seam never closes, re-seals, or reacts to M4; it reads no `memories_collected`. *Hidden-passage probe:* zero interactables, no interaction volume, no breakable. *Test: the per-strategy fixtures/audits.*

### States and Transitions

The seam has **no runtime FSM and stores nothing** — the states are a per-segment render derivation from the epoch + the contract's config-load `tint` field.

| State | Band | Wing frame | Wing fill | Entry | Exit |
|---|---|---|---|---|---|
| **SEALED** | hall's A-wall | hall's A-wall | hall's A-wall | epoch < 1 | epoch ≥ 1 at τ0/E4 |
| **MATERIALIZED (tint NONE)** | MID | north MID; W/E `step_by_row` | SYS-09's ramp | epoch ≥ 1 | none — epoch-invariant |
| **MATERIALIZED (tint ADMITTED)** | MID | north MID; W/E `step_by_row` + static depth tint | SYS-09's ramp | epoch ≥ 1 + `PURPLE_ENABLED` + admission record + art-bible ratification | none — epoch-invariant |

Named edges: the τ0 transaction (SYS-09 E3/E4) → the next render is materialized; an epoch-1 load → the first frame is materialized, zero intermediate A/grey frames; death/respawn → epoch read, zero seam events; M4 taken → no seam change; a VS second flip → the seam persists (epoch-invariant). No reverse transition exists.

### Interactions with Other Systems

| Boundary | Flow | Contract / missing-input path |
|---|---|---|
| **SYS-02** (hard, read-only) | In: band/wing/opening/framing/M4-anchor placement; Out: nothing | Missing/malformed placement → SYS-02's boot fails first; SYS-11's validator fails naming the segment |
| **SYS-09** (hard, shared source) | In: `PROV_LIM_*` ramp + the render application; Out: the step map + tint contract | Missing palette member → boot failure; absent/malformed step map → dev assert + telemetry; no new port |
| **SYS-10** (hard, indirect) | In: epoch + the `GATE_OPEN`/`ZONE_MATERIALIZE` predicates; Out: nothing | Missing epoch → SYS-10/SYS-02's failure path; no seam state |
| **SYS-32** (soft, acceptance fixture only) | In: nothing — **no CameraPort, no `active_hold` read**; Out: nothing | Missing `active_hold` → no effect; the hold-blind fixture asserts zero seam deltas across the reveal hold |
| **SYS-03 / SYS-04 / SYS-01 / SYS-24 / SYS-29 / SYS-14 / SYS-28 / SYS-25** | No interface | No save, audio, input, HUD, VFX, arena, text, or map surface |

### Validation Invariants

- **V-SMB-01** — zero collision/prompt/VFX/audio/HUD/camera symbols in seam code; the contract has zero collision fields.
- **V-SMB-02** — the contract rects are grid-aligned, non-overlapping, inside the seam region; step indices ∈ 0..3; no hex literals.
- **V-SMB-03** — epoch 0: the band + wing keys are the hall's A-wall; zero `PROV_LIM_*`; zero seam keys; the band's epoch-0 record absent.
- **V-SMB-04** — zero seam tell entries; RM-03's tell count = SYS-09's authored allocation; seam-before-tell render order; no unique hue/edge/pulse on the band or north row at epoch ≥1; the admitted frame tint (VR-SMB-08) is the sole bounded exception.
- **V-SMB-05** — the contract is preloaded; zero per-tick seam lookups; the band + frame are in the re-material set; boot ≤ 1 ms; incremental ≤ 0.1 ms.
- **V-SMB-06** — the tint, if present, passes P1–P5; static; epoch-invariant; frame west/east only; alpha 0 at the band/north row/fill; no fixtures/M4.
- **V-SMB-07** — no save field; the seam re-derives from the epoch; M4 taken-ness orthogonal; post-M4 record = pre-M4 except M4's tint.

## Formulas

Three law families govern SYS-11's math: **the sampling law** (the depth field derives the frame's steps from one operand), **the derivation law** (visibility and band presence are pure functions of the epoch + placement), and **the admission law** (the purple is a fail-closed predicate over the palette data, never a runtime choice). No formula converts ms→ticks: SYS-11 has no gameplay timing of its own; the only ms figures are wall-clock dev asserts.

### Formula ledger — law vs knob

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-SMB-01 | depth_field + step_map | True law | `TILE_PX` 16; the `PROV_LIM_*` index order; the two authored pins |
| F-SMB-02 | band_rect + band_cells | True law | SYS-02's tile-space `partition_rect` + `opening_rect`; `TILE_PX` 16; RM-03's origin (1280,0) |
| F-SMB-03 | visible(seg, e) | True law | SYS-10's `gate_open` / `zone_materialize` predicates; `max_epoch` |
| F-SMB-04 | accept(contract) | Guard law | `SEAM_SCHEMA_VERSION`; `ADMISSION_VERSION`; the palette revisions |
| F-SMB-05 | admit(tint) | Guard law | P1–P5 constants + the fail-closed guards |
| F-SMB-06 | tint_alpha | Presentation law | `ADM_ALPHA_MAX`; the mask; the per-step colors |
| F-SMB-07 | feasible_hue_interval | Diagnostic law | the A/B hue sets; `ADM_HUE_SEP_DEG`; `ADM_HUE_BAND` |

#### F-SMB-01 · depth_field + step_map — the sampling rule (TR-SMB-004)

The `depth_field` formula is defined as:

`d(row_y) = clamp((row_y − origin_row) ÷ float(span_intervals), 0.0, 1.0)`
`fill_step(d) = 1 + clamp(floor(d × 3), 0, 2)`
`frame_step(d) = clamp(fill_step(d) + SEAM_SIDE_OFFSET, 0, 3)`
`north_step = 1 (MID)` · `threshold_step = 1 (MID)` — the two authored pins.

The MVP's `origin_row = 11` and `span_intervals = 5` are contract operands, not literals; a room reuse must satisfy `len(step_by_row) == span_intervals`, `len(alpha_by_row) == span_intervals`, and the validator recomputes the table.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| local tile row | `row_y` | int | `origin_row − 1` … `origin_row + span_intervals` | the room's local row (MVP: 10–16) |
| depth origin | `origin_row` | int | 11 | the wing's north edge; the field's zero |
| depth span | `span_intervals` | int | 5 | last row − first row (5 intervals over 6 rows) |
| normalized depth | `d` | float | [0.0, 1.0] | 0 at the mouth, 1 at the far end |
| fill step index | `fill_step` | int | [1, 3] | index into `[DEEP, MID, PALE, LIGHT]` |
| frame step index | `frame_step` | int | [0, 3] | the frame columns' index (`fill_step + SEAM_SIDE_OFFSET`, clamped) |
| side offset | `SEAM_SIDE_OFFSET` | int | [−1, 0] | −1 = one step below the fill; 0 = the fill sample |
| north pin | `north_step` | int | 1 | the frame's north row (authored exception) |
| band pin | `threshold_step` | int | 1 | the threshold band (authored exception) |

**Output Range:** the printed row table; `fill_step ∈ [1,3]`, `frame_step ∈ [0,3]` ([0,2] at the default −1), all indices ∈ 0..3. The two pins are the **only** deviations from the sample; the check whitelists exactly them.

| Row | `d` | `fill_step` | Fill target (SYS-09; OQ-7) | `frame_step` | Frame W/E |
|---|---|---|---|---|---|
| 10 (band) | 0.0 | 1 | — | — | pin 1 MID |
| 11 (north) | 0.0 | 1 | MID | — | pin 1 MID |
| 12 | 0.2 | 1 | MID | 0 | DEEP |
| 13 | 0.4 | 2 | PALE | 1 | MID |
| 14 | 0.6 | 2 | PALE | 1 | MID |
| 15 | 0.8 | 3 | LIGHT | 2 | PALE |
| 16 | 1.0 | 3 | LIGHT | 2 | PALE |

At `SEAM_SIDE_OFFSET = 0`, the W/E = the fill steps (MID/PALE/PALE/LIGHT/LIGHT); at −1, DEEP/MID/MID/PALE/PALE. `tint_by_step[4]` covers the union 0..3; the unreachable members are still validated.

**Examples:** row 13 → `d = 2/5 = 0.4`; `floor(1.2) = 1`; `fill_step = 2` PALE; `frame_step = 1` MID. Row 16 → `d = 1.0`; `floor(3.0) = 3`; the clamp caps it at 2; `fill_step = 3` LIGHT; `frame_step = 2` PALE. **Implementation pins:** force float division (`/ 5.0`; GDScript int `/` truncates and would flatten rows 12–15 to MID); `span_intervals` is 5, not 6 (6 puts rows 13/15 on the 1/3 and 2/3 float boundaries); the clamp is load-bearing at row 16; the frame derives from `d`, **never** from SYS-09's fill (the rows 12–16 agreement is a cross-system target, not a data dependency; the fill's row sampling is OQ-7). The north pin (MID) is one step lighter than the W/E's first row (DEEP) — the top-corner one-step discontinuity is **authored**, not a bug; pinning the north to DEEP would reintroduce the cross-corridor edge the design rejects.

#### F-SMB-02 · band_rect + band_cells — the clip (TR-SMB-002)

The `band_rect` formula is defined as:

Precondition: `tile_aligned(opening_rect_tiles) ∧ opening_rect_tiles ⊆ threshold.rect_tiles`; a violation is a boot failure naming `rm03_partition`, never a quantized clip. `threshold.rect_px` and `opening_rect_px` are F-RWS-01 conversions (`TILE_PX` 16, RM-03's origin (1280,0)).
`band_rect = threshold.rect_px.intersection(opening_rect_px)`
`band_cells = cells(band_rect)` if `band_rect.has_area()` else `∅`
`band_present(e) = visible(BAND, e) ∧ band_rect.has_area()`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| authored band (tiles) | `threshold.rect_tiles` | Rect2i | (2,10,10,1) | SYS-02's partition row |
| authored band (px) | `threshold.rect_px` | Rect2 | tile-aligned 160×16 at (1312,160) | F-RWS-01 from `rect_tiles` + RM-03's origin (1280,0) |
| gate opening (tiles) | `opening_rect_tiles` | Rect2i | tile-aligned, ⊆ `threshold.rect_tiles` | SYS-02's `ZoneGateData.opening_rect` |
| gate opening (px) | `opening_rect_px` | Rect2 | tile-aligned, ⊆ `threshold.rect_px` | F-RWS-01 |
| visible band | `band_rect` | Rect2 | [0,160]×[0,16] px, tile-aligned | the clipped band |
| band cells | `band_cells` | set<(int,int)> | 0–10 cells | the keyed cells |
| epoch | `e` | int | [0, `max_epoch`] | the truth epoch |
| band present | `band_present` | bool | {false, true} | whether the band's record exists |

**Output Range:** `band_rect` may be empty; the remainder `threshold.rect_px \ band_rect` is **not** in the seam's key set and renders the hall's A-wall. An open gate with a zero-area band is a boot/data failure naming `rm03_partition`, never a silent empty band.
**Example:** opening at local x 4..9 → world `Rect2(1344,160,96,16)`, 6 cells; the remainder x 1312..1344 and x 1440..1472 renders the A-wall.

#### F-SMB-03 · visible(seg, e) — per-segment derivation (TR-SMB-003)

The `seam_visibility` formula is defined as:

`visible(seg, e) = (seg == BAND) ? gate_open(rm03_partition, e) : zone_materialize(cold_corridor, e)`
`boot_ok = ∀e ∈ [0, max_epoch]: gate_open(rm03_partition, e) == zone_materialize(cold_corridor, e)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| segment | `seg` | enum | {BAND, FRAME} | the north row and tint ride FRAME |
| epoch | `e` | int | [0, `max_epoch`] | the truth epoch |
| gate predicate | `gate_open` | (room_id, e) → bool | {false, true} | SYS-02/SYS-10's `GATE_OPEN` |
| materialize predicate | `zone_materialize` | (zone_id, e) → bool | {false, true} | SYS-10's `ZONE_MATERIALIZE` |
| visible | `visible` | bool | {false, true} | the segment's render state |
| boot equivalence | `boot_ok` | bool | {false, true} | the epoch-domain equivalence |

**Output Range:** bool; `boot_ok = false` → boot failure naming `REVEAL_CISTERN`. The equivalence is over the **epoch domain**, not the point `e = 1` — a predicate pair that agrees at 1 but splits at 2 must fail; the fixture injects a synthetic `TruthPort` with `max_epoch = 2`.
**Example:** e=0 → (false, false) → SEALED; e=1 → (true, true) → MATERIALIZED; e=1 with (true, false) → boot failure.

#### F-SMB-04 · accept(contract) — the version + staleness guard (TR-SMB-001/005)

The `seam_contract_accept` formula is defined as:

`accept(c) = (c.schema_version == SEAM_SCHEMA_VERSION) ∧ (c.tint == null ∨ (c.tint.admission_record != null ∧ c.tint.admission_record.predicate_version == ADMISSION_VERSION ∧ c.tint.admission_record.ramp_hash == hash(PROV_LIM_*) ∧ c.tint.admission_record.grief_hash == hash(PROV_GRIEF_TINT) ∧ c.tint.admission_record.placement_hash == hash(mask ∪ placement set) ∧ c.tint.admission_record.constants_hash == hash(P1–P5 constants) ∧ c.tint.admission_record.tint_hash == hash(tint_by_step ∪ alpha_by_row) ∧ c.tint.admission_record.hue_hash == hash(A ∪ B)))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| contract version | `c.schema_version` | int | [1, ∞) | the contract's version |
| reader version | `SEAM_SCHEMA_VERSION` | const int | 1 | the reader's version |
| admission record | `c.tint.admission_record` | null \| record | — | the CI-produced admission, nested inside `tint` |
| predicate version | `predicate_version` | int | [1, ∞) | the P1–P5 version |
| admission version | `ADMISSION_VERSION` | const int | 1 | the reader's predicate version |
| ramp hash | `ramp_hash` | hash | — | the `PROV_LIM_*` table's content hash |
| grief hash | `grief_hash` | hash | — | the grief tint's content hash |
| placement hash | `placement_hash` | hash | — | the admitted mask + placement set's content hash |
| constants hash | `constants_hash` | hash | — | the P1–P5 constants' content hash |
| tint hash | `tint_hash` | hash | — | the admitted `tint_by_step ∪ alpha_by_row` content hash |
| hue hash | `hue_hash` | hash | — | the A ∪ B hue sets' content hash |

**Output Range:** bool; `false` → boot failure naming the contract, never a silent fallback.
**Example:** schema 1 + tint null → accept (grey default); schema 1 + tint present + record null → fail (the present-but-unratified boot failure); schema 2 → fail; schema 1 with a record whose `ramp_hash` predates the art-bible re-pin → fail → grey until CI re-admits. This is the guard that stops a purple admitted against PLACEHOLDER hexes from shipping after the ramp is pinned. The applied tint requires `PURPLE_ENABLED ∧` a valid record ∧ the art-bible ratification; the record is necessary, not sufficient. A tint present with the knob false is the present-but-unratified boot failure.

#### F-SMB-05 · admit(tint) — the admission predicate (TR-SMB-005)

The `seam_tint_admission` formula is defined as:

`admit = P1 ∧ P2 ∧ P3 ∧ P4 ∧ P5 ∧ G`

`P1 = ∀i ∈ 0..3: C(T_i) ≤ min(C(R_i) + ADM_C_SLACK, ADM_C_ABS)`
`P2 = ∀i: |L(T_i) − L(R_i)| ≤ ADM_L_TOL ∧ C(D(T_i)) ≤ ADM_C_DESAT ∧ |L(D(T_i)) − L(R_i)| ≤ ADM_L_TOL ∧ (the four L(D(T_i)) strictly monotone in R's order with min adjacent gap ≥ ADM_L_GAP_MIN)`
`P3 = alpha(band) = 0 ∧ alpha(north) = 0 ∧ alpha_by_row monotone non-decreasing in d ∧ max(alpha_by_row) ≤ ADM_ALPHA_MAX ∧ max(alpha_by_row) ≥ 1/255 ∧ mask == (W ∪ E cells rows 12..16) \ cells(fixtures ∪ M4) ∧ |mask| > 0`
`P4 = ∀i: min_{a∈A} hue_dist(h(S(T_i)), h(a)) ≥ ADM_HUE_SEP_DEG ∧ min_{b∈B} hue_dist(h(S(T_i)), h(b)) ≥ ADM_HUE_SEP_DEG ∧ hue_dist(h(S(T_i)), h(grief)) ≥ ADM_HUE_SEP_DEG ∧ h(S(T_i)) ∈ ADM_HUE_BAND`
`P5 = C(T_i) ≤ 0.5 × C(PROV_GRIEF_TINT)`
`G = (|ramp| == 4 ∧ all present) ∧ (grief.present ∧ C(grief) ≥ 0.01) ∧ (|A| ≥ 1) ∧ (|B| ≥ 1) ∧ (mask == expected set) ∧ (|mask| > 0) ∧ (placement_hash == hash(mask ∪ placement set)) ∧ (D defined) ∧ (feasible_hue_interval ≠ ∅)`
`hue_dist(h1, h2) = min(|h1 − h2|, 360 − |h1 − h2|)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| liminal ramp | `R_i` | OKLCH color ×4 | the `PROV_LIM_*` entries, index order | the grey ramp |
| candidate tint | `T_i` | OKLCH color ×4 | per-step | the tint color at step `i` — **per-step**, not one color |
| desaturated candidate | `D(T_i)` | OKLCH color | C → 0, L preserved | the desaturate test |
| saturation-stress candidate | `S(T_i)` | OKLCH color | fixed L/h, C = 0.15 | the identity stress test |
| reality-A hues | `A` | set<deg> | ≥ 1 member | the A slots' hues (dormant included) |
| reality-B hues | `B` | set<deg> | ≥ 1 member | the B slots' hues (dormant included) |
| grief tint | `PROV_GRIEF_TINT` | OKLCH color | 1 member | the wing's one admitted hue |
| grief hue | `h(grief)` | deg | [0, 360) | the grief tint's hue |
| tint mask | `mask` | set<(int,int)> | 0–10 cells | the W/E cells minus fixtures/M4 |
| placement hash | `placement_hash` | hash | — | the admitted mask + placement set's content hash |
| feasible hue interval | `feasible_hue_interval` | set<deg> | ⊆ [255,325] | F-SMB-07's output |
| admission result | `admit` | bool | {false, true} | the tint's admission |

**Constants:** `ADM_C_SLACK` 0.035 · `ADM_C_ABS` 0.045 · `ADM_L_TOL` 0.02 · `ADM_C_DESAT` 0.005 · `ADM_L_GAP_MIN` 0.05 · `ADM_HUE_SEP_DEG` 40 · `ADM_HUE_BAND` [255, 325] · `ADM_ALPHA_MAX` 0.5 · `ADM_GRIEF_C_MIN` 0.01.

**Output Range:** bool. `false` → `tint = null` (the grey default ships), **not** a boot failure; the boot failure is reserved for a present-but-unratified tint (TR-SMB-005). **The ramp precondition:** `|L(R_i) − L(R_{i+1})| ≥ ADM_L_GAP_MIN + 2 × ADM_L_TOL = 0.09` for a guaranteed pass at the stated tolerances; at a 0.05 gap only edge values pass, so the art bible must pin the ramp's L gaps ≥ 0.09 or the D-gap clause relaxes to ≥ 0.01 — recorded as an OQ.
**Examples:** a per-step lavender-grey candidate `C=[0.040,0.040,0.040,0.040]`, `L=[0.41,0.51,0.62,0.73]` against the ramp `C=0.02–0.03`, `L=[0.40,0.50,0.61,0.72]` → P1 `0.040 ≤ min(0.055, 0.045)` pass; P2 `|ΔL|=0.01`, the D-L gaps 0.10/0.11/0.11 ≥ 0.05 pass; P3 pass; P4 hue 275° → nearest A 180° = 95°, nearest B 35° = 120° (circular), grief 0° = 85°, pass; P5 grief C 0.18 → `0.040 ≤ 0.09` pass; G pass → **admitted**. A magenta `C=0.12` fails P1; a blue-violet `h=250°` fails P4's band; a warm mauve `h=330°` fails P4's band; a missing grief tint fails G. The vacuity guards: `C(D(T_i)) ≤ 0.005` is tested on a **defined** desaturation transform (not the achromatic projection, which is 0 by construction); P4's A/B sets include the dormant members; P5 binds only when `C(grief) < 0.09` — add a fixture at `C(grief)=0.08` so the clause is exercised.

#### F-SMB-06 · tint_alpha — the quantized depth tint (TR-SMB-005)

The `seam_tint_alpha` formula is defined as:

`alpha_by_row[k] = floor(ADM_ALPHA_MAX × d(origin_row + 1 + k) × 255) / 255`, k = 0..4 (rows 12..16 at MVP)
`cell_alpha(c,r) = alpha_by_row[r − 12]` if `(c,r) ∈ mask`, else 0
`row_color(c,r) = tint_by_step[frame_step(d(r))]`

The array length is `span_intervals` (5 at MVP); a reused room's arrays follow its span. The array covers the union domain 0..3; the offset's reachable subset is applied.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| max alpha | `ADM_ALPHA_MAX` | float | [0, 0.5] | the tint's ceiling |
| row depth | `d(origin_row + 1 + k)` | float | {0.2, 0.4, 0.6, 0.8, 1.0} | rows 12–16 at MVP |
| per-row alpha | `alpha_by_row` | float[5] | [0, 127/255] | floor-quantized |
| tint mask | `mask` | set<(int,int)> | 0–10 cells | W/E cells minus fixtures/M4 |
| per-step tint | `tint_by_step` | OKLCH color[4] | per-step | the admitted colors |
| cell alpha | `cell_alpha` | float | [0, 127/255] | the blend weight |
| row color | `row_color` | OKLCH color | per-step | the base color |

**Output Range:** monotone non-decreasing; `max(alpha_by_row) ≤ 127/255 = 0.49804`; alpha 0 at the band, north row, fill, fixtures, and M4. **Floor, not round:** `round(0.5 × 255) = 128/255 = 0.502 > 0.5`, violating P3 after quantization.
**Example:** `ADM_ALPHA_MAX = 0.5` → `[floor(0.5×0.2×255), floor(0.5×0.4×255), floor(0.5×0.6×255), floor(0.5×0.8×255), floor(0.5×1.0×255)] = [25, 51, 76, 102, 127]/255 = [0.098, 0.200, 0.298, 0.400, 0.498]` ✓.

#### F-SMB-07 · feasible_hue_interval — the diagnostic (TR-SMB-005)

The `seam_feasible_hue` formula is defined as:

`feasible_hue_interval = ADM_HUE_BAND \ ⋃_{a∈A} arc(h(a), ADM_HUE_SEP_DEG) \ ⋃_{b∈B} arc(h(b), ADM_HUE_SEP_DEG) \ arc(h(grief), ADM_HUE_SEP_DEG)` (circular)
`arc(h, r) = (h − r, h + r) mod 360` (open endpoints; a hue exactly r away remains feasible)

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| hue band | `ADM_HUE_BAND` | interval | [255, 325] | the admitted purple window |
| A/B hues | `h(a)`, `h(b)` | deg | [0, 360) | the truth slots' hues |
| grief hue | `h(grief)` | deg | [0, 360) | the grief tint's hue |
| separation | `ADM_HUE_SEP_DEG` | deg | 40 | the minimum distance |
| feasible interval | `feasible_hue_interval` | set<deg> | ⊆ [255,325] | the remaining hues |

**Output Range:** a possibly empty set. **Empty → the purple is closed** (grey default) — a decision, not a test failure; record it as the feasibility diagnostic. **Example:** A {180,190,200,210} → union [140,250]; B {20,35,45,350} → union [310,85] (wrap); at `h(grief)=0` the grief arc [320,40] does not overlap; `[255,325] \ [140,250] \ [310,85] = [255,310)` → non-empty; a B member at 300 would remove [260,340] and leave [255,260).

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### The truth and the seam

- **If epoch 0** → the band and wing render the hall's A-wall; zero `PROV_LIM_*` pixels; zero seam keys; no tell. [TR-SMB-003/006.]
- **If epoch ≥ 1 post-E4** → the band = MID; the frame = `step_by_row`; the fill is SYS-09's; the first held frame is complete. [TR-SMB-003/004.]
- **If a VS second flip applies** → the seam persists (epoch-invariant); it is neither truth. [TR-SMB-003; TR-RWS-022.]
- **If the flip request arrives mid-arc or mid-activation** → SYS-02 defers to the completion boundary; the seam materializes at the next resolve; no partial band. [TR-SMB-003/007; SYS-02's TR-RWS-014.]
- **If a pre-flip (epoch 0) save restores in RM-03 while the live session was epoch 1** → the load emits the full re-resolve before the first rendered frame; the first frame renders the save's epoch (band absent, wing A-wall); a same-room load that skips the resolve is a dev assert + telemetry, never a stale epoch-1 seam. [TR-SMB-009; SYS-09's TR-DR-003 resolve points are room entry + τ0 — a load is neither.]

### Placement and data

- **If `opening_rect` is not tile-aligned or is not a subset of `threshold.rect`** → boot failure naming `rm03_partition`; the intersection runs only after the alignment/subset guards pass. Never quantize: ceil paints liminal over a sealed cell; floor leaves an open cell A-walled. [TR-SMB-002; F-SMB-02.]
- **If the opening is zero-area while the gate is open** → boot failure naming `rm03_partition`; never a silent empty band. [F-SMB-02.]
- **If the opening is not a subset of the band** (wider or misaligned) → boot failure naming `rm03_partition`; the subset/alignment precondition is binding — never a graceful clip. [F-SMB-02; TR-SMB-002.]
- **If `gate_open(rm03_partition, e)` and `zone_materialize(cold_corridor, e)` desync at any epoch** → boot failure naming `REVEAL_CISTERN`; the equivalence is over the epoch domain, not the point e=1. [F-SMB-03.]
- **If a future mutation set re-times the first true epoch** → `visible_at_epoch_gte` is **derived at boot** as `min{e : both predicates true}`; a stale authored literal → boot failure; null (never true) → boot failure. [TR-SMB-001/003.]
- **If a future room reuses the contract with a different wing height** → boot failure unless `len(step_by_row) == span_intervals`, `len(alpha_by_row) == span_intervals`, and the validator recomputes the row table for the room's domain; the MVP's 11/5 is a fixture, not a law. [TR-SMB-004.]
- **If the contract rects are not grid-aligned or overlap** → boot failure; the frame rects are non-overlapping and inside the seam region. [V-SMB-02.]

### The tint

- **If the tint fails any of P1–P5 or G** → `tint = null`; the grey default ships; no boot failure. [TR-SMB-005; F-SMB-05.]
- **If the tint is present but the admission record is missing or stale** (ramp / grief-tint / placement-mask / P1–P5-constants hash mismatch) → boot failure naming the contract; never a silent fallback. [F-SMB-04.]
- **If a fixture or M4 anchor moves into a frame W/E cell after admission** → the placement hash mismatches → boot failure; the runtime applies the admitted `mask_cells` verbatim, so a moved fixture is never painted over. [TR-SMB-005.]
- **If the admitted `alpha_by_row` is all zeros** → P3 fails (`max(alpha_by_row) ≥ 1/255` on the quantized array); `tint = null`; a present-but-invisible tint cannot consume the purple's ratification while shipping grey. [F-SMB-05/06.]
- **If the alpha is rounded to 128/255** → P3 fails (`> 0.5`); use floor. [F-SMB-06.]
- **If the grief tint is missing or achromatic** → G fails with the named diagnostic "grief tint missing"; `tint = null`. [F-SMB-05.]
- **If the feasible hue interval is empty** → the purple is closed; the grey default; a decision, not a test failure. [F-SMB-07.]
- **If the ramp's L gaps are < 0.09** → P2's guarantee is not met; the D-gap clause relaxes to ≥ 0.01 or the art bible re-pins the ramp; recorded as an OQ. [F-SMB-05.]

### Load, save, and persistence

- **If a save is taken inside the flip window** → SYS-03 queues to the first unfrozen tick; the seam is not a save source; no seam field. [TR-SMB-009; SYS-09's E4 law.]
- **If a deferral-gap save restores** → SYS-10's re-fire; the seam materializes at the first post-load flip; no seam state. [TR-SMB-009.]
- **If an epoch-1 save restores** → the first frame is materialized; zero intermediate A/grey frames. [TR-SMB-009.]
- **If M4 is taken** → the seam is unchanged; the post-M4 record equals pre-M4 except M4's grief tint; no `memories_collected` read. [TR-SMB-009/012.]
- **If the save lacks the trigger flag** → SYS-10's absent-key-unset; the seam is epoch-derived; no seam effect. [TR-SMB-009.]
- **If the restored epoch is out of range** → SYS-10's abort → SYS-03's refusal path; the seam never renders. [TR-SMB-009.]

### The hold and the camera

- **If `active_hold` is live while `visible(BAND, e)` is false** (a synthetic hold-before-E4) → the seam renders SEALED (the epoch's truth); pre-arm hold detection is SYS-32's TR-CAM-013 dev assert; SYS-11 reads no hold and has no fallback. [TR-SMB-006.]
- **If `active_hold` outlives `freeze_close`** → the seam's step map is bit-identical before/during/after; the hold-blind fixture. [TR-SMB-006.]
- **If the reveal hold starts or ends** → zero seam deltas; the seam is hold-blind. [TR-SMB-006.]
- **If `active_hold` is absent** → no effect. [TR-SMB-006.]

### Tells and rendering

- **If RM-03's tell rows are removed or the tell pass is disabled** → the seam's records are bit-identical with and without the tell pass; the zero-tell variant fixture; the seam is a material resolve, not a tell entry. [TR-SMB-006.]
- **If the seam step map is implemented as a tell entry or a post-pass** → the zero-tell variant fails; the boot audit. [TR-SMB-006.]
- **If the band's epoch-0 record is present** → boot failure; the band is absent at epoch 0. [TR-SMB-006.]
- **If the seam at epoch ≥1 has a unique hue, edge, or pulse** → the tell audit fails; the band is the tell's payoff surface, not a second anomaly. [TR-SMB-006.]

### Performance

- **If the contract is parsed or validated inside the flip** → the preload fixture fails; the boot assert. [TR-SMB-007/010.]
- **If a per-tick seam lookup exists** → the zero-lookup audit fails; the not-join. [TR-SMB-010.]
- **If the boot exceeds 1 ms** → the dev assert (contract parse + validation + step-map derivation only; the admission test is CI-only). [TR-SMB-010.]
- **If the 0.1 ms incremental exceeds the budget** → the nearest-rank estimator with n ≥ 1,000; no tick conversion. [TR-SMB-010.]

## Dependencies

**Upstream authoring dependencies: none** — SYS-11 is Core, authored in the approved design order after SYS-02/SYS-32/SYS-09/SYS-10. The runtime consumptions are contracts of landed GDDs and ADR-0001, not authoring dependencies.

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream (runtime) | **SYS-02 Room & World** | **Hard** (read-only) | In: threshold band, `opening_rect`, wing rect, framing zone, M4 anchor, the material lookup · Out: nothing | APPROVED 2026-11-13 |
| Upstream (runtime) | **SYS-09 Dual-Reality** | **Hard** (shared source) | In: `PROV_LIM_*` ramp, the render application, TR-DR-012's admission test, TR-DR-013's camera-witness · Out: the seam contract (step map + tint) | Landed 2026-11-14 |
| Upstream (runtime) | **SYS-10 World Mutation** | **Hard** (indirect) | In: `truth_epoch`, the `GATE_OPEN`/`ZONE_MATERIALIZE` predicates, the tell-free delta namespace · Out: nothing | APPROVED 2026-11-14 |
| Upstream (acceptance fixture) | **SYS-32 Camera & Framing** | **Soft** (hold-blind) | In: nothing — **no CameraPort, no `active_hold` read** · Out: nothing | APPROVED 2026-11-14 |
| Upstream (binding) | **ADR-0001** | **Binding** | §3 freeze, §5 pipeline, §15 purity seam | Accepted 2026-11-12 |
| Downstream | **SYS-09** (renderer) | **Hard** (the applier) | The seam contract is consumed at SYS-09's existing resolve points | Landed |
| Downstream | **SYS-03 Save** | None | No seam field; the epoch re-derives | Not Started |
| Downstream | **SYS-04 / SYS-01 / SYS-24 / SYS-29 / SYS-14 / SYS-28 / SYS-25 / SYS-20 / SYS-15** | None | No audio, input/prompt, HUD, VFX, arena, text, map, memory-content, or cache surface | — |

**Explicit non-dependencies:** SYS-03 (no save field) · SYS-04 (no audio) · SYS-01 (no input/prompt) · SYS-24 (no HUD) · SYS-29 (no VFX/shake) · SYS-14 (the arena is pinned epoch 0; no interface) · SYS-28 (no text) · SYS-25 (the MVP map is truth-agnostic) · SYS-20 (M4's content is SYS-20's; SYS-11 reads no memory state) · SYS-15 (no cache interface) · SYS-12 (VS).

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) **SYS-11's row** gains the GDD path, the counts, the material-only correction ("Yes (one + VFX)" → "Yes (one; material recipe only — no prompt/VFX/audio)"), the not-join, and the OQ-RWS-7 routing; (2) **SYS-02's row** gains the seam placement consumption note (the band + wing rects, the frame step map, the band clip); (3) **SYS-09's row** gains the seam frame step-map consumption, the key-level tint countersign, and the band's inclusion in PR-DR-05/AC-DR-15; (4) **SYS-10's row** gains the epoch read-only + tell-free delta note; (5) **SYS-32's row** gains the hold-blind note; (6) **SYS-03's row** gains the no-seam-field note; (7) the registry gains `seam_border_contract` + `seam_admission_test` and the `room_bounds_contract` / `dual_reality_palette_tables` `referenced_by` updates.

**Missing-input failure paths:** the Interactions table names them — SYS-02 placement → boot failure naming the segment; SYS-09 palette/step map → boot failure or dev assert + telemetry; SYS-10 epoch → SYS-10/SYS-02's failure path; SYS-32 `active_hold` → no effect (hold-blind). No silent defaults.

## Tuning Knobs

**All SYS-11 knobs are designer/art-bible-only at MVP.** The seam's honesty is identity, not preference: the placement, the ramp, the epoch law, the no-tell/no-prompt pivot, and the collision abstention are contracts, not knobs.

| Knob | Default | Safe range | Why the bounds | Rule |
|---|---|---|---|---|
| `SEAM_SIDE_OFFSET` | −1 | [−1, 0] | −1 = the edge shadow (one step below the fill); 0 = the frame samples the fill field. <−1 drops two steps; >0 makes the frame lighter than the fill (a border highlight — the door read). | TR-SMB-004; F-SMB-01 |
| `SEAM_BAND_STEP` | MID | {MID} | DEEP reads as a hole/shadow band on the walkable floor; LIGHT reads as a lit strip (a pointing device); the PALE arm is not exercised without a playtest signal. | TR-SMB-004; F-SMB-01 |
| `ADM_ALPHA_MAX` | 0.5 | [0.0, 0.5] | 0 disables the tint; >0.5 reads as a color, not a tint; the floor-quantized max is 127/255. | TR-SMB-005; F-SMB-06 |
| `ADM_C_ABS` | 0.045 | [0.0, 0.045] | >0.045 fails the lavender-grey bound (P1); 0 = achromatic. | F-SMB-05 |
| `ADM_L_TOL` | 0.02 | [0.01, 0.03] | >0.03 lets the tint move the frame's value against M4 (the value-zoning law). | F-SMB-05 |
| `ADM_L_GAP_MIN` | 0.05 | [0.01, 0.09] | The D-gap; the ramp precondition is `gap_R ≥ 0.09` for a guaranteed pass; <0.01 the monotonicity is noise. | F-SMB-05 |
| `ADM_HUE_SEP_DEG` | 40 | [40, 60] | <40 risks A/B contamination; >60 shrinks the feasible interval (F-SMB-07) toward empty. | F-SMB-05/07 |
| `ADM_GRIEF_C_MIN` | 0.01 | [0.01, 0.05] | Below 0.01 the grief tint is achromatic; the P5 guard fails. | F-SMB-05 |
| `PURPLE_ENABLED` | false | {false, true} | A gate, not a preference: true requires the P1–P5 admission record + the art-bible ratification; a present-but-unratified tint is a boot failure. | TR-SMB-005; F-SMB-04 |

**Cross-system inputs (consumed, not SYS-11 knobs):** the `PROV_LIM_*` hexes (SYS-09's) · the grief tint (SYS-09's) · the placement rects (SYS-02's) · the epoch + predicates (SYS-10's) · `REMATERIALIZE_BUDGET_MS` 100 (SYS-02's) · the 1 ms boot budget (SYS-11's dev assert) · the 0.1 ms incremental (SYS-11's dev assert).

**Not knobs:** the no-prompt/no-VFX/no-audio pivot · the no-tell/no-HUD/no-camera · the collision abstention · the epoch-invariance · the derived visibility · the static tint · the per-step color requirement · the floor quantization · the frame/band rects · the two authored pins (north/band = MID) · the `visible_at_epoch_gte` derivation.

**Provisional lifetimes:** the side offset (playtest/art-bible) · the band step (playtest/art-bible) · the admission constants (art-bible) · the ramp L gaps (art-bible) · the purple's admission (art-bible; OQ-1). The `PROV_LIM_*` hexes are PLACEHOLDER through the greybox MVP.

## Visual/Audio Requirements

**Preamble.** SYS-11 authors no pixels and no sound; it authors the material recipe SYS-09 applies and the constraints the art bible ratifies. All values are art-bible-pinned; the GDD carries constraints, not hexes. The ramp's hexes are SYS-09's `PROV_LIM_*` (PLACEHOLDER through the greybox MVP).

### Visual

| ID | Requirement | Parent |
|---|---|---|
| VR-SMB-01 | **The ramp is a value ladder.** L ≈ 0.40 / 0.50 / 0.61 / 0.72 (ΔL ≥ 0.09; target 0.10–0.11), C ≤ 0.008 all four, one shared hue or none (outside `ADM_HUE_BAND` [255,325], ≥ 40° from every A/B member, dormant included). No step more chromatic than another; the ramp is a material, not a palette. | TR-SMB-004; TR-DR-002/012; F-SMB-05 |
| VR-SMB-02 | **The ramp is the only light.** Steps on tile-row boundaries only (rows 12–16); zero dither/gradient/noise/glitch vocabulary; no per-tile bevels, highlights, or baked shadows. A second light model creates local contrast events and reads "corrupted." | TR-DR-012; TR-SMB-006/011/012 |
| VR-SMB-03 | **Coursing is the only texture.** One 1px course line per 16px tile at ΔL −0.05 (same hue; derived shade, not a member), full width, bottom edge; phase-aligned with the hall (world y ≡ 0 mod 16). Zero vertical joints (max 1-in-2 stagger); zero bevels/highlights/cracks/chips/carvings/ribs/plates/iconography; outline-free. Max 2 values per tile. | TR-DR-012; TR-SMB-012; the concept's pack normalization |
| VR-SMB-04 | **The frame is a return, not a border.** W/E reuse the fill's tiles one step down per row at the default `SEAM_SIDE_OFFSET` −1 (DEEP/MID/MID/PALE/PALE; the offset is a knob, F-SMB-01), same coursing, no outline/bevel, never lighter than the fill (`SEAM_SIDE_OFFSET` ≤ 0). North = MID = band, no line; band + north merge into a 32px threshold plane. The top-corner one-step is a 16×16 corner shadow. The missing S frame is load-bearing (a 4-sided frame reads as a picture/door). The only admitted hue is the bounded frame tint (VR-SMB-08), never a unique hue on the band or north row. | TR-SMB-004; F-SMB-01; `SEAM_SIDE_OFFSET` |
| VR-SMB-05 | **The band is MID at MVP.** `SEAM_BAND_STEP` = MID; the PALE arm is not exercised without a playtest signal (a pale strip on the walkable floor is a pointing device). The clip boundary to the hall's material carries zero 1px edge treatment; the material change is the edge. | TR-SMB-002; F-SMB-02; `SEAM_BAND_STEP` |
| VR-SMB-06 | **The pale end is a plane, not a glow.** The terminal fill's LIGHT rows span the full 128px interior width; the 16px W/E frame cells stay PALE (the return). No radial falloff, center hotspot, halo, or bloom. The far plane is the value maximum (L 0.72, C ≤ 0.008). The south termination (SYS-09's fill/zone) continues the terminal step with no ledge lip/exit notch/lit strip — a consumed visual note for SYS-09's next doc touch. | TR-DR-012; TR-SMB-012 |
| VR-SMB-07 | **The grief tint is chroma-max, value-subordinate.** C 0.12–0.18; L 0.55–0.68 (below LIGHT); ≤ 1/3 of M4's lit pixels, ≤ ~1% of the wing's area; zero spill; no additive/bloom/halo/pulse; M4's anchor only; hue in the warm rose/ember band [330,20] (circular), distinct from A's cyan/teal, B's amber/wine, and `PROV_SIGIL_RED`; the art bible pins the exact hue. M4's body L ≤ 0.50 against LIGHT (≥ 2 steps). **The five-errand grief wash excludes the seam region** — otherwise epoch-invariance and the "one color" law both break. | TR-DR-012; AC-DR-15; F-SMB-05 P5 |
| VR-SMB-08 | **The optional purple is a static depth tint, not a bridge.** W/E only, 10 cells max, per-step colors, alpha monotone/floor-quantized, `ADM_ALPHA_MAX` target ≤ 0.30 (formula ceiling 0.5; max 76/255 at target), source C 0.025–0.043, rendered C 0.010–0.018 (≤ 0.025 at the ceiling), hue in F-SMB-07's interval, ΔL ≤ `ADM_L_TOL` 0.02, alpha 0 at band/north/fill/fixtures/M4. No texture, no animation, no time uniform, epoch-invariant. | TR-SMB-005; F-SMB-05/06/07 |
| VR-SMB-09 | **The 2-second read is negative-identifiability.** Forced choice A / B / neither + failure catch (door/portal/loading/unfinished/corrupted); reveal framing at epoch 1 (B surround) and epoch 0 (A-wall); 1:1 + device scale; n ≥ 5; epoch 1 ≥ 4/5 "neither", epoch 0 ≥ 4/5 "A"; 0 failure reads; stable across all six rows. | the concept's 2-second test; TR-SMB-012; SYS-09's F3 anti-code |
| VR-SMB-10 | **Membership.** Post-E4 wing = 4 ramp members + 4 course shades + grief at M4 + entity colors; no other hue family, with the admitted frame tint (VR-SMB-08) as the sole bounded exception, subordinated to M4's grief (P5). Epoch 0 = the hall's A-wall, zero `PROV_LIM_*`, zero seam keys. The corridor has no GLOW/ACCENT/HAZARD role — only values; that is what keeps it from being a fifth palette. | AC-DR-15; V-SMB-03 |

### Audio

| ID | Requirement | Parent |
|---|---|---|
| AR-SMB-01 | **Zero audio publications.** No one-shot, loop, snapshot, bus change, parameter, or duck; SYS-11 is not an audio publisher. V-SMB-01's static audit; SYS-04's edge list stays closed. | TR-SMB-006/011; TR-RWS-022; TR-JCE-027 |
| AR-SMB-02 | **The bed continues.** RM-03's ambient bed unchanged across the threshold and through the wing: no crossfade, filter sweep, layer add, loop restart, or reveal sting. A no-op on the audio graph — not a mute, not a silence trigger. | TR-RWS-022; SYS-04's closed list |
| AR-SMB-03 | **The no-duck ruling.** No duck; no extension/suppression of TR-DR-004's E1–E7 (SYS-10's E3b `ambient_shift` pinned to `epoch_swap`'s tick); no duck on SYS-32's reveal hold (TR-CAM-013). The only duck is the death beat (TR-JCE-027, provisional). | TR-DR-004; TR-CAM-013; TR-JCE-027 |
| AR-SMB-04 | **M4's chime is not the seam's.** The memory chime is SYS-20/29's TR-JCE-021 edge; the seam does not gate, duck, delay, or re-trigger it. If it fires at M4, it is the corridor's only audio event by consequence, not by seam authorship. | TR-JCE-021 |
| AR-SMB-05 | **The VS record.** A seam audio pass (creak/drone) is VS-recorded (SYS-02's OQ-RWS-5 neighbor) and requires a TR-JCE-027 revision; not an MVP edge. | SYS-02's VS record; TR-JCE-027 |

### Acceptance bars

| Bar | Test | Pass |
|---|---|---|
| Negative 2-second read | Reveal framing, epoch 1 (B surround) vs epoch 0 (A-wall); 1:1 + device scale; n ≥ 5 | ≥ 4/5 "neither"; 0 door/portal/loading/unfinished/corrupted |
| Desaturate/saturate (tint only) | `D(T)` → grey steps; `S(T)` at C 0.15 fixed L/h | D: L within `ADM_L_TOL` 0.02, C ≤ 0.005. S: ≥ 40° from every A/B member and inside [255,325]. Fail either → drop |
| Value zoning | Player body + M4 body vs every fill step | ≥ 2 steps (≥ 0.20 L) clear; ramp monotone ΔL ≥ 0.09; frame never lighter than fill; band/north merge |
| Membership | Post-E4 histogram + state records; epoch-0 records | Exactly the 4 members + 4 course shades + grief at M4 + entities + (if admitted) the bounded frame tint (VR-SMB-08); the band/north carry no hue; epoch 0 = A-wall, zero `PROV_LIM_*`, zero seam keys |
| Static | Two captures 600 ticks apart; static audit | Byte-identical; no time uniform; no animation; alpha max ≤ 127/255 (≤ 76/255 at target) |
| Coursing continuity | Threshold strip at 1:1 | Course-line phase identical across band/north/fill; a 1px offset fails |
| No spill | M4's anchor + 1-tile ring | Zero grief-tinted pixels outside the anchor |

### Asset-spec route

`/asset-spec system:seam-borders` produces the four shared `PROV_LIM_*` tile faces (SYS-09's set, **not forked**), the band/north/W/E compositions, and a `seam_tint_spec` data sheet (4 per-step OKLCH colors + 5 floor-quantized alphas + the 10-cell mask; QA swatch, not a shipped texture; no `vfx_` asset).

### Recorded conflicts and notes

- **The approved-text conflict.** SYS-02's Player Fantasy line 36 ("a purple bridge holding it together") and the systems index's "Cold Corridor purple = bridge material" assert the purple as present; the shipped default is grey. The art-bible pass ratifies the purple or records the rider to SYS-02's fantasy + the index row (the OQ-M1 pattern); OQ-1 owns it.
- **The fixture set.** The wing's fixtures are `[]` at MVP; the contract carries the field explicitly, and the placement hash covers mask ∪ placement set; a moved fixture is a boot failure.
- **The south termination** is SYS-09's fill/zone: the terminal LIGHT step continues; no ledge lip, exit notch, or lit strip (OQ-6).
- **The grief-wash exemption:** if the five-errand grief wash is full-screen, the seam region is excluded (VR-SMB-07).
- **The concept's seam-border Interact verb** (game-concept line 70) is SYS-10's VS shift, not an MVP function; the MVP seam is non-interactable (TR-SMB-006/011).

## UI Requirements

**None of its own.** The seam has no prompt, no HUD element, no map mark, no interactable, and no screen. It is not a UI surface. **No UX flag.**

## Acceptance Criteria

Coverage: **12 TR-SMB rules · 7 F-SMB formulas · 7 V-SMB invariants · 32 ACs · 4 playtest codes · 7 OQs**. Tags: `[GUT]` headless over the injected data/ports · `[LINT]` repo source/doc audit, run from source, not export · `[DEVICE]` on-device capture/diff · `[PLAYTEST]` coded human observation. The level split: GUT asserts **state/contract**; pixel proofs are device-only; the playtest codes are MVP-lock.

- **AC-SMB-01a** [GUT] *(TR-SMB-001/002; F-SMB-01)* — **GIVEN** SYS-02's placement fixture, **WHEN** the validator runs, **THEN** the band = `Rect2(1312,160,160,16)` (derived from SYS-02's tile-space `partition_rect` by F-RWS-01), the wing = `Rect2(1312,176,160,96)`, the frame N/W/E/fill partition the wing exactly (no overlap, no gap), all grid-aligned, and the W/E step arrays = `[0,1,1,2,2]` with the north/band pins = 1.
- **AC-SMB-01b** [GUT] *(TR-SMB-002; F-SMB-02)* — **GIVEN** opening variants (narrower, equal, zero-area-while-open, non-tile-aligned, not-a-subset), **WHEN** the clip runs, **THEN** the narrower opening clips the band and the remainder resolves to the hall's A-wall; zero-area-while-open and malformed openings fail the boot naming `rm03_partition`; no quantized band is produced.
- **AC-SMB-02** [GUT] *(TR-SMB-003/006; F-SMB-03)* — **GIVEN** epoch 0, **WHEN** the seam resolves, **THEN** the band + wing resolved key set equals the enclosing hall's A-wall members, zero `PROV_LIM_*` keys, zero seam keys, the band's epoch-0 record is absent, and the tell registry has zero seam entries.
- **AC-SMB-03** [GUT] *(TR-SMB-003/004/007; F-SMB-01/03)* — **GIVEN** epoch 1 post-E4, **WHEN** the seam resolves, **THEN** the band = MID, the north = MID, the W/E = `[DEEP,MID,MID,PALE,PALE]`, the fill keys are SYS-09's, and the load fixture records exactly one resolve at the save's epoch (materialized at epoch 1; A-wall at epoch 0) with zero intermediate A/grey key-sets (the rendered-frame sequence is AC-19/20's device protocol).
- **AC-SMB-04a** [GUT] *(TR-SMB-003; F-SMB-03)* — **GIVEN** the epoch-domain predicate fixtures, **WHEN** the boot equivalence runs, **THEN** `gate_open ⟺ zone_materialize` for all `e ∈ [0,max_epoch]`; the e=2 desync (a synthetic `TruthPort` at `max_epoch=2`: agree at 1, split at 2) fails the boot naming `REVEAL_CISTERN`.
- **AC-SMB-04b** [GUT] *(TR-SMB-001/003; F-SMB-03)* — **GIVEN** a stale authored `visible_at_epoch_gte` or a null derived min, **WHEN** the validator runs, **THEN** the boot fails naming `REVEAL_CISTERN`; the derived value = `min{e : both predicates true}`.
- **AC-SMB-05** [GUT] *(TR-SMB-004; F-SMB-01)* — **GIVEN** the depth-field fixtures, **WHEN** F-SMB-01 runs at rows 10–16, **THEN** the printed table reproduces exactly (band/north MID; row 12 DEEP/MID; 13 MID/PALE; 14 MID/PALE; 15 PALE/LIGHT; 16 PALE/LIGHT); the float division, clamp, and pins are asserted; the adjacent-step delta ≤ 1 across the band/north/W/E boundaries (the door/trigger guard); a room reuse with array lengths ≠ `span_intervals` (sized to the contract's own span) fails the boot.
- **AC-SMB-06** [GUT] *(TR-SMB-005; F-SMB-05/06)* — **GIVEN** the F-SMB-05 worked example (per-step C≈0.040, L=[0.41,0.51,0.62,0.73], h 275°; ramp C 0.02–0.03 / L=[0.40,0.50,0.61,0.72]; grief C 0.18), **WHEN** the admission and alpha run, **THEN** each P1–P5/G boolean is asserted true, `admit=true`; the tint is static (no time uniform), frame W/E only, alpha 0 at band/north/fill/fixtures/M4; the floor array = `[25,51,76,102,127]/255`; the cell mask equals the expected set.
- **AC-SMB-07a** [GUT] *(TR-SMB-005; F-SMB-05/06/07)* — **GIVEN** each P1–P5/G negative (magenta C=0.12; hue 250°; hue 330°; missing grief; all-zero alpha; 128/255 rounding; empty feasible interval; the P5 binding case `C(grief)=0.08` with a candidate `C(T)=0.045` (P1 passes at equality; P5 fails); the P2 D-gap failure), **WHEN** the admission runs, **THEN** `admit=false`, `tint=null`, the grey default ships with no code change; the empty interval is recorded as the purple-closed decision, not a failure; F-SMB-07's non-empty arithmetic is asserted at [255,310) and [255,260) (B at 300).
- **AC-SMB-07b** [GUT] *(TR-SMB-005; F-SMB-04)* — **GIVEN** a present tint with a null/missing admission record, any of the four hash mismatches (ramp/grief/placement/constants), or a schema/predicate version mismatch, **WHEN** `accept()` runs, **THEN** the boot fails naming the contract; a null record accepts the grey default.
- **AC-SMB-08** [GUT] *(TR-SMB-006)* — **GIVEN** the tell fixtures (enabled, disabled, zero-entry), **WHEN** the seam composites, **THEN** the seam records are bit-identical across all three; zero seam tell entries; RM-03's count = SYS-09's allocation; the render order is seam-before-tell; no unique hue/edge/pulse on the band/north row at epoch ≥1; the admitted frame tint is the sole bounded exception.
- **AC-SMB-09** [LINT] *(TR-SMB-006/008/011)* — **GIVEN** the static audits (scan roots `src/seam/` and `src/world/`'s seam adapter; banned symbols: `Input`, `SceneTree`, `Time`, `RenderingServer`, camera API, prompt/VFX/audio/HUD symbols, `active_hold`), **WHEN** they run from source, **THEN** zero hits; the seam is hold-blind.
- **AC-SMB-10** [LINT] *(TR-SMB-001/011)* — **GIVEN** the collision probe at both epochs with the contract present vs. deleted (scan root `src/seam/`; banned symbol `set_collision_*`), **WHEN** the probes run, **THEN** the results are identical; the contract has zero collision fields.
- **AC-SMB-11a** [GUT] *(TR-SMB-009)* — **GIVEN** the save fixtures (epoch-0 restore, epoch-1 restore, same-room load), **WHEN** each restores, **THEN** no seam save field exists; the epoch-1 first resolve is materialized; the epoch-0 mirror's first resolve is band-absent/wing-A-wall (the rendered-frame sequence is AC-19/20's device protocol); a same-room load that skips the resolve is a dev assert + one telemetry record.
- **AC-SMB-11b** [GUT] *(TR-SMB-009/012)* — **GIVEN** the post-M4 fixture, **WHEN** the seam resolves, **THEN** the record equals pre-M4 except M4's grief tint; zero `memories_collected` reads; zero `reveal_happened` reads/writes.
- **AC-SMB-12a** [GUT] *(TR-SMB-001/002/004/005/007)* — **GIVEN** the boot-failure fixtures (missing/malformed placement; missing palette member; step index out of range; band not in the re-material set; span/array mismatch; malformed opening; unratified tint), **WHEN** the validator runs, **THEN** each fails the boot naming the segment/contract; no silent default.
- **AC-SMB-12b** [LINT] *(TR-SMB-007/008)* — **GIVEN** the adapter-boundary scan (scan root `src/seam/`), **WHEN** it runs, **THEN** zero `RenderPort`/`CameraPort`/`active_hold` references; the seam's adapter uses only the published ports.
- **AC-SMB-12c** [GUT] *(TR-SMB-007)* — **GIVEN** a malformed step map and the preload fixture, **WHEN** the render adapter resolves, **THEN** a dev assert + one telemetry record fire; no silent fill fallback; the flip does no load/parse/validate; the counter delta = the resolve count.
- **AC-SMB-13** [GUT] *(TR-SMB-010)* — **GIVEN** the boot + epoch-change workloads on the `perf-soak` CI job (the reference SKU pinned at OQ-DR-3; warm-up ≥ 100 iterations), **WHEN** the budgets run, **THEN** the boot median of 1,000 boots ≤ 1 ms (parse+validate+derive only; CI admission excluded); the incremental p99.9 of 1,000 epoch-change deltas ≤ 0.1 ms (nearest-rank); zero per-tick seam lookups; the not-join is recorded; a failure fails the job + one telemetry record.
- **AC-SMB-14a** [GUT] *(TR-SMB-001)* — **GIVEN** the contract fixture, **WHEN** the shape audit runs, **THEN** `schema_version` present; step indices ∈ 0..3; zero hex literals; `tint` null|admitted; `visible_at_epoch_gte` derived; the array lengths match the span; `fixtures` is explicit (`[]` at MVP).
- **AC-SMB-14b** [LINT] *(TR-SMB-008)* — **GIVEN** the port/purity audit (scan root `src/seam/`), **WHEN** it runs, **THEN** the port list is exactly `TruthPort`/`RoomDataPort`/`SeamContractPort`; zero banned-symbol hits.
- **AC-SMB-15** [LINT] *(TR-SMB-011/012)* — **GIVEN** the hidden-passage probe (scan roots `src/seam/` and `src/world/`'s seam adapter), **WHEN** it runs, **THEN** zero seam interactables/interaction volumes/breakables; the full not-do list (no fade/wipe/dissolve/animation/seam interactable/no hex/no new `material_rule`/no SYS-02 zone split) is asserted.
- **AC-SMB-16** [GUT] *(TR-SMB-003/007)* — **GIVEN** a VS second flip and a mid-arc flip request, **WHEN** the seam resolves, **THEN** it persists epoch-invariant; the deferral materializes at the completion boundary; no partial band.
- **AC-SMB-17** [GUT] *(TR-SMB-006)* — **GIVEN** the hold fixtures (start/end), **WHEN** the render-state record is compared, **THEN** start = end; zero seam deltas; the seam is hold-blind (pre-arm hold detection is SYS-32's TR-CAM-013).
- **AC-SMB-18** [LINT] *(the traceability audit)* — **GIVEN** the GDD file (scan root `design/gdd/seam-borders.md`; parse the complete citation list inside each AC's `*(…)*` block; every `TR-SMB-*` and `F-SMB-*` identifier is recognized wherever it appears, not only at the prefix), **WHEN** the audit runs, **THEN** every TR-SMB-001..012 and F-SMB-01..07 is cited by ≥1 AC; the AC count = 32; the gate partition = 25+3+4+0.
- **AC-SMB-19** [DEVICE] *(TR-SMB-002/003/006)* — **GIVEN** the epoch-0 capture, **WHEN** it is diffed against the contract-deleted control and the enclosing hall's A-wall reference, **THEN** the band + wing are byte-identical; zero liminal pixels; the RM-03 tell renders; no seam key is asserted here (AC-02's GUT job).
- **AC-SMB-20** [DEVICE] *(TR-SMB-003/004/012)* — **GIVEN** the post-E4 capture and the load-sequence captures (epoch 0/1, first rendered frame), **WHEN** it is diffed against the grey-ramp golden, **THEN** the band = MID, the W/E step colors match, the fill's material keys are SYS-09's (membership; the row sampling is OQ-7), the adjacent-step delta ≤ 1 at the band boundary (no distinct edge), and repeated post-E4 captures hash-equal (static tint). The purple visual fallback is carried to OQ-1 (no admitted purple exists at MVP).
- **AC-SMB-21** [DEVICE] *(VR-SMB-09; the 2-second test)* — **GIVEN** the reveal framing at epoch 1 (B surround) and the epoch-0 A-wall, at 1:1 and the device scale, **WHEN** ≥5 cold viewers (no prior exposure to this build or design; not team members) run the forced choice A / B / neither + failure catch (door/portal/loading/unfinished/corrupted) on each wing row 11–16, **THEN** at epoch 1 ≥4/5 code "neither" (the liminal read), at epoch 0 ≥4/5 code "A" (the hall's A-wall; identifying it as A is correct), and zero code a failure read at either epoch; "stable" = each row's modal choice is the expected read and zero failure reads per row; κ is per-tester (SYS-01 AC-63); the referent rule is SYS-32's P3.
- **AC-SMB-22** [PLAYTEST] *(TR-SMB-012; the fantasy)* — **GIVEN** ≥5 eligible testers (entered the wing post-flip with the band+frame on screen, undirected), **WHEN** the coded rubric runs (SYS-01 AC-63; 3-of-5; κ ≥ 0.7; the referent rule), **THEN** ≥3/5 code `between/neither/quiet/held`; 0/5 code any seam-read token (`door/portal/loading/unfinished/secret passage/hidden`) or palette-identity token (`purple/glowing/different color/fifth color`); ≤2/5 code any incidental quality token (`broken/glitch/bug/out of place`); a failure re-runs the coded set with a fresh facilitator; top up if <3 eligible.
- **AC-SMB-23** [PLAYTEST] *(TR-SMB-006/011)* — **GIVEN** the free-play log, **WHEN** it is coded, **THEN** zero Interact presses in the seam region and zero unprompted "how do I open it" utterances; the seam is never treated as interactable.
- **AC-SMB-24** [PLAYTEST] *(TR-SMB-012)* — **GIVEN** the free-play log, **WHEN** it is coded, **THEN** ≥3/5 code grey continuity (`same grey/matches the corridor/blends`); 0/5 code any palette-identity token (`purple/glowing/different color/fifth color`); ≤2/5 code `out of place`; at MVP defaults the purple tokens are vacuous — the AC scopes to grey continuity (the purple's own gate is OQ-1).
- **AC-SMB-25** [PLAYTEST] *(the fantasy's framing C)* — **GIVEN** the pre-elicitation free-play log of all testers who reached the post-flip state with RM-03 accessible (entrants and non-entrants; both counts reported), **WHEN** it is coded, **THEN** ≥1 of ≥5 of that full population spontaneously mentions re-entering RM-03 post-flip unprompted; the evidence is never an elicited answer (the SYS-32 P3 elicitor is used only after the log); RM-03 is recognized by the referent rule (the cistern/backtrack room).

### Gate partition

| Gate | Units | ACs | Execution |
|---|---|---|---|
| **MVP smoke** | **25** | AC-SMB-01a…18 | 19 GUT + 6 LINT; headless GUT on the CI build (AC-13 on the pinned runner / separate perf job); the LINT scans run from source with the named roots/banned symbols |
| **MVP device** | **3** | AC-SMB-19, 20, 21 | Device matrix capture/diff (PR-DR-05's variant run extended to the band) + the 2-second read |
| **MVP-lock** | **4** | AC-SMB-22…25 | Playtest + coded rubric (SYS-01 AC-63 protocol) |
| **Art-pipeline bars** | **7** | the Acceptance bars table (value zoning, membership, coursing continuity, no spill, negative 2-second read, desaturate/saturate, static) | art-director-owned evidence at the art-bible/asset-pipeline capture (`production/qa/evidence/`); **not counted in the 32 AC units** |
| **VS** | **0** | — | The VS content (seam interact verb, epoch 2+, additional sets) is recorded, not AC'd |
| **Total** | **32** | | 25 + 3 + 4 + 0 = 32 |

**Exactly-one proof.** AC-SMB-01a…25 appear in exactly one gate each; the DEVICE-tagged ACs do not default home to smoke; the PLAYTEST ACs are MVP-lock. Counted: smoke = 25 (19 GUT + 6 LINT); device = 3; lock = 4; VS = 0; 25 + 3 + 4 + 0 = **32**. The seven acceptance bars are art-pipeline gates, not AC-SMB units; they do not change the 32 count. The QA plan expands the device/playtest protocols; this manifest is the GDD-side partition.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **The purple bridge's art-bible ratification** (OQ-RWS-7) — the grey ships; the purple closes at the art-bible pass. The pass also resolves the SYS-02 Player Fantasy line 36 conflict: ratify the purple, or amend the line + qualify the index row (the OQ-M1 pattern). | art-director + lead-programmer | At the art bible |
| 2 | **The AC-DR-15 key-level vs pixel-level reading** — the tint is a scalar modulation over the four `PROV_LIM_*` keys (key-level pass); a pixel-level reading fails any blended purple. SYS-09's owner countersigns before the first SYS-11 story; if pixel-level, the tint is false and the grey ships. | SYS-09's owner + technical-artist | Before the first SYS-11 story |
| 3 | **The band's inclusion in SYS-09's PR-DR-05/AC-DR-15 capture** — the band is outside the wing rect; the variant capture/audit must cover it (or a separate AC). Also the admission harness (OKLCH conversion, desaturate/saturate stress). | technical-artist + SYS-09's owner + tools-programmer | Before the first SYS-11 story |
| 4 | **The ramp's L gaps and the grief tint's C/L pin** — the P2 guarantee needs `gap_R ≥ 0.09`; the art bible pins the four L values, the grief C/L, and the grief hue band [330,20]. If the gaps are < 0.09, the D-gap clause relaxes to ≥ 0.01 or the tint closes. | art-director | At the art bible |
| 5 | **The frame's side offset and the band step at playtest** — `SEAM_SIDE_OFFSET` ∈ {−1, 0}; `SEAM_BAND_STEP` stays {MID} until a playtest signal (PALE is a pointing-device risk). | game-designer + QA | Gate 2 |
| 6 | **The fixture set and the south termination** — the wing's fixtures are `[]` at MVP; a future fixture joins the mask/hash + boot check. The south termination's visual note (terminal LIGHT continues, no ledge lip/exit notch/lit strip) rides SYS-09's next doc touch. | level-designer + technical-artist | The next room-data touch / SYS-09 touch |
| 7 | **The fill's row sampling** — SYS-09's TR-DR-003 keys per zone, not per row; the MID/PALE/PALE/LIGHT/LIGHT mapping is a proposed SYS-09 rider (the OQ-2/OQ-3 pattern) with an AC-DR-15 row-mapping extension. Until it lands, SYS-11's frame derives from `d` independently and the fill is SYS-09's membership-only. | SYS-09's owner + technical-artist | Before the first SYS-11 story |

**Carried obligations (recorded here, owned elsewhere — this GDD does not execute them):** SYS-02's line 36 rider (OQ-1) · SYS-09's key/pixel countersign (OQ-2) · the band capture + harness (OQ-3) · the ramp/grief pins (OQ-4) · the side offset/band step (OQ-5) · the fixture/south note (OQ-6) · the fill row-mapping rider (OQ-7) · the index row's material-only correction + the purple qualification (the completion sync).

**VS content recorded (not gated at MVP):** the seam interact verb (SYS-10's VS shift, OQ-RWS-5's neighbor) · a seam audio pass (a TR-JCE-027 revision) · epoch 2+ and the second flip's shape (SYS-10's) · additional mutation sets (the zone-mutation budget) · a future room's seam reuse (the span/array contract is general; the MVP's 11/5 is a fixture).
