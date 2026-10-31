# งานต่อ 30/10/2026 — ถอดล็อคบอลและทำ smooth turn

สถานะปัจจุบัน: **READY_FOR_OWNER_PLAYTEST — 30/10/2026**. ความเร็วแก้ตาม Ownerล่าสุดแล้ว: ปุ่มเดียว32/เฉียง28.8/เลี้ยวลด28.8หรือ25.92นาน0.7วินาทีแล้วคืนsmooth ดู [sprint-speed-report-001.md](sprint-speed-report-001.md). Owner สั่งเริ่มต่อแล้ว; ทำ backup/ถอด runtimeล็อค/ใส่ smooth turnและความเร็วใหม่ พร้อมเก็บโค้ดเก่าเป็น commentตามคำสั่งเพิ่ม. รายละเอียดและหลักฐานล่าสุดที่ [smooth-turn-report-001.md](smooth-turn-report-001.md). ข้อความด้านล่างเก็บเป็นบันทึกขอบเขตและสถานะก่อนเริ่มงานเมื่อคืน ไม่ใช่สถานะปัจจุบัน. ยังรอ Ownerตรวจฟีลก่อน technicalละเอียด

## ข้อสรุปล่าสุดจาก Owner

1. ท่า run-tap ล่าสุดมองไม่เห็นความเปลี่ยนแปลงและยังไม่ผ่านการตรวจอนิเมชั่น
2. ยกเลิกระบบล็อคบอล/cut commitment ทั้งหมด รวมอนิเมชั่นล็อคบอล การบังคับจบท่าก่อนเปลี่ยนทิศ และคิวกระโดดที่ผูกกับ cut
3. เปลี่ยนเป็นหักเลี้ยวต่อเนื่องแบบ smooth มีช่วงตอบสนองสั้น ๆ ก่อนเปลี่ยนทิศ และเอน/โยกตัวตามทิศให้เห็น แต่เบากว่าเวอร์ชันก่อนและตอบสนองไวขึ้น ไม่กลับไปใช้ท่า cut เดิม
4. Owner เลือกให้ลดความเร็วสูงสุดทุกทิศเหลือ90%ของ32 = **28.8**. เฉพาะ W / WA / WD ถึงค่าสูงสุดใหม่นี้; A / D / S / SA / SD ต้องช้ากว่า
5. **25.92** สำหรับทิศข้าง/หลังเป็นค่าเริ่มจูนที่ Root เสนอ (90%ของ28.8) ไม่ใช่ค่าที่ Owner เลือกเจาะจง. เก็บเป็น config เพื่อจูนภายหลัง. ระยะหน่วง/มุมเอนยังไม่มีตัวเลขที่ Owner ยืนยัน
6. สำรองเวอร์ชันก่อนถอดล็อคไว้ที่ `C:/Users/Stang/OneDrive/Desktop/stang/cage-zero-dev` ก่อนเปลี่ยน source/scene
7. ให้ Owner ตรวจอนิเมชั่นก่อน แล้วค่อยตรวจทางเทคนิคละเอียด. รอบต่อไปเน้น syntax/build และการแสดงท่าที่ตรงคำขอ ไม่วนชุดตรวจใหญ่ก่อน Owner รับฟีล

ข้อ2–4 แทนข้อตกลง grilling เดิมเรื่อง cut0.7s/บังคับจบท่า/จำทิศและกระโดด. ไม่ได้สั่งถอด G close-control, การรับ/เลี้ยงปกติ, การยิง, หรือล็อก yaw ตอนกระโดด; อย่าสับสนการล็อคบอลกับการหันตัวกลางอากาศ

## สถานะจริงตอนพัก

