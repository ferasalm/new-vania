# Audio Core

> **Status**: Draft — skeleton (sections A–B drafted; sections C–K pending user approval)
> **Author**: sound-designer (lane SYS-04; audio-director countersign pending)
> **Last Updated**: 2026-11-14
> **Last Verified**: 2026-11-14 (contracts read at `origin/Main` `e8b194d`)
> **Implements Pillar**: "One World, Two Truths" (primary) · "Read, Then Strike" and "Remade Every Death" (supporting)

> **Contracts**: SYS-09 `design/gdd/dual-reality-state.md` (APPROVED gated on S1-007) — the Flip-Trigger Contract **TR-DR-004 consumed verbatim** (E1–E7 + G1–G7; `ambient_shift` pinned to `epoch_swap`'s tick with the receding-first hold; the beat-aligned tear hook at τ0; `freeze_open`/`freeze_close` as the stillness brackets; `flip_complete` as the resume), the arena's steel-hum expectation (TR-DR-011), the liminal wing (TR-DR-012), the audio interaction row (downstream, contract-first); SYS-10 `design/gdd/world-mutation-epochs.md` (In Design 2026-11-14) — E3b `ambient_shift` is **SYS-10's emission** pinned to `epoch_swap`'s tick, and the **abort case** (`freeze_open` fires, E3/E3b/E4 never do, the bed stays put); SYS-29 `design/gdd/juice-feedback.md` (APPROVED 2026-11-13) — **TR-JCE-027** (the closed audio edge list + the single death-duck request `{bus, dB, hold}`, `DEATH_DUCK_DB` −6 provisional, OQ-J7), TR-JCE-018 (the death sting publishes no audio edge), TR-JCE-021 (the memory chime is audio-led; the Leap-Stone grant reuses it); SYS-11 `design/gdd/seam-borders.md` (APPROVED 2026-11-14) — **AR-SMB-01..04** (zero audio publications; the bed continues; the no-duck ruling; M4's chime is not the seam's); SYS-07 `design/gdd/health-damage.md` — `DamageNumber`/`HealEdge`/`DeathRecord`/`DefeatEvent` edges; SYS-08 `design/gdd/combat.md` — TR-CMB-021/022/023 (the clash pair, the hit-stop pairing, no per-press chatter); SYS-02 `design/gdd/room-world-structure.md` — the six-room fixture (RM-01..RM-06; RM-06 is the pinned arena); SYS-24 — the settings surface renders SYS-04's a11y knobs; ADR-0001 §3 (the freeze) and §5 (the tick boundary) consumed.

---

## A · Overview

Audio Core is the ear's half of the truth contract. SYS-02 stores the world's word, SYS-09 renders it, SYS-10 changes it — and this system is where the change is *heard*. It owns every sound the player perceives: the buses and the mix, the ambient beds, the closed one-shot vocabulary, the flip's sound composition, the single duck request's execution, the import settings, and the mobile budget. It publishes nothing to any other system; it is a leaf consumer, and that is deliberate — a sound that another system had to wait on would be a sound that can stall the world.

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

## C · Contracts Consumed — *to be authored (pending approval)*

The E1–E7 table verbatim with the audio obligation at each edge; G1–G7 as consumed; the closed edge list and its count arithmetic; the arena/wing expectations; the abort case; the latched-resume case; the no-duck rulings (SYS-09's sweep ruling, SYS-11's AR-SMB-03). No contract revision is requested.

## D · The Flip's Sound — *to be authored (pending approval)*

The E1–E7 consumption table (arm → bracket → recede → tear → arrival → resume); the receding-first `ambient_shift` law pinned to `epoch_swap`'s tick; the target set (the non-arena rooms exactly) and the zero-arena-bed-orders assertion; the freeze brackets; the tear layer and its abort-path degenerate form; the in-arena edge case.

## E · The Closed Edge List — *to be authored (pending approval)*

Per-event spec sheets for the ten SYS-29 edges (eleven one-shot voices) and the flip's tear: trigger edge, bus, priority class, concurrency, retrigger floor, variations, pitch randomization, duration class, and the "never a per-hit voice" amount-band law.

## F · Ambience Design — *to be authored (pending approval)*

The three beds and their layers; the wing's no-op; the arena's epoch-invariance; the room→bed table; the transition law (the receding-first turnover); the ban on stochastic detail one-shots at MVP.

## G · Audio Architecture — *to be authored (pending approval)*

Buses, the single mix snapshot, voice pools and the hard cap, loop points, import settings, the mobile budget on the reference SKU, the `duck_request {bus, dB, hold}` schema, telemetry and the order-trace record, and the missing-input failure paths with named owners.

## H · The Mix — *to be authored (pending approval)*

Nominal bus volumes; priority and steal rules; frequency-masking notes; the death-duck ratification (OQ-J7); the accessibility surface (mono, volume groups, the caption-metadata hook).

## I · Formulas — *to be authored (pending approval)*

F-AUD-01 dB↔linear · F-AUD-02 the recede/arrival schedule · F-AUD-03 the damage amount band · F-AUD-04 the duck envelope and hold · F-AUD-05 the voice budget and steal · F-AUD-06 the order-trace hash · F-AUD-07 the glitch-window tick count.

## J · V-Invariants & Acceptance Criteria — *to be authored (pending approval)*

V-AUD-01..07 (one duck family; the closed list; zero arena-bed orders; epoch-blindness; zero snapshot changes across the flip; receding-first by construction; the gate drops-never-queues; the tear never stolen) and the AC set with its gate partition ([GUT] / [LINT] / [DEVICE] / [PLAYTEST]).

## K · Tuning Knobs · Edge Cases · Dependencies · Open Questions — *to be authored (pending approval)*

The knob table with ranges and rationale; the edge-case ledger; the dependency matrix with named owners; the open-question register (OQ-AUD-1..8) with owners and landing points.
