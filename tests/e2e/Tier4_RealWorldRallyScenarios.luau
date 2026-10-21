--!strict
-- tests/e2e/Tier4_RealWorldRallyScenarios.luau
-- Tier 4: Real-World Application Scenarios (Full match rally simulations & chaotic multi-bounce trajectories)

local TestHarness = require(script.Parent:WaitForChild("TestHarness"))

local Describe = TestHarness.Describe
local Test = TestHarness.Test
local Expect = TestHarness.Expect

local function runTier4(CagePhysicsService: any, Constants: any, Types: any)
	Describe("T4_RealWorldRallyScenarios", function()
		-- Scenario 4.1: Continuous Match Rally Simulation across Variants A, B, C
		Test("TC-T4-01_ContinuousMatchRally_VariantA", function()
			-- Simulate multi-phase ball rally: initial serve, wall rebound, floor bounce
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(0, 1.25, 0),
				initialVelocity = Vector3.new(50, 45, 80),
				gravityY = -65.0,
				maxDurationSec = 4.0,
			})
			Expect(traj.cornerStuck).toBeFalse("Variant A rally must not corner-stuck")
			Expect(traj.escapedBounds).toBeFalse("Variant A rally must not escape bounds")
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(3)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(traj.finalPosition, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T4-02_ContinuousMatchRally_VariantB", function()
			-- Variant B: with chamfers and corner bumpers enabled
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 1.25, 0),
				initialVelocity = Vector3.new(-60, 40, -90),
				gravityY = -65.0,
				maxDurationSec = 4.0,
				featureFlags = flags,
			})
			Expect(traj.cornerStuck).toBeFalse("Variant B rally must not corner-stuck")
			Expect(traj.escapedBounds).toBeFalse("Variant B rally must not escape bounds")
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(3)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(traj.finalPosition, "B", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T4-03_ContinuousMatchRally_VariantC", function()
			-- Variant C: with roof bevels
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "C",
				initialPosition = Vector3.new(0, 1.25, 0),
				initialVelocity = Vector3.new(70, 50, -70),
				gravityY = -65.0,
				maxDurationSec = 4.0,
			})
			Expect(traj.cornerStuck).toBeFalse("Variant C rally must not corner-stuck")
			Expect(traj.escapedBounds).toBeFalse("Variant C rally must not escape bounds")
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(3)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(traj.finalPosition, "C", Constants.BALL_RADIUS)).toBeTrue()
		end)

		-- Scenario 4.2: Box-to-Box Counterattack with Midfield Ramp Launch
		Test("TC-T4-04_BoxToBoxCounterattackRampLaunch", function()
			-- Goalkeeper clearance launched from South end (Z = -95) through midfield
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(-60, 3, -80),
				initialVelocity = Vector3.new(-25, 20, 110),
				gravityY = -65.0,
				maxDurationSec = 3.5,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
		end)

		-- Scenario 4.3: Corner Chaos Multi-Bumper Pinball Sequence
		Test("TC-T4-05_CornerChaosMultiBumperPinball", function()
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(-50, 4, -90),
				initialVelocity = Vector3.new(-90, 10, -90),
				gravityY = -65.0,
				maxDurationSec = 3.0,
				featureFlags = flags,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(2)
		end)

		-- Scenario 4.4: High-Arc Lob & Aerial Heading Volley Setup
		Test("TC-T4-06_HighArcLobAndAerialVolleySetup", function()
			-- Ball lofted high to ceiling marker (Z = -60, Y = 32)
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 2, -20),
				initialVelocity = Vector3.new(0, 62, -45),
				gravityY = -65.0,
				maxDurationSec = 2.5,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			local hitCeiling = false
			for _, hit in ipairs(traj.hitSurfaces) do
				if string.find(hit, "Ceiling") then
					hitCeiling = true
					break
				end
			end
			Expect(hitCeiling).toBeTrue("Expected ceiling rebound")
		end)

		-- Scenario 4.5: Randomized Shot Chain Containment Audit
		Test("TC-T4-07_RandomizedShotChainContainment", function()
			local testAngles = { 0, 45, 90, 135, 180, 225, 270, 315 }
			local allContained = true
			local allNoStuck = true

			for idx, deg in ipairs(testAngles) do
				local rad = math.rad(deg)
				local vx = math.cos(rad) * 110
				local vz = math.sin(rad) * 110
				local traj = CagePhysicsService.SimulateBallTrajectory({
					variantId = "B",
					initialPosition = Vector3.new(0, 8, 0),
					initialVelocity = Vector3.new(vx, 30, vz),
					gravityY = -65.0,
					maxDurationSec = 2.0,
				})
				if traj.escapedBounds then
					allContained = false
				end
				if traj.cornerStuck then
					allNoStuck = false
				end
			end

			Expect(allContained).toBeTrue("All 8 directional shots must remain contained")
			Expect(allNoStuck).toBeTrue("Zero corner-stuck states across all 8 shots")
		end)

		-- Scenario 4.6: Extended Vertical Energy Dissipation & Settling
		Test("TC-T4-08_VerticalEnergyDissipationAndSettling", function()
			-- Drop ball from Y = 28 with zero horizontal velocity
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(0, 28, 0),
				initialVelocity = Vector3.new(0, 0, 0),
				gravityY = -65.0,
				maxDurationSec = 3.5,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			-- Ball should have hit floor multiple times and settle near floor surface Y = 1.25
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(3)
			Expect(traj.finalPosition.Y).toBeLessThan(10.0)
		end)
	end)
end

return {
	run = runTier4,
}
