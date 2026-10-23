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
		hum.WalkSpeed = Constants.RUN_SPEED
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

		-- TC-ALP-03: ComputeLeanAngles and ComputeLeanCFrame (Yaw Lock Invariant)
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
			-- Forward pitch rotates around local X axis; LookVector Y component changes but XZ yaw remains locked
			local _, ryFwd, _ = cfFwd:ToEulerAnglesXYZ()
			Expect(math.abs(ryFwd)).toBeLessThan(1e-5, "Pitch forward must not introduce yaw rotation")

			-- Pure Right Roll (D)
			local pr, rr = AirLeanSolver.ComputeLeanAngles(0.0, 1.0)
			Expect(pr).toBe(0.0)
			Expect(math.abs(rr - math.rad(AirLeanConfigs.MAX_ROLL_DEG))).toBeLessThan(0.001)
			local cfRgt = AirLeanSolver.ComputeLeanCFrame(0.0, 1.0)
			local _, ryRgt, _ = cfRgt:ToEulerAnglesXYZ()
			Expect(math.abs(ryRgt)).toBeLessThan(1e-5, "Roll right must not introduce yaw rotation")
		end)

		-- TC-ALP-04: Neutral Air Shot Trajectory Preservation
		SafeTest("TC-ALP-04_NeutralAirShotTrajectoryPreservation", function()
			local F0 = Vector3.new(0, 0, -1)
			local elev = math.rad(15.0)
			local power = 100.0
			local vertPower = 10.0

			local velNeutral, spinNeutral = AirLeanSolver.ComputeAirShotTrajectory(
				F0,
				elev,
				power,
				vertPower,
				0.0,
				0.0,
				"DirectShoot"
			)

			-- Neutral lean must produce zero spin deflection
			Expect(spinNeutral.Magnitude).toBe(0.0, "Neutral lean must produce zero spin deflection")

			-- Expected base velocity
			local expDir = (F0 * math.cos(elev) + Vector3.new(0, 1, 0) * math.sin(elev)).Unit
			local expVel = expDir * power + Vector3.new(0, 1, 0) * vertPower
			Expect((velNeutral - expVel).Magnitude).toBeLessThan(0.01, "Neutral lean must preserve exact base launch velocity")
		end)

		-- TC-ALP-05: Lateral Lean Deflection and Clockwise/Counter-Clockwise Spin (A/D)
		SafeTest("TC-ALP-05_LateralLeanDeflectionAndPhysicalSpin", function()
			local F0 = Vector3.new(0, 0, -1)
			local R0 = F0:Cross(Vector3.new(0, 1, 0)).Unit -- (+1, 0, 0)
			local elev = 0.0
			local power = 100.0
			local vertPower = 0.0

			-- Case A: Right Lean (+1.0, D key)
			local velRight, spinRight = AirLeanSolver.ComputeAirShotTrajectory(
				F0,
				elev,
				power,
				vertPower,
				0.0,
				1.0,
				"Volley"
			)
			-- 1. Velocity must deflect tangentially along R0 (positive X)
			local dotR0_R = velRight:Dot(R0)
			Expect(dotR0_R).toBeGreaterThan(5.0, "Right lean must deflect launch velocity to the right (along R0)")
			-- 2. Physical spin must be negative Y (clockwise curl around vertical axis)
			Expect(spinRight.Y).toBeLessThan(-5.0, "Right lean must induce clockwise spin (yawSpin < 0)")

			-- Case B: Left Lean (-1.0, A key)
			local velLeft, spinLeft = AirLeanSolver.ComputeAirShotTrajectory(
				F0,
				elev,
				power,
				vertPower,
				0.0,
				-1.0,
				"Volley"
			)
			-- 1. Velocity must deflect tangentially along -R0 (negative X)
			local dotR0_L = velLeft:Dot(R0)
			Expect(dotR0_L).toBeLessThan(-5.0, "Left lean must deflect launch velocity to the left (along -R0)")
			-- 2. Physical spin must be positive Y (counter-clockwise curl around vertical axis)
			Expect(spinLeft.Y).toBeGreaterThan(5.0, "Left lean must induce counter-clockwise spin (yawSpin > 0)")

			-- Symmetry check: Left and Right lateral deflections should be mirror opposites
			Expect(math.abs(dotR0_R + dotR0_L)).toBeLessThan(0.01, "Lateral deflections must be symmetric")
			Expect(math.abs(spinRight.Y + spinLeft.Y)).toBeLessThan(0.01, "Spin Y deflections must be symmetric")
		end)

		-- TC-ALP-06: Pitch Lean Elevation and Topspin/Backspin (W/S)
		SafeTest("TC-ALP-06_PitchLeanElevationAndTopspinBackspin", function()
			local F0 = Vector3.new(0, 0, -1)
			local R0 = F0:Cross(Vector3.new(0, 1, 0)).Unit
			local elev = math.rad(10.0)
			local power = 100.0
			local vertPower = 0.0

			local velNeutral, _ = AirLeanSolver.ComputeAirShotTrajectory(F0, elev, power, vertPower, 0.0, 0.0, "DirectShoot")

			-- Case A: Forward Lean (+1.0, W key - Torso leaning down/forward)
			local velFwd, spinFwd = AirLeanSolver.ComputeAirShotTrajectory(F0, elev, power, vertPower, 1.0, 0.0, "DirectShoot")
			-- Forward lean modifies elevation (steeper launch or flatter smash)
			Expect(math.abs(velFwd.Y - velNeutral.Y)).toBeGreaterThan(1.0, "Forward lean must deflect vertical elevation")
			-- Forward pitch induces topspin along R0
			local dotSpinR0_Fwd = spinFwd:Dot(R0)
			Expect(dotSpinR0_Fwd).toBeGreaterThan(2.0, "Forward lean must induce topspin along R0")

			-- Case B: Backward Lean (-1.0, S key - Torso leaning back)
			local velBack, spinBack = AirLeanSolver.ComputeAirShotTrajectory(F0, elev, power, vertPower, -1.0, 0.0, "DirectShoot")
			local dotSpinR0_Back = spinBack:Dot(R0)
			Expect(dotSpinR0_Back).toBeLessThan(-2.0, "Backward lean must induce backspin along R0")
		end)

		-- TC-ALP-07: Energy Conservation Cap
		SafeTest("TC-ALP-07_EnergyConservationCap", function()
			local F0 = Vector3.new(0, 0, -1)
			local elev = 0.0
			local power = 120.0
			local vertPower = 10.0

			-- Maximum corner diagonal lean (W + D)
			local velDiag, _ = AirLeanSolver.ComputeAirShotTrajectory(F0, elev, power, vertPower, 1.0, 1.0, "Volley")

			local maxAllowedSpeed = math.max(power, 120.0) * AirLeanConfigs.ENERGY_BOOST_CAP
			Expect(velDiag.Magnitude).toBeLessThan(maxAllowedSpeed + 0.01, "Lean deflection must not exceed ENERGY_BOOST_CAP")
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

			-- Inject accepted air lean snapshot
			task.wait(0.06)
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
			Expect(okVolley).toBeTrue("Airborne volley execution must succeed")

			local ballSt = BallService.GetBallState()
			Expect(ballSt.inFlightAction).toBe("Volley")
			-- Ball velocity must have lateral deflection to the right
			Expect(ballSt.velocity.X).toBeGreaterThan(0.0, "Airborne shot with right lean must deflect ball to the right")

			-- Lean snapshot must be reset to 0 upon ball release
			local snapPost = BallService.GetPlayerMovementSnapshot(1082)
			Expect(snapPost.airLeanForward or 0.0).toBe(0.0, "Lean forward must reset to 0 on release")
			Expect(snapPost.airLeanRight or 0.0).toBe(0.0, "Lean right must reset to 0 on release")
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
	end)

	cleanupAllMockPlayers()
end

return runAirLeanPhysicsTests
