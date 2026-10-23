--!strict
-- src/server/services/BallService.luau
-- Module 02: Server-Authoritative Ball Possession, Continuous Football Actions, Movement & Team Context
-- Built per Spec 02 (Q22: Continuous Football, no Choice duels, no Parry) and HANDOFF Contract

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local AirLeanSolver = require(Shared:WaitForChild("AirLeanSolver"))
local Configs = Shared:WaitForChild("configs")
local PlayerActionPoseConfigs = require(Configs:WaitForChild("PlayerActionPoseConfigs"))
local AirLeanConfigs = require(Configs:WaitForChild("AirLeanConfigs"))

local Services = script.Parent
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

export type PlayerMovementState = {
	userId: number,
	teamSide: Types.TeamSide,
	stamina: number,
	lastStaminaUseTime: number,
	isSprinting: boolean,
	isDashing: boolean,
	dashEndTime: number,
	dashCooldownUntil: number,
	isAirborne: boolean,
	takeoffTime: number,
	jumpLockedVelocity: Vector3?,
	actionContext: Types.TeamActionContext,
	lastMoveDir: Vector3,
	boostMultiplier: number,
	boostUntil: number,
	characterOverride: Model?,
	characterGeneration: number,
	contextVersion: number,
	actionSequence: number,
	isCharging: boolean,
	chargeStartTime: number,
	chargeAction: Types.ChargeActionType?,
	chargeIntentId: string?,
	chargeGeneration: number,
	chargeContextVersion: number,
	isSliding: boolean,
	slideStartTime: number,
	slideEndTime: number,
	slideCooldownUntil: number,
	slideRecoveryUntil: number,
	slideDir: Vector3,
	slideCharge: number,
	slideHitBall: boolean,
	lastActionRequestTime: number,
	processedIntents: { [string]: { [string]: boolean } },
	terminalIntents: { [string]: boolean },
	lastResolvedAction: string,
	lastActionStatus: string,
	lastActionReason: string,
	lastActionIntentId: string,
	resolvedKickFoot: string?,
	resolvedCurveStyle: string?,
	whiffRecoveryUntil: number?,
	jumpFacingF0: Vector3?,
	airLeanForward: number?,
	airLeanRight: number?,
	lastAirLeanTime: number?,
}

local BALL_PART_NAME = Constants.BALL_PART_NAME or "CageMatchBall"

local ballState = {
	ballId = "BALL_01",
	position = Constants.BALL_SPAWN_POSITION or Vector3.new(0, Constants.BALL_RADIUS, 0),
	velocity = Vector3.zero,
	state = "Free" :: Types.BallPossessionState,
	possessorUserId = nil :: number?,
	lastPossessingTeam = nil :: Types.TeamSide?,
	lastKickerUserId = nil :: number?,
	lastKickTime = 0,
	curveImpulse = nil :: Vector3?,
	inFlightAction = nil :: Types.KickActionType?,
}

local playerStates: { [number]: PlayerMovementState } = {}
local ballPart: Part? = nil
local isInitialized = false
local heartbeatConn: RBXScriptConnection? = nil

local BallService = {}

local function getOrCreatePlayerState(userId: number): PlayerMovementState
	local st = playerStates[userId]
	if st then
		return st
	end
	local team: Types.TeamSide = if (userId % 2 == 0) then "South" else "North"
	local defaultContext: Types.TeamActionContext = "Attacking"

	local newState: PlayerMovementState = {
		userId = userId,
		teamSide = team,
		stamina = 1.0,
		lastStaminaUseTime = 0,
		isSprinting = false,
		isDashing = false,
		dashEndTime = 0,
		dashCooldownUntil = 0,
		isAirborne = false,
		takeoffTime = 0,
		jumpLockedVelocity = nil,
		actionContext = defaultContext,
		lastMoveDir = Vector3.new(0, 0, 1),
		boostMultiplier = 1.0,
		boostUntil = 0,
		characterOverride = nil,
		characterGeneration = 1,
		contextVersion = 1,
		actionSequence = 0,
		isCharging = false,
		chargeStartTime = 0,
		chargeAction = nil,
		chargeIntentId = nil,
		chargeGeneration = 0,
		chargeContextVersion = 0,
		isSliding = false,
		slideStartTime = 0,
		slideEndTime = 0,
		slideCooldownUntil = 0,
		slideRecoveryUntil = 0,
		slideDir = Vector3.new(0, 0, 1),
		slideCharge = 0.5,
		slideHitBall = false,
		lastActionRequestTime = 0,
		processedIntents = {},
		terminalIntents = {},
		lastResolvedAction = "",
		lastActionStatus = "Accepted",
		lastActionReason = "",
		lastActionIntentId = "",
		resolvedKickFoot = nil,
		resolvedCurveStyle = nil,
		whiffRecoveryUntil = 0,
		jumpFacingF0 = nil,
		airLeanForward = 0.0,
		airLeanRight = 0.0,
		lastAirLeanTime = 0,
	}
	playerStates[userId] = newState
	return newState
end

local function getPlayerCharacter(userId: number): Model?
	local st = playerStates[userId]
	if st and st.characterOverride and st.characterOverride.Parent ~= nil then
		return st.characterOverride
	end
	local player = Players:GetPlayerByUserId(userId)
	return player and player.Character
end

local function syncPlayerAttributes(player: Player?, st: PlayerMovementState)
	local char = (player and player.Character) or st.characterOverride
	if not char then
		return
	end
	local now = os.clock()
	char:SetAttribute("Stamina", math.round(st.stamina * 100) / 100)
	char:SetAttribute("TeamSide", st.teamSide)
	char:SetAttribute("IsSprinting", st.isSprinting)
	char:SetAttribute("IsDashing", st.isDashing)
	char:SetAttribute("DashCooldownRemaining", math.max(0, math.round((st.dashCooldownUntil - now) * 100) / 100))
	char:SetAttribute("IsAirborne", st.isAirborne)
	char:SetAttribute("IsCharging", st.isCharging)
	char:SetAttribute("ActionContext", st.actionContext)
	char:SetAttribute("PlayerActionGeneration", st.characterGeneration)
	char:SetAttribute("ActionContextVersion", st.contextVersion)
	char:SetAttribute("IsSliding", st.isSliding)
	char:SetAttribute("SlideCooldownRemaining", math.max(0, math.round((st.slideCooldownUntil - now) * 100) / 100))
	char:SetAttribute("RecoveryRemaining", math.max(0, math.round((st.slideRecoveryUntil - now) * 100) / 100))
	char:SetAttribute("ChargeAction", st.chargeAction or "")
	local chargePower = 0.0
	if st.isCharging and st.chargeStartTime > 0 then
		local elapsed = now - st.chargeStartTime
		chargePower = if elapsed < 0.12
			then Constants.CHARGE_MIN_POWER
			else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
	end
	char:SetAttribute("ChargePower", math.round(chargePower * 100) / 100)
	char:SetAttribute("LastResolvedAction", st.lastResolvedAction)
	char:SetAttribute("ActionSequence", st.actionSequence)
	char:SetAttribute("LastActionIntentId", st.lastActionIntentId)
	char:SetAttribute("LastActionStatus", st.lastActionStatus)
	char:SetAttribute("LastActionReason", st.lastActionReason)
	char:SetAttribute("LastActionRejectReason", st.lastActionReason)
	char:SetAttribute("ResolvedKickFoot", st.resolvedKickFoot or "")
	char:SetAttribute("ResolvedCurveStyle", st.resolvedCurveStyle or "")
end

local function recordActionFailure(player: Player | { UserId: number, Character: Model? }, intentId: string?, reason: Types.ActionRejectReason): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	st.lastActionIntentId = intentId or ""
	st.lastActionStatus = "Rejected"
	st.lastActionReason = reason
	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return false
end

local function recordActionSuccess(player: Player | { UserId: number, Character: Model? }, intentId: string?, resolvedAction: string)
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	st.lastActionIntentId = intentId or ""
	st.lastActionStatus = "Accepted"
	st.lastActionReason = ""
	st.lastResolvedAction = resolvedAction
	st.actionSequence += 1
	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
end

local function syncBallAttributes()
	if not ballPart then
		return
	end
	ballPart:SetAttribute("BallState", ballState.state)
	ballPart:SetAttribute("PossessorUserId", ballState.possessorUserId or 0)
	ballPart:SetAttribute("LastPossessingTeam", ballState.lastPossessingTeam or "None")
	ballPart:SetAttribute("InFlightAction", ballState.inFlightAction or "None")
end

