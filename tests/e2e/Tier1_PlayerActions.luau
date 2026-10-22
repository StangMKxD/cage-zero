--!strict
-- tests/e2e/Tier1_PlayerActions.luau
-- E2E Test Suite for Module 02: 02-player-actions
-- Validates: Ball lifecycle, possession, kicking actions (Shoot, Curve, Pass),
-- team context retention (Q22 Continuous Football), directional jump, and stamina.
-- Fully covers findings F-10 through F-17 with protected teardown and zero leftover mocks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))
local Configs = Shared:WaitForChild("configs")
local RigAnimationConfigs = require(Configs:WaitForChild("RigAnimationConfigs"))
local PlayerActionPoseConfigs = require(Configs:WaitForChild("PlayerActionPoseConfigs"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local BallService = require(Services:WaitForChild("BallService"))
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))

local ClientFolder = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("Client")
local R6AnimationController = require(ClientFolder:WaitForChild("character"):WaitForChild("R6AnimationController"))
local Controllers = ClientFolder:WaitForChild("controllers")
local TrainingHUD = require(Controllers:WaitForChild("TrainingHUD"))

local function runPlayerActionsTests(TestHarness: any)
	local Describe = TestHarness.Describe
	local Test = TestHarness.Test
	local Expect = TestHarness.Expect

	local createdMocks: { [number]: Model } = {}

	local function getOrCreateMockContainer(): Folder
		local folder = Workspace:FindFirstChild("__TestMocks")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "__TestMocks"
			folder.Parent = Workspace
		end
		return folder :: Folder
	end

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

		local testGui = Workspace:FindFirstChild("TestGuiParent")
		if testGui then
			testGui:Destroy()
		end

		-- Clean any legacy models by known names
		local legacyNames = {
			"Shooter1", "SouthPlayer", "Jumper", "MidAirJumper", "Passer1",
			"SnapshotPlayer", "NorthPlayer", "AerialStriker", "AirJumper",
			"Curver1", "Dasher", "TestStriker1", "TestDribbler", "ExhaustedRunner",
			"DefenderStanding", "Collector", "Sprinter", "DistantPlayer",
			"BurstDasher", "AttackerNorth", "DefenderSouth", "RampLander", "DeflectStriker",
			"DirectDefender", "ContestPlayer1", "ContestPlayer2", "CloseOpponent",
			"HighBlocker", "FirstTimeShooter", "ValidationPlayer", "ChargePlayer",
			"EdgeFallingPlayer", "LifecyclePlayer",
			"SlideTackler", "AttackerHolding", "SlideMisser", "DistantOpponent",
			"SlideAirborne", "OtherPlayer", "TableIntentPlayer", "ContextFlipPlayer",
			"ContextFlipOpponent", "SchemaTestPlayer", "MismatchChargePlayer",
			"SlideContextAttacker", "SlideContextDefender", "DashSlideLockPlayer",
			"ReboundBallTester", "DiscreteJumper", "ResolvedCurver", "BicycleAcrobat",
		}
		for _, name in ipairs(legacyNames) do
			local m = Workspace:FindFirstChild(name)
			if m and m:IsA("Model") then
				m:Destroy()
			end
		end
	end

	-- Protected Test Wrapper: ensures cleanupAllMockPlayers ALWAYS runs even if test fails
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

	cleanupAllMockPlayers()

	if BallService.ClearAllPlayerStates then
		BallService.ClearAllPlayerStates()
	end
	BallService.ResetBall()

	-- Helper mock player
	local function createMockPlayer(userId: number, name: string, position: Vector3, lookVec: Vector3?)
		local mockChar = Instance.new("Model")
		mockChar.Name = name

		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Size = Vector3.new(2, 2, 1)
		root.Transparency = 1.0
		root.CastShadow = false
		root.CanCollide = false
		root.CanQuery = false
		root.CanTouch = false
		local look = lookVec or Vector3.new(0, 0, 1)
		root.CFrame = CFrame.lookAt(position, position + look)
		root.Anchored = true
		root.Parent = mockChar
		mockChar.PrimaryPart = root

		local hum = Instance.new("Humanoid")
		hum.Health = 100
		hum.MaxHealth = 100
		hum.WalkSpeed = Constants.WALK_SPEED
		hum.Parent = mockChar

		mockChar.Parent = getOrCreateMockContainer()
		createdMocks[userId] = mockChar

		local mockPlr = {
			UserId = userId,
			Name = name,
			Character = mockChar,
		}

		BallService.SetPlayerCharacterOverride(userId, mockChar)
		return mockPlr, mockChar, root, hum
	end

	local function cleanupMockPlayer(userId: number, char: Model)
		BallService.SetPlayerCharacterOverride(userId, nil)
		createdMocks[userId] = nil
		if char and char.Parent then
			char:Destroy()
		end
	end

	Describe("T1_PlayerActions_BallLifecycleAndPossession", function()
		SafeTest("TC-P02-01_BallInstanceCreation", function()
			local ballPart = BallService.EnsureBallInstance()
			Expect(ballPart).toNotBeNil()
			Expect(ballPart.Name).toBe(Constants.BALL_PART_NAME)
			Expect(ballPart:GetAttribute("IsMatchBall")).toBe(true)
			Expect(ballPart.Shape).toBe(Enum.PartType.Ball)
			Expect(ballPart.Size.X).toBeCloseTo(Constants.BALL_RADIUS * 2, 0.05)
		end)

		SafeTest("TC-P02-02_BallInitialState", function()
			BallService.ResetBall()
			local st = BallService.GetBallState()
			Expect(st.state).toBe("Free")
			Expect(st.possessorUserId).toBeNil()
			Expect(st.velocity.Magnitude).toBeCloseTo(0.0, 0.01)
			-- Ball sits cleanly on ground at BALL_RADIUS without floating
			Expect(st.position.Y).toBeCloseTo(Constants.BALL_RADIUS, 0.05)
		end)

		SafeTest("TC-P02-03_PossessionPickupAndTeamContext", function()
			local p1, char1, root1 = createMockPlayer(1001, "TestStriker1", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1001, "North")
			BallService.SetPossessor(1001)

			local st = BallService.GetBallState()
			Expect(st.state).toBe("Possessed")
			Expect(st.possessorUserId).toBe(1001)
			Expect(st.lastPossessingTeam).toBe("North")
			Expect(BallService.GetPlayerActionContext(1001)).toBe("Attacking")
		end)

		SafeTest("TC-P02-04_PossessionSteppingFollowsPlayer", function()
			local p1, char1, root1 = createMockPlayer(1002, "TestDribbler", Vector3.new(10, 1.5, 20), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1002, "South")
			BallService.SetPossessor(1002)

			-- Step physics for 0.05s
			BallService.StepPhysics(0.05)
			local st = BallService.GetBallState()

			-- Ball should be in front of rootPart (Z ~ 20 + 2.5 = 22.5) and touching turf (Y = BALL_RADIUS)
			Expect(st.position.X).toBeCloseTo(10.0, 0.5)
			Expect(st.position.Z).toBeCloseTo(22.5, 0.5)
			Expect(st.position.Y).toBeCloseTo(Constants.BALL_RADIUS, 0.05)
		end)

		SafeTest("TC-P02-05_StaminaExhaustionWidensDribbleTouch", function()
			local p1, char1, root1 = createMockPlayer(1003, "ExhaustedRunner", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPossessor(1003)

			-- Set stamina to 0.05 (below 0.15 exhausted threshold)
			BallService.SetPlayerStamina(1003, 0.05)
			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Exhausted dribble distance is ~4.2 studs in front of player
			Expect(st.position.Z).toBeCloseTo(4.2, 0.5)
			Expect(st.position.Y).toBeCloseTo(Constants.BALL_RADIUS, 0.05)
		end)
	end)

	Describe("T1_PlayerActions_KickingAndPassing", function()
		SafeTest("TC-P02-06_DirectShootExecution", function()
			local p1, char1, root1 = createMockPlayer(1004, "Shooter1", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1004, "South")
			BallService.SetPossessor(1004)

			local aimDir = Vector3.new(0, 0, 1)
			local ok = BallService.ExecuteKick(p1 :: any, "DirectShoot", aimDir, 1.0)
			Expect(ok).toBeTrue()

			local st = BallService.GetBallState()
			Expect(st.state).toBe("InFlight")
			Expect(st.possessorUserId).toBeNil()
			Expect(st.lastKickerUserId).toBe(1004)
			Expect(st.lastPossessingTeam).toBe("South")
			Expect(st.velocity.Z).toBeGreaterThan(100.0)
		end)

		SafeTest("TC-P02-07_CurveShootAppliesPerpendicularForce", function()
			local p1, char1, root1 = createMockPlayer(1005, "Curver1", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1005, "North")
			BallService.SetPossessor(1005)

			local aimDir = Vector3.new(0, 0, 1)
			local ok = BallService.ExecuteKick(p1 :: any, "CurveShoot", aimDir, 0.8)
			Expect(ok).toBeTrue()

			local st = BallService.GetBallState()
			Expect(st.state).toBe("InFlight")
			Expect(st.curveImpulse).toNotBeNil()
			Expect(math.abs(st.curveImpulse.X)).toBeGreaterThan(15.0)
		end)

		SafeTest("TC-P02-08_PassTrajectoryAndLobPassRejection", function()
			local p1, char1, root1 = createMockPlayer(1006, "Passer1", Vector3.new(0, 1.5, 0), Vector3.new(1, 0, 0))
			BallService.SetPossessor(1006)

			-- 1. Pass: single 3D Pass with loft
			local ok1 = BallService.ExecuteKick(p1 :: any, "Pass", Vector3.new(1, 0.2, 0), 0.5)
			Expect(ok1).toBeTrue()
			local st1 = BallService.GetBallState()
			Expect(st1.inFlightAction).toBe("Pass")
			Expect(st1.velocity.X).toBeGreaterThan(40.0)
			Expect(st1.velocity.Y).toBeGreaterThan(1.0)

			-- 2. Legacy GroundPass alias: functions as Pass
			BallService.SetPossessor(1006)
			local ok2 = BallService.ExecuteKick(p1 :: any, "GroundPass", Vector3.new(1, 0, 0), 0.5)
			Expect(ok2).toBeTrue()
			local st2 = BallService.GetBallState()
			Expect(st2.inFlightAction).toBe("Pass")
			Expect(st2.velocity.X).toBeGreaterThan(40.0)

			-- 3. LobPass rejection: removed action must return false, retain possessor, not mutate ball flight
			BallService.SetPossessor(1006)
			local ok3 = BallService.ExecuteKick(p1 :: any, "LobPass" :: any, Vector3.new(0, 0, -1), 0.5)
			Expect(ok3).toBeFalse()
			local st3 = BallService.GetBallState()
			Expect(st3.possessorUserId).toBe(1006)
			Expect(st3.state).toBe("Possessed")
			Expect(char1:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(char1:GetAttribute("LastActionRejectReason")).toBe("RemovedAction")
		end)

		SafeTest("TC-P02-09_ContinuousTeamContextRetention", function()
			local pNorth, charN = createMockPlayer(1007, "NorthPlayer", Vector3.new(0, 1.5, -20))
			local pSouth, charS = createMockPlayer(1008, "SouthPlayer", Vector3.new(0, 1.5, 20))

			BallService.SetPlayerTeamSide(1007, "North")
			BallService.SetPlayerTeamSide(1008, "South")

			-- North player takes possession and shoots
			BallService.SetPossessor(1007)
			Expect(BallService.GetLastPossessingTeam()).toBe("North")
			Expect(BallService.GetPlayerActionContext(1007)).toBe("Attacking")
			Expect(BallService.GetPlayerActionContext(1008)).toBe("Defending")

			-- Kick ball into flight
			BallService.ExecuteKick(pNorth :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.5)

			-- Ball is InFlight; North team MUST STILL retain Attacking context per Q22!
			Expect(BallService.GetLastPossessingTeam()).toBe("North")
			Expect(BallService.GetPlayerActionContext(1007)).toBe("Attacking")
			Expect(BallService.GetPlayerActionContext(1008)).toBe("Defending")

			-- South player gains confirmed possession -> context flips!
			BallService.SetPossessor(1008)
			Expect(BallService.GetLastPossessingTeam()).toBe("South")
			Expect(BallService.GetPlayerActionContext(1007)).toBe("Defending")
			Expect(BallService.GetPlayerActionContext(1008)).toBe("Attacking")
		end)
	end)

	Describe("T1_PlayerActions_FirstTimeAndMovement", function()
		SafeTest("TC-P02-10_FirstTimeHeaderAndVolley", function()
			local p1, char1, root1 = createMockPlayer(1009, "AerialStriker", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1009, "South")

			-- Ball is in the air above player at height Y = 4.0 (Header height >= root.Y + 0.5)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 4.0, 1.5), Vector3.new(0, -5, 0))
			local okHeader = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.7)
			Expect(okHeader).toBeTrue()
			local stHeader = BallService.GetBallState()
			Expect(stHeader.inFlightAction).toBe("Header")

			-- Ball is lower in the air at height Y = 1.6 (Volley height < root.Y + 0.5)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.6, 1.5), Vector3.new(0, 0, 0))
			local okVolley = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.7)
			Expect(okVolley).toBeTrue()
			local stVolley = BallService.GetBallState()
			Expect(stVolley.inFlightAction).toBe("Volley")
			Expect(stVolley.velocity.Z).toBeGreaterThan(100.0)
		end)

		SafeTest("TC-P02-11_DirectionalJumpLock", function()
			local p1, char1, root1 = createMockPlayer(1010, "Jumper", Vector3.new(0, 1.5, 0))
			local jumpDir = Vector3.new(1, 0, 0)
			local ok = BallService.ExecuteDirectionalJump(p1 :: any, jumpDir)
			Expect(ok).toBeTrue()
		end)

		SafeTest("TC-P02-12_DashStaminaCostAndCooldown", function()
			local p1, char1, root1 = createMockPlayer(1011, "Dasher", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerStamina(1011, 1.0)

			-- First dash: success
			local ok1 = BallService.ExecuteDash(p1 :: any, Vector3.new(0, 0, 1))
			Expect(ok1).toBeTrue()
			Expect(BallService.GetPlayerStamina(1011)).toBeCloseTo(1.0 - Constants.DASH_STAMINA_COST, 0.02)

			-- Second immediate dash: fails due to cooldown (1.2s)
			local ok2 = BallService.ExecuteDash(p1 :: any, Vector3.new(0, 0, 1))
			Expect(ok2).toBeFalse()

			-- Empty stamina dash fails
			BallService.SetPlayerStamina(1011, 0.10)
			local ok3 = BallService.ExecuteDash(p1 :: any, Vector3.new(0, 0, 1))
			Expect(ok3).toBeFalse()
		end)
	end)

	Describe("T1_PlayerActions_DeflectionAndJumpLock", function()
		SafeTest("TC-P02-13_FastBallNoAutoCatchAndDeflection", function()
			local p1, char1, root1 = createMockPlayer(1012, "DefenderStanding", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1012, "North")

			-- High speed ball flying directly at player (110 studs/s > 65 studs/s threshold) toward -Z
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, -110))

			-- Step physics for 0.05s
			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Ball MUST NOT be automatically caught
			Expect(st.state).toNotBe("Possessed")
			Expect(st.possessorUserId).toBeNil()
			-- Ball deflects away with speed and changes direction (F-17)
			Expect(st.velocity.Magnitude).toBeGreaterThan(25.0)
			Expect(st.velocity.Z).toBeGreaterThan(0.0, "Deflection must reverse Z direction away from defender")
		end)

		SafeTest("TC-P02-14_ReceivableBallCleanPossession", function()
			local p1, char1, root1 = createMockPlayer(1013, "Collector", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1013, "South")

			-- Slower receivable ball (10 studs/s <= 65 studs/s threshold)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, 10))

			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			Expect(st.state).toBe("Possessed")
			Expect(st.possessorUserId).toBe(1013)
			Expect(st.lastPossessingTeam).toBe("South")
		end)

		SafeTest("TC-P02-15_DirectionalJumpAirborneLockAndLanding", function()
			local p1, char1, root1, hum1 = createMockPlayer(1014, "AirJumper", Vector3.new(0, 1.5, 0))
			local jumpDir = Vector3.new(1, 0, 0)
			local ok = BallService.ExecuteDirectionalJump(p1 :: any, jumpDir)
			Expect(ok).toBeTrue()
			Expect(root1.AssemblyLinearVelocity.X).toBeCloseTo(Constants.WALK_SPEED, 0.5)

			-- Simulate mid-air steering tamper attempt
			root1.AssemblyLinearVelocity = Vector3.new(0, 5.0, 20.0)

			-- Server StepPhysics enforces locked horizontal vector
			BallService.StepPhysics(0.05)
			Expect(root1.AssemblyLinearVelocity.X).toBeCloseTo(Constants.WALK_SPEED, 0.5)
			Expect(math.abs(root1.AssemblyLinearVelocity.Z)).toBeLessThan(1.0)

			-- Land player: floor seam contact clears airborne state (F-15 & F-17)
			task.wait(0.20)
			root1.CFrame = CFrame.new(0, 0.5, 0)
			BallService.StepPhysics(0.05)

			local snapLanded = BallService.GetPlayerMovementSnapshot(1014)
			Expect(snapLanded.isAirborne).toBeFalse("Airborne lock must be cleared upon landing")
			Expect(snapLanded.jumpLockedVelocity).toBeNil()
		end)

		SafeTest("TC-P02-16_SprintSpeedAndStaminaExhaustionReset", function()
			local p1, char1, root1, hum1 = createMockPlayer(1015, "Sprinter", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerStamina(1015, 1.0)

			-- Execute Sprint: WalkSpeed increases to SPRINT_SPEED (24)
			local ok1 = BallService.ExecuteSprint(p1 :: any, true)
			Expect(ok1).toBeTrue()
			Expect(hum1.WalkSpeed).toBeCloseTo(Constants.SPRINT_SPEED, 0.5)

			-- Exhaust stamina to depleted state
			BallService.SetPlayerStamina(1015, 0.01)
			BallService.StepPhysics(0.05)

			-- WalkSpeed automatically resets to normal WALK_SPEED (16)
			Expect(hum1.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.5)
		end)
	end)

	Describe("T1_PlayerActions_AnimationAndInputIntegrations", function()
		SafeTest("TC-P02-17_AnimationProfileAndProvenanceValidation", function()
			local testStates = { "idle", "walk", "run", "jump", "fall", "climb", "sprint", "dash", "kick", "pass", "header", "volley" }
			for _, stateName in ipairs(testStates) do
				local profile = RigAnimationConfigs.GetProfile(stateName)
				Expect(profile).toNotBeNil(string.format("Profile missing for state: %s", stateName))
				local isValid = RigAnimationConfigs.ValidateProvenance(stateName)
				Expect(isValid).toBeTrue(string.format("Provenance invalid for state: %s", stateName))
			end
		end)

		SafeTest("TC-P02-18_R6AnimationControllerTrackLoading", function()
			local reqStates = R6AnimationController.GetRequiredStates()
			Expect(#reqStates).toBeGreaterThanOrEqual(4)
			Expect(type(R6AnimationController.PlayAction)).toBe("function")
			Expect(type(R6AnimationController.PlayState)).toBe("function")
			Expect(type(R6AnimationController.StopAction)).toBe("function")
		end)

		SafeTest("TC-P02-19_OutOfReachKickRejection", function()
			local p1, char1, root1 = createMockPlayer(1016, "DistantPlayer", Vector3.new(100, 1.5, 100))
			BallService.ResetBall(Vector3.new(0, 2.0, 0))

			-- Attempting to shoot when ball is far away (> BALL_TOUCH_RADIUS) must be rejected
			local ok = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.5)
			Expect(ok).toBeFalse()
		end)

		SafeTest("TC-P02-20_CardModifiersScalingKicks", function()
			local p1, char1, root1 = createMockPlayer(1017, "RonanShooter", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1017, "North")
			BallService.SetPossessor(1017)

			local ok = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 1.0)
			Expect(ok).toBeTrue()

			local st = BallService.GetBallState()
			Expect(st.velocity.Z).toBeGreaterThan(Constants.SHOOT_STRAIGHT_SPEED * 0.95)
		end)

		SafeTest("TC-P02-21_ElevatingRampShootingImpulse", function()
			local p1, char1, root1 = createMockPlayer(1018, "RampShooter", Vector3.new(74.0, 2.0, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1018, "North")
			BallService.SetPossessor(1018)

			local ok = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.5)
			Expect(ok).toBeTrue()

			local st = BallService.GetBallState()
			Expect(st.velocity.Y).toBeGreaterThan(15.0)
		end)

		SafeTest("TC-P02-22_DefendingPlayerKickRejection", function()
			local p1, char1, root1 = createMockPlayer(1019, "DefenderNorth", Vector3.new(0, 1.5, 0))
			local p2, char2, root2 = createMockPlayer(1020, "AttackerSouth", Vector3.new(0, 1.5, 10))

			BallService.SetPlayerTeamSide(1019, "North")
			BallService.SetPlayerTeamSide(1020, "South")

			BallService.SetPossessor(1020)
			Expect(BallService.GetPlayerActionContext(1019)).toBe("Defending")

			local okDef = BallService.ExecuteKick(p1 :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.5)
			Expect(okDef).toBeFalse()
		end)

		SafeTest("TC-P02-23_MidAirDashRejection", function()
			local p1, char1, root1 = createMockPlayer(1021, "MidAirJumper", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerStamina(1021, 1.0)

			-- Jump into air
			BallService.ExecuteDirectionalJump(p1 :: any, Vector3.new(0, 0, 1))

			-- Attempting Dash while airborne must be rejected
			local okDash = BallService.ExecuteDash(p1 :: any, Vector3.new(0, 0, 1))
			Expect(okDash).toBeFalse()

			-- Stamina must remain unconsumed
			Expect(BallService.GetPlayerStamina(1021)).toBeCloseTo(1.0, 0.01)
		end)

		SafeTest("TC-P02-24_ElevatedSurfaceLandingClearsJumpLock", function()
			local p1, char1, root1, hum1 = createMockPlayer(1022, "RampLander", Vector3.new(74.0, 1.5, 0))

			-- Start jump
			BallService.ExecuteDirectionalJump(p1 :: any, Vector3.new(0, 0, 1))
			Expect(BallService.GetPlayerMovementSnapshot(1022).isAirborne).toBeTrue()

			-- Wait past takeoff grace (0.15s)
			task.wait(0.20)
			-- Land on Elevating Ramp surface (Y = 2.2 on East Ramp)
			root1.CFrame = CFrame.new(74.0, 2.2, 0)

			-- Step physics: detects landing on elevated surface and clears airborne lock
			BallService.StepPhysics(0.05)

			local snapLanded = BallService.GetPlayerMovementSnapshot(1022)
			Expect(snapLanded.isAirborne).toBeFalse()
			Expect(snapLanded.jumpLockedVelocity).toBeNil()
		end)

		SafeTest("TC-P02-25_ZeroDistanceDeflectionSafeGuard", function()
			local p1, char1, root1 = createMockPlayer(1023, "DirectDefender", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1023, "North")

			-- Place high speed ball right at player position to trigger diff <= 1e-3
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 0.0001), Vector3.new(0, 0, -110))

			-- Step physics for 0.05s
			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Deflection must not produce NaN velocities (F-13 & F-17)
			Expect(st.velocity.X == st.velocity.X).toBeTrue("Velocity.X must not be NaN")
			Expect(st.velocity.Y == st.velocity.Y).toBeTrue("Velocity.Y must not be NaN")
			Expect(st.velocity.Z == st.velocity.Z).toBeTrue("Velocity.Z must not be NaN")
			Expect(st.velocity.Magnitude).toBeGreaterThan(20.0)
			Expect(st.curveImpulse).toBeNil("Curve impulse must be cleared on deflection")
			Expect(st.inFlightAction).toBeNil()
			Expect(st.state).toBe("Free")
		end)

		SafeTest("TC-P02-26_PlayerMovementSnapshotContract", function()
			local p1, char1, root1 = createMockPlayer(1024, "SnapshotPlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1024, "South")
			BallService.SetPlayerStamina(1024, 0.75)

			local snap = BallService.GetPlayerMovementSnapshot(1024)
			Expect(snap.userId).toBe(1024)
			Expect(snap.teamSide).toBe("South")
			Expect(snap.stamina).toBeCloseTo(0.75, 0.01)
			Expect(snap.isSprinting).toBeFalse()
			Expect(snap.isDashing).toBeFalse()
			Expect(snap.isAirborne).toBeFalse()
			Expect(snap.actionContext).toBe("Attacking")
			Expect(snap.dashCooldownRemaining).toBeCloseTo(0.0, 0.05)
		end)
	end)

	Describe("T1_PlayerActions_ReviewFindingsValidation", function()
		-- F-10: Continuous player contact during possession / dash
		SafeTest("TC-P02-27_OpponentPossessionContestContinuousContact", function()
			local pAtt, charAtt, rootAtt = createMockPlayer(1025, "AttackerNorth", Vector3.new(0, 1.5, 0))
			local pDef, charDef, rootDef = createMockPlayer(1026, "DefenderSouth", Vector3.new(0, 1.5, 3.5))

			BallService.SetPlayerTeamSide(1025, "North")
			BallService.SetPlayerTeamSide(1026, "South")

			BallService.SetPossessor(1025)
			Expect(BallService.GetPossessorUserId()).toBe(1025)

			-- Step physics: ball is at (0, 1.25, 2.5), which is 1 stud from South defender at (0, 1.5, 3.5)
			BallService.StepPhysics(0.05)

			-- South defender intercepts/tackles possession during dribble!
			Expect(BallService.GetPossessorUserId()).toBe(1026)
			Expect(BallService.GetLastPossessingTeam()).toBe("South")
		end)

		-- F-10: Close opponent contact immediately after kick (no 0.3s global immunity)
		SafeTest("TC-P02-28_CloseOpponentContactAfterKickNoGlobalImmunity", function()
			local pKicker, charK, rootK = createMockPlayer(1027, "KickerNorth", Vector3.new(0, 1.5, 0))
			local pBlocker, charB, rootB = createMockPlayer(1028, "CloseOpponent", Vector3.new(0, 1.5, 2.5))

			BallService.SetPlayerTeamSide(1027, "North")
			BallService.SetPlayerTeamSide(1028, "South")
			BallService.SetPossessor(1027)

			-- Kicker kicks directly into opponent
			local ok = BallService.ExecuteKick(pKicker :: any, "DirectShoot", Vector3.new(0, 0, 1), 1.0)
			Expect(ok).toBeTrue()

			-- Step physics immediately (now - lastKickTime < 0.05s)
			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Must deflect off close opponent; not ignore them due to global kick immunity
			Expect(st.velocity.Z).toBeLessThan(0.0, "Ball must deflect backward off close opponent")
			Expect(st.state).toBe("Free")
		end)

		-- F-11: High aerial jump block swept collision (Y > 3.8)
		SafeTest("TC-P02-29_HighAerialJumpBlockSweptCollision", function()
			local pJumper, charJ, rootJ = createMockPlayer(1029, "HighBlocker", Vector3.new(0, 6.0, 0))
			BallService.SetPlayerTeamSide(1029, "South")

			-- High ball at Y = 6.0 flying fast through jumping blocker (swept segment from Z = 6 to Z = -6)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 6.0, 5.0), Vector3.new(0, 0, -90.0))

			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Ball must deflect off jumping player at Y = 6.0 without being ignored by world Y <= 3.8
			Expect(st.velocity.Z).toBeGreaterThan(0.0, "High ball must deflect off mid-air jumping blocker")
			Expect(st.state).toBe("Free")
		end)

		-- F-12: First-time intents preserved without prior possession
		SafeTest("TC-P02-30_FirstTimeIntentsPreservedWithoutPriorPossession", function()
			local pStriker, charS, rootS = createMockPlayer(1030, "FirstTimeShooter", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1030, "North")

			-- Ball is loose within reach (dist = 2 studs <= BALL_TOUCH_RADIUS)
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, 5.0))

			-- 1. First-time Pass
			local okPass = BallService.ExecuteKick(pStriker :: any, "Pass", Vector3.new(1, 0, 0), 0.5)
			Expect(okPass).toBeTrue()
			local stPass = BallService.GetBallState()
			Expect(stPass.inFlightAction).toBe("Pass")

			-- 2. First-time GroundPass alias
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, 5.0))
			local okGP = BallService.ExecuteKick(pStriker :: any, "GroundPass", Vector3.new(1, 0, 0), 0.5)
			Expect(okGP).toBeTrue()
			local stGP = BallService.GetBallState()
			Expect(stGP.inFlightAction).toBe("Pass")

			-- 3. First-time Lob Pass must be rejected without mutating ball
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, 5.0))
			local okLob = BallService.ExecuteKick(pStriker :: any, "LobPass" :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okLob).toBeFalse()
			local stLob = BallService.GetBallState()
			Expect(stLob.state).toBe("Free")
			Expect(stLob.position.Z).toBeCloseTo(2.0, 0.1)

			-- 4. First-time Curve Shoot
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 2.0), Vector3.new(0, 0, 5.0))
			local okCurve = BallService.ExecuteKick(pStriker :: any, "CurveShoot", Vector3.new(0, 0, 1), 0.7)
			Expect(okCurve).toBeTrue()
			local stCurve = BallService.GetBallState()
			Expect(stCurve.inFlightAction).toBe("CurveShoot")
			Expect(stCurve.curveImpulse).toNotBeNil()
		end)

		-- F-13: Validation & Dead Character Rejection
		SafeTest("TC-P02-31_PayloadValidationAndDeadCharacterRejection", function()
			local pVal, charV, rootV, humV = createMockPlayer(1031, "ValidationPlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1031, "North")
			BallService.SetPossessor(1031)

			-- NaN charge must be rejected
			local nanCharge = 0/0
			local okNaN = BallService.ExecuteKick(pVal :: any, "DirectShoot", Vector3.new(0, 0, 1), nanCharge)
			Expect(okNaN).toBeFalse()

			-- Vertical aim (0, 1, 0) must safely normalize to horizontal look vector without producing NaN
			local okVert = BallService.ExecuteKick(pVal :: any, "DirectShoot", Vector3.new(0, 1, 0), 0.5)
			Expect(okVert).toBeTrue()
			local st = BallService.GetBallState()
			Expect(st.velocity.X == st.velocity.X).toBeTrue("Velocity.X must not be NaN")
			Expect(st.velocity.Y == st.velocity.Y).toBeTrue("Velocity.Y must not be NaN")
			Expect(st.velocity.Z == st.velocity.Z).toBeTrue("Velocity.Z must not be NaN")

			-- Dead humanoid must be rejected
			BallService.SetPossessor(1031)
			humV.Health = 0
			local okDeadKick = BallService.ExecuteKick(pVal :: any, "DirectShoot", Vector3.new(0, 0, 1), 0.5)
			Expect(okDeadKick).toBeFalse()
			local okDeadDash = BallService.ExecuteDash(pVal :: any, Vector3.new(0, 0, 1))
			Expect(okDeadDash).toBeFalse()
			local okDeadJump = BallService.ExecuteDirectionalJump(pVal :: any, Vector3.new(0, 0, 1))
			Expect(okDeadJump).toBeFalse()
		end)

		-- F-14: Authoritative Server Charge Enforcement
		SafeTest("TC-P02-32_AuthoritativeServerChargeEnforcement", function()
			local pCharge, charC, rootC, humC = createMockPlayer(1032, "ChargePlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1032, "North")
			BallService.SetPossessor(1032)

			-- 1. StartCharge decelerates walk speed
			local okStart = BallService.StartCharge(pCharge :: any)
			Expect(okStart).toBeTrue()
			Expect(humC.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED * 0.5, 0.5)
			local snapStart = BallService.GetPlayerMovementSnapshot(1032)
			Expect(snapStart.isCharging).toBeTrue()

			-- 2. DirectShoot resolves charge authoritatively and restores speed
			task.wait(0.20)
			local okShoot = BallService.ExecuteKick(pCharge :: any, "DirectShoot", Vector3.new(0, 0, 1))
			Expect(okShoot).toBeTrue()
			Expect(humC.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.5)
			local snapEnd = BallService.GetPlayerMovementSnapshot(1032)
			Expect(snapEnd.isCharging).toBeFalse()

			-- 3. CancelCharge restores speed
			BallService.SetPossessor(1032)
			BallService.StartCharge(pCharge :: any)
			BallService.CancelCharge(pCharge :: any)
			Expect(humC.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.5)
		end)

		-- F-15: Edge fall jump rejection and airborne dash rejection
		SafeTest("TC-P02-33_EdgeFallJumpAndMidAirDashRejection", function()
			local pEdge, charE, rootE, humE = createMockPlayer(1033, "EdgeFallingPlayer", Vector3.new(0, 5.0, 0))
			charE:SetAttribute("IsAirborne", true)

			-- Walking/falling off edge cannot initiate jump
			local okJump = BallService.ExecuteDirectionalJump(pEdge :: any, Vector3.new(0, 0, 1))
			Expect(okJump).toBeFalse()

			-- Walking/falling off edge cannot initiate dash
			local okDash = BallService.ExecuteDash(pEdge :: any, Vector3.new(0, 0, 1))
			Expect(okDash).toBeFalse()
		end)

		-- F-16: Lifecycle reset and team transfer
		SafeTest("TC-P02-34_LifecycleResetAndTeamTransfer", function()
			local pLife, charL, rootL, humL = createMockPlayer(1034, "LifecyclePlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1034, "North")
			BallService.SetPossessor(1034)

			-- 1. Possessor team transfer: changing team updates lastPossessingTeam
			BallService.SetPlayerTeamSide(1034, "South")
			Expect(BallService.GetLastPossessingTeam()).toBe("South")

			-- 2. Character death releases ball and resets movement state
			humL.Health = 0
			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			Expect(st.state).toBe("Free")
			Expect(st.possessorUserId).toBeNil()
		end)

		-- TC-P02-35: Defensive Slide Tackle execution & ball interception
		SafeTest("TC-P02-35_SlideTackleExecutionAndBallInterception", function()
			local pDef, charDef, rootDef, humDef = createMockPlayer(1035, "SlideTackler", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pAtt, charAtt, rootAtt = createMockPlayer(1036, "AttackerHolding", Vector3.new(0, 1.5, 5.0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(1035, "North")
			BallService.SetPlayerTeamSide(1036, "South")
			BallService.SetPossessor(1036)

			-- North is in Defending context
			local snapDef = BallService.GetPlayerMovementSnapshot(1035)
			Expect(snapDef.actionContext).toBe("Defending")

			-- Execute slide tackle towards South attacker (dist 5 studs <= SLIDE_TACKLE_REACH)
			local okSlide = BallService.ExecuteSlide(pDef :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okSlide).toBeTrue()

			-- Check sliding state
			local snapSlide = BallService.GetPlayerMovementSnapshot(1035)
			Expect(snapSlide.isSliding).toBeTrue()
			Expect(humDef.WalkSpeed).toBeCloseTo(Constants.SLIDE_SPEED, 1.0)
			Expect(charDef:GetAttribute("IsSliding")).toBe(true)

			-- Ball intercepted: knocked into free flight away, NO auto-possession by North, NO auto-stun
			local st = BallService.GetBallState()
			Expect(st.possessorUserId).toBeNil()
			Expect(st.state).toBe("InFlight")
			Expect(st.velocity.Z).toBeGreaterThan(60.0)
			Expect(charDef:GetAttribute("IsStunned")).toBeNil()
			Expect(charAtt:GetAttribute("IsStunned")).toBeNil()

			-- Successful tackle does NOT suffer miss penalty after slide duration concludes
			task.wait(Constants.SLIDE_DURATION_SEC + 0.05)
			BallService.StepPhysics(0.05)
			Expect(BallService.IsPlayerSliding(1035)).toBeFalse()
			Expect(humDef.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.5)
		end)

		-- TC-P02-36: Slide tackle miss recovery dampening and cooldown enforcement
		SafeTest("TC-P02-36_SlideTackleMissRecoveryAndCooldown", function()
			local pDef, charDef, rootDef, humDef = createMockPlayer(1037, "SlideMisser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pAtt, charAtt, rootAtt = createMockPlayer(1038, "DistantOpponent", Vector3.new(0, 1.5, 80.0))
			BallService.SetPlayerTeamSide(1037, "North")
			BallService.SetPlayerTeamSide(1038, "South")
			BallService.SetPossessor(1038)

			-- North executes slide with no ball nearby (miss)
			local okSlide = BallService.ExecuteSlide(pDef :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okSlide).toBeTrue()
			Expect(BallService.IsPlayerSliding(1037)).toBeTrue()

			-- Second slide during active slide must be rejected
			local okDouble = BallService.ExecuteSlide(pDef :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okDouble).toBeFalse()

			-- Advance physics past slide duration (Constants.SLIDE_DURATION_SEC = 0.44s)
			task.wait(Constants.SLIDE_DURATION_SEC + 0.05)
			BallService.StepPhysics(0.05)
			Expect(BallService.IsPlayerSliding(1037)).toBeFalse()

			-- During recovery window: walk speed dampened to WALK_SPEED * 0.35, slide rejected
			Expect(humDef.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED * 0.35, 1.0)
			local okDuringRecovery = BallService.ExecuteSlide(pDef :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okDuringRecovery).toBeFalse()
			Expect(charDef:GetAttribute("LastActionRejectReason")).toBe("Recovery")
		end)

		-- TC-P02-37: Slide tackle rejection for Attacking context, airborne state, and low stamina
		SafeTest("TC-P02-37_SlideTackleAirborneAndWrongContextRejection", function()
			local pAir, charAir, rootAir, humAir = createMockPlayer(1039, "SlideAirborne", Vector3.new(0, 1.5, 0))
			local pOther, charO, rootO = createMockPlayer(1040, "OtherPlayer", Vector3.new(0, 1.5, 20.0))
			BallService.SetPlayerTeamSide(1039, "North")
			BallService.SetPlayerTeamSide(1040, "South")

			-- 1. Attacking context rejection (North possesses ball)
			BallService.SetPossessor(1039)
			local okAttSlide = BallService.ExecuteSlide(pAir :: any, Vector3.new(0, 0, 1))
			Expect(okAttSlide).toBeFalse()
			Expect(charAir:GetAttribute("LastActionRejectReason")).toBe("WrongContext")

			-- 2. Airborne rejection (Defending, but jumping/mid-air)
			BallService.SetPossessor(1040)
			charAir:SetAttribute("IsAirborne", true)
			local okAirSlide = BallService.ExecuteSlide(pAir :: any, Vector3.new(0, 0, 1))
			Expect(okAirSlide).toBeFalse()
			Expect(charAir:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")
			charAir:SetAttribute("IsAirborne", false)

			-- 3. Insufficient stamina rejection
			BallService.SetPlayerStamina(1039, 0.10)
			local okLowStam = BallService.ExecuteSlide(pAir :: any, Vector3.new(0, 0, 1))
			Expect(okLowStam).toBeFalse()
			Expect(charAir:GetAttribute("LastActionRejectReason")).toBe("InsufficientStamina")
		end)

		-- TC-P02-38: Table intent protocol idempotency, generation check, and phase transitions
		SafeTest("TC-P02-38_TableIntentProtocolIdempotencyAndPhaseTransition", function()
			local pInt, charInt, rootInt = createMockPlayer(1041, "TableIntentPlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1041, "North")
			BallService.SetPossessor(1041)

			local currentGen = BallService.GetPlayerGeneration(1041)
			local currentCtxVer = BallService.GetPlayerContextVersion(1041)

			-- 1. Stale character generation must be rejected
			BallService.HandleActionRequest(pInt :: any, {
				action = "DirectShoot",
				intentId = "intent_stale_gen",
				phase = "start",
				characterGeneration = currentGen + 5,
				contextVersion = currentCtxVer,
				charge = 0.8,
				aimDirection = Vector3.new(0, 0, 1),
			}, nil, nil)
			Expect(charInt:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charInt:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")

			-- 2. Valid table intent initiates charge
			BallService.HandleActionRequest(pInt :: any, {
				action = "StartCharge",
				intentId = "intent_valid_charge",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
			}, nil, nil)
			Expect(charInt:GetAttribute("IsCharging")).toBe(true)

			-- 3. Duplicate intent with same (intentId, phase) is ignored / rejected as duplicate
			BallService.HandleActionRequest(pInt :: any, {
				action = "StartCharge",
				intentId = "intent_valid_charge",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
			}, nil, nil)
			Expect(charInt:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")

			-- 4. Release phase completes action idempotently
			BallService.HandleActionRequest(pInt :: any, {
				action = "DirectShoot",
				intentId = "intent_valid_charge",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
				charge = 1.0,
				aimDirection = Vector3.new(0, 0, 1),
			}, nil, nil)
			local st = BallService.GetBallState()
			Expect(st.state).toBe("InFlight")
			Expect(charInt:GetAttribute("IsCharging")).toBe(false)

			-- 5. Terminal intent rejects subsequent cancel/start/release phases
			BallService.HandleActionRequest(pInt :: any, {
				action = "CancelCharge",
				intentId = "intent_valid_charge",
				phase = "cancel",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
			}, nil, nil)
			Expect(charInt:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charInt:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")

			-- 6. Instant actions (Dash) cannot be repeated with same intentId across phases
			local pDash, charDash = createMockPlayer(1042, "InstantDashPlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1042, "North")
			BallService.HandleActionRequest(pDash :: any, {
				action = "Dash",
				intentId = "intent_instant_dash",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0, 0, 1),
			}, nil, nil)
			Expect(charDash:GetAttribute("LastActionStatus")).toBe("Accepted")

			BallService.HandleActionRequest(pDash :: any, {
				action = "Dash",
				intentId = "intent_instant_dash",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0, 0, 1),
			}, nil, nil)
			Expect(charDash:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charDash:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")
		end)

		-- TC-P02-39: Ball turnover cancels pending charge and increments contextVersion
		SafeTest("TC-P02-39_ContextChangeCancelsPendingCharge", function()
			local pTurn1, charTurn1, rootTurn1, humTurn1 = createMockPlayer(1043, "ContextFlipPlayer", Vector3.new(0, 1.5, 0))
			local pTurn2, charTurn2, rootTurn2 = createMockPlayer(1044, "ContextFlipOpponent", Vector3.new(0, 1.5, 20.0))
			BallService.SetPlayerTeamSide(1043, "North")
			BallService.SetPlayerTeamSide(1044, "South")
			BallService.SetPossessor(1043)

			local verBefore = BallService.GetPlayerContextVersion(1043)

			-- North begins charging Shoot
			local okStart = BallService.StartCharge(pTurn1 :: any, "DirectShoot")
			Expect(okStart).toBeTrue()
			Expect(charTurn1:GetAttribute("IsCharging")).toBe(true)
			Expect(humTurn1.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED * 0.5, 0.5)

			-- Context flip: South intercepts ball possession
			BallService.SetPossessor(1044)

			-- North's charge must be immediately cancelled and contextVersion incremented
			Expect(charTurn1:GetAttribute("IsCharging")).toBe(false)
			Expect(humTurn1.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.5)
			local verAfter = BallService.GetPlayerContextVersion(1043)
			Expect(verAfter).toBeGreaterThan(verBefore)
		end)

		-- TC-P02-40: Tapered vertical charge gauge GUI hierarchy & R6 slide procedural provenance (F-17 & F-21)
		SafeTest("TC-P02-40_TaperedChargeGaugeAndR6SlideProceduralProvenance", function()
			-- 1. Verify PlayerActionPoseConfigs contains procedural R6 slide pose with distinct joint offsets
			local slidePose = PlayerActionPoseConfigs.GetSlidePose()
			Expect(slidePose).toNotBeNil()
			Expect(slidePose.RootJoint.Position.Y).toBeCloseTo(-0.92, 0.05)
			Expect(slidePose.RightHip.Position.Z).toBeCloseTo(-0.62, 0.05)
			Expect(PlayerActionPoseConfigs.PROVENANCE.sourceFootballClient).toBe("client/FootballClient.client.luau:1982-2273")

			-- 2. Verify TrainingHUD creates tapered KickChargeGaugeBg with 10 segments and ShiftLockReticle
			local testGuiParent = Instance.new("Folder")
			testGuiParent.Name = "TestGuiParent"
			testGuiParent.Parent = Workspace

			local screenGui = TrainingHUD.CreateScreenGui(testGuiParent)
			Expect(screenGui).toNotBeNil()

			local gaugeBg = screenGui:FindFirstChild("KickChargeGaugeBg") :: Frame?
			Expect(gaugeBg).toNotBeNil()
			Expect(gaugeBg.Size).toBe(UDim2.fromOffset(76, 114))

			local expectedWidths = { 16, 20, 24, 28, 32, 36, 40, 44, 49, 56 }
			for i = 1, 10 do
				local segName = string.format("Seg_%02d", i)
				local seg = gaugeBg:FindFirstChild(segName) :: Frame?
				Expect(seg).toNotBeNil()
				Expect(seg.Size.X.Offset).toBe(expectedWidths[i])
				local fill = seg:FindFirstChild("Fill")
				Expect(fill).toNotBeNil()
			end

			local reticle = screenGui:FindFirstChild("ShiftLockReticle") :: Frame?
			Expect(reticle).toNotBeNil()

			local controls = screenGui:FindFirstChild("HUDContainer"):FindFirstChild("ControlsLabel") :: TextLabel?
			Expect(controls).toNotBeNil()
			Expect(string.find(controls.Text, "Lob")).toBeNil("Lob must be removed from controls guide")
			Expect(string.find(controls.Text, "Shift Lock")).toNotBeNil("Shift Lock must be in controls guide")

			local codexModal = screenGui:FindFirstChild("ControlsCodexModal") :: Frame?
			Expect(codexModal).toNotBeNil()
			Expect(codexModal.Visible).toBeFalse("Controls Codex modal must be hidden by default")

			local codexToggleBtn = screenGui:FindFirstChild("HUDContainer"):FindFirstChild("CodexToggleBtn") :: TextButton?
			Expect(codexToggleBtn).toNotBeNil()

			testGuiParent:Destroy()
		end)

		-- TC-P02-41: Remote payload strict schema validation (F-13)
		SafeTest("TC-P02-41_RemotePayloadStrictSchemaValidation", function()
			local pSchema, charSchema, rootSchema = createMockPlayer(1045, "SchemaTestPlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1045, "North")
			BallService.SetPossessor(1045)

			local currentGen = BallService.GetPlayerGeneration(1045)
			local currentCtxVer = BallService.GetPlayerContextVersion(1045)

			-- 1. Non-table string payload must be rejected without creating random intent
			BallService.HandleActionRequest(pSchema :: any, "DirectShoot" :: any, nil, nil)
			Expect(charSchema:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charSchema:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")

			-- 2. Missing intentId must be rejected
			BallService.HandleActionRequest(pSchema :: any, {
				action = "DirectShoot",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0, 0, 1),
				charge = 0.5,
			}, nil, nil)
			Expect(charSchema:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charSchema:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")

			-- 3. Non-finite aimDirection (NaN) must be rejected
			BallService.HandleActionRequest(pSchema :: any, {
				action = "DirectShoot",
				intentId = "intent_nan_aim",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0/0, 0, 1),
				charge = 0.5,
			}, nil, nil)
			Expect(charSchema:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charSchema:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")

			-- 4. Non-finite charge (Inf) must be rejected
			BallService.HandleActionRequest(pSchema :: any, {
				action = "DirectShoot",
				intentId = "intent_inf_chg",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0, 0, 1),
				charge = math.huge,
			}, nil, nil)
			Expect(charSchema:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charSchema:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")

			-- 5. Invalid phase must be rejected
			BallService.HandleActionRequest(pSchema :: any, {
				action = "DirectShoot",
				intentId = "intent_bad_phase",
				phase = "invalid_phase" :: any,
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				aimDirection = Vector3.new(0, 0, 1),
				charge = 0.5,
			}, nil, nil)
			Expect(charSchema:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charSchema:GetAttribute("LastActionRejectReason")).toBe("InvalidPayload")
		end)

		-- TC-P02-42: Charge intent latching and action mismatch rejection (F-14)
		SafeTest("TC-P02-42_ChargeIntentLatchingAndActionMismatchRejection", function()
			local pMismatch, charMismatch, rootMismatch = createMockPlayer(1046, "MismatchChargePlayer", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1046, "North")
			BallService.SetPossessor(1046)

			local currentGen = BallService.GetPlayerGeneration(1046)
			local currentCtxVer = BallService.GetPlayerContextVersion(1046)

			-- 1. Start charge latches intent and action
			BallService.HandleActionRequest(pMismatch :: any, {
				action = "StartCharge",
				intentId = "intent_latch_shoot",
				phase = "start",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
			}, nil, nil)
			Expect(charMismatch:GetAttribute("IsCharging")).toBe(true)

			-- 2. Release with mismatched action (Pass instead of DirectShoot) must be rejected
			BallService.HandleActionRequest(pMismatch :: any, {
				action = "Pass",
				intentId = "intent_latch_shoot",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "Pass",
				aimDirection = Vector3.new(1, 0, 0),
				charge = 0.8,
			}, nil, nil)
			Expect(charMismatch:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charMismatch:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")

			-- 3. Release with mismatched intentId must be rejected
			BallService.HandleActionRequest(pMismatch :: any, {
				action = "DirectShoot",
				intentId = "intent_unlatched_other",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
				aimDirection = Vector3.new(0, 0, 1),
				charge = 0.8,
			}, nil, nil)
			Expect(charMismatch:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charMismatch:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")

			-- 4. Matching release succeeds idempotently
			BallService.HandleActionRequest(pMismatch :: any, {
				action = "DirectShoot",
				intentId = "intent_latch_shoot",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
				aimDirection = Vector3.new(0, 0, 1),
				charge = 0.8,
			}, nil, nil)
			local st = BallService.GetBallState()
			Expect(st.state).toBe("InFlight")
			Expect(charMismatch:GetAttribute("IsCharging")).toBe(false)

			-- 5. Terminal intent replay must be rejected
			BallService.HandleActionRequest(pMismatch :: any, {
				action = "DirectShoot",
				intentId = "intent_latch_shoot",
				phase = "release",
				characterGeneration = currentGen,
				contextVersion = currentCtxVer,
				chargeAction = "DirectShoot",
				aimDirection = Vector3.new(0, 0, 1),
				charge = 0.8,
			}, nil, nil)
			Expect(charMismatch:GetAttribute("LastActionStatus")).toBe("Rejected")
			Expect(charMismatch:GetAttribute("LastActionRejectReason")).toBe("StaleIntent")
		end)

		-- TC-P02-43: Slide tackle hit does not mutate attacking team context (F-20)
		SafeTest("TC-P02-43_SlideTackleDoesNotMutateAttackingTeamContext", function()
			local pAtt, charAtt, rootAtt = createMockPlayer(1047, "SlideContextAttacker", Vector3.new(0, 1.5, 5.0), Vector3.new(0, 0, -1))
			local pDef, charDef, rootDef = createMockPlayer(1048, "SlideContextDefender", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))

			BallService.SetPlayerTeamSide(1047, "North")
			BallService.SetPlayerTeamSide(1048, "South")
			BallService.SetPossessor(1047)

			Expect(BallService.GetLastPossessingTeam()).toBe("North")
			Expect(BallService.GetPlayerActionContext(1047)).toBe("Attacking")
			Expect(BallService.GetPlayerActionContext(1048)).toBe("Defending")

			-- South executes slide tackle hitting the ball
			local okSlide = BallService.ExecuteSlide(pDef :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okSlide).toBeTrue()

			local st = BallService.GetBallState()
			Expect(st.state).toBe("InFlight")
			Expect(st.possessorUserId).toBeNil()

			-- F-20: Slide tackle hit MUST NOT transfer lastPossessingTeam or mutate team contexts!
			Expect(BallService.GetLastPossessingTeam()).toBe("North")
			Expect(BallService.GetPlayerActionContext(1047)).toBe("Attacking")
			Expect(BallService.GetPlayerActionContext(1048)).toBe("Defending")

			-- Only confirmed possession transfers team attacking context
			BallService.SetPossessor(1048)
			Expect(BallService.GetLastPossessingTeam()).toBe("South")
			Expect(BallService.GetPlayerActionContext(1047)).toBe("Defending")
			Expect(BallService.GetPlayerActionContext(1048)).toBe("Attacking")
		end)

		-- TC-P02-44: Dash rejected during slide and recovery window (F-23)
		SafeTest("TC-P02-44_DashRejectedDuringSlideAndRecoveryWindow", function()
			local pDashLock, charDashLock, rootDashLock = createMockPlayer(1049, "DashSlideLockPlayer", Vector3.new(0, 1.5, 0))
			local pOpp, charOpp = createMockPlayer(1050, "OppPossessor44", Vector3.new(0, 1.5, 50))
			BallService.SetPlayerTeamSide(1049, "South")
			BallService.SetPlayerTeamSide(1050, "North")
			BallService.SetPossessor(1050)
			BallService.SetPlayerStamina(1049, 1.0)

			-- Execute slide tackle (whiff)
			local okSlide = BallService.ExecuteSlide(pDashLock :: any, Vector3.new(0, 0, 1), 0.5)
			Expect(okSlide).toBeTrue()
			Expect(BallService.IsPlayerSliding(1049)).toBeTrue()

			-- 1. Dash during active slide must return false
			local okDash1 = BallService.ExecuteDash(pDashLock :: any, Vector3.new(0, 0, 1))
			Expect(okDash1).toBeFalse()

			-- 2. Advance physics past slide duration into recovery window
			task.wait(Constants.SLIDE_DURATION_SEC + 0.05)
			BallService.StepPhysics(0.05)
			Expect(BallService.IsPlayerSliding(1049)).toBeFalse()
			Expect(BallService.IsPlayerInSlideRecovery(1049)).toBeTrue()

			-- Dash during recovery must return false
			local okDash2 = BallService.ExecuteDash(pDashLock :: any, Vector3.new(0, 0, 1))
			Expect(okDash2).toBeFalse()

			-- 3. Advance past recovery window
			task.wait(Constants.SLIDE_RECOVERY_SEC + 0.05)
			BallService.StepPhysics(0.05)
			Expect(BallService.IsPlayerInSlideRecovery(1049)).toBeFalse()

			-- Dash now succeeds
			local okDash3 = BallService.ExecuteDash(pDashLock :: any, Vector3.new(0, 0, 1))
			Expect(okDash3).toBeTrue()
		end)

		-- TC-P02-45: Ball upward rebound from floor preserved against premature ground settling (F-24)
		SafeTest("TC-P02-45_FloorUpwardReboundPreservedAgainstPrematureGroundSettling", function()
			BallService.ResetBall()

			-- High downward velocity collision into floor
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 2.0, 0), Vector3.new(0, -60.0, 0))

			BallService.StepPhysics(0.05)

			local st = BallService.GetBallState()
			-- Collision solver produces positive upward rebound which must NOT be zeroed out
			Expect(st.velocity.Y).toBeGreaterThan(15.0, "Floor rebound must preserve positive upward vertical velocity")
			Expect(st.state).toBe("Free")
		end)
	end)

	Describe("T1_PlayerActions_DiscreteJumpAndResolvedOutcomes", function()
		-- TC-P02-46: Discrete Jump Key Release Guard (F-28)
		SafeTest("TC-P02-46_DiscreteJumpReleaseGuard", function()
			local pJumper, charJ, rootJ, humJ = createMockPlayer(1051, "DiscreteJumper", Vector3.new(0, 1.5, 0))
			BallService.SetPlayerTeamSide(1051, "North")

			-- 1. First jump: successfully executes
			local okJump1 = BallService.ExecuteDirectionalJump(pJumper :: any, Vector3.new(0, 0, 1))
			Expect(okJump1).toBeTrue("First directional jump must succeed")
			local snap1 = BallService.GetPlayerMovementSnapshot(1051)
			Expect(snap1.isAirborne).toBeTrue("Player must be airborne after jump")
			Expect(charJ:GetAttribute("IsAirborne")).toBe(true, "Character IsAirborne attribute must be true")

			-- 2. Immediate second jump while still in airborne state: must be rejected
			local okJump2 = BallService.ExecuteDirectionalJump(pJumper :: any, Vector3.new(0, 0, 1))
			Expect(okJump2).toBeFalse("Subsequent jump while airborne must be rejected")

			-- 3. Simulate landing: floor seam contact clears airborne state
			task.wait(0.20)
			rootJ.CFrame = CFrame.new(0, 0.5, 0)
			BallService.StepPhysics(0.05)
			local snapLanded = BallService.GetPlayerMovementSnapshot(1051)
			Expect(snapLanded.isAirborne).toBeFalse("Player must land on ground")

			-- 4. Jump after clean landing executes successfully
			local okJump3 = BallService.ExecuteDirectionalJump(pJumper :: any, Vector3.new(0, 0, 1))
			Expect(okJump3).toBeTrue("Jump after landing must succeed")
		end)

		-- TC-P02-47: Curve Shot Foot and Style Resolution (F-29)
		SafeTest("TC-P02-47_CurveShotFootAndStyleResolution", function()
			local pCurver, charC, rootC = createMockPlayer(1052, "ResolvedCurver", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(1052, "North")
			BallService.SetPossessor(1052)

			-- Case A: Right foot, Finesse (ball at X = +1.5, aiming left)
			BallService.SetBallPositionAndVelocity(Vector3.new(1.5, 1.25, 0), Vector3.zero)
			local aimLeft = Vector3.new(-0.6, 0, -1).Unit
			local okFinesseR = BallService.ExecuteKick(pCurver :: any, "CurveShoot", aimLeft, 0.75, "intent_fin_r")
			Expect(okFinesseR).toBeTrue()
			Expect(charC:GetAttribute("LastResolvedAction")).toBe("CurveShoot")
			Expect(charC:GetAttribute("ResolvedKickFoot")).toBe("Right")
			Expect(charC:GetAttribute("ResolvedCurveStyle")).toBe("Finesse")

			-- Case B: Right foot, Trivela (ball at X = +1.5, aiming right)
			BallService.SetPossessor(1052)
			BallService.SetBallPositionAndVelocity(Vector3.new(1.5, 1.25, 0), Vector3.zero)
			local aimRight = Vector3.new(0.6, 0, -1).Unit
			local okTrivelaR = BallService.ExecuteKick(pCurver :: any, "CurveShoot", aimRight, 0.75, "intent_triv_r")
			Expect(okTrivelaR).toBeTrue()
			Expect(charC:GetAttribute("LastResolvedAction")).toBe("CurveShoot")
			Expect(charC:GetAttribute("ResolvedKickFoot")).toBe("Right")
			Expect(charC:GetAttribute("ResolvedCurveStyle")).toBe("Trivela")

			-- Case C: Left foot, Finesse (ball at X = -1.5, aiming right)
			BallService.SetPossessor(1052)
			BallService.SetBallPositionAndVelocity(Vector3.new(-1.5, 1.25, 0), Vector3.zero)
			local okFinesseL = BallService.ExecuteKick(pCurver :: any, "CurveShoot", aimRight, 0.75, "intent_fin_l")
			Expect(okFinesseL).toBeTrue()
			Expect(charC:GetAttribute("LastResolvedAction")).toBe("CurveShoot")
			Expect(charC:GetAttribute("ResolvedKickFoot")).toBe("Left")
			Expect(charC:GetAttribute("ResolvedCurveStyle")).toBe("Finesse")

			-- Case D: Left foot, Trivela (ball at X = -1.5, aiming left)
			BallService.SetPossessor(1052)
			BallService.SetBallPositionAndVelocity(Vector3.new(-1.5, 1.25, 0), Vector3.zero)
			local okTrivelaL = BallService.ExecuteKick(pCurver :: any, "CurveShoot", aimLeft, 0.75, "intent_triv_l")
			Expect(okTrivelaL).toBeTrue()
			Expect(charC:GetAttribute("LastResolvedAction")).toBe("CurveShoot")
			Expect(charC:GetAttribute("ResolvedKickFoot")).toBe("Left")
			Expect(charC:GetAttribute("ResolvedCurveStyle")).toBe("Trivela")
		end)

		-- TC-P02-48: Acrobatic Bicycle Kick Resolution and Flight Lifecycle (F-28 & F-29)
		SafeTest("TC-P02-48_BicycleKickLandingLifecycle", function()
			local pAcro, charA, rootA = createMockPlayer(1053, "BicycleAcrobat", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(1053, "South")
			BallService.SetPossessor(1053)

			-- 1. Jump launch into airborne flight
			local okJump = BallService.ExecuteDirectionalJump(pAcro :: any, Vector3.new(0, 0, 1))
			Expect(okJump).toBeTrue("Player must launch into directional jump")
			local snapAir = BallService.GetPlayerMovementSnapshot(1053)
			Expect(snapAir.isAirborne).toBeTrue("Player must be in airborne flight")

			-- 2. Move to mid-air height and place loose ball above/in-reach of player
			rootA.CFrame = CFrame.lookAt(Vector3.new(0, 4.2, 0), Vector3.new(0, 4.2, 1.0))
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 4.5, 1.0), Vector3.zero)

			-- 3. Airborne kicker executes BicycleKick
			local okBicycle = BallService.ExecuteKick(pAcro :: any, "BicycleKick", Vector3.new(0, 0, 1), 0.85, "intent_bike_01")
			Expect(okBicycle).toBeTrue("Bicycle kick execution must succeed")
			local stBike = BallService.GetBallState()
			Expect(stBike.inFlightAction).toBe("BicycleKick")
			Expect(charA:GetAttribute("LastResolvedAction")).toBe("BicycleKick")

			-- 4. Verify Bicycle Kick inverted pose properties
			local bikePose = PlayerActionPoseConfigs.GetFollowThroughPose("BicycleKick", 0.5)
			Expect(bikePose.RootJoint).toNotBeNil()
			local rx, _, _ = bikePose.RootJoint:ToEulerAnglesXYZ()
			Expect(math.abs(rx)).toBeGreaterThan(1.5, "Bicycle kick pose must be inverted acrobatic posture")

			-- 5. Verify Airborne Recovery pose properties (turf breakfall cushion)
			local recoveryPose = PlayerActionPoseConfigs.GetAirborneRecoveryPose(0.5)
			Expect(recoveryPose.RootJoint).toNotBeNil()
			Expect(recoveryPose.RootJoint.Position.Y).toBeLessThan(0.0, "Recovery pose must dip center of mass to turf")

			-- 6. Land player on floor: contact clears airborne state cleanly without upright snapping
			task.wait(0.20)
			rootA.CFrame = CFrame.new(0, 0.5, 0)
			BallService.StepPhysics(0.05)
			local snapAcro = BallService.GetPlayerMovementSnapshot(1053)
			Expect(snapAcro.isAirborne).toBeFalse("Airborne state must be cleared on landing")
		end)

		-- TC-P02-49: Curve Shoot Plant Leg Grounding Verification (F-29)
		SafeTest("TC-P02-49_PlantLegGroundingDuringCurveWindup", function()
			-- 1. Evaluate Charge Pose for CurveShoot Finesse
			local chargeFinesse = PlayerActionPoseConfigs.GetChargePose("CurveShoot", 0.32, "Finesse")
			Expect(chargeFinesse.LeftHip).toNotBeNil()
			Expect(chargeFinesse.RightHip).toNotBeNil()
			Expect(chargeFinesse.RootJoint).toNotBeNil()

			-- Left plant leg must maintain counter-roll to remain grounded against torso side lean
			local _, _, rzFin = chargeFinesse.RootJoint:ToEulerAnglesXYZ()
			local _, _, lzFin = chargeFinesse.LeftHip:ToEulerAnglesXYZ()
			Expect(math.abs(lzFin)).toBeGreaterThan(0.01, "Left plant leg must apply counter-roll against torso lean")
			Expect(math.abs(rzFin + lzFin)).toBeLessThan(0.05, "Plant leg net coronal tilt must cancel torso roll to stay grounded")
			Expect(chargeFinesse.RootJoint.Position.Y).toBeGreaterThan(-0.15, "RootJoint translation must maintain plant foot above floor boundary")

			-- 2. Evaluate Charge Pose for CurveShoot Trivela
			local chargeTrivela = PlayerActionPoseConfigs.GetChargePose("CurveShoot", 0.32, "Trivela")
			Expect(chargeTrivela.LeftHip).toNotBeNil()
			Expect(chargeTrivela.RightHip).toNotBeNil()
			Expect(chargeTrivela.RootJoint).toNotBeNil()
			local _, _, rzTriv = chargeTrivela.RootJoint:ToEulerAnglesXYZ()
			local _, _, lzTriv = chargeTrivela.LeftHip:ToEulerAnglesXYZ()
			Expect(math.abs(lzTriv)).toBeGreaterThan(0.01, "Left plant leg must apply counter-roll in Trivela windup")
			Expect(math.abs(rzTriv + lzTriv)).toBeLessThan(0.05, "Trivela plant leg net coronal tilt must cancel torso roll")

			-- 3. Evaluate Follow-Through Pose for CurveShoot Finesse
			local followFinesse = PlayerActionPoseConfigs.GetFollowThroughPose("CurveShoot", 0.5, "Finesse")
			Expect(followFinesse.LeftHip).toNotBeNil()
			local _, _, frzFin = followFinesse.RootJoint:ToEulerAnglesXYZ()
			local _, _, flzFin = followFinesse.LeftHip:ToEulerAnglesXYZ()
			Expect(math.abs(flzFin)).toBeGreaterThan(0.01, "Left plant leg must apply counter-roll during follow-through")
			Expect(math.abs(frzFin + flzFin)).toBeLessThan(0.05, "Finesse follow-through plant leg net tilt must cancel torso roll")

			-- 4. Evaluate Follow-Through Pose for CurveShoot Trivela
			local followTrivela = PlayerActionPoseConfigs.GetFollowThroughPose("CurveShoot", 0.5, "Trivela")
			Expect(followTrivela.LeftHip).toNotBeNil()
			local _, _, frzTriv = followTrivela.RootJoint:ToEulerAnglesXYZ()
			local _, _, flzTriv = followTrivela.LeftHip:ToEulerAnglesXYZ()
			Expect(math.abs(flzTriv)).toBeGreaterThan(0.01, "Left plant leg must apply counter-roll during Trivela follow-through")
			Expect(math.abs(frzTriv + flzTriv)).toBeLessThan(0.05, "Trivela follow-through plant leg net tilt must cancel torso roll")
		end)

		-- TC-P02-50: Dynamic Airborne Jump Trajectory Phase Mapping (F-28)
		SafeTest("TC-P02-50_DynamicAirborneJumpTrajectoryPhaseMapping", function()
			-- 1. Ascent Phase (vy > 0): Arms drive upward, hip coiling forward
			local ascentPose = PlayerActionPoseConfigs.GetJumpPose(50.0)
			Expect(ascentPose).toNotBeNil()
			local rShoulderAscent = ascentPose.RightShoulder
			local rxAsc, _, _ = rShoulderAscent:ToEulerAnglesXYZ()
			Expect(rxAsc).toBeGreaterThan(math.rad(45.0), "Ascent phase must drive arms upward (rx > 45 deg)")

			-- 2. Apex Phase (vy ≈ 0): Balanced hang-time stance
			local apexPose = PlayerActionPoseConfigs.GetJumpPose(0.0)
			Expect(apexPose).toNotBeNil()

			-- 3. Descent Phase (vy < 0): Arms counter-balance downward/outward
			local descentPose = PlayerActionPoseConfigs.GetJumpPose(-50.0)
			Expect(descentPose).toNotBeNil()
			local rShoulderDesc = descentPose.RightShoulder
			local rxDesc, _, _ = rShoulderDesc:ToEulerAnglesXYZ()
			Expect(rxDesc).toBeLessThan(rxAsc, "Descent phase shoulder angle must be lower than ascent phase")

			-- 4. Default / Backward compatibility (verticalVelocity is nil) returns apex pose
			local defaultJump = PlayerActionPoseConfigs.GetJumpPose()
			Expect(defaultJump).toNotBeNil()
			local rxDef, _, _ = defaultJump.RightShoulder:ToEulerAnglesXYZ()
			local rxApex, _, _ = apexPose.RightShoulder:ToEulerAnglesXYZ()
			Expect(math.abs(rxDef - rxApex)).toBeLessThan(0.01, "Nil vertical velocity must default to apex pose")
		end)

		-- TC-P02-51: Authored Locomotion & Slide Timeline Progression (F-21)
		SafeTest("TC-P02-51_AuthoredLocomotionAndSlideTimelineProgression", function()
			-- 1. A04 Dash Burst timeline
			local dashEntry = PlayerActionPoseConfigs.GetDashPose(0.0)
			local dashPeak = PlayerActionPoseConfigs.GetDashPose(0.5)
			local dashExit = PlayerActionPoseConfigs.GetDashPose(1.0)
			Expect(dashEntry).toNotBeNil()
			Expect(dashPeak).toNotBeNil()
			Expect(dashExit).toNotBeNil()

			-- 2. A17 Slide Tackle timeline progression
			local slideEntry = PlayerActionPoseConfigs.GetSlidePose(0.0)
			local slideActive = PlayerActionPoseConfigs.GetSlidePose(0.38)
			local slideExit = PlayerActionPoseConfigs.GetSlidePose(1.0)
			Expect(slideEntry).toNotBeNil()
			Expect(slideActive).toNotBeNil()
			Expect(slideExit).toNotBeNil()
			-- Active slide authored keyframe has dropped torso (-1.027 studs), sweeping lead leg, and contact phase
			local kfActive = PlayerActionPoseConfigs.SampleAuthoredKeyframe("A17", 0.38)
			Expect(kfActive["RootJoint"].pos.Y).toBeLessThan(0, "Authored active slide RootJoint must have lowered torso position")
			local rHipSpec = kfActive["Right Hip"] or kfActive["RightHip"]
			Expect(rHipSpec).toNotBeNil("Right Hip spec must exist in active slide keyframe")
			Expect(rHipSpec.rotDeg.X).toBeGreaterThan(0, "Authored lead leg must be pitched forward for sweeping tackle")
			local animA17 = PlayerActionPoseConfigs.ANIMATIONS["A17"]
			Expect(animA17).toNotBeNil("A17 animation spec must be registered")
			Expect(animA17.contactPhase).toBe(0.38, "Active slide ball contact phase must be calibrated at t = 0.38")
			Expect(animA17.nextAnimOnComplete).toBe("A18", "A17 slide must hand off to A18 recovery")

			-- 3. A01 Idle, A02 Walk, A03 Sprint, A05 Strafe authored poses exist and sample correctly
			local idlePose = PlayerActionPoseConfigs.SampleAuthoredPose("A01", 0.5)
			local walkPose = PlayerActionPoseConfigs.SampleAuthoredPose("A02", 0.5)
			local sprintPose = PlayerActionPoseConfigs.SampleAuthoredPose("A03", 0.5)
			local strafePose = PlayerActionPoseConfigs.Get8WayStrafePose(Vector3.new(1, 0, 0), math.pi)
			Expect(idlePose).toNotBeNil()
			Expect(walkPose).toNotBeNil()
			Expect(sprintPose).toNotBeNil()
			Expect(strafePose).toNotBeNil()
		end)
	end)

	cleanupAllMockPlayers()
end

return runPlayerActionsTests
