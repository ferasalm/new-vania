# PROTOTYPE - NOT FOR PRODUCTION
"""Attacks (decision 27): poses built from joint angles on her own bone lengths, then PixelLab redraws her.
Run from prototypes/feel-v3:

  python -I tools/attack_rig.py poses [move ...]          free: keypoints + a stick-figure preview per move
  python -I tools/attack_rig.py redraw <move> --seed N    PAID (one PixelLab call per move): she is drawn in its poses
  python -I tools/attack_rig.py finish <move> --seed N    free: palette A, 2/3 size once, outline, eye, blade, flash, B
  python -I tools/attack_rig.py sample <move,...> --seed N free: contact sheet + game-speed GIF beside today's frames

Angles are in degrees on the screen: 0 = forward (she faces right), 90 = down, -90 = up, 180 = back.
Her sword is in the far hand (LEFT keypoints): her chest and face stay turned to the viewer, as in her idle.
The near arm (RIGHT) balances. Paid results are cached; a paid seed is never paid again.
"""
import json
import math
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
MOVES = {
    "attack": {   # ground J: a quick horizontal cut, a fencer's lunge; weight from the back foot to the front
        "action": "graceful fencer lunging forward, arm sweeping straight out at shoulder height",
        "beats": ["wind-up", "step in", "hit: lunge", "follow-through", "recover"],
        "blade": [2, 3], "hit": 2,
        "frames": [
            dict(hx=-8, torso=-96, tw=0.7, head=28, sw=(-150, -125), off=(20, -30), lead=(50, 70), rear=(80, 110)),
            dict(hx=4, torso=-82, tw=0.9, head=30, sw=(-10, 175, 0.8), off=(150, 120), lead=(48, 92), rear=(118, 105)),
            dict(hx=16, torso=-66, tw=1.0, head=34, sw=(-6, -4), off=(-168, -140), lead=(28, 96), rear=(140, 148)),
            dict(hx=18, torso=-70, tw=1.2, head=36, sw=(25, 40, 0.85), off=(-150, -120), lead=(30, 98), rear=(135, 160)),
            dict(hx=6, torso=-86, tw=0.9, head=30, sw=(55, 5), off=(150, 110), lead=(62, 98), rear=(108, 82)),
        ]},
    "attack2": {  # ground I: a rising, turning backhand; she rises onto her front toe, the rear leg lifts behind
        "action": "graceful dancer rising onto her toes and turning, arm sweeping upward",
        "beats": ["wind-up: low", "rise and turn", "hit: arabesque", "follow-through", "recover"],
        "blade": [2, 3], "hit": 2,
        "frames": [
            dict(hx=2, torso=-74, tw=1.3, head=36, sw=(110, 160, 0.9), off=(130, 70), lead=(55, 112), rear=(112, 70)),
            dict(hx=6, torso=-80, tw=0.4, head=28, sw=(70, 30), off=(160, 140), lead=(80, 96), rear=(125, 120)),
            dict(hx=8, lift=6, torso=-74, tw=-0.3, head=20, sw=(-40, -55), off=(170, 150), lead=(86, 92), rear=(160, 168)),
            dict(hx=6, lift=4, torso=-88, tw=-0.9, head=12, sw=(-85, -105), off=(150, 120), lead=(88, 90), rear=(140, 120)),
            dict(hx=2, torso=-86, tw=0.6, head=28, sw=(45, 15), off=(120, 80), lead=(66, 100), rear=(106, 84)),
        ]},
}


# ---------------------------------------------------------------- forward kinematics
def _dir(a):
    return math.cos(math.radians(a)), math.sin(math.radians(a))


def _add(p, a, length):
    d = _dir(a)
    return p[0] + d[0] * length, p[1] + d[1] * length


def build(f):
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
    for side, arm in (("LEFT", f["sw"]), ("RIGHT", f["off"])):
        s = arm[2] if len(arm) > 2 else 1.0
        k[side + " ELBOW"] = _add(k[side + " SHOULDER"], arm[0], UPPER * s)
        k[side + " ARM"] = _add(k[side + " ELBOW"], arm[1], FORE * s)
    for side, leg in (("LEFT", f["lead"]), ("RIGHT", f["rear"])):
        k[side + " KNEE"] = _add(k[side + " HIP"], leg[0], THIGH)
        k[side + " LEG"] = _add(k[side + " KNEE"], leg[1], SHIN)
    tilt = math.radians(f.get("head", 30) - 30 + f["torso"] + 85)
    for lab, (dx, dy) in FACE.items():
        k[lab] = (k["NOSE"][0] + dx * math.cos(tilt) - dy * math.sin(tilt),
                  k["NOSE"][1] + dx * math.sin(tilt) + dy * math.cos(tilt))
    dy = GROUND - lift - max(k["LEFT LEG"][1], k["RIGHT LEG"][1])
    return {lab: (x, y + dy, Z[lab]) for lab, (x, y) in k.items()}


