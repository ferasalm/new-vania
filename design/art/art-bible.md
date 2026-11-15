# Art Bible — Five Errands for the Devil

> **Status**: **AUTHORED — the gate trail runs on this draft.** The user decisions
> D-ORCH-01/02 are recorded and applied (2026-11-15); the CD gate, the three-seat
> panel, the qa-lead spot-check, and the final micro-check gate this document
> before its PR merges. Section status table below carries the per-section state.
> **Last Updated**: 2026-11-15
> **Author**: art-director (lane ART-BIBLE)
> **Model**: `cloudflare-workers-ai/@cf/zai-org/glm-5.3-flash` (GLM — the lane's
> manifest model; creative lanes run GLM, DS is reserved for technical seats)
> **Implements Pillar**: all five — "One World, Two Truths" is the spine this
> document exists to protect; the pillar-coverage map is §1.
> **Visual Identity Anchor**: "Same Room, Two Truths" — *Same geometry, wrong
> world — a room's shape never changes, its truth always does.* LOCKED 2026-11-08
> (AD-CONCEPT-VISUAL, verdict STRONG). This bible formalizes the anchor; it does
> not re-open it.
> **Review mode**: `full` → AD-ART-BIBLE applies via the lane's CD gate; then the
> three-seat panel (creative GLM · technical DS · QA DS), the mandatory qa-lead
> spot-check on the repair diff, and the final micro-check.
> **Companion records**: `design/art/concepts/REVIEW.md` (the locked concept
> winners + the doctrine discoveries), `design/art/concepts/PROMPT-PACK.md` (the
> shot list + the 8-point validity checklist), `design/art/palette.json` (§4B
> export), `design/art/style-anchor-prompt.md` (§4D export),
> `design/gdd/reviews/art-bible-review-log.md` (the running review record).
> **Hard constraints this document enforces** (lane brief): one geometry, two
> palettes; the liminal ramp is epoch-invariant; the arena's pristine lie keeps
> its `epoch_pin: 0`; the greys read quiet, not corrupted; the purple is never on
> the threshold band, the north row, the fill, fixtures, or M4; **no new MVP
> prompt/VFX/audio is authorized by this bible** — §2B is a constraint pass over
> SYS-29/SYS-09's existing vocabulary, not a content grant.

## Decisions and rulings recorded in this document

| ID | Ruling | Date | Record |
|---|---|---|---|
| **D-ORCH-01** | **APPROVED — B (2026-11-15).** SYS-11's OQ-1 resolves to the liminal-grey reservation: **no chromatic exception is ratified at MVP; the purple bridge is declined** (revisitable at the asset-spec pass under the re-open gate below). The tint machinery stays dormant (schema + P1–P5+G + the boot guards retained as the re-open gate — nothing is deleted). SYS-02's Player Fantasy line 36 is amended *"a purple bridge holding it together"* → *"a bridge of neither truth holding it together"* (the recorded proposal text; the executing commit `5cc1377` names D-ORCH-01; exactly one line changed). The SYS-11 index-row qualification is a **sync rider** (the OQ-M1 pattern) — recorded in the lane report; the sync lane applies it. The grey `PROV_LIM_*` default ships. | 2026-11-15 | `production/orchestration/decisions.md` D-ORCH-01 · the executing commit `5cc1377` |
| **D-ORCH-02** | **APPROVED as proposed (2026-11-15).** The four `PROV_LIM_*` L values (with `gap_R ≥ 0.09`), the grief tint's C/L, and the grief hue band [330, 20] stand as specified; the entries upgrade **PLACEHOLDER → PINNED in place** per SYS-09's TR-DR-002 placeholder rule (§4). The pinned set: ramp L 0.40 / 0.50 / 0.61 / 0.72 at C 0.000 (`#484848` / `#636363` / `#838383` / `#A4A4A4`); the grief tint L 0.66 · C 0.14 · h 345 (`#CD6CA6`), band [330, 20]. Quantized gaps 0.098 / 0.110 / 0.109 ≥ 0.09 — **no fallback triggered** (F1 relax-to-0.01 → F2 close-the-tint remain the recorded order; F3 "re-pin the ramp to rescue the tint" is forbidden). | 2026-11-15 | `production/orchestration/decisions.md` D-ORCH-02 · §4 |

## Section status

| § | Section | Status |
|---|---|---|
| 1 | Visual Identity Statement | **AUTHORED** — the one-line rule is the locked anchor; P1–P3 + the pillar map are the lane's formalization; the D-ORCH-01 ruling is **final** (recorded above) |
| 2 | Mood & Atmosphere | AUTHORED — the nine state targets + the three atmosphere laws |
| 2B | VFX & Particle Style | AUTHORED — the constraint pass over SYS-29/SYS-09's vocabulary |
| 3 | Shape Language | AUTHORED — silhouette philosophy, the grief test, the invariants |
| 4 | Color System | AUTHORED — the slot tables, the D-ORCH-02 pins (**PINNED**), the semantic vocabulary, the discriminator tests |
| 4B | Palette Export | AUTHORED — `design/art/palette.json` (JSON only; the recorded default) |
| 4C | Typography Spec | AUTHORED — the diegetic print layer, the pixel tiers at 480×270 |
| 4D | Visual Anchor Prompt | AUTHORED — `design/art/style-anchor-prompt.md` |
| 5 | Character Design Direction | AUTHORED — the four anchors + the grief rig + the evidence standard |
| 6 | Environment Design Language | AUTHORED — the duality, the pack normalization, the tells, the room kit |
| 7 | UI/HUD Visual Direction | AUTHORED — the minimal HUD, the touch surfaces, the a11y baseline |
| 8 | Asset Standards | AUTHORED — naming, format, budgets, the upgrade path |
| 8B | Style Prohibitions | AUTHORED — the not-do list, each with its parent |
| 9 | Reference Direction | AUTHORED — 5 sources with take/avoid + the internal locked masters |
| 10 | `/asset-spec` handoff | AUTHORED — the lane's handoff list (the lane brief obligation 5) |

---

## 1. Visual Identity Statement

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

### The D-ORCH-01 ruling (the seam's color law) — FINAL

The liminal-grey reservation stands; **no chromatic exception is ratified at MVP; the purple bridge is declined.** The grey `PROV_LIM_*` ramp ships as the corridor's whole material voice, epoch-invariant, and the greys read quiet, not corrupted. The grief tint remains the corridor's only free voice — M4's anchor, the player's truth in a place that belongs to the world's.

