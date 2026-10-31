"""Authoritative Configuration and Feature Catalog for Mixamo-to-Roblox R15 v3 E2E Tests.

Target Project: CAGE ZERO — Mixamo to Roblox R15 Animation Conversion (v3 Canonical Batch)
Target Rig: Workspace.PreviewRigs.PreviewRig_R15_Boy_Height30 (Place 137721422246269)
Scope: Exactly 15 Mixamo Animation Clips (5 Loops, 10 One-Shots)
"""

import os
from pathlib import Path
from typing import Any, Dict, List, Optional

# Base Paths
WORKSPACE_ROOT = Path(r"C:\Users\Stang\cage-zero")
ANIMATION_WORK_DIR = WORKSPACE_ROOT / "cage-zero-animation-work"
SOURCE_DIR = Path(r"C:\Users\Stang\OneDrive\Desktop\stang\cage-zero-dev\animation-mixamo")
SRC_DIR = WORKSPACE_ROOT / "src"
STUDIO_RIG_JSON = ANIMATION_WORK_DIR / "jog-forward" / "studio-r15" / "rig.json"

# Output Directories (Local workspace and OneDrive cloud mirror)
OUTPUTAGY_DIR_LOCAL = WORKSPACE_ROOT / "outputagy"
OUTPUTAGY_DIR_ONEDRIVE = SOURCE_DIR / "outputagy"
OUTPUTAGY_V3_LOCAL = OUTPUTAGY_DIR_LOCAL / "v3"
OUTPUTAGY_V3_ONEDRIVE = OUTPUTAGY_DIR_ONEDRIVE / "v3"

# Primary OUTPUTAGY_DIR points to existing path (OneDrive is active source/output target)
OUTPUTAGY_DIR = OUTPUTAGY_DIR_ONEDRIVE if OUTPUTAGY_DIR_ONEDRIVE.is_dir() else OUTPUTAGY_DIR_LOCAL
OUTPUTAGY_V3_DIR = OUTPUTAGY_V3_ONEDRIVE if OUTPUTAGY_V3_ONEDRIVE.is_dir() else OUTPUTAGY_V3_LOCAL

# Manifest Paths
MANIFEST_V3_LOCAL = OUTPUTAGY_V3_LOCAL / "manifest.json"
MANIFEST_V3_ONEDRIVE = OUTPUTAGY_V3_ONEDRIVE / "manifest.json"

# R15 Boy Target Rig Expected Parts (15 driven parts)
EXPECTED_R15_PARTS = [
    "LowerTorso",
    "UpperTorso",
    "Head",
    "LeftUpperArm",
    "LeftLowerArm",
    "LeftHand",
    "RightUpperArm",
    "RightLowerArm",
    "RightHand",
    "LeftUpperLeg",
    "LeftLowerLeg",
    "LeftFoot",
    "RightUpperLeg",
    "RightLowerLeg",
    "RightFoot",
]

EXPECTED_PART_PARENTS = {
    "LowerTorso": "HumanoidRootPart",
    "UpperTorso": "LowerTorso",
    "Head": "UpperTorso",
    "LeftUpperArm": "UpperTorso",
    "LeftLowerArm": "LeftUpperArm",
    "LeftHand": "LeftLowerArm",
    "RightUpperArm": "UpperTorso",
    "RightLowerArm": "RightUpperArm",
    "RightHand": "RightLowerArm",
    "LeftUpperLeg": "LowerTorso",
    "LeftLowerLeg": "LeftUpperLeg",
    "LeftFoot": "LeftLowerLeg",
    "RightUpperLeg": "LowerTorso",
    "RightLowerLeg": "RightUpperLeg",
    "RightFoot": "RightLowerLeg",
}

# The 15 Joint Attachment Names on PreviewRig_R15_Boy_Height30
EXPECTED_JOINTS = [
    "Root",
    "Waist",
    "Neck",
    "LeftShoulder",
    "LeftElbow",
    "LeftWrist",
    "RightShoulder",
    "RightElbow",
    "RightWrist",
    "LeftHip",
    "LeftKnee",
    "LeftAnkle",
    "RightHip",
    "RightKnee",
    "RightAnkle",
]

