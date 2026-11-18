# Pandora sprites: the final move list (v2)

## In plain words

- Her main standing pose is your own hand-on-hip turn (`assets/sprites-pandora/sprite-sheet-pandora-5.gif`).
- Every other move gets its own new drawing. No move borrows another move's frames any more.
- How: each old pose from `assets/pandora` is redrawn in her new 16-colour palette and the level of detail (the
  pandora-16-bit pictures show the detail), then each frame is cleaned up pixel by pixel.
- To draw: 134 frames. 89 for her moves (with a new death and a self-repair), 30 for Elegy's own two-handed moves, 15 for the off-hand pistol shots. The cyborg mini-boss SEXTON-19 adds about 65 (`bosses-story.md` 3b).
- First proof: the standing jump (5 frames), made two ways (decision 23): redrawn over the old pose, and posed on your Godot rig. You watch both at game speed and pick the better one before anything else is made.
- Her look becomes TRUE 16-BIT (decision 22): about 16 colours plus see-through, a clean 1 px dark outline, flat 2-3 tone shading, about 90 px tall, in a new palette of her own. In session 1 you pick it from 3 candidates shown on her idle frame; it is saved as `assets/palettes/pandora.gpl` (Aseprite loads it) and a 1 px strip PNG. Your idle, run, slide, crouch and hand-on-hip frames are converted to it and cleaned. New enemies and bosses match this detail level.
- If the AI tool is paid, each generation call needs your yes, with the price shown first.

