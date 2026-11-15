# The Sandbox Suite — v2

**PROTOTYPE — NOT FOR PRODUCTION.** Throwaway code. It exists to answer one
question: *does the game feel right when its landed numbers are played, not read?*
Nothing here is wired to `src/`, and nothing here should be copied into `src/`.

v2 is the **playtest-feedback pass**: real sprites, a named boss with a new lie,
one button, and no falling deaths. Four playable rooms + a menu, keyboard only,
from a cold start.

```bash
# from the repo root (Windows; use your own Godot 4.7.2 path)
"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --path prototypes/sandbox
```

Or open `prototypes/sandbox/project.godot` in the Godot 4.7.2 editor and press F5.
The main scene is the menu. **No build step, no import step, no plugins** — the
sprites are read as raw PNGs at runtime (`assets.gd`), so a cold clone runs.

---

## What the playtest asked for, and what changed

| # | The feedback | What v2 does |
|---|---|---|
| 1 | *Flat rects are done — use the real sprites* | 90+ sprites copied out of the 24-pack library into `assets/` (self-contained; `inbox/` is a build-time source only). Church, Fort of Illusion, Rocky Pass, Metroidvania Kit, WereWolf, Super Grotto, explosion + magic packs. |
| 2 | *Pandora from the concept art* | Her three green-screen GIFs are chroma-keyed (the screen is an exact 8-colour dither — flood-filled from the border, so her cyan circuits survive) into 12 idle + 8 dash + 5 jump frames on one 128×200 feet-anchored canvas. Attack is an authored 3-frame cyan slash. |
| 3 | *Arnetria from the three-pose sheet* | `IDLE (FLOATING)` / `CAST` / `ATTACK` cropped out of `arnetria-concept-1.jpg` with the labels cut off, white keyed by flood fill (her silver dress is enclosed by linework, so it survives), sine-bobbed at 2.8× the player's height. Her broken clock ring is cut from `arnetria-denial.jpg` and set into the arena backdrop. Mirrors are diamonds holding a flipped, desaturated Pandora. |
| 4 | *The fight: stored damage, a mirror with a timer* | Her bar **does not move**. Every hit prints and is STORED; the store is printed beside the bar. She casts a mirror on a 7 s period with a visible 6 s ring: break it (4 hp) and the whole store lands in one lurch; miss and the store is cleared. The phase ends when the bar finally moves past the stall (20/60). |
| 5 | *One attack button* | `J` only. The press is classified against the enemy's clock: **flash tail → COUNTER** (6, 800 ms stagger), **live swing → CLASH** (both stop, no damage), **anything else → STRIKE** (2, and you eat the swing). The windows are drawn on screen as a live bar with a playhead. |
| 6 | *No fall damage, no falling deaths* | `KILL_Y` is below the room. A fall fades you and hands you back the last ground you actually stood on (a ground probe, not a stale flag). Costs nothing. Pits are routes. |
| 7 | *No room locks outside the boss arena* | `fight.gd` never locks the body. Both mini-bosses leash at 300 px. The only sealed door in the suite is Arnetria's. |
| 8 | *Every boss door looks special* | Two kinds: **plain** (small, dim, rectangular, silent — furniture) and **boss** (a 268 px gothic arch with fluted columns, a cracked sigil, and a slow breath of ice light, composited from the Fort door + church columns). Her door seals with a hot bar across the leaves. |
| 9 | *Mini-bosses from the packs* | `WARDEN — TIER 3` (WereWolf, hp 24) and `THE CHOIR — TIER 2` (church angel, hp 12), each with a title card on first sight and a long-telegraph PUNISH move. Escapable. |
| 10 | *The user must test it themselves* | The command above. Nothing to build. |

**Kept from v1, unchanged:** the cache loop (monochrome + glitch, the three death
options, the 400 ms hold, the 3-digit designation), damage numbers at 700 ms, the
20-segment bone bar (slow pulse at low HP, never red), and the values law.

---

## The rooms

### 1 · THE ONE BUTTON — the ladder, taught by three tiers

HUSK (6) / SPITTER (12) / WARDEN (24) swing at you so the three outcomes can be
felt side by side. The bar above the band is the enemy's own clock: press inside
a zone and that is what the button becomes.

### 2 · THE APPROACH — a room you can walk out of

Two pits (routes, not deaths), a quiet plain door, two named mini-bosses, and her
arch at the far end. Walk away from either fight and it leashes.

### 3 · THE CACHE LOOP — death is still a story

The seam is the kill-zone; the offline screen presents, the options are dead for
400 ms, the designation counter stamps three digits. **The pit no longer kills** —
it fades you and hands you back.

### 4 · ARNETRIA'S ARENA — the Mirror Queen

One door, and it seals behind you.

| Key | Verb |
|---|---|
| `WASD` / arrows | move |
| `Space` | jump |
| `Shift` | dash (140 ms i-frames) |
| `J` | **the button** — strike / clash / counter |
| `F1` | the dev overlay |
| `Esc` | menu |

Her three moves: the **ring sweep** (close, unclashable — step out), the **shard
fling** (counterable, and the shards themselves deflect on the same button), and
the **mirror cast** (the punish window).

---

## The provenance law

Every number comes from a landed contract. Constants live in `consts.gd`, one line
each, with its source named.

