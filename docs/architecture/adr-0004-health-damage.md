# ADR-0004: Health & Damage — The Six-Stage Pipeline, the Latch, and the Pool's One Writer

## Status

**Proposed** — drafted 2026-11-15 by the ADR-DRAFT lane (support), pass 2.
**Acceptance awaits the technical-director's TD-ADR verdict (D-ORCH-06)**: the
`/architecture-review` gate and this lane's gate trail (CD · creative · technical ·
QA · qa-lead spot-check · micro-check · `/architecture-review`) are recorded in
`docs/architecture/adr-draft-review-log.md` **§9 — this pass's record**, which lands
in the same PR as this document. An advisory review verdict does
not replace the TD-ADR gate, and `Status: Accepted` would let story-readiness start
stories against this decision early. **The status is never self-assigned by the lane
that drafts the document.** The engine-probe register in §12 is an **implementation
gate**, not an ADR-status gate. Carried obligations (not status gates): the six
SYS-16 riders (O-HD-1…6), the DEF retirement (O-HD-2), the AC-HD-13 DEFLECT fixture
(CR-HD-01), the energy/mana round-trip (O-HD-7), the superseded four-system
envelope (O-HD-8), the body-state persistence contradiction (O-HD-9), the
tier/strike ordering coverage gap (O-HD-10) and the System Offline publisher's split
(O-HD-11); plus **CR-HD-02** (the late-event sort's one-clause rider). If a later
architecture review finds a contradiction with a newer Accepted ADR, this ADR
reverts to `Proposed` and is superseded explicitly.

## Date

2026-11-15

## Last Verified

2026-11-15 — verified against the SYS-07 GDD at Main `016bbbe`
(`design/gdd/health-damage.md`, APPROVED 2026-11-12, **revised 2026-11-15 by
D-ORCH-03**, the IP-17 low-stat baseline rework), the landed SYS-16 GDD
(`design/gdd/progression.md`, APPROVED 2026-11-15 — the source of the six riders),
the SYS-15 GDD's body row (`design/gdd/cache-stations-death.md`, TR-CSD-013), the
registry entries `damage_event`, `system_offline_contract`, `progression_namespace`,
`six_system_perf_envelope` — and the entries this ADR's decisions **touch** but do not
write: `damage_ladder_mvp` (the 5×4 table), `atk1_damage`/`atk2_damage`/
`crouch_attack_damage`/`air_attack_damage` (row 0's four knobs), `atk_per_point` 8,
`player_atk_base` 100, `level_cap_mvp` 5, `chassis_module` (the closed payload set),
`gear_aggregate` (the equip-change revision and the `hp_max` delta),
`grief_boss_rig_contract` (the floor release) and `designation_counter` (SYS-15's
increment points) — and the Godot 4.7.2 engine-reference snapshots
(`VERSION.md`, `breaking-changes.md`). **No registry entry and no index row is edited
by this lane**: ADRs are not registry entities, and §13's riders are the route.

**Cross-contract findings, recorded not edited** (each is a rider or a carried
obligation, never a silent change to frozen text):

1. **AC-HD-13's DEFLECT fixture contradicts its own dispatch.**
   `design/gdd/health-damage.md` AC-HD-13 reads "one `DEFLECT` fixture at a
   non-default `attack` (raw 2 → 3 at 132)", but F-HD-02 branch 5 says every
   `DEFLECT` **skips the attack scaling** — "the identity, `dealt = raw_damage`,
   whichever side deflected it" — because TR-CMB-015 requires the deflected
   projectile to keep its **original** damage. At `attack 132` a raw-2 deflect is
   2, not 3. → **CR-HD-01** (§13, one clause).
2. **`defense` has no MVP source at all.** SYS-07's TR-HD-006 says "`defense` gains
   its first MVP source at SYS-16 authoring" and its test clause says "a
   module-produced DEF is legal at MVP". SYS-16 landed **TR-PRG-016 — DEF is retired
   from the gear layer**: the payload set is closed to `damage_bonus`/`hp_max`, and
   at MVP every loadout's `defense` is 0. → **O-HD-2** (the two-clause rider SYS-16
   already requested).
3. **`attack > 132` has two laws and only one MVP reachability.** F-HD-02 clamps
   `step()` at row 4; TR-PRG-010/F-PRG-03 extends the ladder by its top row. They
   agree on the whole MVP domain (`attack ≤ 132`, by `POINT_BUDGET_CAP` 4 and
   TR-PRG-012's closed payload — no module carries `attack`). §6 decides the
   extension as the law's closed form and records the rider (**O-HD-6**).
4. **AC-HD-08's "the save round-trips both [energy, mana]" has no registered
   namespace.** SYS-03 declares SYS-07 an explicit runtime non-dependency; the
   landed `progression` namespace carries `{level, training_data, atk_points,
   hp_points, grants, owned, equipped}` and no pool. → **O-HD-7**.
5. **AC-HD-41's "four-system arithmetic envelope" is superseded.** The registry's
   `six_system_perf_envelope` (the historical handle) now composes **seven**
   systems at **2.45 / 6.55 ms**, with SYS-07's own allocation unchanged at
   **0.25 / 0.75 ms**. → **O-HD-8**.

## Decision Makers

| Seat | Role in this decision |
|---|---|
| technical-director | Acceptance chair (TD-ADR, D-ORCH-06); the resolver/reducer split, the tick position, the carried-rider ruling |
| lead-programmer | The pure `DamageResolver`, the `HealthCore` reducer, the port set, the ladder transaction |
| godot-gdscript-specialist | Engine-API verdicts: integer division, `Callable` ports on the hot path, the RNG mixer, the label pool, the verification register |
| game-designer | The six-stage order, the ladder's identity-at-default, the damage-number law |
| qa-lead | The fixture set, the soak's allocation bar, the AC→gate partition, the device gate |
| user | Scope authority; the D-ORCH-03 baseline (2026-11-15) and D-1's MVP gear (2026-11-14) |

## Summary

SYS-07 is design-complete and its numbers are pinned, but its GDD deliberately
stops at the behaviour level: it delegates the `HealthCore` reducer, the
`DamageResolver` pipeline, the `StatBlock` revisions, the RNG port and the pooled
damage-number labels to this ADR, and TR-HD-028 explicitly says "**the ADR pins the
exact node position**" of the damage phase. This ADR decides those, and settles the
four things the GDD could not: the **damage phase's position in the tick** (after
Combat's contact detection, before the hit-stop freeze onset, on the contact
`logic_tick` — with the freeze onset being *next* tick's phase 0 by ADR-0001's own
structure, so the order is true by construction); **which clock `now_tick()` is**
(`logic_tick`, not `physics_tick` — otherwise a 70 ms hit-stop would age every queued
event past the 2-tick bound); **where the per-event cap is applied exactly once**
(the apply boundary, with `DamageResult.dealt` pre-cap and `applied` post-cap); and
**who owns the damage-number pool** (SYS-07 owns the 32-slot record ring and the
zero-frame publication; SYS-24/SYS-29 own the label nodes and lease slots from the
ring). The shape is one pure `DamageResolver` over two injected ports (`HealthPort`,
`RngPort`), one
`HealthCore` reducer that is the pool's only writer, one 5×4 ladder validated as a
unit with its knobs, and one ordered six-stage pipeline with no branch ambiguity.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (pinned; GDScript) |
| **Domain** | Core + Gameplay (pure `RefCounted` reducer, typed containers, `Callable` ports, `Resource`-backed config, `Label` pooling) |
| **Knowledge Risk** | **MEDIUM** — the *gameplay* APIs this ADR uses are 4.0-era and stable in training data; the risk is concentrated in three places: GDScript's **integer division semantics** (truncation toward zero, not floor) against a floor law written for non-negative numerators, `Callable`-per-event cost inside a 0.25 ms p99.9 budget, and the **portability of `hash()`** if it were used for the VS roll |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `breaking-changes.md` (4.6→4.7 table: typed-return overrides, packed-array element setters); `docs/framework/technical-preferences.md` (naming, GUT, the 16.6 ms budget); **ADR-0001 §5** (the phase pipeline this ADR's damage phase follows); **ADR-0002 §5/§6** (the tick-boundary service drain and the `restore_complete`→`load_complete` ordering) |
| **Post-Cutoff APIs Used** | `RefCounted` + static typing (pre-cutoff); `Callable` binding (pre-cutoff); `Resource` + `@export` (pre-cutoff); `Label`/`CanvasLayer` (pre-cutoff); `Node.process_physics_priority` **[unverified for 4.7.2 — register item 8, the fallback ordering only]**; **no** post-cutoff API is load-bearing in this decision, which is why the risk is MEDIUM and not HIGH |
| **Verification Required** | The 9-item register in §12, each with a Method and an Owner. **7 are `PROBE-PENDING`** and block their named gate; **item 1 is `DOCUMENTED`** (GDScript's `/` on two ints yields an int, truncating toward zero — the reason §3's floor law uses `floori()` on a float division or an explicit non-negative integer form); **item 2 is `DOCUMENTED`** by the language reference (`floori`). On the TD-ADR verdict this ADR becomes **Accepted as architecture**; the register is the implementation gate, and no story may consume a `PROBE-PENDING` item as settled fact. |

> **Knowledge-gap warning (MEDIUM).** One failure mode is specific to this decision
> and is load-bearing: the GDD's damage law is written with **floor** semantics
> (`floor(raw × (100 − defense) ÷ 100)`, `floor((attack − 100) ÷ 8)`) while
> GDScript's `/` on two ints **truncates toward zero**. On the MVP domain every
> numerator is non-negative, so the two agree — and that is exactly the trap: the
> day a negative appears (a `damage_bonus` that subtracts, a defense above 100
> before the clamp), truncation and floor diverge and a fixture that passed at DEF 0
> starts passing for the wrong reason. §3 therefore fixes the arithmetic **form**,
> not just the values.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | **ADR-0001** (Accepted) — §5's phase pipeline (the damage phase's position relative to phases 0–6), §6's non-ack gate queue (the death edge's request), §3's freeze law (the freeze onset is next tick's phase 0); **ADR-0002** (Proposed) — §5's tick-boundary service drain (the damage phase is the same shape of service phase) and the `restore_complete`→`load_complete` ordering that both load regimes consume |
| **Enables** | SYS-08 Combat (the resolver's consumption of `DamageEvent` — the producer's contract is ratified, not changed), SYS-13 (the strike table's consumer), SYS-14 (the boss profile hooks), SYS-15 (the options contract's `DeathRecord`), SYS-16 (the `StatBlock` schema and the identity-at-default boot assertion), SYS-24/SYS-29 (the damage-number ring and the HP bar's read), SYS-05 (the death context) |
| **Blocks** | The first SYS-07 implementation story; every story that applies damage, heals, or reads HP; the QA plan's device gate (AC-HD-41/42/43); the four-system → seven-system soak |
| **Ordering Note** | SYS-16's `progression` namespace lands at its own story (v2→v3); SYS-07's health state is **not** persisted (TR-HD-032) so this ADR does not wait on it. The engine probes run at the first story, not at this ADR. The DEF retirement (O-HD-2) changes no mechanism here: the axis is implemented and unit-tested at 0/5/25, and at MVP it is constant 0. |

## Context

### Problem Statement

The GDD is design-complete — 39 TRs, 15 formulas, 50 ACs, and an identity-at-default
law that pins every approved number — but it explicitly delegates the implementation
shape: "*Implementation patterns (`HealthCore` reducer, `DamageResolver`, `StatBlock`
revisions, the RNG port, the pooled damage-number labels) are ADR raw material for
the planned Health/Damage ADR; this GDD stays at the behavior level*" (§Overview),
and TR-HD-028 adds the sharpest obligation of all: "*The ADR pins the exact node
position; this GDD records the requirement*".

Without this ADR, two implementers can build two incompatible resolvers from the same
GDD, and the failure modes are not cosmetic — they are the ones the Player Fantasy's
"the number is the body's memory" clause exists to forbid:

- a pipeline that applies the **module stage after the crit** doubles a gear bonus
  under a VS crit and makes the printed ladder a lie about the hand;
- a `now_tick()` bound to `physics_tick` makes a **70 ms hit-stop age every queued
  event past the 2-tick window**, so a hit that lands during a freeze is silently
  dropped — the one class of bug the player experiences as "the hit didn't register";
- a second writer to the HP pool (a UI clamp, a save restore, a debug setter) breaks
  TR-HD-010's "the only writer is `HealthCore`" and with it the latch's exactly-once
  guarantee;
