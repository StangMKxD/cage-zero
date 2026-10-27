--!strict
-- src/server/services/BallService.luau
-- Module 02: Server-Authoritative Ball Physics, Lifecycle & Ground Dribble/Receive
-- Governed by RF02-DRIBBLE-RECEIVE Contract (Owner Checklist 7, 2026-10-26 & Review026)
-- Server-authoritative custom position/velocity physics solver with bounded touch impulses,
-- proximity/relative-speed receive gates, deterministic contention resolution, and honest contact windows.
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
local activeCharacterConnections: { [number]: RBXScriptConnection } = {}
local ballPart: Part? = nil
local ballSpinRotation: CFrame = CFrame.identity
local isInitialized = false

local BallService = {}

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
		lastTouchInfo.touchId += 1
		lastTouchInfo.ownerUserId = userId
		lastTouchInfo.touchTime = os.clock()
		lastTouchInfo.action = "DirectSet"
		lastTouchInfo.touchCount += 1
	else
		ballState.possessorUserId = nil
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

-- =============================================================================
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

-- RF-F33: Strict transitive total order comparator
-- Guarantees mathematically strict weak ordering with zero pairwise cycles across all permutations.
local function compareCandidates(a: PlayerCandidate, b: PlayerCandidate): boolean
	if a.dist ~= b.dist then
		return a.dist < b.dist
	end
	return a.userId < b.userId
end

