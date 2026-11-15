# Sandbox Suite — three rooms to feel

**PROTOTYPE — NOT FOR PRODUCTION.** Throwaway code. It exists to answer one
question: *does the game feel right when its landed numbers are played, not read?*
Nothing here is wired to `src/`, and nothing here should be copied into `src/`.

Three playable scenes + a menu, keyboard only, from a cold start.

```bash
# from the repo root (Windows; use your own Godot 4.7.2 path)
"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --path prototypes/sandbox
```

Or open `prototypes/sandbox/project.godot` in the Godot 4.7.2 editor and press F5.
The main scene is the menu.

---

## The rooms

### 1 · THE DUEL RANGE — the combat feel

An arena with three tier dummies (HUSK / SPITTER / WARDEN). Everything the
combat contract promises, felt in the hand: the light and the heavy, the clash
window, the counter's 1.5×, the 1200 ms floor, the numbers, the bar.

| Key | Verb |
|---|---|
| `WASD` / arrows | move |
| `Space` | jump |
| `Shift` | dash (140 ms i-frames) |
| `J` | light strike — raw **2** |
| `K` | heavy strike — raw **4** |
| `L` | counter stance (300 ms window) — outputs **3** |
| `K` **inside** the counter stance | upgrades the counter to **6** |
| `Esc` | menu |

What to watch for: a heavy hit (power ≥ 2) puts you on the floor for **1200 ms**
(500 knockdown + 700 getup). A counter that meets a strike prints **3** (or **6**
if you pressed `K` in the window) and staggers the dummy **800 ms**. Numbers
float for **700 ms** of world time and freeze with the hit-stop. The bar is 20
segments of pale bone — no red, ever.

### 2 · THE CACHE LOOP — death is a story

A room with a pit, a seam (the kill-zone) and the cache terminal. Walk into a
death edge. It fires **exactly once**.

| Key | Verb |
|---|---|
| `WASD` / arrows | move |
| `Space` | jump (the pit is jumpable — 60 px) |
| walk into the terminal | the cache ack: HP → full, the first ack grants the module |
| `Esc` | menu |

On the offline screen: `W/S` to select, `Enter` to confirm, `1`/`2`/`3` direct.
The three options are dead for **400 ms** (`OFFLINE_HOLD_MS`) and then unlock.
The module option **greys, never hides**.

- **DRAW THE RESTORE MODULE** — reboot on the spot at half a bar
  (`ceil(20 × 0.5)` = 10), **1000 ms** of invulnerability, the module gone.
  An ENVIRONMENT death places you at the last grounded safe spot, never in the hazard.
- **RECONSTRUCT AT THE NEURAL TERMINAL** — the designation counter stamps a new
  **3-digit** number (`001`, `002`, …) and you wake at the terminal with a full bar.
- **QUIT** — back to the menu. Nothing is saved.

### 3 · THE DENIAL LIE — the boss read

One arena, one boss. She is 60 HP. Her bar **stalls at 20/60 = 1/3**: your damage
lands, your numbers print, and the bar does not move. That is not a bug — that is
her.

| Key | Verb |
|---|---|
| `WASD` / arrows | move |
| `Space` | jump |
| `Shift` | dash (140 ms i-frames) |
| `J` / `K` | light / heavy |
| `L` | counter a clashable strike, or **deflect the ring return** |
| `F1` | the dev overlay (off by default — the contract bans a HUD counter) |
| `Esc` | menu |

Her four strikes: the **ring sweep** (unclashable — *step out*, it is the crack's
fuel), the **lifted ring** (the counter's key), the **clasped thrust** (the
clashable power-2 — meet it with a light and you lose), the **ring jab** (the
punish). Out of her reach she throws the **ring return** — deflect it and her own
ring deals 2 back.

**Three unanswered ring sweeps** crack her halo — one hairline, then a second,
then the break — and a **2000 ms** beat takes her: the floor is released, the
decision table resumes tighter, and **the bar finally moves**. No counter, no
number, no text: the halo and the stalled bar are the whole teach. If you die,
the same offline screen presents, and the fight resumes mid-phase on a revive.

---

## The provenance law

Every number in the prototype comes from a landed contract. The constants live in
`consts.gd`, one line each, with its source named. This table is the same mapping.

