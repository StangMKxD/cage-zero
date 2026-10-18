--!strict
-- src/server/services/CagePhysicsService.luau
-- Module 01: 5-in-1 Extreme Hex-Cage Arena Builder & Server-Authoritative Rebound Physics
-- Implements R = (V - 2(V.N)N) * e, Pinball Bumpers (e = 1.25), 360 Goal Zone (14 Studs), and Elevating Ramps (25 deg).

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local ARENA_MODEL_NAME = "HexCageArena"
local ARENA_HALF_LENGTH_Z = 120.0
local ARENA_HALF_WIDTH_X = 80.0
local ARENA_CEILING_HEIGHT_Y = 32.0
local STANDARD_WALL_RESTITUTION = 0.88
local PILLAR_RESTITUTION = 1.00
local MAX_REBOUND_SPEED = 180.0
local GOAL_WIDTH_X = 24.0
local GOAL_HEIGHT_Y = 10.0
local GOAL_DEPTH_Z = 6.0
local RAMP_TRIGGER_MIN_ABS_X = 66.0

local activeArenaModel: Model? = nil
local isInitialized = false

local CagePhysicsService = {
	ARENA_HALF_LENGTH_Z = ARENA_HALF_LENGTH_Z,
	ARENA_HALF_WIDTH_X = ARENA_HALF_WIDTH_X,
	ARENA_CEILING_HEIGHT_Y = ARENA_CEILING_HEIGHT_Y,
	STANDARD_WALL_RESTITUTION = STANDARD_WALL_RESTITUTION,
	PILLAR_RESTITUTION = PILLAR_RESTITUTION,
	MAX_REBOUND_SPEED = MAX_REBOUND_SPEED,
}

local function registerCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("CageWalls")
		PhysicsService:RegisterCollisionGroup("CageBall")
		PhysicsService:RegisterCollisionGroup("CagePlayers")
	end)
end

local function createArenaPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = true
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function CagePhysicsService.ComputeReboundVelocity(
	incidentVelocity: Vector3,
	surfaceNormal: Vector3,
	restitution: number
): Vector3
	if surfaceNormal.Magnitude < 1e-5 then
		return incidentVelocity
	end
	local n = surfaceNormal.Unit
	local dotProduct = incidentVelocity:Dot(n)
	-- Only reflect if moving into the surface (dotProduct < 0)
	local reflected = if dotProduct < 0
		then (incidentVelocity - (2.0 * dotProduct * n)) * restitution
		else incidentVelocity * restitution

	if reflected.Magnitude > MAX_REBOUND_SPEED then
		reflected = reflected.Unit * MAX_REBOUND_SPEED
	end
	return reflected
end

function CagePhysicsService.ApplyRampImpulse(velocity: Vector3, isOnRamp: boolean): Vector3
	if not isOnRamp then
		return velocity
	end
	local horizontalVel = Vector3.new(velocity.X, 0, velocity.Z)
	local horizontalSpeed = horizontalVel.Magnitude
	local rampRad = math.rad(Constants.ELEVATING_RAMP_ANGLE_DEG)
	local upwardImpulse = (math.sin(rampRad) * horizontalSpeed) + 38.0
	local boostedVel = Vector3.new(velocity.X, math.max(velocity.Y, upwardImpulse), velocity.Z)
	if boostedVel.Magnitude > MAX_REBOUND_SPEED then
		boostedVel = boostedVel.Unit * MAX_REBOUND_SPEED
	end
	return boostedVel
end

function CagePhysicsService.IsPositionOnElevatingRamp(position: Vector3): boolean
	return math.abs(position.X) >= RAMP_TRIGGER_MIN_ABS_X
		and math.abs(position.Z) <= 75.0
		and position.Y <= 8.0
end

function CagePhysicsService.IsBehindGoal360Zone(position: Vector3): boolean
	local northGoalZ = -(ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS) -- -106
	local southGoalZ = ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS -- +106
	local behindNorth = position.Z < northGoalZ and position.Z >= -ARENA_HALF_LENGTH_Z
	local behindSouth = position.Z > southGoalZ and position.Z <= ARENA_HALF_LENGTH_Z
	return behindNorth or behindSouth
end

