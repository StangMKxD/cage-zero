--!strict
-- src/client/controllers/AirMovementController.luau
-- Client Controller for High Momentum Jump, Soft Apex, Liftoff Yaw Lock & Four-Way Air Lean Visual Overlay
-- Governed by: docs/plan/phase-01-gameplay-demo/release-first/assets/dribble-receive-HANDOFF.md
-- & docs/plan/phase-01-gameplay-demo/release-first/assets/jump-stutter-only-HANDOFF.md
-- Features:
-- 1. Continuous grounded momentum tracking: preserves verified takeoff speed across walk/sprint before sprint WalkSpeed resets.
-- 2. Stepped horizontal momentum maintenance: guarantees stand < walk < sprint forward travel without midair boost or arbitrary multipliers.
-- 3. Bounded soft apex integration: clamps dt integration to remaining budget, preventing large dt overruns.
-- 4. Single-owner Yaw Lock: Actual character facing yaw locked at takeoff throughout flight until landed; AutoRotate disabled; deadband-guarded CFrame correction avoids per-frame root teleport stutter. Camera may orbit freely 360°.
-- 5. Four-Way Air Lean: Layered support for both modern AnimationConstraint (via Attachment0) and legacy Motor6D (via C0).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JumpConfigs = require(Shared:WaitForChild("configs"):WaitForChild("JumpConfigs"))
local GroundTurnConfigs = require(Shared:WaitForChild("configs"):WaitForChild("GroundTurnConfigs"))

local isInitialized = false
local localPlayer: Player? = nil
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentHrp: BasePart? = nil

-- Joint Reference (Supports both AnimationConstraint and Motor6D)
local rootJointType: "AnimationConstraint" | "Motor6D" | "None" = "None"
local currentRootJoint: Instance? = nil
local currentRootAttachment0: Attachment? = nil
local baseRootC0: CFrame = CFrame.identity
local baseAttachmentC0: CFrame = CFrame.identity

local characterGeneration: number = 0
local activeConnections: { RBXScriptConnection } = {}

-- Airborne Momentum & Soft Apex State
local isAirborne: boolean = false
local takeoffSpeed: number = 0
local takeoffDirection: Vector3 = Vector3.zero
-- Actual horizontal velocity at liftoff; blended toward the takeoff vector so a direction different from the
-- ground travel/facing does not flip the velocity in a single frame
local takeoffStartHoriz: Vector3 = Vector3.zero
local takeoffBlendElapsed: number = 0
local momentumMaintenanceActive = false
local apexSoftElapsed: number = 0
local flightTime: number = 0

-- Rolling Grounded Momentum Tracking (guards against premature sprint WalkSpeed reset)
local lastGroundedSpeed: number = 0
local lastGroundedDirection: Vector3 = Vector3.zero
local lastGroundedFacingYaw: number = 0

-- Yaw Lock State (Owner Constraint: Lock actual character facing yaw at takeoff until landed)
local lockedTakeoffYaw: number = 0

-- Four-Way Air Lean State (Radians)
local currentPitch: number = 0
local currentRoll: number = 0

-- MovementHeadingPreviewController publishes its latched raw movement intent here
-- while its airborne path intentionally zeros Humanoid:Move.
local leanInputSourceEnabled = false
local leanInputWorldDirection = Vector3.zero

local AirMovementController = {}

local function syncCharacterTelemetry()
	local char = currentCharacter
	if not char or not char:IsDescendantOf(game) then
		return
	end
	char:SetAttribute("AirRootJointType", rootJointType)
	char:SetAttribute("IsAirborne", isAirborne)
	char:SetAttribute("TakeoffSpeed", takeoffSpeed)
	char:SetAttribute("LockedTakeoffYaw", lockedTakeoffYaw)
	char:SetAttribute("AirLeanPitch", currentPitch)
	char:SetAttribute("AirLeanRoll", currentRoll)
end

local function resetAirState()
	isAirborne = false
	takeoffSpeed = 0
	takeoffDirection = Vector3.zero
	takeoffStartHoriz = Vector3.zero
	takeoffBlendElapsed = 0
	momentumMaintenanceActive = false
	apexSoftElapsed = 0
	flightTime = 0
	syncCharacterTelemetry()
