# PROTOTYPE - NOT FOR PRODUCTION
# Builds Pandora's game frames from the user's own Aseprite-cleaned GIFs in
# assets/sprites-pandora/ (idle, breathing, run, slide, crouch, stand-up).
# Moves the GIFs do not have (attacks, jump, cast, backdash, hurt, death, wall
# grip) are posed from the closest frames of the same GIFs.
#
# Output: assets/2x/pandora/<anim>_NN.png at DOUBLE density (a PNG pixel is half
# a world unit; the game draws them at half size through G.tex), canvas 224x160,
# feet at (112, 152). She stands about 90 px tall = 45 world units.
# Also rewrites the "hero" entry of assets/frames.json (counts, hands, shoulders).
#
#   python tools/build_pandora_v3.py            (from prototypes/feel-v3)
#   python tools/build_pandora_v3.py --preview <png>   also writes a contact sheet
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
A = os.path.join(HERE, "..", "assets")
SRC = os.path.join(A, "sprites-pandora")
OUT = os.path.join(A, "2x", "pandora")
GIFS = {"g1": "spritesheet pandora.gif", "g4": "sprite-sheet-pandora-4.gif", "g5": "sprite-sheet-pandora-5.gif"}
S = 2.0 / 3.0                 # GIF pixels -> 2x game pixels (135 px tall -> 90 px)
CW, CH = 224, 160             # canvas in 2x pixels (= 112 x 80 world units)
FX, FY = 112, 152             # her feet on the canvas

# anchor of each GIF segment, in GIF pixels: (x of her body centre, ground line).
# Multiples of 3 keep the 2/3 resampling phase identical from frame to frame.
GROUND = 135
AX = {"g4": 105, "g1run": 114, "g1": 123, "g1slide": 102, "g1kneel": 117}
# "hip": the frame's own hip centre (the lunge frames travel inside the GIF)


def seq(tag, a, b, step=1):
    return [f"{tag}_{i:03d}" for i in range(a, b + (1 if step > 0 else -1), step)]


# anim -> list of (frame, anchor key, dx, dy) ; dx/dy nudge in GIF pixels
def plan():
    p = {}
    idle = seq("g4", 0, 11) + seq("g4", 10, 1, -1)       # forward then back: a calm loop
    p["idle"] = [(f, "g4", 0, 0) for f in idle]
    p["run"] = [(f, "g1run", 0, 0) for f in seq("g1", 37, 47)]
    p["jump"] = [("g1_035", "g1run", 0, -6), ("g1_046", "g1run", 0, -9), ("g1_047", "g1run", 0, -9), ("g1_045", "g1run", 0, -3)]
    p["land"] = [("g1_052", "g1run", 0, 0)]
    p["crouch"] = [(f, "g4", 0, 0) for f in ["g4_012", "g4_014", "g4_016", "g4_018", "g4_021"]]
    p["attack"] = [("g4_013", "g4", 0, 0), ("g1_052", "g1run", 0, 0), ("g1_053", "hip", -3, 0),
                   ("g1_054", "hip", -6, 0), ("g1_055", "hip", -6, 0)]
    p["attack2"] = [("g4_014", "g4", 0, 0), ("g1_034", "g1run", 0, 0), ("g1_056", "hip", -6, 0),
                    ("g1_055", "hip", -6, 0), ("g1_053", "hip", -3, 0)]
    p["crouchatk"] = [("g1_072", "g1kneel", 0, 0), ("g1_068", "g1kneel", 0, 0), ("g1_066", "g1kneel", 0, 0),
                      ("g1_065", "g1kneel", 0, 0), ("g1_069", "g1kneel", 0, 0)]
    p["crouchatk2"] = [("g1_072", "g1kneel", 0, 0), ("g1_070", "g1kneel", 0, 0), ("g1_065", "g1kneel", 0, 0),
                       ("g1_066", "g1kneel", 0, 0), ("g1_068", "g1kneel", 0, 0)]
    p["airatk"] = [("g1_035", "g1run", 0, -6), ("g1_046", "g1run", 0, -9), ("g1_053", "hip", -3, -12),
                   ("g1_054", "hip", -6, -12), ("g1_047", "g1run", 0, -9)]
    p["airatk2"] = [("g1_034", "g1run", 0, -6), ("g1_047", "g1run", 0, -9), ("g1_056", "hip", -6, -12),
                    ("g1_055", "hip", -6, -12), ("g1_046", "g1run", 0, -9)]
    p["cast"] = [("g4_014", "g4", 0, 0), ("g1_067", "g1kneel", 0, 0), ("g1_066", "g1kneel", 0, 0),
                 ("g1_065", "g1kneel", 0, 0), ("g1_065", "g1kneel", 0, 0)]
    p["backdash"] = [("g4_013", "g4", 0, 0), ("g4_014", "g4", 0, 0), ("g4_015", "g4", 0, 0), ("g4_013", "g4", 0, 0)]
    p["hurt"] = [("g1_084", "g1", 0, 0), ("g1_085", "g1", 0, 0)]
    p["dead"] = [("g1_084", "g1", 0, 0), ("g4_016", "g4", 0, 0), ("g4_020", "g4", 0, 0), ("g4_022", "g4", 0, 3)]
    p["slide"] = [(f, "g1slide", 0, 0) for f in ["g1_058", "g1_059", "g1_060"]]
    p["wall"] = [("g4_013", "g4", 0, -6), ("g4_014", "g4", 0, -3)]
    p["walljump"] = [("g1_035", "g1run", 0, -6), ("g1_046", "g1run", 0, -9), ("g1_047", "g1run", 0, -9)]
    p["rise"] = [(f, "g1", 0, 0) for f in seq("g1", 84, 94, 2) + ["g1_095"]]
    p["front"] = [(f, "g4", 0, 0) for f in seq("g5", 0, 11)]
    return p


