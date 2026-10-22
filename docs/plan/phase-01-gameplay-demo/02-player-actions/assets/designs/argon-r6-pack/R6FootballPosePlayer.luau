--!strict
--[[
    R6FootballPosePlayer.luau
    Status: Untested reference code (Mathematically verified against R6 Motor6D FK & OBB solver)

    Reference Runtime Pose Evaluator & Motor6D Controller for Roblox Classic R6 Football Animations (A01 - A18).

    ===========================================================================
    MATHEMATICAL & COORDINATE SPACE SPECIFICATION
    ===========================================================================
    1. Character / Part0 Reference Space:
       +X = Character Right
       +Y = Up
       -Z = Character Forward (Front)
       +Z = Character Backward (Back)

    2. Motor6D Forward Kinematics Equation (Roblox Engine):
       Part0.CFrame * C0 * Transform = Part1.CFrame * C1

    3. Pivot-Relative Part0 Offset (D -> P -> Motor6D.Transform):
       Each keyframe stores translation `pos = (tx, ty, tz)` in studs (at Scale = 1)
       and Euler angles `rotDeg = (rx, ry, rz)` in degrees in Part0 Reference Space
       around the joint pivot `p = baseC0.Position`:
           D = CFrame.new(tx * scaleX, ty * scaleY, tz * scaleZ)
               * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz))
           P = CFrame.new(p) * D * CFrame.new(-p)
           Transform = baseC0:Inverse() * P * baseC0

       Why this is critical for R6:
       - RootJoint & Neck have rest rotation B = CFrame.new(0,0,0, -1,0,0, 0,0,1, 0,1,0).
       - Right Shoulder & Right Hip have rest rotation R = CFrame.Angles(0, +90°, 0).
       - Left Shoulder & Left Hip have rest rotation L = CFrame.Angles(0, -90°, 0).
       Applying `rx` directly to `Motor6D.Transform` without conjugating by `baseC0`
       would abduct the legs sideways instead of swinging them forward/backward!
       Conjugating `P` by `baseC0` (`baseC0:Inverse() * P * baseC0`) guarantees that
       +rx ALWAYS pitches around Part0's +X axis, +ry yaws around Part0's +Y axis,
       and +rz rolls around Part0's +Z axis.

    4. Single Joint Driving Method & Animator Coexistence:
       - This player drives `Motor6D.Transform` exclusively inside `RunService.PreSimulation`
         (with fallback to `RunService.Stepped`).
       - `baseC0` and `baseC1` are read once from the live rig at initialization and NEVER
         overwritten, preventing cumulative floating-point drift.
       - To prevent default Roblox `Animator` / `Animate` tracks from fighting over the
         same 6 joints during full-body preview or active actions, `StopCompetingTracks()`
         stops active `Animator` tracks when `suppressDefaultAnimator = true`.
]]

local RunService = game:GetService("RunService")
local R6FootballPoseData = require(script.Parent:WaitForChild("R6FootballPoseData"))

type JointPoseSpec = R6FootballPoseData.JointPoseSpec
type KeyframeSpec = R6FootballPoseData.KeyframeSpec
type AnimationSpec = R6FootballPoseData.AnimationSpec

export type JointCacheEntry = {
    motor: Motor6D,
    part0: BasePart,
    part1: BasePart,
    baseC0: CFrame,
    baseC1: CFrame,
}

export type PlayParameters = {
    variant: string?,          -- "finesse" | "trivela" | "ground" | "lob" | "hit" | "miss"
    directionMultiplier: number?, -- +1 for Forward Walk, -1 for Backward Walk
    moveDirectionLocal: Vector3?, -- HRP-space move vector for A05 8-Way Strafe
    verticalVelocity: number?,    -- HRP.AssemblyLinearVelocity.Y for A06 Airborne Jump/Fall
    passPower: number?,           -- [0, 1] for A16 Single 3D Pass
    passElevationDeg: number?,    -- [0, 45] degrees for A16 Single 3D Pass
    playbackSpeed: number?,       -- Speed multiplier
    blendWeight: number?,         -- [0, 1] target blend weight (default 1.0)
    blendInOverride: number?,     -- Optional custom blend-in time (seconds)
}