function CagePhysicsService.CheckGoalScored(position: Vector3, gameMode: string?): ("North" | "South" | "Center")?
	local northGoalZ = -(ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS) -- -106
	local southGoalZ = ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS -- +106

	if gameMode == "1v1v1" then
		local distFromCenter = (position - Vector3.new(0, GOAL_HEIGHT_Y * 0.5, 0)).Magnitude
		if distFromCenter <= 8.0 and position.Y <= GOAL_HEIGHT_Y then
			return "Center"
		end
	end

	if math.abs(position.X) <= (GOAL_WIDTH_X * 0.5) and position.Y >= 0 and position.Y <= GOAL_HEIGHT_Y then
		if math.abs(position.Z - northGoalZ) <= (GOAL_DEPTH_Z * 0.5) then
			return "North"
		elseif math.abs(position.Z - southGoalZ) <= (GOAL_DEPTH_Z * 0.5) then
			return "South"
		end
	end
	return nil
end

-- Continuous Server-Authoritative Boundary Step (Zero Clipping Guarantee)
function CagePhysicsService.StepBallCageCollision(
	position: Vector3,
	velocity: Vector3,
	dt: number
): (Vector3, Vector3, string?)
	local nextPos = position + (velocity * dt)
	local nextVel = velocity
	local hitSurfaceTag: string? = nil

	-- Floor rebound
	if nextPos.Y < 1.25 then
		nextPos = Vector3.new(nextPos.X, 1.25, nextPos.Z)
		if nextVel.Y < 0 then
			nextVel = CagePhysicsService.ComputeReboundVelocity(nextVel, Vector3.new(0, 1, 0), 0.75)
			hitSurfaceTag = "CageFloor"
		end
	end

	-- Ceiling rebound (Hex-Cage 3D Ceiling at Y = 32)
	if nextPos.Y > (ARENA_CEILING_HEIGHT_Y - 1.25) then
		nextPos = Vector3.new(nextPos.X, ARENA_CEILING_HEIGHT_Y - 1.25, nextPos.Z)
		if nextVel.Y > 0 then
			nextVel = CagePhysicsService.ComputeReboundVelocity(
				nextVel,
				Vector3.new(0, -1, 0),
				STANDARD_WALL_RESTITUTION
			)
			hitSurfaceTag = "CageCeiling"
		end
	end

	-- Corner Pinball Bumpers (4 diagonal chamfer corners: |X| + 0.5*|Z| > 118)
	local cornerMetric = math.abs(nextPos.X) + (0.5 * math.abs(nextPos.Z))
	if cornerMetric > 118.0 and math.abs(nextPos.X) > 52.0 and math.abs(nextPos.Z) > 78.0 then
		local signX = if nextPos.X >= 0 then -1 else 1
		local signZ = if nextPos.Z >= 0 then -1 else 1
		local cornerNormal = Vector3.new(signX, 0, signZ * 0.5).Unit
		nextVel = CagePhysicsService.ComputeReboundVelocity(
			nextVel,
			cornerNormal,
			Constants.BUMPER_RESTITUTION
		)
		local pullback = cornerMetric - 118.0
		nextPos = nextPos + (cornerNormal * pullback)
		hitSurfaceTag = "PinballBumper"
	end

	-- Side Hex Walls (X = -80 and X = +80)
	if math.abs(nextPos.X) > (ARENA_HALF_WIDTH_X - 1.25) then
		local signX = if nextPos.X >= 0 then 1 else -1
		nextPos = Vector3.new(signX * (ARENA_HALF_WIDTH_X - 1.25), nextPos.Y, nextPos.Z)
		local normal = Vector3.new(-signX, 0, 0)
		nextVel = CagePhysicsService.ComputeReboundVelocity(nextVel, normal, STANDARD_WALL_RESTITUTION)
		hitSurfaceTag = "HexWallSide"
	end

	-- Back Hex Walls behind 360 Goal Zones (Z = -120 and Z = +120)
	if math.abs(nextPos.Z) > (ARENA_HALF_LENGTH_Z - 1.25) then
		local signZ = if nextPos.Z >= 0 then 1 else -1
		nextPos = Vector3.new(nextPos.X, nextPos.Y, signZ * (ARENA_HALF_LENGTH_Z - 1.25))
		local normal = Vector3.new(0, 0, -signZ)
		nextVel = CagePhysicsService.ComputeReboundVelocity(nextVel, normal, STANDARD_WALL_RESTITUTION)
		hitSurfaceTag = "HexWallBack"
	end

	return nextPos, nextVel, hitSurfaceTag
end

