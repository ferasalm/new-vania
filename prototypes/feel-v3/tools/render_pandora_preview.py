"""Original-pose spike, not production animation. No traced sources are read.

Run: blender --background --factory-startup --python tools/render_pandora_preview.py
Outputs four transparent 112x80 frames, large review renders, and packed .blend.
Existing scenes and source GLB are preserved. Refuses to overwrite its blend.
"""

import hashlib
import json
import math
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/models/pandora_rigged.glb"
OUT = ROOT / "assets/hero_3d_preview"
BLEND = OUT / "pandora_pose_preview.blend"


def enum(owner, prop, value):
    """Validate enum identifiers against this installed Blender version."""
    allowed = {item.identifier for item in owner.bl_rna.properties[prop].enum_items}
    assert value in allowed, (prop, value, allowed)
    setattr(owner, prop, value)


def aim(obj, point):
    """Point a camera/light at a world-space position."""
    obj.rotation_euler = (Vector(point) - obj.location).to_track_quat("-Z", "Y").to_euler()


def turn(rig, name, axis, degrees):
    """Rotate a bone about an armature-space axis, preserving its head."""
    bone = rig.pose.bones[name]
    head = bone.head.copy()
    rot = Quaternion(Vector(axis), math.radians(degrees)).to_matrix().to_4x4()
    bone.matrix = Matrix.Translation(head) @ rot @ Matrix.Translation(-head) @ bone.matrix
    bpy.context.view_layer.update()


def build():
    """Render four independent original pose studies and save their source scene."""
    assert SOURCE.is_file(), SOURCE
    assert not BLEND.exists(), f"Refusing to overwrite {BLEND}; archive it before rerunning"
    OUT.mkdir(parents=True, exist_ok=True)
    scene = bpy.data.scenes.new("PandoraPreview")
    bpy.context.window.scene = scene
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    rig = next(obj for obj in scene.objects if obj.type == "ARMATURE")
    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    assert len(rig.pose.bones) >= 50
    assert any(mod.type == "ARMATURE" for obj in meshes for mod in obj.modifiers)
    for bone in rig.pose.bones:
        enum(bone, "rotation_mode", "QUATERNION")

    world = bpy.data.worlds.new("PandoraPreviewWorld")
    world.use_nodes = True
    bg = next(node for node in world.node_tree.nodes if node.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.25, 0.3, 0.38, 1)
    bg.inputs[1].default_value = 0.7
    scene.world = world
    for name, pos, power, size in (
        ("PreviewKey", (-3, -4, 5), 650, 4),
        ("PreviewFill", (-4, 2, 2), 450, 3),
        ("PreviewRim", (2, 1, 3), 750, 2),
    ):
        kind = next(item.identifier for item in bpy.types.Light.bl_rna.properties["type"].enum_items if item.identifier == "AREA")
        data = bpy.data.lights.new(name, kind)
        data.energy, data.size = power, size
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = pos
        aim(obj, (0, 0, 0))

    data = bpy.data.cameras.new("PandoraPreviewCamera")
    enum(data, "type", "ORTHO")
    # Blender ortho_scale is horizontal at this landscape aspect ratio.
    data.ortho_scale = 2.4 * (112 / 80)
    camera = bpy.data.objects.new("PandoraPreviewCamera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    enum(scene.render.image_settings, "file_format", "PNG")
    enum(scene.render.image_settings, "color_mode", "RGBA")
    scene.render.fps = 12
    scene.frame_start, scene.frame_end = 1, 4
    initial = {bone.name: bone.matrix_basis.copy() for bone in rig.pose.bones}
    rest_rig = rig.location.copy()
    x, y, z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
    # Hand-authored pose studies: quiet guard, running push-off, wall reach,
    # and open-hand casting. All angles are newly chosen for this prototype.
    poses = {
        "idle": [("Spine", x, 4), ("LeftArm", x, -20), ("LeftForeArm", x, -35), ("RightArm", x, 8), ("RightForeArm", x, -20)],
        "run": [("Spine", x, 12), ("LeftUpLeg", x, -42), ("LeftLeg", x, 32), ("RightUpLeg", x, 30), ("RightLeg", x, 58), ("LeftArm", x, 30), ("LeftForeArm", x, -65), ("RightArm", x, -40), ("RightForeArm", x, -55)],
        "wall": [("Spine", x, 7), ("LeftArm", x, -110), ("LeftForeArm", x, -22), ("RightArm", x, -95), ("RightForeArm", x, -40), ("LeftUpLeg", x, -68), ("LeftLeg", x, 80), ("RightUpLeg", x, 10), ("RightLeg", x, 25)],
        "cast": [("Spine", x, 4), ("LeftArm", x, -75), ("LeftForeArm", x, -15), ("LeftHand", z, -12), ("RightArm", x, 18), ("RightForeArm", x, -40), ("LeftUpLeg", x, -10), ("RightUpLeg", x, 12)],
    }
    results = []
    for frame, (name, rotations) in enumerate(poses.items(), 1):
        scene.frame_set(frame)
        rig.location = rest_rig
        for bone in rig.pose.bones:
            bone.matrix_basis = initial[bone.name]
        bpy.context.view_layer.update()
        for bone, axis, angle in rotations:
            turn(rig, bone, axis, angle)
        deps = bpy.context.evaluated_depsgraph_get()
        coords = [obj.matrix_world @ Vector(corner) for mesh in meshes for obj in [mesh.evaluated_get(deps)] for corner in obj.bound_box]
        lowest = min(coord.z for coord in coords)
        rig.location.z -= lowest
        bpy.context.view_layer.update()
        rig.keyframe_insert(data_path="location", frame=frame)
        for bone in rig.pose.bones:
            bone.keyframe_insert(data_path="rotation_quaternion", frame=frame)
            bone.keyframe_insert(data_path="location", frame=frame)
            bone.keyframe_insert(data_path="scale", frame=frame)
        # Slight front-facing side view; heroine faces screen-right.
        target = Vector((0, 0, 1.08))
        camera.location = target + Vector((-8, -2.6, 0))
        aim(camera, target)
        for suffix, width, height in (("_review", 448, 320), ("_00", 112, 80)):
            scene.render.resolution_x, scene.render.resolution_y = width, height
            scene.render.filepath = str(OUT / f"{name}{suffix}.png")
            bpy.ops.render.render(write_still=True)
        image = OUT / f"{name}_00.png"
        results.append({"pose": name, "frame": frame, "sha256": hashlib.sha256(image.read_bytes()).hexdigest()})
        print("POSE_RENDERED", name, flush=True)
    assert len({row["sha256"] for row in results}) == 4, "Pose renders must differ"
    scene.frame_set(1)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND))
    (OUT / "preview.json").write_text(json.dumps({"source": "tools/models/pandora_rigged.glb", "original_poses": True, "production_ready": False, "size": [112, 80], "feet_target": [56, 76], "poses": results}, indent=2) + "\n")
    print("PREVIEW PASS: 4 distinct original poses, packed blend saved", flush=True)


if __name__ == "__main__":
    build()
