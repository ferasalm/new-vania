# Design Review Log — SYS-02 Room & World Structure (MetSys)

> **Document**: `design/gdd/room-world-structure.md` · **System ID**: SYS-02 (Foundation, the canonical #6; the bottleneck gating SYS-09/10/11; SYS-32's hard upstream)
> **Session date**: 2026-11-13 · **Authoring session**: user + game-designer (GLM-5.3-Flash)
> **Review seats (fresh — the authoring session was not the reviewer)**: creative = GLM-5.3-Flash (game-designer agent) · technical = DeepSeek V4.1 Flash (systems-designer agent) · QA = DeepSeek V4.1 Flash (qa-lead agent) · **mandatory spot-check**: qa-lead (DeepSeek V4.1 Flash, fresh session) + re-verification (qa-lead, fresh session)
> **Engine/tooling verified before authoring**: Godot **4.7.2.stable.official.ed1daf0bf** (`godot_get_godot_version`) · `docs/engine-reference/godot/VERSION.md` (pinned 2026-11-04; knowledge-gap warning honored) · addon pinned: **Metroidvania System 1.6.1** (KoBeWi; the asset-library listing lags at 1.5 — the owned asset is 1.6.1; the addon targets Godot 4.6+, so 4.7.2 exceeds the floor; the **integration smoke-test gate is the GDD's AC-RWS-28**, per the risk row) · housekeeping: the stale opencode CLI (~655 MB) and the :28894 service confirmed gone; two live opencode processes (258/348 MB — the current sessions) left untouched.

## Round 1 — three-seat design review (whole document, fresh seats)

**Verdict: NEEDS REVISION (all three seats)** — creative 5 blockers (B1–B5) · technical 22 (T1–T22) · QA 12 (Q1–Q12) = **39 blockers**.

### The creative seat (GLM-5.3-Flash)

Confirmed strong: the named fantasy holds; the anchor moments are vivid; the flip/reveal/pocket triangle delivers the concept's promise; no filler rooms; the scope discipline is genuine; **zero consumed contracts misquoted or violated** (the pit pairing, the void bypass, the cap handoff, the label law, the derived window, the ADR §6 ruling all faithful).

| # | Blocker | Fix applied |
|---|---|---|
| B1 | The success signature certified a reveal in the **Courtyard** — the MVP's only mechanical reveal is RM-03's (the Cistern); the em-dash bound both clauses to a room with no new path | "the courtyard was wrong" → **"the cistern was wrong"** (aligned with The Wrong Corridor anchor, TR-RWS-015, AC-RWS-09) |
| B2 | The RM-05 Suture sat "in a tagged-wall shaft" but **no wall-jump verb ships at MVP** (Dash is locked) — a permanently dead promise, the anti-fantasy | The Suture re-pinned **on the shaft's floor, walk-in reachable at MVP**; the two climbable walls are the VS wall-jump surface (the shape-is-memory tease) — in the room table, TR-RWS-024, AC-RWS-03 |
| B3 | The reveal arc's duration was ratified-but-unenforced (V-RWS-13 bounded only `DOOR_OPEN_MS`) — the signature moment had no authored timing and could silently breach the derived 1200 | **`REVEAL_ARC_MS` 700 (400–1200)** authored (knob row + TR-RWS-009's declaration clause); **V-RWS-13 widened to every SYS-02-declared arc** |
| B4 | "Threshold" named two things (RM-01's room name vs the flip beat/the threshold log) — a live misdirection for the SYS-28 author | **RM-01 renamed "The Vestibule"** (room table + L1's epithet; "The Threshold" survives only as the anchor-moment heading) |
| B5 | E1 claimed to carry the MVP gate's ≥1-**spontaneous**-mention, but its elicitor leads with the topic — unverifiable spontaneity | The **pre-elicitation free-play observation clause** added to the protocol; the spontaneity evidence reads the free-play log, not E1's elicited tokens; the AC's parenthetical reworded |

Non-blocking notes adopted: the epoch-0 wing render clause ("sealed, never absent — never renders as a hole"); the skippable-threshold watch folded into OQ-RWS-1; the purple bridge routed to the art bible (OQ-RWS-7); the Five Goodbyes pillar tie; the `TRANSITION_BUDget_MS` casing and "hub-adjacent" stale label (repaired with the technical seat's findings).

### The technical seat (DeepSeek V4.1 Flash)

Independently recomputed and confirmed correct: all six Rect2s' *original* arithmetic, the camera-limit math, the 42-tick conversion, the admission, the pit economics, the doorway margin, the counts, the gate partition, and every consumed contract's fidelity. The blockers were structural, not arithmetic typos:

| # | Blocker | Fix applied |
|---|---|---|
| T1 (CRITICAL) | The authored coordinates produced **rooms that do not touch** — RM-02's east edge (1136) vs RM-03's west (1280) = a 144 px dead gap; flush adjacency was nowhere required; 4 of 6 rooms had no cell coords | **V-RWS-16 authored** (border adjacency + the pair law); the layout re-derived: middle rooms span the full cell width (40 tiles); every room got `cell_coord` + `local_rect`; all examples re-computed (RM-01 Rect2(160,0,480,272) … RM-06 Rect2(3200,0,640,352)) |
| T2 (CRITICAL) | "The corridor's tiles do not exist pre-flip" **contradicted** the byte-identical-geometry invariant | **"Sealed, not absent"**: the wing's tiles exist in both epochs, byte-identical; at epoch 0 it renders the hall's wall material, never a hole; the MVP's only geometry-affecting mutation is a border's *collision* state |
| T3 (CRITICAL) | The truth-border was **intra-room but modeled as an inter-room border**; the "east wall" was double-booked (the wing wall AND the RM-03↔RM-04 passage); an intra-room arc has nothing to swap | **The zone gate introduced** (`ZoneGateData`, SEALED/OPEN, no swap, the reveal arc = collision change + camera hold); the wing re-placed as an **interior** sub-zone (south partition, x∈[2,12)); the RM-03↔RM-04 border is the cell edge, untouched |
| T4 | `epoch_pin: 0` contradicted "all six rooms re-skin"; F-RWS-04 couldn't express the pin | TR-RWS-013 carved out ("all rooms re-skin **except** rooms with a non-null `epoch_pin` — exactly one at MVP"); F-RWS-04 gained `epoch_pin(zone) ?? epoch(tick)`; **V-RWS-17 authored** |
| T5 | Two detectors/two triggers for the swap (MetSys's border-walk request vs SYS-02's detector) — double-swap risk; the door arc's own motion would trip the detector mid-arc | **One owner**: SYS-02 detects; MetSys's request is consumed as a signal only; **ARCING suppresses crossing detection** (in TR-RWS-001/010, the FSM laws, AC-RWS-06/11) |
| T6 | The load budget didn't close: 50 ms ≈ 3 frames; plain walk-throughs have no frame to hide behind; a p99.9 over n=24 *is* the max (the printed example was arithmetically impossible) | **All six rooms resident** (the swap = activation, asserted ≤ 16 ms = one tick); `TRANSITION_BUDGET_MS` re-scoped to **non-resident first-entry loads** (the zone-2+ guard, behind an arc/pre-warm); the estimator pinned to SYS-01 QA §5.3's nearest-rank with n ≥ 1,000; F-RWS-07's numbers labeled **illustrative** |
| T7 | The document both asserted and denied the transition is a gate (law 4 + the ratification row vs TR-RWS-010) | "The room transition is **not a gate**"; TR-MOV-029 applies **only at true gates**; "the swap's only motion is the re-anchor — a position assignment, not integration" |
| T8 | The wall-clamp analog misquoted: Movement clamps **`v_x`**, not `v` | Quoted `v_x` as the analog; **`v_y` zeroing stated as SYS-02's own deliberate rule** (a crossing must not carry a fall), never attributed to Movement |
| T9 | "Combat's hit rule cancels the arc" — not a Combat rule; Movement has no lock-precedence rule either | Re-attributed: **SYS-02 cancels its own scripted move on a consumed `KnockbackOrder`** (a consumer, not an owner; over Movement's lock composition; no Combat rule invoked) |
| T10 | "The swap applies during a freeze" over-read TR-HD-028; the arc's clock domain was unstated | Struck from the ratification row (the crossing needs motion — held); the arcs' clock domain stated (**logic ticks, freeze-paused**, the resume completes the remaining duration, TR-MOV-024's analog) |
| T11 | The discovery set was misclassified as a derived target — it is not derivable from the other sources | **The fifth source family authored: `cells_discovered`** (SYS-02 owns the facts at MVP, SYS-25 the policy at VS) |
| T12 | The spawn-count string "2/2/1/0/1/0" contradicted the room table (true: RM-01 has 0) | Corrected everywhere to **0/2/2/0/1/0** (5 total, max 2/room) — in TR-RWS-005's test, AC-RWS-03, F-RWS-06 |
| T13 | Three knob ranges violated their own laws (`ROOM_MIN_TILES` floor (30,16) doesn't fit the view; the 48-tile ceiling exceeds the 40-tile cell; `CELL` floor 512 < the 40-tile room) | Ranges corrected (`CELL` 640–1024; `ROOM_MIN_TILES` (30,17)–(40,40)); the **pair law** joined V-RWS-16 |
| T14 | The not-join rested on "none to measure" — false (two per-tick predicates exist) | Restated honestly: **no dedicated per-tick gameplay loop**; the material read is an O(1)-per-zone keyed read, the crossings are physics-engine overlaps; the combined soak's measurement re-opens the envelope with a seventh row *if it attributes a delta* — recorded for OQ-RWS-6 |
| T15 | The reveal arc unbounded (dup of B3) + the declaration ownership misattributed to SYS-02 (TR-INP-029 assigns declarations to SYS-06+SYS-08) | `REVEAL_ARC_MS` + the widened V-RWS-13; reworded: **SYS-02 supplies the duration; Movement publishes the lock and the declaration** |
| T16 | TR-RWS-001 had no AC (the audit map's "001→25/27" was false) | TR-RWS-001 added to **AC-RWS-25's header**; the map corrected (final: 001→25/28) |
| T17 | The Courtyard pit was three mutually exclusive things (interior rect ∧ "bottom-left gap" ∧ void border) | **One mechanism**: the pit is an **interior floor gap** (the cistern shaft — the kill volume is an interior rect below the gap); the void border stays as the separate authored surface (F-RWS-05's branch b) |
| T18 | ARCING was a cached state in a derive-never-cache model; its entry row contradicted TR-RWS-008 (the door's arc begins at the ack, not a crossing) | **The model split**: the edge states are derived (LOCKED/OPEN; SEALED/OPEN); the arc is a **controller transient, never stored in the edge**; two entry rows (door: at the ack; zone gate: at the first crossing) |
| T19 | The tagged-wall ruling didn't say what `climbable` gates, and silently changed Movement's shipped wall-slide | **The tag gates wall slide and wall jump together**; the re-arm law's "different wall" = a different *tagged* segment; the **recorded one-clause TR-MOV-014 rider** (the OQ-M1 pattern — before the first wall-jump story) |
| T20 | `doors_opened` write timing inconsistent in three places (post-placement prose vs "at the ack") | **The write is at the ack** (matching AC-RWS-06); the mid-arc press edge rewritten: **no prompt is lit during the arc** — the press expires on its stamp tick (TR-INP-030) |
| T21 | F-RWS-03's expiry was one tick early (a 42-tick lock starting at T is busy through T+41, free at T+42) | "The arc's last busy tick is T+41; the body is free at T+42's tick-open"; the swap = **T+21 (the arc's 22nd tick)** |
| T22 | F-RWS-08's exception sentence was self-contradictory ("except RM-06, which satisfies both") | "All six satisfy the first clause (RM-06 satisfies both); the framing-zone branch is exercised by the fixture, not an MVP room" |

Non-blocking notes adopted: `BorderData`/`FramingZone`/`ZoneGateData` field schemas authored; the `doors_opened` id space pinned to `border_id`; V-RWS-06 reworded to config-record validation (the runtime non-decrement lives in TR-RWS-014); V-RWS-02's resolution unified; F-RWS-02's slack floor-specified; SYS-17 moved from non-dependencies to the placements row; "the world event class" reworded to TR-HD-028's own class; TR-RWS-011's heading fixed; the flag/epoch two-source chain clarified (materials derive from the epoch only); `last_grounded_safe_pos` made room-scoped + swap-reinitialized; the trace schema defined; the doorway width assumption recorded (the stand width pins ≤ 24 at the art pass); the 5th-refusal defence-in-depth note; the registry additions queued (the deliverable below).

### The QA seat (DeepSeek V4.1 Flash)

Independently re-counted everything: the top-line counts and the gate partition were **correct** (27/8/15/32 + 27+3+2+0, the exactly-one proof sound, every tag matched its gate) — the defects were in the per-room string, the audit map, and test falsifiability:

| # | Blocker | Fix applied |
|---|---|---|
| Q1 | The layout counts wrong in three places (dup of T12) | 0/2/2/0/1/0 everywhere + the per-room ≤ cap check |
| Q2 | AC-RWS-27's traceability map had false citations (010→11/26 dropped AC-30; 001→25/27's 27 uncited; 009→09 missed AC-08) | The map regenerated **mechanically from the AC headers**; final: 001→25/28 · 009→08/09 · 010→11/26/30 · 011→12/34 · 020→19/33 |
| Q3 | The reveal arc had no duration/formula/bound and AC-09 asserted only "the world waits" | `REVEAL_ARC_MS` + F-RWS-03 extended + V-RWS-13 widened; AC-09 now asserts the 42 ticks, the no-swap, the framing trigger, the velocity zeroing, the no-prompt audit |
| Q4 | The load-budget statistic was undefined (p99.9 of n=24) | The tour pinned (24 border transitions, the route printed); the estimator pinned (SYS-01 §5.3, n ≥ 1,000); the **slow-port overflow fixture** named; F-RWS-07's numbers labeled illustrative |
| Q5 | E1's spontaneity unmeasurable + 2 accept tokens echoed the elicitor | The operational spontaneity definition (the pre-elicitation free-play log); "went back"/"found a path" **removed** from E1's accept set; the concept-gate citation named (game-concept.md, MVP Definition) |
| Q6 | E1's eligibility was "all testers" — non-backtrackers scored as failures | **E1 eligible = reached RM-04 ∧ re-entered RM-03 post-flip; < 3 eligible → the run is invalid and topped up, no fallback**; the session budget "≥ 30 min from the threshold" |
| Q7 | Three ACs asserted outputs with no port to emit them (the bounds publication; the refusal telemetry) | **`BoundsPort` + `TelemetryPort` authored** (8 ports total); AC-04/11 assert the mock's recorded bounds; AC-07/15/26/33 assert the telemetry count; AC-25 gained the **port-coverage assertion** |
| Q8 | V-RWS-02 had two resolutions and no AC; V-RWS-08 had no AC; AC-13 asserted a render in a headless gate | One resolution (boot failure; the intent-annotation → recorded warn) + the 24 px fixture in AC-RWS-22; the V-RWS-08 negatives (a SPIKE kind + a bound-crossing rect fail the boot) in AC-RWS-14; AC-13 restated **at the data level** |
| Q9 | AC-25 (smoke) depended on the live addon (the device gate's job) | AC-25 is **fake-port-only**; the mock ≡ live-addon equivalence moved to **AC-RWS-28** |
| Q10 | AC-29's pass condition was unfalsifiable ("no frame spike beyond the freeze's own hold") | Pinned: the re-material work ≤ `REMATERIALIZE_BUDGET_MS` (100) measured in the freeze; the per-room programmatic palette assertion; the six-screenshot evidence set under `production/qa/evidence/` |
| Q11 | The Suture full-slot refusal (a loss mode) was prose-only | **AC-RWS-33 authored** (the pickup's grant + the full-slot refusal) |
| Q12 | OQ-RWS-4 was a blocker in disguise (the pit + the module revive = a soft-lock loop) | Promoted to a **release-gate condition**: the pit and the revive must not co-ship unratified; on the QA plan's S1 list |

Non-blocking notes adopted: AC-12 split (the load axis stayed AC-12; the reconstruct axis became **AC-RWS-34**); AC-14's `raw_damage` written as `hp_max` "(100 at the default profile)"; the T+21 0/1-based ambiguity resolved ("the 22nd arc tick"); the casing fix; F-RWS-08's contradiction (T22); the SYS-01-resolution assertions scoped to the published set; the trace schema (T-adopted); AC-28's "D1" expanded (ADR-0001 R6 named); the arena's `epoch_pin` asserted in AC-03; V-RWS-04's exactly-one fixture; OQ-6's target gated to the first SYS-02 story's sprint.

## Round 2 — the mandatory qa-lead spot-check (fresh session)

**Verdict: FAIL — 9 defects** (3 at the claimed repair sites, 6 new). The spot-check re-derived everything independently and verified 11 of 14 repair sites clean on first pass (the layout arithmetic, the wing's interior placement, the zone-gate/border split, the arc timing, the epoch pin, the swap mechanics, the hazard, the five sources, the knobs, the playtest rules).

| # | Defect | Fix applied |
|---|---|---|
| S1 (site 12/14) | **AC-RWS-33 and AC-RWS-34 were cited five times but never defined** — dropped in the revision's rewrite; the coverage line, the gate manifest and the exactly-one proof were false against defined ACs | Both ACs authored (the Suture pickup; the reconstruct axis) — inserted as the "pickups and the reconstruct" block after AC-27 |
| S2 (site 9) | The citation map's `027→26/27/28/29/30` included AC-27 (which carries no TR in its header); `04→08/09/10/29` included AC-10 (whose header then lacked F-RWS-04) | The map corrected to `027→26/28/29/30`; **F-RWS-04 added to AC-RWS-10's header** (the derivable path) |
| S3 (site 13) | The Cold Corridor wing's **px rect never existed** in F-RWS-01 — the framing zone's published rect had no source | Appended: local (2,11) → `Rect2(1312, 176, 160, 96)`; named as `reveal_cistern`'s framing rect |
| S4 | **The partition and the wing occupied the same tile row** (a y=11 partition leaves the wing 10×5, not 10×6) | The partition moved to **y=10 (a one-tile row)**; the wing stays y∈[11,17) = 10×6 = 160×96; all downstream numbers hold |
| S5 | The "24-transition tour" listed **23 transitions** (24 nodes) | One transition appended (the list now 25 nodes = 24 border transitions) in AC-RWS-26; F-RWS-07's reference now accurate |
| S6 | `TRANSITION_BUDget_MS` casing survived in F-RWS-07 | Corrected to `TRANSITION_BUDGET_MS` (grep-clean: 7 occurrences) |
| S7 | `max_epoch` in V-RWS-17 was never defined | The **`max_epoch` knob row authored** (1, fixed at MVP) |
| S8 | AC-13 cited V-RWS-17 (at-most-one) for an exactly-one claim | Re-attributed: "exactly one pinned room — TR-RWS-013's authoring, bounded by V-RWS-17" |
| S9 | `TRUTH_BORDER` survived as a live inter-room epoch-derived kind (tested by AC-05) contradicting the zone-gate split | **Demoted**: removed from `BorderData`'s kind union (`DOOR\|PASSAGE`); AC-05 tests only the live kinds; TR-RWS-007 marks it VS-reserved; the VS content list records it |

## Round 3 — the re-verification (fresh session)

**Verdict: CLEAN.** All nine repairs verified with independent recomputation: the 34 AC headers (no gaps, no duplicates), the gate arithmetic 29+3+2+0 = 34 against defined ACs, the **entire citation map re-derived mechanically from all 34 headers with zero residual mismatch** (all 27 TR entries + all 8 formula entries), the wing conversion (1312/176/160/96 ✓, flush-checked), the partition/wing rows disjoint, the tour's 24 arrows counted, the casing grep-clean (7 correct occurrences), `max_epoch` evaluable (0 ≤ 0 ≤ 1), the at-most-one/exactly-one distinction, and the TRUTH_BORDER demotion at all four sites.

## Final state

- **Counts**: 27 TR-RWS · 8 formulas · 17 V-RWS · **34 ACs** (smoke 29 + device 3 + lock 2 + VS 0 = 34) · 2 playtest codes · 8 OQs — all machine-verified.
- **The GDD is gate-ready**; the Movement OQ-2/3/5 rulings, the SYS-13 spawner-surface landing, the ADR §6 no-new-row ruling, the envelope not-join, and the MetSys layer ruling are all printed with their row amendments queued for the systems-index sync.
- **Review debts: none.** Every blocker from every seat is closed in this log; the carried obligations (SYS-08 OQ#7, SYS-07 OQ#1/#2/#3, SYS-01's proven-140, Movement OQ-M1..M4, SYS-13's OQ-ENM-1..8, the SYS-29 amendments) are recorded in the GDD's carry block, owned elsewhere, not executed here.
