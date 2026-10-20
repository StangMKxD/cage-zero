# UI State & Routing — target หลัง Q22

Decision Accepted / Delivery Planned — 2026-10-20; source UIเก่ายังต้องretireตามHANDOFFของแผนเจ้าของ ไม่มีimplementationapprovalจากเอกสารนี้ [Spec05](../specs/spec-05-ui-navigation-and-hud.md)

## Phase1 — Gameplay/Training

ใช้UIManager routerเดียว HUD/fixtureขั้นต่ำของ02/03/06ทดสอบได้ก่อน08 ตัวเลือกอุปกรณ์/การจัดวางหน้าจอล็อกเมื่อเปิด08 ไม่เพิ่มLobby/แมตช์เต็มเพื่อให้เล่นDemoได้

| State / event | Target UI / control |
| --- | --- |
| เตรียม/หยุด/รีเซ็ตซ้อม | เลือก3skillsจาก5ฟรี/initialteam/scenario; Debug06จูนค่าและเสกDummyได้ตามสิทธิ์ |
| เริ่มรอบเล่น | ล็อกloadoutระหว่างรอบ; แสดงcontext3คู่/3slots/ดาว/CD/Stamina/recovery |
| ทีมครองล่าสุด | ยิง/ส่ง/ยิงโค้ง ทั้งทีมคงlabelหลังปล่อยบอล ไม่มีบอลในระยะก็ไม่ได้สิทธิ์ยิง |
| อีกทีมครองสำเร็จ | เปลี่ยนlabelเป็นSlide/Poke/Shoulder การบล็อกบอลเด้งไม่สลับ; intentที่เริ่มแล้วไม่กลายเป็นอีกท่า |
| Staminaไม่พอ/CD/ช่วงจบท่าหรือrecovery | แสดงเหตุที่กดท่านั้นไม่ได้ แต่ไม่ปิดการเดิน/เล็ง/ยิงส่งที่ท่าทางอนุญาต |
| ลูกนิ่งจาก05 | แสดงaim/spin/timingoverlayตามกติกาลูกนิ่ง แล้วคืนHUD |
| reset/death/leave/เปลี่ยนgeneration | ยกเลิกpendinginput/track/overlayของรอบเก่าและคืนกล้อง |

ไม่มีDuelChoiceModal/ParryPromptOverlay/สโลว์เปิดดวล/คัตซีนล็อกคู่; ท่าร่างskillเป็นanimationระหว่างการเล่น ไม่บังคับกล้องคู่ต่อสู้หรือผู้ชม

## Phase2 — Lobby/Match/Meta

MainMenu → Lobbyผ่านNavigationDock → ModeSelect(3v3/4v4)/PreMatch → MatchHUD → PostMatch → Lobby; Locker/สุ่มตัวละคร/สุ่มสกิล/สุ่มเอฟเฟค/Collection/ตลาด/settingsผ่านrouterเดิม เปิดทีละหน้าตามscopeเจ้าของ ไม่แสดงสถานะplaceholderเป็นระบบพร้อมใช้

Serverตัดสินแมตช์/รางวัล/ownership/ผลสุ่มและsettingsที่กระทบเกม; UIรับsnapshot/ผลจริง รายละเอียดเรต/ราคา/profile/settingsและfirst-timepolishรอPhase2gate ไม่เปิดhandlerเหล่านี้ใน00หรือDemo
