--!strict
-- src/server/services/BallService.luau
-- Module 02: Server-Authoritative Ball Physics, Lifecycle & Ground Dribble/Receive
-- Governed by RF02-DRIBBLE-RECEIVE Contract (Owner Checklist 7, 2026-10-27 Authoritative Grill Final)
-- Server-authoritative custom position/velocity physics solver with bounded touch impulses,
-- proximity/relative-speed receive gates, deterministic contention resolution, honest contact windows,
-- 360 movement lead tracking, forward radial micro-touches (zero lateral sway), real ball rolling,
-- and one-shot Jump Self-Lob (Scoop) with atomic server possession release and brief recapture protection.
-- NO welds, NO attachments, NO teleport/snap follow, NO visual Touched dependencies.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))
local Configs = Shared:WaitForChild("configs")
local DribbleConfigs = require(Configs:WaitForChild("DribbleConfigs"))
local JumpConfigs = require(Configs:WaitForChild("JumpConfigs"))
local DribbleGeometryHelper = require(Shared:WaitForChild("DribbleGeometryHelper"))
local DribbleControlRules = require(Shared:WaitForChild("DribbleControlRules"))
local DribbleActionConfigs = require(Configs:WaitForChild("DribbleActionConfigs"))
local SprintConfigs = require(Configs:WaitForChild("SprintConfigs"))
local Network = require(Shared:WaitForChild("Network"))
local ShotConfig = require(Configs:WaitForChild("ShotConfigs"))
local ShotRules = require(Shared:WaitForChild("ShotRules"))
local ShotModel = require(Shared:WaitForChild("ShotModel"))
local FootballActions=require(Shared.configs.FootballActionConfigs)
local FootballRules=require(Shared.FootballActionRules)
local KickHitbox=require(Shared.KickHitbox)

local Services = script.Parent
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))

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

export type PlayerMovementState = {
	userId: number,
	teamSide: Types.TeamSide,
}

export type TouchInfo = {
	touchId: number,
	ownerUserId: number?,
	touchTime: number,
	action: string,
	touchCount: number,
}

local lastTouchInfo: TouchInfo = {
	touchId = 0,
	ownerUserId = nil,
	touchTime = 0,
	action = "None",
	touchCount = 0,
}

local freeBallOnlyOverride: boolean? = nil
local playerStates: { [number]: PlayerMovementState } = {}
local lastTouchTimeByPlayer: { [number]: number } = {}
local lastStealTimeByPlayer: { [number]: number } = {}
local blockedStealPairs: { [number]: { [number]: boolean } } = {}
local lastPlayerPositions: { [number]: Vector3 } = {}
local playerGenerations: { [number]: number } = {}
local activeCharacterConnections: { [number]: { RBXScriptConnection } } = {}
local ballPart: Part? = nil
local ballSpinRotation: CFrame = CFrame.identity
local isInitialized = false
local currentDribblePhase: string = "Free"
local currentDribbleSpeedFactor: number = 1.0
local controlledCarrierRoot: BasePart? = nil
local previousPossessorUserId: number? = nil

-- Jump Self-Lob state tracking
local lastLobTimeByPlayer: { [number]: number } = {}
local lastLobCarrierUserId: number? = nil
local lobDischargedThisJump: { [number]: boolean } = {}
local lastCameraLookByPlayer: { [number]: Vector3 } = {}
local lastIntentTimeByPlayer: { [number]: number } = {}
local goalDribbleRequests: {[number]: {character: Model, expires: number, lastStart: number}} = {}
local lastGoalStartByPlayer: {[number]: number} = {}
local dribbleTouchIntents: {[number]: {character: Model, foot: string, clip: string, startTime: number, expires: number}} = {}
local lastDribbleTouchByPlayer: {[number]: number} = {}
type ShotIntent = {character: Model, id: number, phase: string, began: number,
	start: number, charge: number, aim: Vector3, curve: number, checked: number, userId: number, kind: string, released: number, lastAim: number}
local shots: {[number]: ShotIntent} = {}
local lastShotIds: {[number]: number} = {}
local lastShotStart: {[number]: number} = {}
local shotRecaptureUntil: {[number]: number} = {}
local shotCurveUntil = 0
local shotCurve = 0

local BallService = {}

local function applyGoalDribbleMode(player: Player, character: Model, humanoid: Humanoid)
	local request = goalDribbleRequests[player.UserId]
	local state = humanoid:GetState()
	local active = request ~= nil and request.character == character and request.expires > os.clock()
		and humanoid.Health > 0 and humanoid.FloorMaterial ~= Enum.Material.Air
		and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.RunningNoPhysics or state == Enum.HumanoidStateType.Landed)
	local wasActive = character:GetAttribute("GoalDribbleActive") == true
	character:SetAttribute("GoalDribbleActive", active)
	if active then
		humanoid.WalkSpeed = DribbleActionConfigs.GOAL_SPEED
		character:SetAttribute("IsSprinting", false)
	elseif wasActive then
		humanoid.WalkSpeed = if character:GetAttribute("ServerShotPhase") == "Charging" then DribbleActionConfigs.GOAL_SPEED elseif character:GetAttribute("IsSprinting") == true then SprintConfigs.SPRINT_SPEED else SprintConfigs.NORMAL_WALK_SPEED
	end
end

function BallService.SetGoalDribbleIntent(player: Player, payload: any): boolean
	if typeof(payload) ~= "table" or typeof(payload.active) ~= "boolean" then return false end
	local character = player.Character
	if not character or payload.character ~= character or not character:IsDescendantOf(Workspace) then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	if payload.active then
		local now = os.clock()
		local lastStart = lastGoalStartByPlayer[player.UserId]
		if lastStart and now - lastStart < DribbleActionConfigs.INTENT_INTERVAL * 0.5 then return false end
		lastGoalStartByPlayer[player.UserId] = now
		goalDribbleRequests[player.UserId] = {character = character, expires = now + DribbleActionConfigs.GOAL_INTENT_TIMEOUT, lastStart = now}
	else
		-- Stops are always accepted for the current character; never rate-limited.
		goalDribbleRequests[player.UserId] = nil
	end
	applyGoalDribbleMode(player, character, humanoid)
	return true
end

function BallService.SetDribbleTouchIntent(player: Player, payload: any): boolean
	if shots[player.UserId] then return false end
	if typeof(payload) ~= "table" then return false end
	if payload.foot ~= "L" and payload.foot ~= "R" then return false end
	if typeof(payload.clip) ~= "string" or not DribbleActionConfigs.IsRecognizedClipName(payload.clip) then return false end
	local character = player.Character
	if not character or payload.character ~= character or not character:IsDescendantOf(Workspace) then return false end
	if ballState.state ~= "Possessed" or ballState.possessorUserId ~= player.UserId then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.FloorMaterial == Enum.Material.Air then return false end
	local state = humanoid:GetState()
	if state ~= Enum.HumanoidStateType.Running and state ~= Enum.HumanoidStateType.RunningNoPhysics and state ~= Enum.HumanoidStateType.Landed then
		return false
	end
	if DribbleActionConfigs.IsGoalModeClipName(payload.clip) and character:GetAttribute("GoalDribbleActive") ~= true then
		return false
	end
	local now = os.clock()
	if payload.isCut == true or payload.phase ~= nil then return false end
	local lastTime = lastDribbleTouchByPlayer[player.UserId]
	if lastTime and (now - lastTime) < DribbleActionConfigs.TOUCH_INTENT_COOLDOWN_SEC then
		return false
	end
	lastDribbleTouchByPlayer[player.UserId] = now
	dribbleTouchIntents[player.UserId] = {
		character = character,
		foot = payload.foot,
		clip = payload.clip,
		startTime = now,
		expires = now + DribbleActionConfigs.TOUCH_PULSE_DURATION_SEC,
	}
	character:SetAttribute("ServerDribbleTouchFoot", payload.foot)
	character:SetAttribute("ServerDribbleTouchClip", payload.clip)
	if ballPart then
		ballPart:SetAttribute("LastDribbleTouchFoot", payload.foot)
		ballPart:SetAttribute("LastDribbleTouchClip", payload.clip)
	end
	return true
end

local function setStealPairBlocked(firstUserId: number, secondUserId: number, blocked: boolean)
	local firstPairs = blockedStealPairs[firstUserId]
	local secondPairs = blockedStealPairs[secondUserId]
	if blocked then
		if not firstPairs then
			firstPairs = {}
			blockedStealPairs[firstUserId] = firstPairs
		end
		if not secondPairs then
			secondPairs = {}
			blockedStealPairs[secondUserId] = secondPairs
		end
		firstPairs[secondUserId] = true
		secondPairs[firstUserId] = true
		return
	end

	if firstPairs then
		firstPairs[secondUserId] = nil
		if next(firstPairs) == nil then
			blockedStealPairs[firstUserId] = nil
		end
	end
	if secondPairs then
		secondPairs[firstUserId] = nil
		if next(secondPairs) == nil then
			blockedStealPairs[secondUserId] = nil
		end
	end
end

local function clearStealPairsForPlayer(userId: number)
	local otherPairs = blockedStealPairs[userId]
	blockedStealPairs[userId] = nil
	if otherPairs then
		for otherUserId in otherPairs do
			local pairsForOther = blockedStealPairs[otherUserId]
			if pairsForOther then
				pairsForOther[userId] = nil
				if next(pairsForOther) == nil then
					blockedStealPairs[otherUserId] = nil
				end
			end
		end
	end
end

local function getOrCreatePlayerState(userId: number): PlayerMovementState
	local st = playerStates[userId]
	if st then
		return st
	end
	local team: Types.TeamSide = if (userId % 2 == 0) then "South" else "North"
	local newState: PlayerMovementState = {
		userId = userId,
		teamSide = team,
	}
	playerStates[userId] = newState
	return newState
end

