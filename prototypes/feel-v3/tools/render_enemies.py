"""Render enemy 3D models into raw 4x pose frames for the 2x pixel-art enemy sprites.

Run (see tools/render_enemies_post.py for the second step that makes the final pixel art):

  blender --background --factory-startup --python tools/render_enemies.py -- \
      --kind crab [--anim walk] [--out <raw dir>] [--measure] [--ppu-scale 1.0]

Raw frames go to <out>/<kind>/<anim>_NN.png (RGBA, 4x the final canvas) and
<out>/<kind>/frames.json (per-frame extras for the post step: glow, puddle ...).
Only reads tools/models/bank/*.glb. Never writes outside --out.
"""

import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "tools/models/bank"
SS = 4  # supersampling: raw render = 4x final canvas

AX = {"x": (1, 0, 0), "y": (0, 1, 0), "z": (0, 0, 1)}


def enum(owner, prop, value):
    """Validate enum identifiers against this installed Blender version."""
    allowed = {item.identifier for item in owner.bl_rna.properties[prop].enum_items}
    assert value in allowed, (prop, value, allowed)
    setattr(owner, prop, value)


# --------------------------------------------------------------------------
# per-kind configuration
# fit = (anim, frame, "width"|"height", px): that pose's image-plane size is
# scaled to px final pixels, which fixes the camera for every frame of the kind.
# ref = which point of that pose sits on the anchor pixel.
# --------------------------------------------------------------------------
KINDS = {
    "crab": dict(glb="crab_custom_rig.glb", canvas=(112, 72), anchor=(56, 71), ref="bottom",
                 fit=(None, 0, "width", 88), yaw=5),
    "moth": dict(glb="moth_custom_rig.glb", canvas=(112, 96), anchor=(56, 52), ref="center",
                 fit=(None, 0, "width", 90), yaw=0),
    "scribe": dict(glb="needle_scribe_rig.glb", canvas=(72, 120), anchor=(37, 60), ref="center",
                   fit=(None, 0, "height", 98), yaw=62),
    "leech": dict(glb="leech_custom_rig.glb", canvas=(40, 88), anchor=(20, 1), ref="top",
                  fit=("hang", 0, "height", 72), yaw=0, ref_x=-0.02),
    "organ": dict(glb=None, plain="landmark_memory_organ.glb", canvas=(256, 288), anchor=(128, 286), ref="bottom",
                  fit=(None, 0, "height", 280), yaw=0, gain=0.45),
}


