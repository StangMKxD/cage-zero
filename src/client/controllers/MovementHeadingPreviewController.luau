--!strict
-- src/client/controllers/MovementHeadingPreviewController.luau
-- Camera-Relative Movement Adapter: Grounded Reticle Facing (ShiftLock style) + Continuous Camera-Relative WASD
-- Governed by RF02-CAMERA-RELATIVE Hand-Off Contract (2026-10-27)

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigsFolder = Shared:WaitForChild("configs")
local CameraPreviewConfigs = require(ConfigsFolder:WaitForChild("CameraPreviewConfigs"))
local JumpConfigs = require(ConfigsFolder:WaitForChild("JumpConfigs"))
local DribbleConfigs = require(ConfigsFolder:WaitForChild("DribbleConfigs"))
local DribbleGeometryHelper = require(Shared:WaitForChild("DribbleGeometryHelper"))
local DribbleActionConfigs = require(ConfigsFolder:WaitForChild("DribbleActionConfigs"))
local DribbleControlRules = require(Shared:WaitForChild("DribbleControlRules"))
local DribbleCutController = require(script.Parent:WaitForChild("DribbleCutController"))
local MOVEMENT_STEP_NAME = "CageZeroMovementHeadingStep"

local MovementHeadingPreviewController = {}

local isInitialized = false
local isActive = false

-- Native PlayerModule controls handle
local nativeControls: any = nil

-- Key state tracking
local isWDown = false
local isSDown = false
local isADown = false
local isDDown = false
local isSpaceDown = false
local isGHeld = false
local goalDirection: Vector3? = nil
local lastGoalIntent = false
local lastGoalSentTime = 0.0
local lastCutChord = "NONE"
local lastCutInput = Vector3.zero
local lastCutInputTime = 0.0

-- Bounded jump input buffer (os.clock deadline); cleared once Humanoid enters Jumping
local jumpBufferUntil: number = 0

-- Movement State
local currentChord: string = "NONE"
local currentWorldDirection: Vector3 = Vector3.zero

-- Phase-Aware Dribble Turn Gate State (RF02-DRIBBLE-RECEIVE 2026-10-27)
local rawWorldDirection: Vector3 = Vector3.zero
local dribbleTurnFactor: number = 1.0

-- Cut speed scale: drops to the cut factor when a cut starts, recovers smoothly afterwards (movement never freezes)
local cutSpeedScale: number = 1.0
local CUT_REVERSE_NAMES = { ReverseLeft = true, ReverseRight = true, GoalReverse = true }

-- Character tracking
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentHrp: BasePart? = nil

-- Remote handle for carrier camera intent reporting
local ballActionRemoteRef: any = nil
local lastSentCameraIntent: number = 0

local connections: { RBXScriptConnection } = {}

-- References (lazy required to avoid circular dependencies)
local cameraControllerRef: any = nil
local airMovementControllerRef: any = nil
local sprintControllerRef: any = nil

local function getCameraController(): any
	if cameraControllerRef ~= nil then
		return cameraControllerRef
	end
	local controllers = script.Parent
	if controllers then
		local mod = controllers:FindFirstChild("CameraPreviewController")
		if mod and mod:IsA("ModuleScript") then
			cameraControllerRef = require(mod)
		end
	end
	return cameraControllerRef
end

local function getAirMovementController(): any
	if airMovementControllerRef ~= nil then
		return airMovementControllerRef
	end
	local controllers = script.Parent
	local mod = controllers and controllers:FindFirstChild("AirMovementController")
	if mod and mod:IsA("ModuleScript") then
		airMovementControllerRef = require(mod)
	end
	return airMovementControllerRef
end

local function getSprintController(): any
	if sprintControllerRef ~= nil then
		return sprintControllerRef
	end
	local controllers = script.Parent
	local mod = controllers and controllers:FindFirstChild("SprintController")
	if mod and mod:IsA("ModuleScript") then
		sprintControllerRef = require(mod)
	end
	return sprintControllerRef
