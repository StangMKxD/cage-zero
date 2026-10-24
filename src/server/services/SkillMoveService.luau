--!strict
-- src/server/services/SkillMoveService.luau
-- Module 03: Server-Authoritative Skill Moves (5 Moves, 3 Slots) & Defense Orchestration
-- Delegates physical ball & stamina mutations to BallService (single authoritative writer).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local Configs = Shared:WaitForChild("configs")
local SkillMoveConfigs = require(Configs:WaitForChild("SkillMoveConfigs"))

local Services = script.Parent
local BallService = require(Services:WaitForChild("BallService"))

export type PlayerSkillRecord = {
	userId: number,
	starCeiling: number,
	loadout: Types.PlayerSkillLoadout,
	cooldownUntilBySkill: { [Types.SkillMoveId]: number },
	processedIntents: { [string]: boolean },
}

local playerRecords: { [number]: PlayerSkillRecord } = {}
local isInitialized = false

local SkillMoveService = {}

local function getOrCreateRecord(userId: number): PlayerSkillRecord
	local existing = playerRecords[userId]
	if existing then
		return existing
	end
	local rec: PlayerSkillRecord = {
		userId = userId,
		starCeiling = Constants.SKILL_CEILING_STARS or SkillMoveConfigs.STARTER_CEILING_STARS,
		loadout = {
			slot1 = SkillMoveConfigs.DEFAULT_LOADOUT.slot1,
			slot2 = SkillMoveConfigs.DEFAULT_LOADOUT.slot2,
			slot3 = SkillMoveConfigs.DEFAULT_LOADOUT.slot3,
		},
		cooldownUntilBySkill = {},
		processedIntents = {},
	}
	playerRecords[userId] = rec
	return rec
end

local function syncSkillAttributes(userId: number)
	local rec = getOrCreateRecord(userId)
	local snap = BallService.GetPlayerMovementSnapshot(userId)
	local player = Players:GetPlayerByUserId(userId)
	local char = player and player.Character
	if not char then
		return
	end
	local now = os.clock()
	char:SetAttribute("SkillStarCeiling", rec.starCeiling)
	char:SetAttribute("SkillSlot1", rec.loadout.slot1)
	char:SetAttribute("SkillSlot2", rec.loadout.slot2)
	char:SetAttribute("SkillSlot3", rec.loadout.slot3)
	for skillId, _ in pairs(SkillMoveConfigs.Catalog) do
		local untilTime = rec.cooldownUntilBySkill[skillId] or 0
		local rem = math.max(0.0, math.round((untilTime - now) * 100) / 100)
		char:SetAttribute("Cooldown_" .. skillId, rem)
	end
	char:SetAttribute("CommonSkillRecoveryRemaining", math.round((snap.commonSkillRecoveryRemaining or 0) * 100) / 100)
end

function SkillMoveService.GetPlayerLoadout(userId: number): Types.PlayerSkillLoadout
	local rec = getOrCreateRecord(userId)
	return table.freeze({
		slot1 = rec.loadout.slot1,
		slot2 = rec.loadout.slot2,
		slot3 = rec.loadout.slot3,
	})
end

function SkillMoveService.GetPlayerStarCeiling(userId: number): number
	return getOrCreateRecord(userId).starCeiling
end

function SkillMoveService.SetPlayerStarCeiling(userId: number, stars: number)
	local rec = getOrCreateRecord(userId)
	rec.starCeiling = math.clamp(math.floor(stars), 1, 5)
	syncSkillAttributes(userId)
end