local function syncBallAttributes()
	if not ballPart then
		return
	end
	ballPart:SetAttribute("BallState", ballState.state)
	ballPart:SetAttribute("PossessorUserId", ballState.possessorUserId or 0)
	ballPart:SetAttribute("LastPossessingTeam", ballState.lastPossessingTeam or "")
	ballPart:SetAttribute("BallVelocity", ballState.velocity)
	ballPart:SetAttribute("BallPosition", ballState.position)
	ballPart:SetAttribute("LastTouchAction", lastTouchInfo.action)
	ballPart:SetAttribute("LastTouchTime", lastTouchInfo.touchTime)
	ballPart:SetAttribute("TouchCount", lastTouchInfo.touchCount)
	ballPart:SetAttribute("DribblePhase", currentDribblePhase)

	local curUid = ballState.possessorUserId
	if curUid ~= previousPossessorUserId then
		if previousPossessorUserId ~= nil then
			local prevPlayer = Players:GetPlayerByUserId(previousPossessorUserId)
			local prevChar = prevPlayer and prevPlayer.Character
			if prevChar then
				prevChar:SetAttribute("IsBallCarrier", false)
				prevChar:SetAttribute("DribblePhase", "Free")
				prevChar:SetAttribute("DribbleSpeedFactor", 1.0)
			end
		end
		previousPossessorUserId = curUid
	end

	if ballState.state ~= "Possessed" then
		currentDribbleSpeedFactor = 1.0
	end

	if curUid ~= nil then
		local curPlayer = Players:GetPlayerByUserId(curUid)
		local curChar = curPlayer and curPlayer.Character
		if curChar then
			curChar:SetAttribute("IsBallCarrier", true)
			curChar:SetAttribute("DribblePhase", currentDribblePhase)
			curChar:SetAttribute("DribbleSpeedFactor", currentDribbleSpeedFactor)
		end
	end
end

function BallService.EnsureBallInstance(): Part
	if ballPart and ballPart.Parent ~= nil then
		ballPart.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
		return ballPart
	end
	local existing = Workspace:FindFirstChild(BALL_PART_NAME)
	if existing and existing:IsA("Part") then
		existing.Material = Enum.Material.SmoothPlastic
		existing.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
		ballPart = existing
		return existing
	end

	local p = Instance.new("Part")
	p.Name = BALL_PART_NAME
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
	p.Color = Color3.fromRGB(245, 250, 255)
	p.Material = Enum.Material.SmoothPlastic
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

BallService.GetBallSnapshot = BallService.GetBallState

function BallService.SetBallPositionAndVelocity(pos: Vector3, vel: Vector3)
	ballState.position = pos
	ballState.velocity = vel
	ballState.state = "Free"
	ballState.possessorUserId = nil
	ballState.inFlightAction = nil
	ballState.curveImpulse = nil
	shotCurve,shotCurveUntil = 0,0
	table.clear(blockedStealPairs)
	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end
	if ballPart then
		ballPart.CFrame = CFrame.new(pos)
	end
	syncBallAttributes()
end

function BallService.SetPossessor(userId: number?)
	if userId ~= nil then
		local st = getOrCreatePlayerState(userId)
		ballState.possessorUserId = userId
		ballState.state = "Possessed"
		ballState.lastPossessingTeam = st.teamSide
		currentDribblePhase = "Contact"
		lastTouchInfo.touchId += 1
		lastTouchInfo.ownerUserId = userId
		lastTouchInfo.touchTime = os.clock()
		lastTouchInfo.action = "DirectSet"
		lastTouchInfo.touchCount += 1
	else
		ballState.possessorUserId = nil
		ballState.state = "Free"
		currentDribblePhase = "Free"
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
	local player = Players:GetPlayerByUserId(userId)
	if player and player.Character then
		player.Character:SetAttribute("AttackGoalPosition", DribbleControlRules.AttackGoal(teamSide, Constants.ARENA_HALF_LENGTH_Z, Constants.GOAL_BACK_ZONE_STUDS))
	end
end

function BallService.GetPlayerTeamSide(userId: number): Types.TeamSide
	return getOrCreatePlayerState(userId).teamSide
end

function BallService.SetFreeBallOnly(enabled: boolean)
	freeBallOnlyOverride = enabled
	-- RF-F31: FreeBallOnly explicitly revokes active possession immediately
	if enabled and ballState.possessorUserId ~= nil then
		ballState.possessorUserId = nil
		ballState.state = "Free"
		syncBallAttributes()
	end
end

function BallService.IsFreeBallOnly(): boolean
	if freeBallOnlyOverride ~= nil then
		return freeBallOnlyOverride
	end
	return DribbleConfigs.FREE_BALL_ONLY_MODE
end

function BallService.GetLastTouchInfo(): TouchInfo
	return {
		touchId = lastTouchInfo.touchId,
		ownerUserId = lastTouchInfo.ownerUserId,
		touchTime = lastTouchInfo.touchTime,
		action = lastTouchInfo.action,
		touchCount = lastTouchInfo.touchCount,
	}
end

function BallService.ResetBall(customPos: Vector3?, initialPossessingTeam: Types.TeamSide?)
	for uid,shot in shots do shot.character:SetAttribute("ServerShotPhase","Cancelled"); shot.character:SetAttribute("ServerShotActive",false); shots[uid]=nil end
	local spawnPos = customPos or Constants.BALL_SPAWN_POSITION or Vector3.new(0, Constants.BALL_RADIUS, 0)
	ballState.position = spawnPos
	ballState.velocity = Vector3.zero
	ballState.state = "Free"
	ballState.possessorUserId = nil
	ballState.lastPossessingTeam = initialPossessingTeam
	ballState.lastKickerUserId = nil
	ballState.lastKickTime = 0
	ballState.curveImpulse = nil
	ballState.inFlightAction = nil
	ballSpinRotation = CFrame.identity
	table.clear(blockedStealPairs)
	table.clear(lastLobTimeByPlayer)
	table.clear(lobDischargedThisJump)
	table.clear(lastCameraLookByPlayer)
	table.clear(lastIntentTimeByPlayer)
	lastLobCarrierUserId = nil

	lastTouchInfo.touchId += 1
	lastTouchInfo.ownerUserId = nil
	lastTouchInfo.touchTime = os.clock()
	lastTouchInfo.action = "ResetBall"

	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end
	if ballPart then
		ballPart.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
		ballPart.CFrame = CFrame.new(spawnPos)
	end
	syncBallAttributes()
end

-- Camera look intent setter (from network remote or tests)
function BallService.SetCameraLookIntent(userId: number, lookDir: Vector3)
	local hDir = Vector3.new(lookDir.X, 0, lookDir.Z)
	local mag = hDir.Magnitude
	if mag > 1e-4 and mag == mag and mag < math.huge then
		lastCameraLookByPlayer[userId] = hDir / mag
	end
end

function BallService.GetLastLobInfo(): { time: number, carrierUserId: number? }
	return {
		time = if lastLobCarrierUserId ~= nil then (lastLobTimeByPlayer[lastLobCarrierUserId] or 0) else 0,
		carrierUserId = lastLobCarrierUserId,
	}
end

-- =============================================================================
-- Jump Self-Lob (Scoop): Triggered by successful upward jump while carrier
-- =============================================================================
function BallService.TriggerSelfLob(player: Player, hrp: BasePart, humanoid: Humanoid): boolean
	if shots[player.UserId] then return false end
	if not DribbleConfigs.SELF_LOB_ENABLED then
		return false
	end
	local uid = player.UserId
	if ballState.state ~= "Possessed" or ballState.possessorUserId ~= uid then
		return false
	end
	if lobDischargedThisJump[uid] then
		return false
	end
	lobDischargedThisJump[uid] = true

	local cVel = hrp.AssemblyLinearVelocity
	local horizVel = Vector3.new(cVel.X, 0, cVel.Z)
	local isMoving = horizVel.Magnitude > DribbleConfigs.MIN_PLAYER_MOVE_SPEED

	local launchDir: Vector3
	if isMoving then
		-- Verified horizontal movement snapshot
		launchDir = horizVel.Unit
	else
		-- Stationary: horizontal CAMERA look (fallback to body look if none)
		local camLook = lastCameraLookByPlayer[uid]
		if camLook and camLook.Magnitude > 0.01 then
			launchDir = camLook
		else
			local look = hrp.CFrame.LookVector
			launchDir = Vector3.new(look.X, 0, look.Z).Unit
		end
	end

	local lobVel = DribbleGeometryHelper.ComputeSelfLobVelocity(launchDir, cVel, isMoving)
	local sep = DribbleGeometryHelper.GetCarrierSeparationDistance()
	local launchPos = Vector3.new(hrp.Position.X, ballState.position.Y, hrp.Position.Z) + launchDir * sep

	local r = DribbleConfigs.BALL_COLLISION_RADIUS
	local mx = Constants.ARENA_HALF_WIDTH_X - r
	local mz = Constants.ARENA_HALF_LENGTH_Z - r
	launchPos = Vector3.new(math.clamp(launchPos.X, -mx, mx), launchPos.Y, math.clamp(launchPos.Z, -mz, mz))

	local now = os.clock()
	ballState.position = launchPos
	ballState.velocity = lobVel
	ballState.state = "Free"
	ballState.possessorUserId = nil
	currentDribblePhase = "Free"

	lastLobTimeByPlayer[uid] = now
	lastLobCarrierUserId = uid

	lastTouchInfo.touchId += 1
	lastTouchInfo.ownerUserId = uid
	lastTouchInfo.touchTime = now
	lastTouchInfo.action = "SelfLob"
	lastTouchInfo.touchCount += 1

	syncBallAttributes()
	return true
end

-- =============================================================================

local function endShot(uid: number, phase: string)
 local shot = shots[uid]
 if shot then
  shot.character:SetAttribute("ServerShotPhase", phase)
  shot.character:SetAttribute("ServerShotActive", false)
 end
 shots[uid] = nil
end

local function ballAvailable(uid: number): boolean
 return ballState.state=="Free" or (ballState.state=="Possessed" and ballState.possessorUserId==uid)
end

local function startKick(shot, now: number)
 shot.phase,shot.start,shot.checked="Windup",now,FootballRules.ContactAt(shot.kind)
 dribbleTouchIntents[shot.userId]=nil
 local char=shot.character
 char:SetAttribute("ServerShotAim",shot.aim)
 char:SetAttribute("ServerShotStart",workspace:GetServerTimeNow())
 char:SetAttribute("ServerShotActive",true)
 char:SetAttribute("ServerShotPhase","Windup")
end

