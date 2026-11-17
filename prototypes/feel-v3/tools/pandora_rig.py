"""Pandora puppet: cuts the user's own run frame 0 (2x art) into bone parts.

PROTOTYPE tool. Source = the user's drawing only
(assets/hero_2d_base/pandora-idle-sprites-32-bit/). Each opaque pixel goes to
the nearest bone segment; poses rotate each part about its joint (forward
kinematics) and draw the parts back to front. Run: python tools/pandora_rig.py label
writes a coloured cut map to check the segmentation.
"""
import math
import os
import sys

from PIL import Image, ImageSequence

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "assets/hero_2d_base/pandora-idle-sprites-32-bit")
OUT_TMP = os.environ.get("RIG_TMP", os.path.join(ROOT, "build", "rig_tmp"))

# Skeleton in run-frame-0 coordinates (224x224 canvas). parent, joint (pivot), end.
# Angles are derived from these; a pose gives each bone a rotation in degrees
# relative to the rest (this drawing). Draw order is back to front.
BONES = {
    "torso":    (None,       (127, 154), (132, 134)),   # pivot = hips, end = neck
    "head":     ("torso",    (132, 135), (137, 122)),
    "hair":     ("head",     (130, 124), (114, 118)),
    "hair_tip": ("hair",     (114, 118), (95, 118)),
    # the scarf has two tails (user: "a scarf, not a cape ... it has two tails")
    "scarf_a":     ("torso",   (122, 133), (101, 134)),
    "scarf_a_tip": ("scarf_a", (101, 134), (80, 147)),
    "scarf_b":     ("torso",   (120, 139), (101, 146)),
    "scarf_b_tip": ("scarf_b", (101, 146), (83, 158)),
    "arm_b_up": ("torso",    (128, 134), (117, 133)),
    "arm_f_up": ("torso",    (131, 135), (137, 143)),
    "arm_f_lo": ("arm_f_up", (137, 143), (151, 143)),
    "leg_b_th": ("torso",    (124, 155), (111, 165)),
    "leg_b_sh": ("leg_b_th", (111, 165), (91, 159)),
    "leg_f_th": ("torso",    (129, 155), (136, 168)),
    "leg_f_sh": ("leg_f_th", (136, 168), (139, 189)),
}
ORDER = ["scarf_b_tip", "scarf_b", "scarf_a_tip", "scarf_a", "arm_b_up", "leg_b_th", "leg_b_sh",
         "hair_tip", "hair", "torso", "head", "leg_f_th", "leg_f_sh", "arm_f_up", "arm_f_lo"]
# how strongly a bone claims pixels (bigger = claims a wider area)
REACH = {"hair": 1.5, "hair_tip": 1.5, "scarf_a": 1.3, "scarf_a_tip": 1.3, "scarf_b": 1.3, "scarf_b_tip": 1.3,
         "torso": 1.3, "head": 1.2}
COLORS = {b: c for b, c in zip(ORDER, [(120, 20, 20), (200, 40, 40), (255, 120, 120), (255, 80, 80),
                                        (255, 170, 60), (240, 240, 60), (140, 240, 60),
                                        (30, 180, 150), (60, 240, 200), (60, 140, 255), (160, 80, 255), (255, 80, 220),
                                        (255, 255, 255), (120, 120, 120), (0, 120, 60)])}


def load_run(i: int) -> Image.Image:
    g = Image.open(os.path.join(SRC, "Idle_v3_running_east (2).gif"))
    frames = [f.convert("RGBA").copy() for f in ImageSequence.Iterator(g)]
    return frames[i]


def _seg_dist(p, a, b) -> float:
    ax, ay = a
    bx, by = b
    px, py = p
    dx, dy = bx - ax, by - ay
    L = dx * dx + dy * dy
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def segment(img: Image.Image, overrides=None) -> dict:
    """bone -> RGBA layer (same canvas size) holding the pixels it owns."""
    W, H = img.size
    px = img.load()
    layers = {b: Image.new("RGBA", (W, H), (0, 0, 0, 0)) for b in BONES}
    lp = {b: layers[b].load() for b in BONES}
    for y in range(H):
        for x in range(W):
            c = px[x, y]
            if c[3] == 0:
                continue
            best, bd = None, 1e9
            for b, (_, j, e) in BONES.items():
                d = _seg_dist((x + 0.5, y + 0.5), j, e) / REACH.get(b, 1.0)
                if d < bd:
                    best, bd = b, d
            if overrides:
                for fn in overrides:
                    best = fn(x, y, c, best)
            lp[best][x, y] = c
    return layers


