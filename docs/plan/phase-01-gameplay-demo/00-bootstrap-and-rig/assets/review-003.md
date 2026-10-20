# Evidence intake 003 — ตรวจฐาน sandbox ผ่าน Studio MCP

- วันที่: 2026-10-20 (Asia/Bangkok); ผู้ตรวจ: Codex
- ขอบเขต: อ่าน source/config/reference และ Edit DataModel เท่านั้น ไม่ตรวจรับ implementation และไม่เปิดรอบแก้ข้อเสนออัตโนมัติหลัง escalation
- Git ref จริง: `main @ 2f5f76b1687fc573d0c35c1ceeaabdda3ec8eb7c`
- ฐานก่อนรอบนี้: `.gitignore` แก้ค้างเพิ่ม `/sourcemap.json`; review-001/002 ยัง untracked; source หลักไม่มี diff
- Input ล่าสุด: `C:\Users\Stang\.codex\attachments\d9a0b22e-c99a-460c-b3c3-f7a4d1ba783f\Pasted text.txt` (SHA-256 `45133E1850A1367753767D8611AAC8B1F41720D6D29378AB614C3CE228384C12`)
- ผลรอบนี้: **ได้ live/static evidence เพิ่มสำหรับเตรียมแผน; implementation approval ยัง PENDING**
- เพิ่มเฉพาะรายงาน/ไฟล์ส่งต่อใน `.sandbox/exports/`; ไม่แก้ source หลัก, PRD/TDD/CONTEXT/spec/plan/tasks ไม่เขียน DataModel ไม่เปิด/ปิด Play ไม่ require โมดูลเกม ไม่รันทดสอบหรือ commit/push

## แก้การตีความเป้าหมายจากรอบก่อน

ผู้ใช้ชี้แจงว่า Place1 เป็นฐานใหม่ที่ยังไม่เริ่มทำ การไม่มี Custom Rig/source ในฐานนั้นเป็นสภาพเริ่มต้นที่ถูกต้อง ไม่ใช่บั๊กหรือเหตุให้หยุด bootstrap audit ส่วน sandbox ที่เปิดในรอบนี้ใช้เป็น reference สำหรับเลือกของเดิม ไม่ใช่ Studio เป้าหมายที่จะเขียน implementation โดยอัตโนมัติ

การไม่พบ template ทำให้ต้องออกแบบวิธีสร้าง rig ในแผน 00 ไม่ได้แปลว่าต้องให้ผู้ใช้สร้าง rig ก่อนจึงวางแผนได้ ข้อจำกัด runtime/visual ที่ยังไม่ได้ตรวจต้องคงแยกจาก static readiness

## Studio reference ที่อ่านจริง

- Studio listing: `sandboxcage-zero (placeId: 112091950831355)`; studio ID `081e9d76-5f04-46e8-8eab-f040651fa22e`
- Properties จริง: `game.Name = Place2`, `PlaceId = 112091950831355`, `GameId = 10771889046`; ยืนยันด้วย place ID ไม่ใช้ Name เพียงอย่างเดียว
- ก่อนตรวจ: Edit mode / available DataModel Edit; ตลอดงานใช้ Edit read-only
- `ServerStorage` มี `CageZeroDevelopment` ที่เป็นโมดูลทดลองเดิม ไม่ถือเป็น source หลัก
- ไม่พบ canonical mappings ทั้ง 7 จุดใน sandbox: `ReplicatedStorage.Shared.{Constants,Types,Network,configs.CardConfigs}`, `ServerScriptService.Server`, `ServerScriptService.Server.services.RigAndCardService`, `StarterPlayer.StarterPlayerScripts.Client`
- สอดคล้องกับสถาปัตยกรรมที่บอกว่า prototype กับ `src/` เป็น source คนละชุด ไม่ใช่ข้อผิดพลาดที่ต้อง sync ทับ sandbox

## Source comparison จาก Source จริง

อ่าน `.Source` ทั้ง 7 scripts ใน Studio ออกเป็น snapshot แยก แล้วคำนวณ SHA-256 ของ UTF-8 bytes หลังตรวจ byte length ครบทุกไฟล์ เทียบกับไฟล์เดิมใน local ทั้งสองชุด ผลและ hash เต็มอยู่ `source-comparison.json` ใน ZIP

