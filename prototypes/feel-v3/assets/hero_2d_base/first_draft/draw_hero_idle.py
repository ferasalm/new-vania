#!/usr/bin/env python3
"""pandora_idle_base — native 112x80 RGBA pixel art, ONE committed idle frame (spike).

Hand-authored polygon/line/pixel geometry on the pixel grid (no vector downsample).
Layers: hair_back, cape, body, arms, head_hair_front, details.
Logical pivot (56, 76); sole row y=75. Candidate palette: palette.json (hexes only).
NOT production-ready, NOT approved, one frame only.
"""
import json, os
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 112, 80
PIVOT = (56, 76)

with open(os.path.join(HERE, "palette.json")) as f:
    PAL = json.load(f)["palette"]
C = {k: tuple(int(v[i:i+2], 16) for i in (1, 3, 5)) + (255,) for k, v in PAL.items()}
T = (0, 0, 0, 0)

layers = {n: Image.new("RGBA", (W, H), T) for n in
          ["hair_back", "cape", "body", "arms", "head_hair_front", "details"]}
def D(n): return ImageDraw.Draw(layers[n])
def poly(n, pts, col): D(n).polygon(pts, fill=col)
def px(n, pts, col): D(n).point(pts, fill=col)
def hline(n, x0, x1, y, col): D(n).line([(x0, y), (x1, y)], fill=col)
def vline(n, x, y0, y1, col): D(n).line([(x, y0), (x, y1)], fill=col)

# ================================================================ HAIR_BACK
# Ponytail: 4 readable mass clusters, backwards sweep, tapered locks.
h = "hair_back"
# volume behind skull
poly(h, [(49,13),(56,10),(61,11),(63,15),(61,20),(57,23),(52,21),(49,17)], C["hair_mid"])
poly(h, [(49,13),(51,12),(51,20),(54,22),(52,21),(49,17)], C["hair_shade"])
# Lock D — flick arcing above the tie
poly(h, [(57,9),(61,7),(64,9),(61,12),(58,11)], C["hair_mid"])
px(h, [(61,8),(62,9),(60,10)], C["hair_light"])
# Lock A — big backwards sweep (main sail mass)
poly(h, [(58,10),(60,12),(55,14),(49,16),(42,18),(36,21),(31,24),(29,27),(33,26),
         (40,22),(47,19),(54,15),(58,13)], C["hair_mid"])
poly(h, [(57,13),(58,13),(50,16),(42,20),(34,25),(31,27),(34,25),(42,21),(50,17),
         (56,14)], C["hair_shade"])
px(h, [(55,12),(51,13),(46,15),(41,17),(37,19),(33,22),(31,24)], C["hair_light"])
# Lock B — long lock curving down the back
poly(h, [(43,18),(47,20),(45,28),(42,36),(39,44),(36,50),(33,50),(32,47),(35,39),
         (38,30),(40,22)], C["hair_mid"])
poly(h, [(45,20),(46,21),(44,30),(40,41),(37,49),(34,49),(36,43),(39,33),(41,24)], C["hair_shade"])
px(h, [(41,20),(39,23),(38,27),(37,31),(36,35)], C["hair_light"])
# Lock C — tapering tail tip with flick
poly(h, [(35,47),(39,49),(37,56),(35,61),(32,62),(30,59),(32,53)], C["hair_mid"])
poly(h, [(36,50),(37,50),(35,57),(32,61),(31,60),(33,54)], C["hair_deep"])
px(h, [(33,49),(32,52),(31,55)], C["hair_light"])

# ================================================================ CAPE
c = "cape"
# left/back drape, tattered hem
poly(c, [(51,29),(58,29),(56,38),(54,46),(50,54),(46,60),(43,64),(41,61),(42,57),
         (40,55),(43,52),(41,49),(44,46),(42,43),(45,39),(44,35),(47,31)], C["cape_base"])
poly(c, [(52,31),(55,31),(53,40),(50,48),(46,56),(43,61),(42,58),(44,53),(46,47),
         (48,40),(49,34)], C["cape_shade"])
