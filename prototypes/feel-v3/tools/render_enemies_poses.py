"""Pose tables for tools/render_enemies.py (imported inside Blender).

Armature space: +X screen right, +Y away from camera, +Z up. A positive turn about Y is clockwise on
screen, so "raise" on the model's left side (+X) is a negative Y turn and on the right side (-X) a positive one.
"""

import math



def sin01(i, n, phase=0.0):
    return math.sin(2 * math.pi * (i / n + phase))


def cos01(i, n, phase=0.0):
    return math.cos(2 * math.pi * (i / n + phase))


def lerp(a, b, t):
    return a + (b - a) * t


def ease(t):
    return t * t * (3 - 2 * t)


def rest(i):
    return {"ops": [], "obj": {}}


SIDE = {"Left": -1.0, "Right": 1.0}  # sign of a Y turn that lifts that side's limb


def lift(side, bone, deg):
    """Raise a limb bone of `side` by deg (screen plane)."""
    return ("rot", f"{side}{bone}", "y", SIDE[side] * deg)


# ------------------------------------------------------------------ crab
CRAB_SZ = 0.45

# arm directions (Arm, ForeArm, Claw, Pincer) in left-side coordinates: x outward, y toward camera = -, z up
GUARD = ((0.6, -0.3, 0.25), (0.15, -0.25, 0.95), (-0.2, -0.3, 0.9), (-0.35, -0.3, 0.85))
RAISED = ((0.45, -0.25, 0.85), (0.1, -0.2, 1.0), (-0.1, -0.2, 1.0), (-0.3, -0.2, 0.95))
LOW = ((0.7, -0.25, -0.1), (0.3, -0.3, -0.6), (-0.1, -0.3, -0.7), (-0.3, -0.4, -0.6))


def blend_dirs(a, b, t):
    return tuple(tuple(lerp(u, v, t) for u, v in zip(da, db)) for da, db in zip(a, b))


def arm_op(side, dirs, pincer=0.0):
    sgn = 1.0 if side == "Left" else -1.0

    def op(sc):
        pos = sc.head(f"{side}Arm")
        for part, d in zip(("Arm", "ForeArm", "Claw", "Pincer"), dirs):
            sc.aim(f"{side}{part}", pos, (d[0] * sgn, d[1], d[2]))
            pos = sc.tail(f"{side}{part}")
        if pincer:
            sc.turn(f"{side}Pincer", "y", SIDE[side] * pincer)
    return ("call", op)


def crab_pose(sz=CRAB_SZ, arms=GUARD, legs=None, bob=0.0, yaw=5, dz=0.0, sx=1.0, extra=None, pincer=(0.0, 0.0)):
    ops = []
    if bob:
        ops.append(("move", "Shell", (0, 0, bob)))
    ops.append(arm_op("Left", arms, pincer[0]))
    ops.append(arm_op("Right", arms, pincer[1]))
    if legs:
        ops += legs
    return {"ops": ops, "obj": {"sz": sz, "sx": sx, "yaw": yaw, "dz": dz}, "extra": extra or {}}


def crab_idle(i):
    n = 4
    s = sin01(i, n)
    tw = [(0, 0), (14, 0), (0, 0), (0, -14)][i]
    arms = blend_dirs(GUARD, LOW, 0.12 + 0.06 * s)
    return crab_pose(sz=CRAB_SZ * (1 + 0.04 * s), arms=arms, pincer=tw, bob=0.02 * s)


def crab_legs(t, amp=9.0, lift_amt=14.0):
    ops = []
    groups = {"Left1": 0.0, "Right2": 0.0, "Left3": 0.0, "Right1": 0.5, "Left2": 0.5, "Right3": 0.5}
    for key, off in groups.items():
        side, num = key[:-1], key[-1]
        ph = t + off
        shift = amp * math.cos(2 * math.pi * ph)
        up = lift_amt * max(0.0, -math.sin(2 * math.pi * ph))
        ops.append(("rot", f"{side}Leg{num}", "y", shift))
        ops.append(("rot", f"{side}Leg{num}Segment2", "y", SIDE[side] * up))
    return ops