end

local function resetJoints()
	if rootJointType == "Motor6D" and currentRootJoint and currentRootJoint.Parent ~= nil then
		(currentRootJoint :: Motor6D).C0 = baseRootC0
	elseif rootJointType == "AnimationConstraint" and currentRootAttachment0 and currentRootAttachment0.Parent ~= nil then
		currentRootAttachment0.CFrame = baseAttachmentC0
	end
	currentPitch = 0
	currentRoll = 0
	syncCharacterTelemetry()
end

local function cleanup(characterBeingRemoved: Model?)
	if characterBeingRemoved ~= nil and currentCharacter ~= characterBeingRemoved then
		return
	end

	characterGeneration += 1

	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)

	-- Restore native AutoRotate if character is still valid
	if currentHumanoid and currentHumanoid.Parent ~= nil then
		currentHumanoid.AutoRotate = true
	end

	resetJoints()
	resetAirState()
	currentCharacter = nil
	currentHumanoid = nil
	currentHrp = nil
	currentRootJoint = nil
	currentRootAttachment0 = nil
	rootJointType = "None"
end

local function isCurrentCharacter(char: Model, generation: number): boolean
	return characterGeneration == generation
		and localPlayer ~= nil
		and localPlayer.Character == char
		and char:IsDescendantOf(game)
end

local function onLiftoff(hrp: BasePart, hum: Humanoid, isLedgeFall: boolean)
	if isAirborne then
		-- Capture yaw and momentum ONCE per flight; no relatch in Freefall or repeated state events
		return
	end

	local currentVel = hrp.AssemblyLinearVelocity
	local effectiveLedgeFall = isLedgeFall and (currentVel.Y <= JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY)

	isAirborne = true
	momentumMaintenanceActive = true
	flightTime = 0
	apexSoftElapsed = 0

	-- Capture actual character facing yaw at liftoff
	if effectiveLedgeFall then
		lockedTakeoffYaw = lastGroundedFacingYaw
	else
		local _, y, _ = hrp.CFrame:ToOrientation()
		lockedTakeoffYaw = y
	end

	-- Lock character yaw: disable native AutoRotate and zero angular velocity
	hum.AutoRotate = false
	hrp.AssemblyAngularVelocity = Vector3.zero

	local horizVel = Vector3.new(currentVel.X, 0, currentVel.Z)
	local rawSpeed = horizVel.Magnitude
	takeoffStartHoriz = horizVel
	takeoffBlendElapsed = 0

	-- RF-F39: Capture verified grounded momentum before sprint reset occurs
	local capturedSpeed = math.max(rawSpeed, lastGroundedSpeed)
	takeoffSpeed = math.clamp(capturedSpeed, 0, JumpConfigs.MAX_AIR_HORIZONTAL_SPEED)

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude > 0.1 then
		takeoffDirection = moveDir.Unit
	elseif rawSpeed > 1.0 then
		takeoffDirection = horizVel.Unit
	elseif lastGroundedDirection.Magnitude > 0.1 then
		takeoffDirection = lastGroundedDirection
	else
		takeoffDirection = Vector3.zero
	end

	syncCharacterTelemetry()
end

local function onLanded(hum: Humanoid)
	resetAirState()
	-- Restore AutoRotate on verified landing
	hum.AutoRotate = true
end

local function applyLeanJoint(pitch: number, roll: number)
	if rootJointType == "Motor6D" and currentRootJoint and currentRootJoint.Parent ~= nil then
		(currentRootJoint :: Motor6D).C0 = baseRootC0 * CFrame.Angles(pitch, 0, roll)
	elseif rootJointType == "AnimationConstraint" and currentRootAttachment0 and currentRootAttachment0.Parent ~= nil then
		currentRootAttachment0.CFrame = baseAttachmentC0 * CFrame.Angles(pitch, 0, roll)
	end
end

