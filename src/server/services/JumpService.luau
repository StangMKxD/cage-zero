--!strict
-- src/server/services/JumpService.luau
-- Authoritative Server Service for Player Jump Mechanics & Airborne Flight Envelope Validation
-- Governed by RF02-DRIBBLE-RECEIVE Contract (Owner Additive Scope, Review026 RF-F35 & jump-stutter-only-HANDOFF)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JumpConfigs = require(Shared:WaitForChild("configs"):WaitForChild("JumpConfigs"))
local SprintConfigs = require(Shared:WaitForChild("configs"):WaitForChild("SprintConfigs"))

type FlightState = {
	isAirborne: boolean,
	isLedgeFall: boolean,
	takeoffTime: number,
	takeoffPos: Vector3,
	takeoffVerticalSpeed: number,
	takeoffYaw: number,
	takeoffSpeed: number,
	takeoffDirection: Vector3,
	lastGroundedSpeed: number,
	lastGroundedDirection: Vector3,
	lastGroundedYaw: number,
	lastGroundedTime: number,
	lastPosition: Vector3,
	horizontalMovementBudget: number,
	correctionCount: number,
	lastCorrectionReason: string,
	lastObservedYaw: number?,
}

local playerFlightStates: { [Player]: FlightState } = {}
local activeConnections: { [Player]: { RBXScriptConnection } } = {}
local lifecycleConnections: { [Player]: { RBXScriptConnection } } = {}
local boundCharacters: { [Player]: Model } = {}
local characterGenerations: { [Player]: number } = {}
local isInitialized = false

local JumpService = {}

local function getOrCreateFlightState(player: Player): FlightState
	local state = playerFlightStates[player]
	if state then
		return state
	end
	local newState: FlightState = {
		isAirborne = false,
		isLedgeFall = false,
		takeoffTime = 0,
		takeoffPos = Vector3.zero,
		takeoffVerticalSpeed = 0,
		takeoffYaw = 0,
		takeoffSpeed = 0,
		takeoffDirection = Vector3.zero,
		lastGroundedSpeed = 0,
		lastGroundedDirection = Vector3.zero,
		lastGroundedYaw = 0,
		lastGroundedTime = os.clock(),
		lastPosition = Vector3.zero,
		horizontalMovementBudget = JumpConfigs.SERVER_POSITION_TOLERANCE,
		correctionCount = 0,
		lastCorrectionReason = "None",
		lastObservedYaw = nil,
	}
	playerFlightStates[player] = newState
	return newState
end

