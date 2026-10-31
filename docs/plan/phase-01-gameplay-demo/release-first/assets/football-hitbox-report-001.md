# RF02 Front kick volume / right-foot tuning

> **Superseded semantics:** Ownerย้ำว่าhitboxใช้เฉพาะตอนยังไม่ครองบอลเพื่อคำนวณทิศ/แรง ไม่ใช่จับบอล. ลบWaitingBall/ballsetupเข้าsweetspotแล้ว;carrierยิงปกติเต็มแรงและdebugซ่อน. ดู [รายงานล่าสุด002](football-actions-report-002.md). พฤติกรรมsetupในข้อความด้านล่างเป็นประวัติรุ่นก่อนแก้

ก่อนเริ่มเขียนhitboxได้ทำcheckpointcommit **22c3731** แล้วตามคำสั่งOwner. Hitboxdeltaเป็นworkingtreeแยกหลังcommitนี้ ไม่push/publish

## พฤติกรรม

- Shared KickHitbox / KickHitboxConfigs ตัดสินจากตำแหน่งballcenterในlocalhorizontalvolumeด้านหน้าserverroot. ไม่รับrange/qualityจากclient และไม่ใช้TouchedของdebugPart. บอลที่คนอื่นถือยังเตะไม่ได้
- ตรวจreadyที่Release/WaitingBallและตรวจอีกครั้งที่authoredcontacttime. จุดยิงบันทึกLastKickPointจากตำแหน่งบอลจริง ไม่วาร์ปบอลเข้าจุดยิง
- Shotกลางsweetspotแรงเต็ม;ขอบ/มุมลดแรงต่ำสุด45% และเบี่ยงซ้าย/ขวาสูงสุด18°. Passใช้volumeเดียวกันแต่ไม่ลดแรงแบบmishit. Ballsetupขณะง้างเข้าsweetspotตามvolumeใหม่
- Clientdebugกรอบ+จุดสัมผัส+ข้อความแรงเป็นcosmetic: Anchored, CanCollide/CanTouch/CanQuery=false,2parts ไม่cloneตัวละครหรือคลัง
- Ownerเห็นกรอบรุ่นแรกแล้วบอกใหญ่เกิน/ขออิงเท้าขวา: **ปรับล่าสุด Center=(0.75,-2.7,-2.3),Size=(2.6,2.4,2.6)studs**,PreferredFootRight. sweetspot/มุม/ทิศmishitคิดสัมพันธ์ศูนย์เท้าขวา ไม่ใช่กลางลำตัว. ด้านหน้าใกล้1.0ไกล3.6studs;ด้านข้างX[-0.55,2.05]

## หลักฐาน

- ก่อนลดขนาด: StudioactualLuau14hitboxassertionsผ่าน (หน้า/หลัง/ขอบ/NaN/หมุนroot/แรง/ทิศ). FootballActions2744ผ่านซ้ำ. Rojo/diffcheckผ่าน
- ก่อนลดขนาด: actualleftclickShotcenter quality0.99997/powerScale0.99998/speed102.58;edgequality0.21783/powerScale0.56981/deflection14.079°/speed57.33. เป็นการวัดserverจริง ไม่ใช่ภาพGIF
- ก่อนลดขนาด: debugFrameerror0,2parts,CanQuery/CanCollide=false;clientแสดงlabelและvolumeจริง. ยังไม่อ้างscreenshotvisualpass
- หลังลดขนาด: StudioactualLuau14assertionsผ่านซ้ำ;3ไฟล์config/math/debug compile+sync+readbackผ่าน. FreshPlayวัดSize=(2.6,2.4,2.6),localCenter=(0.75,-2.7,-2.3),frameError1.19209e-7stud,PreferredFootRight,2parts,labelระยะเตะเท้าขวา
- หลังลดขนาด: actualleftclickserverจบComplete/quality0.996991/powerScale0.998345/deflection0.054157°. ตรวจภาพจากหน้าต่างCage-Zeroผ่านComputerUseพบกรอบเล็กสีเหลืองอยู่ข้างหน้าเท้าขวา. ยังไม่ใช่Ownerยอมรับฟีลทั้งหมด
- เปิดStudioPlayค้างให้Ownerลอง ไม่สั่งStopซ้ำ/kill. Sourceเก็บในEditก่อนเริ่มPlayแล้ว. Hitboxdeltaยังuncommittedตามการแยกcheckpoint
- Knownenvironment: StudioStopPlayยังช้า sourcepreviewมีbackupจำนวนมาก;ไม่killStudioหรือส่งStopซ้ำ. มีerrorpluginBlenderAnimationsPackages/asset203785492เดิมแยกscope

Ownerยังต้องตรวจฟีลท่าต่อกันและขนาดhitboxเท้าขวาฉบับล่าสุด ไม่มีblanketRF02approval
