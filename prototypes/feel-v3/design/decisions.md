# Decisions log, proto v4 design

## In plain words

- This file lists the 24 choices you made on 2026-11-18 and 2026-11-19, in plain words, and where each one is written.
- Your choices outrank the older design documents (the GDDs). The second list shows each GDD sentence that is now
  overruled, by file and line, so it can be corrected later.
- Nothing here changes the game yet. The four design files (`map.md`, `rpg-items.md`, `bosses-story.md`,
  `sprites.md`) now follow these choices.

Status: done (log). The GDD corrections themselves: planned (not made; they wait for your yes on the design files).

## The 24 decisions (2026-11-18/19)

| # | Decision, in plain words | Written in |
|---|---|---|
| 1 | Up is the "use" key: levers, talking, items, gear and abilities. Soul orbs and machine scrap are taken by touch. | rpg-items 3.13 |
| 2 | A small corner map plus a full-screen map. After the shift a new blank map sheet fills in as she explores; the old sheet returns after Arnetria. | map §7, rpg-items 3.12 |
| 3 | Weak enemies (2-3 Dirge hits) come back while she stays in the room (10 s, decision 18); the others come back when she re-enters. Rooms easier, bosses harder, slower pace, same movement speed. At most 2 enemy kinds per room. | rpg-items 3.4-3.5, map §2 and §4, bosses appendix |
| 4 | Two gear kinds, found in different places: HARNESSES worn over her body (2 slots) and MODULES inside her (2 slots). The hidden monster room off the lab hallway gives a harness. 3 harnesses and 4 modules in all. | rpg-items 3.9, map §3 |
| 5 | A RESTORE MODULE lets her stand back up where she fell, from the SYSTEM OFFLINE screen. One charge; it refills at a working save terminal. Found in the winch loft. | rpg-items 3.10, map §2 |
| 6 | A level-up refills health, energy and magic and gives 2 points, spent in the CHARACTER screen (offered at once, can wait) or by AUTO. Stats: VIGOR, POWER, GUARD, STAMINA, MAGIC (special damage and max MP). | rpg-items 3.1-3.2 |
| 7 | Drops: soul orbs (magic) and machine scrap. Two new lab enemies: SAWBONES TROLLEY (scrap) and GRAFTED ORDERLY (scrap and soul orbs). Scrap drops more when her health is low and fills a gauge (10). Self-repair: stand still, hold H, scrap and energy become health; a hit stops it. | rpg-items 3.5-3.7, map §2 and §4 |
| 8 | Sutures heal; only the 8 placed in the world exist and they never refill. Used from ITEMS or the QUICKSLOT strip. | rpg-items 3.8 |
| 9 | Taking an item shows its picture and text on a card (Resident Evil style). Weapons, abilities, harnesses and modules get a special show first. | rpg-items 3.13 |
| 10 | LEXICON CORE (enemy names after a hit) lies in the scriptorium off the library. | rpg-items 3.11, map §2 |
| 11 | THE PALLBEARER: about 3 minutes, health 330, stages at 60 % and 25 %. Its body swings the scythe and the drawing matches each attack. It drops Elegy-013. | bosses §2 |
| 12 | THE UNMUZZLED (werewolf) is in the lab's top-left room, reached by normal jumps. He gives the wall jump and replaces the GRIP SERVOS pickup (the ability keeps that name). | bosses §3, map §2 |
| 13 | Three candles open Arnetria's door. She talks before, during and after. Her death ends the shift. Her cracked visor stays in her room (Up shows a line). The time machine falls silent. | bosses §4, map §4 |
| 14 | RECALL at a working save terminal refights beaten bosses: best time plus 25 % of the boss's XP, never a second copy of its weapon or ability. | bosses §5, rpg-items 4 (F11) |
| 15 | Her main idle is your hand-on-hip turn. An image AI redraws each old pose in your palette and detail, then pixel cleanup. Elegy gets its own two-handed moves (+30). Add death and self-repair. The standing jump is the first proof, approved at game speed. No move reuses another move's frames. | sprites |
| 16 | Pandora's voice from ElevenLabs (paid; every generation call needs your yes): 27 lines with text and mood. | bosses §8 |
| 17 | No text that tells the player where to go or what to press. | map §6, bosses §7, rpg-items 3.13 |
| 18 | Weak enemies (2-3 Dirge hits) come back 10 s after dying while she is still in the room (slider `weak_respawn_s`). They return out of her sight and never within 96 px of her. This replaces the 25 s and 40 s figures. | rpg-items 3.5 and 7, map §2 |
| 19 | Rare drops: every enemy kind has one rare drop at 2-5 % (small consumables or minor gear variants), each named in a table. Exactly one strong rare exists in the whole area: the TANK HEART from the GRAFTED ORDERLY, about 2 %, a permanent +20 max health and a full refill. | rpg-items 3.5b, 4 (F13), 7 |
| 20 | A cyborg mini-boss, SEXTON-19 THE BOLTED, waits before the shift in a new optional lab room (OW) off the upper floor of the specimen hall. He drops the BOLT PISTOL. | bosses §3b, map §2-3 and §5, rpg-items 3.5 |
| 21 | BOLT PISTOL: an off-hand ranged weapon on its own button (key N) that works only while DIRGE-042 is in the main hand (Elegy is two-handed). Each shot costs EN. Bolts never trigger levers: the barred lever still needs Elegy's reach. EQUIPMENT gets MAIN HAND and OFF HAND rows. | rpg-items 3.14, 3.12, 4 (F12), 7 |
| 22 | Pandora becomes true 16-bit: about 16 colours plus see-through, a clean 1 px dark outline, flat 2-3 tone shading, about 90 px tall, in a new unique palette you pick from 2-3 candidates in session 1 (saved as `assets/palettes/pandora.gpl` plus a 1 px strip PNG). Your idle, run, slide, crouch and hand-on-hip frames are converted and cleaned; new enemies and bosses match that detail. Off-hand pistol frames are added. | sprites 3b, 4, 5b |
| 23 | The jump proof is made two ways and you pick the better: (a) redrawn over the old `assets/pandora` pose; (b) posed on your Godot rig (`assets/hero_2d_base/pandora-16-bit/pandora/rigging_godot`) and cleaned pixel by pixel. Good sprite sheets guide timing and poses only, never their pixels. | sprites 6 |
| 24 | History: every build session ends with a dated playable build (PC exe and phone APK) in `C:/Users/AUC/opencode-workspace/playable-history/`, never overwritten, listed by a launcher, plus a git tag. | this file only (below) |

