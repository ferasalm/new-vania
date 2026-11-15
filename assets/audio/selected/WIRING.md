# WIRING.md — Prototype SFX wiring map (SYS-04 vocabulary)

The event → file → bus → gain map for `prototypes/sandbox`. Written in the
vocabulary of the landed SYS-04 audio contracts (ADR-0003: five buses + one Master
limiter, a preallocated player pool, per-tick wall-clock gain writes, one duck).
**Prototype-only**: nothing here touches `src/` or the SYS-04 core; the core
replaces all of this when it lands.

Companion files: `README.md` (what each file is + licenses), `GAPS.md` (what no
pack covers). File paths below are relative to `assets/audio/selected/`.

## The graph this map assumes

```
Master (0 dB) ─[limiter: probe-gated, optional at MVP]─▶ device
  ├── Music    (−6 dB)   1 voice   — untouched by this package (no music selected)
  ├── Ambience (−9 dB)   4 voices  — EMPTY at MVP (no event rides it — see Bus groups)
  ├── SFX      (−3 dB)   the gameplay voices below
  └── UI       (−6 dB)   the menu voices below (see the UI caveat)
```

- The five bus names come from ADR-0003 §3; the prototype creates them in
  `default_bus_layout.tres` once and every player sets `bus` from the map. The
  Master limiter is probe-gated in the ADR — the prototype may ship Master at
  0 dB with no effect and add the limiter when the core lands.
