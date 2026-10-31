#!/usr/bin/env python3
"""run_and_trace_idle.py — Run process_clip on Standing Idle 02 and trace knee dots.
"""

from pathlib import Path
import bpy
import sys

WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
sys.path.insert(0, str(WORKSPACE_ROOT / "cage-zero-animation-work" / "scripts"))
import batch_convert_v3

TEMPLATE_PATH = WORKSPACE_ROOT / "cage-zero-animation-work" / "templates" / "Rig_and_Attachments_Template.blend"
SOURCE_DIR = Path(r"C:\Users\Stang\cage-zero-dev\animation-mixamo" if not Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo").exists() else r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
FBX_FILE = SOURCE_DIR / "Standing Idle 02.fbx"
OUT_DIR = WORKSPACE_ROOT / "cage-zero-animation-work" / "test_output_v3"

print("Running process_clip on Standing Idle 02...")
res = batch_convert_v3.process_clip(
    fbx_path=str(FBX_FILE),
    output_dir=str(OUT_DIR),
    clip_name="StandingIdle02",
    loop_type="loop_y",
    priority="Movement",
    blend_template=str(TEMPLATE_PATH)
)
print(f"Result: {res}")
