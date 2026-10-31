#!/usr/bin/env python3
"""check_soccer_tackle.py — Inspect Soccer Tackle Hips motion.
"""

from pathlib import Path
import bpy

TEMPLATE_PATH = Path(r"C:\Users\Stang\cage-zero\cage-zero-animation-work\templates\Rig_and_Attachments_Template.blend")
SOURCE_DIR = Path(r"C:\Users\Stang\cage-zero-dev\animation-mixamo" if not Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo").exists() else r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
FBX_FILE = SOURCE_DIR / "Soccer Tackle.fbx"

bpy.ops.wm.open_mainfile(filepath=str(TEMPLATE_PATH))
bpy.ops.import_scene.fbx(filepath=str(FBX_FILE))
src = next(o for o in bpy.data.objects if o.type == 'ARMATURE' and o.name != 'StudioR15_Target' and o.name != 'Armature')

hips = src.pose.bones.get('mixamorig:Hips') or src.pose.bones.get('Hips')
print(f"SoccerTackle source frames 1 to 54:")
for f in [1, 10, 20, 30, 40, 50, 54]:
    bpy.context.scene.frame_set(f)
    bpy.context.view_layer.update()
    print(f"F{f:02d}: Hips head={hips.head[:]}")
