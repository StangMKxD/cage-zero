--!strict
-- src/server/services/BallService.luau
-- Module 02: Server-Authoritative Ball Possession, Stamina, Mistake Tracking, Shooting Zone Check, and Pass/Shoot Actions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local Services = script.Parent
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

export type PlayerMovementState = {
	stamina: number,
	isSprinting: boolean,
	lastMoveDir: Vector3,
	badFirstTouchUntil: number,
	sharpTurnUntil: number,
	sprintOvershootUntil: number,
	boostMultiplier: number,
	boostUntil: number,
	teamSide: "North" | "South",
}

local BALL_PART_NAME = "CageMatchBall"
local BASE_PASS_SPEED = 78.0
local BASE_SHOOT_SPEED = 118.0
local STAMINA_DRAIN_PER_SEC = 0.24
local STAMINA_REGEN_PER_SEC = 0.18
local GRAVITY_Y = -52.0

local ballState = {
	ballId = "BALL_01",
	position = Vector3.new(0, 2.0, 0),
	velocity = Vector3.zero,
	possessorUserId = nil :: number?,
	lastKickerUserId = nil :: number?,
	lastKickTeam = nil :: ("North" | "South")?,
	laserGuidedPassActive = false,
	miracleFinishActive = false,
}

local playerStates: { [number]: PlayerMovementState } = {}
local ballPart: Part? = nil
local isInitialized = false

local BallService = {}

local function getOrCreatePlayerState(userId: number): PlayerMovementState
	local st = playerStates[userId]
	if st then
		return st
	end
	local newState: PlayerMovementState = {
		stamina = 1.0,
		isSprinting = false,
		lastMoveDir = Vector3.new(0, 0, 1),
		badFirstTouchUntil = 0,
		sharpTurnUntil = 0,
		sprintOvershootUntil = 0,
		boostMultiplier = 1.0,
		boostUntil = 0,
		teamSide = if (userId % 2 == 0) then "South" else "North",
	}
	playerStates[userId] = newState
	return newState
end

function BallService.EnsureBallInstance(): Part
	if ballPart and ballPart.Parent ~= nil then
		return ballPart
	end
	local p = Instance.new("Part")
	p.Name = BALL_PART_NAME
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(2.5, 2.5, 2.5)
	p.Color = Color3.fromRGB(0, 255, 200)
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CFrame = CFrame.new(ballState.position)
	p:SetAttribute("IsMatchBall", true)
	p.Parent = Workspace
	ballPart = p
	return p
end

-- Section 4.3: Shooting Zone check (South attacks +Z >= 10, North attacks -Z <= -10, 1v1v1 <= 55 Studs from center)
function BallService.IsInShootingZone(ballPosition: Vector3, attackingTeam: string, gameMode: string?): boolean
	if gameMode == "1v1v1" then
		local horizontalDist = Vector3.new(ballPosition.X, 0, ballPosition.Z).Magnitude
		return horizontalDist <= 55.0
	end
	if attackingTeam == "North" or attackingTeam == "TeamB" then
		return ballPosition.Z <= -10.0
	end
	-- Default "South" / "TeamA" attacks toward +Z
	return ballPosition.Z >= 10.0
end

function BallService.GetBallState()
	return ballState
end

function BallService.SetBallPositionAndVelocity(pos: Vector3, vel: Vector3)
	ballState.position = pos
	ballState.velocity = vel
	if ballPart then
		ballPart.CFrame = CFrame.new(pos)
	end
end

function BallService.SetPossessor(userId: number?, incomingSpeed: number?)
	ballState.possessorUserId = userId
	if userId ~= nil then
		local st = getOrCreatePlayerState(userId)
		-- Bad First Touch check if receiving a fast pass while sprinting without slowing down
		if incomingSpeed and incomingSpeed > 68.0 and st.isSprinting then
			st.badFirstTouchUntil = os.clock() + 1.5
		end
		ballState.velocity = Vector3.zero
		ballState.laserGuidedPassActive = false
		ballState.miracleFinishActive = false
	end
end

function BallService.GetPossessorUserId(): number?
	return ballState.possessorUserId
end

function BallService.GetPlayerStamina(userId: number): number
	return getOrCreatePlayerState(userId).stamina
end

function BallService.SetPlayerStamina(userId: number, stamina: number)
	local st = getOrCreatePlayerState(userId)
	st.stamina = math.clamp(stamina, 0.0, 1.0)
end

function BallService.SetPlayerTeamSide(userId: number, teamSide: "North" | "South")
	local st = getOrCreatePlayerState(userId)
	st.teamSide = teamSide
end

function BallService.GetPlayerTeamSide(userId: number): "North" | "South"
	return getOrCreatePlayerState(userId).teamSide
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