## Departs from the GDDs (each now overruled)

| GDD statement (file:line) | What it says | Now |
|---|---|---|
| `design/gdd/health-damage.md:73` | a level-up banks one training point; the point is the only stat growth | 2 points per level over five stats, and a full HP, EN and MP refill (decision 6) |
| `design/gdd/health-damage.md:30`, `design/gdd/cache-stations-death.md:61` | points are a choice made at the cache; the cache is the only place to spend them | spent anywhere in CHARACTER, or by AUTO (decision 6) |
| `design/gdd/health-damage.md:477`, `design/gdd/progression.md:72`, `:80` | highest level 5 (`LEVEL_CAP_MVP`) | highest level 10 |
| `design/gdd/progression.md:72` | XP awards 3 / 7 / 14, boss 40 | per enemy 3-14; bosses 30 / 50 / 80; RECALL 25 % (decision 14) |
| `design/gdd/progression.md:60`, `:108`, `design/gdd/hud.md:145` | no stat sheet, no comparison numbers | a CHARACTER stat screen and green/red comparison numbers in EQUIPMENT (no respec, as before) |
| `design/gdd/progression.md:27` | the two module slots are the only gear choice | two module slots kept, plus two harness slots and a fixed CORE (decision 4) |
| `design/gdd/progression.md:122` | Regulator-000 is the guaranteed Warden-tier part | a found reward in SC~, after the shift |
| `design/gdd/health-damage.md:109`, `:378` | walking over an item does nothing; Interact picks it up | still true for items and gear (Interact = Up), but soul orbs and scrap are taken by touch (decision 1) |
| `design/gdd/health-damage.md:590` | Sutures can drop from enemies | no drops; only 8 placed, never refilled (decision 8) |
| `design/gdd/cache-stations-death.md:112-116` | one restore module per station's first activation, cap 1, used up on use | found once in WL; a fitted part with 1 charge that refills at any working terminal (decision 5) |
| `design/gdd/cache-stations-death.md:29` | after a restore "the module gone" | the module stays; only its charge is spent |

Kept from the GDDs: one POWER point = +8 attack and one VIGOR point = +10 health (the GDD point values, ×5 scale,
`progression.md:72`); DRIVE and FRAME module slots, so two damage bonuses never add up (`progression.md:136-138`,
`:319-329`); a restore rebuilds at half health (`cache-stations-death.md:29`) on the last solid ground after a trap or
pit (`cache-stations-death.md:117-121`); no respec.

Overrules earlier drafts (no GDD line found by search): Sutures refilled at terminals (v1 drafts) → never; specials
ignore all stats → MAGIC scales them; a level-up heals only what it adds → full refill; the wall-jump gift "WARDEN'S
SINEW" → GRIP SERVOS; COUPLER-034 as a harness in GA → a module in LA, with CEREMENT-112 in GA; respawn wait 25 s
(map v1) or 40 s (rpg v1) → 10 s (decision 18); ordinary enemy health −20 % (bosses v1) → unchanged; two different enemy name lists
→ the bosses-story list; the name plate above the enemy for the first few hits → a bottom-left plate on every hit;
RECALL record only → plus 25 % XP; Arnetria's door open at once → three candles. The Pandora master colours (silver-cyan hair, black-teal suit, from your GIFs) → a new 16-colour palette picked in session 1 (decision 22); the image-AI redraw as the only way to make the jump proof → two methods, you pick (decision 23); no enemy drops gear → three minor gear variants can drop (decision 19, in `rpg-items.md` 3.5b).

## Build history (decision 24)

- At the end of every build session the build is saved, not overwritten: a PC exe and a phone APK, both dated, in
  `C:/Users/AUC/opencode-workspace/playable-history/` (proposed folder name per build: `YYYY-MM-DD_N_topic`, with a
  short `build.txt` giving the commit, the tag and what changed, in plain words).
- A launcher in that folder lists every dated build, newest first, and starts the one you pick. Old builds are never
  deleted or replaced; a new session always makes a new folder.
- The same commit gets a git tag (proposed: `build/YYYY-MM-DD-N`), pushed with the checkpoint commit.
- Not designed here: the launcher's exact form (a .cmd list, a small page or a tiny Godot menu). Open for the build session.