end

local function getBallActionRemote(): RemoteEvent?
	if ballActionRemoteRef ~= nil then
		return ballActionRemoteRef
	end
	local remotesFolder = ReplicatedStorage:FindFirstChild("CageZeroRemotes")
	if remotesFolder then
		local r = remotesFolder:FindFirstChild("BallActionRequest")
		if r and r:IsA("RemoteEvent") then
			ballActionRemoteRef = r
		end
	end
	return ballActionRemoteRef
end

local function notifyMovementIntent(isMoving: boolean, forward: number)
	local sprintCtrl = getSprintController()
	if sprintCtrl then
		if sprintCtrl.SetMovementIntent then
			sprintCtrl.SetMovementIntent(isMoving)
		elseif sprintCtrl.SetForwardIntent then
			sprintCtrl.SetForwardIntent(forward)
		end
	end
end

local function getCameraYaw(): number
	local camCtrl = getCameraController()
	if camCtrl and camCtrl.GetCameraYaw then
		return camCtrl.GetCameraYaw()
	end
	local cam = Workspace.CurrentCamera
	if cam then
		local _, y, _ = cam.CFrame:ToOrientation()
		return y
	end
	return 0.0
end

local function publishLeanInput(direction: Vector3)
	local airCtrl = getAirMovementController()
	if airCtrl and airCtrl.SetLeanInputDirection then
		airCtrl.SetLeanInputDirection(direction)
	end
end

local function computeLocalInputVector(): (Vector3, string, number)
	local forward = (isWDown and 1 or 0) - (isSDown and 1 or 0)
	local lateral = (isDDown and 1 or 0) - (isADown and 1 or 0)

	local chord = ""
	if forward > 0 then
		chord ..= "W"
	elseif forward < 0 then
		chord ..= "S"
	end
	if lateral < 0 then
		chord ..= "A"
	elseif lateral > 0 then
		chord ..= "D"
	end
	if chord == "" then
		chord = "NONE"
	end

	if forward == 0 and lateral == 0 then
		return Vector3.zero, chord, forward
	end

	-- In camera space:
	-- -Z is forward (W), +Z is backward (S)
	-- -X is left (A), +X is right (D)
	local rawLocalVector = Vector3.new(lateral, 0, -forward)
	if rawLocalVector.Magnitude < 0.001 then
		return Vector3.zero, chord, forward
	end

	return rawLocalVector.Unit, chord, forward
end

local function computeWorldDirection(camYaw: number): (Vector3, string, number)
	local localVec, chord, forward = computeLocalInputVector()
	if localVec.Magnitude < 0.001 then
		return Vector3.zero, chord, forward
	end
	if goalDirection then
		return DribbleControlRules.GoalMovement(localVec, goalDirection), chord, forward
	end
	local yawRotation = CFrame.Angles(0, camYaw, 0)
	local worldVec = (yawRotation:VectorToWorldSpace(localVec)).Unit
	return worldVec, chord, forward
end

local function checkIsAirborne(): boolean
	local nativeAirborne = false
	if currentHumanoid and currentHumanoid.Parent then
		local state = currentHumanoid:GetState()
		nativeAirborne = (state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall)
	end
	local airCtrl = getAirMovementController()
	local ctrlAirborne = (airCtrl ~= nil and airCtrl.IsAirborne ~= nil and airCtrl.IsAirborne() == true)
	return nativeAirborne or ctrlAirborne
end

