#!/usr/bin/env python3
"""debug_delta_q.py — Inspect delta_q and target_q on frames 1, 2, 3.
"""

from pathlib import Path
import bpy
from mathutils import Matrix, Quaternion, Vector
import sys

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\cage-zero-dev\animation-mixamo" if not Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo").exists() else r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_file = SOURCE_DIR / "Standing Idle 02.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_file))

rig = batch_convert_v3.get_canonical_armature()
source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)

ORDER = ['RightUpperLeg', 'RightLowerLeg']
source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in ORDER}

scene = bpy.context.scene
view = bpy.context.view_layer

for frame in [1, 2, 3]:
    scene.frame_set(frame)
    view.update()
    print(f"\n--- FRAME {frame} ---")
    for name in ORDER:
        sb = source.pose.bones[source_bones[name]]
        sb_mat_q = sb.matrix.to_quaternion()
        delta_q = source_rest[name].inverted() @ sb_mat_q
        target_q = target_rest[name] @ delta_q
        print(f"[{name}]")
        print(f"  sb.matrix.to_quaternion() = {sb_mat_q[:]}")
        print(f"  source_rest.inverted()    = {source_rest[name].inverted()[:]}")
        print(f"  delta_q                   = {delta_q[:]}")
        print(f"  target_q                  = {target_q[:]}")