def label_map(img, layers, scale=6):
    W, H = img.size
    out = Image.new("RGBA", (W, H), (40, 40, 50, 255))
    o = out.load()
    for b, L in layers.items():
        p = L.load()
        for y in range(H):
            for x in range(W):
                if p[x, y][3]:
                    c = p[x, y]
                    k = COLORS[b]
                    o[x, y] = tuple(int(c[i] * 0.45 + k[i] * 0.55) for i in range(3)) + (255,)
    bb = img.getbbox()
    out = out.crop((bb[0] - 2, bb[1] - 2, bb[2] + 2, bb[3] + 2))
    return out.resize((out.width * scale, out.height * scale), Image.NEAREST)


# ---------- posing ----------

def _rot(p, c, deg):
    a = math.radians(deg)
    x, y = p[0] - c[0], p[1] - c[1]
    return (c[0] + x * math.cos(a) - y * math.sin(a), c[1] + x * math.sin(a) + y * math.cos(a))


def world(pose: dict):
    """bone -> (angle_total_deg, joint_world, offset) using forward kinematics.
    pose: {bone: deg, "_root": (dx, dy)} ; positive deg = clockwise on screen."""
    res = {}
    root = pose.get("_root", (0, 0))

    def solve(b):
        if b in res:
            return res[b]
        parent, j, e = BONES[b]
        ang = pose.get(b, 0.0)
        if parent is None:
            jw = (j[0] + root[0], j[1] + root[1])
            tot = ang
        else:
            pa, pjw, _ = solve(parent)
            pj = BONES[parent][1]
            # my joint, carried by the parent's rotation
            rel = _rot(j, pj, pa)
            jw = (rel[0] - pj[0] + pjw[0], rel[1] - pj[1] + pjw[1])
            tot = pa + ang
        res[b] = (tot, jw, None)
        return res[b]

    for b in BONES:
        solve(b)
    return res


def _place(layer: Image.Image, joint, deg, jw, size):
    # rotate the layer around its joint, then move the joint to jw
    pad = Image.new("RGBA", size, (0, 0, 0, 0))
    r = layer.rotate(-deg, resample=Image.NEAREST, center=joint)
    pad.alpha_composite(r, (int(round(jw[0] - joint[0])), int(round(jw[1] - joint[1]))) if False else (0, 0))
    if (round(jw[0] - joint[0]), round(jw[1] - joint[1])) != (0, 0):
        moved = Image.new("RGBA", size, (0, 0, 0, 0))
        moved.paste(pad, (int(round(jw[0] - joint[0])), int(round(jw[1] - joint[1]))), pad)
        pad = moved
    return pad


def caps(layers: dict, r: float = 2.5) -> dict:
    """copy a small disk of the parent's pixels round each joint into the child,
    so a bent joint does not open a gap"""
    out = {b: L.copy() for b, L in layers.items()}
    for b, (parent, j, _) in BONES.items():
        if parent is None:
            continue
        src = layers[parent].load()
        dst = out[b].load()
        W, H = out[b].size
        for y in range(int(j[1] - r - 1), int(j[1] + r + 2)):
            for x in range(int(j[0] - r - 1), int(j[0] + r + 2)):
                if 0 <= x < W and 0 <= y < H and math.hypot(x + 0.5 - j[0], y + 0.5 - j[1]) <= r:
                    if src[x, y][3] and not dst[x, y][3]:
                        dst[x, y] = src[x, y]
    return out


def render(layers: dict, pose: dict, order=None, size=(224, 224)) -> Image.Image:
    w = world(pose)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    for b in (order or pose.get("_order") or ORDER):
        tot, jw, _ = w[b]
        canvas.alpha_composite(_place(layers[b], BONES[b][1], tot, jw, size))
    return canvas


# ---------- absolute posing ----------
# A pose names where each bone POINTS: 0 = straight down, +90 = forward (her
# facing, right), -90 = back, 180 = up. Missing bones keep their drawn direction.

def rest_dir(b: str) -> float:
    _, j, e = BONES[b]
    return math.degrees(math.atan2(e[0] - j[0], e[1] - j[1]))