function BallService.HandleShotIntent(player: Player, payload: any): boolean
 if typeof(payload)~="table" or not ShotRules.IsActionId(payload.id) then return false end
 local kind=FootballRules.Kind(payload.action or "Shot")
 if not kind then return false end
 local uid,char,now=player.UserId,player.Character,os.clock()
 local shot=shots[uid]
 if payload.phase=="Cancel" then
  if shot and shot.id==payload.id and shot.character==char then endShot(uid,"Cancelled");return true end
  return false
 end
 if not char or not char:IsDescendantOf(workspace) then return false end
 local hum=char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health<=0 or not root or not root:IsA("BasePart")
  or hum.FloorMaterial==Enum.Material.Air or BallService.IsFreeBallOnly() then return false end
 if payload.phase=="Aim" then
  if not shot or shot.id~=payload.id or shot.character~=char or shot.kind~=kind or shot.phase~="Charging"
   or now-shot.lastAim<0.08 then return false end
  local aim=ShotRules.Aim(payload.aim)
  if not aim then return false end
  shot.aim,shot.lastAim=aim,now
  char:SetAttribute("ServerShotAim",aim)
  return true
 elseif payload.phase=="Begin" then
  if shot or payload.id<=(lastShotIds[uid] or 0) or now-(lastShotStart[uid] or -math.huge)<ShotConfig.CooldownSec then return false end
  lastShotIds[uid],lastShotStart[uid]=payload.id,now
  shots[uid]={character=char,userId=uid,kind=kind,id=payload.id,phase="Charging",began=now,start=0,
   charge=0,aim=ShotRules.Aim(payload.aim) or root.CFrame.LookVector,curve=0,checked=0,released=0,lastAim=0}
  char:SetAttribute("ServerShotId",payload.id);char:SetAttribute("ServerShotKind",kind)
  char:SetAttribute("ServerShotAim",shots[uid].aim)
  char:SetAttribute("ServerShotPhase","Charging")
  return true
 elseif payload.phase=="Release" then
  local aim=ShotRules.Aim(payload.aim)
  if not shot or shot.kind~=kind or shot.id~=payload.id or shot.character~=char or shot.phase~="Charging"
   or now-shot.began>ShotConfig.ChargeTimeoutSec or not aim
   or (payload.curve~=-1 and payload.curve~=0 and payload.curve~=1) or kind=="Pass" and payload.curve~=0 then return false end
  shot.charge=math.clamp(now-shot.began,0,FootballRules.MaxChargeSec(kind))
  shot.aim,shot.curve,shot.released=aim,payload.curve,now
  startKick(shot,now) -- Never wait for a ball before swinging.
  return true
 end
 return false
end

local function stepShots(now: number)
 for uid,shot in shots do
  local player=Players:GetPlayerByUserId(uid);local char=shot.character
  local hum=char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
  if not player or player.Character~=char or not hum or hum.Health<=0 or not root or not root:IsA("BasePart")
   or not char:IsDescendantOf(workspace) or hum.FloorMaterial==Enum.Material.Air then endShot(uid,"Cancelled")
  elseif shot.phase=="Charging" then
   if now-shot.began>ShotConfig.ChargeTimeoutSec then endShot(uid,"Cancelled") end
  elseif shot.phase=="Windup" then
   local elapsed=now-shot.start;local contact=FootballRules.ContactAt(shot.kind);local contactEnd=FootballRules.ContactEnd(shot.kind)
   if not ballAvailable(uid) then endShot(uid,"Cancelled")
   elseif elapsed>=contact then
    local owned=ballState.state=="Possessed" and ballState.possessorUserId==uid
    local contactInfo=FootballRules.Contact(root.CFrame,ballState.position,owned,DribbleConfigs.LOOSE_BALL_DISTANCE)
    local touched=contactInfo~=nil;local upper=math.min(elapsed,contactEnd)
    -- Sweep the authored interval once even if one slow server tick skips its end.
    -- Previous elapsed<=contactEnd+0.1 discarded valid contact on frame stalls.
    -- Front volume is the sole range gate; authored times still schedule the strike.
    -- Previous foot sweep is retained below as a comment for reference.
    --[========[
    if shot.checked<=contactEnd then
     local samples=math.max(1,math.ceil((upper-shot.checked)*120))
     for i=0,samples do local t=shot.checked+(upper-shot.checked)*i/samples
      if ShotRules.Touches(ShotModel.FootFrame(root.CFrame,FootballRules.SourceTime(shot.kind,t),"Right",shot.kind),ballState.position,Constants.BALL_RADIUS) then touched=true;break end
     end
    end
    ]========]
    shot.checked=upper
    if touched then
     ballState.velocity=FootballRules.Velocity(shot.kind,shot.aim,shot.charge,shot.curve)
     if not owned and shot.kind=="Shot" and contactInfo then ballState.velocity=KickHitbox.ApplyMishit(ballState.velocity,contactInfo) end
     if contactInfo then
      char:SetAttribute("LastKickUsedHitbox",not owned)
      char:SetAttribute("LastKickPoint",contactInfo.point)
      char:SetAttribute("LastKickQuality",contactInfo.quality)
      char:SetAttribute("LastKickPowerScale",if shot.kind=="Shot" then contactInfo.powerScale else 1)
      char:SetAttribute("LastKickDeflection",if shot.kind=="Shot" then contactInfo.deflectionDegrees else 0)
     end
     ballState.possessorUserId=nil;ballState.state="Free";ballState.lastKickerUserId=uid;ballState.lastKickTime=now
     ballState.inFlightAction=if shot.kind=="Pass" then "Pass" elseif shot.curve==0 then "DirectShoot" else "CurveShoot"
     currentDribblePhase="Free";controlledCarrierRoot=nil;dribbleTouchIntents[uid]=nil
     shotCurve,shotCurveUntil=shot.curve,now+ShotConfig.CurveDurationSec
     shotRecaptureUntil[uid]=now+ShotConfig.RecaptureDelaySec
     lastTouchInfo.touchId+=1;lastTouchInfo.touchCount+=1
     lastTouchInfo.ownerUserId,lastTouchInfo.touchTime,lastTouchInfo.action=uid,now,shot.kind
     shot.phase="Struck";char:SetAttribute("ServerShotContactTime",workspace:GetServerTimeNow())
     char:SetAttribute("LastKickCurve",shot.curve)
     char:SetAttribute("ServerShotPower",shot.charge/FootballRules.MaxChargeSec(shot.kind));char:SetAttribute("ServerShotPhase","Struck")
    elseif elapsed>=contactEnd then shot.phase="Whiff";char:SetAttribute("ServerShotPhase","Whiff") end
   end
  elseif now-shot.start>=FootballRules.Duration(shot.kind) then endShot(uid,"Complete") end
 end
end

-- Ground Dribble & Receive Simulation (RF02-DRIBBLE-RECEIVE)
-- =============================================================================
type PlayerCandidate = {
	player: Player,
	character: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	userId: number,
	teamSide: Types.TeamSide,
	dist: number,
	relSpeed: number,
	isGrounded: boolean,
	vertGap: number,
}

local lastActiveCarrierCand: PlayerCandidate? = nil
local carrierPrevRootPos: { [number]: Vector3 } = {}

-- RF-F33: Strict transitive total order comparator
-- Guarantees mathematically strict weak ordering with zero pairwise cycles across all permutations.
local function compareCandidates(a: PlayerCandidate, b: PlayerCandidate): boolean
	if a.dist ~= b.dist then
		return a.dist < b.dist
	end
	return a.userId < b.userId
end

