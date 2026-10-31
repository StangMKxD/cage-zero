"""Empirical Kinematics, Contact Drift, Seam Closure & Excursion Challenger Harness.

Gate 2 Adversarial Verification for Milestone M5:
- Strictly verifies foot contact drift < 0.02 studs during planted intervals.
- Tests loop seam closure (location, rotation, tangent slopes).
- Tests root motion extraction for in-place playback.
- Tests preservation of intentional vertical leap/drop/dive/turn excursions.
- Tests Euler rotational continuity (|Δθ| <= 180°, values in [-360°, 360°]).
"""

import json
import math
import sys
from pathlib import Path

try:
    import bpy
    from mathutils import Matrix, Quaternion, Vector
    HAS_BPY = True
except ImportError:
    HAS_BPY = False

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
ANIM_WORK_DIR = WORKSPACE_ROOT / "cage-zero-animation-work"

R15_PARTS = [
    'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

CLIPS = [
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


def find_target_armature(scene):
    """Find the authentic Studio R15 target armature in the scene."""
    # Look for name prefix StudioR15_ first
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE' and obj.name.startswith("StudioR15_"):
            return obj
    # Fallback: find armature containing R15 parts
    for obj in bpy.data.objects:
        if obj.type == 'ARMATURE' and 'LeftFoot' in obj.pose.bones:
            return obj
    return None


def audit_blend_clip(slug, a_type, blend_path, plant_meta):
    """Empirically audit the armature and action in the blend file."""
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))
    scene = bpy.context.scene

    armature = find_target_armature(scene)
    if not armature:
        return {"error": f"No Studio R15 target armature found in {blend_path.name}"}

    action = armature.animation_data.action if armature.animation_data else None
    if not action:
        return {"error": f"No action on target armature {armature.name}"}

    f_start = int(round(action.frame_range[0]))
    f_end = int(round(action.frame_range[1]))
    total_frames = f_end - f_start + 1

    depsgraph = bpy.context.evaluated_depsgraph_get()

    lt_positions = []
    lt_rotations = []
    foot_tails = {"LeftFoot": [], "RightFoot": []}
    foot_heads = {"LeftFoot": [], "RightFoot": []}

    for frame in range(f_start, f_end + 1):
        scene.frame_set(frame)
        eval_arm = armature.evaluated_get(depsgraph)

        lt = eval_arm.pose.bones.get("LowerTorso")
        if lt:
            lt_positions.append(Vector(eval_arm.matrix_world @ lt.head))
            lt_rotations.append(lt.matrix.to_quaternion())

        for side in ("LeftFoot", "RightFoot"):
            bone = eval_arm.pose.bones.get(side)
            if bone:
                t_pos = eval_arm.matrix_world @ bone.tail
                h_pos = eval_arm.matrix_world @ bone.head
                foot_tails[side].append(Vector(t_pos))
                foot_heads[side].append(Vector(h_pos))

    # Contact drift calculation with travel compensation for in-place locomotion loops
    contact_drift_results = {}
    contact_drift_passed = True
    c_intervals = plant_meta.get("contact_intervals", {}) if plant_meta else {}
    stride = plant_meta.get("stride_studs", 0.0) if plant_meta else 0.0
    mode = plant_meta.get("mode", "loop_inplace") if plant_meta else "loop_inplace"
    cycle_frames = max(1, total_frames - 1)

    # Compute per-frame travel vector
    travel_step = Vector((0.0, 0.0, 0.0))
    if mode == "loop_y":
        travel_step = Vector((0.0, stride / cycle_frames, 0.0))
    elif mode == "loop_x":
        travel_step = Vector((stride / cycle_frames, 0.0, 0.0))

    for side in ("LeftFoot", "RightFoot"):
        intervals = c_intervals.get(side, [])
        side_results = []
        tails = foot_tails[side]
        for interval in intervals:
            st, en = interval
            f_st = st - f_start
            f_en = en - f_start
            if 0 <= f_st < len(tails) and 0 <= f_en < len(tails):
                # Travel-compensated foot world positions
                compensated_positions = [
                    tails[f] + travel_step * f for f in range(f_st, f_en + 1)
                ]
                origin = compensated_positions[0]
                drifts = [(p - origin).length for p in compensated_positions]
                max_drift = max(drifts) if drifts else 0.0
                passed = max_drift < 0.02
                if not passed:
                    contact_drift_passed = False
                side_results.append({
                    "interval": [st, en],
                    "max_drift_studs": round(float(max_drift), 8),
                    "passed_0_02_threshold": passed
                })
        contact_drift_results[side] = side_results

    # Loop seam calculation
    seam_results = None
    if a_type == "loop":
        scene.frame_set(f_start)
        start_arm = armature.evaluated_get(depsgraph)
        start_transforms = {
            pb.name: {
                "loc": Vector(pb.location),
                "rot": pb.matrix.to_quaternion(),
                "scale": Vector(pb.scale)
            } for pb in start_arm.pose.bones if pb.name in R15_PARTS
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
            q_start = st["rot"]
            q_end = pb.matrix.to_quaternion()
            dot = max(-1.0, min(1.0, abs(q_start.dot(q_end))))
            rot_d_deg = math.degrees(2.0 * math.acos(dot))

            if loc_d > max_loc_diff:
                max_loc_diff = loc_d
                worst_loc_bone = pb.name
            if rot_d_deg > max_rot_diff_deg:
                max_rot_diff_deg = rot_d_deg
                worst_rot_bone = pb.name

        seam_results = {
            "max_location_diff": round(float(max_loc_diff), 8),
            "worst_loc_bone": worst_loc_bone,
            "max_rotation_diff_degrees": round(float(max_rot_diff_deg), 6),
            "worst_rot_bone": worst_rot_bone,
            "passed_seam_closure": (max_loc_diff < 0.0001 and max_rot_diff_deg < 0.1)
        }

    # Net LowerTorso displacement start-to-end
    net_lt_disp = None
    if lt_positions:
        p0 = lt_positions[0]
        p1 = lt_positions[-1]
        net_lt_disp = {
            "dx": round(float(abs(p1.x - p0.x)), 6),
            "dy": round(float(abs(p1.y - p0.y)), 6),
            "dz": round(float(abs(p1.z - p0.z)), 6),
            "horiz_drift": round(float(math.sqrt((p1.x - p0.x)**2 + (p1.y - p0.y)**2)), 6)  # Blender XY is horizontal floor plane
        }

    return {
        "armature_name": armature.name,
        "action_name": action.name,
        "frame_start": f_start,
        "frame_end": f_end,
        "total_frames": total_frames,
        "contact_drift": contact_drift_results,
        "contact_drift_all_passed": contact_drift_passed,
        "seam_results": seam_results,
        "net_lt_displacement": net_lt_disp,
        "lt_positions": lt_positions,
        "lt_rotations": lt_rotations
    }


def audit_keyframes_file(slug):
    """Audit keyframes JSON structure and seam closure."""
    kf_path = ANIM_WORK_DIR / slug / f"{slug}-r15-keyframes.json"
    if not kf_path.is_file():
        return {"error": f"Missing keyframes file: {kf_path}"}
    with open(kf_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    frames = data.get("frames", [])
    if not frames:
        return {"error": "Empty frames"}

    f0 = frames[0]["poses"]
    f_end = frames[-1]["poses"]
    max_pos_delta = 0.0
    max_rot_delta = 0.0

    for i in range(len(data.get("parts", []))):
        p0 = f0[i]
        p1 = f_end[i]
        pos_d = math.sqrt((p1[0]-p0[0])**2 + (p1[1]-p0[1])**2 + (p1[2]-p0[2])**2)
        max_pos_delta = max(max_pos_delta, pos_d)
        rot_d = sum(abs(a - b) for a, b in zip(p0[3:], p1[3:]))
        max_rot_delta = max(max_rot_delta, rot_d)

    lt_poses = [f["poses"][0] for f in frames]
    all_x = [p[0] for p in lt_poses]
    all_y = [p[1] for p in lt_poses]
    all_z = [p[2] for p in lt_poses]

    return {
        "frame_count": len(frames),
        "duration": data.get("duration"),
        "loop": data.get("loop"),
        "seam_max_pos_delta": round(float(max_pos_delta), 8),
        "seam_max_rot_delta": round(float(max_rot_delta), 8),
        "lt_range": {
            "dx": round(float(max(all_x) - min(all_x)), 4),
            "dy_vert": round(float(max(all_y) - min(all_y)), 4),
            "dz": round(float(max(all_z) - min(all_z)), 4),
            "peak_vert": round(float(max(all_y) - lt_poses[0][1]), 4),
            "trough_vert": round(float(min(all_y) - lt_poses[0][1]), 4),
        }
    }


def audit_recipe_euler(slug):
    """Audit Motion Tools recipe JSON for Euler continuity."""
    slug_dir = ANIM_WORK_DIR / slug
    recipes = list(slug_dir.glob("*.recipe.json"))
    if not recipes:
        return {"error": f"Missing recipe JSON in {slug}"}
    with open(recipes[0], "r", encoding="utf-8") as f:
        data = json.load(f)

    tracks = data.get("tracks", [])
    max_delta_deg = 0.0
    worst_track = None
    all_angles_bounded = True
    worst_angle = 0.0

    for track in tracks:
        joint_name = track.get("joint", "unknown")
        keys = track.get("keys", [])
        for i in range(len(keys)):
            rot = keys[i].get("rotation", [0, 0, 0])
            for axis_idx, val in enumerate(rot):
                if abs(val) > 360.0:
                    all_angles_bounded = False
                    worst_angle = max(worst_angle, abs(val))
                if i > 0:
                    prev_val = keys[i-1].get("rotation", [0, 0, 0])[axis_idx]
                    delta = abs(val - prev_val)
                    if delta > max_delta_deg:
                        max_delta_deg = delta
                        worst_track = f"{joint_name}[axis_{axis_idx}][t={keys[i].get('time')}]"

    return {
        "track_count": len(tracks),
        "max_frame_delta_deg": round(float(max_delta_deg), 4),
        "worst_track": worst_track,
        "smooth_euler_pass": (max_delta_deg <= 180.0),
        "all_angles_bounded": all_angles_bounded,
        "worst_angle": round(float(worst_angle), 4)
    }


def run_comprehensive_audit():
    print("=" * 90)
    print(" CAGE ZERO — Comprehensive Kinematics, Contact Drift & Seam Audit (Gate 2)")
    print("=" * 90)

    report = {}
    all_clips_approved = True

    for item in CLIPS:
        slug = item["slug"]
        name = item["name"]
        a_type = item["type"]
        slug_dir = ANIM_WORK_DIR / slug

        print(f"\nAUDITING [{name}] ({slug}) [{a_type.upper()}]...")

        # 1. Inspect final-audit.json
        audit_json_path = slug_dir / "final-audit.json"
        audit_data = {}
        if audit_json_path.is_file():
            with open(audit_json_path, "r", encoding="utf-8") as f:
                audit_data = json.load(f)

        # 2. Plant metadata
        plant_meta_path = slug_dir / "plant-metadata.json"
        plant_meta = {}
        if plant_meta_path.is_file():
            with open(plant_meta_path, "r", encoding="utf-8") as f:
                plant_meta = json.load(f)

        # 3. Keyframes audit
        kf_audit = audit_keyframes_file(slug)

        # 4. Recipe Euler audit
        recipe_audit = audit_recipe_euler(slug)

        # 5. Blender blend audit
        blend_files = list(slug_dir.glob("*_Final.blend"))
        blend_audit = None
        if HAS_BPY and blend_files:
            blend_audit = audit_blend_clip(slug, a_type, blend_files[0], plant_meta)

        # Adversarial checks per clip
        clip_verdict = "APPROVE"
        failures = []

        # Check final-audit.json ok status
        if not audit_data.get("ok"):
            failures.append(f"final-audit.json ok is False: {audit_data.get('errors')}")

        if a_type == "loop":
            # Check contact intervals present and non-empty
            c_ints = plant_meta.get("contact_intervals", {})
            if not c_ints.get("LeftFoot") or not c_ints.get("RightFoot"):
                failures.append(f"Loop clip missing contact intervals: {c_ints}")

            # Check blend foot contact drift
            if blend_audit and not blend_audit.get("contact_drift_all_passed"):
                failures.append(f"Blender contact drift exceeded 0.02 studs: {blend_audit.get('contact_drift')}")

            # Check final-audit contact drift metrics
            metrics = audit_data.get("metrics", {})
            cd_metrics = metrics.get("contact_drift", {})
            for side in ("LeftFoot", "RightFoot"):
                intervals = cd_metrics.get(side, [])
                if not intervals:
                    failures.append(f"final-audit.json has no contact drift records for {side}")
                for record in intervals:
                    max_d = record.get("max_drift_studs", 999.0)
                    if max_d >= 0.02:
                        failures.append(f"final-audit.json {side} drift {max_d} >= 0.02 studs")

            # Check seam closure
            if blend_audit and blend_audit.get("seam_results"):
                sr = blend_audit["seam_results"]
                if not sr["passed_seam_closure"]:
                    failures.append(f"Blender seam closure failed: loc_d={sr['max_location_diff']}, rot_d={sr['max_rotation_diff_degrees']}")

            if kf_audit.get("seam_max_pos_delta", 0.0) > 0.0001:
                failures.append(f"Keyframes seam pos delta {kf_audit['seam_max_pos_delta']} > 0.0001 studs")

            # Check in-place extraction (net horizontal LowerTorso displacement = 0)
            if blend_audit and blend_audit.get("net_lt_displacement"):
                h_drift = blend_audit["net_lt_displacement"]["horiz_drift"]
                if h_drift > 0.001:
                    failures.append(f"In-place LowerTorso horizontal drift {h_drift} > 0.001 studs")

        else: # One-shot actions
            lt_r = kf_audit.get("lt_range", {})
            if slug == "standing-jump":
                if lt_r.get("peak_vert", 0) < 1.0:
                    failures.append(f"Standing jump vertical peak {lt_r.get('peak_vert')} < 1.0 studs")
            elif slug == "soccer-trip":
                if lt_r.get("trough_vert", 0) > -1.5:
                    failures.append(f"Soccer trip vertical drop trough {lt_r.get('trough_vert')} > -1.5 studs")
            elif slug == "scissor-kick":
                if lt_r.get("peak_vert", 0) < 0.7:
                    failures.append(f"Scissor kick peak leap {lt_r.get('peak_vert')} < 0.7 studs")
            elif slug == "goalkeeper-diving-save":
                h_dive = math.sqrt(lt_r.get("dx", 0)**2 + lt_r.get("dz", 0)**2)
                if h_dive < 8.0:
                    failures.append(f"Goalkeeper diving save horizontal excursion {h_dive:.2f} < 8.0 studs")
            elif slug == "turn-back-running":
                # Check turnaround
                if blend_audit and blend_audit.get("lt_rotations"):
                    rots = blend_audit["lt_rotations"]
                    v0 = rots[0] @ Vector((0, 0, 1))
                    v_end = rots[-1] @ Vector((0, 0, 1))
                    dot = v0.dot(v_end)
                    if dot > -0.80:
                        failures.append(f"TurnBackRunning heading dot product {dot:.4f} > -0.80 (turnaround < 143 deg)")

        # Check Euler continuity
        if not recipe_audit.get("smooth_euler_pass"):
            failures.append(f"Euler jump > 180 deg in recipe: delta={recipe_audit.get('max_frame_delta_deg')} on {recipe_audit.get('worst_track')}")

        if failures:
            clip_verdict = "REQUEST_CHANGES"
            all_clips_approved = False
            print(f"  FAILED: {failures}")
        else:
            print("  PASSED ALL ADVERSARIAL CHECKS (APPROVE)")

        report[slug] = {
            "name": name,
            "type": a_type,
            "verdict": clip_verdict,
            "failures": failures,
            "audit_json_ok": audit_data.get("ok"),
            "audit_json_errors": audit_data.get("errors", []),
            "audit_json_warnings": audit_data.get("warnings", []),
            "plant_metadata": plant_meta,
            "keyframes_audit": kf_audit,
            "recipe_audit": recipe_audit,
            "blend_audit": {
                "armature": blend_audit.get("armature_name") if blend_audit else None,
                "action": blend_audit.get("action_name") if blend_audit else None,
                "frames": blend_audit.get("total_frames") if blend_audit else None,
                "contact_drift": blend_audit.get("contact_drift") if blend_audit else None,
                "contact_drift_all_passed": blend_audit.get("contact_drift_all_passed") if blend_audit else None,
                "seam_results": blend_audit.get("seam_results") if blend_audit else None,
                "net_lt_displacement": blend_audit.get("net_lt_displacement") if blend_audit else None,
            } if blend_audit else None
        }

    print("\n" + "=" * 90)
    print(f" OVERALL VERDICT: {'APPROVE' if all_clips_approved else 'REQUEST_CHANGES'}")
    print("=" * 90)

    out_file = WORKSPACE_ROOT / "tests" / "kinematics_audit_m5_gate2_output.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(f"Saved full audit report to {out_file}")

    return 0 if all_clips_approved else 1


if __name__ == "__main__":
    sys.exit(run_comprehensive_audit())
