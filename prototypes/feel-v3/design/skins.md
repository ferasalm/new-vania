# Pandora's skins (user decision, 2026-11-19)

## The two skins
| | Skin A: ASH AND TEAL (main) | Skin B: OXBLOOD (optional) |
|---|---|---|
| Palette file | `assets/palettes/pandora.gpl` (+ `pandora.png` strip) | `assets/palettes/pandora_b.gpl` (+ `pandora_b.png`) |
| Hair | silver-cyan | ash-blonde |
| Suit | black-teal | oxblood |
| Eyes, suit seams | glow **cyan** (`#38d8f8`, bright `#bffcff`) | glow **red** (`#ff3b4e`, bright `#ffb8c0`) |
| Weapon strikes, dash trails | cyan | red, the same red as her seams |

Both palettes have the same 16 slots in the same order (outline, skin x3, hair x3, suit x3, glow x2, steel x2,
accent, highlight). Slot 11 and 12 are the glow: eyes, the seam lines on her suit, and nothing else on her body.

## Rule: draw in A only, bake B
1. Every new Pandora sprite is drawn and cleaned in palette A only (sprites.md 5 and 5b checks apply).
2. Check it: `python -I tools/pandora_skins.py check <frames dir>` must print `check: OK`
   (any colour outside palette A fails; fix the frame, never the tool).
3. Bake skin B: `python -I tools/pandora_skins.py bake <frames dir> --out <same dir>_b`
   (for example `assets/2x/pandora/jump_*.png` -> `assets/2x/pandora_b/`). Colour i of A becomes colour i of B;
   see-through stays see-through. Nothing is redrawn and nothing is guessed.
4. Look at A and B side by side at game speed (the contact sheet and GIF of sprites.md 5 show both).
5. Commit the A frames and the baked B frames together.

If a new move needs a colour that is not in the palette, the palette changes first (both files, same slot),
then every frame is re-checked. Never add a 17th colour to one skin only.

## In the game
- Tuning key `pandora_skin`: 0 = A (default), 1 = B. The pause menu gets the switch with S3 (session 2).
- The code colours of her strikes and dash come from `Vfx.her_glow()` / `Vfx.her_glow_alt()`, which follow the skin.
- Her frames load from `assets/2x/pandora/` (A) or `assets/2x/pandora_b/` (B) once new frames are wired.

## Enemies and bosses
They have one look each (their own palettes, sprites.md 5b). Skins are Pandora's only.