local function isEligibleGrounded(): boolean
	local hum = currentHumanoid
	local hrp = currentHrp
	local char = currentCharacter
	if not hum or not hrp or not char or not hum.Parent or hum.Health <= 0 then
		return false
	end

	local state = hum:GetState()

	-- Native airborne states are never eligible grounded
	if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		return false
	end

	-- AirMovementController airborne state is never eligible grounded
	local airCtrl = getAirMovementController()
	if airCtrl and airCtrl.IsAirborne and airCtrl.IsAirborne() == true then
		return false
	end

	-- Unsupported / specialized locomotion states: do NOT force camera yaw or ground movement
	if state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Physics
		or state == Enum.HumanoidStateType.Ragdoll
		or state == Enum.HumanoidStateType.Dead then
		return false
	end

	-- Must be on solid ground (non-air floor material), OR in Landed state
	if hum.FloorMaterial == Enum.Material.Air and state ~= Enum.HumanoidStateType.Landed then
		return false
	end

	return true
end

local function updateMovementIntent(camYaw: number)
	goalDirection = nil
	if isGHeld and isEligibleGrounded() and currentCharacter and currentHrp then
		local goal = currentCharacter:GetAttribute("AttackGoalPosition")
		if typeof(goal) == "Vector3" then
			local direction = DribbleControlRules.HorizontalDirection(goal - currentHrp.Position)
			if direction.Magnitude > 0 then goalDirection = direction end
		end
	end
	local activeGoal = goalDirection ~= nil
	local now = os.clock()
	if currentCharacter and (activeGoal ~= lastGoalIntent or (activeGoal and now - lastGoalSentTime >= DribbleActionConfigs.INTENT_INTERVAL)) then
		local remote = getBallActionRemote()
		if remote then
			remote:FireServer({action = "GoalDribble", active = activeGoal, character = currentCharacter})
			lastGoalIntent = activeGoal
			lastGoalSentTime = now
		end
	end
	local worldDir, chord, forward = computeWorldDirection(camYaw)
	rawWorldDirection = worldDir
	currentChord = chord
	publishLeanInput(worldDir)

	currentWorldDirection = worldDir
	local char = currentCharacter
	if char and char:GetAttribute("IsBallCarrier") == true and isEligibleGrounded() then
		local opposingKeys = (isWDown and isSDown) or (isADown and isDDown)
		if opposingKeys then
			DribbleCutController.Cancel()
			lastCutInput = Vector3.zero
			lastCutChord = "NONE"
			currentWorldDirection = Vector3.zero
		else
			local input = computeLocalInputVector()
			local locked = DribbleCutController.IsLocked(char)
			local sprintCtrl = getSprintController()
			local sprintingNow = (char:GetAttribute("IsSprinting") == true)
				or (sprintCtrl ~= nil and sprintCtrl.IsSprinting ~= nil and sprintCtrl.IsSprinting() == true)
			local cutsAllowed = sprintingNow and not activeGoal and (char:GetAttribute("GoalDribbleActive") ~= true)
			if not cutsAllowed and locked then
				DribbleCutController.Cancel()
				locked = false
			end
			if input.Magnitude > 0 then
				if now - lastCutInputTime > DribbleActionConfigs.REVERSE_INPUT_GRACE_SEC then
					lastCutInput = Vector3.zero
					lastCutChord = "NONE"
				end
				if not locked and cutsAllowed then
					local name = DribbleControlRules.CutForTransition(lastCutChord, chord, lastCutInput, input, DribbleActionConfigs.CUT_REVERSE_ANGLE_DEG)
					if not name and lastCutChord == "NONE" and #chord == 2 then
						name = if input.Z < 0
							then (if input.X < 0 then "FrontLeft" else "FrontRight")
							else (if input.X < 0 then "BackLeft" else "BackRight")
					end
					if name then
						local prevWorldDir = if lastCutInput.Magnitude > 0.001
							then (CFrame.Angles(0, camYaw, 0):VectorToWorldSpace(lastCutInput)).Unit
							else worldDir
						locked = DribbleCutController.TryStart(char, name, worldDir, prevWorldDir)
					end
				end
				-- Latest held input wins when the real animation finishes, without replay.
				lastCutChord = chord
				lastCutInput = input
				lastCutInputTime = now
			end
			-- While a cut animation is active, lock the carrier's travel direction to the cut's diagonal/exit direction
			-- at full normal speed until the animation finishes; new A/D or diagonal changes take effect once the clip ends.
			if locked then
				local lockedDir = DribbleCutController.GetActiveCutDirection()
				if lockedDir and lockedDir.Magnitude > 0.001 then
					currentWorldDirection = lockedDir
				end
			end
		end
	else
		DribbleCutController.Cancel()
		lastCutInput = Vector3.zero
		lastCutChord = "NONE"
	end

	local isMoving = currentWorldDirection.Magnitude > 0.001
	notifyMovementIntent(isMoving and not activeGoal, forward)
