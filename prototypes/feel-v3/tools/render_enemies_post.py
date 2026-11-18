"""Turn raw 4x enemy renders into 2x-density pixel-art frames.

Run (plain Python 3 with Pillow + numpy):

  python -I tools/render_enemies_post.py --kind crab --raw <raw dir> [--sheet <dir for contact sheet>]

Steps per kind: 4x -> 1x area average (premultiplied) -> grade/recolour to the kind's accent ->
per-frame effects -> alpha threshold at 50% -> ONE shared palette (<= 24 colours incl. the outline)
-> speck clean-up -> 1 px outline #0b0912 -> assets/2x/<kind>/<anim>_NN.png + meta.json.
"""

import colorsys
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "assets/2x"
SS = 4
OUTLINE = (0x0B, 0x09, 0x12)
MAX_COLORS = 24

ANIM_COUNTS = {
    "crab": {"idle": 4, "walk": 6, "rear": 4, "burrow": 5, "emerge": 4},
    "moth": {"fly": 6, "gust": 4, "swing": 6, "dive": 2},
    "scribe": {"idle": 6, "write": 6, "throw": 4, "melt": 5},
    "leech": {"hang": 4, "drop": 2, "latch": 4},
    "organ": {"idle": 4},
}

CANVAS = {"crab": (112, 72), "moth": (112, 96), "scribe": (72, 120), "leech": (40, 88), "organ": (256, 288)}
ANCHOR = {"crab": (56, 72), "moth": (56, 52), "scribe": (37, 60), "leech": (20, 0), "organ": (128, 288)}
FORCED = {  # colours always in the palette (glow strokes drawn after the outline use them)
    "scribe": [(0.45, 0.96, 1.0), (0.68, 0.40, 1.0), (0.34, 0.18, 0.58)],
}
RUNE = [  # segments (x0, y0, x1, y1) of the glyph the scribe writes, in a 13 x 15 box
    (3, 0, 3, 14), (3, 3, 10, 6), (10, 6, 3, 9), (3, 9, 10, 13), (6, 0, 10, 2), (0, 7, 3, 7),
]
GROUND_ROW = {"crab": 71}  # rows at or below this are underground in burrow/emerge frames


# ---------------------------------------------------------------- colour helpers
def rgb2hsv(a):
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx, mn = a.max(-1), a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    rc = np.where(m & (mx == r), ((g - b) / np.where(m, d, 1)) % 6, 0)
    gc = np.where(m & (mx == g) & (mx != r), (b - r) / np.where(m, d, 1) + 2, 0)
    bc = np.where(m & (mx == b) & (mx != r) & (mx != g), (r - g) / np.where(m, d, 1) + 4, 0)
    h = (rc + gc + bc) * 60.0
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1), 0)
    return np.stack([h % 360, s, mx], -1)


