--!strict
-- src/server/services/CagePhysicsService.luau
-- Module 01: 01-cage-physics (3D Cage Variants A/B/C, Unified ArenaGeometry Catalog, Swept-Sphere Solver & 5 Base Rebound Mechanics)

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

export type StepCollisionOptions = {
	variantId: Types.CageVariantInput?,
	ballRadius: number?,
	maxSubsteps: number?,
	featureFlags: Types.ReboundFeatureFlags?,
}

export type TrajectoryLaunchConfig = {
	scenarioId: string?,
	variantId: Types.CageVariantInput?,
	initialPosition: Vector3,
	initialVelocity: Vector3,
	dt: number?,
	maxDurationSec: number?,
	gravityY: number?,
	ballRadius: number?,
	featureFlags: Types.ReboundFeatureFlags?,
}

export type TrajectoryProbeResult = {
	scenarioId: string,
	variantId: Types.CageVariantId,
	featureFlags: Types.ReboundFeatureFlags,
	initialPosition: Vector3,
	initialVelocity: Vector3,
	initialSpeed: number,
	firstHitSurfaceTag: string?,
	firstHitPosition: Vector3?,
	firstHitTimeSec: number?,
	speedBeforeFirstHit: number,
	speedPreCapFirstHit: number,
	speedAfterFirstHit: number,
	firstReboundVelocity: Vector3?,
	landingPosition: Vector3,
	landingTimeSec: number,
	landedOnFloorAfterRebound: boolean,
	totalSteps: number,
	totalHitCount: number,
	hitSurfaces: { string },
	repeatedContactCount: number,
	cornerStuck: boolean,
	escapedBounds: boolean,
	budgetExhaustedCount: number,
	finalPosition: Vector3,
	finalVelocity: Vector3,
}

local ARENA_MODEL_NAME = Constants.ARENA_MODEL_NAME
local ARENA_HALF_LENGTH_Z = Constants.ARENA_HALF_LENGTH_Z
local ARENA_HALF_WIDTH_X = Constants.ARENA_HALF_WIDTH_X
local ARENA_CEILING_HEIGHT_Y = Constants.ARENA_CEILING_HEIGHT_Y
local CHAMFER_CUT_STUDS = Constants.CHAMFER_CUT_STUDS
local ROOF_BEVEL_STUDS = Constants.ROOF_BEVEL_STUDS
local ROOF_EAVE_HEIGHT_Y = Constants.ROOF_EAVE_HEIGHT_Y
local BALL_RADIUS = Constants.BALL_RADIUS
local FLOOR_RESTITUTION = Constants.FLOOR_RESTITUTION
local STANDARD_WALL_RESTITUTION = Constants.STANDARD_WALL_RESTITUTION
local TRANSOM_RESTITUTION = Constants.TRANSOM_RESTITUTION
local BUMPER_RESTITUTION = Constants.BUMPER_RESTITUTION
local PILLAR_RESTITUTION = Constants.PILLAR_RESTITUTION
local MAX_REBOUND_SPEED = Constants.MAX_REBOUND_SPEED
local MAX_COLLISION_SUBSTEPS = Constants.MAX_COLLISION_SUBSTEPS
local GOAL_WIDTH_X = Constants.GOAL_WIDTH_X
local GOAL_HEIGHT_Y = Constants.GOAL_HEIGHT_Y
local GOAL_DEPTH_Z = Constants.GOAL_DEPTH_Z
local GOAL_BACK_ZONE_STUDS = Constants.GOAL_BACK_ZONE_STUDS
local GOAL_POST_THICKNESS = Constants.GOAL_POST_THICKNESS or 0.8
local GOAL_POST_X = Constants.GOAL_POST_X or 12.0
local GOAL_CROSSBAR_HEIGHT_Y = Constants.GOAL_CROSSBAR_HEIGHT_Y or 10.0
local GOAL_LINE_Z = Constants.GOAL_LINE_Z or 120.0
local ELEVATING_RAMP_ANGLE_DEG = Constants.ELEVATING_RAMP_ANGLE_DEG

local SQRT2 = math.sqrt(2.0)
local INV_SQRT2 = 1.0 / SQRT2
local WALL_THICKNESS = 2.0

local DEFAULT_FEATURE_FLAGS: Types.ReboundFeatureFlags = table.freeze({
	enableBumpers = true,
	enableTransom = true,
	enableRamps = true,
	includeCornerOverlayInA = false,
})

local activeArenaModel: Model? = nil
local activeVariantId: Types.CageVariantId = Constants.DEFAULT_CAGE_VARIANT :: Types.CageVariantId
local activeFeatureFlags: Types.ReboundFeatureFlags = {
	enableBumpers = true,
	enableTransom = true,
	enableRamps = true,
	includeCornerOverlayInA = false,
}
local isInitialized = false

local function makeSurfaceCFrame(center: Vector3, inwardNormal: Vector3, upHint: Vector3?): CFrame
	local n = inwardNormal.Unit
	local refUp = upHint or Vector3.new(0, 1, 0)
	if math.abs(n:Dot(refUp)) > 0.999 then
		refUp = Vector3.new(0, 0, 1)
	end
	local right = refUp:Cross(n).Unit
	local up = n:Cross(right).Unit
	return CFrame.fromMatrix(center, right, up, -n)
end

