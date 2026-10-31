import hashlib
import json
import math
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")

OUTFIELD_SPECS = [
    {"name": "FastRun", "loop": True, "frames": 17, "fbx": "Fast Run.fbx"},
    {"name": "JogForward", "loop": True, "frames": 26, "fbx": "Jog Forward.fbx"},
    {"name": "ScissorKick", "loop": False, "frames": 84, "fbx": "Scissor Kick.fbx"},
    {"name": "SoccerPass", "loop": False, "frames": 49, "fbx": "Soccer Pass.fbx"},
    {"name": "SoccerTackle", "loop": False, "frames": 54, "fbx": "Soccer Tackle.fbx"},
    {"name": "SoccerTrip", "loop": False, "frames": 49, "fbx": "Soccer Trip.fbx"},
    {"name": "StandingIdle02", "loop": True, "frames": 157, "fbx": "Standing Idle 02.fbx"},
    {"name": "StandingJump", "loop": False, "frames": 74, "fbx": "Standing Jump.fbx"},
    {"name": "TurnBackRunning", "loop": False, "frames": 50, "fbx": "TurnBackRunning.fbx"},
    {"name": "StrikeFowardJog", "loop": True, "frames": 40, "fbx": "Strike Foward Jog.fbx"},
]

EXPECTED_BONES = [
    'Root', 'HumanoidRootNode', 'LowerTorso', 'UpperTorso', 'Head',
    'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
    'RightUpperArm', 'RightLowerArm', 'RightHand',
    'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
    'RightUpperLeg', 'RightLowerLeg', 'RightFoot'
]

EXPECTED_HASHES = {
    "Fast Run.fbx": "822FDC9D28AC97C53FAC37717F20A51A286B44FD389B135119467EC794E912AB",
    "Jog Forward.fbx": "836EF89582F9382598D0B2EDD82F57D3CB8C29DC136A512E45D5637A70C4C2EF",
    "Scissor Kick.fbx": "5E43F565ECE6768118C83BF6A4C7C5A08ECEE4AA6B112BA1C5591065F13687B4",
    "Soccer Pass.fbx": "B10D8ADCC2726A30DCC6BB691FD3DB7D943272780397C87397745806DB71156B",
    "Soccer Tackle.fbx": "E2BDC6A031D770C35F2BF6CED4EFCF15A1BA9154ADF5596B0092215CC9942CD0",
    "Soccer Trip.fbx": "508CEEB3EA6D41B95F71F611616040B586AEEC77901C3AC53540481AF349616A",
    "Standing Idle 02.fbx": "B5C38648952D1A547801200BEFB9B3E7FC2F3FEA1E6F46CB215D12D37551CDBF",
    "Standing Jump.fbx": "5BDF56BB036EC76CFB53BCAD13F06A7D24FE2C4A0B32A04798F3E5B865D9811E",
    "TurnBackRunning.fbx": "EB02912E98FDBAECB7950D2FB8DAF9C6BCE7E32E9B9727C56DDF4B0FFBD52460",
    "Strike Foward Jog.fbx": "271B484652B91ED6945CAE0361008E425CDB524CC403206A6C5DCA94BF02E4EC",
}

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

def compute_sha256(filepath: Path) -> str:
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest().upper()

print("=" * 90)
print("COMPREHENSIVE EMPIRICAL CHALLENGE — 10 OUTFIELD CLIPS (M2 IT2)")
print("=" * 90)

failures = []

