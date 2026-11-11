# PROTOTYPE - NOT FOR PRODUCTION
# Combat Concept-Test — "Five Errands for the Devil"

> Verdict: **PROCEED** (2026-11-11) — designer playtest positive; see Recommendation.

## Prototype Report: Combat Concept-Test (SotN-weight combat: combo + clash + deflect)

### Hypothesis

Committed SotN-weight combat — two-hit combo with real startup/recovery, the clash
(power-comparison parry), and projectile deflect — feels intrinsically rewarding on direct
controls. Measured: clash window fairness, combo buffer responsiveness, hit-stop impact
read, and the subjective "want to keep fighting after 10 dummy kills" test.

### Approach

- Greybox keyboard-first arena per `SPEC.md` (9 files, Godot 4.7.2, everything drawn in
  code, all feel constants in `tunables.gd`). Built in one focused session (~1 day equivalent).
- Shortcuts taken: no physics colliders (floor-snap + Rect2 overlap checks), duck-typed
  enemy calls via groups, no collision layers, local consts for small feel values,
  placeholder visuals. Prototype code is throwaway — production is written from scratch.
- Verification: headless boot + 600-frame unattended soak + 20s synthetic-input combat
  driver (combo cadence, clash branches, jump; deleted after the run) — zero script errors.

### Result

- Designer playtest session completed. Overall reaction: "nice. I like it."
- The tested mechanics landed: the designer's first request was MORE combat depth
  (a crouch layer), not less — the strongest signal a combat prototype can give.
- Automated soak observation: blind mashing counter-clash-stalls melee dummies out of
  their windups (clashes deal no damage per spec), so kills were slow and orb chip damage
  dominated. Emergent: counter-clash is currently a hard-stall tool. Not a defect for the
  question asked, but the combat GDD must decide whether counter-clash should also deal
  damage (SotN-style reward) or stay a pure interrupt.
- Phrase feedback (designer): the death popup "REBUILT — MEMORY CACHED" conflated two
  moments. Correct split per designer: **saving → "MEMORY CACHED"; continuing after
  death → "CACHED MEMORY DOWNLOADED"**. (SYS-15 already owns the save phrase; the
  continue-after-death phrase is new designer input.)

### Metrics

- Frame time: not instrumented (greybox, fixed 60 Hz physics; no hitch reported).
- Feel assessment (designer, one session): "nice. I like it." No window reported unfair;
  no request to speed up or slow down any tested timing.
- Player action counts: automated 20s soak — 1 dummy killed under blind mashing; orb chip
  dominated (steady −8 HP steps). Synthetic driver exercised combo chains, all clash
  branches, respawns, and orb hits without errors.
- Iteration count: 1 build iteration (one parse-bug fix); zero tuning passes needed before
  the designer enjoyed it.

### Recommendation: PROCEED

The game's #1 design bet survived contact: the designer enjoyed the loop enough to want it
deeper (crouch layer), confirmed the save/death phrasing lore, and asked for healing items
rather than questioning the core. All four success criteria answered "yes" — clash window
readable, combo buffer responsive, hit-stop reads as impact, wants to keep fighting.
Per SPEC.md: PROCEED → formal GDD authoring resumes (systems-index design order).

### If Proceeding

Production combat is written from scratch (prototype code never imports into production).
What changes:

- **Architecture**: data-driven combat config (no hardcoded feel), attack phases behind an
  input-buffered action system, data-driven enemy AI, clash resolution as a dedicated
  service rather than per-script branches.
- **Scope adjustments from playtest wants**:
  1. **Crouch + crouch attack + crouch-dodges-high-attacks** (SotN staple) — new combat
     verb spanning SYS-01 (input: touch down-press / keyboard), SYS-06 (crouch movement
     state), SYS-08 (low-profile evasion + high/low attack taxonomy), SYS-13 (enemies
     need designed high attacks).
  2. **Phrase routing**: save → "MEMORY CACHED"; continue-after-death → "CACHED MEMORY
     DOWNLOADED" — SYS-15 Cache Stations & Death-as-Story.
  3. **SotN-style healing items** — currently SYS-17 (Inventory & Items, Vertical Slice
     tier). Decision during GDD authoring: pull a minimal healing consumable into MVP, or
     design fully in VS. Leans MVP-minimal: one heal item is cheap and the designer
     explicitly wants it.
- **Estimated production effort**: combat GDD plus implementation across
  SYS-01/06/07/08/13 — the first real production epic.

### If Pivoting / If Killing

Not applicable — verdict is PROCEED.

### Lessons Learned

- Centralizing clash resolution in one `hurt()` entry point kept the five clash outcomes
  bug-free on first build — carry the pattern into production's resolution service.
- Math gotcha: ATK1 startup+active (0.16s) exceeds COMBO_BUFFER (0.14s) — presses in the
  earliest startup frames drop before the chain point. The combat GDD should define the
  buffer explicitly (e.g., "pressed within N s of the chain point", or lengthen it).
- Telegraph doctrine (color-flash + shape lean, never opacity pulses) was designer-legible
  at greybox fidelity — validates the art-bible binding condition early.
- Committed movement lock (no steering mid-swing) did not frustrate — supports the
  "committed weight" doctrine going forward.
- Mashing should not be the optimal strategy; the combat GDD needs an answer
  (counter-clash damage, or clash costs) — open question carried forward.
