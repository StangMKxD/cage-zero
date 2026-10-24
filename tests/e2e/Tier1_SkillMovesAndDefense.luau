--!strict
-- tests/e2e/Tier1_SkillMovesAndDefense.luau
-- E2E Test Suite for Module 03: 5 Skill Moves, 3 Slots, Quick Poke, Cage Press & Slide Reuse
-- Governed by: docs/plan/phase-01-gameplay-demo/03-dribble-duel/assets/HANDOFF.md & Spec 02

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))
local Configs = Shared:WaitForChild("configs")
local SkillMoveConfigs = require(Configs:WaitForChild("SkillMoveConfigs"))
local PlayerActionPoseConfigs = require(Configs:WaitForChild("PlayerActionPoseConfigs"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local BallService = require(Services:WaitForChild("BallService"))
local SkillMoveService = require(Services:WaitForChild("SkillMoveService"))
local DuelEngineService = require(Services:WaitForChild("DuelEngineService"))

local function runSkillMovesAndDefenseTests(TestHarness: any)
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

		local folder = Workspace:FindFirstChild("__TestSkillDefenseMocks")
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
			if SkillMoveService.ClearAllStatesForTesting then
				SkillMoveService.ClearAllStatesForTesting()
			end
			BallService.ResetBall()
			if not ok then
				error(err)
			end
		end)
	end

	local function createMockPlayer(userId: number, name: string, pos: Vector3, look: Vector3?): (any, Model, Part, Humanoid)
		local folder = Workspace:FindFirstChild("__TestSkillDefenseMocks")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "__TestSkillDefenseMocks"
			folder.Parent = Workspace
		end

		local lookDir = look or Vector3.new(0, 0, 1)
		local char = Instance.new("Model")
		char.Name = name .. "_" .. tostring(userId)

		local hrp = Instance.new("Part")
		hrp.Name = "HumanoidRootPart"
		hrp.Size = Vector3.new(2, 2, 1)
		hrp.Position = pos
		hrp.CFrame = CFrame.lookAt(pos, pos + lookDir)
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
		rootJoint.Parent = hrp

		local hum = Instance.new("Humanoid")
		hum.MaxHealth = 100
		hum.Health = 100
		hum.WalkSpeed = Constants.WALK_SPEED
		hum.Parent = char

		char.Parent = folder
		createdMocks[userId] = char
		BallService.SetPlayerCharacterOverride(userId, char)

		local mockPlayerObj = {
			UserId = userId,
			Name = char.Name,
			Character = char,
		}
		return mockPlayerObj, char, hrp, hum
	end

	Describe("T1_Plan03_SkillMovesAndDefense", function()
		SafeTest("TC-P03-15_CatalogDirectionPolicy_UsesCharacterRelativeSides", function()
			local heavy = SkillMoveConfigs.GetSkill("HeavyKnockOn")
			local openUp = SkillMoveConfigs.GetSkill("OpenUpFakeShot")
			local bodyFeint = SkillMoveConfigs.GetSkill("BodyFeint")
			local heelChop = SkillMoveConfigs.GetSkill("HeelChop")
			local laneChange = SkillMoveConfigs.GetSkill("LaneChange")
			local elastico = SkillMoveConfigs.GetSkill("Elastico")
			local sombrero = SkillMoveConfigs.GetSkill("SombreroFlick")
			Expect(heavy ~= nil).toBeTrue()
			Expect(openUp ~= nil).toBeTrue()
			Expect(bodyFeint ~= nil).toBeTrue()
			Expect(heelChop ~= nil).toBeTrue()
			Expect(laneChange ~= nil).toBeTrue()
			Expect(elastico ~= nil).toBeTrue()
			Expect(sombrero ~= nil).toBeTrue()
			Expect(SkillMoveConfigs.GetSkill("DragBackTurn")).toBeNil()
			Expect(SkillMoveConfigs.GetSkill("LaCroqueta")).toBeNil()

			local facing = CFrame.lookAt(Vector3.zero, Vector3.new(1, 0, 0))
			local right = Vector3.new(0, 0, 1)
			local leftDirection, leftSide = SkillMoveConfigs.ResolveCharacterRelativeDirection(bodyFeint :: any, -right, -right, facing)
			local rightDirection, rightSide = SkillMoveConfigs.ResolveCharacterRelativeDirection(bodyFeint :: any, right, right, facing)
			Expect(leftSide).toBe(-1)
			Expect(rightSide).toBe(1)
			Expect(leftDirection.X).toBeGreaterThan(0.99)
			Expect(rightDirection.X).toBeGreaterThan(0.99)
			Expect((bodyFeint :: any).directionPolicy).toBe("LateralCut")
			Expect((heelChop :: any).directionPolicy).toBe("LateralCut")
			Expect((laneChange :: any).directionPolicy).toBe("LateralCut")
			Expect((elastico :: any).directionPolicy).toBe("LateralCut")
			Expect((sombrero :: any).directionPolicy).toBe("LiftForward")
			Expect((sombrero :: any).contactStages[1].vertical).toBe(1)
			local leftPose = PlayerActionPoseConfigs.GetSkillMovePose("BodyFeint", 0.55, Vector3.new(-1, 0, 0))
			local rightPose = PlayerActionPoseConfigs.GetSkillMovePose("BodyFeint", 0.55, Vector3.new(1, 0, 0))
			Expect(leftPose.RootJoint.Position.X).toBeLessThan(rightPose.RootJoint.Position.X)
		end)
		-- TC-P03-01: Catalog of 7 moves, starter 5-star ceiling, 3 slots, and loadout validation
		SafeTest("TC-P03-01_CatalogAndThreeSlotLoadoutValidation", function()
			local m1 = SkillMoveConfigs.GetSkill("HeavyKnockOn")
			local m2 = SkillMoveConfigs.GetSkill("OpenUpFakeShot")
			local m3 = SkillMoveConfigs.GetSkill("BodyFeint")
			local m4 = SkillMoveConfigs.GetSkill("HeelChop")
			local m5 = SkillMoveConfigs.GetSkill("LaneChange")
			local m6 = SkillMoveConfigs.GetSkill("SombreroFlick")
			local m7 = SkillMoveConfigs.GetSkill("Elastico")

			Expect(m1 ~= nil and m1.starRating == 1).toBeTrue()
			Expect(m2 ~= nil and m2.starRating == 1).toBeTrue()
			Expect(m3 ~= nil and m3.starRating == 2).toBeTrue()
			Expect(m4 ~= nil and m4.starRating == 3).toBeTrue()
			Expect(m5 ~= nil and m5.starRating == 4).toBeTrue()
			Expect(m6 ~= nil and m6.starRating == 4).toBeTrue()
			Expect(m7 ~= nil and m7.starRating == 5).toBeTrue()

			-- Retired skills are absent from catalog
			Expect(SkillMoveConfigs.GetSkill("DragBackTurn")).toBeNil()
			Expect(SkillMoveConfigs.GetSkill("LaCroqueta")).toBeNil()

			-- Starter player has 5-star ceiling and default 3-slot loadout [HeavyKnockOn, BodyFeint, SombreroFlick]
			local uid = 3001
			createMockPlayer(uid, "Starter5Star", Vector3.new(0, 1.5, 0))
			Expect(SkillMoveService.GetPlayerStarCeiling(uid)).toBe(5)

			local defaultLoadout = SkillMoveService.GetPlayerLoadout(uid)
			Expect(defaultLoadout.slot1).toBe("HeavyKnockOn")
			Expect(defaultLoadout.slot2).toBe("BodyFeint")
			Expect(defaultLoadout.slot3).toBe("SombreroFlick")

			-- Retired skill rejected from loadout
			local okRetired, errRetired = SkillMoveService.SetPlayerLoadout(uid, {
				slot1 = "DragBackTurn",
				slot2 = "BodyFeint",
				slot3 = "SombreroFlick",
			}, true)
			Expect(okRetired).toBeFalse()
			Expect(errRetired).toBe("InvalidSkillId")

			-- Equip 1★ OpenUpFakeShot, 3★ HeelChop, and 4★ LaneChange in stopped/reset context
			local okEquip = SkillMoveService.SetPlayerLoadout(uid, {
				slot1 = "OpenUpFakeShot",
				slot2 = "HeelChop",
				slot3 = "LaneChange",
			}, true)
			Expect(okEquip).toBeTrue()
			Expect(SkillMoveService.GetPlayerLoadout(uid).slot3).toBe("LaneChange")

			-- Reject duplicate skill across slots
			local okDup, errDup = SkillMoveService.SetPlayerLoadout(uid, {
				slot1 = "Elastico",
				slot2 = "Elastico",
				slot3 = "HeavyKnockOn",
			}, true)
			Expect(okDup).toBeFalse()
			Expect(errDup).toBe("DuplicateEquippedSkill")

			-- Reject loadout change when match is in progress (isStoppedOrResetContext == false)
			local okInMatch, errMatch = SkillMoveService.SetPlayerLoadout(uid, {
				slot1 = "HeavyKnockOn",
				slot2 = "BodyFeint",
				slot3 = "LaneChange",
			}, false)
			Expect(okInMatch).toBeFalse()
			Expect(errMatch).toBe("MatchInProgress")

			-- Star ceiling enforcement: 3-star ceiling rejects 4★ LaneChange/SombreroFlick & 5★ Elastico
			SkillMoveService.SetPlayerStarCeiling(uid, 3)
			local okOverStar, errStar = SkillMoveService.SetPlayerLoadout(uid, {
				slot1 = "HeavyKnockOn",
				slot2 = "HeelChop",
				slot3 = "SombreroFlick",
			}, true)
			Expect(okOverStar).toBeFalse()
			Expect(errStar).toBe("ExceedsStarCeiling")
		end)

		-- TC-P03-02: 1★ Heavy Knock-On execution, forward ball impulse, and sprint burst
		SafeTest("TC-P03-02_HeavyKnockOn_1Star_BurstAndBallImpulse", function()
			local pAtt, _, rootAtt = createMockPlayer(3002, "KnockOnUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3002, "North")
			BallService.SetPossessor(3002)

			local ok = SkillMoveService.ExecuteSkillSlot(pAtt, 1, Vector3.new(0, 0, 1), "skl_knock_01")
			Expect(ok).toBeTrue()

			local snap = BallService.GetPlayerMovementSnapshot(3002)
			Expect(snap.stamina).toBeCloseTo(1.0 - 0.15, 0.02)
			Expect(snap.activeSkillMove).toBe("HeavyKnockOn")
			Expect(snap.isDashing).toBeTrue()
			Expect(rootAtt.AssemblyLinearVelocity.Z).toBeCloseTo(22.0, 1.0)

			local bState = BallService.GetBallState()
			Expect(bState.state).toBe("InFlight")
			Expect(bState.velocity.Z).toBeCloseTo(45.0, 1.0)
			Expect(bState.velocity.Z > rootAtt.AssemblyLinearVelocity.Z).toBeTrue()
			Expect(SkillMoveService.GetSkillCooldownRemaining(3002, "HeavyKnockOn")).toBeCloseTo(0.0, 0.01)
		end)

		-- TC-P03-03: 2★ Body Feint sharp shoulder drop and lateral ball impulse
		SafeTest("TC-P03-03_BodyFeint_2Star_LateralCutAndImpulse", function()
			local pAtt, _, rootAtt = createMockPlayer(3003, "BodyFeintUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3003, "North")
			BallService.SetPossessor(3003)

			SkillMoveService.SetPlayerLoadout(3003, {
				slot1 = "HeavyKnockOn",
				slot2 = "BodyFeint",
				slot3 = "SombreroFlick",
			}, true)

			local ok = SkillMoveService.ExecuteSkillSlot(pAtt, 2, Vector3.new(0, 0, 1), "skl_bodyfeint_01")
			Expect(ok).toBeTrue()
			task.wait(0.18)
			BallService.StepPhysics(0.016)
			BallService.StepPhysics(0.016)

			local bState = BallService.GetBallState()
			Expect(math.abs(bState.velocity.X)).toBeGreaterThan(8.0)
			Expect(bState.velocity.Z).toBeGreaterThan(4.0)
			Expect(BallService.GetPlayerStamina(3003)).toBeCloseTo(1.0 - 0.18, 0.02)
		end)

		-- TC-P03-04: 3★ Heel Chop lateral shift and procedural R6 pose verification
		SafeTest("TC-P03-04_HeelChop_3Star_SharpLateralShiftAndPoses", function()
			local pAtt, _, _ = createMockPlayer(3004, "HeelChopUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3004, "North")
			BallService.SetPossessor(3004)

			SkillMoveService.SetPlayerLoadout(3004, {
				slot1 = "HeavyKnockOn",
				slot2 = "HeelChop",
				slot3 = "SombreroFlick",
			}, true)

			local ok = SkillMoveService.ExecuteSkillSlot(pAtt, 2, Vector3.new(0, 0, 1), "skl_heelchop_01")
			Expect(ok).toBeTrue()
			task.wait(0.20)
			BallService.StepPhysics(0.016)
			BallService.StepPhysics(0.016)

			local bState = BallService.GetBallState()
			Expect(math.abs(bState.velocity.X)).toBeGreaterThan(10.0)
			Expect(bState.velocity.Z).toBeGreaterThan(2.0)

			-- Verify procedural R6 poses for all 7 active skills and 3 tackles have floor clearance (minY >= -0.02)
			local allPoseNames = {
				"HeavyKnockOn",
				"OpenUpFakeShot",
				"BodyFeint",
				"HeelChop",
				"LaneChange",
				"SombreroFlick",
				"Elastico",
				"Poke",
				"CagePress",
				"CagePressWallSplat",
			}
			for _, actName in ipairs(allPoseNames) do
				for _, phase in ipairs({ 0.15, 0.45, 0.80 }) do
					local pose = PlayerActionPoseConfigs.GetFollowThroughPose(actName, phase)
					local rootCF = pose.RootJoint or CFrame.identity
					local rHipCF = pose.RightHip or CFrame.identity
					local lHipCF = pose.LeftHip or CFrame.identity
					local rLegWorld = CFrame.new(0, 3.0, 0) * rootCF * CFrame.new(1, -1, 0) * rHipCF * CFrame.new(-0.5, -1, 0)
					local lLegWorld = CFrame.new(0, 3.0, 0) * rootCF * CFrame.new(-1, -1, 0) * lHipCF * CFrame.new(0.5, -1, 0)
					local torsoWorld = CFrame.new(0, 3.0, 0) * rootCF
					local minY = PlayerActionPoseConfigs.CalculateRigMinY(rLegWorld, lLegWorld, torsoWorld)
					Expect(minY >= -0.02).toBeTrue()
				end
			end

			-- BodyFeint uses left shoulder drop at phase 0.20 and right shoulder at phase 0.55
			local feintEarly = PlayerActionPoseConfigs.GetSkillMovePose("BodyFeint", 0.20)
			local feintMid = PlayerActionPoseConfigs.GetSkillMovePose("BodyFeint", 0.55)
			Expect(feintEarly.RightShoulder ~= CFrame.identity).toBeTrue()
			Expect(feintMid.LeftShoulder ~= CFrame.identity).toBeTrue()
		end)

		-- TC-P03-05: 4★ Sombrero Flick high parabolic arc distinct from BallPop & evades ground Slide
		SafeTest("TC-P03-05_SombreroFlick_4Star_OverheadArcEvadesGroundSlide", function()
			local pAtt, _, _ = createMockPlayer(3005, "SombreroUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pDef, _, _ = createMockPlayer(3006, "SlidingDefender", Vector3.new(0, 1.5, 11.0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(3005, "North")
			BallService.SetPlayerTeamSide(3006, "South")
			BallService.SetPossessor(3005)
			BallService.StepPhysics(0.016) -- place ball at dribbler's feet (Z = 2.5, Y = 1.25)

			-- Slot 3 defaults to SombreroFlick (4★)
			local ok = SkillMoveService.ExecuteSkillSlot(pAtt, 3, Vector3.new(0, 0, 1), "skl_somb_01")
			Expect(ok).toBeTrue()

			local bState = BallService.GetBallState()
			Expect(bState.velocity.Y).toBeCloseTo(38.0, 1.0)
			Expect(bState.velocity.Z).toBeCloseTo(14.0, 1.0)

			-- Step physics 0.14s so ball rises overhead (Y > 5.5 studs)
			BallService.StepPhysics(0.07)
			BallService.StepPhysics(0.07)
			local highBall = BallService.GetBallState()
			Expect(highBall.position.Y).toBeGreaterThan(5.5)

			-- Move sliding defender beneath the overhead ball (Z = 5.0, Y = 1.5) and slide under the arc
			pDef.Character:PivotTo(CFrame.lookAt(Vector3.new(0, 1.5, 5.0), Vector3.new(0, 1.5, 0)))
			local okSlide = BallService.ExecuteSlide(pDef, Vector3.new(0, 0, -1), 0.5, "sld_under_somb")
			Expect(okSlide).toBeTrue()
			local afterSlideBall = BallService.GetBallState()
			Expect(afterSlideBall.velocity.Z).toBeGreaterThan(0.0) -- Still moving forward (+Z) over defender!
		end)

		-- TC-P03-06: 5★ Elastico execution and inward snap trajectory
		SafeTest("TC-P03-06_Elastico_5Star_OutwardFeintAndInwardSnap", function()
			local pAtt, _, _ = createMockPlayer(3007, "ElasticoUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3007, "North")
			BallService.SetPossessor(3007)

			SkillMoveService.SetPlayerLoadout(3007, {
				slot1 = "HeavyKnockOn",
				slot2 = "BodyFeint",
				slot3 = "Elastico",
			}, true)

			local ok = SkillMoveService.ExecuteSkillSlot(pAtt, 3, Vector3.new(0, 0, 1), "skl_elas_01")
			Expect(ok).toBeTrue()
			Expect(BallService.GetPlayerStamina(3007)).toBeCloseTo(1.0 - 0.32, 0.02)
			Expect(SkillMoveService.GetSkillCooldownRemaining(3007, "Elastico")).toBeCloseTo(0.0, 0.01)
		end)

		-- TC-P03-07: No I-Frames — 5★ Elastico is vulnerable to Quick Poke tackle
		SafeTest("TC-P03-07_NoIFrames_SkillMoveVulnerableToQuickPoke", function()
			local pAtt, _, _ = createMockPlayer(3008, "ElasticoAttacker", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pDef, _, _ = createMockPlayer(3009, "PokeDefender", Vector3.new(1.5, 1.5, 3.0), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(3008, "North")
			BallService.SetPlayerTeamSide(3009, "South")
			BallService.SetPossessor(3008)

			SkillMoveService.SetPlayerLoadout(3008, {
				slot1 = "Elastico",
				slot2 = "BodyFeint",
				slot3 = "SombreroFlick",
			}, true)

			local okSkill = SkillMoveService.ExecuteSkillSlot(pAtt, 1, Vector3.new(0, 0, 1), "skl_elas_vuln")
			Expect(okSkill).toBeTrue()
			Expect(BallService.GetPlayerMovementSnapshot(3008).activeSkillMove).toBe("Elastico")

			-- Defender uses Quick Poke while attacker is mid-Elastico -> knock-away first.
			local okPoke = BallService.ExecutePokeTackle(pDef, Vector3.new(-1, 0, -0.35), "tkl_poke_steal")
			Expect(okPoke).toBeTrue()
			Expect(BallService.GetPossessorUserId()).toBeNil()
			Expect(BallService.GetBallState().state).toBe("InFlight")
		end)

		-- TC-P03-08: Insufficient stamina rejection & continuous stamina-based execution
		SafeTest("TC-P03-08_InsufficientStaminaAndCommonRecoveryGating", function()
			local pAtt, _, _ = createMockPlayer(3010, "LowStamUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3010, "North")
			BallService.SetPossessor(3010)
			BallService.SetPlayerStamina(3010, 0.10)

			-- SombreroFlick costs 0.28 -> rejected without partial mutation
			local okLow = SkillMoveService.ExecuteSkillSlot(pAtt, 3, Vector3.new(0, 0, 1), "skl_low_stam")
			Expect(okLow).toBeFalse()
			local status, reason = BallService.GetPlayerLastActionStatus(3010)
			Expect(status).toBe("Rejected")
			Expect(reason).toBe("InsufficientStamina")
			Expect(BallService.GetPossessorUserId()).toBe(3010)
			Expect(BallService.GetPlayerStamina(3010)).toBeCloseTo(0.10, 0.01)

			-- Restore stamina and trigger Slot 1 (HeavyKnockOn)
			BallService.SetPlayerStamina(3010, 1.0)
			local okFirst = SkillMoveService.ExecuteSkillSlot(pAtt, 1, Vector3.new(0, 0, 1), "skl_chain_1")
			Expect(okFirst).toBeTrue()

			-- Regain possession immediately: chaining Slot 2 (BodyFeint) succeeds because skill has 0 cooldown and stamina is sufficient
			BallService.SetPossessor(3010)
			local okSecond = SkillMoveService.ExecuteSkillSlot(pAtt, 2, Vector3.new(0, 0, 1), "skl_chain_2")
			Expect(okSecond).toBeTrue()
			Expect(BallService.GetPlayerStamina(3010)).toBeCloseTo(1.0 - 0.15 - 0.18, 0.02)
		end)

		-- TC-P03-09: Replay protection with unique intentId & stamina debit
		SafeTest("TC-P03-09_CooldownAntiBypass_LoadoutResetTeamChangeReplay", function()
			local pAtt, _, _ = createMockPlayer(3011, "BypassTester", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3011, "North")
			BallService.SetPossessor(3011)

			local ok1 = SkillMoveService.ExecuteSkillSlot(pAtt, 1, Vector3.new(0, 0, 1), "skl_unique_intent")
			Expect(ok1).toBeTrue()
			Expect(SkillMoveService.GetSkillCooldownRemaining(3011, "HeavyKnockOn")).toBeCloseTo(0.0, 0.01)

			-- Replaying the same intentId is rejected with StaleIntent
			local okReplay = SkillMoveService.ExecuteSkillSlot(pAtt, 2, Vector3.new(0, 0, 1), "skl_unique_intent")
			Expect(okReplay).toBeFalse()
			local _, repReason = BallService.GetPlayerLastActionStatus(3011)
			Expect(repReason).toBe("StaleIntent")

			-- Regain possession; a distinct intentId succeeds immediately with sufficient stamina
			BallService.SetPossessor(3011)
			local okNewIntent = SkillMoveService.ExecuteSkillSlot(pAtt, 1, Vector3.new(0, 0, 1), "skl_unique_intent_2")
			Expect(okNewIntent).toBeTrue()
		end)

		-- TC-P03-10: Quick Poke receivable steal vs high/fast knock-free vs whiff recovery
		SafeTest("TC-P03-10_QuickPoke_ReceivableVsFastHighAndWhiffRecovery", function()
			local pAtt, _, _ = createMockPlayer(3012, "Attacker", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pDef, _, _, _ = createMockPlayer(3013, "Poker", Vector3.new(0, 1.5, 4.8), Vector3.new(0, 0, -1))
			BallService.SetPlayerTeamSide(3012, "North")
			BallService.SetPlayerTeamSide(3013, "South")
			BallService.SetPossessor(3012)
			-- Ball is placed at Z = 2.5 by SetPossessor (distance from Poker at Z = 4.8 is 2.3 studs <= 4.5 reach)

			-- 1. Receivable ground ball is knocked away first; it never awards possession.
			local okPoke = BallService.ExecutePokeTackle(pDef, Vector3.new(0, 0, -1), "poke_steal_01")
			Expect(okPoke).toBeTrue()
			Expect(BallService.GetPossessorUserId()).toBeNil()
			Expect(BallService.GetBallState().state).toBe("InFlight")
			Expect(BallService.GetBallState().velocity.Z).toBeLessThan(-15.0)

			-- 2. Fast ball (> 42 studs/s) within reach -> knocked free, NOT possessed!
			local pDef2, _, _ = createMockPlayer(3014, "PokerFast", Vector3.new(0, 1.5, 10.0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3014, "North")
			BallService.ResetBall(Vector3.new(0, 1.5, 12.0), "South")
			BallService.SetBallPositionAndVelocity(Vector3.new(0, 1.5, 12.0), Vector3.new(0, 0, -60.0))
			local okFastPoke = BallService.ExecutePokeTackle(pDef2, Vector3.new(0, 0, 1), "poke_fast_01")
			Expect(okFastPoke).toBeTrue()
			Expect(BallService.GetPossessorUserId()).toBeNil()
			Expect(BallService.GetBallState().state).toBe("InFlight")
			Expect(BallService.GetBallState().velocity.Z).toBeGreaterThan(15.0)

			-- 3. Out of range whiff -> applies poke recovery slow
			local pDef3, _, _, humDef3 = createMockPlayer(3015, "PokerWhiff", Vector3.new(0, 1.5, 50.0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3015, "North")
			BallService.ResetBall(Vector3.new(0, 1.5, 0), "South")
			local okWhiff = BallService.ExecutePokeTackle(pDef3, Vector3.new(0, 0, 1), "poke_whiff_01")
			Expect(okWhiff).toBeTrue()
			Expect(humDef3.WalkSpeed).toBeLessThan(Constants.WALK_SPEED)
			Expect(BallService.ExecuteDash(pDef3, Vector3.new(0, 0, 1))).toBeFalse()
		end)

		-- TC-P03-11: Open-field Cage Press pushes, but the opponent retains the ball.
		SafeTest("TC-P03-11_CagePressOpenField_RetainsOpponentPossession", function()
			local pAtt, charAtt, _, humAtt = createMockPlayer(3016, "DribblerNorth", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local pDef, _, _, _ = createMockPlayer(3017, "ChargerSouth", Vector3.new(2.5, 1.5, 0), Vector3.new(-1, 0, 0))
			BallService.SetPlayerTeamSide(3016, "North")
			BallService.SetPlayerTeamSide(3017, "South")
			BallService.SetPossessor(3016)

			local okPress = BallService.ExecuteCagePress(pDef, Vector3.new(-1, 0, 0), "cagepress_open_01")
			Expect(okPress).toBeTrue()

			-- Open field contact cannot release the ball or award it to the charger.
			local bState = BallService.GetBallState()
			Expect(bState.possessorUserId).toBe(3016)
			Expect(bState.state).toBe("Possessed")

			-- Even after stepping physics, the target keeps possession.
			BallService.StepPhysics(0.016)
			Expect(BallService.GetPossessorUserId()).toBe(3016)

			-- Open-field contact applies only the brief light disruption.
			Expect(charAtt:GetAttribute("IsCagePressSlowed")).toBe(true)
			Expect(humAtt.WalkSpeed).toBeLessThan(Constants.WALK_SPEED)
		end)

		SafeTest("TC-P03-16_CagePressSweptWallImpact_ReleasesAndStunsCarrier", function()
			local pCarrier, charCarrier, rootCarrier = createMockPlayer(3030, "WallCarrier", Vector3.new(20, 1.5, 118.2), Vector3.new(0, 0, -1))
			local pPress = createMockPlayer(3031, "WallPresser", Vector3.new(20, 1.5, 115.6), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3030, "North")
			BallService.SetPlayerTeamSide(3031, "South")
			BallService.SetPossessor(3030)

			local ok = BallService.ExecuteCagePress(pPress, Vector3.new(0, 0, 1), "cagepress_wall_01")
			Expect(ok).toBeTrue()
			Expect(BallService.GetPossessorUserId()).toBe(3030)
			rootCarrier.CFrame = CFrame.lookAt(Vector3.new(20, 1.5, 119.4), Vector3.new(20, 1.5, 120.4))
			BallService.StepPhysics(0.016)

			Expect(charCarrier:GetAttribute("CagePressWallSplatSequence")).toBeGreaterThan(0)
			Expect(BallService.GetPossessorUserId()).toBeNil()
			Expect(BallService.GetBallState().state).toBe("Free")
			Expect(charCarrier:GetAttribute("RecoveryRemaining")).toBeGreaterThan(0.5)
		end)

		-- TC-P03-12: Ordinary opponent body contact slows without stripping ball; teammates pass through without slow
		SafeTest("TC-P03-12_OrdinaryContactSlowVsTeammatePassThrough", function()
			local p1, _, _, hum1 = createMockPlayer(3018, "NorthCarrier", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			local p2, _, _, hum2 = createMockPlayer(3019, "NorthTeammate", Vector3.new(1.5, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3018, "North")
			BallService.SetPlayerTeamSide(3019, "North")
			BallService.SetPossessor(3018)

			-- Teammates within 1.5 studs -> zero contact slow!
			BallService.StepPhysics(0.05)
			Expect(hum1.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.1)
			Expect(hum2.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED, 0.1)
			Expect(BallService.GetPossessorUserId()).toBe(3018)

			-- Opponent behind carrier (within 2.5 studs of body, but > 3.5 studs from ball in front) -> slows both, carrier keeps ball!
			local _, _, _, humOpp = createMockPlayer(3020, "SouthBodyContact", Vector3.new(0, 1.5, -2.2), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3020, "South")
			BallService.StepPhysics(0.05)
			Expect(BallService.GetPossessorUserId()).toBe(3018)
			Expect(hum1.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED * 0.80, 0.5)
			Expect(humOpp.WalkSpeed).toBeCloseTo(Constants.WALK_SPEED * 0.80, 0.5)
		end)

		-- TC-P03-13: Server payload, generation, and context version validation for Skill & Tackle remotes
		SafeTest("TC-P03-13_ServerPayloadAndGenerationValidation", function()
			local pAtt, _, _ = createMockPlayer(3021, "ValidatorUser", Vector3.new(0, 1.5, 0), Vector3.new(0, 0, 1))
			BallService.SetPlayerTeamSide(3021, "North")
			BallService.SetPossessor(3021)

			local gen = BallService.GetPlayerGeneration(3021)
			local ctxVer = BallService.GetPlayerContextVersion(3021)

			-- Stale generation rejected
			local okStale = SkillMoveService.HandleSkillMoveRequest(pAtt, {
				slotIndex = 1,
				skillId = "HeavyKnockOn",
				direction = Vector3.new(0, 0, 1),
				intentId = "val_stale_01",
				characterGeneration = gen + 99,
				contextVersion = ctxVer,
			})
			Expect(okStale).toBeFalse()
			local _, r1 = BallService.GetPlayerLastActionStatus(3021)
			Expect(r1).toBe("StaleIntent")

			-- NaN direction rejected
			local okNan = SkillMoveService.HandleSkillMoveRequest(pAtt, {
				slotIndex = 1,
				skillId = "HeavyKnockOn",
				direction = Vector3.new(0 / 0, 0, 1),
				intentId = "val_nan_01",
				characterGeneration = gen,
				contextVersion = ctxVer,
			})
			Expect(okNan).toBeFalse()
			local _, r2 = BallService.GetPlayerLastActionStatus(3021)
			Expect(r2).toBe("InvalidPayload")

			-- Valid request succeeds
			local okValid = SkillMoveService.HandleSkillMoveRequest(pAtt, {
				slotIndex = 1,
				skillId = "HeavyKnockOn",
				direction = Vector3.new(0, 0, 1),
				intentId = "val_ok_01",
				characterGeneration = gen,
				contextVersion = ctxVer,
			})
			Expect(okValid).toBeTrue()
		end)

		-- TC-P03-14: Legacy Choice Duel modules are retired
		SafeTest("TC-P03-14_LegacyChoiceDuelRetirement", function()
			Expect(DuelEngineService.IsRetired).toBe(true)
			local p1 = createMockPlayer(3022, "LegacyA", Vector3.new(0, 1.5, 0))
			local p2 = createMockPlayer(3023, "LegacyB", Vector3.new(0, 1.5, 2))
			local session = DuelEngineService.StartDuel(p1 :: any, p2 :: any, "2v2")
			Expect(session).toBeNil()
		end)
	end)
end

return runSkillMovesAndDefenseTests
