--!strict
-- src/server/services/DuelEngineService.luau
-- Module 03: Server-Authoritative 1v1 Choice Duel Engine (<= 6.0 Studs, Shooting Zone Gate, Mistake Penalties & Signature Cooldowns)

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local ConfigsFolder = Shared:WaitForChild("configs")
local CardConfigs = require(ConfigsFolder:WaitForChild("CardConfigs"))
local ChoiceConfigsInst = ConfigsFolder:FindFirstChild("ChoiceConfigs")
local ChoiceConfigs: any = if ChoiceConfigsInst then require(ChoiceConfigsInst) else {}

local Services = script.Parent
local BallService = require(Services:WaitForChild("BallService"))
local ParryServiceInst = Services:FindFirstChild("ParryService")
local ParryService: any = if ParryServiceInst then require(ParryServiceInst) else {}
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

export type ActiveDuelSession = {
	duelId: string,
	attackerUserId: number,
	defenderUserId: number,
	attackerPosition: Types.PlayerPosition,
	defenderPosition: Types.PlayerPosition,
	attackerAvailable: { string },
	defenderAvailable: { string },
	attackerLocked: { string },
	defenderLocked: { string },
	attackerHasMistake: boolean,
	defenderHasMistake: boolean,
	isInShootingZone: boolean,
	attackerChoice: string?,
	defenderChoice: string?,
	startedAt: number,
	expiresAt: number,
	resolved: boolean,
}

local activeDuelsById: { [string]: ActiveDuelSession } = {}
local activeDuelIdByUserId: { [number]: string } = {}
local playerPositionByUserId: { [number]: Types.PlayerPosition } = {}
local signatureCooldownUntilByUserId: { [number]: { [string]: number } } = {}
local duelCooldownUntilByPair: { [string]: number } = {}
local isInitialized = false

local DuelEngineService = {}

local function addUniqueLock(lockList: { string }, choiceId: string)
	for _, existing in ipairs(lockList) do
		if existing == choiceId then
			return
		end
	end
	table.insert(lockList, choiceId)
end

local function isChoiceLocked(lockList: { string }, choiceId: string): boolean
	for _, existing in ipairs(lockList) do
		if existing == choiceId then
			return true
		end
	end
	return false
end

local function isChoiceInList(choiceList: { string }, choiceId: string): boolean
	for _, existing in ipairs(choiceList) do
		if existing == choiceId then
			return true
		end
	end
	return false
end

function DuelEngineService.SetPlayerPosition(userId: number, position: Types.PlayerPosition)
	playerPositionByUserId[userId] = position
end

function DuelEngineService.GetPlayerPosition(userId: number): Types.PlayerPosition
	return playerPositionByUserId[userId] or "Forward"
end

function DuelEngineService.IsSignatureOnCooldown(userId: number, choiceId: string): (boolean, number)
	local userMap = signatureCooldownUntilByUserId[userId]
	if not userMap then
		return false, 0
	end
	local expiresAt = userMap[choiceId] or 0
	local remaining = expiresAt - os.clock()
	if remaining > 0 then
		return true, remaining
	end
	return false, 0
end

function DuelEngineService.PutSignatureOnCooldown(userId: number, choiceId: string, cooldownSec: number)
	if not signatureCooldownUntilByUserId[userId] then
		signatureCooldownUntilByUserId[userId] = {}
	end
	signatureCooldownUntilByUserId[userId][choiceId] = os.clock() + cooldownSec
end

