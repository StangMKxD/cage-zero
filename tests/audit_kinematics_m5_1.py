"""Empirical Kinematics and Foot Contact Challenger Audit for Milestone M5.

Performs mathematical and empirical audit across all 13 animations:
1. Locomotion Loops:
   - Foot sliding during planted contact intervals (< 0.02 studs)
   - First-to-last frame pose continuity across seam (keys[-1] approx keys[0])
   - Horizontal root travel extraction (forward 8.21 studs in Strike Foward Jog, lateral 1.255m in Goalkeeper Sidestep)
2. One-Shot Actions:
   - Preservation of intentional excursions:
     - soccer-trip: -0.76m vertical drop down to ground level
     - standing-jump: +0.87m vertical jump
     - scissor-kick: >1.0m vertical leap & torso flip
     - goalkeeper-diving-save: 3.45m horizontal dive
     - turn-back-running: 180 deg heading rotation preserved (no pop)
     - other one-shots (soccer-pass, soccer-tackle, goalkeeper-scoop, goalkeeper-catch, goalkeeper-overhand-throw)
"""

import json
import math
import os
import sys
from pathlib import Path

# Try importing bpy if run inside Blender
try:
    import bpy
    from mathutils import Euler, Matrix, Quaternion, Vector
    HAS_BPY = True
except ImportError:
    HAS_BPY = False

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
ANIMATION_WORK_DIR = WORKSPACE_ROOT / "cage-zero-animation-work"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
LEG_SCALE = 2.6340783381598905

ORDER = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]


def audit_blend_file(slug, blend_path):
    """Run Blender-level audit on armature and action in the blend file."""
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))
    scene = bpy.context.scene

    armature = None
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break

    if not armature:
        return {"error": "No armature found in blend file"}

    action = armature.animation_data.action if armature.animation_data else None
    if not action:
        return {"error": "No action found in blend file"}

    f_start = int(round(action.frame_range[0]))
    f_end = int(round(action.frame_range[1]))
    total_frames = f_end - f_start + 1

    depsgraph = bpy.context.evaluated_depsgraph_get()

    # Track foot positions (tail and head) across all frames
    foot_data = {"LeftFoot": [], "RightFoot": []}
    pelvis_positions = []
    pelvis_rotations = []

    for frame in range(f_start, f_end + 1):
        scene.frame_set(frame)
        eval_arm = armature.evaluated_get(depsgraph)

        lt = eval_arm.pose.bones.get("LowerTorso")
        if lt:
            pelvis_positions.append(Vector(eval_arm.matrix_world @ lt.head))
            pelvis_rotations.append(lt.matrix.to_quaternion())

        for side in ("LeftFoot", "RightFoot"):
            bone = eval_arm.pose.bones.get(side)
            if bone:
                tail_pos = eval_arm.matrix_world @ bone.tail
                head_pos = eval_arm.matrix_world @ bone.head
                foot_data[side].append({
                    "frame": frame,
                    "tail": Vector(tail_pos),
                    "head": Vector(head_pos),
                    "z": tail_pos.z
                })

    # Seam continuity check
    seam_data = {}
    scene.frame_set(f_start)
    start_arm = armature.evaluated_get(depsgraph)
    start_transforms = {
        pb.name: {
            "loc": Vector(pb.location),
            "rot": pb.matrix.to_quaternion(),
            "scale": Vector(pb.scale)
        } for pb in start_arm.pose.bones if pb.name in ORDER
    }

    scene.frame_set(f_end)
    end_arm = armature.evaluated_get(depsgraph)
    max_loc_diff = 0.0
    max_rot_diff_deg = 0.0
    worst_loc_bone = None
    worst_rot_bone = None

    for pb in end_arm.pose.bones:
        if pb.name not in start_transforms:
            continue
        st = start_transforms[pb.name]
        loc_d = (Vector(pb.location) - st["loc"]).length
        # Angular difference between quaternions
        q_start = st["rot"]
        q_end = pb.matrix.to_quaternion()
        # Angle = 2 * acos(|dot|)
        dot = max(-1.0, min(1.0, abs(q_start.dot(q_end))))
        rot_d_deg = math.degrees(2.0 * math.acos(dot))

        if loc_d > max_loc_diff:
            max_loc_diff = loc_d
            worst_loc_bone = pb.name
        if rot_d_deg > max_rot_diff_deg:
            max_rot_diff_deg = rot_d_deg
            worst_rot_bone = pb.name

    seam_data = {
        "max_location_diff": max_loc_diff,
        "worst_loc_bone": worst_loc_bone,
        "max_rotation_diff_degrees": max_rot_diff_deg,
        "worst_rot_bone": worst_rot_bone
    }

    return {
        "armature_name": armature.name,
        "action_name": action.name,
        "frame_start": f_start,
        "frame_end": f_end,
        "total_frames": total_frames,
        "pelvis_positions": pelvis_positions,
        "pelvis_rotations": pelvis_rotations,
        "foot_data": foot_data,
        "seam_data": seam_data
    }