function CagePhysicsService.BuildHexCageArena(parent: Instance?): Model
	local targetParent = parent or Workspace
	local existing = targetParent:FindFirstChild(ARENA_MODEL_NAME)
	if existing and existing:IsA("Model") then
		activeArenaModel = existing
		return existing
	end

	local arena = Instance.new("Model")
	arena.Name = ARENA_MODEL_NAME

	-- 1. CageFloor
	local floor = createArenaPart(
		"CageFloor",
		Vector3.new(ARENA_HALF_WIDTH_X * 2, 2, ARENA_HALF_LENGTH_Z * 2),
		CFrame.new(0, -1, 0),
		Color3.fromRGB(32, 36, 44),
		Enum.Material.Concrete,
		0,
		arena
	)
	floor:SetAttribute("Restitution", 0.75)
	floor:SetAttribute("SurfaceNormal", Vector3.new(0, 1, 0))

	-- 2. CageCeiling (3D Rebound Mesh Ceiling)
	local ceiling = createArenaPart(
		"CageCeiling",
		Vector3.new(ARENA_HALF_WIDTH_X * 2, 1, ARENA_HALF_LENGTH_Z * 2),
		CFrame.new(0, ARENA_CEILING_HEIGHT_Y, 0),
		Color3.fromRGB(20, 25, 35),
		Enum.Material.Fabric,
		0.55,
		arena
	)
	ceiling:SetAttribute("Restitution", STANDARD_WALL_RESTITUTION)
	ceiling:SetAttribute("SurfaceNormal", Vector3.new(0, -1, 0))
	ceiling:SetAttribute("IsCageBoundary", true)

	-- 3. Six Hex-Cage Walls (HexWall_1 to HexWall_6)
	local wallDefs = {
		{
			name = "HexWall_1",
			size = Vector3.new(2, ARENA_CEILING_HEIGHT_Y, 156),
			cf = CFrame.new(-ARENA_HALF_WIDTH_X, ARENA_CEILING_HEIGHT_Y * 0.5, 0),
			normal = Vector3.new(1, 0, 0),
		},
		{
			name = "HexWall_2",
			size = Vector3.new(2, ARENA_CEILING_HEIGHT_Y, 156),
			cf = CFrame.new(ARENA_HALF_WIDTH_X, ARENA_CEILING_HEIGHT_Y * 0.5, 0),
			normal = Vector3.new(-1, 0, 0),
		},
		{
			name = "HexWall_3",
			size = Vector3.new(104, ARENA_CEILING_HEIGHT_Y, 2),
			cf = CFrame.new(0, ARENA_CEILING_HEIGHT_Y * 0.5, -ARENA_HALF_LENGTH_Z),
			normal = Vector3.new(0, 0, 1),
		},
		{
			name = "HexWall_4",
			size = Vector3.new(104, ARENA_CEILING_HEIGHT_Y, 2),
			cf = CFrame.new(0, ARENA_CEILING_HEIGHT_Y * 0.5, ARENA_HALF_LENGTH_Z),
			normal = Vector3.new(0, 0, -1),
		},
		{
			name = "HexWall_5",
			size = Vector3.new(2, ARENA_CEILING_HEIGHT_Y, 50),
			cf = CFrame.new(-66, ARENA_CEILING_HEIGHT_Y * 0.5, -99) * CFrame.Angles(0, math.rad(32), 0),
			normal = Vector3.new(0.85, 0, 0.52).Unit,
		},
		{
			name = "HexWall_6",
			size = Vector3.new(2, ARENA_CEILING_HEIGHT_Y, 50),
			cf = CFrame.new(66, ARENA_CEILING_HEIGHT_Y * 0.5, 99) * CFrame.Angles(0, math.rad(32), 0),
			normal = Vector3.new(-0.85, 0, -0.52).Unit,
		},
	}

	for _, wDef in ipairs(wallDefs) do
		local wall = createArenaPart(
			wDef.name,
			wDef.size,
			wDef.cf,
			Color3.fromRGB(45, 55, 72),
			Enum.Material.DiamondPlate,
			0.35,
			arena
		)
		wall:SetAttribute("Restitution", STANDARD_WALL_RESTITUTION)
		wall:SetAttribute("SurfaceNormal", wDef.normal)
		wall:SetAttribute("IsCageBoundary", true)
	end

	-- 4. Four Pinball Bumpers (Restitution = 1.25)
	local bumperPositions = {
		{ pos = Vector3.new(-64, 6, -98), normal = Vector3.new(1, 0, 0.5).Unit },
		{ pos = Vector3.new(64, 6, -98), normal = Vector3.new(-1, 0, 0.5).Unit },
		{ pos = Vector3.new(-64, 6, 98), normal = Vector3.new(1, 0, -0.5).Unit },
		{ pos = Vector3.new(64, 6, 98), normal = Vector3.new(-1, 0, -0.5).Unit },
	}
	for idx, bDef in ipairs(bumperPositions) do
		local bumper = createArenaPart(
			"PinballBumper_" .. tostring(idx),
			Vector3.new(18, 12, 3),
			CFrame.lookAt(bDef.pos, bDef.pos + bDef.normal),
			Color3.fromRGB(255, 170, 0),
			Enum.Material.Neon,
			0.1,
			arena
		)
		bumper:SetAttribute("Restitution", Constants.BUMPER_RESTITUTION)
		bumper:SetAttribute("SurfaceNormal", bDef.normal)
		bumper:SetAttribute("IsPinballBumper", true)
	end

	-- 5. Six Glowing Rebound Markers (ReboundMarker_1 to ReboundMarker_6)
	local markerPositions = {
		Vector3.new(-63, 10, -96),
		Vector3.new(63, 10, -96),
		Vector3.new(-63, 10, 96),
		Vector3.new(63, 10, 96),
		Vector3.new(0, ARENA_CEILING_HEIGHT_Y - 0.6, -68),
		Vector3.new(0, ARENA_CEILING_HEIGHT_Y - 0.6, 68),
	}
	for idx, mPos in ipairs(markerPositions) do
		local marker = createArenaPart(
			"ReboundMarker_" .. tostring(idx),
			Vector3.new(6, 6, 0.5),
			CFrame.new(mPos),
			Color3.fromRGB(0, 230, 255),
			Enum.Material.Neon,
			0.15,
			arena
		)
		marker.CanCollide = false
		marker:SetAttribute("IsReboundMarker", true)
	end

	-- 6. 360° Goal Zones (Goal_North at Z = -106, Goal_South at Z = +106, 14 Studs from back wall)
	local northGoalZ = -(ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS)
	local southGoalZ = ARENA_HALF_LENGTH_Z - Constants.GOAL_BACK_ZONE_STUDS

	local goalNorth = createArenaPart(
		"Goal_North",
		Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
		CFrame.new(0, GOAL_HEIGHT_Y * 0.5, northGoalZ),
		Color3.fromRGB(0, 200, 255),
		Enum.Material.Neon,
		0.4,
		arena
	)
	goalNorth:SetAttribute("GoalSide", "North")
	goalNorth:SetAttribute("BackZoneDepthStuds", Constants.GOAL_BACK_ZONE_STUDS)
	goalNorth:SetAttribute("IsGoalFrame", true)

	local goalSouth = createArenaPart(
		"Goal_South",
		Vector3.new(GOAL_WIDTH_X, GOAL_HEIGHT_Y, GOAL_DEPTH_Z),
		CFrame.new(0, GOAL_HEIGHT_Y * 0.5, southGoalZ),
		Color3.fromRGB(255, 80, 120),
		Enum.Material.Neon,
		0.4,
		arena
	)
	goalSouth:SetAttribute("GoalSide", "South")
	goalSouth:SetAttribute("BackZoneDepthStuds", Constants.GOAL_BACK_ZONE_STUDS)
	goalSouth:SetAttribute("IsGoalFrame", true)

	-- 7. Elevating Ramps (Left at X = -72, Right at X = +72, angled 25 degrees)
	local rampAngleRad = math.rad(Constants.ELEVATING_RAMP_ANGLE_DEG)
	local rampLeft = createArenaPart(
		"ElevatingRamp_Left",
		Vector3.new(12, 2, 90),
		CFrame.new(-72, 1.5, 0) * CFrame.Angles(0, 0, -rampAngleRad),
		Color3.fromRGB(90, 220, 140),
		Enum.Material.Neon,
		0.25,
		arena
	)
	rampLeft:SetAttribute("ElevationAngleDeg", Constants.ELEVATING_RAMP_ANGLE_DEG)
	rampLeft:SetAttribute("IsElevatingRamp", true)

	local rampRight = createArenaPart(
		"ElevatingRamp_Right",
		Vector3.new(12, 2, 90),
		CFrame.new(72, 1.5, 0) * CFrame.Angles(0, 0, rampAngleRad),
		Color3.fromRGB(90, 220, 140),
		Enum.Material.Neon,
		0.25,
		arena
	)
	rampRight:SetAttribute("ElevationAngleDeg", Constants.ELEVATING_RAMP_ANGLE_DEG)
	rampRight:SetAttribute("IsElevatingRamp", true)

	arena.PrimaryPart = floor
	arena.Parent = targetParent
	activeArenaModel = arena
	return arena
end

function CagePhysicsService.GetActiveArena(): Model?
	return activeArenaModel
end

function CagePhysicsService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	registerCollisionGroups()
	CagePhysicsService.BuildHexCageArena(Workspace)
end

return table.freeze(CagePhysicsService)
