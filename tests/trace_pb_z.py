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

# Let's inspect ref_z in rest pose
print("--- Rest pose ref_z ---")
for part in ['LeftUpperLeg', 'LeftLowerLeg', 'RightUpperLeg', 'RightLowerLeg']:
    b = rig.data.bones[part]
    ref_z = (b.matrix_local.to_3x3() @ Vector((0, 0, 1))).normalized()
    print(f"{part} rest ref_z: {ref_z[:]}")

# Step 5
scene.frame_set(f_start)
view.objects.active = rig
rig.select_set(True)
bpy.ops.object.mode_set(mode='POSE')

for name in batch_convert_v3.ORDER:
    sb = source.pose.bones[source_bones[name]]
    delta_q = source_rest[name].inverted() @ sb.matrix.to_quaternion()
    target_q = target_rest[name] @ delta_q
    pb = rig.pose.bones[name]
    pb.matrix = Matrix.Translation(pb.head) @ target_q.to_matrix().to_4x4()
view.update()

print("--- Step 5 (Frame 1 posed) ---")
for part in ['LeftUpperLeg', 'LeftLowerLeg', 'RightUpperLeg', 'RightLowerLeg']:
    pb = rig.pose.bones[part]
    pb_z = (pb.matrix.to_3x3() @ Vector((0, 0, 1))).normalized()
    dot = batch_convert_v3.diagnose_bone_front_dot(rig, part)
    print(f"{part}: pb_z={pb_z[:]}, dot={dot:.4f}")

# Now let's see what happens if we do NOT reset pose vs IF we reset pose
print("--- Step 7: Frame 1 with keyframes ---")
# Reset pose bones
for pb in rig.pose.bones:
    pb.matrix_basis = Matrix.Identity(4)
view.update()

for frame in [1, 2, 3]:
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
    
    print(f"--- Frame {frame} after setting pb.matrix ---")
    for part in ['RightUpperLeg', 'RightLowerLeg', 'LeftLowerLeg']:
        pb = rig.pose.bones[part]
        pb_z = (pb.matrix.to_3x3() @ Vector((0, 0, 1))).normalized()
        dot = batch_convert_v3.diagnose_bone_front_dot(rig, part)
        print(f"  {part}: pb_z={pb_z[:]}, dot={dot:.4f}")
        print(f"  {part}: matrix_basis={pb.matrix_basis.to_quaternion()[:]}")
