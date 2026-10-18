# Tasks — MODULE 02: `02-ball-control-and-parry`

- `[ ] Task 02.1:` เขียน `src/server/services/BallService.luau` จัดการการครอบครองบอล (`Possession`), ความเร็วการเลี้ยง, การลด-ฟื้นฟูหลอด Stamina และการตรวจจับ `Shooting Zone`
- `[ ] Task 02.2:` เขียน `src/client/controllers/InputController.luau` รับคำสั่งเลี้ยง ส่ง ยิง และปุ่มกด Parry
- `[ ] Task 02.3:` เขียน `src/server/services/ParryService.luau` ตรวจจับวิถีลูกบอลที่ถูกส่งหรือยิงผ่านรัศมี 5 Studs ของกองหลังโดยไม่เข้าหน้าจอดวล
- `[ ] Task 02.4:` เขียน `src/client/controllers/ParryIndicatorController.luau` เชื่อมกับ `ParryPromptOverlay.luau` แสดงวงแหวนจังหวะกด Parry (`0.35 วินาที`) หากกดตรงจังหวะจะได้ตัดบอลทันที หากกดพลาดจะติด Recovery Cooldown
