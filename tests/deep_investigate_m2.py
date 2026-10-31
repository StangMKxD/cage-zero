#!/usr/bin/env python3
"""deep_investigate_m2.py — Deep inspect source FBXs and template.
"""

import math
from pathlib import Path
import bpy
from mathutils import Matrix, Quaternion, Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"

print("=" * 70)
print("PART 1: Inspect Standing Idle 02 in .blend")
print("=" * 70)
idle_blend = TEST_OUTPUT_DIR / "StandingIdle02" / "StandingIdle02_R15_v03.blend"
bpy.ops.wm.open_mainfile(filepath=str(idle_blend))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
action = rig.animation_data.action

def compute_bone_front_dot(rig, bone_name):
    pb = rig.pose.bones.get(bone_name)
    b = rig.data.bones.get(bone_name)
    pb_z = pb.matrix.to_3x3() @ Vector((0, 0, 1))
    ref_z = b.matrix_local.to_3x3() @ Vector((0, 0, 1))
    return float(pb_z.normalized().dot(ref_z.normalized()))

print("Frame by frame for StandingIdle02 (frames 1 to 10):")
for f in range(1, 11):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    pb_rl = rig.pose.bones['RightLowerLeg']
    pb_ru = rig.pose.bones['RightUpperLeg']
    pb_ll = rig.pose.bones['LeftLowerLeg']
    pb_lu = rig.pose.bones['LeftUpperLeg']
    dot_rl = compute_bone_front_dot(rig, 'RightLowerLeg')
    dot_ru = compute_bone_front_dot(rig, 'RightUpperLeg')
    dot_ll = compute_bone_front_dot(rig, 'LeftLowerLeg')
    dot_lu = compute_bone_front_dot(rig, 'LeftUpperLeg')
    print(f"F{f:02d}: RL_dot={dot_rl:.4f}, RU_dot={dot_ru:.4f} | LL_dot={dot_ll:.4f}, LU_dot={dot_lu:.4f}")
    print(f"     RL_quat={pb_rl.rotation_quaternion[:]}")

print("\n" + "=" * 70)
print("PART 2: Inspect Source FBX for Standing Idle 02")
print("=" * 70)
bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_path = SOURCE_DIR / "Standing Idle 02.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_path))
src_arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o.name != 'Armature' and o.name != 'StudioR15_Target')
print(f"Imported source FBX: {src_arm.name}")
print(f"Source frame range: {src_arm.animation_data.action.frame_range[:]}")

# Check source right leg bone rotations / front vectors
for f in range(1, 11):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    # Find right leg bones in Mixamo
    r_leg = src_arm.pose.bones.get('mixamorig:RightLeg') or src_arm.pose.bones.get('RightLeg')
    r_up_leg = src_arm.pose.bones.get('mixamorig:RightUpLeg') or src_arm.pose.bones.get('RightUpLeg')
    if r_leg:
        print(f"Src F{f:02d}: RightLeg quat={r_leg.rotation_quaternion[:] if r_leg.rotation_mode == 'QUATERNION' else r_leg.matrix.to_quaternion()[:]}")

print("\n" + "=" * 70)
print("PART 3: Inspect SoccerTrip in source FBX and .blend")
print("=" * 70)
bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_trip = SOURCE_DIR / "Soccer Trip.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_trip))
src_trip = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o.name != 'Armature' and o.name != 'StudioR15_Target')
hips = src_trip.pose.bones.get('mixamorig:Hips') or src_trip.pose.bones.get('Hips')
print(f"Source SoccerTrip Hips motion:")
for f in [1, 10, 20, 30, 40, 49]:
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    print(f"Src F{f:02d}: Hips head={hips.head[:]}, location={hips.location[:]}")

print("\n" + "=" * 70)
print("PART 4: Check batch_convert_v3.py Step 5 & Step 7 on Standing Idle 02")
print("=" * 70)
# Let's inspect what apply_leg_roll got diagnosed for StandingIdle02
import sys
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3
print(f"batch_convert_v3 loaded from {batch_convert_v3.__file__}")