# --------------------------------------------------------------------------
# scene
# --------------------------------------------------------------------------
class Scene:
    def __init__(self, kind):
        self.kind = kind
        self.cfg = KINDS[kind]
        bpy.ops.wm.read_factory_settings(use_empty=True)
        glb = self.cfg.get("glb") or self.cfg["plain"]
        bpy.ops.import_scene.gltf(filepath=str(BANK / glb))
        self.scene = bpy.context.scene
        for obj in list(self.scene.objects):
            if obj.name.startswith("Icosphere"):  # Rodin rigging helper, not part of the model
                bpy.data.objects.remove(obj, do_unlink=True)
        self.rig = next((o for o in self.scene.objects if o.type == "ARMATURE"), None)
        self.meshes = [o for o in self.scene.objects if o.type == "MESH"]
        self.mesh = self.meshes[0]
        if self.rig:
            self.rig.animation_data_clear()  # stock animations would overwrite every pose we set
            for pb in self.rig.pose.bones:
                enum(pb, "rotation_mode", "QUATERNION")
        self.root = self.rig or self.mesh  # object that carries the whole-body transform
        self.root.rotation_mode = "XYZ"  # glTF import leaves armatures in QUATERNION mode, which ignores rotation_euler
        self.fix_materials()
        self.px_per_unit = None
        self.fit_top_z = 0.0
        self.setup_render()

    def fix_materials(self):
        """The Rodin 'shaded' texture is wired to Emission only: feed it to Base Color too so lights shape it."""
        for mat in bpy.data.materials:
            nt = mat.node_tree
            bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
            tex = next((n for n in nt.nodes if n.type == "TEX_IMAGE"), None)
            if tex:
                nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
                bsdf.inputs["Emission Strength"].default_value = 0.30 * self.cfg.get("gain", 1.0)
            bsdf.inputs["Roughness"].default_value = 0.62
            bsdf.inputs["Metallic"].default_value = 0.0

    def setup_render(self):
        sc = self.scene
        sc.render.engine = "BLENDER_EEVEE"
        enum(sc.render.image_settings, "file_format", "PNG")
        enum(sc.render.image_settings, "color_mode", "RGBA")
        sc.render.film_transparent = True
        sc.render.resolution_percentage = 100
        sc.render.filter_size = 0.9
        sc.eevee.taa_render_samples = 24
        # dynamic enum (bl_rna lists only NONE): assign, then read back to confirm
        sc.view_settings.view_transform = "Standard"
        assert sc.view_settings.view_transform == "Standard", sc.view_settings.view_transform
        sc.view_settings.look = "None"
        w, h = self.cfg["canvas"]
        sc.render.resolution_x, sc.render.resolution_y = w * SS, h * SS
        world = bpy.data.worlds.new("EnemyWorld")
        world.use_nodes = True
        bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
        bg.inputs[0].default_value = (0.20, 0.22, 0.30, 1)
        gain = self.cfg.get("gain", 1.0)
        bg.inputs[1].default_value = 0.55 * gain
        sc.world = world
        # key: upper left, front; fill: weak, right; rim: cool, from behind
        self.sun("Key", direction=(0.55, 0.62, -0.62), color=(1.0, 0.93, 0.82), strength=3.0 * gain)
        self.sun("Fill", direction=(-0.6, 0.7, -0.2), color=(0.72, 0.78, 1.0), strength=0.8 * gain)
        self.sun("Rim", direction=(-0.35, -0.85, -0.25), color=(0.45, 0.70, 1.0), strength=8.0 * max(gain, 0.5))
        cam = bpy.data.cameras.new("EnemyCam")
        enum(cam, "type", "ORTHO")
        enum(cam, "sensor_fit", "HORIZONTAL")
        cam.clip_start, cam.clip_end = 0.1, 100
        self.cam = bpy.data.objects.new("EnemyCam", cam)
        sc.collection.objects.link(self.cam)
        sc.camera = self.cam
        self.cam.rotation_euler = (math.radians(90), 0, 0)  # looks along +Y, up = +Z

    def sun(self, name, direction, color, strength):
        data = bpy.data.lights.new(name, "SUN")
        data.energy, data.color = strength, color
        data.angle = math.radians(8)
        obj = bpy.data.objects.new(name, data)
        self.scene.collection.objects.link(obj)
        obj.rotation_euler = Vector(direction).normalized().to_track_quat("-Z", "Y").to_euler()

    # ---------------- posing ----------------
    def reset(self):
        if self.rig:
            for pb in self.rig.pose.bones:
                pb.matrix_basis = Matrix.Identity(4)
        self.root.location = (0, 0, 0)
        self.root.rotation_euler = (0, 0, 0)
        self.root.scale = (1, 1, 1)
        bpy.context.view_layer.update()

    def turn(self, bone, axis, degrees, pivot=None):
        """Rotate a bone about an armature-space axis through its head (or `pivot`)."""
        pb = self.rig.pose.bones[bone]
        head = Vector(pivot) if pivot is not None else pb.head.copy()
        rot = Quaternion(Vector(AX[axis]), math.radians(degrees)).to_matrix().to_4x4()
        pb.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ pb.matrix
        bpy.context.view_layer.update()

    def move(self, bone, delta):
        pb = self.rig.pose.bones[bone]
        pb.matrix = Matrix.Translation(Vector(delta)) @ pb.matrix
        bpy.context.view_layer.update()

    def aim(self, bone, head, direction):
        """Point a bone along `direction` (armature space) with its head at `head`; keeps its length."""
        pb = self.rig.pose.bones[bone]
        rest = pb.bone.matrix_local
        rest_dir = (pb.bone.tail_local - pb.bone.head_local).normalized()
        q = rest_dir.rotation_difference(Vector(direction).normalized())
        m3 = q.to_matrix() @ rest.to_3x3()
        pb.matrix = Matrix.Translation(Vector(head)) @ m3.to_4x4()
        bpy.context.view_layer.update()

    def tail(self, bone):
        return self.rig.pose.bones[bone].tail.copy()

    def head(self, bone):
        return self.rig.pose.bones[bone].head.copy()

    def apply(self, pose):
        """pose = dict(ops=[...], obj=dict(yaw, sx, sy, sz, dx, dz, foot))."""
        self.reset()
        for op in pose.get("ops", []):
            kind = op[0]
            if kind == "rot":
                self.turn(op[1], op[2], op[3], op[4] if len(op) > 4 else None)
            elif kind == "move":
                self.move(op[1], op[2])
            elif kind == "call":
                op[1](self)
        o = pose.get("obj", {})
        yaw = o.get("yaw", self.cfg["yaw"])
        self.root.rotation_euler = (0, math.radians(o.get("roll", 0.0)), math.radians(yaw))
        sx, sy, sz = o.get("sx", 1.0), o.get("sy", o.get("sx", 1.0)), o.get("sz", 1.0)
        self.root.scale = (sx, sy, sz)
        foot = o.get("foot", self.fit_top_z if o.get("pivot") == "top" else self.foot_z)
        self.root.location = (o.get("dx", 0.0), 0.0, foot * (1 - sz) + o.get("dz", 0.0))
        bpy.context.view_layer.update()

    # ---------------- measuring ----------------
    def world_points(self):
        deps = bpy.context.evaluated_depsgraph_get()
        pts = []
        for m in self.meshes:
            ev = m.evaluated_get(deps)
            me = ev.to_mesh()
            n = len(me.vertices)
            co = np.empty(n * 3, dtype=np.float32)
            me.vertices.foreach_get("co", co)
            co = co.reshape(-1, 3)
            mw = np.array(ev.matrix_world)
            pts.append(co @ mw[:3, :3].T + mw[:3, 3])
            ev.to_mesh_clear()
        return np.concatenate(pts)

    def bounds(self):
        p = self.world_points()
        return p.min(axis=0), p.max(axis=0)

    def frame_camera(self, anims):
        """Fix ppu and camera from the fit pose, then every frame uses the same camera."""
        fit_anim, fit_i, dim, px = self.cfg["fit"]
        self.foot_z = 0.0
        self.reset()
        lo, hi = self.bounds()
        self.foot_z = float(lo[2])  # rest ground height, used as squash pivot
        self.apply(anims[fit_anim](fit_i) if fit_anim else {"ops": [], "obj": {}})
        lo, hi = self.bounds()
        self.fit_top_z = float(hi[2])
        size = hi - lo
        extent = size[0] if dim == "width" else size[2]
        ppu = px / extent
        W, H = self.cfg["canvas"]
        ax, ay = self.cfg["anchor"]
        ref = self.cfg["ref"]
        rx = self.cfg.get("ref_x", (lo[0] + hi[0]) / 2)
        rz = {"bottom": lo[2], "center": (lo[2] + hi[2]) / 2, "top": hi[2]}[ref]
        cx = rx - (ax - W / 2) / ppu
        cz = rz + (ay - H / 2) / ppu
        self.px_per_unit = ppu
        self.cam_xz = (cx, cz)
        self.cam.data.ortho_scale = W / ppu
        self.cam.location = (cx, -30.0, cz)
        bpy.context.view_layer.update()
        return ppu

    def to_px(self, pts):
        cx, cz = self.cam_xz
        W, H = self.cfg["canvas"]
        x = W / 2 + (pts[:, 0] - cx) * self.px_per_unit
        y = H / 2 - (pts[:, 2] - cz) * self.px_per_unit
        return x, y

    def px_bounds(self):
        x, y = self.to_px(self.world_points())
        return float(x.min()), float(y.min()), float(x.max()), float(y.max())

    def render(self, path):
        self.scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)