The tint machinery (the `SeamBorderContract`'s `tint` field, the P1–P5+G admission predicate, the version/staleness boot guards) is retained **dormant** — it is the re-open gate, not dead code. A future ratification requires all three keys at once: (i) the P1–P5+G admission passing against the then-current palette data with a CI-produced admission record, (ii) `PURPLE_ENABLED` true, and (iii) an explicit user decision amending this ruling. The verified A-path data is recorded in §4 (the razor chroma window, the tint family, the feasible hue interval, `ADM_ALPHA_MAX` 0.30) so a revisit starts from numbers, not from scratch. The declined purple is **revisitable at the asset-spec pass** — the same three keys, then; never by silent edit. Either way, the admitted placement bounds are permanent: the purple is never on the threshold band, the north row, the fill, fixtures, or M4 (TR-SMB-005's absolute bound, consumed verbatim).

SYS-02's Player Fantasy line 36 now reads *"a bridge of neither truth holding it together"* (the user-approved contract revision D-ORCH-01, applied at commit `5cc1377`). The SYS-11 index-row qualification rides the sync lane (the OQ-M1 pattern — the lane report carries the exact diff).

## 2. Mood & Atmosphere

Nine state targets. Each names the emotional target, the lighting character (key direction, temperature, contrast), 3–5 atmospheric descriptors, and an energy level. Two of the nine — the arena and the liminal wing — are the places the world *performs*; they get the tightest bars.

