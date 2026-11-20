# PROTOTYPE - NOT FOR PRODUCTION
"""Attacks (decision 27): poses built from joint angles on her own bone lengths, then PixelLab redraws her.
Run from prototypes/feel-v3:

  python -I tools/attack_rig.py poses [move ...]          free: keypoints + a stick-figure preview per move
  python -I tools/attack_rig.py redraw <move> --seed N    PAID (one PixelLab call per move): she is drawn in its poses
  python -I tools/attack_rig.py finish <move> --seed N    free: palette A, 2/3 size once, outline, eye, blade, flash, B
  python -I tools/attack_rig.py sample <move,...> --seed N free: contact sheet + game-speed GIF beside today's frames

Angles are in degrees on the screen: 0 = forward (she faces right), 90 = down, -90 = up, 180 = back.
J attacks with her right hand (RIGHT keypoints: the near side, facing right), I with her left (far) hand.
Her frames carry no weapon: each weapon is its own layer that appears with the swing and dissolves after
(user, 2026-11-19), so one set of body moves serves every weapon of its kind. Paid results are cached; a paid seed is never paid again.
"""
import json
import math
from collections import Counter
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
import jump_rig as jr  # noqa: E402
import gif_to_palette as g2p  # noqa: E402
import harmonize_pandora as hp  # noqa: E402
from pandora_skins import read_gpl, PAL_A, bake_image, swap_map  # noqa: E402

OUT = Path("art_proof/attacks")
REF = jr._load("ref")                       # her own skeleton, read from her palette-A frame (256 canvas)
REF_IMG = Path("art_proof/jump/pass2/ref_a.png")
SIZE = jr.SIZE


def _d(a, b):
    return math.dist(REF[a][:2], REF[b][:2])


MID_HIP = ((REF["RIGHT HIP"][0] + REF["LEFT HIP"][0]) / 2, (REF["RIGHT HIP"][1] + REF["LEFT HIP"][1]) / 2)
GROUND = (REF["RIGHT LEG"][1] + REF["LEFT LEG"][1]) / 2          # her ankles' line
TORSO = math.dist(REF["NECK"][:2], MID_HIP)
NECK_NOSE = _d("NECK", "NOSE")
UPPER, FORE = _d("RIGHT SHOULDER", "RIGHT ELBOW"), _d("RIGHT ELBOW", "RIGHT ARM")
THIGH = max(_d("RIGHT HIP", "RIGHT KNEE"), _d("LEFT HIP", "LEFT KNEE"))
SHIN = max(_d("RIGHT KNEE", "RIGHT LEG"), _d("LEFT KNEE", "LEFT LEG"))
SH_HALF = _d("RIGHT SHOULDER", "LEFT SHOULDER") / 2
HIP_HALF = _d("RIGHT HIP", "LEFT HIP") / 2
FACE = {k: (REF[k][0] - REF["NOSE"][0], REF[k][1] - REF["NOSE"][1]) for k in
        ("LEFT EYE", "RIGHT EYE", "LEFT EAR", "RIGHT EAR")}
Z = {lab: REF[lab][2] for lab in REF}

# ---------------------------------------------------------------- the moves (decision 27)
# Each frame: hx = hips forward (+) or back (-) of her idle hips, lift = feet off the ground, torso = hips->neck
# angle, tw = shoulder/hip turn (+1 = chest to the viewer, as in her idle; 0 = side; -1 = back to the viewer),
# head = head tilt from the torso line, sw = sword (far) arm (upper, fore[, length 0-1 for foreshortening]),
# off = near arm, lead = far leg (thigh, shin), rear = near leg (thigh, shin).
# Dirge-042 swings level (user, 2026-11-19): a horizontal slash, J with the right hand and I the same lunge with
# the left. The blade is given as yaw (0 forward, 90 toward the camera, 180 back, -90 away) and tilt (degrees the
# swing plane leans, + = front end down); seen from the side a level swing is a flat ellipse (FLAT).
# wz: blade in front of her (1) or behind (-1). tr=0: no swoosh into this frame (the recovery).
LEVEL_BEATS = ["wind-up: arm drawn back", "step in: arm comes round", "hit: level lunge", "follow-through", "recover"]
MOVES = {
    "attack": {   # ground J: RIGHT hand (near). The blade comes round in front of her (toward the camera)
        "action": "graceful wide level sweep of the right arm across her body into a deep low lunge",
        "beats": LEVEL_BEATS, "hand": "RIGHT", "hit": 2,
        "frames": [
            dict(hx=-8, torso=-96, tw=1.4, head=26, sw=(150, 185), off=(-15, -5), lead=(45, 62), rear=(68, 116),
                 yaw=180, tilt=-8, wz=1),
            dict(hx=2, torso=-84, tw=0.5, head=30, sw=(160, 15), off=(150, 125), lead=(52, 96), rear=(108, 104),
                 yaw=110, tilt=0, wz=1),
            dict(hx=22, torso=-60, tw=-0.6, head=38, sw=(-15, -8), off=(-165, -140), lead=(12, 92), rear=(142, 142),
                 yaw=0, tilt=6, wz=1),
            dict(hx=24, torso=-62, tw=-0.8, head=40, sw=(0, 25, 0.85), off=(-150, -125), lead=(14, 94),
                 rear=(145, 150), yaw=-40, tilt=4, wz=1),
            dict(hx=8, torso=-84, tw=0.6, head=30, sw=(60, 20), off=(150, 110), lead=(60, 98), rear=(110, 84),
                 yaw=0, tilt=30, wz=1, tr=0),
        ]},
    "attack2": {  # ground I: the same lunge with the LEFT hand (far). The blade comes round behind her, then in front
        "action": "graceful wide level sweep of the left arm across her body into a deep low lunge",
        "beats": LEVEL_BEATS, "hand": "LEFT", "hit": 2,
        "frames": [
            dict(hx=-8, torso=-96, tw=-1.4, head=26, sw=(150, 185), off=(-15, -5), lead=(45, 62), rear=(68, 116),
                 yaw=180, tilt=-8, wz=-1),
            dict(hx=2, torso=-84, tw=-0.5, head=30, sw=(160, 15), off=(150, 125), lead=(52, 96), rear=(108, 104),
                 yaw=-110, tilt=0, wz=-1),
            dict(hx=22, torso=-60, tw=0.6, head=38, sw=(-15, -8), off=(-165, -140), lead=(12, 92), rear=(142, 142),
                 yaw=0, tilt=6, wz=1),
            dict(hx=24, torso=-62, tw=0.8, head=40, sw=(0, 25, 0.85), off=(-150, -125), lead=(14, 94),
                 rear=(145, 150), yaw=40, tilt=4, wz=1),
            dict(hx=8, torso=-84, tw=-0.6, head=30, sw=(60, 20), off=(150, 110), lead=(60, 98), rear=(110, 84),
                 yaw=0, tilt=30, wz=1, tr=0),
        ]},
}
WEAPON = {"tex": "assets/2x/weapon/dirge.png", "grip": (12, 10)}     # player.gd WEAPONS grip (6, 5) at 1x
FLAT = 0.28


