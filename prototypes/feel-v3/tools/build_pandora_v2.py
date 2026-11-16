"""Build the Route B heroine sprite set (assets/hero_v2/) from pandora-001-sprite.jpg.

Cut-out puppet: the green background is keyed out, the picture is cut into body
parts, every part gets a pivot in a small skeleton, and hand-authored poses drive
it.  Each frame is composed at 8x the final size, box-filtered down to 112x80,
quantised to one shared palette and given a 1 px dark outline.

Run from the game folder:  python tools/build_pandora_v2.py
"""
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw

SRC = "assets/references/pandora-001-sprite.jpg"
OUT = "assets/hero_v2"
W, H = 112, 80
SS = 8                      # supersampling factor
FEET = (56, 76)
GROUND = 75                 # lowest body row before the outline (outline lands on 76)
K = (60.0 / 905.0) * SS     # source px -> hi-res px
OUTLINE = (14, 11, 22)
NCOL = 23                   # palette colours besides the outline

# ---------------------------------------------------------------- skeleton
HIP = (530.0, 590.0)
NECK = (565.0, 262.0)
TIE = (505.0, 118.0)
HP2 = (335.0, 190.0)
HP3 = (245.0, 330.0)
CAPE_PV = (455.0, 285.0)
SHO = (630.0, 325.0)
ELB = (655.0, 445.0)
WRI = (700.0, 545.0)
HAND_PT = (712.0, 585.0)
FHIP = (592.0, 592.0)
KNEE = (625.0, 728.0)
ANK = (645.0, 905.0)
SOLE = [(612.0, 1003.0), (745.0, 1000.0), (680.0, 1003.0)]
KNEECAP = [(650.0, 745.0), (615.0, 755.0)]
BACK_SHO_OFF = (-72.0, 4.0)
BACK_HIP_OFF = (-48.0, -4.0)


def ang(p, q):
    """Bone angle in the down-forward convention: 0 = down, +90 = forward (right)."""
    return math.degrees(math.atan2(q[0] - p[0], q[1] - p[1]))


A_UP = ang(SHO, ELB)
A_FO = ang(ELB, WRI)
A_HA = ang(WRI, HAND_PT)
A_TH = ang(FHIP, KNEE)
A_SH = ang(KNEE, ANK)
L0 = math.degrees(math.atan2(NECK[0] - HIP[0], HIP[1] - NECK[1]))

# part polygons in source pixels
POLY = {
    "hand": [(672, 528), (722, 522), (748, 578), (744, 618), (698, 620), (678, 578)],
    "fore": [(628, 438), (676, 432), (702, 478), (718, 538), (690, 556), (664, 528), (638, 482)],
    "upper": [(602, 288), (662, 292), (678, 360), (676, 446), (640, 458), (620, 404), (608, 340)],
    "foot": [(592, 896), (692, 892), (762, 958), (762, 1012), (592, 1012)],
    "shin": [(582, 732), (670, 730), (676, 800), (684, 900), (596, 904), (588, 820)],
    "thigh": [(556, 592), (656, 580), (672, 650), (668, 736), (588, 738), (568, 680)],
    "head": [(478, 95), (560, 92), (640, 128), (670, 170), (646, 215), (634, 262), (618, 302),
             (592, 282), (562, 270), (530, 276), (510, 300), (490, 270), (480, 200)],
    "torso": [(450, 232), (522, 222), (612, 248), (646, 298), (642, 420), (656, 520),
              (662, 604), (612, 618), (530, 628), (470, 618), (452, 560), (458, 450), (448, 330)],
    "tail": [(140, 8), (575, 8), (575, 95), (478, 95), (474, 200), (440, 236), (380, 292),
             (320, 362), (272, 462), (262, 590), (140, 590)],
    "cape": [(420, 232), (470, 238), (456, 330), (450, 450), (446, 560), (404, 600), (372, 640),
             (360, 700), (332, 835), (250, 845), (175, 835), (165, 700), (218, 560), (280, 430),
             (350, 318)],
    "cape2": [(660, 560), (702, 556), (778, 750), (774, 845), (720, 835), (674, 782), (674, 640)],
}
TAIL_PATH = [TIE, (430.0, 58.0), HP2, HP3, (200.0, 530.0)]


