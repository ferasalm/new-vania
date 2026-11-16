# Playtest verdicts

This file records what the user said after playing a prototype, and what we
change because of it. It is the highest authority in the project: it outranks
every design document. When a document and this file disagree, this file wins
and the document is corrected.

## Prototype v2 — played 2026-11-16 — verdict: rejected

| # | What the user said | What changes in v3 | Stage | Status |
|---|---|---|---|---|
| 1 | Movement is heavy and slow | Full speed the moment you press, instant stop, faster run | 1 | done |
| 2 | The dash is useless | Dash replaced by a quick backdash | 1 | done |
| 3 | The jump is heavy and useless | Hold for a high jump, tap for a short hop, steer in the air | 1 | done |
| 4 | I do not like the knockdown at all | Removed; a hit gives a short flinch and a moment of safety | 1 | done |
| 5 | No sounds, music or visual effects | Footsteps, jump, land, swing, hit, enemy death, music, hit sparks, dust | 1 | in progress (effects done; sounds rejected, see stage 1 verdict) |
| 6 | No animation for movement | Stand-in pixel heroine with idle, run, jump and attack animation | 1 | done |
| 7 | The prototype feels dead | Sound, effects, animation, small screen shake, damage numbers | 1 | done |
| 8 | The boss looked backward to attack; its animation was just flipping pictures | Boss always faces the player and uses full animation | 3 | planned |
| 9 | Enemies looked picked without thought (a crab?); where are the demons and cyborgs | Demons and machines from our art packs, each with one clear behaviour | 1 (two enemies), 2 (full cast) | stage 1 part done; rest planned |
| 10 | Gameplay depends on counter and timing; I wanted the feel of Castlevania: Order of Ecclesia; counter and slash should be minor extras | Attack always hits when it connects; counter removed for now, returns in stage 3 as an optional bonus | 1, 3 | stage 1 part done; rest planned |
| 11 | No attack animation like Order of Ecclesia | Real sword-swing animation, on the ground and in the air | 1 | done |
| 12 | No backdash like Symphony of the Night | Backdash added | 1 | done |
| 13 | No platforms to jump around on | Solid platforms and drop-through ledges | 1 | done |
| 14 | No doors | A working door in stage 1; connected rooms in stage 2 | 1, 2 | stage 1 part done; rest planned |
| 15 | Nothing felt good | The whole prototype is rebuilt as `prototypes/feel-v3/`, judged by the user after each stage | all | planned |

## Stages

- Stage 1 The body (one room: movement and attack) — feel approved 2026-11-16; sounds in progress
- Stage 2 The place (connected rooms, doors, demons and machines) — planned
- Stage 3 The boss (Arnetria rebuilt, counter as a bonus) — planned
- Stage 4 Write it down (approved numbers go into the movement and combat documents) — planned

## Prototype v3 stage 1 — played 2026-11-16 — verdict: feel approved, sounds rejected

**What the user said**

- "That was amazing." "Almost everything felt good": jumping between platforms, attacking,
  backdashing, jumping, chain attacking, run speed.
- They liked tuning with the sliders while playing Castlevania on the side, and want every
  prototype built this way, in OpenCode too.
- "What I did not like was the sounds. The sound effects and BGM were not really good,
  especially the backdash and loud hits when they connect, and the male sounding voices when
  getting hit."

**The values the user saved with the F1 panel** (now in `prototypes/feel-v3/tuning.json`)

| Setting | Before | Saved | What it means |
|---|---|---|---|
| Run speed | 140 | 125 | A little slower: crosses the screen in about 3 seconds |
| Jump power | 300 | 325 | Jumps higher: about 68 px, a bit over one and a half times her height |
| Backdash length | 0.22 s | 0.25 s | The backdash travels a little further |
| Backdash wait | 0.05 s | 0.15 s | A short pause before the next backdash |
| Attack length | 0.26 s | 0.40 s | Each swing is slower and more deliberate |
| Chain speed | 0.15 s | 0.20 s | Alternating the two buttons chains a little slower |

Backdash speed (270) was left as it was. Two values in the user's message differ from the
saved file: attack length (message 0.35, file 0.40) and backdash safety (message 0.15, file
0.14). The saved file is kept until the user says otherwise.

**What changes**

| # | Change | Status |
|---|---|---|
| 1 | Sounds: several options per sound, chosen by ear in the F1 panel; no voices for getting hit; softer hits; softer backdash; other music options | in progress |
| 2 | Every prototype gets tuning sliders that save to a file (rule: `.agents/rules/prototype-code.md`) | done |

## Prototype v3 stage 1, sounds — played 2026-11-16 — verdict: sounds chosen by the user