| Script (path ใต้ FootballSandbox) | Studio bytes | ตรง `.sandbox/football-sandbox/` | ตรง historical reference |
| --- | ---: | --- | --- |
| server/ArenaBuilder.luau | 28494 | ตรง | ต่าง |
| server/DummyController.luau | 24287 | ตรง | ตรง |
| server/FootballServer.server.luau | 67900 | ตรง | ต่าง |
| shared/SandboxConfig.luau | 17494 | ตรง | ต่าง |
| shared/ShiftLockDribble.luau | 15141 | ตรง | ต่าง |
| shared/FootballVFX.luau | 47718 | ตรง | ตรง |
| client/FootballClient.client.luau | 109999 | ตรง | ต่าง |

- ปัจจุบันตรง local current reference **7/7**; ตรง historical reference **2/7**
- historical manifest ที่ `.sandbox/reference/football-sandbox/manifest.json` ยังตรงกับไฟล์ของตัวเอง 7/7 ไม่ควรแทนที่ manifest หรือทับ historical reference ด้วย source ใหม่
- local current reference มี `FootballVFXConfig.luau` เพิ่มจากชุด live ที่อ่าน ไม่มี script ชื่อนี้ใน Studio inventory จึงไม่ถือว่าทั้งโฟลเดอร์ current ตรง Studio ทุกไฟล์

## Rig และ animation ที่ยืนยันได้

- สแกน Workspace/ServerStorage/ReplicatedStorage/StarterPlayer ใน Edit ไม่พบ Humanoid หรือ Animation instance และไม่พบ `CageZeroStandardR15Rig`; `StarterCharacterScripts` ว่าง
- `Players.CharacterAutoLoads = true` ใน snapshot นี้ เป็น property ของ Edit baseline ไม่ใช่หลักฐานว่า custom spawn ผ่านแล้ว
- sandbox มีโค้ดสร้างหุ่น R15 ใน `server/DummyController.luau:97-110` แต่ไม่มี rig model ต้นแบบที่ตรวจรับแล้วใน Edit; ใช้เป็น reference ได้ ไม่รวมระบบหุ่นทั้งชุดเป็น scope แผน 00
- ไม่พบ literal `rbxassetid://` ใน sandbox scripts ทั้ง 7 live scripts หรือ 15 scripts ของ local reference สองชุด; ไม่พบไฟล์โมเดล `.rbxm/.rbxmx/.rbxl/.rbxlx` ในสองโฟลเดอร์ local ที่ตรวจ
- `shared/ShiftLockDribble.luau:285-303` มี API โหลด tracks จาก `animAssetIds` ที่ส่งเข้ามา แต่ค้น `CreateAnimationBlender(` ในทั้งสอง reference พบเพียงนิยาม ไม่มี call site ชื่อเดียวกัน จึงไม่ใช่ชุด locomotion animations ที่มี IDs พร้อม reuse
- มี procedural joint offsets ใน `server/FootballServer.server.luau:1595-1602` สำหรับท่าเลี้ยงบอล ใช้กับ movement/ball state เดิม ไม่เท่ากับ idle/walk/run/jump ของ Custom R15 ที่ผ่านแล้ว และส่วนเลี้ยงบอลเป็นแผนถัดไป
- `src/server/services/RigAndCardService.luau` ยังคงเป็น candidate หลักของการสร้าง/scale Custom R15 ตามแผนเดิม ต้องแก้ bootstrap/template/animation lifecycle ตาม review ไม่เริ่มจากการคัดลอก sandbox ทั้งเกม

## พื้น จุดเกิด และพฤติกรรมที่อาจชนกัน

