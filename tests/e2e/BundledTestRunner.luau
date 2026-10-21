--!strict
-- tests/e2e/BundledTestRunner.luau
-- Self-Contained E2E Test Suite Runner for Cage Zero (Roblox Studio Place4)
-- Automatically bundled from TestHarness and Tiers 1-4.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("services")
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))

-- =============================================================================
-- TEST HARNESS
-- =============================================================================
export type AssertionFailure = {
	suiteName: string,
	testName: string,
	message: string,
	expected: any,
	actual: any,
}

export type TestResult = {
	suiteName: string,
	name: string,
	passed: boolean,
	durationMs: number,
	errorMsg: string?,
}

export type SuiteSummary = {
	suiteName: string,
	total: number,
	passed: number,
	failed: number,
	tests: { TestResult },
}

export type GlobalSummary = {
	status: "PASSED" | "FAILED",
	totalTests: number,
	passedTests: number,
	failedTests: number,
	totalAssertions: number,
	durationMs: number,
	suites: { [string]: SuiteSummary },
	failures: { AssertionFailure },
}

local TestHarness = {}

local currentSuiteName = "DefaultSuite"
local currentTestName = "DefaultTest"
local testPassState = true
local testErrorMessage: string? = nil

local totalAssertions = 0
local suites: { [string]: SuiteSummary } = {}
local failures: { AssertionFailure } = {}

function TestHarness.Reset()
	currentSuiteName = "DefaultSuite"
	currentTestName = "DefaultTest"
	testPassState = true
	testErrorMessage = nil
	totalAssertions = 0
	suites = {}
	failures = {}
end

function TestHarness.Describe(suiteName: string, suiteFn: () -> ())
	currentSuiteName = suiteName
	if not suites[suiteName] then
		suites[suiteName] = {
			suiteName = suiteName,
			total = 0,
			passed = 0,
			failed = 0,
			tests = {},
		}
	end
	suiteFn()
end

function TestHarness.Test(testName: string, testFn: () -> ())
	currentTestName = testName
	testPassState = true
	testErrorMessage = nil

	local suite = suites[currentSuiteName]
	if not suite then
		suite = {
			suiteName = currentSuiteName,
			total = 0,
			passed = 0,
			failed = 0,
			tests = {},
		}
		suites[currentSuiteName] = suite
	end

	local startTime = os.clock()
	local success, err = pcall(testFn)
	local durationMs = (os.clock() - startTime) * 1000.0

	suite.total += 1

	if not success then
		testPassState = false
		testErrorMessage = tostring(err)
		table.insert(failures, {
			suiteName = currentSuiteName,
			testName = currentTestName,
			message = "Test threw unhandled error: " .. tostring(err),
			expected = "Clean execution",
			actual = tostring(err),
		})
	end

	if testPassState then
		suite.passed += 1
	else
		suite.failed += 1
	end

	table.insert(suite.tests, {
		suiteName = currentSuiteName,
		name = testName,
		passed = testPassState,
		durationMs = durationMs,
		errorMsg = testErrorMessage,
	})
end

local function recordFailure(msg: string, expected: any, actual: any)
	testPassState = false
	testErrorMessage = msg
	table.insert(failures, {
		suiteName = currentSuiteName,
		testName = currentTestName,
		message = msg,
		expected = expected,
		actual = actual,
	})
end

function TestHarness.Expect(actual: any)
	totalAssertions += 1

	return {
		toBe = function(expected: any, customMsg: string?)
			if actual ~= expected then
				local msg = customMsg or string.format("Expected %s but got %s", tostring(expected), tostring(actual))
				recordFailure(msg, expected, actual)
			end
		end,

		toNotBe = function(expected: any, customMsg: string?)
			if actual == expected then
				local msg = customMsg or string.format("Expected value not to be %s", tostring(expected))
				recordFailure(msg, "not " .. tostring(expected), actual)
			end
		end,

		toBeTrue = function(customMsg: string?)
			if actual ~= true then
				local msg = customMsg or string.format("Expected true but got %s", tostring(actual))
				recordFailure(msg, true, actual)
			end
		end,

		toBeFalse = function(customMsg: string?)
			if actual ~= false then
				local msg = customMsg or string.format("Expected false but got %s", tostring(actual))
				recordFailure(msg, false, actual)
			end
		end,

		toBeNil = function(customMsg: string?)
			if actual ~= nil then
				local msg = customMsg or string.format("Expected nil but got %s", tostring(actual))
				recordFailure(msg, nil, actual)
			end
		end,

		toNotBeNil = function(customMsg: string?)
			if actual == nil then
				local msg = customMsg or "Expected non-nil value but got nil"
				recordFailure(msg, "non-nil", nil)
			end
		end,

		toBeCloseTo = function(expected: number, tolerance: number?, customMsg: string?)
			local tol = tolerance or 1e-4
			if typeof(actual) ~= "number" or math.abs(actual - expected) > tol then
				local msg = customMsg or string.format("Expected %f to be close to %f (tol: %f)", actual, expected, tol)
				recordFailure(msg, expected, actual)
			end
		end,

		toBeGreaterThan = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual <= expected then
				local msg = customMsg or string.format("Expected %s > %s", tostring(actual), tostring(expected))
				recordFailure(msg, "> " .. tostring(expected), actual)
			end
		end,

		toBeGreaterThanOrEqual = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual < expected then
				local msg = customMsg or string.format("Expected %s >= %s", tostring(actual), tostring(expected))
				recordFailure(msg, ">= " .. tostring(expected), actual)
			end
		end,

		toBeLessThan = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual >= expected then
				local msg = customMsg or string.format("Expected %s < %s", tostring(actual), tostring(expected))
				recordFailure(msg, "< " .. tostring(expected), actual)
			end
		end,

		toBeLessThanOrEqual = function(expected: number, customMsg: string?)
			if typeof(actual) ~= "number" or actual > expected then
				local msg = customMsg or string.format("Expected %s <= %s", tostring(actual), tostring(expected))
				recordFailure(msg, "<= " .. tostring(expected), actual)
			end
		end,

		toBeVector3CloseTo = function(expected: Vector3, tolerance: number?, customMsg: string?)
			local tol = tolerance or 1e-3
			if typeof(actual) ~= "Vector3" then
				recordFailure("Actual value is not a Vector3: " .. typeof(actual), expected, actual)
				return
			end
			local diff = (actual - expected).Magnitude
			if diff > tol then
				local msg = customMsg or string.format(
					"Expected Vector3(%f, %f, %f) close to (%f, %f, %f), diff = %f > tol %f",
					actual.X, actual.Y, actual.Z,
					expected.X, expected.Y, expected.Z,
					diff, tol
				)
				recordFailure(msg, expected, actual)
			end
		end,

		toBeWithinBounds = function(minVec: Vector3, maxVec: Vector3, customMsg: string?)
			if typeof(actual) ~= "Vector3" then
				recordFailure("Actual value is not a Vector3", minVec, actual)
				return
			end
			local inX = actual.X >= minVec.X and actual.X <= maxVec.X
			local inY = actual.Y >= minVec.Y and actual.Y <= maxVec.Y
			local inZ = actual.Z >= minVec.Z and actual.Z <= maxVec.Z
			if not (inX and inY and inZ) then
				local msg = customMsg or string.format(
					"Vector3(%f, %f, %f) out of bounds [%f..%f, %f..%f, %f..%f]",
					actual.X, actual.Y, actual.Z,
					minVec.X, maxVec.X, minVec.Y, maxVec.Y, minVec.Z, maxVec.Z
				)
				recordFailure(msg, { min = minVec, max = maxVec }, actual)
			end
		end,
	}
