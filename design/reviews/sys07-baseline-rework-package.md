# SYS-07 Baseline Rework — the IP-17 contract-revision package (ROUND 2)

> **Status**: **PROPOSAL — awaiting the D-ORCH-03 round-2 user decision.** No frozen
> document has been edited. `design/gdd/health-damage.md`, the registry and the
> systems index are untouched by this package; the diff in § 8 is what *would* be
> applied **after** approval, in a commit that names the decision ID.
> **Lane**: SYS-07-REWORK · **Branch**: `docs/sys07-baseline-rework` ·
> **Round**: 2 (round 1 was NOT approved — "Revise again", no objections recorded)
> **Authority**: benchmark audit **D-7 / IP-17** (`design/reviews/metroidvania-benchmark-audit.md`
> § 5a) · **D-ORCH-03** (`production/orchestration/decisions.md`)
> **Owners**: systems-designer (SYS-07) + lead-programmer; countersigns SYS-08 (one
> clause), SYS-13 (one value + the orb relation), SYS-16 (the parity + DEF inputs)
> **Gates SYS-16 and SYS-17.** **Does not** open new scope: no new system, no VS
> content, no new mechanic.

## 1. The decision, on one page

D-7 (2026-11-14, user): *"RPG stats start low (e.g., level 1 ≈ 20 HP instead of
>100) with overall in-game coherence."* IP-17: *"Re-derive the whole economy
>coherently from a low level-1 baseline (≈20 HP): strikes, tiers, boss pool, the
>F-HD bands, the identity-law fixtures (`TR-HD-006`), and the training-data
>thresholds scale together so every band relationship survives."*

**What this package asks the user to approve**, as one contract revision:

| # | Component | The change | Blast radius | Authority |
|---|---|---|---|---|
| 1 | **The baseline scale** | every *live* absolute quantity ÷5: HP 100→**20**, strikes 6/12/20→**1/2/4**, tiers 30/60/120/300→**6/12/24/60**, heal 25→**5**, thresholds 100/250/450/700→**20/50/90/140**, awards 15/35/70/200→**3/7/14/40**, HP/point 8→**2**, the Spitter's orb 8→**2** | SYS-07 (frozen) + SYS-13 (one value) | IP-17 / D-7 |
| 2 | **The weapon table + the event's arc** | ATK1/ATK2/crouch/air 10/20/8/10 → **2/4/2/2** (counters 15/30 → 3/6); **`DamageEvent` gains `arc`** (the ladder's column selector) | **SYS-08 (frozen) — two clauses** | IP-17 / D-7 |
| 3 | **The growth ladder** | the MVP percent curve is replaced by a printed 5-step damage ladder keyed on the arc + `attack`, so no training point is invisible at 20 HP | SYS-07 (frozen) | IP-17 / D-7 |
| 4 | **`TR-HD-006`'s "MVP has no gear"** | three one-clause corrections (the OQ-M1 rider pattern) — gear is MVP (D-1) | SYS-07 (frozen) | **D-1** |
| 5 | **The mana reconciliation input** | the MVP Stinger is mana-free; mana/energy stay inert and **unscaled** | recorded for SYS-12 | the systems-index SYS-12 row |
| 6 | **The ±10% parity situational-break OQ** | restated measurement + four guardrails + the Gate-2 playtest question | recorded for SYS-16 | **IP-5** (D-1's rider) |

Components 1–4 are D-ORCH-03's enumerated five (components 1 and 2 are the audit's
single "baseline rework"; the ladder is its growth limb). Components 5 and 6 are the
two *inputs* the same decision entry names — 5 is routed by the systems-index SYS-12
row, 6 by the audit's IP-5. **No component is new scope.**

