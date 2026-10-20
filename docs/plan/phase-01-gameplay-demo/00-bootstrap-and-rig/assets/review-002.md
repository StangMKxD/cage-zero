# Review 002 — ข้อเสนอ Bootstrap และ Custom R15 ฉบับแก้

- วันที่: 2026-10-20 (Asia/Bangkok); Reviewer: Codex
- เป้าหมาย: re-review ข้อเสนอแผน ไม่ใช่ผลตรวจรับ implementation
- รายงาน: `C:\Users\Stang\Downloads\00_bootstrap_and_rig_audit_and_plan (1).md` (335 บรรทัด)
- SHA-256 รายงาน: `F9AABD4C670B2B3ACACD327A3107B58C3C646AFC562B08DAC13DB23FBACB866F`
- Ref ที่ตรวจจริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- ฐานก่อนรอบนี้: `.gitignore` แก้ค้างเดิม และ `assets/review-001.md` ยัง untracked; ไม่มี source diff
- Verdict: **CHANGES_REQUESTED — ยังไม่พร้อมเป็น implementation contract**
- Disposition: **ESCALATED สำหรับการวนแก้ข้อเสนอจาก archive** เพราะ F-01/F-03/F-05 ถูกตีกลับสองรอบตาม R02; หยุด automatic ping-pong ให้ Owner/Codex รับทราบและเติม live evidence ก่อน ไม่เปิดรอบแก้อัตโนมัติอีก
- ไม่เปลี่ยนสถานะในแผน/tasks ไม่แก้ source หรือ PRD/TDD/CONTEXT/spec ไม่รัน application tests, Play, commit หรือเขียน Studio

## ผลเทียบตาม Finding IDs เดิม

รหัสต่อไปนี้ยึด `review-001.md` ไม่ยึดตารางที่สลับความหมายในรายงานใหม่ คำว่าแก้ครบหมายถึงข้อความข้อเสนอเท่านั้น ไม่ใช่พิสูจน์ว่าโค้ดแก้แล้ว

| Finding เดิม | ผลตรวจรอบ 2 | หลักฐานในรายงานใหม่ |
| --- | --- | --- |
| F-01: rollback | PARTIAL / OPEN | 175–199, 212–236, 255–276: เปลี่ยนเป็น pre-step snapshot แล้ว แต่ reverse patch ยังเทียบ Git index และไม่มีตรวจการแก้แทรกก่อนเขียนทับ/ลบ |
| F-02: bootstrap dependency | RESOLVED IN PROPOSAL | 79–85, 178–187: ห้าม require ระบบอื่นและให้ client คงเฉพาะ Network; ระบุ client timeout/assert แล้ว ไม่เปิด source งานอื่น |
| F-03: rig/assets/Studio/scene contract | PARTIAL / OPEN | 89–121, 245–276: เพิ่ม paths/classes และการสร้าง instance แต่ยังล็อก animation IDs กับจุดเกิดก่อนอ่านฐานจริง, ไม่มีที่เก็บ template เดิมกลับ repo และยังไม่ bind Studio เป้าหมาย |
| F-04: scope cleanup | PARTIAL / OPEN | 71–75, 105, 179: รักษา contracts/meshes ดีขึ้น; แต่ AC-00-2 ที่ 309 เพิ่มข้อห้าม CharacterMesh ทั้งหมดซึ่งไม่เท่ากับ No Boots และไม่มี requirement รองรับ |
| F-05: evidence/verification | PARTIAL / OPEN | 20–62 แยก archive/live ชัดขึ้น แต่ 46 ยังใช้ Connection Leak เป็น CONFIRMED; 300–312 ตรวจเพียงตายครั้งเดียวและ Y>=0 ไม่พิสูจน์การตกฉาก/เกิดซ้ำ/scale drift/visual readiness |

## Findings เดิมที่ยังต้องแก้

### F-01 [P1] Snapshot ดีขึ้น แต่ reverse patch และ restore ยังไม่จำกัด delta อย่างปลอดภัย