end

local function getShortestAngleDiff(target: number, current: number): number
	return (target - current + math.pi) % (2 * math.pi) - math.pi
end

local function updateGroundedFacing(camYaw: number, dt: number): number
	local hrp = currentHrp
	local hum = currentHumanoid
	if not hrp or not hum or hum.Health <= 0 then
		return 1.0
	end

	-- Ensure AutoRotate is false so native Humanoid does NOT rotate body toward MoveDirection
	if hum.AutoRotate then
		hum.AutoRotate = false
	end

	-- If stationary, maintain current heading; do NOT auto-align to reticle
	if currentWorldDirection.Magnitude <= 0.001 and not goalDirection then
		return 1.0
	end
	-- Cut no longer freezes heading: the body keeps turning toward the held direction while the cut clip plays.

	-- Ground body faces actual movement direction in 360°
	local facing = goalDirection or currentWorldDirection
	local targetYaw = math.atan2(-facing.X, -facing.Z)

	local rx, currentYaw, rz = hrp.CFrame:ToOrientation()
	local diff = getShortestAngleDiff(targetYaw, currentYaw)
	local deadband = CameraPreviewConfigs.Movement.GroundedFacingDeadbandRad or 0.001

	local speedDipFactor = 1.0
	local movementCfg = CameraPreviewConfigs.Movement

	-- Dribbling carrier ONLY (valid grounded carrier): configurable turn slow-down, immediate drop, smooth recovery.
	-- No contact/phase/timer gate: the heading above always follows the latest intent immediately.
	local char = currentCharacter
	local isCarrier = (char and char:GetAttribute("IsBallCarrier") == true)
	if isCarrier then
		local isSprinting = (char:GetAttribute("IsSprinting") == true)
		local target = DribbleGeometryHelper.ComputeTurnSpeedFactor(diff, isSprinting)
		if target < dribbleTurnFactor then
			dribbleTurnFactor = target
		else
			dribbleTurnFactor = math.min(target, dribbleTurnFactor + DribbleConfigs.DRIBBLE_TURN_RECOVERY_RATE * math.clamp(dt, 0.001, 0.1))
		end
		local blocked = char:GetAttribute("DribbleSpeedFactor")
		local blockedFactor = if typeof(blocked) == "number" then math.clamp(blocked, 0, 1) else 1.0
		-- Diagonal turns (< 120 deg) and active dribble cuts keep full 1.0 speed (no speed dip on diagonal keyboard or mouse steering).
		if DribbleCutController.IsLocked(char) then
			dribbleTurnFactor = 1.0
			speedDipFactor = blockedFactor
		else
			speedDipFactor = dribbleTurnFactor * blockedFactor
		end
	elseif movementCfg and movementCfg.TurnSpeedDipEnabled ~= false then
		local threshRad = math.rad(movementCfg.TurnSpeedDipThresholdDeg or 30.0)
		local absDiff = math.abs(diff)
		if absDiff > threshRad then
			local minFactor = movementCfg.TurnSpeedDipMinFactor or 0.65
			local norm = math.clamp((absDiff - threshRad) / (math.pi - threshRad), 0, 1)
			speedDipFactor = 1.0 - (1.0 - minFactor) * (norm ^ 1.5)
		end
		dribbleTurnFactor = 1.0
	else
		dribbleTurnFactor = 1.0
	end

	if math.abs(diff) > deadband or math.abs(rx) > 0.02 or math.abs(rz) > 0.02 then
		local newYaw = targetYaw
		if movementCfg and movementCfg.TurnSmoothingEnabled ~= false then
			local turnSpeed = if isCarrier
				then (DribbleConfigs.DRIBBLE_TURN_RATE_RAD_PER_SEC or 10.0)
				else (movementCfg.FacingTurnSpeedRadPerSec or 20.0)
			local clampedDt = math.clamp(dt, 0.001, 0.1)
			local maxStep = turnSpeed * clampedDt
			if math.abs(diff) <= maxStep then
				newYaw = targetYaw
			else
				newYaw = currentYaw + math.sign(diff) * maxStep
			end
		end

		local curVel = hrp.AssemblyLinearVelocity
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, newYaw, 0)
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.AssemblyLinearVelocity = curVel
	end

	return speedDipFactor
