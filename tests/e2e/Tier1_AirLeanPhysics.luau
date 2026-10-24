--!strict
-- tests/e2e/Tier1_AirLeanPhysics.luau
-- E2E Test Suite for Module 02: Airborne Body Lean & Deflection Physics
-- Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §12.5–12.6

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))
local AirLeanSolver = require(Shared:WaitForChild("AirLeanSolver"))
local AirLeanConfigs = require(Shared:WaitForChild("configs"):WaitForChild("AirLeanConfigs"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local BallService = require(Services:WaitForChild("BallService"))

local function runAirLeanPhysicsTests(TestHarness: any)
	local Describe = TestHarness.Describe
	local Test = TestHarness.Test
	local Expect = TestHarness.Expect

	local createdMocks: { [number]: Model } = {}

	local function cleanupAllMockPlayers()
		for uid, m in pairs(createdMocks) do
			pcall(function()
				BallService.SetPlayerCharacterOverride(uid, nil)
				if m and m.Parent then
					m:Destroy()
				end
			end)
		end
		table.clear(createdMocks)

		local folder = Workspace:FindFirstChild("__TestMocks")
		if folder then
			folder:Destroy()
		end

		local legacyNames = {
			"AirLeanPlayer1", "AirLeanPlayer2", "AirLeanPlayer3",
		}
		for _, name in ipairs(legacyNames) do
			local m = Workspace:FindFirstChild(name)
			if m and m:IsA("Model") then
				m:Destroy()
			end
		end
	end

	local function SafeTest(testName: string, testFn: () -> ())
		Test(testName, function()
			local ok, err = pcall(testFn)
			cleanupAllMockPlayers()
			if BallService.ClearAllPlayerStates then
				BallService.ClearAllPlayerStates()
			end
			BallService.ResetBall()
			if not ok then
				error(err)
			end
		end)
	end

	local function createMockAirPlayer(userId: number, name: string, pos: Vector3, look: Vector3): (any, Model, Part)
		local folder = Workspace:FindFirstChild("__TestMocks")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "__TestMocks"
			folder.Parent = Workspace
		end

		local model = Instance.new("Model")
		model.Name = name
		model.Parent = folder

		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.CFrame = CFrame.lookAt(pos, pos + look)
		root.Anchored = false
		root.CanCollide = true
		root.Parent = model
		model.PrimaryPart = root

		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 100
		hum.Health = 100
		hum.WalkSpeed = Constants.WALK_SPEED
		hum.Parent = model

		local mockPlayer = {
			UserId = userId,
			Name = name,
			Character = model,
			IsA = function(_self: any, className: string)
				return className == "Player"
			end,
		}

		BallService.SetPlayerCharacterOverride(userId, model)
		createdMocks[userId] = model
		return mockPlayer, model, root
	end

	Describe("Module 02: Airborne Body Lean Kinematics & Deflection Physics", function()

		-- TC-ALP-01: ClampLeanInput Unit Box and Diagonal Normalization
		SafeTest("TC-ALP-01_ClampLeanInputSanitizationAndDiagonalNormalization", function()
			-- 1. Neutral inputs
			local f0, r0 = AirLeanSolver.ClampLeanInput(0, 0)
			Expect(f0).toBe(0.0)
			Expect(r0).toBe(0.0)

			-- 2. Single axis maximums
			local f1, r1 = AirLeanSolver.ClampLeanInput(1.0, 0.0)
			Expect(f1).toBe(1.0)
			Expect(r1).toBe(0.0)

			local f2, r2 = AirLeanSolver.ClampLeanInput(0.0, -1.0)
			Expect(f2).toBe(0.0)
			Expect(r2).toBe(-1.0)

			-- 3. Diagonal inputs (W + D): must normalize magnitude to <= 1.0
			local fd, rd = AirLeanSolver.ClampLeanInput(1.0, 1.0)
			local diagMag = math.sqrt(fd * fd + rd * rd)
			Expect(diagMag).toBeLessThan(1.0001, "Diagonal lean input magnitude must be normalized to <= 1.0")
			Expect(math.abs(fd - (1.0 / math.sqrt(2.0)))).toBeLessThan(0.001)
			Expect(math.abs(rd - (1.0 / math.sqrt(2.0)))).toBeLessThan(0.001)

			-- 4. Extreme / out-of-range inputs
			local fe, re = AirLeanSolver.ClampLeanInput(5.0, -5.0)
			local extMag = math.sqrt(fe * fe + re * re)
			Expect(extMag).toBeLessThan(1.0001, "Extreme out-of-range inputs must be clamped to unit circle")

			-- 5. Non-finite values (NaN and Inf) sanitized to 0
			local fn, rn = AirLeanSolver.ClampLeanInput(0/0, math.huge)
			Expect(fn).toBe(0.0, "NaN forward input must sanitize to 0.0")
			Expect(rn).toBe(0.0, "Inf right input must sanitize to 0.0")

			-- 6. Nil inputs default safely to 0
			local fnil, rnil = AirLeanSolver.ClampLeanInput(nil, nil)
			Expect(fnil).toBe(0.0)
			Expect(rnil).toBe(0.0)
		end)

		-- TC-ALP-02: SlewLean Rate Limiting & Transition Clamping
		SafeTest("TC-ALP-02_SlewLeanRateLimiting", function()
			local maxSlew = AirLeanConfigs.MAX_SLEW_DEG_PER_SEC
			local maxPitch = AirLeanConfigs.MAX_PITCH_DEG
			local maxStepPerSec = maxSlew / maxPitch -- e.g. 120 / 20 = 6.0 units/s

			-- dt = 0.05s -> max step is 0.30 units
			local dt = 0.05
			local nextF, nextR = AirLeanSolver.SlewLean(0.0, 0.0, 1.0, 0.0, dt)
			local expectedStep = maxStepPerSec * dt
			Expect(math.abs(nextF - expectedStep)).toBeLessThan(0.001, "Slew step must match max slew rate")
			Expect(nextR).toBe(0.0)

			-- Reaching target smoothly without overshoot
			local closeF, _ = AirLeanSolver.SlewLean(0.95, 0.0, 1.0, 0.0, 0.1)
			Expect(closeF).toBe(1.0, "Slew must clamp exactly at target without overshoot")

			-- Negative slew
			local negF, _ = AirLeanSolver.SlewLean(0.0, 0.0, -1.0, 0.0, dt)
			Expect(math.abs(negF - (-expectedStep))).toBeLessThan(0.001, "Negative slew step must match negative max slew")
		end)

		-- TC-ALP-03: ComputeLeanAngles and ComputeLeanCFrame (Yaw Lock & World Tilt Invariant)
		SafeTest("TC-ALP-03_ComputeLeanAnglesAndCFrameYawLock", function()
			-- Neutral
			local p0, r0 = AirLeanSolver.ComputeLeanAngles(0, 0)
			Expect(p0).toBe(0.0)
			Expect(r0).toBe(0.0)
			local cf0 = AirLeanSolver.ComputeLeanCFrame(0, 0)
			Expect(cf0).toBe(CFrame.identity)

			-- Pure Forward Pitch (W)
			local pf, rf = AirLeanSolver.ComputeLeanAngles(1.0, 0.0)
			Expect(math.abs(pf - math.rad(AirLeanConfigs.MAX_PITCH_DEG))).toBeLessThan(0.001)
			Expect(rf).toBe(0.0)
			local cfFwd = AirLeanSolver.ComputeLeanCFrame(1.0, 0.0)
			local _, ryFwd, _ = cfFwd:ToEulerAnglesXYZ()
			Expect(math.abs(ryFwd)).toBeLessThan(1e-5, "Pitch forward must not introduce yaw rotation")

			-- R6 World Torso Tilt Invariant (F-33): W tilts Torso.Up forward into -Z; S tilts Torso.Up backward into +Z
			local stdR6 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0)
			local torsoUpFwd = (cfFwd * stdR6 * stdR6:Inverse()).UpVector
			Expect(torsoUpFwd.Z).toBeLessThan(-0.01, "W (+forward) must tilt Torso.Up forward into -Z relative to locked facing (F-33)")

			local cfBack = AirLeanSolver.ComputeLeanCFrame(-1.0, 0.0)
			local torsoUpBack = (cfBack * stdR6 * stdR6:Inverse()).UpVector
			Expect(torsoUpBack.Z).toBeGreaterThan(0.01, "S (-backward) must tilt Torso.Up backward into +Z relative to locked facing (F-33)")

			-- Pure Right Roll (D): D tilts Torso.Up right into +X; A tilts Torso.Up left into -X
			local pr, rr = AirLeanSolver.ComputeLeanAngles(0.0, 1.0)
			Expect(pr).toBe(0.0)
			Expect(math.abs(rr - math.rad(AirLeanConfigs.MAX_ROLL_DEG))).toBeLessThan(0.001)
			local cfRgt = AirLeanSolver.ComputeLeanCFrame(0.0, 1.0)
			local _, ryRgt, _ = cfRgt:ToEulerAnglesXYZ()
			Expect(math.abs(ryRgt)).toBeLessThan(1e-5, "Roll right must not introduce yaw rotation")

			local torsoUpRight = (cfRgt * stdR6 * stdR6:Inverse()).UpVector
			Expect(torsoUpRight.X).toBeGreaterThan(0.01, "D (+right) must tilt Torso.Up right into +X relative to locked facing")

			local cfLeft = AirLeanSolver.ComputeLeanCFrame(0.0, -1.0)
			local torsoUpLeft = (cfLeft * stdR6 * stdR6:Inverse()).UpVector
			Expect(torsoUpLeft.X).toBeLessThan(-0.01, "A (-left) must tilt Torso.Up left into -X relative to locked facing")
		end)

		-- TC-ALP-04: Neutral Air Shot Trajectory Preservation
		SafeTest("TC-ALP-04_NeutralAirShotTrajectoryPreservation", function()
			local aimDir = Vector3.new(0, 0.25, -1).Unit
			local power = 100.0
			local upwardBias = 0.05

			local velNeutral, spinNeutral = AirLeanSolver.ComputeAirShotTrajectory(
				aimDir,
				power,
				upwardBias,
				0.0,
				0.0,
				"DirectShoot"
			)

			-- Neutral lean must produce zero spin deflection
			Expect(spinNeutral.Magnitude).toBe(0.0, "Neutral lean must produce zero spin deflection")

			-- Energy conservation: speed must equal power
			Expect(math.abs(velNeutral.Magnitude - power)).toBeLessThan(0.01, "Neutral lean speed must match kick power")

			-- Direction must align with aimDir combined with upwardBias
			Expect(velNeutral.Z).toBeLessThan(-50.0, "Neutral air shot must launch along aim direction")
		end)

		-- TC-ALP-05: Aim-Relative Bounded Lateral Deflection (A/D) with Aim != Facing
		SafeTest("TC-ALP-05_AimRelativeLateralDeflectionAndConeCap", function()
			local power = 100.0
			local upwardBias = 0.0

			-- Case 1: Aim aligned with forward facing (0, 0, -1)
			local aimFwd = Vector3.new(0, 0, -1)
			local velNeutralFwd, _ = AirLeanSolver.ComputeAirShotTrajectory(aimFwd, power, upwardBias, 0.0, 0.0, "Volley")
			local velRightFwd, spinRFwd = AirLeanSolver.ComputeAirShotTrajectory(aimFwd, power, upwardBias, 0.0, 1.0, "Volley")
			local velLeftFwd, spinLFwd = AirLeanSolver.ComputeAirShotTrajectory(aimFwd, power, upwardBias, 0.0, -1.0, "Volley")

			Expect(velRightFwd.X).toBeGreaterThan(0.5, "Right lean must deflect launch velocity to the right of aim")
			Expect(velLeftFwd.X).toBeLessThan(-0.5, "Left lean must deflect launch velocity to the left of aim")
			Expect(spinRFwd.X).toBeLessThan(0.0, "Right lean must induce subtle curve force")

			local dotRFwd = velNeutralFwd.Unit:Dot(velRightFwd.Unit)
			local angleRFwd = math.deg(math.acos(math.clamp(dotRFwd, -1, 1)))
			Expect(angleRFwd).toBeLessThan(5.0001, "Extra deflection cone must not exceed 5.0 deg (Owner Delta §14.3)")
			Expect(dotRFwd).toBeGreaterThan(0.0, "Deflected trajectory must remain in forward hemisphere of aim")

			-- Report measured lateral offsets at 5, 10, 20 studs
			local offset5 = 5.0 * math.tan(math.rad(angleRFwd))
			local offset10 = 10.0 * math.tan(math.rad(angleRFwd))
			local offset20 = 20.0 * math.tan(math.rad(angleRFwd))
			Expect(offset5).toBeLessThan(0.45, "5-stud lateral deflection must be bounded")
			Expect(offset10).toBeLessThan(0.90, "10-stud lateral deflection must be bounded")
			Expect(offset20).toBeLessThan(1.80, "20-stud lateral deflection must be bounded")

			-- Case 2: Aim differing from character facing by 90 deg (aiming right: 1, 0, 0)
			local aim90 = Vector3.new(1, 0, 0)
			local velNeutral90, _ = AirLeanSolver.ComputeAirShotTrajectory(aim90, power, upwardBias, 0.0, 0.0, "DirectShoot")
			local velRight90, _ = AirLeanSolver.ComputeAirShotTrajectory(aim90, power, upwardBias, 0.0, 1.0, "DirectShoot")

			Expect(velNeutral90.X).toBeGreaterThan(99.0, "Base launch must follow 90-deg aim, not locked facing F0 (§14.3)")
			local angle90 = math.deg(math.acos(math.clamp(velNeutral90.Unit:Dot(velRight90.Unit), -1, 1)))
			Expect(angle90).toBeLessThan(5.0001, "Deflection cone at 90-deg aim must not exceed 5.0 deg")

			-- Case 3: Aim differing from character facing by 180 deg (aiming backward: 0, 0, 1)
			local aim180 = Vector3.new(0, 0, 1)
			local velNeutral180, _ = AirLeanSolver.ComputeAirShotTrajectory(aim180, power, upwardBias, 0.0, 0.0, "DirectShoot")
			local velRight180, _ = AirLeanSolver.ComputeAirShotTrajectory(aim180, power, upwardBias, 0.0, 1.0, "DirectShoot")

			Expect(velNeutral180.Z).toBeGreaterThan(99.0, "Base launch must follow 180-deg aim backward (§14.3)")
			local angle180 = math.deg(math.acos(math.clamp(velNeutral180.Unit:Dot(velRight180.Unit), -1, 1)))
			Expect(angle180).toBeLessThan(5.0001, "Deflection cone at 180-deg aim must not exceed 5.0 deg")
		end)

		-- Owner §G.1: S loft is derived from accepted body/contact orientation, not a raw-key launch override.
		SafeTest("TC-ALP-06_ContactFrameLeanAddsSmallContinuousLoft", function()
			local aimDir = Vector3.new(0, 0.1, -1).Unit
			local power = 100.0
			local upwardBias = 0.05
			local facing = CFrame.lookAt(Vector3.zero, Vector3.new(0, 0, -1))
			local neutralContact = facing
			local halfLeanContact = facing * AirLeanSolver.ComputeLeanCFrame(-0.5, 0.0)
			local fullLeanContact = facing * AirLeanSolver.ComputeLeanCFrame(-1.0, 0.0)

			local velNeutral, _ = AirLeanSolver.ComputeContactShotTrajectory(aimDir, power, upwardBias, 0.0, 0.0, "DirectShoot", neutralContact, neutralContact)
			local velHalf, _ = AirLeanSolver.ComputeContactShotTrajectory(aimDir, power, upwardBias, -0.5, 0.0, "DirectShoot", halfLeanContact, neutralContact)
			local velFull, _ = AirLeanSolver.ComputeContactShotTrajectory(aimDir, power, upwardBias, -1.0, 0.0, "DirectShoot", fullLeanContact, neutralContact)

			Expect(math.abs(velNeutral.Y - AirLeanSolver.ComputeAirShotTrajectory(aimDir, power, upwardBias, 0.0, 0.0, "DirectShoot").Y)).toBeLessThan(0.01, "Neutral launch must preserve its established trajectory")
			Expect(velHalf.Y).toBeGreaterThan(velNeutral.Y, "A modest backward body lean should add a modest loft")
			Expect(velFull.Y).toBeGreaterThan(velHalf.Y, "Loft should grow continuously with the accepted posture")
			Expect(math.abs(velFull.Magnitude - power)).toBeLessThan(0.01, "Posture coupling must preserve launch energy")
			local angle = math.deg(math.acos(math.clamp(velNeutral.Unit:Dot(velFull.Unit), -1, 1)))
			Expect(angle).toBeLessThan(4.0, "Maximum S loft should remain a small posture adjustment")
			Expect(Vector3.new(velFull.X, 0, velFull.Z).Unit:Dot(Vector3.new(aimDir.X, 0, aimDir.Z).Unit)).toBeGreaterThan(0.999, "S must not replace camera aim azimuth with character facing")
		end)

		SafeTest("TC-ALP-06B_ContactFrameLoftHandlesAimYawAndNearVertical", function()
			local power = 85.0
			local upwardBias = 0.04
			for _, aim in ipairs({Vector3.new(1, 0.15, 0), Vector3.new(0.01, 0.9998, -0.01).Unit}) do
				local facing = CFrame.lookAt(Vector3.zero, Vector3.new(1, 0, 0))
				local neutralContact = facing
				local backContact = facing * AirLeanSolver.ComputeLeanCFrame(-0.8, 0.2)
				local neutral = AirLeanSolver.ComputeContactShotTrajectory(aim, power, upwardBias, 0.0, 0.0, "Volley", neutralContact, neutralContact)
				local leaning = AirLeanSolver.ComputeContactShotTrajectory(aim, power, upwardBias, -0.8, 0.2, "Volley", backContact, neutralContact)
				Expect(neutral.X == neutral.X and neutral.Y == neutral.Y and neutral.Z == neutral.Z).toBeTrue()
				Expect(leaning.X == leaning.X and leaning.Y == leaning.Y and leaning.Z == leaning.Z).toBeTrue()
				Expect(math.abs(leaning.Magnitude - power)).toBeLessThan(0.01)
			end
		end)

		-- TC-ALP-07: Strict Energy Conservation Cap
		SafeTest("TC-ALP-07_StrictEnergyConservation", function()
			local aimDir = Vector3.new(0, 0, -1)
			local power = 120.0
			local upwardBias = 0.05

			-- Diagonal corner lean (W + D)
			local velDiag, _ = AirLeanSolver.ComputeAirShotTrajectory(aimDir, power, upwardBias, 1.0, 1.0, "Volley")

			-- Strict energy conservation: speed must equal kick power exactly
			Expect(math.abs(velDiag.Magnitude - power)).toBeLessThan(0.01, "Airborne deflection must strictly conserve launch energy")
		end)

		-- TC-ALP-08: BallService SetAirLean Protocol and Airborne State Gating
		SafeTest("TC-ALP-08_BallServiceSetAirLeanAirborneGating", function()
			local pMock, charM, rootM = createMockAirPlayer(1081, "AirLeanPlayer1", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(1081, "North")

			-- 1. On Ground: SetAirLean must be ignored / not mutate state
			BallService.HandleActionRequest(pMock :: any, {
				action = "SetAirLean",
				airLeanForward = 0.8,
				airLeanRight = 0.5,
				intentId = "intent_ground_lean_01",
				characterGeneration = 1,
				contextVersion = 1,
			})
			local snapG = BallService.GetPlayerMovementSnapshot(1081)
			Expect(snapG.airLeanForward or 0.0).toBe(0.0, "Ground player must not accept SetAirLean")
			Expect(snapG.airLeanRight or 0.0).toBe(0.0, "Ground player must not accept SetAirLean")

			-- 2. Transition to Airborne: SetAirLean must now be accepted and slewed
			BallService.ExecuteDirectionalJump(pMock :: any, Vector3.new(0, 0, -1))
			local snapAir = BallService.GetPlayerMovementSnapshot(1081)
			Expect(snapAir.isAirborne).toBeTrue("Player must be airborne after jump")

			-- First lean request
			task.wait(0.06) -- exceed MIN_UPDATE_INTERVAL
			BallService.HandleActionRequest(pMock :: any, {
				action = "SetAirLean",
				airLeanForward = 1.0,
				airLeanRight = 0.0,
				intentId = "intent_air_lean_01",
				characterGeneration = snapAir.characterGeneration,
				contextVersion = snapAir.contextVersion,
			})
			local snapLean1 = BallService.GetPlayerMovementSnapshot(1081)
			Expect((snapLean1.airLeanForward or 0.0)).toBeGreaterThan(0.0, "Airborne player must accept SetAirLean")

			-- 3. Rate limiting: immediate subsequent request within MIN_UPDATE_INTERVAL must be throttled
			local prevFwd = snapLean1.airLeanForward or 0.0
			BallService.HandleActionRequest(pMock :: any, {
				action = "SetAirLean",
				airLeanForward = -1.0,
				airLeanRight = 0.0,
				intentId = "intent_air_lean_02",
				characterGeneration = snapAir.characterGeneration,
				contextVersion = snapAir.contextVersion,
			})
			local snapThrottle = BallService.GetPlayerMovementSnapshot(1081)
			Expect(snapThrottle.airLeanForward).toBe(prevFwd, "Rapid SetAirLean within interval must be throttled")
		end)

		-- TC-ALP-09: Airborne Shot Consumes Lean Snapshot and Clears On Release
		SafeTest("TC-ALP-09_AirborneShotConsumesAndClearsLeanSnapshot", function()
			local pMock, charM, rootM = createMockAirPlayer(1082, "AirLeanPlayer2", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(1082, "North")
			local okJump = BallService.ExecuteDirectionalJump(pMock :: any, Vector3.new(0, 0, -1))
			Expect(okJump).toBeTrue("Jump execution must succeed")
			rootM.CFrame = CFrame.new(0, 5.0, 0)
			rootM.Anchored = true -- Hold the mocked contact pose while the server slew-rate timer advances.

			-- Inject accepted air lean snapshot (allow slew rate to reach target 1.0)
			task.wait(0.18)
			BallService.HandleActionRequest(pMock :: any, {
				action = "SetAirLean",
				airLeanForward = 0.0,
				airLeanRight = 1.0,
				intentId = "intent_air_lean_shot",
				characterGeneration = 1,
				contextVersion = 1,
			})

			-- Position ball in reach of airborne player
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 5.2, -1.0), Vector3.zero)

			-- Airborne RMB -> Volley
			local okVolley = BallService.ExecuteKick(pMock :: any, "Volley", Vector3.new(0, 0, -1), 0.8, "intent_air_volley_01")
			local status, reason = BallService.GetPlayerLastActionStatus(1082)
			Expect(okVolley).toBeTrue("Airborne volley execution must succeed (" .. tostring(status) .. ": " .. tostring(reason) .. ")")

			local ballSt = BallService.GetBallState()
			Expect(ballSt.inFlightAction).toBe("Volley")
			-- Ball velocity must have lateral deflection to the right
			Expect(ballSt.velocity.X).toBeGreaterThan(0.0, "Airborne shot with right lean must deflect ball to the right")

			-- Lean remains active on player state while key held in the air (Owner Delta §14.2: no snap to 0 on release)
			local snapPost = BallService.GetPlayerMovementSnapshot(1082)
			Expect(snapPost.airLeanRight or 0.0).toBe(1.0, "Lean remains active on player state while airborne key held")
		end)

		-- TC-ALP-10: Robustness to Non-Finite and Corrupted Payloads
		SafeTest("TC-ALP-10_NonFinitePayloadRobustness", function()
			local pMock, charM, rootM = createMockAirPlayer(1083, "AirLeanPlayer3", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(1083, "North")
			local okJump = BallService.ExecuteDirectionalJump(pMock :: any, Vector3.new(0, 0, -1))
			Expect(okJump).toBeTrue("Jump execution must succeed")
			rootM.CFrame = CFrame.new(0, 5.0, 0)

			task.wait(0.06)
			-- Send NaN and Inf payloads
			BallService.HandleActionRequest(pMock :: any, {
				action = "SetAirLean",
				airLeanForward = 0/0,
				airLeanRight = math.huge,
				intentId = "intent_bad_lean",
				characterGeneration = 1,
				contextVersion = 1,
			})

			local snap = BallService.GetPlayerMovementSnapshot(1083)
			Expect(snap.airLeanForward ~= snap.airLeanForward).toBeFalse("Lean forward must not be NaN")
			Expect(snap.airLeanRight ~= snap.airLeanRight).toBeFalse("Lean right must not be NaN")
		end)

		-- TC-ALP-11: Client Aim Pipeline Camera Yaw Preservation During Airborne Flight (F-35 / §17)
		SafeTest("TC-ALP-11_ClientAimPipelineYawPreservationDuringAirborneFlight", function()
			local jumpFacingF0 = Vector3.new(0, 0, -1)
			local testAngles = { 0, 60, -60, 180 }
			local power = 100.0
			local upwardBias = 0.05

			for idx, deg in ipairs(testAngles) do
				local rad = math.rad(deg)
				local cameraAim = Vector3.new(math.sin(rad), 0.1, -math.cos(rad)).Unit

				-- 1. Compute trajectory with S-lean (-1.0 fwd, 0.0 rgt)
				local velS, spinS = AirLeanSolver.ComputeAirShotTrajectory(
					cameraAim,
					power,
					upwardBias,
					-1.0, -- S backward lean
					0.0,
					"Volley"
				)

				-- Verify ball trajectory horizontal azimuth matches camera aim, NOT locked facing F0
				local velHoriz = Vector3.new(velS.X, 0, velS.Z).Unit
				local aimHoriz = Vector3.new(cameraAim.X, 0, cameraAim.Z).Unit
				local dotHoriz = math.clamp(velHoriz:Dot(aimHoriz), -1, 1)
				local angleDiffDeg = math.deg(math.acos(dotHoriz))

				Expect(angleDiffDeg).toBeLessThan(0.001, "S-lean pitch deflection must not alter horizontal aim azimuth")

				-- S-lean must scoop trajectory upward
				local velNeutral, _ = AirLeanSolver.ComputeAirShotTrajectory(cameraAim, power, upwardBias, 0.0, 0.0, "Volley")
				Expect(velS.Y).toBeGreaterThan(velNeutral.Y, "S-lean must deflect launch trajectory upward")

				-- Energy conservation
				Expect(math.abs(velS.Magnitude - power)).toBeLessThan(0.01, "Airborne volley speed must conserve kick power")

				-- 2. Server Seam Verification with Mock Player
				local uid = 1084 + idx
				local pMock, charM, rootM = createMockAirPlayer(uid, "AirAimPlayer_" .. tostring(deg), Vector3.new(0, 2.0, 0), jumpFacingF0)
				BallService.SetPlayerTeamSide(uid, "North")
				BallService.SetPossessor(uid)
				BallService.SetPossessor(nil)

				local okJump = BallService.ExecuteDirectionalJump(pMock :: any, jumpFacingF0)
				Expect(okJump).toBeTrue("Airborne jump execution must succeed")
				rootM.CFrame = CFrame.lookAt(Vector3.new(0, 5.0, 0), Vector3.new(0, 5.0, 0) + jumpFacingF0)

				-- Set S-lean snapshot
				BallService.HandleActionRequest(pMock :: any, {
					action = "SetAirLean",
					airLeanForward = -1.0,
					airLeanRight = 0.0,
					intentId = "intent_lean_f35_" .. tostring(deg),
					characterGeneration = 1,
					contextVersion = 1,
				})

				-- Position ball within reach along camera aim
				BallService.SetBallPositionAndVelocity(rootM.Position + cameraAim * 2.0, Vector3.zero)

				-- Server ExecuteKick with cameraAim
				local okKick = BallService.ExecuteKick(pMock :: any, "Volley", cameraAim, 0.8, "intent_kick_f35_" .. tostring(deg))
				Expect(okKick).toBeTrue("Airborne kick with camera aim must succeed")

				local bState = BallService.GetBallState()
				local bHoriz = Vector3.new(bState.velocity.X, 0, bState.velocity.Z).Unit
				local serverDot = math.clamp(bHoriz:Dot(aimHoriz), -1, 1)
				local serverAngleDiff = math.deg(math.acos(serverDot))
				Expect(serverAngleDiff).toBeLessThan(5.001, "Server launched ball horizontal azimuth must track camera aim within 5 deg")

				-- Character body yaw invariant: HumanoidRootPart must remain 100% locked to jumpFacingF0
				local bodyLook = rootM.CFrame.LookVector
				local bodyFacingDot = bodyLook:Dot(jumpFacingF0)
				Expect(bodyFacingDot).toBeGreaterThan(0.9999, "Character body facing must remain strictly locked to jumpFacingF0 (§17.1)")
			end
		end)
	end)

	cleanupAllMockPlayers()
end

return runAirLeanPhysicsTests