def crab_walk(i):
    n = 6
    t = i / n
    bob = 0.03 * abs(math.sin(2 * math.pi * t * 2)) - 0.01
    arms = blend_dirs(GUARD, LOW, 0.1 + 0.05 * math.sin(2 * math.pi * t * 2))
    return crab_pose(sz=CRAB_SZ, arms=arms, legs=crab_legs(t), bob=bob, pincer=(5 * math.sin(2 * math.pi * t), -5 * math.sin(2 * math.pi * t)))


def crab_rear(i):
    k = [0.25, 0.6, 0.9, 1.0][i]
    kk = ease(k)
    legs = []
    for side in ("Left", "Right"):
        legs.append(lift(side, "Leg1", 30 * kk))
        legs.append(lift(side, "Leg2", 22 * kk))
        legs.append(lift(side, "Leg1Segment2", 8 * kk))
    arms = blend_dirs(GUARD, RAISED, kk)
    pin = (12 * kk, 12 * kk) if i < 3 else (18, -18)
    return crab_pose(sz=lerp(CRAB_SZ, 0.57, kk), sx=lerp(1.0, 0.8, kk), arms=arms, legs=legs, bob=0.12 * kk, yaw=lerp(5, 0, kk), pincer=pin)


# world units of drop to bury a crab completely at sz 0.45 (total height ~0.9)
BURY = 0.8


def crab_burrow(i):
    n = 5
    t = i / (n - 1)
    drop = BURY * [0.0, 0.2, 0.42, 0.62, 0.8][i]
    legs = []
    for side in ("Left", "Right"):  # legs fold in as it sinks
        legs.append(lift(side, "Leg1", -10 * t))
    p = crab_pose(sz=CRAB_SZ * (1 - 0.1 * t), arms=blend_dirs(GUARD, LOW, 0.2 + 0.3 * t), legs=legs, dz=-drop, sx=1.0,
                  pincer=(6 * math.sin(i * 2.4), -6 * math.sin(i * 2.4)))
    p["extra"] = {"clip_ground": True}
    return p


def crab_emerge(i):
    # reverse of burrow with a pop: frame 2 overshoots upward, frame 3 lands
    ts = [0.7, 0.22, -0.14, 0.0]   # fraction buried (negative = hop above ground)
    sz_mul = [0.92, 1.0, 1.2, 0.95]
    frac = ts[i]
    drop = BURY * frac
    arms = blend_dirs(GUARD, RAISED, [0.1, 0.7, 1.0, 0.1][i])
    legs = []
    for side in ("Left", "Right"):
        legs.append(lift(side, "Leg1", [0, 20, 40, 0][i]))
        legs.append(lift(side, "Leg2", [0, 10, 25, 0][i]))
    p = crab_pose(sz=CRAB_SZ * sz_mul[i], arms=arms, legs=legs, dz=-drop, sx=[1.0, 1.0, 0.92, 1.0][i])
    p["extra"] = {"clip_ground": True}
    return p


# ------------------------------------------------------------------ moth
def moth_wings(up, tip=0.55, lower=0.55, lag=0.0):
    """up = degrees the upper wing is raised (negative = flapped down)."""
    ops = []
    for side in ("Left", "Right"):
        ops += [lift(side, "Wing", up), lift(side, "WingTip", up * tip + lag), lift(side, "LowerWing", up * lower), lift(side, "LowerWingTip", up * lower * tip + lag * 0.5)]
    return ops


def moth_fly(i):
    n = 6
    s = sin01(i, n)
    s2 = sin01(i, n, -0.12)
    up = 4 + 19 * s
    ops = moth_wings(up, tip=0.55 + 0.25 * (s2 - s), lag=0)
    ops.append(("rot", "Abdomen1", "y", 5 * sin01(i, n, -0.25)))
    ops.append(("rot", "Abdomen3", "y", 8 * sin01(i, n, -0.35)))
    return {"ops": ops, "obj": {"dz": -0.04 * s}}