function DuelEngineService.HasDefenderMistake(
	defenderUserId: number,
	defenderCFrame: CFrame?,
	attackerPosition: Vector3?
): (boolean, { string })
	local reasons: { string } = {}
	if ParryService.IsInMissedSlideRecovery(defenderUserId) then
		table.insert(reasons, "MissedSlideRecovery")
	end
	if BallService.HasSprintOvershootMistake(defenderUserId) then
		table.insert(reasons, "SprintOvershoot")
	end
	if defenderCFrame and attackerPosition then
		local toAttacker = attackerPosition - defenderCFrame.Position
		if toAttacker.Magnitude > 1e-3 then
			local dot = defenderCFrame.LookVector:Dot(toAttacker.Unit)
			if dot < -0.15 then
				table.insert(reasons, "BackTurnedPositioning")
			end
		end
	end
	return (#reasons > 0), reasons
end

function DuelEngineService.SelectTierWinCutscene(userId: number): string
	local cardCfg = RigAndCardService.GetEquippedCardConfig(userId)
	local maxAllowed = Constants.MAX_WIN_CUTSCENES_BY_TIER[cardCfg.tier] or 1
	local animList = cardCfg.winCutsceneAnimIds
	local count = math.min(#animList, maxAllowed)
	if count <= 0 then
		return "SlowMoNutmeg"
	end
	local pickIdx = math.random(1, count)
	return animList[pickIdx]
end

function DuelEngineService.BuildDuelChoicesAndLocks(
	attackerUserId: number,
	defenderUserId: number,
	ballPosition: Vector3,
	attackingTeam: string,
	gameMode: string?,
	defenderCFrame: CFrame?
)
	local attackerCard = RigAndCardService.GetEquippedCardConfig(attackerUserId)
	local defenderCard = RigAndCardService.GetEquippedCardConfig(defenderUserId)
	local attackerPos = DuelEngineService.GetPlayerPosition(attackerUserId)
	local defenderPos: Types.PlayerPosition = "Defender"

	local attackerAvailable = ChoiceConfigs.GetAvailableChoicesForRole(
		"Attacker",
		attackerPos,
		attackerCard.signatureChoiceId
	)
	local defenderAvailable = ChoiceConfigs.GetAvailableChoicesForRole(
		"Defender",
		defenderPos,
		defenderCard.signatureChoiceId
	)

	local attackerLocked: { string } = {}
	local defenderLocked: { string } = {}

	-- Rule 7: Shooting Zone Check
	local inShootingZone = BallService.IsInShootingZone(ballPosition, attackingTeam, gameMode)
	if not inShootingZone then
		addUniqueLock(attackerLocked, "SnapShot")
		if attackerCard.signatureChoiceId == "KnuckleEmperor" then
			addUniqueLock(attackerLocked, "KnuckleEmperor")
		end
	end

	-- Rule 5: Signature Cooldown Check
	local atkSigOnCd = DuelEngineService.IsSignatureOnCooldown(attackerUserId, attackerCard.signatureChoiceId)
	if atkSigOnCd then
		addUniqueLock(attackerLocked, attackerCard.signatureChoiceId)
	end
	local defSigOnCd = DuelEngineService.IsSignatureOnCooldown(defenderUserId, defenderCard.signatureChoiceId)
	if defSigOnCd then
		addUniqueLock(defenderLocked, defenderCard.signatureChoiceId)
	end

	-- Section 4.3: Mistake Mechanics
	local attackerHasMistake = BallService.HasOnBallMistake(attackerUserId)
	if attackerHasMistake then
		addUniqueLock(attackerLocked, "TechNutmeg")
		addUniqueLock(attackerLocked, "BodyFeint")
	end

	local defenderHasMistake = DuelEngineService.HasDefenderMistake(defenderUserId, defenderCFrame, ballPosition)
	if defenderHasMistake then
		addUniqueLock(defenderLocked, "JockeyIntercept")
	end

	local attackerTimeLimit = if attackerHasMistake
		then Constants.CHOICE_DUEL_MISTAKE_WINDOW_SEC
		else Constants.CHOICE_DUEL_DEFAULT_WINDOW_SEC

	return {
		attackerAvailable = attackerAvailable,
		defenderAvailable = defenderAvailable,
		attackerLocked = attackerLocked,
		defenderLocked = defenderLocked,
		attackerHasMistake = attackerHasMistake,
		defenderHasMistake = defenderHasMistake,
		inShootingZone = inShootingZone,
		timeLimit = attackerTimeLimit,
	}
end

function DuelEngineService.StartDuel(
	attacker: Player,
	defender: Player,
	gameMode: string?
): ActiveDuelSession?
	-- Retired per Q22 / Spec 02 (Choice Duel replaced by Continuous Football & SkillMoveService)
	if true then
		return nil
	end
	if activeDuelIdByUserId[attacker.UserId] ~= nil or activeDuelIdByUserId[defender.UserId] ~= nil then
		return nil
	end

	local pairKey = tostring(math.min(attacker.UserId, defender.UserId))
		.. ":"
		.. tostring(math.max(attacker.UserId, defender.UserId))
	local now = os.clock()
	if (duelCooldownUntilByPair[pairKey] or 0) > now then
		return nil
	end

	local ballState = BallService.GetBallState()
	local attackingTeam = BallService.GetPlayerTeamSide(attacker.UserId)
	local defCFrame: CFrame? = nil
	if defender.Character and defender.Character.PrimaryPart then
		defCFrame = defender.Character.PrimaryPart.CFrame
	end

	local built = DuelEngineService.BuildDuelChoicesAndLocks(
		attacker.UserId,
		defender.UserId,
		ballState.position,
		attackingTeam,
		gameMode,
		defCFrame
	)

	local duelId = "DUEL_" .. HttpService:GenerateGUID(false)
	local session: ActiveDuelSession = {
		duelId = duelId,
		attackerUserId = attacker.UserId,
		defenderUserId = defender.UserId,
		attackerPosition = DuelEngineService.GetPlayerPosition(attacker.UserId),
		defenderPosition = "Defender",
		attackerAvailable = built.attackerAvailable,
		defenderAvailable = built.defenderAvailable,
		attackerLocked = built.attackerLocked,
		defenderLocked = built.defenderLocked,
		attackerHasMistake = built.attackerHasMistake,
		defenderHasMistake = built.defenderHasMistake,
		isInShootingZone = built.inShootingZone,
		attackerChoice = nil,
		defenderChoice = nil,
		startedAt = now,
		expiresAt = now + built.timeLimit,
		resolved = false,
	}

	activeDuelsById[duelId] = session
	activeDuelIdByUserId[attacker.UserId] = duelId
	activeDuelIdByUserId[defender.UserId] = duelId

	local startEvent = Network.GetRemoteEvent(Network.Names.DuelStartEvent)
	startEvent:FireClient(
		attacker,
		duelId,
		"Attacker",
		session.attackerAvailable,
		session.attackerLocked,
		built.timeLimit
	)
	startEvent:FireClient(
		defender,
		duelId,
		"Defender",
		session.defenderAvailable,
		session.defenderLocked,
		Constants.CHOICE_DUEL_DEFAULT_WINDOW_SEC
	)

	task.delay(Constants.CHOICE_DUEL_DEFAULT_WINDOW_SEC + 0.05, function()
		if activeDuelsById[duelId] and not activeDuelsById[duelId].resolved then
			DuelEngineService.ResolveDuelSession(duelId)
		end
	end)

	return session
end

function DuelEngineService.SubmitDuelChoice(player: Player, duelId: string, selectedChoiceId: string): boolean
	local session = activeDuelsById[duelId]
	if not session or session.resolved then
		return false
	end

	local userId = player.UserId
	if userId == session.attackerUserId then
		if session.attackerChoice ~= nil then
			return false
		end
		if not isChoiceInList(session.attackerAvailable, selectedChoiceId) then
			return false
		end
		if isChoiceLocked(session.attackerLocked, selectedChoiceId) then
			return false
		end
		session.attackerChoice = selectedChoiceId
	elseif userId == session.defenderUserId then
		if session.defenderChoice ~= nil then
			return false
		end
		if not isChoiceInList(session.defenderAvailable, selectedChoiceId) then
			return false
		end
		if isChoiceLocked(session.defenderLocked, selectedChoiceId) then
			return false
		end
		session.defenderChoice = selectedChoiceId
	else
		return false
	end

	if session.attackerChoice ~= nil and session.defenderChoice ~= nil then
		DuelEngineService.ResolveDuelSession(duelId)
	end
	return true
end

function DuelEngineService.ResolveDuelSession(duelId: string): (number?, string?, string?)
	local session = activeDuelsById[duelId]
	if not session or session.resolved then
		return nil, nil, nil
	end
	session.resolved = true

	local atkChoice = session.attackerChoice or "SpeedBurst"
	local defChoice = session.defenderChoice or "HardTackle"

	-- Trigger Signature Cooldown if a signature choice was used
	local atkDef = ChoiceConfigs.ChoiceCatalog[atkChoice]
	if atkDef and atkDef.isSignature and atkDef.cooldownSec > 0 then
		DuelEngineService.PutSignatureOnCooldown(session.attackerUserId, atkChoice, atkDef.cooldownSec)
	end
	local defDef = ChoiceConfigs.ChoiceCatalog[defChoice]
	if defDef and defDef.isSignature and defDef.cooldownSec > 0 then
		DuelEngineService.PutSignatureOnCooldown(session.defenderUserId, defChoice, defDef.cooldownSec)
	end

	local winnerRole, appliedBuff = ChoiceConfigs.ResolveChoiceOutcome(
		atkChoice,
		defChoice,
		session.attackerHasMistake,
		session.defenderHasMistake,
		session.isInShootingZone
	)

	local winnerUserId = if winnerRole == "Attacker" then session.attackerUserId else session.defenderUserId
	local cutsceneAnimId = DuelEngineService.SelectTierWinCutscene(winnerUserId)

	if winnerRole == "Attacker" then
		BallService.SetPossessor(session.attackerUserId, 0)
		if appliedBuff == "ZoneFocus_+35%" then
			-- Leon Tier S buff: +35% Pass & Shot for 4 seconds
			BallService.ApplyZoneFocusBuff(session.attackerUserId, 1.35, 4.0)
		end
	else
		BallService.SetPossessor(session.defenderUserId, 0)
	end

	local pairKey = tostring(math.min(session.attackerUserId, session.defenderUserId))
		.. ":"
		.. tostring(math.max(session.attackerUserId, session.defenderUserId))
	duelCooldownUntilByPair[pairKey] = os.clock() + 2.5

	activeDuelIdByUserId[session.attackerUserId] = nil
	activeDuelIdByUserId[session.defenderUserId] = nil
	activeDuelsById[duelId] = nil

	local resultEvent = Network.GetRemoteEvent(Network.Names.DuelResultEvent)
	resultEvent:FireAllClients(duelId, winnerUserId, cutsceneAnimId, appliedBuff)

	return winnerUserId, cutsceneAnimId, appliedBuff
end

function DuelEngineService.ScanProximityForDuel(_gameMode: string?)
	-- Retired per Q22 / Spec 02 (no Choice Duel proximity triggers)
	return
end

function DuelEngineService.Init()
	-- Retired per Q22 / Spec 02: DuelChoiceSubmit remote listener is disabled; SkillMoveService is authoritative.
	isInitialized = true
end

DuelEngineService.IsRetired = true

return table.freeze(DuelEngineService)