px(c, [(43,64),(41,61),(46,60),(50,54),(54,46)], C["cape_edge"])
# narrow right drape behind the near leg
poly(c, [(65,33),(68,35),(67,44),(65,52),(63,59),(61,61),(62,54),(63,46),(63,39)], C["cape_base"])
poly(c, [(66,36),(67,37),(66,45),(64,53),(63,58),(62,56),(64,47),(65,40)], C["cape_shade"])
px(c, [(63,59),(65,52),(67,44)], C["cape_edge"])

# ================================================================ BODY
b = "body"
# high scarf collar
poly(b, [(51,27),(62,26),(65,29),(64,32),(60,33),(54,33),(50,31),(49,29)], C["scarf_base"])
poly(b, [(51,27),(54,27),(53,32),(54,33),(52,32),(50,31),(49,29)], C["scarf_shade"])
hline(b, 53, 62, 30, C["cape_edge"])
px(b, [(62,27),(63,28),(63,29)], C["scarf_shade"])
# torso — dark android chassis
poly(b, [(52,31),(66,31),(67,37),(65,42),(62,45),(54,45),(52,41),(51,35)], C["suit_base"])
poly(b, [(52,31),(55,31),(54,44),(56,45),(54,45),(52,41),(51,35)], C["suit_shade"])
poly(b, [(66,31),(67,37),(65,42),(64,42),(65,36),(64,32)], C["suit_hi"])
# waist + hips
poly(b, [(53,44),(63,44),(64,50),(52,50)], C["suit_base"])
poly(b, [(53,44),(55,44),(54,50),(52,50)], C["suit_shade"])
hline(b, 55, 62, 49, C["suit_hi"])
# BACK LEG — weight-bearing, planted, knee slightly bent back
poly(b, [(53,49),(58,49),(57,62),(53,62)], C["suit_base"])
poly(b, [(53,49),(55,49),(54,62),(53,62)], C["suit_shade"])
poly(b, [(52,61),(57,61),(57,64),(52,64)], C["boot_shade"])
poly(b, [(53,63),(57,63),(55,70),(51,70)], C["suit_base"])
poly(b, [(53,63),(54,63),(52,69),(51,70)], C["suit_shade"])
poly(b, [(50,69),(56,69),(57,74),(57,75),(46,75),(46,73),(48,72),(49,70)], C["boot_base"])
poly(b, [(50,69),(52,69),(50,73),(48,73),(47,74),(46,75),(46,73),(48,72),(49,70)], C["boot_shade"])
hline(b, 51, 56, 70, C["boot_hi"])
# FRONT LEG — relaxed forward, knee bend
poly(b, [(59,49),(64,49),(64,61),(60,61)], C["suit_base"])
poly(b, [(59,49),(61,49),(61,61),(60,61)], C["suit_shade"])
poly(b, [(59,60),(64,60),(64,63),(59,63)], C["boot_shade"])
hline(b, 60, 63, 60, C["boot_hi"])
poly(b, [(60,62),(64,62),(63,70),(60,70)], C["suit_base"])
poly(b, [(60,62),(61,62),(61,70),(60,70)], C["suit_shade"])
poly(b, [(59,68),(65,68),(67,72),(67,75),(57,75),(57,72),(58,70)], C["boot_base"])
poly(b, [(59,68),(61,68),(61,72),(58,72),(57,74),(57,75),(58,70)], C["boot_shade"])
hline(b, 60, 66, 69, C["boot_hi"])