local function updateTeamContexts()
	local attackingTeam = ballState.lastPossessingTeam
	for userId, st in pairs(playerStates) do
		local oldContext = st.actionContext
		if attackingTeam == nil then
			st.actionContext = "Attacking"
		elseif st.teamSide == attackingTeam then
			st.actionContext = "Attacking"
		else
			st.actionContext = "Defending"
		end

		if st.actionContext ~= oldContext then
			st.contextVersion += 1
			if st.isCharging then
				if st.chargeIntentId then
					st.terminalIntents[st.chargeIntentId] = true
				end
				st.isCharging = false
				st.chargeStartTime = 0
				st.chargeAction = nil
				st.chargeIntentId = nil
				st.lastActionStatus = "Cancelled"
				st.lastActionReason = "WrongContext"
				local char = getPlayerCharacter(userId)
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					hum.WalkSpeed = if st.isSprinting and st.stamina > 0.05 then Constants.SPRINT_SPEED else Constants.WALK_SPEED
				end
			end
		end

		local player = Players:GetPlayerByUserId(userId)
		syncPlayerAttributes(player, st)
	end
end

function BallService.SetPlayerCharacterOverride(userId: number, character: Model?)
	if character == nil then
		playerStates[userId] = nil
		if ballState.possessorUserId == userId then
			ballState.possessorUserId = nil
			ballState.state = "Free"
			syncBallAttributes()
		end
		return
	end
	local st = getOrCreatePlayerState(userId)
	st.characterOverride = character
	local player = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(player, st)
end

function BallService.ResetPlayerState(userId: number)
	playerStates[userId] = nil
	if ballState.possessorUserId == userId then
		ballState.possessorUserId = nil
		ballState.state = "Free"
		syncBallAttributes()
	end
end

function BallService.ClearAllPlayerStates()
	table.clear(playerStates)
	ballState.possessorUserId = nil
	ballState.state = "Free"
	syncBallAttributes()
end

function BallService.EnsureBallInstance(): Part
	if ballPart and ballPart.Parent ~= nil then
		return ballPart
	end
	local existing = Workspace:FindFirstChild(BALL_PART_NAME)
	if existing and existing:IsA("Part") then
		ballPart = existing
		return existing
	end

	local p = Instance.new("Part")
	p.Name = BALL_PART_NAME
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
	p.Color = Color3.fromRGB(245, 250, 255)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CFrame = CFrame.new(ballState.position)
	p:SetAttribute("IsMatchBall", true)
	p.Parent = Workspace
	ballPart = p
	syncBallAttributes()
	return p
end

function BallService.GetBallState(): Types.BallSnapshot
	return {
		ballId = ballState.ballId,
		position = ballState.position,
		velocity = ballState.velocity,
		state = ballState.state,
		possessorUserId = ballState.possessorUserId,
		lastPossessingTeam = ballState.lastPossessingTeam,
		lastKickerUserId = ballState.lastKickerUserId,
		curveImpulse = ballState.curveImpulse,
		inFlightAction = ballState.inFlightAction,
	}
end

function BallService.SetBallPositionAndVelocity(pos: Vector3, vel: Vector3)
	ballState.position = pos
	ballState.velocity = vel
	ballState.state = "Free"
	ballState.possessorUserId = nil
	ballState.inFlightAction = nil
	ballState.curveImpulse = nil
	if ballPart then
		ballPart.CFrame = CFrame.new(pos)
	end
	syncBallAttributes()
end

function BallService.SetPossessor(userId: number?)
	ballState.possessorUserId = userId
	if userId ~= nil then
		local st = getOrCreatePlayerState(userId)
		ballState.state = "Possessed"
		ballState.velocity = Vector3.zero
		ballState.curveImpulse = nil
		ballState.inFlightAction = nil
		ballState.lastPossessingTeam = st.teamSide
		local char = getPlayerCharacter(userId)
		local rootPart = char and char.PrimaryPart
		if rootPart then
			local fwd = rootPart.CFrame.LookVector
			local flatFwd = Vector3.new(fwd.X, 0, fwd.Z)
			flatFwd = if flatFwd.Magnitude > 1e-3 then flatFwd.Unit else Vector3.new(0, 0, 1)
			local dribbleDist = if st.stamina < Constants.STAMINA_EXHAUSTED_THRESHOLD
				then math.abs(Constants.BALL_DRIBBLE_EXHAUSTED_OFFSET_Z)
				else math.abs(Constants.BALL_DRIBBLE_OFFSET_Z)
			ballState.position = Vector3.new(
				rootPart.Position.X + (flatFwd.X * dribbleDist),
				Constants.BALL_RADIUS,
				rootPart.Position.Z + (flatFwd.Z * dribbleDist)
			)
			if ballPart then
				ballPart.CFrame = CFrame.new(ballState.position)
			end
		end
		updateTeamContexts()
	else
		ballState.state = "Free"
	end
	syncBallAttributes()
end

function BallService.GetPossessorUserId(): number?
	return ballState.possessorUserId
end

function BallService.GetLastPossessingTeam(): Types.TeamSide?
	return ballState.lastPossessingTeam
end

function BallService.SetPlayerTeamSide(userId: number, teamSide: Types.TeamSide)
	local st = getOrCreatePlayerState(userId)
	st.teamSide = teamSide
	if ballState.possessorUserId == userId then
		ballState.lastPossessingTeam = teamSide
		syncBallAttributes()
	end
	updateTeamContexts()
	local player = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(player, st)
end

function BallService.GetPlayerTeamSide(userId: number): Types.TeamSide
	return getOrCreatePlayerState(userId).teamSide
end

function BallService.GetPlayerStamina(userId: number): number
	return getOrCreatePlayerState(userId).stamina
end

function BallService.SetPlayerStamina(userId: number, stamina: number)
	local st = getOrCreatePlayerState(userId)
	st.stamina = math.clamp(stamina, 0.0, 1.0)
	local player = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(player, st)
end

function BallService.GetPlayerActionContext(userId: number): Types.TeamActionContext
	return getOrCreatePlayerState(userId).actionContext
end

function BallService.IsPlayerSliding(userId: number): boolean
	return getOrCreatePlayerState(userId).isSliding
end

function BallService.IsPlayerInSlideRecovery(userId: number): boolean
	local st = getOrCreatePlayerState(userId)
	return (not st.slideHitBall) and (os.clock() < st.slideRecoveryUntil)
end

function BallService.GetPlayerGeneration(userId: number): number
	return getOrCreatePlayerState(userId).characterGeneration
end

function BallService.GetPlayerContextVersion(userId: number): number
	return getOrCreatePlayerState(userId).contextVersion
end

function BallService.GetPlayerActionSequence(userId: number): number
	return getOrCreatePlayerState(userId).actionSequence
end

function BallService.GetPlayerLastActionStatus(userId: number): (string, string)
	local st = getOrCreatePlayerState(userId)
	return st.lastActionStatus, st.lastActionReason
end