| Value | In the sandbox | Source |
|---|---|---|
| `player_max_hp` **20** | the player's pool, the bar's 20 segments | `entities.yaml` → health-damage.md TR-HD-010 |
| `hp_per_point` **2** | the CHASSIS step (displayed on the cache surface) | `entities.yaml` → F-HD-14 |
| 20 segments | the bar's segmentation (1 segment = 1 hp) | SYS-24's read of the pool |
| low cue **≤ 25%** | the slow 1.6 s pulse, never a flash | health-damage.md (HP bar clause) |
| `atk1_damage` **2** | light strike | `entities.yaml` |
| `atk2_damage` **4** | heavy strike | `entities.yaml` |
| counter **1.5×** | 3 (light) / 6 (heavy) | combat.md F-CMB-06 |
| `knockdown_power` **2** | power ≥ 2 knocks down | `entities.yaml` |
| `KNOCKDOWN_MS` 500 + `GETUP_MS` 700 = **1200** | the knockdown floor | movement.md / health-damage.md |
| `strike_dmg_p1/p2/p3` **1 / 2 / 4** | enemy strike damage by power | `entities.yaml` |
| enemy tiers **hp 6 / 12 / 24**, awards **3 / 7 / 14** | HUSK / SPITTER / WARDEN | `entities.yaml` `enemy_archetype_roster` (XP_T1/T2/T3) |
| `damage_number` **700 ms**, pool 32 | the floating numbers | health-damage.md TR-HD-036 |
| `hitstop_hit/clash/deflect` **70 / 90 / 40 ms** | the hit-stops | `entities.yaml` |
| `attack_window_ms` **200** | the strike's active budget | `entities.yaml` |
| `intent_window_ms` **140** | the counter's window discipline | `entities.yaml` |
| `backdash_iframe_ms` **140** | the dash's i-frames | `entities.yaml` |
| `offline_hold_ms` **400** | the options' unlock | `entities.yaml` |
| `designation_print_digits` **3** | `001`, `002`, … | `entities.yaml` |
| `RESTORE_MODULE_HEAL_PCT` **0.5** | half a bar on the revive | health-damage.md TR-HD-025 |
| `REVIVE_IFRAME_MS` **1000** | the one-second hum | TR-HD-025 |
| `RESTORE_MODULE_CAP_MVP` **1** | one module carried | TR-HD-025 |
| `HEAL_ITEM_AMOUNT` **5**, `CACHE_REFILL` **3** | the Suture / the cache refill (display only) | TR-HD-030 / TR-HD-032 |
| `flash_min_interval_ms` **350** | the crack's single flash respects the law | `entities.yaml` |
| `env_void_damage` = `hp_max` | the pit kills outright | `entities.yaml` |
| `boss_hp_pool` **60** | her pool | grief-boss-framework.md TR-GBF-006 (`BOSS_HP`) |
| `hp_floor` **20** | the stall at 20/60 = 1/3 | TR-GBF-012 |
| `CRACK_WHIFFS_REQUIRED` **3** | three unanswered sweeps | TR-GBF-014 / F-GBF-02 |
| `CRACK_BEAT_MS` **2000** | the crack beat | TR-GBF-013 |
| `BOSS_DECISION_CADENCE_MS` **900 / 700** | the cadence, whole / cracked | TR-GBF-010 |
| ring sweep / lifted ring / clasped thrust / ring jab | 350/80/133 · 500/350/250 · 350/116/133 · 250/133/250; reach 56/40/44/44; power 2/1/2/2 | TR-GBF-007 |
| ring return | damage 2, 200 px/s, 1450 ms, deflect at 360 | TR-GBF-008 |
| counter stagger **800 ms**, lose stagger **500 ms** | the exchange's locks | the counter order / F-CMB-05 |
| `XP_BOSS` **40** | her award (printed on death) | TR-GBF-006 |
| recognition **2500 ms** + dissolve **1500 ms** | the goodbye | TR-GBF-021 |
| palette `#D9BC8F` / `#4FC8DC` / `#E8A94A` | bone / truth accents A, B | art bible |

**Invented (the contracts are silent — marked `PROTO` in the code):** the strike
pacing (startup/active/recovery per attack), the counter stance's 300 ms, walk
speed 132 px/s, gravity/jump, the arena geometry, the enemy AI's cooldown, all
drawing (flat rects, no art), and the seam's position.

## Smoke test

```bash
# boot all four scenes headless
"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --headless --path prototypes/sandbox --quit-after 120

# the contract rules, asserted (33 checks)
"C:/dev/game/Godot_v4.7.2-stable_win64_console.exe" --headless --path prototypes/sandbox res://smoke.tscn --quit-after 900
```

`smoke.tscn` prints `PASS`/`FAIL` per rule and exits non-zero on any failure. It
covers: the counter's 3/6, the strike table, the knockdown floor, the 3-digit
stamp, the 20-segment pool, the boss's floor clamp (the stall), the three-whiff
crack, the floor release, the post-crack death edge, the 400 ms offline hold, the
duel's hitbox landing the number, the counter's damage reaching her pool, and the
module revive (half a bar + the body lock released) — 33 checks.

`shots.tscn` renders each scene to a PNG (`shot_*.png`) — a throwaway visual check.

## What this prototype does NOT have

No save, no audio, no real art, no pause menu, no settings, no controller
support, no crouch (so the boss's height bands are carried as data but not
enforced), no jump-attack. It is a feel-test, not a slice.
