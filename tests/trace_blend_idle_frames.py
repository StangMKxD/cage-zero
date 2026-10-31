#!/usr/bin/env python3
"""trace_blend_idle_frames.py — Check knee dots in StandingIdle02_R15_v03.blend.
"""

from pathlib import Path
import bpy
from mathutils import Vector

blend_path = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3\StandingIdle02\StandingIdle02_R15_v03.blend")
bpy.ops.wm.open_mainfile(filepath=str(blend_path))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')

def compute_bone_front_dot(rig, bone_name):
    pb = rig.pose.bones.get(bone_name)
    b = rig.data.bones.get(bone_name)
    pb_z = pb.matrix.to_3x3() @ Vector((0, 0, 1))
    ref_z = b.matrix_local.to_3x3() @ Vector((0, 0, 1))
    return float(pb_z.normalized().dot(ref_z.normalized()))

dots_rl = []
dots_ll = []
for f in range(1, 158):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    rl = compute_bone_front_dot(rig, 'RightLowerLeg')
    ll = compute_bone_front_dot(rig, 'LeftLowerLeg')
    dots_rl.append(rl)
    dots_ll.append(ll)

print(f"Max Left: {max(dots_ll):.4f}, Min Left: {min(dots_ll):.4f}")
print(f"Max Right: {max(dots_rl):.4f}, Min Right: {min(dots_rl):.4f}")
print(f"Frame 1: Left={dots_ll[0]:.4f}, Right={dots_rl[0]:.4f}")
print(f"Frame 2: Left={dots_ll[1]:.4f}, Right={dots_rl[1]:.4f}")
print(f"Frame 3: Left={dots_ll[2]:.4f}, Right={dots_rl[2]:.4f}")
print(f"Frame 10: Left={dots_ll[9]:.4f}, Right={dots_rl[9]:.4f}")
print(f"Frame 50: Left={dots_ll[49]:.4f}, Right={dots_rl[49]:.4f}")
print(f"Frame 100: Left={dots_ll[99]:.4f}, Right={dots_rl[99]:.4f}")
