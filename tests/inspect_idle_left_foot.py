#!/usr/bin/env python3
"""inspect_idle_left_foot.py — Inspect LeftFoot pivot in StandingIdle02.
"""

from pathlib import Path
import bpy
from mathutils import Vector

blend_path = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\test_output_v3\StandingIdle02\StandingIdle02_R15_v03.blend")
bpy.ops.wm.open_mainfile(filepath=str(blend_path))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')

pb_foot = rig.pose.bones['LeftFoot']
b_foot = rig.data.bones['LeftFoot']
pb_parent = pb_foot.parent
b_parent = b_foot.parent

p_mat_rest = b_parent.matrix_local
head_in_parent = p_mat_rest.inverted() @ b_foot.head_local

print(f"LeftFoot rest head in parent space: {head_in_parent[:]}")
print(f"LeftFoot bone head local: {b_foot.head_local[:]}")
print(f"LeftLowerLeg bone head local: {b_parent.head_local[:]}")

for f in [1, 2, 3, 10, 47, 100]:
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    expected_head = pb_parent.matrix @ head_in_parent
    actual_head = pb_foot.head
    dev = (actual_head - expected_head).length
    print(f"F{f:03d}: actual={actual_head[:]}, expected={expected_head[:]}, dev={dev:.8f} studs")