def hsv2rgb(a):
    h, s, v = a[..., 0] / 60.0, a[..., 1], a[..., 2]
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
    out = np.zeros(a.shape, dtype=np.float32)
    for k, (r, g, b) in enumerate([(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]):
        m = i == k
        out[..., 0] = np.where(m, r, out[..., 0])
        out[..., 1] = np.where(m, g, out[..., 1])
        out[..., 2] = np.where(m, b, out[..., 2])
    return out


def hue_in(h, lo, hi):
    return (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)


# per-kind look: grade + recolour ops applied to every frame
LOOK = {
    "crab": dict(sat=1.18, contrast=1.14, gamma=0.95,
                 ops=[dict(kind="hue", h=(140, 215), s_min=0.25, to=8, s_mul=1.3, v_mul=1.25),          # cyan dots -> red glow
                      dict(kind="tint", v=(0.0, 0.5), s_max=0.45, color=(0.36, 0.06, 0.10), mix=0.55),    # dark shell -> dried blood red
                      dict(kind="tint", v=(0.5, 1.0), s_max=0.40, v_min=0.55, color=(0.96, 0.90, 0.76), mix=0.35)],  # bone -> ivory
                 accent=dict(h=(340, 30), s_min=0.5, v_min=0.5)),
    "moth": dict(sat=1.15, contrast=1.18, gamma=0.95,
                 ops=[dict(kind="hue", h=(130, 215), s_min=0.2, to=24, s_mul=1.5, v_mul=1.35),             # teal censer -> ember orange
                      dict(kind="tint", v=(0.55, 1.0), s_max=0.40, color=(0.95, 0.88, 0.72), mix=0.35),
                      dict(kind="tint", v=(0.0, 0.45), s_max=0.5, color=(0.10, 0.07, 0.12), mix=0.4)],
                 accent=dict(h=(5, 50), s_min=0.5, v_min=0.55)),
    "scribe": dict(sat=1.2, contrast=1.2, gamma=0.95,
                   ops=[dict(kind="tint", v=(0.0, 0.5), s_max=0.45, color=(0.10, 0.07, 0.17), mix=0.5),
                        dict(kind="hue", h=(130, 215), s_min=0.25, to=185, s_mul=1.2, v_mul=1.3)],
                   accent=dict(h=(165, 290), s_min=0.45, v_min=0.55)),
    "leech": dict(sat=1.1, contrast=1.15, gamma=0.95,
                  ops=[dict(kind="hue", h=(130, 215), s_min=0.2, to=335, s_mul=0.8, v_mul=1.2),           # mouth glow -> sick pink
                       dict(kind="hue", h=(200, 265), s_min=0.05, to=345, s_mul=0.9, v_mul=1.05),          # blue-grey flesh -> pink-grey
                       ],
                  accent=dict(h=(320, 360), s_min=0.38, v_min=0.7)),
    "organ": dict(sat=1.25, contrast=1.25, gamma=1.12,
                  ops=[dict(kind="tint", v=(0.0, 0.7), s_max=0.4, h=(150, 290), color=(0.24, 0.28, 0.42), mix=0.4),
                       dict(kind="tint", v=(0.3, 1.0), s_max=0.45, h=(15, 75), color=(0.97, 0.90, 0.74), mix=0.5)],
                  accent=dict(h=(150, 205), s_min=0.4, v_min=0.45)),
}


def apply_look(rgb, look):
    hsv = rgb2hsv(rgb)
    for op in look["ops"]:
        h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
        if op["kind"] == "hue":
            m = hue_in(h, *op["h"]) & (s >= op["s_min"])
            hsv[..., 0] = np.where(m, op["to"], h)
            hsv[..., 1] = np.where(m, np.clip(s * op["s_mul"], 0, 1), s)
            hsv[..., 2] = np.where(m, np.clip(v * op["v_mul"], 0, 1), v)
        else:  # tint toward a colour (for low-saturation pixels in a brightness band)
            m = (v >= op["v"][0]) & (v <= op["v"][1]) & (s <= op["s_max"]) & (v >= op.get("v_min", 0.0))
            if "h" in op:
                m &= hue_in(h, *op["h"])
            tgt = np.array(op["color"], dtype=np.float32)
            base = hsv2rgb(hsv)
            lum = base.max(-1, keepdims=True)
            tinted = tgt * np.clip(lum / max(tgt.max(), 1e-6), 0, 1.4)
            mixed = base * (1 - op["mix"]) + tinted * op["mix"]
            hsv = np.where(m[..., None], rgb2hsv(np.clip(mixed, 0, 1)), hsv)
    hsv[..., 1] = np.clip(hsv[..., 1] * look["sat"], 0, 1)
    rgb = hsv2rgb(hsv)
    rgb = np.clip((rgb - 0.5) * look["contrast"] + 0.5, 0, 1) ** look["gamma"]
    return rgb.astype(np.float32)


# ---------------------------------------------------------------- frame handling
def downscale(img):
    a = img[..., 3].astype(np.float32) / 255
    rgb = img[..., :3].astype(np.float32) / 255
    h, w = a.shape[0] // SS, a.shape[1] // SS
    pr = (rgb * a[..., None]).reshape(h, SS, w, SS, 3).mean(axis=(1, 3))
    aa = a.reshape(h, SS, w, SS).mean(axis=(1, 3))
    return pr / np.maximum(aa[..., None], 1e-6), aa


def remove_islands(alpha, min_size):
    h, w = alpha.shape
    seen = np.zeros_like(alpha, bool)
    out = alpha.copy()
    for y in range(h):
        for x in range(w):
            if alpha[y, x] and not seen[y, x]:
                stack, comp = [(y, x)], []
                seen[y, x] = True
                while stack:
                    cy, cx = stack.pop()
                    comp.append((cy, cx))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and alpha[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            stack.append((ny, nx))
                if len(comp) < min_size:
                    for cy, cx in comp:
                        out[cy, cx] = False
    return out


def kmeans(px, k, iters=8, seed=1):
    rng = np.random.default_rng(seed)
    if len(px) <= k:
        return np.unique(px, axis=0)
    # farthest-point style init for better spread
    cent = [px[rng.integers(len(px))]]
    d = ((px - cent[0]) ** 2).sum(1)
    for _ in range(1, k):
        cent.append(px[int(np.argmax(d * rng.random(len(px)) ** 0.3))])
        d = np.minimum(d, ((px - cent[-1]) ** 2).sum(1))
    cent = np.array(cent)
    for _ in range(iters):
        idx = ((px[:, None, :] - cent[None]) ** 2).sum(-1).argmin(1)
        for j in range(len(cent)):
            m = idx == j
            if m.any():
                cent[j] = px[m].mean(0)
    return cent


def nearest(rgb, pal):
    d = ((rgb[..., None, :] - pal[None, None]) ** 2).sum(-1)
    return d.argmin(-1)


def despeckle(idx, alpha, passes=2):
    h, w = idx.shape
    for _ in range(passes):
        out = idx.copy()
        pad = np.pad(idx, 1, constant_values=-1)
        pa = np.pad(alpha, 1, constant_values=False)
        for y in range(h):
            for x in range(w):
                if not alpha[y, x]:
                    continue
                nb = []
                for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                    if pa[y + 1 + dy, x + 1 + dx]:
                        nb.append(pad[y + 1 + dy, x + 1 + dx])
                if len(nb) >= 3:
                    vals, cnt = np.unique(nb, return_counts=True)
                    top = vals[cnt.argmax()]
                    if cnt.max() >= 3 and top != idx[y, x]:
                        out[y, x] = top
        idx = out
    return idx


def outline(alpha):
    p = np.pad(alpha, 1, constant_values=False)
    grown = p[1:-1, 1:-1] | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return grown & ~alpha


# ---------------------------------------------------------------- per-frame effects
def effect_pulse(rgb, alpha, pulse, accent):
    hsv = rgb2hsv(rgb)
    m = hue_in(hsv[..., 0], *accent["h"]) & (hsv[..., 1] >= accent["s_min"] * 0.8) & (hsv[..., 2] >= accent["v_min"] * 0.6)
    hsv[..., 2] = np.where(m, np.clip(hsv[..., 2] * (0.75 + 0.55 * pulse), 0, 1), hsv[..., 2])
    hsv[..., 1] = np.where(m, np.clip(hsv[..., 1] * (1.0 - 0.28 * pulse), 0, 1), hsv[..., 1])
    return hsv2rgb(hsv)


def dilate(m, r):
    out = m.copy()
    for _ in range(r):
        q = np.pad(out, 1, constant_values=False)
        out = out | q[:-2, 1:-1] | q[2:, 1:-1] | q[1:-1, :-2] | q[1:-1, 2:]
    return out


def effect_glow(rgb, mask, accent, color, radius=4, strength=0.6):
    """Warm the body pixels near accent pixels so the glow reads without growing the silhouette."""
    hsv = rgb2hsv(rgb)
    acc = mask & hue_in(hsv[..., 0], *accent["h"]) & (hsv[..., 1] >= accent["s_min"]) & (hsv[..., 2] >= accent["v_min"])
    if acc.sum() < 3:
        return rgb
    out = rgb.copy()
    col = np.array(color, dtype=np.float32)
    reach = acc.copy()
    for d in range(1, radius + 1):
        ring = dilate(acc, d) & ~reach
        reach |= ring
        w = strength * (1 - (d - 1) / radius) ** 1.5
        sel = ring & mask
        out[sel] = out[sel] * (1 - w) + col * w
    return out


def make_frames(kind, raw):
    cnt = ANIM_COUNTS[kind]
    extras = {}
    for f in sorted(Path(raw, kind).glob("frames_*.json")):
        for anim, lst in json.loads(f.read_text()).items():
            extras.setdefault(anim, lst)
    frames = {}
    for anim, n in cnt.items():
        for i in range(n):
            p = Path(raw, kind, f"{anim}_{i:02d}.png")
            img = np.array(Image.open(p).convert("RGBA"))
            rgb, a = downscale(img)
            ex = extras.get(anim, [{}] * n)
            ex = ex[i] if i < len(ex) else {}
            frames[(anim, i)] = dict(rgb=rgb, a=a, ex=ex)
    return frames


def run(kind, raw, sheet_dir):
    look = LOOK[kind]
    W, H = CANVAS[kind]
    frames = make_frames(kind, raw)
    # grade + effects + alpha mask
    for key, fr in frames.items():
        rgb = apply_look(fr["rgb"], look)
        ex = fr["ex"]
        if "pulse" in ex:
            rgb = effect_pulse(rgb, fr["a"], ex["pulse"], look["accent"])
        mask = fr["a"] >= 0.5
        if kind == "organ" and "pulse" in ex:
            rgb = effect_glow(rgb, mask, look["accent"], (0.35, 0.95, 0.9), radius=2, strength=0.8 * ex["pulse"])
        if kind == "moth":
            rgb = effect_glow(rgb, mask, look["accent"], (1.0, 0.45, 0.12), radius=5, strength=0.65)
        if ex.get("clip_ground") and kind in GROUND_ROW:
            mask[GROUND_ROW[kind]:, :] = False
        if kind == "scribe" and "melt" in ex:
            k = ex["melt"]
            clip = ex.get("clip_y", 108)
            yy = np.arange(rgb.shape[0])[:, None]
            t = np.clip((yy - (clip - 18)) / 18.0, 0, 1) * min(1.0, k * 3)   # ink creeps up the body
            ink = np.array([0.07, 0.05, 0.13], dtype=np.float32)
            rgb = rgb * (1 - 0.85 * t[..., None]) + ink * (0.85 * t[..., None])
            mask[clip:, :] = False
        fr["rgb"], fr["mask"] = rgb, mask
        mask = remove_islands(mask, 4)
        fr["mask"] = mask
    return frames


def add_scribe_extras(frames):
    """Ink puddle for melt, glyph strokes for write. Drawn into rgb/mask before quantizing."""
    for (anim, i), fr in frames.items():
        ex = fr["ex"]
        if anim == "melt":
            k = ex.get("melt", 0.0)
            if k > 0.05:
                H, W = fr["mask"].shape
                cx, cy = W // 2 - 2, ex.get("clip_y", 108)
                rx = int(round(7 + 25 * min(1.0, k)))
                ry = int(round(2 + 4 * min(1.0, k)))
                yy, xx = np.mgrid[0:H, 0:W]
                ell = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1
                col = np.array([0.09, 0.06, 0.19], dtype=np.float32)
                hl = np.array([0.30, 0.18, 0.50], dtype=np.float32)
                fr["rgb"] = np.where(ell[..., None], col, fr["rgb"])
                shine = ((xx - (cx - rx // 3)) / max(rx // 3, 1)) ** 2 + ((yy - (cy - 1)) / 1.0) ** 2 <= 1
                fr["rgb"] = np.where((shine & ell)[..., None], hl, fr["rgb"])
                fr["mask"] = fr["mask"] | ell
        if anim == "write":
            pass


def quantize_all(kind, frames):
    look = LOOK[kind]
    allpx = np.concatenate([fr["rgb"][fr["mask"]] for fr in frames.values()])
    hsv = rgb2hsv(allpx)
    ac = look["accent"]
    am = hue_in(hsv[:, 0], *ac["h"]) & (hsv[:, 1] >= ac["s_min"]) & (hsv[:, 2] >= ac["v_min"])
    forced = FORCED.get(kind, [])
    k_total = MAX_COLORS - 1 - len(forced)  # one slot is the outline
    k_acc = 4 if am.sum() > 60 else (2 if am.sum() > 10 else 0)
    base = allpx[~am]
    pal = kmeans(base, k_total - k_acc, iters=10)
    if k_acc:
        pal = np.concatenate([pal, kmeans(allpx[am], k_acc, iters=8)])
    if forced:
        pal = np.concatenate([pal, np.array(forced, dtype=np.float32)])
    return np.clip(pal, 0, 1)


def rune_pixels():
    pts = []
    for x0, y0, x1, y1 in RUNE:
        n = max(abs(x1 - x0), abs(y1 - y0)) + 1
        for t in range(n):
            q = (round(x0 + (x1 - x0) * t / max(n - 1, 1)), round(y0 + (y1 - y0) * t / max(n - 1, 1)))
            if q not in pts:
                pts.append(q)
    return pts


def finish(kind, frames, pal):
    W, H = CANVAS[kind]
    pal_u8 = np.round(np.vstack([pal, np.array(OUTLINE) / 255.0]) * 255).astype(np.uint8)
    out = {}
    for key, fr in frames.items():
        idx = nearest(fr["rgb"], pal)
        idx = despeckle(idx, fr["mask"])
        mask = fr["mask"]
        ol = outline(mask)
        img = np.zeros((H, W, 4), dtype=np.uint8)
        img[mask, :3] = pal_u8[idx[mask]]
        img[mask, 3] = 255
        img[ol, :3] = OUTLINE
        img[ol, 3] = 255
        if kind == "scribe" and key[0] == "write":
            draw_rune(img, key[1], frames)
        out[key] = img
    return out, pal_u8


def draw_rune(img, i, frames):
    """Glowing glyph hanging in the air in front of the writing hand, revealed stroke by stroke."""
    hands = [fr["ex"]["hand_px"] for (a, j), fr in frames.items() if a == "write" and "hand_px" in fr["ex"]]
    hx = float(np.mean([h[0] for h in hands])) if hands else 50.0
    hy = float(np.mean([h[1] for h in hands])) if hands else 40.0
    W = img.shape[1]
    ox = int(min(max(hx + 9, 0), W - 14))
    oy = int(hy - 10)
    pts = rune_pixels()
    n = len(pts)
    shown = int(round(n * (i + 1) / ANIM_COUNTS["scribe"]["write"]))
    cyan, violet, dim = [np.round(np.array(c) * 255).astype(np.uint8) for c in FORCED["scribe"]]
    for j, (x, y) in enumerate(pts[:shown]):
        px, py = ox + x, oy + y
        if not (0 <= px < W and 0 <= py < img.shape[0]):
            continue
        tip = j >= shown - 3
        img[py, px, :3] = cyan if tip else violet
        img[py, px, 3] = 255
        # one dim glow pixel to the right of the shaft on the older strokes
        gx = px + 1
        if not tip and gx < W and img[py, gx, 3] == 0 and j % 2 == 0:
            img[py, gx, :3] = dim
            img[py, gx, 3] = 255


def write_all(kind, imgs, pal_u8, sheet_dir):
    d = OUT_ROOT / kind
    d.mkdir(parents=True, exist_ok=True)
    for (anim, i), img in imgs.items():
        Image.fromarray(img, "RGBA").save(d / f"{anim}_{i:02d}.png")
    # contact sheet: 3x nearest, rows = anims
    zoom = 3
    W, H = CANVAS[kind]
    cols = max(ANIM_COUNTS[kind].values())
    rows = len(ANIM_COUNTS[kind])
    pad = 4
    sheet = Image.new("RGB", (cols * (W * zoom + pad) + pad, rows * (H * zoom + pad) + pad), (14, 14, 20))
    dr = ImageDraw.Draw(sheet)
    ax, ay = ANCHOR[kind]
    for r, (anim, n) in enumerate(ANIM_COUNTS[kind].items()):
        for c in range(n):
            x0, y0 = pad + c * (W * zoom + pad), pad + r * (H * zoom + pad)
            cell = Image.new("RGBA", (W, H), (52, 54, 70, 255))
            cell.alpha_composite(Image.fromarray(imgs[(anim, c)], "RGBA"))
            cell = cell.resize((W * zoom, H * zoom), Image.NEAREST).convert("RGB")
            sheet.paste(cell, (x0, y0))
            dr.rectangle([x0 - 1, y0 - 1, x0 + W * zoom, y0 + H * zoom], outline=(90, 200, 120))
            px, py = x0 + ax * zoom, y0 + min(ay, H - 1) * zoom
            dr.rectangle([px - 2, py - 2, px + 2, py + 2], outline=(255, 40, 90))
    if sheet_dir:
        Path(sheet_dir).mkdir(parents=True, exist_ok=True)
        sheet.save(Path(sheet_dir) / f"{kind}_sheet.png")
        # palette strip
        strip = Image.new("RGB", (len(pal_u8) * 12, 12))
        for i, c in enumerate(pal_u8):
            strip.paste(tuple(int(v) for v in c), (i * 12, 0, i * 12 + 12, 12))
        strip.save(Path(sheet_dir) / f"{kind}_palette.png")


BODY = {"crab": [88, 40], "moth": [40, 56], "scribe": [26, 98], "leech": [22, 70], "organ": [200, 270]}
NOTES = {
    "crab": "Bone-ivory spine crab with dark-red shell, near-frontal view (it scuttles sideways, so it is almost symmetrical; 5 degree turn to the right). Feet on the bottom edge. burrow/emerge are cut off at the ground line (bottom row); the last burrow frame shows only the spine tip.",
    "moth": "Censer moth, front view with ember-orange censer glow; symmetrical so facing right is neutral. Anchor = body centre (56,52), 4 px below the canvas centre so raised wings fit. swing sweeps the censer left to right in one pass; dive is head-down with wings swept back.",
    "scribe": "Needle scribe, side view facing right, floating (legs trail). melt ends in an ink puddle near the bottom of the canvas.",
    "leech": "Thread leech hanging head-down; the thread attaches at the top centre. Latch frames are meant to be drawn over the target.",
    "organ": "Time machine (memory organ) prop, front view, base on the bottom edge. idle = the glowing parts pulse.",
}


def main():
    argv = sys.argv[1:]
    kind = argv[argv.index("--kind") + 1]
    raw = argv[argv.index("--raw") + 1]
    sheet = argv[argv.index("--sheet") + 1] if "--sheet" in argv else None
    frames = run(kind, raw, sheet)
    if kind == "scribe":
        add_scribe_extras(frames)
    pal = quantize_all(kind, frames)
    imgs, pal_u8 = finish(kind, frames, pal)
    write_all(kind, imgs, pal_u8, sheet)
    W, H = CANVAS[kind]
    meta = {"canvas": [W, H], "anchor": list(ANCHOR[kind]), "faces": "right", "anims": ANIM_COUNTS[kind], "body": BODY[kind],
            "notes": NOTES[kind], "palette_size": int(len(pal_u8))}
    (OUT_ROOT / kind / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")
    print("POST DONE", kind, len(imgs), "frames,", len(pal_u8), "colours")


if __name__ == "__main__":
    main()
