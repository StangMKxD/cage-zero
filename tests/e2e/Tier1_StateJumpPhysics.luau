--!strict
-- tests/e2e/Tier1_StateJumpPhysics.luau
-- E2E Test Suite for Module 02: State-Based Momentum Jump & Soft Apex Timing
-- Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md §15

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))
local JumpModel = require(Shared:WaitForChild("JumpModel"))
local JumpConfigs = require(Shared:WaitForChild("configs"):WaitForChild("JumpConfigs"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local BallService = require(Services:WaitForChild("BallService"))

local function runStateJumpPhysicsTests(TestHarness: any)
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

		local folder = Workspace:FindFirstChild("__TestJumpMocks")
		if folder then
			folder:Destroy()
		end

		local legacyNames = {
			"JumpMockPlayer1", "JumpMockPlayer2", "JumpMockPlayer3",
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

	local function createMockJumpPlayer(userId: number, name: string, pos: Vector3, look: Vector3): (any, Model, Part)
		local folder = Workspace:FindFirstChild("__TestJumpMocks")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "__TestJumpMocks"
			folder.Parent = Workspace
		end

		local char = Instance.new("Model")
		char.Name = name

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Position = pos
		hrp.CFrame = CFrame.lookAt(pos, pos + look)
		hrp.Anchored = false
		hrp.CanCollide = true
		hrp.Parent = char
		char.PrimaryPart = hrp

		local torso = Instance.new("Part")
		torso.Name = "Torso"
		torso.Size = Vector3.new(2, 2, 1)
		torso.Position = pos
		torso.Anchored = false
		torso.CanCollide = false
		torso.Parent = char

		local rootJoint = Instance.new("Motor6D")
		rootJoint.Name = "RootJoint"
		rootJoint.Part0 = hrp
		rootJoint.Part1 = torso
		rootJoint.C0 = CFrame.new()
		rootJoint.C1 = CFrame.new()
		rootJoint.Parent = hrp

		local humanoid = Instance.new("Humanoid")
		humanoid.WalkSpeed = Constants.WALK_SPEED
		humanoid.Parent = char
		char.Parent = folder

		createdMocks[userId] = char

		BallService.SetPlayerCharacterOverride(userId, char)
		BallService.SetPlayerTeamSide(userId, "North")
		local mockPlayer = {
			UserId = userId,
			Name = name,
			Character = char,
		}

		return mockPlayer, char, hrp
	end

	Describe("JumpModel Deterministic Mathematics & Invariants", function()
		SafeTest("CalculateExpectedApex accurately solves apex height and time under standard gravity", function()
			local hApex, tApex = JumpModel.CalculateExpectedApex(78.0, 196.2)
			-- h = v^2 / 2g = 6084 / 392.4 ≈ 15.5045
			Expect(hApex > 15.4 and hApex < 15.6).toBe(true)
			-- t = v / g = 78 / 196.2 ≈ 0.39755
			Expect(tApex > 0.39 and tApex < 0.41).toBe(true)
		end)

		SafeTest("CalculateExpectedApex safely guards against zero or negative gravity", function()
			local hZero, tZero = JumpModel.CalculateExpectedApex(78.0, 0.0)
			Expect(hZero > 0).toBe(true)
			Expect(tZero > 0).toBe(true)
			Expect(hZero ~= math.huge and hZero == hZero).toBe(true)
		end)

		SafeTest("CalculateSoftQuality scales continuously between [0.90, 1.00] with peak at apex", function()
			local _, tApex = JumpModel.CalculateExpectedApex(78.0, 196.2)
			local qTakeoff = JumpModel.CalculateSoftQuality(0.0, 78.0)
			local qApex = JumpModel.CalculateSoftQuality(tApex, 0.0)
			local qFalling = JumpModel.CalculateSoftQuality(tApex * 1.5, -39.0)

			Expect(qTakeoff >= JumpConfigs.APEX_QUALITY_MIN).toBe(true)
			Expect(qTakeoff <= JumpConfigs.APEX_QUALITY_MIN + 0.02).toBe(true)

			-- Peak at apex must equal APEX_QUALITY_MAX (1.00)
			Expect(qApex >= JumpConfigs.APEX_QUALITY_MAX - 0.001).toBe(true)
			Expect(qApex <= JumpConfigs.APEX_QUALITY_MAX).toBe(true)

			-- Off-apex falloff is smoothly bounded
			Expect(qFalling >= JumpConfigs.APEX_QUALITY_MIN).toBe(true)
			Expect(qFalling < qApex).toBe(true)
		end)

		SafeTest("ResolveFlightState produces correct discrete states across vertical trajectory", function()
			-- Grounded initially
			local s0 = JumpModel.ResolveFlightState(0.0, 0.0, false, true)
			Expect(s0).toBe("Takeoff")

			-- Takeoff window (< 0.04s)
			local sTakeoff = JumpModel.ResolveFlightState(70.0, 0.02, false, false)
			Expect(sTakeoff).toBe("Takeoff")

			-- Rising phase (> 0.04s, vy > 2.5)
			local sRising = JumpModel.ResolveFlightState(50.0, 0.15, true, false)
			Expect(sRising).toBe("Rising")

			-- Apex phase (|vy| <= 2.5)
			local sApex = JumpModel.ResolveFlightState(0.5, 0.40, true, false)
			Expect(sApex).toBe("Apex")

			-- Falling phase (vy < -2.5)
			local sFalling = JumpModel.ResolveFlightState(-30.0, 0.60, true, false)
			Expect(sFalling).toBe("Falling")

			-- Landed (ground contact after leaving ground)
			local sLanded = JumpModel.ResolveFlightState(-2.0, 0.75, true, true)
			Expect(sLanded).toBe("Landed")
		end)

		SafeTest("CalculateLaunchImpulse calculates exact instantaneous momentum delta", function()
			local currentVel = Vector3.new(0, 0, 0)
			local targetHoriz = Vector3.new(16, 0, 0)
			local mass = 14.5
			local impulse = JumpModel.CalculateLaunchImpulse(currentVel, targetHoriz, 78.0, mass)

			Expect(impulse.X).toBeCloseTo(16.0 * mass, 0.01)
			Expect(impulse.Y).toBeCloseTo(78.0 * mass, 0.01)
			Expect(impulse.Z).toBeCloseTo(0.0, 0.01)
		end)
	end)

	Describe("Directional Jump Launch & Momentum Locking", function()
		SafeTest("Stationary jump sets horizontal velocity to zero and vertical launch speed to 78", function()
			local p1, char1, hrp1 = createMockJumpPlayer(801, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			local ok = BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_801_1", "jump_801_1")
			Expect(ok).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(801)
			Expect(snap.isAirborne).toBe(true)
			Expect(snap.flightState).toBe("Rising")
			Expect(snap.airOffensiveBudget).toBe(1)
			Expect(snap.jumpLockedVelocity).toBe(nil)

			-- Verify impulse applied to mock player assembly
			Expect(hrp1.AssemblyLinearVelocity.Y >= 75.0).toBe(true)
			Expect(math.abs(hrp1.AssemblyLinearVelocity.X) < 0.1).toBe(true)
			Expect(math.abs(hrp1.AssemblyLinearVelocity.Z) < 0.1).toBe(true)
		end)

		SafeTest("Moving jump captures exact walk speed and direction without drift", function()
			local p1, char1, hrp1 = createMockJumpPlayer(802, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			local jumpDir = Vector3.new(0, 0, -1)
			local ok = BallService.ExecuteDirectionalJump(p1, jumpDir, "flight_802_1", "jump_802_1")
			Expect(ok).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(802)
			Expect(snap.isAirborne).toBe(true)
			Expect(snap.flightState).toBe("Rising")
			Expect(snap.jumpLockedVelocity ~= nil).toBe(true)
			if snap.jumpLockedVelocity then
				Expect(snap.jumpLockedVelocity.Z).toBeCloseTo(-Constants.WALK_SPEED, 0.1)
			end

			Expect(hrp1.AssemblyLinearVelocity.Y >= 75.0).toBe(true)
			Expect(hrp1.AssemblyLinearVelocity.Z <= -15.0).toBe(true)
		end)

		SafeTest("Sprint jump captures sprint speed and launches with 78 vertical speed", function()
			local p1, char1, hrp1 = createMockJumpPlayer(803, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(1, 0, 0))
			BallService.ExecuteSprint(p1, true)

			local jumpDir = Vector3.new(1, 0, 0)
			local ok = BallService.ExecuteDirectionalJump(p1, jumpDir, "flight_803_1", "jump_803_1")
			Expect(ok).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(803)
			Expect(snap.isAirborne).toBe(true)
			if snap.jumpLockedVelocity then
				Expect(snap.jumpLockedVelocity.X).toBeCloseTo(Constants.SPRINT_SPEED, 0.1)
			end
			Expect(hrp1.AssemblyLinearVelocity.X >= 23.0).toBe(true)
			Expect(hrp1.AssemblyLinearVelocity.Y >= 75.0).toBe(true)
		end)

		SafeTest("Edge fall gating rejects jump when already falling in air beyond recent tolerance", function()
			local p1, char1, hrp1 = createMockJumpPlayer(804, "JumpMockPlayer1", Vector3.new(0, 15.0, 0), Vector3.new(0, 0, 1))
			local hum = char1:FindFirstChildOfClass("Humanoid")
			if hum then
				-- FloorMaterial is read-only in Roblox; Y=15 ensures in-air
			end

			-- Force lastGroundedTime into past (> 0.12s tolerance)
			local st = (BallService :: any).GetOrCreatePlayerState(804)
			st.lastGroundedTime = os.clock() - 0.5

			local ok = BallService.ExecuteDirectionalJump(p1, Vector3.new(0, 0, 1), "flight_804_1", "jump_804_1")
			Expect(ok).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(804)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("Recovery")
		end)
	end)

	Describe("Airborne Offensive Action Budget & Whiff Handling", function()
		SafeTest("First airborne shot consumes budget; second shot in same flight is rejected with ExceededBudget", function()
			local p1, char1, hrp1 = createMockJumpPlayer(805, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(805)

			-- Jump into air
			local jumpOk = BallService.ExecuteDirectionalJump(p1, Vector3.new(0, 0, 1), "flight_805_1", "jump_805_1")
			Expect(jumpOk).toBe(true)

			-- Move ball close to kicker so kick is valid
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)

			-- First airborne shot (DirectShoot / Volley)
			local kick1Ok = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, 1), 0.5, "kick_805_1")
			Expect(kick1Ok).toBe(true)

			local snap1 = BallService.GetPlayerMovementSnapshot(805)
			Expect(snap1.airOffensiveBudget).toBe(0)

			-- Attempt second shot in same flight
			local kick2Ok = BallService.ExecuteKick(p1, "Volley", Vector3.new(0, 0, 1), 0.5, "kick_805_2")
			Expect(kick2Ok).toBe(false)

			local status2, reason2 = BallService.GetPlayerLastActionStatus(805)
			Expect(status2).toBe("Rejected")
			Expect(reason2).toBe("ExceededBudget")
		end)

		SafeTest("Airborne whiff consumes budget without adding ground whiff stun", function()
			local p1, char1, hrp1 = createMockJumpPlayer(806, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))

			-- Place ball far away (> 50 studs)
			BallService.SetBallPositionAndVelocity(Vector3.new(100, 2, 100), Vector3.zero)

			local jumpOk = BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_806_1", "jump_806_1")
			Expect(jumpOk).toBe(true)

			-- Attempt kick (whiff)
			local kickOk = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, 1), 0.5, "kick_806_whiff")
			Expect(kickOk).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(806)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("OutOfReach")

			-- Budget must be consumed
			local snap = BallService.GetPlayerMovementSnapshot(806)
			Expect(snap.airOffensiveBudget).toBe(0)

			-- Whiff stun must NOT be applied to player
			local hum = char1:FindFirstChildOfClass("Humanoid")
			if hum then
				Expect(hum.WalkSpeed >= Constants.WALK_SPEED).toBe(true)
			end
		end)
	end)

	Describe("Soft Apex Quality Scaling", function()
		SafeTest("Airborne kick near apex scales with peak soft quality 1.00", function()
			local p1, char1, hrp1 = createMockJumpPlayer(807, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(807)

			BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_807_1", "jump_807_1")

			-- Simulate time reaching expected apex (~0.398s)
			local st = (BallService :: any).GetOrCreatePlayerState(807)
			st.takeoffTime = os.clock() - 0.398
			hrp1.AssemblyLinearVelocity = Vector3.new(0, 0.5, 0)

			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)

			local ok = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, 1), 0.5, "kick_807_apex")
			Expect(ok).toBe(true)

			local ballSnap = BallService.GetBallState()
			local speed = ballSnap.velocity.Magnitude
			-- Base shoot straight speed = 125 * 1.05 = 131.25 under 0.5 power at apex (1.00 quality)
			Expect(speed >= 125.0).toBe(true)
		end)

		SafeTest("Airborne kick at takeoff scales with minimum soft quality 0.90", function()
			local p1, char1, hrp1 = createMockJumpPlayer(808, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(808)

			BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_808_1", "jump_808_1")

			-- Takeoff time is immediate (0.0s elapsed)
			local st = (BallService :: any).GetOrCreatePlayerState(808)
			st.takeoffTime = os.clock()
			hrp1.AssemblyLinearVelocity = Vector3.new(0, 78.0, 0)

			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)

			local ok = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, 1), 0.5, "kick_808_early")
			Expect(ok).toBe(true)

			local ballSnap = BallService.GetBallState()
			local speed = ballSnap.velocity.Magnitude
			-- Speed scaled by ~0.90 (131.25 * 0.90 = 118.125)
			Expect(speed >= 115.0 and speed <= 122.0).toBe(true)
		end)
	end)

	Describe("Landing Lag Debounce & Ground Movement Safety", function()
		SafeTest("Jump during landing lag window is rejected with LandingLag reason", function()
			local p1, char1, hrp1 = createMockJumpPlayer(809, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))

			-- Set landing lag active for next 0.08s
			local st = (BallService :: any).GetOrCreatePlayerState(809)
			st.landingLagUntil = os.clock() + 0.08

			local ok = BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_809_lag", "jump_809_lag")
			Expect(ok).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(809)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("LandingLag")
		end)

		SafeTest("Ground kick and movement are NOT stunned during landing lag", function()
			local p1, char1, hrp1 = createMockJumpPlayer(810, "JumpMockPlayer1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(810)

			-- Set landing lag active
			local st = (BallService :: any).GetOrCreatePlayerState(810)
			st.landingLagUntil = os.clock() + 0.08
			st.isAirborne = false
			st.flightState = "Grounded"

			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)

			-- Ground kick must succeed during landing lag!
			local ok = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, 1), 0.5, "kick_810_ground")
			Expect(ok).toBe(true)

			local hum = char1:FindFirstChildOfClass("Humanoid")
			if hum then
				Expect(hum.WalkSpeed >= Constants.WALK_SPEED).toBe(true)
			end
		end)
	end)
end

return runStateJumpPhysicsTests