function BallService.RecordTurnDirection(userId: number, newMoveDir: Vector3)
	if newMoveDir.Magnitude < 1e-3 then
		return
	end
	local st = getOrCreatePlayerState(userId)
	local unitDir = newMoveDir.Unit
	if st.lastMoveDir:Dot(unitDir) < -0.75 then
		-- Sharp 180-degree turn before duel triggers SharpTurnOffBalance
		st.sharpTurnUntil = os.clock() + 1.2
	end
	st.lastMoveDir = unitDir
end

function BallService.HasOnBallMistake(userId: number): (boolean, { string })
	local st = getOrCreatePlayerState(userId)
	local now = os.clock()
	local reasons: { string } = {}

	if st.stamina < Constants.STAMINA_EXHAUSTED_THRESHOLD then
		table.insert(reasons, "StaminaExhausted")
	end
	if now < st.badFirstTouchUntil then
		table.insert(reasons, "BadFirstTouch")
	end
	if now < st.sharpTurnUntil then
		table.insert(reasons, "SharpTurnOffBalance")
	end

	return (#reasons > 0), reasons
end

function BallService.HasSprintOvershootMistake(userId: number): boolean
	local st = getOrCreatePlayerState(userId)
	return st.isSprinting or (os.clock() < st.sprintOvershootUntil)
end

function BallService.ExecuteBallAction(
	player: Player,
	actionType: Types.BallActionType,
	aimVector: Vector3
): boolean
	if not Network.IsFiniteVector3(aimVector) then
		return false
	end

	local userId = player.UserId
	local st = getOrCreatePlayerState(userId)

	if actionType == "Sprint" then
		if st.stamina > 0.05 then
			st.isSprinting = true
			st.sprintOvershootUntil = os.clock() + 0.65
			return true
		end
		st.isSprinting = false
		return false
	end

	if ballState.possessorUserId ~= userId then
		return false
	end

	local dir = if aimVector.Magnitude > 1e-3 then aimVector.Unit else st.lastMoveDir
	local cardCfg = RigAndCardService.GetEquippedCardConfig(userId)
	local boostMult = BallService.GetActiveBoostMultiplier(userId)

	local speed = BASE_PASS_SPEED
	if actionType == "Pass" then
		speed = BASE_PASS_SPEED * cardCfg.statModifiers.passMultiplier * boostMult
	elseif actionType == "Shoot" then
		speed = BASE_SHOOT_SPEED * cardCfg.statModifiers.shotMultiplier * boostMult
	else
		return false
	end

	local launchVel = dir * speed
	local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)
	launchVel = CagePhysicsService.ApplyRampImpulse(launchVel, isOnRamp)

	ballState.possessorUserId = nil
	ballState.lastKickerUserId = userId
	ballState.lastKickTeam = st.teamSide
	ballState.velocity = launchVel

	return true
end

function BallService.StepPhysics(dt: number)
	local now = os.clock()
	for _, st in pairs(playerStates) do
		if st.isSprinting then
			st.stamina = math.max(0.0, st.stamina - (STAMINA_DRAIN_PER_SEC * dt))
			if st.stamina <= 0.02 then
				st.isSprinting = false
			end
		else
			st.stamina = math.min(1.0, st.stamina + (STAMINA_REGEN_PER_SEC * dt))
		end
		if now >= st.boostUntil then
			st.boostMultiplier = 1.0
		end
	end

	if ballState.possessorUserId ~= nil then
		local possessor = Players:GetPlayerByUserId(ballState.possessorUserId)
		if possessor and possessor.Character and possessor.Character.PrimaryPart then
			local rootCf = possessor.Character.PrimaryPart.CFrame
			ballState.position = rootCf.Position + (rootCf.LookVector * 2.5) + Vector3.new(0, -1.0, 0)
			ballState.velocity = Vector3.zero
		end
	else
		local velWithGravity = ballState.velocity + Vector3.new(0, GRAVITY_Y * dt, 0)
		-- Apply slight air/ground drag
		velWithGravity = velWithGravity * math.max(0.0, 1.0 - (0.35 * dt))
		local nextPos, nextVel = CagePhysicsService.StepBallCageCollision(ballState.position, velWithGravity, dt)
		ballState.position = nextPos
		ballState.velocity = nextVel
	end

	if ballPart then
		ballPart.CFrame = CFrame.new(ballState.position)
	end
end

function BallService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	BallService.EnsureBallInstance()

	local ballActionEvent = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	ballActionEvent.OnServerEvent:Connect(function(player: Player, actionType: any, aimVector: any)
		if (actionType == "Pass" or actionType == "Shoot" or actionType == "Sprint")
			and Network.IsFiniteVector3(aimVector)
		then
			BallService.ExecuteBallAction(player, actionType :: Types.BallActionType, aimVector :: Vector3)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerStates[player.UserId] = nil
		if ballState.possessorUserId == player.UserId then
			ballState.possessorUserId = nil
		end
	end)
end

return table.freeze(BallService)
