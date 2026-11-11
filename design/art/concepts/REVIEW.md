# AD-CONCEPT-VISUAL Round 2 — Consolidated Concept Review

*Created: 2026-11-11 · Reviewer: art-director gate (6 scoped reviewer passes, ≤6 images each, per the 8-image harness cap) · Scope: 35 user-generated concepts in `design/art/concepts/new/` · Standard: 8-point validity checklist in `PROMPT-PACK.md`*

## Executive verdict

**MIXED — one refinement pass from STRONG.**

The direction survives contact with the actual work: Shot 2 proves the visual thesis in a single frame, the silhouette lineup passes the doctrine it was designed for, and the weapons set returned the only STRONG verdict of the round. Every failure found is localized and fixable with one targeted edit each. No concept requires a full re-think.

| Binding condition | Verdict | One-liner |
|---|---|---|
| Two-truths discipline | **CONCERNS** | Thesis proven (Shot 2, 01a base, Pandora/Lenore value inversion) but stray reds + violet drift show the palette rules need written enforcement in `/art-bible` |
| Mobile readability | **CONCERNS** | Value separation works (Shot 5, dirge-042, Depression); near-black bodies and density hotspots need a rim-light pass |
| Silhouette-first grief states | **PASS (conditional)** | Lineup passed its own test; Anger contour rebuild + the crown-invariant anchor locks it |

---

## Shot masters (planned shots 1–6)

| Shot | Winner | Verdict | Notes |
|---|---|---|---|
| 1A/1B pair | **01a** (as geometry base) | ❌ Pair FAIL | Identical-geometry rule broken: arch rhythm (5 ribs vs 2–3), back wall (portal+window vs cathedral+walkway), foreground furniture, camera eye-line all drift. 01a is the most disciplined Reality-A palette and most reducible — re-paint 01b's materials onto 01a's exact camera. Do not ship the pair as-is. |
| 2 — library glitch | **02b** | ✅ PASS (all tests) | **Flagship frame.** Warm library above the glitch band, cold snowy gravestone field below; both halves nameable; shelves→tombstones echo is the thesis in one image. Full-RGB glitch band exempt from palette discipline (signature VFX). |
| 3 — cache station | **03** | ⚠️ ONE violation | Narrative read PASSES (reliquary, MEMORY CACHED, counter, red-free). **SPECIAL FAIL:** the woman in the stasis tube breaks the "no characters" constraint — delete her. Brain reads pink (minor warm indicator). |
| 4 — surrender | **04** | ⚠️ Re-strike pose | Environment PASSES (inverted ice cathedral still reads Reality A; human, sword lowered ✓). **SPECIAL FAIL:** the open palm — the entire point of the shot — is missing. Silhouette reads "warrior standing," not surrender; purple glow accents = palette drift. Add palm + collapse shoulders. |
| 5 — demon court | **05** | ✅ Court-ready | Max sigil red is CORRECT here (his court). Red-on-dark-teal telegraphs by value at 3×. Statue/sigil density is the only feasibility note. |
| 6 — silhouette lineup | **06** | ✅ Doctrine PASS | True solid black, one row, same body throughout. Per-state: Denial PASS · Anger PASS (strongest contour) · Depression PASS ("sword-as-crutch" — best grief-specific invention) · Acceptance PASS · **Bargaining WEAK** — reads "captive/puppet"; fix = one arm reaching out of the frame (the deal-making gesture). |

## Characters

### Pandora-001 (protagonist android)
- `Pandora-001-concept.jpg` — **REFINE**: mechanical-but-human lands (seams, lit eyes); replace A-pose with an assassin's loaded stance (weight back, blade hand cocked); trim heel height and cape tatters before sprite budgeting.
- `sprites/pandora-001-sprite.jpg` — **REFINE**: key the green background, re-grid to true 1:1 pixel density (hair/armor mixed-resolution), cut cyan line count. Shape itself (hair sail + tattered hem) is production-worthy.
- `sprites/pandora-001-idle.gif` — **ACCEPT**: hair/armor value split locates the head instantly; alert, self-possessed stance.
- `sprites/pandora-001-jump.gif` — **REFINE (evidence, not art)**: single pose proves momentum, not arc. Deliver a frame strip (anticipation → apex tuck → heavy fall) proving the committed SotN arc.
- `sprites/pandora-001-dash.gif` — **REFINE**: near-black body risks vanishing on dark rooms; add rim-light/value separation. Dash itself reads via pose + sparkle (value telegraph ✓).

