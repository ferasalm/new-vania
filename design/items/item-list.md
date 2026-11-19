# Item list - everything she can pick up or equip

A living list of every item in the game, from `prototypes/feel-v3/data/items.json`
and `prototypes/feel-v3/data/gear.json`, plus the two marks whose data does not
exist yet. "Where it is found" comes from the item marks in
`prototypes/feel-v3/data/rooms_meta.json` and the drop tables in
`prototypes/feel-v3/data/enemies.json`.

How pictures work: the game looks for `prototypes/feel-v3/assets/items/<id>.png`
(one transparent 32x32 PNG per item, named after the id). If the file is there
it is used in menus, in the room, and on the pick-up card. If it is not there,
the game draws a placeholder: a square coloured by the item's kind with the
item's first letter. Adding a correctly named PNG is enough - no code change.
See `prototypes/feel-v3/assets/items/README.txt`.

Status: **not one item has a real picture yet** - the `assets/items/` folder was
empty when this list was written, so every row is "placeholder".

| id | name | kind | where it is found | image file name | image status |
|---|---|---|---|---|---|
| suture | SUTURE | consumable | found in rooms (8 placed: LB, HW, SH, HZ before the shift; SH~, CH~, HZ~, LB~ after) | assets/items/suture.png | placeholder |
| lexicon_core | LEXICON CORE | ability | found in rooms (SC, the scriptorium) | assets/items/lexicon_core.png | placeholder |
| wall_jump | GRIP SERVOS | ability | found in rooms (KN, the kennel); also the reward for beating LUPERCAL-06, THE UNMUZZLED | assets/items/grip_servos.png | placeholder |
| elegy_013 | ELEGY-013 | weapon | reward from THE PALLBEARER (boss) | assets/items/elegy_013.png | placeholder |
| soul_orb | SOUL ORB | orb | dropped by enemies (pale light where something died; weak enemies by chance, others always) | assets/items/soul_orb.png | placeholder |
| scrap | SCRAP | currency | dropped by enemies (bolts and plate; more often the lower her health) | assets/items/scrap.png | placeholder |
| static_shard | STATIC SHARD | consumable | rare drop from GRAVE STATIC (ghost) | assets/items/static_shard.png | placeholder |
| tithe_jar | TITHE JAR | consumable | rare drop from TITHE LEECH (leech) | assets/items/tithe_jar.png | placeholder |
| bile_flask | BILE FLASK | consumable | rare drop from BILE CANTOR (spitter) | assets/items/bile_flask.png | placeholder |
| trolley_bolts | TROLLEY BOLTS | consumable | rare drop from SAWBONES TROLLEY (the trolley enemy is not in enemies.json yet) | assets/items/trolley_bolts.png | placeholder |
| hushed_bell | HUSHED BELL | consumable | rare drop from HOLLOW CHOIR (choir) | assets/items/hushed_bell.png | placeholder |
| ash_poultice | ASH POULTICE | consumable | rare drop from CENSER MOTH (moth) | assets/items/ash_poultice.png | placeholder |
| grave_salt | GRAVE SALT | consumable | rare drop from OSSUARY WARDEN (warden) | assets/items/grave_salt.png | placeholder |
| tank_heart | TANK HEART | consumable | rare drop from GRAFTED ORDERLY (the orderly enemy is not in enemies.json yet; at most 2 can ever drop) | assets/items/tank_heart.png | placeholder |
| coupler_034 | COUPLER-034 | gear (module) | found in rooms (LA, the specimen hall) | assets/items/coupler_034.png | placeholder |
| governor_207 | GOVERNOR-207 | gear (module) | found in rooms (HZ, the threshing chapel) | assets/items/governor_207.png | placeholder |
| regulator_000 | REGULATOR-000 | gear (module) | found in rooms (SC~, the blotted scriptorium) | assets/items/regulator_000.png | placeholder |
| restore_module | RESTORE MODULE | gear (core) | found in rooms (WL, the winch loft) | assets/items/restore_module.png | placeholder |
| cerement_112 | CEREMENT-112 | gear (harness) | found in rooms (GA, the reliquary of shells) | assets/items/cerement_112.png | placeholder |
| pall_090 | PALL-090 | gear (harness) | found in rooms (BI, the empty bier) | assets/items/pall_090.png | placeholder |
| tether_06 | TETHER-06 | gear (harness) | found in rooms (KN~, the sunken kennel) | assets/items/tether_06.png | placeholder |
| chain_collar | CHAIN COLLAR | gear (harness) | rare drop from CHAINBITE HOUND (hound) | assets/items/chain_collar.png | placeholder |
| saint_rib | SAINT RIB | gear (harness) | rare drop from RELIQUARY CRAB (crab) | assets/items/saint_rib.png | placeholder |
| steel_nib | STEEL NIB | gear (module) | rare drop from NEEDLE SCRIBE (scribe) | assets/items/steel_nib.png | placeholder |
| bolt_pistol | BOLT PISTOL | key item | mark exists in OW (the ordnance ward) but no item data yet - the game skips it until SEXTON-19 arrives | assets/items/bolt_pistol.png | placeholder |
| visor | ARNETRIA'S VISOR | key item | mark exists in AR (the quiet ring) but no item data yet and nothing spawns it | assets/items/visor.png | placeholder |

Notes:

- "found in rooms" = an item mark placed in the room map (taken once for ever).
  Room codes are in `rooms_meta.json` (LB = library, SC = scriptorium, and so on).
- "rare drop" = a small chance when that enemy dies (the one rare each enemy
  has, from `enemies.json`).
- The "image file name" column is what the item data's `icon` line already
  names; those PNG files do not exist yet (see the status column).
- GRIP SERVOS uses the file name `grip_servos.png`, not `wall_jump.png` - the
  id and the picture name differ on purpose, because the item data's `icon`
  line names the file.
- A test picture for the suture was created once to prove the picture rule,
  then moved aside to `assets/items/_aside_suture.png`; it is not a real item
  picture and must not be committed.