function BallService.GetPlayerMovementSnapshot(userId: number): Types.PlayerMovementSnapshot
	local st = getOrCreatePlayerState(userId)
	local now = os.clock()
	local power = if st.isCharging and st.chargeStartTime > 0
		then math.clamp((now - st.chargeStartTime) / Constants.CHARGE_TIME_MAX, Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
		else nil
	return {
		userId = st.userId,
		teamSide = st.teamSide,
		stamina = st.stamina,
		isSprinting = st.isSprinting,
		isDashing = st.isDashing,
		dashCooldownRemaining = math.max(0.0, st.dashCooldownUntil - now),
		isAirborne = st.isAirborne,
		jumpLockedVelocity = st.jumpLockedVelocity,
		actionContext = st.actionContext,
		isCharging = st.isCharging,
		chargePower = power,
		isSliding = st.isSliding,
		slideCooldownRemaining = math.max(0.0, st.slideCooldownUntil - now),
		recoveryRemaining = math.max(0.0, st.slideRecoveryUntil - now),
		characterGeneration = st.characterGeneration,
		contextVersion = st.contextVersion,
		chargeAction = st.chargeAction,
		lastResolvedAction = st.lastResolvedAction,
		actionSequence = st.actionSequence,
		resolvedKickFoot = st.resolvedKickFoot,
		resolvedCurveStyle = st.resolvedCurveStyle,
		airLeanForward = st.airLeanForward,
		airLeanRight = st.airLeanRight,
		jumpFacingF0 = st.jumpFacingF0,
	}
end

function BallService.ApplyZoneFocusBuff(userId: number, multiplier: number, durationSec: number)
	local st = getOrCreatePlayerState(userId)
	st.boostMultiplier = multiplier
	st.boostUntil = os.clock() + durationSec
end

function BallService.GetActiveBoostMultiplier(userId: number): number
	local st = getOrCreatePlayerState(userId)
	if os.clock() < st.boostUntil then
		return st.boostMultiplier
	end
	return 1.0
end

-- F-23: Single authoritative server movement speed resolver based on strict priority
function BallService.ResolvePlayerSpeed(st: PlayerMovementState): number
	local now = os.clock()
	if st.isSliding then
		return Constants.SLIDE_SPEED
	end
	if not st.slideHitBall and now < st.slideRecoveryUntil then
		return Constants.WALK_SPEED * Constants.SLIDE_WHIFF_SPEED_RATIO
	end
	if st.whiffRecoveryUntil and now < st.whiffRecoveryUntil then
		return Constants.WALK_SPEED * 0.45
	end
	if st.isDashing and now < st.dashEndTime then
		return Constants.DASH_SPEED_BURST
	end
	if st.isCharging then
		return Constants.WALK_SPEED * 0.50
	end
	if st.isSprinting and st.stamina > 0.05 then
		return Constants.SPRINT_SPEED
	end
	return Constants.WALK_SPEED
end

-- Section 4.3: Shooting Zone check
function BallService.IsInShootingZone(ballPosition: Vector3, attackingTeam: string): boolean
	if attackingTeam == "North" or attackingTeam == "TeamB" then
		return ballPosition.Z <= -10.0
	end
	return ballPosition.Z >= 10.0
end

local function isCharacterAirborne(char: Model, humanoid: Humanoid, rootPart: BasePart): boolean
	if char:GetAttribute("IsAirborne") == true or humanoid:GetAttribute("IsAirborne") == true then
		return true
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { char }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayResult = Workspace:Raycast(rootPart.Position, Vector3.new(0, -3.1, 0), rayParams)
		if not rayResult then
			return true
		end
	end
	return false
end

-- Kicking & Passing Actions (DirectShoot, CurveShoot, Pass/GroundPass, Header, Volley)
function BallService.ExecuteKick(
	player: Player | { UserId: number, Character: Model? },
	actionType: Types.KickActionType,
	aimVector: Vector3,
	chargePower: number?,
	intentId: string?,
	curveSideIntent: Types.CurveSideIntent?
): boolean
	if not Network.IsFiniteVector3(aimVector) then
		return recordActionFailure(player, intentId, "InvalidPayload")
	end

	-- LobPass has been removed per HANDOFF §6; reject without mutation
	if (actionType :: string) == "LobPass" then
		return recordActionFailure(player, intentId, "RemovedAction")
	end

	-- GroundPass is a legacy migration alias for Pass
	if actionType == "GroundPass" then
		actionType = "Pass"
	end

	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)

	-- Defending players cannot execute kicks per Spec 02 §2 & plan.md
	if st.actionContext ~= "Attacking" then
		return recordActionFailure(player, intentId, "WrongContext")
	end

	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	if not char or not char.PrimaryPart then
		return recordActionFailure(player, intentId, "NotAlive")
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return recordActionFailure(player, intentId, "NotAlive")
	end

	local rootPart = char.PrimaryPart
	local isPossessor = (ballState.possessorUserId == userId)

	-- Decoupled 3D reach check matching Sandbox prototype3 (server:832-836)
	local delta = ballState.position - rootPart.Position
	local horizDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
	local vertDist = math.abs(delta.Y)

	local isRealAirborne = (not rootPart.Anchored) and (humanoid.FloorMaterial == Enum.Material.Air) and (rootPart.Position.Y > 3.6)
	local isAirborneKicker = st.isAirborne or (st.takeoffTime > 0 and (os.clock() - st.takeoffTime) < 1.5) or isRealAirborne

	local maxHorizReach = if isAirborneKicker then (Constants.AERIAL_VOLLEY_REACH or 9.5) else (Constants.FIRST_TIME_KICK_REACH or 9.0)
	local maxVertReach = Constants.FIRST_TIME_VERT_REACH or 8.5
	local inKickRange = isPossessor or (horizDist <= maxHorizReach and vertDist <= maxVertReach)
	local isFirstTimeReachable = inKickRange and not isPossessor

	-- Whiff penalty if player kicks when ball is completely out of reach (matching prototype3:839-855)
	if not inKickRange then
		local offBallAction = actionType
		if isAirborneKicker then
			offBallAction = if actionType == "Volley" or actionType == "CurveShoot" then "Volley" else "DirectShoot"
		end
		st.whiffRecoveryUntil = os.clock() + (Constants.WHIFF_RECOVERY_SEC or 0.35)
		humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
		char:SetAttribute("LastResolvedAction", offBallAction)
		char:SetAttribute("LastActionStatus", "Rejected")
		char:SetAttribute("LastActionReason", "OutOfReach")
		char:SetAttribute("LastActionIntentId", intentId or "")
		recordActionFailure(player, intentId, "OutOfReach")
		return false
	end

	-- Authoritative charge & numeric validation (rejects NaN/Inf)
	if chargePower ~= nil then
		if type(chargePower) ~= "number" or chargePower ~= chargePower or chargePower == math.huge or chargePower == -math.huge then
			return recordActionFailure(player, intentId, "InvalidPayload")
		end
	end

	local charge = 0.5
	if st.isCharging and st.chargeStartTime > 0 then
		local elapsed = os.clock() - st.chargeStartTime
		st.isCharging = false
		st.chargeStartTime = 0
		st.chargeAction = nil
		st.chargeIntentId = nil
		charge = if elapsed < 0.12
			then Constants.CHARGE_MIN_POWER
			else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
		humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
	else
		charge = math.clamp(chargePower or 0.5, 0.0, 1.0)
	end

	local boostMult = BallService.GetActiveBoostMultiplier(userId)
	local cardCfg = RigAndCardService.GetEquippedCardConfig(userId)
	local shotMod = cardCfg.statModifiers.shotMultiplier
	local passMod = cardCfg.statModifiers.passMultiplier

	-- Power scaling from kick charging gauge matching Sandbox:
	-- Tap (50%) = 1.05x, 60% = 1.15x, 70% = 1.25x, 80% = 1.35x, 100% MAX = 1.55x!
	local powerMult = (0.55 + charge * 1.00) * shotMod * boostMult

	-- Safe 3D aim normalization (supports true 3D aim, downward smashes, and ceiling shots)
	local rawAim = aimVector
	if typeof(rawAim) ~= "Vector3" or rawAim.Magnitude < 0.001 then
		rawAim = rootPart.CFrame.LookVector
	end
	local aimDir = rawAim.Unit

	local horizAim = Vector3.new(aimDir.X, 0, aimDir.Z)
	if horizAim.Magnitude < 0.01 then
		horizAim = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z)
	end
	local horizUnit = if horizAim.Magnitude > 0.01 then horizAim.Unit else Vector3.new(0, 0, 1)

	local rightVec = Vector3.new(-horizUnit.Z, 0, horizUnit.X)
	if rightVec.Magnitude > 1e-3 then
		rightVec = rightVec.Unit
	else
		rightVec = Vector3.new(1, 0, 0)
	end

	local finalVel = Vector3.zero
	local curveForce: Vector3? = nil
	local resolvedAction = actionType

	if isAirborneKicker then
		-- AIR: LMB = DirectShoot, RMB = Volley (Owner Delta §12.2 & §12.4)
		if actionType == "DirectShoot" then
			resolvedAction = "DirectShoot"
		elseif actionType == "Volley" or actionType == "CurveShoot" or actionType == "BicycleKick" then
			resolvedAction = "Volley"
		elseif actionType == "Pass" then
			resolvedAction = "Pass"
		else
			resolvedAction = "DirectShoot"
		end
	else
		-- GROUND: LMB = DirectShoot, RMB = CurveShoot
		if not isPossessor and isFirstTimeReachable then
			if actionType == "CurveShoot" then
				resolvedAction = "CurveShoot"
			elseif actionType == "Pass" then
				resolvedAction = "Pass"
			elseif actionType == "Volley" then
				resolvedAction = "Volley"
			elseif actionType == "DirectShoot" then
				local relY = ballState.position.Y - rootPart.Position.Y
				if relY >= 2.2 then
					resolvedAction = "Header"
				elseif relY > -0.5 then
					resolvedAction = "Volley"
				else
					resolvedAction = "DirectShoot"
				end
			else
				resolvedAction = actionType
			end
		end
	end

	-- Core 3D Kick Physics Solver
	if resolvedAction == "Header" then
		local kickSpeed = Constants.HEADER_SPEED * powerMult
		local headerLaunchY = math.clamp(aimDir.Y + (if aimDir.Y < -0.1 then -0.05 else 0.04), -0.75, 0.75)
		local hScale = math.sqrt(math.max(0.15, 1 - headerLaunchY * headerLaunchY))
		finalVel = (horizUnit * hScale + Vector3.new(0, headerLaunchY, 0)).Unit * kickSpeed
	elseif resolvedAction == "Pass" then
		local passSpeed = Constants.PASS_BASE_SPEED * (0.55 + charge * 1.00) * passMod * boostMult
		if aimDir.Y < -0.14 and ballState.position.Y <= Constants.BALL_RADIUS + 0.35 then
			local bounceUp = math.abs(aimDir.Y) * passSpeed * (Constants.FLOOR_SMASH_RESTITUTION or 0.84) * 1.15
			local forwardSpeed = math.sqrt(math.max(0.15, 1 - aimDir.Y * aimDir.Y)) * passSpeed * 0.95
			finalVel = horizUnit * forwardSpeed + Vector3.new(0, bounceUp, 0)
		else
			local launchY = math.clamp(aimDir.Y + Constants.PASS_UPWARD_BIAS, 0.0, 0.82)
			local horizScale = math.sqrt(math.max(0.15, 1 - launchY * launchY))
			finalVel = (horizUnit * horizScale + Vector3.new(0, launchY, 0)).Unit * passSpeed
		end
	else
		local kickSpeed = Constants.SHOOT_STRAIGHT_SPEED * powerMult
		local upwardBias = Constants.SHOOT_STRAIGHT_UPWARD_BIAS or 0.05

		if resolvedAction == "Volley" then
			kickSpeed = Constants.AERIAL_VOLLEY_SPEED * powerMult
			upwardBias = 0.04
		elseif resolvedAction == "BicycleKick" then
			kickSpeed = Constants.BICYCLE_KICK_SPEED * powerMult
			upwardBias = 0.05
			curveForce = nil
		elseif resolvedAction == "CurveShoot" then
			local curveRes = PlayerActionPoseConfigs.ResolveCurveShot(rootPart.CFrame, horizUnit, ballState.position, curveSideIntent)
			st.resolvedKickFoot = curveRes.foot
			st.resolvedCurveStyle = curveRes.style
			kickSpeed = curveRes.speed * powerMult
			upwardBias = curveRes.upwardBias
			curveForce = rightVec * (curveRes.spinY * curveRes.magnusFactor * (0.6 + (charge * 0.4)))
		end

		if isAirborneKicker then
			-- Airborne Shot: Lean Trajectory Deflection & Physical Spin (Owner Delta §12.5–12.6)
			local F0 = st.jumpFacingF0 or horizUnit
			local leanFwd = st.airLeanForward or 0.0
			local leanRgt = st.airLeanRight or 0.0
			local elevationAngle = math.asin(math.clamp(aimDir.Y, -0.99, 0.99))

			local airVel, spinVec = AirLeanSolver.ComputeAirShotTrajectory(
				F0,
				elevationAngle,
				kickSpeed,
				upwardBias * kickSpeed,
				leanFwd,
				leanRgt,
				resolvedAction
			)
			finalVel = airVel
			if spinVec.Magnitude > 0.01 then
				curveForce = if curveForce then curveForce + spinVec else spinVec
			end
			-- Reset accepted lean snapshot upon ball release
			st.airLeanForward = 0.0
			st.airLeanRight = 0.0
		else
			-- Ground Shot: Downward Floor Smash Rebound (Sandbox: aimDir.Y < -0.16)
			if aimDir.Y < -0.16 and ballState.position.Y <= Constants.BALL_RADIUS + 0.35 then
				local bounceUp = math.abs(aimDir.Y) * kickSpeed * (Constants.FLOOR_SMASH_RESTITUTION or 0.84)
				local fwd = math.sqrt(math.max(0.2, 1 - aimDir.Y * aimDir.Y)) * kickSpeed
				finalVel = horizUnit * fwd + Vector3.new(0, bounceUp, 0)
			else
				local launchY = math.clamp(aimDir.Y + upwardBias, -0.65, 0.82)
				local horizScale = math.sqrt(math.max(0.15, 1 - launchY * launchY))
				local launchDir = (horizUnit * horizScale + Vector3.new(0, launchY, 0)).Unit
				finalVel = launchDir * kickSpeed
			end
		end
	end

	-- Elevating Ramp boost if kicker is standing on a ramp
	local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(rootPart.Position)
	finalVel = CagePhysicsService.ApplyRampImpulse(finalVel, isOnRamp)

	if not Network.IsFiniteVector3(finalVel) then
		return recordActionFailure(player, intentId, "InvalidPayload")
	end
	if curveForce and not Network.IsFiniteVector3(curveForce) then
		return recordActionFailure(player, intentId, "InvalidPayload")
	end

	ballState.possessorUserId = nil
	ballState.state = "InFlight"
	ballState.lastKickerUserId = userId
	ballState.lastKickTime = os.clock()
	ballState.lastPossessingTeam = st.teamSide
	ballState.velocity = finalVel
	ballState.curveImpulse = curveForce
	ballState.inFlightAction = resolvedAction

	updateTeamContexts()
	syncBallAttributes()
	recordActionSuccess(player, intentId, resolvedAction)
	return true
