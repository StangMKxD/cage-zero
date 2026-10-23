--!strict
-- src/client/controllers/InputController.luau
-- Module 02: Client Input Handler for Continuous Football Actions per Spec 02 & HANDOFF Contract
-- Handles contextual actions: Attacking (Shoot, Pass, Curve) vs Defending, Sprint, Dash, and Directional Jump
-- Adapted from prototype3 with silky-smooth directional jump, instant dash burst, and authoritative charge state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local AirLeanSolver = require(Shared:WaitForChild("AirLeanSolver"))
local JumpModel = require(Shared:WaitForChild("JumpModel"))
local Configs = Shared:WaitForChild("configs")
local PlayerActionPoseConfigs = require(Configs:WaitForChild("PlayerActionPoseConfigs"))
local JumpConfigs = require(Configs:WaitForChild("JumpConfigs"))

local CharacterFolder = script.Parent.Parent:WaitForChild("character")
local R6AnimationController = require(CharacterFolder:WaitForChild("R6AnimationController"))
local R6ActionPoseController = require(CharacterFolder:WaitForChild("R6ActionPoseController"))
local CameraShiftLockController = require(script.Parent:WaitForChild("CameraShiftLockController"))
local TrainingHUD = require(script.Parent:WaitForChild("TrainingHUD"))

local isInitialized = false
local InputController = {}

local isSprinting = false
local chargeStartTime: number? = nil
local currentIntentId: string? = nil
local currentChargeAction: Types.ChargeActionType? = nil
local currentChargeContext: Types.TeamActionContext? = nil
local lastDashTime = -10.0
local lastSlideTime = -10.0

-- Physical Key Tracking for A/D Curve Side & Air WASD Lean (Owner Delta §12.2–12.5)
local keyWDown = false
local keySDown = false
local keyADown = false
local keyDDown = false

local lastAirLeanSendTime = 0.0
local lastSentLeanFwd = 0.0
local lastSentLeanRgt = 0.0

local function getCurveSideIntent(): Types.CurveSideIntent
	if keyADown and not keyDDown then
		return "Left"
	elseif keyDDown and not keyADown then
		return "Right"
	end
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hum and hrp and hum.MoveDirection.Magnitude > 0.1 then
		local localMove = hrp.CFrame:VectorToObjectSpace(hum.MoveDirection)
		if localMove.X < -0.15 then
			return "Left"
		elseif localMove.X > 0.15 then
			return "Right"
		end
	end
	return "Neutral"
end

-- Client Slide Tackle State & Prediction Reconciliation (F-22)
local isSlidingClient = false
local slideEndTimeClient = 0
local clientSlideDir = Vector3.new(0, 0, 1)
local originalHipHeight: number? = nil
local currentSlideIntentId: string? = nil
local speedRestoreToken = 0

-- Smooth Direction-Locked Aerial Jump (adapted from prototype3, zero stutter)
local isAirborneLocked = false
local jumpCommitDir: Vector3 = Vector3.new(0, 0, 1)
local jumpTakeoffTime = 0

-- Discrete Spacebar Jump Release Guard (F-28)
local isSpacebarHeld = false
local jumpConsumedUntilRelease = false

-- Flight Lifecycle State (Owner Delta §15 Central FSM)
local currentFlightState: Types.FlightState = "Grounded"
local currentFlightId: string? = nil
local hasLeftGround = false
local landingLagUntil = 0.0
local lockedFlightVelocity: Vector3? = nil
local isAcrobaticInFlight = false

local charContextConn: RBXScriptConnection? = nil
local charDiedConn: RBXScriptConnection? = nil
local charStateConn: RBXScriptConnection? = nil
local charActionStatusConn: RBXScriptConnection? = nil
local charResolvedActionConn: RBXScriptConnection? = nil

local intentCounter = 0
local function generateIntentId(prefix: string): string
	intentCounter += 1
	return string.format("%s_%d_%d", prefix, math.floor(os.clock() * 1000), intentCounter)
end

local function getCharacterGeneration(): number
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	return if char then (char:GetAttribute("PlayerActionGeneration") :: number?) or 1 else 1
end

local function getActionContextVersion(): number
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	return if char then (char:GetAttribute("ActionContextVersion") :: number?) or 1 else 1
end

local function getAimDirection(): Vector3
	local cam = Workspace.CurrentCamera
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

	if cam then
		local look = cam.CFrame.LookVector
		return if look.Magnitude > 0.001 then look.Unit else Vector3.new(0, 0, 1)
	end

	if hrp then
		local hrpLook = hrp.CFrame.LookVector
		return if hrpLook.Magnitude > 0.001 then hrpLook.Unit else Vector3.new(0, 0, 1)
	end
	return Vector3.new(0, 0, 1)
end

local function getMovementVector(): Vector3
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer.Character and localPlayer.Character.PrimaryPart then
		local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
			return humanoid.MoveDirection
		end
		return localPlayer.Character.PrimaryPart.CFrame.LookVector
	end
	return Vector3.new(0, 0, 1)
end

local function getLocalActionContext(): Types.TeamActionContext
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	if char then
		local ctx = char:GetAttribute("ActionContext")
		if ctx == "Defending" then
			return "Defending"
		end
	end
	return "Attacking"
end

local function setLocalWalkSpeed(speed: number)
	speedRestoreToken += 1
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = speed
	end
end