- หลักฐาน: บรรทัด 188/225 ใช้ `git diff -- <files>` ซึ่งเทียบ working tree กับ index ไม่ใช่ pre-step snapshot; บรรทัด 199/236 ยอมให้คัดลอกไฟล์ทับทั้งไฟล์; 276 คืน Source และลบ created instances โดยไม่ตรวจว่ามีการแก้แทรกหรือมีลูกของผู้อื่นเพิ่มหรือไม่
- ผลกระทบ: หากไฟล์เป้าหมายมี unstaged delta เดิม patch จะรวมงานนั้นด้วย การ apply ย้อนกลับจึงอาจย้อนงานเดิม; snapshot copy อาจทับงานที่เพิ่มหลังจบขั้น ส่วน parent ที่สร้างใหม่อาจมีลูกที่ไม่ได้เป็นของขั้นนี้เมื่อถึง rollback
- ต้องแก้: ใช้ pre-step → post-step diff จริง, manifest แยก run/step ที่ไม่ชนกัน และตรวจ current identity/hash/properties ก่อนคืน/ลบ เมื่อมีการแก้แทรกให้หยุด ไม่อ้างว่าสำเนาทั้งไฟล์หรือ patch จาก Git index คืนเฉพาะ delta ได้ทุกกรณี

### F-03 [P1] ล็อกค่าทดแทนช่องว่างหลักฐานแทนการเลือกจากฐานจริง

- หลักฐาน: 102–121 ล็อก animation IDs ห้าตัวและ Y=-5 / CFrame(0,5,0) ก่อนขั้น 1; 119–120/223/232 กำหนดจุดเกิดจากพิกัดทั่วไป; 301/312 ใช้ Y>=0 เป็นหลักฐานว่าปลอดภัย ส่วน 146–147 ตรวจข้อมูล Studio แต่ stop conditions ที่ 158 ไม่หยุดเมื่อ instance เดียวเป็น target ที่ยังยืนยันไม่ได้
- ต้องแก้: เก็บเป้าหมาย Studio, floor/spawn bounds, rig/template และ animation provenance ก่อนล็อก design ตัวเลขใน baseline เป็น candidate ไม่ใช่ค่าปลอดภัยที่ตรวจแล้ว เกณฑ์เกิดต้องอ้างพื้นที่รองรับจริง ไม่ใช่แกน Y เพียงอย่างเดียว
- Paths/classes และ create-missing flow ดีขึ้น แต่ write allowlist ที่ 245 ระบุ Source-only ขัดกับการสร้าง parents ที่ 260 ต้องแยก create/update/property changes ให้ชัด; บันทึก properties ที่เปลี่ยนและวิธีรับมือ class/path ชนกัน
- หากใช้ Studio template ต้องกำหนดวิธีเก็บ reference/asset ที่จำเป็นใน repo และวิธีได้ template เดิมคืนเมื่อเริ่มจาก place ใหม่; หากไม่พบ asset ที่ผ่านเกณฑ์ให้เสนอทางเลือกเป็น PENDING ไม่ล็อก fallback เป็นข้อสรุปแทน Owner

### F-04 [P2] ยังมี acceptance ที่เพิ่มข้อห้ามลักษณะโมเดลเกิน No Boots

- หลักฐาน: 309 เพิ่ม `ไม่มี CharacterMesh`; แต่ `docs/specs/spec-03-cards-rig-freekick.md:3-10` กำหนด Custom R15/สัดส่วน/หน้าอนิเมะ และข้อกำหนด No Boots ไม่ได้ห้ามทุก CharacterMesh
- ต้องแก้: รักษา mesh/เสื้อผ้าที่สอดคล้องกับ rig เดิม ตรวจชิ้นรองเท้าและความเข้ากันของ skeleton จากของจริง หากจะเพิ่มข้อห้าม class ต้องมีเหตุผลและ scope decision แยก ห้ามให้ acceptance ใหม่บังคับ AGY ลบของเดิมโดยอ้อม

### F-05 [P2] ยังปะปน static fact กับผล runtime และยังไม่มีกรณีตรวจตามความเสี่ยงเดิมครบ

