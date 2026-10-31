#!/usr/bin/env python3
"""inspect_canonical_template.py — Inspect canonical template rest matrices.
"""

from pathlib import Path
import bpy
from mathutils import Vector

TEMPLATE_PATH = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\templates\Rig_and_Attachments_Template.blend")
bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')

ORDER = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

print("Canonical Template Bones Rest Z vectors (in Armature space):")
for name in ORDER:
    b = rig.data.bones[name]
    ref_z = (b.matrix_local.to_3x3() @ Vector((0, 0, 1))).normalized()
    ref_y = (b.matrix_local.to_3x3() @ Vector((0, 1, 0))).normalized()
    ref_x = (b.matrix_local.to_3x3() @ Vector((1, 0, 0))).normalized()
    print(f"[{name:15s}] ref_z={ref_z[:]}, ref_y={ref_y[:]}, ref_x={ref_x[:]}")