Status: waiting on user (v3; the user's decisions 15, 22 and 23 of 2026-11-18/19 applied). Design only; no repo file changed.
Contact sheets from the v1 audit stay in this folder's `sheets/`. g1 = `spritesheet pandora.gif` (98 frames),
g4 = `sprite-sheet-pandora-4.gif` (50), g5 = `sprite-sheet-pandora-5.gif` (66). "Old" = `assets/pandora` (the puppet
set: right poses and timing, wrong pixels).

## 2. What the v1 audit found (short)

Only idle, run, slide, crouch and rise come from your drawings. The jump, wall jump and air attacks were run frames
lifted off the ground; ground attacks were slide frames; the wall grab and backdash were crouch frames; one picture was
used for a standing jump, a running jump and a fall; the landing was never shown. That reuse ends with this list.

## 3. Your drawings, wired in (0 to draw)

| Move | Your frames | When it plays |
|---|---|---|
| **Main idle: hand-on-hip turn** | g5 000-065: the turn toward the viewer (about 000-021) plays once when she stops; the hand-on-hip hold (about 022-065) loops | standing still (ranges read from the sheet; confirm at wiring) |
| Ready stance | g4 000-011 | 2 s after an attack or a hit, then the main idle |
| Calm idle (optional) | g1 000-033 | after 10 s standing still, now and then |
| Run | g1 037-047 | running |
| Slide | g1 053-069 (use more of your frames than today's 3) | sliding |
| Crouch | g4 012-021 | crouching |
| Rise | g1 084-095 | standing up after a rebuild at a terminal and after RESTORE HERE |

With Elegy in hand, idle, run, slide, crouch and the jumps keep these frames, with the scythe as its own sprite in the
free hand (it rests in her free hand in the hand-on-hip pose).

## 3b. Your frames, converted to the new palette (decision 22)

Her colours change; her poses, timing, face and costume shapes stay yours. Frames are converted and cleaned, not redrawn.

| Move | Source frames | Frames to convert |
|---|---|---|
| Hand-on-hip turn idle (main idle) | g5 000-065 | 66 |
| Run | g1 037-047 | 11 |
| Slide | g1 053-069 | 17 |
| Crouch | g4 012-021 | 10 |
| **Core total** | | **104** |
| Only if kept (open point 3): ready stance g4 000-011, calm idle g1 000-033, rise g1 084-095 | | 58 |

How, per source sheet: (1) a one-time **role map** says which of your colours are skin, hair, suit, glow, metal or outline; (2) each role is mapped by lightness to the 2-3 tones of that role in the new palette; (3) **clean-up** by hand in Aseprite: a 1 px dark outline, stray pixels gone, flat tones, no gradients or dithering; (4) the frame is made at its final size (about 90 px): a 135 px source is scaled by 2/3 once and then cleaned, never resampled again; (5) the checks of section 5, then a 4x contact sheet and a game-speed GIF, old beside new. You approve the converted idle first (it is the first frame in the palette pick of 5b).

## 4. Frames to draw

| # | Move | Frames | Pose guide (old `assets/pandora`) | Notes |
|---|---|---|---|---|
| 1 | Jump, standing (the proof) | 5 | jump 00-03 + one in-between | load, push-off, rise ×2, top |
| 2 | Jump, moving | 5 | jump, leaned forward | stride push, leap ×2, tuck, top |
| 3 | Fall | 3 | jump 03 | loops; hair and cape flutter |
| 4 | Land | 2 | land | impact, recover |
| 5 | Wall latch | 3 | wall 2 + one | grab, hang ×2 (loop) |
| 6 | Wall jump | 4 | walljump 3 + one | its old frames equal the jump's: make a new guide that twists away from the wall |
| 7 | Ground attack, J | 5 | attack | |
| 8 | Ground attack, I | 5 | attack2 | |
| 9 | Crouch attack, J | 5 | crouchatk | |
| 10 | Crouch attack, I | 5 | crouchatk2 | its old frames 2-4 nearly equal J's: change the guide so they differ |
| 11 | Air attack, J | 5 | airatk | |
| 12 | Air attack, I | 5 | airatk2 | old frame 4 equals J's: change it |
| 13 | Cast (Dirge blade wave) | 5 | cast | |
| 14 | Backdash | 4 | backdash | |
| 15 | Hurt | 3 | hurt 2 + one | hit, stagger, recover; also cancels self-repair |
| 16 | **Death** | 8 | dead 4 as a start | hit, buckle, knees, fall ×2, hit the ground, eye light dims ×2; then SYSTEM OFFLINE |
| 17 | **Self-repair** | 10 | none: a new guide first | start 3 (kneel, open the forearm panel), loop 4 (feeds scrap in, sparks, the panel glows; loops while H is held), end 3 (closes the panel, stands) |
| 18 | Interact (Up) | 3 | none: a new guide | reach out, touch, draw back; levers, terminals, candles, items |
| 19 | Receive (special pickup) | 4 | none: a new guide | raise a hand, the item enters, clutch to the chest, lower |
| | **Her moves, total** | **89** | | |
| 20 | Elegy ground swing, J | 5 | new guide (both hands on the shaft) | wide, heavy arc |
| 21 | Elegy ground swing, I | 5 | new guide | the return swing, low |
| 22 | Elegy crouch sweep (J and I) | 5 | new guide | floor-level sweep |
| 23 | Elegy air spin (J and I) | 5 | new guide | a full turn with the blade |
| 24 | Elegy Requiem (special) | 5 | new guide | |
| 25 | Elegy draw (swap to Elegy) | 5 | new guide | pulls the scythe from her back |
| | **Elegy set, total** | **30** | | |
| 26 | Pistol shot, standing, forward | 3 | new guide (one arm out, Dirge low in the other hand) | raise, fire with flash and recoil, lower; feet planted |
| 27 | Pistol shot, standing, aimed up 45 degrees | 3 | new guide | for flying enemies and ledges |
| 28 | Pistol shot, crouch, forward (low) | 3 | crouch 4 as a start | same three beats, from the crouch |
| 29 | Pistol shot, air, forward | 3 | jump top as a start | momentum kept; the legs stay tucked |
| 30 | Pistol shot, air, aimed up 45 degrees | 3 | new guide | |
| | **Pistol set, total** | **15** | | plus tiny effect sprites, not counted: bolt 1, muzzle flash 2 |
| | **All frames to draw (Pandora)** | **134** | | |

Not planned: a fourth idle, a turn-around move (3), harness looks on her body (each harness would need every frame redrawn), a drawn pistol on the idle and run frames (it is holstered out of sight until she shoots), shooting while running (the shot plants her feet for 0.2 s; slider `pistol_plant`).

Rules for `player.gd` (for the gameplay programmer):
- Attack and cast animations, the Elegy set included, stay at **5 frames**: their speed is `5.0 / _attack_total()`, and
  `_fit_swings` reads the hand and shoulder points on frames 1 and 3 from `frames.json`.
- Standing jump, moving jump, fall and land become separate states in `_animate`.
- The main idle is today's built "front" set (g5): turn once, then loop the hold. The ready stance plays for 2 s after
  fighting.
- New states: self-repair (start, loop, end; a hit goes straight to hurt), death (before the SYSTEM OFFLINE screen),
  interact, receive, Elegy draw, and the five pistol shots (they play only with DIRGE-042 in hand).
- Pistol shots are 3 frames each plus the 0.2 s plant on the ground; they are not attack swings, so `_fit_swings` does not read them. The off-hand muzzle point (for the bolt spawn) is stored per frame in `frames.json`.

## 5. Method (decision 15)

1. **Pose guide.** A script scales each old `assets/pandora` frame up to the GIF size (240 x 135, feet on the ground
   line) and lines it up. Moves with no old pose (self-repair, interact, receive, the Elegy set) get a rough new guide
   first; you see the guides before the AI step.
2. **Redraw** (an image AI, the rig, or by hand: the proof of section 6 decides). Inputs: the guide (pose), the nearest of your GIF frames (palette,
   costume, face), and one pandora-16-bit picture (level of detail only). The tool is your choice (open point 1);
   PixelLab is already scripted in `pandora_sheet/anim_input/pixellab_animate.py`. A paid tool needs your yes for every
   call; we show the price and the batch first.
3. **Pixel cleanup** (this Claude session, in Aseprite and Python): lock to `pandora.gpl` (16 colours, section 5b); a dark 1 px outline;
   remove stray pixels; keep the face, hair and costume identical to your frames; fix the hand and weapon-grip points.
4. **Final size, once.** Build at about 90 px tall on the 224 x 160 canvas (a 135 px source is scaled by 2/3 one time, then cleaned by hand; no later resampling), feet
   at (112, 152). New and old frames then share one level of detail.

Checks, in this order:
1. **Automatic**: height 88-92 px; feet at (112, 152); every colour from `pandora.gpl` (none off the palette); 2-3 flat tones per material, no dithering or gradients; 1 px outline; no
   lone pixels; **no frame matches a frame of another move** (fewer than 8 % of pixels differing = a copy = fail).
2. **Contact sheet at 4x**: one row per frame, guide / new frame / nearest frame of yours, side by side.
3. **At game speed**: an animated GIF at game size next to idle and run, and the move playing in a test build.
4. **Your yes.** Nothing enters `assets/2x/pandora` before you approve it at game speed.

## 5b. True 16-bit rules and her palette (decisions 22 and 23)

**Rules for every Pandora frame** (new enemies and bosses follow the same detail level):
- About 16 colours plus see-through (index 0, not listed in the .gpl), counted over the whole move set. No colour outside the palette.
- A clean 1 px dark outline in the palette's darkest colour. No soft, doubled or anti-aliased edges.
- Flat shading: 2-3 tones per material (shade, base, light), one light from the upper left, no dithering, no gradients, no blur, no mixed pixel sizes.
- About 90 px tall (88-92), feet at (112, 152) on the 224 x 160 canvas.
- **Enemies and bosses**: each has its own palette of at most 16 colours (saved as `assets/palettes/<name>.gpl`), the same darkest outline colour as hers, the same 1 px outline and flat 2-3 tone shading, and sizes in today's proportions to her (trolley about half her height, orderly about 1.2 times, THE UNMUZZLED about 1.4 times, SEXTON-19 about 1.5 times). Their frame counts stay as in `rpg-items.md` 3.6 and `bosses-story.md`; SEXTON-19 needs about 65.

**Palette candidates** (one is picked in session 1; all three keep her readable on the church's ash grey, the red library and the teal lab):

| # | Role | A. ASH AND TEAL (cool, closest to today) | B. OXBLOOD AND BONE (warm) | C. TWILIGHT VIOLET (indigo and lilac) |
|---|---|---|---|---|
| 1 | outline (darkest) | `#0a0d12` | `#120a0c` | `#0c0a14` |
| 2 | skin shade | `#6b4a52` | `#6d3f3a` | `#5e4254` |
| 3 | skin base | `#b88a80` | `#b97e66` | `#a97a78` |
| 4 | skin light | `#e8c3b0` | `#ecc7a4` | `#e0b9a6` |
| 5 | hair shade | `#56707c` | `#8a6a3c` | `#5b4a8c` |
| 6 | hair base | `#9db8c2` | `#cfa65e` | `#9a86d1` |
| 7 | hair light | `#dff0f0` | `#f3dc9a` | `#d9ccf5` |
| 8 | suit shade | `#0f2328` | `#2a0f16` | `#17142e` |
| 9 | suit base | `#1b4a52` | `#5c1d2a` | `#2c2a5c` |
| 10 | suit light | `#2d7b80` | `#9a3342` | `#4a4d94` |
| 11 | glow base (eyes, panels) | `#1fc9c0` | `#e8a02e` | `#ff5fa2` |
| 12 | glow bright | `#9ffff0` | `#ffe08a` | `#ffc2dd` |
| 13 | steel dark | `#3b4252` | `#3a3436` | `#36344a` |
| 14 | steel light | `#8e9aae` | `#9a9088` | `#8a8aa8` |
| 15 | accent (small trim) | `#c8903a brass` | `#3fa7a0 teal` | `#e6b14a gold` |
| 16 | highlight (sparkle) | `#fdfdf6` | `#fff8e8` | `#fbf8ff` |

- A keeps silver-cyan hair and a black-teal suit with one brass accent. It is the safest, but its teal sits close to the lab's cyan glow.
- B is ash-blonde hair, an oxblood suit and amber glow. It is warm and bold, but the oxblood sits close to the red library.
- C is lilac hair, an indigo suit and a magenta-pink glow. **Recommended:** violet is far from all three of the world's colour families (ash grey, library red, lab teal), so she is readable everywhere and unmistakably hers. Your call.

**How you pick (session 1).** We show her idle frame (the hand-on-hip pose) recoloured in each candidate at 4x on three backdrops (church, library, lab), plus the three palettes as swatches. You pick one, or ask for a mix (for example C with A's brass trim). The pick is then saved as:
- `assets/palettes/pandora.gpl`: the 16 colours as GIMP palette text (name, R G B per line, the role names above); Aseprite loads it with Palette > Load Palette.
- `assets/palettes/pandora.png`: a 16 x 1 px PNG strip (one pixel per colour, in the same order) that scripts read for the "no colour off the palette" check.
Nothing else is converted before the pick.

## 6. Proof first, then batches

1. Make only the **standing jump**, 5 frames, **two ways** (decision 23), both in the new palette:
   - **A. Redraw over the old pose.** The old `assets/pandora` jump frames, scaled to 90 px, are the guide; each frame is redrawn (by the AI tool of open point 1, or by hand in Aseprite) in the 16 colours and cleaned pixel by pixel.
   - **B. Pose on your rig.** Open your Godot rig (`assets/hero_2d_base/pandora-16-bit/pandora/rigging_godot`), key its bones for the five poses (crouch-load, push-off, rise, rise, top), render each pose at 90 px on a see-through background, snap it to the palette, then clean pixel by pixel (outline, stray pixels, hair, cape). No money; more hand time. The rig has not been opened in this pass: its first job is to confirm it has the bones for a jump and that its hair and face can match your GIF frames (open point 5).
   - Both follow section 5b. Well-made sprite sheets, from anywhere, may guide **timing and poses only**; no pixel of them enters a frame. The automatic check also compares each new frame with every reference frame used (fewer than 8 % of pixels differing = a copy = fail).
2. Run the checks on A and on B; make one contact sheet, one GIF per version and a test build where she jumps in the church (A and B switchable).
3. You watch A, B and today's jump side by side at game speed and pick the better method (how it reads at speed, weight and timing, outline, match with your idle frames, cost in time and money), or give notes. The winner makes the batches below unless you say otherwise. At most two revision rounds; if it still fails, that move falls back to
   hand redrawing over the guide (by this session, or by you over the Aseprite guide file).
4. Record the real time and cost per frame, then quote the other 129 frames before going on.
5. Batches after the proof, each approved at game speed before the next: B1 moving jump, fall, land (10); B2 wall latch,
   wall jump (7); B3 six attacks and cast (35); B4 backdash, hurt, death (15); B5 self-repair, interact, receive (17);
   B6 Elegy set (30); B7 pistol shots (15). SEXTON-19 and the other new enemies follow at the same detail level, quoted separately. Wiring into the game follows each approved batch.

## Open points (waiting on user)

1. **Which image AI** does the redraw: PixelLab (recommended: it is already scripted; paid, a yes per call) or another tool you name.
2. **The look**: settled by decision 22. Your GIF frames still give her face, costume shapes and poses; her colours become the new 16-colour palette, picked from three candidates in session 1 (section 5b). The pandora-16-bit pictures guide the level of detail.
3. **Extra idles**: keep the ready stance and the calm idle beside the hand-on-hip idle (recommended: they are already
   drawn), or use the hand-on-hip idle only.
4. **Palette**: pick A, B, C or a mix in session 1 (recommended: C, section 5b).
5. **The rig character**: the rig in `pandora-16-bit` is the blonde, ponytailed Pandora, and your GIF frames show silver-cyan hair. For method B to match your frames, the rig's hair and face must be adjusted to your GIF design before posing. Say which design wins if they differ (recommended: your GIF design, since the converted idle, run, slide and crouch come from it).