def blade_vec(f):
    """The blade on screen, as a vector of length <= 1 (1 = full length, seen side-on)."""
    if "yaw" in f:
        y, t = math.radians(f["yaw"]), math.radians(f.get("tilt", 0))
        x, z = math.cos(y), FLAT * math.sin(y)
        return x * math.cos(t) - z * math.sin(t), x * math.sin(t) + z * math.cos(t)
    a = math.radians(f["wa"] if "wa" in f else f["angle"])
    return math.cos(a), math.sin(a)


def _wrap(d):
    return (d + 180) % 360 - 180


def blade_at(a, b, u):
    """The blade between two frames (u 0..1): a level swing turns its yaw the short way round, else the angle."""
    if "yaw" in a and "yaw" in b:
        return blade_vec({"yaw": a["yaw"] + _wrap(b["yaw"] - a["yaw"]) * u,
                          "tilt": a.get("tilt", 0) + (b.get("tilt", 0) - a.get("tilt", 0)) * u})
    va, vb = blade_vec(a), blade_vec(b)
    aa, ab = math.atan2(va[1], va[0]), math.atan2(vb[1], vb[0])
    ang = aa + math.radians(_wrap(math.degrees(ab - aa))) * u
    ln = math.hypot(*va) + (math.hypot(*vb) - math.hypot(*va)) * u
    return math.cos(ang) * ln, math.sin(ang) * ln


def turn(a, b):
    """How far the blade turned between two frames, in degrees."""
    if "yaw" in a and "yaw" in b:
        return abs(_wrap(b["yaw"] - a["yaw"]))
    va, vb = blade_vec(a), blade_vec(b)
    return abs(_wrap(math.degrees(math.atan2(vb[1], vb[0]) - math.atan2(va[1], va[0]))))


# ---------------------------------------------------------------- forward kinematics
def _dir(a):
    return math.cos(math.radians(a)), math.sin(math.radians(a))


def _add(p, a, length):
    d = _dir(a)
    return p[0] + d[0] * length, p[1] + d[1] * length


def build(f, hand="LEFT"):
    """One frame's 18 keypoints (pixels on the 256 canvas) from its angles."""
    tw, hx, lift = f.get("tw", 1.0), f.get("hx", 0), f.get("lift", 0)
    hip = (MID_HIP[0] + hx, 0.0)
    perp = _dir(f["torso"] + 90)                       # forward, square to the torso line
    k = {}
    k["NECK"] = _add(hip, f["torso"], TORSO)
    k["LEFT SHOULDER"] = (k["NECK"][0] + perp[0] * SH_HALF * tw, k["NECK"][1] + perp[1] * SH_HALF * tw)
    k["RIGHT SHOULDER"] = (k["NECK"][0] - perp[0] * SH_HALF * tw, k["NECK"][1] - perp[1] * SH_HALF * tw)
    k["LEFT HIP"] = (hip[0] + perp[0] * HIP_HALF * tw, hip[1] + perp[1] * HIP_HALF * tw)
    k["RIGHT HIP"] = (hip[0] - perp[0] * HIP_HALF * tw, hip[1] - perp[1] * HIP_HALF * tw)
    k["NOSE"] = _add(k["NECK"], f["torso"] + f.get("head", 30), NECK_NOSE)
    other = "RIGHT" if hand == "LEFT" else "LEFT"
    for side, arm in ((hand, f["sw"]), (other, f["off"])):
        s = arm[2] if len(arm) > 2 else 1.0
        k[side + " ELBOW"] = _add(k[side + " SHOULDER"], arm[0], UPPER * s)
        k[side + " ARM"] = _add(k[side + " ELBOW"], arm[1], FORE * s)
    for side, leg in ((hand, f["lead"]), (other, f["rear"])):
        k[side + " KNEE"] = _add(k[side + " HIP"], leg[0], THIGH)
        k[side + " LEG"] = _add(k[side + " KNEE"], leg[1], SHIN)
    tilt = math.radians(f.get("head", 30) - 30 + f["torso"] + 85)
    for lab, (dx, dy) in FACE.items():
        k[lab] = (k["NOSE"][0] + dx * math.cos(tilt) - dy * math.sin(tilt),
                  k["NOSE"][1] + dx * math.sin(tilt) + dy * math.cos(tilt))
    dy = GROUND - lift - max(k["LEFT LEG"][1], k["RIGHT LEG"][1])
    return {lab: (x, y + dy, Z[lab]) for lab, (x, y) in k.items()}


def move_poses(move):
    return [build(f, MOVES[move].get("hand", "LEFT")) for f in MOVES[move]["frames"]]