- คำสั่งล่าสุดยังอยู่ขั้นอ่านโค้ด/ชี้ขอบเขตและยืนยันความเร็วเท่านั้น **ยังไม่ได้แก้ source หรือ Studio ตามคำขอถอดล็อคนี้**
- **ยังไม่ได้สร้าง backup ที่ path ปลายทาง**. ต้องทำเป็นขั้นตอนแรกเมื่อเริ่มต่อ และตรวจว่าเปิดอ่านคืนได้ก่อนถอดระบบ
- Source ปัจจุบันยังมี cut/run-tap + commitment0.7s และ Sprint32. อย่ารายงานว่าถอดหรือเปลี่ยนเป็น28.8แล้ว
- รุ่นก่อนหน้าที่ส่งไว้: run-tap overlay บนท่าวิ่ง; ไม่มีบอลง้าง/เตะลมแบบ presentation-only ได้; ตรวจ syntax/module-load5/5 และ sync4client sourcesแล้ว แต่ Owner ไม่รับท่า cut ล่าสุด
- งานยิงที่มีอยู่: แรง54–128, ชาร์จเคลื่อนได้ที่ cap8, คลิปยิง22keys/0.56s ตัดท้ายหมุน; jump.md แยกบิน/ลงพื้นและลดแขนระดับเอว. ทั้งชุดยังรอ Owner ตรวจฟีลส่วนที่เปลี่ยน ไม่ถือว่าข้อ7/ข้อ9ผ่าน
- HEAD ที่อ่านตอนพัก: `290726b`; มี working tree dirty หลายไฟล์จากงานก่อนหน้า. ห้าม reset/ทับงานเก่า หรือ commit/push/publish อัตโนมัติ
- Last verified Studio: Cage-Zero placeId137721422246269, session `9341c8f1-6721-4781-965f-e1aa9de15881`. ต้อง refresh list_studios เมื่อกลับมา; ไม่ใช้ session เก่า1afd…ที่หมดอายุ. รอบพักนี้ไม่ได้เปลี่ยนโหมด/scene/Source ใน Studio

## ลำดับเริ่มต่อ

- [ ] รับคำสั่งเริ่มต่อจาก Owner แล้วอ่านโน้ตนี้กับ live board/checklist ล่าสุด
- [ ] สำรอง source/config/tests/เอกสารและ scene cut ที่เกี่ยวข้องไป path ที่ Owner ระบุ พร้อมรายการไฟล์/เวลา/hash หรือหลักฐานเปิดอ่านคืนได้. ห้ามอ้างว่า backupสำเร็จจากการมีโฟลเดอร์อย่างเดียว
- [ ] ไล่ references ถอด cut/lock ออกจาก client input, animation helper/controller และ server ball intents/guide ให้ครบ; ไม่เหลือปุ่ม/marker/remote เก่าที่ทำให้ล็อคกลับมา. เก็บประวัติ/รายงานและ backup ไม่ลบเหมา
- [ ] ทำ smooth steering ต่อเนื่อง + visual body lean ขนาดเล็ก ไม่มี cut clip หรือ animation completion gate
- [ ] ปรับ server/client/config ความเร็วให้ตรงกัน: forward group28.8, other groupต่ำกว่า. ค่าเริ่มเสนอ25.92ต้องระบุว่าเป็นค่าจูน
- [ ] คงการยิง/ชาร์จ8/เตะลม, G, jump/landing/air lean และบอลฟิสิกส์/การแย่งที่ไม่เกี่ยวข้อง
- [ ] ตรวจ syntax/build เฉพาะที่แก้, sync, ให้ Owner ลองภาพก่อน; หลัง Owner รับฟีลจึงตรวจพฤติกรรม/authority/regressionที่เกี่ยวข้อง
- [ ] อัปเดต checklist ตามผล Owner จริง ไม่ติ๊กผ่านจากผล implementer

## จุดโค้ดที่อ่านแล้ว

- `src/client/controllers/MovementHeadingPreviewController.luau`: cut detection/committed direction/queued jump/turn smoothing/speed dip
- `src/client/controllers/DribbleCutController.luau`: animation/visual hip-foot offsets/lock lifecycle
- `src/client/character/DribbleAnimationController.luau`, `DribbleAnimationHelper.luau`, `DribbleClipData.luau`: cut override, warmup/markers and clip definitions
- `src/server/services/BallService.luau`: cut intents, marker validation, ball guide, cancellation and remote dispatch
- `src/client/controllers/SprintController.luau`, `src/server/services/SprintService.luau`, `src/shared/configs/SprintConfigs.luau`: directional sprint intent and authoritative speed
- `src/shared/DribbleCutTimeline.luau`, `src/shared/configs/DribbleActionConfigs.luau`: cut timing/bindings; retire from runtime only after reference check
- `src/client/controllers/ShotController.luau`: remove only dependency on retired cut; preserve shooting changes

เจ้าของตรวจรายการที่ [owner-checklist.md](owner-checklist.md); สถานะงานเดียวที่ [RF-02/tasks.md](../RF-02/tasks.md)
