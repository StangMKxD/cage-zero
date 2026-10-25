# Owner directive — ยกเลิกแผน R6 เดิมและเริ่ม Plan02/03 ใหม่บน R15

> **LATEST Owner choice:** ทุกคนใช้ทรงตัว **ROBLOX Boy แบบ R15 ขนาดเดียวกัน** โดยคงหน้า สีผิว เสื้อผ้า หมวก/เครื่องประดับของผู้เล่นเท่าที่เข้ากันได้. แทนแนวคิด Roblox2.0 และการใช้ body package ต่างกันรายคน. รายละเอียดงานใน [R15 contract](r15-player-and-ball-HANDOFF.md). บอลคง previewล่าสุดเส้นผ่านศูนย์กลาง2.25;ยังไม่ออกแบบIdleใหม่.

## Latest Owner override — Player Avatar R15, equal size

Owner specifies: ใช้โมเดล Avatar ของผู้เล่นเป็น R15 แต่ทุกคนมีขนาดเท่ากัน. This supersedes Custom Blocky R15 as the required visual model in this directive and Release-First target docs. Preserve player identity/appearance where compatible with the standardized gameplay body; no requirement to use a game-owned blocky character instead.

The implementation plan must normalize body dimensions/proportions and gameplay collision/contact geometry across players. Equal scale numbers alone are not evidence of equal dimensions for arbitrary avatar body packages. Audit avatar loading/respawn, body-package normalization, attachments/animation compatibility, accessory collision and team readability. The choice of permitted visual body parts/accessories and exact dimensions remains a design detail to specify; do not silently promise arbitrary packages retain their original shape while sharing identical geometry.

Stats/character-card selection must not change physical size in the Release-First target; legacy archetype scale presets are historical references. No source/Studio changes or implementation authority granted by this documentation decision. Previous Custom Blocky wording below is superseded for target appearance only; R15 restart/cancellation/preservation gates remain.

Date: 2026-10-25 · Authority: Owner Stang directly instructs Codex to arrange documentation.

คำสั่ง: ยกเลิก `02-player-actions` และ `03-dribble-duel` เดิม แล้วเริ่มแผนใหม่บน **Custom Blocky R15** ตาม Release-First ไม่ใช่ยกเลิก Phase2/Phase3 ทั้งหมด

## สถานะและขอบเขต

- Legacy02/03: **CANCELLED_BY_OWNER / SUPERSEDED_FOR_R15_RESTART**. ยุติ task queue และอำนาจดำเนินงาน R6 เดิม ไม่ใช่ APPROVED/PASS/CLOSED หรือผลงานตรวจรับแล้ว
- ทุกสถานะ active/resume/pending implementation ในเนื้อหา legacy02/03 ด้านล่าง banner เป็นประวัติ ถูกแทนที่ด้วยคำสั่งนี้
- เก็บ source, assets, animation-library, HANDOFF, review/fix reports และผลทดลองเดิมครบ ไม่ลบ/ย้อน Git ไม่เปลี่ยน finding ค้างเป็นผ่าน
- Plan00/01 ไม่ถูกปิด ไม่เปิดรอบแก้ runtime เดิมโดยอัตโนมัติ; dependency ที่กระทบ R15 ต้องระบุในแผนใหม่และรอสิทธิ์ลงมือ
- รอบนี้อนุญาต **จัดทำ/ปรับเอกสารเท่านั้น** ยังไม่อนุมัติเปลี่ยน Rig/โค้ด/Studio/ทดสอบแอป/commit/push/merge/publish

## แผนใหม่

1. **RF-02 Core Football & R15 Foundation** — เริ่มออกแบบจาก R15: rig/root/joints/attachments, animation/controller, camera/input, ball contact/possession/network, locomotion/jump/air lean, shooting/passing/curve/first-time/whiff, basic defense, profile/config foundation ตาม Release-First. ตรวจ legacy implementation เป็นข้อมูล reuse candidate เท่านั้น ต้องพิสูจน์ความเข้ากันได้ใหม่ ไม่ port อัตโนมัติและไม่เขียนทุกระบบทิ้งใหม่โดยไม่มีเหตุผล
2. **RF-03 R15 Skill Moves & Defense** — แผนใหม่สำหรับ Heavy Knock-On, Open Up Fake Shot, Body Feint และสามช่องติดตั้ง; R15 choreography/contact synchronization, stamina/recovery/counterplay/whiff/visual UAT. อีกสี่ท่าเก็บเป็น future catalog และ reference assets
3. RF04–07 เดินตาม Release-First หลัง dependency ของแผนใหม่พร้อม โดยไม่อ้างว่าผล R6 คือหลักฐานผ่าน R15

แต่ละแผนต้องแยก AS-IS / TARGET / DELTA / ACCEPTANCE มี migration/rollback strategy และ Owner visual acceptance. Animation R6 ใช้อ้างอิง timing/choreography ได้ แต่ไม่ถือเป็น R15-ready clips. คงค่าบอลเดิมก่อนจูนใหม่และไม่เพิ่ม scope นอกไฟล์ Owner

## Ownership

Codex เขียน directive นี้และ cancellation banners บน legacy02/03 plan/tasks/notes. agyplan เขียน release-first plans และ sync global pointers ตาม primary HANDOFF; งดแก้หกไฟล์ legacy ที่ Codex ครอบครองในรอบนี้. Controller ไม่ monitoring. Original primary assignment remains docs-only, with this directive superseding its continuation wording for02/03.
