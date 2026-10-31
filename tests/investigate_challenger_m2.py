#!/usr/bin/env python3
"""investigate_challenger_m2.py — Deep investigation of anomalies found during challenge.
"""

import json
import math
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"

def get_all_fcurves(action) -> list:
    legacy = getattr(action, "fcurves", None)
    if legacy is not None:
        return list(legacy)
    curves = []
    for layer in getattr(action, "layers", ()):
        for strip in getattr(layer, "strips", ()):
            for channelbag in getattr(strip, "channelbags", ()):
                curves.extend(channelbag.fcurves)
    return curves

print("=" * 60)
print("INVESTIGATION 1: SoccerTrip LowerTorso Trajectory")
print("=" * 60)
trip_blend = TEST_OUTPUT_DIR / "SoccerTrip" / "SoccerTrip_R15_v03.blend"
bpy.ops.wm.open_mainfile(filepath=str(trip_blend))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
action = rig.animation_data.action
curves = get_all_fcurves(action)
lt_loc = [c for c in curves if 'location' in c.data_path and 'LowerTorso' in c.data_path]
for c in lt_loc:
    axis = ["X", "Y", "Z"][c.array_index]
    pts = [kp.co.y for kp in c.keyframe_points]
    print(f"SoccerTrip LowerTorso Location {axis}: start={pts[0]:.4f}, min={min(pts):.4f}, max={max(pts):.4f}, end={pts[-1]:.4f}")

# Also inspect SoccerTrip in -r15-keyframes.json
trip_kf = TEST_OUTPUT_DIR / "SoccerTrip" / "SoccerTrip-r15-keyframes.json"
with open(trip_kf, "r") as f:
    kf_data = json.load(f)
lt_poses = [f['poses'][0][:3] for f in kf_data['frames']]
lt_x = [p[0] for p in lt_poses]
lt_y = [p[1] for p in lt_poses]
lt_z = [p[2] for p in lt_poses]
print(f"SoccerTrip JSON LowerTorso X: start={lt_x[0]:.4f}, min={min(lt_x):.4f}, max={max(lt_x):.4f}, end={lt_x[-1]:.4f}")
print(f"SoccerTrip JSON LowerTorso Y: start={lt_y[0]:.4f}, min={min(lt_y):.4f}, max={max(lt_y):.4f}, end={lt_y[-1]:.4f}")
print(f"SoccerTrip JSON LowerTorso Z: start={lt_z[0]:.4f}, min={min(lt_z):.4f}, max={max(lt_z):.4f}, end={lt_z[-1]:.4f}")

print("\n" + "=" * 60)
print("INVESTIGATION 2: StandingIdle02 Knee & Thigh Orientations across Frames")
print("=" * 60)
idle_blend = TEST_OUTPUT_DIR / "StandingIdle02" / "StandingIdle02_R15_v03.blend"
bpy.ops.wm.open_mainfile(filepath=str(idle_blend))
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
action = rig.animation_data.action
f_start = int(round(action.frame_range[0]))
f_end = int(round(action.frame_range[1]))

def compute_bone_front_dot(rig, bone_name):
    pb = rig.pose.bones.get(bone_name)
    b = rig.data.bones.get(bone_name)
    pb_z = pb.matrix.to_3x3() @ Vector((0, 0, 1))
    ref_z = b.matrix_local.to_3x3() @ Vector((0, 0, 1))
    return float(pb_z.normalized().dot(ref_z.normalized()))

negative_frames_r = []
negative_frames_l = []
for f in range(f_start, f_end + 1):
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    ll = compute_bone_front_dot(rig, 'LeftLowerLeg')
    rl = compute_bone_front_dot(rig, 'RightLowerLeg')
    lu = compute_bone_front_dot(rig, 'LeftUpperLeg')
    ru = compute_bone_front_dot(rig, 'RightUpperLeg')
    if rl < 0:
        negative_frames_r.append((f, rl, ru))
    if ll < 0:
        negative_frames_l.append((f, ll, lu))

print(f"StandingIdle02 frames with RightLowerLeg dot < 0: count={len(negative_frames_r)}")
if negative_frames_r:
    print(f"Sample frames (frame, RightLowerLeg_dot, RightUpperLeg_dot): {negative_frames_r[:10]}")
print(f"StandingIdle02 frames with LeftLowerLeg dot < 0: count={len(negative_frames_l)}")

# Let's inspect frame 1 of StandingIdle02 vs peak frame
bpy.context.scene.frame_set(1)
bpy.context.view_layer.update()
print(f"Frame 1: LeftLowerLeg={compute_bone_front_dot(rig, 'LeftLowerLeg'):.4f}, RightLowerLeg={compute_bone_front_dot(rig, 'RightLowerLeg'):.4f}")
print(f"Frame 1: LeftUpperLeg={compute_bone_front_dot(rig, 'LeftUpperLeg'):.4f}, RightUpperLeg={compute_bone_front_dot(rig, 'RightUpperLeg'):.4f}")

# Also let's check what the source FBX had for Standing Idle 02 at rest and frame 1
print("\n" + "=" * 60)
print("INVESTIGATION 3: Non-Root Joint Pivot Deviations (Excluding LowerTorso)")
print("=" * 60)
for clip_name in ["FastRun", "JogForward", "ScissorKick", "SoccerPass", "SoccerTackle", "SoccerTrip", "StandingIdle02", "StandingJump", "TurnBackRunning", "StrikeFowardJog"]:
    bfile = TEST_OUTPUT_DIR / clip_name / f"{clip_name}_R15_v03.blend"
    bpy.ops.wm.open_mainfile(filepath=str(bfile))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    action = rig.animation_data.action
    f_start = int(round(action.frame_range[0]))
    f_end = int(round(action.frame_range[1]))

    rest_parent_heads = {}
    for pb in rig.pose.bones:
        if pb.name == 'LowerTorso':
            continue
        b = rig.data.bones.get(pb.name)
        if pb.parent and b.parent:
            p_mat_rest = b.parent.matrix_local
            head_in_parent = p_mat_rest.inverted() @ b.head_local
            rest_parent_heads[pb.name] = head_in_parent

    max_dev = 0.0
    worst_b = None
    worst_f = None
    for f in range(f_start, f_end + 1):
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        for pb in rig.pose.bones:
            if pb.name not in rest_parent_heads:
                continue
            expected_head = pb.parent.matrix @ rest_parent_heads[pb.name]
            dev = (pb.head - expected_head).length
            if dev > max_dev:
                max_dev = dev
                worst_b = pb.name
                worst_f = f
    print(f"[{clip_name}] Max non-root pivot dev: {max_dev:.8e} studs (bone={worst_b}, frame={worst_f})")