def load_frames():
    out = {}
    for tag, name in GIFS.items():
        im = Image.open(os.path.join(SRC, name))
        for i in range(im.n_frames):
            im.seek(i)
            f = np.array(im.convert("RGBA"))
            black = (f[..., 0] == 0) & (f[..., 1] == 0) & (f[..., 2] == 0)
            f[black, 3] = 0
            f = clean(f, slide=False)
            out[f"{tag}_{i:03d}"] = f
    return out


def clean(f, slide):
    # stray lines the GIF export left in the top rows, and specks far from her
    from scipy import ndimage
    a = f[..., 3] > 0
    lab, n = ndimage.label(a, structure=np.ones((3, 3)))
    if n <= 1:
        return f
    sizes = ndimage.sum(a, lab, range(1, n + 1))
    big = int(np.argmax(sizes)) + 1
    objs = ndimage.find_objects(lab)
    for k, sl in enumerate(objs, start=1):
        if k == big:
            continue
        y0, y1 = sl[0].start, sl[0].stop
        if y1 <= 5 or sizes[k - 1] < 6:
            f[lab == k, 3] = 0
    return f


def no_debris(f):
    # the slide kicks up stones: keep them for the slide, drop them elsewhere
    from scipy import ndimage
    a = f[..., 3] > 0
    lab, n = ndimage.label(a, structure=np.ones((3, 3)))
    if n <= 1:
        return f
    sizes = ndimage.sum(a, lab, range(1, n + 1))
    big = int(np.argmax(sizes)) + 1
    for k, sl in enumerate(ndimage.find_objects(lab), start=1):
        if k != big and sl[0].start > 110:
            f[lab == k, 3] = 0
    return f


def hip_x(arr):
    # middle of her body at hip height (55-70 % down the figure), snapped to the 2/3 grid
    a = arr[..., 3] > 0
    ys = np.where(a.any(axis=1))[0]
    h = ys[-1] - ys[0]
    band = a[ys[0] + int(h * 0.55): ys[0] + int(h * 0.7)]
    xs = np.where(band.any(axis=0))[0]
    return int(round((xs.min() + xs.max()) / 2.0 / 3.0)) * 3