# ================================================================ ARMS
a = "arms"
# NEAR ARM (right): exposed tan upper arm, elbow low, forearm cocked up-in, dark glove
poly(a, [(64,31),(68,32),(67,40),(65,41),(63,38),(63,33)], C["skin_base"])
poly(a, [(64,31),(65,31),(64,38),(65,41),(63,38),(63,33)], C["skin_shade"])
px(a, [(67,33),(67,34),(66,35)], C["skin_light"])
# gauntlet forearm bent up toward chest
poly(a, [(66,40),(64,43),(60,38),(62,35)], C["gauntlet_base"])
poly(a, [(66,40),(65,41),(61,38),(62,35)], C["gauntlet_shade"])
px(a, [(63,40),(62,39)], C["boot_hi"])
# cocked blade-hand (gloved fist near chest)
poly(a, [(58,33),(61,35),(60,37),(57,36),(56,34)], C["gauntlet_base"])
px(a, [(60,34),(59,35),(58,35)], C["boot_hi"])
px(a, [(57,36),(58,36)], C["gauntlet_shade"])
# FAR ARM (left): exposed upper arm, hangs slightly back, gauntlet, loose fist
poly(a, [(49,31),(53,32),(52,40),(49,41),(47,38),(48,33)], C["skin_base"])
poly(a, [(49,31),(50,31),(49,38),(50,40),(49,41),(47,38),(48,33)], C["skin_shade"])
px(a, [(52,33),(52,34)], C["skin_light"])
poly(a, [(48,39),(51,40),(49,47),(45,47),(44,44),(46,40)], C["gauntlet_base"])
poly(a, [(48,39),(49,40),(47,46),(45,47),(44,44)], C["gauntlet_shade"])
poly(a, [(43,45),(47,46),(46,49),(43,49),(42,47)], C["gauntlet_base"])
px(a, [(46,47),(45,48)], C["boot_hi"])

# ================================================================ HEAD+HAIR FRONT
f = "head_hair_front"
# hair cap / back-of-head volume
poly(f, [(50,14),(56,11),(61,12),(63,16),(62,20),(60,23),(57,25),(52,24),(49,20),(49,16)], C["hair_mid"])
poly(f, [(49,16),(51,14),(51,23),(54,25),(52,24),(49,20)], C["hair_shade"])
# face — right 3/4, adult brow/jaw, small nose
poly(f, [(59,16),(62,17),(63,20),(64,22),(63,24),(61,26),(58,26),(57,23),(57,18)], C["skin_base"])
poly(f, [(57,18),(58,17),(58,25),(60,26),(58,26),(57,23)], C["skin_shade"])
px(f, [(62,18),(63,19),(62,19)], C["skin_light"])
# bangs — layered swept fringe with right-pointing tips
poly(f, [(49,17),(51,12),(57,10),(62,12),(64,15),(62,17),(60,15),(58,17),(56,15),
         (55,17),(53,16),(52,19),(50,19)], C["hair_mid"])
poly(f, [(62,14),(65,16),(63,18),(62,17)], C["hair_mid"])
px(f, [(65,15)], C["hair_light"])
px(f, [(52,12),(55,11),(58,11),(60,12)], C["hair_light"])
hline(f, 57, 61, 16, C["hair_shade"])
hline(f, 53, 56, 18, C["hair_shade"])
# cheek-framing side lock
poly(f, [(50,18),(52,19),(51,25),(49,26),(48,23)], C["hair_mid"])
px(f, [(50,21),(49,23)], C["hair_shade"])
# high tie knot
poly(f, [(55,9),(59,9),(60,12),(55,12)], C["hair_deep"])
px(f, [(56,10),(57,10)], C["hair_shade"])

# ================================================================ DETAILS
d = "details"
# chest circuit emblem (android read)
vline(d, 60, 34, 39, C["cyan_glow"])
px(d, [(57,36),(58,37),(60,38),(62,37),(63,36)], C["cyan_glow"])
px(d, [(60,33),(59,39),(61,40)], C["rim_cyan"])
px(d, [(60,42),(61,43)], C["cyan_deep"])
# hip + leg seams
px(d, [(62,45),(63,46),(61,47),(64,47)], C["cyan_deep"])
vline(d, 63, 51, 59, C["cyan_deep"])
px(d, [(63,53),(62,57)], C["cyan_glow"])
vline(d, 62, 63, 66, C["cyan_deep"])
vline(d, 56, 52, 57, C["cyan_deep"])
px(d, [(62,30)], C["cyan_deep"])
# face: one cyan eye, brow, nose step, mouth, jaw
px(d, [(61,22)], C["eye_cyan"])
px(d, [(60,22)], C["cyan_deep"])
hline(d, 60, 62, 20, C["hair_deep"])
px(d, [(64,23),(61,25),(62,26)], C["skin_shade"])
# 1-px cyan rim key on right contour (rim-light rule)
px(d, [(67,32),(67,33),(67,34),(66,35),(66,36),(65,40),(65,41),(64,42),(64,50),
       (65,51),(64,52),(64,58),(64,59),(68,69),(68,70),(69,71),(69,72),(69,73),
       (67,74)], C["rim_cyan"])

