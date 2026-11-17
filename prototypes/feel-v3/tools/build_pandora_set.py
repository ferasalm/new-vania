"""Builds the Pandora hero set (assets/pandora/) from the user's own drawings.

PROTOTYPE tool. Sources, all drawn by the user:
  - idle: 8-south-east.png, with a one-pixel breath
  - run:  the 8 frames of "Idle_v3_running_east (2).gif", unchanged
  - every other clip: the puppet cut from run frame 0 (tools/pandora_rig.py),
    posed by tools/pandora_poses.json
Each frame is upscaled (Scale2x twice), posed, averaged down to game size,
snapped to the user's palette and given a 1-pixel outline.
Also writes the hand/shoulder points of the attack clips into frames.json so the
weapon sits in her hand, and a contact sheet to build/pandora_sheet.png.

    python tools/build_pandora_set.py            # build and wire into frames.json
    python tools/build_pandora_set.py --only jump,slide --sheet-only
"""
import json
import os
import sys

from PIL import Image, ImageSequence

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pandora_rig as R  # noqa: E402

ROOT = R.ROOT
OUT = os.path.join(ROOT, "assets", "pandora")
FRAMES_JSON = os.path.join(ROOT, "assets", "frames.json")
POSES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "pandora_poses.json")
ATTACK_CLIPS = ["attack", "attack2", "crouchatk", "crouchatk2", "airatk", "airatk2"]


def lerp_pose(a: dict, b: dict, t: float) -> dict:
    out = {}
    for k in set(a) | set(b):
        if k.startswith("_"):
            continue
        va, vb = a.get(k, b.get(k)), b.get(k, a.get(k))
        out[k] = va + (vb - va) * t
    return out


def resolve(frame: dict, named: dict) -> dict:
    """a frame = {"_base": name or [name_a, name_b, t], ...overrides}"""
    base = frame.get("_base")
    if isinstance(base, list):
        d = lerp_pose(resolve(named[base[0]], named), resolve(named[base[1]], named), base[2])
    elif isinstance(base, str):
        d = resolve(named[base], named)
    else:
        d = {}
    d.update({k: v for k, v in frame.items() if k != "_base"})
    return d


def end_world(w: dict, bone: str):
    tot, jw, _ = w[bone]
    _, j, e = R.BONES[bone]
    p = R._rot(e, j, tot)
    return (p[0] - j[0] + jw[0], p[1] - j[1] + jw[1])


def main():
    args = sys.argv[1:]
    only = None
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    sheet_only = "--sheet-only" in args
    data = json.load(open(POSES))
    named = data["poses"]
    run0 = R.load_run(0)
    layers = R.caps(R.segment(run0))
    hi_layers = R.layers_up(layers)
    se = Image.open(os.path.join(R.SRC, "8-south-east.png")).convert("RGBA")
    pal = R.palette_of(run0, se)

    # how far her hip sits above her soles when she stands (source pixels)
    sp = R.abs_pose(resolve(named["stand"], named))
    hi, hip = R.render_hi(hi_layers, sp)
    stand_drop = hi.getbbox()[3] / R.UP - hip[1]

    clips = {}
    meta_h, meta_s = {}, {}

    # idle: the user's south-east sprite, breathing one game pixel
    if not only or "idle" in only:
        frames = []
        for shift in data["idle_breath"]:
            img = se.copy()
            if shift:
                top = img.crop((0, 0, img.width, data["idle_breath_row"]))
                img.paste((0, 0, 0, 0), (0, 0, img.width, data["idle_breath_row"] + shift))
                img.alpha_composite(top, (0, shift))
            frames.append(R.to_game_hi(R.up4(img), (data["idle_hip_x"], 0), pal,
                                       ground_src=se.getbbox()[3] - 1))
        clips["idle"] = frames

    # run: the user's own eight drawn frames
    if not only or "run" in only:
        g = Image.open(os.path.join(R.SRC, "Idle_v3_running_east (2).gif"))
        clips["run"] = [R.to_game_hi(R.up4(f.convert("RGBA")), (data["run_hip_x"], 0), pal,
                                     ground_src=data["run_ground"])
                        for f in ImageSequence.Iterator(g)]

    for name, frames in data["clips"].items():
        if only and name not in only:
            continue
        out, hands, shoulders = [], [], []
        for fr in frames:
            d = resolve(fr, named)
            lift = d.pop("_lift", 0)
            air = d.pop("_air", False)
            dx = d.pop("_dx", 0)
            order = d.pop("_order", None)
            pose = R.abs_pose({k: v for k, v in d.items() if not k.startswith("_")}, order=order)
            hi, hip = R.render_hi(hi_layers, pose)
            off = {}
            if air:
                ground = hip[1] + stand_drop - 1
                img = R.to_game_hi(hi, hip, pal, lift=lift, dx_game=dx, ground_src=ground, offset_out=off)
            else:
                img = R.to_game_hi(hi, hip, pal, lift=lift, dx_game=dx, offset_out=off)
            out.append(img)
            w = R.world(pose)
            to_g = lambda p: [round((p[0] * R.UP + off["ox"]) / 8.0, 1), round((p[1] * R.UP + off["oy"]) / 8.0, 1)]
            shoulders.append(to_g(w["arm_f_up"][1]))
            hands.append(to_g(end_world(w, "arm_f_lo")))
        clips[name] = out
        if name in ATTACK_CLIPS:
            meta_h[name], meta_s[name] = hands, shoulders

    # contact sheet (4x), dark background like the game
    rows = list(clips.items())
    cols = max(len(f) for _, f in rows)
    sheet = Image.new("RGBA", (cols * 112, len(rows) * 80), (34, 36, 48, 255))
    for y, (_, frs) in enumerate(rows):
        for x, f in enumerate(frs):
            sheet.alpha_composite(f, (x * 112, y * 80))
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    sheet_path = os.path.join(ROOT, "build", "pandora_sheet.png")
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(sheet_path)
    print("sheet", sheet_path)
    if sheet_only:
        return

    os.makedirs(OUT, exist_ok=True)
    for name, frs in clips.items():
        for i, f in enumerate(frs):
            f.save(os.path.join(OUT, "%s_%02d.png" % (name, i)))
    fj = json.load(open(FRAMES_JSON))
    hero = fj["hero"]
    hero["dir"] = "pandora"
    for name, frs in clips.items():
        hero["anims"][name] = len(frs)
    hero.setdefault("hands", {}).update(meta_h)
    hero.setdefault("shoulders", {}).update(meta_s)
    with open(FRAMES_JSON, "w") as fh:
        json.dump(fj, fh, indent=2)
    print("wrote", sum(len(f) for f in clips.values()), "frames to", OUT)
    print({k: len(v) for k, v in clips.items()})


if __name__ == "__main__":
    main()