The user picked sounds by ear in the F1 panel and saved. Their choices are in
`prototypes/feel-v3/assets/audio/events.json`. The clear pattern: **everything much quieter.**

| Moment | The user's choice | Loudness |
|---|---|---|
| Footstep | kept | much quieter (-12 to -22) |
| Jump | kept | much quieter (-6 to -21) |
| Landing | kept | much quieter (-6 to -24) |
| Attack swing | changed to "attack swish" | a little quieter (-6 to -9) |
| Hit connects | changed to "shock hit" | much quieter (-10 to -19) |
| She gets hit | changed to "shock sting" (not a voice) | much quieter (-6 to -22) |
| Enemy dies | kept | a little quieter (-6 to -9) |
| Backdash | kept the soft whoosh | quieter (-6 to -12) |
| Door | kept | quieter (-6 to -15) |
| Music | changed to "cyberpunk city 2" | quieter (-8 to -15) |

Rule for later sounds: start quiet (around -18 for small sounds, -15 for music) and let the
user raise them.

## New direction from the user — 2026-11-16 (after stage 1)

In the user's words, tidied:

1. **Concept only.** "The sprites and stuff inside design, they are not ready to use in game,
   they are merely concept." Everything in the game is either redrawn, or reused from the
   asset packs we own and then edited to fit our game.
2. **Ask for concept art.** "The current concept art is not enough, there should be much more,
   I just need to be asked for it." Agents must ask the user what they want to see before
   drawing or choosing art.
3. **Redraw the sprites and edit the levels** to fit the theme of the game and the concept art.
4. **The protagonist is Pandora-001.**
5. **Crouch, and a crouch attack.**
6. **The two attacks look different**: the `J` attack and the chained `I` attack each get
   their own animation.
7. **Three bars**: HP (hit points); Energy, spent by attacks and backdashes, like in
   Castlevania: Order of Ecclesia; MP, spent by special attacks such as Up + Attack, like
   hearts in Order of Ecclesia.
8. **Every prototype gets the tuning sliders**, in OpenCode too.

## Stages (revised 2026-11-16)

