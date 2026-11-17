# Headless Blender: import a .glb, print its skeleton, render four flat views.
#   blender -b -P probe_rig.py -- <in.glb> <out_prefix>
import math
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, out = args[0], args[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
objs = list(bpy.context.scene.objects)
lo = Vector((1e9, 1e9, 1e9))
hi = Vector((-1e9, -1e9, -1e9))
for o in objs:
    print("OBJ", o.type, o.name, [round(v, 3) for v in o.dimensions], "parent", o.parent.name if o.parent else None)
    if o.type == "MESH":
        print("  verts", len(o.data.vertices), "polys", len(o.data.polygons), "groups", len(o.vertex_groups),
              "mods", [m.type for m in o.modifiers])
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c)
            lo = Vector((min(lo[i], w[i]) for i in range(3)))
            hi = Vector((max(hi[i], w[i]) for i in range(3)))
    if o.type == "ARMATURE":
        for b in o.data.bones:
            h = o.matrix_world @ b.head_local
            t = o.matrix_world @ b.tail_local
            print("  BONE %-28s parent=%-24s head=%s tail=%s" % (b.name, b.parent.name if b.parent else "-",
                  [round(v, 3) for v in h], [round(v, 3) for v in t]))
print("BOUNDS", [round(v, 3) for v in lo], [round(v, 3) for v in hi])
print("ACTIONS", [a.name for a in bpy.data.actions])

sc = bpy.context.scene
try:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE"
sc.render.film_transparent = True
sc.render.resolution_x = 400
sc.render.resolution_y = 400
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[0].default_value = (1, 1, 1, 1)
world.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sc.world = world
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
mid = (lo + hi) / 2
size = max(hi[i] - lo[i] for i in range(3)) * 1.15
cam_data.ortho_scale = size
for name, d in (("front", (0, -1, 0)), ("right", (1, 0, 0)), ("left", (-1, 0, 0)), ("back", (0, 1, 0))):
    dv = Vector(d)
    cam.location = mid + dv * 10
    cam.rotation_euler = (-dv).to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = "%s_%s.png" % (out, name)
    bpy.ops.render.render(write_still=True)
