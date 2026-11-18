# Bosses and story (v2)

## In plain words

- **THE PALLBEARER**: a 3-minute fight with three stages. You see its hooded body draw, raise and swing the scythe, and
  the hit lands only where the blade is drawn. Beating it gives Elegy-013.
- **THE UNMUZZLED**, a werewolf, waits in the lab's top-left room. He runs up walls and jumps off them at you. Beating
  him gives the wall jump.
- **SEXTON-19, THE BOLTED**, an optional cyborg mini-boss, guards a side room off the lab's upper floor. He shoots iron
  bolts and hides behind a steel slab. Beating him gives the BOLT PISTOL, an off-hand gun.
- **ARNETRIA** waits behind the door that three candles open. She talks before, during and after the fight. Beating her
  ends the shift; her cracked visor stays on the floor; the time machine falls silent.
- A working save terminal lets you fight beaten bosses again for your best time and a little XP.
- Pandora gets a voice: 27 short lines (shouts, pain, level-up, repair and so on). Each generation costs money, so we
  ask you before every call.
- Text never tells you where to go.

Status: waiting on user (v2; the user's decisions of 2026-11-18/19 applied). Design only; no game files changed.
Sources: `prototypes/feel-v3/boss.gd`, `shots/19_boss_reach.png`, `shots/20_boss_dead.png`, `assets/boss/*.png`,
`production/playtests/VERDICTS.md` (#8, #10), `production/orchestration/decisions.md` (D-ORCH-19, D-ORCH-21),
`design/gdd/game-concept.md`, `design/gdd/narrative-presentation.md`, `design/art/concepts/REVIEW.md`,
`design/art/concepts/new/characters/the-woman-villain/boss/arnetria-*.jpg`, `rpg-items.md` v2, `map.md` v2.
Anything marked **(guess)** was not checked in the code or documents.

Damage: R is the raw value before her defence (rules in `rpg-items.md` F3: bosses × 1.0, then her DEF). In brackets,
the share of her bar at the level we expect her to have (Pallbearer: level 5, 130 HP; Unmuzzled: level 3, 120 HP;
Arnetria: level 7, 140 HP; SEXTON-19: level 4, 125 HP).

---

## 2. First boss: THE PALLBEARER (keeper of Elegy-013)

### 2.1 What is wrong now (from `boss.gd` and the screenshots)

1. **The body never animates.** `assets/boss/body.png` is one still picture. It floats and blinks colours; it never
   raises an arm, holds the scythe or swings (verdict #8, still open).
2. **The drawing does not match the attack.** For `reap` and `throw`, a hand slides to a wall while the code draws the
   small Elegy icon blown up 2.2 times next to it; then a yellow shape flies across the room. Nothing swings.
3. **The hand is always an open palm**, so a slam and a sweep look the same until they move.
4. **It does not face you.**
5. **Every attack hurts the same** (`boss_damage`).
6. **One idea for the whole fight**, two stages, no combinations.
7. **A hint arrow** bobs over a stuck hand: handholding.
8. **Mixed detail**: the purple body and the golden hands look like two art packs.

### 2.2 The rule for every animation (all three bosses)

- **Wind-up frames hold** for the whole warning. The warning is a readable pose plus a sound.
- **The hit exists only on the frames where the weapon is drawn** in that place, and only that area hurts.
- **Recovery frames** follow every attack; that is when you hit back.
- The boss turns to face Pandora **before** an attack (a 0.15 s turn frame), never during a swing.
- No warning is shorter than 0.35 s, however hard the stage.

### 2.3 Move list (decision 11: the body swings the scythe)

Room: the current boss room. The body floats about 140 px up (four times her height). She reaches it by standing on a
hand stuck in the floor and jumping. Hands take a quarter of the damage.

| # | Attack | Warning (sight and sound, time) | What hits | Dodge | R (share) | Frames |
|---|---|---|---|---|---|---|
| 1 | **Grave Slam** | Body points down at her. A hand flies above her and closes into a fist; a gold mark on the floor follows her for 1.1 s, then stops; the fist shakes 0.5 s with a rising whine. | the fist as it falls | step out when the shaking starts | 20 (15 %) | body point 2; fist 1; fist stuck and cracked 1 |
| 2 | **Floor Sweep** | A hand flies to a wall and presses flat; nails-on-stone scrape, 0.9 s. | the flat hand, wall to wall | jump it (half her jump height) | 15 (12 %) | flat palm 1; scrape sparks 2 |
| 3 | **Funeral Bells** | Body raises both arms; the hood glows gold, 0.7 s. One toll per bolt: **high** bell = chest-high bolt, **low** bell = floor bolt. | gold bolts, 0.55 s apart | crouch the high, jump the low | 10 each (8 %) | body cast 3; bolt 2 |
| 4 | **Coffin Lid** (stage 2 on) | Both hands go to the walls, palms facing; deep creak, 1.0 s. | both hands rushing together where she stood | jump straight up, or run out; they stay stuck side by side 4 s: a wide step up | 25 (19 %) | side-on palm 1 |
| 5 | **Elegy Reap** | Body reaches behind its back and draws the scythe (0.3 s), then holds it. **Where the blade is held is where it cuts**: up at shoulder height = chest-high cut; low and back = floor cut. Blade glint, a faint lane, a long breath in; 1.0 s. | the swing throws a crescent of the edge across the room at that height | chest-high: crouch or slide; floor: jump | 25 (19 %) | draw 2; hold high 1; hold low 1; swing with blur 3; recover 2; crescent 3 |
| 6 | **Elegy Throw** | Body pulls the scythe back over its shoulder; blade tips **up** (first pass high) or **down** (first pass low); 0.9 s. A chime at the far wall 0.3 s before it returns. | the spinning scythe: out at one height, back at the other | crouch the high, jump the low | 20 per pass (15 %) | wind-up 2; release 2; catch 2; spinning scythe 4 |
| 7 | **Burial** (stage 3) | Hood tears open; the body sinks to the floor mid-room with the scythe in both hands; the music drops 1.2 s. | two swings close to the body: chest-high, then floor, 0.6 s apart | crouch, then jump; or backdash out of reach | 30 per swing (23 %) | descend 2; swing high 3; swing low 3; winded 2 |

After **Burial** the body stays on the floor, winded, 2.0 s: the only time it can be hit without climbing.

### 2.4 Stages (decision 11: health 330, stages at 60 % and 25 %)

About 3 minutes with Dirge at level 4-5 (12 per hit on the body, 3 on a hand; about 28 body hits).

| Stage | Health | What changes |
|---|---|---|
| 1 "It carries" | 330 to 198 (100-60 %) | Order: Slam, Reap, Slam, Bells (3), Throw, Sweep. Hands stay stuck 3.0 s. |
| 2 "It will not let go" | 198 to 83 (60-25 %) | Short roar, the hood smokes. Coffin Lid joins. Bells become 5. Slam leaves two small floor ripples, 40 px each side (jump them). Hands stuck 2.6 s. Everything 20 % quicker, never under 0.35 s. |
| 3 "It lets go" | 83 to 0 (25-0 %) | Hood tears off (the face under it: a cracked porcelain mask **(guess, needs your yes)**). Burial joins. Combinations: Throw, then Reap the moment it catches; Sweep from both walls 0.6 s apart, the second chest-high. Hands stuck 2.2 s. |

Also needed: float idle 4, turn 1, stage-2 roar 3, hood tear 3, intro 4, death 5. Total about 55 frames.
Death: the body drops the scythe; it falls and sticks in the floor. Up takes it: **ELEGY-013** (special show and card,
`rpg-items.md` 3.13). The card reads only the name and its line. XP 50.

---

## 3. Mini-boss: LUPERCAL-06, THE UNMUZZLED (werewolf)

**Who:** a lab hound grown into something that walks upright; the lab's grip servos were bolted into his claws, which
is how he runs up walls. When he dies, Pandora takes the servos: **GRIP SERVOS**, the wall jump (decision 12). He
replaces today's GRIP SERVOS pickup in the lab, so the well climb still comes after him.

**Where:** KN, the lab's top-left room, reached from LA by normal jumps up platforms.

**Arena:** 20 x 12 tiles of open space (320 x 192 px). Two tall, scratched steel side walls. Flat floor. Two broken cage
roofs 3 tiles up (48 px, a normal jump), each 4 tiles in from a wall. She has no wall jump yet: he uses the walls, she
fights from the floor and the cage roofs. The hole seals when he drops in and opens when he dies.

Health **160**: about 60 to 90 seconds at level 3 (Dirge 11). XP 30.

| # | Attack | Warning | What hits | Dodge | R (share) | Frames |
|---|---|---|---|---|---|---|
| 1 | **Lunge** | drops low, ears flat, growl 0.5 s | his body, sliding about 120 px | jump over him or backdash | 15 (13 %) | crouch-growl 2; lunge 3 |
| 2 | **Rend** | rears up, one arm raised, short snarl 0.35 s | three claw swipes in front; the third slower and bigger | backdash after the second, or get behind him | 10, 10, 15 | swipe right 2; left 2; big swipe 3 |
| 3 | **Wall Pounce** | runs at a wall, leaps on, claws throw sparks; clings 0.6 s, eyes glowing, snarl; picks his target as he kicks off | his body, diving at a slant at where she stood | move as he kicks, or backdash; he skids 0.8 s: hit him | 18 (15 %) | cling 2; kick off 2; dive 2; skid 2 |
| 4 | **Ricochet** (stage 2) | howl at the top of a wall, 1.0 s | bounces wall to wall across the top 2-4 times (a clang each), then drops on her; his shadow shows the landing 0.4 s before | count the clangs, watch the shadow, step aside; he is stunned 1.2 s | 20 (17 %) | howl 3; leap 2 |
| 5 | **Wall Rake** (stage 2) | clings low on a wall; claws scrape, 0.6 s | slides down and along the floor, leaving sparks that hurt 0.5 s | jump onto a cage roof or over him | 15 (13 %) | rake 2 |

| Stage | Health | What changes |
|---|---|---|
| 1 | 160 to 80 | Lunge, Rend, Wall Pounce. |
| 2 | 80 to 0 | The muzzle breaks off (3 frames). 20 % quicker. Ricochet and Wall Rake join. Wall Pounce can chain. |

Also needed: idle 4, run 6, hurt 1, death 4. Total about 45 frames. Size about 1.4 times her height, hunched.
On death: the servos fall from his claws, glowing. Up takes them: special show and card, **GRIP SERVOS** (name and
line only; how to wall jump is what he showed all fight).

---

## 3b. Mini-boss: SEXTON-19, THE BOLTED (cyborg; decision 20)

**Who:** the lab's last armoury guard. He was the church's bell-ringer and gravedigger (a sexton); the lab bolted him back together as a guard, and he still tolls his bell when he is angry. His right arm is a gun. When he falls, Pandora takes the arm-gun and cuts it down for one hand: the **BOLT PISTOL** (rules: `rpg-items.md` 3.14). He is optional: no gate needs him.

**Look:** about 1.5 times her height and twice as wide, hunched under a dented bell-shaped iron helmet with one teal lens slit; a long grey sexton's coat riveted with plates, soot at the hem; the left arm carries a door-sized steel slab (a surgery door) scratched with tally marks, used as a shield; the right arm is a long bolt gun with a spinning brass cylinder; a steam tank on his back vents when he moves fast. Drawn at the true 16-bit level of detail: its own 16 colours, 1 px dark outline, flat 2-3 tone shading (`sprites.md` 5b).

**Where:** OW, THE ORDNANCE WARD, a one-screen room through the boss door at the east end of LA's upper floor (`map.md`). The door is dented from the inside and a bell tolls slowly behind it, so the room tempts without any text.

**Arena:** 20 x 12 tiles of open space (320 x 192 px) inside the 24 x 14-tile room: a flat steel floor, a gun rack of empty hooks on the back wall, two low gurney ledges 3 tiles up (48 px, a normal jump), each 5 tiles in from a wall. The door shuts when she is two tiles inside and opens when he falls. If she goes offline the room resets.

Health **180**: about 90 to 110 seconds at level 4 (Dirge 12). XP 35 (THE UNMUZZLED 30, THE PALLBEARER 50). Every attack follows the rule of 2.2: his body does the move, and the drawing matches what hits.

**The slab (stage 1):** hits on the slab from the front count x 0.25 (never under 1, the same rule as the Pallbearer's hands); hits from behind, while he reloads, or while he stalls count in full. Bolts and the blade wave follow the same rule.

| # | Attack | Warning | What hits | Dodge | R (share) | Frames |
|---|---|---|---|---|---|---|
| 1 | **Bolt Shot** | raises the gun arm, the brass cylinder spins with a clacking chk-chk, the barrel glows amber; 0.6 s | one bolt at chest height, 220 px/s, across the room, sticks in the wall | crouch under it, jump it, or backdash; after two shots he reloads for 1.5 s (steam hiss, arm open): hit him | 14 (11 %) | wind-up 3; shot 2; reload 3 |
| 2 | **Slab Shove** | drops the left shoulder behind the slab, steam jets from his back, boots dig sparks; 0.7 s | drives forward 96 px, slab and body hurt | backdash, or jump over him and hit his back; he stalls 0.9 s afterwards | 18 (14 %) | wind-up 2; shove 3; stall 2 |
| 3 | **Spike Row** | kneels and drives the gun arm into the floor with a clang; 0.8 s | cracks race along the floor toward her; 0.4 s after a crack passes, an iron spike bursts up there (three spikes, 24 px apart) | keep moving or jump as the cracks pass; the arm is stuck 1.2 s: hit him | 15 each (12 %) | kneel 3; drive 2; stuck 2; spike 3 |
| 4 | **Bolt Fan** (stage 2) | the gun arm unfolds to three barrels with a loud clack, a red flash on each; 0.9 s | three bolts at once, 15 degrees apart | far away (over 160 px) the gaps are wider than she is: stand between two bolts; very close (under 64 px) all three miss | 12 each (10 %) | wind-up 3; fan 2 |
| 5 | **Overclock Rush** (stage 2) | the lens turns red, the tank bangs open and steams, the bell rings twice; 1.0 s | runs the whole room at double speed, body hurts; crashes into the wall and is stunned 1.5 s | jump onto a gurney ledge (he runs under), or backdash early; hit him in the stun | 22 (18 %) | wind-up 3; rush 4; crash 3 |

| Stage | Health | What changes |
|---|---|---|
| 1 | 180 to 90 | Slab up. Bolt Shot, Slab Shove, Spike Row. A reload gap after every two bolts. |
| 2 | 90 to 0 | The slab shatters (4 frames) and falls; the gun unfolds to three barrels (3 frames). 20 % quicker. Bolt Fan and Overclock Rush join. No more block. |

Also needed: idle 4, walk 6, hurt 1, death 6, the bolt 1. Total about **65 frames**. On death: the arm-gun clatters to the floor, the lens dims, and the BOLT PISTOL glows where it lies. Up takes it: the special show and the card (name and description only; how it works is what he showed all fight). RECALL (section 5) gives 9 XP and never a second pistol.

---

## 4. The promised boss: ARNETRIA, THE MIRROR QUEEN

### 4.1 Who she is

Pandora was built from a dead woman's preserved brain. The recurring boss is that woman, met in a different stage of
grief in each reality. **Arnetria is the first: Denial** (`game-concept.md`: "pristine lie-world, doesn't recognize
you"). She lives in the one room the shift could not touch and insists nothing has changed.

### 4.2 Look (from `arnetria-concept-1.jpg`, which the user approved)

Floating, never touches the floor. Black hair, a silver spiked crown, a **mirror visor** over her eyes. Silver gown with
cyan circuit lines; the hem breaks into glass dust. Behind her a **broken clock face** (Roman numerals, brass gears,
missing pieces) turns with her. About 2.5 times Pandora's height. Concept art is reference only: every frame is
redrawn in Aseprite, and you say yes to the look before drawing starts.

### 4.3 Arena: THE QUIET RING (AR)

Behind the sealed door in VA~. **Three candles open it** (decision 13): one in KN~, one in BI, one in SC~. Each lit
candle tolls a bell and lights one sconce on the door; the third opens it. It is the only room with **no red filter**:
clean, bright, symmetrical. One thing gives the lie away: a scuff on the floor by the entrance.

Room 48 x 28 tiles (`map.md`): flat floor, two marble ledges 4 tiles up near each wall, five **mirror sockets** (floor
left and right, ledge left and right, one high in the middle, reached with a wall jump **(guess, test in play)**).
The door seals.

### 4.4 Her rule: the stored lie (D-ORCH-19)

- Hitting her **does not move her bar**. Hairline cracks spread over her and a glass creak plays.
- She raises a **mirror** in a socket. Its numerals go dark one by one: the timer, without text.
- **Break the mirror before the numerals are dark** and everything stored hits her at once: a crash, her bar drops,
  she is stunned 2.0 s.
- **Fail** and the mirror heals, her cracks close with a reversed shatter sound, and the stored damage is gone.
- Mirror health: 3 Dirge hits or 2 Elegy hits **(guess)**.

### 4.5 Move list

| # | Attack | Warning | What hits | Dodge | R (share) | Frames |
|---|---|---|---|---|---|---|
| 1 | **Ring Sweep** | the clock spins faster, ticking speeds up, 0.6 s; she spreads her arms | the clock ring grows outward as a blade, about 70 px around her | backdash or step out | 20 (14 %) | 3 |
| 2 | **Shard Fling** | arm drawn back, glass chime, 0.5 s | a fan of 3 (stage 1) or 5 glass shards aimed at her | slide or crouch under, or stand between | 10 each | fling 3; shard 2 |
| 3 | **Mirror Cast** | arms raised, the clock glows cyan, 0.8 s; the socket glints | nothing (starts the timer) | reach the mirror and break it | none | cast 3; mirror rise 3, idle 2, crack 3, break 4, heal 3 |
| 4 | **Clock Hand** (stage 2) | a long clock hand pulls loose with a tick, 0.7 s, points at XII | it sweeps down one side of her to VI: a floor sweep on that side | jump it, or be on the other side | 20 (14 %) | 3 |
| 5 | **Visor Glare** (stage 3) | the visor flashes white twice, 0.8 s; a thin line of light marks her height | a beam along that line | crouch if high, jump if low | 25 (18 %) | 2 |
| 6 | **Shatter Rain** (stage 3) | glints on the ceiling above 3 spots, 0.7 s | shards falling there | stand between the glints | 15 each | 2 |

### 4.6 Stages

Health 450 **(guess; tune by playtest)**, about 3 to 4 minutes. XP 80.

| Stage | Health | What changes |
|---|---|---|
| 1 "Nothing has changed" | 100-66 % | Ring Sweep, Shard Fling, Mirror Cast (1 mirror, floor sockets, about 6 s). |
| 2 "Hold still" | 66-33 % | Clock Hand joins. 2 mirrors at once (only the one you break pays out), ledge sockets too, about 5 s. She Ring Sweeps near a mirror to guard it. |
| 3 "Don't look at me" | 33-0 % | The visor cracks. Visor Glare and Shatter Rain join. Mirrors about 4 s; the high middle socket is used. |

Also needed: idle 4, intro 4, hurt-crack 2, stunned 3, kneel 3, shatter 6. Total about 55 frames with the mirrors.

### 4.7 How the shift ends (decision 13)

On her last mirror she does not get up. The ending dialogue plays. Then she breaks like glass. The clock behind her
makes one full turn and stops at XII and strikes twelve: **with each toll the red drains a little more**. On the twelfth:
- the shift filter is gone, the whispers and the drone stop, the area music returns;
- the rooms and doors are back on sheet I, with AR added east of VA (`map.md` §4);
- save terminals work again ("NO SIGNAL" is gone), with RECALL and the RESTORE MODULE recharge;
- **the time machine (the Organ of Hours) is silent for good**: Up at it gives only a dead key thunk;
- **her cracked visor stays on the floor of AR.** It is never taken. Up beside it shows (working text):
  `> VISOR. CRACKED FROM THE INSIDE.`
  `> IT STILL SHOWS THIS ROOM AS IT WAS.`

### 4.8 Dialogue

Rules (`narrative-presentation.md`): at most 3 short lines on screen at once; no line explains the game; Pandora mostly
speaks in printed readouts (lines starting `>`), with a few spoken words (voiced, section 8).

**Before the fight** (the door opens; the room is clean; a clock ticks)

> ARNETRIA: You're late. The guests left hours ago.
> ARNETRIA: Don't stand there dripping on the floor. Nothing has happened here.
> `> FACE MATCH 98.7%. SOURCE: UNLISTED.`
> ARNETRIA: Take off that face. It isn't yours.
> PANDORA: It's the only one I was given.
> ARNETRIA: Then I'll mend it. I mend everything.

**During the fight** (one line each, short, never blocks play)

| When | Line |
|---|---|
| First hit stored | "That didn't happen." |
| Hits stored, later | "No." / "Still whole." |
| Mirror rises | "Look. See? Nothing's broken." |
| Mirror broken, damage lands | "Stop—" / "That isn't my reflection." |
| Mirror timer runs out | "There. As it was." |
| Stage 2 | "Hold still. The clock is right. The clock is always right." |
| Stage 3 | "Don't look at me. Don't look at me." |
| Pandora badly hurt | "Sit down. You're tired. We're all so tired." |
| Pandora falls | "...Who were you?" |

**After the fight** (she kneels; the visor is cracked through)

> ARNETRIA: The clock stopped. When did the clock stop?
> ARNETRIA: You have my eyes. Why do you have my eyes?
> PANDORA: I don't know.
> ARNETRIA: If I look, it's real.
> ARNETRIA: ...I looked.
> `> MEMORY CACHED.`

Then the twelve tolls (4.7). The last line on screen: **"THE HOUR IS KEPT."**

---

## 5. RECALL: fighting bosses again (decision 14)

- At a **working** save terminal (S2 or VA; none during the shift), the terminal offers CACHE MEMORY, RECALL and BACK.
  RECALL lists the beaten bosses with their best time ("THE PALLBEARER - BEST 2:58").
- The fight is a memory: its arena with a cold cyan scan-line tint. She starts with full HP, EN and MP and her current
  level, gear and weapons. Sutures used come back afterwards. No RESTORE HERE and no self-repair (as in `rpg-items.md` 3.7).
- **Rewards**: the best time is saved, and every win gives **25 % of the boss's XP** (rounded up): THE UNMUZZLED 8, SEXTON-19 9,
  THE PALLBEARER 13, ARNETRIA 20. **No second copy** of its weapon or ability, and no other drops.
- Winning or losing returns her to the terminal: no SYSTEM OFFLINE screen, no designation change. Pause > END RECALL quits.
- The fight is the same difficulty as the first time.
- Arnetria can be recalled only after she is beaten; the shift does not come back.

---

## 6. Names (shown after a hit once LEXICON CORE is found; rules in `rpg-items.md` 3.11)

LEXICON CORE lies in SC, the scriptorium off the library (decision 10). Ghost, hound, spitter, warden and choir
behaviours were not checked against their code, so those names fit the id only **(guess)**.

| Id | Name shown | One line (for a future bestiary) |
|---|---|---|
| ghost | **GRAVE STATIC** | A death that kept broadcasting. |
| hound | **CHAINBITE HOUND** | Bred to fetch the dead. Still fetching. |
| spitter | **BILE CANTOR** | Its hymn is mostly acid. |
| warden | **OSSUARY WARDEN** | Guards the bones. Forgot whose. |
| choir | **HOLLOW CHOIR** | Three voices. No throats. |
| crab | **RELIQUARY CRAB** | Wears a saint's ribs as a shell. Strike where the saint is not. |
| moth | **CENSER MOTH** | Burns the incense no one lit. |
| scribe | **NEEDLE SCRIBE** | Writes your name on the floor. Then reads it aloud. |
| leech | **TITHE LEECH** | Takes its tenth. Then the rest. |
| trolley (new machine) | **SAWBONES TROLLEY** | Wheels the dead to the table. Will not wait for you to die. |
| orderly (new cyborg) | **GRAFTED ORDERLY** | Half the staff were replaced. This one was replaced a piece at a time. |
| boss | **THE PALLBEARER** | Keeper of Elegy-013. It carried something no one came to bury. |
| werewolf | **LUPERCAL-06, THE UNMUZZLED** | The lab took the muzzle off to see what it would do. |
| cyborg mini-boss | **SEXTON-19, THE BOLTED** | Rang the bell for the dead. Rings it for the living now. |
| Arnetria | **ARNETRIA, THE MIRROR QUEEN** | Nothing has changed. Nothing has changed. |

The two machines (look, moves, numbers): `rpg-items.md` 3.6.

---

## 7. Text without handholding (decision 17)

No text tells the player where to go or what to press. Sound, light and the map do it (the full table is `map.md` §6).

| Where | Now | New |
|---|---|---|
| `main.gd:178` first locked door | SEALED. Something in the library holds it shut. | no text: thud, chain rattle, the red lamp blinks |
| library lever (`props.gd:54`) | Far below, a door grinds open. | no text: chain run, distant boom, dust; the door lamp turns pale |
| `main.gd:234` wall grip | GRIP SERVOS ONLINE - jump at a wall and hold... | the card: GRIP SERVOS and its line only |
| `room.gd:242` Arnetria's door | LOCKED - UNTIL THE NEXT UPDATE | no text: three dark candles on the door |
| `main.gd:325`, `:358` prompts | W: pull the lever / W: use the machine | the small hand bubble, no words |
| `main.gd:336` bars | The bars grind upward. | no text: the grind and the moving bars |
| `main.gd:408` after the shift | SOMETHING ANSWERED. | keep (story, not a hint) |
| `main.gd:436` Elegy pickup | ELEGY-013 - the Pallbearer... E to change weapon | the card: name and line only |
| Pallbearer stage 2 | IT WILL NOT LET GO | keep (flavour) |
| Pallbearer death | LAID TO REST - the prototype ends here... | **LAID TO REST.** (the prototype now ends after Arnetria) |
| stuck-hand arrow | a bobbing arrow | removed; the cracked fist reads as a step |

---

## 8. Pandora's voice lines (decision 16)

ElevenLabs is paid. **Every generation call needs your yes**: we show the exact lines of each batch first. Order:
(1) you choose a voice (we suggest 3 from the library to hear; a voice-design call also needs a yes); (2) one batch per
group below, one take per line; extra takes only where you ask. Her voice: a young woman's, calm and low, a little
mechanical in her evenness, feeling showing only under pressure.

Play rules: attack shouts on about 1 swing in 3 and every combo finisher, never twice within 1.2 s; hurt lines never
twice within 1.5 s; a heavy hurt line is for one hit of 20 or more.

| # | Group | Plays when | Text | Mood note |
|---|---|---|---|---|
| V01 | attack | Dirge swing | "Hah!" | short controlled breath out; calm, not shouting |
| V02 | attack | Dirge swing | "Hm!" | clipped, closed-mouth effort |
| V03 | attack | Dirge swing | "Tch!" | sharp, a little annoyed |
| V04 | attack | combo finisher, air attack | "Hyah!" | the biggest of the four, still short |
| V05 | attack (Elegy) | Elegy swing | "Haaah!" | low full-body effort, heavier than V01-V04 |
| V06 | attack (Elegy) | Elegy swing | "Rrh... hah!" | strain, then release |
| V07 | attack (Elegy) | Elegy crouch sweep, air spin | "Hngh!" | a grunt as she hauls the weight round |
| V08 | special | Dirge blade wave | "Cut." | flat, cold, almost bored |
| V09 | special | Elegy Requiem | "Rest now." | soft, almost tender, a little sad |
| V10 | hurt | light hit | "Ngh!" | short, surprised |
| V11 | hurt | light hit | "Ah...!" | caught off guard |
| V12 | hurt | light hit | "Kh!" | teeth clenched |
| V13 | hurt | heavy hit | "Aagh!" | real pain, longer |
| V14 | hurt | heavy hit | "Hhh... no!" | pain turning into defiance |
| V15 | death | SYSTEM OFFLINE begins | "...not... yet..." | fading and slowing, like a machine winding down |
| V16 | death | variant | "Sys... tem..." | the voice drops in pitch and breaks off |
| V17 | rebuild | RESTORE HERE, reconstruct | "Again." | tired, stubborn |
| V18 | level-up | LEVEL UP | "Clearer now." | quiet surprise, a small smile in the voice |
| V19 | level-up | variant | "I remember this." | wondering, half to herself |
| V20 | self-repair | the repair starts | "Patching." | focused, under her breath |
| V21 | self-repair | the repair ends with health gained | "...Holding." | relieved breath out |
| V22 | pickup | an item card opens | "Hm." | a small curious hum |
| V23 | pickup | weapon special show | "...It fits my hands." | low, a little awed |
| V24 | pickup | ability special show | "New pathway." | precise, interested |
| V25 | pickup | harness or module special show | "Fitted." | matter-of-fact, satisfied |
| V26 | story | Arnetria, before the fight | "It's the only one I was given." | quiet and steady, hurt underneath |
| V27 | story | Arnetria, after the fight | "I don't know." | soft, honest, close to a whisper |

27 lines (V17 is an extra not in your list; drop it if you like). A hit during self-repair plays a hurt line, not a
separate "interrupted" line.

---

## Appendix: harder bosses, easier rooms, slower pace (decision 3)

Run speed, jump and backdash stay exactly as the user saved them.

| Change | From | To | What the player feels |
|---|---|---|---|
| Boss health | Pallbearer 220 | 330 | about 3 minutes, not 2 |
| Boss damage | one value for all | 10 to 30 by attack | big attacks feel big |
| Boss stages | 2 | 3, combinations in the last | the fight keeps teaching |
| Ordinary enemy damage | today | × 0.75 | rooms are a walk with teeth, not a wall |
| Ordinary enemy rests | today | × 1.2 longer | easier to read; slower, heavier pace |
| Trap damage | 30 to 40 | × 0.75 (23 to 30) | a blade hurts but does not end the run |
| Enemies per room | up to 10, many kinds | at most 4, at most 2 kinds | space to breathe |
| Quiet rooms | none | an empty room before each boss door (HW, VA~) | a pause before the storm |
| Boss intros | none | 2 to 4 s entrance before the first attack | the fight feels like an event |

Ordinary enemy health stays as today, so "weak" (2-3 Dirge hits) keeps its meaning (`rpg-items.md` 3.5).

## Settled and open

Settled by the user (2026-11-18/19): the body swings the scythe; Pallbearer health 330 with stages at 60 % and 25 %;
the werewolf replaces the wall-grip pickup and sits in the lab's top-left room; three candles open Arnetria's door;
the visor stays; the time machine falls silent; LEXICON CORE in the scriptorium; RECALL gives best time and 25 % XP; the optional cyborg mini-boss SEXTON-19 holds the BOLT PISTOL (2026-11-19, decision 20).

Open (waiting on user, at most five):
1. The Pallbearer's face under the hood in stage 3: a cracked porcelain mask (recommended: it echoes Arnetria's visor).
2. The look of THE UNMUZZLED, Arnetria, SEXTON-19 and the two lab machines, before any frame is drawn (about 55 + 45 + 55 + 51 + 65 frames).
3. Pandora's voice: you pick from 3 suggested library voices (each listen is free; a voice-design call is paid).
4. Arnetria's health 450: keep as the start value and tune after the first playtest (recommended).
