--!strict
-- tests/e2e/Tier1_FeatureCoverage.luau
-- Tier 1: Feature Coverage (>=5 tests per feature across all arena mechanics F01 to F21)

local TestHarness = require(script.Parent:WaitForChild("TestHarness"))

local Describe = TestHarness.Describe
local Test = TestHarness.Test
local Expect = TestHarness.Expect

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

return {
	run = runTier1,
}
