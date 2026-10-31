import bpy
from pathlib import Path
from mathutils import Vector, Matrix

source_dir = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
fbx_path = source_dir / "Standing Idle 02.fbx"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(fbx_path))

arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
action = arm.animation_data.action
print("Action name:", action.name)
print("Frame range:", action.frame_range)

# Check bone rotation / transform frame by frame
for f in range(int(action.frame_range[0]), int(action.frame_range[0]) + 10):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    r_leg = arm.pose.bones.get('mixamorig:RightLeg')
    l_leg = arm.pose.bones.get('mixamorig:LeftLeg')
    r_up = arm.pose.bones.get('mixamorig:RightUpLeg')
    l_up = arm.pose.bones.get('mixamorig:LeftUpLeg')
    print(f"Frame {f}:")
    print(f"  RightLeg rot quat: {r_leg.rotation_quaternion[:] if r_leg else None}")
    print(f"  RightLeg matrix rot: {r_leg.matrix.to_quaternion()[:] if r_leg else None}")
    print(f"  RightUpLeg rot quat: {r_up.rotation_quaternion[:] if r_up else None}")
    print(f"  RightUpLeg matrix rot: {r_up.matrix.to_quaternion()[:] if r_up else None}")