# GIF Validation Standards
GIF_EXPECTED_DIMENSIONS = (512, 512)
GIF_MIN_FRAMES = 15
GIF_EXPECTED_LOOP = 0  # 0 indicates infinite loop in Netscape GIF extension
GIF_EXPECTED_FPS = 30
GIF_FRAME_DURATION_MS = 33

# Verified Source Mixamo FBX Cryptographic Baselines (from survey_assets_v3)
SOURCE_FBX_BASELINE: Dict[str, Dict[str, Any]] = {
    "Fast Run.fbx": {
        "sha256": "822FDC9D28AC97C53FAC37717F20A51A286B44FD389B135119467EC794E912AB",
        "size": 305616,
    },
    "Jog Forward.fbx": {
        "sha256": "836EF89582F9382598D0B2EDD82F57D3CB8C29DC136A512E45D5637A70C4C2EF",
        "size": 356912,
    },
    "Scissor Kick.fbx": {
        "sha256": "5E43F565ECE6768118C83BF6A4C7C5A08ECEE4AA6B112BA1C5591065F13687B4",
        "size": 576160,
    },
    "Soccer Pass.fbx": {
        "sha256": "B10D8ADCC2726A30DCC6BB691FD3DB7D943272780397C87397745806DB71156B",
        "size": 443856,
    },
    "Soccer Tackle.fbx": {
        "sha256": "E2BDC6A031D770C35F2BF6CED4EFCF15A1BA9154ADF5596B0092215CC9942CD0",
        "size": 462752,
    },
    "Soccer Trip.fbx": {
        "sha256": "508CEEB3EA6D41B95F71F611616040B586AEEC77901C3AC53540481AF349616A",
        "size": 443856,
    },
    "Standing Idle 02.fbx": {
        "sha256": "B5C38648952D1A547801200BEFB9B3E7FC2F3FEA1E6F46CB215D12D37551CDBF",
        "size": 732416,
    },
    "Standing Jump.fbx": {
        "sha256": "5BDF56BB036EC76CFB53BCAD13F06A7D24FE2C4A0B32A04798F3E5B865D9811E",
        "size": 538352,
    },
    "Strike Foward Jog.fbx": {
        "sha256": "271B484652B91ED6945CAE0361008E425CDB524CC403206A6C5DCA94BF02E4EC",
        "size": 409840,
    },
    "TurnBackRunning.fbx": {
        "sha256": "EB02912E98FDBAECB7950D2FB8DAF9C6BCE7E32E9B9727C56DDF4B0FFBD52460",
        "size": 430000,
    },
    os.path.join("goal", "Goalkeeper Catch.fbx"): {
        "sha256": "52160C2135CDA64B59E65D1CA0B8C29855328B8623127310CCD741AE54C4C9B8",
        "size": 568592,
    },
    os.path.join("goal", "Goalkeeper Diving Save.fbx"): {
        "sha256": "56062B57A3A2DC8DBA02C643B97ED13132B9CA8FEFE0CE1DE89E2AAB8BED4F54",
        "size": 629072,
    },
    os.path.join("goal", "Goalkeeper Overhand Throw.fbx"): {
        "sha256": "659A864774D08DC7BA7A39C07CF167CA54C63004F339F34D2C370D567DFAF54D",
        "size": 587280,
    },
    os.path.join("goal", "Goalkeeper Scoop.fbx"): {
        "sha256": "F0E88F910B52A68EE094E502D2F5B5A92D2DEA17E5B31F8189A819BA2293B584",
        "size": 557248,
    },
    os.path.join("goal", "Goalkeeper Sidestep.fbx"): {
        "sha256": "8D33AD568E618651D95F244DD2FF643975DC2A22F3C65D3C382C60A51825402F",
        "size": 305616,
    },
}

