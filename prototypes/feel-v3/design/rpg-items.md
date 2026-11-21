# RPG, items and equipment (v2)

## In plain words

- Pandora levels up when she beats enemies. Each level-up refills her health, energy and magic and gives 2 points.
  You can spend them right away in the CHARACTER screen, keep them for later, or press AUTO.
- Up is the "use" key: levers, terminals, candles, items and gear. Soul orbs (magic) and machine scrap are taken by touch.
- Two new lab machines drop scrap. When her health is low, scrap drops more often. Stand still and hold H:
  she repairs herself, turning scrap and energy into health. A hit stops it.
- Sutures heal 40. There are 8 in the world and no more; they never refill.
- Weak enemies come back 10 s after they fall while she stays in the room, out of her sight and never within 96 px (a slider).
- Every enemy kind has one rare drop (2-5 %): small consumables or minor gear. One kind, the GRAFTED ORDERLY, can drop the TANK HEART (about 2 %), a permanent +20 max health.
- The BOLT PISTOL, won from the optional cyborg mini-boss SEXTON-19, is an off-hand gun that works only with DIRGE-042 (Elegy is two-handed). It has its own button (N), costs EN per shot, and is for flying enemies and ledges. It cannot pull levers.
- Gear comes in two kinds: HARNESSES worn over her body (2 slots) and MODULES inside her (2 slots).
  The RESTORE MODULE lets her stand back up where she fell, once, until she next uses a save terminal.
- Picking up an item shows its picture and a short text, like Resident Evil. Big finds get a short light show.
- We recommend building it as written. Say yes and a programmer builds it; say no and we redraw only what you change.

Status: waiting on user (v2; replaces the v1 draft). Scope: the feel-v3/v4 prototype area only. Design only, no code.
Sources: the user's decisions of 2026-11-18/19 (see `decisions.md`; they outrank every GDD), `design/gdd/progression.md`,
`design/gdd/health-damage.md`, `design/gdd/cache-stations-death.md`, `prototypes/feel-v3/tuning.json`, `map.md`, `bosses-story.md`.
Scale: the prototype uses 5 times the GDD's health and damage numbers (her health 100, a Dirge hit 10).

---

## 1. Overview

One sheet of numbers that grows by choice (five stats, two points a level), two ways to heal (8 Sutures found in the
world; scrap turned into health by self-repair), two gear families with two slots each, one second life (the RESTORE
MODULE), and the screens that show all of it. Every number below is a slider in `tuning.json` (section 7).

## 2. Player fantasy

- **Growing stronger the way she chooses** (Achievement, Expression): a level-up is a full refill and a small decision.
- **Scraping by** (Challenge): healing is scarce. Sutures are a fixed treasure; scrap is earned from machines and is
  most generous when she is in trouble, but she must stand still in danger to use it.
- **Finding things** (Discovery): every reward sits in a place you can see but must work to reach, and taking it is a moment.
- Self-Determination check: autonomy (stat points, gear choice), competence (readable numbers, a clear stat screen).

---

## 3. Detailed rules

### 3.1 The stats

> **Superseded 2026-11-20 (decision 28, user):** there are no points and no five-stat sheet to spend. Her stats grow by themselves: every level above 1 adds +6 max HP, +4 max EN, +5 % ATK and +1.5 % DEF (read from tuning: `level_hp`, `level_en`, `level_atk`, `level_def`). Specials follow ATK. MP does not grow with levels (base 60 plus gear). The text below is the old design, kept for history.

Her sheet has five stats she raises with points, and six values that come from them.

| Stat (points) | One point gives | Plain words |
|---|---|---|
| VIGOR | max HP +10 | about two more ghost touches before she falls |
| POWER | weapon damage +8 % | a level 1 Dirge hit of 10 becomes 10.8 |
| GUARD | damage taken from enemies −3 % (DEF +3) | most DEF is 40 |
| STAMINA | max EN +8 | two thirds of one more swing (a swing costs 12) |
| MAGIC | special damage +8 % and max MP +6 | the blade wave (30) hits 2.4 harder; 6 MP is a little over a third of one wave (15) |

| Value | At level 1, no points | What it does |
|---|---|---|
| HP | 100 | health; at 0 she goes offline |
| EN | 100 | swings (12) and backdashes (10) spend it; it refills by itself; self-repair spends it |
| MP | 60 | specials spend it (blade wave 15, Requiem 25); soul orbs refill it |
| ATK | 100 | weapon damage in percent |
| DEF | 0 | percent less damage from enemy hits (not traps) |
| SPC | 100 | special damage in percent |

POWER and VIGOR keep the GDD's own point values (+8 attack, +2 health × 5 = +10).

### 3.2 Levels and the level-up

> **Superseded 2026-11-20 (decision 28, user):** a level-up refills HP, EN and MP and raises her stats at once. It banks no points and opens no menu. Growth by level (HP / EN / ATK % / DEF %): L1 100 / 100 / 100 / 0, L4 118 / 112 / 115 / 4.5, L5 124 / 116 / 120 / 6, L7 136 / 124 / 130 / 9, L10 154 / 136 / 145 / 13.5. MP stays 60 plus gear. The old automatic split below is replaced.

- XP for the next level = 10 × (current level + 1). Highest level 10. Levels 2 to 5 match the GDD (20, 50, 90, 140).
- On a level-up, at once: HP, EN and MP refill to full; 2 points are banked; a gold "LEVEL UP" rises above her
  for 1.2 s with a chime, a ring of light and a voice line (`bosses-story.md` §8). Play does not stop.
- **The offer**: for 4 s a small "+2" badge with a [C] key icon (touch: the LV badge pulses) shows by the HP bar.
  Press C (touch: tap the LV badge) to open CHARACTER; the game pauses while it is open. Ignore it and the points
  stay banked; the "+N" pip on the LV badge keeps blinking softly until they are spent. A slider can make
  CHARACTER open by itself instead (`levelup_opens_menu`).
- **AUTO**: spends points in a fixed balanced order that repeats every 10 points:
  VIGOR, POWER, GUARD, VIGOR, POWER, MAGIC, VIGOR, POWER, GUARD, STAMINA.
  It is a button in CHARACTER, and a switch there, "AUTO EVERY LEVEL", that spends new points as they arrive.
- Spent points are permanent (the GDD forbids a respec). Before DONE, a point can be taken back.

Reference growth (what AUTO gives; a player who chooses may differ):

| LV | Total XP | XP to next | Points | V / P / G / S / M | HP | EN | MP | ATK | DEF | SPC | Dirge hit | Elegy hit |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 0 | 20 | 0 | 0/0/0/0/0 | 100 | 100 | 60 | 100 | 0 | 100 | 10 | 20 |
| 2 | 20 | 30 | 2 | 1/1/0/0/0 | 110 | 100 | 60 | 108 | 0 | 100 | 11 | 22 |
| 3 | 50 | 40 | 4 | 2/1/1/0/0 | 120 | 100 | 60 | 108 | 3 | 100 | 11 | 22 |
| 4 | 90 | 50 | 6 | 2/2/1/0/1 | 120 | 100 | 66 | 116 | 3 | 108 | 12 | 23 |
| 5 | 140 | 60 | 8 | 3/3/1/0/1 | 130 | 100 | 66 | 124 | 3 | 108 | 12 | 25 |
| 6 | 200 | 70 | 10 | 3/3/2/1/1 | 130 | 108 | 66 | 124 | 6 | 108 | 12 | 25 |
| 7 | 270 | 80 | 12 | 4/4/2/1/1 | 140 | 108 | 66 | 132 | 6 | 108 | 13 | 26 |
| 8 | 350 | 90 | 14 | 5/4/3/1/1 | 150 | 108 | 66 | 132 | 9 | 108 | 13 | 26 |
| 9 | 440 | 100 | 16 | 5/5/3/1/2 | 150 | 108 | 72 | 140 | 9 | 116 | 14 | 28 |
| 10 | 540 | max | 18 | 6/6/3/1/2 | 160 | 108 | 72 | 148 | 9 | 116 | 15 | 30 |

