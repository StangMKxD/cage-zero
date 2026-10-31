#!/usr/bin/env python3
"""check_dirty_pb_location.py — Check pb.location of all bones in all 10 .blend files.
"""

from pathlib import Path
import bpy

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
TEST_OUTPUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"

CLIPS = [
    "FastRun", "JogForward", "ScissorKick", "SoccerPass", "SoccerTackle",
    "SoccerTrip", "StandingIdle02", "StandingJump", "TurnBackRunning", "StrikeFowardJog"
]

print(f"{'Clip Name':18s} | {'Worst Non-Root Bone':18s} | {'Max Loc Length (studs)':22s}")
print("-" * 65)

for clip in CLIPS:
    bfile = TEST_OUTPUT_DIR / clip / f"{clip}_R15_v03.blend"
    bpy.ops.wm.open_mainfile(filepath=str(bfile))
    rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    
    max_len = 0.0
    worst_bone = "None"
    for pb in rig.pose.bones:
        if pb.name == 'LowerTorso':
            continue
        l = pb.location.length
        if l > max_len:
            max_len = l
            worst_bone = pb.name
    print(f"{clip:18s} | {worst_bone:18s} | {max_len:.8f} studs")