# ================================================================ COMPOSITE
comp = Image.new("RGBA", (W, H), T)
order = ["hair_back", "cape", "body", "arms", "head_hair_front", "details"]
for n in order:
    comp.alpha_composite(layers[n])

os.makedirs(os.path.join(HERE, "layers"), exist_ok=True)
for n, img in layers.items():
    img.save(os.path.join(HERE, "layers", f"pandora_idle_{n}.png"))
comp.save(os.path.join(HERE, "pandora_idle_base.png"))
comp.resize((W * 4, H * 4), Image.NEAREST).save(os.path.join(HERE, "pandora_idle_base_4x.png"))

def on_bg(img, bg, s=1):
    base = Image.new("RGBA", (img.width * s, img.height * s), bg)
    if s > 1:
        img = img.resize((img.width * s, img.height * s), Image.NEAREST)
    base.alpha_composite(img)
    return base

DARK, LIGHT = (20, 24, 32, 255), (214, 210, 200, 255)
g = 8
comp4 = comp.resize((W * 4, H * 4), Image.NEAREST)
gl = comp.convert("LA")
gray = Image.merge("RGBA", (gl.split()[0],) * 3 + (gl.split()[1],))
gray4 = gray.resize((W * 4, H * 4), Image.NEAREST)
sheet = Image.new("RGBA", (W * 2 + g * 2 + W * 4 + 8, (H + g) * 2), (60, 60, 64, 255))
for x, y, im in [
    (0, 0, on_bg(comp, DARK)), (W + g, 0, on_bg(comp, LIGHT)),
    (0, H + g, on_bg(comp4, DARK)), (W + g, H + g, on_bg(comp4, LIGHT)),
    (W * 2 + g * 2 + 4, 0, on_bg(gray, DARK)),
    (W * 2 + g * 2 + 4, H + g, on_bg(gray4, LIGHT)),
]:
    sheet.alpha_composite(im, (x, y))
sheet.save(os.path.join(HERE, "proof_pandora_idle_base.png"))

# metadata
meta = {
    "asset": "pandora_idle_base",
    "production_ready": False,
    "approved": False,
    "one_frame_only": True,
    "dimensions": [W, H],
    "logical_pivot": list(PIVOT),
    "sole_row": 75,
    "facing": "right_3_4",
    "source_reference_filenames": [
        "Modify_woman_upper_arms_skin_580f0e04.jpg",
        "image.png_cbe4f7e4.jpg",
    ],
    "source_reference_dir": "prototypes/feel-v3/assets/pandora_proportion_study/reference/",
    "palette_file": "palette.json",
    "palette_note": "candidate visual-spike palette, NOT a bible table amendment; needs art-director approval",
    "generator": "draw_hero_idle.py (PIL, native pixel geometry)",
    "layers": order,
}
with open(os.path.join(HERE, "metadata.json"), "w") as fp:
    json.dump(meta, fp, indent=2)

# checks
bb = comp.getbbox()
alpha_vals = sorted({p[3] for p in comp.getdata()})
cols = sorted({p for p in comp.getdata() if p[3] > 0})
h_px = bb[3] - bb[1]
print("dims", comp.size, "bbox", bb, "height_px", h_px)
print("alpha_values", alpha_vals, "unique_rgba", len(cols))
print("padding L/T/R/B", bb[0], bb[1], W - 1 - bb[2], H - 1 - bb[3])
print("pivot row 76 empty", all(comp.getpixel((x, 76))[3] == 0 for x in range(W)))
print("feet opaque at y75", sum(1 for x in range(W) if comp.getpixel((x, 75))[3] == 255))