local function buildVariantCatalog(variantId: Types.CageVariantId): Types.ArenaGeometryProfile
	local hasChamfer = (variantId == "B" or variantId == "C")
	local hasBevel = (variantId == "C")
	local wallHeightY = if hasBevel then ROOF_EAVE_HEIGHT_Y else ARENA_CEILING_HEIGHT_Y
	local cutStuds = if hasChamfer then CHAMFER_CUT_STUDS else 0.0
	local bevelStuds = if hasBevel then ROOF_BEVEL_STUDS else 0.0

	local polygonXZ: { Vector2 } = if hasChamfer
		then {
			Vector2.new(-(ARENA_HALF_WIDTH_X - cutStuds), -ARENA_HALF_LENGTH_Z), -- (-60, -120)
			Vector2.new(ARENA_HALF_WIDTH_X - cutStuds, -ARENA_HALF_LENGTH_Z), -- (60, -120)
			Vector2.new(ARENA_HALF_WIDTH_X, -(ARENA_HALF_LENGTH_Z - cutStuds)), -- (80, -100)
			Vector2.new(ARENA_HALF_WIDTH_X, ARENA_HALF_LENGTH_Z - cutStuds), -- (80, 100)
			Vector2.new(ARENA_HALF_WIDTH_X - cutStuds, ARENA_HALF_LENGTH_Z), -- (60, 120)
			Vector2.new(-(ARENA_HALF_WIDTH_X - cutStuds), ARENA_HALF_LENGTH_Z), -- (-60, 120)
			Vector2.new(-ARENA_HALF_WIDTH_X, ARENA_HALF_LENGTH_Z - cutStuds), -- (-80, 100)
			Vector2.new(-ARENA_HALF_WIDTH_X, -(ARENA_HALF_LENGTH_Z - cutStuds)), -- (-80, -100)
		}
		else {
			Vector2.new(-ARENA_HALF_WIDTH_X, -ARENA_HALF_LENGTH_Z), -- (-80, -120)
			Vector2.new(ARENA_HALF_WIDTH_X, -ARENA_HALF_LENGTH_Z), -- (80, -120)
			Vector2.new(ARENA_HALF_WIDTH_X, ARENA_HALF_LENGTH_Z), -- (80, 120)
			Vector2.new(-ARENA_HALF_WIDTH_X, ARENA_HALF_LENGTH_Z), -- (-80, 120)
		}

	local surfaces: { Types.ArenaSurfaceDef } = {}

	-- 1. Floor (top surface at Y = 0.0)
	table.insert(surfaces, {
		surfaceId = "CageFloor",
		kind = "Floor",
		size = Vector3.new(ARENA_HALF_WIDTH_X * 2.0, WALL_THICKNESS, ARENA_HALF_LENGTH_Z * 2.0),
		cframe = CFrame.new(0, -WALL_THICKNESS * 0.5, 0),
		normal = Vector3.new(0, 1, 0),
		restitution = FLOOR_RESTITUTION,
		color = Color3.fromRGB(44, 48, 52),
		material = Enum.Material.Concrete,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
	})

	-- 2. Primary Spawn Location (invisible anchor at center so no blue pad is visible on the concrete pitch)
	table.insert(surfaces, {
		surfaceId = "CageSpawnLocation",
		kind = "SpawnLocation",
		size = Vector3.new(6.0, 0.2, 6.0),
		cframe = CFrame.new(0, 0.1, 0),
		normal = Vector3.new(0, 1, 0),
		restitution = FLOOR_RESTITUTION,
		color = Color3.fromRGB(44, 48, 52),
		material = Enum.Material.SmoothPlastic,
		transparency = 1.0,
		canCollide = false,
		canQuery = false,
		isGuideOnly = true,
	})

	-- 3. Four Main Cardinal Walls (inner face aligned# to X = ±80 and Z = ±120)
	local northSouthSpanX = if hasChamfer then (ARENA_HALF_WIDTH_X - cutStuds) * 2.0 else ARENA_HALF_WIDTH_X * 2.0 -- 120 or 160
	local westEastSpanZ = if hasChamfer then (ARENA_HALF_LENGTH_Z - cutStuds) * 2.0 else ARENA_HALF_LENGTH_Z * 2.0 -- 200 or 240

	local mainWalls = {
		{
			id = "Wall_West",
			size = Vector3.new(WALL_THICKNESS, wallHeightY, westEastSpanZ),
			cframe = CFrame.new(-(ARENA_HALF_WIDTH_X + WALL_THICKNESS * 0.5), wallHeightY * 0.5, 0),
			normal = Vector3.new(1, 0, 0),
		},
		{
			id = "Wall_East",
			size = Vector3.new(WALL_THICKNESS, wallHeightY, westEastSpanZ),
			cframe = CFrame.new(ARENA_HALF_WIDTH_X + WALL_THICKNESS * 0.5, wallHeightY * 0.5, 0),
			normal = Vector3.new(-1, 0, 0),
		},
		{
			id = "Wall_North",
			size = Vector3.new(northSouthSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(0, wallHeightY * 0.5, -(ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5)),
			normal = Vector3.new(0, 0, 1),
			canCollide = false,
			canQuery = false,
		},
		{
			id = "Wall_South",
			size = Vector3.new(northSouthSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(0, wallHeightY * 0.5, ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5),
			normal = Vector3.new(0, 0, -1),
			canCollide = false,
			canQuery = false,
		},
	}

	for _, w in ipairs(mainWalls) do
		table.insert(surfaces, {
			surfaceId = w.id,
			kind = "Wall",
			size = w.size,
			cframe = w.cframe,
			normal = w.normal,
			restitution = STANDARD_WALL_RESTITUTION,
			color = Color3.fromRGB(55, 60, 66),
			material = Enum.Material.Glass,
			transparency = 0.78,
			canCollide = if w.canCollide ~= nil then w.canCollide else true,
			canQuery = if w.canQuery ~= nil then w.canQuery else true,
			isGuideOnly = false,
		})
	end

	-- North & South End Wall Segments Left and Right of Goal Mouth (Physics Colliders)
	local endWallSideSpanX = (northSouthSpanX - GOAL_WIDTH_X) * 0.5
	local endWallSideOffset = (GOAL_WIDTH_X + endWallSideSpanX) * 0.5
	local endWallSegments = {
		{
			id = "Wall_North_Left",
			size = Vector3.new(endWallSideSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(-endWallSideOffset, wallHeightY * 0.5, -(ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5)),
			normal = Vector3.new(0, 0, 1),
		},
		{
			id = "Wall_North_Right",
			size = Vector3.new(endWallSideSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(endWallSideOffset, wallHeightY * 0.5, -(ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5)),
			normal = Vector3.new(0, 0, 1),
		},
		{
			id = "Wall_South_Left",
			size = Vector3.new(endWallSideSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(-endWallSideOffset, wallHeightY * 0.5, ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5),
			normal = Vector3.new(0, 0, -1),
		},
		{
			id = "Wall_South_Right",
			size = Vector3.new(endWallSideSpanX, wallHeightY, WALL_THICKNESS),
			cframe = CFrame.new(endWallSideOffset, wallHeightY * 0.5, ARENA_HALF_LENGTH_Z + WALL_THICKNESS * 0.5),
			normal = Vector3.new(0, 0, -1),
		},
	}
	for _, w in ipairs(endWallSegments) do
		table.insert(surfaces, {
			surfaceId = w.id,
			kind = "Wall",
			size = w.size,
			cframe = w.cframe,
			normal = w.normal,
			restitution = STANDARD_WALL_RESTITUTION,
			color = Color3.fromRGB(55, 60, 66),
			material = Enum.Material.Glass,
			transparency = 0.78,
			canCollide = true,
			canQuery = true,
			isGuideOnly = false,
		})
	end

	-- 4. Four Chamfered Corner Walls (Variants B & C) + 4 Corner Pinball Bumpers
	local cornerDefs = {
		{
			suffix = "NW",
			innerMidXZ = Vector2.new(-(ARENA_HALF_WIDTH_X - cutStuds * 0.5), -(ARENA_HALF_LENGTH_Z - cutStuds * 0.5)), -- (-70, -110)
			normal = Vector3.new(INV_SQRT2, 0, INV_SQRT2),
		},
		{
			suffix = "NE",
			innerMidXZ = Vector2.new(ARENA_HALF_WIDTH_X - cutStuds * 0.5, -(ARENA_HALF_LENGTH_Z - cutStuds * 0.5)), -- (70, -110)
			normal = Vector3.new(-INV_SQRT2, 0, INV_SQRT2),
		},
		{
			suffix = "SW",
			innerMidXZ = Vector2.new(-(ARENA_HALF_WIDTH_X - cutStuds * 0.5), ARENA_HALF_LENGTH_Z - cutStuds * 0.5), -- (-70, 110)
			normal = Vector3.new(INV_SQRT2, 0, -INV_SQRT2),
		},
		{
			suffix = "SE",
			innerMidXZ = Vector2.new(ARENA_HALF_WIDTH_X - cutStuds * 0.5, ARENA_HALF_LENGTH_Z - cutStuds * 0.5), -- (70, 110)
			normal = Vector3.new(-INV_SQRT2, 0, -INV_SQRT2),
		},
	}

	local chamferLength = (if cutStuds > 0 then cutStuds else CHAMFER_CUT_STUDS) * SQRT2 -- 20 * sqrt(2) = 28.284271
	if hasChamfer then
		for _, cDef in ipairs(cornerDefs) do
			local innerMid = Vector3.new(cDef.innerMidXZ.X, wallHeightY * 0.5, cDef.innerMidXZ.Y)
			local wallCenter = innerMid - (cDef.normal * (WALL_THICKNESS * 0.5))
			table.insert(surfaces, {
				surfaceId = "CornerWall_" .. cDef.suffix,
				kind = "CornerWall",
				size = Vector3.new(chamferLength, wallHeightY, WALL_THICKNESS),
				cframe = makeSurfaceCFrame(wallCenter, cDef.normal),
				normal = cDef.normal,
				restitution = STANDARD_WALL_RESTITUTION,
				color = Color3.fromRGB(55, 60, 66),
				material = Enum.Material.DiamondPlate,
				transparency = 0.50,
				canCollide = true,
				canQuery = true,
				isGuideOnly = false,
			})
		end
	end

	-- Pinball Bumpers on all 4 corners (native on B & C chamfer walls; optional overlay on A for Mechanics Pass comparison)
	local bumperHeightY = 16.0
	local bumperThickness = 1.0
	for _, cDef in ipairs(cornerDefs) do
		local bMidX = if hasChamfer
			then cDef.innerMidXZ.X
			else (if cDef.normal.X > 0 then -(ARENA_HALF_WIDTH_X - 10.0) else (ARENA_HALF_WIDTH_X - 10.0))
		local bMidZ = if hasChamfer
			then cDef.innerMidXZ.Y
			else (if cDef.normal.Z > 0 then -(ARENA_HALF_LENGTH_Z - 10.0) else (ARENA_HALF_LENGTH_Z - 10.0))
		local innerMid = Vector3.new(bMidX, bumperHeightY * 0.5, bMidZ)
		local bumperCenter = innerMid - (cDef.normal * (bumperThickness * 0.5))
		table.insert(surfaces, {
			surfaceId = "PinballBumper_" .. cDef.suffix,
			kind = "PinballBumper",
			size = Vector3.new(chamferLength, bumperHeightY, bumperThickness),
			cframe = makeSurfaceCFrame(bumperCenter, cDef.normal),
			normal = cDef.normal,
			restitution = BUMPER_RESTITUTION,
			color = Color3.fromRGB(155, 115, 45),
			material = Enum.Material.DiamondPlate,
			transparency = 0,
			canCollide = hasChamfer, -- In Variant A, only enabled when includeCornerOverlayInA is true
			canQuery = hasChamfer,
			isGuideOnly = false,
			requiresBumperFlag = true,
		})
	end

	-- 5. Ceiling & Variant C 45-Degree Beveled Roof Faces
	-- Critical Contract (P-02b 3.1): In Variant C, CageCeiling covers ONLY the central flat roof [-72, 72] x [-112, 112]
	-- and NEVER overlaps under the 8 45-degree bevel faces.
	local centralRoofHalfX = if hasBevel then (ARENA_HALF_WIDTH_X - bevelStuds) else ARENA_HALF_WIDTH_X -- 72 or 80
	local centralRoofHalfZ = if hasBevel then (ARENA_HALF_LENGTH_Z - bevelStuds) else ARENA_HALF_LENGTH_Z -- 112 or 120

	table.insert(surfaces, {
		surfaceId = "CageCeiling",
		kind = "Ceiling",
		size = Vector3.new(centralRoofHalfX * 2.0, WALL_THICKNESS, centralRoofHalfZ * 2.0),
		cframe = CFrame.new(0, ARENA_CEILING_HEIGHT_Y + (WALL_THICKNESS * 0.5), 0),
		normal = Vector3.new(0, -1, 0),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(55, 60, 66),
		material = Enum.Material.Glass,
		transparency = 0.78,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
	})

	if hasBevel then
		local bevelSlopeLen = bevelStuds * SQRT2 -- 8 * sqrt(2) = 11.313708
		local bevelMidY = ROOF_EAVE_HEIGHT_Y + (bevelStuds * 0.5) -- 28.0
		local sideBevels = {
			{
				id = "RoofBevel_West",
				span = westEastSpanZ,
				innerMid = Vector3.new(-(ARENA_HALF_WIDTH_X - bevelStuds * 0.5), bevelMidY, 0),
				horizInward = Vector3.new(1, 0, 0),
			},
			{
				id = "RoofBevel_East",
				span = westEastSpanZ,
				innerMid = Vector3.new(ARENA_HALF_WIDTH_X - bevelStuds * 0.5, bevelMidY, 0),
				horizInward = Vector3.new(-1, 0, 0),
			},
			{
				id = "RoofBevel_North",
				span = northSouthSpanX,
				innerMid = Vector3.new(0, bevelMidY, -(ARENA_HALF_LENGTH_Z - bevelStuds * 0.5)),
				horizInward = Vector3.new(0, 0, 1),
			},
			{
				id = "RoofBevel_South",
				span = northSouthSpanX,
				innerMid = Vector3.new(0, bevelMidY, ARENA_HALF_LENGTH_Z - bevelStuds * 0.5),
				horizInward = Vector3.new(0, 0, -1),
			},
		}

		for _, sb in ipairs(sideBevels) do
			local bevelNormal = Vector3.new(
				sb.horizInward.X * INV_SQRT2,
				-INV_SQRT2,
				sb.horizInward.Z * INV_SQRT2
			).Unit
			local slabCenter = sb.innerMid - (bevelNormal * (WALL_THICKNESS * 0.5))
			local upAlongSlope = Vector3.new(
				sb.horizInward.X * INV_SQRT2,
				INV_SQRT2,
				sb.horizInward.Z * INV_SQRT2
			).Unit
			table.insert(surfaces, {
				surfaceId = sb.id,
				kind = "RoofBevel",
				size = Vector3.new(sb.span, bevelSlopeLen, WALL_THICKNESS),
				cframe = makeSurfaceCFrame(slabCenter, bevelNormal, upAlongSlope),
				normal = bevelNormal,
				restitution = STANDARD_WALL_RESTITUTION,
				color = Color3.fromRGB(42, 46, 52),
				material = Enum.Material.Metal,
				transparency = 0.40,
				canCollide = true,
				canQuery = true,
				isGuideOnly = false,
			})
		end

		-- 4 Corner Bevel Faces (connecting the 4 chamfered corner walls from Y=24 to Y=32 at 45 degrees)
		local cornerBevelWidth = chamferLength + (bevelStuds * 1.2)
		for _, cDef in ipairs(cornerDefs) do
			local horizInward = cDef.normal -- (±1/sqrt(2), 0, ±1/sqrt(2))
			local bevelNormal = Vector3.new(
				horizInward.X * INV_SQRT2,
				-INV_SQRT2,
				horizInward.Z * INV_SQRT2
			).Unit
			local eaveMid = Vector3.new(cDef.innerMidXZ.X, ROOF_EAVE_HEIGHT_Y, cDef.innerMidXZ.Y)
			local innerSlopeMid = eaveMid + (horizInward * (bevelStuds * 0.5)) + Vector3.new(0, bevelStuds * 0.5, 0)
			local slabCenter = innerSlopeMid - (bevelNormal * (WALL_THICKNESS * 0.5))
			local upAlongSlope = Vector3.new(
				horizInward.X * INV_SQRT2,
				INV_SQRT2,
				horizInward.Z * INV_SQRT2
			).Unit
			table.insert(surfaces, {
				surfaceId = "RoofBevel_" .. cDef.suffix,
				kind = "RoofBevel",
				size = Vector3.new(cornerBevelWidth, bevelSlopeLen, WALL_THICKNESS),
				cframe = makeSurfaceCFrame(slabCenter, bevelNormal, upAlongSlope),
				normal = bevelNormal,
				restitution = STANDARD_WALL_RESTITUTION,
				color = Color3.fromRGB(45, 50, 56),
				material = Enum.Material.Metal,
				transparency = 0.40,
				canCollide = true,
				canQuery = true,
				isGuideOnly = false,
			})
		end
	end

	-- 6. Standard Goal Posts & Edge Transom at Cage Wall Edge (Z = ±120.0, GOAL_BACK_ZONE_STUDS = 0.0)
	--    Physical posts: Left/Right vertical posts (X = ±12.0, Y in [0, 10.0]), Crossbar (X in [-12, +12], Y = 10.0)
	--    Open goal mouth (CanCollide = false) for scoring detection (CheckGoalScored)
	--    Transom panel above crossbar (Y in [10.0, wallHeightY]) flush at Z = ±120.0
	local northGoalZ = -(ARENA_HALF_LENGTH_Z - GOAL_BACK_ZONE_STUDS) -- -120.0
	local southGoalZ = ARENA_HALF_LENGTH_Z - GOAL_BACK_ZONE_STUDS -- +120.0
	local crossbarTopY = 10.0
	local transomHeightY = wallHeightY - crossbarTopY -- 22.0 for A/B, 14.0 for C
	local transomCenterY = crossbarTopY + (transomHeightY * 0.5) -- 21.0 for A/B, 17.0 for C
	local transomThicknessZ = GOAL_POST_THICKNESS -- 0.8 studs, perfectly flush with crossbar and vertical posts
	local crossbarLengthX = GOAL_WIDTH_X + GOAL_POST_THICKNESS -- 24.8 studs

	-- North Goal (Z = -120.0)
	-- Left Post (X = -12.0, Y in [0, 10.0], CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalPost_North_Left",
		kind = "GoalPost",
		size = Vector3.new(GOAL_POST_THICKNESS, GOAL_HEIGHT_Y, GOAL_POST_THICKNESS),
		cframe = CFrame.new(-GOAL_POST_X, GOAL_HEIGHT_Y * 0.5, northGoalZ),
		normal = Vector3.new(0, 0, 1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "North",
	})

	-- Right Post (X = +12.0, Y in [0, 10.0], CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalPost_North_Right",
		kind = "GoalPost",
		size = Vector3.new(GOAL_POST_THICKNESS, GOAL_HEIGHT_Y, GOAL_POST_THICKNESS),
		cframe = CFrame.new(GOAL_POST_X, GOAL_HEIGHT_Y * 0.5, northGoalZ),
		normal = Vector3.new(0, 0, 1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "North",
	})

	-- Crossbar (X in [-12, +12], Y = 10.0, CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalCrossbar_North",
		kind = "GoalCrossbar",
		size = Vector3.new(crossbarLengthX, GOAL_POST_THICKNESS, GOAL_POST_THICKNESS),
		cframe = CFrame.new(0, GOAL_CROSSBAR_HEIGHT_Y, northGoalZ),
		normal = Vector3.new(0, 0, 1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "North",
	})

	-- Open Goal Mouth for scoring detection (CanCollide = false, invisible trigger)
	table.insert(surfaces, {
		surfaceId = "Goal_North",
		kind = "GoalFrame",
		size = Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
		cframe = CFrame.new(0, GOAL_HEIGHT_Y * 0.5, northGoalZ),
		normal = Vector3.new(0, 0, 1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.SmoothPlastic,
		transparency = 1.0,
		canCollide = false,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "North",
	})

	-- Over-Goal Transom Panel (Y in [10.0, wallHeightY], flush at Z = -120.0, e = 0.95, gritty smoked glass)
	table.insert(surfaces, {
		surfaceId = "Transom_North",
		kind = "GoalTransom",
		size = Vector3.new(GOAL_WIDTH_X, transomHeightY, transomThicknessZ),
		cframe = CFrame.new(0, transomCenterY, northGoalZ - (transomThicknessZ * 0.5)),
		normal = Vector3.new(0, 0, 1),
		restitution = TRANSOM_RESTITUTION,
		color = Color3.fromRGB(55, 60, 66),
		material = Enum.Material.Glass,
		transparency = 0.78,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		requiresTransomFlag = true,
		goalSide = "North",
	})

	-- South Goal (Z = +120.0)
	-- Left Post (X = -12.0, Y in [0, 10.0], CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalPost_South_Left",
		kind = "GoalPost",
		size = Vector3.new(GOAL_POST_THICKNESS, GOAL_HEIGHT_Y, GOAL_POST_THICKNESS),
		cframe = CFrame.new(-GOAL_POST_X, GOAL_HEIGHT_Y * 0.5, southGoalZ),
		normal = Vector3.new(0, 0, -1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "South",
	})

	-- Right Post (X = +12.0, Y in [0, 10.0], CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalPost_South_Right",
		kind = "GoalPost",
		size = Vector3.new(GOAL_POST_THICKNESS, GOAL_HEIGHT_Y, GOAL_POST_THICKNESS),
		cframe = CFrame.new(GOAL_POST_X, GOAL_HEIGHT_Y * 0.5, southGoalZ),
		normal = Vector3.new(0, 0, -1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "South",
	})

	-- Crossbar (X in [-12, +12], Y = 10.0, CanCollide = true, weathered metal/steel)
	table.insert(surfaces, {
		surfaceId = "GoalCrossbar_South",
		kind = "GoalCrossbar",
		size = Vector3.new(crossbarLengthX, GOAL_POST_THICKNESS, GOAL_POST_THICKNESS),
		cframe = CFrame.new(0, GOAL_CROSSBAR_HEIGHT_Y, southGoalZ),
		normal = Vector3.new(0, 0, -1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.Metal,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "South",
	})

	-- Open Goal Mouth for scoring detection (CanCollide = false, invisible trigger)
	table.insert(surfaces, {
		surfaceId = "Goal_South",
		kind = "GoalFrame",
		size = Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
		cframe = CFrame.new(0, GOAL_HEIGHT_Y * 0.5, southGoalZ),
		normal = Vector3.new(0, 0, -1),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(205, 208, 212),
		material = Enum.Material.SmoothPlastic,
		transparency = 1.0,
		canCollide = false,
		canQuery = true,
		isGuideOnly = false,
		goalSide = "South",
	})

	-- Over-Goal Transom Panel (Y in [10.0, wallHeightY], flush at Z = +120.0, e = 0.95, gritty smoked glass)
	table.insert(surfaces, {
		surfaceId = "Transom_South",
		kind = "GoalTransom",
		size = Vector3.new(GOAL_WIDTH_X, transomHeightY, transomThicknessZ),
		cframe = CFrame.new(0, transomCenterY, southGoalZ + (transomThicknessZ * 0.5)),
		normal = Vector3.new(0, 0, -1),
		restitution = TRANSOM_RESTITUTION,
		color = Color3.fromRGB(55, 60, 66),
		material = Enum.Material.Glass,
		transparency = 0.78,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		requiresTransomFlag = true,
		goalSide = "South",
	})

	-- Goal Pocket Surfaces (Back, Sides, Top Net Colliders)
	local pocketThickness = 0.5
	local pocketRestitution = 0.40
	local pocketSurfaces = {
		-- North Goal Pocket (Z in [-126.0, -120.0])
		{
			id = "GoalBackNet_North",
			size = Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, pocketThickness),
			cframe = CFrame.new(0, GOAL_HEIGHT_Y * 0.5, northGoalZ - GOAL_DEPTH_Z),
			normal = Vector3.new(0, 0, 1),
			side = "North",
		},
		{
			id = "GoalSideNet_North_Left",
			size = Vector3.new(pocketThickness, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
			cframe = CFrame.new(-GOAL_WIDTH_X * 0.5, GOAL_HEIGHT_Y * 0.5, northGoalZ - GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(1, 0, 0),
			side = "North",
		},
		{
			id = "GoalSideNet_North_Right",
			size = Vector3.new(pocketThickness, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
			cframe = CFrame.new(GOAL_WIDTH_X * 0.5, GOAL_HEIGHT_Y * 0.5, northGoalZ - GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(-1, 0, 0),
			side = "North",
		},
		{
			id = "GoalTopNet_North",
			size = Vector3.new(GOAL_WIDTH_X, pocketThickness, GOAL_DEPTH_Z),
			cframe = CFrame.new(0, GOAL_HEIGHT_Y, northGoalZ - GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(0, -1, 0),
			side = "North",
		},
		-- South Goal Pocket (Z in [120.0, 126.0])
		{
			id = "GoalBackNet_South",
			size = Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, pocketThickness),
			cframe = CFrame.new(0, GOAL_HEIGHT_Y * 0.5, southGoalZ + GOAL_DEPTH_Z),
			normal = Vector3.new(0, 0, -1),
			side = "South",
		},
		{
			id = "GoalSideNet_South_Left",
			size = Vector3.new(pocketThickness, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
			cframe = CFrame.new(-GOAL_WIDTH_X * 0.5, GOAL_HEIGHT_Y * 0.5, southGoalZ + GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(1, 0, 0),
			side = "South",
		},
		{
			id = "GoalSideNet_South_Right",
			size = Vector3.new(pocketThickness, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
			cframe = CFrame.new(GOAL_WIDTH_X * 0.5, GOAL_HEIGHT_Y * 0.5, southGoalZ + GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(-1, 0, 0),
			side = "South",
		},
		{
			id = "GoalTopNet_South",
			size = Vector3.new(GOAL_WIDTH_X, pocketThickness, GOAL_DEPTH_Z),
			cframe = CFrame.new(0, GOAL_HEIGHT_Y, southGoalZ + GOAL_DEPTH_Z * 0.5),
			normal = Vector3.new(0, -1, 0),
			side = "South",
		},
	}
	for _, pDef in ipairs(pocketSurfaces) do
		table.insert(surfaces, {
			surfaceId = pDef.id,
			kind = "GoalPocket",
			size = pDef.size,
			cframe = pDef.cframe,
			normal = pDef.normal,
			restitution = pocketRestitution,
			color = Color3.fromRGB(180, 185, 190),
			material = Enum.Material.Plastic,
			transparency = 0.5,
			canCollide = true,
			canQuery = true,
			isGuideOnly = false,
			goalSide = pDef.side,
		})
	end

	-- 7. Side Elevating Ramps 25° (X = ±74, Z in [-30, +30], size 12 x 2 x 60, dark industrial steel plate)
	local rampAngleRad = math.rad(ELEVATING_RAMP_ANGLE_DEG)
	local rampNormalLeft = Vector3.new(math.sin(rampAngleRad), math.cos(rampAngleRad), 0).Unit
	local rampNormalRight = Vector3.new(-math.sin(rampAngleRad), math.cos(rampAngleRad), 0).Unit

	table.insert(surfaces, {
		surfaceId = "ElevatingRamp_Left",
		kind = "ElevatingRamp",
		size = Vector3.new(12.0, 2.0, 60.0),
		cframe = CFrame.new(-74.0, 1.5, 0) * CFrame.Angles(0, 0, -rampAngleRad),
		normal = rampNormalLeft,
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(68, 72, 76),
		material = Enum.Material.DiamondPlate,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		requiresRampFlag = true,
	})

	table.insert(surfaces, {
		surfaceId = "ElevatingRamp_Right",
		kind = "ElevatingRamp",
		size = Vector3.new(12.0, 2.0, 60.0),
		cframe = CFrame.new(74.0, 1.5, 0) * CFrame.Angles(0, 0, rampAngleRad),
		normal = rampNormalRight,
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(68, 72, 76),
		material = Enum.Material.DiamondPlate,
		transparency = 0,
		canCollide = true,
		canQuery = true,
		isGuideOnly = false,
		requiresRampFlag = true,
	})

	-- 8. Ceiling Rebound Guide Markers (Zero Aim-Assist: CanCollide = false, CanQuery = false, IsGuideOnly = true)
	--    Gritty industrial metal stencil plates instead of bright neon
	table.insert(surfaces, {
		surfaceId = "CeilingReboundMarker_North",
		kind = "CeilingMarker",
		size = Vector3.new(10.0, 0.2, 10.0),
		cframe = CFrame.new(0, ARENA_CEILING_HEIGHT_Y - 0.1, -68.0),
		normal = Vector3.new(0, -1, 0),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(160, 165, 170),
		material = Enum.Material.Metal,
		transparency = 0.15,
		canCollide = false,
		canQuery = false,
		isGuideOnly = true,
		goalSide = "North",
	})

	table.insert(surfaces, {
		surfaceId = "CeilingReboundMarker_South",
		kind = "CeilingMarker",
		size = Vector3.new(10.0, 0.2, 10.0),
		cframe = CFrame.new(0, ARENA_CEILING_HEIGHT_Y - 0.1, 68.0),
		normal = Vector3.new(0, -1, 0),
		restitution = STANDARD_WALL_RESTITUTION,
		color = Color3.fromRGB(160, 165, 170),
		material = Enum.Material.Metal,
		transparency = 0.15,
		canCollide = false,
		canQuery = false,
		isGuideOnly = true,
		goalSide = "South",
	})

	local displayNames: { [Types.CageVariantId]: string } = {
		A = "A — Classic Box Cage (4 Walls, Flat Ceiling)",
		B = "B — Four-Corner Chamfered Cage (8 Walls, Flat Ceiling)",
		C = "C — Beveled Roof Street Cage (8 Walls, 45° Roof Bevel)",
	}

	return table.freeze({
		variantId = variantId,
		displayName = displayNames[variantId],
		wallCount = if hasChamfer then 8 else 4,
		hasChamferedCorners = hasChamfer,
		hasBeveledRoof = hasBevel,
		halfWidthX = ARENA_HALF_WIDTH_X,
		halfLengthZ = ARENA_HALF_LENGTH_Z,
		ceilingHeightY = ARENA_CEILING_HEIGHT_Y,
		eaveHeightY = wallHeightY,
		chamferCutStuds = cutStuds,
		roofBevelStuds = bevelStuds,
		ballRadius = BALL_RADIUS,
		goalFrontAbsZ = ARENA_HALF_LENGTH_Z - GOAL_BACK_ZONE_STUDS,
		backGoalAlleyStuds = GOAL_BACK_ZONE_STUDS,
		footprintPolygonXZ = table.freeze(polygonXZ),
		surfaces = table.freeze(surfaces),
	})
end

local ARENA_GEOMETRY_CATALOG: { [Types.CageVariantId]: Types.ArenaGeometryProfile } = table.freeze({
	A = buildVariantCatalog("A"),
	B = buildVariantCatalog("B"),
	C = buildVariantCatalog("C"),
})

local CagePhysicsService = {
	ARENA_MODEL_NAME = ARENA_MODEL_NAME,
	ARENA_HALF_LENGTH_Z = ARENA_HALF_LENGTH_Z,
	ARENA_HALF_WIDTH_X = ARENA_HALF_WIDTH_X,
	ARENA_CEILING_HEIGHT_Y = ARENA_CEILING_HEIGHT_Y,
	CHAMFER_CUT_STUDS = CHAMFER_CUT_STUDS,
	ROOF_BEVEL_STUDS = ROOF_BEVEL_STUDS,
	ROOF_EAVE_HEIGHT_Y = ROOF_EAVE_HEIGHT_Y,
	BALL_RADIUS = BALL_RADIUS,
	FLOOR_RESTITUTION = FLOOR_RESTITUTION,
	STANDARD_WALL_RESTITUTION = STANDARD_WALL_RESTITUTION,
	TRANSOM_RESTITUTION = TRANSOM_RESTITUTION,
	BUMPER_RESTITUTION = BUMPER_RESTITUTION,
	PILLAR_RESTITUTION = PILLAR_RESTITUTION,
	MAX_REBOUND_SPEED = MAX_REBOUND_SPEED,
	MAX_COLLISION_SUBSTEPS = MAX_COLLISION_SUBSTEPS,
	GOAL_WIDTH_X = GOAL_WIDTH_X,
	GOAL_HEIGHT_Y = GOAL_HEIGHT_Y,
	GOAL_DEPTH_Z = GOAL_DEPTH_Z,
	GOAL_BACK_ZONE_STUDS = GOAL_BACK_ZONE_STUDS,
	GOAL_POST_THICKNESS = GOAL_POST_THICKNESS,
	GOAL_POST_X = GOAL_POST_X,
	GOAL_CROSSBAR_HEIGHT_Y = GOAL_CROSSBAR_HEIGHT_Y,
	GOAL_LINE_Z = GOAL_LINE_Z,
	ArenaGeometry = ARENA_GEOMETRY_CATALOG,
}

local VARIANT_ALIAS_MAP: { [string]: Types.CageVariantId } = table.freeze({
	-- Canonical single-letter identifiers
	["A"] = "A",
	["B"] = "B",
	["C"] = "C",
	["a"] = "A",
	["b"] = "B",
	["c"] = "C",

	-- "VariantX" and "Variant_X" / "Variant-X" forms
	["VARIANTA"] = "A",
	["VARIANTB"] = "B",
	["VARIANTC"] = "C",
	["ARENAVARIANTA"] = "A",
	["ARENAVARIANTB"] = "B",
	["ARENAVARIANTC"] = "C",

	-- Hex prefixed descriptive names
	["HEXCLASSICVARIANTA"] = "A",
	["HEXCHAMFERVARIANTB"] = "B",
	["HEXSTREETVARIANTC"] = "C",
	["HEXCLASSICA"] = "A",
	["HEXCHAMFERB"] = "B",
	["HEXSTREETC"] = "C",
	["HEXCLASSIC"] = "A",
	["HEXCHAMFER"] = "B",
	["HEXSTREET"] = "C",

	-- Semantic keywords & full display names
	["CLASSIC"] = "A",
	["CLASSICBOX"] = "A",
	["CLASSICBOXCAGE"] = "A",
	["CHAMFER"] = "B",
	["CHAMFERED"] = "B",
	["FOURCORNERCHAMFEREDCAGE"] = "B",
	["STREET"] = "C",
	["STREETCAGE"] = "C",
	["BEVEL"] = "C",
	["BEVELED"] = "C",
	["BEVELROOF"] = "C",
	["BEVELEDROOF"] = "C",
	["BEVELEDROOFSTREETCAGE"] = "C",
})

local function normalizeVariantId(variantId: Types.CageVariantInput?): Types.CageVariantId
	if variantId == nil then
		return activeVariantId
	end

	-- Fast path: canonical uppercase single letter
	if variantId == "A" or variantId == "B" or variantId == "C" then
		return variantId
	end

	if typeof(variantId) ~= "string" then
		return activeVariantId
	end

	-- Sanitize: strip whitespace, hyphens, underscores, punctuation and convert to uppercase
	local clean = string.upper(string.gsub(variantId, "[%s%-_%p]", ""))

	-- 1. Exact alias dictionary lookup
	local mapped = VARIANT_ALIAS_MAP[clean]
	if mapped then
		return mapped
	end

	-- 2. Heuristic keyword and suffix matching
	if string.find(clean, "STREET") or string.find(clean, "BEVEL") or string.find(clean, "VARIANTC") or string.match(clean, "^C$") then
		return "C"
	elseif string.find(clean, "CHAMFER") or string.find(clean, "VARIANTB") or string.match(clean, "^B$") then
		return "B"
	elseif string.find(clean, "CLASSIC") or string.find(clean, "BOX") or string.find(clean, "VARIANTA") or string.match(clean, "^A$") then
		return "A"
	end

	-- Fallback to active variant if unrecognized
	return activeVariantId
end

local function registerCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("CageWalls")
		PhysicsService:RegisterCollisionGroup("CageBall")
		PhysicsService:RegisterCollisionGroup("CagePlayers")
	end)
end

function CagePhysicsService.GetArenaGeometryProfile(variantId: Types.CageVariantInput?): Types.ArenaGeometryProfile
	local vid = normalizeVariantId(variantId)
	return ARENA_GEOMETRY_CATALOG[vid]
end

function CagePhysicsService.GetAllArenaGeometryProfiles(): { [Types.CageVariantId]: Types.ArenaGeometryProfile }
	return ARENA_GEOMETRY_CATALOG
end

function CagePhysicsService.GetActiveVariantId(): Types.CageVariantId
	return activeVariantId
end

function CagePhysicsService.SetActiveVariantId(variantId: Types.CageVariantInput)
	activeVariantId = normalizeVariantId(variantId)
end

function CagePhysicsService.GetFeatureFlags(): Types.ReboundFeatureFlags
	return {
		enableBumpers = activeFeatureFlags.enableBumpers,
		enableTransom = activeFeatureFlags.enableTransom,
		enableRamps = activeFeatureFlags.enableRamps,
		includeCornerOverlayInA = activeFeatureFlags.includeCornerOverlayInA,
	}
end

function CagePhysicsService.SetFeatureFlags(flags: Types.ReboundFeatureFlags)
	activeFeatureFlags = {
		enableBumpers = flags.enableBumpers == true,
		enableTransom = flags.enableTransom == true,
		enableRamps = flags.enableRamps == true,
		includeCornerOverlayInA = flags.includeCornerOverlayInA == true,
	}
end

function CagePhysicsService.ComputeReboundVelocity(
	incidentVelocity: Vector3,
	surfaceNormal: Vector3,
	restitution: number
): (Vector3, number)
	if surfaceNormal.Magnitude < 1e-5 then
		return incidentVelocity, incidentVelocity.Magnitude
	end
	local n = surfaceNormal.Unit
	local dotProduct = incidentVelocity:Dot(n)
	local reflected = if dotProduct < 0
		then (incidentVelocity - (2.0 * dotProduct * n)) * restitution
		else incidentVelocity * restitution

	local preCapSpeed = reflected.Magnitude
	if preCapSpeed > MAX_REBOUND_SPEED then
		reflected = reflected.Unit * MAX_REBOUND_SPEED
	end
	return reflected, preCapSpeed
end

-- 3D Oriented Bounding Box (OBB) ramp surface check (fixes legacy RAMP_TRIGGER_MIN_ABS_X = 66 over-trigger)
function CagePhysicsService.IsPositionOnElevatingRamp(position: Vector3, variantId: Types.CageVariantInput?): boolean
	if position.Y < 0.0 then
		return false
	end
	local profile = CagePhysicsService.GetArenaGeometryProfile(variantId)
	for _, sDef in ipairs(profile.surfaces) do
		if sDef.kind == "ElevatingRamp" then
			local localPos = sDef.cframe:PointToObjectSpace(position)
			local halfSize = sDef.size * 0.5
			-- Must be strictly within the ramp's X width and Z length, and on/just above the top surface (+Y local face)
			if
				math.abs(localPos.X) <= halfSize.X
				and math.abs(localPos.Z) <= halfSize.Z
				and localPos.Y >= -0.25
				and localPos.Y <= (halfSize.Y + BALL_RADIUS + 1.5)
			then
				return true
			end
		end
	end
	return false
end

function CagePhysicsService.ApplyRampImpulse(velocity: Vector3, isOnRamp: boolean, enableRamps: boolean?): Vector3
	local rampsActive = if enableRamps ~= nil then enableRamps else activeFeatureFlags.enableRamps
	if not isOnRamp or not rampsActive then
		return velocity
	end
	local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalSpeed = horizontalVel.Magnitude
	local rampRad = math.rad(ELEVATING_RAMP_ANGLE_DEG)
	local upwardImpulse = (math.sin(rampRad) * horizontalSpeed) + 38.0
	if velocity.Y >= (upwardImpulse - 2.5) then
		return velocity
	end
	local boostedVel = Vector3.new(velocity.X, math.max(velocity.Y, upwardImpulse), velocity.Z)
	if boostedVel.Magnitude > MAX_REBOUND_SPEED then
		boostedVel = boostedVel.Unit * MAX_REBOUND_SPEED
	end
	return boostedVel
end

function CagePhysicsService.IsBehindGoal360Zone(position: Vector3): boolean
	if GOAL_BACK_ZONE_STUDS <= 0 then
		return false
	end
	local northGoalZ = -(ARENA_HALF_LENGTH_Z - GOAL_BACK_ZONE_STUDS)
	local southGoalZ = ARENA_HALF_LENGTH_Z - GOAL_BACK_ZONE_STUDS
	local behindNorth = (position.Z < northGoalZ and position.Z >= -ARENA_HALF_LENGTH_Z)
	local behindSouth = (position.Z > southGoalZ and position.Z <= ARENA_HALF_LENGTH_Z)
	return behindNorth or behindSouth
end

function CagePhysicsService.CheckGoalScored(position: Vector3, _gameMode: string?): ("North" | "South")?
	local northGoalZ = -ARENA_HALF_LENGTH_Z -- -120.0
	local southGoalZ = ARENA_HALF_LENGTH_Z -- +120.0

	if math.abs(position.X) <= (GOAL_WIDTH_X * 0.5) and position.Y >= 0 and position.Y <= GOAL_HEIGHT_Y then
		-- North Goal mouth: boundary edge Z = -120.0, pocket extends into [-126.0, -120.0]
		if position.Z <= (northGoalZ + 0.05) and position.Z >= -(ARENA_HALF_LENGTH_Z + GOAL_DEPTH_Z + 0.05) then
			return "North"
		-- South Goal mouth: boundary edge Z = +120.0, pocket extends into [120.0, 126.0]
		elseif position.Z >= (southGoalZ - 0.05) and position.Z <= (ARENA_HALF_LENGTH_Z + GOAL_DEPTH_Z + 0.05) then
			return "South"
		end
	end
	return nil
end

-- Checks if a point is inside the valid interior volume of the given variant
function CagePhysicsService.IsPointInsideArenaBounds(
	position: Vector3,
	variantId: Types.CageVariantInput?,
	margin: number?
): boolean
	local profile = CagePhysicsService.GetArenaGeometryProfile(variantId)
	local r = margin or 0.0
	local eps = 0.05

	if position.Y < (r - eps) or position.Y > (profile.ceilingHeightY - r + eps) then
		return false
	end
	if math.abs(position.X) > (profile.halfWidthX - r + eps) then
		return false
	end
	if math.abs(position.Z) > (profile.halfLengthZ - r + eps) then
		-- Check if inside goal pocket volume
		local inGoalMouthX = math.abs(position.X) <= (GOAL_WIDTH_X * 0.5 - r + eps)
		local inGoalMouthY = position.Y >= (r - eps) and position.Y <= (GOAL_HEIGHT_Y - r + eps)
		if inGoalMouthX and inGoalMouthY and math.abs(position.Z) <= (profile.halfLengthZ + GOAL_DEPTH_Z - r + eps) then
			return true
		end
		return false
	end
	if profile.hasChamferedCorners then
		local maxCornerSum = (profile.halfWidthX + profile.halfLengthZ - profile.chamferCutStuds) - (r * SQRT2) + eps
		if (math.abs(position.X) + math.abs(position.Z)) > maxCornerSum then
			return false
		end
	end
	if profile.hasBeveledRoof and position.Y > profile.eaveHeightY then
		local dy = position.Y - profile.eaveHeightY
		if (math.abs(position.X) + dy) > (profile.halfWidthX - (r * SQRT2) + eps) then
			return false
		end
		if (math.abs(position.Z) + dy) > (profile.halfLengthZ - (r * SQRT2) + eps) then
			return false
		end
		if profile.hasChamferedCorners then
			local horizDiag = (math.abs(position.X) + math.abs(position.Z)) * INV_SQRT2
			local eaveDiag = (profile.halfWidthX + profile.halfLengthZ - profile.chamferCutStuds) * INV_SQRT2
			if (horizDiag + dy) > (eaveDiag - (r * SQRT2) + eps) then
				return false
			end
		end
	end
	return true
end

type CandidateHit = {
	t: number,
	surfaceId: string,
	normal: Vector3,
	restitution: number,
	penetration: number,
}

local function isSurfaceActiveForSolver(
	sDef: Types.ArenaSurfaceDef,
	profile: Types.ArenaGeometryProfile,
	flags: Types.ReboundFeatureFlags
): boolean
	if sDef.isGuideOnly then
		return false
	end
	if sDef.kind == "GoalFrame" or sDef.kind == "CeilingMarker" or sDef.kind == "SpawnLocation" then
		return false
	end
	if sDef.kind == "PinballBumper" then
		if not flags.enableBumpers then
			return false
		end
		if profile.variantId == "A" and not flags.includeCornerOverlayInA then
			return false
		end
		return true
	end
	if sDef.kind == "CornerWall" then
		-- When bumpers are enabled, the bumper covers [0, 16] on the corner wall with e=1.25;
		-- CornerWall handles hits above Y=16 or when bumpers are disabled.
		return true
	end
	if sDef.kind == "GoalTransom" or sDef.kind == "Transom" then
		return flags.enableTransom == true
	end
	if sDef.kind == "GoalPost" or sDef.kind == "GoalCrossbar" or sDef.kind == "GoalPocket" then
		return sDef.canCollide
	end
	if sDef.kind == "ElevatingRamp" then
		-- Ramps use the 3D OBB upward-impulse mechanic (IsPositionOnElevatingRamp + ApplyRampImpulse) for ball lift
		return false
	end
	return sDef.canCollide
end

-- Swept-Sphere vs 3D OBB + Finite Surface Slab Intersection
local function sweepSphereAgainstSurface(
	startPos: Vector3,
	deltaPos: Vector3,
	radius: number,
	sDef: Types.ArenaSurfaceDef
): CandidateHit?
	local localStart = sDef.cframe:PointToObjectSpace(startPos)
	local localEnd = sDef.cframe:PointToObjectSpace(startPos + deltaPos)
	local localDelta = localEnd - localStart
	local halfSize = sDef.size * 0.5

	-- Expanded AABB in surface local coordinates (Minkowski sum bound)
	local extX = halfSize.X + radius
	local extY = halfSize.Y + radius
	local extZ = halfSize.Z + radius

	local tEnter = 0.0
	local tExit = 1.0

	local axes = {
		{ s = localStart.X, d = localDelta.X, e = extX },
		{ s = localStart.Y, d = localDelta.Y, e = extY },
		{ s = localStart.Z, d = localDelta.Z, e = extZ },
	}

	for _, ax in ipairs(axes) do
		if math.abs(ax.d) < 1e-8 then
			if math.abs(ax.s) > ax.e then
				return nil
			end
		else
			local t1 = (-ax.e - ax.s) / ax.d
			local t2 = (ax.e - ax.s) / ax.d
			if t1 > t2 then
				t1, t2 = t2, t1
			end
			if t1 > tEnter then
				tEnter = t1
			end
			if t2 < tExit then
				tExit = t2
			end
			if tEnter > tExit then
				return nil
			end
		end
	end

	local ta = math.max(0.0, tEnter)
	local tb = math.min(1.0, tExit)
	if ta > tb then
		return nil
	end

	local function getDistAt(t: number): (number, Vector3, Vector3)
		local pt = localStart + (localDelta * t)
		local cl = Vector3.new(
			math.clamp(pt.X, -halfSize.X, halfSize.X),
			math.clamp(pt.Y, -halfSize.Y, halfSize.Y),
			math.clamp(pt.Z, -halfSize.Z, halfSize.Z)
		)
		local df = pt - cl
		return df.Magnitude, df, cl
	end

	local distA, diffA, clampedA = getDistAt(ta)
	local tCandidate = ta
	local localAtT = localStart + (localDelta * tCandidate)
	local clamped = clampedA
	local diff = diffA
	local dist = distA

	if distA > radius then
		-- ta enters the expanded box at a rounded corner/edge.
		-- Find the minimum distance along [ta, tb] using golden-section search.
		local lo = ta
		local hi = tb
		local invphi = 0.3819660112501051
		local phi = 0.6180339887498949
		local t1 = lo + invphi * (hi - lo)
		local t2 = lo + phi * (hi - lo)
		local d1 = getDistAt(t1)
		local d2 = getDistAt(t2)

		for _ = 1, 16 do
			if d1 < d2 then
				hi = t2
				t2 = t1
				d2 = d1
				t1 = lo + invphi * (hi - lo)
				d1 = getDistAt(t1)
			else
				lo = t1
				t1 = t2
				d1 = d2
				t2 = lo + phi * (hi - lo)
				d2 = getDistAt(t2)
			end
		end

		local tMin = (lo + hi) * 0.5
		local distMin = getDistAt(tMin)
		if distMin > (radius + 1e-4) then
			-- Ray passes through expanded box corner without contacting the rounded box
			return nil
		end

		-- Since dist(ta) > radius and dist(tMin) <= radius,
		-- distance is monotonic on [ta, tMin]. Use bisection to find exact TOI.
		local bLo = ta
		local bHi = tMin
		for _ = 1, 16 do
			local mid = (bLo + bHi) * 0.5
			local dMid = getDistAt(mid)
			if dMid <= radius then
				bHi = mid
			else
				bLo = mid
			end
		end

		tCandidate = bHi
		dist, diff, clamped = getDistAt(tCandidate)
		localAtT = localStart + (localDelta * tCandidate)
	end

	-- Determine contact normal in world space
	local worldNormal = sDef.normal
	if sDef.kind == "GoalTransom" or sDef.kind == "Transom" or sDef.kind == "GoalPost" or sDef.kind == "GoalCrossbar" or sDef.kind == "GoalPocket" then
		-- Double-sided panel or post
		local worldDelta = deltaPos
		if worldDelta:Dot(worldNormal) > 0 then
			worldNormal = -worldNormal
		end
	end
	if (sDef.kind == "GoalPost" or sDef.kind == "GoalCrossbar") and diff.Magnitude > 1e-4 then
		local candidateNormal = sDef.cframe:VectorToWorldSpace(diff).Unit
		if deltaPos:Dot(candidateNormal) < -1e-6 then
			worldNormal = candidateNormal
		end
	end

	-- Must be moving into the surface
	if deltaPos:Dot(worldNormal) >= -1e-6 then
		return nil
	end

	local penetration = math.max(0.0, radius - dist)
	return {
		t = tCandidate,
		surfaceId = sDef.surfaceId,
		normal = worldNormal,
		restitution = sDef.restitution,
		penetration = penetration,
	}
end

-- Convex Polytope Outer Boundary Safety Projection (Guarantees 0 Escape / Tunneling at any speed)
local function enforceOuterPolytopeContainment(
	pos: Vector3,
	vel: Vector3,
	radius: number,
	profile: Types.ArenaGeometryProfile,
	flags: Types.ReboundFeatureFlags
): (Vector3, Vector3, string?, number, number)
	local p = pos
	local v = vel
	local hitTag: string? = nil
	local speedBefore = v.Magnitude
	local speedPreCap = speedBefore

	-- 1. Floor Y >= radius
	if p.Y < radius then
		p = Vector3.new(p.X, radius, p.Z)
		if v.Y < 0 then
			v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, Vector3.new(0, 1, 0), FLOOR_RESTITUTION)
			hitTag = "CageFloor"
		end
	end

	-- 2. Variant C 45-degree Roof Bevels (checked BEFORE flat ceiling so bevel hits are never masked by Y=32)
	if profile.hasBeveledRoof and p.Y > (profile.eaveHeightY - radius) then
		local dy = p.Y - profile.eaveHeightY
		local bevelLimitX = profile.halfWidthX - (radius * SQRT2)
		if (math.abs(p.X) + dy) > bevelLimitX then
			local signX = if p.X >= 0 then 1 else -1
			local n = Vector3.new(-signX * INV_SQRT2, -INV_SQRT2, 0)
			local excess = ((math.abs(p.X) + dy) - bevelLimitX) * INV_SQRT2
			p = p + (n * (excess + 1e-3))
			if v:Dot(n) < 0 then
				v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, STANDARD_WALL_RESTITUTION)
				hitTag = if signX > 0 then "RoofBevel_East" else "RoofBevel_West"
			end
		end

		local dyZ = p.Y - profile.eaveHeightY
		local bevelLimitZ = profile.halfLengthZ - (radius * SQRT2)
		if (math.abs(p.Z) + dyZ) > bevelLimitZ then
			local signZ = if p.Z >= 0 then 1 else -1
			local n = Vector3.new(0, -INV_SQRT2, -signZ * INV_SQRT2)
			local excess = ((math.abs(p.Z) + dyZ) - bevelLimitZ) * INV_SQRT2
			p = p + (n * (excess + 1e-3))
			if v:Dot(n) < 0 then
				v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, STANDARD_WALL_RESTITUTION)
				hitTag = if signZ > 0 then "RoofBevel_South" else "RoofBevel_North"
			end
		end

		if profile.hasChamferedCorners then
			local dyC = p.Y - profile.eaveHeightY
			local horizDiag = (math.abs(p.X) + math.abs(p.Z)) * INV_SQRT2
			local eaveDiag = (profile.halfWidthX + profile.halfLengthZ - profile.chamferCutStuds) * INV_SQRT2
			local cornerBevelLimit = eaveDiag - (radius * SQRT2)
			if (horizDiag + dyC) > cornerBevelLimit then
				local signX = if p.X >= 0 then 1 else -1
				local signZ = if p.Z >= 0 then 1 else -1
				local n = Vector3.new(-signX * 0.5, -INV_SQRT2, -signZ * 0.5).Unit
				local excess = ((horizDiag + dyC) - cornerBevelLimit) * INV_SQRT2
				p = p + (n * (excess + 1e-3))
				local suffix = (if signZ < 0 then "N" else "S") .. (if signX < 0 then "W" else "E")
				if v:Dot(n) < 0 then
					v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, STANDARD_WALL_RESTITUTION)
					hitTag = "RoofBevel_" .. suffix
				end
			end
		end
	end

	-- 3. Flat Ceiling Y <= ceilingHeightY - radius
	if p.Y > (profile.ceilingHeightY - radius) then
		p = Vector3.new(p.X, profile.ceilingHeightY - radius, p.Z)
		if v.Y > 0 then
			v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, Vector3.new(0, -1, 0), STANDARD_WALL_RESTITUTION)
			hitTag = "CageCeiling"
		end
	end

	-- 4. 45-Degree Chamfered Corners (Variants B & C, or Variant A with corner overlay enabled)
	local useChamfer = profile.hasChamferedCorners or (profile.variantId == "A" and flags.includeCornerOverlayInA == true and flags.enableBumpers == true)
	if useChamfer then
		local cut = if profile.chamferCutStuds > 0 then profile.chamferCutStuds else CHAMFER_CUT_STUDS
		local cornerSumLimit = (profile.halfWidthX + profile.halfLengthZ - cut) - (radius * SQRT2)
		local currentSum = math.abs(p.X) + math.abs(p.Z)
		if currentSum > cornerSumLimit then
			local signX = if p.X >= 0 then 1 else -1
			local signZ = if p.Z >= 0 then 1 else -1
			local n = Vector3.new(-signX * INV_SQRT2, 0, -signZ * INV_SQRT2)
			local excess = (currentSum - cornerSumLimit) * INV_SQRT2
			p = p + (n * (excess + 1e-3))
			local suffix = (if signZ < 0 then "N" else "S") .. (if signX < 0 then "W" else "E")
			local isBumperHit = flags.enableBumpers == true and p.Y <= 16.0
			local rest = if isBumperHit then BUMPER_RESTITUTION else STANDARD_WALL_RESTITUTION
			if v:Dot(n) < 0 then
				v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, rest)
				hitTag = if isBumperHit then ("PinballBumper_" .. suffix) else ("CornerWall_" .. suffix)
			end
		end
	end

	-- 5. West / East Walls (|X| <= halfWidthX - radius)
	if math.abs(p.X) > (profile.halfWidthX - radius) then
		local signX = if p.X >= 0 then 1 else -1
		p = Vector3.new(signX * (profile.halfWidthX - radius), p.Y, p.Z)
		local n = Vector3.new(-signX, 0, 0)
		if v:Dot(n) < 0 then
			v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, STANDARD_WALL_RESTITUTION)
			hitTag = if signX > 0 then "Wall_East" else "Wall_West"
		end
	end

	-- 6. North / South Walls (|Z| <= halfLengthZ - radius) or Goal Pocket
	if math.abs(p.Z) > (profile.halfLengthZ - radius) then
		local signZ = if p.Z >= 0 then 1 else -1
		local inGoalMouthX = math.abs(p.X) < (GOAL_WIDTH_X * 0.5 - radius)
		local inGoalMouthY = p.Y >= 0 and p.Y <= (GOAL_HEIGHT_Y - radius)
		if inGoalMouthX and inGoalMouthY then
			local maxPocketZ = profile.halfLengthZ + GOAL_DEPTH_Z - radius
			if math.abs(p.Z) > maxPocketZ then
				p = Vector3.new(p.X, p.Y, signZ * maxPocketZ)
				local n = Vector3.new(0, 0, -signZ)
				if v:Dot(n) < 0 then
					v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, 0.40)
					hitTag = if signZ > 0 then "GoalBackNet_South" else "GoalBackNet_North"
				end
			end
		else
			p = Vector3.new(p.X, p.Y, signZ * (profile.halfLengthZ - radius))
			local n = Vector3.new(0, 0, -signZ)
			if v:Dot(n) < 0 then
				v, speedPreCap = CagePhysicsService.ComputeReboundVelocity(v, n, STANDARD_WALL_RESTITUTION)
				local tagSuffix = if p.X < 0 then "_Left" else "_Right"
				hitTag = (if signZ > 0 then "Wall_South" else "Wall_North") .. tagSuffix
			end
		end
	end

	return p, v, hitTag, speedBefore, speedPreCap
end

-- Swept-Sphere Collision Solver (T-02) with Multi-Contact Substep Budget (MAX_COLLISION_SUBSTEPS = 4)
function CagePhysicsService.StepBallCageCollision(
	position: Vector3,
	velocity: Vector3,
	dt: number,
	options: (StepCollisionOptions | Types.CageVariantInput)?,
	maybeFlags: Types.ReboundFeatureFlags?
): (Vector3, Vector3, string?, Types.ReboundStepResult)
	local opts: StepCollisionOptions = if typeof(options) == "table"
		then options :: StepCollisionOptions
		else {
			variantId = if typeof(options) == "string" then options else nil,
			featureFlags = maybeFlags,
		}
	local variantId = normalizeVariantId(opts.variantId)
	local profile = CagePhysicsService.GetArenaGeometryProfile(variantId)
	local radius = opts.ballRadius or profile.ballRadius
	local maxSubsteps = opts.maxSubsteps or MAX_COLLISION_SUBSTEPS
	local flags: Types.ReboundFeatureFlags = opts.featureFlags or maybeFlags or activeFeatureFlags

	local curPos = position
	local curVel = velocity
	local remainingDt = math.max(0.0, dt)
	local hitSurfaces: { string } = {}
	local hitSet: { [string]: boolean } = {}
	local firstHitTag: string? = nil
	local speedBeforeFirstHit = curVel.Magnitude
	local speedPreCapFirstHit = speedBeforeFirstHit
	local speedAfterFirstHit = speedBeforeFirstHit
	local substepsUsed = 0
	local budgetExhausted = false
	local appliedRampLift = false

	-- Check elevating ramp support at start of step
	if flags.enableRamps and CagePhysicsService.IsPositionOnElevatingRamp(curPos, variantId) then
		local speedBefore = curVel.Magnitude
		local lifted = CagePhysicsService.ApplyRampImpulse(curVel, true, true)
		if (lifted - curVel).Magnitude > 1e-3 then
			curVel = lifted
			appliedRampLift = true
			if not hitSet["ElevatingRamp"] then
				hitSet["ElevatingRamp"] = true
				table.insert(hitSurfaces, "ElevatingRamp")
				if firstHitTag == nil then
					firstHitTag = "ElevatingRamp"
					speedBeforeFirstHit = speedBefore
					speedPreCapFirstHit = curVel.Magnitude
					speedAfterFirstHit = curVel.Magnitude
				end
			end
		end
	end

	for stepIdx = 1, maxSubsteps do
		if remainingDt <= 1e-6 or curVel.Magnitude <= 1e-6 then
			break
		end
		substepsUsed = stepIdx
		local stepDelta = curVel * remainingDt
		-- Find earliest swept-sphere hit across all active surfaces in the single ArenaGeometry catalog
		local earliestT = 1.0 + 1e-5
		local simultaneousHits: { CandidateHit } = {}

		for _, sDef in ipairs(profile.surfaces) do
			if isSurfaceActiveForSolver(sDef, profile, flags) then
				-- If a PinballBumper is active on this corner and ball is within bumper height [0, 16], prefer PinballBumper over CornerWall
				if sDef.kind == "CornerWall" and flags.enableBumpers and curPos.Y <= 16.0 then
					continue
				end
				-- In Variant C, if ball is entering the bevel zone (|X| > 72 or |Z| > 112), ignore flat CageCeiling
				if sDef.kind == "Ceiling" and profile.hasBeveledRoof then
					local projected = curPos + stepDelta
					if math.abs(projected.X) > (profile.halfWidthX - profile.roofBevelStuds) or math.abs(projected.Z) > (profile.halfLengthZ - profile.roofBevelStuds) then
						continue
					end
				end

				local hit = sweepSphereAgainstSurface(curPos, stepDelta, radius, sDef)
				if hit and not hitSet[hit.surfaceId] then
					if hit.t < (earliestT - 1e-3) then
						earliestT = hit.t
						simultaneousHits = { hit }
					elseif math.abs(hit.t - earliestT) <= 1e-3 then
						table.insert(simultaneousHits, hit)
					end
				end
			end
		end

		if #simultaneousHits == 0 then
			curPos = curPos + stepDelta
			remainingDt = 0.0
			break
		end

		-- Advance to impact time
		local travelT = math.clamp(earliestT, 0.0, 1.0)
		curPos = curPos + (stepDelta * travelT)
		remainingDt = remainingDt * (1.0 - travelT)

		-- Resolve single or simultaneous multi-surface corner/seam contact
		local combinedNormal = Vector3.zero
		for _, h in ipairs(simultaneousHits) do
			combinedNormal = combinedNormal + h.normal
			if not hitSet[h.surfaceId] then
				hitSet[h.surfaceId] = true
				table.insert(hitSurfaces, h.surfaceId)
			end
		end

		local chosenRestitution: number
		local primaryHitId: string

		if #simultaneousHits == 1 then
			-- Single contact: Use the exact restitution of the hit surface (F-08)
			local h = simultaneousHits[1]
			primaryHitId = h.surfaceId
			chosenRestitution = h.restitution
		else
			-- Simultaneous multi-surface contact resolution policy:
			-- 1. Bumper priority: Any active PinballBumper contact triggers BUMPER_RESTITUTION (1.20)
			-- 2. Dominant impulse: Surface with highest normal approach speed (-curVel:Dot(h.normal)) determines restitution
			-- 3. Tie-breaker: Highest surface restitution
			local bumperHit: CandidateHit? = nil
			for _, h in ipairs(simultaneousHits) do
				if string.find(h.surfaceId, "PinballBumper", 1, true) then
					bumperHit = h
					break
				end
			end

			if bumperHit then
				primaryHitId = bumperHit.surfaceId
				chosenRestitution = BUMPER_RESTITUTION
			else
				local bestHit = simultaneousHits[1]
				local bestApproachSpeed = -curVel:Dot(bestHit.normal)
				for i = 2, #simultaneousHits do
					local h = simultaneousHits[i]
					local approachSpeed = -curVel:Dot(h.normal)
					if approachSpeed > (bestApproachSpeed + 1e-4) then
						bestHit = h
						bestApproachSpeed = approachSpeed
					elseif math.abs(approachSpeed - bestApproachSpeed) <= 1e-4 and h.restitution > bestHit.restitution then
						bestHit = h
						bestApproachSpeed = approachSpeed
					end
				end
				primaryHitId = bestHit.surfaceId
				chosenRestitution = bestHit.restitution
			end
		end

		if combinedNormal.Magnitude < 1e-5 then
			combinedNormal = simultaneousHits[1].normal
		else
			combinedNormal = combinedNormal.Unit
		end

		local speedBefore = curVel.Magnitude
		local reflectedVel, preCapSpeed = CagePhysicsService.ComputeReboundVelocity(curVel, combinedNormal, chosenRestitution)
		curVel = reflectedVel
		-- Push slightly away from contact normal to prevent re-triggering same surface
		curPos = curPos + (combinedNormal * 0.02)

		if firstHitTag == nil then
			firstHitTag = primaryHitId
			speedBeforeFirstHit = speedBefore
			speedPreCapFirstHit = preCapSpeed
			speedAfterFirstHit = curVel.Magnitude
		end

		if stepIdx == maxSubsteps and remainingDt > 1e-4 then
			budgetExhausted = true
			curPos = curPos + (curVel * remainingDt)
			remainingDt = 0.0
		end
	end

	-- Final convex polytope containment guard (guarantees 0 escape even if substep budget was exhausted)
	local safePos, safeVel, polyHitTag, polySpeedBefore, polySpeedPreCap =
		enforceOuterPolytopeContainment(curPos, curVel, radius, profile, flags)
	curPos = safePos
	curVel = safeVel
	if polyHitTag and not hitSet[polyHitTag] then
		hitSet[polyHitTag] = true
		table.insert(hitSurfaces, polyHitTag)
		if firstHitTag == nil then
			firstHitTag = polyHitTag
			speedBeforeFirstHit = polySpeedBefore
			speedPreCapFirstHit = polySpeedPreCap
			speedAfterFirstHit = curVel.Magnitude
		end
	end

	-- Check ramp lift at end of step if ball rolled onto ramp
	if not appliedRampLift and flags.enableRamps and CagePhysicsService.IsPositionOnElevatingRamp(curPos, variantId) then
		local lifted = CagePhysicsService.ApplyRampImpulse(curVel, true, true)
		if (lifted - curVel).Magnitude > 1e-3 then
			curVel = lifted
			appliedRampLift = true
			if not hitSet["ElevatingRamp"] then
				hitSet["ElevatingRamp"] = true
				table.insert(hitSurfaces, "ElevatingRamp")
				firstHitTag = firstHitTag or "ElevatingRamp"
			end
		end
	end

	local stepResult: Types.ReboundStepResult = {
		position = curPos,
		velocity = curVel,
		hitSurfaceTag = firstHitTag,
		hitCount = #hitSurfaces,
		hitSurfaces = hitSurfaces,
		substepsUsed = substepsUsed,
		budgetExhausted = budgetExhausted,
		speedBeforeHit = speedBeforeFirstHit,
		speedPreCap = speedPreCapFirstHit,
		speedAfterHit = if firstHitTag ~= nil then speedAfterFirstHit else curVel.Magnitude,
		appliedRampLift = appliedRampLift,
	}

	return curPos, curVel, firstHitTag, stepResult
end

-- Test Launch Probe (T-04): Deterministic trajectory simulator for controlled A/B/C comparison without BallService
function CagePhysicsService.SimulateBallTrajectory(config: TrajectoryLaunchConfig): TrajectoryProbeResult
	local variantId = normalizeVariantId(config.variantId)
	local dt = config.dt or (1.0 / 60.0)
	local maxDuration = config.maxDurationSec or 3.0
	local gravityY = if config.gravityY ~= nil then config.gravityY else -65.0
	local radius = config.ballRadius or BALL_RADIUS
	local flags: Types.ReboundFeatureFlags = config.featureFlags or DEFAULT_FEATURE_FLAGS

	local pos = config.initialPosition
	local vel = config.initialVelocity
	local initialSpeed = vel.Magnitude

	local firstHitTag: string? = nil
	local firstHitPos: Vector3? = nil
	local firstHitTime: number? = nil
	local speedBeforeFirst = initialSpeed
	local speedPreCapFirst = initialSpeed
	local speedAfterFirst = initialSpeed
	local firstReboundVel: Vector3? = nil

	local landingPos: Vector3? = nil
	local landingTime: number? = nil
	local landedOnFloorAfterRebound = false

	local totalSteps = math.floor(maxDuration / dt + 0.5)
	local allHits: { string } = {}
	local repeatedContacts = 0
	local lastHitSurface: string? = nil
	local consecutiveCornerFrames = 0
	local cornerStuck = false
	local escapedBounds = false
	local budgetExhaustedCount = 0
	local hasNonFloorRebound = false

	for step = 1, totalSteps do
		local tSec = step * dt
		-- Apply gravity before collision step
		if gravityY ~= 0 then
			vel = vel + Vector3.new(0, gravityY * dt, 0)
		end

		local nextPos, nextVel, hitTag, stepRes = CagePhysicsService.StepBallCageCollision(pos, vel, dt, {
			variantId = variantId,
			ballRadius = radius,
			featureFlags = flags,
		})

		if stepRes.budgetExhausted then
			budgetExhaustedCount += 1
		end

		if not CagePhysicsService.IsPointInsideArenaBounds(nextPos, variantId, radius - 0.1) then
			escapedBounds = true
		end

		if hitTag ~= nil then
			table.insert(allHits, hitTag)
			if hitTag == lastHitSurface and hitTag ~= "CageFloor" then
				repeatedContacts += 1
			end
			lastHitSurface = hitTag

			if firstHitTag == nil and hitTag ~= "CageFloor" then
				firstHitTag = hitTag
				firstHitPos = nextPos
				firstHitTime = tSec
				speedBeforeFirst = stepRes.speedBeforeHit
				speedPreCapFirst = stepRes.speedPreCap
				speedAfterFirst = stepRes.speedAfterHit
				firstReboundVel = nextVel
				hasNonFloorRebound = true
			elseif firstHitTag == nil and hitTag == "CageFloor" and config.initialVelocity.Y < 0 then
				firstHitTag = hitTag
				firstHitPos = nextPos
				firstHitTime = tSec
				speedBeforeFirst = stepRes.speedBeforeHit
				speedPreCapFirst = stepRes.speedPreCap
				speedAfterFirst = stepRes.speedAfterHit
				firstReboundVel = nextVel
			end

			if hasNonFloorRebound and hitTag == "CageFloor" and landingPos == nil then
				landingPos = nextPos
				landingTime = tSec
				landedOnFloorAfterRebound = true
			end
		end

		if math.abs(nextPos.X) > 58.0 and math.abs(nextPos.Z) > 98.0 and nextVel.Magnitude < 2.0 then
			consecutiveCornerFrames += 1
			if consecutiveCornerFrames > 15 then
				cornerStuck = true
			end
		else
			consecutiveCornerFrames = 0
		end

		pos = nextPos
		vel = nextVel
	end

	return {
		scenarioId = config.scenarioId or "UnnamedProbe",
		variantId = variantId,
		featureFlags = flags,
		initialPosition = config.initialPosition,
		initialVelocity = config.initialVelocity,
		initialSpeed = initialSpeed,
		firstHitSurfaceTag = firstHitTag,
		firstHitPosition = firstHitPos,
		firstHitTimeSec = firstHitTime,
		speedBeforeFirstHit = speedBeforeFirst,
		speedPreCapFirstHit = speedPreCapFirst,
		speedAfterFirstHit = speedAfterFirst,
		firstReboundVelocity = firstReboundVel,
		landingPosition = landingPos or pos,
		landingTimeSec = landingTime or maxDuration,
		landedOnFloorAfterRebound = landedOnFloorAfterRebound,
		totalSteps = totalSteps,
		totalHitCount = #allHits,
		hitSurfaces = allHits,
		repeatedContactCount = repeatedContacts,
		cornerStuck = cornerStuck,
		escapedBounds = escapedBounds,
		budgetExhaustedCount = budgetExhaustedCount,
		finalPosition = pos,
		finalVelocity = vel,
	}
end

-- Controlled A/B/C Comparison Suite (T-04 / V-05): Runs Shape Pass & Mechanics Pass across Variants A, B, C
function CagePhysicsService.RunVariantComparisonSuite(): {
	shapePass: { TrajectoryProbeResult },
	mechanicsPass: { TrajectoryProbeResult },
	rampObbAudit: { [string]: boolean },
	summary: {
		totalRuns: number,
		zeroEscapeAllRuns: boolean,
		zeroCornerStuckAllRuns: boolean,
		zeroMarkerAimAssistDelta: boolean,
	},
}
	local variants: { Types.CageVariantId } = { "A", "B", "C" }
	local shapeFlags: Types.ReboundFeatureFlags = {
		enableBumpers = false,
		enableTransom = false,
		enableRamps = false,
		includeCornerOverlayInA = false,
	}
	local mechanicsFlags: Types.ReboundFeatureFlags = {
		enableBumpers = true,
		enableTransom = true,
		enableRamps = true,
		includeCornerOverlayInA = false,
	}

	local shapeScenarios = {
		{
			id = "S01_CornerCut_NW",
			pos = Vector3.new(-35, 3.0, -75),
			vel = Vector3.new(-70, 0, -70), -- 98.99 studs/s into NW corner (-70, -110)
			gravityY = 0,
			duration = 1.6,
		},
		{
			id = "S02_CornerCut_NE_Mirror",
			pos = Vector3.new(35, 3.0, -75),
			vel = Vector3.new(70, 0, -70), -- Mirrored into NE corner (+70, -110)
			gravityY = 0,
			duration = 1.6,
		},
		{
			id = "S03_HighSideLob_WestBevel",
			pos = Vector3.new(-40, 18.0, 0),
			vel = Vector3.new(-85, 32, 0), -- Hits West upper eave (Y ~ 28, X ~ -76 in C vs X = -80 in A/B)
			gravityY = -65.0,
			duration = 2.2,
		},
		{
			id = "S04_HighEndLob_NorthBevel",
			pos = Vector3.new(0, 18.0, -75),
			vel = Vector3.new(0, 34, -90), -- Hits North upper eave (Y ~ 28, Z ~ -116 in C vs Z = -120 in A/B)
			gravityY = -65.0,
			duration = 2.2,
		},
		{
			id = "S05_HighCornerLob_NWBevel",
			pos = Vector3.new(-42, 18.0, -82),
			vel = Vector3.new(-62, 32, -62), -- Hits NW upper corner bevel in C vs flat roof/corner in A/B
			gravityY = -65.0,
			duration = 2.2,
		},
		{
			id = "S06_CeilingLob_NorthMarker",
			pos = Vector3.new(0, 6.0, -28),
			vel = Vector3.new(0, 68, -68), -- Hits ceiling near North marker (0, 32, -68)
			gravityY = -65.0,
			duration = 2.4,
		},
		{
			id = "S07_HighSpeed180_GrazingSeam",
			pos = Vector3.new(-55, 22.0, -90),
			vel = Vector3.new(-100, 44, -143), -- ~180 studs/s at dt=1/30s into upper corner/bevel seam
			gravityY = -65.0,
			dt = 1.0 / 30.0,
			duration = 2.0,
		},
	}

	local shapeResults: { TrajectoryProbeResult } = {}
	for _, sc in ipairs(shapeScenarios) do
		for _, vid in ipairs(variants) do
			local res = CagePhysicsService.SimulateBallTrajectory({
				scenarioId = sc.id,
				variantId = vid,
				initialPosition = sc.pos,
				initialVelocity = sc.vel,
				dt = sc.dt or (1.0 / 60.0),
				maxDurationSec = sc.duration,
				gravityY = sc.gravityY,
				featureFlags = shapeFlags,
			})
			table.insert(shapeResults, res)
		end
	end

	local mechanicsScenarios = {
		{
			id = "M01_CeilingMarker_North_Angle1",
			pos = Vector3.new(0, 6.0, -28),
			vel = Vector3.new(0, 68, -68),
			gravityY = -65.0,
			duration = 2.2,
		},
		{
			id = "M01_CeilingMarker_South_Mirror",
			pos = Vector3.new(0, 6.0, 28),
			vel = Vector3.new(0, 68, 68),
			gravityY = -65.0,
			duration = 2.2,
		},
		{
			id = "M02_OverGoalTransom_North",
			pos = Vector3.new(0, 14.0, -76),
			vel = Vector3.new(0, 10, -95), -- Hits Transom_North at Z = -120.0, Y ~ 12.0
			gravityY = -65.0,
			duration = 2.0,
		},
		{
			id = "M02_OverGoalTransom_South_Mirror",
			pos = Vector3.new(0, 14.0, 76),
			vel = Vector3.new(0, 10, 95), -- Hits Transom_South at Z = +120.0, Y ~ 12.0
			gravityY = -65.0,
			duration = 2.0,
		},
		{
			id = "M03_PinballBumper_NW_100",
			pos = Vector3.new(-42, 4.0, -82),
			vel = Vector3.new(-70.710678, 0, -70.710678), -- 100 studs/s perpendicular into NW bumper -> 125 studs/s
			gravityY = 0,
			duration = 1.5,
		},
		{
			id = "M03_PinballBumper_SE_Mirror_100",
			pos = Vector3.new(42, 4.0, 82),
			vel = Vector3.new(70.710678, 0, 70.710678), -- 100 studs/s perpendicular into SE bumper -> 125 studs/s
			gravityY = 0,
			duration = 1.5,
		},
		{
			id = "M03_PinballBumper_SpeedCap_160To180",
			pos = Vector3.new(-42, 4.0, -82),
			vel = Vector3.new(-113.137085, 0, -113.137085), -- 160 studs/s * 1.25 = 200 -> capped at 180 studs/s
			gravityY = 0,
			duration = 1.2,
		},
		{
			id = "M04_SideElevatingRamp_West",
			pos = Vector3.new(-74.0, 2.2, 0),
			vel = Vector3.new(35.0, 0, 20.0), -- Starts on West ramp OBB -> receives 25-deg upward impulse
			gravityY = -65.0,
			duration = 2.0,
		},
		{
			id = "M04_SideElevatingRamp_East_Mirror",
			pos = Vector3.new(74.0, 2.2, 0),
			vel = Vector3.new(-35.0, 0, 20.0), -- Starts on East ramp OBB -> receives 25-deg upward impulse
			gravityY = -65.0,
			duration = 1.8,
		},
		{
			id = "M05_BackGoalAlley14_North",
			pos = Vector3.new(-18.0, 2.0, -113.0), -- Inside 14-stud North back-goal alley (Z in [-120, -106])
			vel = Vector3.new(30.0, 0, -65.0), -- Rebounds off Wall_North (Z = -120)
			gravityY = 0,
			duration = 1.5,
		},
		{
			id = "M05_BackGoalAlley14_South_Mirror",
			pos = Vector3.new(18.0, 2.0, 113.0), -- Inside 14-stud South back-goal alley (Z in [106, 120])
			vel = Vector3.new(-30.0, 0, 65.0), -- Rebounds off Wall_South (Z = +120)
			gravityY = 0,
			duration = 1.5,
		},
	}

	local mechanicsResults: { TrajectoryProbeResult } = {}
	for _, sc in ipairs(mechanicsScenarios) do
		for _, vid in ipairs(variants) do
			local res = CagePhysicsService.SimulateBallTrajectory({
				scenarioId = sc.id,
				variantId = vid,
				initialPosition = sc.pos,
				initialVelocity = sc.vel,
				dt = 1.0 / 60.0,
				maxDurationSec = sc.duration,
				gravityY = sc.gravityY,
				featureFlags = mechanicsFlags,
			})
			table.insert(mechanicsResults, res)
		end
	end

	-- Also run Variant A with includeCornerOverlayInA = true on M03_PinballBumper_NW_100 to isolate overlay effect
	local overlayResA = CagePhysicsService.SimulateBallTrajectory({
		scenarioId = "M03_PinballBumper_NW_100_VariantA_Overlay",
		variantId = "A",
		initialPosition = Vector3.new(-42, 4.0, -82),
		initialVelocity = Vector3.new(-70.710678, 0, -70.710678),
		dt = 1.0 / 60.0,
		maxDurationSec = 1.5,
		gravityY = 0,
		featureFlags = {
			enableBumpers = true,
			enableTransom = true,
			enableRamps = true,
			includeCornerOverlayInA = true,
		},
	})
	table.insert(mechanicsResults, overlayResA)

	-- Ramp 3D OBB precision audit (in-bounds vs inward X=-66.5 vs beyond-end Z=35 vs under-ramp Y=0.2)
	local rampObbAudit = {
		onWestRampCenter = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.2, 0), "B"),
		onEastRampCenter = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(74.0, 2.2, 0), "B"),
		inwardOfRampAtX66_5 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-66.5, 1.25, 0), "B"),
		beyondRampEndAtZ35 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 2.2, 35.0), "B"),
		underneathRampAtY0_2 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-77.5, 0.2, 0), "B"),
		highAboveRampAtY12 = CagePhysicsService.IsPositionOnElevatingRamp(Vector3.new(-74.0, 12.0, 0), "B"),
	}

	local zeroEscape = true
	local zeroStuck = true
	for _, r in ipairs(shapeResults) do
		if r.escapedBounds then
			zeroEscape = false
		end
		if r.cornerStuck then
			zeroStuck = false
		end
	end
	for _, r in ipairs(mechanicsResults) do
		if r.escapedBounds then
			zeroEscape = false
		end
		if r.cornerStuck then
			zeroStuck = false
		end
	end

	-- Verify marker zero aim-assist: compare trajectory aimed at marker (0, 32, -68) vs offset (15, 32, -55)
	-- Both must reflect with exact horizontal velocity unchanged (vx_after == vx_before * 0.88, vz_after == vz_before * 0.88)
	local markerProbe = CagePhysicsService.SimulateBallTrajectory({
		scenarioId = "ZeroAimAssistCheck",
		variantId = "B",
		initialPosition = Vector3.new(5, 20, -48),
		initialVelocity = Vector3.new(-10, 50, -40),
		dt = 1.0 / 60.0,
		maxDurationSec = 0.6,
		gravityY = 0,
		featureFlags = mechanicsFlags,
	})
	local expectedReboundVel = CagePhysicsService.ComputeReboundVelocity(
		Vector3.new(-10, 50, -40),
		Vector3.new(0, -1, 0),
		STANDARD_WALL_RESTITUTION
	)
	local zeroMarkerAssist = markerProbe.firstReboundVelocity ~= nil
		and (markerProbe.firstReboundVelocity - expectedReboundVel).Magnitude < 1e-4

	return {
		shapePass = shapeResults,
		mechanicsPass = mechanicsResults,
		rampObbAudit = rampObbAudit,
		summary = {
			totalRuns = #shapeResults + #mechanicsResults,
			zeroEscapeAllRuns = zeroEscape,
			zeroCornerStuckAllRuns = zeroStuck,
			zeroMarkerAimAssistDelta = zeroMarkerAssist,
		},
	}
