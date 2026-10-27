--!strict
-- src/client/controllers/SprintController.luau
-- Client Controller for Player Sprint Intent & Context Loss Handling
-- Governed by RF02-IDLE-RUNTIME Contract & Owner Additive Scope (2026-10-26 & Review026)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local SprintConfigs = require(Shared:WaitForChild("configs"):WaitForChild("SprintConfigs"))

local isInitialized = false
local isSprinting = false
local sprintRemote: RemoteEvent? = nil
local activeSprintKeys: { [Enum.KeyCode]: boolean } = {}
local activeConnections: { RBXScriptConnection } = {}
local characterGeneration: number = 0
local retryThread: thread? = nil
local lastSentTime: number = 0
local currentCharacter: Model? = nil

local currentForwardIntent: number = 0
local isMovingIntent: boolean = false

local SprintController = {}

local function checkRetrySprint(thisGen: number)
	if retryThread then
		task.cancel(retryThread)
		retryThread = nil
	end

	local isShiftHeld = (next(activeSprintKeys) ~= nil)
	if not isShiftHeld or not isMovingIntent then
		return
	end

	-- Check if character is currently airborne or disabled
	local char = currentCharacter
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local state = hum:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
			or state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Dead then
			return
		end
	end

	-- Schedule a single bounded retry after the rate limit window
	retryThread = task.delay(SprintConfigs.START_RATE_LIMIT_INTERVAL_SEC + 0.02, function()
		retryThread = nil
		if characterGeneration ~= thisGen then
			return
		end
		local stillShift = (next(activeSprintKeys) ~= nil)
		if not stillShift or not isMovingIntent then
			return
		end
		local activeChar = currentCharacter
		if not activeChar or not activeChar:IsDescendantOf(game) then
			return
		end
		local serverState = (activeChar:GetAttribute("IsSprinting") == true)
		if not serverState then
			-- Server did not grant sprint (rate-limited / rejected); re-send intent now that cooldown has elapsed!
			isSprinting = false
			syncSprintIntent()
		end
	end)
end

function syncSprintIntent()
	local isShiftHeld = (next(activeSprintKeys) ~= nil)
	local isEligible = isShiftHeld and isMovingIntent

	if not isEligible then
		if retryThread then
			task.cancel(retryThread)
			retryThread = nil
		end
		if isSprinting then
			isSprinting = false
			lastSentTime = os.clock()
			if sprintRemote then
				sprintRemote:FireServer({
					isShiftHeld = false,
					isMoving = false,
					forward = 0,
				})
			end
		end
		return
	end

	-- isEligible == true
	if isSprinting then
		return
	end
	isSprinting = true
	lastSentTime = os.clock()

	if sprintRemote then
		sprintRemote:FireServer({
			isShiftHeld = isShiftHeld,
			isMoving = true,
			forward = 1,
		})
	end

	-- Always schedule bounded grounded retry in case this request hits a server rate-limit window
	checkRetrySprint(characterGeneration)
end

function SprintController.SetMovementIntent(isMoving: boolean)
	if isMovingIntent == isMoving then
		return
	end
	isMovingIntent = isMoving
	currentForwardIntent = if isMoving then 1 else 0
	syncSprintIntent()
end

function SprintController.SetForwardIntent(forward: number)
	SprintController.SetMovementIntent(forward ~= 0)
end

local function resetSprintState()
	if retryThread then
		task.cancel(retryThread)
		retryThread = nil
	end
	table.clear(activeSprintKeys)
	isMovingIntent = false
	currentForwardIntent = 0
	if isSprinting then
		isSprinting = false
		lastSentTime = os.clock()
		if sprintRemote then
			sprintRemote:FireServer({
				isShiftHeld = false,
				isMoving = false,
				forward = 0,
			})
		end
	end
end

local function isSprintKey(keyCode: Enum.KeyCode): boolean
	for _, key in ipairs(SprintConfigs.SPRINT_KEY_CODES) do
		if key == keyCode then
			return true
		end
	end
	return false
end

local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if isSprintKey(input.KeyCode) then
			activeSprintKeys[input.KeyCode] = true
			syncSprintIntent()
		end
	end
end