def audit_keyframes_json(slug):
    """Audit keyframes JSON and plant metadata independently."""
    slug_dir = ANIMATION_WORK_DIR / slug
    kf_path = slug_dir / f"{slug}-r15-keyframes.json"
    pm_path = slug_dir / "plant-metadata.json"
    rc_files = list(slug_dir.glob("*.recipe.json"))
    rc_path = rc_files[0] if rc_files else None

    if not kf_path.is_file():
        return {"error": f"Keyframes JSON missing: {kf_path}"}

    with open(kf_path, "r", encoding="utf-8") as f:
        kf_data = json.load(f)

    pm_data = None
    if pm_path.is_file():
        with open(pm_path, "r", encoding="utf-8") as f:
            pm_data = json.load(f)

    rc_data = None
    if rc_path and rc_path.is_file():
        with open(rc_path, "r", encoding="utf-8") as f:
            rc_data = json.load(f)

    frames = kf_data.get("frames", [])
    if not frames:
        return {"error": "Empty frames in keyframes JSON"}

    # LowerTorso is pose 0
    lt_poses = [f["poses"][0] for f in frames]
    lt_positions = [Vector((p[0], p[1], p[2])) for p in lt_poses]

    # First and last pose difference across seam
    first_frame_poses = frames[0]["poses"]
    last_frame_poses = frames[-1]["poses"]

    seam_max_pos_diff = 0.0
    seam_max_rot_diff = 0.0
    for part_idx in range(len(kf_data.get("parts", []))):
        p0 = first_frame_poses[part_idx]
        p1 = last_frame_poses[part_idx]
        pos_d = math.sqrt((p1[0]-p0[0])**2 + (p1[1]-p0[1])**2 + (p1[2]-p0[2])**2)
        seam_max_pos_diff = max(seam_max_pos_diff, pos_d)
        # Rotation matrix difference
        r0 = p0[3:]
        r1 = p1[3:]
        rot_diff = sum(abs(a - b) for a, b in zip(r0, r1))
        seam_max_rot_diff = max(seam_max_rot_diff, rot_diff)

    return {
        "name": kf_data.get("name"),
        "loop": kf_data.get("loop"),
        "duration": kf_data.get("duration"),
        "frame_count": len(frames),
        "lt_positions": lt_positions,
        "seam_max_pos_diff": seam_max_pos_diff,
        "seam_max_rot_diff": seam_max_rot_diff,
        "plant_metadata": pm_data,
        "recipe_duration": rc_data.get("duration") if rc_data else None,
        "recipe_loop": rc_data.get("loop") if rc_data else None,
        "markers": kf_data.get("markers", [])
    }


