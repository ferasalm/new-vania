# Systems Index: Five Errands for the Devil

> **Status**: Approved
> **Created**: 2026-11-11
> **Last Updated**: 2026-11-11
> **Source Concept**: design/gdd/game-concept.md
> **Review mode**: lean — director gates (TD-SYSTEM-BOUNDARY, PR-SCOPE, CD-SYSTEMS) deferred to the phase gate per `production/review-mode.txt`
> **Design pivot applied 2026-11-11**: no on-command reality shift — world truth mutates through story progress + backtrack reveal ("Story-Driven Truth"); Stinger = motion input; touch scheme = Attack/Jump main, Dash (ability-unlocked), contextual Interact

## System Enumeration

| ID | System | Category | MVP? | Dependencies | Owner |
|---|---|---|---|---|---|
| SYS-01 | Input & Control Mapping | Foundation | Yes (partial) | None | game-designer + ui-programmer |
| SYS-02 | Room & World Structure (MetSys) | Foundation | Yes | None | lead-programmer |
| SYS-03 | Save & Serialization | Foundation | Yes | None | lead-programmer |
| SYS-04 | Audio Core | Foundation | Yes (minimal) | None | sound-designer |
| SYS-05 | Game Flow & Session Structure | Foundation | Yes (linear stub) | SYS-03 | game-designer |
| SYS-06 | Movement & Platforming | Core | Yes (Dash locked) | SYS-01 | game-designer |
| SYS-07 | Health & Damage | Core | Yes | None (data layer) | systems-designer |
| SYS-08 | Combat | Core | Yes | SYS-01, SYS-06, SYS-07 | game-designer |
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
| SYS-24 | HUD | Presentation | Yes (minimal) | SYS-08, SYS-07 | ui-programmer |
| SYS-25 | Map / Minimap / Fog-of-War | Presentation | No (VS) | SYS-02, SYS-10 | ui-programmer |
| SYS-26 | Sanctuary Menus (Inventory/Contracts/Essence) | Presentation | No (VS) | SYS-17, SYS-18, SYS-19 | ui-programmer |
| SYS-27 | Memory Gallery & Bestiary | Presentation | No (VS) | SYS-20, SYS-13 | narrative-director + ui-programmer |
| SYS-28 | Narrative Presentation | Presentation | Yes (2–3 logs) | SYS-05 | writer |
| SYS-29 | Juice & Feedback | Presentation | Yes (minimal) | SYS-08, SYS-06 | technical-artist + gameplay-programmer |
| SYS-30 | Endings & Final Choice | Polish | No (Full Vision) | SYS-05, SYS-19, SYS-22 | narrative-director |
| SYS-31 | Post-Launch Hooks | Polish | No (Tier 3) | SYS-30 | game-designer |

## Dependency Map

### Foundation

- SYS-01 Input & Control Mapping — no dependencies (Attack / Jump main; Dash = ability-unlocked; contextual Interact; unified across touch/KB/gamepad)
- SYS-02 Room & World Structure (MetSys) — no dependencies (16px grid, room graph, doors)
- SYS-03 Save & Serialization — no dependencies (world truth, designation counter, memories)
- SYS-04 Audio Core — no dependencies
- SYS-05 Game Flow & Session Structure — depends on SYS-03 (hub → briefing → dive → report → contract → spend; linear stub in MVP)

### Core

- SYS-06 Movement → depends on SYS-01 (committed SotN arcs; Dash is an ability gate — locked at start; traversal ladder Dash → Wall Jump → Double Jump as behavior-level gates on Jump; Backdash day-one, SotN-exact double-tap back)
- SYS-07 Health & Damage → no upstream deps (data layer for combat)
- SYS-08 Combat → depends on SYS-01, SYS-06, SYS-07 (combo, clash, deflect)
- SYS-09 Dual-Reality State & Rendering → depends on SYS-02 (epoch-driven: one geometry, two palettes; shift shader for transitions)
- SYS-10 World Mutation & Epochs → depends on SYS-09, SYS-03, SYS-02 (story-threshold truth flips; backtrack reveals; zone scoping/locking)
- SYS-11 Seam Borders → depends on SYS-10 (borders between flipped/unflipped zones; Cold Corridor purple = bridge material)
- SYS-12 Motion Input / Stinger → depends on SYS-01, SYS-08 (quarter-spin + Attack; gesture buffering across touch/KB/gamepad)
- SYS-13 Enemy AI & Telegraphs → depends on SYS-07 (per-reality behaviors, bestiary data)
- SYS-14 Grief-Boss Framework → depends on SYS-13, SYS-08 (one rig, five states, interaction rule per state)
- SYS-15 Cache Stations & Death-as-Story → depends on SYS-03, SYS-05 (MEMORY CACHED, reconstruction, designation increment)