end

local function resetAllKeys()
	isWDown = false
	isSDown = false
	isADown = false
	isDDown = false
	isSpaceDown = false
	isGHeld = false
	goalDirection = nil
	DribbleCutController.Cancel()
	lastCutChord = "NONE"
	lastCutInput = Vector3.zero
	if lastGoalIntent then
		local remote = getBallActionRemote()
		if remote and currentCharacter then
			remote:FireServer({action = "GoalDribble", active = false, character = currentCharacter})
		end
	end
	lastGoalIntent = false
	lastGoalSentTime = 0
	jumpBufferUntil = 0
	dribbleTurnFactor = 1.0
	cutSpeedScale = 1.0
	currentChord = "NONE"
	rawWorldDirection = Vector3.zero
	currentWorldDirection = Vector3.zero
	publishLeanInput(Vector3.zero)
	notifyMovementIntent(false, 0)

	if currentHumanoid and currentHumanoid.Parent then
		currentHumanoid:Move(Vector3.zero, false)
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if not isActive then
		return
	end
	if gameProcessed then
		return
	end

	local key = input.KeyCode
	if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
		isWDown = true
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.S or key == Enum.KeyCode.Down then
		isSDown = true
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.A or key == Enum.KeyCode.Left then
		isADown = true
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right then
		isDDown = true
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.G then
		isGHeld = true
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.Space then
		isSpaceDown = true
		jumpBufferUntil = os.clock() + JumpConfigs.JUMP_BUFFER_WINDOW_SEC
	end
end

local function onInputEnded(input: InputObject, _gameProcessed: boolean)
	if not isActive then
		return
	end

	local key = input.KeyCode
	if key == Enum.KeyCode.W or key == Enum.KeyCode.Up then
		isWDown = false
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.S or key == Enum.KeyCode.Down then
		isSDown = false
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.A or key == Enum.KeyCode.Left then
		isADown = false
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.D or key == Enum.KeyCode.Right then
		isDDown = false
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.G then
		isGHeld = false
		updateMovementIntent(getCameraYaw())
	elseif key == Enum.KeyCode.Space then
		isSpaceDown = false
	end
end