def _ghost():
    im = Image.open(REF_IMG).convert("RGBA")
    a = im.getchannel("A").point(lambda v: v * 45 // 255)
    im.putalpha(a)
    return im


def _weapon_img():
    return Image.open(WEAPON["tex"]).convert("RGBA")


def step_poses(moves):
    OUT.mkdir(parents=True, exist_ok=True)
    S = 2
    ghost = _ghost().resize((SIZE * S, SIZE * S), Image.NEAREST)
    sheet = Image.new("RGB", (SIZE * S * 5, SIZE * S * len(moves)), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    wlen = (_weapon_img().width - WEAPON["grip"][0]) / FACTOR       # blade length on the 256 canvas
    hilt = WEAPON["grip"][0] / FACTOR
    for r, move in enumerate(moves):
        poses = move_poses(move)
        (OUT / "rig").mkdir(parents=True, exist_ok=True)
        (OUT / "rig" / f"{move}.json").write_text(json.dumps(
            {"ref": jr._as_api(REF), "poses": [jr._as_api(p) for p in poses], "beats": MOVES[move]["beats"]}, indent=1))
        for i, p in enumerate(poses):
            f = MOVES[move]["frames"][i]
            ox, oy = i * SIZE * S, r * SIZE * S
            sheet.paste(ghost, (ox, oy), ghost)
            d.line([(ox, oy + GROUND * S), (ox + SIZE * S, oy + GROUND * S)], fill=(70, 70, 80))
            side = MOVES[move].get("hand", "LEFT")
            other = "RIGHT" if side == "LEFT" else "LEFT"
            near = {k: v for k, v in p.items() if not k.startswith(side)}
            far = {k: v for k, v in p.items() if not k.startswith(other)}
            hand = p[side + " ARM"]
            c, sn = blade_vec(f)
            seg = [(ox + (hand[0] - c * hilt) * S, oy + (hand[1] - sn * hilt) * S),
                   (ox + (hand[0] + c * wlen) * S, oy + (hand[1] + sn * wlen) * S)]
            if f["wz"] < 0:
                d.line(seg, fill=(90, 150, 170), width=3)
            jr._draw(d, far, (255, 170, 60), ox, oy, S)     # attacking side in orange
            jr._draw(d, near, (120, 255, 160), ox, oy, S)   # other side in green
            if f["wz"] >= 0:
                d.line(seg, fill=(160, 240, 255), width=3)
            d.text((ox + 6, oy + 6), f"{move} {i}: {MOVES[move]['beats'][i]}", fill=(255, 255, 0))
    out = OUT / "poses_plan.png"
    sheet.save(out)
    print("wrote", out)


# ---------------------------------------------------------------- PixelLab (paid)
def batch_dir(moves, seed):
    return OUT / "raw" / ("+".join(moves) + f"_seed{seed}")


def step_redraw(moves, seed):
    """One paid call for several moves (3-15 frames; price by frames: 3 = 2, 8 = 3, 15 = 4 generations)."""
    raw = batch_dir(moves, seed)
    if raw.exists() and any(raw.glob("*.png")):
        raise SystemExit(f"{raw} already exists: this seed was paid for; use finish, or another seed.")
    rigs = {m: json.loads((OUT / "rig" / f"{m}.json").read_text()) for m in moves}
    poses = [p for m in moves for p in rigs[m]["poses"]]
    if not 3 <= len(poses) <= 15:
        raise SystemExit(f"{len(poses)} frames: one call takes 3 to 15")
    action = "; then ".join(MOVES[m]["action"] for m in moves)
    payload = {"description": jr.DESCRIPTION, "action": action, "direction": "east", "view": "side",
               "first_frame": jr._b64(Image.open(REF_IMG)), "first_frame_keypoints": rigs[moves[0]]["ref"],
               "keypoints": poses, "seed": seed, "no_background": True}
    r = jr._call("POST", "/animate-with-skeleton-v3", payload)
    job = r.get("background_job_id")
    print("job", job, r.get("status"), "frames", len(poses))
    deadline, res = time.time() + 1500, None
    while time.time() < deadline:
        time.sleep(8)
        j = jr._call("GET", f"/background-jobs/{job}")
        st = j.get("status")
        if st == "completed":
            res = j.get("last_response", j)
            break
        if st == "failed":
            raise SystemExit("job failed: " + json.dumps(j)[:600])
    if res is None:
        raise SystemExit("timed out; job id " + str(job))
    raw.mkdir(parents=True, exist_ok=True)
    imgs = res.get("images") or []
    k = 0
    for m in moves:
        for n in range(len(rigs[m]["poses"])):
            if k < len(imgs):
                jr._unb64(imgs[k]).save(raw / f"{m}_{n:02d}.png")
            k += 1
        (raw / f"{m}.rig.json").write_text(json.dumps(rigs[m]))
    (raw / "usage.json").write_text(json.dumps({"usage": res.get("usage"), "job": job, "frames": len(poses)}, indent=1))
    print("saved", len(imgs), "frames to", raw)


# ---------------------------------------------------------------- finish (free)
FACTOR = g2p.TARGET_PX / (Image.open(REF_IMG).getbbox()[3] - Image.open(REF_IMG).getbbox()[1])   # 90 px, once
OFFSET = (27, -11)            # where the shrunk 256 canvas sits on the 224 x 160 game canvas (her idle's place)


def _place(roles):
    """Fixed placement (not by bounding box), so her feet and hips do not jump between frames."""
    out = [[0] * g2p.CANVAS[0] for _ in range(g2p.CANVAS[1])]
    for y, row in enumerate(roles):
        for x, v in enumerate(row):
            X, Y = x + OFFSET[0], y + OFFSET[1]
            if v and 0 <= X < g2p.CANVAS[0] and 0 <= Y < g2p.CANVAS[1]:
                out[Y][X] = v
    return out


def _map(p):
    return p[0] * FACTOR + OFFSET[0], p[1] * FACTOR + OFFSET[1]


def _hand(roles, pose, side="LEFT"):
    """The fist: start at the wrist keypoint, step along the forearm while still on her body."""
    h, w = len(roles), len(roles[0])
    (ex, ey), (wx, wy) = _map(pose[side + " ELBOW"]), _map(pose[side + " ARM"])
    a = math.atan2(wy - ey, wx - ex)
    dx, dy = math.cos(a), math.sin(a)
    on = lambda x, y: 0 <= round(x) < w and 0 <= round(y) < h and roles[round(y)][round(x)]  # noqa: E731
    if not on(wx, wy):
        near = [(abs(x - wx) + abs(y - wy), x, y) for y in range(int(wy) - 6, int(wy) + 7)
                for x in range(int(wx) - 6, int(wx) + 7) if on(x, y)]
        if near:
            _d0, wx, wy = min(near)
    x, y = wx, wy
    for _ in range(4):
        if not on(x + dx, y + dy):
            break
        x, y = x + dx, y + dy
    return (x, y), a


def _thin(roles, k):
    """Pixels of her silhouette in parts narrower than 2k+1 px (an opening with a square of that size)."""
    h, w = len(roles), len(roles[0])
    m = {(x, y) for y in range(h) for x in range(w) if roles[y][x]}
    er = {p for p in m if all((p[0] + a, p[1] + b) in m for a in range(-k, k + 1) for b in range(-k, k + 1))}
    op = {(p[0] + a, p[1] + b) for p in er for a in range(-k, k + 1) for b in range(-k, k + 1)}
    return m - op


def strip_painted_blades(roles, hand, elbow, reach=85):
    """PixelLab sometimes paints a sword in her fist. Her frames carry no weapon, so every thin, straight run that
    starts at the fist is erased (the ray from the fist with the most thin pixels), then the sword's round guard is
    trimmed back to a fist: only pixels near the forearm line stay within 5 px of the fist."""
    thin = _thin(roles, 2)
    hx, hy = hand
    removed = 0
    for _ in range(2):                                 # a second blade (both hands painted) is rare but seen
        best = None
        back = math.degrees(math.atan2(elbow[1] - hy, elbow[0] - hx))      # her own forearm: never a blade
        for deg in range(0, 360, 2):
            if abs((deg - back + 180) % 360 - 180) < 60:
                continue
            dx, dy = math.cos(math.radians(deg)), math.sin(math.radians(deg))
            hits, gap, last, first = 0, 0, 0, 0
            for r in range(3, reach):
                x, y = round(hx + dx * r), round(hy + dy * r)
                if any((x + a, y + b) in thin for a in (-1, 0, 1) for b in (-1, 0, 1)):
                    hits, gap, last, first = hits + 1, 0, r, first or r
                elif first:
                    gap += 1
                    if gap > 4:
                        break
                elif r > 12:
                    break
            if hits >= 8 and last - first >= 10 and (best is None or hits > best[0]):
                best = (hits, deg, last, first)
        if not best:
            break
        _h, deg, last, first = best
        dx, dy = math.cos(math.radians(deg)), math.sin(math.radians(deg))
        for (x, y) in list(thin):
            t = (x - hx) * dx + (y - hy) * dy
            if first - 2 <= t <= last + 2 and abs(-(x - hx) * dy + (y - hy) * dx) <= 2.6:
                roles[y][x] = 0
                thin.discard((x, y))
                removed += 1
    if removed:
        h, w = len(roles), len(roles[0])
        ex, ey = elbow
        L = math.dist((ex, ey), (hx, hy)) or 1.0
        ux, uy = (hx - ex) / L, (hy - ey) / L
        for y in range(int(hy) - 6, int(hy) + 7):
            for x in range(int(hx) - 6, int(hx) + 7):
                if not (0 <= x < w and 0 <= y < h) or not roles[y][x] or math.dist((x, y), (hx, hy)) > 5.5:
                    continue
                t = max(0.0, min(L + 1.5, (x - ex) * ux + (y - ey) * uy))
                if math.dist((x, y), (ex + ux * t, ey + uy * t)) > 2.2:
                    roles[y][x] = 0
                    removed += 1
        for y in range(int(hy) - 8, int(hy) + 9):            # fresh edges get her 1 px outline
            for x in range(int(hx) - 8, int(hx) + 9):
                if 0 < x < w - 1 and 0 < y < h - 1 and roles[y][x] and \
                        0 in (roles[y][x + 1], roles[y][x - 1], roles[y + 1][x], roles[y - 1][x]):
                    roles[y][x] = 1
    return hp.drop_strays(roles, 4), removed


def clean_fist(roles, hand, elbow, r=2.6):
    """After a painted sword is erased, its guard leaves claw-like scraps. Clear thin bits around the fist that are
    off the forearm line, then stamp a plain round fist in the forearm's own colours with her 1 px outline."""
    h, w = len(roles), len(roles[0])
    hx, hy = hand
    ex, ey = elbow
    L = math.dist((ex, ey), (hx, hy)) or 1.0
    ux, uy = (hx - ex) / L, (hy - ey) / L

    def off_arm(x, y):
        t = max(0.0, min(L, (x - ex) * ux + (y - ey) * uy))
        return math.dist((x, y), (ex + ux * t, ey + uy * t))
    tones = Counter()
    for t in range(3, 10):
        for a in (-1, 0, 1):
            x, y = round(hx - ux * t - uy * a), round(hy - uy * t + ux * a)
            if 0 <= x < w and 0 <= y < h and roles[y][x] not in (0, 1):
                tones[roles[y][x]] += 1
    fill = tones.most_common(1)[0][0] if tones else 8
    light = max(tones) if tones else 9
    thin = _thin(roles, 1) | {p for p in _thin(roles, 2) if math.dist(p, (hx, hy)) <= 8}
    for (x, y) in thin:
        if math.dist((x, y), (hx, hy)) <= 11 and off_arm(x, y) > 2.2:
            roles[y][x] = 0
    cx, cy = hx - ux * 0.5, hy - uy * 0.5
    for y in range(int(cy) - 4, int(cy) + 5):
        for x in range(int(cx) - 4, int(cx) + 5):
            if not (0 <= x < w and 0 <= y < h):
                continue
            d = math.dist((x, y), (cx, cy))
            if d <= r - 1:
                roles[y][x] = fill
            elif d <= r + 0.4:
                roles[y][x] = 1
    lx, ly = round(cx - uy * 0.9 - 0.4), round(cy - 1)              # one lit knuckle on the top
    if 0 <= lx < w and 0 <= ly < h and roles[ly][lx] not in (0, 1):
        roles[ly][lx] = light
    for y in range(int(hy) - 13, int(hy) + 14):                   # fresh edges get her outline
        for x in range(int(hx) - 13, int(hx) + 14):
            if 0 < x < w - 1 and 0 < y < h - 1 and roles[y][x] and \
                    0 in (roles[y][x + 1], roles[y][x - 1], roles[y + 1][x], roles[y - 1][x]):
                roles[y][x] = 1
    return hp.drop_strays(roles, 4)


def keep_main(roles, gap=3):
    """Drop loose pieces (left from painted props) that sit more than `gap` px from her main body."""
    h, w = len(roles), len(roles[0])
    seen, comps = set(), []
    for y0 in range(h):
        for x0 in range(w):
            if not roles[y0][x0] or (x0, y0) in seen:
                continue
            comp, stack = [], [(x0, y0)]
            seen.add((x0, y0))
            while stack:
                x, y = stack.pop()
                comp.append((x, y))
                for a in (-1, 0, 1):
                    for b in (-1, 0, 1):
                        q = (x + a, y + b)
                        if 0 <= q[0] < w and 0 <= q[1] < h and roles[q[1]][q[0]] and q not in seen:
                            seen.add(q)
                            stack.append(q)
            comps.append(comp)
    if len(comps) < 2:
        return roles
    comps.sort(key=len, reverse=True)
    near = {(x + a, y + b) for (x, y) in comps[0] for a in range(-gap, gap + 1) for b in range(-gap, gap + 1)}
    for comp in comps[1:]:
        if not any(p in near for p in comp):
            for (x, y) in comp:
                roles[y][x] = 0
    return roles


def fin_dir(move, seed):
    return OUT / f"v2_seed{seed}" / move


def flash(roles):
    """Hit frame: her eyes and seams flash to the bright glow."""
    return [[12 if v == 11 else v for v in row] for row in roles]


def step_finish(moves, seed):
    """Her body frames (no weapon: the weapon is its own layer) plus the weapon track for the game:
    per frame the fist (224 x 160 canvas), the blade angle and whether the blade is in front of her."""
    raw = batch_dir(moves, seed)
    pal, mapping = read_gpl(PAL_A), swap_map()
    for move in moves:
        rig = json.loads((raw / f"{move}.rig.json").read_text())
        poses = [{k["label"]: (k["x"] * SIZE, k["y"] * SIZE) for k in p} for p in rig["poses"]]
        fa, fb = fin_dir(move, seed) / "a", fin_dir(move, seed) / "b"
        fa.mkdir(parents=True, exist_ok=True)
        fb.mkdir(parents=True, exist_ok=True)
        spec = MOVES[move]
        track = []
        for n, f in enumerate(sorted(raw.glob(f"{move}_[0-9]*.png"))):
            img = Image.open(f).convert("RGBA")
            roles = _place(g2p.clean(g2p.shrink(jr.to_roles(img, pal), FACTOR)))
            roles = hp.drop_strays(roles)
            for region, mix in hp.TONE_MIX.items():
                roles = hp.retone(roles, region, mix)
            roles, _eye = hp.eye_from_rig(roles, rig["poses"][n], img)
            if n == spec["hit"]:
                roles = flash(roles)
            (hx, hy), _a = _hand(roles, poses[n], spec.get("hand", "LEFT"))
            side = spec.get("hand", "LEFT")
            roles, gone = strip_painted_blades(roles, (hx, hy), _map(poses[n][side + " ELBOW"]))
            other = "RIGHT" if spec.get("hand", "LEFT") == "LEFT" else "LEFT"
            if gone:
                roles = clean_fist(roles, (hx, hy), _map(poses[n][side + " ELBOW"]))
            oh = _hand(roles, poses[n], other)[0]
            roles, gone2 = strip_painted_blades(roles, oh, _map(poses[n][other + " ELBOW"]))
            if gone2:
                roles = clean_fist(roles, oh, _map(poses[n][other + " ELBOW"]))
            gone += gone2
            roles = keep_main(hp.drop_strays(roles, 40))   # loose blade pieces left behind
            if gone:
                print(f.name, "painted blade erased:", gone, "px")
            fr = spec["frames"][n]
            vx, vy = blade_vec(fr)
            level = {"yaw": fr["yaw"], "tilt": fr.get("tilt", 0)} if "yaw" in fr else {}
            track.append({"hand": [round(hx), round(hy)], "angle": round(math.degrees(math.atan2(vy, vx)), 1),
                          "len": round(math.hypot(vx, vy), 3), **level, "front": fr["wz"] >= 0,
                          "trail": bool(fr.get("tr", 1)),
                          "shoulder": [round(v) for v in _map(poses[n][spec.get("hand", "LEFT") + " SHOULDER"])]})
            a = hp.paint(roles, pal)
            a.save(fa / f"{move}_{n:02d}.png")
            bake_image(a, mapping).save(fb / f"{move}_{n:02d}.png")
            print(f.name, "box", a.getbbox(), "hand", track[-1]["hand"], "off-palette", jr.off_palette(a, pal)[0])
        (fin_dir(move, seed) / "weapon_track.json").write_text(json.dumps(track, indent=1))
    print("finished", moves)


# ---------------------------------------------------------------- the weapon layer (preview of the game's)
def glow_colours(skin):
    pal = read_gpl(PAL_A)
    if skin == "b":
        m = swap_map()
        pal = [m.get(c, c) for c in pal]
    return pal[10], pal[11]                    # glow base, glow bright


def weapon_for(skin):
    """The actual Dirge. Skin B: its cyan blade tones become her red glow, by lightness; dark steel stays."""
    w = _weapon_img()
    if skin != "b":
        return w
    base, bright = glow_colours("b")
    px = w.load()
    for y in range(w.height):
        for x in range(w.width):
            r, g, b, al = px[x, y]
            if al and b > r + 40 and g > r + 20:              # cyan family
                t = min(1.0, max(0.0, (max(g, b) - 90) / 160))
                px[x, y] = tuple(round(base[i] + (bright[i] - base[i]) * t) for i in range(3)) + (al,)
    return w


def _rotated(w, angle, grip=None):
    """The weapon turned about its grip; returns the image and where the grip lands in it."""
    gx, gy = grip or WEAPON["grip"]
    pad = max(w.size) + 4
    canvas = Image.new("RGBA", (pad * 2, pad * 2), (0, 0, 0, 0))
    canvas.paste(w, (pad - gx, pad - gy), w)
    return canvas.rotate(-angle, resample=Image.NEAREST, center=(pad, pad)), (pad, pad)


def _halo(img, colour):
    """A 1 px glow around the weapon, in her glow colour."""
    a = img.getchannel("A")
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    px, ap = out.load(), a.load()
    for y in range(1, img.height - 1):
        for x in range(1, img.width - 1):
            if not ap[x, y] and any(ap[x + dx, y + dy] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                px[x, y] = colour + (150,)
    out.alpha_composite(img)
    return out


def _noise(x, y):
    return ((x * 73856093) ^ (y * 19349663) ^ 0x5bd1e995) % 1009 / 1009


def _phase(img, mode, t, colour):
    """The weapon appearing ("in": pixels arrive, the newest glow) or dissolving ("out": pixels leave as glowing
    sparks that drift up). A preview of the game's weapon shader."""
    if mode == "solid":
        return img
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    src, dst = img.load(), out.load()
    lift = round(2 + 7 * t)
    for y in range(img.height):
        for x in range(img.width):
            if not src[x, y][3]:
                continue
            n = _noise(x, y)
            if mode == "in":
                if n < t:
                    dst[x, y] = colour + (255,) if n > t - 0.2 else src[x, y]
            else:
                if n >= t:
                    dst[x, y] = colour + (255,) if n < t + 0.12 else src[x, y]
                elif n >= t - 0.3 and y - lift >= 0:
                    dst[x + (1 if n * 100 % 2 > 1 else 0) if x + 1 < img.width else x, y - lift] = colour + (190,)
    return out


PAD = 40          # preview only: room above her head for a raised blade (the game draws the weapon unclipped)
PADX = 40         # and in front of her for the lunge


def _pad(img):
    out = Image.new("RGBA", (img.width + PADX, img.height + PAD), (0, 0, 0, 0))
    out.paste(img, (0, PAD))
    return out


def _shift(tr):
    return None if tr is None else {**tr, "hand": [tr["hand"][0], tr["hand"][1] + PAD],
                                    "shoulder": [tr["shoulder"][0], tr["shoulder"][1] + PAD]}


PHASES = {0: ("in", 0.55), 4: ("out", 0.35)}       # frame -> weapon phase; frames 1-3 solid


def compose(body, tr, skin, prev=None, phase=("solid", 0.0)):
    """Body plus the weapon layer (behind or in front), plus a swoosh: the band the outer blade swept through
    since the last frame (hand and blade both interpolated; a level swing traces a flat ellipse), thick at the
    new end and thin at the old. A blade pointing toward or away from the camera is drawn shorter."""
    body, tr, prev = _pad(body), _shift(tr), _shift(prev)
    w = weapon_for(skin)
    base, bright = glow_colours(skin)
    ln = tr.get("len", 1.0)
    gx0, gy0 = WEAPON["grip"]
    ws = w.resize((max(6, round(w.width * ln)), w.height), Image.NEAREST) if ln < 0.98 else w
    rot, (gx, gy) = _rotated(ws, tr["angle"], (round(gx0 * ws.width / w.width), gy0))
    rot = _phase(_halo(rot, base), phase[0], phase[1], bright)
    pos = (tr["hand"][0] - gx, tr["hand"][1] - gy)
    weapon = Image.new("RGBA", body.size, (0, 0, 0, 0))
    weapon.paste(rot, pos, rot)
    arc = None
    if prev is not None and tr.get("trail", True) and turn(prev, tr) > 30 and phase[0] == "solid":
        arc = Image.new("RGBA", body.size, (0, 0, 0, 0))
        d = ImageDraw.Draw(arc)
        reach = w.width - gx0
        outer, inner = [], []
        for k in range(25):
            u = k / 24                                     # 0 = last frame, 1 = this frame
            hx = prev["hand"][0] + (tr["hand"][0] - prev["hand"][0]) * u
            hy = prev["hand"][1] + (tr["hand"][1] - prev["hand"][1]) * u
            vx, vy = blade_at(prev, tr, u)
            band = 0.08 + 0.42 * u ** 1.5                  # share of the blade the band covers
            outer.append((hx + vx * reach, hy + vy * reach))
            inner.append((hx + vx * reach * (1 - band), hy + vy * reach * (1 - band)))
        d.polygon(outer + inner[::-1], fill=bright + (105,))
        d.line(outer[6:], fill=bright + (230,), width=2)
    out = Image.new("RGBA", body.size, (0, 0, 0, 0))
    layers = ([body, arc, weapon] if tr["front"] else [arc, weapon, body])
    for layer in layers:
        if layer is not None:
            out.alpha_composite(layer)
    return out


def _stick(pose, side):
    """A stick figure of one planned pose on the game's 224 x 160 canvas (attacking side orange)."""
    img = Image.new("RGBA", (224, 160), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    m = {lab: _map(v[:2]) for lab, v in pose.items()}
    other = "RIGHT" if side == "LEFT" else "LEFT"
    bones = [("NECK", "NOSE"), ("LEFT SHOULDER", "RIGHT SHOULDER"), ("LEFT HIP", "RIGHT HIP")]
    for s in (other, side):
        bones += [(f"{s} SHOULDER", f"{s} ELBOW"), (f"{s} ELBOW", f"{s} ARM"), (f"{s} HIP", f"{s} KNEE"),
                  (f"{s} KNEE", f"{s} LEG"), (f"{s} SHOULDER", f"{s} HIP")]
    for a, b in bones:
        col = (255, 170, 60, 255) if a.startswith(side) and "HIP" not in b else (200, 210, 225, 255)
        d.line([m[a], m[b]], fill=col, width=3)
    nx, ny = m["NOSE"]
    d.ellipse([nx - 6, ny - 7, nx + 4, ny + 3], outline=(200, 210, 225, 255), width=2)
    return img


def step_plan(moves):
    """Free preview before any drawing: the planned poses as stick figures, with the real Dirge layer, its swoosh
    and the appear / dissolve, at game speed and slowed down."""
    cells, durs = {m: [] for m in moves}, []
    for m in moves:
        spec = MOVES[m]
        side = spec.get("hand", "LEFT")
        poses = move_poses(m)
        track = []
        for i, (p, f) in enumerate(zip(poses, spec["frames"])):
            vx, vy = blade_vec(f)
            level = {"yaw": f["yaw"], "tilt": f.get("tilt", 0)} if "yaw" in f else {}
            track.append({"hand": [round(v) for v in _map(p[side + " ARM"][:2])],
                          "angle": math.degrees(math.atan2(vy, vx)), "len": math.hypot(vx, vy), **level,
                          "front": f["wz"] >= 0, "trail": bool(f.get("tr", 1)),
                          "shoulder": [round(v) for v in _map(p[side + " SHOULDER"][:2])]})
        for i, p in enumerate(poses):
            cells[m].append(compose(_stick(p, side), track[i], "a", track[i - 1] if i else None,
                                    PHASES.get(i, ("solid", 0))))
    n = max(len(v) for v in cells.values())
    bg = Image.new("RGB", (224 + PADX, 160 + PAD), (38, 34, 58))
    ImageDraw.Draw(bg).rectangle([0, 153 + PAD, 224 + PADX, 160 + PAD], fill=(92, 72, 110))
    frames = []
    for j in range(n):
        panel = Image.new("RGB", ((224 + PADX) * len(moves), 160 + PAD))
        for c, m in enumerate(moves):
            cell = bg.copy()
            cell.paste(cells[m][j], (0, 0), cells[m][j])
            panel.paste(cell, (c * (224 + PADX), 0))
        panel = panel.resize((panel.width * 2, panel.height * 2), Image.NEAREST)
        dd = ImageDraw.Draw(panel)
        for c, m in enumerate(moves):
            dd.text((c * (224 + PADX) * 2 + 8, 8), f"{'J (right hand)' if m == 'attack' else 'I (left hand)'}: "
                    f"{MOVES[m]['beats'][j]}", fill=(255, 255, 255))
        frames.append(panel)
    sheet = Image.new("RGB", (frames[0].width // 2 * n // len(moves) * len(moves), frames[0].height), (0, 0, 0))
    sheet = Image.new("RGB", ((224 + PADX) * n, (160 + PAD) * len(moves)))
    for c, m in enumerate(moves):
        for j in range(n):
            cell = bg.copy()
            cell.paste(cells[m][j], (0, 0), cells[m][j])
            sheet.paste(cell, (j * (224 + PADX), c * (160 + PAD)))
    sheet = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
    sheet.save(OUT / "plan_level_sheet.png")
    for name, d in (("gamespeed", 80), ("slow", 400)):
        gif = OUT / f"plan_level_{name}.gif"
        frames[0].save(gif, save_all=True, append_images=frames[1:] + [frames[-1]], duration=[d] * n + [600],
                       loop=0, disposal=2)
        print("wrote", gif)




def step_sample(moves, seed):
    """A contact sheet (today, A, B) and game-speed GIFs: today's swings beside the new ones in A and B."""
    S = 3
    box = (0, 0, 224 + PADX, 160 + PAD)
    cw, ch = (box[2] - box[0]) * S, (box[3] - box[1]) * S
    rows = []
    for m in moves:
        n = len(MOVES[m]["frames"])
        new = fin_dir(m, seed)
        track = json.loads((new / "weapon_track.json").read_text())
        rows.append((m, "today", [_pad(Image.open(f"assets/2x/pandora/{m}_{i:02d}.png").convert("RGBA"))
                                  for i in range(n)]))
        rows.append((m, "body A", [_pad(Image.open(new / "a" / f"{m}_{i:02d}.png").convert("RGBA")) for i in range(n)]))
        for k in ("a", "b"):
            rows.append((m, f"+Dirge {k.upper()}", [compose(Image.open(new / k / f"{m}_{i:02d}.png").convert("RGBA"),
                         track[i], k, track[i - 1] if i else None, PHASES.get(i, ("solid", 0))) for i in range(n)]))
    sheet = Image.new("RGB", (120 + 5 * cw, len(rows) * (ch + 20)), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    for r, (m, lab, imgs) in enumerate(rows):
        y = r * (ch + 20)
        d.text((6, y + ch // 2), f"{'J' if m == 'attack' else 'I'} {lab}", fill=(255, 255, 0))
        for i, im in enumerate(imgs):
            c = im.crop(box).resize((cw, ch), Image.NEAREST)
            sheet.paste(c, (120 + i * cw, y + 18), c)
            if lab == "today":
                d.text((120 + i * cw + 4, y + 2), MOVES[m]["beats"][i], fill=(220, 220, 220))
    out = OUT / f"sample2_seed{seed}_sheet.png"
    sheet.save(out)
    print("wrote", out)
    # game speed: 0.4 s per swing (tuning attack_time), 5 frames = 80 ms each; idle before and after;
    # after the last swing the weapon finishes dissolving over her idle (two more 80 ms steps)
    bg = Image.new("RGB", (224 + PADX, 160 + PAD), (38, 34, 58))       # plain church dusk, floor under her feet
    ImageDraw.Draw(bg).rectangle([0, 153 + PAD, 224 + PADX, 160 + PAD], fill=(92, 72, 110))
    idle = Image.open("assets/2x/pandora/idle_00.png").convert("RGBA")
    cells = {"today": [], "new A": [], "new B": []}
    durs = []
    order = [(None, None, None)] + [(m, i, None) for m in moves for i in range(len(MOVES[m]["frames"]))]
    order += [(None, None, ("out", 0.65)), (None, None, ("out", 0.9)), (None, None, None)]
    last = json.loads((fin_dir(moves[-1], seed) / "weapon_track.json").read_text())[-1]
    for m, i, tail in order:
        if m is None:
            cells["today"].append(_pad(idle))
            for k in ("a", "b"):
                cells[f"new {k.upper()}"].append(compose(idle, last, k, None, tail) if tail else _pad(idle))
            durs.append(80 if tail else 600)
            continue
        track = json.loads((fin_dir(m, seed) / "weapon_track.json").read_text())
        cells["today"].append(_pad(Image.open(f"assets/2x/pandora/{m}_{i:02d}.png").convert("RGBA")))
        for k in ("a", "b"):
            body = Image.open(fin_dir(m, seed) / k / f"{m}_{i:02d}.png").convert("RGBA")
            cells[f"new {k.upper()}"].append(compose(body, track[i], k, track[i - 1] if i else None,
                                                     PHASES.get(i, ("solid", 0))))
        durs.append(80)
    frames = []
    for j in range(len(durs)):
        panel = Image.new("RGB", ((224 + PADX) * 3, 160 + PAD))
        for p, k in enumerate(cells):
            cell = bg.copy()
            cell.paste(cells[k][j], (0, 0), cells[k][j])
            panel.paste(cell, (p * (224 + PADX), 0))
        panel = panel.resize((panel.width * 2, panel.height * 2), Image.NEAREST)
        dd = ImageDraw.Draw(panel)
        for p, k in enumerate(cells):
            dd.text((p * (224 + PADX) * 2 + 8, 8), k, fill=(255, 255, 255))
        frames.append(panel)
    for name, ds in (("gamespeed", durs), ("slow", [600 if x == 600 else 320 for x in durs])):
        gif = OUT / f"sample2_seed{seed}_{name}.gif"
        frames[0].save(gif, save_all=True, append_images=frames[1:], duration=ds, loop=0, disposal=2)
        print("wrote", gif)


def step_install(moves, seed):
    """Put the finished frames into the game (skin A and B), their weapon keys into assets/frames.json
    (hero.weapon.<anim>: per frame the hand on the 224x160 canvas, the blade angle, in front or behind),
    and bake the glowing Dirge textures (1 px halo; skin B recoloured) as weapon/dirge_glow(_b).png."""
    fj = Path("assets/frames.json")
    meta = json.loads(fj.read_text())
    keys = meta["hero"].setdefault("weapon", {})
    for m in moves:
        n = len(MOVES[m]["frames"])
        for k, folder in (("a", "pandora"), ("b", "pandora_b")):
            for i in range(n):
                Image.open(fin_dir(m, seed) / k / f"{m}_{i:02d}.png").save(Path("assets/2x") / folder / f"{m}_{i:02d}.png")
        track = json.loads((fin_dir(m, seed) / "weapon_track.json").read_text())
        keep = ("hand", "angle", "len", "yaw", "tilt", "front", "trail")
        keys[m] = [{k: t[k] for k in keep if k in t} for t in track]
        print("installed", m, n, "frames + weapon keys")
    fj.write_text(json.dumps(meta, indent=2) + "\n")
    for skin in ("a", "b"):
        w = weapon_for(skin)
        big = Image.new("RGBA", (w.width + 2, w.height + 2), (0, 0, 0, 0))
        big.paste(w, (1, 1))
        out = Path("assets/2x/weapon") / ("dirge_glow.png" if skin == "a" else "dirge_glow_b.png")
        _halo(big, glow_colours(skin)[0]).save(out)
        print("baked", out, "grip", (WEAPON["grip"][0] + 1, WEAPON["grip"][1] + 1))


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    seed = int(sys.argv[sys.argv.index("--seed") + 1]) if "--seed" in sys.argv else 9
    args = [a for a in sys.argv[2:] if not a.startswith("--") and a != str(seed)]
    moves = args[0].split(",") if args else list(MOVES)
    if cmd == "poses":
        step_poses(moves)
    elif cmd == "redraw":
        step_redraw(moves, seed)
    elif cmd == "finish":
        step_finish(moves, seed)
    elif cmd == "sample":
        step_sample(moves, seed)
    elif cmd == "plan":
        step_plan(moves)
    elif cmd == "install":
        step_install(moves, seed)
    else:
        print(__doc__)
