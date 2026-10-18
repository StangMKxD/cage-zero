# Technical Notes — MODULE 01: `01-cage-physics`

- **BuildHexCageArena:** สร้าง `CageFloor`, `CageCeiling` (`Y = 32`), `HexWall_1..6` ($e = 0.88$), `PinballBumper_1..4` ($e = 1.25$), `ReboundMarker_1..6`, `Goal_North` (`Z = -106`) และ `Goal_South` (`Z = +106`) เว้นพื้นที่หลังโกล `14 Studs` และ `ElevatingRamp_Left/Right` เอียง `25 องศา`
- **Rebound & Zero Clipping:** `ComputeReboundVelocity` คำนวณ $\vec{R} = (\vec{V} - 2(\vec{V}\cdot\vec{N})\vec{N}) \times e$ พร้อมจำกัดความเร็วสูงสุด `180 Studs/s` และมี `StepBallCageCollision` ป้องกันลูกบอลทะลุกำแพง/เพดาน 100%
