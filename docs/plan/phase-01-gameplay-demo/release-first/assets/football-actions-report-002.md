# RF02 — ปล่อยเตะทันที / ส่งตามเล็ง / ปั่นชัดขึ้น

2026-10-31 · Root ลงมือเอง · READY_FOR_OWNER_PLAYTEST · Working tree หลังcheckpoint22c3731. ไม่มีcommitเพิ่ม/push/publish

## ขอบเขตล่าสุดที่ Owner ยืนยัน

- Owner ทดลองแล้วแจ้งว่าปัญหาง้างตอนปล่อยหายแล้ว. Clientเริ่มreleaseโดยไม่รอack/บอล; serverReleaseเข้าWindupทันที. ลบWaitingBallและการลากบอลเข้าsweetspotออก โค้ดเดิมเก็บcomment
- ถอดReverseTurnAnimationControllerจากbootstrap และถอดtriggerเมาส์/ทิศตรงข้าม. การวิ่งตรงข้ามไม่มีโทษ25.92เฉพาะทางแล้ว; cardinal32/diagonal28.8และ90°slowdownเดิมยังอยู่. เก็บคลิป/sourceเก่าเป็นreference ไม่เล่นท่ากลับตัวแทรก
- Hitboxเท้าขวาใช้กับ **บอลที่ยังไม่ครอง ณ จังหวะสัมผัส** เท่านั้น. ขอบคำนวณแรง/ทิศ Shot;ไม่จับ/ดึงบอล. ตอนครองบอลใช้normalserverdistanceguardและแรง/ทิศปกติ quality1 ไม่มีmishit. Debugซ่อนตอนเป็นcarrier
- Passใช้aimเต็มXYZ: เล็งลงกระทบพื้นเด้งด้วยfloorphysics เล็งสูงโด่ง. Speed42–80stud/s,fullcharge0.55sเฉพาะส่ง;groundPassfriction0.65แทน1.6จึงไม่หมดแรงทันที
- Shotตรงเพิ่ม54–128เป็น60–142stud/s (~11%),fullchargeยัง1.2s
- CurveShotใช้78%ของความเร็วยิงตรงที่ระดับชาร์จเดียวกัน,โค้ง90°/sนาน1.1sตามside ไม่มีhoming. แทนสูตรเดิม24/speedซึ่งความโค้งอ่อนเมื่อยิงเร็ว. จำA/Dระหว่างง้างเพื่อไม่ให้ปล่อยAก่อนเมาส์แล้วเสียทิศ

## ผลตรวจจริงผ่าน MCP

- 20files compile/sync/readbackผ่าน. Rojo package `.sandbox/pass-aim-curve-tuning.rbxlx` และdiffcheckผ่าน
- ActualLuau: FootballActions2746 assertions,PassCurve18ผ่าน. SprintSpeed32และKickHitbox14ผ่านในรอบclarificationก่อนปรับแรง (logicส่วนนี้ไม่เปลี่ยนในการปรับแรง)
- Inputจริง no-ball: Charging→Windup→Whiff→Complete ไม่มีWaitingBall;releaseมองเห็นในprobeแรก0.0142s. Ownerระบุว่าหายแล้ว
- ตอนcarrier: debugกรอบTransparency1/labelปิด,LastKickUsedHitbox=false/quality1;ระหว่างง้างตำแหน่งบอลlocalX≈0,Z=-2.75ไม่ถูกดึงไปเท้าขวา/sweetspot
- ไม่มีReverse trackและbootstrapไม่เรียกcontrollerแล้ว
- E600ms,aimY=-0.6: floorbounceทำให้velocityYเป็น+36.65และบอลขึ้นสูง7.14studหลัง0.2s
- E600ms,aimY=+0.6: velocityY+46.82,บอลสูง9.12studหลัง0.2s,power1
- RightMouseจริง: curve+1,ความเร็ว97.74,เปลี่ยนทิศ-16.78°หลัง0.2s
- A+RightMouseจริง: curve-1,ความเร็ว94.16,เปลี่ยนทิศ+18.00°หลัง0.2s. ค่าความเร็วสองครั้งขึ้นกับcharge ไม่ใช่การเปรียบเทียบpowerเท่ากัน;unitตรวจscale0.78เท่ากันไว้แล้ว
- คืนrenderbindingกล้อง/ค่าวิ่งที่ใช้fixtureและปล่อยปุ่มAแล้ว ปิดdiagnosticScriptsที่เก็บrows ไม่ปล่อยงานเก็บlogโตต่อ. Playเปิดให้Ownerลอง
- ErrorBlenderAnimationsPackages/asset203785492เดิมยังอยู่แยกscope ไม่เรียกว่าconsoleสะอาดหรือfullregression

## Studio หนัก: สิ่งที่พิสูจน์ได้

ActualServerและClientต่างพบPreviewRig_R15_Boy_Height30 **190852descendants** ถูกreplicateมาทั้งก้อน ขณะที่playercharacterมี329descendants. AnimSaves86children มีชื่อซ้ำ2–4ชุด เช่นJogForwardv2×4,FastRunv2×3,SoccerPassv2×3 และมีbackupfoldersเก่า11ชุด

การล้างlibrary103→29ก่อนหน้าไม่ได้ล้างAnimSavesในplace เพราะเป็นคนละคลัง. การimport/exportซ้ำทำให้มีข้อมูลซ้ำจริง;จำนวนอย่างเดียวไม่ยืนยันว่าใครสร้างทุกอัน. BackupG/Walk/Cutบางส่วนเป็นของRootเองที่เก็บตามOwnerขอรักษาประวัติ

พบในtoolsource `C:/Users/Stang/AI-Tools/motion-tools/studio/Preview.lua:16` ว่าcloneทั้งmodelก่อนตัดscripts ทำให้AnimSaves/backupsติดไปviewportได้. รอบก่อนOwnerอนุญาตล้างเฉพาะสำเนาและล้าง190532instancesแล้ว;ต้นฉบับและbackupยังครบ. **ยังไม่ได้แก้การจัดเก็บในplaceหรือpatchpluginถาวร** จึงไม่อ้างว่าหายค้างถาวร

ต้องแยกarchive/ข้อมูลauthoringออกจากWorkspaceและหลีกเลี่ยงcloneคลังเข้าviewportก่อนจะสรุปผลperformanceระยะยาว. ไม่ควรโทษจำนวนframeต่อคลิปอย่างเดียว. ไม่killStudio/แตะPlace2/ใช้ComputerUseต่อหลังOwnerกำหนดMCPเป็นหลัก