def moth_gust(i):
    ups = [34, 58, 60, -36]
    lag = [-8, -14, -14, 20][i]
    ops = moth_wings(ups[i], tip=0.5, lag=lag)
    dz = [0.0, -0.06, -0.06, 0.1][i]
    ops.append(("rot", "Abdomen2", "y", [0, 4, -4, -14][i]))
    return {"ops": ops, "obj": {"dz": dz}}


def moth_swing(i):
    # one sweep of the censer: far left, through the bottom, far right
    ang = [-78, -52, -20, 18, 52, 80][i]
    ops = moth_wings(8 + 10 * math.sin(i * 1.3), tip=0.5)
    ops.append(("rot", "Abdomen1", "y", ang * 0.55))
    ops.append(("rot", "Abdomen2", "y", ang * 0.3))
    ops.append(("rot", "Abdomen3", "y", ang * 0.2))
    ops.append(("rot", "Censer", "y", ang * 0.15))
    ops.append(("rot", "Thorax", "y", -ang * 0.12))
    return {"ops": ops, "obj": {}}


def moth_dive(i):
    # head-first dive: moth flipped head-down, wings swept back (toward the tail) so they trail up behind it
    k = [0.75, 1.0][i]
    ops = moth_wings(-80 * k, tip=0.25, lower=0.85)
    ops.append(("rot", "Abdomen2", "y", 0))
    return {"ops": ops, "obj": {"roll": 180, "dz": 0.0}}


# ------------------------------------------------------------------ scribe
def hand_px(sc):
    """Screen position (final canvas px) of the right hand, so the post step can draw glyphs near it."""
    from mathutils import Vector
    pb = sc.rig.pose.bones["RightHand"]
    p = sc.rig.matrix_world @ (pb.tail + Vector((0, 0, 0)))
    import numpy as np
    x, y = sc.to_px(np.array([[p.x, p.y, p.z]]))
    return {"hand_px": [float(x[0]), float(y[0])]}


def scribe_base(spine=4, legs_back=14):
    ops = [("rot", "Spine", "x", spine), ("rot", "Spine1", "x", spine * 0.5)]
    for side in ("Left", "Right"):
        ops += [("rot", f"{side}UpLeg", "x", legs_back), ("rot", f"{side}Leg", "x", legs_back * 1.3), ("rot", f"{side}Foot", "x", 10)]
    return ops


def scribe_idle(i):
    n = 6
    s = sin01(i, n)
    ops = scribe_base(spine=5 + 1.5 * s, legs_back=10 + 3 * sin01(i, n, -0.15))
    ops += [("rot", "LeftArm", "x", -6 + 5 * s), ("rot", "LeftForeArm", "x", -14 + 6 * s),
            ("rot", "RightArm", "x", -16 - 4 * s), ("rot", "RightForeArm", "x", -30 - 5 * s),
            ("rot", "Head", "x", -4 * s)]
    return {"ops": ops, "obj": {"dz": 0.045 * s}}


def scribe_write(i):
    n = 6
    a = 2 * math.pi * i / n
    ops = scribe_base(spine=7, legs_back=10)
    ops += [("rot", "LeftArm", "x", -8), ("rot", "LeftForeArm", "x", -30),
            ("rot", "RightArm", "x", -46 + 9 * math.sin(a)), ("rot", "RightForeArm", "x", -10 + 14 * math.cos(a)),
            ("rot", "RightHand", "x", 14 * math.sin(a * 2)), ("rot", "Head", "x", 5)]
    return {"ops": ops, "obj": {"dz": 0.02 * math.sin(a)}, "extra": {"write": i}, "extra_fn": hand_px}


def scribe_throw(i):
    arm = [(46, -30, 10), (-30, -34, 0), (-66, -6, -8), (-40, -20, 0)][i]
    spine = [-8, 12, 14, 6][i]
    ops = scribe_base(spine=spine, legs_back=[8, 6, 4, 8][i])
    ops += [("rot", "RightArm", "x", arm[0]), ("rot", "RightForeArm", "x", arm[1]), ("rot", "RightHand", "x", arm[2]),
            ("rot", "LeftArm", "x", [-4, 8, 16, -6][i]), ("rot", "LeftForeArm", "x", [-8, -20, -20, -20][i])]
    return {"ops": ops, "obj": {"dx": [-0.05, 0.06, 0.1, 0.03][i]}}


