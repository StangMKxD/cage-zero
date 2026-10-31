--!strict
-- src/server/services/SprintService.luau
-- Authoritative Server Service for Player Sprint Mechanics
-- Governed by RF02-IDLE-RUNTIME Contract (Owner Scope Delta 2026-10-26 & Additive Scope)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local SprintConfigs = require(Shared:WaitForChild("configs"):WaitForChild("SprintConfigs"))
local DribbleActionConfigs = require(Shared:WaitForChild("configs"):WaitForChild("DribbleActionConfigs"))
local SprintSpeedRules = require(Shared:WaitForChild("SprintSpeedRules"))

local lastSprintStartTime: { [Player]: number } = {}
local activeConnections: { [Player]: { RBXScriptConnection } } = {}
local characterGenerations: { [Player]: number } = {}
local speedStates: { [Player]: SprintSpeedRules.State } = {}
local isInitialized = false

local SprintService = {}

local function cleanupPlayer(player: Player)
	lastSprintStartTime[player] = nil
	characterGenerations[player] = nil
	speedStates[player] = nil
	local conns = activeConnections[player]
	if conns then
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
		activeConnections[player] = nil
	end
end

local function setSprintState(player: Player, shouldSprint: boolean, forward: number?, lateral: number?)
	local character = player.Character
	if not character or not character:IsDescendantOf(game) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return
	end
	-- Owner-approved G close-control mode: Shift cannot raise its server speed cap.
	if character:GetAttribute("GoalDribbleActive") == true or character:GetAttribute("ServerShotPhase") == "Charging" then
		speedStates[player] = nil
		humanoid.WalkSpeed = DribbleActionConfigs.GOAL_SPEED
		character:SetAttribute("IsSprinting", false)
		if shouldSprint then
			character:SetAttribute("SprintRejectedSeq", (character:GetAttribute("SprintRejectedSeq") or 0) + 1)
		end
		return
	end

	if shouldSprint then
		-- Verify not in a state that forbids sprinting
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.Climbing
			or state == Enum.HumanoidStateType.Swimming
			or state == Enum.HumanoidStateType.Seated
			or state == Enum.HumanoidStateType.Dead
			or state == Enum.HumanoidStateType.Physics
			or state == Enum.HumanoidStateType.PlatformStanding then
			humanoid.WalkSpeed = SprintConfigs.NORMAL_WALK_SPEED
			character:SetAttribute("IsSprinting", false)
			character:SetAttribute("SprintRejectedSeq", (character:GetAttribute("SprintRejectedSeq") or 0) + 1)
			return
		end

		local speedState = speedStates[player] or SprintSpeedRules.New()
		speedStates[player] = speedState
		SprintSpeedRules.SetDirection(speedState, forward or 0, lateral or 0, os.clock())
		humanoid.WalkSpeed = speedState.speed
		character:SetAttribute("SprintForward", forward == 1)
		character:SetAttribute("SprintTurnUntil", speedState.penaltyUntil)
		character:SetAttribute("IsSprinting", true)
	else
		humanoid.WalkSpeed = SprintConfigs.NORMAL_WALK_SPEED
		character:SetAttribute("IsSprinting", false)
	end
end

local function onSprintIntentRequest(player: Player, payload: any)
	local shouldSprint: boolean = false
	local forward = 0
	local lateral = 0

	-- Security Gate 1: Strict validation of client intent payload (RF-F44 fix & 360° Analog Sprint).
	-- Never accepts arbitrary client speed/velocity. Server chooses authoritative configured speed.
	-- Sprint allowed when Shift is held and character is moving (isMoving == true, or forward ~= 0).
	if typeof(payload) == "table" then
		local isShiftHeld = payload.isShiftHeld
		if typeof(isShiftHeld) ~= "boolean" then
			return
		end

		local lateralValue = if payload.lateral == nil then 0 else payload.lateral
		if not SprintSpeedRules.IsAxis(payload.forward) or not SprintSpeedRules.IsAxis(lateralValue) then return end
		forward = payload.forward
		lateral = lateralValue
		local isMoving = false
		if typeof(payload.isMoving) == "boolean" then
			isMoving = payload.isMoving
		elseif typeof(payload.forward) == "number" then
			-- Backwards-compatible domain check: domain must be {-1, 0, 1}
			if payload.forward ~= -1 and payload.forward ~= 0 and payload.forward ~= 1 then
				return
			end
			isMoving = (payload.forward ~= 0)
		else
			return
		end

		if isMoving ~= (forward ~= 0 or lateral ~= 0) then return end
		shouldSprint = (isShiftHeld == true and isMoving == true)
	elseif payload == false then
		-- Fail-safe stop request is allowed as a boolean `false`
		shouldSprint = false
	else
		-- Malformed payload (nil, true without direction, number, string, array, etc.): reject safely
		return
	end

	-- Security Gate 2: If requesting to start sprint, apply rate limiting to prevent network spam.
	-- If requesting to stop (shouldSprint == false), NEVER rate-limit, guaranteeing release can never get stuck!
	if shouldSprint then
		local now = os.clock()
		local lastStart = lastSprintStartTime[player] or 0
		if (now - lastStart) < SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC
			and not (player.Character and player.Character:GetAttribute("IsSprinting") == true) then
			-- Rate limit exceeded: reject start request and signal rejection sequence (RF-F45/RF-F48 fix)
			local char = player.Character
			if char and char:IsDescendantOf(game) then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed = if char:GetAttribute("GoalDribbleActive") == true or char:GetAttribute("ServerShotPhase") == "Charging" then DribbleActionConfigs.GOAL_SPEED else SprintConfigs.NORMAL_WALK_SPEED
				end
				char:SetAttribute("IsSprinting", false)
				char:SetAttribute("SprintRejectedSeq", (char:GetAttribute("SprintRejectedSeq") or 0) + 1)
			end
			return
		end
		lastSprintStartTime[player] = now
	end

	-- Security Gate 3: Live R15 character validation and authoritative speed assignment
	setSprintState(player, shouldSprint, forward, lateral)
