# Movement & Platforming

> **Status**: **Approved — diff-scoped re-review PASS (2026-11-12)**. The four-seat design review returned NEEDS REVISION (16 blockers: arithmetic, contract edges, AC layer); all 16 were revised in-session and verified in the diff-scoped re-review (16/16 PASS; 15-site qa-lead spot-check; R1/R2/N1 recorded as non-blocking bookkeeping). The review loop is closed.
> **Author**: user + game-designer/systems-designer/gameplay-programmer (via /design-system)
> **Last Updated**: 2026-11-12 (diff-scoped re-review APPROVED)
> **Design Review**: NEEDS REVISION (2026-11-12) → revision → **APPROVED (diff-scoped re-review, 2026-11-12)**; record at `design/gdd/reviews/movement-review-log.md`
> **Implements Pillar**: "SotN, Not Hollow Knight" (deliberate, weighty movement) · "Read, Then Strike" (movement answers telegraphs) · touch-first platform goal
> **System ID**: SYS-06 (Core layer, MVP — Dash locked at start; Wall Jump and Double Jump gated)
> **Contracts**: ADR-0001 — Input Architecture (Accepted 2026-11-12); SYS-01 `design/gdd/input-control-mapping.md` (UNFROZEN, #10 record) — TR-INP-013/014/019/022/024/028/029/047/056/057/065/066/071/076, F-01/F-02/F-03/F-04/F-07/F-08

## Overview

The Movement & Platforming system is the body half of the trust contract: it turns SYS-01's honest orders into committed motion. It owns the speed model behind the five `move_order` values (creep, walk, sign), acceleration/friction, the fixed-arc jump and its behavior-gated extensions (Wall Jump, then Double Jump), crouch posture and crouch-walk, the ground Dash (locked at start), the backdash hop, knockback/knockdown execution, and the traversal physics of stairs, slopes and one-way floors. It publishes `grounded`, `facing` (`value + epoch + cause + asserted_tick`), and its locomotion locks into `body_busy`; it consumes the raw `crouch` channel and applies posture at the first grounded body-free tick (the B2 handoff), with a posture-carry for a commitment pulled while crouched; it owns the movement side of the defensive family (hop direction = `entry_sign`, `facing = −entry_sign` during the hop, body-free completion) and declares the derived `worst_case_arc_ms` (1200 at defaults) for TR-INP-029. It never reads `Input` directly and never selects a movement band — band selection is SYS-01's, speed and feel are SYS-06's. Without it the game loses the SotN-weight identity: distances learnable in strides, commitments that are honest, and a body that never mishears an order.

→ *Implementation patterns (CharacterBody2D wiring, floor-snap/slope/one-way probes, tick-driven motion, knockback integration) are ADR raw material for the planned **Movement Architecture ADR**; this GDD stays at the behavior level. The input contracts it consumes are ratified by **ADR-0001** (`docs/architecture/adr-0001-input-architecture.md`, Accepted 2026-11-12).*

## Player Fantasy

### The named fantasy — The Body Obeys, and the World Answers

You deliberate; she moves. The body's stride is a unit you can learn: a room is measured in walk-lengths, a gap in jump-arcs, a threat in crouch-heights. Nothing about her movement is twitchy, floaty, or approximate — the commitment is the point. When you choose a direction, she commits to it with weight; when you choose to stop, she stops like mass, not like a cursor. The fiction labels, never prescribes: the android body is precise because the movement layer is precise, not because the player has fast hands.

### The contract — committed strides, honest edges

Three terms: (1) **A stride is a unit** — walk speed is constant and distances are learnable; creep is exactly half a walk, so the analog rig's gift never breaks the ruler. (2) **A commitment is whole** — once an arc starts (jump, dash, hop, knockdown), it completes or is honestly interrupted by a gate, never half-cancelled by a new idea. (3) **An edge is readable** — ledges, walls, stairs, slopes and one-way floors answer the same way every time; the body never surprises you at a boundary. Crouch is a stance, not a button: entering it is a deliberate hold or toggle, crouch-walking is slow and low, and standing up under a low ceiling is refused honestly rather than clipping.

### Anchor moment — The Low Read

A heavy enemy winds a high strike. You hold down; she settles into the crouch *before* the strike lands, the high arc passes over her, and the crouch-attack answers from below. The read was yours; the posture was the body's. The movement layer's promise is that the crouch she shows is the crouch the world hits.

### Anchor moment — The Backdash That Faces the Threat

A strike commits; you flick back. She hops away *and keeps her eyes on the enemy* — `facing = −entry_sign` for the hop's duration — so the next read is already aimed. The dodge is a reposition, not a blind turn.

### Language law

Use *committed, whole, learnable, honest, weighted*; ban *crisp, snappy, instant, floaty, twitchy, frame-perfect*. "Precision" is the body's property, never the player's demand. Falsifiability rule: every feel-sentence must be verifiable by playtest or build check; if verifying it would need a stopwatch on reflexes, cut it.

### Success signature

Playtesters describe distances in walk-lengths or jump-arcs unprompted; nobody calls the jump floaty or the walk laggy; the crouch-walk reads as a stance, not a slowdown; the backdash reads as a dodge that keeps the enemy in view.

*Pillar ties: "SotN, Not Hollow Knight" (deliberation as chosen texture) · "Read, Then Strike" (movement answers telegraphs) · touch-first platform goal (parity of contract, not of milliseconds).*

## Detailed Design

### Core Rules

**Rule IDs (`TR-MOV-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** PROVISIONAL marks indicate contracts with undesigned downstream GDDs; ownership boundaries are intended final.

#### 1 · The movement contract — consume, never poll

- **TR-MOV-001 — Consume, never poll.** SYS-06 consumes `(raw_axis, move_order)` from the InputBus. `move_order ∈ {−1, −CREEP_RATIO, 0, +CREEP_RATIO, +1}` is the contract (F-03; `CREEP_RATIO` is SYS-01's, 0.5 at defaults); `raw_axis` is the audit/trace channel only. Band selection is SYS-01's; speed, ramps and feel are SYS-06's. No `Input.*` call outside `src/input/` (CI grep). *Test: a mocked axis stream behaves identically to human input; `src/movement/` contains no direct-Input symbol.*
- **TR-MOV-002 — The stride ruler.** Steady-state target speed is `move_order × WALK_SPEED`; creep is exactly `CREEP_RATIO × WALK_SPEED` (0.5 by SYS-01's published order). Acceleration and friction shape the approach, never the steady ratio. *Test: a 2 s hold at order 0.5 converges to 0.5 × `WALK_SPEED` ± 1 px/s.*
- **TR-MOV-003 — Committed motion.** Velocity changes through `GROUND_ACCEL`, `GROUND_FRICTION`, `AIR_ACCEL` and `COMMITTED_FRICTION`; no instant stops. While `body_busy` is true and no Movement-scripted arc is active, target speed is 0 and existing velocity decays at `COMMITTED_FRICTION` — this is how Combat's attack arc gets its locomotion lock without Combat owning movement. *Test: an attack mid-run stops steering within `COMMITTED_STOP_MS`; release at neutral decays to 0 without reversing.*
- **TR-MOV-004 — Data-driven feel.** Every speed, ramp, arc and timing is a Tuning Knob; no gameplay literal in code. *Test: changing a knob changes behavior with no code edit.*
- **TR-MOV-005 — Gravity, terminal velocity, floor snap.** `GRAVITY` down, `TERMINAL_VELOCITY` cap, floor snap on descent; no wall friction except the wall slide. *Test: terminal velocity reached in a long fall; landing snaps without a one-tick bounce.*

#### 2 · Facing — the publication the gesture machine reads

- **TR-MOV-006 — Facing publication.** `FacingPublication {value ∈ {−1,+1}, epoch, cause ∈ {INPUT_TURN, KNOCKBACK, WALL_TURN, HOP, SCRIPTED}, changed_tick, asserted_tick}` is published on every change and **re-asserted every `physics_tick`** (raw, including freeze — ADR-0001 R3/§8; the §10 "logic_tick" cadence is superseded by R3, recorded as OQ-M2). The epoch increments only on a **`logic_tick` value change**; the cause describes that change; `changed_tick` is the `logic_tick` of the change; `asserted_tick` is the last assertion. **Initial epoch = 0** at boot (cause SCRIPTED). A cause may be published with an unchanged value/epoch — HOP on the a11y path, WALL_TURN when already facing away — as a **cause re-assertion** (`asserted_tick` updates, epoch does not). *Test: every flip carries a cause; an epoch is never reused; a missed read never sees a stale value; a cause-only publication never increments the epoch.*
- **TR-MOV-007 — Turn rule.** Facing flips when `sign(move_order) ≠ facing` and `|move_order| ≥ TURN_MIN_ORDER`, where `TURN_MIN_ORDER = CREEP_RATIO` (SYS-01's published order magnitude — **not a fixed 0.5**; the order set is `{−1, −CREEP_RATIO, 0, +CREEP_RATIO, +1}`), outside scripted arcs. The **press1-induced turn** is the ordinary INPUT_TURN produced by the back flick; it is published on the press1 tick or the next — inside ADR-0001's `FLIP_ATTRIBUTION_WINDOW_TICKS = 2` causality window. **Hop-exit:** the turn predicate is suppressed for the full `BACKDASH_LOCK_MS`; on the tick after the lock clears, the ordinary predicate runs and may publish INPUT_TURN. No turn at neutral. **Cross-contract note (OQ-M1):** a slow back flick enters creep before the walk band; if SYS-01's true-back press1 is the **walk-band** entry, the creep turn makes `entry_sign = facing` and the gesture never arms. The required SYS-01 one-clause amendment: press1 = the first back-direction **creep** entry, with the true-back check reading facing before it. *Test: a flick back publishes INPUT_TURN within 2 ticks; a neutral stick never turns her; no turn during the hop lock.*
- **TR-MOV-008 — Scripted facing changes.** `KNOCKBACK` sets `facing = −sign(knockback_dir_x)` (she faces the attacker); `WALL_TURN` sets facing away from the wall; `HOP` sets `facing = −entry_sign`; `SCRIPTED` (doors, elevators, cutscenes) sets facing from the script. A scripted cause never re-enters the backdash machine as an INPUT_TURN. A same-value cause is a **cause re-assertion** (epoch unchanged; `asserted_tick` updates). *Test: a knockback flip resets the detector; a hop flip does not; the a11y hop publishes HOP with an unchanged value and epoch.*
- **TR-MOV-009 — Facing is always published.** From boot, facing is initialized from spawn data (cause SCRIPTED) and re-asserted every tick. The backdash detector fails closed if facing is absent (EX-11); Movement is the publisher, so absence is a Movement bug, not a design state. *Test: the detector never sees an unpublished facing after boot.*

#### 3 · Ground movement, jump, and the traversal ladder

- **TR-MOV-010 — Grounded publication is raw.** `grounded = is_on_floor()`; coyote is internal and never changes the published stream (TR-INP-014's test). *Test: toggling coyote changes behavior while the grounded trace is bit-identical.*
- **TR-MOV-011 — jump_held consumption.** `jump_held` is read every airborne tick. `JUMP_CUT_RATIO = 1.0` (no cut) at MVP — the fixed SotN arc the combat prototype's **fixed-arc** player validated. **Hybrid option:** when the designer enables the knob, releasing jump multiplies upward velocity by the ratio once per jump; height scales as the **square** of the velocity ratio — at 0.5 the apex quarters, at √0.5 ≈ 0.707 it halves. The channel is already plumbed, so enabling it needs no input change. *Test: at 1.0 release does nothing; at 0.707 the apex halves; the press itself is unaffected.*
- **TR-MOV-012 — Ground jump.** A pulled `jump` intent applies `JUMP_VELOCITY`; `COYOTE_MS` extends the ground window; a buffered press is pulled on landing (input's buffering, TR-INP-025); one press = one jump. Jump stands her up (input clears the latch; Movement applies the stand on the jump tick). *Test: coyote boundary; buffered landing jump; no double ground jump.*
- **TR-MOV-013 — Traversal ladder.** Dash is **action-level** (input delivers regardless; Movement rejects pre-unlock with no execution, no error — TR-INP-003). Wall Jump and Double Jump are **behavior-level** gates on Jump (input behavior is bit-identical pre/post — TR-INP-057). Grants flow SYS-16 → SYS-06. No new buttons. *Test: pre-unlock presses execute nothing and error nowhere; post-unlock the identical press executes.*
- **TR-MOV-014 — Wall slide / Wall Jump.** Airborne + wall contact + `move_order` toward the wall → wall slide at `WALL_SLIDE_SPEED` (requires Wall Jump). A pulled jump applies `WALL_JUMP_VELOCITY` away and up. **Re-arm:** a wall jump re-arms after `WALL_JUMP_REARM_MS` off wall contact, or immediately on a **different wall** or a ground touch; **a single wall cannot be climbed indefinitely** (the re-arm gap is the anti-ladder law). Wall jump **does not refresh double jump**; facing turns away from the wall (cause WALL_TURN). *Test: a two-wall chain works; a single wall cannot be climbed past the re-arm gap; the double jump stays spent.*
- **TR-MOV-015 — Double jump.** One air jump per airtime; resets on ground only; consumes the jump press; not refreshed by wall jump. *Test: ground → air jump → wall jump → no second air jump; landing restores it.*

#### 4 · Crouch — the posture handoff

- **TR-MOV-016 — Crouch posture.** The raw `crouch` channel (`latch ∨ held_zone`, B2) is consumed every tick. Posture is applied at the **first grounded body-free tick**; the latest raw value is queued while committed or airborne, and if it flips back before application the queued latest wins (no net posture change). States: STANDING / CROUCHING / CROUCH_WALK. Crouch speed is creep (`CREEP_RATIO × walk`); the crouch lowers the hurtbox top by `STAND_HEIGHT × (1 − CROUCH_HURTBOX_RATIO)` (Combat consumes); crouch-walk traverses stairs and slopes; jump stands her up; standing is refused under a low ceiling (she stays crouched). **The activating edge is the engage** — the tick the published crouch becomes true — not the cone entry; a brush that never engages does nothing. **Posture-carry (attack commitments only):** an **attack** commitment pulled while the raw crouch is true carries the crouch posture for its duration — the hurtbox is crouched on the commitment's first tick, so a crouch attack never shows a standing hurtbox. The Movement locomotion commitments (dash, jump, hop) use the **commitment-entry stand** instead (transition law 1's exception); posture-carry never applies to them. Movement publishes **`crouch_effective`** (the applied posture) for Combat's hurtbox/overlap; the **raw** channel remains Combat's selection input (TR-INP-028). **`posture_pending`** is published while a posture order is queued (the SYS-24 cue; the player can see that the body will crouch when it can). *Test: crouch during an attack applies at recovery end; a release during the commitment yields no crouch; a crouch+attack pulled on the same tick shows a crouched hurtbox on the first active tick; a brush that never engages does nothing (the guard is SYS-01's); a crouch-held dash/jump/hop stands her up on the first tick (the commitment-entry stand), never posture-carry.*
- **TR-MOV-017 — Crouch is a stance, not a commitment.** Crouching never publishes a body_busy lock; the player can crouch-walk, turn, and be interrupted. A crouch that cannot stand (low ceiling) is a legal persistent state. *Test: body_busy is false while crouch-walking; a low ceiling holds the posture.*

#### 5 · The defensive family — hop and dash (movement side)

- **TR-MOV-018 — Backdash hop.** The intent carries `entry_sign` only; direction = `entry_sign`; `facing = −entry_sign` during the hop (cause HOP); hop `BACKDASH_HOP_MS` at `BACKDASH_SPEED`; lock `BACKDASH_LOCK_MS` = hop + recovery; **body-free completion** (input's check at the completion tick); **MVP ships drop-when-busy**; no deferred queue; no input-side cooldown. Movement pulls the same tick the intent is offered. **No-headroom refusal:** if the body cannot clear the ceiling, the hop is pulled and refused by Movement — a `move_refused {verb, reason}` edge, logged separately from input drops (honored but unexecuted, never a wrong motion). Off a ledge the hop keeps horizontal motion and gravity applies; into a wall it stops at the wall and the lock continues. The hop is a locomotion lock. *Test: hop direction and facing; busy-at-completion drop; no-headroom refusal is a `move_refused`, not a motion; no second hop inside the lock.*
- **TR-MOV-019 — Dash.** Ground-only; action-level lock; `DASH_MS` at `DASH_SPEED`; `DASH_COOLDOWN_MS` between starts; **no i-frames at MVP** (Combat's ruling); no steering; off a ledge the dash completes horizontally, then gravity applies; the dash is a locomotion lock. **Direction = the published `facing` at the pull tick**; a same-tick INPUT_TURN is applied before the first motion tick; a neutral stick uses the current facing. From crouch, the dash stands her up on its first tick if headroom exists (a commitment-entry stand, exempt from the body-free posture law); otherwise it is refused with `move_refused`. **Dash-jump:** a jump pulled during the dash motion window preserves the dash horizontal velocity into the jump (the remaining dash momentum converts to the jump's `v_x`), giving the unlock its traversal job — the forward gap extender. *Test: pre-unlock no-op; cooldown; no i-frames; dash direction follows facing; crouch-dash stands her up; dash-jump reach exceeds a walk-jump.*
- **TR-MOV-020 — The defensive-family ruling (Movement's ratification).** Movement ratifies the hop side: the hop is a body-free-completion reflex, and **MVP ships drop-when-busy**. Combat proposes the recorded short-defer ruling (EX-1/D-5); Movement ratifies **drop-when-busy for MVP** — a short-defer amendment would require a Movement-side deferred-hop queue and is therefore not ratified at MVP; it returns as a recorded VS question. *Test: a busy body at completion produces a still body and no motion.*
- **TR-MOV-021 — Knockback / knockdown / getup.** Combat sends a `KnockbackOrder {dir, power}`; Movement executes the motion and the lock. **A hit with `power ≥ KNOCKDOWN_POWER` enters KNOCKDOWN on the hit tick** — the KNOCKBACK phase does not run; `KNOCKDOWN_MS + GETUP_MS` = **1200 ms**. A hit below the threshold runs KNOCKBACK (`KNOCKBACK_MS`). A wall stops horizontal knockback; a pit becomes a fall (SYS-07/15 resolve death). **No re-knockdown:** during KNOCKDOWN or GETUP a further hit applies damage but starts no new lock (Combat may grant getup i-frames). The body is busy throughout. *Test: the 1200 ms arc; wall stop; no control during getup; a second heavy hit does not re-enter the lock.*
- **TR-MOV-022 — body_busy publication.** Movement locks = {backdash hop, dash, **knockback**, knockdown, getup, scripted move, **freeze_hold**}. Every lock publishes `start_tick` and `end_tick` as a **level** (set membership, true on `start_tick` through `end_tick−1`); the OR is `body_busy` (F-08). Locks persist through freeze and are never cleared by a freeze. Movement declares `worst_case_arc_ms` at registration as the **derived max** `max(BACKDASH_LOCK_MS, DASH_MS, KNOCKBACK_MS, KNOCKDOWN_MS + GETUP_MS, SCRIPTED_MAX_MS)` — **1200 at defaults**, re-declared on every lock-arc edit, and validated ≤ 1200 by V-MOV-17 (TR-INP-029). *Test: a publisher raises/clears mid-window; fail-open remains input's; the declaration equals the derived max; KNOCKBACK raises the OR.*
- **TR-MOV-023 — Hit-stop ⇒ body-committed (Movement side).** Movement raises no hit-stop at MVP; any future Movement hit-stop source must publish a locomotion lock for its duration. **`freeze_hold`:** Movement publishes a zero-motion lock for any `logic_running == false` interval that starts while no other Movement/Combat lock is active, so a SYS-29 freeze on an idle body is still body-committed. Movement ratifies Combat's paired commitments. *Test: no freeze exists without a published body commitment; an idle-body freeze publishes `freeze_hold`; the backdash detector sees body_busy mid-freeze.*
- **TR-MOV-024 — Freeze integration.** Motion integrates only on `logic_tick` advances; while `logic_running` is false (hit-stop) or the context is non-Gameplay, Movement holds position and velocity and continues raw publication (grounded, facing, body_busy, `crouch_effective`). Movement does not pull or start arcs during freeze. *Test: a mid-hop hit-stop freezes the hop's position; the lock remains published; the hop resumes with the same remaining duration.*

#### 6 · World traversal — edges that answer the same way

- **TR-MOV-025 — Stairs and slopes.** Auto-stairs (SotN): walking into a step ≤ `STEP_HEIGHT` snaps up; descending snaps down; no jump needed. Slopes: walk along up to `MAX_SLOPE_DEG`; steeper → slide at `SLIDE_SPEED`. Crouch-walk traverses both at creep speed. *Test: a stair climb at walk; a steep slope slides; crouch-walk keeps the posture.*
- **TR-MOV-026 — One-way floors.** **Crouch + jump drops through** a one-way floor (SotN; a derived behavior, not a new verb). The drop is **armed only by a crouch whose engage edge occurred while grounded**; an air-held crouch that lands does not arm it — the first ground jump is ordinary. The drop disables the one-way collision for `drop_ticks = ceil(DROP_THROUGH_MS × physics_tps ÷ 1000)` and releases when the ticks elapse **and** the feet are below the platform (no overlap) or a solid floor is contacted. The drop **does not change posture**; the raw crouch channel governs on landing. On solid floors the same input is an ordinary jump. *Test: crouch+jump on a one-way platform drops; an air-held crouch that lands jumps; the drop releases without an overlap ejection.*
- **TR-MOV-027 — Movement zone and audited layout.** SYS-01 owns the movement-zone rect, the audited cluster table and touchdown binding; Movement never reads touch geometry, and no Movement knob may alter them. The zone's single-owner rule is input's. *Test: the Movement build has no touch-region symbols; the audited table is unchanged by Movement tuning.*
- **TR-MOV-028 — Camera handoff.** Movement publishes velocity, grounded, facing, wall state, body_busy and the hop/knockback events to SYS-32; camera logic is SYS-32's. *Test: a camera mock consumes the publication without reaching into Movement.*
- **TR-MOV-029 — Gate terminality.** At gate entry, scripted arcs die with the gate; no motion is applied on the transition frame; held states persist; on resume nothing is queued. *Test: pause mid-dash → no motion on resume until a new order.*
- **TR-MOV-030 — No new verbs, no ninth body verb.** Crouch+jump drop-through, crouch+attack (Combat), wall jump and double jump are behaviors over the existing eight verbs. *Test: registry diff empty; input-layer files unchanged.*
- **TR-MOV-031 — Testability.** Split the seam: **`MotionCore`** is a pure reducer over an injected InputBus and a **`BodyPort`** (`probe_floor/wall/slope`, `step(velocity, dt) → MoveResult{position, grounded, wall_normal, floor_normal, one_way_hit}`); `FakeBodyPort` is the GUT fixture, `CharacterBody2D` the play implementation. Fixed 60 tps. *Test: bit-identical velocity/state traces under a fixed `BodyPort` fixture; positions equal under the same fixture.*
- **TR-MOV-032 — Integrator law.** Motion uses **semi-implicit Euler**: `v ← v + a × Δt`, then `position ← position + v × Δt`; the jump/impulse is applied **before** the first move; `Δt = 1 ÷ physics_tps`. The continuous formulas are the design contract; the discrete 60-tps values are the AC fixture (Formulas). *Test: the 60-tps jump apex is 70.4 px ± 1; the hop is 14 ticks × 7 px; the dash is 12 ticks × 7 px.*
- **TR-MOV-033 — Body-free definition.** `body_free` is true when the `body_busy` OR is false **in the tick-open snapshot**; posture application and gate/arc decisions read that definition, so the application tick is deterministic. *Test: a lock ending at tick T yields application at T+1's tick-open snapshot; the same fixture repeats bit-identically.*
- **TR-MOV-034 — Body phase.** Movement integrates in a **body phase** after the input publish and before the next tick's snapshot; a hop pulled at T moves at T; the Movement ADR pins the exact position in the ADR pipeline (OQ#1). The puller receives `accept(PulledIntent)` — "pull" names the puller's decision, not a poll of `Input`. *Test: a hop pulled at T has moved by T's end; the next tick's snapshot sees the new `body_busy`/`grounded`.*

### States and Transitions

Two orthogonal channels: **posture** and **locomotion**. Posture is the stance; locomotion is the body's current motion. Jump behavior is a sub-state with its own counters.

**Posture**

| State | Enter | Exit | Notes |
|---|---|---|---|
| **STANDING** | boot; crouch released and applied; jump; stand permitted | crouch engaged at first grounded body-free tick | default |
| **CROUCHING** | published crouch true at the first grounded body-free tick, or posture-carry on a commitment | published crouch false at the first grounded body-free tick **and** headroom exists | hurtbox top lowered; speed 0 while idle |
| **CROUCH_WALK** | CROUCHING + `move_order ≠ 0` | `move_order = 0` → CROUCHING | speed = creep; stairs/slopes allowed |
| **BLOCKED_STAND** | stand requested, no headroom | headroom appears → STANDING | honest refusal; never clips |

**Locomotion**

| State | Enter | Exit | body_busy |
|---|---|---|---|
| **IDLE** | grounded, target speed 0 | move order; jump; dash; hop; knockback | no |
| **MOVE** | grounded, target speed ≠ 0 | target 0; jump; dash; hop; knockback | no |
| **AIR_RISE** | jump | apex; wall contact; landing | no |
| **AIR_FALL** | apex; walked off a ledge | landing; wall contact; air jump; wall jump | no |
| **WALL_SLIDE** | airborne + wall + toward-wall order + Wall Jump unlocked | jump (wall jump); wall lost; landing | no |
| **DASH** | dash pulled + gate open + cooldown ready | `DASH_MS` elapsed; gate; knockdown | **yes** |
| **BACKDASH_HOP** | backdash intent pulled + body free | `BACKDASH_LOCK_MS` elapsed; gate; knockdown | **yes** |
| **KNOCKBACK** | hit with `power < KNOCKDOWN_POWER` | `KNOCKBACK_MS` elapsed; gate | **yes** |
| **KNOCKDOWN** | hit with `power ≥ KNOCKDOWN_POWER` (on the hit tick) | `KNOCKDOWN_MS` elapsed | **yes** |
| **GETUP** | knockdown ends | `GETUP_MS` elapsed | **yes** |
| **DROP_THROUGH** | crouch+jump on a one-way floor, armed while grounded | `drop_ticks` elapsed **and** no overlap or solid floor | no |
| **SCRIPTED** | SYS-02/SYS-05 scripted move | script end; gate | **yes** |
| **DISABLED** | death/respawn transition | respawn complete | yes (context gate) |

**Jump sub-state (one per airtime)**

| Field | Rule |
|---|---|
| `ground_jump_used` | set on ground jump; cleared on landing |
| `air_jump_used` | set on double jump; cleared on landing only |
| `wall_jump_available` | set on wall touch; cleared on wall jump; does not touch `air_jump_used`; re-arms after `WALL_JUMP_REARM_MS` off wall contact, or on a different wall / ground touch |
| `jump_cut_applied` | one cut per jump; only when `JUMP_CUT_RATIO < 1.0` |

**Transition laws**

1. **Posture is applied only at a grounded body-free tick.** A posture change requested during a commitment or in the air is queued (latest wins) and applied when `body_busy` clears on the ground. **Exception — commitment-entry stands:** a dash, jump or hop that starts from crouch stands her on the commitment's first tick if headroom exists; the stand is part of the commitment, not a body-free posture application. **Exception — posture-carry (attack commitments only):** an **attack** commitment pulled while raw crouch is true carries the crouch posture for its duration (TR-MOV-016); dash, jump and hop never carry it — they stand her up.
2. **A scripted arc cannot be interrupted by a new request.** DASH, BACKDASH_HOP, KNOCKBACK, KNOCKDOWN, GETUP and SCRIPTED cannot be entered from each other by a new order; **the KNOCKBACK→KNOCKDOWN→GETUP chain is one arc** and a hit during KNOCKDOWN/GETUP does not start a new lock.
3. **Crouch never blocks a commitment except the no-headroom stand-up.** A crouched body can dash (stands first), jump (stands first), be hit, or be scripted; a dash/hop that cannot clear the ceiling is refused with `move_refused`.
4. **Gate entry clears arcs.** No locomotion state survives a gate entry except DISABLED; on resume the body is IDLE.
5. **Facing changes only through the five causes.** The locomotion state never flips facing on its own.

### Interactions with Other Systems

| Contract | SYS-06 owns | Consumer owns |
|---|---|---|
| **`move_x` consumption** | speed mapping, ramps, committed hold | SYS-01: raw axis + band selection (F-02/F-03) |
| **`crouch` consumption** | posture application at the first grounded body-free tick; posture-carry; `crouch_effective` + `posture_pending`; crouch speed; hurtbox height; stairs/slopes | SYS-01: raw `latch ∨ held_zone` every tick (B2); SYS-08: selection from the raw channel, hurtbox/overlap from `crouch_effective` |
| **`jump` / `dash` / `backdash`** | pull discipline, arcs, gates, cooldowns, hop lock | SYS-01: delivery, windows, backdash gesture, `entry_sign` |
| **`facing`** | value + epoch + cause + `asserted_tick`; press1-induced turn; hop facing; cause re-assertion | SYS-01: reads at press1 for the true-back check and flip-attribution (ADR-0001 §10) |
| **`grounded` / `jump_held`** | `grounded` published raw; coyote internal; `jump_held` consumed | SYS-01: consumes `grounded` for buffering; Combat reads body state |
| **`body_busy`** | locomotion locks + `start_tick`/`end_tick`; KNOCKBACK + `freeze_hold`; derived `worst_case_arc_ms` (1200 at defaults) | SYS-01: ORs into `body_busy` (F-08); SYS-08: commitments |
| **`move_refused`** | `{verb, reason}` edge for a no-headroom dash/hop | SYS-24: optional cue; SYS-01: drop-rate telemetry (separate from input drops) |
| **Combat commitment** | applies the committed locomotion hold while busy | SYS-08: publishes the attack/clash/stagger commitment |
| **Knockback / knockdown** | motion + lock (1200 ms) | SYS-08: computes vector/power; SYS-07: HP/damage/death |
| **Traversal grants** | gates: Dash action-level; Wall Jump/Double Jump behavior-level | SYS-16: grants flow |
| **Camera** | publishes velocity, grounded, facing, wall state, body_busy, hop/knockback events | SYS-32: follow/look-ahead/framing |
| **Hit-stop** | holds motion during freeze; keeps locks published | SYS-29: requests hit-stop; SYS-08: pairs the commitment |
| **Contexts/gates** | arcs die at gate entry; no motion on the transition frame | SYS-05: context state; SYS-01: gate enforcement |

- **SYS-01 Input (upstream, hard):** the contracts above; the movement-zone rect and audited layout are input-owned; Movement never reads touches.
- **SYS-08 Combat (downstream, hard):** attack commitments drive the locomotion hold; crouch hurtbox is read by Combat; knockback vector comes from Combat; i-frames are Combat's grant.
- **SYS-07 Health & Damage (downstream, hard at hit time):** HP, damage application, death/respawn; Movement enters DISABLED on death.
- **SYS-02 Room & World Structure (upstream, hard):** collision geometry, one-way platforms, stairs/slopes, scripted moves; Movement never reads room logic.
- **SYS-16 Progression (upstream, soft):** grants Dash, Wall Jump, Double Jump.
- **SYS-24 HUD (downstream, soft):** reads state for visuals; no touch geometry from Movement.
- **SYS-29 Juice (downstream, soft):** hit-stop clock; Movement freezes motion; no requests at MVP.
- **SYS-32 Camera (downstream, soft):** reads the publication; camera GDD last.
- **SYS-05 Game Flow (upstream, coordination):** contexts/gates; Movement honors gate entry.

### ADR-0001 Contract Ratification (Movement side)

| ADR-0001 contract | Movement's obligation | Test |
|---|---|---|
| `move_x = (raw_axis, move_order)`; band selection SYS-01's | Consume the pair; map order to speed; never select a band; never read `Input` | TR-MOV-001/002; CI grep |
| `crouch` publishes raw `latch ∨ held_zone` every tick; posture application is SYS-06's handoff (B2) | Apply posture at the first **grounded** body-free tick; posture-carry; `crouch_effective`; activating edge = the engage; crouch-walk/stairs/slopes | TR-MOV-016/017/025 |
| `facing` publication with value + epoch + cause | Publish on change and re-assert every `physics_tick`; value/epoch on `logic_tick`; `asserted_tick`; cause re-assertion; own the press1-induced turn; set `facing = −entry_sign` during the hop | TR-MOV-006/007/008/018 |
| Backdash hop: direction = `entry_sign`, hop-lock rate, body-free completion; MVP drop-when-busy | Pull the same tick; run the hop/lock; face the threat; accept the drop; no deferred queue | TR-MOV-018/020 |
| Defensive-family short-defer ruling (EX-1/D-5) is Combat's to propose | Ratify the hop side as **MVP drop-when-busy**; a short-defer amendment is a recorded VS question, not an MVP code path | TR-MOV-020 |
| `body_busy` contribution (locomotion locks); declare `worst_case_arc_ms` for TR-INP-029 | Publish every lock's `start_tick`/`end_tick`; KNOCKBACK + `freeze_hold`; derive the max (1200 at defaults); locks persist through freeze | TR-MOV-022/024 |
| `grounded`, `jump_held` | **Movement publishes `grounded` raw**; read `jump_held` every airborne tick; fixed arc default, cut optional | TR-MOV-010/011 |
| Traversal ladder Dash → Wall Jump → Double Jump | Dash action-level; Wall Jump/Double Jump behavior-level; grants from SYS-16; no new buttons; dash-jump is the unlock's traversal job | TR-MOV-013/014/015/019 |
| Hit-stop ⇒ body-committed invariant | Raise no hit-stop at MVP; future sources pair a lock; `freeze_hold` covers an idle-body freeze; ratify Combat's commitments | TR-MOV-023 |
| Movement-zone rect and audited layout table | Input-owned; Movement never reads touch geometry; no Movement knob may alter them | TR-MOV-027 |
| Gate-request terminality | Arcs die at gate entry; no motion on the transition frame; held states persist | TR-MOV-029 |
| No new input verbs; no ninth body verb | All behaviors are over the existing eight verbs | TR-MOV-030 |

## Formulas

Movement's formulas are **conversion laws** (orders → speeds), **integration laws** (velocity → position on the game clock), and **arc laws** (jump, dash, hop, knockback). Three laws govern every formula:

- **Named-symbol law.** Every literal appears here only as a named symbol; values live in exactly one place — the Tuning Knobs table.
- **Never-stingy boundary law.** Every boundary comparison is inclusive on entry, strict on exit: a window engages at `≤`/`≥` the threshold; leaving requires strictly beyond the exit counterpart.
- **Clock law.** All gameplay motion integrates on `logic_tick`; hit-stop freezes the integration (F-MOV-14). Touch-feel timers are input's, not Movement's.

**Integrator law (TR-MOV-032).** Motion is integrated with **semi-implicit Euler**: `v ← v + a × Δt`, then `position ← position + v × Δt`; the jump/impulse is applied **before** the first move; `Δt = 1 ÷ physics_tps`. The continuous-time formulas below are the design contract; the **discrete realization at 60 tps** is the AC fixture. Discrete values: jump apex **70.4 px**, air time **41–42 ticks**; hop **98 px** (14 ticks × 7 px); dash **84 px** (12 ticks × 7 px); wall jump **≈82.3 px**; knockback **16.9 px** at power 1 / **67.6 px** at power 2. ACs assert the discrete values ±1 px / ±1 tick; the continuous values are the design intent.

**Range convention.** Every range column below is the value **at the other knobs' defaults**; the joint safe-range envelope is wider and is asserted by AC-MOV-28, not printed here. A printed range is not a joint-envelope claim.

**Formula ledger — law vs knob.**

| # | Formula | Class | Constants consumed (live in Tuning Knobs) |
|---|---|---|---|
| F-MOV-01 | order_to_target_speed | True law | `WALK_SPEED` |
| F-MOV-02 | ground_velocity_step | True law | `GROUND_ACCEL`, `GROUND_FRICTION`, `COMMITTED_FRICTION`, `COMMITTED_STOP_MS` |
| F-MOV-03 | air_velocity_step | True law | `AIR_ACCEL`, `AIR_CONTROL_RATIO` |
| F-MOV-04 | jump_arc | True law | `JUMP_VELOCITY`, `GRAVITY` |
| F-MOV-05 | coyote_window | Threshold law | `COYOTE_MS` |
| F-MOV-06 | dash_arc | True law | `DASH_SPEED`, `DASH_MS`, `DASH_COOLDOWN_MS` |
| F-MOV-07 | backdash_arc | True law | `BACKDASH_SPEED`, `BACKDASH_HOP_MS`, `BACKDASH_LOCK_MS`, `BACKDASH_IFRAME_MS` (consumed from SYS-08) |
| F-MOV-08 | wall_jump_arc | True law | `WALL_JUMP_X`, `WALL_JUMP_Y`, `WALL_JUMP_REARM_MS` |
| F-MOV-09 | step_and_slope | Threshold law | `STEP_HEIGHT`, `MAX_SLOPE_DEG`, `SLIDE_SPEED`, `GRAVITY` |
| F-MOV-10 | knockback_arc | True law | `KNOCKBACK_SPEED`, `KNOCKBACK_MAX`, `KNOCKBACK_DECEL`, `KNOCKBACK_MS`, `KNOCKDOWN_MS`, `GETUP_MS`, `power` (power + `KNOCKDOWN_POWER` consumed from SYS-08) |
| F-MOV-11 | crouch_hurtbox | True law | `STAND_HEIGHT`, `CROUCH_HURTBOX_RATIO` |
| F-MOV-12 | stride_ruler | Derived metric | `WALK_SPEED`; F-MOV-04 |
| F-MOV-13 | turn_predicate | Threshold law | `TURN_MIN_ORDER` |
| F-MOV-14 | freeze_integration | True law | — |

#### F-MOV-01 · order_to_target_speed — the ruler (TR-MOV-002)

`target_speed = move_order × WALK_SPEED`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Move order | `move_order` | float | {−1, −`CREEP_RATIO`, 0, +`CREEP_RATIO`, +1} (0.5 at defaults) | SYS-01's band order (F-03) |
| Walk speed | `WALK_SPEED` | float | 180–280 px/s | The stride unit; designer-only |
| Target speed | `target_speed` | float | −280…+280 px/s | Velocity the ground step approaches |

**Output Range:** five discrete values at defaults: **{−230, −115, 0, +115, +230} px/s**. Creep is exactly half a walk; the ratio never drifts with acceleration.

**Example:** order +0.5 held → target 115 px/s; the body ramps to it and stays. A keyboard walk (order +1.0) is 230 px/s.

#### F-MOV-02 · ground_velocity_step — committed approach (TR-MOV-003)

`v_x ← move_toward(v_x, target, a × Δt)`, where

```
a = GROUND_ACCEL        if target ≠ 0
a = GROUND_FRICTION     if target = 0
a = COMMITTED_FRICTION  if body_busy ∧ no Movement-scripted arc
t_stop = min((|v_x| ÷ COMMITTED_FRICTION) × 1000, COMMITTED_STOP_MS)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current velocity | `v_x` | float | −`DASH_SPEED`…+`DASH_SPEED` px/s | Horizontal velocity |
| Target | `target` | float | −280…+280 px/s | F-MOV-01, or 0 while committed |
| Acceleration | `a` | float | 1200–3200 px/s² | Selected by the ordered branch above |
| Tick | `Δt` | float | 1/60 s | Physics tick |
| Stop cap | `COMMITTED_STOP_MS` | int | 100–250 ms | The honest stop while an attack commits |

**Output Range:** `v_x` converges to `target` in `|target − v_x| ÷ a` seconds; release at neutral reaches 0 in ≤ `COMMITTED_STOP_MS`. No instant stops, no overshoot. **Branch order (ordered):** `if body_busy ∧ no scripted arc → COMMITTED_FRICTION; elif target = 0 → GROUND_FRICTION; else → GROUND_ACCEL`. The pair invariant V-MOV-16 guarantees `WALK_SPEED ÷ COMMITTED_FRICTION × 1000 ≤ COMMITTED_STOP_MS` at every legal configuration.

**Example:** running at 230 px/s; an attack commits. `COMMITTED_FRICTION` 1800 → 230 ÷ 1800 = **128 ms** to stop (< 150 ms cap). The attack's arc keeps the body still without Combat owning movement.

#### F-MOV-03 · air_velocity_step — reduced air control (TR-MOV-003)

`v_x ← v_x` if `air_target = 0` **or** (`sign(v_x) = sign(air_target) ∧ |v_x| ≥ |air_target|`); otherwise `v_x ← move_toward(v_x, air_target, AIR_ACCEL × Δt)`, where `air_target = move_order × WALK_SPEED × AIR_CONTROL_RATIO`; there is no air friction at neutral or when the body already exceeds the air target.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Air target | `air_target` | float | −210…+210 px/s | 75% of the ground target at defaults |
| Air acceleration | `AIR_ACCEL` | float | 700–1600 px/s² | Air steering authority |
| Control ratio | `AIR_CONTROL_RATIO` | float | 0.6–0.9 | Deliberate, not twitchy |

**Output Range:** full-order air target = **172.5 px/s** at defaults (75% of walk); a faster same-direction body is preserved (the committed jump), while a slower or opposite-direction body accelerates toward the target. Releasing the stick in air preserves `v_x` — the committed arc.

**Example:** jump at walk (230), hold forward → `v_x` stays 230 (above the 172.5 air target); release → 230 preserved (no air friction) until landing; press back → `v_x` moves toward −172.5 at `AIR_ACCEL`. The jump arc is the commitment.

#### F-MOV-04 · jump_arc — the fixed arc (TR-MOV-012)

`h_max = JUMP_VELOCITY² ÷ (2 × GRAVITY)` · `t_apex = |JUMP_VELOCITY| ÷ GRAVITY` · `t_air = 2 × t_apex` · `d_jump = WALK_SPEED × t_air`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Jump impulse | `JUMP_VELOCITY` | float | 360–500 px/s | Upward velocity on the jump tick |
| Gravity | `GRAVITY` | float | 1000–1600 px/s² | Downward acceleration |
| Apex height | `h_max` | float | 40–125 px (joint extremes); **74.0 at defaults** | Vertical reach |
| Air time | `t_air` | float | 0.45–1.0 s (joint extremes); **0.688 at defaults** | Flat-ground total |
| Jump length | `d_jump` | float | 81–280 px (joint extremes); **158.2 at defaults** | Horizontal reach at walk |

**Output Range:** at 430/1250: **h_max 74.0 px, t_apex 0.344 s, t_air 0.688 s, d_jump 158.2 px** (continuous); the 60-tps semi-implicit fixture is **70.4 px apex, 41–42 ticks air time**. The arc is fixed at MVP (`JUMP_CUT_RATIO = 1.0`). **Hybrid option:** the cut scales **velocity**; height scales as the square — at `r = 0.5` the apex is **0.25 × h_max** (18.5 px), at `r = √0.5 ≈ 0.707` it is **0.5 × h_max** (37.0 px). *Test: at 1.0 release does nothing; at 0.707 the apex halves; the press itself is unaffected.*

**Example:** a 3-tile gap at 16 px/tile = 48 px is trivial; a **9-tile gap (144 px) is inside** a walk-jump (158.2 px continuous / **≈157–161 px discrete**); a **10-tile gap (160 px) is past the edge**. Level design reads the ruler, not a stopwatch.

#### F-MOV-05 · coyote_window — the internal grace (TR-MOV-012)

`coyote_ok = (logic_tick − last_grounded_tick) ≤ coyote_ticks`, `coyote_ticks = ceil(COYOTE_MS × physics_tps ÷ 1000)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Coyote window | `COYOTE_MS` | int | 60–150 ms | Grace after leaving the floor |
| Last grounded tick | `last_grounded_tick` | int | `logic_tick` | Updated while `grounded` |
| Coyote ticks | `coyote_ticks` | int | ≥ 1 | 6 at 100 ms / 60 tps |

**Output Range:** boolean. Boundary: `age = coyote_ticks` is still ok (never-stingy); `+1` is not. The published `grounded` stream never changes (TR-MOV-010).

**Example:** walk off a ledge at tick 1000; jump at 1006 → 6 ≤ 6 → ground jump executes; at 1007 → no.

#### F-MOV-06 · dash_arc — the reposition (TR-MOV-019)

`d_dash = DASH_SPEED × DASH_MS ÷ 1000` · `cooldown_ready = (logic_tick − last_dash_tick) ≥ cooldown_ticks`, `cooldown_ticks = ceil(DASH_COOLDOWN_MS × physics_tps ÷ 1000)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Dash speed | `DASH_SPEED` | float | 360–520 px/s | Horizontal burst |
| Dash duration | `DASH_MS` | int | 160–260 ms | Motion window |
| Dash distance | `d_dash` | float | 60–120 px | `420 × 0.2 = 84 px` |
| Cooldown | `DASH_COOLDOWN_MS` | int | 350–800 ms | Between starts; 30 ticks at 500 ms |
| i-frames | — | — | 0 at MVP | Combat's ruling: none |

**Output Range:** 84 px at defaults; the cooldown is a gate, not a body lock. Off a ledge the dash completes horizontally, then gravity applies.

**Example:** dash from a stand → 84 px in 200 ms; a second dash pressed at 300 ms is ignored; at 500 ms it starts.

#### F-MOV-07 · backdash_arc — the hop (TR-MOV-018)

`d_hop = BACKDASH_SPEED × BACKDASH_HOP_MS ÷ 1000` · `lock_ticks = ceil(BACKDASH_LOCK_MS × tps ÷ 1000)` · `iframe_ticks = ceil(BACKDASH_IFRAME_MS × tps ÷ 1000)` · `exposure_ticks = lock_ticks − iframe_ticks`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Hop speed | `BACKDASH_SPEED` | float | 360–520 px/s | Along `entry_sign` |
| Hop motion | `BACKDASH_HOP_MS` | int | 180–260 ms | Motion window; 220 |
| Hop distance | `d_hop` | float | 65–120 px | `420 × 0.22 = 92.4 px` |
| Lock | `BACKDASH_LOCK_MS` | int | 240–320 ms | Hop + recovery; 280 |
| i-frames | `BACKDASH_IFRAME_MS` | int | 100–180 ms | Combat's grant; 140 |
| Exposure | `exposure_ticks` | int | ≥ 1 | Lock − i-frames; 8 ticks ≈ 133 ms |

**Output Range:** 92.4 px continuous (60-tps semi-implicit fixture: **14 ticks × 7 px = 98 px**), 17-tick lock (283.3 ms effective), 9-tick i-frame window (150 ms effective), **8-tick exposure**. Chained hops can never be continuously invincible. Facing = `−entry_sign` for the hop; the lock is a body_busy locomotion lock.

**Example:** facing right, flick left → `entry_sign = −1`; hop 92.4 px left; facing +1 during the hop; a second backdash inside 283 ms is dropped by the body-free check.

#### F-MOV-08 · wall_jump_arc — the wall answer (TR-MOV-014)

`v_x = −wall_normal_x × WALL_JUMP_X` · `v_y = −WALL_JUMP_Y` · `t_apex_wall = WALL_JUMP_Y ÷ GRAVITY` · `d_x = WALL_JUMP_X × t_apex_wall`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Horizontal impulse | `WALL_JUMP_X` | float | 200–320 px/s | Away from the wall |
| Vertical impulse | `WALL_JUMP_Y` | float | 340–460 px/s | Up |
| Apex time | `t_apex_wall` | float | 0.21–0.46 s (joint extremes); **0.32 at defaults** | Time to apex |
| Horizontal reach | `d_x` | float | 42.5–147.2 px (joint extremes); **83.2 at defaults** | 83.2 px at defaults |

**Output Range:** 83.2 px away, 64 px up (400² ÷ 2500) continuous; the 60-tps fixture is **≈82.3 px**. Wall jump resets on wall touch **after a re-arm gap** (`WALL_JUMP_REARM_MS`, B-fix); it does not refresh the double jump. **A single wall cannot be climbed indefinitely**: the re-arm requires `WALL_JUMP_REARM_MS` off wall contact before the same wall re-arms; a different wall or a ground touch re-arms immediately.

**Example:** a two-wall shaft: jump, wall jump left, wall jump right; each wall touch re-arms the wall jump; the air jump stays spent.

#### F-MOV-09 · step_and_slope — honest edges (TR-MOV-025)

`step_ok = step_height ≤ STEP_HEIGHT` · `slope_ok = slope_deg ≤ MAX_SLOPE_DEG` · if `¬slope_ok`: `a_slide = GRAVITY × sin(deg_to_rad(slope_deg))`, `v_slide = min(v_slide + a_slide × Δt, SLIDE_SPEED)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Step height | `STEP_HEIGHT` | int | 8–16 px | Auto-stair snap; 16 |
| Max slope | `MAX_SLOPE_DEG` | int | 30–50° | Walkable; 45 |
| Slide speed | `SLIDE_SPEED` | float | 80–180 px/s | Steep-slope cap; 120 |
| Gravity | `GRAVITY` | float | 1000–1600 px/s² | Slide acceleration source |
| Slope angle | `slope_deg` | float | 0–90° | From the floor normal |

**Output Range:** steps ≤ 16 px snap up/down; slopes ≤ 45° walk; > 45° slide at ≤ 120 px/s. Crouch-walk uses the same geometry at creep speed.

**Example:** a 16 px stair step is walked up; a 24 px step requires a jump; a 60° slope slides her down at 120 px/s; crouch-walk climbs the 16 px step at 115 px/s.

#### F-MOV-10 · knockback_arc — the hit's body (TR-MOV-021)

`v_kb = min(KNOCKBACK_SPEED × power, KNOCKBACK_MAX)` · `d_kb = v_kb² ÷ (2 × KNOCKBACK_DECEL)` · `knockdown = power ≥ KNOCKDOWN_POWER` · `lock_ms = knockdown ? (KNOCKDOWN_MS + GETUP_MS) : KNOCKBACK_MS` · `lock_ticks = ceil(lock_ms × physics_tps ÷ 1000)`

**Entry rule:** a hit with `power ≥ KNOCKDOWN_POWER` enters **KNOCKDOWN on the hit tick** — the KNOCKBACK phase does not run, and the 1200 ms arc is the whole lock. A hit below the threshold runs KNOCKBACK only. **No re-knockdown:** during KNOCKDOWN or GETUP a further hit applies damage but starts no new lock (Combat may grant getup i-frames).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Hit power | `power` | int | 1–3 | Combat's strike power (consumed at registration) |
| Knockback speed | `KNOCKBACK_SPEED` | float | 180–340 px/s | Per power unit |
| Knockback cap | `KNOCKBACK_MAX` | float | 400–700 px/s | Heavy-hit cap; 520 |
| Knockback decel | `KNOCKBACK_DECEL` | float | 1200–3000 px/s² | 2000; `v_kb` decays to 0 |
| Knockback distance | `d_kb` | float | 8–90 px | 16.9 px at power 1 / 67.6 px at power 2 |
| Knockdown threshold | `KNOCKDOWN_POWER` | int | 1–3 | **Consumed from SYS-08**; 2 |
| Knockback lock | `KNOCKBACK_MS` | int | 120–260 ms | Non-knockdown reaction; 180 |
| Knockdown | `KNOCKDOWN_MS` | int | 350–700 ms | 500 |
| Getup | `GETUP_MS` | int | 500–900 ms | 700 |
| Lock | `lock_ms` | int | ≤ 1200 | `max(KNOCKBACK_MS, KNOCKDOWN_MS + GETUP_MS)` |

**Output Range:** power 1 → 260 px/s, 16.9 px, **180 ms**; power 2 → 520 px/s, 67.6 px, **1200 ms** knockdown+getup; power 3 → capped 520 px/s, 1200 ms. The **1200 ms** is `worst_case_arc_ms` for TR-INP-029. A wall clamps `v_x` to 0 and the lock continues.

**Example:** a heavy hit knocks her 520 px/s into a wall; the wall stops horizontal motion; knockdown 500 + getup 700 = 1200 ms body-busy; an Interact pressed at the hit derives its window from 1200 + margin. A second heavy hit during GETUP deals damage but starts no new lock.

#### F-MOV-11 · crouch_hurtbox — the low read (TR-MOV-016)

`crouch_height = STAND_HEIGHT × CROUCH_HURTBOX_RATIO` · `top_drop = STAND_HEIGHT − crouch_height`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Stand height | `STAND_HEIGHT` | float | 40–48 px | Body hurtbox height |
| Crouch ratio | `CROUCH_HURTBOX_RATIO` | float | 0.5–0.7 | 0.6 |
| Crouch height | `crouch_height` | float | 20–34 px | 26.4 px |
| Top drop | `top_drop` | float | 14–22 px | 17.6 px |

**Output Range:** the crouched hurtbox top drops 17.6 px; the feet stay planted. Combat consumes this to decide high/low attack overlap. **Default high-attack band (contract for SYS-13):** a high attack's lowest active pixel is **> 26.4 px and ≤ 44 px** above the floor — it whiffs the crouched body and connects with the standing body. The GDD does not design enemy moves (SYS-13's); it publishes the band the crouch promises.

**Example:** an enemy high strike whose lowest active pixel is **30 px** above the floor passes over the 26.4 px crouched body but connects with the 44 px standing body. A 20 px strike is a low attack and hits both.

#### F-MOV-12 · stride_ruler — the level-design metric (TR-MOV-002/012)

`walk_length = WALK_SPEED × 1 s` · `jump_length = d_jump` (alias of F-MOV-04's `d_jump`) · `jump_height = h_max` (alias of F-MOV-04's `h_max`)

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Walk length | `walk_length` | float | 180–280 px | One second of walk; 230 px |
| Jump length | `jump_length` | float | 120–190 px | Flat-ground reach; 158.2 px |
| Jump height | `jump_height` | float | 40–100 px | 74.0 px |

**Output Range:** at defaults, a room 3 walk-lengths wide is 690 px; a 10-tile (160 px) gap is a walk-jump edge. Level design uses this ruler; the GDD does not set room sizes (SYS-02's).

**Example:** a 6-room zone at 480×270 art units; a 2-walk-length room = 460 px = ~1 screen width.

#### F-MOV-13 · turn_predicate — when facing flips (TR-MOV-007)

`turn = (sign(move_order) ≠ facing) ∧ (|move_order| ≥ TURN_MIN_ORDER) ∧ ¬scripted`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Move order | `move_order` | float | five values | F-03 |
| Facing | `facing` | int | {−1, +1} | Published value |
| Turn floor | `TURN_MIN_ORDER` | float | `= CREEP_RATIO` (0.5 at defaults) | Creep or walk turns; neutral does not |
| Scripted | `scripted` | bool | {true, false} | A scripted arc owns facing |

**Output Range:** boolean. The press1-induced turn is this predicate's ordinary INPUT_TURN; it is exempt from the backdash reset only via the ADR's cause/epoch rule.

**Example:** facing right, order −1 → turn; order −0.5 → turn; order 0 → no turn; during a HOP → no turn (the hop owns facing).

#### F-MOV-14 · freeze_integration — the clock law (TR-MOV-024)

`if logic_running: position += velocity × (1 ÷ physics_tps)` · `else: position, velocity unchanged`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Logic running | `logic_running` | bool | {true, false} | `context == GAMEPLAY ∧ freeze_sources empty` |
| Velocity | `velocity` | Vector2 | bounded | Current body velocity |
| Tick | `1 ÷ physics_tps` | float | 1/60 s | Fixed |

**Output Range:** a 70 ms hit-stop (4–5 logic ticks) holds position exactly; the hop resumes with its remaining duration; raw publication continues every physics tick.

**Example:** a hop with 13 ticks remaining is hit-stopped for 4 ticks; position freezes; on unfreeze it completes the remaining 13 ticks — the hop is not shortened or extended.

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### Commitments and posture

- **If crouch engages during an attack, hop or dash** → the value is queued (latest wins); posture is applied at the first **grounded** body-free tick. If the raw channel returns to false before that tick, no crouch is applied. [B2: input publishes raw; Movement owns application.]
- **If crouch releases during a commitment** → the release is queued; she stands at the first **grounded** body-free tick. If crouch re-engages before that tick, she stays crouched (latest wins). [One posture order survives, not a queue of orders.]
- **If crouch is held in the air** → the posture is queued; it applies on the first grounded body-free tick. Air crouch is not a stance. [Held states persist; the body applies them when it can.]
- **If she is crouched under a low ceiling and stand is requested** → `BLOCKED_STAND`: she stays crouched, no clip, no error. The state persists until headroom appears; a jump is refused while blocked. [Honest refusal over clipping.]
- **If jump is pressed while crouched** → she stands and jumps on the same tick if headroom exists; if not, the jump is refused with no error and no lost input state (the press expires silently per TR-INP-023). [Jump stands her up — one rule, no mode exceptions.]
- **If crouch+jump is pressed on a one-way floor** → she drops through (`drop_ticks`), then the raw crouch channel governs on landing; the drop is armed only by a crouch whose engage edge occurred while grounded — an air-held crouch that lands jumps normally. On a solid floor the same input is an ordinary jump. [SotN's down-jump; a derived behavior, not a new verb.]
- **If backdash is pulled while crouched** → she stands first (if headroom), then hops; if no headroom, the hop is refused by Movement with `move_refused` (honored but unexecuted, logged separately from input drops). [The hop is a standing motion.]
- **If crouch-walk meets a step > `STEP_HEIGHT`** → she is blocked; a jump is required. [Auto-stairs are a convenience, not a wall-climb.]

### The hop and the dash

- **If the hop meets a wall** → horizontal motion stops at the wall; the lock continues; facing stays `−entry_sign`. [The hop is a commitment, not a bounce.]
- **If the hop leaves a ledge** → horizontal motion continues; gravity applies; the lock continues; landing inside the lock keeps the recovery. [The hop is whole; the ledge does not shorten it.]
- **If the body becomes busy on the completion tick** → the input's body-free check fails; the hop is dropped: still body, no motion, no error. [EX-1's "declined, not misheard".]
- **If the gesture and the a11y direct press land on the same tick** → exactly one `backdash` intent is published; the a11y press wins the payload (`entry_sign = −facing` at the press tick); the gesture machine resets to IDLE; Movement pulls one hop. [ADR-0001 §10's coalesce rule.]
- **If dash is pressed during a hop, or hop during a dash** → dropped; no queue. [Scripted arcs cannot be entered from each other.]
- **If the dash meets a wall** → she stops at the wall; the dash duration/lock continues; no slide. [The dash is a horizontal commitment.]
- **If the dash leaves a ledge** → the dash completes horizontally, then gravity applies; there is no air dash at MVP. [Ground-only by ruling.]
- **If a hit lands during a hop or dash** → the hit wins; the scripted arc is cancelled; the knockback lock applies. If Combat's i-frames cover the tick, the hit is negated first and the arc continues. [Combat owns the hit resolution; Movement owns the body.]
- **If a second heavy hit lands during KNOCKDOWN or GETUP** → damage applies, but no new lock starts (no re-knockdown); Combat may grant getup i-frames. [The 1200 ms arc is whole; stun-lock is shut down.]
- **If dash is pulled with a neutral stick** → it travels along the current facing; a same-tick turn is applied before the first motion tick. [Direction is never ambiguous.]
- **If jump is pulled during the dash motion window** → the dash-jump preserves the dash horizontal velocity into the jump; the remaining dash motion converts to jump momentum. [The unlock's traversal job.]
- **If a backdash is attempted inside its own lock** → the body is busy; the completion check drops it; no input-side cooldown is added. [The lock is the rate; grace is not the post office's.]

### Freeze, gates, death

- **If hit-stop begins mid-hop or mid-dash** → position and velocity are frozen (F-MOV-14); the lock stays published; on unfreeze the arc resumes with its remaining duration. [Freeze is a clock, not a gate.]
- **If a gate opens mid-arc** → the arc dies with the gate; no motion is applied on the transition frame; held states persist; on resume the body is IDLE and nothing is queued. [TR-MOV-029; TR-INP-047(2).]
- **If death lands mid-air or mid-hop** → DISABLED; respawn resets posture, jump counters and locks; facing comes from spawn data with cause SCRIPTED. [Death is SYS-07/15's; Movement only stops.]
- **If pause opens mid-crouch** → held states persist; the raw crouch stream continues; on resume the posture is unchanged. [A gate is not a posture change.]
- **If the game clock is frozen while crouch flips** → the raw channel still publishes; the posture applies at the first unfrozen **grounded** body-free tick. [Publication knows no freeze; application is body-gated.]

### Rigs, geometry, rates

- **If the active rig transfers mid-walk** → the new source's order takes over; velocity continues; no snap; the stride ruler is unchanged. [One body, three rigs.]
- **If the app blurs or focus is lost** → touch-held move/crouch release (EX-3); KB/pad held states persist; Movement consumes the raw stream and takes no side. [An occluded surface's truth is unreadable; hardware truth is not.]
- **If the axis is zero** → target 0; friction; no turn; no hop/dash. [Neutral is an order.]
- **If she is airborne against a wall with no toward-wall order** → no wall slide; ordinary fall. [The wall slide is a deliberate lean, not a magnet.]
- **If a wall jump meets a ceiling** → vertical velocity is zeroed by the collision; horizontal continues; the double jump stays spent. [The wall answer is honest at the boundary.]
- **If a wall jump is attempted on the same wall before the re-arm gap** → it is refused; the wall must be left for `WALL_JUMP_REARM_MS`, or a different wall / ground touch must re-arm. [A single wall is not an infinite ladder.]
- **If a coyote jump is taken after walking off** → it consumes the ground jump, not the air jump; the air jump remains. [Coyote is the ground jump's grace, not a free air jump.]
- **If a buffered jump resolves at the ground→air boundary** → one pull, one jump; the buffer clears at the pull; the same press is never double-consumed. [TR-INP-021 + one jump per press.]
- **If `physics_tps` changes mid-session** → all tick constants recompute from their ms contracts (F-01); arcs preserve ms; no early expiry. [The ms contract is the promise.]

### Degenerate strategies — named and shut down

- **If the player spams backdash for continuous i-frames** → the lock (280 ms) exceeds the i-frame window (140 ms); the 8-tick exposure and the body-free gate make continuous invincibility impossible. [The defensive family's roles stay distinct.]
- **If the player spams crouch to dodge every high** → the 90 ms input guard and the body-free application make crouch a read, not a toggle-spam; crouch-walk is creep-slow. [The guard is the cost.]
- **If the player spams dash** → 500 ms cooldown; no i-frames; dashing into a strike is a hit. [Dash is repositioning, not a dodge.]
- **If the player spams jump** → one ground + one air jump per airtime; wall jump does not refresh the air jump. [The traversal ladder is a ladder, not a flight.]
- **If the player holds the stick into a wall while grounded** → no wall slide (grounded), no auto-climb; facing stays toward the wall. [Wall movement is an air verb.]
- **If the player tries to climb a single wall indefinitely** → the wall-jump re-arm gap (`WALL_JUMP_REARM_MS`) refuses a same-wall re-jump; a two-wall shaft still works. [The ladder is not a flight.]

### Value and config extremes

**Knob validation law (V-MOV).** Every knob value and every pair is validated at config load and re-validated on every live edit (the production resolution is clamp + rate-limited telemetry; dev asserts). A non-fixpoint config is a dev boot failure; production keeps the last good config + telemetry.

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-MOV-01 | `WALK_SPEED > 0` | clamp to range floor | a zero walk breaks the ruler |
| V-MOV-02 | `GROUND_ACCEL`, `GROUND_FRICTION`, `AIR_ACCEL`, `COMMITTED_FRICTION` > 0 | clamp to 1 | division by zero in the step |
| V-MOV-03 | `JUMP_VELOCITY > 0`, `GRAVITY > 0` | clamp to range floor | no arc without both |
| V-MOV-04 | `BACKDASH_LOCK_MS ≥ BACKDASH_HOP_MS + 40` | raise LOCK | the lock must include recovery |
| V-MOV-05 | `BACKDASH_IFRAME_MS < BACKDASH_LOCK_MS` | lower IFRAME to LOCK − 1 tick | exposure ≥ 1 tick; no continuous invincibility |
| V-MOV-06 | `DASH_COOLDOWN_MS ≥ DASH_MS + 150` | raise COOLDOWN | the cooldown must outlast the motion |
| V-MOV-07 | `KNOCKDOWN_MS + GETUP_MS ≤ 5000` | clamp GETUP | TR-INP-029's declared-arc cap |
| V-MOV-08 | `STEP_HEIGHT ≤ 16` (tile height) | clamp | auto-stairs never become a wall-climb |
| V-MOV-09 | `MAX_SLOPE_DEG ≤ 90`, `SLIDE_SPEED > 0` | clamp | geometry sanity |
| V-MOV-10 | `CROUCH_HURTBOX_RATIO ∈ [0.5, 0.7]` | clamp | the crouch must clear a high attack at the default enemy profile |
| V-MOV-11 | `COYOTE_MS ≤ 300` | clamp | coyote must not become a second jump |
| V-MOV-12 | `WALL_JUMP_X > 0`, `WALL_JUMP_Y > 0` | clamp | the wall answer must leave the wall and rise |
| V-MOV-13 | `AIR_CONTROL_RATIO ∈ [0.6, 0.9]` | clamp | air control stays deliberate |
| V-MOV-14 | `JUMP_CUT_RATIO ∈ [0.3, 1.0]` | clamp | 0 would kill the arc; 1 is the fixed default |
| V-MOV-15 | `worst_case_arc_ms = max(BACKDASH_LOCK_MS, DASH_MS, KNOCKBACK_MS, KNOCKDOWN_MS + GETUP_MS, SCRIPTED_MAX_MS)` and `= 1200` at defaults | dev boot failure (fix the declaration) | TR-INP-029's derivation must cover the longest lock |
| V-MOV-16 | `WALK_SPEED ÷ COMMITTED_FRICTION × 1000 ≤ COMMITTED_STOP_MS` | dev boot failure (raise FRICTION or the stop cap) | the committed stop must be true at every legal pair |
| V-MOV-17 | `KNOCKBACK_MS ≤ 1200`, `KNOCKDOWN_MS + GETUP_MS ≤ 1200`, `SCRIPTED_MAX_MS ≤ 1200` | clamp GETUP / SCRIPTED to 1200 | the declared 1200 arc must cover every lock |

- **If `GRAVITY ≤ 0` or `WALK_SPEED ≤ 0`** → clamp to the floor; dev assert; production telemetry. [A degenerate config must not ship a silent wrong motion.]
- **If `CROUCH_HURTBOX_RATIO` is outside its range** → clamp; the crouch must still clear a high attack at the default enemy profile (SYS-13's). [Combat's low/high read depends on it.]
- **If `worst_case_arc_ms` is under-declared** → dev boot failure; the Interact derivation would under-cover a lock. [TR-INP-029's promise is structural.]
- **If `physics_tps ≤ 0`** → conversion asserts (the engine guarantees ≥ 1). [F-01's domain.]

## Dependencies

**Upstream: SYS-01 is the hard dependency; SYS-02 is hard at runtime but undesigned; SYS-16 is soft (grants).**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream | **SYS-01 Input & Control Mapping** | **Hard** — cannot function without orders | In: `move_x` (`raw_axis`, `move_order`), `crouch` (`latch ∨ held_zone`), `jump`/`dash`/`backdash` intents, `jump_held`, the `body_busy` OR · Out: `grounded`, `facing` (`value, epoch, cause, asserted_tick`), `crouch_effective`, `posture_pending`, `move_refused`, locomotion locks, derived `worst_case_arc_ms` (1200 at defaults), consumption acks | GDD UNFROZEN; ADR-0001 Accepted 2026-11-12 |
| Upstream | **SYS-02 Room & World Structure** | **Hard at runtime** | In: collision geometry, one-way floors, stairs, slopes, scripted moves · Out: none (Movement never reads room logic) | GDD not written — PROVISIONAL |
| Upstream | **SYS-16 Progression** | Soft | In: grants Dash (action-level), Wall Jump and Double Jump (behavior-level) · Out: gate state for the HUD | GDD not written — PROVISIONAL |
| Coordination | **SYS-05 Game Flow** | Soft | In: contexts and gate entry · Out: no context state (SYS-05 owns it) | Linear stub |
| Downstream | **SYS-08 Combat** | **Hard** | Out: `facing`/`grounded`/`body_busy`, crouch hurtbox height, knockback execution, hop arc · In: attack/clash/stagger commitments (the locomotion hold), knockback vector/power, i-frame grants, hit-stop pairing | GDD next |
| Downstream | **SYS-07 Health & Damage** | **Hard at hit time** | Out: DISABLED on death · In: HP, damage application, death/respawn | GDD not written — PROVISIONAL |
| Downstream | **SYS-24 HUD** | Soft | Out: state for visuals (grounded, crouch, dash readiness) · In: none — Movement never reads touch geometry | GDD not written |
| Downstream | **SYS-29 Juice & Feedback** | Soft | Out: freeze integration (F-MOV-14); no hit-stop requests at MVP · In: the hit-stop clock | GDD not written |
| Downstream | **SYS-32 Camera & Framing** | Soft | Out: velocity, grounded, facing, wall state, body_busy, hop/knockback events · In: none | GDD last |
| Via Combat | **SYS-13 Enemy AI / SYS-14 Grief-Boss** | Soft | Enemy strike heights and powers are consumed by Combat, never by Movement | GDDs not written |

**Explicit non-dependencies:** SYS-03 Save (Movement has no save data; feel knobs are config, not player progress) · SYS-09/10/11 (world truth changes rendering and mutation, never movement physics at MVP) · SYS-12 Stinger (VS; Movement reads no gestures) · SYS-17/18 (no inventory/economy coupling).

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) SYS-06's row gains ADR-0001 and the contract list; (2) SYS-32's row gains the SYS-06 publication; (3) SYS-08's row gains the Movement commitment/knockback contract; (4) SYS-24's row notes it consumes Movement state but never touch geometry.

## Tuning Knobs

**All Movement knobs are designer-only at MVP.** No player-facing movement settings: the feel is identity, and accessibility lives in SYS-01 (`TOUCH_HIT_SCALE`, `CROUCH_MODE`, `ATTACK_HOLD_REPEAT`, etc.). A future game-speed or assist option would be a separate system, not a Movement knob.

**Knob validation law (V-MOV, Edge Cases):** every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry, dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| Knob | Default | Safe range | Extreme behavior (too low / too high) | Interactions | Rule |
|---|---|---|---|---|---|
| `WALK_SPEED` | 230 px/s | 180–280 | <180: rooms feel cramped, the ruler shrinks · >280: the touch stick feels over-sensitive | `CREEP_RATIO` (SYS-01), level metrics | F-MOV-01 |
| `GROUND_ACCEL` | 1900 px/s² | 1200–2600 | <1200: mushy starts · >2600: twitch-coded | `GROUND_FRICTION` | F-MOV-02 |
| `GROUND_FRICTION` | 2400 px/s² | 1600–3200 | <1600: ice · >3200: instant stop (breaks commitment) | `GROUND_ACCEL` | F-MOV-02 |
| `AIR_ACCEL` | 1100 px/s² | 700–1600 | <700: air control feels dead · >1600: air steering ≈ ground | `AIR_CONTROL_RATIO` | F-MOV-03 |
| `AIR_CONTROL_RATIO` | 0.75 | 0.6–0.9 | <0.6: jumps feel locked · >0.9: air = ground, the arc loses weight | `AIR_ACCEL` | F-MOV-03 |
| `COMMITTED_FRICTION` | 1800 px/s² | 1200–2600 | <1200: she slides during attacks · >2600: the stop is instant | `COMMITTED_STOP_MS` | F-MOV-02 |
| `COMMITTED_STOP_MS` | 150 | 100–250 | <100: abrupt · >250: attack drift | `COMMITTED_FRICTION` | F-MOV-02 |
| `GRAVITY` | 1250 px/s² | 1000–1600 | <1000: floaty · >1600: heavy, short arcs | `JUMP_VELOCITY`, `TERMINAL_VELOCITY` | F-MOV-04 |
| `TERMINAL_VELOCITY` | 900 px/s | 700–1200 | <700: long falls capped early · >1200: pit deaths are fast | `GRAVITY` | F-MOV-04 (fall cap) |
| `JUMP_VELOCITY` | 430 px/s | 360–500 | <360: 40 px apex — gaps shrink · >500: 100 px apex — rooms break | `GRAVITY`, `STEP_HEIGHT` | F-MOV-04 |
| `COYOTE_MS` | 100 | 60–150 | <60: ledge jumps feel unfair · >150: near-second-jump | `JUMP_VELOCITY` | F-MOV-05 |
| `JUMP_CUT_RATIO` | 1.0 (fixed) | 0.3–1.0 | 0.3: a velocity cut leaves 9% height · 1.0: fixed SotN arc | hybrid option | TR-MOV-011 |
| `WALL_SLIDE_SPEED` | 120 px/s | 80–180 | <80: sticky · >180: barely a slide | `WALL_JUMP_Y` | TR-MOV-014 |
| `WALL_JUMP_X` | 260 px/s | 200–320 | <200: can't leave the wall · >320: overshoots ledges | `WALL_JUMP_Y` | F-MOV-08 |
| `WALL_JUMP_Y` | 400 px/s | 340–460 | <340: no height gain · >460: wall-climb trivializes | `WALL_SLIDE_SPEED` | F-MOV-08 |
| `WALL_JUMP_REARM_MS` | 250 | 150–400 | <150: a single wall becomes a ladder · >400: a two-wall chain feels sticky | wall contact, `WALL_JUMP_Y` | TR-MOV-014 |
| `DASH_SPEED` | 420 px/s | 360–520 | <360: not a burst · >520: overshoots rooms | `DASH_MS` | F-MOV-06 |
| `DASH_MS` | 200 | 160–260 | <160: blink · >260: a walk | `DASH_COOLDOWN_MS` | F-MOV-06 |
| `DASH_COOLDOWN_MS` | 500 | 350–800 | <350: dash-spam · >800: the ability feels lost | `DASH_MS` | F-MOV-06 |
| `BACKDASH_SPEED` | 420 px/s | 360–520 | <360: not a dodge · >520: teleport | `BACKDASH_HOP_MS` | F-MOV-07 |
| `BACKDASH_HOP_MS` | 220 | 180–260 | <180: no distance · >260: long float | `BACKDASH_LOCK_MS` | F-MOV-07 |
| `BACKDASH_LOCK_MS` | 280 | 240–320 | <240: hop-spam · >320: the dodge feels punished | `BACKDASH_IFRAME_MS` (SYS-08) | F-MOV-07 |
| `KNOCKBACK_SPEED` | 260 px/s | 180–340 | <180: hits feel weightless · >340: pinball | `KNOCKBACK_MAX` | F-MOV-10 |
| `KNOCKBACK_MAX` | 520 px/s | 400–700 | <400: heavies don't read · >700: off-screen | `KNOCKBACK_SPEED` | F-MOV-10 |
| `KNOCKBACK_DECEL` | 2000 px/s² | 1200–3000 | <1200: knockback slides · >3000: the hit stops dead | `KNOCKBACK_SPEED` | F-MOV-10 |
| `KNOCKBACK_MS` | 180 | 120–260 | <120: no reaction · >260: stun-lock | `KNOCKDOWN_MS` | F-MOV-10 |
| `KNOCKDOWN_MS` | 500 | 350–500 | <350: no weight · >500: the 1200 arc is breached | `GETUP_MS` | F-MOV-10 |
| `GETUP_MS` | 700 | 500–700 | <500: pop-up · >700: the 1200 arc is breached | `KNOCKDOWN_MS` | F-MOV-10 |
| `SCRIPTED_MAX_MS` | 1200 | 500–1200 | <500: scripted moves truncate · >1200: the declared arc is breached (make it a gate) | `worst_case_arc_ms` | TR-MOV-022 |
| `STAND_HEIGHT` | 44 px | 40–48 | <40: crouch barely differs · >48: the crouch read breaks | `CROUCH_HURTBOX_RATIO` | F-MOV-11 |
| `CROUCH_HURTBOX_RATIO` | 0.6 | 0.5–0.7 | <0.5: crouch too strong · >0.7: high attacks still hit | `STAND_HEIGHT`, SYS-13 heights | F-MOV-11 |
| `STEP_HEIGHT` | 16 px | 8–16 | <8: stairs need jumps · >16: wall-climb | tile grid | F-MOV-09 |
| `MAX_SLOPE_DEG` | 45° | 30–50 | <30: most slopes slide · >50: walls become walkable | `SLIDE_SPEED` | F-MOV-09 |
| `SLIDE_SPEED` | 120 px/s | 80–180 | <80: sticky · >180: slide dominates | `MAX_SLOPE_DEG` | F-MOV-09 |
| `DROP_THROUGH_MS` | 200 | 120–300 | <120: may not clear · >300: falls through multi-layer | one-way floors | TR-MOV-026 |
| `TURN_MIN_ORDER` | `= CREEP_RATIO` (SYS-01; 0.5 at defaults) | derived | below CREEP_RATIO: creep cannot turn · above: creep turns (unstable) | F-03 | F-MOV-13 |

**Cross-system inputs (consumed at registration — not Movement knobs, but validated by Movement):** `CREEP_RATIO` (SYS-01's F-03 order magnitude; Movement derives `TURN_MIN_ORDER` from it) · `BACKDASH_IFRAME_MS` (SYS-08's defensive grant; validated `∈ [100, 180]` and `< BACKDASH_LOCK_MS` at registration) · `KNOCKDOWN_POWER` (SYS-08's hit rule; validated `∈ [1, 3]`) · `power` (per-hit, from Combat) · `physics_tps` (engine; F-MOV-05/06/07 parameterize by it; AC-MOV-27 tests the recompute). A missing or invalid cross-system input is a dev boot failure, never a silent default.

**Not knobs (documented so nobody adds them):** `worst_case_arc_ms` (derived max of the locks, validated 1200) · `facing`, `body_busy`, `grounded`, `crouch_effective`, `posture_pending` (published states, not values) · the audited layout table and the movement-zone rect (SYS-01's).

**Provisional lifetimes:** `CROUCH_HURTBOX_RATIO` + `STAND_HEIGHT` (SYS-13 enemy height profiles) · `STEP_HEIGHT` / `MAX_SLOPE_DEG` (SYS-02 geometry) · `KNOCKDOWN_MS` / `GETUP_MS` (SYS-07 hit reaction) · the Wall Jump / Double Jump arcs (playtest).

## Visual/Audio Requirements

*(Movement names the states and event edges; rendering is SYS-24's, VFX/audio design is SYS-29/SYS-04's.)*

- **Animation states:** idle, walk, creep-walk, crouch-idle, crouch-walk, jump-rise, jump-fall, land, wall-slide, wall-jump, dash, backdash-hop, knockback, knockdown, getup, blocked-stand. The locomotion cycle is speed-keyed to `v_x` (walk vs creep); the crouch pose is a stance, not a squash.
- **Silhouette-first:** crouch lowers the top silhouette by `top_drop` (17.6 px default) so the high/low read is legible at 32 px; the backdash hop keeps the front-facing silhouette (she faces the threat).
- **Telegraph doctrine:** dust/landing/slide VFX use color-flash + shape, never opacity pulses; 2 px value separation from backdrops; no screen-space effects owned by Movement (SYS-29).
- **VFX hooks (SYS-29 designs):** landing dust, dash streak, hop afterimage, wall-slide sparks, knockdown impact. Movement emits the event edges only.
- **Audio events (SYS-04 designs):** footstep cadence keyed to speed; jump/land; dash whoosh; hop; wall-slide loop; knockdown/getup. No per-press popups.
- **No Movement-owned UI or VFX:** the glitch transition, hit sparks and camera shake are SYS-29/SYS-32.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:movement` for per-asset descriptions, dimensions and generation prompts.

## UI Requirements

**None of its own.** Movement has no screen, menu or HUD element. The Dash socket is SYS-01's (dormant-visible) and SYS-24's (rendering); the crouch/dash state may be read by the HUD for feedback, but the HUD never consumes touch geometry from Movement. **No UX flag.**

## Acceptance Criteria

**Classification legend:** `[GUT]` automatable in Godot Unit Test · `[DEVICE]` on-device manual QA · `[PLAYTEST]` human feel observation with the SYS-01 trust rubric. Dual tags mean the GUT half gates first, the DEVICE half confirms.

### The movement contract

- **AC-MOV-01** [GUT] *(TR-MOV-001)* — **(a)** the same `CapturedEvent` stream through `InputCore → InputBus` and through a scripted axis provider produces **bit-identical position traces** over 600 ticks (tolerance 0, fixed `BodyPort` fixture); **(b)** a 30 s human capture replayed through the same fixture diverges by ≤ 1 tick from the live run (cite SYS-01 AC-07/AC-55); **(c)** `src/movement/` contains **zero** `Input.` symbols (CI grep).
- **AC-MOV-02** [GUT] *(TR-MOV-002, F-MOV-01)* — **GIVEN** a 2 s hold at `move_order = CREEP_RATIO`, **WHEN** velocity converges, **THEN** steady-state speed is exactly `CREEP_RATIO × WALK_SPEED` ± 1 px/s (0.5 × walk at defaults); a 1.0 order is exactly `WALK_SPEED`.
- **AC-MOV-03** [GUT] *(TR-MOV-003, F-MOV-02)* — **GIVEN** a run at walk speed, **WHEN** a Combat commitment raises `body_busy`, **THEN** target speed becomes 0 and velocity reaches 0 within `COMMITTED_STOP_MS` at **defaults and at the corner (WALK_SPEED 280 / COMMITTED_FRICTION 1200 / stop 250)**, monotonic, with no overshoot or reversal; releasing the stick at neutral also reaches 0 without reversing.
- **AC-MOV-04** [GUT] *(TR-MOV-012, TR-MOV-032, F-MOV-04)* — **GIVEN** a flat-ground ground jump at 60 tps, **WHEN** the semi-implicit arc is integrated, **THEN** the apex is **70.4 px ± 1 px**, air time is **41–42 ticks**, and horizontal reach at walk is **157–161 px** (continuous design intent 74.0 px / 0.688 s; the discrete fixture governs).
- **AC-MOV-05** [GUT] *(TR-MOV-011)* — **GIVEN** `JUMP_CUT_RATIO = 1.0`, **WHEN** jump is released mid-rise, **THEN** the arc is unchanged; **GIVEN** `r = 0.5`, **WHEN** released on the jump tick, **THEN** the apex is **0.25 × h_max (18.5 px ± 1)**; **GIVEN** `r = √0.5 ≈ 0.707`, **THEN** the apex is **0.5 × h_max (37.0 px ± 1)**; the press/consumption is unaffected in every case.
- **AC-MOV-06** [GUT] *(F-MOV-05)* — **GIVEN** a walk off a ledge, **WHEN** jump is pressed at `coyote_ticks` and at `coyote_ticks + 1`, **THEN** the first executes a ground jump and the second does not.
- **AC-MOV-07** [GUT] *(TR-MOV-012)* — **GIVEN** a jump press 60 ms before landing, **WHEN** the body lands, **THEN** exactly one jump executes on the landing tick; the buffer clears at the pull and the same press never fires again.
- **AC-MOV-08** [GUT] *(TR-MOV-010)* — **GIVEN** coyote toggled between 0 and 100 ms, **WHEN** the same ledge-walk trace runs, **THEN** the published `grounded` stream is bit-identical in both runs while the jump behavior differs.

### Facing

- **AC-MOV-09** [GUT] *(TR-MOV-006/007)* — **GIVEN** a facing publication trace, **WHEN** she turns from a back flick, **THEN** the publication carries `INPUT_TURN`, the epoch increments once, `changed_tick` is within 2 ticks of press1, and a neutral stick never produces a turn.
- **AC-MOV-10** [GUT] *(TR-MOV-008)* — **GIVEN** an armed backdash machine, **WHEN** a knockback flip occurs, **THEN** the machine resets to IDLE; **WHEN** the hop's own HOP flip occurs, **THEN** the machine is already IDLE and does not re-enter; a wall jump publishes `WALL_TURN`.

### Jump, wall, crouch

- **AC-MOV-11** [GUT] *(TR-MOV-014, F-MOV-08)* — **GIVEN** Wall Jump unlocked and airborne against a wall, **WHEN** the stick points away from the wall, **THEN** no slide occurs; **WHEN** it points toward the wall, **THEN** she slides at `WALL_SLIDE_SPEED`; a wall jump reaches **≈82.3 px** horizontally at 60 tps (continuous 83.2 px) and 64 px vertically, and the air jump stays spent; **a same-wall re-jump before `WALL_JUMP_REARM_MS` is refused**.
- **AC-MOV-12** [GUT] *(TR-MOV-015)* — **GIVEN** ground → air jump → wall jump, **WHEN** jump is pressed again in the air, **THEN** no second air jump executes; landing restores exactly one air jump.
- **AC-MOV-13** [GUT] *(TR-MOV-016)* — **GIVEN** crouch engaged at tick T during an attack, **WHEN** the attack's commitment ends, **THEN** the posture is applied on the **first tick where `body_busy` is false at Movement's read phase** (T+1's tick-open snapshot after a lock ending at T), not during the arc; **GIVEN** crouch released before that tick, **THEN** no crouch is applied.
- **AC-MOV-14** [GUT] *(TR-MOV-016)* — **GIVEN** the raw crouch channel true for exactly **1 tick**, **WHEN** Movement consumes it, **THEN** no posture change occurs and the body remains STANDING; **GIVEN** true at the engage tick, **THEN** posture applies at the first grounded body-free tick. (The guard itself is SYS-01 AC-31's; Movement consumes the post-guard boolean.)
- **AC-MOV-15** [GUT] *(TR-MOV-016, F-MOV-11)* — **GIVEN** a crouch-walk at full order, **WHEN** speed settles, **THEN** it is exactly `CREEP_RATIO × WALK_SPEED` (0.5 × walk at defaults); the crouched hurtbox top is `STAND_HEIGHT × (1 − CROUCH_HURTBOX_RATIO)` = 17.6 px lower than standing.
- **AC-MOV-16** [GUT] *(TR-MOV-016)* — **GIVEN** a low ceiling and a stand request, **WHEN** headroom is insufficient, **THEN** the state is `BLOCKED_STAND`, the body does not clip, and a jump is refused with no error; **WHEN** headroom appears, **THEN** she stands.
- **AC-MOV-17** [GUT] *(TR-MOV-026)* — **GIVEN** a one-way floor and a grounded-armed crouch, **WHEN** jump is pressed, **THEN** she drops through for `drop_ticks`, the raw crouch channel governs on landing; an air-held crouch that lands jumps normally; on a solid floor the same input jumps.

### Hop, dash, knockback

- **AC-MOV-18** [GUT] *(TR-MOV-018, F-MOV-07)* — **GIVEN** a fired backdash intent with `entry_sign = −1`, **WHEN** the hop executes at 60 tps, **THEN** she travels **98 px** (14 ticks × 7 px; continuous 92.4 px), `facing = +1` for the hop's duration (cause HOP), the lock is **17 ticks (283.3 ms effective)**, and a second hop inside the lock is dropped; on the a11y path (no press1 turn) the value is unchanged and HOP is a cause re-assertion with the epoch unchanged.
- **AC-MOV-19** [GUT] *(TR-MOV-018/020)* — **GIVEN** a body busy at the completion tick, **WHEN** the intent completes, **THEN** no hop motion occurs, no `body_busy` raise occurs, no error is raised, and the body remains still; the drop is a **dev-only trace field, not a publication** (SYS-01 AC-39's "the drop publishes nothing"). **GIVEN** a free body with no headroom, **THEN** the hop is pulled and refused with `move_refused {verb, reason}` — a Movement-side refusal, logged separately from input drops.
- **AC-MOV-20** [GUT] *(TR-MOV-019, F-MOV-06)* — **GIVEN** Dash unlocked, **WHEN** it is pulled, **THEN** she travels **84 px in 12 ticks**; a second start before 500 ms is ignored; **the publication schema contains no i-frame field** (static assertion — the grant is SYS-08's); **pre-unlock the same press executes nothing and errors nowhere**; the dash direction follows the published facing (a same-tick turn applies first; neutral uses the current facing); a jump pulled during the dash motion window preserves the dash horizontal velocity (dash-jump).
- **AC-MOV-21** [GUT] *(TR-MOV-019)* — **GIVEN** a crouched body with headroom, **WHEN** Dash is pulled, **THEN** she stands on the dash's first tick and dashes; without headroom the dash is refused with `move_refused` and no motion occurs.
- **AC-MOV-22** [GUT] *(TR-MOV-021, F-MOV-10)* — **GIVEN** a power-1 hit, **WHEN** knockback applies, **THEN** velocity is 260 px/s, `d_kb = 16.9 px`, and the lock is 180 ms (11 ticks); **GIVEN** power 2, **THEN** the hit enters KNOCKDOWN on the hit tick (no KNOCKBACK phase), velocity is 520 px/s, `d_kb = 67.6 px`, and the lock is **1200 ms (72 ticks)**; a wall clamps horizontal motion and the lock continues; a second heavy hit during GETUP deals damage but starts no new lock; the derived `worst_case_arc_ms` equals 1200.
- **AC-MOV-23** [GUT] *(TR-MOV-022)* — **GIVEN** every Movement lock, **WHEN** it starts and ends, **THEN** `body_busy` is true on `start_tick` through `end_tick−1` and false on `end_tick`; the set equals the state table's `body_busy = yes` rows (including KNOCKBACK and `freeze_hold`); a hit-stop inside the lock does not clear it; the declaration equals the derived max (1200 at defaults).
- **AC-MOV-24** [GUT] *(TR-MOV-024, F-MOV-14)* — **GIVEN** a hop with 13 ticks remaining, **WHEN** a 4-tick hit-stop begins, **THEN** position and velocity are frozen for 4 ticks, the lock stays published, and the hop resumes with 13 ticks remaining; raw publication continues every physics tick.
- **AC-MOV-25** [GUT] *(TR-MOV-029)* — **GIVEN** a dash in progress, **WHEN** a gate opens, **THEN** no motion is applied on the transition frame, the arc dies, and on resume the body is IDLE with nothing queued.
- **AC-MOV-26** [GUT] *(TR-MOV-025, F-MOV-09)* — **GIVEN** default tuning, **WHEN** she walks into a 16 px stair step, **THEN** she snaps up; a 24 px step blocks; a 45° slope walks; a 60° slope slides at ≤ 120 px/s; crouch-walk traverses the 16 px step at creep speed; walk/slide/wall is classified by the floor normal (≤ `MAX_SLOPE_DEG` walk, (`MAX_SLOPE_DEG`, `floor_max_angle`] slide, > `floor_max_angle` wall).
- **AC-MOV-27** [GUT] *(F-MOV-14, SYS-01 F-01)* — **GIVEN** a mid-session `physics_tps` change, **WHEN** all tick constants recompute from their ms contracts, **THEN** no arc expires early or overstays from the rate event alone.
- **AC-MOV-28** [GUT] *(V-MOV-01…17)* — **GIVEN** each knob at its low and high extremes, **WHEN** config validation runs, **THEN** single-knob invariants clamp to the safe range, pair invariants adjust the **named counterpart** (LOCK, IFRAME, COOLDOWN, GETUP, HYST), V-MOV-15/16/17 are dev boot failures (not clamps), and production keeps the last good config + telemetry.
- **AC-MOV-29** [GUT] *(TR-MOV-031)* — **GIVEN** a scripted axis/press trace, **WHEN** it is replayed twice through `MotionCore` with a fixed `BodyPort` fixture, **THEN** the two velocity/state traces are bit-identical and the position traces are equal under the same fixture.
- **AC-MOV-30** [GUT + DEVICE] *(TR-MOV-031)* — **(GUT)** a static audit finds no allocation calls in the per-tick path, and a 10,000-tick soak under the SYS-01 AC-54 monitors shows zero net object/resource delta and bounded churn for the named structures (capture-free motion core, lock set, timers). **(DEVICE)** on the QA plan §5.1 reference SKU, after a 600-tick warm-up, 10,000 ticks of workload **W11** (walk → jump → crouch-walk → hop → dash → knockback cycle) give nearest-rank **p99.9 ≤ 0.3 ms, max ≤ 1.0 ms** per physics tick; the combined SYS-01 + Movement tick budget is ≤ 2.0 ms p99.9 / ≤ 4.0 ms max.
- **AC-MOV-31** [GUT] *(TR-MOV-001/022)* — **GIVEN** a Combat mock, **WHEN** it publishes an attack commitment, **THEN** the locomotion hold engages; the mock **records the hurtbox height it read**, and Movement asserts the published value equals F-MOV-11's `crouch_effective`; a `KnockbackOrder {dir, power}` is executed; the `body_busy` OR reflects both publishers.
- **AC-MOV-32** [GUT + DEVICE] *(TR-MOV-018)* — **(GUT)** 20 body-free intents → exactly one hop each, direction = `entry_sign`, `facing = −entry_sign` for the hop; 20 intents completing busy → zero hops, zero errors, drop is a dev trace. **(DEVICE)** on the QA plan §7.1 matrix, the SYS-01 gesture trace's intents produce a hop count equal to the body-free subset (gesture production is SYS-01 AC-38/39/64's).

### Device and playtest

- **AC-MOV-33** [DEVICE] *(TR-MOV-016)* — **GIVEN** crouch hold and crouch toggle on touch, **WHEN** each is used under an attack commitment, **THEN** the posture applies at the first **grounded** body-free tick and never pops mid-arc.
- **AC-MOV-34** [GUT + DEVICE] *(TR-MOV-001)* — **(GUT)** injecting `move_order = +1 / +CREEP_RATIO / 0 / −CREEP_RATIO / −1` produces target speeds `+WALK_SPEED / +CREEP_RATIO×WALK_SPEED / 0 / −CREEP_RATIO×WALK_SPEED / −WALK_SPEED`; the consumer never reads the stick. **(DEVICE)** the debug order readout matches the injected order on the device matrix; the stick's own producibility is SYS-01 AC-27/34's.
- **AC-MOV-35** [PLAYTEST] *(Player Fantasy)* — **GIVEN** 5 playtesters × 30 min (two facilitators, the SYS-01 AC-63 coding and per-statement kappa protocol), **WHEN** the trust-rubric interview codes **Q5 distance language**, **Q6 jump feel**, **Q7 crouch stance**, **Q8 hop-keeps-the-enemy-in-view**, **THEN** each code reaches ≥3/5: Q5 uses walk-lengths/jump-arcs unprompted; Q6 contains zero floaty/laggy attributions; Q7 describes the crouch as a stance and can explain a late crouch; Q8 describes the hop as a dodge that keeps the enemy in view.
- **AC-MOV-36** [PLAYTEST] *(TR-MOV-013)* — **GIVEN** the same 5 × 30 min cohort reaching the Dash unlock, **WHEN** the interview codes **Q9 promise-kept** and **Q10 gate-earned**, **THEN** each reaches ≥3/5; the "no new button" and "no dual-purpose press" claims are **GUT registry audits** (AC-MOV-40 and SYS-01 AC-02), not playtest observations.

### Traceability and contract-edge ACs

- **AC-MOV-37** [GUT] *(TR-MOV-004/005)* — **GIVEN** a knob edit at runtime, **WHEN** the same scripted trace runs, **THEN** the behavior changes with no code edit; **GIVEN** a long fall, **THEN** `TERMINAL_VELOCITY` caps the fall and landing snaps without a one-tick bounce.
- **AC-MOV-38** [GUT] *(TR-MOV-009/006)* — **GIVEN** boot with spawn facing −1, **WHEN** the first publication is read, **THEN** value = −1, cause = SCRIPTED, epoch = 0; a 600-tick trace shows 600 assertions; **GIVEN** facing withheld, **THEN** the backdash detector disables itself with a dev assert.
- **AC-MOV-39** [GUT] *(TR-MOV-017/027)* — **GIVEN** a crouch-walk, **THEN** `body_busy` is false; **GIVEN** the Movement build, **THEN** it contains zero touch-region symbols and the audited layout table is unchanged by Movement tuning.
- **AC-MOV-40** [GUT] *(TR-MOV-028/030)* — **GIVEN** a camera mock, **WHEN** it consumes the publication, **THEN** it reads velocity/grounded/facing/wall state/body_busy without reaching into Movement; **GIVEN** the registry, **THEN** a crouch+jump drop-through, a crouch attack and a wall jump add zero registry entries (no ninth body verb).
- **AC-MOV-41** [GUT] *(F-MOV-03/12/13)* — **GIVEN** a jump at walk, **WHEN** the stick is released at apex, **THEN** `v_x` is preserved (no air friction); **GIVEN** default tuning, **THEN** `walk_length = 230 px` and `jump_length = 158 px`; **GIVEN** the turn predicate, **THEN** a creep or walk order against facing turns, neutral does not.
- **AC-MOV-42** [GUT] *(OQ-M1)* — **GIVEN** neutral → slow back order −0.5 → −1.0 over 4 ticks, **WHEN** the trace runs (after the SYS-01 press1-creep amendment), **THEN** exactly one hop fires left; **GIVEN** the unamended walk-band press1, **THEN** the trace is a recorded xfail until the amendment lands.
- **AC-MOV-43** [GUT] *(TR-MOV-016)* — **GIVEN** crouch+attack pulled on the same tick, **WHEN** the attack's first active tick runs, **THEN** `crouch_effective` is CROUCHING and the hurtbox is crouched; the raw selection snapshot still records `crouching = true`.
- **AC-MOV-44** [GUT] *(TR-MOV-023)* — **GIVEN** an idle body, **WHEN** a `logic_running == false` interval begins with no other lock, **THEN** `freeze_hold` is published for the interval; the backdash detector sees `body_busy` at a mid-freeze completion and drops.
- **AC-MOV-45** [GUT] *(TR-MOV-019)* — **GIVEN** facing right and a neutral stick, **WHEN** dash is pulled, **THEN** it travels right; **GIVEN** a same-tick left order, **THEN** the turn publishes before the first motion tick and the dash travels left; **GIVEN** a jump during the dash motion, **THEN** the dash-jump preserves the dash `v_x` and the reach exceeds a walk-jump.
- **AC-MOV-46** [GUT] *(TR-MOV-021/026)* — **GIVEN** a second heavy hit during GETUP, **THEN** damage applies and no new lock starts; **GIVEN** an air-held crouch that lands on a one-way floor, **WHEN** jump is pressed, **THEN** it is an ordinary jump (the drop was not armed).
- **AC-MOV-47** [GUT] *(TR-MOV-018/019)* — **GIVEN** a free body with no headroom, **WHEN** a hop or dash is pulled, **THEN** `move_refused {verb, reason}` is published and no motion occurs; the refusal is logged separately from an input drop.
- **AC-MOV-48** [GUT] *(TR-MOV-022)* — **GIVEN** a power-1 hit, **THEN** KNOCKBACK raises `body_busy` for 180 ms; **GIVEN** the lock-arc knobs at their maxima, **THEN** the derived `worst_case_arc_ms` equals the max and V-MOV-15/17 pass; a legal pair that would exceed 1200 is a dev boot failure.
- **AC-MOV-49** [GUT] *(TR-MOV-014)* — **GIVEN** a single wall, **WHEN** she wall-jumps and re-contacts the same wall before `WALL_JUMP_REARM_MS`, **THEN** the re-jump is refused; **GIVEN** a different wall or a ground touch, **THEN** the wall jump re-arms immediately.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **Movement Architecture ADR** — CharacterBody2D wiring, floor-snap/slope/one-way probes, wall detection, **the body phase** (integrate after publish, before the next snapshot; a hop pulled at T moves at T), **`MotionCore` + `BodyPort` seam**, **floor-normal classification** (walk/slide/wall; `floor_max_angle`, `floor_snap_length`, `floor_stop_on_slope`, `up_direction`), the one-way layer scheme, freeze integration, knockback integration, test seams | technical-director + gameplay-programmer | Before the first implementation story |
| 2 | Moving platforms / carriers — does SYS-02 need them at MVP? If yes, a carrier velocity contract is required | SYS-02 + SYS-06 | At SYS-02 authoring |
| 3 | Ladders — not in the eight verbs; if SYS-02 needs them, they are a derived climb (no new verb) | SYS-02 + game-designer | At SYS-02 authoring |
| 4 | Water/swim — out of MVP scope; if added, a new movement state | game-designer | Post-MVP |
| 5 | Wall-jump availability — all walls vs tagged walls | SYS-02 + SYS-06 | At SYS-02 authoring |
| 6 | Crouch hurtbox vs SYS-13's high/low attack heights — the default profile must clear the 17.6 px drop | SYS-13 + SYS-08 | At SYS-13 authoring |
| 7 | Dash i-frames at VS — Combat's defensive-family ruling | SYS-08 | At Combat GDD / VS |
| 8 | Backdash hop off a ledge with i-frames — Combat's grant; Movement executes | SYS-08 | At Combat GDD |
| 9 | Game-speed / assist options — future system, not a Movement knob | accessibility-specialist | VS |
| 10 | Double-jump relic VFX / Leap-Stone moment — SYS-29 + art | SYS-29 | At Juice authoring |
| 11 | **OQ-M1 — SYS-01 press1-creep amendment**: the true-back press1 must be the first back-direction **creep** entry (not the walk band), with the true-back check reading facing before it; otherwise a slow flick turns her before the arming entry and never arms. One-clause SYS-01 amendment; AC-MOV-42 is the xfail trace | SYS-01 + SYS-06 | Before the first SYS-06 implementation story |
| 12 | **OQ-M2 — ADR-0001 §10 cadence erratum**: §10 says `facing` re-asserts every `logic_tick`; R3/§8 say every `physics_tick`. This GDD follows R3/§8 (raw every `physics_tick`, value/epoch on `logic_tick`); the ADR needs the one-line erratum | technical-director | With the Movement ADR |
| 13 | **OQ-M3 — `posture_pending` cue**: how SYS-24 shows a queued crouch (stance lean, HUD pip) so the player can tell "will crouch when it can" from "lost" | SYS-24 + ux-designer | At HUD authoring |
| 14 | **OQ-M4 — dash-jump gap budget**: the dash-jump preserves 420 px/s into a 0.688 s arc (≈289 px theoretical); level design must set the unlock's gap budget against the walk-jump's 158 px | SYS-06 + level-designer | Playtest |