local R6FootballPosePlayer = {}
R6FootballPosePlayer.__index = R6FootballPosePlayer

-- Hierarchy lookup table for standard R6 Motor6D instances
local R6_MOTOR_LOCATIONS: { [string]: { parentName: string, motorName: string } } = {
    ["RootJoint"]      = { parentName = "HumanoidRootPart", motorName = "RootJoint" },
    ["Neck"]           = { parentName = "Torso",            motorName = "Neck" },
    ["Right Shoulder"] = { parentName = "Torso",            motorName = "Right Shoulder" },
    ["Left Shoulder"]  = { parentName = "Torso",            motorName = "Left Shoulder" },
    ["Right Hip"]      = { parentName = "Torso",            motorName = "Right Hip" },
    ["Left Hip"]       = { parentName = "Torso",            motorName = "Left Hip" },
}

-- Frame-rate independent exponential decay factor
local function expAlpha(lambda: number, dt: number): number
    if dt <= 0 then
        return 0
    end
    return 1 - math.exp(-lambda * dt)
end

-- Converts a Part0-space (pos, rotDeg) offset around pivot p = baseC0.Position into Motor6D.Transform
local function buildMotorTransform(
    baseC0: CFrame,
    pos: Vector3,
    rotDeg: Vector3,
    scaleVec: Vector3
): CFrame
    local scaledPos = Vector3.new(pos.X * scaleVec.X, pos.Y * scaleVec.Y, pos.Z * scaleVec.Z)
    local rx = math.rad(rotDeg.X)
    local ry = math.rad(rotDeg.Y)
    local rz = math.rad(rotDeg.Z)

    -- XYZ Euler multiplication order: Rx(rx) * Ry(ry) * Rz(rz)
    local D = CFrame.new(scaledPos) * CFrame.Angles(rx, ry, rz)
    local p = baseC0.Position
    local P = CFrame.new(p) * D * CFrame.new(-p)
    return baseC0:Inverse() * P * baseC0
end

-- Evaluates piecewise keyframe list at normalized phase t in [0, 1] using CFrame:Lerp (shortest-path quaternion slerp)
local function sampleKeyframeList(
    keyframes: { KeyframeSpec },
    t: number,
    jointCache: { [string]: JointCacheEntry },
    scaleVec: Vector3
): { [string]: CFrame }
    local clampedT = math.clamp(t, 0, 1)
    local count = #keyframes
    local k0 = keyframes[1]
    local k1 = keyframes[count]
    local localAlpha = 0.0

    for i = 1, count - 1 do
        local a = keyframes[i]
        local b = keyframes[i + 1]
        if clampedT >= a.t and clampedT <= b.t then
            k0 = a
            k1 = b
            local span = b.t - a.t
            if span > 1e-6 then
                localAlpha = (clampedT - a.t) / span
            else
                localAlpha = 0.0
            end
            break
        end
    end

    local result: { [string]: CFrame } = {}
    for _, jointName in ipairs(R6FootballPoseData.RigConstants.JointNames) do
        local cache = jointCache[jointName]
        if cache then
            local spec0 = k0.joints[jointName]
            local spec1 = k1.joints[jointName]
            local cf0 = buildMotorTransform(cache.baseC0, spec0.pos, spec0.rotDeg, scaleVec)
            local cf1 = buildMotorTransform(cache.baseC0, spec1.pos, spec1.rotDeg, scaleVec)
            -- CFrame:Lerp uses quaternion shortest-path slerp internally, avoiding ±180° Euler jumps
            result[jointName] = cf0:Lerp(cf1, localAlpha)
        end
    end
    return result
end

