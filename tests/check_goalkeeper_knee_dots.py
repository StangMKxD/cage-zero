#!/usr/bin/env python3
"""check_goalkeeper_knee_dots.py — Check knee front dot products across all frames for 5 GK clips.
"""

from pathlib import Path
import bpy
from mathutils import Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_V3 = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"

CLIPS = [
    "GoalkeeperCatch",
    "GoalkeeperDivingSave",
    "GoalkeeperOverhandThrow",
    "GoalkeeperScoop",
    "GoalkeeperSidestep"
]

def diagnose_bone_front_dot(rig, bone_name):
    pb = rig.pose.bones.get(bone_name)
    b = rig.data.bones.get(bone_name)
    if not pb or not b:
        return 0.0
    pb_z = pb.matrix.to_3x3() @ Vector((0, 0, 1))
    ref_z = b.matrix_local.to_3x3() @ Vector((0, 0, 1))
    if pb_z.length < 1e-6 or ref_z.length < 1e-6:
        return 0.0
    return float(pb_z.normalized().dot(ref_z.normalized()))

print("=" * 80)
print(f"{'Clip Name':24s} | {'Left Knee (Min/Med/Max)':26s} | {'Right Knee (Min/Med/Max)':26s}")
print("-" * 80)

for clip in CLIPS:
    bfile = TEST_OUTPUT_V3 / clip / f"{clip}_R15_v03.blend"
    bpy.ops.wm.open_mainfile(filepath=str(bfile))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    scene = bpy.context.scene
    action = rig.animation_data.action if rig.animation_data else None

    f_start = int(round(action.frame_range[0])) if action else 1
    f_end = int(round(action.frame_range[1])) if action else 1

    left_dots = []
    right_dots = []
    for f in range(f_start, f_end + 1):
        scene.frame_set(f)
        bpy.context.view_layer.update()
        left_dots.append(diagnose_bone_front_dot(rig, "LeftLowerLeg"))
        right_dots.append(diagnose_bone_front_dot(rig, "RightLowerLeg"))

    l_min, l_max = min(left_dots), max(left_dots)
    l_med = sorted(left_dots)[len(left_dots) // 2]
    r_min, r_max = min(right_dots), max(right_dots)
    r_med = sorted(right_dots)[len(right_dots) // 2]

    l_str = f"{l_min:.2f} / {l_med:.2f} / {l_max:.2f}"
    r_str = f"{r_min:.2f} / {r_med:.2f} / {r_max:.2f}"
    print(f"{clip:24s} | {l_str:26s} | {r_str:26s}")

print("=" * 80)
