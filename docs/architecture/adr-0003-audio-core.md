# ADR-0003: Audio Core — Bus Graph, Voice Pool, and the Flip's Sound Mechanism

## Status

**Proposed** — drafted 2026-11-15 by the ADR-DRAFT lane (support). It becomes
`Accepted` only on a PASS from the `/architecture-review` gate; the lane's gate
trail (CD · three-seat panel · qa-lead spot-check · micro-check) is recorded in
`docs/architecture/adr-draft-review-log.md`. If a later architecture review finds
a contradiction with a newer Accepted ADR, this ADR reverts to `Proposed` and is
superseded explicitly.

## Date

2026-11-15

## Last Verified

2026-11-15 — verified against the SYS-04 GDD at Main `3fcedc6`
(`design/gdd/audio-core.md`, APPROVED 2026-11-15), the Godot 4.7.2
engine-reference snapshots (`VERSION.md`, `breaking-changes.md`,
`modules/audio.md`), and the SYS-03 GDD at the same Main (for the load seam,
§12).

## Decision Makers

| Seat | Role in this decision |
|---|---|
| technical-director | Acceptance chair; the budget ratification (OQ-AUD-6), the ADR dependency ruling |
| audio-director | The palette's realisation boundary; the bed-contrast bar; the MONO question's owner |
| sound-designer | The voice table, the envelopes, the import pins, the telemetry |
| godot-specialist | Engine-API verdicts: `AudioServer`, bus effects, `AudioStreamPlayer`, the Ogg loop probe |
| qa-lead | The AC→gate ledger, the device fixtures, the two probes' protocols |
| user | Scope authority; the MVP posture (OQ-AUD-1/2/3/5/8 resolved 2026-11-14) |

## Summary