| # | State | Emotion (the target) | Lighting character | Descriptors | Energy |
|---|---|---|---|---|---|
| 1 | **A-exploration** (epoch 0) | Clinical reverence — a sacred place repurposed by something that does not worship | Cool key from monitor strips + A_GLOW; low-contrast ambient, high local contrast at glow edges; no warm light anywhere | sterile, museum-clean, humming, slate, watchful | measured, quiet |
| 2 | **B-exploration** (post-flip) | Home that is wrong now — warmth as accusation | Warm key from candle pools + B_GLOW; gentle falloff, soft shadows; the same corners the monitor light never reached now hold amber | candlelit, gothic, incense, wax, aged | measured, hushed |
| 3 | **The liminal wing** (post-E4) | The honest joint — neither truth, still, older than the argument | **No key.** Sourceless pale light, mild vertical falloff (brighter deep end, VR-SMB-06's plane-not-glow); the ramp IS the only light model | plain, even, coursing, sourceless, quiet | still |
| 4 | **The arena** (the Denial fight) | The pristine lie — a pocket that pretends the flip never happened | A's own lighting at full fidelity: cleaner, brighter, *more* A than the world around it (it is the lie's over-fidelity that betrays it on the second look) | pristine, symmetrical, scuffed-floor tell, halo-bright, sealed | combat pace |
| 5 | **The court** (demon lord's hub; VS-era for full dressing) | Dread dressed as hospitality | Sigil-red key surfaces (banners, seals, floor circuitry) against cold steel-cyan ambient; red is *earned* here (REVIEW finding 5) | cathedral-scale, chrome saints, circuitry, branded, quiet-danger | deliberate |
| 6 | **The cache sanctuary** | Safety with a price printed on it | Cyan pool from the terminal/reliquary; the one room where light pools deliberately and still reads earned (it is the fiction's machine) | reliquary, printed, cable-ceremonial, white-blue brain glow, reverent | restful |
| 7 | **Combat** (any truth) | Readable violence | The truth's own key; telegraphs carry the extra contrast (color-flash + shape), the world's contrast budget never moves for combat | committed, weighty, high-contrast on threats only | sharp |
| 8 | **The flip** (the held breath) | The world stops arguing | Desaturation to grey-white over the freeze (MAG 0.6), the tear's cyan accent, the strobe's one neutral beat — then the new truth lands whole | torn, desaturated, held, scanlined, atomic | suspended |
| 9 | **Death / reconstruct** | Death is story, not a penalty screen | Desaturation + the death sting's band (by `overkill_ratio`); the reconstruct is SYS-15's fiction — the body reassembles where the world can see it | cold print, counter ticking, offline, re-membered | slow, then released |

**Atmosphere laws (binding on every state):**

- **The key-light direction law.** Key light falls from above in truth A (monitor strips, ceiling racks) and from *beside* in truth B (candle pools at their holders' height — sconces, stands, the altar). The flip therefore also changes the *direction* of shadow, not only its temperature — one more material-level proof the world changed. No state introduces a third key direction.
- **The contrast budget.** The world renders inside a fixed value envelope per truth (A: void-to-frame ≈ L 0.21 → 0.74; B: void-to-frame ≈ L 0.21 → 0.81, §4 tables). Threats, telegraphs, and interactables get their contrast by *their own* value/color treatment (§2B), never by pushing the room's envelope. The arena is the sole licensed exception in the *other* direction: it may run *cleaner* (higher fidelity, lower ambient grime) than its zone — that is how the pristine lie reads.
- **The "quiet, not corrupted" bar (SYS-09's TR-DR-012, consumed verbatim).** The liminal wing's material grammar is stripped of both packs' detail: plain even coursing, sourceless pale light, desaturated clear of both truths' glows. It must read as *an honest place*, never as a rendering failure. The F3 anti-code bar applies here as much as in the arena: if a cold viewer says "buggy / didn't load / looks broken", the pass fails.

## 2B. VFX & Particle Style

**Scope law: this section authorizes no new MVP prompt/VFX/audio.** It is the style contract for the vocabulary SYS-29 (juice), SYS-09 (the flip), SYS-13 (telegraphs) already own. Every effect below cites its owning contract; where this section and the owning GDD disagree, **the owning GDD wins** and this section records the correction.

**The glitch is the signature, never the wallpaper.**

- **The tear/glitch vocabulary** (SYS-09 TR-DR-006 / F-DR-04, consumed verbatim at `FLIP_GLITCH_MAG` 0.6): tear displacement 5 art px (hard cap 8, never tile-aligned), desaturation depth 0.6, channel jitter 2 px, scanline spacing 4 art px (static per frame — no scrolling), scanline alpha 0.36, the cyan tear accent (`PROV_GLITCH_ACCENT`, 1-art-px jagged line, alpha 0.9) at the tear edges. One choreography-anchored strobe beat at τ0 (neutral scanline flash over desaturated content, one wall tick, no red channel); the aftershock rule per F-DR-04's clamp (off at the default MAG). The wing receives the tear like the rest of the world — it is part of the fault, and making it the tear's epicenter is the rejected flourish (TR-DR-012).
- **`REDUCED_FLASH` visual set:** zero beats, zero jitter, one static tear band (4 art px minimum) visible through the hold, desat unchanged, logic trace bit-identical. This is an art constraint, not a settings afterthought — every VFX spec must name its REDUCED_FLASH variant.
- **The photosensitivity law as an art constraint:** ≤ 3 flashes/s (SYS-29's law); no flash frequency ever scales with glitch magnitude (F-DR-04 amplitude-only); the strobe's neutral beat uses no red channel.
- **Juice vocabulary** (SYS-29's, style-only constraints): hit sparks = the double-beat pair (contact + midpoint at +21 logic ticks) drawn in the truth's steel-cyan (A) / amber (B) families — **no new hue family in VFX**; damage numbers = world-space, zero-frame, 7 px floor (the print layer, §4C); heal shimmer = soft value lift in the truth's glow family; the memory chime's visual is SYS-20/29's grant cue; the death sting scales by `overkill_ratio` band — strike deaths stay quiet by design.
- **The telegraph grammar** (locked AD condition; SYS-13's closed list): telegraph = **color-flash + shape, never opacity pulses**. The flash color comes from the owning truth's table (A cold cyan family, B amber family); the shape carries the attack's identity (§3's silhouette rules). An opacity pulse is a prohibition (§8B) — it dies at phone scale and it lies about timing.
- **The evidence standard (REVIEW doctrine 4):** animation/VFX claims require **frame strips** (anticipation → strike → recovery, ≥ 3 frames), never single-frame GIFs. VFX sheets ship with their frame strips or they are not reviewed.
- **The seam is VFX-free** (SYS-11 TR-SMB-006/011): zero VFX, zero glow, zero dither, zero animation on the band, the frame, or the fill. The corridor's only effects are the world's own tear passing through it.
- **Full-RGB exemption:** the glitch band's RGB-shifted strips are the one place outside palette discipline (REVIEW Shot 2 note) — the signature VFX is allowed to break the palette *inside the tear*, for the tear's duration only. Nothing else borrows the exemption.

## 3. Shape Language

**Character silhouette philosophy — every silhouette names itself at 32 px, no color.**

- **The 32 px grief test** (the locked AD condition; the concept's test 3): at 32 px tall, as a solid black silhouette, a cold viewer names the grief stage uncaptioned. The per-state contour rules (§5) are the rig's answer; palette-only variants are forbidden — they collapse at phone scale.
- **Value inversion (REVIEW doctrine 1):** Pandora dark-body / light-head; Lenore light-body / dark-head. The two women are unambiguous at a glance, in either reality, before any color is read.
- **The crown invariant (REVIEW doctrine 2, adopted):** the crown persists across all five grief states, cracked differently per stage. One anchor per state fixes the same-woman failure the concept round caught.
- **The rim-light rule (REVIEW doctrine 6):** near-black bodies on dark rooms carry a 1-px rim in the truth's glow family, on the side facing the key. This is value separation, not decoration — it is what keeps Pandora's dash from vanishing (the REVIEW finding on `pandora-001-dash`).
- **Committed poses:** SotN weight — loaded stances, planted follow-through, decaying trails (REVIEW's animation accepts). No neutral A-poses; no weightless floats.

**Environment geometry — one geometry, two dialects.**

- Truth A: strictly rectilinear 90/45° geometry; pointed gothic arches *rendered as* cold bulkhead frames; server monoliths where pews would stand (PROMPT-PACK shot 1A's material list).
- Truth B: the same 90/45° bones rendered as carved gothic — the same arch rhythm, the same openings, candlelit stone, choir stalls, banners (PROMPT-PACK shot 1B's edit list).
- The shared-geometry rule is absolute (REVIEW Shot-1 pair verdict): arch rhythm, back wall, foreground furniture, camera eye-line do not drift between truths. A screenshot of the same room at both epochs, overlaid, must align to the pixel.
- **Hero shapes vs supporting shapes:** arches, doorways, and the stair runs are hero shapes (learnable, re-tourable); rivets, pipes, candles, debris are supporting texture (≤ 2 values per tile, §6). Hero shapes never trade silhouette for detail.

**UI shape grammar.** The interface is a pane of glass over the world, not a second game: rectangular panels with the print layer's hard 1-px edge (§4C), no skeuomorphic chrome, no rounded-glass panels. The HUD's shapes are rectangles and ticks; the map's shapes are the room graph's own rects (SYS-25's discovered cells). UI echoes the world through its *type and edge*, not through ornament.

## 4. Color System

**The slot structure is SYS-09 TR-DR-002's, consumed verbatim:** one table, three groups — the reality-A slots, the reality-B slots (`B_SEAL` dormant at MVP per OQ-DR-8), and the liminal ramp — plus `PROV_GLITCH_ACCENT` (the tear accent; SYS-29 consumes the name), `PROV_GRIEF_TINT` (overlay anchor, not a member), and `PROV_SIGIL_RED` (**reserved, not a member** — lord presence only). Every entry carries `{hex, status, source}`. **The isomorphism law:** both truths fill the same slot list at the same placements — a re-skin is a table swap over unchanged coordinates, never a redraw; `FRAME` is the shape-carrier exemplar.

**Status semantics:** `PINNED` = user-approved via a recorded decision (the greybox MVP may ship it); `PLACEHOLDER` = legal through the greybox MVP, PINNED required before content ship (SYS-09's placeholder rule — the owning pack's nearest existing tone, value band first); `RESERVED` = not a table member; a hex exists only as the recorded candidate for the owning pass.

### 4.1 The liminal ramp — **PINNED** (D-ORCH-02)

The corridor's whole material voice: a pure value ladder with **no hue at all** (C 0.000). Achromatic is the emotional argument *and* the normative read of VR-SMB-01 ("one shared hue **or none**", C ≤ 0.008): any hue belongs to somebody — a cool bias leans A, a warm bias leans B; a pure ladder is the only material provably neither truth, and it cannot drift toward a truth under the hue-swap test. It keeps VR-SMB-10's membership exact (4 members + 4 derived course shades, no hue family) and makes AC-SMB-21's ≥ 4/5 "neither" read a property of the paint.

| Name | OKLCH (source of truth) | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_LIM_DEEP` | L **0.40** · C **0.000** | `#484848` | **PINNED** (D-ORCH-02) | SYS-09's ramp + VR-SMB-01's ladder; round-trip verified | step 0; the frame at offset −1 |
| `PROV_LIM_MID` | L **0.50** · C **0.000** | `#636363` | **PINNED** (D-ORCH-02) | same | step 1; the band + north pin (`SEAM_BAND_STEP` = MID) |
| `PROV_LIM_PALE` | L **0.61** · C **0.000** | `#838383` | **PINNED** (D-ORCH-02) | same | step 2 |
| `PROV_LIM_LIGHT` | L **0.72** · C **0.000** | `#A4A4A4` | **PINNED** (D-ORCH-02) | same | step 3; the terminal plane — the corridor's value maximum (VR-SMB-06) |

**The gap check (`gap_R ≥ 0.09`) — verified, no fallback triggered.** Source ΔL 0.100 / 0.110 / 0.110; quantized (8-bit round-trip) **0.098 / 0.110 / 0.109** — all ≥ 0.09, so F-SMB-05's P2 guarantee (`ADM_L_GAP_MIN` 0.05 + 2 × `ADM_L_TOL` 0.02 = 0.09) holds with margins +0.008 / +0.020 / +0.019. **OQ-4's conditional is therefore not exercised:** the D-gap clause does **not** relax, and the tint does not close on gap grounds — recorded per the lane brief's obligation 3. Contrast ratios (relative luminance): DEEP→MID 1.52 · MID→PALE 1.58 · PALE→LIGHT 1.52 · DEEP→LIGHT 3.67 — an even ladder, no compressed step. If a future harness's conversion reports DEEP→MID < 0.09, the pre-agreed remedy is DEEP L 0.395 (`#474747`) — a one-value change, no design change.

**Ramp laws:** epoch-invariant (TR-DR-012 — the wing does not re-skin); the ramp is the wing's *only* light model (VR-SMB-02 — zero dither/gradient/noise; steps on tile-row boundaries only); coursing is the only texture (VR-SMB-03 — one 1 px course line per 16 px tile at ΔL −0.05, same hue, a derived shade **not a member**); max 2 values per tile; the ramp's hexes live in the palette data file, never as literals in code (AC-DR-02's literal-grep).

### 4.2 The grief tint — **PINNED** (D-ORCH-02)

| Name | OKLCH (source of truth) | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_GRIEF_TINT` | L **0.66** · C **0.14** · h **345** | `#CD6CA6` | **PINNED** (D-ORCH-02) | SYS-09's overlay anchor + VR-SMB-07's range; round-trip verified (0.6602, 0.1402, 344.8°) | M4's anchor only; P5's input |

- **The hue band [330, 20] (circular) is the binding constraint** (D-ORCH-02); h 345 is the pinned member inside it. The recorded alternative if the rose should read redder: h 355 → `#D36A96` (verified round-trip 0.6595, 0.1404, 355.2°) — same C/L, P4 still passes. Switching members inside the band is an art-bible edit, not a decision.
- **Value rationale:** L 0.66 clears `PROV_LIM_PALE` (0.61) by +0.05 and stays below `PROV_LIM_LIGHT` (0.72) by 0.06 — the pale terminal plane remains the corridor's value maximum; M4's body at L ≤ 0.50 reads dark against its own glow (≥ 2 steps vs LIGHT, VR-SMB-07).
- **Separation rationale:** 345° sits 70° from the tint's admissible hue (275°), 85–95° from B's amber/candle hues, and distinct from A's cyan/teal by construction. Its distance from wine red and the reserved sigil red is carried by **value** (L 0.66 glow against dark fabric/seals) — recorded explicitly, because the band and the red family are neighbors by construction and hue alone cannot carry the distinction.
- **VR-SMB-07's usage bounds, consumed verbatim:** C 0.12–0.18 · L 0.55–0.68 (below LIGHT) · ≤ 1/3 of M4's lit pixels · ≤ ~1% of the wing's area · zero spill · no additive/bloom/halo/pulse · M4's anchor only · M4's body L ≤ 0.50 against LIGHT (≥ 2 steps) · **the five-errand grief wash excludes the seam region** (epoch-invariance + the one-color law both break otherwise).

### 4.3 The tear accent — PLACEHOLDER (companion)

| Name | OKLCH | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_GLITCH_ACCENT` | L 0.783 · C 0.136 · h 210 | `#00CFE8` | PLACEHOLDER (companion — pinned at the §8 content-ship gate) | the art-bible pass; the tear's cyan (SYS-09 TR-DR-002's name; SYS-29 consumes) | the tear's 1-px edges at α 0.9 (F-DR-04); no other use |

### 4.4 The reserved red — not a member

| Name | OKLCH | Hex | Status | Source | Rule |
|---|---|---|---|---|---|
| `PROV_SIGIL_RED` | — (candidate L 0.49 · C 0.19 · h 21 at `#B3122E`) | — | **RESERVED** | SYS-09 TR-DR-002: recorded as reserved, **not a member** | the lord's physical presence only: his sigils, seals, contracts, his granted Stinger, and the court's own canonical red (banners, floor seal — court decoration *is* earned red, REVIEW finding 5). Zero occurrences across both epochs' MVP replays (AC-DR-02). The exact hex pins at the court pass (VS-era dressing) |

### 4.5 The A/B slot tables — PLACEHOLDER (pending the pack promotion + normalization audit)

The 16 slot hexes below are **PLACEHOLDER**, sourced from the locked concept masters' dialect bands (PROMPT-PACK shots 1A/1B; REVIEW's locked selections) because the owned packs (Warped City / Gothicvania) are not yet promoted (`assets/source` is empty; the normalization audit has not run). On promotion, each slot upgrades to the owning pack's nearest existing tone — value band first (SYS-09's placeholder rule) — and the table re-passes the discriminator tests. **The slot list, placements, and value bands are already binding**; the pack audit changes hexes, never the structure.

| Slot | OKLCH (L · C · h) | Hex | Status | Source | Notes |
|---|---|---|---|---|---|
| `PROV_A_WALL` | 0.342 · 0.024 · 244 | `#2E3A44` | PLACEHOLDER | concept master 01a dialect band | the backdrop body; cool-dominant |
| `PROV_A_FLOOR` | 0.432 · 0.023 · 243 | `#46525C` | PLACEHOLDER | same | ≥ 2 steps clear for entities (value zoning) |
| `PROV_A_TRIM` | 0.580 · 0.029 · 239 | `#6B7D8A` | PLACEHOLDER | same | conduits, rails, racks' frames |
| `PROV_A_FRAME` | 0.741 · 0.025 · 236 | `#9DAEB9` | PLACEHOLDER | same | the bulkhead frame edges — the shape-carrier exemplar slot |
| `PROV_A_GLOW` | 0.773 · 0.110 · 210 | `#4FC8DC` | PLACEHOLDER | same | **A's largest chroma area** (monitor-glow); the discriminator's cool anchor |
| `PROV_A_HAZARD` | 0.893 · 0.107 · 207 | `#7DF0FF` | PLACEHOLDER | same | the cold flash — brightest value in A; pairs with shape (§2B) |
| `PROV_A_VOID` | 0.214 · 0.013 · 244 | `#141A1F` | PLACEHOLDER | same | the unlit read |
| `PROV_A_SEAL` | (the reserved red) | — | PLACEHOLDER — **dormant at MVP** | the sigil-red binding (§4.4) | renders only where the lord's presence is physically in an A frame; zero MVP occurrences |
| `PROV_B_WALL` | 0.349 · 0.038 · 55 | `#4A3527` | PLACEHOLDER | concept master 01b-v2 dialect band | warm-dominant backdrop body |
| `PROV_B_FLOOR` | 0.513 · 0.049 · 69 | `#7A6248` | PLACEHOLDER | same | aged stone/parchment mid |
| `PROV_B_TRIM` | 0.655 · 0.067 · 75 | `#A98B62` | PLACEHOLDER | same | carved stone, choir-stall wood |
| `PROV_B_FRAME` | 0.809 · 0.068 · 79 | `#D9BC8F` | PLACEHOLDER | same | the same openings' gothic render — the exemplar's B half |
| `PROV_B_GLOW` | 0.777 · 0.132 · 75 | `#E8A94A` | PLACEHOLDER | same | **B's largest chroma area** (candlelight); the discriminator's warm anchor |
| `PROV_B_HAZARD` | 0.569 · 0.158 · 33 | `#C24B33` | PLACEHOLDER — **dormant at MVP** (OQ-DR-8) | same | no B-side effect ships at MVP; warm wine/flame flash for VS |
| `PROV_B_VOID` | 0.208 · 0.017 · 59 | `#1E1610` | PLACEHOLDER | same | the unlit warm read |
| `PROV_B_SEAL` | 0.443 · 0.134 · 14 | `#8E2A3C` | PLACEHOLDER — **dormant at MVP** (OQ-DR-8) | same | the wine-red seal family; no B-side effect at MVP |

**Value zoning (the discriminator test):** entities are ≥ 2 value-ramp steps clear of every backdrop member of their frame's truth (SYS-29's metric, TR-DR-002 verbatim). Pandora's chassis (L ≈ 0.24 body with the rim-light rule) clears A's wall/floor/trim by ≥ 2 ramp steps and uses the inversion + rim to hold B's warmer mids; the Warden-tier drops are value-pinned at authoring.

**The hue-swap survival test:** recolor each set's glow to the other's temperature — A must still read machine (the rectilinear coursing, the rack silhouettes carry it), B must still read crafted (the arch rhythm, the wax and grain carry it). If truth dies in the swap, the table fails — this is a pack-audit bar, re-run after every hex change.

**The semantic vocabulary (color means something, or it does not appear):**

| Hue family | Meaning | Where it may appear | Where it may never appear |
|---|---|---|---|
| Steel-cyan / monitor cyan (A_GLOW family) | the machine's truth — reality A | A frames, tells (epoch-0, resolving at 1), the tear accent's family, HUD's A-side readouts | in the liminal wing; on B-only surfaces |
| Amber / candlelight (B_GLOW family) | the crafted truth — reality B | B frames, the flip's arrival state, HUD's B-side readouts | in the liminal wing; on A-only surfaces |
| Pure grey (the ramp) | **neither truth** — the honest material | the seam region only (band, frame, fill-by-SYS-09) | anywhere a truth renders; as a "neutral UI" shortcut |
| Rose glow (`PROV_GRIEF_TINT`) | **the player's truth** — memory, grief, the one admitted color | M4's anchor only | any world surface; the five-errand grief wash inside the seam region |
| Sigil red (`PROV_SIGIL_RED`) | **the lord's presence** — contracts, seals, his court | only where his influence is physically rendered | decoration; HUD segments; weapons; any unearned surface |
| Tear cyan (`PROV_GLITCH_ACCENT`) | the fault in the world | the tear's 1-px edges only | any surface; any duration beyond the tear |

**Colorblind safety (value-first is the primary backup).** Because P2 makes value the reading order, every semantic distinction must survive grayscale *before* a shape/icon backup is needed. The named risks and their backups:

- **Wine red / sigil red (B surfaces vs the lord's marks):** neighboring by construction → backed by **shape** (a seal is a closed sigil form; a banner is fabric with a hem) and by **value** (§4.2's separation note). No meaning rides hue alone.
- **A_GLOW cyan / B_GLOW amber (the two truths' glows):** deuteranopia-safe by value (L 0.773 vs 0.777 — near-equal!) — so the *shape* of the light source is the load-bearing distinction (a strip = A, a pool from a holder = B); the key-light direction law (§2) is the second channel.
- **The ramp's steps (for low-vision players):** the even ladder (CR ≥ 1.52 per step) is the a11y answer; no step depends on hue (there is none).
- **Telegraphs:** color-flash is *always* paired with shape (§2B) — a colorblind player reads the telegraph from the shape alone.

**The A/B hue-set extraction rule (art-bible-side definition of F-SMB-07's inputs).** The A/B hue sets include only members with **C ≥ 0.05**; near-achromatic slots (the slates, the voids, the parchment neutrals at C 0.013–0.049) are excluded because their hue is unstable under pack normalization and would arbitrarily shrink the feasible interval. *(The prior lane's draft recorded 0.02 provisionally; this bible pins 0.05 — the slate members at C 0.022–0.029 sit inside quantization noise and their hues drift ±30° under the pack audit; a hue interval must not depend on them. Recorded for SYS-11's data sheet at its next touch — an art-bible-side data definition, not a SYS-11 formula change.)* With the §4.5 placeholders: **A = {206.6, 210.3}, B = {14.1, 33.2, 74.6, 74.9, 78.5}** (dormant members included, per F-SMB-05), grief 344.8 → the feasible interval is **[255, 304.8]** (open arcs; a hue exactly 40° from a member stays feasible) — non-empty, and the recorded candidate h 275 sits inside. The same arithmetic with the source-C-0.034 tint family (`#42465A / #5D6277 / #7D8298 / #9EA3BA`, h 274.6–275.9, ΔL vs ramp ≤ 0.004, rendered C ≈ 0.0102 at α 0.30) is the recorded A-ratification data.

**`ADM_ALPHA_MAX` = 0.30** (knob range [0, 0.5]; VR-SMB-08's target) — recorded for the re-open path and §8: the floor-quantized array at 0.30 is `[15, 30, 45, 61, 76]/255` (monotone, max ≤ 0.30, ≥ 1/255; F-SMB-06's floor law — never round to 128/255).

### 4B. Palette Export

`design/art/palette.json` is the machine-readable source for `/asset-spec` and the AI generation prompts (JSON only — a Godot project has no CSS consumer; CSS is added if a web prototype appears; the recorded default). It carries every §4 entry with `hex`, `oklch`, `status`, `role`, `context`, and the colorblind backup where one exists. The JSON is generated *from* this section; this section is the contract, the JSON is the export. (Written alongside this bible.)

### 4C. Typography Spec

**Text in this world is printed by the world.** All in-game text is diegetic-first: the print layer ("MEMORY CACHED", the serial numbers stamped on her chassis, the error-code stencils on A's walls, the memory fragments' written voice) is the game's primary text surface; screen-space type exists only where the fiction cannot hold it (the pause map's labels, the settings surface).

- **Families (pixel fonts only):** one display family (titles, chapter headers, the court's formal register) + one body/mono family (logs, item descriptions, the counter, damage numbers). Both are pixel-grid fonts at the art resolution; no outline font, no anti-aliased TTF rendered into the art res. Named candidates are an asset-spec decision; the bible pins the *constraints*, not the storefront.
- **The pixel tiers at 480×270** (the skill's 1.25-ratio scale translated to art px; base 16):

| Tier | Size (art px) | Use |
|---|---|---|
| caption | 10 | the map's labels, the counter's fine print |
| body | 16 | logs, descriptions, dialogue-adjacent text |
| lead | 20 | memory fragments' headers |
| subhead | 24 | menu section heads |
| headline | 32 | the flip's chapter card, boss names |
| display | 48 | title only |

- **Contrast floors:** body text ≥ 4.5:1 against its actual background at ship scale (the print layer prints on the truth's paper/steel tones — the tone pair is checked per surface); captions ≥ 3:1. The print layer's ink is the truth's void tone (A: `#141A1F` family; B: `#1E1610` family) or the paper tone, whichever the surface carries.
- **The no-gibberish-shipping rule** (REVIEW's key-art finding): generated text is accepted in concepts, never in production; every shipped string is real copy (SYS-28 owns the text pass).
- **Special treatments:** the print layer may glow only as its owning light does (the terminal's strip backlights "MEMORY CACHED" — that is the object's light, not a text effect); damage numbers are world-space prints, 7 px floor (SYS-29's law); no text ever pulses to point (P3).

### 4D. Visual Anchor Prompt

`design/art/style-anchor-prompt.md` is the seed prompt for `/asset-spec`: the modular style anchor (style keywords, the palette names as anchors, the lighting direction laws, composition philosophy, camera distance defaults) + the strong negative prompts + the per-truth variant blocks. (Written alongside this bible; §1–§4C are its source.)

## 5. Character Design Direction

**The promise: you know who is on screen before you know what you are looking at.**

- **Pandora-001** (the android assassin): the value inversion's dark half — dark chassis body, light head; the hair sail and tattered hem from the adopted sprite (production-worthy shape, REVIEW); the loaded assassin's stance (weight back, blade hand cocked — the A-pose replacement); the dash reads via pose + sparkle with the rim-light rule so the near-black body never vanishes; the jump ships as a frame strip (anticipation → apex tuck → heavy fall) proving the committed SotN arc. The death counter is stamped on her chassis (diegetic print, §4C).
- **Lenore Vane** (the woman): the inversion's light half — light body, dark head; spectacles, braid, watch chains (the timepiece motif — her chains rhyme with the court's clock-face imagery; motif, not decoration: it appears where she is remembered); composed-guarded default read (REVIEW's ACCEPT).
- **The demon lord:** the hybrid canon (designer decision 2026-11-11) — hooded silhouette with horns barely breaking the hood line; carries both the employer and the monstrous read; the sigil is restored and re-carved so jaw/hair/sigil survive 32 px; **red lives only on his sigils/contracts/court** — his body's materials contain zero red (REVIEW's red-rule finding).
- **The grief rig — one rig, five truths** (the crown invariant binds all five):

| State | Contour rules (silhouette-carried) | Crown state |
|---|---|---|
| Denial | rigid pristine upright, hands clasped, thin halo ring | whole, pristine |
| Anger | mid-lunge, sword raised high overhead, jagged flame-shaped ragged hair | cracked, heat-shattered edges |
| Bargaining | upright but held by an external scaffolding frame, cables trailing and breaking the outline, **one arm reaching out of the frame** (the deal-making gesture — the REVIEW fix) | cracked, pinned/supported |
| Depression | deeply hunched, sword tip resting on the ground as a crutch, head bowed, one ruined dangling arm (the best grief-state read in the set — REVIEW) | whole but lowered/slumped, weighing |
| Acceptance | relaxed upright, arms slightly open, completely smooth unbroken slimmer outline | the crown gone or dissolved — the one state without it |

  The MVP ships **Denial only**; the other four are VS content recorded here as direction. The rig is one body throughout — same height, same proportions (PROMPT-PACK shot 6).
- **Enemy archetypes** (SYS-13's three; value-separated from backdrops ≥ 2 ramp steps): Husk (T1/HUMAN — human silhouette wrongness), Spitter (T2/DEMONIC — the projectile telegraph is shape-first), Warden (T3/CYBORG — the elite read; the guaranteed post-flip drop). MACHINE unassigned at MVP.
- **The animation evidence standard** (REVIEW doctrine 4, binding): every animation claim ships as a frame strip; committed arcs (anticipation → strike → recovery) with recovery padded 2–3 frames to lock the weight (REVIEW's telegraph-grammar accept); no single-frame GIF ever proves a timing claim.
- **Pixel density rules:** true 1:1 pixel density (the adopted sprite's mixed-resolution hair/armor is the correction list), 1:1 + device scale captures, the green-key/cyan-line cleanup from the sprite refine list.

## 6. Environment Design Language

**The promise: the world is built, not decorated — and it is built twice, on the same bones.**

- **The duality:** chapel-factory (A) ↔ gothic chapel (B) — the locked concept pair's material lists (§3) applied to every room. One tile grid: **16 px tiles** (`TILE_PX` 16), 480×270 base art resolution, integer scaling; the world renders in the D1 SubViewport model at a safe-derived integer scale with the HUD at native resolution (ADR-0001's D1, technical-preferences.md).
- **Pack normalization (the locked AD binding condition 1):** Warped City and Gothicvania never share a frame — one pack per reality; they meet only at seam/glitch transitions. The normalization audit gates promotion from `inbox/` into `assets/`: single tile grid, shared outline color, harmonized saturation, the license check (`assets/LICENSE-MANIFEST.md`). A pack member that fails the audit is re-toned or excluded — never blended by hand into a hybrid material (§8B).
- **Texture philosophy:** value and coursing over detail. One 1 px course line per 16 px tile at ΔL −0.05 (derived shade, same hue, full width, bottom edge, phase-aligned with the hall — world y ≡ 0 mod 16); max 2 values per tile; zero vertical joints (max 1-in-2 stagger); no per-tile bevels, highlights, baked shadows, or outline (SYS-11 VR-SMB-03/04's grammar is the *whole game's* tile grammar, not just the seam's). Dither exists nowhere in the seam; elsewhere it is a §2B-adjacent style decision, capped by the 2-value law.
- **Prop density by room type:** hub/court = sparse, monumental (the architecture is the content); sanctuary = the one hero prop (the terminal/reliquary) + printed details; corridors = none beyond the coursing; arena = the fight's furniture only, pristine; the cistern's wrong-side = the reveal's one new passage, shown not sprung (SYS-02's reveal law).
- **Environmental storytelling — the tells** (D-6's epistemic epoch-0 tells, SYS-09's registry): symmetry that has no reason (the sealed passage's twin), dead conduits, error-code stencils (the print layer). They render in epoch 0 with the A table's own members (no special tell color — TR-DR-008) and resolve at epoch 1 by re-skinning to their B reading — never a scheduled event, never a highlight. The arena's scuffed floor is the pristine lie's one crack (the room's own tell). The seam's missing S frame is load-bearing (a 4-sided frame reads as a picture/door — VR-SMB-04).
- **The room-type kit:** hub, sanctuary (cache), corridor, arena (the Denial pocket, `epoch_pin: 0` — the pristine lie keeps it), the wing (the liminal corridor — its own material law, §4.1). Six MVP rooms on the 16 px grid; every room's bounds are the camera's default limits (SYS-02's room-limits-first).
- **The south-termination note (OQ-6 rider, consumed):** the wing's south end continues the terminal LIGHT step — no ledge lip, exit notch, or lit strip (SYS-09's fill/zone; rides SYS-09's next doc touch).

## 7. UI/HUD Visual Direction

**The promise: the interface is a pane of glass, not a second game.**

- **The minimal HUD** (SYS-24's 9-field publication): the HP bar, the item chip, the memory counter, the map availability, the prompt slot's active verb, the boss bar (arena only), the a11y flags, the clock fields, the settings entry — the *fields* are SYS-24's; this bible pins their *look*: flat rectangles in the print layer's edge style, the truth's steel-cyan (A contexts) / amber (B contexts) fills, **no red segments ever** (the REVIEW key-art finding; the court-canonical red exception applies only to court-owned UI, none at MVP).
- **Diegetic vs screen-space:** the death counter and "MEMORY CACHED" live in the world (the machine prints them); the HP bar and the map live on the glass (the fiction cannot hold a heartbeat). The split is fixed per surface; a surface's home is not a per-room choice.
- **The touch controls' look** (SYS-01's floating stick + Attack/Jump; Interact bubble; Quick-use chip): translucent value-neutral forms (the ramp's greys are forbidden here — UI is not liminal; the truth's glow family at low alpha over the world), ≥ 44 px touch targets, the frozen world's inert/ghosting state during the flip's freeze (SYS-01's freeze rules — the controls visibly but calmly disengage, no error state).
- **The pause room-grid map** (SYS-25's MVP surface): discovered cells + unexplored-doorway ticks; the grid is the room graph's own rectangles (no artistic re-layout); the current room pulses *once* on open, never continuously (P3).
- **The sanctuary menus** (SYS-26's lean-but-accessible stat presentation, the D-2 amendment): the two-slot loadout's cards, the level/points view — the anti-pillar's "stat-spreadsheet density" is the failure mode; the card + one-line lore is the form.
- **Accessibility** (SYS-01's TR-INP-070 baseline; SYS-24's settings): `REDUCED_FLASH` (§2B's static tear), text-scale, contrast floors (§4C), colorblind backups (§4), remapping — each surface names its a11y state in its spec. The `ux-designer` alignment check rides `/ux-design` for the Recalibration screen + touch help overlay before UI stories (the systems-index's UX flag) — it is a downstream handoff, not this bible's gate.

## 8. Asset Standards

**The promise: a file that fails the standard fails review, quietly and early.**

- **Naming:** `snake_case`, matching the tech preferences; `[category]_[subject]_[variant]` with the truth/epoch tag where the asset is truth-specific: `tileset_cistern_a.png` / `tileset_cistern_b.png` (the isomorphism law's data form — the pair ships together, same dimensions, same placements); sprites `spr_pandora001_dash_strip.png` (frame strips, not GIFs); VFX `vfx_<source>_<effect>_strip.png`; UI `ui_<surface>_<element>.png`. No truth-specific asset ships without its twin or its documented single-truth reason.
- **Resolution & format:** art at 480×270 (16 px tiles); PNG (indexed where the palette allows — the palette tables are the palette); sRGB color; nearest-neighbor everywhere (no filtering, no mipmaps, no subpixel sampling — SYS-09's whole-art-px law); captures at 1:1 + device scale.
- **Palette discipline:** every game asset's colors resolve to palette-table members or their derived shades (coursing at ΔL −0.05; the print layer's inks; the rim-light tones = the owning truth's glow family at 1 px). No asset carries a hex outside the tables; a new need is a bible amendment, not a hex picked in a file. Zero hex literals in code (AC-DR-02's literal-grep) — the palette data file is the only hex home.
- **Budgets** (technical-preferences.md): 60 fps / 16.6 ms frame; ≤ 150 draw calls; ~150 MB RAM on mid-range mobile; tilemaps batched per room; the flip's re-material inside SYS-02's 100 ms `REMATERIALIZE_BUDGET_MS`; SYS-11's boot ≤ 1 ms / incremental ≤ 0.1 ms dev asserts.
- **Import settings:** Godot — filter = nearest, mipmaps off, lossless compression; the palette data file versioned with the sprite data; the animation frame strips carry their frame-count + fps metadata in the filename or an adjacent `.json`.
- **The pack promotion audit** (before `inbox/` → `assets/`): the §6 normalization list + the license manifest + the discriminator tests (§4) — one audit, three failure exits (re-tone, exclude, escalate).
- **The placeholder → PINNED upgrade path** (SYS-09 TR-DR-002's rule, the bible's operational form): a PLACEHOLDER entry upgrades **in place** when its pinning evidence lands — (i) the owning pack's tone (the A/B slots, at the promotion audit), (ii) the recorded decision (the ramp + grief, done — D-ORCH-02), (iii) the owning pass's verified value (the tear accent, at the content-ship gate; the sigil red, at the court pass). Upgrading a seam-consumed entry re-runs the admission hashes (F-SMB-04's stale-hash boot failure is the tripwire — a re-pin re-admits or the grey ships). PINNED is required before content ship; PLACEHOLDER is legal through the greybox MVP.
- **The evidence standard** rides every asset review (frame strips for anything animated; 1:1 + device-scale captures for anything readable).

## 8B. Style Prohibitions

**The not-do list is the identity's other half.** Each prohibition carries its parent. Violating any of these is a review blocker, not a taste call.

| # | Prohibition | Parent |
|---|---|---|
| 1 | No fifth palette — the seam admits only the ramp + grief; the corridor has no GLOW/ACCENT/HAZARD role | SYS-11 VR-SMB-10; TR-DR-002's three groups |
| 2 | No purple/violet anywhere at MVP — the D-ORCH-01 decline is total (the REVIEW's violet-drift findings; the tint machinery is dormant) | D-ORCH-01; REVIEW L13/L26/L55 |
| 3 | No red as decoration — red only where the lord's presence is physically rendered | the red rule (REVIEW finding 5); AC-DR-02's zero-occurrence bar |
| 4 | No hybrid materials — the packs never share a frame; no hand-blended cross-pack props | the locked AD condition 1; §6 normalization |
| 5 | No per-room exceptions to the palette tables — a new need is a bible amendment | TR-DR-002's isomorphism law |
| 6 | No bloom/halo/glow on the liminal — the pale end is a plane, not a glow | SYS-11 VR-SMB-06; TR-DR-012 |
| 7 | No dither/gradient/noise/glitch vocabulary in the seam; no second light model there | SYS-11 VR-SMB-02; TR-SMB-005's static law |
| 8 | No unique hue, edge, or pulse on the band or north row at epoch ≥ 1 | SYS-11 VR-SMB-04/05; TR-SMB-006 |
| 9 | No characters in environment concepts; no environment in character sheets — the concept corpus's own failure list | REVIEW (the tube-woman, the A-pose findings) |
| 10 | No opacity-pulse telegraphs — color-flash + shape only | the locked AD condition 2; SYS-13's closed list |
| 11 | No subpixel sampling, fractional scaling, or non-integer displacement — whole art px at every frame | SYS-09's mechanism requirements; the D1 model |
| 12 | No frame-rate-dependent VFX — timing derives from ms/ticks, never from fps | SYS-29's clock law; F-DR-04 |
| 13 | No anime/cel drift, no photoreal texture, no painterly smoothing — SotN-era pixel craft only | the PROMPT-PACK style line; the klein-limitation note |
| 14 | No cutscene framing — story lives in logs, environments, boss encounters | the anti-pillar (game-concept) |
| 15 | No helpless-horror composition — her posture carries agency; the surrender is an offer, not a collapse | the anti-pillar; REVIEW's shot-4 fix |
| 16 | No timers, speed lines, or urgency framing — deliberation is the fantasy | the anti-pillar |
| 17 | No stat-spreadsheet density in menus — card + one-line lore | the anti-pillar (as amended, D-2); §7 |
| 18 | No red HUD segments | REVIEW's key-art finding; §7 |
| 19 | No gibberish text shipping — every string is real copy | REVIEW's key-art finding; §4C |
| 20 | No animation evidence without frame strips | REVIEW doctrine 4; §5 |
| 21 | No new hue family in VFX — effects borrow the owning truth's table members | §2B; P3 |
| 22 | No telling the machinery — no prompt/VFX/audio/HUD mark on the seam; the language law's ban list holds for visual language too | SYS-11 TR-SMB-006/011; SYS-02's language law |
| 23 | No third key-light direction | §2's key-light law |
| 24 | No glow/pulse/highlight/unique hue that exists to point — the world never beckons | P3; SYS-11's no-pointing law |
| 25 | No silent palette edits — a hex change is a bible change with its round-trip recorded | SYS-09's placeholder rule; F-SMB-04's hash tripwire |

## 9. Reference Direction

Five sources, each with a specific take and a specific avoid. Additive — no two point the same way.

| Source | Take (the specific element) | Avoid (the specific divergence) |
|---|---|---|
| **Castlevania: SotN** | the doubled map's memory — the same rooms made strange by a palette flip; sanctuaries that feel like sanctuaries; committed attack weight | the gore density and the gothic excess — our horror is clinical and domestic, not viscera |
| **Bloodstained / Timespinner** | the RPG-MV texture — drops worth inspecting, levels as build texture, the deliberate backtrack loop | the ornate particle density that fails at 270p — our sprites stay value-simple |
| **Ghost Song** | android melancholy — the lonely-body read, the quiet corridors between fights | the murky value range — our voids are near-black but our reads are high-contrast |
| **Warped City + Gothicvania (the owned packs)** | the two material dialects themselves — they are the palette tables' sources; the steel-cyan monitor language and the candle-wax language | sharing a frame, native-palette drift, un-normalized outlines — the audit's three exits |
| **Blasphemous** | architecture scale and pixel craft — monumental arches, the vertical grandeur of a church-as-institution | the religious-gore iconography and the penitent-body horror — our sacred horror is serene and unsettling, never suffering-display |

**The internal locked masters** (the corpus is the reference catalog; the skill's Phase 4.5 web search is skipped — the recorded default): 02b the library glitch (flagship frame), 06 the silhouette lineup, 05 the demon court, dirge-042 (the ship-grade weapon read), 04-final (the surrender), 01a-clean-v2 + 01b-v2 (the geometry-locked pair). Each master carries its REVIEW verdict line and is the first-stop reference for its subject.

## 10. The `/asset-spec` handoff list

The lane brief's obligation 5 — what `/asset-spec` consumes from this bible:

1. **The palette tables** (§4 + `palette.json`): every entry's `{hex, status, source}`; PINNED entries are production-legal now; PLACEHOLDER entries are greybox-legal with the upgrade path (§8); the derived-shade rules (coursing −0.05, the print inks, the rim tones).
2. **The style prohibitions** (§8B) as the per-asset lint — each spec's checklist cites the numbered prohibitions that bind its asset class.
3. **The silhouette/read rules** (§3, §5): the 32 px grief test, the value inversion, the crown invariant, the rim-light rule, the 2-step value zoning, the 2-second truth test, the hue-swap survival test.
4. **The placeholder → PINNED upgrade path** (§8): the three pinning-evidence kinds, the admission-hash re-run for seam-consumed entries.
5. **The naming convention + format + budgets** (§8): `snake_case` naming, PNG/indexed, nearest filtering, the draw-call/memory/frame budgets, the D1 SubViewport model.
6. **The 480×270 / 16 px constraints** (§6): the tile grid, the integer scale, the 1:1 + device-scale capture rule.
7. **The animation evidence standard** (§5): frame strips, committed arcs, recovery padding — an asset without its strip does not enter review.
8. **The pack-normalization audit gate** (§6): the promotion checklist from `inbox/` to `assets/`, including the license manifest.
9. **The D-ORCH-01 record for the seam work** (§1, §4): the purple is declined at MVP — `/asset-spec` produces **no** `seam_tint_spec` at MVP; the four `PROV_LIM_*` tile faces + the band/north/W-E compositions are the seam's asset scope (SYS-11's asset-spec route, grey default). A future ratification re-opens `seam_tint_spec` under §1's three keys.

---

*End of the art bible. The review log (`design/gdd/reviews/art-bible-review-log.md`) carries the gate trail; the lane report carries the sync request and the OQ-1/OQ-4 closing records.*