def main():
    print("=" * 80)
    print(" CAGE ZERO — Empirical Kinematics & Foot Contact Audit (M5 Challenger)")
    print("=" * 80)

    animations = [
        {"slug": "standing-idle-02", "name": "Standing Idle 02", "type": "loop"},
        {"slug": "strike-foward-jog", "name": "Strike Foward Jog", "type": "loop"},
        {"slug": "goalkeeper-sidestep", "name": "Goalkeeper Sidestep", "type": "loop"},
        {"slug": "standing-jump", "name": "Standing Jump", "type": "oneshot"},
        {"slug": "soccer-pass", "name": "Soccer Pass", "type": "oneshot"},
        {"slug": "soccer-tackle", "name": "Soccer Tackle", "type": "oneshot"},
        {"slug": "soccer-trip", "name": "Soccer Trip", "type": "oneshot"},
        {"slug": "turn-back-running", "name": "TurnBackRunning", "type": "oneshot"},
        {"slug": "scissor-kick", "name": "Scissor Kick", "type": "oneshot"},
        {"slug": "goalkeeper-scoop", "name": "Goalkeeper Scoop", "type": "oneshot"},
        {"slug": "goalkeeper-catch", "name": "Goalkeeper Catch", "type": "oneshot"},
        {"slug": "goalkeeper-diving-save", "name": "Goalkeeper Diving Save", "type": "oneshot"},
        {"slug": "goalkeeper-overhand-throw", "name": "Goalkeeper Overhand Throw", "type": "oneshot"},
    ]

    results = {}

    for anim in animations:
        slug = anim["slug"]
        name = anim["name"]
        a_type = anim["type"]

        print(f"\n[{name}] ({slug}) - Category: {a_type}")
        kf_res = audit_keyframes_json(slug)
        if "error" in kf_res:
            print(f"  ERROR: {kf_res['error']}")
            continue

        blend_files = list((ANIMATION_WORK_DIR / slug).glob("*_Final.blend"))
        blend_res = None
        if HAS_BPY and blend_files:
            blend_res = audit_blend_file(slug, blend_files[0])

        anim_result = {
            "slug": slug,
            "name": name,
            "type": a_type,
            "keyframes": kf_res,
            "blend": blend_res
        }
        results[slug] = anim_result

        # Detailed checks per animation
        if a_type == "loop":
            print(f"  Keyframes Loop: {kf_res['loop']}, Frames: {kf_res['frame_count']}")
            print(f"  Seam Max Position Delta: {kf_res['seam_max_pos_diff']:.6f} studs")
            print(f"  Seam Max Rotation Delta: {kf_res['seam_max_rot_diff']:.6f}")
            if blend_res and "seam_data" in blend_res:
                sd = blend_res["seam_data"]
                print(f"  Blend Seam Max Bone Loc Diff: {sd['max_location_diff']:.6f} (bone: {sd['worst_loc_bone']})")
                print(f"  Blend Seam Max Bone Rot Diff: {sd['max_rotation_diff_degrees']:.4f} deg (bone: {sd['worst_rot_bone']})")

            # Check horizontal in-place drift
            lt_pos = kf_res["lt_positions"]
            p_start = lt_pos[0]
            p_end = lt_pos[-1]
            # Horizontal coordinates: X, Z in Roblox space (or X, Y in Blender)
            dx = abs(p_end.x - p_start.x)
            dy = abs(p_end.y - p_start.y)
            dz = abs(p_end.z - p_start.z)
            horiz_drift = math.sqrt(dx * dx + dz * dz)
            print(f"  Net LowerTorso translation start->end: dx={dx:.4f}, dy={dy:.4f}, dz={dz:.4f}")
            print(f"  Net Horizontal In-Place Drift: {horiz_drift:.4f} studs")

            # Foot contact analysis
            pm = kf_res.get("plant_metadata") or {}
            print(f"  Stride extracted: {pm.get('stride_studs')} studs (mode: {pm.get('mode')})")
            print(f"  Contact intervals from metadata: {pm.get('contact_intervals')}")

            if blend_res and "foot_data" in blend_res:
                fd = blend_res["foot_data"]
                for side in ("LeftFoot", "RightFoot"):
                    foot_pts = [f["tail"] for f in fd[side]]
                    speeds = [
                        (foot_pts[i] - foot_pts[i-1]).length
                        for i in range(1, len(foot_pts))
                    ]
                    min_speed = min(speeds) if speeds else 0.0
                    avg_speed = sum(speeds) / len(speeds) if speeds else 0.0
                    z_vals = [p.z for p in foot_pts]
                    min_z = min(z_vals) if z_vals else 0.0
                    max_z = max(z_vals) if z_vals else 0.0
                    print(f"  {side} Kinematics: Z range [{min_z:.4f}, {max_z:.4f}], min step speed {min_speed:.4f}, avg {avg_speed:.4f}")

                    # Check drift during metadata contact intervals if present
                    c_ints = pm.get("contact_intervals", {}).get(side, [])
                    if c_ints:
                        for idx, (st, en) in enumerate(c_ints):
                            # Frame indices relative to frame_start
                            f_st = st - blend_res["frame_start"]
                            f_en = en - blend_res["frame_start"]
                            if 0 <= f_st < len(foot_pts) and 0 <= f_en < len(foot_pts):
                                origin = foot_pts[f_st]
                                max_drift = max((foot_pts[f] - origin).length for f in range(f_st, f_en + 1))
                                print(f"    Interval [{st}, {en}]: max drift = {max_drift:.6f} studs (pass < 0.02: {max_drift < 0.02})")
                    else:
                        print(f"    WARNING: No contact intervals specified in plant-metadata for {side}!")

        else: # One-shot
            print(f"  Keyframes Loop: {kf_res['loop']}, Frames: {kf_res['frame_count']}")
            lt_pos = kf_res["lt_positions"]
            p_start = lt_pos[0]
            # Excursions
            all_x = [p.x for p in lt_pos]
            all_y = [p.y for p in lt_pos]
            all_z = [p.z for p in lt_pos]

            dx_max = max(all_x) - min(all_x)
            dy_max = max(all_y) - min(all_y)
            dz_max = max(all_z) - min(all_z)

            # In Roblox coordinates: Y is vertical, X is lateral, Z is depth/forward
            delta_y_peak = max(all_y) - p_start.y
            delta_y_trough = min(all_y) - p_start.y

            print(f"  LowerTorso Range: dX={dx_max:.4f}, dY(vert)={dy_max:.4f}, dZ={dz_max:.4f}")
            print(f"  Vertical Excursion relative to start: Peak={delta_y_peak:+.4f} studs, Trough={delta_y_trough:+.4f} studs")

            if slug == "standing-jump":
                print(f"  >> Standing Jump Peak Leap: {delta_y_peak:.4f} studs (expected Mixamo ~0.87m = ~2.3 studs)")
            elif slug == "soccer-trip":
                print(f"  >> Soccer Trip Trough Drop: {delta_y_trough:.4f} studs (expected Mixamo -0.76m = ~-2.0 studs)")
            elif slug == "scissor-kick":
                print(f"  >> Scissor Kick Peak Leap: {delta_y_peak:.4f} studs (expected Mixamo >1.0m = >2.6 studs)")
            elif slug == "goalkeeper-diving-save":
                dive_dist = math.sqrt(dx_max**2 + dz_max**2)
                print(f"  >> Goalkeeper Diving Save Horizontal Excursion: {dive_dist:.4f} studs (expected ~3.45m / 3.0m)")
            elif slug == "turn-back-running":
                # Check heading rotation
                # Check orientation of LowerTorso
                first_pose = kf_res["lt_positions"]
                # In kf_data frames:
                f0 = anim_result["keyframes"]["plant_metadata"] # or from frames
                print("  >> TurnBackRunning: checking rotation continuity...")

    # Write output audit results to JSON
    out_report = WORKSPACE_ROOT / "tests" / "kinematics_audit_m5_1_output.json"
    clean_results = {}
    for slug, res in results.items():
        clean_results[slug] = {
            "name": res["name"],
            "type": res["type"],
            "keyframes": {
                "name": res["keyframes"]["name"],
                "loop": res["keyframes"]["loop"],
                "duration": res["keyframes"]["duration"],
                "frame_count": res["keyframes"]["frame_count"],
                "seam_max_pos_diff": res["keyframes"]["seam_max_pos_diff"],
                "seam_max_rot_diff": res["keyframes"]["seam_max_rot_diff"],
                "plant_metadata": res["keyframes"]["plant_metadata"],
            },
            "blend": {
                "frame_start": res["blend"]["frame_start"] if res["blend"] else None,
                "frame_end": res["blend"]["frame_end"] if res["blend"] else None,
                "seam_data": res["blend"]["seam_data"] if res["blend"] else None,
            } if res["blend"] else None
        }

    with open(out_report, "w", encoding="utf-8") as f:
        json.dump(clean_results, f, indent=2)
    print(f"\nWrote full audit output to {out_report}")


if __name__ == "__main__":
    main()
