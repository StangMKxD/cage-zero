--!strict
-- src/client/controllers/EventVFXController.luau
-- Module 05: Client VFX for PillarLockdown (1.5s warning rings), BlackoutVoid (walls hidden, goals/ball/players highlighted),
-- and FavelaAlley (Server-synced Low-Poly pedestrians).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local EventConfigs = require(Shared:WaitForChild("configs"):WaitForChild("EventConfigs"))

local currentEventType: Types.MatchEventType? = nil
local currentEventState: Types.MatchEventState = "Ended"
local favelaStartedClientClock = 0.0
local warningRingParts: { Part } = {}
local pedestrianParts: { Part } = {}
local blackoutHighlights: { Highlight } = {}
local isInitialized = false

local EventVFXController = {}

local function clearWarningRings()
	for _, p in ipairs(warningRingParts) do
		if p.Parent ~= nil then
			p:Destroy()
		end
	end
	table.clear(warningRingParts)
end

local function clearPedestrians()
	for _, p in ipairs(pedestrianParts) do
		if p.Parent ~= nil then
			p:Destroy()
		end
	end
	table.clear(pedestrianParts)
end

local function clearBlackoutVFX()
	for _, h in ipairs(blackoutHighlights) do
		if h.Parent ~= nil then
			h:Destroy()
		end
	end
	table.clear(blackoutHighlights)

	Lighting.FogEnd = 10000
	local arena = Workspace:FindFirstChild("HexCageArena")
	if arena then
		for _, inst in ipairs(arena:GetChildren()) do
			if inst:IsA("BasePart") and inst:GetAttribute("IsCageBoundary") == true then
				inst.Transparency = if inst.Name == "CageCeiling" then 0.55 else 0.35
			elseif inst:IsA("BasePart") and inst:GetAttribute("IsReboundMarker") == true then
				inst.Transparency = 0.15
			end
		end
	end
end

local function applyBlackoutVoidVFX()
	Lighting.FogColor = Color3.new(0, 0, 0)
	Lighting.FogEnd = 90

	local arena = Workspace:FindFirstChild("HexCageArena")
	if arena then
		for _, inst in ipairs(arena:GetChildren()) do
			if inst:IsA("BasePart") and (inst:GetAttribute("IsCageBoundary") == true or inst:GetAttribute("IsReboundMarker") == true) then
				-- Hide boundary meshes visually while keeping CanCollide intact on Server & Client
				inst.Transparency = 1.0
			elseif inst:IsA("BasePart") and inst:GetAttribute("IsGoalFrame") == true then
				local hl = Instance.new("Highlight")
				hl.Name = "BlackoutGoalHighlight"
				hl.FillColor = inst.Color
				hl.OutlineColor = Color3.new(1, 1, 1)
				hl.Parent = inst
				table.insert(blackoutHighlights, hl)
			end
		end
	end

	local ball = Workspace:FindFirstChild("CageMatchBall")
	if ball then
		local hl = Instance.new("Highlight")
		hl.Name = "BlackoutBallHighlight"
		hl.FillColor = Color3.fromRGB(0, 255, 200)
		hl.OutlineColor = Color3.new(1, 1, 1)
		hl.Parent = ball
		table.insert(blackoutHighlights, hl)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local hl = Instance.new("Highlight")
			hl.Name = "BlackoutPlayerHighlight"
			hl.FillColor = Color3.fromRGB(255, 210, 60)
			hl.OutlineColor = Color3.new(1, 1, 1)
			hl.Parent = player.Character
			table.insert(blackoutHighlights, hl)
		end
	end
end

local function spawnWarningRings(positions: { Vector3 })
	clearWarningRings()
	for idx, pos in ipairs(positions) do
		local ring = Instance.new("Part")
		ring.Name = "PillarWarningRing_" .. tostring(idx)
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.4, 8, 8)
		ring.CFrame = CFrame.new(pos.X, 0.25, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 45, 45)
		ring.Parent = Workspace
		table.insert(warningRingParts, ring)
	end
end

local function spawnFavelaPedestrianModels()
	clearPedestrians()
	for idx, track in ipairs(EventConfigs.FavelaPedestrianTracks) do
		local npc = Instance.new("Part")
		npc.Name = track.pedestrianId
		npc.Size = Vector3.new(3, 6, 3)
		npc.Anchored = true
		npc.CanCollide = true
		npc.Material = Enum.Material.SmoothPlastic
		npc.Color = Color3.fromRGB(235, 185, 90)
		npc.CFrame = CFrame.new(track.startPos)
		npc:SetAttribute("IsFavelaPedestrian", true)
		npc.Parent = Workspace
		table.insert(pedestrianParts, npc)
	end
end

function EventVFXController.HandleEventBroadcast(
	eventType: Types.MatchEventType,
	state: Types.MatchEventState,
	payload: any
)
	currentEventType = if state == "Ended" then nil else eventType
	currentEventState = state

	if state == "Ended" then
		clearWarningRings()
		clearPedestrians()
		clearBlackoutVFX()
		return
	end

	if state == "Warning" then
		if eventType == "PillarLockdown" and type(payload) == "table" and type(payload.pillarPositions) == "table" then
			spawnWarningRings(payload.pillarPositions)
		end
		return
	end

	if state == "Active" then
		clearWarningRings()
		if eventType == "BlackoutVoid" then
			applyBlackoutVoidVFX()
		elseif eventType == "FavelaAlley" then
			favelaStartedClientClock = os.clock()
			spawnFavelaPedestrianModels()
		end
	end
end

function EventVFXController.GetCurrentEventState(): (Types.MatchEventType?, Types.MatchEventState)
	return currentEventType, currentEventState
end

function EventVFXController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	RunService.RenderStepped:Connect(function()
		if currentEventType == "FavelaAlley" and currentEventState == "Active" then
			local elapsed = math.max(0.0, os.clock() - favelaStartedClientClock)
			for idx, npcPart in ipairs(pedestrianParts) do
				if npcPart.Parent ~= nil then
					local pos = EventConfigs.ComputePedestrianPosition(idx, elapsed)
					npcPart.CFrame = CFrame.new(pos)
				end
			end
		end
	end)

	local broadcastRemote = Network.GetRemoteEvent(Network.Names.MatchEventBroadcast)
	broadcastRemote.OnClientEvent:Connect(
		function(eventType: Types.MatchEventType, state: Types.MatchEventState, payload: any)
			EventVFXController.HandleEventBroadcast(eventType, state, payload)
		end
	)
end

return table.freeze(EventVFXController)