def load_parts():
    src = np.asarray(Image.open(SRC).convert("RGB")).astype(np.int32)
    r, g, b = src[..., 0], src[..., 1], src[..., 2]
    bg = (g > 140) & (g > r + 50) & (g > b + 50)
    rgb = src.copy()
    spill = (~bg) & (g > np.maximum(r, b) + 25)
    rgb[..., 1] = np.where(spill, np.maximum(r, b), g)
    alpha = (~bg).astype(np.uint8)
    # drop the source's own black outline ring on the outer silhouette: it would double
    # the outline after downscaling; the final outline is regenerated.
    lum = 0.3 * rgb[..., 0] + 0.59 * rgb[..., 1] + 0.11 * rgb[..., 2]
    sat = rgb.max(-1) - rgb.min(-1)

    def pmask(name):
        im = Image.new("L", (1024, 1024), 0)
        ImageDraw.Draw(im).polygon(POLY[name], fill=1)
        return np.asarray(im).astype(bool)

    taken = np.zeros_like(alpha, dtype=bool)
    masks = {}
    for name in ["hand", "fore", "upper", "foot", "shin", "thigh", "head", "torso"]:
        m = pmask(name) & alpha.astype(bool) & ~taken
        masks[name] = m
        taken |= m
    hairish = (lum > 62) & (sat < 70)
    tail = pmask("tail") & alpha.astype(bool) & ~taken & hairish
    # also keep dark hair-shadow pixels that sit between hair pixels
    taken |= tail
    cape = pmask("cape") & alpha.astype(bool) & ~taken
    masks["cape"] = cape
    # split the ponytail into three segments along its path
    ys, xs = np.nonzero(tail)
    pts = np.stack([xs, ys], 1).astype(float)
    best = np.full(len(pts), 1e9)
    seg = np.zeros(len(pts), int)
    for i in range(len(TAIL_PATH) - 1):
        p, q = np.array(TAIL_PATH[i]), np.array(TAIL_PATH[i + 1])
        d = q - p
        t = np.clip(((pts - p) @ d) / (d @ d), 0, 1)
        dist = np.linalg.norm(pts - (p + t[:, None] * d), axis=1)
        upd = dist < best
        best[upd] = dist[upd]
        seg[upd] = i
    group = np.array([0, 0, 1, 2])[seg]
    for gi, name in enumerate(["tailA", "tailB", "tailC"]):
        m = np.zeros_like(tail)
        sel = group == gi
        m[ys[sel], xs[sel]] = True
        masks[name] = m
    # cape: hide the far arm's cyan lines that sit on the cape area
    cyan = (rgb[..., 2] > 120) & (rgb[..., 2] > rgb[..., 0] + 60)
    capecol = np.array([38, 42, 40])
    rgb_cape = rgb.copy()
    rgb_cape[cape & cyan] = capecol
    parts = {}
    for name, m in masks.items():
        base = rgb_cape if name == "cape" else rgb
        ys, xs = np.nonzero(m)
        x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
        arr = np.zeros((y1 - y0, x1 - x0, 4), np.uint8)
        arr[..., :3] = base[y0:y1, x0:x1]
        arr[..., 3] = m[y0:y1, x0:x1] * 255
        parts[name] = (Image.fromarray(arr, "RGBA"), x0, y0)
        dark = arr.copy()
        dark[..., :3] = (dark[..., :3] * 0.62).astype(np.uint8)
        parts[name + "_dk"] = (Image.fromarray(dark, "RGBA"), x0, y0)
    return parts


# ---------------------------------------------------------------- matrices
def T(dx, dy):
    return np.array([[1, 0, dx], [0, 1, dy], [0, 0, 1]], float)


def R(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]], float)


def S(sx, sy):
    return np.array([[sx, 0, 0], [0, sy, 0], [0, 0, 1]], float)


def L(deg, pv):
    """Rotate by deg (clockwise on screen) about source point pv."""
    return T(pv[0], pv[1]) @ R(deg) @ T(-pv[0], -pv[1])


def app(M, p):
    v = M @ np.array([p[0], p[1], 1.0])
    return v[0], v[1]


BASE = dict(lean=6, bob=0.0, tilt=0, fa=8, fe=10, fh=0, ba=4, be=14, bh=0,
            ft=10, fk=4, ff=0, bt=-10, bk=6, bf=0, hair=(0, 0, 0), cape=0,
            rot=0, sx=1.0, dx=0.0, dy=0.0, bfront=False)


def P(**kw):
    p = dict(BASE)
    p.update(kw)
    return p