def abs_pose(dirs: dict, root=(0, 0), order=None) -> dict:
    """dirs may also hold shorthands: "scarf" (both tails, spread apart by
    "scarf_spread", default 14 degrees) and "*_bend" (a tip's extra turn vs its root).
    A bone not named keeps its drawn angle relative to its parent."""
    dirs = dict(dirs)
    if "scarf" in dirs:
        sp = dirs.pop("scarf_spread", 14.0)
        s = dirs.pop("scarf")
        dirs.setdefault("scarf_a", s - sp / 2)
        dirs.setdefault("scarf_b", s + sp / 2)
    bends = {"hair": dirs.pop("hair_bend", None)}
    bends["scarf_a"] = bends["scarf_b"] = dirs.pop("scarf_bend", None)
    for root_b, tip in (("hair", "hair_tip"), ("scarf_a", "scarf_a_tip"), ("scarf_b", "scarf_b_tip")):
        bend = bends[root_b]
        if tip not in dirs and root_b in dirs:
            rest_rel = rest_dir(tip) - rest_dir(root_b)
            dirs[tip] = dirs[root_b] + (rest_rel if bend is None else bend)
    tot = {}
    for b in BONES:                      # parents come first in BONES
        p = BONES[b][0]
        if b in dirs or p is None:
            tot[b] = rest_dir(b) - dirs.get(b, rest_dir(b))   # screen-clockwise turn
        else:
            tot[b] = tot[p]
    rel = {b: tot[b] - (tot[p] if p else 0.0) for b, (p, _, _) in BONES.items()}
    rel["_root"] = root
    if order:
        rel["_order"] = order
    return rel


def plant(img: Image.Image, hip_x=112, ground=151, lift=0, hip_world=None) -> Image.Image:
    """move the figure so the hip sits at hip_x and the lowest pixel on `ground`
    (minus lift for airborne poses); returns a 224x160 frame"""
    bb = img.getbbox()
    hx = hip_world[0] if hip_world else BONES["torso"][1][0]
    dx = int(round(hip_x - hx))
    dy = ground - (bb[3] - 1) - lift
    out = Image.new("RGBA", (224, 160), (0, 0, 0, 0))
    out.paste(img, (dx, dy), img)
    return out


def pose_frame(layers, dirs, lift=0, order=None, root=(0, 0)):
    p = abs_pose(dirs, root, order)
    img = render(layers, p)
    return plant(img, lift=lift, hip_world=world(p)["torso"][1])


# ---------- 2x -> 1x ----------

def _lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def reduce2x(img: Image.Image) -> Image.Image:
    """2x2 blocks -> 1 pixel. Keeps a block if 2+ of its 4 pixels are opaque.
    A block on the figure's edge takes its darkest pixel (keeps the outline);
    an inner block takes its most common colour, but a bright accent (cyan
    line, hair highlight, skin) wins when it is clearly brighter than the rest."""
    W, H = img.size[0] // 2, img.size[1] // 2
    src = img.load()
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    o = out.load()
    for y in range(H):
        for x in range(W):
            px = [src[2 * x + i, 2 * y + j] for j in (0, 1) for i in (0, 1)]
            op = [c for c in px if c[3] > 0]
            if len(op) < 2:
                continue
            if len(op) < 4:
                o[x, y] = min(op, key=_lum)
                continue
            counts = {}
            for c in op:
                counts[c] = counts.get(c, 0) + 1
            common = max(counts, key=lambda c: (counts[c], -_lum(c)))
            o[x, y] = common
    return out


def outline(img: Image.Image, color=(14, 10, 22, 255)) -> Image.Image:
    """close the silhouette: a transparent pixel touching the figure on 3+ of its
    4 sides is filled with the outline colour (no 1-pixel notches)"""
    W, H = img.size
    p = img.load()
    out = img.copy()
    o = out.load()
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            if p[x, y][3]:
                continue
            n = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)) if p[x + dx, y + dy][3])
            if n >= 3:
                o[x, y] = color
    return out


def to_game(frame2x: Image.Image) -> Image.Image:
    return outline(reduce2x(frame2x))


# ---------- high-quality path: Scale2x x2 -> rotate at 4x -> average to 1/8 ----------
import numpy as np  # noqa: E402

UP = 4          # source (2x art) is upscaled 4x = 8x game pixels
GAME = (112, 80)
FEET = (56, 76)