local function isCharacterAirborne(char: Model?, hum: Humanoid?, hrp: BasePart?): boolean
	if isAirborneLocked or isAcrobaticInFlight then
		return true
	end
	if currentFlightState ~= "Grounded" and currentFlightState ~= "Landed" then
		return true
	end
	if char and char:GetAttribute("IsAirborne") == true then
		return true
	end
	if hum and hum.FloorMaterial == Enum.Material.Air then
		return true
	end
	if char and hrp then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = { char }
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayOrigin = hrp.Position - Vector3.new(0, 1.5, 0)
		local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -1.7, 0), rayParams)
		if not rayResult then
			return true
		end
	end
	return false
end

function InputController.RequestKick(actionType: Types.KickActionType, charge: number?, intentId: string?)
	local aimDir = getAimDirection()
	local resolvedIntentId = intentId or generateIntentId("kick")

	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isAir = isCharacterAirborne(char, hum, hrp)

	local finalAction: Types.KickActionType = actionType
	if isAir then
		if actionType == "CurveShoot" or actionType == "Volley" or actionType == "BicycleKick" then
			finalAction = "Volley"
		elseif actionType == "DirectShoot" or actionType == "Shoot" then
			finalAction = "DirectShoot"
		end
	end

	local cAct: Types.ChargeActionType = if finalAction == "CurveShoot"
		then "CurveShoot"
		elseif finalAction == "Pass" or finalAction == "GroundPass"
		then "Pass"
		elseif finalAction == "Volley"
		then "Volley"
		else "DirectShoot"

	local curveSide = getCurveSideIntent()

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = finalAction,
		intentId = resolvedIntentId,
		flightId = if isAir then currentFlightId else nil,
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "release",
		chargeAction = cAct,
		aimDirection = aimDir,
		charge = charge,
		curveSideIntent = curveSide,
		airLeanForward = lastSentLeanFwd,
		airLeanRight = lastSentLeanRgt,
	})
	R6ActionPoseController.SetCharging(false)

	local ballPart = Workspace:FindFirstChild(Constants.BALL_PART_NAME)
	local isPossessor = (char ~= nil and (char:GetAttribute("HasBall") == true or char:GetAttribute("IsPossessor") == true))
	local isOutOfReach = false
	if not isPossessor then
		if ballPart and hrp then
			local delta = ballPart.Position - hrp.Position
			local horizDist = Vector3.new(delta.X, 0, delta.Z).Magnitude
			local vertDist = math.abs(delta.Y)
			local maxH = if isAir then (Constants.AERIAL_VOLLEY_REACH or 9.5) else (Constants.FIRST_TIME_KICK_REACH or 9.0)
			local maxV = Constants.FIRST_TIME_VERT_REACH or 8.5
			isOutOfReach = (horizDist > maxH) or (vertDist > maxV)
		else
			isOutOfReach = true
		end
	end

	local visualAction = finalAction
	local visualAnim = if visualAction == "Volley" then "volley"
		elseif visualAction == "DirectShoot" then "kick"
		else visualAction

	isAcrobaticInFlight = false

	R6AnimationController.PlayAction(visualAnim)
	local duration = if visualAction == "Header" then 0.35
		elseif visualAction == "Volley" then 0.44
		elseif visualAction == "CurveShoot" then 0.44
		elseif visualAction == "Pass" or visualAction == "GroundPass" then 0.36
		elseif visualAction == "LobPass" then 0.36
		else 0.34
	local kickCurveStyle: string? = nil
	local kickFoot: string? = nil
	if finalAction == "CurveShoot" then
		if hrp then
			local curveRes = PlayerActionPoseConfigs.ResolveCurveShot(hrp.CFrame, aimDir, ballPart and ballPart.Position, curveSide)
			kickCurveStyle = curveRes.style
			kickFoot = curveRes.foot
		end
	end
	R6ActionPoseController.TriggerAction(visualAction, duration, kickCurveStyle, nil, kickFoot)

	if isOutOfReach and not isAir then
		speedRestoreToken += 1
		local myToken = speedRestoreToken
		if hum and hum.Health > 0 then
			hum.WalkSpeed = Constants.WALK_SPEED * 0.45
			task.delay(Constants.WHIFF_RECOVERY_SEC, function()
				if speedRestoreToken == myToken and hum and hum.Health > 0 and not isAirborneLocked and not isSlidingClient then
					hum.WalkSpeed = if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
				end
			end)
		end
	end
end

function InputController.RequestStartCharge(chargeAction: Types.ChargeActionType)
	if chargeStartTime ~= nil then
		return
	end
	local ctx = getLocalActionContext()
	currentIntentId = generateIntentId("chg")
	chargeStartTime = os.clock()
	currentChargeAction = chargeAction
	currentChargeContext = ctx

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = "StartCharge",
		intentId = currentIntentId,
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "start",
		chargeAction = chargeAction,
	})

	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isAir = isCharacterAirborne(char, hum, hrp)

	local chargeCurveStyle: string? = nil
	local chargeFoot: string? = nil
	if chargeAction == "CurveShoot" then
		local aimDir = getAimDirection()
		local ballPart = Workspace:FindFirstChild(Constants.BALL_PART_NAME)
		if hrp then
			local curveSide = getCurveSideIntent()
			local curveRes = PlayerActionPoseConfigs.ResolveCurveShot(hrp.CFrame, aimDir, ballPart and ballPart.Position, curveSide)
			chargeCurveStyle = curveRes.style
			chargeFoot = curveRes.foot
		end
	end

	local visualChargeAct: string = chargeAction
	if isAir and chargeAction == "DirectShoot" then
		visualChargeAct = "AirDirectShoot"
	end

	setLocalWalkSpeed(Constants.WALK_SPEED * 0.5)
	R6ActionPoseController.SetCharging(true, visualChargeAct, chargeCurveStyle, chargeFoot)
