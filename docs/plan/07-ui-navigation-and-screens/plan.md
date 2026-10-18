# MODULE 07: `07-ui-navigation-and-screens` (ระบบ UI ทั้งหมด การเชื่อมหน้าจอ Lobby, HUD & ร้านค้า)

## 1. เป้าหมาย (Objective)
สร้างระบบ UI ทั้งหมดและตัวจัดการเปลี่ยนหน้าจอ (`UIManager.luau`) ให้เชื่อมต่อกันครบทุกหน้าตามสเปกในส่วนที่ 4.7 ตั้งแต่นอกสนาม (Main Menu, Lobby Navigation, Mode Select, Locker, Summon, Trade Plaza) ไปจนถึงในสนาม (Pre-Match Position Select, Match HUD, Duel Choice Modal, Parry Prompt Overlay, Free Kick UI, Post-Match Summary)

## 2. เอกสารสเปกที่อ้างอิง (Referenced Specs)
- `docs/specs/spec-05-ui-navigation-and-hud.md`
- `docs/design/ui-state-and-routing.md`
- `docs/design/architecture-and-network.md`

## 3. ห้ามทำเกินขอบเขต (Out of Scope)
- ห้ามเขียนลอจิกคำนวณผลแพ้ชนะหรือคำนวณเงินไว้ในไฟล์ UI (ไฟล์ UI ทำหน้าที่แสดงผลและส่งคำสั่งผ่าน RemoteEvents เท่านั้น)

## 4. เกณฑ์ตรวจรับสำหรับ Codex (TDD Acceptance Criteria)
1. สามารถกดเชื่อมต่อไปยังทุกหน้าจอ (`MainMenu` -> `Lobby` -> `Locker` / `Summon` / `Trade` / `ModeSelect` -> `PreMatch` -> `MatchHUD` -> `PostMatch` -> `Lobby`) ได้ครบสมบูรณ์โดยไม่มีหน้าต่างค้างหรือซ้อนทับกัน
2. ใน `LockerScreen` สามารถกดสวมใส่การ์ด, สวมใส่ชุด `Battle Threads`, และใส่/ถอดหิน `Trait` แล้วข้อมูลอัปเดตตรงกับ Server ทันที
3. ใน `DuelChoiceModal` ปุ่ม `Snap Shot` จะถูกล็อกหากอยู่นอกระยะยิง และแสดงไอคอนแม่กุญแจเมื่อติดสถานะ `Mistake`