local function cleanupPlayer(player: Player)
	playerFlightStates[player] = nil
	characterGenerations[player] = nil
	boundCharacters[player] = nil
	local conns = activeConnections[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		activeConnections[player] = nil
	end
	local lifecycleConns = lifecycleConnections[player]
	if lifecycleConns then
		for _, connection in lifecycleConns do
			connection:Disconnect()
		end
		lifecycleConnections[player] = nil
	end
end

local function onLiftoff(player: Player, hrp: BasePart, hum: Humanoid, isLedgeFall: boolean)
	local state = getOrCreateFlightState(player)
	if state.isAirborne then
		return
	end

	local currentVel = hrp.AssemblyLinearVelocity
	-- Guard against coalesced Jumping -> Freefall replication classifying a rising jump as a ledge fall
	local effectiveLedgeFall = isLedgeFall and (currentVel.Y <= JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY)

	state.isAirborne = true
	state.isLedgeFall = effectiveLedgeFall
	state.takeoffTime = os.clock()
	state.takeoffPos = hrp.Position
	state.takeoffVerticalSpeed = if effectiveLedgeFall
		then math.min(currentVel.Y, 0)
		else JumpConfigs.JUMP_POWER
	state.lastPosition = hrp.Position
	state.horizontalMovementBudget = JumpConfigs.SERVER_POSITION_TOLERANCE

	-- Authoritative liftoff yaw: snapshot current character facing
	local _, y, _ = hrp.CFrame:ToOrientation()
	state.takeoffYaw = y
	state.lastObservedYaw = nil

	-- Validate takeoff horizontal speed against maximum allowed grounded speed (Sprint Speed + tolerance)
	local horizVel = Vector3.new(currentVel.X, 0, currentVel.Z)
	local rawSpeed = horizVel.Magnitude

	-- Snapshot verified grounded momentum before takeoff (guards against premature sprint WalkSpeed reset)
	local validSpeed = math.max(rawSpeed, state.lastGroundedSpeed)
	state.takeoffSpeed = math.clamp(validSpeed, 0, JumpConfigs.MAX_AIR_HORIZONTAL_SPEED)

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude > 0.1 then
		state.takeoffDirection = moveDir.Unit
	elseif rawSpeed > 1.0 then
		state.takeoffDirection = horizVel.Unit
	elseif state.lastGroundedDirection.Magnitude > 0.1 then
		state.takeoffDirection = state.lastGroundedDirection
	else
		state.takeoffDirection = Vector3.zero
	end
end

local function onLanded(player: Player, hrp: BasePart)
	local state = getOrCreateFlightState(player)
	state.isAirborne = false
	state.isLedgeFall = false
	state.takeoffSpeed = 0
	state.takeoffDirection = Vector3.zero
	state.lastPosition = hrp.Position
	state.horizontalMovementBudget = JumpConfigs.SERVER_POSITION_TOLERANCE
end

local function recordCorrection(state: FlightState, char: Model?, reason: string)
	state.correctionCount += 1
	state.lastCorrectionReason = reason
	if char and char:GetAttribute("JumpDiagEnabled") == true then
		char:SetAttribute("JumpServerCorrectionCount", state.correctionCount)
		char:SetAttribute("JumpServerLastReason", reason)
	end
end

local function validateAirborneEnvelope(player: Player, hrp: BasePart, _hum: Humanoid, dt: number)
	local state = playerFlightStates[player]
	if not state or not state.isAirborne then
		return
	end

	local char = player.Character
	local now = os.clock()
	local flightDuration = math.max(0, now - state.takeoffTime)
	local currentVel = hrp.AssemblyLinearVelocity

	-- Reconcile delayed jump launch replication if Freefall arrived 1 frame before upward jump velocity
	if state.isLedgeFall
		and flightDuration <= JumpConfigs.RECENT_GROUND_TOLERANCE_SEC
		and currentVel.Y > JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY then
		state.isLedgeFall = false
		state.takeoffVerticalSpeed = JumpConfigs.JUMP_POWER
		state.takeoffPos = Vector3.new(
			state.takeoffPos.X,
			math.min(state.takeoffPos.Y, hrp.Position.Y),
			state.takeoffPos.Z
		)
		local _, y, _ = hrp.CFrame:ToOrientation()
		state.takeoffYaw = y
	end

	local horizVel = Vector3.new(currentVel.X, 0, currentVel.Z)

	-- 1. Velocity Cap Validation: Reject forged client airborne acceleration / speed hacks
	if horizVel.Magnitude > JumpConfigs.MAX_AIR_HORIZONTAL_SPEED + 2.0 then
		local clampedHoriz = horizVel.Unit * JumpConfigs.MAX_AIR_HORIZONTAL_SPEED
		hrp.AssemblyLinearVelocity = Vector3.new(clampedHoriz.X, currentVel.Y, clampedHoriz.Z)
		currentVel = hrp.AssemblyLinearVelocity
		recordCorrection(state, char, "HorizVelCap")
	end
	if not state.isLedgeFall
		and currentVel.Y > JumpConfigs.JUMP_POWER + JumpConfigs.SERVER_VERTICAL_SPEED_TOLERANCE then
		hrp.AssemblyLinearVelocity = Vector3.new(
			currentVel.X,
			JumpConfigs.JUMP_POWER + JumpConfigs.SERVER_VERTICAL_SPEED_TOLERANCE,
			currentVel.Z
		)
		currentVel = hrp.AssemblyLinearVelocity
		recordCorrection(state, char, "VertVelCap")
	end

	-- 2. Horizontal displacement envelope: validate both per-step anti-teleport delta
	-- and cumulative horizontal radius from takeoffPos.
	local currentPosition = hrp.Position
	local delta = currentPosition - state.lastPosition
	local horizontalDelta = Vector3.new(delta.X, 0, delta.Z)
	local pingAllowance = math.clamp(player:GetNetworkPing(), 0, 0.25)

	local stepTimeAllowance = math.max(dt, 1 / 60) * 2.0 + pingAllowance
	local availableMovementBudget = JumpConfigs.MAX_AIR_HORIZONTAL_SPEED * stepTimeAllowance
		+ JumpConfigs.SERVER_POSITION_TOLERANCE
	state.horizontalMovementBudget = availableMovementBudget

	local correctedPosition = currentPosition
	local positionCorrectedReason: string? = nil

	if horizontalDelta.Magnitude > availableMovementBudget then
		local boundedDelta = horizontalDelta.Unit * availableMovementBudget
		correctedPosition = Vector3.new(
			state.lastPosition.X + boundedDelta.X,
			currentPosition.Y,
			state.lastPosition.Z + boundedDelta.Z
		)
		positionCorrectedReason = "HorizStepBudget"
	else
		local totalHorizFromTakeoff = Vector3.new(
			currentPosition.X - state.takeoffPos.X,
			0,
			currentPosition.Z - state.takeoffPos.Z
		)
		local maxCumulativeHoriz = JumpConfigs.MAX_AIR_HORIZONTAL_SPEED * (flightDuration + pingAllowance)
			+ JumpConfigs.SERVER_POSITION_TOLERANCE * 2.0
		if totalHorizFromTakeoff.Magnitude > maxCumulativeHoriz then
			local clampedOffset = totalHorizFromTakeoff.Unit * maxCumulativeHoriz
			correctedPosition = Vector3.new(
				state.takeoffPos.X + clampedOffset.X,
				currentPosition.Y,
				state.takeoffPos.Z + clampedOffset.Z
			)
			positionCorrectedReason = "HorizCumulativeBudget"
		end
	end

	-- Bound upward position against the server-owned launch trajectory, including the
	-- full kinematic integral of the bounded soft-apex counter-acceleration:
	-- dy_soft = 0.5 * a_soft * t_active^2 + (a_soft * t_active) * t_after
	local effectiveLaunchVy = state.takeoffVerticalSpeed
	if not state.isLedgeFall then
		effectiveLaunchVy = math.max(state.takeoffVerticalSpeed, JumpConfigs.JUMP_POWER + 2.0)
	end

	local function expectedYAt(t: number): number
		local softStart = math.max(
			0,
			(JumpConfigs.JUMP_POWER - JumpConfigs.APEX_SOFT_ZONE_VY_MAX) / JumpConfigs.GRAVITY
		)
		local sinceSoft = if state.isLedgeFall then 0 else math.max(0, t - softStart)
		local activeSoft = math.min(sinceSoft, JumpConfigs.APEX_SOFT_MAX_DURATION)
		local postSoft = math.max(0, sinceSoft - JumpConfigs.APEX_SOFT_MAX_DURATION)
		local accel = JumpConfigs.GRAVITY * JumpConfigs.APEX_GRAVITY_DAMPING
		return state.takeoffPos.Y
			+ effectiveLaunchVy * t
			- 0.5 * JumpConfigs.GRAVITY * (t ^ 2)
			+ 0.5 * accel * (activeSoft ^ 2)
			+ (accel * activeSoft) * postSoft
	end
	-- The server's liftoff clock and replicated root position lag the owning client. While rising, the
	-- skewed (earlier) point on the trajectory is lower, so max() keeps the rising bound strict; while
	-- falling it is higher, which stops false VertPosEnvelope snaps of a legitimately descending character.
	local expectedY = math.max(
		expectedYAt(flightDuration),
		expectedYAt(math.max(0, flightDuration - JumpConfigs.SERVER_FLIGHT_CLOCK_SKEW_SEC))
	)
	local verticalPositionTolerance = JumpConfigs.SERVER_VERTICAL_POSITION_TOLERANCE
		+ math.min(math.abs(currentVel.Y) * pingAllowance, JumpConfigs.SERVER_VERTICAL_POSITION_TOLERANCE)
	local maxExpectedY = expectedY + verticalPositionTolerance
	if currentPosition.Y > maxExpectedY then
		correctedPosition = Vector3.new(
			correctedPosition.X,
			maxExpectedY,
			correctedPosition.Z
		)
		positionCorrectedReason = positionCorrectedReason or "VertPosEnvelope"
	end

	-- 3. Yaw Invariance Validation:
	-- During the initial takeoff replication settle window (TAKEOFF_YAW_SETTLE_WINDOW_SEC),
	-- latch the client's replicated liftoff yaw so turning on the takeoff frame does not
	-- snap the rising character back to a stale pre-turn server CFrame.
	local _, currentYaw, _ = hrp.CFrame:ToOrientation()
	-- Replication lag: if the replicated yaw is still moving after the nominal settle window (client had a ground turn in
	-- progress at liftoff), keep adopting it until it stops, bounded by TAKEOFF_YAW_CATCHUP_MAX_SEC.
	local yawSettling = flightDuration <= JumpConfigs.TAKEOFF_YAW_SETTLE_WINDOW_SEC
	local lastObservedYaw = state.lastObservedYaw
	if not yawSettling and lastObservedYaw ~= nil and flightDuration <= JumpConfigs.TAKEOFF_YAW_CATCHUP_MAX_SEC then
		local stepDiff = math.abs(currentYaw - lastObservedYaw)
		if stepDiff > math.pi then
			stepDiff = 2 * math.pi - stepDiff
		end
		if stepDiff > math.rad(0.5) then
			yawSettling = true
		end
	end
	state.lastObservedYaw = currentYaw
	if yawSettling then
		state.takeoffYaw = currentYaw
	end

	local yawDiff = math.abs(currentYaw - state.takeoffYaw)
	if yawDiff > math.pi then
		yawDiff = 2 * math.pi - yawDiff
	end

	local maxAllowedYawDiv = math.rad(JumpConfigs.SERVER_YAW_TOLERANCE_DEG)
	local correctedYaw = currentYaw
	if not yawSettling and yawDiff > maxAllowedYawDiv then
		correctedYaw = state.takeoffYaw
		positionCorrectedReason = positionCorrectedReason or "YawDivergence"
	end

	if correctedPosition ~= currentPosition or correctedYaw ~= currentYaw then
		local preservedVel = hrp.AssemblyLinearVelocity
		hrp.CFrame = CFrame.new(correctedPosition) * CFrame.Angles(0, correctedYaw, 0)
		hrp.AssemblyLinearVelocity = preservedVel
		if positionCorrectedReason then
			recordCorrection(state, char, positionCorrectedReason)
		end
	end
	if correctedYaw ~= currentYaw then
		hrp.AssemblyAngularVelocity = Vector3.zero
	end
	state.lastPosition = hrp.Position

	-- 4. Flight Envelope Duration / Exploit Check. If a client suppresses descent,
	-- force downward motion after the configured maximum flight duration.
	local maxFlightDuration = if state.isLedgeFall
		then JumpConfigs.SERVER_MAX_FLIGHT_DURATION_SEC
		else JumpConfigs.EXPECTED_APEX_TIME * 2 + JumpConfigs.APEX_SOFT_MAX_DURATION + 0.3
	if flightDuration > maxFlightDuration then
		if currentVel.Y > -20.0 then
			local latestVelocity = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(latestVelocity.X, -20.0, latestVelocity.Z)
			recordCorrection(state, char, "MaxFlightDuration")
		end
	end
end

local function bindCharacter(player: Player, character: Model)
	if player.Character ~= character or not character:IsDescendantOf(game) then
		return
	end

	local currentGen = (characterGenerations[player] or 0) + 1
	characterGenerations[player] = currentGen
	boundCharacters[player] = character

	local prevConns = activeConnections[player]
	if prevConns then
		for _, c in ipairs(prevConns) do
			c:Disconnect()
		end
		activeConnections[player] = nil
	end
	playerFlightStates[player] = nil

	local conns: { RBXScriptConnection } = {}

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if characterGenerations[player] ~= currentGen
		or player.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid then
		return
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?

	-- Post-yield generation and hierarchy verification
	if characterGenerations[player] ~= currentGen
		or player.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid
		or not hrp then
		return
	end

	-- Configure Humanoid Jump parameters
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JumpConfigs.JUMP_POWER
	humanoid.JumpHeight = JumpConfigs.EXPECTED_APEX_HEIGHT
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	local flightState = getOrCreateFlightState(player)
	flightState.isAirborne = false
	flightState.lastPosition = hrp.Position
	flightState.horizontalMovementBudget = JumpConfigs.SERVER_POSITION_TOLERANCE

	-- State observer
	local stateConn = humanoid.StateChanged:Connect(function(_oldState, newState)
		if characterGenerations[player] ~= currentGen then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			onLiftoff(player, hrp, humanoid, false)
		elseif newState == Enum.HumanoidStateType.Freefall then
			if not flightState.isAirborne then
				local isRisingJump = hrp.AssemblyLinearVelocity.Y > JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY
				onLiftoff(player, hrp, humanoid, not isRisingJump)
			end
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			if flightState.isAirborne then
				onLanded(player, hrp)
			end
		elseif newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.Seated
			or newState == Enum.HumanoidStateType.Swimming
			or newState == Enum.HumanoidStateType.Climbing then
			flightState.isAirborne = false
			flightState.isLedgeFall = false
		end
	end)
	table.insert(conns, stateConn)

	local diedConn = humanoid.Died:Connect(function()
		if characterGenerations[player] == currentGen then
			flightState.isAirborne = false
			flightState.isLedgeFall = false
		end
	end)
	table.insert(conns, diedConn)

	activeConnections[player] = conns
end

function JumpService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Server validation Heartbeat step
	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char and char:IsDescendantOf(game) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local state = playerFlightStates[player]

				if hum and hum.Health > 0 and hrp and state then
					if state.isAirborne then
						validateAirborneEnvelope(player, hrp, hum, dt)
					else
						-- Grounded: Track rolling verified momentum for takeoff snapshot
						local hVel = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
						state.lastGroundedSpeed = hVel.Magnitude
						local moveDir = hum.MoveDirection
						if moveDir.Magnitude > 0.1 then
							state.lastGroundedDirection = moveDir.Unit
						elseif hVel.Magnitude > 1.0 then
							state.lastGroundedDirection = hVel.Unit
						end
						local _, y, _ = hrp.CFrame:ToOrientation()
						state.lastGroundedYaw = y
						state.lastGroundedTime = now
						state.lastPosition = hrp.Position
						state.horizontalMovementBudget = JumpConfigs.SERVER_POSITION_TOLERANCE
					end
				end
			end
		end
	end)

	local function onCharacterRemoving(player: Player, character: Model)
		if boundCharacters[player] ~= character then
			return
		end
		boundCharacters[player] = nil
		characterGenerations[player] = (characterGenerations[player] or 0) + 1
		local conns = activeConnections[player]
		if conns then
			for _, connection in conns do
				connection:Disconnect()
			end
			activeConnections[player] = nil
		end
		playerFlightStates[player] = nil
	end

	local function connectPlayer(player: Player)
		getOrCreateFlightState(player)
		local conns: { RBXScriptConnection } = {}
		table.insert(conns, player.CharacterRemoving:Connect(function(character)
			onCharacterRemoving(player, character)
		end))
		table.insert(conns, player.CharacterAdded:Connect(function(character)
			bindCharacter(player, character)
		end))
		lifecycleConnections[player] = conns
		if player.Character then
			task.spawn(bindCharacter, player, player.Character)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		connectPlayer(player)
	end

	Players.PlayerAdded:Connect(connectPlayer)

	Players.PlayerRemoving:Connect(cleanupPlayer)
end

function JumpService.GetFlightState(player: Player): FlightState?
	return playerFlightStates[player]
end

return table.freeze(JumpService)