end

-- Defensive Slide Tackle Action (adapted from prototype3, grounded only, no auto-possession)
function BallService.ExecuteSlide(
	player: Player | { UserId: number, Character: Model? },
	aimVector: Vector3?,
	chargePower: number?,
	intentId: string?
): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	local now = os.clock()

	-- Defending context only
	if st.actionContext ~= "Defending" then
		return recordActionFailure(player, intentId, "WrongContext")
	end

	-- Cannot slide while possessing ball
	if ballState.possessorUserId == userId then
		return recordActionFailure(player, intentId, "WrongContext")
	end

	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	if not char or not char.PrimaryPart then
		return recordActionFailure(player, intentId, "NotAlive")
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return recordActionFailure(player, intentId, "NotAlive")
	end

	local rootPart = char.PrimaryPart

	-- Airborne check (cannot slide in mid-air)
	if isCharacterAirborne(char, humanoid, rootPart) or st.isAirborne then
		return recordActionFailure(player, intentId, "InvalidPayload")
	end

	-- Already sliding check
	if st.isSliding then
		return recordActionFailure(player, intentId, "Cooldown")
	end

	-- Recovery check
	if now < st.slideRecoveryUntil then
		return recordActionFailure(player, intentId, "Recovery")
	end

	-- Cooldown check
	if now < st.slideCooldownUntil then
		return recordActionFailure(player, intentId, "Cooldown")
	end

	-- Stamina check
	if st.stamina < Constants.SLIDE_STAMINA_COST then
		return recordActionFailure(player, intentId, "InsufficientStamina")
	end

	-- Deduct stamina
	st.stamina = math.max(0.0, st.stamina - Constants.SLIDE_STAMINA_COST)

	-- Charge calculation
	local charge = Constants.CHARGE_MIN_POWER
	if st.isCharging and st.chargeStartTime > 0 then
		local elapsed = now - st.chargeStartTime
		st.isCharging = false
		st.chargeStartTime = 0
		st.chargeAction = nil
		st.chargeIntentId = nil
		st.chargeGeneration = 0
		st.chargeContextVersion = 0
		charge = if elapsed < 0.12
			then Constants.CHARGE_MIN_POWER
			else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
	else
		charge = math.clamp(chargePower or Constants.CHARGE_MIN_POWER, Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
	end

	local speedScale = 0.75 + charge * 0.50
	local durationScale = 0.85 + charge * 0.30

	-- Slide direction
	local slideDir: Vector3
	if aimVector and aimVector.Magnitude > 0.05 and Network.IsFiniteVector3(aimVector) then
		local flat = Vector3.new(aimVector.X, 0, aimVector.Z)
		slideDir = if flat.Magnitude > 0.05 then flat.Unit else rootPart.CFrame.LookVector
	elseif humanoid.MoveDirection.Magnitude > 0.05 then
		slideDir = humanoid.MoveDirection.Unit
	else
		slideDir = rootPart.CFrame.LookVector
	end
	slideDir = Vector3.new(slideDir.X, 0, slideDir.Z).Unit

	st.isSliding = true
	st.slideStartTime = now
	st.slideEndTime = now + (Constants.SLIDE_DURATION_SEC * durationScale)
	st.slideCooldownUntil = now + Constants.SLIDE_COOLDOWN_SEC
	st.slideRecoveryUntil = st.slideEndTime + Constants.SLIDE_RECOVERY_SEC
	st.slideDir = slideDir
	st.slideCharge = charge
	st.slideHitBall = false

	-- Apply slide impulse to rootPart & set WalkSpeed
	local curSlideSpeed = Constants.SLIDE_SPEED * speedScale
	humanoid.WalkSpeed = curSlideSpeed
	rootPart.AssemblyLinearVelocity = Vector3.new(
		slideDir.X * curSlideSpeed,
		rootPart.AssemblyLinearVelocity.Y,
		slideDir.Z * curSlideSpeed
	)

	-- Check contact with ball / possessor immediately
	local distToBall = (rootPart.Position - ballState.position).Magnitude
	if distToBall <= Constants.SLIDE_TACKLE_REACH then
		st.slideHitBall = true
		st.slideRecoveryUntil = 0
		ballState.possessorUserId = nil
		ballState.state = "InFlight"
		-- Slide kick strikes the ball away per §6.3 (no auto-possession, no auto-stun)
		ballState.velocity = (slideDir * Constants.SLIDE_KICK_SPEED) + Vector3.new(0, 4.0, 0)
		-- F-20: Slide hitting ball MUST NOT change lastPossessingTeam or call updateTeamContexts!
		ballState.lastKickerUserId = userId
		ballState.lastKickTime = now
		ballState.inFlightAction = "DirectShoot"
		syncBallAttributes()
	end

	recordActionSuccess(player, intentId, "Slide")
	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return true
end

function BallService.ExecuteSprint(player: Player | { UserId: number, Character: Model? }, isSprinting: boolean): boolean
	local st = getOrCreatePlayerState(player.UserId)
	local char = getPlayerCharacter(player.UserId) or (player :: any).Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local p = Players:GetPlayerByUserId(player.UserId)

	if isSprinting then
		if st.stamina > 0.05 then
			st.isSprinting = true
			if humanoid then
				humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
			end
			syncPlayerAttributes(p, st)
			return true
		end
		st.isSprinting = false
		if humanoid then
			humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
		end
		syncPlayerAttributes(p, st)
		return false
	else
		st.isSprinting = false
		if humanoid then
			humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
		end
		syncPlayerAttributes(p, st)
		return true
	end
end

function BallService.ExecuteDash(player: Player | { UserId: number, Character: Model? }, moveDirection: Vector3?): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	local now = os.clock()

	-- Mid-air dash is prohibited to preserve Directional Jump trajectory (F-15)
	if st.isAirborne then
		return false
	end
	-- F-23: Dash during slide or slide recovery is strictly rejected
	if st.isSliding or now < st.slideRecoveryUntil then
		return false
	end
	-- Cannot dash while charging kick
	if st.isCharging then
		return false
	end
	if st.stamina < Constants.DASH_STAMINA_COST then
		return false
	end
	if now < st.dashCooldownUntil then
		return false
	end

	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	if not char or not char.PrimaryPart then
		return false
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Walking/falling off an edge or air material cannot initiate dash (F-15)
	if isCharacterAirborne(char, humanoid, char.PrimaryPart) then
		return false
	end

	local rootPart = char.PrimaryPart
	local dir = if moveDirection and moveDirection.Magnitude > 1e-3
		then moveDirection.Unit
		else rootPart.CFrame.LookVector
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	dir = if flatDir.Magnitude > 1e-3 then flatDir.Unit else Vector3.new(0, 0, 1)

	st.stamina = math.max(0.0, st.stamina - Constants.DASH_STAMINA_COST)
	st.lastStaminaUseTime = now
	st.isDashing = true
	st.dashEndTime = now + Constants.DASH_DURATION_SEC
	st.dashCooldownUntil = now + Constants.DASH_COOLDOWN_SEC

	humanoid.WalkSpeed = Constants.DASH_SPEED_BURST
	-- Apply impulse velocity
	rootPart.AssemblyLinearVelocity = Vector3.new(dir.X * Constants.DASH_SPEED_BURST, rootPart.AssemblyLinearVelocity.Y, dir.Z * Constants.DASH_SPEED_BURST)

	-- Knock-on dash if currently holding ball (prototype3 mechanism)
	if ballState.possessorUserId == userId then
		ballState.velocity = rootPart.AssemblyLinearVelocity
		local knockOnPos = rootPart.Position + (dir * (Constants.BALL_COLLECT_RADIUS - 0.5))
		ballState.position = Vector3.new(knockOnPos.X, Constants.BALL_RADIUS, knockOnPos.Z)
	end

	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return true
end

function BallService.ExecuteDirectionalJump(player: Player | { UserId: number, Character: Model? }, jumpDirection: Vector3): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	local now = os.clock()

	-- Directional jump cannot alter trajectory once airborne per Spec 02 §1 & F-15
	if st.isAirborne then
		return false
	end

	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	if not char or not char.PrimaryPart then
		return false
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	-- Cannot initiate jump while already falling in air (F-15 edge fall)
	if isCharacterAirborne(char, humanoid, char.PrimaryPart) then
		return false
	end

	local rootPart = char.PrimaryPart
	local isStationaryJump = (jumpDirection.Magnitude <= 0.08)
	local flatDir = Vector3.new(jumpDirection.X, 0, jumpDirection.Z)
	local dir = if flatDir.Magnitude > 0.08 then flatDir.Unit else Vector3.zero

	st.isAirborne = true
	st.takeoffTime = now
	st.jumpFacingF0 = if dir.Magnitude > 0.08 then dir else Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit
	st.airLeanForward = 0.0
	st.airLeanRight = 0.0
	st.lastAirLeanTime = now

	if isStationaryJump then
		st.jumpLockedVelocity = nil
	else
		local horizSpeed = if st.isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
		st.jumpLockedVelocity = dir * horizSpeed
	end

	-- For mock players or server physics where Humanoid JumpPower is not simulated by client:
	local isMockPlayer = (typeof(player) == "table") or (not (typeof(player) == "Instance" and player:IsA("Player")))
	if isMockPlayer and rootPart and st.jumpLockedVelocity then
		local currentVY = rootPart.AssemblyLinearVelocity.Y
		local vertY = if currentVY > 1.0 then currentVY else (Constants.DIRECTIONAL_JUMP_VERTICAL_SPEED or 56.0)
		rootPart.AssemblyLinearVelocity = Vector3.new(st.jumpLockedVelocity.X, vertY, st.jumpLockedVelocity.Z)
	end

	-- If possessing ball, jumping drops ball into free/loose ball (matching Sandbox prototype3:1717)
	if ballState.possessorUserId == userId then
		ballState.possessorUserId = nil
		ballState.state = "Free"
		ballState.lastPossessingTeam = st.teamSide
		syncBallAttributes()
		updateTeamContexts()
	end

	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return true
end

function BallService.StartCharge(
	player: Player | { UserId: number, Character: Model? },
	chargeAction: Types.ChargeActionType?,
	intentId: string?
): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	local action = chargeAction or "DirectShoot"

	-- F-14: Reject starting a charge if another charge is already active
	if st.isCharging then
		return recordActionFailure(player, intentId, "StaleIntent")
	end

	if action == "Slide" then
		if st.actionContext ~= "Defending" then
			return recordActionFailure(player, intentId, "WrongContext")
		end
		if ballState.possessorUserId == userId then
			return recordActionFailure(player, intentId, "WrongContext")
		end
		if st.stamina < Constants.SLIDE_STAMINA_COST then
			return recordActionFailure(player, intentId, "InsufficientStamina")
		end
		local now = os.clock()
		if now < st.slideCooldownUntil then
			return recordActionFailure(player, intentId, "Cooldown")
		end
		if now < st.slideRecoveryUntil then
			return recordActionFailure(player, intentId, "Recovery")
		end
	else
		if st.actionContext ~= "Attacking" then
			return recordActionFailure(player, intentId, "WrongContext")
		end
	end

	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return recordActionFailure(player, intentId, "NotAlive")
	end

	st.isCharging = true
	st.chargeStartTime = os.clock()
	st.chargeAction = action
	st.chargeIntentId = intentId
	st.chargeGeneration = st.characterGeneration
	st.chargeContextVersion = st.contextVersion
	humanoid.WalkSpeed = Constants.WALK_SPEED * 0.50
	recordActionSuccess(player, intentId, "StartCharge")
	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return true
end

function BallService.CancelCharge(player: Player | { UserId: number, Character: Model? }, intentId: string?): boolean
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)
	local resolvedIntentId = intentId or st.chargeIntentId
	if resolvedIntentId then
		st.terminalIntents[resolvedIntentId] = true
	end
	st.isCharging = false
	st.chargeStartTime = 0
	st.chargeAction = nil
	st.chargeIntentId = nil
	st.chargeGeneration = 0
	st.chargeContextVersion = 0
	local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
	end
	st.lastActionStatus = "Cancelled"
	st.lastActionReason = ""
	if resolvedIntentId then
		st.lastActionIntentId = resolvedIntentId
	end
	local p = Players:GetPlayerByUserId(userId)
	syncPlayerAttributes(p, st)
	return true
