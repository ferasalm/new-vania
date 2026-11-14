# Game Concept: Five Errands for the Devil

*Created: 2026-11-08*
*Status: Draft*

## Core Identity

| Field | Details |
|---|---|
| Working title | Five Errands for the Devil |
| Genre | 2D story-forward metroidvania (SotN-school: RPG texture, deliberate combat, room-based exploration) |
| Platform | Mobile (iOS/Android) primary, PC (itch.io demo → Steam) secondary. Touch-first controls; keyboard + gamepad supported from day one |
| Estimated scope | Large (≈155–195 dev-days cumulative ≈ 2.5–3× MVP's 55–70; ~12–18 months solo part-time with agent harness) |
| Engine recommendation | Godot 4 (both owned core assets — Metroidvania System 1.6.1 addon, Warped City — are Godot projects) |

## Elevator Pitch

A demon lord's android assassin — built from a dead woman's preserved brain — is sent through parallel universes to hunt her maker. Five errands, five grief-warped realities, and a final choice: the timeline where she lives, or the one where you don't lose yourself.

## Core Fantasy & Unique Hook

- **Core fantasy**: Be the slick, clever anti-hero who wins by reading the world — then discover you are the weapon, and choose whose side you're on. Includes the revenge-rematch arc (an unbeatable early foe, later crushed) and a long peak-power window.
- **Unique hook**: Like SotN's inverted castle, AND ALSO the inversion creeps forward as you work — every errand leaves reality wronger than you found it, and backtracking shows you exactly how — AND ALSO the recurring boss is the woman you're copied from, fought across grief stages, with one version that lowers her weapon and joins you before the demon lord executes her.

## Pillars

| Pillar | One-sentence definition | Design test |
|---|---|---|
| SotN, Not Hollow Knight | Deliberation + RPG texture (levels, drops, gear, save sanctuaries) over twitch platforming purity | Would this design fit HK better than SotN? Then cut it |
| Read, Then Strike | Every threat telegraphs; the clash/parry is optional mastery, never a requirement | Flashy-but-unreadable vs. readable → choose readable |
| One World, Two Truths | Reality's changing truth is the single spine: traversal, puzzles, story structure | A feature not expressible through the world's changing truth or memory → cut it |
| Five Goodbyes | The map is her mind; every region changes what we know or feel about her | An area that teaches nothing about her → it doesn't ship |
| Remade Every Death | Death is story: cache stations, body reconstruction, the incrementing name counter | A death reduced to a plain "YOU DIED" screen → redesign it |

### Anti-Pillars

- We will NOT do helpless horror — the player always has attack and clash, with Dash arriving as an unlock (compromises Read, Then Strike)
- We will NOT do timers or speed pressure — deliberation is the fantasy (compromises Read, Then Strike)
- We will NOT do endless multiverse content — 5 realities + hub + final room, boss variety within budget (compromises Five Goodbyes and scope)
- We will NOT do stat-spreadsheet menus — **lean but accessible stat presentation** (amended 2026-11-14, user decision D-2: a stat menu is acceptable if accessible and not too complicated; the `TR-INP-070` a11y baseline binds it, and the presentation itself lands at SYS-26 Sanctuary Menus). A dense numeric spreadsheet still fails (compromises touch-first simplicity)
- We will NOT do cutscene-driven storytelling — story lives in logs, environments, boss encounters (compromises scope and Five Goodbyes)
- We will NOT do twitch-precision platforming gauntlets (compromises SotN, Not Hollow Knight)

## Core Loop

### 30-Second Loop

Read a room → fight 2–3 telegraphed enemies (two-hit combo, optional clash with power comparison and the flashy double-clash when evenly matched, projectile deflects, mid-air attacks, Stinger via quarter-spin + attack once granted) → loot roll (essence + rare gear) → push deeper until the errand's threshold flips the zone's truth — and when you backtrack, familiar rooms are wrong now: new paths open where reality has moved on. Juice: glitch transition at truth changes, hit-stop, clash sparks, soft memory chime.

### 5-Minute Loop

Clear a wing → reach a **cache station** (iconic sci-fi save terminal; saving prints **"MEMORY CACHED"**) → memory fragment (numbered, e.g., "Memory 7/24") + materials. Choices: which seam to shift at, detour to optional memory rooms, push on or return to spend.

### Session Loop (30–120 minutes)

One session = 1–2 errands. Court briefing → dive a reality → grief-stage boss → return → **report to the demon lord** (dramatic irony, text-only) → **demon contract choice** (accept a blessing = power that visibly corrupts the android; "don't lose yourself" as a mechanic) → spend essence/gear → pick next errand. Cliffhanger: a new memory recontextualizes the lord's last order.

### Progression Loop (Days/Weeks)

Power: one new **reality law** per errand (the dive rewrites a law of reality; mutated zones obey it going forward) + ability unlocks (Dash first, then Wall Jump, then Double Jump) + the **Demonic Cyber Stinger** (demon lord's gift — quarter-spin + Attack punctures through an enemy, exits behind, brief i-frames) + XP/gear. Knowledge: assembling who really killed her father. Emotion: five goodbyes. Completion: the final choice + short epilogue shaped by it.

### Combat Verbs (touch-first: Attack / Jump main; Dash unlocked as an ability; contextual Interact)

- Two-hit combo; committed SotN-weight attacks; mid-air versions
- **Clash (optional parry)**: timed Attack as a strike lands — vastly stronger → stagger them; evenly matched → weapons lock and clash twice, neither staggers, flashy; weaker → you're staggered. Projectiles deflect back and can hit other enemies
- **Dash**: a movement ability LOCKED at start, gained through progression (classic MV gating); designed as the defensive repositioning answer — i-frame usage decided in the combat GDD
- **Backdash (day-one)**: double-tap back — brief i-frames, quick backward hop (SotN-exact); joins the defensive family (backdash · Dash · clash; i-frame rules decided in the combat GDD)
- **Wall Jump (ability-unlocked, after Dash)**: wall-slide + jump-off; generous physics, no stamina — the two-wall shaft climb is a deliberate read, never a reflex test
- **Double Jump (ability-unlocked, after Wall Jump)**: the Leap-Stone-style relic moment — the map changes meaning when she can jump twice
- **Interact (contextual)**: cache terminals, memory pickups, seam borders, logs — one contextual button
- **Demonic Cyber Stinger (motion input)**: quarter-spin on the floating stick + Attack — the stylish lunge-through granted by the demon lord (keyboard: ↓↘→ + Attack; gamepad same). Requires gesture buffering across all input methods
- **Unhinted tech**: emergent chains (e.g., backdash dodge → Stinger counter) are real and NEVER taught — no tutorial, log, or bestiary hint; the player figures them out. Guard: both gestures stay natural enough to stumble into (SotN playground-culture depth)

### Boss Roster (variety beyond the mirror)

- **5 grief-stage self-bosses** (one rig, five states): Denial (pristine lie-world, doesn't recognize you), Anger (warzone), Bargaining (machine scaffolding + her experiment logs), Depression (inverted silent world — lowers her weapon, joins, is executed mid-conversation), Acceptance (final confrontation)
- **Demon lord** — final boss; every prior errand was his errand
- **Shapeshifter** — variety boss (candidates: copies the player's moveset, or mimics her across stages)
- **Mini-bosses** (2–3 elite encounters) — short arenas, story-lore hooks
- Doctrine: every non-self boss introduces a new interaction rule

### Enemy Lore Doctrine

Every enemy type gets a bestiary entry tying it to the world and plot (e.g., reality A's demons are AI-possessed humans; reality B's undead are magic-era remains). Text-only, cohesion-first.

### Story-Revealing Item

A SotN-Holy-Glasses-analog item that reveals hidden truths/illusions in the world (gates the true ending route). Name and exact behavior TBD (see Open Questions).

## MVP Definition

Greybox/juice-first prototype (feel over visuals): one zone — ~6 rooms with one story-threshold that flips the zone's truth mid-run, plus a backtrack reveal of an earlier flipped room — the Denial boss, core combat (combo, clash, deflect; Attack/Jump/Interact), movement state Crouch (stick down-zone), day-one Backdash (double-tap-back + a11y press); Dash locked (the D-3 mandate adds the gesture ability, not Dash — the unlock-ladder doctrine and its anticipation design stand). One cache station with the death counter, 3–4 memory fragments. Floating-stick touch controls + keyboard. Two-stage prototyping: FIRST a single-mechanic combat concept-test (combo weight + clash timing + deflect feel), THEN the ACTUAL greybox MVP with the truth-flip. Success test (testable): the combat concept-test is **concluded — verdict PROCEED** (`prototypes/combat-concept-test/REPORT.md`, all four success criteria met 2026-11-11).

**The MVP expansion (2026-11-14, user decisions D-1…D-7 — benchmark audit § 5a; the audit's IP-14…IP-17; D-2's wording rides the Anti-Pillars above):**

- **The pause room-grid map** (D-4): SYS-25-minimal — discovered cells + unexplored-doorway ticks — reading the already-MVP `cells_discovered` save family (`TR-RWS-025`); SYS-24 coordinates the pause surface
- **The MVP gear layer** (D-1): deterministic named Chassis Modules (build modifier + 2-line lore), a two-slot loadout, and the guaranteed Warden-tier drop behind the post-flip partition — the benchmark-pillar-5 (secrets worth finding) seed; authored at SYS-16/17 **after** the low-stat baseline rework lands
- **The demonic gesture ability** (D-3): the Stinger-like, Tekken-style quarter-spin + Attack combination — demon-granted at MVP, with its grant story moment in SYS-05; **Dash stays locked**; Backdash day-one confirmed as intended (`TR-INP-056`)
- **The epistemic Epoch-0 tells** (D-6): architectural tells in the existing rooms' Epoch-0 presentation (symmetry, dead conduits, error codes) telegraphing the post-flip openings — an MVP authoring obligation at SYS-09/10; no geometry change, and the dedicated "aha" room stays a zone amendment candidate (the room set is frozen by `AC-RWS-03`)
- **Benchmark pillars 4/5/6 as MVP priorities** (D-5 — the audit's numbering, not this concept's five pillars): movement pacing — the **450 ms** door-open working default under OQ-RWS-1's playtest question (the reveal arc's 700 ms held signature frame is out of scope); secrets worth finding — the gear seed above; low-friction backtracking — already FIT, protected not regressed as the map and gear land
- **The low-stat baseline** (D-7): level 1 ≈ 20 HP — the SYS-07 economy rework (strikes, tiers, boss pool, the F-HD bands, the identity-law fixtures re-derive together) is its own amendment session, sequenced BEFORE the gear layer's numbers are authored

The full nine-stat sheet and the essence economy stay VS.

**The greybox MVP playtest gates (phased first contact — user decision 2026-11-14)**: ≥3 outside playtesters × 20-min sessions per contact. **Gate 1 — the core slice** (rooms, flip + reveal, Denial boss, combat core, cache + counter, memories, movement; the **450 ms** door working default already set under OQ-RWS-1): the original pass codes — ≥2/3 keep playing past the 20-min mark unprompted, ≥1 tester spontaneously mentions the backtrack reveal, clash timing codes trust on the SYS-01 AC-63 rubric (≥3/5 trust-coded, 0 lag-attribution). **The expansion increment** — the map (D-4), the gear layer (D-1), the gesture ability (D-3), the epistemic tells (D-6) — lands immediately post-gate-1, shaped by its signal. **Gate 2 — the full expanded slice**: the same pass codes plus the grown elicitation set — AC-RWS-31/32 and AC-HD-44…48 stand unamended, the session scripts grow by four probes: the **map** (is the pause grid consulted unprompted after the flip?), the **gear beat** (is the post-flip Warden drop noticed and equipped?), the **gesture beat** (is the Stinger stumbled into or sought after its grant?), and **tell-noticing** (does any tester mention an Epoch-0 tell without prompting?). The spatial loop-closure question (RM-04→RM-02) stays playtest-gated beside both contacts (IP-1 — amendment-ready, pre-gate no-op).

## Scope Tiers

| Tier | Included scope | Target timeline / team |
|---|---|---|
| MVP | 1 zone, 6 rooms, one story-truth-flip + backtrack reveal, Denial boss, combat core (combo/clash/deflect), cache + death counter, 3–4 memories, greybox visuals — **+ the 2026-11-14 expansion (D-1…D-7): the pause room-grid map, the MVP gear layer (named modules · two-slot loadout · the Warden drop behind the post-flip partition), the demonic gesture ability (Dash stays locked), the epistemic Epoch-0 tells, the low-stat baseline (≈20 HP, the SYS-07 rework sequenced ahead of the gear authoring), the 450 ms door working default** | **phased first contact** (re-est. 2026-11-14, producer): core-slice gate ~Jan 2027 → the expansion increment → the full gate ~Mar–Apr 2027 · ~55–70 dev-days · solo part-time + agent harness |
| Vertical Slice | One complete errand loop: court briefing → dive (7–8 rooms) → Anger boss → report → contract choice + essence spend | ~15–20 dev-days · 7–9 weeks solo part-time, starting after MVP gate 2 (est. VS gate Jun–Jul 2027) |
| Full Vision | Hub + 5 realities (~35–40 rooms), 5 self-bosses + demon lord + shapeshifter + 2–3 mini-bosses, 24 memories, 5 shift rules, ~10 contracts, story-revealing item, 2 endings, touch/keyboard/gamepad, MetSys map/minimap/fog-of-war, enemy bestiary | ~85–105 dev-days post-VS · ~12–18 months cumulative solo part-time, agent harness (est. 2028) |

*Post-launch / sequel hooks (Tier 3): evidence-withholding system (present or hide proof at court), SotN-style inverted re-tour, NG+, additional endings. Production doctrine: every asset works twice where the story says — mutated zones are one geometry, two palettes; zones the story never flips are single-truth (locked or unchanged); one rig, five grief states. Story is woven into gameplay and visuals, never narrated.*

## Risks

| Risk | Type | Mitigation or validation |
|---|---|---|
| Dual-reality rendering + mobile performance | technical | MetSys room instancing + palette-swap approach; build the shift shader first, week 1 of MVP |
| Emotional pacing by a first-time developer | design | Log-driven storytelling (anti-pillar); the surrender scene is short and scripted; playtest with 3–5 players |
| Clash-window tuning | design | Generous windows in MVP; tighten from playtest data |
| 7+ boss fights in 1–2 hours feels dense/repetitive | design | Mini-bosses are short arenas; grief bosses 2–4 minutes; every boss has a unique interaction rule |
| One rig across five bosses feels samey | design | State-driven movesets + reality-specific arena hazards, not new sprites |
| Mobile discoverability | market | Free itch.io demo → Steam page; "the boss that lowers her weapon" is the marketing hook |

## Visual Identity Anchor

**LOCKED 2026-11-08** — AD-CONCEPT-VISUAL verdict: STRONG (art-director gate, run via subagent). Direction selected by designer. To be formalized and expanded via `/art-bible`.

- **Direction name**: "Same Room, Two Truths" (+ two grafts: grief-tint washes from "Grief Made Geography"; diegetic serial numbers from "Chrome Reliquary")
- **One-line visual rule**: Same geometry, wrong world — a room's shape never changes, its truth always does; any screenshot must be nameable as demon-future (reality A) or magic-past (reality B) within 2 seconds
- **Supporting visual principles and design tests**:
  - Dual-palette doctrine: cold cyan/steel demon-tech (Warped City assets) vs. warm candlelit gothic (Gothicvania assets) — test: screenshot identifiable as A or B in 2 seconds
  - Shared silhouettes: the two truths share shape language — an arch is a bulkhead frame in A, a gothic arch in B; shape is memory, material is truth
  - The glitch is the signature VFX — test: shift transition stays readable at mobile framerates, no frame-rate-dependent tricks
  - One rig, five truths: each grief state changes contour-bearing elements (Denial: pristine + halo-frame; Anger: burning hair, raised weapon; Bargaining: half-disassembled with scaffolding; Depression: weapon lowered, posture collapsed; Acceptance: chrome stripped, true face) — test: name the state from a 32px-tall black silhouette, no color
  - Grief-tint washes: five errands = five tint layers applied over both truths (cheap tint passes, not new art)
  - Diegetic serial numbers: death counter stamped on her chassis, "MEMORY CACHED" as printed output, sigil-red strictly reserved for the demon lord's presence
- **Color philosophy**: Reality A: steel cyan/teal, desaturated slate, monitor-glow. Reality B: amber candlelight, wine red, aged parchment. Demon-sigil red appears only where the lord's influence is physically present (contracts, seals, his court) — never decoration. Neutral greys mark liminal/seam space.
- **Binding conditions from the AD gate (carry into `/art-bible`)**:
  1. Pack normalization: Warped City and Gothicvania never share a frame — one pack per reality; they meet only at seam/glitch transitions; normalization audit (single tile grid, shared outline color, harmonized saturation) before promotion from `inbox/`
  2. Mobile readability budget: ~480×270 base art resolution, one tile grid, integer scaling; enemies 2px value-separated from backdrops; telegraphs = color-flash + shape, never opacity pulses
  3. Silhouette-first grief states (as above) — palette-only variants would collapse at phone scale

## MDA Analysis

- **Primary aesthetic**: Narrative + Discovery (Challenge secondary)
- **Desired player emotion**: Catharsis through understanding, wrapped in the "slick and smart" mastery feeling
- **Dynamics that create it**: Backtrack reveals and reality-law rewrites create discovery and dread; clash timing creates tactical mastery; memory collection recontextualizes earlier areas; grief-stage bosses convert combat into story beats; contracts create identity tension
- **Mechanics that enable those dynamics**: committed combat + clash; reality-law mutations; memory pickups; cache stations + death counter; demon contracts

## Player Motivation Profile

- **Autonomy**: Backtrack route-finding through mutated zones, contract choices, optional memory detours, the final choice
- **Competence**: Telegraph-reading, clash timing, shift-rule mastery, revenge-rematch power arc
- **Relatedness**: Her — the woman you're copied from and trying to save; her father's messages; the court's false warmth
- **Primary player type**: Explorer-Storyteller (Discovery + Mastery + Fantasy motivations) — the SotN camp
- **Secondary appeal**: Achievers with taste for builds (Hades/DMC refugees who want their power trip framed by story)
- **Not for**: Twitch-platforming purists, pure competitors, cozy/sandbox players, helpless-horror fans
- **Market validation**: Bloodstained (RPG-MV audience at scale), Timespinner (time-travel MV), Ghost Song (android-protagonist MV), Grimvalor + Dead Cells mobile (touch-first action-MV viability). Niche: story-forward SotN-like built touch-first — proven audience, thin competition

## Flow State Design

- **Challenge-skill balance**: Telegraphs + optional clash = high skill ceiling, low floor; bosses escalate across errands; contracts let players tune their own difficulty
- **Clear goals**: Errand structure gives an explicit objective per reality; map % + memory counter serve completists
- **Feedback**: Hit-stop, clash sparks, glitch VFX, "MEMORY CACHED" text, incrementing name counter, memory chime, bestiary lore confirming understanding
- **Agency and focus**: Save rooms as sanctuaries (RE anchor); court reports as session bookends; backtrack exploration through mutated zones rewards curiosity without punishing progress

## Open Questions

- Visual identity: RESOLVED — anchor "Same Room, Two Truths" + grafts locked 2026-11-08 (AD verdict STRONG); concept-test renders are user-driven (`design/art/concepts/PROMPT-PACK.md`, results to `inbox/art-concepts/`); then `/art-bible` formalization
- Story-revealing item: name and exact mechanics (candidates: father's locket, optic implant, preserved brain resonance)
- Shapeshifter design: copies the player's moveset, or mimics her across grief stages?
- Does the demon lord ever address the player's death-counter number (e.g., "004") as a story hook?
- Engine version pin: RESOLVED — Godot 4.7.2 pinned 2026-11-11 (`/setup-engine` complete; reference docs verified)
- Defensive answer in combat now that shift tactics are gone: Dash i-frames vs clash-as-only-defense — decide in the combat GDD
- Zone-mutation budget: how many zones are dual-truth in Full Vision (mutation scoping doctrine)
- Stinger gesture details: touch quarter-spin tolerance window, keyboard ↓↘→ input buffer length
- License verification for all inbox packs before promotion to `assets/` (recorded in `assets/LICENSE-MANIFEST.md`)
