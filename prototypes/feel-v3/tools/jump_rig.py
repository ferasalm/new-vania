# PROTOTYPE - NOT FOR PRODUCTION
"""Jump pass 2: the rig plus PixelLab (decision 26, sprites.md 5 and 6). Run from prototypes/feel-v3.

  python -I tools/jump_rig.py ref                free: her palette-A frame on a 256 x 256 canvas
  python -I tools/jump_rig.py skeletons          PAID 0.8 generation: PixelLab reads 8 skeletons (cached)
  python -I tools/jump_rig.py retarget           free: the 7 poses scaled to her body, plus a preview picture
  python -I tools/jump_rig.py redraw --seed N    PAID 3 generations: PixelLab draws her in the 7 poses
  python -I tools/jump_rig.py finish --seed N    free: palette A, 2/3 size once, outline, check, bake B, sheet, GIF

The rig: PixelLab's 18-joint skeleton, read from each chosen frame of the user's jump GIFs. Each pose is scaled
so its bones match her own (the median ratio of four bone lengths, one scale per GIF), centred on her hips, feet on the ground
line. PixelLab then redraws her approved palette-A frame in every pose. The key comes from PIXELLAB_API_KEY
(or the Windows user environment) and is never printed. Paid results are cached; a cached step is never paid again.
"""
import base64
import io
import json
import os
import statistics
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandora_skins import read_gpl, PAL_A, bake_image, swap_map, off_palette  # noqa: E402
import gif_to_palette as g2p  # noqa: E402
import palette_proof as pp  # noqa: E402

API = "https://api.pixellab.ai/v2"
OUT = Path("art_proof/jump/pass2")
GIFS = Path("assets/sprites-pandora/jump")
SIZE = 256
GROUND = 240                     # her ankles' line on the 256 canvas
DESCRIPTION = ("slender pale woman with long flowing silver-cyan hair, sleek black-teal bodysuit with thin glowing "
               "cyan seam lines, glowing cyan eyes, long dark sleeve-tails trailing from her forearms")
ACTION = "graceful jump"
# pass-2 picks (gif, frame, beat): the air frames come from j2's knee lift and raised arm (more grace than pass 1)
PICKS2 = [("j1", 7, "crouch"), ("j1", 10, "push-off"), ("j2", 20, "rise: knee up"), ("j2", 24, "rise: arm up"),
          ("j3", 29, "top"), ("j1", 43, "fall"), ("j1", 64, "land")]
BONES = [("NECK", "NOSE"), ("NOSE", "RIGHT EYE"), ("NOSE", "LEFT EYE"), ("RIGHT EYE", "RIGHT EAR"),
         ("LEFT EYE", "LEFT EAR"), ("NECK", "RIGHT SHOULDER"), ("RIGHT SHOULDER", "RIGHT ELBOW"),
         ("RIGHT ELBOW", "RIGHT ARM"), ("NECK", "LEFT SHOULDER"), ("LEFT SHOULDER", "LEFT ELBOW"),
         ("LEFT ELBOW", "LEFT ARM"), ("NECK", "RIGHT HIP"), ("RIGHT HIP", "RIGHT KNEE"),
         ("RIGHT KNEE", "RIGHT LEG"), ("NECK", "LEFT HIP"), ("LEFT HIP", "LEFT KNEE"), ("LEFT KNEE", "LEFT LEG")]


# ---------------------------------------------------------------- PixelLab
def _key():
    k = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not k and os.name == "nt":
        k = subprocess.run(["powershell", "-NoProfile", "-Command",
                            "[Environment]::GetEnvironmentVariable('PIXELLAB_API_KEY','User')"],
                           capture_output=True, text=True).stdout.strip()
    if not k:
        raise SystemExit("PIXELLAB_API_KEY is not set.")
    return k