end

local function createSurfaceInstance(sDef: Types.ArenaSurfaceDef, parent: Instance, isVariantAOverlay: boolean): BasePart
	local inst: BasePart
	if sDef.kind == "SpawnLocation" then
		local spawnLoc = Instance.new("SpawnLocation")
		spawnLoc.Enabled = true
		spawnLoc.Neutral = true
		spawnLoc.Duration = 0
		inst = spawnLoc
	else
		inst = Instance.new("Part")
	end

	inst.Name = sDef.surfaceId
	inst.Size = sDef.size
	inst.CFrame = sDef.cframe
	inst.Anchored = true
	inst.CanCollide = sDef.canCollide or isVariantAOverlay
	inst.CanQuery = sDef.canQuery or isVariantAOverlay
	inst.CanTouch = true
	inst.Massless = false
	inst.Color = sDef.color
	inst.Material = sDef.material
	inst.Transparency = sDef.transparency
	inst.TopSurface = Enum.SurfaceType.Smooth
	inst.BottomSurface = Enum.SurfaceType.Smooth

	inst:SetAttribute("SurfaceId", sDef.surfaceId)
	inst:SetAttribute("SurfaceKind", sDef.kind)
	inst:SetAttribute("Restitution", sDef.restitution)
	inst:SetAttribute("SurfaceNormal", sDef.normal)
	inst:SetAttribute("IsGuideOnly", sDef.isGuideOnly)

	if sDef.kind == "Wall" or sDef.kind == "CornerWall" or sDef.kind == "Ceiling" or sDef.kind == "RoofBevel" then
		inst:SetAttribute("IsCageBoundary", true)
	elseif sDef.kind == "PinballBumper" then
		inst:SetAttribute("IsPinballBumper", true)
	elseif sDef.kind == "CeilingMarker" then
		inst:SetAttribute("IsReboundMarker", true)
	elseif sDef.kind == "GoalFrame" then
		inst:SetAttribute("IsGoalFrame", true)
		inst:SetAttribute("GoalSide", sDef.goalSide or "North")
		inst:SetAttribute("BackZoneDepthStuds", GOAL_BACK_ZONE_STUDS)
	elseif sDef.kind == "GoalPost" or sDef.kind == "GoalCrossbar" then
		inst:SetAttribute("IsGoalPost", true)
		inst:SetAttribute("GoalSide", sDef.goalSide or "North")
	elseif sDef.kind == "GoalTransom" or sDef.kind == "Transom" then
		inst:SetAttribute("IsGoalTransom", true)
		inst:SetAttribute("GoalSide", sDef.goalSide or "North")
	elseif sDef.kind == "ElevatingRamp" then
		inst:SetAttribute("IsElevatingRamp", true)
		inst:SetAttribute("ElevationAngleDeg", ELEVATING_RAMP_ANGLE_DEG)
	end

	inst.Parent = parent
	return inst
