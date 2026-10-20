# 02-player-actions — บอล การเคลื่อนที่ และปุ่มตามทีม

- **State:** SCOPE_CONFIRMED / IMPLEMENTATION_PENDING; [สถานะงาน](tasks.md)
- Owner Stang; Planner/Reviewer Codex; Implementerยังไม่มอบหมาย
- Design approval Q22 เมื่อ2026-10-20; ไม่มีimplementationapprovalใหม่; localcommitเอกสารตามคำสั่งล่าสุดในagent.md
- Planning HEAD f8729cc6e714f10a1cb60253a4f037d7c49f7505 + dirty files; ก่อนลงมือต้องpreflightใหม่ ปกป้องsource/เอกสารค้างและงาน00
- Prerequisite [01-cage-physics](../01-cage-physics/plan.md); [Phase1](../plan.md) / [Spec02](../../../specs/spec-02-duel-and-parry.md) / [Architecture](../../../design/architecture-and-network.md#6-continuous-football--q22)

## Scope/เจ้าของ

- บอลจริง/การเลี้ยง/ครอง/ปล่อย/รับ/deflect และทีมที่ครองสำเร็จล่าสุดเป็นข้อมูลคนละส่วน BallServiceเป็นsingle writerของบอล
- เดิน/Sprint/Dash/Stamina/Shift Lockคงไว้; กระโดดล็อกทิศเคลื่อนตัวก่อนขึ้น เปลี่ยนกลางอากาศไม่ได้ รองรับHeader/Volley/Blockตามcontactจริง
- ยิงตรง/ยิงโค้งปุ่มออกลูกแยก/ส่งเรียดและโด่ง/เล็ง3D/ชาร์จระหว่างเคลื่อนที่หรือกลางอากาศได้ตามscopeเดิม โดยชาร์จแล้วเคลื่อนช้าลง
- ทีมครองล่าสุดใช้ยิง/ส่ง/ยิงโค้ง; อีกทีมใช้Slide/Poke/Shoulderใน03 ทั้งทีมคงปุ่มบุกตอนบอลอิสระหลังยิง/ส่ง/ชิ่ง สลับเฉพาะเมื่ออีกทีมครองสำเร็จ
- Phase1เล่นบอลจังหวะแรกได้ไม่ต้องจับครองก่อน แต่ต้องอยู่ในระยะสัมผัส/เงื่อนไขบอลจริง ปุ่มยิงของเพื่อนที่ไม่มีบอลไม่ทำให้ยิงจากระยะไกลได้
- รับบอลพื้นที่รับไหวเข้าpossessionได้ ลูกแรง/สูงโดนตัวเด้งอิสระ ไม่มีI-frameหรือการซ่อนhitboxระหว่างDash/Skill
- Staminaเป็นทรัพยากรร่วมให้03ใช้: ต้องจ่ายไหวก่อนออกท่าที่มีต้นทุน ล้ายังเดิน/ยิง/ส่ง/ยืนตัดบอลได้ แต่เลี้ยงแตะห่างขึ้น ไม่มีสุ่มบังคับเสียบอล
- เตรียมtraining fixtureระบุinitialball/ทีม/จุดเริ่ม/รีเซ็ตและinput/HUDขั้นต่ำให้ตรวจได้ ไม่รอfullUI08หรือเปิดMatchService

## Seam กับ03/04/05/06/08

- 03เรียกผ่านบอล/possession/contactและทรัพยากรร่วม02 ไม่เขียนผู้ครองบอล/คูณmovement statsซ้ำ
- 03เป็นเจ้าของSkill5ท่า/เกมรับ/CD/recovery ไม่เปิดChoice serviceหรือFeintเดิมใน02
- โกล04ใช้กติกาในเขตของตนต่อจากบอลนี้ ไม่เอากติกาผู้เล่นสนามไปแทนการรับมือของโกล
- 05ตัดสินฟาวล์/ลูกนิ่งตามcontactsที่ตรวจได้; 06overrideค่าจูนเฉพาะtestsession; 08แสดงcontextและสถานะจากServer
- Network/Types migrationต้องระบุexactcontract/allowlistในHANDOFFของแผนก่อนแก้ ไม่เปลี่ยน12definitions/gettersของ00ระหว่างเก็บงาน00

## Acceptance

- บอล/ผู้ครอง/ทีมโหมดบุกไม่ค้างเมื่อปล่อย/ชิ่ง/บล็อก/รับ/เปลี่ยนทีม/reset/death/leave
- inputเดิมไม่กลายเป็นสไลด์กลางคันเมื่อcontextสลับ Serverreject/cancelเมื่อเงื่อนไขไม่ครบ
- first-timeยิง/ส่งเล่นได้ทั้งบอลเข้าและบอลชิ่งจริง; blockersยังสัมผัสได้ ไม่มีการรับประกันเข้าประตูหรือauto-catchบอลแรง
- DirectionalJumpเปลี่ยนทิศกลางอากาศไม่ได้; Sprint/Dash/cost/exhaustionตรวจServerและแยกจากvisual
- ใช้source/hashปัจจุบันตรวจruntime ไม่ใช้เพียงsnapshot/JSsimulationรับรองผล; syncdocs/TDDแล้วส่งreview

## Deferred

[Phase2](../../phase-02-full-match-and-progression/plan.md)รับแอนิเมชันยิง/ส่งจังหวะแรกพร้อมเสียจังหวะเมื่อวืด ต้องเปิดimplementationplanก่อนทำ ไม่เป็นเกณฑ์Phase1; สุ่ม/Statsหลายตัว/ownership/ระบบตั้งค่าถาวรไม่อยู่02 งาน00ไม่ขยาย