# --------------------------------------------------------------------------
# animations: each kind maps anim name -> (frame count, pose function(i) -> pose dict)
# --------------------------------------------------------------------------
sys.path.insert(0, str(Path(__file__).resolve().parent))
import render_enemies_poses as P  # noqa: E402


def parse(argv):
    args = {"kind": None, "anim": None, "out": None, "measure": False, "frame": None}
    it = iter(argv)
    for a in it:
        if a == "--kind":
            args["kind"] = next(it)
        elif a == "--anim":
            args["anim"] = next(it)
        elif a == "--out":
            args["out"] = next(it)
        elif a == "--frame":
            args["frame"] = int(next(it))
        elif a == "--measure":
            args["measure"] = True
    return args


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parse(argv)
    kind = args["kind"]
    assert kind in KINDS, kind
    sc = Scene(kind)
    table = P.ANIMS[kind]  # name -> (count, fn)
    anims = {name: fn for name, (count, fn) in table.items()}
    ppu = sc.frame_camera(anims)
    print("PPU", kind, round(ppu, 2), flush=True)
    out = Path(args["out"]) / kind
    out.mkdir(parents=True, exist_ok=True)
    extras = {}
    W, H = sc.cfg["canvas"]
    for name, (count, fn) in table.items():
        if args["anim"] and name != args["anim"]:
            continue
        extras[name] = []
        for i in range(count):
            if args["frame"] is not None and i != args["frame"]:
                continue
            pose = fn(i)
            sc.apply(pose)
            ex = dict(pose.get("extra", {}))
            if "extra_fn" in pose:
                ex.update(pose["extra_fn"](sc))
            extras[name].append(ex)
            if args["measure"]:
                x0, y0, x1, y1 = sc.px_bounds()
                flag = "" if (x0 >= 0 and y0 >= 0 and x1 <= W and y1 <= H) else "  <-- OUT OF CANVAS"
                print(f"BOUNDS {name}_{i:02d} x {x0:6.1f}..{x1:6.1f}  y {y0:6.1f}..{y1:6.1f}{flag}", flush=True)
            else:
                sc.render(out / f"{name}_{i:02d}.png")
    if not args["measure"]:
        (out / f"frames_{args['anim'] or 'all'}.json").write_text(json.dumps(extras))
        print("RENDERED", kind, flush=True)


if __name__ == "__main__":
    main()
