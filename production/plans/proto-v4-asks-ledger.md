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
| A4 | Every missing move drawn new; no frame or motion used by two moves | part | in progress | jump and standing J/I are new (attack != attack2 now); air attacks, crouch attacks, cast = backdash remain |
| A5 | About 90 px, same level of detail as everything else | yes | done (her) | other assets not re-checked |

## B. The backtrack puzzle (2026-11-18 morning)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| B1 | Church's left door locked; the library lever opens it | yes | done | S1 keeps it, lamp instead of text |
| B2 | Vertical hall needs the wall jump; wall jump earned in the lab (now: from the werewolf's room, KN) | yes (old lab relic) | in progress | task 1: GRIP SERVOS lies in the kennel (Up); the well is climbable (4 wide, ledges 80 px apart with lips, climb test PASS); the werewolf who drops it: session 5 |
| B3 | First boss uses ELEGY-013 against her; she takes it after | yes | done | still taken by touch, not Up (C5) |
| B4 | Save terminal in the room above | yes | done | |
| B5 | Hazard room: new enemies (Rodin models) with surprising telegraphed moves; dynamic hazards that hit hard | yes | done | S1 trims it to 2 kinds, 4 traps (C4) |
| B6 | Bars with a lever behind them that only Elegy reaches | yes | done | task 1: chapel rebuilt, lever west of the bars |
| B7 | Cracked wall, then a low opening only a slide passes | yes | done | task 1: cracked wall at the chapel's west end, 2-tile crawl to the organ |
| B8 | Time machine asks Yes/No; YES shifts reality: demonic sounds and incantations, new filters, rooms reordered | yes (old) | done | task 1: organ restored (the shift crashed), she wakes beside it |
| B9 | After the shift the terminal is dead; a special boss door stays shut | yes | done | now the sealed door to Arnetria (C15) |
| B10 | Dying after the shift keeps the world shifted | yes | done | |
| B11 | Windows and Android every time | part | done | the harmony APK was missing; added 2026-11-19 09:15 |

## C. The 16 comments (2026-11-18 evening)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| C1 | Church and boss backdrops without black gaps | no | done | merged with the rooms (task 1) |
| C2 | No filter that makes things harder to see (the library's red) | no | done | task 1: library red but not inverted, full brightness; no dark screen edges; well and vault lighter |
| C3 | Draw every move: jump standing and moving (separate), wall jump, all attacks, dynamic idles (hand-on-hip turn first), death, self-repair | part (jump) | planned | session 2 batches; the 12-frame turn exists but the game never plays it |
| C4 | At most 2 enemy kinds per room; weak enemies back in 10 s while she stays, slowly; a lever that turns the traps off; a reward at the end | no | done | task 1: the loft winch stops every chapel trap for good; GOVERNOR-207 on the chapel altar |
| C5 | Library: several doors, hazard monsters, a healing item; every pickup with Up, never by touch | part | done | task 1: Suture on the library ledge; scythe and relic with Up + card |
| C6 | Whole map before and after the shift; corner map + full map; a blank new map after the shift | no | planned | design done (`map.md`); screens in session 2 |
| C7 | Pallbearer: attacks fixed, top tier (about 3 min, 3 stages, its body swings the scythe) | no | planned | session 3 |
| C8 | No hand-holding text | no | done | task 1: removed ITS HANDS ARE YOUR STAIRS, IT WILL NOT LET GO, the leech tip, the controls line, the SEALED line |
| C9 | Lab to 3 ways: save; hallway with a monster room (harness reward) and the Pallbearer; top-left werewolf who wall-jumps and gives the wall jump; a special show for special pickups | part (show) | in progress | task 1: CEREMENT-112 harness in the reliquary, COUPLER-034 in the lab; werewolf session 5 |
| C10 | Pickup card with picture and text; LEXICON CORE shows descriptive enemy names on hit | part | in progress | task 1: LEXICON CORE lies in the scriptorium (Up); item pictures and the name plate: session 3 |
| C11 | ITEMS and EQUIPMENT menus | no | planned | session 2 |
| C12 | A room off the hazard room turns the traps off (winch loft) | no | done | task 1: climb two lipped ledges to the loft; the winch stops the traps |
| C13 | Post-shift map reorganised a lot | old version | done | 11 shifted rooms merged (task 1) |
| C14 | RPG: XP, levels, 2 points, AUTO, 5 stats with MAGIC, full refill on level-up, orbs, scrap, self-repair, Sutures, rare drops (one strong) | part | in progress | task 1: kills give XP (gold number), LV and XP in the top bar, orbs drift to her again; spending points (CHARACTER): session 3 |
| C15 | Arnetria: three candles, dialogue, her death ends the shift, cracked visor | no | planned | session 3; S1 has her room and the candle door |
| C16 | RECALL boss refights at the terminal (best time + some XP) | no | planned | session 2 |

## D. From your answers (2026-11-18)

| # | Ask | Played? | Status | Where it stands |
|---|---|---|---|---|
| D1 | Rooms easier, bosses harder, slower pace, same movement speed | no | planned | balance pass after the bosses |
| D2 | New machine enemies (SAWBONES TROLLEY, GRAFTED ORDERLY); cyborgs drop scrap and soul orbs | no | planned | session 2 |
| D3 | Scrap by touch, more when her health is low, a cap, then self-repair standing still with an animation | part | in progress | works; the repair animation is in the C3 batches |
| D4 | RESTORE MODULE: stand up where she fell, from SYSTEM OFFLINE | no | in progress | task 1: lies in the winch loft (Up); not yet checked in a run |
| D5 | Harness and modules, both, in different places; 2 + 2 slots | no | in progress | task 1: pieces placed (lab, reliquary, chapel, shifted rooms); EQUIPMENT menu session 3 |
| D6 | Sutures: only the ones you find | part | done | task 1: Sutures 1-4 (LB, HW, SH, HZ) and 5-8 after the shift placed |
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
| E4 | Attacks as a fencer or dancer: J and I clearly different, crouch, air and cast moves, Elegy and pistol sets, a slim blade on the hit frames | part (standing J + I) | in progress | 2026-11-19: user asked for level slashes and I like J (no dance): J = right-hand level sweep in front into a low lunge, I = the same lunge left-handed, sword round behind her; the real Dirge is its own layer (appears, swoosh, breaks into sparks). Build proto-v4-level-slash (commit 89eb789); waiting on user: play it. Crouch/air/cast/wall/Elegy next; pistol in task 4 |
| E5 | One design and one palette for every frame of a skin | yes | done | recolour; the redraws follow the same rule |
| E6 | Moth test fix; smoke/climb tests rewritten for the new map | n/a | done | task 1: smoke 145/145 and climb PASS, both locked (`tests_v4/locks/step1.json`) |
| E7 | Well climb too tight: ledge lips (thin planks at each ledge end) instead of a stronger kick | n/a | done | user decision 2026-11-19 (task 1) |
| E8 | Tunnel test: her slide out of a low tunnel may carry her up to 120 px in (was 60) | n/a | done | user decision 2026-11-19 (task 1); the game is unchanged |
| E9 | Every room walkable: no item, door or exit she cannot reach | n/a | done | task 1: `tools/roomreach.py` walks her moves through all 29 rooms; fixed the lab (floors joined, climb to the kennel without the wall jump), the library climb (3 floors joined, before and after the shift), reliquary, hallway, loft, shifted kennel and scriptorium; she now arrives at the door that leads back |

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
