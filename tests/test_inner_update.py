import bpy
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector
import sys

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

action = source.animation_data.action
scene = bpy.context.scene
view = bpy.context.view_layer

source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}

print("\n--- Test 1: Step 7 WITHOUT view.update inside bone loop (current code) ---")
for frame in range(1, 6):
    scene.frame_set(frame)
    view.update()
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
    
    dots = {p: batch_convert_v3.diagnose_bone_front_dot(rig, p) for p in ['LeftLowerLeg', 'RightLowerLeg']}
    print(f"Frame {frame} (no inner update): {dots}")

print("\n--- Test 2: Step 7 WITH view.update inside bone loop ---")
for frame in range(1, 6):
    scene.frame_set(frame)
    view.update()
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
    
    dots = {p: batch_convert_v3.diagnose_bone_front_dot(rig, p) for p in ['LeftLowerLeg', 'RightLowerLeg']}
    print(f"Frame {frame} (with inner update): {dots}")
