# Systems Index: Five Errands for the Devil

> **Status**: Approved
> **Created**: 2026-11-11
> **Last Updated**: 2026-11-11
> **Source Concept**: design/gdd/game-concept.md
> **Review mode**: lean at creation — per-skill director gates **skipped** (lean runs phase gates only — `docs/framework/director-gates.md`; not deferred); switched to **full** 2026-11-11
> **Design pivot applied 2026-11-11**: no on-command reality shift — world truth mutates through story progress + backtrack reveal ("Story-Driven Truth"); Stinger = motion input; touch scheme = Attack/Jump main, Dash (ability-unlocked), contextual Interact

## System Enumeration

| ID | System | Category | MVP? | Dependencies | Owner |
|---|---|---|---|---|---|
| SYS-01 | Input & Control Mapping | Foundation | Yes (partial) | None | game-designer + ui-programmer |
| SYS-02 | Room & World Structure (MetSys) | Foundation | Yes | None | lead-programmer |
| SYS-03 | Save & Serialization | Foundation | Yes | None | lead-programmer |
| SYS-04 | Audio Core | Foundation | Yes (minimal) | None | sound-designer |
| SYS-05 | Game Flow & Session Structure | Foundation | Yes (linear stub) | SYS-03 | game-designer |
| SYS-06 | Movement & Platforming | Core | Yes (Dash locked) | SYS-01, SYS-02, SYS-16, SYS-05 | game-designer |
| SYS-07 | Health & Damage | Core | Yes | None (data layer) | systems-designer |
| SYS-08 | Combat | Core | Yes | SYS-01, SYS-06, SYS-07, SYS-13, SYS-29 | game-designer |
| SYS-09 | Dual-Reality State & Rendering | Core | Yes (one scripted flip) | SYS-02 | technical-artist |
| SYS-10 | World Mutation & Epochs | Core | Yes (scripted flip + backtrack reveal) | SYS-09, SYS-03, SYS-02 | game-designer |
| SYS-11 | Seam Borders | Core | Yes (one + VFX) | SYS-10 | game-designer + technical-artist |
| SYS-12 | Motion Input / Stinger Gesture | Core | No (demon-granted, VS) | SYS-01, SYS-08 | game-designer |
| SYS-13 | Enemy AI & Telegraphs | Core | Yes (2–3 types) | SYS-07 | game-designer |
| SYS-14 | Grief-Boss Framework | Core | Yes (Denial state only) | SYS-13, SYS-08 | game-designer |
| SYS-15 | Cache Stations & Death-as-Story | Core | Yes | SYS-03, SYS-05 | game-designer |
| SYS-16 | Progression (XP/Gear/Levels) | Feature | No (VS) | SYS-08, SYS-13 | systems-designer |
| SYS-17 | Inventory & Items | Feature | No (VS) | SYS-16 | game-designer |
| SYS-18 | Essence Economy | Feature | No (VS) | SYS-16 | economy-designer |
| SYS-19 | Demon Contracts & Corruption | Feature | No (VS) | SYS-16, SYS-05 | game-designer + narrative-director |
| SYS-20 | Memory Fragments | Feature | Yes (3–4 pickups + counter) | SYS-03, SYS-05 | narrative-director |
| SYS-21 | Reality-Law Progression | Feature | No (VS: first law) | SYS-10, SYS-16 | game-designer |
| SYS-22 | Story-Revealing Item | Feature | No (Alpha) | SYS-17, SYS-10 | narrative-director |
| SYS-23 | Variety Bosses | Feature | No (Alpha) | SYS-14 | game-designer |
| SYS-24 | HUD | Presentation | Yes (minimal) | SYS-08, SYS-07, SYS-01, SYS-06 (state read-only; no touch geometry), SYS-32 | ui-programmer |
| SYS-25 | Map / Minimap / Fog-of-War | Presentation | No (VS) | SYS-02, SYS-10 | ui-programmer |
| SYS-26 | Sanctuary Menus (Inventory/Contracts/Essence) | Presentation | No (VS) | SYS-17, SYS-18, SYS-19 | ui-programmer |
| SYS-27 | Memory Gallery & Bestiary | Presentation | No (VS) | SYS-20, SYS-13 | narrative-director + ui-programmer |
| SYS-28 | Narrative Presentation | Presentation | Yes (2–3 logs) | SYS-05 | writer |
| SYS-29 | Juice & Feedback | Presentation | Yes (minimal) | SYS-08, SYS-06 | technical-artist + gameplay-programmer |
| SYS-30 | Endings & Final Choice | Polish | No (Full Vision) | SYS-05, SYS-19, SYS-22 | narrative-director |
| SYS-31 | Post-Launch Hooks | Polish | No (Tier 3) | SYS-30 | game-designer |
| SYS-32 | Camera & Framing | Presentation | Yes (minimal) | SYS-01, SYS-02, SYS-06 | game-designer + gameplay-programmer |