def rig(p, root):
    """World matrices (source -> hi-res canvas) for every drawn part."""
    G = T(root[0], root[1]) @ R(p["rot"]) @ S(p["sx"] * K, K) @ T(-HIP[0], -HIP[1])
    torso = T(0, p["bob"] * SS / K) @ L(p["lean"] - L0, HIP)
    head = torso @ L(p["tilt"], NECK)
    ha, hb, hc = p["hair"]
    tA = head @ L(ha - 0.5 * p["tilt"], TIE)
    tB = tA @ L(hb, HP2)
    tC = tB @ L(hc, HP3)
    cape = torso @ L(p["cape"], CAPE_PV)
    M = {"tailA": tA, "tailB": tB, "tailC": tC, "cape": cape, "torso": torso, "head": head}

    def arm(prefix, a, e, h, base):
        up = base @ L(A_UP - a, SHO)
        fo = up @ L(A_FO - A_UP - e, ELB)
        hd = fo @ L(A_HA - A_FO - h, WRI)
        M[prefix + "upper"], M[prefix + "fore"], M[prefix + "hand"] = up, fo, hd

    def leg(prefix, t, k, f, base):
        th = base @ L(A_TH - t, FHIP)
        sh = th @ L(A_SH - A_TH + k, KNEE)
        foot_world = -f
        th_w = (A_TH - t)
        sh_w = th_w + (A_SH - A_TH + k)
        ft = sh @ L(foot_world - sh_w, ANK)
        M[prefix + "thigh"], M[prefix + "shin"], M[prefix + "foot"] = th, sh, ft

    arm("f_", p["fa"], p["fe"], p["fh"], torso)
    arm("b_", p["ba"], p["be"], p["bh"], torso @ T(*BACK_SHO_OFF))
    leg("f_", p["ft"], p["fk"], p["ff"], np.eye(3))
    leg("b_", p["bt"], p["bk"], p["bf"], T(*BACK_HIP_OFF))
    return {k: G @ v for k, v in M.items()}


def order(p):
    back_arm = ["b_upper", "b_fore", "b_hand"]
    o = ["cape", "tailC", "tailB", "tailA"]
    if not p["bfront"]:
        o += back_arm
    o += ["b_thigh", "b_shin", "b_foot", "torso", "head", "f_thigh", "f_shin", "f_foot"]
    if p["bfront"]:
        o += back_arm
    o += ["f_upper", "f_fore", "f_hand"]
    return o


def ground_y(Ms):
    pts = []
    for side in ("f_", "b_"):
        pts += [app(Ms[side + "foot"], s)[1] for s in SOLE]
        pts += [app(Ms[side + "shin"], s)[1] for s in KNEECAP]
    return max(pts)


def compose(parts, p, mode):
    root = [W * SS / 2 + p["dx"] * SS, 48.5 * SS + p["dy"] * SS]
    Ms = rig(p, root)
    if mode == "feet":
        root[1] += (GROUND + 1) * SS - ground_y(Ms)
        Ms = rig(p, root)
    canvas = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    striker = {"f_upper", "f_fore", "f_hand"}
    if p["bfront"]:
        striker = {"b_upper", "b_fore", "b_hand"}
    arm = np.zeros((H * SS, W * SS), np.uint8)
    for name in order(p):
        key = name[2:] if name[:2] in ("f_", "b_") else name
        limb = key in ("upper", "fore", "hand")
        dark = name.startswith("b_") and not (p["bfront"] and limb)
        img, x0, y0 = parts[key + ("_dk" if dark else "")]
        Mi = np.linalg.inv(Ms[name])
        data = (Mi[0, 0], Mi[0, 1], Mi[0, 2] - x0, Mi[1, 0], Mi[1, 1], Mi[1, 2] - y0)
        layer = img.transform(canvas.size, Image.AFFINE, data, resample=Image.NEAREST)
        canvas.alpha_composite(layer)
        la = np.asarray(layer)[..., 3]
        if name in striker:
            arm = np.maximum(arm, la)
        else:
            arm = np.minimum(arm, 255 - la)
    a = np.asarray(canvas).astype(np.float32) / 255.0
    pm = a[..., :3] * a[..., 3:4]
    pm = pm.reshape(H, SS, W, SS, 3).mean((1, 3))
    al = a[..., 3].reshape(H, SS, W, SS).mean((1, 3))
    arm_m = (arm.astype(np.float32) / 255.0).reshape(H, SS, W, SS).mean((1, 3)) > 0.45
    rgb = pm / np.maximum(al[..., None], 1e-6)
    opaque = al > 0.45
    if mode == "pixels":
        rows = np.nonzero(opaque.any(1))[0]
        if len(rows):
            shift = GROUND - rows.max()
            opaque = np.roll(opaque, shift, 0)
            arm_m = np.roll(arm_m, shift, 0)
            rgb = np.roll(rgb, shift, 0)
            for k in Ms:
                Ms[k] = T(0, shift * SS) @ Ms[k]
    if mode in ("feet", "pixels"):
        opaque[GROUND + 1:] = False
    arm_m &= opaque
    # selective outline: a dark line where the striking arm crosses the body or hair
    nb = np.zeros_like(arm_m)
    nb[1:] |= arm_m[:-1]
    nb[:-1] |= arm_m[1:]
    nb[:, 1:] |= arm_m[:, :-1]
    nb[:, :-1] |= arm_m[:, 1:]
    line = nb & ~arm_m & opaque
    hand_f = app(Ms["f_hand"], HAND_PT)
    hand_b = app(Ms["b_hand"], HAND_PT)
    sho_f = app(Ms["f_upper"], SHO)
    sho_b = app(Ms["b_upper"], SHO)
    info = {k: (round(v[0] / SS), round(v[1] / SS)) for k, v in
            dict(hand_f=hand_f, hand_b=hand_b, sho_f=sho_f, sho_b=sho_b).items()}
    info["line"] = line
    return rgb * 255.0, opaque, info


