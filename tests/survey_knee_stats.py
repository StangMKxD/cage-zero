import bpy
from pathlib import Path
from mathutils import Matrix, Quaternion, Vector
import sys
import numpy as np

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

all_clips = [
    ("Fast Run.fbx", "FastRun", "loop_y"),
    ("Jog Forward.fbx", "JogForward", "loop_y"),
    ("Scissor Kick.fbx", "ScissorKick", "oneshot"),
    ("Soccer Pass.fbx", "SoccerPass", "oneshot"),
    ("Soccer Tackle.fbx", "SoccerTackle", "oneshot"),
    ("Soccer Trip.fbx", "SoccerTrip", "oneshot"),
    ("Standing Idle 02.fbx", "StandingIdle02", "loop_y"),
    ("Standing Jump.fbx", "StandingJump", "oneshot"),
    ("TurnBackRunning.fbx", "TurnBackRunning", "oneshot"),
    ("Strike Foward Jog.fbx", "StrikeFowardJog", "loop_y"),
    ("goal/Goalkeeper Catch.fbx", "GoalkeeperCatch", "oneshot"),
    ("goal/Goalkeeper Diving Save.fbx", "GoalkeeperDivingSave", "oneshot"),
    ("goal/Goalkeeper Overhand Throw.fbx", "GoalkeeperOverhandThrow", "oneshot"),
    ("goal/Goalkeeper Scoop.fbx", "GoalkeeperScoop", "oneshot"),
    ("goal/Goalkeeper Sidestep.fbx", "GoalkeeperSidestep", "loop_x"),
]

print(f"{'Clip':22s} | {'Left Min':8s} {'Left Med':8s} {'Left P10':8s} {'Left Max':8s} | {'Right Min':9s} {'Right Med':9s} {'Right P10':9s} {'Right Max':9s}")
print("-" * 105)

for fbx_name, clip_slug, loop_type in all_clips:
    fbx_file = SOURCE_DIR / fbx_name
    bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
    bpy.ops.import_scene.fbx(filepath=str(fbx_file))
    rig = batch_convert_v3.get_canonical_armature()
    source = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig)
    action = source.animation_data.action
    scene = bpy.context.scene
    view = bpy.context.view_layer
    
    f_start = int(round(action.frame_range[0]))
    f_end = int(round(action.frame_range[1]))
    
    source_bones = {n: batch_convert_v3.get_source_bone_name(source, n) for n in batch_convert_v3.ORDER}
    source_rest = {n: source.data.bones[source_bones[n]].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
    target_rest = {n: rig.data.bones[n].matrix_local.to_quaternion() for n in batch_convert_v3.ORDER}
    
    # Clean retargeting with inner view.update()
    left_dots = []
    right_dots = []
    
    # We do frames from f_start to f_end
    for frame in range(f_start, f_end + 1):
        scene.frame_set(frame)
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
        
        # We evaluate without blanket roll (since none are inverted)
        left_dots.append(batch_convert_v3.diagnose_bone_front_dot(rig, 'LeftLowerLeg'))
        right_dots.append(batch_convert_v3.diagnose_bone_front_dot(rig, 'RightLowerLeg'))
    
    # Discard frame 1 transient if needed or evaluate stabilized frames [3..f_end-1]
    stab_left = left_dots[2:-1] if len(left_dots) > 4 else left_dots
    stab_right = right_dots[2:-1] if len(right_dots) > 4 else right_dots
    
    l_min, l_med, l_p10, l_max = min(stab_left), np.median(stab_left), np.percentile(stab_left, 10), max(stab_left)
    r_min, r_med, r_p10, r_max = min(stab_right), np.median(stab_right), np.percentile(stab_right, 10), max(stab_right)
    
    print(f"{clip_slug:22s} | {l_min:+.4f}   {l_med:+.4f}   {l_p10:+.4f}   {l_max:+.4f}   | {r_min:+.4f}    {r_med:+.4f}    {r_p10:+.4f}    {r_max:+.4f}")