local function simulateDribbleAndReceive(dt: number, now: number)
	controlledCarrierRoot = nil
	lastActiveCarrierCand = nil
	if BallService.IsFreeBallOnly() then
		return
	end

	-- 1. Candidate gathering and Teleport/Dead Carrier verification
	local candidates: { PlayerCandidate } = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:IsDescendantOf(game) then
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?

			if hum and hum.Health > 0 and root then
				local uid = player.UserId

				-- Teleport detection: sudden jump exceeding threshold revokes possession immediately
				local lastPos = lastPlayerPositions[uid]
				local invalidMovement = false
				if lastPos and (root.Position - lastPos).Magnitude > DribbleConfigs.MAX_TELEPORT_DISPLACEMENT then
					invalidMovement = true
					if ballState.possessorUserId == uid then
						ballState.possessorUserId = nil
						ballState.state = "Free"
					end
				end
				lastPlayerPositions[uid] = root.Position
				if invalidMovement then
					-- Revoke and skip this sample so a teleported player cannot reacquire this tick.
					continue
				end

				local hState = hum:GetState()
				local isGrounded = hum.FloorMaterial ~= Enum.Material.Air
					and (
						hState == Enum.HumanoidStateType.Running
							or hState == Enum.HumanoidStateType.RunningNoPhysics
							or hState == Enum.HumanoidStateType.Landed
					)

				local feetY = root.Position.Y - DribbleConfigs.PLAYER_FEET_OFFSET
				local vertGap = math.abs(ballState.position.Y - feetY)
				local horizDiff = Vector3.new(ballState.position.X - root.Position.X, 0, ballState.position.Z - root.Position.Z)
				local dist = horizDiff.Magnitude
				local pVel = root.AssemblyLinearVelocity
				local relSpeed = (ballState.velocity - pVel).Magnitude
				local team = getOrCreatePlayerState(uid).teamSide

				table.insert(candidates, {
					player = player,
					character = char,
					humanoid = hum,
					rootPart = root,
					userId = uid,
					teamSide = team,
					dist = dist,
					relSpeed = relSpeed,
					isGrounded = isGrounded,
					vertGap = vertGap,
				})
			end
		end
	end

	-- 2. State: FREE -> Check Reception Gate
	if ballState.state == "Free" then
		local eligibleReceivers: { PlayerCandidate } = {}

		for _, cand in ipairs(candidates) do
			if now < (shotRecaptureUntil[cand.userId] or 0) then continue end
			-- Former owner lob recapture protection guard
			local isFormerLobOwner = (cand.userId == lastLobCarrierUserId)
			local inLobCooldown = isFormerLobOwner
				and ((now - (lastLobTimeByPlayer[cand.userId] or 0)) < DribbleConfigs.SELF_LOB_RECAPTURE_COOLDOWN_SEC)
			if inLobCooldown then
				continue
			end

			local passGrounded = if DribbleConfigs.PLAYER_GROUNDED_REQUIRED then cand.isGrounded else true
			local passBallGrounded = ballState.position.Y <= DribbleConfigs.GROUNDED_MAX_BALL_Y
			local passVert = cand.vertGap <= DribbleConfigs.MAX_RECEIVE_VERTICAL_GAP
			local passDist = cand.dist <= DribbleConfigs.MAX_RECEIVE_DISTANCE
			local passSpeed = cand.relSpeed <= DribbleConfigs.MAX_RECEIVE_RELATIVE_SPEED

			if passGrounded and passBallGrounded and passVert and passDist and passSpeed then
				table.insert(eligibleReceivers, cand)
			end
		end

		if #eligibleReceivers > 0 then
			-- RF-F33: Strict total order sort
			table.sort(eligibleReceivers, compareCandidates)

			local winner = eligibleReceivers[1]
			lastActiveCarrierCand = winner
			ballState.possessorUserId = winner.userId
			ballState.state = "Possessed"
			ballState.lastPossessingTeam = winner.teamSide
			currentDribblePhase = "Contact"

			lastTouchTimeByPlayer[winner.userId] = now
			lastTouchInfo.touchId += 1
			lastTouchInfo.ownerUserId = winner.userId
			lastTouchInfo.touchTime = now
			lastTouchInfo.action = "Receive"
			lastTouchInfo.touchCount += 1

			-- Reception cushion: guide ball along receiver's movement heading
			local moveDir = winner.humanoid.MoveDirection
			local forward = if moveDir.Magnitude > DribbleConfigs.TARGET_DIRECTION_THRESHOLD
				then moveDir.Unit
				else Vector3.new(winner.rootPart.CFrame.LookVector.X, 0, winner.rootPart.CFrame.LookVector.Z).Unit
			local rootVelocity = winner.rootPart.AssemblyLinearVelocity
			local horizontalSpeed = Vector3.new(rootVelocity.X, 0, rootVelocity.Z).Magnitude
			local pSpeed = math.min(horizontalSpeed, DribbleConfigs.MAX_RECEIVE_CUSHION_SPEED)
			local initialLeadSpeed = math.max(pSpeed * 1.25, DribbleConfigs.MIN_RECEIVE_CUSHION_SPEED)
			ballState.velocity = forward * initialLeadSpeed
			syncBallAttributes()
			return
		end
	end

	-- 3. State: POSSESSED -> Carrier validity, Opponent Steal, and Honest Touch Rhythm
	if ballState.state == "Possessed" then
		local currentCarrierId = ballState.possessorUserId
		local carrierCand: PlayerCandidate? = nil

		for _, cand in ipairs(candidates) do
			if cand.userId == currentCarrierId then
				carrierCand = cand
				lastActiveCarrierCand = carrierCand
				break
			end
		end

		-- Carrier no longer valid (died, disconnected, or missing root part)
		if not carrierCand then
			lastActiveCarrierCand = nil
			ballState.possessorUserId = nil
			ballState.state = "Free"
			currentDribblePhase = "Free"
			syncBallAttributes()
			return
		end

		-- Check if carrier launched into an upward jump (authoritative liftoff detection)
		local cVel = carrierCand.rootPart.AssemblyLinearVelocity
		if not carrierCand.isGrounded and cVel.Y > DribbleConfigs.SELF_LOB_MIN_TAKEOFF_VY and not lobDischargedThisJump[currentCarrierId] then
			local scooped = BallService.TriggerSelfLob(carrierCand.player, carrierCand.rootPart, carrierCand.humanoid)
			if scooped then
				return
			end
		end

		-- Check if ball got away (Loose Ball trigger: distance exceeds LOOSE_BALL_DISTANCE)
		if carrierCand.dist > DribbleConfigs.LOOSE_BALL_DISTANCE then
			lastActiveCarrierCand = nil
			ballState.possessorUserId = nil
			ballState.state = "Free"
			currentDribblePhase = "Free"
			syncBallAttributes()
			return
		end

		-- RF-F32: Opponent Interception / Steal with Team Check, Contest Cooldown & Valid Contact Gate
		local opponentsInStealRange: { PlayerCandidate } = {}
		for _, cand in ipairs(candidates) do
			if cand.userId ~= currentCarrierId then
				-- Teammate Policy: Players on the same team cannot steal from each other
				local isTeammate = (carrierCand.teamSide ~= nil and cand.teamSide ~= nil and cand.teamSide == carrierCand.teamSide)
				if not isTeammate then
					-- Contest Debounce: Dispossessed player cannot immediately re-steal on adjacent frames
					local pairDistance = (cand.rootPart.Position - carrierCand.rootPart.Position).Magnitude
					local pairBlocked = blockedStealPairs[cand.userId] ~= nil
						and blockedStealPairs[cand.userId][currentCarrierId] == true
					if pairBlocked and pairDistance > DribbleConfigs.STEAL_REENTRY_DISTANCE then
						setStealPairBlocked(cand.userId, currentCarrierId, false)
						pairBlocked = false
					end

					local lastSteal = lastStealTimeByPlayer[cand.userId] or 0
					if not pairBlocked and (now - lastSteal) >= DribbleConfigs.STEAL_CONTEST_COOLDOWN_SEC then
						-- Full Valid Contact Gate for Stealer
						local passGrounded = if DribbleConfigs.PLAYER_GROUNDED_REQUIRED then cand.isGrounded else true
						local passBallGrounded = ballState.position.Y <= DribbleConfigs.GROUNDED_MAX_BALL_Y
						local passVert = cand.vertGap <= DribbleConfigs.MAX_RECEIVE_VERTICAL_GAP
						local passStealDist = cand.dist <= DribbleConfigs.STEAL_INTERCEPT_DISTANCE
						local passSpeed = cand.relSpeed <= DribbleConfigs.MAX_RECEIVE_RELATIVE_SPEED

						if passGrounded and passBallGrounded and passVert and passStealDist and passSpeed then
							table.insert(opponentsInStealRange, cand)
						end
					end
				end
			end
		end

		if #opponentsInStealRange > 0 then
			-- RF-F33: Strict total order resolution for Steal
			table.sort(opponentsInStealRange, compareCandidates)

			local stealer = opponentsInStealRange[1]
			lastActiveCarrierCand = stealer
			ballState.possessorUserId = stealer.userId
			ballState.lastPossessingTeam = stealer.teamSide
			-- Lock every opposing player already engaged in this close contest until
			-- they separate, preventing multi-player overlap from rotating possession.
			for _, engagedCand in ipairs(candidates) do
				local isOpponent = engagedCand.teamSide ~= stealer.teamSide
				local isClose = (engagedCand.rootPart.Position - stealer.rootPart.Position).Magnitude
					<= DribbleConfigs.STEAL_REENTRY_DISTANCE
				if engagedCand.userId ~= stealer.userId and isOpponent and isClose then
					setStealPairBlocked(engagedCand.userId, stealer.userId, true)
				end
			end

			-- Cool down both contest participants; the pair remains locked until separation.
			lastStealTimeByPlayer[currentCarrierId] = now
			lastStealTimeByPlayer[stealer.userId] = now
			lastTouchTimeByPlayer[stealer.userId] = now
			lastTouchInfo.touchId += 1
			lastTouchInfo.ownerUserId = stealer.userId
			lastTouchInfo.touchTime = now
			lastTouchInfo.action = "Steal"
			lastTouchInfo.touchCount += 1

			local moveDir = stealer.humanoid.MoveDirection
			local forward = if moveDir.Magnitude > DribbleConfigs.TARGET_DIRECTION_THRESHOLD
				then moveDir.Unit
				else Vector3.new(stealer.rootPart.CFrame.LookVector.X, 0, stealer.rootPart.CFrame.LookVector.Z).Unit
			local rootVelocity = stealer.rootPart.AssemblyLinearVelocity
			local horizontalSpeed = Vector3.new(rootVelocity.X, 0, rootVelocity.Z).Magnitude
			local pSpeed = math.min(horizontalSpeed, DribbleConfigs.MAX_RECEIVE_CUSHION_SPEED)
			ballState.velocity = forward * math.max(pSpeed, DribbleConfigs.MIN_STEAL_CUSHION_SPEED)
			syncBallAttributes()
			return
		end

		-- RF-F31: Require Real Contact Window for Carrier Touches & Cushion Damping
		-- Grounded ball carriers retain continuous front-foot control across the entire possession window
		-- (up to LOOSE_BALL_DISTANCE) unless dispossessed by an opponent steal, jump self-lob, or kick/shot.
		local carrierInContact = carrierCand.isGrounded
			and (ballState.position.Y <= DribbleConfigs.GROUNDED_MAX_BALL_Y)
			and (carrierCand.vertGap <= DribbleConfigs.MAX_RECEIVE_VERTICAL_GAP)
			and (carrierCand.dist <= DribbleConfigs.LOOSE_BALL_DISTANCE)

		if not carrierInContact then
			-- Out of physical contact window: preserve free physics flight/roll without modification
			return
		end

		-- Continuous front-foot control for valid current grounded carrier:
		-- 1. Moving: lead follows horizontal MoveDirection, independent of body/camera.
		-- 2. Idle: lead smoothly settles to body LookVector front.
		-- 3. Speed-related forward radial micro-touches (zero lateral sway).
		local isSprinting = (carrierCand.character:GetAttribute("IsSprinting") == true)
		local moveDir = carrierCand.humanoid.MoveDirection
		local horizMove = Vector3.new(moveDir.X, 0, moveDir.Z)
		local isMoving = horizMove.Magnitude > DribbleConfigs.MOVE_DIRECTION_THRESHOLD
		-- Replicated velocity remains available when server Humanoid input is stale.
		if not isMoving then
			local velocityDirection = Vector3.new(cVel.X, 0, cVel.Z)
			if velocityDirection.Magnitude > DribbleConfigs.MIN_PLAYER_MOVE_SPEED then
				horizMove = velocityDirection.Unit
				isMoving = true
			end
		end
		local cSpeed = Vector3.new(cVel.X, 0, cVel.Z).Magnitude
		local goalMode = carrierCand.character:GetAttribute("GoalDribbleActive") == true

		local look = carrierCand.rootPart.CFrame.LookVector
		local bodyLook = Vector3.new(look.X, 0, look.Z).Unit
		local leadDir: Vector3
		if goalMode then
			-- In Goal Mode (Close-Control / G mode), the ball is always controlled & rolled in FRONT of the body
			-- (where the character is facing, towards the goal), even while backpedaling with S or strafing with A/D!
			local goal = DribbleControlRules.AttackGoal(carrierCand.teamSide, Constants.ARENA_HALF_LENGTH_Z, Constants.GOAL_BACK_ZONE_STUDS)
			if goal then
				local dirToGoal = DribbleControlRules.HorizontalDirection(goal - carrierCand.rootPart.Position)
				leadDir = if dirToGoal.Magnitude > 0.001 then dirToGoal else bodyLook
			else
				leadDir = bodyLook
			end
		elseif isMoving then
			leadDir = horizMove.Unit
		else
			leadDir = bodyLook
		end

		local touchIntent = dribbleTouchIntents[currentCarrierId]
		local markerPulse = 0.0
		local touchSpeedScale = 1.0
		local touchKickImpulse = 0.0
		if touchIntent and touchIntent.character == carrierCand.character and touchIntent.expires > now then
			local progress = math.clamp((now - touchIntent.startTime) / DribbleActionConfigs.TOUCH_PULSE_DURATION_SEC, 0, 1)
			local wave = math.sin(progress * math.pi)
			local boost = if goalMode
				then DribbleActionConfigs.TOUCH_PULSE_BOOST_GOAL
				elseif isSprinting then DribbleActionConfigs.TOUCH_PULSE_BOOST_RUN
				else DribbleActionConfigs.TOUCH_PULSE_BOOST_WALK
			markerPulse = boost * wave
			local maxOrbitBoost = if goalMode
				then DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_GOAL
				elseif isSprinting then DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_RUN
				else DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_WALK
			touchSpeedScale = 1.0 + (maxOrbitBoost - 1.0) * wave
			local maxImpulse = if goalMode
				then DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_GOAL
				elseif isSprinting then DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_RUN
				else DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_WALK
			-- Front-loaded impulse on foot strike (first half of the touch window) so the ball visibly accelerates off the boot
			local strikeEnv = if progress < 0.55 then math.sin((progress / 0.55) * math.pi) else 0.0
			touchKickImpulse = maxImpulse * strikeEnv
		end
		local hasRecentMarker = touchIntent ~= nil
			and touchIntent.character == carrierCand.character
			and (now - touchIntent.startTime) <= 0.65
		local microOffset = if goalMode
			then 0
			elseif hasRecentMarker then markerPulse
			else DribbleGeometryHelper.ComputeMicroTouchOffset(cSpeed, isSprinting, now)
		local target, flankDeg, infeasible = DribbleGeometryHelper.FeasibleFrontTarget(
			carrierCand.rootPart.Position,
			leadDir,
			isSprinting,
			microOffset
		)
		if goalMode then
			-- Reuse the same joint-safe target search, with a close-control radius + bounded marker lead pulse.
			local baseDistance = if isSprinting then DribbleConfigs.FRONT_DISTANCE_SPRINT else DribbleConfigs.FRONT_DISTANCE_WALK
			target, flankDeg, infeasible = DribbleGeometryHelper.FeasibleFrontTarget(
				carrierCand.rootPart.Position,
				leadDir,
				isSprinting,
				(DribbleActionConfigs.GOAL_BALL_DISTANCE - baseDistance) + markerPulse,
				DribbleActionConfigs.GOAL_CARRIER_SEPARATION
			)
		end
		-- Owner update: arrange only the ball already possessed by this player.
		-- Loose/foreign balls never enter this carrier branch and are never pulled in.
		local shot=shots[currentCarrierId]
		local settingUp=shot and shot.character==carrierCand.character and (shot.phase=="Charging" or shot.phase=="Windup")
		if settingUp then
			local point=KickHitbox.Frame(carrierCand.rootPart.CFrame,shot.aim).Position
			target=Vector3.new(point.X,Constants.BALL_RADIUS,point.Z)
			touchKickImpulse,markerPulse,touchSpeedScale=0,0,1
		end
		local minSep = if goalMode then DribbleActionConfigs.GOAL_CARRIER_SEPARATION else nil
		local v = DribbleGeometryHelper.ComputeFrontVelocity(
			carrierCand.rootPart.Position,cVel,ballState.position,target,dt*touchSpeedScale,minSep)
		if settingUp then
			local relative=Vector3.new(target.X-ballState.position.X,0,target.Z-ballState.position.Z)*ShotConfig.BallSetupTrackGain
			if relative.Magnitude>ShotConfig.BallSetupMaxRelativeSpeed then relative=relative.Unit*ShotConfig.BallSetupMaxRelativeSpeed end
			v=Vector3.new(cVel.X,0,cVel.Z)+relative
			if v.Magnitude>DribbleConfigs.MAX_BALL_DRIBBLE_SPEED then v=v.Unit*DribbleConfigs.MAX_BALL_DRIBBLE_SPEED end
		end
		if touchKickImpulse > 0 then
			local toTarget = Vector3.new(target.X - ballState.position.X, 0, target.Z - ballState.position.Z)
			local kickDir = if toTarget.Magnitude > 0.15 then toTarget.Unit else leadDir
			v = v + kickDir * touchKickImpulse
			if v.Magnitude > DribbleConfigs.MAX_BALL_DRIBBLE_SPEED then
				v = v.Unit * DribbleConfigs.MAX_BALL_DRIBBLE_SPEED
			end
		end
		ballState.velocity = Vector3.new(v.X, 0, v.Z)
		currentDribblePhase = "Control"
		controlledCarrierRoot = carrierCand.rootPart
		lastTouchInfo.action = "DribbleControl"
		if infeasible then
			currentDribbleSpeedFactor = DribbleConfigs.INFEASIBLE_SPEED_FACTOR
		elseif flankDeg > DribbleConfigs.BLOCKED_FLANK_ANGLE_DEG then
			currentDribbleSpeedFactor = DribbleConfigs.BLOCKED_SPEED_FACTOR
		else
			currentDribbleSpeedFactor = 1.0
		end
	end