# ---------------------------------------------------------------- poses
def lerp(a, b, t):
    out = {}
    for k in a:
        if isinstance(a[k], tuple):
            out[k] = tuple(x + (y - x) * t for x, y in zip(a[k], b[k]))
        elif isinstance(a[k], bool):
            out[k] = a[k] if t < 0.5 else b[k]
        else:
            out[k] = a[k] + (b[k] - a[k]) * t
    return out


def anim_idle():
    fr = []
    for i in range(6):
        s = math.sin(2 * math.pi * i / 6)
        c = math.cos(2 * math.pi * i / 6)
        fr.append(P(lean=6 + s, bob=0.5 - 0.5 * c, fa=10 + 3 * s, fe=12 + 4 * s, ba=4 - 3 * s,
                    be=16, ft=12, fk=6 + 3 * (1 - c), bt=-12, bk=6 + 3 * (1 - c),
                    hair=(2 * s, 4 * math.sin(2 * math.pi * i / 6 - 1), 6 * math.sin(2 * math.pi * i / 6 - 2)),
                    cape=2 * math.sin(2 * math.pi * i / 6 - 0.8)))
    return fr


def leg_cycle(ph):
    t = 14 + 42 * math.sin(ph)
    k = 18 + 78 * max(0.0, math.cos(ph)) ** 1.3
    f = -28 * max(0.0, -math.sin(ph)) * (1 if math.cos(ph) > -0.3 else 0.5) + 8 * max(0.0, math.sin(ph))
    return t, k, f


def anim_run():
    fr = []
    for i in range(16):
        ph = 2 * math.pi * i / 16
        ft, fk, ff = leg_cycle(ph)
        bt, bk, bf = leg_cycle(ph + math.pi)
        w = math.sin(2 * ph)
        fr.append(P(lean=16 + 2 * w, bob=0.6 * (1 + math.cos(2 * ph)) * 0.5, tilt=-8,
                    fa=2 - 44 * math.sin(ph), fe=52 + 14 * math.sin(ph), fh=-10,
                    ba=2 + 44 * math.sin(ph), be=52 - 14 * math.sin(ph),
                    ft=ft, fk=fk, ff=ff, bt=bt, bk=bk, bf=bf,
                    hair=(-14 + 3 * math.sin(2 * ph), 22 + 6 * math.sin(2 * ph - 1.0), 16 + 8 * math.sin(2 * ph - 2.0)),
                    cape=26 + 5 * math.sin(2 * ph - 0.7)))
    return fr


def anim_jump():
    return [
        P(lean=8, tilt=-6, fa=150, fe=20, ba=-35, be=20, ft=62, fk=95, ff=0, bt=-14, bk=12, bf=-30,
          hair=(8, -18, -14), cape=-10),
        P(lean=6, tilt=-2, fa=80, fe=40, ba=-10, be=40, ft=46, fk=72, ff=0, bt=8, bk=56, bf=-15,
          hair=(0, 0, 0), cape=4),
        P(lean=4, tilt=0, fa=110, fe=30, ba=50, be=40, ft=30, fk=40, ff=-5, bt=-4, bk=40, bf=-20,
          hair=(-8, 14, 12), cape=16),
        P(lean=2, tilt=2, fa=150, fe=20, ba=125, be=25, ft=16, fk=16, ff=-12, bt=-14, bk=26, bf=-25,
          hair=(-16, 30, 22), cape=30),
    ]


def anim_land():
    return [P(lean=26, tilt=-10, bob=1.0, fa=36, fe=30, ba=-14, be=30, ft=66, fk=112, ff=0,
              bt=10, bk=96, bf=-10, hair=(6, -10, -8), cape=-8)]


