# Input & Control Mapping

> **Status**: Designed (pending review)
> **Creative Director Review (CD-GDD-ALIGN)**: CONCERNS (accepted) 2026-11-11
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
- **TR-INP-004 — No derived moves in the registry (amended 2026-11-11: eight body verbs).** The registry holds **eight** body verbs: the seven press verbs + **`backdash`** (a RECOGNIZED verb — the gesture detector publishes it from the stick, or it arrives as a direct press via its accessibility sources; see TR-INP-056). "Crouch attack," "air attack," "clash" are not input actions — they are Combat states produced from (verb press + body state). No NINTH body verb without a ratification amendment. *Test: a third aerial variant requires zero registry/input changes; the count is eight and audited (AC-01/AC-04).*
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
| Backdash | `backdash` | Active | SYS-06 | Touch: double-tap-back on the stick (fixed). KB `C` / pad `B` = direct a11y press (rebindable). Reflex-class, single-tick offer (TR-INP-056, Annex EX-1) |
| Demonic Cyber Stinger | `stinger` | **Reserved-VS** | SYS-12 | Composite gesture (TR-INP-031) |

**Tier 2 — System verbs**: `pause` (Active, SYS-05 — verb ours, menu content theirs); `open_map` (Reserved-VS, SYS-25 — touch surface: pause-menu tab, PROVISIONAL).

- **TR-INP-057 — Behavior-level gating (traversal ladder).** The Jump action is live from day one; its **air-jump** and **wall-jump** behaviors unlock through progression — ladder: **Dash → Wall Jump → Double Jump** (user-mandated 2026-11-11). Gates are Movement's (SYS-06); input delivers every Jump press honestly regardless of unlock state. Contrast with Dash's action-level lock (TR-INP-003). *Test: pre-unlock double-tap jump mid-air executes nothing and errors nowhere; post-unlock it executes — input behavior bit-identical in both cases.*
- **TR-INP-056 — Backdash gesture (MVP, day-one).** Double-tap **back** with a release between taps, both edges inside `BACKDASH_TAP_WINDOW_MS` (default 280 — generous, SotN-exact feel). Touch: flick-back → release → flick-back on the floating stick; keyboard/gamepad: double-tap the back binding — **or the a11y direct source** (KB `C` / pad `B`, rebindable; touch = toggle-only cluster socket). The detector publishes a `backdash` intent; **SYS-06 pulls and owns the hop**. **Reflex-class: not buffered** — fires when the body is free at pattern completion; if the body is committed, the pattern is dropped (a delayed dodge can walk the player into a hit). Brief i-frames are the combat GDD's ruling (defensive family: backdash · Dash · clash). **Direction discipline (review fix):** press1 and press2 must be WALK-band entries with the **same** sign, opposite `facing`; a forward-sign WALK entry between them, or a `facing` flip, **resets the machine to IDLE** (a direction change is a different gesture); creep-magnitude wobble between edges is ignored. **Arming:** press edges are entries into the arming zone — by default the walk band (one definition of "back is pressed"; a shallow tap peaking below the threshold is *correctly* a walk, not a tap); the `BACKDASH_ARM_MAG` fallback decouples the gesture from the walk band only if device evidence (AC-64) shows natural flicks under-arm (pairwise-validated, V12). Release = dropping strictly below the arming threshold. *Test: tap-tap-back on empty ground = hop; tap-tap-back during attack recovery = nothing; held back = walk, never backdash; forward-press between the back presses = reset.*

#### 2 · Cross-rig mapping — touch native, three rigs one body

