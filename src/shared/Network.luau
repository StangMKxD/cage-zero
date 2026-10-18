--!strict
-- src/shared/Network.luau
-- Canonical Network Contract (Section 4.8 of startprojects.md)
-- All 12 RemoteEvents / RemoteFunctions are defined here so Server and Client never drift.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteKind = "RemoteEvent" | "RemoteFunction"
export type RemoteDirection = "ClientToServer" | "ServerToClient"

export type RemoteDefinition = {
	name: string,
	kind: RemoteKind,
	direction: RemoteDirection,
	moduleScope: string,
}

local REMOTE_FOLDER_NAME = "CageZeroRemotes"

local RemoteNames = table.freeze({
	BallActionRequest = "BallActionRequest",
	ParryWindowTrigger = "ParryWindowTrigger",
	ParryAttemptRequest = "ParryAttemptRequest",
	DuelStartEvent = "DuelStartEvent",
	DuelChoiceSubmit = "DuelChoiceSubmit",
	DuelResultEvent = "DuelResultEvent",
	FreeKickStartEvent = "FreeKickStartEvent",
	FreeKickSubmit = "FreeKickSubmit",
	MatchEventBroadcast = "MatchEventBroadcast",
	InventoryEquipRequest = "InventoryEquipRequest",
	SummonRequest = "SummonRequest",
	TradeActionRequest = "TradeActionRequest",
})

local Definitions: { [string]: RemoteDefinition } = table.freeze({
	BallActionRequest = table.freeze({
		name = "BallActionRequest",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 02",
	}),
	ParryWindowTrigger = table.freeze({
		name = "ParryWindowTrigger",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ServerToClient" :: RemoteDirection,
		moduleScope = "Module 02, 07",
	}),
	ParryAttemptRequest = table.freeze({
		name = "ParryAttemptRequest",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 02",
	}),
	DuelStartEvent = table.freeze({
		name = "DuelStartEvent",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ServerToClient" :: RemoteDirection,
		moduleScope = "Module 03, 07",
	}),
	DuelChoiceSubmit = table.freeze({
		name = "DuelChoiceSubmit",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 03, 07",
	}),
	DuelResultEvent = table.freeze({
		name = "DuelResultEvent",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ServerToClient" :: RemoteDirection,
		moduleScope = "Module 03, 04, 07",
	}),
	FreeKickStartEvent = table.freeze({
		name = "FreeKickStartEvent",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ServerToClient" :: RemoteDirection,
		moduleScope = "Module 04, 07",
	}),
	FreeKickSubmit = table.freeze({
		name = "FreeKickSubmit",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 04, 07",
	}),
	MatchEventBroadcast = table.freeze({
		name = "MatchEventBroadcast",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ServerToClient" :: RemoteDirection,
		moduleScope = "Module 05, 07",
	}),
	InventoryEquipRequest = table.freeze({
		name = "InventoryEquipRequest",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 06, 07",
	}),
	SummonRequest = table.freeze({
		name = "SummonRequest",
		kind = "RemoteFunction" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 06, 07",
	}),
	TradeActionRequest = table.freeze({
		name = "TradeActionRequest",
		kind = "RemoteEvent" :: RemoteKind,
		direction = "ClientToServer" :: RemoteDirection,
		moduleScope = "Module 06, 07",
	}),
})

local Network = {
	RemoteFolderName = REMOTE_FOLDER_NAME,
	Names = RemoteNames,
	Definitions = Definitions,
}

local function getOrCreateRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	assert(RunService:IsServer(), "[Network] Remotes folder must be initialized on Server before Client access")
	local folder = Instance.new("Folder")
	folder.Name = REMOTE_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

function Network.InitServer(): Folder
	assert(RunService:IsServer(), "[Network] InitServer can only be called on the Server")
	local folder = getOrCreateRemotesFolder()

	for remoteKey, def in pairs(Definitions) do
		local existing = folder:FindFirstChild(def.name)
		if not existing then
			if def.kind == "RemoteFunction" then
				local rf = Instance.new("RemoteFunction")
				rf.Name = def.name
				rf.Parent = folder
			else
				local re = Instance.new("RemoteEvent")
				re.Name = def.name
				re.Parent = folder
			end
		end
		assert(remoteKey == def.name, "[Network] Remote key mismatch: " .. tostring(remoteKey))
	end

	return folder
end

function Network.GetRemoteEvent(remoteName: string): RemoteEvent
	local def = Definitions[remoteName]
	assert(def ~= nil, "[Network] Unknown Remote name: " .. tostring(remoteName))
	assert(def.kind == "RemoteEvent", "[Network] Remote is not a RemoteEvent: " .. tostring(remoteName))

	local folder = if RunService:IsServer()
		then getOrCreateRemotesFolder()
		else ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 10) :: Folder
	assert(folder ~= nil, "[Network] Remotes folder not found in ReplicatedStorage")

	local remote = if RunService:IsServer()
		then folder:FindFirstChild(def.name)
		else folder:WaitForChild(def.name, 10)
	assert(remote ~= nil and remote:IsA("RemoteEvent"), "[Network] Missing RemoteEvent: " .. def.name)
	return remote
end

function Network.GetRemoteFunction(remoteName: string): RemoteFunction
	local def = Definitions[remoteName]
	assert(def ~= nil, "[Network] Unknown Remote name: " .. tostring(remoteName))
	assert(def.kind == "RemoteFunction", "[Network] Remote is not a RemoteFunction: " .. tostring(remoteName))

	local folder = if RunService:IsServer()
		then getOrCreateRemotesFolder()
		else ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 10) :: Folder
	assert(folder ~= nil, "[Network] Remotes folder not found in ReplicatedStorage")

	local remote = if RunService:IsServer()
		then folder:FindFirstChild(def.name)
		else folder:WaitForChild(def.name, 10)
	assert(remote ~= nil and remote:IsA("RemoteFunction"), "[Network] Missing RemoteFunction: " .. def.name)
	return remote
end

return table.freeze(Network)
