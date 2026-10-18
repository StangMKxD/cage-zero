--!strict
-- src/server/services/EventManagerService.luau
-- Module 05: Server-Authoritative Dynamic Match Event Scheduler & Pillar/Pedestrian Rebound Collisions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local EventConfigs = require(Shared:WaitForChild("configs"):WaitForChild("EventConfigs"))

local Services = script.Parent
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))

local activeEventType: Types.MatchEventType? = nil
local activeEventState: Types.MatchEventState = "Ended"
local activeEventStartedAt = 0.0
local activePillarPositions: { Vector3 } = {}
local spawnedPillarParts: { Part } = {}
local isInitialized = false

local EventManagerService = {}

local function clearSpawnedPillars()
	for _, p in ipairs(spawnedPillarParts) do
		if p.Parent ~= nil then
			p:Destroy()
		end
	end
	table.clear(spawnedPillarParts)
	table.clear(activePillarPositions)
end

local function spawnConcretePillars(positions: { Vector3 })
	clearSpawnedPillars()
	local arena = CagePhysicsService.GetActiveArena() or Workspace
	for idx, pos in ipairs(positions) do
		local pillar = Instance.new("Part")
		pillar.Name = "ReboundPillar_" .. tostring(idx)
		pillar.Size = EventConfigs.PillarSize
		pillar.CFrame = CFrame.new(pos)
		pillar.Anchored = true
		pillar.CanCollide = true
		pillar.Material = Enum.Material.Concrete
		pillar.Color = Color3.fromRGB(120, 128, 140)
		pillar:SetAttribute("IsReboundPillar", true)
		pillar:SetAttribute("Restitution", EventConfigs.PillarRestitution)
		pillar.Parent = arena
		table.insert(spawnedPillarParts, pillar)
		table.insert(activePillarPositions, pos)
	end
end

local function broadcastEvent(eventType: Types.MatchEventType, state: Types.MatchEventState, payload: any)
	local remote = Network.GetRemoteEvent(Network.Names.MatchEventBroadcast)
	remote:FireAllClients(eventType, state, payload)
end

function EventManagerService.GetActiveEvent(): (Types.MatchEventType?, Types.MatchEventState, number)
	return activeEventType, activeEventState, activeEventStartedAt
end

function EventManagerService.EndCurrentEvent()
	if activeEventType == nil or activeEventState == "Ended" then
		return
	end
	local endedType = activeEventType
	clearSpawnedPillars()
	activeEventState = "Ended"
	activeEventType = nil
	broadcastEvent(endedType, "Ended", { restoredAt = os.clock() })
end

function EventManagerService.TriggerEvent(eventType: Types.MatchEventType, skipWarningDelayForTest: boolean?)
	if EventConfigs.Definitions[eventType] == nil then
		return false
	end

	EventManagerService.EndCurrentEvent()
	activeEventType = eventType
	activeEventState = "Warning"

	local chosenPillars = EventConfigs.StrategicPillarSets[1]
	local warningPayload = {
		eventType = eventType,
		warningDurationSec = EventConfigs.PillarWarningLeadSec,
		pillarPositions = if eventType == "PillarLockdown" then chosenPillars else nil,
	}
	broadcastEvent(eventType, "Warning", warningPayload)

	local function activateNow()
		if activeEventType ~= eventType then
			return
		end
		activeEventState = "Active"
		activeEventStartedAt = os.clock()

		if eventType == "PillarLockdown" then
			spawnConcretePillars(chosenPillars)
		end

		broadcastEvent(eventType, "Active", {
			eventType = eventType,
			startedAt = activeEventStartedAt,
			durationSec = EventConfigs.DurationSec,
			pillarPositions = if eventType == "PillarLockdown" then chosenPillars else nil,
			pedestrianTrackCount = if eventType == "FavelaAlley" then #EventConfigs.FavelaPedestrianTracks else 0,
		})
	end

	if skipWarningDelayForTest then
		activateNow()
	else
		task.delay(EventConfigs.PillarWarningLeadSec, activateNow)
	end

	return true
end

-- Checks ball collision against active PillarLockdown pillars (e = 1.00) or FavelaAlley pedestrians (e = 1.00)
function EventManagerService.StepDynamicObstacleCollision(
	ballPos: Vector3,
	ballVel: Vector3,
	elapsedOverrideSec: number?
): (Vector3, Vector3, boolean)
	if activeEventState ~= "Active" or activeEventType == nil then
		return ballPos, ballVel, false
	end

	if activeEventType == "PillarLockdown" then
		local halfRadius = (EventConfigs.PillarSize.X * 0.5) + 1.25
		for _, pPos in ipairs(activePillarPositions) do
			local deltaXZ = Vector3.new(ballPos.X - pPos.X, 0, ballPos.Z - pPos.Z)
			if deltaXZ.Magnitude <= halfRadius and ballPos.Y <= EventConfigs.PillarSize.Y then
				local normal = if deltaXZ.Magnitude > 1e-3 then deltaXZ.Unit else Vector3.new(0, 0, 1)
				local reflected = CagePhysicsService.ComputeReboundVelocity(
					ballVel,
					normal,
					EventConfigs.PillarRestitution
				)
				local pushedPos = Vector3.new(pPos.X, ballPos.Y, pPos.Z) + (normal * (halfRadius + 0.1))
				return pushedPos, reflected, true
			end
		end
	elseif activeEventType == "FavelaAlley" then
		local elapsed = if elapsedOverrideSec ~= nil
			then elapsedOverrideSec
			else math.max(0.0, os.clock() - activeEventStartedAt)
		for idx, track in ipairs(EventConfigs.FavelaPedestrianTracks) do
			local npcPos = EventConfigs.ComputePedestrianPosition(idx, elapsed)
			local deltaXZ = Vector3.new(ballPos.X - npcPos.X, 0, ballPos.Z - npcPos.Z)
			if deltaXZ.Magnitude <= track.hitboxRadius and ballPos.Y <= 7.0 then
				local normal = if deltaXZ.Magnitude > 1e-3 then deltaXZ.Unit else Vector3.new(0, 0, 1)
				local reflected = CagePhysicsService.ComputeReboundVelocity(ballVel, normal, track.restitution)
				local pushedPos = Vector3.new(npcPos.X, ballPos.Y, npcPos.Z) + (normal * (track.hitboxRadius + 0.1))
				return pushedPos, reflected, true
			end
		end
	end

	return ballPos, ballVel, false
end

function EventManagerService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
end

return table.freeze(EventManagerService)
