# Audio Core

> **Status**: APPROVED (2026-11-15 — the audio-director's countersign; PR #46's recorded condition closed); **rider applied 2026-11-15 by D-ORCH-03** (the IP-17 baseline: F-AUD-03's examples and AC-AUD-08's fixtures re-derived — the band boundaries are symbol-anchored, so they moved with the arcs)
> **Author**: sound-designer (lane SYS-04; audio-director countersign pending)
> **Last Updated**: 2026-11-15 (the D-ORCH-03 baseline rider; previously 2026-11-14)
> **Last Verified**: 2026-11-14 (contracts read at `origin/Main` `e8b194d`)
> **Implements Pillar**: "One World, Two Truths" (primary) · "Read, Then Strike" and "Remade Every Death" (supporting)

> **Contracts**: SYS-09 `design/gdd/dual-reality-state.md` (APPROVED gated on S1-007) — the Flip-Trigger Contract **TR-DR-004 consumed verbatim** (E1–E7 + G1–G7; `ambient_shift` pinned to `epoch_swap`'s tick with the receding-first hold; the beat-aligned tear hook at τ0; `freeze_open`/`freeze_close` as the stillness brackets; `flip_complete` as the resume), the arena's steel-hum expectation (TR-DR-011), the liminal wing (TR-DR-012), the audio interaction row (downstream, contract-first), AC-DR-27; SYS-10 `design/gdd/world-mutation-epochs.md` (APPROVED 2026-11-14 — the batch co-review pilot; S1-002b) — E3b `ambient_shift` is **SYS-10's emission** pinned to `epoch_swap`'s tick, the **abort case** (`freeze_open` fires, E3/E3b/E4 never do, the bed stays put), the latched-resume rider (i), AC-WME-07; SYS-29 `design/gdd/juice-feedback.md` (APPROVED 2026-11-13) — **TR-JCE-027** (the closed audio edge list + the single death-duck request `{bus, dB, hold}`, `DEATH_DUCK_DB` −6 provisional, OQ-J7), TR-JCE-018 (the death sting publishes no audio edge), TR-JCE-021 (the memory chime is audio-led; the Leap-Stone grant reuses it), AC-JCE-31/32; SYS-11 `design/gdd/seam-borders.md` (APPROVED 2026-11-14) — **AR-SMB-01..04** (zero audio publications; the bed continues; the no-duck ruling; M4's chime is not the seam's); SYS-07 `design/gdd/health-damage.md` — `DamageNumber`/`HealEdge`/`DeathEdge`+`DeathRecord`/`DefeatEvent`; SYS-08 `design/gdd/combat.md` — TR-CMB-021/022/023 (the clash pair, the hit-stop pairing, no per-press chatter); SYS-02 `design/gdd/room-world-structure.md` — the six-room fixture (RM-01..RM-06; RM-06 is the pinned arena) + the room activation; SYS-24 — the settings surface renders SYS-04's a11y knobs; ADR-0001 §3 (the freeze) and §5 (the tick boundary) consumed. **The concept's 2026-11-14 expansion (D-1/D-3/D-7) is consumed as scope: the Stinger, the demon grant, the Warden drop, and the low-stat baseline are named in §C.3 and §K.3.**

---

## A · Overview

Audio Core is the ear's half of the truth contract. SYS-02 stores the world's word, SYS-09 renders it, SYS-10 changes it — and this system is where the change is *heard*. It owns every sound the player perceives: the buses and the mix, the ambient beds, the closed one-shot vocabulary, the flip's sound composition, the single duck request's execution, the import settings, and the mobile budget. It publishes no gameplay or state event to any other system; it is a leaf consumer, and that is deliberate — a sound that another system had to wait on would be a sound that can stall the world. (Two read-only surfaces are the exception: the tuning read SYS-24 consumes for the settings sliders, and the event-metadata read the caption layer may consume; both are ports, not events — §G.8.)

The system's whole design is three laws.

1. **The world's truth is heard, never announced.** The flip gets no fanfare, no stinger, no rise. At the tear the old air draws in and the new air is not yet there; the arriving bed's first audible sample is at the release boundary, never earlier. The bed turns over *under* the tear. What the player learns is that the world sounds different, not that a sound effect played.
2. **The mix never performs.** Exactly one duck request exists in the entire game: the death beat's −6 dB on the music bus, held until the offline screen exits. There is no hit-stop duck, no flip duck, no seam duck, no reveal-hold duck, no pause duck. A 300 ms duck at the flip is a sweep, not a beat (SYS-09's ruling) — and a mix that flinches at every punctuation is a mix the player stops believing.
3. **The closed list.** Ten SYS-29 edges (eleven one-shot voices — the clash pair carries two components) plus the flip's own tear. No per-press popups, no "ORDER RECEIVED" voice, no menu clicks, no stochastic ambience one-shots at MVP. If no system asked for a sound, the sound does not exist; the static audit is the proof.

Two places are load-bearing exceptions, and both are silences of a kind. The **arena** (RM-06) keeps its steel hum at both epochs — the one room whose bed the flip never orders, because if the bed shifted the pristine lie would break at the ear. The **liminal wing** gets nothing: RM-03's bed continues across the threshold and through the wing, no crossfade, no filter sweep, no layer add, no reveal sting (AR-SMB-02) — the corridor's audio identity is the absence of a change, and M4's chime, if it fires there, is the memory's edge by consequence, never the seam's.