end

-- Lowers Workspace.Baseplate cleanly beneath CageFloor (Position = (0, -10.05, 0), top Y = -2.05)
-- to eliminate visual Z-fighting without deleting the Baseplate fixture.
local function lowerBaseplateToPreventZFighting(targetParent: Instance?)
	local ws = targetParent or Workspace
	local baseplate = ws:FindFirstChild("Baseplate")
	if not baseplate and ws ~= Workspace then
		baseplate = Workspace:FindFirstChild("Baseplate")
	end
	if baseplate and baseplate:IsA("BasePart") then
		local currentTopY = baseplate.Position.Y + (baseplate.Size.Y * 0.5)
		if currentTopY > -2.05 then
			local newPosY = -2.05 - (baseplate.Size.Y * 0.5)
			baseplate.Position = Vector3.new(baseplate.Position.X, newPosY, baseplate.Position.Z)
		end
	end
end

local function makeVisualPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function makeVisualCylinder(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): Part
	local p = makeVisualPart(parent, name, size, cframe, color, material, transparency)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function makeVisualWedge(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?
): WedgePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function createCircleArcMarkings(
	parent: Instance,
	namePrefix: string,
	center: Vector3,
	radius: number,
	lineWidth: number,
	lineHeight: number,
	startAngleDeg: number,
	endAngleDeg: number,
	segments: number,
	color: Color3,
	material: Enum.Material
)
	local totalRad = math.rad(endAngleDeg - startAngleDeg)
	local startRad = math.rad(startAngleDeg)
	local segLen = (math.abs(totalRad) * radius) / segments + 0.12
	for i = 1, segments do
		local a0 = startRad + totalRad * ((i - 1) / segments)
		local a1 = startRad + totalRad * (i / segments)
		local mid = (a0 + a1) * 0.5
		local px = center.X + math.cos(mid) * radius
		local pz = center.Z + math.sin(mid) * radius
		local tangent = Vector3.new(-math.sin(mid), 0, math.cos(mid))
		makeVisualPart(
			parent,
			string.format("%s_%02d", namePrefix, i),
			Vector3.new(lineWidth, lineHeight, segLen),
			CFrame.lookAt(Vector3.new(px, center.Y, pz), Vector3.new(px, center.Y, pz) + tangent),
			color,
			material,
			0
		)
	end