SYS-04's GDD fixes every audible law but deliberately leaves the engine mechanism
to this ADR: "*The engine-side import flags and the playback mechanism are the
ADR's*" (§G.6) and "*MONO … The engine mechanism is the ADR's*" (§H.4), with two
probes named as ADR gates (Ogg gapless loop points; a stereo→mono sum on Master).
This ADR decides the bus graph and its single Master limiter, the MONO stage as
one swappable `MonoStage` behind which the only stereo asset ships as a
**second encode** (no engine summing needed, so the second probe shrinks to a
click test), the preallocated 18-player voice pool with the reserved flip slot
outside the steal table, **per-tick wall-clock gain writes** for every envelope
(a `Tween` is linear in dB and would violate F-AUD-02's linear-in-gain ramp), and
the epoch-blind `AudioCore` `RefCounted` over injected ports that makes V-AUD-04's
poisoned-sentinel run possible at all.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (pinned; GDScript) |
| **Domain** | Audio (+ Core, for the tick/thread boundary) |
| **Knowledge Risk** | **MEDIUM** — the audio API is stable across 4.4–4.7 per the repo's snapshot ("No major breaking changes to the audio API in 4.4–4.6"), but two *mechanisms* this ADR needs are undocumented or unverified: the stereo→mono collapse and the Ogg loop seam. Both are probe-gated (§13) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/audio.md`; `breaking-changes.md` (4.7 `AudioStreamPlayer.area_mask` default; 4.7 `AudioEffectSpectrumAnalyzer.tap_back_pos` removed); `deprecated-apis.md`; `docs/framework/technical-preferences.md` |
| **Post-Cutoff APIs Used** | `AudioServer.set_bus_volume_db` / `get_bus_index` / `set_bus_mute` (**documented in `modules/audio.md`**); `AudioServer.set_bus_effect` + the effect slot model **[unverified for 4.7.2's limiter class name: `AudioEffectLimiter` vs `AudioEffectHardLimiter`]**; `AudioStreamPlayer.play(from_position)` **[unverified parameter name]**; `AudioStreamOggVorbis.loop` / `loop_offset` **[unverified for gapless behaviour]**; `AudioStreamWAV.loop_mode` / `loop_begin` / `loop_end`; `AudioEffectCapture` (the loop-seam probe); `AudioStreamPlayer.area_mask` default `0` (4.7 — irrelevant here: no `Area` audio overrides in the audio graph, and none may be added) |
| **Verification Required** | The 8-item register in §13. 4 items are `PROBE-PENDING` and block the first SYS-04 implementation story (and, for item 2, the bed assets' import); 4 are `DOCUMENTED`. |

> **Knowledge-gap warning (MEDIUM).** Two traps are specific to this decision.
> (1) The `AudioStreamPlayer.area_mask` default changed to `0` in 4.7: an
> `Area`-driven `audio_bus_override` would silently stop applying. This ADR
> **forbids** `Area`-based bus overrides — the bus is a property of the voice's
> slot, never of a zone — so the trap is structurally unreachable.
> (2) A `Tween` on `volume_db` is the obvious way to write an envelope and is
> **wrong** here: it interpolates in dB, while F-AUD-02 and F-AUD-04 are linear in
> **gain**. The difference is audible as a front-loaded fade and it fails
> AC-AUD-02's tick arithmetic.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | **ADR-0001** (Accepted) — §3's freeze (the bracket), §5's tick boundary (the wall clock the envelopes run on) |
| **Enables** | SYS-24's settings surface (the tuning read + the group map); SYS-29's audits (AC-JCE-31/32 find exactly the thirteen voices); SYS-15/SYS-20's triggers (the chime's sources); the sound-bible pass (the `PROV_AUD_*` upgrade and the bed-contrast bar) |
| **Blocks** | The first SYS-04 implementation story; the bed assets' import (register item 2); AC-AUD-20/21/31's device runs |
| **Ordering Note** | The audio core may be built before SYS-24 exists (the settings surface is a read-only port); the *load* seam (§12) depends on SYS-05's authoring and is carried as O-AUD-1, not as a blocker. |

## Context

### Problem Statement

SYS-04 is design-complete and APPROVED, and it is unusually explicit about what
it is not deciding: the playback mechanism, the import flags' engine side, the
MONO mechanism, and two probes that "gate the ADR" (§G.6). The GDD's laws are
mechanism-independent *by design* — "the recede is a per-voice ramp", "the gate
drops, never queues", "one duck, one application site" — which means two
implementers can satisfy every sentence of the GDD with two incompatible graphs:
one with a `Tween`-driven bed fade (linear in dB, failing F-AUD-02), one with a
pool that steals the reserved tear slot (failing AC-AUD-07), one with an
`Area`-driven bus override (silently dead after 4.7's `area_mask` default change),
one that reads `truth_epoch` to pick the arriving bed (failing V-AUD-04 and
destroying the epoch-blindness that makes the audio a leaf consumer).

The cost of not deciding is that the GDD's most valuable property — that the
audio **cannot stall the world and cannot lie about it** — depends entirely on
choices the GDD does not make.

### Current State

- `src/` contains no game code; there is no audio graph, no bus layout, no asset.
- The SYS-04 GDD is **APPROVED** (2026-11-15) at Main `3fcedc6`; its gate trail is
  `design/gdd/reviews/sys04-audio-core-review-log.md`.
- The upstream contracts are landed and frozen: SYS-09's Flip-Trigger Contract
  (TR-DR-004, E1–E7 + G1–G7), SYS-10's E3b `ambient_shift` (with the abort case
  and the latched-resume rider (i)), SYS-29's `TR-JCE-027` edge list + the
  `duck_request` schema, SYS-11's `AR-SMB-01..04` (zero audio, the bed continues,
  no duck, M4's chime is not the seam's).
- **SYS-03 has landed since the GDD was written** — the GDD's §K.3 still records
  it as "Not Started". Its `restore_complete(slot, tick)` is published and its
  schema has no load-complete event; the audio's post-load epoch source therefore
  resolves to SYS-05's `load_complete` (§12, obligation O-AUD-1).
- The sound bible does not exist; every voice and bed carries a `PROV_AUD_*` role
  with `status: PLACEHOLDER` (§E.1). The palette's realisation is the
  audio-director's, not this ADR's.

### Constraints

- **Engine**: Godot 4.7.2, GDScript; 2D; mobile-first; 60 fps; 16.6 ms frame;
  ~150 MB memory ceiling; the Pixel 6a reference SKU.
- **Budget** (§G.7): disk ≤ 10 MB; runtime ≤ 16 MB; **20 voices hard cap**
  (allocated 18); the core's tick p99.9 ≤ 0.10 ms / max ≤ 0.30 ms
  (**provisional**, OQ-AUD-6, the technical-director ratifies).
- **Design**: the core is a leaf consumer and **epoch-blind** — it never reads
  `truth_epoch`; it consumes E3b. It publishes no gameplay/state event; its only
  outward surfaces are two read-only ports (the tuning read, the event-metadata
  read). One duck, one application site. One snapshot, zero changes across
  [E1, E7]. Zero stochastic ambience one-shots.
- **Contracts**: E1–E7 consumed verbatim; a change to any consumed edge is a
  `decisions.md` contract-revision request.
- **Process**: Main is protected; work lands via branch + PR; every checkpoint is
  pushed.

### Requirements

- **R1 — One graph, one owner.** Exactly five buses, one Master effect, one
  snapshot; every voice's bus is a property of its slot, never of a zone.
- **R2 — The envelopes are tick-exact and linear in gain.** Every flip-scoped
  envelope (the recede, the arrival, the tear's tail, the duck) advances on the
  **wall clock** (`physics_tick`, ADR-0001 §5) by one tick per tick.
- **R3 — The pool is preallocated and auditable.** 18 players at boot; the
  reserved flip slot is outside the steal table; the registration list is the
  audit's input (AC-AUD-15/18).
- **R4 — The gate drops.** A gameplay one-shot requested inside [E2, E6) never
  starts, never queues, and increments a counter.
- **R5 — One duck application site.** `src/audio/` contains exactly one call that
  applies a duck; the schema has exactly three fields.
- **R6 — Epoch-blindness by construction.** Zero truth-state symbols in the core;
  a poisoned-sentinel run produces the identical order trace.
- **R7 — The bed turnover is the only loop-graph motion.** No restart, no
  loop-point jump, no snapshot change, no duck, no score touch across [E1, E7].
- **R8 — The arrival is a first start.** From the floor, at the release boundary,
  never a pre-roll and never a resume of a sounding loop.
- **R9 — Failures never block and never synthesize.** Every missing input has a
  named record and a named behaviour; no omission produces a substitute.
- **R10 — The budget is measurable.** Disk, runtime, voices and the core's tick
  are device-measurable on the reference SKU.

## Decision

### 1 · Scope and non-goals

**In scope.** The node graph and the core/adapter seam; the bus graph and its one
Master effect; the MONO stage; the voice pool, the classes and the steal; the bed
director (recede/arrival); the tear; the duck; the gate and the failsafe; the
import pins' engine side and the two probes; the load seam; the test seams; the
verification register.

**Out of scope (owned elsewhere).** The flip's choreography and timing (SYS-09);
the epoch and E3b's emission (SYS-10); the edge list and the duck's *publication*
(SYS-29); the seam's material (SYS-11); the score's composition and the palette
(the audio-director, via the sound bible); the settings UI (SYS-24); the offline
screen's lifetime (SYS-15); the captions (OQ-AUD-7, out of scope at MVP).

**Non-goals.** No spatialised audio (no `AudioStreamPlayer3D`, no `Area` bus
overrides); no interactive-music or playlist streams; no runtime DSP authoring;
no GDExtension at MVP; no stochastic ambience; no UI voices; no snapshot changes;
no second duck family; no reading the truth state; no per-press chatter.

### 2 · The node graph and the core/adapter seam

```
 SYS-09 E1/E4/E7 ─┐
 SYS-29 E2/E5/E6 ─┤   ┌──────────── AudioAdapter (Node) ────────────┐
 SYS-10 E3b ──────┼──▶│ subscribes · stamps · forwards · publishes  │
 SYS-02 room ─────┤   │ nothing gameplay-facing                     │
 SYS-05 load ─────┘   └──────────────┬──────────────────────────────┘
                                     │ EdgeEvent{edge_id, tick, clock, payload}
                                     ▼
              ┌──────────────── AudioCore (RefCounted, pure) ───────────────┐
              │ FlipStateMachine · BedDirector · VoicePool · DuckStage      │
              │ Gate · Failsafe · VariationRng · OrderTrace · EdgeTrace     │
              │ TelemetryRing(256) · Tuning                                  │
              └───┬───────────┬────────────┬───────────┬───────────┬────────┘
                  │ ClockPort │ BusPort    │ PlayerPort│ Telemetry │ MetaPort
                  ▼           ▼            ▼           ▼           ▼
              physics_tick  AudioServer  18 players   ring     {event_id,tick}
```

**The seam is one-way.** The adapter subscribes to the six publishers and
forwards stamped edge events; the core returns **commands** (start voice N with
stream S at gain G, set bus volume V, emit record R); the adapter executes them.
Nothing in the core calls `AudioServer`, `AudioStreamPlayer`, `Time`,
`SceneTree`, `RenderingServer`, or reads `truth_epoch` — that is V-AUD-04, and it
is enforceable by grep because the core holds ports instead of singletons.

**Why this matters beyond style.** V-AUD-04's poisoned-sentinel run ("a stubbed
bed run produces the identical order trace with the truth state replaced by a
poisoned sentinel") is only possible if the core *cannot* read the truth. A core
that reads it and merely promises not to would make the test a code-review
assertion rather than a fixture.

### 3 · The bus graph and its one Master effect

```
Master (0 dB)  ──[ Limiter ]──▶ device
  ├── Music   (−6 dB)   1 voice   — the duck's only target
  ├── Ambience(−9 dB)   4 voices  — 2 sounding during a turnover
  ├── SFX     (−3 dB)  12 + 1 reserved
  └── UI      (−6 dB)   0 voices  — reserved; zero voices at MVP
```

- **One effect in the whole graph**: the limiter on Master. It exists for the
  mobile speaker, not for loudness (TR-AUD-035). The class is probe item 1
  (`AudioEffectHardLimiter` if 4.7.2 exposes it, else `AudioEffectLimiter`); the
  choice is confined to one factory function so a swap touches no call site.
- **One snapshot** (`SNAP_GAMEPLAY`). The offline state is the duck, not a
  snapshot; the bracket is an event-gate state, not a mix state. That is what
  makes "no snapshot change that reads as a beat" provable: there is nothing to
  change (TR-AUD-027).
- **The bus layout is a committed resource** (`default_bus_layout.tres`) and its
  five buses, parents and nominal volumes are asserted at boot against §G.1; a
  mismatch is a boot failure, not a warning (AC-AUD-26).
- **No `Area` bus overrides, ever.** In 4.7 `AudioStreamPlayer.area_mask`
  defaults to `0`; an `Area`-driven override would silently stop applying. The
  bus is a property of the voice's slot. (This is a *structural* answer to a
  version trap, not a stylistic preference.)

### 4 · The MONO stage

`MONO` (default off, `MONO_DEFAULT`) must collapse every bus to mono (TR-AUD-037,
AC-AUD-22). Four of the five buses are **already mono by import** (§G.6: beds
mono, one-shots mono); the score is the only stereo asset. So MONO's whole job is
the score, and the GDD names the difficulty honestly: "*a stereo→mono sum on
Master (no documented built-in)*".

**Decision.** MONO is one **Master-bus stage behind a `MonoStage` interface**, and
the MVP implementation is a **second encode of the score**, not an engine sum:

- The score ships as `MUS_HOUSE_LOOP` (stereo, the only stereo asset) **and** its
  mono fold `MUS_HOUSE_LOOP_MONO` — a content-pipeline artifact of the same
  asset, not a new voice and not a new bed. **The GDD's 29-asset arithmetic
  stands** (25 one-shots + 3 beds + 1 score); the fold is an encode, and the disk
  budget carries it (3.7 MB → ~4.25 MB against a 10 MB bar, §G.7).
- The toggle swaps the Music player's stream **preserving the playhead**
  (`play(from_position)`), preceded by a **2-tick per-voice gain ramp** so the
  swap cannot click. The ramp is a per-voice gain motion, the same mechanism the
  bed recede uses — **never a `duck_request`** (V-AUD-01's one-duck audit would
  fail, and a settings toggle is not a mix beat).
- **Nothing else changes**: the four mono buses are unaffected, no bus gain moves,
  no snapshot changes.

**Why not an engine sum.** A summing `AudioEffect` would need a GDExtension build
(a native toolchain and export-binary verification the MVP pipeline does not
have), and the GDD itself records that no documented built-in exists. A
double-encode is GDScript-only, deterministic, and testable — and it reduces the
GDD's second probe from "does a stereo→mono sum exist?" (an engine question) to
"does the swap click?" (a two-tick ramp question, answerable in one fixture).

**The upgrade path.** If the sound-bible pass finds the fold audible at the
toggle (a stereo image collapsing abruptly), the fix is a native summing effect
behind the same `MonoStage` interface. The interface is the decision; the
implementation is swappable.

### 5 · The voice pool and the steal rule

**Eighteen preallocated `AudioStreamPlayer` nodes at boot**, each with
`max_polyphony = 1`: 13 on SFX (12 pool + **1 reserved flip slot**), 4 on
Ambience, 1 on Music, 0 on UI. `allocated = 12 + 4 + 1 + 1 + 0 = 18` of a 20 hard
cap (2 slack) — the arithmetic reproduces from the knobs (F-AUD-05, AC-AUD-11).

- **Why fixed players, not `max_polyphony` on a few nodes**: the steal rule needs
  per-voice identity (class, age, signature flag) and the closed-list audit needs
  a registration list that can be counted. A polyphonic player hides both.
- **The reserved slot is outside the steal table.** The tear is P0 and is never a
  steal candidate; a full SFX pool can never starve it (AC-AUD-07). This is
  enforced structurally — the reserved player is not in the candidate array — not
  by a class check.
- **The steal is a pure function** over a preallocated `VoiceSlot` array:
  `admit(request) -> ADMIT | STEAL(victim_index) | DROP`, candidates ordered by
  class then age, **excluding P0 and every signature** (P1: death, revive, memory).
  If only P0/P1 remain, the request drops.
- **Ambience has 4** because a turnover sounds two beds at once (the receding and
  the arriving) and a room-entry crossfade may need a second pair; the pool is the
  bound, and a fifth concurrent bed is a design error, not a config.
- **The gate is a boolean on the core, not a bus mute.** `set_bus_mute` on SFX
  would silence already-sounding voices (a cut is a click and reads as a bug —
  §D.3's ring-out law). The gate refuses **new** starts and leaves the ringing
  voices alone.

### 6 · The bed director: receding-first on the wall clock

Every flip-scoped envelope advances **one step per `physics_tick`** (ADR-0001 §5),
computed from F-AUD-02's tick boundaries:

```
τ0 ──recede (15 ticks, linear in GAIN 1.0 → 10^(−60/20))──▶ recede_end
   ──floor hold──▶ release_boundary = τ0 + N
   ──arrival (15 ticks, linear in GAIN 0.001 → 1.0)──▶ arrive_end
```

- **Linear in gain, converted per tick**: each tick computes
  `gain = lerp(1.0, floor_gain, k / ticks)`, then writes
  `volume_db = 20·log10(gain)` (F-AUD-01). **A `Tween` on `volume_db` would
  interpolate in dB and violate the law** — the audible difference is a
  front-loaded fade, and the tick arithmetic of AC-AUD-02 would not reproduce.
  This is the single most likely way to build a graph that satisfies the prose
  and fails the fixtures.
- **The recede is a per-voice ramp**, never a `duck_request` (§D.2 clause 4).
- **The arrival is a first start**: `play()` at the loop start with the gain
  starting at the floor, at the release boundary — never a resume, never a
  pre-roll (§G.5, TR-AUD-030).
- **`min(recede_ticks, N)`** guards a short freeze: the recede compresses, the
  hold disappears, the arrival still waits for the boundary.
- **The arena is excluded by the order record**, not by a runtime check: the
  target set `{RM-01..RM-05}` and `excluded {RM-06}` are carried in the order
  record so the assertion holds even when only one bed is sounding (TR-AUD-008,
  AC-AUD-03).
- **The abort path emits zero orders** and never enters `RELEASED`; the degenerate
  tear plays, the bracket closes at the force-release-derived `freeze_close` as an
  **event**, and the bed stays put (TR-AUD-011).

### 7 · The tear

`EV_FLIP_TEAR` (success) and `EV_FLIP_TEAR_ABORT` (degenerate) are two event IDs
so the trace can assert the degenerate form; both occupy the reserved P0 slot,
latch once per run, and run 24 ticks (`ceil(400 × 60 ÷ 1000)`) inside the 26-tick
window with 2 ticks of slack. The abort variant has **no transient and no success
beats** — the same body and tail. A missing tear asset makes the flip **silent**
with one `AUD_ASSET_MISSING` record; the choreography never waits on audio
(TR-AUD-010, AC-AUD-07).

The tear's tail may ring **past E6** while the gate is open — concurrency is legal
and already-sounding voices are never truncated (§D.3).

### 8 · The duck: one site, one family, the wall clock

```gdscript
# THE single application site in src/audio/. Called once per death; released on
# the offline exit (reconstruct / revive / quit).
func apply_duck(request: DuckRequest) -> void:
    # request = {bus, dB, hold}; exactly three fields; bus ∈ {MUSIC}; dB ∈ [−12, 0]
    _duck = DuckStage.new(request.bus, request.dB, request.hold)   # wall-clock envelope
```

- The envelope is **F-AUD-04 on the wall clock** (the logic clock stalls inside
  the freeze and does not run across the death→offline transition, where the duck
  lives). Each tick: `gain(t)` → `bus_volume_db = NOMINAL + 20·log10(gain(t))`.
  At `−6 dB` the Music bus reads `−6 + −6 = −12 dB`.
- **The release is on the offline exit** — reconstruct, revive, and the quit exit
  (SYS-15's third exit; `UNTIL_OFFLINE_EXIT` already covers it, the schema is
  unchanged). The **backstop** is the offline screen's tree-exit
  (`AUD_DUCK_RELEASE_BACKSTOP`), because a lost release edge would leave the score
  ducked forever.
- **A missing bus** drops the request with one record — **never a silent Master
  duck**.
- **One application site** is structural: the duck lives in `DuckStage` and
  `apply_duck` is its only entry; V-AUD-01's static audit finds exactly one call
  site, and no hit-stop / flip / seam / reveal-hold / pause source calls it.

### 9 · The gate and the failsafe

- **The gate**: `gate_open` is false across [E2, E6). A gameplay one-shot request
  inside returns `DROP` and increments `AUD_GATE_DROP` — **never queued**, because
  a queue would replay stale sounds at release, which is a burst, and a drop is
  honest. A room-entry request inside the bracket is dropped with the rest; the
  mismatch persists to the next room entry (§K.2 #14).
- **The licensed exception** is the tear at τ0: the bracket forbids *foreign*
  one-shots, not the flip's own voice. Named here so it is never mistaken for a
  bug.
- **The failsafe**: armed at E2 (or from E1 if E2 never arrives). If E6 has not
  arrived by `GATE_FAILSAFE_MS` (700 ms = the 600 ms max freeze + 100 ms margin),
  the gate opens, `AUD_GATE_FAILSAFE` fires, the arrival never starts, and the
  receded bed **holds at the floor** until the next room entry re-applies the
  room's bed. **E6 wins the deadline**: an E6 that arrives before the deadline
  cancels the failsafe. This is the only failure SYS-04 contains itself
  (TR-AUD-033, AC-AUD-13).
- **The state machine** is the GDD's §D.1 verbatim; `DEGRADED` is reachable only
  from `HELD` by the abort's force-release, which **takes precedence** over an E6.

### 10 · Import pins and the two probes

The GDD's pins (§G.6) are the *what*; this ADR owns the *engine side*:

| Asset class | Format | Channels | Rate | Loop | Engine side |
|---|---|---|---|---|---|
| Beds | Ogg Vorbis q0.5–0.6 | mono | 44.1 kHz | on, seamless | `AudioStreamOggVorbis.loop = true`; the loop seam is **probe item 2** |
| Score | Ogg Vorbis q0.6–0.7 | stereo | 44.1 kHz | on, seamless | as above; plus the mono fold (§4) |
| One-shots | WAV 16-bit PCM | mono | 44.1 kHz | off | trimmed, −3 dBFS peak, no silence padding; no loop flags |

- **The import flags are committed** (`*.ogg.import` / `*.wav.import`) and an
  **import audit** reads every `.import` and asserts the table (AC-AUD-32, LINT).
  A re-import that flips a channel count is a CI failure, not a mix surprise.
- **Probe 1 — the limiter class** (register item 1): which of
  `AudioEffectHardLimiter` / `AudioEffectLimiter` 4.7.2 exposes, and its
  gain-reduction readback for AC-AUD-20's ≤ 3 dB high-water.
- **Probe 2 — the Ogg loop seam** (register item 2): record ten loop iterations
  through an `AudioEffectCapture` on the Ambience bus and assert no discontinuity
  above the seam threshold at the loop point (encoder padding is the risk).
  **Fallback, pre-priced**: beds as `AudioStreamWAV` with
  `loop_mode = LOOP_FORWARD` and sample-exact `loop_begin`/`loop_end` — mono
  44.1 kHz 16-bit is 88.2 kB/s, so the three beds fit the 10 MB bar at a combined
  bed duration ≤ ~84 s (10 − 1.1 score − 1.5 one-shots = 7.4 MB). The fallback
  changes no law; only the file format.
- **No `AudioEffect` other than the limiter** may be added without a new ADR: the
  "one effect" property is what makes the mix auditable.

### 11 · Epoch-blindness and the ports

The core consumes **six** inbound things and publishes **none**:

| Inbound | Owner | Port | Missing → |
|---|---|---|---|
| E1 / E4 / E7 | SYS-09 | adapter signal | `AUD_MISSING_E1/_E7` (E4 has no obligation) |
| E2 / E5 / E6 | SYS-29 | adapter signal | `AUD_MISSING_E2/_E5/_E6` + the named behaviour (§G.8) |
| E3b `ambient_shift` | SYS-10 | adapter signal | `AUD_MISSING_E3B`; **the bed stays put; no self-shift** |
| Room activation | SYS-02 | adapter signal | the bed re-applies at the next entry |
| Load-complete (`restored_epoch`) | SYS-05 (§12) | adapter signal | `AUD_LOAD_MISSING`; the derived state stands |
| The tick | ADR-0001 | `ClockPort` | a boot-order defect; the dev assert |

**The allowlist** is exactly two read-only ports: the tuning read
(`MASTER_VOLUME`/`MUSIC_VOLUME`/`SFX_VOLUME`/`MONO` + the bus group map, for
SYS-24) and the event-metadata read (`{event_id, tick}`, reserved for captions).
They are ports, not events. A grep for cross-system calls from `src/audio/` must
match only these two (AC-AUD-19).

**No `truth_epoch`, no mutation registry, no truth flag.** The MVP's monotone 0→1
assumption is the **config constant** `MVP_FLIP_TO_EPOCH = 1`, boot-validated, and
it is removed when CR-AUD-01 (E3b's `to_epoch` payload) lands.

### 12 · The load seam — `restored_epoch` (obligation O-AUD-1)

The GDD's CR-AUD-02 asked SYS-03's authoring to carry `restored_epoch` on a
load-complete payload. **SYS-03 has since landed and does not publish a
load-complete event**: its contract is `restore_complete(slot, tick)` plus
`load_result`, and `load_complete` belongs to **SYS-05** (Not Started). The
request therefore resolves to a precise owner:

- **The payload rides SYS-05's `load_complete`**: `load_complete` must carry
  `restored_epoch`, derived from the store after SYS-03's `restore_complete`. No
  SYS-03 change is needed — the epoch is in the restored store, and SYS-03's
  ordering guarantee (`restore_complete` strictly before `load_complete`) is what
  makes the value available in time.
- **The audio side is already built for it**: the core applies `restored_epoch` to
  its derived bed map at the load-complete tick, so the first room entry after a
  load resolves the epoch-correct bed (TR-AUD-022).
- **Until SYS-05 lands**, the GDD's recorded gap stands: a post-flip load boots on
  the derived epoch-0 state. The bounded fallback is the GDD's own, and it is
  **not** a blocker for the audio core.
- **O-AUD-1** (carried obligation): SYS-05's authoring must include
  `restored_epoch` on `load_complete`. Recorded here and in the lane report; **no
  frozen contract is edited** — SYS-04's text is unchanged, and this is a seam
  resolution, not a revision.

### 13 · Test seams

- **`ClockPort`** — the injected `physics_tick`, so every envelope is
  fixture-drivable at exact ticks.
- **`BusPort`** — `set_volume_db(bus, db)`, `get_volume_db(bus)`,
  `apply_effect(slot, effect)`; the fake records a per-tick gain trace, which is
  what AC-AUD-02's schedule fixture asserts.
- **`PlayerPort`** — `start(slot, stream_id, gain_db, from_position)`,
  `stop(slot)`, `is_playing(slot)`, `playhead(slot)`; the fake is the pool's
  audit surface (AC-AUD-07/11).
- **`TelemetryPort`** — the 256-record ring; the fixtures drain it (AC-AUD-14).
- **The static audits** (LINT) are greps over `src/audio/`: no truth symbols
  (V-AUD-04), exactly thirteen registered voices (V-AUD-02), exactly one duck
  application site (V-AUD-01), only the two allowlisted ports (AC-AUD-19).
- **The device fixtures** (AC-AUD-20/21/22/31) run on the Pixel 6a reference SKU;
  nothing pixel- or channel-accurate is asserted headless.

### 14 · The engine verification register

| # | Item | Verdict | Blocks |
|---|---|---|---|
| 1 | The Master limiter class in 4.7.2 (`AudioEffectHardLimiter` vs `AudioEffectLimiter`) and its gain-reduction readback | **PROBE-PENDING** | The first story; AC-AUD-20 |
| 2 | Ogg Vorbis loop seams are gapless on 4.7.2 (beds, score) | **PROBE-PENDING** | The beds' import; AC-AUD-28/30 |
| 3 | `AudioStreamPlayer.play(from_position)` preserves the playhead across the MONO swap | **PROBE-PENDING** | The MONO stage; AC-AUD-22 |
| 4 | `AudioServer.set_bus_volume_db` per tick at 60 tps is within the core's tick bar and does not zipper | **PROBE-PENDING** | AC-AUD-02/21 |
| 5 | Five buses + one Master effect is inside the mobile mix budget (the limiter is the only CPU cost) | **DOCUMENTED** (`modules/audio.md`: the mixing is on the audio thread) | — |
| 6 | `AudioServer.set_bus_volume_db` / `get_bus_index` / `set_bus_mute` exist and behave as used | **DOCUMENTED** (`modules/audio.md`) | — |
| 7 | `AudioEffectCapture` can record the Ambience bus for the loop-seam probe | **DOCUMENTED** (the class is the documented capture route) | — |
| 8 | `AudioStreamWAV.loop_mode` / `loop_begin` / `loop_end` give sample-exact loops (the fallback) | **DOCUMENTED** | — |

`PROBE-PENDING` is an open verdict: items 1–4 block the first implementation story
and item 2 blocks the beds' import. No story may consume one as settled fact.

### Architecture diagram — the flip's 34 ticks

```
tick  100        101        116      119              134
      │ E1       │ E2+E3b   │        │ E6             │ E7 → arrive_end
      │ arm      │ gate shut│ recede │ gate open      │ resume
      │ beds+    │ recede→  │ ends   │ arrival starts │
      │ tear     │ tear at  │        │ at the floor   │
      │ resident │ τ0       │        │                │
      │          └── floor hold ──────┘                │
      │  zero orders before τ0 · zero arena orders anywhere in [100,134]
      │  zero ducks · zero snapshot changes · zero loop restarts
      └── the score untouched, playing, at the same playhead
```

### Key interfaces

```gdscript
# ---- core (pure, injected; holds NO singleton) -----------------------------
class_name AudioCore extends RefCounted

func on_edge(edge: EdgeEvent) -> void          # E1/E2/E3b/E4/E5/E6/E7
func on_room_entry(room_id: StringName) -> void
func on_load_complete(restored_epoch: int) -> void   # O-AUD-1's payload
func tick(t: int) -> void                      # envelopes + failsafe + drain
func request_voice(event_id: StringName, tick: int) -> void  # gate + pool
func apply_duck(request: DuckRequest) -> void   # THE one duck site
func set_mono(on: bool) -> void
func tuning_read() -> Dictionary                # SYS-24's port
func event_metadata() -> Array[Dictionary]      # the caption port (reserved)

# ---- the class table (the steal's only input) ------------------------------
enum VoiceClass { P0_RESERVED, P1_SIGNATURE, P2_COMBAT, P3_FEEDBACK }

# ---- the result of an admission --------------------------------------------
# ADMIT(slot) | STEAL(victim_slot) | DROP(reason: GATE | POOL | BUS_MISSING)
```

### Implementation guidelines

- **Every envelope is a tick loop, never a `Tween`.** Write gain, convert to dB.
- **The reserved player is not in the candidate array.** Never a class check.
- **Never mute a bus to gate a voice.** The gate refuses starts; it does not cut.
- **Never read `truth_epoch`.** If a bed needs an epoch, it comes from E3b or
  `restored_epoch`.
- **Never add an `AudioEffect`.** One limiter, one MONO stage, nothing else.
- **Never queue a one-shot.** Drop and count.
- The order record is written **once per run**; a second `ambient_shift` in one
  run is a defect, not a re-order.

## Alternatives Considered

### Alternative 1: Spatialised audio (`AudioStreamPlayer3D`) with `Area` bus overrides

- **Description**: place emitters in the room, let `Area3D.audio_bus_override`
  route them.
- **Pros**: free occlusion/attenuation; zones map naturally to rooms.
- **Cons**: the game is 2D and the mix is authored, not simulated; and 4.7 changed
  `AudioStreamPlayer.area_mask`'s default to `0`, so overrides silently stop
  applying.
- **Estimated Effort**: 1.3×.
- **Rejection Reason**: the bus must be a property of the slot (R1); a zone-driven
  mix cannot be asserted per voice, and the version trap is structural.

### Alternative 2: `AudioStreamInteractive` / `AudioStreamPlaylist` for the beds

- **Description**: let the engine's interactive-music resources handle the
  transition.
- **Pros**: built-in crossfade clips; less code.
- **Cons**: the transition's timing would be the engine's (clip durations in
  seconds), while F-AUD-02 is tick-exact and the arrival must start *at* the
  release boundary; and the recede must be linear in gain.
- **Estimated Effort**: 0.9×.
- **Rejection Reason**: the laws are tick arithmetic; an engine clip clock cannot
  express "the arrival's first sample is at tick ≥ 119".

### Alternative 3: `Tween`-driven envelopes

- **Description**: `create_tween().tween_property(player, "volume_db", …)`.
- **Pros**: two lines per envelope; no per-tick code.
- **Cons**: interpolates in **dB** (F-AUD-02/04 are linear in gain), runs on
  `_process` (frame-rate dependent), and cannot be asserted at a tick boundary.
- **Estimated Effort**: 0.2×.
- **Rejection Reason**: R2. It satisfies the prose and fails AC-AUD-02.

### Alternative 4: One polyphonic player per bus

- **Description**: one `AudioStreamPlayer` with `max_polyphony = 12`.
- **Pros**: minimal node count; the engine handles concurrency.
- **Cons**: no per-voice class, age or signature flag, so the steal rule is
  unimplementable; no reserved slot; the registration scan cannot count voices.
- **Estimated Effort**: 0.4×.
- **Rejection Reason**: R3 and AC-AUD-07/11/15 need per-voice identity.

### Alternative 5: The duck as a mix-snapshot change

- **Description**: define a `SNAP_OFFLINE` snapshot that ducks Music and switch
  to it on death.
- **Pros**: declarative; one resource per state.
- **Cons**: it makes the duck a *snapshot change*, which V-AUD-05 forbids in the
  flip window and which the GDD explicitly rejects ("the offline state is the duck
  request, not a snapshot"); and the envelope (120/240 ms) is not expressible as a
  snapshot.
- **Estimated Effort**: 0.7×.
- **Rejection Reason**: TR-AUD-027/036.

### Alternative 6: A GDExtension stereo→mono summing effect at MVP

- **Description**: write a native `AudioEffect` that sums L+R on Master.
- **Pros**: the "correct" DSP answer; no extra asset.
- **Cons**: a native toolchain, per-platform export binaries, and a second build
  artifact to verify — for one asset that is already mono everywhere else.
- **Estimated Effort**: 2× plus release-pipeline work.
- **Rejection Reason**: §4's double-encode is GDScript-only and the same interface
  accepts the native effect later.

### Alternative 7: WAV beds from day one

- **Description**: skip the Ogg loop question entirely.
- **Pros**: sample-exact loops; no encoder padding; no probe.
- **Cons**: ~10× the disk per second; the 10 MB bar then bounds the beds' total
  duration to ~84 s.
- **Estimated Effort**: 1.0×.
- **Rejection Reason**: kept as the **pre-priced fallback** (register item 2) —
  chosen only if the Ogg seam fails the probe.

### Alternative 8: Read `truth_epoch` in the core (simplest bed resolution)

- **Description**: pick the bed by reading the epoch.
- **Pros**: no derived state, no load seam, no `restored_epoch` obligation.
- **Cons**: destroys epoch-blindness (V-AUD-04), makes the audio a state consumer,
  and creates a second reader of the truth that can disagree with SYS-02.
- **Estimated Effort**: 0.3×.
- **Rejection Reason**: TR-AUD-003. The poisoned-sentinel run would be impossible.

### Alternative 9: Queue one-shots inside the bracket

- **Description**: hold gameplay one-shots and release them at E6.
- **Pros**: nothing is lost.
- **Cons**: a release burst of stale sounds — the exact "the mix performs" failure
  the design rejects.
- **Estimated Effort**: 0.5×.
- **Rejection Reason**: TR-AUD-009 — drop, never queue.

### Alternative 10: `set_bus_mute` as the gate

- **Description**: mute SFX across the bracket.
- **Pros**: one line.
- **Cons**: truncates already-sounding voices (a cut is a click), violating the
  ring-out law, and it is a bus-gain change inside [E1, E7] (V-AUD-05).
- **Estimated Effort**: 0.1×.
- **Rejection Reason**: R4 + §D.3's ring-out law.

## Consequences

### Positive

- The graph is small enough to audit completely: five buses, one effect, eighteen
  players, thirteen voices, one duck site — every count is a grep.
- The core/adapter seam makes the epoch-blindness and the "publishes nothing"
  claims *structural* rather than promises, which is what V-AUD-04's sentinel run
  needs.
- Per-tick gain writes make every envelope fixture-assertable at an exact tick,
  which is the whole basis of the 22 GUT ACs.
- The MONO decision removes an engine unknown (no summing effect exists) and
  replaces it with a priced asset variant.
- The bed-format fallback is pre-priced, so probe 2 cannot become a schedule
  surprise.

### Negative

- Eighteen nodes and a per-tick loop are more code than a `Tween`-driven graph;
  the envelopes are hand-rolled arithmetic that must stay in step with F-AUD-02/04.
- The MONO fold adds one encode to the content pipeline and ~0.55 MB to disk.
- The voice pool's fixed sizing means a future voice class needs a code change
  (a new slot array entry), not a config edit — deliberate, since the cap is a
  device fact.
- `GATE_FAILSAFE_MS` is the one failure the system contains itself; it is also the
  one place a wrong value is silent until the E6-lost fixture runs.

### Neutral

- The sound bible does not exist; every role is `PROV_AUD_*` / `PLACEHOLDER` and
  this ADR pins no realisation.
- OQ-AUD-6 (the budget) stays open and provisional; the technical-director
  ratifies it, not this ADR.
- OQ-AUD-4 (UI voices) and OQ-AUD-7 (captions) stay open; the metadata port is
  reserved so neither requires a re-authoring.
- SYS-03's landed state makes CR-AUD-02's owner precise (SYS-05) without editing
  any frozen text.

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| A `Tween` creeps into an envelope | Medium | High | R2; AC-AUD-02's tick fixture; the review guideline |
| The reserved tear slot is stolen under a flood | Low | High | The slot is outside the candidate array; AC-AUD-07's flood fixture |
| Ogg loop seams click on the beds | Medium | High | Probe 2; the pre-priced WAV fallback |
| The MONO swap clicks | Medium | Medium | The 2-tick per-voice ramp; AC-AUD-22; probe 3 |
| A per-tick bus write zippers or costs too much | Low | High | Probe 4; the core's tick bar (p0.10/max 0.30 ms) |
| An `Area` bus override is added later | Low | High | R1 + the boot assert on the five buses; the 4.7 `area_mask` note |
| The E6-lost failsafe never fires (wrong `GATE_FAILSAFE_MS`) | Low | High | AC-AUD-13's injection; the knob's range [600, 1200] |
| The duck's release edge is lost | Medium | Medium | The offline screen's tree-exit backstop + `AUD_DUCK_RELEASE_BACKSTOP` |
| Epoch-blindness erodes (a convenience read) | Medium | High | V-AUD-04's grep + the poisoned-sentinel run; `MVP_FLIP_TO_EPOCH` is a constant |
| `restored_epoch` never lands on SYS-05 | Medium | Medium | O-AUD-1 carried to SYS-05's authoring; the bounded fallback is playable |

## Performance Implications

| Metric | Before | Expected After | Budget |
|---|---|---|---|
| CPU — the core's tick | N/A (no code) | ≤ 0.10 ms p99.9 / ≤ 0.30 ms max (**provisional**, OQ-AUD-6) | 16.6 ms frame; the core routes, the mix is on the audio thread |
| CPU — the mixer | N/A | 18 voices + 1 effect | The 20-voice hard cap |
| Memory — audio runtime | N/A | ≤ 16 MB (one-shots resident; beds/score stream) | ~150 MB ceiling (~10%) |
| Disk | N/A | ~3.7 MB (25 one-shots + 3 beds + 1 score) + ~0.55 MB (the MONO fold) | ≤ 10 MB |
| Load time | N/A | the beds' first start is at the release boundary, not at load | Negligible |
| Network | N/A | None | N/A |

The six-system envelope join is recorded **NOT-JOIN** at MVP (the SYS-09
precedent): SYS-04 prices its **own** tick budget rather than a frame share, and
the bar is provisional pending the technical-director's ratification.

## Migration Plan

No existing audio code or assets exist; the migration is a greenfield scaffold.

1. **The bus layout + the limiter.** Add `default_bus_layout.tres` (five buses,
   the §G.1 volumes), the limiter factory, and the boot assert.
2. **The core.** Add `src/audio/core/` (`AudioCore`, `FlipStateMachine`,
   `BedDirector`, `VoicePool`, `DuckStage`, `Gate`, `VariationRng`, `OrderTrace`,
   `TelemetryRing`, `Tuning`) and the GUT suite under `tests/unit/audio/` with the
   four port fakes. No `AudioServer`, no node.
3. **The adapter + the players.** Add `AudioAdapter` and the eighteen players; wire
   the six subscriptions; wire `ClockPort` to ADR-0001's `physics_tick`.
4. **The assets' import.** Commit the `.import` flags; run the import audit; close
   probe 2 (the loop seam) before the beds are accepted.
5. **The MONO stage.** Produce the score's mono fold; wire `MonoStage`; close
   probe 3.
6. **The device gate.** AC-AUD-20/21/22/31 on the Pixel 6a; ratify OQ-AUD-6.

**Rollback plan.** Delete `src/audio/` and the bus layout; no save data, no schema
and no cross-system contract is touched. The GDD and this ADR remain; a
superseding ADR would replace the graph, not the laws.

## Validation Criteria

- [ ] The bus table matches §G.1 exactly; the SFX pool is 12 + 1 reserved; a duck
      naming a non-Music bus is rejected with a record (AC-AUD-26).
- [ ] `allocated` = 18 of 20 reproduces from the knobs; `VOICE_CAP < allocated` is
      a boot failure; a full SFX pool never starves the tear (AC-AUD-07/11).
- [ ] The steal order is P3 → P2 → drop; P0 and every signature survive their
      floods (AC-AUD-11).
- [ ] The schedule reproduces exactly: recede 101→116, floor hold 116→119,
      arrival 119→134 at the defaults, and 116→122 / 122→137 at N = 21
      (AC-AUD-02) — **linear in gain**, not in dB.
- [ ] The arrival's first sample is at ≥ the release boundary and starts at the
      floor; the sounding loop's playhead advances monotonically across [E2, E6]
      (AC-AUD-28).
- [ ] Zero arena-bed orders across [E1, E7]; the stub-bed hash matches (AC-AUD-03).
- [ ] The gate drops (never queues) and the drop counter equals the request count;
      a voice sounding at E2 is the same voice at E6 (AC-AUD-06).
- [ ] The E6-lost failsafe opens the gate at `GATE_FAILSAFE_MS` only without E6;
      `HELD → IDLE` with no `RELEASED` entry (AC-AUD-13).
- [ ] The abort trace shows E2, the degenerate tear, the derived E6 as an event,
      and zero orders (AC-AUD-04).
- [ ] Exactly one duck request per death, attack 8 / release 15 ticks, both exits
      release it; one application site in `src/audio/` (AC-AUD-10/17).
- [ ] MONO collapses every bus; the Ambience and UI buses follow the SFX slider;
      the swap does not click (AC-AUD-22).
- [ ] Exactly thirteen registered one-shot IDs; a 10,000-tick soak emits zero
      ambience one-shots (AC-AUD-15).
- [ ] Zero truth-state symbols in the core; the adapter's subscriptions equal the
      publisher map; the allowlist grep matches only two ports (AC-AUD-19).
- [ ] The snapshot hash is unchanged and the score untouched across [E1, E7]
      (AC-AUD-16).
- [ ] The import audit matches §G.6 on every asset; the metadata read is present on
      every registered voice and bed (AC-AUD-32).
- [ ] Disk ≤ 10 MB, runtime ≤ 16 MB, voices ≤ 20, the core's tick within its
      (provisional) bar on the Pixel 6a (AC-AUD-21).
- [ ] Zero `PROBE-PENDING` items remain before the first implementation story.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|---|---|---|---|
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-001/002 — consume E1–E7 verbatim; the publisher map; publishes nothing | The adapter's six subscriptions equal the publisher map; the core returns commands, never events (§2, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-003 — epoch-blindness | Ports instead of singletons; `MVP_FLIP_TO_EPOCH` as a boot-validated constant; the poisoned-sentinel run (§2, §11, §13) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-004 — the closed list is closed | Thirteen voices over eighteen preallocated slots; the registration scan (AC-AUD-15/18) (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-005 — the death duck is consumed, not designed | `DuckStage` + one `apply_duck` site; three fields; `UNTIL_OFFLINE_EXIT` (§8) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-006 — the missing-input failure paths | The six-row inbound table with named records and no synthesized substitute (§11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-007 — the arm is silent (E1) | The arm validates and makes resident; no player starts; no order before τ0 (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-008 — the receding-first law | The wall-clock schedule, the target set in the order record, the arena exclusion (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-009 — the stillness bracket | `gate_open = false`; drop-never-queue; no loop restart; zero snapshot changes; ring-out (§5, §9) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-010 — the tear | The reserved P0 slot outside the steal table; 24 ticks in a 26-tick window; the silent-asset path (§7) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-011 — the abort path | Zero orders; the force-release-derived `freeze_close` as an event; `DEGRADED` precedence; no `RELEASED` (§6, §9) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-012 — the resume re-run | The order trace relative to the raise tick; the post-resume hash equals the fresh run's (§6, §13) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-013/014 — the arena hum; the wing's no-op | RM-06 excluded by the order record; no separate wing bed; the room-entry path only at real entries (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-015…021 — the eight one-shot voices | The voice table's slots, classes, retrigger floors and signatures; the variation law's deterministic draw (§5, §7) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-022/024/025 — the bed table; the seam's exemption; the transition law | The derived bed map + `restored_epoch`; the room-entry crossfade only at a real entry; no restart, no duck (§6, §12) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-023 — beds only, no stochastic detail | Zero ambience one-shot registrations; the 10,000-tick soak (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-026/034 — the bus layout; the nominal mix | The committed bus layout + the boot assert; the four classes; the steal (§3, §5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-027 — one snapshot, zero changes | `SNAP_GAMEPLAY` only; nothing to change inside the bracket (§3) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-028/029 — the pools and the cap; the steal rule | 18 of 20; the pure `admit()`; the reserved slot outside the candidates (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-030 — the loop law | The arrival as a first start from the floor; no restart flag; the playhead assertion (§6, §10) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-031 — the import pins | The committed `.import` flags + the import audit; the Ogg/WAV decision (§10) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-032 — the budget | Disk/runtime/voices/tick, measured on the Pixel 6a; the provisional marker (§10, §14) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-033 — the duck schema, telemetry, allowlist, failure paths | The one-site rule; the 256-record ring; the two-port allowlist; the failsafe (§8, §9, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-035 — masking and headroom | One limiter; the beds ≥ 6 dB under the one-shots; the device measurement (§3) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-036 — the death duck, ratified | −6 dB, 120/240 ms on the wall clock, the hold, both exits (§8) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-037 — the accessibility surface | The MONO stage + the three sliders' group map + the metadata port (§4, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-038 — the variation law | The deterministic seeded draw; no immediate repeat; zero drift on the eight signatures and the clash pair (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-039 — the bed-contrast bar | The sound-bible pass owns the realisation; the DEVICE fixture (AC-AUD-31) owns the bar (§10) |
| `design/gdd/dual-reality-state.md` | SYS-09 | TR-DR-004 / E1–E7 + G1–G7 | The six subscriptions; the arm, the bracket, the tear, the release, the resume (§2, §6, §7, §9) |
| `design/gdd/world-mutation-epochs.md` | SYS-10 | E3b `ambient_shift` + the abort + the latched resume | The order record; zero orders on the abort; the resume hash (§6, §12) |
| `design/gdd/juice-feedback.md` | SYS-29 | TR-JCE-027 + the `duck_request` schema | The ten edges → eleven voices; the three-field schema; one application site (§5, §8) |
| `design/gdd/seam-borders.md` | SYS-11 | AR-SMB-01..04 | Zero audio publications; the bed continues; no duck; M4's chime is not the seam's (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | `restore_complete` before `load_complete`; the restored epoch | O-AUD-1: the payload rides SYS-05's `load_complete`; the bounded fallback (§12) |
| `docs/architecture/adr-0001-input-architecture.md` | ADR-0001 | §3 freeze; §5 tick boundary | The bracket's window; the wall clock every envelope runs on (§6, §8, §9) |

**Counts consumed, not re-derived:** 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs
(22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; the gate manifest 26 smoke · 4 device ·
2 MVP-lock · 0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role
rows · 29 audio assets · 2 contract-revision requests (CR-AUD-01, CR-AUD-02). This
ADR adds **no** TR, **no** formula and **no** AC.

## Related

- **GDD**: `design/gdd/audio-core.md` — the laws, F-AUD-01…07, the seven
  V-invariants, the 32 ACs, the closed edge list, the failure paths.
- **Review log**: `design/gdd/reviews/sys04-audio-core-review-log.md` — the
  authoring gate trail.
- **ADR-0001**: `docs/architecture/adr-0001-input-architecture.md` — §3 (the
  freeze), §5 (the tick boundary), and the probe-register pattern this ADR's §14
  follows.
- **ADR-0002**: `docs/architecture/adr-0002-save-serialization.md` — the
  `restore_complete` contract the load seam consumes (§12).
- **Upstream contracts**: `design/gdd/dual-reality-state.md`,
  `design/gdd/world-mutation-epochs.md`, `design/gdd/juice-feedback.md`,
  `design/gdd/seam-borders.md`.
- **Registry**: `audio_bus_contract`, `ambient_bed_contract`, `audio_edge_list`,
  `duck_request_contract` (all `status: active`).