local function onStepped(_time: number, dt: number, thisGen: number)
	if characterGeneration ~= thisGen or not currentHrp or not currentHumanoid or currentHumanoid.Health <= 0 then
		return
	end

	local hrp = currentHrp
	local hum = currentHumanoid

	if isAirborne and momentumMaintenanceActive then
		-- RF-F39: PreSimulation Velocity Maintenance
		-- Directly sets horizontal flight velocity along takeoff vector in Stepped,
		-- before physics solver runs, preventing native Humanoid air drag from collapsing sprint to walk.
		if takeoffSpeed > 0.5 and takeoffDirection.Magnitude > 0.1 then
			local currentVy = hrp.AssemblyLinearVelocity.Y
			if hum:GetState() == Enum.HumanoidStateType.Jumping and flightTime < 0.03 and currentVy < JumpConfigs.JUMP_POWER * 0.5 then
				currentVy = math.max(currentVy, JumpConfigs.JUMP_POWER)
			end
			local targetHoriz = takeoffDirection * takeoffSpeed
			if takeoffBlendElapsed < JumpConfigs.TAKEOFF_VELOCITY_BLEND_SEC then
				local alpha = takeoffBlendElapsed / JumpConfigs.TAKEOFF_VELOCITY_BLEND_SEC
				targetHoriz = takeoffStartHoriz:Lerp(targetHoriz, alpha)
				takeoffBlendElapsed += dt
			end
			hrp.AssemblyLinearVelocity = Vector3.new(targetHoriz.X, currentVy, targetHoriz.Z)
		end
	end
end