end

function InputController.RequestCancelCharge()
	if currentIntentId ~= nil then
		local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
		remote:FireServer({
			action = "CancelCharge",
			intentId = currentIntentId,
			characterGeneration = getCharacterGeneration(),
			contextVersion = getActionContextVersion(),
			phase = "cancel",
			chargeAction = currentChargeAction,
		})
	end
	chargeStartTime = nil
	currentChargeAction = nil
	currentChargeContext = nil
	currentIntentId = nil
	R6ActionPoseController.SetCharging(false)
	setLocalWalkSpeed(if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED)
end

local function cancelSlidePrediction()
	if not isSlidingClient then
		return
	end
	isSlidingClient = false
	slideEndTimeClient = 0
	currentSlideIntentId = nil

	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp then
		local lv = hrp:FindFirstChild("PlayerSlideLV")
		if lv then lv:Destroy() end
		local att = hrp:FindFirstChild("PlayerSlideAtt")
		if att then att:Destroy() end
	end
	R6ActionPoseController.SetSliding(false)
	CameraShiftLockController.SetSlideLock(false)
	if hum and hum.Health > 0 then
		if not CameraShiftLockController.IsEnabled() and not isAirborneLocked then
			hum.AutoRotate = true
		end
		if originalHipHeight then
			hum.HipHeight = originalHipHeight
		end
		setLocalWalkSpeed(if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED)
	end
end

local function cancelDashPhysics(char: Model?)
	local c = char or (Players.LocalPlayer and Players.LocalPlayer.Character)
	if not c then return end
	local hrp = c:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local lv = hrp:FindFirstChild("PlayerDashLV")
		if lv then lv:Destroy() end
		local att = hrp:FindFirstChild("PlayerDashAtt")
		if att then att:Destroy() end
	end
	c:SetAttribute("IsDashing", false)
	R6ActionPoseController.SetDashing(false)
end

function InputController.RequestSlide(chargeRatio: number?)
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hrp or not hum or hum.Health <= 0 then
		InputController.RequestCancelCharge()
		return
	end
	if hum.FloorMaterial == Enum.Material.Air or isAirborneLocked or isSlidingClient then
		InputController.RequestCancelCharge()
		return
	end

	local now = os.clock()
	if now - lastSlideTime < Constants.SLIDE_COOLDOWN_SEC then
		InputController.RequestCancelCharge()
		return
	end

	local curStam = (char:GetAttribute("Stamina") :: number?) or 1.0
	if curStam < Constants.SLIDE_STAMINA_COST then
		InputController.RequestCancelCharge()
		return
	end

	lastSlideTime = now
	cancelDashPhysics(char)

	local charge = math.clamp(chargeRatio or Constants.CHARGE_MIN_POWER, Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
	local speedScale = 0.75 + charge * 0.50
	local durationScale = 0.85 + charge * 0.30

	local slideDir: Vector3
	if hum.MoveDirection.Magnitude > 0.05 then
		slideDir = hum.MoveDirection.Unit
	else
		local cam = Workspace.CurrentCamera
		local camLook = if cam then cam.CFrame.LookVector else hrp.CFrame.LookVector
		local flatCam = Vector3.new(camLook.X, 0, camLook.Z)
		slideDir = if flatCam.Magnitude > 0.05 then flatCam.Unit else hrp.CFrame.LookVector
	end
	slideDir = Vector3.new(slideDir.X, 0, slideDir.Z).Unit

	isSlidingClient = true
	slideEndTimeClient = now + (Constants.SLIDE_DURATION_SEC * durationScale)
	clientSlideDir = slideDir

	if originalHipHeight == nil then
		originalHipHeight = hum.HipHeight
	end
	hum.HipHeight = 0.55
	hum.AutoRotate = false
	hum.WalkSpeed = 0

	local att = hrp:FindFirstChild("PlayerSlideAtt") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "PlayerSlideAtt"
		att.Parent = hrp
	end
	local lv = hrp:FindFirstChild("PlayerSlideLV") :: LinearVelocity?
	if not lv then
		lv = Instance.new("LinearVelocity")
		lv.Name = "PlayerSlideLV"
		lv.MaxForce = 150000
		lv.Attachment0 = att
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = hrp
	end
	local curSlideSpeed = Constants.SLIDE_SPEED * speedScale
	lv.VectorVelocity = slideDir * curSlideSpeed
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + slideDir)

	R6AnimationController.PlayAction("Slide")
	R6ActionPoseController.SetSliding(true)
	CameraShiftLockController.SetSlideLock(true, slideDir)

	local slideIntentId = currentIntentId or generateIntentId("slide")
	currentSlideIntentId = slideIntentId

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = "Slide",
		intentId = slideIntentId,
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "release",
		chargeAction = "Slide",
		aimDirection = slideDir,
		charge = charge,
	})
	chargeStartTime = nil
	currentChargeAction = nil
	currentChargeContext = nil
	currentIntentId = nil
	R6ActionPoseController.SetCharging(false)
end