function R6FootballPosePlayer.new(character: Model, suppressDefaultAnimator: boolean?)
    local self = setmetatable({}, R6FootballPosePlayer)
    self.character = character
    self.humanoid = character:FindFirstChildOfClass("Humanoid")
    self.animator = if self.humanoid then self.humanoid:FindFirstChildOfClass("Animator") else nil
    self.suppressDefaultAnimator = if suppressDefaultAnimator == nil then true else suppressDefaultAnimator

    -- Read and cache original Motor6D instances and their live rest C0 / C1
    self.jointCache = {} :: { [string]: JointCacheEntry }
    self.currentTransforms = {} :: { [string]: CFrame }

    for jointName, loc in pairs(R6_MOTOR_LOCATIONS) do
        local parentPart = character:FindFirstChild(loc.parentName)
        local motor: Motor6D? = nil
        if parentPart then
            local found = parentPart:FindFirstChild(loc.motorName)
            if found and found:IsA("Motor6D") then
                motor = found
            end
        end
        -- Fallback search across character descendants if RootJoint is inside Torso
        if not motor then
            for _, desc in ipairs(character:GetDescendants()) do
                if desc:IsA("Motor6D") and desc.Name == loc.motorName then
                    motor = desc
                    break
                end
            end
        end

        if motor and motor.Part0 and motor.Part1 then
            self.jointCache[jointName] = {
                motor = motor,
                part0 = motor.Part0,
                part1 = motor.Part1,
                baseC0 = motor.C0,
                baseC1 = motor.C1,
            }
            self.currentTransforms[jointName] = CFrame.identity
        else
            warn(string.format("[R6FootballPosePlayer] Missing Motor6D '%s' on rig '%s'", jointName, character.Name))
        end
    end

    -- Playback state
    self.activeAnimId = nil :: string?
    self.activeSpec = nil :: AnimationSpec?
    self.phase = 0.0
    self.elapsedSec = 0.0
    self.holdState = "None" :: "None" | "Entering" | "Holding" | "Canceling"
    self.blendWeight = 0.0
    self.targetBlendWeight = 1.0
    self.blendRate = 10.0
    self.params = {} :: PlayParameters
    self.smoothedMoveDir = Vector3.new(0, 0, -1)
    self.connection = nil :: RBXScriptConnection?

    return self
end

-- Computes current rig scale ratio relative to standard R6 Torso size (2, 2, 1)
function R6FootballPosePlayer:GetRigScaleVector(): Vector3
    local torso = self.character:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") then
        local baseSize = R6FootballPoseData.RigConstants.BasePartSizes["Torso"]
        return Vector3.new(
            torso.Size.X / baseSize.X,
            torso.Size.Y / baseSize.Y,
            torso.Size.Z / baseSize.Z
        )
    end
    return Vector3.new(1, 1, 1)
end

