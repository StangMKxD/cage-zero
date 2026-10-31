import bpy
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector
import sys

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

gk_clips = [
    ("goal/Goalkeeper Catch.fbx", "GoalkeeperCatch"),
    ("goal/Goalkeeper Diving Save.fbx", "GoalkeeperDivingSave"),
    ("goal/Goalkeeper Overhand Throw.fbx", "GoalkeeperOverhandThrow"),
    ("goal/Goalkeeper Scoop.fbx", "GoalkeeperScoop"),
    ("goal/Goalkeeper Sidestep.fbx", "GoalkeeperSidestep"),
]

for fbx_name, clip_slug in gk_clips:
    fbx_file = SOURCE_DIR / fbx_name
    bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
    bpy.ops.import_scene.fbx(filepath=str(fbx_file))
    rig = batch_convert_v3.get_canonical_armature()
    source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)
    scene = bpy.context.scene
    view = bpy.context.view_layer
    
    source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
    source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
    target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
    
    scene.frame_set(1)
    view.objects.active = rig
    rig.select_set(True)
    if rig.mode != 'POSE':
        bpy.ops.object.mode_set(mode='POSE')
    
    # 1. Without inner update
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    view.update()
    for name in batch_convert_v3.ORDER:
        sb = source.pose.bones[source_bones[name]]
        delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
        target_q = target_rest[name] @ delta_q
        pb = rig.pose.bones[name]
        pos = pb.head.copy()
        pb.matrix = Matrix.Translation(pos) @ target_q.to_matrix().to_4x4()
    view.update()
    dots_no_inner = {p: batch_convert_v3.diagnose_bone_front_dot(rig, p) for p in ['LeftLowerLeg', 'RightLowerLeg']}
    
    # 2. With inner update
    for pb in rig.pose.bones:
        pb.matrix_basis = Matrix.Identity(4)
    view.update()
    for name in batch_convert_v3.ORDER:
        sb = source.pose.bones[source_bones[name]]
        delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
        target_q = target_rest[name] @ delta_q
        pb = rig.pose.bones[name]
        pos = pb.head.copy()
        pb.matrix = Matrix.Translation(pos) @ target_q.to_matrix().to_4x4()
        view.update()
    dots_with_inner = {p: batch_convert_v3.diagnose_bone_front_dot(rig, p) for p in ['LeftLowerLeg', 'RightLowerLeg']}
    
    print(f"[{clip_slug:22s}] No-update: L={dots_no_inner['LeftLowerLeg']:+.3f}, R={dots_no_inner['RightLowerLeg']:+.3f} | With-update: L={dots_with_inner['LeftLowerLeg']:+.3f}, R={dots_with_inner['RightLowerLeg']:+.3f}")