Weak enemies stay at 2 to 3 Dirge hits at every level on the AUTO path:

| Dirge hits to beat | L1 (10) | L3 (11) | L5 (12) | L7 (13) | L10 (15) |
|---|---|---|---|---|---|
| ghost 22 | 3 | 2 | 2 | 2 | 2 |
| leech 25 | 3 | 3 | 3 | 2 | 2 |
| spitter 26 | 3 | 3 | 3 | 2 | 2 |
| trolley 28 (new) | 3 | 3 | 3 | 3 | 2 |
| hound 30 | 3 | 3 | 3 | 3 | 2 |

Pacing ledger (each enemy beaten once, plus a few that came back):

| Moment | XP about | Level | Notes |
|---|---|---|---|
| Church | 6 | 1 | |
| Library | 30 | 2 | |
| Lab hall (LA) | 54 | 3 | |
| After THE UNMUZZLED (+30) | 84 | 3 | expect him at L3: HP 120, Dirge 11 |
| After the hidden room (GA) | 128 | 4 | optional |
| After THE PALLBEARER (+50) | 178 | 5 | expect it at L4-5: HP 120-130, Dirge 12 |
| After the walk back and the chapel | 262 | 6 | |
| After the shifted route | 346 | 7 | expect Arnetria at L7-8: HP 140-150 |
| After Arnetria (+80) | 426 | 8 | level 10 needs extra fighting or RECALL |

### 3.3 Damage she deals

- Weapon swings use ATK and the DRIVE module bonus (rule F1). Specials use SPC and nothing else (rule F2).
- On the Pallbearer's hands every hit is × 0.25 (the boss design: hands take a quarter).
- Hazards and specials ignore DEF and harnesses.

### 3.4 Damage she takes

- Ordinary enemies and their shots: × 0.75 (rooms easier), then DEF (rule F3). Bosses: × 1.0, then DEF.
- Traps: × 0.75 of today's values (pendulum 35 → 26, crusher 40 → 30, flames 30 → 23, spikes 30 → 23); DEF does not apply.
- Leech drains of MP and EN are not damage.

### 3.5 XP, drops and coming back

| id | Shown name | Kind | Health | Dirge hits at L1 | XP | Comes back | Drops |
|---|---|---|---|---|---|---|---|
| `ghost` | GRAVE STATIC | spirit | 22 | 3 | 3 | yes, in room | soul orb 60 % |
| `leech` | TITHE LEECH | organic | 25 | 3 | 4 | yes, in room | soul orb 60 % |
| `spitter` | BILE CANTOR | organic | 26 | 3 | 3 | yes, in room | soul orb 60 % |
| `trolley` (new) | SAWBONES TROLLEY | machine | 28 | 3 | 4 | yes, in room | scrap 40 % (more at low health) |
| `hound` | CHAINBITE HOUND | organic | 30 | 3 | 3 | yes, in room | soul orb 60 % |
| `choir` | HOLLOW CHOIR | spirit | 34 | 4 | 6 | on re-entry | soul orb 100 % |
| `moth` | CENSER MOTH | organic | 40 | 4 | 7 | on re-entry | soul orb 100 % |
| `orderly` (new) | GRAFTED ORDERLY | cyborg | 60 | 6 | 10 | on re-entry | scrap 50 % (more at low health) and soul orb 70 % |
| `scribe` | NEEDLE SCRIBE | spirit | 50 | 5 | 10 | on re-entry | soul orb 100 % |
| `crab` | RELIQUARY CRAB | organic | 70 | 7 + shell | 12 | on re-entry | 2 soul orbs |
| `warden` | OSSUARY WARDEN | organic | today's value (13 hits) | 13 | 14 | on re-entry | 2 soul orbs |
| THE UNMUZZLED | mini boss | | 160 | | 30 | no | GRIP SERVOS (wall jump), first win only |
| SEXTON-19, THE BOLTED | mini boss, optional | | 180 | | 35 | no | BOLT PISTOL (off-hand gun), first win only |
| THE PALLBEARER | boss | | 330 | | 50 | no | ELEGY-013, first win only |
| ARNETRIA | boss | | 450 (to tune) | | 80 | no | the end of the shift |

- No enemy drops a Suture. Gear drops only as the three minor variants in 3.5b (decision 19). Bosses drop no orbs or scrap.
- **Soul orb**: a pale floating light, +10 MP. Floats where the enemy fell for 12 s (blinks the last 3 s). Taken by
  touch. At full MP it is not taken and stays.
- **Machine scrap**: a small heap of bolts and plate on the floor, +1 on the scrap gauge (most 10). Lies where the
  enemy fell for 20 s (blinks the last 3 s), sliding to the nearest floor if it fell over a pit. Taken by touch.
  With a full gauge it is not taken and the gauge flashes once.
- **Coming back** (decision 3): weak enemies (health 30 or less) come back 10 s after falling (decision 18, slider `weak_respawn_s`) while she stays in the
  room. They return out of her sight and never closer than 96 px (6 tiles): at their own spot only if that spot is off the screen, otherwise by walking in through the door farthest from her; a faint rattle sounds 1 s before (no shimmer on screen), then a 1 s pause before their first
  attack; never more alive than the room started with; not in save rooms, boss rooms or GA. The others come back when
  she re-enters. Enemies that came back give half XP (rounded up). Timers stop while paused.

### 3.5b Rare drops (decision 19)

Every enemy kind has exactly one rare drop, rolled once when it dies, after its usual drops in 3.5 (an enemy can drop an
orb or scrap and its rare). A rare is useful but less special than a reward placed in the world (Sutures, gear, abilities):
small consumables and three minor gear variants. Exactly one strong rare exists in the whole area: the TANK HEART.

| Enemy (kind) | Rare drop | Kind | Effect | Chance | Card line (working text) |
|---|---|---|---|---|---|
| GRAVE STATIC (`ghost`, weak) | STATIC SHARD | consumable | +30 MP | 3 % | "A spark that would not stay buried." |
| TITHE LEECH (`leech`, weak) | TITHE JAR | consumable | EN back to full | 3 % | "It took a tenth. Here is some of it back." |
| BILE CANTOR (`spitter`, weak) | BILE FLASK | consumable | 20 s: swings +3 damage | 3 % | "Acid, bottled before the hymn could end." |
| SAWBONES TROLLEY (`trolley`, weak) | TROLLEY BOLTS | consumable | +5 scrap at once (up to the gauge size) | 4 % | "A tray of bolts that still fit." |
| CHAINBITE HOUND (`hound`, weak) | CHAIN COLLAR | minor harness, LIMBS | DEF +2 | 3 % | "Still warm. Still looking for a neck." |
| HOLLOW CHOIR (`choir`) | HUSHED BELL | consumable | 15 s: damage taken -25 % | 4 % | "It rings without a sound. So do the hits." |
| CENSER MOTH (`moth`) | ASH POULTICE | consumable | heals 20 HP | 4 % | "Incense ash, pressed into a wound." |
| NEEDLE SCRIBE (`scribe`) | STEEL NIB | minor module, DRIVE | swings +2 damage, no price | 4 % | "It wrote her name. Now it writes in her favour." |
| RELIQUARY CRAB (`crab`) | SAINT'S RIB | minor harness, TORSO | DEF +3 | 5 % | "A shell plate that remembers being a saint." |
| OSSUARY WARDEN (`warden`) | GRAVE SALT | consumable | heals 30 HP | 5 % | "Salt from the ossuary floor. It keeps things." |
| GRAFTED ORDERLY (`orderly`) | **TANK HEART** (the one strong rare) | consumable, permanent | max HP +20 for good, and a full refill of HP, EN and MP | 2 % | "The glass tank held a heart. It still beats." |