## Dependency Map

### Foundation

- SYS-01 Input & Control Mapping — no dependencies (Attack / Jump main; Dash = ability-unlocked; Backdash day-one — double-tap back + a11y direct press; contextual Interact; unified across touch/KB/gamepad; **landscape-primary at MVP** — review ruling D-1, portrait = post-MVP re-audit; landscape safe-area floors sides 59 / bottom 48 / top 0; **D1 render model: world in a SubViewport at a safe-derived integer scale, HUD at native resolution**). Soft downstream: SYS-02/15 Prompt Slot; SYS-29 clock/haptics; SYS-12 VS. Backdash hop = `entry_sign` (D4: press1 must be a true back entry — a forward double-tap never fires; payload `(entry_sign)` only); Movement owns facing publication, sets facing = −`entry_sign` during the hop, and owns posture application during commitments (B2 handoff) + hop-lock rate. Crouch publishes raw (`latch ∨ held_zone`, never commitment-frozen). Pause-menu a11y actions synthesize ordinary input at the first Gameplay tick after the transition frame (EX-14). Coordination authority: SYS-05 owns the context state machine, input enforces gates. UX flag: `/ux-design` for the Recalibration screen + touch help overlay before UI stories
- SYS-02 Room & World Structure (MetSys) — no dependencies (16px grid, room graph, doors)
- SYS-03 Save & Serialization — no dependencies (world truth, designation counter, memories)
- SYS-04 Audio Core — no dependencies
- SYS-05 Game Flow & Session Structure — depends on SYS-03 (hub → briefing → dive → report → contract → spend; linear stub in MVP)

### Core

