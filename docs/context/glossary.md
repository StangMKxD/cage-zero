> **CURRENT TARGET 2026-10-26 — Street Football:** [authoritative Phase1 plan](../plan/phase-01-gameplay-demo/release-first/plan.md) supersedes conflicting target/delivery statements below (retained as historical/reference). Phase1: R15/core ball + kick/slide/poke/block/normal body-check, separate CombatHP/stun/I-frame, gauge+ground/air Orbs, **RF04 walls BEFORE six Supers**, one-use timed armed Super/manual aim/no homing/no guaranteed goal, capped gauge-rate-only per-copy earnedCash upgrade,2v2/tiedGoldenGoal. Remove foul/free kick/cards/penalties/regular overtime/SuperMastery power scaling. Extra dribble skills/gacha/13stats/Traits/advanced aerial hold+guides/shops deferredPhase2; walls remainPhase1. Owner approved docs commit and checklist7 dribble/receive plus later explicit high momentumjump/four-way airlean and relevant locomotion fixes now; no blanket source implementation/commit/push/publish authority. Owner first6 visual accepted; technical review remains separate. Historical code/reviews/findings not erased.

# Project Glossary — นิยามคำศัพท์มาตรฐานของโปรเจกต์

| คำศัพท์ (Term) | คำจำกัดความและกฎการทำงาน (Definition & Rules) |
| :--- | :--- |
| **Single Custom Rig (Phase 1: R6)** | Rig มาตรฐานของเกม ไม่ใช้ avatar ส่วนตัว; Phase 1 ใช้ R6, PrimaryPart/Root เป็น HumanoidRootPart คง presets และใบหน้าอนิเมะ; Phase 2 ยังไม่กำหนดการย้าย rig |
| **Cage profile / Hex-Cage (legacy name)** | Aกล่อง4ผนัง; Bปาด4มุม8ผนัง; CฐานB+ขอบroof45° ผู้ใช้เลือกเทียบทดลองทั้ง3 ไม่มีข้อกำหนด6ด้านซ่อนอยู่ในB/C |
| **Pinball Bumpers** | แผงสะท้อนความยืดหยุ่นสูงบริเวณมุมกรง (`Restitution = 1.25`) สำหรับเตะชิ่งเปลี่ยนทิศทางความเร็วสูง |
| **360° Goal Zone** | พื้นที่ด้านหลังประตูที่ตั้งยื่นออกจากผนังหลัง `14 Studs` ให้เลี้ยงอ้อมหรือเตะชิ่งกำแพงหลังโกลได้ |
| **Elevating Ramps** | ทางลาดเอียง `25 องศา` บริเวณขอบสนามซ้าย-ขวา เมื่อเตะบอลผ่านจะได้รับแรงยกตัว (`Upward Impulse`) ลอยโด่งเข้ากลางสนาม |
| **Choice Duel (superseded)** | ระบบเลือกชอยส์/ชนะทาง/ล็อกคู่และคัตซีนแพ้ชนะถูกตัดตามQ22 ใช้ฟุตบอลต่อเนื่องแทน |
| **Shooting Zone (legacy)** | ไม่ใช้ล็อกยิงปกติ และไม่มี Snap Shot ในดวล ตาม N-10/N-12 |
| **Jump Block** | กระโดดบล็อกด้วยcontactจริง บอลแรง/สูงเด้งอิสระ ไม่ดูดเข้าครองทุกลูก |
| **Parry System (legacy)** | timed Parry นอกดวลถูกตัดตาม N-14; source/remote เดิมยังไม่ใช่สิทธิ์ให้เปิดใช้ |
| **Recovery** | หลังพลาดช้าลงและล็อกSkill/Dash/เข้าสกัดซ้ำ ยิงส่งเมื่อท่าเอื้อ; ไม่ใช่ลดเวลาChoice/สตั้นแพ้ดวล |
| **Player Cards / Skill Stars** | Tier/สัดส่วนและstatsไม่ใช่เพดานSkill Move1–5ดาว; Phase1ตัวเริ่มต้น5ดาว สุ่ม/ความต่างตัวละครอยู่Phase2 Signature Choice/จำนวนคัตซีนเก่าไม่ใช่กติกาปัจจุบัน |
| **Battle Threads** | อุปกรณ์สวมใส่ประเภทชุดแข่งแนวสตรีท/อนิเมะ (ไม่มีระบบรองเท้าสตั๊ด) มีช่องใส่หิน Trait (`Trait Slots`) 1–2 ช่องตามระดับความหายาก |
| **Trait (Soul Stone)** | ระบบไอเทมPhase2ที่ยังต้องgrillผลกับเกมเพลย์ใหม่ Traitยิง/ส่งที่ตัดและชนะChoiceอัตโนมัติไม่คืนจากspecเก่า |
| **Mutated Gear** | ชุด `Battle Threads` ที่ติดสถานะกลายพันธุ์ (เช่น `Golden Aura`, `Void Glitch`, `Blood Moon Flame`) ช่วยเพิ่มเอฟเฟกต์ VFX, มูลค่าการเทรด และบัฟคูณรางวัลหลังจบแมตช์ (`Cash Multiplier x1.5–x5`, `EXP Multiplier x1.5–x3`) โดยห้ามเพิ่มสเตตัสในสนามเด็ดขาด |
| **FC27 Free Kick Control** | ระบบยิงลูกนิ่งและฟรีคิก 3 ขั้นตอน: เล็งทิศทาง (`Aim Line`), เลือกจุดสัมผัสบอล (`Ball Spin Selector` สำหรับ Curve / Dipping / Knuckleball) และกดแถบจังหวะ 2 ครั้ง (`Timed Power & Accuracy Bar`) |
| **UIManager** | ตัวควบคุมหน้าจอหลักตัวเดียว (`src/client/ui/UIManager.luau`) ที่บริหารโหมด `LOBBY_MODE` และ `MATCH_MODE` ไม่ให้หน้าต่าง UI เปิดซ้อนทับกัน |
| **Ceiling Sweet-Spot Marker** | เป้าเรืองแสงช่วยเล็ง ไม่เปลี่ยนvelocityหรือรับรองlandingที่ตำแหน่งใด บอลสะท้อนตามnormalจริง |
| **Attack Context Team** | ทีมที่ครองบอลสำเร็จล่าสุด ทั้งทีมใช้ปุ่มบุกต่อเมื่อบอลอิสระ; block/ผนัง/เพดานไม่เปลี่ยนฝั่ง แยกจากคนครองบอลจริง |
| **Skill Move Loadout** | เลือก3ท่าจาก5ท่าทดลองฟรี จำกัดดาวตามตัวละคร คูลดาวน์แยกและช่วงจบท่าร่วม เปลี่ยนชุดก่อนรอบ/หยุดรีเซ็ตซ้อม |
| **First-Time Play** | ยิง/ส่งเมื่อสัมผัสบอลโดยไม่จับครองก่อน ใช้ได้Phase1; แอนิเมชันและเสียจังหวะเมื่อวืดเพิ่มPhase2 |
| **Debug Tuning** | ค่าoverrideเฉพาะtestsession/คืนdefaultและจัดDummyได้ ระบบตั้งค่าจริง/ค่าถาวรอยู่Phase2 |
