# Art Bible — Five Errands for the Devil

> **Status**: **DRAFT — authoring in progress.** No section is approved until its
> status row says APPROVED and the status header carries the AD-ART-BIBLE record.
> **Last Updated**: 2026-11-14
> **Author**: art-director (lane ART-BIBLE)
> **Implements Pillar**: all five — "One World, Two Truths" is the spine this
> document exists to protect; the pillar-coverage map is §1.
> **Visual Identity Anchor**: "Same Room, Two Truths" — *Same geometry, wrong
> world — a room's shape never changes, its truth always does.* LOCKED 2026-11-08
> (AD-CONCEPT-VISUAL, verdict STRONG). This bible formalizes the anchor; it does
> not re-open it.
> **Review mode**: `full` → AD-ART-BIBLE applies after the sections; then the
> lane's CD gate, three-seat panel, qa-lead spot-check, and micro-check.
> **Companion records**: `design/art/concepts/REVIEW.md` (the locked concept
> winners + the doctrine discoveries), `design/art/concepts/PROMPT-PACK.md` (the
> shot list), `design/art/palette.json` (§4B export).

## Decisions and rulings recorded in this document

| ID | Ruling | Date | Record |
|---|---|---|---|
| **D-ORCH-01** | **OPEN — proposed amendment only.** The package proposes B (amend SYS-02's Player Fantasy line 36 to *"a bridge of neither truth holding it together"*) and closing the purple. The text is **PROPOSED — pending user approval** in the lane report; **no SYS-02 edit is applied** (the premature edit was reverted in `8fbc13e`). The decision is recorded in `decisions.md` before any edit. SYS-11's tint machinery stays dormant regardless. | — | the ART-BIBLE lane report |
| **D-ORCH-02** | **Approved (lane-internal).** The `PROV_LIM_*` ramp: L 0.40 / 0.50 / 0.61 / 0.72, C 0.000 (`#484848` / `#636363` / `#838383` / `#A4A4A4`); the grief tint: L 0.66, C 0.14, h 345 (`#CD6CA6`), band [330, 20]; the fallback order F1 (relax the D-gap to ≥ 0.01) → F2 (close the tint). Gaps 0.098 / 0.110 / 0.109 ≥ 0.09 — no fallback triggered. | 2026-11-14 | the ART-BIBLE lane report; §4 |

## Section status

| § | Section | Status |
|---|---|---|
| 1 | Visual Identity Statement | DRAFT — pending user approval |
| 2 | Mood & Atmosphere | [To be designed — DRAFT] |
| 2B | VFX & Particle Style | [To be designed — DRAFT] |
| 3 | Shape Language | [To be designed — DRAFT] |
| 4 | Color System | DRAFT — pending user approval (the D-ORCH-02 pins are approved and recorded above) |
| 4B | Palette Export | [To be designed — DRAFT] |
| 4C | Typography Spec | [To be designed — DRAFT] |
| 4D | Visual Anchor Prompt | [To be designed — DRAFT] |
| 5 | Character Design Direction | [To be designed — DRAFT] |
| 6 | Environment Design Language | [To be designed — DRAFT] |
| 7 | UI/HUD Visual Direction | [To be designed — DRAFT] |
| 8 | Asset Standards | [To be designed — DRAFT] |
| 8B | Style Prohibitions | [To be designed — DRAFT] |
| 9 | Reference Direction | [To be designed — DRAFT] |

---

## 1. Visual Identity Statement

> **DRAFT — pending user approval.** The one-line rule + 3 principles + the pillar
> coverage map are drafted in the lane report (Deliverable 3, §3.1); the approved
> text lands here.

## 2. Mood & Atmosphere

> **[To be designed — DRAFT]** Nine state targets (A-exploration, B-exploration,
> the liminal wing, the arena, the court, the cache sanctuary, combat, the flip,
> death/reconstruct), each with emotion, lighting character, descriptors, energy.

## 2B. VFX & Particle Style

> **[To be designed — DRAFT]** The tear/glitch vocabulary, the telegraph grammar,
> the spark/chime/sting sets, the photosensitivity constraint, the frame-strip
> evidence standard, the no-new-hue-family rule.

## 3. Shape Language

> **[To be designed — DRAFT]** Silhouette philosophy, the 32 px grief test, the
> value inversion, the crown invariant, the rim-light rule, environment geometry,
> UI shape grammar.

## 4. Color System

> **DRAFT — pending user approval.** The A/B slot tables, the semantic vocabulary,
> the discriminator tests, and the colorblind backups; the D-ORCH-02 pins above are
> approved and are the section's fixed core.

## 4B. Palette Export

> **[To be designed — DRAFT]** `design/art/palette.json` — the machine-readable
> table for `/asset-spec` and the AI generation prompts.

## 4C. Typography Spec

> **[To be designed — DRAFT]** The diegetic print layer, the HUD text, the pixel
> font families and tiers at 480×270, the contrast floors.

## 4D. Visual Anchor Prompt

> **[To be designed — DRAFT]** `design/art/style-anchor-prompt.md` — the seed
> prompt for `/asset-spec`.

## 5. Character Design Direction

> **[To be designed — DRAFT]** Pandora-001, Lenore Vane, the demon lord, the grief
> rig (one rig, five truths), the enemy archetypes, the animation evidence standard.

## 6. Environment Design Language

> **[To be designed — DRAFT]** Architecture, pack normalization, texture
> philosophy, prop density, environmental storytelling (the tells), the room-type
> kit, the 480×270 / 16 px constraints.

## 7. UI/HUD Visual Direction

> **[To be designed — DRAFT]** The minimal HUD, the touch controls, the pause
> room-grid map, the sanctuary menus, accessibility. UX alignment check by
> `ux-designer`.

## 8. Asset Standards

> **[To be designed — DRAFT]** Naming, resolution/format, palette discipline,
> budgets, import settings, the pack promotion audit, the placeholder → PINNED
> upgrade path. Engine constraints by `technical-artist`.

## 8B. Style Prohibitions

> **[To be designed — DRAFT]** The not-do list, each prohibition with its parent
> (the anti-pillars, the REVIEW findings, SYS-11's not-do list).

## 9. Reference Direction

> **[To be designed — DRAFT]** 3–5 sources with take/avoid, plus the internal
> locked masters from `REVIEW.md`.