def dead_pose(frames):
    # last death frame: the kneeling figure laid on its side (a lossless quarter turn)
    k = frames["g1_075"].copy()
    im = Image.fromarray(k).rotate(-90, expand=True)
    bb = im.getbbox()
    im = im.crop(bb)
    canvas = Image.new("RGBA", (240, 135), (0, 0, 0, 0))
    canvas.alpha_composite(im, (AX["g4"] - im.width // 2, 135 - im.height))
    return np.array(canvas)


def premul_resize(arr, size):
    a = arr.astype(np.float32) / 255.0
    al = a[..., 3:4]
    pm = np.concatenate([a[..., :3] * al, al], axis=2)
    chans = []
    for c in range(4):
        ch = Image.fromarray(np.clip(pm[..., c] * 255.0 + 0.5, 0, 255).astype(np.uint8), "L").resize(size, Image.LANCZOS)
        chans.append(np.asarray(ch).astype(np.float32) / 255.0)
    o = np.stack(chans, axis=2)
    al = o[..., 3:4]
    rgb = np.where(al > 1e-4, o[..., :3] / np.maximum(al, 1e-4), 0.0)
    return np.clip(rgb, 0, 1), al[..., 0]


def place(arr, ax, dx, dy):
    # crop a window around the anchor so that it lands on (FX, FY) after scaling
    wx, wy = round(CW / S), round(CH / S)            # 336 x 240 GIF pixels
    ox, oy = ax + dx - round(FX / S), GROUND + dy - round(FY / S)
    src = np.zeros((wy, wx, 4), np.uint8)
    h, w = arr.shape[:2]
    x0, y0 = max(0, ox), max(0, oy)
    x1, y1 = min(w, ox + wx), min(h, oy + wy)
    src[y0 - oy:y1 - oy, x0 - ox:x1 - ox] = arr[y0:y1, x0:x1]
    return premul_resize(src, (CW, CH))


def main():
    frames = load_frames()
    frames["DEAD"] = dead_pose(frames)
    p = plan()
    rendered = {}
    for anim, items in p.items():
        out = []
        for name, key, dx, dy in items:
            arr = frames[name].copy()
            if anim != "slide":
                arr = no_debris(arr)
            ax = hip_x(arr) if key == "hip" else AX[key]
            out.append(place(arr, ax, dx, dy))
        rendered[anim] = out
    # one shared palette from her own colours keeps every frame consistent
    sample = Image.open(os.path.join(SRC, "spritesheet pandora.png")).convert("RGBA")
    sm = np.array(sample)
    opaque = sm[sm[..., 3] > 0][:, :3]
    pal_src = Image.fromarray(opaque.reshape(1, -1, 3).astype(np.uint8), "RGB")
    pal = pal_src.quantize(colors=40, dither=Image.Dither.NONE)
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.endswith(".png"):
            os.remove(os.path.join(OUT, f))
    counts = {}
    for anim, out in rendered.items():
        counts[anim] = len(out)
        for i, (rgb, al) in enumerate(out):
            img = Image.fromarray((rgb * 255.0 + 0.5).astype(np.uint8), "RGB").quantize(palette=pal, dither=Image.Dither.NONE).convert("RGB")
            alpha = (al >= 0.5).astype(np.uint8) * 255
            Image.fromarray(np.dstack([np.asarray(img), alpha]), "RGBA").save(os.path.join(OUT, f"{anim}_{i:02d}.png"))
    write_meta(counts)
    if "--preview" in sys.argv:
        preview(counts, sys.argv[sys.argv.index("--preview") + 1])
    print("pandora v3:", sum(counts.values()), "frames", counts)


def write_meta(counts):
    path = os.path.join(A, "frames.json")
    meta = json.load(open(path))
    hero = meta["hero"]
    hero["anims"] = counts
    hero["dir"] = "pandora"
    hero["faces"] = "right"
    hero["size"] = [CW // 2, CH // 2]
    hero["feet"] = [FX // 2, FY // 2]
    hero["density"] = 2
    # her shoulders sit where player.gd's SWINGS table expects them, so no per-frame grip points
    hero.pop("shoulders", None)
    hero.pop("hands", None)
    json.dump(meta, open(path, "w"), indent=2)


def arm_points():
    # measured on the built frames (2x pixels / 2): the shoulder of the striking arm and its hand
    sh_stand, sh_low, sh_air = [57, 44], [57, 52], [57, 42]
    shoulders = {
        "attack": [sh_stand] * 5, "attack2": [sh_stand] * 5,
        "crouchatk": [sh_low] * 5, "crouchatk2": [sh_low] * 5,
        "airatk": [sh_air] * 5, "airatk2": [sh_air] * 5,
    }
    hands = {
        "attack": [[60, 52], [52, 50], [70, 47], [76, 46], [74, 47]],
        "attack2": [[60, 52], [52, 50], [72, 47], [76, 46], [70, 48]],
        "crouchatk": [[60, 60], [52, 58], [70, 55], [76, 54], [72, 56]],
        "crouchatk2": [[60, 60], [52, 58], [74, 54], [72, 55], [68, 57]],
        "airatk": [[60, 50], [52, 48], [70, 45], [76, 44], [72, 46]],
        "airatk2": [[60, 50], [52, 48], [72, 45], [76, 44], [70, 46]],
    }
    return shoulders, hands


def preview(counts, path):
    from PIL import ImageDraw
    rows = list(counts.items())
    cols = max(min(c, 12) for _, c in rows)
    sheet = Image.new("RGBA", (cols * CW, len(rows) * (CH + 12)), (58, 58, 76, 255))
    dr = ImageDraw.Draw(sheet)
    for r, (anim, n) in enumerate(rows):
        for i in range(min(n, cols)):
            im = Image.open(os.path.join(OUT, f"{anim}_{i:02d}.png"))
            x, y = i * CW, r * (CH + 12) + 12
            # her collision box (12 x 36 world units = 24 x 72 px) and the feet line
            dr.rectangle([x + FX - 12, y + FY - 72, x + FX + 12, y + FY], outline=(90, 200, 90, 255))
            dr.line([x, y + FY, x + CW, y + FY], fill=(120, 120, 150, 255))
            sheet.alpha_composite(im, (x, y))
        dr.text((2, r * (CH + 12)), anim, fill=(255, 255, 0, 255))
    sheet.save(path)


if __name__ == "__main__":
    main()