end

local function bindCharacter(player: Player, character: Model)
	speedStates[player] = nil
	local currentGen = (characterGenerations[player] or 0) + 1
	characterGenerations[player] = currentGen

	-- Disconnect previous connections for this player
	local prevConns = activeConnections[player]
	if prevConns then
		for _, c in ipairs(prevConns) do
			c:Disconnect()
		end
		activeConnections[player] = nil
	end

	local conns: { RBXScriptConnection } = {}

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?

	-- Post-yield generation and hierarchy verification
	if characterGenerations[player] ~= currentGen
		or player.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid
		or not humanoid:IsDescendantOf(character) then
		return
	end

	-- Initialize walk speed to baseline normal
	humanoid.WalkSpeed = SprintConfigs.NORMAL_WALK_SPEED
	character:SetAttribute("IsSprinting", false)

	local shotConn = character:GetAttributeChangedSignal("ServerShotPhase"):Connect(function()
		if player.Character == character then setSprintState(player,false) end
	end)
	table.insert(conns,shotConn)

	-- Reset sprint on death
	local diedConn = humanoid.Died:Connect(function()
		setSprintState(player, false)
	end)
	table.insert(conns, diedConn)

	-- Reset sprint on airborne, seated, climbing, or swimming states
	local jumpConn = humanoid.Jumping:Connect(function(active: boolean)
		if active then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, jumpConn)

	local fallConn = humanoid.FreeFalling:Connect(function(active: boolean)
		if active then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, fallConn)

	local seatConn = humanoid.Seated:Connect(function(active: boolean)
		if active then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, seatConn)

	-- RF-F30 fix: Climbing and Swimming callbacks receive numeric speed, not boolean
	local climbConn = humanoid.Climbing:Connect(function(speed: number)
		if speed > 0.1 then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, climbConn)

	local swimConn = humanoid.Swimming:Connect(function(speed: number)
		if speed > 0.1 then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, swimConn)

	local stateConn = humanoid.StateChanged:Connect(function(_oldState, newState)
		if newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
			or newState == Enum.HumanoidStateType.Seated
			or newState == Enum.HumanoidStateType.Climbing
			or newState == Enum.HumanoidStateType.Swimming
			or newState == Enum.HumanoidStateType.Dead then
			setSprintState(player, false)
		end
	end)
	table.insert(conns, stateConn)

	activeConnections[player] = conns
end

function SprintService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local sprintEvent = Network.GetRemoteEvent(Network.Names.SprintIntentRequest)
	assert(sprintEvent ~= nil, "[SprintService] SprintIntentRequest remote event missing")

	sprintEvent.OnServerEvent:Connect(onSprintIntentRequest)
	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		for player, state in pairs(speedStates) do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hum and hum.Health > 0 and char:GetAttribute("IsSprinting") == true then
				if char:GetAttribute("GoalDribbleActive") == true or char:GetAttribute("ServerShotPhase") == "Charging" then
					setSprintState(player, false)
				else
					hum.WalkSpeed = SprintSpeedRules.Advance(state, now, dt)
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			bindCharacter(player, char)
		end)
		player.CharacterRemoving:Connect(function()
			cleanupPlayer(player)
		end)
	end)

	Players.PlayerRemoving:Connect(cleanupPlayer)

	-- Bind existing players
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function(char)
			bindCharacter(player, char)
		end)
		player.CharacterRemoving:Connect(function()
			cleanupPlayer(player)
		end)
		if player.Character and player.Character:IsDescendantOf(game) then
			local existingChar = player.Character
			task.spawn(function()
				bindCharacter(player, existingChar)
			end)
		end
	end
end

return table.freeze(SprintService)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

local function setSprintState(player: Player, shouldSprint: boolean)

-- Previous section --
		humanoid.WalkSpeed = SprintConfigs.SPRINT_SPEED

-- Previous section --
		if (now - lastStart) < SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC then

-- Previous section --
	setSprintState(player, shouldSprint)
]====]

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

local function setSprintState(player: Player, shouldSprint: boolean, forward: number?)

-- Previous section --
		humanoid.WalkSpeed = if forward == 1 then SprintConfigs.SPRINT_SPEED else SprintConfigs.OTHER_DIRECTION_SPEED

-- Previous section --
		if payload.forward ~= -1 and payload.forward ~= 0 and payload.forward ~= 1 then return end

-- Previous section --
	setSprintState(player, shouldSprint, forward)
]====]