### Feature

- SYS-16 Progression → depends on SYS-08, SYS-13 (lean RPG texture; ability unlock ladder: Dash → Wall Jump → Double Jump)
- SYS-17 Inventory & Items → depends on SYS-16
- SYS-18 Essence Economy → depends on SYS-16
- SYS-19 Demon Contracts & Corruption → depends on SYS-16, SYS-05
- SYS-20 Memory Fragments → depends on SYS-03, SYS-05
- SYS-21 Reality-Law Progression → depends on SYS-10, SYS-16 (one rewritten law per errand)
- SYS-22 Story-Revealing Item → depends on SYS-17, SYS-10 (gates true ending)
- SYS-23 Variety Bosses → depends on SYS-14 (shapeshifter, mini-bosses)

### Presentation

- SYS-24 HUD → depends on SYS-08, SYS-07 (red-disciplined per REVIEW.md)
- SYS-25 Map / Minimap / Fog-of-War → depends on SYS-02, SYS-10
- SYS-26 Sanctuary Menus → depends on SYS-17, SYS-18, SYS-19
- SYS-27 Memory Gallery & Bestiary → depends on SYS-20, SYS-13
- SYS-28 Narrative Presentation → depends on SYS-05 (logs, briefings, reports — text-only)
- SYS-29 Juice & Feedback → depends on SYS-08, SYS-06 (hit-stop, clash sparks, glitch transition, chime)

### Polish

- SYS-30 Endings & Final Choice → depends on SYS-05, SYS-19, SYS-22
- SYS-31 Post-Launch Hooks → depends on SYS-30 (NG+, inverted re-tour, evidence-withholding)

### Cycles and Bottlenecks

- Apparent cycle Combat ↔ Health — resolved by contract: Health & Damage is the data layer (HP pools, formulas), Combat is the behavior layer. No true cycle.
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
7. SYS-09 Dual-Reality State & Rendering
8. SYS-10 World Mutation & Epochs
9. SYS-11 Seam Borders
10. SYS-03 Save & Serialization
11. SYS-15 Cache Stations & Death-as-Story
12. SYS-13 Enemy AI & Telegraphs
13. SYS-14 Grief-Boss Framework
14. SYS-20 Memory Fragments
15. SYS-04 Audio Core
16. SYS-05 Game Flow & Session Structure
17. SYS-24 HUD
18. SYS-12 Motion Input / Stinger
19. SYS-16 Progression → SYS-17 Inventory → SYS-18 Essence → SYS-19 Contracts → SYS-21 Reality-Laws
20. SYS-25 Map/Fog → SYS-26 Sanctuary Menus → SYS-27 Gallery/Bestiary → SYS-28 Narrative
21. SYS-22 Story-Revealing Item → SYS-23 Variety Bosses → SYS-30 Endings → SYS-31 Post-Launch

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
| SYS-01 | Input & Control Mapping | MVP | Not Started | design/gdd/input-control-mapping.md |
| SYS-02 | Room & World Structure (MetSys) | MVP | Not Started | design/gdd/room-world-structure.md |
| SYS-03 | Save & Serialization | MVP | Not Started | design/gdd/save-serialization.md |
| SYS-04 | Audio Core | MVP | Not Started | design/gdd/audio-core.md |
| SYS-05 | Game Flow & Session Structure | MVP | Not Started | design/gdd/game-flow-session.md |
| SYS-06 | Movement & Platforming | MVP | Not Started | design/gdd/movement-platforming.md |
| SYS-07 | Health & Damage | MVP | Not Started | design/gdd/health-damage.md |
| SYS-08 | Combat | MVP | Prototype PROCEED 2026-11-11 — ready to author | design/gdd/combat.md |
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
| SYS-31 | Post-Launch Hooks | Full Vision | Not Started | design/gdd/post-launch-hooks.md |
