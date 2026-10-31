#!/usr/bin/env python3
"""trace_standing_idle.py — Trace Standing Idle 02 conversion frame by frame.
"""

import math
from pathlib import Path
import bpy
from mathutils import Matrix, Quaternion, Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_path = SOURCE_DIR / "Standing Idle 02.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_path))

rig = bpy.data.objects.get('StudioR15_Target') or bpy.data.objects.get('Armature')
source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)

ORDER = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

MAPPING = {
    'RightUpperLeg': 'mixamorig:RightUpLeg',
    'RightLowerLeg': 'mixamorig:RightLeg',
    'RightFoot': 'mixamorig:RightFoot',
}

source_rest = {n: source.data.bones[MAPPING[n]].matrix_local.to_quaternion() for n in MAPPING}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in MAPPING}

print("Tracing Step 7 calculation for RightUpperLeg and RightLowerLeg on frames 1, 2, 3:")
for f in range(1, 6):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    
    for name in ['RightUpperLeg', 'RightLowerLeg']:
        sb = source.pose.bones[MAPPING[name]]
        sb_q = sb.matrix.to_quaternion()
        delta_q = source_rest[name].inverted() @ sb_q
        target_q = target_rest[name] @ delta_q
        
        pb = rig.pose.bones[name]
        pos = pb.head.copy()
        pb.matrix = Matrix.Translation(pos) @ target_q.to_matrix().to_4x4()
    bpy.context.view_layer.update()

    for name in ['RightUpperLeg', 'RightLowerLeg']:
        pb = rig.pose.bones[name]
        b = rig.data.bones[name]
        pb_z = pb.matrix.to_3x3() @ Vector((0, 0, 1))
        ref_z = b.matrix_local.to_3x3() @ Vector((0, 0, 1))
        dot = float(pb_z.normalized().dot(ref_z.normalized()))
        print(f"F{f:02d} [{name}]: sb_matrix_q={source.pose.bones[MAPPING[name]].matrix.to_quaternion()[:]} -> dot={dot:.4f}")
