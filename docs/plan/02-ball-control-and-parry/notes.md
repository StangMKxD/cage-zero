# Technical Notes — MODULE 02: `02-ball-control-and-parry`

- **BallService:** จัดการ Possession, Stamina (`0.0–1.0`), `IsInShootingZone` (`Z >= 10` สำหรับทีมบุกฝั่งใต้, `Z <= -10` สำหรับทีมบุกฝั่งเหนือ, และระยะ `<= 55 Studs` ในโหมด `1v1v1`), และการตรวจจับ Mistake (`StaminaExhausted`, `BadFirstTouch`, `SharpTurnOffBalance`)
- **ParryService:** ตรวจจับลูกบอลที่ถูกส่ง/ยิงผ่านรัศมี `<= 5.0 Studs` ของกองหลัง เปิดหน้าต่าง `0.35 วินาที` โดยไม่ตัดเข้าหน้าจอดวล 1v1 และตรวจสอบจังหวะกดด้วย `os.clock()` บน Server หากกดพลาดติด `MissedSlideRecovery` `0.50 วินาที`