local function onMovementStep(dt: number)
	if not isActive then
		return
	end

	if not currentHumanoid or not currentHumanoid.Parent then
		return
	end

	if currentHumanoid.Health <= 0 then
		return
	end

	local camYaw = getCameraYaw()
	updateMovementIntent(camYaw)

	local isAirborne = checkIsAirborne()
	if isAirborne then
		-- Humanoid air physics must not see a non-zero MoveDirection: AirMovementController owns
		-- airborne horizontal momentum/lean. Lean intent is delivered via publishLeanInput().
		currentHumanoid:Move(Vector3.zero, false)
		-- Landing-edge jump buffer is preserved: do not clear jumpBufferUntil here
	elseif isEligibleGrounded() then
		-- Grounded: 360° Analog Locomotion Facing with Turn Smoothing & Speed Dip
		local speedDipFactor = updateGroundedFacing(camYaw, dt)
		if goalDirection then
			speedDipFactor *= math.min(1, DribbleActionConfigs.GOAL_SPEED / math.max(1, currentHumanoid.WalkSpeed))
		end

		-- Dribble cut: keep moving at reduced speed for the cut, then recover smoothly.
		local cutLocked = currentCharacter ~= nil and DribbleCutController.IsLocked(currentCharacter)
		if cutLocked then
			local cutName = DribbleCutController.GetActiveCutName()
			local cutFactor = if cutName ~= nil and CUT_REVERSE_NAMES[cutName]
				then DribbleActionConfigs.CUT_MOVE_SPEED_FACTOR_REVERSE
				else DribbleActionConfigs.CUT_MOVE_SPEED_FACTOR
			cutSpeedScale = math.min(cutSpeedScale, cutFactor)
		else
			cutSpeedScale = math.min(1.0, cutSpeedScale + DribbleActionConfigs.CUT_SPEED_RECOVERY_PER_SEC * dt)
		end
		speedDipFactor = math.min(speedDipFactor, cutSpeedScale)

		-- Apply camera-relative movement direction while grounded, scaled by turn speed dip factor
		if currentWorldDirection.Magnitude > 0.001 then
			currentHumanoid:Move(currentWorldDirection * speedDipFactor, false)
		else
			currentHumanoid:Move(Vector3.zero, false)
		end

		local state = currentHumanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping then
			jumpBufferUntil = 0
		elseif (isSpaceDown or os.clock() < jumpBufferUntil)
			and not (currentCharacter and DribbleCutController.IsLocked(currentCharacter)) then
			-- A press on the Landed edge would otherwise be eaten by Landed -> Running
			if state == Enum.HumanoidStateType.Landed and currentHumanoid.FloorMaterial ~= Enum.Material.Air then
				currentHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			else
				currentHumanoid.Jump = true
			end
		end
	else
		-- Unsupported state (Seated, Climbing, Swimming, Physics, Ragdoll, etc.)
		-- Hands off without forcing camera yaw or overriding native movement.
		if not currentHumanoid.AutoRotate then
			currentHumanoid.AutoRotate = true
		end
		publishLeanInput(Vector3.zero)
	end

	if currentCharacter then
		currentCharacter:SetAttribute("MovePreviewActive", true)
		currentCharacter:SetAttribute("CurrentMoveDirection", currentWorldDirection)
		currentCharacter:SetAttribute("DesiredMoveDirection", rawWorldDirection)
		currentCharacter:SetAttribute("LatchedMoveDirection", currentWorldDirection)

		-- Report validated camera look intent when player is the active ball carrier
		if currentCharacter:GetAttribute("IsBallCarrier") == true then
			local now = os.clock()
			if now - lastSentCameraIntent >= 0.1 then
				lastSentCameraIntent = now
				local camLook = Vector3.new(-math.sin(camYaw), 0, -math.cos(camYaw))
				local remote = getBallActionRemote()
				if remote then
					pcall(function()
						remote:FireServer({
							action = "CameraIntent",
							lookDirection = camLook,
						})
					end)
				end
			end
		end
	end
end

local function setupCharacter(char: Model)
	currentCharacter = char
	currentHumanoid = char:WaitForChild("Humanoid", 5.0) :: Humanoid?
	currentHrp = char:WaitForChild("HumanoidRootPart", 5.0) :: BasePart?

	resetAllKeys()

	if currentHumanoid then
		currentHumanoid.AutoRotate = false
		table.insert(
			connections,
			currentHumanoid.Died:Connect(function()
				resetAllKeys()
			end)
		)
	end
end

