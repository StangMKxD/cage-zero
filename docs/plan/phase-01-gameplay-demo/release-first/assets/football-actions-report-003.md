# RF02 — ลดโค้ง / กรอบใหญ่ขึ้น / จัดบอลตามเล็ง / ส่งไกลขึ้น

2026-10-31 · Root ทำเองผ่าน MCP · READY_FOR_OWNER_PLAYTEST · Working tree หลังcheckpoint22c3731 ไม่มีcommit/push/publishเพิ่ม

## Owner delta ล่าสุด

- Curveลด90→50°/s และเวลา1.1→0.85s (มุมรวมในกรณีไม่ชนประมาณ99→42.5°). ความเร็วยัง78%ของยิงตรง
- Hitboxขยาย2.6×2.4×2.6→**3.4×2.8×3.4studs**,Center=(0.75,-2.7,-2.5),คงเท้าขวาเป็นหลัก
- Ownerเปลี่ยนข้อกำหนดการครองบอล: ตอนง้างยิง/ส่งให้บอลที่ครองอยู่ค่อยๆจัดเข้ากรอบตามทิศเล็ง. ทำเฉพาะcarrierbranchด้วยvelocityจำกัดและcollision/body sweepเดิม ไม่วาร์ปบอล ไม่ดึงบอลอิสระหรือบอลของคนอื่น
- ส่งaimระหว่างง้าง10Hzบนremoteเดิม มีnonce/character/kind/Chargingphase/finitevector/rate-limit0.08sฝั่งserver. เล็งแนวตั้งยังคุมวิถีปล่อยบอลเต็มXYZ;จัดบอลที่พื้นตามaimแนวราบ. Releaseยังเตะทันที ไม่คืนWaitingBallหรือท่ากลับตัว
- Debugกรอบแสดงขณะจัดบอลที่ครองอยู่และหันตามaim;ปกติซ่อนตอนcarrierไม่ได้ง้าง. Free-ballhitbox/mishitคงทำหน้าที่เดิม;carrierยังยิงเต็มตามปกติ ไม่คิดmishitจากกรอบ
- Passเพิ่ม42–80→46–90stud/s และgroundfriction0.65→0.45เฉพาะfreePass ให้ส่งไกลขึ้นโดยไม่เปลี่ยนลูกยิง/การเลี้ยงอื่น. เกจส่ง0.55sเดิม

## ตรวจจริง

- Rojo build `.sandbox/aimed-setup-pass-range.rbxlx` และdiffcheckผ่าน
- 20files compile/sync/exactreadbackผ่านในCage-Zero137721422246269
- ActualLuau: PassCurve18, KickHitbox17ผ่าน (รวมaimframe/offset/sweetspot)
- Private uninitializedBallService fixture9ข้อผ่าน: Begin/Aim nonceผิด/NaN/rate limit/Aimถูกต้อง/Releaseทันทีเข้าWindup/Aimหลังrelease/Cancel. ไม่มีInitหรือwriterบอลตัวที่สอง คืนcharacterattributesหลังfixture
- ActualMousehold0.9s: หมุนaimจาก-Zเป็น+Xระหว่างง้าง;serverAim=(1,0,0),บอลยังเป็นเจ้าของเดิม,insideAimVolume=true,ระยะห่างtargetแนวราบ0.04844stud ณ0.65s
- ActualE0.6s: Passspeed89.31stud/s,วิ่งได้53.28studหลัง0.7sและยังเร็ว65.34stud/s
- ActualRightMouse: Curvespeed97.64stud/s,เปลี่ยนทิศ-10.06°หลัง0.2s (รอบก่อนประมาณ-16.78°ในตัวอย่างที่ทดสอบ). ไม่อ้างว่าเป็นbenchmarkสภาพเหมือนกันทุกประการ
- คืนกล้องและunbindrenderfixtureแล้ว ปิดdiagnosticScriptsทั้งหมดของรอบนี้;Playเปิดให้Ownerลอง. ไม่มีComputerUseในรอบนี้

ข้อจำกัดStudio/ข้อมูลซ้ำในplaceยังตามรายงาน002 ไม่ถือว่าปัญหาค้างได้รับการแก้ถาวรจากการจูนบอล
