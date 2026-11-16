import bpy, json
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"C:/Users/AUC/opencode-workspace/workspace/new-vania-proto-v3-patch/prototypes/feel-v3/tools/models/pandora_rigged.glb")
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
print("BONES", len(arm.data.bones))
for b in arm.data.bones:
    print("  B", b.name, "<-", b.parent.name if b.parent else None)
for m in [o for o in bpy.data.objects if o.type == 'MESH']:
    lo = [1e9]*3; hi = [-1e9]*3
    M = m.matrix_world
    for v in m.data.vertices:
        w = M @ v.co
        for i in range(3):
            lo[i] = min(lo[i], w[i]); hi[i] = max(hi[i], w[i])
    print("MESH", m.name, "verts", len(m.data.vertices), "parent", m.parent.name if m.parent else None,
          "mods", [(md.type, getattr(md, 'object', None).name if getattr(md, 'object', None) else None) for md in m.modifiers],
          "vgroups", len(m.vertex_groups), "uv", [l.name for l in m.data.uv_layers],
          "scale", tuple(round(x, 4) for x in m.scale),
          "bbox", [round(x, 3) for x in lo], [round(x, 3) for x in hi])
print("MATS", [ms.material.name if ms.material else None for m in [o for o in bpy.data.objects if o.type == 'MESH'] for ms in m.material_slots])
