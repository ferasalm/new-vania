# Combat

> **Status**: **In Review — NEEDS REVISION addressed in-session (2026-11-12)**. The three-seat design review (technical 8 blockers, QA 8 blockers, creative PASS) was revised in-session; a diff-scoped re-review is pending. The user-approved decisions 1–11 held; no design re-open.
> **Author**: user + game-designer (creative seat, GLM-5.3-Flash) + systems-designer/gameplay-programmer (technical seat, DeepSeek V4.1 Flash)
> **Last Updated**: 2026-11-12 (design review + in-session revision)
> **Design Review**: NEEDS REVISION (2026-11-12) → revision applied; record at `design/gdd/reviews/combat-review-log.md`
> **Implements Pillar**: "Read, Then Strike" (every threat telegraphs; the clash is optional mastery) · "SotN, Not Hollow Knight" (committed weight, deliberate exchange) · "Remade Every Death" (the body's commitments are honest, so death is never a mishearing)
> **System ID**: SYS-08 (Core layer, MVP)
> **Contracts**: ADR-0001 — Input Architecture (Accepted 2026-11-12); SYS-01 `design/gdd/input-control-mapping.md` (UNFROZEN, #10 record) — TR-INP-013/014/019/020/021/022/024/028/029/047/056/057/066/070/075/076, F-01/F-05/F-07/F-08, EX-1/EX-5, AC-18/AC-65; SYS-06 `design/gdd/movement.md` (APPROVED 2026-11-12) — `facing`/`grounded`/`body_busy`, `crouch_effective` + posture-carry, `KnockbackOrder {dir, power}`, `KNOCKDOWN_POWER`, `BACKDASH_IFRAME_MS`, derived `worst_case_arc_ms` 1200, `move_refused`, `freeze_hold`.

## Overview

The Combat system is the exchange half of the trust contract: it turns SYS-01's honored attack presses and SYS-06's committed body into a deliberate, readable fight. It owns the attack arcs (ATK1 → ATK2, crouch, air), the chain point and combo custody, the clash — eligibility, power comparison, counter-clash, double clash, the lose branch — projectile deflect, the player's commitments (attack arc, clash lock, stagger, hit-stop pairing), the defensive family's i-frame grants (backdash 140 ms, Dash 0, clash 0, getup 300 ms), the `DamageEvent`/`KnockbackOrder` boundary to SYS-07/SYS-06, and the enemy-strike contract it consumes from SYS-13. It never reads `Input` directly and never owns HP: input promises the press, Combat promises the answer, SYS-07 owns the number. Without it the game loses the pillar's central bet — a fight where the read is the skill, the clash is the reward, and mashing is never the answer.

→ *Implementation patterns (CombatCore reducer, hitbox probes, commitment publication, the freeze pairing) are ADR raw material for the planned **Combat Architecture ADR**; this GDD stays at the behavior level. The input contracts it consumes are ratified by **ADR-0001**; the body contracts by the approved **Movement GDD**.*

## Player Fantasy

### The named fantasy — The Body Answers the Read

You read; she answers. Combat here is a conversation you can study. Every threat speaks first — a flash of color, a lean of shape — and every strike you throw is a written reply, delivered with SotN weight: signed, carried, finished. You are never asked to be fast; you are asked to be attentive. When your answer meets their strike on purpose, the clash turns the conversation into a duet — sparks, lock, the double-beat — and when your answer was early and true, it does not just stop their strike, it lands in them. Nothing in combat is a reflex test. The floor is deliberation; the ceiling is the early press, honored. The body never answers faster than your read earned, and never answers something you didn't see.

### The contract — the read, the clash, the commitment, the family

Four terms, each testable:

1. **The read is guaranteed.** Every enemy strike telegraphs in one shared language — color-flash plus shape lean, never opacity tricks. Nothing lands that was not shown. No "unreadable but fair" exceptions. The telegraph's timing and palette belong to SYS-13; the promise that it precedes the strike belongs to Combat.
2. **The strike is whole.** A signed attack carries through its arc — lift, swing, recovery — interrupted only honestly (a clash, a stagger, a gate), never half-cancelled by a new idea. The two-hit combo has a learnable chain point; mid-air versions obey the same promise. A hit that lands on her cancels the arc; that is the cost of signing.
3. **The clash is a dialogue.** Press as their strike arrives — a breath early. Answer heavier → they stagger and your counter lands. Evenly matched → weapons lock, the clash beats twice, neither yields. Answer lighter → you are staggered. Deflected projectiles fly back and can strike other enemies. The clash denies the exchanged strike; it is not a shield.
4. **The commitment is published.** When strikes meet, the world holds its breath for a beat, and the body is visibly committed through it. Impact reads as weight, always. The body that answers is the body the world hits — no invisible states.

**The defensive family** is three honest answers to "I am about to be hit": **backdash** (hop away untouchable, eyes forward), **clash** (deny the hit at the exchange), **Dash** (reposition — never invulnerability). **Crouch** is a posture read outside the i-frame family: it makes high arcs miss, and it is the low answer. The family's roles stay distinct; no member does another's job.

**Trust is inherited, not restated.** A press made within a breath of the exchange is kept and answered on the frame it was meant for. Combat adds no second-guessing of what Input promised. The Early Press's window is SYS-01's; the answer is Combat's.

### Anchor moment — The Early Press

A heavy enemy winds a wide overhead. You read it and press Attack a breath early. The body holds the order; at contact the exchange resolves — sparks, lock, the double-beat — or, if your read was the deeper one, your counter lands with damage: the reward for the early press is that it hurts them. The read was early; the answer was on time.

### Anchor moment — The Backdash That Faces the Threat

A strike commits; you flick back. She hops out of its arc untouched and keeps her eyes on the enemy, so the next read is already aimed — and the player who privately learned the untaught chain can answer out of the hop with the Stinger's lunge. The dodge buys the second read; the game never says so.

### Anchor moment — The Low Read

She settles into crouch beneath the high arc; the strike passes over the crouch the world actually hits; her answer from below is a true punish, not a consolation. The posture was yours; the hurtbox was the body's.

### Language law

**Use:** read, telegraph, answered, honored, committed, whole, weighty, SotN-weight, exchange, deliberate, earned, breath (for timing windows), honest.

**Ban:** crisp, snappy, instant, frame-perfect, razor-thin, zero-lag, twitch, reflex, "perfect timing," "just dodge," reaction speed.

"Precision" is the body's property, never the player's demand. Timing windows are "a breath" in player-facing copy; no millisecond talk reaches the player. Telegraph doctrine is color-flash + shape lean; opacity pulses are banned language and banned craft. Falsifiability rule: every feel-sentence must be verifiable by playtest or build check; if verifying it would need a stopwatch on reflexes, cut it.

### Success signature

Playtesters say: "I saw it coming"; "I knew when to hit it"; "I pressed a little early and it still worked"; after mashing and losing an exchange, "it answered my last press" (the cost self-attributed); the clash described in duet words — sparks, lock, the double-beat — never as "frame perfect"; "backdashing kept her facing them"; Dash described as "getting somewhere," never as "not getting hit"; "when I timed it, it hurt them"; someone discovers the untaught chain live — "wait— you can— oh. OH."; nobody asks for a dodge-roll, a parry button, or an invincible dash.

*Pillar ties: "Read, Then Strike" (the clash is optional mastery, never a requirement) · "SotN, Not Hollow Knight" (committed weight over twitch) · "Remade Every Death" (an honest body makes death a story, not a mishearing).*

## Detailed Design

### Core Rules

**Rule IDs (`TR-CMB-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** PROVISIONAL marks indicate contracts with undesigned downstream GDDs; ownership boundaries are intended final. **No direct `Input` reads; no new verbs; no ninth body verb.**

#### 1 · The combat contract — consume, never poll

- **TR-CMB-001 — Consume, never poll.** SYS-08 consumes attack presses through the InputBus (`PulledIntent {verb, press_tick, snapshot, gesture_tag}`); it never calls `Input.*`. The attack override is `ATTACK_WINDOW_MS = 200` (12 ticks at 60 tps), set through SYS-01's override hook; the global `INTENT_WINDOW_MS` stays 140. Combat pulls the held attack at the strike-contact frame (TR-INP-020) or the chain point; the intent's `press_tick` and supersede recency are exposed (TR-INP-022's handoff). The attack hitbox is placed on the published `facing` side, read at the pull. *Test: a mocked intent stream behaves identically to a human capture; `src/combat/` contains no direct-Input symbol (CI grep); the hitbox side follows `facing`.*
- **TR-CMB-002 — No new verbs, no ninth body verb.** Attack, crouch attack, air attack, clash and deflect are Combat states produced from (verb press + body state); they add zero registry entries. The eight body verbs are SYS-01's. *Test: the registry diff is empty; input-layer files unchanged.*
- **TR-CMB-003 — Data-driven arcs.** Every phase, damage, power, lock, hit-stop, i-frame, multiplier and hitbox is a Tuning Knob; no gameplay literal in code. *Test: changing a knob changes behavior with no code edit.*

#### 2 · The attack arcs

- **TR-CMB-004 — The arc table.** Combat owns four arcs: **ATK1** (90/70/170 ms; damage 10; power 1), **ATK2** (100/80/250 ms; damage 20; power 2), **crouch attack** (80/60/150 ms; damage 8; power 1; low hitbox), **air attack** (80/70/120 ms; damage 10; power 1; landing cancels the remaining arc and applies `AIR_LANDING_LAG_MS = 100`). Phase ticks are derived by F-CMB-01; the active window is inclusive; the chain point is the first tick after ATK1's active window. *Test: the 60-tps fixtures (ATK1 6/5/11 = 22 ticks; ATK2 6/5/15 = 26; crouch 5/4/9 = 18; air 5/5/8 = 18); phase boundaries at the exact tick.*
- **TR-CMB-005 — Chain point and combo custody.** A pending attack at ATK1's chain point starts ATK2 on that tick and cancels the remaining ATK1 recovery; a press after the chain point does not chain (it opens a new window and starts a new ATK1 after recovery). The press may be up to `ATTACK_WINDOW_MS` early — the 200 ms override resolves the prototype's 160 > 140 lesson. ATK2 is the finisher; no ATK3 at MVP. Custody is TR-INP-075's: the pull consumes the slot, Combat holds the honored intent through the arc, input never re-offers. *Test: a press at ATK1's first startup tick chains; a press one tick after the chain point does not; one press = one resolution; the slot clears at the ack.*
- **TR-CMB-006 — Crouch + attack.** The derived-move selection reads the **raw** `crouch` channel (`latch ∨ held_zone`) at the pull (the consumption frame); the stamp-tick snapshot rides as context. A release before the pull selects the stand attack (SYS-01 AC-56). The **hurtbox** reads Movement's `crouch_effective` and the posture-carry: an **attack** commitment pulled while the raw crouch is true carries the crouch posture for its duration, so the crouched hurtbox is present on the commitment's first tick and a crouch attack never shows a standing hurtbox. The locomotion commitments (dash, jump, hop) stand her up instead; posture-carry never applies to them. The crouch attack's hitbox is low; the high/low read is against SYS-13's strike height. *Test: SYS-01 AC-56's trace; AC-MOV-43's first-active-tick hurtbox; a release mid-window yields the stand attack while the snapshot still logs `crouching = true`.*
- **TR-CMB-007 — Air attack.** Airborne + attack → the air arc; no air combo at MVP; no steering. The air attack is a whole arc, not a chain. Landing during the air attack cancels the remaining active/recovery and applies `AIR_LANDING_LAG_MS` as a Combat commitment. *Test: a landing mid-air-attack applies the 100 ms lag; the air attack never chains; the body is busy through the lag.*

#### 3 · The clash

- **TR-CMB-008 — Clash eligibility (the press-age gate).** A clash is possible when (a) the enemy strike's hitbox contacts the player's hurtbox at `contact_tick` — the pull tick; (b) the press-age gate passes at the pull: for a discrete tap, `CLASH_MIN_AGE_TICKS = 5 ≤ age ≤ CLASH_MAX_AGE_TICKS = 12`; for a hold-repeat stream, `age ≥ 5` (the upper bound is waived — the repeats keep the order alive); and (c) the attack's **projected** active window (start at `contact_tick + startup_ticks`) still overlaps the enemy's active window — the enemy's remaining active window must be ≥ the attack's startup + 1 tick. A fresh press (age < 5) is not eligible. The clash resolves at the attack's projected active start; the hit-stop/lock starts there. *Test: age 4 loses, 5 passes, 12 passes, 13 is not offered; a fresh press is ineligible; the projected active start is `contact + startup`; the enemy's active must cover it.*
- **TR-CMB-009 — Clash resolution.** With eligibility: `player_power > enemy_power` → **counter-clash**; `=` → **double clash**; `<` → **lose**. Without eligibility or overlap → **no clash** (the normal hit/whiff resolves). The clash is grounded-only at MVP (an air attack hits or whiffs; no air clash). *Test: the four branches resolve exactly once; the power comparison uses the strike powers, never the damage values.*
- **TR-CMB-010 — Counter-clash damage (the reward).** The counter deals `floor(ATK.damage × COUNTER_CLASH_MULT)` with `COUNTER_CLASH_MULT = 1.5` (provisional; SYS-07 ratifies the economy): ATK1 15, ATK2 30 at defaults. The enemy is staggered (SYS-13's `ENEMY_STAGGER_MS = 800`); the player's attack arc completes; hit-stop 90 ms. *Test: ATK1 15 / ATK2 30; the enemy stagger order; no clash lock on the counter branch.*
- **TR-CMB-011 — Double clash (the duet).** Equal powers: both weapons lock for `CLASH_LOCK_MS = 700` (42 ticks); no damage; two spark pulses within the lock (the double-beat); hit-stop 90 ms. Both bodies are committed for the lock; the player's attack is consumed; after the lock both are free. *Test: 700 ms; zero damage; both `body_busy`; the second spark pulse at the lock midpoint; no second resolution.*
- **TR-CMB-012 — The lose branch.** Player power < enemy power: the enemy strike's damage applies; the player is staggered for `STAGGER_MS = 500` (30 ticks); the player's attack is cancelled; hit-stop 90 ms; the enemy continues its recovery. The lose branch publishes the `DamageEvent` but **no `KnockbackOrder`** — the 500 ms Combat stagger replaces the hit reaction (the weapons met; the player lost the lock, not a clean hit); the enemy's `power` does not drive Movement's `KNOCKDOWN_POWER` on this branch. *Test: the damage event; the 500 ms stagger; no knockback order; the attack arc dies; the enemy's recovery continues.*
- **TR-CMB-013 — The mash cost (the Fresh Press rule).** A fresh press (age < `CLASH_MIN_AGE_TICKS`) is not clash-eligible: the strike lands, the attack is cancelled, the hit reaction applies. The cost is player-observable — the lost clash, the strike connecting, the hit reaction — never a silent stat. The anti-mash guarantee is SYS-01's TR-INP-022 handoff: mash-through-windup is **weakly dominated**; the single deliberate early press wins, the mash fails or pays. *Test: a 12 t/s mash loses the clash; a single early press at the same contact wins; the GUT sweep on AC-20's harness (the D6/B11 handoff) shows at least one arc timing where the single press wins and the mash fails.*
- **TR-CMB-014 — Hold-repeat exemption (a11y).** The `ATTACK_HOLD_REPEAT` stream (SYS-01 AC-49) is exempt from the freshness cost, not from the read: the gate uses the hold's **origin** (`stream_origin_tick`), the repeats do not re-origin the order, and the power comparison still applies. The hold's selected arc at the pull is ATK1 (power 1) unless the combo state is already ATK2; the hold cannot *choose* ATK2, but a chained ATK2 still uses its power 2. The origin resets when the order is consumed (a clash/attack) and the stream re-origins on the first repeat after the body is free. *Test: a hold whose origin is ≥5 ticks survives; a hold does not auto-win a power-2 exchange; a direct tap still pays the freshness cost; the origin resets on consumption.*
- **TR-CMB-015 — Projectile deflect.** The player's attack active window overlapping a projectile's hitbox, with the same age gate, deflects it: the projectile reverses at `DEFLECT_SPEED = 360` px/s, its owner flips to the player, its damage is the projectile's original damage (8 at the prototype default), friendly fire applies, and the deflect hit-stop is 40 ms. A fresh press does not deflect. *Test: the reversal; the deflected orb damages an enemy; the fresh press is hit; the 40 ms freeze.*

#### 4 · The defensive family

- **TR-CMB-016 — Backdash i-frames.** Combat grants `BACKDASH_IFRAME_MS = 140` (9 ticks; 150 ms effective) from the hop's first tick; Movement executes the hop and the lock. The 280 ms lock leaves an **8-tick exposure**; chained hops can never be continuously invincible. *Test: the 140/9/8 fixture; a hit inside the i-frames is negated; a hit in the exposure lands; the Movement F-MOV-07 arithmetic.*
- **TR-CMB-017 — Dash 0 i-frames.** Dash is reposition, not a second dodge: ground-only, `DASH_MS = 200`, `DASH_SPEED = 420`, `DASH_COOLDOWN_MS = 500`, no i-frames at MVP; dashing into a strike is a hit. Dash's traversal job (dash-jump) is Movement's. *Test: a hit during the dash lands; the dash publication contains no i-frame field.*
- **TR-CMB-018 — Clash 0 i-frames.** The clash negates the **exchanged** strike, not all damage: the lock is mutual and body-committed; a third strike during the lock lands (the body is committed). There is no shield window around the clash. *Test: a second enemy strikes during the double clash; the damage applies; the player's lock dies, the hit reaction applies.*
- **TR-CMB-019 — Getup i-frames.** Combat grants `GETUP_IFRAME_MS = 300` (18 ticks) from the getup's first tick; the remaining 400 ms of the 700 ms getup is exposed. The no-re-knockdown rule is Movement's; the getup grant prevents the can't-act punish. *Test: a hit in the first 300 ms is negated; a hit after lands; the Movement GETUP arc is unchanged.*
- **TR-CMB-020 — The defensive-family ruling (EX-1/D-5).** MVP ships **drop-when-busy** for the backdash; Combat adds no deferred-hop queue; the short-defer amendment is a recorded VS question. *Test: a busy completion produces a still body and no motion; no queue exists.*

#### 5 · Commitments and the clock

- **TR-CMB-021 — Commitments and `body_busy`.** Combat publishes **five** commitments as levels (`start_tick` through `end_tick−1`): the attack arc, the air landing lag, the clash lock, the player stagger, and the hit-stop pair. The OR is `body_busy` (F-08); Combat declares `worst_case_arc_ms = max(arc_ms, air_landing_lag_ms, clash_lock_ms, stagger_ms) = 700` at registration, re-declared on every arc edit, validated by SYS-01's TR-INP-029 rules. The combined `body_busy` max is **1200** (Movement's knockdown). *Test: the level semantics; the declaration equals the derived max (700 at defaults); the combined max is 1200; a publisher raises/clears mid-window.*
- **TR-CMB-022 — Hit-stop and the paired commitment.** Hit-stop is SYS-29's clock; Combat pairs every source with a commitment: hit 70 ms (5 ticks; 83.3 effective), clash 90 ms (6; 100), deflect 40 ms (3; 50). Every freeze source publishes a commitment for the freeze's duration (ADR-0001's hit-stop⇒body-committed invariant); an idle body is covered by Movement's `freeze_hold`. *Test: the 5/6/3 tick conversion; no freeze exists without a published commitment; the pair survives the freeze.*
- **TR-CMB-023 — Freeze integration.** Combat timers (arc, lock, stagger) run on `logic_tick`; a freeze holds them; Combat does not pull or start arcs during freeze; raw publications continue. The freeze is a clock, not a gate. *Test: a mid-arc freeze holds the remaining duration; no new arc starts frozen; the commitment stays published.*
- **TR-CMB-024 — Gates.** At gate entry, Combat arcs die; no damage or motion is applied on the transition frame; held states persist; on resume the body is IDLE and nothing is queued. *Test: pause mid-arc → no damage on the transition frame; resume IDLE; no queued attack.*

#### 6 · Damage, knockback, death

- **TR-CMB-025 — The damage boundary.** Combat publishes `DamageEvent {source, target, raw_damage, kind ∈ {NORMAL, COUNTER, DEFLECT, ENEMY_STRIKE}, contact_tick}`; SYS-07 owns HP, damage application, death and respawn. Combat never subtracts HP. The Combat GDD's damage values are provisional until SYS-07 ratifies the economy. *Test: a SYS-07 mock receives the event; Combat's state contains no HP field; death is SYS-07's edge.*
- **TR-CMB-026 — The knockback order.** Combat sends `KnockbackOrder {dir, power}` to Movement: `dir = sign(target_x − source_x)` (away from the attacker), `power = strike.power` — the single strike power; the enemy contract has no separate `knockback_power`. Movement executes the motion and the lock; `KNOCKDOWN_POWER = 2` is consumed by Movement (a player hit with power ≥ 2 enters KNOCKDOWN on the hit tick; below runs KNOCKBACK). The player's ATK1/crouch/air power is 1; ATK2 is 2. The clash-lose branch publishes no `KnockbackOrder` (TR-CMB-012). *Test: a power-2 enemy strike → knockdown; power 1 → knockback; the order's direction; the 1200 ms arc; the lose branch publishes no order.*
- **TR-CMB-027 — No re-knockdown.** During KNOCKDOWN or GETUP a further hit applies damage but starts no new lock (Movement's rule); Combat may grant the 300 ms getup i-frames. *Test: a second heavy hit during GETUP deals damage, no new lock; the getup grant covers the first 300 ms.*

#### 7 · The enemy strike contract

- **TR-CMB-028 — The enemy strike contract.** Every enemy strike publishes `{power ∈ 1…3, active_ms, telegraph_ms, hitbox}`; SYS-13 owns the values, Combat consumes them. `active_ms` must be ≥ 84 ms (6 ticks at 60 tps) for the clash to be possible — the fastest startup is 5 ticks and the enemy's active must cover the startup + 1 tick; the specific clashability is `remaining active ≥ startup + 1`. A shorter strike is flagged **unclashable** and the GDD records it. The telegraph must precede the active window by `telegraph_ms`; the MVP threats must be answerable with **backdash · clash · crouch** (Dash is locked). *Test: a mock contract; the unclashable flag; the telegraph precedes the active; the answerability review at SYS-13.*
- **TR-CMB-029 — Multi-enemy resolution order.** The first contact in the tick resolves; ties break by entity id. The clash lock does not protect against a third strike: the other strikes resolve normally, and a hit during the lock cancels the player's lock and applies the hit reaction. *Test: two enemies strike the same tick — one clashes, the other hits; ties by id; the lock dies on the hit.*
- **TR-CMB-030 — Telegraph language.** Every enemy strike telegraphs with color-flash + shape lean; opacity pulses are banned. SYS-13 owns the timing and palette; Combat's contract requires the telegraph to be readable before the active window. *Test: the static audit finds zero opacity-pulse telegraphs; the SYS-13 mock's telegraph precedes the active.*

#### 8 · Testability and performance

- **TR-CMB-031 — Testability.** Split the seam: **`CombatCore`** is a pure reducer over an injected `CombatBodyPort` (`probe_hurtbox`, `probe_enemy`, `apply_damage`, `apply_knockback`, `apply_stagger`, `publish_commitment`) and a `CombatClockPort`; `FakeCombatBodyPort` is the GUT fixture, the play implementation binds SYS-06/SYS-07/SYS-13/SYS-29. Fixed 60 tps. *Test: bit-identical traces under the fake; the same fixture repeats bit-identically.*
- **TR-CMB-032 — No direct Input reads.** `src/combat/` contains zero `Input.` symbols; Combat consumes the InputBus and `PulledIntent` only. *Test: CI grep; a mocked intent stream.*
- **TR-CMB-033 — Performance and allocation.** No hot-path allocation; the combat structures are preallocated and bounded (the active arc, the commitment set, the contact list, the trace ring); the AC-CMB perf bars. *Test: the 10,000-tick soak; the reference-SKU device bar; the named-structure high-water marks.*
- **TR-CMB-034 — Traceability.** Every TR-CMB has an AC or a recorded guidance note; every formula has an AC; the IDs are stable; no `[To be designed]`. *Test: the traceability audit.*

### States and Transitions

Combat's player states are orthogonal to Movement's locomotion: a Combat state is a **commitment** on top of the body.

| State | Enter | Exit | body_busy |
|---|---|---|---|
| **COMBAT_IDLE** | no Combat commitment | attack pulled; clash; stagger; hit | no |
| **ATTACK_ATK1** | attack pulled on the ground | chain at the chain point; recovery end; hit; gate | yes |
| **ATTACK_ATK2** | chain point + pending attack | recovery end; hit; gate | yes |
| **ATTACK_CROUCH** | crouch attack pulled | recovery end; hit; gate | yes |
| **ATTACK_AIR** | air attack pulled | landing (lag); recovery end; hit; gate | yes |
| **CLASH_LOCK** | double clash | lock end; third hit; gate | yes |
| **STAGGER** | clash lose | stagger end; gate | yes |
| **HITSTOP_PAIR** | a freeze source with a commitment | unfreeze | yes (paired) |
| **DEAD** | SYS-07's death edge | respawn (Movement's DISABLED) | yes (context) |

**Transition laws.**

1. **One arc at a time.** An attack arc cannot be interrupted by a new attack; the chain is the only continuation. A new press during an arc opens a window for the chain point or the next arc; it never cancels the current arc.
2. **A hit wins.** A hit that lands on the player cancels the attack (or the clash lock, or the stagger) and applies the hit reaction; the arc dies; no double commitment.
3. **The clash lock is mutual and committed.** It is entered only from the clash resolution; it cannot be entered from a hit or a stagger. The lock is not invulnerability; a third strike cancels it.
4. **Gate entry clears Combat.** No Combat state survives a gate entry; no damage or motion on the transition frame; on resume COMBAT_IDLE.
5. **Freeze holds, never clears.** A freeze holds the arc/lock/stagger timer; the commitment stays published; no new arc starts frozen.

### Interactions with Other Systems

| Contract | SYS-08 owns | Consumer owns |
|---|---|---|
| **Attack presses** | the pull at the contact/chain point; the arc; the clash | SYS-01: the window (200 ms override), the stamp, the custody, the supersede record |
| **Crouch + attack** | the selection from the raw channel; the crouch hurtbox read; the low hitbox | SYS-01: the raw `crouch` channel; SYS-06: `crouch_effective` + posture-carry |
| **`body_busy`** | the Combat commitments (arc, lock, stagger, hit-stop pair); the 700 ms declaration | SYS-01: the OR; SYS-06: the locomotion locks |
| **Knockback** | the vector/power computation; the order | SYS-06: the motion and the lock; SYS-07: the HP/damage/death |
| **Damage** | the `DamageEvent`; the provisional values | SYS-07: HP, damage, death, respawn |
| **Enemy strikes** | the clash/deflect resolution; the counter/stagger orders | SYS-13: the strike contract, telegraphs, AI; SYS-14: boss rules |
| **i-frames** | the grants: backdash 140, Dash 0, clash 0, getup 300 | SYS-06: the hop/getup execution; SYS-01: the input's body-free checks |
| **Hit-stop** | the pairing; the commitment | SYS-29: the clock; SYS-32: the camera shake; SYS-04: the audio |
| **Gates** | the arc death at gate entry | SYS-05: the context; SYS-01: the gate enforcement |
| **HUD/haptics** | the commitment state for the HUD/haptic hooks | SYS-24: the visuals; SYS-29: the haptic IPC |

- **SYS-01 Input (upstream, hard):** attack presses + snapshots + `press_tick`/supersede; the 200 ms override; custody; `crouch` raw; the `body_busy` OR; the gate manifest. **No direct `Input` reads.**
- **SYS-06 Movement (upstream, hard):** `facing`/`grounded`/`body_busy`; `crouch_effective` + posture-carry; `KnockbackOrder` execution; `KNOCKDOWN_POWER`; `BACKDASH_IFRAME_MS`; the derived 1200 ms; `move_refused`; `freeze_hold`.
- **SYS-07 Health & Damage (downstream, hard at hit time):** HP, damage application, death/respawn; the `DamageEvent` boundary.
- **SYS-13 Enemy AI & Telegraphs (upstream, hard for strikes):** the enemy strike contract; the telegraph; the AI. Combat never designs enemy moves.
- **SYS-29 Juice (upstream for the freeze, downstream for the VFX):** the hit-stop clock; the haptic channel; the clash sparks.
- **SYS-05 Game Flow (coordination):** the contexts and gates.
- **SYS-24 HUD (downstream, soft):** reads the commitment state; no Combat-owned HUD.
- **SYS-14 Grief-Boss (downstream, soft):** the boss interaction rules; the arena locks.
- **SYS-12 Stinger (VS):** the composite gesture's combat interaction; no MVP dependency.
- **SYS-16 Progression (soft):** the ability grants (Dash, Wall Jump, Double Jump) are Movement's; Combat reads the body state.

### ADR-0001 + SYS-01 Contract Ratification (Combat side)

| Contract | Combat's obligation | Test |
|---|---|---|
| Attack presses + stamp snapshots + `press_tick`/supersede | Pull at the contact/chain point; expose the age; never read `Input`; the 200 ms override | TR-CMB-001/005; AC-CMB-01/05 |
| Crouch raw is the selection input; `crouch_effective` is the hurtbox | Select from the raw channel at the pull; read the applied posture for the hurtbox; posture-carry | TR-CMB-006; AC-CMB-07/08 |
| `body_busy` OR + `worst_case_arc_ms` | Publish the commitments as levels; declare 700; coordinate with Movement's 1200 | TR-CMB-021; AC-CMB-26 |
| Hit-stop⇒body-committed | Pair every hit-stop source with a commitment; no freeze without one | TR-CMB-022; AC-CMB-27 |
| Gate terminality | Arcs die at gate entry; no damage/motion on the transition frame | TR-CMB-024; AC-CMB-29 |
| Custody (TR-INP-075) | Hold the attack through the arc; no re-offer; the slot clears at the ack | TR-CMB-005; AC-CMB-06 |
| Backdash drop-when-busy (EX-1/D-5) | Add no deferred-hop queue; ratify the drop | TR-CMB-020; AC-CMB-25 |
| No new verbs | All Combat states are over the eight verbs | TR-CMB-002; AC-CMB-02 |
| Damage boundary | Publish `DamageEvent`; never own HP | TR-CMB-025; AC-CMB-30 |

## Formulas

Combat's formulas are **arc laws** (phase ms → ticks), **exchange laws** (overlap → contact → clash), and **commitment laws** (lock, stagger, hit-stop, i-frames). Three laws govern every formula:

- **Named-symbol law.** Every literal appears here only as a named symbol; values live in exactly one place — the Tuning Knobs table.
- **Never-stingy boundary law.** Every boundary comparison is inclusive on entry, strict on exit: a window engages at `≤`/`≥` the threshold; leaving requires strictly beyond the exit counterpart.
- **Clock law.** All Combat timing runs on `logic_tick`; hit-stop freezes it; gates stop it. Wall-clock is for UI feel only.

**Formula ledger — law vs knob.**

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-CMB-01 | phase_to_ticks | True law | `physics_tps` |
| F-CMB-02 | attack_arc | True law | the four arcs' phase ms; `CHAIN_POINT` derived |
| F-CMB-03 | clash_contact | True law | the active windows; the hurtboxes; the projected startup |
| F-CMB-04 | press_age_gate | Threshold law | `CLASH_MIN_AGE_TICKS`, `ATTACK_WINDOW_MS` |
| F-CMB-05 | clash_resolution | True law | `power` (both sides) |
| F-CMB-06 | counter_damage | True law | `COUNTER_CLASH_MULT`, `ATK.damage` |
| F-CMB-07 | hitstop_ticks | True law | the three hit-stop ms |
| F-CMB-08 | iframe_window | True law | `BACKDASH_IFRAME_MS`, `GETUP_IFRAME_MS`, `DASH_IFRAME_MS` |
| F-CMB-09 | knockback_order | True law | `power`; the positions |
| F-CMB-10 | deflect | True law | `DEFLECT_SPEED`; the projectile's damage |
| F-CMB-11 | commitment_publication | True law | the arc/lock/stagger ms |
| F-CMB-12 | combo_custody | True law | `ATTACK_WINDOW_MS`; the chain point |

#### F-CMB-01 · phase_to_ticks — the conversion (TR-CMB-004)

`phase_ticks = ceil(phase_ms × physics_tps ÷ 1000)` · `arc_ticks = Σ phase_ticks`

**Variables:** `phase_ms` int 1–5000; `physics_tps` int (60 pinned); `phase_ticks` int ≥ 1. **Output:** the phase boundaries; effective duration ≥ the ms contract, overshoot ≤ 1 tick. **Example:** 90 ms → 6 ticks; 70 → 5; 170 → 11.

#### F-CMB-02 · attack_arc — the four arcs (TR-CMB-004)

`startup_ticks = ceil(startup_ms × tps ÷ 1000)` · `active_ticks = ceil(active_ms × tps ÷ 1000)` · `recovery_ticks = ceil(recovery_ms × tps ÷ 1000)` · `active_start = start_tick + startup_ticks` · `active_end = active_start + active_ticks − 1` · `chain_point = active_end + 1` · `arc_end = active_end + recovery_ticks + 1` (exclusive; the last busy tick is `arc_end − 1`)

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Startup | `startup_ms` | int | 60–140 | The lift; committed |
| Active | `active_ms` | int | 50–120 | The swing; the hitbox window |
| Recovery | `recovery_ms` | int | 100–300 | The cost of signing |
| Chain point | `chain_point` | int | derived | The first recovery tick; ATK2 may start here |
| Arc end | `arc_end` | int | derived | The last busy tick is `arc_end − 1` |

**Output at defaults:** ATK1 6/5/11 = **22 ticks** (366.7 ms); ATK2 6/5/15 = **26 ticks** (433.3 ms); crouch 5/4/9 = **18 ticks** (300 ms); air 5/5/8 = **18 ticks** (300 ms). **Example:** ATK1 start 1000 → active 1006–1010 → chain point 1011 → arc end 1022 (exclusive; the last busy tick is 1021).

#### F-CMB-03 · clash_contact — the pull and the projected answer (TR-CMB-008)

`contact_tick` = the enemy strike's first hitbox/hurtbox contact (the pull tick) · `projected_active_start = contact_tick + startup_ticks` · `projected_active_end = projected_active_start + active_ticks − 1` · `clash_resolves = (projected_active_start ≤ enemy_active_end) ∧ hurtbox_overlap` · `clash_tick = projected_active_start`

**Output:** the clash resolves at the attack's projected active start; the enemy's active window must cover it (`remaining active ≥ startup + 1`). No overlap → no clash (the normal hit/whiff resolves). **Example:** the enemy's strike contacts the player at 1008; ATK1's startup is 6 ticks → the projected active is 1014–1018; the enemy's active 1008–1015 covers 1014 → the clash resolves at 1014 (2 ticks of the enemy's active remain). A 4-tick enemy active (1008–1011) cannot be clashed by a 6-tick startup.

#### F-CMB-04 · press_age_gate — the breath (TR-CMB-008/013/014)

`age = pull_tick − origin_tick` · `pull_tick = contact_tick` · discrete tap: `clash_eligible = 5 ≤ age ≤ 12` · hold-repeat: `clash_eligible = age ≥ 5` · `origin_tick` = `press_tick` (tap) or `stream_origin_tick` (hold)

**Variables:** `pull_tick` int; `press_tick` int; `stream_origin_tick` int; `CLASH_MIN_AGE_TICKS` 5; `CLASH_MAX_AGE_TICKS` = `ATTACK_WINDOW_MS` in ticks (12). **Output:** boolean; age 5 and 12 inclusive; 4 loses; 13 is not offered (the window expired). **Example:** press 2000, the enemy's strike contacts at 2008 → age 8 → eligible; the clash resolves at 2014 (ATK1 startup 6). Press 2006, contact 2008 → age 2 → fresh → loses.

#### F-CMB-05 · clash_resolution — the matrix (TR-CMB-009)

`if ¬clash_eligible ∨ ¬hit → NO_CLASH` · `elif player_power > enemy_power → COUNTER` · `elif player_power = enemy_power → DOUBLE` · `else → LOSE`

**Output:** exactly one of the four; the power comparison uses the strike powers (player ATK1/crouch/air 1, ATK2 2; enemy 1–3). **Example:** ATK2 (2) vs enemy power 1 → COUNTER; vs 2 → DOUBLE; vs 3 → LOSE.

#### F-CMB-06 · counter_damage — the reward (TR-CMB-010)

`counter_damage = floor(ATK.damage × COUNTER_CLASH_MULT)`

**Variables:** `ATK.damage` 8–20; `COUNTER_CLASH_MULT` 1.5 (1.2–2.0). **Output:** ATK1 15, ATK2 30 at defaults. **Example:** ATK2 20 × 1.5 = 30; the enemy's HP is SYS-07's.

#### F-CMB-07 · hitstop_ticks — the beat (TR-CMB-022)

`hitstop_ticks = ceil(hitstop_ms × tps ÷ 1000)`

**Output:** hit 70 → 5 ticks (83.3 ms); clash 90 → 6 (100 ms); deflect 40 → 3 (50 ms). **Example:** a clash request raised during tick 3000 makes 3000 the last stamped `logic_tick`; the next 6 physics ticks open frozen (3001–3006); the lock resumes at 3007 with its remaining duration.

#### F-CMB-08 · iframe_window — the grants (TR-CMB-016/019)

`iframe_ticks = ceil(iframe_ms × tps ÷ 1000)` · `invulnerable(t) = start_tick ≤ t < start_tick + iframe_ticks`

**Output:** backdash 140 → 9 ticks (150 ms); getup 300 → 18 (300 ms); Dash 0 → 0. **Example:** a hop at 4000 is invulnerable 4000–4008; the 8-tick exposure is 4009–4016; the lock ends at 4017.

#### F-CMB-09 · knockback_order — the body's answer (TR-CMB-026)

`dir = sign(target_x − source_x)` · `power = strike.power` · `KnockbackOrder {dir, power}`

**Output:** the order; Movement's F-MOV-10 executes (`d_kb` 16.9 px @ p1, 67.6 @ p2; lock 180 / 1200 ms). **Example:** a heavy at x 300 hits the player at x 340 → dir +1, power 2 → knockdown.

#### F-CMB-10 · deflect — the return (TR-CMB-015)

`deflect = (attack_active ∩ projectile_hitbox ≠ ∅) ∧ age_gate` · `deflected_speed = DEFLECT_SPEED` · `damage = projectile.damage`

**Output:** the projectile reverses, owner flips, friendly fire; hit-stop 40 ms. **Example:** an orb at 170 px/s is deflected to 360 px/s; it damages the shooter for 8.

#### F-CMB-11 · commitment_publication — the body's promise (TR-CMB-021)

`body_busy = OR(attack_arc, air_landing_lag, clash_lock, stagger, hitstop_pair)` · `worst_case_arc_ms = max(arc_ms, air_landing_lag_ms, clash_lock_ms, stagger_ms)` · `start_tick`/`end_tick` level semantics (busy on start through end−1)

**Output:** 700 ms at defaults; the combined max with Movement is 1200. **Example:** a clash lock at 5000–5041 is busy 5000–5041 (42 ticks); `end_tick` 5042; the Interact derivation for a clash-busy body uses 700 + margin.

#### F-CMB-12 · combo_custody — the chain (TR-CMB-005)

`chain_ok = pending_at(chain_point) ∧ ¬consumed` · `ATK2.start = chain_point` · `custody` held through the arc

**Output:** one resolution per press; the 200 ms window covers the earliest startup press. **Example:** ATK1 starts 1000; a press at 1002 is pending at 1011 → ATK2 starts 1011; a press at 1012 opens a new window for the next ATK1.

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### Commitments and arcs

- **If attack is pressed during ATK1's startup** → it is held (200 ms override); at the chain point it starts ATK2; no double fire. [The prototype's 160 > 140 lesson is resolved by the override, not a longer global window.]
- **If attack is pressed after the chain point** → no chain; the press opens a new window and starts a new ATK1 after recovery if it survives; otherwise it expires silently. [One arc at a time.]
- **If attack is pressed during recovery** → the same rule: the chain point has passed; the press waits for the next arc or expires.
- **If crouch + attack are pulled on the same tick** → the crouch attack; `crouch_effective` is CROUCHING on the first active tick; the hurtbox is crouched (posture-carry). [SYS-01 AC-56 + AC-MOV-43.]
- **If crouch is released during the crouch attack** → the attack completes as a crouch attack; the posture-carry keeps the hurtbox crouched for the arc. [The selection is at the pull.]
- **If crouch is released before the pull** → the stand attack executes; the stamp snapshot still logs `crouching = true`. [The consumption frame governs.]
- **If an air attack lands** → the remaining active/recovery is cancelled; `AIR_LANDING_LAG_MS` (100 ms) applies as a Combat commitment. [The air arc is not a ground combo.]
- **If attack is pressed during a dash** → the dash is body-busy; the attack waits; if the dash ends within the 200 ms window, it pulls; otherwise it expires. [Dash is a Movement lock, not a Combat cancel.]
- **If attack is pressed during a hop** → the press waits; if the body becomes free within the 200 ms window (a press in the lock's last 200 ms), it pulls at the lock's end; a press early in the 280 ms lock expires. [The hop is whole; the window still holds the late press.]
- **If attack is pressed during knockback/knockdown/getup** → the press waits; if the body becomes free within the 200 ms window (a press in the lock's last 200 ms), it pulls at the lock's end; a press early in the 1200 ms arc expires. [The body finishes what it signed; a late press is not lost.]

### The clash

- **If the contact is airborne** → no clash at MVP (grounded-only); the air attack hits or whiffs. [Air clash is a VS question; the lock's physics in the air is a new rule.]
- **If two enemies strike on the same tick** → the first contact resolves; the second resolves normally; the clash lock is not i-frames; a hit during the lock cancels it and applies the hit reaction. [The lock is mutual, not protective.]
- **If a melee strike and a projectile land on the same tick** → the first contact resolves; the other resolves normally; the player cannot clash both. [One exchange at a time.]
- **If the enemy's active window starts before the player's pull** → the player is late; the strike lands; no clash. [The read was late.]
- **If the attack's projected active start falls after the enemy's active end** → no overlap; no clash; the enemy strike resolves; the player's attack may hit the recovery. [The windows must meet: `remaining active ≥ startup + 1`.]
- **If a fresh press meets the contact** → the mash cost: no clash; the strike lands; the attack is cancelled. [The Fresh Press rule.]
- **If a hold-repeat stream meets the contact** → the origin gate applies; the freshness cost is waived; the power comparison still governs. [The a11y aid is a fatigue aid, not a clash cheat.]
- **If a hold begins before the telegraph** → the hold's origin is old; for a tap the window would have expired; the hold's repeats keep the order alive, but the power comparison still applies (ATK1 power 1 cannot counter a power-2 heavy). [Holding is not a win button.]
- **If a second attack is pressed during the clash lock** → the press waits; if the body becomes free within the 200 ms window (a press in the lock's last 200 ms), it pulls at the lock's end; a press early in the 700 ms lock expires. [The lock is whole; the window still holds the late press.]
- **If a backdash is attempted during the clash lock** → the body is busy; the hop drops (drop-when-busy); no defer. [EX-1/D-5.]
- **If a backdash is pulled at the exact contact tick** → the attack arc is body-busy; the hop drops. If the player is not attacking, the hop's i-frames negate the hit; no clash occurs. [The i-frame dodge is the alternative answer.]
- **If the player's i-frames cover the contact** → the enemy strike is negated; the clash does not resolve; the player's attack resolves normally. [VS/dead at MVP: the only i-frame sources (hop, getup) are body-busy, so an attack cannot be active through them; recorded for the VS air-clash/Stinger cases.]
- **If a crouch attack meets a high strike** → the high strike whiffs the crouched hurtbox; the crouch attack's low hitbox may whiff the high enemy hurtbox; no clash. [The high/low read.]
- **If a crouch attack meets a low strike** → the hitboxes overlap; the clash resolves by power. [The low exchange is real.]
- **If the player attacks an enemy during its windup** → the hit lands; the strike continues unless SYS-13's poise cancels it. [The clash is for the active strike; the windup hit is a different read. The heavy's poise is SYS-13's.]
- **If the player attacks a staggered enemy** → damage; no clash (no active strike); the stagger continues. [The punish window.]

### Defense, freeze, gates, death

- **If a hit lands during the backdash i-frames** → negated; the hop continues. **If it lands in the 8-tick exposure** → it lands; the hit reaction applies. [The 140/9/8 fixture.]
- **If a hit lands during the Dash** → it lands; Dash has 0 i-frames. [Reposition, not a dodge.]
- **If a third strike lands during the clash lock** → the damage applies; the player's lock dies; the hit reaction applies; the clash partner's lock is SYS-13's. [The lock is not a shield.]
- **If a hit lands during the first 300 ms of getup** → negated; after 300 ms it lands. [The getup grant.]
- **If hit-stop begins on a hit/clash/deflect** → the freeze holds the contact; the commitment stays published; the timer resumes with its remaining duration. [F-CMB-07/11.]
- **If a gate opens mid-arc** → the arc dies; no damage or motion on the transition frame; on resume COMBAT_IDLE; nothing queued. [TR-CMB-024.]
- **If death lands mid-arc** → SYS-07's death; Combat clears; Movement enters DISABLED; respawn resets. [SYS-07/15 own death.]
- **If a second heavy hit lands during GETUP** → damage applies; no new lock; the getup i-frames cover the first 300 ms. [No re-knockdown.]

### Rigs, a11y, values

- **If a direct tap and a hold-repeat repeat land on the same tick** → one intent; the SYS-01 slot outcome governs the payload (arrival order/supersede); the tap pays the freshness cost; the hold stream's origin is unaffected. [One verb, one order; the coalesce is SYS-01's, not a new Combat rule.]
- **If the a11y hold-repeat is on and the player holds from before the telegraph** → the attack executes (the repeats keep the order alive); the clash does not auto-win; the power comparison applies. [The aid never becomes the meta.]
- **If the player mashes at 12 t/s** → the newest press is fresh; the clash is lost; the strike lands; the cost is observable. [TR-CMB-013.]
- **If the player taps once, early** → the press is 5–12 ticks old at the contact; the clash resolves; the counter/stagger/lock follows the power. [The reward.]
- **If `physics_tps` changes mid-session** → all phase ticks recompute from their ms contracts; no arc expires early or overstays from the rate event alone. [F-CMB-01.]
- **If a knob is invalid** → the config validation clamps to the safe range; the production resolution is clamp + telemetry; a dev boot fails naming the knob. [The V-CMB law.]
- **If the enemy's active window is < 6 ticks (84 ms)** → the strike is flagged unclashable; the GDD records it; the player cannot clash it with the 5-tick startup (the 6-tick startup needs 7 ticks). [The SYS-13 contract.]

### Degenerate strategies — named and shut down

- **If the player mashes Attack** → the Fresh Press rule: the newest press loses the clash; the mash pays with the hit. [The single early press wins.]
- **If the player holds Attack (a11y)** → the hold is exempt from the freshness cost, but the power comparison still applies; the hold yields ATK1 (power 1) and cannot choose ATK2; it is not the optimal counter strategy. [The read is still the read.]
- **If the player spams backdash** → the 280 ms lock exceeds the 140 ms i-frames; the 8-tick exposure and the body-free gate make continuous invincibility impossible. [Movement's F-MOV-07.]
- **If the player spams Dash** → 500 ms cooldown; no i-frames; dashing into a strike is a hit. [Reposition, not a dodge.]
- **If the player tries to clash two strikes at once** → the first contact resolves; the second hits; the clash is not i-frames. [One exchange.]
- **If the player tries to stall the clash forever** → the counter-clash deals damage; the double clash locks both for 700 ms; the lose branch staggers; no outcome is a free stall. [The prototype's stall question is closed by the counter reward.]

## Dependencies

**Upstream: SYS-01 and SYS-06 are hard; SYS-07 is hard at hit time; SYS-13 is hard for strikes.**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream | **SYS-01 Input & Control Mapping** | **Hard** | In: attack presses + stamp snapshots + `press_tick`/supersede; `crouch` raw; the `body_busy` OR; the 200 ms override; custody · Out: commitments, clash results, damage events, knockback orders, stagger orders | GDD UNFROZEN; ADR-0001 Accepted |
| Upstream | **SYS-06 Movement & Platforming** | **Hard** | In: `facing`/`grounded`/`body_busy`; `crouch_effective` + posture-carry; `KnockbackOrder` execution; `KNOCKDOWN_POWER`; `BACKDASH_IFRAME_MS`; derived 1200; `freeze_hold` · Out: the Combat commitments; the i-frame grants | **APPROVED 2026-11-12** |
| Upstream | **SYS-07 Health & Damage** | **Hard at hit time** | In: HP, damage application, death/respawn · Out: `DamageEvent` | GDD not written — PROVISIONAL |
| Upstream | **SYS-13 Enemy AI & Telegraphs** | **Hard for strikes** | In: the enemy strike contract (`power`, `active_ms`, `telegraph_ms`, hitbox) · Out: clash/counter/stagger orders | GDD not written — PROVISIONAL |
| Upstream | **SYS-29 Juice & Feedback** | Soft/hard for the freeze | In: the hit-stop clock · Out: the paired commitment; the haptic hook | GDD not written — PROVISIONAL |
| Coordination | **SYS-05 Game Flow** | Soft | In: contexts and gates · Out: no context state | Linear stub |
| Downstream | **SYS-14 Grief-Boss Framework** | Soft | In: the boss interaction rules · Out: the clash/stagger/deflect results | GDD not written |
| Downstream | **SYS-24 HUD** | Soft | In: the commitment state for the HUD/haptics · Out: none | GDD not written |
| Downstream | **SYS-12 Motion Input / Stinger** | VS | In: the Stinger's combat interaction · Out: none at MVP | VS |
| Downstream | **SYS-16 Progression** | Soft | In: the ability grants (Movement's) · Out: none | VS |

**Explicit non-dependencies:** SYS-03 Save (Combat has no save data) · SYS-09/10/11 (rendering/mutation, never combat physics) · SYS-17/18 (inventory/economy; the healing item is SYS-17's VS question) · SYS-02 (collision is Movement's).

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) SYS-08's row gains the Combat GDD path, the 34 TR-CMB / 12 formulas / 48 ACs counts, and the 700 ms declaration; (2) SYS-13's row gains the enemy strike contract; (3) SYS-07's row gains the `DamageEvent` boundary; (4) SYS-29's row gains the hit-stop pairing; (5) SYS-24's row gains the commitment state read.

## Tuning Knobs

**All Combat knobs are designer-only at MVP.** No player-facing combat settings: the feel is identity; accessibility lives in SYS-01 (`ATTACK_HOLD_REPEAT`, `TOUCH_HIT_SCALE`, etc.). The enemy strike values are SYS-13's; the HP/damage economy is SYS-07's.

**Knob validation law (V-CMB).** Every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry; dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-CMB-01 | `CLASH_MIN_AGE_TICKS < CLASH_MAX_AGE_TICKS` | clamp MIN to MAX − 1 | an empty band is no clash |
| V-CMB-02 | `CLASH_MAX_AGE_TICKS = ms_to_ticks(ATTACK_WINDOW_MS)` | dev boot failure | the gate cannot outlive the window |
| V-CMB-03 | `BACKDASH_IFRAME_MS < BACKDASH_LOCK_MS` (SYS-06) | lower IFRAME | exposure ≥ 1 tick |
| V-CMB-04 | `GETUP_IFRAME_MS < GETUP_MS` (SYS-06) | lower GETUP_IFRAME | the getup is not free |
| V-CMB-05 | `worst_case_arc_ms = max(arc, air_landing_lag, clash_lock, stagger)` and `≤ 1200` | dev boot failure | TR-INP-029's declaration must cover the longest lock |
| V-CMB-06 | `COUNTER_CLASH_MULT ∈ [1.2, 2.0]` | clamp | the reward curve |
| V-CMB-07 | `KNOCKDOWN_POWER ∈ [1, 3]` | clamp | Movement's threshold |
| V-CMB-08 | `DEFLECT_SPEED ≥ the projectile's speed` (SYS-13) | clamp / flag | the return must outrun the orb |
| V-CMB-09 | `HITSTOP_*_MS ≤ the paired commitment` | clamp | the freeze never outlives the body's promise |
| V-CMB-10 | `air_landing_lag` is in the `body_busy` OR | dev boot failure | the fifth commitment is not lost |
| V-CMB-11 | `ENEMY_ACTIVE_MS ≥ 84` (6 ticks) for a clashable strike | flag unclashable | the 5-tick startup needs 6 ticks |
| V-CMB-12 | every hitbox knob is present or marked provisional | dev boot failure | TR-CMB-003's data-driven law |

| Knob | Default | Safe range | Extreme behavior | Interactions | Rule |
|---|---|---|---|---|---|
| `ATTACK_WINDOW_MS` | 200 | 140–260 | <140: the earliest startup press drops; >260: the mash's old presses survive | `CLASH_MAX_AGE_TICKS`; **Combat declares the value, SYS-01 owns the slot/window** | TR-CMB-001/005 |
| `ATK1_STARTUP_MS` | 90 | 70–120 | <70: no lift; >120: the read feels late | `ATK1_ACTIVE_MS` | F-CMB-02 |
| `ATK1_ACTIVE_MS` | 70 | 50–90 | <50: the hitbox blinks; >90: the swing lingers | `ATK1_RECOVERY_MS` | F-CMB-02 |
| `ATK1_RECOVERY_MS` | 170 | 120–220 | <120: no cost; >220: the punish is too long | `ATK2_STARTUP_MS` | F-CMB-02 |
| `ATK1_DAMAGE` | 10 | 6–14 | SYS-07 economy | `ATK2_DAMAGE` | F-CMB-06 |
| `ATK1_POWER` | 1 | 1–2 | The clash comparison | enemy power | F-CMB-05 |
| `ATK2_STARTUP_MS` | 100 | 80–130 | The finisher's lift | `ATK1_RECOVERY_MS` | F-CMB-02 |
| `ATK2_ACTIVE_MS` | 80 | 60–100 | The finisher's swing | `ATK2_RECOVERY_MS` | F-CMB-02 |
| `ATK2_RECOVERY_MS` | 250 | 180–300 | The finisher's cost | `CHAIN` | F-CMB-02 |
| `ATK2_DAMAGE` | 20 | 14–26 | SYS-07 economy | `ATK1_DAMAGE` | F-CMB-06 |
| `ATK2_POWER` | 2 | 2–3 | The finisher wins vs light | enemy power | F-CMB-05 |
| `CROUCH_ATTACK_STARTUP_MS` | 80 | 60–110 | The low answer | `CROUCH_ATTACK_ACTIVE_MS` | F-CMB-02 |
| `CROUCH_ATTACK_ACTIVE_MS` | 60 | 40–80 | The low swing | `CROUCH_ATTACK_RECOVERY_MS` | F-CMB-02 |
| `CROUCH_ATTACK_RECOVERY_MS` | 150 | 100–200 | The low cost | `CROUCH_ATTACK_DAMAGE` | F-CMB-02 |
| `CROUCH_ATTACK_DAMAGE` | 8 | 5–12 | SYS-07 economy | `CROUCH_ATTACK_POWER` | F-CMB-06 |
| `CROUCH_ATTACK_POWER` | 1 | 1–2 | The low clash | enemy power | F-CMB-05 |
| `AIR_ATTACK_STARTUP_MS` | 80 | 60–110 | The air lift | `AIR_ATTACK_ACTIVE_MS` | F-CMB-02 |
| `AIR_ATTACK_ACTIVE_MS` | 70 | 50–90 | The air swing | `AIR_ATTACK_RECOVERY_MS` | F-CMB-02 |
| `AIR_ATTACK_RECOVERY_MS` | 120 | 80–160 | The air cost | `AIR_LANDING_LAG_MS` | F-CMB-02 |
| `AIR_ATTACK_DAMAGE` | 10 | 6–14 | SYS-07 economy | `AIR_ATTACK_POWER` | F-CMB-06 |
| `AIR_ATTACK_POWER` | 1 | 1–2 | The air clash (VS) | enemy power | F-CMB-05 |
| `ATK1_HITBOX` | 28 px reach; 20×16 px | 24–32; 16–24×12–20 | provisional; art/SYS-13 | `ATK1_ACTIVE_MS` | TR-CMB-004 |
| `ATK2_HITBOX` | 32 px reach; 24×18 px | 28–36; 20–28×14–22 | provisional; art/SYS-13 | `ATK2_ACTIVE_MS` | TR-CMB-004 |
| `CROUCH_ATTACK_HITBOX` | 24 px reach; 20×12 px (low 0–20 px) | 20–28; 16–24×8–16 | provisional; art/SYS-13 | `CROUCH_ATTACK_ACTIVE_MS` | TR-CMB-004 |
| `AIR_ATTACK_HITBOX` | 26 px reach; 20×16 px | 22–30; 16–24×12–20 | provisional; art/SYS-13 | `AIR_ATTACK_ACTIVE_MS` | TR-CMB-004 |
| `AIR_LANDING_LAG_MS` | 100 | 60–160 | <60: no landing cost; >160: the landing is a trap | `AIR_ATTACK_RECOVERY_MS` | TR-CMB-007 |
| `CLASH_MIN_AGE_TICKS` | 5 | 3–7 | <3: the mash survives; >7: the read is too strict | `ATTACK_WINDOW_MS` | F-CMB-04 |
| `CLASH_MAX_AGE_TICKS` | 12 | = the window | derived | `ATTACK_WINDOW_MS` | F-CMB-04 |
| `CLASH_LOCK_MS` | 700 | 500–900 | <500: the duet is short; >900: the fight stalls | `HITSTOP_CLASH_MS` | F-CMB-11 |
| `STAGGER_MS` | 500 | 350–650 | <350: no cost; >650: the lose branch is a death sentence | `CLASH_LOCK_MS` | TR-CMB-012 |
| `COUNTER_CLASH_MULT` | 1.5 | 1.2–2.0 | <1.2: the reward is weak; >2.0: the counter is the only game | `ATK.damage` | F-CMB-06 |
| `HITSTOP_HIT_MS` | 70 | 40–100 | The impact beat | `HITSTOP_CLASH_MS` | F-CMB-07 |
| `HITSTOP_CLASH_MS` | 90 | 60–120 | The clash beat | `CLASH_LOCK_MS` | F-CMB-07 |
| `HITSTOP_DEFLECT_MS` | 40 | 20–60 | The deflect ping | `DEFLECT_SPEED` | F-CMB-07 |
| `BACKDASH_IFRAME_MS` | 140 | 100–180 | **SYS-08's grant; consumed by SYS-06** | `BACKDASH_LOCK_MS` | F-CMB-08 |
| `GETUP_IFRAME_MS` | 300 | 200–400 | <200: the can't-act punish; >400: the getup is free | `GETUP_MS` (SYS-06) | F-CMB-08 |
| `DASH_IFRAME_MS` | 0 (fixed MVP) | 0 | VS question | `DASH_MS` (SYS-06) | TR-CMB-017 |
| `CLASH_IFRAME_MS` | 0 (fixed) | 0 | The clash is negation | — | TR-CMB-018 |
| `DEFLECT_SPEED` | 360 px/s | 300–420 | The return | projectile speed | F-CMB-10 |
| `DEFLECT_DAMAGE` | = the projectile's | — | SYS-13's projectile | — | F-CMB-10 |
| `KNOCKDOWN_POWER` | 2 | 1–3 | **SYS-08's value; consumed by SYS-06** | `power` | TR-CMB-026 |
| `ENEMY_STAGGER_MS` | 800 | 500–1000 | **SYS-13's value** | the counter branch | TR-CMB-010 |
| `ENEMY_ACTIVE_MS` | ≥84 (6 ticks) | SYS-13's | <84: unclashable | the clash | TR-CMB-028 |
| `TELEGRAPH_MS` | SYS-13's | — | The read's lead | the active | TR-CMB-030 |

**Cross-system inputs (consumed at registration — not Combat knobs, but validated by Combat):** `physics_tps` (engine; F-CMB-01) · `power` (per strike, from SYS-13; the single strike power — no separate `knockback_power`) · `active_ms`/`telegraph_ms`/`hitbox` (SYS-13's) · `BACKDASH_LOCK_MS` (SYS-06; validates `BACKDASH_IFRAME_MS < LOCK`) · `GETUP_MS` (SYS-06; validates `GETUP_IFRAME_MS < GETUP_MS`) · `KNOCKDOWN_MS` (SYS-06; the 1200 arc) · `INTERACT_MARGIN_MS` (SYS-01's) · the HP/damage economy (SYS-07's). A missing or invalid cross-system input is a dev boot failure, never a silent default.

**Not knobs (documented so nobody adds them):** `worst_case_arc_ms` (derived max 700) · `chain_point` (derived) · `contact_tick` (derived) · the hit-stop clock (SYS-29's) · the enemy AI/telegraphs (SYS-13's) · HP/damage/death (SYS-07's) · the eight verbs (SYS-01's).

**Provisional lifetimes:** `ATK1/ATK2` and `CROUCH_ATTACK`/`AIR_ATTACK` phase values (playtest) · `COUNTER_CLASH_MULT` and the damage values (SYS-07) · `GETUP_IFRAME_MS` (playtest) · `CLASH_MIN_AGE_TICKS` (playtest) · `CLASH_LOCK_MS`/`STAGGER_MS` (playtest) · `HITSTOP_*` (SYS-29/playtest) · `DEFLECT_SPEED` (playtest) · the hitbox reach/dimensions (art/SYS-13) · the enemy strike values (SYS-13) · the air clash (VS).

## Visual/Audio Requirements

*(Combat names the states and event edges; rendering is SYS-24's, VFX/audio design is SYS-29/SYS-04's.)*

- **Clash:** two spark pulses for the double clash — the contact pulse and the lock's midpoint; color-flash + shape, never opacity pulses; 2 px value separation from backdrops; the spark palette uses the world's palette (cyan/amber), **never sigil-red** (reserved for the demon lord's presence). The lock pose reads as two committed bodies, not a shield.
- **Counter-clash:** a heavier impact than a normal hit; the enemy's stagger silhouette; the counter's damage is visible in the enemy's reaction, not a floating number at MVP.
- **Hit-stop:** the world holds its breath; the camera shake is SYS-32's (clamped); the haptic is SYS-29's (heavy = clash/stagger, medium = commit, light = press).
- **Deflect:** a distinct ping and a reversed projectile trail; the deflected orb's owner flip is visible (color/shape).
- **Telegraphs:** every enemy strike uses color-flash + shape lean; no opacity pulses; SYS-13 owns the timing/palette; Combat's contract requires the telegraph before the active window.
- **Animation states (SYS-24 renders):** ATK1 lift/swing/recovery; ATK2 finisher; crouch attack low stab; air attack; clash lock (two bodies); stagger; getup; deflect. The silhouette-first rule: the crouch attack's low posture and the clash lock's two-body silhouette must read at 32 px.
- **Audio (SYS-04 designs):** clash chime, hit thud, counter impact, deflect ping, stagger, getup. No per-press popups; no "ORDER RECEIVED."

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:combat` for per-asset descriptions, dimensions and generation prompts.

## UI Requirements

**None of its own.** Combat has no screen, menu or HUD element. SYS-24 may read the commitment state for feedback (the clash lock, the stagger), but the HUD never consumes gameplay touches from Combat. The haptic channel map is SYS-01/SYS-29's. The a11y hold-repeat is SYS-01's setting; Combat consumes the tag. **No UX flag.**

## Acceptance Criteria

**Classification legend:** `[GUT]` automatable in Godot Unit Test · `[DEVICE]` on-device manual QA · `[PLAYTEST]` human feel observation with the coded rubric. Dual tags mean the GUT half gates first, the DEVICE half confirms.

### The combat contract

- **AC-CMB-01** [GUT] *(TR-CMB-001)* — **GIVEN** a mocked `PulledIntent` stream and a human capture replayed through `InputCore → InputBus → CombatCore`, **WHEN** the same attack presses run, **THEN** the two traces are bit-identical over 600 ticks; the attack override is 200 ms (12 ticks); the intent carries `press_tick` and the supersede recency; `src/combat/` contains **zero** `Input.` symbols (CI grep).
- **AC-CMB-02** [GUT] *(TR-CMB-002)* — **GIVEN** the registry at eight body verbs, **WHEN** the combat states are exercised (ATK1/ATK2/crouch/air/clash/deflect), **THEN** the registry diff is empty, no input-layer file changes, and no ninth body verb exists.
- **AC-CMB-03** [GUT] *(TR-CMB-003)* — **GIVEN** a knob edit at runtime (`ATK1_STARTUP_MS` 90→120), **WHEN** the same scripted trace runs, **THEN** the ATK1 startup changes from 6 to 8 ticks, the active/chain/arc boundaries move accordingly, and no code edit occurs.

### Arcs and combo

- **AC-CMB-04** [GUT] *(TR-CMB-004, F-CMB-01/02)* — **GIVEN** 60 tps, **WHEN** the four arcs convert, **THEN** ATK1 = 6/5/11 = 22 ticks; ATK2 = 6/5/15 = 26; crouch = 5/4/9 = 18; air = 5/5/8 = 18; the active window is inclusive; the chain point is the first tick after ATK1's active.
- **AC-CMB-05** [GUT] *(TR-CMB-005, F-CMB-12)* — **GIVEN** a press at ATK1's first startup tick, **WHEN** the chain point arrives, **THEN** ATK2 starts exactly at the chain point and the remaining ATK1 recovery is cancelled; a press one tick after the chain point does not chain; one press = one resolution.
- **AC-CMB-06** [GUT] *(TR-CMB-005)* — **GIVEN** a pulled attack, **WHEN** the arc runs, **THEN** the slot is cleared at the ack, the intent is held through the arc, no input-side re-offer occurs, and the attack resolves once (TR-INP-075's custody).
- **AC-CMB-07** [GUT] *(TR-CMB-006)* — **GIVEN** crouch held and attack pressed, **WHEN** crouch is released before the pull, **THEN** the stand attack executes; the stamp snapshot still logs `crouching = true`; a crouch attack pulled on the same tick shows the crouched hurtbox on the first active tick.
- **AC-CMB-08** [GUT] *(TR-CMB-006, F-MOV-11)* — **GIVEN** a crouch attack pulled while the raw crouch is true, **WHEN** the first active tick runs, **THEN** `crouch_effective` is CROUCHING and the hurtbox equals Movement's F-MOV-11 value (17.6 px top drop at defaults); the posture-carry holds for the arc.
- **AC-CMB-09** [GUT] *(TR-CMB-007)* — **GIVEN** an air attack, **WHEN** the player lands mid-arc, **THEN** the remaining active/recovery is cancelled and `AIR_LANDING_LAG_MS` (100 ms) applies; no air chain; the body is busy through the lag.
- **AC-CMB-10** [GUT] *(TR-CMB-004/008, F-CMB-03)* — **GIVEN** the enemy strike contacts the player at 1008 and ATK1's startup is 6 ticks, **WHEN** the clash evaluates, **THEN** the attack's projected active window is 1014–1018 and the clash resolves at 1014 if the enemy's active covers it (e.g., 1008–1015); a 4-tick enemy active (1008–1011) cannot be clashed by the 6-tick startup; no hurtbox overlap → no clash.

### The clash

- **AC-CMB-11** [GUT] *(TR-CMB-008, F-CMB-04)* — **GIVEN** presses aged 4, 5, 12, 13 ticks at the pull, **WHEN** the gate runs, **THEN** 4 loses (fresh), 5 passes, 12 passes (inclusive), 13 is not offered (the window expired); the pull lands at the contact tick and the clash resolves at `contact + startup` (6 ticks for ATK1).
- **AC-CMB-12** [GUT] *(TR-CMB-009/010, F-CMB-05/06)* — **GIVEN** ATK2 (power 2, damage 20) vs enemy power 1, **WHEN** the clash resolves, **THEN** the counter-clash fires: the enemy takes `floor(20 × 1.5) = 30`, the enemy stagger order (800 ms) is published, the player's attack arc completes, and no clash lock occurs; **GIVEN** ATK1 (power 1, damage 10), **THEN** the counter is 15; **GIVEN** a mock strike with power 1/damage 20 vs power 2/damage 10, **THEN** the comparison uses the powers, never the damage values.
- **AC-CMB-13** [GUT] *(TR-CMB-009/011)* — **GIVEN** equal powers, **WHEN** the clash resolves, **THEN** the double clash fires: 700 ms lock, zero damage, both bodies `body_busy`, two `spark_pulse` events (contact + midpoint; the visual is SYS-29's), no second resolution; after the lock both are free.
- **AC-CMB-14** [GUT] *(TR-CMB-009/012)* — **GIVEN** player power 1 vs enemy power 2, **WHEN** the clash resolves, **THEN** the lose branch fires: the enemy strike's damage applies via a `DamageEvent`, **no `KnockbackOrder` is published**, the player is staggered 500 ms, the attack arc dies, the enemy's recovery continues.
- **AC-CMB-15** [GUT] *(TR-CMB-013)* — **GIVEN** a 12 t/s mash and a single early press at the same contact, **WHEN** the gate runs, **THEN** the mash's newest press is fresh and loses the clash; the single early press (5–12 ticks) wins; the GUT sweep on **SYS-01 AC-20's** 600 ms arc mock shows at least one arc timing where the single press wins and the mash fails (the D6/B11 handoff).
- **AC-CMB-16** [GUT] *(TR-CMB-014)* — **GIVEN** the a11y hold-repeat on, **WHEN** the hold's origin is ≥5 ticks at the contact, **THEN** the freshness cost is waived; the power comparison still applies; a hold does not auto-win a power-2 exchange; a direct tap still pays; the origin resets on consumption.
- **AC-CMB-17** [GUT] *(TR-CMB-015, F-CMB-10)* — **GIVEN** a player attack active window overlapping a projectile with an eligible age, **WHEN** the deflect resolves, **THEN** the projectile reverses at 360 px/s, the owner flips, the damage is the projectile's (8 at default), friendly fire applies, and the hit-stop is 40 ms.
- **AC-CMB-18** [GUT] *(TR-CMB-015)* — **GIVEN** a fresh press at the projectile contact, **WHEN** the deflect evaluates, **THEN** no deflect occurs; the projectile hits the player; the cost is observable.
- **AC-CMB-19** [GUT] *(TR-CMB-008/028)* — **GIVEN** an enemy strike with `active_ms = 84` (6 ticks) and another with 60 ms (4 ticks), **WHEN** the clash evaluates against the 5-tick crouch startup, **THEN** the 6-tick strike is clashable (startup + 1 = 6); the 4-tick strike is flagged unclashable; the 6-tick ATK1/ATK2 startup needs a 7-tick strike (the per-arc condition); the GDD records it.
- **AC-CMB-20** [GUT] *(TR-CMB-009)* — **GIVEN** no active-window overlap (or no hurtbox overlap), **WHEN** the exchange evaluates, **THEN** no clash occurs; the normal hit/whiff resolves; no power comparison runs.

### The defensive family

- **AC-CMB-21** [GUT] *(TR-CMB-016, F-CMB-08)* — **GIVEN** a backdash at 60 tps, **WHEN** the i-frame window runs, **THEN** it is 140 ms / 9 ticks (150 ms effective), the 17-tick lock leaves an 8-tick exposure; a hit inside the i-frames is negated; a hit in the exposure lands; chained hops cannot be continuously invincible.
- **AC-CMB-22** [GUT] *(TR-CMB-017)* — **GIVEN** a Dash, **WHEN** a hit lands during the motion, **THEN** it lands; `iframe_ticks = 0` and the publication contains no i-frame field; the dash is ground-only with the 500 ms cooldown.
- **AC-CMB-23** [GUT] *(TR-CMB-018)* — **GIVEN** a double clash and a third enemy strike, **WHEN** the third strike lands during the lock, **THEN** the damage applies, the player's lock dies, the hit reaction applies; the clash is not i-frames.
- **AC-CMB-24** [GUT] *(TR-CMB-019, F-CMB-08)* — **GIVEN** a getup, **WHEN** a hit lands in the first 300 ms, **THEN** it is negated; a hit after 300 ms lands; the 700 ms getup arc is unchanged.
- **AC-CMB-25** [GUT] *(TR-CMB-020)* — **GIVEN** a backdash intent completing while the body is busy, **WHEN** the completion check runs, **THEN** the hop drops; no queue exists; no deferred motion.

### Commitments, clock, gates

- **AC-CMB-26** [GUT] *(TR-CMB-021, F-CMB-11)* — **GIVEN** every Combat commitment (attack arc, air landing lag, clash lock, player stagger, hit-stop pair), **WHEN** it starts and ends, **THEN** `body_busy` is true on `start_tick` through `end_tick−1` and false on `end_tick`; the declaration equals the derived max (700 at defaults; a `CLASH_LOCK_MS` edit re-declares the max); the combined max with Movement is 1200; a publisher raises/clears mid-window.
- **AC-CMB-27** [GUT] *(TR-CMB-022, F-CMB-07)* — **GIVEN** a hit, clash and deflect, **WHEN** the hit-stop converts, **THEN** 70→5, 90→6, 40→3 ticks; every source publishes a commitment; no freeze exists without one; an idle body is covered by `freeze_hold`.
- **AC-CMB-28** [GUT] *(TR-CMB-023)* — **GIVEN** an arc with 10 ticks remaining, **WHEN** a 6-tick hit-stop begins, **THEN** the timer holds, the commitment stays published, and the arc resumes with 10 ticks; no new arc starts frozen.
- **AC-CMB-29** [GUT] *(TR-CMB-024)* — **GIVEN** an attack in progress, **WHEN** a gate opens, **THEN** no damage or motion is applied on the transition frame, the arc dies, and on resume COMBAT_IDLE with nothing queued.
- **AC-CMB-30** [GUT] *(TR-CMB-025)* — **GIVEN** a hit, **WHEN** the damage resolves, **THEN** a `DamageEvent {source, target, raw_damage, kind, contact_tick}` is published to the SYS-07 mock; Combat contains no HP field; death is SYS-07's edge.
- **AC-CMB-31** [GUT] *(TR-CMB-026, F-CMB-09)* — **GIVEN** a power-2 enemy strike, **WHEN** the knockback order is published, **THEN** `dir` is away from the attacker and `power = 2`; Movement's F-MOV-10 enters KNOCKDOWN on the hit tick; power 1 runs KNOCKBACK.
- **AC-CMB-32** [GUT] *(TR-CMB-027)* — **GIVEN** a second heavy hit during GETUP, **WHEN** it lands, **THEN** damage applies and no new lock starts; the getup i-frames cover the first 300 ms.
- **AC-CMB-33** [GUT] *(TR-CMB-028)* — **GIVEN** the enemy strike contract mock, **WHEN** the fields are validated, **THEN** `power ∈ 1…3`, `active_ms ≥ 84` (6 ticks), the telegraph precedes the active, the hitbox is present, and no `knockback_power` field exists (the single `power` drives the order); the MVP answerability review (backdash · clash · crouch) is a SYS-13 gate record, not a GUT observation.
- **AC-CMB-34** [GUT] *(TR-CMB-029)* — **GIVEN** two enemies striking the same tick, **WHEN** the resolution runs, **THEN** the first contact resolves, the second resolves normally, ties break by entity id, and a hit during the lock cancels it.
- **AC-CMB-35** [GUT] *(TR-CMB-030)* — **GIVEN** the SYS-13 telegraph contract mock and the fixture set, **WHEN** the static audit sweeps, **THEN** zero opacity-pulse telegraphs exist in the fixture; every telegraph is color-flash + shape and precedes the active window; the shipped-asset audit is SYS-13's gate (owner/trigger recorded there).

### Testability, performance, traceability

- **AC-CMB-36** [GUT] *(TR-CMB-031)* — **GIVEN** a scripted trace, **WHEN** it is replayed twice through `CombatCore` with `FakeCombatBodyPort`, **THEN** the two traces are bit-identical; the fixture repeats bit-identically.
- **AC-CMB-37** [GUT] *(TR-CMB-032)* — **GIVEN** the combat build, **WHEN** the CI grep runs, **THEN** `src/combat/` contains zero `Input.` symbols; all presses arrive through the InputBus.
- **AC-CMB-38** [GUT] *(TR-CMB-033)* — **GIVEN** a 10,000-tick soak under the SYS-01 AC-54 monitors (600-tick warm-up, counters reset), **WHEN** the combat structures run, **THEN** net object delta == 0, net resource delta == 0, dynamic heap growth ≤ 256 KB, and the churn envelope ≤ 16 KB over any 1,000-tick window; the named structures are preallocated and bounded — active arc 1, commitment set 5, contact list 8, trace ring 600, hitbox probes fixed — with dev assert + production telemetry on overflow; no hot-path allocation.
- **AC-CMB-39** [DEVICE] *(TR-CMB-033)* — **GIVEN** the QA plan §5.1 reference SKU, **WHEN** workload **W12** runs 10,000 ticks after a 600-tick warm-up, **THEN** the combat tick budget is p99.9 ≤ 0.3 ms / max ≤ 1.0 ms. **W12 definition:** 2,500 ATK1→ATK2 chains (600 ms apart), 2,500 counter-clashes (ATK2 vs power 1), 2,500 double clashes, 2,500 lose-branch + getup cycles; the enemy-strike fixture: active 120 ms, power 1/2/3, telegraph 450/850 ms; the freeze windows 70/90/40 ms; nearest-rank estimators and sample counts are the SYS-01 QA plan §5.3's. The combined SYS-01 + SYS-06 + SYS-08 bar is scoped to **S_base**: ≤ 2.0 ms p99.9 / ≤ 4.0 ms max; the S_burst combined bar is defined per the QA plan's partition (SYS-01 alone may reach 4.0 ms on a burst tick); the combined claim is the arithmetic envelope of the three individual runs, not a single W12 measurement.
- **AC-CMB-40** [GUT] *(TR-CMB-034)* — **GIVEN** the TR-CMB registry, **WHEN** the traceability audit runs, **THEN** every TR has an AC or a recorded guidance note, every formula has an AC, the counts are 34 TR / 12 formulas / 48 ACs, and no `[To be designed]` exists.

### Feel and device

- **AC-CMB-41** [PLAYTEST] *(Player Fantasy)* — **GIVEN** 5 playtesters × 30 min (the SYS-01 AC-63 coding protocol), **WHEN** the trust-rubric interview codes **C1 clash-as-read** and **C2 no-reflex-attribution**, **THEN** each reaches ≥3/5: C1 describes the clash as a read/judgment, not a reaction test; C2 contains zero "I couldn't react" attributions.
- **AC-CMB-42** [PLAYTEST] *(TR-CMB-013)* — **GIVEN** the same cohort, **WHEN** the interview codes **C3 mash-cost-observable**, **THEN** ≥3/5 who mashed can attribute the lost exchange to their newest press ("it answered my last press"), not to randomness.
- **AC-CMB-43** [PLAYTEST] *(TR-CMB-016/017)* — **GIVEN** the same cohort, **WHEN** the interview codes **C4 backdash-as-dodge** and **C5 Dash-as-reposition**, **THEN** each reaches ≥3/5: the backdash is described as an i-frame dodge that keeps the enemy in view; Dash is described as getting somewhere, never as not getting hit.
- **AC-CMB-44** [PLAYTEST] *(TR-CMB-010)* — **GIVEN** the same cohort, **WHEN** the interview codes **C6 counter-as-hit**, **THEN** ≥3/5 describe the counter-clash as a hit/reward, not as a stall or interrupt.
- **AC-CMB-45** [PLAYTEST] *(TR-CMB-006)* — **GIVEN** the same cohort, **WHEN** the interview codes **C7 crouch-low-read**, **THEN** ≥3/5 describe the crouch as making a high attack miss and the crouch attack as the answer from below.
- **AC-CMB-46** [DEVICE] *(TR-CMB-001)* — **GIVEN** the QA plan §7.1 device matrix and the Combat attack trace (a scripted 600-tick attack/clash trace replayed through the device input path; the trace and the enemy-strike fixture are pinned in the Combat QA plan), **WHEN** the trace runs, **THEN** every attack press is delivered once, the clash count equals the **eligible-contact count** (contacts passing F-CMB-04's age gate and the projected-active overlap), and no input failure is recorded.
- **AC-CMB-47** [DEVICE] *(TR-CMB-014)* — **GIVEN** the `ATTACK_HOLD_REPEAT` toggle on, **WHEN** the hold-repeat stream meets a clash, **THEN** the read resolves without the freshness penalty; the hold is not the optimal counter; the scripted hold-repeat exchange completes with AC-CMB-16's expected outcome (power comparison applied, no freshness penalty), and the a11y player can complete the exchange.
- **AC-CMB-48** [DEVICE] *(TR-CMB-001)* — **GIVEN** three-finger play (move + attack + jump) on the device matrix, **WHEN** the combat exchange runs, **THEN** no cross-capture, no double-fire, and the attack intent resolves once.

### Playtest coding table (C1–C7)

The five playtest ACs use the SYS-01 AC-63 protocol: ≥5 testers × ≥30 min, two facilitators coding per statement, agreement ≥90%, Cohen's kappa ≥0.7, disagreements adjudicated by the definition list, never by taste. The negation rule is bidirectional (a negated forbidden term within 3 tokens of its subject does not block; a negated inclusion term blocks). The codes:

| Code | Inclusion set | Exclusion set |
|---|---|---|
| **C1 clash-as-read** | read, saw it, timed it, knew, judgment, deliberate | couldn't react, too fast, reflex, luck, random |
| **C2 no-reflex-attribution** | — (any exclusion term from C1 fails the code) | couldn't react, too fast, reflex, luck, random |
| **C3 mash-cost-observable** | answered my last press, my newest press, I mashed, it caught my mash, the last press | random, unfair, lag, didn't register |
| **C4 backdash-as-dodge** | dodged, i-frames, untouchable, kept facing, eyes on | teleport, random, didn't work |
| **C5 Dash-as-reposition** | reposition, get somewhere, distance, angle, close the gap | dodge, invincible, i-frames, not get hit |
| **C6 counter-as-hit** | hurt them, damage, punished, counter, reward | stall, interrupt only, no damage, waste |
| **C7 crouch-low-read** | ducked, under, high attack missed, low, from below | random, didn't work |

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[DEVICE]`/`[PLAYTEST]` describe where an AC runs, not which gate owns it.

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP smoke** | **39** | AC-CMB-01…38, AC-CMB-40 | Headless GUT on the CI build |
| **MVP device** | **4** | AC-CMB-39, AC-CMB-46, AC-CMB-47, AC-CMB-48 | Device matrix (QA plan §7.1) |
| **MVP-lock** | **5** | AC-CMB-41…45 | Playtest + coded rubric (SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The VS content (air clash, Dash i-frames, short-defer, Stinger) is recorded, not AC'd at MVP |
| **Total** | **48** | | 39 + 4 + 5 + 0 = 48 |

**Exactly-one proof.** Every AC-CMB-01…48 appears in exactly one gate; no AC is in two gates; the count is 48. The DEVICE-tagged ACs do not default home to smoke; the playtest ACs are MVP-lock, not smoke. The Combat QA plan will expand the device/playtest protocols; this manifest is the GDD-side partition.

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **Air clash at VS** — grounded-only at MVP; does the air clash (with a suspended-gravity lock) earn its complexity? | game-designer + SYS-13 | VS |
| 2 | **Clash-lose stagger ownership — RESOLVED 2026-11-12:** Combat owns the 500 ms stagger and publishes **no `KnockbackOrder`** on the lose branch (the weapons met; the player lost the lock, not a clean hit). The normal-hit branch still routes to Movement's knockback/knockdown. | SYS-06 + SYS-08 | Closed; revisit only if SYS-07's hit-reaction data contradicts it |
| 3 | **Enemy active-window minimum** — the 6-tick (84 ms) clashability floor and the "unclashable" flag; which SYS-13 strikes are deliberately unclashable? | SYS-13 | At SYS-13 authoring |
| 4 | **Hitbox reach/dimensions** — the provisional 24–32 px reaches; the art/SYS-13 pass | SYS-13 + art | At SYS-13/art |
| 5 | **Counter-clash economy** — the 1.5× multiplier and the damage values; SYS-07 ratifies | SYS-07 | At SYS-07 authoring |
| 6 | **Getup i-frame value** — 300 ms vs 200/400; playtest | SYS-08 + QA | Playtest |
| 7 | **Hold-repeat contract extension** — the intent record exposes `repeat_tag` and `stream_origin_tick` for the a11y exemption; a one-field SYS-01/ADR extension | SYS-01 + SYS-08 | Before the first Combat story |
| 8 | **Multi-enemy contact order** — the first-contact rule and the entity-id tie-break; performance at 3+ enemies | SYS-13 + SYS-08 | At SYS-13 authoring |
| 9 | **Stinger clash interaction** — the Stinger's lunge-through vs the clash; VS | SYS-12 + SYS-08 | VS |
| 10 | **Boss interaction rules** — the grief-boss states' clash/deflect exceptions; SYS-14 | SYS-14 | At SYS-14 authoring |