local function simulateDribbleAndReceive(dt: number, now: number)
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
			ballState.possessorUserId = winner.userId
			ballState.state = "Possessed"
			ballState.lastPossessingTeam = winner.teamSide

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
			ballState.velocity = forward * math.max(pSpeed, DribbleConfigs.MIN_RECEIVE_CUSHION_SPEED)
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
				break
			end
		end

		-- Carrier no longer valid (died, disconnected, or missing root part)
		if not carrierCand then
			ballState.possessorUserId = nil
			ballState.state = "Free"
			syncBallAttributes()
			return
		end

		-- Check if ball got away (Loose Ball trigger: distance exceeds LOOSE_BALL_DISTANCE)
		if carrierCand.dist > DribbleConfigs.LOOSE_BALL_DISTANCE then
			ballState.possessorUserId = nil
			ballState.state = "Free"
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
		-- If ball is outside contact range (e.g. 4.5 < dist <= 7.5 or ball overhead/high),
		-- carrier retains possession state but CANNOT touch or damp the ball!
		-- Ball continues traveling freely under autonomous physics solver.
		local carrierInContact = carrierCand.isGrounded
			and (ballState.position.Y <= DribbleConfigs.GROUNDED_MAX_BALL_Y)
			and (carrierCand.vertGap <= DribbleConfigs.MAX_RECEIVE_VERTICAL_GAP)
			and (carrierCand.dist <= DribbleConfigs.MAX_RECEIVE_DISTANCE)
			and (carrierCand.relSpeed <= DribbleConfigs.MAX_RECEIVE_RELATIVE_SPEED)

		if not carrierInContact then
			-- Out of physical contact window: preserve free physics flight/roll without modification
			return
		end

		local moveDir = carrierCand.humanoid.MoveDirection
		local cVel = carrierCand.rootPart.AssemblyLinearVelocity
		local horizSpeed = Vector3.new(cVel.X, 0, cVel.Z).Magnitude
		local isMoving = (
			moveDir.Magnitude > DribbleConfigs.MOVE_DIRECTION_THRESHOLD
			or horizSpeed > DribbleConfigs.MIN_PLAYER_MOVE_SPEED
		)

		if not isMoving then
			-- RF-F31: Idle stop: dt-independent exponential cushion damping within contact gate
			-- Replaces naive every-frame multiplication to avoid infinite-magnet attraction
			local decay = math.exp(-DribbleConfigs.CUSHION_DAMPING_RATE * dt)
			ballState.velocity = ballState.velocity * decay
			if ballState.velocity.Magnitude < Constants.BALL_REST_THRESHOLD_SPEED then
				ballState.velocity = Vector3.zero
			end
			lastTouchInfo.action = "Cushion"
		else
			-- Moving: Check touch cooldown cadence
			local isSprinting = (carrierCand.character:GetAttribute("IsSprinting") == true)
			local cooldown = if isSprinting then DribbleConfigs.TOUCH_COOLDOWN_SPRINT else DribbleConfigs.TOUCH_COOLDOWN_NORMAL
			local lastTouch = lastTouchTimeByPlayer[carrierCand.userId] or 0

			if (now - lastTouch) >= cooldown then
				local forward = if moveDir.Magnitude > DribbleConfigs.TARGET_DIRECTION_THRESHOLD
					then moveDir.Unit
					else Vector3.new(carrierCand.rootPart.CFrame.LookVector.X, 0, carrierCand.rootPart.CFrame.LookVector.Z).Unit
				local targetSpot = carrierCand.rootPart.Position + forward * DribbleConfigs.DRIBBLE_TOUCH_FORWARD_OFFSET
				local toTarget = (targetSpot - ballState.position)
				local horizToTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
				local targetSpeed = if isSprinting then DribbleConfigs.DRIBBLE_TOUCH_SPEED_SPRINT else DribbleConfigs.DRIBBLE_TOUCH_SPEED_WALK

				local impulseDir = if horizToTarget.Magnitude > DribbleConfigs.TARGET_DIRECTION_THRESHOLD
					then (forward * 0.70 + horizToTarget.Unit * 0.30).Unit
					else forward

				local finalSpeed = math.min(targetSpeed, DribbleConfigs.MAX_BALL_DRIBBLE_SPEED)
				local touchVel = impulseDir * finalSpeed
				ballState.velocity = Vector3.new(touchVel.X, DribbleConfigs.DRIBBLE_TOUCH_VERTICAL_IMPULSE, touchVel.Z)

				lastTouchTimeByPlayer[carrierCand.userId] = now
				lastTouchInfo.touchId += 1
				lastTouchInfo.ownerUserId = carrierCand.userId
				lastTouchInfo.touchTime = now
				lastTouchInfo.action = "DribbleTouch"
				lastTouchInfo.touchCount += 1
				syncBallAttributes()
			end
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

	-- 1. Server-authoritative Dribble & Receive simulation
	simulateDribbleAndReceive(clampedDt, now)

	-- 2. Physical flight, Cage collision, and Turf rolling friction
	local r = Constants.BALL_RADIUS
	local isOnRamp = CagePhysicsService.IsPositionOnElevatingRamp(ballState.position)
	local onGround = not isOnRamp and (ballState.position.Y <= r + 0.08) and (math.abs(ballState.velocity.Y) < 3.0)

	local currentVel = ballState.velocity
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

		local rollFriction = Constants.GROUND_ROLLING_FRICTION
		local frictionDecel = math.max(0.0, 1.0 - (rollFriction * clampedDt))
		nextVel = Vector3.new(nextVel.X * frictionDecel, nextVel.Y, nextVel.Z * frictionDecel)

		if nextVel.Magnitude < Constants.BALL_REST_THRESHOLD_SPEED then
			nextVel = Vector3.zero
			nextPos = Vector3.new(nextPos.X, r, nextPos.Z)
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
			local rotAngle = (rollSpd / Constants.BALL_RADIUS) * clampedDt
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

	local currentGen = (playerGenerations[userId] or 0) + 1
	playerGenerations[userId] = currentGen
	local activeCharacter: Model? = nil

	local function onCharAdded(char: Model)
		if player.Character ~= char then
			return
		end
		activeCharacter = char
		local thisGen = currentGen
		local oldConnection = activeCharacterConnections[userId]
		if oldConnection then
			oldConnection:Disconnect()
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

		activeCharacterConnections[userId] = humanoid.Died:Connect(function()
			if playerGenerations[userId] == thisGen and activeCharacter == char and ballState.possessorUserId == userId then
				ballState.possessorUserId = nil
				ballState.state = "Free"
				syncBallAttributes()
			end
		end)
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
			activeCharacter = nil
			playerGenerations[userId] = (playerGenerations[userId] or 0) + 1
			lastPlayerPositions[userId] = nil
			local deathConnection = activeCharacterConnections[userId]
			if deathConnection then
				deathConnection:Disconnect()
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
		playerStates[uid] = nil
		lastTouchTimeByPlayer[uid] = nil
		lastStealTimeByPlayer[uid] = nil
		lastPlayerPositions[uid] = nil
		playerGenerations[uid] = nil
		local deathConnection = activeCharacterConnections[uid]
		if deathConnection then
			deathConnection:Disconnect()
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