- **Gains are per-voice gain writes at play start** — the value the per-tick
  wall-clock writer would hold (in SYS-04 terms: `volume_db = bus_nominal +
  gain`). Each number below is precomputed per file: normalize the file's
  measured peak toward −3 dBFS (SYS-04's one-shot pin) plus an event trim for the
  mix hierarchy. One number per event; tune by ear at playtest, one line each.
- **Retrigger floors** are clock-ms in the prototype; in SYS-04 they are tick
  counts (1/2/3/21/30). The floor values below are the SYS-04 tick values so the
  prototype matches the contract it is rehearsing.
- **Concurrency caps** reuse SYS-04's `Max conc.` discipline: a voice that wants a
  second concurrent instance takes a second slot from its bus pool; a third drops.

## Bus groups — who rides what

- **SFX** (−3 dB nominal): every gameplay event in the map — the hits, the clash,
  the knockdown, the death story, the terminal, the boss's tells and the crack.
- **UI** (−6 dB nominal): menu move / confirm / quit, on the menu screen and on
  the SYSTEM OFFLINE screen. **Caveat (MVP-honest):** SYS-04 reserves the UI bus
  with **zero voices at MVP** and lists "no UI voices, no per-press chatter" as a
  non-goal (ADR-0003 §1/§3). These three rows are `PROTO_UI`: the prototype
  rehearses them on the UI bus so the ear pass can judge them; if they graduate to
  production that is an OQ for the audio-director, not a silent precedent.
- **Ambience** (−9 dB nominal): **no event rides it in this package.** The
  1000 ms hum is an event-driven one-shot (it starts with the revive i-frames and
  hard-stops), not a bed — it rides SFX. The room beds of the next iteration land
  on Ambience; nothing here pre-empts them.
- **Music** (−6 dB nominal): untouched. See the duck below.

## The duck (one duck, one application site)

The death event (`SYSTEM OFFLINE`) is the duck's only source in this suite: on the
death latch it publishes SYS-15's `duck_request {bus: MUSIC, dB: −6,
hold: UNTIL_OFFLINE_EXIT}`; the request is released by the three offline exits —
the module draw, the reconstruct, and the quit — with the offline screen's
tree-exit as the backstop. **At MVP the duck is inert: no music is selected in
this package, so there is nothing to duck.** Wire the request and the release
anyway (one application site, one call) so the offline story is already shaped
when the score lands. The duck never touches SFX/UI/Ambience.

## The map

Gain is dB **relative to the bus nominal** (what the writer adds on top of
−3/−6/−9). "Stop" = mandatory scheduled `stop()`; "natural" = the file rings out.
Hooks name the sandbox script and the moment (line numbers at Main `953edb2`).

### SFX — the duel (`prototypes/sandbox/duel.gd`)

| Event | SYS-04 voice | Hook | File | Bus | Pri | Conc | Floor | Gain | Pitch | Stop |
|---|---|---|---|---|---|---|---|---|---|---|
| light hit | `EV_DAMAGE_TICK` band 1 | `_resolve()` player→enemy branch (`~108`), `attack_raw == 2` | `duel/attack.ogg` | SFX | P2 | 2 | 1 tick | +5.5 | ±2 st | natural |
| heavy hit | `EV_DAMAGE_TICK` band 3 | same branch, `attack_raw == 4` | `duel/shock.wav` | SFX | P2 | 2 | 1 tick | −3.0 | ±1 st | natural |
| counter-clash | `EV_CLASH_CONTACT` | counter branch (`~131`) at `_hitstop(HITSTOP_CLASH_MS)` | `duel/error.wav` | SFX | P2 | 1 | 21 ticks | −2.0 | 0 | natural |
| ↳ midpoint rider | `EV_CLASH_MIDPOINT` | same, +21 logic ticks (~350 ms) later | `duel/error.wav` (reuse) | SFX | P2 | 1 | 21 ticks | −2.0 | −3 st | natural |
| knockdown (1200 ms) | — (`PROTO_KNOCKDOWN`; SYS-04 has no knockdown voice) | `_resolve()` `K.knocks_down(p)` branch (`~142`) — the body is airborne ~120 ms; fire `land` then | `duel/land.wav` | SFX | P2 | 1 | 30 ticks | +2.0 | 0 | natural |
| player hurt *(suppl.)* | `EV_DAMAGE_TICK` band 2 rider | `player.take_hit()` returning true (`player.gd ~255`) | `duel/hurt.wav` | SFX | P2 | 2 | 1 tick | −5.0 | −2…0 st | natural |
| enemy defeat *(suppl.)* | `EV_DEFEAT_TICK` | `_on_enemy_death()` (`~146`) | `duel/kill.ogg` | SFX | P2 | 2 | 2 ticks | +4.0 | ±1 st | natural |
| **death (SYSTEM OFFLINE)** | `EV_DEATH_POWER_DOWN` (P1 signature) | the scenes' `_die()` — fire once at the death latch (`player.gd ~268`), before the screen presents | `shared/death.wav` | SFX | P1 | 1 | latch | +3.5 | 0 | **hard stop 2100 ms** |

### SFX — the cache loop (`prototypes/sandbox/cache.gd`)

| Event | SYS-04 voice | Hook | File | Bus | Pri | Conc | Floor | Gain | Pitch | Stop |
|---|---|---|---|---|---|---|---|---|---|---|
| terminal interact | `EV_MEMORY_CHIME` family (the cache ack) | `_ack_cache()` (`~122`) — fire on the ack, not per tick | `cache/open-terminal.wav` | SFX | P2 | 1 | 21 ticks | 0.0 | 0 | natural |
| module grant | `EV_HEAL_CHIME` family | `_ack_cache()` first-grant branch (`~131`), once per run | `cache/pick-important.wav` | SFX | P1 | 1 | latch per grant | +2.0 | 0 | natural |
| **death** | `EV_DEATH_POWER_DOWN` | `_die()` (`~150`) — pit (`~115`) or seam (`~117`) | `shared/death.wav` | SFX | P1 | 1 | latch | +3.5 | 0 | **hard stop 2100 ms** |

### SFX — the denial lie (`prototypes/sandbox/denial.gd`, `boss.gd`)

| Event | SYS-04 voice | Hook | File | Bus | Pri | Conc | Floor | Gain | Pitch | Stop |
|---|---|---|---|---|---|---|---|---|---|---|
| boss door open | — (`PROTO_DOOR`) | `denial.gd _ready()` (`~55`) — PROTO placement; move to the next iteration's real door trigger | `denial/open-door.wav` | SFX | P2 | 1 | latch per entry | +11.0 | 0 | **hard stop 900 ms** |
| mini-boss title card | — (`PROTO_TITLE`) | `denial.gd _ready()` — fire once ~1.0 s after the door (the card is 1600 ms class) | `denial/rise.ogg` | SFX | P3 | 1 | latch per entry | +8.0 | 0 | natural |
| ring sweep (tell) | — (bespoke boss tell; GAPS) | `boss.gd _begin_strike("sweep")` (`~152`) — at the telegraph's first tick | `denial/beam.ogg` | SFX | P2 | 1 | 21 ticks | +1.5 | ±1 st | natural |
| lifted ring (tell) | — (bespoke boss tell; GAPS) | `boss.gd _begin_strike("lifted")` (`~152`) | `denial/Laser_Shoot.wav` | SFX | P2 | 1 | 21 ticks | −1.0 | 0 | natural |
| the crack beat | — (bespoke; GAPS) | `boss.gd _begin_crack()` (`~183`) — the beat's first tick; the floor releases here (TR-GBF-013) | `denial/explosion.ogg` | SFX | P1 | 1 | latch per run | +1.5 | 0 | natural |
| phase release | — (bespoke; GAPS) | `boss.gd` the `"crack"` state exit (`~113`) — the first idle tick of `LIE_CRACKED` (the cadence tightens, the bar moves) | `denial/unpause.wav` | SFX | P1 | 1 | latch per run | +1.0 | 0 | natural |
| ↳ deflect rider | `EV_DEFLECT` | `_resolve()` `deflect_projectile()` branch (`~139`) at `HITSTOP_DEFLECT_MS` | `duel/error.wav` (reuse) | SFX | P2 | 2 | 3 ticks | −2.0 | −2 st | natural |
| ↳ thrust-tell rider | — | `boss.gd _begin_strike("thrust")` — the cycle's third strike | `denial/beam.ogg` (reuse) | SFX | P2 | 1 | 21 ticks | +1.5 | −3 st | natural |
| ↳ boss-defeat rider *(suppl.)* | — | `boss.gd take_damage()` → `state = "script"` (`~276`), at the recognition beat's first tick | `duel/kill.ogg` (reuse) | SFX | P1 | 1 | latch per run | +4.0 | −4 st | natural |

### SFX — the offline story (`shared/`, all three scenes)

| Event | SYS-04 voice | Hook | File | Bus | Pri | Conc | Floor | Gain | Pitch | Stop |
|---|---|---|---|---|---|---|---|---|---|---|
| revive (module draw) | `EV_REVIVE_BOOT` (P1) | the `"module"` choice handler — with `player.revive()` (`player.gd ~273`) | `shared/powerup.wav` | SFX | P1 | 1 | 30 ticks | +3.0 | 0 | natural |
| the offline hum (1000 ms) | — (`PROTO_HUM`; TR-HD-025's "one second of hum") | fires with the revive, spans `REVIVE_IFRAME_MS`, **cut at 1000 ms** | `shared/alien.wav` | SFX | P1 | 1 | latch per revive | −2.0 (peaks ≈ −12 dBFS) | 0 | **hard stop 1000 ms** |
| designation stamp | `EV_LEVELUP_PRINT` | where the stamp text is set — `"module"` handler (`duel ~192`, `cache ~174`, `denial ~197`) and the `"reconstruct"` path (`cache ~187`) | `shared/switch.wav` | SFX | P3 | 1 | 30 ticks | −7.0 | 0 | natural |

### UI — menu + offline options (`menu.gd`, `offline.gd`)

| Event | SYS-04 voice | Hook | File | Bus | Pri | Conc | Floor | Gain | Pitch | Stop |
|---|---|---|---|---|---|---|---|---|---|---|
| menu move | — (`PROTO_UI`; zero UI voices at MVP — see the caveat) | `menu.gd` W/S (`~34`); `offline.gd _move()` (`~102`) — **not before the 400 ms hold unlocks** (`offline.gd ~81`) | `shared/click.wav` | UI | P3 | 1 | 2 ticks | −3.0 | 0 | natural |
| menu confirm | — (`PROTO_UI`) | `menu.gd _go()` (`~50`); `offline.gd _commit()` (`~111`) | `shared/topen.wav` | UI | P3 | 1 | 6 ticks | −4.0 | 0 | natural |
| quit | — (`PROTO_UI`) | `offline.gd _commit("quit")` / Esc (`~98`); `menu.gd` Esc / the QUIT item (`~47`, `~54`) — fire before the scene change / app exit | `shared/close-terminal.wav` | UI | P3 | 1 | 6 ticks | −4.0 | 0 | natural |

### Priorities in one line

P1 (signature, never steal candidates, latch where named): **death, revive, the
hum, the module grant, the crack beat, the phase release, the module-grant/defeat
riders marked P1.** P2: the hits, the clash, the knockdown, the hurt, the defeat,
the tells, the door, the terminal ack. P3: the stamp, the title card, the UI
chatter. P0 (the reserved tear slot) is untouched by this package — the prototype
has no flip.

## Player budget (prototype arithmetic)

Distinct SFX voices in this map: 18 (16 primary + 2 rider reuse rows that share
files but not slots). Distinct UI voices: 3. The prototype preallocates what it
needs — **21 players** (18 SFX + 3 UI) — well inside SYS-04's 20-voice hard cap
per bus arithmetic only if UI stays empty in production; that reconciliation is
the audio-director's, flagged in GAPS.md. The production voice table (SYS-04 §E.2
— 13 SFX + 4 Ambience + 1 Music = 18) is unchanged by a prototype; this map's
delta voices (`PROTO_KNOCKDOWN`, `PROTO_HUM`, `PROTO_DOOR`, `PROTO_TITLE`, the
boss tells, `PROTO_UI`) are prototype-only until a sound-bible pass adopts them.

## The mandatory hard stops

| File | Stop at | Why |
|---|---|---|
| `shared/death.wav` | 2100 ms | the source is 42.6 s; audible content ends at 2.03 s, then ~40 s of digital silence. A voice left ringing holds a pool slot for nothing. |
| `denial/open-door.wav` | 900 ms | same source quirk; audible content ends at 0.86 s. |
| `shared/alien.wav` | 1000 ms | the hum's window is `REVIVE_IFRAME_MS`; the file is 3.5 s of continuous warble. |

## One-pass wiring recipe (the next prototype iteration)

1. Create the five buses in `prototypes/sandbox/default_bus_layout.tres`
   (Master 0 dB; Music −6; Ambience −9; SFX −3; UI −6). No effects at MVP except
   optionally the Master limiter (probe-gated in the ADR).
2. One `SfxBank` autoload: preload the map as a dictionary —
   `event → {path, bus, gain_db, floor_ms, conc, stop_ms, pitch_range}` — and
   create one `AudioStreamPlayer` per distinct voice (18 SFX + 3 UI), `bus` set
   from the map, `max_polyphony = 1`.
3. `play(event)`: check the floor (`now − last[event] ≥ floor_ms`) and the cap,
   then `volume_db = gain_db`, `pitch_scale = 1 + randf_range(...)`, `play()`,
   and for `stop_ms` rows arm a `get_tree().create_timer(stop_ms)` that calls
   `stop()`.
4. Wire the hooks from the map's Hook column — each is one line at the named
   branch. The three UI hooks fire before `change_scene_to_file`/`quit()` so the
   blip is audible.
5. Arm the duck in the scenes' `_die()` and release it in the three choice
   handlers — one call site, `DuckStage`-shaped, inert until music exists.
