# PROTOTYPE - NOT FOR PRODUCTION
"""Palette proof (sprites.md 5b): her hand-on-hip idle frame recoloured in palettes A, B and C.

Role map: each colour of the source GIF frame is given a role (outline, skin, hair, suit),
using hand-placed boxes for face/skin and hair, then mapped to that role's tone in each
candidate palette. No cleanup yet (dither noise stays); this is only for picking colours.

usage: python -I tools/palette_proof.py <out_dir>   (run from prototypes/feel-v3)
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

SRC = "assets/sprites-pandora/sprite-sheet-pandora-5.gif"
FRAME = 40                      # inside the hand-on-hip hold (g5 022-065)
CROP = (79, 0, 155, 135)        # the figure's box in the 240 x 135 frame

PALETTES = {
    "A  ASH AND TEAL": ["0a0d12", "6b4a52", "b88a80", "e8c3b0", "56707c", "9db8c2", "dff0f0", "0f2328",
                        "1b4a52", "2d7b80", "1fc9c0", "9ffff0", "3b4252", "8e9aae", "c8903a", "fdfdf6"],
    "B  OXBLOOD AND BONE": ["120a0c", "6d3f3a", "b97e66", "ecc7a4", "8a6a3c", "cfa65e", "f3dc9a", "2a0f16",
                            "5c1d2a", "9a3342", "e8a02e", "ffe08a", "3a3436", "9a9088", "3fa7a0", "fff8e8"],
    "C  TWILIGHT VIOLET": ["0c0a14", "5e4254", "a97a78", "e0b9a6", "5b4a8c", "9a86d1", "d9ccf5", "17142e",
                           "2c2a5c", "4a4d94", "ff5fa2", "ffc2dd", "36344a", "8a8aa8", "e6b14a", "fbf8ff"],
}
ROLE_NAMES = ["outline", "skin shade", "skin base", "skin light", "hair shade", "hair base", "hair light",
              "suit shade", "suit base", "suit light", "glow", "glow bright", "steel dark", "steel light",
              "accent", "highlight"]

# source colour -> (role outside hair, role inside hair, role inside a skin box); roles are 1-based
OUTLINE = {(18, 18, 21), (39, 34, 31)}
MAP = {
    (21, 29, 26): (8, 8, 8),
    (43, 69, 78): (9, 9, 9),
    (49, 78, 63): (9, 9, 9),
    (58, 112, 141): (9, 5, 9),
    (105, 159, 172): (10, 6, 10),
    (79, 91, 66): (9, 5, 9),
    (80, 86, 60): (9, 5, 9),
    (153, 158, 135): (9, 6, 6),
    (244, 216, 147): (4, 7, 4),
    (237, 230, 203): (7, 7, 4),
    (231, 178, 112): (3, 6, 3),
    (180, 145, 98): (2, 5, 2),
}
SKIN = [(39, 13, 49, 28), (25, 34, 41, 41), (43, 29, 60, 45), (39, 54, 47, 61)]   # face, chest, shoulder, hand
HAIR = [(18, 0, 56, 33), (16, 25, 30, 52), (56, 38, 70, 64)]


def _in(boxes, x, y):
    return any(x0 <= x <= x1 and y0 <= y <= y1 for x0, y0, x1, y1 in boxes)


def _rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def source_frame():
    im = Image.open(SRC)
    im.seek(FRAME)
    return im.convert("RGB").crop(CROP)


def role_image(src):
    """2D list of roles (0 = see-through)."""
    w, h = src.size
    roles = [[0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            c = src.getpixel((x, y))
            if c == (0, 0, 0):
                continue
            if c in OUTLINE:
                roles[y][x] = 1
                continue
            out, hair, skin = MAP[c]
            roles[y][x] = skin if _in(SKIN, x, y) else (hair if _in(HAIR, x, y) else out)
    return roles


def paint(roles, pal):
    h, w = len(roles), len(roles[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cols = [_rgb(p) for p in pal]
    for y in range(h):
        for x in range(w):
            r = roles[y][x]
            if r:
                im.putpixel((x, y), cols[r - 1] + (255,))
    return im


def original(src):
    im = Image.new("RGBA", src.size, (0, 0, 0, 0))
    for y in range(src.height):
        for x in range(src.width):
            c = src.getpixel((x, y))
            if c != (0, 0, 0):
                im.putpixel((x, y), c + (255,))
    return im


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    src = source_frame()
    roles = role_image(src)
    figs = [("today", original(src))] + [(k, paint(roles, v)) for k, v in PALETTES.items()]

    # 1. close-up at 4x on a neutral dark ground, with swatches under A/B/C
    S, cw, ch = 4, 76 * 4 + 40, 135 * 4 + 150
    close = Image.new("RGB", (cw * len(figs), ch), (28, 28, 32))
    d = ImageDraw.Draw(close)
    for i, (name, fig) in enumerate(figs):
        close.paste(fig.resize((76 * S, 135 * S), Image.NEAREST), (i * cw + 20, 30), fig.resize((76 * S, 135 * S), Image.NEAREST))
        d.text((i * cw + 20, 8), name, fill=(235, 235, 235))
        if name in PALETTES:
            for j, hx in enumerate(PALETTES[name]):
                x0, y0 = i * cw + 20 + (j % 8) * 38, 135 * S + 50 + (j // 8) * 48
                d.rectangle([x0, y0, x0 + 34, y0 + 34], fill=_rgb(hx), outline=(90, 90, 90))
    close.save(out / "palette_closeup_4x.png")

    # 2. game size: her at about 90 px (2/3 once) over each room at 2x, today / A / B / C side by side
    rooms = [("church", "shots/1_church_start.png", (100, 88, 215, 205)),
             ("library", "shots/10_library_1.png", (100, 85, 215, 202)),
             ("lab", "shots/14_lab_1.png", (110, 98, 225, 215))]
    small = [(n, f.resize((51, 90), Image.NEAREST)) for n, f in figs]
    cell_w = 115 * 2
    game = Image.new("RGB", (cell_w * len(small), 117 * 2 * len(rooms)), (0, 0, 0))
    for r, (_, path, box) in enumerate(rooms):
        bg = Image.open(path).convert("RGB").crop(box).resize((cell_w, 117 * 2), Image.NEAREST)
        for i, (_, fig) in enumerate(small):
            cell = bg.copy()
            cell.paste(fig, ((cell_w - 51) // 2, 117 * 2 - 90 - 14), fig)
            game.paste(cell, (i * cell_w, r * 117 * 2))
    game = game.resize((game.width * 2, game.height * 2), Image.NEAREST)
    d = ImageDraw.Draw(game)
    for i, (name, _) in enumerate(small):
        d.text((i * cell_w * 2 + 8, 6), name, fill=(255, 255, 255))
    game.save(out / "palette_game_size.png")
    print("wrote", out / "palette_closeup_4x.png", out / "palette_game_size.png")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "art_proof/palette")
