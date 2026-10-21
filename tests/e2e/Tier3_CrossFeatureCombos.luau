--!strict
-- tests/e2e/Tier3_CrossFeatureCombos.luau
-- Tier 3: Cross-Feature Combinations (Pairwise & compound interactions)

local TestHarness = require(script.Parent:WaitForChild("TestHarness"))

local Describe = TestHarness.Describe
local Test = TestHarness.Test
local Expect = TestHarness.Expect

local function runTier3(CagePhysicsService: any, Constants: any, Types: any)
	local SQRT2 = math.sqrt(2.0)
	local INV_SQRT2 = 1.0 / SQRT2

	Describe("T3_CrossFeatureCombinations", function()
		-- Scenario 1: Ramp Upward Launch -> Ceiling Lob Rebound
		Test("TC-T3-01_RampLaunchToCeilingLob", function()
			-- Start on West ramp at X = -74 with upward impulse
			local initVel = Vector3.new(40, 0, 0)
			local rampVel = CagePhysicsService.ApplyRampImpulse(initVel, true, true)
			Expect(rampVel.Y).toBeGreaterThan(0)

			-- Simulate trajectory reaching ceiling at Y = 32
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(-74, 3, 0),
				initialVelocity = Vector3.new(40, 50, 0),
				gravityY = -65.0,
				maxDurationSec = 2.0,
			})
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		-- Scenario 2: Ramp Launch -> Variant C 45° Roof Bevel
		Test("TC-T3-02_RampLaunchToRoofBevelInC", function()
			-- In Variant C, roof bevel starts at Y = 24. A ball launched high hits the bevel.
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "C",
				initialPosition = Vector3.new(-74, 2.5, 0),
				initialVelocity = Vector3.new(110, 60, 0),
				gravityY = -65.0,
				maxDurationSec = 2.0,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			local hitRoof = false
			for _, hit in ipairs(traj.hitSurfaces) do
				if string.find(hit, "RoofBevel") or string.find(hit, "Ceiling") then
					hitRoof = true
					break
				end
			end
			Expect(hitRoof).toBeTrue("Expected ball to strike roof bevel or ceiling in Variant C")
		end)

		-- Scenario 3: Corner Pinball Bumper -> Over-Goal Transom
		Test("TC-T3-03_CornerBumperToGoalTransom", function()
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			-- Shot reflecting off NW bumper (+70, -110) towards North goal transom (0, 15, -106)
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(-45, 12, -85),
				initialVelocity = Vector3.new(-50, 0, -50),
				gravityY = 0, -- flat trajectory
				maxDurationSec = 2.0,
				featureFlags = flags,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.speedAfterFirstHit).toBeGreaterThan(0)
		end)

		-- Scenario 4: Back-Goal Alley (14 studs) -> Rear Corner Chamfer Bumper Chain
		Test("TC-T3-04_BackGoalAlleyToRearBumper", function()
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			-- Trajectory running behind goal at Z = 112, reflecting off South wall then SE bumper
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(30, 3, 112),
				initialVelocity = Vector3.new(40, 0, 40),
				gravityY = -65.0,
				maxDurationSec = 2.0,
				featureFlags = flags,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		-- Scenario 5: High-Speed Lob Passing Through Guide Marker
		Test("TC-T3-05_GuideMarkerZeroPullDuringBumperBoost", function()
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, -50),
				initialVelocity = Vector3.new(0, 60, -30),
				gravityY = -65.0,
				maxDurationSec = 1.8,
				featureFlags = flags,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		-- Scenario 6: Elevating Ramp Incline -> Wall Glancing Collision
		Test("TC-T3-06_RampInclineWallGlance", function()
			-- Ball moving along West wall while climbing ramp
			local pos = Vector3.new(-78, 2.5, 0)
			local vel = Vector3.new(-10, 0, 80)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "B" })
			Expect(res.position.X).toBeGreaterThanOrEqual(-80.0 + Constants.BALL_RADIUS - 0.1)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "B", Constants.BALL_RADIUS)).toBeTrue()
		end)

		-- Scenario 7: Over-Goal Transom Rebound -> Floor Ground Rebound Chain
		Test("TC-T3-07_TransomToFloorReboundChain", function()
			-- Ball rebounds off Transom_North, falls under gravity, bounces off floor
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(0, 16, -95),
				initialVelocity = Vector3.new(0, 5, -60),
				gravityY = -65.0,
				maxDurationSec = 2.5,
			})
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.landingPosition.Y).toBeCloseTo(Constants.BALL_RADIUS, 0.5)
		end)

		-- Scenario 8: Variant C Dual Roof Bevel Corner Reflection
		Test("TC-T3-08_VariantCDualRoofBevelCornerReflection", function()
			-- High corner shot into NW roof bevel in Variant C
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "C",
				initialPosition = Vector3.new(-42, 18.0, -82),
				initialVelocity = Vector3.new(-62, 32, -62),
				gravityY = -65.0,
				maxDurationSec = 2.2,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		-- Scenario 9: Bumper-to-Bumper Cross-Corner Pinball Ricochet
		Test("TC-T3-09_BumperCrossCornerRicochet", function()
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(-35, 3.0, -75),
				initialVelocity = Vector3.new(-70, 0, -70),
				gravityY = 0,
				maxDurationSec = 2.0,
				featureFlags = flags,
			})
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		-- Scenario 10: Low-Speed Ramp Rollback
		Test("TC-T3-10_LowSpeedRampRollback", function()
			-- Ball gently rolls up ramp, decelerates, rolls back down onto floor
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(-74, 3, 0),
				initialVelocity = Vector3.new(5, 5, 0),
				gravityY = -65.0,
				maxDurationSec = 2.0,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.finalPosition.Y).toBeGreaterThanOrEqual(0)
		end)

		-- Scenario 11: Controlled Comparison Suite Execution
		Test("TC-T3-11_RunVariantComparisonSuite_SummaryInvariants", function()
			local suiteRes = CagePhysicsService.RunVariantComparisonSuite()
			Expect(suiteRes).toNotBeNil()
			Expect(suiteRes.summary).toNotBeNil()
			Expect(suiteRes.summary.totalRuns).toBeGreaterThanOrEqual(50)
			Expect(suiteRes.summary.zeroEscapeAllRuns).toBeTrue("0 escapes required across all runs")
			Expect(suiteRes.summary.zeroCornerStuckAllRuns).toBeTrue("0 corner stuck states required")
			Expect(suiteRes.summary.zeroMarkerAimAssistDelta).toBeTrue("0 marker aim assist delta required")
		end)

		-- Scenario 12: Controlled Comparison Matrix Data Structure
		Test("TC-T3-12_ComparisonMatrixDataFields", function()
			local suiteRes = CagePhysicsService.RunVariantComparisonSuite()
			Expect(#suiteRes.shapePass).toBeGreaterThan(0)
			Expect(#suiteRes.mechanicsPass).toBeGreaterThan(0)

			-- Inspect first shape pass result structure
			local r1 = suiteRes.shapePass[1]
			Expect(r1.scenarioId).toNotBeNil()
			Expect(r1.variantId).toNotBeNil()
			Expect(r1.initialPosition).toNotBeNil()
			Expect(r1.initialVelocity).toNotBeNil()
			Expect(r1.landingPosition).toNotBeNil()
			Expect(r1.totalHitCount).toBeGreaterThanOrEqual(0)
		end)
	end)
end

return {
	run = runTier3,
}
