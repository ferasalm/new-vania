"""Builds Pandora-001 from the Order of Ecclesia heroine sheet the user supplied.

  python tools/build_pandora.py <path to the Shanoa sheet PNG>

1. Recolours the WHOLE sheet by colour role (hair -> silver-white, dress -> near-black
   suit, trim -> cyan lines, lining -> dark teal scarf) and writes the complete Pandora
   sheet to assets/hero/pandora_sheet.png (same layout as the source sheet).
2. Cuts the game's animations out of it into assets/hero/<anim>_NN.png on one canvas
   size with her feet on one fixed point, and records them in assets/frames.json.

The poses are traced from a commercial game's sprites: placeholder art for a private
prototype only. The outputs are git-ignored and must be redrawn before anything ships.
"""
import json, os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from shanoa_cells import cells

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "hero")
CANVAS = (112, 80)
FEET = (56, 76)

SKIN_HI, SKIN_MID = (248, 232, 216), (208, 168, 88)
ROLE = {
    (0, 0, 0): (9, 10, 16),
    (40, 24, 48): (22, 24, 36),
    (48, 32, 80): (17, 19, 29),
    (80, 48, 48): (98, 106, 134),      # hair shadow
    (120, 80, 64): (166, 174, 196),    # hair
    (144, 104, 64): (228, 232, 242),   # hair light
    (56, 40, 192): (38, 44, 62),       # suit
    (48, 40, 120): (25, 29, 42),       # suit dark
    (88, 88, 216): (70, 206, 228),     # cyan lines
    (144, 136, 168): (150, 162, 188),
    (128, 48, 24): (16, 50, 62),       # scarf lining
    (168, 80, 8): (26, 96, 112),
    (176, 8, 24): (96, 232, 246),
}
FACE = {SKIN_HI: (242, 228, 218), SKIN_MID: (204, 164, 150)}
BODY = {SKIN_HI: (140, 236, 248), SKIN_MID: (62, 74, 100)}   # armour plate + cyan glint

# animation -> list of "row.col" cells on the sheet, and how to place them
#   feet: bottom of the sprite on the floor, x from the middle of her feet
#   grid: x from the sheet's own 96 px cells (keeps a run cycle steady)
#   air : like grid, but the sprite's middle sits at chest height
ANIMS = {
    "idle": ("feet", ["1.0", "1.1", "1.2", "1.3", "1.4", "1.5"]),
    "run": ("grid", ["43.5", "43.6", "44.0", "44.1", "44.2", "44.3", "44.4", "44.5",
                     "45.0", "45.1", "45.2", "45.3", "45.4", "45.5", "46.0", "46.1"]),
    "jump": ("air", ["5.2", "9.0", "9.2", "9.3"]),
    "land": ("feet", ["9.4"]),
    "crouch": ("feet", ["10.3", "10.6", "11.0", "11.1", "11.2"]),
    "attack": ("feet", ["11.4", "12.3", "12.4", "13.0", "13.4"]),
    "attack2": ("feet", ["14.1", "14.2", "14.3", "15.1", "15.3"]),
    "crouchatk": ("feet", ["16.2", "16.6", "16.7", "17.0", "17.2"]),
    "crouchatk2": ("feet", ["17.8", "18.0", "18.2", "18.4", "19.0"]),
    "airatk": ("air", ["19.3", "20.1", "20.2", "20.4", "21.2"]),
    "airatk2": ("air", ["21.5", "22.0", "22.2", "22.4", "23.1"]),
    "backdash": ("feet", ["49.3", "50.0", "50.3", "50.5"]),
    "hurt": ("feet", ["4.0", "4.1"]),
    "cast": ("feet", ["25.3", "25.5", "26.0", "26.1", "26.3"]),
    "dead": ("feet", ["41.4", "41.7", "42.1", "42.4"]),
}


def recolour(a, fg):
    out = a.copy()
    rgb = a[..., :3]
    for src, dst in ROLE.items():
        m = fg & (rgb == src).all(axis=-1)
        out[m, :3] = dst
    return out


def paint_skin(src, out, fg, box):
    """Her face keeps its skin; skin anywhere else becomes armour (she wears a full suit)."""
    x0, y0, x1, y1 = box
    rgb = src[y0:y1, x0:x1, :3]
    m = fg[y0:y1, x0:x1]
    skin = m & ((rgb == SKIN_HI).all(-1) | (rgb == SKIN_MID).all(-1))
    if not skin.any():
        return None
    hair = m & ((rgb == (80, 48, 48)).all(-1) | (rgb == (120, 80, 64)).all(-1) | (rgb == (144, 104, 64)).all(-1))
    ys, xs = np.where(skin)
    # the face is the skin that touches the most hair: score each skin blob row-band
    best, best_score = None, -1
    for y in sorted(set(ys)):
        band = (ys >= y) & (ys < y + 8)
        bx = xs[band]
        cx = int(bx.mean())
        win = hair[max(0, y - 5):y + 12, max(0, cx - 9):cx + 10].sum() - 0.4 * (y - ys.min())
        if win > best_score:
            best, best_score = (y, cx), win
    fy, fx = best
    sub = out[y0:y1, x0:x1]
    for y, x in zip(ys, xs):
        key = tuple(int(v) for v in rgb[y, x])
        face = fy - 1 <= y < fy + 8 and abs(x - fx) <= 6
        sub[y, x, :3] = (FACE if face else BODY)[key]
    return (x0 + fx, y0 + fy)


def main():
    im, fg, rows = cells(sys.argv[1])
    src = np.array(im)
    out = recolour(src, fg)
    faces = {}
    for r in rows:
        for b in r:
            faces[b] = paint_skin(src, out, fg, b)
    out[~fg] = (0, 0, 0, 0)
    out[fg, 3] = 255
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    sheet = Image.fromarray(out)
    sheet.save(os.path.join(OUT, "pandora_sheet.png"))
    meta = {}
    for anim, (mode, ids) in ANIMS.items():
        boxes = []
        for i in ids:
            r, c = i.split(".")
            boxes.append(rows[int(r)][int(c)])
        for n, b in enumerate(boxes):
            spr = sheet.crop(b)
            w, h = spr.size
            if mode == "feet":
                al = np.array(spr)[..., 3] > 0
                xs = np.where(al[-3:].any(axis=0))[0]
                ax = (xs.min() + xs.max()) // 2
                px, py = FEET[0] - ax, FEET[1] - h
            elif mode == "air":
                # hang the body from her face, so the head stays put while the legs move
                fx, fy = faces[b]
                px, py = FEET[0] + 3 - (fx - b[0]), FEET[1] - 44 - (fy - b[1])
            else:
                cell = (b[0] + b[2]) // 2 // 96 * 96
                px = FEET[0] - 48 + (b[0] - cell)
                row = rows[int(ids[n].split(".")[0])]
                py = FEET[1] - (max(x[3] for x in row) - b[1])
            frame = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
            frame.alpha_composite(spr, (int(px), int(py)))
            frame.save(os.path.join(OUT, f"{anim}_{n:02d}.png"))
        meta[anim] = len(ids)
    fj = os.path.join(HERE, "..", "assets", "frames.json")
    data = json.load(open(fj))
    data["hero"] = {"faces": "right", "anims": meta, "size": list(CANVAS), "feet": list(FEET)}
    json.dump(data, open(fj, "w"))
    print("hero frames:", meta)


if __name__ == "__main__":
    main()
