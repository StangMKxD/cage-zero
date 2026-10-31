import bpy
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector
import sys
import math

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_file = SOURCE_DIR / "Standing Idle 02.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_file))
rig = batch_convert_v3.get_canonical_armature()
source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)
scene = bpy.context.scene
view = bpy.context.view_layer

source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}

scene.frame_set(10)
for pb in rig.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
view.update()

for name in batch_convert_v3.ORDER:
    sb = source.pose.bones[source_bones[name]]
    delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
    target_q = target_rest[name] @ delta_q
    pb = rig.pose.bones[name]
    pos = pb.head.copy()
    pb.matrix = Matrix.Translation(pos) @ target_q.to_matrix().to_4x4()
    view.update()

for part in ['LeftLowerLeg', 'RightLowerLeg']:
    pb = rig.pose.bones[part]
    b = rig.data.bones[part]
    pb_z = (pb.matrix.to_3x3() @ Vector((0, 0, 1))).normalized()
    ref_z = (b.matrix_local.to_3x3() @ Vector((0, 0, 1))).normalized()
    dot = pb_z.dot(ref_z)
    angle_deg = math.degrees(math.acos(max(-1.0, min(1.0, dot))))
    print(f"{part}:")
    print(f"  pb_z (posed front vector): {pb_z[:]}")
    print(f"  ref_z (rest front vector): {ref_z[:]}")
    print(f"  dot: {dot:.4f}, angle from rest forward: {angle_deg:.1f} deg")
    
    # Also check world Y (Blender global forward)
    world_forward = Vector((0, -1, 0)) # Roblox forward is -Z or Blender forward is -Y?
    # In canonical template, let's see what direction character faces in Blender:
    head_b = rig.data.bones['Head']
    head_front = (head_b.matrix_local.to_3x3() @ Vector((0, 0, 1))).normalized()
    print(f"  Head rest front: {head_front[:]}")