def move_poses(move):
    return [build(f) for f in MOVES[move]["frames"]]


def _ghost():
    im = Image.open(REF_IMG).convert("RGBA")
    a = im.getchannel("A").point(lambda v: v * 45 // 255)
    im.putalpha(a)
    return im


def step_poses(moves):
    OUT.mkdir(parents=True, exist_ok=True)
    S = 2
    ghost = _ghost().resize((SIZE * S, SIZE * S), Image.NEAREST)
    sheet = Image.new("RGB", (SIZE * S * 5, SIZE * S * len(moves)), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    for r, move in enumerate(moves):
        poses = move_poses(move)
        (OUT / "rig").mkdir(parents=True, exist_ok=True)
        (OUT / "rig" / f"{move}.json").write_text(json.dumps(
            {"ref": jr._as_api(REF), "poses": [jr._as_api(p) for p in poses], "beats": MOVES[move]["beats"]}, indent=1))
        for i, p in enumerate(poses):
            ox, oy = i * SIZE * S, r * SIZE * S
            sheet.paste(ghost, (ox, oy), ghost)
            d.line([(ox, oy + GROUND * S), (ox + SIZE * S, oy + GROUND * S)], fill=(70, 70, 80))
            near = {k: v for k, v in p.items() if not k.startswith("LEFT")}
            far = {k: v for k, v in p.items() if not k.startswith("RIGHT")}
            jr._draw(d, far, (255, 170, 60), ox, oy, S)     # sword side (far) in orange
            jr._draw(d, near, (120, 255, 160), ox, oy, S)   # near side in green
            hand, elbow = p["LEFT ARM"], p["LEFT ELBOW"]
            if i in MOVES[move]["blade"]:
                a = math.atan2(hand[1] - elbow[1], hand[0] - elbow[0])
                d.line([(ox + hand[0] * S, oy + hand[1] * S),
                        (ox + (hand[0] + math.cos(a) * 70) * S, oy + (hand[1] + math.sin(a) * 70) * S)],
                       fill=(200, 230, 255), width=2)
            d.text((ox + 6, oy + 6), f"{move} {i}: {MOVES[move]['beats'][i]}", fill=(255, 255, 0))
    out = OUT / "poses_preview.png"
    sheet.save(out)
    print("wrote", out)


# ---------------------------------------------------------------- PixelLab (paid)
def step_redraw(move, seed):
    raw = OUT / "raw" / f"{move}_seed{seed}"
    if raw.exists() and any(raw.glob("*.png")):
        raise SystemExit(f"{raw} already exists: this seed was paid for; use finish, or another seed.")
    rig = json.loads((OUT / "rig" / f"{move}.json").read_text())
    payload = {"description": jr.DESCRIPTION, "action": MOVES[move]["action"], "direction": "east", "view": "side",
               "first_frame": jr._b64(Image.open(REF_IMG)), "first_frame_keypoints": rig["ref"],
               "keypoints": rig["poses"], "seed": seed, "no_background": True}
    r = jr._call("POST", "/animate-with-skeleton-v3", payload)
    job = r.get("background_job_id")
    print("job", job, r.get("status"), "usage", r.get("usage"))
    deadline, res = time.time() + 1200, None
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
    for n, obj in enumerate(imgs):
        jr._unb64(obj).save(raw / f"{move}_{n:02d}.png")
    (raw / "rig.json").write_text(json.dumps(rig))
    (raw / "usage.json").write_text(json.dumps({"usage": res.get("usage"), "job": job}, indent=1))
    print("saved", len(imgs), "frames to", raw, "usage", res.get("usage"))


# ---------------------------------------------------------------- finish (free)
FACTOR = g2p.TARGET_PX / (Image.open(REF_IMG).getbbox()[3] - Image.open(REF_IMG).getbbox()[1])   # 90 px, once
OFFSET = (27, -11)            # where the shrunk 256 canvas sits on the 224 x 160 game canvas (her idle's place)
BLADE_LEN = 46                # final pixels: about half her height
OUTLINE, STEEL_D, STEEL_L, ACCENT, SHINE = 1, 13, 14, 15, 16


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


def _hand(roles, pose):
    """The fist: start at the wrist keypoint, step along the forearm while still on her body."""
    h, w = len(roles), len(roles[0])
    (ex, ey), (wx, wy) = _map(pose["LEFT ELBOW"]), _map(pose["LEFT ARM"])
    a = math.atan2(wy - ey, wx - ex)
    dx, dy = math.cos(a), math.sin(a)
    on = lambda x, y: 0 <= round(x) < w and 0 <= round(y) < h and roles[round(y)][round(x)]  # noqa: E731
    if not on(wx, wy):
        near = [(abs(x - wx) + abs(y - wy), x, y) for y in range(int(wy) - 6, int(wy) + 7)
                for x in range(int(wx) - 6, int(wx) + 7) if on(x, y)]
        if near:
            _d0, wx, wy = min(near)
    x, y = wx, wy
    for _ in range(10):
        if not on(x + dx, y + dy):
            break
        x, y = x + dx, y + dy
    return (x, y), a


def add_blade(roles, pose):
    """A slim sword in her far hand: 2 px steel with a bright top edge, a brass guard, a 1 px dark outline."""
    h, w = len(roles), len(roles[0])
    (hx, hy), a = _hand(roles, pose)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx                                   # square to the blade
    if ny > 0:                                         # the "top" edge is the one facing up
        nx, ny = -nx, -ny
    pix = {}
    steps = int(BLADE_LEN * 2)
    for i in range(steps + 1):
        t = i / 2
        cx, cy = hx + dx * (t + 1), hy + dy * (t + 1)
        pix[(round(cx), round(cy))] = STEEL_L
        if t < BLADE_LEN - 7:                          # 2 px wide, then a 1 px point
            pix.setdefault((round(cx + nx), round(cy + ny)), SHINE)
    for s in (-2, -1, 1, 2):                           # guard at the fist
        pix[(round(hx + dx * 1.5 + nx * s), round(hy + dy * 1.5 + ny * s))] = ACCENT
    for (x, y), v in pix.items():
        if 0 <= x < w and 0 <= y < h:
            roles[y][x] = v
    for (x, y) in list(pix):
        for ax, ay in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            X, Y = x + ax, y + ay
            if 0 <= X < w and 0 <= Y < h and not roles[Y][X]:
                roles[Y][X] = OUTLINE
    return roles


def flash(roles):
    """Hit frame: her eyes and seams flash to the bright glow."""
    return [[12 if v == 11 else v for v in row] for row in roles]


def step_finish(move, seed):
    raw = OUT / "raw" / f"{move}_seed{seed}"
    rig = json.loads((raw / "rig.json").read_text())
    poses = [{k["label"]: (k["x"] * SIZE, k["y"] * SIZE) for k in p} for p in rig["poses"]]
    fa, fb = OUT / f"{move}_seed{seed}" / "a", OUT / f"{move}_seed{seed}" / "b"
    fa.mkdir(parents=True, exist_ok=True)
    fb.mkdir(parents=True, exist_ok=True)
    pal, mapping = read_gpl(PAL_A), swap_map()
    spec = MOVES[move]
    meta = {"hands": [], "shoulders": []}
    for n, f in enumerate(sorted(raw.glob(f"{move}_*.png"))):
        img = Image.open(f).convert("RGBA")
        roles = _place(g2p.clean(g2p.shrink(jr.to_roles(img, pal), FACTOR)))
        roles = hp.drop_strays(roles)
        for region, mix in hp.TONE_MIX.items():
            roles = hp.retone(roles, region, mix)
        roles, _eye = hp.eye_from_rig(roles, rig["poses"][n], img)
        if n == spec["hit"]:
            roles = flash(roles)
        if n in spec["blade"]:
            roles = add_blade(roles, poses[n])
        (hx, hy), _a = _hand(roles, poses[n])
        meta["hands"].append([round(hx), round(hy)])
        meta["shoulders"].append([round(v) for v in _map(poses[n]["LEFT SHOULDER"])])
        a = hp.paint(roles, pal)
        a.save(fa / f"{move}_{n:02d}.png")
        bake_image(a, mapping).save(fb / f"{move}_{n:02d}.png")
        bb = a.getbbox()
        print(f.name, "box", bb, "off-palette", jr.off_palette(a, pal)[0] if hasattr(jr, "off_palette") else "-")
    (OUT / f"{move}_seed{seed}" / "points.json").write_text(json.dumps(meta))
    print("wrote", fa, fb)


def _church():
    return Image.open("shots/1_church_start.png").convert("RGB")


def step_sample(moves, seed):
    """A contact sheet (raw, A, B, today) and a game-speed GIF: today's combo beside the new one, A and B."""
    S = 3
    box = (40, 20, 224, 158)                           # the part of the game canvas she uses
    cw, ch = (box[2] - box[0]) * S, (box[3] - box[1]) * S
    rows = []
    for m in moves:
        n = len(MOVES[m]["frames"])
        new = OUT / f"{m}_seed{seed}"
        rows.append((f"{m} today", [Image.open(f"assets/2x/pandora/{m}_{i:02d}.png").convert("RGBA") for i in range(n)]))
        rows.append((f"{m} new A", [Image.open(new / "a" / f"{m}_{i:02d}.png") for i in range(n)]))
        rows.append((f"{m} new B", [Image.open(new / "b" / f"{m}_{i:02d}.png") for i in range(n)]))
    sheet = Image.new("RGB", (110 + 5 * cw, len(rows) * (ch + 20)), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    for r, (lab, imgs) in enumerate(rows):
        y = r * (ch + 20)
        d.text((6, y + ch // 2), lab, fill=(255, 255, 0))
        for i, im in enumerate(imgs):
            c = im.crop(box).resize((cw, ch), Image.NEAREST)
            sheet.paste(c, (110 + i * cw, y + 18), c)
            if r % 3 == 0:
                d.text((110 + i * cw + 4, y + 2), MOVES[lab.split()[0]]["beats"][i], fill=(220, 220, 220))
    out = OUT / f"sample_seed{seed}_sheet.png"
    sheet.save(out)
    print("wrote", out)
    # game speed: 0.4 s per swing (tuning attack_time), 5 frames = 80 ms each; idle before and after
    bg = _church().crop((60, 70, 60 + 112, 70 + 80)).resize((224, 160), Image.NEAREST)
    idle = Image.open("assets/2x/pandora/idle_00.png").convert("RGBA")
    seqs = [("today", "assets/2x/pandora/{m}_{i:02d}.png")] + [
        (k, str(OUT / f"{{m}}_seed{seed}" / k.lower()[-1] / "{m}_{i:02d}.png")) for k in ("new A", "new B")]
    frames, durs = [], []
    order = [(None, None)] * 1 + [(m, i) for m in moves for i in range(len(MOVES[m]["frames"]))] + [(None, None)]
    for m, i in order:
        panel = Image.new("RGB", (224 * 3, 160))
        for p, (lab, pat) in enumerate(seqs):
            cell = bg.copy()
            f = idle if m is None else Image.open(pat.format(m=m, i=i)).convert("RGBA")
            cell.paste(f, (0, 0), f)
            panel.paste(cell, (p * 224, 0))
        panel = panel.resize((panel.width * 2, panel.height * 2), Image.NEAREST)
        dd = ImageDraw.Draw(panel)
        for p, (lab, _pat) in enumerate(seqs):
            dd.text((p * 448 + 8, 8), lab, fill=(255, 255, 255))
        frames.append(panel)
        durs.append(600 if m is None else 80)
    gif = OUT / f"sample_seed{seed}_gamespeed.gif"
    frames[0].save(gif, save_all=True, append_images=frames[1:], duration=durs, loop=0, disposal=2)
    slow = OUT / f"sample_seed{seed}_slow.gif"
    frames[0].save(slow, save_all=True, append_images=frames[1:], duration=[600 if x == 600 else 320 for x in durs],
                   loop=0, disposal=2)
    print("wrote", gif, slow)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    seed = int(sys.argv[sys.argv.index("--seed") + 1]) if "--seed" in sys.argv else 9
    args = [a for a in sys.argv[2:] if not a.startswith("--") and a != str(seed)]
    if cmd == "poses":
        step_poses(args or list(MOVES))
    elif cmd == "redraw":
        step_redraw(args[0], seed)
    elif cmd == "finish":
        step_finish(args[0], seed)
    elif cmd == "sample":
        step_sample(args[0].split(","), seed)
    else:
        print(__doc__)
