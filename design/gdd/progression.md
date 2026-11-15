# Progression

> **Status**: **APPROVED (2026-11-15, lane SYS-16)** — CD-GDD-ALIGN APPROVED (two passes; pass 1 CONCERNS → repaired) · three-seat panel NEEDS REVISION (3 creative + 10 technical + 10 QA blockers) → all revised in-session → qa-lead spot-check **PASS (round 4)** → final micro-check **PASS (round 2)**. Scope: the MVP-minimal level 1–5 progression layer, the **MVP gear layer** (D-1, 2026-11-14) and the ability unlock ladder. Consumes SYS-07's authored economy without re-deriving it; owns the spend/progression layer *around* the printed damage ladder (SYS-15 is the ladder's MVP consumer; SYS-16 owns the growth law the ladder sits in).
> **Author**: user + systems-designer (creative seat, GLM-5.3-Flash) + gameplay-programmer (technical seat, DeepSeek V4.1 Flash) — via /design-system
> **Last Updated**: 2026-11-15
> **Last Verified**: 2026-11-15 (qa-lead spot-check PASS round 4 + final micro-check PASS round 2; the counts and every worked example re-derived against the consumed fixtures)
> **Design Review**: CD-GDD-ALIGN **APPROVED** (2026-11-15) · three-seat review NEEDS REVISION (3 + 10 + 10) → all revised · qa-lead spot-check **PASS** · micro-check **PASS** — record at `design/gdd/reviews/sys16-progression-review-log.md`
> **Implements Pillar**: "SotN, Not Hollow Knight" (levels, drops, gear, save sanctuaries as structure, not decoration) · "Read, Then Strike" (gear changes *how* you read an exchange; it never buys the read) · "Remade Every Death" (growth is the machine's memory of what it learned, and it survives the print)
> **System ID**: SYS-16 (Feature layer, MVP)
> **Counts**: 28 TR-PRG · 10 formulas · 12 V-PRG · 36 ACs · 44 edge bullets · 8 OQ rows · 21 knob rows · gate manifest 29 + 2 + 5 + 0 = 36
> **Contracts**: SYS-07 `design/gdd/health-damage.md` (APPROVED 2026-11-12; **revised 2026-11-15 by D-ORCH-03**) — TR-HD-006 (`StatBlock` + the identity law + the gear riders), TR-HD-007 (the MVP level 1–5: thresholds 20/50/90/140, awards 3/7/14/40, points +8 ATK / +2 HP, cache-only), TR-HD-010/011 (the pool, the tiers), TR-HD-035 (`HealthRead`), F-HD-02 (the ladder + the module stage), F-HD-03 (`taken`, `DEF_CAP_PCT` 25, R10), F-HD-13/14 (the parity, the printed ladder), **OQ#5 + OQ#18 + OQ#20 (all resolved here)**; SYS-08 `design/gdd/combat.md` (APPROVED + D-ORCH-03) — `DamageEvent.arc`, the weapon table 2/4/2/2, the counter 1.5×, the `AttackContext` transport; SYS-13 `design/gdd/enemy-ai-telegraphs.md` (APPROVED) — Husk T1 / Spitter T2 / Warden T3, `soul_class`, the `DefeatEvent`; SYS-06 `design/gdd/movement.md` (APPROVED) — the traversal gates (Dash action-level; Wall Jump / Double Jump behaviour-level on Jump), `WALL_CLIMBABLE`, `air_jump_used`; SYS-01 `design/gdd/input-control-mapping.md` (UNFROZEN, #10 record) — TR-INP-003 (Dash Locked-at-start), TR-INP-057 (the gates live in SYS-06; the input record is bit-identical), the dormant Dash socket + `DORMANT_DIM_AFTER_TEASE`; SYS-15 `design/gdd/cache-stations-death.md` (APPROVED) — TR-CSD-006 (the frozen spend surface), TR-CSD-012/013 (the carry law, the three-baseline ledger), TR-CSD-016 (the `cache` v1→v2 bump); SYS-03 (the persistence envelope, ADR-0002); `design/reviews/metroidvania-benchmark-audit.md` — D-1, IP-5, IP-16; `design/gdd/game-concept.md` — the frozen MVP definition, the anti-pillar D-2, the Gate-2 parity-promise probe.

## Overview

Progression is the layer that answers *what the body becomes*. It sits above SYS-07's resolver: SYS-07 owns the number a hit costs, the printed damage ladder and the points-only level 1–5 data; **SYS-16 owns the growth law the ladder sits in** — the seam from the points model into the full sheet (levels 6–20), the pacing budget that makes the four points land where the slice needs them, the **gear layer** that turns two equipment slots into a build, and the **ability ladder** whose grants flow into SYS-06's gates. It never resolves damage, never decides a hit, and never writes a stat that another system owns: it publishes a `GearAggregate` and a `GrantEvent`, and the owners apply them.

The MVP's progression is deliberately small and deliberately honest. Four points, spent at one terminal, each worth exactly one step of a printed ladder. Three named modules, two typed slots, one guaranteed part behind the truth's flip. Three locked abilities whose absence is the slice's shape. The whole layer is bounded by one finding that governs every number in it:

**The Quantisation Law.** At the 20-HP baseline every lever's smallest integer step is larger than the ±10% band the game promises. One chain point on a chain of six is +16.7%. One point of `defense` is the entire 25-point cap, because at raw 1–4 any `defense ≥ 1` returns the same 1/1/3. So no lever can move unconditionally without breaking a promise — and the design's answer is not to hide the step but to make it **paid** (the gear exchange), **absent** (DEF retired), or **enumerated and closable** (the one Warden drop). That single law is why this GDD's gear section is mostly about what gear may *not* do.

→ *Implementation patterns (the `ProgressionCore` pure aggregation, the namespace writer, the loadout validator) are ADR raw material for the planned **Progression ADR**; this GDD stays at the behavior level. The persistence envelope is ADR-0002's; the stat schema is SYS-07's.*

## Player Fantasy

### The named fantasy — The Machine Keeps What It Learned

You are a copy that gets better at being a copy. Every kill teaches the chassis something, every level is a point you carry to the terminal and *choose* to spend, and every module you bolt on is a part of some other dead thing that now works through you. Nothing about your growth is a curve that happens to you: the four points are four decisions, the two slots are two arguments, and the modules say what they cost on their face. And when the world flips and the corridor it opens holds a part of the machine's own dead, the reward is not a bigger number — it is a part that makes your swing mean something the swing did not mean before.

The counter-fantasy, refused: no spreadsheet, no nine-column sheet, no "+7.3% crit". The machine's growth is legible in the machine's own units — a point that moves ATK1 from 2 to 3 and the chain from 6 to 7, a module that takes a third of your chassis and gives a third more of your swing. You can hold the whole progression in your head at once, which is the only way a choice stays a choice.

### The contract — four terms, each testable

1. **Growth is chosen, never accrued.** Four points by level 5, spent at a cache terminal, never automatically, never mid-fight. A banked point is legal; a point spent outside a cache is refused and stays banked. The player can always name what the last point bought.
2. **The sheet is identity at default.** Level 1 with no modules returns every approved number exactly — ATK1 2 / ATK2 4 / crouch 2 / air 2 / counter 3/6 / strikes 1/2/4 / tiers 6/12/24 / `hp_max` 20 / `defense` 0. Gear is additive and visible; there is no hidden multiplier anywhere in the layer.
3. **Gear is a trade, and the trade is printed.** No module is a free step. A module that gives damage pays pool at a stated exchange; a module that gives pool stays inside the band; the one exception is enumerated, bounded, placed behind the flip, and closable by playtest. The player can say what the module costs before equipping it.
4. **The ladder is a promise, not a wall.** Dash is locked at start and the lock is *shown* — a dimmed socket that says "not yet" without a tutorial. No gate may ever strand the player: every grant gate is authored with the pre-grant path back to the cache, and the audit is a build gate, not a review note.

### Anchor moment — The Point You Chose

The Sanctum terminal. Two rows: `STRIKES +8` and `CHASSIS +2`. You have one point. The STRIKES row prints what it will do before you commit — `ATK1 2→3 · chain 6→7` — so you can see exactly what moves: the light hit gains a point and the chain closes one higher. The next point's preview prints `ATK1 3→3 · chain 7→8`, which tells you the truth the ladder has: that point is not for the light hit, it is for the *finisher's* count. You take the first. Two rooms later the light hit lands for **3** and the chain closes at 7, and the number is one higher than your hand expected — and you remember choosing it.

*(The honest ledger of the four points, because the ladder's rows are coarse: **every point shortens the boss by one chain** (10/9/8/7/6 across the five builds), **the Warden's four-to-three is the one pre-boss flip** (point 2), and the Husk and the Spitter never change. The growth-felt gate codes the **printed** change, never a guaranteed kill-time flip.)*

### Anchor moment — The Part That Costs

The Warden's governor lies on the floor of the flipped corridor, past the partition the truth opened. The pause says what it is: `damage +1`, and the frame slot is empty so nothing pays for it. You have the Coupler in the drive slot — the one that costs eight points of chassis. You put the governor in and the Coupler comes out, and your chassis goes back to 20 while your chain stays at 8. You are not stronger than the Coupler made you; you are stronger *and* whole, and the difference is a thing you found, not a thing you were given.

### Anchor moment — The Socket That Says Not Yet

The Dash socket starts hidden. You find it the first time your thumb lands where a dash ought to be — the corner lights dim, a lock glyph settles in, and nothing else happens. You press it twice in the first ten minutes. Nothing executes, nothing errors, nothing is explained. By the third room you have stopped pressing it and started *looking* for where a dash would go — and the looking is the slice's whole argument about what an unlock is for.

### Language law

**Use:** growth, point, step, chapter, part, salvage, cost, trade, chassis, frame, drive, the machine's memory, earned, chosen, printed.

**Player-facing copy — banned:** DPS, burst, tank, glass cannon, heal-spam, "+N DMG", "gear score", any number-as-identity, any percentage in a module row ("+33%" never reaches the player — the row says what moves: `damage +1`). **Diegetic serial numbers are the carved-out exception** (Dirge-042, Elegy-013, Coupler-034, Governor-207 — the chassis/serial doctrine, not a stat as identity). **GDD prose — preferred:** exchange, chain, counter, cost, build, slot. **Economy and formula tables — permitted:** `TTK`, `chain_damage`, `dps_chain`, `dmg/s`, `chain%`, `pool%` (the designer's ruler, never player copy — the SYS-07 precedent). **Telemetry/field names — unconstrained.**

### Success signature

Playtesters say: "I knew what the last point bought"; "the module told me what it cost"; "I went back for the thing behind the flipped corridor"; "the dimmed button made me look for the dash"; "I never felt like the game was hiding a number from me"; nobody asks for a stat screen, a respec, or a comparison tooltip.

*Pillar ties: "SotN, Not Hollow Knight" (levels, drops, gear, sanctuaries as structure) · "Read, Then Strike" (gear changes the shape of an exchange, never the read) · "Remade Every Death" (growth survives the print).*

## Detailed Design

### Core Rules

**Rule IDs (`TR-PRG-*`) are stable requirement proposals — each carries a falsifiable test and is ready for `tr-registry.yaml` ingestion.** SYS-16 is the **growth layer**: it never resolves damage, never owns HP, never reads `Input`, and never renders. It owns the seam between the points model and the full sheet, the gear layer's laws, the grant contract, and the progression namespace.

#### 1 · The boundary and the progression state

- **TR-PRG-001 — Consume the economy, never re-derive it.** SYS-07 owns the training-data thresholds (`TRAINING_DATA_L2..L5` = 20/50/90/140), the kill awards (`XP_T1/T2/T3` = 3/7/14, `XP_BOSS` = 40), `LEVEL_CAP_MVP` 5, the point values (`ATK_PER_POINT` 8, `HP_PER_POINT` 2), `PLAYER_ATK_BASE` 100, the printed `DAMAGE_LADDER_MVP`, the `StatBlock` schema and the identity law. SYS-16 consumes all of them as cross-system inputs, validates them at registration (a missing or invalid input is a dev boot failure, never a silent default), and **publishes no threshold, award or ladder cell of its own**. **The pending registration (this lane's sync request):** `design/registry/entities.yaml` carries `player_max_hp`, `hp_per_point`, `training_data_l2..l5`, `damage_ladder_mvp` and `damage_event`; it does **not** yet carry `atk_per_point`, `player_atk_base`, `level_cap_mvp`, `xp_t1`, `xp_t2`, `xp_t3` or `xp_boss` — seven constants whose own registry comment already says "`atk_per_point` is registered when SYS-16 lands". Until the sync lands, the boot's registry check runs against that named pending list (a *known* absence, never a silent default); after it, the check is the empty diff. *Test: the registry diff is empty **after the sync lands** (before it, the pending list is exactly the seven named constants and any other absence fails the boot); `src/progression/` contains no threshold literal and no ladder cell (CI grep); a mocked SYS-07 with a missing `TRAINING_DATA_L3` fails the boot naming it.*

- **TR-PRG-002 — The progression state.** SYS-16 owns one record: `ProgressionState {level, training_data, atk_points, hp_points, banked_points, grants, owned, equipped: {drive, frame}}`. **The runtime writer of `level`/`training_data` is SYS-07** (`HealthCore`; `HealthRead.training_points` is the bank); **SYS-16 is the *persistence* writer** — the namespace's single writer (TR-PRG-025) snapshots SYS-07's values on the save request and never competes with the runtime source. SYS-16 is the runtime writer of `atk_points`/`hp_points`/`grants`/`owned`/`equipped`; the point counters are written on the spend's acknowledgement from SYS-15's surface, and **`banked_points` is a read alias, not a second source**: it must equal SYS-07's `HealthRead.training_points` at every publication (an equality assertion, not a derivation that can drift), and the budget identity of F-PRG-08 holds against it. *Test: the writer audit (one runtime writer per field; one namespace writer); the alias fixture (a divergence between the alias and `training_points` is refused with telemetry, never silently reconciled); the budget identity reproduces on every fixture.*

- **TR-PRG-003 — The layer has no tick.** The progression layer performs **no per-tick work**: the aggregate is computed on a change (an equip, a spend, a grant, a level) and cached; the read is a copy. It joins no gameplay-tick envelope (the SYS-02/SYS-15 not-join precedent): the only runtime cost is the namespace snapshot (SYS-03's bounded-constant budget, TR-SAV-012) and the HUD's read (SYS-24's budget). *Test: the 10,000-tick soak shows zero `ProgressionCore` ticks and zero allocations; the aggregate's recompute count equals the change count exactly.*

#### 2 · Level 1–5: the curve, the pacing, the point

- **TR-PRG-004 — The curve is consumed verbatim.** Levels 1–5; cumulative thresholds **L2 20 · L3 50 · L4 90 · L5 140**; a level-up banks exactly one point; four points exist by L5; **no training data accrues past L5** (`LEVEL_CAP_MVP`; the VS cap is 20). The award key is the defeated enemy's tier (SYS-13: Husk T1 → 3, Spitter T2 → 7, Warden T3 → 14); the boss awards 40 from **SYS-07's `XP_BOSS`** — SYS-14 authors the boss's profile and phases, never its award. *Test: the threshold fixture; the award fixture per tier; a kill at L5 accrues nothing and publishes no level edge; the boss award is read from SYS-07's registered constant, never from SYS-14 and never from a literal (an MVP boot must not require an unwritten system).*

- **TR-PRG-005 — The pacing ledger is derived from the spawn list and the respawn law.** SYS-02's frozen layout pins **five spawns** (RM-01 0 · RM-02 2 · RM-03 2 · RM-04 0 · RM-05 1 · RM-06 0, max two per room) and **re-arms the list on every room entry** (TR-RWS-011); SYS-13 assigns the tier per archetype, and RM-03 is pinned **1 Spitter + 1 Husk**. So the slice's training data is a **rate, not a static total**: one **pass** (one traversal of the mandatory rooms) yields `PACING_PASS_YIELD` = 2×3 (RM-02's Husks) + 1×3 + 1×7 (RM-03) + 1×14 (RM-05's Warden) = **30**. The landmarks are `passes_to(level) = ceil(TRAINING_DATA[level] ÷ pass_yield)`: **L2 at 1 pass · L3 at 2 · L4 at 3 · L5 at the fourth pass's boss** (120 + 40 = 160; the 20 excess is discarded at the cap). The authored bar: **L4 by the third pass** (`PACING_PASSES_L4_MAX` 3) and **L5 by the fourth pass's boss** (`PACING_PASSES_L5_MAX` 4); a slice whose derived yield misses the bar is flagged at build time naming the pass count. **The archetypes are SYS-02's room data** (RM-03's pair is pinned by its room table) **and the tiers are SYS-13's per archetype** — the placement this budget requires (RM-02's two Husks, RM-05's Warden) is SYS-02's to satisfy, not SYS-16's to author. This table is the budget those owners must satisfy, not an edit to the room data or the archetype registry. *Test: the ledger fixture reproduces 30 per pass and the four landmarks; the derived-rate audit (a spawn-list or tier change re-derives the table — nothing is hand-typed); a slice missing the bar is flagged; the boss's award is SYS-07's `XP_BOSS` (SYS-14 authors the boss's profile and phases, never its award).*

- **TR-PRG-006 — The point is the only MVP growth, and it is spent at the terminal.** `+8 attack` (the ladder's index step) or `+2 max HP` per point; **spent only at a cache station**, through SYS-15's frozen surface (`STRIKES +8` / `CHASSIS +2`, TR-CSD-006 — the rows and the per-move preview are SYS-15's; SYS-16 supplies the preview's *values*, never the surface). A spend outside the terminal context is refused and the point stays banked. A `CHASSIS` spend raises the pool **and heals the added amount** (SYS-07's law); a banked point is legal and prints no row (the rows vanish at zero — **and on the first pass the player reaches the first cache with 16 of the 20 XP, so the rows are legitimately absent on that visit: the banked-point pip and the return teach the surface, never a dead row**). **The ladder's rows are coarse, so a point's kill-time payoff is uneven by design — and the boss is its honest ruler: every point shortens the boss by exactly one chain (10/9/8/7/6 across the five builds), the Warden's four-to-three is the one pre-boss flip (point 2), the Husk and the Spitter never change, and the arena-entry build of three points meets the boss at seven chains while the post-boss build of four finishes it at six (OQ-PRG-6 owns whether that fourth point is spendable)** (the ledger below). The growth-felt gate therefore codes the **printed** change (AC-PRG-33), never a promised kill-time flip — a preview that claims a flip it does not deliver is a defect. *Test: the spend fixture (one point, one `StatRevision`, the rows re-render); a spend outside the terminal is refused with the point intact; a banked point survives a reconstruct; the `CHASSIS` heal is exactly +2; **the ledger fixture reproduces the five-row table below cell for cell**.*

**The four-point ledger (TR-PRG-006's fixture).** Re-derived against the roster (Husk 6, Spitter 12, Warden 24, the Denial boss 60):

| points | `attack` | chain | Husk | Spitter | Warden | the boss |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 100 | 6 | 1 | 2 | 4 | **10** |
| 1 | 108 | 7 | 1 | 2 | 4 | **9** |
| 2 | 116 | 8 | 1 | 2 | **3** | **8** |
| 3 | 124 | 9 | 1 | 2 | 3 | **7** |
| 4 | 132 | 10 | 1 | 2 | 3 | **6** |

**This table is TR-PRG-006's reading, printed once.** Whether the fourth point is spendable is OQ-PRG-6's. **A `BOSS_HP` change re-derives this table** (the boss's column is the divisor's output) and a ledger that no longer matches is flagged at build time, never silently staled.

- **TR-PRG-007 — The point budget is capped, and the cap is a law.** `atk_points + hp_points + banked_points = min(level − 1, POINT_BUDGET_CAP)` with `POINT_BUDGET_CAP = 4`. The four points are the **whole game's** allocation budget: levels 6–20 grow the sheet through the level curve (TR-PRG-008/009), never through more points. This is the seam that keeps one growth source at a time. *Test: the budget identity at L1/L5/L6/L20; a level-up past 5 banks nothing; a fifth point is rejected with telemetry.*

#### 3 · The stat growth and the seam (OQ#20's answer)

- **TR-PRG-008 — The attack seam is monotone in both axes.** `attack(L, atk_points) = PLAYER_ATK_BASE + ATK_PER_POINT × atk_points + VS_ATTACK_STEP × max(0, L − LEVEL_CAP_MVP)` with `VS_ATTACK_STEP = 6`. **At L5 this is exactly SYS-07's points law** (`100 + 8a`); from L6 the level adds a flat step, so the stat **never decreases** on any level-up. This supersedes the frozen VS candidate `100 + 6×(L−1)` — which gives 130 at L6, *below* the 132 points cap and therefore a decrease — by resolving exactly the OQ F-HD-14 delegates here. **SYS-07's text is not edited**: the rider request is recorded in the sync block. *Test: the seven fixtures (L1/a0 100; L5/a4 132; L6/a0 106; L6/a4 138; L6/a2 122; L20/a0 190; L20/a4 222); the monotonicity sweep over every (L, a) pair; a level-up never lowers `attack`.*

- **TR-PRG-009 — The pool seam is the same shape.** `hp_max(L, hp_points) = PLAYER_MAX_HP + HP_PER_POINT × (hp_points + max(0, L − LEVEL_CAP_MVP))`. At L20 with four HP points this is **58** — reproducing F-HD-14's re-based VS literal exactly (D-ORCH-03's `20 + 2×(L−1)`), which is therefore the *all-HP* build, not a separate law. A negative `hp_max` change (a module) **clamps the current HP** (TR-HD-010); a positive one from a *point* heals the delta, from a *module* it does not (a point is growth, a module is equipment) — **the asymmetry is a SYS-07 input, because `HealthCore` is the pool's only writer (rider (e))**. *Test: the fixtures (L5/h4 28; L6/h4 30; L20/h4 58; L20/h0 50); the clamp on equip; the heal on spend; the asymmetry fixture.*

- **TR-PRG-010 — The dealt seam continues the ladder; no percent curve takes over.** For `attack ≤ 132` the printed ladder governs (`step(attack) = clamp(floor((attack − 100) ÷ 8), 0, 4)` — SYS-07's law, unchanged). For `attack > 132` the ladder **extends by its top row**: `dealt(arc) = max(LADDER[4][arc], floor(LADDER[4][arc] × attack ÷ 132))`. The seam is flat by construction (at 132 and at 138 both give 4/6/3/4, chain 10), so the dealt value is monotone non-decreasing across L5→L6 for **every** point split. The ladder's four columns remain ATK1/ATK2/crouch/air; `arc = ABILITY` never reads it (SYS-07's branch 4). *Test: the seam fixture at 132/138 (identical rows); the L10 (162) and L20 (222) fixtures (chain 11 / chain 16); the monotone sweep over every (L, a); the split-independence fixture (a=0, 2, 4).*

- **TR-PRG-011 — The no-full-sheet law.** At MVP the progression is read as **three values and two rows**: the pause readout shows **level, HP and ATK**; the loadout shows the two equipped modules by name and by their one-line effect. **ATK prints the *effective* pair** — the ladder row's ATK1/ATK2 **plus** the loadout's `damage_bonus` (with the Coupler equipped it prints `ATK 3/5`, and the loadout row's `damage +1` is the why) — never the raw 100–132 resolver scale, which is the designer's ruler and not player copy. **The printed number must equal the number the hand deals**, or the readout is the exact lie the success signature forbids. **`DEF` is omitted from the MVP readout** — it has no source at MVP (TR-PRG-016) and a dead value on a readout is a lie about a choice the player does not have. There is **no nine-stat sheet, no numeric spreadsheet, no comparison tooltip, no respec** at MVP (the anti-pillar D-2's amended wording: lean but accessible — the sheet itself is SYS-26's, VS). **The loadout rows speak the terminal's word:** a module's effect prints in the game's units and in the chassis vocabulary (`damage +1`, `chassis +2`, `damage +1 · chassis −8`) — never a percentage, and never "pool", because SYS-15's frozen row is `CHASSIS +2` and one axis must have one player-facing name. *Test: the readout fixture (exactly three values; ATK as the effective pair, not 100–132); **the geared fixture (the Coupler's readout is `ATK 3/5` and matches the dealt fixture's values)**; a static audit finds no nine-stat surface in the MVP build; the loadout rows print the game's units and the chassis vocabulary; no DEF row renders while `defense = 0`.*

#### 4 · The gear layer: the quantisation law, the lever set

- **TR-PRG-012 — The gear layer exists, and its levers are enumerated.** MVP gear is **deterministic named Chassis Modules** (D-1, 2026-11-14): a fixed catalogue, fixed pickups, no RNG, no loot table, no affixes, no rarity. A module's payload is drawn from a **closed lever set**: `hp_max` (the frame axis) and `damage_bonus` (the drive axis, F-HD-02's branch-2 stage). **`attack` is excluded** (one +8 step is one ladder row: +16.7% at row 0, +11.1% at row 3, **0% at row 4** because `step()` clamps — a non-monotone value is a trap, not a reward). **`defense` is excluded** (TR-PRG-016). **Behavioural modifiers are excluded at MVP** (every behavioural surface in the MVP belongs to another system's frozen contract — SYS-01's chip, SYS-07's restore fraction, SYS-08's arcs, SYS-06's dash — and a gear-driven override of a frozen knob is a contract revision, not a gear design). Behavioural modifiers are the VS lever. *Test: the payload schema rejects any field outside `{hp_max, damage_bonus}`; the catalogue audit finds no attack/defense/behaviour payload; a module with an out-of-set field fails the boot naming the field.*

- **TR-PRG-013 — The Quantisation Law (the layer's governing finding).** At the 20-HP baseline the smallest integer step of every lever is larger than the ±10% band the game promises: **one chain point on a chain of six is +16.7%** (so no unconditional integer damage gain fits the band); **one point of `defense` is the entire cap** (at raw 1–4, any `defense ≥ 1` returns 1/1/3 — F-HD-03/R10). Therefore the layer's three answers are exhaustive and each is named: **(i) paid** — a damage gain is bought on the pool axis at a stated exchange (TR-PRG-014); **(ii) absent** — a lever that cannot express a choice is retired (TR-PRG-016); **(iii) enumerated and closable** — exactly one module may exceed the band, and its exceedance is bounded, placed and playtest-gated (TR-PRG-015/017). A fourth answer (a windowed payload keyed to a target's state or an arc) is **refused at MVP**: F-HD-02 copies `StatBlock.damage_bonus` into the `AttackContext` at the contact, so a per-target or per-arc window cannot live in the player's `StatBlock` without a third `StatRevision` cause — TR-HD-006 names exactly two (a point spend, an equipment change) — which would be a SYS-07 contract revision. **The reading of F-HD-10's module-build note (recorded, with its rider and its fallback).** F-HD-10 says "a module build (a non-zero `damage_bonus`) is measured against the parity bands (V-HD-14), not this envelope — a module's damage is a situational source, not a TTK-ruler input". **This lane reads it as a ruler, not a ceiling**: the sentence's contrast is envelope-vs-bands as *measurement methods*, and it calls module damage "a situational source" — SYS-07's own words for exactly the framing this GDD uses. The ±10% ceiling itself belongs to TR-HD-034/F-HD-13, whose subject is the **weapon set** (Dirge vs Elegy; one weapon at MVP). Read as a hard ±10% ceiling on gear instead, **D-1's gear layer cannot exist at all** — every integer damage step breaches it at chain 6 (the integral must stay ≤ 642, i.e. chain ≤ 6.58, i.e. no damage lever), which contradicts the user's own D-1. **The rider request (d) asks SYS-07's next doc touch to make the reading explicit**; **the pre-authorised fallback, if the ceiling reading is upheld**: the damage lever is withdrawn, the drive slot ships empty, `WINDOW_EXCEPTION_ENABLED` goes false, and the MVP gear layer is pool-only (the frame + the frame's cost) — a data change plus its conditional criteria, recorded so the decision is a switch, not a redesign. **The fallback's conditional criteria, named now so they are not discovered later** (every AC the fallback touches, exhaustively): the catalogue is **one frame module** — AC-PRG-18's "three entries" becomes one and its drive/frame split is vacated; **AC-PRG-15's aggregate and drive-unequip fixtures are vacated** with the drives (the sign fixture and the synthetic two-drive max-law fixture remain, as does the empty-loadout identity); **AC-PRG-17 is vacated** — the Warden-tier part does not exist with the drive slot empty; **AC-PRG-19 is vacated** — the Coupler pair is the only floor loadout *while the switch is true*, and with it false the paid Regulator alone also lands on −6; **AC-PRG-35 is vacated** with the Coupler (the run's qualifying floor drops to the remaining codes); **AC-PRG-34 is vacated** — its script includes the part and its closure rule targets a switch the fallback has already set false; **AC-PRG-14 is conditional** — its two exception rows and "the exception set is exactly one id" hold while `WINDOW_EXCEPTION_ENABLED` is true, and with it false the exception set is empty and the paid Regulator + a frame is refused; **AC-PRG-32's G5 still runs** (the part is the frame); AC-PRG-13's fallback fixture asserts the reduced set, **and a save carrying a removed module's id clears that slot on load with one report (TR-PRG-025's load-time validation) — the fallback never destroys a save.** *Test: the printed law; the window-refusal fixture (a proposed windowed module is rejected by the payload schema); the two-cause audit on the revision counter; the fallback fixture (`WINDOW_EXCEPTION_ENABLED = false` + the drive payload removed re-runs the budget table, and the conditional criteria above are the ones the QA plan executes — every remaining loadout passes on the pool axis alone).*

- **TR-PRG-014 — The gear guardrail: the free band, the exchange, the anti-stacking rule.** For every authored loadout: `chain_points = chain_loadout − chain_nogear`; `chain% = chain_points ÷ chain_nogear`; `Δhp = hp_max_loadout − hp_max_nogear`. **(a) The free band:** a loadout may gain up to `GEAR_BAND_PCT` = 10% on the pool axis free (at the baseline: +2 HP; the ratio is the bound, so it scales with the pool). **(b) The exchange:** beyond the free band on the damage axis, the loadout must pay `MODULE_HP_PER_CHAIN_POINT` = 3 HP per chain point: `chain% > 10% ⇒ Δhp ≤ −3 × chain_points`. **(c) No pool stacking:** at most one frame payload contributes (the typing, TR-PRG-015) — the pool gain can never sum, so a VS second frame slot cannot double the band. **(d) The exception:** exactly one module (the Warden's, TR-PRG-017) may exceed (a)/(b); it is enumerated, bounded at `chain_points ≤ 2`, and closable. **The bands bind `damage_bonus` at the loadout level, never per module** — the loadout is the unit the player actually fields. *Test: the six-loadout budget table reproduces (F-PRG-06); a loadout violating (b) is refused at authoring time with the shortfall printed; **(a) holds at L1 and at L5**; (c) holds structurally (one frame module authored; a synthetic second frame is refused); the exception set is exactly one id.*

- **TR-PRG-015 — The drive/frame typing makes stacking impossible.** The loadout is **two typed slots**: one **drive** (the payload that changes what the body does — `damage_bonus`) and one **frame** (the payload that changes what the body is — `hp_max`). A module declares its slot in the catalogue; a drive cannot fill the frame slot and vice versa; a module is unique (a deterministic named part cannot exist twice). **The slot types the *gain*, not the cost:** a drive may carry a **negative** `hp_max` (the payment of TR-PRG-014(b)) but never a positive one — a positive pool payload is a frame's job — and a frame may carry no `damage_bonus` at all. **`damage_bonus` never sums:** the loadout's value is the **maximum** over equipped drives (with one drive slot the rule is structural, and it is stated so a VS second drive slot cannot silently stack). *Test: the typing fixture (a drive in the frame slot is refused); the sign fixture (a drive with `hp_max +2` is refused as a frame payload; a frame with `damage_bonus` is refused); the uniqueness fixture; the max-law fixture (a synthetic two-drive catalogue yields the max, not the sum); the empty loadout is the identity.*

- **TR-PRG-016 — DEF is retired from the gear layer (D-ORCH-03's named consequence, resolved).** **No MVP module carries a `defense` payload.** The axis stays implemented and unit-tested at DEF 0/5/25 (AC-HD-14 is untouched); at MVP every loadout's `defense` is **0**. The defensive build is served by the frame axis (`hp_max`), which is granular at the baseline (one step = 10% of the pool) and already a legal gear lever under TR-HD-006. **The take-side alternative is declined**: a flat post-`taken` reduction would need a new stage in SYS-07's total, deterministic damage order (TR-HD-005 names the module stage as "the player's weapon-arc branch only") — a frozen-contract revision for a lever the frame axis already provides. **The revisit gate is named:** DEF returns to gear when SYS-13's strike table's reference heavy (power 3) reaches `raw ≥ 12`, where a 5-point DEF step changes the integer (`floor(12 × 0.95) = 11` vs `floor(12 × 0.85) = 10`); until then the axis is enforced but unobservable (F-HD-03/R10), and a module claiming "+N DEF" would be a number that lies. *Test: the catalogue audit finds zero defense payloads; every loadout's `defense` is 0; AC-HD-14's three fixtures still pass unchanged; the revisit gate is printed with its owner.*

- **TR-PRG-017 — The one exception: the guaranteed Warden-tier part.** Exactly one module — **Regulator-000**, the Warden's own regulator — exceeds the guardrail: a free `damage_bonus +1` (two chain points: **+33.3%** at row 0, **+20%** at row 4 — the exceedance decays as the ladder climbs and is bounded at two points). It is **(a) placed** behind the post-flip partition — a fixed `TAKE` in the Cold Corridor wing beside memory M4 (the wing is RM-03's zone, sealed at epoch 0 and open at epoch ≥ 1: the reveal *is* the partition) — **(b) guaranteed** (always there, never a roll), **(c) bounded** (`chain_points ≤ 2`, no pool gain of its own), and **(d) closable** — the Gate-2 parity-promise probe (the concept's fifth expansion probe, SYS-16 + qa-lead) decides whether the exception stands: **one coded "broken promise" answer closes it** (the concept's rule, verbatim), and the module drops to the paid payload (`damage_bonus +1, hp_max −MODULE_DAMAGE_HP_COST`) with no other change. The switch is `WINDOW_EXCEPTION_ENABLED`; closing it is a data change, not a redesign. **Why a placed part and not an enemy drop:** SYS-02's frozen layout pins five spawns with a two-per-room maximum and the wing carries none, so a second Warden in the wing would be a contract revision this lane will not take; and a drop *table* would break the anti-junk determinism D-1 asks for. The audit's "Warden-tier drop" is therefore realised as **the Warden's own part, guaranteed, behind the partition** — the tier is the part's, the guarantee is the placement's, and the lore carries the kill that put it there. *Test: the drop fixture (a placed `TAKE` in the wing beside M4, present on every run, unreachable at epoch 0 because the zone gate is SEALED); the bound fixture (`chain_points` = 2); the closure fixture (`WINDOW_EXCEPTION_ENABLED = false` re-runs the budget table and the module becomes paid); the no-spawn audit (the wing's spawn list stays empty — SYS-02's five-spawn fixture is untouched); the probe's instrument is AC-PRG-32.*

#### 5 · The catalogue, the loadout, the pickup

- **TR-PRG-018 — The catalogue: three named modules, two drives and one frame.** Each entry is `{module_id, display_name, slot ∈ {drive, frame}, payload, lore_lines: 2, source_room}`; deterministic, unique, no duplicates. The lore is exactly **two lines** in the print voice, never a stat line (the language law). The MVP catalogue:

  | id | slot | payload | where |
  |---|---|---|---|
  | **Coupler-034** | drive | `damage_bonus` `MODULE_DAMAGE_BONUS` (+1), `hp_max` `−MODULE_COUPLER_HP_COST` (−8) | a fixed pre-flip pickup |
  | **Governor-207** | frame | `hp_max` `MODULE_FRAME_HP_BONUS` (+2) | a fixed pre-flip pickup |
  | **Regulator-000** (the Warden's) | drive | `damage_bonus` `MODULE_DAMAGE_BONUS` (+1) — the exception | the Cold Corridor wing, beside M4 (post-flip, guaranteed) |

  *Test: the catalogue fixture (three entries, unique ids, the slot declared, two lore lines each, the payload inside the closed set); the source-room audit (each is a fixed placement, no table); the lore audit (two lines, no percentage, no banned term).*

- **TR-PRG-019 — The Coupler's cost is authored to land the designed pair.** `MODULE_DAMAGE_BONUS` 1 = two chain points = a 6 HP exchange floor. The Coupler pays **8** — a premium that makes it a real cost alone (pool 12: the glass build) — and the pair **Coupler + Governor-207** pays exactly **6** (pool 14), landing on the exchange floor. That coupling is deliberate: the damage build is *playable alone and designed with the frame*, which is what makes the two slots an argument rather than a sum. The glass-alone build (12 HP) is a recorded playtest question (OQ-PRG-1) because the MVP roster's heaviest strike is power 2 (SYS-13: no power-3 strike ships at MVP). *Test: the pair fixture (Coupler+Governor → chain 8, pool 14, Δhp −6 = the floor); the alone fixture (pool 12); the exchange-floor fixture (F-PRG-06 passes for all six loadouts).*

- **TR-PRG-020 — The pickup law: found, never granted; equipped, never automatic.** A module is a fixed pickup taken through SYS-01's `TAKE` bubble (no auto-pickup, no auto-equip — SYS-07's item doctrine consumed); the pickup adds the id to `owned` and publishes one print row naming the module and SYS-29's pickup-class chime edge (TR-JCE-021's treatment). **Equipping is a player action on the pause surface** (SYS-24's; two rows, the equipped names, no submenu, no sheet); an equip applies exactly one `StatRevision` and re-aggregates. **Equipping is legal whenever the pause is legal** — the pause is SYS-05's context and SYS-01's gate (no verb resolves on the transition frame, and the pause is unreachable mid-arc), so a player may swap before an engagement but never inside one; a negative delta clamps the current HP at the swap, and that self-clamp is the trade's cost, not a bug (a Coupler fitted at 20/20 leaves the body at 12/12). A module may be unequipped at any time; the empty slot is the identity. **At MVP the frame slot has one option**, so the frame is effectively auto-advised (empty is strictly worse) — **the *argument* the two slots make is the drive's**, and the second frame option is VS. *Test: the pickup fixture (TAKE only; the owned set grows; nothing auto-equips); the equip fixture (one revision, the aggregate updates, the pool clamps on a negative delta); the mid-fight fixture (the pause context is unavailable, so the swap is unavailable); the pause fixture (two rows, no third surface); the one-frame note (the drive's choice is the loadout's live decision at MVP).*

#### 6 · The ability ladder

- **TR-PRG-021 — The ladder is three rungs, strictly ordered.** `DASH → WALL_JUMP → DOUBLE_JUMP`. **Dash is an action-level lock** (SYS-01's registry: Locked-at-start, TR-INP-003 — the grant flips the registry entry); **Wall Jump and Double Jump are behaviour-level gates on Jump** (SYS-06 owns the behaviour; TR-INP-057 — the input layer's event record is bit-identical pre- and post-unlock, so the gate is never in the input path). SYS-16 publishes the grant; SYS-06 applies it. The Stinger is **off-ladder** (SYS-05's story moment, SYS-12's ability; SYS-16 records the grant in the same set so the state has one home). *Test: the order fixture (`WALL_JUMP` without `DASH` is refused at boot; `DOUBLE_JUMP` without `WALL_JUMP` is refused); the registry-flip fixture (Dash's socket activates); the bit-identical input record (SYS-01 AC-06's clause, cited not owned).*

- **TR-PRG-022 — The grant contract.** `GrantEvent {grant ∈ {DASH, WALL_JUMP, DOUBLE_JUMP, STINGER}, source, tick}`; **once per grant, latched** (a repeat publishes nothing); persisted in the namespace; published to SYS-06 (the gates), SYS-01 (Dash's registry state), SYS-24 (the socket's render) and SYS-29 (the grant cue — the Leap-Stone treatment, TR-JCE-021: one chime-class edge + one print row, no haptic, no flash). A grant never fires from a load, a level-up, or a region entry unless the slice's own trigger says so. **A consumer that starts after the grant reads the persisted grant set at its init and restore and applies each recorded grant without a new `GrantEvent`** — the latch blocks *re-publication*, not *re-application from stored state* (SYS-06's init/restore path is the reader; its GDD's specification needs the same reader contract, recorded in the sync request). *Test: the latch fixture (a second grant publishes nothing); the persistence fixture (a grant survives a reload); **the late-consumer fixture (SYS-06 starts after the grant, the gate is applied from the persisted set, and no second event publishes)**; the cue fixture (one edge, one row, zero haptics); the missing-consumer path (SYS-06 absent at the grant → the grant is recorded and the gate is not applied, with telemetry — never a silent success).*

- **TR-PRG-023 — The MVP posture: zero grants, and the lock is the content.** The six-room slice grants **no traversal ability** — the frozen MVP definition says Dash stays locked (RJ-1 stands) and no wall-jump or double-jump content ships in the six rooms. The MVP's ability-ladder content is the **anticipation design**: the dormant Dash socket (hidden → dimmed-after-tease with the lock glyph → active; SYS-01's `DORMANT_DIM_AFTER_TEASE`, SYS-24's render), which says "not yet" without a tutorial and never errors when pressed (SYS-01 AC-03's pre-unlock clause). The ladder's **unlock moments are authored as a table** so the VS and Full-Vision slices land them without redesign:

  | Rung | The moment | The slice | The gate's owner | Where |
  |---|---|---|---|---|
  | **Dash** | the first errand's traversal gate — the classic MV lock, one named room | the VS slice (the 7–8-room errand) | SYS-01 (the action registry) + SYS-06 (the behaviour) | SYS-05's story moment authors the trigger; the room is the VS slice's level data |
  | **Wall Jump** | the second errand's tagged-wall shaft — the two-wall climb is the deliberate read | Full Vision, errand 2 | SYS-06 (the behaviour) + SYS-02 (`WALL_CLIMBABLE` segments) | the errand's level data |
  | **Double Jump** | the Leap-Stone relic — the moment the map changes meaning | Full Vision, errand 3 | SYS-06 (the behaviour) + SYS-29 (the grant cue, TR-JCE-021) | the relic's placement in the errand's level data |

  *Test: the boot fixture (zero grants in the slice); the socket-state fixture (dimmed, non-executing, non-erroring); the ladder table's completeness (three rows, each with a moment, a slice, an owner and a placement home); a VS/Full-Vision slice that ships a grant must satisfy TR-PRG-024.*

- **TR-PRG-024 — The no-softlock law.** **A grant gate may never be the only exit from a region the player can enter before the grant.** For every slice that ships a gate: (a) the pre-grant reachable set contains a path back to the last activated cache; (b) the gate opens on the grant's tick, never earlier (a gate that admits a pre-grant body is a design error, not a shortcut); (c) the relic's placement is reachable with the pre-grant kit (the reachability claim is authored per slice with its kit list). At MVP the law passes **vacuously** (zero gates) and the audit is a build gate that reports the vacuous pass explicitly — a silent skip is forbidden. *Test: the MVP audit prints "0 gates, vacuous pass"; the synthetic gate fixture (a one-way gate with no return path fails the audit); the early-open fixture; the reachability fixture per authored slice.*

#### 7 · The persistence and the read contracts

- **TR-PRG-025 — The `progression` namespace (the v2→v3 bump).** The progression state persists in SYS-03's envelope as one namespace, `progression`, registered at MVP. SYS-15's `cache` took v1→v2 (TR-CSD-016); this namespace is the **v2→v3** bump (`MIGRATIONS[2]`, `CURRENT_SCHEMA_VERSION` 2 → 3 — SYS-03's schema facts, updated through SYS-03's own change path at the implementation story: the OQ-M1 rider pattern, mirroring SYS-15's OQ-CSD-9, **including the same obligation to reconcile SYS-03's stale "zero registered migrations at MVP" posture sentence at that touch**). **The shape:** `{level, training_data, atk_points, hp_points, grants, owned, equipped: {drive, frame}}` — the conservative default is the identity (`1, 0, 0, 0, [], [], {null, null}`); `banked_points` is **derived from SYS-07's `training_points`, never stored** (TR-PRG-002). **No floats.** **SYS-16 is the namespace's only writer** — it snapshots SYS-07's `level`/`training_data` on the save request and never competes with the runtime source. **The carry law:** the namespace is **live-carried across the reconstruct inside the restore window, read-gated** (TR-CSD-012's pattern consumed verbatim) — a level earned after the last save is never rolled back (TR-CSD-013's no-XP-loss law); the saved value seeds only a fresh session load. **SYS-16's carry-complete acknowledgment is a named input to SYS-05's `load_complete`** (the same gate SYS-15's carry supplies), so no consumer can read `ProgressionRead` before the carry and observe the rollback the law forbids. A v2 payload carrying `progression` is `REFUSE_UNKNOWN_KEY`; an absent namespace or key at v3 reads its conservative default. **The load-time validation (the law for a catalogue that moved under a save):** `LOAD` validates every equipped id against the catalogue and the loadout against the guardrail, and **a slot whose payload cannot be validated is cleared to `null` with exactly one report naming it — the load itself never fails for gear.** Two instances: (a) an equipped id **absent from the catalogue** (a save from a build that shipped a module this build does not — e.g. after the pool-only fallback) clears that slot; (b) a saved pair that **fails the guardrail** after a closure (the closed Regulator + a frame, `Δhp −4`) clears the **drive** — the side the closure changed — leaving the frame. The rule is the same shape as SYS-03's absent-key-unset: a conservative default, reported, never a refused save and never a silently invalid loadout. **`owned` obeys the same rule:** each id in `owned` that is absent from the catalogue is removed from `owned` in the same load, and the removal is included in that single report; a save holding only catalogued ids loads unchanged. *Test: the round-trip fixture; the absent-default fixture; the carry fixture (level after the save survives a reconstruct, and the saved value is used only on a fresh load); the read-gate fixture (a `ProgressionRead` consumer before the carry-complete acknowledgment is refused); the refuse-unknown-key fixture; **the load-validation fixtures** (an unknown equipped id clears its slot and reports; a post-closure invalid pair clears the drive and reports; the load succeeds in both); the no-stored-`banked_points` audit; the no-float audit.*

- **TR-PRG-026 — The read contracts.** SYS-16 publishes read-only: `ProgressionRead {atk_points, hp_points, banked_points, atk_pair: {atk1, atk2}, grants, owned, equipped, aggregate: GearAggregate}` and `GearAggregate {damage_bonus, hp_max_delta, attack_delta, defense_delta, revision}`. **`atk_pair` is the printed effective pair** — the ladder row's ATK1/ATK2 plus the loadout's `damage_bonus` (TR-PRG-011) — so SYS-24 renders a number it does not have to re-derive and the printed number equals the dealt one by construction. **The level and the training data are SYS-07's** (`HealthRead`) and are **not re-owned**: `ProgressionRead` carries no `level` and no `training_data`, and a consumer that needs them reads SYS-07. The aggregate's `attack_delta` and `defense_delta` are **always 0 at MVP** (the lever set, TR-PRG-012) and exist so a VS module cannot need a new schema. **The point's transport is the spend's ack:** SYS-15's commit → SYS-16 writes the counter → SYS-07 reads `ProgressionRead` and applies exactly one `StatRevision` (TR-HD-007's recompute-on-spend); the same ack carries the gear's aggregate on an equip. No consumer writes back; there is no writer field. *Test: the mock-consumer fixture (SYS-24/SYS-15/SYS-17 read it); the schema audit (no writer field; no `level`, no `training_data`); the zero-delta audit at MVP; the ack fixture (one `StatRevision` per spend and per equip, the pair republished).*

- **TR-PRG-027 — The HUD, inventory and save boundaries.** **SYS-24** renders: the level + banked-point pip (from SYS-07's `HealthRead`), the pause readout (three values, TR-PRG-011), the two loadout rows + the equip action, and the dormant Dash socket. **SYS-24's obligations from this layer** (stated here so they are not lost between the two GDDs): the rows' **focus order is top→bottom**; a **screen-reader session announces each row's label and its effect** (name + role per row, SYS-01's a11y baseline); the row's effect text is **generated from the payload** (an edited payload changes the text with no string edit — a hand-typed per-module string would drift from the payload); every row is ≥ 48 dp. **SYS-17** owns the item entities (ids, display names, the `TAKE` interaction, the VS inventory screen) and the VS `inventory` namespace — the MVP's `owned`/`equipped` keys **move to it at VS** in a named migration (v3→v4, recorded in OQ-PRG-5); SYS-16 owns the catalogue's payloads and the loadout law. **SYS-15** owns the spend surface (frozen rows); SYS-16 supplies the preview's values. **SYS-03** owns the serialization, the bump's registration and the writer thread (ADR-0002). *Test: the boundary audit (`src/progression/` contains no screen, no item entity, no serializer); the mock handoffs; the SYS-24 obligation list's presence in the systems index's SYS-24 entry (the sync request's correction (3)); the VS-migration record's presence.*

#### 8 · Testability and performance

- **TR-PRG-028 — The purity seam, the budget, the traceability.** **`ProgressionCore`** is a pure reducer: `(ProgressionState, Command) → (ProgressionState, Publications)` where `Command ∈ {SPEND_POINT(kind), EQUIP(module_id), UNEQUIP(slot), ACQUIRE(module_id), GRANT(grant), SYNC(health_read), LOAD(namespace), SNAPSHOT()}` — **the set is total**: `EQUIP` names the module and its slot is read from the catalogue (a drive cannot fill the frame slot, TR-PRG-015), `UNEQUIP` names the slot (the only way a BUILT loadout reaches a defined single-slot state), `SYNC` carries a level-up or an external `HealthRead` change (the trigger TR-PRG-003 names), and `LOAD` restores the namespace whole. The ports are `ProgressionPort {health_read(), now_tick(), publish(event)}`. The catalogue and the consumed constants are injected (`ProgressionTables`), so the core has no global state and no engine symbol (`Input`, `SceneTree`, `Time`, `RenderingServer` are absent — ADR-0001 §15's seam). Fixed 60 tps where ticks are named. **Budget:** zero per-tick work (TR-PRG-003); the soak's object/resource delta 0 and heap ≤ 256 KB; the namespace snapshot inside SYS-03's budget. **Traceability:** every TR has an AC or a recorded guidance note; every formula has an AC; the counts are 28 / 10 / 12 / 36 / 8; no `[To be designed]`. *Test: the purity audit; the command-totality fixture (every command from every state yields a defined state or a named refusal; BUILT → UNEQUIP(slot) reaches exactly one state); the bit-identical replay under a `FakeProgressionPort`; the soak; the traceability audit (AC-PRG-29).*

### States and Transitions

Progression is two small machines and one derived record. The body, the combat and the context are other systems'.

**The state machine.**

| State | Enter | Exit | Aggregate | Notes |
|---|---|---|---|---|
| **EMPTY** | boot with no modules equipped; **the last equipped module unequipped** | `EQUIP(drive)` → DRIVEN · `EQUIP(frame)` → FRAMED | identity | the identity law's home; `damage_bonus` 0, `hp_max_delta` 0 |
| **FRAMED** | `EQUIP(frame)`; **`UNEQUIP(drive)` from BUILT** | `EQUIP(drive)` → BUILT · `UNEQUIP(frame)` → EMPTY | `hp_max_delta` ≠ 0 | the pool moves; the current HP clamps on a negative delta |
| **DRIVEN** | `EQUIP(drive)`; **`UNEQUIP(frame)` from BUILT** | `EQUIP(frame)` → BUILT · `UNEQUIP(drive)` → EMPTY | `damage_bonus` = 1 | the ladder's module stage fires on branch 2 only |
| **BUILT** | both slots filled | `UNEQUIP(drive)` → **FRAMED** (the frame stays) · `UNEQUIP(frame)` → **DRIVEN** (the drive stays) | both | the designed pairs (TR-PRG-019) — **an unequip never clears the other slot** |

**The grant machine.**

| State | Enter | Exit | Publication | Notes |
|---|---|---|---|---|
| **LOCKED** | boot | the slice's grant trigger | none | Dash: the registry says Locked-at-start; the socket is dimmed (the anticipation design) |
| **GRANTED** | `GrantEvent` (once, latched) | — (terminal within a run) | one `GrantEvent` + the cue | persisted; never re-fires |

**Transition laws.**

1. **The loadout is the unit.** Every gear law is evaluated on the *loadout*, never on a module in isolation (TR-PRG-014) — the player fields a pair, and a pair is what the budget audits.
2. **Equipping is a player act, and an unequip is partial.** No pickup auto-equips; no load auto-equips; a load restores the saved loadout exactly (TR-PRG-025); **unequipping one slot never clears the other** (BUILT → FRAMED or DRIVEN, never EMPTY).
3. **One revision per change.** An equip, an unequip and a point spend each apply exactly one `StatRevision`; there is no per-tick recompute and no third cause (TR-HD-006's two-cause law consumed).
4. **The pool clamps, the point heals.** A negative `hp_max_delta` clamps the current HP; a point's `+2` heals the added amount. The asymmetry is the design: growth is felt, equipment is fitted.
5. **A grant never un-happens.** `GRANTED` is terminal within a run; a reload restores the set; a new game clears it (SYS-05's action).
6. **The ladder is a strict order.** `WALL_JUMP ⇒ DASH`; `DOUBLE_JUMP ⇒ WALL_JUMP`; the Stinger is off-ladder and never satisfies a rung.

### Interactions with Other Systems

| Contract | SYS-16 owns | Consumer owns |
|---|---|---|
| **`StatBlock` growth** | the seam laws (F-PRG-01/02/03), the point budget, the gear aggregation | SYS-07: the schema, the resolver, the identity law, the thresholds, the awards, the point values |
| **The spend surface** | the preview's *values* (the per-move delta) | SYS-15: the terminal's frozen rows (`STRIKES +8` / `CHASSIS +2`), the commit, the re-render |
| **The gear catalogue** | the ids, the payloads, the lore, the slot typing, the loadout law, the guardrail | SYS-17: the item entities, the `TAKE` pickup, the VS inventory screen + namespace |
| **`GearAggregate`** | the aggregation, the max-law, the revision | SYS-07: folding it into the `StatBlock` at the equip |
| **`ProgressionRead`** | the read-only publication (no level, no XP) | SYS-24: the pause readout (three values), the two loadout rows, the dormant socket render |
| **`GrantEvent`** | the set, the order law, the latch, the persistence | SYS-06: the gates (Wall Jump / Double Jump); SYS-01: Dash's registry flip; SYS-24: the socket's active state; SYS-29: the grant cue |
| **The namespace** | the shape, the writer, the carry, the conservative default | SYS-03: the serialization, the bump's registration (`MIGRATIONS[2]`, v2→v3), the writer thread (ADR-0002) |
| **The pacing budget** | the derived ledger and its landmarks | SYS-02: the room spawn list (the placement); SYS-13/SYS-14: the awards |

- **SYS-07 Health & Damage (upstream, hard):** the `StatBlock` + the identity law, the printed ladder, the thresholds/awards, the point values, the `HealthRead`, the module stage. **Status: APPROVED + D-ORCH-03.**
- **SYS-08 Combat (upstream, soft):** the `arc` enum, the weapon table, the counter, the `AttackContext.damage_bonus` transport. **APPROVED + D-ORCH-03.**
- **SYS-13 Enemy AI (upstream, soft):** the tier per archetype (the award key). **APPROVED.**
- **SYS-06 Movement (downstream for grants, hard for the gate's behaviour):** the three gates, `WALL_CLIMBABLE`, `air_jump_used`. **APPROVED.**
- **SYS-01 Input (downstream for Dash's registry, hard for the socket):** TR-INP-003, TR-INP-057, `DORMANT_DIM_AFTER_TEASE`. **UNFROZEN (#10 record).**
- **SYS-15 Cache Stations (coordination, hard for the spend):** the frozen rows, the preview's contract, the carry pattern. **APPROVED.**
- **SYS-24 HUD (downstream, hard for the loadout surface):** the three-value readout, the two rows, the socket. **Not written — the contract is stated here.**
- **SYS-17 Inventory (downstream, MVP carve-out + gear):** the item entities, the `TAKE`, the VS namespace migration. **Blocked on SYS-16.**
- **SYS-29 Juice (downstream, soft):** the grant cue, the pickup chime, the level-up print (SYS-07's edge). **APPROVED.**
- **SYS-03 Save (downstream, hard at save time):** the namespace, the bump, the writer thread. **APPROVED (ADR-0002).**
- **SYS-02 Room & World (coordination):** the spawn budget's placement, the post-flip wing's drop. **APPROVED.**
- **SYS-05 Game Flow (coordination):** the Stinger's grant moment, the new-game reset, the post-boss state. **Pre-shaped.**
- **SYS-14 Grief-Boss (coordination):** the boss award. **Not written.**

**Explicit non-dependencies:** SYS-09/10/11 (the flip is theirs; the gear keys on no epoch), SYS-18/19/21 (VS consumers of SYS-16), SYS-25 (the map), SYS-26 (the VS sheet), SYS-27 (the bestiary), SYS-28 (the lore's voice review is a copy pass, not a runtime dependency), SYS-12 (the Stinger's ability is SYS-12's; only its grant flag is here).

## Formulas

Progression's formulas are **seam laws** (the points model → the full sheet), **budget laws** (the pacing, the point budget, the gear guardrail) and **state laws** (the aggregate, the grant set, the namespace default). Three laws govern every formula:

- **Named-symbol law.** Every literal appears here only as a named symbol; values live in exactly one place — the Tuning Knobs table.
- **Never-stingy boundary law.** Every boundary comparison is inclusive on entry, strict on exit (`≥` for a threshold reached, `≤` for a budget met).
- **Consumed-source law.** No formula re-derives a SYS-07 number; the consumed constants enter as symbols and a disagreement is a boot failure.

**Formula ledger — law vs knob.**

| # | Formula | Class | Constants consumed |
|---|---|---|---|
| F-PRG-01 | attack_seam | True law | `PLAYER_ATK_BASE`, `ATK_PER_POINT`, `VS_ATTACK_STEP`, `LEVEL_CAP_MVP` |
| F-PRG-02 | hp_seam | True law | `PLAYER_MAX_HP`, `HP_PER_POINT`, `LEVEL_CAP_MVP` |
| F-PRG-03 | dealt_extension | True law | `DAMAGE_LADDER_MVP`, `ATK_PER_POINT` |
| F-PRG-04 | level_landmark | Derived metric | `TRAINING_DATA_L2..L5`, `XP_T1/T2/T3`, `XP_BOSS`, the pacing counts |
| F-PRG-05 | gear_aggregate | True law | the catalogue, `MODULE_SLOTS` |
| F-PRG-06 | gear_budget | Threshold law | `GEAR_BAND_PCT`, `MODULE_HP_PER_CHAIN_POINT` |
| F-PRG-07 | exception_bound | Threshold law | `WINDOW_EXCEPTION_CHAIN_POINTS` |
| F-PRG-08 | point_budget | True law | `POINT_BUDGET_CAP` |
| F-PRG-09 | grant_state | True law | the ladder order |
| F-PRG-10 | namespace_default | True law | `PROGRESSION_SCHEMA_VERSION`, the shape |

#### F-PRG-01 · attack_seam — the points model meets the sheet (TR-PRG-008)

`attack(L, a) = PLAYER_ATK_BASE + ATK_PER_POINT × a + VS_ATTACK_STEP × max(0, L − LEVEL_CAP_MVP)`

**Variables:** `L` int 1–20 (the level; MVP cap 5, VS cap 20) · `a` = `atk_points` int 0–4 · `PLAYER_ATK_BASE` 100 (fixed identity) · `ATK_PER_POINT` 8 (fixed identity) · `VS_ATTACK_STEP` 6 · `LEVEL_CAP_MVP` 5. **Output:** int 100–222.

**Worked examples:** (L1, a0) **100** · (L5, a4) **132** · (L6, a0) **106** · (L6, a4) **138** · (L6, a2) **122** · (L20, a0) **190** · (L20, a4) **222**. **Monotonicity:** `∂/∂L = 6` for `L > 5` and 0 below; `∂/∂a = 8` — so the stat is non-decreasing in both axes and the L5→L6 step is **+6 for every split** (132→138, 124→130, 116→122, 108→114, 100→106). **Why not the frozen candidate `100 + 6×(L−1)`:** it gives 130 at L6, *below* the 132 cap — a player who spent four points would lose 2 attack on the level-up. The OQ asked for monotonicity in the stat *and* the dealt value; this law gives both.

#### F-PRG-02 · hp_seam — the pool (TR-PRG-009)

`hp_max(L, h) = PLAYER_MAX_HP + HP_PER_POINT × (h + max(0, L − LEVEL_CAP_MVP))`

**Variables:** `h` = `hp_points` int 0–4 · `PLAYER_MAX_HP` 20 · `HP_PER_POINT` 2. **Output:** int 20–58.

**Worked examples:** (L1, h0) **20** · (L5, h4) **28** · (L6, h4) **30** · (L6, h0) **22** · (L20, h0) **50** · (L20, h4) **58**. **The 58 is F-HD-14's re-based VS literal** — which is therefore the all-HP build, not a second law. **A module's delta applies after this law** (`hp_max_effective = hp_max(L, h) + aggregate.hp_max_delta`), clamped ≥ 1.

#### F-PRG-03 · dealt_extension — the ladder continues (TR-PRG-010)

`step(attack) = clamp(floor((attack − PLAYER_ATK_BASE) ÷ ATK_PER_POINT), 0, 4)`

`dealt(arc) = LADDER[step][arc]` if `attack ≤ 132`; else `max(LADDER[4][arc], floor(LADDER[4][arc] × attack ÷ 132))`.

**Variables:** `arc ∈ {ATK1, ATK2, CROUCH, AIR}` (the ladder's four columns; `ABILITY` never reads it) · `attack` int 100–222 · `LADDER[4]` = 4/6/3/4 (chain 10). **Output:** the dealt value per arc; the chain is the sum of ATK1 + ATK2.

**Worked examples:** attack **132** (L5/a4) → row 4 → 4/6/3/4, chain **10**; attack **138** (L6/a4) → `max(4, floor(4×138÷132)=4)` → **4/6/3/4, chain 10** (the seam is flat by construction); attack **162** (L10/a4) → 4/7/3/4, chain **11**; attack **222** (L20/a4) → 6/10/5/6, chain **16**. **The split-independence fixture:** attack 130 (L6/a3) → `step` 3 → row 3 → 4/5/3/3, chain 9 — identical to L5/a3 (attack 124), so no split loses damage at the seam. **Monotone:** the else-branch's floor of an increasing function, `max`-ed with a constant.

#### F-PRG-04 · level_landmark — the pacing rate (TR-PRG-005)

`pass_yield = Σ_{rooms} Σ_{entries} XP_T[tier(archetype)]` over the mandatory rooms' spawn lists (the list re-arms every entry — TR-RWS-011).
`passes_to(level) = ceil(TRAINING_DATA[level] ÷ pass_yield)`; `level(xp) = 1 + |{t : TRAINING_DATA[t] ≤ xp}|`, capped at `LEVEL_CAP_MVP`.

**Variables:** `pass_yield` int > 0 (derived; `PACING_PASS_YIELD_MIN` 30 is its floor) · the thresholds 20/50/90/140 · the awards 3/7/14 · `XP_BOSS` 40 · the spawn lists (SYS-02's: 0/2/2/0/1/0) · the tier assignment (SYS-13's; RM-03 pinned 1 Spitter + 1 Husk). **Output:** the per-pass yield, the passes-to-landmark table, the level from an XP total.

**The derived yield (the authored assignment the budget requires):**

| Room | spawns | assignment | yield per pass |
|---|---:|---|---:|
| RM-01 | 0 | — | 0 |
| RM-02 | 2 | 2 × Husk (T1) | 6 |
| RM-03 | 2 | 1 × Husk + 1 × Spitter (**SYS-02's pinned pair**) | 10 |
| RM-04 (cache) | 0 | — | 0 |
| RM-05 | 1 | 1 × Warden (T3) | 14 |
| RM-06 (arena) | 0 | the boss (SYS-14; the award is SYS-07's) | — |
| **per pass** | **5** | | **30** |

**The landmarks:**

| after | cumulative | level | points | note |
|---|---:|---|---:|---|
| 1 pass | 30 | **L2** | 1 | the first point in the first traversal |
| 2 passes | 60 | **L3** | 2 | |
| 3 passes | 90 | **L4** | 3 | the design target for entering the arena |
| 3 passes + the boss | 130 | L4 | 3 | a boss attempted early does not finish the curve |
| 4 passes + the boss | **160** | **L5** | **4** | the 20 excess is discarded at the cap |

**Worked examples:** xp 19 → L1; xp 20 → **L2**; xp 50 → **L3**; xp 90 → **L4** (exactly — the never-stingy boundary); xp 140 → **L5**; xp 400 → L5. **`passes_to(L4) = ceil(90 ÷ 30) = 3`** ✓ the bar; **`passes_to(L5) = ceil(140 ÷ 30) = 5`** — the bar is met only *with* the boss (120 + 40), which is why the L5 row is "4 passes **+ the boss**". **The design claim:** the slice is a **farm loop by construction** (the respawn is the verb SYS-07 licenses and SYS-15's ledger states), so the ledger is a *rate*; the authored bar is that the growth is felt within three traversals and completed by the fourth. **A pass is not a chore requirement:** the player may fight the boss at L3 or L4; the curve simply says the fourth point needs the fourth pass.

**The placement is SYS-02's and the archetypes are SYS-02's room data (their tiers are SYS-13's).** This table is the *budget* those owners must satisfy, not an edit to the room data or the archetype registry. A spawn-list change, a tier change or an award change re-derives the table (nothing is hand-typed); if the derived yield falls under `PACING_PASS_YIELD_MIN`, the build flags the pass count it would take.

#### F-PRG-05 · gear_aggregate — the loadout becomes a stat (TR-PRG-015/026)

`aggregate.damage_bonus = max({m.damage_bonus : m equipped ∧ m.slot = drive} ∪ {0})`
`aggregate.hp_max_delta = Σ {m.hp_max : m equipped}` — **both slots**: the frame contributes its gain and a drive contributes its **cost** (the Coupler's −8 is the payment of F-PRG-06(b), so it must land in the aggregate or the exchange would be unpayable and the budget table would disagree with the formula)
`aggregate.attack_delta = 0`; `aggregate.defense_delta = 0` (the lever set, TR-PRG-012)
`aggregate.revision = revision + 1` on every change.

**Variables:** the catalogue entries; `MODULE_SLOTS` = 2 (one drive, one frame). **Output:** the `GearAggregate`.

**Worked examples:** ∅ → `{0, 0, 0, 0}` (the identity) · Governor-207 → `{0, +2, 0, 0}` · Coupler-034 → `{1, −8, 0, 0}` · Coupler + Governor → `{1, −6, 0, 0}` · Regulator-000 → `{1, 0, 0, 0}` · Regulator-000 + Governor-207 → `{1, +2, 0, 0}`. **The max-law fixture:** a synthetic catalogue with two drives (payloads 1 and 1) yields **1**, never 2 — a VS second drive slot cannot silently stack.

#### F-PRG-06 · gear_budget — the guardrail (TR-PRG-014)

`chain_nogear = dealt(ATK1) + dealt(ATK2)` — **F-PRG-03's law, not `step()`'s clamp** (the clamp saturates at row 4, so a `step()`-based chain under-reports every L6+ build; the guardrail must measure the chain the resolver actually deals)
`chain_loadout = chain_nogear + 2 × aggregate.damage_bonus`
`chain_points = chain_loadout − chain_nogear`; `chain% = chain_points ÷ chain_nogear`
`Δhp = aggregate.hp_max_delta`; `pool% = Δhp ÷ hp_max(L, h)`

**The guardrail (all four terms must hold, or the loadout is the enumerated exception):**
`(a) pool% ≤ GEAR_BAND_PCT` · `(b) chain% ≤ GEAR_BAND_PCT ∨ Δhp ≤ −MODULE_HP_PER_CHAIN_POINT × chain_points` · `(c) no pool stacking: at most one frame payload contributes (the typing, TR-PRG-015) — the pool gain can never sum` · `(d) the exception set is exactly {Regulator-000} while `WINDOW_EXCEPTION_ENABLED`.

**Variables:** `GEAR_BAND_PCT` 0.10 · `MODULE_HP_PER_CHAIN_POINT` 3 · `MODULE_FRAME_HP_BONUS` 2 · `MODULE_DAMAGE_BONUS` 1 (→ 2 chain points). **Output:** pass / the named failing term.

**The six-loadout budget table (L1: chain 6, pool 20):**

| Loadout | chain | pool | `chain_points` | `chain%` | `Δhp` | term (b) needs | verdict |
|---|---:|---:|---:|---:|---:|---|---|
| ∅ | 6 | 20 | 0 | 0% | 0 | — | **pass** (a) |
| Governor-207 | 6 | 22 | 0 | 0% | +2 | — | **pass** (a: 10% ≤ 10%) |
| Coupler-034 | 8 | 12 | 2 | +33.3% | −8 | ≤ −6 | **pass** (b) |
| Coupler + Governor | 8 | 14 | 2 | +33.3% | −6 | ≤ −6 | **pass** (b, at the floor) |
| Regulator-000 | 8 | 20 | 2 | +33.3% | 0 | ≤ −6 | **exception** (d) |
| Regulator-000 + Governor-207 | 8 | 22 | 2 | +33.3% | +2 | ≤ −6 | **exception** (d) |

**Level-invariance:** the exchange is a **point-for-point** law, so it holds unchanged at L5 all-ATK (chain 10 / Coupler 12, pool 20→12: Δhp −8 ≤ −6) and at L5 all-HP (chain 6 / Coupler 8, pool 28→20: −8 ≤ −6; the pair 28→22: −6 ≤ −6; the frame alone 28→30: pool% **+7.1%** ≤ 10%). **The integral's blindness:** the 60 s integral cannot see the pool (the Coupler's damage build reads **779** vs 584 — the same as the free exception), which is *why* the guardrail is a pair of axes and not one number. **Example:** the Coupler's 8 HP premium exists so the designed pair lands exactly on the floor (TR-PRG-019).

#### F-PRG-07 · exception_bound — the one window (TR-PRG-017)

`chain%_exception = 2 ÷ chain_nogear` → **+33.3%** at row 0 (chain 6), **+25.0%** at chain 8, **+20.0%** at row 4 (chain 10). Bound: `chain_points ≤ WINDOW_EXCEPTION_CHAIN_POINTS` = 2. Closure: `WINDOW_EXCEPTION_ENABLED = false` ⇒ the module's payload becomes `{damage_bonus +1, hp_max −MODULE_DAMAGE_HP_COST}` and the budget table re-runs with zero exceptions.

**Variables:** the chain at the player's current step; the constant 2. **Output:** the printed exceedance and its bound.

**Worked example:** at L1 **Regulator-000's** chain 8 vs 6 = **+33.4%** on the 60 s integral (97 chains × 8 + one ATK1 of 3 = **779** vs **584**); at L5 all-ATK, chain 12 vs 10 = **+20%**. (Governor-207 is the *frame* — it never moves the chain; only the two drives do.) The exceedance is bounded, printed, decays with the ladder, and is placed behind an optional fight. **The closure's arithmetic — and its refusal.** With `WINDOW_EXCEPTION_ENABLED = false` the paid payload is `{damage_bonus +1, hp_max −6}`. **Alone** it gives chain 8, chassis 14 → `Δhp −6 ≤ −6` ✓ (the Coupler+Governor loadout's shape). **With Governor-207** it gives chain 8, chassis 16 → `Δhp −4`, which **fails (b)** (`≤ −6`) — so **the closed module may not be equipped alongside a frame**: the equip is refused with the shortfall printed ("this part's cost cannot be paid with a frame fitted"). That is the honest closure: the part's cost is unpayable with a frame, so closing the exception narrows the loadout rather than re-tuning a derived constant (`MODULE_DAMAGE_HP_COST` is derived by V-PRG-06 and cannot be raised to 8 without breaking the derivation). **Recorded so the closure is known to be a content decision, not a tuning nudge.**

#### F-PRG-08 · point_budget — the four points (TR-PRG-007)

`a + h + banked = min(L − 1, POINT_BUDGET_CAP)`, `0 ≤ a, h, banked`, `POINT_BUDGET_CAP = 4`.

**Variables:** `a`/`h`/`banked` int ≥ 0 · `L` int 1–20. **Output:** the identity holds at every level.

**Worked examples:** L1 → 0 = 0 ✓ · L5 → `a + h + banked = 4` · L6 → 4 (not 5) · L20 → 4 (not 19). **A spend** decrements `banked` and increments `a` or `h`, preserving the sum; **a level-up** increments `min(L−1, 4)` only while `L ≤ 5`.

#### F-PRG-09 · grant_state — the ladder's order (TR-PRG-021/022)

`grants ⊆ {DASH, WALL_JUMP, DOUBLE_JUMP, STINGER}`; `WALL_JUMP ∈ grants ⇒ DASH ∈ grants`; `DOUBLE_JUMP ∈ grants ⇒ WALL_JUMP ∈ grants`; `STINGER` is unconstrained (off-ladder). `grant(g)` is idempotent: a second call publishes nothing and changes nothing.

**Variables:** the set; the order. **Output:** the valid set + the publication count.

**Worked example:** `{}` → valid · `{DASH}` → valid · `{WALL_JUMP}` → **invalid at boot** (names the missing `DASH`) · `{DASH, WALL_JUMP, DOUBLE_JUMP}` → valid · `{STINGER}` → valid (off-ladder). **The MVP fixture:** `{}` at boot, zero publications, and the ladder table's three authored moments are data, not runtime.

#### F-PRG-10 · namespace_default — the shape (TR-PRG-025)

`default_progression = {level: 1, training_data: 0, atk_points: 0, hp_points: 0, grants: [], owned: [], equipped: {drive: null, frame: null}}`; `PROGRESSION_SCHEMA_VERSION = 3`; `banked_points` is **derived** (F-PRG-08), never stored.

**Variables:** the shape; the version. **Output:** the namespace value, applied whole.

**Worked examples:** (1) a synthetic v2 file migrates → `progression` appears with the default and the `world`/`cache` families are byte-identical. (2) An explicit new game → the default (SYS-05's action); the terminal prints the level from SYS-07's read. (3) A v3 file missing `owned` (a future shape's absent key) → `[]` at restore. (4) A v2 payload carrying `progression` → `REFUSE_UNKNOWN_KEY`.

## Edge Cases

**Format: If [condition] → [exact outcome]. [rationale where non-obvious.]**

### Growth and the point

- **If a kill crosses two thresholds at once** (a boss award of 40 taken at 19 XP → 59, crossing 20 and 50) → both levels apply in the same tick, **two** points bank, and **two** level edges publish (the award is one event, the levels are two, crossed in order). [The award is not split; the thresholds are crossed in order. The frozen gaps (30/40/50) against a 40 maximum award mean a *double* crossing needs a starting XP under 20 — the runner who reaches the boss early is the real instance.]
- **If a kill arrives at L5** → no training data accrues and no level edge publishes; the award is discarded (not banked for VS). [The cap is the cap; a hidden bank would be a lie about the MVP's end.]
- **If the player farms a respawned room to L5 early** → legal; the cap holds; the later rooms' awards are discarded. [The grind verb exists by design (TR-RWS-011); the cap bounds it.]
- **If a point is spent outside the terminal context** → refused; the point stays banked; no `StatRevision`. [The station is the only allocation surface.]
- **If a `CHASSIS` point is spent at full HP** → the pool rises by 2 and the current HP rises by 2 (not clamped, not overhealed). [The point is felt immediately.]
- **If a banked point survives a death** → it survives the reconstruct (the namespace is carried) and survives a fresh load (it is in the save). [Banked points are growth, and growth survives the print.]
- **If a level-up arrives during a gate or a death beat** → the edge queues at the next gameplay tick; the point banks then. [No allocation in a context that cannot show it.]
- **If the derived pass yield falls under `PACING_PASS_YIELD_MIN`** → the build flags the pass count it would take and names the spawn list or the tier assignment to fix; the slice ships only after the bar is met. [The bar is a gate on data, not a note.]

### The seam

- **If a player reaches L6 with four ATK points** → attack 138 (not 130), row 4, chain 10 — no loss. [F-PRG-01's reason to exist.]
- **If a player reaches L6 with zero ATK points** → attack 106, row 0, chain 6 — the same damage as L5, +6 banked for later rows. [Monotone, never a drop.]
- **If a player reaches L20** → attack 222 all-ATK (chain 16) or 190 with the points elsewhere (chain 12-ish); the pool 58 all-HP. [The seam's outputs.]
- **If a module raises `attack`** → impossible at MVP (the lever set); a VS module that does must re-run F-PRG-03 with the effective attack. [The attack lever's exclusion is structural.]
- **If `VS_ATTACK_STEP` is edited to 0** → the stat is flat from L6 and the dealt value flat — legal but the VS sheet loses its growth; the knob's safe range floors at 4. [A zero step is a design error, not a crash.]

### Gear

- **If the player equips the Coupler alone at 20 HP** → pool 12; the current HP clamps to 12 if it was higher. [The glass build is a real cost.]
- **If the player equips the Coupler at 6/20 HP** → pool 12, current HP 6 (no clamp needed). [A clamp never heals.]
- **If the player unequips the Coupler** → pool back to 20, current HP unchanged at 6 (the pool grows; the current does not). [Equipment is fitted, not growth.]
- **If the player equips the Governor at 20/20** → pool 22, current HP 20 (not 22). [A module never heals; only a point does.]
- **If both slots hold a drive** → refused by the typing (a drive cannot fill the frame slot). [TR-PRG-015.]
- **If a module is picked up while both slots are full** → it enters `owned` unequipped; the pause surface shows it available. [No auto-equip, no refusal — the part is kept.]
- **If a module is picked up twice** → impossible (unique deterministic parts; the pickup latches). [No duplicates by construction.]
- **If the loadout breaks the guardrail at authoring** → the build fails naming the failing term and the shortfall. [The guardrail is a gate on data, not on the player.]
- **If `WINDOW_EXCEPTION_ENABLED` is false** → the Warden's module becomes the paid payload; the drop still exists and is still guaranteed. [The closure changes the payload, not the content.]
- **If the player equips nothing** → the aggregate is the identity and every approved number is exact. [The identity law's home.]
- **If a VS module carries a behavioural modifier** → legal at VS only; the payload schema's closed set widens with a recorded decision. [The lever set is versioned, not permanent.]

### The ability ladder

- **If the Dash socket is pressed pre-unlock** → no execution, no error state, no registry change. [SYS-01 AC-03's clause, consumed.]
- **If a grant is published twice** → the second publishes nothing (the latch). [TR-PRG-022.]
- **If `WALL_JUMP` is granted without `DASH`** → a boot failure naming the missing rung. [The order law.]
- **If a grant arrives after the player has already passed the gate** → the slice's authoring is wrong; the audit fails. [A gate must open on the grant's tick, never earlier.]
- **If the MVP slice ships a gate anyway** → the no-softlock audit runs and must prove the return path; a vacuous pass is impossible once a gate exists. [The law binds the first slice with a gate.]

### The namespace

- **If the save is loaded** → the level/XP/points/loadout restore from the namespace; the current HP is full (SYS-07's law: the save stores no HP). [Consumed.]
- **If a reconstruct follows a death after a level-up** → the namespace is carried live (never rolled back); the level survives. [TR-CSD-013's no-XP-loss law.]
- **If a v2 file carries a `progression` key** → `REFUSE_UNKNOWN_KEY`. [SYS-03's version-aware allowlist.]
- **If a v3 file is missing `equipped`** → `{drive: null, frame: null}` (the conservative default). [Absent-key-unset.]
- **If a float appears in the namespace** → the canonicalizer refuses the write. [SYS-03's no-float law.]
- **If two writers touch the namespace** → the boot fails naming both; SYS-16 is the only writer. [One writer per family.]

### Degenerate strategies — named and shut down

- **If the player hoards every point to the end** → legal: a banked point is carried, prints no row, and is spendable at the terminal whenever the player returns. [Hoarding is a choice, not an exploit — and there is no respec to need.]
- **If the player farms training data to break a wall** → the cap holds at L5 and the later rooms' awards are discarded; the ladder's row 4 is the damage ceiling, so the farm buys the *four points*, never a fifth. [The cap is the answer to the grind verb.]
- **If the player equips the strongest module and never swaps** → legal, and the second slot still forces a frame choice or an honest empty slot. [The typing, not the power, is what makes the choice.]
- **If the player re-loads to re-roll a drop** → impossible: there is no RNG and no table; the drop is a fixed placement. [Determinism is the anti-junk doctrine (D-1).]
- **If the player tries to spend a point mid-fight** → refused; the terminal is a context and the point stays banked. [The station is the only allocation surface.]

### Value and config extremes

**Knob validation law (V-PRG).** Every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry, dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config. **The guardrail and the seam are authoring gates, not runtime clamps** — a bad loadout or a non-monotone seam is a data error and must fail the build, never be silently repaired in play.

| # | Invariant | Violation resolution | Why |
|---|---|---|---|
| V-PRG-01 | identity at default: L1 with no modules → every approved number exact; the empty aggregate is `{0,0,0,0}` | dev boot failure | the identity law's home |
| V-PRG-02 | the seam is monotone: `attack` and `hp_max` non-decreasing in `L` at fixed points; the dealt value non-decreasing across every (L, a) | dev boot failure | a level-up never lowers a stat |
| V-PRG-03 | the point budget: `a + h + banked = min(L−1, POINT_BUDGET_CAP)`; each term ≥ 0 | reject + telemetry | one growth source at a time |
| V-PRG-04 | `level ≤ LEVEL_CAP_MVP` at MVP; no training data accrues past it | clamp (the award is discarded) | the MVP arc is bounded |
| V-PRG-05 | the loadout: ≤ 1 drive + ≤ 1 frame; no duplicates; every module declares a slot; **on load, an equipped id absent from the catalogue or a pair that fails the guardrail clears that slot to `null` with one report — the load never fails for gear** | refuse the equip + telemetry; the load-time case clears + reports | the typing is the law; a save must never be destroyed by a catalogue change |
| V-PRG-06 | the guardrail: every authored loadout satisfies F-PRG-06's four terms; the exception set is enumerated; **`MODULE_DAMAGE_HP_COST` is derived** (`MODULE_HP_PER_CHAIN_POINT × 2 × MODULE_DAMAGE_BONUS` = 6) so the closure payload can never drift off the exchange floor | dev boot failure (authoring) | the promise is a gate on data |
| V-PRG-07 | the exception's bound: `chain_points ≤ WINDOW_EXCEPTION_CHAIN_POINTS` | dev boot failure | the exception stays bounded |
| V-PRG-08 | the DEF retirement: no `defense` payload at MVP; `defense = 0` at every loadout | dev boot failure | a retired axis cannot leak back |
| V-PRG-09 | the max-law: `damage_bonus = max(drives)`, never the sum | dev boot failure | no silent stacking |
| V-PRG-10 | the pool clamp: a negative delta clamps the current HP; no equip heals | dev boot failure | equipment is fitted, growth is felt |
| V-PRG-11 | the grant order: `WALL_JUMP ⇒ DASH`; `DOUBLE_JUMP ⇒ WALL_JUMP` | dev boot failure | the ladder is a ladder |
| V-PRG-12 | the namespace: the registered shape, no floats, an absent key reads its conservative default, exactly one writer | refuse the load / boot failure | the mechanism's laws, consumed |

- **If `VS_ATTACK_STEP` is set to 0** → the seam is flat from L6; the config is legal but the VS sheet loses its growth; the knob's safe range floors at 4 and a 0 is clamped with telemetry. [A zero step is a design error, not a crash.]
- **If a live edit breaks the guardrail** → rejected and the last good config kept; the offending module and the failing term are named. [The guardrail is authoring-time; production never re-balances a shipped loadout under the player.]
- **If a live edit makes the seam non-monotone** → rejected (the last good config kept), naming the level and the axis. [A drop is a lie the player feels.]
- **If `POINT_BUDGET_CAP` is raised above 4 at a live edit** → **rejected** and the last good config kept: the level-up rule grants one point per level to L5 only, so a cap above 4 demands a point the curve never grants — a non-fixpoint by the V-PRG law, not a tuning choice. [The cap is fixed at MVP; VS re-opens it with a re-derived level-up rule.]

## Dependencies

**Upstream: SYS-07 is hard (the economy and the schema); SYS-08/SYS-13 are soft (the transport and the award key). Downstream: SYS-06 is hard for a grant's behaviour, SYS-24 hard for the loadout surface.**

| Direction | System | Hard/Soft | Interface (in → out) | Status |
|---|---|---|---|---|
| Upstream | **SYS-07 Health & Damage** | **Hard** | In: the `StatBlock` + identity law, the ladder, the thresholds/awards, the point values, `HealthRead`, the module stage · Out: the seam laws, `GearAggregate`, the preview's values | **APPROVED + D-ORCH-03** |
| Upstream | **SYS-08 Combat** | Soft | In: `arc`, the weapon table, `AttackContext.damage_bonus` · Out: none | **APPROVED + D-ORCH-03** |
| Upstream | **SYS-13 Enemy AI** | Soft | In: the tier per archetype · Out: none | **APPROVED** |
| Coordination | **SYS-02 Room & World** | Soft | In: the spawn list's placement, the post-flip wing · Out: the pacing budget, the drop's placement request | **APPROVED** |
| Coordination | **SYS-15 Cache Stations** | **Hard for the spend** | In: the frozen rows, the preview's contract, the carry pattern · Out: the preview's values, the namespace's carry participation | **APPROVED** |
| Downstream | **SYS-06 Movement** | **Hard for a grant** | In: `GrantEvent` · Out: the gates' behaviour (Wall Jump / Double Jump) | **APPROVED** |
| Downstream | **SYS-01 Input** | **Hard for the socket** | In: `GrantEvent` (Dash) · Out: the registry flip, the socket's state | **UNFROZEN (#10)** |
| Downstream | **SYS-24 HUD** | **Hard for the loadout surface** | In: `ProgressionRead`, `HealthRead` (level), `GrantEvent` · Out: the three-value readout, the two rows, the socket | **Not written** |
| Downstream | **SYS-17 Inventory** | MVP carve-out + gear | In: the catalogue, the loadout law · Out: the item entities, the `TAKE`, the VS namespace | **Blocked on SYS-16** |
| Downstream | **SYS-29 Juice** | Soft | In: the grant cue, the pickup chime · Out: none | **APPROVED** |
| Downstream | **SYS-03 Save** | **Hard at save time** | In: the namespace's shape + the v2→v3 bump · Out: serialization, the writer thread (ADR-0002) | **APPROVED** |
| Coordination | **SYS-05 Game Flow** | Soft | In: the Stinger's grant moment, the new-game reset, **SYS-16's carry-complete acknowledgment (a named input to `load_complete`)** · Out: the story trigger for the Stinger's grant (SYS-16 stays the sole writer of the grant set — TR-PRG-002), the reset's namespace default | **Pre-shaped** |
| Coordination | **SYS-14 Grief-Boss** | None for the award | The boss's award is **SYS-07's `XP_BOSS`** (TR-HD-007); SYS-14 authors the profile, the phases and the arena — SYS-16 consumes nothing from it at MVP | **Not written** |

**Bidirectional-consistency corrections to apply to the systems index at completion:** (1) SYS-16's row → APPROVED with the counts and the gear-layer contract, **and its OQ-SAV-11 clause (which records "a `v1→v2` bump") corrected to `v2→v3`** — SYS-15's `cache` already took v1→v2; (2) SYS-17's row gains the catalogue/namespace split and its VS migration; (3) SYS-24's row gains the three-value readout, the two loadout rows, the socket and the focus/screen-reader obligation; (4) SYS-15's row gains the preview's values and the `progression` namespace's carry participation; (5) SYS-03's row gains the v2→v3 bump; (6) SYS-07's row gains **OQ#5, OQ#18 and OQ#20 closed** and the F-HD-14 rider; (7) SYS-13's row gains the DEF revisit gate; (8) SYS-05's row gains SYS-16's carry-complete acknowledgment as a `load_complete` input.

**Rider requests (recorded, never edited here):** (a) **SYS-07's F-HD-14 VS clauses** — the `attack` candidate `100 + 6×(L−1)` **and its frozen ceiling "up to L20 (214)"** are superseded by F-PRG-01 (the candidate gives 130 at L6, below the 132 cap; F-PRG-01 gives 222 at L20 all-ATK — the rider must move both the curve and the ceiling so SYS-07 does not carry two), and the `hp_max` clause `20 + 2×(L−1)` is under-specified rather than wrong (it is exactly the **all-HP** build, reproduced by F-PRG-02 at L20); a rider at SYS-07's next doc touch (the OQ-M1 pattern). (b) **SYS-15's TR-CSD-013 body row** — "the body (store-absent: SYS-16/17's session-only namespaces)" becomes store-carried for `progression` at v3, live-carried by the same read-gated window write; a one-line rider at SYS-15's next doc touch. (c) **SYS-07's TR-HD-006 gear clauses** — "`defense` gains its first MVP source at SYS-16 authoring" **and its test clause "a module-produced DEF is legal at MVP"** are **resolved as retired** by TR-PRG-016 (D-ORCH-03 accepted the consequence; the axis stays implemented and unit-tested at 0/5/25, and its revisit gate is OQ-PRG-8 — the test clause must be re-scoped to the VS revisit, or SYS-07 keeps a fixture no MVP module can satisfy); a two-clause rider at SYS-07's next doc touch. (d) **SYS-07's F-HD-10 module-build note** — this lane's reading (TR-PRG-013: the note names the *ruler*, not a ±10% ceiling on gear) is to be made explicit, or the ceiling upheld and the pre-authorised pool-only fallback taken; the request names both outcomes. (e) **SYS-07's TR-HD-010 writer clause** — the gear-delta rule (a point's `+2` heals; a module's positive delta does not; a negative delta clamps) is a SYS-07 input, because `HealthCore` is the pool's only writer (TR-PRG-009). (f) **SYS-07's F-HD-02 branch 2** — the `attack > 132` dealt law (F-PRG-03) names SYS-07 as its implementer; unreachable at MVP (`attack ≤ 132`), so the rider is VS-gated and the MVP is unaffected.

## Tuning Knobs

**All Progression knobs are designer-only at MVP** — none is player-facing (the anti-pillar: no stat-spreadsheet menus, no respec).

**Knob validation law (V-PRG).** Every value and pair is validated at config load and re-validated on every live edit; the production resolution is clamp + rate-limited telemetry, dev asserts. A non-fixpoint config is a dev boot failure; production keeps the last good config.

| Knob | Default | Safe range | Extreme behavior (too low / too high) | Interactions | Rule |
|---|---|---|---|---|---|
| `VS_ATTACK_STEP` | 6 | 4–8 | <4: the VS sheet barely grows · >8: the VS cap runs away (222+) | `ATK_PER_POINT`, F-PRG-01 | TR-PRG-008 |
| `POINT_BUDGET_CAP` | 4 | **4 (fixed at MVP)** | >4: the level-up rule grants one point per level to L5 only, so a cap above 4 is a non-fixpoint and fails the boot (F-PRG-08); VS may re-open it with a re-derived level-up rule | `LEVEL_CAP_MVP` | TR-PRG-007 |
| `MODULE_SLOTS` | 2 (1 drive + 1 frame) | 2 (fixed) | 1: no build · 3: stacking returns | the catalogue | TR-PRG-015 |
| `MODULE_DAMAGE_BONUS` | 1 | 1 (fixed identity) | 0: the drive axis vanishes · 2: +4 chain points, unbuyable | `MODULE_HP_PER_CHAIN_POINT` | TR-PRG-012 |
| `MODULE_HP_PER_CHAIN_POINT` | 3 | 2–4 | <2: damage is cheap (power creep) · >4: damage is a trap | `MODULE_DAMAGE_BONUS` | TR-PRG-014 |
| `MODULE_DAMAGE_HP_COST` | derived (3 × 2 × 1 = 6) | — (derived, never edited) | an edited value drifts the closure off the exchange floor (V-PRG-06) | F-PRG-06(b) | TR-PRG-014 |
| `MODULE_FRAME_HP_BONUS` | 2 | 2–4 | 4: +20% pool, over the band · 2: exactly 10% | `GEAR_BAND_PCT` | TR-PRG-014 |
| `MODULE_COUPLER_HP_COST` | 8 | 6–10 | 6: the pair overshoots the floor (+2 back) · 10: the pair is at −8 (over-paying) | F-PRG-06(b) | TR-PRG-019 |
| `GEAR_BAND_PCT` | 0.10 | 0.05–0.15 | <0.05: no module fits · >0.15: the promise weakens | the budget table | TR-PRG-014 |
| `WINDOW_EXCEPTION_ENABLED` | true | on/off | off: the Warden's module becomes the paid payload | F-PRG-07 | TR-PRG-017 |
| `WINDOW_EXCEPTION_CHAIN_POINTS` | 2 | 2 (fixed bound) | 4: the exception doubles and the promise breaks | F-PRG-07 | TR-PRG-017 |
| `PACING_PASS_YIELD_MIN` | 30 | **30–40** (the floor is derived: `ceil(TRAINING_DATA_L4 ÷ PACING_PASSES_L4_MAX)` = `ceil(90 ÷ 3)` = 30, asserted at boot) | <30: L4 needs a 4th pass · <25: L5 needs a 5th pass · >40: the curve flattens | the spawn list, the tiers | TR-PRG-005 |
| `PACING_PASSES_L4_MAX` | 3 | 2–4 | >4: the growth is not felt in the slice | `PACING_PASS_YIELD_MIN` | TR-PRG-005 |
| `PACING_PASSES_L5_MAX` | 4 — passes **including** the boss's (pure farm alone needs 5) | 3–5 | >5: the cap is unreachable in an MVP session | `XP_BOSS` | TR-PRG-005 |
| `PACING_T3_PER_PASS` | 1 | 1–2 | 0: the punish lesson is optional-only · 2: RM-05's single spawn cannot hold it | the tier assignment | TR-PRG-005 |
| `PROGRESSION_SCHEMA_VERSION` | 3 | 3 (the bump) | 2: the namespace cannot exist; 4 without a migration: refuse | SYS-03's registry | TR-PRG-025 |
| `LOADOUT_SWAP_SURFACE` | `pause` | `pause` \| `cache` | `cache`: the swap joins SYS-15's frozen row set (a contract change) | SYS-24/SYS-15 | TR-PRG-020 |
| `PRG_READOUT_VALUES` | 3 (level, HP, ATK) | 3 (fixed at MVP) | 4: DEF returns with no source (a lie); 9: the sheet (VS) | TR-PRG-011 | TR-PRG-011 |
| `MODULE_LORE_LINES` | 2 | 2 (fixed) | 3: the module becomes a paragraph | TR-PRG-018 | TR-PRG-018 |
| `POINT_SPEND_SURFACE` | `cache` | `cache` (fixed) | elsewhere: SYS-07's law breaks | TR-CSD-006 | TR-PRG-006 |
| `GRANT_ORDER` | `strict` | `strict` (fixed) | relaxed: the ladder stops being a ladder | F-PRG-09 | TR-PRG-021 |

**Cross-system inputs (consumed at registration — not SYS-16 knobs, but validated by SYS-16):** `physics_tps` (engine) · `PLAYER_MAX_HP` 20, `HP_PER_POINT` 2, `PLAYER_ATK_BASE` 100, `ATK_PER_POINT` 8, `DAMAGE_LADDER_MVP`, `TRAINING_DATA_L2..L5`, `XP_T1/T2/T3`, **`XP_BOSS`** (the boss's award — SYS-07's, never SYS-14's), `LEVEL_CAP_MVP` 5 (SYS-07's) · `DEF_CAP_PCT` 25 (SYS-07's; the retired axis's cap) · the four weapon arcs' damage 2/4/2/2 and the `arc` enum (SYS-08's) · the tiers 6/12/24 (SYS-07's), **`BOSS_HP` 60 (SYS-07's TR-HD-011 — the ledger's fourth ruler)** and the tier-per-archetype (SYS-13's) · `CACHE_REFILL` and the terminal's row set (SYS-15's) · `DORMANT_DIM_AFTER_TEASE` (SYS-01's) · `CURRENT_SCHEMA_VERSION` 2 (SYS-03's, at the bump's branch point). A missing or invalid cross-system input is a dev boot failure, never a silent default.

**Not knobs (documented so nobody adds them):** the seam laws (F-PRG-01/02/03) · the point budget identity · the guardrail's four terms · the lever set · the drive/frame typing · the max-law · the identity-at-default · the DEF retirement · the namespace's shape · `banked_points` (derived) · `chain%`/`pool%` (derived) · the ladder order · the no-softlock law · the ladder's authored unlock moments (content, not tuning).

**Provisional lifetimes:** the pacing counts (playtest — the slice's population) · `VS_ATTACK_STEP` (VS playtest) · `MODULE_HP_PER_CHAIN_POINT` / `MODULE_COUPLER_HP_COST` (playtest) · `WINDOW_EXCEPTION_ENABLED` (the Gate-2 probe) · the module lore (a copy pass, SYS-28).

## Visual/Audio Requirements

*(Progression names the states and the edges; rendering is SYS-24's, VFX/audio is SYS-29/SYS-04's, the art pass is the art bible's.)*

- **The dormant Dash socket:** hidden → dimmed-after-tease with a lock glyph → active. It must read as **a promise, not a broken button** — the dim is a slow, steady state, never a flash, never a "locked!" toast. The glyph is a silhouette-first shape (legible at 480×270).
- **The module pickup:** the standard `TAKE` bubble (SYS-01's) and the memory-chime family's audio-led cue (TR-JCE-021's pickup-class treatment) + one print row naming the module. **No bespoke VFX at MVP** (the stone's glow, the wing motif are the art pass — OQ-PRG-3).
- **The pause loadout rows:** two rows, the module's display name and its effect in the game's units (`damage +1`, `chassis +2`, `damage +1 · chassis −8`). **No percentage, no colour-coded rarity, no icon-only rows** (the meaning = text + shape law).
- **The three-value readout:** level, HP and ATK — ATK as the row's pair (`ATK 2/4`), flat print rows in the terminal's voice, never a panel with borders. `DEF` renders only when it has a source.
- **The level-up:** SYS-29's existing level-up print (TR-JCE's edge) — no fanfare, no confetti; the point is a pip that appears.
- **Audio:** the grant cue reuses the memory-chime voice (SYS-04 designs it; one chime per grant); the pickup is the same family; the equip is silent (a menu action is not a beat).

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:progression` for the socket glyph, the three module sprites and the terminal rows' dimensions.

## UI Requirements

**The read contract plus two small surfaces, never a sheet.**

- **The pause readout (SYS-24):** three values (level, HP, ATK) as flat print rows; the two loadout rows below them with the equip/unequip action; every row ≥ 48 dp; focus order top→bottom; a screen reader announces each row's label and its effect. **No submenu, no comparison tooltip, no sheet, no respec.**
- **The loadout rows:** the equipped name + effect; the available list is the `owned` set; an empty slot prints `—`. The row's effect text is generated from the payload (the game's units), never hand-typed per module (a hand-typed string would drift from the payload).
- **The dormant socket (SYS-01's geometry, SYS-24's render):** the third state must be distinguishable from "active" by shape, not colour alone.
- **The terminal (SYS-15's, unchanged):** the two training rows are SYS-15's; SYS-16 supplies the preview values. **Do not add loadout rows to the terminal** — its row set is frozen (AC-CSD-06) and the swap surface is the pause (`LOADOUT_SWAP_SURFACE`).
- **No stat sheet at MVP.** The nine-stat readout is VS (SYS-26); the anti-pillar's amended wording (D-2) permits a lean, accessible stat menu at VS, never a numeric spreadsheet.

**UX flag:** `/ux-design` for the pause readout + the loadout rows + the dormant socket's three states **before the SYS-24 UI stories**; the legibility audit runs at the locked art scale (480×270).

## Acceptance Criteria

**Classification legend:** `[GUT]` automatable in Godot Unit Test · `[LINT]` static audit · `[GUT + LINT]` a dual-tagged AC whose GUT half gates first and whose static half runs in the same gate · `[DEVICE]` on-device manual QA · `[PLAYTEST]` human feel observation with the SYS-01 AC-63 protocol.

### The boundary and the state

- **AC-PRG-01** [GUT] *(TR-PRG-001)* — **GIVEN** the consumed constants and the printed ladder, **WHEN** the boundary audit runs, **THEN** after the sync lands the registry diff for SYS-07's constants is empty, and before it the pending list is exactly the seven named constants (`atk_per_point`, `player_atk_base`, `level_cap_mvp`, `xp_t1`, `xp_t2`, `xp_t3`, `xp_boss`) with any other absence failing the boot; `src/progression/` contains zero threshold literals and zero ladder cells (CI grep); a mocked SYS-07 missing `TRAINING_DATA_L3` fails the boot naming it.
- **AC-PRG-02** [GUT + LINT] *(TR-PRG-002)* — **GIVEN** a `ProgressionState`, **WHEN** the writer audit runs, **THEN** exactly one **runtime** writer exists per field (`level`/`training_data` → SYS-07; `atk_points`/`hp_points`/`grants`/`owned`/`equipped` → SYS-16) and exactly one **namespace** writer (`progression` → SYS-16) — **the LINT half**; `banked_points` is a read alias whose equality with `HealthRead.training_points` is asserted every publication, and a divergence is refused with telemetry — **the GUT half**; the budget identity reproduces on every fixture.
- **AC-PRG-03** [GUT] *(TR-PRG-003)* — **GIVEN** a 10,000-tick soak, **WHEN** the counters are read, **THEN** `ProgressionCore` ticks 0 times, its **core-owned allocation counter** reads 0 (the reducer's own counter, not a GDScript-wide claim), and the aggregate's recompute count equals the `SYNC`/`EQUIP`/`UNEQUIP`/`SPEND_POINT` command count exactly.

### Level 1–5 and the point

- **AC-PRG-04** [GUT] *(TR-PRG-004)* — **GIVEN** kills accrue, **THEN** L2 at 20, L3 at 50, L4 at 90, L5 at 140; a Husk awards 3, a Spitter 7, a Warden 14, the boss **40 from SYS-07's `XP_BOSS`** (SYS-14 is not in the award path and the MVP boot does not require it); a kill at L5 accrues nothing and publishes no level edge; **the double-crossing fixture** (a 40 award taken at 16–19 XP → two levels, two points, two edges in one tick, crossed in order); **the queue fixture** (a level-up arriving during a gate or the death beat banks at the next gameplay tick, publishing one edge).
- **AC-PRG-05** [GUT] *(TR-PRG-005, F-PRG-04)* — **GIVEN** SYS-02's five-spawn layout (**RM-03's pinned 1 Spitter + 1 Husk**) and SYS-13's tier-per-archetype, **WHEN** the ledger runs, **THEN** one pass yields **30** (6 + 10 + 14), the landmarks are L2@1 / L3@2 / L4@3 passes and L5 at the fourth pass's boss (160, the excess discarded), `passes_to(L4) = 3 ≤ PACING_PASSES_L4_MAX`, and a derived yield under `PACING_PASS_YIELD_MIN` is flagged at build time naming the pass count it would take; the table is regenerated from the spawn list and the tiers (a change to either re-derives it — nothing is hand-typed); the wing's spawn list stays empty (SYS-02's five-spawn fixture untouched).
- **AC-PRG-06** [GUT] *(TR-PRG-006, TR-PRG-026; AC-CSD-04 consumed)* — **GIVEN** one banked point at the terminal, **WHEN** `STRIKES` commits, **THEN** SYS-16 writes `atk_points` +1 and SYS-07 reads `ProgressionRead` and applies exactly one `StatRevision` (the ack chain), the effective pair republishes as `ATK 3/4`; **GIVEN** `CHASSIS`, **THEN** max HP +2 **and** current HP +2 in the same application; the surface's own clauses (0 banked → no row; a spend outside the terminal refused) are **SYS-15's AC-CSD-04, cited not duplicated**; **the ledger fixture reproduces TR-PRG-006's five-row table cell for cell, with the Warden column (4/4/3/3/3) and the boss column (10/9/8/7/6) named explicitly** (the table is the single source; this AC pins its expected cells so an edited table cannot pass silently).
- **AC-PRG-07** [GUT] *(TR-PRG-007, F-PRG-08)* — **GIVEN** the budget identity, **THEN** `a + h + banked = min(L−1, 4)` at L1/L5/L6/L20; a level-up past 5 banks nothing; a fifth point is rejected with telemetry; a banked point survives a reconstruct and a fresh load.

### The seam

- **AC-PRG-08** [GUT] *(TR-PRG-008, F-PRG-01)* — **GIVEN** the seven fixtures, **THEN** attack is 100 (L1/a0), 132 (L5/a4), 106 (L6/a0), 138 (L6/a4), 122 (L6/a2), 190 (L20/a0), 222 (L20/a4); the monotonicity sweep over every (L, a) pair finds no decrease in either axis; the L5→L6 step is +6 for all five splits; **the live-edit fixtures**: `VS_ATTACK_STEP = 0` is clamped to 4 with telemetry, and a live edit making the seam non-monotone is rejected with the last good config kept (naming the level and the axis).
- **AC-PRG-09** [GUT] *(TR-PRG-009, F-PRG-02)* — **GIVEN** the pool fixtures, **THEN** 20 (L1/h0), 28 (L5/h4), 30 (L6/h4), 22 (L6/h0), 50 (L20/h0), **58 (L20/h4)**; a negative module delta clamps the current HP; a point's +2 heals; a module's +2 does not; **the unequip fixture** (unequipping a frame at 6/22 leaves 6/20 — the pool shrinks and the current HP is untouched, so an unequip never heals).
- **AC-PRG-10** [GUT] *(TR-PRG-010, F-PRG-03)* — **GIVEN** attack 132 and 138, **THEN** both give 4/6/3/4, chain 10 (the seam is flat); **GIVEN** 162 and 222, **THEN** chain 11 and chain 16; **GIVEN** every (L, a) pair, **THEN** the dealt value is non-decreasing; **the split-independence fixture** (a = 0, 2, 4 each cross the seam without a loss); **GIVEN** `arc = ABILITY`, **THEN** the ladder is not read.
- **AC-PRG-11** [GUT + LINT] *(TR-PRG-011)* — **GIVEN** the pause readout, **THEN** exactly three values render (level, HP, ATK); **HP renders as current/max (`HP 12/20`)**; **ATK prints the effective pair (the ladder row + `damage_bonus`) — `ATK 2/4` bare, `ATK 3/5` with the Coupler — never the raw 100–132 scale, and the geared fixture's readout equals the dealt fixture's values**; no DEF row renders while `defense = 0`; **the static audit (LINT half)** finds no nine-stat surface, no comparison tooltip and no respec in the MVP build; the loadout rows print the effect in the game's units and in the chassis vocabulary (`damage +1`, `chassis +2`), never a percentage and never "pool".

### The gear layer

- **AC-PRG-12** [GUT] *(TR-PRG-012)* — **GIVEN** the payload schema, **WHEN** a module declares any field outside `{hp_max, damage_bonus}`, **THEN** it is rejected naming the field; the catalogue audit finds no attack, defense or behavioural payload; a windowed payload (a per-target or per-arc condition) is rejected by the schema.
- **AC-PRG-13** [GUT + LINT] *(TR-PRG-013)* — **GIVEN** the Quantisation Law, **THEN** **the LINT half** finds the printed law naming all three answers and their reasons, the window refusal's reason naming TR-HD-006's two revision causes, F-HD-10's reading printed with rider (d) and its named fallback (the pool-only gear layer), and the fallback's data switch present; **the GUT half** reproduces the attack lever's exclusion (+16.7% at row 0, +11.1% at row 3, 0% at row 4), **the DEF sweep (DEF 1–24 × raw 1–4, every value ≡ DEF 25's 1/1/3 — the retirement's proof)**, the two-cause revision audit on the revision counter, and **the pool-only fallback fixture** (`WINDOW_EXCEPTION_ENABLED = false` + the drive payload removed re-runs the budget table and every loadout passes on the pool axis alone).
- **AC-PRG-14** [GUT] *(TR-PRG-014, F-PRG-06)* — **GIVEN** the six loadouts, **WHEN** the budget runs, **THEN** the table reproduces exactly (∅ pass; Governor +10% pass; Coupler −8 pass; Coupler+Governor −6 pass at the floor; Regulator-000 exception; Regulator-000+Governor exception); the table holds at L5 all-ATK and L5 all-HP; a loadout violating (b) fails authoring with the shortfall printed; the exception set is exactly one id **while `WINDOW_EXCEPTION_ENABLED` is true** (with it false the set is empty — TR-PRG-013's fallback); **the live-edit fixture** (an edit breaking the guardrail is rejected with the last good config kept, naming the module and the failing term).
- **AC-PRG-15** [GUT] *(TR-PRG-015, F-PRG-05)* — **GIVEN** the loadout, **THEN** a drive in the frame slot is refused; a duplicate is refused; **the sign fixture** (a drive carrying `hp_max +2` is refused as a frame payload; a frame carrying `damage_bonus` is refused); **the aggregate fixture** (the Coupler alone → `hp_max_delta −8`, the Coupler + Governor → `−6`, the Regulator + Governor → `+2` — the drive's cost lands in the sum, F-PRG-05); a synthetic two-drive catalogue yields the **max** (1), never the sum (2); **the unequip fixture** (BUILT → `UNEQUIP(drive)` reaches FRAMED with the frame still fitted, and vice versa); the empty loadout's aggregate is `{0,0,0,0}` and every approved number is exact.
- **AC-PRG-16** [GUT] *(TR-PRG-016)* — **GIVEN** the catalogue, **THEN** zero modules carry a `defense` payload; every MVP loadout's `defense` is 0; AC-HD-14's DEF 0/5/25 fixtures still pass unchanged; the revisit gate prints its threshold (`raw ≥ 12` on power 3) and its owners.
- **AC-PRG-17** [GUT] *(TR-PRG-017, F-PRG-07)* — **GIVEN** the Warden-tier part, **THEN** it is a placed `TAKE` **in the Cold Corridor wing** (beside M4 or at the wing's end — SYS-02's placement, OQ-PRG-4), present on every run, **unreachable at epoch 0** (the zone gate is SEALED — SYS-02's TR-RWS-009); its `chain_points` is 2 (the bound); the printed exceedance is +33.3% at row 0 and +20% at row 4; with `WINDOW_EXCEPTION_ENABLED = false` the payload becomes `{damage_bonus +1, hp_max −MODULE_DAMAGE_HP_COST}`, the budget re-runs with zero exceptions, **the paid module alone passes (Δhp −6) and the paid module + a frame is refused at equip with the shortfall printed (Δhp −4 fails (b))** — the closure narrows the loadout, it does not re-tune the derived cost.
- **AC-PRG-18** [GUT + LINT] *(TR-PRG-018)* — **GIVEN** the catalogue, **THEN** three entries with unique ids, a declared slot each (2 drive + 1 frame), a payload inside the closed set (**each payload value is its named symbol** — `MODULE_DAMAGE_BONUS`, `MODULE_COUPLER_HP_COST`, `MODULE_FRAME_HP_BONUS`), **exactly two lore lines** each, and a fixed source (no table, no RNG); **the lore audit (LINT half)** finds no percentage and no banned term; **in the pool-only fallback the count is one entry (the frame) and the drive/frame split is vacated** (TR-PRG-013's conditional criteria).
- **AC-PRG-19** [GUT] *(TR-PRG-019)* — **GIVEN** the Coupler, **THEN** alone it is chain 8 / chassis 12 (Δhp −8); with Governor-207 it is chain 8 / chassis 14 (Δhp **−6**, the floor); **while `WINDOW_EXCEPTION_ENABLED` is true** the pair is the only loadout that lands exactly on the floor (with it false the paid Regulator alone also lands on −6 — TR-PRG-013's fallback).
- **AC-PRG-20** [GUT] *(TR-PRG-020)* — **GIVEN** a dropped module, **THEN** walking over it does nothing, `TAKE` acquires it (one print row + one chime edge, zero haptics), nothing auto-equips; **GIVEN** an equip, **THEN** exactly one `StatRevision` and the aggregate updates; a negative delta clamps; **the mid-fight fixture** (with the pause context unavailable the swap is unavailable — no path exists); the pause surface shows two rows and no third surface exists.

### The ability ladder

- **AC-PRG-21** [GUT] *(TR-PRG-021, F-PRG-09)* — **GIVEN** the grant set, **THEN** `{WALL_JUMP}` alone fails the boot naming `DASH`; `{DOUBLE_JUMP}` alone fails naming `WALL_JUMP`; `{STINGER}` alone is valid (off-ladder); the Dash grant flips SYS-01's registry entry **and SYS-06's mock `GrantPort` receives the gate** (the integration boundary is the port, so the GUT half is executable); the input layer's event record is bit-identical pre/post (SYS-01 AC-06, cited).
- **AC-PRG-22** [GUT] *(TR-PRG-022)* — **GIVEN** a grant, **THEN** one `GrantEvent` publishes and the latch holds (a second publishes nothing); the grant survives a reload; **the late-consumer fixture** (SYS-06 starts after the grant, reads the persisted set at init, applies the gate, and no second event publishes); the cue fires once (one edge, one row, zero haptics); with SYS-06 absent at the grant the grant is recorded and the gate is not applied, with telemetry.
- **AC-PRG-23** [GUT] *(TR-PRG-023)* — **GIVEN** the MVP slice at boot, **THEN** zero grants exist; the Dash socket is dimmed, non-executing and non-erroring (SYS-01 AC-03's clause); the ladder table has three rows, each with a moment, a slice, an owner and a placement home.
- **AC-PRG-24** [GUT] *(TR-PRG-024)* — **GIVEN** the MVP slice, **THEN** the no-softlock audit prints "0 gates, vacuous pass" (never a silent skip); **GIVEN** a synthetic one-way gate with no return path, **THEN** the audit fails; **GIVEN** a gate that admits a pre-grant body, **THEN** the audit fails.

### The persistence and the read contracts

- **AC-PRG-25** [GUT] *(TR-PRG-025, F-PRG-10)* — **GIVEN** a save round-trip, **THEN** every field restores; the absent namespace at v3 defaults whole; no float serializes; `banked_points` is absent from the stored shape (derived); the carry fixture shows a level earned after the save surviving a reconstruct while the saved value seeds only a fresh load; **the read-gate fixture** (a `ProgressionRead` consumer before SYS-16's carry-complete acknowledgment is refused — no consumer observes the rollback); **the load-validation fixtures** (an equipped id absent from the catalogue clears its slot and reports; **an `owned` id absent from the catalogue is removed from `owned` in the same load and folded into that one report; a save holding only catalogued ids loads unchanged**; a post-closure pair that fails the guardrail clears the drive and reports; the load succeeds in all of them).
- **AC-PRG-26** [GUT] *(TR-PRG-025)* — **GIVEN** a synthetic v2 file, **WHEN** the v2→v3 migration runs, **THEN** `progression` appears with the conservative default and the `world`/`cache` families are byte-identical; **GIVEN** a v2 payload carrying `progression`, **THEN** `REFUSE_UNKNOWN_KEY`; **GIVEN** a v3 file missing `equipped`, **THEN** `{null, null}`; two writers fail the boot.
- **AC-PRG-27** [GUT] *(TR-PRG-026)* — **GIVEN** the read contracts, **WHEN** SYS-24/SYS-15/SYS-17 mocks consume them, **THEN** every field is present, there is no writer field and no `level` field (no duplicate of `HealthRead`), and `attack_delta`/`defense_delta` are 0 at MVP.
- **AC-PRG-28** [LINT] *(TR-PRG-027)* — **GIVEN** the codebase, **WHEN** the boundary audit runs, **THEN** `src/progression/` contains no screen, no item entity, no serializer and no input symbol; the VS-migration record for `owned`/`equipped` is present; the terminal's row set is unchanged (SYS-15 AC-CSD-06, cited).
- **AC-PRG-29** [GUT] *(TR-PRG-028)* — **GIVEN** the TR-PRG registry, **WHEN** the traceability audit runs, **THEN** every TR has an AC **or a named fixture inside one** (the audit is fixture-level, not TR-level), every formula has an AC, the counts are 28 TR / 10 formulas / 12 V-PRG / 36 ACs / 44 edge bullets / 8 OQs / 21 knob rows (all five counted, not three), the gate partition sums 29+2+5+0 = 36, and no `[To be designed]` exists; the purity audit finds no engine symbol in `ProgressionCore`; **the command-totality fixture** (every command from every state yields a defined state or a named refusal, including BUILT → `UNEQUIP(slot)` reaching exactly one state); the replay is bit-identical under `FakeProgressionPort`.

### Device

- **AC-PRG-30** [DEVICE] *(TR-PRG-011/023/027)* — **GIVEN** the device matrix at the locked 480×270 art scale, **WHEN** the pause surface and the socket are inspected, **THEN** the three-value readout and the two loadout rows are legible, every row is ≥ 48 dp and reachable, **the focus order is top→bottom**, **a screen-reader session announces each row's label and its effect** (name + role per row), **the effect text is generated from the payload — an edited payload changes the row's text with no string edit** (no hand-typed per-module string), the three socket states are distinguishable **by shape**, and no row occludes the body.
- **AC-PRG-31** [DEVICE] *(TR-PRG-025)* — **GIVEN** a real device, **WHEN** the player levels, spends, equips, then suspends/kills the app (iOS background-kill / Android onStop / desktop quit), **THEN** the relaunch restores the level, the points, the grants and the loadout exactly; the suspension save's cause is the platform's event from SYS-15's closed set, **observed on the save-machine's debug log (the named observation surface — the save record's `cause` field is printed at the drain, so the check is a log assertion, not an inference)**.
- **AC-PRG-32** [PLAYTEST] *(TR-PRG-017/020; the concept's Gate-2 gear probe)* — **GIVEN** ≥5 testers × ≥30 min (the SYS-01 AC-63 protocol) with a session script that includes the flip and the Cold Corridor backtrack, **WHEN** the rubric codes **G5 the-earn** (inclusion: the part, I went back for it, it was the Warden's, I put it on; exclusion: didn't see it, didn't know what it was, skipped it), **THEN** ≥3/5 of the testers **who took the part** are coded G5 — and the qualifying subset is floored: **fewer than 4 of 5 qualifying invalidates the run and it is topped up** (no 3-of-5 fallback). The print row and the chime are the only cues; no bespoke VFX is required for the beat to land.

### Feel and the promise

- **AC-PRG-33** [PLAYTEST] *(TR-PRG-006, Player Fantasy)* — **GIVEN** ≥5 testers × ≥30 min (the SYS-01 AC-63 protocol) with at least one point spend each, **WHEN** the rubric codes **G1 growth-chosen** (inclusion: chose it, knew what it bought, picked it myself; exclusion: automatic, didn't notice, no difference), **THEN** ≥3/5 of the testers who spent ≥1 are coded G1; **fewer than 4 of 5 qualifying invalidates the run and it is topped up.**
- **AC-PRG-34** [PLAYTEST] *(TR-PRG-017; the concept's Gate-2 parity-promise probe)* — **GIVEN** the same cohort and a script that includes the Warden-tier part, **WHEN** the rubric codes **G2 parity-promise** (inclusion: earned it, a reward, it cost me the fight; exclusion: too strong, broke the game, a cheat, a broken promise), **THEN** ≥3/5 of the testers who took the part read it as a reward, **and the closure rule is the concept's verbatim: a single coded "broken promise" answer closes `WINDOW_EXCEPTION_ENABLED`** (the module becomes the paid payload; the closure is a data switch, recorded, and reversible only by a new decision) — **the reward bar is the signal, the broken-promise answer is the gate**; fewer than 4 of 5 qualifying invalidates the run and it is topped up.
- **AC-PRG-35** [PLAYTEST] *(TR-PRG-019, the trade's legibility)* — **GIVEN** the same cohort and a script that includes one Coupler equip, **WHEN** the rubric codes **G3 trade-legible** (inclusion: it costs me chassis, I read the row, I chose the trade; exclusion: didn't know, felt cheated, hidden), **THEN** ≥3/5 of the testers who equipped it can state its cost unprompted; fewer than 4 of 5 qualifying invalidates the run and it is topped up.
- **AC-PRG-36** [PLAYTEST] *(TR-PRG-023, the anticipation design)* — **GIVEN** the same cohort and a session that includes the dimmed Dash socket, **WHEN** the rubric codes **G4 lock-as-promise** (inclusion: not yet, it's coming, I looked for where it goes; exclusion: broken, bugged, confusing), **THEN** ≥3/5 read the lock as a promise rather than a fault; fewer than 4 of 5 qualifying invalidates the run and it is topped up.

### Gate manifest

The four-gate partition, exactly one gate per AC. `[GUT]`/`[LINT]`/`[DEVICE]`/`[PLAYTEST]` describe where an AC runs, not which gate owns it.

| Gate | Units | ACs | Execution |
|---|---:|---|---|
| **MVP smoke** | **29** (24 GUT + 4 dual GUT+LINT + 1 LINT) | AC-PRG-01…29 | Headless GUT/LINT on the CI build |
| **MVP device** | **2** | AC-PRG-30, AC-PRG-31 | Device matrix (QA plan §7.1) |
| **MVP-lock** | **5** | AC-PRG-32…36 | Playtest + coded rubric (SYS-01 AC-63 protocol) |
| **VS** | **0** | — | The VS content (the nine-stat sheet, behavioural modifiers, the second drive slot, Elegy, the inventory migration) is recorded in the Open Questions, not AC'd at MVP |
| **Total** | **36** | | 29 + 2 + 5 + 0 = 36 |

**Exactly-one proof.** Every AC-PRG-01…36 appears in exactly one gate; no AC is in two gates; the count is 36. The smoke gate's dual-tagged ACs (02, 11, 13, 18) gate their GUT half first and their LINT half in the same run; the DEVICE-tagged ACs do not default home to smoke; the playtest ACs are MVP-lock, not smoke. **The gear beat (AC-PRG-32) is a lock gate, not a device gate** — its outcome is a coded observation, and the device matrix cannot falsify it. The Progression QA plan will expand the device/playtest protocols; this manifest is the GDD-side partition.

### Playtest coding table (G1–G5)

The **five playtest ACs** use the SYS-01 AC-63 protocol: ≥5 testers × ≥30 min, two facilitators coding per statement, agreement ≥ 90%, Cohen's kappa ≥ 0.7, disagreements adjudicated by the definition list, never by taste. **The negation rule is the SYS-01 AC-63 operationalization:** a negated forbidden term within 3 tokens of its subject does **not** block; a negated inclusion term **does** block; set-membership idioms are evaluated first. **The elicitors are Progression's own** — the SYS-01 script's four questions cannot elicit a point spend, a module's cost or a dimmed socket, so each code carries its question.

| Code | The elicitor (asked after free play, before the definition list is shown) | Inclusion set | Exclusion set |
|---|---|---|---|
| **G1 growth-chosen** | "Tell me about the last point you spent at the terminal — what did you get?" | chose it, knew what it bought, picked it myself, worth it | automatic, didn't notice, no difference, pointless |
| **G2 parity-promise** | "You found the part in the corridor behind the shifted wall. What was that, and what did it do for you?" | earned it, a reward, it cost me the fight, I went back for it | too strong, broke the game, a cheat, unearned, a broken promise |
| **G3 trade-legible** | "Tell me about the module you put on and then took off." | it costs me chassis, I read the row, I chose the trade | didn't know, felt cheated, hidden, a trap |
| **G4 lock-as-promise** | "The dash button in the corner — what did you make of it?" | not yet, it's coming, I looked for where it goes | broken, bugged, confusing, a dead button |
| **G5 the-earn** | "Did you go back anywhere after the world changed? What did you find?" | the part, I went back for it, it was the Warden's, I put it on | didn't see it, didn't know what it was, skipped it |

**The qualifying-subset floor:** each code's denominator is the testers who performed the act (spent ≥1, took the part, equipped the Coupler, saw the socket, took the part). **Fewer than 4 of 5 qualifying invalidates the run and it is topped up** — no 3-of-5 fallback, because a 2-tester denominator makes "≥3/5" unreadable (SYS-02's E1 precedent, consumed).

## Open Questions

| # | Question | Owner | Target |
|---|---|---|---|
| 1 | **The glass-alone build** — the Coupler with no frame is 12 HP; the MVP roster's heaviest strike is power 2 (no power-3 strike ships), so 6 hits — playable, or a trap? If it reads as a trap at playtest, `MODULE_COUPLER_HP_COST` drops to 6 and the Coupler+Governor pair is re-authored (the pair would overshoot the floor by 2). | SYS-16 + QA | Playtest (Gate 2) |
| 2 | **The exception's closure** — AC-PRG-34's G2 code decides whether `WINDOW_EXCEPTION_ENABLED` stands; **the concept's rule is verbatim and single-answer: one coded "broken promise" closes it** (the module becomes the paid payload, the same loadout as Coupler+Governor, and the module loses its reason to exist — a content decision follows). The closure is a data switch, reversible only by a new decision. | SYS-16 + qa-lead | Gate 2 |
| 3 | **The module art + the pickup's bespoke VFX** — the three modules' sprites, the socket's lock glyph, and whether the Warden-tier part earns a bespoke glow (TR-JCE-021's OQ-J3 pattern: the relic's bespoke VFX is the art pass). | art-director + technical-artist | After the art bible; `/asset-spec system:progression` |
| 4 | **The part's exact position in the wing** — the Cold Corridor wing (10×6 tiles, RM-03's zone) holds memory M4; the Warden-tier part sits beside it or at the wing's end. The placement is SYS-02's room data and must satisfy AC-PRG-32's instrument. **A guard enemy in the wing is not available**: SYS-02's frozen layout pins five spawns with a two-per-room maximum. **Target: before the first SYS-02 room-data touch and before the first SYS-24 story** — AC-PRG-32 gates on it. | SYS-02 + level-designer | Before the SYS-02/SYS-24 stories |
| 5 | **The VS inventory migration** — the MVP's `owned`/`equipped` keys move to SYS-17's `inventory` namespace at VS (a v3→v4 bump + a migration step); the split's exact boundary (does SYS-17 own the catalogue's payloads too?) is SYS-17's authoring decision. | SYS-17 | At SYS-17 authoring |
| 6 | **The fourth point's home** — it arrives at the boss's death and the MVP slice ends there; whether the player can walk back to the cache to spend it (SYS-05's post-boss state) or the point is banked for the VS carry is SYS-05's call. **The recommendation:** keep the cache reachable post-boss so the fourth decision is actually taken — three chosen and one carried is a weaker promise than four chosen. | SYS-05 | At SYS-05 authoring |
| 7 | **The loadout surface's final shape** — the pause's two rows are SYS-24's render of SYS-16's law; whether the rows live in the pause's root or a sub-pane, and the a11y read-out order, are SYS-24's (with the accessibility specialist's baseline). | SYS-24 + accessibility-specialist | Before the first SYS-24 story |
| 8 | **The DEF revisit** — DEF returns to gear when SYS-13's strike table's reference heavy (power 3) reaches `raw ≥ 12`; the VS strike scale is SYS-13's, and the moment it crosses the threshold this lane's retirement should be re-opened with a named decision. | SYS-13 + SYS-07 | At the VS strike re-scale |

### Closed by this GDD (the record)

| OQ | Question | Resolution | Where |
|---|---|---|---|
| **SYS-07 OQ#20** | The L5→L6 growth handoff — does the ladder continue, or does the percent curve take over, and at what damage scale? | **The ladder continues.** The points stay additive, the level adds a flat +6 from L6, and the ladder extends by its top row (`max(row 4, floor(row 4 × attack ÷ 132))`). Monotone in the stat and the dealt value for every split; the frozen `100 + 6×(L−1)` candidate is superseded (it drops 2 attack at L6); the pool re-base is reproduced exactly (58 at L20 = the all-HP build). | TR-PRG-008/009/010; F-PRG-01/02/03; the rider request to SYS-07's F-HD-14 |
| **SYS-07 OQ#5** | The SYS-16 scope split — MVP points-only 1–5 vs the full nine-stat sheet, and the curve handoff. | **Split confirmed:** MVP = the points model + the gear layer + three read values; VS = the nine-stat sheet, behavioural modifiers, a second drive slot. The handoff is OQ#20's, above. | TR-PRG-011/012; the no-full-sheet law |
| **SYS-07 OQ#18** | The nine-stat sheet readout vs no readout — the pause screen's diegetic values, and the "no stat-spreadsheet menus" anti-pillar. | **MVP: three values, no sheet.** Level, HP and ATK (ATK as the ladder row's pair, never the raw scale); `DEF` is omitted while it has no source (TR-PRG-016); the loadout's two rows carry the gear. The nine-stat sheet and its readout stay VS (SYS-26) — the anti-pillar's D-2 wording permits a lean accessible menu there, never a numeric spreadsheet. | TR-PRG-011; AC-PRG-11 |
| **The benchmark audit's IP-5 (GA14/GA24)** | May weapons or modules break the ±10% sustained-damage band under situational conditions? | **Modules: no — except one enumerated, bounded, placed, closable exception.** The band is infeasible on the damage axis at the baseline (one chain point = +16.7%), so the guardrail is a two-axis pair (the free band, the exchange, the no-stacking rule) and the single exception is the Warden-tier part, closed by the Gate-2 probe. Weapons keep TR-HD-034's law untouched. | TR-PRG-013/014/017; F-PRG-06/07; AC-PRG-14/34 |
| **D-ORCH-03's named consequence (the DEF axis)** | What does the gear layer do with `defense`? | **Retired from gear at MVP** — the axis is a binary at the baseline (any `defense ≥ 1` ≡ DEF 25), so it cannot express a build modifier; the defensive build is the frame axis; the take-side alternative is declined (it needs a SYS-07 pipeline stage); the revisit gate is named and owned. SYS-07's frozen text is untouched. | TR-PRG-016; AC-PRG-16; OQ-PRG-8 |

### VS record (not AC'd at MVP)

The nine-stat sheet and its readout (SYS-26) · behavioural modifiers (the VS lever) · a second drive slot (the max-law already guards it) · Elegy-013 and weapon switching (SYS-17/SYS-08) · the `inventory` namespace and its migration (SYS-17) · elements/resistances (SYS-07 OQ#15) · the DEF revisit (OQ-PRG-8) · the `attack` lever's re-examination at the VS scale (where one ladder row is a smaller percentage).