### Lenore Vane (the woman)
- Both monochrome concepts (`Dr-Lenore-Vane-concept-monochrome.jpg`, `Lenore-Vane-concept-monochrome.jpg`) and `sprites/lenore-vane-sprite.jpg` — **ACCEPT**. Spectacles, braid, watch chains, long coat survive pixelation. Grief state reads as composed-guarded.
- **Discovery — value inversion**: Lenore light-body/dark-head vs Pandora dark-body/white-head makes the two characters unambiguous at a glance, in either reality. → **Carry into `/art-bible`.**
- **Discovery — timepiece motif**: her watch chains rhyme with Arnetria's clock-face imagery; worth re-touring her stages. → carry into `/art-bible`.

### Demon lord
- `demon-lord-concept.jpg` — **ACCEPT**: branded quiet-danger noble; instant read.
- `demon-lord-sprite.jpg` — **REFINE**: forehead sigil was dropped entirely; reads as a generic SotN cloak NPC. Re-carve so chrome jaw + hair + sigil brand survive 32px.
- **Red-rule finding**: red is *unexercised*, not violated — his materials contain zero red. Restore the contract-sigil to the sprite; reserve red strictly for seal/contract states.

### Grief-boss states (one rig, five truths)
| File | State (honest read) | Verdict |
|---|---|---|
| `Amythia-depression.jpg` | Depression — weapon lowered as crutch, head bowed | **ACCEPT — best grief-state read in the set**; survives shape-only reading |
| `arnetria-concept-1.jpg` | Denial — idle/cast/attack poses | **ACCEPT** — pose-breaks the design; silhouette holds in motion |
| `arnetria-denial.jpg` | Denial — poster pose | **REFINE** — key art only; passive arms-down fails agency; blindfold cue dies at 32px (crown+halo carries it) |
| `Ira-anger.jpg` | Anger (weak) | **REFINE** — weapon held LOW (doctrine: raised overhead), hair not burning, violet lightning is an off-doctrine third palette |
| `Ira-anger-masked.jpg` | Not the same rig | **REJECT** — reads as a hulking mech; mask erases face continuity; same-rig doctrine broken |
| `pandora-001-dash.gif` | (reference) | see Pandora above |

**⚠️ Same-woman test: FAILS across the set.** Only shared anchors are slim frame + long dark hair. **Proposed invariant (adopt into `/art-bible`): one anchor per state — the crown persists in all five, cracked differently by grief stage.**

## Weapons

| File | Verdict | Note |
|---|---|---|
| `dirge-042.png` | **ACCEPT — ship-grade** | Protagonist primary. Steel-cyan energy edge on dark tech blade; value structure survives 3× and downsamples to 3 colors. Strip AI noise in cyan field at downsample. |
| `elegy-013.jpg` | **ACCEPT** | Secondary / boss-drop. Crescent value-read excellent; scythe silhouette reads reaper/enemy, not hero-sword (see scythe-consolidation note below). Key the green bg. |
| `lament-006.jpg` | **REFINE** | Blade is 100% glow — no steel anchor; reads as projectile FX at 270p. Re-add a metal core edge; keep the energy. |