CROUCH = P(lean=18, tilt=-8, bob=0.5, fa=34, fe=48, ba=14, be=50, ft=84, fk=128, ff=0,
           bt=12, bk=112, bf=-35, hair=(4, -6, -4), cape=-4)


def anim_crouch():
    a = anim_idle()[0]
    return [lerp(a, CROUCH, t) for t in (0.2, 0.45, 0.7, 0.9, 1.0)]


# upper-body keys for the attacks (front arm strikes)
ATK_UP = [
    dict(lean=3, fa=195, fe=45, fh=-10, ba=16, be=50, hair=(2, -2, 0), cape=-2),
    dict(lean=1, fa=205, fe=10, fh=-10, ba=12, be=50, hair=(3, -4, -2), cape=-4),
    dict(lean=8, fa=118, fe=12, fh=0, ba=-12, be=40, hair=(-6, 10, 8), cape=8),
    dict(lean=12, fa=50, fe=0, fh=0, ba=-36, be=30, hair=(-10, 18, 12), cape=14),
    dict(lean=10, fa=46, fe=6, fh=0, ba=-30, be=32, hair=(-6, 12, 10), cape=10),
]
# the other (far) hand strikes: sweeps from low in front up to head height
ATK2_UP = [
    dict(lean=8, ba=0, be=110, bh=-10, fa=24, fe=60, hair=(-2, 4, 4), cape=2, bfront=True),
    dict(lean=10, ba=-15, be=115, bh=-10, fa=14, fe=64, hair=(-2, 6, 4), cape=4, bfront=True),
    dict(lean=5, ba=60, be=50, bh=0, fa=-16, fe=40, hair=(-6, 12, 8), cape=8, bfront=True),
    dict(lean=1, ba=125, be=15, bh=0, fa=-34, fe=30, hair=(-10, 18, 14), cape=12, bfront=True),
    dict(lean=2, ba=120, be=20, bh=0, fa=-30, fe=32, hair=(-6, 12, 10), cape=8, bfront=True),
]
ATK_LEGS = [dict(ft=20, fk=12, bt=-18, bk=8), dict(ft=20, fk=12, bt=-18, bk=8),
            dict(ft=28, fk=20, bt=-20, bk=8), dict(ft=32, fk=24, bt=-22, bk=8),
            dict(ft=30, fk=22, bt=-22, bk=8)]
AIR_LEGS = [dict(ft=50, fk=76, bt=0, bk=52, bf=-20), dict(ft=52, fk=80, bt=2, bk=56, bf=-20),
            dict(ft=44, fk=66, bt=-6, bk=44, bf=-25), dict(ft=40, fk=60, bt=-10, bk=40, bf=-25),
            dict(ft=42, fk=62, bt=-8, bk=42, bf=-25)]


def build_attack(ups, legs, crouch=False):
    fr = []
    for u, lg in zip(ups, legs):
        p = P(**lg)
        if crouch:
            p = dict(CROUCH)
            p["lean"] = 0
        p.update(u)
        if crouch:
            p["lean"] = u["lean"] + 10
            p["tilt"] = -6
        fr.append(p)
    return fr


def anim_backdash():
    return [
        P(lean=14, tilt=-6, bob=0.6, fa=-10, fe=30, ba=30, be=40, ft=40, fk=40, bt=-6, bk=60, bf=-20,
          hair=(6, -10, -8), cape=-6),
        P(lean=10, tilt=-4, fa=-30, fe=40, ba=-10, be=40, ft=52, fk=34, ff=10, bt=10, bk=70, bf=-10,
          hair=(14, -22, -18), cape=-22),
        P(lean=10, tilt=-4, fa=-26, fe=40, ba=-6, be=40, ft=48, fk=30, ff=10, bt=6, bk=64, bf=-10,
          hair=(16, -26, -20), cape=-26),
        P(lean=16, tilt=-6, bob=0.8, fa=10, fe=30, ba=20, be=40, ft=36, fk=50, bt=-8, bk=58, bf=-15,
          hair=(8, -12, -10), cape=-12),
    ]