end

-- Helper to create non-colliding visual beam between two 3D points
local function makeBeam(
	parent: Instance,
	name: string,
	p1: Vector3,
	p2: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material
): Part?
	local delta = p2 - p1
	local dist = delta.Magnitude
	if dist < 0.05 then
		return nil
	end
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(thickness, thickness, dist)
	p.CFrame = CFrame.lookAt((p1 + p2) * 0.5, p2)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material
	p.Parent = parent
	return p
end

-- Builds Pitch Markings (parented under CageFloor to guarantee RigAndCardService raycast passes)
local function buildPitchMarkings(floorPart: BasePart, profile: Types.ArenaGeometryProfile)
	local lineColor = Color3.fromRGB(195, 198, 202)
	local lineMat = Enum.Material.Concrete
	local lineY = 0.025
	local lw = 0.6
	local lh = 0.05

	if profile.hasChamferedCorners then
		-- Touchlines (West: X = -79.4, East: X = +79.4, Z in [-100, +100])
		makeVisualPart(floorPart, "TouchlineWest", Vector3.new(lw, lh, 200.0), CFrame.new(-79.4, lineY, 0), lineColor, lineMat)
		makeVisualPart(floorPart, "TouchlineEast", Vector3.new(lw, lh, 200.0), CFrame.new(79.4, lineY, 0), lineColor, lineMat)

		-- Goal lines (North: Z = -119.5, South: Z = +119.5, spanning X in [-59.5, +59.5])
		makeVisualPart(floorPart, "GoalLineNorth", Vector3.new(119.0, lh, lw), CFrame.new(0, lineY, -119.5), lineColor, lineMat)
		makeVisualPart(floorPart, "GoalLineSouth", Vector3.new(119.0, lh, lw), CFrame.new(0, lineY, 119.5), lineColor, lineMat)

		-- 4 Diagonal Chamfer Corner lines parallel to chamfer walls
		makeBeam(floorPart, "CornerLine_NW", Vector3.new(-79.4, lineY, -100.0), Vector3.new(-59.5, lineY, -119.5), lw, lineColor, lineMat)
		makeBeam(floorPart, "CornerLine_NE", Vector3.new(79.4, lineY, -100.0), Vector3.new(59.5, lineY, -119.5), lw, lineColor, lineMat)
		makeBeam(floorPart, "CornerLine_SW", Vector3.new(-79.4, lineY, 100.0), Vector3.new(-59.5, lineY, 119.5), lw, lineColor, lineMat)
		makeBeam(floorPart, "CornerLine_SE", Vector3.new(79.4, lineY, 100.0), Vector3.new(59.5, lineY, 119.5), lw, lineColor, lineMat)
	else
		-- Touchlines (West: X = -79.4, East: X = +79.4, Z in [-120, +120])
		makeVisualPart(floorPart, "TouchlineWest", Vector3.new(lw, lh, 240 + lw), CFrame.new(-79.4, lineY, 0), lineColor, lineMat)
		makeVisualPart(floorPart, "TouchlineEast", Vector3.new(lw, lh, 240 + lw), CFrame.new(79.4, lineY, 0), lineColor, lineMat)

		-- Goal lines (North: Z = -120, South: Z = +120, spanning X in [-79.4, +79.4])
		makeVisualPart(floorPart, "GoalLineNorth", Vector3.new(158.8 + lw, lh, lw), CFrame.new(0, lineY, -120), lineColor, lineMat)
		makeVisualPart(floorPart, "GoalLineSouth", Vector3.new(158.8 + lw, lh, lw), CFrame.new(0, lineY, 120), lineColor, lineMat)
	end

	-- Halfway line (Z = 0)
	makeVisualPart(floorPart, "HalfwayLine", Vector3.new(158.8, lh, lw), CFrame.new(0, lineY, 0), lineColor, lineMat)

	-- Center Circle (Radius ~20 studs) & Center Spot
	createCircleArcMarkings(floorPart, "CenterCircle", Vector3.new(0, lineY, 0), 20, lw, lh, 0, 360, 36, lineColor, lineMat)
	makeVisualCylinder(
		floorPart,
		"CenterSpot",
		Vector3.new(lh, 2.0, 2.0),
		CFrame.new(0, lineY + 0.005, 0) * CFrame.Angles(0, 0, math.rad(90)),
		lineColor,
		lineMat,
		0
	)

	-- North and South Penalty Areas, Goal Areas, Penalty Spots and D-Arcs
	for _, zSign in ipairs({ -1, 1 }) do
		local sideTag = if zSign < 0 then "North" else "South"
		local penFrontZ = zSign * 84.0
		local penMidZ = zSign * 102.0
		local goalAreaFrontZ = zSign * 106.0
		local goalAreaMidZ = zSign * 113.0
		local penSpotZ = zSign * 96.0

		-- Penalty Box (Width 56, Depth 36 studs: X in [-28, 28], Z in [±84, ±120])
		makeVisualPart(floorPart, sideTag .. "PenaltyFront", Vector3.new(56 + lw, lh, lw), CFrame.new(0, lineY, penFrontZ), lineColor, lineMat)
		makeVisualPart(floorPart, sideTag .. "PenaltyWest", Vector3.new(lw, lh, 36), CFrame.new(-28, lineY, penMidZ), lineColor, lineMat)
		makeVisualPart(floorPart, sideTag .. "PenaltyEast", Vector3.new(lw, lh, 36), CFrame.new(28, lineY, penMidZ), lineColor, lineMat)

		-- Goal Area / 6-yard box (Width 32, Depth 14 studs: X in [-16, 16], Z in [±106, ±120])
		makeVisualPart(floorPart, sideTag .. "GoalAreaFront", Vector3.new(32 + lw, lh, lw), CFrame.new(0, lineY, goalAreaFrontZ), lineColor, lineMat)
		makeVisualPart(floorPart, sideTag .. "GoalAreaWest", Vector3.new(lw, lh, 14), CFrame.new(-16, lineY, goalAreaMidZ), lineColor, lineMat)
		makeVisualPart(floorPart, sideTag .. "GoalAreaEast", Vector3.new(lw, lh, 14), CFrame.new(16, lineY, goalAreaMidZ), lineColor, lineMat)

		-- Penalty Spot
		makeVisualCylinder(
			floorPart,
			sideTag .. "PenaltySpot",
			Vector3.new(lh, 1.5, 1.5),
			CFrame.new(0, lineY + 0.005, penSpotZ) * CFrame.Angles(0, 0, math.rad(90)),
			lineColor,
			lineMat,
			0
		)

		-- Penalty D-Arc (radius 11 studs centered on penalty spot)
		if zSign < 0 then
			createCircleArcMarkings(floorPart, sideTag .. "PenaltyArc", Vector3.new(0, lineY, penSpotZ), 11, lw, lh, 36, 144, 14, lineColor, lineMat)
		else
			createCircleArcMarkings(floorPart, sideTag .. "PenaltyArc", Vector3.new(0, lineY, penSpotZ), 11, lw, lh, 216, 324, 14, lineColor, lineMat)
		end
	end
end