- **Red audit: clean.** No improper demon-sigil red on any weapon. (Red would be legitimate only on the demon lord's granted Stinger form.)
- **Name tone-fit: strong.** Grief-liturgy names (Dirge/Elegy/Lament) against cold serial numbers = exactly the goth/demon-tech duality.
- **Scythe consolidation note**: `elegy-013` (scythe silhouette), reviewer finding on `scythe.gif` (design retained as Lenore weapon candidate), and the grief theme converge — decide whether the scythe belongs to the boss/elite-drop identity rather than the protagonist.

## Animation references (`weapons/attack animation example/`)

| File | Verdict | Note |
|---|---|---|
| `Cyberpunk_warrior_swinging_sword_a4c099eb.jpg` | **ACCEPT** | Strongest still: planted follow-through, decaying trail — textbook recovery. |
| `Cyberpunk_warrior_swinging_sword_55d8bd18.jpg` | **ACCEPT** | Windup bookend; keep pose, strip the oversized FX arc. Pair with the above as windup/recovery bookends. |
| `Woman_performing_sword_combo_872c0033.gif` | **ACCEPT** | Best feel reference: committed lunge/thrust, Alucard-flavored. Single-frame caveat. |
| `Cyberpunk Warrior Sword Slash Sprite Sheet.png` | **ACCEPT** | Correct telegraph grammar: anticipation → strike → recovery. Pad recovery 2–3 frames to lock committed feel. |
| `cyber_warrior_upward_slash.gif` / `cyberpunk_swordswoman_slash_attack.gif` | **ACCEPT** | Planted stances, committed weight; timing unverifiable from stills. |
| `scythe.gif` | **REFINE** | Reject as motion evidence; RETAIN the scythe design as Lenore weapon/mood reference. |
| `sword.gif` | **REJECT** | Idle frame; no motion value. |
| `cybernetic-fighter-slash-…541356.gif` | **BLOCKED** | >20 MB — exceeds read cap. Re-export as a compressed contact-sheet PNG or short clip if it is to be judged. |

**Systemic finding:** every animated file is single-frame or under-sampled — none can prove timing. **Evidence standard going forward (adopt into `/art-bible`): animation claims require frame strips, not single-frame GIFs.**

## Key art / store page

- `game-concept.jpg` — **REFINE**: in-game mock / store-page candidate. Red HUD segments (Pandora HP bar, boss bar) break sigil discipline. Recolor to cyan/amber — or earn the red with a visible sigil if that UI belongs to the lord's court.

## Re-generation list (exact single changes, user-driven edits)

| # | Target | Exact change |
|---|---|---|
| 1 | 01b | Re-paint warm-truth materials onto 01a's exact arch rhythm/camera (geometry-locked edit). Pre-step: strip 01A's stray red pipe-wraps/LEDs; drop 01B's duplicate sigil-pattern rug. |
| 2 | 03 | Delete the woman in the stasis tube. |
| 3 | 04 | Add the open palm extended forward + collapse the shoulder line. |
| 4 | Ira-anger | Sword raised overhead + hair ignited (match Shot-6 Anger contour); violet → steel-cyan/amber. |
| 5 | Demon lord sprite | Restore forehead sigil + contract sigil; re-carve so jaw/hair/sigil survive 32px. |
| 6 | lament-006 | Re-add a steel core edge to the blade. |
| 7 | game-concept.jpg | HUD red segments → cyan/amber (or sigil-earned red for court UI). |
| 8 | 06 lineup | Bargaining: add the deal-making reaching arm. |
| 9 (optional) | Blocked GIF | Re-export as compressed contact sheet for review. |

## Doctrine discoveries to carry into `/art-bible`

1. **Value inversion** (Pandora dark-body/white-head vs Lenore light-body/dark-head) — instant dual-readability.
2. **Crown invariant** — one anchor per grief state; the crown persists, cracked differently per stage (fixes the same-woman failure).
3. **Timepiece motif** — Lenore's watch chains ↔ Arnetria's clock-face; rhyming motifs across grief stages.
4. **Animation evidence standard** — frame strips required; single-frame GIFs prove nothing.
5. **Red-rule enforcement in writing** — red = lord's physical presence only (court, seals, contracts, his granted Stinger); HUD and decoration never.
6. **Rim-light rule for near-black bodies** on dark room palettes (mobile readability).

## Final Selections — LOCKED 2026-11-11 (designer-confirmed)

**Shot masters**
- Shot 1 pair: **01a is the geometry base.** 1B will be regenerated as a geometry-locked edit of 01a (pre-step: strip 01A's stray reds; drop 01B's duplicate sigil rug).
- Shot 2: **02b — ENSHRINED** (flagship frame).
- Shot 3: **03 adopted** with the tube-woman deletion.
- Shot 4: **04 adopted** with the open-palm + shoulder-collapse re-strike.
- Shot 5: **05 — ENSHRINED** (demon court).
- Shot 6: **06 — ENSHRINED** (silhouette lineup); Bargaining gets the reaching-arm fix.

**Characters**
- Pandora-001: concept + sprite adopted as design refs pending the refine pass (loaded stance, green-key/re-grid, rim-lit dash, jump frame-strip). Idle ACCEPTED as-is.
- Lenore Vane: both monochrome concepts + sprite **ACCEPTED as the character anchor**.
- Demon lord: concept **ACCEPTED as the character anchor**; sprite pending the sigil-restore refine.

**Grief bosses (locked)**
- Depression = **Amythia** (production reference) · Denial = **arnetria-concept-1** (production reference) + `arnetria-denial` poster (key art only) · Anger = **regenerate** per fixes (sword overhead, burning hair, violet → steel-cyan/amber) · **Ira-anger-masked rejected permanently.**
- **Crown invariant ADOPTED** into `/art-bible`: the crown persists across all five grief states, cracked differently per stage.

**Weapons (locked)**
- **dirge-042 = protagonist primary** (ship-grade) · **elegy-013 = boss/elite-drop secondary** (scythe identity assigned to the boss side) · **lament-006 = third weapon**, pending the steel-core regen.

**Key art**
- **game-concept.jpg ADOPTED** as store-page/key-art candidate after the HUD recolor (cyan/amber, or sigil-earned red for court UI).

**Regen priority order** (user-driven edits): 1) 1B geometry-locked re-paint · 2) 03 tube-woman · 3) 04 open palm · 4) Ira-anger rebuild · 5) demon-lord sprite sigil · 6) lament steel core · 7) key-art HUD recolor · 8) Bargaining arm · 9) (optional) blocked GIF re-export.

