# Pandora proportion study (spike) - headless Blender 5.2
# blender.exe --background --factory-startup --python build_study.py
import bpy, os, sys, json, math, hashlib, shutil, traceback
from mathutils import Vector, Matrix

ROOT = r"C:/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch/prototypes/feel-v3"
SRC = ROOT + "/tools/models/pandora_rigged.glb"
OUT = ROOT + "/assets/pandora_proportion_study"

ARTIFACTS = ["packed.blend", "authoring.blend", "before_after.png", "settings.json",
             "old_front.png", "old_side.png", "new_front.png", "new_side.png"]

S_LEG = 1.16      # leg length +16%
S_TORSO = 1.06    # torso +6%
S_HEAD = 0.895    # head/hair isotropic -10.5%
B = 0.06          # smoothstep half-band at joints (m)
STEP = 0.001
RES_W, RES_H = 360, 480
SAMPLES = 32


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def die(m):
    print("FAIL: " + m); sys.exit(1)


def main():
    for a in ARTIFACTS:
        if os.path.exists(os.path.join(OUT, a)):
            die("refusing to overwrite existing " + a)
    sha_before = sha(SRC)
    print("source_sha256_before", sha_before)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)
    arms = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    all_meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    if len(arms) != 1:
        die("armature count %d" % len(arms))
    arm = arms[0]
    arm.data.pose_position = 'REST'
    for pb in arm.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)

    meshes = [m for m in all_meshes if any(md.type == 'ARMATURE' for md in m.modifiers)]
    ignored = [m for m in all_meshes if m not in meshes]
    for m in ignored:
        m.hide_render = True
        print("ignored non-character mesh:", m.name, len(m.data.vertices), "verts")
    if not meshes:
        die("no skinned mesh")

    def bfind(*names):
        for n in names:
            for b in arm.data.bones:
                if b.name.lower() == n:
                    return b.name
        return None

    hips_name = bfind("hips", "pelvis")
    head_name = bfind("head")
    arm_names = [b for b in arm.data.bones if b.name.lower() in ("leftarm", "rightarm", "upperarm_l", "upperarm_r")]
    if not hips_name or not head_name or not arm_names:
        die("bones: hips=%s head=%s arms=%s" % (hips_name, head_name, [b.name for b in arm_names]))

    def wpos(bn):
        return arm.matrix_world @ arm.data.bones[bn].head_local

    HIPS, HEADP = wpos(hips_name), wpos(head_name)

    def desc(bn, acc=None):
        acc = [] if acc is None else acc
        for c in arm.data.bones[bn].children:
            acc.append(c.name); desc(c.name, acc)
        return acc

    head_set = set(desc(head_name)) | {head_name}
    arm_set = set()
    for a in arm_names:
        arm_set.add(a.name); arm_set |= set(desc(a.name))
    print("anchors hips=%s head=%s head_descendants=%d arm_bones=%d" %
          (hips_name, head_name, len(head_set), len(arm_set)))

    orig_counts = {m.name: len(m.data.vertices) for m in meshes}
    orig_uv = {m.name: [l.name for l in m.data.uv_layers] for m in meshes}
    orig_scale = {m.name: tuple(round(v, 6) for v in m.scale) for m in meshes}
    orig_names = [m.name for m in meshes]
    bone_count = len(arm.data.bones)

    def bounds(objs):
        lo = Vector((1e9,) * 3); hi = Vector((-1e9,) * 3)
        for m in objs:
            M = m.matrix_world
            for v in m.data.vertices:
                w = M @ v.co
                for i in range(3):
                    lo[i] = min(lo[i], w[i]); hi[i] = max(hi[i], w[i])
        return lo, hi

    lo0, hi0 = bounds(meshes)
    H0 = hi0.z - lo0.z
    ZF = lo0.z                      # floor = feet level (-0.952)
    Z_TOP = hi0.z
    print("bounds_old min=%s max=%s height=%.4f floor=%.4f" %
          (tuple(round(x, 4) for x in lo0), tuple(round(x, 4) for x in hi0), H0, ZF))

    # ---- continuous piecewise world-Z warp, anchored at the floor --------
    z_hips, z_head = HIPS.z, HEADP.z

    def gfun(z):
        if z < z_hips - B:
            return S_LEG
        if z < z_hips + B:
            t = (z - (z_hips - B)) / (2 * B); t = t * t * (3 - 2 * t)
            return S_LEG + (S_TORSO - S_LEG) * t
        if z < z_head - B:
            return S_TORSO
        if z < z_head + B:
            t = (z - (z_head - B)) / (2 * B); t = t * t * (3 - 2 * t)
            return S_TORSO + (1.0 - S_TORSO) * t
        return 1.0

    N = int((Z_TOP - ZF + 1.0) / STEP) + 1
    F = [0.0] * N
    acc = 0.0
    for i in range(1, N):
        acc += gfun(ZF + (i - 0.5) * STEP) * STEP
        F[i] = acc

    def warp_z(z):
        if z <= ZF:
            return ZF + S_LEG * (z - ZF)
        x = (z - ZF) / STEP
        i = int(x)
        if i >= N - 1:
            return ZF + F[N - 1] + (z - (ZF + (N - 1) * STEP))
        fr = x - i
        return ZF + F[i] * (1 - fr) + F[i + 1] * fr

    PIVOT_OLD = HEADP.copy()
    PIVOT_NEW = Vector((HEADP.x, HEADP.y, warp_z(HEADP.z)))
    # arm anchors: (new_head, old_head, side_x)
    ANCH = [(Vector((a.x, a.y, warp_z(a.z))), Vector(a), a.x) for a in (wpos(n.name) for n in arm_names)]

    def warp_point(p, w_head, w_arm, anchor):
        base = Vector((p.x, p.y, warp_z(p.z)))
        if w_head > 0.0:
            base = base.lerp(PIVOT_NEW + (p - PIVOT_OLD) * S_HEAD, w_head)
        if w_arm > 0.0 and anchor is not None:
            base = base.lerp(anchor[0] + (p - anchor[1]), w_arm)
        return base

    def pick_anchor(x):
        return min(ANCH, key=lambda a: abs(a[2] - x)) if ANCH else None

    # ---- independent original / modified copies --------------------------
    arm_mod = arm.copy(); arm_mod.data = arm.data.copy(); arm_mod.name = "Pandora_ARM_mod"
    bpy.context.scene.collection.objects.link(arm_mod)
    arm.name = "Pandora_ARM_orig"
    mod_meshes = []
    for m in list(meshes):
        c = m.copy(); c.data = m.data.copy()
        c.name = m.name + "_mod"; m.name = m.name + "_orig"
        bpy.context.scene.collection.objects.link(c)
        c.parent = arm_mod
        c.matrix_parent_inverse = m.matrix_parent_inverse.copy()
        for md in c.modifiers:
            if md.type == 'ARMATURE':
                md.object = arm_mod
        mod_meshes.append(c)

    # ---- deform modified mesh -------------------------------------------
    head_w_zrange = [1e9, -1e9]
    arm_w_count = 0
    for m in mod_meshes:
        gname = {g.index: g.name for g in m.vertex_groups}
        M = m.matrix_world.copy(); Minv = M.inverted()
        for v in m.data.vertices:
            w_head = w_arm = 0.0
            for ge in v.groups:
                nm = gname.get(ge.group)
                if nm is None:
                    continue
                if nm in head_set:
                    w_head = max(w_head, ge.weight)
                elif nm in arm_set:
                    w_arm = max(w_arm, ge.weight)
            wco = M @ v.co
            if w_head > 0.0:
                head_w_zrange[0] = min(head_w_zrange[0], wco.z)
                head_w_zrange[1] = max(head_w_zrange[1], wco.z)
            if w_arm > 0.0:
                arm_w_count += 1
            an = pick_anchor(wco.x) if w_arm > 0.0 else None
            v.co = Minv @ warp_point(wco, min(w_head, 1.0), min(w_arm, 1.0), an)
        m.data.update()

    # ---- coherent bone rest edits ---------------------------------------
    bpy.context.view_layer.objects.active = arm_mod
    bpy.ops.object.mode_set(mode='EDIT')
    AMW = arm_mod.matrix_world.copy(); AMWi = AMW.inverted()
    for eb in arm_mod.data.edit_bones:
        nm = eb.name
        if nm in head_set:
            wh, wa, an = 1.0, 0.0, None
        elif nm in arm_set:
            wh, wa, an = 0.0, 1.0, pick_anchor((AMW @ eb.head).x)
        else:
            wh, wa, an = 0.0, 0.0, None
        h = AMW @ eb.head; t = AMW @ eb.tail
        eb.head = AMWi @ warp_point(h, wh, wa, an)
        eb.tail = AMWi @ warp_point(t, wh, wa, an)
    bpy.ops.object.mode_set(mode='OBJECT')
    arm_mod.data.pose_position = 'REST'

    lo1, hi1 = bounds(mod_meshes)
    H1 = hi1.z - lo1.z
    head_h0 = Z_TOP - z_head
    head_h1 = hi1.z - PIVOT_NEW.z

    # ---- verification ----------------------------------------------------
    checks = {}
    checks["vertex_counts_unchanged"] = all(len(m.data.vertices) == orig_counts[nm]
                                            for m, nm in zip(mod_meshes, orig_names))
    checks["bone_count_52"] = (len(arm_mod.data.bones) == 52 == bone_count)
    checks["uv_layers_preserved"] = all([l.name for l in m.data.uv_layers] == orig_uv[nm]
                                        for m, nm in zip(mod_meshes, orig_names))
    finite = True
    for m in mod_meshes:
        for v in m.data.vertices:
            if not all(math.isfinite(c) for c in v.co):
                finite = False; break
    checks["finite_coords"] = finite
    checks["object_scale_untouched"] = all(tuple(round(v, 6) for v in m.scale) == orig_scale[nm]
                                          for m, nm in zip(mod_meshes, orig_names))
    checks["geometry_height_changed"] = abs(H1 - H0) > 0.02
    checks["feet_on_floor"] = abs(lo1.z - ZF) < 0.005
    weighted = 0
    for b in arm_mod.data.bones:
        tot = 0.0
        for m in mod_meshes:
            g = m.vertex_groups.get(b.name)
            if not g:
                continue
            for v in m.data.vertices:
                for ge in v.groups:
                    if ge.group == g.index:
                        tot += ge.weight
        if tot > 0.001:
            weighted += 1
    checks["bones_with_weights"] = weighted
    checks["head_weighted_verts"] = arm_w_count
    print("checks", json.dumps(checks))

    # ---- render ----------------------------------------------------------
    scene = bpy.context.scene
    try:
        scene.render.engine = 'CYCLES'
        scene.cycles.device = 'CPU'
        scene.cycles.samples = SAMPLES
        try:
            scene.cycles.use_denoising = True
        except Exception:
            pass
    except TypeError as e:
        print("engine fallback:", e)
    scene.view_settings.view_transform = 'Standard'
    scene.render.resolution_x = RES_W
    scene.render.resolution_y = RES_H
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'

    world = bpy.data.worlds.new("W"); scene.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (0.012, 0.020, 0.055, 1.0)
    bg.inputs[1].default_value = 1.0

    bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 0, ZF))
    floor = bpy.context.active_object; floor.name = "floor"
    fm = bpy.data.materials.new("floor_mat"); fm.use_nodes = True
    pn = next(n for n in fm.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    pn.inputs["Base Color"].default_value = (0.15, 0.16, 0.18, 1)
    pn.inputs["Roughness"].default_value = 0.85
    floor.data.materials.append(fm)

    view_h = max(H0, H1) + 0.26
    zc = ZF - 0.045 + view_h / 2.0
    cd = bpy.data.cameras.new("cam")
    cd.type = 'ORTHO'; cd.ortho_scale = view_h; cd.sensor_fit = 'VERTICAL'
    cam = bpy.data.objects.new("cam", cd); scene.collection.objects.link(cam)
    scene.camera = cam

    rig = bpy.data.objects.new("light_rig", None); scene.collection.objects.link(rig)
    tgt = bpy.data.objects.new("light_tgt", None); scene.collection.objects.link(tgt)
    tgt.parent = rig; tgt.location = (0, 0, ZF + 0.95)

    def add_light(name, loc, power, size, color):
        d = bpy.data.lights.new(name, 'AREA'); d.energy = power; d.size = size; d.color = color
        o = bpy.data.objects.new(name, d); scene.collection.objects.link(o)
        o.parent = rig; o.location = loc
        c = o.constraints.new('TRACK_TO'); c.target = tgt
        c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'

    add_light("key", (-2.2, -3.0, 3.9), 1800, 3.0, (1.0, 0.96, 0.92))
    add_light("fill", (2.6, -2.5, 2.3), 900, 3.0, (0.85, 0.92, 1.0))
    add_light("rim", (0.5, 2.8, 3.6), 2200, 2.0, (0.62, 0.95, 1.0))

    def shot(tag, side, use_mod):
        for m in meshes:
            m.hide_render = use_mod
        for m in mod_meshes:
            m.hide_render = not use_mod
        arm.hide_render = use_mod; arm_mod.hide_render = not use_mod
        if side:
            rig.rotation_euler = (0, 0, math.radians(-90))
            cam.location = (-6, 0, zc)
            cam.rotation_euler = (math.radians(90), 0, math.radians(-90))
        else:
            rig.rotation_euler = (0, 0, 0)
            cam.location = (0, -6, zc)
            cam.rotation_euler = (math.radians(90), 0, 0)
        bpy.context.view_layer.update()
        scene.render.filepath = os.path.join(OUT, tag + ".png")
        bpy.ops.render.render(write_still=True)
        print("rendered", tag)

    shot("old_front", False, False)
    shot("old_side", True, False)
    shot("new_front", False, True)
    shot("new_side", True, True)

    # ---- save ------------------------------------------------------------
    arm.hide_render = False; arm_mod.hide_render = False
    for m in meshes + mod_meshes:
        m.hide_render = False
    try:
        bpy.ops.file.pack_all()
    except Exception as e:
        print("pack_all warning:", e)
    blend = os.path.join(OUT, "authoring.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend)
    shutil.copyfile(blend, os.path.join(OUT, "packed.blend"))

    sha_after = sha(SRC)
    checks["source_sha_unchanged"] = (sha_after == sha_before)
    print("source_sha256_after", sha_after)

    data = {
        "study": "pandora_proportion_study",
        "production_ready": False,
        "approved": False,
        "source": SRC,
        "source_sha256_before": sha_before,
        "source_sha256_after": sha_after,
        "engine": "Blender " + bpy.app.version_string,
        "params": {"leg_scale": S_LEG, "torso_scale": S_TORSO, "head_scale_isotropic": S_HEAD,
                   "blend_band_m": B, "deform": "continuous piecewise world-Z, feet anchored at floor"},
        "anchors": {"hips_head_z": round(z_hips, 4), "head_head_z": round(z_head, 4),
                    "head_head_z_new": round(PIVOT_NEW.z, 4),
                    "hips_head_z_new": round(warp_z(z_hips), 4),
                    "arm_bones": [b.name for b in arm_names]},
        "measurements": {
            "height_old_m": round(H0, 4), "height_new_m": round(H1, 4),
            "height_gain_pct": round(100.0 * (H1 / H0 - 1), 2),
            "head_hair_height_old_m": round(head_h0, 4),
            "head_hair_height_new_m": round(head_h1, 4),
            "head_reduction_pct": round(100.0 * (1 - head_h1 / head_h0), 2),
            "heads_tall_old": round(H0 / head_h0, 2), "heads_tall_new": round(H1 / head_h1, 2),
            "leg_len_old_m": round(z_hips - ZF, 4), "leg_len_new_m": round(warp_z(z_hips) - ZF, 4),
            "leg_gain_pct": round(100.0 * ((warp_z(z_hips) - ZF) / (z_hips - ZF) - 1), 2),
            "torso_len_old_m": round(z_head - z_hips, 4),
            "torso_len_new_m": round(PIVOT_NEW.z - warp_z(z_hips), 4),
            "torso_gain_pct": round(100.0 * ((PIVOT_NEW.z - warp_z(z_hips)) / (z_head - z_hips) - 1), 2),
            "floor_z": round(ZF, 4), "min_z_new": round(lo1.z, 4),
            "head_weight_z_range_old": [round(x, 3) for x in head_w_zrange],
        },
        "verification": checks,
        "mesh_objects": {m.name: {"verts": len(m.data.vertices),
                                  "uv_layers": [l.name for l in m.data.uv_layers]}
                         for m in mod_meshes},
        "ignored_objects": [{"name": m.name, "verts": len(m.data.vertices)} for m in ignored],
        "bone_count": len(arm_mod.data.bones),
        "object_scale_mod": {m.name: list(m.scale) for m in mod_meshes},
        "camera": {"ortho": True, "view_height_m": round(view_h, 4), "center_z": round(zc, 4),
                   "res": [RES_W, RES_H], "sensor_fit": "VERTICAL"},
        "limits": [
            "Cape/skirt weighting issues in the source rig are NOT fixed by this study.",
            "Bone rest lengths changed (legs/torso/head); animation retarget test required before runtime use.",
            "No animation, no sprite/sheet, no gameplay or asset integration performed.",
            "Arm vertices preserve length (anchored at LeftArm/RightArm head); arms were not re-proportioned.",
            "Face identity preserved only via isotropic head scale + Head weight blend; no re-sculpt, no re-UV.",
            "Adult proportions NOT approved; art-director sign-off pending.",
        ],
    }
    with open(os.path.join(OUT, "settings.json"), "w") as f:
        json.dump(data, f, indent=2)
    print("RESULT_JSON " + json.dumps(data["measurements"]))
    print("checks_final " + json.dumps(checks))
    print("DONE")


try:
    main()
except SystemExit:
    raise
except Exception:
    traceback.print_exc(); print("FAIL: exception"); sys.exit(1)
