# Every ask, in one list (proto v4)

Written 2026-11-19 after the user played the harmony build and found more than half missing. Sources: the user's
own messages and every answer to a question, 2026-11-17 to 2026-11-19 (transcripts 711ab256, 23ffef18, 0caf524a,
bbe3ffd1), checked against the code by a read-only audit on the area branch (the build played) and the S1 branch.

**Rule: every session reads this file first, and no build goes to the user without a "what is in it" list built
from this file.** Status words: done | in progress | planned | not planned | waiting on user.
"Played?" = was it in the 2026-11-19 harmony build (yes / part / no).

## A. Movement and her frames (2026-11-17)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| A1 | Slide like Order of Ecclesia | yes | done | `player.gd` slide state |
| A2 | Two backdash buttons: one left, one right | yes | done | Q/U left, L/O right |
| A3 | Her own frames replace the Konami hero frames | yes | done | `assets/2x/pandora` |
| A4 | Every missing move drawn new; no frame or motion used by two moves | part | in progress | only the jump is new; 23 groups of identical frames remain (attack = attack2, air attacks, crouch attacks, cast = backdash) |
| A5 | About 90 px, same level of detail as everything else | yes | done (her) | other assets not re-checked |

## B. The backtrack puzzle (2026-11-18 morning)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| B1 | Church's left door locked; the library lever opens it | yes | done | S1 keeps it, lamp instead of text |
| B2 | Vertical hall needs the wall jump; wall jump earned in the lab (now: from the werewolf's room, KN) | yes (old lab relic) | in progress | S1: nothing gives the wall jump yet, so the well cannot be climbed |
| B3 | First boss uses ELEGY-013 against her; she takes it after | yes | done | still taken by touch, not Up (C5) |
| B4 | Save terminal in the room above | yes | done | |
| B5 | Hazard room: new enemies (Rodin models) with surprising telegraphed moves; dynamic hazards that hit hard | yes | done | S1 trims it to 2 kinds, 4 traps (C4) |
| B6 | Bars with a lever behind them that only Elegy reaches | yes | in progress | S1 defect: the lever stands in front of the bars |
| B7 | Cracked wall, then a low opening only a slide passes | yes | in progress | S1 defect: the wall is missing |
| B8 | Time machine asks Yes/No; YES shifts reality: demonic sounds and incantations, new filters, rooms reordered | yes (old) | in progress | S1 defect: the shift crashes (`Organ.charge()` missing) |
| B9 | After the shift the terminal is dead; a special boss door stays shut | yes | done | now the sealed door to Arnetria (C15) |
| B10 | Dying after the shift keeps the world shifted | yes | done | |
| B11 | Windows and Android every time | part | done | the harmony APK was missing; added 2026-11-19 09:15 |

## C. The 16 comments (2026-11-18 evening)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| C1 | Church and boss backdrops without black gaps | no | in progress | fixed on S1, not merged |
| C2 | No filter that makes things harder to see (the library's red) | no | in progress | S1 still tints the library red (0.45) and keeps a vignette: to fix |
| C3 | Draw every move: jump standing and moving (separate), wall jump, all attacks, dynamic idles (hand-on-hip turn first), death, self-repair | part (jump) | planned | session 2 batches; the 12-frame turn exists but the game never plays it |
| C4 | At most 2 enemy kinds per room; weak enemies back in 10 s while she stays, slowly; a lever that turns the traps off; a reward at the end | no | in progress | S1: kinds and respawn done; the winch does not turn traps off; reward not placed |
| C5 | Library: several doors, hazard monsters, a healing item; every pickup with Up, never by touch | part | in progress | S1: 3 doors, moth + scribe; Suture not placed; relic and scythe still by touch |
| C6 | Whole map before and after the shift; corner map + full map; a blank new map after the shift | no | planned | design done (`map.md`); screens in session 2 |
| C7 | Pallbearer: attacks fixed, top tier (about 3 min, 3 stages, its body swings the scythe) | no | planned | session 3 |
| C8 | No hand-holding text | no | in progress | S1 removed the door/lever text; still there: "ITS HANDS ARE YOUR STAIRS", the leech tip, the controls line at the bottom |
| C9 | Lab to 3 ways: save; hallway with a monster room (harness reward) and the Pallbearer; top-left werewolf who wall-jumps and gives the wall jump; a special show for special pickups | part (show) | in progress | S1 rooms exist; harness not placed; werewolf session 3 |
| C10 | Pickup card with picture and text; LEXICON CORE shows descriptive enemy names on hit | part | in progress | card works; item pictures missing; name plate session 2; LEXICON not placed |
| C11 | ITEMS and EQUIPMENT menus | no | planned | session 2 |
| C12 | A room off the hazard room turns the traps off (winch loft) | no | in progress | S1 room and winch exist; traps stay on |
| C13 | Post-shift map reorganised a lot | old version | in progress | S1: 11 new shifted rooms |
| C14 | RPG: XP, levels, 2 points, AUTO, 5 stats with MAGIC, full refill on level-up, orbs, scrap, self-repair, Sutures, rare drops (one strong) | part | in progress | orbs, scrap, self-repair, Suture key, rare drops work; **kills give no XP (missed wiring)**; no way to spend points (CHARACTER, session 2); no XP/level on screen |
| C15 | Arnetria: three candles, dialogue, her death ends the shift, cracked visor | no | planned | session 3; S1 has her room and the candle door |
| C16 | RECALL boss refights at the terminal (best time + some XP) | no | planned | session 2 |

## D. From your answers (2026-11-18)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| D1 | Rooms easier, bosses harder, slower pace, same movement speed | no | planned | balance pass after the bosses |
| D2 | New machine enemies (SAWBONES TROLLEY, GRAFTED ORDERLY); cyborgs drop scrap and soul orbs | no | planned | session 2 |
| D3 | Scrap by touch, more when her health is low, a cap, then self-repair standing still with an animation | part | in progress | works; the repair animation is in the C3 batches |
| D4 | RESTORE MODULE: stand up where she fell, from SYSTEM OFFLINE | no | in progress | S1 places its marker in the winch loft, but nothing gives it |
| D5 | Harness and modules, both, in different places; 2 + 2 slots | no | in progress | logic done; menu session 2; pieces not placed |
| D6 | Sutures: only the ones you find | part | in progress | logic done; none placed |
| D7 | Level-up: offer CHARACTER at once, full HP/EN/MP, 2 points, AUTO, MAGIC raises special damage and max MP | part | in progress | logic only |
| D8 | SEXTON-19 (cyborg mini-boss) drops the BOLT PISTOL: off hand, with Dirge, uses EN | no | planned | session 2 |
| D9 | Elegy gets its own two-handed moves | no | planned | sprites |
| D10 | Her voice (ElevenLabs, your yes on 3 samples first) | no | planned | session 3 |
| D11 | Playable after every session; every build kept and replayable (launcher) | yes | done | `playable-history/` + `play-history.cmd` |
| D12 | True 16-bit with her own palette, saved for Aseprite | part | in progress | palette + `pandora.gpl` done; moves are recoloured, not redrawn yet |

## E. 2026-11-19

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| E1 | Palette A (ash and teal), cyan-glowing eyes and seams; fix the bald-looking spot in her hair | yes | done | |
| E2 | Skin B (oxblood, red strikes, eyes and seams) as an option; save the method | yes (F1) | done | pause-menu switch with the menus (session 2) |
| E3 | Graceful jump from your 3 clips, rig + PixelLab; the crouch faces her way | yes | done | |
| E4 | Attacks as a fencer or dancer: J and I clearly different, crouch, air and cast moves, Elegy and pistol sets, a slim blade on the hit frames | no | planned | needs PixelLab (29.3 left): your yes first |
| E5 | One design and one palette for every frame of a skin | yes | done | recolour; the redraws follow the same rule |
| E6 | Moth test fix; smoke/climb tests rewritten for the new map | n/a | in progress | review done 2026-11-19; climb test being finished |

## How you want the work done

- Plain words; ask on taste, edge cases and critical choices, and explain design documents simply.
- From 2026-11-20 (user's decision): the main Claude session builds everything itself, no briefs or cheap workers;
  one task per chat; hand off at about 220k context. Task order: 1 rooms fix + merge, XP from kills, orb pull,
  hint text; 2 attacks (decision 27) + wall jump; 3 menus + map; 4 machines, SEXTON-19, pistol, RECALL;
  5 Pallbearer + werewolf; 6 Arnetria + voice; 7 remaining frames + pacing.
- The locked tests are never tuned; a test failing twice in a row is reported first.
- Every build hand-off lists, from this file, what is in it and what is NOT.
- Before compaction or after each task, write the state and next steps to a file.
- Every session ends with a dated exe and APK in `playable-history/`, never overwritten, plus a tag.