function InputController.EndSlide()
	if not isSlidingClient then
		return
	end
	isSlidingClient = false
	slideEndTimeClient = 0
	currentSlideIntentId = nil

	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp then
		local lv = hrp:FindFirstChild("PlayerSlideLV")
		if lv then lv:Destroy() end
		local att = hrp:FindFirstChild("PlayerSlideAtt")
		if att then att:Destroy() end
	end
	R6ActionPoseController.SetSliding(false)
	CameraShiftLockController.SetSlideLock(false)

	if hum and hum.Health > 0 then
		speedRestoreToken += 1
		local myToken = speedRestoreToken

		local recoveryRemaining = if char then (char:GetAttribute("RecoveryRemaining") :: number?) or 0 else 0
		if recoveryRemaining > 0 then
			-- Whiffed: apply recovery dampening & play slide recovery push-up pose (Image 3 Row 1 Step 4)
			R6ActionPoseController.TriggerSlideRecovery(Constants.SLIDE_RECOVERY_SEC)
			hum.WalkSpeed = Constants.WALK_SPEED * Constants.SLIDE_WHIFF_SPEED_RATIO
			task.delay(Constants.SLIDE_RECOVERY_SEC, function()
				if speedRestoreToken == myToken and hum and hum.Health > 0 and not isAirborneLocked and not isSlidingClient then
					if not CameraShiftLockController.IsEnabled() then
						hum.AutoRotate = true
					end
					if originalHipHeight then
						hum.HipHeight = originalHipHeight
					end
					hum.WalkSpeed = if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
				end
			end)
		else
			-- Successful tackle or no whiff penalty
			if not CameraShiftLockController.IsEnabled() and not isAirborneLocked then
				hum.AutoRotate = true
			end
			if originalHipHeight then
				hum.HipHeight = originalHipHeight
			end
			hum.WalkSpeed = if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
		end
	end
end

function InputController.RequestSprint(sprintActive: boolean)
	isSprinting = sprintActive
	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = if sprintActive then "Sprint" else "StopSprint",
		intentId = generateIntentId("spr"),
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "start",
		isSprinting = sprintActive,
	})
	if chargeStartTime == nil and not isSlidingClient then
		local localPlayer = Players.LocalPlayer
		local char = localPlayer and localPlayer.Character
		local curStam = if char then (char:GetAttribute("Stamina") :: number?) or 1.0 else 1.0
		local recRemaining = if char then (char:GetAttribute("RecoveryRemaining") :: number?) or 0 else 0
		if recRemaining <= 0 then
			if sprintActive and curStam > 0.05 then
				setLocalWalkSpeed(Constants.SPRINT_SPEED)
				R6AnimationController.PlayAction("sprint")
			else
				setLocalWalkSpeed(Constants.WALK_SPEED)
			end
		end
	end
end

function InputController.RequestDash(overrideDir: Vector3?)
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hrp or not hum or hum.Health <= 0 then
		return
	end
	if hum.FloorMaterial == Enum.Material.Air or isSlidingClient then
		return
	end
	if isAirborneLocked then
		if hum.FloorMaterial ~= Enum.Material.Air then
			isAirborneLocked = false
			currentFlightState = "Grounded"
		else
			return
		end
	end

	local now = os.clock()
	-- F-23: Reject Dash during Slide and Slide Recovery window
	if (now - lastSlideTime) < (Constants.SLIDE_DURATION_SEC + Constants.SLIDE_RECOVERY_SEC) then
		return
	end
	local recRemaining = (char:GetAttribute("RecoveryRemaining") :: number?) or 0
	if recRemaining > 0 then
		return
	end

	if now - lastDashTime < Constants.DASH_COOLDOWN_SEC then
		return
	end

	local curStam = (char:GetAttribute("Stamina") :: number?) or 1.0
	if curStam < Constants.DASH_STAMINA_COST then
		return
	end

	lastDashTime = now

	-- Direction resolution:
	-- If programmatic/custom direction provided: use overrideDir
	-- If player picked a direction via movement keys (WASD / diagonals): dash in that direction
	-- If player did NOT pick a direction (standing still): automatically dash forward in the direction the character is currently facing
	local dashDir: Vector3
	if overrideDir and overrideDir.Magnitude > 0.05 then
		dashDir = Vector3.new(overrideDir.X, 0, overrideDir.Z).Unit
	elseif hum.MoveDirection.Magnitude > 0.05 then
		dashDir = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
	else
		local charFacing = hrp.CFrame.LookVector
		local flatFacing = Vector3.new(charFacing.X, 0, charFacing.Z)
		dashDir = if flatFacing.Magnitude > 0.05 then flatFacing.Unit else Vector3.new(0, 0, -1)
	end

	-- Instantly orient character to face the chosen dash direction
	hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dashDir)

	-- Apply active LinearVelocity constraint so the character bursts across the pitch without being braked in-place by Humanoid friction
	local att = hrp:FindFirstChild("PlayerDashAtt") :: Attachment?
	if not att then
		att = Instance.new("Attachment")
		att.Name = "PlayerDashAtt"
		att.Parent = hrp
	end
	local lv = hrp:FindFirstChild("PlayerDashLV") :: LinearVelocity?
	if not lv then
		lv = Instance.new("LinearVelocity")
		lv.Name = "PlayerDashLV"
		lv.MaxForce = 200000
		lv.Attachment0 = att
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.Parent = hrp
	end
	lv.VectorVelocity = Vector3.new(
		dashDir.X * Constants.DASH_SPEED_BURST,
		0,
		dashDir.Z * Constants.DASH_SPEED_BURST
	)

	-- Client immediately applies dash velocity burst & WalkSpeed so there is zero input lag
	speedRestoreToken += 1
	local myToken = speedRestoreToken
	hum.WalkSpeed = Constants.DASH_SPEED_BURST
	hrp.AssemblyLinearVelocity = Vector3.new(
		dashDir.X * Constants.DASH_SPEED_BURST,
		hrp.AssemblyLinearVelocity.Y,
		dashDir.Z * Constants.DASH_SPEED_BURST
	)

	char:SetAttribute("IsDashing", true)
	R6ActionPoseController.SetDashing(true, Constants.DASH_DURATION_SEC)
	R6AnimationController.PlayAction("dash")

	task.delay(Constants.DASH_DURATION_SEC, function()
		if hrp then
			local dlv = hrp:FindFirstChild("PlayerDashLV")
			if dlv then dlv:Destroy() end
			local datt = hrp:FindFirstChild("PlayerDashAtt")
			if datt then datt:Destroy() end
		end
		if speedRestoreToken == myToken and hum and hum.Health > 0 and not isAirborneLocked and not isSlidingClient then
			hum.WalkSpeed = if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED
		end
		if char then
			char:SetAttribute("IsDashing", false)
		end
	end)

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = "Dash",
		intentId = generateIntentId("dash"),
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "start",
		aimDirection = dashDir,
	})
