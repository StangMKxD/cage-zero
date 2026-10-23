# Review 005 — partial live moving-jump test / resume 2026-10-23

- **Verdict: CHANGES_REQUESTED / F-15 and F-28 remain OPEN.** พบอาการผิดปกติใน real keyboard moving-jump แต่ยังไม่พิสูจน์ root cause หรือรับรองทั้งแผน
- Actual tested ref: HEAD `e38e2f489fca522dbf0d12ea73894f2332e0118d` + dirty working tree ของวันที่22; live-source SHA parity ยังไม่ยืนยัน. ขณะ resume วันที่23 HEADยังเดิมแต่ต้องตรวจ hashes ใหม่
- Owner อนุญาตให้ Codex ทดสอบ MCP โดยตรงเฉพาะเรื่องกระโดด; ไม่มีการแก้ application source โดย Codex. สถานะ Plan02 ยัง OPEN; Plan03 ได้รับคำสั่งให้ทำต่อ; Plan04ถูกพักภายหลังและยังพัก
- Target ที่ทดสอบ: Studio `cfc72f6f-7ad7-476d-b821-0b815063d6f6`, Place137721422246269, Client Play; session/IDนี้เป็นประวัติ ต้อง discover ใหม่ก่อนใช้อีก
- Evidence: [codex-moving-jump-partial-20261022.json](evidence/codex-moving-jump-partial-20261022.json) ถอดตัวเลขจาก MCP result จริงก่อนพัก ไม่ใช่ simulation และไม่ใช่ raw full-frame capture ที่ยังเก็บอยู่

## F-15 — P1 / OPEN: actual moving jump loses upward velocity early

Reproที่ได้ข้อมูลจริง: W200ms → Space100ms → ปล่อยSpace → รอ900ms → ปล่อยW. เก็บเริ่มเมื่อเกิดSpace/Jumpingจริง ได้210Heartbeat samples. Root Y3.090ขึ้นสูงสุด5.539 (เพิ่ม2.449stud). ที่t=.05052s VYเปลี่ยน70.5975→-4.0875ในช่วงdt=.01692s; residualหลังชดเชยgravity≈-71.4556stud/s. Landedที่t=.31623s. maxHeartbeatdt≈.01998s จึงไม่ใช่เพียงช่วงเก็บข้อมูลขาดยาวในtraceนี้

นี่เป็นหลักฐาน velocity ถูกเปลี่ยนหรือชนบางสิ่งระหว่างflight ไม่ใช่หลักฐานระบุwriterตัวใดแล้ว. ต้องตรวจ input/Humanoid/controller/server correction/contact/geometry และลำดับeventโดยใช้fixtureเดิม เทียบnativeSandbox ห้ามสรุปว่าdoubleimpulseเป็นrootcauseโดยไม่มีtrace

## F-28 — P1 / OPEN: client flight and replicated state disagree during anomaly

ในsampleที่VYตก: Client flight=`idle` แต่ replicated IsAirborne=`true`. Torso-relative-Y stepสูงสุดในcaseเพียง.00306stud; ยังไม่มีหลักฐานว่าrootvisualoffsetเป็นสาเหตุหลักของcaseนี้. ต้อง trace state writers และ final pose/physics แยกกัน

## Coverage and cleanup

- WALK+SPACE: anomaly observed, cause UNRESOLVED; ไม่ใช่ functional pass
- SPRINT+SPACE: INCONCLUSIVE เพราะprobeหมดอายุก่อนinput; ต้องทดสอบซ้ำ ไม่ใช้sampleCount0เป็นผลผ่านหรือผลว่าไม่กระโดด
- Stationary control/Sandbox comparison: NOT VERIFIED. ชุดแรกที่เริ่มจับเวลาตั้งแต่MCPrequestพลาดช่วงinput ไม่ใช้สรุปผล
- ก่อนpause Codex disconnect probes, ล้างtemporaryglobals และหยุดPlayที่Codexเปิดเองเพื่อคืนEdit. ไม่มีsourcefix/commit/push
- Ownerขอเปลี่ยนเฉพาะภาพท่า airborneCurve/Bicycle เป็นHeaderชั่วคราว รวมpredicted/resolved mapping และไม่เรียกflip/breakfall recovery; ไม่ใช่คำสั่งเปลี่ยน ballistics หรือ Header action ใหม่

## Resume handoff

ใช้HANDOFF02§11ตามคำสั่งresumeล่าสุด; AGYทำfocusedreproduction/rootcausefixและtemporaryHeadervisual แล้วส่งfix-006. ไม่สร้างรายงานแก้ซ้ำ ไม่แก้fix005ย้อนหลัง ไม่ปิดfindingsจากคำว่าRESOLVEDของimplementer