def scribe_melt(i):
    k = [0.0, 0.2, 0.45, 0.72, 0.97][i]
    ops = scribe_base(spine=5 + 14 * k, legs_back=lerp(12, 20, k))
    ops += [("rot", "LeftArm", "x", lerp(-6, 25, k)), ("rot", "RightArm", "x", lerp(-16, 25, k)),
            ("rot", "Head", "x", lerp(0, 20, k))]
    return {"ops": ops, "obj": {"sz": lerp(1.0, 0.85, k), "sx": lerp(1.0, 1.1, k), "dz": -1.9 * k}, "extra": {"melt": k, "clip_y": 108}}


# ------------------------------------------------------------------ leech
def leech_chain(sc, angles, top_x=0.06):
    """Straighten the spine chain, give each segment an absolute lean `angles[k]` (deg, in the screen
    plane, + = toward +X when pointing down), then slide the whole body so the tail tip hangs at top_x."""
    from mathutils import Vector
    names = [f"Spine{k}" for k in range(1, 13)]
    pos = sc.head("Spine1")
    for name, ang in zip(names, angles):
        a = math.radians(ang)
        d = Vector((math.sin(a), 0.0, -math.cos(a)))
        sc.aim(name, pos, d)
        pos = sc.tail(name)
    tip = sc.tail("Spine12")
    sc.move("Head", (top_x - tip.x, 0.0, 0.0))  # the whole body follows its parent so the thread end stays put
    return tip


def leech_pose(wave_t=0.0, amp=14.0, sway=0.0, jaw=0.0, scale=(1.0, 1.0)):
    def op(sc):
        angles = [sway + amp * (1 - k / 13.0) * math.sin(2 * math.pi * (wave_t - k / 5.0)) for k in range(12)]
        leech_chain(sc, angles)
        sc.turn("Jaw1", "x", -jaw)
        sc.turn("Jaw2", "x", jaw)
        sc.turn("Jaw3", "x", jaw)
    return {"ops": [("call", op)], "obj": {"roll": 180, "pivot": "top", "sx": scale[0], "sz": scale[1]}}


def leech_hang(i):
    n = 4
    return leech_pose(wave_t=i / n, amp=16.0, sway=4 * sin01(i, n, 0.1), jaw=[6, 24, 36, 18][i])


def leech_drop(i):
    return leech_pose(wave_t=0.0, amp=1.5, jaw=[46, 58][i], scale=(0.9, 1.1))


def leech_latch(i):
    # clamped onto its victim: mouth wide and pressed, body pulses fat/thin
    return leech_pose(wave_t=0.0, amp=5.0, sway=[-2, 0, -2, 0][i], jaw=[34, 26, 34, 26][i], scale=[(1.12, 0.96), (0.94, 1.04), (1.12, 0.96), (0.94, 1.04)][i])


# ------------------------------------------------------------------ organ
def organ_idle(i):
    return {"ops": [], "obj": {}, "extra": {"pulse": [0.0, 0.6, 1.0, 0.6][i]}}


ANIMS = {
    "crab": {"idle": (4, crab_idle), "walk": (6, crab_walk), "rear": (4, crab_rear), "burrow": (5, crab_burrow), "emerge": (4, crab_emerge)},
    "moth": {"fly": (6, moth_fly), "gust": (4, moth_gust), "swing": (6, moth_swing), "dive": (2, moth_dive)},
    "scribe": {"idle": (6, scribe_idle), "write": (6, scribe_write), "throw": (4, scribe_throw), "melt": (5, scribe_melt)},
    "leech": {"hang": (4, leech_hang), "drop": (2, leech_drop), "latch": (4, leech_latch)},
    "organ": {"idle": (4, organ_idle)},
}