local function onHeartbeat(dt: number, thisGen: number)
	if characterGeneration ~= thisGen or not currentHrp or not currentHumanoid or currentHumanoid.Health <= 0 then
		return
	end

	local hrp = currentHrp
	local hum = currentHumanoid

	if isAirborne then
		flightTime += dt

		-- 1. Owner Yaw Lock Enforcement & Collision Guard
		local currentPos = hrp.Position
		local currentVel = hrp.AssemblyLinearVelocity
		local horizontalVelocity = Vector3.new(currentVel.X, 0, currentVel.Z)
		if momentumMaintenanceActive
			and flightTime > 0.04
			and takeoffBlendElapsed >= JumpConfigs.TAKEOFF_VELOCITY_BLEND_SEC
			and takeoffSpeed > 0.5
			and takeoffDirection.Magnitude > 0.1
			and horizontalVelocity:Dot(takeoffDirection) < takeoffSpeed * 0.5
			and horizontalVelocity.Magnitude < takeoffSpeed * 0.65 then
			-- Accept a strong post-solver speed loss as collision/obstruction response;
			-- stop restoring the takeoff vector so the character cannot push into a wall.
			momentumMaintenanceActive = false
		end

		if hum.AutoRotate then
			hum.AutoRotate = false
		end
		hrp.AssemblyAngularVelocity = Vector3.zero

		-- Deadband-guarded orientation lock: only rewrite hrp.CFrame if rotation drifted from lockedTakeoffYaw,
		-- avoiding unconditional per-frame CFrame teleport stutter during smooth flight.
		local rx, currentYaw, rz = hrp.CFrame:ToOrientation()
		local yawDiff = math.abs(currentYaw - lockedTakeoffYaw)
		if yawDiff > math.pi then
			yawDiff = 2 * math.pi - yawDiff
		end
		if yawDiff > JumpConfigs.CLIENT_YAW_LOCK_DEADBAND_RAD or math.abs(rx) > 0.02 or math.abs(rz) > 0.02 then
			hrp.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, lockedTakeoffYaw, 0)
			hrp.AssemblyAngularVelocity = Vector3.zero
			hrp.AssemblyLinearVelocity = currentVel
		end

		local vy = currentVel.Y

		-- 2. RF-F36: Soft Apex Integration Clamping: Clamp integration step to remaining duration budget
		if vy <= JumpConfigs.APEX_SOFT_ZONE_VY_MAX and vy >= JumpConfigs.APEX_SOFT_ZONE_VY_MIN then
			if apexSoftElapsed < JumpConfigs.APEX_SOFT_MAX_DURATION then
				local remainingTime = JumpConfigs.APEX_SOFT_MAX_DURATION - apexSoftElapsed
				local stepDt = math.min(dt, remainingTime)
				apexSoftElapsed += stepDt
				local counterAccel = (JumpConfigs.GRAVITY * JumpConfigs.APEX_GRAVITY_DAMPING) * stepDt
				hrp.AssemblyLinearVelocity = Vector3.new(currentVel.X, vy + counterAccel, currentVel.Z)
			end
		end

		-- 3. Four-Way Air Lean: Visual pitch/roll tilt overlay based on flight movement input
		-- Relative to LOCKED takeoff yaw (does NOT turn character yaw!)
		local moveDir = if leanInputSourceEnabled then leanInputWorldDirection else hum.MoveDirection
		local targetPitch = 0
		local targetRoll = 0

		local horizontalMoveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
		if horizontalMoveDir.Magnitude > 0.05 then
			local lockedCFrame = CFrame.Angles(0, lockedTakeoffYaw, 0)
			local localMove = lockedCFrame:VectorToObjectSpace(horizontalMoveDir.Unit)
			local inputX = math.clamp(localMove.X, -1, 1)   -- Left (-) / Right (+)
			local inputZ = math.clamp(-localMove.Z, -1, 1)  -- Forward (+) / Back (-)

			targetPitch = -inputZ * math.rad(JumpConfigs.LEAN_MAX_PITCH_DEG)
			targetRoll = -inputX * math.rad(JumpConfigs.LEAN_MAX_ROLL_DEG)
		end

		local lerpFactor = math.clamp(dt * JumpConfigs.LEAN_LERP_SPEED, 0, 1)
		currentPitch += (targetPitch - currentPitch) * lerpFactor
		currentRoll += (targetRoll - currentRoll) * lerpFactor

		-- RF-F34: Apply lean to joint (AnimationConstraint or Motor6D)
		applyLeanJoint(currentPitch, currentRoll)
		syncCharacterTelemetry()
	else
		-- Grounded: Track rolling verified momentum for takeoff snapshot (RF-F39)
		local currentVel = hrp.AssemblyLinearVelocity
		local horizVel = Vector3.new(currentVel.X, 0, currentVel.Z)
		lastGroundedSpeed = horizVel.Magnitude

		local moveDir = hum.MoveDirection
		if moveDir.Magnitude > 0.1 then
			lastGroundedDirection = moveDir.Unit
		elseif horizVel.Magnitude > 1.0 then
			lastGroundedDirection = horizVel.Unit
		else
			lastGroundedDirection = Vector3.zero
		end

		local _, y, _ = hrp.CFrame:ToOrientation()
		local yawDelta = (y - lastGroundedFacingYaw + math.pi) % (2 * math.pi) - math.pi
		local yawRate = yawDelta / math.max(dt, 0.001)
		lastGroundedFacingYaw = y

		-- Reuse the existing single visual-joint owner; airborne yaw/momentum stay unchanged.
		local targetPitch, targetRoll = 0, 0
		local char = currentCharacter
		local eligible = char ~= nil and char:GetAttribute("MovePreviewActive") == true
			and char:GetAttribute("GoalDribbleActive") ~= true
			and char:GetAttribute("ShotActive") ~= true and char:GetAttribute("ShotCharging") ~= true
			and hum.FloorMaterial ~= Enum.Material.Air
			and hum:GetState() == Enum.HumanoidStateType.Running
		if eligible and char and horizVel.Magnitude > 2 then
			local desired = char:GetAttribute("DesiredMoveDirection")
			if typeof(desired) == "Vector3" and desired.Magnitude > 0.01 then
				local wantedYaw = math.atan2(-desired.X, -desired.Z)
				local delta = (wantedYaw - y + math.pi) % (2 * math.pi) - math.pi
				local turn = math.clamp(delta / math.rad(GroundTurnConfigs.FullLeanAngleDeg)
					+ yawRate / GroundTurnConfigs.FullLeanRateRadPerSec, -1, 1)
				local speedWeight = math.clamp(horizVel.Magnitude / 28.8, 0, 1)
				targetRoll = turn * math.rad(GroundTurnConfigs.MaxRollDeg) * speedWeight
				targetPitch = -math.abs(turn) * math.rad(GroundTurnConfigs.MaxPitchDeg) * speedWeight
			end
		end
		local alpha = 1 - math.exp(-GroundTurnConfigs.LeanResponse * math.clamp(dt, 0, 0.1))
		currentPitch += (targetPitch - currentPitch) * alpha
		currentRoll += (targetRoll - currentRoll) * alpha
		applyLeanJoint(currentPitch, currentRoll)
		if char then
			char:SetAttribute("GroundTurnRoll", currentRoll)
			char:SetAttribute("GroundTurnPitch", currentPitch)
		end
	end