end

local function commitJumpDirection(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	if isSlidingClient then
		return
	end
	cancelDashPhysics(char)

	local moveDir = hum.MoveDirection
	local flatMove = Vector3.new(moveDir.X, 0, moveDir.Z)
	local isMoving = flatMove.Magnitude > 0.08
	local commitDir: Vector3
	if isMoving then
		commitDir = flatMove.Unit
	else
		local cam = Workspace.CurrentCamera
		local camLook = if cam then cam.CFrame.LookVector else hrp.CFrame.LookVector
		local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
		commitDir = if flatLook.Magnitude > 0.08 then flatLook.Unit else Vector3.new(0, 0, -1)
	end

	local targetSpeed = if isMoving then (if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED) else 0.0
	lockedFlightVelocity = if isMoving then (commitDir * targetSpeed) else Vector3.zero

	jumpCommitDir = commitDir
	jumpTakeoffTime = os.clock()
	isAirborneLocked = true
	currentFlightId = generateIntentId("flight")
	currentFlightState = "Takeoff"
	hasLeftGround = false
	CameraShiftLockController.SetAirborneJumpLock(true, commitDir)

	-- If Shift Lock is OFF, face jump direction at takeoff
	if not CameraShiftLockController.IsEnabled() then
		hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + commitDir)
	end

	-- Single custom instantaneous launch impulse (BasePart:ApplyImpulse) per §15.2
	local totalMass = hrp.AssemblyMass
	local launchImpulse = JumpModel.CalculateLaunchImpulse(
		hrp.AssemblyLinearVelocity,
		lockedFlightVelocity,
		JumpConfigs.VERTICAL_LAUNCH_SPEED,
		totalMass
	)
	hrp:ApplyImpulse(launchImpulse)

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = "DirectionalJump",
		intentId = generateIntentId("jump"),
		flightId = currentFlightId,
		characterGeneration = getCharacterGeneration(),
		contextVersion = getActionContextVersion(),
		phase = "start",
		aimDirection = if isMoving then commitDir else Vector3.zero,
	})
	R6AnimationController.PlayAction("jump")
end

local function isLocalPlayerPossessor(): boolean
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return false
	end
	local char = localPlayer.Character
	if char and (char:GetAttribute("HasBall") == true or char:GetAttribute("IsPossessor") == true) then
		return true
	end
	local ballPart = Workspace:FindFirstChild(Constants.BALL_PART_NAME)
	if ballPart and ballPart:GetAttribute("PossessorUserId") == localPlayer.UserId then
		return true
	end
	return false
end

function InputController.RequestBallPop()
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp or hum.Health <= 0 then
		return
	end

	-- Space consumed until physical key release
	jumpConsumedUntilRelease = true

	-- Compute validated horizontal WASD move direction
	local moveDir = Vector3.zero
	if hum.MoveDirection.Magnitude > (JumpConfigs.BALL_POP_MIN_MOVE_THRESHOLD or 0.08) then
		local flat = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z)
		if flat.Magnitude > 0.08 then
			moveDir = flat.Unit
		end
	end

	local popIntentId = generateIntentId("pop")

	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer({
		action = "BallPop",
		intentId = popIntentId,
		contextVersion = getActionContextVersion(),
		characterGeneration = getCharacterGeneration(),
		phase = "start",
		aimDirection = moveDir,
		isSprinting = isSprinting,
	})

	-- Play subtle ground pass/kick visual feedback
	R6AnimationController.PlayAction("pass")
end

function InputController.RequestSpaceAction()
	local now = os.clock()
	if jumpConsumedUntilRelease or now < landingLagUntil then
		return
	end
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or isSlidingClient then
		return
	end

	local isGrounded = (hum.FloorMaterial ~= Enum.Material.Air) and (currentFlightState == "Grounded")
	local possessesBall = isLocalPlayerPossessor()

	if possessesBall and isGrounded then
		-- OWNER DELTA § 16: Grounded Personal Possessor -> BallPop!
		-- Character stays 100% on the ground.
		InputController.RequestBallPop()
		return
	end

	-- Non-possessor or mid-air -> normal directional jump
	InputController.RequestDirectionalJump()
end

function InputController.RequestDirectionalJump()
	local now = os.clock()
	if jumpConsumedUntilRelease or now < landingLagUntil then
		return
	end
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not isSlidingClient then
			local isGrounded = (hum.FloorMaterial ~= Enum.Material.Air) and (currentFlightState == "Grounded")
			-- Contextual gate: grounded possessor must perform BallPop, never character jump!
			if isGrounded and isLocalPlayerPossessor() then
				InputController.RequestBallPop()
				return
			end
			if isGrounded then
				jumpConsumedUntilRelease = true
				commitJumpDirection(char)
			end
		end
	end
end