How it works:
- **Why the chances differ**: weak enemies come back every 10 s (decision 18), so they get the low end (3-4 %); enemies that come back only when she re-enters get 4-5 %. A returned enemy rolls at half chance (`rare_respawn_mult`).
- **The strong rare**: only the GRAFTED ORDERLY drops the TANK HEART, 2 % a kill (slider range 1-3 %). Orderlies stand in LA (1), GA (2, in its second wave) and KN~ (1), so a normal run meets about four: roughly an 8 % chance in one run, a lucky find and not a plan. At most `tank_heart_max` (2) can ever drop; after that the roll stops. There is no bad-luck guard on purpose.
- **Looks**: a small amber light with a dark rim, so it is not mistaken for a pale soul orb or scrap. It lies where the enemy fell for 20 s (blinks the last 3 s) and is taken by touch (no Up). No special show: only placed rewards get one. The first time each kind is taken, the short card shows (picture, name, one effect line; closes after 0.3 s); after that a one-line toast ("TITHE JAR x2").
- **Carrying**: consumables stack to 3 each (`rare_stack_max`); a fourth stays on the floor. USE them from ITEMS or the QUICKSLOT like Sutures. The TANK HEART is used from ITEMS only (it asks YES or NO first). A timed effect used again restarts its timer; it never doubles.
- **Gear variants** (CHAIN COLLAR, SAINT'S RIB, STEEL NIB): fit like other gear (the card offers EQUIP NOW and LATER, no special show). Only one of each can be owned; a second stays on the floor. They share the slot rules of 3.9, so STEEL NIB and COUPLER or REGULATOR still never add up (all DRIVE).

### 3.6 The two lab machines (decision 7)

Both live only in lab rooms (LA, GA, LA~, KN~; see `map.md`). Hits on metal give a "tink" and sparks.
Their art needs your yes on the look before drawing (design rule).

**SAWBONES TROLLEY** (`trolley`, machine, weak). *Wheels the dead to the table. Will not wait for you to die.*
Look: a knee-high rusted autopsy trolley on three squeaky wheels, a tray of instruments on top, one jointed arm with a
round bone saw, a cracked green lamp for an eye; it leaks oil. About 28 x 22 px at game size (half her height).
Patrols its floor and turns at edges; never falls.

| Move | Warning (sight, sound, time) | What hits | Dodge | Damage (before × 0.75) |
|---|---|---|---|---|
| SAW RUN | lamp turns red, saw spins up with a rising whine and sparks, it rocks back on two wheels; 0.6 s | rolls 96 px (6 tiles) along the floor, saw forward at knee height | jump over it, or backdash; it skids and sputters 0.8 s after: hit it | 10 |
| INSTRUMENT FLING | tray tips up with a rattle; 0.5 s | three scalpels in a short low arc, landing 48-80 px ahead | step back out of the arc, or run under and past it | 6 each |

Health 28, XP 4, drops scrap 40 %. Frames: patrol 4, saw wind-up 2, saw run 3, skid 2, fling wind-up 2, fling 2,
hurt 1, break apart 4 (20), scalpel 1.

**GRAFTED ORDERLY** (`orderly`, cyborg, re-entry). *Half the staff were replaced. This one was replaced a piece at a time.*
Look: a tall, stooped hospital orderly (about 1.2 times her height) in a stained grey gown; the left arm is a brass
piston ending in a three-finger clamp; a glass tank on its back holds a teal-glowing organ; iron braces on both legs;
a surgical mask wired over its face.

| Move | Warning | What hits | Dodge | Damage (before × 0.75) |
|---|---|---|---|---|
| CLAMP PUNCH | draws the piston arm back, steam hiss, the clamp opens; 0.6 s | the arm shoots 56 px forward at chest height | crouch under it, or backdash; 0.6 s recovery after: hit it | 16 |
| TANK SPRAY | the tank bubbles and glows brighter, it hunches forward; 0.8 s | boiling fluid splashes the floor 64 px in front and stays hot 0.6 s | jump back, or be behind it | 12 |
| LURCH | groans and leans; 0.4 s (used when she is 64-128 px away) | two quick heavy steps toward her (48 px); its body hurts | jump over it, or backdash | 10 |

Health 60, XP 10, drops scrap 50 % and a soul orb 70 %. Frames: idle 4, walk 6, clamp wind-up 2, punch 2, recover 1,
spray wind-up 3, spray 3, lurch wind-up 1, lurch 3, hurt 1, death 5 (31), spray splash 3.

### 3.7 SELF-REPAIR (decision 7)

- Hold H (touch: hold the wrench button by the HP bar). It starts only if she is on the ground, not moving, not
  attacking, has at least 1 scrap, at least 6 EN, and is below full health. Otherwise a dull click.
- 0.4 s start (she kneels and opens a panel in her forearm), then every 0.5 s one tick: −1 scrap, −6 EN, +6 HP.
  EN does not refill while she repairs.
- It ends when the button is released, the health is full, or scrap or EN runs out: a 0.25 s end (panel closes, she stands).
- **A hit cancels it at once** (the tick in progress is not paid and gives nothing). Moving, jumping, attacking or
  opening the quickslot also stops it, with the short end.
- Usable anywhere, boss rooms included, but not in RECALL fights or during dialogue.
- Example: health 60 of 120, 7 scrap, EN 100 → 7 ticks → health 102, EN 58, about 3.9 s standing still.
- Animation and voice: `sprites.md` (self-repair, 10 frames), `bosses-story.md` §8.

### 3.8 SUTURES (decision 8)

- Heals 40 HP at once. Used from ITEMS or the QUICKSLOT strip (no separate key). Refused at full health (a dull click).
- Only the 8 placed in the world exist (carry up to 9). Never refilled: not at terminals, not when she is rebuilt.
- In a RECALL fight, Sutures used come back afterwards (the fight is a memory).

| # | Sheet | Room | Spot |
|---|---|---|---|
| 1 | before the shift | LB | a reading desk at the top of the climb |
| 2 | before the shift | HW | on a coffin lid halfway down the hall |
| 3 | before the shift | SH | a side alcove high in the well (wall-jump climb) |
| 4 | before the shift | HZ | a ledge between the two crushers |
| 5 | after the shift | SH~ | at the bottom of the drained well |
| 6 | after the shift | CH~ | under the altar |
| 7 | after the shift | HZ~ | past the last flame vent, by the shutter lever |
| 8 | after the shift | LB~ | the top shelf near the HZ~ door |

### 3.9 Gear: harnesses and modules (decision 4)

- **MODULES** are parts inside her. Two slots, as in the GDD: **DRIVE** (how hard she hits) and **FRAME** (how much she
  takes). A DRIVE module fits only DRIVE, a FRAME only FRAME, so two damage bonuses never add up (the GDD rule).
- **HARNESSES** are suit pieces worn over her body. Two slots: **TORSO** and **LIMBS**.
- The RESTORE MODULE is a fixed core part: always fitted, no slot, shown in EQUIPMENT as CORE.
- Gear never fits itself, except when you pick EQUIP NOW on its pickup card.
- Harnesses do not change her sprite in the prototype (not planned: that would mean redrawing every frame per harness).
  The icon and the card show them.

| id | Name | Kind, slot | Effect | Where | Sheet |
|---|---|---|---|---|---|
| `coupler_034` | COUPLER-034 | module, DRIVE | swings +5 damage; max HP −40 | LA, upper floor: a dissection table near the hole up to KN | before |
| `governor_207` | GOVERNOR-207 | module, FRAME | max HP +10 | HZ, the altar at the west end behind the bars (Elegy's reach for the lever) | before |
| `restore_module` | RESTORE MODULE | module, CORE (fixed) | one charge: stand back up where she fell (3.10) | WL, inside a dead cache drone hanging from the winch chain | before |
| `cerement_112` | CEREMENT-112 | harness, TORSO | DEF +8 | GA, the hidden monster room off the lab hallway: a pedestal that lights when the last wave falls | before |
| `regulator_000` | REGULATOR-000 | module, DRIVE | swings +5 damage, no cost (the GDD's one exception) | SC~, beside candle 3 | after |
| `pall_090` | PALL-090 | harness, TORSO | max MP +15; soul orbs give 50 % more MP | BI, draped over the empty bier beside candle 2 | after |
| `tether_06` | TETHER-06 | harness, LIMBS | scrap gauge +4 (most 14); each self-repair tick heals +2 more | KN~, the werewolf's old restraints at the bottom, beside candle 1 | after |

Totals: 3 harnesses, 4 modules (3 slotted + the RESTORE MODULE). Before the shift the TORSO choice is "CEREMENT or
nothing" and the DRIVE choice is "COUPLER or nothing"; after it, TORSO and DRIVE each offer a real choice.

| Build at level 1 | Max HP | Dirge hit | DEF |
|---|---|---|---|
| nothing | 100 | 10 | 0 |
| COUPLER + GOVERNOR + CEREMENT | 70 | 15 | 8 |
| REGULATOR + GOVERNOR + CEREMENT + TETHER | 110 | 15 | 8 |

### 3.10 RESTORE MODULE (decision 5)

- Found once, in WL. One charge (the GDD cap of 1). A small diamond by the HP bar is lit while it is charged.
- When she goes offline, the SYSTEM OFFLINE screen offers **RESTORE HERE** (first, highlighted when charged; greyed with
  an empty diamond when not) and **RECONSTRUCT** (at the last save terminal, as today).
- RESTORE HERE: she is rebuilt where she fell (after a trap or a pit: the last solid ground she stood on, the GDD's
  rule), with half her max HP (rounded up), full EN, MP and scrap as they were, and 2 s in which nothing hurts her.
  She plays the rise animation. Enemies and bosses keep their health and stage; boss doors stay shut. The designation
  number still goes up (the death happened).
- **Recharge**: back to 1 whenever she uses a working save terminal, or is reconstructed at one. During the shift no
  terminal works, so its one charge must last until Arnetria falls (being rebuilt at the organ does not recharge it).
- Not offered in RECALL fights (losing one just ends the recall).

### 3.11 LEXICON CORE (decision 10)

Found in SC, the scriptorium off the library. After she has it, each hit on an ordinary enemy (a crab shell's "tink"
counts) shows a plate at the bottom left for 2.5 s: the name and a thin health line. A new hit refreshes it; another
enemy swaps it. The first time a kind is named, the plate flashes cyan with a soft chime. ITEMS shows "Names: 6 / 11".
Bosses already show their names on their bars. Names: section 3.5.

### 3.12 Menus

The pause (Esc or P; touch: the corner button) has five tabs: **ITEMS, EQUIPMENT, CHARACTER, MAP, SYSTEM**. It opens
on the last tab used. C opens CHARACTER directly, M opens MAP directly. Everything stops while a menu is open.
The menu cannot open during a door, a death, a pickup card or show, a dialogue or a recall intro. The key that closes a
menu is swallowed, and attack and jump are ignored for 0.15 s after.

**ITEMS**. Left: USE (SUTURE ×N), then KEY (LEXICON CORE with names learned, GRIP SERVOS, ELEGY-013 once owned),
then the SCRAP gauge (7 / 10). Right: the selected item's picture at 2x, name, description and effect.
Confirm on SUTURE opens a small choice: USE, PUT IN QUICKSLOT 1-4, BACK. The rare consumables of 3.5b are listed under USE and work the same way.

**EQUIPMENT**. Left, seven rows: MAIN HAND, OFF HAND, DRIVE, FRAME, TORSO, LIMBS, CORE (fixed). MAIN HAND lists DIRGE-042 and ELEGY-013; OFF HAND lists BOLT PISTOL and (none), and reads TWO-HANDED, greyed, while ELEGY-013 is in the main hand (3.14). Confirm a row to list what she owns
for it, plus "(none)". Right: LV, HP, EN, MP, ATK, DEF, SPC, and the scrap gauge size. While a choice is highlighted,
each value it would change shows the new number, green if better, red if worse ("HP 100 → 60").

> **Superseded 2026-11-20 (decision 28):** CHARACTER is a read-only sheet: LV, XP, NEXT, HP, EN, MP, ATK, DEF, SPC, and a line "NEXT LEVEL HP +6 EN +4 ATK +5% DEF +1.5%" read from tuning. No buttons, no AUTO, no points.

**CHARACTER (old design)**. Left: VIGOR, POWER, GUARD, STAMINA, MAGIC with their points, a + and − beside each, "POINTS 2", then
the rows AUTO, AUTO EVERY LEVEL (ON/OFF) and DONE. Right: LV, XP, NEXT, and HP, EN, MP, ATK, DEF, SPC with pending
changes in green. − only takes back points added since the screen opened. DONE (or closing) makes them permanent.

**QUICKSLOT**. A strip of 4 slots that opens over the bottom of the screen. While it is open the world runs at a quarter
speed (a slider; 0 stops the world). A slot holds a USE item or a main-hand weapon (the pistol has its own button, 3.14). Default: 1 SUTURE, 2 DIRGE-042, 3 ELEGY-013
(once found), 4 empty. Using a Suture or a weapon closes the strip.

**MAP** (decision 2). Full screen: every visited cell of the current sheet; save terminals `*`, bosses `!`, doors as
ticks, locked doors red, the sealed door's three dots filling in as candles are lit; her cell blinks. Before the shift
it shows sheet I; during the shift sheet II, blank until explored, on a darker paper; after Arnetria sheet I returns
with the new room AR. The corner minimap (top right, 5 x 3 cells around her) is always on. Layout: `map.md`.

**SYSTEM**. Today's buttons: RESUME, CONTROLS (the full key list lives here), RECONSTRUCT, rooms.

Controls (checked against KEYS in `game.gd` lines 6-22 on 2026-11-19: H, F, C, M and N are not used there, so they are free; the pistol takes N. Confirm against `main.gd` before building. Note: 1-4 as quickslot keys collide with the room-jump keys 1-0 in KEYS):

| Action | Keyboard | Touch |
|---|---|---|
| Use (levers, terminals, candles, items, gear) | W / Up | push the stick up, or tap the small hand bubble over the thing |
| Self-repair | hold H | hold the wrench button by the HP bar |
| Pistol (off hand; only with DIRGE-042) | N; Up held aims 45 degrees up (pad: right shoulder) | the pistol button above the attack buttons |
| Quickslot | F opens the strip; A/D or 1-4 choose; J uses; F or K closes; 1-4 also use a slot directly | the bag button above the attack buttons; tap a slot |
| Open CHARACTER / MAP | C / M | tap the LV badge / tap the minimap |
| Pause | Esc or P | the corner button |
| Menu: move | W/S or arrows | tap a row |
| Menu: + / − (CHARACTER) | D / A or right / left | tap + or − |
| Menu: confirm | J or Enter | tap the selected row again |
| Menu: back | K or Backspace | BACK, bottom left |
| Menu: switch tab | Q / E or Tab | tap the tab |
| Pan the full map | arrows or WASD | drag |

### 3.13 Taking things and the pickup card (decisions 1 and 9)

- Items, gear and abilities glow and bob. Within 24 px the hand bubble shows over them; Up takes them, standing or in
  the air. Walking through does nothing. If several things are in reach, the nearest wins. Up and attack on the same
  frame is the special attack, not a pickup. Soul orbs and scrap are taken by touch, with no card.
- **The card** (every item and gear piece; Resident Evil style): the game pauses, the screen dims to 70 % black, the
  item flies to her (0.1 s), chime and a voice line. At 0.15 s the card fades in, centred, 232 x 112 on the
  384 x 216 screen: left, the picture at 2x, slowly bobbing; right, a tag (ITEM, ABILITY, WEAPON, HARNESS, MODULE), the
  NAME, the description and one plain effect line ("Heals 40 HP."). No control hints (decision 17). It cannot close for
  0.5 s, then OK blinks; J, K, Up, Enter or a tap closes it. Gear cards offer EQUIP NOW (J) and LATER (K).
  Sutures after the first show a short card (picture, name, "×3") that can close after 0.3 s.
- **The special show** (weapon, ability, harness, module), about 1.6 s before the card: the world freezes and the music
  drops; the item rises above her with slow light rays (0.5 s); the screen darkens around her and she raises her hand
  (the "receive" animation, 0.5 s); the item shoots into her: white flash, ring burst, sparks, a sting (0.2 s); a cyan
  line sweeps down the screen with one word line, "ARMAMENT BOUND", "PATCH ACCEPTED", "HARNESS FITTED" or "MODULE
  SEATED" (0.4 s); then the card opens with a coloured frame (gold weapon, cyan ability, violet harness, teal module).
  The "Effects amount" and "Screen flash" sliders shrink or remove the rays, sparks and flash.

| id | On screen | Tag | Description (working text; the writer polishes) | Picture idea |
|---|---|---|---|---|
| `suture` | SUTURE | ITEM | "Black thread that knows where the wound is." | curved needle through a black spool |
| `lexicon_core` | LEXICON CORE | ABILITY | "An index of every name the dead were given. Strike a thing and it answers." | small open book-shaped chip, cyan rune |
| `grip_servos` | GRIP SERVOS | ABILITY | "Pulled from the werewolf's claws. Her legs remember how it climbed." | clawed servo with torn fur |
| `elegy_013` | ELEGY-013 | WEAPON | "The Pallbearer's scythe. It was made to carry the dead; now it makes them." | scythe on a diagonal, gold edge |
| `bolt_pistol` | BOLT PISTOL | WEAPON | "SEXTON-19's arm-gun, cut down for one hand. It rang the bell; this is what answered." | iron pistol, brass cylinder, one amber bolt |
| `coupler_034` | COUPLER-034 | MODULE | "Bolts the arm servos to the core. Every strike lands heavier; the core runs thin." | bronze coupling ring, two cables |
| `governor_207` | GOVERNOR-207 | MODULE | "A plated governor for the spine. It keeps the body standing a little longer." | grey spine plate with a gauge |
| `regulator_000` | REGULATOR-000 | MODULE | "The Warden's own regulator, still ticking after its heart stopped." | black clockwork heart, cyan hand |
| `restore_module` | RESTORE MODULE | MODULE | "A cache core small enough to carry. It keeps one copy of her, and only one." | small glass cube with a sleeping light |
| `cerement_112` | CEREMENT-112 | HARNESS | "Grave-cloth bound in steel thread. It held something that did not want to stay down." | wrapped chest piece, steel stitches |
| `pall_090` | PALL-090 | HARNESS | "The velvet from the bier. It remembers the weight of the dead and gives some back." | black velvet mantle, brass clasps |
| `tether_06` | TETHER-06 | HARNESS | "Restraint straps from the kennel. Every buckle has a socket for spare parts." | leather straps with steel sockets |

Pictures are 32 x 32, drawn or edited in Aseprite, shown at 2x on the card.

### 3.14 BOLT PISTOL: the off hand (decision 21)

**What it is.** A small ranged weapon taken from SEXTON-19 (`bosses-story.md` 3b; room OW in `map.md`). It is for what the blade cannot reach: flying enemies and enemies standing on ledges. It is optional: no gate needs it.

**Who can hold it.**
- She has two hand slots: MAIN HAND (DIRGE-042 or ELEGY-013) and OFF HAND (BOLT PISTOL or nothing).
- The pistol works only while DIRGE-042 is in the main hand. ELEGY-013 is two-handed: with Elegy in hand the OFF HAND row is greyed (TWO-HANDED), the pistol button is dimmed and does nothing (a dull click). Swapping back to Dirge makes it ready again; nothing is fitted twice.
- It is fitted to OFF HAND by itself when taken (EQUIP NOW is the default on its card).

**Controls.** Keyboard N: checked against KEYS in `game.gd` lines 6-22, it is unused (H, F, C and M are taken by this design; N sits under the right hand beside J and K). Add `"pistol": [KEY_N]` to KEYS. Pad: right shoulder (the pad map uses A, X, Y and B). Touch: a round pistol button above the attack buttons with a small EN pip, dimmed with Elegy. Holding the button repeats at the fire rate. Up held while firing aims 45 degrees up; otherwise the shot goes straight ahead, the way she faces.

**Firing rules.**
- One shot costs `pistol_en` EN. With less EN: no shot, a dull click, the EN bar flashes once. EN refills by the same rules as every other EN cost.
- A shot can start standing, crouching, jumping or falling. Not during a swing, backdash, slide, hurt, self-repair or cast. On the ground a shot plants her feet for 0.2 s (stop and shoot); in the air she keeps her momentum.
- A 0.15 s recoil follows each shot: no swing can start in it, and no shot can start inside a swing. Shots come `pistol_cooldown` seconds apart at most.
- A bolt flies straight at `pistol_speed` px/s and vanishes after `pistol_range` px, at the first enemy or solid tile (a spark and a tink), or at the room edge. It does not pass through doors. It never hurts her.
- Damage: formula F12. Kills by bolts give normal XP and drops. Arnetria's rules (`bosses-story.md` 4.4) treat a bolt like any hit: check this when it is built.
- **Bolts cannot open or move anything.** No lever, switch, winch, candle, door, shutter or cracked wall reads a bolt. The hazard chapel's barred lever still needs Elegy's reach: the bars stop bolts (a tink) and the lever ignores them anyway. The same holds for the barred lever in BI and every other lever.

**Menus.** EQUIPMENT has seven rows (3.12). With OFF HAND highlighted the right panel shows the pistol's numbers ("BOLT 6, EN 8, 2.5 a second").

**Looks.** Her pistol is drawn only while she shoots (five 3-frame shots, `sprites.md` section 4); otherwise it is holstered out of sight. The bolt is a small amber dart with a 2-frame muzzle flash.

**Balance reasoning.** A bolt is 60 % of a Dirge hit for 8 EN, and a full 100 EN gives 12 shots, about 72 damage: enough to finish a ledge ghost or soften a moth, not enough to replace the blade. It is a tool with a cost (Autonomy: a choice of how to answer a flyer), not a damage upgrade.


---

## 4. Formulas

All results round half up to a whole number. `h` = HP / max HP.

| # | Formula | Variables (range) |
|---|---|---|
| F1 | `weapon_hit = max(1, round(P × ATK / 100 + D)) × hand` | P = swing power: Dirge 10, Elegy 20; ATK = 100 + 8 × POWER (100-244); D = DRIVE bonus 0 or 5; hand = 0.25 on the Pallbearer's hands, else 1 (round again after) |
| F2 | `special_hit = max(1, round(S × SPC / 100))` | S = blade wave 30, Requiem 24 per pass; SPC = 100 + 8 × MAGIC (100-244) |
| F3 | `taken = max(1, round(R × M × (100 − DEF) / 100))` | R = the enemy's damage value; M = 0.75 ordinary enemies, 1.0 bosses; DEF = min(40, 3 × GUARD + harness DEF) |
| F4 | `trap_taken = round(T × 0.75)` | T = today's trap value (30-40); DEF does not apply |
| F5 | `max_HP = max(50, 100 + 10 × VIGOR + module HP)`; `max_EN = 100 + 8 × STAMINA`; `max_MP = 60 + 6 × MAGIC + harness MP` | module HP: Coupler −40, Governor +10; harness MP: Pall +15 |
| F6 | `xp_to_next(L) = 10 × (L + 1)`; `total_xp(L) = 5 × (L − 1) × (L + 2)` | L = 1-10 |
| F7 | `scrap_chance = min(0.95, base × (1 + boost × clamp((0.75 − h) / 0.5, 0, 1)))` | base: trolley 0.40, orderly 0.50; boost = 1.0 (double chance at 25 % health or less) |
| F8 | `repair_ticks = min(scrap, floor(EN / 6), ceil((max_HP − HP) / R))`, `healed = min(max_HP − HP, ticks × R)`, `time = 0.4 + 0.5 × ticks` | R = 6, or 8 with TETHER-06 (if held for all ticks) |
| F9 | `orb_mp = 10 × (1.5 if PALL-090 else 1)` | capped at max MP |
| F10 | `restore_HP = ceil(max_HP × 0.5)` | |
| F11 | `respawn_xp = ceil(xp × 0.5)`; `recall_xp = ceil(boss_xp × 0.25)` | recall: UNMUZZLED 8, SEXTON-19 9, PALLBEARER 13, ARNETRIA 20 |
| F12 | `bolt_hit = max(1, round(B x ATK / 100)) x armour` | B = `pistol_damage` 6; ATK = 100 + 8 x POWER (100-244); armour = 0.25 on the Pallbearer's hands and on SEXTON-19's slab, else 1; DRIVE bonuses do not apply (they are for swings). Level 5 on AUTO: 6 x 1.24 = 7.44, so 7 |
| F13 | `rare drops if R.rng.randf() < chance`; `chance = base_k x (rare_respawn_mult if the enemy had come back, else 1)` | base_k from 3.5b (0.02-0.05); the TANK HEART's base is 0 once `tank_heart_max` have dropped; one roll per kill, after the orb and scrap rolls |

Worked examples:
- F1: level 5 on AUTO, Dirge: 10 × 124 / 100 = 12.4 → 12. With COUPLER: 12.4 + 5 = 17.4 → 17.
  On a Pallbearer hand: 17 × 0.25 = 4.25 → 4.
- F2: MAGIC 2 (SPC 116): blade wave 30 × 1.16 = 34.8 → 35; Requiem 24 × 1.16 = 27.8 → 28 per pass.
- F3: ghost touch (R 7) at level 1: 7 × 0.75 = 5.25 → 5 (20 touches from 100). Orderly clamp (R 16) at level 4 with
  CEREMENT (DEF 3 + 8 = 11): 16 × 0.75 × 0.89 = 10.7 → 11. Pallbearer Reap (R 25) at level 5 (DEF 3): 24.25 → 24 of 130.
- F4: crusher 40 × 0.75 = 30.
- F7: trolley at full health 40 %; at half health (h 0.5): 0.4 × 1.5 = 60 %; at 20 % health: 80 %. Orderly at 20 %: 95 %.
- F8: see 3.7.
- F10: max HP 130 → rebuilt with 65.

---

## 5. Edge cases

- **Unspent points**: kept forever; the "+N" pip keeps blinking. AUTO EVERY LEVEL spends only new points, never banked ones.
- **Level 10**: XP stops; the XP line reads MAX. Two level-ups from one kill: one "LEVEL UP", 4 points, one refill.
- **Level-up mid-fight**: the refill happens at once; the offer never pauses the game by itself (unless the slider says so).
- **POWER all in plus COUPLER** (level 10: ATK 244, Dirge 24 + 5 = 29): a hound (30) still takes 2 hits. Weak means
  health 30 or less, not hit count, so they still come back.
- **Self-repair** at full health, with 0 scrap or under 6 EN: does not start (dull click). In the air or on a moving
  platform: does not start. Hit on the same frame as a tick: the hit wins, the tick is not paid.
- **Scrap or orb** over a pit or inside a wall: placed on the nearest floor, at least 16 px from walls. Full gauge or
  full MP: it stays on the floor until it fades.
- **Gear**: losing max HP (fitting COUPLER) lowers current HP to the new max, never below 1. Gaining max HP (removing
  it) does not heal, so swapping is never a free heal. Max HP never drops below 50. Removing TETHER-06 with 13 scrap
  keeps 10; the extra 3 drop on the floor at her feet.
- **RESTORE HERE** with no charge: greyed, cannot be picked. Death in a trap or pit: rebuilt on the last solid ground
  she stood on. Death on the same frame a boss dies: the boss death wins; she is not offline.
- **Pickups**: Up with nothing in reach does nothing (no sound). Going offline during a card or the special show cannot
  happen: the world is frozen. Gear left behind waits where it lies.
- **RECALL**: full HP, EN and MP; Sutures used come back; no restore; no drops; going offline only ends the recall.
- **Respawn farming** (10 s returns): two trolleys in LA give about three scrap a minute (about 19 HP); half-XP enemies give about
  16 XP a minute in the best room (open point 4). Moving on still pays better.
- **Rare drops**: a returned weak enemy rolls at half chance, so 10 s farming finds a rare about once in 10 to 15 minutes. A full stack (3) of a consumable leaves the next one on the floor. TANK HEART stops dropping after 2. Using a timed rare while its timer runs restarts it, never doubles it.
- **BOLT PISTOL**: with Elegy in hand the button does nothing; EN under the cost never fires; bolts stop at bars and the barred lever never sees them; a bolt in flight when she swaps to Elegy still lands. Taking the pistol with Elegy in hand fits it to OFF HAND and greys it until Dirge is back. RECALL: the pistol works, the TANK HEART and rares are not dropped.

## 6. Dependencies

| System | This design needs from it | It needs from this design |
|---|---|---|
| `player.gd` | states for self-repair, rise after restore, receive and interact poses | stat values (F1-F5), self-repair rules (3.7) |
| `enemy.gd`, `enemy2.gd`, new `trolley`, `orderly` | death event with kind and position | XP, drops, coming back (3.5, 3.6) |
| `main.gd` (pause, cards, offline screen) | today's pause tree and offline screen | menus (3.12), card and show (3.13), RESTORE HERE (3.10) |
| HUD | today's HP, EN, MP bars | LV badge, XP line, scrap gauge, restore diamond, minimap |
| `map.md` | room ids and spots for every reward | the gear and Suture lists (3.8, 3.9) |
| `bosses-story.md` | boss health and XP, RECALL rules | stat expectations per boss (3.2 ledger) |
| `sprites.md` | self-repair, death, interact, receive, rise animations, five pistol shots | when each plays |
| `game.gd` (KEYS), touch HUD, `player.gd` | a `pistol` action (N, pad right shoulder), a touch button, five shot states | the pistol rules (3.14) |
| levers, barred walls (`props.gd`), `door.gd` | bolts are their own group; nothing reads them | the rule that bolts never trigger anything (3.14) |
| `loot.gd` | the drop table (3.5b), the `R.rng` rare roll | rare roll after the orb and scrap rolls (F13) |
| GDDs | point values (+8 ATK, +10 HP), module slots and effects, the restore placement rule | departures listed in `decisions.md` |

## 7. Tuning knobs (new `tuning.json` rows, an RPG page in the F1 panel)

Format as today: value / min / max / step / label / help. Kind: F = feel, C = curve, G = gate.

| key | value | min | max | step | label | help (plain words) |
|---|---|---|---|---|---|---|
| xp_curve_step | 10 | 4 | 30 | 1 | Levels: XP curve (C) | XP for the next level is this × (level + 1). 10: level 2 at 20 XP, 5 at 140, 10 at 540. |
| level_cap | 10 | 5 | 20 | 1 | Levels: highest level (G) | She stops gaining XP here. |
| points_per_level | 2 | 1 | 4 | 1 | Levels: points per level (C) | Points she gets at each level-up. |
| levelup_opens_menu | 0 | 0 | 1 | 1 | Level up: open CHARACTER by itself (F) | 0 = a small prompt you can ignore. 1 = the screen opens at once. |
| levelup_prompt_time | 4 | 1 | 10 | 0.5 | Level up: prompt shown for (F) | Seconds the "+2 [C]" prompt stays. |
| levelup_text_time | 1.2 | 0.4 | 3 | 0.1 | Level up: text time (F) | How long "LEVEL UP" floats above her. |
| start_level | 1 | 1 | 10 | 1 | Test: start at level | For testing; points are spent by AUTO. |
| vigor_hp | 10 | 0 | 30 | 1 | One VIGOR point: health + (C) | 10 = about two more ghost touches. |
| power_atk | 8 | 0 | 20 | 1 | One POWER point: weapon damage % (C) | 8 = a Dirge hit grows by almost 1. |
| guard_def | 3 | 0 | 8 | 1 | One GUARD point: less damage % (C) | Enemy hits only, not traps. |
| stamina_en | 8 | 0 | 20 | 1 | One STAMINA point: energy + (C) | A swing costs 12. |
| magic_special | 8 | 0 | 20 | 1 | One MAGIC point: special damage % (C) | Blade wave 30 becomes 32.4. |
| magic_mp | 6 | 0 | 15 | 1 | One MAGIC point: MP + (C) | A blade wave costs 15. |
| def_cap | 40 | 0 | 60 | 5 | Defence: most (C) | DEF never goes above this percent. |
| xp_ghost / xp_hound / xp_spitter | 3 | 0 | 50 | 1 | XP: ghost, hound, spitter (C) | XP for beating it (three rows). |
| xp_leech / xp_trolley | 4 | 0 | 50 | 1 | XP: leech, trolley (C) | Two rows. |
| xp_choir | 6 | 0 | 50 | 1 | XP: choir (C) | |
| xp_moth | 7 | 0 | 50 | 1 | XP: moth (C) | |
| xp_orderly / xp_scribe | 10 | 0 | 50 | 1 | XP: orderly, scribe (C) | Two rows. |
| xp_crab | 12 | 0 | 50 | 1 | XP: crab (C) | |
| xp_warden | 14 | 0 | 50 | 1 | XP: warden (C) | |
| xp_unmuzzled | 30 | 0 | 150 | 5 | XP: THE UNMUZZLED (C) | Takes her from about level 3 toward 4. |
| xp_sexton | 35 | 0 | 150 | 5 | XP: SEXTON-19 (C) | Optional mini-boss; about level 4 toward 5. |
| xp_pallbearer | 50 | 0 | 200 | 5 | XP: THE PALLBEARER (C) | Takes her from about level 4 to 5. |
| xp_arnetria | 80 | 0 | 300 | 5 | XP: ARNETRIA (C) | |
| xp_respawn_mult | 0.5 | 0 | 1 | 0.1 | XP: enemies that came back × (C) | 0.5 = half, rounded up. |
| recall_xp_mult | 0.25 | 0 | 1 | 0.05 | RECALL: share of the boss's XP (C) | Given for every recall win. |
| area_damage_mult | 0.75 | 0.25 | 1.5 | 0.05 | Area enemies: damage × (F) | Ordinary enemies and shots. Not bosses. |
| area_rest_mult | 1.2 | 0.5 | 2 | 0.05 | Area enemies: rest × (F) | Longer pauses between their attacks. |
| trap_damage_mult | 0.75 | 0.25 | 1.5 | 0.05 | Traps: damage × (F) | Crusher 40 becomes 30. |
| weak_respawn_s | 10 | 3 | 120 | 1 | Coming back: wait (G) | Seconds before a fallen weak enemy returns while she stays (decision 18). It comes back out of her sight and never within 96 px. |
| respawn_hp_limit | 30 | 0 | 80 | 1 | Coming back: weak means health up to (G) | 0 = none come back in the room. |
| respawn_warning | 1 | 0.3 | 2.5 | 0.1 | Coming back: warning sound (F) | Seconds of faint rattle before it returns (it is out of sight, so a sound, not a shimmer). |
| respawn_distance | 96 | 32 | 200 | 8 | Coming back: not closer than (F) | 96 = six tiles. |
| soul_orb_mp | 10 | 2 | 40 | 1 | Soul orb: MP (C) | Two thirds of a blade wave. |
| soul_orb_chance_weak | 0.6 | 0 | 1 | 0.05 | Soul orb: chance from weak enemies (C) | Others always drop one. |
| orb_life | 12 | 4 | 30 | 1 | Soul orb: seconds before it fades (F) | Blinks the last 3 s. |
| scrap_max | 10 | 1 | 30 | 1 | Scrap: gauge size (C) | Most scrap she can hold. |
| scrap_life | 20 | 5 | 60 | 1 | Scrap: seconds on the floor (F) | Blinks the last 3 s. |
| scrap_chance_trolley | 0.4 | 0 | 1 | 0.05 | Scrap: chance from the trolley (C) | At full health. |
| scrap_chance_orderly | 0.5 | 0 | 1 | 0.05 | Scrap: chance from the orderly (C) | At full health. |
| scrap_low_hp_boost | 1 | 0 | 3 | 0.1 | Scrap: extra chance when hurt (C) | 1 = double chance at a quarter health or less. |
| scrap_low_hp_start | 0.75 | 0.3 | 1 | 0.05 | Scrap: extra chance starts below (C) | Health share where the bonus begins. |
| repair_start | 0.4 | 0.1 | 1.5 | 0.05 | Self-repair: start time (F) | Kneel and open the panel. |
| repair_tick | 0.5 | 0.2 | 1.5 | 0.05 | Self-repair: time per scrap (F) | |
| repair_hp | 6 | 1 | 30 | 1 | Self-repair: health per scrap (C) | A full gauge of 10 heals 60. |
| repair_en | 6 | 0 | 30 | 1 | Self-repair: energy per scrap (C) | |
| suture_heal | 40 | 10 | 100 | 5 | Suture: heals (C) | Eight ghost touches. |
| suture_max | 9 | 1 | 9 | 1 | Suture: most carried (G) | Only 8 exist. |
| restore_charges | 1 | 0 | 3 | 1 | Restore module: charges (G) | Refilled at a working save terminal. |
| restore_hp | 0.5 | 0.1 | 1 | 0.05 | Restore module: health share (C) | 0.5 = half her max health. |
| restore_safe_time | 2 | 0.5 | 4 | 0.25 | Restore module: unhurtable time (F) | Seconds after she stands up. |
| coupler_damage | 5 | 0 | 20 | 1 | COUPLER-034: damage + (C) | |
| coupler_hp | -40 | -80 | 0 | 5 | COUPLER-034: health change (C) | The price. |
| governor_hp | 10 | 0 | 40 | 5 | GOVERNOR-207: health + (C) | Raise it if it feels small. |
| regulator_damage | 5 | 0 | 20 | 1 | REGULATOR-000: damage + (C) | No price. |
| cerement_def | 8 | 0 | 20 | 1 | CEREMENT-112: defence + (C) | |
| pall_mp | 15 | 0 | 40 | 5 | PALL-090: MP + (C) | |
| pall_orb_mult | 1.5 | 1 | 3 | 0.1 | PALL-090: soul orb × (C) | |
| tether_scrap | 4 | 0 | 10 | 1 | TETHER-06: gauge + (C) | |
| tether_repair | 2 | 0 | 10 | 1 | TETHER-06: health per scrap + (C) | |
| trolley_health / orderly_health | 28 / 60 | 10 | 150 | 1 | Machines: health (C) | Two rows. |
| trolley_saw_damage / trolley_scalpel_damage | 10 / 6 | 0 | 40 | 1 | Trolley: damage (F) | Before the area × 0.75. Two rows. |
| orderly_clamp_damage / orderly_spray_damage / orderly_lurch_damage | 16 / 12 / 10 | 0 | 40 | 1 | Orderly: damage (F) | Three rows. |
| trolley_windup / orderly_windup | 0.6 / 0.6 | 0.35 | 1.5 | 0.05 | Machines: warning time (F) | Never under 0.35 s. |
| pickup_reach | 24 | 12 | 48 | 2 | Pickup: reach (F) | How close she must stand to use Up. |
| pickup_lock | 0.5 | 0 | 1.5 | 0.05 | Pickup card: cannot close for (F) | Stops a mashed button skipping it. |
| special_pickup_time | 1.6 | 0.6 | 3 | 0.1 | Special pickup: show length (F) | |
| scan_show_time | 2.5 | 0.5 | 6 | 0.5 | Enemy names: shown for (F) | |
| quickslot_time_scale | 0.25 | 0 | 1 | 0.05 | Quickslot: world speed while open (F) | 0 = the world stops. |
| pistol_damage | 6 | 1 | 20 | 1 | Bolt pistol: damage per bolt (C) | Before her POWER. 6 is 60 % of a Dirge hit. |
| pistol_speed | 360 | 120 | 720 | 20 | Bolt pistol: bolt speed (F) | Pixels a second. 360 crosses most of a screen in a second. |
| pistol_range | 240 | 96 | 480 | 16 | Bolt pistol: range (F) | Pixels before the bolt fades. 240 is 15 tiles. |
| pistol_en | 8 | 0 | 30 | 1 | Bolt pistol: EN per shot (C) | 100 EN gives 12 shots. 0 makes it free. |
| pistol_cooldown | 0.4 | 0.15 | 1.5 | 0.05 | Bolt pistol: seconds between shots (F) | Fire rate: 0.4 is 2.5 shots a second. |
| pistol_plant | 0.2 | 0 | 0.5 | 0.05 | Bolt pistol: feet planted on the ground (F) | Seconds she stands still to shoot. 0 = run and gun (needs run-shot frames). |
| pistol_up_angle | 45 | 0 | 60 | 5 | Bolt pistol: aim up angle (F) | Degrees when Up is held. |
| rare_chance_weak | 0.03 | 0 | 0.1 | 0.005 | Rare drops: ghost, leech, spitter, hound (C) | Four rows. 3 %. |
| rare_chance_trolley / choir / moth / scribe | 0.04 | 0 | 0.1 | 0.005 | Rare drops: trolley, choir, moth, scribe (C) | Four rows. 4 %. |
| rare_chance_crab / warden | 0.05 | 0 | 0.1 | 0.005 | Rare drops: crab, warden (C) | Two rows. 5 %. |
| rare_chance_strong | 0.02 | 0 | 0.03 | 0.005 | Rare drops: the one strong rare, TANK HEART (C) | The orderly's 2 %. 0 turns it off. |
| rare_respawn_mult | 0.5 | 0 | 1 | 0.1 | Rare drops: chance for enemies that came back x (C) | Keeps 10 s farming honest. |
| rare_stack_max | 3 | 1 | 9 | 1 | Rare drops: most carried of each (G) | A fourth stays on the floor. |
| rare_life | 20 | 5 | 60 | 1 | Rare drops: seconds on the floor (F) | Blinks the last 3 s. |
| static_shard_mp / ash_poultice_hp / grave_salt_hp | 30 / 20 / 30 | 5 | 100 | 5 | Rare effects: MP and health given (C) | Three rows. |
| bile_flask_damage / bile_flask_time | 3 / 20 | 1 | 60 | 1 | BILE FLASK: damage + and seconds (C) | Two rows. |
| trolley_bolts_scrap | 5 | 1 | 10 | 1 | TROLLEY BOLTS: scrap given (C) | Up to the gauge size. |
| hushed_bell_cut / hushed_bell_time | 0.25 / 15 | 0.05 | 0.6 | 0.05 | HUSHED BELL: damage cut and seconds (C) | Two rows; the time slider runs 5-40. |
| steel_nib_damage / chain_collar_def / saint_rib_def | 2 / 2 / 3 | 0 | 8 | 1 | Minor gear: damage + and defence + (C) | Three rows. |
| tank_heart_hp / tank_heart_max | 20 / 2 | 5 | 50 | 5 | TANK HEART: max health + and most that can drop (C) | Two rows; the count slider runs 1-5. |

Unchanged: weapon power (`attack_damage`, `elegy_damage_mult`), run speed, jump, backdash, today's enemy health and
damage values, specials' MP costs. Boss numbers belong to `bosses-story.md`.

## 8. Acceptance criteria

Functional (a tester can check each):
- XP thresholds are 20/50/90/140/200/270/350/440/540; level 10 stops XP.
- A level-up refills HP, EN and MP to full and banks 2 points; ignoring the prompt keeps them; AUTO spends them in the
  stated order; the AUTO table matches at every level.
- One point gives exactly: VIGOR +10 HP, POWER +8 % ATK, GUARD +3 DEF, STAMINA +8 EN, MAGIC +8 % SPC and +6 MP.
- Dirge on a ghost: 3 hits at level 1, 2 at level 3 on AUTO. Blade wave at MAGIC 2 deals 35.
- Walking through a Suture or gear does nothing; Up takes it. Touching a soul orb or scrap takes it; at full it stays.
- Trolley scrap chance is 40 % at full health and 80 % at 20 % health (1,000 simulated kills, within 3 %).
- Self-repair with 7 scrap, 100 EN, 60/120 HP ends at 102 HP, 58 EN, 0 scrap after about 3.9 s; a hit stops it at once.
- Sutures: exactly 8 exist; none refill at a terminal or after a death; one heals 40 and is refused at full health.
- RESTORE HERE appears only when charged, rebuilds her where she fell at half health, and recharges at a working terminal.
- Equipment preview numbers equal the stats after equipping. COUPLER and REGULATOR can never be fitted together.
- The card cannot close before 0.5 s; the special show lasts about 1.6 s; no card shows a control hint.
- A weak enemy returns 10 s after falling while she stays, out of her sight, never within 96 px, with half XP.
- Every enemy kind has exactly one rare in the 3.5b table; over 10,000 simulated kills each kind's rate is within 0.5 points of its chance; the TANK HEART is only ever dropped by the orderly and never more than twice.
- BOLT PISTOL: with ELEGY-013 in hand it never fires and its button is dimmed; with DIRGE-042 it fires, costs 8 EN, and cannot fire with less. A bolt never moves the hazard chapel's barred lever or any other lever, and is stopped by bars.
- EQUIPMENT shows MAIN HAND and OFF HAND rows; OFF HAND is greyed while Elegy is in the main hand.
- RECALL never shows the SYSTEM OFFLINE screen; a win gives 25 % of the boss's XP and no second weapon or ability.

Playtest (you):
- Does a level-up feel like a reward, and is the CHARACTER screen easy to understand without help?
- Do you reach the Pallbearer at about level 4 or 5, and Arnetria at about 7 or 8?
- Does self-repair feel tense (worth the risk) but not slow?
- Are 8 Sutures enough to finish without feeling stuck, and is the scrap at low health noticeable?
- Do rooms feel calmer and bosses harder but fair?
- Does the 10 s return feel like pressure and not like a chore? Does a rare drop feel like a small pleasant surprise?
- Does the pistol feel worth its EN against a flyer and a ledge enemy, without making the blade feel second-best?

## Open points (waiting on user, at most five)

1. Main stat names VIGOR, POWER, GUARD, STAMINA, MAGIC: recommended as plain words; say if you want others.
2. CHARACTER opens by itself after a level-up, or a small prompt (recommended: the prompt, so fights are not interrupted).
3. The art look of the two lab machines (section 3.6) before anything is drawn.
4. Respawn farming at 10 s: about 16 XP a minute in the best room. Recommended: keep it and watch it in the first playtest; if it feels cheap, add a slider so a room's returned enemies give no XP after 5 returns.
5. BOLT PISTOL numbers (6 damage, 8 EN, 0.4 s, key N) and whether bolts may break the cracked wall in HZ (the draft says no: bolts open nothing).