end
-- =============================================================================
-- Autonomous Ball Physics & Trajectory Stepping
-- =============================================================================
function BallService.StepPhysics(dt: number)
	-- Clamp delta time to guard against physics explosion spikes
	local clampedDt = math.clamp(dt, 0.001, DribbleConfigs.MAX_DT_SIMULATION)
	local now = os.clock()
	-- Mode expiry must also run in free-ball-only mode, where receive simulation
	-- deliberately returns early. Otherwise a lost release packet could leave speed capped.
	for uid, request in goalDribbleRequests do
		local player = Players:GetPlayerByUserId(uid)
		local hum = request.character:FindFirstChildOfClass("Humanoid")
		if player and player.Character == request.character and hum then
			applyGoalDribbleMode(player, request.character, hum)
		end
		if not player or player.Character ~= request.character or request.expires <= now then
			goalDribbleRequests[uid] = nil
		end
	end

	-- 1. Server-authoritative Dribble & Receive simulation
	simulateDribbleAndReceive(clampedDt, now)
	stepShots(now)

	-- 2. Physical flight, Cage collision, and Turf rolling friction
	local r = Constants.BALL_RADIUS
	local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)
	local directedDownPass=ballState.state=="Free" and ballState.inFlightAction=="Pass" and ballState.velocity.Y < -0.05
	local onGround = not isOnRamp and not directedDownPass and (ballState.position.Y <= r + 0.08) and (math.abs(ballState.velocity.Y) < 3.0)

	local currentVel = ballState.velocity
 if ballState.state == "Free" and now < shotCurveUntil and shotCurve ~= 0 then
  local horizontal = Vector3.new(currentVel.X,0,currentVel.Z)
  if horizontal.Magnitude > 1 then
   local rotated = FootballRules.CurveVelocity(horizontal,shotCurve,clampedDt)
   currentVel=Vector3.new(rotated.X,currentVel.Y,rotated.Z)
  end
 elseif ballState.state == "Possessed" then shotCurve,shotCurveUntil=0,0 end
	if onGround then
		-- Suppress downward velocity when resting on turf
		currentVel = Vector3.new(currentVel.X, 0, currentVel.Z)
		ballState.position = Vector3.new(ballState.position.X, r, ballState.position.Z)
	else
		-- Baseline gravity
		local effGravity = Constants.GRAVITY_ACCELERATION_Y
		currentVel = currentVel + Vector3.new(0, effGravity * clampedDt, 0)
		currentVel = currentVel * math.max(0.0, 1.0 - (0.20 * clampedDt))
	end

	local prevPos = ballState.position
	local nextPos, nextVel = CagePhysicsService.StepBallCageCollision(prevPos, currentVel, clampedDt)

	-- Turf contact & rolling friction
	if onGround or (not isOnRamp and nextPos.Y <= (r + 0.08)) then
		if nextVel.Y > 1.5 then
			-- Preserve upward bounce velocity from floor collision
		elseif nextVel.Y < -3.5 then
			-- High downward velocity before bounce sub-step
		else
			-- Low vertical velocity: settle cleanly on turf
			nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
			nextVel = Vector3.new(nextVel.X, 0, nextVel.Z)
		end

		local rollFriction = if ballState.state=="Free" and ballState.inFlightAction=="Pass"
			then FootballActions.Pass.GroundFriction else Constants.GROUND_ROLLING_FRICTION
		local frictionDecel = math.max(0.0, 1.0 - (rollFriction * clampedDt))
		nextVel = Vector3.new(nextVel.X * frictionDecel, nextVel.Y, nextVel.Z * frictionDecel)

		if nextVel.Magnitude < Constants.BALL_REST_THRESHOLD_SPEED then
			nextVel = Vector3.zero
			nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
		end
	end

	-- Joint swept body + cage clearance for the CURRENT valid carrier only (RF-F51)
	local carrierCand = lastActiveCarrierCand
	if
		carrierCand
		and ballState.state == "Possessed"
		and ballState.possessorUserId == carrierCand.userId
		and carrierCand.rootPart.Parent
	then
		local hrp = carrierCand.rootPart
		local p1 = hrp.Position
		local p0 = carrierPrevRootPos[carrierCand.userId] or p1
		carrierPrevRootPos[carrierCand.userId] = p1
			local look = hrp.CFrame.LookVector
			local goalMode = carrierCand.character:GetAttribute("GoalDribbleActive") == true
			local minSep = if goalMode then DribbleActionConfigs.GOAL_CARRIER_SEPARATION else nil
			local sepPos, sepVel, _adjusted, infeasible = DribbleGeometryHelper.ResolveBodyCage(
				p0,
				p1,
				prevPos,
				nextPos,
				nextVel,
				hrp.AssemblyLinearVelocity,
				clampedDt,
				Vector3.new(look.X, 0, look.Z),
				minSep
			)
			nextPos = sepPos
			nextVel = sepVel
			if infeasible then
				currentDribbleSpeedFactor = DribbleConfigs.INFEASIBLE_SPEED_FACTOR
			end
	else
		lastActiveCarrierCand = nil
	end

	ballState.position = nextPos
	ballState.velocity = nextVel

	-- Visual roll from ACTUAL horizontal travel: angle = distance / radius; zero travel => zero spin
	local travel = Vector3.new(nextPos.X - prevPos.X, 0, nextPos.Z - prevPos.Z)
	local travelDist = travel.Magnitude
	if travelDist > 1e-4 then
		local rotAxis = Vector3.new(0, 1, 0):Cross(travel / travelDist)
		if rotAxis.Magnitude > 0.01 then
			ballSpinRotation = CFrame.fromAxisAngle(rotAxis.Unit, travelDist / Constants.BALL_RADIUS) * ballSpinRotation
		end
	end
	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end

	if ballPart then
		ballPart.CFrame = CFrame.new(ballState.position) * ballSpinRotation
		-- One relative-pose snapshot transports the controlled ball with the rendered
		-- carrier, rather than mixing an old server ball pose with a newer local root.
		-- This is presentation data only: ownership/contact/physics stay on the server.
		local root = controlledCarrierRoot
		if root and root.Parent and ballState.state == "Possessed" then
			ballPart:SetAttribute("DribbleVisualPose", root.CFrame:ToObjectSpace(ballPart.CFrame))
			ballPart:SetAttribute("DribbleVisualTime", Workspace:GetServerTimeNow())
			ballPart:SetAttribute("DribbleVisualOwner", ballState.possessorUserId)
		else
			ballPart:SetAttribute("DribbleVisualOwner", nil)
		end
	end
	syncBallAttributes()
