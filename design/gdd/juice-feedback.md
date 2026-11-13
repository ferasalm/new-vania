# Juice & Feedback

> **Status**: **APPROVED (2026-11-13 — three-seat design review NEEDS REVISION (creative 3 + technical 7 + QA 11) → all 21 blockers revised in-session with the riders adopted → the mandatory qa-lead spot-check FAIL at 1 blocking fixture defect + 5 repairs, all repaired in-session → gate-ready)**. The user-locked MVP-minimal scope held; no design re-open; the consumed contracts (ADR-0001; SYS-01/SYS-06/SYS-07/SYS-08) were consumed, not re-opened.
> **Author**: user + technical-artist/gameplay-programmer (authoring session, GLM-5.3-Flash)
> **Last Updated**: 2026-11-13 (design review + in-session revision + spot-check repairs)
> **Design Review**: NEEDS REVISION (2026-11-13, three seats) → revision applied in-session → qa-lead spot-check FAIL (1 blocking fixture) → repaired → gate-ready; record at `design/gdd/reviews/juice-feedback-review-log.md`
> **Implements Pillar**: "Read, Then Strike" (every answer is confirmed within one breath) · "SotN, Not Hollow Knight" (the world holds its breath around a committed exchange) · "Remade Every Death" (the glitch is the fiction faulting by magnitude, never an alarm)
> **System ID**: SYS-29 (Presentation layer, MVP-minimal)
> **Contracts**: ADR-0001 — Input Architecture (Accepted 2026-11-12) — §3 (two clocks + the manual freeze), §5 (the per-tick pipeline + the hit-stop⇒body-committed invariant), §6 (gates and terminality), §14 (haptics — the enqueue-only boundary), §15 (test seams pattern); SYS-01 `design/gdd/input-control-mapping.md` (UNFROZEN, #10 record) — TR-INP-064/070, F-01, EX-14, AC-61/AC-70, `HAPTIC_GLOBAL_STRENGTH`, `HAPTIC_CHANNEL_MAP`, `HAPTIC_MIN_INTERVAL_MS`, the capability table, the press/depress hooks; SYS-06 `design/gdd/movement.md` (APPROVED 2026-11-12) — F-MOV-14, TR-MOV-022/023/024, `freeze_hold`, the lock publication; SYS-08 `design/gdd/combat.md` (APPROVED 2026-11-12) — TR-CMB-021/022/023, F-CMB-07, TR-CMB-011, AC-CMB-26/27/28, the clash sparks (two pulses: contact + midpoint), the counter/stagger/deflect event edges, the haptic meaning handoff; SYS-07 `design/gdd/health-damage.md` (APPROVED 2026-11-12) — TR-HD-013/015/035/036/038, F-HD-04, the `DamageNumber`/`HealEdge`/`DeathRecord` edges, `overkill_ratio`, AC-HD-38/40. **Consumers not yet authored (PROVISIONAL):** SYS-32 (the shake execution + clamp), SYS-04 (the audio design for the published edges), SYS-09/10/11 (the glitch-transition triggers), SYS-15/20 (the memory-chime edges), SYS-24 (the settings surface + the print/HUD geometry), SYS-13 (no direct edge at MVP).

## Overview

Juice & Feedback is the presentation half of the trust contract: it owns the **freeze clock** that makes the world hold its breath around a committed exchange (hit-stop 70/90/40 ms — Combat's values, this system's clock), the **haptic drain** that turns SYS-01's enqueued events into the body's three-meaning memory (light = press, medium = commit, heavy = clash/stagger) under the enqueue-only boundary, and the **VFX vocabulary** that makes every answer legible: the clash sparks (the double-beat), the glitch transition (the seam and the death beat's signature), the death sting scaled by `overkill_ratio`, the heal shimmer, the level-up print, and the damage numbers' render law (zero-frame, world-anchored, pooled 32, 700 ms, never sigil-red). It owns no gameplay truth — Combat promises the answer, SYS-07 owns the number, SYS-06 owns the body, SYS-32 owns the camera; SYS-29 makes the answer *felt*: every effect is a receipt for something that really happened, published through event edges the downstream systems design against. Without it the fight wins on the read but the body never remembers, and the game feels like a spreadsheet wearing a costume.

## Player Fantasy

### The named fantasy — Every Answer Is a Receipt

You press; the world confirms. Not with fireworks — with **receipts**: the exchange stops for a blink and the held frame says *that happened*; the spark says *the duet happened*; the buzz in your hand says *your body felt it*; the number says *it was honest*; and when you die, the screen doesn't scold you — it faults, by magnitude, like the machine's own readout of a story that ended too hard. Nothing sparkles for decoration. If removing an effect loses no information, the effect is cut — juice here is feedback integrity, the fiction telling the truth at speed.

### The contract — the freeze, the buzz, the receipt, the fault

- **The freeze is weight, not lag.** Hit-stop is the world holding its breath around a commitment — a hit, a clash, a deflect — and every hold is paired to a body commitment, so a freeze is always *someone's* held breath, never a stutter.
- **The buzz is a language with three words.** Light = you pressed and the body heard. Medium = it committed. Heavy = the exchange answered — a clash, a stagger. No fourth word at MVP; a game that babbles is a game you mute.
- **The number is the receipt.** Small, muted, brief, zero-frame with the contact, never sigil-red, no "CRITICAL" — the honest accounting under the spectacle.
- **The fault is the fiction, not the referee.** The death sting scales with how hard the story ended (`overkill_ratio`); it reads as a system-fault readout in the fiction's voice, never as punishment punctuation.

### Anchor moments

- **The Clash Duet.** Your answer meets their strike on purpose. The world stops — a blink (the 6-tick hold). Amber sparks on the contact; the lock begins; at its midpoint the cyan beat answers the amber one; your hand remembers the heavy word. Two committed bodies, one double-beat, zero damage — the reward was the duet.
- **The Killing Blow.** A power-3 heavy empties the bar — 20 into 16, overkill 4. The hit-stop holds the contact for a blink; the number prints the 20; then the screen goes monochrome — a soft fault shift, the edges intact (ratio 0.04: the quietest readout). The cause row prints the heavy's name. The fiction faulted quietly; it did not scold. (The signature HIGH band — the glitch eating the edges — is reserved for hard faults: the deep pit, the VS curve's heavier strikes.)
- **The Quiet Heal.** You commit the Suture. One medium word in the hand, the cyan shimmer crosses the chassis, the number rises in cyan, the chime lands. No fanfare, no screen flash — the pool is a resource, and the game treats your spending with respect.

### Language law

- No millisecond talk reaches the player ("a breath", never "70 ms"); no design jargon ("juice", "hit-stop", "VFX") in player-facing copy.
- **Every effect is a receipt**: it must carry information (what happened, how hard, what it meant). An effect that survives the removal test — "would anyone miss it if the information moved elsewhere?" — is decoration and is cut. Two channels are **gains, not receipts**: the haptics (TR-JCE-013) and the shake (TR-JCE-026) carry zero unique meaning — they are redundant weight that makes the receipts *felt*; they are legal precisely because they are removable by design, and their removal loses no information — which is the test they pass by construction.
- **No opacity pulses** in any SYS-29 effect (Combat's telegraph ban extended): color-flash + shape, always.
- **Never sigil-red** anywhere in SYS-29's palette surface (reserved for the demon lord's presence).
- **No per-press popups ever** (TR-INP-064) — nothing announces a press in words; the held-state visual + the light buzz are the whole acknowledgment.
- Falsifiability: every feel-sentence in this GDD is verifiable by playtest rubric or build check; if verifying it would need a stopwatch on reflexes, it is cut.

### Success signature

Playtesters say: "when I hit it, everything stopped for a beat — it felt *heavy*"; "the clash — the sparks, that second beat — I felt it in my hands before I processed it"; "the numbers are small but I always knew what happened"; "when I died the screen glitched — like the world itself broke, not like I failed"; "I turned the shake off and nothing important was lost"; "I played with vibration off and never felt talked down to". **Anti-signatures** (the failure modes this GDD exists to prevent): "sometimes it stutters" (an unpaired freeze), "my phone buzzes constantly" (coalescing broken), "the numbers are arcade candy" (the palette or the lifetime mis-tuned), "the death felt like a cheap jump-scare" (an alarm-shaped sting), "I can't tell the press buzz from the clash buzz" (the three-meaning map blurred).

## Detailed Design

### Core Rules

Three laws govern everything below: **the clock law** (all world juice counts on `logic_tick`; a freeze holds it; the offline screen's presentation is context-time), **the receipt law** (every effect is triggered by a published event edge and carries information; nothing self-fires), and **the boundary law** (SYS-29 raises freezes only — never a gate, never a pause, never a context; it renders; it never owns gameplay truth).

#### A · The freeze clock

- **TR-JCE-001 — The freeze clock service.** SYS-29 owns the clock service that ADR-0001 §3 specifies: a single `GameClock` implementation publishing `FreezeState {logic_running, active_sources, freeze_start_physics_tick}` **every physics tick** (raw publication, freeze and pause included — ADR §3/§5). The API is `request_freeze(source: StringName, duration_ms: int, commitment: CommitmentClaim)` / `release_freeze(source: StringName)` — **the clock takes milliseconds and converts inside itself** (F-JCE-01), because the ms contract is what survives a rate change (a ticks-only entry would conflate 70 ms and 80 ms at 5 ticks). Consumers hold ports to it (SYS-01's `clock: GameClockPort`, SYS-06/SYS-08's freeze integration); they never touch the internals. `logic_running = (context == GAMEPLAY) ∧ (freeze_sources.is_empty())` is ADR §3's law, implemented here, consumed by everyone. **Ownership and the advance seam (ADR §3/§5, pinned):** `GameClock` owns the 64-bit `logic_tick`; **`InputTick`'s phase 0 invokes `GameClock.tick_open(context)`** — the ADR §5 pseudocode's tick-open line — which applies the pending freeze/unfreeze and advances `logic_tick` iff running; **no SYS-29 node self-advances the clock**, and the injected `ClockPort` is a read-only view (`physics_tick`, `logic_tick`, `logic_running`) plus the request/release API; SYS-01's phase-0 snapshot then observes the advanced state. *Test: a request freezes the next ticks; a release resumes; `FreezeState` publishes on frozen ticks too; the onset advances exactly one logic tick at the first unfrozen physics tick; the ms contract survives the API (the record's `duration_ms` equals the requested value); a static audit finds exactly one clock implementation, no second writer to `logic_tick`, and no self-advancing node in SYS-29.*

- **TR-JCE-002 — The source set, the countdown, the last-release resume.** `freeze_sources` is a **set of `StringName` reasons, not a boolean** (ADR §3): overlapping freezes do not double-unfreeze; **the last source removed resumes the clock**. Each source carries a **record `(duration_ms, elapsed_ms, current_tps)` and a countdown owned by the clock** (leak-proof: a raiser that is freed mid-freeze cannot leave a frozen world — the countdown expires on physics ticks regardless of the raiser's lifetime); expiry is automatic, and `release_freeze` is an **early-release override** for designer sources (a cancelled script). **A re-request of the same source while it is active is ignored** — no stacking, no extension (mash cannot manufacture a freeze wall); a *different* source joins the set and runs concurrently. *Test (the request-tick anchor): A(5)@T + B(8)@T+2 → frozen T+1…T+10, resume at physics T+11 (stamping logic T+1); B released early at T+4 → frozen to A's expiry T+5, resume physics T+6; a re-request of A mid-flight changes nothing; a raiser freed at T+2 of a 5-tick source does not leak the freeze.*

- **TR-JCE-003 — The tick conversion (never-stingy ceil, rate-safe).** `freeze_ticks = max(1, ceil(duration_ms × physics_tps ÷ 1000))` on the **physics** rate — the freeze cannot be counted on `logic_tick` because that is the counter being stopped (physics always advances, ADR §3). The law is the registry's `ms_to_ticks` ceil family: **ms is the contract, ticks are derived**; a `physics_tps` change re-baselines every pending conversion from ms — the source's accumulated `elapsed_ms` **grows by each rate segment's consumed time** (`elapsed_ms += segment_elapsed_ticks × (1000 ÷ segment_tps)` at every rate change, the anchor reset per segment), then `remaining_ms = duration_ms − elapsed_ms` (integer hundredths) and `new_countdown = max(1, ceil(remaining_ms × new_tps ÷ 1000))` — so **two or more rate changes accumulate correctly** (the single-record `onset_tps` form would under-count the middle segment). Combat's values convert: 70 → 5 ticks (83.3 effective), 90 → 6 (100), 40 → 3 (50). *Test: the 5/6/3 table at 60 tps; a mid-session rate change re-baselines every pending source from its accumulated record with no early expiry and no overstay — the 90 ms source with 2 ticks elapsed at 60 tps recomputes to 3 ticks at 45 tps (66.7 ms; total ≈ 100 ms ≥ the 90 ms contract — the ceil is never-stingy on the hold, never a restart), and a second rate change (2 ticks at 60, then 2 at 45, back to 60) accumulates 77.8 ms consumed before the recompute; no wall-clock read exists inside the core.*

- **TR-JCE-004 — The onset boundary (ratified, ADR §3).** A request raised during physics tick `T` makes `T` the **last stamped `logic_tick`**: `GameClock` records `freeze_pending`; the next physics tick opens with `logic_running = false` and does not increment `logic_tick`; a freeze of N ticks holds `logic_tick` for the N physics ticks `T+1 … T+N`; the first unfrozen physics tick `T+N+1` stamps `logic_tick = T+1`. A capture arriving in `T`'s capture phase stamps at `T`; a capture arriving **after** the request waits for the first unfrozen `logic_tick`. Never-stingy on the hold: N is the ceil-derived count. *Test: the ADR's onset fixture replays 1:1; the capture-after-request stamps at the first unfrozen logic tick; a 5-tick freeze raised in T resumes logic at T+1 on physics T+6.*

- **TR-JCE-005 — Freeze vs pause vs gate.** They are different mechanisms (ADR §3's discrimination table, ratified): a **freeze** stops `logic_tick` on physics-continuing ticks, preserves pending intents (age frozen), suspends offers/acks, publishes raw states, exits by `release_freeze`; a **pause/gate** stops `logic_tick` via a non-GAMEPLAY context, clears buffers at gate entry, has no offers (context gate), exits by a context transition. SYS-29's authority boundary: **it raises freezes only** — never a gate request, never a pause, never a context write (SYS-05 owns context; ADR §6's gate-source table has no juice row). *Test: a pending backdash intent survives a freeze with age frozen and is offerable at resume; the same intent clears at a pause's gate entry; a static audit finds zero context writes in JuiceCore.*

- **TR-JCE-006 — The paired-commitment law (ADR §5's invariant, enforced here).** `request_freeze` requires a `CommitmentClaim` naming one of: a **published Combat commitment** (the hit-stop pair, the clash lock, the player stagger — TR-CMB-021's levels), a **published Movement lock** (a scripted move — TR-MOV-022), or **`FREEZE_HOLD`** (Movement's zero-motion lock auto-covers a freeze whose onset finds no other lock active — TR-MOV-023). An unpaired request is a **dev assert + production telemetry**, never a silent freeze. The **pair audit** runs each physics tick (≤ 4 sources — cheap): each frozen physics tick is checked against the claimed commitment **level at the stamped logic tick** (commitments are logic-tick levels `[start, end−1]`; the frozen interval's stamped logic tick is the onset's `T`) — a physics-interval containment test is never used; for a `FREEZE_HOLD` claim the check is **liveness**: Movement's `freeze_hold` level must publish by the first frozen tick `T+1` (TR-MOV-023's publication rule) — the cover is *generated by the freeze itself* by design, so the claim proves the coverage contract is live, not an independent commitment (that is the ADR's design, not a circularity accident). If a source cannot assert the invariant, the backdash detector's fail-closed rule applies (ADR §5) — a delayed dodge is worse than a missing one. *Test: an unpaired request asserts; every source in the soak has a live commitment for its full interval; an idle-body freeze shows `freeze_hold` within one tick of onset; the backdash detector sees `body_busy` mid-freeze and drops.*

- **TR-JCE-007 — The cap and the freeze trace.** `MAX_CONCURRENT_FREEZE_SOURCES = 4` (dev assert on the 5th join; the MVP exchange shape never exceeds 2). Every freeze interval records `(source, duration_ticks, commitment, onset_physics_tick, release_physics_tick)` in the **freeze trace** — the tick-trace tests' spine and the pair audit's input. *Test: the 5th concurrent source asserts; the soak's trace shows every freeze paired and bounded; no source exceeds its countdown.*

#### B · The haptic channel

- **TR-JCE-008 — The drain (the enqueue-only boundary's other half).** SYS-01's input layer **enqueues only** (ADR §14); **SYS-29 drains the preallocated `HapticQueue` (capacity 64) every physics tick** and performs the rendition execution outside the instrumented input scope — in SYS-29's tick budget (TR-JCE-030). The drain dequeues, coalesces (TR-JCE-009), applies strength (TR-JCE-011) and hands the rendition to the platform; the drain never enqueues, and JuiceCore never writes the queue. *Test: the drain empties a seeded queue within one tick; a static audit finds no enqueue calls in SYS-29; the input-side AC-61 edge hooks remain SYS-01's.*

- **TR-JCE-009 — The coalescing law (meaning preservation, never a meaning lost).** At most **one emission per interval** (`interval_ticks = ceil(HAPTIC_MIN_INTERVAL_MS × physics_tps ÷ 1000)` = 3 physics ticks at the 50 ms default — the interval measures on **physics ticks**, never wall-clock, never logic ticks, so the cadence stays alive during freezes). **Three per-class pending slots** (light/medium/heavy): an event emits immediately if the interval has elapsed; otherwise it enters its class's slot, **replacing the slot's previous same-class event** — the freshest same-class event stands in, because same-class predecessors within one interval are the same meaning (absorbed **by design**, counted in telemetry). **Arbitration is aging, not strict priority**: the interval's emission goes to the **oldest pending arrival**, ties → the strongest class (heavy > medium > light) — a class that has waited always outranks a fresher heavier arrival, so **no class can be starved by a sustained heavier stream**. **The delivery bound**: every class's newest pending event emits within **three intervals** (≤ 150 ms at defaults) of arrival — no meaning is ever lost ("coalescing is not overflow", ADR §14). The steady state at the worst-case 12 t/s mash (24 edges/s into the 20/s cap): the press/depress alternation rides the 50 ms cadence with each emitted event within one interval of its arrival; when two same-class events land in one interval, the later stands in (≤ 4 light absorptions/s at the ceiling, telemetried) — every **meaning** still arrives, not every edge. *Test: the press@t / depress@+41.7 ms fixture emits both (the second at +50); a heavy+medium collision emits the heavy first and the medium at the following interval — both arrive within the bound; the starvation fixture (a heavy arriving every interval with a medium pending) shows the medium emitting within three intervals (aging wins); the 1,000-event mash records zero medium/heavy losses, ≤ 20 emissions/s, and the light absorption count in telemetry.*

- **TR-JCE-010 — The overflow law.** If the ring is **full at dequeue**, the event is a **dev assert + production telemetry** — never silently dropped as if coalesced (ADR §14, the AC-61 hazard). The drain runs every physics tick, so the worst-case mash stream (24 events/s) cannot overflow a 64-ring; overflow in the wild means a stalled drain, which is the assert's job to surface. *Test: a stalled-drain fixture fills the ring and asserts; the 10,000-tick mash soak records zero overflow.*

- **TR-JCE-011 — Strength and rendition.** Emitted amplitude = the event's base strength × `HAPTIC_GLOBAL_STRENGTH` (0–1, SYS-01's Recalibration knob); **strength 0 produces no rendition call at all** (not an amplitude-0 call). The **capability probe** runs at boot and logs the rendition per SYS-01's capability table: Android API 26+ = amplitude scaling (the full map honored); Android < 26 = on/off (strength maps to 0/1); no-vibrator hardware = silent (visuals carry all meaning); iOS = the engine-verification item 13 caveat — the stock API is presumed to ignore duration/amplitude and expose no light/medium/heavy styles; until verified, iOS fires the platform default short pulse and, if strength 0 cannot be honored, the settings copy says so (AC-70's platform carve-out). *Test: the strength fixture (0 → no calls; 1.0 → base amplitude); the probe logs one rendition per class; the iOS row degrades to the documented default.*

- **TR-JCE-012 — The closed edge list (SYS-01 OQ #7's answer: none beyond the mapped three).** The haptic channel stays **three-meaning**; the qualifying edge list is **closed at MVP**: **light** = the press/depress edges (exactly once per edge — AC-61); **medium** = the quick-use/heal use; **heavy** = the clash family's resolutions — the counter-clash, the double clash, and the lose branch (the lose's onset **is** the player's stagger: one edge, not two). The **chip's preview/commit edges complete the map** (light/medium) and join the audit when SYS-07's OQ#1 promotion lands (the chip is VS-gated in SYS-01 until then — AC-69's precedent; the promotion carries the edges into the MVP audit). **No other event earns buzz at MVP**: knockback, knockdown, damage taken, the level-up, the memory chime would each be a *fourth meaning* — the SYS-01 re-review #8 rider deliberately refuses a growing map (the chip's distinct-drop precedent is not extended). A hold-repeat stream's repeats are ordinary press edges — light ticks absorbed by coalescing, never a new meaning (OQ#7's `stream_origin_tick` extension rides the same edges when it lands). **The MVP visual carriers are named so the map is complete without the chip**: the light press = the held-state visual; the medium use = the heal shimmer + the cyan number; the heavy = the spark pair + the freeze. *Test: a static audit of SYS-29's emissions finds exactly the MVP set (press/depress, the use, the clash family); the chip edges appear in the map and join the audit at the promotion; the mash loop produces only light renditions; the deferred list appears in the Open Questions, not in code.*

- **TR-JCE-013 — The a11y law (haptics are a gain, not decoration).** The channel exists for the low-vision gain and the body's memory; every meaning remains fully conveyed by the **visual channel** (text + shape, never color alone — SYS-01's law): the held-state visual is the press acknowledgment, the chip's flash is the commit acknowledgment, the spark pair is the clash acknowledgment. Strength 0 is legal and complete (SYS-01's edge case: the acknowledgment falls entirely to the visuals; no timeout compensates, because none exist). The off-switch disables a *rendition*, never a *meaning*. *Test: the strength-0 loop completes every meaning on visuals alone; the meaning audit (light/medium/heavy × press/commit/clash) passes with haptics muted.*

#### C · The VFX vocabulary

- **TR-JCE-014 — The pulse scheduler.** Scheduled world VFX are **logic-tick-anchored entries** in a preallocated ring (`PULSE_SCHEDULER_CAPACITY` 64): a pulse fires on the **logic tick it names** — an intervening freeze shifts its wall arrival with the world (the held-breath coherence), never fires early or on wall-clock. Ring overflow recycles the oldest entry + telemetry (a pathological scripted sequence degrades visibly, never crashes). *Test: a pulse scheduled at L fires at L across an intervening freeze; the 65th entry recycles the oldest with a telemetry record.*

- **TR-JCE-015 — The clash sparks (the double-beat).** The **double clash fires two pulses** (TR-CMB-011's two spark pulses, the visual is SYS-29's): the **contact pulse** at the resolution tick (the lock's start) and the **midpoint pulse** at `lock_start_logic_tick + ceil(CLASH_LOCK_TICKS ÷ 2)` = +21 (350 ms into the 700 ms lock) — both **logic-tick-anchored**, so a mid-lock freeze shifts the second beat with the lock (the duet never desyncs from the bodies it belongs to). The **counter** and **lose** branches fire the contact pulse only; the **deflect** fires a single reversal pulse at the reversal tick. **The contact pulse is never delayed by the freeze it accompanies**: it is scheduled at the resolution tick, which is the freeze's last stamped logic tick (TR-JCE-004), so it renders on the contact frame itself — zero-frame with the number; only pulses scheduled at **later** logic ticks (the midpoint) shift with the freeze. No second resolution ever produces a second contact pulse (TR-CMB-011's no-second-resolution). *Test: the two-pulse fixture (contact + midpoint); the shift fixture (a 6-tick freeze at the lock's start leaves the contact pulse on the contact frame and moves the midpoint 6 wall-ticks later, keeping it at +21 logic ticks); the counter/lose/deflect single-pulse fixtures.*

- **TR-JCE-016 — The spark palette law.** The spark palette is **the world's palette (cyan/amber)** — never sigil-red (the static audit; reserved for the demon lord's presence); **contact = amber, midpoint = cyan** (designer-fixed members of the world palette; hex pinned at the art-bible pass, OQ-J3); **≥ 2 value-ramp steps of separation** from backdrops (the audit's measurable metric: the absolute delta of the palette **value-ramp indices** between the effect's color and the backdrop's sampled color — the world palette's ordered value ramp, the `PROV_PALETTE` ordering until the art-bible pin; the term is Combat's "2 px value separation" with its unit made measurable); shapes are **procedural at MVP** (a radial spark silhouette, 2 frames per pulse at MVP — the asset pass re-skins later); **color-flash + shape, never opacity pulses** (Combat's ban extended to every SYS-29 effect). **Definitions for the audits:** *"sigil-red"* is the demon-lord palette class — the reserved red family (hue in the red band at game saturation); the palette audits run against the **provisional palette table** (the repo-pinned `PROV_PALETTE` entries — named placeholders until the art-bible pin, OQ-J3). *"Opacity pulse"* (the banned pattern) is an alpha (or alpha-equivalent) oscillation with **≥ 2 direction reversals within one effect instance**; a single monotonic fade-in or fade-out is legal — and is exactly what `REDUCED_FLASH` renders. *Test: the static audit finds no sigil-red (the PROV_PALETTE audit) and no alternation pattern in the shipped fixtures; the two palette members match the world-palette table; the value-separation check passes on the backdrop fixture set.*

- **TR-JCE-017 — The glitch transition (the seam's VFX).** The glitch effect lives here; its **triggers** are SYS-09/10's reality flip (world-time, provisional pending their authoring — OQ-J1) and SYS-15's death beat (context-time — the offline screen's own presentation clock; SYS-15 owns the screen, SYS-29 renders the glitch component into it). The effect is band-scaled where the trigger is the death beat (TR-JCE-018) and designer-scaled for the flip (`FLIP_GLITCH_MAG` provisional). It obeys the flash law (TR-JCE-022) and the palette law (monochrome + the world palette's cyan tear accent; never sigil-red). *Test: the flip fixture renders the effect over the (held) world; the death fixture renders it on the offline surface; both pass the flash and palette audits.*

- **TR-JCE-018 — The death sting (the glitch magnitude, not an alarm).** The sting scales with `overkill_ratio = overkill ÷ hp_max` from the player's `DeathRecord` (TR-HD-015) in **three bands**: **LOW** (ratio ≤ 0.25) — the quiet fault readout: a soft monochrome shift, the edges intact; **MID** (0.25 < ratio ≤ 0.60) — the standard glitch; **HIGH** (ratio > 0.60) — the signature: the glitch eats the edges. A **0-overkill death is LOW** (the band includes 0 — an exact-HP kill is the quietest fault). The sting is the **player's death beat only**: an enemy death carries no sting and no glitch (the defeat is carried by the numbers and the audio defeat tick — SYS-04's) — a ruling, not an omission: the enemy defeat carries no MVP visual cue beyond the killing number. Magnitude is *never* alarm: no alarm color (sigil-red stays banned), no alarm sound (the sting publishes **no audio edge of its own** — the death power-down is the death's only audio), no punishment punctuation — the fiction faulting by magnitude, exactly as SYS-07 rules it. SYS-07's fantasy prose ("the glitch eats the edges") describes the death beat's general texture; **this band law sets the per-death magnitude** — recorded for the cross-doc sync (the SYS-07 ledger). *Test: ratios 0.0/0.04 → LOW, 0.40 → MID, 0.73 → HIGH; an enemy death produces no sting; the static audit finds no red and no alarm-class audio trigger in the sting's edge.*

- **TR-JCE-019 — The heal shimmer.** On the `HealEdge` (TR-HD-035), a **cyan value-shift** crosses the chassis for `HEAL_SHIMMER_MS` = 300 (18 logic ticks, world-time — a mid-shimmer freeze holds it); **no screen flash** (the pool is a resource, not a jackpot); **no haptic of its own** (the chip's use edge — medium — already carries the buzz; a shimmer buzz would be a fourth meaning). The charge pip's dim is SYS-24's render. *Test: the shimmer spans 18 ticks and holds across a freeze; the fixture contains no screen-space flash; the heal trace contains no haptic event beyond the chip's use edge.*

- **TR-JCE-020 — The level-up print cue.** On the `StatRevision` edge (TR-HD-035), a **single diegetic print row** in the print voice ("TRAINING POINT BANKED" class copy — the final copy is SYS-28's/SYS-24's): one line, in the HUD print slot, held `PRINT_ROW_HOLD_MS` = 2500 (150 logic ticks), **non-modal, no freeze, no fanfare** (TR-HD-007's "no mid-combat interruption" — the cue never interrupts); the only sound is the print tick SYS-04 designs. **One print slot**: a newer print replaces an older (the slot is shared with the memory print, TR-JCE-021). *Test: the level-up publishes the row with no freeze and no fanfare trigger; a second print replaces the first within the hold; the trace shows no context or clock writes from the print path.*

- **TR-JCE-021 — The memory chime edge.** On a memory pickup (SYS-20) or a cache's MEMORY CACHED (SYS-15), SYS-29 publishes the **chime event edge** + the shared print row (the copy is SYS-15/20's); the celebration is **audio-led** (SYS-04 designs the chime) — **no haptic** (a fourth meaning is refused at MVP, TR-JCE-012) and no screen flash. The edge fires **exactly once per pickup** (SYS-03's save and the pickup latch own the truth; SYS-29 only echoes). **The grant cue (Movement OQ row 10 — the Leap-Stone — answered here):** pickup-class grants (the Leap-Stone) reuse the memory-pickup treatment — the chime-class audio edge + the shared print row, once per grant; the **double-jump's in-air tell** is a single soft pulse at the double-jump takeoff tick (the deflect's pulse vocabulary — world palette, ≤ 2 frames) + the jump-2 audio edge (SYS-04's); the relic's bespoke VFX (the stone's glow, the wing motif) is the art pass (OQ-J3). *Test: the edge fires once per pickup fixture; the trace shows no haptic event; a repeat pickup in the same session (a latched re-read) does not re-chime; the grant fires the cue exactly once; the double-jump takeoff fires one pulse + one audio edge and the first jump fires neither.*

- **TR-JCE-022 — The photosensitivity law.** Every SYS-29 effect **at defaults** satisfies the WCAG flash-threshold test: **≤ 3 flashes per second, no red-flash** — the double-beat is 2 pulses in 700 ms; the glitch's scanline/strobe texture is designed under the same cap (the shader's flash rate is a knob with a compliance ceiling). The audit's scope is per-effect; the **combined-screen case** (the busiest scripted exchange — clash + sparks + a sting-class effect co-present) rides the device pass (AC-JCE-38). The **`REDUCED_FLASH` player toggle** removes alternation entirely: pulses render as a single monotonic soft fade each, the glitch renders as desaturation + a single tear with no scanline strobe, the spark shapes lose their alternation frames. The toggle is a Recalibration setting (SYS-24's surface); the audit runs at defaults **and** reduced. *Test: the flash-rate audit at defaults (≤ 3/s per effect, no red); the reduced-mode fixture shows zero alternation; the device pass repeats both audits at 60 Hz.*

#### D · The damage numbers (the render half of SYS-07's law)

- **TR-JCE-023 — The render law (zero-frame, world anchor, legibility).** The number is **visible on the contact tick's first rendered frame** — zero-frame relative to the hit-stop onset (TR-HD-036's law; the render pairs with the freeze: the damage phase runs after contact detection and before the freeze onset in the same physics tick — SYS-07's pinned order — so the first frame of the contact tick shows number and (next tick) the held world). The anchor is the edge's `world_pos`; the label renders **in the world SubViewport** (the D1 render model — diegetic world feedback at the world's integer scale, not a HUD overlay; native-rendered text would drift off the contact point during camera motion and fight the safe-area clamps). Glyph height **≥ `NUM_GLYPH_MIN_PX` = 7 world px** (legibility floor at the smallest matrix profile); the float rise ≤ `NUM_RISE_PX` = 8 px over the lifetime; the lifetime is SYS-07's 700 ms = **42 logic ticks, world-time** — a mid-display freeze holds the number mid-flight (world-time coherence: numbers do not march while bodies hold). *Test: the zero-frame fixture (number visible on the contact frame; the freeze holds it at +1); the anchor fixture (the glyph tracks `world_pos` through camera motion); the 42-tick lifetime fixture (a 6-tick freeze mid-display extends the wall duration by 6 and the logic duration by 0).*

- **TR-JCE-024 — The ownership boundary.** SYS-07 owns the **pool (32), the lifetime (700 ms), the off-switch flag, the edge schema, and the pool's writes — including the recycle** (TR-HD-036/038 — the pool is SYS-07's preallocated structure); **SYS-29 renders the pool's state** — consuming **SYS-07's read view** (each label's anchor, kind, remaining life — part of TR-HD-035's read-only publication) and applying the palette (amber = enemy damage, pale bone = player damage taken, cyan = heal; gold glyph is VS, TR-HD-036), the glyph draw, the motion, the legibility floor — and adds **no state and no writer** (SYS-07's read contract: no consumer writes back, TR-HD-035). **The lifetime ages on `logic_tick` (world-time)** — this GDD's clock law supplies the render-side reading; the one-clause ratification on SYS-07's side is recorded for the cross-doc sync. The palette members are named by SYS-07's law; the hex pins at the art-bible pass (OQ-J3); **never sigil-red** (SYS-07's law, audited here too); **no "CRITICAL" text ever**. *Test: a static audit finds no writer to the pool outside SYS-07; the palette audit across SYS-29's glyph colors finds no sigil-red; the VS gold path is absent from the MVP fixture.*

- **TR-JCE-025 — Overflow rendering (steal-oldest, single-frame replace).** When SYS-07's pool recycles under pressure, **SYS-07 performs the steal** (its pool law: **steal-oldest** — the active label with the least remaining life, ties → the lowest id, F-JCE-08; SYS-07's TR-HD-038 preallocates and owns the write) and **SYS-29 renders the post-recycle state on the same rendered frame**: the steal is visible as a **replace**, never as a two-frame gap, a double-draw, or a pop-in. SYS-29 performs no pool write (TR-JCE-024's audit holds); the **steal count** is SYS-07's telemetry. No number renders for an event with `applied = 0` (SYS-07: a 0-damage event changes nothing — no receipt for nothing). *Test: the 33-spawn fixture replaces the oldest single-frame; the telemetry counter increments once; a 0-applied event publishes no glyph; the soak's net allocation is 0.*

#### E · The shake

- **TR-JCE-026 — The shake request edge (SYS-29 requests, SYS-32 executes).** SYS-29 publishes `ShakeRequest {magnitude_px, duration_ms, source, tick}` and its **cancel variant** (carrying the source — the toggle-off path), then SYS-32 executes and clamps to its limits (the clamp is SYS-32's; a static audit finds **no camera writes** in JuiceCore). The shake is a **gain channel, not a receipt** (the language law's carve-out): zero unique meaning — weight redundancy over the sparks, the haptic and the audio — which is why it is player-removable without loss. The MVP envelope is **the clash family only**: clash resolution 3 px / 120 ms, counter-clash 3 / 120, lose-branch stagger 2 / 80 — **`SHAKE_MAX_PX` = 3 cap**, linear decay (F-JCE-09); **hits taken produce no shake** (the hit reaction + the pale-bone number + the audio damage tick carry a taken hit; per-hit shake on mobile is noise). The **`SCREEN_SHAKE` player toggle** (default on) gates requests at the source and **cancels the active request on the next physics tick** (a settings-time change — the player asked, the shake stops). *Test: the request fixture matches the envelope table; a static audit finds no camera writes in SYS-29; the toggle-off cancels the active request within one tick; the 4th-px request is clamped at the source.*

#### F · The audio event edges

- **TR-JCE-027 — The audio edge list + the single duck request.** SYS-29 publishes the **event edges SYS-04 designs sounds for** (SYS-04's list, ratified here as the edges): the **damage tick** (pitched by amount band — never a per-hit voice), the **clash pair** (contact + midpoint), the **deflect tick**, the **heal chime**, the **death power-down**, the **revive boot**, the **level-up print**, the **memory chime**, the **jump-2 tick** (the double-jump takeoff — TR-JCE-021's grant-cue clause), the **defeat tick** (an enemy defeat — the revive's visual is SYS-24's chassis reboot animation; the edge is audio-led by ruling). **No per-press popups, no "ORDER RECEIVED" voice** (SYS-01's law). The **single duck request**: the death beat ducks the music bus by `DEATH_DUCK_DB` = −6, held until the offline screen exits (`duck_request {bus, dB, hold}`) — **provisional pending SYS-04's mix** (OQ-J7); **the hit-stop never ducks** (a 70–90 ms duck is a click artifact — the law is written down so nobody adds one). *Test: the static audit finds exactly the listed edges; no duck request exists for any hit-stop source; the offline entry/exit fixture publishes exactly one duck request and its release.*

#### G · Testability and performance

- **TR-JCE-028 — The purity seam.** **`FreezeClock`** and **`JuiceCore`** are `RefCounted` cores over injected ports: `ClockPort` (physics_tick / logic_tick / logic_running application), `HapticQueuePort` (drain), `EventEdgePort` (the published edges: Combat's event edges, SYS-07's edges, the pickup/cached edges), `RenderPort` (draw-command emission — tests assert the emitted command list, never pixels), `RenditionPort` (the platform vibrator + the capability probe), `TuningPort`. **No `Input`, no `SceneTree`, no `Time`, no `RenderingServer` inside the cores** (the ADR §15 seam pattern). The only wall-clock in the system is the OS-side rendition execution — outside the cores by design, covered by the device jank check, never by a unit test. *Test: both cores instantiate with fakes; the render asserts the emitted draw-command list; the static purity audit passes.*

- **TR-JCE-029 — The deterministic trace law.** Every juice decision is a pure function of **(event edges, ticks, knobs)**; a tick trace replay is **bit-identical**; no wall-clock, no frame-count dependence, no float drift inside the cores (integer-hundredths arithmetic where fractions are unavoidable — SYS-01's R10 pattern). The trace schema publishes: per physics tick — the freeze delta, the drained/emit/coalesce records, the scheduled pulses fired, the draw commands, the print/shimmer/sting transitions. **The full per-tick trace is a test-build artifact** (compiled in the GUT harness); production keeps the counters only (freeze joins/releases, absorptions, steals, overflows) — a 10,000-tick full trace would contradict the allocation bar (TR-JCE-031). *Test: the same fixture run twice yields bit-identical traces; the trace schema is published; the GUT suite replays traces instead of eyeballing frames.*

- **TR-JCE-030 — The tick budget + the five-system envelope.** SYS-29's per-tick work (the haptic drain, the pulse scheduler pass, the damage-number render pass, the print/shimmer/sting state machines, the pair audit): **p99.9 ≤ 0.20 ms / max ≤ 0.60 ms** (the AC-53 tick-budget family). The bar's **workload** — the SYS-29 soak (its W-number is assigned at the QA-plan sync, OQ-J2): 600-tick warm-up, then **10,000 scripted ticks of the exchange grammar's worst case** — a double clash every 42 ticks (the pulses + the 6-tick freeze), a deflect every 30, a 12 t/s mash stream on the haptic queue, a full 32-label number churn, and one print + shimmer + sting transition per 1,000 ticks — measured per tick by the harness's monotonic stopwatch **outside the cores** (the cores stay pure); the estimator is p99.9 over the 10,000 samples; the device pass repeats it on the reference SKU (an idle tick passes nothing). The **OQ#19 envelope grows to five systems**: **p99.9 ≤ 2.05 ms** (1.0 SYS-01 + 0.3 SYS-06 + 0.3 SYS-08 + 0.25 SYS-07 + 0.20 SYS-29) and **max ≤ 5.35 ms** (2.0 + 1.0 + 1.0 + 0.75 + 0.60) — recorded as OQ-J2's amendment to the four-system 1.85/4.75 record. **The sum is the budget allocation, the measurement is the proof**: percentiles do not add, so the soak's per-tick stopwatch covers the **five systems' combined work** and the measured combined p99.9 ≤ 2.05 is the allocation's validation instrument (the max sum 5.35 stands as the hard ceiling). The **vibrator IPC** is outside the instrumented scope by ADR §14 — its cost is bounded by the emission cap (≤ 20 calls/s) and verified end-to-end by **AC-70's haptics-on jank clause** (the MVP device pass: no dropped frames during a 12 t/s mash + haptic stream — the sole instrument), so the cost is not merely relocated. *Test: the device soak meets both bars; the AC-70 clause runs in the same device pass.*

- **TR-JCE-031 — The allocation bar.** No hot-path allocation (the AC-54 family). Preallocated structures: `FreezeState` (one), the pulse ring (64), the shake slot (one), the print slot (one), the shimmer state (one), the sting band table (fixed), the haptic drain scratch (fixed), the render pass scratch (fixed over SYS-07's 32-pool) — the per-tick trace is a test-build artifact, not a production structure (TR-JCE-029). Heap growth ≤ 256 KB; churn ≤ 16 KB / 1,000 ticks; net object/resource delta 0 across the soak. *Test: the 10,000-tick soak (600-tick warm-up, counters reset) reports net deltas 0, heap ≤ 256 KB, churn ≤ 16 KB / 1,000 ticks.*

### States and Transitions

#### FreezeClock

| State | Meaning | Exits |
|---|---|---|
| `EMPTY` | no sources; `logic_running = (context == GAMEPLAY)` | a request → `ACTIVE` |
| `PENDING_APPLY` | `freeze_pending` recorded in tick `T` (ADR §3); `T` is the last stamped logic tick | the next physics tick's open → `ACTIVE` |
| `ACTIVE` | ≥ 1 source; `logic_running = false` in GAMEPLAY; countdowns tick down every physics tick | all sources gone → `EMPTY` (the last release resumes) |
| `MIXED_CONTEXT` | sources exist while context ≠ GAMEPLAY (e.g. a flip-freeze raised during Reading) | the countdowns keep expiring; on GAMEPLAY return the clock is unfrozen unless a live source remains |

**Transitions invariants:** `ACTIVE` never skips `PENDING_APPLY` (the onset boundary); `EMPTY → ACTIVE` always records the claim (the pair law); a source's countdown always terminates (leak-proof); the last release — expiry or early — is the resuming one.

#### JuiceCore machines

| Machine | States | Notes |
|---|---|---|
| Haptic drain | `idle` → `pending(slot)` → `emit` → `idle` | three per-class pending slots; oldest-arrival-first (ties strongest); per-class delivery ≤ 3 intervals; overflow = assert + telemetry |
| Pulse scheduler | `idle` → `scheduled(≤ 64)` → `fired` (per entry) | logic-tick-anchored; freeze shifts wall arrival; overflow recycles-oldest |
| Print slot | `empty` → `printing(hold 150 ticks)` | one slot; a newer print replaces; no freeze, no fanfare |
| Shimmer | `idle` → `active(18 ticks)` | world-time; holds across freeze |
| Sting | `idle` → `LOW / MID / HIGH` (band by `overkill_ratio`) | context-time on SYS-15's surface; magnitude, not alarm |
| Number render | passive pass over SYS-07's 32-pool | zero-frame spawn; steal = single-frame replace; no state of its own |

### Interactions with Other Systems

| Boundary | Flow | Contract |
|---|---|---|
| **SYS-01 Input** | upstream (hard for the clock law + the haptic queue) | `GameClockPort` consumption (ADR §3/§15); the `HapticQueue` (SYS-01 enqueues, SYS-29 drains); the press/depress hooks (AC-61); `HAPTIC_*` knobs; the freeze-vs-pause discrimination (EX riders) |
| **SYS-06 Movement** | upstream (hard for `freeze_hold`) | F-MOV-14 (motion holds during freeze; raw continues); TR-MOV-023 (`freeze_hold` covers an idle-body freeze — the pair law's Movement side); the lock publication |
| **SYS-08 Combat** | upstream (hard for the hit-stop) + downstream (soft, read-only) | TR-CMB-022 (the 70/90/40 sources; every source pairs a commitment — this GDD enforces the law); TR-CMB-023 (Combat's timers hold); the clash/counter/lose/deflect event edges (the sparks + the heavy haptic); the meaning ownership (heavy = clash/stagger is Combat's to name) |
| **SYS-07 Health & Damage** | upstream (hard for the edges) | `DamageNumber {target_id, amount, kind, contact_tick, world_pos, crit, is_heal}` (the render law's input); `HealEdge` (the shimmer); `DeathEdge`+`DeathRecord` (`overkill_ratio` → the sting); `StatRevision` (the print cue); the pool/lifetime/off-switch are SYS-07's — SYS-29 renders |
| **SYS-32 Camera** | downstream (hard for the schema, soft for the clamp) | `ShakeRequest` (this GDD publishes; SYS-32 executes + clamps to its limits; the follow runs on the game clock — SYS-32's plan) |
| **SYS-04 Audio** | downstream (soft) | the event edges list (TR-JCE-027); the death duck request (provisional); SYS-04 designs the sounds against the edges |
| **SYS-09/10/11 Dual-Reality / Mutation / Seam** | downstream (soft, provisional) | the glitch transition triggers (the flip — OQ-J1; the seam's reveal framing) |
| **SYS-15/20 Cache / Memory** | downstream (soft) | the death-beat glitch component (into SYS-15's screen); the memory-chime edge + the shared print row |
| **SYS-24 HUD** | downstream (soft) | the settings surface (the toggles); the print slot's geometry; the charge-pip dim; no touch geometry is touched here (SYS-01's law) |
| **SYS-13 Enemy AI** | none at MVP | the enemy defeat renders no SYS-29 VFX (TR-JCE-018); the strike contract (SYS-13, later) may add edges — recorded, not designed here |

### ADR-0001 + SYS-01 Contract Ratification (Juice side)

| ADR/SYS-01 law | SYS-29 ratification |
|---|---|
| §3 the manual freeze (logic stops, physics continues; the source set; the last release) | **Owned**: the `GameClock` service is SYS-29's; the law is implemented 1:1 (TR-JCE-001..004) |
| §3 freeze-onset boundary + the capture-after-request wait | Ratified in the conversion law (TR-JCE-004); the onset fixture replays the ADR's rule |
| §5 frozen ticks: phases 0–2 run, 3–6 replaced by `mid_freeze_phase()` | Ratified: the drain (a phase-2-class raw publication) continues; nothing in SYS-29 requires phases 3–6 to run mid-freeze |
| §5 the hit-stop⇒body-committed invariant | **Enforced**: the required `CommitmentClaim`, the pair audit, the fail-closed note (TR-JCE-006); SYS-08's commitments and SYS-06's `freeze_hold` are the covered classes |
| §6 gates and terminality | Ratified by refusal: SYS-29 raises no gate request (the audit proves it — TR-JCE-005) |
| §14 the haptics enqueue-only boundary | **Owned (drain half)**: the 64-ring drain, the coalescing, the overflow law, the strength law, the capability rendition (TR-JCE-008..011); the enqueue half stays SYS-01's |
| F-01 (ms is the contract; ceil; rate-safe re-baseline) | Ratified for the freeze conversion (TR-JCE-003) and every SYS-29 ms knob (world-time knobs convert at the same law) |
| AC-61 (the hooks fire exactly once; no popups through any hook) | Ratified: the drain consumes the edges as-is; no SYS-29 path emits a popup or a second edge (TR-JCE-027's audit) |
| AC-70 (the capability rendition clause + the haptics-on jank clause) | Ratified: the device-side drain/emission behavior (AC-JCE-14/37); the clause remains SYS-01's gate instrument |

## Formulas

Three law families govern every formula: **the conversion law** (ms is the contract, ticks are derived by the never-stingy ceil on the active rate — a rate change re-baselines through ms), **the world-time law** (world juice counts on `logic_tick`; the offline screen's presentation is context-time), and **the receipt law** (every output is driven by a published edge — nothing self-fires).

### F-JCE-01 · freeze_ticks — the conversion (TR-JCE-003)

```
freeze_ticks = max(1, ceil(duration_ms × physics_tps ÷ 1000))
effective_ms = freeze_ticks ÷ physics_tps × 1000
```

**Variables:** `duration_ms` (the source's contract, ms); `physics_tps` (60 at MVP). **Output:** ticks ≥ 1; effective ≥ duration (never-stingy). **Examples:** 70 × 0.06 = 4.2 → **5** (83.3); 90 → 5.4 → **6** (100.0); 40 → 2.4 → **3** (50.0); a 45 tps re-baseline converts 90 → ceil(4.05) = 5 (111.1 effective). **Rate law:** a `physics_tps` change re-baselines every pending countdown from its ms contract (no early expiry, no overstay — F-01's rule on the freeze side).

### F-JCE-02 · freeze_resume — the set semantics (TR-JCE-002)

```
logic_running = (context == GAMEPLAY) ∧ (|freeze_sources| == 0)
join(source, n):  if source ∈ set → ignore;  else set += {source}, countdown(source) = n
release(source):  set −= {source};  if set is empty → the clock resumes (last-release)
countdown(source): decrements every physics tick; at 0 → automatic release (leak-proof)
```

**Output:** the running predicate; the trace records every join/release/expiry. **Example (one anchor — the request tick):** A(5) joined at T holds T+1…T+5 (resume physics T+6, stamping logic T+1); B(8) joined at T+2 holds T+3…T+10 (resume physics T+11, stamping logic T+1); the union is frozen **T+1…T+10** and B's expiry at T+10 is the last release. B's early release at T+4 → the world stays frozen until A expires at T+5 → resume physics T+6. A re-request `join(A, 5)` at T+3 is **ignored**.

### F-JCE-03 · haptic_emission — the coalescing law (TR-JCE-009)

```
interval_ticks = ceil(HAPTIC_MIN_INTERVAL_MS × physics_tps ÷ 1000)   # 3 at the 50 ms default
elapsed_ticks_since_emit ≥ interval_ticks → emit(dequeued) immediately
else → slot[event.class] = dequeued   # replaces the slot's previous same-class event (absorption; telemetry)
on interval elapse → emit(oldest pending arrival first; ties → strongest class)   # aging arbitration, no starvation
liveness: every class's newest pending event emits within 3 × interval_ticks of arrival
emission_cap = 1000 ÷ HAPTIC_MIN_INTERVAL_MS          # 20/s at the 50 default
```

**Output:** ≤ 1 emission per interval; per-class delivery ≤ 3 intervals; **zero meaning losses** — same-class absorption is by design and telemetried (a drop is overflow's territory, TR-JCE-010). **Example (the worst-case mash):** press at t=0 emits; depress at +41.7 ms pends and emits at +50 — both fire, the second 8.3 ms late, imperceptible.

### F-JCE-04 · haptic_amplitude — strength and rendition (TR-JCE-011)

```
amplitude = HAPTIC_RENDITION[event.meaning].base_strength × HAPTIC_GLOBAL_STRENGTH
rendition = probe(class)          # Android 26+: amplitude;  <26: on/off;  none: silent;  iOS: default pulse (item 13)
HAPTIC_GLOBAL_STRENGTH == 0 → no rendition call
```

**Variables:** `HAPTIC_RENDITION` is the designer-fixed per-meaning table (light 0.4 / 10 ms · medium 0.7 / 20 ms · heavy 1.0 / 35 ms — Visual/Audio). **Output:** the rendition call's (duration, amplitude) per the capability table. **Example:** heavy base 1.0 at strength 0.6 on Android 26+ → amplitude 0.6; on Android < 26 → on (1); at strength 0 → no call anywhere.

### F-JCE-05 · spark_midpoint — the double-beat (TR-JCE-015)

```
contact_pulse_tick = resolution_logic_tick L          # the lock's start
midpoint_pulse_tick = L + ceil(CLASH_LOCK_TICKS ÷ 2)  # 42 ticks → +21 (350 ms into the lock)
```

**Output:** the two scheduled pulses. **Example:** the lock starts at L = 2000 → pulses at 2000 (amber, contact) and 2021 (cyan, midpoint); a 6-tick freeze raised in the same tick leaves the **contact pulse on the contact frame** (it is scheduled at the freeze's last stamped logic tick — zero-frame with the number, never shifted) and shifts the **midpoint pulse's wall arrival by 6 physics ticks**, its logic schedule staying +21 — the duet stays with the bodies.

### F-JCE-06 · sting_band — the death sting's magnitude (TR-JCE-018)

```
overkill_ratio = overkill ÷ hp_max                   # from the player's DeathRecord
band = LOW  if ratio ≤ STING_MID_RATIO (0.25)
     = MID  if ratio ≤ STING_HIGH_RATIO (0.60)
     = HIGH otherwise
magnitude = STING_MAG_LOW / MID / HIGH [band]        # the glitch's displacement/tear/scanline params
```

**Output:** the band + magnitude for the offline surface's glitch component. The band comparison runs in **integer hundredths** (`overkill × 100` vs `threshold_hundredths × hp_max`, where `threshold_hundredths` = 25 for the LOW/MID split and 60 for the MID/HIGH split) — no float boundary (TR-JCE-029's law). The ratio is the **player's** (`hp_max` 100 at L1). **Examples:** the fantasy heavy (20 into 16 → overkill 4) → 0.04 → **LOW** (the quiet fault); a pit death at 40/100 (the environment applies `hp_max` → overkill 60) → 0.60 → **MID** (the boundary, inclusive); a pit death at 39 → 0.61 → **HIGH** (the signature). **MVP reachability note:** strike deaths cap at the strike's value (6/12/20 of 100 → ratio ≤ 0.20 → LOW) — narrow deaths are quiet by design; the MID/HIGH reaches belong to the environment's raw kills (ratio = 1 − hp_ratio, so dying deep faults hard) and the VS curve's heavier strikes. An enemy death never reaches this formula.

### F-JCE-07 · number_lifetime — the world-time display (TR-JCE-023)

```
lifetime_ticks = ceil(DAMAGE_NUMBER_LIFETIME_MS × physics_tps ÷ 1000)   # 700 → 42 (exact)
visible on logic ticks [C, C + 42); a freeze holds the count (world-time)
```

**Variables:** `C` = the contact logic tick (the zero-frame); SYS-07 owns the ms and the pool. **Output:** the render window. **Example:** spawned at C = 3000 with a 6-tick freeze in the same tick → visible through logic 3041; wall-visible through physics 3047 (the freeze held the count).

### F-JCE-08 · pool_recycle — steal-oldest (TR-JCE-025)

```
on spawn with no free label: victim = argmin(remaining_life over active labels); ties → lowest id
replace the victim single-frame; steal_count += 1 (telemetry — SYS-07's write; SYS-29 renders the result)
```

**Output:** the recycled index (SYS-07's pool law — consumed here as the render-side contract); zero allocation. **Example:** 32 active; the 33rd spawn finds the minimum remaining life (a 700 ms-old label at 3 ticks left) → replaces it on the same rendered frame.

### F-JCE-09 · shake_envelope — the request law (TR-JCE-026)

```
duration_ticks = ceil(duration_ms × physics_tps ÷ 1000)    # 120 → 8 (133.3); 80 → 5 (83.3)
magnitude_px ≤ SHAKE_MAX_PX (3)                             # clamped at the source
same-tick requests coalesce to the strongest magnitude (that request's duration)
SCREEN_SHAKE off → no request published; the active request cancels next physics tick
```

**Output:** the `ShakeRequest` stream — magnitude/duration/source + the cancel variant only; **the offset/decay shape is SYS-32's execution** (not specified here). **Example:** the clash resolution publishes (3 px, 120 ms, `clash`); SYS-32's clamp holds it inside its room limits; the toggle-off publishes the cancel and the shake stops within one tick.

### F-JCE-10 · perf_envelope — the five-system sum (TR-JCE-030)

```
p99.9 = 1.00 (SYS-01) + 0.30 (SYS-06) + 0.30 (SYS-08) + 0.25 (SYS-07) + 0.20 (SYS-29) = 2.05 ms
max   = 2.00 + 1.00 + 1.00 + 0.75 + 0.60 = 5.35 ms
```

**Output:** the MVP gameplay-tick envelope (the OQ#19 record, extended by this GDD — OQ-J2). This **supersedes** the four-system record's ≤ 2.0 p99.9 bar (1.85 + 0.20 = 2.05): the OQ-J2 amendment records both numbers so the headroom change is explicit, never silent. **Example:** the soak measures each system's own bar; the envelope is the sum's guard, re-derived at every system's budget change (never silently).

## Edge Cases

### The clock

- **If two sources are active and the shorter is released early** → the world stays frozen until the longer expires; the last release (expiry or early) resumes. [F-JCE-02; ADR §3]
- **If the same source is re-requested mid-freeze** → ignored; no stacking, no extension — mash cannot manufacture a freeze wall (the degenerate strategy is named and shut down). [TR-JCE-002]
- **If a raiser is freed mid-freeze** (a scene unloads under a strike) → the clock's countdown expires the source; the world unfreezes; no leak. [TR-JCE-002]
- **If a freeze request is raised while context ≠ GAMEPLAY** → the source registers and its countdown expires on physics ticks during the pause; on return to GAMEPLAY the clock is unfrozen unless a live source remains. The countdown never pauses. [F-JCE-02; TR-JCE-001]
- **If a capture arrives after the request in the same tick** → it waits and stamps at the first unfrozen `logic_tick` (the ADR's rule; SYS-29 adds nothing to it). [TR-JCE-004; ADR §3]
- **If the killing blow's hit-stop runs** → the 5-tick hold completes inside GAMEPLAY, then the death edge's non-ack gate request transitions the context; the offline screen (context-time) owns the beat from there. The order is contact → damage → freeze → (next gate-entry) transition — never freeze-then-skip. [SYS-07's pinned order; TR-JCE-018]
- **If a freeze ends exactly at a gate-entry tick** → phase 0 applies the pending unfreeze, then the gate phases run — the ADR §5 order holds; no same-tick double effect. [TR-JCE-004; ADR §5]
- **If a lock ends on the same tick a freeze begins** → the lock's membership is `[start, end−1]`; a freeze starting at `end_tick` finds no active lock → `freeze_hold` covers it (never-stingy on entry). [TR-JCE-006; TR-MOV-023]
- **If a 5th concurrent source joins** → dev assert (the shape never occurs in the MVP exchange grammar; the cap exists so a future system cannot silently stack). [TR-JCE-007]

### Haptics

- **If the depress lands 41.7 ms after the press** (the worst-case mash) → the press emits on time, the depress emits one interval later (≤ 8.3 ms delay) — both fire, nothing drops. [F-JCE-03]
- **If a medium (chip commit) and a heavy (clash) collide in one interval** → the heavy emits first; the medium emits one interval later; both meanings arrive. [TR-JCE-009]
- **If the app loses focus with pending haptics** → the pending queue clears silently (telemetry only) — no buzz inside menus or on the lock screen; a context change is not a player error. [TR-JCE-008; SYS-01's blur semantics]
- **If strength is 0** → no rendition calls at all; every meaning completes on the visual channel (the strength-0 loop). [TR-JCE-011/013; SYS-01's edge]
- **If the hardware has no vibrator** → silent; the capability probe logs it; visuals carry. [TR-JCE-011]
- **If iOS cannot honor strength 0 or the style map** (engine-verification item 13) → the documented default pulse fires; the settings copy says so; the visual channel carries the meaning (AC-70's carve-out). [TR-JCE-011; OQ-J5]
- **If a hold-repeat stream runs** (the a11y toggle) → the repeats are ordinary press edges — light ticks at the stream's rate, absorbed by the 20/s coalescing cap; no fourth meaning is born. When OQ#7's `repeat_tag`/`stream_origin_tick` lands, the edges are unchanged. [TR-JCE-012; OQ#7]

### VFX

- **If `REDUCED_FLASH` is on during the double clash** → both pulses still fire (the receipt is not removed) but render as single soft fades — no alternation frames, no strobe texture. [TR-JCE-022]
- **If the reality flip's trigger fires mid-hit-stop** → the flip's source joins the set; the glitch renders over the held world; the freeze outlasts per the set law. Provisional pending SYS-09/10 (OQ-J1). [TR-JCE-017]
- **If the death is an exact-HP kill** (`overkill = 0`) → ratio 0 → **LOW** — the quietest fault readout; the band includes 0. [F-JCE-06]
- **If an enemy dies** → no sting, no glitch; the defeat is carried by the numbers and the audio defeat tick. [TR-JCE-018]
- **If the player dies to a strike at MVP** → the overkill caps at the strike's value (≤ 20 of hp_max 100) → ratio ≤ 0.20 → LOW — narrow deaths are quiet by design; the MID/HIGH reaches belong to the environment's raw kills (the pit applies `hp_max`, so the ratio is 1 − hp_ratio) and the VS curve's heavier strikes. The scale is designed for the whole game, not just MVP. [TR-JCE-018; F-JCE-06]
- **If a heal is refused (full HP)** → no edge fires, no shimmer, no number, no chime — nothing happened, nothing renders. [TR-JCE-019; SYS-07's refusal law]
- **If a level-up print collides with a memory print** → one slot; the newer replaces the older; both edges still fire to the audio list. [TR-JCE-020/021]
- **If the shimmer is mid-flight when a freeze begins** → the shimmer holds (world-time) and completes after the freeze. [TR-JCE-019]

### The numbers

- **If a number spawns while a freeze is already running** → it appears on the contact tick's first rendered frame and holds with the world (zero-frame relative to the onset — the pairing is the definition, not an exception). [TR-JCE-023]
- **If the contact point leaves the safe rect during camera motion** → the label exits honestly with the world (world truth); no clamp, no re-anchor — the D1 law keeps the mapping exact. [TR-JCE-023]
- **If two numbers spawn the same tick on different targets** → both draw (distinct anchors); the pool handles the pair; a same-tick same-target pair is impossible (one `DamageEvent` per contact). [TR-JCE-025]
- **If an event applies 0** → no glyph (no receipt for nothing). [TR-JCE-025]
- **If the pool recycles under a swarm** → steal-oldest, single-frame replace, telemetry; the pool never allocates mid-run. [TR-JCE-025; F-JCE-08]
- **If the off-switch flips** → the flag is read at spawn; active labels render out; no spawn after; the edges keep publishing (SYS-07 unchanged). The switch lives in Recalibration (context-time — it never flips mid-exchange). [TR-JCE-024]

### Shake and audio

- **If two shake requests land the same tick** → the strongest magnitude wins (that request's duration); the slot is one. [F-JCE-09]
- **If `SCREEN_SHAKE` flips off mid-shake** → the active request cancels on the next physics tick; no request publishes after. [TR-JCE-026]
- **If a shake request is raised outside GAMEPLAY** → dropped silently + telemetry (there is no world to shake on the offline surface; SYS-15's screen owns its own presentation). [TR-JCE-026]
- **If a hit-stop source would duck audio** → it does not; the law forbids it (a 70–90 ms duck is a click artifact). [TR-JCE-027]

### Degenerate strategies — named and shut down

- **Freeze-spam:** mashing cannot stack or extend freezes (same-source ignore; the countdown is clock-owned) — the world's held breath is bounded by the exchange grammar, never by the input rate. [TR-JCE-002]
- **Buzz-spam:** the emission cap (20/s) + the closed edge list bound the channel; the mash soak proves the ceiling. [TR-JCE-009/012]
- **Number-flood:** the pool + steal-oldest cap the render; no allocation, no unbounded growth. [TR-JCE-025]
- **Print-spam:** one slot; the newest replaces. [TR-JCE-020]
- **Decoration creep:** the removal test (the receipt law) is the review rubric for every proposed effect; an effect that carries no information is cut at review, not tuned. [Player Fantasy — the language law]

## Dependencies

| Direction | System | Coupling | Contract | Status |
|---|---|---|---|---|
| Upstream | **SYS-01 Input & Control Mapping** | Hard (clock law + haptic queue) | `GameClockPort`; the `HapticQueue` drain; the press/depress hooks; `HAPTIC_*` knobs; the capability table; EX-14's delivery law | **UNFROZEN (#10 record)** |
| Upstream | **SYS-06 Movement** | Hard (`freeze_hold`) | F-MOV-14; TR-MOV-022/023/024; the lock publication; the idle-body coverage | **APPROVED 2026-11-12** |
| Upstream | **SYS-08 Combat** | Hard (the hit-stop sources) + soft (read-only edges) | TR-CMB-021/022/023; F-CMB-07; the event edges (clash/counter/lose/deflect); the meaning ownership | **APPROVED 2026-11-12** |
| Upstream | **SYS-07 Health & Damage** | Hard (the published edges) | `DamageNumber`/`HealEdge`/`DeathRecord`/`StatRevision`; TR-HD-035/036/038; the pool/lifetime/off-switch ownership | **APPROVED 2026-11-12** |
| Downstream | **SYS-32 Camera & Framing** | Hard (the request schema) + soft (the clamp) | `ShakeRequest`; SYS-32 executes + clamps; the follow runs on the game clock | GDD pending (working plan recorded) |
| Downstream | **SYS-04 Audio Core** | Soft | the event-edge list; the death-duck request (provisional) | Not Started |
| Downstream | **SYS-09/10/11 Dual-Reality / Mutation / Seam** | Soft (provisional) | the glitch-transition triggers (OQ-J1) | Not Started |
| Downstream | **SYS-15/20 Cache / Memory** | Soft | the death-beat component (into SYS-15's screen); the memory-chime edge | Not Started |
| Downstream | **SYS-24 HUD** | Soft | the settings surface; the print geometry; the pip dim | Not Started |
| Architecture | **ADR-0001** | Binding | §3/§5/§6/§14/§15 (ratified above) | **Accepted 2026-11-12** |

**Design-order note:** SYS-29 is #5 in the approved order (after SYS-08/SYS-07) — the freeze clock contract, the haptic drain and the render law are published here so SYS-32 (camera, #7) can consume the `ShakeRequest` schema at its authoring, and so SYS-04/SYS-15/20/SYS-24 author against published edges.

**Registry additions at completion (cross-boundary constants this GDD references and must agree with):** `hitstop_hit_ms` 70, `hitstop_clash_ms` 90, `hitstop_deflect_ms` 40 — source `design/gdd/combat.md` (F-CMB-07), referenced by `design/gdd/juice-feedback.md`. The conversion law (F-JCE-01) joins the `ms_to_ticks` family in the formulas registry. SYS-29's internal knobs (bands, envelopes, capacities) are single-document facts — not registered.

## Tuning Knobs

Designer-fixed (the feel-identity core — never in Recalibration) unless marked player-facing. The conversion of every ms knob follows F-JCE-01 (ms is the contract; ticks derived; rate-safe).

| Knob | Default | Range | Why the bounds | Consumes / feeds |
|---|---|---|---|---|
| `MAX_CONCURRENT_FREEZE_SOURCES` | 4 | 2–6 | the MVP exchange shape never exceeds 2; the cap is a future-proof guard, not a feature | the clock; the pair audit |
| `PULSE_SCHEDULER_CAPACITY` | 64 | 32–128 | the scripted grammar's worst case; overflow degrades visibly (recycle-oldest) | the scheduler; the soak |
| `SPARK_PALETTE_CONTACT` | world-amber (pin at art bible, OQ-J3) | world-palette members | off-palette sparks break the world's read | the pulse render; the audit |
| `SPARK_PALETTE_MIDPOINT` | world-cyan (pin at art bible, OQ-J3) | world-palette members | the two beats must stay two tones | the pulse render; the audit |
| `SPARK_VALUE_SEPARATION_PX` | 2 | 2–3 | < 2: the spark drowns in backdrops | the backdrop audit |
| `SPARK_PULSE_FRAMES` | 2 | 2–4 | more frames = strobe risk (the flash law) | the flash-rate audit |
| `HEAL_SHIMMER_MS` | 300 | 200–500 | < 200: unreadable · > 500: a jackpot flash, and the resource stops feeling scarce | the shimmer; the chime edge |
| `STING_MID_RATIO` | 0.25 | 0.15–0.35 | the LOW/MID split; ≤ 0.15 makes ordinary deaths loud | F-JCE-06 |
| `STING_HIGH_RATIO` | 0.60 | 0.50–0.75 | the MID/HIGH split; < 0.50 makes common kills "signature" | F-JCE-06 |
| `STING_MAG_LOW / _MID / _HIGH` | quiet / standard / signature | magnitudes (art pass) | HIGH is the ceiling the fiction allows — never an alarm | the offline component; OQ-J3 |
| `DEATH_DUCK_DB` | −6 (provisional, OQ-J7) | −12…0 | < −12: the death goes silent · 0: no duck | the duck request; SYS-04 |
| `SHAKE_CLASH_PX / _MS` | 3 / 120 | 0–3 / 80–160 | > 3 px breaks the D1 integer-scale read on mobile | the shake slot; SYS-32 |
| `SHAKE_COUNTER_PX / _MS` | 3 / 120 | 0–3 / 80–160 | the counter's reward must match the clash's weight | the shake slot; SYS-32 |
| `SHAKE_LOSE_PX / _MS` | 2 / 80 | 0–3 / 60–120 | the lose branch is a lesson, not a hit | the shake slot; SYS-32 |
| `SHAKE_MAX_PX` | 3 | 1–3 | the envelope cap; SYS-32's clamp is still authoritative | every shake request |
| `PRINT_ROW_HOLD_MS` | 2500 | 1500–4000 | < 1500: unreadable · > 4000: a lingering billboard | the print slot |
| `NUM_GLYPH_MIN_PX` | 7 | 6–9 | < 6: illegible at the smallest matrix profile | the render pass; AC-JCE-40 |
| `NUM_RISE_PX` | 8 | 4–12 | the float is motion, not a billboard climb | the render pass |
| `FLIP_FREEZE_MS` | provisional (OQ-J1) | — | SYS-09/10 own the flip's shape | the clock; SYS-09/10 |
| `FLIP_GLITCH_MAG` | provisional (OQ-J1) | — | SYS-09/10 own the flip's drama | the glitch component |
| `HAPTIC_RENDITION` | light 0.4/10 ms · medium 0.7/20 ms · heavy 1.0/35 ms | designer-fixed rows | wrong weights blur the three meanings | F-JCE-04; the capability table | TR-JCE-011 |
| **Player-facing (Recalibration — SYS-24's surface):** `REDUCED_FLASH` | off | on/off | the photosensitivity escape; never removes the receipt, only the strobe | TR-JCE-022 |
| **Player-facing:** `SCREEN_SHAKE` | on | on/off | cancels the active request; the receipts stay | TR-JCE-026 |
| **Player-facing (SYS-07's flag, consumed):** `DAMAGE_NUMBERS_ENABLED` | on | on/off | SYS-07's off-switch; SYS-29 reads at spawn | TR-JCE-024 |
| **Player-facing (SYS-01's knob, consumed):** `HAPTIC_GLOBAL_STRENGTH` | 1.0 | 0–1 | 0 is legal and complete | TR-JCE-011/013 |

**Not knobs (documented so nobody adds them):** the hit-stop values 70/90/40 (Combat's F-CMB-07 — SYS-29 owns the conversion, not the values) · `HAPTIC_MIN_INTERVAL_MS`, `HAPTIC_CHANNEL_MAP` (SYS-01's — the three-meaning map is the language, not a preference) · `DAMAGE_NUMBER_LIFETIME_MS`, `DAMAGE_NUMBER_POOL` (SYS-07's TR-HD-036/038) · the camera clamp and follow (SYS-32's) · the bus mix and the sound designs (SYS-04's) · the enemy-strike presentation (SYS-13's) · the context state machine (SYS-05's) · the intent windows and the dp floors (SYS-01's).

## Visual/Audio Requirements

*(Behavior-level specification — SYS-24 owns the HUD rendering and the settings surface; SYS-04 owns the sound designs against these edges; the art-bible pass pins the hex (OQ-J3).)*

- **The clash sparks:** two pulses for the double clash — the **contact pulse** (amber, 2 frames, a radial spark silhouette centered on the lock point) and the **midpoint pulse** (cyan, 2 frames, the same silhouette mirrored in tone) — the double-beat; single pulses for the counter, the lose branch and the deflect (reversal-point); color-flash + shape, never opacity pulses; ≥ 2 px value separation from backdrops; **never sigil-red**; the lock pose reads as two committed bodies, not a shield (Combat's rule — the sparks frame it, never replace it).
- **The glitch transition:** monochrome desaturation + edge displacement + a cyan tear accent; the scanline/strobe texture obeys the flash law at defaults (≤ 3 flashes/s); `REDUCED_FLASH` renders desaturate + a single tear, no strobe. **The death-beat instance** renders into SYS-15's offline surface at the `overkill_ratio` band's magnitude (LOW quiet / MID standard / HIGH eats the edges); **the flip instance** (provisional, OQ-J1) renders over the held world. Never sigil-red; never alarm-shaped (no full-screen white, no strobe-to-white, no sting chord).
- **The heal shimmer:** a cyan value-shift crossing the chassis over 300 ms; no screen flash; no particles at MVP (the asset pass may add restraint-only).
- **The damage numbers:** amber (enemy damage) / pale bone (player damage taken) / cyan (heal); gold glyph is VS-only; **no "CRITICAL" text, never sigil-red**; world-SubViewport rendering at the world's integer scale; glyph ≥ 7 px; the rise ≤ 8 px over 700 ms; zero-frame with the contact; the off-switch hides all numbers.
- **The print voice:** one diegetic print row (the level-up, the memory) — the terminal-print voice the death beat's cause row shares; held 2500 ms; one slot; no fanfare beyond the print tick.
- **The audio edges (SYS-04 designs against):** the damage tick (pitched by amount band), the clash pair, the deflect tick, the heal chime, the death power-down, the revive boot, the level-up print, the memory chime, the defeat tick. **No per-press popups; no "ORDER RECEIVED."** The death duck (−6 dB, held to the offline exit) is the only bus surgery, provisional pending SYS-04's mix.
- **The `HAPTIC_RENDITION` table (designer-fixed — the rendition inputs):** per meaning — light: base_strength 0.4, duration 10 ms; medium: 0.7, 20 ms; heavy: 1.0, 35 ms. The **capability table (SYS-01's)** maps each device class to how (strength, duration) is realized: the probe runs at boot as a **dry-run log** (one rendition recorded per class, zero calls fired — no buzz at launch); Android 26+ realizes the amplitude scaling (the full map honored); Android < 26 realizes on/off (strength maps to 0/1); no-vibrator hardware is silent (visuals carry all meaning); iOS fires the documented default pulse until engine-verification item 13 verifies.

📌 **Asset Spec** — the procedural MVP shapes are specified above; after the art bible is approved, run `/asset-spec system:juice-feedback` to produce per-asset visual descriptions and prompts (the sparks, the glitch bands, the shimmer, the print voice, the rendition table's feel targets).

## UI Requirements

*(Behavior-level — SYS-24 owns all rendering geometry; this GDD owns semantics and the settings contract.)*

- **The settings surface (SYS-24 renders, Recalibration):** SYS-29 contributes exactly four player-facing entries — `REDUCED_FLASH`, `SCREEN_SHAKE`, the damage-numbers off-switch (SYS-07's flag), and haptic strength (SYS-01's knob). Each entry states what it removes (the strobe / the shake / the numbers / the buzz). The **gain toggles** (flash, shake, haptic strength) guarantee the information: every meaning completes on the remaining channels (the text+shape law). The **numbers off-switch** is honest about its purpose: it removes the per-hit readout — that is its function — and the HP bar, the hit reaction and the audio remain the taken-hit's carriers (SYS-07's off-switch law claims no completion guarantee, and this copy claims none either).
- **The print slot:** one line, diegetic print voice, held 2500 ms; the geometry is SYS-24's; the voice is SYS-29's (shared with the death beat's cause row).
- **No per-press popups ever** — no SYS-29 path announces a press in words; the acknowledgment is the held-state visual + the light buzz (TR-INP-064).
- **No "CRITICAL" text, no alarm copy, no sigil-red** anywhere in SYS-29's surface (the static audits).
- **The iOS haptic caveat copy:** if the platform cannot silence at strength 0, the settings copy says so verbatim (AC-70's carve-out) — never a silent lie.

## Acceptance Criteria

Coverage: **31 TR-JCE rules · 10 formulas · 46 ACs · 6 playtest codes · 7 OQs**. Tags: `[GUT]` automatable in Godot Unit Test over the injected ports · `[DEVICE]` on-device QA (the device matrix) · `[PLAYTEST]` human feel observation with the coded rubric.

### The clock contract

- **AC-JCE-01** [GUT] *(TR-JCE-003, F-JCE-01)* — **GIVEN** the three hit-stop contracts (70/90/40 ms), **WHEN** the conversion runs at 60 tps, **THEN** 70→5 (83.3 effective), 90→6 (100.0), 40→3 (50.0); a mid-session `physics_tps` change re-baselines every pending countdown **from its record** (elapsed time preserved, never restarted) with no early expiry and no overstay.
- **AC-JCE-02** [GUT] *(TR-JCE-004; ADR §3)* — **GIVEN** a freeze raised during physics tick T, **WHEN** the onset applies, **THEN** T is the last stamped logic tick, the N frozen physics ticks do not advance `logic_tick`, the first unfrozen tick stamps T+1, a capture arriving in T stamps at T, and a capture arriving after the request stamps at the first unfrozen logic tick.
- **AC-JCE-03** [GUT] *(TR-JCE-002, F-JCE-02)* — **GIVEN** source A(5) joined at T and source B(8) joined at T+2 (the request-tick anchor), **WHEN** the set runs, **THEN** the world is frozen T+1…T+10 (B's expiry at T+10 is the last release; the resume is physics T+11, stamping logic T+1); an early release of B at T+4 leaves the world frozen to A's expiry T+5 (resume physics T+6, stamping logic T+1); a re-request of A at T+3 is ignored (no stacking, no extension); a raiser freed at T+2 of a 5-tick source does not leak the freeze.
- **AC-JCE-04** [GUT] *(TR-JCE-005; ADR §3; SYS-01 AC-21)* — **GIVEN** a freeze and then a pause (SYS-29 asserts only the clock's side of the discrimination), **WHEN** each runs, **THEN** `FreezeState` and the raw states publish every physics tick in both, the freeze exits by release and the pause by a context transition, and a static audit finds zero context writes and zero gate requests in JuiceCore; the **buffer-intent behavior** (pending intents preserved with age frozen across a freeze; cleared at a pause's gate entry; offers/acks suspended in both) is **SYS-01's AC-21's** instrument — cited, not duplicated.
- **AC-JCE-05** [GUT] *(TR-JCE-006)* — **GIVEN** an unpaired request, **WHEN** it reaches the clock, **THEN** a dev assert fires and no freeze exists; **GIVEN** the paired sources (the Combat pair, the clash lock, the stagger, a scripted lock, an idle-body freeze), **WHEN** the pair audit runs each tick, **THEN** every claimed commitment level covers the source's full interval and `freeze_hold` appears within one tick of an idle-body onset.
- **AC-JCE-06** [GUT] *(TR-JCE-007)* — **GIVEN** four active sources, **WHEN** a fifth joins, **THEN** the dev assert fires; the freeze trace records every `(source, ticks, commitment, onset, release)`; the soak's trace shows every freeze paired and bounded.
- **AC-JCE-07** [GUT] *(TR-JCE-001; ADR §3)* — **GIVEN** any tick (frozen, paused, gameplay), **WHEN** `FreezeState` publishes, **THEN** it publishes every physics tick including frozen ones, `logic_running` equals `(context == GAMEPLAY) ∧ (sources empty)`, and a static audit finds exactly one clock implementation with no second writer to `logic_tick`.

### The haptic channel

- **AC-JCE-08** [GUT] *(TR-JCE-008; ADR §14)* — **GIVEN** a seeded 64-ring, **WHEN** the drain runs, **THEN** the queue empties within one physics tick, the execution happens outside the instrumented input scope, and a static audit finds no enqueue calls in SYS-29 (the boundary: SYS-01 enqueues, SYS-29 drains).
- **AC-JCE-09** [GUT] *(TR-JCE-009, F-JCE-03)* — **GIVEN** the worst-case mash stream, **WHEN** the drain coalesces, **THEN** a press at t emits on time, its depress 41.7 ms later emits at +50 (delayed, never a meaning lost), the emission rate never exceeds 20/s, and the 1,000-event mash fixture records **zero medium/heavy losses**, the light absorption count in telemetry, and no class starves (each class's newest pending event emits within three intervals).
- **AC-JCE-10** [GUT] *(TR-JCE-009)* — **GIVEN** a heavy and a medium in one interval, **WHEN** the pending slots resolve, **THEN** the heavy (the older arrival) emits at the next interval and the medium at the following one — both arrive within the bound; the starvation fixture (a heavy arriving every interval, a medium pending) shows the medium emitting within three intervals — aging beats priority; the same-class tie case (two heavies) emits the newest; a same-class light pair in one interval absorbs the earlier (telemetry +1) with no meaning lost.
- **AC-JCE-11** [GUT] *(TR-JCE-010; ADR §14)* — **GIVEN** a stalled drain that fills the ring, **WHEN** dequeue finds it full, **THEN** a dev assert fires with production telemetry — the record is never silently dropped as if coalesced; the 10,000-tick mash soak records zero overflow.
- **AC-JCE-12** [GUT] *(TR-JCE-011/013, F-JCE-04)* — **GIVEN** strength 1.0 then 0, **WHEN** the renditions fire, **THEN** at 1.0 the amplitude equals base × strength and the class-appropriate rendition fires per the capability table, and at 0 **no rendition call happens at all** (the held-state visual loop conveys every meaning — the strength-0 completion, TR-JCE-013's law).
- **AC-JCE-13** [GUT] *(TR-JCE-012)* — **GIVEN** SYS-29's edge emissions, **WHEN** the static audit sweeps (SYS-29's side only — SYS-01's own edges are AC-61's to audit), **THEN** exactly the MVP set exists (light: press/depress; medium: the use; heavy: the counter, the double, and the lose branch's stagger onset — one edge per branch, no double-count) and no fourth meaning exists (no knockback, damage-taken, level-up or memory haptic anywhere); the chip's preview/commit edges are present in the map and gated to the OQ#1 promotion; a hold-repeat stream produces only light renditions.
- **AC-JCE-14** [GUT] *(TR-JCE-008/009/011)* — **GIVEN** the boot sequence, **WHEN** the capability probe runs, **THEN** it is a **dry-run log** (one rendition recorded per device class, zero rendition calls fired — no buzz at boot), and on the fake `RenditionPort` the drain's cadence respects `interval_ticks` (≤ 1 emission per 3 physics ticks at defaults).

### The VFX vocabulary

- **AC-JCE-15** [GUT] *(TR-JCE-015, F-JCE-05)* — **GIVEN** a double clash resolving at logic tick L, **WHEN** the pulses schedule, **THEN** the contact pulse fires at L (amber) and the midpoint pulse at L+21 (cyan); with a 6-tick freeze raised in the same tick, the **contact pulse renders on the contact frame** (no shift — it is scheduled at the freeze's last stamped logic tick) and the **midpoint pulse's wall arrival shifts by 6 physics ticks** with its logic schedule staying +21; no second resolution produces a second contact pulse.
- **AC-JCE-16** [GUT] *(TR-JCE-015)* — **GIVEN** the counter branch, the lose branch and the deflect, **WHEN** each resolves, **THEN** exactly one pulse fires per branch (contact for counter/lose, the reversal tick for the deflect).
- **AC-JCE-17** [GUT] *(TR-JCE-016)* — **GIVEN** the shipped spark fixtures, **WHEN** the static audit sweeps, **THEN** zero sigil-red pixels exist (the PROV_PALETTE audit), the palette members are the world table's amber/cyan entries, the value separation is ≥ 2 value-ramp steps (the ramp-index delta metric) against every backdrop fixture, and zero alternation patterns (≥ 2 alpha reversals per instance) exist anywhere in SYS-29's effects (a monotonic fade is legal).
- **AC-JCE-18** [GUT] *(TR-JCE-017/018, F-JCE-06)* — **GIVEN** deaths with ratios 0.0, 0.04, 0.40, 0.73 and an enemy death, **WHEN** the sting resolves, **THEN** 0.0/0.04 → LOW, 0.40 → MID, 0.73 → HIGH (integer-hundredths comparison), the enemy death produces no sting at all, and the sting's edge audit finds no audio edge of its own and no color outside its declared palette.
- **AC-JCE-19** [GUT] *(TR-JCE-019)* — **GIVEN** a heal on a non-full pool, **WHEN** the `HealEdge` fires, **THEN** the shimmer runs 18 logic ticks, holds across a mid-shimmer freeze, contains no screen-space flash, and carries no haptic event beyond the chip's use edge; a refused heal (full HP) fires no shimmer.
- **AC-JCE-20** [GUT] *(TR-JCE-020)* — **GIVEN** a level-up (`StatRevision`), **WHEN** the cue publishes, **THEN** one print row appears for 150 logic ticks with no freeze, no context write, no fanfare trigger, and a second print replaces the first within the hold.
- **AC-JCE-21** [GUT] *(TR-JCE-021)* — **GIVEN** a memory pickup and a cache MEMORY CACHED, **WHEN** each fires, **THEN** the chime edge publishes exactly once per pickup, the shared print row replaces, no haptic event exists in the trace, and a latched re-read does not re-chime.
- **AC-JCE-22** [GUT] *(TR-JCE-022)* — **GIVEN** every effect at defaults, **WHEN** the flash-rate audit runs, **THEN** no effect exceeds 3 flashes/s and none uses a red-flash; the double-beat measures 2 flashes in 700 ms.
- **AC-JCE-23** [GUT] *(TR-JCE-022)* — **GIVEN** `REDUCED_FLASH` on, **WHEN** the effects render, **THEN** the pulses render as single soft fades (no alternation frames), the glitch renders desaturation + a single tear with no scanline strobe, and every receipt still appears (the information is never removed).
- **AC-JCE-24** [GUT] *(TR-JCE-014)* — **GIVEN** a pulse scheduled at logic tick L with an intervening freeze, **WHEN** the world runs, **THEN** the pulse fires at L (logic-anchored), and the 65th scheduled entry recycles the oldest with one telemetry record and no crash.

### The damage numbers

- **AC-JCE-25** [GUT] *(TR-JCE-023; SYS-07 TR-HD-036)* — **GIVEN** a hit resolving at logic tick C with the freeze raised in the same tick, **WHEN** the first rendered frame of C draws, **THEN** the number is visible (zero-frame relative to the onset) and holds with the world across the freeze.
- **AC-JCE-26** [GUT] *(TR-JCE-023, F-JCE-07)* — **GIVEN** a spawn at C = 3000, **WHEN** the display runs, **THEN** the glyph height is ≥ 7 world px (the data invariant; the device legibility is AC-JCE-40's), the anchor tracks `world_pos` through camera motion, the rise is ≤ 8 px, and the label is visible for exactly 42 logic ticks (a 6-tick mid-display freeze extends the wall window by 6 and the logic window by 0).
- **AC-JCE-27** [GUT] *(TR-JCE-025, F-JCE-08)* — **GIVEN** 32 active labels, **WHEN** the 33rd spawns (SYS-07's recycle), **THEN** the least-remaining-life label (ties → the lowest id) is recycled and SYS-29 renders the post-recycle state on the same rendered frame (no gap, no double-draw, no pop-in), SYS-07's steal telemetry increments once, and the net allocation is 0.
- **AC-JCE-28** [GUT] *(TR-JCE-024; SYS-07 TR-HD-036)* — **GIVEN** `DAMAGE_NUMBERS_ENABLED` off, **WHEN** the edges publish, **THEN** no glyph spawns, the edges still publish (SYS-07 unchanged), active labels render out; **GIVEN** the on-mode palette sweep (the PROV_PALETTE audit), **THEN** amber/pale-bone/cyan only — zero sigil-red, zero "CRITICAL" text, no VS gold in the MVP fixture; a static audit finds no writer to the pool outside SYS-07.

### The shake and the audio edges

- **AC-JCE-29** [GUT] *(TR-JCE-026, F-JCE-09)* — **GIVEN** the clash resolution, the counter-clash and the lose branch, **WHEN** each resolves, **THEN** the request table matches (3 px/120 ms, 3/120, 2/80), the durations ceil-convert (8/8/5 ticks), the magnitude never exceeds `SHAKE_MAX_PX` at the source, and **a hit taken publishes no shake request**.
- **AC-JCE-30** [GUT] *(TR-JCE-026)* — **GIVEN** `SCREEN_SHAKE` off, **WHEN** the effects run, **THEN** no request publishes and the active request cancels on the next physics tick; a static audit finds zero camera writes in JuiceCore (the clamp is SYS-32's).
- **AC-JCE-31** [GUT] *(TR-JCE-027; SYS-01 TR-INP-064)* — **GIVEN** the codebase, **WHEN** the static audit sweeps the audio emissions, **THEN** exactly the listed edges exist (the damage tick, the clash pair, the deflect tick, the heal chime, the death power-down, the revive boot, the level-up print, the memory chime, the jump-2 tick, the defeat tick), no per-press popup or voice exists, and **no hit-stop source issues a duck request**.
- **AC-JCE-32** [GUT] *(TR-JCE-027)* — **GIVEN** the offline entry and its exit, **WHEN** the beat runs, **THEN** exactly one duck request publishes (−6 dB, held) and its release fires on the exit (provisional pending SYS-04 — the fixture pins the edge, SYS-04 pins the mix).

### Testability, performance, traceability

- **AC-JCE-33** [DEVICE] *(TR-JCE-030, F-JCE-10)* — **GIVEN** the SYS-29 soak workload on the reference SKU (600-tick warm-up, counters reset; the scripted exchange-grammar worst case — TR-JCE-030), **WHEN** SYS-29's per-tick work runs, **THEN** p99.9 ≤ 0.20 ms and max ≤ 0.60 ms (the harness's per-tick stopwatch, outside the cores), and the **combined** five-system work measured by the same stopwatch satisfies the allocation (combined p99.9 ≤ 2.05 ms; the max ceiling ≤ 5.35 ms — the sum is the budget, the measurement is the proof); the envelope re-derives as 2.05 / 5.35 from the named budgets (1.0+0.3+0.3+0.25+0.20; 2.0+1.0+1.0+0.75+0.60).
- **AC-JCE-34** [GUT] *(TR-JCE-031)* — **GIVEN** the SYS-29 soak workload (headless — allocation counting needs no device timing), **WHEN** the allocation audit runs, **THEN** net object delta 0, net resource delta 0, heap growth ≤ 256 KB, churn ≤ 16 KB / 1,000 ticks, and the named structures are preallocated (the state, the pulse ring 64, the slots, the band table, the scratch — the full trace absent from production, TR-JCE-029).
- **AC-JCE-35** [GUT] *(TR-JCE-028/029)* — **GIVEN** the same fixture run twice, **WHEN** the traces compare, **THEN** they are bit-identical; the trace schema is published (freeze deltas, drain/coalesce records, fired pulses, draw commands, machine transitions); the purity audit finds no `Input`/`SceneTree`/`Time`/`RenderingServer` in the cores and both cores run over fakes.
- **AC-JCE-36** [GUT] *(TR-JCE-006/007)* — **GIVEN** the soak's freeze trace, **WHEN** the pair audit replays, **THEN** every freeze has a live claimed commitment for its full interval, no unpaired freeze exists, and no source exceeds its countdown (the leak-proof property holds across the whole soak).

### Device

- **AC-JCE-37** [DEVICE] *(TR-JCE-009/030; AC-70)* — **GIVEN** the reference device with the haptic stream on, **WHEN** the 12 t/s mash + haptic-stream run executes, **THEN** the observed emission cadence is ≤ 20/s (the rendition-service call log) and the jank check itself is **AC-70's sole instrument** (SYS-01's clause — this AC makes no second no-dropped-frames claim).
- **AC-JCE-38** [DEVICE] *(TR-JCE-022)* — **GIVEN** the device matrix at 60 Hz, **WHEN** the flash audit runs at defaults and with `REDUCED_FLASH` on, **THEN** no effect breaches the flash threshold at defaults and the reduced mode shows no alternation on any device.
- **AC-JCE-39** [DEVICE] *(TR-JCE-017/018)* — **GIVEN** the three death fixtures on device (LOW/MID/HIGH), **WHEN** each presents, **THEN** the three bands are visibly distinct (LOW's edges intact; HIGH's edge-eating visible), no audio edge of the sting's own fires and no color outside its declared palette appears, and the cause row stays legible (SYS-15's screen composes it); the *feel* of the scale is C5's instrument (AC-JCE-45), not this AC's.
- **AC-JCE-40** [DEVICE] *(TR-JCE-023)* — **GIVEN** the smallest matrix profile and the largest, **WHEN** numbers render in the world SubViewport, **THEN** the 7 px glyph floor holds at the D1 scale, the palette reads against the world's backdrops, and the zero-frame holds on device (no first-frame pop-in).

### Feel and playtest (MVP-lock — the coded rubric)

The playtest set runs the SYS-01 AC-63 protocol: **≥ 5 testers**, the interviewer's 3-token prompt, set-membership coding, logged. A code **passes** when ≥ 3 of 5 testers' transcripts contain ≥ 1 in-code token and the anti-code appears in < 3 transcripts (an anti-code majority fails the code outright). C4 has its own trial bar below.

- **AC-JCE-41** [PLAYTEST] *(C1 — weight/anti-lag)* — testers describe the hit-stop as weight or a held breath ("heavy", "stopped", "held"); the anti-codes "lag", "stutter", "froze — bug?" fail the AC.
- **AC-JCE-42** [PLAYTEST] *(C2 — duet/anti-random)* — testers describe the clash in duet words (sparks, lock, the two beats) and identify the double-beat as deliberate; "random sparks", "just flashing" fail.
- **AC-JCE-43** [PLAYTEST] *(C3 — receipt/anti-clutter)* — testers can state what the numbers told them after an exchange; "clutter", "can't tell", "arcade candy" fail.
- **AC-JCE-44** [PLAYTEST] *(C4 — body-memory/anti-visual-only)* — the discrimination task: 6 trials per tester (2 per meaning, order-shuffled); **≥ 4 of 5 testers score ≥ 4/6 correct at strength 1.0** ("I could tell them apart without looking"); the **strength-0 arm** completes the loop identifying every meaning on visuals and reports no loss; "all the buzzes feel the same" fails.
- **AC-JCE-45** [PLAYTEST] *(C5 — magnitude/anti-alarm)* — testers describe the death as the fiction faulting ("the screen broke", "the world glitched out"); "cheap", "it punished me", "jump-scare" fail.
- **AC-JCE-46** [PLAYTEST] *(C6 — comfort/anti-discomfort)* — **0 of 5 testers report flash discomfort at defaults** (any report fails the default); `REDUCED_FLASH` is then offered and re-checked — testers who enable it report the receipts still landed; "the flashing got to me" at defaults fails.

### Playtest coding table (C1–C6)

| Code | In-code tokens (accept) | Anti-codes (fail) |
|---|---|---|
| **C1 weight** | heavy, held, stopped, weight, deliberate | lag, stutter, froze/bug, dropped frames |
| **C2 duet** | sparks, lock, two beats, duet, answered | random, flashy, just effects |
| **C3 receipt** | knew what happened, read the number, honest, respect | clutter, can't tell, arcade, noisy |
| **C4 body-memory** | felt it, hands knew, distinct | all the same, missed it, buzz spam |
| **C5 magnitude** | the screen broke, glitched, the world faulted | cheap, punished me, jump-scare, scare |
| **C6 comfort** | comfortable, fine, calmer with reduced | flashing bothered me, harsh, strobing |

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[DEVICE]`/`[PLAYTEST]` describe where an AC runs, not which gate owns it.

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP smoke** | **35** | AC-JCE-01…14, AC-JCE-15…32, AC-JCE-34…36 | Headless GUT on the CI build |
| **MVP device** | **5** | AC-JCE-33, AC-JCE-37, AC-JCE-38, AC-JCE-39, AC-JCE-40 | Device matrix (the QA plan's device pass) |
| **MVP-lock** | **6** | AC-JCE-41…46 | Playtest + coded rubric (the SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The VS content (the gold crit glyph, the flip's final shape, the enemy-defeat VFX, the extended rendition table) is recorded, not AC'd at MVP |
| **Total** | **46** | | 35 + 5 + 6 + 0 = 46 |

**Exactly-one proof.** AC-JCE-01…46 appear in exactly one gate each; the DEVICE-tagged ACs do not default home to smoke; the playtest ACs are MVP-lock. Counted: smoke = 13 (01–13) + 1 (14) + 18 (15–32) + 3 (34–36) = **35**; device = 1 (33) + 4 (37–40) = **5**; lock = 41–46 = **6**; VS = **0**; 35 + 5 + 6 + 0 = **46**. The SYS-29 QA plan will expand the device/playtest protocols; this manifest is the GDD-side partition.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **The reality-flip freeze** — does SYS-09/10's scripted flip freeze the clock, for how long, and with what commitment? `FLIP_FREEZE_MS`/`FLIP_GLITCH_MAG` are provisional placeholders until the flip's shape exists. | SYS-09 + SYS-10 | At their authoring |
| 2 | **The five-system perf envelope** — this GDD extends OQ#19's four-system record (1.85 p99.9 / 4.75 max) to **2.05 / 5.35** with SYS-29's 0.20/0.60. The QA plan's obligation must be re-recorded at the next sync. | qa-lead | The next QA-plan sync (before the first Combat story) |
| 3 | **The hex pins** — the spark (amber/cyan), the number (amber/pale bone/cyan) and the sting-band palettes are named members of the world palette; the hex values pin at the art-bible pass and the static audits run against the pinned table. | art-director + technical-artist | At the art bible |
| 4 | **The shake envelope's feel** — magnitudes/durations are provisional (3/120, 3/120, 2/80); SYS-32's GDD ratifies the schema and playtest tunes the values. | SYS-32 + QA | At SYS-32 authoring + playtest |
| 5 | **The iOS haptic rendition** — engine-verification item 13 (carried from SYS-01): the stock API's duration/amplitude/style truth; the capability table and the settings copy amend on the verdict. | technical-director | At the ADR verification pass |
| 6 | **The deflect's second pulse** — MVP ships a single reversal pulse; does the deflection earn a second beat at playtest? | game-designer + QA (QA runs the instrument; design owns the call) | Playtest |
| 7 | **The death-duck values** — the request edge and its hold are pinned here; the dB value and the bus design are SYS-04's (provisional −6). | SYS-04 | At SYS-04 authoring |

**Carried obligations (recorded here, owned elsewhere — this GDD does not execute them):** SYS-07 OQ#1 (the SYS-01 chip promotion + the six-unit ledger move — before the first SYS-07 story; **the chip's preview/commit haptic edges join the MVP audit at this promotion**, TR-JCE-012) · SYS-07 OQ#2/#3 (the SYS-08 lose-branch + damage-numbers amendments — before the first Combat story; OQ#3's damage-number amendment routes through **this** GDD's render law, TR-JCE-023/024) · OQ#4 (SYS-13's follow-up / power legibility / `soul_class`) · OQ#19 (the four-system envelope — extended to five systems by OQ-J2 above) · SYS-01's **proven-140 combo-value row** (the 140 ms proven window; Combat's 200 ms attack window is the recorded per-verb override — the ledger-row amendment rides the SYS-01 sync) · SYS-08 OQ#7 (`repeat_tag` + `stream_origin_tick` — before the first Combat story; the haptic edges are unaffected meanwhile, TR-JCE-012) · the Movement **OQ-M1..M4 batch**. **Answered by this GDD (the row amendments ride the systems-index sync):** SYS-01 OQ #7 (haptics event qualification — *none beyond the mapped three at MVP*, TR-JCE-012) · Movement OQ row 10 (the Leap-Stone grant + the double-jump tell — TR-JCE-021's grant-cue clause) · SYS-07 (one-clause ratification: the damage-number lifetime ages on `logic_tick`, TR-JCE-024).

**VS content recorded (not gated at MVP):** the gold crit glyph (TR-HD-036's VS member) · the flip instance's final shape (OQ-J1) · the enemy-defeat VFX (SYS-13/SYS-24's) · the extended rendition table (per-style light/medium/heavy on platforms that support it) · the focus/parallax juice (SYS-32's VS scope).
