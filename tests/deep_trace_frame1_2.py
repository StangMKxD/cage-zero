import bpy
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector
import sys

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
fbx_file = SOURCE_DIR / "Standing Idle 02.fbx"
bpy.ops.import_scene.fbx(filepath=str(fbx_file))

rig = batch_convert_v3.get_canonical_armature()
source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)

action = source.animation_data.action
f_start = int(round(action.frame_range[0]))
scene = bpy.context.scene
view = bpy.context.view_layer

source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}

for f in [1, 2, 3]:
    scene.frame_set(f)
    view.update()
    sb = source.pose.bones[source_bones['RightLowerLeg']]
    print(f"--- Frame {f} ---")
    print("source bone matrix:")
    print(sb.matrix)
    print("source bone matrix rot quat:", sb.matrix.to_quaternion())
    print("source rest quat:", source_rest['RightLowerLeg'])
    delta_q = source_rest['RightLowerLeg'].inverted() @ sb.matrix.to_quaternion()
    print("delta_q:", delta_q)
    target_q = target_rest['RightLowerLeg'] @ delta_q
    print("target_q:", target_q)
    
    # Check parent: RightUpperLeg
    sb_up = source.pose.bones[source_bones['RightUpperLeg']]
    print("source upper leg matrix rot quat:", sb_up.matrix.to_quaternion())
    delta_q_up = source_rest['RightUpperLeg'].inverted() @ sb_up.matrix.to_quaternion()
    target_q_up = target_rest['RightUpperLeg'] @ delta_q_up
    print("target_q_up:", target_q_up)
