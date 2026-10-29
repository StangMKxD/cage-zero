# Review036 — Dribble animation / walking + G / MCP technical review

2026-10-29 · Controller / Reviewer (Owner assigned this session) · **CHANGES_REQUESTED**

> **Owner follow-up 2026-10-29:** Owner ยืนยันว่าปรับระยะ G เอง; ถอน R036-02 จากรายการที่ต้องแก้ (เก็บผลวัดเดิมเป็นประวัติ). Owner ขอ sync disk version เพื่อลองเอง: disk controller เป็น uncommitted revision หลัง HEAD และ SHA256 `43772bf29ada1acceda8a1f97e958787a1e5163ee5beaaf78981608f467e02cb` ตรงกับ prepared sync manifest; ไม่อ้างว่า timestamp พิสูจน์ลำดับของ Studio revision. สำรอง Studio เดิมที่ `.sandbox/review036-before-owner-sync.luau` แล้ว sync **เฉพาะ DribbleAnimationController** ด้วย ScriptEditorService.UpdateSourceAsync พร้อมตรวจ unchanged-source guard และ independent exact readback 21,413 characters. R036-01 ด้าน parity ของไฟล์นี้แก้แล้ว; runtime observations ด้านล่างเป็นผลก่อน sync จึงยังไม่รับรอง behavior ของชุดใหม่. Studio คง Edit พร้อม Owner เริ่ม Play ใหม่ทดสอบ; ไม่แก้ game source บนดิสก์/ระยะบอล และไม่ commit/publish.

ตรวจรายงาน AGY `dribble-animation-integration-report-001.md` / `002.md`, integration HANDOFF, current working tree และ Studio จริง `Cage-Zero`, place `137721422246269` ผ่าน Roblox Studio MCP. Owner รับภาพอนิเมชันตอนวิ่งแล้ว; รายงานนี้ไม่แทนการรับภาพตอนเดิน/G ของ Owner และไม่เปลี่ยนสถานะงานอื่น.

## Findings

### R036-01 — High: ไฟล์ DribbleAnimationController บนดิสก์ไม่ใช่ชุดที่ Play ทดสอบ

- ตรวจเทียบ source หลัง normalize CRLF: **10/11 ตรงกัน**, ตัวที่ต่างคือ `src/client/character/DribbleAnimationController.luau`: disk 21,413 characters, Edit/Play 20,971 characters.
- Disk บรรทัด 230 คืนออกเมื่อ `not isMoving` ก่อนอ่าน goal mode. ดังนั้นเมื่อ G ยืนเฉย ๆ จะหยุด dribble loops; Studio บรรทัด 234 ใช้ `horizVel < 1.0 and not goalMode` จึงเล่น G loop ต่อได้จริง.
- Disk ใช้ getter `GetWalkDribbleTrack` / `GetRunDribbleTrack`; Studio ใช้ `GetWalkTrack` / `GetRunTrack`. ยังต่างด้าน cleanup/death hooks, playback speed และ ActiveDribbleClip ระหว่าง cut.
- Runtime ยืนยัน G ยืนมี GModeLoop 86 samples, velocity 0, speed 8 และ touch count 24→34. หลักฐานนี้รับรองได้เฉพาะ Studio version; ห้ามใช้เป็นหลักฐานว่า disk version ทำงานเหมือนกัน.
- ต้องให้ผู้รับผิดชอบเลือก source ที่ถูกต้อง รวม behavior ที่ต้องรักษา แล้ว sync/readback และทดสอบ fresh Play ซ้ำ. Reviewer ไม่เลือกทับ source ฝ่ายใดเอง.

### R036-02 — Medium: G ลดระยะกันบอลทะลุตัวต่ำกว่า geometry invariant เดิม

- `src/shared/configs/DribbleActionConfigs.luau:22` ตั้งระยะบอล G 1.95 และ minimum separation 1.85.
- Geometry เดิมคำนวณ clearance = body radius 1.25 + ball radius 1.125 + margin 0.05 = **2.425 studs** (`DribbleGeometryHelper.GetCarrierSeparationDistance`).
- Override ถูกส่งถึงทั้ง server target/velocity/final ResolveBodyCage และ client presentation; จึงยอมให้ผลลัพธ์ใกล้กว่า invariant เดิมจริง ไม่ใช่แก้เฉพาะภาพเท้า.
- Edit MCP pure-function reproduction ที่จุดกลางสนาม: G target/resolved horizontal distance **1.95** แม้ default clearance **2.425**. G ยืนใน Play วัดระยะบอลประมาณ 1.951–2.294.
- นี่คือการละเมิดขอบเขต cylinder/sphere ตามโมเดล collision ที่โค้ดประกาศ ไม่ใช่ข้อสรุปว่าภาพ mesh ทะลุกันทุกเฟรม. ต้องคืน invariant หรือส่งหลักฐาน geometry/ขอบเขตที่อนุญาตใหม่และการทดสอบ joint body+cage ก่อนอ้าง zero-clipping.

### R036-03 — Low: รายงาน AGY ยังไม่ครอบคลุมชุดส่งมอบล่าสุด