def scale2x(a: np.ndarray) -> np.ndarray:
    """EPX/Scale2x on an RGBA uint8 array (H, W, 4)."""
    p = a.view(np.uint32)[..., 0] if a.flags["C_CONTIGUOUS"] else np.ascontiguousarray(a).view(np.uint32)[..., 0]
    P = np.pad(p, 1, mode="edge")
    A, B, C, D = P[:-2, 1:-1], P[1:-1, :-2], P[1:-1, 2:], P[2:, 1:-1]   # up, left, right, down
    E = p
    e0 = np.where((B == A) & (B != D) & (A != C), A, E)
    e1 = np.where((A == C) & (A != B) & (C != D), C, E)
    e2 = np.where((D == B) & (D != C) & (B != A), B, E)
    e3 = np.where((C == D) & (C != A) & (D != B), D, E)
    H, W = p.shape
    out = np.empty((H * 2, W * 2), np.uint32)
    out[0::2, 0::2], out[0::2, 1::2], out[1::2, 0::2], out[1::2, 1::2] = e0, e1, e2, e3
    return out.view(np.uint8).reshape(H * 2, W * 2, 4)


def up4(img: Image.Image) -> Image.Image:
    a = np.ascontiguousarray(np.array(img.convert("RGBA")))
    a = scale2x(scale2x(a))
    return Image.fromarray(np.ascontiguousarray(a), "RGBA")


def palette_of(*imgs) -> np.ndarray:
    cols = set()
    for im in imgs:
        for c in im.convert("RGBA").getdata():
            if c[3]:
                cols.add(c[:3])
    return np.array(sorted(cols), np.float32)


def layers_up(layers: dict) -> dict:
    return {b: up4(L) for b, L in layers.items()}


def render_hi(layers_hi: dict, pose: dict) -> tuple:
    """compose the pose on the 4x canvas; returns (image, hip_world_in_source_px)"""
    w = world(pose)
    size = (layers_hi["torso"].width, layers_hi["torso"].height)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    for b in (pose.get("_order") or ORDER):
        tot, jw, _ = w[b]
        j = BONES[b][1]
        L = layers_hi[b]
        r = L.rotate(-tot, resample=Image.NEAREST, center=(j[0] * UP, j[1] * UP))
        dx, dy = int(round((jw[0] - j[0]) * UP)), int(round((jw[1] - j[1]) * UP))
        canvas.paste(r, (dx, dy), r) if (dx or dy) else canvas.alpha_composite(r)
    return canvas, w["torso"][1]


def to_game_hi(hi: Image.Image, hip, pal: np.ndarray, lift=0, dx_game=0,
               outline_col=(13, 9, 20), ground_src=None, offset_out=None) -> Image.Image:
    """plant the 4x render in an 8x game frame and average it down to 112x80.
    ground_src: source row that stands on the floor (fixed, for drawn cycles);
    default = the lowest pixel of this frame. offset_out (dict) receives ox, oy
    so source points can be mapped: game = (src * UP + o) / 8."""
    S = UP * 2          # hi pixels per game pixel
    Wg, Hg = GAME
    frame = Image.new("RGBA", (Wg * S, Hg * S), (0, 0, 0, 0))
    bottom = hi.getbbox()[3] if ground_src is None else int(round((ground_src + 1) * UP))
    ox = int(round(FEET[0] * S - hip[0] * UP)) + dx_game * S
    oy = (FEET[1] * S) - bottom - lift * S
    if offset_out is not None:
        offset_out.update(ox=ox, oy=oy)
    frame.paste(hi, (ox, oy), hi)
    a = np.array(frame, np.float32).reshape(Hg, S, Wg, S, 4)
    alpha = a[..., 3] > 0
    cover = alpha.mean(axis=(1, 3))
    rgb = (a[..., :3] * alpha[..., None]).sum(axis=(1, 3)) / np.maximum(alpha.sum(axis=(1, 3)), 1)[..., None]
    solid = cover >= 0.42
    # snap to the artist's palette
    d = ((rgb[..., None, :] - pal[None, None, :, :]) ** 2).sum(-1)
    snapped = pal[d.argmin(-1)]
    out = np.zeros((Hg, Wg, 4), np.uint8)
    out[..., :3] = snapped.astype(np.uint8)
    out[..., 3] = np.where(solid, 255, 0)
    # 1-px outline: every solid pixel that touches empty space (4-neighbour)
    s = solid
    pad = np.pad(s, 1)
    edge = s & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
    out[edge, :3] = outline_col
    return Image.fromarray(out, "RGBA")


if __name__ == "__main__":
    os.makedirs(OUT_TMP, exist_ok=True)
    img = load_run(0)
    layers = segment(img)
    if len(sys.argv) > 1 and sys.argv[1] == "label":
        label_map(img, layers).save(os.path.join(OUT_TMP, "labels.png"))
        print("wrote", os.path.join(OUT_TMP, "labels.png"))