function InputController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer

	local function bindChar(char: Model)
		if charContextConn then
			charContextConn:Disconnect()
			charContextConn = nil
		end
		if charDiedConn then
			charDiedConn:Disconnect()
			charDiedConn = nil
		end
		if charStateConn then
			charStateConn:Disconnect()
			charStateConn = nil
		end
		if charActionStatusConn then
			charActionStatusConn:Disconnect()
			charActionStatusConn = nil
		end
		if charResolvedActionConn then
			charResolvedActionConn:Disconnect()
			charResolvedActionConn = nil
		end

		isSprinting = false
		chargeStartTime = nil
		currentChargeAction = nil
		currentChargeContext = nil
		currentIntentId = nil
		currentSlideIntentId = nil
		isAirborneLocked = false
		isSlidingClient = false
		isSpacebarHeld = false
		jumpConsumedUntilRelease = false
		currentFlightState = "Grounded"
		currentFlightId = nil
		hasLeftGround = false
		landingLagUntil = 0.0
		lockedFlightVelocity = nil
		isAcrobaticInFlight = false
		CameraShiftLockController.SetSlideLock(false)
		CameraShiftLockController.SetAirborneJumpLock(false)
		cancelDashPhysics(char)
		R6ActionPoseController.ResetPoses(char)

		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if hum and hrp then
			hum.UseJumpPower = true
			hum.JumpPower = 0
			hum.JumpHeight = 0
			hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			charStateConn = hum.StateChanged:Connect(function(_oldState, newState)
				if newState == Enum.HumanoidStateType.Landed then
					if isSpacebarHeld then
						jumpConsumedUntilRelease = true
					else
						jumpConsumedUntilRelease = false
					end
					if isAcrobaticInFlight then
						isAcrobaticInFlight = false
						R6ActionPoseController.TriggerAirborneRecovery(0.32)
					end
					if currentFlightState ~= "Grounded" then
						landingLagUntil = os.clock() + JumpConfigs.LANDING_LAG_SEC
						currentFlightState = "Grounded"
						isAirborneLocked = false
						currentFlightId = nil
						hasLeftGround = false
						lockedFlightVelocity = nil
						CameraShiftLockController.SetAirborneJumpLock(false)
						if not isSlidingClient and not CameraShiftLockController.IsEnabled() then
							hum.AutoRotate = true
						end
					end
				elseif newState == Enum.HumanoidStateType.Running and isAirborneLocked then
					if hasLeftGround and (os.clock() - jumpTakeoffTime) > 0.12 then
						landingLagUntil = os.clock() + JumpConfigs.LANDING_LAG_SEC
						currentFlightState = "Grounded"
						isAirborneLocked = false
						currentFlightId = nil
						hasLeftGround = false
						lockedFlightVelocity = nil
						CameraShiftLockController.SetAirborneJumpLock(false)
						if not isSlidingClient and not CameraShiftLockController.IsEnabled() then
							hum.AutoRotate = true
						end
					end
				end
			end)

			charDiedConn = hum.Died:Connect(function()
				if chargeStartTime ~= nil then
					InputController.RequestCancelCharge()
				end
				if isSlidingClient then
					cancelSlidePrediction()
				end
				isAirborneLocked = false
				isSpacebarHeld = false
				jumpConsumedUntilRelease = false
				currentFlightState = "Grounded"
				currentFlightId = nil
				hasLeftGround = false
				landingLagUntil = 0.0
				lockedFlightVelocity = nil
				isAcrobaticInFlight = false
				CameraShiftLockController.SetSlideLock(false)
				CameraShiftLockController.SetAirborneJumpLock(false)
				cancelDashPhysics(char)
				R6ActionPoseController.ResetPoses(char)
			end)

			local function onActionOutcomeReconciled()
				local status = char:GetAttribute("LastActionStatus")
				local actionIntent = char:GetAttribute("LastActionIntentId")
				if status == "Accepted" then
					local resolvedAction = char:GetAttribute("LastResolvedAction") :: string?
					local resolvedFoot = char:GetAttribute("ResolvedKickFoot") :: string?
					local resolvedStyle = char:GetAttribute("ResolvedCurveStyle") :: string?

					if resolvedAction and resolvedAction ~= "" then
						isAcrobaticInFlight = false
						if resolvedAction == "Header" then
							R6AnimationController.PlayAction("header")
							R6ActionPoseController.TriggerAction("Header", 0.35, nil, nil, resolvedFoot)
						elseif resolvedAction == "Volley" then
							R6AnimationController.PlayAction("volley")
							R6ActionPoseController.TriggerAction("Volley", 0.44, nil, nil, resolvedFoot)
						elseif resolvedAction == "CurveShoot" then
							R6AnimationController.PlayAction("kick")
							R6ActionPoseController.TriggerAction("CurveShoot", 0.30, resolvedStyle, nil, resolvedFoot)
						elseif resolvedAction == "DirectShoot" then
							R6AnimationController.PlayAction("kick")
							R6ActionPoseController.TriggerAction("DirectShoot", 0.34, nil, nil, resolvedFoot)
						elseif resolvedAction == "Pass" then
							R6ActionPoseController.TriggerAction("Pass", 0.36, nil, nil, resolvedFoot)
						end
					end
				elseif status == "Rejected" and currentSlideIntentId ~= nil and (actionIntent == currentSlideIntentId or not actionIntent) then
					cancelSlidePrediction()
				end
			end

			charActionStatusConn = char:GetAttributeChangedSignal("LastActionStatus"):Connect(onActionOutcomeReconciled)
			charResolvedActionConn = char:GetAttributeChangedSignal("LastResolvedAction"):Connect(onActionOutcomeReconciled)
		end

		charContextConn = char:GetAttributeChangedSignal("ActionContext"):Connect(function()
			local ctx = char:GetAttribute("ActionContext")
			-- Context switch while holding charge cancels old intent immediately per §6.3
			if chargeStartTime ~= nil and currentChargeContext ~= nil and ctx ~= currentChargeContext then
				InputController.RequestCancelCharge()
			end
		end)
	end

	if localPlayer then
		if localPlayer.Character then
			bindChar(localPlayer.Character)
		end
		localPlayer.CharacterAdded:Connect(bindChar)
	end

	-- Window Focus Lost cancels charging and active slide prediction cleanly (F-22)
	UserInputService.WindowFocusReleased:Connect(function()
		isSpacebarHeld = false
		jumpConsumedUntilRelease = false
		if chargeStartTime ~= nil then
			InputController.RequestCancelCharge()
		end
		if isSlidingClient then
			cancelSlidePrediction()
		end
	end)

	-- Discrete single action per Space press: BallPop if grounded possessor, else DirectionalJump
	UserInputService.JumpRequest:Connect(function()
		if jumpConsumedUntilRelease or isSpacebarHeld then
			return
		end
		InputController.RequestSpaceAction()
	end)

	-- RenderStepped maintains smooth orientation lock, handles slide expiration, physical flight lifecycle, and air lean
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local char = localPlayer and localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

		if isSlidingClient and now >= slideEndTimeClient then
			InputController.EndSlide()
		end

		-- Air Lean update while airborne (Owner Delta §12.5)
		local isAir = isCharacterAirborne(char, hum, hrp)
		if isAir then
			local fwd = (if keyWDown then 1.0 else 0.0) - (if keySDown then 1.0 else 0.0)
			local rgt = (if keyDDown then 1.0 else 0.0) - (if keyADown then 1.0 else 0.0)
			local cleanF, cleanR = AirLeanSolver.ClampLeanInput(fwd, rgt)

			-- Visual local preview (smooth, no network latency)
			R6ActionPoseController.SetAirLean(cleanF, cleanR)

			-- Bounded 20Hz network update (Constants.AIR_LEAN_MIN_UPDATE_INTERVAL = 0.045)
			if (now - lastAirLeanSendTime) >= 0.05 then
				if cleanF ~= lastSentLeanFwd or cleanR ~= lastSentLeanRgt then
					lastAirLeanSendTime = now
					lastSentLeanFwd = cleanF
					lastSentLeanRgt = cleanR
					local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
					remote:FireServer({
						action = "SetAirLean",
						intentId = generateIntentId("lean"),
						characterGeneration = getCharacterGeneration(),
						contextVersion = getActionContextVersion(),
						phase = "start",
						airLeanForward = cleanF,
						airLeanRight = cleanR,
					})
				end
			end
		else
			if lastSentLeanFwd ~= 0.0 or lastSentLeanRgt ~= 0.0 then
				lastSentLeanFwd = 0.0
				lastSentLeanRgt = 0.0
				R6ActionPoseController.SetAirLean(0.0, 0.0)
			end
		end

		if isAirborneLocked or currentFlightState ~= "Grounded" then
			if hrp and hum and hum.Health > 0 then
				local timeSinceJump = now - jumpTakeoffTime
				local vy = hrp.AssemblyLinearVelocity.Y

				-- Lock horizontal flight velocity to captured momentum
				if lockedFlightVelocity then
					hrp.AssemblyLinearVelocity = Vector3.new(
						lockedFlightVelocity.X,
						vy,
						lockedFlightVelocity.Z
					)
				end

				if not hasLeftGround and (timeSinceJump >= 0.04 or vy > 2.0 or hum.FloorMaterial == Enum.Material.Air) then
					hasLeftGround = true
				end

				local isGrounded = (hasLeftGround and timeSinceJump > 0.12 and hum.FloorMaterial ~= Enum.Material.Air and vy <= 0.5)

				local nextState = JumpModel.ResolveFlightState(vy, timeSinceJump, hasLeftGround, isGrounded)
				if nextState ~= currentFlightState then
					currentFlightState = nextState
				end

				if currentFlightState == "Landed" then
					landingLagUntil = now + JumpConfigs.LANDING_LAG_SEC
					currentFlightState = "Grounded"
					isAirborneLocked = false
					currentFlightId = nil
					hasLeftGround = false
					lockedFlightVelocity = nil
					CameraShiftLockController.SetAirborneJumpLock(false)
					if not isSlidingClient and not CameraShiftLockController.IsEnabled() then
						hum.AutoRotate = true
					end
					if isAcrobaticInFlight then
						isAcrobaticInFlight = false
						R6ActionPoseController.TriggerAirborneRecovery(0.32)
					end
				end
			else
				isAirborneLocked = false
				isAcrobaticInFlight = false
				currentFlightState = "Grounded"
				currentFlightId = nil
				hasLeftGround = false
				lockedFlightVelocity = nil
				CameraShiftLockController.SetAirborneJumpLock(false)
			end
		end
	end)

	-- Key Press (InputBegan) — Strictly Single Physical Key per Action (§12.2)
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		local ctx = getLocalActionContext()

		-- Movement & Air Lean WASD state tracking
		if input.KeyCode == Enum.KeyCode.W then
			keyWDown = true
		elseif input.KeyCode == Enum.KeyCode.S then
			keySDown = true
		elseif input.KeyCode == Enum.KeyCode.A then
			keyADown = true
		elseif input.KeyCode == Enum.KeyCode.D then
			keyDDown = true
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			InputController.RequestSprint(true)
		elseif input.KeyCode == Enum.KeyCode.Q then
			InputController.RequestDash()
		elseif input.KeyCode == Enum.KeyCode.Space then
			isSpacebarHeld = true
			if not jumpConsumedUntilRelease then
				InputController.RequestSpaceAction()
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ctx == "Attacking" then
				InputController.RequestStartCharge("DirectShoot")
			elseif ctx == "Defending" then
				InputController.RequestStartCharge("Slide")
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			if ctx == "Attacking" then
				InputController.RequestStartCharge("Pass")
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if ctx == "Attacking" then
				local char = localPlayer and localPlayer.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local isAir = isCharacterAirborne(char, hum, hrp)
				if isAir then
					InputController.RequestStartCharge("Volley")
				else
					InputController.RequestStartCharge("CurveShoot")
				end
			end
		elseif input.KeyCode == Enum.KeyCode.X then
			local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
			remote:FireServer({
				action = "ResetBall",
				intentId = generateIntentId("rst"),
				characterGeneration = getCharacterGeneration(),
				contextVersion = getActionContextVersion(),
				phase = "start",
			})
		elseif input.KeyCode == Enum.KeyCode.H then
			TrainingHUD.ToggleCodex()
		end
	end)

	-- Key Release (InputEnded) — Strictly Single Physical Key per Action (§12.2)
	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessed: boolean)
		if input.KeyCode == Enum.KeyCode.W then
			keyWDown = false
		elseif input.KeyCode == Enum.KeyCode.S then
			keySDown = false
		elseif input.KeyCode == Enum.KeyCode.A then
			keyADown = false
		elseif input.KeyCode == Enum.KeyCode.D then
			keyDDown = false
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			InputController.RequestSprint(false)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if chargeStartTime ~= nil then
				local ctx = getLocalActionContext()
				local now = os.clock()
				local elapsed = now - chargeStartTime
				local finalCharge = if elapsed < 0.12
					then Constants.CHARGE_MIN_POWER
					else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)

				if currentChargeAction == "DirectShoot" then
					if ctx ~= "Attacking" then
						InputController.RequestCancelCharge()
					else
						local prevIntentId = currentIntentId
						chargeStartTime = nil
						currentChargeAction = nil
						currentChargeContext = nil
						currentIntentId = nil
						setLocalWalkSpeed(if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED)
						InputController.RequestKick("DirectShoot", finalCharge, prevIntentId)
					end
				elseif currentChargeAction == "Slide" then
					if ctx ~= "Defending" then
						InputController.RequestCancelCharge()
					else
						InputController.RequestSlide(finalCharge)
					end
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
			if chargeStartTime ~= nil and currentChargeAction == "Pass" then
				local ctx = getLocalActionContext()
				if ctx ~= "Attacking" then
					InputController.RequestCancelCharge()
				else
					local now = os.clock()
					local elapsed = now - chargeStartTime
					local finalCharge = if elapsed < 0.12
						then Constants.CHARGE_MIN_POWER
						else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
					local prevIntentId = currentIntentId
					chargeStartTime = nil
					currentChargeAction = nil
					currentChargeContext = nil
					currentIntentId = nil
					setLocalWalkSpeed(if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED)
					InputController.RequestKick("Pass", finalCharge, prevIntentId)
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			if chargeStartTime ~= nil and (currentChargeAction == "CurveShoot" or currentChargeAction == "Volley") then
				local ctx = getLocalActionContext()
				if ctx ~= "Attacking" then
					InputController.RequestCancelCharge()
				else
					local now = os.clock()
					local elapsed = now - chargeStartTime
					local finalCharge = if elapsed < 0.12
						then Constants.CHARGE_MIN_POWER
						else math.clamp(Constants.CHARGE_MIN_POWER + (elapsed / Constants.CHARGE_TIME_MAX) * (Constants.CHARGE_MAX_POWER - Constants.CHARGE_MIN_POWER), Constants.CHARGE_MIN_POWER, Constants.CHARGE_MAX_POWER)
					local prevIntentId = currentIntentId
					local char = localPlayer and localPlayer.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					local isAir = isCharacterAirborne(char, hum, hrp)
					local kickAct: Types.KickActionType = if isAir then "Volley" else "CurveShoot"

					chargeStartTime = nil
					currentChargeAction = nil
					currentChargeContext = nil
					currentIntentId = nil
					setLocalWalkSpeed(if isSprinting then Constants.SPRINT_SPEED else Constants.WALK_SPEED)
					InputController.RequestKick(kickAct, finalCharge, prevIntentId)
				end
			end
		elseif input.KeyCode == Enum.KeyCode.Space then
			isSpacebarHeld = false
			jumpConsumedUntilRelease = false
			local char = localPlayer and localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			end
		end
	end)
end

function InputController.ReleaseJumpKey()
	isSpacebarHeld = false
	jumpConsumedUntilRelease = false
	local localPlayer = Players.LocalPlayer
	local char = localPlayer and localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end

function InputController.IsJumpConsumed(): boolean
	return jumpConsumedUntilRelease
end

function InputController.IsSpacebarHeld(): boolean
	return isSpacebarHeld
end

function InputController.GetFlightState(): Types.FlightState
	return currentFlightState
end

function InputController.GetFlightId(): string?
	return currentFlightId
end

function InputController.GetLandingLagRemaining(): number
	return math.max(0.0, landingLagUntil - os.clock())
end

function InputController.IsAcrobaticInFlight(): boolean
	return isAcrobaticInFlight
end

function InputController.GetAimDirection(): Vector3
	return getAimDirection()
end

return table.freeze(InputController)
