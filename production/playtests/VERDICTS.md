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
