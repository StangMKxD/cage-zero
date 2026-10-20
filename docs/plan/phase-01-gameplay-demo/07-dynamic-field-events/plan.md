# 07-dynamic-field-events — อีเวนต์สนามทั้งสามแบบ

- **Phase:** 1; **State:** SCOPE_SELECTED / PLAN_DRAFT
- **Owner:** Stang; Planner: Codex; Implementer / Reviewer: ยังไม่มอบหมาย
- **Implementation approval:** PENDING; งานนี้ปรับโครงแผนและเอกสารเท่านั้น
- **Baseline:** main @ `6d0f273dc174f0c1460e9ed8ce98e5aa4261b182`; ไม่มีข้อมูล session/log เพิ่มเติม
- **ลำดับและ gate:** [phase plan](../plan.md); [roadmap](../../roadmap.md)
- **ข้อสรุปกติกา:** [accepted decisions](../01-cage-physics/notes.md)
- **Prerequisites:** [05-fouls-and-set-pieces](../05-fouls-and-set-pieces/plan.md), [06-training-ground](../06-training-ground/plan.md)

## Scope
- Pillar Lockdown, Blackout Void, Favela Alleyway พร้อม warning/collision/VFX/NPC sync
- ใช้เวลาและตัวควบคุมฉากฝึกสำหรับเปิด สลับ จบ และคืนสภาพ ไม่ต้องมี match clock 5 นาทีก่อน
- ไม่เพิ่มอีเวนต์ชนิดใหม่จากการปรับโครงแผน

## Acceptance / ก่อนลงมือ
- เสาเตือนก่อนเกิด/ชิ่งได้ Blackout ซ่อนภาพแต่ยังชนได้ และยังเห็นบอล/โกล/ผู้เล่น
- Favela NPC sync และชนบอล/ขวางทางได้ตาม spec; ตรวจผลกับ duel/โกล/ลูกนิ่งไม่ให้ state ค้าง
- วัดปัญหาประสิทธิภาพที่พบ ไม่รับรองว่าเฟรมไม่ตกโดยไม่มีหลักฐาน

อ่าน [architecture](../../../design/architecture-and-network.md) และ PRD/spec เดิมเพื่อทำ diff เฉพาะส่วนก่อนลงมือ ไม่ใช้เนื้อหา Parry/Choice ยิงส่งหรือสถานะปิดงานเก่าเป็นสิทธิ์ให้ทำของที่ถูกตัด/เลื่อน

รายงานใน assets/runs ที่ย้ายมาด้วยเป็นประวัติของ module baseline เดิม ชื่อ/หมายเลข/ข้อความอนุมัติในรายงานไม่ใช่ผลตรวจของแผนฉบับนี้ รายงาน card/UI/เศรษฐกิจเดิมอาจครอบหลายขอบเขตก่อนแยก phase ให้ใช้อ้างอิงประวัติเท่านั้น


## Rebound experiments เพิ่มตามคำสั่งผู้ใช้ 2026-10-20

เป็นรายการทดลองของอีเวนต์เดิมสามชนิด ไม่เพิ่ม event ชนิดที่สี่ และยังไม่ถือว่าทุกรูปแบบถูกเลือกเป็น final gameplay ต้องเทียบกับ map profiles A/B/C จากแผน 01 หลัง prerequisites 05/06 พร้อม

| Event | Trial ที่เพิ่ม | สิ่งที่ต้องวัดและขอบเขต |
| --- | --- | --- |
| **Pillar Lockdown** | ชุดเริ่มทดลอง 3 เสา; response e=1.0–1.15 เป็นช่วงจูน; แถบนีออนชิ่งต่ำ/สูงสองระดับและ cap เอียงบนเสา | วัดเส้นทาง one-two/roof→cap/เสาไกล, contact/seam/เกิดหรือหายเสา, warningและclearance; ไม่รับรองว่าโกลรับไม่ทันหรือบอลหักเข้าเสาไกลทุกครั้ง |
| **Blackout Void** | ซ่อนภาพ wall/roof แต่คง collider; แสงขอบกรง/ceiling markers/โกล/บอล/ผู้เล่น และ Neon Impact Ripple อายุทดลอง1s ณ contact | ripple เป็น visual จาก contact จริง ไม่มีแรงช่วย trajectory; ทุก geometry A/B/C ต้องยังชิ่งเหมือนก่อนดับไฟ ทดสอบ lifetime/cleanup/จำนวนeffectและการอ่านเกม ไม่อ้างว่าเฟรมไม่ตก |
| **Favela Alleyway** | เริ่มทดลอง NPC3คนภายใต้ capเดิม และป้ายสังกะสี/ถังแขวนสลิงที่แกว่งใต้เพดานหน้า goal | moving collider ต้องมี server-authoritative trajectory/เวลาและ surface velocity; แยก visualกับphysics ตรวจ swept contact/เพดาน/goal/GK/ผู้เล่น ไม่ใช้ static-plane reflection อ้างว่า swing physics ผ่าน |

- Phase 1 ใช้ controller ฉากฝึกเปิด/สลับ/จบ/restore; 90s interval และ40s duration เป็น default config ของ eventเดิม ไม่ดึง match clock5นาทีมาเป็น dependency
- เทียบ baselineไม่มีeventกับมีevent แล้วเปลี่ยนหนึ่ง trial feature ต่อรอบ ใช้ launch set/activeVariantId เดียวกับ01; สูตร/response/timing เป็นค่าจูน ไม่เพิ่ม aim assist หรือ markerแรงนำบอล
- หลัง event จบ/cancel/restart ให้คืน geometry/visibility/material/collision state และล้าง transient surfaces/connections/effects/NPC/props ของ eventนั้น ไม่ทิ้ง contact ซ้ำหรือทรัพย์สินค้าง
- รายละเอียด contact payload/activation/replication กับ collision owner ออกแบบใน07; แผน01เตรียม surface IDs/normals/catalogและdiagnosticsเท่านั้น ไม่เพิ่ม endpoint หรือสร้าง moving props ใน01