**What this system never owns.** The flip's choreography and timing (SYS-09's), the epoch state and its write (SYS-10's), the event edges' publication (SYS-29's), the seam's material (SYS-11's), the score's composition (the audio-director's, via the sound bible), the settings UI (SYS-24's), any input, save, render, or camera surface. The audio core is **epoch-blind**: it never reads `truth_epoch`; it consumes E3b and nothing else. It is a pure `RefCounted` over injected ports, and the edges arrive at the node adapter, never through the core.

**MVP scope (minimal).** Four child buses under Master; three ambient beds (the A house bed, the B house bed, the epoch-invariant arena steel hum); one score loop; thirteen one-shot voices; one mix snapshot; one duck family; a twenty-voice hard cap on the Pixel 6a reference SKU. The content is minimal on purpose: the contract is the deliverable, and the palette is the sound bible's.

---

## B · Player Fantasy

You learn the house by its hum before you learn it by its shape. The first rooms have one air — a machine air, steady, a little too clean — and you stop hearing it the way you stop hearing your own breathing. Then the log closes, the panel goes dark, and the air *draws in*. Not a sting, not a chord: the old hum recedes the way a room goes quiet when everyone in it turns to look at you, and for the length of a held breath there is almost nothing — the tear, and your own music still playing, because the score was always yours and the air was always hers. Then the new air arrives, and it is warmer, and it is wrong, and the room's shape has not moved at all. You are standing in the same place. You have never been here.

That is the fantasy this system serves: **the truth is audible, and it never announces itself.** You are never told the world changed. You hear it change, one room at a time, and the recognition does the work — the same silhouette, a different breath.

The arena is the ear's proof of the lie. You walk in and the hum is *the same hum* — the steel, the perfect steady steel, the one bed in the whole house the flip never touches. Everything you crossed to get here sounds wrong now; this room sounds exactly right. She is standing in a world that never changed, and the ear confirms it before the eye has finished arguing. The corridor is the other proof: you cross the threshold and nothing happens — no crossfade, no filter, no sting — because the one honest place between the truths is the one place the world stops arguing. The silence of the seam is its signature, and it is the only signature it is allowed.

And death is the only time the music steps back. Not the world — the world keeps humming, the house goes on without you, that is the point — but the score bows out, six decibels down and held, and the shape of where the music was is the shape of the loss. You draw the module, or you reconstruct at the terminal, and the score comes back up under the boot. Nothing else in the game is allowed to move the mix like that. The ear is never lied to: one death, one duck, one release.

*Pillar ties: "One World, Two Truths" (the truth is heard, never announced) · "Read, Then Strike" (the edges are the fight's punctuation, never a per-press chatter) · "Remade Every Death" (the death duck is the only mix gesture in the game).*

---

## C · Contracts Consumed

This system composes against the Flip-Trigger Contract, the SYS-29 edge list, and SYS-02's room activation — and **nothing else**. No edge is added, removed, or re-timed; a change to any consumed edge is a contract-revision request (the `decisions.md` route), never a silent edit.

### C.1 · The E1–E7 table, with the audio obligation

Defaults: N = 18 (`FLIP_FREEZE_MS` 300 at 60 tps); the fixture's R = 100, τ0 = 101, the release boundary 118→119, E7 = 119.

| # | Edge | Fired at | Publisher | **Audio obligation (SYS-04)** | Audible result | Forbidden at this edge |
|---|---|---|---|---|---|---|
| E1 | `flip_begin` | R | SYS-09 | **Arm silently**: validate the bed table, make **all three beds** and the tear resident, build the order record | none | any pre-telegraph cue, any bed order, any duck |
| E2 | `freeze_open` | τ0 boundary | SYS-29 (`active_sources` gains `truth_flip`) | **Open the stillness bracket**: close the gameplay one-shot gate (**drop, never queue**); no loop restart; no snapshot change; no duck | the bracket opens | duck, loop restart, stinger |
| E3 | `epoch_swap` | τ0 | SYS-10 | **No direct obligation** — the audio core never reads `truth_epoch`; it consumes E3b | none | any audio read of the epoch |
| E3b | `ambient_shift` | τ0 (pinned to E3) | SYS-10 | **The receding-first order** (§D.2): target set = RM-01..RM-05 exactly; excluded = RM-06; `to_epoch` selects the arriving bed (CR-AUD-01; the MVP default 1); the sounding bed's recede begins at τ0; the arriving bed's first audible sample ≥ the release boundary; zero arena-bed orders | the old air draws in | arena-bed orders; any arrival before E6; any order before τ0 |
| E4 | `rematerial_done` | R+1 frame | SYS-09 | **Sync point only** — no sound keyed to E4; the tear is already sounding | none | a second tear hit |
| E5 | `glitch_window` | [τ0, τ0 + 26) | SYS-29 | **The tear layer** (§D.4): the beat-aligned transient at τ0 + the body through the window + the 120 ms decay tail; the flip's only one-shot; the reserved voice. **Abort path**: the degenerate form (no transient, no success beats), the tail runs | the tear | any second one-shot inside the window |
| E6 | `freeze_close` | 118→119 boundary | SYS-29 | **The release boundary**: the gate lifts; the arriving bed **may** begin (never before; for the room the player occupies at the release boundary — the arena gets none, edge case #1); the arrival fades in | the new air arrives | any arrival before this tick; a release stinger |
| E7 | `flip_complete` | 119 | SYS-09 | **Resume**: the gameplay one-shots resume; the arrival fade continues as a voice envelope to `arrive_end` (134) | the world is other | a completion sting/fanfare |

### C.2 · The guarantees as consumed

- **G1 atomicity** → the audio sees one order, at one tick. There is no partial shift to hear.
- **G2 monotonicity, single-shot** → the tear latches once per landed flip; the latched-resume re-run replays the same order trace from R′ (§D.5). Re-reading the log emits zero flip edges and therefore zero audio orders.
- **G3 deferred-but-invisible** → the arm happens once, at R, after every deferral resolves. The audio never observes a stretched sequence.
- **G4 re-material inside the freeze** → the recede and the arrival are keyed to the bracket and the release boundary, not to E4's render timing.
- **G5 pin and reveal integrity** → the arena's bed is untouched; the wing's *material* is untouched, and acoustically the wing resolves to RM-03's bed, which turns over like every non-arena room's (§D.6, §F.3).
- **G6 photosensitivity** → the audio carries no flash and no strobe; `REDUCED_FLASH` changes no audio edge and no timing (the audio is flash-blind).
- **G7 totality and order, fire-once** → the **edge trace** asserts exactly one observation per edge per run; the **order trace** asserts exactly one `ambient_shift` order per run (the record is E3b's; the seven-edge assertion lives on the edge trace — §G.8).

### C.3 · The closed list, the two seam rulings, and the three named silences

- **TR-JCE-027's ten edges** (eleven voices — the clash pair) are the entire gameplay one-shot vocabulary; the flip's tear is the twelfth and thirteenth voice (§E). Zero UI voices; zero stochastic ambience one-shots at MVP.
- **SYS-11 publishes zero audio** (AR-SMB-01). Its rulings are consumed as law: **the bed continues** across the seam threshold (AR-SMB-02); **no duck** on the seam or the reveal hold (AR-SMB-03); **M4's chime is not the seam's** — if it fires in the corridor it is TR-JCE-021's edge by consequence (AR-SMB-04).
- **The flip publishes no duck** (SYS-09's ruling: a 300 ms duck is a sweep, not a beat).
- **The three named silences** (the 2026-11-14 expansion's beats; each is a decision, not an omission, and each names its revision route — if a Gate 2 probe codes one of these beats unnoticed, the response routes through the same TR-JCE-027 revision, never an ad-hoc voice):
  1. **The Stinger lunge** (D-3): no voice of its own at MVP. The lunge is silent; its *impact* is carried by the existing damage/defeat/clash edges. A swing or lunge voice is a TR-JCE-027 revision.
  2. **The demon-grant moment** (D-3's grant story beat, SYS-05): no audio edge at MVP. It is a narrative presentation beat (SYS-05/28's surface); a bespoke grant voice is a TR-JCE-027 revision, and the memory chime is **not** reused (it means memory, not power).
  3. **The Warden drop** (D-1): no voice at MVP. It is a gear drop, not a memory pickup; TR-JCE-021's chime does not cover gear. A pickup voice is a TR-JCE-027 revision — the sound-bible pass may request it; the Gate 2 gear beat is the concept's noticed-and-equipped probe, and no channel is pinned for it.

### C.4 · The requirements

- **TR-AUD-001 — Consume E1–E7 verbatim.** The composition surface is SYS-09's table and nothing else: no edge added, removed, or re-timed; the audio obligation at each edge is the one printed in §C.1. A change is a contract-revision request. *Test: the **edge trace** equals the published set exactly, in order, once per run; the **order trace** contains exactly one `ambient_shift` record per run; a diff of the consumed edge names against TR-DR-004 is empty.*
- **TR-AUD-002 — The publisher map; SYS-04 publishes no gameplay or state event.** E1/E4/E7 are SYS-09's; E2/E5/E6 are SYS-29's; E3b is SYS-10's; the room activation is SYS-02's; the load-complete is SYS-03's (its payload carries `restored_epoch` — CR-AUD-02's request). The core subscribes at the node adapter and emits no cross-system gameplay/state event. The two read-only surfaces (the tuning read for SYS-24, the event-metadata read for captions) are ports, named in §G.8's allowlist. *Test: the adapter's subscription list equals the publisher map; a grep for cross-system calls from `src/audio/` matches only the allowlist.*
- **TR-AUD-003 — Epoch-blindness.** The audio core never reads `truth_epoch`, the mutation registry, or any truth flag; it consumes E3b and the E-edges only. The MVP's monotone 0→1 assumption is a **config constant** (`MVP_FLIP_TO_EPOCH = 1`, boot-validated), not a state read, and it is removed when CR-AUD-01 lands. *Test: the static audit finds zero truth-state symbols in the core; a stubbed-bed run produces the identical order trace with the truth state replaced by a poisoned sentinel.*
- **TR-AUD-004 — The closed list is closed.** The only one-shot emissions are the thirteen voices of §E; zero UI voices, zero per-press popups, zero stochastic ambience one-shots. *Test: the runtime registration scan and the static audit both find exactly thirteen registered one-shot IDs; a menu press emits nothing.*
- **TR-AUD-005 — The death duck is consumed, not designed.** `duck_request {bus, dB, hold}` with `bus ∈ {MUSIC}`, `dB ∈ [−12, 0]`, `hold ∈ {UNTIL_OFFLINE_EXIT}`; `DEATH_DUCK_DB = −6` (ratified, §H.3); published once per death; released on the offline exit (reconstruct or revive). *Test: the fixture publishes exactly one request and one release per death; the request's three fields are the only fields.*
- **TR-AUD-006 — The missing-input failure paths.** Each consumed input names its owner and its failure: a missing edge never produces a silent default. The paths are §G.8's table. *Test: each injected omission produces its named record and its named behaviour; no omission produces a synthesized substitute.*

---

## D · The Flip's Sound

### D.1 · The state machine

| State | Entered | The audio graph | Exits |
|---|---|---|---|
| `IDLE` | nominal gameplay, or the E6-lost failsafe's exit — the one exception to the nominal-gain graph: the receded bed holds at the floor until the next room entry re-applies the room's bed (§G.8) | the room's bed at nominal gain; the score playing; the gate open | E1 → `ARMED` |
| `ARMED` | E1 (R) | unchanged, audibly; the bed table + the tear resident; the order record built | E2 → `HELD`; E2 lost → the gate failsafe (§G.8) |
| `HELD` | E2 (τ0) | the gate closed (the failsafe opens it from outside — the E6-lost path); the sounding bed's recede running (if in the target set); the tear sounding | E6 → `RELEASED`; the abort's force-release → `DEGRADED` — **precedence: the force-release wins**; the E6-lost failsafe → `IDLE` (§G.8's recovery: the gate opens at `GATE_FAILSAFE_MS` only if E6 has not arrived by that tick — **E6 wins the deadline**; the receded bed holds at the floor, the arrival never starts); the derived E6 closes the bracket as an event, never as a state transition |
| `RELEASED` | E6 | the gate open; the arrival fading in; E7 marks the gameplay resume (the fade continues as a voice envelope) | `arrive_end` (134) → `IDLE` |
| `DEGRADED` | the abort's force-release | the gate open; zero orders; the degenerate tear + tail | the tail clears → `IDLE`; the resume's R′ ≥ the tail-clear (SYS-10's rider (i)) |

**The clock law.** Every flip-scoped audio *envelope* (the recede, the arrival, the tear's decay, the duck) runs on the **wall clock** (`physics_tick`, ADR-0001 §5) — the logic clock stalls inside the freeze, and an envelope must not freeze mid-decay. Every voice's *start tick* is the publisher's tick, on the publisher's clock: the clash midpoint is +21 **logic** ticks (SYS-29's publication, SYS-08's sparks); the damage/deflect/heal/death/defeat edges are logic-tick stamped; the flip's edges are wall-tick stamped. The duck spans the death→offline transition, where the logic clock does not run — hence the wall clock.

### D.2 · The receding-first law (AR-AUD-01)

Seven clauses, all testable:

1. **Pinned.** The order's tick equals E3's tick (τ0 = 101 at the fixture). A one-tick drift fails.
2. **The target set is the non-arena rooms exactly.** `target_rooms = {RM-01, RM-02, RM-03, RM-04, RM-05}`; `excluded = {RM-06}`. The set is carried in the order record, so the assertion holds even when only one bed is sounding.
3. **Zero arena-bed orders across [E1, E7].** `AMB_ARENA_STEEL_HUM` appears in no order, ever.
4. **The recede begins at τ0, never before.** The first audio-graph motion is the sounding bed's gain ramp at τ0 (not at R). It is a **per-voice ramp**, never a `duck_request` — a duck here would break the one-duck audit.
5. **The recede completes inside the bracket.** `AMB_RECEDE_MS` = 240 (15 ticks, 250.0 ms). At the default freeze (N = 18) the bed holds at the floor for 3 ticks (50 ms) before the release boundary; an admitted extension lengthens the hold, never the recede; a shorter freeze compresses the ramp via `min(recede_ticks, N)`. The ramp is **linear in gain** to `AMB_RECEDE_FLOOR_DB`.
6. **The arrival is no earlier than the release boundary.** The arriving bed's first audible sample is at tick ≥ R+N+1 (119 at the fixture); no pre-roll, no crossfade tail before it. Fade-in `AMB_ARRIVE_MS` = 240 (15 ticks, 250.0 ms), **from the floor to nominal, linear in gain**.
7. **The abort case: the bed stays put.** E3b absent → zero orders, zero recede, zero arrival; the bracket opens at E2 and closes at the force-release-derived `freeze_close`; the tear's degenerate layer runs; the world stays truth A and the ear agrees.

*The fixture (AC-DR-04's timeline):* arm at 100 · bracket + recede + tear at 101 · the recede ends at 116 · the floor hold 116→119 · the arrival 119→134 · full B bed at 134 · no arena order anywhere in [100, 134].

*Composition note:* the tear's transient at τ0 masks the recede's first motion — the bed is never heard "starting to fade", only "already going". That is why the recede is safe at τ0 and would not be safe at R.

### D.3 · The freeze brackets (AR-AUD-02)

- **The bracket** = `[E2, E6)` = 18 ticks = 300.0 ms at defaults; moved only by an admitted extension.
- **The gate**: gameplay one-shots **drop, never queue**. A queue would replay stale sounds at release — a burst; a drop is honest. Counter + telemetry. A room-entry request inside the bracket is dropped with the rest; the mismatch persists to the next room entry (K.2 #14).
- **The licensed exception**: the flip's own tear at τ0. The bracket forbids *foreign* one-shots, not the event itself. E5's τ0 sits inside the bracket; the reconciliation is named here, not implied.
- **Loops**: no restart, no loop-point jump. The only loop-graph motion is the sounding bed's recede.
- **No snapshot change that reads as a beat**: zero mix-snapshot changes across [E1, E7]; the score is untouched (no stinger, no score duck, no transition).
- **The freeze is not a duck**: zero duck requests in the window.
- **Already-sounding voices ring out** — never truncated (a cut is a click and reads as a bug). The tear's 120 ms tail lies inside the E5 window, which extends 8 ticks past E6; the tail may therefore ring past E6 while the gate is open — concurrency is legal.
- **Abort**: the same rules; the bracket closes at the force-release-derived `freeze_close`; zero bed orders; the state precedence is §D.1's.

### D.4 · The tear layer (E5)

- **The success tear** (`EV_FLIP_TEAR`): the beat-aligned transient at τ0 + the body + the 120 ms tail; `TEAR_DURATION_MS` = 400 (24 ticks, 400.0 ms), inside the 26-tick window with 2 ticks of slack. The "beat" is the game's tick grid (60 tps): τ0 is event-driven (the Reading's close), so the transient is **meter-agnostic** — designed to land on any score phase without reading as a stumble. The score is not re-timed or quantized (OQ-AUD-2's ratified reading).
- **The abort tear** (`EV_FLIP_TEAR_ABORT`): the same body and tail, **no transient, no success beats** — the fault that did not take. It is a distinct event ID so the trace can assert the degenerate form.
- **The reserved voice**: the tear is P0; it is never stolen; at most one per run (the latch).
- **Asset failure**: if the tear asset is missing, the flip is **silent** (the beds and the score continue) and one error record is written; the audio never blocks the choreography.

### D.5 · The latched resume (rider (i))

The resume re-arms at R′ and re-runs E1–E7 for the same logical flip. The audio: the bed is still the A bed (it never moved on the abort); the second run's E3b, if it commits, executes AR-AUD-01 identically; **the post-resume order trace hashes identically to the fresh flip's** (F-AUD-06), compared from the resume's raise tick. The abort's degenerate tear is the declared offset; the compared span starts at R′.

### D.6 · The arena and the wing

- **The arena (RM-06)** keeps `AMB_ARENA_STEEL_HUM` at both epochs — one asset, epoch-invariant, never ordered. If the player stands in the arena during the flip (the long-deferral chain), the hum continues untouched; the tear layer is global and plays (the world tears around the untouched room — the seam is the point). Zero bed orders either way. The Gate 2 session script names this state so it is never coded as breakage.
- **The wing** is a rect inside RM-03, not a room and not an audio zone: RM-03's bed turns over at the flip like every non-arena room's, and the wing has no separate bed, no separate layer, and no treatment. Its "never touched" is **material**, not acoustic; the acoustic no-op is the **seam crossing** (AR-SMB-02: no crossfade, filter, layer, restart, or sting when the player crosses the threshold or walks the wing). M4's chime, if it fires, is TR-JCE-021's edge by consequence (AR-SMB-04). The material/acoustic split is a **named ruling**, countersigned by the audio-director at this document's approval.

### D.7 · The requirements

- **TR-AUD-007 — The arm is silent (E1).** At R the core validates the bed table, makes all three beds and the tear resident, and builds the order record. Zero audible change; zero pre-telegraph. *Test: the R→τ0 interval's audio-graph delta is empty; no voice starts at R; all three beds and the tear are resident by τ0.*
- **TR-AUD-008 — The receding-first law (E3b).** AR-AUD-01's seven clauses, with the order record carrying `{tick, edge_id, to_epoch, target_rooms, excluded, recede_ms, arrive_not_before_tick}`. *Test: the fixture reproduces §D.2's timeline exactly; the target set equals the non-arena rooms; the arena bed ID appears in zero orders; the arrival's first sample is at ≥ the release boundary tick.*
- **TR-AUD-009 — The stillness bracket (E2/E6).** The gate drops (never queues); no loop restart; zero snapshot changes; zero ducks; sounding voices ring out. *Test: the gate-drop counter equals the number of gameplay one-shot requests inside the bracket; zero of them start; a loop that was sounding at E2 is the same loop at E6 (no restart flag); the snapshot hash is unchanged across [E1, E7].*
- **TR-AUD-010 — The tear (E5).** The success tear at τ0; the reserved voice; `TEAR_DURATION_MS` ≤ the window's span; the beat is the tick grid. *Test: the tear's start tick equals τ0; it is never stolen under a full pool; its duration is `ceil(400 × 60 ÷ 1000)` = 24 ticks ≤ 26.*
- **TR-AUD-011 — The abort path.** E3b absent → zero orders; the bracket closes at the force-release-derived `freeze_close`; `EV_FLIP_TEAR_ABORT` (no transient, no beats); the tail runs; the state precedence is §D.1's. *Test: the abort trace shows E2, the degenerate E5, the derived E6 as an event, and zero E3/E3b/E4/E7; the order count is zero; the bed's gain is unchanged; the state reaches `DEGRADED` then `IDLE` with no `RELEASED` entry.*
- **TR-AUD-012 — The resume re-run.** The post-resume order trace hashes identically to the fresh flip's (F-AUD-06), compared from R′. *Test: the fixture's two hashes are equal; the abort prefix is the declared offset.*
- **TR-AUD-013 — The arena hum.** `AMB_ARENA_STEEL_HUM` is one asset at both epochs; RM-06 is excluded from every order; the bed is unchanged across the whole window. *Test: the bed ID's order count is zero; the arena bed's playhead advances monotonically across the window (no restart, no gain change).*
- **TR-AUD-014 — The wing's no-op.** No audio event, gain change, layer, filter, or restart accompanies the wing's traversal; the wing has no bed of its own. *Test: the wing-traversal fixture's audio-graph delta is empty; the wing's bed ID equals RM-03's.*

---

## E · The Closed Edge List

### E.1 · The role vocabulary (the palette's home)

The sonic palette is the **audio-director's**, via the sound bible. Until that pass exists, every voice and bed carries a `PROV_AUD_*` **role** — function, register, and envelope class, never an instrument pin — with `status: PLACEHOLDER`; the sound-bible pass upgrades the roles in place (the `PROV_*` pattern the art pipeline uses). A role's identity is stable; its realisation is not yet pinned.

| Role | Used by | Register | Envelope class | Status |
|---|---|---|---|---|
| `PROV_AUD_A_AIR` | `AMB_A_HOUSE` | low-mid | sustained, steady | PLACEHOLDER |
| `PROV_AUD_B_AIR` | `AMB_B_HOUSE` | low-mid | sustained, warm | PLACEHOLDER |
| `PROV_AUD_ARENA_STEEL` | `AMB_ARENA_STEEL_HUM` | low-mid | sustained, perfectly steady | PLACEHOLDER |
| `PROV_AUD_SCORE` | `MUS_HOUSE_LOOP` | full | looping | PLACEHOLDER |
| `PROV_AUD_TEAR` | `EV_FLIP_TEAR` | full | transient + body + tail | PLACEHOLDER |
| `PROV_AUD_TEAR_DEGRADED` | `EV_FLIP_TEAR_ABORT` | mid | body + tail, no transient | PLACEHOLDER |
| `PROV_AUD_IMPACT_LIGHT/MID/HEAVY` | `EV_DAMAGE_TICK` (bands 1–3) | mid / mid-high / high | transient | PLACEHOLDER |
| `PROV_AUD_CLASH_CONTACT` | `EV_CLASH_CONTACT` | high | transient | PLACEHOLDER |
| `PROV_AUD_CLASH_MID` | `EV_CLASH_MIDPOINT` | high | transient | PLACEHOLDER |
| `PROV_AUD_DEFLECT` | `EV_DEFLECT` | high | transient | PLACEHOLDER |
| `PROV_AUD_HEAL` | `EV_HEAL_CHIME` | high | bell, short tail | PLACEHOLDER |
| `PROV_AUD_DEATH` | `EV_DEATH_POWER_DOWN` | full → low | descending body | PLACEHOLDER |
| `PROV_AUD_REVIVE` | `EV_REVIVE_BOOT` | low → mid | rising body | PLACEHOLDER |
| `PROV_AUD_PRINT` | `EV_LEVELUP_PRINT` | mid | mechanical print | PLACEHOLDER |
| `PROV_AUD_MEMORY` | `EV_MEMORY_CHIME` | high | bell, long tail | PLACEHOLDER |
| `PROV_AUD_AIRSTEP` | `EV_JUMP2_TICK` | mid | tick | PLACEHOLDER |
| `PROV_AUD_DEFEAT` | `EV_DEFEAT_TICK` | mid | tick + short body | PLACEHOLDER |

### E.2 · The thirteen voices

Ten SYS-29 edges → eleven voices (the clash pair) + two flip tear voices.

| Event ID | Source edge | Trigger | Bus | Class | Max conc. | Retrigger floor | Variants | Duration |
|---|---|---|---|---|---|---|---|---|
| `EV_DAMAGE_TICK` | SYS-07 `DamageNumber` | the damage edge where **`is_heal == false`**; **pitched by amount band, never a per-hit voice** | SFX | P2 | 2 | 1 tick | 4 files; the band is a runtime pitch shift | 90 ms |
| `EV_CLASH_CONTACT` | SYS-29 (SYS-08's clash) | the clash tick | SFX | P2 | 1 | 21 ticks | 3 | 120 ms |
| `EV_CLASH_MIDPOINT` | SYS-29 (SYS-08's clash) | +21 **logic** ticks (the spark's midpoint) | SFX | P2 | 1 | 21 ticks | 3 | 120 ms |
| `EV_DEFLECT` | SYS-08 | the deflect resolution | SFX | P2 | 2 | 3 ticks | 2 | 100 ms |
| `EV_HEAL_CHIME` | SYS-07 `HealEdge` | the heal edge | SFX | P3 | 1 | 6 ticks | 1 (signature) | 350 ms |
| `EV_DEATH_POWER_DOWN` | SYS-07 `DeathEdge` | the player's death latch | SFX | P1 | 1 | latch | 1 (signature) | 700 ms |
| `EV_REVIVE_BOOT` | SYS-07 revive | the restore-module draw | SFX | P1 | 1 | 30 ticks | 1 | 500 ms |
| `EV_LEVELUP_PRINT` | SYS-07/SYS-29 | the level-up print edge | SFX | P3 | 1 | 30 ticks | 1 | 400 ms |
| `EV_MEMORY_CHIME` | SYS-29 TR-JCE-021 | the memory pickup (SYS-20) or the cache's MEMORY CACHED (SYS-15), once per pickup | SFX | P1 | 1 | latch per pickup | 1 (signature) | 1200 ms |
| `EV_JUMP2_TICK` | SYS-29 TR-JCE-021 | the double-jump takeoff | SFX | P3 | 2 | 2 ticks | 3, ±1 st | 120 ms |
| `EV_DEFEAT_TICK` | SYS-29 | an enemy defeat | SFX | P2 | 2 | 2 ticks | 3, ±1 st | 200 ms |
| `EV_FLIP_TEAR` | SYS-09 E5 | τ0, the flip's own voice | SFX (reserved) | P0 | 1 | latch per run | 1 (signature) | 400 ms |
| `EV_FLIP_TEAR_ABORT` | SYS-09 E5 (degenerate) | τ0 on the abort path; no transient | SFX (reserved) | P0 | 1 | latch per run | 1 | the tail |

**The variation law.** Variants are round-robin with **no immediate repeat**; pitch randomization is ±1 semitone *within* a band and never applied to a signature or the clash pair. The heal, the death, the revive, the level-up, the memory chime, and the tear are **signatures** — one variant, zero pitch drift, because their identity is the meaning. The clash pair keeps its three variants **and shares the zero-drift law without being a signature** — the pair reads as one gesture, and a drifting component would fracture the contact→midpoint shape. Selection is deterministic under a fixed seed (a replay reproduces the draw sequence). The signatures' repeat-exposure tolerance across a session (the memory chime's 1200 ms bell fired on every cache save above all) is a sound-bible-pass assessment; the one-variant law stands.

**The asset arithmetic.** 25 one-shot files (4 + 3 + 3 + 2 + 1 + 1 + 1 + 1 + 1 + 3 + 3 + 1 + 1 = 25; the damage bands are runtime pitch shifts, not extra files) + 3 beds + 1 score = **29 audio files** at MVP.

### E.3 · The requirements

- **TR-AUD-015 — The damage tick.** One voice per damage event where `is_heal == false`, pitched by `F-AUD-03`'s band; max 2 concurrent; 1-tick retrigger floor; four variant files, the band a runtime pitch shift, ±1 semitone within the band; never a per-hit voice. *Test: amounts at the arc symbols **1/2/3/4/6** → bands **1/2/2/3/3**; a heal edge produces zero damage ticks; two same-tick events produce at most two voices; a 12-hit flurry produces no more than one voice per tick after the floor.*
- **TR-AUD-016 — The clash pair.** Two components, contact at the clash tick and midpoint at +21 logic ticks, consumed from SYS-29's publication — **never self-derived** (the hit-stop freezes the logic clock; the audio must not compute the midpoint). *Test: the audio's two start ticks equal SYS-29's published ticks exactly under a 6-tick freeze; the midpoint's wall offset is 6 ticks later than its logic offset (the AC-JCE-15 mirror); a publication suppression yields zero components.*
- **TR-AUD-017 — The deflect tick.** At the deflect resolution; max 2; 3-tick floor; two variants. *Test: the start tick equals the publication's tick.*
- **TR-AUD-018 — The heal chime and the death power-down.** The heal on `HealEdge` (a full-HP no-op publishes no edge and therefore no chime); the death power-down on the death latch, once per life, 700 ms, no alarm character. *Test: the full-HP fixture emits zero chimes; the death fixture emits exactly one power-down and zero sting audio.*
- **TR-AUD-019 — The revive boot and the level-up print.** The boot on the restore-module draw; the print on the level-up edge. The **reconstruct** path carries no voice (it is not in the closed list); its offline exit only releases the duck. *Test: the revive fixture emits one boot; the reconstruct fixture emits zero voices and one duck release; the level-up fixture emits one print.*
- **TR-AUD-020 — The memory chime.** Audio-led (TR-JCE-021), once per pickup, fired by the memory pickup (SYS-20) or the cache's MEMORY CACHED (SYS-15); the Leap-Stone grant reuses the voice; no haptic, no flash. *Test: one chime per pickup; one per cache MEMORY CACHED; a latched re-read re-chimes zero times; the grant fires one chime.*
- **TR-AUD-021 — The jump-2 and defeat ticks.** The double-jump takeoff and the enemy defeat; the first jump and an enemy's death-sting carry neither. *Test: the double-jump fixture emits one jump-2 and the first jump none; an enemy death emits one defeat tick and zero sting audio.*
- **TR-AUD-038 — The variation law.** Round-robin with no immediate repeat; ±1 semitone within a band; zero drift on the signatures and the clash pair; deterministic under a fixed seed. *Test: the seeded 40-draw fixture per voice — no adjacent repeat on the multi-variant voices, |Δst| ≤ 1, zero drift on the six signatures and the clash pair, the draw sequence identical on replay.*

---

## F · Ambience Design

### F.1 · The bed table

Three beds, one per truth plus the arena's invariant hum. The bed is per **room**; the wing is not a room.

**The bed resolution's epoch source (CR-AUD-02).** The core never reads the truth state. In-session, each room's bed derives from the core's own consumed-event state: epoch-0 beds at boot, shifted for the target rooms by the flip's E3b order. A **load** is the one case the derived state cannot cover (a save made after the flip restores epoch 1 and replays no flip edges): the **load-complete event's payload carries the restored epoch** (`restored_epoch` — SYS-03's save data, consumed as event data at the adapter, the CR-AUD-01 pattern), and the core applies it to the derived map at the load-complete tick, so the first room entry after a load resolves the epoch-correct bed. **CR-AUD-02** records the request to SYS-03's authoring (SYS-03 is Not Started — the payload rides its design); until it lands, a post-flip load boots on the derived epoch-0 state, the recorded gap the request closes before the first audio story.

| Room | Epoch 0 | Epoch 1 | Notes |
|---|---|---|---|
| RM-01 | `AMB_A_HOUSE` | `AMB_B_HOUSE` | |
| RM-02 | `AMB_A_HOUSE` | `AMB_B_HOUSE` | |
| RM-03 | `AMB_A_HOUSE` | `AMB_B_HOUSE` | the wing is inside; no separate bed; the seam crossing is a no-op |
| RM-04 | `AMB_A_HOUSE` | `AMB_B_HOUSE` | |
| RM-05 | `AMB_A_HOUSE` | `AMB_B_HOUSE` | |
| RM-06 | `AMB_ARENA_STEEL_HUM` | `AMB_ARENA_STEEL_HUM` | epoch-invariant; never ordered |

The **score** (`MUS_HOUSE_LOOP`) plays in every room, at both epochs, through the flip and through the wing. It is the player's constant; the air is the world's.

### F.2 · The layers

At MVP a bed is a **single continuous loop asset** that carries its own texture. There are **zero stochastic detail one-shots** and **zero layer adds** — a random creak or drip would be an audio emission no system asked for (the closed-list audit would fail), and it would break the mobile budget's predictability. Detail layers are a VS item and require a TR-JCE-027 revision.

### F.3 · The two silences

- **The arena** never turns over: the steel hum is the same asset at both epochs, the same gain, the same playhead continuity. It is the ear's proof of the lie.
- **The wing** has no audio identity of its own: no crossfade, no filter, no layer, no restart, no sting at the threshold or in the wing (AR-SMB-02). The corridor's signature is that nothing happens.

### F.4 · The requirements

- **TR-AUD-022 — The bed table.** Three beds; the room→bed map of §F.1; `AMB_ARENA_STEEL_HUM` is RM-06's at both epochs; the score is global; the epoch source is §F.1's rule (the derived consumed-event state in-session; the load-complete payload's `restored_epoch` after a load). *Test: the table resolves every room at both epochs; the arena's bed ID is epoch-independent; the wing resolves to RM-03's bed; the load-complete fixture applies `restored_epoch` to the derived map and the post-flip-load room entry plays the epoch-1 bed.*
- **TR-AUD-023 — Beds only, no stochastic detail.** Zero one-shot emissions from the ambience layer; a bed's texture lives inside its loop asset. *Test: the ambience layer's registration list contains loops only; a 10,000-tick soak emits zero ambience one-shots.*
- **TR-AUD-024 — The seam's exemption from the room-entry path.** The seam threshold is not a room boundary: a room-activation zone at the threshold produces zero crossfades, and the wing's traversal produces zero graph deltas (the room-entry crossfade fires only at a real room entry). *Test: the threshold fixture's audio-graph delta is empty; a normal room entry crossfades; a filter/volume snapshot of the wing equals RM-03's.*
- **TR-AUD-025 — The transition law.** The only bed transition at the flip is the turnover (AR-AUD-01); room-to-room transitions are a crossfade owned by the room-entry path (SYS-02's room activation, consumed at the adapter), never a restart and never a duck. *Test: a room-entry fixture crossfades without a restart; the flip fixture reproduces §D.2.*
- **TR-AUD-039 — The bed-contrast law (the ear's 2-second test).** The A and B house beds are recognisably different truths at the sound-bible pass: a blind A/B nameability bar (≥ 4 of 5 listeners name the truth from the bed alone within 10 s), the beds audible on the Pixel 6a speaker at the default volume, and the arena hum distinct from both house beds. The sound bible pins the realisation; this document pins the bar. *Test: the DEVICE fixture (AC-AUD-31) runs the three comparisons; the sound-bible pass records the pinned realisations.*

---

## G · Audio Architecture

### G.1 · Buses and volumes

| Bus | Parent | Nominal | Voices | Role |
|---|---|---|---|---|
| Master | — | 0 dB | — | the limiter only |
| Music | Master | −6 dB | 1 | the score; the duck's only target |
| Ambience | Master | −9 dB | 4 | the beds (2 sounding during a turnover) |
| SFX | Master | −3 dB | 12 + 1 reserved | the thirteen one-shot voices; the tear holds the reserved slot |
| UI | Master | −6 dB | 0 | reserved; zero voices at MVP |

### G.2 · The snapshot

**Exactly one mix snapshot exists at MVP** (`SNAP_GAMEPLAY`, the nominal mix). There are **zero snapshot changes across [E1, E7]**. The offline state is the duck request, not a snapshot; the flip bracket is an event-gate state, not a mix state. This is what makes "no snapshot change that reads as a beat" provable: there is nothing to change.

### G.3 · Voice pools and the cap

`allocated = SFX_POOL + AMB_POOL + MUSIC 1 + FLIP 1 + UI 0` = 12 + 4 + 1 + 1 + 0 = **18** of a **20 hard cap** (2 slack). The turnover needs two beds simultaneously (the receding bed and the arriving bed). The theoretical instant worst case on the SFX bus is 15 voices (damage 2 + clash 2 + deflect 2 + heal 1 + death 1 + revive 1 + level-up 1 + memory 1 + jump-2 2 + defeat 2), which the 12-slot pool resolves by the steal rule (P3 first) — the realistic worst case is a clash + a flurry + a heal, and 12 covers it. `VOICE_CAP` must be ≥ `allocated` and ≤ the 20-voice hard cap; a config outside that span is a config-load rejection (a boot failure).

### G.4 · The steal rule

Classes: **P0** reserved (the tear) · **P1** signature (death, revive, memory) · **P2** combat (damage, clash pair, deflect, defeat) · **P3** feedback (heal, level-up, jump-2). Steal the lowest class first, within a class the oldest: **P3 → P2 → drop**. Never steal P0; never steal a signature. If only P0/P1 remain, **drop** the new request.

### G.5 · Loop points and the arrival

Beds loop seamlessly at bar boundaries. The arrival is a bed's **first start**, faded in from the floor — never a restart of a sounding loop (the bracket's loop-restart ban). A room-entry crossfade may reuse the sounding bed's playhead; the flip's arrival does not (the arriving bed starts at its loop start).

### G.6 · Import settings

| Asset class | Format | Channels | Rate | Loop | Notes |
|---|---|---|---|---|---|
| Beds | Ogg Vorbis, q0.5–0.6 | mono | 44.1 kHz | on, seamless | mono halves memory; no spatialization |
| Score | Ogg Vorbis, q0.6–0.7 | stereo | 44.1 kHz | on, seamless | the one stereo asset |
| One-shots | WAV 16-bit PCM | mono | 44.1 kHz | off | trimmed, −3 dBFS peak, no silence padding |

The engine-side import flags and the playback mechanism are the ADR's (the GDD states what, never how); the format/rate/channel/loop/peak pins are this system's. **Two probes gate the ADR:** Ogg Vorbis gapless loop points on the beds, and a stereo→mono sum on Master (no documented built-in).

### G.7 · The budget

| Budget | Value | Basis |
|---|---|---|
| Disk | ≤ 10 MB | ~1.1 MB beds + ~1.1 MB score + ~1.5 MB one-shots ≈ 3.7 MB at MVP; headroom for VS |
| Runtime | ≤ 16 MB | ~10% of the 150 MB RAM ceiling; the one-shots are resident, the beds/score stream |
| Voices | 20 hard cap | §G.3 |
| The core's logic tick | p99.9 ≤ 0.10 ms / max ≤ 0.30 ms (**provisional**) | the core routes events; the mixing is on the audio thread; the technical-director ratifies |
| Reference SKU | **Pixel 6a** (QA plan §5.1) | the mobile reference class |

The six-system envelope join is recorded as **NOT-JOIN** at MVP (the SYS-09 precedent: event budgets instead of a summed frame bar); the audio's bar is its own tick budget, provisional pending the technical-director's ratification (OQ-AUD-6).

### G.8 · The duck schema, telemetry, the read-only surfaces, and the failure paths

**The duck.** `duck_request {bus, dB, hold}` — exactly three fields: `bus ∈ {MUSIC}`, `dB ∈ [−12, 0]`, `hold ∈ {UNTIL_OFFLINE_EXIT}`. The release is `duck_release {bus}`. No other field exists; adding one is a contract revision. The **application site** is one (`src/audio/`); the publication is SYS-29's.

**The read-only surfaces (the allowlist).** The tuning read (`MASTER_VOLUME`/`MUSIC_VOLUME`/`SFX_VOLUME`/`MONO` + the bus group map, consumed by SYS-24) and the event-metadata read (`{event_id, tick}`, reserved for the caption layer). Both are ports, not events; they are the only entries in AC-AUD-19's allowlist.

**Telemetry.** The **edge trace** (`{tick, edge_id, source}` per consumed edge — the seven-edge assertion); the **order trace** (`{tick, edge_id, to_epoch, target_rooms, excluded, recede_ms, arrive_not_before_tick}`, hashed by F-AUD-06 — the audio half of the replay hash); the duck counter (1 per death); the steal counter; the gate-drop counter; the missing-input counter; a bounded 256-record ring.

**The records.**

| Record ID | Fields | Rate limit |
|---|---|---|
| `AUD_MISSING_E1` / `_E2` / `_E5` / `_E6` / `_E7` | `{tick, expected_edge}` | 1 per run each |
| `AUD_MISSING_E3B` | `{tick, expected_edge}` | 1 per run |
| `AUD_ASSET_MISSING` | `{asset_id, tick}` | 1 per asset per run |
| `AUD_DUCK_BUS_MISSING` | `{bus, tick}` | 1 per run |
| `AUD_DUCK_RELEASE_BACKSTOP` | `{tick, reason}` | 1 per death |
| `AUD_GATE_FAILSAFE` | `{tick, bracket_ms}` | 1 per run |
| `AUD_GATE_DROP` | `{event_id, tick}` | counted (not ringed) |
| `AUD_LOAD_MISSING` | `{tick}` | 1 per run |

| Missing input | Owner | The audio's behaviour |
|---|---|---|
| **E1** never arrives | SYS-09 | no arm; the beds stay as they are; one record; no self-arm |
| **E2** never arrives | SYS-29 | the state never enters `HELD`; the gate never closes; one record; the gate failsafe is armed from E1 |
| **E3b** never arrives while E2/E5/E6/E7 do | SYS-10 (its emission) | the bed stays put; one record; a dev assert in dev builds; **no self-shift** (the epoch is not read) |
| **E5** never arrives | SYS-29 | the flip is silent (no tear); one record; the choreography proceeds |
| **E6** never arrives | SYS-29 | **the gate failsafe**: the gate opens at `GATE_FAILSAFE_MS` (700 ms = the 600 ms max freeze + 100 ms margin) after E2 — only if E6 has not arrived by that tick (**E6 wins the deadline**); one `AUD_GATE_FAILSAFE` record; the arrival is not started (no release boundary); the state exits `HELD` → `IDLE` without a `RELEASED` entry; the receded bed holds at `AMB_RECEDE_FLOOR_DB` (a bed that did not recede — the arena's hum — keeps its unchanged gain, TR-AUD-013) and zero new orders are emitted; the next room entry re-applies the room's bed at nominal (the normal room-entry path, on the derived epoch-correct state — §F.1) |
| **E7** never arrives | SYS-09 | the state exits `RELEASED` at `arrive_end` regardless; one record |
| The tear asset missing | SYS-04's content pipeline | the flip is silent; one `AUD_ASSET_MISSING` record; the choreography proceeds |
| The duck's bus missing | SYS-04's bus table | the request is dropped; one record; **never a silent Master duck** |
| The duck's release edge lost | SYS-15's screen lifetime | the offline screen's tree-exit is the backstop; one `AUD_DUCK_RELEASE_BACKSTOP` record |
| A gameplay one-shot requested inside the bracket | SYS-04's gate | dropped; `AUD_GATE_DROP` increments; never queued |
| The score asset missing | SYS-04's content pipeline | the score is silent; one `AUD_ASSET_MISSING` record; every other law holds |
| The load-complete never arrives | SYS-03/SYS-05's flow | the derived state stands unchanged (boot-epoch beds); one `AUD_LOAD_MISSING` record |

### G.9 · The requirements

- **TR-AUD-026 — The bus layout.** Four child buses under Master with the §G.1 roles; the duck targets Music only; UI has zero voices at MVP; the SFX pool is 12 + 1 reserved. *Test: the bus table matches; a duck request naming any other bus is rejected with a record; the class assignment of every voice matches §E.2.*
- **TR-AUD-027 — One snapshot, zero changes.** `SNAP_GAMEPLAY` is the only mix snapshot; zero snapshot changes across [E1, E7]. *Test: the snapshot hash is unchanged across the window; the snapshot registry contains exactly one entry.*
- **TR-AUD-028 — The pools and the cap.** `allocated` derives from the pool knobs (18 at defaults); `VOICE_CAP ≥ allocated` at boot; the flip slot is reserved. *Test: the arithmetic reproduces from the knobs; a `VOICE_CAP` below the allocation is a boot failure; a full SFX pool never starves the tear.*
- **TR-AUD-029 — The steal rule.** P3 → P2 → drop; never P0, never a signature. *Test: the §G.4 fixtures; the tear survives a 12-voice flood; a signature survives a P2 flood.*
- **TR-AUD-030 — The loop law.** Beds loop seamlessly; the arrival is a first start from the floor; no restart across the bracket. *Test: the loop-point fixture; the arrival's start tick is the release boundary and its start gain is `AMB_RECEDE_FLOOR_DB`; the sounding loop's playhead advances monotonically across [E2, E6].*
- **TR-AUD-031 — The import pins.** The §G.6 table. *Test: the import audit reads the format/channels/rate/loop/peak of every asset.*
- **TR-AUD-032 — The budget.** The §G.7 table, measured on the reference SKU; the tick bar provisional pending OQ-AUD-6. *Test: the device run reports disk, runtime, voice high-water, and the core's tick percentiles within the bars; a PROVISIONAL marker rides the tick bar.*
- **TR-AUD-033 — The duck schema, the telemetry, the allowlist, and the failure paths.** The §G.8 tables. *Test: each failure fixture produces its named record and behaviour; the edge trace and the order trace are emitted once per run; the allowlist grep matches only the two ports.*

---

## H · The Mix

### H.1 · The nominal mix and the priority classes

The §G.1 volumes: the beds sit ≥ 6 dB under the one-shots; the score sits between them — under the one-shots, a shade over the beds (the score is the player's constant; the air is the world's). The classes and the steal rule are §G.4's. The mix's job is to keep the **transient band** (the one-shots) clear of the **sustained low-mid** (the beds) — a static carve of the beds around the one-shots' fundamentals is the audio-director's palette pass, not this document's.

### H.2 · Masking and headroom

- The limiter on Master is the only master effect; it exists for the mobile speaker, not for loudness.
- The beds are mono and low-mid weighted; the one-shots are mono transients. The stereo field is the score's alone (the one stereo asset) — which is also what makes the MONO toggle's effect legible.
- The tear and the death power-down are the two loudest events in the game; they are also the two that must never clip (the limiter's first job).
- The tear's body sits **a shade under the air change** in the mix pass — it masks the turnover's first half, so it must not become the thing the player remembers. AC-AUD-23 is the arbiter.

### H.3 · The death duck (OQ-J7 ratified)

`DEATH_DUCK_DB = −6` on the Music bus, attack 120 ms (8 ticks, 133.3 ms effective), hold until the offline exit, release 240 ms (15 ticks, 250.0 ms effective), released on **both** exits (reconstruct and revive). Rationale: −6 is audible as a step-back but leaves the score present (the death is not a silence); −12 would read as the music dying (the world's job, not the score's); 0 would make the beat invisible. The `[−12, 0]` range stands. **Carried to the sound bible:** the ducked score is the most-heard stretch of the loop on repeat-death sessions — the hold's length and the loop's tolerance are a palette-pass note, and the held segment must not sit on the loop's most repetitive bar.

### H.4 · Accessibility and the settings surface

- **MONO** toggle on Master (default off): one stereo-to-mono collapse, all buses. The engine mechanism is the ADR's.
- **Three volume sliders** — Master, Music, SFX (default 80%) — with the **Ambience and UI buses assigned to the SFX slider's group** (3 sliders, 4 buses, one documented group mapping). SYS-24 renders the surface; SYS-04 publishes the knobs and their group map.
- **Captions for non-speech cues**: out of scope at MVP (OQ-AUD-7), but the core publishes an **event-metadata read** (event ID + tick) so captions can be added without re-authoring a single edge.
- **The text+shape law**: audio carries no unique meaning; every meaning completes visually (SYS-29's gain-toggle law). The mix is redundancy, never information.
- **Visual requirements**: none — SYS-04 renders nothing, owns no screen, and draws no icon.

### H.5 · The requirements

- **TR-AUD-034 — The nominal mix and the classes.** The §G.1 volumes; the four classes; the steal rule. *Test: the mix table matches; the class assignment of every voice matches §E.2.*
- **TR-AUD-035 — The masking and headroom law.** The beds ≥ 6 dB under the one-shots; the limiter is the only master effect; the tear and the death never clip. *Test: the device mix measurement; the limiter's gain-reduction high-water ≤ 3 dB (provisional) on the loudest fixture.*
- **TR-AUD-036 — The death duck, ratified.** −6 dB, 120/240 ms, the hold, both exits. *Test: AC-AUD-10's fixture; the [−12, 0] range enforced at config load.*
- **TR-AUD-037 — The accessibility surface.** MONO; the three sliders and the group map; the caption-metadata read; no unique-meaning audio. *Test: the settings fixture; the mono run's channel-collapse assertion; the metadata read's presence on every event.*

---

## I · Formulas

**The clock law.** ms is the contract; ticks derive by the never-stingy ceil at the active rate: `ticks = ceil(ms × tps ÷ 1000)` (tps = 60 pinned). A tick-derived duration is ≥ the ms contract; the overshoot is < 1 tick per conversion.

### F-AUD-01 · db_to_gain — the conversion

`gain = 10^(dB ÷ 20)` · `dB = 20 · log10(gain)`

**Variables:** `dB` float [−60, 0]; `gain` float [0.001, 1]. **Output:** the linear gain for a voice ramp; the bus volumes stay in dB. **Examples:** −6 → 0.5012; −9 → 0.3548; −3 → 0.7079; −60 → 0.001.

### F-AUD-02 · recede_schedule — the turnover

`recede_ticks = ceil(AMB_RECEDE_MS × tps ÷ 1000)` · `recede_end = τ0 + min(recede_ticks, N)` · `floor_hold = [recede_end, release_boundary)` · `arrive_start = release_boundary = τ0 + N` · `arrive_ticks = ceil(AMB_ARRIVE_MS × tps ÷ 1000)` · `arrive_end = arrive_start + arrive_ticks`

**Variables:** `τ0` int (the E3/E3b tick); `N` int (the freeze span in ticks, 18 at defaults); `AMB_RECEDE_MS` 240; `AMB_ARRIVE_MS` 240; `tps` 60. **Output:** the four tick boundaries; the invariants `recede_end ≤ release_boundary` and `arrive_start ≥ release_boundary`; the arrival's start gain = `AMB_RECEDE_FLOOR_DB`, its end gain = nominal, linear in gain. **Example (defaults):** τ0 = 101, N = 18 → recede 101→116; floor hold 116→119 (3 ticks); arrival 119→134; full B at 134. **Example (one admitted extension, N = 21):** release boundary 122 → recede 101→116; floor hold 116→122 (6 ticks); arrival 122→137.

### F-AUD-03 · amount_band — the damage pitch

`band = 1 + int(amount ≥ BAND_2_MIN) + int(amount ≥ BAND_3_MIN)` · `BAND_2_MIN = max(2, ATK1_DAMAGE)` · `BAND_3_MIN = ATK2_DAMAGE` · `pitch_st = {B1: 0, B2: +3, B3: +6}`

**Variables:** `amount` int ≥ 1 (a 0-damage event publishes no edge); `ATK1_DAMAGE`/`ATK2_DAMAGE` int — SYS-08's arc symbols (**2/4 on the D-ORCH-03 baseline**), **never literals**, so the SYS-07-REWORK re-derivation moves the bands with the arcs; **`BAND_2_MIN` carries the `max(2, …)` floor so B1 stays reachable at the knob's legal minimum (`ATK1_DAMAGE = 1` would otherwise collapse every legal amount into B2)**; `band` int ∈ {1, 2, 3}; `pitch_st` the band's runtime pitch shift. **Output:** the band and its shift; adjacent bands are ≥ 3 semitones apart **at nominal pitch** (the audible-separation floor on a phone speaker; the ±1 st within-band draw narrows the worst case to 1 st — the band's meaning is the printed amount, and the pitch is a reinforcement, never the sole carrier). **Scope:** the amount is any damage edge — the player's arcs and the received strikes **1/2/4** (TR-HD-003) and tiers **6/12/24** (TR-HD-006) — so received damage maps onto the same three bands; the thresholds stay arc-anchored. A Gate 2 ear check on the +3 st floor is carried to the sound-bible pass: if the bands blur by ear, the fix is the floor, never more voices. **Examples (the D-ORCH-03 baseline):** 1 → B1; 2 → B2 (+3 st); 3 → B2; 4 → B3 (+6 st); 6 → B3.

### F-AUD-04 · duck_envelope — the death beat

`attack_ticks = ceil(DUCK_ATTACK_MS × tps ÷ 1000)` = 8 · `release_ticks = ceil(DUCK_RELEASE_MS × tps ÷ 1000)` = 15 · `target = 10^(DEATH_DUCK_DB ÷ 20)` = 0.5012

`gain(t) = 1` for `t < death_tick` · `gain(t) = 1 + (target − 1) · (t − death_tick) ÷ attack_ticks` for `death_tick ≤ t < death_tick + attack_ticks` · `gain(t) = target` while held · the release mirrors from the exit tick. **The envelope runs on the wall clock.**

**Variables:** `death_tick` int; `exit_tick` int > death_tick; `DUCK_ATTACK_MS` 120; `DUCK_RELEASE_MS` 240; `DEATH_DUCK_DB` −6. **Output:** the per-tick gain; the invariant that exactly one request exists per death and the hold ends only on the offline exit. **Example:** death 5000 → unity at 5000; the ramp runs 5001–5008 and reaches 0.5012 at 5008; held; exit 5600 → the release mirrors over 5600–5614; nominal at 5615.

### F-AUD-05 · voice_budget — the pools and the steal

`allocated = SFX_POOL + AMB_POOL + 1 (Music) + 1 (Flip) + 0 (UI)` · `cap = VOICE_CAP` · `slack = cap − allocated` · `admit(r) = (pool.used < pool.max) ∨ (steal_candidate ≠ ∅)` · `steal_candidate = the lowest class, then the oldest, excluding P0 and signatures`

**Variables:** the pool knobs; the request's class ∈ {P0..P3}. **Output:** admit / steal(victim) / drop; a boot failure if `VOICE_CAP < allocated`. **Examples (defaults):** 18 allocated, 2 slack; 12 SFX sounding + a P2 → steal the oldest P3; if none, the oldest P2; if only P0/P1 remain → drop. A full SFX pool never steals the flip slot.

### F-AUD-06 · order_trace_hash — the replay's audio half

`h = FNV-1a(canonical_bytes(records))` over the ordered records `{tick, edge_id, to_epoch, target_rooms[], excluded[], recede_ms, arrive_not_before_tick}`, in emission order, **integer-encoded** (ticks and ms as ints; `to_epoch` int; no floats; room IDs sorted). A record with no rooms (never emitted at MVP) encodes empty arrays as zero-length. **Both timestamps encode relative to the run's raise tick** — `tick` and `arrive_not_before_tick` are hashed as `value − raise_tick` (`R` for a fresh flip, `R′` for a latched resume), so equivalent schedules produce identical hashes across the fresh and resumed runs (AC-AUD-05); `recede_ms` is a duration and is already relative.

**Variables:** the record list; the 32-bit hash. **Output:** a deterministic hash; the fresh flip's hash ≡ the latched resume's post-resume span (compared from R′). **The stub-bed hash** = the same hash over a run with the bed table stubbed to a single ID — the secondary check for AC-AUD-03. **Example:** the fixture's fresh run and the abort→resume run produce the same hash over the compared span; a one-tick drift in the order's `tick` changes it.

### F-AUD-07 · glitch_window_ticks — the tear's span

`window_ticks = N + ceil(GLITCH_TAIL_MS × tps ÷ 1000)`

**Variables:** `N` int; `GLITCH_TAIL_MS` 120 → 8 ticks; `window_ticks` int. **Output:** the E5 window's span, `[τ0, τ0 + window_ticks)`. **Examples:** N = 18 → 26 ticks (433.3 ms); N = 36 → 44 ticks (733.3 ms). The tear's `TEAR_DURATION_MS` 400 = 24 ticks ≤ 26 (2 ticks of slack).

---

## J · V-Invariants & Acceptance Criteria

### J.1 · The invariants

| ID | Invariant | Enforcement |
|---|---|---|
| V-AUD-01 | Exactly one duck request family exists; one application site; one runtime request per death | the static audit + the runtime counter; a second application site fails the build |
| V-AUD-02 | The closed list: zero one-shot emissions outside the thirteen voices | the registration scan + the static audit |
| V-AUD-03 | Zero arena-bed orders across [E1, E7]; the target set = the non-arena rooms exactly | the order record + the stub-bed hash (F-AUD-06) |
| V-AUD-04 | Epoch-blindness: zero `truth_epoch`/mutation-state reads in the audio core | the static audit + the poisoned-sentinel run |
| V-AUD-05 | Zero mix-snapshot changes and zero bus-gain changes across [E1, E7] | the snapshot hash + the bus-gain trace |
| V-AUD-06 | Receding-first by construction: the recede's first sample at τ0; the arrival's first sample ≥ the release boundary, starting at the floor | the schedule fixture (F-AUD-02) |
| V-AUD-07 | The gate drops, never queues; zero gameplay one-shots start inside [E2, E6); the tear is never stolen | the gate counter + the pool flood fixture |

### J.2 · The acceptance criteria (32: 22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST)

- **AC-AUD-01** [GUT] *(TR-AUD-001/007/008/009/010)* — **GIVEN** the scripted flip at the fixture (R = 100, τ0 = 101), **WHEN** the trace runs, **THEN** the arm is at 100 with an empty graph delta and all three beds + the tear resident; the bracket, the order, and the tear start at 101; the recede ends at 116; the arrival starts at 119; the resume is at 119; **the edge trace equals the published set in order, once per run**; **the order trace contains exactly one `ambient_shift` record**.
- **AC-AUD-02** [GUT] *(TR-AUD-008, F-AUD-02)* — **GIVEN** the defaults and one admitted extension (N = 21), **WHEN** the schedule resolves, **THEN** the two examples of F-AUD-02 reproduce exactly (recede 101→116 in both; the floor hold 116→119 in the defaults and 116→122 in the extension; the arrival 119→134 and 122→137).
- **AC-AUD-03** [GUT] *(TR-AUD-008/013)* — **GIVEN** the flip with a stubbed bed state, **WHEN** the order record is audited, **THEN** `target_rooms` = {RM-01..RM-05} exactly, `excluded` = {RM-06}, `AMB_ARENA_STEEL_HUM` appears in zero orders across the window, and the **stub-bed hash** (F-AUD-06) matches the baseline.
- **AC-AUD-04** [GUT] *(TR-AUD-011)* — **GIVEN** the commit-abort injection, **WHEN** the abort trace runs, **THEN** E2 fires, E3/E3b/E4/E7 are absent, `EV_FLIP_TEAR_ABORT` fires (no transient, no beats), the bracket closes at the force-release-derived `freeze_close` as an **event**, the tail runs, the state reaches `DEGRADED` then `IDLE` with **no `RELEASED` entry**, and the order count is zero with the bed's gain unchanged.
- **AC-AUD-05** [GUT] *(TR-AUD-012, F-AUD-06)* — **GIVEN** the latched-resume fixture, **WHEN** the post-resume trace hashes, **THEN** it equals the fresh flip's hash over the compared span, and the abort prefix is the declared offset.
- **AC-AUD-06** [GUT] *(TR-AUD-009)* — **GIVEN** gameplay one-shot requests inside the bracket, **WHEN** the gate runs, **THEN** every request is dropped (zero starts), the gate-drop counter equals the request count, a voice sounding at E2 is still the same voice at E6 (no truncation), and the loop's playhead advanced monotonically.
- **AC-AUD-07** [GUT] *(TR-AUD-010/028)* — **GIVEN** a full SFX pool and a P2 flood, **WHEN** the tear fires at τ0, **THEN** it starts (never stolen), its duration is `ceil(400 × 60 ÷ 1000)` = 24 ticks ≤ the 26-tick window, and the flood's victims are P3s then P2s only.
- **AC-AUD-08** [GUT] *(TR-AUD-015, F-AUD-03)* — **GIVEN** amounts at the arc symbols (**1/2/3/4/6**), **WHEN** the damage tick resolves, **THEN** the bands are **1/2/2/3/3**, a heal edge (`is_heal == true`) produces zero damage ticks, two same-tick events produce ≤ 2 voices, and the 12-hit flurry respects the 1-tick floor.
- **AC-AUD-09** [GUT] *(TR-AUD-016)* — **GIVEN** a clash under a 6-tick hit-stop, **WHEN** the pair resolves, **THEN** the audio's two **logic** start ticks equal SYS-29's published ticks (contact + 21 logic ticks) exactly, the midpoint's **wall** offset is 6 ticks later than its logic offset (the AC-JCE-15 mirror), and a suppressed publication yields zero components.
- **AC-AUD-10** [GUT] *(TR-AUD-005/036, F-AUD-04)* — **GIVEN** the death and the offline exit, **WHEN** the duck runs on the wall clock, **THEN** exactly one request publishes (−6 dB, Music, held), the attack is 8 ticks, the release is 15 ticks, and both the reconstruct and revive exits release it; a second request in the same life fails.
- **AC-AUD-11** [GUT] *(TR-AUD-028/029, F-AUD-05)* — **GIVEN** the §G.4 fixtures, **WHEN** the budget resolves, **THEN** the arithmetic reproduces from the knobs (18 of 20), a `VOICE_CAP` below the allocation is a boot failure, the steal order is **P3 → P2 → drop** (P0 and the P1 signatures are never stolen), and the drop path is reached only when P0/P1 remain.
- **AC-AUD-12** [GUT] *(TR-AUD-022)* — **GIVEN** the six rooms at both epochs, **WHEN** the bed table resolves, **THEN** RM-01..RM-05 map A→B, RM-06 maps to the same invariant bed at both epochs, and the wing resolves to RM-03's bed.
- **AC-AUD-13** [GUT] *(TR-AUD-006/033)* — **GIVEN** the missing-input injections of §G.8 (E1, E2, E3b, E5, E6, E7, the tear asset, the duck bus, the duck release, the bracket request, the score asset, the load-complete), **WHEN** each runs, **THEN** each produces its named record ID and behaviour, and no injection produces a synthesized substitute (the E3b omission leaves the bed put; the E6 omission opens the gate at `GATE_FAILSAFE_MS` only without E6 by that tick — E6 wins the deadline — exits `HELD` → `IDLE` without a `RELEASED` entry, holds the receded bed at the floor while the arena's hum keeps its gain, starts no arrival, and the next room entry re-applies the room's bed at nominal; the load-complete omission leaves the derived state standing).
- **AC-AUD-14** [GUT] *(TR-AUD-033, F-AUD-06)* — **GIVEN** the fixture set (the default flip, the abort, the latched resume, the extension, the missing-input run), **WHEN** the telemetry drains, **THEN** the edge trace and the order trace are emitted once, the duck counter = 1 per death, the steal/gate-drop/missing-input counters equal their fixture counts, and the ring never exceeds 256 records.
- **AC-AUD-15** [GUT] *(TR-AUD-004/023)* — **GIVEN** the runtime registration scan, **WHEN** it sweeps the emissions, **THEN** exactly thirteen one-shot IDs exist, zero UI voices exist, and a 10,000-tick soak emits zero ambience one-shots.
- **AC-AUD-16** [GUT] *(TR-AUD-027)* — **GIVEN** the flip window, **WHEN** the snapshot and score are audited, **THEN** the snapshot hash is unchanged, the score's gain and playhead state are unchanged across [E1, E7], and zero score ducks exist.
- **AC-AUD-17** [LINT] *(TR-AUD-005, V-AUD-01)* — **GIVEN** the source, **WHEN** the one-duck audit runs, **THEN** exactly one **application site** of the duck exists in `src/audio/` (the publication is SYS-29's), no hit-stop/flip/seam/reveal-hold/pause source calls it, and the request's schema has exactly three fields.
- **AC-AUD-18** [LINT] *(TR-AUD-004, V-AUD-02)* — **GIVEN** the source, **WHEN** the closed-list audit runs, **THEN** exactly the thirteen voices are registered, and zero popup/voice/menu-click emissions exist.
- **AC-AUD-19** [LINT] *(TR-AUD-002/003, V-AUD-04)* — **GIVEN** the source, **WHEN** the seam audit runs, **THEN** the core contains no `Input`/`Time`/`SceneTree`/`RenderingServer`/truth-state symbol, the adapter's subscriptions equal the publisher map, and a grep for cross-system calls from `src/audio/` matches only the §G.8 allowlist (the tuning read, the event-metadata read).
- **AC-AUD-20** [DEVICE] *(TR-AUD-034/035)* — **GIVEN** the Pixel 6a reference SKU, **WHEN** the mix runs, **THEN** the beds sit ≥ 6 dB under the one-shots, the limiter's gain-reduction high-water stays ≤ 3 dB on the loudest fixture (provisional; the sound-bible pass may re-pin), and no fixture clips.
- **AC-AUD-21** [DEVICE] *(TR-AUD-032, PROVISIONAL on OQ-AUD-6)* — **GIVEN** the release-like build on the reference SKU, **WHEN** the budget run measures, **THEN** disk ≤ 10 MB, runtime ≤ 16 MB, the voice high-water ≤ 20, and the core's tick is within p99.9 ≤ 0.10 ms / max ≤ 0.30 ms (the tick bar provisional).
- **AC-AUD-22** [DEVICE] *(TR-AUD-037)* — **GIVEN** the settings surface SYS-24 renders, **WHEN** MONO and the three sliders are exercised, **THEN** MONO collapses every bus to mono, the Ambience and UI buses follow the SFX slider's group, and every slider's range is honoured.
- **AC-AUD-23** [PLAYTEST] *(TR-AUD-008/010/039, the Player Fantasy)* — **GIVEN** ≥ 5 eligible testers from the Gate 2 cohort (the SYS-09 AC-DR-25 precedent; 3-of-5 pass), **WHEN** the AC-SMB-22 coding protocol runs (a free-play log first, then the elicitor; κ ≥ 0.7; top-up below 3 eligible), **THEN** ≥ 3/5 use the pass token set {air changed, bed turned over, the room sounds different} for the flip; the fail set {a sound effect played, a stinger, the sound cut out, the audio broke} fails the code outright. The probe also runs at Gate 1 on the core-slice cohort so a failed turnover surfaces early.
- **AC-AUD-24** [PLAYTEST] *(TR-AUD-036, the Player Fantasy)* — **GIVEN** the same cohort and protocol, **WHEN** the rubric codes the death beat, **THEN** ≥ 3/5 use the pass set {the music stepped back, the score bowed out}; the fail set {silence, a bug, the world went silent} fails the code.
- **AC-AUD-25** [GUT] *(TR-AUD-017/018/019/020/021)* — **GIVEN** the voice fixtures, **WHEN** each edge resolves, **THEN** the deflect/heal/death/revive/level-up/memory/jump-2/defeat voices each fire exactly once per edge; the full-HP heal emits zero chimes; a repeat pickup re-chimes zero times; the reconstruct emits zero voices and one duck release; the first jump emits none; an enemy death emits one defeat tick and zero sting audio.
- **AC-AUD-26** [GUT] *(TR-AUD-026/034)* — **GIVEN** the bus table and a duck request naming Ambience, **WHEN** the audit runs, **THEN** the four child buses and their nominal volumes match §G.1, the SFX pool is 12 + 1 reserved, the non-Music request is rejected with a record, and the class assignment of every voice matches §E.2.
- **AC-AUD-27** [GUT] *(TR-AUD-014/024/025)* — **GIVEN** the seam and room-entry fixtures, **WHEN** the crossings run, **THEN** the threshold crossing and the wing's traversal produce zero graph deltas (no crossfade, filter, layer, restart, gain, snapshot), a normal room entry crossfades without a restart, and the wing's bed equals RM-03's.
- **AC-AUD-28** [GUT] *(TR-AUD-030)* — **GIVEN** the loop fixture, **WHEN** the turnover runs, **THEN** the arrival is a first start at the release boundary with its start gain at `AMB_RECEDE_FLOOR_DB`, the sounding loop's playhead advances monotonically across [E2, E6], and no loop restart flag is set.
- **AC-AUD-29** [GUT] *(TR-AUD-009/015/018/020/036, §K.2)* — **GIVEN** the edge-case fixtures (#5 `REDUCED_FLASH` mid-hold, #6 a damage event in the death-latch tick, #9 an enemy defeat during the death beat, #12 the pause/map screen, #14 a room-entry request inside the bracket), **WHEN** each runs, **THEN** #5 changes zero audio events, #6 sounds both voices (≤ 2) and ducks once, #9 sounds the defeat tick with the music ducked and the ambience not, #12 changes zero bus gains and issues zero ducks, and #14 is **dropped** at the gate with the counter incremented.
- **AC-AUD-30** [GUT] *(TR-AUD-038)* — **GIVEN** the fixed seed, **WHEN** 40 draws per voice run, **THEN** no adjacent repeat occurs on the multi-variant voices, |Δst| ≤ 1 within a band, the six signatures and the clash pair show zero drift, and the draw sequence is identical on replay.
- **AC-AUD-31** [DEVICE] *(TR-AUD-039)* — **GIVEN** the Pixel 6a speaker at the default volume, **WHEN** the bed-contrast fixture runs, **THEN** ≥ 4 of 5 listeners name the truth from the bed alone within 10 s, both house beds are audible, and the arena hum is distinguishable from both.
- **AC-AUD-32** [LINT] *(TR-AUD-031/037)* — **GIVEN** the import audit, **WHEN** it reads every asset, **THEN** the format/channels/rate/loop/peak match §G.6, and the event-metadata read is present on every registered voice and bed.

**The gate manifest:** MVP smoke **26** (22 GUT + 4 LINT) · device **4** · MVP-lock **2** (AC-AUD-23/24) · VS **0** = **32**.

---

## K · Tuning Knobs · Edge Cases · Dependencies · Open Questions

### K.1 · Tuning knobs

| Knob | Value | Range | Rationale | Owner |
|---|---|---|---|---|
| `DEATH_DUCK_DB` | −6 | [−12, 0] | ratified (OQ-J7); audible step-back, score present | SYS-04 |
| `DUCK_ATTACK_MS` | 120 | [60, 240] | a musical fade, not a click | SYS-04 |
| `DUCK_RELEASE_MS` | 240 | [120, 480] | the return is slower than the step-back | SYS-04 |
| `AMB_RECEDE_MS` | 240 | [180, 300] | 15 ticks at the default freeze, leaving a 3-tick floor hold; `min(recede_ticks, N)` guards short freezes | SYS-04 |
| `AMB_ARRIVE_MS` | 240 | [120, 480] | under the recede — the arrival is the softer motion | SYS-04 |
| `AMB_RECEDE_FLOOR_DB` | −60 | [−60, −24] | effectively silence; the held breath; the arrival's start gain | SYS-04 |
| `SFX_POOL` | 12 | [12, 16] | covers the realistic worst case (a clash + a flurry + a heal); the theoretical 15 is handled by the steal rule | SYS-04 |
| `AMB_POOL` | 4 | [2, 6] | two sounding during a turnover + slack | SYS-04 |
| `VOICE_CAP` | 20 | [18, 20] | ≥ the derived allocation (18) + 2 slack; the 20-voice hard cap is the mobile ceiling, so the range's top is the cap itself | SYS-04 / technical-director |
| `GATE_FAILSAFE_MS` | 700 | [600, 1200] | the 600 ms max freeze + 100 ms margin; the only failure SYS-04 contains itself | SYS-04 |
| `AUDIO_DISK_BUDGET_MB` | 10 | [6, 16] | 3.7 MB at MVP + VS headroom | technical-director |
| `AUDIO_RUNTIME_BUDGET_MB` | 16 | [8, 24] | ~10% of the 150 MB ceiling | technical-director |
| `TEAR_DURATION_MS` | 400 | [300, 420] | 24 ticks at the default; the cap 420 = 26 ticks = the window's span (zero slack) | SYS-04 |
| `MONO_DEFAULT` | off | {on, off} | the player's choice; the mobile speaker is the reason it exists | SYS-24 |

### K.2 · Edge cases

1. **The player in the arena during the flip** → the steel hum continues untouched; the tear layer plays (global); zero bed orders. The Gate 2 script names this state. [TR-AUD-013.]
2. **The flip aborts** → zero orders, zero recede, zero arrival; the degenerate tear; the bracket closes at the force-release as an event; `DEGRADED` → `IDLE`, never `RELEASED`. [TR-AUD-011.]
3. **The latched resume** → the re-run's post-resume trace hash equals the fresh flip's. [TR-AUD-012.]
4. **An admitted extension (N = 21/36)** → the recede still ends at 240 ms; the floor hold lengthens; the arrival moves with the boundary. [F-AUD-02.]
5. **`REDUCED_FLASH` toggled mid-hold** → zero audio change; the audio is flash-blind. [G6; AC-AUD-29.]
6. **A damage event in the same tick as the death latch** → the power-down and the damage tick may both sound (max 2); the duck fires only from the death latch. [TR-AUD-015/018; AC-AUD-29.]
7. **A heal at full HP** → no `HealEdge` publishes (TR-HD-029's no-op) → no chime. [TR-AUD-018; AC-AUD-25.]
8. **A repeat pickup / a latched re-read** → no re-chime (SYS-29's once). [TR-AUD-020; AC-AUD-25.]
9. **An enemy defeat during the player's death beat** → the defeat tick may sound (the world continues); the music is ducked, the ambience is not. [AC-AUD-29.]
10. **The offline exit edge lost** → the screen's tree-exit is the backstop; one record. [TR-AUD-033.]
11. **E3b lost while the rest of the sequence fires** → the bed stays put; one record; a dev assert; no self-shift. [TR-AUD-033.]
12. **The pause/map screen** → zero ducks, zero bus-gain changes; the audio continues (SYS-25's surface owns the pause). [AC-AUD-29.]
13. **The score asset missing** → silent score; every other law holds; one record. [TR-AUD-033.]
14. **A room-entry request during the bracket** → the gate **drops** it (never queues, never defers); the counter increments; the room's bed change applies at the next room entry after E6. A dropped room-entry bed mismatch persists until that next room entry; the E6 arrival serves the room the player occupies at the release boundary, and if that room is the arena no arrival is ordered (the steel hum continues — edge case #1). [TR-AUD-009; AC-AUD-29.]
15. **E6 lost after E3b fired** → the failsafe at `GATE_FAILSAFE_MS` (only if E6 has not arrived by that tick — E6 wins the deadline); `HELD` → `IDLE` without a `RELEASED` entry; the receded bed holds at the floor (a bed that did not recede — the arena's hum — keeps its unchanged gain, TR-AUD-013); the arrival never starts; the next room entry re-applies the room's bed. [TR-AUD-033; AC-AUD-13.]

### K.3 · Dependencies

| System | Direction | Contract | State |
|---|---|---|---|
| SYS-09 Dual-Reality | upstream (hard) | the Flip-Trigger Contract (E1/E4/E7 + G1–G7), the tear hook, AC-DR-27 | landed (APPROVED gated on S1-007) |
| SYS-10 World Mutation | upstream (hard) | E3b `ambient_shift` (pinned, receding-first), the abort case, the latched resume; **CR-AUD-01: the `to_epoch` payload** | APPROVED 2026-11-14 (S1-002b) |
| SYS-29 Juice | upstream (hard) | TR-JCE-027 (the edge list + the duck), E2/E5/E6, AC-JCE-31/32 | APPROVED 2026-11-13 |
| SYS-11 Seam Borders | upstream (soft) | AR-SMB-01..04 (zero audio, the bed continues, the no-duck ruling, M4's chime) | APPROVED 2026-11-14 |
| SYS-07 Health & Damage | upstream (hard) | `DamageNumber`/`HealEdge`/`DeathEdge`/`DefeatEvent`; **the SYS-07-REWORK re-derives the arc symbols F-AUD-03 consumes** | APPROVED 2026-11-12; the rework queued |
| SYS-08 Combat | upstream (hard) | the clash pair's publication; the hit-stop pairing; the arc damage symbols | APPROVED 2026-11-12 |
| SYS-02 Room & World | upstream (hard) | the six-room fixture; RM-06 = the arena; the room activation | APPROVED 2026-11-13 |
| SYS-03 Save & Serialization | upstream (soft) | the load-complete event's `restored_epoch` payload (CR-AUD-02's request; SYS-03 is Not Started — the request rides its authoring) | Not Started |
| SYS-15 / SYS-20 | downstream (soft) | the offline screen's lifetime (the duck's hold); the memory-pickup / MEMORY CACHED triggers | Not Started |
| SYS-24 HUD | downstream (soft) | the settings surface (MONO + three sliders) | Not Started |
| ADR-DRAFT | support | the audio ADR (the mechanism choices: bus effects, snapshot implementation, the voice pool, the Ogg gapless loop + stereo→mono probes) | STANDBY |
| The sound bible | support | the palette's realisation (the `PROV_AUD_*` upgrade) + the bed-contrast pass (TR-AUD-039) | not authored |

**CR-AUD-01 — the contract-revision request (SYS-10).** E3b's payload is undefined in the published contract. The audio core needs `to_epoch` (or `arrive_bed_id`) on E3b to select the arriving bed without reading the epoch. Until it lands, the MVP uses the config constant `MVP_FLIP_TO_EPOCH = 1` (the monotone 0→1 assumption, boot-validated). Recorded for the batch; **not blocking** the document.

**CR-AUD-02 — the contract-revision request (SYS-03, Not Started).** The load-complete event's payload must carry the restored epoch (`restored_epoch`) so the audio's bed derivation covers a post-flip load without reading the truth state (§F.1's epoch-source rule). In-session paths are covered by the derived state; the post-load path is the recorded gap. Recorded for SYS-03's authoring; **not blocking** the document.

**The missing-input failure paths** are §G.8's table; every consumed edge names its owner there.

### K.4 · Open questions

| # | Question | Status | Recommendation / answer |
|---|---|---|---|
| OQ-AUD-1 | Where the sonic palette lives | **RESOLVED 2026-11-14 (user)** | provisional `PROV_AUD_*` roles; the sound-bible pass upgrades them in place |
| OQ-AUD-2 | The MVP score's scope + the "beat-aligned" reading | **RESOLVED 2026-11-14 (user)** | one score loop; the beat = the 60 tps tick grid; the score is untouched by the flip |
| OQ-AUD-3 | OQ-J7 ratification | **RESOLVED 2026-11-14 (user)** | −6 dB, held to the offline exit, released on reconstruct and revive |
| OQ-AUD-5 | The arena bed's identity | **RESOLVED — decided in body** | a distinct epoch-invariant asset `AMB_ARENA_STEEL_HUM` (§F.1, TR-AUD-013) |
| OQ-AUD-8 | The a11y surface's ownership | **RESOLVED — decided in body** | 3 sliders (Master/Music/SFX; Ambience+UI ride the SFX group) + MONO, rendered by SYS-24 (§H.4) |
| OQ-AUD-4 | UI voices at MVP | open — the body assumes zero | zero (the closed list stays exact); adding them is a TR-JCE-027 revision. **Probe at Gate 2:** do fully silent pause/map/settings read as broken on touch? (stage one deliberate silent interaction early in the session, before habituation confounds the read) |
| OQ-AUD-6 | The mobile audio budget | open — the body assumes the values | ≤ 10 MB disk / ≤ 16 MB runtime / 20 voices / the tick bar; the technical-director ratifies (AC-AUD-21 is PROVISIONAL on it) |
| OQ-AUD-7 | Captions for non-speech cues | open — the body assumes out-of-scope | out of scope at MVP; the event-metadata read is reserved |

---

**Counts**: 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs (22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; the gate manifest 26 smoke · 4 device · 2 MVP-lock · 0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role rows · 29 audio files · 2 contract-revision requests (CR-AUD-01, CR-AUD-02).
