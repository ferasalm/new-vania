# GAPS.md — What the packs don't cover (AUTHOR-LATER)

Every sandbox event has a file (see WIRING.md), but some events are covered by a
**placeholder** — the closest pack sound standing in for a sound that should be
authored. This file names them honestly, so the ear pass at playtest knows which
rows are "good enough for the feel test" and which rows are waiting for the sound
bible. Placeholder = the file already wired; **AUTHOR-LATER** = bespoke work for
the sound-bible pass (the palette is `PROV_AUD_*` / the audio-director's call).

| # | Event | Why the pack coverage is wrong | Placeholder wired | Bespoke target (AUTHOR-LATER) |
|---|---|---|---|---|
| 1 | **The offline hum (1000 ms)** — `TR-HD-025` "one second of hum" | No pack ships a machine hum or a sustained tone; `Magic Fx 7.ogg` is a 90 s music track, not a sound. | `shared/alien.wav` — a 3.5 s alien warble, cut at 1000 ms, peaks ≈ −12 dBFS. Reads as an eerie device tone. | A low near-sine hum (40–80 Hz + a soft harmonic), 20 ms fade-in, hard cut at 1000 ms, loopable if the i-frame window ever widens. |
| 2 | **Arnetria's ring sweep (tell)** | The ring is her weapon and its metal voice exists nowhere; `beam.ogg` is a generic energy sweep. | `denial/beam.ogg` (0.422 s ≈ the 350 ms telegraph + 80 ms active). | A metallic whoosh with a pitch bend down into the active window; distinct from every other tell. Bespoke boss vocabulary. |
| 3 | **Arnetria's lifted ring (tell)** | The counter's key needs a rising "she is lifting it" cue; `Laser_Shoot.wav` is a gun fire, not a lift. | `denial/Laser_Shoot.wav` (0.566 s ≈ the 500 ms telegraph), −1 dB. | A rising metal shimmer that *invites* the counter — the tell is a teaching tool, it should sound like an opening, not an attack. |
| 4 | **The crack beat (2000 ms)** — the halo breaks | The halo is ceramic/glass; `explosion.ogg` is a generic boom — right size, wrong material. | `denial/explosion.ogg` (0.723 s) at the beat's first tick. | A brittle ceramic crack + shard scatter + a sub drop, sized to the 2000 ms beat (sound leads, silence holds the rest). |
| 5 | **The phase release** — the floor releases, the bar finally moves | `unpause.wav` is a menu blip borrowed for a phase transition. | `denial/unpause.wav` (0.272 s) at the first `LIE_CRACKED` idle tick. | A rising release with the tightened cadence's tick embedded — the "she is faster now" cue. |
| 6 | **The counter-clash** — `EV_CLASH_CONTACT` | SYS-04 wants a high transient clank (120 ms class); `error.wav` is a rejection buzz — right *meaning* (the strike is denied), wrong material. | `duel/error.wav` (0.327 s); the midpoint rider reuses it at −3 st. | Metal-on-metal ring, ~120 ms, plus a distinct midpoint spark; the deflect rider wants a brighter parry ping. |
| 7 | **Mini-boss title card sting** | A title card wants the boss's motif; `rise.ogg` is an enemy-riser from the cemetery demo. | `denial/rise.ogg` (0.441 s) ~1.0 s after the door. | A 2–3 s motif sting that ends before her first telegraph; the same motif should seed the cracked-phase variants. |
| 8 | **The boss door open** | `open-door.wav` covers the event semantically, but the source's audible body is 0.86 s at −13.7 dBFS (boosted +11 dB in wiring) with a broken tail. | `denial/open-door.wav`, hard stop at 900 ms. | A clean heavy door (1.0–1.5 s, no silent tail), presumably the same field as the miniboss arena's dressing. |

## Structural gaps (not sounds — contract deltas to flag, not file)

- **`PROTO_UI` rides a bus SYS-04 reserves empty.** Menu move / confirm / quit are
  wired to the UI bus, whose MVP allocation is **zero voices** (ADR-0003 §3) and
  "no UI voices, no per-press chatter" is a listed non-goal (§1). Either the
  prototype keeps them as prototype-only rehearsals (this package's position), or
  the sound-bible pass files an OQ to give the UI bus voices. **Not decided here.**
- **Six prototype voices have no SYS-04 voice row.** `PROTO_KNOCKDOWN`,
  `PROTO_HUM`, `PROTO_DOOR`, `PROTO_TITLE`, the two boss tells (plus the crack
  pair, which the GDD treats as `PROV_AUD` placeholders). If any graduate to
  production, the voice table (SYS-04 §E.2) grows and the pool arithmetic (18 of
  20) must be re-run. **Not decided here.**
- **The player's own whiff and the enemy strike *tells* are silent.** The brief
  covers strikes landing, not being thrown; the dummies telegraph visually only.
  If the feel test wants swing-tells, that is new scope for the next pass — no
  files were copied for it.

## Excluded on license grounds (not gaps — decisions)

- **Sewers pack** — `player-death.wav` (1.103 s) is the strongest candidate for
  the death slot, but the pack's license PDF is font-encoded and unreadable in
  this pass and the pack has no `LICENSE-MANIFEST.md` row. Excluded per the
  no-guessing law; revisit if the PDF text is extracted.
- **GothicVania-town music** — credit-required (Pascal Belisle); no SFX role.
