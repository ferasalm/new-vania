# ADR-0003: Audio Core — Bus Graph, Voice Pool, and the Flip's Sound Mechanism

## Status

**Proposed** — drafted 2026-11-15 by the ADR-DRAFT lane (support). **Acceptance
awaits the technical-director's TD-ADR verdict**: the `/architecture-review` gate
returned `CONCERNS` with **zero blockers** and all ten recommendations were applied
and confirmed (the gate trail is `docs/architecture/adr-draft-review-log.md` §5),
but an advisory architecture-review verdict does not replace the TD-ADR gate, and
`Status: Accepted` would let story-readiness start stories against this decision
early. The acceptance text is prepared and recorded in the log; the status flips to
`Accepted` on the TD's verdict. The engine-probe register in §14 is an
**implementation gate**, not an ADR-status gate. Carried obligations (not status
gates): O-AUD-1, CR-AUD-03, CR-AUD-04, **OQ-AUD-9**. If a later architecture review
finds a contradiction with a newer Accepted ADR, this ADR reverts to `Proposed`
and is superseded explicitly.

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
poisoned-sentinel run possible at all — plus the **import ladder** that answers a
failed loop-seam probe per asset class, moves the mono fold with the score, and
**never ships a failing seam** (§10).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (pinned; GDScript) |
| **Domain** | Audio (+ Core, for the tick/thread boundary) |
| **Knowledge Risk** | **MEDIUM** — the audio API is stable across 4.4–4.7 per the repo's snapshot ("No major breaking changes to the audio API in 4.4–4.6"), but two *mechanisms* this ADR needs are undocumented or unverified: the stereo→mono collapse and the Ogg loop seam. Both are probe-gated (§14) |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/audio.md`; `breaking-changes.md` (4.7 `AudioStreamPlayer.area_mask` default; 4.7 `AudioEffectSpectrumAnalyzer.tap_back_pos` removed); `deprecated-apis.md`; `docs/framework/technical-preferences.md` |
| **Post-Cutoff APIs Used** | `AudioServer.set_bus_volume_db` / `get_bus_index` / `set_bus_mute` (**documented in `modules/audio.md`**); `AudioServer.set_bus_effect` + the effect slot model **[unverified for 4.7.2's limiter class name: `AudioEffectLimiter` vs `AudioEffectHardLimiter`]**; `AudioStreamPlayer.play(from_position)` **[unverified parameter name]**; `AudioStreamOggVorbis.loop` / `loop_offset` **[unverified for gapless behaviour]**; `AudioStreamWAV.loop_mode` / `loop_begin` / `loop_end`; `AudioEffectCapture` (the loop-seam probe); `AudioStreamPlayer.area_mask` default `0` (4.7 — irrelevant here: no `Area` audio overrides in the audio graph, and none may be added) |
| **Verification Required** | The 8-item register in §14, each with a Method and an Owner. **7 are `PROBE-PENDING`** and block their named gate (item 2 blocks **every looped file's** import); **1 is `DOCUMENTED`** by the repo's snapshot. On the TD-ADR verdict this ADR becomes **Accepted as architecture**; the register is the implementation gate, and no story may consume a `PROBE-PENDING` item as settled fact. |

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
| **Blocks** | The first SYS-04 implementation story; **every looped file's** import (register item 2: 3 beds + the score pair); AC-AUD-20/21/31's device runs |
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
              └───┬───────────┬────────────┬───────────┬───────────┬─────────┬──────┘
                  │ ClockPort │ BusPort    │ PlayerPort│ Telemetry │ MetaPort│ SeedPort
                  ▼           ▼            ▼           ▼           ▼         ▼
              physics_tick  AudioServer  18 players   ring   {event_id,tick}  adapter (boot)
```

**The seam is one-way.** The adapter subscribes to the **five publishers** (SYS-09,
SYS-29, SYS-10, SYS-02, SYS-05) and forwards stamped edge events; the core returns
**commands** (start voice N with stream S at gain G, set bus volume V, emit record
R); the adapter executes them. Nothing in the core calls `AudioServer`,
`AudioStreamPlayer`, `Time`, `SceneTree`, `RenderingServer`, or reads
`truth_epoch` — that is V-AUD-04, and it is enforceable by grep because the core
holds ports instead of singletons.

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
- **The repo's own audio reference shows the forbidden pattern.** `modules/audio.md`'s
  "Playing Audio" example fades with `create_tween().tween_property(music_player,
  "volume_db", …)` — linear in **dB**, on `_process`. It is the exact shape R2
  forbids; an implementer who copies the reference will fail AC-AUD-02. The
  reference is a quick-reference, not this project's law: §6 is.

### 4 · The MONO stage

`MONO` (default off, `MONO_DEFAULT`) must collapse every bus to mono (TR-AUD-037,
AC-AUD-22). Four of the five buses are **already mono by import** (§G.6: beds
mono, one-shots mono); the score is the only stereo asset. So MONO's whole job is
the score, and the GDD names the difficulty honestly: "*a stereo→mono sum on
Master (no documented built-in)*".

**Decision.** `MonoStage` is a **stream strategy on the Music voice** — *not* a bus
effect — and the MVP implementation is a **second encode of the score**, not an
engine sum:

```gdscript
## The MONO strategy. The ONLY thing that differs between implementations is how the
## Music voice's stereo image is collapsed. The upgrade path (a native Master effect)
## replaces this object; no call site changes.
class_name MonoStage extends RefCounted
## @param player  the Music voice's AudioStreamPlayer
## @param at      the tick the toggle was requested
## @return        the tick the swap actually lands (see the deferral rule)
func apply(player: AudioStreamPlayer, at: int) -> int
func restore(player: AudioStreamPlayer, at: int) -> int
```

- The score ships as `MUS_HOUSE_LOOP` (stereo, the only stereo asset) **and** its
  mono fold `MUS_HOUSE_LOOP_MONO`. The fold is a **30th file** (see the contract
  note below) with its own §G.6 import row: Ogg Vorbis q0.6–0.7 **by default** (the
  score's fallback row if probe 2 takes it — §10), **mono**,
  44.1 kHz, loop on, +~0.55 MB. Disk: 3.7 → ~4.25 MB against the 10 MB bar.
  **The fold's format always follows the score's** (§10): if probe 2 sends the
  score to WAV, the fold goes with it, because an Ogg fold beside a WAV score would
  keep the rejected loop playable — and the MONO toggle is the one path that plays
  it.
- **The swap preserves the playhead** (`play(from_position)`) and is preceded by a
  **2-tick per-voice gain ramp** (1 tick down to the swap floor, the swap, 1 tick
  back up — 33 ms total), so the stream change cannot click. The ramp is a
  per-voice gain motion, the same mechanism the bed recede uses — **never a
  `duck_request`** (V-AUD-01's one-duck audit would fail, and a settings toggle is
  not a mix beat).
- **The deferral rule.** If the toggle is requested **inside [E1, E7]** — or if its
  2-tick ramp or the swap itself would land inside the window (a toggle one tick
  before E1) — **the whole sequence** defers to the first `IDLE` tick after the
  window: the pause screen is reachable during the bracket (AC-AUD-29 #12), and a
  2-tick gain ramp there would be a second audible motion inside the stillness
  bracket. The toggle's *setting* is recorded immediately; only the *ramp and swap*
  wait.
- **The fold's loudness is matched to the stereo encode** (a pipeline RMS/LUFS
  assert), so the toggle reads as a stereo collapse, not a volume step.
- **The pipeline rule**: no stereo asset may ship without a fold (or the native
  `MonoStage` upgrade). A second stereo asset at VS would otherwise silently break
  "collapses every bus".
- **The fold's missing-asset path** is §G.8's: `AUD_ASSET_MISSING {asset_id:
  "MUS_HOUSE_LOOP_MONO", tick}`, the toggle stays off, the stereo stream continues,
  and the record is rate-limited to one per asset per run. The audio never fails a
  toggle into silence.
- **Nothing else changes**: the four mono buses are unaffected, no bus gain moves,
  no snapshot changes.

**Contract note (CR-AUD-03, carried).** The GDD's counts line records **29 audio
files** and its §G.6 table has one stereo Score row, while AC-AUD-32's `[LINT]`
asserts "every asset … match §G.6". Shipping a 30th file therefore **requires** a
one-line contract revision: the counts line 29 → 30, the §G.6 Score row gaining the
mono-encode row, and AC-AUD-32's scope naming it — **plus, because the same AC is
the import audit, the fallback rows §10 defines** (the beds' and the score pair's
stereo + mono rows; a WAV score pair matches no
§G.6 row). **This ADR files CR-AUD-03 rather
than reinterpreting a frozen count**, and carries it as an obligation — the ADR's
*decision* (the `MonoStage` interface + the fold) is sound either way; only the
count and the audit's scope need the user's nod. If CR-AUD-03 is declined, the
fallback is the native summing effect behind the same interface (Alternative 6),
which restores 29 files at the cost of a GDExtension build — and **that fallback
requires its own ADR**, because the one-effect law (§3, restated as the operative
prohibition in §10) admits no production effect other than the limiter without
one. The fallback is therefore not a silent alternative: it is a second decision.

**Why not an engine sum.** A summing `AudioEffect` would need a GDExtension build
(a native toolchain and export-binary verification the MVP pipeline does not
have), and the GDD itself records that no documented built-in exists. A
double-encode is GDScript-only, deterministic, and testable — and it reduces the
GDD's second probe from "does a stereo→mono sum exist?" (an engine question) to
"does the swap click?" (a two-tick ramp question, answerable in one fixture,
register item 3).

**The upgrade path.** If the sound-bible pass finds the fold audible at the
toggle (a stereo image collapsing abruptly), the fix is a native summing effect
behind the same `MonoStage` interface. The interface is the decision; the
implementation is swappable.

### 5 · The voice pool and the steal rule

**Eighteen preallocated `AudioStreamPlayer` nodes at boot**, each with
`max_polyphony = 1`: 13 on SFX (12 pool + **1 reserved flip slot**), 4 on
Ambience, 1 on Music, 0 on UI. `allocated = 12 + 4 + 1 + 1 + 0 = 18` of a 20 hard
cap (2 slack) — the arithmetic reproduces from the knobs (F-AUD-05, AC-AUD-11).

**A voice may hold more than one slot.** Four voices declare `Max conc. = 2`
(`EV_DAMAGE_TICK`, `EV_DEFLECT`, `EV_JUMP2_TICK`, `EV_DEFEAT_TICK` — §E.2), and
`max_polyphony = 1` per player means a second concurrent instance of one of those
voices takes **a second slot from the same pool**, not a second voice on one
player. The mapping is explicit and auditable:

- each slot carries `voice_id`; the pool's candidate array is **per slot**, so a
  conc-2 voice can occupy two slots and each is individually stealable;
- a conc-2 voice is **capped at its declared 2** by the core (a third concurrent
  request for the same voice drops);
- the voice's retrigger floor (1/2/3/21/30 ticks, §E.2) is evaluated **per voice**,
  before slot admission — so the floor, not the pool, is what prevents a flurry
  from consuming the whole bus;
- the theoretical 15-voice instant worst case still exceeds the 12-slot SFX pool,
  which is exactly why the steal rule exists (§G.3).

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
- **The draw is seeded and injected.** `VariationRng` takes the run's **seed** from
  a declared `SeedPort` at arm time: one 32-bit value per run, drawn **once by the
  adapter at boot** (never per draw, never from wall time). The adapter holds it for
  the session; the core sees only the value. A fixture supplies a fixed seed, so the
  draw sequence is reproducible (AC-AUD-30's 40 draws); a fresh session gets a fresh
  seed, so the sequence is not memorisable across sessions. **The draw** reads
  neither a clock nor a global RNG — the injected seed is its only entropy; the
  core's `ClockPort` remains the envelopes' tick source (§6, §8). The seed is
  **never persisted**: SYS-03's schema is closed (TR-SAV-004) and a seed key would be
  `REFUSE_UNKNOWN_KEY`; determinism is a fixture property, not a save property.
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
  **floor hold becomes zero — never negative** (`floor_hold = [recede_end,
  release_boundary)` is empty when `recede_end ≥ release_boundary`), and the arrival
  still waits for the boundary.
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
- **A missing bus** drops the request with one `AUD_DUCK_BUS_MISSING` record —
  **never a silent Master duck**.
- **The third exit is SYS-15's, and it is authored** — the audio GDD's §K.3 still
  lists SYS-15 as "Not Started", but `design/gdd/cache-stations-death.md` carries
  **TR-CSD-015 / AC-CSD-15**: the duck releases on the reconstruct exit, the revive
  exit, **and the quit exit**. The `UNTIL_OFFLINE_EXIT` value already covers the
  third exit, so **the schema is unchanged** and the audio core simply subscribes
  to the release. The tree-exit backstop remains for a lost edge: a missing release
  costs one telemetry record, never a permanently ducked score. (Stale-row note
  routed to the sync lane; no frozen text edited here.)
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

| Asset class | Format | Channels | Rate | Loop | Engine side | Fallback row — **only** if probe 2 fails |
|---|---|---|---|---|---|---|
| Beds | Ogg Vorbis q0.5–0.6 | mono | 44.1 kHz | on, seamless | `AudioStreamOggVorbis.loop = true`; the loop seam is **probe item 2** | `AudioStreamWAV` 16-bit PCM, mono, 44.1 kHz, `loop_mode = LOOP_FORWARD` + sample-exact `loop_begin`/`loop_end` (register item 8) |
| Score (stereo) | Ogg Vorbis q0.6–0.7 | stereo | 44.1 kHz | on, seamless | as above; **CR-AUD-03** adds the row below | `AudioStreamWAV` 16-bit PCM, **stereo**, 44.1 kHz, `LOOP_FORWARD` + sample-exact bounds |
| Score (mono fold) | Ogg Vorbis q0.6–0.7 | **mono** | 44.1 kHz | on, seamless | `MUS_HOUSE_LOOP_MONO` (§4); the same loop pin; a **30th file**, pending CR-AUD-03 | `AudioStreamWAV` 16-bit PCM, mono, 44.1 kHz, `LOOP_FORWARD` — **always the same format as the score row: the pair moves together** |
| One-shots | WAV 16-bit PCM | mono | 44.1 kHz | off | trimmed, −3 dBFS peak, no silence padding; no loop flags | — (already WAV; probe 2 does not apply) |

- **The import flags are committed** (`*.ogg.import` / `*.wav.import`) and an
  **import audit** reads every `.import` and asserts the table (AC-AUD-32, LINT).
  A re-import that flips a channel count is a CI failure, not a mix surprise.
  **The audit's rule for the fallback is defined here** — this ADR owns the
  import-pipeline decision, and the GDD's §G.6 table is frozen and is **not**
  edited. An asset passes when its `.import` matches **either §G.6's row or the
  fallback row of its own class**; the fallback row changes exactly two things — the
  format and the loop mechanism — and keeps the channel count, the rate and the peak
  **identical** to §G.6's row, so the audit stays a LINT over a fixed two-row table
  and cannot be satisfied by an arbitrary WAV.

  **The fallback row is conditional on CR-AUD-03, exactly as the fold is.**
  AC-AUD-32's THEN clause is "match §G.6", and a WAV fallback matches no §G.6 row,
  so until the AC's scope names the fallback rows this rule is the ADR's *decision*
  and not yet the *audit's* law. This ADR does not reinterpret a frozen AC — §4's
  contract note states the method once: file the CR, never read the text.
  **CR-AUD-03's scope is therefore widened to carry both**: the mono-fold row **and**
  the three fallback rows (beds; the score pair's stereo + mono), with AC-AUD-32's
  THEN clause reading
  "match §G.6's row or, where the import manifest declares `fallback_probe2`, that
  class's fallback row". Until it lands the audit runs §G.6 literally — which is a
  passing state, because no asset sits on a fallback row until probe 2 fails and the
  rung is chosen. (The rider is recorded in the review log; nothing here edits the
  GDD.)

  **The declaration lives in a project-owned manifest, not in `.import`.** A
  `.import` file's `[params]` block is regenerated by the importer on every
  reimport, so a custom key there is not durable — and the same paragraph above
  relies on `.import` being toolchain-owned. `fallback_probe2` is therefore declared
  per asset in **`assets/audio/import-pins.yaml`**, a committed file this ADR's
  pipeline owns and the LINT reads beside the `.import` flags. The legality test is
  then two-sided and durable: the manifest declares the asset on a fallback row
  **and** the gate evidence names probe 2 as failed for its class. A stray WAV
  matches neither.
- **Probe 1 — the limiter class** (register item 1): which of
  `AudioEffectHardLimiter` / `AudioEffectLimiter` 4.7.2 exposes, and its
  gain-reduction readback for AC-AUD-20's ≤ 3 dB high-water.
- **Probe 2 — the Ogg loop seam** (register item 2): **run in a dev-only probe
  scene on a dedicated probe bus layout** — the probe's `AudioEffectCapture` is
  *not* part of the production graph, and §3's one-effect law applies to the
  shipping layout only (the exemption is named here so the probe cannot be read as
  a second production effect). Method: record ten loop iterations on the probe
  bus, **plus at least 50 ms beyond the tenth seam** — the window *after* a seam
  needs its own samples, and a capture that ends exactly at the tenth seam cannot
  supply them; **pass** = the seam test below passes at all ten loop points; **fail**
  = it fails at any of them.

  **The seam test is boundary-local, because a click is a discontinuity, not a
  transient.** A threshold taken from the asset's loudest interior peak cannot
  distinguish the two: a bed with an 0.8 interior transient would license a 0.5 jump
  at an otherwise quiet loop point — an audible click that the probe would pass.
  The test is therefore a predicate, **`seam_pass()`**, evaluated per loop point, per
  asset **and per channel**, with **two local conditions** measured on the seam's own
  neighbourhood (the last and first 50 ms of the loop, exactly 2,205 samples each at
  44.1 kHz). **Channels are tested independently**: a stereo capture is never summed
  or downmixed before the test, because opposite-sign discontinuities in the two
  channels cancel in a sum and a click would pass in both — an asset passes only when
  **every channel** satisfies all three conjuncts. **The conjuncts, per channel:**

  - **(a) the step bound** — `|x[0] − x[N−1]|` must not exceed the largest
    adjacent-sample delta **inside those two windows, excluding the seam pair
    itself** `(x[N−1], x[0])`. Excluding it is what keeps the condition from being
    vacuous: including it would make (a) trivially `d ≤ d`. An authored transient is
    a *slope* — its energy is spread over many samples, so its adjacent deltas are
    small — while a loop discontinuity is a *single jump*, measured against a
    quantity it cannot hide behind.
  - **(b) the slope bound** — the **magnitude** of the second difference across
    **each seam-spanning triple** — `(x[N−2], x[N−1], x[0])` **and**
    `(x[N−1], x[0], x[1])` — must not exceed the largest **|second difference|**
    **inside the same windows, excluding both triples**. Magnitude, not sign, for
    the same reason (a) uses `|·|`: a downward kink is as audible as an upward one,
    and a signed comparison passes whichever direction the interior max does not
    happen to cover. And **both** triples, because a kink can sit on either side of
    the join: a silent last window and a first window that starts with a slope has a
    zero step and a zero left second difference, and a large right one.

  `SEAM_DELTA_MAX` remains the **scalar upper bound** and is the test's third,
  independent conjunct: the seam delta must also stay below **that channel's**
  loudest
  **interior** transient (the interior excluding both 50 ms windows). It is a real
  constraint, not a sanity check — (a) alone can license up to roughly twice the
  local peak — and it is never borrowed across asset classes: a score's bar-boundary
  transient and a bed's steady hum do not share a tolerance. It is **that channel's**
  loudest interior event (per channel, like the other two conjuncts), so a quiet
  channel is judged on its own material and not licensed by its loud sibling. A seam
  delta that exceeds the material's own loudest interior event is a click without
  further argument.

  All three conjuncts are post-processing on **one contiguous capture per looped
  file** — drained per frame from `AudioEffectCapture.get_buffer()` into the probe's
  own buffer, because the effect's ring buffer is ~0.1 s by default and cannot hold a
  loop. So the probe's cost does not change. **Contiguity, timeline and rate are
  preconditions** (register item 7):

  - **Contiguity** — no `get_buffer()` call may underrun, **requesting the frame
    count the elapsed mix time owes** (never `get_frames_available()`, which makes
    the check vacuous by construction and cannot see a ring-buffer *overflow* — the
    actual drop mode at ~0.1 s capacity). A dropped buffer at a seam would either
    fabricate a failure or measure the wrong sample pair, and a length tolerance
    cannot establish gap-freeness: the defect is exactly one buffer.
  - **Timeline — δ is measured, never assumed zero.** **Clear, then play:**
    `clear_buffer()` before `play()`, in that order, or δ can go negative. `play()`
    starts the stream at the next **mix callback**, while `clear_buffer()` clears the
    ring buffer wherever the main thread lands in that callback, so the capture index
    of the playback's first sample is `δ ∈ [0, one mix block)` — up to ~15 ms at the
    default output latency, i.e. 30 % of the 50 ms window. δ is **constant per run**
    (set once at the start), so it is measured **once per run** — a marker at the test
    loop's start, or cross-correlation against one decoded iteration — **asserted
    constant across the ten iterations**, and applied to the seam index:
    **`seam_index_k = k·loop_end + δ`** for iteration *k* (1…10). An unmeasured δ is a
    **probe failure**: a δ-shifted read lands mid-loop, where a continuous waveform
    passes the local test, so assuming δ = 0 would silently pass a seam nobody
    checked.
  - **Rate** — the project pins `audio/driver/mix_rate = 44100`, the rate §G.6 pins for
    every asset, and the probe **asserts** it recorded at 44.1 kHz, so
    `loop_end` needs no conversion and the 50 ms window is exactly 2,205 capture
    samples (`44,100 × 0.05`). A device-forced rate is a **probe failure** that
    requires both the conversion `capture_index = loop_end × mix_rate / asset_rate`
    (window scaled by the same factor) **and a re-run at that rate** — a formula
    substitution on a 44.1 kHz capture cannot speak for a build that resamples across
    the seam.

  **The pass condition is absolute.** An asset that fails `seam_pass()` **never
  ships on any rung of this ladder**. The measured **seam delta** recorded in the gate
  evidence
  is *evidence of a failure*, never a waiver: "the loop point is authored at a
  musical bar boundary" is the hypothesis the probe exists to test, not a substitute
  for testing it. (This replaces an earlier draft's "accepted for the score alone",
  which recorded the delta and shipped the loop anyway.)

  **The fallback is one ladder, and the fold always follows the score.** Probe 2
  fails per asset class, but the score's two encodings are one **pair**: a stereo
  WAV score beside an Ogg fold would leave `MUS_HOUSE_LOOP_MONO` playing exactly the
  loop the probe rejected — the one stream the MONO toggle exists to reveal — so
  the pair moves together, always, and its WAV cost is the **pair's** (stereo +
  mono), not the stereo file's alone. **A fold-only failure is therefore a pair
  failure** — the fold is captured as its own probe-2 target (register item 2), and
  a fold that fails while the stereo passes sends the **pair** down the rung, never
  a fold-only swap. The ladder's **first** rung is not a format
  change at all: **the authoring fix** — move the loop point to a sample-continuous
  position and re-encode at the same quality — because a format switch cannot repair
  an authoring seam (register item 8 applies the same `seam_pass()`, and a WAV loop is
  sample-exact but not seam-exact). Its last rung for any looped asset is
  sample-exact WAV, whose
  cost is linear in duration; every rung therefore has a **ceiling in seconds**, and
  the ceilings share the 10 MB bar.

  | Rung set | What ships | Fixed cost | Rate for the variable material | Ceiling |
  |---|---|---|---|---|
  | probe 2 passes | 3 beds + score + fold, all Ogg | 1.1 beds + 1.1 score + 0.55 fold + 1.5 one-shots ≈ **4.25 MB** | — | — |
  | beds fail only | beds WAV; score + fold Ogg | 1.1 + 0.55 + 1.5 = 3.15 MB | 88.2 kB/s (mono WAV) | **T_beds ≤ 77.7 s (~78 s combined)** |
  | score fails (fold follows) | score + fold WAV; beds Ogg | 1.1 + 1.5 = 2.6 MB | 176.4 + 88.2 = **264.6 kB/s** | **T_score ≤ 27.97 s (~28 s)** |
  | both fail | all WAV | 1.5 one-shots only → **8.5 MB shared** | 88.2·T_beds + 264.6·T_score | **88.2·T_beds + 264.6·T_score ≤ 8,500 kB** — the sound-bible pass splits the pool (96 s of bed WAV if the score takes none of it) |

  Two corrections to the earlier arithmetic, both of the same kind: the score's WAV
  ceiling was priced at 176.4 kB/s with the fold left on Ogg, and the shared pool
  released only the score's 1.1 MB. With the fold priced as part of the pair, the
  score's ceiling is **~28 s, not ~38 s**, and the shared pool is **8.5 MB, not
  7.95 MB**. The fallback also makes the beds **resident rather than streamed**: the
  beds-fail rung's runtime cost is **+6.85 MB** and the both-fail rung's is **+8.5 MB**
  (~10 MB with the one-shots) — no rung breaches the 16 MB bar, and the worst case is
  stated rather than the best. It changes no law; only the file format, the
  residency, and — for the score pair — the loop's maximum length.

  **Two conditionals the ceilings depend on.** The ceilings assume **CR-AUD-03
  lands**: the fold's 0.55 MB and its 88.2 kB/s are part of the pair's rate. If the
  mono fold is declined (the native `MonoStage` instead, 29 files), the score is the
  stereo file alone at 176.4 kB/s — and **~42 s is then a rung-specific figure, not
  an independent native ceiling**: it holds only while the beds stay Ogg (7.4 MB ÷
  176.4 kB/s). If the beds also fall back, the joint inequality becomes
  **88.2·T_beds + 176.4·T_score ≤ 8,500 kB** — so 70 s of beds plus a 42 s stereo
  score plus the one-shots would be ≈ 15.1 MB, over the **10 MB disk** bar by 5.1 MB
  (it is still under the 16 MB runtime bar, which is a different budget). A decline must
  therefore **narrow** the CR rather than drop it: the fallback rows keep their audit
  home, or a WAV score has none. And the
  joint inequality does not license short beds: the split must keep each bed at the
  length its room was authored for (three loops, the sound bible's), so the
  inequality bounds the *total*, not the *minimum*.

  **A loop longer than its rung's ceiling is not decided here.** The score's loop
  length belongs to the sound bible and is not yet authored (the palette is
  `PROV_AUD_*` placeholders; OQ-AUD-1), and the beds' `~1.1 MB` Ogg pin implies
  roughly 110–140 s of bed material — longer than the 78 s the beds-fail rung allows.
  So the gap is not the score's alone: **any looped asset whose authored duration
  exceeds its rung's ceiling** has no rung that satisfies both the seamless
  requirement and the 10 MB bar (Ogg cannot guarantee the seam once the probe fails;
  WAV cannot fit the duration). That case is filed as **OQ-AUD-9** — filed by this
  ADR, and the GDD's OQ table gains it at its next touch, exactly as CR-AUD-03/04 are
  filed rather than written into frozen text — for the **audio-director**, naming the
  beds' ~78 s combined and the score pair's ~28 s explicitly, with two branches:
  **(i)** re-author the material to the ceiling, a palette cost (the loops are
  authored at musical bar boundaries either way); or **(ii)** an **explicit, scoped
  revision** of the seamless-loop requirement for that asset alone — §G.6's `Loop`
  column, probe 2's scope, TR-AUD-030's "beds loop seamlessly" where the asset is a
  bed, and AC-AUD-32's row (which the asset still has to match) — with the measured
  delta as the revision's evidence.
  **The default until OQ-AUD-9 is answered is branch (i)**: a shorter seamless loop
  beats a longer clicking one, and branch (ii)'s failure mode is audible on every
  loop. Branch (ii) is honest about what it is: it ships a seam that **fails
  `seam_pass()` as it stands**, and it is legal only once the requirement itself is
  revised — it is not a waiver, and it is never taken by this ADR.
- **No `AudioEffect` other than the limiter** may be added to the **production**
  graph without a new ADR: the "one effect" property is what makes the mix
  auditable. (Probe scenes and the dev-only probe layout are exempt and never
  ship.)

### 11 · Epoch-blindness and the ports

The core consumes **five inbound signal sources, plus the clock and the variation
seed**, and publishes **none**:

| Inbound | Owner | Port | Missing → |
|---|---|---|---|
| E1 / E4 / E7 | SYS-09 | adapter signal | `AUD_MISSING_E1/_E7` (E4 has no obligation) |
| E2 / E5 / E6 | SYS-29 | adapter signal | `AUD_MISSING_E2/_E5/_E6` + the named behaviour (§G.8) |
| E3b `ambient_shift` | SYS-10 | adapter signal | `AUD_MISSING_E3B`; **the bed stays put; no self-shift** |
| Room activation | SYS-02 | adapter signal | **no record** — the only **edge** input whose absence has no distinct behaviour: the bed stays as it is and the next real room entry re-applies the room's bed. Named here as the one edge-input exception to R9, so "every missing input has a record" is not silently false |
| Load-complete (`restored_epoch`) | SYS-05 (§12, O-AUD-1) | adapter signal | `AUD_LOAD_MISSING`; the derived state stands |
| The tick | ADR-0001 | `ClockPort` | a boot-order defect; the dev assert |
| The variation seed | the adapter (boot) | `SeedPort` | a boot failure: no seed, no deterministic draw (§5) |

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
  `restored_epoch` on `load_complete`, and must assert it is present and
  non-default after a post-flip load. Recorded here and in the lane report.

**CR-AUD-04 (contract-revision request, carried).** TR-AUD-002's publisher map
says "*the load-complete is SYS-03's (its payload carries `restored_epoch` —
CR-AUD-02's request)*" — which SYS-03's landed contract contradicts: SYS-03
publishes `restore_complete` + `load_result`, and `load_complete` is SYS-05's.
An implementer reading TR-AUD-002 verbatim would subscribe the adapter to an event
that does not exist. **That is a one-clause correction to a frozen GDD, so it rides
the contract-revision route** (the `decisions.md` batch, alongside CR-AUD-01/02),
not a self-declared exemption: TR-AUD-002's publisher row becomes
"load-complete — SYS-05 (its payload carries `restored_epoch`)". O-AUD-1 is the
carrying obligation; **this ADR changes no decision either way**, and no frozen
text is edited here.

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
- **`SeedPort`** — the run's one 32-bit variation seed (§5); a fake returns a fixed
  seed so AC-AUD-30's 40-draw fixture is reproducible.
- **The static audits** (LINT) are greps over `src/audio/`: no truth symbols
  (V-AUD-04), exactly thirteen registered voices (V-AUD-02), exactly one duck
  application site (V-AUD-01), only the two allowlisted ports (AC-AUD-19).
- **The device fixtures** (AC-AUD-20/21/22/31) run on the Pixel 6a reference SKU;
  nothing pixel- or channel-accurate is asserted headless.

### 14 · The engine verification register

Every `PROBE-PENDING` row carries a **Method** (a runnable protocol with a
pass/fail) and an **Owner**, so a probe closes or fails rather than being narrated.
The `Blocks` column names **what the probe gates**, which is the probe itself plus
the AC it unblocks — not an AC that already tests something else.

| # | Item | Verdict | Method (pass = ) | Owner | Blocks |
|---|---|---|---|---|---|
| 1 | The Master limiter class in 4.7.2 (`AudioEffectHardLimiter` vs `AudioEffectLimiter`) and its gain-reduction readback | **PROBE-PENDING** | instantiate both candidates; the surviving class is instantiated on Master and its reduction is readable during AC-AUD-20's loudest fixture | godot-specialist | The first story; AC-AUD-20's ≤ 3 dB high-water |
| 2 | Ogg Vorbis loop seams are gapless on 4.7.2 (**every looped file**: 3 beds, the stereo score, the mono fold — each its own capture) | **PROBE-PENDING** | §10's ten-iteration capture in the dev-only probe scene, **once per looped file**, including a separate capture of `MUS_HOUSE_LOOP_MONO` (conditional on CR-AUD-03): **δ is measured and constant**, no `get_buffer()` call underruns, the recorded mix rate is the asserted **44.1 kHz**, and `seam_pass()` (§10) then holds at all ten loop points | sound-designer + godot-specialist | **The import of every looped file** (5 seams — 4 if CR-AUD-03 is declined); the fallback rows and their ceilings (§10); **OQ-AUD-9** if any looped file exceeds its rung's ceiling |
| 3 | `AudioStreamPlayer.play(from_position)` preserves the playhead across the MONO swap | **PROBE-PENDING** | the swap at tick T: the post-swap `playback_position` is within 1 tick of the pre-swap value, and the gain ramp's two ticks are exact; **and the swap is captured and passes a click test** — a **±10 ms** capture around T must show no step or slope discontinuity above the §10 `seam_pass()` bounds (the swap is a stream change, so the click test is the same predicate applied to a different seam), which playhead and ramp timing alone cannot establish. **All three conjuncts apply** to the swap capture (step, slope, and the scalar bound) — it is the same predicate, not a two-condition version of it. The window is **±10 ms around T** because the ramp's two *intended* gain writes sit one tick away on each side (down at T − 16.7 ms, the swap at T, up at T + 16.7 ms, §4's 33 ms total), so a half-width below 16.7 ms keeps both intended steps **outside** the capture; widening the window without moving those writes out would fail on the ramp rather than on a click | lead-programmer | The MONO stage; AC-AUD-22's collapse assertion becomes meaningful |
| 4 | Per-tick `set_bus_volume_db` at 60 tps is inside the core's tick bar and does not zipper | **PROBE-PENDING** | a 15-tick ramp at 240 ms: the core's tick stays within p99.9 ≤ 0.10 / max ≤ 0.30 ms **and** a capture of the ramp shows no step above `ZIPPER_DELTA_MAX`; a staircase reading fails the probe and moves the envelope to a per-tick interpolation inside one audio-thread callback | performance-analyst | AC-AUD-21 (the tick bar) — the probe gates the measurement; AC-AUD-02 is a GUT over the fake `BusPort` and cannot zipper, so it is **not** a gate here |
| 5 | Five buses + one Master effect is inside the mobile mix budget | **PROBE-PENDING** | measured as an **extra instrument** during AC-AUD-21's device run (mixer CPU share, no new AC); the bar is "the audio thread's share stays under 25% of the frame" | performance-analyst | The graph's viability on the reference SKU |
| 6 | `AudioServer.set_bus_volume_db` / `get_bus_index` / `set_bus_mute` exist and behave as used | **DOCUMENTED** (`modules/audio.md`'s "Audio Buses" block) | — | — | — |
| 7 | `AudioEffectCapture` can record a bus for the loop-seam probe | **PROBE-PENDING** | the probe scene captures **a known short test loop (≤ 10 s, so the capture crosses at least one seam)**, drained per frame; **no `get_buffer()` call underruns**, **δ is measured once and asserted constant across the ten iterations** (§10's timeline precondition), and the recorded **mix rate is the asserted 44.1 kHz** (a device-forced rate is a failure requiring the §10 conversion **and** a re-run) | godot-specialist | Probe 2's method; §10's contiguity + timeline + rate preconditions |
| 8 | `AudioStreamWAV.loop_mode` / `loop_begin` / `loop_end` give sample-exact loops (the fallback) | **PROBE-PENDING** | a WAV **looped file** (a bed, or the score pair on its fallback row) loops 100× and passes **the same boundary-local seam test probe 2 uses** (`seam_pass()`, §10) at every loop point — a continuous waveform's last and first samples legitimately differ, which is why the test is local rather than an absolute-zero rule; `loop_end − loop_begin` equals the authored sample count | sound-designer | The fallback's viability (only if probe 2 fails) |

`PROBE-PENDING` is an open verdict: items 1–5 and 7–8 block their named gates, and
item 2 blocks the import of **every looped asset — the beds, the stereo score and
the mono fold** (the fold is its own capture target, not implied by the stereo
pass). No story may consume one as settled
fact. **Only item 6 is documented by the repo's own snapshot** — a grep for
`AudioEffectCapture`, `loop_mode` or "audio thread" in
`docs/engine-reference/godot/` finds nothing, which is why the rest are probes.

### Architecture diagram — the flip's 34 ticks

```
tick  100        101        116      119              134
      │ E1       │ E2+E3b   │        │ E6 + E7        │ arrive_end
      │ arm      │ gate shut│ recede │ gate open      │ (the arrival's fade
      │ beds+    │ recede→  │ ends   │ arrival starts │  completes; E7 was
      │ tear     │ tear at  │        │ + gameplay     │  at 119)
      │ resident │ τ0       │        │   resumes      │
      │          └── floor hold ──────┘                │
      │  zero orders before τ0 · zero arena orders anywhere in [100,134]
      │  zero ducks · zero snapshot changes · zero loop restarts
      └── the score untouched, playing, at the same playhead
```

**E7 is at 119, not 134.** `flip_complete` fires with E6 at the release boundary and
the gameplay one-shots resume there; the arrival's fade *continues* to
`arrive_end` (134) as a voice envelope. 134 is a fade boundary, never a resume
boundary — an implementer who resumes at 134 is 15 ticks late and fails AC-AUD-06
and AC-AUD-02's schedule.

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
  duration to ~78 s (with the score and its fold on Ogg — the ladder in §10 prices
  every rung, including the all-WAV one).
- **Estimated Effort**: 1.0×.
- **Rejection Reason**: kept as the **pre-priced fallback** (register item 2) —
  chosen only if the Ogg seam fails the probe, and applied per asset class (§10).

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
- The format ladder is pre-priced, so probe 2 cannot become a schedule
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
| Ogg loop seams click on the beds or on the score pair | Medium | High | Probe 2's **absolute, boundary-local** `seam_pass()` (step + slope + the scalar bound, per asset and per channel; every looped file captured, the fold as its own target); the priced ladder (§10: 78 s beds / 28 s score pair / 8.5 MB joint); OQ-AUD-9 if any looped file exceeds its rung's ceiling |
| The MONO swap clicks | Medium | Medium | The 2-tick per-voice ramp; AC-AUD-22; probe 3 |
| A per-tick bus write zippers or costs too much | Low | High | Probe 4; the core's tick bar (p0.10/max 0.30 ms) |
| An `Area` bus override is added later | Low | High | R1 + the boot assert on the five buses; the 4.7 `area_mask` note |
| The E6-lost failsafe never fires (wrong `GATE_FAILSAFE_MS`) | Low | High | AC-AUD-13's injection; the knob's range [600, 1200] |
| The duck's release edge is lost | Medium | Medium | The offline screen's tree-exit backstop + `AUD_DUCK_RELEASE_BACKSTOP` |
| Epoch-blindness erodes (a convenience read) | Medium | High | V-AUD-04's grep + the poisoned-sentinel run; `MVP_FLIP_TO_EPOCH` is a constant |
| `restored_epoch` never lands on SYS-05 | Medium | Medium | O-AUD-1 carried to SYS-05's authoring; the bounded fallback is playable |
| CR-AUD-03 (the mono fold's count/audit row) is declined | Medium | Low | The decision stands; the fallback is the native summing effect behind the same `MonoStage` (29 files, a GDExtension build) — **and the CR must still be narrowed to the fallback rows**, or a WAV score has no audit home (§10) |
| CR-AUD-04 (TR-AUD-002's publisher row) is declined | Low | Medium | The adapter still subscribes to SYS-05's `load_complete` (the only event that exists); the frozen text stays wrong and a reader can be misled — the ADR's §12 note is the mitigation until the correction lands |

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
   the §G.1 volumes), the limiter factory, and the boot assert. **Pin
   `audio/driver/mix_rate = 44100` in `project.godot`** — the seam probe asserts it
   (§10), and an unpinned rate is a probe failure that needs the conversion and a
   re-run.
2. **The core.** Add `src/audio/core/` (`AudioCore`, `FlipStateMachine`,
   `BedDirector`, `VoicePool`, `DuckStage`, `Gate`, `VariationRng`, `OrderTrace`,
   `TelemetryRing`, `Tuning`) and the GUT suite under `tests/unit/audio/` with the
   four port fakes. No `AudioServer`, no node.
3. **The adapter + the players.** Add `AudioAdapter` and the eighteen players; wire
   the five subscriptions; wire `ClockPort` to ADR-0001's `physics_tick`.
4. **The assets' import.** Commit the `.import` flags; run the import audit; close
   probe 2 (the loop seam) before the beds are accepted.
5. **The MONO stage.** Produce the score's mono fold; wire `MonoStage`; close
   probe 3.
6. **The device gate.** AC-AUD-20/21/22/31 on the Pixel 6a; ratify OQ-AUD-6.

**Rollback plan.** Delete `src/audio/` and the bus layout; no save data, no schema
and no cross-system contract is touched. The GDD and this ADR remain; a
superseding ADR would replace the graph, not the laws.

## Validation Criteria

**Two gates, two lists.** The **decision-conformance** list (17 criteria) states
what this decision must be able to prove. Several are verified by fixtures and
device runs that land with the implementation (`src/audio/` and the assets do not
exist yet), so they are the criteria the *decision* fixes — not checks runnable at
sign-off. The **story gate** (3 criteria) closes at the first implementation story.

**Decision conformance (what the decision must be able to prove).**

- [ ] The bus table matches §G.1 exactly; the SFX pool is 12 + 1 reserved; a duck
      naming a non-Music bus is rejected with a record (AC-AUD-26).
- [ ] `allocated` = 18 of 20 reproduces from the knobs; `VOICE_CAP < allocated` is
      a boot failure; a full SFX pool never starves the tear (AC-AUD-07/11).
- [ ] The steal order is P3 → P2 → drop; P0 and every signature survive their
      floods (AC-AUD-11); a conc-2 voice occupies at most two slots (§5).
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
- [ ] Exactly one duck request per death, attack 8 / release 15 ticks, released on
      the two exits the GDD names **and on the quit exit** (TR-CSD-015; the schema
      is unchanged); one application site in `src/audio/` (AC-AUD-10/17).
- [ ] MONO collapses every bus; the Ambience and UI buses follow the SFX slider;
      every slider's range is honoured (AC-AUD-22) — **plus** the swap's own
      fixture, which AC-AUD-22 does not cover: the ramp's two ticks are exact, the
      playhead is preserved, **the captured swap passes the click test** (no step or
      slope discontinuity above §10's `seam_pass()` bounds — playhead and ramp timing
      alone cannot establish that the swap is inaudible), and a toggle requested
      inside [E1, E7] **or one whose
      ramp or swap would land inside it** defers the whole sequence to the first
      `IDLE` tick (§4's deferral rule).
- [ ] The fold's missing-asset path emits `AUD_ASSET_MISSING` and leaves the toggle
      off with the stereo stream playing (§4, §G.8's class).
- [ ] Exactly thirteen registered one-shot IDs; a 10,000-tick soak emits zero
      ambience one-shots (AC-AUD-15).
- [ ] Zero truth-state symbols in the core; the adapter's subscriptions equal the
      publisher map; the allowlist grep matches only two ports (AC-AUD-19).
- [ ] The snapshot hash is unchanged and the score untouched across [E1, E7]
      (AC-AUD-16).
- [ ] The import audit matches §G.6 on every asset, including the mono fold's own
      row (AC-AUD-32, scoped by CR-AUD-03) — **and**, once CR-AUD-03's widened scope
      lands, an asset declared on a fallback row in `assets/audio/import-pins.yaml`
      matches that class's fallback row instead, with the channel count, rate and
      peak unchanged from §G.6 and the gate evidence naming probe 2 as failed (§10).
      An asset may never match *neither* row; until the CR lands the audit is §G.6
      literal and no asset may sit on a fallback row.
- [ ] Probe 2's verdict is applied **per looped asset** — beds, stereo score and mono
      fold each captured, the fold as its own target — **and to the score pair as one
      unit**: a fold-only failure sends the pair down the rung, a failed score never
      ships beside an Ogg fold, and no rung ships an asset that fails the
      **boundary-local seam test** (`seam_pass()`: step + slope + the scalar bound,
      per asset and per channel; §10).

**Story gate (the first SYS-04 implementation story).**

- [ ] **The asset count is settled before any audio asset ships**: either
      **CR-AUD-03 has landed** (the counts line 29→30, the §G.6 mono-encode row,
      AC-AUD-32's scope) **or** the story ships the native `MonoStage` fallback
      (29 files, and its own ADR). A story may not ship the fold against an
      unchanged 29-file count.
- [ ] Disk ≤ 10 MB, runtime ≤ 16 MB, voices ≤ 20, the core's tick within its
      (provisional) bar, and the mixer's share within item 5's bar on the Pixel 6a
      (AC-AUD-21 + register item 5's extra instrument).
- [ ] Every `PROBE-PENDING` item in §14 has a verdict; zero remain open.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|---|---|---|---|
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-001/002 — consume E1–E7 verbatim; the publisher map; publishes nothing | The adapter's five subscriptions equal the publisher map; the core returns commands, never events (§2, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-003 — epoch-blindness | Ports instead of singletons; `MVP_FLIP_TO_EPOCH` as a boot-validated constant; the poisoned-sentinel run (§2, §11, §13) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-004 — the closed list is closed | Thirteen voices over eighteen preallocated slots; the registration scan (AC-AUD-15/18) (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-005 — the death duck is consumed, not designed | `DuckStage` + one `apply_duck` site; three fields; `UNTIL_OFFLINE_EXIT` (§8) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-006 — the missing-input failure paths | The six-row inbound table with named records and no synthesized substitute (§11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-007 — the arm is silent (E1) | The arm validates and makes resident; no player starts; no order before τ0 (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-008 — the receding-first law | The wall-clock schedule, the target set in the order record, the arena exclusion (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-009 — the stillness bracket | `gate_open = false`; drop-never-queue; no loop restart; zero snapshot changes; ring-out (§5, §9) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-010 — the tear | The reserved P0 slot outside the steal table; 24 ticks in a 26-tick window; the silent-asset path (§7) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-011 — the abort path | Zero orders; the force-release-derived `freeze_close` as an event; `DEGRADED` precedence; no `RELEASED` (§6, §9) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-012 — the resume re-run | The order trace encodes **relative to the raise tick** (F-AUD-06: `tick` and `arrive_not_before_tick` hashed as `value − raise_tick`), so the post-resume span hashes identically to the fresh flip's; the compared span starts at R′ (F-AUD-06's rule, AC-AUD-05's fixture) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-013/014 — the arena hum; the wing's no-op | RM-06 excluded by the order record; no separate wing bed; the room-entry path only at real entries (§6) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-015…021 — **the eleven** one-shot voices of the SYS-29 list (015 damage; 016 clash contact + midpoint; 017 deflect; 018 heal + death; 019 revive + level-up; 020 memory; 021 jump-2 + defeat) | The voice table's slots, classes, retrigger floors and signatures; the conc-2 slot mapping (§5); the variation law's deterministic draw (§7) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-022/024/025 — the bed table; the seam's exemption; the transition law | The derived bed map + `restored_epoch`; the room-entry crossfade only at a real entry; no restart, no duck (§6, §12) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-023 — beds only, no stochastic detail | Zero ambience one-shot registrations; the 10,000-tick soak (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-026/034 — the bus layout; the nominal mix | The committed bus layout + the boot assert; the four classes; the steal (§3, §5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-027 — one snapshot, zero changes | `SNAP_GAMEPLAY` only; nothing to change inside the bracket (§3) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-028/029 — the pools and the cap; the steal rule | 18 of 20; the pure `admit()`; the reserved slot outside the candidates (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-030 — the loop law | The arrival as a first start from the floor; no restart flag; the playhead assertion (§6, §10) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-031 — the import pins | The committed `.import` flags + the import audit; the Ogg/WAV ladder and its audit rule (§10) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-032 — the budget | Disk/runtime/voices/tick, measured on the Pixel 6a; the provisional marker (§10, §14) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-033 — the duck schema, telemetry, allowlist, failure paths | The one-site rule; the 256-record ring; the two-port allowlist; the failsafe (§8, §9, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-035 — masking and headroom | One limiter; the beds ≥ 6 dB under the one-shots; the device measurement (§3) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-036 — the death duck, ratified | −6 dB, 120/240 ms on the wall clock, the hold, both named exits (+ the quit exit, TR-CSD-015 — the GDD's TR-AUD-036 predates it and the `UNTIL_OFFLINE_EXIT` value already covers it) (§8) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-037 — the accessibility surface | The MONO stage + the three sliders' group map + the metadata port (§4, §11) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-038 — the variation law | The deterministic seeded draw: the **seed is injected** (`VariationRng` takes one 32-bit value per run from `SeedPort`, held by the adapter for the session and **never persisted**; a fixture supplies a fixed seed), no immediate repeat, ±1 st within a band, zero drift on the **six signatures** and the clash pair (§5) |
| `design/gdd/audio-core.md` | SYS-04 | TR-AUD-039 — the bed-contrast bar | **Partial by design**: the bar (≥4/5 nameability, audible on the Pixel 6a speaker, the arena distinct) is AC-AUD-31's; the *realisation* is the sound-bible pass's, and no engine mechanism decides it. The ADR's part is the import pins that make the comparison fair (§10) |
| `design/gdd/dual-reality-state.md` | SYS-09 | TR-DR-004 / E1–E7 + G1–G7 | The five subscriptions; the arm, the bracket, the tear, the release, the resume (§2, §6, §7, §9) |
| `design/gdd/world-mutation-epochs.md` | SYS-10 | E3b `ambient_shift` + the abort + the latched resume | The order record; zero orders on the abort; the resume hash (§6, §12) |
| `design/gdd/juice-feedback.md` | SYS-29 | TR-JCE-027 + the `duck_request` schema | The ten edges → eleven voices; the three-field schema; one application site (§5, §8) |
| `design/gdd/seam-borders.md` | SYS-11 | AR-SMB-01..04 | Zero audio publications; the bed continues; no duck; M4's chime is not the seam's (§6) |
| `design/gdd/save-serialization.md` | SYS-03 | `restore_complete` before `load_complete`; the restored epoch | O-AUD-1: the payload rides SYS-05's `load_complete`; the bounded fallback (§12) |
| `docs/architecture/adr-0001-input-architecture.md` | ADR-0001 | §3 freeze; §5 tick boundary | The bracket's window; the wall clock every envelope runs on (§6, §8, §9) |

**Counts consumed, not re-derived:** 39 TR-AUD · 7 F-AUD · 7 V-AUD · 32 ACs
(22 GUT · 4 LINT · 4 DEVICE · 2 PLAYTEST; the gate manifest 26 smoke · 4 device ·
2 MVP-lock · 0 VS) · 14 knobs · 8 OQs (5 resolved, 3 open) · 13 voices · 17 role
rows · **29 audio assets (30 files with the mono fold — CR-AUD-03)** · 2
contract-revision requests inherited from the GDD (CR-AUD-01, CR-AUD-02) + **2
filed here** (CR-AUD-03 the mono fold's count/audit row; CR-AUD-04 TR-AUD-002's
load-complete publisher) + **1 open question filed here** (OQ-AUD-9, any looped
asset's duration against its rung's ceiling). This ADR adds **no** TR, **no**
formula and **no** AC.

**V-invariant coverage** (all seven carried): V-AUD-01 by AC-AUD-10/17 (the one
application site); V-AUD-02 by AC-AUD-15/18 (the registration scan); V-AUD-03 by
AC-AUD-03 and the order record's target/excluded sets (§6); V-AUD-04 by AC-AUD-19
and the poisoned-sentinel run (§11); V-AUD-05 by AC-AUD-16 and §3's one snapshot;
V-AUD-06 by AC-AUD-02's schedule fixture (§6); V-AUD-07 by AC-AUD-06/07 (the gate
and the reserved slot) (§5, §9).

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
- **Carried**: O-AUD-1 (`restored_epoch` on SYS-05's `load_complete`); CR-AUD-03
  (the mono fold's counts/§G.6/AC-AUD-32 row **+ the fallback rows**); CR-AUD-04
  (TR-AUD-002's load-complete publisher); OQ-AUD-9 (any looped asset's authored
  duration against its rung's ceiling — the beds' ~78 s and the score pair's ~28 s —
  the audio-director's). None changes a decision in this ADR: OQ-AUD-9 is a *content*
  bound the ladder already prices, with a stated fail-safe default.
