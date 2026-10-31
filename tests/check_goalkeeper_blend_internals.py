#!/usr/bin/env python3
"""check_goalkeeper_blend_internals.py — Deep inspection of goalkeeper .blend files in Blender.
"""

from pathlib import Path
import bpy
from mathutils import Vector, Matrix

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_V3 = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"

CLIPS = [
    "GoalkeeperCatch",
    "GoalkeeperDivingSave",
    "GoalkeeperOverhandThrow",
    "GoalkeeperScoop",
    "GoalkeeperSidestep"
]

print("=" * 75)
print(f"{'Clip Name':24s} | {'Frames':6s} | {'Worst Non-Root Bone':16s} | {'Max Loc Length':16s} | {'Loc FCurves':11s}")
print("-" * 75)

all_clean = True

for clip in CLIPS:
    bfile = TEST_OUTPUT_V3 / clip / f"{clip}_R15_v03.blend"
    bpy.ops.wm.open_mainfile(filepath=str(bfile))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    scene = bpy.context.scene
    action = rig.animation_data.action if rig.animation_data else None

    # Count location fcurves for non-root bones
    curves = list(getattr(action, "fcurves", []))
    non_root_loc_curves = [
        c for c in curves
        if "location" in c.data_path and "LowerTorso" not in c.data_path and "HumanoidRootPart" not in c.data_path
    ]

    f_start = int(round(action.frame_range[0])) if action else 1
    f_end = int(round(action.frame_range[1])) if action else 1
    total_frames = f_end - f_start + 1

    max_len = 0.0
    worst_bone = "None"

    for f in range(f_start, f_end + 1):
        scene.frame_set(f)
        bpy.context.view_layer.update()
        for pb in rig.pose.bones:
            if pb.name == 'LowerTorso':
                continue
            l = pb.location.length
            if l > max_len:
                max_len = l
                worst_bone = pb.name

    print(f"{clip:24s} | {total_frames:<6d} | {worst_bone:16s} | {max_len:.8f} studs | {len(non_root_loc_curves):<11d}")
    if max_len > 0.0 or len(non_root_loc_curves) > 0:
        all_clean = False

print("-" * 75)
print(f"ALL 5 GOALKEEPER .BLEND FILES ZERO TRANSLATION: {all_clean}")
print("=" * 75)