end

local function setupCharacter(char: Model)
	local player = localPlayer
	if player == nil or player.Character ~= char or not char:IsDescendantOf(game) then
		return
	end

	-- Invalidate and disconnect the old character first, then capture the token
	-- that identifies this setup attempt. cleanup() increments the generation.
	cleanup()
	local thisGen = characterGeneration

	currentCharacter = char
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not isCurrentCharacter(char, thisGen) or not hum then
		return
	end

	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not isCurrentCharacter(char, thisGen) or not hrp or hum.Health <= 0 then
		return
	end

	currentHumanoid = hum
	currentHrp = hrp

	-- RF-F34: Inspect Root joint in LowerTorso (Supports AnimationConstraint and Motor6D)
	local lowerTorso = char:WaitForChild("LowerTorso", 5) :: BasePart?
	if not isCurrentCharacter(char, thisGen) or not lowerTorso then
		return
	end

	local root = lowerTorso:FindFirstChild("Root")
	if root and root:IsA("Motor6D") then
		rootJointType = "Motor6D"
		currentRootJoint = root
		baseRootC0 = root.C0
	elseif root and root:IsA("AnimationConstraint") then
		rootJointType = "AnimationConstraint"
		currentRootJoint = root
		local attachment0 = root.Attachment0
		if attachment0 then
			currentRootAttachment0 = attachment0
			baseAttachmentC0 = attachment0.CFrame
		end
	end

	if rootJointType == "None"
		or (rootJointType == "AnimationConstraint" and currentRootAttachment0 == nil) then
		warn("[AirMovementController] Current R15 character has no supported LowerTorso.Root joint; callbacks were not installed")
		cleanup(char)
		return
	end

	-- Configure higher jump parameters
	hum.UseJumpPower = true
	hum.JumpPower = JumpConfigs.JUMP_POWER
	hum.JumpHeight = JumpConfigs.EXPECTED_APEX_HEIGHT
	hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	hum.AutoRotate = true

	local _, initYaw, _ = hrp.CFrame:ToOrientation()
	lastGroundedFacingYaw = initYaw
	lockedTakeoffYaw = initYaw
	syncCharacterTelemetry()

	-- State observer for liftoff and landing transitions
	local stateConn = hum.StateChanged:Connect(function(_oldState, newState)
		if not isCurrentCharacter(char, thisGen) then
			return
		end

		if newState == Enum.HumanoidStateType.Jumping then
			onLiftoff(hrp, hum, false)
		elseif newState == Enum.HumanoidStateType.Freefall then
			if not isAirborne then
				local isRisingJump = hrp.AssemblyLinearVelocity.Y > JumpConfigs.LEDGE_FALL_MAX_INITIAL_VY
				onLiftoff(hrp, hum, not isRisingJump)
			end
		elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			if isAirborne then
				onLanded(hum)
			end
		elseif newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.Seated
			or newState == Enum.HumanoidStateType.Swimming
			or newState == Enum.HumanoidStateType.Climbing then
			resetAirState()
			resetJoints()
			hum.AutoRotate = true
		end
	end)
	table.insert(activeConnections, stateConn)

	local diedConn = hum.Died:Connect(function()
		if isCurrentCharacter(char, thisGen) then
			resetAirState()
			resetJoints()
			hum.AutoRotate = true
		end
	end)
	table.insert(activeConnections, diedConn)

	-- PreSimulation stepping for continuous forward momentum maintenance (RF-F39)
	local steppedConn = RunService.Stepped:Connect(function(time: number, dt: number)
		onStepped(time, dt, thisGen)
	end)
	table.insert(activeConnections, steppedConn)

	-- PostSimulation stepping for soft apex, yaw lock & air lean overlay
	local heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		onHeartbeat(dt, thisGen)
	end)
	table.insert(activeConnections, heartbeatConn)
