# Owner delta — ถอด runtime ที่เพิ่มตั้งแต่ legacy Plan02

2026-10-25: Owner ต้องการนำ Animation/Gameplay เก่าที่ทำตั้งแต่ Plan02 ออกจากระบบสำหรับ R15 restart ไม่ใช่เพียงหยุดใช้แผนเดิม

## ขอบเขต

- รวม legacy Plan02 player actions และ Plan03 skill/defense ที่ต่อยอดมา: controllers, services, poses/clips/configs, input/HUD, remotes/types/constants, bootstrap registrations และ tests เฉพาะพฤติกรรมที่ถูกถอด
- ไฟล์ที่เกิดใหม่ใน02/03ถอดได้ทั้งไฟล์เมื่อไม่มี consumer ที่ต้องเก็บ ส่วนไฟล์ร่วมให้ถอดเฉพาะ hunk ที่ยืนยัน provenance/dependency แล้ว ห้ามลบไฟล์ร่วมทั้งไฟล์เพียงเพราะถูกแก้ใน02
- รักษา Plan00 rig/bootstrap foundation และ Plan01 cage geometry/ball collision/rebound ที่ยังจำเป็น การแก้ BallService/CagePhysicsService ต้องแยกของ01ออกจาก02ด้วย Git history และรายงาน ไม่ลบเหมารวม
- เก็บเอกสารเก่า reviews/fixes/animation references และ Git history เป็นประวัติ ห้ามลบ published assets/Studio objects/rollback snapshots อัตโนมัติ
- ถอด runtime registration/input/event connections พร้อม implementation ไม่เหลือ dead require/remotes หรือทดสอบที่อ้างโมดูลซึ่งถูกลบ

## งานก่อนลงมือ

RF02 ต้องมี cleanup task ก่อนสร้าง R15 gameplay ใหม่: สร้าง removal manifest แบบ READ-ONLY ระบุ path/symbol/hunk, originating commit/plan, consumers, KEEP/REMOVE/REPLACE/UNCERTAIN, reset baseline และ verification/rollback strategy. ใช้ actual history ไม่เดา baseline ก่อน02จากวันที่หรือชื่อไฟล์. HEAD ขณะรับคำสั่ง `25a67d5575e31034a5a08290873b9c401357d33a`; working treeมีงานเอกสาร อย่า reset/revertทั้งtree

Owner เลือกเป้าหมายถอดระบบแล้ว ไม่ต้องถามซ้ำว่าจะเก็บ gameplay R6หรือไม่. การลงมือใช้ approved RF02 cleanup contract ตาม gateโปรเจกต์; เอกสารนี้ไม่ใช่คำสั่งให้ Codexแก้ sourceเองหรืออนุมัติทดสอบ/ลบ Studio. ก่อน destructive execution ต้องมีรายการขอบเขตที่ตรวจสอบได้ ไม่ลบแบบเหมารวม

Default worker คือ agyanimation/3.8 Flash เมื่อยืนยัน pane identityแล้ว; Argonใช้เฉพาะ dependency ที่ซับซ้อนซึ่ง Flashชี้หลักฐานปัญหาได้. ไม่ monitoring