- Edit snapshot มี `Workspace.FootballSandbox.SafePlayerSpawn` เปิดใช้งาน ที่ประมาณ `(1.687629, 0.1, 19.458717)` ขนาด `(6, 0.2, 6)`, Anchored=true, CanCollide=false
- `Workspace.SpawnLocation` เดิมอยู่ `(0,-30,0)` และ Enabled=false; Baseplate อยู่ `(0,-16,0)` และ CanCollide=false
- อ่าน geometry ด้วย raycast ที่กรองเฉพาะ Pitch: จุด `(0,5,0)` และเหนือ SafePlayerSpawn กระทบ GrassStripe บนผิว Y=0, CanCollide=true, Anchored=true; เป็นหลักฐานเฉพาะฉาก sandbox ใน Edit ไม่รับรอง safe spawn ในฐานใหม่
- ต้องกรอง geometry ที่ตรวจ: raycast แบบไม่กรองจาก `(0,5,0)` กระทบลูกบอลที่ Y≈2.2 ก่อนพื้น จึงไม่ควรถือ first hit ทุกชนิดเป็นพื้นปลอดภัย
- config ของ sandbox ระบุ `PLAYER_SPAWN_POS = (0,0.5,24)` (`shared/SandboxConfig.luau:24`) ต่างจากตำแหน่ง SpawnLocation ที่วางจริง; `FootballServer.server.luau:1138-1142` จะ teleport character ไป config บวก Y อีก 3 หลังเกิด ทั้งสองแหล่งต้องแยกกัน ไม่เลือกตัวเลขหนึ่งมารับรองฐานใหม่โดยอัตโนมัติ
- script `ServerScriptService.FootballSandbox.FootballServer` และ LocalScript `StarterPlayer.StarterPlayerScripts.FootballSandbox.FootballClient` มี Disabled=false; module อื่นไม่มีสถานะ auto-run แบบ Script
- source server เดิมแก้ WalkSpeed/Jump และย้าย character (`1098-1142`); client เดิมควบคุม camera/input การเปิด bootstrap ใหม่ใน sandbox เดียวกันจึงต้องมีแผนแยกฉาก/สคริปต์ก่อน แต่รอบนี้ไม่ disable/move/ลบอะไร

## ความพร้อมและสิ่งที่ยังไม่ยืนยัน

- ข้อมูลจาก Cloud report ถูกต้องตรงที่ session นั้นไม่มี local/MCP และไม่มี review files ใน archive เก่า รายงานนั้นไม่ใช่ผล live audit; review-001/002 เป็น untracked จึงไม่ติด `git archive` ที่ commit เดิม
- ถอนการล็อก animation IDs ที่ไม่มี provenance ในโค้ด เป็นการแก้สมมติฐานที่เหมาะสม แต่ยังไม่ปิด F-03/F-05 หรือข้อผิดลำดับ F-07
- ข้อความว่าไม่มีพื้นแล้วจะตายวนทุก 2 วินาทีเป็นการอนุมานจาก source ไม่ใช่ผล reproduce จริง ใน sandbox ที่เปิดรอบนี้มีพื้นอยู่แล้ว ส่วนฐานใหม่ต้องกำหนด fixture พื้นขั้นต่ำในข้อเสนอให้ชัด โดยไม่ดึงแผนสนามทั้งหมดมาทำ
- มีหลักฐานพอให้ร่างรายละเอียด bootstrap, ขอบเขต reuse และวิธีสร้าง rig จากฐานใหม่ต่อได้ โดยแยกการเลือก animation source/สิทธิ์ asset และวิธีเก็บ fixture/template กลับ repo เป็นเรื่องที่ต้องออกแบบ/ยืนยัน ห้ามเติมผล runtime แทนสิ่งที่ยังไม่ตรวจ
- ยังไม่ยืนยัน: movement, animation loading/replication, รูปลักษณ์ใบหน้า, scale ไป–กลับ, respawn/fall lifecycle และ visual acceptance; ไม่บังคับ screenshot/video
- Findings F-01/F-03–F-09 ยังต้องแก้ในข้อเสนอ; F-02 แก้ครบเฉพาะข้อความตาม review-002 ไม่มีการเปลี่ยนสถานะอนุมัติหรือปิดงานจาก evidence intake นี้

## ชุดส่งต่อ

ZIP: `.sandbox/exports/phase00-readonly-20261020-081e9d76.zip` รวม review-001/002/003, local evidence, metadata Studio, hash comparison, decoded source snapshot ทั้ง 7 จุด, และ reference ทั้งสองชุด พร้อม manifest ของไฟล์ในแพ็กเกจ ไม่มี `.git/`, credentials หรือผลรันเทสต์

ใช้ ZIP นี้ร่วมกับ Git archive เดิม `2f5f76b...` เมื่อส่งให้ Gemini Webargon ให้อ่านเอกสารจริงและคง Finding IDs เดิม แยก reference sandbox จากฐานใหม่ ไม่อ้างว่าต้องพบ rig ในฐานใหม่ก่อนวางแผน รอบถัดไปเป็นข้อเสนอเท่านั้น รอคำสั่ง Owner ก่อนปรับแผนหลัก/เตรียม implementation HANDOFF; ไม่มีสิทธิ์ implement, local commit, push, merge หรือ deploy จากรายงานนี้
