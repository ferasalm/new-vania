# Art Bible — Five Errands for the Devil

> **Status**: **DRAFT — authoring in progress.** No section is approved until its
> status row says APPROVED and the status header carries the AD-ART-BIBLE record.
> **Last Updated**: 2026-11-14
> **Author**: art-director (lane ART-BIBLE)
> **Model**: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` — **GLM rerun
> (2026-11-14)**: the creative deliverables are (re-)authored on GLM per the user's
> hard rule (creative lanes = GLM; DS reserved for technical work). The DS-run
> draft prose is superseded where the creative voice matters; verified facts,
> contracts, and citations are kept. The prior text is preserved in git history
> (`218cdee`).
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
| **D-ORCH-02** | **PROPOSED — pending user approval** (re-classified by the GLM rerun to match `decisions.md`/`STATE.md`, which carry it as a user decision; the prior "approved in-session" recording did not satisfy that and nothing was ever written with a PINNED status). The `PROV_LIM_*` ramp: L 0.40 / 0.50 / 0.61 / 0.72, C 0.000 (`#484848` / `#636363` / `#838383` / `#A4A4A4`); the grief tint: L 0.66, C 0.14, h 345 (`#CD6CA6`), band [330, 20]; the fallback order F1 (relax the D-gap to ≥ 0.01) → F2 (close the tint). Gaps 0.098 / 0.110 / 0.109 ≥ 0.09 — no fallback triggered. The values are re-verified by the rerun (round-trips in the lane report §5). On approval the entries upgrade PLACEHOLDER → PINNED in place per SYS-09's TR-DR-002 placeholder rule. | — | the ART-BIBLE lane report (Deliverable 2); §4 |

## Section status

| § | Section | Status |
|---|---|---|
| 1 | Visual Identity Statement | DRAFT — pending user approval |
| 2 | Mood & Atmosphere | [To be designed — DRAFT] |
| 2B | VFX & Particle Style | [To be designed — DRAFT] |
| 3 | Shape Language | [To be designed — DRAFT] |
| 4 | Color System | DRAFT — pending user approval (the D-ORCH-02 pins are **proposed** and recorded above; re-verified by the GLM rerun) |
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

> **DRAFT — pending user approval.** The one-line rule is the locked anchor,
> verbatim; the three principles and the pillar map below are the GLM rerun's
> formalization. The D-ORCH-01 ruling paragraph finalizes after the user's
> decision.

### The one-line rule (LOCKED 2026-11-08, AD-CONCEPT-VISUAL — verdict STRONG)

> **Same geometry, wrong world — a room's shape never changes, its truth always does.**
> Any screenshot must be nameable as demon-future (reality A) or magic-past (reality B) within 2 seconds.

This bible formalizes the anchor; it does not re-open it.

### Principle 1 — The silhouette is the memory; the palette is the lie.

The player remembers a room by its bones: the arch rhythm, the doorway they misjudged, the stair they fell down once. We never touch the bones. Only the skin changes — steel becomes candlelight, a conduit route becomes a correct wall, the same window holds candle-glow where it held monitor-glow. The player's déjà vu is the product of this game; it only works if the shape stays perfectly loyal while the material betrays it. Every flip is a confidence trick played on a memory that was always true.

*Design test:* if a visual decision needs a new silhouette, a new prop, or a moved opening to read, it is not a material decision — reject it, or route it to SYS-02 as a geometry change.

*Pillar:* **One World, Two Truths.**

### Principle 2 — The eye reads value before it reads color.

At 480×270 and phone scale, hue is the first thing to die and the last thing to save you. So the reading order is fixed and non-negotiable: **value first** — a threat must separate from its backdrop by lightness before it may use color at all; **shape second** — contours are read in silhouette, not in detail; **hue last** — color is the seasoning on a dish that already tastes. Nothing that matters may depend on color alone; every danger, tell, and interactable must survive the grayscale test. Reward the second look — the SotN texture, the drop worth inspecting — but never require it for legibility.

*Design test:* at 3× device scale, one glance must name a threat's intent or a surface's anomaly. If it needs a second look to be *legible* (not to be *noticed*), raise value separation before adding color or detail.

*Pillars:* **Read, Then Strike**; **SotN, Not Hollow Knight.**

### Principle 3 — The world never beckons; it remembers.

No glow, pulse, highlight, unique hue, or fifth palette exists to direct attention. Nothing in this world raises its hand. Meaning is carried by material, repetition, and memory: the tells that were always there and resolve when the truth changes, the seam that never pretended, the diegetic print layer that stamps `MEMORY CACHED` on the machinery of grief. The player's attention is earned by consistency, not borrowed from effects — the world's quiet is what makes the two truths loud.

*Design test:* if an element exists to point (a highlight, a lit strip, a special color, a marker), delete it; if it exists to be remembered, keep it quiet, static, and consistent.

*Pillars:* **Five Goodbyes**; **One World, Two Truths**; **Remade Every Death** (via the diegetic print layer: "MEMORY CACHED", the serial numbers — diegetic, never HUD litter).

### Pillar coverage map (nothing dropped)

| Pillar | Where it binds |
|---|---|
| SotN, Not Hollow Knight | P2 · §5 (committed animation weight) · §6 (rooms worth re-touring, sanctuaries) |
| Read, Then Strike | P2 · §2B (telegraph grammar) · §5 (silhouette reads) |
| One World, Two Truths | P1 · §4 (the two tables + the liminal) · §6 (one geometry) |
| Five Goodbyes | P3 · §5 (one rig, five truths; the crown invariant) · §4 (the grief tint) |
| Remade Every Death | §2 (the death beat) · §4C/§7 (the print layer) · §5 (the body's reconstruction marks) |

### The D-ORCH-01 ruling (the seam's color law)

> **PENDING — the user decides.** The package (the lane report, Deliverable 1)
> proposes **B**: the liminal-grey reservation stands; no chromatic exception is
> ratified at MVP; the tint machinery stays dormant (schema + P1–P5+G + boot
> guards retained as the re-open gate); SYS-02's line 36 is amended to *"a bridge
> of neither truth holding it together"* under the recorded, user-approved
> contract revision. If the user ratifies **A** instead, this paragraph records
> the gated tint against the pinned ramp, the razor-window chroma band
> (source C 0.0333–0.0349), `ADM_ALPHA_MAX` 0.30, and the A1–A3 gates as the
> tint's permanent admission terms. Either way: the grey `PROV_LIM_*` default
> ships, the greys read quiet, not corrupted, and the grief tint remains the
> corridor's only free voice.

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
> **proposed (re-verified by the GLM rerun)** and are the section's intended core
> — they flip to the section's fixed core at the user's approval.

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