-- Builds Goal Back Frame & Nets behind North & South goals (Z in [±120, ±126])
local function buildGoalNets(arena: Model)
	local gw = GOAL_WIDTH_X -- 24.0
	local gh = GOAL_HEIGHT_Y -- 10.0
	local gd = GOAL_DEPTH_Z -- 6.0
	local frameColor = Color3.fromRGB(205, 208, 212)
	local frameMat = Enum.Material.Metal
	local netColor = Color3.fromRGB(75, 80, 85)
	local netMat = Enum.Material.Fabric

	for _, zSign in ipairs({ -1, 1 }) do
		local sideTag = if zSign < 0 then "North" else "South"
		local backZ = zSign * (ARENA_HALF_LENGTH_Z + gd) -- ±126.0
		local midZ = zSign * (ARENA_HALF_LENGTH_Z + gd * 0.5) -- ±123.0

		-- Vertical back stanchions
		makeVisualPart(arena, sideTag .. "GoalLeftBackStanchion", Vector3.new(0.5, gh, 0.5), CFrame.new(-12, gh * 0.5, backZ), frameColor, frameMat)
		makeVisualPart(arena, sideTag .. "GoalRightBackStanchion", Vector3.new(0.5, gh, 0.5), CFrame.new(12, gh * 0.5, backZ), frameColor, frameMat)

		-- Depth bars (top and ground)
		makeVisualPart(arena, sideTag .. "GoalLeftTopBar", Vector3.new(0.5, 0.5, gd), CFrame.new(-12, gh, midZ), frameColor, frameMat)
		makeVisualPart(arena, sideTag .. "GoalRightTopBar", Vector3.new(0.5, 0.5, gd), CFrame.new(12, gh, midZ), frameColor, frameMat)
		makeVisualPart(arena, sideTag .. "GoalLeftGroundBar", Vector3.new(0.5, 0.5, gd), CFrame.new(-12, 0.25, midZ), frameColor, frameMat)
		makeVisualPart(arena, sideTag .. "GoalRightGroundBar", Vector3.new(0.5, 0.5, gd), CFrame.new(12, 0.25, midZ), frameColor, frameMat)

		-- Back crossbars
		makeVisualPart(arena, sideTag .. "GoalBackTopBar", Vector3.new(gw + 0.5, 0.5, 0.5), CFrame.new(0, gh, backZ), frameColor, frameMat)
		makeVisualPart(arena, sideTag .. "GoalBackGroundBar", Vector3.new(gw + 0.5, 0.5, 0.5), CFrame.new(0, 0.25, backZ), frameColor, frameMat)

		-- Net sheets (Back, Top, Left, Right) with physical collision enabled
		local backNet = makeVisualPart(arena, sideTag .. "GoalBackNet", Vector3.new(gw, gh, 0.4), CFrame.new(0, gh * 0.5, backZ + zSign * 0.2), netColor, netMat, 0.45)
		backNet.CanCollide = true
		backNet.CanQuery = false
		local topNet = makeVisualPart(arena, sideTag .. "GoalTopNet", Vector3.new(gw, 0.4, gd), CFrame.new(0, gh, midZ), netColor, netMat, 0.45)
		topNet.CanCollide = true
		topNet.CanQuery = false
		local leftNet = makeVisualPart(arena, sideTag .. "GoalLeftNet", Vector3.new(0.4, gh, gd), CFrame.new(-12, gh * 0.5, midZ), netColor, netMat, 0.45)
		leftNet.CanCollide = true
		leftNet.CanQuery = false
		local rightNet = makeVisualPart(arena, sideTag .. "GoalRightNet", Vector3.new(0.4, gh, gd), CFrame.new(12, gh * 0.5, midZ), netColor, netMat, 0.45)
		rightNet.CanCollide = true
		rightNet.CanQuery = false



		-- Visual net strands (offset cleanly in front of back net sheet to eliminate Z-fighting)
		local strandColor = Color3.fromRGB(115, 120, 125)
		for x = -10, 10, 2 do
			makeVisualPart(arena, string.format("%sGoalNetStrandV_%d", sideTag, x), Vector3.new(0.08, gh, 0.08), CFrame.new(x, gh * 0.5, backZ - zSign * 0.10), strandColor, netMat, 0.35)
		end
		for y = 2, 8, 2 do
			makeVisualPart(arena, string.format("%sGoalNetStrandH_%d", sideTag, y), Vector3.new(gw, 0.08, 0.08), CFrame.new(0, y, backZ - zSign * 0.16), strandColor, netMat, 0.35)
		end
	end
end