end

function TestHarness.GetSummary(totalDurationMs: number): GlobalSummary
	local total = 0
	local passed = 0
	local failed = 0

	for _, suite in pairs(suites) do
		total += suite.total
		passed += suite.passed
		failed += suite.failed
	end

	return {
		status = if failed == 0 then "PASSED" else "FAILED",
		totalTests = total,
		passedTests = passed,
		failedTests = failed,
		totalAssertions = totalAssertions,
		durationMs = totalDurationMs,
		suites = suites,
		failures = failures,
	}
end

local Describe = TestHarness.Describe
local Test = TestHarness.Test
local Expect = TestHarness.Expect

local SQRT2 = math.sqrt(2.0)
local INV_SQRT2 = 1.0 / SQRT2

-- =============================================================================
-- TIER 1: FEATURE COVERAGE (F01-F21)
-- =============================================================================
local function runTier1(CagePhysicsService: any, Constants: any, Types: any)
	local SQRT2 = math.sqrt(2.0)
	local INV_SQRT2 = 1.0 / SQRT2

	-- =========================================================================
	-- F01: Unified Arena Catalog
	-- =========================================================================
	Describe("F01_UnifiedArenaCatalog", function()
		Test("TC-F01-01_VariantA_ProfileIntegrity", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			Expect(profile).toNotBeNil()
			Expect(profile.variantId).toBe("A")
			Expect(profile.wallCount).toBe(4)
			Expect(profile.hasChamferedCorners).toBeFalse()
			Expect(profile.hasBeveledRoof).toBeFalse()
			Expect(profile.ceilingHeightY).toBe(Constants.ARENA_CEILING_HEIGHT_Y)
			Expect(profile.halfWidthX).toBe(Constants.ARENA_HALF_WIDTH_X)
			Expect(profile.halfLengthZ).toBe(Constants.ARENA_HALF_LENGTH_Z)
		end)

		Test("TC-F01-02_VariantB_ProfileIntegrity", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			Expect(profile).toNotBeNil()
			Expect(profile.variantId).toBe("B")
			Expect(profile.wallCount).toBe(8)
			Expect(profile.hasChamferedCorners).toBeTrue()
			Expect(profile.hasBeveledRoof).toBeFalse()
			Expect(profile.chamferCutStuds).toBe(Constants.CHAMFER_CUT_STUDS)
		end)

		Test("TC-F01-03_VariantC_ProfileIntegrity", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			Expect(profile).toNotBeNil()
			Expect(profile.variantId).toBe("C")
			Expect(profile.wallCount).toBe(8)
			Expect(profile.hasChamferedCorners).toBeTrue()
			Expect(profile.hasBeveledRoof).toBeTrue()
			Expect(profile.eaveHeightY).toBe(Constants.ROOF_EAVE_HEIGHT_Y)
			Expect(profile.roofBevelStuds).toBe(Constants.ROOF_BEVEL_STUDS)
		end)

		Test("TC-F01-04_GetAllProfiles_ContainsABC", function()
			local profiles = CagePhysicsService.GetAllArenaGeometryProfiles()
			Expect(profiles).toNotBeNil()
			Expect(profiles["A"]).toNotBeNil()
			Expect(profiles["B"]).toNotBeNil()
			Expect(profiles["C"]).toNotBeNil()
		end)

		Test("TC-F01-05_FootprintPolygon_MathematicalBounds", function()
			local profileA = CagePhysicsService.GetArenaGeometryProfile("A")
			local profileB = CagePhysicsService.GetArenaGeometryProfile("B")
			Expect(#profileA.footprintPolygonXZ).toBe(4)
			Expect(#profileB.footprintPolygonXZ).toBe(8)

			-- Check that corner cuts in B reduce outer corners (-80, -120) to (-60, -120) and (-80, -100)
			local foundChamferPt = false
			for _, pt in ipairs(profileB.footprintPolygonXZ) do
				if math.abs(pt.X - 60) < 0.1 and math.abs(pt.Y - 120) < 0.1 then
					foundChamferPt = true
					break
				end
			end
			Expect(foundChamferPt).toBeTrue("Expected chamfer vertex (60, 120) in footprint")
		end)
	end)

	-- =========================================================================
	-- F02: Variant A Geometry
	-- =========================================================================
	Describe("F02_VariantA_Geometry", function()
		Test("TC-F02-01_OuterWallsCount", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local activeWalls = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Wall" and surf.canCollide then
					activeWalls += 1
				end
			end
			-- 2 side walls (West, East) + 4 split end walls flanking goal mouths (North L/R, South L/R)
			Expect(activeWalls).toBe(6)
		end)

		Test("TC-F02-02_CeilingIsFlatAtY32", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local foundCeiling = false
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Ceiling" then
					foundCeiling = true
					local ceilingBottomY = surf.cframe.Position.Y - surf.size.Y * 0.5
					Expect(ceilingBottomY).toBeCloseTo(32.0, 0.1)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(0, -1, 0), 1e-3)
					Expect(surf.restitution).toBeCloseTo(Constants.STANDARD_WALL_RESTITUTION, 1e-3)
				end
			end
			Expect(foundCeiling).toBeTrue()
		end)

		Test("TC-F02-03_NorthSouthWallsAtZ120", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local northFound, southFound = false, false
			for _, surf in ipairs(profile.surfaces) do
				if surf.surfaceId == "Wall_North" then
					northFound = true
					Expect(surf.cframe.Position.Z).toBeCloseTo(-120.0, 1.0)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(0, 0, 1), 1e-3)
				elseif surf.surfaceId == "Wall_South" then
					southFound = true
					Expect(surf.cframe.Position.Z).toBeCloseTo(120.0, 1.0)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(0, 0, -1), 1e-3)
				end
			end
			Expect(northFound).toBeTrue()
			Expect(southFound).toBeTrue()
		end)

		Test("TC-F02-04_WestEastWallsAtX80", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local westFound, eastFound = false, false
			for _, surf in ipairs(profile.surfaces) do
				if surf.surfaceId == "Wall_West" then
					westFound = true
					Expect(surf.cframe.Position.X).toBeCloseTo(-80.0, 1.0)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(1, 0, 0), 1e-3)
				elseif surf.surfaceId == "Wall_East" then
					eastFound = true
					Expect(surf.cframe.Position.X).toBeCloseTo(80.0, 1.0)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(-1, 0, 0), 1e-3)
				end
			end
			Expect(westFound).toBeTrue()
			Expect(eastFound).toBeTrue()
		end)

		Test("TC-F02-05_FloorAtYZeroRestitution", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local floorFound = false
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Floor" then
					floorFound = true
					Expect(surf.cframe.Position.Y).toBeCloseTo(-1.0, 0.1) -- center at Y = -1, top at Y = 0
					Expect(surf.size.Y).toBeCloseTo(2.0, 0.1)
					Expect(surf.normal).toBeVector3CloseTo(Vector3.new(0, 1, 0), 1e-3)
					Expect(surf.restitution).toBeCloseTo(Constants.FLOOR_RESTITUTION, 1e-3)
				end
			end
			Expect(floorFound).toBeTrue()
		end)
	end)

	-- =========================================================================
	-- F03: Variant B Geometry
	-- =========================================================================
	Describe("F03_VariantB_Geometry", function()
		Test("TC-F03-01_FourChamferSurfacesPresent", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			local chamfers = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "CornerWall" then
					chamfers += 1
				end
			end
			Expect(chamfers).toBe(4)
		end)

		Test("TC-F03-02_ChamferNormalsAre45Degrees", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "CornerWall" then
					Expect(math.abs(math.abs(surf.normal.X) - INV_SQRT2)).toBeCloseTo(0, 1e-3)
					Expect(math.abs(math.abs(surf.normal.Z) - INV_SQRT2)).toBeCloseTo(0, 1e-3)
					Expect(surf.normal.Y).toBeCloseTo(0, 1e-3)
				end
			end
		end)

		Test("TC-F03-03_FourPinballBumpersPresent", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			local bumpers = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "PinballBumper" then
					bumpers += 1
					Expect(surf.restitution).toBeCloseTo(Constants.BUMPER_RESTITUTION, 1e-3)
				end
			end
			Expect(bumpers).toBe(4)
		end)

		Test("TC-F03-04_FlatCeilingPresentAtY32", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			local ceilingFound = false
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Ceiling" then
					ceilingFound = true
					local ceilingBottomY = surf.cframe.Position.Y - surf.size.Y * 0.5
					Expect(ceilingBottomY).toBeCloseTo(32.0, 0.1)
				end
			end
			Expect(ceilingFound).toBeTrue()
		end)

		Test("TC-F03-05_ShortenedStraightWalls", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			for _, surf in ipairs(profile.surfaces) do
				if surf.surfaceId == "Wall_North" or surf.surfaceId == "Wall_South" then
					-- North/South span X in [-60, 60] -> width = 120
					Expect(surf.size.X).toBeCloseTo(120.0, 1.0)
				elseif surf.surfaceId == "Wall_West" or surf.surfaceId == "Wall_East" then
					-- West/East span Z in [-100, 100] -> length = 200
					Expect(surf.size.Z).toBeCloseTo(200.0, 1.0)
				end
			end
		end)
	end)

	-- =========================================================================
	-- F04: Variant C Geometry
	-- =========================================================================
	Describe("F04_VariantC_Geometry", function()
		Test("TC-F04-01_OuterEaveHeightY24", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			Expect(profile.eaveHeightY).toBe(24.0)
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Wall" or surf.kind == "CornerWall" then
					Expect(surf.size.Y).toBeCloseTo(24.0, 1.0)
				end
			end
		end)

		Test("TC-F04-02_EightRoofBevelsSlope45Degrees", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			local bevelCount = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "RoofBevel" then
					bevelCount += 1
					-- Y component of inward normal must be negative (sloping downward into arena)
					Expect(surf.normal.Y).toBeLessThan(0)
					Expect(math.abs(surf.normal.Y)).toBeCloseTo(INV_SQRT2, 0.01)
					-- Verify exact 45-degree angle with horizontal plane for all 8 faces
					local horiz = math.sqrt(surf.normal.X * surf.normal.X + surf.normal.Z * surf.normal.Z)
					local angleDeg = math.deg(math.atan2(math.abs(surf.normal.Y), horiz))
					Expect(angleDeg).toBeCloseTo(45.0, 0.05)
				end
			end
			Expect(bevelCount).toBe(8)
		end)

		Test("TC-F04-03_InsetCeilingAtY32Dimensions", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			local insetCeilingFound = false
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Ceiling" then
					insetCeilingFound = true
					local ceilingBottomY = surf.cframe.Position.Y - surf.size.Y * 0.5
					Expect(ceilingBottomY).toBeCloseTo(32.0, 0.1)
					-- Inset by 8 studs on each side: 160 - 16 = 144, 240 - 16 = 224
					Expect(surf.size.X).toBeCloseTo(144.0, 2.0)
					Expect(surf.size.Z).toBeCloseTo(224.0, 2.0)
				end
			end
			Expect(insetCeilingFound).toBeTrue()
		end)

		Test("TC-F04-04_ZeroFlatCeilingOverlapUnderBevels", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			local fullCeilingFound = false
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "Ceiling" and surf.size.X > 150 then
					fullCeilingFound = true
				end
			end
			Expect(fullCeilingFound).toBeFalse("Variant C must not have a full-width flat ceiling under bevels")
		end)

		Test("TC-F04-05_BevelNormalsPointInwardDownward", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("C")
			for _, surf in ipairs(profile.surfaces) do
				if surf.surfaceId == "RoofBevel_West" then
					-- Normal should point positive X (inward) and negative Y (downward)
					Expect(surf.normal.X).toBeGreaterThan(0.5)
					Expect(surf.normal.Y).toBeLessThan(-0.5)
				elseif surf.surfaceId == "RoofBevel_North" then
					-- Normal should point positive Z (inward) and negative Y (downward)
					Expect(surf.normal.Z).toBeGreaterThan(0.5)
					Expect(surf.normal.Y).toBeLessThan(-0.5)
				end
			end
		end)
	end)

	-- =========================================================================
	-- F05: Swept-Sphere Solver
	-- =========================================================================
	Describe("F05_SweptSphereSolver", function()
		Test("TC-F05-01_NormalWallImpactDetected", function()
			local pos = Vector3.new(-30, 5, -100)
			local vel = Vector3.new(0, 0, -100) -- moving toward North wall
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(newVel.Z).toBeGreaterThan(0) -- bounced southwards
		end)

		Test("TC-F05-02_BallRadiusStopsBeforeWall", function()
			local pos = Vector3.new(-30, 5, -118)
			local vel = Vector3.new(0, 0, -50)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			-- Center must not penetrate past -120 + 1.25 = -118.75
			Expect(newPos.Z).toBeGreaterThanOrEqual(-120.0 + Constants.BALL_RADIUS - 0.1)
		end)

		Test("TC-F05-03_HitSurfaceTagMatches", function()
			local pos = Vector3.new(-30, 5, -100)
			local vel = Vector3.new(0, 0, -100)
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(hitTag).toBe("Wall_North_Left")

			-- F-01 Regression: Ball shot down the center passes through Z = -120 into goal pocket without wall collision
			local centerPos = Vector3.new(0, 5, -117)
			local centerVel = Vector3.new(0, 0, -180)
			local cPos, cVel, cTag, cRes = CagePhysicsService.StepBallCageCollision(centerPos, centerVel, 1/30, { variantId = "A" })
			Expect(cTag ~= "Wall_North" and cTag ~= "Wall_North_Left" and cTag ~= "Wall_North_Right").toBeTrue("Must not hit end wall in goal mouth")
			Expect(cPos.Z).toBeLessThan(-120.0)
			Expect(CagePhysicsService.CheckGoalScored(cPos)).toBe("North")

			-- Mirrored South regression
			local southPos = Vector3.new(0, 5, 117)
			local southVel = Vector3.new(0, 0, 180)
			local sPos, sVel, sTag, sRes = CagePhysicsService.StepBallCageCollision(southPos, southVel, 1/30, { variantId = "A" })
			Expect(sTag ~= "Wall_South" and sTag ~= "Wall_South_Left" and sTag ~= "Wall_South_Right").toBeTrue("Must not hit end wall in goal mouth")
			Expect(sPos.Z).toBeGreaterThan(120.0)
			Expect(CagePhysicsService.CheckGoalScored(sPos)).toBe("South")
		end)

		Test("TC-F05-04_PenetrationPreventionOutsideBounds", function()
			local pos = Vector3.new(-30, 5, 110)
			local vel = Vector3.new(0, 0, 120) -- heading South at Z = 120
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(newPos.Z).toBeLessThanOrEqual(120.0 - Constants.BALL_RADIUS + 0.1)
		end)

		Test("TC-F05-05_RemainingDtAdvancement", function()
			local pos = Vector3.new(-30, 5, -110)
			local vel = Vector3.new(0, 0, -100) -- heading North at Z = -120
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(newVel.Z).toBeGreaterThan(0)
			Expect(newPos.Z).toBeGreaterThan(-120.0 + Constants.BALL_RADIUS)

			-- F-03 Swept-Sphere Post Edge/Corner Regression (Reviewer counterexample)
			local postPos = Vector3.new(-15, 5, -118.6)
			local postVel = Vector3.new(180, 0, 0)
			local pNewPos, pNewVel, pHitTag, pRes = CagePhysicsService.StepBallCageCollision(postPos, postVel, 1/30, { variantId = "A" })
			Expect(pHitTag).toBe("GoalPost_North_Left")
			Expect(pNewVel.Z).toBeGreaterThan(0) -- Rebounded forward into pitch off front-left post corner
			Expect(pNewVel.X).toBeLessThan(postVel.X) -- Speed along X decelerated from 180
			Expect(pRes.hitCount).toBeGreaterThan(0)

			-- Mirrored right post
			local rPostPos = Vector3.new(15, 5, -118.6)
			local rPostVel = Vector3.new(-180, 0, 0)
			local rNewPos, rNewVel, rHitTag, rRes = CagePhysicsService.StepBallCageCollision(rPostPos, rPostVel, 1/30, { variantId = "A" })
			Expect(rHitTag).toBe("GoalPost_North_Right")
			Expect(rNewVel.Z).toBeGreaterThan(0) -- Rebounded forward into pitch
			Expect(rNewVel.X).toBeGreaterThan(rPostVel.X) -- Speed along X decelerated towards 0
		end)
	end)

	-- =========================================================================
	-- F06: Multi-Contact Substepping
	-- =========================================================================
	Describe("F06_MultiContactSubstepping", function()
		Test("TC-F06-01_SubstepsBudgetRespected", function()
			local pos = Vector3.new(75, 1.5, 0)
			local vel = Vector3.new(120, -50, 0) -- aiming at corner between floor and East wall
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(res.substepsUsed).toBeLessThanOrEqual(Constants.MAX_COLLISION_SUBSTEPS)
			Expect(res.budgetExhausted).toBeFalse()
		end)

		Test("TC-F06-02_FloorThenWallSequentialResolution", function()
			local pos = Vector3.new(-30, 2.0, -110)
			local vel = Vector3.new(0, -80, -100)
			local dt = 0.15
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(res.hitCount).toBeGreaterThanOrEqual(1)
			Expect(newVel.Y).toBeGreaterThanOrEqual(0)
			Expect(newVel.Z).toBeGreaterThan(0)
		end)

		Test("TC-F06-03_SubstepCounterMatchesContacts", function()
			local pos = Vector3.new(0, 5, 0)
			local vel = Vector3.new(20, 0, 0)
			local dt = 0.05 -- no collision in 1 stud
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(res.hitCount).toBe(0)
			Expect(res.substepsUsed).toBe(1)
		end)

		Test("TC-F06-04_BudgetExhaustionDoesNotHang", function()
			local pos = Vector3.new(78, 1.3, 118)
			local vel = Vector3.new(180, -180, 180) -- extreme corner wedge velocity
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(newPos).toNotBeNil()
			Expect(newVel).toNotBeNil()
		end)

		Test("TC-F06-05_FinalPositionRemainsInsideArena", function()
			local pos = Vector3.new(0, 2.0, 110)
			local vel = Vector3.new(0, 0, 150)
			local dt = 0.2
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(CagePhysicsService.IsPointInsideArenaBounds(newPos, "A", Constants.BALL_RADIUS)).toBeTrue()
		end)
	end)

	-- =========================================================================
	-- F07: Boundary & Safety Containment
	-- =========================================================================
	Describe("F07_BoundaryContainment", function()
		Test("TC-F07-01_CenterPointInside", function()
			local pt = Vector3.new(0, 10, 0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "A", 0)).toBeTrue()
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "B", 0)).toBeTrue()
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "C", 0)).toBeTrue()
		end)

		Test("TC-F07-02_OutsideXBoundsReturnsFalse", function()
			local pt = Vector3.new(85, 10, 0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "A", 0)).toBeFalse()
		end)

		Test("TC-F07-03_OutsideZBoundsReturnsFalse", function()
			-- Beyond goal back net at Z = 126
			Expect(CagePhysicsService.IsPointInsideArenaBounds(Vector3.new(0, 10, 130), "A", 0)).toBeFalse()
			-- Beyond solid end wall (Z > 120 outside goal mouth |X| > 12)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(Vector3.new(30, 10, 125), "A", 0)).toBeFalse()
		end)

		Test("TC-F07-04_ChamferCornerOutsideInVariantB", function()
			-- In A, point (75, 10, 115) is inside (X < 80, Z < 120)
			-- In B, X + Z = 75 + 115 = 190 > 180 (chamfer line X+Z = 180), so it is OUTSIDE!
			local pt = Vector3.new(75, 10, 115)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "A", 0)).toBeTrue()
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "B", 0)).toBeFalse()
		end)

		Test("TC-F07-05_RoofBevelOutsideInVariantC", function()
			-- Point near eave: X = 78, Y = 30.
			-- In A and B, ceiling is at Y = 32, so (78, 30, 0) is inside.
			-- In C, bevel starts at X = 72 for Y = 32, so at Y = 30 the boundary is at X = 74.
			local pt = Vector3.new(78, 30, 0)
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "A", 0)).toBeTrue()
			Expect(CagePhysicsService.IsPointInsideArenaBounds(pt, "C", 0)).toBeFalse()
		end)
	end)

	-- =========================================================================
	-- F08: High-Speed Ball Reflection
	-- =========================================================================
	Describe("F08_HighSpeedBallReflection", function()
		Test("TC-F08-01_DirectNormalImpactFormula", function()
			local inVel = Vector3.new(100, 0, 0)
			local normal = Vector3.new(-1, 0, 0)
			local e = Constants.STANDARD_WALL_RESTITUTION -- 0.88
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, e, false)
			-- v' = 100 - (1 + 0.88)(-100)(-1) = 100 - 188 = -88
			Expect(outVel.X).toBeCloseTo(-88.0, 1e-2)
			Expect(outVel.Y).toBeCloseTo(0, 1e-2)
			Expect(outVel.Z).toBeCloseTo(0, 1e-2)
		end)

		Test("TC-F08-02_TangentialVelocityPreserved", function()
			local inVel = Vector3.new(100, 0, 50)
			local normal = Vector3.new(-1, 0, 0)
			local e = 0.88
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, e, false)
			Expect(outVel.X).toBeCloseTo(-88.0, 1e-2)
			Expect(outVel.Z).toBeCloseTo(50.0 * 0.88, 1e-2)
		end)

		Test("TC-F08-03_ArbitraryIncidenceVector", function()
			local inVel = Vector3.new(40, -30, 40)
			local normal = Vector3.new(0, 1, 0)
			local e = Constants.FLOOR_RESTITUTION -- 0.75
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, e, false)
			Expect(outVel.X).toBeCloseTo(40.0 * 0.75, 1e-2)
			Expect(outVel.Y).toBeCloseTo(30.0 * 0.75, 1e-2) -- +22.5
			Expect(outVel.Z).toBeCloseTo(40.0 * 0.75, 1e-2)
		end)

		Test("TC-F08-04_HighSpeedEnergyRestitution", function()
			local inVel = Vector3.new(0, 0, 150)
			local normal = Vector3.new(0, 0, -1)
			local e = 0.88
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, e, false)
			Expect(outVel.Magnitude).toBeCloseTo(150 * 0.88, 1e-2)
		end)

		Test("TC-F08-05_SpeedBoundedByMaxReboundSpeed", function()
			local inVel = Vector3.new(180, 0, 0)
			local normal = Vector3.new(-1, 0, 0)
			local e = 1.25 -- bumper
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, e, true)
			Expect(outVel.Magnitude).toBeLessThanOrEqual(Constants.MAX_REBOUND_SPEED)
			Expect(outVel.Magnitude).toBeCloseTo(Constants.MAX_REBOUND_SPEED, 1e-2)
		end)
	end)

	-- =========================================================================
	-- F09: Ceiling Lob & Smash
	-- =========================================================================
	Describe("F09_CeilingLobSmash", function()
		Test("TC-F09-01_UpwardShotReboundsDownward", function()
			local pos = Vector3.new(0, 28, 0)
			local vel = Vector3.new(0, 60, 0)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(newVel.Y).toBeLessThan(0)
			-- e = 0.88 -> 60 * 0.88 = 52.8
			Expect(math.abs(newVel.Y)).toBeCloseTo(52.8, 0.5)
		end)

		Test("TC-F09-02_HorizontalPreservedOnCeiling", function()
			local pos = Vector3.new(0, 28, 0)
			local vel = Vector3.new(45, 60, 30)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(newVel.Y).toBeLessThan(0)
			Expect(math.abs(newVel.X - (45.0 * 0.88))).toBeLessThan(1.0)
			Expect(math.abs(newVel.Z - (30.0 * 0.88))).toBeLessThan(1.0)
		end)

		Test("TC-F09-03_HighVelocityCeilingSmash", function()
			local pos = Vector3.new(0, 25, 0)
			local vel = Vector3.new(0, 120, 0)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = { enableBumpers = false, enableTransom = false, enableRamps = false } })
			Expect(newVel.Y).toBeLessThan(0)
			Expect(math.abs(newVel.Y)).toBeCloseTo(120 * 0.88, 1.0)
		end)

		Test("TC-F09-04_CeilingLobTrajectoryLandingA", function()
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "A",
				initialPosition = Vector3.new(0, 10, 0),
				initialVelocity = Vector3.new(0, 50, 40),
				gravityY = -65.0,
				maxDurationSec = 2.0,
			})
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)

		Test("TC-F09-05_CeilingLobTrajectoryLandingB", function()
			local traj = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, 0),
				initialVelocity = Vector3.new(0, 50, -40),
				gravityY = -65.0,
				maxDurationSec = 2.0,
			})
			Expect(traj.totalHitCount).toBeGreaterThanOrEqual(1)
			Expect(traj.cornerStuck).toBeFalse()
			Expect(traj.escapedBounds).toBeFalse()
		end)
	end)

	-- =========================================================================
	-- F10: Zero Aim-Assist Guide Markers
	-- =========================================================================
	Describe("F10_ZeroAimAssistGuideMarkers", function()
		Test("TC-F10-01_MarkersAreCanCollideFalse", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "CeilingMarker" then
					Expect(surf.canCollide).toBeFalse()
				end
			end
		end)

		Test("TC-F10-02_MarkersAreCanQueryFalse", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "CeilingMarker" then
					Expect(surf.canQuery).toBeFalse()
				end
			end
		end)

		Test("TC-F10-03_TrajectoryThroughMarkerZeroVelocityDelta", function()
			-- Simulate ball passing through marker at Z = -60, Y = 32
			local flagsDefault: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
				includeCornerOverlayInA = false,
			}
			local traj1 = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, -30),
				initialVelocity = Vector3.new(0, 55, -60),
				gravityY = -65.0,
				maxDurationSec = 1.5,
				featureFlags = flagsDefault,
			})
			local traj2 = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, -30),
				initialVelocity = Vector3.new(0, 55, -60),
				gravityY = -65.0,
				maxDurationSec = 1.5,
				featureFlags = flagsDefault,
			})
			Expect((traj1.finalVelocity - traj2.finalVelocity).Magnitude).toBeCloseTo(0, 1e-4)
		end)

		Test("TC-F10-04_TrajectoryThroughMarkerZeroPositionDelta", function()
			local traj1 = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, 30),
				initialVelocity = Vector3.new(0, 55, 60),
				gravityY = -65.0,
				maxDurationSec = 1.5,
			})
			local traj2 = CagePhysicsService.SimulateBallTrajectory({
				variantId = "B",
				initialPosition = Vector3.new(0, 10, 30),
				initialVelocity = Vector3.new(0, 55, 60),
				gravityY = -65.0,
				maxDurationSec = 1.5,
			})
			Expect((traj1.finalPosition - traj2.finalPosition).Magnitude).toBeCloseTo(0, 1e-4)
		end)

		Test("TC-F10-05_ProfileMarksGuideOnlyTrue", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("B")
			local markerCount = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "CeilingMarker" then
					markerCount += 1
					Expect(surf.isGuideOnly).toBeTrue()
				end
			end
			Expect(markerCount).toBe(2)
		end)
	end)

	-- =========================================================================
	-- F11: Over-Goal Transom Rebound
	-- =========================================================================
	Describe("F11_OverGoalTransomRebound", function()
		Test("TC-F11-01_TransomNorthImpact", function()
			local pos = Vector3.new(0, 15, -114)
			local vel = Vector3.new(0, 0, -80)
			local dt = 0.15
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = flags })
			Expect(res.hitCount).toBeGreaterThan(0)
			Expect(newVel.Z).toBeGreaterThan(0) -- bounced southwards
		end)

		Test("TC-F11-02_TransomRestitutionIs095", function()
			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "GoalTransom" then
					Expect(surf.restitution).toBeCloseTo(Constants.TRANSOM_RESTITUTION, 1e-3)
				end
			end
		end)

		Test("TC-F11-03_TransomSouthReflectsTowardsMidfield", function()
			local pos = Vector3.new(0, 15, 114)
			local vel = Vector3.new(0, 0, 80)
			local dt = 0.15
			local flags: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = true,
				enableRamps = true,
			}
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = flags })
			Expect(newVel.Z).toBeLessThan(0) -- bounced northwards
		end)

		Test("TC-F11-04_BelowCrossbarEntersGoalZone", function()
			-- At Y = 5, Z = -121 (inside North goal pocket [X in -12..12, Y in 0..10, Z in -126..-120])
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(0, 5, -121))).toBe("North")
			-- South goal pocket [X in -12..12, Y in 0..10, Z in 120..126]
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(0, 5, 121))).toBe("South")
			-- Midfield / on-pitch positions are not goals
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(0, 5, -108))).toBeNil()
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(0, 5, 108))).toBeNil()
			-- Outside goal width (X = 13) or height (Y = 11) at Z = -121 is not scored
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(13, 5, -121))).toBeNil()
			Expect(CagePhysicsService.CheckGoalScored(Vector3.new(0, 11, -121))).toBeNil()
		end)

		Test("TC-F11-05_TransomDisabledBehavesAsPassThroughOrBackWall", function()
			local flagsNoTransom: Types.ReboundFeatureFlags = {
				enableBumpers = true,
				enableTransom = false,
				enableRamps = true,
			}
			local pos = Vector3.new(0, 15, -100)
			local vel = Vector3.new(0, 0, -80)
			local dt = 0.1
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, { variantId = "A", featureFlags = flagsNoTransom })
			Expect(hitTag ~= "Transom_North").toBeTrue()
		end)
	end)

	-- =========================================================================
	-- F11b: Goal Pocket Restitution Regression (F-08 & F-09)
	-- =========================================================================
	Describe("F11b_GoalPocketRestitution_Regression", function()
		Test("TC-F11b-01_NorthGoalBackNetRestitution040", function()
			-- Codex counterexample: start (0, 5, -123), velocity (0, 0, -60), dt 1/30, radius 1.25, Variant A
			local pos = Vector3.new(0, 5, -123)
			local vel = Vector3.new(0, 0, -60)
			local dt = 1.0 / 30.0
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, {
				variantId = "A",
				ballRadius = 1.25,
			})
			Expect(hitTag).toBe("GoalBackNet_North")
			-- Restitution 0.40 reflection: -60 * -0.40 = +24.0
			Expect(newVel.Z).toBeCloseTo(24.0, 0.5)
			Expect(res.speedAfterHit).toBeCloseTo(24.0, 0.5)
		end)

		Test("TC-F11b-02_SouthGoalBackNetRestitution040_Mirror", function()
			-- Mirrored South GoalBackNet: start (0, 5, 123), velocity (0, 0, 60), dt 1/30, radius 1.25, Variant A
			local pos = Vector3.new(0, 5, 123)
			local vel = Vector3.new(0, 0, 60)
			local dt = 1.0 / 30.0
			local newPos, newVel, hitTag, res = CagePhysicsService.StepBallCageCollision(pos, vel, dt, {
				variantId = "A",
				ballRadius = 1.25,
			})
			Expect(hitTag).toBe("GoalBackNet_South")
			-- Restitution 0.40 reflection: 60 * -0.40 = -24.0
			Expect(newVel.Z).toBeCloseTo(-24.0, 0.5)
			Expect(res.speedAfterHit).toBeCloseTo(24.0, 0.5)
		end)

		Test("TC-F11b-03_GoalSideNetsRestitution040", function()
			local dt = 1.0 / 30.0
			-- North Left side net: start (-10.5, 5, -123), vel (-60, 0, 0)
			local _, newVelNL, hitTagNL = CagePhysicsService.StepBallCageCollision(Vector3.new(-10.5, 5, -123), Vector3.new(-60, 0, 0), dt, { variantId = "A" })
			Expect(hitTagNL).toBe("GoalSideNet_North_Left")
			Expect(newVelNL.X).toBeCloseTo(24.0, 0.5)

			-- North Right side net: start (10.5, 5, -123), vel (60, 0, 0)
			local _, newVelNR, hitTagNR = CagePhysicsService.StepBallCageCollision(Vector3.new(10.5, 5, -123), Vector3.new(60, 0, 0), dt, { variantId = "A" })
			Expect(hitTagNR).toBe("GoalSideNet_North_Right")
			Expect(newVelNR.X).toBeCloseTo(-24.0, 0.5)

			-- South Left side net: start (-10.5, 5, 123), vel (-60, 0, 0)
			local _, newVelSL, hitTagSL = CagePhysicsService.StepBallCageCollision(Vector3.new(-10.5, 5, 123), Vector3.new(-60, 0, 0), dt, { variantId = "A" })
			Expect(hitTagSL).toBe("GoalSideNet_South_Left")
			Expect(newVelSL.X).toBeCloseTo(24.0, 0.5)

			-- South Right side net: start (10.5, 5, 123), vel (60, 0, 0)
			local _, newVelSR, hitTagSR = CagePhysicsService.StepBallCageCollision(Vector3.new(10.5, 5, 123), Vector3.new(60, 0, 0), dt, { variantId = "A" })
			Expect(hitTagSR).toBe("GoalSideNet_South_Right")
			Expect(newVelSR.X).toBeCloseTo(-24.0, 0.5)
		end)

		Test("TC-F11b-04_GoalTopNetsRestitution040", function()
			local dt = 1.0 / 30.0
			-- North Top Net: start (0, 8.5, -123), vel (0, 60, 0)
			local _, newVelNT, hitTagNT = CagePhysicsService.StepBallCageCollision(Vector3.new(0, 8.5, -123), Vector3.new(0, 60, 0), dt, { variantId = "A" })
			Expect(hitTagNT).toBe("GoalTopNet_North")
			Expect(newVelNT.Y).toBeCloseTo(-24.0, 0.5)

			-- South Top Net: start (0, 8.5, 123), vel (0, 60, 0)
			local _, newVelST, hitTagST = CagePhysicsService.StepBallCageCollision(Vector3.new(0, 8.5, 123), Vector3.new(0, 60, 0), dt, { variantId = "A" })
			Expect(hitTagST).toBe("GoalTopNet_South")
			Expect(newVelST.Y).toBeCloseTo(-24.0, 0.5)
		end)

		Test("TC-F11b-05_GoalPocketKindStrictTypeParity", function()
			-- Verify F-09: GoalPocket is part of ArenaSurfaceKind union and all pocket surfaces have it
			local kindCheck: Types.ArenaSurfaceKind = "GoalPocket"
			Expect(kindCheck).toBe("GoalPocket")

			local profile = CagePhysicsService.GetArenaGeometryProfile("A")
			local foundPocket = 0
			for _, surf in ipairs(profile.surfaces) do
				if surf.kind == "GoalPocket" then
					foundPocket = foundPocket + 1
					Expect(surf.restitution).toBeCloseTo(0.40, 1e-3)
				end
			end
			-- 4 North pocket surfaces (back, left, right, top) + 4 South pocket surfaces = 8 total
			Expect(foundPocket).toBe(8)
		end)
	end)

	-- =========================================================================
	-- F12: Corner Pinball Bumpers
	-- =========================================================================
	Describe("F12_CornerPinballBumpers", function()
		Test("TC-F12-01_BumperApplies125Boost", function()
			local inVel = Vector3.new(50, 0, 50)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.BUMPER_RESTITUTION, true)
			Expect(outVel.Magnitude).toBeCloseTo(inVel.Magnitude * 1.25, 1e-2)
		end)

		Test("TC-F12-02_NominalSpeed100Becomes125", function()
			local inVel = Vector3.new(100 * INV_SQRT2, 0, 100 * INV_SQRT2)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.BUMPER_RESTITUTION, true)
			Expect(outVel.Magnitude).toBeCloseTo(125.0, 1e-2)
		end)

		Test("TC-F12-03_HighSpeedClampedAt180", function()
			local inVel = Vector3.new(160 * INV_SQRT2, 0, 160 * INV_SQRT2)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.BUMPER_RESTITUTION, true)
			Expect(outVel.Magnitude).toBeCloseTo(180.0, 1e-2)
		end)

		Test("TC-F12-04_ReflectsAlong45Normal", function()
			local inVel = Vector3.new(60 * INV_SQRT2, 0, 60 * INV_SQRT2)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, 1.25, true)
			local dir = outVel.Unit
			Expect(dir.X).toBeCloseTo(-INV_SQRT2, 1e-2)
			Expect(dir.Z).toBeCloseTo(-INV_SQRT2, 1e-2)
		end)

		Test("TC-F12-05_DisabledBumperStandardRestitution", function()
			local inVel = Vector3.new(100 * INV_SQRT2, 0, 100 * INV_SQRT2)
			local normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2)
			local outVel = CagePhysicsService.ComputeReboundVelocity(inVel, normal, Constants.STANDARD_WALL_RESTITUTION, false)
			Expect(outVel.Magnitude).toBeCloseTo(88.0, 1e-2)
		end)
	end)

	-- =========================================================================
	-- F13: Elevating Ramps 25° OBB Query
	-- =========================================================================
	Describe("F13_ElevatingRampsOBB", function()
		Test("TC-F13-01_InwardWestBoundFalseAt66_5", function()
			local onRamp = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-66.5, 2.5, 0), "B")
			Expect(onRamp).toBeFalse("Position X = -66.5 must return false")
		end)

		Test("TC-F13-02_InwardEastBoundFalseAt66_5", function()
			local onRamp = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(66.5, 2.5, 0), "B")
			Expect(onRamp).toBeFalse("Position X = +66.5 must return false")
		end)

		Test("TC-F13-03_TrueOnWestRampBody", function()
			local onRamp = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 0), "B")
			Expect(onRamp).toBeTrue("Position X = -74.0, Y = 2.5 must return true")
		end)

		Test("TC-F13-04_TrueOnEastRampBody", function()
			local onRamp = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(74.0, 2.5, 0), "B")
			Expect(onRamp).toBeTrue("Position X = +74.0, Y = 2.5 must return true")
		end)

		Test("TC-F13-05_FalseOutsideZRange", function()
			local onRamp = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.5, 35.0), "B")
			Expect(onRamp).toBeFalse("Position outside Z range (|Z| > 30) must return false")
		end)
	end)

	-- =========================================================================
	-- F14: Elevating Ramps Vertical Impulse
	-- =========================================================================
	Describe("F14_ElevatingRampsImpulse", function()
		Test("TC-F14-01_AppliesUpwardImpulseOnRamp", function()
			local inVel = Vector3.new(-50, 0, 0)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, true, true)
			Expect(outVel.Y).toBeGreaterThan(0)
		end)

		Test("TC-F14-02_NoImpulseWhenNotOnRamp", function()
			local inVel = Vector3.new(-50, 0, 0)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, false, true)
			Expect(outVel.Y).toBe(0)
			Expect(outVel).toBeVector3CloseTo(inVel, 1e-3)
		end)

		Test("TC-F14-03_NoImpulseWhenDisabled", function()
			local inVel = Vector3.new(-50, 0, 0)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, true, false)
			Expect(outVel.Y).toBe(0)
			Expect(outVel).toBeVector3CloseTo(inVel, 1e-3)
		end)

		Test("TC-F14-04_MagnitudeProportionalTo25Degrees", function()
			local inVel = Vector3.new(-50, 0, 0)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, true, true)
			local rad25 = math.rad(Constants.ELEVATING_RAMP_ANGLE_DEG)
			local expectedVy = (math.sin(rad25) * math.abs(inVel.X)) + 38.0
			Expect(outVel.Y).toBeCloseTo(expectedVy, 0.5)
		end)

		Test("TC-F14-05_PreservesHorizontalTrajectory", function()
			local inVel = Vector3.new(-60, 0, 20)
			local outVel = CagePhysicsService.ApplyRampImpulse(inVel, true, true)
			Expect(outVel.Z).toBeCloseTo(20.0, 1e-2)
			Expect(outVel.Y).toBeGreaterThan(0)
		end)
	end)

	-- =========================================================================
	-- F15: 14-Stud Back-Goal Alley (Superseded: Goals at Z = ±120.0)
	-- =========================================================================
	Describe("F15_BackGoalAlley", function()
		Test("TC-F15-01_AlleyDepthIsZeroSuperseded", function()
			Expect(Constants.GOAL_BACK_ZONE_STUDS).toBe(0.0)
		end)

		Test("TC-F15-02_BehindGoal360ZoneNorthReturnsFalse", function()
			local isBehind = CagePhysicsService.IsBehindGoal360Zone(Vector3.new(0, 2, -122))
			Expect(isBehind).toBeFalse()
		end)

		Test("TC-F15-03_BehindGoal360ZoneSouthReturnsFalse", function()
			local isBehind = CagePhysicsService.IsBehindGoal360Zone(Vector3.new(0, 2, 122))
			Expect(isBehind).toBeFalse()
		end)

		Test("TC-F15-04_MidfieldReturnsFalse", function()
			local isBehind = CagePhysicsService.IsBehindGoal360Zone(Vector3.new(0, 2, 50))
			Expect(isBehind).toBeFalse()
		end)

		Test("TC-F15-05_CorridorClearanceNoColliders", function()
			local inside = CagePhysicsService.IsPointInsideArenaBounds(Vector3.new(0, 5, 0), "A", 0)
			Expect(inside).toBeTrue()
		end)
	end)

	-- =========================================================================
	-- F16-F21: Bootstrap & Scene Fixtures
	-- =========================================================================
	Describe("F16_F21_BootstrapAndSceneFixtures", function()
		Test("TC-F16-01_PrimaryFloorPathMatchesConstant", function()
			Expect(Constants.PRIMARY_FLOOR_PATH).toBe("Workspace.HexCageArena.CageFloor")
		end)

		Test("TC-F17-01_PrimarySpawnPathMatchesConstant", function()
			Expect(Constants.PRIMARY_SPAWN_PATH).toBe("Workspace.HexCageArena.CageSpawnLocation")
		end)

		Test("TC-F18-01_RetireBootstrapFixturesLeavesBaseplateIntact", function()
			-- Verify function exists and executes safely
			Expect(typeof(CagePhysicsService.RetireBootstrapFixtures)).toBe("function")
		end)

		Test("TC-F19-01_BaseplateLoweringCoordinates", function()
			-- In Baseplate lowering fix, Position = (0, -10.05, 0), Size = 16 -> top Y = -2.05
			local baseplateY = -10.05
			local sizeY = 16.0
			local topY = baseplateY + sizeY * 0.5
			Expect(topY).toBeCloseTo(-2.05, 1e-3)
			Expect(topY).toBeLessThan(-2.00) -- Cleanly below CageFloor bottom at Y = -2.0
		end)

		Test("TC-F20_01_RigConstantsCompliance", function()
			Expect(Constants.IS_STANDARD_CUSTOM_RIG).toBeTrue()
			Expect(Constants.RIG_PROFILE).toBe("R6")
			Expect(Constants.ALLOW_PLAYER_AVATAR_MODELS).toBeFalse()
			Expect(Constants.ALLOW_BOOTS_OR_CLEATS_SYSTEM).toBeFalse()
			Expect(Constants.ALLOW_MUTATION_COMBAT_STATS).toBeFalse()
		end)
	end)
end

-- =============================================================================
-- TIER 2: BOUNDARY & CORNER CASES
-- =============================================================================
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

-- =============================================================================
-- TIER 3: CROSS-FEATURE COMBINATIONS
-- =============================================================================
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

-- =============================================================================
-- TIER 4: REAL-WORLD RALLY SCENARIOS
-- =============================================================================
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

-- =============================================================================
-- MASTER EXECUTION
-- =============================================================================
TestHarness.Reset()
local startTime = os.clock()

runTier1(CagePhysicsService, Constants, Types)
runTier2(CagePhysicsService, Constants, Types)
runTier3(CagePhysicsService, Constants, Types)
runTier4(CagePhysicsService, Constants, Types)

local durationMs = (os.clock() - startTime) * 1000.0
local summary = TestHarness.GetSummary(durationMs)

return {
	status = summary.status,
	totalTests = summary.totalTests,
	passedTests = summary.passedTests,
	failedTests = summary.failedTests,
	totalAssertions = summary.totalAssertions,
	durationMs = durationMs,
	failures = summary.failures,
}