Report002 ระบุ walk/run/G loop 33 keys และ sprint cut lead 0.85; ชุด Edit ปัจจุบันมี 209/145/225 keys และ lead 0.90 พร้อม directional G อีก 4 clips ที่ไม่มีในรายงาน. รายงานกล่าวว่า G ตาม live travel direction แต่ BallService ปัจจุบันตั้งบอลด้านหน้า goal-facing แม้ถอยหลัง/strafe. ต้องปรับ report/manifest ให้ชี้ exact source และแยก Owner decisions ที่รองรับ delta นี้; ไม่อนุมานว่า delta ได้รับหรือไม่ได้รับอนุญาตจากการไม่มีข้อความในรายงานเพียงอย่างเดียว.

## ทดสอบจริงผ่าน MCP

ใช้ fresh Play, `user_keyboard_input`, อ่าน character attributes และ Animator tracks จริงด้วย telemetry 0.05s (4,342 samples รวมช่วง idle). ไม่มีการเรียก Init เพื่อทำให้ผลทดสอบผ่าน. ผลด้านล่างจำกัดเฉพาะ Studio version.

| กรณี | ผลที่ยืนยัน |
|---|---|
| เดิน W / WA ไม่กด Shift | WalkDribble length 1.04s, Movement priority; speed 16; ไม่เกิด cut และไม่เสีย carrier ในช่วงที่ทดสอบ |
| G+W / S / A / D | เรียก GoalForward / GoalBackward / GoalLeft / GoalRight ตรงทิศ; speed 8 ทั้งหมด; ไม่เกิด cut และไม่เสีย carrier |
| G+D+Shift | speed 8, peak horizontal velocity ประมาณ 8.000001; ไม่มี acceleration เป็น sprint |
| G ยืน | GModeLoop เล่น, speed 8, velocity 0, marker count เพิ่ม |
| G+W+S | velocity 0, GModeLoop คงอยู่, ไม่เกิด cut |
| G+W → S | เปลี่ยน forward→backward loop, ไม่เกิด cut, speed 8 |
| ปล่อย G ขณะกด Shift+S | คืน speed 32 และ RunDribble; reverse cut ทำงานหลังออก G; carrier คงอยู่ |
| Sprint W | RunDribble length 0.72s, speed 32; ไม่ใช้แทน Owner visual acceptance |
| W+Shift → Space+S | พบ Jump track และ carrier ถูกปล่อย; ยังไม่รับรอง air-yaw/4 lean ทั้งชุดเพราะรอบนี้ไม่ได้วัดมุม |

Touch attributes และ ServerDribbleTouchClip ยืนยัน marker path ของ G/run; ไม่อ้าง marker coverage ทุก clip จาก smoke รอบนี้. Module getters ที่เรียกผ่าน execute_luau ไม่ใช้ตัดสิน initialization เพราะค่า cache ใน execution context ต่างจาก LocalScript ที่กำลังรัน; ใช้ Animator/attributes จริงแทน.

## Checks / limits / handback

- `git diff --check`: exit 0 (มีคำเตือน LF/CRLF).
- `rojo build default.project.json -o .sandbox/review036-build.rbxlx`: exit 0. เป็น build gate ไม่ใช่ Luau typecheck/full regression.
- Exact source parity ตรวจ 11 ตัว: bootstrap, DribbleAnimationController/helper/data, R15AnimationController, DribblePresentationController, DribbleCutController, MovementHeadingPreviewController, DribbleGeometryHelper, DribbleActionConfigs, BallService; ต่างเฉพาะข้อ R036-01.
- Console มี asset `203785492` type mismatch 3 รายการ; ยังไม่พิสูจน์ว่าเกี่ยวกับ dribble และไม่พบ error ที่ชี้ตรงเข้า dribble จาก output ที่ได้.
- Heartbeat พบ ball CFrame เข้าใกล้ root ระหว่างเคลื่อนที่ แต่ยังไม่แยก pre-render replication ออกจากภาพสุดท้าย จึงไม่ใช้เป็นหลักฐาน rendered clipping. screen_capture ได้ภาพมืด มีเพียง Roblox UI จึง **visual walking/G NOT VERIFIED**.
- Multiplayer/latency, render-phase clearance, full death/respawn/menu/focus matrix, production asset permissions และ performance profiling: NOT RUN. PublishedIds ยังว่างและใช้ Studio fallback ตามขอบเขต handoff.
- รอบแรกมีการจัดตำแหน่ง fixture ชั่วคราว; หยุดแล้วเริ่ม fresh Play ใหม่ก่อน telemetry matrix ข้างต้น. คืน Studio เป็น **Edit** ยืนยันด้วย get_studio_state. ไม่แก้ game source/scene ถาวร, ไม่ sync, commit, push, publish หรือส่งคำสั่งข้าม pane.
- หลักฐาน local: `.sandbox/review036-summary.json`, `review036-runtime-sources.json`, `review036-live-DribbleAnimationController.luau`, `review036-edit-sources.json`, `review036-edit-snapshot.json` (ใช้ clips inventory เท่านั้น; sources ใน snapshot นี้ถูก MCP ย่อ จึงใช้ edit-sources ที่อ่านแยก batch สำหรับ parity).

**Handback:** CHANGES_REQUESTED ตาม R036-01/02; Owner visual running acceptance คงเดิม. ไม่ปิด task และไม่ dispatch แก้อัตโนมัติ.
