--!strict
-- src/client/character/R6ActionPoseController.luau
-- Authoritative Procedural R6 Action Pose Evaluator & Joint Transformer
-- Adapted from FootballSandbox (.sandbox/prototype3) per HANDOFF Contract §7.3
-- Source reference: prototype3/client/FootballClient.client.luau:1982-2273

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Configs = Shared:WaitForChild("configs")
local PlayerActionPoseConfigs = require(Configs:WaitForChild("PlayerActionPoseConfigs"))

local R6ActionPoseController = {}

local localPlayer = Players.LocalPlayer
local isInitialized = false
local renderConn: RBXScriptConnection? = nil

export type ActionPlaybackState =
	| "Inactive"
	| "Playing"
	| "Holding"
	| "Stopping"
	| "Cancelled"
	| "Rejected"
	| "Completed"

local currentActionState: ActionPlaybackState = "Inactive"
local currentActionToken: number = 0
local activeCharacterGeneration: number = 1

local activeAction: string? = nil
local actionStartTime = 0
local actionDuration = 0
local activeCurveStyle: string? = nil
local autoNextAction: string? = nil
local canAutoNext: boolean = false
local activeKickFoot: string? = nil

local actionBlendWeight: number = 1.0
local actionTargetWeight: number = 1.0
local actionFadeRate: number = 20.0

-- Charge Stance
local isCharging = false
local chargeStartTime = 0
local chargeAction = "DirectShoot"
local chargeCurveStyle: string? = nil
local chargeKickFoot: string? = nil

-- Dash
local isDashing = false
local dashStartTime = 0
local dashDuration = 0.22

-- Slide
local isSliding = false
local slideStartTime = 0
local slideDuration = 0.55

-- Locomotion Stride Cycle
local locomotionStridePhase = 0

-- Recovery & Whiff States
local isLanding = false
local landingStartTime = 0
local landingDuration = 0.16

local isWhiffing = false
local whiffStartTime = 0
local whiffDuration = 0.35
local isCurveWhiff = false

local isSlideRecovering = false
local slideRecoveryStartTime = 0
local slideRecoveryDuration = 0.35

local isAirborneRecovering = false
local airborneRecoveryStartTime = 0
local airborneRecoveryDuration = 0.28

local wasCustomPoseActive = false
local lastObservedCharacter: Model? = nil

type JointMap = {
	RootJoint: Motor6D?,
	Neck: Motor6D?,
	RightShoulder: Motor6D?,
	LeftShoulder: Motor6D?,
	RightHip: Motor6D?,
	LeftHip: Motor6D?,
}

-- Rig Space Joint Pivot offsets (relative to Part0: Torso, or HRP for RootJoint)
-- In R6, all limbs connect to Torso. Applying offsets around these pivots prevents
-- limb translation dislocations and ensures natural body-frame pitch, yaw, and roll.
local JOINT_PIVOTS: { [string]: Vector3 } = table.freeze({
	["RootJoint"] = Vector3.new(0, 0, 0),
	["Neck"] = Vector3.new(0, 1, 0),
	["Right Shoulder"] = Vector3.new(1, 0.5, 0),
	["Left Shoulder"] = Vector3.new(-1, 0.5, 0),
	["Right Hip"] = Vector3.new(1, -1, 0),
	["Left Hip"] = Vector3.new(-1, -1, 0),
	["RightShoulder"] = Vector3.new(1, 0.5, 0),
	["LeftShoulder"] = Vector3.new(-1, 0.5, 0),
	["RightHip"] = Vector3.new(1, -1, 0),
	["LeftHip"] = Vector3.new(-1, -1, 0),
})