-- Loadout changes allowed only before round or when stopped/reset training; never clears cooldowns
function SkillMoveService.SetPlayerLoadout(
	userId: number,
	newLoadout: Types.PlayerSkillLoadout,
	isStoppedOrResetContext: boolean?
): (boolean, string?)
	if isStoppedOrResetContext == false then
		return false, "MatchInProgress"
	end

	local snap = BallService.GetPlayerMovementSnapshot(userId)
	if snap.activeSkillMove ~= nil or (snap.commonSkillRecoveryRemaining or 0) > 0 or snap.isSliding or snap.isCharging then
		return false, "ActionInProgress"
	end

	local rec = getOrCreateRecord(userId)
	local ok, reason = SkillMoveConfigs.ValidateLoadout(newLoadout, rec.starCeiling)
	if not ok then
		return false, reason
	end

	rec.loadout = {
		slot1 = newLoadout.slot1,
		slot2 = newLoadout.slot2,
		slot3 = newLoadout.slot3,
	}
	-- NOTE: rec.cooldownUntilBySkill is intentionally preserved so loadout swaps cannot evade cooldowns
	syncSkillAttributes(userId)
	return true, nil
end

function SkillMoveService.GetSkillCooldownRemaining(userId: number, skillId: Types.SkillMoveId): number
	local rec = getOrCreateRecord(userId)
	local untilTime = rec.cooldownUntilBySkill[skillId] or 0
	return math.max(0.0, untilTime - os.clock())
end

function SkillMoveService.ClearAllStatesForTesting()
	table.clear(playerRecords)
end

function SkillMoveService.ExecuteSkillSlot(
	player: Player | { UserId: number, Character: Model? },
	slotIndex: number,
	direction: Vector3,
	intentId: string?,
	requestedSkillId: string?
): boolean
	local userId = player.UserId
	local rec = getOrCreateRecord(userId)
	local now = os.clock()

	if type(slotIndex) ~= "number" or (slotIndex ~= 1 and slotIndex ~= 2 and slotIndex ~= 3) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	if typeof(direction) ~= "Vector3" or not Network.IsFiniteVector3(direction) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	if intentId ~= nil then
		if rec.processedIntents[intentId] then
			return BallService.RecordActionFailure(player, intentId, "StaleIntent")
		end
	end

	local equippedSkillId: Types.SkillMoveId = if slotIndex == 1
		then rec.loadout.slot1
		elseif slotIndex == 2 then rec.loadout.slot2
		else rec.loadout.slot3

	if requestedSkillId ~= nil and requestedSkillId ~= "" and requestedSkillId ~= equippedSkillId then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	local skillDef = SkillMoveConfigs.GetSkill(equippedSkillId)
	if not skillDef then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	if skillDef.starRating > rec.starCeiling then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	-- Skills have 0 cooldown; governed purely by stamina per Owner directive
	if intentId ~= nil then
		rec.processedIntents[intentId] = true
	end

	local character = if typeof(player) == "Instance" and player:IsA("Player")
		then player.Character else (player :: any).Character
	local root = character and character.PrimaryPart
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return BallService.RecordActionFailure(player, intentId, "NotAlive")
	end
	local resolvedDirection, resolvedSide = SkillMoveConfigs.ResolveCharacterRelativeDirection(
		skillDef,
		direction,
		humanoid.MoveDirection,
		root.CFrame
	)
	local ok = BallService.ApplySkillBallImpulse(player, skillDef, resolvedDirection, resolvedSide, intentId, slotIndex)
	if not ok then
		return false
	end

	rec.cooldownUntilBySkill[equippedSkillId] = 0
	syncSkillAttributes(userId)

	local flatDir = Vector3.new(resolvedDirection.X, 0, resolvedDirection.Z)
	flatDir = if flatDir.Magnitude > 1e-3 then flatDir.Unit else Vector3.new(0, 0, 1)

	if RunService:IsServer() and RunService:IsRunning() then
		local replicateEvent = Network.GetRemoteEvent(Network.Names.SkillMoveReplicate)
		replicateEvent:FireAllClients({
			userId = userId,
			skillId = equippedSkillId,
			direction = flatDir,
		side = resolvedSide,
			durationSec = skillDef.totalDurationSec,
			intentId = intentId or "",
		})
	end

	return true
end

