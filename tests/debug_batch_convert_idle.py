#!/usr/bin/env python3
"""debug_batch_convert_idle.py — Debug StandingIdle02 frame 1 vs 2 in batch_convert_v3.
"""

from pathlib import Path
import bpy
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
f_start = int(round(action.frame_range[0]))
f_end = int(round(action.frame_range[1]))
scene = bpy.context.scene
view = bpy.context.view_layer

source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}

print(f"f_start={f_start}, f_end={f_end}")

# Step 5
scene.frame_set(f_start)
view.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='POSE')

for name in batch_convert_v3.ORDER:
    sb = source.pose.bones[source_bones[name]]
    delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
    target_q = target_rest[name] @ delta_q
    pb = rig.pose.bones[name]
    pb.matrix = Matrix.Translation(pb.head) @ target_q.to_matrix().to_4x4()
view.update()

initial_dots = {part: batch_convert_v3.diagnose_bone_front_dot(rig, part) for part in ['LeftUpperLeg', 'LeftLowerLeg', 'RightUpperLeg', 'RightLowerLeg']}
print(f"Step 5 initial dots: {initial_dots}")

# Reset pose
for pb in rig.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
view.update()

# Step 7 for frames 1 to 5
for frame in range(f_start, f_start + 5):
    scene.frame_set(frame)
    view.update()
    
    for name in batch_convert_v3.ORDER:
        sb = source.pose.bones[source_bones[name]]
        delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
        target_q = target_rest[name] @ delta_q

        pb = rig.pose.bones[name]
        pos = pb.head.copy()
        pb.matrix = Matrix.Translation(pos) @ target_q.to_matrix().to_4x4()
    view.update()
    
    dots = {part: batch_convert_v3.diagnose_bone_front_dot(rig, part) for part in ['LeftUpperLeg', 'LeftLowerLeg', 'RightUpperLeg', 'RightLowerLeg']}
    print(f"Frame {frame} dots AFTER Step 7: {dots}")
    pb_rl = rig.pose.bones['RightLowerLeg']
    pb_ru = rig.pose.bones['RightUpperLeg']
    print(f"   pb.rotation_quaternion RU={pb_ru.rotation_quaternion[:]}, RL={pb_rl.rotation_quaternion[:]}")
    print(f"   pb.matrix RU={pb_ru.matrix.to_quaternion()[:]}, RL={pb_rl.matrix.to_quaternion()[:]}")