end

-- =============================================================================
-- Player Lifecycle & Bootstrap
-- =============================================================================
local function setupPlayerLifecycle(player: Player)
	local userId = player.UserId
	getOrCreatePlayerState(userId)

	local currentGen = (playerGenerations[userId] or 0) + 1
	playerGenerations[userId] = currentGen
	local activeCharacter: Model? = nil

	local function onCharAdded(char: Model)
		if player.Character ~= char then
			return
		end
		activeCharacter = char
		endShot(userId,"Cancelled")
		shotRecaptureUntil[userId]=nil
		goalDribbleRequests[userId] = nil
		lastGoalStartByPlayer[userId] = nil
		dribbleTouchIntents[userId] = nil
		lastDribbleTouchByPlayer[userId] = nil
		char:SetAttribute("GoalDribbleActive", false)
		char:SetAttribute("AttackGoalPosition", DribbleControlRules.AttackGoal(getOrCreatePlayerState(userId).teamSide, Constants.ARENA_HALF_LENGTH_Z, Constants.GOAL_BACK_ZONE_STUDS))
		local thisGen = currentGen
		local oldConnections = activeCharacterConnections[userId]
		if oldConnections then
			for _, conn in ipairs(oldConnections) do
				conn:Disconnect()
			end
			activeCharacterConnections[userId] = nil
		end
		local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?

		-- RF-F37: Post-yield generation and hierarchy verification
		if playerGenerations[userId] ~= thisGen
			or player.Character ~= char
			or not char:IsDescendantOf(game)
			or not humanoid then
			return
		end

		humanoid.UseJumpPower = true
		humanoid.JumpPower = JumpConfigs.JUMP_POWER
		humanoid.JumpHeight = JumpConfigs.EXPECTED_APEX_HEIGHT
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		lobDischargedThisJump[userId] = false

		local conns: { RBXScriptConnection } = {}

		-- Jump state observer for upward self-lob scoop
		table.insert(conns, humanoid.StateChanged:Connect(function(oldState, newState)
			if playerGenerations[userId] ~= thisGen then
				return
			end
			if player.Character ~= char or not char:IsDescendantOf(game) then
				return
			end

			if ballState.state == "Possessed" and ballState.possessorUserId == userId then
				local isJumpState = (newState == Enum.HumanoidStateType.Jumping)
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local vy = hrp.AssemblyLinearVelocity.Y
					local isCoalescedRising = (newState == Enum.HumanoidStateType.Freefall and vy > DribbleConfigs.SELF_LOB_MIN_TAKEOFF_VY)
					if (isJumpState or isCoalescedRising) and not lobDischargedThisJump[userId] then
						if vy > DribbleConfigs.SELF_LOB_MIN_TAKEOFF_VY then
							BallService.TriggerSelfLob(player, hrp, humanoid)
						end
					end
				end
			end

			if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
				lobDischargedThisJump[userId] = false
			end
		end))

		table.insert(conns, humanoid.Died:Connect(function()
			if player.Character == char then
				endShot(userId,"Cancelled")
				goalDribbleRequests[userId] = nil
				dribbleTouchIntents[userId] = nil
				char:SetAttribute("GoalDribbleActive", false)
			end
			if playerGenerations[userId] == thisGen and activeCharacter == char and ballState.possessorUserId == userId then
				ballState.possessorUserId = nil
				ballState.state = "Free"
				syncBallAttributes()
			end
		end))

		activeCharacterConnections[userId] = conns
	end

	if player.Character then
		onCharAdded(player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		currentGen = (playerGenerations[userId] or 0) + 1
		playerGenerations[userId] = currentGen
		onCharAdded(char)
	end)

	player.CharacterRemoving:Connect(function(char)
		local wasActiveCharacter = activeCharacter == char
		if wasActiveCharacter then
			endShot(userId,"Cancelled")
			activeCharacter = nil
			playerGenerations[userId] = (playerGenerations[userId] or 0) + 1
			lastPlayerPositions[userId] = nil
			lobDischargedThisJump[userId] = nil
			lastCameraLookByPlayer[userId] = nil
			lastIntentTimeByPlayer[userId] = nil
			dribbleTouchIntents[userId] = nil
			lastDribbleTouchByPlayer[userId] = nil
			local oldConnections = activeCharacterConnections[userId]
			if oldConnections then
				for _, conn in ipairs(oldConnections) do
					conn:Disconnect()
				end
				activeCharacterConnections[userId] = nil
			end
		end
		if wasActiveCharacter and ballState.possessorUserId == userId then
			ballState.possessorUserId = nil
			ballState.state = "Free"
			syncBallAttributes()
		end
	end)
end

function BallService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Ensure ball instance is in Workspace
	BallService.EnsureBallInstance()
	BallService.ResetBall()

	-- Hook BallActionRequest for validated camera intent from client carrier
	local remotesFolder = ReplicatedStorage:FindFirstChild(Network.RemoteFolderName)
	if remotesFolder then
		local ballActionRemote = remotesFolder:FindFirstChild(Network.Names.BallActionRequest)
		if ballActionRemote and ballActionRemote:IsA("RemoteEvent") then
			ballActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
				if typeof(payload) ~= "table" then
					return
				end
				if payload.action == "Shot" or payload.action == "Pass" then
     BallService.HandleShotIntent(player,payload)
     return
    end
    if payload.action == "GoalDribble" then
					BallService.SetGoalDribbleIntent(player, payload)
					return
				end
				if payload.action == "DribbleTouch" then
					BallService.SetDribbleTouchIntent(player, payload)
					return
				end
				if payload.action == "CameraIntent" then
					local uid = player.UserId
					if ballState.possessorUserId ~= uid then
						return
					end
					local dir = payload.lookDirection
					if typeof(dir) ~= "Vector3" then
						return
					end
					if dir.X ~= dir.X or dir.Z ~= dir.Z then
						return
					end
					if math.abs(dir.X) == math.huge or math.abs(dir.Z) == math.huge then
						return
					end
					local hDir = Vector3.new(dir.X, 0, dir.Z)
					local mag = hDir.Magnitude
					if mag < 0.01 or mag > 1.5 then
						return
					end
					local now = os.clock()
					if (now - (lastIntentTimeByPlayer[uid] or 0)) < 0.05 then
						return
					end
					lastIntentTimeByPlayer[uid] = now
					lastCameraLookByPlayer[uid] = hDir / mag
				end
			end)
		end
	end

	-- Step physics in Heartbeat
	if RunService:IsServer() then
		RunService.Heartbeat:Connect(function(dt: number)
			BallService.StepPhysics(dt)
		end)
	end

	-- Enumerate existing players and setup lifecycle
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerLifecycle(player)
	end
	Players.PlayerAdded:Connect(setupPlayerLifecycle)

	Players.PlayerRemoving:Connect(function(player: Player)
		local uid = player.UserId
		endShot(uid,"Cancelled")
		lastShotIds[uid],lastShotStart[uid],shotRecaptureUntil[uid]=nil,nil,nil
		goalDribbleRequests[uid] = nil
		lastGoalStartByPlayer[uid] = nil
		dribbleTouchIntents[uid] = nil
		lastDribbleTouchByPlayer[uid] = nil
		playerStates[uid] = nil
		lastTouchTimeByPlayer[uid] = nil
		lastStealTimeByPlayer[uid] = nil
		lastPlayerPositions[uid] = nil
		playerGenerations[uid] = nil
		lobDischargedThisJump[uid] = nil
		lastCameraLookByPlayer[uid] = nil
		lastIntentTimeByPlayer[uid] = nil
		local oldConnections = activeCharacterConnections[uid]
		if oldConnections then
			for _, conn in ipairs(oldConnections) do
				conn:Disconnect()
			end
			activeCharacterConnections[uid] = nil
		end
		clearStealPairsForPlayer(uid)
		if ballState.possessorUserId == uid then
			ballState.possessorUserId = nil
			ballState.state = "Free"
			syncBallAttributes()
		end
	end)
end

return table.freeze(BallService)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

local CutTimeline = require(Shared:WaitForChild("DribbleCutTimeline"))

-- Previous section --
local bypassCarrierBodyCircleThisStep: boolean = false

-- Previous section --
local dribbleTouchIntents: {[number]: {character: Model, foot: string, clip: string, isCut: boolean, startTime: number, expires: number}} = {}

-- Previous section --
type CutIntent = {
	character: Model, cutName: string, cutId: number, direction: Vector3, entryDirection: Vector3,
	startTime: number, duration: number, expires: number, phase: string, struckAt: number?,
}
local dribbleCutIntents: { [number]: CutIntent } = {}
local lastDribbleCutByPlayer: { [number]: { id: number, time: number } } = {}
local lastSprintContextAt: { [number]: number } = {}

-- Previous section --
local function hasSprintContext(userId: number, character: Model, now: number): boolean
	local active = character:GetAttribute("IsSprinting") == true
	if active then lastSprintContextAt[userId] = now end
	return CutTimeline.HasSprintContext(active, lastSprintContextAt[userId], now)
end


-- Previous section --
		local cut = dribbleCutIntents[player.UserId]
		if cut and CutTimeline.Get(cut.cutName) and now-cut.startTime<cut.duration then return false end

