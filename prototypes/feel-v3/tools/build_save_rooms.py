"""Builds the two save-room pictures from the user's reference paintings.

  python tools/build_save_rooms.py

Each room is 448 x 216 (a little wider than one screen). Both keep the same three
things in the same order: capsules on the left, the brain cache station in the
middle, the terminal on the right. The left capsule holds a sleeping body; the
one next to it is EMPTY - that is where a new Pandora is rebuilt.

  env/save_room.png   cache station 002: from save-room-v2.jpg, cold teal
  env/save_room2.png  cache station 003 (before the boss): the SAME painting
                      (save-room-v2.jpg) under a violet filter, amber warning lamps
"""
import os
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "..", "assets")
REF = os.path.join(A, "references")
CUT0, CUT1 = 54, 118     # the slice of the painting that holds the capsule
EXTRA = CUT1 - CUT0
W, H = 384 + EXTRA, 216
GLASS = (65, 71, 109, 174)   # the glass of the capsule in the 384 x 216 painting


def base(name):
    """The painting without its black side bars, at game size (384 x 216)."""
    im = Image.open(os.path.join(REF, name)).convert("RGB")
    a = np.array(im).astype(int).sum(axis=2)
    cols = np.where(a.mean(axis=0) > 30)[0]
    x0, x1 = cols.min(), cols.max() + 1
    w = x1 - x0
    h = round(w * 216 / 384)
    y0 = min((im.height - h) // 2 + 20, im.height - h)
    return im.crop((x0, y0, x1, y0 + h)).resize((384, 216), Image.BOX)


def empty_glass(im, box):
    """Paints the body out of a capsule: plain glowing liquid with a few bubbles."""
    x0, y0, x1, y1 = box
    a = np.array(im).astype(float)
    # the liquid colour, row by row, taken from the two edge columns of the glass
    for y in range(y0, y1):
        left = a[y, x0:x0 + 3].mean(axis=0)
        right = a[y, x1 - 3:x1].mean(axis=0)
        for x in range(x0 + 2, x1 - 2):
            t = (x - x0) / max(1, x1 - x0 - 1)
            edge = left * (1 - t) + right * t
            mid = 1.0 - abs(t - 0.5) * 0.5          # a little brighter in the middle
            a[y, x] = np.clip(edge * mid * 0.92, 0, 255)
    out = Image.fromarray(a.astype("uint8"), "RGB")
    d = ImageDraw.Draw(out)
    rng = np.random.default_rng(7)
    for _ in range(9):
        bx = int(rng.integers(x0 + 5, x1 - 5))
        by = int(rng.integers(y0 + 6, y1 - 6))
        d.point((bx, by), fill=(215, 255, 255))
        d.point((bx, by - 3), fill=(150, 235, 240))
    # the empty cradle: two thin clamps where a body would hang
    cx = (x0 + x1) // 2
    for yy in (y0 + (y1 - y0) // 3, y0 + 2 * (y1 - y0) // 3):
        d.line((cx - 7, yy, cx - 3, yy), fill=(30, 70, 80))
        d.line((cx + 3, yy, cx + 7, yy), fill=(30, 70, 80))
    return out


def widen(im):
    """Repeats the slice of the painting that holds the capsule, so there are two."""
    out = Image.new("RGB", (W, H))
    out.paste(im.crop((0, 0, CUT1, H)), (0, 0))
    out.paste(im.crop((CUT0, 0, 384, H)), (CUT1, 0))
    return out


def tint(im, mult, lift=(0, 0, 0)):
    a = np.array(im).astype(float)
    a = a * np.array(mult) + np.array(lift)
    return Image.fromarray(np.clip(a, 0, 255).astype("uint8"), "RGB")


def finish(im, name, colours):
    im = im.quantize(colours, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    im.save(os.path.join(A, "env", name))
    print(name, im.size)


def room(ref, name, look):
    im = base(ref)
    wide = widen(im)
    # the second capsule (the one nearer the cache station) is the empty one
    shifted = (GLASS[0] + EXTRA, GLASS[1], GLASS[2] + EXTRA, GLASS[3])
    wide = empty_glass(wide, shifted)
    if look == "violet":
        # same room, other light: violet glass and stone, amber warning lamps
        a = np.array(wide).astype(float)
        r, g, b = a[..., 0].copy(), a[..., 1].copy(), a[..., 2].copy()
        a[..., 0] = np.clip(r * 0.7 + b * 0.55, 0, 255)
        a[..., 1] = np.clip(g * 0.72, 0, 255)
        a[..., 2] = np.clip(b * 1.05 + 8, 0, 255)
        wide = Image.fromarray(a.astype("uint8"), "RGB")
        d = ImageDraw.Draw(wide)
        for lx in (20, 122, 236, 340, 430):
            d.rectangle((lx, 6, lx + 3, 8), fill=(255, 170, 50))
            d.point((lx + 1, 9), fill=(160, 90, 20))
        d.rectangle((0, 205, W, 206), fill=(120, 70, 20))
        for sx in range(0, W, 12):
            d.line((sx, 207, sx + 5, 207), fill=(255, 180, 60))
    finish(wide, name, 44)
    print("  empty capsule centre x =", (shifted[0] + shifted[2]) // 2, "glass", shifted)


if __name__ == "__main__":
    room("save-room-v2.jpg", "save_room.png", "teal")
    # user 2026-11-17: the second room is the first room's picture under a violet filter
    room("save-room-v2.jpg", "save_room2.png", "violet")
