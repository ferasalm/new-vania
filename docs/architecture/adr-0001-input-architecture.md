# ADR-0001: Input Architecture — Capture, Tick Pipeline, Gates, and the D1 Render Model

## Status

**Accepted** — accepted 2026-11-12 against the SYS-01 GDD's #10 unfreeze record
(`PASS WITH RECORDED OBLIGATIONS`; review loop closed at #10). Acceptance ratifies
the five laws and owns the four mechanisms named in the GDD's unfreeze sequencing;
the engine-probe register below remains a **pre-implementation gate** (AC-74), not
an ADR-status gate. If a later architecture review finds a contradiction with a
newer Accepted ADR, this ADR reverts to `Proposed` and is superseded explicitly.

## Date

2026-11-12

## Last Verified

2026-11-12 — verified against Godot 4.7.2 engine-reference snapshots and the
SYS-01 GDD at Main `af39307` (the #10 record).

2026-11-13 — §10 cadence erratum applied (Movement OQ-M2): `facing` re-asserts
raw every `physics_tick` (R3/§8); the section's original "every `logic_tick`"
wording corrected. No decision changes; the FacingPublication contract is
untouched.

## Decision Makers

| Seat | Role in this decision |
|---|---|
| technical-director | Acceptance chair; architectural coherence and ADR dependency ruling |
| gameplay-programmer | Pipeline, buffer, gates, touch dispatcher, test seams |
| godot-specialist | Engine-API verdicts, D1 SubViewport wiring, verification register |
| qa-lead | Gate manifest, 96-unit ledger, O1/AC-65 protocol, evidence paths |
| user | Scope authority; approval of the accepted record |

The engine-probe spike referenced below is a **throwaway prototype**: its scenes,
scripts and measurements are evidence only. No probe code is imported into `src/`,
and the probe is not a dependency of any story.

## Summary

Godot 4.7.2's default input, pause and stretch models cannot satisfy SYS-01's
first-`logic_tick` stamping law, raw-state publication law, gate-request terminality,
or the D1 render model, so this ADR pins one `_input` capture path, a
`_physics_process` pipeline with an explicit `logic_tick`/`physics_tick` split and a
manual freeze, an atomic offer–pull–ack service, a dispatcher-owned touch surface,
and a root-stretch-disabled `SubViewport` world band with a native-resolution HUD.
It ratifies the five GDD laws, owns the D1 wiring, flip-attribution,
mirror/reach-disc mechanism and pipeline order, and carries obligation **O1**
(AC-18's stamp-budget head vs its parenthetical).

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.7.2 (pinned; GDScript) |
| **Domain** | Input + Rendering (Core/Input/Rendering) |
| **Knowledge Risk** | **HIGH** — 4.7.2 is post-LLM-cutoff (May 2025); 4.5/4.6/4.7 all carry changes |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `modules/input.md`; `modules/rendering.md`; `modules/ui.md`; `breaking-changes.md`; `current-best-practices.md`; `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | `InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD` (4.7); dual-focus input routing (4.6); SDL3 gamepad backend (4.5); `DisplayServer.get_display_safe_area()` **[unverified — zero repo citations]**; `DisplayServer.screen_get_scale()` / `screen_get_dpi()` **[unverified source choice]**; `Input.use_accumulated_input`; `Input.vibrate_handheld()`; `Performance.MEMORY_DYNAMIC` / `OBJECT_COUNT` / `OBJECT_RESOURCE_COUNT` **[monitor names unverified against 4.7.2]**; `Window.CONTENT_SCALE_MODE_DISABLED`; `SubViewport` + `SubViewportContainer` (not post-cutoff, but the D1 wiring is engine-verified) |
| **Verification Required** | The 16-item register in §16. **13 items are `PROBE-PENDING`** and block the first implementation story per AC-74; 2 are `DOCUMENTED`; 1 is `REASSIGNED`. The ADR is Accepted as architecture; no story may consume a `PROBE-PENDING` item as settled fact. |

> **Knowledge-gap warning (HIGH).** 4.7's new-project defaults are
> `canvas_items` + `expand`; the D1 model **explicitly rejects** them. Do not
> copy engine defaults into this project. Verify every `[unverified]` API in the
> probe register before writing production input or render-rig code.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (first ADR; SYS-01 is the root of the design order) |
| **Enables** | SYS-06 Movement GDD/ADR (facing publication + posture handoff); SYS-08 Combat GDD/ADR (arc declarations, commitments, press-age handoff); SYS-24 HUD (touch-region registration); SYS-32 Camera (D1 world band, camera reads no input); SYS-29 Juice (hit-stop clock, haptic enqueue) |
| **Blocks** | The first SYS-01 implementation story; every story that consumes `move_x`, `crouch`, `jump`, `dash`, `backdash`, `interact`, `quick_item`, `body_busy`, or `facing`; the QA plan's smoke gate execution (the ledger is written, but execution waits on the probe register) |
| **Ordering Note** | The ADR precedes the Combat/Movement GDDs' normative consumption of the crouch channel, posture handoff and gate manifest. The QA plan's 96-unit ledger may be printed now (it is), but its smoke gate runs only after the probe register closes. |

## Context

### Problem Statement

SYS-01 is design-complete and unfrozen, but every implementation story is blocked
on one architecture decision: how the input path is wired in Godot 4.7.2 so that
the GDD's laws are *achievable*, not merely stated. The GDD deliberately pushed
the mechanism to this ADR: the capture callback, the two clocks, the freeze
mechanism, the per-tick pipeline order, the `(raw_axis, move_order)` wire shape,
the D1 SubViewport wiring, flip-attribution, the mirror/reach-disc mechanism, the
Prompt Slot's sole-puller role, remap persistence, the injection vehicle, and the
16 engine-verification items. Without this ADR, two implementers can read the same
GDD and build two incompatible input layers — the exact failure mode the GDD's
review loop spent ten rounds eliminating from the text.

The cost of not deciding is concrete: a wrong capture path double-captures or
misses presses; a wrong freeze mechanism either starves physics ticks
(`Engine.time_scale = 0`) or freezes crouch publication against B2; a wrong
render model makes the GDD's `k`/band/hit-rect arithmetic false; a wrong pipeline
order makes gate terminality underivable; and a wrong `move_x` shape hides a
second normalizer behind `Input.get_vector`, falsifying AC-07's replay
equivalence.

### Current State

- `src/` contains no game code; the combat concept prototype is throwaway and
  was never imported.
- The SYS-01 GDD is **UNFROZEN** at Main `af39307` (#10 diff-scoped: PASS WITH
  RECORDED OBLIGATIONS; loop closed at #10).
- The QA plan does not yet exist; its 96-unit AC→gate ledger is written by this
  session's companion artifact.
- The engine-probe spike is a throwaway prototype; its outputs are evidence, not
  a code dependency. No probe result is treated as a production fact until the
  register records it.
- The project has no `docs/registry/architecture.yaml`; this ADR is the first
  entry in the architecture log. The TR registry is seeded separately by
  `/architecture-review`.

### Constraints

- **Engine**: Godot 4.7.2, GDScript; 2D; mobile-first (iOS/Android) with PC
  secondary; 60 fps target; 16.6 ms frame budget; ~150 MB memory ceiling;
  ≤150 draw calls.
- **Platform**: landscape-locked at MVP (EX-10); touch, keyboard and gamepad
  from day one; safe-area cutouts on mobile; desktop windowed profiles have zero
  floor insets (NB-G).
- **Design**: SYS-01 is a foundation layer; its core must be pure, deterministic
  and clock-injected (GUT); no `Input` singleton in the testable core; no direct
  `Input` reads by consumers; gameplay values data-driven; public APIs documented.
- **GDD laws**: TR-INP-076 (stamp law; two clocks), TR-INP-013/014/066 (raw
  states), TR-INP-047 (gates/terminality), TR-INP-020/021/022/075 (offer–pull–ack
  and custody), TR-INP-059/063/077 (D1/safe area/dead taps), TR-INP-056/F-07
  (backdash/flip), TR-INP-069/V20 (mirror/reach), TR-INP-036/037 (persistence),
  TR-INP-070 (a11y), TR-INP-067/030 (Prompt Slot), AC-18/59/65 (O1/gate/stamp),
  AC-53/54 (perf/allocation), AC-74 (verification).
- **Process**: Main is protected; work lands via branch + PR; the collaboration
  protocol requires approval before writes; every checkpoint is pushed.

### Requirements

- **R1 — One capture point.** Gameplay events enter through exactly one callback
  per event family (`_input`, pre-GUI); no semantic work on the render path; no
  double capture with `_unhandled_input`.
- **R2 — First-boundary stamping.** Every event stamps to the first `logic_tick`
  boundary at or after arrival; never back-dated; freeze arrivals stamp at the
  first unfrozen boundary.
- **R3 — Raw states every tick.** `move_x`, `crouch`, `jump_held`, `body_busy`,
  `facing` publish raw every `physics_tick`, including during freeze; no
  smoothing, no deferral, no commitment-freeze.
- **R4 — Gate terminality.** Any gate request in tick T is terminal for
  uncommitted acks in T; gate-capable pullers poll first; non-ack requests queue
  to the next gate-entry phase; forward-binding governs from the raise.
- **R5 — Freeze scope.** While `logic_tick` is frozen: raw publication and
  mid-freeze semantic evaluation continue; offers, acks and expiry suspend; the
  chip decides at the crossing and delivers at the first unfrozen boundary.
- **R6 — D1 render model.** Root stretch disabled; world in a `SubViewport` at
  480k×270k centered in the safe rect; HUD at native resolution; bars dead to
  world taps; screen→art transform exact.
- **R7 — Flip attribution.** The backdash machine distinguishes the
  press1-induced turn from every other facing flip; the intent carries
  `entry_sign` only.
- **R8 — Mirror/reach.** `MIRROR` reflects the canonical right-anchored layout;
  the pause mirrors with the stick; the 200 dp reach disc is centered on the
  cluster corner and contains the four gameplay centers.
- **R9 — Persistence.** Bindings persist device-local to `user://controls.cfg`,
  schema-versioned; never in SYS-03 save slots; a11y toggles excluded from
  defaults reset unless "Restore Everything".
- **R10 — Testability.** The core is pure and injected; the injection vehicle is
  `parse_input_event` for event-delivery equivalence; `action_press` is state-only.
- **R11 — Performance/allocation.** The AC-53/54 bars are achievable; the
  pipeline owns every hot-path structure and preallocates it; the vibrator IPC
  stays in SYS-29.
- **R12 — Verification.** Every one of the 16 engine items has a verdict before
  the first implementation story (AC-74); `PROBE-PENDING` is an open verdict.

## Decision

### 1 · Scope and non-goals

**In scope.** The input service's node graph, capture path, clocks, freeze,
per-tick pipeline, gate handling, buffer/offer–pull–ack service, raw state
publication, `move_x` wire shape, touch dispatcher, D1 render rig, flip
attribution, mirror/reach-disc geometry, Prompt Slot service, remap persistence,
haptic enqueue boundary, test seams, and the 16-item engine verification register.

**Out of scope (owned elsewhere).** Movement feel curves, coyote time, committed
movement locks, hop-lock rate, posture application during commitments (SYS-06);
Combat arcs, clash/deflect rules, i-frames, press-age gating (SYS-08); HUD
visuals and region rendering (SYS-24); hit-stop requests and vibrator IPC
(SYS-29); camera framing (SYS-32); save serialization (SYS-03); the Stinger
recognizer's tolerances (SYS-12, VS).

**Non-goals.** No ninth body verb; no derived moves in the registry; no per-press
popups; no engine-default stretch model; no `Engine.time_scale` freeze; no direct
`Input` reads by consumers; no bindings in save slots; no HUD consumption of
gameplay touches.

### 2 · Node graph and ownership

The input layer is a **scene-tree service with a pure core**, not a god-autoload.
The nodes own engine contact (callbacks, tree lifecycle); the `InputCore`
(`RefCounted`) owns all decisions and is the GUT seam. The service is instantiated
once in the boot scene and injected into consumers through a typed `InputBus`
interface, never through a global singleton lookup.

```
Boot (Node)
├── InputService (Node, process_mode = ALWAYS)
│   ├── InputCapture (Node, _input only)
│   ├── InputTick (Node, _physics_process)
│   ├── GameClock (Node)
│   ├── InputStateProvider (Node)
│   ├── TouchDispatcher (Node)
│   ├── PromptSlotService (Node)
│   ├── HapticQueue (Node)
│   └── InputCore (RefCounted — pure, injected)
├── RenderRig (Node)
│   ├── WorldBand (Control, mouse_filter = IGNORE, full rect)
│   │   └── BandContainer (SubViewportContainer, stretch = false)
│   │       └── WorldViewport (SubViewport, size = 480k × 270k)
│   │           └── WorldRoot (Node2D)
│   │               └── Camera2D (zoom = (k, k))
│   └── HudLayer (CanvasLayer, layer = 10)
│       └── HudRoot (Control, native px, mouse_filter = IGNORE for gameplay)
└── Game (Node) — consumers: SYS-06, SYS-08, SYS-15, SYS-24, SYS-29, SYS-32
```

**Ownership rules.**

- `InputCapture` is the **only** node that registers `_input` for gameplay event
  families. It never registers `_unhandled_input` for the same family; it never
  calls `set_input_as_handled()` (capture is observational, not consuming).
- `InputTick` is the **only** node that runs the per-tick pipeline. It runs in
  `_physics_process`, `process_mode = PROCESS_MODE_ALWAYS` so pause/menu
  transitions and blur disposal still receive input; the **context gate**, not
  the tree pause, decides what is semantically live.
- `InputCore` never touches `Input`, the scene tree, `Time`, or the renderer.
  It receives `CapturedEvent` batches, a clock snapshot, and publisher
  publications; it returns `InputFrame` results.
- Consumers receive `InputBus` (a typed facade over the published snapshot and
  `try_pull`); they never read `Input` directly and never read another
  consumer's private state.
- `RenderRig` owns the D1 wiring; `TouchDispatcher` owns region registration and
  screen→region binding; `HudRoot` owns visuals only.

### 3 · Two clocks and the manual freeze

**`physics_tick`** is `Engine.get_physics_frames()` — it always advances. The
dispatcher runs on every physics tick, including frozen and non-Gameplay ticks.

**`logic_tick`** is a 64-bit counter owned by `GameClock`. It advances by exactly
one at the **start** of a physics tick iff:

```
logic_running = (context == GAMEPLAY) ∧ (freeze_sources.is_empty())
```

`context` is SYS-05's published context (input enforces gates; SYS-05 owns the
state). `freeze_sources` is a set of `StringName` reasons (e.g. `&"hit_stop"`,
`&"clash"`, `&"boss_intro"`), not a boolean: overlapping freezes do not
double-unfreeze. The last source removed resumes the clock.

**Freeze is manual tick-freeze, never `Engine.time_scale = 0`.** Setting
`time_scale = 0` schedules no physics ticks, so the dispatcher's per-tick drain
does not exist; fractional values starve it. Both contradict TR-INP-076's
"`physics_tick` always advances" axiom. The freeze is a clock flag; the engine
keeps ticking; the pipeline keeps draining captures and publishing raw states.

**Freeze-onset boundary.** A freeze request raised during tick `T` makes `T` the
last stamped `logic_tick`. `GameClock` records `freeze_pending`; the next physics
tick opens with `logic_running = false` and does **not** increment `logic_tick`.
A capture arriving in `T`'s capture phase stamps at `T`; a capture arriving
after the request waits for the first unfrozen `logic_tick`. This is exactly
TR-INP-076's freeze-onset rule.

**Freeze vs pause.** They are different mechanisms:

| | Hit-stop freeze | Pause/gate |
|---|---|---|
| Clock | `logic_tick` stops; `physics_tick` continues | `logic_tick` stops (non-Gameplay) |
| Buffers | pending intents **preserved**, age frozen | buffers **cleared at gate entry** |
| Offers/acks | suspended | none (context gate) |
| Raw states | publish every tick | publish every tick (held states persist) |
| Exit | `release_freeze(source)` | context transition back to Gameplay |

The buffer service keys on `GameClock.logic_running` and `context` separately; a
freeze never clears a buffer, and a pause never preserves one. This is the
"freeze-vs-pause discrimination" rider from OQ#1.

**`process_mode`.** `InputService` is `PROCESS_MODE_ALWAYS`. If the game uses
`get_tree().paused = true` for menus, the service still runs; the context gate
routes `pause`/menu input and blocks gameplay verbs. The service must not rely
on tree pause for input semantics.

### 4 · Capture and stamping

**One callback per family.** `InputCapture._input(event)` is the only gameplay
capture callback. It filters by event family and device id:

| Family | Events | Handling |
|---|---|---|
| Touch | `InputEventScreenTouch`, `InputEventScreenDrag` | raw enqueue; index-tracked |
| Key | `InputEventKey` | raw enqueue; OS repeat filtered at semantic phase |
| Pad button | `InputEventJoypadButton` | raw enqueue |
| Pad motion | `InputEventJoypadMotion` | raw enqueue (stick + trigger axes) |
| Action | `InputEventAction` | raw enqueue (test/injection path; not the runtime path) |
| Mouse | `InputEventMouse*` | **ignored for gameplay**; menu-only |
| Synthesized mouse-from-touch | `InputEventMouse*` with touch device id | **ignored** (double-handling guard) |

The capture callback does exactly three things: **(1)** read
`Time.get_ticks_usec()` once, **(2)** append a `CapturedEvent` to the preallocated
capture queue, **(3)** return. It performs **no** normalization, deadzone,
binding, buffering, gesture or prompt work. This is what makes AC-53's "zero
semantic render-path work" true.

**Queue.** The capture queue is a preallocated ring of `CAPTURE_QUEUE_CAPACITY =
256` `CapturedEvent` records (the probe verifies the worst-case burst is well
below it; overflow is a dev assert + production telemetry, and the test fails if
it occurs — the drain-all policy forbids silent pre-dispatch drops). The queue is
drained **all at once** at the next `physics_tick`'s capture phase, in arrival
order.

**Arrival timestamp.** `arrival_usec = Time.get_ticks_usec()` at callback
receipt. Godot events carry no reliable cross-platform OS timestamp; OS-event-time
exposure is engine item 12. If item 12 yields an OS timestamp, the device budget
uses it; otherwise the budget degrades to callback-arrival with a documented
OS-side caveat (AC-65's conditional device half).

**Stamping.** At the capture phase, each queued event is stamped to the **current
`logic_tick`** if `logic_running`; otherwise it remains queued and is stamped at
the first unfrozen `logic_tick`. Never back-date. Multi-tick frames (two physics
ticks in one render frame at 30 fps) drain all captures in the first tick's
capture phase; arrival order is preserved; the second tick has an empty queue.
Events arriving between physics ticks wait for the next tick's capture phase —
that tick is the first boundary at or after arrival.

**`Input.use_accumulated_input = false`.** The engine's input accumulator would
collapse arrival timestamps to the render frame and flush once per frame,
violating the arrival definition the stamp law measures. The capture queue is
this project's accumulator; it preserves per-event arrival order and timestamps.
The probe verifies the event-rate cost of disabling the engine accumulator; if a
platform shows a material cost, the fallback is documented in the probe register
and AC-65's device budget records the caveat. `Input.use_accumulated_input` is
set once at boot, before the first scene, and never toggled.

**Flushing cadence.** The exact 4.7 setting names
(`agile_input_flushing` / `input_buffering`) are `[unverified]`; item 16 pins
them. The architecture requires **per-physics-tick delivery** (or the closest
achievable cadence) so the stamp law and AC-65 measure the intended distribution;
if the engine can only flush per render frame, the ADR records the amended
arrival definition and AC-65's device half degrades accordingly.

### 5 · The per-tick pipeline

`InputTick._physics_process` runs the following phases in this exact order. The
order is the GDD's intra-tick choreography, confirmed achievable:

```
PHASE 0 — TICK OPEN
  physics_tick += 1
  apply pending freeze/unfreeze; logic_tick += 1 iff logic_running
  snapshot context, facing, body_busy, prompt state

PHASE 1 — CAPTURES / SUPERSEDES
  batch = capture_queue.drain_all()            # arrival order
  state_provider.poll()                        # held keys/pad/touch re-assertion
  core.capture_phase(batch, clock)             # stamp; F-02/03/04/09; F-07 edges
  core.supersede_phase()                       # Latest Order Honored

PHASE 2 — PUBLISH RAW
  core.publish_raw()                           # move_x, crouch, jump_held,
                                               # body_busy, facing — EVERY tick

PHASE 3 — GATE-ENTRY
  core.apply_queued_gate_requests()            # non-ack requests from prior ticks
  core.clear_intents_at_entry()                # buffers clear at gate entry
  core.void_uncommitted_acks()                 # terminality effects

PHASE 4 — OFFERS
  for puller in pullers_sorted(gate_capable_first):
      intent = core.try_pull(verb)             # atomic consume; no half-state
      if intent: puller.accept(intent)         # accept invoked after commit
      if core.gate_request_latched: break      # forward-binding

PHASE 5 — ACKS
  core.invoke_accept_callbacks()               # custody transfer; faults logged
  core.apply_ack_sourced_gate_requests()       # immediate terminality (B4)

PHASE 6 — EXPIRY
  core.expiry_phase()                          # lazy bookkeeping; over-age resets
```

**Why this order.**

- **Captures before gate-entry** so a gate opening in `T` cannot be pulled past
  by an intent captured in `T`; the gate-opening puller is polled first.
- **Gate-entry before offers** so no same-tick offered intent can be pulled past
  a gate that opens that tick (TR-INP-047).
- **Offers before acks** because `try_pull` is the atomic commit; the accept
  callback runs after the commit, and a fault is "honored but unexecuted".
- **Acks before expiry** so an intent pulled on its last eligible tick is
  honored (age == window is inclusive).
- **State re-assertion with the capture phase**, ownership-conditional: an edge
  beats a same-tick assertion (TR-INP-071).

**Same-tick resolution.** Because the capture phase stamps at the current
`logic_tick` and the offer phase runs later in the same tick, an intent can be
offered and pulled on its stamp tick. This is the GDD's "offer begins on the
stamp tick itself" (F-05), now structurally true. It is the Early Press's
foundation and AC-18's zero stamp-relative delay.

**Frozen ticks.** Phases 0–2 run; phases 3–6 are replaced by
`core.mid_freeze_phase()`:

- F-04 guard crossings publish raw at the crossing tick (B2).
- F-07 pattern completions evaluate `body_available` at the completion tick;
  the hit-stop⇒body-committed invariant (below) makes a mid-freeze completion
  body-busy and it drops. If a freeze source cannot assert the invariant, the
  detector fails closed (drops) — a delayed dodge is worse than a missing one.
- F-09 chip decisions land at the crossing tick; the synthesized `quick_item`
  press is **delivered at the first unfrozen boundary**, stamped there; the
  window age is frozen.
- Offers, acks and expiry do not run. No pending intent is offered, pulled or
  expired while frozen.

**Hit-stop⇒body-committed invariant (ADR-ratified).** Every hit-stop source in
MVP must also publish a body commitment (SYS-08's clash lock or SYS-06's
committed movement) for the freeze's duration. This makes the GDD's
"completion during clash-freeze → dropped" well-defined and removes the need for
a frozen-pulse queue. The Combat/Movement GDDs must ratify this contract; if a
future freeze source cannot, the backdash detector's fail-closed rule applies.

### 6 · Gates and terminality

**Gate request sources.**

| Source | Kind | Application point |
|---|---|---|
| Prompt Slot bubble-confirm | ack-sourced | immediately at the ack commit (phase 5), same tick |
| Death (SYS-07/SYS-15) | non-ack | queued; next gate-entry phase (T's own if unrun, else T+1) |
| Cutscene trigger (SYS-05) | non-ack | queued; next gate-entry phase |
| Pause / app blur | non-ack (context) | queued; next gate-entry phase |
| Log/reading/cache terminal | non-ack (context) | queued; next gate-entry phase |

**Terminality (B4).** Any gate request raised in tick `T` is terminal for every
uncommitted ack in `T`:

1. **From the raise (forward-binding).** After the request is raised, no further
   offers or acks resolve that tick. The offer loop checks
   `gate_request_latched` after each pull and breaks; the ack loop does not
   start new accepts.
2. **Grandfathering.** An ack **committed before the raise** is honored. Acks
   after the raise never commit (forward-binding). Uncommitted acks **at the
   application point** are voided.
3. **Application point.** An ack-sourced request applies immediately at the ack
   commit. A non-ack request applies at the next gate-entry phase: `T`'s own if
   phase 3 has not yet run, else `T+1`'s phase 3.
4. **Intent clearing.** At the application point, all remaining pending intents
   clear (buffers clear at gate entry); held states persist.
5. **Gate-capable pullers first.** The Prompt Slot (Interact) is gate-capable;
   it is polled before Combat/Movement pullers so a gate-opening pull commits
   before other pullers act.

**One consistent death-frame outcome.** The death case's observation point is the
application point, not SYS-05/SYS-07's unpinned tick position. An ack committed
before the death request is grandfathered; acks after the raise are blocked;
uncommitted acks at the application point are voided. This is the rule AC-59's
death-case grandfathering depends on (NB-J); this ADR ratifies it.

**Pipeline amendment clause.** If a future engine constraint makes the phase
order unachievable, the ADR must be superseded with an explicit amendment to the
GDD's Edge Case — not silently reordered. The GDD's choreography is normative.

### 7 · The buffer service and offer–pull–ack

`BufferService` is a pure `RefCounted` with an injected `GameClock`. It owns one
slot per verb (eight body verbs + the `stinger` socket), each with:

```
IntentSlot:
  verb: StringName
  pending: bool
  consumed: bool
  press_tick: int          # logic_tick of the stamp
  window_ticks: int        # F-01 from ms contract
  snapshot: BodySnapshot   # crouching, grounded, move_x, body_busy
  entry_sign: int          # backdash only: -1 / +1
  gesture_tag: StringName  # &"plain" / &"gesture"
  supersede_count: int
```

**Entry.** On a press, `press_tick = stamp_tick`, `snapshot = snapshot_at(stamp)`,
`consumed = false`, `window_ticks = ms_to_ticks(override.get(verb,
INTENT_WINDOW_MS))`; the Interact override is derived per press at the stamp
tick from the publishers busy in the snapshot (TR-INP-029), not tuned.

**Offer.** A slot is offered while `current_logic_tick - press_tick <=
window_ticks ∧ ¬consumed ∧ context == GAMEPLAY`. `age == window` is still
pending (inclusive); `age == window + 1` is never offered (lazy expiry). The
offer phase calls the single registered puller for the verb.

**Atomic `try_pull`.** Pull and ack are one transaction:

```gdscript
func try_pull(verb: StringName) -> PulledIntent:
    var slot := _slots[verb]
    if not _offerable(slot):
        return PulledIntent.none()
    var intent := slot.take()          # consumed = true, custody transferred
    _ack_log.append(intent)            # committed before accept is invoked
    return intent
```

The consumed flag, snapshot and custody transfer commit **before** the puller's
`accept` is invoked. A puller that faults after commit is *honored but
unexecuted*: log a `puller_fault`, never re-offer. A slot can never be observed
half-consumed.

**Latest Order Honored.** A new press of the same verb, pending or consumed,
replaces `press_tick`/snapshot, resets `consumed = false`, and restarts the
window. One slot per verb forever. The G1/G2/G3 theorem is the GDD's; the ADR
implements it with `supersede_count` and the press record.

**Custody.** The ack transfers custody (TR-INP-075). Input neither re-offers a
consumed slot nor retains a copy. A pulled order that dies mid-arc dies with the
arc; it never re-enters a buffer. Attack is held across Combat's arc; Jump, Dash,
Interact and Quick-use execute-at-pull.

**Interact's gates.** F-05's context gate, F-10's lit-prompt/binding gate, and
F-08's body gate are evaluated at resolution. A binding failure dominates the
body wait (F-10's both-fail precedence); a body-busy resolution waits inside the
derived window. The Prompt Slot is the sole puller; publishers publish, never
pull.

**Backdash.** Reflex-class: no window slot; the detector publishes a single-tick
`backdash` offer carrying `(entry_sign)` at the completion tick; SYS-06 pulls the
same tick or it vanishes. The body-free check at completion; busy → drop (EX-1);
mid-freeze → drop via the hit-stop⇒body-committed invariant.

### 8 · Raw state publication and the `move_x` wire shape

**Publication.** `InputStateProvider` builds a `BodySnapshot` every
`physics_tick` from the live sources; `InputCore.publish_raw()` publishes it
before offers. The published channels are:

| Channel | Shape | Owner of truth |
|---|---|---|
| `move_x` | `(raw_axis: Vector2, move_order: float)` | input (raw + band selection) |
| `crouch` | `bool` = `latch ∨ held_zone` | input (raw) |
| `jump_held` | `bool` | input (raw) |
| `grounded` | `bool` | SYS-06 |
| `body_busy` | `bool` = OR of publisher locks | SYS-06 + SYS-08 (input ORs) |
| `facing` | `FacingPublication { value, epoch, cause }` | SYS-06 |
| `context` | enum | SYS-05 |

**No smoothing, no deferral, no commitment-freeze.** The crouch channel flips at
the guard-crossing tick even while the body is committed; posture application is
SYS-06's handoff. `move_x`'s raw axis is the pre-normalization trace; `move_order`
is the contract (five discrete values). The pair is published together so the
audit/trace channel and the consumer contract never diverge.

**`move_x` wire shape — the decision.** `move_x` is **one signed channel plus a
discrete order**, not a half-action pair and not `Input.get_vector`:

- **Raw axis**: touch vector after F-02 (normalized, deadzoned, pinned at leash);
  gamepad `Input.get_joy_axis(device, JOY_AXIS_LEFT_X)` with F-02's ratio
  deadzone; keyboard/d-pad synthesized ±1.0. Sign is preserved.
- **Move order**: F-03's `sign(x) × band_multiplier` ∈ {−1.0, −0.5, 0, +0.5,
  +1.0}. Consumers map it to speed with their own ramps.
- **Why not `Input.get_vector`**: it re-normalizes diagonals and hides a second
  normalizer; it cannot express the raw trace; it would make AC-07's replay
  equivalence unenforceable.
- **Why not a half-action pair**: two half-actions cannot express a signed analog
  axis or the raw trace; they also reintroduce the deadzone ambiguity.
- **No direct `Input` reads by consumers.** Consumers read the published
  `InputFrame` or `try_pull`. This is the rule that makes replay equivalence
  testable.

**InputMap deadzones are 0.** Every SYS-01-registered action gets deadzone 0 at
registration; F-02 is the sole deadzone authority. Axis-sourced buttons (Dash on
RB/R2 as `JoypadMotion`) use the source-filter comparator
`AXIS_BUTTON_THRESHOLD = 0.5` with hysteresis; the InputMap deadzone stays 0.
`Input.get_joy_axis` is the poll path for held stick states; `InputEventJoypadMotion`
is the capture path for edges. No `InputMap` edge reads for analog sources.

**Held-state re-assertion.** TR-INP-071's active republish: every tick, the
dispatcher re-publishes the tracked value of each state channel from its tracked
source (touch live vector; KB/pad per-tick poll). A stationary held thumb
re-asserts every tick; `ScreenDrag` only fires on movement. Publish neutral on
the first missed assertion; clear ownership after two consecutive misses. An edge
beats a same-tick assertion (ownership-conditional).

### 9 · The D1 render model — SubViewport wiring

**Project settings (explicit, not engine defaults).**

```ini
display/window/stretch/mode = "disabled"
display/window/stretch/aspect = "keep"      # irrelevant when stretch is disabled
display/window/size/viewport_width = 1280   # boot fallback; recomputed at runtime
display/window/size/viewport_height = 720
```

At boot, `get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED`
and `content_scale_size = Vector2i.ZERO`. This explicitly rejects 4.7's
new-project defaults (`canvas_items` + `expand`); the D1 band depends on native
pixels, not a stretch model.

**Metrics computation (per session, on resize/safe-area/density change).**

```gdscript
window_rect  = Rect2i(Vector2i.ZERO, DisplayServer.window_get_size())
display_safe = DisplayServer.get_display_safe_area()          # [unverified]
safe_rect    = window_rect.intersection(display_safe)
if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
    safe_rect = window_rect; log_warning("safe-area empty; window fallback")

density = DisplayServer.screen_get_scale()                    # [unverified source]
          # cross-check: DisplayServer.screen_get_dpi() / 160.0
if density <= 0.0: density = 1.0; log_warning("density unavailable")

# mobile cutout surfaces only; desktop floors are 0 on every axis (NB-G)
if OS.has_feature("mobile") and not OS.has_feature("desktop"):
    inset_l = max(display_safe.position.x, ceil(59 * density))
    inset_r = max(window_rect.size.x - display_safe.end.x, ceil(59 * density))
    inset_t = max(display_safe.position.y, ceil(0 * density))
    inset_b = max(window_rect.size.y - display_safe.end.y, ceil(48 * density))
    # safe_rect is recomputed from these floors; desktop reads 0

k = max(1, min(floor(safe_rect.size.x / 480.0),
               floor(safe_rect.size.y / 270.0)))
band_size   = Vector2i(480 * k, 270 * k)
band_origin = safe_rect.position + (safe_rect.size - band_size) / 2  # integer div
band_rect   = Rect2i(band_origin, band_size)
visible_band = band_rect.intersection(safe_rect)
```

**Wiring.**

```
WorldBand (Control, full window rect, mouse_filter = IGNORE)
└── BandContainer (SubViewportContainer)
    stretch = false
    position = band_origin
    size = band_size
    mouse_filter = IGNORE
    └── WorldViewport (SubViewport)
        size = band_size
        render_target_update_mode = ALWAYS
        handle_input_locally = false
        gui_disable_input = true            # if present in 4.7.2; probe item 8
        └── WorldRoot (Node2D)
            └── Camera2D
                zoom = Vector2(k, k)        # 480×270 art units -> 480k×270k px
```

The world is authored at 480×270 art units. The `SubViewport` is `480k × 270k`
physical pixels; `Camera2D.zoom = (k, k)` maps one art unit to `k` screen pixels.
The `SubViewportContainer` displays the viewport 1:1 (`stretch = false`), so no
second resample exists. The HUD is a separate `CanvasLayer` at native resolution;
it never inherits the world's `k`.

**Screen→art transform (bounds-test, then floor division).**

```gdscript
func screen_to_art(p: Vector2i) -> Variant:
    if not visible_band.has_point(p):
        return null                              # bar / crop / outside safe
    var crop_origin_px := visible_band.position - band_origin
    var art_origin := Vector2(crop_origin_px) / float(k)
    var art := (Vector2(p - visible_band.position) / float(k)) + art_origin
    return Vector2i(floor(art.x), floor(art.y))
```

- **Non-crop case**: `visible_band == band_rect`, `art_origin = (0,0)`, and
  `art = floor((p - band_origin) / k)`.
- **Crop case** (`safe_rect` smaller than 480×270): `k = 1`, the band is
  center-cropped to `visible_band`; `art_origin` is the cropped art offset; the
  crop edge behaves as the viewport boundary; taps beyond it are dead; hit rects
  clip to the visible region.
- **Bars**: `safe_rect - visible_band` on either or both axes. Every bar surface
  is a dead world tap (TR-INP-063); HUD controls may sit over a bar because they
  are on the native layer.

**HUD native layer.** `HudRoot` is a `Control` sized to `window_rect.size`; all
positions are native px computed as `dp * density`. `HudRoot.mouse_filter =
IGNORE` during Gameplay so it never eats gameplay touches; the `TouchDispatcher`
routes touches by registered region. Menu surfaces (pause → Recalibration) use
ordinary `Control` GUI input while the context is non-Gameplay; the dispatcher's
gameplay capture is context-gated. The bubble is the one HUD-rendered gameplay
region: its position derives from the world anchor, its hit rect is native px,
and the dispatcher routes its touch to the Prompt Slot.

**Region registration.** `TouchDispatcher` owns a registry of
`TouchRegion { id, kind, rect_px, z, gate_capable }`. Z-order is load-bearing:
**buttons > bubble > chip > movement zone**; among buttons the audited table's
row order is **Attack > Jump > Dash socket > a11y Backdash**; the pause is a
button and wins over the zone. Overlap at `TOUCH_HIT_SCALE = 1.5` is resolved,
not prevented (EX-9). A touch binds to exactly one region at touchdown; no
mid-touch rebind; release unbinds; the binding survives region re-registration
(F-09's `release_observed` is binding-based).

**World taps.** A touchdown inside `visible_band` that hits no HUD region is a
`WorldTapEvent(art_pos, index)`; the dispatcher emits it to the world layer
(SYS-02/15/11). The HUD never consumes gameplay touches directly (AC-60). A
touchdown outside `visible_band` is `DEAD` — no capture, no error, no haptic.

**Mirror and metrics changes.** `MIRROR` and every metrics change
(`metrics_changed`) rebuild the region registry. A live touch keeps its bound
region; the world moved, not the order. Density/orientation change recomputes
`k`; rotation is post-MVP (EX-10), but the density/scale change is in scope
(AC-37).

### 10 · Flip-attribution — the facing publication contract

The backdash machine must distinguish **the press1-induced turn** (the player
flicked back; SYS-06 turns her to face the threat) from **every other facing
flip** (knockback, wall turn, a later deliberate turn, scripted). The GDD's
`facing` contract is expanded by this ADR to a structured publication:

```gdscript
class FacingPublication:
    var value: int          # -1 (left) / +1 (right)
    var epoch: int          # increments on every change; never reused
    var cause: int          # INPUT_TURN / KNOCKBACK / WALL_TURN / HOP / SCRIPTED
    var changed_tick: int   # logic_tick of the change
```

**Publication cadence.** SYS-06 publishes on every change **and re-asserts raw
every `physics_tick`, including during freeze — R3/§8 (erratum 2026-11-13,
Movement OQ-M2: this section originally said "every `logic_tick`"; value/epoch
changes remain keyed to `logic_tick`)** (so a missed read never sees a stale
value). The epoch increments only on a value change; the cause is the cause of that change. The input layer
reads the publication at press1 and on every tick while the machine is armed.

**Attribution rule.**

```
on press1:
    press1_facing = facing.value
    press1_epoch  = facing.epoch
    press1_tick   = current_logic_tick

while machine != IDLE and not fired:
    if facing.epoch > press1_epoch:
        if facing.cause == INPUT_TURN
           and facing.value == -press1_facing
           and facing.epoch == press1_epoch + 1
           and facing.changed_tick - press1_tick <= FLIP_ATTRIBUTION_WINDOW_TICKS:
               # the press1-induced turn — exempt
        else:
               reset_to_IDLE()
```

`FLIP_ATTRIBUTION_WINDOW_TICKS = 2` is an **implementation constant**, not a
tuning knob: it bounds the causality window for Movement processing the turn on
the press1 tick or the next. A later `INPUT_TURN` (a second deliberate turn) has
a later epoch and resets. A `KNOCKBACK`/`WALL_TURN`/`SCRIPTED` flip resets
regardless of value. The `HOP` cause occurs after the fire (machine already IDLE)
and is recorded for the trace.

**Fail-closed.** If SYS-06 has not published `facing`, the detector disables
itself + dev assert (EX-11: a misfired dodge is worse than a missing one). This
is deliberately asymmetric with `body_busy`'s fail-open.

**Same-tick dual-source coalescing.** If the gesture pulse and the a11y direct
press land on the same tick, the pulse channel is **not additive**: exactly one
`backdash` intent is published. The **a11y direct press wins** the payload (it is
the player's explicit order): `entry_sign = -facing` at the press tick; the
gesture machine resets to IDLE. If only the gesture completes, its `entry_sign`
is the chain's latched value. This pins the #9 ADR-routed coalesce case.

**Hop direction.** The intent carries `(entry_sign)` only; SYS-06 sets
`facing = -entry_sign` during the hop. The press1-induced flip is exempt from the
reset; the hop's own flip is a `HOP` cause after the fire and does not re-enter
the machine.

### 11 · Mirror and reach-disc mechanism

**Canonical frame.** All cluster geometry is authored as `(x_in, y_up)`:
`x_in` = dp inward from the right safe edge; `y_up` = dp up from the bottom safe
edge. The audited table (TR-INP-069) is the sole authority:

| Control | `x_in` | `y_up` | Visual dp | Present |
|---|---:|---:|---:|---|
| Attack | 70 | 60 | 60 | always |
| Jump | 40 | 142 | 56 | always |
| Dash socket | 156 | 44 | 48 | always (dormant-visible) |
| a11y Backdash | 130 | 138 | 48 | only when `BACKDASH_BTN_TOGGLE` |
| Pause | `24·s` | `24·s` from the **stick-side top corner** | `48·s` | always |
| Home ghost | stick-zone center-x | `0.30 · H_safe` | — | visual anchor |

`MIRROR` maps the canonical frame:

```
unmirrored: x_px = safe_rect.end.x - x_in * density
            y_px = safe_rect.end.y - y_up * density
            stick zone = left 42% of safe width; pause = top-left
mirrored:   x_px = safe_rect.position.x + x_in * density
            y_px = safe_rect.end.y - y_up * density
            stick zone = right 42% of safe width; pause = top-right
```

The pause **mirrors with the stick** (D2): it is anchored to the stick-side top
corner, so its canonical `(24·s, 24·s)` inset reads from that corner in both
orientations. `s = TOUCH_HIT_SCALE`; the inset and the hit scale together (V19).

**Reach disc.** The disc is a test geometry, not a rendered control:

```
center = (safe_rect.end.x, safe_rect.end.y)        # unmirrored cluster corner
         (safe_rect.position.x, safe_rect.end.y)   # mirrored
radius_px = REACH_DISC_DP * density
```

The four **gameplay** centers (Attack, Jump, Dash, a11y Backdash) must satisfy
`distance(center, control_center) <= radius_px`; the pause is exempt (R-9:
secondary UI) but remains in the pairwise gap audit. At the audited table the
edge-anchored distances are profile-invariant: Attack 92.2 dp, Jump 147.5 dp,
Dash 162.1 dp, a11y Backdash 189.6 dp — all ≤ 200 dp. V20 flags a profile if the
table changes; the table is not a knob (B6).

**Pairwise gap.** Every pair of the five sockets satisfies
`center_distance >= r1 + r2 + CLUSTER_GAP_DP` at `TOUCH_HIT_SCALE = 1.5`, each
pair's radii computed from its scaled hit size. The six gameplay center
distances at the table are 87.32, 87.48, 98.41, 151.86, 90.09, 97.53 dp; at 1.5
the floor-dominated requirement is 36 + 36 + 12 = 84 dp; the minimum 87.32
passes. Pause pairs are profile-dependent and are audited per profile.

**Bubble mirror.** The bubble's interior offset is `(+offset_x, offset_y)` toward
the band interior; under `MIRROR` the x component negates; the leader line's x
endpoint mirrors; the prefer-above fallback is vertical and unchanged. The
bubble never spawns inside the movement zone; the fallback cascade
(interior-offset → prefer-above → leader-line detached) re-validates edge +
cluster + pause clearance at the active hit-scale.

**Audit-gated.** Any position change re-runs AC-34/AC-66. Free-form tweaks are
forbidden; the table is the authority.

### 12 · The Prompt Slot service

`PromptSlotService` is input-owned and is the **sole** `interact` puller.

```gdscript
class Prompt:
    var id: StringName
    var label: String
    var anchor_art: Vector2
    var range_dp: float
    var state: int              # LIT / STATE_GATED
    var gate_capable: bool = true

func publish(prompt: Prompt) -> void
func withdraw(id: StringName) -> void
func lit() -> Prompt            # at most one; nearest wins
```

**Laws.**

- At most one prompt lit; a second publish resolves by nearest-wins before any
  press binds; ties break by registry id, never float comparison.
- A press binds to the prompt lit **at its stamp tick**; a later-lit prompt
  never consumes a stale press.
- `try_pull(interact)` resolves only if the bound prompt is still lit, unsigned,
  and `body_available(t)` at the resolution tick. A binding failure clears
  immediately; a body-busy failure waits inside the derived window.
- The signed latch: a prompt that consumed a press is signed while it stays lit;
  a second press is unresolvable; unlight/context change clears.
- The 150 ms fade-out is visual only; the hit region deactivates at logical
  unlight; presses in the tail bind dead.
- The service is gate-capable and polled first; a bubble-confirm gate request is
  ack-sourced and applies immediately.
- The bubble is world-anchored (inside `visible_band`) and HUD-rendered at native
  resolution; its hit is 56 dp (a11y-sized, exempt from `TOUCH_HIT_SCALE`).
- Publishers publish, never pull. SYS-15, SYS-02, SYS-20, SYS-28, SYS-11 are
  clients; the slot generalizes to every interactable.

### 13 · Remap persistence

**File.** `user://controls.cfg`, `ConfigFile`, schema `version = 1`. It is
**device-local** and never a field in a SYS-03 save slot.

```ini
[meta]
schema_version = 1

[bindings]
jump/slot0 = [InputEventKey, InputEventJoypadButton, ...]
attack/slot0 = ...
# one slot per action; dual defaults are two events in slot0

[ergonomics]
mirror = false
stick_leash_dp = 56
stick_deadzone_dp = 4
# ...

[a11y]
touch_hit_scale = 1.0
crouch_mode = "hold"
chip_tap_commit = false
backdash_btn_toggle = false
haptic_global_strength = 1.0
```

**Serialization.** Events serialize as dictionaries (`type`, `keycode` /
`physical_keycode`, `device`, `button_index`, `axis`, `axis_value`), not as raw
`InputEvent` objects; the loader reconstructs the `InputEvent` and adds it to the
`InputMap`. This keeps the file schema-versionable and portable across engine
patch versions.

**Rules.**

- **Slot-preserving rebind.** Rebinding replaces the events of one action slot;
  it never rewrites another slot. Dual defaults (`A`/`D` + arrows, `Space`/`Z`,
  etc.) live in the same slot as two events.
- **Rebuild.** On load, `InputMap.action_erase_events(action)` then
  `action_add_event` for each event; every SYS-01 action's deadzone is reset to 0
  after the rebuild. Touch semantics are not InputMap actions; they are
  dispatcher regions and are never rebound.
- **Validation.** Schema version, event types, enum membership; corrupt/unknown
  → defaults + one telemetry event; never crash. TR-INP-074's knob validation is
  separate (config load + live edit).
- **Atomic write.** Write `controls.cfg.tmp`, flush, rename over `controls.cfg`.
  A crash leaves the old file intact.
- **Defaults.** Factory bindings + ergonomics; `Restore Defaults` resets both;
  the five a11y toggles (`TOUCH_HIT_SCALE`, `CROUCH_MODE`, `CHIP_TAP_COMMIT`,
  `BACKDASH_BTN_TOGGLE`, `HAPTIC_GLOBAL_STRENGTH`) are excluded unless the player
  explicitly chooses "Restore Everything" (TR-INP-037).
- **Android auto-backup.** Exclude `controls.cfg` from OS auto-backup via the
  export preset's backup rules if the platform allows; if not, document the
  OS-level caveat (probe item 12's platform scope). The game's contract is
  device-local; OS backup is outside the game's save system but inside the
  player's expectation.
- **No save coupling.** A SYS-03 save schema grep for `controls` must return
  zero fields (AC-10).

### 14 · Haptics — enqueue-only boundary

`HapticQueue` is a preallocated ring of `HapticEvent { channel, strength,
event_id, tick }` (capacity 64; the probe verifies the worst-case mash stream).
The input layer **enqueues only**; SYS-29 drains the ring and performs the
vibrator IPC outside the instrumented input scope.

- **Channel map** (designer-fixed): light = press/preview; medium = commit/use;
  heavy = clash/stagger (the last two meanings are Combat's).
- **Coalescing** at `HAPTIC_MIN_INTERVAL_MS`; coalescing is not overflow.
- **Overflow** is a dev assert + production telemetry; the record is not silently
  dropped as if coalesced (AC-61 hazard). The test asserts no overflow at the
  worst-case 12 t/s mash + haptic stream.
- **Global strength 0** silences every meaning legally; the visual channel carries
  the meaning. The capability probe runs at boot and logs the rendition.
- **iOS caveat**: the stock `Input.vibrate_handheld` may ignore duration/
  amplitude and expose no light/medium/heavy style selection; item 13 verifies
  and amends the capability table. If strength 0 cannot be honored, the settings
  copy says so (AC-70's platform carve-out).

### 15 · Test seams and injection vehicle

**Pure core.** `InputCore` is a `RefCounted` with injected dependencies:

```gdscript
InputCore.new(clock: GameClockPort,
              states: StateProviderPort,
              metrics: RenderMetricsPort,
              prompts: PromptRegistryPort,
              body: BodyBusyPort,
              facing: FacingPort,
              tuning: TuningPort)
```

No `Input`, no `SceneTree`, no `Time`, no `RenderingServer` inside the core. The
GUT map's purity table is the contract.

**Injection vehicle — the decision.**

- **Event-delivery equivalence** uses `Input.parse_input_event(event)` with a
  real `InputEvent` (key, joypad, screen touch). This exercises the same capture
  callback and the same deadzone-0 policy as hardware.
- **`Input.action_press(action, strength)` is state-only.** It bypasses the
  InputMap deadzone and does not deliver an event; it is used only for
  state-provider tests, never for the deadzone-0 equivalence test.
- **The deadzone-0 equivalence test** injects a hardware-like
  `InputEventJoypadMotion` / `InputEventScreenTouch` through
  `parse_input_event` and asserts the same post-F-02 magnitude as the hardware
  path. AC-73's "the test must also exercise the hardware path" is satisfied by
  a device-lab run.
- **Poll-only read path.** The input layer polls `Input.get_joy_axis` and
  `Input.is_action_pressed` for held states; it captures edges from the queue.
  Consumers never poll `Input`. Analog edge logic comes from F-02/F-03
  comparators, not `InputMap` edges.
- **Replay.** `CapturedEvent` streams carry `arrival_usec`; replay through the
  core with a `FixedClock` and mocked pullers; compare the output to the human
  capture (AC-07). A replay must be bit-identical for the same input stream.

**Determinism.** Band thresholds, crouch cones, hit geometry and density math
use integer-hundredths arithmetic where the GDD allows (R10); F-02's vector
remains float; comparators are deterministic on identical inputs. No float
equality in tie-breaks; registry ids break ties.

### 16 · The 16-item engine verification register

Every item has a verdict; `PROBE-PENDING` is an open verdict that blocks the
first implementation story (AC-74). The probe is a throwaway prototype under
`prototypes/input-probe/`; its report is evidence in
`production/qa/evidence/sys01/`; no probe code is imported.

| # | Item | Verdict | Evidence / next action | Gate |
|---|---|---|---|---|
| 1 | Device-ID constants (`DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`, 4.7) | **DOCUMENTED** | `docs/engine-reference/godot/breaking-changes.md`; `modules/input.md` | — |
| 2 | Dual-focus touch routing (4.6) — multi-touch delivery to Controls/GUI | **PROBE-PENDING** | Device probe with the dispatcher + HUD; OQ#12's MVP week-1 probe | AC-74 |
| 3 | Dual-focus visual feedback divergence (4.6) | **REASSIGNED — SYS-24** | SYS-24 HUD GDD; documented 4.6 behavior | SYS-24 |
| 4 | SDL3 rumble API surface (4.5) | **PROBE-PENDING** | Desktop + pad probe; exact method names; capability table | AC-74 |
| 5 | SDL3 device detection + hot-swap (`joy_connection_changed`) | **PROBE-PENDING** | Pad unplug/replug probe; held-state release | AC-74 |
| 6 | SDL3 button-mapping normalization vs the standard table | **PROBE-PENDING** | Pad-family glyph probe; `AXIS_BUTTON_THRESHOLD` | AC-74 |
| 7 | Recursive Control disable property (4.5) | **DOCUMENTED + REASSIGNED — SYS-24** | `current-best-practices.md`; HUD hierarchy disable | SYS-24 |
| 8 | **SubViewport render model vs touch coordinates (D1)** | **PROBE-PENDING** | Probe scene: root stretch disabled, band centering, screen→art, crop, dead bars | AC-25/66; AC-74 |
| 9 | `action_press(strength)` × InputMap deadzone | **PROBE-PENDING** | GUT harness: event vs state injection; hardware path | AC-73; AC-74 |
| 10 | Same-tick capture/consume ordering | **PROBE-PENDING** | Pipeline probe: capture → gate-entry → offer → ack → expiry | AC-17/18/44/59; AC-74 |
| 11 | Mouse-as-touch emulation (both directions) | **PROBE-PENDING** | 4.7.2 `emulate_mouse_from_touch` default; filter + dev toggle | AC-27/74 |
| 12 | Safe area + event timestamps | **PROBE-PENDING** | `get_display_safe_area()` query-vs-physical; cutout mode; OS event time; density source; orientation lock | AC-25/37/65/66/74 |
| 13 | Handheld haptics API surface | **PROBE-PENDING** | `vibrate_handheld` on iOS/Android; strength 0; style mapping | AC-50/70/74 |
| 14 | Focus-loss held-state semantics | **PROBE-PENDING** | `WM_WINDOW_FOCUS_OUT` / `APPLICATION_PAUSED`; auto-release? | AC-45/74 |
| 15 | Touch-cancel translation | **PROBE-PENDING** | Android `ACTION_CANCEL` / iOS; synthesized release? | AC-36/74 |
| 16 | Input flushing cadence | **PROBE-PENDING** | Pin the 4.7 setting names; `Input.use_accumulated_input`; per-tick vs per-frame | AC-53/65/74 |

**Counts.** 2 documented (items 1, 7), 1 reassigned (item 3; item 7 is also
reassigned to SYS-24), 13 `PROBE-PENDING`. The first implementation story is
blocked until every `PROBE-PENDING` item has a verified/amended/reassigned
verdict (AC-74). The ADR is Accepted as architecture; the register is the
implementation gate, not a re-open of the decision.

### Architecture diagram — one tick at a glance

```
render frame (variable)
  _input(event)  ──► CapturedEvent{family, arrival_usec, payload}
                        │  (O(1) enqueue; no semantics)
                        ▼
                 capture ring (256)
                        │
physics tick (60 Hz)    ▼
  ┌──────────────────────────────────────────────────────────────┐
  │ 0 TICK OPEN   physics_tick++; freeze? logic_tick++?          │
  │ 1 CAPTURES    drain-all → stamp at logic_tick → F-02/03/04/09│
  │               re-assert held states; F-07 edges; supersede    │
  │ 2 PUBLISH     move_x, crouch, jump_held, body_busy, facing    │
  │ 3 GATE-ENTRY  queued non-ack requests; clear intents; void    │
  │ 4 OFFERS      gate-capable first; try_pull atomic; forward-   │
  │               binding check after each pull                   │
  │ 5 ACKS        accept callbacks; ack-sourced gate requests     │
  │ 6 EXPIRY      lazy bookkeeping; over-age slots reset          │
  └──────────────────────────────────────────────────────────────┘
        │                    │                         │
        ▼                    ▼                         ▼
   InputFrame          PulledIntent              HapticEvent
   (published)         (custody → SYS-06/08)     (enqueue → SYS-29)
```

### Key interfaces

```gdscript
# ---- clock ---------------------------------------------------------------
class GameClock:
    var physics_tick: int
    var logic_tick: int
    var logic_running: bool
    func begin_physics_tick() -> void
    func request_freeze(source: StringName) -> void
    func release_freeze(source: StringName) -> void
    func is_frozen() -> bool

# ---- capture -------------------------------------------------------------
class CapturedEvent:
    var family: int          # TOUCH / KEY / PAD_BUTTON / PAD_MOTION / ACTION
    var device_id: int
    var arrival_usec: int
    var payload: Variant

class InputCapture:
    func _input(event: InputEvent) -> void   # the only gameplay capture callback
    func drain_all() -> Array[CapturedEvent]

# ---- core ----------------------------------------------------------------
class BodySnapshot:
    var crouching: bool
    var grounded: bool
    var move_x: Vector2      # raw axis
    var move_order: float    # -1 / -0.5 / 0 / +0.5 / +1
    var body_busy: bool
    var facing: int

class PulledIntent:
    var verb: StringName
    var press_tick: int
    var snapshot: BodySnapshot
    var entry_sign: int      # backdash only
    var gesture_tag: StringName

class InputCore:
    func capture_phase(batch: Array[CapturedEvent], clock: GameClock) -> void
    func supersede_phase() -> void
    func publish_raw() -> void
    func apply_queued_gate_requests() -> void
    func clear_intents_at_entry() -> void
    func void_uncommitted_acks() -> void
    func try_pull(verb: StringName) -> PulledIntent
    func invoke_accept_callbacks() -> void
    func apply_ack_sourced_gate_requests() -> void
    func expiry_phase() -> void
    func mid_freeze_phase() -> void

# ---- render metrics ------------------------------------------------------
class RenderMetrics:
    var window_rect: Rect2i
    var safe_rect: Rect2i
    var visible_band: Rect2i
    var k: int
    var density: float
    func screen_to_art(p: Vector2i) -> Variant   # Vector2i or null
    func dp_to_px(dp: float) -> int

# ---- touch ---------------------------------------------------------------
class TouchRegion:
    var id: StringName
    var kind: int            # BUTTON / BUBBLE / CHIP / ZONE / DEAD
    var rect_px: Rect2i
    var z: int
    var gate_capable: bool

class TouchDispatcher:
    func register(region: TouchRegion) -> void
    func rebuild(metrics: RenderMetrics, mirror: bool) -> void
    func bind(index: int, pos: Vector2i) -> TouchRegion   # one region, no rebind

# ---- prompt slot ---------------------------------------------------------
class PromptSlotService:
    func publish(prompt: Prompt) -> void
    func withdraw(id: StringName) -> void
    func lit() -> Prompt
    func try_pull_interact() -> PulledIntent   # sole Interact puller

# ---- haptics -------------------------------------------------------------
class HapticQueue:
    func enqueue(channel: int, event_id: StringName) -> void
    func drain() -> Array[HapticEvent]         # SYS-29 only
```

### Implementation guidelines

1. **Build order.** `GameClock` + `InputCore` + `BufferService` (pure, GUT) →
   `InputCapture` + `InputTick` (node integration) → `InputStateProvider` +
   `TouchDispatcher` (touch surface) → `RenderRig` (D1) → `PromptSlotService` →
   remap + haptics → the probe register's verdicts → the first gameplay story.
2. **One owner per decision.** The clock owns ticks; the core owns decisions; the
   dispatcher owns touch binding; the render rig owns metrics; the Prompt Slot
   owns Interact; SYS-06/SYS-08 own body truth. No node reaches around another.
3. **No direct `Input` reads by consumers.** Enforce with a CI grep for
   `Input.is_action_`, `Input.get_axis`, `Input.get_vector` outside
   `src/input/`. A violation fails code review.
4. **Every hot-path structure is preallocated and bounded.** Slots, snapshots,
   trace ring (600 ticks), haptic records (64), capture queue (256), gate-request
   queue (8). No allocation in the per-tick pipeline; no `Array` growth in the
   hot path.
5. **Integer-hundredths geometry.** Band thresholds, crouch cones, hit rects and
   density math use integer hundredths where the GDD allows; the float boundary
   is F-02's normalized vector. No float equality; registry ids break ties.
6. **Data-driven knobs.** Every literal resolves to the Tuning Knobs table or
   the audited layout table; no magic numbers in the pipeline. The ADR's
   constants (`CAPTURE_QUEUE_CAPACITY`, `FLIP_ATTRIBUTION_WINDOW_TICKS`,
   `HAPTIC_QUEUE_CAPACITY`, `GATE_REQUEST_QUEUE_CAPACITY`) are implementation
   constants, documented here, not player-facing knobs.
7. **Doc comments on public APIs.** Every `class_name` and public method gets a
   `##` doc comment; the contracts above are the source.
8. **Fail loud in dev, telemetry in production.** Queue overflow, missing
   publisher, non-fixpoint config, puller fault, facing absent: dev assert +
   production rate-limited telemetry (never a silent wrong motion).
9. **No singleton lookup.** Consumers receive `InputBus`; the service is
   instantiated once and injected. GUT constructs the core directly.
10. **The probe is throwaway.** Do not import probe scenes, scripts or assets
    into `src/`; do not cite probe code as production. Cite the register's
    verdict and the evidence path.

## Alternatives Considered

### Alternative 1: Engine-default stretch (`canvas_items` + `expand`)

- **Description**: Keep 4.7's new-project default; let the root viewport scale
  the whole game, including the HUD; derive touch coordinates from the stretched
  viewport.
- **Pros**: Zero custom render rig; Godot's `Control` anchors "just work"; one
  coordinate space.
- **Cons**: The world band depends on the safe-derived integer `k`; `expand`
  produces no bars and a fractional scale, so the GDD's `k`, band centering,
  dead-bar law and `hit_px` arithmetic are all false. The HUD would be scaled by
  the same factor, breaking the native-resolution dp contract.
- **Estimated Effort**: Lower initial wiring, higher rework.
- **Rejection Reason**: Explicitly rejected by D1 and engine item 8; it cannot
  satisfy TR-INP-059/063/077 or AC-25/66.

### Alternative 2: Root stretch `viewport` + `integer` (the old R-2 model)

- **Description**: Use `viewport` stretch with `integer` scaling; render the HUD
  inside the same viewport and scale it.
- **Pros**: Integer art pixels; simpler than a SubViewport; familiar Godot
  pattern.
- **Cons**: The HUD is scaled with the world, so dp text/hit sizes drift; the
  safe-area clamp and the native dp floors cannot be exact; the touch layer has
  no independent resolution. The GDD's review #5 reversed R-2 for these reasons.
- **Estimated Effort**: Medium; would require re-baselining F-06/AC-25/66.
- **Rejection Reason**: Reversed by D1; the HUD must be native-resolution.

### Alternative 3: Capture in `_unhandled_input`

- **Description**: Let GUI Controls consume first; capture only unhandled events
  in `_unhandled_input`.
- **Pros**: Natural for menu-heavy games; no pre-GUI observer.
- **Cons**: Gameplay touches on HUD Controls are consumed before the dispatcher
  sees them; registering both `_input` and `_unhandled_input` for the same family
  double-captures unconsumed events; the capture point becomes conditional on
  the GUI tree. This falsifies the "one capture point" law and AC-60.
- **Estimated Effort**: Low; high debugging cost.
- **Rejection Reason**: TR-INP-076 pins `_input` (pre-GUI) for gameplay capture.

### Alternative 4: Per-frame dispatch in `_process`

- **Description**: Drain the capture queue and evaluate semantics once per render
  frame.
- **Pros**: One dispatch per visible frame; simpler ordering at high fps.
- **Cons**: The stamp law is defined on `logic_tick`/`physics_tick`; per-frame
  dispatch makes arrival→stamp depend on render rate, breaks the 30/60/120 rate
  matrix, and makes AC-53's per-physics-tick budget unmeasurable.
- **Estimated Effort**: Low.
- **Rejection Reason**: The GDD's two-clock law requires `_physics_process`.

### Alternative 5: `Engine.time_scale = 0` as the freeze

- **Description**: Freeze hit-stop by setting `Engine.time_scale = 0`; restore
  on unfreeze.
- **Pros**: One line; freezes everything (physics, animation, timers).
- **Cons**: No physics ticks are scheduled at 0, so the dispatcher's per-tick
  drain does not exist; fractional values starve it; it contradicts TR-INP-076's
  "`physics_tick` always advances" axiom. It also freezes the capture drain,
  which the freeze scope requires to continue.
- **Estimated Effort**: Very low; incompatible.
- **Rejection Reason**: Manual tick-freeze is the only mechanism that preserves
  the two-clock law and the mid-freeze publication/evaluation scope.

### Alternative 6: Poll `Input` directly in every consumer

- **Description**: Let SYS-06/SYS-08 call `Input.is_action_just_pressed`,
  `Input.get_axis`, `Input.get_vector` directly.
- **Pros**: No central service; least code.
- **Cons**: No single puller, no one-consumption, no gate terminality, no replay
  equivalence, no deadzone-0 policy, and `get_vector` hides a second normalizer.
  Two consumers can fire the same press; a gate cannot void an uncommitted ack.
- **Estimated Effort**: Low; impossible to test.
- **Rejection Reason**: Falsifies AC-05/07/21/44/59 and the GDD's post-office
  doctrine.

### Alternative 7: Per-verb signal bus instead of a central buffer

- **Description**: Each verb emits a signal; consumers connect and decide.
- **Pros**: Decoupled; idiomatic Godot.
- **Cons**: Signals have no built-in one-consumption, supersede, window, stamp or
  gate semantics; ordering across verbs is undefined; a gate cannot atomically
  void uncommitted acks. Rebuilding those semantics on signals recreates the
  buffer with less testability.
- **Estimated Effort**: Medium; high correctness risk.
- **Rejection Reason**: The buffer service is the single owner of window,
  supersede and custody; signals remain the publication edge, not the decision.

### Alternative 8: Route world taps through the SubViewport's GUI

- **Description**: Put the world in a `SubViewport` and let its `Control`/GUI
  tree receive touches; use `SubViewportContainer` input forwarding.
- **Pros**: Godot-native input routing; no manual screen→art transform.
- **Cons**: The SubViewport's coordinate space and the HUD's native space
  diverge; bars/crop edges would need GUI dead zones; HUD Controls could consume
  gameplay touches; the transform would be implicit and untestable. The GDD
  explicitly makes the transform the ADR's and requires bounds-test + floor
  division.
- **Estimated Effort**: Medium; high ambiguity.
- **Rejection Reason**: The dispatcher is the single gameplay touch owner; the
  world layer receives `WorldTapEvent(art_pos)` only.

### Alternative 9: Keep `Input.use_accumulated_input = true`

- **Description**: Let the engine accumulate events and flush once per frame;
  timestamp at flush.
- **Pros**: Lower event overhead; engine default.
- **Cons**: Arrival timestamps collapse to the render frame; the stamp law's
  "first boundary at or after arrival" measures the flush, not the arrival;
  AC-65's device budget becomes a render-rate measurement. Multi-tick frames
  lose the per-event arrival order the capture queue preserves.
- **Estimated Effort**: Zero; falsifies the measurement.
- **Rejection Reason**: The capture queue is the project's accumulator; disabling
  the engine accumulator is required for the stamp law's honesty.

### Alternative 10: Use tree pause as the freeze

- **Description**: `get_tree().paused = true` for hit-stop; `process_mode`
  handles the rest.
- **Pros**: One flag; built-in.
- **Cons**: Tree pause clears/blocks the input service unless `ALWAYS`; it is a
  context gate, not a clock freeze; pending intents must survive hit-stop, but
  pause clears buffers. The GDD's freeze-vs-pause discrimination is the opposite.
- **Estimated Effort**: Low; wrong semantics.
- **Rejection Reason**: Freeze is a clock; pause is a gate. The service runs in
  `ALWAYS` and discriminates explicitly.

### Alternative 11: Store bindings in the SYS-03 save

- **Description**: Persist controls with the save file so they travel together.
- **Pros**: One persistence path; one file.
- **Cons**: Violates TR-INP-036's device-local contract; a save from another
  device would carry another player's hands; the save schema would grow a
  controls field; AC-10's grep would fail.
- **Estimated Effort**: Low; contract violation.
- **Rejection Reason**: `user://controls.cfg` is separate, versioned and
  device-local.

### Alternative 12: Let HUD Controls consume gameplay touches

- **Description**: HUD buttons use `_gui_input`; the world uses its own input.
- **Pros**: Standard Control behavior; less dispatcher work.
- **Cons**: Two consumers for one touch; z-order and overlap at 1.5 become
  GUI-tree accidents; AC-60's "HUD never consumes gameplay touches directly"
  fails; the bubble/chip/zone arbitration becomes untestable.
- **Estimated Effort**: Low; high ambiguity.
- **Rejection Reason**: One dispatcher, one binding, one z-order table.

## Consequences

### Positive

- **One source of truth.** Capture, stamping, windows, gates, custody and
  publication live in one pure core; consumers cannot disagree about a press.
- **Deterministic and replayable.** The two-clock split, injected clock and
  capture stream make AC-07's replay equivalence and AC-55's rate matrix
  testable without a device.
- **Gate terminality is structural.** The phase order, gate-capable-first poll
  and atomic `try_pull` make B4 and NB-J achievable, not aspirational.
- **D1 is exact.** The SubViewport band, native HUD, screen→art transform and
  dead-bar law are one implementation; AC-25/66's arithmetic has a home.
- **Accessibility is native.** Hit floors, scale, mirror, reach disc, pause-menu
  fallbacks and the bubble's 56 dp are geometry, not afterthoughts.
- **Performance is bounded by construction.** Preallocated rings, no hot-path
  allocation, enqueue-only haptics, and a measured S_base/S_burst partition.

### Negative

- **A central service is a bottleneck.** Every gameplay verb routes through
  `InputCore`; a bug there is global. Mitigation: pure core, GUT map, replay.
- **Disabling engine accumulation may cost event overhead.** The probe measures
  it; the fallback is documented, and the stamp law's honesty is worth the cost.
- **The SubViewport adds a render target.** One extra viewport and a band
  composite; the mobile fill-rate budget must be verified (item 8, AC-53).
- **Native HUD means every HUD layout is dp-aware.** SYS-24 cannot rely on a
  global stretch; every region must compute from `RenderMetrics`.
- **The facing cause/epoch contract adds SYS-06 work.** Movement must publish
  the cause, not just the value; the Movement GDD must ratify it.
- **The probe register blocks the first story.** 13 pending items are deliberate;
  shipping on unverified engine assumptions is the larger cost.
- **The pipeline order constrains pullers.** Gate-capable pullers must be
  registered as such; a puller that opens a gate without the flag can violate
  terminality. The registry audit catches it.
- **The capture queue is bounded.** Capacity 256 is sized to the worst-case
  burst; an overflow is a bug, not a silent drop.

### Neutral

- The engine-probe spike remains throwaway; it is evidence, not a dependency.
- This is the first ADR; the architecture registry and TR registry are seeded
  separately by `/architecture-review`.
- The QA plan's 96-unit ledger is written now but executes after the probe gate.
- `FLIP_ATTRIBUTION_WINDOW_TICKS`, queue capacities and `AXIS_BUTTON_THRESHOLD`
  are implementation constants; they are not player-facing knobs.

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Engine API uncertainty (safe area, SubViewport, flushing, haptics) | High | High | The 16-item probe register; `[unverified]` marks; fallbacks documented per item; no story consumes a pending item |
| Mobile density/safe-area variance | Medium | High | Seven-profile matrix; `screen_get_scale` cross-checked with `screen_get_dpi/160`; AC-25/66; device query-vs-physical check |
| Multi-touch/dual-focus routing | Medium | High | Dispatcher-only capture; index tracking; item 2 probe; AC-27 |
| OS touch-cancel under-delivery | Medium | Medium | TR-INP-073 fallback (visibility-change disposal + phantom telemetry); item 15 |
| Focus-loss auto-release | Medium | Medium | Item 14; EX-3 amendment if the engine releases; AC-45 |
| Performance on low-end mobile | Medium | High | AC-53 S_base/S_burst; perf ledger; enqueue-only haptics; preallocation |
| Allocation churn | Medium | High | AC-54 control run; named structures; churn envelope; no hot-path allocation |
| Gate-request race | Low | High | Phase order; gate-capable-first; forward-binding; AC-59; machine audit |
| Flip-attribution wrong | Medium | High | Cause/epoch contract; `FLIP_ATTRIBUTION_WINDOW_TICKS`; AC-38/39; Movement GDD ratification |
| D1 band/crop transform | Medium | High | Item 8 probe; bounds-test + floor division; AC-25/66; crop case |
| Remap backup carries bindings | Low | Medium | Export backup exclusion; document OS caveat; AC-10 |
| iOS haptics cannot honor strength 0 | High | Medium | Item 13; AC-70 carve-out; visual channel carries meaning |
| 96-unit ledger drift | Low | High | Exactly-one proof; manifest↔inline check; QA plan re-derivation |
| O1 residue survives | Low | Medium | ADR + QA plan carry it; one-clause fix; audit re-run + qa-lead spot-check |
| Probe register never closes | Medium | High | AC-74 blocks the first story; the register is the gate; owner per item |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU — input pipeline | N/A (no code) | S_base p99.9 ≤ 1.0 ms, max ≤ 2.0 ms per physics tick; S_burst max ≤ 4.0 ms; enqueue p99.9 ≤ 0.1 ms, max ≤ 0.5 ms | 16.6 ms frame; input is a minority slice |
| Memory — input structures | N/A | Preallocated: slots (9), snapshots (9), trace ring (600 ticks), capture queue (256), gate-request queue (8), haptic ring (64) | ≤ 256 KB dynamic growth; ~150 MB process ceiling |
| Load time | N/A | `controls.cfg` load < 1 ms; no scene preload in the hot path | Negligible |
| Network | N/A | None (single-player) | N/A |

The AC-53/54/65 methodology (reference SKU, workloads, estimators, sample counts,
thermal protocol, monitors, control run) lives in the QA plan's perf ledger.
This ADR owns the requirement bars and the structural choices; the QA plan owns
the measurement.

## Migration Plan

No existing game input code exists; the migration is a greenfield scaffold.

1. **Pure core.** Add `src/input/core/` (`GameClock`, `InputCore`,
   `BufferService`, `Tuning`, `BodySnapshot`, `PulledIntent`) and the GUT suite
   (`tests/unit/input/`). No scene tree, no `Input`.
2. **Node adapters.** Add `InputCapture`, `InputTick`, `InputStateProvider`; boot
   scene; set `Input.use_accumulated_input = false`; add the integration tests.
3. **Render rig.** Add `RenderRig` + `RenderMetrics`; verify item 8 (band
   centering, screen→art, crop, dead bars); wire `TouchDispatcher`; re-register
   on metrics change.
4. **Prompt Slot + remap + haptics.** Add the service, `controls.cfg`, the
   haptic ring; wire SYS-24/SYS-29; add AC-58/67/10/61 tests.
5. **Probe register.** Close all 16 items (verified/amended/reassigned); attach
   the evidence to `production/qa/evidence/sys01/`; update the QA plan.
6. **First story.** Only after step 5; the smoke gate then runs the 67 smoke
   units.

**Rollback plan.** Delete `src/input/` and the boot wiring; no save data
migration is required (`controls.cfg` is additive and device-local). The GDD and
this ADR remain; a superseding ADR would replace the pipeline, not the design
laws.

## Validation Criteria

- [ ] The 96-unit ledger holds: 67 smoke + 19 device + 3 lock + 7 VS = 96, every
      unit exactly once (QA plan's exactly-one proof).
- [ ] The five laws are ratified by the Acceptance Record and verified by their
      named ACs: EX-14/AC-79; B2/AC-32/33/71; B4/AC-44/59; NB-I/AC-21/33/65;
      NB-J/AC-59.
- [ ] D1 is exact: AC-25/66 pass at the seven profiles; item 8 is verified; no
      world tap binds on a bar; the screen→art transform is bit-identical to the
      formula.
- [ ] Flip-attribution: AC-38 (a)/(b)/(c)/(d) pass; AC-39's negative cases
      reset; the press1-induced turn is exempt; no forward double-tap fires.
- [ ] Mirror/reach: AC-34/66/76 pass mirrored and unmirrored; the four gameplay
      centers are inside 200 dp; the pause is exempt but in the gap audit.
- [ ] Gates: AC-44/59 pass, including the death-frame grandfathering at the
      application point; no third verb resolves on the transition frame.
- [ ] Freeze: AC-21/33 pass; raw crouch publishes at the crossing tick; offers,
      acks and expiry suspend; the chip decision/delivery split is exact.
- [ ] Perf/allocation: AC-53/54 pass on the reference SKU; the control run's
      net deltas are zero; S_burst is non-empty; the churn envelope holds.
- [ ] O1: the ratified budget is p99.9 ≤ 2, max ≤ 3; AC-65's protocol measures
      it; the AC-18 one-clause correction is verified by an audit re-run +
      qa-lead spot-check.
- [ ] AC-74: all 16 engine items have a verdict; zero `PROBE-PENDING` before the
      first implementation story.
- [ ] No direct `Input` reads outside `src/input/` (CI grep); every hot-path
      structure is preallocated and bounded; every public API has a doc comment.

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|---|---|---|---|
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-076 — first-`logic_tick` stamping; two clocks; freeze scope | `_input` capture + `Captures` phase + `GameClock` manual freeze; freeze suspends offers/acks/expiry only |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-013/014/066 — events vs states; raw publication; crouch `latch ∨ held_zone` | `publish_raw()` every `physics_tick`; no smoothing/deferral; posture application is SYS-06 |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-047 — gate rules; B4 terminality; NB-J non-ack entry | Phase order; gate-capable-first; forward-binding; queued non-ack requests; application point |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-020/021/022/075 — offer–pull–ack; one consumption; supersede; custody | `try_pull` atomic transaction; one slot per verb; `supersede_count`; ack transfers custody |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-059/063/077 — D1 model; dead bars; safe-area unit law | `RenderRig` + `RenderMetrics`; root stretch disabled; band/crop; native HUD; screen→art |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-056/F-07 — backdash gesture; true-back press1; flip-attribution | `FacingPublication` value/epoch/cause; exemption window; direct-press coalesce; drop-when-busy |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-069/V20 — cluster layout; mirror; reach disc | Canonical frame; mirror map; pause mirrors with stick; 200 dp corner disc; gap audit |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-030/067 — Prompt Slot; bubble; signed latch | `PromptSlotService` sole Interact puller; nearest-wins; stamp binding; signed latch; 56 dp |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-036/037 — device-local bindings; defaults reset | `user://controls.cfg`; schema v1; slot-preserving; a11y exclusion; no save coupling |
| `design/gdd/input-control-mapping.md` | SYS-01 | TR-INP-070 — a11y baseline; hit floors; scale; pause-menu fallbacks | `TOUCH_HIT_SCALE` geometry; 48/44 dp; bubble 56 dp exempt; pause scales; EX-14 delivery |
| `design/gdd/input-control-mapping.md` | SYS-01 | AC-18/59/65 — Early Press; gate terminality; stamp budget | Same-tick offer; gate pipeline; AC-65 protocol; O1 carried |
| `design/gdd/input-control-mapping.md` | SYS-01 | AC-53/54 — frame/allocation bars | Preallocated rings; no hot-path allocation; S_base/S_burst; control run |
| `design/gdd/input-control-mapping.md` | SYS-01 | AC-25/66 — layout audit; seven profiles; V21 | `RenderMetrics`; per-profile ledger; k/band/hit arithmetic; V21 runtime flag |
| `design/gdd/input-control-mapping.md` | SYS-01 | AC-74 — 16 engine verdicts | The verification register; `PROBE-PENDING` blocks the first story |
| `design/gdd/input-control-mapping.md` | SYS-01 | AC-79 — pause-menu actions deliver at the first Gameplay tick | `DeferredSyntheticInput` at phase 1 of the first Gameplay tick; never on the transition frame |
| `design/gdd/systems-index.md` | SYS-06/08/24/32 | Downstream contracts (facing, body_busy, touch regions, world band) | `InputBus`; `FacingPublication`; `TouchDispatcher`; `RenderMetrics` |
| `docs/engine-reference/godot/` | Engine | 4.7.2 post-cutoff compatibility | The 16-item register; `[unverified]` marks; no default-stretch assumptions |

## Acceptance Record — the unfreeze ratification

**Recorded 2026-11-12. Authority: the SYS-01 GDD's #10 diff-scoped record
(`PASS WITH RECORDED OBLIGATIONS`; the review loop is closed at #10).**

### The five laws

| Law | GDD source | Ratified text | Verification |
|---|---|---|---|
| **First-Gameplay-tick delivery** | EX-14; TR-INP-070; AC-79 | A pause-menu a11y action synthesizes ordinary input at the **first Gameplay tick after the transition frame**, through the ordinary pipeline; never on the transition frame. | AC-79; `DeferredSyntheticInput` phase-1 injection |
| **Publish-raw-every-tick** | B2; TR-INP-013/066; F-04 | `move_x`, `crouch` (`latch ∨ held_zone`), `jump_held`, `body_busy`, `facing` publish raw every `physics_tick`, including freeze; no smoothing, no deferral, no commitment-freeze. | AC-32/33/71; `publish_raw()` |
| **Gate-request terminality** | B4; TR-INP-047; AC-44/59 | Any gate request in `T` is terminal for uncommitted acks in `T`; gate-capable pullers first; forward-binding from the raise; grandfathering only for acks before the raise; uncommitted acks at the application point voided. | AC-44/59; phase order + `gate_request_latched` |
| **NB-I freeze-processing scope** | EX-15; TR-INP-076 | While frozen: raw publication and mid-freeze semantic evaluation continue; **offers, acks and expiry suspend**; the chip decides at the crossing and delivers at the first unfrozen boundary, age frozen. | AC-21/33/65; `mid_freeze_phase()` |
| **NB-J non-ack gate-entry rule** | TR-INP-047; AC-59 | Non-ack requests (death, cutscene) queue and apply at the next gate-entry phase — `T`'s own if unrun, else `T+1`'s; terminality effects at that application point; AC-59's death-frame grandfathering depends on it. | AC-59; `apply_queued_gate_requests()` |

### The four owned mechanisms

| Mechanism | GDD source | ADR ownership | Verification |
|---|---|---|---|
| **D1 SubViewport wiring** | TR-INP-059/F-06; D1 | Root stretch disabled; world `SubViewport` 480k×270k centered in the safe rect; native HUD; screen→art bounds-test + floor division; dead bars; crop case. | Item 8; AC-25/66; the layout ledger |
| **Flip-attribution** | TR-INP-056/F-07; D4 | `FacingPublication { value, epoch, cause, changed_tick }`; press1-induced turn exempt within 2 ticks; every other flip resets; direct-press coalesce wins. | AC-38/39; Movement GDD ratifies the cause |
| **Mirror/reach-disc** | TR-INP-069/V20; AC-34/66 | Canonical right-anchored frame; `MIRROR` reflects x; pause mirrors with stick; 200 dp disc on the cluster corner; four gameplay centers inside; pause exempt but in the gap audit. | AC-34/66/76; layout ledger |
| **Pipeline order** | TR-INP-076/047; AC-59 | Captures/supersedes → gate-entry → offers (gate-capable first) → acks → expiry; re-assertion with captures; frozen ticks run 0–2 + mid-freeze only. | AC-17/18/44/59/65; pipeline probe item 10 |

### O1 — carried obligation

**O1 (AC-18).** The stamp-budget head says "arrival→stamp may consume up to 2
`logic_tick`s" while its own parenthetical says "p99.9 ≤ 2 **and** max ≤ 3".
**This ADR ratifies the parenthetical: p99.9 ≤ 2 `logic_tick`s, max ≤ 3** (the
TR-INP-076/AC-65 budget). The head's "up to 2" is a one-clause residue; it is
carried here and by the QA plan's AC-65 protocol. The GDD correction is an
ordinary one-clause edit under the unfrozen regime, verified by a re-run of the
machine cross-reference membership audit + a qa-lead spot-check on the changed
site (the #10 record's route). O1 does not block the ADR's acceptance; it blocks
nothing except its own text.

### Acceptance statement

**ADR-0001 is Accepted.** It ratifies the five laws, owns the four mechanisms,
and carries O1. The QA plan's 96-unit AC→gate ledger is the execution home; the
16-item engine register is the implementation gate. The engine-probe spike is a
throwaway prototype; no probe code is imported, and no `PROBE-PENDING` item is
treated as a settled fact.

| Seat | Acceptance | Date |
|---|---|---|
| technical-director (chair) | Accepted — no open architectural alternative; probe register is the implementation gate | 2026-11-12 |
| gameplay-programmer | Accepted — pipeline, buffer, gates, touch and seams implementable as specified | 2026-11-12 |
| godot-specialist | Accepted — engine claims marked; 13 probe items gate the first story | 2026-11-12 |
| qa-lead | Accepted — 96-unit ledger, O1/AC-65 protocol, evidence paths | 2026-11-12 |
| user | Approved the write; scope authority | 2026-11-12 |

## Related

- **GDD**: `design/gdd/input-control-mapping.md` — the design laws, formulas,
  edge cases, annex EX-1…EX-15, AC-01…AC-79, and the #10 unfreeze record.
- **Review log**: `design/gdd/reviews/input-control-mapping-review-log.md` — the
  #10 entry (O1) and the #8/#9 records (NB-I, NB-J, the 96-unit ledger).
- **QA plan**: `production/qa/qa-plan-sys01-input-control-mapping-2026-11-12.md`
  — the 96-unit ledger, perf/layout/device/playtest protocols, O1/AC-65.
- **Systems index**: `design/gdd/systems-index.md` — SYS-01 row and downstream
  contracts.
- **Engine reference**: `docs/engine-reference/godot/VERSION.md`,
  `modules/input.md`, `modules/rendering.md`, `modules/ui.md`,
  `breaking-changes.md`, `current-best-practices.md`.
- **Next ADRs**: SYS-06 Movement (facing cause, posture handoff, hop-lock rate);
  SYS-08 Combat (arc declarations, commitments, press-age gating); SYS-24 HUD
  (region rendering, bubble/chip visuals); SYS-32 Camera (D1 world band, camera
  reads no input).