local function onInputEnded(input: InputObject, _gameProcessedEvent: boolean)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if isSprintKey(input.KeyCode) then
			activeSprintKeys[input.KeyCode] = nil
			-- Releasing one Shift while other Shift is still held preserves sprinting
			if next(activeSprintKeys) == nil then
				if retryThread then
					task.cancel(retryThread)
					retryThread = nil
				end
			end
			syncSprintIntent()
		end
	end
end

local function setupCharacter(character: Model)
	characterGeneration += 1
	local thisGen = characterGeneration
	currentCharacter = character

	for _, c in ipairs(activeConnections) do
		c:Disconnect()
	end
	table.clear(activeConnections)

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?

	-- Post-yield generation check
	if characterGeneration ~= thisGen or not character:IsDescendantOf(game) or not humanoid then
		return
	end

	-- Cancel sprint intent on airborne, seated, climbing, or swimming states
	local stateConn = humanoid.StateChanged:Connect(function(_oldState, newState)
		if characterGeneration == thisGen then
			if newState == Enum.HumanoidStateType.Jumping or newState == Enum.HumanoidStateType.Freefall then
				-- Airborne: cancel retry timer and suspend server sprint intent
				if retryThread then
					task.cancel(retryThread)
					retryThread = nil
				end
				if isSprinting then
					isSprinting = false
					if sprintRemote then
						sprintRemote:FireServer({
							isShiftHeld = false,
							isMoving = false,
							forward = 0,
						})
					end
				end
			elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
				-- Landing/Running: if user was holding Shift throughout jump and forward > 0, seamlessly resume sprint
				syncSprintIntent()
			elseif newState == Enum.HumanoidStateType.Seated
				or newState == Enum.HumanoidStateType.Climbing
				or newState == Enum.HumanoidStateType.Swimming
				or newState == Enum.HumanoidStateType.Dead then
				resetSprintState()
			end
		end
	end)
	table.insert(activeConnections, stateConn)

	local diedConn = humanoid.Died:Connect(function()
		if characterGeneration == thisGen then
			resetSprintState()
		end
	end)
	table.insert(activeConnections, diedConn)

	-- Reconcile client optimistic sprint with authoritative server attribute
	local attrConn = character:GetAttributeChangedSignal("IsSprinting"):Connect(function()
		if characterGeneration == thisGen then
			local serverState = (character:GetAttribute("IsSprinting") == true)
			if not serverState and isSprinting then
				-- Server rejected or revoked sprint: reconcile client state
				isSprinting = false
				checkRetrySprint(thisGen)
			end
		end
	end)
	table.insert(activeConnections, attrConn)

	-- Reconcile negative rate-limit acknowledgement from server (RF-F45 fix)
	local rejectConn = character:GetAttributeChangedSignal("SprintRejectedSeq"):Connect(function()
		if characterGeneration == thisGen then
			if isSprinting then
				isSprinting = false
			end
			checkRetrySprint(thisGen)
		end
	end)
	table.insert(activeConnections, rejectConn)
end

function SprintController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	assert(localPlayer ~= nil, "[SprintController] LocalPlayer required for initialization")

	sprintRemote = Network.GetRemoteEvent(Network.Names.SprintIntentRequest)
	assert(sprintRemote ~= nil, "[SprintController] SprintIntentRequest remote event missing")

	-- Bind keyboard inputs
	UserInputService.InputBegan:Connect(onInputBegan)
	UserInputService.InputEnded:Connect(onInputEnded)

	-- Context loss handlers: ensure sprint is released when focus, window, menu, or chat opens
	UserInputService.WindowFocusReleased:Connect(resetSprintState)
	GuiService.MenuOpened:Connect(resetSprintState)
	UserInputService.TextBoxFocused:Connect(resetSprintState)

	-- Character lifecycle observers
	localPlayer.CharacterAdded:Connect(function(char)
		resetSprintState()
		setupCharacter(char)
	end)

	localPlayer.CharacterRemoving:Connect(function()
		characterGeneration += 1
		resetSprintState()
	end)

	if localPlayer.Character and localPlayer.Character:IsDescendantOf(game) then
		local existingChar = localPlayer.Character
		task.spawn(function()
			setupCharacter(existingChar)
		end)
	end
end

function SprintController.IsSprinting(): boolean
	return isSprinting
end

return table.freeze(SprintController)
