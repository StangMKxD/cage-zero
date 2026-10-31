# RF02 Football actions — checkpoint ก่อน hitbox

Owner สั่ง Root ทำเอง: Shot `0a38ab54`, reverse `fcecd793`, walk dribble `69f7c65f`, Run/no-ball+dribble `c63773e9`, Pass `a35ae5a3`; Eค้างง้าง/ปล่อยส่ง. Snapshotข้อมูลจริง5assetsอยู่ FootballClipReferenceData โดยไม่พึ่งคลังMotionตอนruntime. โค้ดเดิมเก็บcomment

## ช่วงแรก

อนุญาต commit checkpointก่อนเริ่มhitboxตามคำสั่งOwnerโดยตรง. ไม่มีpush/publish. ใช้ source checkpointปัจจุบันพร้อม dependency ของงาน locomotion/jump/shoot เดิมที่ยังuntracked; ไม่รวม .gitignore, outputagy, generatedartifacts หรือชุดงานAGYนอกscope

- Shooting/Passing server-authoritative nonce/finiteaim/cooldown/ground checks. Beginง้างได้ก่อนมีบอล, Releaseรอบอล1s, ห้ามเตะบอลที่คนอื่นถือ, สัมผัสเท้าตามsourceframeก่อนเปลี่ยนvelocity. Chargeท่าstationary/movingมาจากช่วงต้นของแต่ละคลิป
- Reverseเล่นเฉพาะคู่ทิศตรงข้ามหรือหันเมาส์เกิน110°ใน0.25s; fullturnclipย่อเวลา0.7s. ไม่กลับไปใช้ระบบcut/ล็อคบอลเดิม
- เดิน/วิ่งเลี้ยงใช้Jog/FastRunv2พร้อม2touchmarkers;ตัวเปล่าWalkJogv2/RunFastv2
- เวลาShotConfigsปรับอิง FootballActionConfigs แทนตัวเลขเก่า และเคลียร์trackreferenceเมื่อrespawn
- แก้การsweepตรวจสัมผัส: ตรวจช่วงauthoredcontactหนึ่งครั้งแม้servertickช้าข้ามปลายwindow ไม่ขยายระยะเท้า ไม่บังคับhit

## ผลตรวจที่ทำจริง

- Rojo package buildและdiffcheckผ่านก่อนcheckpoint
- Studio16files compile/sync/readbackผ่านก่อนslowticklinefix;บรรทัดfixสุดท้ายจะตรวจใหม่กับhitbox delta
- StudioactualLuau FootballActions2744assertions +Sprint34ผ่าน;ตัวตรวจคลิปWalkDribble26keys/RunDribble17keysผ่าน พร้อมmarker
- Actualinput E: Charging→Windup→Struck→Complete, Passปล่อยballspeed44.018stud/s. ActualleftclickShot: Struck/DirectShoot98.520stud/s (ไม่ใช่ค่าความเร็วคงที่ ขึ้นกับชาร์จ)
- Actualtracks: ReverseTurn_fcecd793 weight1 และWalk/Run fallbackweight1. Consoleไม่มีdribblevalidationerrorหลังเติมmarker; errorBlenderAnimationsPackages/asset203785492ยังเป็นปัญหาเก่าคนละscope
- Serverlate-ballfixture: PassWaitingBall→Struck; ShottraceWaitingBall→Struckเมื่อบอลอยู่ในช่วงสัมผัส. มีหนึ่งครั้งShotWhiffขณะบอลมีvelocity140.2ตอนWindup จึงไม่อ้างว่าทุกlateballต้องเข้า. Hitboxช่วงถัดไปจะกำหนดeligibleระยะด้านหน้าชัดเจน
- ยังไม่ใช่Ownervisualacceptanceหรือfullregression

## ช่วงถัดไปที่ Owner อนุญาต

หลังcheckpointcommitสำเร็จจึงสร้างhitboxด้านหน้าplayerที่มองเห็นได้ ใช้คำนวณeligiblecontact/จุดยิง. ขอบ/มุมทำให้Shotแรงลดและทิศคลาด (Ownerเลือกแล้ว);ไม่มีการrandomความเสียหายหรือเพิ่มcombat. ให้เซิร์ฟเวอร์ตัดสินจากroot+ตำแหน่งบอลจริง debugเป็นcosmeticเท่านั้น