local function suspendNativeControls()
	task.spawn(function()
		local playerScripts = localPlayer:WaitForChild("PlayerScripts", 5.0) :: PlayerScripts?
		if not playerScripts then
			return
		end
		local playerModuleScript = playerScripts:WaitForChild("PlayerModule", 5.0) :: ModuleScript?
		if not playerModuleScript then
			return
		end

		local ok, PlayerModule = pcall(require, playerModuleScript)
		if ok and typeof(PlayerModule) == "table" and PlayerModule.GetControls then
			nativeControls = PlayerModule:GetControls()
			if nativeControls and nativeControls.Disable then
				nativeControls:Disable()
			end
		end
	end)
end

local function restoreNativeControls()
	if nativeControls and nativeControls.Enable then
		pcall(function()
			nativeControls:Enable()
		end)
	end
end

function MovementHeadingPreviewController.GetCurrentDirection(): Vector3
	return currentWorldDirection
end

function MovementHeadingPreviewController.GetLatchedDirection(): Vector3
	return currentWorldDirection
end

function MovementHeadingPreviewController.GetCurrentChord(): string
	return currentChord
end

function MovementHeadingPreviewController.GetResolvedForward(): number
	return (isWDown and 1 or 0) - (isSDown and 1 or 0)
end

function MovementHeadingPreviewController.IsForwardEligible(): boolean
	return ((isWDown and 1 or 0) - (isSDown and 1 or 0)) > 0
end

function MovementHeadingPreviewController.GetDesiredDirection(): Vector3
	return rawWorldDirection
end

-- Touch-phase turn gate removed (Owner 2026-10-27): turns are never gated
function MovementHeadingPreviewController.IsTurnGated(): boolean
	return false
end

function MovementHeadingPreviewController.IsActive(): boolean
	return isActive
end

function MovementHeadingPreviewController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	if not CameraPreviewConfigs.IsActiveInCurrentContext() then
		return
	end
	if not CameraPreviewConfigs.Movement.Enabled then
		return
	end

	isActive = true

	-- Suspend native PlayerModule movement so custom camera-relative movement has sole control
	suspendNativeControls()
	local airCtrl = getAirMovementController()
	if airCtrl and airCtrl.SetLeanInputSourceEnabled then
		airCtrl.SetLeanInputSourceEnabled(true)
	end

	-- Input listeners
	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(connections, UserInputService.InputEnded:Connect(onInputEnded))

	-- Safety resets
	table.insert(
		connections,
		GuiService.MenuOpened:Connect(function()
			resetAllKeys()
		end)
	)
	table.insert(
		connections,
		UserInputService.WindowFocusReleased:Connect(function()
			resetAllKeys()
		end)
	)
	table.insert(
		connections,
		UserInputService.TextBoxFocused:Connect(function()
			resetAllKeys()
		end)
	)

	-- Pre-physics movement application
	-- Bound AFTER native Humanoid input (RenderPriority.Input) and BEFORE physics, so native input
	-- cannot reset Humanoid.Jump / Move set here.
	RunService:BindToRenderStep(MOVEMENT_STEP_NAME, Enum.RenderPriority.Input.Value + 5, onMovementStep)

	-- Character tracking
	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
	table.insert(
		connections,
		localPlayer.CharacterAdded:Connect(function(newChar)
			setupCharacter(newChar)
		end)
	)
end

function MovementHeadingPreviewController.Cleanup()
	isActive = false
	pcall(function()
		RunService:UnbindFromRenderStep(MOVEMENT_STEP_NAME)
	end)

	resetAllKeys()
	local airCtrl = getAirMovementController()
	if airCtrl and airCtrl.SetLeanInputSourceEnabled then
		airCtrl.SetLeanInputSourceEnabled(false)
	end
	restoreNativeControls()

	if currentHumanoid and currentHumanoid.Parent then
		currentHumanoid.AutoRotate = true
	end

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	currentCharacter = nil
	currentHumanoid = nil
	currentHrp = nil
	nativeControls = nil
	ballActionRemoteRef = nil
	lastSentCameraIntent = 0
	isInitialized = false
end

return MovementHeadingPreviewController