# The 33 Protected Dirty Files in src/ (from survey_assets_v3 Obs 1.4)
PROTECTED_SRC_FILES: Dict[str, str] = {
    "client/character/DribbleAnimationController.luau": "ADB3574B21C1D9EEE4BC481DCAD9F3AAB3F6BB8ABF74716F39FACB5D41C3C4D1",
    "client/character/DribbleAnimationHelper.luau": "0984215393F78DDDA4E980BCD15C6A97F04C58F16C8007AEA9240DF1F42815EC",
    "client/character/DribbleClipData.luau": "C4DE6FEF9DF29929DD395D61525485C22D3A96F674FC359CC15538A3CC1A1AF3",
    "client/character/R15AnimationController.luau": "CEC43800E26A0068102B12220091C52F6B0CB79FFF4EF5617C49F5858362CD1F",
    "client/character/R15LocomotionHelper.luau": "DDB009AAED7F3898DF5E308060B5A804A0AB2BAF0839E5BC931BFFE455ADE3F2",
    "client/character/SprintCutReferenceData.luau": "2C670BB2D918ADDB19775444B3C5FDA68AF01BD7B9F00F0D9C8584E88D9AACE3",
    "client/controllers/AirMovementController.luau": "1130166D326A13F51D12D0346AC601835417ABDCECE8ECA07D22DAB67947D7B3",
    "client/controllers/DribbleCutController.luau": "685C49C091CECD2903A31CB4383F3FDD844146220DC9F1B73517E98BDF36478B",
    "client/controllers/MovementHeadingPreviewController.luau": "23609944F4D5F216EC09228D2788E8704356664861CD777544A6C35BD4192B56",
    "client/controllers/SprintController.luau": "2EFE8863B73ABE911561B4FE165D5F2BD5258A8B9BAA2761F9639A46019275EF",
    "client/init.client.luau": "A7085B08C130F648A86220AFCA22E88584CA392145EA4BA083FD3176201956F7",
    "server/services/BallService.luau": "2519B510C67F3F830F68C33F96531968178D624AFB70884406366C79F2462B95",
    "server/services/SprintService.luau": "0076C6EFFA273E650647AD0F7D2100258E527A6FE28957A08384560F15873335",
    "shared/DribbleControlRules.luau": "A90B9D659802ED35FC5DC7B51B6AB29CAFD71FE500467B5D4FE4A2E4DBD50FA8",
    "shared/configs/DribbleActionConfigs.luau": "34D5E7B1BD93529B60F6D6F79259B8A52BFAC6C88D817E03657CA36414F5AA56",
    "shared/configs/R15LocomotionConfigs.luau": "1BB064FC998C265F7F077396617B49E7F456213CCB20040F1C03D7755818C9E8",
    "shared/configs/SprintConfigs.luau": "8F98FEC6B829F5998C9CF2B602E7FC02A40850A9D7DD7A89ADA0820F1D271616",
    "client/character/FastRunClipData.luau": "75B64242F548FCEF01F4566F613BD3C797A2D0D8BAAEDC340CDC528B0621EEBB",
    "client/character/JogForwardClipData.luau": "5B7051F89F9AAB717A4BA3C5F148B8E279C94F01DF6D120E31C629F99B74E8F8",
    "client/character/JumpClipData.luau": "23D6E7B10908838A7F19E4D03A54B8A55934F36C5ABCE2B1677E7D0CBA7D593B",
    "client/character/JumpReferenceData.luau": "98D9712A3BD5E663F559FA103C020CB4B219E939729683C466644190FB7EF697",
    "client/character/ShotChargeClipData.luau": "A2A72AE7032E4C7A6772084918B8D0B117B580429BD2EA8AFAF3E5A5CB05EE2F",
    "client/character/WalkDribbleReferenceData.luau": "272655B9E2394F7C9BDCF5714D5A8FC67F0AD347CDC38811D8B0486A4B1695ED",
    "client/controllers/ShotController.luau": "27738D37E423FB8A9D0FAC16CD2F02CFB055EA6D657449FE71468734F5D6C624",
    "shared/DribbleCutTimeline.luau": "E0F7B924FCD489890A507C9768DE2E1DED83A9C2C41451CEFAA60DE882860611",
    "shared/JumpAnimationTiming.luau": "DDC55D943F26BEBF66B49A52ECC7614CA227A7B1D1CBF0B178C34C0F0A3259CA",
    "shared/R15PoseSupport.luau": "EB7A0BF8D51F26BA07B0F26999B7E7DF6A18384AEB981B6F8D0AB5734C92713C",
    "shared/ShotModel.luau": "30BA5777186405442B51F14551205A839DAF0655BA2DCC9DE0E011497CDE8B9B",
    "shared/ShotReferenceData.luau": "AFCA6AC4079DDE54E94CA3E50576689766C7B4FDE8F76B4BB885EE8509164066",
    "shared/ShotRules.luau": "07CE101A3D500D706C5BBAB445215C179546887806A6F50E36AFD8E54A4D16E3",
    "shared/SprintSpeedRules.luau": "E74F05D9A9B10BC9E2B6B9B942DB5A1DE2A100B623067A516CE18F87E90872AF",
    "shared/configs/GroundTurnConfigs.luau": "7080C30218CC02D3218863CDC0AFCE5CAAC3392699A422C77500BA0EC0FC11CD",
    "shared/configs/ShotConfigs.luau": "C5F474D6986E9DA3A95B53524435FE49A85EAB7AE41877C057226C687201FE6B",
}