def _call(method, path, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(API + path, data=data, method=method, headers={
        "Authorization": "Bearer " + _key(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        raise SystemExit(f"{method} {path} -> HTTP {e.code}: {e.read().decode(errors='replace')[:600]}")


def _b64(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return {"type": "base64", "base64": base64.b64encode(buf.getvalue()).decode(), "format": "png"}


def _unb64(obj):
    s = obj["base64"] if isinstance(obj, dict) else obj
    return Image.open(io.BytesIO(base64.b64decode(s))).convert("RGBA")


# ---------------------------------------------------------------- frames
def ref_image():
    """Her approved palette-A frame (palette proof, decision 25), feet on the ground line of a 256 canvas."""
    src = pp.source_frame()
    fig = pp.paint(pp.role_image(src), pp._hex(read_gpl(PAL_A)))
    bb = fig.getbbox()
    fig = fig.crop(bb)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    canvas.paste(fig, (SIZE // 2 - fig.width // 2, GROUND + 4 - fig.height), fig)
    return canvas


def source_image(gif, idx):
    """One frame of the user's GIF with the green keyed out (135 x 240)."""
    im = Image.open(GIFS / f"{gif}.gif")
    im.seek(idx)
    rgb = im.convert("RGB")
    out = Image.new("RGBA", rgb.size, (0, 0, 0, 0))
    px, po = rgb.load(), out.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            c = px[x, y]
            if not g2p.is_bg(*c):
                po[x, y] = c + (255,)
    return out


def _images():
    yield "ref", Image.open(OUT / "ref_a.png")
    for gif, idx, _b in PICKS2:
        yield f"{gif}_{idx:02d}", source_image(gif, idx)


# ---------------------------------------------------------------- steps
def step_ref():
    OUT.mkdir(parents=True, exist_ok=True)
    ref_image().save(OUT / "ref_a.png")
    print("wrote", OUT / "ref_a.png")


def step_skeletons():
    rig = OUT / "rig"
    rig.mkdir(parents=True, exist_ok=True)
    for name, img in _images():
        f = rig / f"{name}.json"
        if f.exists():
            print(name, "cached")
            continue
        r = _call("POST", "/estimate-skeleton", {"image": _b64(img)})
        kps = r["keypoints"]
        if kps and max(max(k["x"], k["y"]) for k in kps) > 1.5:      # pixels: turn into fractions
            kps = [dict(k, x=k["x"] / img.width, y=k["y"] / img.height) for k in kps]
        f.write_text(json.dumps({"size": img.size, "keypoints": kps, "usage": r.get("usage")}, indent=1))
        print(name, len(kps), "joints", "usage", r.get("usage"))


def _load(name):
    d = json.loads((OUT / "rig" / f"{name}.json").read_text())
    w, h = d["size"]
    return {k["label"]: (k["x"] * w, k["y"] * h, k.get("z_index", 0)) for k in d["keypoints"]}


def _len(sk, a, b):
    if a not in sk or b not in sk:
        return None
    return ((sk[a][0] - sk[b][0]) ** 2 + (sk[a][1] - sk[b][1]) ** 2) ** 0.5


def _limb(sk, a, b):
    """The longer of the left and right bone: the shorter one is often foreshortened in a side view."""
    vals = [v for v in (_len(sk, "RIGHT " + a, "RIGHT " + b), _len(sk, "LEFT " + a, "LEFT " + b)) if v]
    return max(vals) if vals else None


def _mid_hip(sk):
    return ((sk["RIGHT HIP"][0] + sk["LEFT HIP"][0]) / 2, (sk["RIGHT HIP"][1] + sk["LEFT HIP"][1]) / 2)


def _size_measures(sk):
    mh = _mid_hip(sk)
    torso = ((sk["NECK"][0] - mh[0]) ** 2 + (sk["NECK"][1] - mh[1]) ** 2) ** 0.5
    return [torso, _limb(sk, "HIP", "KNEE"), _limb(sk, "KNEE", "LEG"), _limb(sk, "SHOULDER", "ELBOW")]


def body_ratio(ref, src):
    """Her size over the pose's size: the median ratio of torso, thigh, shin and upper arm."""
    return statistics.median([r / s for r, s in zip(_size_measures(ref), _size_measures(src)) if r and s])


def retarget(ref, src, k):
    smh, rmh = _mid_hip(src), _mid_hip(ref)
    pts = {lab: ((x - smh[0]) * k, (y - smh[1]) * k, z) for lab, (x, y, z) in src.items()}
    low = max(p[1] for lab, p in pts.items() if lab in ("RIGHT LEG", "LEFT LEG"))
    ref_low = max(ref["RIGHT LEG"][1], ref["LEFT LEG"][1])
    dy = ref_low - low
    out = {lab: (rmh[0] + x, y + dy, z) for lab, (x, y, z) in pts.items()}
    return out, k


def _as_api(sk):
    return [{"label": lab, "x": min(1.0, max(0.0, x / SIZE)), "y": min(1.0, max(0.0, y / SIZE)), "z_index": int(z)}
            for lab, (x, y, z) in sk.items()]


def _draw(d, sk, col, ox=0, oy=0, s=1.0):
    for a, b in BONES:
        if a in sk and b in sk:
            d.line([(ox + sk[a][0] * s, oy + sk[a][1] * s), (ox + sk[b][0] * s, oy + sk[b][1] * s)], fill=col, width=2)
    for lab, (x, y, _z) in sk.items():
        c = (255, 80, 80) if lab.startswith("RIGHT") else ((80, 160, 255) if lab.startswith("LEFT") else col)
        d.ellipse([ox + x * s - 2, oy + y * s - 2, ox + x * s + 2, oy + y * s + 2], fill=c)


def step_retarget():
    ref = _load("ref")
    poses, info = [], []
    sheet = Image.new("RGB", (SIZE * (1 + len(PICKS2)), SIZE * 2), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    r_img = Image.open(OUT / "ref_a.png")
    sheet.paste(r_img, (0, 0), r_img)
    _draw(d, ref, (255, 255, 0))
    d.text((4, 4), "her (ref)", fill=(255, 255, 0))
    # one scale per GIF (the median over all its read frames), so her size does not pulse inside a clip
    per_gif = {}
    for f in sorted((OUT / "rig").glob("j[0-9]_*.json")):        # every read frame of that GIF, picked or not
        per_gif.setdefault(f.stem.split("_")[0], []).append(body_ratio(ref, _load(f.stem)))
    per_gif = {g: statistics.median(v) for g, v in per_gif.items()}
    for n, (gif, idx, beat) in enumerate(PICKS2):
        src = _load(f"{gif}_{idx:02d}")
        out, k = retarget(ref, src, per_gif[gif])
        poses.append(_as_api(out))
        info.append({"pose": n, "src": f"{gif}:{idx}", "beat": beat, "scale": round(k, 3)})
        im = source_image(gif, idx)
        ox = SIZE * (n + 1)
        sheet.paste(im, (ox + (SIZE - im.width) // 2, 8), im)
        _draw(d, src, (255, 255, 0), ox + (SIZE - im.width) // 2, 8)
        d.text((ox + 4, 4), f"{gif}:{idx} {beat}", fill=(220, 220, 220))
        d.line([(ox, SIZE + GROUND), (ox + SIZE, SIZE + GROUND)], fill=(70, 70, 80))
        _draw(d, out, (120, 255, 160), ox, SIZE)
        d.text((ox + 4, SIZE + 4), f"rig x{k:.2f}", fill=(120, 255, 160))
    (OUT / "rig" / "jump_poses.json").write_text(json.dumps({"ref": _as_api(ref), "poses": poses, "info": info}, indent=1))
    sheet.save(OUT / "rig_preview.png")
    for i in info:
        print(i)
    print("wrote", OUT / "rig_preview.png")


def step_redraw(seed):
    raw = OUT / "raw" / f"seed{seed}"
    if raw.exists() and any(raw.glob("*.png")):
        raise SystemExit(f"{raw} already exists: this seed was paid for; use finish, or another seed.")
    rig = json.loads((OUT / "rig" / "jump_poses.json").read_text())
    payload = {"description": DESCRIPTION, "action": ACTION, "direction": "east", "view": "side",
               "first_frame": _b64(Image.open(OUT / "ref_a.png")), "first_frame_keypoints": rig["ref"],
               "keypoints": rig["poses"], "seed": seed, "no_background": True}
    r = _call("POST", "/animate-with-skeleton-v3", payload)
    job = r.get("background_job_id")
    print("job", job, r.get("status"), "usage", r.get("usage"))
    deadline, res = time.time() + 1200, None
    while time.time() < deadline:
        time.sleep(8)
        j = _call("GET", f"/background-jobs/{job}")
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
        _unb64(obj).save(raw / f"jump_{n:02d}.png")
    (raw / "picks.json").write_text(json.dumps(PICKS2))
    (raw / "usage.json").write_text(json.dumps({"usage": res.get("usage"), "job": job}, indent=1))
    print("saved", len(imgs), "frames to", raw, "usage", res.get("usage"))


# ---------------------------------------------------------------- finish (free)
def _nearest_role(c, pal):
    best, bi = None, 0
    for i, p in enumerate(pal):
        dd = 0.3 * (c[0] - p[0]) ** 2 + 0.59 * (c[1] - p[1]) ** 2 + 0.11 * (c[2] - p[2]) ** 2
        if best is None or dd < best:
            best, bi = dd, i
    return bi + 1


def to_roles(img, pal):
    w, h = img.size
    px = img.load()
    cache = {}
    out = []
    for y in range(h):
        row = []
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128:
                row.append(0)
                continue
            if (r, g, b) not in cache:
                cache[(r, g, b)] = _nearest_role((r, g, b), pal)
            row.append(cache[(r, g, b)])
        out.append(row)
    return out


def step_finish(seed):
    raw = OUT / "raw" / f"seed{seed}"
    fa, fb = OUT / f"seed{seed}" / "a", OUT / f"seed{seed}" / "b"
    fa.mkdir(parents=True, exist_ok=True)
    fb.mkdir(parents=True, exist_ok=True)
    pal, mapping = read_gpl(PAL_A), swap_map()
    ref_h = Image.open(OUT / "ref_a.png").getbbox()
    factor = g2p.TARGET_PX / (ref_h[3] - ref_h[1])           # her standing height becomes 90 px, once
    frames = sorted(raw.glob("jump_*.png"))
    for f in frames:
        a = g2p.to_canvas(g2p.clean(g2p.shrink(to_roles(Image.open(f).convert("RGBA"), pal), factor)), pal)
        a.save(fa / f.name)
        bake_image(a, mapping).save(fb / f.name)
        bb = a.getbbox()
        print(f.name, "height", bb[3] - bb[1], "px; off-palette", off_palette(a, pal)[0])
    _sheet(seed, frames)
    _gif(seed)


def _sheet(seed, frames):
    S, cw, chh = 3, 120 * 3, 104 * 3
    box = (52, 52, 172, 156)
    picks = json.loads((OUT / "raw" / f"seed{seed}" / "picks.json").read_text())
    rows = [("your GIF", [source_image(g, i) for g, i, _b in picks]),
            ("PixelLab", [Image.open(f).convert("RGBA") for f in frames]),
            ("A", [Image.open(OUT / f"seed{seed}" / "a" / f.name) for f in frames]),
            ("B", [Image.open(OUT / f"seed{seed}" / "b" / f.name) for f in frames]),
            ("pass 1", [Image.open(f"art_proof/jump/pass1/a/{f.name}") for f in frames])]
    if seed != 7 and (OUT / "seed7" / "a").exists():
        rows[-1] = ("seed 7", [Image.open(OUT / "seed7" / "a" / f.name) for f in frames])
    sheet = Image.new("RGB", (70 + len(frames) * cw, len(rows) * (chh + 18)), (30, 30, 36))
    d = ImageDraw.Draw(sheet)
    for r, (lab, imgs) in enumerate(rows):
        y = r * (chh + 18)
        d.text((6, y + chh // 2), lab, fill=(255, 255, 0))
        for i, im in enumerate(imgs):
            if lab in ("A", "B", "pass 1"):
                c = im.crop(box).resize((cw, chh), Image.NEAREST)
            else:
                bb = im.getbbox() or (0, 0, im.width, im.height)
                c = im.crop(bb)
                k = min(cw / c.width, chh / c.height)
                c = c.resize((max(1, int(c.width * k)), max(1, int(c.height * k))), Image.NEAREST)
            sheet.paste(c, (70 + i * cw + (cw - c.width) // 2, y + 16 + chh - c.height), c)
            if r == 0:
                d.text((70 + i * cw + 4, y + 2), f"{picks[i][0]}:{picks[i][1]} {picks[i][2]}", fill=(220, 220, 220))
    sheet.save(OUT / f"jump_pass2_seed{seed}_sheet.png")
    print("wrote", OUT / f"jump_pass2_seed{seed}_sheet.png")


def _gif(seed):
    base = OUT / f"seed{seed}"
    bg = Image.open("shots/1_church_start.png").convert("RGB").crop((100, 88, 215, 205)).resize((230, 234), Image.NEAREST)
    dur = [70, 60, 90, 90, 140, 110, 90, 400]
    lift = [0, 0, 30, 46, 52, 30, 0, 0]
    old_seq = [0, 0, 1, 1, 2, 3, 3]
    idle = Image.open("assets/2x/pandora/idle_00.png").convert("RGBA")
    frames = []
    for k in range(8):
        panel = Image.new("RGB", (230 * 3, 234))
        for p in range(3):
            cell = bg.copy()
            if k == 7:
                f = idle
            elif p == 0:
                f = Image.open(f"assets/2x/pandora/jump_{old_seq[k]:02d}.png").convert("RGBA")
            else:
                f = Image.open(base / ("a" if p == 1 else "b") / f"jump_{k:02d}.png")
            f2 = f.crop((52, 30, 172, 156))
            cell.paste(f2, (55, 234 - 14 - 126 - lift[k]), f2)
            panel.paste(cell, (p * 230, 0))
        panel = panel.resize((panel.width * 2, panel.height * 2), Image.NEAREST)
        ImageDraw.Draw(panel).text((8, 8), "today            A (main)            B (skin)", fill=(255, 255, 255))
        frames.append(panel)
    frames[0].save(OUT / f"jump_pass2_seed{seed}_gamespeed.gif", save_all=True, append_images=frames[1:],
                   duration=dur, loop=0, disposal=2)
    print("wrote", OUT / f"jump_pass2_seed{seed}_gamespeed.gif")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    seed = int(sys.argv[sys.argv.index("--seed") + 1]) if "--seed" in sys.argv else 7
    {"ref": step_ref, "skeletons": step_skeletons, "retarget": step_retarget,
     "redraw": lambda: step_redraw(seed), "finish": lambda: step_finish(seed)}.get(cmd, lambda: print(__doc__))()