- a stateful RNG (or the engine's global `randf()`) makes a trace unreplayable, which
  kills AC-HD-39's bit-identical assertion and the whole determinism story at VS;
- a damage number that allocates a `Label` per hit blows AC-HD-40's churn bar in the
  one moment the game is busiest (a swarm).

The cost of not deciding is therefore a class of bugs the player experiences as the
game lying about a number — in the one channel the design says the player must be
able to trust without thinking.

### Current State

- `src/` contains no game code; the project has no `project.godot`. There is no
  health code to migrate.
- The SYS-07 GDD is **APPROVED** (2026-11-12) and **revised 2026-11-15 by
  D-ORCH-03** (the ÷5 baseline rescale, the growth ladder, the gear riders, the
  parity restatement). Its package is `design/reviews/sys07-baseline-rework-package.md`;
  its review record is `design/gdd/reviews/sys07-rework-review-log.md`.
- **SYS-16 has landed** (`design/gdd/progression.md`, APPROVED 2026-11-15) and
  resolves three of SYS-07's open questions (OQ#5, OQ#18, OQ#20) while requesting
  **six riders** to SYS-07's text (a–f). This ADR consumes SYS-16's answers and
  carries the riders.
- **SYS-15 has landed** (`design/gdd/cache-stations-death.md`) and closes SYS-07's
  OQ#8; its body row (TR-CSD-013) states the carried module is **live session
  state** — "the store never carries it" — which is the fact §9's persistence
  boundary rests on.
- The registry holds `damage_event` (`active`, added 2026-11-15 by D-ORCH-03),
  `system_offline_contract`, `progression_namespace`, `six_system_perf_envelope`.
- `docs/architecture/tr-registry.yaml` is still empty (`requirements: []`); the TR
  population is `/architecture-review`'s write, not this lane's.

### Constraints

- **Engine**: Godot 4.7.2, GDScript; 2D; mobile-first (iOS/Android) with PC
  secondary; 60 fps; 16.6 ms frame budget; ~150 MB memory ceiling.
- **Budget**: SYS-07's allocation is **p99.9 ≤ 0.25 ms / max ≤ 0.75 ms** inside the
  seven-system envelope (2.45 / 6.55 ms).
- **Design**: SYS-07 never reads `Input`, never inspects a hitbox, never renders,
  and never decides hit/miss (TR-HD-001). Every HP/damage/heal value is an integer
  (TR-HD-004). The pipeline is total and deterministic (TR-HD-005/V-HD-15).
- **Contracts**: `DamageEvent` is SYS-08's and is consumed verbatim (six fields);
  the strike table is SYS-07's and consumed by Combat; the boss hooks are SYS-07's
  and valued by SYS-14; the `StatBlock` schema is SYS-07's and the sheet is SYS-16's.
- **Process**: Main is protected; work lands via branch + PR; the collaboration
  protocol requires approval before writes; every checkpoint is pushed.

### Requirements

- **R1 — One pure resolver, one stateful reducer.** The damage law is decidable from
  data, so it lives in a pure function over `(AttackContext, DefenderSnapshot,
  RngPort, DamageLadder)`; the pools, the latch and the state machine live in
  `HealthCore`, which is the **only** writer of HP (TR-HD-010/037).
- **R2 — The six stages, in order, once each.** `raw → ladder/percent (dealt) or
  F-HD-03 (taken) → module → crit → floor → cap`. No stage is skipped, doubled, or
  reordered by a branch (TR-HD-005, V-HD-15).
- **R3 — The damage phase runs on the contact tick, before the freeze onset.** After
  Combat's contact detection, before the hit-stop freeze onset, same `physics_tick`,
  on the contact `logic_tick` (TR-HD-028).
- **R4 — The age bound is measured on the stamp clock.** `now_tick()` is
  `logic_tick` — the clock `contact_tick` is stamped on (TR-INP-076) — so a freeze
  holds the window instead of ageing events through it.
- **R5 — The edge is a latch.** It fires iff `hp_before > 0 ∧ hp_after = 0` and
  `state = ALIVE`, exactly once per life, carrying a `DeathRecord` (TR-HD-014/015,
  F-HD-05).
- **R6 — Identity at default is a boot assertion.** Level 1 with no gear returns
  every approved number exactly; the ladder's row 0 equals the four raw knobs; a
  disagreement is a boot failure (TR-HD-006, V-HD-12).
- **R7 — The RNG is inert at MVP.** Zero rolls; a `FixedRngPort` returns the median
  (0.5); at VS the roll is a **stateless** counter hash over
  `(logic_tick, attacker_id, defender_id, contact_tick)` (TR-HD-037).
- **R8 — No hot-path allocation.** The entity table, the event ring, the ledger, the
  damage-number ring and the telemetry ring are preallocated and bounded
  (TR-HD-038).
- **R9 — HP is never persisted.** A load reconstructs at the station with a full
  pool; the save carries progression, not the body (TR-HD-032, TR-CSD-013).
- **R10 — The cap is applied once.** `dealt` is post-floor pre-cap; `applied` is
  post-cap; `capped` is computed at the single apply site (TR-HD-017 term 10,
  F-HD-04).
- **R11 — The ladder is one unit with its knobs.** A live edit to a raw knob is a
  two-field transaction with its row-0 cell; the four V-HD-12 checks decide
  accept/reject/clamp (F-HD-14).
- **R12 — Testability.** Every law is falsifiable headless through the ports; a
  scripted trace replays bit-identically (TR-HD-037, AC-HD-39).

## Decision

### 1 · Scope and non-goals

**In scope.** The resolver/reducer split and the port set; the six-stage pipeline and
its dispatch; the damage phase's tick position; the `StatBlock` schema, the revision
discipline and the identity-at-default boot assertion; the 5×4 ladder, its
validation and its transaction; the `attack > 132` extension; the RNG port; the
`HealthCore` state machine, the latch, the ledger, the gates; the two load regimes
and the persistence boundary; the damage-number record ring and the label lease; the
test seams; the engine verification register.

**Out of scope (owned elsewhere).** The `DamageEvent`'s production, `raw_damage`,
`kind`, `arc` and `contact_tick` (SYS-08); hitbox/whiff truth (SYS-08/SYS-13);
`power`, `soul_class`, the enemy tier per type (SYS-13); the knockback/stagger/
`DISABLED` mechanics (SYS-06); the freeze/hit-stop publication (SYS-29); the tick
director's composition (the tick-director story); the System Offline screen, the
print copy, the neural terminal and the counter (SYS-15/SYS-28); the HP bar, the
chip's visuals and the damage-number **nodes** (SYS-24/SYS-29); the full sheet,
levels 6–20 and the gear aggregation (SYS-16); the item definitions and the full
inventory (SYS-17); the save schema and the writer thread (SYS-03/ADR-0002).

**Non-goals.** No crit at MVP (VS); no elements/resistances (VS); no agility
recovery (VS); no mana consumers (VS); no second weapon (VS); no in-place respawn
i-frames (VS, SYS-07 OQ#16); no damage-number world/native anchoring decision (SYS-24);
no second `DamageEvent` schema field; no percentage damage curve; no floating-point
damage; no stateful RNG.

### 2 · The node graph and the resolver/reducer split

The GDD splits the seam itself (TR-HD-037): `DamageResolver` is a pure function,
`HealthCore` is the stateful reducer. This ADR takes that split literally — the
resolver has **no** `HealthPort`, no clock, no publication, and the reducer has no
arithmetic beyond the subtraction and the clamps.

```
                    ┌──────────────── DamageResolver (RefCounted, pure) ───────────────┐
 SYS-08 DamageEvent │ resolve(ctx: AttackContext, snap: DefenderSnapshot,               │
 SYS-02/15 ENV ────▶│         rng: RngPort, ladder: DamageLadder) -> DamageResult     │
                    │  stage 1 raw · stage 2 ladder/percent/taken · stage 3 module     │
                    │  stage 4 crit · stage 5 floor · stage 6 cap (the apply boundary) │
                    └───────────────────────────┬─────────────────────────────────────┘
                                                │ DamageResult {dealt, applied, overkill, crit, capped}
                                                ▼
                    ┌──────────────── HealthCore (RefCounted, stateful) ───────────────┐
 SYS-16 StatRevision│ the entity table (64) · the pools · the latch · the state machine│
 SYS-01 chip ──────▶│ the idempotence ledger (256) · the event ring (32)               │
 SYS-03 load ──────▶│ damage_phase(t) · heal() · apply_stat_revision() · reconstruct() │
                    │ draw_restore_module() · read() -> HealthRead                     │
                    └──────┬──────────────────┬───────────────────┬────────────────────┘
                           │ HealthPort        │ RngPort           │ publication ring
                           ▼                   ▼                   ▼
                    profile/invuln/anchor   FixedRngPort (0.5)   DamageNumber ring (32)
                    now_tick()/publish()    VS: counter hash     → SYS-24/SYS-29 labels
```

**Why the split is load-bearing.** AC-HD-39 replays a scripted trace twice through
`HealthCore` with `FakeHealthPort`/`FixedRngPort` and asserts bit-identity; AC-HD-01
runs a mocked stream and a human capture through the resolver and asserts
bit-identity over 600 ticks; AC-HD-40's soak asserts zero net allocation. A resolver
that called `publish()` or read a singleton would make all three impossible, and the
GDD's own test clause names the fakes. The reducer is stateful **only** in the ways
the GDD enumerates — the pools, the latch, the ledger, the state, the revision — and
nothing else.

**The tick position is a service phase, not a node order.** ADR-0001's pipeline is
phases 0–6 and has no damage phase; ADR-0002 solved the same problem for the save by
running "its own drain **after** that pipeline, on the same tick boundary". The damage
phase is that shape with one extra constraint: it must also run **after Combat's
contact detection**. §4 pins it.

**§2a · The three records, with their fields.** TR-HD-037 names the resolver's two
inputs and the profile; this ADR fixes their shapes so a fixture can construct one.
The `StatBlock` is the **source** of three of these values, copied in by the reducer
before the call — the resolver never reads a `StatBlock` (that is what makes it pure).

```gdscript
class_name AttackContext extends RefCounted
var attacker_id: int
var target_id: int
var raw_damage: int          # the producer's, already including the counter's 1.5x
var kind: int                # NORMAL | COUNTER | DEFLECT | ENEMY_STRIKE | ENVIRONMENT
var arc: int                 # ATK1 | ATK2 | CROUCH | AIR | ABILITY | NONE
var contact_tick: int        # a LOGIC tick (TR-INP-076)
var attack: int              # the ATTACKER's StatBlock.attack (the PLAYER's 100-132 at MVP)
var damage_bonus: int        # the ATTACKER's StatBlock.damage_bonus (0 at no gear)

class_name DefenderSnapshot extends RefCounted
var target_id: int
var defense: int             # the TARGET's StatBlock.defense; ALWAYS 0 at MVP
var hp_current: int
var hp_max: int
var profile: HealthProfile
var invulnerable: bool       # the lock's verdict, read once per event by the reducer

class_name HealthProfile extends RefCounted
var entity_id: int
var hp_max: int
var tier: int                # 1 | 2 | 3 | boss
var iframe_windows: Array    # the entity's own published windows
var damage_cap_per_event: int # 0 = UNCAPPED (§8a)
var hp_floor: int            # 0 = NO FLOOR (§8a)
var immune_kinds: int        # a bitmask over the five-value enum
var death_scripted: bool
var soul_class: int          # DEMONIC | HUMAN | CYBORG | MACHINE
```

**Which record carries which value** — so no value has two homes: `attack` and
`damage_bonus` are the **attacker's** and live in `AttackContext`; `defense` is the
**target's** and lives in `DefenderSnapshot`; `damage_cap_per_event`, `hp_floor`,
`immune_kinds`, `death_scripted` and `soul_class` are the **profile's**. The reducer
copies `StatBlock.attack`/`damage_bonus` into the context and
`StatBlock.defense` into the snapshot at the phase's top, so the resolver stays pure
and the `StatBlock` stays SYS-16's publication.

**A non-player attacker.** TR-HD-019 forbids a team assumption, and AC-HD-21
exercises an enemy-sourced `DEFLECT`. `AttackContext.attack` is therefore the
**attacker's own** `attack`: an enemy attacker publishes its own value from its
profile (SYS-13's, 0 at MVP), and the ladder/percent branches read it as they would
the player's. At MVP only the player carries a ladder arc, so a non-player
`NORMAL`-with-arc event is a **dev assert** — the law is general, the MVP content is
not.

### 3 · The six stages, and the dispatch that selects them

The order is TR-HD-005's and V-HD-15's: **raw → ladder/percent (dealt) or F-HD-03
(taken) → module → crit → floor → cap**. The resolver is one function with one entry
and **seven content branches plus an else-reject** (the registry's `damage_event` note
calls the content set "seven-branch"; the else is the eighth arm and carries no law);
every branch produces the same six-stage walk, and no branch re-enters a stage.

| # | Stage | What it does | Branches that reach it | Forbidden here |
|---|---|---|---|---|
| 1 | **raw** | the producer's `raw_damage`, already including the counter's 1.5× | all | any SYS-07 re-application of `COUNTER_CLASH_MULT` |
| 2 | **ladder / percent / taken** | `NORMAL`+arc → `LADDER[step][arc]`; `COUNTER`/`NORMAL`+`ABILITY` → `max(1, ceil(raw × attack ÷ 100))`; `ENEMY_STRIKE`/`ENVIRONMENT` → F-HD-03's `taken`; `DEFLECT` → the identity | 2–7 | a percent curve for `NORMAL`+arc; a DEF read on `ENVIRONMENT` |
| 3 | **module** | `dealt = max(1, dealt + ctx.damage_bonus)` — **branch 2 only** | 2 | applying `damage_bonus` to `COUNTER`, `DEFLECT`, `ABILITY`, `ENEMY_STRIKE` or `ENVIRONMENT` |
| 4 | **crit** | `dealt = floor(dealt × CRIT_MULT)` — **VS, `kind = NORMAL` only** | 2 **and 4** (VS) | a crit on `COUNTER` (no 2.25×), on `DEFLECT`, on `ENEMY_STRIKE`, or on the taken side |
| 5 | **floor** | `dealt = 0` if `raw = 0`, else `max(1, dealt)` | all | a floor on a zero-raw event (the zero-exempt rule) |
| 6 | **cap** | `applied = min(dealt, profile.damage_cap_per_event)`, then the subtraction | all | a cap as a **gate** (it is a clamp: TR-HD-017 term 10) |

**The dispatch, in order, with its rejections.** A pre-dispatch check runs first,
after the zero branch: a `NORMAL` or `COUNTER` event with `arc = NONE` is **rejected
per event** with a named telemetry reason (and a dev assert). This is an event-level
rejection, never a config resolution — "keep the last good config" is the knob
validation's rule (V-HD), not this one.

1. `dealt = 0` if `raw_damage = 0` (the zero branch; no floor, no crit, no cap).
2. `NORMAL ∧ arc ∈ {ATK1, ATK2, CROUCH, AIR}` → the ladder, then the module stage.
3. `COUNTER` → `max(1, ceil(raw_damage × attack ÷ 100))`. Combat stamps
   `raw = floor(ATK.damage × 1.5)`; SYS-07 **must not** re-apply the multiplier.
4. `NORMAL ∧ arc = ABILITY` → the same percent law on the event's raw (D-3's Stinger
   cell). `ABILITY` is **not** a ladder column; the ladder's four columns are
   `ATK1/ATK2/CROUCH/AIR`. It **is** a `NORMAL`, so at VS it takes the crit stage like
   any other `NORMAL` — TR-HD-005's "dealt, `kind = NORMAL` only" is the crit's scope,
   and branch 4's kind is `NORMAL`; a rule that excluded `ABILITY` would be a second
   law the GDD does not state.
5. `DEFLECT` → **the identity, `dealt = raw_damage`**, whichever side deflected it
   (TR-CMB-015: the deflected projectile keeps its **original** damage). For a
   player target the value then passes F-HD-03's `taken` at stage 2's arithmetic
   (the player carries `defense`; TR-HD-018 names only `ENVIRONMENT` as bypassing
   mitigation) — and at MVP `defense = 0`, so the identity holds numerically as well
   as by law.
6. `ENEMY_STRIKE` → F-HD-03's `taken` (never the dealt law).
7. `ENVIRONMENT` → `taken = raw_damage` (no DEF, no i-frame lock), then the cap.
8. else → reject with telemetry.

**§3a · The arithmetic form is part of the law.** The GDD writes the ladder's index,
the mitigation and the crit with **floor**; it writes the counter and the ability
percent law with **ceil**. GDScript's `/` on two ints **truncates toward zero**, and
the two agree with `floor` only while the numerator is non-negative — and with
`ceil` never. The implementation therefore makes the rounding **explicit at every
site**: `floori(a / float(b))` where the GDD writes `floor`, `ceili(a / float(b))`
where it writes `ceil`, and **never** bare `a / b` for either law. The clamp before
the division is what keeps the floor's numerator non-negative:
`defense = clampi(defense, 0, DEF_CAP_PCT)` is applied **before** `(100 − defense)`.
AC-HD-14's DEF 100 fixture (clamps to 25 → 1/1/3) is the same assertion from the
other side. Register items 1–2 record the language facts; this paragraph is why they
matter — a `floori` applied to the counter law would return 3/3/3/3/3 where F-HD-11
promises 3/4/4/4/4, and the counter's reward would vanish one step at a time.

**§3b · The cap is one site, and `dealt`/`applied` are the two sides of it.** F-HD-02
ends with `dealt = min(dealt, profile.damage_cap_per_event)` and F-HD-04 says
`applied = min(taken, profile.damage_cap_per_event)`. Both are true statements of the
same clamp; applying it twice is harmless (a `min` is idempotent) but **reporting**
it twice is not, because `DamageResult` carries both `dealt` and `applied` and
`overkill` is computed from `applied`. The law is therefore: **`dealt` is the
post-floor, pre-cap value; `applied` is the post-cap value; `capped` is
`applied < dealt`.** The single site is the apply boundary, and F-HD-02's trailing
`min` is read as the same clamp seen from the dealt formula (the ADR-0002 §6a
"cited reading" pattern — the alternative leaves `dealt` and `applied` equal by
construction and makes `capped` unobservable, which AC-HD-23's "a 6 hit with cap 2
applies 2" needs it not to be).

**§3c · The floor-held case and `overkill`.** `overkill = max(0, applied −
hp_before)` is computed **after** the cap and **before** the profile floor. On the
ordinary lethal path the floor is 0 and `hp_after = 0`, so `overkill > 0 ⟺` the edge
fires. On a boss at its `hp_floor`, `overkill` can be positive while `hp_after` holds
at the floor and **no edge fires** (TR-HD-021's "the phase gate is not a death"). No
consumer reads it there — SYS-29's death sting is edge-triggered, and `DeathRecord`
exists only when the edge fires — so the resolver reports the arithmetic value and
this ADR records that the floor-held case has **no overkill reader**. A future
"sting on a floor-held hit" would need a new rule, not a reinterpretation of this
one.

**§3d · The `attack > 132` law is the same law's closed form.** F-HD-02 clamps
`step()` at row 4; TR-PRG-010/F-PRG-03 extends the ladder by its top row. They agree
on the whole MVP domain (`attack ≤ 132`) and the ADR implements **one function**:

```
dealt_for_arc(attack, arc):
    if attack <= ATTACK_POINTS_CAP:  return LADDER[step(attack)][arc]
    else:  return max(LADDER[4][arc],
                      floori(LADDER[4][arc] * attack / float(ATTACK_POINTS_CAP)))
step(attack) = clampi(floori((attack - PLAYER_ATK_BASE) / float(ATK_PER_POINT)), 0, 4)
ATTACK_POINTS_CAP = PLAYER_ATK_BASE + ATK_PER_POINT * POINT_BUDGET_CAP   # 132
```

`ATTACK_POINTS_CAP` is a **named symbol, not a literal** (the GDD's named-symbol
law): it is derived from `PLAYER_ATK_BASE`, `ATK_PER_POINT` and SYS-16's
`POINT_BUDGET_CAP` (4, fixed at MVP), so the day the budget moves the cap moves with
it instead of becoming a second number that disagrees. It is not a knob — it is a
derived symbol, and the "not knobs" discipline applies to it.

At 132 and at 138 both give 4/6/3/4 (chain 10) — the seam is flat by construction,
so the dealt value is monotone non-decreasing across L5→L6 for every point split
(AC-PRG-10). At MVP the extension is **unreachable**: `POINT_BUDGET_CAP` is 4
(`attack ≤ 132`) and TR-PRG-012 closes the module payload to
`damage_bonus`/`hp_max`, so **no MVP module raises `attack`**. F-HD-02's "an MVP
module that raises `attack` above 132 holds row 4" is therefore a rider (O-HD-6): the
sentence describes a module the closed payload set forbids. This ADR's implementation
satisfies both laws on their own domains and needs no change when the rider lands.

### 4 · The damage phase's position in the tick

TR-HD-028 requires the damage phase "**after Combat's contact detection and before
the hit-stop freeze onset, in the same `physics_tick`, on the contact `logic_tick`**"
and says the ADR pins the node position. The pin is:

| Field | Value |
|---|---|
| **Entry point** | `HealthCore.damage_phase(t: int, events: Array[DamageEvent]) -> void` — one call per tick, events in the tick's arrival batch |
| **Position** | **after** ADR-0001's phases 0–6 and **after** Combat's contact detection, **before** the freeze publication. It is a **service phase**, the same shape as ADR-0002's save drain |
| **Clock** | runs on `physics_tick`; every event's `contact_tick` is a `logic_tick` (TR-INP-076); `now_tick()` returns `logic_tick` (§4a) |
| **Freeze onset** | **next tick's phase 0.** ADR-0001 §5's phase 0 is "apply pending freeze/unfreeze", so a freeze requested in `T` is applied in `T+1`. The damage phase in `T` therefore precedes the onset **by construction**, not by node ordering |
| **Frozen ticks** | the phase **still runs** (TR-HD-028: "freeze blocks producers … not the reducer"); a scripted `ENVIRONMENT` event during a freeze applies |
| **The dev assert** | `assert(not freeze_onset_applied_for(t))` — a hit-stop requested in `T` must not be readable as "applied" when the damage phase for `T` runs |
| **Composition root** | the tick director (its own story) calls, in order: input pipeline (ADR-0001) → Combat contact detection → **damage phase (this ADR)** → freeze publication (SYS-29) → save drain (ADR-0002) |
| **Fallback ordering** | if the director ever defers to the scene tree, `Node.process_physics_priority` pins the three gameplay services **[register item 8]**; the explicit call is the primary and the priority is the documented fallback |

**§4a · `now_tick()` is `logic_tick`, and that is load-bearing.** TR-HD-017's term 5
is `0 ≤ now_tick − contact_tick ≤ DAMAGE_EVENT_MAX_AGE_TICKS (2)`, and
`contact_tick` is stamped on the **`logic_tick`** (TR-INP-076, and SYS-07's own
ADR-0001 ratification row says so). A 70 ms hit-stop at 60 tps is ~4.2 `physics_tick`s
during which `logic_tick` does not advance. If `now_tick()` were `physics_tick`,
**every** event queued across a hit-stop would be 3–5 ticks old on arrival and would
fail term 5 — i.e. a hit that starts a hit-stop would apply (it arrives the same
tick) but a hit that lands **during** one would be dropped, which is exactly the
"the hit didn't register" failure the pillar forbids. Binding `now_tick()` to
`logic_tick` makes the window **freeze with the clocks**, which is the GDD's clock
law ("a freeze holds the clocks, not the reducer") and the reason a scripted void
during a freeze still applies. `physics_tick` remains the **phase** clock; the two
are ADR-0001's two clocks and this ADR consumes both, for different jobs.

**§4b · Same-tick ordering is total, and the heal phase follows.** **One rule, no
second clause**: the batch is sorted by `(contact_tick, source_id, publication_index)`
and that sort is the only order the phase applies. Every event sees the HP after the
previous; the first **applied** lethal event is the `DeathRecord`'s cause; later
events in the same tick see `DEAD` and are rejected (TR-HD-020).

**The late event, and why the GDD's "arrival order" clause is subsumed rather than
contradicted.** A late event is a batch member whose `contact_tick` precedes the
phase it arrives in; its `publication_index` **is** its arrival index, so it sorts
into its own `contact_tick` group and — because that group's key is lower — **ahead
of every fresh event in the batch**. The GDD's sentence ("applied in arrival order if
the target is `ALIVE`") describes exactly this whenever the producer's publication
order matches its contact order, which the GDD itself guarantees ("Combat publishes
every contact event in its contact tick's damage phase … the age bound is a safety
net"). Where the two could disagree — a batch mixing a late and a fresh event — the
**sort wins**, because the sort is total and the arrival clause is not, and a
non-total rule makes `hp_before` (and therefore `overkill`, and therefore SYS-29's
sting) depend on delivery order. Stated as the law: *the batch has one total order;
a late event is ordered by its stamp, not by its lateness.* A late event that reaches
its sorted position when the target is already `DEAD` is rejected and never rewrites
the recorded cause. **Because this reads TR-HD-020's sentence rather than restating
it, it is filed as CR-HD-02** — a one-clause rider, not a silent reading.

The **heal/use phase resolves after the damage phase in the same tick**: a heal whose
target reached `DEAD` is refused and its charge is preserved. The reducer exposes
`heal_phase()` as a distinct entry so the order is a call order, not a hope.

**§4c · The non-Gameplay context.** The damage phase is a **Gameplay** service: it
does not run in the loading, menu or System Offline contexts, because no producer
publishes a contact there. Pending damage events **drop at gate entry** (TR-HD-027) —
the gate's entry is ADR-0001's **phase 3**, and the drop is the same
`clear_intents_at_entry` shape applied to SYS-07's event ring: the ring is cleared
**at phase 3, in the same phase ADR-0001 clears the intents**, not before phase 0 and
not after the gate has opened.

### 5 · The `StatBlock`, the revision discipline, and identity at default

```gdscript
## The resolver's input, published by SYS-16 and consumed read-only here.
## Identity at default: level 1, no gear -> attack 100, defense 0, hp_max 20,
## energy_max 50, mana_max 30, precision 0, agility 0, damage_bonus 0.
class_name StatBlock extends RefCounted
var level: int
var attack: int
var defense: int          # ALWAYS 0 at MVP: TR-PRG-016 retired the gear lever
var hp_max: int
var energy_max: int
var mana_max: int
var precision: int
var agility: int
var damage_bonus: int
var revision: int         # bumps EXACTLY ONCE per point spend or equipment change
```

**The schema split.** SYS-07 owns the schema, the resolver and the identity law;
SYS-16 owns the full sheet, levels 6–20 and the gear aggregation (TR-HD-006). The
split exists to prevent a SYS-07 ↔ SYS-16 cycle: SYS-16 publishes `StatRevision`
(SYS-07's TR-HD-035 read contract) and SYS-07 consumes it. SYS-16 is the **sole
writer** of the stat values; SYS-07 is the **sole writer** of the pool they bound
(TR-PRG-009: "`HealthCore` is the pool's only writer").

**The revision discipline.** `revision` bumps **exactly once** per point spend or
equipment change; there is **no per-tick recompute** (AC-HD-06 asserts a recompute
spy counts 1 over a spend and 0 over 600 ticks). The reducer's `apply_stat_revision`
is the only consumer, and it **guards on the revision itself**: a revision whose
`rev.revision <= current.revision` is a **no-op with one telemetry record** — without
that guard a re-published revision would apply the `hp_max` delta a second time and
double-heal a point, which is the one way the asymmetry below can be turned into a
bug. The guard is also what makes the reducer idempotent against a duplicate
publication, the same discipline the damage ledger enforces on events.

The **gear-delta asymmetry** is the same entry point's second law — rider (e),
decided by TR-PRG-009:

```
delta = new.hp_max - old.hp_max
if delta < 0:                      hp_current = min(hp_current, new.hp_max)   # a shrink clamps
elif source == POINT:              hp_current = min(hp_current + delta, new.hp_max)  # a point heals
else:                              hp_current = min(hp_current, new.hp_max)   # a module does NOT heal
```

The asymmetry is the design's: **a point is growth, a module is equipment.** The
unequip fixture (6/22 → 6/20) is the shrink clause; the point fixture (+2 max heals
+2) is the growth clause; a frame's +2 at 6/20 leaves 6/22 (no heal). All three are
AC-PRG-09's, and this ADR implements the mechanism that makes them true.

**Identity at default is a boot assertion, not a comment.** `validate_config()` runs
at boot and **fails closed** on: the eight approved numbers not reproducing at level
1/no gear; the ladder's four V-HD-12 checks (monotone columns, a strictly increasing
derived chain, row-0 equality with the four raw knobs, row 4's chain ≤ 10); **the
tier ladder's monotonicity over the registered profiles' `hp_max`
(`T1 < T2 < T3 < boss`, V-HD-06)**; **the strike ladder's monotonicity
(`P1 < P2 < P3`, V-HD-07 — a violation raises `P2`/`P3` and never lowers the fixed
`P1`, which is the invariant's own resolution)**; a `DEF_CAP_PCT` outside its own safe
range (`0–25` at MVP, `0–40` VS); a `DAMAGE_EVENT_MAX_AGE_TICKS` outside `0–2`
(**`clampi` to 2, V-HD-10's resolution** — a clamp, not a rejection, because a stale
hit is a ghost and the tighter bound is always the safe one); a `hp_floor ≥ hp_max` in
any registered profile; a non-integer anywhere. **The
assertion is about the config, not about an entity's `defense`**: a per-entity
`defense` outside `[0, DEF_CAP_PCT]` is a **runtime clamp** (`clampi`, V-HD-13's own
resolution), never a boot failure — the two are different surfaces and this ADR does
not make the clamp a boot check. AC-HD-05's "the reworked Combat fixtures pass
unmodified" is the same assertion from the other side. **A config that cannot be a
fixpoint is a dev boot failure; production keeps the last good config** (V-HD's law).

### 6 · The ladder: one table, one transaction, four checks

`DAMAGE_LADDER_MVP` is a **5×4 integer table** (`step` 0–4 × `ATK1/ATK2/CROUCH/AIR`),
injected into the resolver as a value — no global state, no singleton read
(TR-HD-037):

| step (`attack`) | ATK1 | ATK2 | crouch | air | chain (derived) |
|---:|---:|---:|---:|---:|---:|
| 0 (100) | 2 | 4 | 2 | 2 | 6 |
| 1 (108) | 3 | 4 | 2 | 3 | 7 |
| 2 (116) | 3 | 5 | 3 | 3 | 8 |
| 3 (124) | 4 | 5 | 3 | 3 | 9 |
| 4 (132) | 4 | 6 | 3 | 4 | 10 |

**Row 0 is not free data.** It must equal the four raw weapon knobs
(`ATK1_DAMAGE` 2, `ATK2_DAMAGE` 4, `CROUCH_ATTACK_DAMAGE` 2, `AIR_ATTACK_DAMAGE` 2 —
registered in `entities.yaml` by the D-ORCH-03 sync), and a disagreement is a boot
failure. That equality is what keeps the printed ladder honest against Combat's
provisional values while both are alive.

**§6a · The two-field transaction.** A live edit to a raw knob is **one transaction
with its row-0 cell**: the knob and `DAMAGE_LADDER_MVP[0][arc]` change together and
validate as one, so a legal pair (`ATK1_DAMAGE` 2 → 1 with row 0's ATK1 2 → 1) is
accepted and an illegal pair is still rejected. A single-field change that breaks
row-0 equality is **rejected with the last good config kept**. The API is one call —
`apply_config_transaction(edits: Array[ConfigEdit]) -> ConfigVerdict` — never two
writes in sequence, because two writes have an intermediate state and the
intermediate state is exactly what row-0 equality forbids.

**§6b · The live-edit resolution split.** The generic V-HD law is "clamp + rate-limited
telemetry"; V-HD-12 names its own exceptions and they are not the generic law:

| Case | Resolution |
|---|---|
| row-0 equality broken | **reject**, keep the last good config |
| row 4's chain > 10 | **reject** |
| a non-monotone `ATK1` / `crouch` / `air` column | **reject** |
| a non-monotone `ATK2` column, or a non-strictly-increasing chain | **accept clamped**: the offending row's `ATK2` rises by one, all four checks re-run, a residual violation rejects |

The clamp loop terminates by construction: at most four rows, one increment each, and
a residual violation is a rejection rather than another pass. The clamp is **upward
only** — the ladder's promise is that growth never loses a step.

### 7 · The RNG port

```gdscript
## The resolver's only randomness. Stateless by contract: the same key always
## yields the same roll, in any branch order, on any platform.
class_name RngPort extends RefCounted

## Called ONCE by the reducer at the top of damage_phase. It binds the phase's
## LOGIC tick into the port, so the resolver never needs a clock (§7a).
func bind_phase(logic_tick: int) -> void

## The roll for one event. TR-HD-037's key is
## (logic_tick, attacker_id, defender_id, contact_tick): the tick comes from
## bind_phase, the other three are the event's own.
func roll(attacker_id: int, defender_id: int, contact_tick: int) -> float   # [0,1)
```

**§7a · How the tick reaches a clock-free resolver.** TR-HD-037's key includes
`logic_tick`, and the resolver is deliberately clock-free (`AttackContext` carries
`contact_tick`, not `now_tick`). Rather than widen a frozen schema, the tick enters
through the **port's per-phase binding**: the reducer calls `bind_phase(logic_tick)`
once at the top of `damage_phase`, and every `roll()` in that phase composes the
four-part key with the bound tick. For a same-tick event the bound tick **is** the
`contact_tick`; for a late event (the 1–2-tick window §4a exists for) they differ,
and the key uses the **bound** tick — the tick the roll is taken on, which is the
only value that makes two replays of the same event stream agree. This is why the
resolver needs no change at the VS handoff: the key's fourth part is the port's
business, and the resolver's signature is already correct.

- **`FixedRngPort`** returns the **median roll, 0.5**, for every key — the fixture
  port. It makes a trace bit-identical and it is what AC-HD-39's replay uses.
- **At MVP the port is never called.** Crit is VS; the resolver asserts a **call
  count of 0** over the MVP fixture set (AC-HD-39: "the MVP run performs zero
  rolls"). A non-zero count at MVP is a defect, not a rounding difference. **The VS
  mixer is nevertheless implemented and unit-tested at MVP** — inert, not absent — so
  AC-HD-39's VS clause ("two different hash keys yield different rolls but identical
  timing") is a real, runnable assertion in the MVP smoke suite rather than a
  deferred one. The crit's *consumption* is what is VS-gated; the mixer's *contract*
  is not.
- **At VS the roll is a stateless counter hash** over
  `(logic_tick, attacker_id, defender_id, contact_tick)` — **no `swing_seq`, no
  mutable RNG state** — so a trace is bit-identical regardless of branch path and two
  different keys yield different rolls with identical timing. The hash is an
  **explicit 64-bit integer mixer implemented in the project**, not `hash()` and not
  `String.hash()`: the engine's hashing is not a documented cross-platform contract,
  and a roll that changes between platforms would make a replay test lie. The mixer's
  output is reduced to `[0,1)` by taking the top 53 bits over `2^53` (the exact-float
  region), and the mixer's shifts use **unsigned** masks — GDScript's `>>` on a
  negative int is arithmetic, so a sign-extended shift would fold every negative mix
  toward `-1` **[register item 5]**.

### 8 · The pool's one writer: the state machine, the latch, the ledger

`HealthCore` owns the only writable HP (TR-HD-010) and the only legal transitions:

| State | Enter | Exit | Damage |
|---|---|---|---|
| `ALIVE` | boot; reconstruct complete; revive | HP → 0 (the edge) | applied |
| `DEAD` | the death edge | the player chooses reconstruct / revive / quit | rejected |
| `RECONSTRUCTING` | the reconstruct choice | `load_complete` | rejected |
| `QUIT` | the quit choice | session end | — |

**The latch (R5).** `edge = (hp_before > 0) ∧ (hp_after = 0) ∧ (state = ALIVE) ∧
(hp_floor = 0 ∨ released)`. On true: `state ← DEAD`, `death_tick ← now_tick`,
publish once. Three lethal events in one tick → one edge; every later event sees
`DEAD` and is rejected with telemetry; the latch clears **only** on reconstruct or
revive. There is no 0-HP `ALIVE` state and no timer that can produce an edge.

**§8b · The two writers the predicate needs, and where they live.** F-HD-05's
`released` and TR-HD-025's revive grant are both **reducer state**, not port reads —
the port only *reads* invulnerability, and a window SYS-07 itself wrote cannot come
back through it:

```gdscript
## SYS-14's scripted phase release. The ONLY writer of `released`, and it is
## per-entity reducer state; a second call is a no-op (idempotent by construction).
func release_hp_floor(target_id: int) -> void

## TR-HD-025's grant. Draws the module in DEAD, sets hp = ceil(hp_max * 50%),
## consumes it, and opens SYS-07's OWN window `[t, t + 60)` on the same entity.
func draw_restore_module() -> bool
```

**The lock is a disjunction, and that is the second lock's whole point.** TR-HD-018's
`invulnerable(target, contact_tick)` is evaluated as
`port.invulnerable(id, tick) or self._own_iframes_active(id, tick)` — the published
windows (Combat's backdash/getup grants, an enemy's profile windows) **or** SYS-07's
own revive window. A Combat bug cannot leak damage through the first half; a
mis-published grant cannot leak it through the second. `FakeHealthPort` therefore
carries only the *published* windows, and the revive's 60 ticks are asserted against
the reducer's own state — which is exactly what AC-HD-27's "60 ticks of
invulnerability" needs.

**The enemy's mirrored latch and `DefeatEvent` (TR-HD-009).** The same latch runs per
entity: an enemy's HP reaching 0 publishes **one** `DefeatEvent {target, soul_class,
killer_id, contact_tick}` from the same edge, and a second lethal event in the same
tick publishes nothing (the entity is already `DEAD`). `soul_class` is SYS-13's tag on
the profile; the mana payoff is VS and consumed by SYS-12/SYS-18/SYS-27, not here. A
deflected orb that kills an enemy publishes with the orb's `source` as `killer_id` —
friendly fire is real (TR-HD-019).

**The heal API (TR-HD-029/030/031), stated once.** `heal(amount, source)` clamps to
`hp_max`; a heal at full HP is a **no-op that consumes nothing**; a heal on a `DEAD`
target is refused with its charge preserved (§4b); overheal is discarded but the
charge is consumed **on a legal use**, at the **commit tick** — the charge is spent on
the commit, not on the press, and a committed use is not interruptible between commit
and application (same tick). A pickup adds **+1 charge** through the same entry
(`add_charge()`), is **refused at `QUICK_SLOT_MAX`** with the item left on the ground,
and never auto-applies — the Interact bubble is SYS-01's and the item is SYS-17's.
`CACHE_REFILL` and the revive's `ceil(hp_max × 50%)` are the two other writers, and
both are F-HD-06's.

**The off-switch's injection path.** TR-HD-036's damage-number off-switch is a
**readability/a11y setting**, and it is injected into the reducer at construction as a
`bool` (`number_publish_enabled`), updated from the setting's change signal — **not** a
sixth port. The reducer is the only place that reads it, and §10 says what it does.

**The ledger (idempotence).** The key is the six-tuple `(source, target, raw_damage,
kind, arc, contact_tick)`; a bounded ring of **256**. The 2-tick age bound is what
bounds the live key window — only a few ticks of keys are ever live — so 256 is
generous by two orders of magnitude and the ring's overwrite-oldest behaviour is
unreachable in a legal run. A duplicate is **rejected with telemetry**, never applied
twice; a same-tick pair differing only in `arc` both apply (AC-HD-18's synthetic
fixture proves the element is real schema, not padding).

**The gates.** The 11-term predicate is one function with a **named first-failing
term** (F-HD-15), evaluated in the GDD's order, and a failed term rejects the whole
event — no partial application. Two things are **not** gates and the code must not
grow them: the per-event cap and the HP floor are clamps in the apply stage
(TR-HD-017 term 10's parenthetical says so explicitly), and the floor's *release* is
an edge condition (F-HD-05), not a gate term.

**The strikes table.** `enemy_strike_damage(power)` — 1/2/4 — is SYS-07's knob and
Combat's cross-system input at registration (TR-HD-003). A missing table is a dev
boot failure, never a silent default; a live edit re-stamps on the next contact.

**The `ENVIRONMENT` path.** `kind = ENVIRONMENT ⟺ source = ENV` (entity id 0); the
source-domain law rejects both mismatches and `target = ENV`. The path bypasses the
i-frame lock **and** the defense mitigation (a void is not an attack) and still goes
through the edge and the `DeathRecord`. A pit event stamps `raw_damage = hp_max`, so
`applied = min(hp_max, cap)`; the player profile's cap is **0 = uncapped** (§8a).

**§8a · The profile's two sentinels.** `damage_cap_per_event = 0` means **no cap**
(the resolver skips the clamp) and `hp_floor = 0` means **no floor** — both are
SYS-14 hooks that a boss values and every other entity leaves at 0. The GDD's
F-HD-05 already reads `hp_floor = 0 ∨ released`, so the floor sentinel is the GDD's
own; the cap's is this ADR's encoding, chosen because a cap of 0 is otherwise
indistinguishable from "no damage ever" and the `ENVIRONMENT` path needs an uncapped
player.

### 9 · The two load regimes and the persistence boundary

SYS-07 has **two** paths into `ALIVE` from outside, and they are not the same path
with a different name:

| | **Regime 1 — the session load** | **Regime 2 — the in-session reconstruct** |
|---|---|---|
| Trigger | a save load (SYS-05's context) | the player's reconstruct choice on the System Offline screen |
| Path | `restore_complete` (SYS-03/ADR-0002) → `load_complete` (SYS-05) → `ALIVE` | `DEAD` → `RECONSTRUCTING` → `load_complete` → `ALIVE` |
| HP | `hp_max` — **no HP field is read** (TR-HD-032) | `hp_max` (F-HD-08) |
| Quick slot | `CACHE_REFILL` (3) | `CACHE_REFILL` (3) |
| **Restore modules** | **0** — no module is carried into a load (§9b) | the drawn module is consumed; the count is otherwise unchanged |
| Ledger / latch | ∅ / clear | ∅ / clear |
| `hp_floor` | the profile's base | **reset to the profile's base** (F-HD-08's list) |
| Progression source | the **save** (`progression` namespace, SYS-16's carry) | the **live carry** — a level earned after the last save is never rolled back (TR-CSD-013's no-XP-loss law, the read-gated window) |
| i-frames | **none at MVP** — the cache is a safe context; an in-place respawn would need a grant (VS, SYS-07 OQ#16) | the revive's 1000 ms window is the only grant |

Both consume ADR-0002's ordering where a save is involved — **regime 1 strictly**
(`restore_complete` then `load_complete`); regime 2 is an in-session gate/load with no
`restore_complete` at all, so it consumes only `load_complete`. **ADR-0002's acceptance
therefore precedes any story that implements regime 1**, and this ADR declares the
dependency rather than assuming it. Both end at a full pool. **Neither reads an HP
field**, because none exists: the body is reconstructed from the station's law, not
restored from a file. Regime 1's `quick_charges = CACHE_REFILL` is TR-HD-032's
"reconstructs at the station" read together with TR-CSD-007's activation restore — the
load applies the cache restore's values, which is why the slot is full without a
stored charge count.

**§9b · The body's persistence, quoted rather than paraphrased.** SYS-15's TR-CSD-013
body clause reads, verbatim: "**the body** (store-absent: SYS-16/17's session-only
namespaces) restores from **the live session** (the load never touches it — there is
no file carrying it): it survives death outright, within the session." **The clause's
parenthetical is already superseded for `progression`**: SYS-16's rider (b) — carried
here as **O-HD-5** — makes the body store-carried for `progression` at v3,
live-carried by the same read-gated window; what stays store-absent is exactly the
part no namespace carries (the pools, the charges, the modules, the ledger, the
latch). Three things follow, and the ADR states them rather than letting a reader
infer them:

1. **At MVP there is no file carrying the body** — no namespace exists for
   `hp_current`, `quick_charges`, `restore_modules`, the ledger or the latch. A load
   therefore starts with `restore_modules = 0` and `quick_charges = CACHE_REFILL`,
   and the module's faucet is re-evaluated per station **activation** (TR-CSD-017),
   not restored: the station the player loads at is already in `activated_caches`, so
   it grants nothing, and the next *new* station grants one.
2. **SYS-07's own save field list is therefore an unmet obligation, not a law this
   ADR can implement.** `design/gdd/health-damage.md`'s Interactions/Save row names
   "(level, training data/points, stat sources, **charges, modules, quickslot**)" and
   its Dependencies row names SYS-03 as hard at save time — but SYS-03 lists SYS-07
   as an explicit runtime non-dependency and registers no such namespace. Only the
   level/training-data/points half is actually persisted (SYS-16's `progression`).
   → **O-HD-9**, with the two candidate resolutions named there.
3. **The consequence is a design consequence, not a bug**: a save→quit→load loses a
   carried module. That is the landed MVP behaviour of TR-CSD-013 + TR-CSD-017, and
   this ADR does not paper over it by inventing a namespace — a new namespace is
   SYS-03's + SYS-16's decision and a schema bump, not an ADR's.

**§9c · The pools (TR-HD-008), which the reducer does own.** The pools are **inert**
at MVP, not absent: `HealthCore` holds `energy`/`mana` as reducer state, ticks them on
`logic_tick`, and publishes nothing.

```
energy_max = ENERGY_BASE + ENERGY_PER_LEVEL * (level - 1)      # 50 at L1, 90 at L5
mana_max   = MANA_BASE   + MANA_PER_LEVEL   * (level - 1)      # 30 at L1, 50 at L5
# ENERGY_REGEN_PER_S = 5; the integer accumulator makes 60 logic ticks == +5 exactly
regen_acc += ENERGY_REGEN_PER_S
while regen_acc >= TPS:  energy = mini(energy + 1, energy_max); regen_acc -= TPS
```

- **The regen runs on `logic_tick`**, so a freeze holds it by construction (the clock
  does not advance) — AC-HD-08's "a 30-tick freeze holds it" is the clock law, not a
  special case.
- **The efficiency term** (`max(70, 100 − 2×(L−1))%`) is carried as a stored value and
  has **no consumer at MVP**; it is written only by the level seam.
- **No publication.** `HealthRead` deliberately omits both pools (TR-HD-008's "the HUD
  read contains no energy/mana field at MVP"); the GUT half reads them through a
  **test-only accessor** (`pool_state()`, not a publication), which is what makes
  AC-HD-08's two regen fixtures runnable without adding a HUD field.
- **Mana has regen 0** and no consumer; it is initialised at `mana_max` and never
  moves at MVP.
- **"Saved at defaults"** is O-HD-7's: no namespace carries either pool, so a load
  starts at the max — which *is* the default, and is why the clause is currently
  unsatisfiable rather than violated.

**§9d · The `DeathRecord` archive (TR-HD-024/025).** Both reset paths say "archives
the `DeathRecord`", and F-HD-08's list does not contain it — so the ADR names the
home rather than leaving each implementer to invent one. The archive is **reducer
state**: a bounded ring of **8** `DeathRecord`s (`DEATH_ARCHIVE_DEPTH`), appended by
the **edge** (the same write that publishes it), and **surviving both resets** — that
is what "archive" means and it is why the reset clears the latch and the ledger but
not this ring. `read_death_archive()` is the read; SYS-15's cause row and counter and
SYS-29's sting are its consumers. The ring's depth is bounded because a life's deaths
are bounded and the ring is a diagnostic, not a ledger — the designation *counter* is
SYS-15's and is not derived from this ring.

**§9e · The options contract's split (TR-HD-023, the registry's reading).** The
active registry entry `system_offline_contract` registers **SYS-15** as the publisher
of the three rows (SYSTEM OFFLINE / *you are destroyed* / the cause row) and the three
options **verbatim**, with **SYS-07 as a verbatim consumer** — added 2026-11-15 at
SYS-15's authoring. SYS-07's GDD says "SYS-07 publishes the options contract". The
ADR takes the **registered** split, which is the later landed contract, and records
the divergence as **O-HD-11**: SYS-15 publishes the rows and the three option
surfaces; **SYS-07 publishes the availability predicate** it alone can know —
`DeathOptions {revive_available: bool}` (the module is carried), which is what
"greys, never hides" needs, and the `DeathRecord` that fills the cause row. Nothing
is rendered here and nothing duplicates a registered publisher.

**The persistence boundary, stated once.** What persists and what does not is a
landed-contract fact, not a choice this ADR makes:

- **Persists** — `level`, `training_data`, `atk_points`, `hp_points`, `grants`,
  `owned`, `equipped`: SYS-16's `progression` namespace (v2→v3), SYS-16 the sole
  writer, snapshotting SYS-07's `level`/`training_data` at the save request.
- **Derived, never stored** — `banked_points` from SYS-07's `training_points`
  (SYS-16's namespace note); `active_cache` from `activated_caches`.
- **Never persists at MVP** — `hp_current`, `quick_charges`, `restore_modules`, the
  idempotence ledger, the death latch, the revive window: live session state, because
  no namespace carries them (§9b).
- **The gap this ADR records rather than fills** — `energy`/`mana` have **no**
  registered namespace either, while AC-HD-08 asserts "the save round-trips both".
  Both pools are inert at MVP (TR-HD-008: no consumer, no HUD field), so the clause is
  currently unsatisfiable rather than violated. → **O-HD-7**.

### 10 · The damage-number ring and the label lease

TR-HD-036 and TR-HD-038 say the number is **pooled (32)** with a 700 ms lifetime and
a zero-frame publication; the Interactions table says SYS-24/SYS-29 own "rendering,
the pool, the off-switch". Both are true once the boundary is drawn at the record:

- **SYS-07 owns the record ring.** 32 preallocated `DamageNumber` records
  `{target_id, amount, kind, contact_tick, world_pos, crit, is_heal}`; a publish
  writes the next slot and advances a head — **overwrite-oldest, never allocate**.
  A full ring in a swarm drops the oldest number, which is the honest behaviour (the
  newest hit is the one the player needs) and is what makes the ring's bound a *law*
  rather than a hope. The drop is **observable without a new telemetry record**: the
  ring exposes its `head` and `occupancy`, so a fixture asserts 32/32 with the head
  wrapped — a dropped number is a diagnostic of the ring, not a gate rejection, and
  the GDD's telemetry set gains nothing here.
- **`amount` is `applied`, always.** The record's amount is the **value the
  subtraction actually did** — `DamageResult.applied` (post-cap), and for a heal the
  applied portion (`min(amount, hp_max − hp_current)`, F-HD-06) — never `dealt` and
  never the requested amount. A boss's 6-into-cap-2 publishes **2**, and a Suture at
  18/20 publishes **2**, so the number and the bar can never disagree. That is the one
  lie the fantasy's first term forbids ("every number is earned and shown"), and §3b
  makes `dealt` and `applied` deliberately distinct, so the record has to say which.
  `capped` stays in `DamageResult` for telemetry only.
- **SYS-07 owns the zero-frame law.** The record is written **on the contact tick**,
  in the same damage phase that applies it — zero frames relative to the hit-stop
  onset, because the onset is next tick's phase 0 (§4).
- **SYS-24/SYS-29 own the label nodes.** The ring's slot index is the **lease token**:
  the render side keeps a 32-entry slot→node map and shows the node whose slot was
  last written, so it never allocates, never searches, and never needs the record's
  identity to survive a frame. **A re-lease resets the node's state**: the overwrite
  of a slot is a fresh number, so the node's lifetime counter and its rise animation
  restart from zero — otherwise a 33rd hit in one tick would make a dying number
  teleport and re-age mid-fade, which reads as a second hit that never happened. The
  700 ms lifetime is measured on the **freeze-holding clock** (`logic_tick`,
  `ceil(DAMAGE_NUMBER_LIFETIME_MS × tps ÷ 1000)` ticks) — a number must not outlive
  its own hit-stop's clock law.
- **The off-switch suppresses publication**, not rendering: with the switch off the
  ring stays empty (AC-HD-38's "the off-switch hides all numbers" becomes a ring
  occupancy of 0, which is falsifiable headless), and no telemetry record is emitted
  for a suppressed number.
- **The render side's text is not SYS-07's**, but the churn bar is: a `Label.text`
  assignment allocates a `String`, and `str(amount)` allocates one per hit. Because
  the legal amounts are a **small bounded integer set**, the render side builds its
  strings once at boot (a value→string table) and assigns from it. That is an
  implementation note for SYS-24's story, recorded here because AC-HD-40's churn bar
  is the assertion that fails without it.

**The palette is a law, not a style.** Enemy damage amber, player damage taken pale
bone, heal cyan, crit gold (VS), **never sigil-red** (reserved for the demon lord),
no word "CRITICAL". AC-HD-38's palette audit greps for red; the law lives here so a
render story cannot re-open it.

### 11 · Test seams

```gdscript
# ---- the pure resolver -------------------------------------------------------
class_name DamageResolver extends RefCounted

## The six stages, once each. Pure: no port, no clock, no publication.
static func resolve(ctx: AttackContext, snap: DefenderSnapshot,
                    rng: RngPort, ladder: DamageLadder) -> DamageResult

# ---- the stateful reducer ----------------------------------------------------
class_name HealthCore extends RefCounted

func damage_phase(t: int, events: Array[DamageEvent]) -> void   # §4's entry point
func heal_phase(t: int) -> void                                 # strictly after damage
func heal(amount: int, source: StringName) -> int               # 0 = refused
func add_charge() -> bool                                       # the pickup; false = full
func apply_stat_revision(rev: StatRevision, source: StatDeltaSource) -> void
func release_hp_floor(target_id: int) -> void                    # SYS-14's phase release (§8b)
func draw_restore_module() -> bool                              # DEAD only; opens SYS-07's window
func reconstruct_complete() -> void
func read() -> HealthRead
func read_death_archive() -> Array[DeathRecord]                 # §9d; survives both resets
func pool_state() -> Vector2i                                   # TEST-ONLY (§9c); never published
func options() -> DeathOptions                                  # §9e; revive_available

# ---- the ports (the only doors) ---------------------------------------------
class_name HealthPort extends RefCounted
func profile(id: int) -> HealthProfile
func invulnerable(id: int, tick: int) -> bool     # the PUBLISHED windows only (§8b)
func now_tick() -> int                            # LOGIC_TICK (§4a) — never physics
func anchor(id: int) -> Vector2
func publish(event: HealthEvent) -> void

class_name RngPort extends RefCounted
func bind_phase(logic_tick: int) -> void          # once per damage_phase (§7a)
func roll(attacker_id: int, defender_id: int, contact_tick: int) -> float   # [0,1)

# ---- the fakes the GDD names ------------------------------------------------
# FakeHealthPort  — a fixture table for profile/invulnerable/anchor/publish;
#                   it carries the PUBLISHED windows only, never SYS-07's own
# FixedRngPort    — 0.5 for every key, and a call counter the MVP asserts is 0

# ---- the result records (stable API; never display text) --------------------
# DamageResult {dealt, applied, overkill, crit, capped}
# HealthRead   {hp_current, hp_max, hp_ratio, state, low_hp, level, training_data,
#               training_points, quick_charges, quick_item, restore_modules,
#               last_damage_tick, invulnerable}
# DeathEdge + DeathRecord {cause_source, cause_kind, contact_tick, raw_damage,
#               overkill, hp_before, hp_max, level}
# HealEdge {target, amount, source, tick} · DefeatEvent {target, soul_class,
#               killer_id, contact_tick} · StatRevision
```

### 12 · The engine verification register

Every `PROBE-PENDING` row carries a **Method** (a runnable protocol with a pass/fail)
and an **Owner**, so a probe can be closed or failed rather than narrated.

| # | Item | Verdict | Method (pass = ) | Owner | Blocks |
|---|---|---|---|---|---|
| 1 | GDScript's `/` on two ints yields an int and **truncates toward zero** (not floor) | **DOCUMENTED** (language reference) | — | — | — |
| 2 | `floori(float)` exists and floors correctly, including `floori(-0.5) = -1` | **DOCUMENTED** (language reference) | — | — | — |
| 3 | The **four port calls per event** (`profile`, `invulnerable`, `anchor`, `publish`, all on `HealthPort`) stay inside the damage phase's 0.25 ms p99.9 / 0.75 ms max allocation | **PROBE-PENDING** | the W13 workload (2,000 events, 100 death→reconstruct cycles, 200 heals, 500 i-frame rejections, 500 duplicates, 50 boss events) on the reference SKU: nearest-rank p99.9 ≤ 0.25 ms, max ≤ 0.75 ms. **A miss is a design finding, not a rounding difference**: the fallback is a per-phase port cache (the port reference read once per `damage_phase`) | performance-analyst | The first story; AC-HD-41 |
| 4 | A preallocated typed `Array` of `RefCounted` records + an overwrite-oldest head performs **zero allocation** across 10,000 ticks | **PROBE-PENDING** | the soak with `Performance.MONITOR_OBJECT_COUNT`/`MEMORY_STATIC` sampled at the warm-up and at the end: net object delta 0, net resource delta 0, heap growth ≤ 256 KB, churn ≤ 16 KB / 1,000 ticks | lead-programmer | The first story; AC-HD-40 |
| 5 | An explicit 64-bit integer mixer gives a **platform-stable, stateless** roll, with unsigned shifts, **keyed through `bind_phase`** | **PROBE-PENDING** | the same `(bound logic_tick, attacker_id, defender_id, contact_tick)` key yields the identical 64-bit value on iOS, Android and desktop builds of the same revision, 10,000 keys per platform, zero mismatches; the roll lands in `[0,1)` with no value at 1.0; **a negative intermediate must not fold toward −1** (the unsigned-mask fixture); **and a late event's key uses the bound tick, not its `contact_tick`** (the two differ by 1–2 ticks, and the roll must not change with the event's lateness) | godot-gdscript-specialist | The VS crit; AC-HD-39's two-key fixture |
| 6 | `HealthCore.damage_phase()` can assert "the freeze onset has not been applied for `t`" from the publication SYS-29 actually offers | **PROBE-PENDING** | in a scene where a hit-stop is requested in `T`, the damage phase for `T` observes the onset as *pending*, not *applied*, 100/100 runs; the same assertion fails if the damage phase is moved after the freeze publication (the negative control) | lead-programmer | §4's dev assert; AC-HD-30 |
| 7 | A `Label` pool of 32 with a slot→node map shows a number on the **contact tick** with no `queue_free` and no instantiation | **PROBE-PENDING** | **the headless half first** (it is what AC-HD-38/40's GUT halves need): a 32-record burst in one tick fills the ring 32/32 with the head wrapped, a 33rd overwrites slot 0, and 10,000 ticks show zero ring growth; **then the render half**: all 32 nodes render on the frame, a re-lease resets the node's lifetime and animation, and no `Label` is instantiated after boot | ui-programmer (SYS-24's story) | AC-HD-38/40; the render side's churn bar |
| 8 | `Node.process_physics_priority` (the documented fallback ordering) exists in 4.7.2 and orders the three gameplay services as §4 names | **PROBE-PENDING** | three probe nodes at priorities `-10/0/+10` log their `_physics_process` order: the log is stable across 1,000 ticks and matches the assigned order. **Only needed if the tick director defers to the scene tree**; the explicit call is the primary | godot-specialist | The fallback ordering only |
| 9 | `ceil`/`floor` on the ms→tick conversion reproduce the GDD's tick fixtures at 60 tps | **PROBE-PENDING** | `ceil(DAMAGE_NUMBER_LIFETIME_MS × tps ÷ 1000)` = 42 ticks at 700 ms/60 tps; `REVIVE_IFRAME_MS` 1000 ms = 60 ticks; `GETUP_IFRAME_MS` 300 ms = 18 ticks; the backdash's 140 ms = **9 protected ticks** (`t…t+8`) with the exposure at `t+9…t+16` (**8 ticks**), matching F-CMB-08's 140/9/8 fixture (protect `4000–4008`, expose `4009–4016`) — the fixture asserts both numbers so the off-by-one is pinned rather than implied | qa-lead | AC-HD-20/38's tick fixtures |

`PROBE-PENDING` is an open verdict, not a pass: no story may consume items 3–9 as
settled fact (the AC-74 pattern from ADR-0001). **Items 1 and 2 are the only language
facts the decision rests on**, and they are why §3a writes the arithmetic form rather
than trusting the operator.

### Implementation guidelines

- **Never** write `hp_current` outside `HealthCore`. A debug setter is a second
  writer; if one is wanted it is a test-only subclass, never a public method.
- **Never** call `a / b` for a GDD `floor`. Use `floori(a / float(b))` and clamp the
  numerator non-negative first (§3a).
- **Never** apply `damage_bonus` outside branch 2. A counter, a deflect, an ability
  and a strike are not weapon arcs.
- **Never** re-apply `COUNTER_CLASH_MULT`. Combat already stamped it.
- **Never** make the cap or the floor a gate term; they are clamps.
- **Never** read `physics_tick` in `now_tick()`. The stamp clock is `logic_tick`.
- **Never** allocate in `damage_phase`, `heal_phase` or `read()`. The rings are
  preallocated; a `Dictionary` per event is the bug AC-HD-40 catches.
- **Never** let a second site publish a `DamageNumber`. One ring, one head.
- The resolver is `static` and takes the ladder as a **value**; the reducer holds the
  state. A resolver that reads a field of the reducer is the split collapsing.
- Every config read goes through `validate_config()`'s output, never a raw constant.

## Alternatives Considered

### Alternative 1: One stateful `HealthSystem` node doing resolver and reducer

- **Description**: a single node with `_physics_process`, the pool, the arithmetic and
  the publications.
- **Pros**: one object; no port plumbing; the fastest thing to write.
- **Cons**: the arithmetic becomes untestable without a scene tree; AC-HD-39's
  bit-identical replay and AC-HD-01's 600-tick trace both need a pure function; a
  node is a second place HP can be written.
- **Estimated Effort**: 0.6× to write, 2× to keep.
- **Rejection Reason**: TR-HD-037 splits the seam itself and names the fakes.

### Alternative 2: A percentage damage curve instead of the printed ladder

- **Description**: `dealt = round(base × attack ÷ 100)` for every arc.
- **Pros**: one formula; trivially monotone; no table to validate.
- **Cons**: the printed ladder is the design's promise — "ATK1 2 / ATK2 4 … exactly"
  — and a percent curve gives 2.16 at ATK 108 where the ladder says 3; the identity
  law (V-HD-12) is stated in **integers**.
- **Estimated Effort**: 0.5×.
- **Rejection Reason**: TR-HD-006 and F-HD-14. The ladder is the sheet's promise; the
  curve is only the **VS** continuation (F-PRG-03) and it is defined *on the ladder's
  top row*, not instead of it.

### Alternative 3: Floating-point damage with display rounding

- **Description**: keep floats internally, round at the label.
- **Pros**: smooth curves; no quantization argument.
- **Cons**: the integer law is a **player-facing** law ("every number is earned and
  shown"); a 2.4 that displays 2 makes the bar and the number disagree; float
  accumulation makes a trace non-reproducible across platforms.
- **Estimated Effort**: 0.7×.
- **Rejection Reason**: TR-HD-004 and the Player Fantasy's honesty clause.

### Alternative 4: The engine's global RNG (`randf` / `RandomNumberGenerator`)

- **Description**: use the engine's RNG for the crit roll.
- **Pros**: no mixer to write; statistically fine.
- **Cons**: stateful — the roll depends on how many calls preceded it, so a trace
  replay diverges the moment a branch differs; a seeded generator is still an
  ordering dependency.
- **Estimated Effort**: 0.2×.
- **Rejection Reason**: TR-HD-037's stateless counter hash; AC-HD-39's replay.

### Alternative 5: Signals for the damage path (`area_entered` → apply)

- **Description**: Combat emits a signal per contact; the reducer connects and applies.
- **Pros**: decoupled; idiomatic Godot.
- **Cons**: delivery order is not the GDD's `(contact_tick, source_id,
  publication_index)`; a signal is asynchronous with respect to the tick, so
  TR-HD-020's total order and TR-HD-028's "applies on the contact tick" both break;
  a connect/disconnect per entity is a lifecycle the soak would catch as churn.
- **Estimated Effort**: 0.8×.
- **Rejection Reason**: the damage phase is a **batch** with a total order (§4b), not
  an event stream.

### Alternative 6: Combat applies the damage (the producer owns the subtraction)

- **Description**: SYS-08 owns HP; SYS-07 becomes a helper.
- **Pros**: one fewer boundary.
- **Cons**: Combat contains no HP field by contract (TR-CMB-025), the death edge and
  the latch would live in a system that does not own the state machine, and the
  i-frame second lock (TR-HD-018) would be inside the system whose bug it exists to
  survive.
- **Estimated Effort**: 1.2×.
- **Rejection Reason**: the resolver/consumer split is the trust contract's shape.

### Alternative 7: `_physics_process` node order instead of an explicit service phase

- **Description**: rely on the scene tree's order (Combat above Health above Juice).
- **Pros**: no director; nothing to wire.
- **Cons**: order becomes a property of the scene file — a reparent, an instancing
  change or an autoload insertion silently reorders damage against contact detection,
  and the failure is intermittent and invisible. The damage phase would also be
  unable to assert "the freeze onset has not been applied".
- **Estimated Effort**: 0.3×.
- **Rejection Reason**: §4. `process_physics_priority` is kept as the **documented
  fallback** (register item 8), not as the primary.

### Alternative 8: A `Label` per damage number, `queue_free` after 700 ms

- **Description**: instantiate on hit, free on expiry.
- **Pros**: dead simple; no pool bookkeeping.
- **Cons**: an allocation and a free per hit in the busiest frame, plus node
  enter/exit churn — exactly AC-HD-40's churn bar, and the swarm case is the one the
  pool exists for.
- **Estimated Effort**: 0.4×.
- **Rejection Reason**: TR-HD-036/038's pool and the soak's zero-net-allocation bar.

### Alternative 9: Persist HP in the save (a "resume where you were" body)

- **Description**: store `hp_current` so a load resumes at the exact pool.
- **Pros**: no surprise refill; a "harder" feel.
- **Cons**: it turns the cache station into a save point rather than a checkpoint,
  contradicts TR-HD-032's "the save stores no HP", and creates a second writer at
  restore — the latch's exactly-once guarantee would have to be re-established from a
  file.
- **Estimated Effort**: 1.5× and a new failure surface.
- **Rejection Reason**: TR-HD-032, TR-CSD-013, and the design's "the cache is the
  checkpoint".

### Alternative 10: Make the cap a gate term

- **Description**: reject an event whose damage exceeds the profile's per-event cap.
- **Pros**: one rule instead of a clamp; a boss "immune" to big hits reads cleanly.
- **Cons**: a rejected over-cap hit deals **zero**, not the cap — phase armor would
  become phase immunity, and TR-HD-017's term 10 parenthetical explicitly says the cap
  and the floor are "clamps executed in F-HD-04, not gates".
- **Estimated Effort**: 0.3×.
- **Rejection Reason**: the GDD states the clamp in two formulas and the gate in none.

## Consequences

### Positive

- The damage law is a pure function, so the GDD's own fixtures (AC-HD-13's ladder
  rows, AC-HD-14's DEF fixtures, AC-HD-23's cap) become headless unit tests with no
  scene tree and no engine.
- One writer for HP makes the latch's exactly-once guarantee a property of a single
  object rather than a convention across four systems.
- Pinning `now_tick()` to `logic_tick` removes a whole class of "the hit didn't
  register" bugs that would otherwise appear only under hit-stop, i.e. exactly when
  the game is most intense.
- The freeze onset being *next* tick's phase 0 means TR-HD-028's order is true **by
  construction** — no node priority, no frame accounting, nothing to re-verify when
  the scene tree changes.
- The ladder's one-function extension (F-PRG-03) means the VS handoff needs no change
  to the resolver: the law's closed form already covers `attack > 132`.

### Negative

- Four port **calls** per event (two ports) on a 0.25 ms p99.9 budget is real overhead; register item 3
  prices it and §12's mitigation (a per-phase port cache) is the fallback.
- The resolver/reducer split costs one extra record (`DamageResult`) per event and one
  call boundary; at a swarm's 32 events/tick this is measurable but bounded.
- The ring's overwrite-oldest behaviour means a 33rd simultaneous number in one tick
  silently drops the oldest — a deliberate, documented loss.
- Two sentinels (`cap = 0`, `floor = 0`) are encodings this ADR invents; a reader who
  assumes "0 means zero damage" gets the wrong answer until they read §8a.

### Neutral

- `docs/architecture/tr-registry.yaml` stays empty until `/architecture-review`
  populates it (ADR-0001/0002 left it empty too).
- SYS-07's numbers are unchanged by this ADR; it decides mechanism only.
- The DEF axis is implemented and unit-tested at 0/5/25 while being constant 0 at
  MVP (O-HD-2): a fixture that no MVP build can exercise is the price of a VS axis
  that must not be retrofitted later.
- The damage-number **nodes** are SYS-24/SYS-29's; this ADR owns the ring and the
  lease contract between them.

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| `now_tick()` bound to `physics_tick` → every event during a hit-stop fails the age bound | Medium | High | §4a's law stated once; the `HealthPort` signature names the clock; AC-HD-30's freeze fixture is the assertion (a scripted `ENVIRONMENT` event during a freeze applies) |
| Integer truncation where the GDD writes `floor` | Medium | Medium | §3a's arithmetic form; register item 1; AC-HD-14's DEF 100 fixture |
| The cap applied and reported at two sites → `dealt` and `applied` equal, `capped` unobservable | Medium | Medium | §3b's single-site law; AC-HD-23's cap fixture |
| A second HP writer appears (a UI clamp, a debug setter, a restore path) | Medium | High | TR-HD-010's static assertion (AC-HD-10); the port is the only door; the reducer is the only writer |
| Port overhead exceeds the 0.25 ms p99.9 allocation | Low | Medium | Register item 3; the per-phase port cache fallback; the four-port surface is small |
| A stateful RNG or the engine's `hash()` used for the VS roll → a replay diverges | Low | High | §7's explicit mixer; register item 5; AC-HD-39's two-key fixture |
| A `Label` per number, or `str()` per hit, blows the churn bar | Medium | Medium | §10's ring + lease + the boot-built string table; AC-HD-40's soak |
| A module's `hp_max` delta heals (the asymmetry inverted) | Low | Medium | §5's three clauses; AC-PRG-09's unequip/point/module fixtures |
| AC-HD-13's DEFLECT fixture read literally → an implementer scales a deflect by `attack` | **Occurred** | Medium | **CR-HD-01** filed (§13); this ADR implements the identity (TR-CMB-015) and the fixture text is the GDD's to fix |
| `defense` assumed to have an MVP source → a dead DEF path or a bogus module | **Occurred** | Medium | **O-HD-2**; §5's `defense` comment states "ALWAYS 0 at MVP"; AC-HD-14 stays green at 0/5/25 |
| The four-system envelope quoted as current (it is seven-system) | **Occurred** | Low | **O-HD-8**; SYS-07's own 0.25/0.75 allocation is unchanged and is what this ADR prices |
| The energy/mana round-trip clause has no namespace | **Occurred** | Low | **O-HD-7**; both pools are inert at MVP so nothing reads them |
| The body's field list (charges/modules) has no namespace and contradicts SYS-15's body row | **Occurred** | Medium | **O-HD-9**; §9b states the landed behaviour and regime 1's `restore_modules = 0` rather than leaving it undefined |
| A display amount sourced from `dealt` makes the number and the bar disagree on a capped hit | **Occurred** (raised by two seats) | High | §10's "`amount` is `applied`, always" — the one lie the fantasy's first term forbids |

## Performance Implications

| Metric | Before | Expected After | Budget |
|---|---|---|---|
| CPU — damage phase | N/A (no code) | the resolver's six stages + the gate, per event; the rings preallocated | **p99.9 ≤ 0.25 ms / max ≤ 0.75 ms** (SYS-07's allocation in the seven-system envelope) |
| CPU — heal phase | N/A | one clamp and one publication per use | inside the same allocation |
| Memory | N/A | entity table 64 · event ring 32 · ledger 256 · number ring 32 · telemetry ring 600 · death archive 8 · one `HealthRead`/`StatRevision` | ~150 MB process ceiling; SYS-07 is not a memory consumer |
| Allocation | N/A | **zero net** over a 10,000-tick soak (600-tick warm-up, counters reset); heap growth ≤ 256 KB; churn ≤ 16 KB / 1,000 ticks | AC-HD-40's bars |
| Load time | N/A | no health field is read; the reconstruct is a reset, not a restore | negligible |
| Network | N/A | None (single-player) | N/A |

SYS-07 **does** join the gameplay-tick envelope — unlike SYS-03's snapshot, the damage
phase is on the critical path of every hit — and its share is the 0.25/0.75 row of the
seven-system composition (2.45/6.55). The device gate is AC-HD-41's W13 workload
(2,000 damage events, 100 death→reconstruct cycles, 200 heals, 500 i-frame
rejections, 500 duplicates, 50 boss-floor/cap events) at the reference SKU.

## Migration Plan

No existing game code exists; the migration is a greenfield scaffold.

1. **The pure core.** Add `src/health/core/` (`DamageResolver`, `HealthCore`,
   `DamageLadder`, `HealthProfile`, `RefusalReasons`, `TelemetryRing`) and the GUT
   suite under `tests/unit/health/` with `FakeHealthPort`/`FixedRngPort`. No node, no
   `Input`, no `Label`.
2. **The config and the boot assertion.** `validate_config()` with the four V-HD-12
   checks, the identity-at-default assertion and the two-field transaction
   (`apply_config_transaction`); wire it to the boot's fail-closed path.
3. **The adapters.** `HealthNode` (the `HealthCore` host), the publication ring, the
   `HealthPort` implementation over the entity table, and the tick director's
   **damage-phase call position** (§4). Assert the freeze-onset precondition.
4. **The seams.** `StatRevision` from SYS-16; the chip's pull from SYS-01's phase 4;
   the death edge's non-ack gate request through ADR-0001 §6; `restore_complete`/
   `load_complete` from SYS-03/SYS-05.
5. **The publications.** `HealthRead` (SYS-24's bar), `DamageNumber` (the ring and the
   lease, SYS-24/SYS-29), `DeathEdge`+`DeathRecord` (SYS-15/SYS-29), `HealEdge`,
   `DefeatEvent` (SYS-12/SYS-18/SYS-27), `StatRevision`.
6. **The probes.** Close register items 1–9 in-engine; the soak; the device gate.

**Rollback plan.** Delete `src/health/` and the tick director's damage-phase call. No
persisted state depends on it (HP is never stored), so no save data needs migrating.
The GDD and this ADR remain; a superseding ADR would replace the resolver, not the
laws.

## Validation Criteria

**Two gates, two lists.** The **decision-conformance** list (20 criteria) states what
this decision must be able to prove; several are verified by fixtures that land with
the implementation (`src/health/` does not exist yet), so they are the criteria the
*decision* fixes. The **story gate** (3 criteria) closes at the first implementation
story. A criterion that cites a GDD AC states **which clause** of that AC it rests
on, because three of them are qualified below (CR-HD-01, O-HD-2, O-HD-7).

**Decision conformance (what the decision must be able to prove).**

- [ ] **One pure resolver, one stateful reducer.** The resolver takes
      `(AttackContext, DefenderSnapshot, RngPort, DamageLadder)` — the three records
      with §2a's field lists — and reads no port, no clock and no `StatBlock`; the
      reducer is the only writer of HP (AC-HD-10's static assertion; AC-HD-39's
      replay).
- [ ] **The six stages run once each, in order, on every branch**; the module stage is
      branch 2 only and identity at `damage_bonus = 0`; the counter never crits; a
      crit is asserted only on `kind = NORMAL` (AC-HD-13 — **except its `DEFLECT`
      fixture's value, which CR-HD-01 corrects to raw 2 → 2 at 132**).
- [ ] **The arithmetic form is explicit at every site**: `floori` where the GDD writes
      floor, `ceili` where it writes ceil, never bare `a / b`; the counter returns
      3/4/4/4/4 and 6/7/7/8/8 (F-HD-11) and the ladder's index is exact at all five
      steps (AC-HD-13/14; register items 1–2).
- [ ] **The damage phase runs after Combat's contact detection and before the freeze
      onset on the contact `logic_tick`**; the freeze onset is next tick's phase 0; a
      scripted `ENVIRONMENT` event during a freeze applies (AC-HD-30).
- [ ] **The age bound is frozen with the clocks** — its own fixture, not AC-HD-19's:
      stamp `contact_tick` on the `logic_tick`, open a 70 ms freeze, deliver the event
      in the freeze: it **applies**, and the assertion records that
      `now − contact` is 0–2 **logic** ticks while 4–5 **physics** ticks have
      elapsed. The negative control — `now_tick()` returning `physics_tick` — must
      fail this fixture with term 5 (AC-HD-30/19; §4a).
- [ ] **`dealt` is post-floor pre-cap, `applied` is post-cap, `capped = applied <
      dealt`**; the cap and the floor are clamps, never gate terms; a capped hit's
      overkill is computed on the **applied** value (AC-HD-23's "a 6 hit with cap 2
      applies 2"; the capped-overkill fixture is this criterion's own).
- [ ] **The batch has one total order.** A three-event batch ordered by
      `(contact_tick, source_id, publication_index)` resolves identically on two
      different delivery orders; a late event sorts ahead of the fresh ones and
      **applies** when the target is `ALIVE` (the case AC-HD-22's late-event fixture
      ends `DEAD` and therefore does not cover) (AC-HD-22; §4b).
- [ ] **The `attack > 132` extension is one function** that reduces exactly to the
      ladder for `attack ≤ 132`, is flat across the L5→L6 seam (132 and 138 both
      4/6/3/4), and continues at 162 (chain 11) and 222 (chain 16) (AC-PRG-10; §3d).
- [ ] **The ladder is one unit with its knobs**: the two-field transaction is atomic, a
      single-field row-0 break is rejected, and the live-edit split rejects three
      cases and accept-clamps two with a terminating loop (AC-HD-13's negative
      fixtures).
- [ ] **Identity at default is a boot assertion**: the eight approved numbers
      reproduce at level 1/no gear (AC-HD-05 **plus AC-HD-08's pool values and
      AC-HD-10's boot HP 20**), row 0 equals the four raw knobs, and a disagreement
      fails the boot.
- [ ] **The revision discipline holds**: exactly one `StatRevision` per **point spend
      and** per **equipment change** (AC-HD-06 covers the spend; the equip-bump
      fixture is this criterion's own), zero per-tick recomputes over 600 ticks, a
      stale revision is a no-op, and the gear-delta asymmetry (a point heals, a module
      does not, a shrink clamps) is the reducer's (AC-PRG-09).
- [ ] **The edge is a latch**: exactly one `DeathEdge` per life, `hp_before > 0 ∧
      hp_after = 0 ∧ ALIVE ∧ (floor = 0 ∨ released)`, and every later event is
      rejected; the **release** is `release_hp_floor`'s and a floor-held lethal hit
      fires no edge (AC-HD-16/17/23).
- [ ] **The lock is a disjunction**: a hit inside the revive's 60-tick window is
      rejected **through SYS-07's own state**, with `FakeHealthPort` carrying no such
      window; a hit inside the published backdash/getup windows is rejected; a void
      hit during any window still kills (AC-HD-20/27; §8b).
- [ ] **The 11-term gate rejects the whole event with a named first-failing term** —
      including a **multi-term fixture** (an event that fails terms 1 and 11) that
      asserts *which* term is reported, which AC-HD-19's one-per-term set cannot
      cover — and the ledger's 256-ring never overwrites a live key (an occupancy spy
      over AC-HD-17's fuzz; AC-HD-19/18).
- [ ] **The RNG is inert at MVP**: zero rolls, `FixedRngPort` 0.5, and the VS mixer is
      stateless, explicit, platform-stable and keyed through `bind_phase` (AC-HD-39's
      two-key clause, runnable at MVP because the mixer ships inert; register item 5).
- [ ] **No hot-path allocation**: the four rings plus the entity table are preallocated, the soak shows zero
      net object/resource delta, ≤ 256 KB heap growth and ≤ 16 KB churn per 1,000
      ticks; the number ring is **32** and bounded (AC-HD-40's preallocation list,
      which is where the ring's size is asserted — AC-HD-38 does not assert it).
- [ ] **The persistence boundary holds**: no HP field exists, a load is always full,
      `restore_modules = 0` on a load, the ledger/latch/charges/modules are session
      state, and progression persists only through SYS-16's namespace (AC-HD-34;
      AC-HD-08 **except its energy/mana round-trip clause, which O-HD-7 records as
      unsatisfiable**).
- [ ] **The damage-number law holds**: the record's `amount` is the **applied** value
      (a capped 6 publishes 2; a Suture at 18/20 publishes 2), the number is published
      on the contact tick, the off-switch empties the ring, and the palette audit finds
      no sigil-red (AC-HD-38's four clauses); **the ring's 32 slots are overwrite-oldest
      and the lease token is the slot index** — asserted by the headless ring fixture,
      not by AC-HD-38, which says nothing about size, overwrite or the lease
      (AC-HD-40 for the size; register item 7 for the overwrite/lease fixture; §10).
- [ ] **The two load regimes are distinct and total**: a session load and an
      in-session reconstruct both end at `hp_max` with the slot at `CACHE_REFILL`,
      differ on the progression source (the save vs the live carry — a level earned
      after the last save is never rolled back), and both reset `hp_floor` to the
      profile's base (§9, F-HD-08; AC-HD-26/34). **The `DeathRecord` archive survives
      both resets** and the designation counter is not derived from it (§9d).
- [ ] **The System Offline split holds**: SYS-15's three rows and three options are
      consumed verbatim (the registered publisher), and SYS-07 publishes only
      `DeathOptions {revive_available}` plus the `DeathRecord` — with the revive
      option greyed and unselectable at 0 modules (§9e, AC-HD-25).

**Story gate (the first SYS-07 implementation story).**

- [ ] Every `PROBE-PENDING` item in §12 has a verdict; zero remain open.
- [ ] The boot assertion runs in-engine against the shipped config and the identity
      fixtures reproduce exactly.
- [ ] **The three qualified citations are reconciled before their fixtures are
      written**: **CR-HD-01** (AC-HD-13's DEFLECT value), **O-HD-7** (AC-HD-08's
      energy/mana round-trip) and **O-HD-2** (AC-HD-14's DEF 0/5/25 fixtures stay
      green while `defense` is constant 0 — the axis is carried, the *MVP source*
      clause is retired). A story that writes any of those three ACs against the
      unqualified text would assert something this decision forbids.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|---|---|---|---|
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-001 — consume, never poll | The resolver takes `AttackContext`; no `Input` read, no hitbox probe (§2, §11) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-002 — the five-value consumer enum and the `ENV` sentinel | The gate's term 11 and the source-domain law; `target ≠ ENV` (§8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-003 — the strike table (1/2/4) | `enemy_strike_damage(power)`, SYS-07's knob, a boot failure if absent (§8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-004 — the integer law | Integer-only schemas; a non-integer is rejected with telemetry (§3, §5) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-005 — the damage order | §3's six-stage table, the seven content branches plus the else-reject, and the "once each" rule |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-006 — the `StatBlock` and identity at default | §5's schema, the revision discipline, the boot assertion, the DEF retirement note |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-007 — MVP progression (1–5, points-only) | §5/§9: the points are SYS-16's `atk_points`/`hp_points`; the reducer applies the pool delta |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-008 — the inert pools | §9c: the two max formulas, the `logic_tick` regen accumulator, the efficiency value, the test-only accessor, mana's regen 0; no publication (O-HD-7 for the save clause) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-009 — the defeat edge and `soul_class` | §8b's mirrored latch and `DefeatEvent`, one per entity per life |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-010 — the player pool and the only writer | `HealthCore` is the sole writer; the static assertion is AC-HD-10; the revision guard is §5 (§5, §8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-011 — the enemy tiers | Consumed as profile `hp_max` values; the TTK ruler is F-HD-10's, unchanged |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-012 — the `HealthProfile` | §8a's shape + the two sentinels; registration validated, a bad profile a boot failure |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-013 — apply and overkill | §3c: the subtraction, the cap-then-floor order, the overkill's definition |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-014 — the death edge exactly once | §8's latch and the F-HD-05 predicate |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-015 — the `DeathRecord` | The edge's payload; every field sourced from the applied instance (§8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-016 — idempotence | §8's six-tuple key and the 256 ring |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-017 — the 11-term gate | §8's one-function predicate with the named first-failing term; cap/floor are not gates |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-018 — the i-frame lock and the void's exception | The lock is the second lock; `ENVIRONMENT` bypasses it and the mitigation (§8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-019 — no team assumption | The reducer keys on `(source, target)`; `source ≠ target` is term 1 (§8) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-020 — same-tick ordering; heals after damage | §4b's total order and the distinct `heal_phase` entry |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-021 — boss exceptions | §8a's hooks: cap, floor, immune kinds, `death_scripted` |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-022 — the health state machine | §8's four states and the total transition table |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-023 — no auto-respawn; the options contract | §9e: SYS-15 publishes the rows and options (registered); SYS-07 publishes `DeathOptions {revive_available}` and the `DeathRecord` (O-HD-11) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-024 — the reconstruct reset | §9's regime 2 and F-HD-08's reset list, **plus §9d's archive** (the record survives the reset) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-025 — the restore module | §8b's revive window + §9's revive row; the record is archived by §9d |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-026/027 — the non-ack gate request; terminality | The edge queues through ADR-0001 §6; no damage on the transition frame (§4) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-028 — freeze; the damage phase's position | §4's pin: the entry point, the position, the clock, the freeze onset, the assert |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-029 — the heal API | §8b's heal law: clamp, refuse at full, refuse a `DEAD` target, publish `HealEdge` |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-030 — the Suture and the quick slot | The charge is spent on the commit tick (§8b); the chip is SYS-01's pull (§11) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-031 — the pickup rule | §8b's `add_charge()`: no automatic pickup, refused at `QUICK_SLOT_MAX`, the item stays |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-032 — the cache restore; no HP in the save | §9's persistence boundary |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-033 — the inventory boundary | SYS-17 supplies the id and amount; SYS-07 applies; no inventory screen exists here |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-034 — the weapon-parity law | Unchanged: the harness is a fixture over the ladder, not a resolver stage (§3) |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-035 — the read contract | §11's records, read-only, no writer field |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-036 — the damage-number render law | §10's ring, the zero-frame law, the palette, the off-switch |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-037 — testability | §2/§11's split, the four ports, the two fakes, the stateless RNG |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-038 — performance and allocation | §Performance: the four rings + the entity table + §9d's 8-slot archive, the soak's three bars, the device gate |
| `design/gdd/health-damage.md` | SYS-07 | TR-HD-039 — traceability | Consumed unchanged: 39 TR / 15 F / 50 AC / 15 V / 68 edge bullets / 20 OQ / 33 knobs |
| `design/gdd/combat.md` | SYS-08 | TR-CMB-025 — the `DamageEvent` boundary (six fields, `arc`) | Consumed verbatim; `arc` is the ladder's column selector, `ABILITY` is not a column (§3) |
| `design/gdd/combat.md` | SYS-08 | TR-CMB-015 — a deflected projectile keeps its original damage | §3 branch 5's identity; the source of **CR-HD-01** |
| `design/gdd/movement.md` | SYS-06 | the 1200 ms arc, `DISABLED`, `body_busy`, the knockback distances | Consumed as the death edge's body consequence and the revive window's shape; **no movement mechanism is decided here**, so this row cites the GDD's laws rather than a TR-MOV ID |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-029/068/075/076 — body availability, the chip, custody, stamping | The chip arrives as a pulled intent; `contact_tick` is the stamp; the age bound is measured on it (§4a) |
| `design/gdd/progression.md` | SYS-16 | TR-PRG-007/008/009/010 — the budget, the two seams, the dealt extension | §3d's one function; §5's `hp_max` seam and the gear-delta asymmetry |
| `design/gdd/progression.md` | SYS-16 | TR-PRG-012/016 — the closed payload set; DEF retired | §5's `defense` comment; **O-HD-2** |
| `design/gdd/cache-stations-death.md` | SYS-15 | TR-CSD-007/013/017 — the activation restore, the body row, the faucet | §9's persistence boundary and the module's per-activation grant |
| `docs/architecture/adr-0001-input-architecture.md` | ADR-0001 | §5 phases, §6 the non-ack queue, §3 the freeze law | §4's position and the freeze-onset argument; the edge's gate request |
| `docs/architecture/adr-0002-save-serialization.md` | ADR-0002 | §5 the tick-boundary service drain; §6 the load ordering | §4's service-phase shape; §9's two regimes |

**Counts consumed, not re-derived:** 39 TR-HD · 15 formulas · 50 ACs (42 smoke + 3
device + 5 playtest + 0 VS) · 15 V-HD · 68 edge bullets · 20 OQ rows · 33 knobs.
This ADR adds **no** TR, **no** formula and **no** AC — it is a decision record, not a
second design.

**V-invariant coverage** (all fifteen carried, none re-minted; **five carry a named
qualification**). V-HD-01 by §8's latch and AC-HD-16; V-HD-02 by the integer law and
AC-HD-04/19, **with `heal > 0` carried by §8b's heal law and no dedicated fixture
(part of O-HD-10)**; V-HD-03 by §8's exactly-once and AC-HD-17's fuzz; V-HD-04 by
§9's reset list and AC-HD-26; V-HD-05 by §8b's disjunction and AC-HD-20/27; **V-HD-06
and V-HD-07 by §5's fail-closed ordering checks on the tier ladder and the strike
ladder, with no AC asserting the clamp/raise resolution, which is O-HD-10**; V-HD-08 by
`heal()`'s clamp (AC-HD-31); V-HD-09 by §8a's sentinel and the boot check; V-HD-10 by
§4a's `logic_tick` bound plus **§5's `clampi(…, 0, 2)`**, **with no dedicated fixture
(O-HD-10)**; V-HD-11 by the reducer's clamps
(AC-HD-27/33); V-HD-12 by §6's four checks and the two-field transaction
(AC-HD-05/13); **V-HD-13 by §3a's clamp-before-division and AC-HD-14, except its
third clause ("the MVP DEF source is the module layer"), which TR-PRG-016 retires —
O-HD-2**; V-HD-14 by the parity harness's unchanged consumption (AC-HD-36); V-HD-15 by
§3's "once each" and §4b's total order.

**Two coverage gaps are named rather than claimed** (O-HD-10): V-HD-06/07's ordering
**resolution** and V-HD-02/10's two minor clauses have **no MVP fixture**, because the
GDD gives them none — AC-HD-03 has no ordering case, AC-HD-11 is TTK values, AC-HD-12
is profile fields. The ADR **implements both ordering checks and the age-bound clamp**
in §5's fail-closed list and records the fixture gap; inventing an AC would be a
second design.

## 13 · The carried obligations

| ID | What | Owner | Blocks |
|---|---|---|---|
| **CR-HD-01** | **AC-HD-13's `DEFLECT` fixture reads "raw 2 → 3 at 132"; F-HD-02 branch 5 and TR-CMB-015 make it "raw 2 → 2 at 132"** (a deflect keeps its original damage and never scales by `attack`). One clause: the fixture's value. | the user (batched) | the first SYS-07 story that writes AC-HD-13's DEFLECT fixture — it cannot assert both the identity and 3. **The gate is named here because nothing else gates on an open CR**: story-readiness and `/dev-story` block on a `Proposed` ADR and on GDD/ADR *deviations*, not on unresolved change requests |
| **O-HD-1** | SYS-07's **F-HD-14 VS clauses** — the `attack` candidate `100 + 6×(L−1)` and its ceiling "up to L20 (214)" are superseded by F-PRG-01 (222 at L20); the `hp_max` clause is the all-HP build. Rider (a). | SYS-07's next doc touch | nothing in this ADR; a reader who quotes F-HD-14's VS curve as current |
| **O-HD-2** | SYS-07's **TR-HD-006 gear clauses** — "`defense` gains its first MVP source at SYS-16 authoring" and "a module-produced DEF is legal at MVP" are **retired** by TR-PRG-016. Rider (c). | SYS-07's next doc touch | the VS DEF revisit (OQ-PRG-8); a fixture no MVP module can satisfy |
| **O-HD-3** | SYS-07's **F-HD-10 module-build note** — the reading (the note names the ruler, not a ±10% ceiling on gear) is **DECIDED, option (i), D-ORCH-13**. Rider (d). | SYS-07's next doc touch | nothing in this ADR |
| **O-HD-4** | SYS-07's **TR-HD-010 writer clause** — the gear-delta asymmetry (a point's `+2` heals, a module's does not, a negative clamps) as a SYS-07 input. Rider (e). | SYS-07's next doc touch | nothing: §5 implements the mechanism already |
| **O-HD-5** | SYS-15's **TR-CSD-013 body row** — "store-absent" becomes store-carried for `progression` at v3, live-carried by the same read-gated window. Rider (b). | SYS-15's next doc touch | a reader who concludes progression is session-only |
| **O-HD-6** | SYS-07's **F-HD-02 branch 2** — the `attack > 132` dealt law is F-PRG-03's extension; F-HD-02's "an MVP module that raises `attack` above 132 holds row 4" describes a module TR-PRG-012's closed payload forbids. Rider (f). | SYS-07's next doc touch | nothing: §3d satisfies both laws on their domains |
| **O-HD-7** | **The energy/mana round-trip has no registered namespace** — AC-HD-08 asserts "the save round-trips both"; SYS-03 declares SYS-07 a runtime non-dependency and SYS-16's `progression` carries no pool. | SYS-03/SYS-16 at their next touch | AC-HD-08's save clause only; both pools are inert at MVP |
| **O-HD-8** | **AC-HD-41's "four-system arithmetic envelope" is superseded** by the registry's seven-system 2.45/6.55; SYS-07's own 0.25/0.75 allocation is unchanged. | qa-lead (the QA-plan sync) | nothing: the allocation this ADR prices is unchanged |
| **O-HD-9** | **The body's persistence contradiction.** SYS-07's save field list names "charges, modules, quickslot"; SYS-03 declares SYS-07 a runtime non-dependency and registers no namespace; SYS-15's TR-CSD-013 body row says the body is store-absent ("there is no file carrying it"). At MVP the landed behaviour is session-only, so a save→quit→load loses a carried restore module. **Two candidate resolutions, for the user batch**: (i) declare the body session-only at MVP and re-scope SYS-07's field list (a one-line rider, no schema bump); or (ii) register a `body` namespace at a future v3→v4 bump (SYS-03's mechanism, SYS-16's writer discipline) — which the carried module's one-per-station faucet would then need to reconcile with TR-CSD-017. | SYS-03 + SYS-15 + SYS-16 (the user batches the choice) | nothing in this ADR: §9b states the landed behaviour and regime 1's `restore_modules = 0` explicitly |
| **O-HD-10** | **Two V-invariant coverage gaps** — V-HD-06/07's ordering **resolution** (the tier ladder `T1<T2<T3<boss` and the strike ladder `P1<P2<P3`, with their clamp/raise rules) and V-HD-02's `heal > 0` / V-HD-10's `≤ 2` knob clamp have **no MVP fixture**: the GDD's AC set never asserts them. The ADR **implements the two ordering checks and the age-bound clamp in §5's fail-closed list** and records the fixture gap. | qa-lead (the SYS-07 QA plan) | the first SYS-07 story's evidence pack, which cannot claim full V coverage without them |
| **O-HD-11** | **The System Offline options contract's publisher.** SYS-07's GDD says "SYS-07 publishes the options contract"; the active registry entry `system_offline_contract` (added 2026-11-15 at SYS-15's authoring) registers **SYS-15** as the publisher of the three rows and the three options verbatim, with SYS-07 a verbatim consumer. The ADR takes the registered split (§9e) and this rider reconciles SYS-07's sentence. | SYS-07's next doc touch (with SYS-15's, if it prefers the other split) | nothing: §9e's split is implementable either way, and the availability predicate is SYS-07's under both readings |
| **CR-HD-02** | **TR-HD-020's late-event clause.** "A late event whose `contact_tick` precedes the phase in which it arrives is applied **in arrival order** if the target is `ALIVE`" gains "…which is its **sorted** position, since a late event's `publication_index` is its arrival index" — one clause, so the total order in §4b and the GDD's sentence are the same law. | the user (batched) | nothing in this ADR: §4b's sort is the decision and this clause makes the GDD agree with it. A story that writes AC-HD-22's late-event fixture against the unamended wording would assert delivery order |

## Related

- **GDD**: `design/gdd/health-damage.md` — the laws, F-HD-01…15, the 15 V-invariants,
  the 50 ACs, the gate manifest, the 20 OQ rows.
- **Revision package**: `design/reviews/sys07-baseline-rework-package.md` — the
  D-ORCH-03 ÷5 baseline rework; the applied-diff gates in
  `design/gdd/reviews/sys07-rework-review-log.md`.
- **ADR-0001**: `docs/architecture/adr-0001-input-architecture.md` — §5's phase
  pipeline (the damage phase's position), §6's non-ack queue (the death edge), §3's
  freeze law (the onset is next tick's phase 0).
- **ADR-0002**: `docs/architecture/adr-0002-save-serialization.md` — §5's service
  drain (the same shape), §6's `restore_complete`→`load_complete` ordering (both load
  regimes).
- **SYS-16**: `design/gdd/progression.md` — the six riders (a–f), TR-PRG-007…016, the
  `progression` namespace and the carry law.
- **SYS-15**: `design/gdd/cache-stations-death.md` — TR-CSD-007/013/017, the body row
  ("the store never carries it"), the module faucet.
- **Registry**: `damage_event`, `system_offline_contract`, `progression_namespace`,
  `six_system_perf_envelope` (all `status: active`).
- **Carried**: **CR-HD-01** (AC-HD-13's DEFLECT fixture value — §13); **CR-HD-02**
  (TR-HD-020's late-event clause); **O-HD-1…6** (the six SYS-16 riders, SYS-07's next
  doc touch); **O-HD-7** (the energy/mana round-trip's missing namespace); **O-HD-8**
  (the superseded four-system envelope); **O-HD-9** (the body-state persistence
  contradiction and its two candidate resolutions); **O-HD-10** (the two V-invariant
  coverage gaps); **O-HD-11** (the System Offline options publisher).