| Stage | What you get to play | Status |
|---|---|---|
| 1 The body | Movement, jump, backdash, attack, two enemies, two rooms, sounds | done (approved) |
| 1b The full body | Crouch and crouch attack; two different attack animations; HP, Energy and MP bars; one special attack on Up + Attack; all with sliders | done (approved 2026-11-16) |
| Weapons and hands | J and I are her right and left hand, one weapon each; two-handed weapons; the fast two-hit combo; Pandora-001 redrawn with weapons | in progress (plan agreed 2026-11-16) |
| Art direction | The user is asked what the game should look like (hero, enemies, places, mood); then Pandora-001 and the rooms are redrawn or re-edited from our packs to match | done (the user's answers are recorded below) |
| 2 The place | Four or five connected rooms with doors, demons and machines | planned |
| 3 The boss | Arnetria rebuilt; counter as an optional bonus | planned |
| 4 Write it down | The approved numbers go into the design documents, in plain words | planned |

## Prototype v3 stage 1b — played 2026-11-16 — verdict: approved (all five good)

What was built, for the user to judge by playing. Every value below has a slider in the F1 panel.

| What | How it works now | Starting value |
|---|---|---|
| Crouch | Hold Down: she ducks and cannot be hit as high | 22 tall (standing is 36) |
| Crouch attack | Attack while crouching: a low swing | same damage and length as a normal swing |
| Two attack looks | `J` is a blue cut, `I` is a pink cut that runs the other way | stand-in art, edited from the pack |
| Energy bar | Attacks and backdashes spend it; it refills after a short rest | 100; attack 12, backdash 10; refills in about 2 seconds |
| MP bar | Only the special spends it; blue orbs from defeated enemies refill it | 60; special 15 (4 uses); orb gives 8, drops about 6 times in 10 |
| Special (Up + Attack) | A blade wave flies forward and cuts through enemies | damage 30 (one hit kills a hound), flies 150 px |
| New sounds | Special, orb pickup, "no energy" click: three options each in the SOUNDS page | quiet (-18) |

Also fixed from the review of stage 1: a tap pressed just before landing is now a short hop; an
attack pressed together with a jump keeps air steering; the hound no longer jitters against a
wall; two enemies hit by one swing both take the hit; dying inside a door no longer starts two
fades; Reset also restores the sound choices; the remaining enemy and jump timings have sliders.

**What the user said after playing (2026-11-16)**

- "I noticed a problem where the character faces the opposite side when crouching." Fixed: the
  crouch picture is now made from the standing pose, which faces forward. Status: done.
- The verdict, asked point by point on 2026-11-16: the crouch "Good, keep it"; the low attack
  "Good, keep it"; the two attack looks "Good, keep both"; the three bars "Good, keep them";
  the special "Good, keep it". All five are approved; nothing was asked to change.

**The values the user saved with the F1 panel**

| Setting | Before | Saved | What it means |
|---|---|---|---|
| Hit pause | 0.05 s | 0.03 s | The tiny freeze when a hit lands is shorter |
| Screen shake | 2 | 1 | The screen shakes half as much on a hit |
| Footstep / jump / landing | -22 / -21 / -24 | -4 / -3 / -3 | Much louder |
| Attack swing / hit connects | -9 / -19 | -4 / -4 | Louder |
| She gets hit | -22 | -3 | Much louder |
| Enemy dies / backdash / door | -9 / -12 / -15 | -1 / -1 / -1 | Louder |
| Special attack | "magic shot", -18 | "magic charge", 0 | Different sound, much louder |
| Orb pickup | "coin chime", -18 | "bright blip", -4 | Different sound, louder |
| No energy | "dull click", -18 | "soft denied", +5 | Different sound, much louder |
| Music | -15 | +2 | Much louder |

Every sound went up by about 10 to 20. We asked the user: were the sounds too quiet, or were
the speakers turned down? Their answer on 2026-11-16: "Sounds were too quiet." So the earlier
rule (start quiet, around -18) is dropped. Rule for later sounds: start at about the loudness
the user saved (small sounds around -4 to 0, music around +2) and let them tune from there.

## Art direction — the user's answers, 2026-11-16

In the user's words, tidied. This is the brief for every redraw.

1. **Pandora-001**: the concept is exactly her in the game (silver-white ponytail, black armoured
   suit with cyan lines, torn black scarf, cyan eyes). She poses like the main character of
   Castlevania: Order of Ecclesia.
2. **Weapons and hands**: `J` and `I` are her two hands. She can hold one weapon in each hand, as
   in Order of Ecclesia.
   - Dirge-042 is her short sword and her starting weapon. It can be held in both hands.
   - Elegy and Lament are two-handed: nothing else can be held with them. `J` and `I` are two
     different swings, and chaining them makes a two-hit combo.
   - The same weapon in both hands: `J` and `I` are two different swings, and chaining them makes
     a fast two-hit combo (two Dirges: one hand, then the other).
   - More weapons come later, including ranged ones (a pistol, or a boomerang-like weapon). Two
     pistols chained with `J` and `I` should look like stylish two-gun gunslinging.
3. **Enemies**: the future leans to colder colours and metal (dominant, with other colours too);
   the past leans to warmer colours and flesh. Cyborgs of the past look steampunk; cyborgs of the
   future look cyberpunk. All enemies look scary; even sad ones are eerie, with unique, searing
   names and attributes. Liked references, past: Order of Ecclesia, Symphony of the Night, Devil
   May Cry. Future: Metroid, Metal Gear Solid, Cyberpunk, Pragmata. The user's own addition: a
   demonic feel in the cyber future.
4. **Places**: the user did not like the test rooms. Places are eerie and scary but iconic, in the
   future and in the past. Not depressing, except the depression stage, much later in the game.
5. **Concept pictures that are right**: Lenore (the original past version); Pandora (all
   versions); Dirge-042; the Demon Lord (fits the past); Arnetria (denial, the first main boss);
   Amythia (the depression boss). Everything else is unsure and may be redrawn.

What this changes: the stage 1b "J blue cut, I pink cut" becomes "right hand, left hand" with a
weapon per hand. That is a new stage of work (weapons and hands), agreed with the user before
stage 2. Status: agreed (see below).

## Weapons and hands — the plan agreed with the user, 2026-11-16

The user's answers to the four plan questions, in their words, tidied:

1. **One Dirge, equipped in both hands.** The user's exact answer: "One dirge, but can be
   equipped twice; meaning that when she attacks with her right hand, the weapon materializes
   as she attacks with her right hand and then dematerializes; same thing when she attacks with
   her left hand. So she can equip it in both hands, attacking with either hand using the
   weapon, but she is not holding two weapons at the same time, but rather chaining attacks and
   swapping between right and left hand using the same weapon, similar to Castlevania Order of
   Ecclesia."
2. **Elegy first.** Of the two two-handed weapons, Elegy-013 is built first (the design book
   already holds its swing numbers); Lament comes after.
3. **Two-handed feel: yes, slower but stronger**, with a longer reach; one swing hits harder
   than one short-sword swing.
4. **Pandora-001 is redrawn now**, from her concept art, holding the weapons, with the paid
   generation tool; the user's yes covers this redraw. Poses like the Order of Ecclesia heroine.
