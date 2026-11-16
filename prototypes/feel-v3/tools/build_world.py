"""Builds everything that is not the heroine from the reference folder:
weapons (from the concept art), the library / lab / save-room art, the doors,
the boss parts and the extra enemies.

  python tools/build_world.py <references folder> <sandbox assets folder>

Every picture is reduced to a small fixed palette at game size (the 16-bit look),
never used as-is.
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "..", "assets")
REF, SAND = sys.argv[1], sys.argv[2]
LIB = os.path.join(REF, "Metroidvania Library Asset Pack")
LAB = os.path.join(REF, "Scifi lab Files")


def save(im, rel):
    p = os.path.join(A, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.save(p)


def quant(im, n):
    """Fixed small palette, hard-edged alpha."""
    im = im.convert("RGBA")
    a = np.array(im)
    alpha = a[..., 3] >= 128
    q = im.convert("RGB").quantize(n, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGB")
    out = np.dstack([np.array(q), np.where(alpha, 255, 0).astype("uint8")])
    out[~alpha] = 0
    return Image.fromarray(out, "RGBA")


def outline(im, col=(8, 10, 16, 255)):
    im = im.convert("RGBA")
    pad = Image.new("RGBA", (im.width + 2, im.height + 2), (0, 0, 0, 0))
    pad.alpha_composite(im, (1, 1))
    a = np.array(pad)
    solid = a[..., 3] > 0
    grow = solid.copy()
    grow[1:] |= solid[:-1]
    grow[:-1] |= solid[1:]
    grow[:, 1:] |= solid[:, :-1]
    grow[:, :-1] |= solid[:, 1:]
    a[grow & ~solid] = col
    return Image.fromarray(a, "RGBA")


def key_green(im):
    a = np.array(im.convert("RGBA")).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    green = (g > r * 1.35) & (g > b * 1.35) & (g > 90)
    a[green] = 0
    return Image.fromarray(a.astype("uint8"), "RGBA")


# ---------------------------------------------------------------- weapons
def weapon(name, length, rot, n):
    im = key_green(Image.open(os.path.join(REF, name + ".jpg")))
    if rot:
        im = im.rotate(rot, expand=True, resample=Image.BICUBIC)
    im = im.crop(im.getbbox())
    s = length / im.width
    im = im.resize((length, max(1, round(im.height * s))), Image.BOX)
    im = quant(im, n)
    return outline(im.crop(im.getbbox()))


def weapons():
    d = weapon("dirge-042", 38, 0, 10)
    save(d, "weapon/dirge.png")
    e = weapon("elegy-013", 58, -47.5, 12)
    save(e, "weapon/elegy.png")
    return {"dirge": list(d.size), "elegy": list(e.size)}


# ---------------------------------------------------------------- library
def library():
    full = Image.open(os.path.join(LIB, "Full Asset 1.png")).convert("RGBA")

    def cut(box):
        c = full.crop(box)
        return c.crop(c.getbbox())
    storey = cut((95, 95, 356, 290))
    case = cut((780, 25, 1000, 355))
    window = cut((510, 28, 642, 355))
    grad = Image.open(os.path.join(LIB, "spin off", "BG 2", "loop background_1.png")).convert("RGBA")
    # one wall module that repeats in both directions
    W, H = 640, 384
    wall = Image.new("RGBA", (W, H), (26, 10, 14, 255))
    wall.alpha_composite(grad.resize((W, H), Image.BILINEAR))
    y0 = H - storey.height * 2 + 2
    for k in range(2):
        wall.alpha_composite(storey, (8, y0 + k * (storey.height - 2)))
        wall.alpha_composite(storey, (8 + 256 + 132 - 10, y0 + k * (storey.height - 2)))
    wall.alpha_composite(window, (8 + 258, H - window.height))
    wall.alpha_composite(window.crop((0, 0, window.width, 64)), (8 + 258, H - window.height - 60))
    # push it back: darker and cooler so the play layer reads in front
    a = np.array(wall).astype(float)
    a[..., :3] = a[..., :3] * [0.50, 0.46, 0.60] + [6, 4, 14]
    wall = quant(Image.fromarray(a.clip(0, 255).astype("uint8"), "RGBA"), 28)
    save(wall, "env/library_wall.png")
    save(quant(case, 20), "env/library_case.png")
    t = os.path.join(LIB, "spin off", "tiles")
    top = Image.open(os.path.join(t, "tiles_1.png")).convert("RGBA")
    fill = Image.open(os.path.join(t, "tiles_2.png")).convert("RGBA")
    trim = Image.open(os.path.join(t, "tiles_8.png")).convert("RGBA")
    tiles = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    tiles.alpha_composite(top.crop((0, 0, 64, 16)), (0, 0))            # row 0: floor top
    tiles.alpha_composite(top.crop((0, 16, 64, 32)), (0, 16))          # row 1: under the top
    for x in range(0, 64, 32):
        tiles.alpha_composite(fill.crop((0, 0, 32, 16)), (x, 32))      # row 2: deep fill
    save(tiles, "env/library_tiles.png")
    led = Image.new("RGBA", (64, 8), (0, 0, 0, 0))
    led.alpha_composite(trim.crop((0, 0, 64, 8)))
    save(led, "env/library_ledge.png")


# ---------------------------------------------------------------- church
def church():
    """The church pack tiles, laid out like the other themes (top / under / deep, 64 px wide)."""
    src = Image.open(os.path.join(A, "env", "church_tileset.png")).convert("RGBA")
    slab = src.crop((64, 167, 112, 183))
    fill = src.crop((16, 112, 48, 144))
    tiles = Image.new("RGBA", (64, 48), (0, 0, 0, 0))
    tiles.alpha_composite(slab, (0, 0))
    tiles.alpha_composite(slab.crop((0, 0, 16, 16)), (48, 0))
    for x in (0, 32):
        tiles.alpha_composite(fill.crop((0, 0, 32, 16)), (x, 16))
        tiles.alpha_composite(fill.crop((0, 16, 32, 32)), (x, 32))
    save(tiles, "env/church_tiles.png")
    save(tiles.crop((0, 0, 64, 8)), "env/church_ledge.png")


def music():
    """The area music the user supplied, under plain names."""
    import shutil
    names = {"Battle Encounter.ogg": "battle_encounter.ogg", "Battle Encounter 2.ogg": "battle_encounter_2.ogg",
             "BossBattle.ogg": "boss_battle.ogg", "save-room-music.ogg": "save_room.ogg"}
    for src, dst in names.items():
        shutil.copyfile(os.path.join(REF, src), os.path.join(A, "audio", "music", dst))


# ---------------------------------------------------------------- lab
def lab():
    back = Image.open(os.path.join(LAB, "layers", "back.png")).convert("RGBA")
    mid = Image.open(os.path.join(LAB, "layers", "middle.png")).convert("RGBA")
    wall = Image.new("RGBA", (320, 240), (4, 10, 20, 255))
    wall.alpha_composite(back)
    wall.alpha_composite(mid)
    a = np.array(wall).astype(float)
    a[..., :3] *= 0.72
    save(quant(Image.fromarray(a.astype("uint8"), "RGBA"), 24), "env/lab_wall.png")
    for i in (1, 2, 3):
        save(Image.open(os.path.join(LAB, "layers", "Props", f"tank-{i}.png")).convert("RGBA"), f"env/lab_tank{i}.png")
    # metal tiles, drawn here in the colours of the lab art
    C = [(5, 12, 22), (10, 26, 40), (16, 44, 60), (28, 78, 96), (74, 190, 200), (170, 240, 240)]
    tiles = Image.new("RGBA", (64, 48), C[1] + (255,))
    d = ImageDraw.Draw(tiles)
    for x in range(0, 64, 16):
        d.rectangle([x, 0, x + 15, 15], fill=C[2])           # top plate
        d.line([x, 0, x + 15, 0], fill=C[4])
        d.line([x, 1, x + 15, 1], fill=C[3])
        d.line([x, 15, x + 15, 15], fill=C[0])
        d.line([x + 15, 2, x + 15, 15], fill=C[1])
        d.point([(x + 2, 4), (x + 12, 4)], fill=C[3])
        if x % 32 == 0:
            d.rectangle([x + 5, 6, x + 10, 8], fill=C[0])
            d.line([x + 6, 7, x + 9, 7], fill=C[4])
        d.rectangle([x, 16, x + 15, 31], fill=C[1])          # under plate
        d.line([x, 16, x + 15, 16], fill=C[0])
        d.line([x + 15, 16, x + 15, 31], fill=C[0])
        for k in (3, 7, 11):
            d.line([x + k, 20, x + k, 28], fill=C[2])
        d.rectangle([x, 32, x + 15, 47], fill=C[0])          # deep fill
        d.line([x, 47, x + 15, 47], fill=C[1])
        d.point([(x + 1, 33), (x + 14, 33), (x + 1, 46), (x + 14, 46)], fill=C[2])
        if x % 32 == 16:
            d.line([x + 4, 39, x + 11, 39], fill=C[1])
            d.line([x + 4, 41, x + 11, 41], fill=C[1])
    save(tiles, "env/lab_tiles.png")
    led = Image.new("RGBA", (64, 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(led)
    for x in range(0, 64, 16):
        d.rectangle([x, 0, x + 15, 5], fill=C[1])
        d.line([x, 0, x + 15, 0], fill=C[4])
        d.line([x, 1, x + 15, 1], fill=C[3])
        for k in range(1, 16, 3):
            d.line([x + k, 3, x + k, 4], fill=C[0])
        d.line([x, 5, x + 15, 5], fill=C[0])
        d.point([(x, 6), (x + 15, 6), (x, 7), (x + 15, 7)], fill=C[2])
    save(led, "env/lab_ledge.png")


# ---------------------------------------------------------------- save room
def save_room():
    # the user replaced the first picture with a second one; use it when it is there
    pic = os.path.join(REF, "save-room-v2.jpg")
    if not os.path.exists(pic):
        pic = os.path.join(REF, "save-room-cache-station-terminal.jpg")
    im = Image.open(pic).convert("RGB")
    a = np.array(im).astype(int).sum(axis=2)
    cols = np.where(a.mean(axis=0) > 30)[0]
    x0, x1 = cols.min(), cols.max() + 1
    w = x1 - x0
    h = round(w * 216 / 384)
    y0 = min((im.height - h) // 2 + 20, im.height - h)
    im = im.crop((x0, y0, x1, y0 + h)).resize((384, 216), Image.BOX)
    im = im.quantize(40, method=Image.MEDIANCUT, dither=Image.NONE).convert("RGBA")
    save(im, "env/save_room.png")


# ---------------------------------------------------------------- doors
def doors():
    themes = {
        "church": [(20, 16, 34), (52, 44, 78), (92, 82, 128), (150, 140, 190), (226, 200, 120)],
        "library": [(24, 8, 10), (70, 30, 30), (120, 62, 50), (190, 130, 110), (236, 200, 120)],
        "lab": [(4, 10, 20), (14, 38, 54), (28, 78, 96), (74, 190, 200), (170, 240, 240)],
        "save": [(6, 14, 20), (20, 48, 56), (40, 96, 104), (110, 210, 210), (200, 250, 250)],
        "boss": [(10, 4, 18), (40, 14, 70), (88, 32, 150), (160, 90, 230), (255, 208, 60)],
    }
    for name, C in themes.items():
        boss = name == "boss"
        w, h = (24, 64) if boss else (16, 48)
        slab = Image.new("RGBA", (w, h), C[1] + (255,))      # the part that slides up
        d = ImageDraw.Draw(slab)
        d.rectangle([0, 0, w - 1, h - 1], outline=C[0])
        d.line([1, 1, 1, h - 2], fill=C[3])
        d.line([2, 1, 2, h - 2], fill=C[2])
        d.line([w - 2, 1, w - 2, h - 2], fill=C[0])
        for y in range(6, h - 8, 10):
            d.rectangle([4, y, w - 4, y + 6], outline=C[0], fill=C[2])
            d.line([5, y + 1, w - 5, y + 1], fill=C[3])
        cy = h // 2
        if boss:
            # a lidless eye: the special door watches you
            d.ellipse([3, cy - 12, w - 4, cy + 12], fill=C[0], outline=C[4])
            d.ellipse([7, cy - 6, w - 8, cy + 6], fill=C[2], outline=C[3])
            d.rectangle([w // 2 - 1, cy - 5, w // 2, cy + 5], fill=C[4])
            for k in (-20, 20):
                d.line([w // 2 - 4, cy + k, w // 2 + 3, cy + k], fill=C[4])
                d.point([(w // 2 - 1, cy + k - 1), (w // 2, cy + k + 1)], fill=C[4])
        else:
            d.rectangle([w // 2 - 2, cy - 3, w // 2 + 1, cy + 2], fill=C[0])
            d.rectangle([w // 2 - 1, cy - 2, w // 2, cy + 1], fill=C[4])
        save(slab, f"env/door_{name}.png")
        fw, fh = w + 8, h + 12                               # the frame around it
        fr = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        d = ImageDraw.Draw(fr)
        d.rectangle([0, 0, fw - 1, 11], fill=C[1], outline=C[0])
        d.line([1, 1, fw - 2, 1], fill=C[3])
        d.line([1, 10, fw - 2, 10], fill=C[0])
        d.rectangle([fw // 2 - 3, 3, fw // 2 + 2, 8], fill=C[0])
        d.rectangle([fw // 2 - 2, 4, fw // 2 + 1, 7], fill=C[4])
        for x in (0, fw - 4):
            d.rectangle([x, 12, x + 3, fh - 1], fill=C[1], outline=C[0])
            d.line([x + 1, 13, x + 1, fh - 2], fill=C[2])
            for y in range(18, fh - 4, 12):
                d.point([(x + 2, y)], fill=C[4])
        save(fr, f"env/doorframe_{name}.png")


# ---------------------------------------------------------------- boss
def boss():
    im = Image.open(os.path.join(REF, "mini-boss.png")).convert("RGBA")
    a = np.array(im).astype(int)
    r, g, b, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    gold = (al > 0) & (r > 170) & (g > 90) & (b < 110) & (r > b + 80)
    dark = (al > 0) & (r + g + b < 60)
    H, W = gold.shape
    hand = gold.copy()
    for y in range(H):                      # black shapes boxed in by gold on their row
        xs = np.where(gold[y])[0]
        if len(xs) < 2:
            continue
        for x in range(xs.min(), xs.max() + 1):
            if dark[y, x] and gold[y, max(0, x - 14):x].any() and gold[y, x + 1:x + 15].any():
                hand[y, x] = True
    # the open palm becomes the hand sprite
    box = (48, 8, 84, 52)
    sub = np.zeros_like(a)
    m = np.zeros_like(hand)
    m[box[1]:box[3], box[0]:box[2]] = hand[box[1]:box[3], box[0]:box[2]]
    sub[m] = a[m]
    hs = Image.fromarray(sub.astype("uint8"), "RGBA")
    hs = hs.crop(hs.getbbox())
    save(hs, "boss/hand.png")
    # the body: hands lifted off, the holes patched from the cloak beside them
    body = a.copy()
    body[hand] = 0
    body[108:] = 0                          # the painted floor shadow
    body[(dark & (np.arange(W)[None, :] < 26))[..., None].repeat(4, axis=2) & (np.arange(H)[:, None, None] < 84)] = 0   # scraps of the lifted left hand
    solid = body[..., 3] > 0
    xs = np.arange(W)[None, :]
    hole = hand & (xs > 24) & (xs < 62)
    # each hole pixel takes the colour of the nearest cloak pixel, so folds carry on
    sy, sx = np.where(solid & ~dark)
    for y, x in zip(*np.where(hole & ~solid)):
        k = np.argmin((sy - y) ** 2 * 3 + (sx - x) ** 2)
        if (sy[k] - y) ** 2 + (sx[k] - x) ** 2 <= 144:
            body[y, x] = body[sy[k], sx[k]]
    bs = Image.fromarray(body.astype("uint8"), "RGBA")
    bs = bs.crop(bs.getbbox())
    save(bs, "boss/body.png")
    return {"body": list(bs.size), "hand": list(hs.size)}


# ---------------------------------------------------------------- enemies
def enemies(meta):
    sets = {"choir": {"idle": ("choir_idle", 8), "attack": ("choir_attack", 3)},
            "spitter": {"idle": ("spitter", 5)},
            "warden": {"idle": ("warden_idle", 5), "run": ("warden_run", 6)}}
    for kind, anims in sets.items():
        out = {}
        size = None
        for anim, (stem, n) in anims.items():
            for i in range(n):
                im = Image.open(os.path.join(SAND, "miniboss", f"{stem}_{i + 1:02d}.png")).convert("RGBA")
                size = im.size
                save(im, f"{kind}/{anim}_{i:02d}.png")
            out[anim] = n
        ref = Image.open(os.path.join(A, kind, "idle_00.png"))
        meta[kind] = {"anims": out, "size": list(size), "bbox": list(ref.getbbox())}


def main():
    fj = os.path.join(A, "frames.json")
    meta = json.load(open(fj))
    for k in ("weapon-dirge", "weapon-elegy"):
        meta.pop(k, None)
    meta["weapon"] = weapons()
    church()
    music()
    library()
    lab()
    save_room()
    doors()
    meta["boss"] = boss()
    enemies(meta)
    json.dump(meta, open(fj, "w"))
    print({k: meta[k] for k in ("weapon", "boss", "choir", "spitter", "warden")})


if __name__ == "__main__":
    main()
