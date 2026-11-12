# Health & Damage

> **Status**: **APPROVED (2026-11-12 — three-seat design review NEEDS REVISION → all 27 blockers revised in-session → mandatory qa-lead spot-check PASS)**. Scope: Plan B (feel + minimal progression) — the resolver, the `StatBlock` identity law, MVP level 1–5 with training data, the **HP bar**, damage numbers, the death/revive contract, the heal item + quick slot, and the weapon-parity law. The full nine-stat sheet, energy consumers, mana payoffs, elements, crit, agility and gear are **VS-gated and recorded** (Open Questions).
> **Author**: user + game-designer (creative seat, GLM-5.3-Flash) + systems-designer/gameplay-programmer (technical seat, DeepSeek V4.1 Flash) — via /design-system
> **Last Updated**: 2026-11-12 (review repair + approval)
> **Last Verified**: 2026-11-12 (qa-lead spot-check PASS: 19/19 claims, counts, arithmetic, gate manifest)
> **Design Review**: NEEDS REVISION (2026-11-12) → revision applied → **APPROVED (qa-lead spot-check PASS, 2026-11-12)**; record at `design/gdd/reviews/health-damage-review-log.md`
> **Implements Pillar**: "Remade Every Death" (death is a story, never a mishearing; the System Offline beat) · "Read, Then Strike" (the clash-lose punish is a read, not a reflex) · "SotN, Not Hollow Knight" (HP is a resource you learn, not a number you watch)
> **System ID**: SYS-07 (Core layer, MVP)
> **Counts**: 39 TR-HD · 15 formulas · 50 ACs · 68 edge bullets · 19 OQ rows · 15 V-HD invariants · 32 knob rows · gate manifest 42 + 3 + 5 + 0 = 50
> **Contracts**: ADR-0001 — Input Architecture (Accepted 2026-11-12) — gate terminality, the logic/physics split, the hit-stop⇒body-committed invariant, the non-ack gate queue; SYS-08 `design/gdd/combat.md` (APPROVED 2026-11-12; **OQ#2/#3 amendments pending**) — `DamageEvent {source, target, raw_damage, kind, contact_tick}` (TR-CMB-025), the provisional damage values, `KNOCKDOWN_POWER = 2`, the counter 1.5× (F-CMB-06), the i-frame grants (TR-CMB-016/019), the lose branch (TR-CMB-012 — **amendment requested in OQ#2**); SYS-06 `design/gdd/movement.md` (APPROVED 2026-11-12) — `KNOCKDOWN_MS 500 + GETUP_MS 700 = 1200`, knockback 16.9/67.6 px, `DISABLED`, `body_busy`, `freeze_hold`, `worst_case_arc_ms` 1200; SYS-01 `design/gdd/input-control-mapping.md` (UNFROZEN, #10 record) — the eight verbs, `TR-INP-029` body availability, the Quick-use chip (`TR-INP-068`/F-09, `CHIP_HOLD_COMMIT_MS`), `TR-INP-075` custody, `TR-INP-076` stamping, `TR-INP-047` gates.

## Overview

The Health & Damage system is the **resolver** half of the trust contract: Combat promises the answer, SYS-07 owns the number. It consumes `DamageEvent` from Combat (and `ENVIRONMENT` events from SYS-02/SYS-15), applies the damage pipeline (`raw → attack scaling (dealt) or defense mitigation (taken) → crit (dealt, NORMAL only) → floor → cap`), owns the player and enemy HP pools, the death edge and its exactly-once latch, the **System Offline** death beat (no auto-respawn; reconstruct at the neural terminal, draw a restore module, or quit), the revive, the heal item and its quick slot, the character model's `StatBlock` (identity-at-default: level 1 / no gear returns every approved number exactly), the MVP training-data loop (level 1–5, points spent at the cache), the energy and mana pools as inert saved data awaiting their VS consumers, the defeat edge that feeds mana/bestiary/economy, the damage-number publication, and the **weapon-parity law** that keeps Dirge-042 and Elegy-013 within the same sustained-damage band while their reach, weight and clash power differ. It never decides whether a hit landed — hitbox/whiff truth is Combat's and SYS-13's — and it never owns the death *presentation*: SYS-15 owns the screen, the fiction and the designation counter. Without it the game loses the pillar's mechanical guarantee: every death is attributable, every number is honest, and the body's memory is legible.

→ *Implementation patterns (`HealthCore` reducer, `DamageResolver`, `StatBlock` revisions, the RNG port, the pooled damage-number labels) are ADR raw material for the planned **Health/Damage ADR**; this GDD stays at the behavior level. The input contracts it consumes are ratified by **ADR-0001**; the body contracts by the approved **Movement GDD**; the damage boundary by the approved **Combat GDD**.*

## Player Fantasy

### The named fantasy — The Number Is the Body's Memory

You are a machine that remembers its damage. Every hit is a subtraction you could have counted; every heal is a repair you chose; every death is a sentence you can finish — *what* hit you, *how hard*, and *why you were there*. Nothing is taken by a hidden die. The bar is not a scoreboard; it is the chassis's memory of the fight. When it empties, the world does not say "you died" and reload you: the screen goes monochrome, the system prints **SYSTEM OFFLINE**, and the quiet line under it — *you are destroyed* — is the truth the fiction has been promising since the first cache. Then you choose: reconstruct at the neural terminal, draw the restore module you carried for exactly this, or quit. The death is a beat, not an interruption.

### The contract — four terms, each testable

1. **Every number is earned and shown.** Damage and healing resolve to integers and publish a number on the contact tick. A hit that lands is geometry, never a die roll; a miss is a whiff you can see. The player can always answer "why did that hurt?" without a stopwatch.
2. **Death is attributable.** The death edge fires exactly once, from an applied damage instance, and carries a `DeathRecord` — source, kind, contact tick, overkill, HP before. There is no death without a cause, and no second death in the same life.
3. **The pool is a resource, not a punishment.** HP, the heal charges and the restore module are scarce; the cache station restores; the quick slot makes the heal a decision you take into the fight, not a menu you hide in. No automatic pickup, no automatic use.
4. **The sheet is a promise, not a spreadsheet.** The character model is identity-at-default: level 1, no harness, returns ATK1 10 / ATK2 20 / crouch 8 / air 10 / counter 15/30 / strikes 6/12/20 / tiers 30/60/120 exactly. Growth is additive and legible: a training point is a choice you make at the cache, not a curve that happens to you. The nine-stat sheet is a later chapter, not a launch condition.

### Anchor moment — The Honest Subtraction

A power-2 heavy lands. The number **12** rises in pale bone, the bar loses a little more than a tenth, the body is knocked down for 1200 ms. You knew the strike's weight from its telegraph; the subtraction is the same one you could do on paper. The death, when it comes, is a sentence you can finish.

### Anchor moment — The Death You Can Narrate

The bar empties to a power-3 heavy — **20**, overkill 4. The screen goes monochrome; the glitch eats the edges; **SYSTEM OFFLINE** prints; *you are destroyed* sits underneath, quiet; a third line names the cause — the heavy's name, the strike, the tick. You are carrying a restore module. You draw it: the chassis reboots on the spot at half a bar, a second of invulnerability humming, the module gone. Or you reconstruct at the neural terminal and the counter stamps a new number on the remade body. Either way the death is *yours*, and the game never pretends it didn't happen.

### Anchor moment — The Heal You Chose

Three charges in the quick slot. The boss is at a third; you are at 18. The chip needs a 150 ms hold and a free body — you have to make the space, commit, and take the 25 back. The number is cyan, the charge is gone, and the next exchange is a decision you can afford. Nothing was auto-used. Nothing was wasted at full HP.

### Language law

**Use:** weight, cost, chapter, memory, repair, earned, attributable, honest, read, the body's memory.

**Player-facing copy — banned:** DPS, burst, tank, heal-spam, "+N DMG", any number-as-identity. **Diegetic serial numbers are the carved-out exception** (Dirge-042, Elegy-013 — the chassis/serial-number doctrine, not a stat as identity). **GDD prose — preferred:** exchange, chain, counter, cost, chapter. "Burst" is replaced by **"the counter window"** or **"a heavy exchange"**. **Economy and formula tables — permitted:** `TTK`, `chain_damage`, `damage per exchange`, `dps_chain`, `dmg/s` (the designer's ruler, not player copy; the SYS-08 precedent allows ms/ticks in the GDD and bans them only in player-facing text). **Telemetry/field names — unconstrained** (the law governs meaning, not identifiers). "Precision" is the body's property, never the player's demand; the RNG cuts below exist to keep that true.

### Success signature

Playtesters say: "I knew exactly what killed me"; "I saw the 20 and knew I was in trouble"; "I chose to heal, I didn't spam it"; "the numbers tell me the truth, they don't replace the fight"; "when the screen said SYSTEM OFFLINE I actually felt it"; "I reconstructed because I wanted to, not because the game reloaded me"; nobody asks for a dodge-roll, an accuracy stat, or a damage-number toggle to *escape* the feedback.

*Pillar ties: "Remade Every Death" (the death beat, the counter, the reconstruct choice) · "Read, Then Strike" (the clash-lose punish is a read; no RNG miss/dodge) · "SotN, Not Hollow Knight" (resources learned, not watched).*

## Detailed Design

### Core Rules

**Rule IDs (`TR-HD-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** PROVISIONAL marks indicate contracts with undesigned downstream GDDs; ownership boundaries are intended final. **SYS-07 is the resolver: it never decides whether a hit landed, never reads `Input`, and never renders.**

#### 1 · The boundary and the data model

- **TR-HD-001 — Consume, never poll.** SYS-07 consumes `DamageEvent` from Combat and `ENVIRONMENT` events from SYS-02/SYS-15; it never reads `Input.*`, never inspects a hitbox, and never decides hit/miss. Hitbox/whiff truth is SYS-08/SYS-13 geometry; SYS-07 owns what a landed event costs or grants. *Test: a mocked event stream behaves identically to a live capture; `src/health/` contains no `Input.` and no hitbox-probe symbol (CI grep).*
- **TR-HD-002 — The damage kinds and the reserved source.** Combat's producer enum is unchanged: `kind ∈ {NORMAL, COUNTER, DEFLECT, ENEMY_STRIKE}` (TR-CMB-025). SYS-07's **consumer** enum is a superset of five: the four plus `ENVIRONMENT`. The **source-domain law** uses the reserved sentinel `ENV` (entity id 0) rather than a new field: `kind = ENVIRONMENT ⟺ source = ENV`; a Combat kind requires `source ≠ ENV`; `source = ENV` with a Combat kind is rejected; `target` is never `ENV`. `ENVIRONMENT` is never published by Combat. *Test: the enum membership check; the sentinel pairing check rejects both mismatches; the target-is-not-ENV check.*
- **TR-HD-003 — The strike-damage table.** The enemy strike contract has no damage field (TR-CMB-028). SYS-07 publishes `enemy_strike_damage(power)` — **power 1 → 6, power 2 → 12, power 3 → 20** — and Combat stamps `raw_damage` from it at the strike's contact. The table is a SYS-07 knob, consumed by Combat as a cross-system input at registration (Combat's GDD already lists "the HP/damage economy (SYS-07's)" as such an input); no new strike field, no SYS-08 schema change. A live table edit re-stamps on the next contact. *Test: a mock strike at each power stamps 6/12/20; the strike contract diff is empty; a missing table is a dev boot failure.*
- **TR-HD-004 — Integer law.** Every HP, damage and heal value is an integer. SYS-07 performs **no rounding of its own**: producers floor their formulas (F-CMB-06's counter, the crit 3/2), SYS-07 rejects a non-integer `raw_damage` or heal amount with telemetry. *Test: 12.5 is rejected; 0 is legal; the fixture table is integer-only.*
- **TR-HD-005 — The damage order.** The pipeline is total and deterministic: **`raw_damage` (producer, already includes the counter's 1.5×) → attack scaling (dealt) or defense mitigation (taken) → crit (dealt, `kind = NORMAL` only) → floor 1 → profile cap**. The counter never crits; the counter's 1.5× is a producer law, not a SYS-07 roll; the two never stack (no 2.25×). *Test: the ATK2 counter is 30 at level 1 / ATK 100 and 40 at ATK 132, and never crits; a crit is asserted only on `kind = NORMAL`; the order fixture per branch.*

#### 2 · The character model

- **TR-HD-006 — The `StatBlock` contract and the identity law.** SYS-07 consumes a `StatBlock {level, attack, defense, hp_max, energy_max, mana_max, precision, agility, revision}` from the character model. **Identity-at-default:** at level 1 with no harness (`attack = 100`, `defense = 0`, `precision = 0`, `agility = 0`) every approved number is exact — ATK1 10 / ATK2 20 / crouch 8 / air 10 / counter 15/30 / strikes 6/12/20 / tiers 30/60/120. SYS-07 owns the resolver and the schema; **SYS-16 owns the full sheet** (levels 6–20, gear aggregation, the nine-stat expansion) — the split prevents a SYS-07 ↔ SYS-16 cycle. A `StatRevision` bumps exactly once per point spend or equipment change; there is no per-tick stat recompute. **MVP has no gear**: `defense` is a VS stat (the formula supports it; no MVP source produces it). *Test: the defaults-identity AC (every approved Combat fixture passes unmodified at level 1/no harness); a point spend shows exactly one revision bump and zero per-tick recomputes; no MVP item produces DEF.*
- **TR-HD-007 — The MVP progression (level 1–5, training data, points-only).** MVP ships **level 1–5** (cap 5; VS cap 20). `training_data` is the XP currency. Cumulative thresholds: **L2 100, L3 250, L4 450, L5 700**. Kill awards: **T1 15, T2 35, T3 70, boss 200**. A level-up **banks one training point**; **the point is the only stat growth at MVP** — points are spent **at a cache station** (no mid-combat interruption, no automatic allocation): **+8 attack or +8 max HP per point**. Four points exist by L5; the split is the player's. The StatBlock recomputes on spend and the HP pool gains the delta (a +HP point heals the added amount). *Test: the threshold fixture; 4 points by L5; a point cannot be spent outside a cache; four points all-in on ATK → ATK 132, ATK1 14, chain 41; four all-in on HP → max HP 132; a 2/2 split → 116/116.*
- **TR-HD-008 — The pools (energy, mana) are inert saved data.** `energy_max = 50 + 10×(L−1)`, regen 5/s on `logic_tick`, efficiency `max(70, 100 − 2×(L−1))%`; `mana_max = 30 + 5×(L−1)`, regen 0. **At MVP neither pool has a consumer and neither appears on the HUD** — a meter with no consumer is dead weight. Pools tick on `logic_tick` (a freeze holds them); they are saved at defaults; their first live consumers are VS (energy → the charge attack, SYS-08; mana → the Stinger, SYS-12). *Test: the pool values at L1/L5; 60 logic ticks of regen raise energy 50 → 55; a 30-tick freeze holds it; the HUD read contains no energy/mana field at MVP; the save round-trips both.*
- **TR-HD-009 — The defeat edge and `soul_class`.** When an enemy's HP reaches 0, SYS-07 publishes `DefeatEvent {target, soul_class, killer_id, contact_tick}`; the death edge for enemies is the mirror of the player's (exactly once, latched). `soul_class ∈ {DEMONIC, HUMAN, CYBORG, MACHINE}` is tagged by SYS-13 on every enemy type (the MVP's 2–3 types are tagged now; the field is free). The mana payoff — demonic **+12**, human **+6**, cyborg **+2**, machine **+0** — is VS, consumed by SYS-12/SYS-18/SYS-27. *Test: a mock defeat publishes one event with the tag and the killer; a second lethal event in the same tick publishes nothing; the machine payoff is 0 at VS.*

#### 3 · Pools and profiles

- **TR-HD-010 — The player pool.** `PLAYER_MAX_HP = 100` at level 1; spawn/reconstruct/revive set it to `hp_max` (or the revive's fraction); the only writer is `HealthCore`. *Test: boot HP 100; no other system can write the pool (static assertion); a max-HP change clamps the current HP.*
- **TR-HD-011 — Enemy tiers.** `T1 = 30`, `T2 = 60`, `T3 = 120`, boss = 300 (SYS-14's value inside the SYS-07 range 200–400). SYS-13 assigns a tier per enemy type. The tiers are exact chain multiples at defaults (1 / 2 / 4 / 10 chains of 30). *Test: the tier table; the TTK envelope at the chain-damage extremes (20–41): T1 1–2, T2 2–3, T3 3–6, boss 8–15 chains.*
- **TR-HD-012 — The `HealthProfile`.** Every damageable entity registers `{entity_id, hp_max, tier, iframe_windows, damage_cap_per_event, hp_floor, immune_kinds, death_scripted, soul_class}`. Registration is validated (V-HD); a missing or invalid profile is a dev boot failure, never a silent default. *Test: the profile fixture; an unknown target is rejected; a floor ≥ max fails the boot.*

#### 4 · Application

- **TR-HD-013 — Apply and overkill.** `hp_after = max(0, hp_before − applied)`; `overkill = max(0, applied − hp_before)`; the HP read publishes; the damage-number edge publishes. Overkill is recorded (SYS-29 scales the death sting by it); the HP is never negative. *Test: 20 into 8 → hp 0, overkill 12; 0 damage → no change, no death.*
- **TR-HD-014 — The death edge exactly once.** The edge fires **iff `hp_before > 0 ∧ hp_after = 0`**, and latches for the life: the state becomes DEAD, the `DeathEdge` publishes once, and every further event in DEAD/RECONSTRUCTING is rejected (no HP change, no second edge). *Test: three lethal events in one tick → one edge; a post-edge event → rejected with telemetry; the latch clears only on reconstruct/revive.*
- **TR-HD-015 — The `DeathRecord`.** The edge carries `{cause_source, cause_kind, contact_tick, raw_damage, overkill, hp_before, hp_max, level}`. **Every death is attributable** — the pillar's mechanical guarantee. SYS-15 reads it for the System Offline beat (the cause row) and the counter; SYS-29 reads `overkill` for the sting. *Test: a fuzz of 10,000 damage events — every edge has a valid record and no death occurs without one.*
- **TR-HD-016 — Idempotence.** The tuple `(source, target, raw_damage, kind, contact_tick)` applies **at most once**; a duplicate is rejected with telemetry. The ledger is a bounded ring (256) — the 2-tick age bound means only a few ticks of keys are ever live. *Test: a double-published identical event applies once; a same-tick distinct event (different kind) applies twice.*
- **TR-HD-017 — The validation gate.** The **11-term** predicate: **(1)** `source ≠ target`; **(2)** `raw_damage` is an integer; **(3)** `raw_damage ≥ 0`; **(4)** `kind` in the five-value enum; **(5)** `0 ≤ now_tick − contact_tick ≤ DAMAGE_EVENT_MAX_AGE_TICKS (2)`; **(6)** the target is registered; **(7)** the target is ALIVE; **(8)** the i-frame lock passes (except `ENVIRONMENT`); **(9)** the idempotence key is fresh; **(10)** the profile cap/floor/immune terms pass; **(11)** the source-domain law holds. A failed term rejects the whole event (no partial application) with a named telemetry reason. *Test: one fixture per term (11); a 10,000-event fuzz never applies an invalid event.*
- **TR-HD-018 — The i-frame consumer lock; the void's exception.** SYS-07 evaluates `invulnerable(target, contact_tick)` from the target's published windows (the player's Combat grants: backdash 140 ms, getup 300 ms, revive 1000 ms; an enemy's profile windows) and rejects the event if true. This is the **second lock** behind Combat's negation: a Combat bug cannot leak damage through i-frames. **`ENVIRONMENT` bypasses the i-frame lock and the defense mitigation** — a void is not an attack, and no dodge survives the floor opening; it still goes through the death edge and the `DeathRecord`. *Test: a hit inside the backdash/getup/revive window is rejected; a hit in the 8-tick backdash exposure applies; a void hit during any i-frame window still kills.*
- **TR-HD-019 — No team assumption; friendly fire.** Any registered `(source, target)` pair is legal: the player can be hit by a deflected projectile only if an enemy deflects (VS), an enemy can be hit by another enemy's deflected orb, and a self-hit is rejected by `source ≠ target`. The reducer never assumes "player attacks enemy". *Test: an enemy-vs-enemy DEFLECT event applies; a player self-hit is rejected; a deflected orb's owner flip is just a new source.*
- **TR-HD-020 — Same-tick ordering; heals resolve after damage.** Damage events apply in ascending `(contact_tick, source_id, publication_index)`; each sees the HP after the previous; the first lethal event **applied** is the `DeathRecord`'s cause; later events in the same tick are rejected by the DEAD state. **The ordering is total over the events present at the damage phase.** Combat publishes every contact event in its contact tick's damage phase (the producer timing guarantee); the age bound is a safety net for a late/queued event, not a license to delay. A late event whose `contact_tick` precedes the phase in which it arrives is applied **in arrival order** if the target is ALIVE; if the target is DEAD, it is rejected, and it never rewrites the recorded cause. **The heal/use phase resolves after the damage phase in the same tick**: a heal whose target reached DEAD is refused and its charge is preserved (the death is not undone, and the charge is not stolen). *Test: two enemies hit the same tick → the lower source id resolves first; a source-9 lethal hit at T and a source-2 hit for T arriving at T+1 → the source-9 hit is the cause and the late event is rejected (DEAD); a lethal hit + a heal in one tick → the death stands, the heal is refused, the charge remains.*
- **TR-HD-021 — Boss exceptions.** SYS-14's profile hooks: `damage_cap_per_event` clamps a single event (phase armor), `hp_floor` stops HP at a value until a script releases it (the death edge cannot fire while `floor > 0`), `immune_kinds` rejects named kinds, `death_scripted` publishes the edge with `scripted = true` and SYS-14 owns the transition. SYS-07 provides the hooks; SYS-14 authors the values. *Test: a 30 hit with cap 10 applies 10; a lethal hit at floor 1 leaves 1 HP and no edge; the release then allows the edge; an immune kind is rejected.*

#### 5 · Death, respawn, gates

- **TR-HD-022 — The health state machine.** `ALIVE → DEAD` on the death edge; `DEAD → RECONSTRUCTING` on the player's reconstruct choice; `DEAD → ALIVE` on the restore-module revive; `RECONSTRUCTING → ALIVE` on load complete; `DEAD → QUIT` ends the session. Damage is rejected in DEAD and RECONSTRUCTING. *Test: the transition fixture; damage in each state; no transition without a player choice.*
- **TR-HD-023 — No auto-respawn; the System Offline options contract.** The death edge **never** transitions to RECONSTRUCTING on its own. SYS-15 presents the screen (monochrome glitch, **SYSTEM OFFLINE**, the quiet line *you are destroyed*, and the **cause row printed from the `DeathRecord`**); SYS-07 publishes the options contract: **RECONSTRUCT AT THE NEURAL TERMINAL** (the cache station's terminal surface), **DRAW THE RESTORE MODULE** (only when one is carried; the option greys, never hides), **QUIT**. The designation counter increments on the reconstruction (SYS-15) and on the revive (the death happened). *Test: a death with no input stays DEAD indefinitely; the options fixture; a zero-module death has the revive option greyed and unselectable; the cause row matches the record.*
- **TR-HD-024 — The reconstruct reset.** Reconstruct sets HP = `hp_max`, clears the idempotence ledger and the death latch, archives the `DeathRecord`, restores the quick slot to `CACHE_REFILL` (3), and clears the transient damage state. The cache station is a safe context: **no respawn i-frames at MVP**; an in-place respawn would require a grant (VS, OQ#16). *Test: the reset fixture; HP max; the ledger empty; a stale pre-death event is rejected by the age bound.*
- **TR-HD-025 — The restore module: acquisition, revive, archive.** **The first cache activation grants one restore module; carry cap 1 at MVP; enemies do not drop modules.** In DEAD, drawing a carried module sets HP = `ceil(hp_max × RESTORE_MODULE_HEAL_PCT)` (50%), consumes the module, grants `REVIVE_IFRAME_MS = 1000` (60 ticks) of invulnerability through the SYS-07 i-frame lock, **archives the `DeathRecord`** (the death still happened; the counter increments), and returns to ALIVE **on the spot**. It is a **player choice on the death screen**, never an automatic trigger (the no-auto-use law). *Test: the first-cache grant; the cap 1; the 50% value; one module consumed; the 60-tick window; an automatic death with a module carried stays DEAD until chosen; the record is archived on both paths.*
- **TR-HD-026 — Death is a non-ack gate request.** The edge publishes immediately; the gate request is **queued and applied at the next gate-entry phase** (ADR-0001 §6, the NB-J non-ack rule). Movement enters DISABLED on the edge; Combat clears at the gate; input clears buffers at the application point. *Test: the death-frame outcome is the application point; no verb resolves after the raise; the buffers clear at entry.*
- **TR-HD-027 — Gate terminality and stale events.** No damage is applied on the transition frame; pending damage events drop at gate entry; a post-reconstruct event older than the age bound is rejected. *Test: a gate mid-fight → no damage on the transition frame; a pre-death event replayed post-respawn is rejected.*
- **TR-HD-028 — Freeze; the damage phase's position.** The damage phase runs **after Combat's contact detection and before the hit-stop freeze onset, in the same `physics_tick`, on the contact `logic_tick`**. A hit that starts a hit-stop **applies on the contact tick**, then the freeze holds the clocks. Freeze blocks producers (no new arcs/contacts), not the reducer; a scripted `ENVIRONMENT` event during a freeze still applies. The ADR pins the exact node position; this GDD records the requirement. *Test: a hit + 70 ms hit-stop applies the damage on the contact tick, then the freeze holds; the order fixture is contact → damage → freeze; a scripted void event during a freeze applies.*

#### 6 · Items and healing

- **TR-HD-029 — The heal API.** `heal(amount, source)` clamps to `hp_max`; the amount is an integer > 0; a heal at full HP is a **no-op that consumes nothing** (never waste); a heal whose target reached DEAD in the same tick is refused and the charge is preserved (TR-HD-020); overheal is discarded but the charge is consumed when the use is legal. The heal publishes a `HealEdge` and a cyan damage-number-style edge. *Test: heal 25 at 90/100 → 10 applied, 15 discarded, one charge consumed; at full HP the use is refused and the charge remains; a lethal hit + heal in one tick → the heal is refused, the charge remains.*
- **TR-HD-030 — The Suture and the quick slot.** The MVP heal item is the **SUTURE** (`HEAL_ITEM_AMOUNT = 25`). The quick slot holds one item type, `QUICK_SLOT_MAX = 3` charges. Use = the **Quick-use chip** (SYS-01, `TR-INP-068`/F-09): `CHIP_HOLD_COMMIT_MS = 150` hold-to-commit, commit on the measured release; the use resolves only when the body is available (`TR-INP-029`), consuming one charge and applying the heal on the commit tick. **The chip press publishes no `body_busy`** (the heal is not a commitment); a committed use is not interruptible between the commit and the application (same tick); the charge is spent on the commit. An empty slot publishes a refused use (no charge, no heal). *Test: the 150 ms commit; a busy body waits; one charge per commit; an empty slot refuses; the heal applies on the commit tick; no `body_busy` is raised.*
- **TR-HD-031 — The pickup rule.** **No automatic pickup.** A dropped item is an interactable with a `TAKE` label; the Interact bubble picks it up (SYS-01's Prompt Slot). A Suture pickup adds **+1 charge**; at `QUICK_SLOT_MAX` the pickup is refused and the item **stays on the ground** (never wasted). A restore module pickup is refused at cap 1 (it stays). No automatic use, ever. *Test: walking over an item does nothing; Interact picks it up; a full slot leaves it; the label is ≤ 6 chars; a module at cap 1 stays.*
- **TR-HD-032 — The cache restore.** At a cache station, the player restores HP to `hp_max`, refills the quick slot to `CACHE_REFILL` (3), and grants the first-activation restore module (TR-HD-025). The save stores no HP: a load reconstructs at the station with a full pool. *Test: the restore fixture; the save round-trip has no HP field; a load is always full; the first activation grants exactly one module.*
- **TR-HD-033 — The inventory boundary.** SYS-17 owns item definitions, the full inventory screen, stacks, equipment and the assignable quick slot (VS); SYS-07 owns the heal amount/application, the charge consumption and the revive. At MVP the quick slot **is** the inventory (one item type, 3 charges); the full screen is SYS-17/SYS-26 at VS. *Test: a SYS-17 mock provides the item id and amount; SYS-07 applies; no SYS-07-owned inventory screen exists.*

#### 7 · Economy and publication

- **TR-HD-034 — The weapon-parity law.** Weapons are balanced to **equal sustained damage within ±10% over a measured chain cycle against a dummy**, within **±10%** on single-arc loops, and within **±15%** TTK across three encounter archetypes (swarm, poise-heavy, evasive). The trade axes are reach, per-hit damage, arc speed, **power (the clash matrix)**, and the agility bonus. **Dirge-042** is the approved arc table (ATK1 90/70/170 · 10 · p1; ATK2 100/80/250 · 20 · p2; crouch 80/60/150 · 8 · p1; air 80/70/120 · 10 · p1). The **chain cycle** is `ATK1.startup + ATK1.active + ATK2.startup + ATK2.active + ATK2.recovery` = **37 ticks** (ATK1's recovery is cancelled at the chain point), so `dps_chain = 30 × 60 ÷ 37 = 48.65`. **Elegy-013** (VS, **PROVISIONAL — its 250/450 ms arcs exceed Combat's player-arc ranges and require a SYS-08 per-weapon range extension**) is 250/100/450 · 24 · p2; 300/100/400 · 36 · p3; crouch 20 · p2; air 24 · p2; chain cycle 69 ticks → 52.17 dmg/s (**+7.2%**, inside the ±10% band); reach 40 px. The dummy-minute is the **floor test**, not the law; the clash asymmetry (Elegy's p3 second hit counters power ≤ 2) is the point and is documented, not tuned away. *Test: Dirge's cycle 37 ticks and 48.65 dmg/s; the 60 s integral 2920 (97 chains + one ATK1); Elegy's 69/52.17/+7.2% (VS); the three archetype TTKs within ±15%; Dirge is the only shipped MVP weapon.*
- **TR-HD-035 — The read contract.** SYS-07 publishes read-only: `HealthRead {hp_current, hp_max, hp_ratio, state, low_hp, level, training_data, training_points, quick_charges, quick_item, restore_modules, last_damage_tick, invulnerable}`, `DamageNumber {target_id, amount, kind, contact_tick, world_pos, crit, is_heal}`, `DeathEdge`+`DeathRecord`, `HealEdge {target, amount, source, tick}`, `DefeatEvent`, `StatRevision {level, attack, defense, hp_max, energy_max, mana_max, precision, agility, revision}`. No consumer writes back. *Test: a SYS-24/SYS-29 mock consumes the publications; the schema has no writer field; `hp_ratio`/`low_hp` at 25/100 (low), 26/100 (not), 33/132 (low).*
- **TR-HD-036 — The damage-number render law.** The number appears on the **contact tick** (zero-frame relative to the hit-stop onset), is pooled (32), has a 700 ms lifetime, and uses the palette: enemy damage **amber**, player damage taken **pale bone**, heal **cyan**, crit **gold glyph** (VS). **Never sigil-red** (reserved for the demon lord). The off-switch is a designer/player setting. No word "CRITICAL". *Test: the zero-frame fixture; the pool never allocates mid-run; the palette audit finds no red; the toggle hides all numbers.*

#### 8 · Testability and performance

- **TR-HD-037 — Testability.** Split the seam: **`DamageResolver`** is a pure function `(AttackContext, DefenderSnapshot, RngPort) → DamageResult`; **`HealthCore`** is the stateful reducer (pools, the death/revive machine) over the resolver's output and an injected `HealthPort`. The schemas: `AttackContext {attacker_id, target_id, raw_damage, kind, contact_tick, attack}`, `DefenderSnapshot {target_id, defense, hp_current, hp_max, profile, invulnerable}`, `DamageResult {dealt, applied, overkill, crit, capped}`, `HealthPort {profile(id), invulnerable(id, tick), now_tick(), anchor(id) → Vector2, publish(event)}`. `FakeHealthPort` returns a fixture table; `FixedRngPort` returns the median roll (0.5). **The RNG is inert at MVP** (the only consumer, crit, is VS); at VS it is a stateless counter hash keyed on `(logic_tick, attacker_id, defender_id, contact_tick)` — no `swing_seq`, no mutable RNG state — so a trace is bit-identical regardless of branch path. Fixed 60 tps. *Test: bit-identical traces under the fake; at VS two different keys yield different rolls but identical timing; the same fixture repeats bit-identically; the MVP run performs zero rolls.*
- **TR-HD-038 — Performance and allocation.** No hot-path allocation; the structures are preallocated and bounded: entity table 64, damage-event ring 32, idempotence ledger 256, damage-number pool 32, telemetry ring 600, one `HealthRead`/`StatRevision`. The **AC-53 (tick budget) and AC-54 (allocation)** bars apply; the SYS-07 tick budget is **p99.9 ≤ 0.25 ms / max ≤ 0.75 ms** (W13). The four-system arithmetic envelope is **p99.9 ≤ 2.0 ms (1.0 + 0.3 + 0.3 + 0.25 = 1.85) and max ≤ 4.75 ms (2.0 + 1.0 + 1.0 + 0.75)** — a re-baseline of the three-system 4.0 ms claim, recorded as a QA-plan obligation (OQ#19). *Test: the 10,000-tick soak; net object/resource delta 0; heap ≤ 256 KB; churn ≤ 16 KB / 1,000 ticks; the device bar.*
- **TR-HD-039 — Traceability.** Every TR-HD has an AC or a recorded guidance note; every formula has an AC; the IDs are stable; no `[To be designed]`; the counts are 39 TR / 15 formulas / 50 ACs / 68 edge bullets / 19 OQ rows. *Test: the traceability audit (AC-HD-49).*

### States and Transitions

Health is a small state machine; the body and the combat states are other systems'.

| State | Enter | Exit | Damage | Notes |
|---|---|---|---|---|
| **ALIVE** | boot; reconstruct complete; revive | HP → 0 (the edge) | applied | the only writable state |
| **DEAD** | the death edge | the player chooses reconstruct / revive / quit | rejected | the System Offline beat; no auto-respawn |
| **RECONSTRUCTING** | the reconstruct choice | load complete | rejected | the gate/load; the cache restore |
| **QUIT** | the quit choice | session end | — | SYS-05's context |

**Transition laws.**

1. **The edge is a latch, not a level.** It fires once per life, from an applied damage instance, and carries a `DeathRecord`. No timer, no pit without an `ENVIRONMENT` event, no state change can produce it.
2. **No auto-respawn.** DEAD persists until the player chooses. The screen is SYS-15's; the options contract is SYS-07's.
3. **Revive is a choice.** The restore module is drawn on the death screen; it is never consumed automatically; the record is archived and the counter increments.
4. **Reconstruct is a reset, not a resurrection.** HP max, the ledger clear, the death latch clear, the quick-slot refill; the world state is SYS-15/SYS-02's.
5. **Gates clear pending damage.** No damage on the transition frame; pending events drop at gate entry; a post-reconstruct stale event is rejected by the age bound.
6. **Damage precedes healing in a tick.** The heal/use phase resolves after the damage phase; a heal on a DEAD target is refused and the charge preserved.

### Interactions with Other Systems

| Contract | SYS-07 owns | Consumer owns |
|---|---|---|
| **`DamageEvent`** | the application pipeline; HP; the death edge; the `DeathRecord` | SYS-08: the event, `raw_damage`, the kind, `contact_tick` |
| **Strike damage** | the `enemy_strike_damage(power)` table (6/12/20) | SYS-08: stamps `raw_damage`; SYS-13: authors `power` |
| **`StatBlock`** | the schema, the resolver, the identity law, the MVP points-only level 1–5 data | SYS-16: the full sheet, levels 6–20, gear aggregation (VS); SYS-06/SYS-08: agility/attack consumers (VS) |
| **Pools** | HP, energy, mana as data; regen on `logic_tick`; the kill-sourced mana payoff (VS) | SYS-24: the HP bar (energy/mana HUD-invisible at MVP); SYS-08/SYS-12: the VS consumers |
| **Death** | the edge, the state machine, the options contract, the revive, the record | SYS-15: the System Offline screen, the cause row, the counter, the fiction; SYS-05: the context; SYS-06: DISABLED; SYS-08: the clear |
| **Items** | the Suture amount, the charges, the heal, the revive, the pickup rule, the first-cache module | SYS-17: item defs, the full inventory (VS); SYS-01: Interact + the chip; SYS-24: the chip/HUD |
| **Damage numbers** | the `DamageNumber` edge, the zero-frame law, the palette | SYS-24/SYS-29: rendering, the pool, the off-switch |
| **Defeat** | the `DefeatEvent` + `soul_class` + the killer | SYS-12/SYS-18: mana; SYS-27: dossiers; SYS-13: the tag |
| **Weapon parity** | the law + the acceptance harness | SYS-17/SYS-16: the weapon table; SYS-08: the arcs/powers |
| **Boss profiles** | the hooks (cap/floor/immune/scripted) | SYS-14: the values, the phases |
| **Save** | the field list (level, training data/points, stat sources, charges, modules, quickslot) | SYS-03: serialization, versioning, migration |

- **SYS-08 Combat (upstream, hard at hit time):** the `DamageEvent`, the provisional values, the counter, the i-frame grants, the lose branch (amendment requested in OQ#2), the strike contract. **Status: APPROVED + OQ#2/#3 pending.**
- **SYS-06 Movement (upstream, hard):** the 1200 ms arc, the knockback distances, `DISABLED`, `body_busy`, `freeze_hold`.
- **SYS-01 Input (upstream, hard for the chip):** the eight verbs, `TR-INP-029`, the Quick-use chip, `TR-INP-075`, `TR-INP-076`, the gates.
- **SYS-13 Enemy AI (upstream, hard for strikes):** `power`, `active_ms`, `telegraph_ms`, hitbox, `facing`, `soul_class`, the follow-up punish, power legibility.
- **SYS-15 Cache Stations (coordination, hard for the death beat):** the System Offline screen, the neural terminal, the counter, the cache restore, the phrases.
- **SYS-17 Inventory (downstream, VS; MVP carve-out):** the full inventory, equipment, the assignable quick slot; the MVP carve-out is the Suture + the fixed quick slot + the restore module.
- **SYS-24 HUD (downstream, soft for the bar/numbers; HARD for the chip):** the HP bar, the boss bar, the damage numbers, the chip (3 pips), the level/training-point cue. The MVP heal cannot be used without the chip's touch region and ring.
- **SYS-29 Juice (downstream, soft):** the damage numbers' render, the death sting scaled by `overkill_ratio`, the heal shimmer.
- **SYS-05 Game Flow (coordination):** the death context, quit, the gate.
- **SYS-14 Grief-Boss (downstream, soft):** the boss profile values, the phases.
- **SYS-16 Progression (VS, coordination):** the full sheet, levels 6–20, gear, the nine stats.
- **SYS-03 Save (downstream, hard at save time):** the field list; SYS-03 owns the schema.
- **SYS-12 Stinger (VS):** the mana consumer.
- **SYS-18 Essence (VS):** the scarcity ledger, the mana faucet.
- **SYS-27 Gallery/Bestiary (VS):** the dossiers.

### ADR-0001 Contract Ratification (Health/Damage side)

| Contract | SYS-07's obligation | Test |
|---|---|---|
| Gate terminality (non-ack queue) | The death edge raises a non-ack request; it applies at the next gate-entry phase; no damage on the transition frame | TR-HD-026/027; AC-HD-28 |
| Two clocks | Pools/regen and all timers run on `logic_tick`; the damage phase runs on `physics_tick` | TR-HD-008/028; AC-HD-08/30 |
| Hit-stop⇒body-committed | SYS-07 raises no hit-stop; a hit applies on the contact tick **before the freeze onset** | TR-HD-028; AC-HD-30 |
| No direct `Input` reads | The chip arrives as a pulled intent; SYS-07 never reads `Input` | TR-HD-001/030; AC-HD-01/32 |
| Custody (`TR-INP-075`) | A pulled quick-use is consumed once; no re-offer; the slot clears at the ack | TR-HD-030; AC-HD-32 |
| Stamping (`TR-INP-076`) | `contact_tick` is a `logic_tick`; the age bound is measured on it | TR-HD-017; AC-HD-19 |
| Body availability (`TR-INP-029`) | The quick-use waits for a free body; the derived window is unaffected at MVP (agility 0) | TR-HD-030; AC-HD-32 |

## Formulas

Health's formulas are **conversion laws** (raw → dealt/taken), **state laws** (the edge, the reset, the revive), and **economy laws** (TTK, the counter, the parity, the lose branch). Three laws govern every formula:

- **Named-symbol law.** Every literal appears here only as a named symbol; values live in exactly one place — the Tuning Knobs table.
- **Never-stingy boundary law.** Every boundary comparison is inclusive on entry, strict on exit.
- **Clock law.** Pools, timers and the death beat run on `logic_tick`; the damage phase runs on `physics_tick`; a freeze holds the clocks, not the reducer.

**Formula ledger — law vs knob.**

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-HD-01 | strike_damage | Threshold law | `STRIKE_DMG_P1/P2/P3` |
| F-HD-02 | dealt_damage | True law | `PLAYER_ATK_BASE`, `ATK_PER_POINT`, `CRIT_MULT` (VS) |
| F-HD-03 | taken_damage | True law | `DEF_CAP_PCT`, the floor 1 |
| F-HD-04 | apply_damage | True law | the profile cap/floor |
| F-HD-05 | death_edge | True law | — |
| F-HD-06 | heal | True law | `HEAL_ITEM_AMOUNT`, `RESTORE_MODULE_HEAL_PCT`, `CACHE_REFILL` |
| F-HD-07 | hp_ratio / low_hp | Threshold law | `LOW_HP_THRESHOLD_PCT` |
| F-HD-08 | reconstruct_reset | True law | `PLAYER_MAX_HP`, `CACHE_REFILL` |
| F-HD-09 | idempotence_key | True law | `DAMAGE_EVENT_MAX_AGE_TICKS` |
| F-HD-10 | ttk | Derived metric | the tiers, `chain_damage`, the chain cycle |
| F-HD-11 | counter_value | True law | `COUNTER_CLASH_MULT`, the crit prohibition |
| F-HD-12 | lose_branch_cost | True law | `STAGGER_MS`, the lock by power |
| F-HD-13 | weapon_parity | True law | the weapon table, the tolerance bands |
| F-HD-14 | stat_curves | True law | `ATK_PER_POINT`, `HP_PER_POINT`, the VS caps |
| F-HD-15 | damage_event_gate | True law | the 11 terms |

#### F-HD-01 · strike_damage — the enemy's weight (TR-HD-003)

`enemy_strike_damage(power) = STRIKE_DMG_P[power]`, with `STRIKE_DMG_P1 = 6`, `P2 = 12`, `P3 = 20`.

**Variables:** `power` int 1–3 (SYS-13's); the table is SYS-07's. **Output:** 6 / 12 / 20. **Example:** a power-2 heavy stamps `raw_damage = 12`; at DEF 0 the player takes 12 (8.3 hits from 100).

#### F-HD-02 · dealt_damage — the player's weight (TR-HD-005/006)

`dealt = 0 if raw_damage = 0; else max(1, ceil(raw_damage × attack ÷ 100))` · crit (VS, `kind = NORMAL` only): `dealt = floor(dealt × CRIT_MULT)` with `CRIT_MULT = 1.5` · `dealt = min(dealt, profile.damage_cap_per_event)`.

**Variables:** `raw_damage` int ≥ 0; `attack` int 100–132 at MVP (points), up to 214 at VS. **Output:** ATK 100 → 10/20/8/10, counter 30; ATK 108 → 11/22/9/11, counter 33; ATK 116 → 12/24/10/12, counter 35; ATK 124 → 13/25/10/13, counter 38; ATK 132 → 14/27/11/14, counter 40. **Example:** ATK2 20 at ATK 132 → ceil(26.4) = 27; a chain = 41; T3 120 dies in 3 chains (123).

#### F-HD-03 · taken_damage — the enemy's weight against the chassis (TR-HD-005/006)

`taken = 0 if raw_damage = 0; else max(1, floor(raw_damage × (100 − defense) ÷ 100))`, `defense = min(DEF_CAP_PCT, defense)` with `DEF_CAP_PCT = 25` at MVP (safe range 0–40; VS 40). **At MVP no source produces DEF** (gear is VS); the formula is implemented and unit-tested at DEF 5/25 for the VS sheet.

**Variables:** `raw_damage` int; `defense` int 0–40 (0 at L1/no harness). **Output:** DEF 0 → 6/12/20; DEF 5 → 5/11/19; DEF 25 → 4/9/15. **Example:** a power-3 heavy at DEF 5 → floor(19) = 19; at DEF 25 → 15; the floor 1 keeps a light hit readable (`raw 1` at DEF 25 → floor(0.75) = 0 → 1).

#### F-HD-04 · apply_damage — the subtraction (TR-HD-013)

`hp_after = max(0, hp_before − applied)` · `overkill = max(0, applied − hp_before)` · `applied = min(taken, profile.damage_cap_per_event)`; `hp_after = max(hp_after, profile.hp_floor)`.

**Output:** the new HP, the overkill, the death predicate. **Example:** 20 into 8 → hp 0, overkill 12; a floor 1 holds hp at 1 and no edge fires.

#### F-HD-05 · death_edge — the latch (TR-HD-014)

`edge = (hp_before > 0) ∧ (hp_after = 0) ∧ (state = ALIVE) ∧ (profile.hp_floor = 0 ∨ released)`. On true: `state ← DEAD`, `death_tick ← now_tick`, publish once.

**Output:** boolean, exactly once per life. **Example:** three lethal events in one tick → the first fires, the next two see DEAD and are rejected.

#### F-HD-06 · heal — the repair (TR-HD-029/030/032)

`applied = min(amount, hp_max − hp_current)` · `hp_current ← hp_current + applied` · a heal at `hp_current = hp_max` is refused before the charge is spent · a heal on a DEAD target in the same tick is refused and the charge preserved · the cache restore: `hp_current ← hp_max`, `quick_charges ← CACHE_REFILL` · the revive: `hp_current ← ceil(hp_max × RESTORE_MODULE_HEAL_PCT)`.

**Output:** the applied amount (0 if refused). **Example:** 25 at 90/100 → 10 applied, 15 discarded, one charge consumed; at full HP the use is refused and the charge remains; a revive at 132 max → 66.

#### F-HD-07 · hp_ratio / low_hp — the bar and the cue (TR-HD-035)

`hp_ratio = hp_current ÷ hp_max` · `low_hp = hp_ratio ≤ LOW_HP_THRESHOLD_PCT` with `0.25`.

**Output:** float 0–1; the edge at 0.25 inclusive (never-stingy). **Example:** 25/100 → low; 26/100 → not; 33/132 → low (exactly 0.25).

#### F-HD-08 · reconstruct_reset — the reset (TR-HD-024)

`hp_current ← hp_max` · `quick_charges ← CACHE_REFILL` · `ledger ← ∅` · `death_latch ← false` · `state ← ALIVE` · `revive_iframes ← 0` · `hp_floor` reset to the profile's base.

**Output:** the ALIVE state at full pool. **Example:** reconstruct at 132 max → 132 HP, 3 charges, no stale keys.

#### F-HD-09 · idempotence_key — the tuple (TR-HD-016)

`key = (source, target, raw_damage, kind, contact_tick)`; `seen(key)` → reject; else insert into the ring (256). The age bound `now_tick − contact_tick ≤ DAMAGE_EVENT_MAX_AGE_TICKS = 2` bounds the live key window.

**Output:** boolean. **Example:** a double-published (enemy 7, player, 12, ENEMY_STRIKE, 4000) applies once; (…, NORMAL, 4000) is a distinct event.

#### F-HD-10 · ttk — the kill-time ruler (TR-HD-011/034)

`chain_damage = dealt(ATK1) + dealt(ATK2)` · `chain_cycle_ticks = ATK1.startup + ATK1.active + ATK2.startup + ATK2.active + ATK2.recovery` · `ttk_chains = ceil(hp_tier ÷ chain_damage)` · `ttk_seconds = ttk_chains × chain_cycle_ticks ÷ 60`.

**Output at defaults (chain 30 / 37 ticks):** T1 1 chain (0.617 s), T2 2 (1.233 s), T3 4 (2.467 s), boss 10 (6.167 s). **Envelope (chain 20–41):** T1 1–2, T2 2–3, T3 3–6, boss 8–15. **Example:** at ATK 132 (chain 41) T3 needs ceil(120/41) = 3 chains (123).

#### F-HD-11 · counter_value — the reward (TR-HD-005; F-CMB-06)

`raw_counter = floor(ATK.damage × COUNTER_CLASH_MULT)` with `1.5` (Combat's producer law) · `dealt_counter = max(1, ceil(raw_counter × attack ÷ 100))` · **the counter never crits** (no 2.25×).

**Output:** ATK1 15 / ATK2 30 at ATK 100; ATK1 20 / ATK2 40 at ATK 132. **Example:** the ATK2 counter equals a full chain's 30 in one 26-tick arc; the reward is the stagger + the denied strike, not a damage shortcut.

#### F-HD-12 · lose_branch_cost — the attempt discount (TR-HD-023; the SYS-08 amendment)

The lose branch: `damage = 0`, `stagger = STAGGER_MS (500)`, no `KnockbackOrder`, no `DamageEvent`. The follow-up (SYS-13's ordinary strike during the stagger) applies its own event and order: `total = stagger_elapsed + lock(power)`, where `lock(power 1) = KNOCKBACK_MS (180)` and `lock(power ≥ 2) = KNOCKDOWN_MS + GETUP_MS (1200)`.

**Output:** a follow-up at 250–500 ms gives **430–680 ms** total for power 1 (vs a clean power-1 hit's 180 ms) and **1450–1700 ms** for power ≥ 2 (vs a clean hit's 1200 ms). **The delta is always 250–500 ms** — the stagger elapsed; losing a clash is never cheaper than a clean hit of the same power. Against a non-punishing archetype, the lose is **500 ms and 0 damage** — a learnable bestiary advantage. **Example:** a power-2 follow-up at 300 ms → 300 + 1200 = 1500 ms; a clean power-2 hit = 1200 ms.

#### F-HD-13 · weapon_parity — the equal-band law (TR-HD-034)

`dps_chain = chain_damage × 60 ÷ chain_cycle_ticks` · parity: `|dps_a − dps_b| ÷ dps_a ≤ 0.10` · single-arc: the same ±10% band (inclusive) · archetypes: `|ttk_a − ttk_b| ÷ ttk_a ≤ 0.15` across swarm / poise-heavy / evasive · the 60 s integral: `floor(3600 ÷ cycle) × chain_damage + the partial ATK1 hit`.

**Output:** Dirge 30 × 60 ÷ 37 = **48.65** dmg/s; the 60 s integral 97 chains + one ATK1 = **2920**. Elegy 60 × 60 ÷ 69 = **52.17** (+7.2%); the 60 s integral 52 chains = **3120** (+6.8%). Dirge's light loop 10 × 60 ÷ 22 = **27.27**; Elegy's 24 × 60 ÷ 48 = **30.0** (+10.0% — exactly on the inclusive boundary). **Example:** the parity law passes at ±10%; the clash asymmetry is documented.

#### F-HD-14 · stat_curves — the sheet's promise (TR-HD-006/007)

**MVP (points-only):** `attack = PLAYER_ATK_BASE + 8 × atk_points`; `hp_max = PLAYER_MAX_HP + 8 × hp_points`; `defense = 0`; `precision = 0`; `agility = 0`; `atk_points + hp_points + banked_points = level − 1` (4 points by L5; a banked point is legal and is not spent). **VS (SYS-16's sheet):** `attack = 100 + 6×(L−1)` up to L20 (214); `hp_max = 100 + 8×(L−1)` (252); `defense = min(40, 2×(L−1))`; `precision = min(15, 5 + (L−1))`; `agility = min(30, 2×(L−1) + gear)`; `energy_max = 50 + 10×(L−1)`; `mana_max = 30 + 5×(L−1)`.

**Output:** L1 100/100; 4 ATK points → 132/100; 4 HP points → 100/132; 2/2 → 116/116. **Example:** 4 ATK points → ATK1 14, ATK2 27, chain 41; 4 HP points → max 132, current +32 across the four spends.

#### F-HD-15 · damage_event_gate — the eleven terms (TR-HD-017)

`valid = (1 source ≠ target) ∧ (2 int(raw)) ∧ (3 raw ≥ 0) ∧ (4 kind ∈ {NORMAL, COUNTER, DEFLECT, ENEMY_STRIKE, ENVIRONMENT}) ∧ (5 0 ≤ now − contact ≤ 2) ∧ (6 registered(target)) ∧ (7 state(target) = ALIVE) ∧ (8 ¬invulnerable(target, contact) ∨ kind = ENVIRONMENT) ∧ (9 fresh(key)) ∧ (10 profile_terms(cap, floor, immune)) ∧ (11 source_law(kind, source))`.

**Output:** boolean + the first failing term as telemetry. **Example:** an i-frame hit fails term 8; a stale event fails term 5; a self-hit fails term 1; an `ENVIRONMENT` event with a Combat source fails term 11.

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### Application

- **If a hit lands inside the backdash i-frames** → rejected by the consumer lock; no HP change, no damage number; the hop continues. **If it lands in the 8-tick exposure** → it applies. [The second lock behind Combat's negation.]
- **If a hit lands in the first 300 ms of getup** → rejected; after 300 ms it applies. [TR-CMB-019.]
- **If a hit lands during the revive's 1000 ms window** → rejected; after it, it applies. [TR-HD-025.]
- **If the same event is published twice** → the second is rejected by the idempotence key. [A double-publish is a bug, not double damage.]
- **If two enemies hit the same tick** → the lower source id resolves first; the first lethal event is the death cause; the second sees DEAD and is rejected. [TR-HD-020.]
- **If a same-tick event arrives one tick late** → it is applied in arrival order if the target is ALIVE; if the target is DEAD it is rejected, and it never rewrites the recorded cause. [The producer guarantee is the rule; the 2-tick age bound is the net.]
- **If a lethal hit and a heal land on the same tick** → the damage phase runs first; the death stands; the heal is refused and its charge preserved. [The death is not undone; the charge is not stolen.]
- **If a hit deals exactly the remaining HP** → hp 0, overkill 0, the edge fires. [The boundary is inclusive on the killing blow.]
- **If a hit overkills by 12** → hp 0, overkill 12, the edge fires once; SYS-29 reads the ratio. [The death is a story with a magnitude.]
- **If a 0-damage event arrives** → legal; no HP change, no death; the damage number reads 0 only if a producer publishes one (none at MVP). [Reserved for a future "blocked" event.]
- **If a non-integer `raw_damage` arrives** → rejected; telemetry names the producer. [TR-HD-004.]
- **If the target is unknown** → rejected; dev assert. [A silent default would hide a spawn bug.]
- **If the player is hit by their own deflected projectile** → `source ≠ target` rejects it at MVP; an enemy-vs-enemy deflect applies. [No team assumption; the self-hit guard is explicit.]
- **If a deflected orb kills an enemy** → the `DefeatEvent` fires with the enemy's `soul_class` and the killer; the mana payoff is VS. [Friendly fire is real.]
- **If a boss is hit above its per-event cap** → the applied damage is capped; the overkill is computed on the capped value. [Phase armor is honest.]
- **If a boss is at its HP floor and takes a lethal hit** → HP holds at the floor; no edge; the release then allows the edge. [The phase gate is not a death.]
- **If a boss is immune to a kind** → the event is rejected with the immune reason; no HP change. [SYS-14's values.]
- **If a boss dies with `death_scripted`** → the edge publishes with `scripted = true`; SYS-14 owns the transition; the counter increments on the reconstruction. [The script is not a mishearing.]
- **If a pit/void kills** → an `ENVIRONMENT` event with `source = ENV` and `raw_damage = hp_max` applies through the same path; **it bypasses DEF and the i-frame lock**; the edge fires once; the record's cause is `ENVIRONMENT`. [The death is attributable even when the world kills; no dodge survives the floor opening.]
- **If a scripted hazard hits during a freeze** → it applies; the reducer is not frozen. [TR-HD-028.]

### Death and respawn

- **If the player dies mid-arc** → the edge publishes; Combat clears at the gate; Movement enters DISABLED on the edge. [TR-HD-026.]
- **If the player dies during a hit-stop** → the damage applies on the contact tick; the edge publishes; the freeze releases into DEAD. [The freeze is a clock, not a gate.]
- **If the player dies during the clash lock** → the edge publishes; the lock dies at the gate; the clash partner's state is SYS-13's. [A third strike can kill.]
- **If the player dies with no restore module** → the revive option is greyed; RECONSTRUCT and QUIT remain. [Never hide an option silently.]
- **If the player chooses reconstruct** → the gate/load; HP max; the quick slot refilled; the counter increments (SYS-15). [The cache is the checkpoint.]
- **If the player chooses revive** → HP 50%; one module consumed; 60 ticks of invulnerability; the record archived; the death counter still increments (SYS-15). [The death happened.]
- **If the player chooses quit** → SYS-05's context ends; no save is written beyond the last cache. [No save-scum: the cache is the checkpoint; the counter persistence is OQ#8.]
- **If a stale pre-death event is replayed after the reconstruct** → rejected by the age bound. [A ghost hit cannot follow you through the load.]
- **If the player dies again in the revive window** → attack damage is rejected; **a void/pit still kills** (`ENVIRONMENT` bypasses the lock). [The second life is real against attacks, not against the floor opening.]
- **If the player is at 0 HP but the edge has not fired** → impossible; the edge is synchronous with the subtraction. [No 0-HP ALIVE state.]
- **If the first cache activation runs** → one restore module is granted; later activations do not stack beyond cap 1. [The module has a faucet.]
- **If the module is at cap 1 and a pickup is found** → the pickup stays on the ground. [Never waste.]

### Items and healing

- **If a Suture is used at full HP** → refused before the charge is spent; the charge remains; the chip shows the full state. [Never waste.]
- **If a Suture is used at 90/100** → 10 applied, 15 discarded, one charge consumed. [The charge is spent on a legal use.]
- **If the quick slot is empty** → the chip publishes a refused use; no heal, no charge. [The button is honest.]
- **If the body is busy when the chip commits** → the use waits inside its window (TR-INP-029); if the body frees in time, it resolves; otherwise it expires. [The body finishes what it signed.]
- **If the chip press lands** → no `body_busy` is raised; the heal is not a commitment. [The heal is a repair, not an arc.]
- **If a Suture pickup lands on a full slot** → the item stays on the ground; the prompt stays lit. [Never waste.]
- **If the player walks over an item without Interact** → nothing happens. [No auto-pickup.]
- **If the player holds the chip for less than 150 ms** → no commit; no charge. [The chip's confirmation weight.]
- **If the player holds the chip and the body frees exactly at the commit** → the use resolves on that tick. [The never-stingy boundary.]
- **If a restore module is drawn on the death screen** → HP 50%, one module consumed, 60 ticks of invulnerability, the record archived. [The second life is a choice.]
- **If the cache restore runs** → HP max, the quick slot refilled to 3, the first-activation module. [The station is the reset.]
- **If a save is loaded** → the player is at the last cache with a full pool; no HP field is read. [HP is not persisted.]

### Stats and progression

- **If the player spends a training point on +ATK** → ATK +8; the StatBlock revision bumps; the damage numbers change on the next hit; the approved L1 fixtures are untouched. [Identity at default.]
- **If the player spends a point on +HP** → max HP +8 and current HP +8. [The point is felt immediately.]
- **If a point is spent outside a cache** → refused; the point remains banked. [The station is the only allocation surface.]
- **If the player reaches L5** → no further training data accrues (MVP cap); the VS cap is 20. [The MVP arc is bounded.]
- **If four points all go to ATK** → ATK 132, ATK1 14, ATK2 27, chain 41; max HP stays 100. [The split is the player's.]
- **If four points all go to HP** → max HP 132, ATK stays 100. [The split is the player's.]
- **If a VS crit rolls on a COUNTER** → impossible; the counter never crits. [No 2.25×.]
- **If a VS dodge would fire** → cut; the strike is resolved by geometry, not a die. [The telegraph never lies.]
- **If a VS agility build shortens the knockdown** → the recovery floor is 900 ms; the declared `worst_case_arc_ms` is computed from the stat envelope (min agility), not the current build. [TR-INP-029 stays structural.]
- **If `physics_tps` changes mid-session** → the ms contracts hold; the tick fixtures recompute. [The ms contract is the promise.]

### Degenerate strategies — named and shut down

- **If the player spams the heal chip** → the 3-charge cap, the 150 ms commit and the body gate bound it; an empty slot refuses. [The heal is a decision.]
- **If the player hoards heals forever** → the cache refills; hoarding is a choice, not an exploit. [Scarcity is the tension.]
- **If the player farms the restore module** → one per first cache activation, cap 1, no enemy drops. [The second life is a resource.]
- **If the player tries to die to reset the counter** → the counter increments on the reconstruction and on the revive; death is never free. [The pillar.]
- **If the player tries to skip the death screen** → no auto-respawn; the choice is required. [The beat is the design.]
- **If the player watches the numbers instead of the body** → the numbers are small, muted, short-lived, and same-tick; the hit-stop and sparks stay primary; the off-switch exists. [The body is the read.]
- **If the player loses a clash to a punishing archetype** → 0 damage + 500 ms stagger + the follow-up's damage and lock; losing is 250–500 ms worse than a clean hit of the same power. [The read is the skill.]
- **If the player loses a clash to a non-punishing archetype** → 0 damage + 500 ms; a learnable bestiary advantage. [Knowing who punishes is the reward.]
- **If the player mashes into a clash** → the Fresh Press rule (SYS-08) denies the clash; the clean hit lands. [The mash pays.]

### Value and config extremes

**Knob validation law (V-HD).** Every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry; dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-HD-01 | in ALIVE, `hp_current > 0`; the edge fires iff `hp_before > 0 ∧ hp_after = 0` | dev boot failure | no 0-HP ALIVE |
| V-HD-02 | damage/heal integers; `raw ≥ 0`; `heal > 0` | reject + telemetry | the integer law |
| V-HD-03 | the death edge fires exactly once per life | dev boot failure | the pillar's guarantee |
| V-HD-04 | the reconstruct resets HP, the ledger, the latch, the quick slot | dev boot failure | a stale life is a bug |
| V-HD-05 | the i-frame lock includes the revive window | dev boot failure | the second life is real |
| V-HD-06 | `T1 < T2 < T3 < boss` | clamp / boot failure | the tier ladder |
| V-HD-07 | `P1 < P2 < P3` | clamp | the strike ladder |
| V-HD-08 | `heal ≤ hp_max`; no overheal | clamp | never waste |
| V-HD-09 | `hp_floor < hp_max` | boot failure | a floor at max is an unkillable boss |
| V-HD-10 | `DAMAGE_EVENT_MAX_AGE_TICKS ≤ 2` | clamp | a stale hit is a ghost |
| V-HD-11 | `0 ≤ quick_charges ≤ QUICK_SLOT_MAX`; `0 ≤ restore_modules ≤ 1` | clamp | the item bounds |
| V-HD-12 | L1/no harness → the approved numbers exact | dev boot failure | identity at default |
| V-HD-13 | `DEF_CAP_PCT ≤ 25` at MVP (≤ 40 VS); `taken ≥ 1` for `raw > 0` (raw 0 → 0) | clamp | the telegraph stays readable |
| V-HD-14 | the parity bands hold (±10% / ±10% / ±15%) | flag the weapon | the equal-band law |
| V-HD-15 | the damage order is total and deterministic; the heal phase follows the damage phase | dev boot failure | no branch ambiguity |

- **If `PLAYER_MAX_HP ≤ 0`** → clamp to 1; dev assert. [A zero pool is a boot failure.]
- **If a tier is not a positive integer** → clamp to 1. [The TTK ruler needs a positive denominator.]
- **If `QUICK_SLOT_MAX = 0`** → the chip is disabled; the heal item is unusable; a dev warning names the knob. [A zero slot is a design error.]
- **If `DEF_CAP_PCT = 100`** → clamp to 25 at MVP; the floor 1 still applies. [Mitigation never erases the read.]
- **If the parity band is violated** → the weapon is flagged; it cannot ship until re-tuned. [The law is a gate, not a suggestion.]

## Dependencies

**Upstream: SYS-08 and SYS-06 are hard at hit time; SYS-01 is hard for the chip; ADR-0001 is the pipeline.**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream | **SYS-08 Combat** | **Hard at hit time** | In: `DamageEvent {source, target, raw_damage, kind, contact_tick}`; the provisional damage; the counter 1.5×; the i-frame grants; the lose branch · Out: HP, the death edge, the read contract | **APPROVED 2026-11-12 + OQ#2/#3 pending** |
| Upstream | **SYS-06 Movement** | **Hard** | In: the 1200 ms knockdown+getup; knockback 16.9/67.6 px; `DISABLED`; `body_busy`; `freeze_hold` · Out: the death edge; the revive window | **APPROVED 2026-11-12** |
| Upstream | **SYS-01 Input** | **Hard for the chip** | In: the eight verbs; `TR-INP-029`; the Quick-use chip (`CHIP_HOLD_COMMIT_MS`); `TR-INP-075`; `TR-INP-076`; the gates · Out: the heal/revive consumption; no Input reads | UNFROZEN (#10 record); ADR-0001 Accepted |
| Upstream | **SYS-13 Enemy AI** | **Hard for strikes** | In: `power`, `active_ms`, `telegraph_ms`, hitbox, `facing`, `soul_class`; the follow-up punish; power legibility · Out: the strike damage table; the defeat edge | GDD not written — PROVISIONAL |
| Coordination | **SYS-15 Cache Stations** | **Hard for the death beat** | In: the System Offline screen; the neural terminal; the counter; the cache restore; the phrases · Out: the death edge; the options contract; the restore | GDD not written — PROVISIONAL |
| Downstream | **SYS-17 Inventory** | VS; MVP carve-out | In: item defs, the full inventory, equipment, the assignable quick slot · Out: the Suture amount, the charges, the restore module | GDD not written — PROVISIONAL |
| Downstream | **SYS-24 HUD** | **Hard for the chip**; soft for the bar/numbers | In: `HealthRead`, `DamageNumber`, the chip, the level/training cue · Out: none | GDD not written |
| Downstream | **SYS-29 Juice** | Soft | In: the damage numbers' render; `overkill_ratio`; the heal shimmer · Out: none | GDD not written |
| Downstream | **SYS-03 Save** | **Hard at save time** | In: the field list (level, training data/points, stat sources, charges, modules, quickslot) · Out: serialization, versioning | GDD not written — PROVISIONAL |
| Downstream | **SYS-14 Grief-Boss** | Soft | In: the profile values (cap/floor/immune/scripted) · Out: the hooks | GDD not written |
| Downstream | **SYS-16 Progression** | VS | In: the full sheet, levels 6–20, gear, the nine stats · Out: the `StatBlock` contract | GDD not written — VS |
| Downstream | **SYS-12 Stinger** | VS | In: the mana consumer · Out: the mana pool | VS |
| Downstream | **SYS-18 Essence** | VS | In: the scarcity ledger, the mana faucet · Out: the payoff values | VS |
| Downstream | **SYS-27 Gallery/Bestiary** | VS | In: the dossiers · Out: the defeat edge, `soul_class` | VS |
| Coordination | **SYS-05 Game Flow** | Soft | In: the death context, quit, the gate · Out: no context state | Linear stub |

**Explicit non-dependencies:** SYS-02 (collision is Movement's; hazards arrive as `ENVIRONMENT` events) · SYS-09/10/11 (rendering/mutation, never HP) · SYS-19 (contracts; VS) · SYS-20 (memory fragments; the counter is SYS-15's).

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) SYS-07's row gains the GDD path, the counts, the `DamageEvent` boundary and the death/revive/item/parity contracts; (2) SYS-16's row becomes **MVP-minimal (level 1–5 points-only data owned by SYS-07) + VS full sheet**; (3) SYS-17's row becomes **MVP carve-out (the Suture + the fixed quick slot + the restore module) + VS full inventory**; (4) SYS-24's row gains the HP bar, boss bar, damage numbers and chip; (5) SYS-15's row gains the System Offline contract and the training-point surface; (6) SYS-13's row gains `soul_class`, the follow-up punish and power legibility; (7) SYS-08's row gains the lose-branch amendment and the damage-numbers reversal.

## Tuning Knobs

**All Health/Damage knobs are designer-only at MVP** except the damage-number off-switch (a readability/a11y setting). The feel is identity; accessibility lives in SYS-01/SYS-24.

**Knob validation law (V-HD, Edge Cases).** Every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry, dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| Knob | Default | Safe range | Extreme behavior (too low / too high) | Interactions | Rule |
|---|---|---|---|---|---|
| `PLAYER_MAX_HP` (base) | 100 | 60–160 | <60: two heavies kill · >160: the bar loses meaning | `HP_PER_POINT` | F-HD-04 |
| `HP_PER_POINT` | 8 | 4–12 | <4: points feel flat · >12: the pool inflates | `PLAYER_MAX_HP` | F-HD-14 |
| `PLAYER_ATK_BASE` | 100 | 100 (fixed identity) | not tunable | the identity law | F-HD-02 |
| `ATK_PER_POINT` | 8 | 4–10 | <4: no power spike · >10: T3 trivializes by L5 | `HP_PER_POINT` | F-HD-14 |
| `LEVEL_CAP_MVP` | 5 | 3–5 | — | `TRAINING_DATA_L5` | TR-HD-007 |
| `LEVEL_CAP` (VS) | 20 | 10–30 | — | the VS sheet | F-HD-14 |
| `TRAINING_DATA_L2` | 100 | 60–160 | <60: L2 in one room · >160: the first level is late | the kill awards | TR-HD-007 |
| `TRAINING_DATA_L3` | 250 | 180–350 | — | — | TR-HD-007 |
| `TRAINING_DATA_L4` | 450 | 350–600 | — | — | TR-HD-007 |
| `TRAINING_DATA_L5` | 700 | 550–900 | — | — | TR-HD-007 |
| `XP_T1` / `XP_T2` / `XP_T3` | 15 / 35 / 70 | 8–25 / 20–50 / 40–100 | <8: a zone over-levels · >100: a zone under-levels | the thresholds | TR-HD-007 |
| `XP_BOSS` | 200 | 100–300 | — | — | TR-HD-007 |
| `DEF_CAP_PCT` | 25 | 0–25 (MVP), 0–40 (VS) | >25: the telegraph stops reading | `taken ≥ 1` | F-HD-03 |
| `ENEMY_HP_T1` / `T2` / `T3` | 30 / 60 / 120 | 20–40 / 45–75 / 90–150 | off-ladder: the TTK ruler breaks | `chain_damage` | F-HD-10 |
| `BOSS_HP` | 300 | 200–400 | <200: the boss is a room · >400: a slog | the phases | F-HD-10 |
| `STRIKE_DMG_P1` / `P2` / `P3` | 6 / 12 / 20 | 4–8 / 9–15 / 16–24 | <4: chip damage · >24: a heavy is a death sentence | `DEF_CAP_PCT` | F-HD-01 |
| `HEAL_ITEM_AMOUNT` | 25 | 15–35 | <15: the charge is a bandage · >35: the heal trivializes attrition | `QUICK_SLOT_MAX` | F-HD-06 |
| `QUICK_SLOT_MAX` | 3 | 1–5 | <1: the chip is dead · >5: the HUD chip grows into the thumb zone | `HEAL_ITEM_AMOUNT` | TR-HD-030 |
| `CACHE_REFILL` | 3 | 1–5 | — | `QUICK_SLOT_MAX` | F-HD-06 |
| `RESTORE_MODULE_HEAL_PCT` | 0.5 | 0.3–0.7 | <0.3: the second life is a formality · >0.7: the module replaces the cache | `REVIVE_IFRAME_MS` | F-HD-06 |
| `REVIVE_IFRAME_MS` | 1000 | 600–1500 | <600: the revive is a re-death · >1500: the second life is free | `RESTORE_MODULE_HEAL_PCT` | TR-HD-025 |
| `RESTORE_MODULE_CAP_MVP` | 1 | 1–2 | >2: the module is a stock | `RESTORE_MODULE_HEAL_PCT` | TR-HD-025 |
| `LOW_HP_THRESHOLD_PCT` | 0.25 | 0.15–0.35 | <0.15: the cue is late · >0.35: the cue is constant | the HUD | F-HD-07 |
| `DAMAGE_EVENT_MAX_AGE_TICKS` | 2 | 1–2 | >2: a ghost hit can survive a load | the gate | F-HD-15 |
| `DAMAGE_NUMBER_LIFETIME_MS` | 700 | 400–1000 | <400: unreadable · >1000: clutter | the pool | TR-HD-036 |
| `DAMAGE_NUMBER_POOL` | 32 | 16–64 | <16: drops under a swarm · >64: memory | the soak | TR-HD-038 |
| `CRIT_MULT` (VS) | 1.5 | 1.3–1.8 | — | the counter prohibition | F-HD-02 |
| `AGI_RECOVERY_FLOOR_MS` (VS) | 900 | 800–1200 | <800: the stagger-proof build | `worst_case_arc_ms` | F-HD-14 |
| `ENERGY_BASE` / `ENERGY_PER_LEVEL` | 50 / 10 | 30–80 / 5–15 | — | the VS consumer | F-HD-14 |
| `ENERGY_REGEN_PER_S` | 5 | 2–10 | — | the VS consumer | F-HD-14 |
| `MANA_BASE` / `MANA_PER_LEVEL` | 30 / 5 | 20–50 / 3–8 | — | the VS consumer | F-HD-14 |
| `MANA_DEMONIC` / `HUMAN` / `CYBORG` / `MACHINE` (VS) | 12 / 6 / 2 / 0 | 8–20 / 4–10 / 1–4 / 0 | — | `soul_class` | TR-HD-009 |

**Cross-system inputs (consumed at registration — not SYS-07 knobs, but validated by SYS-07):** `physics_tps` (engine) · the SYS-08 damage values (`ATK1_DAMAGE` 10, `ATK2_DAMAGE` 20, `CROUCH_ATTACK_DAMAGE` 8, `AIR_ATTACK_DAMAGE` 10; registered in `design/registry/entities.yaml`) and `COUNTER_CLASH_MULT` 1.5 · `KNOCKDOWN_POWER` 2 · the SYS-06 `KNOCKDOWN_MS` 500 + `GETUP_MS` 700 = 1200 · `STAGGER_MS` 500 (the lose branch) · `BACKDASH_IFRAME_MS` 140, `GETUP_IFRAME_MS` 300 · **`CHIP_HOLD_COMMIT_MS` 150** (SYS-01's chip) · `QUICK_SLOT_MAX` (SYS-17's item stack at VS) · the enemy `power` (SYS-13). A missing or invalid cross-system input is a dev boot failure, never a silent default.

**Not knobs (documented so nobody adds them):** `chain_damage` (derived) · `chain_cycle_ticks` (derived) · `ttk_chains` (derived) · the damage order (a law) · the identity-at-default (a law) · `hp_ratio` (derived) · the death edge (a law) · the parity bands (a law, not a tuning range) · the heal-then-damage order (a law) · the eight verbs (SYS-01's) · the strike `power` (SYS-13's).

**Provisional lifetimes:** `HP_PER_POINT` / `ATK_PER_POINT` / the training thresholds (playtest) · `HEAL_ITEM_AMOUNT` / `QUICK_SLOT_MAX` (playtest) · `RESTORE_MODULE_HEAL_PCT` / `REVIVE_IFRAME_MS` / `RESTORE_MODULE_CAP_MVP` (playtest) · `STRIKE_DMG_P1/P2/P3` (SYS-13's enemy pacing) · `DEF_CAP_PCT` (SYS-16's VS sheet) · the damage-number lifetime/pool (SYS-24/SYS-29) · the energy/mana values (VS) · the Elegy table (VS).

## Visual/Audio Requirements

*(Health names the states and event edges; rendering is SYS-24's, VFX/audio design is SYS-29/SYS-04's.)*

- **The HP bar:** a segment-readable bar (SYS-24 owns the segmentation), pale bone on dark; the low-HP cue at ≤ 25% (a slow pulse, not a flash); no red fill — the bar's loss is read by length, not alarm color. The boss bar appears only for SYS-14's boss (SYS-24 renders).
- **Damage numbers:** amber for enemy damage, pale bone for player damage taken, cyan for heals, gold glyph for crits (VS). Zero-frame with the hit-stop; 700 ms; small, muted, short-lived. **Never sigil-red.** No "CRITICAL" text. The off-switch hides all numbers.
- **The heal:** a cyan shimmer on the chassis; the charge pip dims; the number rises. No screen flash.
- **The death beat:** monochrome glitch (SYS-29's signature VFX), **SYSTEM OFFLINE** in the print voice, *you are destroyed* quiet underneath (the lowercase is deliberate — the quiet line under the loud headline; SYS-15/28 may rule otherwise), and the **cause row printed from the `DeathRecord`** (the heavy's name, the strike, the tick). The options are diegetic print rows. **The death sting is the fiction's glitch magnitude, not an alarm** — it scales with `overkill_ratio` as a system-fault readout, never as punishment punctuation.
- **The revive:** a hard cyan reboot pulse; the 60-tick window reads as a hum, not a shield bubble.
- **The training point:** a small diegetic cue on the HUD at level-up and a print row at the cache; no fanfare.
- **Animation states (SYS-24 renders):** hit reaction (shared with Combat/Movement), the death collapse, the reconstruct boot, the revive reboot, the heal shimmer, the chip press.
- **Audio (SYS-04 designs):** the damage tick (pitched by amount band, never a per-hit voice), the heal chime, the death power-down, the revive boot, the level-up print. No per-press popups; no "ORDER RECEIVED."

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:health-damage` for per-asset descriptions, dimensions and generation prompts.

## UI Requirements

**The read contract, not a screen.** SYS-07 publishes `HealthRead`, `DamageNumber`, `DeathEdge` and `HealEdge`; SYS-24 owns the rendering.

- **HP bar:** player only; the boss bar is SYS-14/SYS-24's. No enemy HP bars for regular enemies (the hit reaction is the read).
- **Quick-slot chip:** one item type, 3 charge pips, the 150 ms hold-to-commit ring; the hit rect is SYS-01's; the visuals are SYS-24's. **No auto-use.** The chip is **hard-required** for the MVP heal.
- **Damage numbers:** SYS-24/SYS-29 render; the off-switch is a setting.
- **Level/training cue:** level and a banked-point pip; the allocation prompt lives at the cache (SYS-15's station surface).
- **The death screen:** SYS-15 owns the screen; SYS-07 supplies the options contract, the `DeathRecord` cause row and the revive availability.
- **No stat sheet at MVP.** The nine-stat readout is VS (SYS-16/SYS-26); at MVP the pause screen may show **level, HP, ATK and DEF** as a short diegetic readout (four values; SYS-24's call).

**UX flag:** `/ux-design` for the HP bar + quick-slot chip + damage-number legibility + the System Offline screen **before the SYS-24/SYS-15 UI stories**. The chip's thumb coverage and the bar's safe-area placement are SYS-24/SYS-32's; the numbers' world-vs-native anchoring is a SYS-24 decision with a real mobile cost; the legibility audit runs at the locked art scale (480×270).

## Acceptance Criteria

**Classification legend:** `[GUT]` automatable in Godot Unit Test · `[DEVICE]` on-device manual QA · `[PLAYTEST]` human feel observation with the SYS-01 AC-63 protocol. Dual tags mean the GUT half gates first, the DEVICE half confirms.

### The boundary and the data model

- **AC-HD-01** [GUT] *(TR-HD-001)* — **GIVEN** a mocked `DamageEvent` stream and a human capture replayed through the resolver, **WHEN** the same events run, **THEN** the traces are bit-identical over 600 ticks; `src/health/` contains **zero** `Input.` and zero hitbox-probe symbols (CI grep).
- **AC-HD-02** [GUT] *(TR-HD-002)* — **GIVEN** the consumer enum, **WHEN** the membership check runs, **THEN** it is exactly `{NORMAL, COUNTER, DEFLECT, ENEMY_STRIKE, ENVIRONMENT}`; Combat's producer enum is unchanged at four; `kind = ENVIRONMENT` with a non-`ENV` source is rejected; a Combat kind with `source = ENV` is rejected; `target = ENV` is rejected.
- **AC-HD-03** [GUT] *(TR-HD-003, F-HD-01)* — **GIVEN** the strike table, **WHEN** a mock strike at each power stamps `raw_damage`, **THEN** it is 6 / 12 / 20; the strike contract diff is empty; a missing table is a dev boot failure.
- **AC-HD-04** [GUT] *(TR-HD-004)* — **GIVEN** raw values 12, 12.5, −3, 0, **WHEN** the gate runs, **THEN** 12 and 0 pass, 12.5 and −3 are rejected with the named term.

### The character model

- **AC-HD-05** [GUT] *(TR-HD-006, F-HD-02/03)* — **GIVEN** level 1, no harness (ATK 100, DEF 0, precision 0, agility 0), **WHEN** every approved Combat fixture runs, **THEN** ATK1 10 / ATK2 20 / crouch 8 / air 10 / counter 15/30 / strikes 6/12/20 / tiers 30/60/120 are exact; no approved fixture changes.
- **AC-HD-06** [GUT] *(TR-HD-006)* — **GIVEN** a training-point spend, **WHEN** the StatBlock recomputes, **THEN** exactly one `StatRevision` bumps (a recompute spy counts 1), zero per-tick recomputes occur over 600 ticks, and the next hit uses the new value.
- **AC-HD-07** [GUT] *(TR-HD-007, F-HD-14)* — **GIVEN** the training thresholds, **WHEN** kills accrue, **THEN** L2 at 100, L3 at 250, L4 at 450, L5 at 700; 4 points by L5; a point cannot be spent outside a cache; a banked point is legal (`atk_points + hp_points + banked_points = level − 1`); 4 ATK points → ATK 132, ATK1 14, ATK2 27, chain 41, max HP 100; 4 HP points → max HP 132, ATK 100; 2/2 → 116/116; each +HP point raises current HP by 8.
- **AC-HD-08** [GUT] *(TR-HD-008)* — **GIVEN** the pools at L1/L5, **WHEN** they tick, **THEN** energy is 50/90 and mana 30/50; 60 logic ticks of regen raise energy 50 → 55; a 30-tick freeze holds it; the `HealthRead` contains no energy/mana field at MVP; the save round-trips both.
- **AC-HD-09** [GUT] *(TR-HD-009)* — **GIVEN** a mock enemy defeat, **WHEN** the edge fires, **THEN** one `DefeatEvent` publishes with the `soul_class` and the killer id; a second lethal event in the same tick publishes nothing; the machine payoff is 0 at VS (AC record: OQ#13).

### Application

- **AC-HD-10** [GUT] *(TR-HD-010)* — **GIVEN** boot, **WHEN** the pool initializes, **THEN** HP is 100; a static assertion finds no writer outside `HealthCore`; a max-HP change clamps the current HP.
- **AC-HD-11** [GUT] *(TR-HD-011, F-HD-10)* — **GIVEN** the tiers, **WHEN** the TTK runs at the chain-damage extremes 20–41, **THEN** T1 1–2, T2 2–3, T3 3–6, boss 8–15 chains; at defaults 1 / 2 / 4 / 10 and 0.617 / 1.233 / 2.467 / 6.167 s.
- **AC-HD-12** [GUT] *(TR-HD-012)* — **GIVEN** a profile fixture, **WHEN** it registers, **THEN** a floor ≥ max fails the boot; an unknown target is rejected; the `iframe_windows` are present.
- **AC-HD-13** [GUT] *(TR-HD-005, F-HD-02/11)* — **GIVEN** ATK 100/108/116/124/132, **WHEN** the dealt and counter formulas run, **THEN** ATK1 10/11/12/13/14, ATK2 20/22/24/25/27, crouch 8/9/10/10/11, air 10/11/12/13/14, ATK2 counter 30/33/35/38/40, ATK1 counter 15/17/18/19/20; the cap clamps; a COUNTER never crits; the order is base → attack scaling (dealt) / defense mitigation (taken) → crit (dealt, NORMAL only) → floor → cap.
- **AC-HD-14** [GUT] *(F-HD-03)* — **GIVEN** DEF 0/5/25, **WHEN** the taken formula runs, **THEN** 6/12/20, 5/11/19, 4/9/15; raw 1 at DEF 25 → floor(0.75) = 0 → **1** (the floor for positive raw); raw 0 → **0** (the zero-exempt floor); DEF 100 clamps to 25 → 4/9/15.
- **AC-HD-15** [GUT] *(TR-HD-013, F-HD-04)* — **GIVEN** 20 into 8, **WHEN** the subtraction runs, **THEN** hp 0, overkill 12; a 0-damage event changes nothing; HP is never negative.
- **AC-HD-16** [GUT] *(TR-HD-014, F-HD-05)* — **GIVEN** three lethal events in one tick, **WHEN** they apply, **THEN** exactly one `DeathEdge` publishes; the later two are rejected; the latch clears only on reconstruct/revive.
- **AC-HD-17** [GUT] *(TR-HD-015)* — **GIVEN** the seeded 10,000-event fuzz (mix: 40% NORMAL, 20% COUNTER, 10% DEFLECT, 20% ENEMY_STRIKE, 10% ENVIRONMENT; the oracle: no invalid event applies, HP ∈ [0, max], every death has a record), **WHEN** it runs, **THEN** every edge has a valid `DeathRecord` and no death occurs without one; the record's cause is the first lethal event.
- **AC-HD-18** [GUT] *(TR-HD-016, F-HD-09)* — **GIVEN** a duplicate tuple, **WHEN** it applies, **THEN** the second is rejected; a same-tick distinct kind applies twice; the ledger is 256 and bounded.
- **AC-HD-19** [GUT] *(TR-HD-017, F-HD-15)* — **GIVEN** one fixture per validation term (11), **WHEN** the gate runs, **THEN** each fails with its named reason; a 10,000-event fuzz applies no invalid event.
- **AC-HD-20** [GUT] *(TR-HD-018)* — **GIVEN** hits inside the backdash (140 ms), getup (300 ms) and revive (1000 ms) windows, **WHEN** the lock runs, **THEN** all are rejected; a hit in the 8-tick backdash exposure applies; a void hit during any i-frame window still kills.
- **AC-HD-21** [GUT] *(TR-HD-019)* — **GIVEN** an enemy-vs-enemy DEFLECT event, **WHEN** it applies, **THEN** it lands; a player self-hit is rejected; the reducer has no team assumption.
- **AC-HD-22** [GUT] *(TR-HD-020)* — **GIVEN** two enemies hitting the same tick, **WHEN** the ordering runs, **THEN** the lower source id resolves first; the death cause is the first lethal applied; the second publishes no edge; a source-9 lethal hit at T and a source-2 hit for T arriving at T+1 → the source-9 hit is the cause and the late event is rejected (DEAD); a lethal hit + a heal in one tick → the death stands, the heal is refused, the charge remains.
- **AC-HD-23** [GUT] *(TR-HD-021)* — **GIVEN** a boss profile, **WHEN** a 30 hit meets cap 10, **THEN** 10 applies; a lethal hit at floor 1 leaves 1 HP and no edge; the release allows it; an immune kind is rejected.

### Death and respawn

- **AC-HD-24** [GUT] *(TR-HD-022)* — **GIVEN** the state machine, **WHEN** damage arrives in DEAD/RECONSTRUCTING, **THEN** it is rejected; no transition occurs without a player choice.
- **AC-HD-25** [GUT] *(TR-HD-023)* — **GIVEN** a death with no input, **WHEN** 10,000 ticks pass, **THEN** the state is still DEAD; the options are reconstruct / revive (greyed with 0 modules) / quit; no auto-respawn exists; the cause row matches the `DeathRecord`.
- **AC-HD-26** [GUT] *(TR-HD-024, F-HD-08)* — **GIVEN** a reconstruct, **WHEN** the reset runs, **THEN** HP max, the ledger empty, the latch clear, the quick slot 3; a stale pre-death event is rejected by the age bound.
- **AC-HD-27** [GUT] *(TR-HD-025, F-HD-06)* — **GIVEN** a carried restore module, **WHEN** it is drawn, **THEN** HP 50% (66 at 132), one module consumed, 60 ticks of invulnerability, the record archived; a death with a module carried stays DEAD until chosen; the first cache activation grants exactly one module (cap 1); a module pickup at cap 1 stays.
- **AC-HD-28** [GUT] *(TR-HD-026/027)* — **GIVEN** a death edge, **WHEN** the gate request applies, **THEN** the edge raised a non-ack request; the request applies at the next gate-entry phase; no damage is applied on the transition frame. *(The buffer/verb assertions are SYS-01/Combat's, cited not owned: SYS-01 AC-59, AC-CMB-29.)*
- **AC-HD-29** [GUT] *(TR-HD-027)* — **GIVEN** a pre-death event replayed after the reconstruct, **WHEN** it arrives, **THEN** it is rejected as stale; a post-reconstruct fresh event applies.
- **AC-HD-30** [GUT] *(TR-HD-028)* — **GIVEN** a hit that starts a 70 ms hit-stop, **WHEN** the tick runs, **THEN** the order is contact → damage → freeze: the damage applies on the contact tick, then the freeze holds; a scripted `ENVIRONMENT` event during a freeze applies.

### Items and healing

- **AC-HD-31** [GUT] *(TR-HD-029, F-HD-06)* — **GIVEN** a 25 heal at 90/100, **WHEN** it applies, **THEN** 10 is applied, 15 discarded, and `quick_charges` drops by 1; at full HP the use is refused and `quick_charges` is unchanged.
- **AC-HD-32** [GUT] *(TR-HD-030)* — **GIVEN** the Suture and the chip, **WHEN** a 150 ms hold commits, **THEN** one charge is consumed and 25 HP applied on the commit tick (clamped); a busy body waits per TR-INP-029; an empty slot refuses; one charge per commit; no `body_busy` is raised.
- **AC-HD-33** [GUT] *(TR-HD-031)* — **GIVEN** a dropped Suture, **WHEN** the player walks over it, **THEN** nothing happens; Interact picks it up (+1 charge); a full slot leaves it on the ground; the label is `TAKE`; a module at cap 1 stays.
- **AC-HD-34** [GUT] *(TR-HD-032)* — **GIVEN** a cache station, **WHEN** the restore runs, **THEN** HP max, the quick slot 3, the first-activation module; the save round-trip has no HP field; a load is full.
- **AC-HD-35** [GUT] *(TR-HD-033)* — **GIVEN** a SYS-17 mock, **WHEN** it provides the item id and amount, **THEN** SYS-07 applies; no SYS-07-owned inventory screen exists.

### Economy and publication

- **AC-HD-36** [GUT] *(TR-HD-034, F-HD-13)* — **GIVEN** the Dirge chain-loop harness (fixed dummy: infinite HP, no knockback, hit-stop excluded from the loop clock, the chain started at melee reach), **WHEN** it runs, **THEN** the cycle is 37 ticks and `dps_chain = 48.65 ± 0.01`; the 60 s integral is 2920 (97 chains + one ATK1); the single-arc loop is 27.27 ± 0.01; Dirge is the only shipped MVP weapon.
- **AC-HD-37** [GUT] *(TR-HD-035)* — **GIVEN** the read contract, **WHEN** a SYS-24/SYS-29 mock consumes it, **THEN** every field is present; no writer field exists; the schema is read-only; `hp_ratio`/`low_hp` at 25/100 (low), 26/100 (not), 33/132 (low).
- **AC-HD-38** [GUT] *(TR-HD-036)* — **GIVEN** a hit, **WHEN** the number publishes, **THEN** it is on the contact tick; the pool never allocates mid-run; the palette audit finds no sigil-red; the off-switch hides all numbers.

### Testability, performance, traceability

- **AC-HD-39** [GUT] *(TR-HD-037)* — **GIVEN** a scripted trace, **WHEN** it replays twice through `HealthCore` with `FakeHealthPort`/`FixedRngPort`, **THEN** the traces are bit-identical; the MVP run performs zero rolls; at VS two different hash keys yield different rolls but identical timing; the fixture repeats bit-identically.
- **AC-HD-40** [GUT] *(TR-HD-038)* — **GIVEN** a 10,000-tick soak (600-tick warm-up, counters reset), **WHEN** the structures run, **THEN** net object delta 0, net resource delta 0, heap growth ≤ 256 KB, churn ≤ 16 KB / 1,000 ticks; the named structures are preallocated (entity 64, event ring 32, ledger 256, number pool 32, telemetry 600, one `HealthRead`/`StatRevision`); no hot-path allocation.
- **AC-HD-41** [DEVICE] *(TR-HD-038)* — **GIVEN** the QA plan §5.1 reference SKU, **WHEN** **W13** runs 10,000 ticks after a 600-tick warm-up, **THEN** the SYS-07 tick budget is p99.9 ≤ 0.25 ms / max ≤ 0.75 ms. **W13 definition:** 2,000 damage events (40% NORMAL / 20% COUNTER / 10% DEFLECT / 20% ENEMY_STRIKE / 10% ENVIRONMENT), 100 death→reconstruct cycles (60 ticks each), 200 heals, 500 i-frame rejections, 500 idempotence duplicates, 50 boss-floor/cap events; the enemy fixture: power 1/2/3, the freeze windows 70/90/40 ms; nearest-rank estimators and sample counts are the SYS-01 QA plan §5.3's. **The four-system arithmetic envelope is p99.9 ≤ 2.0 ms (1.0 + 0.3 + 0.3 + 0.25 = 1.85) and max ≤ 4.75 ms (2.0 + 1.0 + 1.0 + 0.75)** — the re-baseline of AC-CMB-39's three-system 4.0 ms claim (OQ#19).
- **AC-HD-42** [DEVICE] *(TR-HD-035/036)* — **GIVEN** the device matrix at the locked 480×270 art scale, **WHEN** the HUD read runs, **THEN** the HP bar, the chip (3 pips, 150 ms ring), the damage numbers and the low-HP cue are legible; no number occludes the body; the safe-area placement holds.
- **AC-HD-43** [DEVICE] *(TR-HD-023)* — **GIVEN** a death on device, **WHEN** the screen presents, **THEN** no auto-respawn occurs; the three options are reachable; the revive option is greyed with 0 modules; the reconstruct returns to the last cache with a full pool; the cause row is legible.
- **AC-HD-49** [GUT] *(TR-HD-039)* — **GIVEN** the TR-HD registry, **WHEN** the traceability audit runs, **THEN** every TR has an AC or a recorded guidance note, every formula has an AC, the counts are 39 TR / 15 formulas / 50 ACs / 68 edge bullets / 19 OQ rows, and no `[To be designed]` exists.
- **AC-HD-50** [GUT] *(TR-HD-023, F-HD-12)* — **GIVEN** the lose-branch record, **WHEN** the economy audit runs, **THEN** the lose branch deals 0 damage and a 500 ms stagger with no `KnockbackOrder` and no `DamageEvent`; a power-1 follow-up at 300 ms totals 480 ms vs a clean 180 ms; a power-2 follow-up at 300 ms totals 1500 ms vs a clean 1200 ms; the delta is 250–500 ms in every case.

### Feel and device

- **AC-HD-44** [PLAYTEST] *(Player Fantasy, TR-HD-015/023)* — **GIVEN** 5 playtesters × 30 min (the SYS-01 AC-63 protocol), **WHEN** the trust rubric codes **D1 death-as-story** and **D2 death-beat-not-punishment**, **THEN** each reaches ≥ 3/5.
- **AC-HD-45** [PLAYTEST] *(TR-HD-036)* — **GIVEN** the same cohort, **WHEN** the rubric codes **D3 numbers-subordinate**, **THEN** ≥ 3/5 describe the numbers as confirmation, not as the fight.
- **AC-HD-46** [PLAYTEST] *(TR-HD-029/030/031)* — **GIVEN** the same cohort, **WHEN** the rubric codes **D4 heal-as-decision**, **THEN** ≥ 3/5 report a deliberate heal decision.
- **AC-HD-47** [PLAYTEST] *(TR-HD-023; the SYS-08 amendment)* — **GIVEN** the same cohort and a session script that includes **at least one lost clash per tester** (a scripted power-2 heavy vs ATK1), **WHEN** the rubric codes **D5 lose-punish-legible**, **THEN** ≥ 3/5 of the testers who lost a clash can describe the follow-up before it landed; the denominator is the testers who lost ≥ 1.
- **AC-HD-48** [PLAYTEST] *(TR-HD-007)* — **GIVEN** the same cohort and a session script that includes **at least one cache point spend per tester**, **WHEN** the rubric codes **D6 growth-felt**, **THEN** ≥ 3/5 report a felt change after the first point; the denominator is the testers who spent ≥ 1.

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[DEVICE]`/`[PLAYTEST]` describe where an AC runs, not which gate owns it.

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP smoke** | **42** | AC-HD-01…40, AC-HD-49, AC-HD-50 | Headless GUT on the CI build |
| **MVP device** | **3** | AC-HD-41, AC-HD-42, AC-HD-43 | Device matrix (QA plan §7.1) |
| **MVP-lock** | **5** | AC-HD-44…48 | Playtest + coded rubric (SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The VS content (full inventory, energy consumers, mana, crit/agility, elements, Elegy) is recorded in the Open Questions, not AC'd at MVP |
| **Total** | **50** | | 42 + 3 + 5 + 0 = 50 |

**Exactly-one proof.** Every AC-HD-01…50 appears in exactly one gate; no AC is in two gates; the count is 50. The DEVICE-tagged ACs do not default home to smoke; the playtest ACs are MVP-lock, not smoke. The Health QA plan will expand the device/playtest protocols; this manifest is the GDD-side partition.

### Playtest coding table (D1–D6)

The **five playtest ACs** use the SYS-01 AC-63 protocol: ≥5 testers × ≥30 min, two facilitators coding per statement, agreement ≥ 90%, Cohen's kappa ≥ 0.7, disagreements adjudicated by the definition list, never by taste. **The negation rule is the SYS-01 AC-63 operationalization:** a negated forbidden term within 3 tokens of its subject does **not** block; a negated inclusion term **does** block; set-membership idioms are evaluated first; the negation is logged and the negation counts reported. **The six codes** (D1–D6) map onto the five ACs: AC-44 carries D1+D2, AC-45 D3, AC-46 D4, AC-47 D5, AC-48 D6.

| Code | Inclusion set | Exclusion set |
|---|---|---|
| **D1 death-as-story** | knew what killed me, I can tell you why, my fault, the read, saw it | random, unfair, out of nowhere, lag, didn't register |
| **D2 death-beat-not-punishment** | a beat, a moment, the screen, the choice, reconstructed | reload, restart, punished, wasted my time |
| **D3 numbers-subordinate** | confirmation, tells me the truth, I still watch the body, the number agrees | the numbers are the fight, I only watch numbers, clutter |
| **D4 heal-as-decision** | I chose, I saved it, I made space, worth it, should have healed | spammed, forgot, hoarded, useless |
| **D5 lose-punish-legible** | saw it coming, knew the follow-up, should have used ATK2, the weight | gotcha, unfair, couldn't react, random |
| **D6 growth-felt** | stronger, faster kill, the point mattered, felt the difference | no difference, flat, same fight |

### VS record (not AC'd at MVP)

The VS content is recorded in the Open Questions, not gated: the full inventory/equipment/assignable quick slot (OQ#6) · the energy consumers, the charge attack, efficiency/regen (OQ#12) · mana live, the Stinger, the `soul_class` payoffs (OQ#13) · Elegy-013 + switching (OQ#14) · elements/resistances (OQ#15) · crit + agility recovery (F-HD-02/14) · the nine-stat sheet (OQ#5).

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **Quick-use chip promotion (SYS-01)** — the chip moves from VS to MVP; the verb table row, `TR-INP-029`'s "at VS" clause and **the six chip ledger units** (AC-33 chip, AC-35, AC-36 chip, AC-37 chip, AC-60 chip, AC-69 chip) move; **AC-42 stays VS** (the Stinger, not a chip clause); the 96-unit AC→gate ledger must be re-derived; `CHIP_HOLD_COMMIT_MS` joins the cross-system inputs. **Blocking: before the first SYS-07 story.** | SYS-01 + qa-lead | Before the first SYS-07 story |
| 2 | **The clash-lose amendment (SYS-08)** — TR-CMB-012's rule **and its test clause** ("the damage event" → "no damage event"), AC-CMB-14, and the "the clash denies the exchanged strike; it is not a shield" rationale; a **new Combat OQ** (not the resolved OQ#2, which is the stagger-ownership row); the follow-up carries the damage. **Blocking: before the first Combat story.** | SYS-08 | Before the first Combat story |
| 3 | **The damage-numbers reversal (SYS-08 Visual/Audio)** — "not a floating number at MVP" is superseded; SYS-24/SYS-29 render the numbers. | SYS-08 + SYS-24 | With #2 |
| 4 | **The SYS-13 follow-up + power legibility + `soul_class`** — at least one clash-capable archetype whose follow-up lands inside the 500 ms stagger; the follow-up telegraph ≥ 250 ms from the stagger start; the strike's `power` legible in the telegraph; `soul_class` on every enemy type; the follow-up's power (F-HD-12 assumes 2), the enemy tier/hp_max/defense, and the `DefeatEvent` killer. | SYS-13 | At SYS-13 authoring |
| 5 | **The SYS-16 scope split** — MVP points-only level 1–5 (owned by SYS-07) vs the full nine-stat sheet (VS); the curve handoff; whether the VS curve keeps the +8 points (L20 + 19 points = 366 vs the printed 214). | SYS-16 | At SYS-16 authoring |
| 6 | **The SYS-17 MVP carve-out** — the Suture + the fixed quick slot + the restore module at MVP; the full inventory/equipment/assignable slot at VS. | SYS-17 | At SYS-17 authoring |
| 7 | **The SYS-03 save schema** — the field list (level, training data/points, stat sources, charges, modules, quickslot); **store sources, derive targets**; `schema_version` + migration from day one. | SYS-03 | At SYS-03 authoring |
| 8 | **The SYS-15 System Offline screen** — the monochrome glitch, the print copy, the neural terminal, the cause row, the counter on reconstruction **and on revive**, the counter persistence across quit/reload, the reconstruct/quit options, the lowercase *you are destroyed* ruling. | SYS-15 + SYS-28 | At SYS-15 authoring |
| 9 | **The SYS-24 HUD** — the HP bar, the boss bar, the damage numbers' world-vs-native anchoring, the chip (3 pips), the low-HP cue, the level/training cue. | SYS-24 | At SYS-24 authoring |
| 10 | **Boss values** — HP (200–400), the per-event cap, the phase floors, the immune kinds, the scripted death. | SYS-14 | At SYS-14 authoring |
| 11 | **Enemy tiers per type** — which MVP enemy is T1/T2/T3; the `soul_class` tags. | SYS-13 | At SYS-13 authoring |
| 12 | **Energy consumers** — the charge attack (SYS-08) and the efficiency/regen curves; the first live energy sink. | SYS-08 + SYS-16 | VS |
| 13 | **Mana live** — the Stinger (SYS-12) + the `soul_class` payoff matrix. | SYS-12 + SYS-13 | VS |
| 14 | **Elegy-013 + weapon switching** — the second weapon table, the **per-weapon arc-range extension** (its 250/450 ms arcs exceed Combat's player-arc ranges), the fixture set, the swap UI. | SYS-17 + SYS-16 + SYS-08 | VS |
| 15 | **Elements/resistances** — the 2–3 element matrix and the harness modules. | SYS-16 + SYS-13 | VS |
| 16 | **In-place respawn i-frames** — if SYS-15 ever respawns outside a cache station, a grant is required. | SYS-15 | VS |
| 17 | **Multi-hit `strike_id`** — a per-strike id would replace the tuple key if SYS-13 ever ships same-tick multi-hit strikes. | SYS-13 | VS |
| 18 | **The nine-stat sheet readout** — the pause-screen diegetic readout (level, HP, ATK, DEF at MVP; the full sheet at VS) vs no readout; the "no stat-spreadsheet menus" anti-pillar. | SYS-16 + SYS-24 | VS |
| 19 | **The four-system perf envelope re-baseline** — AC-CMB-39's three-system max 4.0 ms becomes 4.75 ms with SYS-07's 0.75; the QA plan's S_base/S_burst partition must name the four-system claim. | qa-lead + SYS-01 | Before the SYS-07 QA plan |