def anim_dash():
    return [
        P(lean=24, tilt=-12, bob=0.6, fa=-30, fe=30, ba=-40, be=30, ft=40, fk=50, bt=-30, bk=30, bf=-25,
          hair=(-16, 26, 18), cape=28),
        P(lean=32, tilt=-16, bob=0.8, fa=-50, fe=20, ba=-60, be=20, ft=58, fk=30, bt=-46, bk=24, bf=-30,
          hair=(-22, 36, 26), cape=40),
        P(lean=32, tilt=-16, bob=0.8, fa=-54, fe=20, ba=-64, be=20, ft=60, fk=28, bt=-48, bk=22, bf=-30,
          hair=(-24, 40, 30), cape=44),
        P(lean=20, tilt=-10, bob=0.6, fa=-20, fe=30, ba=-30, be=30, ft=44, fk=46, bt=-28, bk=30, bf=-20,
          hair=(-14, 24, 18), cape=26),
    ]


def anim_hurt():
    return [
        P(lean=-12, tilt=-14, fa=60, fe=30, ba=-50, be=20, ft=30, fk=14, ff=10, bt=-16, bk=30,
          hair=(10, -18, -14), cape=-16),
        P(lean=-20, tilt=-20, bob=0.6, fa=80, fe=40, ba=-70, be=30, ft=36, fk=20, ff=14, bt=-20, bk=40,
          hair=(14, -26, -20), cape=-24),
    ]


def anim_cast():
    return [
        P(lean=8, tilt=4, fa=28, fe=104, fh=-20, ba=22, be=104, bh=-20, ft=14, fk=10, bt=-14, bk=10,
          hair=(0, 4, 4), cape=2),
        P(lean=0, tilt=-10, fa=158, fe=30, ba=146, be=40, ft=12, fk=6, bt=-14, bk=6,
          hair=(-6, 14, 12), cape=10),
        P(lean=12, tilt=-4, fa=92, fe=4, ba=84, be=10, ft=24, fk=18, bt=-20, bk=8,
          hair=(-12, 22, 16), cape=20),
        P(lean=12, tilt=-4, fa=90, fe=2, ba=82, be=8, ft=24, fk=18, bt=-20, bk=8,
          hair=(-14, 26, 20), cape=24),
        P(lean=8, tilt=0, fa=40, fe=30, ba=30, be=30, ft=16, fk=10, bt=-16, bk=8,
          hair=(-4, 8, 8), cape=8),
    ]


def anim_dead():
    return [
        P(lean=-14, tilt=-18, bob=0.6, fa=50, fe=30, ba=-40, be=30, ft=40, fk=40, bt=-10, bk=50,
          hair=(10, -16, -12), cape=-14),
        P(lean=24, tilt=26, bob=1.0, fa=10, fe=10, ba=0, be=10, ft=88, fk=150, bt=40, bk=150, bf=-40,
          hair=(6, -10, -8), cape=-6),
        P(rot=-40, lean=4, tilt=10, fa=40, fe=10, ba=30, be=10, ft=60, fk=70, bt=40, bk=60,
          hair=(10, -10, -6), cape=-10),
        P(rot=-86, lean=6, tilt=6, fa=20, fe=4, ba=10, be=6, ft=14, fk=6, ff=20, bt=6, bk=10, bf=20,
          hair=(30, -20, -10), cape=0),
    ]


def anim_wall():
    return [
        P(lean=-4, tilt=-4, fa=40, fe=50, ba=-95, be=10, ft=34, fk=60, bt=-34, bk=96, bf=40,
          hair=(-4, 10, 8), cape=6, dx=-1),
        P(lean=-3, tilt=-2, bob=0.5, fa=44, fe=54, ba=-92, be=12, ft=30, fk=56, bt=-30, bk=92, bf=40,
          hair=(-6, 14, 12), cape=8, dx=-1),
    ]


def anim_walljump():
    return [
        P(lean=6, tilt=-6, bob=0.6, fa=-40, fe=40, ba=-70, be=30, ft=-10, fk=96, bt=-40, bk=110, bf=30,
          hair=(4, -6, -4), cape=-4, dx=-2),
        P(lean=24, tilt=-10, fa=130, fe=20, ba=-40, be=20, ft=20, fk=30, bt=-40, bk=20, bf=-30,
          hair=(-12, 20, 16), cape=22),
        P(lean=10, tilt=-6, fa=140, fe=24, ba=-30, be=24, ft=60, fk=90, bt=-12, bk=16, bf=-30,
          hair=(4, -12, -10), cape=-6),
    ]


def anim_turn():
    return [
        P(lean=-6, tilt=-4, sx=0.82, fa=30, fe=40, ba=-20, be=40, ft=26, fk=10, ff=10, bt=-8, bk=20,
          hair=(8, -16, -12), cape=-14),
        P(lean=2, tilt=0, sx=0.62, fa=14, fe=50, ba=10, be=50, ft=6, fk=12, bt=-4, bk=12,
          hair=(12, -24, -18), cape=-20),
    ]


