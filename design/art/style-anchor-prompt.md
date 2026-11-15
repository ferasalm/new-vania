# Visual Anchor Prompt — Five Errands for the Devil

> Generated: 2026-11-15
> Art Bible: `design/art/art-bible.md` (§1–§4C are this prompt's source)
> Consumer: `/asset-spec` — paste this anchor, then the asset description, then the camera/detail instructions.

## Style Anchor

Use this as the prefix for all asset generations:

```
[style: 16-bit era pixel art, Castlevania Symphony of the Night school, Sega
Saturn texture — clean pixel clusters, no painterly smoothing, no anime/cel
drift, no photoreal texture;
lighting: truth A = cool key from above (monitor strips, ceiling racks),
truth B = warm key from beside (candle pools at holder height) — one key
direction per truth, never mixed in one frame;
colors: reality A anchored by --color-a-glow (steel-cyan monitor light) over
desaturated slate; reality B anchored by --color-b-glow (amber candlelight)
over aged stone and parchment; pure grey exists ONLY as the liminal ramp
(--color-lim-deep/--color-lim-mid/--color-lim-pale/--color-lim-light) and
NEVER reads as "neutral decoration"; rose (--color-grief-tint) is the grief/
memory voice — M4's anchor only; sigil red is the demon lord's physical
presence only — never decoration, never HUD;
composition: centered subject with negative space breathing room; arch
rhythms and doorways as hero shapes; supporting detail capped at 2 values
per tile with one 1px course line per 16px tile;
detail level: pixel-grid production art — value-first legibility, threats
separate from backdrops by 2+ value steps before any color is spent;
camera: side-on 2D game view, medium distance, eye-level for scenes;
negative: no bloom, no halo, no lens flare, no opacity-pulse telegraphs,
no subpixel sampling, no frame-rate-dependent motion, no cutscene framing,
no helpless-horror composition, no gore, no timers/speed lines, no
stat-spreadsheet density, no gibberish text, no characters in environment
concepts, no hybrid cross-pack materials]
```

## Usage

For any asset spec, insert the asset description between the style anchor and
camera/detail instructions:

```
[style anchor as above]
subject: a cache-station alcove — a tall glass reliquary cradle on a modest
pedestal, pale brain suspended in softly glowing blue fluid, thin dark cables
descending like ceremonial cords, a paper strip printing "MEMORY CACHED"
(truth: reality A — cold steel-cyan demon-tech, the one safe pocket)
[camera/detail instructions]
```

## Per-Truth Variants

| Truth | Palette anchor | Lighting adjust | Geometry dialect |
|-------|----------------|-----------------|------------------|
| Reality A (demon-future) | `--color-a-glow` dominant; slates/steels for structure | cool key from above; low ambient contrast, high local contrast at glow edges | strictly rectilinear 90/45°; pointed arches rendered as cold bulkhead frames; server monoliths where pews stand |
| Reality B (magic-past) | `--color-b-glow` dominant; ambers/parchments for structure | warm key from beside; gentle falloff, soft shadows | the same bones rendered as carved gothic — candlelit stone, choir stalls, banners |
| The liminal wing | the ramp only (`--color-lim-*`); `--color-grief-tint` at M4's anchor only | **no key** — sourceless pale light, mild vertical falloff; the ramp is the only light model | plain even coursing; zero detail vocabulary from either pack; quiet, not corrupted |
| The glitch tear (transition only) | full-RGB strips exempt from palette discipline inside the tear; `--color-glitch-accent` at the 1-px tear edges | desaturated content under the tear (depth 0.6 at MAG 0.6) | the tear displaces 5 art px, never tile-aligned; static scanlines 4 art px |

## Palette Name Map (consumes `design/art/palette.json`)

`--color-lim-deep` `#484848` · `--color-lim-mid` `#636363` · `--color-lim-pale` `#838383` ·
`--color-lim-light` `#A4A4A4` · `--color-grief-tint` `#CD6CA6` · `--color-glitch-accent` `#00CFE8` ·
`--color-a-wall` `#2E3A44` · `--color-a-floor` `#46525C` · `--color-a-trim` `#6B7D8A` ·
`--color-a-frame` `#9DAEB9` · `--color-a-glow` `#4FC8DC` · `--color-a-hazard` `#7DF0FF` ·
`--color-a-void` `#141A1F` · `--color-b-wall` `#4A3527` · `--color-b-floor` `#7A6248` ·
`--color-b-trim` `#A98B62` · `--color-b-frame` `#D9BC8F` · `--color-b-glow` `#E8A94A` ·
`--color-b-hazard` `#C24B33` · `--color-b-void` `#1E1610` · `--color-b-seal` `#8E2A3C`

(A/B slot hexes are PLACEHOLDER pending the pack promotion + normalization audit —
the bible §4.5 carries the upgrade rule; regenerate from the JSON after any re-pin.)

## Character Seed Blocks

- **Pandora-001**: android assassin; dark chassis body, light head (value
  inversion); hair sail + tattered hem; loaded stance (weight back, blade hand
  cocked); rim-lit on dark rooms; death counter stamped on the chassis.
- **Lenore Vane**: light body, dark head; spectacles, braid, watch chains
  (timepiece motif); composed-guarded.
- **The demon lord**: hooded silhouette, horns barely breaking the hood line;
  sigils red on forehead/chest — red nowhere else on the body.
- **The grief rig**: one body, five states, crown persists (cracked per state);
  Denial = pristine + halo ring · Anger = overhead sword + burning hair ·
  Bargaining = scaffolding + cables + reaching arm · Depression = sword-as-crutch
  + collapsed shoulder · Acceptance = smooth open outline. Each state must pass
  the 32 px black-silhouette test.
- **Enemies**: Husk (T1) / Spitter (T2) / Warden (T3) — silhouette-first,
  ≥ 2 value steps clear of backdrops, telegraphs = color-flash + shape.