end

function AirMovementController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local player = Players.LocalPlayer
	assert(player ~= nil, "[AirMovementController] LocalPlayer required for initialization")
	localPlayer = player

	player.CharacterAdded:Connect(function(char)
		setupCharacter(char)
	end)

	player.CharacterRemoving:Connect(function(char)
		cleanup(char)
	end)

	if player.Character and player.Character:IsDescendantOf(game) then
		local existingChar = player.Character
		task.spawn(function()
			setupCharacter(existingChar)
		end)
	end
end

-- Seams for future mechanics (AimOrientation, shot/pass/curve queries)
function AirMovementController.IsAirborne(): boolean
	if not isInitialized then
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		if char then
			return char:GetAttribute("IsAirborne") == true
		end
	end
	return isAirborne
end

function AirMovementController.GetTakeoffSpeed(): number
	if not isInitialized then
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local attr = char and char:GetAttribute("TakeoffSpeed")
		if type(attr) == "number" then
			return attr
		end
	end
	return takeoffSpeed
end

function AirMovementController.GetLockedTakeoffYaw(): number
	if not isInitialized then
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local attr = char and char:GetAttribute("LockedTakeoffYaw")
		if type(attr) == "number" then
			return attr
		end
	end
	return lockedTakeoffYaw
end

function AirMovementController.GetAirLean(): (number, number)
	if not isInitialized then
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		if char then
			local p = char:GetAttribute("AirLeanPitch")
			local r = char:GetAttribute("AirLeanRoll")
			if type(p) == "number" and type(r) == "number" then
				return p, r
			end
		end
	end
	return currentPitch, currentRoll
end

function AirMovementController.GetRootJointType(): string
	if not isInitialized then
		local lp = Players.LocalPlayer
		local char = lp and lp.Character
		local attr = char and char:GetAttribute("AirRootJointType")
		if type(attr) == "string" then
			return attr
		end
	end
	return rootJointType
end

function AirMovementController.SetLeanInputSourceEnabled(enabled: boolean)
	leanInputSourceEnabled = enabled
	if not enabled then
		leanInputWorldDirection = Vector3.zero
	end
end

function AirMovementController.SetLeanInputDirection(direction: Vector3)
	local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
	if horizontalDirection.Magnitude > 1 then
		horizontalDirection = horizontalDirection.Unit
	end
	leanInputWorldDirection = horizontalDirection
end

function AirMovementController.GetAimOrientation(): CFrame
	if currentHrp then
		return CFrame.new(currentHrp.Position) * CFrame.Angles(0, lockedTakeoffYaw, 0) * CFrame.Angles(currentPitch, 0, currentRoll)
	end
	local lp = Players.LocalPlayer
	local char = lp and lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local yaw = AirMovementController.GetLockedTakeoffYaw()
		local pitch, roll = AirMovementController.GetAirLean()
		return CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, roll)
	end
	return CFrame.identity
end

return table.freeze(AirMovementController)

--[====[
Retired/replaced code retained as comments at Owner request (2026-10-30).
Original complete source is also in the external backup.

		-- Grounded: Smoothly return lean to neutral
		if math.abs(currentPitch) > 0.001 or math.abs(currentRoll) > 0.001 then
			local returnFactor = math.clamp(dt * JumpConfigs.LEAN_RETURN_SPEED, 0, 1)
			currentPitch += (0 - currentPitch) * returnFactor
			currentRoll += (0 - currentRoll) * returnFactor

			if math.abs(currentPitch) < 0.001 and math.abs(currentRoll) < 0.001 then
				currentPitch = 0
				currentRoll = 0
				resetJoints()
			else
				applyLeanJoint(currentPitch, currentRoll)
				syncCharacterTelemetry()
]====]
