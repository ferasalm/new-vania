# Area map, before and after the shift (v2)

## In plain words

- The game still starts in the church. There are 15 rooms before the shift and 11 after it; once Arnetria falls, sheet I returns with her room added (16).
- The library is a crossroads: three doors, a bricked arch that opens only after the shift, the lever, a Suture, and the
  scriptorium with LEXICON CORE (enemy names).
- The lab now has two machine enemies that drop scrap. Its top-left room holds THE UNMUZZLED (wall jump). Its hallway
  leads to the Pallbearer and, through a hole in the floor, to a hidden monster room that gives the CEREMENT-112 harness.
- Every reward has one fixed spot: 8 Sutures, 3 harnesses, 4 modules, 2 abilities, 2 weapons (ELEGY-013 and the off-hand BOLT PISTOL; tables below).
- After the shift the same places join in a new order on a new, blank map sheet. Three candles open Arnetria's door.
  Beating her brings the old sheet back. No text tells you where to go.
- One new optional room, OW (the ordnance ward, cell 16,1), hangs off the lab's upper floor east wall: the cyborg mini-boss SEXTON-19, who drops the BOLT PISTOL. `map.tmpl.md` (now the v2 text with sheet placeholders) and `mapgen2.py` were updated and the sheets rebuilt; the overlap and exit checks pass.