function SkillMoveService.HandleSkillMoveRequest(player: Player | { UserId: number, Character: Model? }, payload: any): boolean
	if type(payload) ~= "table" then
		return BallService.RecordActionFailure(player, nil, "InvalidPayload")
	end

	local rawIntentId = payload.intentId
	if not Network.IsNonEmptyString(rawIntentId, 64) then
		return BallService.RecordActionFailure(player, nil, "InvalidPayload")
	end
	local intentId = rawIntentId :: string

	local userId = player.UserId
	local rawGen = payload.characterGeneration
	local rawCtx = payload.contextVersion
	if not Network.IsNumberInRange(rawGen, 0, 1e9) or rawGen ~= math.floor(rawGen) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end
	if not Network.IsNumberInRange(rawCtx, 0, 1e9) or rawCtx ~= math.floor(rawCtx) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	if rawGen ~= BallService.GetPlayerGeneration(userId) or rawCtx ~= BallService.GetPlayerContextVersion(userId) then
		return BallService.RecordActionFailure(player, intentId, "StaleIntent")
	end

	local slotIndex = payload.slotIndex
	local direction = payload.direction
	local skillId = payload.skillId
	if skillId ~= nil and type(skillId) ~= "string" then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	return SkillMoveService.ExecuteSkillSlot(player, slotIndex, direction, intentId, skillId)
end

function SkillMoveService.HandleTackleActionRequest(player: Player | { UserId: number, Character: Model? }, payload: any): boolean
	if type(payload) ~= "table" then
		return BallService.RecordActionFailure(player, nil, "InvalidPayload")
	end

	local rawIntentId = payload.intentId
	if not Network.IsNonEmptyString(rawIntentId, 64) then
		return BallService.RecordActionFailure(player, nil, "InvalidPayload")
	end
	local intentId = rawIntentId :: string

	local userId = player.UserId
	local rec = getOrCreateRecord(userId)
	if rec.processedIntents[intentId] then
		return BallService.RecordActionFailure(player, intentId, "StaleIntent")
	end

	local rawGen = payload.characterGeneration
	local rawCtx = payload.contextVersion
	if not Network.IsNumberInRange(rawGen, 0, 1e9) or rawGen ~= math.floor(rawGen) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end
	if not Network.IsNumberInRange(rawCtx, 0, 1e9) or rawCtx ~= math.floor(rawCtx) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	if rawGen ~= BallService.GetPlayerGeneration(userId) or rawCtx ~= BallService.GetPlayerContextVersion(userId) then
		return BallService.RecordActionFailure(player, intentId, "StaleIntent")
	end

	local tackleType = payload.tackleType
	local direction = payload.direction
	if typeof(direction) ~= "Vector3" or not Network.IsFiniteVector3(direction) then
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end

	rec.processedIntents[intentId] = true

	if tackleType == "Poke" then
		return BallService.ExecutePokeTackle(player, direction, intentId)
	elseif tackleType == "CagePress" then
		return BallService.ExecuteCagePress(player, direction, intentId)
	elseif tackleType == "Slide" then
		return BallService.ExecuteSlide(player, direction, 0.5, intentId)
	else
		return BallService.RecordActionFailure(player, intentId, "InvalidPayload")
	end
end

function SkillMoveService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local skillReqEvent = Network.GetRemoteEvent(Network.Names.SkillMoveRequest)
	skillReqEvent.OnServerEvent:Connect(function(player: Player, payload: any)
		SkillMoveService.HandleSkillMoveRequest(player, payload)
	end)

	local tackleReqEvent = Network.GetRemoteEvent(Network.Names.TackleActionRequest)
	tackleReqEvent.OnServerEvent:Connect(function(player: Player, payload: any)
		SkillMoveService.HandleTackleActionRequest(player, payload)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		getOrCreateRecord(player.UserId)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				syncSkillAttributes(player.UserId)
			end)
		end)
		if player.Character then
			syncSkillAttributes(player.UserId)
		end
	end

	Players.PlayerAdded:Connect(function(player: Player)
		getOrCreateRecord(player.UserId)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				syncSkillAttributes(player.UserId)
			end)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerRecords[player.UserId] = nil
	end)
end

return table.freeze(SkillMoveService)
