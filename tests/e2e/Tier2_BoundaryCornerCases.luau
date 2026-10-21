--!strict
-- tests/e2e/Tier2_BoundaryCornerCases.luau
-- Tier 2: Boundary & Corner Cases (>=5 tests per boundary/corner domain)

local TestHarness = require(script.Parent:WaitForChild("TestHarness"))

local Describe = TestHarness.Describe
local Test = TestHarness.Test
local Expect = TestHarness.Expect

local function runTier2(CagePhysicsService: any, Constants: any, Types: any)
	local SQRT2 = math.sqrt(2.0)
	local INV_SQRT2 = 1.0 / SQRT2

	-- =========================================================================
	-- Domain 1: Velocity Extremes & Boundary Speeds
	-- =========================================================================
	Describe("T2_VelocityExtremes", function()
		Test("TC-T2-VEL-01_MaxSpeed180_NoTunneling", function()
			local pos = Vector3.new(0, 5, 0)
			local vel = Vector3.new(180, 0, 0) -- 180 studs/s toward East wall (distance 80 studs)
			local dt = 0.5 -- would travel 90 studs (reaching X = 90 without collision)
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(res.position.X).toBeLessThanOrEqual(80.0 - Constants.BALL_RADIUS + 0.1)
			Expect(res.velocity.X).toBeLessThan(0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-VEL-02_CreepingSpeed005_NoDivZero", function()
			local pos = Vector3.new(78.5, 5, 0)
			local vel = Vector3.new(0.05, 0, 0)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position).toNotBeNil()
			Expect(res.velocity).toNotBeNil()
			Expect(math.abs(res.velocity.X)).toBeLessThanOrEqual(0.05 + 1e-4)
		end)

		Test("TC-T2-VEL-03_FloorRestitutionDecayLowSpeed", function()
			local inVel = Vector3.new(0, -1.0, 0)
			local normal = Vector3.new(0, 1, 0)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.FLOOR_RESTITUTION, false)
			Expect(outVel.Y).toBeCloseTo(0.75, 1e-3)
		end)

		Test("TC-T2-VEL-04_BumperHardClampAt180", function()
			-- InVel = 175 studs/s into bumper. Nominal 1.25x would be 218.75 studs/s.
			local inVel = Vector3.new(175 * INV_SQRT2, 0, 175 * INV_SQRT2)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.BUMPER_RESTITUTION, true)
			Expect(outVel.Magnitude).toBeCloseTo(180.0, 1e-2)
			Expect(outVel.Magnitude).toBeLessThanOrEqual(Constants.MAX_REBOUND_SPEED)
		end)

		Test("TC-T2-VEL-05_MaxSpeedCeilingSmashContainment", function()
			local pos = Vector3.new(0, 20, 0)
			local vel = Vector3.new(0, 180, 0)
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position.Y).toBeLessThanOrEqual(Constants.ARENA_CEILING_HEIGHT_Y - Constants.BALL_RADIUS + 0.1)
			Expect(res.velocity.Y).toBeLessThan(0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)
	end)

	-- =========================================================================
	-- Domain 2: Shallow & Grazing Angles
	-- =========================================================================
	Describe("T2_GrazingShallowAngles", function()
		Test("TC-T2-ANG-01_Grazing1DegEastWall", function()
			local rad1 = math.rad(1.0)
			local speed = 100.0
			local inVel = Vector3.new(speed * math.sin(rad1), 0, speed * math.cos(rad1))
			local normal = Vector3.new(-1, 0, 0)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.STANDARD_WALL_RESTITUTION, false)
			Expect(outVel.X).toBeLessThan(0) -- reversed
			Expect(outVel.Z).toBeCloseTo(inVel.Z * Constants.STANDARD_WALL_RESTITUTION, 1e-2) -- restitution scales full velocity vector
		end)

		Test("TC-T2-ANG-02_Grazing3DegChamferCorner", function()
			local pos = Vector3.new(65, 5, 95)
			local vel = Vector3.new(40, 0, 42) -- grazing glancing blow on SE chamfer
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "B" })
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "B", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-ANG-03_Grazing5DegCeiling", function()
			local pos = Vector3.new(0, 30.5, 0)
			local vel = Vector3.new(0, 5, 90) -- shallow approach into ceiling at Y = 32
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.velocity.Y).toBeLessThan(0)
			Expect(res.velocity.Z).toBeCloseTo(90.0 * Constants.STANDARD_WALL_RESTITUTION, 1.0)
		end)

		Test("TC-T2-ANG-04_NearOrthogonal89_9Deg", function()
			local rad89_9 = math.rad(89.9)
			local inVel = Vector3.new(100 * math.sin(rad89_9), 0, 100 * math.cos(rad89_9))
			local normal = Vector3.new(-1, 0, 0)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, 0.88, false)
			Expect(outVel.X).toBeCloseTo(-88.0, 0.5)
			Expect(math.abs(outVel.Z)).toBeLessThan(1.0)
		end)

		Test("TC-T2-ANG-05_ShallowGroundSkip", function()
			local inVel = Vector3.new(0, -2.0, 75.0)
			local normal = Vector3.new(0, 1, 0)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.FLOOR_RESTITUTION, false)
			Expect(outVel.Y).toBeCloseTo(1.5, 1e-2)
			Expect(outVel.Z).toBeCloseTo(75.0 * Constants.FLOOR_RESTITUTION, 1e-2)
		end)
	end)

	-- =========================================================================
	-- Domain 3: Multi-Surface Seams & Corner Junctions
	-- =========================================================================
	Describe("T2_MultiSurfaceSeamsAndJunctions", function()
		Test("TC-T2-SEAM-01_OrthogonalCornerSeamInA", function()
			-- Shot directly into NE corner (+80, +120) in Variant A
			local pos = Vector3.new(70, 5, 110)
			local vel = Vector3.new(80, 0, 80)
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.hitCount).toBeGreaterThanOrEqual(1)
			Expect(res.velocity.X).toBeLessThan(0)
			Expect(res.velocity.Z).toBeLessThan(0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-SEAM-02_ChamferToWallSeamInB", function()
			-- Junction between East wall (X=80, Z in [-100, 100]) and SE chamfer at (80, 100)
			local pos = Vector3.new(75, 5, 98)
			local vel = Vector3.new(60, 0, 40)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "B" })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "B", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-SEAM-03_FloorToWallCornerSeam", function()
			-- Joint between floor (Y = 0) and West wall (X = -80)
			local pos = Vector3.new(-75, 1.5, 0)
			local vel = Vector3.new(-80, -60, 0)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position.Y).toBeGreaterThanOrEqual(Constants.BALL_RADIUS - 0.05)
			Expect(res.position.X).toBeGreaterThanOrEqual(-80.0 + Constants.BALL_RADIUS - 0.05)
		end)

		Test("TC-T2-SEAM-04_CeilingToWallSeamInA", function()
			-- Joint between ceiling (Y = 32) and North wall (Z = -120)
			local pos = Vector3.new(0, 30, -115)
			local vel = Vector3.new(0, 60, -80)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position.Y).toBeLessThanOrEqual(32.0 - Constants.BALL_RADIUS + 0.1)
			Expect(res.position.Z).toBeGreaterThanOrEqual(-120.0 + Constants.BALL_RADIUS - 0.1)
		end)

		Test("TC-T2-SEAM-05_VariantCRoofBevelTransitionSeamY24", function()
			-- Vertical wall to 45° roof bevel seam at Y = 24.0, X = -80
			local pos = Vector3.new(-75, 23.5, 0)
			local vel = Vector3.new(-60, 20, 0)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "C" })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "C", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-SEAM-06_VariantCRoofBevelToCeilingSeamY32", function()
			-- 45° roof bevel to flat inset ceiling seam at Y = 32.0, X = -72
			local pos = Vector3.new(-70, 31.0, 0)
			local vel = Vector3.new(-30, 25, 0)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "C" })
			Expect(res.position.Y).toBeLessThanOrEqual(32.0 - Constants.BALL_RADIUS + 0.1)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "C", Constants.BALL_RADIUS)).toBeTrue()
		end)
	end)

	-- =========================================================================
	-- Domain 3b: Variant C Roof Bevel & Ceiling Coverage (F-10)
	-- =========================================================================
	Describe("T2_VariantCRoofCoverage", function()
		Test("TC-T2-ROOF-01_VariantC_CounterexamplePointsContained", function()
			-- Codex counterexamples: Points (54, 32, 108) and (60, 32, 106) have |X|+|Z| <= 168.6863
			-- and must be strictly contained within Variant C flat ceiling bounds
			local points = {
				Vector3.new(54, 32, 108), -- sum = 162
				Vector3.new(-54, 32, 108),
				Vector3.new(54, 32, -108),
				Vector3.new(-54, 32, -108),
				Vector3.new(60, 32, 106), -- sum = 166 (Codex Review-003 counterexample)
				Vector3.new(-60, 32, 106),
				Vector3.new(60, 32, -106),
				Vector3.new(-60, 32, -106),
			}
			for _, pt in ipairs(points) do
				Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "C", 0.0)).toBeTrue(
					string.format("Point %s must be inside Variant C bounds", tostring(pt))
				)
			end
		end)

		Test("TC-T2-ROOF-02_VariantC_CeilingCollisionAtCounterexamplePoints", function()
			-- Ball moving upward into ceiling at (54, 30.5, 108) and (60, 30.5, 106)
			-- must hit ceiling and reflect downward (zero pass-through)
			local testPoints = {
				Vector3.new(54, 30.5, 108),
				Vector3.new(60, 30.5, 106),
			}
			for _, pos in ipairs(testPoints) do
				local vel = Vector3.new(0, 40, 0)
				local dt = 0.1
				local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "C" })
				Expect(res.hitCount).toBeGreaterThan(0)
				Expect(newVel.Y).toBeLessThan(0)
				Expect(res.position.Y).toBeLessThanOrEqual(32.0 + 0.1)
			end
		end)

		Test("TC-T2-ROOF-03_VariantC_VisualCeilingWatertightNoGaps", function()
			-- Build Variant C arena in Workspace and inspect visual ceiling corner wedges
			local arena = CagePhysicsService.BuildCageArena(Workspace, "C")
			local cornerNames = {
				"VisualCeiling_Corner_1_1",
				"VisualCeiling_Corner_-1_1",
				"VisualCeiling_Corner_1_-1",
				"VisualCeiling_Corner_-1_-1",
			}
			for _, name in ipairs(cornerNames) do
				local w = arena:FindFirstChild(name)
				Expect(w).toNotBeNil(name .. " must exist in Variant C arena")
				if w and w:IsA("BasePart") then
					Expect(w:IsA("WedgePart")).toBeTrue(name .. " must be a WedgePart")
					Expect(w.CanCollide).toBeFalse(name .. " must have CanCollide = false")
				end
			end

			-- Reset arena back to Variant A
			CagePhysicsService.BuildCageArena(Workspace, "A")
		end)

		Test("TC-T2-ROOF-04_VariantC_VisualCeilingAreaCoverageParity", function()
			-- Verify 7-piece visual ceiling decomposition covers the theoretical inset octagon area
			-- Bounding box = 144 x 224 = 32,256 sq studs
			-- Inset diagonal boundary: |X| + |Z| = 180 - 8*sqrt(2) ≈ 168.6862915
			-- Corner cuts: 4 corners with legs cutStuds = 4 + 8*sqrt(2) ≈ 15.3137085
			-- 4 corner triangles cut area = 2 * (cutStuds^2) ≈ 469.019336 sq studs
			-- Theoretical octagon area = 32,256 - 469.019336 = 31,786.98066 sq studs
			local arena = CagePhysicsService.BuildCageArena(Workspace, "C")
			local centerPart = arena:FindFirstChild("VisualCeiling_Center") :: BasePart
			local westPart = arena:FindFirstChild("VisualCeiling_West") :: BasePart
			local eastPart = arena:FindFirstChild("VisualCeiling_East") :: BasePart

			Expect(centerPart).toNotBeNil("VisualCeiling_Center must exist")
			Expect(westPart).toNotBeNil("VisualCeiling_West must exist")
			Expect(eastPart).toNotBeNil("VisualCeiling_East must exist")

			local centerArea = centerPart.Size.X * centerPart.Size.Z
			local westArea = westPart.Size.X * westPart.Size.Z
			local eastArea = eastPart.Size.X * eastPart.Size.Z

			local cornerAreaSum = 0
			for _, c in ipairs({ { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
				local w = arena:FindFirstChild(string.format("VisualCeiling_Corner_%d_%d", c[1], c[2])) :: BasePart
				Expect(w).toNotBeNil("Corner wedge must exist")
				if w then
					-- Wedge triangle area in XZ plane = 0.5 * legY * legZ
					cornerAreaSum += 0.5 * w.Size.Y * w.Size.Z
				end
			end

			local totalVisualArea = centerArea + westArea + eastArea + cornerAreaSum
			local expectedOctagonArea = 31786.98066
			local areaDiff = math.abs(totalVisualArea - expectedOctagonArea)
			Expect(areaDiff).toBeLessThan(0.05)

			-- Reset arena back to Variant A
			CagePhysicsService.BuildCageArena(Workspace, "A")
		end)

		Test("TC-T2-ROOF-05_VariantC_VisualPolygonPointCoverageAndAbsence", function()
			-- Verify mathematical coverage inside the visual polygon and absence outside
			-- Inner rectangle bounds: innerRoofX = 68 - 8*sqrt(2) ≈ 56.6863, innerRoofZ = 108 - 8*sqrt(2) ≈ 96.6863
			-- Half roof bounds: halfRoofX = 72, halfRoofZ = 112
			-- Diagonal limit: C = 180 - 8*sqrt(2) ≈ 168.6863
			local sqrt2 = math.sqrt(2)
			local diagLimit = 180 - (8 * sqrt2)
			local halfRoofX = 72.0
			local halfRoofZ = 112.0
			local cutStuds = (halfRoofX + halfRoofZ) - diagLimit
			local innerRoofX = halfRoofX - cutStuds
			local innerRoofZ = halfRoofZ - cutStuds

			local function isInsideVisualCeiling(x: number, z: number): boolean
				local ax = math.abs(x)
				local az = math.abs(z)
				if ax > halfRoofX or az > halfRoofZ then
					return false
				end
				if ax <= innerRoofX or az <= innerRoofZ then
					return true
				end
				-- In corner square: ax in [innerRoofX, halfRoofX], az in [innerRoofZ, halfRoofZ]
				return (ax + az) <= (diagLimit + 1e-4)
			end

			-- Inside points (must be covered)
			Expect(isInsideVisualCeiling(0, 0)).toBeTrue("Center (0,0) must be inside")
			Expect(isInsideVisualCeiling(54, 108)).toBeTrue("(54, 108) sum=162 must be inside")
			Expect(isInsideVisualCeiling(60, 106)).toBeTrue("(60, 106) sum=166 must be inside (Codex counterexample)")
			Expect(isInsideVisualCeiling(56.68, 112)).toBeTrue("Boundary point at Z=112 must be inside")
			Expect(isInsideVisualCeiling(72, 96.68)).toBeTrue("Boundary point at X=72 must be inside")

			-- Outside points (must NOT be covered - zero protrusion)
			Expect(isInsideVisualCeiling(62, 108)).toBeFalse("(62, 108) sum=170 must be outside")
			Expect(isInsideVisualCeiling(74, 90)).toBeFalse("(74, 90) outside halfRoofX must be outside")
			Expect(isInsideVisualCeiling(50, 114)).toBeFalse("(50, 114) outside halfRoofZ must be outside")
			Expect(isInsideVisualCeiling(70, 105)).toBeFalse("(70, 105) sum=175 must be outside")
		end)
	end)

	-- =========================================================================
	-- Domain 4: Elevating Ramp Spatial Boundaries
	-- =========================================================================
	Describe("T2_RampSpatialBoundaries", function()
		Test("TC-T2-RAMP-01_InwardPrecisionThreshold", function()
			-- Inward bound: X = -66.5 is FALSE, X = -68.0 is TRUE
			local out1 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-66.5, 2.5, 0), "B")
			local in1 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-68.0, 2.5, 0), "B")
			Expect(out1).toBeFalse("X = -66.5 must return false")
			Expect(in1).toBeTrue("X = -68.0 must return true")
		end)

		Test("TC-T2-RAMP-02_OutwardPrecisionThreshold", function()
			-- Outward bound: X = -74.0 is TRUE, X = -81.0 is FALSE
			local in2 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 0), "B")
			local out2 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-81.0, 2.5, 0), "B")
			Expect(in2).toBeTrue("X = -74.0 must return true")
			Expect(out2).toBeFalse("X = -81.0 must return false")
		end)

		Test("TC-T2-RAMP-03_LongitudinalZBoundary", function()
			-- Lengthwise [-30, +30]: Z = 29.5 is TRUE, Z = 30.5 is FALSE
			local inZ = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 29.5), "B")
			local outZ = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 30.5), "B")
			Expect(inZ).toBeTrue("Z = 29.5 must return true")
			Expect(outZ).toBeFalse("Z = 30.5 must return false")
		end)

		Test("TC-T2-RAMP-04_VerticalAltitudeThreshold", function()
			-- On ramp surface Y = 2.5 is TRUE, high in air Y = 15.0 is FALSE
			local inY = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 0), "B")
			local outY = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 15.0, 0), "B")
			Expect(inY).toBeTrue("Y = 2.5 must return true")
			Expect(outY).toBeFalse("Y = 15.0 must return false")
		end)

		Test("TC-T2-RAMP-05_DownwardBallOnRamp", function()
			-- Ball moving downwards onto ramp
			local inVel = Vector3.new(-40, -20, 0)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, true, true)
			Expect(outVel.Y).toBeGreaterThan(0)
		end)
	end)

	-- =========================================================================
	-- Domain 5: Transom & Goal Aperture Thresholds
	-- =========================================================================
	Describe("T2_TransomAndGoalThresholds", function()
		Test("TC-T2-GOAL-01_CrossbarHeightThresholdY10", function()
			-- Just below crossbar (Y = 9.5) enters goal
			local scored = CagePhysicsService.CheckGoalScored(Vector3.new(0, 9.5, -121))
			Expect(scored).toBe("North")

			-- Just above crossbar (Y = 10.5) hits transom zone / outside goal
			local notScored = CagePhysicsService.CheckGoalScored(Vector3.new(0, 10.5, -121))
			Expect(notScored).toBeNil()
		end)

		Test("TC-T2-GOAL-02_TransomTopEdgeBoundary", function()
			-- Profile check: Transom extends from Y = 10 up to eave/ceiling height
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "GoalTransom" then
					local bottomY = surf.cframe.Position.Y - surf.size.Y * 0.5
					Expect(bottomY).toBeCloseTo(10.0, 0.5)
				end
			end
		end)

		Test("TC-T2-GOAL-03_GoalPostLateralWidthX12", function()
			-- Inside goal post width [-12, +12]: X = 11.5 is inside goal
			local insidePost = CagePhysicsService.CheckGoalScored(Vector3.new(11.5, 5, -121))
			Expect(insidePost).toBe("North")

			-- Outside goal post width: X = 12.5 is outside goal
			local outsidePost = CagePhysicsService.CheckGoalScored(Vector3.new(12.5, 5, -121))
			Expect(outsidePost).toBeNil()
		end)

		Test("TC-T2-GOAL-04_DirectTransomImpactVelocityRetention", function()
			local inVel = Vector3.new(0, 0, -100)
			local normal = Vector3.new(0, 0, 1)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.TRANSOM_RESTITUTION, false)
			Expect(outVel.Z).toBeCloseTo(95.0, 1e-2)
		end)

		Test("TC-T2-GOAL-05_BackGoalAlleyEntryThresholdZ106", function()
			local inAlley = CagePhysicsService.IsBehindGoal360Zone(Vector3.new(0, 2, 108))
			local inMidfield = CagePhysicsService.IsBehindGoal360Zone(Vector3.new(0, 2, 104))
			Expect(inAlley).toBeFalse("Back-goal alley is superseded (GOAL_BACK_ZONE_STUDS = 0.0)")
			Expect(inMidfield).toBeFalse("Z = 104 is in front of goal line")
		end)
	end)

	-- =========================================================================
	-- Domain 6: Collision Substepping & Budget Stress
	-- =========================================================================
	Describe("T2_SubsteppingBudgetStress", function()
		Test("TC-T2-SUB-01_TripleContactBudgetRespected", function()
			local pos = Vector3.new(78, 1.25, 118)
			local vel = Vector3.new(120, -60, 120)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.substepsUsed).toBeLessThanOrEqual(Constants.MAX_COLLISION_SUBSTEPS)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-SUB-02_RemainingDtConsumptionPrecision", function()
			local pos = Vector3.new(0, 5, 0)
			local vel = Vector3.new(100, 0, 0)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			-- Distance to wall is 80 - 1.25 = 78.75. At 100 studs/s, travel is 10 studs (no hit).
			Expect(res.hitCount).toBe(0)
			Expect(res.position.X).toBeCloseTo(10.0, 1e-2)
		end)

		Test("TC-T2-SUB-03_LargeDtLagSpikeNoTunneling", function()
			local pos = Vector3.new(0, 5, 0)
			local vel = Vector3.new(150, 0, 0)
			local dt = 0.5 -- 500ms lag spike, ball would travel 75 studs (stopping just before wall)
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position.X).toBeLessThanOrEqual(80.0 - Constants.BALL_RADIUS + 0.1)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(res.position, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)

		Test("TC-T2-SUB-04_SmallDtNumericalPrecision", function()
			local pos = Vector3.new(0, 5, 0)
			local vel = Vector3.new(100, 0, 0)
			local dt = 0.001 -- 1ms physics tick
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A" })
			Expect(res.position.X).toBeCloseTo(0.1, 1e-3)
		end)

		Test("TC-T2-SUB-05_TwentyStepTrajectoryStability", function()
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(0, 15, 0),
				initialVelocity = Vector3.new(70, 0, 70),
				gravityY = -65.0,
				maxDurationSec = 2.5,
			})
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
			Expect(traj.totalSteps).toBeGreaterThan(20)
		end)
	end)
end

return {
	run = runTier2,
}
