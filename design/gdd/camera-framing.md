# Camera & Framing

> **Status**: In Design — all sections authored (pending CD-GDD-ALIGN + the three-seat design review)
> **Author**: user + game-designer/gameplay-programmer (authoring session, GLM-5.3-Flash)
> **Last Updated**: 2026-11-13
> **Design Review**: pending — three seats (creative → GLM-5.3-Flash; technical/QA → deepseek-v4.1-flash-1017) + the mandatory qa-lead spot-check on any repaired text
> **Creative Director Review (CD-GDD-ALIGN)**: CONCERNS (2026-11-13, five findings F1–F5 — none REJECT-class) → REVISED in-session (all five repairs applied: the staging-band duty widened to all participants/threat effects; the reveal arc window authored threat-free; the courtesy re-anchored to her read + the `courteous` language guard; the P1 rubric operationalized the applause + missing-verb anti-signatures; the fifth pillar tie added)
> **Implements Pillar**: "SotN, Not Hollow Knight" (deliberate framing — the room is the screen; distances learnable in strides) · "One World, Two Truths" (the reveal's held frame; the arena's pristine lie stays framed) · "Read, Then Strike" (the look-ahead keeps the read on screen)

## Overview

Camera & Framing is the eye of the trust contract: it owns the one camera the game renders through under ADR-0001's D1 model — the world renders in a root-stretch-disabled SubViewport at a safe-derived **integer scale** (the camera lives in the world's 480×270 art-unit space at `zoom (k, k)`), the HUD renders native above it, and **every framing output is whole art pixels**: the camera never zooms, never subpixel-drifts, never re-scales. It consumes SYS-02's per-room bounds as its **default limits** ("room limits first" — the room's honest rect is the frame's word; when a room is smaller than the view the centered rule holds and the room's backdrop covers the slack), consumes SYS-06's publications (`facing`, velocity, `grounded`, wall state, `body_busy`, the hop/knockback events) to drive the follow, and executes SYS-29's shake requests — **clamping them inside the room limits** — while publishing the on-screen player position SYS-24's thumb-coverage caps and the hold targets SYS-10/11's truth flip and reveal consume. The MVP camera is deliberately small: follow + a small facing-keyed look-ahead with a commit delay, vertical motion only on landing, a long-fall look-down, and the **two authored framing zones** (the Denial arena's boss lock; the backtrack reveal's held frame). It **reads no input** — no ninth verb, no manual look, no zoom (rejected: it breaks the integer scale and the mobile fill-rate) — a camera you never notice because it never lies about where you are. Without it the world has no frame: honest bounds without a window, a boss without a stage, a reveal without the held breath.