def anim_rise():
    return [
        P(lean=10, tilt=24, bob=0.6, fa=12, fe=124, fh=-30, ba=16, be=124, bh=-30, ft=3, fk=6, bt=-3, bk=6,
          hair=(10, -18, -16), cape=-6),
        P(lean=8, tilt=12, bob=0.3, fa=10, fe=80, ba=12, be=80, ft=4, fk=6, bt=-4, bk=6,
          hair=(6, -10, -8), cape=-4),
        P(lean=6, tilt=0, fa=8, fe=14, ba=4, be=16, ft=6, fk=4, bt=-6, bk=4,
          hair=(2, -2, 0), cape=0),
        P(lean=8, tilt=-2, fa=-10, fe=20, ba=24, be=20, ft=32, fk=18, ff=6, bt=-16, bk=12, bf=-12,
          hair=(-4, 6, 6), cape=6),
    ]


ANIMS = [
    ("idle", 6, anim_idle, "feet"),
    ("run", 16, anim_run, "feet"),
    ("jump", 4, anim_jump, "air"),
    ("land", 1, anim_land, "feet"),
    ("crouch", 5, anim_crouch, "feet"),
    ("attack", 5, lambda: build_attack(ATK_UP, ATK_LEGS), "feet"),
    ("attack2", 5, lambda: build_attack(ATK2_UP, ATK_LEGS), "feet"),
    ("crouchatk", 5, lambda: build_attack(ATK_UP, ATK_LEGS, True), "feet"),
    ("crouchatk2", 5, lambda: build_attack(ATK2_UP, ATK_LEGS, True), "feet"),
    ("airatk", 5, lambda: build_attack(ATK_UP, AIR_LEGS), "air"),
    ("airatk2", 5, lambda: build_attack(ATK2_UP, AIR_LEGS), "air"),
    ("backdash", 4, anim_backdash, "feet"),
    ("dash", 4, anim_dash, "feet"),
    ("hurt", 2, anim_hurt, "feet"),
    ("cast", 5, anim_cast, "feet"),
    ("dead", 4, anim_dead, "pixels"),
    ("wall", 2, anim_wall, "air"),
    ("walljump", 3, anim_walljump, "air"),
    ("turn", 2, anim_turn, "feet"),
    ("rise", 4, anim_rise, "feet"),
]
OTHER_HAND = {"attack2", "crouchatk2", "airatk2"}
ATTACKS = ["attack", "attack2", "crouchatk", "crouchatk2", "airatk", "airatk2"]
GROUNDED = ["idle", "run", "land", "crouch", "attack", "attack2", "crouchatk", "crouchatk2",
            "backdash", "dash", "hurt", "cast", "turn", "rise"]


# ---------------------------------------------------------------- palette + outline
def build_palette(frames):
    px = np.concatenate([rgb[op] for rgb, op, _ in frames], 0)
    px = np.clip(px, 0, 255).astype(np.uint8)
    strip = Image.fromarray(px.reshape(1, -1, 3), "RGB")
    q = strip.quantize(colors=NCOL, method=Image.Quantize.MEDIANCUT, kmeans=4)
    pal = np.array(q.getpalette()[: NCOL * 3], np.float32).reshape(-1, 3)
    pal = np.unique(pal, axis=0)
    return np.vstack([pal, np.array([OUTLINE], np.float32)])


def finish(rgb, opaque, pal, line=None):
    flat = rgb.reshape(-1, 3)
    d = ((flat[:, None, :] - pal[None, :-1, :]) ** 2).sum(-1)
    idx = d.argmin(1).reshape(opaque.shape)
    out = np.zeros((H, W, 4), np.uint8)
    out[..., :3] = pal[idx].astype(np.uint8)
    out[..., 3] = np.where(opaque, 255, 0)
    o = opaque
    nb = np.zeros_like(o)
    nb[1:] |= o[:-1]
    nb[:-1] |= o[1:]
    nb[:, 1:] |= o[:, :-1]
    nb[:, :-1] |= o[:, 1:]
    ring = nb & ~o
    out[ring, :3] = np.array(OUTLINE, np.uint8)
    out[ring, 3] = 255
    out[~(o | ring)] = 0
    if line is not None:
        out[line, :3] = np.array(OUTLINE, np.uint8)
    return out