end

function BallService.ResetBall(customPos: Vector3?, initialPossessingTeam: Types.TeamSide?)
	for _, st in pairs(playerStates) do
		if st.isCharging then
			if st.chargeIntentId then
				st.terminalIntents[st.chargeIntentId] = true
			end
			st.isCharging = false
			st.chargeStartTime = 0
			st.chargeAction = nil
			st.chargeIntentId = nil
			st.lastActionStatus = "Cancelled"
			st.lastActionReason = "Reset"
			local char = getPlayerCharacter(st.userId)
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				hum.WalkSpeed = if st.isSprinting and st.stamina > 0.05 then Constants.SPRINT_SPEED else Constants.WALK_SPEED
			end
		end
		st.isSliding = false
		st.slideHitBall = false
		st.contextVersion += 1
		local p = Players:GetPlayerByUserId(st.userId)
		syncPlayerAttributes(p, st)
	end

	local pos = customPos or Constants.BALL_SPAWN_POSITION or Vector3.new(0, Constants.BALL_RADIUS, 0)
	ballState.position = pos
	ballState.velocity = Vector3.zero
	ballState.state = "Free"
	ballState.possessorUserId = nil
	ballState.lastPossessingTeam = initialPossessingTeam
	ballState.lastKickerUserId = nil
	ballState.lastKickTime = 0
	ballState.curveImpulse = nil
	ballState.inFlightAction = nil
	if ballPart then
		ballPart.CFrame = CFrame.new(pos)
	end
	updateTeamContexts()
	syncBallAttributes()
