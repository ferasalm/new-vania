# Input & Control Mapping

> **Status**: In Design
> **Author**: user + game-designer/ux-designer/gameplay-programmer (via /design-system)
> **Last Updated**: 2026-11-11
> **Implements Pillar**: "SotN, Not Hollow Knight" (deliberate, weighty controls) · "Read, Then Strike" (inputs answer telegraphs) · touch-first platform goal
> **System ID**: SYS-01 (Foundation layer, MVP — no dependencies; root of the design order)

## Overview

The Input & Control Mapping system is the game's action registry and control-feel contract. It defines every player verb as a named input action — **Move, Jump, Attack, Crouch, Dash (slot reserved, locked at start), Interact (contextual), Quick-use Item (slot reserved)** — and maps them across touch (floating stick + button cluster), keyboard, and gamepad, so the touch-first mobile experience and the day-one PC experience are the same game. On the infrastructure side it owns the cross-platform policies every other system consumes: press/buffer semantics, input priority when verbs conflict, gesture reservation for the Demonic Cyber Stinger (vertical-slice), remapping and persistence, and accessibility. On the experience side it is why the game feels SotN-committed rather than twitchy: every action answers immediately or is buffered deliberately, telegraph-reactive inputs (clash, deflect) stay frame-honest, and nothing important is buried behind a gesture the player must discover. Without it, the game loses its platform promise, its control-weight identity, and the shared action vocabulary that Movement, Combat, Stinger, HUD, and Juice all build on.

→ *Implementation patterns (InputMap layout, buffering service, remap persistence) are specified in the **Input Architecture ADR** — planned; created via `/architecture-decision` and cited by ID here once it exists.*

## Player Fantasy

### The named fantasy — The Body Obeys

You deliberate; she obeys. Every order kept, every commitment honored. You are the will inside a purpose-built chassis, and the body never mishears an order: presses are never lost, never doubled, never second-guessed. Deliberation is safe *because* the body is trustworthy — this is the "slick and smart" competence fantasy at its root. The fiction resonance is free: in the story her body obeys the demon lord; at the input layer, it obeys **you** — the player is the self she is trying not to lose. The fiction labels, never prescribes: no simulated impedance, no "warming up" — the body is precise because the input layer is precise.

### The contract — The Honored Commitment

Pressing is signing. Startup and recovery are the cost of signing — *those values belong to Combat and Movement; this system owns only the trust half*: that a decision, once pressed, is executed honestly through its full arc. Three terms, testable on every rig:

1. **A press is never lost** — the intent window holds it.
2. **A press is never doubled** — the second-hit lockout is honest.
3. **A press resolves at the intended frame** — never swallowed, never fired early into a whiff.

Verb clarity is a term of the contract, not a feature: seven verbs — Move, Jump, Attack, Crouch, Dash, Interact, Quick-use Item — each means exactly one thing, in every room, in every truth, on every rig. Interact's carve-out is honest by design: *one button — the world tells you what it means.* **Three rigs, one body**: touch is the native rig, not an adaptation — parity of contract, not of milliseconds. Never apologize for mobile.

### Reserved slots are promise, not absence

Dash and Quick-use Item are empty sockets in a body built with room to grow — "built for verbs she doesn't have yet" turns locked-at-start into anticipation. When the Stinger arrives (vertical slice), the contract extends to gestures: the game asks for *shapes, never reflexes*, and the touch tolerance window is generosity, codified.

### Anchor moment — The Early Press

A heavy enemy winds up a wide overhead. The player reads it and presses Attack a beat *early*. The intent window holds the press; the body answers on the exact frame of contact: clash, lock, sparks. *The press was early; the answer was on time.* Combat owns the clash's design; **input owns whether the early press was kept** — held within the intent window, resolved at the optimal frame, identical on floating-stick and keyboard. Every failure mode indicts input, not tuning: fires into a whiff (buffer too stingy), fires twice (too greedy), swallowed by lockout (dishonest).

### Language law for this GDD (all sections)

Use *kept, honored, exact, whole, trustworthy*; ban *crisp, snappy, instant, frame-perfect, razor-thin, zero lag* — twitch-coded promises the design rejects. "Precision" is the body's property, never the player's demand. The intent window is "a breath" in player-facing copy; millisecond values live only in Tuning Knobs. Remapping is diegetically *Recalibration* (flavor in the UI half, near-zero cost). No per-press popups — "ORDER RECEIVED" on every button would cheapen MEMORY CACHED's rarity. Falsifiability rule: every feel-sentence must be verifiable by a playtest or build check; if verifying it would need a stopwatch on reflexes, cut it.