Status: waiting on user (v2.1; the user's decisions of 2026-11-18/19 applied, plus 18 and 20). Game: `prototypes/feel-v3`.
Matches `rpg-items.md` v2 and `bosses-story.md` v2.

Legend (one box = one screen = 24 x 14 tiles): `=` door · `~` low tunnel (slide) · `oo` hole up/down ·
`L` door locked by the library lever · `B` boss door · `X` Arnetria's sealed door · `:` one-way shutter ·
`#` barred wall inside a room · `@` start/respawn · `*` save + RECALL terminal · `!` boss · `$` pickup ·
`c1-c3` candles. Exits in the tables are side + cell offset: `L1` = left edge, second cell row; `U0` = top edge, first column.

## 2. Before the shift (sheet I)

```
                                                                                           +------+
                                                                                           |KN !  |
                            +------+                                                       +--oo--+-------------+------+
                            |WL lev|                                                       |LA                  BOW !  |
+-------------+-------------+--oo--+------+------+             +------+-------------+------+                    +------+------+------+
|OR organ     ~HZ $         #bars         =VA *  |             |SC $? =LB lever $   =S2 *  =                    =HW           BPB !  |
+-------------+---------------------------+--oo--+             +------+             +------+--------------------+------+--oo--+------+------+
                                          |SH    |                    |             |                                  |GA  crabs  $        |
                                          |      +--------------------+             |                                  +--------------------+
                                          |      LCH @ start          =             |
                                          +------+--------------------+-------------+
```

Enemy marks: **W** = weak (dies in 2-3 Dirge hits): one comes back 10 s after it falls while she stays (slider `weak_respawn_s`), out of her sight and never within 96 px,
never more than the room started with. **R** = comes back only when she re-enters.
Weak: hound (3 hits), ghost (3), spitter (3), leech (3), SAWBONES TROLLEY (3, new machine).
Re-entry: choir (4), moth (4), scribe (5), GRAFTED ORDERLY (6, new cyborg), crab (7), warden (13).
Pickups: Up takes items, gear and abilities. Soul orbs and machine scrap (enemy drops) are taken by touch.

| id | name | screens | map cell x,y,w,h | exits (side, target, needs) | enemies (max 2 kinds) | hazards | pickups (press Up) | save |
|---|---|---|---|---|---|---|---|---|
| CH | THE NAVE OF ASH (start) | 3 | 7,4,3,1 | L0 `L` SH (locked until the library lever) · R0 `=` LB | hound 1 W, ghost 1 W | none | none | no |
| LB | THE UNREAD STACKS | 6 | 10,2,2,3 | L2 `=` CH · L0 `=` SC · R0 `=` S2 · L1 bricked arch (shut) | moth 2 R, scribe 1 R | none | lever (opens CH's left door); **Suture 1** on a reading desk at the top of the climb | no |
| SC | THE SCRIPTORIUM | 1 | 9,2,1,1 | R0 `=` LB | none | none | **LEXICON CORE** (ability) on the copying desk | no |
| S2 | CACHE STATION 002 | 1 | 12,2,1,1 | L0 `=` LB · R0 `=` LA | none | none | none | save + RECALL |
| LA | SPECIMEN HALL (lab) | 6 | 13,1,3,2 | L1 `=` S2 · R1 `=` HW · U0 `oo` KN (normal jumps up platforms) · R0 `B` OW (upper floor, east wall) | **trolley 2 W** (lower floor), **orderly 1 R** (upper floor) | none | **COUPLER-034** (module, DRIVE) on a dissection table on the upper floor, near the hole up to KN | no |
| KN | THE KENNEL (lab, top left) | 1 | 13,0,1,1 | D0 `oo` LA (shut during the fight) | mini-boss THE UNMUZZLED | none | **GRIP SERVOS** = wall jump (falls from his claws) | no |
| OW | THE ORDNANCE WARD (lab, optional) | 1 | 16,1,1,1 | L0 `B` LA (upper floor east wall; shuts during the fight, opens when he falls) | mini-boss SEXTON-19 (cyborg) | none | **BOLT PISTOL** (weapon, off hand) falls from his arm-gun | no |
| HW | THE PROCESSIONAL (lab hallway) | 2 | 16,2,2,1 | L0 `=` LA · R0 `B` PB · D1 `oo` GA (hole in the floor, jumpable) | none (breathing room) | none | **Suture 2** on a coffin lid halfway down the hall | no |
| PB | THE PALLBEARER | 1 | 18,2,1,1 | L0 `B` HW (shuts during the fight) | boss THE PALLBEARER | none | **ELEGY-013** (the scythe sticks in the floor) | no |
| GA | THE RELIQUARY OF SHELLS (hidden monster room) | 3 | 17,3,3,1 | U0 `oo` HW (ledge under the hole, normal jump) | locked-in waves: **crab 2 R**, then **orderly 2 R**; bars cover the ledge until the last one falls; offline inside resets the room | none | **CEREMENT-112** (harness, TORSO) on a pedestal at the far east end, lit when the waves end | no |
| SH | THE MARROW WELL | 2 | 6,3,1,2 | R1 `L` CH · U0 `oo` VA (wall jump) | none | none | **Suture 3** in a side alcove high in the well | no |
| VA | CACHE STATION 004 | 1 | 6,2,1,1 | D0 `oo` SH · L0 `=` HZ | none | none | none | save + RECALL |
| HZ | THE THRESHING CHAPEL | 4 | 2,2,4,1 | R0 `=` VA · U2 `oo` WL (wall-jump up the middle wall, east side) · L0 `~` OR (cracked wall: 3 hits, then slide) | crab 2 R, leech 2 W | pendulum 2, crusher 2 | lever behind the bars (Elegy's reach only); **GOVERNOR-207** (module, FRAME) on the altar at the west end; **Suture 4** on a ledge between the two crushers | no |
| WL | THE WINCH LOFT | 1 | 4,1,1,1 | D0 `oo` HZ | leech 1 W | none | winch: stops every trap in HZ for good; **RESTORE MODULE** inside a dead cache drone hanging from the winch chain | no |
| OR | THE ORGAN OF HOURS | 2 | 0,2,2,1 | R0 `~` HZ (arrive sliding) | none | none | the organ: Up, then Yes = the shift | no |

15 rooms, 35 screens, 17 ordinary enemies (today 29): CH 2, LB 3, LA 3, GA 4, HZ 4, WL 1. Both saves sit 2-3 rooms
from a boss. Machines appear only in the lab rooms (LA, GA). The cyborg mini-boss is in OW, also in the lab region, and is not counted as an ordinary enemy.

Pacing (0 calm, 10 hardest), first run about 35-45 minutes:
CH 2 > LB 4 > SC 1 > S2 0 > LA 4 > KN 7 > (optional OW 7) > HW 1 > GA 6 > PB 9 > walk back 2 > SH 3 (first climb, no enemies) >
VA 0 > HZ 6 (3 with the traps off) > WL 3 > OR 1 > the shift 8 (story, not combat).
Boss targets: THE UNMUZZLED about 2 tries, SEXTON-19 about 2-3 (optional), THE PALLBEARER about 3, Arnetria 4-6. Music: HW drops to near silence; boss
doors cut the music; pulling the winch silences every trap sound in HZ.

KN arena: about 320 x 192 px of open space (20 x 12 tiles) inside a 24 x 14 room, ledges on both walls under a cage
roof, which he kicks between. He replaces today's GRIP SERVOS pickup, so the well still needs him first.

OW arena: 20 x 12 open tiles inside a 24 x 14 room, two gurney ledges 3 tiles up; moves and numbers in `bosses-story.md` 3b.

## 3. Critical path and gates, in order

1. CH (start) > LB. Pull the lever (the player may not know what it did yet). Take Suture 1. Optional: SC (LEXICON CORE).
2. LB > S2 (save) > LA. Upper floor: COUPLER-034.
3. LA > climb the platforms > KN. Beat THE UNMUZZLED > GRIP SERVOS (wall jump). Optional branch that tempts, any time after LA: the upper floor's east door > OW > beat SEXTON-19 > BOLT PISTOL (an off-hand gun; no gate needs it).
4. LA > HW (Suture 2) > PB. Beat THE PALLBEARER > ELEGY-013. Optional: the floor hole in HW > GA (two waves) >
   CEREMENT-112. Steps 3 and 4 work in either order.
5. Walk back: LA > S2 > LB > CH > left door > SH (wall-jump climb, Suture 3) > VA (save).
6. VA > HZ. Optional: WL (traps off, RESTORE MODULE). Hit the lever behind the bars with Elegy > bars lift >
   GOVERNOR-207 on the altar; Suture 4 between the crushers > break the cracked wall > slide through the tunnel > OR.
7. OR: Up at the organ, Yes > the shift (section 4).

| gate | where | needs | got at |
|---|---|---|---|
| church left door | CH / SH | library lever pulled | LB |
| climb the well | SH | WALL JUMP | KN |
| barred wall | middle of HZ | ELEGY-013's long reach | PB |
| cracked wall | west end of HZ | 3 hits, any weapon | start |
| low tunnel | HZ > OR | slide | start |
| winch loft | HZ ceiling | WALL JUMP | KN |
| GA's bars | GA ledge | beat both waves | - |
| OW's boss door | LA upper floor, east wall | nothing (optional; it shuts during the fight) | - |
| Arnetria's door (after the shift) | VA~ | three candles lit | KN~, BI, SC~ |

Every reward and where it lies (both sheets):

| reward | kind | room | sheet |
|---|---|---|---|
| LEXICON CORE | ability | SC | I |
| GRIP SERVOS (wall jump) | ability | KN (THE UNMUZZLED) | I |
| ELEGY-013 | weapon | PB (THE PALLBEARER) | I |
| BOLT PISTOL | weapon (off hand) | OW (SEXTON-19) | I |
| COUPLER-034 | module, DRIVE | LA | I |
| GOVERNOR-207 | module, FRAME | HZ | I |
| RESTORE MODULE | module, CORE | WL | I |
| CEREMENT-112 | harness, TORSO | GA | I |
| TETHER-06 | harness, LIMBS | KN~ (with candle 1) | II |
| PALL-090 | harness, TORSO | BI (with candle 2) | II |
| REGULATOR-000 | module, DRIVE | SC~ (with candle 3) | II |
| Sutures 1-4 | healing | LB, HW, SH, HZ | I |
| Sutures 5-8 | healing | SH~, CH~, HZ~, LB~ | II |
| Arnetria's cracked visor | not taken: Up shows a line | AR | after Arnetria |

Why the player wants each branch:
- SC: ink-blue light and the scratch of a pen from a high door in the red library.
- KN: howls carry into the lab; claw marks and fur ring the hole in the ceiling.
- HW > PB: a grand door at the end of a silent hall lined with coffins.
- GA: cyan light glows up through a hole in the hallway floor.
- WL: the pendulum chains run up into a hole in the chapel ceiling; a faint blink of a dead drone shows through it.
- HZ altar: its light shows through the bars the first time the bars stop you.
- LA upper floor: a dissection lamp swings over a table, a part glinting on it.
- OW: a red lamp blinks over a steel door at the far east end of LA's upper floor; the door is dented outward as if something fired at it from inside, and a bell tolls slowly every few seconds.

Soft-lock check: every hole you can drop into has a way out with what you hold at that moment
(GA: normal jump once the bars lift; SH before the wall jump: walk back to CH; KN~ and SH~ after the shift: wall jump,
which the shift requires). GA's bars drop only when she lands in its east half, and lift if she goes offline (the room resets). OW has no hole: its only door shuts during the fight and opens when SEXTON-19 falls or when she goes offline (the room resets).

## 4. After the shift (sheet II)

The same places in a new order, drawn on a new blank map sheet that fills in as she explores. The organ, the dead save
room and the well sit in a row at the top; the trap chapel is next to the organ; the library is in the far west; the
church lies under the chapel; the lab is under the organ; the kennel has sunk below the lab; the Pallbearer's room
hangs above the church. The route is one clockwise loop with three short side branches, each ending at a candle and a
piece of gear.

```
       +-------------+---------------------------+-------------+------+-------------+
       |LB~          =HZ~ flames                 :OR~ @        =VA~   XAR  !!       |
+------+             +------+------+------+------+-------------+--oo--+             |
|SC~c3$~             |      |BI c2 |      |LA~                 |SH~   |             |
+------+             +------+--oo--+------+                    |      +-------------+
       |             =CH~                 =                    =      |
       +-------------+--------------------+------+--oo--+------+------+
                                                 |KN~ c1|
                                                 |      |
                                                 |      |
                                                 +------+
```

| id | name | screens | map cell x,y,w,h | exits (side, target, needs) | enemies (max 2 kinds) | hazards | pickups / goal (press Up) | save |
|---|---|---|---|---|---|---|---|---|
| OR~ | THE HOUR UNWOUND | 2 | 7,0,2,1 | R0 `=` VA~ · L0 `:` HZ~ (shutter, opens only from HZ~) | none | none | none | respawn only (does not recharge the RESTORE MODULE) |
| VA~ | THE SEALED STATION | 1 | 9,0,1,1 | L0 `=` OR~ · D0 `oo` SH~ · R0 `X` AR (three candles) | none | none | dead terminal (no save, no RECALL) | no |
| SH~ | THE DRAINED WELL (mirrored) | 2 | 9,1,1,2 | U0 `oo` VA~ (drop in; wall jump back up) · L1 `=` LA~ | ghost 1 W | none | **Suture 5** at the bottom | no |
| LA~ | THE WAKING HALL (lab) | 6 | 6,1,3,2 | R1 `=` SH~ · L1 `=` CH~ · D1 `oo` KN~ | **trolley 2 W**, choir 2 R | none | none | no |
| KN~ | THE SUNKEN KENNEL (lab) | 2 | 7,3,1,2 | U0 `oo` LA~ (wall jump to climb out) | **orderly 1 R**, ghost 1 W | none | candle 1, at the bottom; **TETHER-06** (harness, LIMBS) in the werewolf's old restraints beside it | no |
| CH~ | THE NAVE UNBURNED | 3 | 3,2,3,1 | R0 `=` LA~ · L0 `=` LB~ · U1 `oo` BI | warden 1 R, hound 2 W | none | **Suture 6** under the altar | no |
| BI | THE EMPTY BIER | 1 | 4,1,1,1 | D0 `oo` CH~ | none | none | candle 2, behind bars: hit their lever with Elegy; **PALL-090** (harness, TORSO) draped over the bier | no |
| LB~ | THE STACKS THAT READ | 6 | 1,0,2,3 | R2 `=` CH~ · L1 `~` SC~ (the bricked arch is now a crawl) · R0 `=` HZ~ | leech 2 W, ghost 1 W | none | **Suture 8** on the top shelf near the HZ~ door | no |
| SC~ | THE BLOTTED SCRIPTORIUM | 1 | 0,1,1,1 | R0 `~` LB~ (slide) | none | none | candle 3; **REGULATOR-000** (module, DRIVE) | no |
| HZ~ | THE KINDLED CHAPEL | 4 | 3,0,4,1 | L0 `=` LB~ · R0 `:` OR~ (lever beside the shutter) | moth 2 R, spitter 1 W | flame vent 3, spikes 1 (no off switch) | **Suture 7** past the last flame vent, by the shutter lever | no |
| AR | THE QUIET RING | 4 | 10,0,2,2 | L0 `X` VA~ (shuts during the fight) | boss ARNETRIA | her attacks | the end of the shift | no |

11 rooms, 32 screens, 16 ordinary enemies: SH~ 1, LA~ 4, KN~ 2, CH~ 3, LB~ 3, HZ~ 3. Machines appear only in the
lab rooms (LA~, KN~). After a death she is rebuilt at the organ (OR~), unless she uses the RESTORE MODULE's charge.
Arnetria is two rooms from the organ: a retry is about an 8 s walk.

Route: OR~ > VA~ (the sealed door, three dark candles) > drop down SH~ > LA~ (branch KN~: candle 1, TETHER-06) > CH~
(branch BI: candle 2, PALL-090) > LB~ (branch SC~ through the crawl: candle 3, REGULATOR-000) > HZ~ > lever > shutter
opens > OR~ > VA~ > the door opens > AR. About 15-20 minutes plus Arnetria.
Pacing: OR~ 2 > VA~ 1 > SH~ 2 > LA~ 4 > KN~ 5 > CH~ 5 > BI 2 > LB~ 4 > SC~ 1 > HZ~ 5 > OR~ 1 > AR 10.

How the world comes back when Arnetria dies (story: `bosses-story.md` §4.7):
- Her ring cracks. The screen tear runs backwards, the colour filters drain, the whispers and the drone stop, and the
  room music returns after two seconds of silence.
- AR stays, in normal colours. Its west door leads to CACHE STATION 004, whose terminal works again (RECALL and the
  RESTORE MODULE's recharge work again too).
- Her cracked visor lies on the floor of AR. Up beside it shows one line about her. It is never taken.
- Sheet I returns with one new room, AR, east of VA (cell 7,2,2,2; sheet below). OW, the ordnance ward, has no twin on sheet II: if she skipped it, SEXTON-19 waits there on the restored sheet.
- Rooms take back their first layouts and enemies. Doors, levers, bars and the winch keep the state she left them in.
  Rewards already taken stay taken. The organ is silent for good: Up at it gives only a dead key thunk.
  RECALL can now refight Arnetria too.

```
                                                                                           +------+
                                                                                           |KN !  |
                            +------+                                                       +--oo--+-------------+------+
                            |WL lev|                                                       |LA                  BOW !  |
+-------------+-------------+--oo--+------+------+-------------+------+-------------+------+                    +------+------+------+
|OR organ     ~HZ $         #bars         =VA *  =AR (visor)   |SC $? =LB lever $   =S2 *  =                    =HW           BPB !  |
+-------------+---------------------------+--oo--+             +------+             +------+--------------------+------+--oo--+------+------+
                                          |SH    |             |      |             |                                  |GA  crabs  $        |
                                          |      +-------------+------+             |                                  +--------------------+
                                          |      LCH @ start          =             |
                                          +------+--------------------+-------------+
```

## 5. Room files: reused, changed, new

Map cell = 24 x 14 tiles (one screen). A room's cell size = its tile size divided by 24 and by 14, rounded.

| room | file | tiles (w x h) | what to do |
|---|---|---|---|
| CH | church.txt | 72 x 16 | changed: hound 1 + ghost 1; backdrop fix (below) |
| LB | library.txt | 48 x 42 (was 44 x 34) | changed: rebuilt for 3 doors + bricked arch; moth + scribe; lever mid-height right; Suture 1 at the top |
| SC | scriptorium.txt | 24 x 14 | new: LEXICON CORE on the copying desk |
| S2 | save.txt | 30 x 14 | reused; terminal gains RECALL |
| LA | lab.txt | 72 x 28 (was 84 x 17) | changed: rebuilt on two floors, hole top-left, doors lower left and lower right, a boss door upper right (to OW); relic removed; trolley spawns (lower floor), orderly spawn and COUPLER-034 table (upper floor) |
| KN | kennel.txt | 24 x 14 | new: 20 x 12 open arena, wall ledges, cage roof |
| OW | ordnance.txt | 24 x 14 | new: 20 x 12 open arena, two gurney ledges 3 tiles up, gun rack of empty hooks, boss door on the left; SEXTON-19 spawn |
| HW | hallway.txt | 48 x 14 | new: coffins; Suture 2 on a lid |
| PB | boss.txt | 30 x 14 | reused; backdrop fix |
| GA | gallery.txt | 72 x 14 | new: two wave spawn groups (crabs, orderlies), bars over the ledge under the hole, CEREMENT-112 pedestal east |
| SH | shaft.txt | 24 x 30 | changed: one side alcove high up for Suture 3 |
| VA | vault.txt | 30 x 15 | reused; terminal gains RECALL |
| HZ | hazard.txt | 96 x 16 (was 100 x 16) | changed: traps 18 > 4, enemies 10 > 4, two kinds; hole up east of the bars; altar (GOVERNOR-207) at the west end; Suture 4 ledge between the crushers |
| WL | loft.txt | 24 x 14 | new: winch, hanging dead drone with the RESTORE MODULE |
| OR | timemachine.txt | 48 x 16 (was 36 x 16) | changed: wider, more breathing room |
| OR~ | timemachine_shift.txt | 48 x 16 | new: shutter left, door right |
| VA~ | vault_shift.txt | 30 x 15 | changed: X door leads to AR; three candle sconces |
| SH~ | shaft.txt, mirrored | 24 x 30 | no new file: add to the mirrored list; Suture 5 at the bottom (a pickup letter in the mirrored copy) |
| LA~ | lab_shift.txt | 72 x 28 | new: doors lower left and right, floor hole, top hole sealed; trolley and choir spawns |
| KN~ | kennel_shift.txt | 24 x 28 | new: hole on top only; orderly and ghost spawns; candle and TETHER-06 at the bottom |
| CH~ | church_shift.txt | 72 x 16 | new (start from the mirrored church, add the hole up); Suture 6 under the altar |
| BI | boss_shift.txt | 30 x 14 | new: floor hole, bars + lever + candle, PALL-090 on the bier, no door |
| LB~ | library_shift.txt | 48 x 42 | new: doors top right and bottom right, crawl on the left; Suture 8 top shelf |
| SC~ | scriptorium_shift.txt | 24 x 14 | new: crawl on the right, candle and REGULATOR-000 on the left |
| HZ~ | hazard_shift.txt | 96 x 16 | new: flames + spikes, door left, shutter right; Suture 7 by the shutter lever |
| AR | arnetria.txt | 48 x 28 | new: tall arena, two platform heights; visor spot (after the fight) |
| - | save2.txt | 30 x 14 | off the map; kept for open point 1 |

The per-room shift files replace today's `SHIFT_ROUTES` and the church/library mirror. New grid letters are needed
for: bricked arch, candle shrine, one-way shutter, winch lever, werewolf spawn, cyborg boss spawn, Arnetria spawn, trolley spawn, orderly
spawn, wave group (GA), Suture, module, harness, ability, weapon, and the visor.

Backdrops (the user's first ask): `room.gd` draws the church and boss wall as 192 px tall panels with 40 px gaps,
so black shows between and above them. The church needs a wall that covers 1152 x 256 px with no gaps, the boss room
480 x 224 px. This is art and drawing work, not a map change.

## 6. Clues without words (decision 17: no handholding text)

Hint texts to remove (keep names and story lines such as MEMORY CACHED, NO SIGNAL, LAID TO REST):

| today | replace with |
|---|---|
| "Far below, a door grinds open." (`props.gd:54`) | a chain run and a distant boom from the left, dust falls; the church door lamp turns from red to pale; its map mark turns from red to white |
| locked-door text (`door.gd:57`, incl. "UNTIL THE NEXT UPDATE") | a heavy thud and chain rattle; the door's red lamp blinks; the X door shows three dark candles |
| "GRIP SERVOS ONLINE - jump at a wall and hold..." (`main.gd:234`) | THE UNMUZZLED shows the move all fight; the card shows only the name and description |
| "ELEGY-013 - ... E (or SWAP) to change weapon." (`main.gd:436`) | the card only; the SWAP button pulses once; keys stay listed in the pause CONTROLS page |
| "ITS HANDS ARE YOUR STAIRS" (`main.gd:458`), "IT WILL NOT LET GO" (`boss.gd:111`) | the hands glow where she can stand; the grip shows by animation and sound |
| "The bars grind upward.", "THE ORGAN IS SILENT." | sound only (a grind; a dead key thunk) |
| "W: pull the lever", "W: use the machine" | the small hand bubble, no words |

Clues placed in the world:
- Claw marks on the well walls where a wall kick lands: something climbed here.
- Fur and claw marks around the lab's ceiling hole; howls carry into the lab.
- A scythe carved over the barred wall; the lever sits just past Dirge's reach, so the first swing visibly falls short.
- Dust trickles from the cracked wall and air blows out of it; the organ hum grows louder near it.
- The bricked arch in the library is a different brick colour in an arch shape; after the shift, cold air blows out.
- After the shift, each branch entrance flickers with the same candle light as the sconces on the sealed door.
  Lighting a candle (Up) tolls a bell and lights one sconce on that door.
- Oil stains and wheel tracks lead along the lab floors where the trolleys patrol.
- The map: a room appears only once entered; an exit seen but not used is a small gap; a locked door is red;
  the sealed door shows three dots that fill in.

## 7. Map screen (decision 2; menu rules in `rpg-items.md` 3.12)

- Corner minimap: 5 x 3 cells around her, top right; her cell blinks. Tap it (touch) or press M to open the full map.
- Full map: every visited cell; saves `*`, bosses `!`, doors as ticks at the exit offsets in the tables.
- Each table row gives the room's cell rectangle (x, y, w, h) and its exits as side + offset: enough to draw the map.
- Before the shift: sheet I. After the shift: sheet II, blank until explored, on darker paper. After Arnetria: sheet I
  returns with AR added. Sheet II is not shown again (not planned).

## 8. Settled and open

Settled by the user (2026-11-18/19): LEXICON CORE in SC; three candles; a new blank sheet after the shift; Sutures
only found, never refilled (8 placed); THE UNMUZZLED in KN reached by normal jumps; machines in the lab rooms;
CEREMENT-112 in GA; the optional cyborg mini-boss SEXTON-19 with the BOLT PISTOL in OW (decision 20); weak enemies return after 10 s (decision 18); at most 2 enemy kinds per room (checked: every row above has 2 or fewer).

Open (waiting on user):
1. **Walk from the save to the Pallbearer** (about 16 s through the lab). Recommended: keep it and check it in the next
   playtest. Other option: a save point in the hallway now (reuse save2.txt).

Also needed, not decisions: art for THE UNMUZZLED, Arnetria's arena and the two lab machines (your yes on the look first).