end

function BallService.StepPhysics(dt: number)
	local now = os.clock()

	-- 1. Step Player Stamina & Movement States
	for userId, st in pairs(playerStates) do
		local char = getPlayerCharacter(userId)
		local rootPart = char and char.PrimaryPart
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")

		if st.isDashing then
			if now >= st.dashEndTime then
				st.isDashing = false
				if humanoid then
					humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
				end
			end
		end

		if st.isSprinting then
			st.stamina = math.max(0.0, st.stamina - (Constants.SPRINT_STAMINA_DRAIN_PER_SEC * dt))
			st.lastStaminaUseTime = now
			if st.stamina <= 0.02 then
				st.isSprinting = false
				if humanoid then
					humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
				end
			end
		else
			if now - (st.lastStaminaUseTime or 0) > Constants.STAMINA_RECOVERY_DELAY_SEC then
				st.stamina = math.min(1.0, st.stamina + (Constants.STAMINA_REGEN_PER_SEC * dt))
			end
		end

		-- Directional Jump airborne & landing lifecycle (F-15)
		if st.isAirborne then
			if rootPart and humanoid then
				local takeoffPassed = (now - st.takeoffTime) > 0.18
				local isDescending = rootPart.AssemblyLinearVelocity.Y <= 0.5
				local isLanded = false
				if takeoffPassed then
					if rootPart.Position.Y <= 2.25 or CagePhysicsService.IsPositionOnElevatingRamp(rootPart.Position) then
						isLanded = true
					elseif isDescending then
						if humanoid.FloorMaterial ~= Enum.Material.Air then
							isLanded = true
						else
							local rayParams = RaycastParams.new()
							local char = getPlayerCharacter(userId)
							if char then rayParams.FilterDescendantsInstances = { char } end
							rayParams.FilterType = Enum.RaycastFilterType.Exclude
							local footPos = rootPart.Position - Vector3.new(0, 2.0, 0)
							local rayResult = Workspace:Raycast(footPos, Vector3.new(0, -0.9, 0), rayParams)
							if rayResult then
								isLanded = true
							end
						end
					end
				end

				if not isLanded then
					local playerObj = Players:GetPlayerByUserId(userId)
					local isRealPlayer = (playerObj ~= nil and playerObj:IsA("Player"))
					if not isRealPlayer and st.jumpLockedVelocity and rootPart then
						rootPart.AssemblyLinearVelocity = Vector3.new(
							st.jumpLockedVelocity.X,
							rootPart.AssemblyLinearVelocity.Y,
							st.jumpLockedVelocity.Z
						)
					end
				else
					st.isAirborne = false
					st.jumpLockedVelocity = nil
					st.jumpFacingF0 = nil
					st.airLeanForward = 0.0
					st.airLeanRight = 0.0
				end
			end
		end

		if st.isSliding then
			if now >= st.slideEndTime then
				st.isSliding = false
				if humanoid and humanoid.Health > 0 then
					humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
				end
			else
				-- Continuous slide tackle contact during active slide window (only once per slide!)
				if rootPart and not st.slideHitBall then
					local distToBall = (rootPart.Position - ballState.position).Magnitude
					if distToBall <= Constants.SLIDE_TACKLE_REACH then
						st.slideHitBall = true
						st.slideRecoveryUntil = 0
						ballState.possessorUserId = nil
						ballState.state = "InFlight"
						ballState.velocity = (st.slideDir * Constants.SLIDE_KICK_SPEED) + Vector3.new(0, 4.0, 0)
						-- F-20: Slide hitting ball MUST NOT change lastPossessingTeam or call updateTeamContexts!
						ballState.lastKickerUserId = userId
						ballState.lastKickTime = now
						ballState.inFlightAction = "DirectShoot"
						syncBallAttributes()
					end
				end
			end
		elseif not st.slideHitBall and now < st.slideRecoveryUntil then
			-- In recovery wait: slowed down
			if humanoid and humanoid.Health > 0 then
				humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
			end
		elseif not st.slideHitBall and now >= st.slideRecoveryUntil and (now - dt) < st.slideRecoveryUntil then
			-- Finished recovery: restore walkspeed
			if humanoid and humanoid.Health > 0 then
				humanoid.WalkSpeed = BallService.ResolvePlayerSpeed(st)
			end
		end

		if now >= st.boostUntil then
			st.boostMultiplier = 1.0
		end

		local player = Players:GetPlayerByUserId(userId)
		syncPlayerAttributes(player, st)
	end

	-- 2. Step Ball Position & Possession
	if ballState.state == "Possessed" and ballState.possessorUserId ~= nil then
		local char = getPlayerCharacter(ballState.possessorUserId)
		local rootPart = char and char.PrimaryPart
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")

		if not char or not rootPart or not humanoid or humanoid.Health <= 0 then
			-- Possessor lost or dead; release ball
			ballState.possessorUserId = nil
			ballState.state = "Free"
		else
			local st = getOrCreatePlayerState(ballState.possessorUserId)
			local dribbleDist = if st.stamina < Constants.STAMINA_EXHAUSTED_THRESHOLD
				then math.abs(Constants.BALL_DRIBBLE_EXHAUSTED_OFFSET_Z)
				else math.abs(Constants.BALL_DRIBBLE_OFFSET_Z)

			local fwd = rootPart.CFrame.LookVector
			local flatFwd = Vector3.new(fwd.X, 0, fwd.Z)
			flatFwd = if flatFwd.Magnitude > 1e-3 then flatFwd.Unit else Vector3.new(0, 0, 1)

			local groundY = Constants.BALL_RADIUS
			local targetY = groundY
			if rootPart.Position.Y > 3.5 then
				targetY = math.max(groundY, rootPart.Position.Y - 1.75)
			end

			local targetPos = Vector3.new(
				rootPart.Position.X + (flatFwd.X * dribbleDist),
				targetY,
				rootPart.Position.Z + (flatFwd.Z * dribbleDist)
			)
			ballState.position = targetPos
			ballState.velocity = rootPart.AssemblyLinearVelocity

			-- F-10: Continuous player contact during possession / dash
			local possTeam = st.teamSide
			for otherUserId, otherSt in pairs(playerStates) do
				if otherUserId ~= ballState.possessorUserId and otherSt.teamSide ~= possTeam then
					local otherChar = getPlayerCharacter(otherUserId)
					local otherRoot = otherChar and otherChar.PrimaryPart
					local otherHum = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
					if otherRoot and otherHum and otherHum.Health > 0 then
						local dist = (otherRoot.Position - targetPos).Magnitude
						if dist <= (Constants.BALL_COLLECT_RADIUS - 0.5) then
							-- Defending player tackles/contests possession
							BallService.SetPossessor(otherUserId)
							break
						end
					end
				end
			end
		end
	else
		-- Free or InFlight Ball
		local r = Constants.BALL_RADIUS
		local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)
		local onGround = not isOnRamp and (ballState.position.Y <= r + 0.08) and (math.abs(ballState.velocity.Y) < 3.0)

		if ballState.curveImpulse ~= nil then
			ballState.velocity = ballState.velocity + (ballState.curveImpulse * dt)
			ballState.curveImpulse = ballState.curveImpulse * math.max(0.0, 1.0 - (1.5 * dt))
		end

		local currentVel = ballState.velocity
		if onGround then
			-- Suppress vertical downward gravity when resting on turf (prevents perpetual elastic micro-bouncing)
			currentVel = Vector3.new(currentVel.X, 0, currentVel.Z)
			ballState.position = Vector3.new(ballState.position.X, r, ballState.position.Z)
		else
			currentVel = currentVel + Vector3.new(0, Constants.GRAVITY_ACCELERATION_Y * dt, 0)
			currentVel = currentVel * math.max(0.0, 1.0 - (0.20 * dt))
		end

		local prevPos = ballState.position
		local nextPos, nextVel = CagePhysicsService.StepBallCageCollision(prevPos, currentVel, dt)

		-- Turf contact & rolling friction (prototype3 mechanism & F-24 fix)
		if onGround or (not isOnRamp and nextPos.Y <= (r + 0.08)) then
			if nextVel.Y > 1.5 then
				-- F-24: High upward rebound from floor collision! Preserve upward bounce velocity
			elseif nextVel.Y < -3.5 then
				-- High downward velocity before bounce sub-step
			else
				-- Low vertical velocity: settle cleanly on turf
				nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
				nextVel = Vector3.new(nextVel.X, 0, nextVel.Z)
			end

			-- Turf rolling friction
			local frictionDecel = math.max(0.0, 1.0 - (Constants.GROUND_ROLLING_FRICTION * dt))
			nextVel = Vector3.new(nextVel.X * frictionDecel, nextVel.Y, nextVel.Z * frictionDecel)

			if nextVel.Magnitude < Constants.BALL_REST_THRESHOLD_SPEED then
				nextVel = Vector3.zero
				nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
				ballState.state = "Free"
				ballState.inFlightAction = nil
			end
		end

		-- F-10 & F-11: Swept contact and relative body height check (no 0.3s global immunity!)
		local seg = nextPos - prevPos
		local segLenSq = seg:Dot(seg)
		local ballSpeed = nextVel.Magnitude

		for userId, st in pairs(playerStates) do
			local isKickerCooldown = (userId == ballState.lastKickerUserId and (now - ballState.lastKickTime) < 0.22)
			if not isKickerCooldown then
				local char = getPlayerCharacter(userId)
				local rootPart = char and char.PrimaryPart
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if rootPart and humanoid and humanoid.Health > 0 then
					local t = if segLenSq > 1e-6 then math.clamp((rootPart.Position - prevPos):Dot(seg) / segLenSq, 0.0, 1.0) else 0.0
					local closestPt = prevPos + (seg * t)

					local playerBaseY = rootPart.Position.Y - 2.0
					local playerHeadY = rootPart.Position.Y + 2.5
					local inVerticalReach = (closestPt.Y >= playerBaseY and closestPt.Y <= playerHeadY)
					local horizDist = Vector2.new(closestPt.X - rootPart.Position.X, closestPt.Z - rootPart.Position.Z).Magnitude

					if inVerticalReach and horizDist <= Constants.BALL_COLLECT_RADIUS then
						if ballSpeed > 65.0 then
							-- High speed ball / aerial jump block deflects off player (reversing incoming direction)
							local incomingDir = if nextVel.Magnitude > 1e-3
								then nextVel.Unit
								else (if segLenSq > 1e-6 then seg.Unit else Vector3.new(0, 0, 1))
							local bounceBack = Vector3.new(-incomingDir.X, 0, -incomingDir.Z)
							local deflectDir = if bounceBack.Magnitude > 1e-3
								then bounceBack.Unit
								else (if rootPart then -rootPart.CFrame.LookVector else Vector3.new(0, 0, 1))
							nextVel = (deflectDir * (ballSpeed * 0.65)) + Vector3.new(0, 10.0, 0)
							nextPos = closestPt + (deflectDir * (Constants.BALL_RADIUS + 0.1))
							ballState.curveImpulse = nil
							ballState.inFlightAction = nil
							ballState.state = "Free"
						else
							BallService.SetPossessor(userId)
						end
						break
					end
				end
			end
		end

		ballState.position = nextPos
		ballState.velocity = nextVel
	end

	if ballPart then
		ballPart.CFrame = CFrame.new(ballState.position)
	end
	syncBallAttributes()