- **TR-INP-006 — Semantic channels, per-rig sources.** The registry names semantic channels; rigs bind physical sources to them. The body is one; the rigs are three ways of addressing it.
- **TR-INP-007 — Touch is designed first.** Parity of contract, not of milliseconds.
- **TR-INP-008 — Touch fixed semantics (non-negotiable).** Crouch = stick down-zone only; Quick-use = HUD chip hold only; Interact = floating bubble only. The rig's identity; never rebound. **Amendment (review fix, Annex EX-2):** ratified a11y modes — crouch toggle via double-tap-down, the a11y Backdash button/key, chip tap-commit at 50 ms — are **settings, not rebindings**, enumerated in the Contract-Exceptions annex; the Recalibration audit treats them as settings (AC-09 rider). *Test: Recalibration offers no control that can change the three semantics; the a11y toggles appear as settings.*
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
- **TR-INP-014 — States are raw.** No smoothing, no grace of its own; hardware-noise deadzone only — **and only in F-02: engine InputMap deadzones are forced to 0 at registration so exactly one layer owns noise rejection** (review fix; the signed-strength representation for injected/hardware action strength is an ADR decision, OQ#1). Walk/run curves and coyote are Movement's. *Grace belongs to Movement and Combat — never to the post office.* *Test: toggling coyote changes behavior while the reported `grounded` stream is bit-identical.*
- **TR-INP-015 — Edge-triggered only; OS repeat filtered.** Hold = one press. *Test: 3 s hold under OS key-repeat = exactly one press.*
- **TR-INP-016 — Multi-touch is table stakes.** ≥3 simultaneous contacts, zero cross-capture. *Test: move + jump + attack concurrently.*
- **TR-INP-017 — Holding is the buffer states already have.** States are never buffered; a held state persists into the next resolvable frame (airborne Down held → still held on landing).

#### 4 · The intent window — "a breath" (all ratified)

- **TR-INP-018 — One service, uniform default, per-verb single slots.** `INTENT_WINDOW_MS` = 140 default applied per verb's own slot — *not* one shared slot (same-frame Jump+Attack both survive). Per-verb overrides via tuning map. *Test: same-frame Jump+Attack during recovery → both pending independently.*
- **TR-INP-019 — Entry.** A press enters at its press frame with a **press-frame body snapshot** (crouching, grounded, move_x, body-busy) attached.
- **TR-INP-020 — Offer–pull–ack.** Input **offers** the pending intent to its single puller every frame; the puller decides when to pull (Combat pulls at the clash-contact frame) and **acks**; input clears the slot. Input never executes on its own — it structurally cannot fire early into a whiff. **Pull–ack atomicity (review fix):** pull and ack are **one atomic service call** — `try_pull(verb) → intent | none` — the consumed flag, the snapshot, and the custody transfer are a single transaction committed **before** the puller's accept is invoked. A puller that faults after commit has been *honored but unexecuted* — logged as a puller fault, never re-offered (one-consumption is absolute); the slot can never be observed half-consumed. Dev assert: accept completes within the tick. *Test (the Early Press): attack pressed early during a windup → offered each frame → pulled at the strike-contact frame → clash.*
- **TR-INP-021 — One consumption.** A pulled intent cannot fire twice; a new press opens a new window. Layered with Combat's active-frame lockout, "never doubled" holds twice over.
- **TR-INP-022 — Latest Order Honored (the anti-mash law, corrected theorem).** A second press of the same verb while pending **supersedes**: `press_tick` and snapshot are replaced, the window restarts, one slot per verb forever. The law's true guarantees: **(G1) count** — the slot resolves at most once per consumption; mashing cannot produce a second resolution while the first is pending (layered with Combat's active-frame lockout, "never doubled" holds twice over). **(G2) freshness** — the order honored at any pull is the most recent press at that tick. **(G3) keep-alive corollary, owned explicitly** — a same-verb stream whose inter-tap gap ≤ `window_ms` maintains an unbroken pending slot and can carry an order across an arc longer than one window; it cannot create extra resolutions (G1) and the honored order is always fresh (G2); residual chain-rate consequences are Combat's tuning (ratified boundary). **Retracted claim (Annex EX-6):** "identical stall durations across tap rates" is false — a stream whose inter-tap gap exceeds `window_ms` leaves pending gaps, and a pull frame inside a gap resolves nothing. Stall parity is not an input guarantee and never was. *Test: 12 t/s stream (83 ms gaps) across a 600 ms arc mock → pending at every tick of the arc, exactly one resolution at the mock's pull frame; 4 t/s stream (250 ms gaps) against the same arc → pending gaps exist and a pull frame in a gap resolves nothing — both behaviors asserted, not assumed.*
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
- **TR-INP-029 — Body availability.** Interact (and Quick-use at VS) resolve only when the body is **available**: Movement publishes locomotion-locks, Combat publishes commitments; input ORs them into `body_busy`. A pending interact waits inside its window until the commitment ends — the body finishes what it signed before signing anew. **Derivation law (review fix, Annex EX-4):** `INTERACT_WINDOW_MS` is **derived, not tuned** — at publisher registration each body-busy publisher declares `worst_case_arc_ms`; the buffer computes `INTERACT_WINDOW_MS = max(all declared arcs) + INTERACT_MARGIN_MS` and re-derives when publishers register/unregister (**owner: SYS-08 + SYS-06 jointly**). A publisher that fails to declare: dev assert + fallback to `INTENT_WINDOW_MS` (fail-open keeps the verb alive). The TR-INP-029 promise ("mid-swing tap → terminal opens at recovery end") is now *structural*. **Production watchdog:** dev — silent publisher = loud assertion; production — behavior unchanged (fail-open **is** the shipping behavior) + a rate-limited (≤ 1/min) telemetry event naming the publisher. *Test: tap Interact mid-swing beside a cache → opens at recovery end; tap outside the window → nothing.*
- **TR-INP-075 — Pull-and-hold custody (all verbs; Annex EX-5).** The ack transfers custody. The puller owns the honored intent through its own arc; input neither re-offers a consumed slot nor retains a copy, and a pulled order that dies mid-arc (gate entry) dies with the arc — it never re-enters an input buffer. Coverage: **Attack** — held across the Combat arc (SYS-08's ruling); **Jump, Dash, Interact, Quick-use** — execute-at-pull, no custody gap; a future pull-then-execute-later design inherits this rule automatically. *Test: a pulled attack intent survives a Combat-mock 300-tick arc and resolves at the mock's chosen execution frame; input-side records show the slot cleared at the ack tick.*
- **TR-INP-030 — Interact means the lit bubble.** Interact enters its window **only when a prompt is lit**; presses with no target expire immediately (ratified — no walk-by accidental saves). *Test: press Interact in an empty corridor → nothing; a later-lit bubble does not consume the stale press.*

#### 6 · Gestures

- **TR-INP-031 — Composite action structure (Stinger, VS).** `stinger` = (directional pattern) + (attack press), each with its own tolerance window, consumed once when both are satisfied. Touch: quarter-spin on the stick; keyboard/gamepad: `↓↘→` + Attack. The touch tolerance window is *generosity, codified* — a knob, not a reflex test.
- **TR-INP-032 — Reservation by presence-of-a-small-thing (amended 2026-11-11).** MVP ships **one** piece of gesture machinery: the TR-INP-056 backdash detector (backdash is day-one). The Stinger recognizer remains **flagged out of MVP builds** (hook idle, not dead code). What the reservation leaves in place: the registry socket, the buffer's composite-registration hook + `gesture` tag on press records, and the stick's raw trace channel — **a ring buffer of `TRACE_RING_TICKS` (600 ticks = 10 s @ 60), bounded memory by construction** (the backdash detector needs edge events only — stateless; a future composite gesture ≈ < 2 s fits the window with margin). Adding the Stinger later requires no changes to the seven press verbs' delivery path. *Test (MVP): grep/audit confirms no stinger code path executes; backdash detector active.*
- **TR-INP-033 — Composite precedence (VS).** Pattern completed + attack pending → the composite consumes the press; the plain attack does not also fire. *Test: quarter-spin + Attack = exactly one Stinger; quarter-spin alone = nothing.*
- **TR-INP-058 — Unhinted-tech doctrine (user-mandated).** The **backdash → Stinger counter** and similar emergent chains are real and **never taught** — no tutorial, log, or bestiary hint; the player figures them out (SotN playground-culture depth). Guard: both gestures must remain natural enough to stumble into; playtest checks discoverability by exposure, not by hinting. *Test: no hint surface references the combo; a hint-free playtest cohort can still produce at least one spontaneous discovery report.*

#### 7 · The touch surface contract (the dp law)

- **TR-INP-059 — Two canvases, one truth.** The world renders at 480×270 integer-scaled; the touch/HUD layer lays out at **screen resolution in dp** with hit-rect floors: `hit = max(art_size, dp_floor / hud_scale)`. Target sizes in dp/mm, never art pixels. **Safe-area carve (review fix):** all interactive regions are clamped into **viewport ∩ safe area** (TR-INP-077) before any other rule applies. *Test: hit circles ≥ dp floors at every device scale; no hit rect crosses a system inset.*
- **TR-INP-060 — Touchdown binding.** Each touch binds to exactly one region at landing (movement zone / one button / one chip / one bubble / dead); no mid-touch rebind; release unbinds. Stick finger + chip/bubble finger work simultaneously. *Test: two-finger stick + attack tap.*
- **TR-INP-061 — Clock split.** The intent window ticks on the **game clock** (TR-INP-024); every other touch feel timer (fades, hold-guards, hysteresis) runs on **wall-clock** — UI-feel is not gameplay intent, and frame-rate independence is the glitch doctrine.
- **TR-INP-062 — Impulse vs state (touch-facing taxonomy).** Impulse verbs (Attack, Jump, Dash, Interact, Quick-use) are single signatures through the intent window; state verbs (Move, Crouch) are held orders with no buffer — honored while held, never queued.
- **TR-INP-063 — Letterbox bars are dead taps (two-surface rule, review fix).** The integer-scale viewport leaves bars on exactly one axis pair — **portrait: left/right bars; landscape: top/bottom bars — both bar surfaces are dead taps**, no interactive region may straddle or touch a bar edge, and on sub-base screens the crop edge plays the bar's role (TR-INP-077). Zones live on the art viewport only. Predictable over clever.
- **TR-INP-064 — No per-press popups (ratified, all rigs).** Touch acknowledgment = held-state visual + light haptic tick. The player sees and feels the signature; nothing announces it in words.
- **TR-INP-065 — Movement band policy (ratified: walk-only keyboard at MVP).** One axis, three orders: neutral < 0.25 · creep 0.5× ≥ 0.25 · walk ≥ 0.45, with hysteresis on every boundary. Analog rigs *measure* the bands; keyboard presses what it has (walk; creep unbound at MVP). *Rationale: SotN identity makes distances learnable in walk-lengths — rooms are designed in committed strides; continuous analog would mishear every re-summoned thumb ("she inched at 73% when I meant to stand").*
- **TR-INP-066 — Crouch cone.** Narrow entry (half-angle 25°, magnitude 0.65, **90 ms hold guard** — a brush is not an order) → wide exit (45°, 0.40) so crouch-walking works on diagonals without popping up. Deferred-during-commit, never discarded (still in-zone when the body frees → she crouches then). Jump stands her up. Toggle crouch mode is an a11y option (TR-INP-070); hold is the locked default.
- **TR-INP-067 — Floating Interact bubble (ratified).** Spawns adjacent to the interactable, offset toward screen interior (≥16 dp edges, ≥12 dp clear of cluster/pause; prefer-above fallback; leader line beyond 90 dp). Label: ≤6-char imperative, ≥14 dp text, icon + text, ≥4.5:1 contrast. Range hysteresis consumed from the world (input owns presentation only); fades 100/150 ms; nearest wins; **56 dp hit** — larger than the floor because a dynamically appearing control deserves slack. Disabled-vs-hidden rule: **proximity-gated → hidden; state-gated → dimmed with the reason in the label** ("SHIFTING — WAIT") — never a silent grey slot. **Movement-zone clearance (review fix):** the bubble **never spawns inside the movement zone** — if the interactable's adjacency lands in the zone, it spawns at the zone boundary + `BUBBLE_CLUSTER_CLEAR_DP` toward screen interior (AC-76). *World word list belongs to narrative + HUD GDDs; the mechanic is owned here.*
- **TR-INP-068 — Chip hold-to-commit — "spend weight" (ratified).** Touchdown → preview (ring, name, count, light haptic); release after ≥150 ms → commit (this moment is the `quick_item` press for window purposes); slide-off → cancel free; panic brush → distinct "not signed" haptic, no order. The governing principle for every future verb: **confirmation weight matches the verb's cost.** **A11y exception (review fix, Annex EX-2):** the `CHIP_TAP_COMMIT` toggle reduces the threshold to the fixed `CHIP_TAP_COMMIT_MS` = 50 — a deliberate tap commits; grazes under 50 ms still cancel; the preview remains the visible weight. Confirmation weight still matches cost *as bent by accessibility*. *Test: <150 ms touch-and-lift = no item consumed, always; with the toggle on, <50 ms never commits and 50.0 commits.*
- **TR-INP-069 — Cluster layout & mirror (rewritten — review fix, re-derived geometry).** Two-thumb default, **portrait-locked at MVP** (Annex EX-10; landscape = post-MVP re-audit). **Anchor law:** all cluster positions are (x, y) = (dp inward from the right safe edge, dp up from the bottom safe edge); `MIRROR` reflects x to the left safe edge and swaps the stick zone to the right 42%. **Hit geometry:** hit areas are circles, radius = hit_dp ÷ 2. **Gap law:** every pairwise center distance ≥ r₁ + r₂ + `CLUSTER_GAP_DP`, evaluated at hit-scale **1.5** (the strictest scale — 1.5-valid ⇒ 1.0-valid, since max 1.0 radius-sum + gap = 70 ≤ 84); at 1.5 every gameplay hit is floor-dominated (48 × 1.5 = 72). **Layout (corrected numbers):** Attack center (70, 60), visual 60 · Jump center (40, 142), visual 56 · Dash socket center (156, 44), visual **48** (was undefined — defined at the gameplay floor) · a11y Backdash button center (130, 138), visual 48, **present only when the a11y toggle is on** · pause: top-right safe corner, center (24, `H_safe` − 24), hit 48. Home ghost: stick-zone center-x, 30% of safe height above the bottom safe edge. Positions are **audit-gated** (AC-66): free-form tweaks are forbidden; any change re-runs the audit. **Reach claim (re-scoped — Annex EX-8):** the **reach disc** = circle centered at the cluster pivot (bottom-right safe corner), radius = `REACH_DISC_PCT` (30)% of the safe-area diagonal; claim: every cluster control's hit-rect **center** lies inside the disc at hit-scale 1.0 on every profile in the matrix (verified: smallest profile 360×640, insets 24/24 → disc r ≈ 208; Attack 91.8 · Jump 147.5 · Dash 162.1 · a11y Backdash 189.6 — all ✓). This is a **two-thumb contract with a one-thumb reach guarantee for the cluster**; "one-thumb comfortable" is hand-dependent and not claimed. *Failure evidence reproduced from the old layout: Jump↔Attack visual gap 4.2 dp (< 12); Dash↔Attack overlapped −5.7 dp; Jump at 128 dp violated the band claim — all corrected by the layout above (all six pairwise gaps ≥ 84 dp at 1.5).*
- **TR-INP-077 — Safe-area & two-surface letterbox contract (new — review fix).** All interactive regions live inside the **safe area**: screen rect minus system insets (status bar, gesture-nav bar, notches/cutouts), queried per device with build-time floors when unavailable (top 24 / bottom 24 / sides 0 + display-cutout). Insets convert to art px via `hud_scale` and clamp every registered region into viewport ∩ safe area. Portrait leaves left/right bars; landscape top/bottom — both surfaces dead per TR-INP-063. *Test: with a 48 dp gesture-nav inset forced on, every hit rect's bottom edge ≥ the inset; with the viewport letterboxed left/right, taps on both bars bind dead.*
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

The Input system is a foundation layer: its formulas are **conversion laws** (human ms → engine ticks), **band/threshold math** (analog noise → discrete orders), and **timing predicates** (when a promise is alive, honored, or silently dropped). Three laws govern every formula:

- **Named-symbol law.** Every literal (140, 280, 150, 90, 0.25, 0.45, …) appears here only as a named symbol; values live in exactly one place — the Tuning Knobs table. This section defines *structure*; that section defines *numbers*.
- **Never-stingy boundary law (ratified GDD-wide).** Every boundary comparison is **inclusive on entry, strict on exit**: an order engages at `≥`/`≤` the threshold; leaving requires strictly beyond the exit counterpart.
- **Clock law.** Gameplay timing (intent windows, backdash tap window) runs on the **game clock**; touch-feel timing (hold-guards, fades, chip hold measurement) runs on **wall-clock** (TR-INP-061, TR-INP-024). Where they meet (F-09 → F-05), the handoff is explicit.

Data chain: raw touch → **F-02** normalization → **F-03** bands / **F-04** crouch cone; F-03's edge stream → **F-07** backdash; presses → **F-05** windows, gated by **F-08**/**F-10**; **F-09** produces a press into F-05; **F-06** is the independent layout-conversion law feeding all touch geometry.

**Formula ledger — law vs knob.** No entry is a bare tuning constant; each defines structure, and each constant it consumes is flagged to Tuning Knobs.

| # | Formula | Class | Constants consumed (live in Tuning Knobs) |
|---|---|---|---|
| F-01 | ms_to_ticks | True law | — |
| F-02 | stick_vector_normalization | True law | `STICK_LEASH`, `STICK_DEADZONE` |
| F-03 | movement_band_selection | Threshold law | `BAND_CREEP_ENTER`, `BAND_WALK_ENTER`, `BAND_HYST`, `CREEP_RATIO` |
| F-04 | crouch_zone_test | Threshold law | `CROUCH_ENTRY_ANGLE/MAG`, `CROUCH_HOLD_GUARD_MS`, `CROUCH_EXIT_ANGLE/MAG` |
| F-05 | intent_window_evaluation | True law | `INTENT_WINDOW_MS`, per-verb overrides |
| F-06 | hit_rect_floor | True law | `DP_FLOOR_*`, `TOUCH_HIT_SCALE` |
| F-07 | backdash_pattern_recognition | Threshold law | `BACKDASH_TAP_WINDOW_MS` |
| F-08 | body_busy | True law (zero constants) | — |
| F-09 | chip_commit_rule | Threshold law | `CHIP_HOLD_COMMIT_MS` |
| F-10 | interact_target_binding | True law (zero constants) | — |

#### F-01 · ms_to_ticks — the window conversion law (TR-INP-024)

`window_ticks = ceil(window_ms × physics_tps ÷ 1000)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Design duration | `window_ms` | int | 1–5000 | Contract duration in ms — `INTENT_WINDOW_MS` or a per-verb override |
| Physics rate | `physics_tps` | int | 1–1000 (project pins 60) | Engine physics ticks per second |
| Window length | `window_ticks` | int | ≥ 1 (practical ≤ ~500) | Ticks the intent stays offerable |

**Output Range:** `window_ticks ≥ 1`; effective duration is **always ≥ window_ms** — the window never rounds stingy. Overshoot ≤ 1 tick (16.7 ms @ 60, 8.3 @ 120, 33.3 @ 30). Exact-integer products round with zero overshoot.

**Rate-scaling rule:** `window_ms` is the contract; ticks are derived. Higher physics rates shrink overshoot toward the exact value — fidelity improves, the promise never shrinks below it. On `physics_tps` change mid-session: recompute all `window_ticks` from ms and re-baseline pending ages through ms so no intent expires early or overstays from the rate event alone.

| physics_tps | ticks from 140 ms | effective window |
|---|---|---|
| 30 | 5 | 166.7 ms |
| 60 | **9** | 150.0 ms |
| 120 | 17 | 141.7 ms |
| 240 | 34 | 141.7 ms |

**Example:** 140 ms @ 60 tps → `ceil(8.4)` = **9 ticks** = 150 ms effective (the ratified value). At 120 tps: 17 ticks = 141.7 ms — same promise, finer granularity.

#### F-02 · stick_vector_normalization (TR-INP-014, TR-INP-009)

The stick_vector_normalization formula is defined as:
`stick_vector = (raw_offset ÷ |raw_offset|) × stick_magnitude`, where
`stick_magnitude = 0` if `|raw_offset| ≤ D_src`; otherwise `min(|raw_offset| ÷ L_src, 1)`; and `(0, 0)` when `|raw_offset| = 0`.

**Per-source parameters (review fix — the unit correction):**
- **Touch:** `raw_offset` in dp; `L_src = STICK_LEASH` (dp); `D_src = STICK_DEADZONE` (dp).
- **Gamepad stick:** `raw_offset` = the axis vector, already unit-normalized; `L_src = 1.0` (identity); `D_src = PAD_DEADZONE_RATIO` (**ratio, not dp** — applying a dp deadzone to a unit vector was the unit bug this fixes).
- **Keyboard/d-pad:** boolean sources deliver ±1.0 directly, bypassing F-02.

**InputMap deadzones are forced to 0 on every registered action** (TR-INP-014 amendment): F-02 is the **sole deadzone authority** — one implementation, one test seam, and injected `action_press(strength)` behaves identically to hardware.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Raw offset | `raw_offset` | Vector2 | unbounded | Touch: dp (dp-converted via F-06). Gamepad: axis units (unit-normalized) |
| Leash radius | `L_src` | float | > 0 | Touch: `STICK_LEASH` (dp). Gamepad: 1.0 (identity) |
| Noise floor | `D_src` | float | ≥ 0 | Touch: `STICK_DEADZONE` (dp). Gamepad: `PAD_DEADZONE_RATIO` (ratio) |
| Stick vector | `stick_vector` | Vector2 | [−1, 1]² | Normalized output; feeds F-03 (x) and F-04 (x, y) |

**Output Range:** magnitude exactly [0, 1]; pinned at exactly 1.0 at/over the leash (a flick saturates); exactly (0, 0) inside the deadzone. No smoothing, no curve — geometry, not feel; ramps are Movement's. The **pre-normalization raw trace** is the SYS-12 gesture channel; gestures read raw, orders read normalized.

**Example:** leash 56 dp; finger drags 72 dp right → pinned **1.0**, full walk. Finger at 19 dp → 0.34 → creep band (F-03). Finger at 3 dp (deadzone 4 dp) → **0** → neutral.

#### F-03 · movement_band_selection — one axis, three orders (TR-INP-065)

`move_order = sign(x) × band_multiplier(band)`, with **two independent hysteretic comparators** on `|x|`:

```
creep_on: OFF→ON when |x| ≥ BAND_CREEP_ENTER (0.25)   ON→OFF when |x| < BAND_CREEP_ENTER − BAND_HYST (0.20)
walk_on:  OFF→ON when |x| ≥ BAND_WALK_ENTER  (0.45)   ON→OFF when |x| < BAND_WALK_ENTER  − BAND_HYST (0.40)
band      = WALK if walk_on · CREEP if creep_on · NEUTRAL otherwise
multiplier= 0 · CREEP_RATIO (0.5) × walk · 1.0
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Axis sample | `x` | float | [−1, 1] | `stick_vector.x` (touch/gamepad); keyboard & d-pad report ±1.0 directly |
| Comparator states | `creep_on`, `walk_on` | bool | {true, false} | Persistent — the hysteresis memory |
| Band | `band` | enum | {NEUTRAL, CREEP, WALK} | Selected order |
| Published order | `move_order` | float | {−1.0, −0.5, 0, 0.5, 1.0} | Sign × multiplier; Movement maps to speed with its own ramps |

**Output Range:** five discrete values. Nesting invariant: `walk_on ⇒ creep_on` (ordered thresholds and ordered exits) — assert in tests. Sticky no-chatter zones: [0.20, 0.25) and [0.40, 0.45). Sign is read fresh every sample; magnitude band is sticky. Keyboard at MVP presses ±1.0 → always WALK or NEUTRAL (walk-only MVP, ratified).

**Delivery recommendation (→ ADR):** SYS-01 publishes **(raw_axis, move_order)** — raw for the audit/trace channel, order as the contract; band *selection* is SYS-01's (TR-INP-065), speed execution is SYS-06's.

**Example:** settle at x = 0.30 → creep engages → 0.5× walk. Drift to 0.22 → still CREEP (exit needs < 0.20). To 0.19 → NEUTRAL. Push 0.47 → WALK. Slide 0.42 → still WALK. 0.39 → CREEP. No sequence oscillates bands while the thumb holds position.

#### F-04 · crouch_zone_test — the down-zone cone (TR-INP-066, TR-INP-061, TR-INP-029)

`in_entry = (angle_from_down ≤ CROUCH_ENTRY_ANGLE) ∧ (magnitude ≥ CROUCH_ENTRY_MAG)`
`in_exit  = (angle_from_down ≤ CROUCH_EXIT_ANGLE)  ∧ (magnitude ≥ CROUCH_EXIT_MAG)`
`angle_from_down = atan2(|stick_vector.x|, stick_vector.y)` degrees, screen-space y-down (0° = straight down).

State machine (analog sources; keyboard/d-pad-down deliver a boolean directly, bypassing cone and guard):

```
STANDING → CROUCHING:  in_entry sustained ≥ CROUCH_HOLD_GUARD_MS (wall-clock accumulator)
CROUCHING → STANDING:  ¬in_exit   (unguarded — ratified: the asymmetry IS the design)
accumulator: += Δwall while in_entry ∧ context = Gameplay; resets on any out-of-entry sample
             or at gate entry (TR-INP-047)
```

**Deferred-during-commit rule:** zone evaluation never pauses, but **application** waits: a state flip executes only on a tick where `body_available` (F-08); at that tick the **current** vector is evaluated against the **current** state's thresholds. Still in-zone when the body frees → she crouches then; left the zone first → nothing. The guard already elapsed during the commit — not re-charged.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Stick vector | `stick_vector` | Vector2 | [−1, 1]² | From F-02, unsmoothed |
| Angle from down | `angle_from_down` | float | 0°–180° | Symmetric down-cone (both diagonals count) |
| Magnitude | `magnitude` | float | 0–1 | From F-02 |
| Guard accumulator | `guard_ms` | float | 0–∞ | Sustained-in-entry time; resets on any out-of-entry sample |
| Crouch state | `crouch_engaged` | bool | {true, false} | Published **state** channel — never buffered |

**Output Range:** boolean state + internal accumulator. Stick released → stands; brush < 90 ms never engages (inclusive at exactly 90.0); the 25°→45° / 0.65→0.40 dual thresholds **are** the hysteresis — crouch-walking on diagonals never pops her up.

**Example:** vector (0.30, 0.95) → 17.5°, 0.996 → in entry; held 90 ms → crouch. Drift to (0.52, 0.85): 31.4° → outside entry (31.4 > 25) but inside exit (31.4 ≤ 45) → **stays crouched** — diagonal crouch-walk. Drift to (0.80, 0.60): 53.1° > 45 → stands.

#### F-05 · intent_window_evaluation — the breath (TR-INP-018…024, TR-INP-028)

`intent_pending = (current_game_tick − press_tick ≤ window_ticks) ∧ ¬consumed ∧ (context = GAMEPLAY)`
with `window_ticks = ms_to_ticks(override_map.get(verb, INTENT_WINDOW_MS))` (F-01) and the supersede rule:
`on new press of same verb while pending: press_tick ← current_game_tick; snapshot ← new; consumed stays false` (age restarts — Latest Order Honored).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Game clock now | `current_game_tick` | int | 0–∞ | Physics tick counter; freezes under hit-stop, stops in non-Gameplay contexts |
| Press stamp | `press_tick` | int | 0–∞ | Game tick at capture; press-frame body snapshot attaches (TR-INP-019) |
| Window | `window_ticks` | int | ≥ 1 | From F-01; per-verb override map |
| Consumed flag | `consumed` | bool | {true, false} | Set by puller ack (TR-INP-020); permanent for the slot |
| Pending | `intent_pending` | bool | {true, false} | Offered to the single puller every tick while true |

**Output Range:** boolean per verb slot (exactly one slot per verb). Boundary: `age = window_ticks` is **still pending** (honored on its last eligible tick — never-stingy); `age = window_ticks + 1` → silent expiry (TR-INP-023). Offer begins on the press frame itself — same-frame resolution possible. One-consumption per TR-INP-021.

**Supersede rule (corrected):** on new press of same verb while pending: `press_tick ← current_game_tick`; snapshot ← new; consumed stays false (age restarts — Latest Order Honored). Corollaries: **G1 count / G2 freshness / G3 keep-alive** — see TR-INP-022; a gap > window between taps leaves the slot momentarily empty (**pending-gap property** — the retracted stall-parity claim's root cause).

**Interact override (review fix — derived, not tuned):** the override map carries an `INTERACT_WINDOW_MS` entry **derived at boot** from registered publishers' declared worst-case arcs + `INTERACT_MARGIN_MS` (TR-INP-029); SYS-08 and SYS-06 jointly own the declarations. The ratified promise is now structural (U-4 closes).

**Example (the Early Press):** Attack pressed at tick 2000 during a windup → pending ticks 2000–2009. A second tap at 2004 supersedes → pending to 2013, still one slot. Combat pulls at tick 2010 (strike-contact): age 6 ≤ 9 → **honored**; ack → consumed. No pull by 2013 → tick 2014 drops it silently.

#### F-06 · hit_rect_floor — the dp law's arithmetic (TR-INP-059, TR-INP-070, TR-INP-063)

`hit_art_px = max(visual_art_px, (dp_floor × touch_hit_scale) ÷ hud_scale)`
where `integer_scale k = max(1, min(floor(screen_w ÷ 480), floor(screen_h ÷ 270)))` and `hud_scale = k ÷ screen_density` (dp per art pixel).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Art scale | `k` | int | ≥ 1 | Integer letterboxed scale: art viewport = 480k × 270k physical px, centered; letterbox bars are dead taps |
| Screen density | `screen_density` | float | ≥ 0.1 | OS density (physical px per dp) |
| HUD scale | `hud_scale` | float | ~0.25–8 | The single dp↔art bridge; consumed at region registration AND F-02's leash conversion. **Input computes it; SYS-24 consumes it** (registry candidate) |
| Visual size | `visual_art_px` | float | > 0 | Drawn extent in art px |
| Accessibility floor | `dp_floor` | float | 44–72 | 48 gameplay / 44 absolute / 56 bubble |
| Hit-only scale | `touch_hit_scale` | float | {1.0, 1.25, 1.5} | Player a11y setting |
| Hit rect | `hit_art_px` | float | ≥ floor-equivalent | Region rect for touchdown binding |

**Output Range:** `hit_art_px ≥ (dp_floor × touch_hit_scale) ÷ hud_scale` always. Identity: `hit_art_px × hud_scale = max(visual_dp, dp_floor × touch_hit_scale)` — **the floor is guaranteed in dp at every device scale**. A hit rect larger than visual is legal and intended; smaller is a bug.

**Example:** phone 2400×1080, density 2.75 → `k = min(5, 4) = 4`; `hud_scale = 1.4545`. Attack drawn 60 dp = 41.25 art px; floor 48 ÷ 1.4545 = 33.0 → `hit = max(41.25, 33.0)` = 41.25 art px = 60 dp ✓. Small phone 1560×720, density 2.0 → k = 2, `hud_scale = 1.0`; jump visual 56 dp → 56 art px ≥ floor 48 ✓. Touch coordinates map screen→art by `(screen_px − viewport_origin) ÷ k` (integer, exact).

#### F-07 · backdash_pattern_recognition (TR-INP-056) — clock: game clock (ratified)

`backdash_fires = (press2_tick − press1_tick ≤ tap_window_ticks) ∧ release1_observed_strictly_between ∧ body_available(completion_tick)`
evaluated at the press2 edge; `tap_window_ticks = ms_to_ticks(BACKDASH_TAP_WINDOW_MS)` (F-01).

**Edge definitions (rig-blind — every rig compiles to the same edge stream; review fix):**
- **Back edge (arming)** = entering the **arming zone** with sign opposite to `facing` — by default the WALK band (F-03; one definition of "back is pressed"; keyboard/d-pad binding press = edge directly). **If the evidence-gated `BACKDASH_ARM_MAG` fallback is promoted (AC-64), the arming zone decouples from the walk band** (pairwise-validated, V12).
- **Release edge** = magnitude strictly **below the arming threshold** (with the default arming zone this is exactly the walk-band exit, < 0.40).
- **Reset condition (new):** a forward-sign WALK-band entry between press1 and press2, or a `facing` flip, **resets the machine to IDLE** — a direction change is a different gesture; creep-magnitude wobble between edges is ignored (below the arming threshold = no committed direction).

Machine: `IDLE → BACK1 (back edge) → RELEASED (release edge) → fire-or-drop at back edge → IDLE`. Release must be **strictly** between the presses (same-tick release+press fails the ordering and restarts). Held back produces one edge, then nothing — *held back = walk, never backdash*.

**Body-free completion:** fire only if `body_available` at the completion tick — else **dropped, not deferred** (ratified). The published intent is a **single-tick offer**: SYS-06 pulls the same tick (hop starts on the completion frame) or it vanishes — no window slot, reflex-class.

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| First back press | `press1_tick` | int | game tick | Arms the detector |
| Release | `release1` | bool | {observed, not} | Must occur strictly between presses |
| Second back press | `press2_tick` | int | game tick | Completion edge — the pattern dies or fires here |
| Tap window | `tap_window_ticks` | int | ≥ 1 | From F-01 (280 ms default) |
| Facing | `facing` | enum | {left, right} | **Published by SYS-06** (new contract item, ratified — registry candidate) |
| Fire | `backdash_fires` | bool | pulse | Single-tick publish; consumed or vanished |

**Output Range:** boolean pulse (at most one per completion) + internal 3-state machine. `press2 − press1 = tap_window_ticks` exactly → honored (inclusive). A late press2 **re-arms as a new press1** — attempts chain naturally. Post-fire → IDLE; re-edges during the hop hit the body-free rule → dropped; no input-side cooldown. Detector state clears at gate entry.

**Example:** @ 60 tps (window 17 ticks = 283.3 ms). Facing right. press1 @ 5000, release @ 5010, press2 @ 5050 → 50 ticks apart → invalid; re-arms (BACK1 @ 5050). Release @ 5062, press2 @ 5064 → 14 ticks = 233 ms ✓, release strictly between ✓, body free → **fires at 5064**; SYS-06 pulls same tick. Had the body been mid-attack: nothing, silently.

#### F-08 · body_busy — the availability composition (TR-INP-029)

`body_busy(t) = (∨ movement_locks)(t) ∨ (∨ combat_commitments)(t)`; `body_available(t) = ¬body_busy(t)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Movement locks | `movement_locks` | set[bool] | any | SYS-06's published locomotion locks (committed movement, hop, knockdown, …) |
| Combat commitments | `combat_commitments` | set[bool] | any | SYS-08's published commitments (startup/active/recovery, clash lock, …) |
| Availability | `body_available` | bool | {true, false} | Input-owned OR; consumed by F-04 (defer), F-07 (completion), F-10, item resolution |

**Output Range:** boolean. Evaluated **fresh every game tick** — a state, never buffered; press-frame snapshot records it at capture while consumption-frame state governs derived moves (input delivers both, never arbitrates). **Fails open (ratified):** empty/missing publication = available (OR of nothing = false), with a loud dev-mode assertion when a registered publisher goes silent — fail-closed would silently kill verbs during development.

**Example:** tick 4000: locks = {}, commitments = {attack} → busy → a pending interact keeps waiting. Tick 4018: recovery ends → available → interact resolves **this** tick — provided the interact window override still holds (see F-05's ratified note; the exact override value comes from Combat's arc budget).

#### F-09 · chip_commit_rule — spend weight (TR-INP-068, TR-INP-061)

`chip_committed = release_observed ∧ ¬slid_off ∧ (release_wall_ms − touchdown_wall_ms ≥ CHIP_HOLD_COMMIT_MS)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Touchdown time | `touchdown_wall_ms` | int | monotonic wall ms | Chip region touchdown |
| Release time | `release_wall_ms` | int | > touchdown | Finger lift inside chip bounds |
| Commit threshold | `chip_hold_commit_ms` | int | ≥ 1 | 150 — knob |
| Slide-off flag | `slid_off` | bool | {true, false} | Finger exited chip bounds while held → set **at the exit frame** (cancel fires then, free — ratified: slide-off dominates hold duration) |
| Commit | `chip_committed` | bool | pulse | On true: a `quick_item` press is stamped into the F-05 window at the commit tick (game clock) |

**Output Range:** boolean pulse. Boundary: exactly 150.0 ms → commit (inclusive); 149.9 → no order. Keyboard `Q` / gamepad `LB` skip this formula entirely — their press **is** the `quick_item` press at press-tick (the hold is the touch rig's confirmation weight, TR-INP-008 fixed semantics).

**Handoff semantics (where the clocks meet):** the hold is *measured* on wall-clock (touch-feel); the resulting press enters the F-05 window **stamped at the commit tick on the game clock**. The window does not retroactively start at touchdown. An app blur mid-hold cancels silently — no commit on return.

**Example:** touchdown wall 5023 ms, release wall 5180 → 157 ≥ 150 → commit at game tick 9000: `quick_item` pending ticks 9000–9008. Touch-and-lift in 80 ms → no order, preview fades, item unconsumed — always.

#### F-10 · interact_target_binding (TR-INP-030, TR-INP-067)

The interact_target_binding formula is defined as:
`interact_resolvable = intent_pending(interact) ∧ prompt_lit ∧ (lit_prompt_id = bound_prompt_id) ∧ ¬signed(bound_prompt_id)`

**The signed latch (review fix):** a prompt that has consumed a press latches **signed** while it stays lit; further presses on the same lit prompt are unresolvable at entry — one lit bubble, one signature per lighting. The latch clears on unlight or context change (gate entry).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Pending intent | `intent_pending` | bool | — | From F-05 (interact slot) |
| Prompt lit | `prompt_lit` | bool | {true, false} | Exactly one prompt at a time (nearest wins) |
| Bound prompt | `bound_prompt_id` | id | registry ids | The prompt lit **at press time** — the press binds to it |
| Lit prompt | `lit_prompt_id` | id | registry ids | The prompt lit now |

**Output Range:** boolean. The intent is valid **only for the bubble it was pressed on**. Any term failing → the intent clears **immediately** (not at window end): prompt unlights mid-window (walked away) → expired at once; a later-lit bubble never consumes a stale press. Rig-agnostic: keyboard `E` in an empty corridor expires on the press frame.

**Example:** `E` at tick 300 with the CACHE bubble lit (bound = cache_A), window 9. Player steps back; prompt unlights at tick 305 → cleared immediately. At tick 320 a nearer door lights: nothing pending → no fire, no accidental save.

### Cross-cutting edge behavior

**Never-ticking game clock (frozen under hit-stop):** F-05 age freezes → the breath extends 1:1 (ratified); non-Gameplay contexts clear intents at gate entry, so a paused freeze never meets a pending intent. F-07: the tap window cannot close during a freeze; a pattern completing mid-freeze hits the body-free check — during clash-freeze the body is committed → dropped, well-defined either way. F-04/F-09: wall-clock guards keep running through hit-stop (UI-feel doctrine), but their *application* stays gated (crouch defers via F-08; chip commits only in Gameplay; blur mid-hold cancels silently).

**Degenerate inputs:** `physics_tps ≤ 0` → conversion asserts (engine guarantees ≥ 1). Screens smaller than 480×270 → `k` clamps to 1 with the art viewport cropped (full ruling in Edge Cases). Density/orientation change → recompute `k`/`hud_scale`; touch regions re-register (SYS-24 contract).

### GUT testability map

Every formula is a pure function or pure state machine over injected inputs — no `Input` singleton, no scene tree, no rendering in the testable core. Tick-driven seams run the rate matrix (30/60/120) in CI.

| Formula | Purity | Injected clock | Signature test |
|---|---|---|---|
| F-01 | pure fn | none | boundary table: 140@60→9; exact-integer case; rate matrix |
| F-02 | pure fn | none | pin-at-leash, deadzone→0, sign preservation (property fuzz) |
| F-03 | pure reducer | none | no-chatter fuzz in both sticky zones; nesting invariant |
| F-04 | reducer + guard | wall-clock ms | 89 vs 90 ms brush; 25→45° diagonal no-pop; defer recheck |
| F-05 | service | game tick source | age = window honored, +1 silent-expired; supersede restarts; freeze holds; same-frame offer |
| F-06 | pure fn ×2 | none | device-profile table (2400×1080@2.75, 1560×720@2.0, 4K desktop) |
| F-07 | detector | game tick source | 280 boundary inclusive; missing release → walk; busy-at-completion → drop; late-press2 re-arms |
| F-08 | pure OR | none (publishers mocked) | publisher raises/clears mid-window; fail-open + assertion |
| F-09 | predicate | wall-clock ms | 149.9 vs 150.0 boundary; slide-off dominance |
| F-10 | predicate | none (prompt stub) | mid-window unlight kills; relit bubble ≠ stale press |

## Edge Cases

**Amendments ratified during edge-case derivation** (they amend Detailed Design): **TR-INP-071 Cross-rig state arbitration (rewritten — review fix: edge-driven).** Events deliver honestly from any rig into the same slots. Each state channel (`move_x`, crouch) has exactly one owning rig. **Transfer happens on positive edges only** — a rig takes a channel on its activating edge (touchdown in the zone / key-down / stick crossing into a non-neutral band); continuous position alone never transfers ownership. **Re-assertion cadence:** the owning rig re-asserts the channel every dispatcher tick; **two consecutive ticks without the owner's assertion = the state releases to neutral and ownership clears** (device removal, focus loss). A released channel is taken only by a later edge — never by silence. **TR-INP-072 Movement-zone single-owner** — the first touchdown owns the stick until release; a second finger in the zone is inert. **TR-INP-073 Touch-cancel semantics** — an OS-cancelled touch (system gesture, app switch) is never a signed order: a chip hold mid-cancel cannot commit, the stick releases, the crouch guard resets. **Fallback (rider):** if a device profile under-delivers OS cancels, that profile disposes all touch-originated held states on every visibility change + a telemetry counter for suspected phantoms; per-platform cancel delivery is verified in device QA (OQ#15). **TR-INP-074 Knob validation (rewritten — review fix: pairwise law).** Every knob value AND every knob pair is validated at config load, before any region or service registers. **Dev builds: violation = boot failure naming both knobs and the invariant. Production: the listed resolution applies + rate-limited telemetry naming the clamp** (a shipping build must never crash from config; a broken pair must never drift silently). The exhaustive pair table (V1–V12) lives in the Tuning Knobs preamble. `[TR-INP-*]` = owning rule(s); `F-xx` = the formula doing the work.

### Value & config extremes

- **If `physics_tps` changes mid-session**: all windows recompute from their ms contracts and pending ages re-baseline through ms — no intent expires early or overstays from the rate event alone. Full rate-scaling rule is F-01's. [TR-INP-024 · F-01]
- **If any timing/geometry knob is set out of range** (window override ≤ 0, `STICK_LEASH` ≤ 0, `STICK_DEADZONE ≥ STICK_LEASH`): clamped at registration — overrides floor at 1 ms (⇒ 1 tick, never-stingy), leash floors at 1 dp, deadzone clamps to ≤ 10% of leash. [TR-INP-018, TR-INP-014, TR-INP-009 · F-01, F-02 · TR-INP-074]
- **If the screen is smaller than 480×270 physical**: `k` clamps to 1 and the art viewport is center-cropped — the crop edge behaves as the viewport boundary; taps beyond it are dead; hit rects clip to the visible region. [TR-INP-059, TR-INP-063 · F-06]
- **If SYS-06 has not published `facing`**: the backdash detector disables itself (it cannot classify "back") + dev-mode assertion. Deliberate asymmetry with body_busy's fail-open: a misfired dodge is worse than a missing one — the gesture fails closed while availability fails open. [TR-INP-056 · F-07, F-08]

### Simultaneous rules

- **If two prompts light on the same frame**: the publisher's nearest-wins resolves before any press binds — input never observes two lit prompts, because the Prompt Slot publishes at most ONE. A tie is the publisher's deterministic order. [TR-INP-067, TR-INP-026]
- **If an Interact press lands the same tick its bubble-confirm opens a gate**: the press resolves the prompt and the context transitions on that tick; every OTHER pending intent clears at gate entry; atomic transitions guarantee no third verb resolves on the transition frame. [TR-INP-047, TR-INP-030]
- **If a press is captured on the exact frame a gate opens**: dropped with the buffers — age is irrelevant at entry. [TR-INP-047]
- **If hit-stop freezes while a backdash pattern is mid-recognition**: the game clock stops, the tap window cannot close; a completion during the freeze hits the body-free check — busy during a clash-freeze → dropped. No wall-clock leak can fire a dodge into frozen frames. [TR-INP-024, TR-INP-056 · F-07]
- **If a wall-clock feel timer crosses its threshold during hit-stop** (crouch guard's 90 ms, chip hold's 150 ms): the timer keeps counting (UI-feel doctrine) while application stays gated — crouch defers via body-available and applies on the first free tick still in-zone; a chip crossing 150 ms during a Gameplay-context hit-stop commits, and its window age stays frozen until the clock resumes. [TR-INP-061, TR-INP-066, TR-INP-068 · F-04, F-09, F-05]
- **If supersede, puller-ack, and expiry all land on one tick**: intra-tick order is captures/supersedes → offers → acks → expiry — the puller deciding at tick T honors the order signed at tick T (Latest Order Honored extends *within* the tick). Rides the ADR's same-tick capture/consume verification item. **CONTINGENT on the ADR pipeline order (review fix):** this ordering is achievable only if the ADR's per-tick node pipeline processes captures before offers before acks before expiry; if the ADR lands a different achievable order, this entry and AC-18/AC-20 re-baseline to it — the ordering is a contract item *pending* the ADR (OQ#1), not an independent truth. [TR-INP-022, TR-INP-021 · F-05]
- **If an interact press and its prompt's unlight land on the same tick**: the press binds to the lit-at-capture snapshot; F-10 re-evaluates against the next state publication → unlit → cleared immediately. A press on the exact tick the bubble dies does nothing. [TR-INP-030 · F-10]
- **If a gate entry lands mid-chip-hold or mid-crouch-guard** (pause, blur, Reading, Cache-terminal): the in-flight hold and accumulator are cancelled silently — no commit on return, no "not signed" haptic: a context change is not a player error. Held *states* persist; in-flight *measurements* do not. [TR-INP-047, TR-INP-068 · F-04, F-09]
- **If a gate opens mid-attack-commitment**: input's part is done — the intent was pulled and Combat owns the arc; input clears buffers and persists states; no half-signed order survives the transition. [TR-INP-047, TR-INP-029]

### Device & rig anomalies

- **If a gamepad disconnects mid-hold or mid-window**: held states sourced from that device release as if the player lifted (honest body truth); already-captured pending intents survive untouched (rig-agnostic once stamped); no error state. [TR-INP-006, TR-INP-013]
- **If touch and keyboard are used simultaneously**: events deliver honestly from either rig into the same slots; each *state* channel is owned by the most recently active rig — a stick touch after a key press owns `move_x` until the keyboard presses again. [TR-INP-006, TR-INP-016 · F-03 · TR-INP-071]
- **If the device rotates or the density rescales mid-chip-hold**: no mid-touch rebind — the hold keeps its binding, slide-off is set only by *finger* movement crossing bounds, never by the region moving under a stationary finger; release duration alone decides commit. The world moved, not the order. [TR-INP-060, TR-INP-068 · F-09, F-06]
- **If a palm or edge touch lands outside every zone or on the letterbox/crop**: binds "dead", release unbinds — no capture, no error, no haptic. [TR-INP-063, TR-INP-060]
- **If a second finger enters the movement zone while the stick is owned**: inert — the zone is single-owner. [TR-INP-060, TR-INP-016 · TR-INP-072]
- **If the stick finger lifts and a different finger lands a moment later**: a full release-then-touchdown handoff — at least one honest neutral frame between (the anchor re-homes at touchdown); never a blended continuation masquerading as one hold. [TR-INP-060, TR-INP-013 · F-02]
- **If the OS cancels a touch mid-hold** (system gesture, app switch, notification shade): cancel ≠ release — a chip hold cancels silently (never commits), the stick state releases, the crouch guard resets. A cancelled touch is never a signed order. [TR-INP-060, TR-INP-068 · TR-INP-073]

### Pattern & buffer edges

- **If backdash press2 keeps landing beyond the window** (mash-back slower than 280 ms): every late press2 re-arms as a fresh press1 — attempts chain indefinitely by design, but a fire still needs release-strictly-between + in-window + body-free; hops only when the body frees, at whatever rate Movement's hop lock allows. The input layer adds no cooldown — grace is not the post office's. [TR-INP-056 · F-07, F-08]
- **If a deferred crouch's first body-free tick falls in the gap between two commitments**: the flip applies on that free tick if in-entry is still true (the guard already elapsed during the first commitment — never re-charged); thumb left the zone meanwhile → no crouch. The zone test *at the flip tick* is the only truth. [TR-INP-066 · F-04, F-08]
- **If toggle-crouch is latched and Jump is pressed**: the latch clears — Jump stands her up in both modes, one rule with no mode exceptions; re-crouch is one deliberate press. [TR-INP-066, TR-INP-070]

### Degenerate strategies — named and shut down

- **If the player mashes Attack** (12 taps/s vs 4 taps/s): structurally shut on **resolution count** — one slot per verb, supersede restarts the age, never adds resolutions; the keep-alive corollary (G3) is owned in TR-INP-022: a sustained mash keeps one order pending through an arc; **stall parity across tap rates is explicitly not guaranteed (retracted — Annex EX-6)**. Mashing buys the newest order, nothing more. [TR-INP-022, TR-INP-021 · F-05]
- **If the player presses Interact while walking toward a not-yet-lit cache** (pre-range buffering attempt): shut — a press with no lit bubble dies on the press frame (TR-INP-030), a stale press dies the moment its bubble unlights (F-10), a later-lit bubble never consumes it. Walking by a cache cannot open it. [TR-INP-030 · F-10]
- **If the player chains backdash into backdash hunting an i-frame loop**: input's exposure is minimal by construction — single-tick publish, drop-when-busy, no input-side cooldown — at most one dodge per body-free completion; invincibility overlap math (i-frame duration vs hop recovery) is Combat/Movement tuning, not input's to enable or prevent. [TR-INP-056, TR-INP-014 · F-07, F-08]
- **If a quarter-spin lands the same frame as a plain attack press (VS)**: the composite consumes the press — ratified precedence. Guarding knob: `STINGER_TOUCH_TOLERANCE_MS` — generous enough to stumble into, narrow enough that ordinary attacks aren't eaten. [TR-INP-033, TR-INP-031]

### Accessibility space

- **If TOUCH_HIT_SCALE = 1.5 makes hit rects overlap neighboring regions**: touchdown still binds to exactly one region — overlap is resolved by registration z-order, which SYS-24 owns (input consumes the winner). At 1.5 the overlap must be resolved, not prevented — the floors are promises. **SYS-24 contract note: registration z-order is load-bearing.** [TR-INP-070, TR-INP-060 · F-06]
- **If attack hold-repeat is toggled ON**: repeat presses are ordinary edge-triggered presses — supersede applies, one slot caps the stall, clash timing unaffected (the slot always holds the newest order). OS key repeat stays filtered separately (TR-INP-015) — the toggle is input-generated repeat, a different mechanism. New designer-only knob: repeat rate, when the toggle ships. [TR-INP-070, TR-INP-015, TR-INP-022]
- **If toggle-crouch is latched during stair or slope traversal**: the crouch channel stays latched and raw — whether crouch-walking traverses stairs is Movement's call; input delivers state truth unchanged and takes no side. [TR-INP-066, TR-INP-013, TR-INP-014]
- **If haptics are set to global strength 0**: every haptic meaning goes silent legally — acknowledgment falls entirely to the held-state visual, which the text+shape-never-color law keeps sufficient; no input timeout exists to compensate, because none exist anywhere. [TR-INP-064, TR-INP-070]

## Dependencies

**Upstream: none as a data dependency (SYS-01 is the root of the design order) — with one coordination authority.**

| Direction | System | Hard/Soft | Interface (data in → out) | Status |
|---|---|---|---|---|
| Authority | **SYS-05 Game Flow** | Hard at runtime (soft while its GDD is a linear stub) | In: context transitions (gameplay/paused/reading/terminal/cutscene), quit semantics · Out: `pause` events, ContextGate enforcement, app-blur forced pause | PROVISIONAL — SYS-05 owns contexts; input owns gate enforcement (TR-INP-045/047) |
| Downstream | **SYS-06 Movement** | **Hard** — cannot function without verbs | Out: `move_x` (raw axis + order), `crouch` state + edges, `jump` event + held, `dash` event, `backdash` intent · In: `grounded`, locomotion-locks, `facing`, consumption acks — **each publisher declares `worst_case_arc_ms` at registration** (TR-INP-029 derivation) | PROVISIONAL — all feel curves, coyote, committed lock, traversal gates theirs |
| Downstream | **SYS-08 Combat** | **Hard** | Out: `attack` presses + press-frame snapshots, window-override hook, body-state queries · In: commitments (body-busy), pull discipline, second-hit lockout — **declares `worst_case_arc_ms` at registration** (TR-INP-029 derivation) | PROVISIONAL — derived-move rule is Combat's over input's delivery |
| Downstream | **SYS-24 HUD** | **Hard on touch** (desktop builds: soft) | Out: touch dispatcher (single capture point), binding-display data, rig states (bubble, dormant socket) · In: touch-region registrations, prompt visuals | PROVISIONAL — HUD never consumes gameplay touches directly; registration z-order load-bearing at hit-scale 1.5 |
| Downstream | **SYS-12 Stinger** | Soft (VS) | Out: raw stick trace, directional press stream, composite hook · In: composite `stinger` intents | Reserved-VS — zero MVP footprint beyond the backdash detector |
| Downstream | **SYS-29 Juice** | Soft | Out: game-clock honoring (hit-stop), press/depress event hooks for haptics · In: hit-stop requests | PROVISIONAL |
| Downstream | **SYS-15 Cache Stations** | Soft (flagship publisher) | Prompt Slot: publishers publish ONE prompt (label, range, predicates); input lights the bubble, routes presses back | PROVISIONAL — the slot generalizes to SYS-02 doors, SYS-20 memories, SYS-28 logs, SYS-11 seams |
| Downstream | **SYS-02 Room Structure** | Soft (via Prompt Slot only) | Publishes interactable positions + prompt predicates consumed by the Prompt Slot; input never reads room geometry directly | PROVISIONAL — SYS-02 GDD pending (review fix: was implied-only) |
| Downstream | **SYS-17 Inventory** | Soft (VS) | `quick_item` pulls from the intent window; HUD chip is the touch surface | Reserved slot |

**Explicit non-dependencies:** SYS-03 Save (bindings persist device-local to `user://controls.cfg`, versioned — a save may never carry a controls field; the only cross-system travel is the save itself, never the hands) · SYS-09/10 (dual-reality rendering/mutation — no direct input dependency; the world's truth never changes what a press means).

**Bidirectional-consistency corrections applied to the systems index at completion:** (1) SYS-24's dependency row gains SYS-01 (touch dispatcher); (2) SYS-01's row gains SYS-05 as coordination authority; (3) SYS-06's row already carries the traversal ladder + backdash (2026-11-11).

## Tuning Knobs

**Knob validation law (TR-INP-074, review fix) — pairwise invariants, validated at config load. Dev: violation = boot failure naming both knobs. Production: the listed resolution applies + rate-limited telemetry. Adding a knob without its pair rows is a review blocker.** `DEADZONE_EQUIV = STICK_DEADZONE ÷ STICK_LEASH` (smallest non-zero magnitude a touch can produce).

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V1 | `CROUCH_EXIT_ANGLE > CROUCH_ENTRY_ANGLE` (spread ≥ 10°) | raise EXIT to ENTRY + 10° | the wide exit IS the crouch hysteresis |
| V2 | `CROUCH_EXIT_ANGLE ≤ 90` | clamp to 90 | cone must not reach past horizontal |
| V3 | `CROUCH_ENTRY_MAG > CROUCH_EXIT_MAG` (spread ≥ 0.10) | lower EXIT to ENTRY − 0.10 | wide-exit promise |
| V4 | `CROUCH_EXIT_MAG > DEADZONE_EQUIV + 0.05` | raise EXIT to that floor | crouch zone must clear noise |
| V5 | `CROUCH_ENTRY_MAG ≤ 1.0` | clamp | — |
| V6 | `BAND_CREEP_ENTER < BAND_WALK_ENTER` (spacing ≥ 0.10) | raise WALK to CREEP + 0.10 | walk must sit clearly beyond creep |
| V7 | `BAND_HYST ≤ BAND_WALK_ENTER − BAND_CREEP_ENTER` | clamp HYST down to the gap | sticky zones must not overlap (implies the F-03 nesting invariant — asserted, not clamped) |
| V8 | `BAND_CREEP_ENTER − BAND_HYST > DEADZONE_EQUIV + 0.02` | shrink HYST | neutral exit must clear noise |
| V9 | `BAND_HYST > 0` | floor 0.02 | zero hysteresis = chatter |
| V10 | `STICK_DEADZONE ≤ 0.1 × STICK_LEASH` | clamp deadzone | leash-degeneracy guard |
| V11 | every timing override `1 ≤ ms ≤ 5000` | clamp to range | F-01 domain |
| V12 | `BACKDASH_ARM_MAG < BAND_WALK_ENTER` (if the fallback knob is promoted) | lower ARM to WALK − 0.05 | gesture must arm below the walk band |

**Not knobs** (documented so nobody adds them later): `physics_tps` (engine setting, pinned 60; rate changes handled by F-01's rule), `k`/`hud_scale` (device-derived each session, F-06), `facing`/`body_busy` (published states, not values), all binding *assignments* (Recalibration scope per TR-INP-034/035, not numbers). Every literal in Detailed Design and Formulas resolves to exactly one row below.

| Knob | Default | Safe range | Extreme behavior (too low / too high) | Interactions | Rule |
|---|---|---|---|---|---|
| `INTENT_WINDOW_MS` | 140 | 80–300 | <100: early presses expire before any pullable frame — the Early Press breaks, presses feel swallowed · >300: stale orders fire after the player re-decided; mush | all per-verb overrides; Combat's pull frames; `INTERACT_WINDOW_MS` | TR-INP-018 |
| `INTERACT_WINDOW_MS` (override) **DERIVED, not tuned (review fix — Annex EX-4)** | max(declared worst-case arcs) + `INTERACT_MARGIN_MS` | derivation-owned | too low: TR-INP-029's test fails structurally (fixed by derivation) · too high: a tap during a fight opens the cache the moment the body frees — surprise, not order (margin keeps it honest) | `body_busy` (F-08); publisher declarations (SYS-06 + SYS-08) | TR-INP-029 |
| `INTERACT_MARGIN_MS` **NEW** | 100 | 50–200 | too low: derivation barely covers arcs — timing jitter breaks the promise · too high: stale-order risk grows | `INTERACT_WINDOW_MS`; publisher declarations | TR-INP-029 |
| `BACKDASH_TAP_WINDOW_MS` | 280 | 200–400 | <200: flick-release-flick misses the window — the day-one gesture fails on the native rig · >400: ordinary retreat micro-adjustment misfires hops | `BAND_WALK_ENTER` (edge source); `facing`; Movement's hop lock | TR-INP-056 |
| `CHIP_HOLD_COMMIT_MS` | 150 | 100–300 | <100: grazes commit — irreversible spend from a brush, the worst failure direction · >300: spend weight becomes a stall | chip preview visuals (SYS-24); panic discriminator | TR-INP-068 |
| `CROUCH_HOLD_GUARD_MS` | 90 | 60–150 | <60: brushes engage crouch — accidental orders · >150: deliberate holds feel unheard | `CROUCH_ENTRY_*` (accumulator counts only in-zone) | TR-INP-066 |
| `CROUCH_ENTRY_ANGLE` | 25° | 15–40 | <15: cone ≈ straight-down — diagonals never crouch, precision demanded of the player (banned) · >40: side-drag drift crouches accidentally | `CROUCH_EXIT_ANGLE` (must stay above entry) | TR-INP-066 |
| `CROUCH_ENTRY_MAG` | 0.65 | 0.45–0.85 | <0.5: light touches crouch · >0.85: near-full deflection required — **the same dp drag maps to different magnitudes as `STICK_LEASH` moves** (tune the pair together) | `STICK_LEASH`; presets | TR-INP-066 |
| `CROUCH_EXIT_ANGLE` | 45° | 30–60 | <30: diagonal crouch-walk pops up constantly — the dual-threshold hysteresis dies · >60: standing requires near-releasing the stick | `CROUCH_ENTRY_ANGLE` | TR-INP-066 |
| `CROUCH_EXIT_MAG` | 0.40 | 0.25–0.55 | <0.25: barely-touched stick keeps her crouched · >0.55: the wide-exit promise breaks | `CROUCH_ENTRY_MAG` | TR-INP-066 |
| `BAND_CREEP_ENTER` | 0.25 | 0.15–0.35 | <0.15: re-summoned thumbs inch — the failure the bands exist to prevent · >0.35: the creep band starves | `STICK_DEADZONE` (must sit far below); `BAND_HYST` | TR-INP-065 |
| `BAND_WALK_ENTER` | 0.45 | 0.35–0.60 | <0.35: flicks meant as creep land as walk · >0.60: walking needs near-full deflection — fights the leash; also the backdash edge source | `STICK_LEASH`; `BAND_HYST`; backdash | TR-INP-065 |
| `BAND_HYST` | 0.05 | 0.02–0.12 | <0.02: sensor noise chatters bands at boundaries · >0.12: huge sticky zones — exits feel unheard | both `BAND_*_ENTER` (exit = entry − hyst; nesting invariant) | TR-INP-065 |
| `CREEP_RATIO` | 0.5 | 0.35–0.65 | <0.35: creep reads as a stall under Movement's ramp · >0.65: creep ≈ walk — the third order loses meaning and walk-length room metrics blur | SYS-06 ramps; level-design walk-length metrics | TR-INP-065 |
| `STICK_LEASH` | 56 dp | 40–80 | <40: thumb runs out of travel — pinned early, creep hard to hold · >80: full deflection needs long drags — flicks under-deflect and mis-band | `CROUCH_ENTRY_MAG`, `BAND_WALK_ENTER` (magnitude-per-dp coupling); thumb reach | TR-INP-009 |
| `STICK_DEADZONE` | 4 dp | 2–12 | <2: sensor noise reads as creep jitter at rest · >12: fine positioning dead, creep entry demands large drags | `BAND_CREEP_ENTER`; leash | TR-INP-014 |
| `STICK_ZONE_WIDTH_PCT` | 42% | 35–50 | <35: cramped, anchor re-homes mid-fight · >50: invades cluster and pause real estate | cluster geometry; one-thumb band; mirror | TR-INP-069 |
| `ATTACK_BTN_POS_DP` | 88 right / 56 up | ±20% | too central: overlaps Jump's thumb travel · too peripheral: panic presses miss | `CLUSTER_GAP_DP`; mirror; hit floors | TR-INP-069 |
| `ATTACK_BTN_VISUAL_DP` | 60 | 48–72 | <48: smallest-finger target breaks · >72: occludes gameplay art | size presets; `DP_FLOOR_GAMEPLAY` | TR-INP-069 |
| `JUMP_BTN_POS_DP` | 44 / 100 | ±20% | same shape as Attack position | same | TR-INP-069 |
| `JUMP_BTN_VISUAL_DP` | 56 | 44–72 | same shape as Attack visual | same | TR-INP-069 |
| `DASH_SOCKET_POS_DP` | 44 / 36 | **locked by policy** — position is the muscle-memory promise; moving it post-tease breaks pre-formed memory | n/a by policy | dormant rendering | TR-INP-012 |
| `PAUSE_CORNER_DP` | 48 | 44–56 | too small: accidental pause from edge swipes · too large: eats edge margins | dead-tap margins | TR-INP-069 |
| `CLUSTER_GAP_DP` | 12 | 8–20 | <8: hit rects collide at hit-scale 1.5 · >20: cluster outgrows the one-thumb band | hit floors × hit scale; one-thumb band | TR-INP-069 |
| `ONE_THUMB_BAND_PCT` → **`REACH_DISC_PCT`** (renamed — review fix: disc semantics) | 30% of safe-area diagonal | 25–35 | too small: cluster controls leave the disc — the reach claim fails its own audit · too large: the claim becomes unfalsifiable | all cluster geometry; safe-area contract | TR-INP-069 |
| `CLUSTER_OPACITY` | per SYS-24 | 0.4–1.0 | too low: controls invisible against either truth's backdrop · high end is safe | art readability budget; dual-palette doctrine | TR-INP-009 |
| `MIRROR` | off | toggle | mis-set = hindered play, not breakage | every spatial knob above; bubble interior-offset + leader line must mirror too (SYS-24 layout law) | TR-INP-009 |
| `BUBBLE_HIT_DP` | 56 | 48–72 | <48: below the gameplay floor — a11y violation · >72: overlaps neighbors, z-order arbitration fires constantly | `DP_FLOOR_*`; `TOUCH_HIT_SCALE`; cluster clearance | TR-INP-067 |
| `BUBBLE_EDGE_MARGIN_DP` | 16 | 12–24 | <12: bubble under system-gesture bars · >24: unreachable near edges | orientation; crop law | TR-INP-067 |
| `BUBBLE_CLUSTER_CLEAR_DP` | 12 | 8–20 | <8: bubble sits under the thumb's shadow · >20: pushed off its interactable | cluster geometry | TR-INP-067 |
| `BUBBLE_LEADER_BREAK_DP` | 90 | 60–120 | <60: leader line drawn for trivial offsets (noise) · >120: prefer-above fallback reads as a teleport | prefer-above fallback | TR-INP-067 |
| `BUBBLE_FADE_IN/OUT_MS` | 100 / 150 | 80–250 | too fast: a dynamically appearing control is unreadable — the hazard the slack exists for · too slow: stale bubbles during fights misdirect presses | F-10 binding (press during fade-out tail) | TR-INP-067 |
| `BUBBLE_LABEL_MAX_CHARS` | 6 | 4–8 | too low: words stop fitting ("SHIFTING" breaks) · too high: label sprawl | `BUBBLE_TEXT_DP` | TR-INP-067 |
| `BUBBLE_TEXT_DP` | 14 | 12–18 | <12: unreadable at arm's length · >18: overflows the ≤6-char imperative | label chars; contrast | TR-INP-067 |
| `BUBBLE_CONTRAST_RATIO` | 4.5:1 | ≥4.5 | lower: WCAG violation · higher: costs palette room against the dual-truth doctrine | art bible palettes | TR-INP-067 |
| `DP_FLOOR_GAMEPLAY` | 48 | 48–56 | below 44 violates the absolute floor · above 56: small phones cannot fit the cluster | `DP_FLOOR_ABSOLUTE` (must be ≤); hit scale | TR-INP-070 |
| `DP_FLOOR_ABSOLUTE` | 44 | 44 (compliance floor — practically fixed) | below: a11y violation, full stop | gameplay floor | TR-INP-070 |
| `TOUCH_HIT_SCALE` | 1.0 | {1.0, 1.25, 1.5} discrete | 1.5: overlaps appear by design → z-order arbitration handles it; beyond 1.5 needs a re-layout, not a bigger number | every hit rect; `CLUSTER_GAP_DP` | TR-INP-070 |
| `CROUCH_MODE` | hold | hold/toggle | toggle bypasses cone + guard (button truth enters F-04 directly); Jump clears the latch in both modes | toggle edge cases | TR-INP-070 |
| `ATTACK_HOLD_REPEAT` | off | on/off toggle | on: repeats are ordinary presses — supersede caps stall; no interaction with OS repeat (separate filter) | supersede law; repeat-rate knob when shipped | TR-INP-070 |
| `HAPTIC_GLOBAL_STRENGTH` | 1.0 | 0–1 | 0: legal — visuals carry all meaning (text+shape law) · oversaturated: noise fatigue defeats the low-vision gain | channel map; SYS-29 hooks | TR-INP-070 |
| `HAPTIC_CHANNEL_MAP` | light=press · medium=commit · heavy=clash/stagger | designer-fixed | wrong mapping = the haptic language lies about meaning | global strength; Combat's meaning ownership | TR-INP-070 |
| `PAD_DEADZONE_RATIO` **NEW (review fix)** | 0.12 | 0.05–0.25 | too low: stick-center noise reads as creep jitter on pads · too high: fine pad steering dead | same coupling shape as the touch pair | TR-INP-014 / F-02 |
| `TRACE_RING_TICKS` **NEW (review fix)** | 600 (10 s @ 60) | 300–1800 | too small: long gesture chains truncate · too large: wasted memory | composite gestures (VS) | TR-INP-032 |
| `DASH_SOCKET_VISUAL_DP` **NEW (review fix)** | 48 | 44–56 | was undefined; ≥ floor required | gap law | TR-INP-069 |
| `BACKDASH_ARM_MAG` **CONDITIONAL NEW KNOB** | = walk entry (no separate knob by default) | 0.25–0.45, V12-gated | promoted only by AC-64 device evidence | `BAND_WALK_ENTER`, `BAND_HYST` | TR-INP-056 |
| `CHIP_TAP_COMMIT_MS` **NEW (a11y, Annex EX-2)** | 50 | fixed designer constant | below: grazes commit (worst direction) · above: not a "tap" anymore | `CHIP_HOLD_COMMIT_MS`; a11y toggle | TR-INP-068 |
| `BACKDASH_BTN_TOGGLE` **NEW (a11y)** | off | on/off | — | cluster geometry (4th socket at (130,138)) | TR-INP-070 |
| `DORMANT_DIM_AFTER_TEASE` | per SYS-24 **PROVISIONAL** | — | too aggressive: the socket effectively vanishes — the muscle-memory promise breaks | TR-INP-012 policy; SYS-24 rendering | TR-INP-012 |
| `PANIC_BRUSH_DISCRIMINATOR` **NEW KNOB** | undefined — decide by slide speed or hold-time when the chip goes live | — | needed to fire the distinct "not signed" haptic vs ordinary cancel; flagged so it isn't silently assumed | `CHIP_HOLD_COMMIT_MS` | TR-INP-068 |
| `HOLD_REPEAT_RATE` **NEW KNOB** (designer-only, when the toggle ships) | TBD | — | wrong rate defeats the a11y purpose or trivializes deliberate pressing | supersede law | TR-INP-070 |
| `STINGER_TOUCH_TOLERANCE_MS` (VS) | TBD — generous by doctrine | — | too low: shapes become reflex tests (banned) · too high: quarter-spins steal plain attacks via composite precedence | TR-INP-033 precedence | TR-INP-031 |
| `STINGER_PATTERN_WINDOW_MS` (VS, keyboard/gamepad ↓↘→ buffer) | TBD (concept Open Question) | — | interacts with the attack half's own window (composite = two components, each with tolerance) | `INTENT_WINDOW_MS`; composite hook | TR-INP-031 |

### Exposure — who may turn what

**Designer-only (never in Recalibration).** The feel-identity core: `INTENT_WINDOW_MS` + the whole override map (the window is fixed scope per TR-INP-035), `BACKDASH_TAP_WINDOW_MS`, `CHIP_HOLD_COMMIT_MS`, all band knobs, `CROUCH_HOLD_GUARD_MS`, both dp floors, all cluster/bubble geometry (positions, visuals, gap, margins, fades, label, contrast), `STICK_ZONE_WIDTH_PCT`, `ONE_THUMB_BAND_PCT`, `DORMANT_DIM_AFTER_TEASE`, `PANIC_BRUSH_DISCRIMINATOR`, both Stinger windows, the haptic channel *map*, hold-repeat *rate*. Rationale: these values **are** the SotN texture — the bands make distances learnable, the windows make pressing-signing trustworthy; exposing them invites players to retune the fantasy away from itself.

**Player-facing (Recalibration / accessibility).** Exactly the TR-INP-009/070 ratified lists, nothing more: `MIRROR`, button size presets (60/56 dp values are the M preset's defaults), `CLUSTER_OPACITY`, `STICK_LEASH`, `STICK_DEADZONE`, down-zone thresholds **as presets** (Default / Wide / Precise covering `CROUCH_ENTRY_ANGLE/MAG` — the 90 ms guard stays designer-only: "a brush is not an order" is identity, not preference), `TOUCH_HIT_SCALE`, `CROUCH_MODE`, `ATTACK_HOLD_REPEAT` toggle, `HAPTIC_GLOBAL_STRENGTH`.

**Provisional lifetimes:** `INTERACT_WINDOW_MS` (resolve when the Combat GDD publishes its arc budget) · `DORMANT_DIM_AFTER_TEASE` (SYS-24 sign-off) · chip live behavior + `PANIC_BRUSH_DISCRIMINATOR` (chip is a Reserved slot until SYS-17/SYS-24 at VS) · both Stinger windows (Reserved-VS).

## Visual/Audio Requirements

*(Input is a foundation system — brief requirements; detailed VFX/audio design belongs to SYS-29/SYS-04.)*

- **Haptic channel (ratified)**: light = press/preview acknowledgment, medium = commit/use, heavy = clash/stagger (the last two's *meaning* is owned by Combat). Global strength knob 0–1; haptics are an accessibility gain, not decoration. Event hooks: press/depress edges fire exactly once (AC-61).
- **Press acknowledgment visuals**: the held-state visual is the acknowledgment — `BUTTON_HELD_VISUAL` persists for the full commitment (the touch-side proof of the Early Press). **No per-press popups ever** (TR-INP-064; would cheapen MEMORY CACHED's rarity).
- **Sound events this system emits** (SYS-04 designs; this GDD names them): soft confirm chime on chip commit; distinct "empty chip" sound paired with the shake; *no* generic button-press sounds at MVP — silence is the resting state of a pressed button.
- **Doctrine binding**: input visuals obey the telegraph doctrine (color-flash + shape, never opacity pulses) and the text+shape-never-color law; every state-bearing control reads in grayscale.
- **Haptic capability table (review fix)** — capability probed at boot, result logged; the best available rendition fires per event:

| Device class | Haptic rendition | Degrade path |
|---|---|---|
| iOS | style-based only (light/medium/heavy map natively to impact styles; no amplitude scaling) | strength knob maps to style choice |
| Android API 26+ | amplitude scaling | full channel map honored |
| Android < 26 | on/off only | strength maps to 0/1 |
| No-vibrator hardware | silent | visuals carry all meaning (text+shape law) |
- **No lobby/VFX of its own**: the glitch transition, clash sparks, and juice live in SYS-29; input contributes the honest event edges only.

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:input-control-mapping` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## UI Requirements

*(Behavior-level specification — all rendering/visual design is SYS-24's (HUD GDD); this GDD owns semantics and states.)*

- **Recalibration screen** (pause → Controls): exposes exactly the player-facing list from Tuning Knobs — mirror toggle, button size presets (S/M/L; defaults are the M values), cluster opacity slider, stick leash + deadzone, down-zone presets (Default/Wide/Precise), `TOUCH_HIT_SCALE`, crouch hold/toggle, attack hold-repeat toggle, haptic strength, per-action rebinding for KB/gamepad, Restore Defaults. **Must visibly document the three fixed touch semantics** (crouch = down-zone, item = chip hold, Interact = bubble) rather than offer them as changeable (TR-INP-008). AccessKit: name/role/focus for every control; keyboard-navigable end to end (AC-52).
- **Touch help overlay**: static diagram of the current layout from pause, with gesture cards for day-one gestures (backdash: double-tap back — the verb is taught, the chain it enables never is; toggle-crouch: double-tap-down; a11y Backdash button when enabled); doubles as the mirror-toggle preview.
- **Recalibration a11y settings (Annex EX-2)**: crouch mode (hold/toggle), chip tap-commit toggle, Backdash button toggle — present as settings, never as rebindings of the three fixed semantics (AC-09 rider).
- **Contextual Interact bubble states**: hidden (nothing in range) → fading in (100 ms) → lit with label (the prompt publisher's text) → fading out (150 ms); state-gated unavailability shows the label as the reason ("SHIFTING — WAIT"), never silent grey. Presentation owned here; rendering SYS-24's.
- **Dormant Dash socket states**: hidden → dimmed-after-tease (lock glyph) → active. `DASH_SOCKET_VISIBILITY` knob; policy PROVISIONAL pending SYS-24.
- **Chip states**: idle → preview (highlight ring + item name + count + "release to use" microcopy + light haptic) → committed flash (count ticks down, medium haptic, chime) → empty (distinct haptic + shake, never silent). Slide-off → cancel with no trace.
- **Pause entry**: corner control (48 dp) outside all zones; menu content is SYS-05/SYS-24's.
- **📌 UX Flag — Input & Control Mapping**: this system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the **Recalibration screen** and the **touch help overlay** before writing epics; stories referencing them must cite `design/ux/[screen].md`, not this GDD. Noted for the systems index at completion.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **Input Architecture ADR** — InputMap layout, buffer-service shape (pure, clock-injected, lazy expiry), floating-stick pattern (raw ScreenTouch/Drag actuating real InputMap actions), remap persistence, `(raw_axis, move_order)` wire shape, same-tick capture/consume ordering, and the 11 engine-verification items (device-ID constants, dual-focus touch routing, emulation defaults, `action_press` × deadzone interplay, SDL3 rumble API, recursive-disable property, stretch defaults) | technical-director + gameplay-programmer via `/architecture-decision` | Before first implementation story |
| 2 | ~~`INTERACT_WINDOW_MS` value (PROVISIONAL)~~ **CLOSED 2026-11-11 (review):** the window is derived at boot from declared publisher arcs + margin — see TR-INP-029 (Annex EX-4) | SYS-08 + SYS-06 (declarations) | Declared at publisher registration |
| 3 | `DORMANT_DIM_AFTER_TEASE` policy + dormant-socket rendering | SYS-24 HUD GDD | At HUD authoring |
| 4 | `PANIC_BRUSH_DISCRIMINATOR` definition (proposal: slide-off velocity ≥ X dp/ms) | SYS-17 + SYS-24 at VS | Chip goes live |
| 5 | Stinger tolerances (`STINGER_TOUCH_TOLERANCE_MS`, `STINGER_PATTERN_WINDOW_MS`) | SYS-12 Motion Input GDD | VS authoring |
| 6 | Map surface on touch: pause-menu tab proposal | SYS-25 + SYS-24 ratification | VS authoring |
| 7 | Haptics event qualification — which events beyond the mapped three earn buzz | SYS-29 Juice GDD | At Juice authoring |
| 8 | Damage-vs-context race: hit lands the same frame as Interact confirm — which wins | SYS-07 Health + SYS-15 arbitration | At either GDD's authoring |
| 9 | Advance/skip policy for Reading (skip must never skip a choice) | SYS-28 Narrative Presentation | At its authoring |
| 10 | Keyboard scancode defaults so AZERTY/Dvorak aren't broken; symbol-correct display | First PC build | PC milestone |
| 11 | Default-binding confirm pass (dual defaults are proposals) | Combat playtest cohort | After Combat GDD |
| 12 | On-device probe: touch→Control routing post-dual-focus + emulation defaults (build with the MVP week-1 shift-shader probe) | gameplay-programmer | MVP week 1 |
| 13 | Input test-harness service (scripted axis/press streams for GUT) — cheap now, expensive to retrofit | Input ADR scope | With the ADR |
| 14 | Sub-480×270 crop: full ruling beyond the clamp | Edge Cases follow-up | Device-matrix QA |
| 15 | Touch-cancel per-platform verification (OS cancel delivery may under-deliver on some profiles — fallback: visibility-change disposal + phantom telemetry, TR-INP-073 rider) | device QA | Device-matrix pass |
| 16 | Haptic capability probe results per device class (Visual/Audio table) | device QA | Device-matrix pass |

*OQ#1 riders (review fixes):* the signed-strength representation for injected/hardware action strength; the pipeline-order dependency for the intra-tick choreography (captures→offers→acks→expiry) — the ADR either confirms this order or returns an achievable order that amends the Edge Case.

## Annex — Contract Exceptions & Engine Verification

*Single home for every ruling that deviates from a default law (review fix), and the full engine-verification list. Rule ID refs: TR-INP-078 = this annex's governs-the-governors clause — every future deviation ruling lands here or the deviation doesn't ship.*

### EX — Contract exceptions

| # | Exception | Bends | Rationale |
|---|---|---|---|
| EX-1 | Backdash is reflex-class: no buffer, single-tick offer, drop-when-busy | the intent-window default | a delayed dodge can walk the player into a hit; SotN-exact |
| EX-2 | A11y modes: crouch toggle (double-tap-down), a11y Backdash button/key, chip tap-commit at 50 ms | TR-INP-008 fixed semantics + confirmation-weight principle | accessibility bent by design, as settings not rebindings |
| EX-3 | App blur disposes touch-originated held states (KB/pad held states persist) | TR-INP-047(1) "held states persist" | an occluded surface's truth is unreadable; hardware truth is |
| EX-4 | `INTERACT_WINDOW_MS` derived from publisher declarations + margin | "windows are hand-tuned constants" | makes the ratified promise structural |
| EX-5 | Pull-and-hold custody — Combat holds the honored intent across its arc | naive "input resolves it" reading | the Early Press guarantee is two-part: input holds, Combat executes |
| EX-6 | Retracted guarantee: stall parity across tap rates (on record) | TR-INP-022's original claim | superseded by the G1/G2/G3 theorem; honesty over face-saving |
| EX-7 | Registry is **eight** body verbs | "seven forever" | backdash recognized as a Tier 1 verb (2026-11-11 review) |
| EX-8 | One-thumb claim = defined reach disc, centers-in-disc at scale 1.0 | the old ≤30%-screen band | testable geometry replaced an untestable claim |
| EX-9 | Hit-overlap at hit-scale 1.5 is resolved (z-order), not prevented | collision-free assumption | the floors are promises; arbitration is the mechanism |
| EX-10 | Portrait-locked at MVP | rigidity assumption | reach math + safe-area contract assume portrait; landscape = post-MVP re-audit |
| EX-11 | body_busy fails open / `facing` fails closed | uniform failure policy | per-state failure policy is explicit: a misfired dodge is worse than a missing one |
| EX-12 | Crouch exit unguarded (entry guarded 90 ms) | symmetric-guards assumption | the asymmetry IS the crouch-walk hysteresis |

### Engine verification items (the full 11 — ADR must verify each before the first implementation story)

1. Device-ID constants (`InputEvent.DEVICE_ID_MOUSE` / `DEVICE_ID_KEYBOARD`, 4.7) — rebind-code disambiguation.
2. Dual-focus touch routing (4.6) — multi-touch `InputEventScreenTouch` delivery to Controls/GUI.
3. Dual-focus **visual** feedback divergence (4.6) — HUD focus styles per input method.
4. SDL3 rumble API surface (4.5) — exact method names for the haptic channel.
5. SDL3 device detection + hot-swap events (4.5) — `joy_connection_changed` semantics.
6. SDL3 button-mapping normalization vs the standard-layout table (4.5) — glyph selection per pad type.
7. Recursive Control disable property (4.5) — whole-hierarchy mouse/focus disable for HUD toggling.
8. Stretch/scale defaults vs touch coordinates — `canvas_items` + `expand` interplay with F-06.
9. `action_press(strength)` × InputMap deadzone interplay — validates the deadzone-0 policy (TR-INP-014).
10. Same-tick capture/consume ordering in the SceneTree input pipeline — the intra-tick choreography's achievability (OQ#1).
11. Mouse-as-touch emulation defaults on desktop — the floating stick must ignore synthesized mouse events.

## Acceptance Criteria

**Classification legend:** `[GUT]` automatable in Godot Unit Test (the formulas are pure/injected per the GUT testability map) · `[DEVICE]` on-device manual QA (multi-touch, palm, haptics, OS-cancel, blur) · `[PLAYTEST]` human feel observation with a defined rubric. Dual tags mean the GUT half gates first, the DEVICE half confirms. Coverage note: rule IDs TR-INP-027, 038–044, 049–055 are unused numbering gaps — coverage spans the 63 IDs that exist (TR-INP-075…078 added by the 2026-11-11 revision).

### Registry & Verb Semantics

- **AC-01** [GUT] *(TR-INP-001, TR-INP-002)* — **GIVEN** a booted MVP build with the action registry loaded, **WHEN** the build audit dumps every registered action with its tier, status, and puller, **THEN** every action id appears in exactly one tier, Tier 2 contains zero aliases of any Tier 1 id, the **eight body verbs** + `stinger` socket are present, and no action id routes to two semantic meanings.
- **AC-02** [PLAYTEST] *(TR-INP-002)* — **GIVEN** a playtest cohort of ≥5 (mix of touch-native and PC), each completing ≥30 min of play, **WHEN** the control questionnaire asks "name any button that sometimes does two things," **THEN** zero testers name one. **Reproduction step (review fix):** a named dual-purpose button counts only if the facilitator reproduces the dual behavior on device within 5 minutes; unreproducible names are logged as misrecall, discarded from the bar, and their rate reported.
- **AC-03** [GUT + DEVICE] *(TR-INP-003, TR-INP-012)* — **GIVEN** Dash registered Locked-at-start with its dormant socket at final position, **WHEN** the socket is pressed pre-unlock and then again post-unlock, **THEN** pre-unlock produces no execution, no error state, no registry change; post-unlock the identical press lights the socket and executes; lifecycle audit shows every action in exactly one of Active/Locked-at-start/Reserved-VS with zero consuming code paths behind Reserved-VS. (Visual dim level: deferred to SYS-24 sign-off — Flag U-3.)
- **AC-04** [GUT] *(TR-INP-004)* — **GIVEN** the registry at eight body verbs, **WHEN** a third aerial variant is added as a Combat state over (verb + body state), **THEN** the registry diff is empty, no input-layer file changes, registry count unchanged (audited at eight).
- **AC-05** [GUT] *(TR-INP-005)* — **GIVEN** `jump` pulled by its single registered owner, **WHEN** a second consumer registers for the same action, **THEN** registration is rejected with a loud error and the original binding is unchanged.
- **AC-06** [GUT] *(TR-INP-057)* — **GIVEN** the traversal ladder Dash → Wall Jump → Double Jump with Double Jump locked, **WHEN** a jump press is delivered mid-air pre-unlock and post-unlock, **THEN** pre-unlock executes nothing and errors nowhere; post-unlock it executes; the input-layer event record is bit-identical in both cases (gating lives in SYS-06, not delivery).

### Cross-Rig Delivery

- **AC-07** [GUT] *(TR-INP-006, TR-INP-007)* — **GIVEN** all three rigs configured, **WHEN** a boot audit runs and a recorded human input session is replayed through the dispatcher against mocked pullers, **THEN** every Tier 1 verb has a bound source on all three rigs at boot (missing = boot failure), and the replayed stream produces output identical to the human capture.
- **AC-08** [GUT] *(TR-INP-071, TR-INP-006)* — **GIVEN** keyboard and touch both connected, **WHEN** keyboard holds right (move_x = +1) and a stick touch lands left, **THEN** `move_x` flips to the touch value; a subsequent keyboard press re-takes it — while event verbs fire honestly from either rig into the same slots.
- **AC-09** [GUT] *(TR-INP-010/011, TR-INP-034/035, TR-INP-008)* — **GIVEN** a fresh install, **WHEN** the binding-scope audit enumerates Recalibration's exposed controls, **THEN** both keyboard defaults are pre-bound (`A/D`+arrows, `Space/Z`, `X/J`, `Down/S`, `Shift`, `E`, `Q`), gamepad layout matches the table (`A`=Jump, `X`=Attack, `Y`=Interact, `RB`=Dash, `LB`=Quick-use, `Start`=Pause), the rebindable set matches TR-INP-034 exactly, and **no exposed control can change** crouch=down-zone-only, Quick-use=chip-hold-only, Interact=bubble-only, gesture patterns, or the intent-window value.
- **AC-10** [GUT] *(TR-INP-036, TR-INP-037)* — **GIVEN** a changed keyboard binding and stick leash, **WHEN** the session saves, the process reloads, and Restore Defaults runs, **THEN** the persisted config is `user://controls.cfg`, schema-version stamped, byte-identical after reload; the save file (SYS-03) contains zero controls fields (schema grep); Restore produces a byte-identical factory config for bindings **and** ergonomics.
- **AC-11** [GUT] *(TR-INP-009)* — **GIVEN** default ergonomics, **WHEN** `STICK_LEASH` 56→64 dp, `STICK_DEADZONE` 4→8 dp, `MIRROR` on, and `CLUSTER_OPACITY` change live, **THEN** F-02's pin point and neutral floor shift on the next sample, cluster and bubble geometry mirror, and no verb stops delivering mid-session.
- **AC-12** [DEVICE] *(TR-INP-009)* — **GIVEN** a left-handed playtester with `MIRROR` on, **WHEN** they complete the MVP core loop on a real device, **THEN** zero input failures are recorded in the session log.
- **AC-13** [GUT] *(rig anomalies)* — **GIVEN** a gamepad holding a state and a pending buffered intent, **WHEN** the gamepad disconnects mid-hold, **THEN** held states sourced from that device release as if lifted, the captured pending intent survives untouched, and no error state is raised.

### Intent Window & Buffer

- **AC-14** [GUT] *(TR-INP-013, TR-INP-017, TR-INP-062)* — **GIVEN** the two delivery channels, **WHEN** a jump press lands, Down is held while airborne, and Attack is tapped, **THEN** jump produces an edge event and a readable held state, the held Down is still engaged on landing without re-press, Attack produces exactly one window signature per touchdown, and crouch produces a state that never enters any buffer.
- **AC-15** [GUT] *(TR-INP-014)* — **GIVEN** a recorded state stream, **WHEN** the run repeats with Movement's coyote setting toggled, **THEN** the reported `grounded`/`move_x`/`crouch` streams are bit-identical between runs while downstream behavior differs.
- **AC-16** [GUT] *(TR-INP-015)* — **GIVEN** OS key-repeat at its fastest, **WHEN** keyboard Attack is held 3 s, **THEN** exactly one press is captured and one intent enters the window.
- **AC-17** [GUT] *(TR-INP-018/019, F-05)* — **GIVEN** the body mid attack-recovery (Combat-mocked), **WHEN** Jump and Attack are pressed on the same frame, **THEN** both verbs hold independent pending slots with their own windows, and each slot record carries the press-frame snapshot (`crouching`, `grounded`, `move_x`, `body_busy`) equal to the published states at that tick.
- **AC-18** [GUT] *(TR-INP-020, F-05)* — **GIVEN** the Early Press setup (attack pressed 6 ticks before a Combat-mock strike-contact frame), **WHEN** the window runs, **THEN** the intent is offered every tick **including the press tick** (zero dispatch delay), the ack at the contact frame consumes it, the clash fires exactly once, and input executed nothing on its own.
- **AC-19** [GUT] *(TR-INP-021)* — **GIVEN** a consumed attack intent, **WHEN** the slot is re-offered and a new press arrives during recovery, **THEN** the consumed slot never re-fires, and the new press opens a fresh window that resolves exactly once.
- **AC-20** [GUT] *(TR-INP-022, F-05)* — **GIVEN** a **600 ms (36-tick) arc mock** (pinned: ≥ 2× window [300 ms] + max inter-tap gap [250 ms] = 550 ms floor), **WHEN** a 12 t/s scripted stream and a 4 t/s scripted stream run against it, **THEN** the 12 t/s run shows a pending slot at every arc tick with exactly one resolution at the mock's pull frame, the 4 t/s run shows ≥ 1 pending gap with a probe pull frame inside a gap resolving nothing, both runs never show two pending slots, and every honored order's stamp equals the latest press ≤ that tick (the corrected G1/G2/G3 theorem — stall parity is not claimed).
- **AC-21** [GUT] *(TR-INP-024)* — **GIVEN** a pending intent mid-window, **WHEN** hit-stop freezes the game clock for 300 ticks and then a pause gate opens, **THEN** age is frozen during the freeze (the breath extended 1:1), the intent resolves identically regardless of wall-clock after unfreeze, and pause entry clears the slot with no execution.
- **AC-22** [GUT] *(TR-INP-025)* — **GIVEN** coyote ∈ {0, 5, 10} ticks, **WHEN** jump is pressed ~60 ms before landing (run A) and ~60 ms after leaving ground (run B), **THEN** run A's press is buffered and pulled at landing, run B's press is never buffered, and input-layer records are identical across all coyote settings.
- **AC-23** [GUT] *(F-01, F-05, TR-INP-023)* — **GIVEN** the conversion law, **WHEN** the boundary table runs at each rate, **THEN** 140 ms → 5@30 (166.7 ms), 9@60 (150.0 ms), 17@120 (141.7 ms), 34@240 (141.7 ms); exact-integer cases round with zero overshoot; effective duration never < contract ms; age == window is honored, age == window+1 expires with zero execution or notification; a per-verb override demonstrably replaces the default for its verb only; a mid-session `physics_tps` change recomputes windows and re-baselines ages with no early expiry.
- **AC-24** [GUT] *(TR-INP-074, F-01, F-02)* — **GIVEN** out-of-range config (override ≤ 0, leash ≤ 0, deadzone ≥ leash), **WHEN** registered, **THEN** overrides clamp to 1 ms, leash floors at 1 dp, deadzone ≤ 10% of leash, no division-by-zero, every verb still delivers, one dev-mode warning logged.

### Touch Surface & Feel

- **AC-25** [GUT] *(TR-INP-059, F-06, TR-INP-063, TR-INP-070)* — **GIVEN** the device-profile matrix (2400×1080 @2.75; 1560×720 @2.0; 4K desktop; sub-480×270 clamp), **WHEN** the hit-rect audit computes every region, **THEN** every hit rect satisfies `hit_art_px ≥ (dp_floor × touch_hit_scale) ÷ hud_scale` at scales 1.0/1.25/1.5, the bubble uses 56 dp, no hit rect is smaller than its visual, `k` clamps to 1 on tiny screens with crop-edge dead taps, and screen→art coordinate mapping is exact.
- **AC-26** [GUT] *(TR-INP-060)* — **GIVEN** overlapping regions (hit-scale 1.5), **WHEN** a touchdown spans two regions and drags across a boundary mid-hold, **THEN** the touch binds exactly one region at landing (z-order winner), the other receives nothing, no mid-touch rebind occurs, release unbinds cleanly.
- **AC-27** [DEVICE] *(TR-INP-016, TR-INP-063, TR-INP-060)* — **GIVEN** the device matrix (small phone, large phone, one tablet; Android + iOS), **WHEN** three fingers play move + jump + attack concurrently, a stick + bubble-finger pair works simultaneously, and a palm/edge touch lands on the letterbox or outside every zone, **THEN** ≥3 contacts track with zero cross-capture, stick + secondary finger operate independently, and the letterbox/palm touch binds "dead" — no capture, no error, no haptic.
- **AC-28** [GUT] *(TR-INP-072, TR-INP-060)* — **GIVEN** the stick owned by finger 1, **WHEN** a second finger enters the zone and finger 1 lifts with a different finger landing a frame later, **THEN** the second finger is fully inert while owned, the zone frees on release, and the handoff reports at least one honest neutral frame — never a blended continuation.
- **AC-29** [GUT] *(TR-INP-014, F-02)* — **GIVEN** property-fuzz per source (review fix: touch profile = dp leash/deadzone; gamepad profile = ratio deadzone, leash 1.0), **WHEN** raw offsets sweep inside deadzone, mid-range, at, and beyond the leash, **THEN** magnitude is exactly 0 inside deadzone, pinned exactly 1.0 at/over leash, bounded [0,1], sign-preserving, and bit-identical for identical inputs — for BOTH source profiles.
- **AC-30** [GUT] *(TR-INP-065, F-03)* — **GIVEN** a 10k-sample fuzz walk across both sticky zones **computed from the knobs** (`BAND_CREEP_ENTER − BAND_HYST` … etc. — no hardcoded thresholds, review fix), **WHEN** band selection evaluates each sample, **THEN** no sequence oscillates bands while the thumb holds position, the nesting invariant `walk_on ⇒ creep_on` holds everywhere, output ∈ {−1.0, −0.5, 0, 0.5, 1.0}, and keyboard/d-pad ±1.0 always maps to WALK or NEUTRAL.
- **AC-31** [GUT] *(TR-INP-066, F-04)* — **GIVEN** the crouch cone state machine, **WHEN** scripted vectors run — entry sustained 89 ms / exactly 90.0 ms, drift (0.52, 0.85) ≈ 31°, drift (0.80, 0.60) ≈ 53°, stick release — **THEN** 89 ms never engages, exactly 90.0 engages, 31° stays crouched (crouch-walk never pops), 53° stands (unguarded exit), release stands, and keyboard Down delivers boolean truth bypassing cone and guard.
- **AC-32** [GUT] *(TR-INP-066, F-08)* — **GIVEN** a crouch-zone entry whose guard elapses during an attack commitment, **WHEN** the commitment ends with the thumb still in-zone vs having left, **THEN** case A applies crouch on the first body-free tick against the **current** vector/thresholds (guard never re-charged), case B applies nothing, and zone evaluation never paused.
- **AC-33** [GUT] *(TR-INP-061, F-04, F-09, F-05)* — **GIVEN** Gameplay-context hit-stop, **WHEN** the crouch guard and a chip hold cross their thresholds during the freeze while a window ages, **THEN** wall-clock timers keep counting, the window age stays frozen, the chip that crossed 150 ms during Gameplay hit-stop commits with its age frozen until resume, and crouch application defers via body-available.
- **AC-34** [GUT] *(TR-INP-067, TR-INP-069, TR-INP-077)* — **GIVEN** a lit prompt and the cluster, **WHEN** the layout audit runs against registration data, **THEN** every pairwise center distance ≥ 84 dp at hit-scale 1.5 (Attack 70/60 v60 · Jump 40/142 v56 · Dash socket 156/44 v48 · a11y Backdash 130/138 v48, toggle-only), all hit edges inside viewport ∩ safe area (TR-INP-077), all cluster centers inside the reach disc at scale 1.0, the bubble sits ≥16 dp from edges, ≥12 dp clear of cluster/pause, **never inside the movement zone** (zone-boundary + clearance fallback), prefer-above fallback + leader beyond 90 dp, hit = 56 dp, label ≤6 chars at ≥14 dp; pause corner 48 dp; mirror flips every spatial element including bubble offset and leader line.
- **AC-35** [GUT] *(TR-INP-068, F-09)* — **GIVEN** a chip touchdown with an item, **WHEN** release is scripted at 149.9 ms / exactly 150.0 ms / with slide-off mid-hold / with an app blur mid-hold, **THEN** 149.9 never commits, 150.0 commits with the press stamped at the commit tick on the **game clock** (no retroactive touchdown stamping), slide-off cancels free at the exit frame and dominates hold duration, blur cancels silently with no commit on return.
- **AC-36** [DEVICE] *(TR-INP-073)* — **GIVEN** a chip hold, a stick touch, and a crouch guard in flight, **WHEN** the OS cancels the touch (system gesture, app switch, notification shade) on each, **THEN** the chip hold cancels silently (never commits on return), the stick releases, the crouch guard resets — a cancelled touch is never a signed order on Android/iOS.
- **AC-37** [DEVICE] *(TR-INP-060, TR-INP-068, F-06)* — **GIVEN** a chip hold or stick contact in progress, **WHEN** the device rotates or density rescales mid-touch, **THEN** no commit results from the region moving under a stationary finger, the hold keeps its binding, release duration alone decides commit, and regions re-register correctly after the change.

### Gestures & Backdash

- **AC-38** [GUT] *(TR-INP-056, F-07)* — **GIVEN** facing right (SYS-06-mocked) on empty ground, **WHEN** the edge stream runs walk-back → release → walk-back with press2 − press1 ≤ 17 ticks, **THEN** a single-tick `backdash` intent publishes at press2's tick and the Movement mock pulls it the same tick; press2 − press1 == window exactly is honored (inclusive); the KB `C` / pad `B` a11y press publishes a direct intent with the same single-tick offer.
- **AC-39** [GUT] *(TR-INP-056, F-07)* — **GIVEN** the detector, **WHEN** each negative case runs — held back only, missing release, release+press2 same tick, press2 beyond window, body busy at completion, hit-stop mid-recognition, re-edges during the hop, **a forward-sign walk entry between the back presses, a `facing` flip mid-machine** — **THEN** held back walks and never backdashes, invalid orderings drop and restart cleanly, direction changes and facing flips reset to IDLE, late press2 re-arms as fresh press1, busy-at-completion drops silently (never deferred), and no input-side cooldown exists.
- **AC-40** [GUT] *(TR-INP-032)* — **GIVEN** the MVP build, **WHEN** the reservation audit runs (grep + runtime probe), **THEN** no Stinger code path executes anywhere, the backdash detector is the sole active gesture machinery, the composite hook is idle-but-alive, press records carry the `gesture` tag, and the raw stick trace publishes pre-normalization data.
- **AC-41** [GUT] *(TR-INP-058)* — **GIVEN** all shipped content, UI strings, localization tables, and bestiary/log stubs, **WHEN** a text/asset sweep runs for backdash→Stinger or gesture-combo hints, **THEN** zero hint surfaces exist. The discovery half of TR-INP-058 is deliberately **not** a pass/fail criterion (Flag U-2) — tracked as playtest observation only.
- **AC-42** [GUT, VS-gated] *(TR-INP-031, TR-INP-033)* — **GIVEN** the VS build with the recognizer flagged in, **WHEN** quarter-spin + attack completes within tolerances on touch and `↓↘→` + attack on keyboard/gamepad, **THEN** exactly one Stinger fires and no plain attack also fires; quarter-spin alone produces nothing; the tolerance bracket test bounds `STINGER_TOUCH_TOLERANCE_MS` (too-low misses shapes, too-high eats ordinary attacks).

### Context Gates

- **AC-43** [GUT] *(TR-INP-045, TR-INP-046)* — **GIVEN** the six-row context table, **WHEN** each context is entered/exited in sequence including menu-focus stacked above Paused, **THEN** exactly one context is active at a time, gameplay verbs are dead and buffers cleared in every non-Gameplay context, input routes per the table, and focus restores on exit to Gameplay.
- **AC-44** [GUT] *(TR-INP-047)* — **GIVEN** pending intents and held states, **WHEN** a gate opens and a press is captured on that exact frame, **THEN** all buffers clear at entry (held states persist), the same-frame press is dropped regardless of age, no verb resolves on the transition frame, and no timer in the gate service can auto-expire a context's input availability (static audit + accelerated-dwell functional check).
- **AC-45** [DEVICE] *(TR-INP-047)* — **GIVEN** active gameplay (and each other context) on device, **WHEN** the app is blurred mid-fight and restored, and platform Back is pressed in Gameplay and Paused, **THEN** blur forces Paused from any context and restore returns to Paused (never straight to Gameplay), Back in Gameplay opens Pause, Back elsewhere maps to that context's back; **blur disposes touch-originated held states while keyboard/gamepad held states persist** (TR-INP-047 amendment, Annex EX-3). (iOS: blur + on-screen controls only; platform Back is Android-only.)
- **AC-46** [GUT] *(TR-INP-048)* — **GIVEN** a log or dialogue open, **WHEN** gameplay verbs are pressed while the SYS-28 mock holds the world frozen, **THEN** only advance/skip controls route to SYS-28, movement/combat verbs produce nothing, buffers stay empty, and closing returns full Gameplay delivery next frame.

### Accessibility

- **AC-47** [GUT + DEVICE] *(TR-INP-070, TR-INP-060, F-06)* — **GIVEN** TOUCH_HIT_SCALE ×1.25 then ×1.5, **WHEN** the audit recomputes hit rects and a real device session touches overlapping neighbors, **THEN** scaling is hit-only (visuals unchanged), the 48/44 dp floors hold after scaling, and each overlap touchdown binds exactly one region per z-order — resolved, never double-fired (double-fire = S2).
- **AC-48** [GUT + DEVICE] *(TR-INP-070, TR-INP-066)* — **GIVEN** CROUCH_MODE = toggle, **WHEN** a press latches, movement occurs crouch-walking, an attack fires from crouch, Jump is pressed, and re-crouch is attempted, **THEN** the latch toggles on single press (cone + guard bypassed), Jump clears the latch in both modes with one rule, re-crouch requires one deliberate press, and the sequence completes on device.
- **AC-49** [GUT] *(TR-INP-070, TR-INP-015, TR-INP-022)* — **GIVEN** hold-repeat OFF (audit) then ON, **WHEN** the button is held, **THEN** OFF produces exactly one press, ON produces input-generated edge-triggered repeats obeying the supersede law, and OS key-repeat remains filtered independently.
- **AC-50** [DEVICE] *(TR-INP-070, TR-INP-064)* — **GIVEN** the haptic channel map, **WHEN** each mapped event fires at strength 1.0 then 0, **THEN** the correct weight is felt per event at 1.0, and at 0 every haptic is silent while every meaning remains conveyed through the held-state visual (loop completed haptics-off). Per-device-class capability rendition: see AC-70.
- **AC-51** [GUT] *(TR-INP-064, TR-INP-067, TR-INP-070)* — **GIVEN** all shipped UI and gameplay visuals, **WHEN** the static accessibility audit sweeps, **THEN** zero popup nodes exist on any press path, every state-bearing visual carries text or shape in addition to color, and the bubble label measures ≥4.5:1 contrast. *(Provisional palette until SYS-09 art lands — Flag U-7.)*
- **AC-52** [GUT + DEVICE] *(TR-INP-070)* — **GIVEN** pause → Recalibration and the touch help overlay, **WHEN** AccessKit properties are inspected and a screen-reader session runs, **THEN** every control exposes name + role, the bubble's accessible name equals its label text, focus order navigates pause → Recalibration → every control by keyboard, the help overlay exists and documents the three fixed touch semantics, and nothing requires hover.

### Performance

- **AC-53** [GUT + DEVICE] *(frame budget — methodology pinned, review fix)* — **GIVEN** the input path instrumented as one scope (touch capture → F-02/03/04 → buffer tick F-05 → dispatch/ack) with the budget **≤ 1.0 ms hard cap at p99 per physics tick** (≈6% of the 16.6 ms frame; input contributes zero render-path work), **WHEN** the measurement runs — **reference environment:** mid-tier Android (SD-7-class, 8 GB, Android 14), sustained thermal state (≥ 10 min warm-up, not throttled), battery ≥ 50%, performance mode, release build; **workload:** 3 concurrent touches driving all live verbs at plausible peak (12 t/s mash + stick sweeps + guard oscillation), 60 s @ 60 tps = 3,600 ticks = the measurement window; a separate 10-minute comfort soak (DEVICE) checks thermal drift, not the cap — **THEN** p99 ≤ 1.0 ms in GUT and on the reference device; **enforcement split:** GUT cap breach fails the build (CI), device regression beyond 2× baseline is a warning-tier perf bug, not a build block.
- **AC-54** [GUT] *(allocation — rewritten, review fix)* — **GIVEN** a 10,000-tick GUT soak under the full workload **plus a no-workload control run**, **WHEN** `Performance.get_monitor` object/resource counts and `Memory.get_memory_usage` (static+dynamic) are sampled at tick 0 and tick 10,000 and the control run's deltas are subtracted, **THEN** net object delta == 0, net resource delta == 0, dynamic heap growth ≤ 256 KB — any positive net allocation fails; the harness must be allocation-neutral (the control subtraction is the proof).
- **AC-55** [GUT] *(F-01/F-05 rate matrix)* — **GIVEN** one scripted input pattern, **WHEN** it runs at 30/60/120 tps with ms-contracts re-baselined per F-01, **THEN** the set of per-verb outcomes (honored/expired/consumed/superseded) is identical across rates — the promise is rate-invariant.

### Cross-System Contracts

- **AC-56** [GUT] *(TR-INP-026, TR-INP-028)* — **GIVEN** crouch held and Attack pressed mid-window, **WHEN** crouch is released before the Combat-mock pulls, **THEN** input delivered both the state and the event with both timestamps, Combat's consumption-frame rule selects the **stand attack**, and the pull's snapshot still logs `crouching=true`.
- **AC-57** [GUT] *(TR-INP-029, F-08)* — **GIVEN** publishers mocked for locks and commitments, **WHEN** publications are raised, cleared, and one goes silent mid-window, **THEN** `body_busy` is the fresh-every-tick OR, availability flips on the exact publication tick, and a silent registered publisher fails **open** with a loud dev-mode assertion.
- **AC-58** [GUT] *(TR-INP-029/030, TR-INP-075, F-08, F-10)* — **GIVEN** a scripted interact scenario against a cache mock **with publishers declaring arcs (Combat mock 300 ms, Movement mock 240 ms)**, **WHEN** the sequence runs — corridor press; later-lit bubble; press with bubble lit mid-commitment; walk away mid-window; commitment ends in-zone; **a second press on the same lit prompt after a consumed signature** — **THEN** the corridor press expires on the press frame, the later-lit bubble never consumes a stale press, the mid-swing press resolves on the first body-free tick **structurally** (`INTERACT_WINDOW_MS` derives to 300 + margin — U-4 closes), mid-window unlight clears the intent **immediately**, the signed latch makes the same-lit-prompt second press unresolvable (AC-67), and a walk-by can never open the cache; an undeclaring publisher triggers the fallback + dev assert.
- **AC-59** [GUT] *(SYS-15, TR-INP-047/030/026)* — **GIVEN** the Prompt Slot registry, **WHEN** two publishers light on the same frame and a resolving press opens a gate that same tick, **THEN** input never observes two lit prompts, the press consumes the prompt and the context transitions that tick, all other intents clear at entry, no third verb resolves on the transition frame.
- **AC-60** [GUT] *(SYS-24, TR-INP-068)* — **GIVEN** the single touch dispatcher, **WHEN** gameplay touches land and a chip is tapped with zero items, **THEN** HUD never consumes gameplay touches directly (asserted by probe), registration and visuals come only from SYS-24, and the no-item chip tap is a silent no-op.
- **AC-61** [GUT] *(SYS-29, TR-INP-024, TR-INP-064)* — **GIVEN** the clock contract and Juice's hooks, **WHEN** SYS-29 requests hit-stop and press/depress events fire, **THEN** the buffer clock honors the freeze 1:1, haptic hooks fire exactly once per edge, and no per-press popup or text announcement is emitted through any hook.
- **AC-62** [GUT] *(SYS-05, TR-INP-045, TR-INP-047)* — **GIVEN** the ContextGate service, **WHEN** SYS-05 transitions contexts and quit semantics execute, **THEN** gate enforcement follows SYS-05's transitions unconditionally, a `pause` event reaches SYS-05 from all three rigs, and quit flow clears all gameplay delivery atomically.
- **AC-63** [PLAYTEST] *(Player Fantasy success signature — coded rubric, review fix)* — **GIVEN** ≥ 5 mixed-rig testers with ≥ 30 min sessions and the interview script, **WHEN** two facilitators independently code the transcripts, **THEN** they agree ≥ 90% (disagreements adjudicated by the definition list, never by taste): **Q1** "Describe the controls to a friend" → *trust-code* if the answer contains any of {always does what I mean / obeys / listens / trust / never lost a press} and none of {lag / delay / late / slow / response time}; **Q2** "Describe a moment a press felt off" → *early-press observation* if they describe pressing before the visible hit and the game answering (logged, **non-gating**); **Q3** "Describe your last death — what did you press?" → *lag-attribution* (failure signal) if startup frames are named as lag; **Q4** "Name anything you pressed that did nothing" → feeds AC-02's probe. **Pass bar:** ≥ 3/5 trust-coded on Q1 · 0/5 lag-attribution on Q3 · Q2 logged as VS depth observation only.

### Revision addenda (2026-11-11 design-review — AC-64…76)

- **AC-64** [DEVICE] *(TR-INP-056, TR-INP-065)* — **GIVEN** the reference device matrix and 3 uncoached testers, **WHEN** 20 natural flick-backs per device and the KB/pad a11y presses run, **THEN** ≥ 90% of flicks cross the arming threshold with peak-magnitude p95 ≥ threshold + 0.10, ≥ 85% of flick-release-flick sequences complete ≤ 280 ms, the a11y path is 100%, and any device failure blocks MVP lock and triggers the `BACKDASH_ARM_MAG` fallback evaluation.
- **AC-65** [GUT + DEVICE] *(TR-INP-076)* — **GIVEN** events injected at known sub-tick offsets, **WHEN** stamped, **THEN** every stamp is the next tick boundary after arrival (zero retroactive stamps under fuzz), and the device probe's arrival→stamp distribution reports p95 ≤ 2 ticks on all reference profiles.
- **AC-66** [GUT + DEVICE] *(TR-INP-077, TR-INP-069, TR-INP-063)* — **GIVEN** the four-profile matrix with forced gesture-bar insets, **WHEN** the layout audit computes centers, radii, and gaps, **THEN** all six pairwise center distances ≥ 84 dp at hit-scale 1.5 (⇒ all 1.0 requirements), every hit edge lies inside viewport ∩ safe area, both letterbox surfaces bind dead on both axis orientations, all cluster centers sit inside the reach disc, and a device pass confirms taps at the inset boundary are dead.
- **AC-67** [GUT] *(F-10)* — **GIVEN** a lit bubble that consumed a press, **WHEN** a second press lands on the same lit prompt, **THEN** it is unresolvable at entry (signed latch); unlight + relight re-arms a fresh signature; a *different* prompt relit never accepts the stale press (existing law intact).
- **AC-68** [GUT] *(TR-INP-020, TR-INP-029)* — **GIVEN** a puller mock that faults after `try_pull` returns, **WHEN** the transaction completes, **THEN** the slot is fully consumed (never half-consumed), the fault is logged as puller custody, no re-offer occurs, and a silent publisher in production mode emits one rate-limited telemetry event with unchanged gameplay.
- **AC-69** [GUT + DEVICE] *(TR-INP-068, TR-INP-066, TR-INP-056 a11y)* — **GIVEN** each a11y toggle on, **WHEN** the gestures run, **THEN** the chip commits at 50.0 ms and not at 49.9, the Backdash button publishes a direct intent (single-tick offer, body-free-gated), and toggle-crouch latches on double-tap-down while Jump still clears it.
- **AC-70** [DEVICE] *(haptic capability table, Visual/Audio)* — **GIVEN** each device class (iOS style-based; Android 26+ amplitude; Android < 26 on/off; no-vibrator), **WHEN** each mapped event fires, **THEN** the best available rendition fires per event and haptics-off is silent everywhere (replaces AC-50's per-class body; AC-50 keeps the strength-0 loop).
- **AC-71** [GUT] *(TR-INP-071)* — **GIVEN** keyboard holding move_x and a stick touchdown, **WHEN** the transfer runs, **THEN** ownership flips exactly on the touchdown edge (a stick hover/creep without a new edge after release does NOT retake), two ticks without the owner's assertion release the channel to neutral, and a keyboard re-press retakes via its edge.
- **AC-72** [GUT] *(TR-INP-074)* — **GIVEN** each invariant V1–V12 with a violating config, **WHEN** loaded in dev and in production mode, **THEN** dev boot fails naming both knobs, production applies exactly the listed resolution + telemetry event, and the post-clamp config satisfies every invariant.
- **AC-73** [GUT] *(TR-INP-014, F-02)* — **GIVEN** a boot audit, **WHEN** actions register, **THEN** every InputMap deadzone == 0, the touch fuzz profile (dp leash/deadzone) and gamepad fuzz profile (ratio deadzone, leash 1.0) both satisfy the AC-29 properties per source, and an injected `action_press(0.5)` yields magnitude 0.5 post-deadzone — identical to a hardware half-deflection.
- **AC-74** [GUT] *(contract-exceptions annex)* — **GIVEN** the 11-item engine verification list, **WHEN** the ADR lands, **THEN** every item has a verdict (verified/amended) — open items block the first implementation story.
- **AC-75** [GUT] *(TR-INP-075)* — **GIVEN** a Combat-mock 300-tick arc, **WHEN** the attack intent is pulled at tick 10, **THEN** the slot is cleared at the ack tick, the mock holds and executes at its arc frame, and no input-side re-offer occurs.
- **AC-76** [GUT] *(TR-INP-067)* — **GIVEN** an interactable whose adjacency lands inside the movement zone, **WHEN** the bubble positions, **THEN** it spawns at the zone boundary + clearance, never inside the zone, in mirrored layouts too.

### Untestable-as-written flags (fixed in the criteria above)

| # | Rule | Problem | Fix |
|---|---|---|---|
| U-1 | TR-INP-002 | "Playtesters can't name a dual-purpose button" — no cohort/bar defined | AC-02: N ≥ 5, zero named = pass |
| U-2 | TR-INP-058 | "≥1 spontaneous discovery report" gates on luck | AC-41 gates the falsifiable half only (no hint surfaces); discovery is observation, never pass/fail |
| U-3 | TR-INP-012 | Visual half pending SYS-24 sign-off | AC-03 gates delivery + position now; visual criterion added when SYS-24 signs off |
| U-4 | TR-INP-029 | Promise depended on `INTERACT_WINDOW_MS` = TBD | **CLOSED by the revision:** the window is now derived at boot from declared publisher arcs (TR-INP-029) — AC-58 runs structurally |
| U-5 | TR-INP-022 | "Identical stall durations" — adjudicated FALSE | **CLOSED by the revision:** claim retracted (Annex EX-6); TR-INP-022 rewritten as the G1/G2/G3 theorem; AC-20 pins the 600 ms arc mock |
| U-6 | TR-INP-068 | "Distinct 'not signed' haptic" — discriminator undefined; chip is Reserved | Define `PANIC_BRUSH_DISCRIMINATOR` (proposal: slide-off velocity ≥ X dp/ms) before chip goes live at VS |
| U-7 | TR-INP-067 | 4.5:1 contrast needs final dual-truth palettes | AC-51 audits the provisional palette now; re-runs as a release gate when final palettes exist |
| U-8 | TR-INP-007 | "Parity of contract, not of milliseconds" — unfalsifiable as a claim | AC-07: boot-audit + scripted-vs-human replay equivalence as the falsifiable proxy |

### Smoke gate — "input is ready for QA hand-off" (operational home: the QA plan)

Headless GUT + one device pass; any single failure blocks hand-off: AC-01 (registry audit) · AC-07 (rig parity) · AC-23 (F-01 boundary + rate matrix) · AC-17 (same-frame dual intent) · AC-18 (Early Press) · AC-20 (supersede law + keep-alive corollary) · AC-16 (OS repeat) · AC-38/39 (backdash space incl. resets) · AC-44 (gate rules) · AC-27 [DEVICE] (3-contact + dead taps) · AC-35 (chip commit discipline) · AC-58 (interact law) · AC-25 (hit floors) · AC-53/54 (perf + zero-alloc) · AC-10 (persistence isolation) · AC-66 (layout audit) · AC-24 (knob clamps).

