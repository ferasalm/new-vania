"""Builds the save point and the save-room back wall from the user's kit sheet.

  python tools/build_save_point.py

The save point is an OBJECT that stands inside an ordinary room (user, 2026-11-17):
from left to right the full capsule, the EMPTY capsule (a new Pandora is rebuilt in it),
the brain cradle and the terminal. They are cut from
assets/references/Save room/assets.jpg (props on a magenta background) and shrunk to
1/8, so a capsule stands a little taller than Pandora (about 60 px against her 46).

  env/save_point.png   the four props on one floor line (teal)
  env/save_point2.png  the same under the violet filter (cache station 003)
  env/save_wall.png    the kit's background strip, dimmed, as the room's back wall
  env/save_wall2.png   the same, violet
The script prints where the empty capsule and the terminal stand inside save_point.png;
room.gd draws the picture so the empty capsule stands on the room's K.
"""
import os
import numpy as np
from scipy import ndimage
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "..", "assets")
KIT = os.path.join(A, "references", "Save room", "assets.jpg")
SCALE = 8
GAP = 3
# boxes in the kit sheet (2752 x 1536): left, top, right, bottom
PROPS = [
    ("full", (36, 1020, 254, 1504)),
    ("empty", (296, 1020, 494, 1504)),
    ("cradle", (1250, 516, 1504, 994)),
    ("terminal", (2136, 646, 2414, 990)),
]
# the painted backdrop behind the cradle and the terminal in the kit, cut away by hand
ERASE = {
    "cradle": [(1250, 516, 1290, 880), (1462, 516, 1504, 880)],
    "terminal": [(2136, 646, 2186, 800)],
}
BACK = (1094, 1068, 2728, 1512)


def magenta(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    return (np.minimum(r, b) - g) > 60


def cut(im, box, erase=()):
    """One prop, magenta removed, shrunk to 1/SCALE with a hard edge."""
    a = np.array(im.crop(box)).astype(float)
    for x0, y0, x1, y1 in erase:
        a[y0 - box[1]:y1 - box[1], x0 - box[0]:x1 - box[0]] = (255, 0, 255)
    # only the background magenta (and its haze) that reaches the edge of the box goes;
    # the purple glow inside the cradle's glass stays
    bg = (np.minimum(a[..., 0], a[..., 2]) - a[..., 1]) > 35
    lab, _ = ndimage.label(bg)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    alpha = (~np.isin(lab, list(edge))).astype(float)
    alpha = ndimage.binary_opening(alpha > 0, iterations=2).astype(float)
    h, w = a.shape[0] // SCALE * SCALE, a.shape[1] // SCALE * SCALE
    a, alpha = a[:h, :w], alpha[:h, :w]
    pre = a * alpha[..., None]
    blk = lambda x: x.reshape(h // SCALE, SCALE, w // SCALE, SCALE, *x.shape[2:]).sum(axis=(1, 3))
    cov = blk(alpha)
    col = blk(pre) / np.maximum(cov, 1)[..., None]
    cov = cov / (SCALE * SCALE)
    out = np.zeros((h // SCALE, w // SCALE, 4))
    out[..., :3] = col
    out[..., 3] = np.where(cov >= 0.5, 255, 0)
    # take the magenta glow out of the edge colours
    spill = np.minimum(out[..., 0], out[..., 2]) - out[..., 1]
    m = spill > 20
    out[m, 0] -= (spill[m] - 20) * 0.8
    out[m, 2] -= (spill[m] - 20) * 0.8
    # trim empty rows and columns
    ys, xs = np.where(out[..., 3] > 0)
    out = out[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return np.clip(out, 0, 255)


def violet(a):
    a = a.copy()
    r, g, b = a[..., 0].copy(), a[..., 1].copy(), a[..., 2].copy()
    a[..., 0] = np.clip(r * 0.7 + b * 0.55, 0, 255)
    a[..., 1] = np.clip(g * 0.72, 0, 255)
    a[..., 2] = np.clip(b * 1.05 + 8, 0, 255)
    return a


def save(a, name, colours):
    im = Image.fromarray(a.astype("uint8"), "RGBA" if a.shape[2] == 4 else "RGB")
    if im.mode == "RGBA":
        rgb = im.convert("RGB").quantize(colours, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
        rgb.putalpha(im.getchannel("A"))
        im = rgb
    else:
        im = im.quantize(colours, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    im.save(os.path.join(A, "env", name))
    print(name, im.size)


def main():
    kit = Image.open(KIT).convert("RGB")
    parts = [(n, cut(kit, b, ERASE.get(n, ()))) for n, b in PROPS]
    W = sum(p.shape[1] for _, p in parts) + GAP * (len(parts) - 1)
    H = max(p.shape[0] for _, p in parts)
    group = np.zeros((H, W, 4))
    x = 0
    where = {}
    for n, p in parts:
        h, w = p.shape[:2]
        sub = group[H - h:, x:x + w]
        m = p[..., 3] > 0
        sub[m] = p[m]
        where[n] = x + w // 2
        x += w + GAP
    save(group, "save_point.png", 48)
    g2 = group.copy()
    g2[..., :3] = violet(group[..., :3])
    save(g2, "save_point2.png", 48)
    print("save_point: width %d height %d; centre x of empty capsule %d, terminal %d, cradle %d" % (
        W, H, where["empty"], where["terminal"], where["cradle"]))
    # the back wall: the kit's background strip, room height, dimmed so the props read
    back = kit.crop(BACK)
    h = 200
    back = back.resize((round(back.width * h / back.height), h), Image.BOX)
    b = np.array(back).astype(float) * 0.62
    save(b, "save_wall.png", 40)
    save(violet(b), "save_wall2.png", 40)


if __name__ == "__main__":
    main()
