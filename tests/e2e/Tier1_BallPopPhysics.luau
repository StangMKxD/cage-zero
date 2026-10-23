--!strict
-- tests/e2e/Tier1_BallPopPhysics.luau
-- E2E Test Suite for Module 02: Grounded Possessor BallPop & Follow-Up Jump
-- Governed by: docs/plan/phase-01-gameplay-demo/02-player-actions/assets/HANDOFF.md § 16 & tasks.md T-10

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

local function runBallPopPhysicsTests(TestHarness: any)
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

		local folder = Workspace:FindFirstChild("__TestBallPopMocks")
		if folder then
			folder:Destroy()
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

	local function createMockPopPlayer(userId: number, name: string, pos: Vector3, look: Vector3): (any, Model, Part)
		local folder = Workspace:FindFirstChild("__TestBallPopMocks")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "__TestBallPopMocks"
			folder.Parent = Workspace
		end

		local char = Instance.new("Model")
		char.Name = name .. "_" .. tostring(userId)

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

	Describe("Deterministic BallPop Math & Invariants", function()
		SafeTest("CalculateBallPopLaunchVelocity matches character jump apex height under ball gravity", function()
			local vel = JumpModel.CalculateBallPopLaunchVelocity(Vector3.zero, false, -65.0, 196.2, 78.0)

			-- Character jump apex height: H = 78^2 / (2 * 196.2) = 6084 / 392.4 ≈ 15.5046 studs
			-- Ball launch Vy = sqrt(2 * 65.0 * 15.5046) = sqrt(2015.6) ≈ 44.895 studs/s
			Expect(vel.Y > 44.0 and vel.Y < 46.0).toBe(true)

			-- Resulting ball apex height = Vy^2 / (2 * 65.0) ≈ 15.50 studs
			local ballApexH = (vel.Y * vel.Y) / (2.0 * 65.0)
			Expect(ballApexH > 15.3 and ballApexH < 15.7).toBe(true)
		end)

		SafeTest("CalculateBallPopLaunchVelocity produces strictly vertical launch when stationary", function()
			local vel = JumpModel.CalculateBallPopLaunchVelocity(Vector3.new(0.01, 0, 0.01), false)
			Expect(vel.X).toBe(0.0)
			Expect(vel.Z).toBe(0.0)
			Expect(vel.Y > 44.0).toBe(true)
		end)

		SafeTest("CalculateBallPopLaunchVelocity captures exact walk and sprint horizontal speeds along move direction", function()
			-- Walk along +Z
			local velWalk = JumpModel.CalculateBallPopLaunchVelocity(Vector3.new(0, 0, 1), false, -65.0, 196.2, 78.0, 20.0, 24.0)
			Expect(velWalk.Z).toBeCloseTo(20.0, 0.01)
			Expect(velWalk.X).toBeCloseTo(0.0, 0.01)
			Expect(velWalk.Y > 44.0).toBe(true)

			-- Sprint along diagonal (+X, +Z)
			local diagDir = Vector3.new(1, 0, 1).Unit
			local velSprint = JumpModel.CalculateBallPopLaunchVelocity(diagDir, true, -65.0, 196.2, 78.0, 20.0, 24.0)
			local horizSpeed = math.sqrt(velSprint.X * velSprint.X + velSprint.Z * velSprint.Z)
			Expect(horizSpeed).toBeCloseTo(24.0, 0.01)
			Expect(velSprint.Y > 44.0).toBe(true)
		end)
	end)

	Describe("Grounded Possessor BallPop Execution", function()
		SafeTest("Stationary grounded possessor Space performs BallPop: ball launches up, character remains grounded with zero impulse", function()
			local p1, char1, hrp1 = createMockPopPlayer(901, "PopMock1", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(901)

			local ok = BallService.ExecuteBallPop(p1, Vector3.zero, "pop_901_stationary")
			Expect(ok).toBe(true)

			-- Ball state verification
			local ballSnap = BallService.GetBallState()
			Expect(ballSnap.possessorUserId).toBe(nil)
			Expect(ballSnap.state).toBe("Free")
			Expect(ballSnap.velocity.Y > 44.0 and ballSnap.velocity.Y < 46.0).toBe(true)
			Expect(math.abs(ballSnap.velocity.X) < 0.1).toBe(true)
			Expect(math.abs(ballSnap.velocity.Z) < 0.1).toBe(true)
			Expect(ballSnap.lastPossessingTeam).toBe("North")

			-- Character state verification: player is 100% grounded, ZERO launch impulse!
			local playerSnap = BallService.GetPlayerMovementSnapshot(901)
			Expect(playerSnap.isAirborne).toBe(false)
			Expect(playerSnap.flightState).toBe("Grounded")
			Expect(playerSnap.flightId).toBe(nil)
			Expect(playerSnap.airOffensiveBudget).toBe(0)
			Expect(playerSnap.landingLagRemaining).toBe(0)
			Expect(hrp1.AssemblyLinearVelocity.Y).toBe(0.0)
		end)

		SafeTest("Moving grounded possessor Space performs BallPop along movement direction with Walk and Sprint speeds", function()
			local p1, char1, hrp1 = createMockPopPlayer(902, "PopMock2", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(902)

			-- Pop while walking forward (-Z)
			local ok = BallService.ExecuteBallPop(p1, Vector3.new(0, 0, -1), "pop_902_walk")
			Expect(ok).toBe(true)

			local ballSnap = BallService.GetBallState()
			Expect(ballSnap.velocity.Z <= -19.0).toBe(true)
			Expect(ballSnap.velocity.Y > 44.0).toBe(true)
			Expect(ballSnap.possessorUserId).toBe(nil)

			-- Reset and test Sprint pop
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(902)
			local st = (BallService :: any).GetOrCreatePlayerState(902)
			st.isSprinting = true

			local okSprint = BallService.ExecuteBallPop(p1, Vector3.new(1, 0, 0), "pop_902_sprint")
			Expect(okSprint).toBe(true)

			local ballSnapSprint = BallService.GetBallState()
			Expect(ballSnapSprint.velocity.X >= 23.5).toBe(true)
			Expect(ballSnapSprint.velocity.Y > 44.0).toBe(true)
		end)

		SafeTest("DirectionalJump is rejected with PossessingBall when called by grounded possessor", function()
			local p1, char1, hrp1 = createMockPopPlayer(903, "PopMock3", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			BallService.SetPossessor(903)

			local ok = BallService.ExecuteDirectionalJump(p1, Vector3.new(0, 0, -1), "flight_903_illegal", "jump_903_illegal")
			Expect(ok).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(903)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("PossessingBall")

			-- Ball possession was NOT released or corrupted
			local ballSnap = BallService.GetBallState()
			Expect(ballSnap.possessorUserId).toBe(903)
		end)
	end)

	Describe("Space Sequence: Release + Second Press Jumps to Follow Ball", function()
		SafeTest("After BallPop release, second Space press executes normal custom jump towards ball", function()
			local p1, char1, hrp1 = createMockPopPlayer(904, "PopMock4", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(904)

			-- 1st Space: BallPop
			local popOk = BallService.ExecuteBallPop(p1, Vector3.new(0, 0, -1), "pop_904_seq")
			Expect(popOk).toBe(true)

			local ballSnap = BallService.GetBallState()
			Expect(ballSnap.possessorUserId).toBe(nil)

			-- 2nd Space: DirectionalJump (ball is free, non-possessor jump succeeds!)
			local jumpOk = BallService.ExecuteDirectionalJump(p1, Vector3.new(0, 0, -1), "flight_904_follow", "jump_904_follow")
			Expect(jumpOk).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(904)
			Expect(snap.isAirborne).toBe(true)
			Expect(snap.flightState).toBe("Rising")
			Expect(snap.airOffensiveBudget).toBe(1)
			Expect(hrp1.AssemblyLinearVelocity.Y >= 75.0).toBe(true)
		end)

		SafeTest("Airborne first-time kick hits popping ball in mid-air", function()
			local p1, char1, hrp1 = createMockPopPlayer(905, "PopMock5", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, -1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(905)

			-- 1. Pop ball
			BallService.ExecuteBallPop(p1, Vector3.zero, "pop_905_aerial")

			-- 2. Follow-up jump
			BallService.ExecuteDirectionalJump(p1, Vector3.zero, "flight_905_aerial", "jump_905_aerial")

			-- 3. Position ball in air within kicker's aerial reach
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 3.0, -1.0), Vector3.zero)

			-- 4. Execute mid-air strike
			local kickOk = BallService.ExecuteKick(p1, "DirectShoot", Vector3.new(0, 0, -1), 0.5, "kick_905_aerial")
			Expect(kickOk).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(905)
			Expect(snap.airOffensiveBudget).toBe(0)

			local ballSnap = BallService.GetBallState()
			Expect(ballSnap.velocity.Magnitude >= 115.0).toBe(true)
		end)
	end)

	Describe("Negative & Edge Case Rejections", function()
		SafeTest("BallPop is rejected with NotPossessor when player does not own the ball", function()
			local p1, char1, hrp1 = createMockPopPlayer(906, "PopMock6", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			-- Player does not own ball (ball is free)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 2, 5), Vector3.zero)

			local ok = BallService.ExecuteBallPop(p1, Vector3.new(0, 0, 1), "pop_906_not_owner")
			Expect(ok).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(906)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("NotPossessor")
		end)

		SafeTest("BallPop is rejected with Recovery when player is airborne", function()
			local p1, char1, hrp1 = createMockPopPlayer(907, "PopMock7", Vector3.new(0, 15.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(907)
			local st = (BallService :: any).GetOrCreatePlayerState(907)
			st.lastGroundedTime = os.clock() - 1.0

			local ok = BallService.ExecuteBallPop(p1, Vector3.new(0, 0, 1), "pop_907_airborne")
			Expect(ok).toBe(false)

			local status, reason = BallService.GetPlayerLastActionStatus(907)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("Recovery")
		end)

		SafeTest("BallPop does not clear active charge or consume airborne offensive budget", function()
			local p1, char1, hrp1 = createMockPopPlayer(908, "PopMock8", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(908)

			-- Start a charge
			BallService.StartCharge(p1, "DirectShoot", "charge_908")
			local snapPre = BallService.GetPlayerMovementSnapshot(908)
			Expect(snapPre.isCharging).toBe(true)

			-- Perform BallPop
			local ok = BallService.ExecuteBallPop(p1, Vector3.zero, "pop_908_charge")
			Expect(ok).toBe(true)

			-- Charge remains intact and active!
			local snapPost = BallService.GetPlayerMovementSnapshot(908)
			Expect(snapPost.isCharging).toBe(true)
			Expect(snapPost.chargeAction).toBe("DirectShoot")
			Expect(snapPost.airOffensiveBudget).toBe(0)
			Expect(snapPost.landingLagRemaining).toBe(0)
		end)

		SafeTest("BallPop does not trigger landing lag or walk speed stun on the player", function()
			local p1, char1, hrp1 = createMockPopPlayer(909, "PopMock9", Vector3.new(0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetBallPositionAndVelocity(hrp1.Position + Vector3.new(0, 0, 2), Vector3.zero)
			BallService.SetPossessor(909)

			local ok = BallService.ExecuteBallPop(p1, Vector3.zero, "pop_909_nostun")
			Expect(ok).toBe(true)

			local snap = BallService.GetPlayerMovementSnapshot(909)
			Expect(snap.landingLagRemaining).toBe(0)

			local hum = char1:FindFirstChildOfClass("Humanoid")
			if hum then
				Expect(hum.WalkSpeed >= Constants.WALK_SPEED).toBe(true)
			end
		end)
	end)
end

return runBallPopPhysicsTests