→ *Implementation patterns (the `Camera2D` limit wiring under the SubViewport render path, `reset_smoothing()` on the atomic handoff, the look-ahead's game-clock integration, integer-snap enforcement) are ADR raw material for the planned **Camera & Framing ADR**; this GDD stays at the behavior level. The camera reads no input (TR-INP-004's eight-verb closure — the down-zone is Crouch); the follow runs on the game clock (SYS-32's plan, consumed by SYS-29).*

## Player Fantasy

### The named fantasy — The Room Waits to Be Read

You never think about the eye. It is already ahead — a few steps in the direction you chose — and once it commits, it holds: your strike, your retreat, your stumble all happen inside a frame that has already decided. It moves on the ground's schedule, rises and falls only when you land, and when the drop is long it looks down with you and shows you the whole fall. In a duel it gives you the stage; in a revelation it gives you time. And its weight — the tremble when the exchange answers — stays inside what the room can honestly show. In a world of errands, contracts, and receipts, nothing is given freely — but **the read is hers**: the assassin's trained patience is the one uncontracted thing she owns, and the frame is its instrument — not the employer watching her, never the surveillance register; an eye that waits because she reads.

### The contract — four terms, each testable

1. **It goes ahead of you, and then it holds.** The frame leads by your facing and does not chase: the commit delay is the hold's promise, and a strike or a stumble happens inside a frame that already decided. *(Facing-keyed look-ahead with a commit delay; frozen through attack, backdash, knockback, hit-stop.)*
2. **It moves on the ground's schedule.** No vertical motion while airborne; the eye re-frames on landing only. A long fall is shown whole — the eye tips down with you and the floor arrives inside the frame. *(Vertical reframe on landing; long-fall look-down presents the full drop.)*
3. **In a duel it gives you the stage; in a revelation it gives you time.** The Denial arena is held whole for the length of the fight — the duel reads as staged choreography. The backtrack truth resolves inside a held frame while the world waits — **shown, not sprung**, SYS-02's words inherited without paraphrase. *(The arena framing lock; the reveal hold at the framing zone.)*
4. **Its weight stays inside the room's honesty.** The tremble is weight, not spectacle: the clash family's few pixels, clamped within what the room can truthfully show. The eye never reaches past the room — no closer view, no straddled thresholds — because a frame that exceeds the room is a frame that lies about it. *(Shake clamped to the room limits; never zooms; never straddles two rooms.)*

### Anchor moment — The Wrong Corridor, Held

You take the long corridor back — the one your feet know by now. The eye rides a few steps ahead of your facing, the way it always does, already holding the ground you're about to cross. Then it stops. Not because you stopped. The frame settles on the far wall and stays, and the world waits with it — no lurch, no snap, no hand at your collar. While you walk the last few steps, the wall's other truth resolves inside a frame that never moved to meet it: shown, not sprung. By the time you arrive, the room is simply larger than it was, and it never once grabbed you into knowing.

### Anchor moment — The Whole Fall

You miss the perch. The drop is longer than the screen. The eye does not chase your feet — it tips down with you and holds, and you see the whole fall and the floor it ends on. The height was told before the pit answered.

### Language law

**Use:** frame, eye, room, stage, duel, shown, waits/waited, read/reading, hold/held/still/steady, whole, honest, weight, settle, ahead, land, fall, courteous.
**Ban (player-facing copy):** *camera* (dev sections only — player-facing says *the frame* or *the eye*); all mechanism jargon — viewport, deadzone, lerp, smoothing, easing, snap, screen-space, integer scale, look-ahead (say *already ahead*), zoom, pan, sweep, cinematic, dynamic. Ban the sinister register — *watch, spy, stalk, surveil* — the eye is patience, never surveillance. *Sprung* appears only inside the inherited phrase **"shown, not sprung."** **The `courteous` guard:** the word describes the frame's *patience* — never the world's kindness (warmth in her world is false, tragic, or corrupting) — and never appears in diegetic or log text (SYS-28's surface).
Falsifiability rule: every feel-sentence is verifiable by playtest rubric or build check; if verifying it would need a stopwatch on reflexes, cut it.

### Success signature

Playtesters say: *"saw it coming"* as a fact, not a boast — threats named while still steps out of range, without noticing the eye that made it possible; nobody dies to the unseen in framed zones — the Denial duel described as watched choreography, stages and tells and exchanges, not survived chaos; players stop on their own at the reveal — the held frame reads as an invitation to look. **Anti-signatures** (the failure modes this GDD exists to prevent): "the camera got me killed" in any dialect — an off-screen hit, a threat entering the frame mid-swing, a reveal that lurches (one instance in an authored zone is a breach, not a tuning note); hands reaching for a verb that doesn't exist — dragging the view, asking for manual look, fighting the frame's edges; the eye noticed as an effect — "that camera move was cool" is failure wearing applause, and shake that escapes the room's honest few pixels is the same failure with tremble.

*Pillar ties: "Read, Then Strike" (the waiting is the read-window — telegraphy made spatial) · "One World, Two Truths" (the reveal's held frame is SYS-02's "shown, not sprung" made visible; the arena's pristine lie stays framed) · "SotN, Not Hollow Knight" (a camera that plans, not chases — deliberation as chosen texture) · "Five Goodbyes" (rooms that wait to be read are pages of her mind — backtracking is re-reading her) · "Remade Every Death" (the death-hold is the honest witness frame — a story-death held on the body, without spectacle).*

## Detailed Design

### Core Rules

Three laws govern everything below: **the D1 law** (every framing output is whole art pixels — never zoom, never subpixel), **the game-clock law** (the camera's world state advances only on elapsed `logic_tick`s — a held world holds its eye), and **the command law** (everything with a schedule — arcs, arena, shake — arrives as a command from its owning system; the camera interprets no facing causes, no zone semantics, no boss state; it consumes publications and commands only). Design-source note: the follow/look-ahead/vertical model adapts the Inbound Shovel metroidvania-camera devlog ("How Metroidvania Cameras are Shockingly Different than Platformer Cameras" — the half-screen boundary principle, the push-ahead with a settle, the phase-keyed vertical look-ahead), plus the Order of Ecclesia single-screen boss-stage pattern for the arena hold.

**Rule IDs (`TR-CAM-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** PROVISIONAL marks indicate contracts whose owning GDD touch is recorded, not yet landed; ownership boundaries are intended final. **No input reads; no zoom; no subpixel placement; no room-straddle; no arc constants of its own.**

- **TR-CAM-001 — The purity seam.** **`CameraCore`** is a pure `RefCounted` reducer over injected ports: `BoundsPort` (SYS-02's generation-stamped publication), `BodyPort` (SYS-06's publication), `ShakeQueuePort` (SYS-29's request drain), `ClockPort` (the `GameClock` read view), `TuningPort`, `TelemetryPort`. **No `Input`, no `SceneTree`, no `Time`, no `RenderingServer` — and no `Camera2D` — inside the core** (ADR-0001 §15's seam pattern, applied a third time after `InputCore`/`WorldCore`); the node adapter (`CameraRig`, owning one persistent `Camera2D` child) owns all engine contact. Determinism: the same inputs at the same ticks produce bit-identical state traces. *Test: the core instantiates with fakes; the purity audit greps the five forbidden symbols; two replays are bit-identical.*

- **TR-CAM-002 — The game-clock law.** `CameraCore.advance_world()` is invoked **exactly once per elapsed `logic_tick` and zero times otherwise** — an elapsed tick is `logic_running = (context == GAMEPLAY) ∧ freeze_sources.is_empty()` (ADR §3, read from `GameClock`, never recomputed). During a hit-stop the camera's **entire world pipeline halts** — position, look-ahead FSM, commit countdown, vertical state, hold evaluation — the camera is a *witness of a held world, not an actor in one* (SYS-29's damage numbers hold mid-flight because their world does; a converging follower would be a moving window over a still painting). Pause/gates step nothing; resume continues from identical state — no teleport, no catch-up. **The commit countdown is logic-clock: it does not expire during a freeze — resuming, never dropping.** *Test: a 6-tick hit-stop mid-follow holds the camera bit-stable; the countdown survives; resume closes the gap by normal convergence.*

- **TR-CAM-003 — The D1 integer-snap law.** The camera's rendered placement is **always whole art pixels**. All follow/hold state integrates in **integer hundredths** (the house's no-float law); the emitted position is the integer division `base_px = pos_h ÷ 100`, with the truncation remainder **retained in the gap** (`target − pos`) — the residual *is* the accumulator, so rounding error can neither accumulate nor jitter; a stop-snap at ≤ 0.5 px ends sub-pixel crawl. Dev builds assert the integer-ness of every written position. **The camera never zooms** (D1; zoom rejected through VS); the renderer's pixel-snap settings are admissible only as a failsafe, never as the law's enforcement. *Test: replay asserts integer output at every tick; the fractional-position probe (PR-CAM-05) demonstrates the artifact the law prevents.*

- **TR-CAM-004 — The room-limits law ("room limits first").** On the first camera tick in a room, the limits equal the published `RoomBounds.rect_px` **verbatim through F-RWS-02** — both systems compute identical integers by quoting the same formula (rect-exact when the room ≥ the view; the centered branch otherwise). Per-axis travel is `max(0, dim − view)`; no margins are added. **Missing bounds at the room's first tick is a fail-loud event** (dev assert + telemetry; production holds the last valid state) — never a silent default. *Test: the bounds fixture per room (RM-01 480×272 → 2 px vertical travel; RM-04/06 640×352 → 82 px); the missing-bounds fixture.*

- **TR-CAM-005 — The centered rule.** In any axis where the room is smaller than the view, that axis **locks**: the view's offset into the room is `floor(slack ÷ 2)` from the room's top/left edge, the odd remainder is backdrop-covered at the bottom/right, and follow, look-ahead and shake are **zero in a locked axis**. Dormant at MVP (every room ≥ 480×272) but exercised by F-RWS-02's fixture alcove — the branch ships because the fixture tests it. *Test: the alcove fixture (rect 320×192 → slack_x 160 → 80 px extension per side, span == view on that axis).*

- **TR-CAM-006 — The follow law.** In FOLLOW, the camera target = the **body-center anchor** (SYS-06's published position — see the recorded rider below) + the horizontal lead, and the position chases the target with **one capped exponential on integer hundredths**: `move_h = clamp((target − pos) × ALPHA_H ÷ 100, −MAX_STEP, +MAX_STEP)`. Both target-side and emitted-side clamping to the center-clamp range; the stop-snap ends convergence. Only this tick's publications are consumed — no extrapolation between ticks, ever. *Test: the convergence fixture (32 px swing settles ≈ 0.25–0.3 s); the capped-step fixture; bit-identical replay.*

- **TR-CAM-007 — The vertical law (phase-keyed — the Inbound Shovel model, adapted).** The vertical look-ahead is keyed to the jump phase, not to a threshold: **grounded or wall-clinging, the target sits `V_LOOK_UP_PX` (8) above the head** — the jump-planning space; **rising, the bias tweens to body-center by the apex; falling, it tweens below the feet** — the eye tips down with her, deeper fall = deeper tip. The tween rides `ALPHA_V_H` (10/tick — the heavier, ground-schedule ease). **Landing re-anchors** to the floor anchor and the tween is already converged — the merge, never a stack. The phase model (not a separate rule) is what keeps a cling visible up a shaft and re-centers a knockback; **no separate keep-in-frame backstop rule exists** (the hard-inset alternative was considered and rejected in favor of this model — the video is the design source). *Test: the phase fixtures (grounded bias; apex center; full-fall offset); the landing-merge fixture; the cling-bias fixture.*

- **TR-CAM-008 — The long-fall look-down (the falling phase's completion).** The falling tween completes at **`LONG_FALL_PX` (96)** cumulative downward displacement since the last vertical anchor event — full below-feet offset `LOOKDOWN_PX` (64). 96 px engages before her body would sink past the frame's bottom band (~135 px to the frame edge; the mobile thumb band makes a "technically visible" fall effectively invisible well before that). Displacement counters reset on any grounded tick and on the knockback-family lock's start. Falls shorter than 96 px get a proportional tip; the law is nearly inert in the shallow rooms (RM-01/02/03 clamp it to a no-op) and visible in RM-04/06. *Test: the 96-px threshold fixture; the proportional-tip fixture; the counter-reset fixtures.*

- **TR-CAM-009 — The look-ahead commit law.** The lead is a **discrete committed offset** (`LOOKAHEAD_PX` 32, sign = the facing value): a facing change *proposes*; the proposal commits after `COMMIT_DELAY_MS` (150) of unchanged value on running clock; **the countdown restarts when the proposal changes** (no commit during turn-dancing) and never restarts while it continues. The commit moves the *target*, not the camera — the glide is the follow law's. Stopping never un-commits (facing is binary; the eye stays ahead of the last read). **Cause-blind**: causes are SYS-06's business — the camera reads values and locks only, so a `WALL_TURN` re-commits naturally after the delay with zero wall-specific code. *Test: the commit fixture (flip at T → commit at T+9 — 9 elapsed ticks = 150.0 ms, 10 tick-instants counting the flip tick); the restart fixture (R→L→R never commits); the stop fixture.*

- **TR-CAM-010 — The look-ahead freeze law.** While **any** `body_busy` lock level is active (Movement's {backdash, dash, knockback, knockdown, getup, scripted, `freeze_hold`} + Combat's paired commitments), the FSM **holds its current state verbatim** — offset, proposal, countdown — and resumes (never drops) at lock release (the tick-open snapshot at `end_tick` is already free, TR-MOV-033). **One exception: the knockback/knockdown family drops the offset target to 0 at the lock's `start_tick`** (eased under `ALPHA_H`) — a hit re-centers the eye on the body; the bias re-commits afterward under the ordinary window. Death is the freeze family's terminal member: the camera holds on the body. *Test: the hold-through-dash fixture (invisible by construction — no steering mid-dash); the knockback-drop fixture; the resume fixture; the death-hold fixture.*

- **TR-CAM-011 — The room-swap law.** At SYS-02's commanded swap tick the camera's sequence is: **assert bounds-first** (the new room's `RoomBounds` generation is already published — TR-RWS-006's precondition as an enforceable invariant) → derive the new limits via F-RWS-02 → re-anchor the target at the re-anchored body (lead reset to neutral, vertical re-anchored, zone state cleared and re-evaluated next tick — a spawn inside the arena zone re-locks immediately) → **kill the glide**: `pos = target` exactly, both axes, residual zeroed — one-tick teleport, atomic with the limits swap, so **no tick exists with new limits and an old position**: no straddle, no glide, by construction (the camera-side meaning of `reset_smoothing()`; we own the smoothing). A **freeze guard** asserts no swap under hit-stop. The camera node is **persistent across rooms** (rooms instantiate around it). *Test: the swap fixture (zero straddle frames; the glide-kill assertion; the freeze-guard assert); the every-tick no-straddle assert.*

- **TR-CAM-012 — The arena hold law (HOLD_ZONE — the OoE stage).** On SYS-14's lock command (boss spawn) the camera eases (`HOLD_EASE_MS` 400) to the **fixed single-screen stage point** — the zone's center clamped to the room limits, here RM-06's center **(3520, 176)** — and **fixes there for the fight**: follow, look-ahead and vertical laws all suspended (zone-as-subject); shake still applies, clamped. This is the **Order of Ecclesia pattern**: the boss room is a stage the camera never scrolls during the fight — OoE authors its boss rooms to fit the screen; RM-06 is already authored 640×352 in the APPROVED SYS-02 GDD, so the recorded analog is the **staging-band constraint**: SYS-14/level-design keep the fight inside the held frame's interior (≈ 448×238 px + margin — x ∈ [3296, 3744], y ∈ [57, 295]), and the duty covers **every fight participant and threat effect** — both fighters, projectiles, hazards — not only the boss anchor; the player's reachable space is sealed to the band (the arena's playable interior authored within it), so a reachable side strip is an authoring defect against this row, never a designed state (the honest `on_screen = false` publication and the fallback knob remain the robustness path). Release on SYS-14's defeat command returns to FOLLOW from rest. Locks arriving mid-hold queue FIFO. *Test: the lock/release fixtures; the staging-band data check (the boss anchor inside the band); the FIFO fixture.*

- **TR-CAM-013 — The reveal hold law (REVEAL_HOLD).** On SYS-02's arc-start command (the `reveal_cistern` first crossing, TR-RWS-009) the camera glides, integer-snapped per tick, to the hold point — **(1520, 137)**: the zone center (1392, 224) clamped to RM-03's limits, **and the clamp is load-bearing** (the unclamped center would show 128 px of out-of-room void west of RM-03 — recorded so nobody "fixes" it later) — **completing by the arc's midpoint** (SYS-02's own swap-tick convention, F-RWS-03's shape), then **holds** for the arc's second half while the world waits (the body is on SYS-02's scripted-move lock; the hold coincides with it). **No room swap at any point of the arc** (SYS-02's no-swap guarantee; dev assert). On the arc-end command the camera returns to FOLLOW riding the ordinary follow law — no SYS-32-owned reveal constant exists anywhere (`REVEAL_ARC_MS` and its feel are SYS-02's, OQ-RWS-1). **The arc window is authored threat-free** (a recorded SYS-02 arc-authoring duty — no live strike can reach her during the glide or the hold; the authored data already satisfies it — the wing carries no spawn entries — and the duty makes it contractual). *Test: the glide/hold/return fixture (midpoint completion; the hold-point clamp; the return under τ); the no-swap assert; the threat-free-window data check.*

- **TR-CAM-014 — The shake execution law.** SYS-32 executes only SYS-29's requests — **one preallocated slot**: a new request **replaces** the active one iff strictly stronger (otherwise dropped + telemetry; equal magnitude keeps first-come — the cross-tick generalization of SYS-29's same-tick strongest-wins); the cancel variant clears the slot on the next physics tick. The executor runs **on the physics tick and is freeze-blind** (SYS-29's contract is physics-keyed: 8/8/5-tick durations, cancel-next-tick) — the shake is a gain channel, not world content. Offset = the deterministic per-tick pattern × the **even-step linear decay** (F-CAM-05): whole-px steps 3→2→1→0, first step carrying the remainder frames; signs from a core-owned xorshift seeded by the request tick (replay-deterministic; no engine RNG). The clamp bites only near walls (the shaken view stays inside the room rect; a zero-travel axis shakes zero — recorded consequence: the shallow rooms' tutorial clash reads ≤ 2 px vertical-only). `SCREEN_SHAKE` gating stays SYS-29's — SYS-32 holds no settings knowledge. *Test: the decay table (3/120 → 3,3,3,2,2,2,1,1); the replace/drop fixtures; the cancel fixture; the clamp fixture (asymmetric tremble at the wall, never out-of-room).*

- **TR-CAM-015 — The publication law.** Every physics tick — **unconditionally, including frozen ticks and holds** — the camera publishes `{mode, view_rect_px (int), player_screen_px (int art px, band-relative, post-clamp, pre-shake), on_screen (bool), authority (enum: follow/commit-frozen/hold/look-down/knockback/hit-stop), shake_offset_px, active_hold {zone_id, hold_point_px, start_tick} | null, tick}`. This is the sole channel to **SYS-24** (the thumb-coverage caps: SYS-24 derives caps only from the live published value — never world position, never cached reads — because world-still ≠ screen-still during a hold pan) and to **SYS-10/11** (hold announcements + the per-tick `active_hold` are the truth-flip staging and reveal-seam sync targets). One-way; no consumer write-back; the camera never pre-clamps or pre-shakes SYS-24's value. *Test: the frozen-tick publication fixture; the pre-shake fixture; the no-write-back audit.*

- **TR-CAM-016 — The focus seam (reserved, dormant).** A VS-facing seam (`FocusPort`) exists by which a future focus system may bias the follow target or the limits — **weight ≤ 0.4, bias only, never zoom, never enemy lock-on, never violating D1, the room-limit law or the input ban** — and it ships dormant at MVP (type signature present; nothing writes it). All VS camera ideas (focus objects, in-room directors/false boundaries, a future cutscene zoom spike — the recorded zoom note) route only through this seam. *Test: the seam-exists audit; the no-writer audit.*

- **TR-CAM-017 — Performance and the envelope entry.** SYS-32 joins the MVP gameplay-tick envelope with its own entry — **p99.9 ≤ 0.15 ms / max ≤ 0.45 ms per physics tick** (the lightest joiner: the core is bounded integer work over borrowed references, no copies, no allocation) — and **the bounds read rides this entry** (SYS-02's recorded expectation, kept: SYS-02 prices no row of its own). The **seven-system envelope becomes 2.45 / 6.55 ms** (1.00 SYS-01 + 0.30 SYS-06 + 0.30 SYS-08 + 0.25 SYS-07 + 0.20 SYS-29 + 0.25 SYS-13 + 0.15 SYS-32 = 2.45 p99.9; 2.0+1.0+1.0+0.75+0.60+0.75+0.45 = 6.55 max). **The sum is the budget allocation; the combined soak's measurement is the proof** (the OQ-J2 pattern — recorded for the QA-plan sync). Preallocated: the state structs (scalars in place), the trace ring (256, test-build artifact), the shake slot (one). Heap growth ≤ 256 KB; net allocation delta 0 across the soak. *Test: the 10,000-tick soak on the reference SKU; the allocation audit; the envelope re-derivation check.*

**Recorded rider (the OQ-M1 pattern — one clause, owned elsewhere):** TR-MOV-028's publication list must gain **`position`** — the body-center point (art-px hundredths, quantized at the port boundary); a follow camera cannot exist without it. Movement is APPROVED, so this rides as a recorded rider: **owner lead-programmer + game-designer (the Movement touch); landing gate: before the first SYS-32 implementation story.** Everything else in TR-MOV-028's list is already pinned.

### States and Transitions

| Mode | Entry | In-state | Exit | Room swap | Death / gate |
|---|---|---|---|---|---|
| **FOLLOW** (default) | boot/first room; hold release; arc end | TR-CAM-006…010 | → HOLD_ZONE on SYS-14 lock; → REVEAL_HOLD on SYS-02 arc-start | TR-CAM-011 (snap + reset), remain FOLLOW | death = the freeze family's terminal lock (holds on the body); revive = the swap mechanism; gates: no motion on the transition frame, nothing queued |
| **HOLD_ZONE** (arena) | ← FOLLOW on SYS-14's lock command | fixed stage point; follow/look-ahead/vertical suspended; shake applies (clamped); publication carries `active_hold` | → FOLLOW on SYS-14's release; queued locks FIFO | **force-exit** — a hold never survives a room change: TR-CAM-011 runs, SYS-14 re-commands for any new-room hold (unreachable in authored content — the arena seals; robustness path) | death → exit via force-exit or release |
| **REVEAL_HOLD** (reveal arc) | ← FOLLOW on SYS-02's arc-start | glide to (1520, 137) by the arc's midpoint, hold the arc's second half; no swap; follow laws suspended | → FOLLOW on SYS-02's arc-end (return rides the follow law) | **unreachable** (SYS-02's no-swap-during-arc guarantee; dev assert fail-loud) | **gate-mid-arc is reachable** (TR-MOV-029: arcs die at true gate entry) — on any non-GAMEPLAY context the hold exits to FOLLOW **seeded at the current position, no snap**; on resume the follow law continues (the vanished arc-end cannot deadlock the camera) |

**Transition laws.** 1. Swap is a one-tick **action**, never a state — it executes inside whichever mode is active. 2. Holds dominate FOLLOW; between holds there is **no preemption — FIFO queue** (authored content never conflicts: the reveal lives in RM-03, the arena in RM-06; the queue is the robustness path and is fixture-tested). 3. Mode transitions never cross a room boundary except via the swap action. 4. Authority priority within FOLLOW: hit-stop (the clock gate) > the knockback-family re-center > the lock freeze > the phase-keyed vertical law > the commit window > the base follow — specified now so the systems never fight.

### Interactions with Other Systems

| Boundary | Flow | Contract |
|---|---|---|
| **SYS-01 Input (D1)** | out: the integer view rect (placement for the SubViewport at `zoom (k, k)`) · in: 480×270 art-unit metrics + the safe-derived integer `k` — **build-time constants via data** (the rig reads `RenderMetrics` at boot/resize, never per tick) | never zoom, never subpixel, never non-integer placement; the HUD's CanvasLayer is unaffected (its own transform) |
| **SYS-02 Room & World** | in: `RoomBounds` (atomic, pre-first-tick, generation-stamped) · the reveal arc-start/end commands · the commanded swap tick | SYS-32 owns the snap; SYS-02 owns arc timing + the door-frame mask; SYS-32 never derives zone triggers, never owns arc constants, never writes bounds; **the arena's consumer contract (OQ-RWS-8) is stated here: SYS-14 commands the lock/release and keeps the fight inside the staging band; SYS-32 owns nothing else of the boss** |
| **SYS-06 Movement** | in: position (the recorded rider), velocity, grounded, facing, wall state (published, **unconsumed at MVP — reserved**), body_busy lock levels, hop/knockback events, `logic_running` | consume TR-MOV-024's advance condition verbatim; never interpret `cause`; never extrapolate |
| **SYS-29 Juice** | in: `ShakeRequest` + cancel; `logic_running` | SYS-29 publishes, SYS-32 executes + clamps (TR-JCE-026's boundary; F-JCE-09's offset/decay shape is completed by F-CAM-05); never exceed `SHAKE_MAX_PX`; no settings knowledge |
| **SYS-14 Grief-Boss** | in: lock/release commands (event) | commands only — never read boss HP/state; the staging-band constraint is SYS-14's authoring duty (the OoE analog) and covers **every fight participant and threat effect** — both fighters, projectiles, hazards — with the player's reachable space sealed to the band |
| **SYS-24 HUD** | out: `player_screen_px` (int, post-clamp pre-shake), `on_screen`, view rect — every tick | the thumb-coverage caps' input; SYS-24 owns interpretation and never caches stale reads; no touch geometry crosses |
| **SYS-10/11 Mutation/Seam** | out: hold announcements + per-tick `active_hold` | consumed for truth-flip staging and the reveal seam's sync; the truth flip itself needs **no camera mode** (the epoch applies at one tick boundary; an OQ-J1 freeze holds the eye automatically) |
| **FocusPort (VS, reserved)** | dormant | TR-CAM-016's seam; nothing writes it at MVP |

### The engine probe register (the PROBE-PENDING pattern)

*The ADR-0001 §16 register format, applied to the camera. Every item is `PROBE-PENDING` — an open verdict that blocks **SYS-32's first implementation story**, never this GDD's acceptance. The probe is a throwaway prototype under `prototypes/camera-probe/`; evidence in `production/qa/evidence/sys32/`; no probe code is imported. The engine-reference tree holds zero Camera2D/SubViewport coverage (grep-verified) — a doc-pass creating `docs/engine-reference/godot/modules/camera2d-subviewport.md` is the DOCUMENTED route for the doc-settleable halves.*

| # | Item | Verdict | Evidence / next action | Gate |
|---|---|---|---|---|
| PR-CAM-01 | **Camera2D limits under the D1 SubViewport path** — world-space clamp of the visible 480×270 rect at `zoom (k,k)`; the owning-viewport size source; hard clamp with `limit_smoothed = false` (no glide); `span == view` (centered) and `span > view` (rect-exact) both hold; 4.7 semantics + defaults | **PROBE-PENDING** | Probe scene: the ADR §9 band rig + RM-02's rect + the F-RWS-02 sub-view alcove; teleporting target; next-frame hard clamp at every edge; doc-pass the 4.7 Camera2D class page first | AC-CAM-24 |
| PR-CAM-02 | **`reset_smoothing()` at the atomic handoff** — next-frame vs immediate effect; the 1-frame-glide signature; internal snap-on-activation triggers | **PROBE-PENDING** | Smoothing-enabled variant probe (frame-by-frame capture); the primary design keeps smoothing **disabled** — the probe then verifies the negative (engine adds nothing to a disabled teleport) | AC-CAM-10 (the fixture shares) |
| PR-CAM-03 | **position_smoothing vs the game-clock freeze** — smoothing advances on the render-frame delta (a frozen target keeps easing — the residual-glide class); disabled-state purity | **PROBE-PENDING** *(downgradable: class semantics → doc-pass)* | Doc-pass pins the render-delta/exponential class; the probe confirms disabled-mode purity | AC-CAM-02 |
| PR-CAM-04 | **offset-vs-limits order (the shake clamp law)** — does engine `offset` bypass the limit clamp in 4.7.2 | **PROBE-PENDING** | Probe: view flush at `limit_right`, `offset.x = +3` (and mirrored); the design consequence is pre-decided either way — the shake is baked into the position math pre-clamp; engine offset stays 0 | AC-CAM-14 |
| PR-CAM-05 | **Integer-snap / resampling at zoom k** — pixel-identity at integral art positions (k ∈ {1,2,3,4}); the fractional-position shimmer signature; snap switches snap in band px (guard-only); the final-composite 1:1 check; engine center-rounding at clamped edges | **PROBE-PENDING** | Pixel-exact capture probe: authored-offset vs camera-offset bit-diff; the edge-clamped case; the fractional case (the artifact demo) | AC-CAM-24 |
| PR-CAM-06 | **D1 device cost under camera motion + shake** — fill-rate deltas (hidden/static/scroll/scroll+shake, the S0–S4 states); draw calls vs ≤ 150; same-frame world↔HUD latency; target-memory stability | **PROBE-PENDING** | Device perf probe on the reference SKU per the S0–S4 workload; reuse the AC-53/65 measurement methodology | AC-CAM-23 |
| PR-CAM-07 | **Same-tick limits+position atomicity at the swap tick** — no mixed-state frame (old-limits/new-position or inverse); the persistent node across swaps; the disabled-smoothing teleport renders atomically next frame; `process_physics_priority` ordering (the camera after the swap orchestrator + body phase) | **PROBE-PENDING** | Swap fixture mirroring SYS-02's handoff on the mock `BoundsPort`; frame-by-frame capture across the swap tick; zero straddle frames asserted | AC-CAM-10 / AC-CAM-24 (shared) |
| PR-CAM-08 | **The visual audits** — the subpixel-artifact demo (k ∈ {1,2,3}, fractional vs floored); the shake quantization audit (whole-px offsets; even decay steps; the axis-crossing tail, signed off jointly with SYS-29) | **PROBE-PENDING** | Side-by-side captures (pan + look-ahead + landing) per k; the S4 shake-storm frame-step review | AC-CAM-24 / AC-CAM-25 |

**Counts:** 8 `PROBE-PENDING`, 0 settled. Per ADR-0001's pattern these gate the first implementation story; the GDD's own design keeps engine smoothing/offset unused, which demotes PR-CAM-02/03/04 to verification-of-the-negative.

### Consumed-Contracts Ratification (SYS-32 side)

| Contract | SYS-32's ratification | Test |
|---|---|---|
| TR-RWS-006 / F-RWS-02 (bounds; the limit math) | Limits = the published rect verbatim through the shared formula; missing bounds fail-loud | TR-CAM-004/005 |
| TR-RWS-009 / TR-RWS-015 (the reveal arc; the framing zone) | The command-driven hold; the midpoint-completion glide; no competing constants; hold point (1520, 137) with the load-bearing clamp | TR-CAM-013 |
| TR-RWS-010 (the swap; re-anchor + zeroed velocities) | The one-tick kill-the-glide response; the freeze guard; the persistent node | TR-CAM-011 |
| TR-MOV-022/023/024/033 (locks as levels; `freeze_hold`; the advance condition; tick-open freedom) | The FSM freeze + resume-not-drop; the advance law consumed verbatim | TR-CAM-002/010 |
| TR-MOV-028 (the camera handoff) | The publication consumed; **the `position` rider recorded** (before the first camera story) | TR-CAM-006; the rider note |
| TR-JCE-026 / F-JCE-09 (the shake request; linear decay; the toggle) | The executor + even-step decay (F-CAM-05 completes F-JCE-09); the slot policy; the clamp | TR-CAM-014 |
| ADR-0001 §3/§5 (clocks; freeze scope) | The game-clock law; the freeze-blind shake exception justified (physics-keyed contract) | TR-CAM-002/014 |
| ADR-0001 §9 (D1 wiring) | Whole-art-px placement; no zoom; `position_smoothing_enabled = false` (own math), `limit_smoothed = false`, `drag_enabled = false`, engine limits as the redundancy net | TR-CAM-003/006 |
| TR-INP-004 (the eight-verb closure) | The camera reads no input — ever; no manual look; the toggle-off arrives via the ShakeQueue | TR-CAM-001 |

## Formulas

Three law families govern every formula: **L1 — the D1 integer law** (every camera quantity is a signed integer in hundredths of an art pixel — 1 hundredth = 0.01 px; constant names carry the `_H` suffix (`ALPHA_H_H`, `MAX_STEP_H`, `SNAP_EPS_H`; TR-CAM-006's prose `ALPHA_H`/`MAX_STEP` names the same values); all arithmetic integer, division floor, **no float equality on the camera path** — arrival tests use the explicit threshold `SNAP_EPS_H` 50; the truncation remainder stays in the gap (`target − pos`) — the residual *is* the accumulator; `pos ∈ [center_min, center_max] × 100` per axis always (the clamp domain — origin-agnostic: the MVP room set is positive-origin, VS rooms with negative origins drive `pos`/`view_rect` legally negative, with floor-div emit semantics flagged for VS); the render value is `base_px = pos_h ÷ 100`), **L2 — the game-clock law** (the registry's `ms_to_ticks` ceil family, cited not redefined — ms is the contract, ticks derived by the never-stingy ceil on the active rate; every tick figure re-derives on a rate change), and **L3 — the command law** (every behavior change arrives as data stamped with its tick, consumed at a physics-tick boundary, mutating state atomically within that tick — only this tick's publications are consumed, no extrapolation between ticks, ever; all stochastic behavior seeds from command data through a core-owned xorshift, never wall-clock — bit-identical replay).

**Formula ledger — law vs knob.**

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-CAM-01 | center_range | True law | `VIEW_W/H` (480/270), `HALF_VIEW` (240/135), SYS-02's `rect_px` |
| F-CAM-02 | follow_step | True law | `ALPHA_H_H` 18, `MAX_STEP_H` 1200, `SNAP_EPS_H` 50 |
| F-CAM-03 | commit_conversion | Threshold law | `COMMIT_DELAY_MS` 150; the `ms_to_ticks` family |
| F-CAM-04 | vertical_bias | True law | `V_LOOK_UP_H` 800, `LONG_FALL_H` 9600, `LOOKDOWN_H` 6400, `ALPHA_V_H` 10, `MAX_STEP_H` |
| F-CAM-05 | shake_decay | Threshold law | `SHAKE_MAX_PX` 3 (SYS-29's), the envelope table, the `ms_to_ticks` family |
| F-CAM-06 | hold_point | True law | F-CAM-01's range; SYS-02's zone rects |
| F-CAM-07 | perf_envelope | True law (allocation) | the seven named budgets (TR-CAM-017) |

#### F-CAM-01 · center_range — the camera's word (TR-CAM-004/005)

```
slack_x = max(0, VIEW_W − rect.w)                    slack_y = max(0, VIEW_H − rect.h)
limit_left  = rect.x − floor(slack_x ÷ 2)            limit_top   = rect.y − floor(slack_y ÷ 2)
limit_right = limit_left + max(rect.w, VIEW_W)       limit_bottom = limit_top + max(rect.h, VIEW_H)
center_min_x = limit_left + 240    center_max_x = limit_right − 240
center_min_y = limit_top + 135     center_max_y = limit_bottom − 135
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Room rect | `rect` | Rect2 (int px) | world space, ≥ 0 | The active room's `rect_px` (SYS-02's `room_bounds_contract`) |
| View | `VIEW_W/H` | int px | 480 / 270 | The art-pixel view (pinned) |
| Half view | `HALF_VIEW` | int px | 240 / 135 | Center-to-limit offset |
| Center range | `center_min/max` | int px | `min ≤ max` always | The camera **center's** clamp range |

**Output Range:** per axis `center_max − center_min = max(rect.dim − view.dim, 0)` — never inverted; on a **sub-view axis** the span is 0 (`min == max`, the locked axis). **Examples:** RM-02 `Rect2(640,0,640,272)`: limits (640,0)…(1280,272) → x ∈ [880, 1040], y ∈ [135, 137]. RM-06 `Rect2(3200,0,640,352)`: x ∈ [3440, 3600], y ∈ [135, 217]. Zero-travel row: RM-01 `Rect2(160,0,480,272)` → x ∈ [400, 400], y ∈ [135, 137].

#### F-CAM-02 · follow_step — the one smoothing law (TR-CAM-003/006)

```
gap   = target − pos                                  # int hundredths, signed
move  = clamp(gap × ALPHA_H_H ÷ 100, −MAX_STEP_H, +MAX_STEP_H)
pos  += move
if |target − pos| ≤ SNAP_EPS_H: pos = target          # stop-snap — post-move check (pinned)
emit = pos ÷ 100                                      # floor; whole art px; emitted-side re-clamped
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Target | `target` | int hundredths | in-range × 100 | Desired center this tick (target-side clamped) |
| Position | `pos` | int hundredths | the clamp domain × 100 | Camera-center state; the gap retains the remainder |
| Follow gain | `ALPHA_H_H` | int | 18 (tuning 10–30) | Exponential gain per tick |
| Step cap | `MAX_STEP_H` | int | 1200 (12 px/tick) | Max step |
| Snap epsilon | `SNAP_EPS_H` | int | 50 (0.5 px) | Stop-snap threshold |
| Move | `move` | int hundredths | [−1200, +1200] | This tick's displacement |

**Output Range:** `|move| ≤ 1200`; monotone approach; **termination by snap, never by stall** (`move = 0` only at gap ≤ 5 h, snap at ≤ 50 h). The cap binds iff **gap ≥ 6667 h (66.67 px)** — in practice: one capped tick on a long-fall landing (the 72 px falling→grounded retarget binds when D ≥ 88 px at touch-down), multi-tick after a knockback unlock with displacement > 66.67 px, **never** on commit swings (the max designed retarget is 32 px). **Example — the full 32-px commit swing** (gap 3200 h; first move 576 < cap): remaining hundredths trace `2624, 2152, 1765, 1448, 1188, 975, 800, 656, 538, 442, 363, 298, 245, 201, 165, 136, 112, 92, 76, 63, 52, 43 → snap at tick 22` — **the emitted px stops changing at tick 18 (300 ms), the stop-snap completes at tick 22 (≈ 367 ms)**; the visible swing reads settled by ~0.25–0.3 s. The convergence rides ALPHA_V_H for vertical (a full fall-bias engage settles ≈ 48 ticks ≈ 0.8 s; steady-state lag while falling = 10·f hundredths, inside the half-view for fall speeds f ≤ 13 px/tick).

#### F-CAM-03 · commit_conversion — the delay's shape (TR-CAM-009; `ms_to_ticks` cited)

`COMMIT_DELAY_TICKS = ceil(COMMIT_DELAY_MS × physics_tps ÷ 1000) = ceil(150 × 60 ÷ 1000) = 9` — **150.0 ms exact** (the ceil adds nothing at 60 tps; re-derives at any rate, e.g. 120 Hz → 18).

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Commit delay | `COMMIT_DELAY_MS` | int ms | 150 (pinned) | The stability-delay contract |
| Physics rate | `physics_tps` | int | 60 at MVP | Ticks per second |
| Derived ticks | `COMMIT_DELAY_TICKS` | int | 9 at MVP | Ceil conversion |

**Output Range:** 9 at MVP (the family's [1, 5000]). **Example:** proposal at T; unchanged ticks T+1…T+9; **the commit processes at T+9 — 9 elapsed ticks = 150.0 ms** (10 tick-instants counting the flip tick — the Section C fixture phrase reads exactly this).

#### F-CAM-04 · vertical_bias — the phase-keyed law (TR-CAM-007/008)

```
target_v = anchor_y + bias(state, D)
bias:  grounded, cling → −V_LOOK_UP_H (−800: 8 px above the anchor)
       rising          → 0 (center; the tween is ALPHA_V_H's convergence)
       falling         → min(LOOKDOWN_H, (D × LOOKDOWN_H) ÷ LONG_FALL_H)
D = cumulative downward displacement since the last vertical anchor event
    (resets on ANY non-falling entry: grounded, rising, cling — and on the
    knockback-family lock's start)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Vertical state | `state` | enum | grounded/cling/rising/falling | SYS-06's publication |
| Anchor y | `anchor_y` | int hundredths | ≥ 0 | Body-center anchor (the recorded rider) |
| Up bias | `V_LOOK_UP_H` | int hundredths | 800 (8 px) | Grounded/cling jump-planning bias |
| Fall displacement | `D` | int hundredths | 0…9600 | Cumulative down-displacement while falling |
| Long-fall ref | `LONG_FALL_H` | int hundredths | 9600 (96 px) | D at which the bias completes |
| Look-down max | `LOOKDOWN_H` | int hundredths | 6400 (64 px) | Saturated falling bias |
| Vertical gain | `ALPHA_V_H` | int | 10 (tuning 6–20) | Convergence gain |

**Output Range:** bias ∈ [−800, +6400]; the falling ramp is exactly linear (⅔ px of bias per px fallen), saturating at D = 96 (held beyond by `min`); the vertical move reuses `MAX_STEP_H` (transiently binding only for fall speeds > 7.2 px/tick); no discontinuity at engage (bias starts ≈ 0 on the first falling tick and ramps continuously). **Example:** D = 48 → bias 32; D = 96 → 64; a fall from a cling with stale D is impossible (the reset covers it — fall → cling → jump-off re-enters falling from bias 0, never a slam).

#### F-CAM-05 · shake_decay — the envelope's execution (TR-CAM-014; completes SYS-29's F-JCE-09)

```
T = ceil(duration_ms × physics_tps ÷ 1000)            # 120 → 8 (133.3); 80 → 5 (83.3)
amp_px(t) = A0 − floor(t × A0 ÷ T),  t ∈ [0, T)       # whole px by construction
offset_axis(t) = ±amp_px(t)                           # sign per axis: core-owned xorshift seeded by request tick
rendered_axis = clampi(base_px + offset, center_min, center_max)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Request amplitude | `A0` | int px | 1…`SHAKE_MAX_PX` (3) | `ShakeRequest.magnitude_px` |
| Request duration | `duration_ms` | int ms | > 0 | `ShakeRequest.duration_ms` |
| Derived duration | `T` | int ticks | ceil(ms×60÷1000) | 120 → 8, 80 → 5 — never stingy |
| Tick index | `t` | int | 0…T−1 | Position in the envelope |
| Amplitude | `amp_px(t)` | int px | 1…A0 | Monotone nonincreasing; whole px by construction |

**Output Range:** `|offset| ≤ A0 ≤ 3` per axis; the envelope ends at amp ≥ 1 (no zero-amplitude tick); the xorshift **advances every tick even on a zero-travel axis** (replay determinism); shake composes on the emitted value only — `pos_h` is never mutated by the shake. **Examples:** clash 3/120 → `[3,3,3,2,2,2,1,1]`; lose 2/80 → `[2,2,2,1,1]`.

#### F-CAM-06 · hold_point — the framing zones' stage (TR-CAM-012/013)

```
zone_center = (rect.x + rect.w ÷ 2, rect.y + rect.h ÷ 2)     # floor (all pinned dims even → exact)
hold        = clamp(zone_center, center_min, center_max)     # the ROOM's F-CAM-01 range, per axis
frame       = [hold_x − 240, hold_x + 240] × [hold_y − 135, hold_y + 135]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Framing zone | `zone` | Rect2 (int px) | inside a room | The pinned zone (arena / `reveal_cistern` — SYS-02's `room_bounds_contract`) |
| Zone center | `zone_center` | int px ×2 | — | Rect center (floor-rounded) |
| Center range | `center_min/max` | int px | F-CAM-01 output | The **room's** clamp range, not the zone's |
| Hold point | `hold` | int px ×2 | inside center range | The camera center while holding |
| Frame | `frame` | Rect2 | inside room rect | The held view |

**Output Range:** hold is always inside the room's center range; by clamp construction the frame is always fully inside the room rect. **Examples:** the **arena** zone == RM-06's rect → hold **(3520, 176)** unclamped; frame x [3280, 3760] (80 px/side crop of 640), y [41, 311] (41 px top/bottom of 352); the staging band (16 px interior margin) x [3296, 3744] (448), y [57, 295] (238). **`reveal_cistern`** (1312,176,160,96) in RM-03 → center (1392, 224) clamped to **(1520, 137)** — the unclamped view's left edge (1152) would show 128 px of out-of-room void, eliminated by the clamp; the clamped frame x [1280, 1760], y [2, 272] contains the wing [1312, 1472]×[176, 272] (its bottom flush with the room floor — by design).

#### F-CAM-07 · perf_envelope — the seven-system sum (TR-CAM-017; the OQ-J2 pattern)

```
Σ p99.9 = 1.00 + 0.30 + 0.30 + 0.25 + 0.20 + 0.25 + 0.15 = 2.45 ms
Σ max   = 2.0 + 1.0 + 1.0 + 0.75 + 0.60 + 0.75 + 0.45    = 6.55 ms
        (SYS-01 · SYS-06 · SYS-08 · SYS-07 · SYS-29 · SYS-13 · SYS-32)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Per-system budgets | `p_i` / `m_i` | float ms | ≥ 0 | The seven systems' per-tick budgets (named in TR-CAM-017) |
| Envelope p99.9 | `Σp` | float ms | 2.45 | The OQ#19 family's fourth record (1.85/4.75 → 2.05/5.35 → 2.30/6.10 → 2.45/6.55) |
| Envelope max | `Σm` | float ms | 6.55 | Summed worst case |

**Output Range:** fixed sums, bounded by definition; the additive composition is the **allocation** — **the combined soak's measurement is the proof** (recorded for the QA-plan sync). **Example:** the partial sums reproduce the recorded milestones exactly (…+0.20 = 2.05, +0.25 = 2.30, +0.15 = 2.45).

## Edge Cases

*Format: If [condition] → [exact outcome]. [rationale where non-obvious.]*

### Bounds that lie

- **If the bounds-first assert fails at the commanded swap tick** (the new room's `RoomBounds` generation absent, stale, wrong-room or malformed) → the swap cannot complete: dev assert + telemetry, fail-loud; production defers the swap tick-by-tick, executing on the first tick the assert passes, the view staying inside the old room's limits (the every-tick no-straddle assert still holds; `on_screen` may read false; no re-anchor, no glide). The commanded tick is the *earliest* tick, not the exact one. [TR-CAM-004/011]
- **If a second `RoomBounds` publish lands mid-room** → same generation, identical rect: idempotent no-op (the port dedupes on generation). New generation mid-room: dev assert naming the regression; production **adopts** — limits re-derive via F-RWS-02, both clamps re-apply within the same tick, no swap, no glide, no snap; SYS-24's caps re-derive from the live publication (never cached). Same generation, different rect: a corrupt publish — rejected into the row above's path. [TR-CAM-006/015]

### Swaps under fire

- **If the swap commands while HOLD_ZONE is active** → the hold **force-exits as part of the swap action itself**, same tick: TR-CAM-011 runs, zone state cleared *including the FIFO queue*; SYS-14 re-commands for any new-room hold (unreachable in authored content — the arena seals). [TR-CAM-011/012]
- **If SYS-14's defeat release races the swap tick** → both orders converge to exactly one re-anchor: release-first = at most one tick of FOLLOW-from-rest inside the arena before the swap; swap-first = the release is a no-op (the hold already force-exited). No old-room frame publishes after the swap; no double ease. [TR-CAM-011/012]
- **If the swap commands mid-arc (REVEAL_HOLD)** → the true gate entry (TR-MOV-029) kills the arc and the glide mid-flight → FOLLOW **seeded at the current glide position, no snap, that tick** — the vanished arc-end cannot deadlock the camera. Any other mid-arc swap is **unreachable by construction** (the body is on SYS-02's scripted-move lock); the no-swap-during-arc dev assert is the defence-in-depth. [TR-CAM-013; TR-MOV-029]
- **If the swap tick arrives at the freeze/lock edges** → (a) *hit-stop spanning the commanded tick*: `advance_world()` runs zero times — the swap structurally cannot run; the freeze guard marks the deferral; the swap executes on the first unfrozen tick. (b) *a `body_busy` lock ending exactly on the swap tick*: `end_tick` is already tick-open (TR-MOV-033), the swap proceeds same tick — and **the re-anchor wins over the FSM resume** (lead neutral, vertical re-anchored; a held countdown survives the seam and re-commits through the ordinary window if the facing held). (c) *a hold command stamped the same tick as the swap*: zone state re-evaluates next tick — one tick of seeded FOLLOW publishes between the swap and the ease, by design. [TR-CAM-002/010/011; TR-MOV-033]

### When the world stops

- **If hit-stop starts mid-commit-countdown** → the count holds its value and resumes — never drops, never expires; no restart race exists (the facing cannot flip during the freeze — ADR §5's invariant), so resume counts the remainder to 9 and commits. [TR-CAM-002]
- **If hit-stop meets the holds** → mid-reveal-glide: the glide freezes mid-flight (the entire hold pipeline halts), the arc freezes on the same clock gate so *completes by the midpoint* is preserved in game-time (no deadline breach, no catch-up burst); the frozen frame still publishes every tick and still trembles (the shake is the one freeze-blind channel); resume continues tick-by-tick. Mid-HOLD_ZONE: nothing visible halts — the held frame is already still, the shake keeps trembling, release restores the identical hold (no re-ease). [TR-CAM-002/014/015]

### Death and the outside world

- **If death lands mid-look-down** → at the death lock's `start_tick` the offset target drops to 0 (eased) and the D counter resets (the knockback-family reset) — the look-down bias collapses with the offset; the camera converges onto the body and holds; the countdown dies permanently (no resume, no re-commit). [TR-CAM-010; F-CAM-04]
- **If death lands during HOLD_ZONE** → the hold is **untouched by death** (only a room swap force-exits a hold): the death lock plays inside the held frame, the stage point never moves; exit comes from SYS-14's release (boss reset) or the respawn swap (revive *is* the swap mechanism → force-exit) — both end in FOLLOW. [TR-CAM-012]
- **If a non-GAMEPLAY context arrives mid-hold** → the asymmetry is the spec: `REVEAL_HOLD` exits to FOLLOW seeded, no snap, on any non-GAMEPLAY context (the arc died on the context exit; no re-glide on resume; SYS-02 must re-request). `HOLD_ZONE` **persists** — the lock is SYS-14's game-clocked state and the fight freezes with the world; resume continues the identical hold. Principle: REVEAL_HOLD follows its arc's death; HOLD_ZONE follows the lock's lifecycle. [TR-CAM-002/013]
- **If the app blurs / lifecycle suspends** → zero ticks elapse — the state is bit-stable across the suspension: no catch-up, no wall-clock debt; the shake schedule freezes with the ticks and resumes mid-envelope. If the platform maps blur to a designed gate, the non-GAMEPLAY rules above apply — the camera has no blur-specific code and needs none. [TR-CAM-001/002]

### What the camera believes

- **If the `position` rider has not landed** (boot before the first publication; a tick whose BodyPort lacks a valid body-center) → **the camera never fabricates a position** — no zero-default, no spawn-guess. Dev: assert + telemetry (the missing-bounds pattern). Production: the camera **activates on the first tick carrying valid bounds ∧ valid position** — the unconditional publication binds *from activation*; before it, the boot frame is presentation's, not the camera's. After activation, a lost rider freezes the body-driven pipeline for that tick (bit-stable, like a freeze tick) while command-driven channels continue; consumers detect the stall via the `tick` field. [TR-CAM-006/015; the recorded rider]
- **If `facing` is absent at boot** → FOLLOW runs (position-driven) but the commit window stays idle — no proposal can form without a facing value; the first valid facing opens the ordinary 9-tick window from its arrival tick; boot frames are centered, zero offset. [TR-CAM-009]
- **If velocity is zero/garbled, or cling arrives with no toward-wall order** → consumed by **no camera law at MVP**: the falling tween is D-driven from published position deltas (a zero-velocity fall still tips the eye correctly), cling frames by the phase key alone (grounded/cling share the −8 bias, side-agnostic); the camera never reads a wall order — the wall state is published and reserved. [TR-CAM-006/007]
- **If two `body_busy` locks overlap** (SYS-06-impossible; the FSM's defensive answer) → the freeze applies while *any* level is active and ends when the *last* ends; the knockback-family drop fires at the family level's `start_tick` (a second family start re-fires onto an already-0 target — idempotent); `authority` publishes the top present class; the dev assert flags the single-active-level violation to SYS-06's telemetry. Deterministic even from a buggy FSM. [TR-CAM-010/015]

### The one slot

- **If a request arrives outside the contract** (context ≠ GAMEPLAY; magnitude > `SHAKE_MAX_PX`; magnitude 0) → three guards, one shape: non-GAMEPLAY — SYS-29 drops at source, a leak is rejected by the executor's context guard; over-cap — SYS-29 clamps at source, a leak is clamped to 3 by the executor (the clamp is SYS-32's authoritative act); zero — outside F-CAM-05's declared domain, rejected, not executed. All three: dev assert + telemetry, **no slot entry, no xorshift advance**. [TR-CAM-014; TR-JCE-026]
- **If a cancel arrives with no active request, or keyed to a foreign source** → no-op — the slot is source-keyed; a stray cancel cannot kill an active shake. **Same-tick self-cancel** → the cancel clears on the next physics tick by contract — exactly one decay step publishes, then the slot is clear; no intra-tick mutation path exists, so there is no ordering race to lose. [TR-CAM-014]
- **If a stronger request and the compose land on the same tick** → no race: the tick order is fixed — drain (ingest → replace-resolve) → advance → compose → publish. Strictly stronger same-tick: replaces before compose (it shakes *this* tick); equal: first-come keeps (the incumbent composes); weaker: dropped + telemetry without touching the compose. [TR-CAM-014; F-CAM-05]

### Honest frames

- **If a consumer reads the publication on the swap tick** → it publishes the **post-swap frame atomically** (the action completes pre-emit): one room's truth — no tick exists with new limits and an old position; band-relative coordinates carry no room identity (identity lives in `view_rect` + the bounds generation), so the entry "jump" is the re-anchor, correct by construction. [TR-CAM-011/015]
- **If a consumer reads during the reveal glide** → `on_screen` reports the truth per tick — she can sit at or past the frame edge (the hold point frames the wing, not her): a transient false is *designed behavior*, and the arc window is **threat-free** (TR-CAM-013's recorded duty — a transient-false frame contains no live strike, so the framed-zone guarantee holds); SYS-10/11 key on `active_hold`/the epoch, never on `on_screen`; SYS-24 derives from the live value, never cached. [TR-CAM-013/015; F-CAM-06]
- **If the hold announcement arrives before the glide completes** → `active_hold` publishes from the arc-start tick through glide and hold alike (`start_tick` = the command's tick): SYS-10/11 stage the truth-flip against the *announced* hold while the frame is still traveling — nobody infers hold state from motion. [TR-CAM-015]

### The law's teeth

- **If a fractional px write or an inverted limit arrives** → fractional write: the ports quantize at the boundary; an *internal* fractional write trips the dev assert and is rejected (the hundredths accumulator is the only fractional carrier). Limit inversion: impossible from valid input — F-CAM-01's construction cannot invert; an inverted result means a garbled rect, failing validation into the missing-bounds path. Both asserts name the offending source. `pos`'s invariant is the **clamp domain** (`pos ∈ [center_min, center_max] × 100` per axis — origin-agnostic; the MVP room set is positive-origin, VS rooms with negative origins drive `pos`/`view_rect` legally negative, with floor-div emit semantics flagged for VS). [TR-CAM-003; F-CAM-01]

### Shape classes

- **If she lands after a fall — RM-01 (2 px vertical travel)** → the falling→grounded retarget clamps to ≤ 2 px and the clamp does **not** swallow it: 200 h; the mover steps 36→29→24→19→16→13→11→9 h (gap 43 ≤ 50 → snap) — emitted schedule `0,0,0,1,1,1,1,2` across ticks 1–8: first visible move ≈ 4 ticks (~67 ms) after touchdown, the final pixel lands by the stop-snap at ≈ tick 8 (~130 ms). **Not a sub-pixel ripple and not a no-op** — the full 2 px always arrives (termination by snap, never by stall). The instant-write alternative (a direct 2-px exception for span ≤ 2 px axes) is a recorded tuning note, not the rule. [TR-CAM-006; F-CAM-02]
- **If she lands after a fall — RM-04/06 (82 px travel)** → a D ≥ 88 touchdown carries the ~72 px falling→grounded retarget: one capped first tick, then the ×0.82 tail; the stop-snap completes ≈ 26 ticks (~0.43 s), the visible re-anchor reading settled in ~0.25–0.3 s. The travel band is what makes this class visible where RM-01's clamp hides it. [TR-CAM-006/008; F-CAM-02]

### Degenerate strategies — named and shut down

- **"Countdown weaning"** (baiting the commit delay both ways to peek without committing) → shut down by the restart rule: every proposal change restarts the 9-tick count and the countdown places *nothing* until it completes — oscillation accumulates zero lead, forever. The single-direction committed lead past a corner is the design, not a leak: paid at 150 ms, bounded at 32 px, symmetric — turning to read behind her spends the same budget the other way (there is no manual-look verb; this *is* the look-back). [TR-CAM-009]
- **"Pit scouting from the ledge"** → structurally closed: no grounded look-down exists — the eye tips only while falling (the grounded/cling bias points *up*), so the pit's depth is revealed only once she has committed to the drop; the whole-fall presentation is the compensation, not a leak. [TR-CAM-007/008]
- **"Hiding in the arena's side strips"** → an authored-reachable strip is an **authoring defect against the staging-band duty** (TR-CAM-012: the band covers every fight participant and threat effect, and the player's reachable space is sealed to it) — not a designed state; the arena seals and both fighters stay inside the held interior. The robustness path remains: if content ever violates the band, `on_screen = false` keeps the publication honest (blind to the fight she is hiding in) and the follow-clamped fallback is one knob away. [TR-CAM-012; F-CAM-06]
- **"Shake sonar"** (reading hidden state off the tremble) → no channel exists: the MVP envelope is the clash family only — three fixed pairs firing on exchanges she participated in; hits taken produce no shake; class-fixed magnitudes carry no analog information; the xorshift's replay-fixed sign pattern is cosmetics with zero state. [TR-CAM-014; F-CAM-05]

### Value and config extremes

**Knob validation law (V-CAM).** Every knob value is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry; dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-CAM-01 | every knob within its safe range (Tuning Knobs' table) | clamp + telemetry | the house law |
| V-CAM-02 | `LONG_FALL_PX ≤ 128` ∧ `LOOKDOWN_PX ≤ 96` | clamp | the engagement must precede frame-exit (~135 px); the bias cap ≤ 35% of the view |
| V-CAM-03 | `ALPHA_H_H ∈ [10, 30]` ∧ `ALPHA_V_H ∈ [6, 20]` | clamp | slower than 10 reads as lag; faster than 30 reads as twitch |
| V-CAM-04 | `COMMIT_DELAY_MS ∈ [80, 250]` | clamp | below 80: turn-dancing commits; above 250: the read starves |
| V-CAM-05 | `LOOKAHEAD_PX ∈ [24, 48]` | clamp | < 24 unreadable at this art scale; ≥ 68 the frame leads her |
| V-CAM-06 | F-CAM-07's sum equals the recorded envelope value | re-derive the sum on any budget change (never silent) | the OQ-J2 pattern's bookkeeping |
| V-CAM-07 | every executed shake ≤ `SHAKE_MAX_PX` (SYS-29's 3) | clamp at the executor | defence in depth over the source clamp |
| V-CAM-08 | `VIEW_W`/`VIEW_H` even (the integer halves) | dev boot failure | the centered/hold math derives from integer halves |

## Dependencies

**Upstream: SYS-02 (HARD — the bounds are the frame's word; the camera cannot exist in a room without its rect), SYS-06 (HARD at runtime — the follow's input, plus the recorded `position` rider), SYS-01 + ADR-0001 (HARD build-time — the D1 rig is the render substrate). SYS-29 is a soft input feed (the executor is inert without requests). The downstream consumers are soft — the camera works without them; they consume it.**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream | **SYS-01 Input + ADR-0001** | **Hard (build-time)** | In: 480×270 art metrics + the safe-derived integer `k` (via data, at boot/resize) · Out: the integer view rect (placement for the SubViewport) | UNFROZEN (#10); ADR-0001 **Accepted 2026-11-12** — the D1 render model is binding (§9) |
| Upstream | **SYS-02 Room & World Structure** | **Hard** | In: `RoomBounds {room_id, rect_px, spawn_anchors, framing_zones}` (atomic, pre-first-tick, generation-stamped) · the reveal arc-start/end commands · the commanded swap tick · Out: nothing (SYS-32 never writes bounds, never derives zone triggers, never owns arc constants) | **APPROVED 2026-11-13** — the bounds contract is ratified there |
| Upstream | **SYS-06 Movement** | **Hard (runtime)** | In: position (**the recorded TR-MOV-028 rider** — before the first camera story), velocity, grounded, facing, wall state (reserved), body_busy lock levels, hop/knockback events, `logic_running` · Out: nothing | APPROVED 2026-11-12 — the rider is the one open clause |
| Input feed | **SYS-29 Juice & Feedback** | Soft | In: `ShakeRequest {magnitude_px, duration_ms, source, tick}` + the cancel variant · Out: nothing (no camera writes in JuiceCore — the static audit is SYS-29's AC-JCE-30) | APPROVED 2026-11-13 — F-CAM-05 completes F-JCE-09 |
| Downstream | **SYS-24 HUD** | Soft | Out: `player_screen_px` (int art px, band-relative, post-clamp, pre-shake), `on_screen`, view rect — every physics tick · In: nothing (SYS-24 owns interpretation; never caches) | Not Started — the thumb-coverage caps' input |
| Downstream | **SYS-14 Grief-Boss** | Soft | Out: the arena hold (commands in, `active_hold` out); the staging-band constraint (SYS-14's authoring duty) · In: lock/release commands | Not Started — the Denial arena framing zone is the MVP's lock |
| Downstream | **SYS-10 / SYS-11** | Soft | Out: hold announcements + per-tick `active_hold` (truth-flip staging; reveal-seam sync) · In: nothing | Not Started — the truth flip needs no camera mode; the reveal hold is SYS-02's arc |
| Downstream | **SYS-04 Audio** | None | No audio edges at MVP | Not Started |

**Explicit non-dependencies:** SYS-03 Save (the camera is stateless across sessions — every frame is derived from live publications; nothing to persist) · SYS-05 Game Flow (contexts are consumed through the clock's `logic_running`, never directly) · SYS-08 Combat (its commitments ride `body_busy` — no direct edge) · SYS-13 (nothing direct) · SYS-12 (VS) · SYS-16/17/18/19/20/21 (none) · SYS-25/26/27/28 (none).

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) **SYS-32's row** gains the GDD path, the counts, the pinned values and the envelope entry (0.15/0.45 → the seven-system 2.45/6.55); (2) **SYS-06's row** gains the recorded TR-MOV-028 `position` rider (the OQ-M1 pattern — before the first camera story); (3) **SYS-29's row** gains the F-CAM-05 completion note (the offset/decay shape is now specified); (4) **SYS-02's row** gains the arena-consumer-contract note (OQ-RWS-8 stated in SYS-32's Interactions: SYS-14 commands, SYS-32 holds); (5) **SYS-24's row** gains the publication-law note (per-tick live reads, never cached).

## Tuning Knobs

**All camera knobs are designer-only at MVP.** The camera adds no settings surface — it reads no input, and the player-facing shake toggle (`SCREEN_SHAKE`) and `REDUCED_FLASH` are SYS-29's/SYS-24's. Every ms knob converts by the `ms_to_ticks` ceil family (F-CAM-03's law); a rate change re-derives every tick figure. The V-CAM validation law (Edge Cases) governs every value.

| Knob | Default | Safe range | Why the bounds (feel notes) | Rule |
|---|---|---|---|---|
| `LOOKAHEAD_PX` | 32 | 24–48 | < 24 unreadable at this art scale (a 16-px tile is invisible as a lead); ≥ 68 the frame *leads* her; the 32-px swing's visible settle completes by ~tick 18 (F-CAM-02) | TR-CAM-009 |
| `COMMIT_DELAY_MS` | 150 | 80–250 | < 80: turn-dancing commits; > 250: the read starves; 9 ticks exact at 60 tps | TR-CAM-009; F-CAM-03 |
| `ALPHA_H_H` | 18 | 10–30 | at 10 the 32-px swing takes ≈ 41 ticks (≈ 683 ms — laggy); at 30 ≈ 12 ticks (≈ 200 ms — twitch-coded); 18 → visible settle ≈ 300 ms | TR-CAM-006; F-CAM-02 |
| `MAX_STEP_H` | 1200 | 800–2000 | the cap binds only on large retargets (gaps ≥ 66.67 px); below 800 long-fall landings crawl; above 2000 the cap stops protecting the settle | TR-CAM-006; F-CAM-02 |
| `SNAP_EPS_H` | 50 | 30–80 | below 30 the sub-pixel crawl lengthens; above 80 the snap becomes a visible pop | TR-CAM-003; F-CAM-02 |
| `ALPHA_V_H` | 10 | 6–20 | the ground's schedule — deliberately heavier than horizontal; 20 makes landings pop | TR-CAM-007; F-CAM-04 |
| `V_LOOK_UP_PX` | 8 | 0–16 | the jump-planning bias; 0 hides the apex read on tall rooms; 16 floats the frame off the ground's schedule | TR-CAM-007; F-CAM-04 |
| `LONG_FALL_PX` | 96 | 64–128 | < 64: the eye tips on ordinary hops; > 128: the engagement arrives after frame-sink (~135 px) | TR-CAM-008; F-CAM-04; V-CAM-02 |
| `LOOKDOWN_PX` | 64 | 32–96 | < 32: the tip is invisible; > 96: she leaves the upper frame during the fall | TR-CAM-008; F-CAM-04; V-CAM-02 |
| `HOLD_EASE_MS` | 400 | 250–700 | the arena entry ease, masked by the boss-intro beat; < 250 reads as a snap onto the stage; > 700 the duel starts before the stage settles | TR-CAM-012 |

**Cross-system inputs (consumed at registration — not SYS-32 knobs, but validated by SYS-32):** `VIEW_W`/`VIEW_H` 480/270 (SYS-01's D1 metrics — V-CAM-08's evenness) · the safe-derived integer `k` (SYS-01's) · `SHAKE_MAX_PX` 3 + the envelope table 3/120, 3/120, 2/80 (SYS-29's — SYS-32 re-asserts the cap, never owns the values) · `DOOR_OPEN_MS`/`REVEAL_ARC_MS` 700 (SYS-02's — the arc commands carry their own timing) · the room rects + framing zones (SYS-02's data) · the body publications + `logic_running` (SYS-06's/SYS-29's clock) · `physics_tps` (engine). A missing or invalid cross-system input is a dev boot failure, never a silent default.

**Not knobs (documented so nobody adds them):** the D1 law itself (zoom is never a knob — its absence is the design; the recorded VS zoom-spike note routes through the FocusPort seam only) · manual look (the eight-verb closure — no verb exists to tune) · the shake envelope's values and `SHAKE_MAX_PX` (SYS-29's) · the decay schedule's shape (the even-step law is identity, not preference) · the hold points (3520,176)/(1520,137) (derived by F-CAM-06, never tuned) · the staging band (derived from the frame) · the envelope row 0.15/0.45 (the allocation is the QA soak's instrument — V-CAM-06's identity, not a feel dial) · the room rects and framing zones (SYS-02's data).

**Recorded tuning note:** the RM-01 instant-write alternative (a direct 2-px exception for span ≤ 2 px axes) — one line if shallow-room landings should feel instant; playtest owns the call.

**Provisional lifetimes:** every feel knob in the table (playtest — the working plan's "playtest-tunable" clause) · `MAX_STEP_H`/`SNAP_EPS_H` (implementation-feel; playtest-secondarily) · the arena/reveal hold timing (SYS-02's/SYS-14's constants — OQ-RWS-1; SYS-32 mints none).

## Visual/Audio Requirements

*(Behavior-level — the camera renders nothing: no assets, no VFX, no audio of its own. What it owns are **integrity rules** — the conditions under which everyone else's art reads honestly through the frame. The technical-artist seat's rules are folded here; the art bible ratifies the hex-level surface.)*

- **The whole-art-pixel rule (the D1 law's visual justification).** A fractional camera placement displaces texels by k×f physical px: at k=1 a speed ripple and 1-px crawl on diagonals; at k=2 "fat pixels" (texel blocks alternating 1/3 px wide) and irregular 2-px crawl; at k=3 a visibly ragged pixel grid that reads as glitching. With linear filtering the same misregistration shows as blur. **Pin: nearest filtering on the world upscale; the camera math's integer law is the enforcement; the renderer's pixel-snap settings are failsafe only (PR-CAM-05's evidence demonstrates the artifact the law prevents).**
- **The room-swap hard cut.** A cross-room glide drags two palettes through one frame — a rendering error's read. The cut is the medium's native transition language: *the camera may be discontinuous only at room boundaries; inside a room it is whole-px continuous.* No crossfade, no extra composite, no camera-owned transition VFX (SYS-09/10 own the flip's drama; SYS-02's arc timing owns the door-frame mask).
- **The shake's visual language.** ≤ 3 px whole-px offsets, even-step linear decay (3→2→1→0), read as **impact — a world shudder, not a glitch** (SYS-29's glitch vocabulary — larger offsets, RGB-split, scanline — stays clearly separate); the asymmetric tremble at a wall is honesty, not a defect. Implementation watch (not a law): the axis-crossing tail (one axis reaching 0 first; both axes flipping in lockstep) — phase-offset the sign patterns if it reads as crawl at playtest. The quantization audit is PR-CAM-08's (0 subpixel frames; even steps).
- **The reveal hold's composition.** The held frame puts the wing left-of-center-bottom (hold point (1520, 137), the clamp load-bearing) and her entry reads as an invitation — the frame never moves to meet her. No camera-owned fade, sting, or emphasis: SYS-09/10 own the flip's presentation; the hold is the frame's only statement.
- **The arena stage.** The fixed single-screen duel read (the OoE pattern): no camera-owned intro/outro, no drift, no re-ease after release-return; SYS-14 owns the boss-intro presentation; the staging band is the level-design's composition duty.
- **Translate-only camera.** No screen-space rotation, no zoom, no motion blur — ever (the a11y vection guardrail; also the integer-scale law). If the art pass introduces parallax, far layers ≤ 0.3 factor and minimal vertical parallax (the vection source the camera doesn't own) — routed to the art bible (OQ-CAM-5).
- **Audio:** none authored by SYS-32 at MVP. No camera edges exist in SYS-04's closed list; the shake rides SYS-29's clash-family edges (SYS-04's designs), never a camera sound.

**No Asset Spec flag** — the camera authors no assets (procedural math only); `/asset-spec` has nothing to produce for SYS-32.

## UI Requirements

**None of its own.** The camera has no screen, menu or HUD element. Its publication (`player_screen_px`, `on_screen`, view rect — every physics tick, post-clamp, pre-shake) is **SYS-24's input** for the thumb-coverage caps: SYS-24 derives the caps only from the live published value — never world position, never cached reads (world-still ≠ screen-still during a hold pan); the conversion from art px to native dp geometry is SYS-24's (via SYS-01's `RenderMetrics`). The player-facing shake/flash toggles are SYS-29's contract rendered by SYS-24's Recalibration surface. **No UX flag** — no new screen, flow or HUD geometry is authored here.

## Acceptance Criteria

Coverage: **17 TR-CAM rules · 7 formulas · 8 V-CAM invariants · 8 probe items · 31 ACs · 5 playtest codes · 8 OQs**. Tags: `[GUT]` automatable in Godot Unit Test over the injected ports · `[DEVICE]` on-device QA (the device matrix) · `[PLAYTEST]` human feel observation with the coded rubric.

### The core laws

- **AC-CAM-01** [GUT] *(TR-CAM-001)* — **GIVEN** `CameraCore` with the fake ports, **WHEN** the purity audit runs, **THEN** the audit finds zero `Input`/`SceneTree`/`Time`/`RenderingServer`/`Camera2D` symbols in the core (the five forbidden), the same scripted fixture run twice yields **bit-identical traces** on the named comparison surface (the 256-entry trace ring + the published field stream), and the core instantiates over fakes without a node.
- **AC-CAM-02** [GUT] *(TR-CAM-002; PR-CAM-03's negative)* — **GIVEN** a 6-tick hit-stop raised mid-follow, **WHEN** the frozen ticks run, **THEN** TR-CAM-002's five-item pipeline (position, look-ahead FSM, commit countdown, vertical state, hold evaluation) is **bit-stable** across the freeze (the shake channel legitimately continues — freeze-blind), the countdown survives and resumes to 9 without dropping, resume closes the gap by normal convergence (no teleport, no catch-up), a pause/gate steps nothing, an app-blur suspension elapses zero ticks with bit-stable state and the shake resuming mid-envelope, and a config assert pins `position_smoothing_enabled = false` (zero render-frame drift during the hold — PR-CAM-03's verification-of-the-negative).
- **AC-CAM-03** [GUT] *(TR-CAM-003/006, F-CAM-02)* — **GIVEN** the full 32-px commit swing (gap 3200 h), **WHEN** the floor trace runs, **THEN** every emitted position is a whole art px, the emitted px stops changing at tick 18 and the stop-snap completes at tick 22 (post-move check; ≈ 367 ms), the cap binds exactly at gaps ≥ 6667 h (6667 × 18 ÷ 100 = 1200), a fractional write attempt trips the dev assert (the hundredths accumulator is the only fractional carrier), and `zoom` is constant `(k, k)` at every tick (the never-zooms clause, asserted).
- **AC-CAM-04** [GUT] *(TR-CAM-004/005, F-CAM-01)* — **GIVEN** each room's bounds, **WHEN** the center range derives, **THEN** the worked rows hold exactly (RM-01 x [400, 400], y [135, 137]; RM-02 x [880, 1040], y [135, 137]; RM-06 x [3440, 3600], y [135, 217]), the centered alcove fixture yields span == view with the `floor(slack ÷ 2)` extension and a zero-travel axis (lead, hold and shake all collapse to the fixed center on it), and **the dev half** of missing bounds is the fail-loud assert + telemetry (AC-CAM-18 owns the production deferral — cited, not duplicated).
- **AC-CAM-05** [GUT] *(TR-CAM-006)* — **GIVEN** a retarget, **WHEN** the follow integrates, **THEN** the approach is monotone with both target-side and emitted-side clamps, termination is by snap never stall (`move = 0` only at gap ≤ 5 h), and the target consumes **only this tick's publications** — a stale publication tick produces no motion (no extrapolation between ticks, ever).
- **AC-CAM-06** [GUT] *(TR-CAM-007, F-CAM-04)* — **GIVEN** the vertical phases, **WHEN** each runs, **THEN** grounded/cling bias is −800 (8 px above the anchor), rising targets center, the falling ramp yields D = 48 → 32 and D = 96 → 64 (held beyond by `min`), landing merges with the already-converged tween (never a stack), the engage is continuous (bias ≈ 0 on the first falling tick — no discontinuity), and zero/garbled velocity plus cling-without-toward-wall-order are consumed by no camera law (the tween is D-driven from position deltas; cling shares the −8 bias, side-agnostic — the wall state is published and reserved).
- **AC-CAM-07** [GUT] *(TR-CAM-008, F-CAM-04)* — **GIVEN** the D counter, **WHEN** the reset events fire, **THEN** D resets on any grounded tick, any non-falling entry (rising, cling), and the knockback-family lock's `start_tick` (death's reset rides AC-CAM-09's death clause); the saturation is held explicitly (D ≥ 96 ⇒ bias 64); a shallow room (RM-01/02/03) clamps the law to a no-op.
- **AC-CAM-08** [GUT] *(TR-CAM-009, F-CAM-03)* — **GIVEN** a facing flip at T, **WHEN** the commit window runs, **THEN** the commit flag raises at **T+9** (9 elapsed ticks = 150.0 ms; 10 tick-instants counting the flip tick), a proposal change restarts the countdown and **oscillation accumulates zero lead, forever** (the R→L→R fixture — the weaning shutdown asserted), stopping never un-commits, and the law is cause-blind (a `WALL_TURN` re-commits after the delay with zero wall-specific code; a `KNOCKBACK`-caused facing flip's window opens only after the lock releases).
- **AC-CAM-09** [GUT] *(TR-CAM-010; F-CAM-04)* — **GIVEN** every `body_busy` lock class, **WHEN** each runs, **THEN** the FSM holds its state verbatim through the lock (the dash case invisible by construction), the knockback/knockdown family drops the offset target to 0 at `start_tick` (eased; death's D-reset included — the edge row's knockback-family reset), resume is never a drop (the tick-open snapshot at `end_tick` is already free), death is the terminal member (the camera holds on the body; the countdown dies permanently), and the **overlapping-locks defensive answer** holds (freeze while any level is active, end when the last ends; a second family start re-fires onto an already-0 target — idempotent; the dev assert flags the single-active violation to SYS-06's telemetry).
- **AC-CAM-10** [GUT] *(TR-CAM-011; PR-CAM-02/07's negatives)* — **GIVEN** the commanded swap tick, **WHEN** the sequence runs, **THEN** the bounds-first assert gates it, the limits swap + target re-anchor + glide-kill complete in the same tick (`pos = target` exactly, residual zeroed — no tick exists with new limits and an old position), the every-tick no-straddle assert holds, the freeze guard defers the swap to the first unfrozen tick when hit-stop spans the commanded tick, a lock ending exactly on the swap tick sees the **re-anchor win over the FSM resume**, the camera node is persistent across rooms, and a config assert pins `limit_smoothed = false` ∧ `drag_enabled = false` (PR-CAM-02's verification-of-the-negative).
- **AC-CAM-11** [GUT] *(TR-CAM-012, F-CAM-06)* — **GIVEN** SYS-14's arena lock command, **WHEN** the hold runs, **THEN** the ease completes by **tick 24** (ceil(400 × 60 ÷ 1000)) reaching exactly **(3520, 176)** and holds at zero motion thereafter (the ease's shape is unpinned — completion + final point are the oracle), follow/look-ahead/vertical are suspended while shake still applies clamped, the staging-band data check passes (**every fight participant's authored position and threat-effect extent inside x [3296, 3744] × y [57, 295]** — the boss anchor, both fighters, projectiles, hazards — and the player's reachable space sealed to the band), release returns to FOLLOW from rest, queued locks FIFO, a swap force-exits the hold (including the FIFO queue), SYS-14's defeat-release racing the swap tick converges to exactly one re-anchor, **death in the hold is untouched** (the stage point never moves; exit via release or the respawn swap), a non-GAMEPLAY context mid-hold **persists bit-stably** (resume continues the identical hold, no re-ease), a hold command stamped the swap tick publishes one seeded-FOLLOW tick before the ease, a spawn inside the arena zone re-locks next tick, and a reachable side strip is an authoring defect against the band (the robustness path: `on_screen = false` publishes honestly).
- **AC-CAM-12** [GUT] *(TR-CAM-013, F-CAM-06)* — **GIVEN** SYS-02's reveal arc-start command, **WHEN** the arc runs (42 ticks at the authored 700 ms), **THEN** the glide completes by the arc's midpoint (≤ 21 ticks) at exactly **(1520, 137)** (the 128-px-void clamp — the unclamped left edge 1152 < 1280), the wing [1312, 1472] × [176, 272] sits inside the held frame, emission stays whole-px per tick through the glide, no swap occurs at any arc point (the dev assert), the arc-end command returns to FOLLOW riding the follow law, a true gate mid-arc exits seeded with no snap (the vanished arc-end cannot deadlock), the **arc window's threat-free data check** passes (no spawn entry, no hazard rect intersecting the arc's path — the recorded SYS-02 duty), and a static grep finds **no SYS-32-owned arc/reveal constant** (the no-competing-constants audit).
- **AC-CAM-13** [GUT] *(TR-CAM-014, F-CAM-05)* — **GIVEN** the clash-family envelope, **WHEN** each request executes, **THEN** 3/120 → `[3,3,3,2,2,2,1,1]` and 2/80 → `[2,2,2,1,1]` (whole px by construction), the slot policy holds (strictly stronger replaces; equal keeps first-come; weaker dropped + telemetry), the cancel clears on the next physics tick, a foreign-keyed cancel is a no-op (a stray cancel cannot kill an active shake), the sign pattern is replay-deterministic (core-owned xorshift seeded by the request tick), a zero-travel axis collapses the offset while the xorshift still advances, and the executor decays **through** a hit-stop (freeze-blind).
- **AC-CAM-14** [GUT] *(TR-CAM-014; PR-CAM-04's negative)* — **GIVEN** the compose step, **WHEN** the offset applies, **THEN** `clampi(base_px + offset, center_min, center_max)` per axis yields the asymmetric tremble at a wall and never out-of-room, a request > 3 is clamped to 3 and magnitude 0 rejected (no slot entry, no xorshift advance), a non-GAMEPLAY leak is rejected by the executor's context guard (the third guard), the fixed tick order holds (drain → advance → compose → publish; a strictly stronger same-tick request shakes *this* tick), and a config assert pins engine `offset ≡ 0` (the shake composes pre-clamp in the position math — PR-CAM-04's verification-of-the-negative).
- **AC-CAM-15** [GUT] *(TR-CAM-015; Transition law 4)* — **GIVEN** any tick (frozen, holding, gliding, swapped), **WHEN** the publication runs, **THEN** it publishes **every physics tick unconditionally** with exactly the 8 fields `{mode, view_rect_px, player_screen_px, on_screen, authority, shake_offset_px, active_hold, tick}`, `player_screen_px` is post-clamp **pre-shake**, the swap tick publishes the post-swap frame atomically (one room's truth), `active_hold` publishes from the arc-start tick through glide and hold alike, `on_screen`'s transient false during the glide is designed behavior (SYS-10/11 key on `active_hold`, never on `on_screen`), the **authority ladder fixture** presents each class and asserts the published top (hit-stop > knockback-family > freeze > vertical > commit > base), and the no-write-back audit finds no consumer write path.
- **AC-CAM-16** [GUT] *(TR-CAM-016)* — **GIVEN** the shipped camera, **WHEN** the audits run, **THEN** the FocusPort signature exists in the type surface with **zero writers** at MVP, and a grep finds no `SCREEN_SHAKE`/`REDUCED_FLASH` settings symbol in the camera (no settings knowledge — the toggles are SYS-29's contract, SYS-24's surface).
- **AC-CAM-17** [GUT] *(TR-CAM-017, F-CAM-07)* — **GIVEN** the CI soak harness (the workload's W-number assigned at the QA-plan sync, OQ-CAM-8), **WHEN** the 10,000-tick soak runs headless, **THEN** the harness completes, the allocation audit reports heap growth ≤ 256 KB and net allocation delta 0 (the state structs, the trace ring 256, the shake slot preallocated), the **envelope identity** re-derives (2.45 / 6.55 = the recorded seven-system sum per V-CAM-06), and the CI W-number is recorded for regression tracking — **the SKU-timed enforcement (p99.9 ≤ 0.15 / max ≤ 0.45 on the reference SKU) is AC-CAM-23's** (a CI number cannot prove a SKU budget; the gate home is fixed by this GDD, one clause for the QA-plan sync to confirm).
- **AC-CAM-18** [GUT] *(TR-CAM-004/011; the bounds edge rows)* — **GIVEN** the bounds fault fixtures, **WHEN** each runs, **THEN** missing/stale/wrong-room/malformed bounds fail loud in dev (the assert names the offending source) and **production defers the swap tick-by-tick, executing on the first tick the assert passes with the view inside the old room's limits throughout** (the every-tick no-straddle assert holds; `on_screen` may read false; no re-anchor, no glide), a mid-room republish with a new generation is adopted (limits re-derive, both clamps re-apply, same tick, no glide) and identical-rect same-generation is an idempotent no-op, a corrupt publish is rejected into the missing-bounds path, and an **inverted limit** (impossible from valid input — F-CAM-01's construction) fails validation into that same path.
- **AC-CAM-19** [GUT] *(V-CAM-01…08)* — **GIVEN** each knob at its extremes, **WHEN** config validation runs, **THEN** single-knob invariants clamp with rate-limited telemetry, the two dev-boot-failure rows fire (V-CAM-08's odd view dims; the cross-system-input row — a missing/invalid `VIEW_W/H`, `SHAKE_MAX_PX`, arc timing, room rect, publication or `physics_tps`), and the envelope identity is re-derived on any budget change (never silent).
- **AC-CAM-20** [GUT] *(TR-CAM-006/015; the activation gate)* — **GIVEN** boot before the first valid publication, **WHEN** the camera starts, **THEN** it **never fabricates a position** (no zero-default, no spawn-guess), it activates on the first tick carrying valid bounds ∧ valid position with **zero camera publications before activation** and every-physics-tick publication from it, a lost rider after activation freezes the body-driven pipeline for that tick (bit-stable, like a freeze tick) while command-driven channels continue, and **facing absent at boot** leaves FOLLOW position-driven with the commit window idle (the first valid facing opens the ordinary 9-tick window; boot frames centered, zero offset).
- **AC-CAM-21** [GUT] *(TR-CAM-006/008; F-CAM-02)* — **GIVEN** the shape-class fixtures, **WHEN** the landings run, **THEN** RM-01's 2-px retarget emits exactly `0, 0, 0, 1, 1, 1, 1, 2` across ticks 1–8 (first visible move at tick 4; the final pixel by the stop-snap; rounding pinned floor — not approximately), and RM-04/06's 82-px-travel landing from D ≥ 88 takes one capped first tick then the ×0.82 tail with the snap at tick 26 — the exact sequences asserted, no tolerance.
- **AC-CAM-22** [GUT] *(the traceability audit — no TR of its own, the AC-RWS-27/AC-ENM-19 pattern)* — **GIVEN** the TR-CAM registry, **WHEN** the audit runs, **THEN** the citation map is **produced mechanically from the AC headers** (not hand-authored): 001→01 · 002→02 · 003→03 · 004→04/18 · 005→04 · 006→03/05/20 · 007→06 · 008→07/21 · 009→08 · 010→09 · 011→10/18 · 012→11 · 013→12 · 014→13/14 · 015→15/20 · 016→16 · 017→17; the formulas F-CAM-01→04 · 02→03/05/21 · 03→08 · 04→06/07 · 05→13/14 · 06→11/12 · 07→17/19; the counts asserted: **17 TR-CAM / 7 F-CAM / 8 V-CAM / 8 PR-CAM / 31 ACs (22+4+5+0)**; every PR-CAM gate reference resolves (01/05→24 · 02→10 · 03→02 · 04→14 · 06→23 · 07→10/24 · 08→24/25) and every Consumed-Contracts Ratification row is cited by ≥ 1 AC; and no `[To be designed]` exists anywhere in this file.

### Device

- **AC-CAM-23** [DEVICE] *(TR-CAM-017; PR-CAM-06; OQ-CAM-8)* — **GIVEN** the S0–S4 scripted workload on the reference SKU (the mapping artifact: S0 still room · S1 the 24-transition tour · S2 the long fall · S3 the arena fight · S4 the shake storm), **WHEN** the device pass runs, **THEN** per-tier frame time p95 ≤ 16.6 ms at that tier's ship k with p99 ≤ 25 ms and ≤ 1 such frame per 2 s, the tour drops < 0.5% of frames with ≤ 1 dropped frame per 3 transitions, the shake storm never drops 2 consecutive frames and never stalls > 33 ms, draw calls stay ≤ 150 in S3, render-target switches stay ≤ 3 constant across all states, the world↔HUD composite shows **0-frame skew** (the same tick's world sprite and HUD marker in the same captured frame), and SYS-32's per-tick budget holds on the SKU: **p99.9 ≤ 0.15 ms / max ≤ 0.45 ms**. *(The unratified thresholds — the 0.5%/1-per-3/33 ms/RT-switch/p95 numbers — record their ratification point here: the QA-plan sync, OQ-CAM-8; the ≤ 150 draw-call bar is the project's pinned budget.)*
- **AC-CAM-24** [DEVICE] *(PR-CAM-01/05/07)* — **GIVEN** the pixel-integrity captures at every admissible ship k (the register's k ∈ {1,2,3,4}; the MVP ship set is a subset), **WHEN** each capture compares, **THEN** the authored-offset vs camera-offset renders are pixel-identical at integral positions, the fractional-position shimmer is demonstrated (the artifact evidence for the law), zero straddle frames exist across the swap on device, zero subpixel frames exist in any capture, PR-CAM-01's in-engine halves hold (the next-frame hard clamp at every edge; the centered span==view and rect-exact span>view branches hold in-engine, not just in the math), and the translate-only transform is asserted across every capture (`zoom (k,k)` constant, rotation 0, no motion blur).
- **AC-CAM-25** [DEVICE] *(PR-CAM-08)* — **GIVEN** the S4 shake-storm capture, **WHEN** the frame-step review runs, **THEN** every rendered offset is an integer (offset ∈ ℤ), the per-axis decay deltas are ∈ {0, −1} (the even-step schedule), and the axis-crossing tail treatment is **signed off jointly with SYS-29** (the implementation watch's deliverable).
- **AC-CAM-26** [DEVICE] *(TR-CAM-002/012/013; the comfort telemetry)* — **GIVEN** the full playtest build's telemetry, **WHEN** the sessions run, **THEN** zero hard cuts exist outside the swap action (no 1-tick camera displacement > 24 art px — 2× the 12 px/tick step cap's headroom), and **game-caused motion meets the recorded velocity-envelope oracle**: the authored moves' computed envelopes are the arena ease (≤ 160 px of travel over 24 ticks) and the reveal glide (≤ 128 px over ≤ 21 ticks) — the motion-parity caps for *non-authored* (player-uncased) motion are **ratified at the QA-plan sync / SYS-24's authoring** against these envelopes (the values are not asserted unpinned here).

### Feel and playtest (MVP-lock — the coded rubric)

The playtest set runs the SYS-01 AC-63 protocol: **≥ 5 mixed-rig testers with ≥ 30-min sessions**, two facilitators coding independently, **≥ 90 % per-statement agreement and Cohen's κ ≥ 0.7 required before any code is scored**. A code **passes** when ≥ 3 of 5 testers' transcripts contain ≥ 1 in-code token and the anti-code appears in < 3 transcripts (an anti-code majority fails the code outright).

- **AC-CAM-27** [PLAYTEST] *(P1 — the-eye-unseen)* — elicitor: *"Tell me about how the view moved — did it ever work against you?"* with the follow-up *"Was there anything you wished you could do with the view?"* Testers never attribute lag, lurch or betrayal to the camera, name threats while still steps out of range ("saw it coming" as fact), never praise the camera as an effect (applause is failure wearing applause), and produce no "wanted to look around" token (the missing-verb test — the eye is ahead often enough that the wish never forms). Anti-codes: "lag", "lurch", "the camera got me killed", "the camera moved weird", "cool camera", "cinematic", "movie-like", "wanted to look around".
- **AC-CAM-28** [PLAYTEST] *(P2 — the-stage)* — elicitor: *"Describe the boss fight — what did you see?"* The Denial duel is described as choreography — staged, readable, the whole fight on one screen. Anti-codes: "lost him off-screen", "couldn't see the boss", "camera chaos".
- **AC-CAM-29** [PLAYTEST] *(P3 — the-held-reveal)* — elicitor: *"What happened when you went back through the cistern?"* Testers **stop or turn within the framing zone without a prompt** (the operational definition), and the hold reads as an invitation. Anti-codes: "it grabbed me", "startled", "the camera lurched".
- **AC-CAM-30** [PLAYTEST] *(P4 — the-fall-shown)* — elicitor: *"Tell me about the long drops."* Falls read as whole — "I saw where I'd land". Anti-codes: "fell off-screen", "didn't see the ground".
- **AC-CAM-31** [PLAYTEST] *(P5 — comfort; absorbs the SSQ-short instrument)* — the pre/post **SSQ-short survey shows no nausea-score increase in > 10% of playtesters** over a 20-min session; **0 of 5 testers report motion discomfort at defaults**; SCREEN_SHAKE-off testers complete the Denial fight with no readability complaint (the hit-stop carries the impact). Anti-codes: nausea, "shaky", "hurt my eyes".

### Playtest coding table (P1–P5)

| Code | In-code tokens (accept) | Anti-codes (fail) |
|---|---|---|
| **P1 the-eye-unseen** | saw it coming, ahead of me, didn't notice it move | lag, lurch, camera got me killed, moved weird, cool camera, cinematic, movie-like, wanted to look around |
| **P2 the-stage** | staged, choreography, readable, one screen, saw the whole fight | lost him, off-screen, couldn't see the boss, chaos |
| **P3 the-held-reveal** | stopped to look, invitation, waited, shown | grabbed me, startled, lurched, snapped |
| **P4 the-fall-shown** | saw the whole fall, knew where I'd land, showed the ground | fell off-screen, didn't see the ground, blind drop |
| **P5 comfort** | comfortable, fine, calm | nausea, shaky, hurt my eyes, strobing |

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[DEVICE]`/`[PLAYTEST]` describe where an AC runs, not which gate owns it — **the tag mapping is stated once: [GUT] ⇒ MVP-smoke, [DEVICE] ⇒ MVP-device, [PLAYTEST] ⇒ MVP-lock.**

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP-smoke** | **22** | AC-CAM-01…22 | Headless GUT on the CI build |
| **MVP-device** | **4** | AC-CAM-23…26 | Device matrix (the QA plan's device pass) |
| **MVP-lock** | **5** | AC-CAM-27…31 | Playtest + coded rubric (the SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The VS estate (the FocusPort tenants, the continuous vertical follow, the negative-origin rooms) is recorded, not AC'd at MVP |
| **Total** | **31** | | 22 + 4 + 5 + 0 = 31 |

**Exactly-one proof.** AC-CAM-01…31 appear in exactly one gate each; the DEVICE-tagged ACs do not default home to smoke; the playtest ACs are MVP-lock. Counted: smoke = 01–22 = **22**; device = 23–26 = **4**; lock = 27–31 = **5**; VS = **0**; 22 + 4 + 5 + 0 = **31**. All probe-register gate references resolve (PR-CAM-01/05→24 · 02→10 · 03→02 · 04→14 · 06→23 · 07→10/24 · 08→24/25 — none dangles). The SYS-32 QA plan will expand the device/playtest protocols; this manifest is the GDD-side partition.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **The probe register's verdicts** — PR-CAM-01…08 are `PROBE-PENDING` (Camera2D limits under the D1 path; reset_smoothing/atomic handoff; smoothing-vs-freeze; offset-vs-limits order; integer-snap/resampling at zoom k; D1 device cost; same-tick limits+position atomicity; the artifact/quantization audits). They gate **SYS-32's first implementation story**, not this GDD; the planned Camera & Framing ADR carries the register. | godot-specialist + technical-artist | Before the first SYS-32 story |
| 2 | **The feel-knob tuning pass** — `LOOKAHEAD_PX` 32, `COMMIT_DELAY_MS` 150, `ALPHA_H_H` 18 / `ALPHA_V_H` 10, `LONG_FALL_PX` 96, `LOOKDOWN_PX` 64, `V_LOOK_UP_PX` 8, `HOLD_EASE_MS` 400 are authored defaults within pinned ranges (the working plan's "playtest-tunable" clause; the GDD pins the numbers and the commit/drop laws). | game-designer + QA | The greybox MVP playtest |
| 3 | **The staging band's ratification** — the arena's fight must play out inside x[3296, 3744] × y[57, 295] (+16 px margin; the OoE analog); the duty covers **every fight participant and threat effect**, and the player's reachable space is sealed to the band (a reachable strip is an authoring defect). SYS-14/level-design author to it; if the authored arena cannot fit, the recorded fallback (follow-clamped-to-zone) is one knob away. | SYS-14 + level-designer | At SYS-14 authoring |
| 4 | **The TR-MOV-028 `position` rider** — the publication must gain the body-center point (art-px hundredths, quantized at the port boundary) before the camera can follow. | lead-programmer + game-designer | Before the first SYS-32 story |
| 5 | **The parallax/vection guardrail** — far layers ≤ 0.3 factor, minimal vertical parallax; ratified against the art bible's composition doctrine. | art-director | At the art bible |
| 6 | **The VS seam estate** — FocusPort's future tenants (focus objects weight ≤ 0.4; in-room directors/false boundaries where a secret must sit inside a room; the cutscene zoom-spike note; continuous vertical follow for VS wall-jump chains): recorded, not designed. | game-designer | At VS authoring |
| 7 | **The RM-01 micro-ease feel** — the ~130 ms two-pixel glide vs the instant-write alternative (the recorded tuning note): playtest owns the call. | game-designer + QA | Playtest |
| 8 | **The QA-plan sync** — SYS-32's soak W-number assignment (the OQ-J2 pattern) + the seven-system envelope re-record (2.45/6.55; the sum is the allocation, the combined soak is the proof). The smoke/device gate split is derivable from the ACs alone; this GDD's resolutions to confirm at the sync: the SKU-timed soak lives in the device gate (AC-CAM-23), the motion-parity caps ratify against the recorded authored-moves envelopes (AC-CAM-26), and the device thresholds (AC-CAM-23's p95/drop/RT numbers) ratify there. | qa-lead | Before the first SYS-32 story |

**Carried obligations (recorded here, owned elsewhere — this GDD does not execute them):** **OQ-RWS-1** (the arcs' feel + the skippable-threshold watch — playtest): the camera's hold durations ride SYS-02's `door_open_ms`/`reveal_arc_ms`; SYS-32 mints no competing constants — the coordination happens at playtest · **OQ-RWS-2** (the flip's budget reconciliation — SYS-09/10): the camera's hold-target-through-flip duty is satisfied structurally (no camera mode; the epoch applies at one tick boundary; an OQ-J1 freeze holds the eye automatically — TR-CAM-002); the seam is recorded, SYS-09/10 reconcile at their authoring · **OQ-RWS-5** (the seam's player-facing surface — VS): carried, not resolved · **OQ-RWS-7** (the wall-tag visual language — art bible): carried, not resolved (the camera consumes wall state only as reserved data) · **OQ-RWS-8** (the arena's data extension — SYS-14): the consumer contract is **stated here** (SYS-14 commands the lock/release and keeps the fight inside the staging band; SYS-32 owns nothing else of the boss) — SYS-14 ratifies at its authoring · **OQ-J4** (SYS-29's shake-envelope feel): the schema is **ratified here** (F-CAM-05's executor + decay; the values stay playtest-tunable) — the answer rides the systems-index sync.

**Answered by this GDD (the row amendments ride the systems-index sync):** OQ-J4 (the shake schema ratification — F-CAM-05 completes F-JCE-09) · the OQ-RWS-8 consumer contract · SYS-02's "bounds read rides SYS-32's own envelope entry" expectation (kept: TR-CAM-017's entry, SYS-02 prices no row).