## Status

- Review complete. **Winners locked 2026-11-11.**
- Next: execute regen list (user's tool) → `/setup-engine` (Godot 4 pin) → `/art-bible` (formalizes: value inversion, crown invariant, timepiece motif, animation evidence standard, red-rule enforcement, rim-light rule).

---

## Regen Log — flux-2-klein-4b img2img (2026-11-11)

*22 generations, $0.00, executed by the studio (user-approved). Reviewer passes: Wave A, Wave B, fix round, corrective round + direct AD verification. All outputs in `design/art/concepts/regen/`; originals untouched. Known model limitation: klein renders SMOOTHED (no pixel grid) — accepted as concept-grade; final pixels come from asset packs + Aseprite.*

| Item | Outcome | File | Notes |
|---|---|---|---|
| 1A/1B pair geometry | ✅ GEOMETRY-PASS | `01a-clean-v2` + `01b-v2` | Camera, arches, altar, rack footprints, seal placement locked. B-flavor drift (back-wall haze, wax, smoke) acceptable |
| 1A red-strip | ❌ MODEL-LIMITED (4 attempts) | `01a-final` rejected | Klein cannot do selective red removal on this scene — red migrated elsewhere each time. → user-tool item #1 |
| 1B warm re-paint | ✅ PASS | `01b-v2` | Amber candlelight, gothic stone arches, choir stalls, wine-red banners, floor seal red |
| 03 tube-woman | ✅ ACCEPT-WITH-NOTES | `03-v3` | Woman removed, brain white-blue, cyan pool restored, red-free; minor crop tightening |
| 04 surrender | ✅ ACCEPT-WITH-NOTES | `04-final` | Open palm ✓, bowed head, lowered blade, amber orb, violet gone; full shoulder collapse partial → polish list |
| Ira (Anger) rebuild | ✅ PASS-with-notes | `ira-v4` | Sword overhead ✓, flame-greatsword ✓, black hair ✓, violet gone ✓, red gem → cyan ✓; identity drift (front-facing, silver armor, cape, square crop) → polish list |
| Demon-lord sigil | ✅ PASS | `demonlord-sprite-v2` | Sigil red correctly scoped to forehead/chest; face reworked hooded-human → horned demon skull — **designer canon decision pending** |
| lament steel core | ✅ PASS | `lament-v2` | Metal core + rim-only cyan energy |
| Key-art HUD | ✅ PASS | `gameconcept-v2` | Bars amber, zero red; garbled HUD text + boss eye-veil removal logged (polish list) |
| Bargaining arm | ❌ MODEL-LIMITED (3 attempts; final was a no-op) | — | Fine-grained edit inside a 5-figure lineup — → user-tool item #3 |

### User-tool items (exact instructions)

1. **01A red discipline** (edit `new/01a-cold-truth-chapel-factory.jpg`): "Recolor every glowing element — arch rib strips, floor rails, rack LEDs, cable glows — to steel-cyan/teal; red may appear ONLY in the demon-sigil seal on the floor." Re-pair with `01b-v2` afterward (or re-edit 01b from the cleaned 01A).
2. **01A sigil color** (working base `regen/01a-clean-v2.jpg`): recolor the floor seal from cyan to RED — single-element edit.
3. **Bargaining arm** (edit `new/06-silhouette-lineup.jpg`): "Add one arm to the third (scaffolding) silhouette reaching diagonally outward past the frame's right edge, palm-open deal-making gesture; keep all five silhouettes otherwise identical to the source."
4. **Polish list (optional):** 04-final full shoulder collapse · Ira identity polish (dark armor, side-profile lunge) · gameconcept-v2 HUD text (PANDORA-001 01/80, ARNETRIA) + boss eye-veil restore.

### Designer decisions from regen results (2026-11-11)

- **Demon-lord face canon: HYBRID** — hooded silhouette with horns barely breaking the hood line; carries both the employer and the monstrous read at once; finalize the design in `/art-bible`.
- **04-final ACCEPTED** as the surrender scene reference (partial slump stays on the optional polish list).
