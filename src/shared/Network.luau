--!strict
-- src/shared/Network.luau
-- Canonical Network Contract (Section 4.8 & [FIX-M00-04] Lazy Remote Creation + Payload Validators)

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

local function getOrCreateServerRemote(folder: Folder, def: RemoteDefinition): Instance
	local existing = folder:FindFirstChild(def.name)
	if existing then
		return existing
	end
	if def.kind == "RemoteFunction" then
		local rf = Instance.new("RemoteFunction")
		rf.Name = def.name
		rf.Parent = folder
		return rf
	else
		local re = Instance.new("RemoteEvent")
		re.Name = def.name
		re.Parent = folder
		return re
	end
end

function Network.InitServer(): Folder
	assert(RunService:IsServer(), "[Network] InitServer can only be called on the Server")
	local folder = getOrCreateRemotesFolder()

	for remoteKey, def in pairs(Definitions) do
		assert(remoteKey == def.name, "[Network] Remote key mismatch: " .. tostring(remoteKey))
		getOrCreateServerRemote(folder, def)
	end

	return folder
end

function Network.Init(timeoutSec: number?): Folder
	local deadline = timeoutSec or 10.0
	local startTime = os.clock()

	if RunService:IsServer() then
		local folder = Network.InitServer()
		for _, def in pairs(Definitions) do
			local child = folder:FindFirstChild(def.name)
			assert(child ~= nil, "[Network.Init] Server remote missing: " .. def.name)
			assert(child.ClassName == def.kind, string.format(
				"[Network.Init] Server remote class mismatch for %s: expected %s, got %s",
				def.name, def.kind, child.ClassName
			))
		end
		local elapsed = os.clock() - startTime
		assert(elapsed <= deadline, string.format("[Network.Init] Server initialization exceeded deadline (%.3fs > %.3fs)", elapsed, deadline))
		return folder
	else
		local remaining = deadline - (os.clock() - startTime)
		assert(remaining > 0, "[Network.Init] Bootstrap deadline exhausted before waiting for Remotes folder")
		local folder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, remaining) :: Folder?
		assert(folder ~= nil and folder:IsA("Folder"), "[Network.Init] Remotes folder timed out in ReplicatedStorage")

		for _, def in pairs(Definitions) do
			remaining = deadline - (os.clock() - startTime)
			assert(remaining > 0, string.format("[Network.Init] Bootstrap deadline exhausted while waiting for remote %s", def.name))
			local remote = folder:WaitForChild(def.name, remaining)
			assert(remote ~= nil, string.format("[Network.Init] Remote %s timed out on client", def.name))
			assert(remote.ClassName == def.kind, string.format(
				"[Network.Init] Client remote class mismatch for %s: expected %s, got %s",
				def.name, def.kind, remote.ClassName
			))
		end

		return folder
	end
end

function Network.GetRemoteEvent(remoteName: string): RemoteEvent
	local def = Definitions[remoteName]
	assert(def ~= nil, "[Network] Unknown Remote name: " .. tostring(remoteName))
	assert(def.kind == "RemoteEvent", "[Network] Remote is not a RemoteEvent: " .. tostring(remoteName))

	if RunService:IsServer() then
		local folder = getOrCreateRemotesFolder()
		local remote = getOrCreateServerRemote(folder, def)
		assert(remote:IsA("RemoteEvent"), "[Network] Expected RemoteEvent: " .. def.name)
		return remote
	end

	local folder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 10) :: Folder
	assert(folder ~= nil, "[Network] Remotes folder not found in ReplicatedStorage")
	local remote = folder:WaitForChild(def.name, 10)
	assert(remote ~= nil and remote:IsA("RemoteEvent"), "[Network] Missing RemoteEvent: " .. def.name)
	return remote
end

function Network.GetRemoteFunction(remoteName: string): RemoteFunction
	local def = Definitions[remoteName]
	assert(def ~= nil, "[Network] Unknown Remote name: " .. tostring(remoteName))
	assert(def.kind == "RemoteFunction", "[Network] Remote is not a RemoteFunction: " .. tostring(remoteName))

	if RunService:IsServer() then
		local folder = getOrCreateRemotesFolder()
		local remote = getOrCreateServerRemote(folder, def)
		assert(remote:IsA("RemoteFunction"), "[Network] Expected RemoteFunction: " .. def.name)
		return remote
	end

	local folder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 10) :: Folder
	assert(folder ~= nil, "[Network] Remotes folder not found in ReplicatedStorage")
	local remote = folder:WaitForChild(def.name, 10)
	assert(remote ~= nil and remote:IsA("RemoteFunction"), "[Network] Missing RemoteFunction: " .. def.name)
	return remote
end

-- [FIX-M00-04] Server Payload Validators to prevent NaN / malformed payloads from Clients
function Network.IsFiniteVector3(v: any): boolean
	if typeof(v) ~= "Vector3" then
		return false
	end
	local vec = v :: Vector3
	if vec.X ~= vec.X or vec.Y ~= vec.Y or vec.Z ~= vec.Z then
		return false
	end
	if math.abs(vec.X) == math.huge or math.abs(vec.Y) == math.huge or math.abs(vec.Z) == math.huge then
		return false
	end
	return true
end

function Network.IsNonEmptyString(s: any, maxLen: number?): boolean
	if type(s) ~= "string" then
		return false
	end
	local str = s :: string
	local len = #str
	if len < 1 then
		return false
	end
	if maxLen ~= nil and len > maxLen then
		return false
	end
	return true
end

function Network.IsNumberInRange(n: any, minVal: number, maxVal: number): boolean
	if type(n) ~= "number" then
		return false
	end
	local num = n :: number
	if num ~= num or math.abs(num) == math.huge then
		return false
	end
	return num >= minVal and num <= maxVal
end

return table.freeze(Network)
