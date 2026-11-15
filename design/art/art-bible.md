# Art Bible — Five Errands for the Devil

> **Status**: **AUTHORED — the gate trail closed (2026-11-15).** CD-GDD-ALIGN CONCERNS → repaired (2 blockers + 7 recs) · three-seat panel NEEDS REVISION (3 creative + 6 technical + 8 QA, all valid) → repaired (14 text repairs) · qa-lead spot-check **PASS** (17/17 rows; 5 advisories applied) · final micro-check run 1 FAIL (2) → repaired → run 2 **PASS** (zero blockers). The user decisions D-ORCH-01/02 are recorded and applied (2026-11-15); the PR carries the trail. Section status table below carries the per-section state.
> **Review record**: `design/gdd/reviews/art-bible-review-log.md` (§A authoring + the independent color-math verification; §B the gate trail).
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

**The 2-second test, instrumented (this bible's pin — TR-DR-002 assigns the A half's two-sided check to this pass).** *Scope: truth-rendered frames only — the liminal wing is excluded here because the seam's own bar is the opposite read (VR-SMB-09/AC-SMB-21: ≥ 4/5 code "neither" on the A/B/neither forced choice; one frame cannot pass both bars, and both are correct).* Instrument (AC-DR-24's, adopted verbatim): a 2-second still card of a truth-rendered room is shown and then hidden — the tester answers "which world is this room in?" aloud while the card is visible; the card's onset starts the clock; a material naming (the cold register / the warm register) emitted inside the display window passes; answers after the hide are unscored; a bare room name without a material read does not score. Protocol: n ≥ 5 cold viewers, ≥ 4/5 naming the correct truth's material, 0 failure reads (door/portal/loading/unfinished/corrupted vocabulary); 1:1 + device scale. **Owner: art-director. Evidence: the capture set in `production/qa/evidence/`. Gate: the art-pipeline bars at the greybox device pass** (SYS-11's partition vocabulary), with the record carried at AD-ART-BIBLE.

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

SYS-02's Player Fantasy line 36 now reads *"a bridge of neither truth holding it together"* (the user-approved contract revision D-ORCH-01, applied at commit `5cc1377`). **The purple's remaining references are the sync rider's named sites** (the rider the lane report carries; the sync lane applies the index row now, the SYS-02 clauses ride its next doc touch — the OQ-M1 pattern; this bible edits neither): (a) **the systems-index SYS-11 row** ("Cold Corridor purple = bridge material" → the qualified grey-default reading); (b) **SYS-02 TR-RWS-015**'s parenthetical ("SYS-11's purple bridge spans it as material, routed to the art bible" → the grey default, the purple declined per D-ORCH-01); (c) **SYS-02 TR-RWS-022**'s clause ("SYS-11 owns the border material (the Cold Corridor purple bridge — routed to the art bible for ratification…)" → the same qualification); (d) **SYS-02 AC-RWS-21**'s final clause ("the purple bridge material is referenced as SYS-11's" → the liminal material per the pinned ramp). **Owner: the sync lane (a) / SYS-02's next doc touch (b–d, the OQ-M1 pattern). Verification gate: the sync PR's diff review + the next SYS-02 touch's review.**

## 2. Mood & Atmosphere

Nine state targets. Each names the emotional target, the lighting character (key direction, temperature, contrast), 3–5 atmospheric descriptors, and an energy level. Two of the nine — the arena and the liminal wing — are the places the world *performs*; they get the tightest bars.

| # | State | Emotion (the target) | Lighting character | Descriptors | Energy |
|---|---|---|---|---|---|
| 1 | **A-exploration** (epoch 0) | Clinical reverence — a sacred place repurposed by something that does not worship | Cool key from monitor strips + A_GLOW; low-contrast ambient, high local contrast at glow edges; no warm light anywhere | sterile, museum-clean, humming, slate, watchful | measured, quiet |
| 2 | **B-exploration** (post-flip) | Home that is wrong now — warmth as accusation | Warm key from candle pools + B_GLOW; gentle falloff, soft shadows; the same corners the monitor light never reached now hold amber | candlelit, gothic, incense, wax, aged | measured, hushed |
| 3 | **The liminal wing** (post-E4) | The honest joint — neither truth, still, older than the argument | **No key.** Sourceless pale light, mild vertical falloff (brighter deep end, VR-SMB-06's plane-not-glow); the ramp IS the only light model | plain, even, coursing, sourceless, quiet | still |
| 4 | **The arena** (the Denial fight) | The pristine lie — a pocket that pretends the flip never happened | A's own lighting at full fidelity: cleaner, brighter, *more* A than the world around it (it is the lie's over-fidelity that betrays it on the second look) — **the licence is exactly AC-DR-14's two authored exceptions (the scuff decal + the west entrance); no third deviation** | pristine, symmetrical, scuffed-floor tell, halo-bright, sealed | combat pace |
| 5 | **The court** (demon lord's hub; VS-era for full dressing) | Dread dressed as hospitality | Sigil-red key surfaces (banners, seals, floor circuitry) against cold steel-cyan ambient; red is *earned* here (REVIEW finding 5) | cathedral-scale, chrome saints, circuitry, branded, quiet-danger | deliberate |
| 6 | **The cache sanctuary** | Safety with a price printed on it | Cyan pool from the terminal/reliquary — **the interactable's own local treatment, not a second key direction** (A's overhead key remains; the pool is the cache's earned "older than the epoch claims" anomaly — RM-04's tell family) | reliquary, printed, cable-ceremonial, white-blue brain glow, reverent | restful |
| 7 | **Combat** (any truth) | Readable violence | The truth's own key; telegraphs carry the extra contrast (color-flash + shape), the world's contrast budget never moves for combat | committed, weighty, high-contrast on threats only | sharp |
| 8 | **The flip** (the held breath) | The world stops arguing | Desaturation to grey-white over the freeze (MAG 0.6), the tear's cyan accent, the strobe's one neutral beat — then the new truth lands whole | torn, desaturated, held, scanlined, atomic | suspended |
| 9 | **Death / reconstruct** | Death is story, not a penalty screen | Desaturation + the death sting's band (by `overkill_ratio`); the reconstruct is SYS-15's fiction — the body reassembles where the world can see it | cold print, counter ticking, offline, re-membered | slow, then released |

**Atmosphere laws (binding on every state):**

- **The key-light direction law.** Key light falls from above in truth A (monitor strips, ceiling racks) and from *beside* in truth B (candle pools at their holders' height — sconces, stands, the altar). The flip therefore also changes the *direction* of shadow, not only its temperature — one more material-level proof the world changed. No state introduces a third key direction.
- **The contrast budget.** The world renders inside a fixed value envelope per truth (A: void-to-frame ≈ L 0.21 → 0.74; B: void-to-frame ≈ L 0.21 → 0.81, §4 tables). Threats, telegraphs, and interactables get their contrast by *their own* value/color treatment (§2B), never by pushing the room's envelope. The arena is the sole licensed exception in the *other* direction: it may run *cleaner* (higher fidelity, lower ambient grime) than its zone — that is how the pristine lie reads.
- **The "quiet, not corrupted" bar (SYS-09's TR-DR-012, consumed verbatim).** The liminal wing's material grammar is stripped of both packs' detail: plain even coursing, sourceless pale light, desaturated clear of both truths' glows. It must read as *an honest place*, never as a rendering failure. **The bar's instrument is the failure-catch vocabulary the playtest ACs already run**: the arena's version is AC-DR-25 (F3 — "buggy / didn't load / looks broken" fail the code outright; the eligibility rule — ≥ 1 pre-flip arena visit — is the arena's own and does not transfer), and the wing's version rides AC-SMB-21's failure catch (door/portal/loading/unfinished/corrupted, 0 allowed) at the wing's own rows. The F3 anti-code bar applies here as much as in the arena.

## 2B. VFX & Particle Style

**Scope law: this section authorizes no new MVP prompt/VFX/audio.** It is the style contract for the vocabulary SYS-29 (juice), SYS-09 (the flip), SYS-13 (telegraphs) already own. Every effect below cites its owning contract; where this section and the owning GDD disagree, **the owning GDD wins** and this section records the correction.

**The glitch is the signature, never the wallpaper.**

- **The tear/glitch vocabulary** (SYS-09 TR-DR-006 / F-DR-04, consumed verbatim at `FLIP_GLITCH_MAG` 0.6): tear displacement 5 art px (hard cap 8, never tile-aligned), desaturation depth 0.6, channel jitter 2 px, scanline spacing 4 art px (static per frame — no scrolling), scanline alpha 0.36, the cyan tear accent (`PROV_GLITCH_ACCENT`, 1-art-px jagged line, alpha 0.9) at the tear edges. One choreography-anchored strobe beat at τ0 (neutral scanline flash over desaturated content, one wall tick, no red channel); the aftershock rule per F-DR-04's clamp (off at the default MAG). The wing receives the tear like the rest of the world — it is part of the fault, and making it the tear's epicenter is the rejected flourish (TR-DR-012). **The tear's GPU budget (OQ-DR-6, answered here):** ≤ **1.5 ms/frame p95**, provisional — adopted as this bible's VFX performance bar; PR-DR-03/06's probes are the measurement and the tripwire (an exceedance re-opens the budget at SYS-09, never a silent overage). **The resolution half of OQ-DR-6 is answered by §6**: the world renders at the 480×270 / 16 px art resolution in the D1 SubViewport (ADR-0001) — there is no second tear resolution to pin.
- **`REDUCED_FLASH` visual set:** zero beats, zero jitter, one static tear band (4 art px minimum) visible through the hold, desat unchanged, logic trace bit-identical. This is an art constraint, not a settings afterthought — every VFX spec must name its REDUCED_FLASH variant.
- **The photosensitivity law as an art constraint:** ≤ 3 flashes/s (SYS-29's law); no flash frequency ever scales with glitch magnitude (F-DR-04 amplitude-only); the strobe's neutral beat uses no red channel.
- **Juice vocabulary** (SYS-29's, style-only constraints): **the spark pair is designer-fixed and truth-independent (TR-JCE-016, consumed verbatim): contact = amber, midpoint = cyan — this bible pins the hexes (OQ-J3): contact amber = `PROV_B_GLOW` `#E8A94A`, midpoint cyan = `PROV_A_GLOW` `#4FC8DC`** (PLACEHOLDER members; the two beats stay two tones); sparks are procedural at MVP (a radial silhouette, 2 frames per pulse). **The damage-number glyph palette (SYS-07's law via TR-JCE-024, hexes pinned here per OQ-J3):** enemy damage = amber `PROV_B_GLOW` `#E8A94A` · player damage taken = pale bone `PROV_B_FRAME` `#D9BC8F` · heal = cyan `PROV_A_GLOW` `#4FC8DC` · the gold glyph is VS (unpinned) · never sigil-red · no "CRITICAL" text. **The death sting's magnitudes (OQ-J3's art pass):** LOW = the authored base (quiet — strike deaths) · MID = ×1.5 · HIGH = ×2.2 (the signature ceiling; `overkill_ratio`'s HIGH band); the sting is one flash — the ≤ 3 flashes/s law holds. **The grant cue's bespoke VFX (the Leap-Stone's stone glow + wing motif, OQ-J3):** the `PROV_A_GLOW` family + the print layer; authored at the asset-spec pass. **No new hue family in VFX** — every effect borrows the tables' members or the recorded derived shades.
- **The telegraph grammar** (locked AD condition; SYS-13's TR-ENM-013 two-channel law, consumed verbatim): telegraph = **color-flash + shape, never opacity pulses**. **The flash carries the power band — the band hexes are this bible's pin (OQ-ENM-3, answered here):**
  - **Band 1 (light) = the cold bright flash — `PROV_A_HAZARD` `#7DF0FF`** (L 0.893; a live A member — this is its MVP consumer).
  - **Band 2 (heavy) = the deep amber flash — `#C78B28`** (OKLCH L 0.68 · C 0.13 · h 75 — a derived presentation shade of the B_GLOW family, recorded here; the derivation's reason is the separation bullet below).
  - **Separation: ΔL 0.213 ≥ 0.20** (= ≥ 2 steps of the seam bar's L definition; ≈ 7 index positions on §4.6's canonical value ramp — both metric forms pass). *(Why a derived shade: no bright member (L ≥ 0.70) sits ≥ 0.20 below a bright flash — the dimmer qualifying members (e.g., B_TRIM 0.655, `PROV_GRIEF_TINT` 0.660, LIM_PALE 0.610) are mid-value materials or overlays, not flashes.)* Band 3 (dire) is recorded, unshipped — its member pins at VS. **Never sigil-red; never color-alone** (the shape channel carries the height band and the meet/deny verdict — a colorblind player reads the telegraph from shape alone, AC-ENM-32's bar).
  - The flash is **truth-independent** (a threat reads the same in both truths — the flash is the glass's grammar, not the room's material); the shape carries the attack's identity (§3's silhouette rules). An opacity pulse is a prohibition (§8B) — it dies at phone scale and it lies about timing.
- **The evidence standard (REVIEW doctrine 4):** animation/VFX claims require **frame strips** (anticipation → strike → recovery, ≥ 3 frames), never single-frame GIFs. VFX sheets ship with their frame strips or they are not reviewed.
- **The seam is VFX-free** (SYS-11 TR-SMB-006/011): zero VFX, zero glow, zero dither, zero animation on the band, the frame, or the fill. The corridor's only effects are the world's own tear passing through it.
- **Full-RGB exemption:** the glitch band's RGB-shifted strips are the one place outside palette discipline (REVIEW Shot 2 note) — the signature VFX is allowed to break the palette *inside the tear*, for the tear's duration only. Nothing else borrows the exemption.

## 3. Shape Language

**Character silhouette philosophy — every silhouette names itself at 32 px, no color.**

- **The 32 px grief test** (the locked AD condition; the concept's test 3) — **instrumented (this bible's pin):** n ≥ 5 cold viewers; a **closed five-stage list + "cannot tell"** as the answer set; ≥ 4/5 modal-correct **per state**; the named confusable pair (Denial ↔ Acceptance — the crown states) is scored with zero tolerance for cross-coding between them; evidence = the 06 silhouette strip rendered at 32 px; **owner: art-director; gate: the grief-rig asset-spec pass, with Denial's row run at MVP** (the other four rows run when their states exist — the bar is per-state, not per-roster). Palette-only variants are forbidden — they collapse at phone scale.
- **Value inversion (REVIEW doctrine 1):** Pandora dark-body / light-head; Lenore light-body / dark-head. The two women are unambiguous at a glance, in either reality, before any color is read.
- **The crown invariant (REVIEW doctrine 2, adopted):** the crown persists across all five grief states, cracked differently per stage. One anchor per state fixes the same-woman failure the concept round caught.
- **The rim-light rule (REVIEW doctrine 6):** near-black bodies on dark rooms carry a 1-px rim in the truth's glow family, on the side facing the key. This is value separation, not decoration — it is what keeps Pandora's dash from vanishing (the REVIEW finding on `pandora-001-dash`).
- **Committed poses:** SotN weight — loaded stances, planted follow-through, decaying trails (REVIEW's animation accepts). No neutral A-poses; no weightless floats.

**Environment geometry — one geometry, two dialects.**

- Truth A: strictly rectilinear 90/45° geometry; pointed gothic arches *rendered as* cold bulkhead frames; server monoliths where pews would stand (PROMPT-PACK shot 1A's material list).
- Truth B: the same 90/45° bones rendered as carved gothic — the same arch rhythm, the same openings, candlelit stone, choir stalls, banners (PROMPT-PACK shot 1B's edit list).
- The shared-geometry rule is absolute (REVIEW Shot-1 pair verdict): arch rhythm, back wall, foreground furniture, camera eye-line do not drift between truths. A screenshot of the same room at both epochs, overlaid, must align to the pixel. **The test (this bible's pin):** the geometry guarantee is SYS-09's — TR-DR-009/AC-DR-03's packed-data byte hash (the TileMap is byte-identical across the flip; a decal that alters cell or collision data fails the boot) — and the **visual twin** is the art-side check: the epoch-0 vs epoch-1 render of one room at 480×270, XOR-diffed, whose non-zero pixels are exactly the designed palette deltas. **Owner: art-director. Evidence: the diff pair in `production/qa/evidence/`. Gate: the art-pipeline bars at the greybox device pass** (added to §10's handoff).
- **Hero shapes vs supporting shapes:** arches, doorways, and the stair runs are hero shapes (learnable, re-tourable); rivets, pipes, candles, debris are supporting texture (≤ 2 values per tile, §6). Hero shapes never trade silhouette for detail.
- **Where the SotN texture lives (the richness budget — P2's "reward the second look" needs somewhere to go):** the tile field stays austere (the coursing grammar); the second look is rewarded in the **props** (the cache's reliquary, the court's chrome saints), the **memory fragments' presentation** (SYS-20's), and the **print layer** (§4C) — texture austerity in the walls is what makes those three worth inspecting.

**UI shape grammar.** The interface is a pane of glass over the world, not a second game: rectangular panels with the print layer's hard 1-px edge (§4C), no skeuomorphic chrome, no rounded-glass panels. The HUD's shapes are rectangles and ticks; the map's shapes are the room graph's own rects (SYS-25's discovered cells). UI echoes the world through its *type and edge*, not through ornament.

## 4. Color System

**The slot structure is SYS-09 TR-DR-002's, consumed verbatim:** one table, three groups — the reality-A slots, the reality-B slots (`B_SEAL`/`B_HAZARD` dormant at MVP per OQ-DR-8; `A_SEAL` zero-occurrence at MVP per AC-DR-02's red rule), and the liminal ramp — plus `PROV_GLITCH_ACCENT` (the tear accent; SYS-29 consumes the name), `PROV_GRIEF_TINT` (overlay anchor, not a member), and `PROV_SIGIL_RED` (**reserved, not a member** — lord presence only). Every entry carries `{hex, status, source}`. **The isomorphism law:** both truths fill the same slot list at the same placements — a re-skin is a table swap over unchanged coordinates, never a redraw; `FRAME` is the shape-carrier exemplar.

**Status semantics:** `PINNED` = user-approved via a recorded decision (the greybox MVP may ship it); `PLACEHOLDER` = legal through the greybox MVP, PINNED required before content ship (SYS-09's placeholder rule — the owning pack's nearest existing tone, value band first); `RESERVED` = not a table member; a hex exists only as the recorded candidate for the owning pass. *(TR-DR-002's schema names two statuses — `RESERVED` is this bible's recorded extension for the not-a-member class; the schema rider rides the sync.)*

### 4.1 The liminal ramp — **PINNED** (D-ORCH-02)

The corridor's whole material voice: a pure value ladder with **no hue at all** (C 0.000). Achromatic is the emotional argument *and* the normative read of VR-SMB-01 ("one shared hue **or none**", C ≤ 0.008): any hue belongs to somebody — a cool bias leans A, a warm bias leans B; a pure ladder is the only material provably neither truth, and it cannot drift toward a truth under the hue-swap test. It keeps VR-SMB-10's membership exact (4 members + 4 derived course shades, no hue family) and makes AC-SMB-21's ≥ 4/5 "neither" read a property of the paint.

| Name | OKLCH (source of truth) | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_LIM_DEEP` | L **0.40** · C **0.000** | `#484848` | **PINNED** (D-ORCH-02) | SYS-09's ramp + VR-SMB-01's ladder; round-trip verified | step 0; the frame at offset −1 — the W/E array's first member [DEEP, MID, MID, PALE, PALE] (VR-SMB-04) |
| `PROV_LIM_MID` | L **0.50** · C **0.000** | `#636363` | **PINNED** (D-ORCH-02) | same | step 1; the band + north pin (`SEAM_BAND_STEP` = MID) |
| `PROV_LIM_PALE` | L **0.61** · C **0.000** | `#838383` | **PINNED** (D-ORCH-02) | same | step 2 |
| `PROV_LIM_LIGHT` | L **0.72** · C **0.000** | `#A4A4A4` | **PINNED** (D-ORCH-02) | same | step 3; the terminal plane — the corridor's value maximum (VR-SMB-06) |

**The gap check (`gap_R ≥ 0.09`) — verified, no fallback triggered.** Source ΔL 0.100 / 0.110 / 0.110; quantized (8-bit round-trip) **0.098 / 0.110 / 0.109** — all ≥ 0.09, so F-SMB-05's P2 guarantee (`ADM_L_GAP_MIN` 0.05 + 2 × `ADM_L_TOL` 0.02 = 0.09) holds with margins +0.008 / +0.020 / +0.019. *(Column note: the L values are the approved targets; the hexes are their 8-bit quantizations — `#A4A4A4` round-trips to L 0.7186. The gap check is computed on the quantized values throughout.)* **OQ-4's conditional is therefore not exercised:** the D-gap clause does **not** relax, and the tint does not close on gap grounds — recorded per the lane brief's obligation 3. Contrast ratios (relative luminance): DEEP→MID 1.52 · MID→PALE 1.58 · PALE→LIGHT 1.52 · DEEP→LIGHT 3.67 — an even ladder, no compressed step. If a future harness's conversion reports DEEP→MID < 0.09, the pre-agreed remedy is DEEP L 0.395 (`#474747`) — **a one-value change that may apply only through the recorded-decision path (§8B #25): a silent re-pin of a PINNED value is forbidden**.

**Ramp laws:** epoch-invariant (TR-DR-012 — the wing does not re-skin); the ramp is the wing's *only* light model (VR-SMB-02 — zero dither/gradient/noise; steps on tile-row boundaries only); coursing is the only texture (VR-SMB-03 — one 1 px course line per 16 px tile at ΔL −0.05, same hue, a derived shade **not a member**); max 2 values per tile; the ramp's hexes live in the palette data file, never as literals in code (AC-DR-02's literal-grep).

### 4.2 The grief tint — **PINNED** (D-ORCH-02)

| Name | OKLCH (source of truth) | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_GRIEF_TINT` | L **0.66** · C **0.14** · h **345** | `#CD6CA6` | **PINNED** (D-ORCH-02) | SYS-09's overlay anchor + VR-SMB-07's range; round-trip verified (0.6602, 0.1402, 344.8°) | M4's anchor only; P5's input |

- **The hue band [330, 20] (circular) is the binding constraint** (D-ORCH-02); h 345 is the pinned member inside it. The recorded alternative if the rose should read redder: h 355 → `#D36A96` (verified round-trip 0.6595, 0.1404, 355.2°) — same C/L, P4 still passes. Switching members inside the band is an art-bible edit, not a decision.
- **Value rationale:** L 0.66 clears `PROV_LIM_PALE` (0.61) by +0.05 and stays below `PROV_LIM_LIGHT` (0.72) by 0.06 — the pale terminal plane remains the corridor's value maximum; M4's body at L ≤ 0.50 reads dark against its own glow (≥ 2 steps vs LIGHT, VR-SMB-07).
- **Separation rationale:** 345° sits 69.8° from the tint's admissible hue (275°), 85–95° from B's amber/candle hues, and distinct from A's cyan/teal by construction. **The band's edges are the honest worst case** (recorded so a member swap cannot silently break separation): h 330 → 55° from the candidate; the h-355 alternative → 80°. **The wine family's distances, printed:** `PROV_B_SEAL` h 14.1 is **29.3°** from the pinned 345 (and lies inside [330, 20] — a hue-only claim would be false); `PROV_B_HAZARD` h 33.2 is 48.4°. The tint's distance from the wine family and the reserved sigil red is therefore carried by **value** (L 0.66 glow against dark fabric/seals — ΔL ≥ 0.05 from every wine-band member) — recorded explicitly, because the band and the red family are neighbors by construction and hue alone cannot carry the distinction. The court pass must prove the sigil red's final value ≥ 2 ramp steps from the grief tint, or declare the separation shape-only.
- **VR-SMB-07's usage bounds, consumed verbatim:** C 0.12–0.18 · L 0.55–0.68 (below LIGHT) · ≤ 1/3 of M4's lit pixels · ≤ ~1% of the wing's area · zero spill · no additive/bloom/halo/pulse · M4's anchor only · M4's body L ≤ 0.50 against LIGHT (≥ 2 steps) · **the five-errand grief wash excludes the seam region** (epoch-invariance + the one-color law both break otherwise). **The wash's status (this bible's ruling): the five-errand grief wash is VS-recorded direction, not an MVP channel** — no GDD owns an MVP wash; the concept's graft (game-concept L139) lands as direction for VS authoring, where each errand's wash needs an owning GDD, a bounded alpha knob, a discriminator re-run (the 2-second and hue-swap tests re-run on the washed tables), and VR-SMB-07's exclusion. **At MVP no wash ships — the grief tint's MVP presence is M4's anchor only** (AC-DR-15's confinement; the no-spill bar measures M4's anchor + 1-tile ring).

### 4.3 The tear accent — PLACEHOLDER (companion)

| Name | OKLCH | Hex | Status | Source | Consumer / rule |
|---|---|---|---|---|---|
| `PROV_GLITCH_ACCENT` | L 0.783 · C 0.136 · h 210 | `#00CFE8` | PLACEHOLDER (companion — pinned at the §8 content-ship gate) | the art-bible pass; the tear's cyan (SYS-09 TR-DR-002's name; SYS-29 consumes) | the tear's 1-px edges at α 0.9 (F-DR-04); no other use |

### 4.4 The reserved red — not a member

| Name | OKLCH | Hex | Status | Source | Rule |
|---|---|---|---|---|---|
| `PROV_SIGIL_RED` | — (candidate L 0.49 · C 0.19 · h 21 at `#B3122E`) | — | **RESERVED** | SYS-09 TR-DR-002: recorded as reserved, **not a member** | the lord's physical presence only: his sigils, seals, contracts, his granted Stinger, and the court's own canonical red (banners, floor seal — court decoration *is* earned red, REVIEW finding 5). Zero occurrences across both epochs' MVP replays (AC-DR-02). The exact hex pins at the court pass (VS-era dressing) |

### 4.5 The A/B slot tables — PLACEHOLDER (pending the pack promotion + normalization audit)

The 16 slot hexes below (15 shipped — `PROV_A_SEAL`'s hex is the reserved red's binding, §4.4) are **PLACEHOLDER**, sourced from the locked concept masters' dialect bands (PROMPT-PACK shots 1A/1B; REVIEW's locked selections) because the owned packs (Warped City / Gothicvania) are not yet promoted (`assets/source` is empty; the normalization audit has not run). On promotion, each slot upgrades to the owning pack's nearest existing tone — value band first (SYS-09's placeholder rule) — and the table re-passes the discriminator tests. **The slot list, placements, and value bands are already binding**; the pack audit changes hexes, never the structure.

| Slot | OKLCH (L · C · h) | Hex | Status | Source | Notes |
|---|---|---|---|---|---|
| `PROV_A_WALL` | 0.342 · 0.024 · 244 | `#2E3A44` | PLACEHOLDER | concept master 01a dialect band | the backdrop body; cool-dominant |
| `PROV_A_FLOOR` | 0.432 · 0.023 · 243 | `#46525C` | PLACEHOLDER | same | ≥ 2 steps clear for entities (value zoning) |
| `PROV_A_TRIM` | 0.580 · 0.029 · 239 | `#6B7D8A` | PLACEHOLDER | same | conduits, rails, racks' frames |
| `PROV_A_FRAME` | 0.741 · 0.025 · 236 | `#9DAEB9` | PLACEHOLDER | same | the bulkhead frame edges — the shape-carrier exemplar slot |
| `PROV_A_GLOW` | 0.773 · 0.110 · 210 | `#4FC8DC` | PLACEHOLDER | same | **A's largest chroma area** (monitor-glow); the discriminator's cool anchor |
| `PROV_A_HAZARD` | 0.893 · 0.107 · 207 | `#7DF0FF` | PLACEHOLDER | same | the cold bright flash — **the telegraph's band-1 member (§2B, OQ-ENM-3)**; always paired with shape (the telegraph grammar) |
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

**Value zoning (the discriminator test) — the unit, pinned.** The metric exists in two consumed forms: the seam bar's "≥ 2 steps (**≥ 0.20 L**) clear" (seam-borders' acceptance bars) and SYS-29's "**the absolute delta of palette value-ramp indices**" (TR-JCE-016 — "the `PROV_PALETTE` ordering until the art-bible pin"). **This bible pins the canonical value ramp (§4.6) and thereby the index unit; where an audit's own bar prints an L form, the L form governs that audit.** The honest statement for the flagship case: Pandora's chassis body (L ≈ 0.24) does **not** clear the darkest backdrops by raw fill value (A_WALL ΔL 0.102; B_WALL ΔL 0.109 — under 0.20). The zoning read is **rim-carried**: the body's readable contour is the 1-px glow-family rim (the rim-light rule, §3), and the rim's value (L ≈ 0.77, ramp index ~16) clears every backdrop member by ≥ 2 ramp indices; **for rim-lit near-black bodies the value-zoning audit measures the contour, not the fill** — recorded here as the metric's measurement-surface rule, with SYS-29's owner countersigning the rule at the next SYS-29 touch (the metric is SYS-29's). If a device capture shows the fill itself reading as the silhouette (the rim failing), the body's L re-derives at the asset-spec pass — the rim is the default answer, not a fudge. The Warden-tier drops are value-pinned at authoring.

### 4.6 The canonical value ramp (the metric's pin)

**The world palette's ordered value ramp** — every hexed member (the A/B slots, the liminal ramp, the overlay anchors) ordered by OKLCH L ascending, indexed from 0; ties broken by hue. This is the ordering TR-JCE-016's audits consume ("the `PROV_PALETTE` ordering until the art-bible pin" — pinned here), and the reference for every "≥ 2 ramp steps" claim in this document and its consumers. One **ramp step = one index position**.

| Idx | Member | L | Idx | Member | L |
|---|---|---|---|---|---|
| 0 | `PROV_B_VOID` | 0.208 | 11 | `PROV_LIM_PALE` | 0.610 |
| 1 | `PROV_A_VOID` | 0.214 | 12 | `PROV_B_TRIM` | 0.655 |
| 2 | `PROV_A_WALL` | 0.342 | 13 | `PROV_GRIEF_TINT` *(overlay)* | 0.660 |
| 3 | `PROV_B_WALL` | 0.349 | 14 | `PROV_LIM_LIGHT` | 0.719 |
| 4 | `PROV_LIM_DEEP` | 0.402 | 15 | `PROV_A_FRAME` | 0.741 |
| 5 | `PROV_A_FLOOR` | 0.432 | 16 | `PROV_A_GLOW` | 0.773 |
| 6 | `PROV_B_SEAL` *(dormant)* | 0.443 | 17 | `PROV_B_GLOW` | 0.777 |
| 7 | `PROV_LIM_MID` | 0.500 | 18 | `PROV_GLITCH_ACCENT` *(overlay)* | 0.783 |
| 8 | `PROV_B_FLOOR` | 0.513 | 19 | `PROV_B_FRAME` | 0.809 |
| 9 | `PROV_B_HAZARD` *(dormant)* | 0.569 | 20 | `PROV_A_HAZARD` | 0.893 |
| 10 | `PROV_A_TRIM` | 0.580 | — | (a derived shade reads at its own L within its source's hue neighborhood) | — |

`PROV_A_SEAL` (no hex — the reserved red's binding) has no index until the court pass pins it. The band-2 flash `#C78B28` (L 0.68) sits at index ~13's neighborhood; the telegraph pair's index distance (≈ 7) and L distance (0.213) both clear the ≥ 2-step bar. *(Derived shades: the conservative reading is that a derived shade inherits its **source's ramp neighborhood shifted by the shade's own L** — so the band-2 shade reads ≥ 3 steps from its source `PROV_B_GLOW` (index 17 → ~13) and the distance it must clear is measured from the shade's own position, which every recorded shade does.)*

**The hue-swap survival test:** recolor each set's glow to the other's temperature — A must still read machine (the rectilinear coursing, the rack silhouettes carry it), B must still read crafted (the arch rhythm, the wax and grain carry it). If truth dies in the swap, the table fails — this is a pack-audit bar, re-run after every hex change.

**The semantic vocabulary (color means something, or it does not appear):**

| Hue family | Meaning | Where it may appear | Where it may never appear |
|---|---|---|---|
| Steel-cyan / monitor cyan (A_GLOW family) | the machine's truth — reality A | A frames, tells (epoch-0, resolving at 1), the tear accent's family, HUD's A-side readouts, the midpoint spark + the heal glyph (the pinned cyan voice) | in the liminal wing; on B-only surfaces |
| Amber / candlelight (B_GLOW family) | the crafted truth — reality B | B frames, the flip's arrival state, HUD's B-side readouts, the contact spark + the enemy-damage glyph (the pinned amber voice) | in the liminal wing; on A-only surfaces |
| The telegraph flash pair (band 1 `#7DF0FF` / band 2 `#C78B28`) | **strike power** — light vs heavy (OQ-ENM-3's pin, §2B) | the enemy telegraph's flash only, both truths | any surface; decoration; sigil-red never |
| Pure grey (the ramp) | **neither truth** — the honest material | the seam region only (band, frame, fill-by-SYS-09) | anywhere a truth renders; as a "neutral UI" shortcut |
| Rose glow (`PROV_GRIEF_TINT`) | **the player's truth** — memory, grief, the one admitted color | M4's anchor only (the MVP's entire grief-tint presence — AC-DR-15) | any other world surface; the five-errand grief wash is **VS-recorded, not an MVP channel** (§4.2's ruling); the wash layer, when VS-authored, excludes the seam region (VR-SMB-07) |
| Sigil red (`PROV_SIGIL_RED`) | **the lord's presence** — contracts, seals, his court | only where his influence is physically rendered | decoration; HUD segments; weapons; any unearned surface |
| Tear cyan (`PROV_GLITCH_ACCENT`) | the fault in the world | the tear's 1-px edges only | any surface; any duration beyond the tear |

**Colorblind safety (value-first is the primary backup).** Because P2 makes value the reading order, every semantic distinction must survive grayscale *before* a shape/icon backup is needed. The named risks and their backups:

- **Wine red / sigil red (B surfaces vs the lord's marks):** neighboring by construction → backed by **shape** (a seal is a closed sigil form; a banner is fabric with a hem) and by **value** (§4.2's separation note). No meaning rides hue alone.
- **A_GLOW cyan / B_GLOW amber (the two truths' glows):** **not value-separated** (ΔL 0.004 — the two glows are near-equal in lightness) — so hue is not the channel and the grayscale test would fail it; the load-bearing distinctions are **shape** (a strip = A, a pool from a holder = B) and the **key-light direction law** (§2). Recorded honestly: this pair survives by shape + direction, never by value.
- **The ramp's steps (for low-vision players):** the honest claim is that **no meaning rides the ramp's steps** (there is no hue to lose); the even ladder (CR ≥ 1.52 per step) keeps the descent readable for low-vision players, but nothing is encoded in the steps themselves.
- **Telegraphs:** color-flash is *always* paired with shape (§2B) — a colorblind player reads the telegraph from the shape alone.

**The A/B hue-set extraction rule (art-bible-side definition of F-SMB-07's inputs).** The A/B hue sets include only members with **C ≥ 0.05**; near-achromatic slots (the slates, the voids, the parchment neutrals at C 0.013–0.049) are excluded because their hue is unstable under pack normalization and would arbitrarily shrink the feasible interval. **The rule is load-bearing and needs its countersign: the threshold change is what keeps the recorded candidate feasible — at the prior provisional 0.02 the A slates (h 236–244, C 0.022–0.029) qualify and push the free arc's lower bound to 284°, making [255, 275) infeasible; at the pinned 0.05 the interval is [255, 304.8].** *(The 255 floor is `ADM_HUE_BAND` [255, 325]'s.)* **Both intervals, printed:** [284, 304.8] at 0.02 · **[255, 304.8] at 0.05 (the pinned rule)**. The set definition changes F-SMB-07's *output* (it is computed from the sets), so the countersign is **SYS-09's owner + SYS-11's owner** (the OQ-2/OQ-3 pattern), at the gate **before the first SYS-11 story**; until countersigned, the recorded arithmetic is the art-bible's proposal, and SYS-11's `hue_hash` guard (F-SMB-04) fails the tint automatically if the sets move unrecorded. With the §4.5 placeholders: **A = {206.6, 210.3}, B = {14.1, 33.2, 74.6, 74.9, 78.5}** (dormant members included, per F-SMB-05), grief 344.8 → the feasible interval is **[255, 304.8]** (open arcs; a hue exactly 40° from a member stays feasible) — non-empty, and the recorded candidate h 275 sits inside. The same arithmetic with the source-C-0.034 tint family (`#42465A / #5D6277 / #7D8298 / #9EA3BA`, h 274.6–275.9, ΔL vs ramp ≤ 0.004, rendered C ≈ 0.0102 at α 0.30) is the recorded A-ratification data. *(P1 margin note: with the ramp pinned at C 0.000, P1's bound is min(0 + 0.035, 0.045) = **0.035** — the recorded family's C 0.034 passes by 0.001; F-SMB-05's worked example assumes a chromatic ramp (C 0.02–0.03) that VR-SMB-01 forbids, so its 0.055 bound is illustrative, not applicable.)*

**`ADM_ALPHA_MAX` = 0.30** (knob range [0, 0.5]; VR-SMB-08's target) — recorded for the re-open path and §8: the floor-quantized array at 0.30 is `[15, 30, 45, 61, 76]/255` (monotone, max ≤ 0.30, ≥ 1/255; F-SMB-06's floor law — never round to 128/255).

### 4B. Palette Export

`design/art/palette.json` is the machine-readable source for `/asset-spec` and the AI generation prompts (JSON only — a Godot project has no CSS consumer; CSS is added if a web prototype appears; the recorded default). It carries every §4 entry with `hex`, `oklch`, `status`, `role`, `context`, and the colorblind backup where one exists. The JSON is generated *from* this section; this section is the contract, the JSON is the export. (Written alongside this bible.)

### 4C. Typography Spec

**Text in this world is printed by the world.** All in-game text is diegetic-first: the print layer ("MEMORY CACHED", the serial numbers stamped on her chassis, the error-code stencils on A's walls, the memory fragments' written voice) is the game's primary text surface; screen-space type exists only where the fiction cannot hold it (the pause map's labels, the settings surface).

- **Families (pixel fonts only):** one display family (titles, chapter headers, the court's formal register) + one body/mono family (logs, item descriptions, the counter, damage numbers). Both are pixel-grid fonts at the art resolution; no outline font, no anti-aliased TTF rendered into the art res. Named candidates are an asset-spec decision; the bible pins the *constraints*, not the storefront.
- **The pixel tiers at 480×270** (the named tiers at their art-px sizes — a naming scale, not a strict geometric progression; base 16):

| Tier | Size (art px) | Use |
|---|---|---|
| caption | 10 | the map's labels, the counter's fine print |
| body | 16 | logs, descriptions, dialogue-adjacent text |
| lead | 20 | memory fragments' headers |
| subhead | 24 | menu section heads |
| headline | 32 | the flip's chapter card, boss names |
| display | 48 | title only |

- **Which surface renders where (the D1 split):** world-space text (the print layer's in-world stamps, damage numbers, the logs' diegetic surfaces) renders **at art resolution inside the world SubViewport**; screen-space text (the pause map's labels, the settings surface, the HUD) renders **at native resolution** (ADR-0001's D1) — where the text-scale accessibility setting applies. The tier table governs the art-res surfaces; native-res UI text scales per SYS-24's settings.
- **Contrast floors:** body text ≥ 4.5:1 against its actual background at ship scale; captions ≥ 3:1. **The ink rule:** the print layer's ink is the truth's void tone (A: `#141A1F` family; B: `#1E1610` family) or the paper tone, whichever the surface carries — **with the light-ink fallback for mid-value steel surfaces**: where void ink on the surface fails the floor (e.g., void on `PROV_A_WALL` ≈ 1.5:1), the ink switches to the frame/glow family's light tone. **The check is owned:** the per-surface tone-pair contrast check runs at the asset-spec pass (owner: art-director; evidence: the checked pairs in `production/qa/evidence/`; a failing pair is a spec defect, not a ship-time discovery).
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
| Acceptance | relaxed upright, arms slightly open, completely smooth unbroken slimmer outline | **the crown persists, healed smooth** — the one state whose crown shows no crack; its unadorned presence (and the halo ring's absence vs Denial) keeps the same-woman read while the body's openness carries the stage (the invariant holds in all five — REVIEW L132) |

  The MVP ships **Denial only**; the other four are VS content recorded here as direction. The rig is one body throughout — same height, same proportions (PROMPT-PACK shot 6).
- **Enemy archetypes** (SYS-13's three; value-separated from backdrops ≥ 2 ramp steps): Husk (T1/HUMAN — human silhouette wrongness), Spitter (T2/DEMONIC — the projectile telegraph is shape-first), Warden (T3/CYBORG — the elite read; the guaranteed post-flip drop). MACHINE unassigned at MVP.
- **The animation evidence standard** (REVIEW doctrine 4, binding): every animation claim ships as a frame strip; committed arcs (anticipation → strike → recovery) with recovery padded 2–3 frames to lock the weight (REVIEW's telegraph-grammar accept); no single-frame GIF ever proves a timing claim.
- **Pixel density rules:** true 1:1 pixel density (the adopted sprite's mixed-resolution hair/armor is the correction list), 1:1 + device scale captures, the green-key/cyan-line cleanup from the sprite refine list.

## 6. Environment Design Language

**The promise: the world is built, not decorated — and it is built twice, on the same bones.**

- **The duality:** chapel-factory (A) ↔ gothic chapel (B) — the locked concept pair's material lists (§3) applied to every room. One tile grid: **16 px tiles** (`TILE_PX` 16), 480×270 base art resolution, integer scaling; the world renders in the D1 SubViewport model at a safe-derived integer scale with the HUD at native resolution (ADR-0001's D1, technical-preferences.md).
- **Pack normalization (the locked AD binding condition 1):** Warped City and Gothicvania never share a frame — one pack per reality; they meet only at seam/glitch transitions. The normalization audit gates promotion from `inbox/` into `assets/`: single tile grid, shared outline color, harmonized saturation, the license check (`assets/LICENSE-MANIFEST.md`). A pack member that fails the audit is re-toned or excluded — never blended by hand into a hybrid material (§8B).
- **Texture philosophy:** value and coursing over detail. One 1 px course line per 16 px tile at ΔL −0.05 (derived shade, same hue, full width, bottom edge, phase-aligned with the hall — world y ≡ 0 mod 16); max 2 values per tile; zero vertical joints (max 1-in-2 stagger); no per-tile bevels, highlights, baked shadows, or outline (SYS-11 VR-SMB-03/04's grammar is the *whole game's* tile grammar, not just the seam's). **Dither is prohibited by default** — a per-asset-spec grant under the 2-value cap is possible and must be recorded in that asset's spec; nowhere is it a silent default (the seam: absolute prohibition, §8B #7).
- **Prop density by room type:** hub/court = sparse, monumental (the architecture is the content); sanctuary = the one hero prop (the terminal/reliquary) + printed details; corridors = none beyond the coursing; arena = the fight's furniture only, pristine; the cistern's wrong-side = the reveal's one new passage, shown not sprung (SYS-02's reveal law).
- **Environmental storytelling — the tells** (D-6's epistemic epoch-0 tells, SYS-09's registry): symmetry that has no reason (the sealed passage's twin), dead conduits, error-code stencils (the print layer). They render in epoch 0 with the A table's own members (no special tell color — TR-DR-008) and resolve at epoch 1 by re-skinning to their B reading — never a scheduled event, never a highlight. **The altar pair is the isomorphism law's free epoch-tell (pinned here):** the steel altar + the single candle is shared geometry — at epoch 0 the flame renders in the A_GLOW family (the machine's one impossible object — a blue-burning candle), at epoch 1 the same coordinates hold the warm candle reading (the B_GLOW family); the flame's temperature flip is a tell the geometry already carries, needing no new prop (the concept's "one impossible object", locked in the masters). The arena's scuffed floor is the pristine lie's one crack (the room's own tell). The seam's missing S frame is load-bearing (a 4-sided frame reads as a picture/door — VR-SMB-04).
- **The room-type kit:** hub, sanctuary (cache), corridor, arena (the Denial pocket, `epoch_pin: 0` — the pristine lie keeps it), the wing (the liminal corridor — its own material law, §4.1). Six MVP rooms on the 16 px grid; every room's bounds are the camera's default limits (SYS-02's room-limits-first).
- **The climbable-surface language (OQ-RWS-7 — the pin SYS-02 assigns to this bible).** A `WALL_CLIMBABLE` segment must **read as climbable at a glance** (TR-RWS-024's visual-honesty clause; the shape-is-memory doctrine) — by **shape rhythm, never by a pointing device** (no glow, no pulse, no unique hue; P3). **The treatment, pinned numerically:** a climbable wall carries a **vertical rhythm of discrete grips at a 2-tile pitch (32 px)** — the visual cadence the climbing motion will sync to (re-pitchable only at a Movement touch, recorded); the grip's footprint is a **½-tile relief step** built inside the wall's own 2-value cap (the wall's own members + their derived shades — no new color); the **minimum tagged run is 4 tiles (64 px)** vertical, so the rhythm reads as a climbable column, not a decorative band. Truth renderings: in A, **maintenance rungs / bolted grips** (the machine's scaffolding); in B, **projecting masonry handhold courses** (the mason's footholds) — same pitch, same silhouette rhythm (the isomorphism law). The rhythm is what separates climbable relief from decorative coursing (coursing is horizontal full-width lines; grips are a vertical rhythm of discrete shapes) and from the seam's no-carvings rule (§8B #7 binds the seam's tiles, not a truth wall's grip relief). **The read test:** a 1:1 capture of RM-05's tagged shaft vs an untagged control wall; n ≥ 5 cold viewers; ≥ 4/5 answer "you could climb that" on the tagged capture and **0** on the control; **owner: art-director; gate: RM-05's asset-spec pass**. RM-05's two parallel tagged segments (3 tiles apart) read as a climbable chimney pair. At MVP no wall-jump ships — the shaft's grips read as interesting relief texture (the shape-is-memory tease), and the language is already pinned so the VS verb lands on walls that always told the truth.
- **The south-termination note (OQ-6 rider, consumed):** the wing's south end continues the terminal LIGHT step — no ledge lip, exit notch, or lit strip (SYS-09's fill/zone; rides SYS-09's next doc touch).

## 7. UI/HUD Visual Direction

**The promise: the interface is a pane of glass, not a second game.**

- **The minimal HUD** (SYS-24 owns the HUD's rendering and settings surface; **its contract input is SYS-32's 9-field camera publication, TR-CAM-015** — `{mode, view_rect_px, player_screen_px, on_screen, authority, shake_offset_px, active_hold, bounds_generation, tick}`; SYS-24 is Not Started and consumes that publication). **The nine-item look list below is therefore this bible's proposal for SYS-24's authoring, not a citation of an existing contract:** the HP bar, the item chip, the memory counter, the map availability, the prompt slot's active verb, the boss bar (arena only), the a11y flags, the clock fields, the settings entry — the *fields* land with SYS-24's GDD; this bible pins their *look*: flat rectangles in the print layer's edge style, the truth's steel-cyan (A contexts) / amber (B contexts) fills, **no red segments ever** (the REVIEW key-art finding; the court-canonical red exception applies only to court-owned UI, none at MVP).
- **Diegetic vs screen-space:** the death counter and "MEMORY CACHED" live in the world (the machine prints them); the HP bar and the map live on the glass (the fiction cannot hold a heartbeat). The split is fixed per surface; a surface's home is not a per-room choice.
- **The touch controls' look** (SYS-01's floating stick + Attack/Jump; Interact bubble; Quick-use chip): translucent value-neutral forms (the ramp's greys are forbidden here — UI is not liminal; the truth's glow family at low alpha over the world), ≥ 44 px touch targets, the frozen world's inert/ghosting state during the flip's freeze (SYS-01's freeze rules — the controls visibly but calmly disengage, no error state).
- **The pause room-grid map** (SYS-25's MVP surface): discovered cells + unexplored-doorway ticks; the grid is the room graph's own rectangles (no artistic re-layout); the current room pulses **once per open** — **an explicit screen-space UI exception** (bounded: once per open, never continuous; the world layer's no-pointing law is §8B #24 and does not govern the glass).
- **The sanctuary menus** (SYS-26's lean-but-accessible stat presentation, the D-2 amendment): the two-slot loadout's cards, the level/points view — the anti-pillar's "stat-spreadsheet density" is the failure mode; the card + one-line lore is the form.
- **Accessibility** (SYS-01's TR-INP-070 baseline; SYS-24's settings): `REDUCED_FLASH` (§2B's static tear), text-scale, contrast floors (§4C), colorblind backups (§4), remapping — each surface names its a11y state in its spec. The `ux-designer` alignment check rides `/ux-design` for the Recalibration screen + touch help overlay before UI stories (the systems-index's UX flag) — it is a downstream handoff, not this bible's gate.

## 8. Asset Standards

**The promise: a file that fails the standard fails review, quietly and early.**

- **Naming:** `snake_case`, matching the tech preferences; `[category]_[subject]_[variant]` with the truth/epoch tag where the asset is truth-specific: `tileset_cistern_a.png` / `tileset_cistern_b.png` (the isomorphism law's data form — the pair ships together, same dimensions, same placements); sprites `spr_pandora001_dash_strip.png` (frame strips, not GIFs); VFX `vfx_<source>_<effect>_strip.png`; UI `ui_<surface>_<element>.png`. No truth-specific asset ships without its twin or its documented single-truth reason.
- **Resolution & format:** art at 480×270 (16 px tiles); PNG (indexed where the palette allows — the palette tables are the palette); sRGB color; nearest-neighbor everywhere (no filtering, no mipmaps, no subpixel sampling — SYS-09's whole-art-px law); captures at 1:1 + device scale.
- **Palette discipline:** every game asset's colors resolve to palette-table members or their derived shades (coursing at ΔL −0.05; the print layer's inks; the rim-light tones = the owning truth's glow family at 1 px). No asset carries a hex outside the tables; a new need is a bible amendment, not a hex picked in a file. Zero hex literals in code (AC-DR-02's literal-grep) — the palette data file is the only hex home.
- **Budgets** (technical-preferences.md): 60 fps / 16.6 ms frame; ≤ 150 draw calls; ~150 MB RAM on mid-range mobile; tilemaps batched per room; the flip's re-material inside SYS-02's 100 ms `REMATERIALIZE_BUDGET_MS`; **the tear's GPU cost ≤ 1.5 ms/frame p95 (OQ-DR-6's bar, adopted in §2B; PR-DR-03/06 measure)**; SYS-11's boot ≤ 1 ms / incremental ≤ 0.1 ms dev asserts.
- **Import settings:** Godot 4.7.2 — nearest-neighbor via the project's canvas-texture filter setting (`rendering/textures/canvas_textures/default_texture_filter` = Nearest; per-node `texture_filter` where an override is needed — there is no per-import 2D filter flag), mipmaps off, lossless compression; the palette data file versioned with the sprite data; the animation frame strips carry their frame-count + fps metadata in the filename or an adjacent `.json`. *(The 4.4–4.7 post-cutoff rule applies: any import API claim is verified against `docs/engine-reference/godot/` before it lands in a spec.)*
- **The pack promotion audit** (before `inbox/` → `assets/`): the §6 normalization list + the license manifest + the discriminator tests (§4) — one audit, three failure exits (re-tone, exclude, escalate).
- **The placeholder → PINNED upgrade path** (SYS-09 TR-DR-002's rule, the bible's operational form — every upgrade names its evidence, owner, gate, and evidence path, in the repo's gate vocabulary):

| Entry class | Pinning evidence | Owner | Gate | Evidence path |
|---|---|---|---|---|
| The A/B slots (16) | the owning pack's nearest existing tone + the normalization audit's pass | art-director + technical-artist | **the pack promotion audit** (before `inbox/` → `assets/`) | `production/qa/evidence/` |
| The liminal ramp + the grief tint | the recorded user decision | art-director | **done** (D-ORCH-02, 2026-11-15 — recorded in §4) | `production/orchestration/decisions.md` |
| `PROV_GLITCH_ACCENT` | the tear's device capture (the accent readable at the tear edges at α 0.9, both flash modes) | art-director + SYS-29's owner | **the MVP device gates** (SYS-09's first device capture pass) | `production/qa/evidence/` |
| `PROV_SIGIL_RED` | the court pass's verified value (+ the ≥ 2-step proof from the grief tint, or the shape-only declaration) | art-director | **the court dressing pass** (the VS-era asset-spec pass named for the court) | `production/qa/evidence/` |
| Any seam-consumed entry re-pin | the admission hashes re-run (F-SMB-04's stale-hash boot failure is the tripwire — a re-pin re-admits or the grey ships) | tools-programmer (CI) | **the SYS-11 admission harness run** | the CI admission record |

  Upgrades happen **in place** (never a fork), PINNED is required before content ship, PLACEHOLDER is legal through the greybox MVP, and a silent re-pin of a PINNED value is forbidden (§8B #25).
- **The evidence standard** rides every asset review (frame strips for anything animated; 1:1 + device-scale captures for anything readable).

## 8B. Style Prohibitions

**The not-do list is the identity's other half.** Each prohibition carries its parent. Violating any of these is a review blocker, not a taste call.

| # | Prohibition | Parent |
|---|---|---|
| 1 | No fifth palette — the seam admits only the ramp + grief; the corridor has no GLOW/ACCENT/HAZARD role | SYS-11 VR-SMB-10; TR-DR-002's three groups |
| 2 | No purple/violet anywhere at MVP — the D-ORCH-01 decline is total (the REVIEW's violet-drift findings; the tint machinery is dormant) | D-ORCH-01; REVIEW L13/L26/L55 |
| 3 | No red as decoration — red only where the lord's presence is physically rendered: his sigils, seals, contracts, his granted Stinger, **and the court's own canonical red (banners, floor seals — court decoration *is* earned red)**; everything else, HUD segments and stray/unearned decoration included, never | the red rule (REVIEW finding 5); AC-DR-02's zero-occurrence bar |
| 4 | No hybrid materials — the packs never share a frame; no hand-blended cross-pack props | the locked AD condition 1; §6 normalization |
| 5 | No per-room exceptions to the palette tables — a new need is a bible amendment | TR-DR-002's isomorphism law |
| 6 | No bloom/halo/glow on the liminal — the pale end is a plane, not a glow | SYS-11 VR-SMB-06; TR-DR-012 |
| 7 | No dither/gradient/noise/glitch vocabulary in the seam's **standing presentation** (the wing still receives the world's tear during the flip window — §2B, TR-DR-012); no second light model there | SYS-11 VR-SMB-02; TR-SMB-005's static law |
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
| 21 | No new hue family in VFX — effects borrow the owning truth's table members or the recorded derived shades; **the flash pair's truth-independence is the recorded exception** (§2B, OQ-ENM-3: the owning GDD's designer-fixed bands) | §2B; P3 |
| 22 | No telling the machinery — no prompt/VFX/audio/HUD mark on the seam; the language law's ban list holds for visual language too | SYS-11 TR-SMB-006/011; SYS-02's language law |
| 23 | No third key-light direction | §2's key-light law |
| 24 | No glow/pulse/highlight/unique hue **in the world layer** that exists to point — the world never beckons. Screen-space UI's own affordances (the map's once-per-open pulse, the HUD's legibility fills, the telegraph flash) are the glass's language — bounded (once-only, value-safe), never the world's | P3; SYS-11's no-pointing law; §7's split |
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

**The internal locked masters** (the corpus is the reference catalog; the skill's Phase 4.5 web search is skipped — the recorded default). Selection rule: a master is listed when it is either an **ENSHRINED shot** or an **ACCEPTED production reference** in REVIEW's Final Selections. The set: 02b the library glitch (flagship frame), 06 the silhouette lineup, 05 the demon court, 01a-clean-v2 + 01b-v2 (the geometry-locked pair), 03-v3 the cache sanctuary, 04-final the surrender, dirge-042 (the ship-grade weapon read), elegy-013 (the boss-drop secondary), lament-v2 (the steel-core regen), and the character anchors (Pandora-001 concept + idle; Lenore's monochrome pair + sprite; the demon-lord concept; Amythia/Depression + arnetria-concept-1/Denial as the grief-rig production references). Each master carries its REVIEW verdict line and is the first-stop reference for its subject.

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
10. **The climbable-surface language** (§6, OQ-RWS-7): the grip-rhythm treatment per truth (A rungs / B handhold courses, **2-tile pitch, ½-tile relief footprint, 4-tile minimum run**); RM-05's tagged shaft is the first asset to carry it; the read test (tagged vs untagged capture, n ≥ 5, ≥ 4/5 + 0 on the control) is a per-asset lint.
11. **The pinned OQ answers this bible delivers** (the handoffs `/asset-spec` consumes):
    - **OQ-ENM-3** (SYS-13's telegraph flash hexes): band 1 = `PROV_A_HAZARD` `#7DF0FF`, band 2 = `#C78B28` (the derived deep amber), ΔL 0.213 ≥ 0.20, band 3 VS-recorded — §2B + §4's semantic vocabulary.
    - **OQ-J3** (SYS-29's art-bible hex pins): the spark pair (contact amber = `PROV_B_GLOW`, midpoint cyan = `PROV_A_GLOW`), the damage-number glyph palette (amber/pale-bone/cyan = `PROV_B_GLOW`/`PROV_B_FRAME`/`PROV_A_GLOW`), the death-sting magnitudes (LOW base / MID ×1.5 / HIGH ×2.2), the grant cue's bespoke VFX family — §2B.
    - **OQ-DR-6** (SYS-09's tear budget + resolution): ≤ 1.5 ms/frame p95 adopted; the resolution pinned by §6's 480×270 / 16 px + ADR-0001's D1 — §2B + §8.
    - **OQ-RWS-7** (SYS-02's wall-tag visual language): pinned in §6 — this item 10.
    - **SYS-11 OQ-1/OQ-4**: closed by D-ORCH-01/02 (§1, §4); the sync rider in the lane report.
12. **The visual twin** (§3): the epoch-0/epoch-1 XOR-diff test of one room — a per-room lint the asset pass runs on the first paired tileset.

---

*End of the art bible. The review log (`design/gdd/reviews/art-bible-review-log.md`) carries the gate trail; the lane report carries the sync request and the OQ-1/OQ-4 closing records.*