-- Previous section --
	local cut = dribbleCutIntents[player.UserId]
	local profile = cut and CutTimeline.Get(cut.cutName)
	local cutSpec = cut and (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[cut.cutName]
	local isSprintCutClip = false
	for key, spec in pairs(DribbleActionConfigs.Clips) do
		if CutTimeline.Get(key) and spec.ClipName == payload.clip then isSprintCutClip = true break end
	end
	if payload.isCut == true then
		if not cut or not cutSpec or cut.character ~= character or cut.expires <= now
			or cutSpec.ClipName ~= payload.clip or payload.cutId ~= cut.cutId then return false end
		if profile then
			if now-cut.startTime > cut.duration+DribbleActionConfigs.CUT_BALL_INTENT_GRACE_SEC then return false end
			if not CutTimeline.ValidateMarker(profile, payload.phase, payload.foot, now - cut.startTime) then return false end
			local expected = if payload.phase == "Trap" then "Approach" elseif payload.phase == "Strike" then "Trapped" else "Struck"
			if cut.phase ~= expected then return false end
			cut.phase = if payload.phase == "Trap" then "Trapped" elseif payload.phase == "Strike" then "Struck" else "Released"
			character:SetAttribute("ServerDribbleCutBallPhase", cut.phase)
			if payload.phase == "Strike" then
				cut.struckAt = now
				character:SetAttribute("ServerDribbleCutStrikeTime", now)
			else
				dribbleTouchIntents[player.UserId] = nil
				return true
			end
		end
	elseif isSprintCutClip or (profile and cut and cut.expires > now
		and (cut.phase ~= "Released" or now - cut.startTime < cut.duration)) then
		-- A background run marker cannot strike/redirect the ball while an Action cut owns it.
		return false
	end

-- Previous section --
		isCut = payload.isCut == true,

-- Previous section --
-- Correlated start/cancel intents; validated animation markers own sprint-cut ball phases.
function BallService.SetDribbleCutIntent(player: Player, payload: any): boolean
	if shots[player.UserId] then return false end
	if typeof(payload) ~= "table" then return false end
	local character = player.Character
	if not character or payload.character ~= character or not character:IsDescendantOf(Workspace) then return false end
	if payload.cancel == true then
		local active = dribbleCutIntents[player.UserId]
		if not active or active.character ~= character or payload.cutId ~= active.cutId then return false end
		local hum=character:FindFirstChildOfClass("Humanoid")
		if CutTimeline.Get(active.cutName) and os.clock()-active.startTime < active.duration and hum and hum.Health>0
			and hum.FloorMaterial~=Enum.Material.Air and ballState.possessorUserId==player.UserId then return false end
		dribbleCutIntents[player.UserId] = nil
		local touch = dribbleTouchIntents[player.UserId]
		if touch and touch.isCut then dribbleTouchIntents[player.UserId] = nil end
		character:SetAttribute("ServerDribbleCutBallPhase", if CutTimeline.Get(active.cutName) and os.clock()-active.startTime>=active.duration then "Complete" else "Cancelled")
		return true
	end
	if typeof(payload.cut) ~= "string" or typeof(payload.cutId) ~= "number" or payload.cutId ~= payload.cutId
		or payload.cutId < 1 or payload.cutId > 2147483647 or payload.cutId % 1 ~= 0 then return false end
	local approved = (DribbleActionConfigs.ApprovedCutAnimations :: { [string]: string? })[payload.cut]
	local spec = (DribbleActionConfigs.Clips :: { [string]: DribbleActionConfigs.DribbleClipSpec })[payload.cut]
	if not approved or not spec then return false end
	local direction = payload.direction
	if typeof(direction) ~= "Vector3" or not DribbleControlRules.IsFiniteVector(direction) then return false end
	local horizontal = DribbleControlRules.HorizontalDirection(direction)
	if horizontal.Magnitude < 0.5 then return false end
	if ballState.state ~= "Possessed" or ballState.possessorUserId ~= player.UserId then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.FloorMaterial == Enum.Material.Air then return false end
	if payload.cut == "GoalReverse" and character:GetAttribute("GoalDribbleActive") ~= true then return false end
	local now = os.clock()
	local profile = CutTimeline.Get(payload.cut)
	if profile and (not hasSprintContext(player.UserId, character, now) or character:GetAttribute("GoalDribbleActive") == true) then return false end
	local previous = lastDribbleCutByPlayer[player.UserId]
	if previous and (payload.cutId <= previous.id or now - previous.time < DribbleActionConfigs.CUT_COOLDOWN_SEC) then return false end
	local active = dribbleCutIntents[player.UserId]
	if active and active.character == character and active.expires > now then return false end
	local duration = math.min(DribbleActionConfigs.CUT_MAX_DURATION, spec.ExpectedDuration)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or Vector3.new(ballState.position.X - hrp.Position.X, 0, ballState.position.Z - hrp.Position.Z).Magnitude > DribbleConfigs.LOOSE_BALL_DISTANCE then return false end
	local entryDir = horizontal.Unit
	if hrp then
		local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
		if look.Magnitude > 0.01 then
			entryDir = look.Unit
		end
	end
	dribbleCutIntents[player.UserId] = {
		character = character,
		cutName = payload.cut,
		cutId = payload.cutId,
		phase = "Approach",
		direction = horizontal.Unit,
		entryDirection = entryDir,
		startTime = now,
		duration = duration,
		expires = now + duration + DribbleActionConfigs.CUT_BALL_INTENT_GRACE_SEC,
	}
	lastDribbleCutByPlayer[player.UserId] = { id = payload.cutId, time = now }
	dribbleTouchIntents[player.UserId] = nil
	character:SetAttribute("ServerDribbleCutId", payload.cutId)
	character:SetAttribute("ServerDribbleCutBallPhase", "Approach")
	character:SetAttribute("ServerDribbleCutEntryDirection", entryDir)
	character:SetAttribute("ServerDribbleCutExitDirection", horizontal.Unit)
	return true
end


-- Previous section --
  if shot or payload.id <= (lastShotIds[uid] or 0) or dribbleCutIntents[uid]

-- Previous section --
	bypassCarrierBodyCircleThisStep = false

-- Previous section --
		if isSprinting then lastSprintContextAt[currentCarrierId] = now end

-- Previous section --
		-- During a sprint cut:
		-- 1) Before the boot strikes the ball (wind-up / plant phase), the ball stays on the entry line so the foot visibly reaches and hits it first.
		-- 2) Once the boot strikes the ball (TouchL/TouchR marker or strikePhase), the ball slides linearly along a straight line (through the legs for W->S reverse, or straight diagonally for 45/135 cuts) with zero circular orbit!
		local cutIntent = dribbleCutIntents[currentCarrierId]
		local cutSprint = cutIntent ~= nil and CutTimeline.Get(cutIntent.cutName) ~= nil
			and now-cutIntent.startTime < cutIntent.duration
		local isCutEligible = cutIntent ~= nil
			and (cutIntent.character == carrierCand.character and cutIntent.expires > now)
			and (((isSprinting or cutSprint) and not goalMode) or (goalMode and cutIntent.cutName == "GoalReverse"))
		if cutSprint then isSprinting = true end
		local isCutActive = isCutEligible == true and (cutSprint or not cutIntent or cutIntent.phase ~= "Released")


-- Previous section --
		if goalMode and not isCutActive then

-- Previous section --
				elseif touchIntent.isCut then DribbleActionConfigs.TOUCH_PULSE_BOOST_CUT

-- Previous section --
				elseif touchIntent.isCut then DribbleActionConfigs.TOUCH_ORBIT_SPEED_BOOST_CUT

-- Previous section --
				elseif touchIntent.isCut then DribbleActionConfigs.TOUCH_KICK_SPEED_IMPULSE_CUT

-- Previous section --
		if cutIntent and CutTimeline.Get(cutIntent.cutName) and cutIntent.phase == "Released"
			and now - cutIntent.startTime < cutIntent.duration then
			-- The visible cut is still playing: let the last strike roll without invisible run-loop taps.
			microOffset, markerPulse, touchKickImpulse, touchSpeedScale = 0, 0, 0, 1
		end

		local cutLead = 0.0
		local cutPostStrike = false
		local cutLinearTarget: Vector3? = nil
		if cutIntent and isCutActive and CutTimeline.Get(cutIntent.cutName) then
			local elapsed = now - cutIntent.startTime
			local baseD = if isSprinting then DribbleConfigs.FRONT_DISTANCE_SPRINT else DribbleConfigs.FRONT_DISTANCE_WALK
			local closeAlpha = math.clamp(elapsed / CutTimeline.TrapAt, 0, 1)
			local closeDistance = baseD + (CutTimeline.TrapDistance - baseD) * closeAlpha
			local pEntry = DribbleGeometryHelper.FeasibleFrontTarget(carrierCand.rootPart.Position, cutIntent.entryDirection, isSprinting, closeDistance - baseD)
			leadDir = cutIntent.entryDirection
			cutLinearTarget = pEntry
			microOffset, markerPulse = 0, 0
			if (cutIntent.phase == "Struck" or cutIntent.phase == "Released") and cutIntent.struckAt then
				local post = math.clamp((now - cutIntent.struckAt) / (CutTimeline.ReleaseAt - CutTimeline.StrikeAt), 0, 1)
				local alpha = post * post * (3 - 2 * post)
				cutPostStrike = true
				cutLead = CutTimeline.PushLead * math.sin(post * math.pi)
				local pExit = DribbleGeometryHelper.FeasibleFrontTarget(carrierCand.rootPart.Position, cutIntent.direction, isSprinting, cutLead)
				cutLinearTarget = pEntry:Lerp(pExit, alpha)
				leadDir = cutIntent.direction
				-- Keep the normal body/cage sweep for marker-driven cuts.
			else
				touchKickImpulse, touchSpeedScale = 0, 1
			end
		elseif cutIntent and isCutActive then
			local uCut = math.clamp((now - cutIntent.startTime) / math.max(0.1, cutIntent.duration), 0, 1)
			local strikePhase = DribbleActionConfigs.CUT_BALL_STRIKE_PHASE or 0.36
			local hasCutTouch = touchIntent ~= nil
				and touchIntent.character == carrierCand.character
				and touchIntent.isCut
				and touchIntent.startTime >= (cutIntent.startTime - 0.05)
			cutPostStrike = hasCutTouch or (uCut >= strikePhase)
			local baseD = if isSprinting then DribbleConfigs.FRONT_DISTANCE_SPRINT else DribbleConfigs.FRONT_DISTANCE_WALK
			local pEntry, _, _ = DribbleGeometryHelper.FeasibleFrontTarget(
				carrierCand.rootPart.Position,
				cutIntent.entryDirection,
				isSprinting,
				0
			)
			if not cutPostStrike then
				-- Wind-up phase: keep ball right on the entry line so the foot reaches out and traps it first
				leadDir = cutIntent.entryDirection
				cutLead = 0.0
				cutLinearTarget = pEntry
			else
				-- Strike & pull-through phase: interpolate target along a pure straight lineSegment from pEntry to pExit
				-- (so W->S pulls straight through the legs instead of orbiting around the right hip!)
				local postU = if hasCutTouch
					then math.max(
						math.clamp((uCut - strikePhase) / math.max(0.1, 1.0 - strikePhase), 0, 1),
						math.clamp((now - touchIntent.startTime) / math.max(0.15, cutIntent.duration * (1.0 - strikePhase)), 0, 1)
					)
					else math.clamp((uCut - strikePhase) / math.max(0.1, 1.0 - strikePhase), 0, 1)
				local linAlpha = math.clamp(postU * 1.45, 0, 1)
				local sLin = linAlpha * linAlpha * (3 - 2 * linAlpha)
				leadDir = cutIntent.direction
				cutLead = DribbleActionConfigs.CUT_BALL_LEAD_SPRINT * math.sin(postU * math.pi)
				local pExit, _, _ = DribbleGeometryHelper.FeasibleFrontTarget(
					carrierCand.rootPart.Position,
					cutIntent.direction,
					isSprinting,
					microOffset + cutLead
				)
				cutLinearTarget = pEntry * (1 - sLin) + pExit * sLin
				bypassCarrierBodyCircleThisStep = true
			end
		elseif cutIntent and not isCutEligible then
			dribbleCutIntents[currentCarrierId] = nil
			if touchIntent and touchIntent.isCut then dribbleTouchIntents[currentCarrierId] = nil end
			carrierCand.character:SetAttribute("ServerDribbleCutBallPhase", if CutTimeline.Get(cutIntent.cutName) and now-cutIntent.startTime>=cutIntent.duration then "Complete" else "Cancelled")
		end