- SYS-06 Movement → depends on SYS-01 (committed SotN arcs; **Dash is an action-level lock — locked at start, TR-INP-003; Wall Jump → Double Jump are behavior-level gates on Jump owned by SYS-06, TR-INP-057**; Backdash day-one, SotN-exact double-tap back), SYS-02 (collision/stairs/slopes/one-way, hard at runtime), SYS-16 (grants, soft) and SYS-05 (coordination). **GDD `design/gdd/movement.md` — APPROVED (2026-11-12, diff-scoped re-review PASS 16/16; 15-site qa-lead spot-check; R1/R2/N1 non-blocking bookkeeping):** ADR-0001 contracts ratified (facing `value/epoch/cause/asserted_tick`, **re-asserted every `physics_tick` per R3/§8; the §10 cadence erratum remains pending under OQ-M2**, crouch handoff + posture-carry + `crouch_effective`, hop side + MVP drop-when-busy, `body_busy` locks incl. KNOCKBACK + `freeze_hold` + derived `worst_case_arc_ms` 1200, `grounded` publication, movement-zone ownership, body phase + `MotionCore`/`BodyPort`); 34 TR-MOV / 14 formulas / 49 ACs; the review loop is closed; OQ-M1 (SYS-01 press1-creep amendment) remains a one-clause edit before the first SYS-06 story
- SYS-07 Health & Damage → no upstream deps (data layer for combat)
- SYS-08 Combat → depends on SYS-01, SYS-06, SYS-07, SYS-13, SYS-29 (combo, clash, deflect; enemy strikes; hit-stop). **GDD `design/gdd/combat.md` — APPROVED (2026-11-12):** the creative seat (GLM-5.3-Flash) returned the feel memo "The Body Answers the Read"; the technical spine authored the arcs (ATK1 90/70/170, ATK2 100/80/250, crouch 80/60/150, air 80/70/120 + 100 ms landing lag), the clash matrix (contact-time pull; age gate 5–12 ticks; counter 1.5×; double lock 700 ms; lose 500 ms with no `KnockbackOrder`), the defensive family (backdash 140 / Dash 0 / clash 0 / getup 300), the five commitments (`worst_case_arc_ms` 800; combined 1200), the hit-stop table (70/90/40) and the SYS-07/SYS-13 boundaries; 34 TR-CMB / 12 formulas / 48 ACs; the three-seat design review returned NEEDS REVISION (technical 8 + QA 8 blockers; creative PASS); all blockers revised in-session; the **diff-scoped re-review** then found 2 revision regressions + 3 arithmetic/range defects (5 blockers) and 6 one-clause notes, all repaired in-session; **verdict PASS** (qa-lead spot-check 16/16 sites, 6/6 fixtures; machine audit 60/60); the post-review CodeRabbit pass found 4 more (the 800 ms consecutive-busy interval, the same-x `dir` fallback, the active-start edge case, AC-CMB-19's contact tick), all repaired; the review record is `design/gdd/reviews/combat-review-log.md`
- SYS-09 Dual-Reality State & Rendering → depends on SYS-02 (epoch-driven: one geometry, two palettes; shift shader for transitions)
- SYS-10 World Mutation & Epochs → depends on SYS-09, SYS-03, SYS-02, SYS-32 (story-threshold truth flips; backtrack reveals; zone scoping/locking; camera holds the target through the truth flip + reveal framing zone)
- SYS-11 Seam Borders → depends on SYS-10, SYS-32 (borders between flipped/unflipped zones; Cold Corridor purple = bridge material; reveal framing zone at seams)
- SYS-12 Motion Input / Stinger → depends on SYS-01, SYS-08 (quarter-spin + Attack; gesture buffering across touch/KB/gamepad)
- SYS-13 Enemy AI & Telegraphs → depends on SYS-07 (per-reality behaviors, bestiary data)
- SYS-14 Grief-Boss Framework → depends on SYS-13, SYS-08, SYS-32 (one rig, five states, interaction rule per state; boss-arena camera locks)
- SYS-15 Cache Stations & Death-as-Story → depends on SYS-03, SYS-05 (MEMORY CACHED, reconstruction, designation increment)

### Feature

- SYS-16 Progression → depends on SYS-08, SYS-13 (lean RPG texture; ability unlock ladder: Dash → Wall Jump → Double Jump — **grants flow SYS-16 → SYS-06's gates**: Dash action-level, Wall Jump/Double Jump behavior-level on Jump, TR-INP-057)
- SYS-17 Inventory & Items → depends on SYS-16
- SYS-18 Essence Economy → depends on SYS-16
- SYS-19 Demon Contracts & Corruption → depends on SYS-16, SYS-05
- SYS-20 Memory Fragments → depends on SYS-03, SYS-05
- SYS-21 Reality-Law Progression → depends on SYS-10, SYS-16 (one rewritten law per errand)
- SYS-22 Story-Revealing Item → depends on SYS-17, SYS-10 (gates true ending)
- SYS-23 Variety Bosses → depends on SYS-14 (shapeshifter, mini-bosses)

### Presentation

- SYS-24 HUD → depends on SYS-08, SYS-07, SYS-01, SYS-32 (touch dispatcher + hit-rect registration, z-order load-bearing; thumb-coverage caps from the camera; red-disciplined per REVIEW.md)
- SYS-25 Map / Minimap / Fog-of-War → depends on SYS-02, SYS-10
- SYS-26 Sanctuary Menus → depends on SYS-17, SYS-18, SYS-19
- SYS-27 Memory Gallery & Bestiary → depends on SYS-20, SYS-13
- SYS-28 Narrative Presentation → depends on SYS-05 (logs, briefings, reports — text-only)
- SYS-29 Juice & Feedback → depends on SYS-08, SYS-06, SYS-32 (hit-stop, clash sparks, glitch transition, chime; camera shake offset clamped to limits)
- SYS-32 Camera & Framing → depends on SYS-01 (D1 render model: world SubViewport at safe-derived integer scale, native HUD; camera reads no input), SYS-02 (room bounds = default limits), SYS-06 (facing/velocity/grounded/wall-cling/body-busy/backdash/knockback publication). Feeds SYS-29 (shake offset, clamped to limits; follow runs on the game clock), SYS-14 (boss-arena locks), SYS-10/11 (hold target through the truth flip; reveal framing zone), SYS-24 (thumb-coverage caps). **Working plan (user-accepted 2026-11-11, from the camera brief — playtest-tunable, GDD pending):** room limits first, in-room directors/false boundaries at VS only where a secret must sit inside a room; MVP = follow + small facing-keyed look-ahead with a commit delay (~32 px, frozen during attacks/backdash/knockback/hit-stop) + vertical move only on landing + long-fall look-down + 2 framing zones (Denial arena, backtrack reveal); focus objects VS (weight ≤ 0.4, never enemy lock-on); manual look up/down not planned (no ninth verb — TR-INP-004; down-zone = Crouch); zoom rejected through VS (breaks D1 integer scale, mobile fill-rate; cutscene zoom-in spike later). Engine feasibility items → godot-specialist / technical-artist at authoring. Source: the Inbound Shovel camera devlog + game-designer brief.

### Polish

- SYS-30 Endings & Final Choice → depends on SYS-05, SYS-19, SYS-22
- SYS-31 Post-Launch Hooks → depends on SYS-30 (NG+, inverted re-tour, evidence-withholding)

### Cycles and Bottlenecks

- Apparent cycle Combat ↔ Health — resolved by contract: Health & Damage is the data layer (HP pools, formulas), Combat is the behavior layer. No true cycle.
- Apparent cycle Combat ↔ Juice — resolved: SYS-08 → SYS-29 is **soft at design** (the hit-stop clock is a contract; a stub clock suffices for Combat authoring) and SYS-29 → SYS-08 is **soft** (read-only commitment state); the design order SYS-08 → SYS-29 stands.
- Apparent cycle World Mutation ↔ Seam Borders — resolved: Seam Borders are derived read-only from mutation state.
- **Bottlenecks (high-risk, many dependents):** SYS-08 Combat · SYS-02 Room Structure · SYS-09 Dual-Reality State · SYS-03 Save · SYS-10 World Mutation
- Leaf nodes (low risk, design late): SYS-23, SYS-25, SYS-27, SYS-30, SYS-31

## Recommended Design Order

1. SYS-01 Input & Control Mapping
2. SYS-06 Movement & Platforming
3. SYS-08 Combat
4. SYS-07 Health & Damage
5. SYS-29 Juice & Feedback
6. SYS-02 Room & World Structure (MetSys)
7. SYS-32 Camera & Framing
8. SYS-09 Dual-Reality State & Rendering
9. SYS-10 World Mutation & Epochs
10. SYS-11 Seam Borders
11. SYS-03 Save & Serialization
12. SYS-15 Cache Stations & Death-as-Story
13. SYS-13 Enemy AI & Telegraphs
14. SYS-14 Grief-Boss Framework
15. SYS-20 Memory Fragments
16. SYS-04 Audio Core
17. SYS-05 Game Flow & Session Structure
18. SYS-24 HUD
19. SYS-12 Motion Input / Stinger
20. SYS-16 Progression → SYS-17 Inventory → SYS-18 Essence → SYS-19 Contracts → SYS-21 Reality-Laws
21. SYS-25 Map/Fog → SYS-26 Sanctuary Menus → SYS-27 Gallery/Bestiary → SYS-28 Narrative
22. SYS-22 Story-Revealing Item → SYS-23 Variety Bosses → SYS-30 Endings → SYS-31 Post-Launch

> **Fast-lane note (approved 2026-11-11):** Prototype 1 (combat concept-test) runs BEFORE formal GDDs — it uses a bullet spec, not a GDD. Formal authoring via /design-system resumes with the systems that survive the prototype, in the order above.

## High-Risk Systems

| System | Risk / reason | Mitigation or validation |
|---|---|---|
| SYS-09 Dual-Reality State & Rendering | Technical — mobile perf with two truth states + transition shader | MetSys room instancing + palette-swap approach; **shift/transition shader experiment in week 1 of MVP** (per concept risk table) |
| SYS-10 World Mutation & Epochs | Design — does backtrack reveal actually land emotionally? | Prototype 2 (greybox MVP) validates the flip + reveal before any full production |
| SYS-08 Combat | Design — the game's #1 bet: committed SotN weight + clash timing | **Prototype 1 (combat concept-test) — runs first, before any GDD** |
| SYS-12 Motion Input / Stinger | Technical — touch quarter-spin tolerance; gesture feel | Defer to VS; prototype the gesture buffer in isolation if it feels bad |
| SYS-14 Grief-Boss Framework | Design — one rig, five states must not feel samey | State-driven movesets + arena hazards (concept doctrine); silhouette test per state (REVIEW.md) |
| SYS-02 Room Structure (MetSys) | Integration — third-party addon on pinned Godot 4.7.2 | Addon ships 4.7.2 binaries; smoke-test integration in MVP week 1 |

## Progress Tracker

| ID | System | Priority tier | GDD status | GDD path |
|---|---|---|---|---|
| SYS-01 | Input & Control Mapping | MVP | **UNFROZEN (2026-11-12 — #10 diff-scoped: PASS WITH RECORDED OBLIGATIONS; the review loop is CLOSED, capped at #10; one recorded one-clause obligation O1 (AC-18's stamp-budget head vs its parenthetical) with its verification route in the #10 log entry; ADR Acceptance and the QA plan's AC→gate ledger UNBLOCK on this record; **ADR-0001 Accepted 2026-11-12**; **QA plan's 96-unit ledger printed at 96 = 67+19+3+7 (carries O1)**)** — history: **enumerated repair #8 EXECUTED (2026-11-12, the fresh-session repair pass under CD's third targeted-repair authority): NB-F…NB-K landed exactly as pinned** (F-10 body term at the resolution tick, never F-05 · safe-area floor platform-scoped mobile-only/desktop-0 with AC-25/AC-66 aligned · scale-exempt-controls clause in F-06/AC-25 · TR-INP-076's freeze prohibition scoped to offers/acks/expiry + EX-15 (chip: decision at crossing, delivery at first unfrozen boundary, age frozen) · non-ack gate requests queue-and-apply at the next gate-entry phase · the haptics-on jank check anchored as AC-70's clause) **+ 8 pinned riders (R13 direction (a) — ceil inside F-06 · backdash-drop scoped rewrite + Q4 watch · Early-Press anchor "honored alike" · C2 AC-38 positive trace · C5 OQ#18 closed · C8 knob-row record · S_burst non-emptiness · `AXIS_BUTTON_THRESHOLD` named) + the machine cross-reference membership audit (full artifact in the review log). NB-K LEDGER SURGERY LANDED: the gate manifest and its mini-proof re-derived TOGETHER at 96 clause-units = 67 smoke + 19 device + 3 lock + 7 VS.** **Re-review #9 EXECUTED (2026-11-12, full panel, WHOLE document, 7 fresh seats + CD): NEEDS REVISION — TRIPWIRE FIRED branch (b) at 3 new blockers, ALL in UNTOUCHED text, ZERO in repaired text** (UX B1 the exposure inventory drops `CHIP_TAP_COMMIT` + `BACKDASH_BTN_TOGGLE` · PA B-1 AC-54's allocation-scope exclusivity falsified by the capture queue + the NB-J gate-request queue — CD-ruled UNTOUCHED, fix target = AC-54 · GP B1 L535's same-frame-drop blanket, the third PR-#15-species copy). qa-lead duties CONFIRMED (AC-32 trace three variants; ledger 96 = 67 smoke + 19 device + 3 lock + 7 VS re-derived from the manifest alone — the fourth deterministic derivation; NB-D remains CLOSED); machine audit VERIFIED (47 claims + the 35/10/2 tally reproduce; 15 spot-checks); proofs standing, no cause; **the #8 repair's text survived all seven seats clean.** **CD rulings: branch (b) — ONE FINAL ENUMERATED REPAIR in a FRESH session (fresh CD authority: the 3 blockers + 12 pinned riders; the machine-audit re-run adds the symbol-uniqueness stem + the event-class membership check) → #10 DIFF-SCOPED on that repair + audit verification only (fresh session, qa-lead spot-check mandatory, no tripwire) → the GDD UNFREEZES after #10 regardless of outcome — the adversarial loop is CAPPED, it ends by #10; any #10 blockers land as one-clause fixes verified by an audit re-run + qa-lead spot-check, recorded as explicit ADR/QA-plan obligations.** ADR Acceptance + the QA plan's AC→gate ledger unblock on the #10 record; Combat/Movement normative consumption of the crouch channel / posture handoff / gate manifest hard-gated; the ADR engine-probe spike remains permitted during the freeze. Earlier state — #8 full-panel NEEDS REVISION (tripwire at 6: NB-F…NB-K; qa-lead duties confirmed; 95-unit ledger identical — NB-D closed); #7 NEEDS REVISION (tripwire at 1: NB-E; convergence proofs 1–3 attached); #6 NEEDS REVISION (tripwire at 4: NB-A…NB-D, repaired in-session); #5 NEEDS REVISION (14 blockers + D1–D6, altitude law) — full history in design/gdd/reviews/input-control-mapping-review-log.md **FINAL ENUMERATED REPAIR EXECUTED (2026-11-12, fresh session): the 3 blockers + the 12 pinned riders (a)–(l) landed exactly as pinned, nothing else (UX B1 exposure inventory + EX-2 cross-cite · PA B-1 AC-54 six-structure bounded scope + measurand attribution · GP B1 L535 scoping + species-grep certification · AC-11 legal pair 64/6 + live-change re-validation, TR-INP-074 aligned · CLUSTER_GAP_DP rationale/V0 · center distances · F-01 old-60-tps label · AC-18 p99.9/max · duplicate knob row deleted · AC-70 breach pointer · AC-50 carve-out + item 13 · provenance demotions · F-04 release half · AC-63 Q4 drop-rate report · F-10 both-fail precedence); machine audit re-run attached to the review log (recorded stems + symbol uniqueness 55/55 + event-class membership); ledger unchanged at 96 = 67+19+3+7. Freeze continues — #10 diff-scoped is next.** | design/gdd/input-control-mapping.md |
| SYS-02 | Room & World Structure (MetSys) | MVP | Not Started | design/gdd/room-world-structure.md |
| SYS-03 | Save & Serialization | MVP | Not Started | design/gdd/save-serialization.md |
| SYS-04 | Audio Core | MVP | Not Started | design/gdd/audio-core.md |
| SYS-05 | Game Flow & Session Structure | MVP | Not Started | design/gdd/game-flow-session.md |
| SYS-06 | Movement & Platforming | MVP | **APPROVED (2026-11-12 — diff-scoped re-review PASS 16/16; 15-site qa-lead spot-check; R1/R2/N1 non-blocking bookkeeping; the review loop is closed; ADR-0001 contracts ratified; derived `worst_case_arc_ms` 1200; 34 TR-MOV / 14 formulas / 49 ACs; OQ-M1 remains a one-clause SYS-01 edit before the first story)** | design/gdd/movement.md |
| SYS-07 | Health & Damage | MVP | Not Started | design/gdd/health-damage.md |
| SYS-08 | Combat | MVP | **APPROVED (2026-11-12 — diff-scoped re-review PASS after an in-session 5-blocker repair + 4 post-review CodeRabbit repairs; qa-lead spot-check 16/16 sites, 6/6 fixtures; machine audit 71/71; 34 TR-CMB / 12 formulas / 48 ACs; Combat `worst_case_arc_ms` 800; 5 commitments; the ATK2 counter is reachable via the chain clash on a long-active power-1 heavy; review record `design/gdd/reviews/combat-review-log.md`)** | design/gdd/combat.md |
| SYS-09 | Dual-Reality State & Rendering | MVP | Not Started | design/gdd/dual-reality-state.md |
| SYS-10 | World Mutation & Epochs | MVP | Not Started | design/gdd/world-mutation-epochs.md |
| SYS-11 | Seam Borders | MVP | Not Started | design/gdd/seam-borders.md |
| SYS-12 | Motion Input / Stinger Gesture | Vertical Slice | Not Started | design/gdd/motion-input-stinger.md |
| SYS-13 | Enemy AI & Telegraphs | MVP | Not Started | design/gdd/enemy-ai-telegraphs.md |
| SYS-14 | Grief-Boss Framework | MVP | Not Started | design/gdd/grief-boss-framework.md |
| SYS-15 | Cache Stations & Death-as-Story | MVP | Not Started | design/gdd/cache-stations-death.md |
| SYS-16 | Progression (XP/Gear/Levels) | Vertical Slice | Not Started | design/gdd/progression.md |
| SYS-17 | Inventory & Items | Vertical Slice | Not Started | design/gdd/inventory-items.md |
| SYS-18 | Essence Economy | Vertical Slice | Not Started | design/gdd/essence-economy.md |
| SYS-19 | Demon Contracts & Corruption | Vertical Slice | Not Started | design/gdd/demon-contracts.md |
| SYS-20 | Memory Fragments | MVP | Not Started | design/gdd/memory-fragments.md |
| SYS-21 | Reality-Law Progression | Vertical Slice | Not Started | design/gdd/reality-law-progression.md |
| SYS-22 | Story-Revealing Item | Alpha | Not Started | design/gdd/story-revealing-item.md |
| SYS-23 | Variety Bosses | Alpha | Not Started | design/gdd/variety-bosses.md |
| SYS-24 | HUD | MVP | Not Started | design/gdd/hud.md |
| SYS-25 | Map / Minimap / Fog-of-War | Vertical Slice | Not Started | design/gdd/map-minimap-fog.md |
| SYS-26 | Sanctuary Menus | Vertical Slice | Not Started | design/gdd/sanctuary-menus.md |
| SYS-27 | Memory Gallery & Bestiary | Vertical Slice | Not Started | design/gdd/memory-gallery-bestiary.md |
| SYS-28 | Narrative Presentation | MVP | Not Started | design/gdd/narrative-presentation.md |
| SYS-29 | Juice & Feedback | MVP | Not Started | design/gdd/juice-feedback.md |
| SYS-30 | Endings & Final Choice | Full Vision | Not Started | design/gdd/endings.md |
| SYS-31 | Post-Launch Hooks | Post-Launch (Tier 3) | Not Started | design/gdd/post-launch-hooks.md |
| SYS-32 | Camera & Framing | MVP | Not Started (working plan recorded in the Dependency Map; GDD after the SYS-01 revision lands) | design/gdd/camera-framing.md |