| Value | In the sandbox | Source |
|---|---|---|
| `player_max_hp` **20**, `hp_per_point` **2** | the pool, the bar's 20 segments | `entities.yaml` → health-damage.md TR-HD-010 / F-HD-14 |
| low cue **≤ 25%** | the slow 1.6 s pulse, never a flash | health-damage.md |
| `atk1_damage` **2** | the tap's strike | `entities.yaml` |
| `atk2_damage` **4** | the counter's raw (×1.5 = **6**) | `entities.yaml` + combat.md F-CMB-06 |
| `knockdown_power` **2**, 500 + 700 = **1200 ms** | the knockdown floor | `entities.yaml` / movement.md |
| `strike_dmg_p1/p2/p3` **1/2/4** | enemy damage by power | `entities.yaml` |
| tiers **hp 6/12/24**, awards **3/7/14** | HUSK / SPITTER / WARDEN | `entities.yaml` roster |
| `damage_number` **700 ms**, pool 32 | the floating numbers | health-damage.md TR-HD-036 |
| `hitstop_hit/clash/deflect` **70/90/40 ms** | the hit-stops | `entities.yaml` |
| `attack_window_ms` **200**, `intent_window_ms` **140** | the strike budget, the press window | `entities.yaml` |
| `backdash_iframe_ms` **140** | the dash | `entities.yaml` |
| `offline_hold_ms` **400**, `designation_print_digits` **3** | the offline surface | `entities.yaml` |
| `RESTORE_MODULE_HEAL_PCT` **0.5**, `REVIVE_IFRAME_MS` **1000**, cap **1** | the module | health-damage.md TR-HD-025 |
| `flash_min_interval_ms` **350** | the flash law | `entities.yaml` |
| `boss_hp_pool` **60**, `hp_floor` **20** | her pool and the stall | grief-boss-framework.md TR-GBF-006/012 |
| `BOSS_DECISION_CADENCE_MS` **900 / 700** | whole / released | TR-GBF-010 |
| counter stagger **800 ms** | the counter order | combat.md |
| `XP_BOSS` **40**, recognition **2500** + dissolve **1500** | her goodbye | TR-GBF-006 / TR-GBF-021 |
| palette `#D9BC8F` / `#4FC8DC` / `#E8A94A` / `#BFE8F2` | bone / cyan / amber / ice | art bible + the concept art |

**Invented, marked `PROTO` in `consts.gd`:** the one-button ladder's windows
(`COUNTER_WINDOW_MS` 150, `CLASH_WINDOW_MS` 140, the reaches), the mirror's period
/ timer / hp (7000 / 6000 / 4), `BAR_LURCH_MS` 320, `FALL_FADE_MS` 140, `KILL_Y`,
`LEASH_PX` 300, the door pulse, the scales, the strike pacing, the room geometry,
the AI cadence, and the fact that a CLASH deals no damage (the contracts describe
the clash's hitstop, not its damage).

**Deliberate v2 changes to how the landed numbers are felt:**
- The heavy strike is no longer on the player's hand — one button means one strike
  (2). `atk2_damage` 4 is still felt, as the counter's raw (×1.5 = 6), which makes
  the punish meaningfully bigger than the tap.
- `env_void_damage` is **not** applied to pits. It still applies to the seam.
- v1's "three whiffed sweeps crack the halo" is retired; the crack is now the
  mirror's timer.

---

## The assets

`tools/build_assets.py` builds everything in `assets/` from the concept art and the
downloaded packs, and writes `assets/MANIFEST.txt` naming the source of every file:

```bash
python tools/build_assets.py --src <repo>/inbox/downloads/organized/art
```

The game never reads `inbox/` — only `assets/`.

**License:** every pack here is licence-verified (user, 2026-11-16: all itch.io /
MIT GitHub). Promotion from `inbox/` to `assets/` happens on use, at the
asset-spec pass; this prototype is the "use".

**Two honest deviations, both forced by the source art:**
- **Pandora's jump** is 3 airborne poses + idle bookends, not a full 48-frame
  slice. That clip is a different shoot with an overexposed, noisy screen and heavy
  green spill on the body, so a colour-distance key eats her; it is split by hue
  and blob instead, and only the three cleanest poses survive.
- **Arnetria's sprite carries her own clock ring.** The ring is inseparable from
  the pose art (it is behind her, and the gown's silhouette depends on it), so the
  arena's backdrop ring is the one cut from the reference render, set huge and dim
  — the arena is the clock, she is its hand.

---

## Smoke test

```bash
# the contract rules, asserted (69 checks)
"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --headless --path prototypes/sandbox res://smoke.tscn --quit-after 900
```

`smoke.tscn` prints `PASS`/`FAIL` per rule and exits non-zero on any failure. It
covers the values law, the one-button ladder (counter on the flash / clash into the
swing / strike with no threat), the stored damage (bar frozen, store accumulates,
break → lurch, miss → cleared, the stall at 20 → phase 2), the mirror's timer ring,
the door language, no locks, the fall rule (no HP, no death, back in the room), the
cache loop (pit is a route, seam still kills, 400 ms hold), the revive, and that
the real art is wired (12/8/5 frames on one canvas, Arnetria's 381 px crop, the
mirror, the 268 px arch).

`shots.tscn` renders each room to a PNG (`shot_*.png`) — a throwaway visual check
for a human, not a gate.

## What this prototype does NOT have

No save, no audio, no pause menu, no settings, no controller support, no crouch, no
jump-attack, no tilemap collision (the rooms are hand-rolled rects). It is a
feel-test, not a slice.