end

local function setupPlayerLifecycle(player: Player)
	local userId = player.UserId
	getOrCreatePlayerState(userId)
	updateTeamContexts()

	local function onCharAdded(char: Model)
		local st = getOrCreatePlayerState(userId)
		st.characterGeneration += 1
		st.contextVersion += 1
		local localGen = st.characterGeneration
		st.stamina = 1.0
		st.lastStaminaUseTime = 0
		st.isSprinting = false
		st.isDashing = false
		st.isAirborne = false
		st.jumpFacingF0 = nil
		st.airLeanForward = 0.0
		st.airLeanRight = 0.0
		st.isSliding = false
		st.slideHitBall = false
		st.isCharging = false
		st.chargeStartTime = 0
		st.chargeAction = nil
		st.chargeIntentId = nil
		st.chargeGeneration = 0
		st.chargeContextVersion = 0
		st.jumpLockedVelocity = nil
		st.dashCooldownUntil = 0
		st.slideCooldownUntil = 0
		st.slideRecoveryUntil = 0
		table.clear(st.processedIntents)
		table.clear(st.terminalIntents)

		local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
		-- F-16 Post-yield guard: if character was destroyed or superseded during WaitForChild, abort
		if player.Character ~= char or st.characterGeneration ~= localGen then
			return
		end

		if humanoid then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = Constants.HIGH_JUMP_POWER or 72.0
			humanoid.JumpHeight = Constants.HIGH_JUMP_HEIGHT or 15.5

			local diedConn: RBXScriptConnection? = nil
			diedConn = humanoid.Died:Connect(function()
				if diedConn then
					diedConn:Disconnect()
					diedConn = nil
				end
				-- F-16 Guard: only mutate state if it matches this character generation!
				if player.Character ~= char or st.characterGeneration ~= localGen then
					return
				end

				if ballState.possessorUserId == userId then
					ballState.possessorUserId = nil
					ballState.state = "Free"
					syncBallAttributes()
				end
				local curSt = playerStates[userId]
				if curSt and curSt.characterGeneration == localGen then
					curSt.isSprinting = false
					curSt.isDashing = false
					curSt.isAirborne = false
					curSt.jumpFacingF0 = nil
					curSt.airLeanForward = 0.0
					curSt.airLeanRight = 0.0
					curSt.isSliding = false
					curSt.slideHitBall = false
					if curSt.isCharging then
						if curSt.chargeIntentId then
							curSt.terminalIntents[curSt.chargeIntentId] = true
						end
						curSt.isCharging = false
						curSt.chargeStartTime = 0
						curSt.chargeAction = nil
						curSt.chargeIntentId = nil
						curSt.chargeGeneration = 0
						curSt.chargeContextVersion = 0
					end
					curSt.jumpLockedVelocity = nil
					curSt.lastActionStatus = "Cancelled"
					curSt.lastActionReason = "NotAlive"
					curSt.contextVersion += 1
					syncPlayerAttributes(player, curSt)
				end
			end)
		end
		updateTeamContexts()
		syncPlayerAttributes(player, st)
	end

	if player.Character then
		task.spawn(onCharAdded, player.Character)
	end
	player.CharacterAdded:Connect(onCharAdded)
	player.CharacterRemoving:Connect(function(removingChar: Model)
		local st = playerStates[userId]
		if st and player.Character == removingChar then
			if ballState.possessorUserId == userId then
				ballState.possessorUserId = nil
				ballState.state = "Free"
				syncBallAttributes()
			end
		end
	end)
end

