# Implementation Notes — MODULE 08: `08-integration-and-uat`

## Technical Decisions
- **End-to-End Match Loop (`MatchService.luau`):** ควบคุมลำดับเฟส `LOBBY` -> `PRE_MATCH` -> `IN_PROGRESS` -> `COMPLETED` โดยเชื่อม `EventManagerService.StepMatchClock` (หมุนเวียนอีเวนต์ทุก 90 วินาที), `BallService.StepBallPhysics`, `CagePhysicsService.CheckGoalScored` และคำนวณรางวัลหลังจบแมตช์ผ่าน `TraitAndThreadService.ComputePostMatchReward`
- **Unified Bootstrap (`init.server.luau` & `init.client.luau`):** เรียก `Network.Init()` ก่อนเริ่ม Services และ Controllers ทั้งหมด เพื่อให้ RemoteEvents และ RemoteFunctions ทั้ง 12 รายการพร้อมใช้งานเสมอ