for spec in OUTFIELD_SPECS:
    clip = spec["name"]
    is_loop = spec["loop"]
    expected_frames = spec["frames"]
    clip_dir = TEST_OUTPUT_DIR / clip
    
    # 1. Deliverables existence
    blend_file = clip_dir / f"{clip}_R15_v03.blend"
    kf_file = clip_dir / f"{clip}-r15-keyframes.json"
    recipe_file = clip_dir / f"{clip}.recipe.json"
    audit_file = clip_dir / f"{clip}_audit.json"
    
    for fpath in [blend_file, kf_file, recipe_file, audit_file]:
        if not fpath.exists():
            failures.append(f"[{clip}] Missing deliverable: {fpath.name}")
            
    # 2. Check .blend internals
    bpy.ops.wm.open_mainfile(filepath=str(blend_file))
    rig = next((o for o in bpy.data.objects if o.type == 'ARMATURE'), None)
    if not rig:
        failures.append(f"[{clip}] No armature found in {blend_file.name}")
        continue
        
    bone_names = [b.name for b in rig.data.bones]
    for eb in EXPECTED_BONES:
        if eb not in bone_names:
            failures.append(f"[{clip}] Missing bone in rig: {eb}")
            
    # Check Action
    action = rig.animation_data.action if rig.animation_data else None
    if not action:
        failures.append(f"[{clip}] No action on armature")
        continue
        
    f_start = int(round(action.frame_range[0]))
    f_end = int(round(action.frame_range[1]))
    frame_count = f_end - f_start + 1
    if frame_count != expected_frames:
        failures.append(f"[{clip}] Frame count mismatch: got {frame_count}, expected {expected_frames}")
        
    curves = get_all_fcurves(action)
    non_root_loc_curves = [c for c in curves if 'location' in c.data_path and 'LowerTorso' not in c.data_path and 'HumanoidRootPart' not in c.data_path]
    if len(non_root_loc_curves) > 0:
        failures.append(f"[{clip}] Found {len(non_root_loc_curves)} non-root location curves in Action!")
        
    root_loc_curves = [c for c in curves if 'location' in c.data_path and 'LowerTorso' in c.data_path]
    if len(root_loc_curves) == 0:
        failures.append(f"[{clip}] Missing LowerTorso root location curves!")
        
    # Check static pose bone location
    max_pb_loc = 0.0
    for pb in rig.pose.bones:
        if pb.name == 'LowerTorso' or pb.name == 'HumanoidRootPart':
            continue
        if pb.location.length > max_pb_loc:
            max_pb_loc = pb.location.length
    if max_pb_loc > 1e-7:
        failures.append(f"[{clip}] Non-root pose bone static location > 0: {max_pb_loc:.8f}")
        
    # Check FK Pivot deviation across all frames
    rest_parent_heads = {}
    for pb in rig.pose.bones:
        if pb.name == 'LowerTorso' or pb.name == 'HumanoidRootPart':
            continue
        b = rig.data.bones.get(pb.name)
        if pb.parent and b.parent:
            p_mat_rest = b.parent.matrix_local
            head_in_parent = p_mat_rest.inverted() @ b.head_local
            rest_parent_heads[pb.name] = head_in_parent

    max_pivot_dev = 0.0
    for f in range(f_start, f_end + 1):
        bpy.context.scene.frame_set(f)
        bpy.context.view_layer.update()
        for pb in rig.pose.bones:
            if pb.name not in rest_parent_heads:
                continue
            expected_head = pb.parent.matrix @ rest_parent_heads[pb.name]
            dev = (pb.head - expected_head).length
            if dev > max_pivot_dev:
                max_pivot_dev = dev
                
    if max_pivot_dev > 0.00020:
        failures.append(f"[{clip}] Non-root pivot dev exceeded gate (0.00020): {max_pivot_dev:.8e}")
        
    # Check StandingIdle02 recipe subsampling
    with open(recipe_file, 'r', encoding='utf-8') as rf:
        rc_data = json.load(rf)
    tracks = rc_data.get('tracks', [])
    for tr in tracks:
        klen = len(tr.get('keys', []))
        if klen > 128:
            failures.append(f"[{clip}] Recipe track {tr.get('joint')} has {klen} keys (> 128)")
            
    # Check source FBX hash integrity
    fbx_name = spec["fbx"]
    current_hash = compute_sha256(SOURCE_DIR / fbx_name)
    expected_hash = EXPECTED_HASHES[fbx_name]
    if current_hash != expected_hash:
        failures.append(f"[{fbx_name}] SHA256 integrity failure! {current_hash} != {expected_hash}")
        
    print(f"[{'PASS' if not failures or clip not in str(failures[-1:]) else 'FAIL'}] {clip:18s} | Frames={frame_count:3d} | MaxPBLoc={max_pb_loc:.8f} | MaxPivotDev={max_pivot_dev:.8e} studs | Tracks={len(tracks)}")

print("=" * 90)
if failures:
    print(f"FAILED CHECKS COUNT: {len(failures)}")
    for fail in failures:
        print("  - ", fail)
else:
    print("ALL EMPIRICAL CHECKS PASSED: 10/10 CLIPS FLAWLESS!")
print("=" * 90)