-- Previous section --
			microOffset + cutLead

-- Previous section --
		if cutLinearTarget then
			target = cutLinearTarget
			flankDeg = 0
			infeasible = false
		end

-- Previous section --
			-- Reuse the same joint-safe target search, with a close-control radius + bounded marker/cut lead pulse.

-- Previous section --
				(DribbleActionConfigs.GOAL_BALL_DISTANCE - baseDistance) + markerPulse + cutLead,

-- Previous section --
		if isCutActive or settingUp then
			-- Direct linear trajectory toward the cut target (no circular polar orbit arc in either wind-up or pull-through)

-- Previous section --
			local linearGain = (DribbleActionConfigs.CUT_LINEAR_TRACK_GAIN or 9.5) * math.min(touchSpeedScale, 1.35)
			local maxRel = DribbleActionConfigs.CUT_LINEAR_MAX_REL_SPEED or 28.0

-- Previous section --
		if bypassCarrierBodyCircleThisStep then
			-- During a linear cut pull-back (e.g. W->S sole drag), allow the ball to pass straight through the legs
			-- while still clamping inside the cage walls.
			local rBall = DribbleConfigs.BALL_COLLISION_RADIUS
			local mx = Constants.ARENA_HALF_WIDTH_X - rBall
			local mz = Constants.ARENA_HALF_LENGTH_Z - rBall
			nextPos = Vector3.new(math.clamp(nextPos.X, -mx, mx), nextPos.Y, math.clamp(nextPos.Z, -mz, mz))
		else

-- Previous section --
		end

-- Previous section --
		dribbleCutIntents[userId] = nil
		lastDribbleCutByPlayer[userId] = nil
		lastSprintContextAt[userId] = nil

-- Previous section --
				dribbleCutIntents[userId] = nil

-- Previous section --
			dribbleCutIntents[userId] = nil

-- Previous section --
				if payload.action == "DribbleCut" then
					BallService.SetDribbleCutIntent(player, payload)
					return
				end

-- Previous section --
		dribbleCutIntents[uid] = nil
		lastDribbleCutByPlayer[uid] = nil
		lastSprintContextAt[uid] = nil
]====]

--[========[
Previous carrier-only shot state machine retained.
function BallService.HandleShotIntent(player: Player, payload: any): boolean
 if typeof(payload) ~= "table" or not ShotRules.IsActionId(payload.id) then return false end
 local uid, char, now = player.UserId, player.Character, os.clock()
 local shot = shots[uid]
 if payload.phase == "Cancel" then
  if shot and shot.id == payload.id and shot.character == char then endShot(uid,"Cancelled"); return true end
  return false
 end
 if not char or not char:IsDescendantOf(workspace) then return false end
 local hum = char:FindFirstChildOfClass("Humanoid")
 local root = char:FindFirstChild("HumanoidRootPart")
 if not hum or hum.Health <= 0 or not root or not root:IsA("BasePart")
  or hum.FloorMaterial == Enum.Material.Air or BallService.IsFreeBallOnly()
  or ballState.possessorUserId ~= uid or ballState.state ~= "Possessed"
  or (root.Position-ballState.position).Magnitude > DribbleConfigs.LOOSE_BALL_DISTANCE then return false end
 if payload.phase == "Begin" then
  if shot or payload.id <= (lastShotIds[uid] or 0)
   or now-(lastShotStart[uid] or -math.huge) < ShotConfig.CooldownSec then return false end
  lastShotIds[uid],lastShotStart[uid] = payload.id,now
  shots[uid] = {character=char,id=payload.id,phase="Charging",began=now,start=0,
   charge=0,aim=root.CFrame.LookVector,curve=0,checked=ShotConfig.ContactAt}
  char:SetAttribute("ServerShotId",payload.id)
  char:SetAttribute("ServerShotPhase","Charging")
  return true
 elseif payload.phase == "Release" then
  local aim = ShotRules.Aim(payload.aim)
  if not shot or shot.character ~= char or shot.id ~= payload.id or shot.phase ~= "Charging"
   or now-shot.began > ShotConfig.ChargeTimeoutSec or not aim
   or (payload.curve ~= -1 and payload.curve ~= 0 and payload.curve ~= 1) then return false end
  shot.phase,shot.start,shot.charge,shot.aim,shot.curve = "Windup",now,
   math.clamp(now-shot.began,0,ShotConfig.MaxChargeSec),aim,payload.curve
  dribbleTouchIntents[uid] = nil
  char:SetAttribute("ServerShotAim",aim)
  char:SetAttribute("ServerShotStart",workspace:GetServerTimeNow())
  char:SetAttribute("ServerShotActive",true)
  char:SetAttribute("ServerShotPhase","Windup")
  return true
 end
 return false
end

local function stepShots(now: number)
 for uid,shot in shots do
  local player = Players:GetPlayerByUserId(uid)
  local char = shot.character
  local hum = char:FindFirstChildOfClass("Humanoid")
  local root = char:FindFirstChild("HumanoidRootPart")
  local elapsed = now-shot.start
  if not player or player.Character ~= char or not hum or hum.Health <= 0
   or not root or not root:IsA("BasePart") or not char:IsDescendantOf(workspace) then
   endShot(uid,"Cancelled")
  elseif shot.phase == "Charging" then
   if now-shot.began > ShotConfig.ChargeTimeoutSec or ballState.possessorUserId ~= uid
    or hum.FloorMaterial == Enum.Material.Air then endShot(uid,"Cancelled") end
  elseif shot.phase == "Windup" then
   if ballState.possessorUserId ~= uid or hum.FloorMaterial == Enum.Material.Air then
    endShot(uid,"Cancelled")
   elseif elapsed >= ShotConfig.ContactAt then
    local upper = math.min(elapsed,ShotConfig.ContactEnd)
    local touched = false
    -- Swept authored foot samples cover a low-FPS tick without enlarging the hitbox.
    if elapsed <= ShotConfig.ContactEnd+0.1 then
     local samples = math.max(1,math.ceil((upper-shot.checked)*120))
     for i=0,samples do
      local t=shot.checked+(upper-shot.checked)*i/samples
      if ShotRules.Touches(ShotModel.FootFrame(root.CFrame,t*ShotConfig.PlaybackRate,"Right"),ballState.position,Constants.BALL_RADIUS) then
       touched=true; break
      end
     end
    end
    shot.checked=upper
    if touched then
     ballState.velocity=ShotRules.Velocity(shot.aim,shot.charge)
     ballState.possessorUserId=nil
     ballState.state="Free"
     ballState.lastKickerUserId=uid
     ballState.lastKickTime=now
     ballState.inFlightAction=if shot.curve == 0 then "DirectShoot" else "CurveShoot"
     currentDribblePhase="Free"
     controlledCarrierRoot=nil
     dribbleTouchIntents[uid]=nil
     shotCurve,shotCurveUntil=shot.curve,now+ShotConfig.CurveDurationSec
     shotRecaptureUntil[uid]=now+ShotConfig.RecaptureDelaySec
     lastTouchInfo.touchId+=1
     lastTouchInfo.touchCount+=1
     lastTouchInfo.ownerUserId,lastTouchInfo.touchTime,lastTouchInfo.action=uid,now,"Shot"
     shot.phase="Struck"
     char:SetAttribute("ServerShotContactTime",workspace:GetServerTimeNow())
     char:SetAttribute("ServerShotPower",shot.charge/ShotConfig.MaxChargeSec)
     char:SetAttribute("ServerShotPhase","Struck")
    elseif elapsed >= ShotConfig.ContactEnd then
     shot.phase="Whiff"
     char:SetAttribute("ServerShotPhase","Whiff")
    end
   end
  elseif elapsed >= ShotConfig.Duration then endShot(uid,"Complete") end
 end
end


]========]

--[============[
Removed waiting and shot setup retained.
  elseif shot.phase=="WaitingBall" then
   if readyToKick(root,shot) then startKick(shot,now)
   elseif now-shot.released>=FootballActions.ReleaseWaitSec then
    shot.phase="Whiff";shot.start=now;char:SetAttribute("ServerShotPhase","Whiff")
   end

		local shot = shots[currentCarrierId]
  local settingUp = shot and shot.character == carrierCand.character and (shot.phase == "Windup" or shot.phase == "Charging" or shot.phase == "WaitingBall")
  if settingUp then
   -- Checkpoint22c3731 aimed setup at the authored foot. The visible volume now
   -- owns range/quality, so normal possession settles at its horizontal sweet spot.
   local offset = KickHitbox.Frame(carrierCand.rootPart.CFrame).Position-carrierCand.rootPart.Position
   target = Vector3.new(carrierCand.rootPart.Position.X+offset.X,Constants.BALL_RADIUS,carrierCand.rootPart.Position.Z+offset.Z)
   touchKickImpulse, markerPulse, touchSpeedScale = 0,0,1
  end
  local v: Vector3
		if settingUp then
			-- Preserve the existing bounded shot setup approach.
			local toTarget = Vector3.new(target.X - ballState.position.X, 0, target.Z - ballState.position.Z)
			local linearGain = (ShotConfig.BallSetupTrackGain or 9.5) * math.min(touchSpeedScale, 1.35)
			local maxRel = ShotConfig.BallSetupMaxRelativeSpeed or 28.0
			local relVel = toTarget * linearGain
			if relVel.Magnitude > maxRel then
				relVel = relVel.Unit * maxRel
			end
			v = Vector3.new(cVel.X, 0, cVel.Z) + relVel
			if v.Magnitude > DribbleConfigs.MAX_BALL_DRIBBLE_SPEED then
				v = v.Unit * DribbleConfigs.MAX_BALL_DRIBBLE_SPEED
			end
		else
			local minSep = if goalMode then DribbleActionConfigs.GOAL_CARRIER_SEPARATION else nil
			v = DribbleGeometryHelper.ComputeFrontVelocity(
				carrierCand.rootPart.Position,
				cVel,
				ballState.position,
				target,
				dt * touchSpeedScale,
				minSep
			)
		end

]============]