-- Canonical standard R6 C0 matrices (immutable reference to prevent drift)
local STANDARD_R6_C0: { [string]: CFrame } = table.freeze({
	["RootJoint"] = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
	["Neck"] = CFrame.new(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
	["Right Shoulder"] = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
	["Left Shoulder"] = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	["Right Hip"] = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
	["Left Hip"] = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	-- Aliases without space:
	["RightShoulder"] = CFrame.new(1, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
	["LeftShoulder"] = CFrame.new(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	["RightHip"] = CFrame.new(1, -1, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
	["LeftHip"] = CFrame.new(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
})

local IDENTITY_POSE: PlayerActionPoseConfigs.R6JointPoseOffsets = table.freeze({
	RootJoint = CFrame.identity,
	Neck = CFrame.identity,
	RightShoulder = CFrame.identity,
	LeftShoulder = CFrame.identity,
	RightHip = CFrame.identity,
	LeftHip = CFrame.identity,
})

-- Smoothed Joint Offsets (interpolated every frame via CFrame:Lerp)
local currentOffsets: { [string]: CFrame } = {
	RootJoint = CFrame.identity,
	Neck = CFrame.identity,
	RightShoulder = CFrame.identity,
	LeftShoulder = CFrame.identity,
	RightHip = CFrame.identity,
	LeftHip = CFrame.identity,
}

local function getCharacterJoints(char: Model): JointMap
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = char:FindFirstChild("Torso")

	local rootJoint = if hrp then hrp:FindFirstChild("RootJoint") :: Motor6D? else nil
	if not rootJoint and torso then
		rootJoint = torso:FindFirstChild("RootJoint") :: Motor6D?
	end

	local neck = if torso then torso:FindFirstChild("Neck") :: Motor6D? else nil
	local rShoulder = if torso then (torso:FindFirstChild("Right Shoulder") or torso:FindFirstChild("RightShoulder")) :: Motor6D? else nil
	local lShoulder = if torso then (torso:FindFirstChild("Left Shoulder") or torso:FindFirstChild("LeftShoulder")) :: Motor6D? else nil
	local rHip = if torso then (torso:FindFirstChild("Right Hip") or torso:FindFirstChild("RightHip")) :: Motor6D? else nil
	local lHip = if torso then (torso:FindFirstChild("Left Hip") or torso:FindFirstChild("LeftHip")) :: Motor6D? else nil

	return {
		RootJoint = rootJoint,
		Neck = neck,
		RightShoulder = rShoulder,
		LeftShoulder = lShoulder,
		RightHip = rHip,
		LeftHip = lHip,
	}
end

local function setJointOffset(joint: Motor6D?, offsetCF: CFrame)
	if not joint then
		return
	end
	local orig = joint:GetAttribute("OrigC0")
	if typeof(orig) ~= "CFrame" then
		orig = STANDARD_R6_C0[joint.Name] or joint.C0
		joint:SetAttribute("OrigC0", orig)
	end
	local p = JOINT_PIVOTS[joint.Name] or Vector3.zero
	joint.C0 = CFrame.new(p) * offsetCF * CFrame.new(-p) * (orig :: CFrame)
end

local function resetAllJoints(char: Model)
	local joints = getCharacterJoints(char)
	for name, joint in pairs(joints) do
		if joint then
			local orig = joint:GetAttribute("OrigC0")
			if typeof(orig) == "CFrame" then
				joint.C0 = orig
			else
				local std = STANDARD_R6_C0[joint.Name]
				if std then
					joint.C0 = std
				end
			end
		end
		currentOffsets[name] = CFrame.identity
	end
end

-- Native in-engine CFrame evaluation of lowest vertical bounding point (minY) across all 6 R6 parts
-- Reference frame: HRP standing at Y = 3.00 studs, floor at Y = 0.00 studs.
local function calculateRigMinY(offsets: { [string]: CFrame }?): number
	local o = offsets or currentOffsets
	local rootOffset = o["RootJoint"] or CFrame.identity
	local neckOffset = o["Neck"] or CFrame.identity
	local rShoulderOffset = o["RightShoulder"] or o["Right Shoulder"] or CFrame.identity
	local lShoulderOffset = o["LeftShoulder"] or o["Left Shoulder"] or CFrame.identity
	local rHipOffset = o["RightHip"] or o["Right Hip"] or CFrame.identity
	local lHipOffset = o["LeftHip"] or o["Left Hip"] or CFrame.identity

	-- Torso in HRP space
	local torsoCF = rootOffset

	-- Head in HRP space: Torso.CFrame * CFrame.new(0, 1, 0) * NeckOffset * CFrame.new(0, 0.5, 0)
	local headCF = torsoCF * CFrame.new(0, 1, 0) * neckOffset * CFrame.new(0, 0.5, 0)

	-- Right Arm: pivot (1, 0.5, 0) in Torso space, center (1.5, 0, 0)
	local rArmCF = torsoCF * CFrame.new(1, 0.5, 0) * rShoulderOffset * CFrame.new(0.5, -0.5, 0)

	-- Left Arm: pivot (-1, 0.5, 0) in Torso space, center (-1.5, 0, 0)
	local lArmCF = torsoCF * CFrame.new(-1, 0.5, 0) * lShoulderOffset * CFrame.new(-0.5, -0.5, 0)

	-- Right Leg: pivot (1, -1, 0) in Torso space, center (0.5, -2, 0)
	local rLegCF = torsoCF * CFrame.new(1, -1, 0) * rHipOffset * CFrame.new(-0.5, -1, 0)

	-- Left Leg: pivot (-1, -1, 0) in Torso space, center (-0.5, -2, 0)
	local lLegCF = torsoCF * CFrame.new(-1, -1, 0) * lHipOffset * CFrame.new(0.5, -1, 0)

	local function partMinY(cf: CFrame, hx: number, hy: number, hz: number): number
		local extY = math.abs(cf.RightVector.Y) * hx + math.abs(cf.UpVector.Y) * hy + math.abs(cf.LookVector.Y) * hz
		return cf.Position.Y - extY + 3.0
	end

	local minY = partMinY(torsoCF, 1.0, 1.0, 0.5)
	minY = math.min(minY, partMinY(headCF, 1.0, 0.5, 0.5))
	minY = math.min(minY, partMinY(rArmCF, 0.5, 1.0, 0.5))
	minY = math.min(minY, partMinY(lArmCF, 0.5, 1.0, 0.5))
	minY = math.min(minY, partMinY(rLegCF, 0.5, 1.0, 0.5))
	minY = math.min(minY, partMinY(lLegCF, 0.5, 1.0, 0.5))

	return minY
end

-- ============================================================================
-- Public Action Trigger Interface
-- ============================================================================

function R6ActionPoseController.TriggerAction(
	actionName: string,
	durationSec: number?,
	curveStyle: string?,
	nextAction: string?,
	kickFoot: string?
): number
	currentActionToken += 1
	local thisToken = currentActionToken

	activeAction = actionName
	actionStartTime = os.clock()
	actionDuration = durationSec or 0.28
	activeCurveStyle = curveStyle
	autoNextAction = nextAction
	canAutoNext = (nextAction ~= nil)
	activeKickFoot = kickFoot

	currentActionState = "Playing"
	actionBlendWeight = 1.0
	actionTargetWeight = 1.0
	actionFadeRate = 100.0

	return thisToken
end

function R6ActionPoseController.StopAction(token: number?, fadeOutSec: number?)
	if token ~= nil and token ~= currentActionToken then
		return
	end
	currentActionState = "Stopping"
	canAutoNext = false -- TERMINAL: Never resurrects
	autoNextAction = nil
	activeKickFoot = nil

	local fade = fadeOutSec or 0.12
	actionTargetWeight = 0.0
	actionFadeRate = if fade > 1e-4 then (1.0 / fade) else 1000.0
end

function R6ActionPoseController.CancelAction(token: number?, fadeOutSec: number?)
	if token ~= nil and token ~= currentActionToken then
		return
	end
	currentActionState = "Cancelled"
	canAutoNext = false -- TERMINAL: Never resurrects
	autoNextAction = nil
	activeKickFoot = nil

	local fade = fadeOutSec or 0.10
	actionTargetWeight = 0.0
	actionFadeRate = if fade > 1e-4 then (1.0 / fade) else 1000.0
end

function R6ActionPoseController.RejectAction(token: number?, fadeOutSec: number?)
	if token ~= nil and token ~= currentActionToken then
		return
	end
	currentActionState = "Rejected"
	canAutoNext = false -- TERMINAL: Never resurrects
	autoNextAction = nil
	activeKickFoot = nil

	local fade = fadeOutSec or 0.05
	actionTargetWeight = 0.0
	actionFadeRate = if fade > 1e-4 then (1.0 / fade) else 1000.0
end

function R6ActionPoseController.GetActionState(): (ActionPlaybackState, number, number)
	return currentActionState, currentActionToken, activeCharacterGeneration
end

function R6ActionPoseController.SetCharging(charging: boolean, action: string?, curveStyle: string?, kickFoot: string?)
	isCharging = charging
	if charging then
		currentActionToken += 1
		currentActionState = "Holding"
		canAutoNext = false
		autoNextAction = nil
		chargeStartTime = os.clock()
		chargeAction = action or "DirectShoot"
		chargeCurveStyle = curveStyle
		chargeKickFoot = kickFoot
		actionBlendWeight = 1.0
		actionTargetWeight = 1.0
	else
		chargeStartTime = 0
		chargeKickFoot = nil
		if currentActionState == "Holding" then
			currentActionState = "Inactive"
		end
	end
end

function R6ActionPoseController.SetDashing(dashing: boolean, durationSec: number?)
	isDashing = dashing
	if dashing then
		dashStartTime = os.clock()
		dashDuration = durationSec or 0.30
	end
end

function R6ActionPoseController.IsCharging(): boolean
	local char = localPlayer and localPlayer.Character
	return isCharging or (char ~= nil and char:GetAttribute("IsCharging") == true) or (currentActionState == "Holding")
end

function R6ActionPoseController.SetSliding(sliding: boolean)
	isSliding = sliding
	if sliding then
		slideStartTime = os.clock()
	else
		slideStartTime = 0
	end
end

function R6ActionPoseController.IsCustomPoseActive(): boolean
	return wasCustomPoseActive
end

function R6ActionPoseController.TriggerLandingRecovery(durationSec: number?)
	isLanding = true
	landingStartTime = os.clock()
	landingDuration = durationSec or Constants.LANDING_RECOVERY_SEC
end

function R6ActionPoseController.TriggerWhiff(isCurve: boolean?, durationSec: number?)
	isWhiffing = true
	isCurveWhiff = isCurve == true
	whiffStartTime = os.clock()
	whiffDuration = durationSec or Constants.WHIFF_RECOVERY_SEC
	activeAction = nil
end

function R6ActionPoseController.TriggerSlideRecovery(durationSec: number?)
	isSlideRecovering = true
	slideRecoveryStartTime = os.clock()
	slideRecoveryDuration = durationSec or Constants.SLIDE_RECOVERY_SEC
	isSliding = false
end

function R6ActionPoseController.TriggerAirborneRecovery(durationSec: number?)
	currentActionToken += 1
	currentActionState = "Playing"
	canAutoNext = false
	autoNextAction = nil
	isAirborneRecovering = true
	airborneRecoveryStartTime = os.clock()
	airborneRecoveryDuration = durationSec or 0.28
	activeAction = nil
	actionBlendWeight = 1.0
	actionTargetWeight = 1.0
end

function R6ActionPoseController.ResetPoses(char: Model?)
	activeCharacterGeneration += 1
	currentActionToken += 1
	currentActionState = "Inactive"
	canAutoNext = false
	activeAction = nil
	autoNextAction = nil
	isCharging = false
	isDashing = false
	isSliding = false
	slideStartTime = 0
	locomotionStridePhase = 0
	isLanding = false
	isWhiffing = false
	isSlideRecovering = false
	isAirborneRecovering = false
	wasCustomPoseActive = false
	actionBlendWeight = 1.0
	actionTargetWeight = 1.0

	local targetChar = char or (localPlayer and localPlayer.Character)
	if targetChar then
		resetAllJoints(targetChar)
	end
end

R6ActionPoseController.JOINT_PIVOTS = JOINT_PIVOTS
R6ActionPoseController.STANDARD_R6_C0 = STANDARD_R6_C0
R6ActionPoseController.CalculateRigMinY = calculateRigMinY
R6ActionPoseController.CalculateMinY = calculateRigMinY

-- ============================================================================
-- Lifecycle & Evaluation
-- ============================================================================

function R6ActionPoseController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	if not localPlayer then
		localPlayer = Players.LocalPlayer
	end

	renderConn = RunService.RenderStepped:Connect(function(dt: number)
		local char = localPlayer and localPlayer.Character
		if not char then
			return
		end

		-- Character generation / respawn validation
		if char ~= lastObservedCharacter then
			lastObservedCharacter = char
			activeCharacterGeneration += 1
			currentActionToken += 1
			currentActionState = "Inactive"
			canAutoNext = false
			activeAction = nil
			autoNextAction = nil
			isCharging = false
			isDashing = false
			isSliding = false
			isLanding = false
			isWhiffing = false
			isSlideRecovering = false
			isAirborneRecovering = false
			wasCustomPoseActive = false
			actionBlendWeight = 1.0
			actionTargetWeight = 1.0
			resetAllJoints(char)
		end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not hrp or hum.Health <= 0 then
			if wasCustomPoseActive or currentActionState ~= "Inactive" then
				currentActionState = "Inactive"
				canAutoNext = false
				activeAction = nil
				autoNextAction = nil
				wasCustomPoseActive = false
				resetAllJoints(char)
			end
			return
		end

		local now = os.clock()

		-- Smooth action blend weight transition
		if actionBlendWeight < actionTargetWeight then
			actionBlendWeight = math.min(actionTargetWeight, actionBlendWeight + actionFadeRate * dt)
		elseif actionBlendWeight > actionTargetWeight then
			actionBlendWeight = math.max(actionTargetWeight, actionBlendWeight - actionFadeRate * dt)
		end

		-- Determine target pose based on highest priority active state
		local targetPose: PlayerActionPoseConfigs.R6JointPoseOffsets = IDENTITY_POSE
		local isActionActive = false

		-- PRIORITY 1: Confirmed Slide Tackle (Turf slide: dropped torso, extended lead leg, tucked trail leg)
		local serverSliding = char:GetAttribute("IsSliding") == true
		if isSliding or serverSliding then
			isActionActive = true
			if slideStartTime == 0 then
				slideStartTime = now
			end
			local elapsed = now - slideStartTime
			local progress = math.clamp(elapsed / slideDuration, 0, 1)
			targetPose = PlayerActionPoseConfigs.GetSlidePose(progress)

		-- PRIORITY 2: Slide Recovery (Image 3 Row 1 Step 4: Pushing up from turf)
		elseif isSlideRecovering or (char:GetAttribute("RecoveryRemaining") or 0) > 0 then
			local elapsed = now - slideRecoveryStartTime
			if elapsed < slideRecoveryDuration then
				isActionActive = true
				local progress = elapsed / slideRecoveryDuration
				targetPose = PlayerActionPoseConfigs.GetSlideRecoveryPose(progress)
			else
				isSlideRecovering = false
			end

		-- PRIORITY 3: Action Follow-Through / Timeline (Playing, Stopping, Cancelled, Rejected)
		elseif activeAction ~= nil and (currentActionState == "Playing" or currentActionState == "Stopping" or currentActionState == "Cancelled" or currentActionState == "Rejected") then
			local elapsed = now - actionStartTime
			if elapsed < actionDuration and actionBlendWeight > 0.001 then
				isActionActive = true
				local progress = elapsed / actionDuration
				local rawPose = PlayerActionPoseConfigs.GetFollowThroughPose(activeAction, progress, activeCurveStyle)
				local resolvedFoot = activeKickFoot or (char:GetAttribute("ResolvedKickFoot") :: string?) or (char:GetAttribute("KickFoot") :: string?)
				if resolvedFoot == "Left" then
					rawPose = PlayerActionPoseConfigs.MirrorPoseSagittal(rawPose)
				end
				if actionBlendWeight < 0.999 then
					targetPose = {
						RootJoint = IDENTITY_POSE.RootJoint:Lerp(rawPose.RootJoint, actionBlendWeight),
						Neck = IDENTITY_POSE.Neck:Lerp(rawPose.Neck, actionBlendWeight),
						RightShoulder = IDENTITY_POSE.RightShoulder:Lerp(rawPose.RightShoulder, actionBlendWeight),
						LeftShoulder = IDENTITY_POSE.LeftShoulder:Lerp(rawPose.LeftShoulder, actionBlendWeight),
						RightHip = IDENTITY_POSE.RightHip:Lerp(rawPose.RightHip, actionBlendWeight),
						LeftHip = IDENTITY_POSE.LeftHip:Lerp(rawPose.LeftHip, actionBlendWeight),
					}
				else
					targetPose = rawPose
				end
			else
				-- Timeline finished or fade completed
				activeKickFoot = nil
				if currentActionState == "Playing" and canAutoNext and autoNextAction ~= nil then
					local nextAct = autoNextAction
					autoNextAction = nil
					canAutoNext = false
					currentActionState = "Completed"
					R6ActionPoseController.TriggerAction(nextAct, 0.35)
				else
					currentActionState = "Inactive"
					activeAction = nil
					autoNextAction = nil
					canAutoNext = false
				end
			end

		-- PRIORITY 4: Airborne Ground Recovery (Image 2 Row 1 Step 3: Landing after Bicycle Kick / aerial strike)
		elseif isAirborneRecovering then
			local elapsed = now - airborneRecoveryStartTime
			if elapsed < airborneRecoveryDuration then
				isActionActive = true
				local progress = elapsed / airborneRecoveryDuration
				targetPose = PlayerActionPoseConfigs.GetAirborneRecoveryPose(progress)
			else
				isAirborneRecovering = false
				if currentActionState == "Playing" then
					currentActionState = "Inactive"
				end
			end

		-- PRIORITY 5: Whiff / Missed Shot Recovery (Image 2 Row 3: Wild swing -> Stumble -> Hesitation)
		elseif isWhiffing then
			local elapsed = now - whiffStartTime
			if elapsed < whiffDuration then
				isActionActive = true
				local progress = elapsed / whiffDuration
				targetPose = if isCurveWhiff
					then PlayerActionPoseConfigs.GetCurveWhiffPose(progress)
					else PlayerActionPoseConfigs.GetWhiffPose(progress)
			else
				isWhiffing = false
			end

		-- PRIORITY 6: Active Charge Stance ("ง้าง รอได้" windup hold)
		elseif isCharging or (char:GetAttribute("IsCharging") == true) or (currentActionState == "Holding") then
			isActionActive = true
			local sAct = (char:GetAttribute("ChargeAction") :: string?) or chargeAction
			local elapsed = if chargeStartTime > 0 then (now - chargeStartTime) else 0.2
			local rawPose = PlayerActionPoseConfigs.GetChargePose(sAct, elapsed, chargeCurveStyle)
			local resolvedFoot = chargeKickFoot or (char:GetAttribute("ResolvedKickFoot") :: string?) or (char:GetAttribute("KickFoot") :: string?)
			if resolvedFoot == "Left" then
				rawPose = PlayerActionPoseConfigs.MirrorPoseSagittal(rawPose)
			end
			targetPose = rawPose

		-- PRIORITY 7: Dash Burst Forward Lean
		elseif isDashing then
			local elapsed = now - dashStartTime
			if elapsed < dashDuration then
				isActionActive = true
				local progress = elapsed / dashDuration
				targetPose = PlayerActionPoseConfigs.GetDashPose(progress)
			else
				isDashing = false
			end

		-- PRIORITY 8: Jump Landing Shock Absorption (Image 1 Row 1 Step 3)
		elseif isLanding then
			local elapsed = now - landingStartTime
			if elapsed < landingDuration then
				isActionActive = true
				local progress = elapsed / landingDuration
				targetPose = PlayerActionPoseConfigs.GetJumpLandingPose(progress)
			else
				isLanding = false
			end
		end

		if isActionActive then
			wasCustomPoseActive = true
			char:SetAttribute("IsCustomPoseActive", true)
			local lerpRate = if isDashing then 36.0 elseif isCharging or currentActionState == "Holding" then 30.0 else 22.0
			local minAlpha = if isDashing then 0.35 elseif isCharging or currentActionState == "Holding" then 0.25 else 0.15
			local alpha = math.clamp(dt * lerpRate, minAlpha, 1.0)
			local joints = getCharacterJoints(char)
			for name, joint in pairs(joints) do
				local target = (targetPose :: any)[name] or CFrame.identity
				currentOffsets[name] = currentOffsets[name]:Lerp(target, alpha)
			end

			-- Dynamic visual RootJoint clearance shift:
			-- Evaluates minimum Y across all 6 body parts in reference floor coordinates.
			-- If minY < 0.010, shifts RootJoint C0 by Δy = max(0, 0.010 - minY) to prevent floor penetration (F-25)
			-- without shifting HRP, modifying physics, or anchoring.
			local minY = calculateRigMinY(currentOffsets)
			local deltaY = math.max(0, 0.010 - minY)
			local effectiveRootCF = if deltaY > 0 then (CFrame.new(0, deltaY, 0) * currentOffsets.RootJoint) else currentOffsets.RootJoint

			for name, joint in pairs(joints) do
				if name == "RootJoint" then
					setJointOffset(joint, effectiveRootCF)
				else
					setJointOffset(joint, currentOffsets[name])
				end
			end
		elseif wasCustomPoseActive then
			-- Smoothly lerp back to neutral pose before resting
			local alpha = math.clamp(dt * 20, 0.15, 1.0)
			local joints = getCharacterJoints(char)
			local isSettled = true
			for name, joint in pairs(joints) do
				currentOffsets[name] = currentOffsets[name]:Lerp(CFrame.identity, alpha)
				if currentOffsets[name].Position.Magnitude > 0.005 then
					isSettled = false
				end
			end

			local minY = calculateRigMinY(currentOffsets)
			local deltaY = math.max(0, 0.010 - minY)
			local effectiveRootCF = if deltaY > 0 then (CFrame.new(0, deltaY, 0) * currentOffsets.RootJoint) else currentOffsets.RootJoint

			for name, joint in pairs(joints) do
				if name == "RootJoint" then
					setJointOffset(joint, effectiveRootCF)
				else
					setJointOffset(joint, currentOffsets[name])
				end
			end

			if isSettled then
				wasCustomPoseActive = false
				char:SetAttribute("IsCustomPoseActive", false)
				resetAllJoints(char)
			end
		end
	end)
end

function R6ActionPoseController.Cleanup()
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
	local char = localPlayer and localPlayer.Character
	if char then
		resetAllJoints(char)
	end
	isInitialized = false
	lastObservedCharacter = nil
end

return R6ActionPoseController
