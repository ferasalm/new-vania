# Prompt Pack — Concept Tests (User-Driven Generation)

*Created 2026-11-08. You generate these on your own tool (Google Flow / Nano Banana etc.),
drop results in `inbox/art-concepts/`, and the next chat reviews them against the checklist.*

**Suggested naming** (matches the shot numbers): `01a-cold-truth.png`, `01b-warm-truth.png`,
`02-library-glitch.png`, `03-cache-station.png`, `04-surrender.png`, `05-throne-room.png`,
`06-silhouette-lineup.png` — add `-v2`, `-v3` for variants.

**Generation protocol (from the AD gate):**
- Generate 3–4 variants per shot; pick by checklist, not prettiness
- Masters at 16:9; judge every master under a center-crop to ~2.2:1 (simulates a phone) —
  focal point and threat-readability must survive the crop
- Shot 1 works best in **edit mode**: generate 01a first, then EDIT that image into 01b
  (geometry must be provably identical — that's the whole point of the pair)
- Text in generated images will be gibberish; accept it in concepts (production replaces it)

---

## Shot 1A — Cold Truth (chapel-factory, reality A)

```
16-bit pixel art game background, 16:9 widescreen. Interior of a vast chapel reimagined
as a sterile demon-tech factory: pointed gothic arches rendered as cold bulkhead frames,
strictly rectilinear 90/45-degree geometry, desaturated steel-cyan and slate palette,
glowing monitor light strips, rows of server monoliths standing in place of altar pews,
pristine museum-clean surfaces. At center, a steel altar with a single candle burning a
BLUE flame — the room's one impossible object. A single red demon sigil seal glows on the
floor; red appears ONLY there. Clinical sacred horror, serene and unsettling, strong value
contrast, no visual noise, no characters. Style: Castlevania Symphony of the Night, Sega
Saturn era pixel art.
```

## Shot 1B — Warm Truth (same geometry, magic past, reality B)

**Preferred: edit the 01a result with:**
```
Edit this image: keep the camera angle, geometry, arches, pillars and altar position
EXACTLY identical — change only materials and light. The bulkhead arches become gothic
candlelit arches, the server pews become carved stone choir stalls with candles, warm
amber candlelight, wine-red hanging banners, aged parchment tones, incense haze, wax
drips on stone. Same composition, same shapes, wrong world.
```

**Fallback (fresh generation):** same prompt as 1A but replace the material sentences with:
`carved stone gothic arches with candlelight, choir stalls with rows of burning candles,
warm amber light, wine-red hanging banners, incense haze, sacred decay` — keep every
geometry sentence word-for-word.

## Shot 2 — Library Glitching into a Mass Grave

```
16-bit pixel art game background, 16:9 widescreen. One cozy library torn between two
truths: warm amber candlelight, tall wooden bookshelves, a soft armchair with a steaming
cup — and the middle third of the frame is torn by a horizontal glitch band of RGB-shifted
pixel displacement strips; below the band, the same shelves stand as rows of weathered
gothic gravestones in deep snow, cold steel-blue palette, bare trees. One room, two truths.
Melancholy and unsettling, not gory, no characters. Style: Castlevania Symphony of the
Night pixel art.
```

## Shot 3 — Cache Station (save sanctuary)

**Primary concept — the brain cradle (fuses the save ritual with the story's core object):**
```
16-bit pixel art game scene, 16:9 widescreen. A small serene chapel alcove in cold
steel-cyan demon-tech architecture. At center: a tall glass reliquary cradle on a modest
pedestal containing a pale human brain suspended in softly glowing blue fluid, thin dark
cables descending from the ceiling like ceremonial cords. A small white paper strip from
a slot on the pedestal reads "MEMORY CACHED", and beneath it a small counter displays
"002". Soft cyan light pools on the floor. Quiet, reverent, safe — the one sanctuary in a
hostile facility. No red anywhere, no characters. Style: Castlevania SotN pixel art.
```

**Alt concept — kiosk terminal, if you want a simpler object:**
```
16-bit pixel art game scene, 16:9. A small sanctuary alcove in a cold steel-cyan facility:
an iconic sci-fi save terminal on a pedestal, soft cyan light pooling across the floor, a
printed paper strip reading "MEMORY CACHED", a small counter showing "002". The one serene
safe pocket in a hostile facility. No red, no characters.
```

## Shot 4 — The Surrender (Depression boss lowers her weapon)

```
16-bit pixel art game scene, 16:9 widescreen. An inverted cathedral of ice — architecture
hanging upside down from above, pale desaturated blue-white palette, gentle snowfall. A
female android stands centered: her sword lowered in one hand and clearly pointing down
and away, her other hand extended forward with an open palm — an unmistakable gesture of
surrender and offer of trust. Head up, steady gaze with softly glowing amber eyes,
dignified upright stance, absolutely not kneeling or defeated. One warm amber light
touches her face; her silhouette stays clean and readable against the pale world.
Melancholy, tender. Style: SotN pixel art.
```

## Shot 5 — The Demon Lord's Court (hub throne room)

```
16-bit pixel art game background, 16:9 widescreen. The demon lord's court: a
cathedral-scale factory throne hall — chrome saint statues standing in wall alcoves,
industrial buttresses, a circuit-pattern carpet running up the nave to a colossal horned
silhouette seated on a steel throne. Demon-sigil RED at maximum density: red banners, red
floor seals, red light in the circuitry — everywhere his presence is; everything else cold
steel-cyan ambient. A church that is a factory of souls; dramatic irony. No readable
characters besides the distant throne silhouette. Style: SotN pixel art.
```

## Shot 6 — One Rig, Five Grief States (silhouette lineup)

```
Sprite design sheet on a plain off-white background, 16:9. Five SOLID FLAT BLACK
silhouettes — single color, no gradients, no gray, no colored accents — of the SAME female
android, identical height and body proportions, standing in one row, each a different
grief stage told only by pose and contour: 1) Denial: rigid pristine upright stance, hands
clasped, thin halo ring above the head. 2) Anger: mid-lunge, sword raised high overhead,
jagged flame-shaped ragged hair. 3) Bargaining: upright but held together by an external
scaffolding frame, cables trailing and breaking the outline. 4) Depression: deeply hunched,
sword tip resting on the ground supporting her, head bowed, one ruined dangling arm.
5) Acceptance: relaxed upright, arms slightly open, completely smooth unbroken slimmer
outline, distinct from 1. Each silhouette nameable by pose alone.
```

---

## The 8-Point Validity Checklist (judge your results against this)

1. **2-Second Truth Test** — a cold viewer names the reality (A cold-tech / B warm-gothic) from a still in under 2 seconds, no caption
2. **Read-Then-Strike Test** — threats separate from background by *value*, not detail; a telegraph would be visible at 3× scale on a phone screen
3. **Grief Test** — the image teaches one specific thing about her (a viewer guesses the emotional stage uncaptioned)
4. **Death-as-Story Test** — cache/counter reads as narrative device, not HUD litter
5. **SotN Test** — feels like a place worth re-touring; sanctuaries feel like sanctuaries
6. **Production Feasibility** — reducible to ~480×270 pixel art buildable from the owned packs + palette passes
7. **Palette Discipline** — count the colors; red appearing anywhere the demon lord isn't = fail
8. **Anti-Pillar Sweep** — no helpless composition (her posture carries agency), no urgency framing

## Status of the 15 existing AI-generated concepts

All 15 images in `design/art/concepts/` were **rejected by the designer on 2026-11-08**.
They are retained only as style-what-not-to-do reference and can be deleted on request.
The doctrine and shot list survive — the renders didn't.