Everything else in SYS-07 is unchanged: the `DamageEvent` boundary, the five-value
consumer enum, the 11-term gate, the **damage order's stage sequence** (raw → scaling
/ mitigation → crit → floor 1 → cap, plus **one new named stage** — the module modifier
after the ladder, § 3.1), **F-HD-11's counter law** (its *outputs* move, its body does
not — § 3.1), the death edge and the `DeathRecord`, the System Offline
options contract, the heal/chip/pickup laws, the i-frame consumer lock, the ms
contracts, the parity *bands*, **the `StatBlock` schema (it gains exactly one field —
`damage_bonus`, default 0, SYS-16-owned: the module stage's carrier)**, and the identity
law's *form* (level 1 + no gear = the approved numbers, exactly). **Two schemas change
beyond that field** — both in SYS-08's boundary, because the ladder's column selector
must cross it: `DamageEvent` gains `arc ∈ {ATK1, ATK2, CROUCH, AIR, ABILITY, NONE}`
(Combat stamps it at the contact from the arc it is executing — TR-CMB-025 has no arc
field today, so the ladder is otherwise unimplementable), and SYS-07's `AttackContext`
copies it (§ 8, TR-HD-037).

**The coherence invariants this package holds** (the test of "re-derived together"):

1. **TTK reproduces exactly**: T1 1 chain · T2 2 · T3 4 · boss 10; 0.617 / 1.233 /
   2.467 / 6.167 s. Unchanged from the frozen GDD.
2. **Hits-to-kill is preserved** (a *new* derivation — the frozen GDD states no such
   invariant): arc hits in a chain-based kill (ATK1 + ATK2 alternating) T1 2 · T2 4 ·
   T3 8 · boss 20.
3. **The heavy is still a fifth of the bar**: a power-3 heavy is 4/20 = 20/100.
4. **The heal is still a quarter of the bar**: 5/20 = 25/100.
5. **The module is still a half**: 50% of 20 = 10.
6. **The low-HP cue is still a quarter**: ≤ 5/20.
7. **The pit is still lethal by construction**: `raw_damage = hp_max` (now 20).
8. **The grind is unchanged in kills**: L2 = 7 T1 kills (21 ≥ 20) before and after.
9. **The level-up arc is still 4 points** across 5 levels.

## 2. Provenance — the round-1 package was not found

**Recorded honestly, per the lane instruction.** A search of this worktree, the main
checkout, every local branch (`git branch -a`, `git log --all --grep=sys07`), the
stash list, and `production/`, `design/`, `docs/` for any file matching
`rework|ip-17|baseline|sys07` found **no round-1 package artifact**. The only
SYS-07-REWORK artifacts in the repo are the lane prompt and the manifest row. The
round-1 package appears to have existed only in a prior session's conversation.

**This package is therefore reconstructed** from (a) the frozen SYS-07 GDD
(`design/gdd/health-damage.md`, read in full), (b) D-ORCH-03's five enumerated
components, (c) IP-17 / D-7 in the benchmark audit, (d) the amended MVP Definition
in `design/gdd/game-concept.md` § MVP Definition, and (e) the systems index's
SYS-07/16/17 rows. **Round 2 cannot diff against round 1**; it re-presents the
rework from first principles, with the decision points surfaced explicitly (which is
what the user asked for: *"tighten the presentation and surface the decision points"*).

## 3. The reworked baseline — the numbers

**Level 1, no gear, no points** (the identity-at-default fixtures):

| Quantity | Frozen | **Reworked** | Law |
|---|---:|---:|---|
| `PLAYER_MAX_HP` | 100 | **20** | ÷5 |
| strikes P1 / P2 / P3 | 6 / 12 / 20 | **1 / 2 / 4** | ÷5, P1/P2 rounded down (see § 4.1) |
| `ATK1_DAMAGE` / `ATK2_DAMAGE` | 10 / 20 | **2 / 4** | ÷5 exact — **SYS-08 clause** |
| `CROUCH_ATTACK_DAMAGE` / `AIR_ATTACK_DAMAGE` | 8 / 10 | **2 / 2** | ÷5, crouch rounded up (1.6→2 — R3) |
| counter ATK1 / ATK2 (raw) | 15 / 30 | **3 / 6** | `floor(move × 1.5)`, exact — the law is unchanged |
| `spitter_orb_damage` | 8 | **2** | ÷5, rounded up (1.6→2 — R4) |
| `ENEMY_HP_T1` / `T2` / `T3` | 30 / 60 / 120 | **6 / 12 / 24** | ÷5 exact |
| `BOSS_HP` | 300 | **60** | ÷5 exact (SYS-14's range 200–400 → **40–80**) |
| `HEAL_ITEM_AMOUNT` (Suture) | 25 | **5** | ÷5 exact |
| `RESTORE_MODULE_HEAL_PCT` | 0.5 | 0.5 | unchanged (10 HP at 20) |
| `LOW_HP_THRESHOLD_PCT` | 0.25 | 0.25 | unchanged (≤ 5/20) |
| `TRAINING_DATA_L2…L5` | 100 / 250 / 450 / 700 | **20 / 50 / 90 / 140** | ÷5 exact |
| `XP_T1/T2/T3`, `XP_BOSS` | 15 / 35 / 70 / 200 | **3 / 7 / 14 / 40** | ÷5 exact |
| `HP_PER_POINT` | 8 | **2** | ÷5 → 1.6, rounded up (R5) |
| `PLAYER_ATK_BASE` | 100 | 100 | unchanged (the ladder's index origin) |
| `DEF_CAP_PCT` | 25 | 25 | unchanged **— but see R10: the DEF axis collapses** |
| `ENERGY_*` / `MANA_*` | 50+10(L−1) / 30+5(L−1) | **unscaled** | the inert-data exemption (§ 6) |
| chain (ATK1+ATK2) | 30 | **6** | derived |
| `dps_chain` | 48.65 | **9.73** | derived: 6 × 60 ÷ 37 |
| 60 s integral | 2920 | **584** | derived: 97 chains + one ATK1 (97×6+2) |
| single-arc loop | 27.27 | **5.45** | derived: 2 × 60 ÷ 22 |
| chain cycle | 37 t | **37 t** | unchanged (arcs are SYS-08's, untouched) |

**The derived bands reproduce** (F-HD-10): TTK chains 1 / 2 / 4 / 10 at defaults;
TTK seconds 0.617 / 1.233 / 2.467 / 6.167 — **identical to the frozen GDD**.

**The TTK envelope is re-derived, not asserted** (F-HD-10 / AC-HD-11). Its bottom is
a *knob* value (the minimum legal chain: `ATK1_DAMAGE` 1 + `ATK2_DAMAGE` 3 = **4**); its
top is the ladder's row 4 (knob row 33's default: 4 + 6 = **10**), a *table* value
rather than a single-knob value.
Result: **T1 1–2, T2 2–3, T3 3–6, boss 6–15**. The frozen envelope was 1–2 / 2–3 /
3–6 / **8–15**; the boss's low end widens from 8 to 6 because the ladder's all-ATK
arc is +67% (the frozen +37%) — see **R6**, the boss tuning watch.

**The re-derived knob table** (÷5, re-clamped — and the honest casualties):

- `PLAYER_MAX_HP` **12–32** · `HP_PER_POINT` **1–3** · `BOSS_HP` **40–80** ·
  `HEAL_ITEM_AMOUNT` **3–7** · tiers **4–8 / 9–15 / 18–30** ·
  `TRAINING_DATA_L2…L5` **12–32 / 36–70 / 70–120 / 110–180** ·
  `XP_T1/T2/T3` **2–5 / 4–10 / 8–20** · `XP_BOSS` **20–60**.
- **The strike table has no tuning room at 20 HP.** The frozen ranges (4–8 / 9–15 /
  16–24) ÷5 and re-clamped to *disjoint* integers collapse to **P1 = 1 (fixed),
  P2 = 2–3, P3 = 4–5** — a one-value range for the light strike. V-HD-07
  (`P1 < P2 < P3`) stays **satisfied** (1 < 2 < 4), but the *tuning lever* moves: at
  MVP the strike weights are fixed at **1/2/4** and the economy is tuned through
  `PLAYER_MAX_HP` and the tier pools (R1).
- **The SYS-08 raw ranges are constrained by the ladder, not by ÷5**:
  `ATK1_DAMAGE` **1–2**, `ATK2_DAMAGE` **3–4**, `CROUCH` **1–2**, `AIR` **1–2**. The
  wider ÷5 image (1–3 / 3–6) would let row 0 collide with row 1 (ATK1 3 → chain 7 =
  row 1's 7) or let the ATK2 column *fall* (ATK2 5 → 4). The narrow ranges are what
  keeps V-HD-12's monotonicity satisfiable, and they are the reason the ranges are
  stated as a derivation rather than a ÷5 map.
- **`ATK_PER_POINT` is pinned to 8 (fixed identity)**, like `PLAYER_ATK_BASE`: it is
  the ladder's index divisor **and** the VS sheet's shared per-level step, and the
  printed 100–132 anchors depend on it. It stops being a tunable knob (R7) — the
  reason is the anchors and OQ#20's handoff, not a claim that other values break the
  table (the ladder is scale-invariant in a *shared* divisor).
- **Knob row 33 — `DAMAGE_LADDER_MVP`**: default the § 3.1 table (a quoted 5×4 string);
  safe range "authored — validated by V-HD-12"; extreme behavior "a non-monotone or
  row-0-divergent table is a dev boot failure"; interactions: the four raw knobs (row 0),
  `ATK_PER_POINT` (the index), the counter law (F-HD-11 reads `raw_damage`, not the
  table); rule: F-HD-14.
- **The ladder itself is knob row 33** (`DAMAGE_LADDER_MVP`, § 3.1), so the
  named-symbol law keeps one home for the values.

### 3.1 The growth ladder (component 3 — the reason for it)

At 20 HP the frozen percent curve (`dealt = ceil(raw × attack ÷ 100)`, +8 attack per
point) **stops resolving**: ATK1 goes 2 → 3 → 3 → 3 → 3 and ATK2 4 → 5 → 5 → 5 → 6,
so **training points 2 and 3 change no number at all** and the chain is 6, 8, 8, 8, 9.
The frozen GDD's own promise ("the sheet is a promise, not a spreadsheet"; a point is
"a choice you make") and AC-HD-48 (growth felt) fail at two of the four MVP points.

The rework replaces the MVP branch of **F-HD-14** with a printed ladder, keyed on the
**arc** and the **attack** stat (**no new field for the ladder itself** — the module
stage's `damage_bonus` is the one schema addition, § 8 / TR-HD-037; `AttackContext`
gains the arc):

`step(attack) = clamp(floor((attack − PLAYER_ATK_BASE) ÷ ATK_PER_POINT), 0, 4)` — **scoped to
`attack ≤ 132`** (the points cap); above it the VS sheet governs (OQ#20), so the clamp's
"hold row 4" is a defined MVP behaviour, not a pre-emption of SYS-16's choice.

**The dispatch is total over the frozen event space** (F-HD-02 was total; the ladder
must not narrow it):

**The dispatch replaces one stage, not the pipeline.** The frozen order is `raw →
attack scaling (dealt) OR defense mitigation (taken) → crit → floor 1 → cap`; the
ladder replaces **only the player's weapon-arc `dealt`**. Every other stage is
untouched. **A pre-dispatch event check runs after the zero branch**: a `NORMAL` or `COUNTER`
event with `arc = NONE` is **rejected** — dev assert + a named telemetry reason in
production (the same clamp-and-log resolution as V-HD; the GDD's own law: *"dev
asserts … production keeps the last good config"*). It runs *after* branch 1, so a
**0-damage event with `arc = NONE` stays legal** (TR-HD-004's "0 is legal"; the Edge
Case *"a 0-damage event arrives → legal"*). The config-load assert covers the ladder's
**structure** only (monotone columns, row 0 = the four knobs). Then:

1. `dealt = 0 if raw_damage = 0` (the zero branch precedes everything).
2. `else if kind = NORMAL ∧ arc ∈ {ATK1, ATK2, CROUCH, AIR}` → `dealt = DAMAGE_LADDER_MVP[step][arc]`
   (the player's four weapon arcs). **The ladder is followed by one named modifier stage
   — branch 2 only** — `dealt = max(1, dealt + stat_block.damage_bonus)` (F-HD-02's
   stage, reading the `StatBlock` field TR-HD-037 adds): **0 at no gear** (the identity
   law holds) and the transport D-1's Chassis Modules need (§ 5a: `defense` is inert at
   this scale, so the module's build modifier lands here or on the gear-aggregated
   `attack`/`hp_max`). The stage sits *after* the ladder and *before* crit → floor 1 →
   cap, and it does **not** touch the counter, ability, deflect, `ENEMY_STRIKE` or
   `ENVIRONMENT` branches.
3. `else if kind ∈ {COUNTER} ∨ (kind = NORMAL ∧ arc = ABILITY)` → **the frozen percent
   law on the event's raw**: `dealt = max(1, ceil(raw_damage × attack ÷ 100))`. For a
   counter this *is* F-HD-11's body verbatim — Combat stamps `raw_damage =
   floor(ATK.damage × COUNTER_CLASH_MULT)` at the contact (F-CMB-06), so SYS-07 must not
   re-apply the multiplier (its 1.2–2.0 range would double-count). For an ability it is
   D-3's Stinger cell (§ 6).
4. `else if kind = DEFLECT` → **the projectile's raw** (F-CMB-10 / TR-CMB-015: *"its
   damage is the projectile's original damage"*), through the frozen percent law. This
   is the explicit resolution of F-HD-02's kind-blind `dealt` — pinned in AC-HD-13 /
   AC-CMB-17 at a **non-default** attack, so the branch is not accidentally the identity.
5. `else if kind = ENEMY_STRIKE` → **F-HD-03's `taken`** (the player's defense) — never
   the ladder, never the dealt law.
6. `else if kind = ENVIRONMENT` → **the TR-HD-018 bypass**: `taken = raw_damage` (no
   DEF, no i-frame lock), *then* F-HD-04's cap/floor still apply (TR-HD-018 bypasses the
   defense and the i-frame lock, **not** the profile's `damage_cap_per_event` /
   `hp_floor`) — the pit stays `raw = hp_max` at **any** attack build.
7. `else` → **reject with telemetry** (a kind outside the five-value enum cannot reach
   here — TR-HD-017's term 4 already rejects it — so this is the belt-and-braces
   terminal arm; `dealt` is never left unassigned).

| step (`attack`) | ATK1 | ATK2 | crouch | air | **chain** (derived) | boss chains |
|---:|---:|---:|---:|---:|---:|---:|
| 0 (100) | 2 | 4 | 2 | 2 | **6** | 10 |
| 1 (108) | 3 | 4 | 2 | 3 | **7** | 9 |
| 2 (116) | 3 | 5 | 3 | 3 | **8** | 8 |
| 3 (124) | 4 | 5 | 3 | 3 | **9** | 7 |
| 4 (132) | 4 | 6 | 3 | 4 | **10** | 6 |

**The table is authored, not derived** (the percent law is the VS law, F-HD-02). Each
point moves 2–4 printed numbers (a move, sometimes a second move, the chain, the boss
TTK), so **no point is flat**. **The knob stores all five rows; row 0 is *validated*
against the four raw knobs** at config load (a disagreement is a boot failure — it is
not re-derived, so a live knob edit *fails validation*, it does not silently rewrite
authored data). Its validation extends **V-HD-12** (no new invariant, no count change):
every column is monotone non-decreasing, the chain column is strictly increasing, and
row 0 equals the four raw knobs exactly **and row 4's chain is ≤ 10** (the envelope's
top, so a legal live edit cannot widen AC-HD-11's 4–10). **The knob stores the four move cells; the
chain column is derived** (`ATK1 + ATK2`, F-HD-10's law) and validated per row, not
stored — so a clamp moves cells and the chain re-derives. **A live edit resolves by
case**: a broken row-0 equality or a row-4 chain > 10 is *rejected* (the last good
config is kept); a non-monotone **ATK2** column or a non-strictly-increasing chain is
*accepted clamped* — the offending row's ATK2 cell rises by one and all four checks
re-run, a residual violation rejecting the edit; the **ATK1/crouch/air** columns are
never clamped — a live edit that breaks one of them is rejected.

**The counter is deliberately not on the ladder** — F-HD-11's *body* is untouched, so
there is still one owner for the number: Combat stamps `raw_damage =
floor(ATK.damage × COUNTER_CLASH_MULT)` (→ 3 / 6), then `dealt_counter = max(1, ceil(raw_counter × attack ÷ 100))`
→ ATK1 **3/4/4/4/4** and ATK2 **6/7/7/8/8** across the five steps. The counter grows
more slowly than the chain, exactly as the frozen GDD intends (*"the reward is the
stagger + the denied strike, not a damage shortcut"*).

**The L5→L6 handoff is not solved here — it is delegated, with a requirement.** Above
`attack` 132 (the points cap) the VS sheet's law governs — and the frozen VS curve
(`attack = 100 + 6×(L−1)`) gives **130 at L6**, i.e. the *stat itself falls* below the
points cap before the law changes. So **the VS sheet must be monotonic against the
ladder's top row in both the stat and the dealt value** (the frozen percent law at
`attack` 140 would give ATK1 3 < the ladder's 4, so the naive handoff *lowers*
damage). The candidate repair — carrying row 4 through the percent law
(`ceil(4 × attack ÷ 132)`) — is recorded in the new OQ for SYS-16, not applied as an
untestable MVP branch (R11).

**Worked examples (they land in the existing ACs — AC-HD-07 and AC-HD-13 — not in new
ones; the counts are unchanged):**

- **All-in ATK (4 points)** → ATK1 4 / ATK2 6 / chain 10 / boss 6 chains (3.70 s);
  T3 3 chains (1.85 s). **The arc is +67% chain** (vs the frozen +37%).
- **All-in HP (4 points)** → max HP 28, ATK 100 (ATK1 2 / chain 6); a power-3 heavy
  takes 7 hits (vs 5 at the no-points baseline; the frozen all-HP build also took 7).
- **The 2/2 split** → max HP 24, ATK1 3 / ATK2 5 / chain 8.
- **A Suture at 18/20** → 2 applied, 3 discarded, one charge spent (the frozen
  90/100 case, ÷5).
- **A revive at 28 max** → ceil(28 × 0.5) = **14**.
- **The pit at 8/20** → `raw_damage = hp_max = 20` → hp 0, overkill 12, the edge
  fires once; SYS-29's ratio 12/20 = **0.60 → MID (inclusive)** — the exact mirror of
  the frozen 40/100 case. At 7/20 → 13/20 = **0.65 → HIGH** (the boundary pair).

## 4. The three decision points inside the package

Round 1's failure mode is not recorded, so round 2 names every axis on which a
reviewer could disagree. **The recommendation is the bundle in § 12 (Option A).**

### 4.1 Axis P — the pool size (how low is "low")

| | Pool | Strikes | Exact ratios? | Note |
|---|---:|---|---|---|
| **P1 (recommended)** | **20** | 1 / 2 / 4 | P3 exact (20% of the bar); P1/P2 round down | D-7's own number |
| P2 | 25 | 2 / 3 / 5 | P1 rounds up | "≈20" strained |
| P3 | 50 | 3 / 6 / 10 | **all exact** (the frozen ratios ÷2) | only half of D-7's intent |

**What P1 actually costs — stated correctly** (round 1's framing had this backwards):
rounding 1.2 → 1 and 2.4 → 2 makes the light and mid strikes *relatively **lighter***,
not heavier — a power-1 hit is 5% of the bar (frozen 6%) and a power-2 is 10% (frozen
12%). So light chip is *more survivable* (20 hits to kill instead of 16.7; 10 instead
of 8.3), and the heavy keeps its exact 20%. **The real trade is the spread**: the
ladder P1:P2:P3 goes from 1:2:3.33 to **1:2:4** — heavies are relatively heavier and
the light strike loses some of its bite. That is the axis-P question, and it is a
*design* shift, not an error: a low baseline where the heavy is the readable threat
and chip is survivable reads well against "HP is a resource you learn". P3 buys exact
ratios at the price of the whole point of D-7.

### 4.2 Axis S — does SYS-08's weapon table move?

| | Mechanism | Frozen contracts touched | Consequence |
|---|---|---|---|
| **S2 (recommended)** | the weapon table rescales to 2/4/2/2, and `DamageEvent` gains the `arc` the ladder reads | SYS-07 + **SYS-08** (two clauses: TR-CMB-004's damage column + four knobs + their safe ranges; and TR-CMB-025's event schema + AC-CMB-30) | **one scale everywhere**; symbol-anchored band boundaries move with the table |
| S1 | SYS-07 applies a hidden `DAMAGE_SCALE = 5` divisor to Combat's raw 10/20/8/10 | SYS-07 only | two scales in the corpus; **SYS-04's three damage bands collapse to one** (§ 9) |

**S2 is what the corpus already expects.** `design/gdd/audio-core.md` F-AUD-03 says,
of `ATK1_DAMAGE`/`ATK2_DAMAGE`: *"never literals, so the **SYS-07-REWORK
re-derivation moves the bands with the arcs**."* Its **band boundaries** are
symbol-anchored (`BAND_2_MIN = ATK1_DAMAGE`, `BAND_3_MIN = ATK2_DAMAGE`), so they move
with the table automatically; its **printed examples** (8→B1 … 30→B3) are literals and
need re-deriving on the new arcs (a § 9 rider). Under S1 the symbols stay at 10/20
while every published amount is 1–4 → all damage ticks land in band 1 and the
three-band language dies at MVP. (Under S2 the *player-dealt* amounts 2–8 occupy
bands 2–3; band 1 survives through the **received** power-1 strike (1) — the three-band
language holds, with a narrower spread than the frozen design.)

S2's price: **the user is approving a one-clause revision of two frozen contracts in
one decision** (SYS-07 and SYS-08). That is recorded as part of the decision, not as
a surprise.

### 4.3 Axis G — the growth curve

| | Mechanism | Every point felt? | Frozen diff |
|---|---|---|---|
| **G2 (recommended)** | the printed ladder (§ 3.1), keyed on the arc + `attack`; the percent law becomes the VS law | **yes** | F-HD-14's MVP branch + F-HD-02's scope + TR-HD-006's fixture list + `AttackContext`'s arc field |
| G1 | keep the percent curve (ATK 100→132, +8/point) | **no** — points 2 and 3 are invisible | smaller diff |

G1 is the smaller diff and the honest "no new formula" choice, but it ships a GDD
whose own growth promise fails at half the MVP points. G2 is a *table*, not a new
mechanic, and it is the only option where AC-HD-48's "a felt change after the first
point" holds for **every** point.

## 5. The `TR-HD-006` correction (component 4 — the OQ-M1 rider pattern)

D-1 (2026-11-14, user) overturned "MVP has no gear". Three clauses of the frozen GDD
now contradict it. The correction is **three one-clause riders**, each written into
the GDD at the approved diff with a dated parenthetical naming **D-1** and
**D-ORCH-03** — never a silent rewrite, never a reopened review loop.

**5a. TR-HD-006, the gear clause.** Frozen: *"**MVP has no gear**: `defense` is a VS
stat (the formula supports it; no MVP source produces it)."* →
*"**MVP has gear (D-1, 2026-11-14)**: SYS-16/SYS-17 author the deterministic named
Chassis Modules and the two-slot loadout; `defense` gains its first MVP source at
SYS-16 authoring. The identity-at-default law is unchanged — level 1 with no modules
returns the approved numbers exactly — and `DEF_CAP_PCT` 25 binds at MVP — **enforced at
the resolver, though not observable at raw 1–4** (R10: **any `defense ≥ 1`** yields the
same taken values, 1/1/3, as `defense 25`). So a module's build modifier must not rely
on `defense` as its lever — SYS-16's input. **The levers are `StatBlock.damage_bonus`**
(F-HD-02's post-ladder stage), **the gear-aggregated `attack`/`hp_max`** (their own
fields), **and behavioural modifiers** — all 0 at no gear, so the identity law holds.
The DEF formula (F-HD-03) is implemented
and unit-tested at DEF 0/5/25 now (AC-HD-14's three fixtures), and at the
module-produced values when SYS-16 lands."* Its test clause changes from *"every
approved Combat fixture passes unmodified … no MVP item produces DEF"* to *"the
reworked Combat fixtures pass unmodified at level 1/no modules; a module-produced DEF
is legal at MVP; DEF clamps at 25"*.

**5b. F-HD-03's scope note.** Frozen: *"At MVP no source produces DEF (gear is VS);
the formula is implemented and unit-tested at DEF 5/25 for the VS sheet."* → the same
rider: DEF 0/5/25 remain the unit-test points, and the MVP source is the module layer.

**5c. TR-HD-033, the inventory boundary.** Frozen: *"SYS-17 owns item definitions,
the full inventory screen, stacks, equipment and the assignable quick slot (VS)"* →
*"equipment (the two-slot loadout) is **MVP** (D-1); the full inventory screen,
stacks and the assignable quick slot remain VS."* **And the Interactions table's
`StatBlock` consumer cell** — *"SYS-16: the full sheet, levels 6–20, gear aggregation
(VS)"* → *"gear aggregation (**MVP — D-1**); the nine-stat sheet remains VS"* (the
fourth site; without it the doc asserts gear is MVP and that gear aggregation is VS in
the same table).

**Not corrected here** (owned elsewhere, recorded so it is not lost): SYS-17's GDD
does not exist yet, so the carve-out wording is authored fresh at SYS-17; the
systems-index SYS-07 row's "player 100 HP" is the sync lane's edit.

## 6. The mana reconciliation input (component 5 — for SYS-12)

The systems index (SYS-12 row) routes this here: *"SYS-12's authoring either keeps
the MVP Stinger mana-free (the VS mapping stands) or gives mana an MVP consumer
(re-routes to the SYS-07 baseline-rework session, IP-17)."* D-3 promoted the Stinger
to MVP, so mana *could* have an MVP consumer for the first time.

| | Decision | Consequences |
|---|---|---|
| **M1 (recommended)** | **the MVP Stinger is mana-free.** Its cost is its commitment (the quarter-spin gesture + the body arc), not a resource. Mana stays inert saved data; TR-HD-008's *"neither pool appears on the HUD at MVP"* stands verbatim. | SYS-12: no mana cost, no meter, no new SYS-24 work; the Stinger's lever is arc + commitment. **It declares `kind = NORMAL, arc = ABILITY`** when its damage lands — Combat publishes
the event (§ 3.1's branch 3, TR-HD-001's rider), the schema now has the cell. TR-HD-008/009 take a one-line rider (§ 8) because *"mana → the Stinger, SYS-12 (VS)"* still reads as though the Stinger were VS. |
| M2 | mana becomes the Stinger's MVP cost | mana must scale (6 + 1×(L−1) = **6 / 10**) and the `soul_class` payoff must scale — but `CYBORG` 2 ÷5 = 0 **collides with `MACHINE` 0**, so the matrix collapses to **2 / 1 / 0 / 0** (demonic/human/cyborg/machine) and the cyborg's payoff dies; TR-HD-008's HUD clause is revised; **SYS-24 gains a mana meter** (a third contract touch). |

**And either way: the inert pools are NOT scaled by the /5 law.** This is the
**inert-data exemption**, and it is a real clause: `energy_max` and `mana_max` are not
numbers the player ever reads at MVP; they are saved data whose consumers and sheet
are VS. Scaling them now would force SYS-16's VS sheet to rescale them again — the
exact SYS-07 ↔ SYS-16 cycle the StatBlock split exists to prevent. Recorded as:
*"the /5 law applies to live quantities (HP, damage, tiers, thresholds, awards, the
heal); the inert pools are VS data and keep their VS scale."* (M2 is therefore the
*more* expensive path: it makes mana live, and a live pool must scale.)

## 7. The ±10% parity situational-break OQ (component 6 — the SYS-16 input)

The audit's question (IP-5, D-1's rider): *may weapons break the sustained-damage
band under situational conditions (epoch scaling, counter-window multipliers)?*

**The low baseline changes the arithmetic of the law itself.** At chain 6, one
integer damage step is **+16.7%** — larger than the ±10% band. So the per-chain dps
comparison usually cannot express the band at MVP (a different *cycle length* can
still land inside it — chain 7 over 43 t = 9.77 dps is +0.4% — but that is a
coincidence of the arc timings, not a usable design surface). The rework's input to
SYS-16:

**7a. The restated measurement (TR-HD-034 / F-HD-13 / V-HD-14).** All three frozen
bands are addressed, not two:

| Band | Frozen | At MVP |
|---|---|---|
| sustained (per-chain `dps_chain`) | ±10% | **unmeasurable per-chain** (one step = +16.7%): reported as a diagnostic with a **±1 integer step** tolerance |
| sustained (60 s integral) | — (a derived check) | **the binding measurement**: ±10% of **584** → [526, 642] |
| single-arc loop | ±10% | **unmeasurable at MVP** (5.45; one step = **+50.0%**, ATK2 +25%): binds at VS |
| TTK across the three archetypes | ±15% | **the second binding measurement**, unchanged |

The **bands themselves are unchanged** (10 / 10 / 15); only the *measurement surface*
moves, and only because integer steps exceed the band. At MVP one weapon ships
(Dirge), so the law has a single instance; it binds at VS where Elegy's table is
authored on the new baseline.

**7b. The four guardrails (SYS-16's authoring constraints).**

1. **The counter never enters the parity measurement.** The counter is a producer law
   (1.5× of the struck weapon's *own* damage), so it is symmetric by construction. A
   weapon whose *counter* is asymmetric must declare the counter as a trade axis.
2. **Epoch scaling applies to the dummy and the world, never to a weapon's table.**
   A weapon is measured at epoch 0 and re-measured at epoch 1; a weapon that breaks
   the band only post-flip declares the epoch as a trade axis.
3. **A situational break must be declared, bounded and self-clearing**:
   `situational_band ≤ +25%` sustained, over `≤ 2 s`, returning to the band outside
   the window. Undeclared breaks are a flag, not a tuning note (V-HD-14).
4. **The Warden-tier module (D-1) may break the band only inside its declared
   window** — the module's build modifier is a *situational* source, and its window is
   authored at SYS-16 with the module, not retro-fitted to the law.

**7c. The playtest question (Gate 2).** *"When a weapon (or a module) exceeds the
band inside a named window, does the player read it as a reward or as a broken
promise?"* — coded in the Gate-2 session script (the gear-beat probe, game-concept
§ MVP Definition), owner **SYS-16 + qa-lead**. Because game-concept currently
enumerates exactly **four** Gate-2 probes, the fifth is added through the **sync
request** (§ 10) so the playtest contract stays single-sourced. If it reads as a
broken promise, the window closes and the band is absolute; that is a design call at
Gate 2, not now.

## 8. The exact diff (what the application commit would contain)

**File**: `design/gdd/health-damage.md` — the only frozen document **whose diff is
printed here** (SYS-08, SYS-13 and SYS-02 take one-clause riders, § 9).

**The completeness test is a sweep plus an exclusion set** — the sweep alone would
fire on correct clauses:

- **Sweep** for the frozen absolutes, **matched on non-digit boundaries** (so `10`
  does not hit `10,000`, `6` does not hit `60`/`600`, `12` does not hit `1200`), and
  including the derived outputs that must move: **5 · 6 · 8 · 10 · 12 · 14 · 15 · 17 ·
  18 · 19 · 20 · 25 · 27 · 28 · 30 · 33 · 35 · 38 · 40 · 41 · 48.65 · 52.17 · 60 · 70 ·
  100 · 116 · 120 · 130 · 132 · 140 · 200 · 250 · 252 · 300 · 366 · 450 · 700 · 2920 ·
  3120**.
- **Exclusions** (must NOT change): the `÷ 100` normalization in F-HD-02/03/11/14; the
  **attack axis itself** (`PLAYER_ATK_BASE` 100, `ATK_PER_POINT` **+8**, the 100–132
  span, "4 ATK points → ATK 132", the VS cap **214**); `DEF_CAP_PCT` **25** and its
  `= 100` clamp fixture, **`0.25` as TR-HD-038/AC-HD-41's p99.9 tick budget** (ms, not
  an economy value),
  `LOW_HP_THRESHOLD_PCT` 0.25 (and the Visual/Audio "low-HP cue at ≤ 25%" — a
  *percentage*, not a pool value), `LEVEL_CAP_MVP` **5** and the DEF 0/5/25 fixtures;
  the unchanged ms/tick durations (`700` lifetime, `150` chip, `700` getup, `500`
  stagger, `1000` revive, **getup i-frame 300**, **F-HD-12's `300 + 1200` follow-up
  arithmetic**, `60` ticks, the 60 s integral's window, the 8-tick backdash exposure);
  the `soul_class` payoff matrix **12 / 6 / 2 / 0** (unchanged under M1); the *"≤ 6
  chars"* label rule; **TR-HD-013 / F-HD-04's "20 into 8 → hp 0, overkill 12" and the
  overkill-12 edge bullet** (they are the *same* overkill arithmetic the reworked
  8/20 case reproduces — the literal 20 and 12 are the pit's payload and its overkill,
  not the pool and a strike); AC-HD-04's integer-validity fixtures (`12`, `12.5` — they
  test the gate, not the economy); **AC-HD-44…48's "5 playtesters × 30 min" and
  "≥ 3/5"** (cohort sizes, not economy); **the pit's `raw_damage = hp_max`** (its value
  is the *symbol*, not the literal); **the VS level caps — "levels 6–20"** (a level range, not
  an economy value); **TR-HD-008's `max(70, 100 − 2×(L−1))%`** (the inert pools'
  efficiency curve — part of the inert-data exemption); **"Fixed 60 tps"** (the tick
  rate, not an economy value); and the **inert pools** (`energy` 50/90, `mana` 30/50).
- **Rule**: the clause rows above are the **completeness proof**; the sweep is the
  tripwire that finds an *unlisted* copy. A swept hit that is neither listed in a
  clause row nor in the exclusion set is a blocker at the application gate.

| Clause | From | To |
|---|---|---|
| Header — Status / Last Updated / **Last Verified** / Counts / Contracts | APPROVED 2026-11-12; *"Last Verified 2026-11-12 (… 19/19 claims …)"*; 19 OQs; **32 knob rows**; **the Contracts line's `DamageEvent {source, target, raw_damage, kind, contact_tick}` (TR-CMB-025)** | + *"revised 2026-<date> by **D-ORCH-03** (the IP-17 low-stat baseline rework); re-verified by the application run's qa-lead spot-check"*; **20 OQ rows**; **33 knob rows**; **the Contracts-line tuple gains `arc`** (the third printed copy — § 9's SYS-08 rider) |
| Header **Scope** line | *"…elements, crit, agility and **gear** are VS-gated"* | *"…elements, crit and agility are VS-gated; **gear is MVP (D-1)**"* |
| **`## Overview`** (prose) | *"applies the damage pipeline (`raw → attack scaling (dealt) or defense mitigation (taken) → crit (dealt, NORMAL only) → floor → cap`)"* — **the fourth copy of the order, and the one an implementer reads first** | the six-stage string: *"`raw → ladder / percent law (dealt) or F-HD-03 (taken) → module modifier (weapon arcs) → crit → floor → cap`"* |
| **Player Fantasy — term 4** | ATK1 10 / ATK2 20 / crouch 8 / air 10 / counter 15/30 / strikes 6/12/20 / tiers 30/60/120 | **2 / 4 / 2 / 2 / 3·6 / 1·2·4 / tiers 6·12·24** (the boss's 60 is SYS-14's and is named separately, as now) |
| **Player Fantasy — the three anchor moments + the success signature** | *"The number **12** rises … the bar loses a little more than a tenth"* · *"a power-3 heavy — **20**, overkill 4"* · *"you are at 18 … take the 25 back"* · *"I saw the 20 and knew I was in trouble"* | **prose re-derived, not number-swapped**: *"the number **2** rises … the bar loses exactly a tenth"* (2/20) · *"**4**, overkill 1"* · *"you are at **4** … take the **5** back"* (18/5 = 3.6, rounded to the readable 4) · *"I saw the **4**"* |
| **TR-HD-003** | power 1→6, 2→12, 3→20; test "6/12/20" | **1 / 2 / 4** |
| **TR-HD-005** (body **and** test clause) | body: *"`raw_damage` … → attack scaling (dealt) or defense mitigation (taken) → crit (dealt, `kind = NORMAL` only) → floor 1 → profile cap"*; test: *"the ATK2 counter is 30 at level 1 / ATK 100 and 40 at ATK 132"* | body → **"`raw_damage` → ladder / percent law (dealt) or F-HD-03 (taken) → **module modifier (the player's weapon-arc branch only)** → crit → floor 1 → cap"** (the new stage gets its law); test → **6 at ATK 100 and 8 at ATK 132** |
| **TR-HD-006** | identity fixtures 10/20/8/10/15·30/6·12·20/30·60·120; "MVP has no gear"; test "every approved Combat fixture passes unmodified … no MVP item produces DEF" | **2/4/2/2/3·6/1·2·4/6·12·24** (tiers only — the boss's 60 is SYS-14's, as frozen); the 5a rider + its test restatement |
| **TR-HD-007** | thresholds 100/250/450/700; awards 15/35/70/200; **+8 attack or +8 max HP**; test *"4 ATK points → ATK 132, ATK1 14, chain 41; 4 HP points → max HP 132; a 2/2 split → 116/116"* | **20/50/90/140**; **3/7/14/40**; **+8 attack (unchanged — it is the ladder's index step) or +2 max HP**; test → *"4 ATK points → ATK 132, ATK1 4, ATK2 6, chain 10; 4 HP points → max HP 28; a 2/2 split → 116/24"* |
| **TR-HD-008 / TR-HD-009** | *"mana → the Stinger, SYS-12"* (VS); the Dependencies bullet *"SYS-12 Stinger (VS): the mana consumer"* | + the M1 rider: *"mana → the Stinger (SYS-12, **MVP** — D-3); the pool stays inert and HUD-invisible at MVP (M1)"* |
| **TR-HD-010** | `PLAYER_MAX_HP = 100`; test "boot HP 100" | **20** |
| **TR-HD-011** | T1 30 / T2 60 / T3 120 / boss 300; "1/2/4/10 chains of 30"; **test: "the TTK envelope at the chain-damage extremes (20–41): T1 1–2, T2 2–3, T3 3–6, boss 8–15 chains"**; the SYS-14 range 200–400 | **6 / 12 / 24 / 60**; "chains of **6**" (still exact); test → **"the envelope at the extremes (4–10): T1 1–2, T2 2–3, T3 3–6, boss 6–15"**; range **40–80** |
| **TR-HD-021** (test clause) | *"a 30 hit with cap 10 applies 10"* | **"a 6 hit with cap 2 applies 2"** |
| **TR-HD-029** (test clause) | *"heal 25 at 90/100 → 10 applied, 15 discarded"* | **5 at 18/20 → 2 applied, 3 discarded** |
| **TR-HD-030 / 032** | Suture 25; `CACHE_REFILL` 3 | **5**; 3 (unchanged) |
| **TR-HD-033** | equipment "(VS)" | the 5c rider |
| **TR-HD-034** | the parity law per-chain; Dirge's arc table damage column (10/20/8/10); **Elegy-013's whole table (300/100/400 · 36 · p3; crouch 20; air 24; 52.17 dmg/s; +7.2%)**; 48.65 / 2920 / 27.27 | the 7a restatement; **2/4/2/2**; **Elegy struck to OQ#14** (VS, PROVISIONAL — its ÷5 image is 5/7/4/5 → chain 12 → 10.43, **+7.2% preserved**); **9.73 / 584 / 5.45** |
| **TR-HD-035** | `hp_ratio`/`low_hp` fixtures 25/100, 26/100, 33/132 | **5/20 (low), 6/20 (not), 7/28 (low, exactly 0.25)** |
| **TR-HD-001** | *"SYS-07 consumes `DamageEvent` from Combat and `ENVIRONMENT` events from SYS-02/SYS-15"* | **+ the `ABILITY` publisher is named**: Combat publishes the Stinger's event (IP-15's SYS-08 behavior integration — *"integrate the Stinger's behavior in SYS-08's arcs"*), stamped `kind = NORMAL, arc = ABILITY`; SYS-12 authors the ability, Combat owns the arc, SYS-07 resolves it (§ 3.1's branch 3) |
| **TR-HD-037** | `AttackContext {attacker_id, target_id, raw_damage, kind, contact_tick, attack}` | **+ `arc ∈ {ATK1, ATK2, CROUCH, AIR, ABILITY, NONE}`** (copied from `DamageEvent.arc` — the raw values collide at row 0, so `raw_damage` cannot disambiguate; `ABILITY` carries D-3's Stinger, `NONE` the non-arc sources, § 3.1's dispatch); `StatBlock` **gains one field — `damage_bonus` (int ≥ 0, default 0, SYS-16-owned)** — the carrier the module stage reads; the frozen *"a `StatRevision` bumps exactly once per point spend or equipment change"* already covers it (attack/hp_max aggregate gear through their own fields, so no second module term is needed); **`DAMAGE_LADDER_MVP` is an injected resolver input** (so AC-HD-13's five-step fixtures run against a pure `DamageResolver` with no global state); **the `arc` position in the tuple is pinned once — `(source, target, raw_damage, kind, arc, contact_tick)`**; the zero branch precedes the lookup; a `NORMAL`/`COUNTER` with `arc = NONE` is **rejected at dispatch** with a named telemetry reason (dev assert — a runtime event cannot exist at boot); **at VS, `arc = ABILITY` rides `kind = NORMAL` and is therefore crit-eligible under TR-HD-005 — an explicit VS consequence for SYS-16/SYS-12** |
| **F-HD-09** | `key = (source, target, raw_damage, kind, contact_tick)` — **printed three times: the header Contracts line, TR-HD-016, and F-HD-09's body** | **+ `arc` in all three copies** — at row 0 the four arcs all stamp raw 2, so a same-tick ATK1 + crouch pair would be rejected as a duplicate without it; the example gains it and is re-derived: `(enemy 7, player, 2, ENEMY_STRIKE, NONE, 4000)` (a reachable power-2 strike) |
| **TR-HD-039** | counts 39 / 15 / 50 / 68 / **19 OQs** | 39 / 15 / 50 / 68 / **20 OQs** (the new OQ) |
| **F-HD-01** | output 6/12/20; "8.3 hits from 100" | **1/2/4**; **"10 hits from 20"** |
| **F-HD-02** | outputs at ATK 100/108/116/124/132; **Example: "ATK2 20 at ATK 132 → ceil(26.4) = 27; a chain = 41; T3 120 dies in 3 chains (123)"** | the MVP branch reads the **ladder** (§ 3.1); **the percent law is scoped to VS, the `arc = ABILITY` branch and the `DEFLECT` branch — explicitly *not* `ENEMY_STRIKE` (F-HD-03's `taken`) or `ENVIRONMENT` (the TR-HD-018 bypass)**; the zero branch restated; **the five-step outputs are the ladder's columns — ATK1 2/3/3/4/4 · ATK2 4/4/5/5/6 · crouch 2/2/3/3/3 · air 2/3/3/3/4**; **the module stage is added** (`max(1, dealt + stat_block.damage_bonus)`); Example → **"ATK2 6 at ATK 132; a chain = 10; T3 24 dies in 3 chains (30)"** |
| **F-HD-03** | DEF 0/5/25 → 6/12/20, 5/11/19, 4/9/15 | **1/2/4 · 1/1/3 · 1/1/3** (the DEF collapse, R10); the floor 1 keeps the **light** hit readable; the 5b rider |
| **F-HD-06** | heal 25 at 90/100; revive 66 at 132 | **5 at 18/20**; **14 at 28** |
| **F-HD-07** | 25/100, 26/100, 33/132 | **5/20, 6/20, 7/28** |
| **F-HD-08** | *"reconstruct at 132 max → 132 HP"* | **28 → 28** |
| **F-HD-10** | **Output header "at defaults (chain 30 / 37 ticks)"**; defaults 1/2/4/10; envelope chain 20–41 | **"at defaults (chain 6 / 37 ticks)"**; the TTK results unchanged (1/2/4/10; 0.617/1.233/2.467/6.167 s); envelope **4–10** (knob floor / table top) → 1–2 / 2–3 / 3–6 / 6–15 |
| **Formula ledger** (the Constants-consumed column) | F-HD-02 lists `PLAYER_ATK_BASE`, `ATK_PER_POINT`, `CRIT_MULT`; F-HD-14 lists `ATK_PER_POINT`, `HP_PER_POINT` | **both gain `DAMAGE_LADDER_MVP`; F-HD-02 gains `StatBlock.damage_bonus`** (a *field*, not a constant — default 0, SYS-16-owned), so the named-symbol law has no formula reading an unregistered symbol |
| **STRIKE_DMG_P1/P2/P3 · HEAL_ITEM_AMOUNT · XP_T1/T2/T3 · XP_BOSS · HP_PER_POINT · PLAYER_MAX_HP · TRAINING_DATA_L2…L5 · ENEMY_HP_T1/T2/T3 · BOSS_HP** (extreme cells) | *"<4: chip damage"* · *"<15: the charge is a bandage"* · *"<8: a zone over-levels"* / *">100: a zone under-levels"* · *"<100"* / *">300"* · *"<4: points feel flat"* / *">12: the pool inflates"* · *"<60"* / *">160"* · *"<60"* / *">160"* (L2; L3–L5 the same ÷5) · *"off-ladder"* (scale-free) · *"<200"* / *">400"* | **"1 is the floor — no lower value is legal"** (P1) · *"<3"* / *">7"* · *"<2"* / *">20"* · *"<20"* / *">60"* · **"1: the point is a 5% pool step"** / *">3"* · *"≤ 8: two heavies kill"* / *">32"* · *"<12"* / *">32"* (L2), **"<36" / ">70" (L3) · "<70" / ">120" (L4) · "<110" / ">180" (L5)** · **"off-ladder" (unchanged — the cell is scale-free)** · *"<40"* / *">80"* — **this row is the single home for the extreme cells; the knob-table row does not repeat them** |
| **Provisional lifetimes** | *"`ATK_PER_POINT` … (playtest)"* | **struck** — the same diff pins it to 8 (fixed identity) |
| **F-HD-11** | **Output** *"ATK1 15 / ATK2 30 at ATK 100; ATK1 20 / ATK2 40 at ATK 132"*; **Example** *"the ATK2 counter equals a full chain's 30"* | **the body is unchanged**; Output → **ATK1 3 / ATK2 6 at ATK 100; ATK1 4 / ATK2 8 at ATK 132** (the five-step 3/4/4/4/4 and 6/7/7/8/8); Example → *"a full chain's **6**"* |
| **F-HD-13** | Dirge 48.65 / 2920 / 27.27; Elegy 52.17 (+7.2%) | **9.73 / 584 / 5.45**; Elegy → OQ#14 |
| **F-HD-14** | MVP percent curves (`attack = 100 + 8 × atk_points`; `hp_max = PLAYER_MAX_HP + 8 × hp_points`; **`defense = 0`**); **the VS sheet's `hp_max = 100 + 8×(L−1)` (252)**; VS sheet; *"L1 100/100; 4 ATK points → 132/100; 4 HP points → 100/132; 2/2 → 116/116"* | **the printed ladder** (§ 3.1, with its V-HD-12 validation); `hp_max = PLAYER_MAX_HP + HP_PER_POINT × hp_points`; `attack = PLAYER_ATK_BASE + ATK_PER_POINT × atk_points` (**both already aggregate gear — the module's contribution lands in `attack`/`hp_max` through SYS-16's aggregation; `defense` is inert at this scale, R10, so the damage lever is `StatBlock.damage_bonus`**); **the VS sheet's HP curve is rewritten on the new symbols — `hp_max = PLAYER_MAX_HP + HP_PER_POINT × (L−1)` = 20 + 2×(L−1) → 58 at L20** (otherwise the applied GDD carries two HP scales and a 28 → 140 discontinuity at the L5→L6 seam; OQ#20 names it as the **second** handoff axis, alongside `attack`); the VS dealt outputs re-derive against the new raw table (SYS-16's, OQ#20); the examples → **100/20 · 132/20 · 100/28 · 116/24** (attack / hp_max pairs) |
| **V-HD-06/07** | T1<T2<T3<boss; P1<P2<P3 | restated with the new values (both still hold: 1<2<4; 6<12<24<60)); **V-HD-07's clamp order is named** — a violation raises P2/P3 (never lowers the fixed P1), so a clamp can never make a light strike illegal |
| **V-HD-12** | "L1/no harness → the approved numbers exact" | + the ladder's validation — **four checks**: monotone columns, strictly increasing chain, row-0 equality, **and row 4's chain ≤ 10** (the envelope's top). **At config load, any failure is a boot failure.** **On a live edit, the resolution splits by case**: row-0 equality broken → **rejected, the last good config kept**; row 4's chain > 10 → **rejected** (the pin is a law, not a clamp); a non-monotone **ATK2** column or a non-strictly-increasing chain → **the offending row's ATK2 cell rises by one, then all four checks re-run — a residual violation rejects the edit** (the ATK1/crouch/air columns are never clamped; a live edit that breaks one of *them* is rejected) |
| **V-HD-13** | `DEF_CAP_PCT ≤ 25` at MVP; `taken ≥ 1` | unchanged law; the 5b rider on the MVP source; + the R10 quantization note |
| **V-HD-14** | the parity bands hold | + *"at MVP the sustained band binds through the 60 s integral; the per-chain and single-arc comparisons carry the ±1-step granularity tolerance"* |
| **Edge Cases — Items** | *"a Suture is used at 90/100"* | **18/20** |
| **Edge Cases — Stats** | *"+HP → max HP +8"* · *"four points all go to ATK → ATK 132, ATK1 14, ATK2 27, chain 41"* · *"four points all go to HP → max HP 132"* | **+2** · **ATK 132, ATK1 4, ATK2 6, chain 10** · **max HP 28** |
| Knob table | **12 rows change value** (18 symbols: `PLAYER_MAX_HP` · `HP_PER_POINT` · `TRAINING_DATA_L2/L3/L4/L5` · `XP_T1/T2/T3` · `XP_BOSS` · `ENEMY_HP_T1/T2/T3` · `BOSS_HP` · `STRIKE_DMG_P1/P2/P3` · `HEAL_ITEM_AMOUNT`), **`ATK_PER_POINT` reclassified to "8 (fixed identity)"**, **one new row** (`DAMAGE_LADDER_MVP`), 19 rows unchanged | § 3's defaults + the re-derived safe ranges (**including the strike table's: P1 **1
(fixed)** / P2 2–3 / P3 4–5**), **and every changed row's extreme-behavior column
re-derived** (the cells are enumerated in their own row below — this row does not repeat them) |
| **Cross-system inputs** paragraph | *"the SYS-08 damage values (`ATK1_DAMAGE` 10, `ATK2_DAMAGE` 20, `CROUCH_ATTACK_DAMAGE` 8, `AIR_ATTACK_DAMAGE` 10 …)"* | **2 / 4 / 2 / 2** (the same four symbols as the S2 clause — without this the GDD declares 10/20/8/10 as its own input while its knobs say 2/4/2/2, and V-HD-12's "row 0 equals the four raw knobs" fails at boot) |
| **Interactions** row — *Strike damage* | *"the `enemy_strike_damage(power)` table (6/12/20)"* | **1 / 2 / 4** |
| **F-HD-10** (Example clause) | *"at ATK 132 (chain 41) T3 needs ceil(120/41) = 3 (123)"* | **"at ATK 132 (chain 10) T3 needs ceil(24/10) = 3 (30)"** |
| **AC-HD-03/05/07/10/11/13/14/15/23/27/29/31/32/34/36/37/42/49** | the frozen fixtures | every expected number re-derived; **AC-HD-13 hosts the ladder's five-step dealt/counter fixtures** and **the six-stage
order assertion** (base → ladder/percent (dealt) / F-HD-03 (taken) → module modifier →
crit → floor → cap) (and its **negative fixtures**: a non-monotone column and row 0 ≠
the four knobs → both **fail the boot**; a `NORMAL`/`COUNTER` with `arc = NONE` →
**rejected at dispatch** with the named telemetry reason, dev assert; a **live** broken
row-0 equality or row-4 chain > 10 → rejected, a live non-monotone **ATK2** column or
chain → accepted clamped then re-validated, a live non-monotone **ATK1/crouch/air**
column → rejected) — plus **one
`NORMAL`/`ABILITY` fixture at a non-default `attack` (raw 3 → 4 at ATK 132)** and **one
`DEFLECT` fixture at a non-default `attack` (raw 2 → 3 at 132)**, so neither branch is
accidentally the identity — **one same-kind/different-arc pair on the idempotence key**
(AC-HD-18: two events differing only in `arc` both apply — a *synthetic* fixture; one
body cannot fire two arcs in a tick, so the element is defensive schema completeness) —
and **AC-HD-07 the
build examples only** (the Suture / revive / pit examples land in **AC-HD-31 /
AC-HD-27 / AC-HD-15**); no new AC, no count change; AC-HD-05's *"no approved fixture changes"* → *"the reworked Combat fixtures pass unmodified"*; the gate partition stays **42 + 3 + 5 + 0 = 50** |
| **AC-HD-14** (an out-of-band fixture) | — (the frozen DEF fixtures sit at raw 1–4, where DEF 5 ≡ DEF 25) | **+ raw 20 → 19 at DEF 5 / 15 at DEF 25** — the only fixture that discriminates the mitigation arithmetic at the low baseline |
| **AC-HD-17** | the 10,000-event fuzz mix | **+ `arc` stamped on every NORMAL/COUNTER event** (otherwise ~60% of the mix is rejected at dispatch and the damage-path coverage silently collapses) |
| **AC-HD-41 / AC-HD-50** | — | **unchanged** (the perf budget and the lose-branch economy carry no damage number) |
| **OQ#5 / #6 / #10 / #13 / #14** + the VS-record line | the SYS-16 split; the SYS-17 carve-out; boss HP 200–400; mana live; Elegy; **OQ#5's *"L20 + 19 points = 366"*** | + the new baseline as the input; OQ#13 carries M1; OQ#6/#10 re-derived; OQ#10's range **40–80**; OQ#14 carries Elegy's table; **OQ#5's 366 is re-derived on the new symbols (20 + 2×19 = 58 at L20) or struck** |
| **New OQ (the 20th)** | — | *"The SYS-16 growth handoff at the low baseline — **two axes**: (a) the `attack` stat and the dealt value must be monotonic against the ladder's top row (the candidate rule `ceil(4 × attack ÷ 132)` is **flat at L6**, since the frozen VS curve gives `attack` 130 → ATK1 4, and +1 only at L7); (b) the VS sheet's `hp_max` curve is re-based on the new symbols (`20 + 2×(L−1)` → 58 at L20) or another scale is chosen — the frozen 252 leaves a 28 → 140 seam. Does the ladder continue past L5, or does the percent curve take over at L6, and at what damage scale does the curve resolve?"* — owner SYS-16, at SYS-16 authoring |
| Dependencies rows **and bullets** | SYS-16 *"VS"*; SYS-17 *"VS; MVP carve-out … equipment"*; SYS-12 *"VS"*; **the SYS-08 interface cell *"In: `DamageEvent {source, target, raw_damage, kind, contact_tick}`"*** | SYS-16 *"MVP (the gear layer) + VS sheet"*; SYS-17 *"MVP carve-out + gear (D-1)"*; SYS-12 *"MVP (D-3) — mana-free (M1)"*; **the SYS-08 cell gains `arc`** |

**Not touched**: the boundary/enum, the 11-term gate, **the damage order's stage
sequence (it gains one named stage — the module modifier after the ladder — not a
reordering)**, F-HD-11's counter body, the death edge/`DeathRecord`, the state machine,
the options contract, the chip/pickup/heal laws, the i-frame lock, the ms/tick
contracts, the damage-number law, the perf budget, **the `StatBlock` schema beyond the
one added field (`damage_bonus`)**.

## 9. The downstream riders (frozen docs that go stale — one line each)

These are **recorded here, applied by their owners on each doc's next touch** (the
OQ-M1 pattern). This lane does not edit them.

| Doc | Clause | New value |
|---|---|---|
| **`combat.md` (SYS-08)** — the S2 co-revision | TR-CMB-004's damage column; the four damage knobs **and their safe ranges** (6–14 / 14–26 / 5–12 / 6–14 — the new defaults would otherwise clamp back to 6/14/5/6 at config load); TR-CMB-010's *"ATK1 15, ATK2 30 at defaults"*; F-CMB-06's outputs (*"ATK2 20 × 1.5 = 30"*, *"`ATK.damage` 5–26"*); **TR-CMB-015 / F-CMB-10's Example / AC-CMB-17** (*"its damage is the projectile's original damage (8 at the prototype default)"*, *"it damages the shooter for 8"*, *"the damage is the projectile's (8 at default)"*); **AC-CMB-12** (*"the enemy takes floor(20 × 1.5) = 30"* and *"the ATK1 damage-10 → 15 case is F-CMB-06's formula unit test"*); **TR-CMB-025's `DamageEvent` schema and AC-CMB-30's five-field fixture** (the ladder's `arc` must cross this boundary) | 2 / 4 / 2 / 2; ranges **1–2 / 3–4 / 1–2 / 1–2**; counters **3 / 6**; F-CMB-06's input band **`ATK.damage` 1–4** (the raw counter's 6 is an output, not an input); the deflect keeps **2**; the applied counter **6**; AC-CMB-12's unit case **2 → 3**; **`DamageEvent` gains `arc ∈ {ATK1, ATK2, CROUCH, AIR, ABILITY, NONE}`**, stamped at the contact from the executing arc |
| **`enemy-ai-telegraphs.md` (SYS-13)** | the Contracts line + the Interactions row + the cross-system-inputs line (6/12/20, 30/60/120); **TR-ENM-004's** *"tier (30/60/120 per SYS-07)"*; **TR-ENM-005's roster** (HUSK hp 30/award 15 · SPITTER hp 60/award 35 · WARDEN hp 120/award 70); **TR-ENM-009's** *"the counter (30 damage + the enemy's 800 ms stagger)"*; **TR-ENM-011's** `EnemyProjectile {…, damage: 8, …}` + *"its 8 damage sits between the P1 6 and the P2 12 rows"* + its test *"the friendly-fire kill publishes `killer_id = player`"*; **F-ENM-07's** *"it kills the Spitter for 8"*; **TR-ENM-024's** edge case *"If a deflected orb kills the Spitter"*; **F-ENM-04 / TR-ENM-018's tail** *"at ATK 132: 40 + 41 = 81 (T2 dead with overkill; T3 survives at 39)"*; **V-HD-06's** `30 < 60 < 120`; the *"counter-punish ceiling 60 (= T2's pool)"*; **the SYS-16 Interactions row's kill-award table (15/35/70)**, **the Dependencies SYS-07 row's tier ranges (30/60/120)**, **the answerability-matrix row (*"— (8 dmg; band 1)"*)**, **the "farms orb-deflects" edge bullet (*"the orb is 8 damage"*)**; **AC-ENM-03** (*"the ATK2 counter fires (30 damage)"*), **AC-ENM-12** (*"the ceiling arithmetic prints 60 (defaults) and 81 (ATK 132)"*), **AC-ENM-16** (the envelope 20–41), **AC-ENM-18** (the deflected-orb kill); **and its own traceability row** *"F-HD-01 (the strike table 6/12/20)"* plus the **Not-knobs** line *"the strike damage table 6/12/20 (SYS-07's F-HD-01)"* | 1/2/4; 6/12/24; hp **6/12/24** with awards **3/7/14**; the counter **6**; the orb **2**, *"equal to the P2 and above the P1"*; the deflect *"deals 2 to a 12-HP Spitter — no longer a one-shot"* (**a behaviour change, SYS-13's call** — it strikes F-ENM-07, TR-ENM-024 and AC-ENM-18 together); *"at ATK 132: 8 + 10 = 18 (T2 dead with overkill 6; T3 survives at 6)"*; `6 < 12 < 24`; ceiling **12** and **18**; the award table **3/7/14**; the matrix **"2 dmg; band 2"** (the same 2-damage hit SYS-04 bands as 2 — `BAND_2_MIN = ATK1_DAMAGE` = 2), **SYS-13 re-confirms the orb's flash band** (its old "band 1 says light" justification, *"8 sits between P1 6 and P2 12"*, no longer holds); envelope **4–10** → 1–2 / 2–3 / 3–6 / 6–15; `spitter_orb_damage` **8 → 2** |
| **`audio-core.md` (SYS-04)** | F-AUD-03's printed examples (8→B1, 10→B2, 15→B2, 20→B3, 30→B3); its **Variables** clause *"`ATK1_DAMAGE`/`ATK2_DAMAGE` int — SYS-08's arc symbols (10/20 at the provisional table)"*; its **Scope** clause *"the received strikes 6/12/20 (TR-HD-003) and tiers 30/60/120 (TR-HD-006)"*; **TR-AUD-015's test / AC-AUD-08** (*"amounts at the arc symbols (8/10/15/20/30) … the bands are 1/2/2/3/3"*) | the band boundaries move **automatically** (symbol-anchored: `BAND_2_MIN = ATK1_DAMAGE` = 2, `BAND_3_MIN = ATK2_DAMAGE` = 4); the Variables/Scope literals become **2/4** and **1/2/4 + 6/12/24**; the printed fixtures become **1/2/3/4/6 → bands 1/2/2/3/3** |
| **`juice-feedback.md` (SYS-29)** | F-JCE-06's *"the ratio is the player's (hp_max 100 at L1)"* + its examples (*"20 into 16 → overkill 4 → 0.04"*, *"a pit death at 40/100 → 0.60"*, *"39 → 0.61"*), the Edge-Cases mirror, **the § Player Fantasy anchor moment** (*"A power-3 heavy empties the bar — 20 into 16, overkill 4 … (ratio 0.04)"*), and **TR-JCE-018's test / AC-JCE-18** (*"ratios 0.0, 0.04, 0.40, 0.73"*) | `hp_max` **20**; the reachable 1/20 pairs: **4 into 3 → overkill 1 → 0.05 (LOW)**;
  **a pit death at 8/20 → overkill 12 → 0.60 (MID, inclusive)**; **7/20 → overkill 13 →
  0.65 (HIGH)** — **the 0.60 threshold is unchanged** (it is a hundredths law, not an
  absolute); the frozen *example* 0.61 (39/100) has no ÷5 integer image, so the first
  reachable HIGH ratio is 0.65 (13/20); the *"strike deaths ≤ 0.20"* reachability note
  still holds (P3 = 4/20 = 0.20, inclusive); AC-JCE-18 → **0.00 / 0.05 / 0.40 / 0.75** |
| **`cache-stations-death.md` (SYS-15)** | AC-CSD-05's *"37/100 HP"* and *"HP = 100"* | **7/20**; **HP = 20** |
| **`room-world-structure.md` (SYS-02)** | **F-RWS-05's Example** and **AC-RWS-14**: *"`raw_damage = hp_max` (100 at the default profile)"* — the pit's publisher | **"(20 at the default profile)"** (the law is unchanged; only the printed default moves — the same correction as the registry's `env_void_damage` note) |
| **SYS-15 / SYS-26 (the cache spend surface)** | — (new obligation) | the spend UI previews the **ladder's per-move deltas** (ATK1 2→3, chain 6→7), not the 100-scale `attack` readout — keeping the lean-but-accessible presentation (D-2) and term 4's promise |
| **The Gate-2 session script (qa-lead)** | — (new obligation) | the parity-promise probe (§ 7c) joins the four existing probes; **game-concept's probe list is edited by the sync lane**, so the playtest contract stays single-sourced |
| **`systems-index.md` (SYS-07)** | the **dependency-map bullet** (line 61) *"player 100 HP; strikes 6/12/20; tiers 30/60/120; boss 300; Dirge chain 37 t = 48.65 dmg/s"* + its *"19 OQs"*, and the **status row**'s *"67 edge bullets / 19 OQs"* (the GDD has always claimed **68** — correct it while editing the string), its *"VS: … gear"*, and its carried-OQ list (*"carries OQ#1/#2/#3/#4/#19"* → **+#20**) | the sync lane applies (never this lane) |

**No rider is needed for SYS-14**: its GDD is not written, so the boss pool is
authored fresh on the new baseline (TR-HD-011's range and OQ#10 carry the input).

## 10. The sync request (prepared, not applied)

**`design/registry/entities.yaml`** — value updates (never new duplicates). **The
registry is a *mirror* of the knob tables, never a second source**: F-HD-14's
named-symbol law keeps the values in the Tuning Knobs table, and the registry carries
only the cross-boundary ones.

- `strike_dmg_p1` 6 → **1**; `strike_dmg_p2` 12 → **2**; `strike_dmg_p3` 20 → **4**
  (`source: health-damage.md`; `revised:` names D-ORCH-03).
- `atk1_damage` 10 → **2**; `atk2_damage` 20 → **4**; `crouch_attack_damage` 8 →
  **2**; `air_attack_damage` 10 → **2** (`source: combat.md`; the S2 clause); each
  note's printed chain/counter sentence re-derived (`atk2_damage`'s *"the chain total
  is 30 at ATK 100"* → **6**).
- `spitter_orb_damage` 8 → **2** (`source: enemy-ai-telegraphs.md`); its note's
  cross-row claim (*"a deflected kill publishes `killer_id = player`"*) is re-derived
  with the value — at 2 vs a 12-HP Spitter it is no longer a kill.
- `enemy_archetype_roster` — *"HUSK T1 hp30 award15 · SPITTER T2 hp60 award35 ·
  WARDEN T3 hp120 award70"* → **hp 6/12/24, awards 3/7/14** (its `referenced_by`
  includes `health-damage.md`, so the mirror must not contradict it).
- `enemy_strike_contract`'s `EnemyProjectile` payload — *"`{projectile_id, owner_entity, damage 8, power_band 1, …}`"* → **damage 2** (`source: enemy-ai-telegraphs.md`; the SYS-13 rider) — the registry's **second** home for the orb's damage; leaving it at 8 would recreate the second source the mirror rule forbids.
- `enemy_stagger_ms`'s note — *"the counter+chain ceiling is 60 = T2's pool at defaults
  (81 at ATK 132)"* → **12 = T2's pool at defaults (18 at ATK 132)**.
- `env_void_damage`'s note: *"(100 at the default profile)"* → **"(20 at the
  default profile)"** (the value `hp_max` is unchanged — the law is scale-free).
- **New constants**: `damage_ladder_mvp` — **registered, with SYS-15 named as the MVP
  consumer** (the cache spend surface is SYS-15's at MVP; SYS-26 is VS — the preview
  reads the per-step deltas; without the registration the preview has no transport and
  SYS-15/26 would re-author the numbers, the second source the mirror rule forbids) ·
  `player_max_hp` 20 (consumer: SYS-15's AC-CSD-05 fixture prints it; SYS-24 reads
  `HealthRead.hp_max`, not the constant) · `hp_per_point` 2 (consumer: the same
  spend-surface preview) · `training_data_l2..l5` 20/50/90/140 (consumer: **SYS-07**
  publishes `HealthRead.training_data`; SYS-24 renders the cue) · **`atk_per_point`
  registered when SYS-16 lands** (the ladder's index divisor crosses to OQ#20).

**`design/gdd/systems-index.md`** — the SYS-07 **dependency-map bullet**'s economy
clause (line 61) **and its own "19 OQs"**; the **status row**'s *"67 edge bullets / 19
OQs"*, its *"VS: … gear"*, and its carried-OQ list (*"carries OQ#1/#2/#3/#4/#19"* →
**+#20**); the design-order row 22 note *"rework applied — <hash>"*; the SYS-16 and
SYS-17 **dependency-map bullets'** sequencing clause (SYS-16: *"sequenced after the
SYS-07 low-stat baseline rework (IP-17)…"*; SYS-17: *"…after the SYS-07 baseline rework
(IP-17)"*) → *"unblocked — the baseline landed <hash>"*; plus **game-concept's Gate-2
probe list** (the fifth probe, § 7c).

## 11. Risks (named, with the lever)

| # | Risk | Severity | Mitigation / lever |
|---|---|---|---|
| **R1** | **Integer granularity is the whole game at 20 HP**: one damage step = 5% of the bar and +16.7% of the chain; the percent curve cannot resolve, the ±10% band is unmeasurable per-chain, **the strike table loses its tuning room** (P1 fixed at 1), and the SYS-08 raw ranges must narrow to keep the ladder monotone. | **High** | the ladder (G2) + the integral-based parity measurement (§ 7a); the tuning lever moves to the pool and the tiers (§ 3). Accepted, not hidden. |
| **R2** | **The strike rounding widens the spread** (P1:P2:P3 1:2:3.33 → 1:2:4): the light strike is relatively lighter (5% vs 6% of the bar), the heavy keeps exactly 20%. | Medium | accepted as a design shift (§ 4.1); the alternative is P3 (50 HP), which abandons D-7. |
| **R3** | **The crouch loses its number gap** (1.6 → 2 = ATK1): the 8-vs-10 hierarchy cannot survive integer rounding; the crouch's distinction becomes arc + hitbox only. | Medium | stated in the ladder's note; the frozen trade axes already make reach/arc the differentiator; SYS-08's crouch arc (18 t, low hitbox) carries it. |
| **R4** | **The Spitter's orb is relatively promoted**: 8 vs a P1 6 (1.33×) becomes 2 vs 1 (2×) — and the deflected orb no longer one-shots a Spitter (F-ENM-07 / TR-ENM-024 / AC-ENM-18). | Medium | rounded up by the never-stingy law; recorded as a SYS-13 authoring input (the orb is a T2 ranged attacker's only attack; the one-shot claim is SYS-13's to re-decide). |
| **R5** | **`HP_PER_POINT` 1.6 → 2** makes each HP point +10% of the pool (frozen +8%). | Low | the closest integer to the ÷5 intent; the alternative (1) makes HP points flat. |
| **R6** | **The all-ATK L5 build is ~25% stronger than the frozen arc** (chain +67% vs +37%; the boss falls in 6 chains vs 8). | Medium | the **boss tuning watch**: `BOSS_HP` 60 sits at the **midpoint** of the new 40–80 range; if the Gate-2 playtest says L5 trivializes the Denial boss, raise it to 72 (12 chains at L1). |
| **R7** | **The growth arc is chunkier than the frozen design** (+1 whole damage steps read as big jumps: ATK1 2→3 is +50%), and `ATK_PER_POINT` stops being tunable (it is the ladder's *printed* 8-spaced index column and the VS sheet's shared step, not a free divisor). | Medium | that is the *point* of a low baseline (D-7's "the growth arc reads"); each point still moves ≤ 1 step per move. |
| **R8** | **SYS-16/17 author after this** — if SYS-16 wants a different scale, this rework is partly wasted. | Low (accepted by D-7's sequencing) | the ladder + the parity input + OQ#20 are SYS-16's starting contract. |
| **R9** | **The HP bar at 20 points** (a 2-damage step is a visible chunk). | Low | SYS-24's segmentation; AC-HD-42's device legibility re-runs at the locked 480×270 scale. |
| **R10** | **The DEF axis collapses at the low baseline**: at raw 1–4, **any `defense ≥ 1`** yields the same taken values (1/1/3) as `defense 25` — mitigation is quantized to a binary, and `DEF_CAP_PCT` 25 is decorative at MVP. | **High for D-1** | stated in the 5a rider: a Chassis Module must not rely on `defense` as its build modifier; SYS-16's input (a module may instead move HP, damage, or a behavioral modifier). |
- **R11** | **The L5→L6 handoff is unresolved**: the frozen VS curve gives `attack` 130 at L6 (below the points cap) and the frozen percent law at `attack` 140 would give ATK1 3 < the ladder's 4 — the stat and the damage both fall at the level cap. | Medium | **delegated with a requirement**: the VS sheet must be monotonic against the ladder's top row in the stat *and* the dealt value; the candidate rule is in OQ#20. Not applied as an untestable MVP branch. |
| **R12** | **A reviewer reads the parity restatement as weakening the law.** | Medium | the *bands* are unchanged (10/10/15); only the *measurement surface* moves, and only because integer steps exceed the band. Stated in the GDD's own V-HD-14. |

## 12. Options

**Option A — approve as revised (recommended).** The /5 coherent scale (20 HP) · the
weapon table rescaled (SYS-08 co-clause + the Spitter's orb) · the growth ladder ·
the three TR-HD-006/033 riders · mana-free Stinger (M1) · the parity restatement +
guardrails. Every § 1 invariant holds, every training point is felt, and the
consequences are named rather than hidden (R10's DEF collapse → SYS-16's gear input;
R11's L5→L6 handoff → OQ#20). **The residual is SYS-16-owned, not this package's**:
the VS sheet's scale above level 5. Cost: two frozen contracts + nine one-line
downstream riders.

**Option B — approve the SYS-07-only variant.** 20 HP · strikes 1/2/4 · **keep the
percent growth curve** · the `DAMAGE_SCALE` divisor instead of the SYS-08 clause ·
mana-free. One frozen contract only. Cost: training points 2 and 3 are invisible, and
SYS-04's three damage bands collapse to one band until its own rider lands.

**Option C — hold.** No edit; SYS-16/SYS-17 stay blocked. The baseline stays at 100
HP and D-7 is unmet; the gear layer's numbers would be authored on the old baseline
and the rework would have to be re-run later.

**A component swap is available without rejecting the bundle** (e.g. *"A but with the
50 HP pool"*, or *"A but keep mana live"*) — each swap is named in § 4 and § 6 and its
consequences are stated there.

## 13. After approval — the application plan (not this run)

1. Apply § 8's diff to `design/gdd/health-damage.md`; the commit names **D-ORCH-03**
   and the date, and its message cites IP-17. The **sweep + exclusion set** in § 8's
   preamble is the completeness test.
2. Apply the SYS-08 one-clause revision and the SYS-13 orb value (separate commits,
   naming the same decision and each owner's countersign).
3. Send § 10's sync request to the orchestrator (the sync lane applies it serially).
4. Record the § 9 riders in `decisions.md` as carried obligations with owners.
5. Re-derive the review trail: the diff is a **contract revision**, so it runs the
   CD gate + the technical seat on the *applied* text (a diff-scoped pass, the SYS-01
   #10 precedent), then the qa-lead spot-check on the arithmetic.
6. Unblock SYS-16 and SYS-17 on the landing receipt.

## 14. Provenance of the numbers

Every number in § 3 is derived from the frozen GDD's own values by a single named
operation (÷5, or the printed ladder), and every derived band in § 1 is checked
against the frozen band it replaces. The arithmetic was re-derived by hand and is
listed in the review log (`design/gdd/reviews/sys07-rework-review-log.md`) with the
formula that produced it, so a spot-check can reproduce it without reading this
document. The seat passes that shaped round 2 are recorded there with their verdicts
and the disposition of every blocker.