- หลักฐาน: 46 ตั้งหัวข้อ Connection Leak เป็น CONFIRMED_FROM_ARCHIVE; 298–312 ยังมีเพียง track IsPlaying และตายครั้งเดียว ไม่มีเส้นทางตกฉากจริง/เกิดซ้ำ/สลับ scale ไป–กลับ/delayed respawn ของ character เก่า/การโหลดและแสดงผล animation จริง
- ต้องแก้: ยืนยันเพียงพบการเก็บ connection reference เพิ่ม ไม่อ้าง active leak ที่ยังไม่ reproduce; บันทึกผล live ของ Codex ใน review-001 เป็นข้อมูลจากผู้ตรวจรอบก่อนแยกจาก session ของ Gemini พร้อมระบุว่าต้องตรวจซ้ำก่อนใช้ ไม่ลบหลักฐานนั้นหรืออ้างว่าเป็นผลรันของตน
- เพิ่มวิธีตรวจแบบจำกัดและมี timeout สำหรับประเด็นเดิม สังเกต/วัด movement และ pose จริงแยกจาก Attributes/IsPlaying ไม่บังคับ screenshot/video; visual verification ที่ขาดต้องระบุ incomplete

## Findings ใหม่

### F-06 [P2] ตารางตอบแก้ไขเปลี่ยนความหมาย Finding IDs ทำให้ตรวจย้อนกลับผิด

- หลักฐาน: 12 ระบุ F-01 เป็นการแยกหลักฐาน แต่เดิม F-01 คือ rollback; 13 เปลี่ยน F-02 เป็น rollback ทั้งที่เดิมเป็น bootstrap; 16 เปลี่ยน F-05 เป็น scope แทน evidence/verification
- ต้องแก้: คงความหมาย F-01–F-05 ตาม review-001 พร้อมตำแหน่งที่แก้จริง ใช้ F-06 เป็นต้นไปสำหรับข้อใหม่ ห้ามสร้างตารางที่ดูเหมือนปิดข้อเดิมโดยตอบคนละประเด็น

### F-07 [P1] แผนโหลด Animation ใน Build ก่อน Animator อยู่ใน Workspace