-- Builds High-Detail Steel Cage Structure for Variants A, B, and C
local function buildDetailedSteelCage(arena: Model, profile: Types.ArenaGeometryProfile)
	local cageFolder = Instance.new("Folder")
	cageFolder.Name = "SteelCageStructure"
	cageFolder.Parent = arena

	local steelColor = Color3.fromRGB(28, 31, 35)
	local steelMat = Enum.Material.CorrodedMetal
	local railHeights = { 4.0, 10.0, 16.0, 22.0, profile.eaveHeightY }
	local poly = profile.footprintPolygonXZ
	local numPoly = #poly

	-- Loop through polygon edges to build perimeter pillars, horizontal rails, and X-braces
	for i = 1, numPoly do
		local pA = poly[i]
		local pB = poly[(i % numPoly) + 1]
		local edgeVec = pB - pA
		local edgeLen = edgeVec.Magnitude
		local edgeDir = edgeVec / edgeLen
		local nBays = math.max(1, math.round(edgeLen / 10.0))
		local bayLen = edgeLen / nBays

		-- Pillar creation: Loop b from 0 to nBays - 1 to prevent duplicate corner pillars
		for b = 0, nBays - 1 do
			local ptXZ = pA + edgeDir * (b * bayLen)
			local inGoalZone = math.abs(ptXZ.X) < 12.0 and math.abs(ptXZ.Y) > 118.0

			-- Vertical Pillar (skip entirely in the 24-stud goal opening & transom to avoid Z-fighting)
			if not inGoalZone then
				makeVisualPart(
					cageFolder,
					string.format("Pillar_E%d_B%d", i, b),
					Vector3.new(0.65, profile.eaveHeightY, 0.65),
					CFrame.new(ptXZ.X, profile.eaveHeightY * 0.5, ptXZ.Y),
					steelColor,
					steelMat
				)
			end

			-- Bays between b and b + 1: horizontal rails and X-bracing
			local bNext = b + 1
			local pt1 = ptXZ
			local pt2 = pA + edgeDir * (bNext * bayLen)
			local bayMidX = (pt1.X + pt2.X) * 0.5
			local bayMidZ = (pt1.Y + pt2.Y) * 0.5
			local isNorthSouthWall = math.abs(bayMidZ) > 118.0
			local bayInGoalZone = math.abs(bayMidX) < 12.0 and isNorthSouthWall
			local overlapsGoalMouth = isNorthSouthWall and ((math.min(pt1.X, pt2.X) < 12.0) and (math.max(pt1.X, pt2.X) > -12.0))

			-- Horizontal sub-rails
			for rIdx, yLevel in ipairs(railHeights) do
				-- In the goal opening, only create the top roof eave rail to avoid crossbar/transom Z-fighting.
				-- Any bay overlapping |X| < 12.0 on North/South walls must skip rails below crossbar (Y < 10.0).
				local skipRail = false
				if bayInGoalZone and yLevel < profile.eaveHeightY then
					skipRail = true
				elseif overlapsGoalMouth and yLevel < 10.0 then
					skipRail = true
				end

				if not skipRail then
					makeBeam(
						cageFolder,
						string.format("Rail_E%d_B%d_L%d", i, b, rIdx),
						Vector3.new(pt1.X, yLevel, pt1.Y),
						Vector3.new(pt2.X, yLevel, pt2.Y),
						0.45,
						steelColor,
						steelMat
					)
				end
			end

			-- Diagonal X-Braces (only outside goal mouth)
			if not bayInGoalZone then
				-- Lower bay cross: Y = 0 to 10 (skip if overlapping goal mouth |X| < 12 on North/South walls)
				if not overlapsGoalMouth then
					makeBeam(
						cageFolder,
						string.format("XBraceLowA_E%d_B%d", i, b),
						Vector3.new(pt1.X, 0.2, pt1.Y),
						Vector3.new(pt2.X, 10.0, pt2.Y),
						0.28,
						steelColor,
						steelMat
					)
					makeBeam(
						cageFolder,
						string.format("XBraceLowB_E%d_B%d", i, b),
						Vector3.new(pt1.X, 10.0, pt1.Y),
						Vector3.new(pt2.X, 0.2, pt2.Y),
						0.28,
						steelColor,
						steelMat
					)
				end

				-- Upper bay cross: Y = 10 to eaveHeight
				if profile.eaveHeightY > 16.0 then
					makeBeam(
						cageFolder,
						string.format("XBraceHiA_E%d_B%d", i, b),
						Vector3.new(pt1.X, 10.0, pt1.Y),
						Vector3.new(pt2.X, profile.eaveHeightY, pt2.Y),
						0.28,
						steelColor,
						steelMat
					)
					makeBeam(
						cageFolder,
						string.format("XBraceHiB_E%d_B%d", i, b),
						Vector3.new(pt1.X, profile.eaveHeightY, pt1.Y),
						Vector3.new(pt2.X, 10.0, pt2.Y),
						0.28,
						steelColor,
						steelMat
					)
				end
			end
		end
	end

	-- Roof framing:
	if profile.hasBeveledRoof then
		-- Variant C: 45-degree angled roof bevel rafters connecting eave to flat ceiling
		-- Corner bevel at 45 deg meets North/South bevel (Z=±112) at X=±56.686 and West/East bevel (X=±72) at Z=±96.686
		local ceilPoly = {
			Vector2.new(-56.686, -112),
			Vector2.new(56.686, -112),
			Vector2.new(72, -96.686),
			Vector2.new(72, 96.686),
			Vector2.new(56.686, 112),
			Vector2.new(-56.686, 112),
			Vector2.new(-72, 96.686),
			Vector2.new(-72, -96.686),
		}

		for i = 1, numPoly do
			local pA = poly[i]
			local pB = poly[(i % numPoly) + 1]
			local pA_ceil = ceilPoly[i]
			local pB_ceil = ceilPoly[(i % numPoly) + 1]
			local edgeVec = pB - pA
			local edgeLen = edgeVec.Magnitude
			local nRafters = math.max(1, math.round(edgeLen / 10.0))

			for r = 0, nRafters do
				local t = r / nRafters
				local ptEaveXZ = pA:Lerp(pB, t)
				local ptCeilXZ = pA_ceil:Lerp(pB_ceil, t)
				local eavePt = Vector3.new(ptEaveXZ.X, profile.eaveHeightY, ptEaveXZ.Y)
				local ceilPt = Vector3.new(ptCeilXZ.X, profile.ceilingHeightY, ptCeilXZ.Y)
				makeBeam(
					cageFolder,
					string.format("Rafter_E%d_R%d", i, r),
					eavePt,
					ceilPt,
					0.5,
					steelColor,
					steelMat
				)
			end
		end

		-- Central flat ceiling grid at Y = 32.0 (restricted to |X|+|Z| <= diagLimit)
		local ceilInnerX = profile.halfWidthX - profile.roofBevelStuds -- 72
		local ceilInnerZ = profile.halfLengthZ - profile.roofBevelStuds -- 112
		local baseChamferCut = if profile.chamferCutStuds > 0 then profile.chamferCutStuds else CHAMFER_CUT_STUDS
		local diagLimit = (profile.halfWidthX + profile.halfLengthZ - baseChamferCut) - (profile.roofBevelStuds * SQRT2) -- approx 168.68629

		for x = -ceilInnerX + 9, ceilInnerX - 9, 18 do
			local maxZ = math.min(ceilInnerZ, diagLimit - math.abs(x))
			if maxZ > 0.5 then
				makeVisualPart(
					cageFolder,
					string.format("CeilBeamZ_%d", math.floor(x)),
					Vector3.new(0.5, 0.5, maxZ * 2.0),
					CFrame.new(x, profile.ceilingHeightY + 0.25, 0),
					steelColor,
					steelMat
				)
			end
		end
		for z = -ceilInnerZ + 11.2, ceilInnerZ - 11.2, 22.4 do
			local maxX = math.min(ceilInnerX, diagLimit - math.abs(z))
			if maxX > 0.5 then
				makeVisualPart(
					cageFolder,
					string.format("CeilBeamX_%d", math.floor(z)),
					Vector3.new(maxX * 2.0, 0.5, 0.5),
					CFrame.new(0, profile.ceilingHeightY + 0.25, z),
					steelColor,
					steelMat
				)
			end
		end

		-- 8-gon Ceiling Perimeter Ring
		for idx = 1, #ceilPoly do
			local nextIdx = (idx % #ceilPoly) + 1
			makeBeam(
				cageFolder,
				string.format("CeilPerimeterRing_%d", idx),
				Vector3.new(ceilPoly[idx].X, profile.ceilingHeightY + 0.25, ceilPoly[idx].Y),
				Vector3.new(ceilPoly[nextIdx].X, profile.ceilingHeightY + 0.25, ceilPoly[nextIdx].Y),
				0.5,
				steelColor,
				steelMat
			)
		end
	elseif profile.hasChamferedCorners then
		-- Variant B: 8-gon ceiling grid at Y = 32.0 (restricted to |X|+|Z| <= 180)
		for x = -profile.halfWidthX + 10, profile.halfWidthX - 10, 20 do
			local maxZ = math.min(profile.halfLengthZ, 180 - math.abs(x))
			if maxZ > 0.5 then
				makeVisualPart(
					cageFolder,
					string.format("CeilBeamZ_%d", math.floor(x)),
					Vector3.new(0.5, 0.5, maxZ * 2.0),
					CFrame.new(x, profile.ceilingHeightY + 0.25, 0),
					steelColor,
					steelMat
				)
			end
		end
		for z = -profile.halfLengthZ + 10, profile.halfLengthZ - 10, 20 do
			local maxX = math.min(profile.halfWidthX, 180 - math.abs(z))
			if maxX > 0.5 then
				makeVisualPart(
					cageFolder,
					string.format("CeilBeamX_%d", math.floor(z)),
					Vector3.new(maxX * 2.0, 0.5, 0.5),
					CFrame.new(0, profile.ceilingHeightY + 0.25, z),
					steelColor,
					steelMat
				)
			end
		end

		-- 8-gon Ceiling Perimeter Ring
		for idx = 1, #poly do
			local nextIdx = (idx % #poly) + 1
			makeBeam(
				cageFolder,
				string.format("CeilPerimeterRing_%d", idx),
				Vector3.new(poly[idx].X, profile.ceilingHeightY + 0.25, poly[idx].Y),
				Vector3.new(poly[nextIdx].X, profile.ceilingHeightY + 0.25, poly[nextIdx].Y),
				0.5,
				steelColor,
				steelMat
			)
		end
	else
		-- Variant A: Full rectangular flat ceiling grid at Y = 32.0
		for x = -profile.halfWidthX + 20, profile.halfWidthX - 20, 20 do
			makeVisualPart(
				cageFolder,
				string.format("CeilBeamZ_%d", math.floor(x)),
				Vector3.new(0.5, 0.5, profile.halfLengthZ * 2.0),
				CFrame.new(x, profile.ceilingHeightY + 0.25, 0),
				steelColor,
				steelMat
			)
		end
		for z = -profile.halfLengthZ + 20, profile.halfLengthZ - 20, 20 do
			makeVisualPart(
				cageFolder,
				string.format("CeilBeamX_%d", math.floor(z)),
				Vector3.new(profile.halfWidthX * 2.0, 0.5, 0.5),
				CFrame.new(0, profile.ceilingHeightY + 0.25, z),
				steelColor,
				steelMat
			)
		end

		-- 4-corner Ceiling Perimeter Ring
		for idx = 1, #poly do
			local nextIdx = (idx % #poly) + 1
			makeBeam(
				cageFolder,
				string.format("CeilPerimeterRing_%d", idx),
				Vector3.new(poly[idx].X, profile.ceilingHeightY + 0.25, poly[idx].Y),
				Vector3.new(poly[nextIdx].X, profile.ceilingHeightY + 0.25, poly[nextIdx].Y),
				0.5,
				steelColor,
				steelMat
			)
		end
	end

	-- Over-Goal Transom Steel Cage Framing (North & South):
	-- Covers the area above the crossbar (Y in [10.0, eaveHeightY], X in [-12, +12])
	-- so the steel cage does not break or have a gap above the goal.
	for _, zSign in ipairs({ -1, 1 }) do
		local goalZ = zSign * profile.halfLengthZ
		local tag = if zSign < 0 then "North" else "South"
		local transomHeight = profile.eaveHeightY - 10.0
		local transomCenterY = 10.0 + (transomHeight * 0.5)

		-- Vertical mullions above crossbar (X = -6, 0, +6)
		for _, xPos in ipairs({ -6.0, 0.0, 6.0 }) do
			makeVisualPart(
				cageFolder,
				string.format("OverGoalMullion_%s_X%d", tag, math.floor(xPos)),
				Vector3.new(0.65, transomHeight, 0.65),
				CFrame.new(xPos, transomCenterY, goalZ),
				steelColor,
				steelMat
			)
		end

		-- Horizontal rails matching cage levels at Y = 16.0 and Y = 22.0
		for _, yLevel in ipairs(railHeights) do
			if yLevel > 10.0 and yLevel < profile.eaveHeightY then
				makeBeam(
					cageFolder,
					string.format("OverGoalRail_%s_Y%d", tag, math.floor(yLevel)),
					Vector3.new(-12.0, yLevel, goalZ),
					Vector3.new(12.0, yLevel, goalZ),
					0.45,
					steelColor,
					steelMat
				)
			end
		end

		-- Diagonal X-Braces in the two 12-stud bays above crossbar (Y = 10.2 to 22.0)
		for _, xCenter in ipairs({ -6.0, 6.0 }) do
			makeBeam(
				cageFolder,
				string.format("OverGoalBraceA_%s_X%d", tag, math.floor(xCenter)),
				Vector3.new(xCenter - 6.0, 10.2, goalZ),
				Vector3.new(xCenter + 6.0, 22.0, goalZ),
				0.28,
				steelColor,
				steelMat
			)
			makeBeam(
				cageFolder,
				string.format("OverGoalBraceB_%s_X%d", tag, math.floor(xCenter)),
				Vector3.new(xCenter - 6.0, 22.0, goalZ),
				Vector3.new(xCenter + 6.0, 10.2, goalZ),
				0.28,
				steelColor,
				steelMat
			)
		end
	end
end

-- Builds Gritty Urban Street Backdrop (360° horizon buildings, alleys, floodlights, containers)
local function buildUrbanBackdrop(arena: Model, profile: Types.ArenaGeometryProfile)
	local backdrop = Instance.new("Folder")
	backdrop.Name = "UrbanBackdrop"
	backdrop.Parent = arena

	local darkAsphaltColor = Color3.fromRGB(32, 35, 38)
	local concreteColor = Color3.fromRGB(44, 48, 52)
	local wallColor = Color3.fromRGB(38, 41, 45)
	local steelCapColor = Color3.fromRGB(24, 27, 30)

	-- 1. Outer Perimeter Asphalt Apron (600 x 600 studs, top at Y = -0.15, CanCollide = true, CanQuery = false)
	local apron = makeVisualPart(
		backdrop,
		"OuterAlleyApron",
		Vector3.new(600, 2.0, 600),
		CFrame.new(0, -1.15, 0),
		darkAsphaltColor,
		Enum.Material.Concrete
	)
	apron.CanCollide = true
	apron.CanQuery = false

	-- 2. Concrete Goal Runoff Slabs & Concrete Backing Walls
	for _, zSign in ipairs({ -1, 1 }) do
		local sideTag = if zSign < 0 then "North" else "South"
		local wallZ = zSign * 128.5

		-- Runoff slab below playing floor at Y = -0.1 (Pos.Y = -0.6, Size.Y = 1.0, starts at Z = ±121.0 behind cage wall ±120.0)
		local runoffSlab = makeVisualPart(
			backdrop,
			sideTag .. "GoalRunoffSlab",
			Vector3.new(36, 1.0, 9.0),
			CFrame.new(0, -0.6, zSign * 125.5),
			concreteColor,
			Enum.Material.Concrete
		)
		runoffSlab.CanCollide = true
		runoffSlab.CanQuery = false

		-- Concrete wall behind goal
		makeVisualPart(
			backdrop,
			sideTag .. "GoalBackWall",
			Vector3.new(36, 14, 1.6),
			CFrame.new(0, 7.0, wallZ),
			wallColor,
			Enum.Material.Concrete
		)
		makeVisualPart(
			backdrop,
			sideTag .. "GoalBackWallCap",
			Vector3.new(37, 0.6, 2.2),
			CFrame.new(0, 14.3, wallZ),
			steelCapColor,
			Enum.Material.CorrodedMetal
		)
	end

	-- 3. Perimeter Alley Walls surrounding the Pitch at |X| = 104, |Z| = 152
	for _, xSign in ipairs({ -1, 1 }) do
		local tag = if xSign < 0 then "West" else "East"
		local wallX = xSign * 104.0
		makeVisualPart(
			backdrop,
			"AlleyWall_" .. tag,
			Vector3.new(2.0, 20.0, 304.0),
			CFrame.new(wallX, 10.0, 0),
			wallColor,
			Enum.Material.Concrete
		)
		makeVisualPart(
			backdrop,
			"AlleyWallCap_" .. tag,
			Vector3.new(2.8, 0.6, 305.0),
			CFrame.new(wallX, 20.3, 0),
			steelCapColor,
			Enum.Material.Metal
		)
	end

	for _, zSign in ipairs({ -1, 1 }) do
		local tag = if zSign < 0 then "North" else "South"
		local wallZ = zSign * 152.0
		makeVisualPart(
			backdrop,
			"AlleyWall_" .. tag,
			Vector3.new(208.0, 20.0, 2.0),
			CFrame.new(0, 10.0, wallZ),
			wallColor,
			Enum.Material.Concrete
		)
		makeVisualPart(
			backdrop,
			"AlleyWallCap_" .. tag,
			Vector3.new(209.0, 0.6, 2.8),
			CFrame.new(0, 20.3, wallZ),
			steelCapColor,
			Enum.Material.Metal
		)
	end

	-- 4. Gritty Industrial Props (Shipping Containers, Stacks, Dugouts)
	local containerDefs = {
		{ pos = Vector3.new(-92, 5, -135), angY = 15, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(125, 58, 38) },
		{ pos = Vector3.new(-92, 15, -135), angY = 15, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(42, 65, 75) },
		{ pos = Vector3.new(92, 5, -136), angY = -12, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(52, 60, 48) },
		{ pos = Vector3.new(-93, 5, 135), angY = -8, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(38, 56, 80) },
		{ pos = Vector3.new(92, 5, 134), angY = 12, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(50, 48, 48) },
		{ pos = Vector3.new(93, 15, 134), angY = 12, size = Vector3.new(10, 10, 28), col = Color3.fromRGB(120, 52, 35) },
	}
	for idx, cDef in ipairs(containerDefs) do
		makeVisualPart(
			backdrop,
			string.format("Container_%d", idx),
			cDef.size,
			CFrame.new(cDef.pos) * CFrame.Angles(0, math.rad(cDef.angY), 0),
			cDef.col,
			Enum.Material.CorrodedMetal
		)
	end

	-- Wooden crate stacks in alley corners
	local crateColor = Color3.fromRGB(85, 72, 58)
	local crateClusters = {
		Vector3.new(-94, 0, -105),
		Vector3.new(94, 0, -105),
		Vector3.new(-94, 0, 105),
		Vector3.new(94, 0, 105),
	}
	for cIdx, basePos in ipairs(crateClusters) do
		makeVisualPart(backdrop, string.format("Crate_%d_1", cIdx), Vector3.new(4, 4, 4), CFrame.new(basePos + Vector3.new(0, 2, 0)), crateColor, Enum.Material.WoodPlanks)
		makeVisualPart(backdrop, string.format("Crate_%d_2", cIdx), Vector3.new(3.5, 3.5, 3.5), CFrame.new(basePos + Vector3.new(2, 1.75, 2.5)), crateColor, Enum.Material.WoodPlanks)
		makeVisualPart(backdrop, string.format("Crate_%d_3", cIdx), Vector3.new(3.8, 3.8, 3.8), CFrame.new(basePos + Vector3.new(-0.2, 5.9, 0.4)), crateColor, Enum.Material.WoodPlanks)
	end

	-- Oil drum clusters
	local drumClusters = {
		Vector3.new(-94, 0, -80),
		Vector3.new(94, 0, 80),
	}
	for dIdx, basePos in ipairs(drumClusters) do
		for offsetIdx, offset in ipairs({ Vector3.new(0, 2, 0), Vector3.new(1.8, 2, 0), Vector3.new(0.9, 2, 1.6) }) do
			makeVisualCylinder(
				backdrop,
				string.format("OilDrum_%d_%d", dIdx, offsetIdx),
				Vector3.new(4.0, 2.2, 2.2),
				CFrame.new(basePos + offset) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(48, 52, 58),
				Enum.Material.CorrodedMetal
			)
		end
	end

	-- Sideline player benches / shelters (outside cage at X = ±86.5, Z = 0)
	for _, xSign in ipairs({ -1, 1 }) do
		local sideTag = if xSign < 0 then "West" else "East"
		local benchX = xSign * 86.5
		-- Concrete bench
		makeVisualPart(
			backdrop,
			sideTag .. "PlayerBench",
			Vector3.new(2.5, 1.4, 24.0),
			CFrame.new(benchX, 0.7, 0),
			concreteColor,
			Enum.Material.Concrete
		)
		-- Overhead metal shelter
		makeVisualPart(
			backdrop,
			sideTag .. "ShelterRoof",
			Vector3.new(5.0, 0.3, 26.0),
			CFrame.new(benchX + xSign * 0.5, 8.5, 0) * CFrame.Angles(0, 0, -xSign * math.rad(8)),
			Color3.fromRGB(36, 40, 44),
			Enum.Material.CorrodedMetal
		)
		makeVisualPart(
			backdrop,
			sideTag .. "ShelterPost1",
			Vector3.new(0.4, 8.5, 0.4),
			CFrame.new(benchX + xSign * 2.0, 4.25, -12.0),
			steelCapColor,
			Enum.Material.Metal
		)
		makeVisualPart(
			backdrop,
			sideTag .. "ShelterPost2",
			Vector3.new(0.4, 8.5, 0.4),
			CFrame.new(benchX + xSign * 2.0, 4.25, 12.0),
			steelCapColor,
			Enum.Material.Metal
		)
	end

	-- 5. 360° Urban Horizon Buildings (taller heights 85 to 160 studs filling the skyline)
	local buildingData = {
		-- West buildings (X in [-135, -230])
		{ pos = Vector3.new(-145, 0, -120), size = Vector3.new(45, 95, 45), col = Color3.fromRGB(34, 38, 42) },
		{ pos = Vector3.new(-155, 0, -65),  size = Vector3.new(52, 125, 50), col = Color3.fromRGB(40, 44, 48) },
		{ pos = Vector3.new(-140, 0, 0),    size = Vector3.new(44, 88, 60), col = Color3.fromRGB(36, 39, 43) },
		{ pos = Vector3.new(-160, 0, 65),   size = Vector3.new(55, 140, 50), col = Color3.fromRGB(42, 46, 50) },
		{ pos = Vector3.new(-145, 0, 120),  size = Vector3.new(46, 110, 45), col = Color3.fromRGB(32, 35, 39) },
		{ pos = Vector3.new(-205, 0, 0),    size = Vector3.new(65, 155, 180), col = Color3.fromRGB(26, 29, 32) },

		-- East buildings (X in [135, 230])
		{ pos = Vector3.new(145, 0, -120),  size = Vector3.new(46, 100, 45), col = Color3.fromRGB(38, 42, 46) },
		{ pos = Vector3.new(155, 0, -65),   size = Vector3.new(50, 130, 52), col = Color3.fromRGB(34, 37, 41) },
		{ pos = Vector3.new(140, 0, 0),     size = Vector3.new(42, 92, 58), col = Color3.fromRGB(42, 45, 50) },
		{ pos = Vector3.new(160, 0, 65),    size = Vector3.new(54, 145, 48), col = Color3.fromRGB(36, 40, 44) },
		{ pos = Vector3.new(145, 0, 120),   size = Vector3.new(45, 115, 45), col = Color3.fromRGB(30, 33, 37) },
		{ pos = Vector3.new(205, 0, 0),     size = Vector3.new(65, 160, 180), col = Color3.fromRGB(25, 28, 31) },

		-- North buildings (Z in [-180, -280])
		{ pos = Vector3.new(-85, 0, -195),  size = Vector3.new(48, 110, 50), col = Color3.fromRGB(38, 41, 45) },
		{ pos = Vector3.new(0, 0, -205),    size = Vector3.new(60, 145, 55), col = Color3.fromRGB(30, 33, 36) },
		{ pos = Vector3.new(85, 0, -195),   size = Vector3.new(48, 120, 50), col = Color3.fromRGB(40, 44, 48) },
		{ pos = Vector3.new(0, 0, -265),    size = Vector3.new(180, 160, 60), col = Color3.fromRGB(24, 27, 30) },

		-- South buildings (Z in [180, 280])
		{ pos = Vector3.new(-85, 0, 195),   size = Vector3.new(48, 105, 50), col = Color3.fromRGB(36, 39, 43) },
		{ pos = Vector3.new(0, 0, 205),     size = Vector3.new(60, 138, 55), col = Color3.fromRGB(32, 35, 38) },
		{ pos = Vector3.new(85, 0, 195),    size = Vector3.new(48, 125, 50), col = Color3.fromRGB(42, 45, 50) },
		{ pos = Vector3.new(0, 0, 265),     size = Vector3.new(180, 155, 60), col = Color3.fromRGB(24, 27, 30) },
	}

	for bIdx, bData in ipairs(buildingData) do
		local bH = bData.size.Y
		local bCenterY = bH * 0.5
		local bCenter = Vector3.new(bData.pos.X, bCenterY, bData.pos.Z)

		-- Main building block
		makeVisualPart(
			backdrop,
			string.format("Bldg_%d", bIdx),
			bData.size,
			CFrame.new(bCenter),
			bData.col,
			Enum.Material.Concrete
		)

		-- Rooftop parapet trim
		makeVisualPart(
			backdrop,
			string.format("BldgParapet_%d", bIdx),
			Vector3.new(bData.size.X + 0.6, 1.5, bData.size.Z + 0.6),
			CFrame.new(bData.pos.X, bH + 0.75, bData.pos.Z),
			steelCapColor,
			Enum.Material.Concrete
		)

		-- Rooftop AC condenser box unit
		makeVisualPart(
			backdrop,
			string.format("BldgAC_%d", bIdx),
			Vector3.new(6.0, 4.0, 5.0),
			CFrame.new(bData.pos.X + 6, bH + 2.0, bData.pos.Z + 4),
			Color3.fromRGB(46, 50, 54),
			Enum.Material.CorrodedMetal
		)

		-- Distant subtle amber twilight window rows
		if bH >= 65 and bIdx <= 16 then
			local winColor = Color3.fromRGB(180, 140, 75)
			for wY = 20, bH - 15, 18 do
				local winOffset = (wY % 8) * 2 - 8
				local winCF: CFrame
				local winSize: Vector3
				if math.abs(bData.pos.X) > 0.1 then
					local faceX = bData.pos.X - math.sign(bData.pos.X) * (bData.size.X * 0.5 + 0.2)
					winCF = CFrame.new(faceX, wY, bData.pos.Z + winOffset)
					winSize = Vector3.new(0.3, 3.5, 4.0)
				else
					local faceZ = bData.pos.Z - math.sign(bData.pos.Z) * (bData.size.Z * 0.5 + 0.2)
					winCF = CFrame.new(bData.pos.X + winOffset, wY, faceZ)
					winSize = Vector3.new(4.0, 3.5, 0.3)
				end
				makeVisualPart(
					backdrop,
					string.format("BldgWin_%d_%d", bIdx, math.floor(wY)),
					winSize,
					winCF,
					winColor,
					Enum.Material.Neon
				)
			end
		end
	end

	-- 6. Street Floodlight Towers (8 Towers around pitch)
	local towerLocations = {
		Vector3.new(-87, 0, -85),
		Vector3.new(-87, 0, -25),
		Vector3.new(-87, 0, 25),
		Vector3.new(-87, 0, 85),
		Vector3.new(87, 0, -85),
		Vector3.new(87, 0, -25),
		Vector3.new(87, 0, 25),
		Vector3.new(87, 0, 85),
	}

	for tIdx, tPos in ipairs(towerLocations) do
		local signX = if tPos.X < 0 then -1 else 1
		local towerHeight = 36.0

		-- Heavy square steel column
		makeVisualPart(
			backdrop,
			string.format("TowerColumn_%d", tIdx),
			Vector3.new(1.3, towerHeight, 1.3),
			CFrame.new(tPos.X, towerHeight * 0.5, tPos.Z),
			steelCapColor,
			Enum.Material.CorrodedMetal
		)

		-- Cantilever boom arm toward pitch
		local armReach = 4.0
		local armCenter = Vector3.new(tPos.X - signX * (armReach * 0.5), towerHeight + 0.6, tPos.Z)
		makeVisualPart(
			backdrop,
			string.format("TowerArm_%d", tIdx),
			Vector3.new(armReach, 0.7, 0.7),
			CFrame.new(armCenter),
			steelCapColor,
			Enum.Material.Metal
		)

		-- Floodlight lamp housing
		local headPos = Vector3.new(tPos.X - signX * armReach, towerHeight + 0.3, tPos.Z)
		local headPart = makeVisualPart(
			backdrop,
			string.format("TowerHead_%d", tIdx),
			Vector3.new(1.8, 1.4, 3.2),
			CFrame.new(headPos) * CFrame.Angles(0, 0, signX * math.rad(22)),
			Color3.fromRGB(30, 34, 38),
			Enum.Material.Metal
		)

		-- Neon bulb face
		local bulbPart = makeVisualPart(
			backdrop,
			string.format("TowerBulb_%d", tIdx),
			Vector3.new(0.2, 1.0, 2.6),
			headPart.CFrame * CFrame.new(-signX * 0.95, 0, 0),
			Color3.fromRGB(245, 230, 200),
			Enum.Material.Neon
		)

		-- Real warm industrial SpotLight
		local spot = Instance.new("SpotLight")
		spot.Name = "FloodSpot"
		spot.Color = Color3.fromRGB(235, 215, 185)
		spot.Brightness = 3.6
		spot.Range = 125.0
		spot.Angle = 75.0
		spot.Shadows = true
		spot.Face = if signX < 0 then Enum.NormalId.Right else Enum.NormalId.Left
		spot.Parent = bulbPart
	end

	-- 6. In Variants B & C, cover protruding CageFloor corners outside chamfer walls (|X|+|Z| > 180)
	if profile.hasChamferedCorners then
		for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
			local xSign, zSign = c[1], c[2]
			local suffix = (if zSign < 0 then "N" else "S") .. (if xSign < 0 then "W" else "E")
			local normal = Vector3.new(xSign * INV_SQRT2, 0, zSign * INV_SQRT2)
			local center = Vector3.new(xSign * 75.1, 0.02, zSign * 115.1)
			local rotCF = CFrame.lookAt(center, center + normal)
			makeVisualPart(
				backdrop,
				"CornerApronCover_" .. suffix,
				Vector3.new(32.0, 0.05, 15.0),
				rotCF,
				darkAsphaltColor,
				Enum.Material.Concrete
			)
		end
	end
end

-- Sets up moody dusk lighting and atmosphere (gritty realistic street aesthetic with misty overcast haze)
local function setupGrittyLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 16.8
	Lighting.GeographicLatitude = 41.5
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(85, 92, 102)
	Lighting.OutdoorAmbient = Color3.fromRGB(115, 125, 138)
	Lighting.ShadowSoftness = 0.2
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.25

	-- Gritty overcast/foggy city sky replacing default cartoon sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Name = "GrittyOvercastSky"
		sky.Parent = Lighting
	end
	sky.SkyboxBk = "rbxassetid://658623433"
	sky.SkyboxDn = "rbxassetid://316342560"
	sky.SkyboxFt = "rbxassetid://658625205"
	sky.SkyboxLf = "rbxassetid://658627155"
	sky.SkyboxRt = "rbxassetid://658628504"
	sky.SkyboxUp = "rbxassetid://658632701"
	sky.CelestialBodiesShown = false

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") and child ~= sky then
			child:Destroy()
		end
	end

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.38
	atmosphere.Offset = 0.22
	atmosphere.Color = Color3.fromRGB(155, 165, 178)
	atmosphere.Decay = Color3.fromRGB(110, 118, 128)
	atmosphere.Glare = 0.10
	atmosphere.Haze = 2.5

	local colorCorrection = Lighting:FindFirstChild("GrittyColorCorrection")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "GrittyColorCorrection"
		colorCorrection.Parent = Lighting
	end
	colorCorrection.Brightness = -0.01
	colorCorrection.Contrast = 0.08
	colorCorrection.Saturation = -0.15
	colorCorrection.TintColor = Color3.fromRGB(235, 238, 242)

	local bloom = Lighting:FindFirstChild("GrittyBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "GrittyBloom"
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 0.80
end

-- Builds tangible, realistic everyday urban street assets for in-field gameplay mechanics
-- (Stacked tire crash cushions for corner bumpers, heavy loading dock kickers for elevating ramps,
-- and suspended target signs with hanging chains for ceiling markers)
local function buildEverydayStreetFieldAssets(arena: Model, profile: Types.ArenaGeometryProfile, includeOverlayInA: boolean)
	local vid = profile.variantId
	if vid == "A" and not includeOverlayInA then
		return
	end

	local root = Instance.new("Folder")
	root.Name = "EverydayStreetFieldAssets"
	root.Parent = arena

	local function makeVisualPart(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Name = props.Name or "FieldAssetPart"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Material = props.Material or Enum.Material.Metal
		p.Color = props.Color or Color3.fromRGB(150, 150, 150)
		p.Size = props.Size or Vector3.new(1, 1, 1)
		if props.CFrame then
			p.CFrame = props.CFrame
		elseif props.Position then
			p.Position = props.Position
		end
		if props.Shape then
			p.Shape = props.Shape
		end
		if props.Transparency then
			p.Transparency = props.Transparency
		end
		p.Parent = props.Parent or root
		return p
	end

	-- 1. Tangible Corner Bumpers: Recycled Tire Wall & Heavy Impact Crash Cushion
	for _, suffix in ipairs({ "NW", "NE", "SW", "SE" }) do
		local bumper = arena:FindFirstChild("PinballBumper_" .. suffix)
		if bumper and bumper:IsA("BasePart") then
			bumper.Transparency = 1.0 -- Hide flat collision box while retaining CanCollide and attributes
			local cf = bumper.CFrame
			local normal = bumper:GetAttribute("SurfaceNormal") or cf.LookVector
			local tangent = Vector3.new(0, 1, 0):Cross(normal).Unit
			local wallCenter = cf.Position
			local length = bumper.Size.X

			local bumperFolder = Instance.new("Folder")
			bumperFolder.Name = "TireBumper_" .. suffix
			bumperFolder.Parent = root

			local length = 24.0 -- Inset to strictly fit within |X| <= 79.8, |Z| <= 119.8, |X|+|Z| <= 179.8
			local shiftInward = normal * 0.85
			local bumperInwardCenter = wallCenter + shiftInward

			-- Backing Steel Plate against fence
			makeVisualPart({
				Name = "BackingPlate",
				Parent = bumperFolder,
				Size = Vector3.new(length, 15.5, 0.4),
				CFrame = CFrame.lookAt(bumperInwardCenter, bumperInwardCenter + normal),
				Material = Enum.Material.CorrodedMetal,
				Color = Color3.fromRGB(35, 38, 42),
			})

			-- 5 columns x 2 rows of stacked recycled rubber tires (10 tires per corner)
			local colOffsets = { -7.6, -3.8, 0, 3.8, 7.6 }
			local rowY = { 4.0, 9.8 }
			local rotCF = CFrame.lookAt(Vector3.zero, normal) * CFrame.Angles(0, math.rad(90), 0)

			for rowIdx, yPos in ipairs(rowY) do
				for colIdx, xOff in ipairs(colOffsets) do
					local tireCenter = bumperInwardCenter + (tangent * xOff)
					tireCenter = Vector3.new(tireCenter.X, yPos, tireCenter.Z)

					-- Outer Rubber Tire Body
					makeVisualPart({
						Name = string.format("Tire_R%d_C%d", rowIdx, colIdx),
						Parent = bumperFolder,
						Shape = Enum.PartType.Cylinder,
						Size = Vector3.new(1.3, 3.8, 3.8),
						CFrame = CFrame.new(tireCenter) * rotCF.Rotation,
						Material = Enum.Material.Rubber,
						Color = Color3.fromRGB(25, 27, 30),
					})

					-- Inner Steel Rim / Wheel Hub
					makeVisualPart({
						Name = string.format("Rim_R%d_C%d", rowIdx, colIdx),
						Parent = bumperFolder,
						Shape = Enum.PartType.Cylinder,
						Size = Vector3.new(1.35, 1.9, 1.9),
						CFrame = CFrame.new(tireCenter) * rotCF.Rotation,
						Material = Enum.Material.Metal,
						Color = Color3.fromRGB(115, 120, 125),
					})

					-- Street stencil paint on alternating tires
					if (rowIdx + colIdx) % 2 == 0 then
						local stripePos = tireCenter + (normal * 0.66)
						makeVisualPart({
							Name = string.format("Stripe_R%d_C%d", rowIdx, colIdx),
							Parent = bumperFolder,
							Size = Vector3.new(0.5, 3.8, 0.08),
							CFrame = CFrame.lookAt(stripePos, stripePos + normal),
							Material = Enum.Material.Concrete,
							Color = Color3.fromRGB(205, 160, 40),
						})
					end
				end
			end

			-- Horizontal galvanized steel retention pipes across tire rows (flush against tire faces)
			for _, yPos in ipairs(rowY) do
				local pipePos = Vector3.new(bumperInwardCenter.X, yPos, bumperInwardCenter.Z) + (normal * 0.7)
				makeVisualPart({
					Name = "RetentionPipe_Y" .. math.floor(yPos),
					Parent = bumperFolder,
					Size = Vector3.new(length, 0.45, 0.45),
					CFrame = CFrame.lookAt(pipePos, pipePos + normal),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(55, 60, 66),
				})
			end

			-- Top Industrial Hazard Bumper Cap with safety chevrons (flush on top of bumper, no protrusion)
			local capPos = Vector3.new(bumperInwardCenter.X, 14.8, bumperInwardCenter.Z)
			makeVisualPart({
				Name = "TopHazardCap",
				Parent = bumperFolder,
				Size = Vector3.new(length, 1.4, 0.6),
				CFrame = CFrame.lookAt(capPos, capPos + normal),
				Material = Enum.Material.DiamondPlate,
				Color = Color3.fromRGB(195, 145, 35),
			})
		end
	end

	-- 2. Tangible Elevating Ramps: Industrial Steel Loading Dock Kickers
	for _, rampSide in ipairs({ "Left", "Right" }) do
		local ramp = arena:FindFirstChild("ElevatingRamp_" .. rampSide)
		if ramp and ramp:IsA("BasePart") and ramp.Transparency < 1.0 then
			local xSign = if rampSide == "Left" then -1 else 1
			local rampFolder = Instance.new("Folder")
			rampFolder.Name = "IndustrialRamp_" .. rampSide
			rampFolder.Parent = root

			ramp.Material = Enum.Material.DiamondPlate
			ramp.Color = Color3.fromRGB(48, 52, 56)

			-- Under-truss vertical I-beam support legs along Z (strictly within |X| <= 79.8)
			local legZ = { -25, -15, -5, 5, 15, 25 }
			local legX = xSign * 78.5
			for _, zPos in ipairs(legZ) do
				makeVisualPart({
					Name = "RampLeg_Z" .. zPos,
					Parent = rampFolder,
					Size = Vector3.new(0.5, 4.0, 0.5),
					Position = Vector3.new(legX, 2.0, zPos),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(42, 45, 50),
				})
				makeVisualPart({
					Name = "RampFoot_Z" .. zPos,
					Parent = rampFolder,
					Size = Vector3.new(1.0, 0.2, 1.0),
					Position = Vector3.new(legX, 0.1, zPos),
					Material = Enum.Material.CorrodedMetal,
					Color = Color3.fromRGB(30, 32, 35),
				})
			end

			-- Ramp end triangular gusset plates (North & South ends)
			for _, zSign in ipairs({ -1, 1 }) do
				local zEnd = zSign * 30.0
				makeVisualPart({
					Name = "RampEndPlate_Z" .. zSign,
					Parent = rampFolder,
					Size = Vector3.new(11.0, 3.8, 0.3),
					Position = Vector3.new(xSign * 74.0, 1.9, zEnd),
					Material = Enum.Material.CorrodedMetal,
					Color = Color3.fromRGB(40, 44, 48),
				})
			end

			-- Ramp Outer Safety Wheel Curb along the high side (within |X| <= 79.8)
			makeVisualPart({
				Name = "RampSafetyCurb",
				Parent = rampFolder,
				Size = Vector3.new(0.5, 0.8, 60.0),
				CFrame = ramp.CFrame * CFrame.new(xSign * 5.2, 1.2, 0),
				Material = Enum.Material.DiamondPlate,
				Color = Color3.fromRGB(205, 160, 35),
			})

			-- Ramp Ground Transition Lip along low side (flush to pitch)
			makeVisualPart({
				Name = "RampGroundLip",
				Parent = rampFolder,
				Size = Vector3.new(0.8, 0.15, 60.0),
				Position = Vector3.new(xSign * 68.3, 0.08, 0),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(75, 80, 85),
			})

			-- Stenciled Chevron Launch Arrows on ramp deck
			local arrowZ = { -20, -10, 0, 10, 20 }
			for _, zPos in ipairs(arrowZ) do
				makeVisualPart({
					Name = "RampArrow_Z" .. zPos,
					Parent = rampFolder,
					Size = Vector3.new(4.0, 0.05, 1.2),
					CFrame = ramp.CFrame * CFrame.new(0, 1.03, zPos),
					Material = Enum.Material.Concrete,
					Color = Color3.fromRGB(220, 222, 225),
				})
			end
		end
	end

	-- 3. Tangible Ceiling Rebound Markers: Suspended Overhead Industrial Signboards with Chains
	for _, sideTag in ipairs({ "North", "South" }) do
		local marker = arena:FindFirstChild("CeilingReboundMarker_" .. sideTag)
		if marker and marker:IsA("BasePart") and marker.Transparency < 1.0 then
			marker.Transparency = 1.0 -- Hide flat floating box
			local zSign = if sideTag == "North" then -1 else 1
			local markerZ = zSign * 68.0

			local markerFolder = Instance.new("Folder")
			markerFolder.Name = "SuspendedSign_" .. sideTag
			markerFolder.Parent = root

			-- Heavy Signboard metal face
			makeVisualPart({
				Name = "TargetSign",
				Parent = markerFolder,
				Size = Vector3.new(9.6, 0.3, 9.6),
				Position = Vector3.new(0, 31.7, markerZ),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(38, 42, 48),
			})

			-- Amber/Yellow Hazard Border
			makeVisualPart({
				Name = "TargetBorder",
				Parent = markerFolder,
				Size = Vector3.new(9.2, 0.05, 9.2),
				Position = Vector3.new(0, 31.5, markerZ),
				Material = Enum.Material.Concrete,
				Color = Color3.fromRGB(225, 175, 40),
			})

			-- Inner White Aiming Reticle Circle
			makeVisualPart({
				Name = "TargetReticle",
				Parent = markerFolder,
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.06, 5.0, 5.0),
				CFrame = CFrame.new(0, 31.45, markerZ) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Concrete,
				Color = Color3.fromRGB(240, 242, 245),
			})

			-- Center Red Bullseye
			makeVisualPart({
				Name = "TargetBullseye",
				Parent = markerFolder,
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.08, 1.8, 1.8),
				CFrame = CFrame.new(0, 31.42, markerZ) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Concrete,
				Color = Color3.fromRGB(225, 60, 50),
			})

			-- 4 Corner Suspension Chains to ceiling (Y = 32.0)
			local chainOffsets = {
				Vector3.new(-4.5, 0.15, -4.5),
				Vector3.new(4.5, 0.15, -4.5),
				Vector3.new(-4.5, 0.15, 4.5),
				Vector3.new(4.5, 0.15, 4.5),
			}
			for idx, off in ipairs(chainOffsets) do
				makeVisualPart({
					Name = "SuspensionChain_" .. idx,
					Parent = markerFolder,
					Size = Vector3.new(0.18, 0.5, 0.18),
					Position = Vector3.new(off.X, 31.95, markerZ + off.Z),
					Material = Enum.Material.Metal,
					Color = Color3.fromRGB(60, 65, 70),
				})
			end
		end
	end
end

-- Builds Workspace.HexCageArena from the single ArenaGeometry catalog (T-01)
function CagePhysicsService.BuildCageArena(
	parent: Instance?,
	variantId: Types.CageVariantInput?,
	options: { includeCornerOverlayInA: boolean? }?
): Model
	local targetParent = parent or Workspace
	lowerBaseplateToPreventZFighting(targetParent)

	local vid = normalizeVariantId(variantId)
	activeVariantId = vid
	local profile = CagePhysicsService.GetArenaGeometryProfile(vid)
	local includeOverlayInA = options ~= nil and options.includeCornerOverlayInA == true

	local existing = targetParent:FindFirstChild(ARENA_MODEL_NAME)
	if existing then
		existing:Destroy()
	end

	local arena = Instance.new("Model")
	arena.Name = ARENA_MODEL_NAME
	arena:SetAttribute("CageVariantId", profile.variantId)
	arena:SetAttribute("DisplayName", profile.displayName)
	arena:SetAttribute("WallCount", profile.wallCount)
	arena:SetAttribute("HasChamferedCorners", profile.hasChamferedCorners)
	arena:SetAttribute("HasBeveledRoof", profile.hasBeveledRoof)
	arena:SetAttribute("CeilingHeightY", profile.ceilingHeightY)
	arena:SetAttribute("EaveHeightY", profile.eaveHeightY)
	arena:SetAttribute("ChamferCutStuds", profile.chamferCutStuds)
	arena:SetAttribute("RoofBevelStuds", profile.roofBevelStuds)
	arena:SetAttribute("GoalBackZoneStuds", profile.backGoalAlleyStuds)

	local floorPart: BasePart? = nil

	for _, sDef in ipairs(profile.surfaces) do
		if sDef.kind == "PinballBumper" and vid == "A" and not includeOverlayInA then
			continue
		end
		local part = createSurfaceInstance(sDef, arena, vid == "A" and includeOverlayInA and sDef.kind == "PinballBumper")
		if sDef.surfaceId == "CageFloor" then
			floorPart = part
		end

		-- Clean Variant "A" Visual Dressing: Hide ramps and ceiling rebound markers in 3D scene when not using overlay
		if vid == "A" and not includeOverlayInA then
			if sDef.kind == "ElevatingRamp" then
				part.Transparency = 1.0
				part.CanCollide = false
				part.CanQuery = false
			elseif sDef.kind == "CeilingMarker" then
				part.Transparency = 1.0
				part.CanCollide = false
				part.CanQuery = false
			end
		end

		-- Hide thick 4-stud collider on Wall_West and Wall_East, add thin visual panel inside frame
		if sDef.surfaceId == "Wall_West" or sDef.surfaceId == "Wall_East" then
			part.Transparency = 1.0
			local visualPart = Instance.new("Part")
			visualPart.Name = sDef.surfaceId .. "_Visual"
			local lenZ = if profile.hasChamferedCorners then sDef.size.Z - 1.0 else sDef.size.Z
			visualPart.Size = Vector3.new(0.35, sDef.size.Y, lenZ)
			visualPart.CFrame = CFrame.new(
				sDef.cframe.Position.X + (sDef.normal.X * (sDef.size.X * 0.5 - 0.175)),
				sDef.cframe.Position.Y,
				sDef.cframe.Position.Z
			)
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.CanQuery = false
			visualPart.CanTouch = false
			visualPart.Color = sDef.color
			visualPart.Material = sDef.material
			visualPart.Transparency = sDef.transparency
			visualPart.TopSurface = Enum.SurfaceType.Smooth
			visualPart.BottomSurface = Enum.SurfaceType.Smooth
			visualPart.Parent = arena
		end

		-- Hide thick 4-stud collider on CornerWall_*, add thin visual diamond plate panel inside frame
		if sDef.kind == "CornerWall" then
			part.Transparency = 1.0
			local visualPart = Instance.new("Part")
			visualPart.Name = sDef.surfaceId .. "_Visual"
			visualPart.Size = Vector3.new(sDef.size.X - 1.0, sDef.size.Y, 0.35)
			visualPart.CFrame = sDef.cframe * CFrame.new(0, 0, -((sDef.size.Z * 0.5) - 0.175))
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.CanQuery = false
			visualPart.CanTouch = false
			visualPart.Color = sDef.color
			visualPart.Material = sDef.material
			visualPart.Transparency = sDef.transparency
			visualPart.TopSurface = Enum.SurfaceType.Smooth
			visualPart.BottomSurface = Enum.SurfaceType.Smooth
			visualPart.Parent = arena
		end

		-- End Wall segments Left/Right: thin visual panel inside frame
		if string.find(sDef.surfaceId, "Wall_North_") or string.find(sDef.surfaceId, "Wall_South_") then
			part.Transparency = 1.0
			local visualPart = Instance.new("Part")
			visualPart.Name = sDef.surfaceId .. "_Visual"
			visualPart.Size = Vector3.new(sDef.size.X, sDef.size.Y, 0.35)
			visualPart.CFrame = CFrame.new(
				sDef.cframe.Position.X,
				sDef.cframe.Position.Y,
				sDef.cframe.Position.Z + (sDef.normal.Z * (sDef.size.Z * 0.5 - 0.175))
			)
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.CanQuery = false
			visualPart.CanTouch = false
			visualPart.Color = sDef.color
			visualPart.Material = sDef.material
			visualPart.Transparency = sDef.transparency
			visualPart.TopSurface = Enum.SurfaceType.Smooth
			visualPart.BottomSurface = Enum.SurfaceType.Smooth
			visualPart.Parent = arena
		end

		-- Open goal mouth on North & South end walls in 3D Scene
		if sDef.surfaceId == "Wall_North" or sDef.surfaceId == "Wall_South" then
			part.Transparency = 1.0
			part.CanCollide = false
			part.CanQuery = false
		end

		-- Hide physical GoalPocket colliders in 3D scene (net visuals handled in buildGoalPostsAndTransom)
		if sDef.kind == "GoalPocket" then
			part.Transparency = 1.0
		end

		-- Visual Ceiling for Chamfered Variants (B & C)
		-- Constructs flat roof visual covering the exact octagon footprint with zero gaps and zero protrusions (F-10)
		if sDef.surfaceId == "CageCeiling" then
			if profile.hasChamferedCorners then
				part.Transparency = 1.0
				local ceilY = profile.ceilingHeightY + 0.175
				local halfRoofX = if profile.hasBeveledRoof then (profile.halfWidthX - profile.roofBevelStuds) else profile.halfWidthX
				local halfRoofZ = if profile.hasBeveledRoof then (profile.halfLengthZ - profile.roofBevelStuds) else profile.halfLengthZ
				local cutStuds: number
				if profile.hasBeveledRoof then
					-- Corner bevel catalog 45 deg uses normal inset bevelStuds:
					-- Diagonal boundary at Y = 32 is |X| + |Z| = (halfWidthX + halfLengthZ - chamferCutStuds) - (roofBevelStuds * SQRT2)
					-- = 180 - 8 * sqrt(2) ≈ 168.6862915
					-- Intersecting with Z = halfRoofZ (112) gives innerRoofX = (180 - 8 * sqrt(2)) - 112 = 68 - 8 * sqrt(2) ≈ 56.6862915
					-- Therefore corner cutStuds = halfRoofX - innerRoofX = 72 - (68 - 8 * sqrt(2)) = 4 + 8 * sqrt(2) ≈ 15.3137085
					local baseChamferCut = if profile.chamferCutStuds > 0 then profile.chamferCutStuds else CHAMFER_CUT_STUDS
					local diagLimit = (profile.halfWidthX + profile.halfLengthZ - baseChamferCut) - (profile.roofBevelStuds * SQRT2)
					cutStuds = (halfRoofX + halfRoofZ) - diagLimit
				else
					cutStuds = if profile.chamferCutStuds > 0 then profile.chamferCutStuds else CHAMFER_CUT_STUDS
				end
				local innerRoofX = halfRoofX - cutStuds
				local innerRoofZ = halfRoofZ - cutStuds

				-- 1. Center strip: [-innerRoofX, innerRoofX] x [-halfRoofZ, halfRoofZ]
				makeVisualPart(arena, "VisualCeiling_Center", Vector3.new(innerRoofX * 2.0, 0.35, halfRoofZ * 2.0), CFrame.new(0, ceilY, 0), sDef.color, sDef.material, sDef.transparency)

				-- 2. Side strips (West and East): width = cutStuds, length = innerRoofZ * 2.0
				local sideCenterX = innerRoofX + (cutStuds * 0.5)
				makeVisualPart(arena, "VisualCeiling_West", Vector3.new(cutStuds, 0.35, innerRoofZ * 2.0), CFrame.new(-sideCenterX, ceilY, 0), sDef.color, sDef.material, sDef.transparency)
				makeVisualPart(arena, "VisualCeiling_East", Vector3.new(cutStuds, 0.35, innerRoofZ * 2.0), CFrame.new(sideCenterX, ceilY, 0), sDef.color, sDef.material, sDef.transparency)

				-- 3. Corner wedges (NW, NE, SW, SE) closing corners perfectly with zero gaps and zero protrusions
				for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
					local xs, zs = c[1], c[2]
					local vX = Vector3.new(0, xs * zs, 0)
					local vY = Vector3.new(xs, 0, 0)
					local vZ = Vector3.new(0, 0, -zs)
					local center = Vector3.new(xs * (innerRoofX + cutStuds * 0.5), ceilY, zs * (innerRoofZ + cutStuds * 0.5))
					local cornerCF = CFrame.fromMatrix(center, vX, vY, vZ)
					makeVisualWedge(arena, string.format("VisualCeiling_Corner_%d_%d", xs, zs), Vector3.new(0.35, cutStuds, cutStuds), cornerCF, sDef.color, sDef.material, sDef.transparency)
				end
			end
		end

		-- Physical RoofBevel collider hidden, clean visual bevel panel created
		if sDef.kind == "RoofBevel" then
			part.Transparency = 1.0
			local isCorner = not (string.find(sDef.surfaceId, "RoofBevel_North") or string.find(sDef.surfaceId, "RoofBevel_South") or string.find(sDef.surfaceId, "RoofBevel_West") or string.find(sDef.surfaceId, "RoofBevel_East"))
			local width = sDef.size.X
			if string.find(sDef.surfaceId, "RoofBevel_North") or string.find(sDef.surfaceId, "RoofBevel_South") then
				width = sDef.size.X - 16.0 -- 104.0
			elseif string.find(sDef.surfaceId, "RoofBevel_West") or string.find(sDef.surfaceId, "RoofBevel_East") then
				width = sDef.size.X - 16.0 -- 184.0
			else
				local cutStuds = if profile.chamferCutStuds > 0 then profile.chamferCutStuds else CHAMFER_CUT_STUDS
				width = cutStuds * SQRT2
			end
			local visualBevel = Instance.new("Part")
			visualBevel.Name = sDef.surfaceId .. "_Visual"
			visualBevel.Size = Vector3.new(width, sDef.size.Y, 0.35)
			visualBevel.CFrame = sDef.cframe * CFrame.new(0, 0, -((sDef.size.Z * 0.5) - 0.175))
			visualBevel.Anchored = true
			visualBevel.CanCollide = false
			visualBevel.CanQuery = false
			visualBevel.CanTouch = false
			visualBevel.Color = sDef.color
			visualBevel.Material = sDef.material
			visualBevel.Transparency = sDef.transparency
			visualBevel.TopSurface = Enum.SurfaceType.Smooth
			visualBevel.BottomSurface = Enum.SurfaceType.Smooth
			visualBevel.Parent = arena
		end
	end

	-- Pitch Markings, Goal Nets, Detailed Steel Cage, Urban Backdrop, Everyday Field Assets, and Dusk Lighting
	if floorPart then
		buildPitchMarkings(floorPart, profile)
	end
	buildGoalNets(arena)
	buildDetailedSteelCage(arena, profile)
	buildUrbanBackdrop(arena, profile)
	setupGrittyLighting()
	buildEverydayStreetFieldAssets(arena, profile, includeOverlayInA)

	if floorPart then
		arena.PrimaryPart = floorPart
		arena.WorldPivot = floorPart.CFrame
	end

	arena.Parent = targetParent
	activeArenaModel = arena
	return arena
end

-- Legacy builder entrypoint preserved to route through the same ArenaGeometry catalog
function CagePhysicsService.BuildHexCageArena(parent: Instance?, variantId: Types.CageVariantInput?): Model
	return CagePhysicsService.BuildCageArena(parent, variantId)
end

-- Retires temporary Module 00 bootstrap fixtures ONLY after HexCageArena.CageFloor is verified active;
-- NEVER touches Workspace.Baseplate (T-05), lowers Baseplate to eliminate Z-fighting.
function CagePhysicsService.RetireBootstrapFixtures(targetWorkspace: Instance?): boolean
	local ws = targetWorkspace or Workspace
	lowerBaseplateToPreventZFighting(ws)

	local arena = ws:FindFirstChild(ARENA_MODEL_NAME)
	local cageFloor = if arena then arena:FindFirstChild("CageFloor") else nil
	if not cageFloor or not cageFloor:IsA("BasePart") then
		return false
	end

	local tempFloor = ws:FindFirstChild("BootstrapTestFloor")
	if tempFloor then
		tempFloor:Destroy()
	end

	local tempSpawn = ws:FindFirstChild("BootstrapSpawnLocation")
	if tempSpawn then
		tempSpawn:Destroy()
	end

	return true
end

function CagePhysicsService.GetActiveArena(): Model?
	return activeArenaModel
end

function CagePhysicsService.Init(variantId: Types.CageVariantInput?)
	local resolvedInput: Types.CageVariantInput? = variantId
	if resolvedInput == nil then
		local existingArena = Workspace:FindFirstChild(ARENA_MODEL_NAME)
		local attrVid = if existingArena then existingArena:GetAttribute("CageVariantId") else nil
		if typeof(attrVid) == "string" and attrVid ~= "" then
			resolvedInput = attrVid
		end
	end
	local vid = normalizeVariantId(resolvedInput)
	if isInitialized and activeArenaModel and activeArenaModel.Parent ~= nil then
		if variantId == nil or vid == activeVariantId then
			return
		end
	end
	isInitialized = true
	registerCollisionGroups()
	CagePhysicsService.BuildCageArena(Workspace, vid)
	CagePhysicsService.RetireBootstrapFixtures(Workspace)
end

return table.freeze(CagePhysicsService)