# ---------------------------------------------------------------- sheet
def contact_sheet(images, path):
    sc = 3
    per_row = 8
    label_w = 110
    rows = []
    for name, frs in images:
        for i in range(0, len(frs), per_row):
            rows.append((name if i == 0 else "", frs[i:i + per_row], i))
    cw, ch = W * sc, H * sc + 14
    sheet = Image.new("RGBA", (label_w + per_row * cw, len(rows) * ch + 4), (128, 128, 128, 255))
    d = ImageDraw.Draw(sheet)
    for r, (name, frs, start) in enumerate(rows):
        y = r * ch + 2
        d.text((6, y + ch // 2 - 6), name, fill=(255, 255, 255, 255))
        for j, im in enumerate(frs):
            x = label_w + j * cw
            big = im.resize((W * sc, H * sc), Image.NEAREST)
            sheet.alpha_composite(big, (x, y + 12))
            d.rectangle([x, y + 12, x + W * sc - 1, y + 12 + H * sc - 1], outline=(110, 110, 110, 255))
            d.text((x + 3, y), "%02d" % (start + j), fill=(230, 230, 230, 255))
            fx, fy = x + FEET[0] * sc, y + 12 + FEET[1] * sc
            d.line([fx - 4, fy, fx + 4, fy], fill=(255, 40, 40, 255))
            d.line([fx, fy - 4, fx, fy + 4], fill=(255, 40, 40, 255))
    sheet.save(path)


def main():
    os.makedirs(OUT, exist_ok=True)
    parts = load_parts()
    raw = []
    for name, count, fn, mode in ANIMS:
        poses = fn()
        assert len(poses) == count, (name, len(poses), count)
        for i, p in enumerate(poses):
            rgb, op, info = compose(parts, p, mode)
            raw.append((name, i, rgb, op, info))
    pal = build_palette([(r[2], r[3], None) for r in raw])
    for f in os.listdir(OUT):
        if f.endswith(".png") and f != "contact_sheet.png":
            os.remove(os.path.join(OUT, f))
    hands, shoulders, images = {}, {}, {}
    for name, i, rgb, op, info in raw:
        img = Image.fromarray(finish(rgb, op, pal, info["line"]), "RGBA")
        img.save(os.path.join(OUT, "%s_%02d.png" % (name, i)))
        images.setdefault(name, []).append(img)
        other = name in OTHER_HAND
        hands.setdefault(name, []).append(list(info["hand_b" if other else "hand_f"]))
        if name in ATTACKS:
            shoulders.setdefault(name, []).append(list(info["sho_b" if other else "sho_f"]))
    meta = {"faces": "right", "anims": {n: c for n, c, _, _ in ANIMS}, "size": [W, H],
            "feet": list(FEET), "hands": hands, "shoulders": shoulders}
    with open(os.path.join(OUT, "frames_hero.json"), "w") as fh:
        json.dump(meta, fh, indent=1)
    contact_sheet([(n, images[n]) for n, _, _, _ in ANIMS], os.path.join(OUT, "contact_sheet.png"))
    for n in ATTACKS:
        ds = ["%.1f" % math.dist(h, s) for h, s in zip(hands[n], shoulders[n])]
        print("reach %-10s hand-shoulder px: %s  shoulder: %s" % (n, " ".join(ds), shoulders[n]))
    self_check()


def self_check():
    ok = True
    meta = json.load(open(os.path.join(OUT, "frames_hero.json")))
    cols = set()
    for name, count, _, _ in ANIMS:
        files = sorted(f for f in os.listdir(OUT) if f.startswith(name + "_") and f[len(name) + 1:-4].isdigit())
        good = len(files) == count and meta["anims"].get(name) == count and len(meta["hands"][name]) == count
        print("%-10s frames %2d / %2d %s" % (name, len(files), count, "ok" if good else "BAD"))
        ok &= good
        for i in range(count):
            im = np.asarray(Image.open(os.path.join(OUT, "%s_%02d.png" % (name, i))).convert("RGBA"))
            if im.shape[:2] != (H, W):
                print("  size BAD", name, i, im.shape)
                ok = False
            a = im[..., 3]
            if not ((a == 0) | (a == 255)).all():
                print("  partial alpha", name, i)
                ok = False
            if not (a == 255).any():
                print("  EMPTY", name, i)
                ok = False
                continue
            cols |= set(map(tuple, im[a == 255][:, :3].tolist()))
            low = np.nonzero((a == 255).any(1))[0].max()
            if name in GROUNDED and low not in (75, 76):
                print("  ground BAD %s_%02d lowest row %d" % (name, i, low))
                ok = False
    print("distinct colours:", len(cols), "(<= 24)" if len(cols) <= 24 else "TOO MANY")
    ok &= len(cols) <= 24
    print("PASS" if ok else "FAIL")


if __name__ == "__main__":
    main()