function BallService.HandleActionRequest(player: Player | { UserId: number, Character: Model? }, actionPayload: any, maybeAim: any, maybeCharge: any)
	local now = os.clock()
	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)

	-- F-13: Strict schema validation. Reject non-table, missing metadata, non-finite values.
	if type(actionPayload) ~= "table" then
		recordActionFailure(player, nil, "InvalidPayload")
		return
	end

	local rawIntentId = actionPayload.intentId
	if type(rawIntentId) ~= "string" or #rawIntentId < 1 or #rawIntentId > 64 then
		recordActionFailure(player, nil, "InvalidPayload")
		return
	end
	local intentId: string = rawIntentId

	local rawGen = actionPayload.characterGeneration
	if type(rawGen) ~= "number" or rawGen ~= math.floor(rawGen) or rawGen < 0 or rawGen ~= rawGen or rawGen == math.huge or rawGen == -math.huge then
		recordActionFailure(player, intentId, "InvalidPayload")
		return
	end

	local rawCtxVer = actionPayload.contextVersion
	if type(rawCtxVer) ~= "number" or rawCtxVer ~= math.floor(rawCtxVer) or rawCtxVer < 0 or rawCtxVer ~= rawCtxVer or rawCtxVer == math.huge or rawCtxVer == -math.huge then
		recordActionFailure(player, intentId, "InvalidPayload")
		return
	end

	local rawPhase = actionPayload.phase
	if rawPhase ~= nil and rawPhase ~= "start" and rawPhase ~= "release" and rawPhase ~= "cancel" then
		recordActionFailure(player, intentId, "InvalidPayload")
		return
	end
	local phase: "start" | "release" | "cancel" = rawPhase or "start"

	-- Aim direction validation: if provided, must be finite Vector3
	local aim = Vector3.zero
	if actionPayload.aimDirection ~= nil then
		if typeof(actionPayload.aimDirection) ~= "Vector3" or not Network.IsFiniteVector3(actionPayload.aimDirection) then
			recordActionFailure(player, intentId, "InvalidPayload")
			return
		end
		aim = actionPayload.aimDirection
	end

	-- Charge value validation: if provided, must be finite number
	if actionPayload.charge ~= nil then
		if type(actionPayload.charge) ~= "number" or actionPayload.charge ~= actionPayload.charge or actionPayload.charge == math.huge or actionPayload.charge == -math.huge then
			recordActionFailure(player, intentId, "InvalidPayload")
			return
		end
	end

	local act = actionPayload.action
	if act == "LobPass" then
		recordActionFailure(player, intentId, "RemovedAction")
		return
	end

	local allowedActions = {
		Sprint = true,
		StopSprint = true,
		Dash = true,
		DirectionalJump = true,
		StartCharge = true,
		CancelCharge = true,
		DirectShoot = true,
		Shoot = true,
		CurveShoot = true,
		Pass = true,
		GroundPass = true,
		Slide = true,
		ResetBall = true,
		Volley = true,
		BicycleKick = true,
		AcrobaticFinishing = true,
		SetAirLean = true,
	}
	if not allowedActions[act] then
		recordActionFailure(player, intentId, "InvalidPayload")
		return
	end

	-- Generation & Context Staleness check
	if rawGen ~= st.characterGeneration or rawCtxVer ~= st.contextVersion then
		recordActionFailure(player, intentId, "StaleIntent")
		return
	end

	-- Terminal intent check: rejected after terminal phase
	if st.terminalIntents[intentId] == true then
		recordActionFailure(player, intentId, "StaleIntent")
		return
	end

	-- Canonical action mapping
	local canonicalAct = act
	if act == "GroundPass" then canonicalAct = "Pass"
	elseif act == "Shoot" then canonicalAct = "DirectShoot"
	end

	if canonicalAct == "SetAirLean" then
		local char = getPlayerCharacter(userId) or (if typeof(player) == "Instance" and player:IsA("Player") then player.Character else (player :: any).Character)
		if not char or not char.PrimaryPart then
			return
		end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
		if not st.isAirborne then
			return
		end

		local prevTime = st.lastAirLeanTime or 0
		if (now - prevTime) < (Constants.AIR_LEAN_MIN_UPDATE_INTERVAL or 0.045) then
			return
		end

		local rawFwd = actionPayload.airLeanForward
		local rawRight = actionPayload.airLeanRight
		if typeof(rawFwd) ~= "number" or typeof(rawRight) ~= "number" then
			return
		end
		if rawFwd ~= rawFwd or rawRight ~= rawRight or math.abs(rawFwd) == math.huge or math.abs(rawRight) == math.huge then
			return
		end

		local f, r = AirLeanSolver.ClampLeanInput(rawFwd, rawRight)
		local dt = math.clamp(now - prevTime, 0.0, 0.2)
		local currF = st.airLeanForward or 0.0
		local currR = st.airLeanRight or 0.0
		local nextF, nextR = AirLeanSolver.SlewLean(currF, currR, f, r, dt)

		st.airLeanForward = nextF
		st.airLeanRight = nextR
		st.lastAirLeanTime = now
		return
	end

	-- F-14: Charge / Intent Latch & Lifecycle
	st.processedIntents[intentId] = st.processedIntents[intentId] or {}

	local isInstant = (canonicalAct == "Sprint" or canonicalAct == "StopSprint" or canonicalAct == "Dash" or canonicalAct == "DirectionalJump" or canonicalAct == "ResetBall")

	if phase == "start" then
		if st.processedIntents[intentId]["start"] or st.processedIntents[intentId]["release"] or st.processedIntents[intentId]["cancel"] then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end

		if canonicalAct == "StartCharge" then
			if st.isCharging then
				-- Cannot start a charge while another charge is already active!
				recordActionFailure(player, intentId, "StaleIntent")
				return
			end
			local cAct = actionPayload.chargeAction or "DirectShoot"
			if cAct ~= "DirectShoot" and cAct ~= "CurveShoot" and cAct ~= "Pass" and cAct ~= "Slide" and cAct ~= "Volley" and cAct ~= "BicycleKick" then
				recordActionFailure(player, intentId, "InvalidPayload")
				return
			end
			st.processedIntents[intentId]["start"] = true
			BallService.StartCharge(player, cAct, intentId)
			return
		elseif isInstant then
			st.processedIntents[intentId]["start"] = true
			st.terminalIntents[intentId] = true
		else
			-- Direct kick without prior hold (tap kick)
			st.processedIntents[intentId]["start"] = true
		end
	elseif phase == "release" then
		-- Release MUST correspond to an active charge started with the SAME intentId
		if not st.isCharging or st.chargeIntentId ~= intentId then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end
		if st.chargeGeneration ~= st.characterGeneration or st.chargeContextVersion ~= st.contextVersion then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end

		-- Action MUST match latched chargeAction (or legal ground/air conversion: CurveShoot <-> Volley)!
		local expectedKickAct = if st.chargeAction == "Slide" then "Slide" else st.chargeAction
		local matchesCharge = (canonicalAct == expectedKickAct)
			or (expectedKickAct == "CurveShoot" and canonicalAct == "Volley")
			or (expectedKickAct == "Volley" and canonicalAct == "CurveShoot")
			or (canonicalAct == "CancelCharge")

		if not matchesCharge then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end

		if st.processedIntents[intentId]["release"] or st.processedIntents[intentId]["cancel"] then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end

		st.processedIntents[intentId]["release"] = true
		st.terminalIntents[intentId] = true
	elseif phase == "cancel" then
		if not st.isCharging or st.chargeIntentId ~= intentId then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end
		if st.processedIntents[intentId]["cancel"] or st.processedIntents[intentId]["release"] then
			recordActionFailure(player, intentId, "StaleIntent")
			return
		end
		st.processedIntents[intentId]["cancel"] = true
		st.terminalIntents[intentId] = true
		BallService.CancelCharge(player, intentId)
		return
	end

	-- Rate limiting: exempt CancelCharge, StopSprint, and phase release/cancel
	local isRateExempt = (canonicalAct == "CancelCharge" or canonicalAct == "StopSprint" or phase == "release" or phase == "cancel")
	if not isRateExempt and (now - st.lastActionRequestTime < 0.033) then
		recordActionFailure(player, intentId, "RateLimited")
		return
	end
	if not isRateExempt then
		st.lastActionRequestTime = now
	end

	-- Dispatch execution
	if canonicalAct == "Sprint" then
		BallService.ExecuteSprint(player, actionPayload.isSprinting ~= false)
	elseif canonicalAct == "StopSprint" then
		BallService.ExecuteSprint(player, false)
	elseif canonicalAct == "Dash" then
		BallService.ExecuteDash(player, aim)
	elseif canonicalAct == "DirectionalJump" then
		BallService.ExecuteDirectionalJump(player, aim)
	elseif canonicalAct == "CancelCharge" then
		BallService.CancelCharge(player, intentId)
	elseif canonicalAct == "ResetBall" then
		BallService.ResetBall()
	elseif canonicalAct == "DirectShoot" or canonicalAct == "CurveShoot" or canonicalAct == "Pass" or canonicalAct == "Volley" or canonicalAct == "BicycleKick" then
		-- Server is charge authority: calculate power internally from elapsed charge time!
		local charge = 0.50
		if st.isCharging and st.chargeStartTime > 0 then
			local elapsed = now - st.chargeStartTime
			charge = if elapsed < 0.12
				then Constants.CHARGE_MIN_POWER
				else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
			st.isCharging = false
			st.chargeStartTime = 0
			st.chargeAction = nil
			st.chargeIntentId = nil
		end
		BallService.ExecuteKick(player, canonicalAct :: Types.KickActionType, aim, charge, intentId, actionPayload.curveSideIntent)
	elseif canonicalAct == "Slide" then
		local charge = 0.50
		if st.isCharging and st.chargeStartTime > 0 then
			local elapsed = now - st.chargeStartTime
			charge = if elapsed < 0.12
				then Constants.CHARGE_MIN_POWER
				else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
			st.isCharging = false
			st.chargeStartTime = 0
			st.chargeAction = nil
			st.chargeIntentId = nil
		end
		BallService.ExecuteSlide(player, aim, charge, intentId)
	end
end

function BallService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Ensure ball instance is in Workspace
	BallService.EnsureBallInstance()
	BallService.ResetBall()

	-- Step physics in Heartbeat
	if RunService:IsServer() then
		RunService.Heartbeat:Connect(function(dt: number)
			BallService.StepPhysics(dt)
		end)
	end

	-- Connect Network Client Actions (Table Intent & Legacy compatibility)
	local ballActionEvent = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	ballActionEvent.OnServerEvent:Connect(function(player: Player, actionPayload: any, maybeAim: any, maybeCharge: any)
		BallService.HandleActionRequest(player, actionPayload, maybeAim, maybeCharge)
	end)

	-- Enumerate existing players and setup lifecycle (F-16)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerLifecycle(player)
	end
	Players.PlayerAdded:Connect(setupPlayerLifecycle)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerStates[player.UserId] = nil
		if ballState.possessorUserId == player.UserId then
			ballState.possessorUserId = nil
			ballState.state = "Free"
			syncBallAttributes()
		end
	end)
end

return table.freeze(BallService)
