--!strict
-- src/server/services/BallService.luau
-- Module 02: Server-Authoritative Ball Physics & Lifecycle (Option A Cleanup Baseline)
-- Autonomous server free ball simulation in HexCageArena with baseline turf and collision physics.
-- Legacy Plan 02/03 action routers, poses, and continuous possession mechanics excised.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Types = require(Shared:WaitForChild("Types"))

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

local playerStates: { [number]: PlayerMovementState } = {}
local ballPart: Part? = nil
local ballSpinRotation: CFrame = CFrame.identity
local isInitialized = false

local BallService = {}

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
		curveImpulse = nil,
		inFlightAction = nil,
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
	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end
	if ballPart then
		ballPart.CFrame = CFrame.new(pos)
	end
	syncBallAttributes()
end

function BallService.SetPossessor(_userId: number?)
	-- Option A Baseline: Free ball only. Ball never acquires a carrier.
	ballState.possessorUserId = nil
	ballState.state = "Free"
	syncBallAttributes()
end

function BallService.GetPossessorUserId(): number?
	return nil
end

function BallService.GetLastPossessingTeam(): Types.TeamSide?
	return ballState.lastPossessingTeam
end

function BallService.SetPlayerTeamSide(userId: number, teamSide: Types.TeamSide)
	local st = getOrCreatePlayerState(userId)
	st.teamSide = teamSide
end

function BallService.GetPlayerTeamSide(userId: number): Types.TeamSide
	return getOrCreatePlayerState(userId).teamSide
end

function BallService.ResetBall(customPos: Vector3?, initialPossessingTeam: Types.TeamSide?)
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

	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end
	if ballPart then
		ballPart.Size = Vector3.new(Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2, Constants.BALL_RADIUS * 2)
		ballPart.CFrame = CFrame.new(spawnPos)
	end
	syncBallAttributes()
end

-- =============================================================================
-- Autonomous Free Ball Simulation (Option A Baseline)
-- =============================================================================
function BallService.StepPhysics(dt: number)
	local r = Constants.BALL_RADIUS
	local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)
	local onGround = not isOnRamp and (ballState.position.Y <= r + 0.08) and (math.abs(ballState.velocity.Y) < 3.0)

	local currentVel = ballState.velocity
	if onGround then
		-- Suppress downward velocity when resting on turf
		currentVel = Vector3.new(currentVel.X, 0, currentVel.Z)
		ballState.position = Vector3.new(ballState.position.X, r, ballState.position.Z)
	else
		-- Option A: Normal baseline gravity (No Pass-special gravity)
		local effGravity = Constants.GRAVITY_ACCELERATION_Y
		currentVel = currentVel + Vector3.new(0, effGravity * dt, 0)
		currentVel = currentVel * math.max(0.0, 1.0 - (0.20 * dt))
	end

	local prevPos = ballState.position
	local nextPos, nextVel = CagePhysicsService.StepBallCageCollision(prevPos, currentVel, dt)

	-- Turf contact & rolling friction (Option A: Normal friction only)
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

		local rollFriction = Constants.GROUND_ROLLING_FRICTION
		local frictionDecel = math.max(0.0, 1.0 - (rollFriction * dt))
		nextVel = Vector3.new(nextVel.X * frictionDecel, nextVel.Y, nextVel.Z * frictionDecel)

		if nextVel.Magnitude < Constants.BALL_REST_THRESHOLD_SPEED then
			nextVel = Vector3.zero
			nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
			ballState.state = "Free"
			ballState.inFlightAction = nil
		end
	end

	ballState.position = nextPos
	ballState.velocity = nextVel

	-- Part synchronization and roll spin CFrame
	local hVel = ballState.velocity
	local rollSpd = hVel.Magnitude
	if rollSpd > 0.1 then
		local velUnit = hVel.Unit
		local rotAxis = Vector3.new(0, 1, 0):Cross(velUnit)
		if rotAxis.Magnitude > 0.01 then
			local rotAngle = (rollSpd / Constants.BALL_RADIUS) * dt
			ballSpinRotation = CFrame.fromAxisAngle(rotAxis.Unit, rotAngle) * ballSpinRotation
		end
	end

	if not ballPart or ballPart.Parent == nil then
		BallService.EnsureBallInstance()
	end

	if ballPart then
		ballPart.CFrame = CFrame.new(ballState.position) * ballSpinRotation
	end
	syncBallAttributes()
end

-- =============================================================================
-- Player Lifecycle & Bootstrap
-- =============================================================================
local function setupPlayerLifecycle(player: Player)
	local userId = player.UserId
	getOrCreatePlayerState(userId)

	local function onCharAdded(char: Model)
		local humanoid = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			-- Option A: Restore native Humanoid locomotion and jumping
			humanoid.UseJumpPower = true
			humanoid.JumpPower = 50
			humanoid.JumpHeight = 7.2
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		end
	end

	if player.Character then
		onCharAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharAdded)
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

	-- Enumerate existing players and setup lifecycle
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayerLifecycle(player)
	end
	Players.PlayerAdded:Connect(setupPlayerLifecycle)

	Players.PlayerRemoving:Connect(function(player: Player)
		playerStates[player.UserId] = nil
	end)
end

return table.freeze(BallService)