*Pillar ties: "SotN, Not Hollow Knight" (deliberation as chosen texture, not sluggishness) · "Read, Then Strike" (an optional miracle must be dependable) · "Remade Every Death" (body half only — the memory/caching fiction belongs to the death systems, not this GDD).*

**Success signature**: playtesters describe the controls in trust-language ("it always does what I mean"), call out the early press unprompted, and nobody — touch or PC — describes startup frames as lag.

## Detailed Design

### Core Rules

**Rule IDs (`TR-INP-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** PROVISIONAL marks indicate contracts with undesigned downstream GDDs; ownership boundaries are intended final.

#### 1 · The action registry — two tiers, seven body verbs forever

- **TR-INP-001 — Two-tier registry.** All player input resolves through one named-action registry: **Tier 1 — body verbs** (the seven-verb vocabulary + reserved Stinger) and **Tier 2 — system verbs** (Pause; Open Map at VS). Tier 2 never aliases a Tier 1 id. *Test: build audit lists every action; each in exactly one tier.*
- **TR-INP-002 — One meaning per verb.** Exactly one semantic meaning across every room, context, rig. *Test: no verb does two things; playtesters can't name a button that "sometimes does two things."*
- **TR-INP-003 — Status lifecycle.** Every action is exactly one of **Active**, **Locked-at-start** (registered, delivery gated by the owning system's grant), **Reserved-VS** (socket only, no consuming code in MVP). *Test: Dash pre-unlock produces no execution and no error state.*
- **TR-INP-004 — No derived moves in the registry.** "Crouch attack," "air attack," "clash" are not input actions — they are Combat states produced from (verb press + body state). The registry stays at seven body verbs forever. *Test: a third aerial variant requires zero registry/input changes.*
- **TR-INP-005 — Single puller per verb.** One designated consumption owner per action; second registration rejected. *Test: unit test injects two consumers; second is rejected.*

**Tier 1 — Body verbs**

| Verb | action_id | Status | Puller | Notes |
|---|---|---|---|---|
| Move | `move_x` | Active | SYS-06 (axis read) | Also the gesture-trace source (SYS-12, VS) |
| Jump | `jump` | Active | SYS-06 | Event + held state; **behavior-level gating — see TR-INP-057** |
| Attack | `attack` | Active | SYS-08 | Window-override hook ready (proven 140 combo value) |
| Crouch | `crouch` | Active | SYS-06 (state), SYS-08 (pairing) | State channel — never a buffered press |
| Dash | `dash` | **Locked-at-start** | SYS-06 | Gate lives in SYS-06; input delivers regardless |
| Interact | `interact` | Active | The active prompt's publisher | Floating bubble (TR-INP-067); never shared with Attack |
| Quick-use Item | `quick_item` | Reserved slot (empty in MVP) | SYS-17 at VS via SYS-24 chip | Touch = HUD chip, hold-to-commit (TR-INP-068) |
| Demonic Cyber Stinger | `stinger` | **Reserved-VS** | SYS-12 | Composite gesture (TR-INP-031) |

**Tier 2 — System verbs**: `pause` (Active, SYS-05 — verb ours, menu content theirs); `open_map` (Reserved-VS, SYS-25 — touch surface: pause-menu tab, PROVISIONAL).

- **TR-INP-057 — Behavior-level gating (traversal ladder).** The Jump action is live from day one; its **air-jump** and **wall-jump** behaviors unlock through progression — ladder: **Dash → Wall Jump → Double Jump** (user-mandated 2026-11-11). Gates are Movement's (SYS-06); input delivers every Jump press honestly regardless of unlock state. Contrast with Dash's action-level lock (TR-INP-003). *Test: pre-unlock double-tap jump mid-air executes nothing and errors nowhere; post-unlock it executes — input behavior bit-identical in both cases.*
- **TR-INP-056 — Backdash gesture (MVP, day-one).** Double-tap **back** with a release between taps, both edges inside `BACKDASH_TAP_WINDOW_MS` (default 280 — generous, SotN-exact feel). Touch: flick-back → release → flick-back on the floating stick; keyboard/gamepad: double-tap the back binding. The detector publishes a `backdash` intent; **SYS-06 pulls and owns the hop**. **Reflex-class: not buffered** — fires when the body is free at pattern completion; if the body is committed, the pattern is dropped (a delayed dodge can walk the player into a hit). Brief i-frames are the combat GDD's ruling (defensive family: backdash · Dash · clash). *Test: tap-tap-back on empty ground = hop; tap-tap-back during attack recovery = nothing; held back = walk, never backdash.*

#### 2 · Cross-rig mapping — touch native, three rigs one body

- **TR-INP-006 — Semantic channels, per-rig sources.** The registry names semantic channels; rigs bind physical sources to them. The body is one; the rigs are three ways of addressing it.
- **TR-INP-007 — Touch is designed first.** Parity of contract, not of milliseconds.
- **TR-INP-008 — Touch fixed semantics (non-negotiable).** Crouch = stick down-zone only; Quick-use = HUD chip hold only; Interact = floating bubble only. The rig's identity; never rebound. *Test: Recalibration offers no control that can change these three semantics.*
- **TR-INP-009 — Touch ergonomics are rebindable.** Side-swap (mirror), button size presets, cluster opacity, stick leash/deadzone, down-zone thresholds. *Test: left-handed playtester swaps sides, completes MVP with zero input failures.*
- **TR-INP-010/011 — Dual keyboard defaults; standard gamepad face layout.** All rebindable except crouch's rig-fixed source.

| Verb | Touch (native, fixed) | Keyboard (defaults) | Gamepad (defaults) |
|---|---|---|---|
| Move | Floating stick, left 42% zone, analog bands | `A`/`D` + `←`/`→` (both pre-bound); **walk-only at MVP** (creep band is the analog rigs' gift; rebind later if PC data wants it) | Left stick (band policy) + d-pad |
| Jump | Jump button, touchdown | `Space` + `Z` | `A` / Cross |
| Attack | Attack button (largest, innermost), touchdown | `X` + `J` | `X` / Square |
| Crouch | Stick **down-zone** cone (hold) — LOCKED | `Down`/`S` (hold) | Stick-down + d-pad-down |
| Dash | Dormant-visible socket (TR-INP-012) | `Shift` (**ratified**: the pre-pivot key reborn as Dash) | `RB` / R2 |
| Interact | **Floating bubble beside the interactable** | `E` | `Y` / Triangle |
| Quick-use Item | **HUD chip, 150 ms hold-to-commit** | `Q` | `LB` / L1 |
| Stinger (VS) | Quarter-spin on stick + Attack (gesture only) | `↓↘→` + Attack | `↓↘→` + Attack |
| Pause | Corner control outside all zones | `Esc` (+`P`) | `Start` / Menu |
| Open Map (VS) | Pause-menu tab (proposed) | `M` | `Select` / Back |

- **TR-INP-012 — Dormant sockets policy (ratified).** The Dash touch socket exists from day one at its final position — **dormant-visible** (dimmed, lock glyph; "dimmed after first tease" knob) so muscle memory pre-forms and the unlock lands as promise kept. The Stinger gets no socket — motion input needs no button. *(Dormant rendering: PROVISIONAL pending SYS-24 sign-off.)* *Test: pre-unlock Dash press is non-interactive, post-unlock same position lights and executes.*

#### 3 · Delivery semantics — events and states

- **TR-INP-013 — Two channels.** **Events** (Jump, Attack, Dash, Interact, Quick-use, backdash) are edge-triggered intents that may be buffered. **States** (move axis, crouch, jump-held, grounded, body-busy) are continuously readable body truth. Events may wait; states never do.
- **TR-INP-014 — States are raw.** No smoothing, no grace of its own; hardware-noise deadzone only. Walk/run curves and coyote are Movement's. *Grace belongs to Movement and Combat — never to the post office.* *Test: toggling coyote changes behavior while the reported `grounded` stream is bit-identical.*
- **TR-INP-015 — Edge-triggered only; OS repeat filtered.** Hold = one press. *Test: 3 s hold under OS key-repeat = exactly one press.*
- **TR-INP-016 — Multi-touch is table stakes.** ≥3 simultaneous contacts, zero cross-capture. *Test: move + jump + attack concurrently.*
- **TR-INP-017 — Holding is the buffer states already have.** States are never buffered; a held state persists into the next resolvable frame (airborne Down held → still held on landing).

#### 4 · The intent window — "a breath" (all ratified)

- **TR-INP-018 — One service, uniform default, per-verb single slots.** `INTENT_WINDOW_MS` = 140 default applied per verb's own slot — *not* one shared slot (same-frame Jump+Attack both survive). Per-verb overrides via tuning map. *Test: same-frame Jump+Attack during recovery → both pending independently.*
- **TR-INP-019 — Entry.** A press enters at its press frame with a **press-frame body snapshot** (crouching, grounded, move_x, body-busy) attached.
- **TR-INP-020 — Offer–pull–ack.** Input **offers** the pending intent to its single puller every frame; the puller decides when to pull (Combat pulls at the clash-contact frame) and **acks**; input clears the slot. Input never executes on its own — it structurally cannot fire early into a whiff. *Test (the Early Press): attack pressed early during a windup → offered each frame → pulled at the strike-contact frame → clash.*
- **TR-INP-021 — One consumption.** A pulled intent cannot fire twice; a new press opens a new window. Layered with Combat's active-frame lockout, "never doubled" holds twice over.
- **TR-INP-022 — Latest Order Honored (the anti-mash rule).** A second press of the same verb while pending **supersedes** it — one slot per verb; mashing cannot buy more resolutions than deliberate play. *Test: 12 taps/s and 4 taps/s produce identical stall durations.*
- **TR-INP-023 — Expiry is silent.** Dropped with no execution, no notification (per-press popups would cheapen MEMORY CACHED's rarity).
- **TR-INP-024 — The window ticks on the game clock (ratified).** Hit-stop extends the breath 1:1; paused contexts clear intents outright. Touch impulse verbs commit on **touchdown** (ratified); the release is delivered as an honest separate event (unused at MVP; enables hold-glide later with zero input changes). *Test: buffered press consumed N ms of game-time later regardless of wall-clock; jump pressed mid-clash window resolves at touchdown.*
- **TR-INP-025 — Jump-buffering vs coyote, the division.** Press 60 ms before landing → held → Movement pulls → jump on landing (input's buffering). Press 60 ms after walking off → input already reported airborne honestly; firing is Movement's coyote call. Input is identical in both coyote settings.
- **Conversion law (ratified).** `ticks = ceil(ms × physics_tps ÷ 1000)` — 140 ms → **9 ticks (150 ms @ 60 Hz)**: the window never rounds stingy. Override knobs are expressed in milliseconds; conversion is centralized in the buffer service. *Other touch feel timers (fades, hold-guards, hysteresis) run on wall-clock* — they are UI-feel, not gameplay intents (TR-INP-061).

#### 5 · Priority and conflict resolution — the post-office doctrine

- **TR-INP-026 — Input delivers, timestamps, dedupes; it does not judge.** Verbs are compatible by default; consumers arbitrate with honest, complete delivery.

| Overlap case | Rule | Owner |
|---|---|---|
| State + event (crouch held + Attack) | Both delivered; consumer selects the derived move | SYS-08 |
| Two events, same frame | Both delivered, arrival order preserved | consumers |
| Same verb repeated in window | Latest Order Honored — one pending intent | SYS-01 |
| Same verb after consumption | New window; one press = one execution | SYS-01 |
| Verb vs gated context | Gate holds the verb; buffers cleared at gate entry | SYS-01 |
| OS repeat / held button | Edge-trigger only | SYS-01 |
| Hit-stop vs window | Window ticks on game clock | SYS-01 + SYS-29 |
| Interact, no bubble lit | Expires immediately — no pre-range buffering | SYS-01 |
| Composite vs plain (VS) | Composite precedes plain in the same frame | SYS-12 |

- **TR-INP-028 — Derived-move boundary (ratified).** *Crouch-state + Attack = crouch attack* is **Combat's rule** over input's honest delivery. **Consumption-frame body state governs** derived-move selection; the press-frame snapshot rides along as intent context (input delivers both timestamps so Combat can choose without re-plumbing). *Test: crouch → Attack → release crouch mid-window before the pull → stand attack executes; snapshot still logged `crouching=true`.*
- **TR-INP-029 — Body availability.** Interact (and Quick-use at VS) resolve only when the body is **available**: Movement publishes locomotion-locks, Combat publishes commitments; input ORs them into `body_busy`. A pending interact waits inside its window until the commitment ends — the body finishes what it signed before signing anew. *Test: tap Interact mid-swing beside a cache → opens at recovery end; tap outside the window → nothing.*
- **TR-INP-030 — Interact means the lit bubble.** Interact enters its window **only when a prompt is lit**; presses with no target expire immediately (ratified — no walk-by accidental saves). *Test: press Interact in an empty corridor → nothing; a later-lit bubble does not consume the stale press.*

#### 6 · Gestures

- **TR-INP-031 — Composite action structure (Stinger, VS).** `stinger` = (directional pattern) + (attack press), each with its own tolerance window, consumed once when both are satisfied. Touch: quarter-spin on the stick; keyboard/gamepad: `↓↘→` + Attack. The touch tolerance window is *generosity, codified* — a knob, not a reflex test.
- **TR-INP-032 — Reservation by presence-of-a-small-thing (amended 2026-11-11).** MVP ships **one** piece of gesture machinery: the TR-INP-056 backdash detector (backdash is day-one). The Stinger recognizer remains **flagged out of MVP builds** (hook idle, not dead code). What the reservation leaves in place: the registry socket, the buffer's composite-registration hook + `gesture` tag on press records, and the stick's raw trace channel. Adding the Stinger later requires no changes to the seven verbs' delivery path. *Test (MVP): grep/audit confirms no stinger code path executes; backdash detector active.*
- **TR-INP-033 — Composite precedence (VS).** Pattern completed + attack pending → the composite consumes the press; the plain attack does not also fire. *Test: quarter-spin + Attack = exactly one Stinger; quarter-spin alone = nothing.*
- **TR-INP-058 — Unhinted-tech doctrine (user-mandated).** The **backdash → Stinger counter** and similar emergent chains are real and **never taught** — no tutorial, log, or bestiary hint; the player figures them out (SotN playground-culture depth). Guard: both gestures must remain natural enough to stumble into; playtest checks discoverability by exposure, not by hinting. *Test: no hint surface references the combo; a hint-free playtest cohort can still produce at least one spontaneous discovery report.*

#### 7 · The touch surface contract (the dp law)

- **TR-INP-059 — Two canvases, one truth.** The world renders at 480×270 integer-scaled; the touch/HUD layer lays out at **screen resolution in dp** with hit-rect floors: `hit = max(art_size, dp_floor / hud_scale)`. Target sizes in dp/mm, never art pixels. *Test: hit circles ≥ dp floors at every device scale.*
- **TR-INP-060 — Touchdown binding.** Each touch binds to exactly one region at landing (movement zone / one button / one chip / one bubble / dead); no mid-touch rebind; release unbinds. Stick finger + chip/bubble finger work simultaneously. *Test: two-finger stick + attack tap.*
- **TR-INP-061 — Clock split.** The intent window ticks on the **game clock** (TR-INP-024); every other touch feel timer (fades, hold-guards, hysteresis) runs on **wall-clock** — UI-feel is not gameplay intent, and frame-rate independence is the glitch doctrine.
- **TR-INP-062 — Impulse vs state (touch-facing taxonomy).** Impulse verbs (Attack, Jump, Dash, Interact, Quick-use) are single signatures through the intent window; state verbs (Move, Crouch) are held orders with no buffer — honored while held, never queued.
- **TR-INP-063 — Letterbox bars are dead taps.** Zones live on the art viewport only. Predictable over clever.
- **TR-INP-064 — No per-press popups (ratified, all rigs).** Touch acknowledgment = held-state visual + light haptic tick. The player sees and feels the signature; nothing announces it in words.
- **TR-INP-065 — Movement band policy (ratified: walk-only keyboard at MVP).** One axis, three orders: neutral < 0.25 · creep 0.5× ≥ 0.25 · walk ≥ 0.45, with hysteresis on every boundary. Analog rigs *measure* the bands; keyboard presses what it has (walk; creep unbound at MVP). *Rationale: SotN identity makes distances learnable in walk-lengths — rooms are designed in committed strides; continuous analog would mishear every re-summoned thumb ("she inched at 73% when I meant to stand").*
- **TR-INP-066 — Crouch cone.** Narrow entry (half-angle 25°, magnitude 0.65, **90 ms hold guard** — a brush is not an order) → wide exit (45°, 0.40) so crouch-walking works on diagonals without popping up. Deferred-during-commit, never discarded (still in-zone when the body frees → she crouches then). Jump stands her up. Toggle crouch mode is an a11y option (TR-INP-070); hold is the locked default.
- **TR-INP-067 — Floating Interact bubble (ratified).** Spawns adjacent to the interactable, offset toward screen interior (≥16 dp edges, ≥12 dp clear of cluster/pause; prefer-above fallback; leader line beyond 90 dp). Label: ≤6-char imperative, ≥14 dp text, icon + text, ≥4.5:1 contrast. Range hysteresis consumed from the world (input owns presentation only); fades 100/150 ms; nearest wins; **56 dp hit** — larger than the floor because a dynamically appearing control deserves slack. Disabled-vs-hidden rule: **proximity-gated → hidden; state-gated → dimmed with the reason in the label** ("SHIFTING — WAIT") — never a silent grey slot. *World word list belongs to narrative + HUD GDDs; the mechanic is owned here.*
- **TR-INP-068 — Chip hold-to-commit — "spend weight" (ratified).** Touchdown → preview (ring, name, count, light haptic); release after ≥150 ms → commit (this moment is the `quick_item` press for window purposes); slide-off → cancel free; panic brush → distinct "not signed" haptic, no order. The governing principle for every future verb: **confirmation weight matches the verb's cost.** *Test: <150 ms touch-and-lift = no item consumed, always.*
- **TR-INP-069 — Cluster layout & mirror.** Two-thumb default: Attack (88 dp right / 56 dp up, 60 dp visual), Jump (44/100, 56), dormant Dash socket (44/36), pause corner 48 dp; stick zone left 42% with home ghost; `CLUSTER_GAP_DP` 12; mirror toggle for left-handers; one-thumb viability preserved by a ≤30%-screen cluster band. Letterbox/dead-zone margins per TR-INP-063.
- **TR-INP-070 — Accessibility baseline.** Hit floors 48 dp gameplay (44 dp absolute floor, secondary UI only); `TOUCH_HIT_SCALE` ×1.0/1.25/1.5 hit-only; crouch hold/toggle; attack hold-repeat off by default (toggle for motor fatigue); haptics as a channel with global strength (low-vision gain; light = press/preview, medium = commit/use, heavy = clash/stagger — meaning owned by Combat); **meaning = text + shape, never color alone**; AccessKit role/name/focus through pause → Recalibration; Interact's label is the bubble's accessible name; no hover-only interactions; no input timeouts anywhere. Touch help overlay in pause.

#### 8 · Remapping — Recalibration

- **TR-INP-034 — Rebindable scope.** Keyboard + gamepad bindings for every Tier 1/Tier 2 action; touch ergonomics per TR-INP-009.
- **TR-INP-035 — Fixed scope.** Touch semantic bindings (TR-INP-008); Interact/Attack exclusivity; gesture patterns at VS; the intent window (a tuning knob, not a binding).
- **TR-INP-036 — Device-local, versioned persistence.** Bindings persist to `user://controls.cfg` (schema-versioned ConfigFile) — **never inside SYS-03 save slots**; explicit non-dependency. *Test: save travels across devices, bindings do not.*
- **TR-INP-037 — Defaults restore.** One control restores factory bindings + ergonomics; flavor copy in the UI half as *Recalibration*.

### States and Transitions — the input context model

- **TR-INP-045 — Single active context; SYS-05 owns the state machine.** Exactly one context active at a time (stackable — `paused` may hold `menu-focus` above it). **SYS-05 owns context state; input owns gate enforcement.** The one upstream owner input defers to unconditionally.
- **TR-INP-046 — The gating table.**

| Context | Gameplay verbs | Intent buffers | Input goes to | Entry | Exit |
|---|---|---|---|---|---|
| **Gameplay** | all live verbs (Dash per unlock) | ticking (game clock) | rig → verb pullers | focus restored; resume; exit any gate | `pause`; bubble-confirm on cache; log opened; cutscene |
| **Paused** | none | **cleared at entry** | SYS-05 pause menu | `pause`; **app blur (forced)** | resume; quit flow |
| **Menu-focus** | none | cleared | UI focus/nav layer | open submenu | back → Paused |
| **Reading** (logs/dialogue) | none | cleared | SYS-28 advance controls | pickup confirm; story trigger | close → Gameplay |
| **Cache-terminal** | none | cleared | SYS-15 terminal menu | Interact on cache | leave control → Gameplay |
| **Cutscene** (VS) | none (skip only) | cleared | SYS-05 script | scripted | script end → Gameplay |

- **TR-INP-047 — Universal gate rules (ratified).** (1) **Buffers clear at gate entry** — no stale order survives a context change; held *states* persist (physical truth of fingers still down). (2) **Atomic transitions** — no verb resolves on the transition frame. (3) **No auto-timeout** — no context expires input availability. (4) **App blur = forced pause from any context**; restore returns to Paused, never straight to Gameplay. (5) Platform Back maps to the active context's back action; in Gameplay it opens Pause. *Test: attack pressed on the same frame the menu opens → nothing fires on resume; blur mid-fight → paused on return.*
- **TR-INP-048 — Reading is a full gate, deliberately.** Logs and dialogue freeze the world — story demands deliberation, and touch has no hover to peek. Advance/skip policy is SYS-28's (PROVISIONAL); input supplies the gated channel.

### Interactions with Other Systems

| Contract | Input owns | Consumer owns |
|---|---|---|
| **Offer–pull–ack** | window timing, slots, gates, clock | when to pull and what execution means |
| **State publication** | raw pass-through | computing the states (grounded: SYS-06; commitments: SYS-08; body-busy: ORed) |
| **Prompt Slot** | lighting the bubble; consuming presses to the publisher | publishing at most ONE prompt (nearest), label text, predicates |
| **Window-override hook** | the override map mechanism | per-verb values (Combat's proven 140 lives here) |
| **Touch dispatcher** | all on-screen touch capture | region registration + visuals (SYS-24) |
| **Clock contract** | game-clock countdown honoring hit-stop | requesting hit-stop (SYS-29) |

- **SYS-05 Game Flow (upstream, PROVISIONAL):** gets `pause` events + the ContextGate service; returns context transitions + quit semantics. Input owns gate enforcement; SYS-05 owns context state and menu content.
- **SYS-06 Movement (PROVISIONAL):** gets `move_x` raw axis (deadzone hygiene only), `crouch` state + edges, `jump` event + held state, `dash` event, `backdash` intent (TR-INP-056); returns `grounded` publication, locomotion-lock contribution to `body_busy`, consumption acks. **Boundary: input never ramps the axis — every feel curve, the committed movement lock, coyote, and all traversal gates (Dash/Wall Jump/Double Jump) are theirs.** *Contract test: mocked axis stream behaves identically to human input.*
- **SYS-08 Combat (PROVISIONAL):** gets attack presses + snapshots + the override hook; returns pull discipline, commitment publication, second-hit lockout. **Crouch+Attack = Combat's rule over input's delivery (TR-INP-028).** Anti-stall note: Latest-Order-Honored caps mashing structurally; residual counter-clash stall tuning is Combat's (prototype evidence). Defensive family for their i-frames ruling: backdash · Dash · clash.
- **SYS-12 Stinger (Reserved-VS, PROVISIONAL):** gets recorded stick trace, directional stream, attack presses, composite hook; returns composite intents. MVP footprint: the backdash detector only (TR-INP-032 amended).
- **SYS-24 HUD (PROVISIONAL, co-owned with ui-programmer):** gets binding-display data, rig states (bubble lit/label, dormant socket, chip state); returns touch-region registrations. **HUD never consumes gameplay touches directly** — one dispatcher, no double-handling. *Test: chip tap with no item = silent no-op.*
- **SYS-29 Juice (PROVISIONAL):** hit-stop requests honored by the clock contract; event hooks for rig press/depress haptics; no per-press popups ever.
- **SYS-15 Cache Stations (PROVISIONAL):** the flagship Prompt Slot publisher ("CACHE"); terminal contexts coordinated with SYS-05. The slot generalizes to SYS-02 doors, SYS-20 memories, SYS-28 logs, SYS-11 seams — one prompt registry serves every interactable.
- **Explicit non-dependency:** SYS-03 saves never carry bindings (TR-INP-036). SYS-09/10 rendering/mutation: no direct input dependency (SYS-11 only via the Prompt Slot).

*Implementation note: the InputMap layout, buffer-service shape (pure, clock-injected, lazy expiry), floating-stick pattern (raw ScreenTouch/Drag with index tracking actuating real InputMap actions so all rigs share one read path), and the GUT test seams are **ADR raw material** — captured for the planned Input Architecture ADR, not designed here. Eleven 4.7-specific verification items (device-ID constants, dual-focus touch routing, emulation defaults, `action_press` × deadzone interplay, same-tick capture/consume ordering, SDL3 rumble API, recursive-disable property, stretch defaults) ride with that ADR.*

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
