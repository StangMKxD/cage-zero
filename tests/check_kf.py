import json

with open("cage-zero-animation-work/test_output_v3/StandingIdle02/StandingIdle02-r15-keyframes.json") as f:
    d = json.load(f)

for i in range(5):
    p12 = d["frames"][i]["poses"][12]
    p13 = d["frames"][i]["poses"][13]
    print(f"Frame {i}: RightUpperLeg (pos={p12[:3]}, rot={p12[3:]})")
    print(f"         RightLowerLeg (pos={p13[:3]}, rot={p13[3:]})")