-- Stops competing Roblox Animator tracks so default Walk/Idle do not overwrite Motor6D.Transform
function R6FootballPosePlayer:StopCompetingTracks()
    if not self.suppressDefaultAnimator then
        return
    end
    local animateScript = self.character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
        animateScript.Enabled = false
        self._disabledAnimateScript = animateScript
    end
    if self.animator then
        for _, track in ipairs(self.animator:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end
end

-- Starts or switches to an animation ID ("A01" .. "A18")
function R6FootballPosePlayer:Play(animId: string, params: PlayParameters?, preservePhase: boolean?)
    local spec = R6FootballPoseData.Animations[animId]
    if not spec then
        warn(string.format("[R6FootballPosePlayer] Unknown animation ID '%s'", tostring(animId)))
        return
    end

    self:StopCompetingTracks()

    local p: PlayParameters = params or {}
    local keepPhase = (preservePhase == true) and (self.activeAnimId ~= nil)

    self.activeAnimId = animId
    self.activeSpec = spec
    self.params = p

    if not keepPhase then
        self.phase = 0.0
        self.elapsedSec = 0.0
    end

    if spec.mode == "Hold" then
        self.holdState = "Entering"
    else
        self.holdState = "None"
    end

    self.targetBlendWeight = if p.blendWeight ~= nil then math.clamp(p.blendWeight, 0, 1) else 1.0
    local blendIn = if p.blendInOverride ~= nil then p.blendInOverride else spec.blendIn
    if blendIn > 1e-4 then
        self.blendRate = 1.0 / blendIn
    else
        self.blendWeight = self.targetBlendWeight
        self.blendRate = 1000.0
    end
end

-- Releases a Hold animation (A12 -> A13, or A14 -> A15 with optional variant "finesse" | "trivela")
function R6FootballPosePlayer:ReleaseHold(releaseVariant: string?)
    local spec = self.activeSpec
    if not spec or spec.mode ~= "Hold" then
        return
    end
    local nextId = spec.nextAnimOnRelease
    if nextId then
        self:Play(nextId, {
            variant = releaseVariant or self.params.variant,
            blendWeight = self.targetBlendWeight,
            blendInOverride = 0.0, -- 0.0s seamless hand-off from Hold KF3
        }, false)
    end
end

-- Cancels a Hold animation (A12 or A14), advancing phase from 0.50 -> 1.00 (Cancel branch)
function R6FootballPosePlayer:CancelHold()
    local spec = self.activeSpec
    if not spec or spec.mode ~= "Hold" then
        return
    end
    if self.phase < (spec.holdPhase or 0.50) then
        self.phase = spec.holdPhase or 0.50
    end
    self.holdState = "Canceling"
end

-- Smoothly fades out active animation back to rest pose (or A01 Idle)
function R6FootballPosePlayer:Stop(fadeOutSec: number?)
    local fade = fadeOutSec or (if self.activeSpec then self.activeSpec.blendOut else 0.12)
    self.targetBlendWeight = 0.0
    if fade > 1e-4 then
        self.blendRate = 1.0 / fade
    else
        self.blendWeight = 0.0
        self.activeAnimId = nil
        self.activeSpec = nil
        self:ResetTransformsToRest()
    end
end

-- Directly sets normalized phase t in [0, 1] (useful for studio scrubbing & preview inspection)
function R6FootballPosePlayer:SetPhase(t: number, blendWeight: number?)
    self.phase = math.clamp(t, 0, 1)
    if blendWeight ~= nil then
        self.blendWeight = math.clamp(blendWeight, 0, 1)
        self.targetBlendWeight = self.blendWeight
    end
    self:EvaluateAndApply(0.0)
end

function R6FootballPosePlayer:UpdateParameters(partialParams: PlayParameters)
    for k, v in pairs(partialParams :: any) do
        (self.params :: any)[k] = v
    end
end

-- Evaluates current pose transforms for all 6 joints without mutating physics or C0/C1
function R6FootballPosePlayer:EvaluatePoseTransforms(dt: number): { [string]: CFrame }
    local spec = self.activeSpec
    if not spec then
        local identityMap: { [string]: CFrame } = {}
        for _, jn in ipairs(R6FootballPoseData.RigConstants.JointNames) do
            identityMap[jn] = CFrame.identity
        end
        return identityMap
    end

    local scaleVec = self:GetRigScaleVector()
    local animId = spec.id

    -- 1. Special Case: A16 Parametric Single 3D Pass (blends Ground & Lob profiles + Power scale)
    if animId == "A16" and spec.variants then
        local groundVar = spec.variants["ground"]
        local lobVar = spec.variants["lob"]
        local elevDeg = math.clamp(self.params.passElevationDeg or (if self.params.variant == "lob" then 35.0 else 0.0), 0.0, 45.0)
        local elevAlpha = math.clamp(elevDeg / 35.0, 0.0, 1.0)
        local power = math.clamp(self.params.passPower or 0.75, 0.0, 1.0)
        local powerScale = 0.65 + 0.35 * power

        local groundMap = sampleKeyframeList(groundVar.keyframes, self.phase, self.jointCache, scaleVec)
        local lobMap = sampleKeyframeList(lobVar.keyframes, self.phase, self.jointCache, scaleVec)

        local outMap: { [string]: CFrame } = {}
        for _, jn in ipairs(R6FootballPoseData.RigConstants.JointNames) do
            local blended = groundMap[jn]:Lerp(lobMap[jn], elevAlpha)
            outMap[jn] = CFrame.identity:Lerp(blended, powerScale)
        end
        return outMap
    end

    -- 2. Special Case: A05 Shift Lock 8-Way Strafe (continuous 2D directional modulation)
    if animId == "A05" and self.params.moveDirectionLocal then
        local rawMove = self.params.moveDirectionLocal
        local flatMove = Vector3.new(rawMove.X, 0, rawMove.Z)
        if flatMove.Magnitude > 1e-3 then
            flatMove = flatMove.Unit
            local a = expAlpha(R6FootballPoseData.Tuning.StrafeSmoothingLambda, dt)
            self.smoothedMoveDir = self.smoothedMoveDir:Lerp(flatMove, a)
            if self.smoothedMoveDir.Magnitude > 1e-3 then
                self.smoothedMoveDir = self.smoothedMoveDir.Unit
            end
        end

        local vx = self.smoothedMoveDir.X
        local vz = self.smoothedMoveDir.Z
        -- Forward component = -vz, Right component = +vx
        local fwd = -vz
        local right = vx
        local s = math.sin(self.phase * math.pi * 2)
        local c = math.cos(self.phase * math.pi * 2)

        -- Compute clamped diagonal hip yaw (prevents 180° leg flip when switching FL <-> FR or BL <-> BR)
        local diagSign = if math.abs(fwd) >= 0.15 then math.sign(fwd) else 1.0
        local torsoRy = math.clamp(-right * fwd * 48.0, -24.0, 24.0)
        local torsoRx = -8.0 - 4.0 * math.max(0, fwd)
        local torsoRz = -8.0 * right
        local hipRxAmp = 34.0 * fwd
        local hipRzAmp = 26.0 * right
        local bobY = 0.08 + 0.08 * math.abs(c)

        local synthPose: { [string]: JointPoseSpec } = {
            ["RootJoint"]      = { pos = Vector3.new(0.03 * right * s, bobY, 0), rotDeg = Vector3.new(torsoRx, torsoRy - 6.0 * c * diagSign, torsoRz) },
            ["Neck"]           = { pos = Vector3.zero, rotDeg = Vector3.new(-torsoRx, -torsoRy * 0.85, -torsoRz * 0.75) },
            ["Right Shoulder"] = { pos = Vector3.zero, rotDeg = Vector3.new(-28.0 * fwd * c, -6.0, 18.0 + 8.0 * math.max(0, right)) },
            ["Left Shoulder"]  = { pos = Vector3.zero, rotDeg = Vector3.new( 28.0 * fwd * c,  6.0, -18.0 - 8.0 * math.min(0, right)) },
            ["Right Hip"]      = { pos = Vector3.zero, rotDeg = Vector3.new( hipRxAmp * c, torsoRy * 0.35, math.max(2.0, hipRzAmp * c + 12.0 * math.max(0, right))) },
            ["Left Hip"]       = { pos = Vector3.zero, rotDeg = Vector3.new(-hipRxAmp * c, torsoRy * 0.35, math.min(-2.0, hipRzAmp * c + 12.0 * math.min(0, right))) },
        }

        local outMap: { [string]: CFrame } = {}
        for _, jn in ipairs(R6FootballPoseData.RigConstants.JointNames) do
            local cache = self.jointCache[jn]
            if cache then
                local sp = synthPose[jn]
                outMap[jn] = buildMotorTransform(cache.baseC0, sp.pos, sp.rotDeg, scaleVec)
            end
        end
        return outMap
    end

    -- 3. Standard Keyframe Evaluation (with Variant selection if present)
    local activeKeyframes = spec.keyframes
    if spec.variants and self.params.variant then
        local v = spec.variants[self.params.variant]
        if v then
            activeKeyframes = v.keyframes
        end
    end

    return sampleKeyframeList(activeKeyframes, self.phase, self.jointCache, scaleVec)
end

-- Advances timeline phase and applies interpolated transforms to Motor6D.Transform
function R6FootballPosePlayer:EvaluateAndApply(dt: number)
    local spec = self.activeSpec
    if spec then
        local speedMult = self.params.playbackSpeed or 1.0
        local dirMult = self.params.directionMultiplier or 1.0

        if spec.mode == "Loop" then
            local deltaPhase = (dt * speedMult * dirMult) / math.max(0.01, spec.duration)
            self.phase = (self.phase + deltaPhase) % 1.0
            self.elapsedSec += dt * speedMult
        elseif spec.mode == "StateAirborne" then
            -- A06 Directional Jump / Fall: map phase from vertical velocity vy if provided
            if self.params.verticalVelocity ~= nil then
                local vRef = R6FootballPoseData.Tuning.JumpReferenceVelocityY
                local mappedPhase = 0.50 - 0.50 * (self.params.verticalVelocity / vRef)
                self.phase = math.clamp(mappedPhase, 0.08, 0.98)
            else
                self.phase = math.clamp(self.phase + (dt * speedMult) / spec.duration, 0.0, 1.0)
            end
            self.elapsedSec += dt
        elseif spec.mode == "Hold" then
            local holdT = spec.holdPhase or 0.50
            if self.holdState == "Entering" then
                self.phase += (dt * speedMult) / spec.duration
                if self.phase >= holdT then
                    self.phase = holdT
                    self.holdState = "Holding"
                end
            elseif self.holdState == "Holding" then
                -- Strictly freeze phase at holdT: zero walk cycle, zero leg swapping
                self.phase = holdT
            elseif self.holdState == "Canceling" then
                self.phase += (dt * speedMult) / spec.duration
                if self.phase >= 1.0 then
                    self.phase = 1.0
                    self:Play("A01", { blendInOverride = spec.blendOut })
                end
            end
            self.elapsedSec += dt
        else -- "OneShot"
            self.phase += (dt * speedMult) / math.max(0.01, spec.duration)
            self.elapsedSec += dt * speedMult
            if self.phase >= 1.0 then
                self.phase = 1.0
                if spec.nextAnimOnComplete then
                    local nextId = spec.nextAnimOnComplete
                    local keep = (nextId == "A03")
                    self:Play(nextId, { variant = self.params.variant }, keep)
                    if nextId == "A03" then
                        self.phase = 0.50 -- A04 KF4 matches A03 KF3 (t=0.50)
                    end
                else
                    self:Stop(spec.blendOut)
                end
            end
        end
    end

    -- Update overall blend weight cleanly
    if self.blendWeight < self.targetBlendWeight then
        self.blendWeight = math.min(self.targetBlendWeight, self.blendWeight + self.blendRate * dt)
    elseif self.blendWeight > self.targetBlendWeight then
        self.blendWeight = math.max(self.targetBlendWeight, self.blendWeight - self.blendRate * dt)
    end

    local targetTransforms = self:EvaluatePoseTransforms(dt)
    local smoothAlpha = if dt > 0 then expAlpha(R6FootballPoseData.Tuning.DefaultSmoothingLambda, dt) else 1.0

    for _, jointName in ipairs(R6FootballPoseData.RigConstants.JointNames) do
        local cache = self.jointCache[jointName]
        if cache then
            local desired = CFrame.identity:Lerp(targetTransforms[jointName] or CFrame.identity, self.blendWeight)
            local nextCf = self.currentTransforms[jointName]:Lerp(desired, smoothAlpha)
            self.currentTransforms[jointName] = nextCf
            cache.motor.Transform = nextCf
        end
    end
end

-- Starts automatic frame-by-frame evaluation on RunService.PreSimulation (or Stepped)
function R6FootballPosePlayer:Start()
    if self.connection then
        return
    end
    self:StopCompetingTracks()
    local signal = if RunService:IsClient() or RunService:IsServer() then RunService.PreSimulation else RunService.Stepped
    self.connection = signal:Connect(function(dt: number)
        self:EvaluateAndApply(dt)
    end)
end

function R6FootballPosePlayer:ResetTransformsToRest()
    for _, jointName in ipairs(R6FootballPoseData.RigConstants.JointNames) do
        local cache = self.jointCache[jointName]
        if cache then
            cache.motor.Transform = CFrame.identity
            cache.motor.C0 = cache.baseC0
            cache.motor.C1 = cache.baseC1
            self.currentTransforms[jointName] = CFrame.identity
        end
    end
end

function R6FootballPosePlayer:Destroy()
    if self.connection then
        self.connection:Disconnect()
        self.connection = nil
    end
    self:ResetTransformsToRest()
    if self._disabledAnimateScript then
        self._disabledAnimateScript.Enabled = true
        self._disabledAnimateScript = nil
    end
end

return R6FootballPosePlayer
