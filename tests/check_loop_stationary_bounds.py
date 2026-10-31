import json
from pathlib import Path
import bpy

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"
LOOPS = ["FastRun", "JogForward", "StrikeFowardJog", "StandingIdle02"]

def get_all_fcurves(action):
    legacy = getattr(action, "fcurves", None)
    if legacy is not None:
        return list(legacy)
    curves = []
    for layer in getattr(action, "layers", ()):
        for strip in getattr(layer, "strips", ()):
            for channelbag in getattr(strip, "channelbags", ()):
                curves.extend(channelbag.fcurves)
    return curves

print("=" * 80)
print(f"{'Clip Name':18s} | {'Blend X max':12s} | {'Blend Y max':12s} | {'JSON X max':12s} | {'JSON Y max':12s} | Status")
print("-" * 80)

all_passed = True

for loop_name in LOOPS:
    bfile = TEST_OUTPUT_DIR / loop_name / f"{loop_name}_R15_v03.blend"
    bpy.ops.wm.open_mainfile(filepath=str(bfile))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    action = rig.animation_data.action
    curves = get_all_fcurves(action)
    
    # Check Action FCurves for LowerTorso location
    lt_x_curve = [c for c in curves if 'location' in c.data_path and 'LowerTorso' in c.data_path and c.array_index == 0]
    lt_y_curve = [c for c in curves if 'location' in c.data_path and 'LowerTorso' in c.data_path and c.array_index == 1]
    
    max_abs_x = 0.0
    if lt_x_curve:
        pts_x = [abs(kp.co.y) for kp in lt_x_curve[0].keyframe_points]
        max_abs_x = max(pts_x)
        
    max_abs_y = 0.0
    if lt_y_curve:
        pts_y = [abs(kp.co.y) for kp in lt_y_curve[0].keyframe_points]
        max_abs_y = max(pts_y)
        
    # Check JSON exported poses
    json_path = TEST_OUTPUT_DIR / loop_name / f"{loop_name}-r15-keyframes.json"
    json_max_abs_x = 0.0
    json_max_abs_y = 0.0
    if json_path.exists():
        with open(json_path, "r") as f:
            data = json.load(f)
        frames = data.get("frames", [])
        xs = [abs(f["poses"][0][0]) for f in frames]
        ys = [abs(f["poses"][0][1]) for f in frames]
        json_max_abs_x = max(xs) if xs else 0.0
        json_max_abs_y = max(ys) if ys else 0.0
        
    passed = (max_abs_x < 1e-6 and max_abs_y < 1e-6 and json_max_abs_x < 1e-6 and json_max_abs_y < 1e-6)
    if not passed:
        all_passed = False
        
    status = "PASS" if passed else "FAIL"
    print(f"{loop_name:18s} | {max_abs_x:10.8f} s | {max_abs_y:10.8f} s | {json_max_abs_x:10.8f} s | {json_max_abs_y:10.8f} s | {status}")

print("=" * 80)
print(f"VERDICT: {'ALL 4 LOOPS STRICTLY STATIONARY (X=0.0, Y=0.0)' if all_passed else 'FAIL'}")
