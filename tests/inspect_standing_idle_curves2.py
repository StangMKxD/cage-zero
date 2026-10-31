#!/usr/bin/env python3
"""inspect_standing_idle_curves2.py — Inspect raw fcurves of StandingIdle02 with get_all_fcurves.
"""

from pathlib import Path
import bpy

blend_path = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3\StandingIdle02\StandingIdle02_R15_v03.blend")
bpy.ops.wm.open_mainfile(filepath=str(blend_path))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
action = rig.animation_data.action

def get_all_fcurves(action) -> list:
    legacy = getattr(action, "fcurves", None)
    if legacy is not None and len(legacy) > 0:
        return list(legacy)
    curves = []
    for layer in getattr(action, "layers", ()):
        for strip in getattr(layer, "strips", ()):
            for channelbag in getattr(strip, "channelbags", ()):
                curves.extend(channelbag.fcurves)
    return curves

curves = get_all_fcurves(action)
print(f"Total curves in action: {len(curves)}")

for bname in ['RightUpperLeg', 'RightLowerLeg', 'LeftUpperLeg', 'LeftLowerLeg']:
    b_curves = [c for c in curves if bname in c.data_path and 'rotation_quaternion' in c.data_path]
    print(f"\n--- {bname} Curves ({len(b_curves)}) ---")
    for c in sorted(b_curves, key=lambda x: x.array_index):
        pts = [kp.co.y for kp in c.keyframe_points]
        axis = ["W", "X", "Y", "Z"][c.array_index]
        print(f"{bname}.{axis}: F1={pts[0]:.4f}, F2={pts[1]:.4f}, F3={pts[2]:.4f}, F4={pts[3]:.4f}, F157={pts[-1]:.4f}")