# The Authoritative 15 Canonical R15 Animation Catalog
ALL_15_CLIPS: List[Dict[str, Any]] = [
    # --- 5 Locomotion & Stance Loops ---
    {
        "id": 1,
        "name": "Fast Run",
        "slug": "fast-run",
        "category": "Outfield",
        "source_rel": "Fast Run.fbx",
        "source_sha256": "822FDC9D28AC97C53FAC37717F20A51A286B44FD389B135119467EC794E912AB",
        "source_size": 305616,
        "loop": True,
        "conversion_mode": "loop_y",
        "priority": "Movement",
        "gif_name_v03": "FastRun_R15_v03.gif",
        "gif_name_legacy": "FastRun_R15.gif",
        "fbx_name": "FastRun_R15.fbx",
        "keyframes_name": "fast-run-r15-keyframes.json",
        "recipe_name": "FastRun.recipe.json",
        "duration_mixamo": 0.5333,
        "frames_mixamo": 17,
        "expected_travel": {"axis": "Y", "distance": 2.85, "extracted": True},
        "behavior": "forward_sprint_loop",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 2,
        "name": "Jog Forward",
        "slug": "jog-forward",
        "category": "Outfield",
        "source_rel": "Jog Forward.fbx",
        "source_sha256": "836EF89582F9382598D0B2EDD82F57D3CB8C29DC136A512E45D5637A70C4C2EF",
        "source_size": 356912,
        "loop": True,
        "conversion_mode": "loop_y",
        "priority": "Movement",
        "gif_name_v03": "JogForward_R15_v03.gif",
        "gif_name_legacy": "JogForward_R15.gif",
        "fbx_name": "JogForward_R15.fbx",
        "keyframes_name": "jog-r15-keyframes.json",
        "recipe_name": "JogForward.recipe.json",
        "duration_mixamo": 0.8333,
        "frames_mixamo": 26,
        "expected_travel": {"axis": "Y", "distance": 2.21, "extracted": True},
        "behavior": "forward_jog_loop",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 3,
        "name": "Standing Idle 02",
        "slug": "standing-idle-02",
        "category": "Outfield",
        "source_rel": "Standing Idle 02.fbx",
        "source_sha256": "B5C38648952D1A547801200BEFB9B3E7FC2F3FEA1E6F46CB215D12D37551CDBF",
        "source_size": 732416,
        "loop": True,
        "conversion_mode": "loop_inplace",
        "priority": "Movement",
        "gif_name_v03": "StandingIdle02_R15_v03.gif",
        "gif_name_legacy": "StandingIdle02_R15.gif",
        "fbx_name": "StandingIdle02_R15.fbx",
        "keyframes_name": "standing-idle-02-r15-keyframes.json",
        "recipe_name": "StandingIdle02.recipe.json",
        "duration_mixamo": 5.2000,
        "frames_mixamo": 157,
        "expected_travel": {"axis": None, "distance": 0.0},
        "behavior": "idle_balance_loop",
        "subsample_max_keys": 128,
        "expected_knee_front_dot_min": 0.60,
    },
    {
        "id": 4,
        "name": "Strike Foward Jog",
        "slug": "strike-foward-jog",
        "category": "Outfield",
        "source_rel": "Strike Foward Jog.fbx",
        "source_sha256": "271B484652B91ED6945CAE0361008E425CDB524CC403206A6C5DCA94BF02E4EC",
        "source_size": 409840,
        "loop": True,
        "conversion_mode": "loop_y",
        "priority": "Movement",
        "gif_name_v03": "StrikeFowardJog_R15_v03.gif",
        "gif_name_legacy": "StrikeFowardJog_R15.gif",
        "fbx_name": "StrikeFowardJog_R15.fbx",
        "keyframes_name": "strike-foward-jog-r15-keyframes.json",
        "recipe_name": "StrikeFowardJog.recipe.json",
        "duration_mixamo": 1.3000,
        "frames_mixamo": 40,
        "expected_travel": {"axis": "Y", "distance": 3.1178, "extracted": True},
        "behavior": "locomotion_loop_in_place",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 5,
        "name": "Goalkeeper Sidestep",
        "slug": "goalkeeper-sidestep",
        "category": "Goalkeeper",
        "source_rel": os.path.join("goal", "Goalkeeper Sidestep.fbx"),
        "source_sha256": "8D33AD568E618651D95F244DD2FF643975DC2A22F3C65D3C382C60A51825402F",
        "source_size": 305616,
        "loop": True,
        "conversion_mode": "loop_x",
        "priority": "Movement",
        "gif_name_v03": "GoalkeeperSidestep_R15_v03.gif",
        "gif_name_legacy": "GoalkeeperSidestep_R15.gif",
        "fbx_name": "GoalkeeperSidestep_R15.fbx",
        "keyframes_name": "goalkeeper-sidestep-r15-keyframes.json",
        "recipe_name": "GoalkeeperSidestep.recipe.json",
        "duration_mixamo": 0.5333,
        "frames_mixamo": 17,
        "expected_travel": {"axis": "X", "distance": 1.2555, "extracted": True},
        "behavior": "lateral_shuffle_loop",
        "expected_knee_front_dot_min": 0.70,
    },
    # --- 10 Action One-Shots (Preserve Ending/Recovery Frames) ---
    {
        "id": 6,
        "name": "Scissor Kick",
        "slug": "scissor-kick",
        "category": "Outfield",
        "source_rel": "Scissor Kick.fbx",
        "source_sha256": "5E43F565ECE6768118C83BF6A4C7C5A08ECEE4AA6B112BA1C5591065F13687B4",
        "source_size": 576160,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "ScissorKick_R15_v03.gif",
        "gif_name_legacy": "ScissorKick_R15.gif",
        "fbx_name": "ScissorKick_R15.fbx",
        "keyframes_name": "scissor-kick-r15-keyframes.json",
        "recipe_name": "ScissorKick.recipe.json",
        "duration_mixamo": 2.7667,
        "frames_mixamo": 84,
        "expected_travel": {"vertical_leap": 1.0271},
        "behavior": "acrobatic_kick_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 7,
        "name": "Soccer Pass",
        "slug": "soccer-pass",
        "category": "Outfield",
        "source_rel": "Soccer Pass.fbx",
        "source_sha256": "B10D8ADCC2726A30DCC6BB691FD3DB7D943272780397C87397745806DB71156B",
        "source_size": 443856,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "SoccerPass_R15_v03.gif",
        "gif_name_legacy": "SoccerPass_R15.gif",
        "fbx_name": "SoccerPass_R15.fbx",
        "keyframes_name": "soccer-pass-r15-keyframes.json",
        "recipe_name": "SoccerPass.recipe.json",
        "duration_mixamo": 1.6000,
        "frames_mixamo": 49,
        "expected_travel": {"axis": None, "distance": 0.0},
        "behavior": "ground_pass_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 8,
        "name": "Soccer Tackle",
        "slug": "soccer-tackle",
        "category": "Outfield",
        "source_rel": "Soccer Tackle.fbx",
        "source_sha256": "E2BDC6A031D770C35F2BF6CED4EFCF15A1BA9154ADF5596B0092215CC9942CD0",
        "source_size": 462752,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "SoccerTackle_R15_v03.gif",
        "gif_name_legacy": "SoccerTackle_R15.gif",
        "fbx_name": "SoccerTackle_R15.fbx",
        "keyframes_name": "soccer-tackle-r15-keyframes.json",
        "recipe_name": "SoccerTackle.recipe.json",
        "duration_mixamo": 1.7667,
        "frames_mixamo": 54,
        "expected_travel": {"axis": "Y", "distance": 4.6171},
        "behavior": "sliding_tackle_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 9,
        "name": "Soccer Trip",
        "slug": "soccer-trip",
        "category": "Outfield",
        "source_rel": "Soccer Trip.fbx",
        "source_sha256": "508CEEB3EA6D41B95F71F611616040B586AEEC77901C3AC53540481AF349616A",
        "source_size": 443856,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "SoccerTrip_R15_v03.gif",
        "gif_name_legacy": "SoccerTrip_R15.gif",
        "fbx_name": "SoccerTrip_R15.fbx",
        "keyframes_name": "soccer-trip-r15-keyframes.json",
        "recipe_name": "SoccerTrip.recipe.json",
        "duration_mixamo": 1.6000,
        "frames_mixamo": 49,
        "expected_travel": {"axis": "Z", "distance": -0.7622, "vertical_drop": True},
        "behavior": "trip_fall_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 10,
        "name": "Standing Jump",
        "slug": "standing-jump",
        "category": "Outfield",
        "source_rel": "Standing Jump.fbx",
        "source_sha256": "5BDF56BB036EC76CFB53BCAD13F06A7D24FE2C4A0B32A04798F3E5B865D9811E",
        "source_size": 538352,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "StandingJump_R15_v03.gif",
        "gif_name_legacy": "StandingJump_R15.gif",
        "fbx_name": "StandingJump_R15.fbx",
        "keyframes_name": "standing-jump-r15-keyframes.json",
        "recipe_name": "StandingJump.recipe.json",
        "duration_mixamo": 2.4333,
        "frames_mixamo": 74,
        "expected_travel": {"axis": "Z", "distance": 0.8739},
        "behavior": "standing_jump_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 11,
        "name": "TurnBackRunning",
        "slug": "turn-back-running",
        "category": "Outfield",
        "source_rel": "TurnBackRunning.fbx",
        "source_sha256": "EB02912E98FDBAECB7950D2FB8DAF9C6BCE7E32E9B9727C56DDF4B0FFBD52460",
        "source_size": 430000,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "TurnBackRunning_R15_v03.gif",
        "gif_name_legacy": "TurnBackRunning_R15.gif",
        "fbx_name": "TurnBackRunning_R15.fbx",
        "keyframes_name": "turn-back-running-r15-keyframes.json",
        "recipe_name": "TurnBackRunning.recipe.json",
        "duration_mixamo": 1.6333,
        "frames_mixamo": 50,
        "expected_travel": {"heading_rotation": 180.0},
        "behavior": "pivot_turn_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 12,
        "name": "Goalkeeper Catch",
        "slug": "goalkeeper-catch",
        "category": "Goalkeeper",
        "source_rel": os.path.join("goal", "Goalkeeper Catch.fbx"),
        "source_sha256": "52160C2135CDA64B59E65D1CA0B8C29855328B8623127310CCD741AE54C4C9B8",
        "source_size": 568592,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "GoalkeeperCatch_R15_v03.gif",
        "gif_name_legacy": "GoalkeeperCatch_R15.gif",
        "fbx_name": "GoalkeeperCatch_R15.fbx",
        "keyframes_name": "goalkeeper-catch-r15-keyframes.json",
        "recipe_name": "GoalkeeperCatch.recipe.json",
        "duration_mixamo": 2.7000,
        "frames_mixamo": 82,
        "expected_travel": {"axis": "Y", "distance": 4.2494},
        "behavior": "aerial_catch_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 13,
        "name": "Goalkeeper Diving Save",
        "slug": "goalkeeper-diving-save",
        "category": "Goalkeeper",
        "source_rel": os.path.join("goal", "Goalkeeper Diving Save.fbx"),
        "source_sha256": "56062B57A3A2DC8DBA02C643B97ED13132B9CA8FEFE0CE1DE89E2AAB8BED4F54",
        "source_size": 629072,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "GoalkeeperDivingSave_R15_v03.gif",
        "gif_name_legacy": "GoalkeeperDivingSave_R15.gif",
        "fbx_name": "GoalkeeperDivingSave_R15.fbx",
        "keyframes_name": "goalkeeper-diving-save-r15-keyframes.json",
        "recipe_name": "GoalkeeperDivingSave.recipe.json",
        "duration_mixamo": 3.2333,
        "frames_mixamo": 98,
        "expected_travel": {"horizontal_dive": 2.9996},
        "behavior": "horizontal_diving_save_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 14,
        "name": "Goalkeeper Overhand Throw",
        "slug": "goalkeeper-overhand-throw",
        "category": "Goalkeeper",
        "source_rel": os.path.join("goal", "Goalkeeper Overhand Throw.fbx"),
        "source_sha256": "659A864774D08DC7BA7A39C07CF167CA54C63004F339F34D2C370D567DFAF54D",
        "source_size": 587280,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "GoalkeeperOverhandThrow_R15_v03.gif",
        "gif_name_legacy": "GoalkeeperOverhandThrow_R15.gif",
        "fbx_name": "GoalkeeperOverhandThrow_R15.fbx",
        "keyframes_name": "goalkeeper-overhand-throw-r15-keyframes.json",
        "recipe_name": "GoalkeeperOverhandThrow.recipe.json",
        "duration_mixamo": 2.8333,
        "frames_mixamo": 86,
        "expected_travel": {"axis": "Y", "distance": 3.9495},
        "behavior": "distribution_throw_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
    {
        "id": 15,
        "name": "Goalkeeper Scoop",
        "slug": "goalkeeper-scoop",
        "category": "Goalkeeper",
        "source_rel": os.path.join("goal", "Goalkeeper Scoop.fbx"),
        "source_sha256": "F0E88F910B52A68EE094E502D2F5B5A92D2DEA17E5B31F8189A819BA2293B584",
        "source_size": 557248,
        "loop": False,
        "conversion_mode": "oneshot",
        "priority": "Action",
        "gif_name_v03": "GoalkeeperScoop_R15_v03.gif",
        "gif_name_legacy": "GoalkeeperScoop_R15.gif",
        "fbx_name": "GoalkeeperScoop_R15.fbx",
        "keyframes_name": "goalkeeper-scoop-r15-keyframes.json",
        "recipe_name": "GoalkeeperScoop.recipe.json",
        "duration_mixamo": 2.6000,
        "frames_mixamo": 79,
        "expected_travel": {"axis": "Y", "distance": 4.0685},
        "behavior": "ground_scoop_save_oneshot",
        "expected_knee_front_dot_min": 0.70,
    },
]

# Set TARGET_ANIMATIONS to the authoritative 15 clips catalog
TARGET_ANIMATIONS = ALL_15_CLIPS

# Loop vs One-shot Slugs Subsets
LOOP_SLUGS = [a["slug"] for a in ALL_15_CLIPS if a["loop"]]
ONESHOT_SLUGS = [a["slug"] for a in ALL_15_CLIPS if not a["loop"]]

# Reference Completed Animations (Baseline for Self-Testing & Integrity)
REFERENCE_ANIMATIONS = [
    ALL_15_CLIPS[0],  # Fast Run
    ALL_15_CLIPS[1],  # Jog Forward
    ALL_15_CLIPS[3],  # Strike Foward Jog
    ALL_15_CLIPS[4],  # Goalkeeper Sidestep
]

# Baseline Snapshot of SRC files (Saved at start of animation project)
SRC_BASELINE_MANIFEST = Path(__file__).resolve().parent / "src_baseline_manifest.json"