- หลักฐาน: 214–221 เสนอ `setupBasicR15Animations` และ `Animator:LoadAnimation()` ภายใน `BuildStandardCustomR15Rig`; source จริง `src/server/services/RigAndCardService.luau:352` เรียก Build ก่อน `customRig.Parent = Workspace` ที่ 375
- ผลกระทบ: เมื่อทำตามลำดับที่เขียนใน procedural path Animator ยังไม่อยู่ใน Workspace จึงเสี่ยง error ก่อนสร้าง character เสร็จ เป็นข้อผิดพลาดของลำดับในข้อเสนอ ยังไม่ได้รันเพื่อยืนยัน error รอบนี้
- เอกสาร Roblox ระบุว่า Animator ต้องอยู่ใน Workspace ก่อนเรียก LoadAnimation: [Animator:LoadAnimation](https://create.roblox.com/docs/reference/engine/classes/Animator#LoadAnimation); ตรวจคำอธิบายจาก [Roblox creator-docs source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/Animator.yaml#L182) ด้วย
- ต้องแก้: แยกการสร้าง rig ออกจากขั้นเริ่มเล่น animation หลัง parent/character พร้อม ระบุ owner ของ tracks/สัญญาณ/cleanup และไม่เปิด controller แข่งกับ Animate ที่ถูกใส่ภายหลัง ตรวจ client/server replication ด้วยหลักฐานใน phase ที่ได้รับสิทธิ์

### F-08 [P2] เกณฑ์คอและ movement probe อาจตัดสิน rig ที่ทำงานถูกต้องว่าผิด

- หลักฐาน: 296/310 บังคับส่วนต่าง World-Y ของศูนย์กลาง Head/UpperTorso เท่าครึ่งผลรวมความสูงคลาดเคลื่อน 0.01; 298/311 ใช้ Humanoid:Move ครั้งเดียวโดยไม่กำหนด DataModel/client/server ownership หรือช่วงควบคุม input
- ผลกระทบ: สูตรคอนั้นรองรับ procedural rest pose เฉพาะแบบ ไม่ครอบคลุม template ที่มี offsets/rotation หรือท่า idle ที่ขยับคอ; ระยะศูนย์กลางไม่ใช่หลักฐานความต่อเนื่องของ joint โดยทั่วไป ส่วน Move อาจถูก default controls ทับ หรือไม่ทำงานตามคาดเมื่อสั่งคนละฝั่ง
- ต้องแก้: แยก rest-pose scaling/joint correctness จาก animated pose ตาม template ที่เลือก ตรวจ joint frames/scale ไม่สะสม แล้วตรวจภาพขณะเคลื่อนไหวแยก; ใช้ input/client probe ที่สอดคล้องกับ ownership และกำหนดช่วงสังเกต/cleanup ชัด
- แหล่ง API: [Humanoid:Move](https://create.roblox.com/docs/reference/engine/classes/Humanoid#Move) ระบุข้อจำกัด default controls และ server ownership

### F-09 [P1] ตีความห้ามแก้เอกสารในรอบเสนอเป็นตัด prerequisite ก่อน implementation

- หลักฐาน: 15/130 ตัดการ sync เอกสารและ HANDOFF ออกจากแผนทั้งหมด; 166 ให้เริ่มแก้ source หลังขั้น 1 และ implementation approval โดยไม่มีขั้นเตรียม/ตรวจ contract และ sync ข้อขัดแย้งเฉพาะแผน
- ขัดกับ `docs/plan/phase-01-gameplay-demo/00-bootstrap-and-rig/tasks.md:8-9` (P-02 ก่อน P-03), `plan.md:19`, และ `docs/design/architecture-and-network.md:55` ที่ต้อง sync เฉพาะส่วนที่ทำก่อน implementation รวมถึงหน้าที่เตรียม HANDOFF ตามกติกาผู้ใช้
- ต้องแก้: แยกสิทธิ์รอบนี้ซึ่งไม่แก้เอกสารหลัก ออกจากขั้นอนาคตหลังแผนได้รับความเห็นชอบที่ต้องเตรียม scope/spec delta และ HANDOFF ให้ตรวจได้ ไม่แก้ PRD/TDD/CONTEXT/spec แบบกว้าง ไม่ข้าม prerequisite โดยอ้างว่าถูกห้ามถาวร ระบุสิทธิ์ Git ว่าไม่มี local commit/push/merge/deploy ใน contract

## ขั้นถัดไปและ corrective prompt

หยุดวนแก้รายละเอียดจาก archive อย่างเดียว ข้อเสนอรอบนี้ยังไม่อนุญาต implementation และไม่อนุญาตการแก้เอกสารหลักเพิ่ม ขั้นถัดไปที่ทำได้ในขอบเขตเดิมคือ read-only inventory บน local repo/Studio เป้าหมาย โดยต้องระบุเป้าหมายได้ก่อนเติม target-specific evidence การเปิดงานแก้หลัง escalation ให้ Owner/Codex กำหนดจากฐานนี้ ไม่ dispatch หรือเรียก subagent อัตโนมัติ

ข้อความส่งต่อให้ AGY เมื่อ Owner เลือกเดินต่อ:

> อ่าน agent.md, docs/READ.md, แผน 00, accepted decisions และ assets/review-001.md กับ review-002.md ก่อน งานนี้ตรวจฐานแบบ read-only เท่านั้น: ยืนยัน Git/dirty files และ Studio instance/place ที่เป็น Cage Zero จริง ถ้ายังยืนยัน target ไม่ได้ให้หยุดเฉพาะ Studio จากนั้นสำรวจ rig/template/Animate/animation references, StarterCharacterScripts, floor/spawn และ enabled scripts ที่อาจรันชนกัน เทียบ source/path/class/hash ตามขอบเขตแผน 00 โดยไม่เขียนไฟล์หรือ DataModel ไม่เปิด/ปิด Play ไม่รันทดสอบ ไม่เรียก subagent ไม่ commit/push และไม่เปลี่ยน approval ส่งข้อเท็จจริงพร้อม path/ค่าที่อ่านได้และ UNKNOWN กลับให้ Codex ใช้ตัดสินใจแก้ข้อเสนอ F-01–F-09 ห้ามกำหนด asset IDs, spawn coordinates หรือเกณฑ์ตรวจใหม่จากการเดา งานนี้ไม่ใช่สิทธิ์ implement หรือแก้เอกสารหลัก
