#!/usr/bin/env python3
"""test_step8.py — Trace Step 8 hemisphere flip on StandingIdle02.
"""

from pathlib import Path
import bpy
import sys
from mathutils import Matrix, Quaternion, Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\cage-zero-dev\animation-mixamo" if not Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo").exists() else r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
FBX_FILE = SOURCE_DIR / "Standing Idle 02.fbx"

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
bpy.ops.import_scene.fbx(filepath=str(FBX_FILE))

rig = batch_convert_v3.get_canonical_armature()
source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)

# We want to check the keyframe insertion during Step 7
action = source.animation_data.action
f_start = int(round(action.frame_range[0]))
f_end = int(round(action.frame_range[1]))
scene = bpy.context.scene
view = bpy.context.view_layer

source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}

# Let's check what Step 7 inserts at frame 1, 2, 3 for RightLowerLeg
# Create action
target_action = bpy.data.actions.new(name="Test_Idle")
rig.animation_data_create()
rig.animation_data.action = target_action

for pb in rig.pose.bones:
    pb.rotation_mode = 'QUATERNION'

# Apply roll to all 4 leg parts as diagnosed
apply_leg_roll = {'LeftUpperLeg': True, 'LeftLowerLeg': True, 'RightUpperLeg': True, 'RightLowerLeg': True}

# Run Step 7 for frames 1 to 5
for frame in range(1, 6):
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

    orig_matrices = {pb.name: pb.matrix.copy() for pb in rig.pose.bones}
    for side in ('Left', 'Right'):
        for part in ('UpperLeg', 'LowerLeg'):
            bname = side + part
            pb = rig.pose.bones[bname]
            pb.matrix = orig_matrices[bname] @ Matrix.Rotation(3.141592653589793, 4, 'Y')
            view.update()
        pb_foot = rig.pose.bones[side + 'Foot']
        pb_foot.matrix = orig_matrices[side + 'Foot']
        view.update()

    # Insert keyframe
    for pb in rig.pose.bones:
        pb.keyframe_insert('rotation_quaternion', frame=frame)
    view.update()
    
    # Check what quaternion was inserted
    rl_q = rig.pose.bones['RightLowerLeg'].rotation_quaternion.copy()
    ru_q = rig.pose.bones['RightUpperLeg'].rotation_quaternion.copy()
    print(f"Frame {frame} inserted quat: RU={ru_q[:]}, RL={rl_q[:]}")
