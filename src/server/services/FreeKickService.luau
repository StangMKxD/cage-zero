--!strict
-- src/server/services/FreeKickService.luau
-- Module 04: FC27 Set-Piece & Free Kick Control (Aim Line + Spin Selector Curve/Dip/Knuckleball + Timed Bar)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local Services = script.Parent
local BallService = require(Services:WaitForChild("BallService"))
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

export type FreeKickTrajectory = {
	initialVelocity: Vector3,
	magnusLateralAccel: Vector3,
	dippingVerticalAccel: number,
	isKnuckleball: boolean,
	knuckleWobbleAmplitude: number,
	accuracyFactor: number,
	shotClassification: "CurveShot" | "DippingTopspin" | "LoftedChip" | "Knuckleball",
}

local TIMING_ZONE_ACCURACY: { [Types.FreeKickTimingZone]: number } = table.freeze({
	Green = 1.00,
	Yellow = 0.75,
	Red = 0.40,
})

local activeShooterUserId: number? = nil
local activeSpotPosition = Vector3.zero
local activeFreeKickExpiresAt = 0.0
local isInitialized = false

local FreeKickService = {}

function FreeKickService.ComputeFreeKickTrajectory(
	aimDir: Vector3,
	spinOffset: Vector2,
	powerPercent: number,
	timingZone: Types.FreeKickTimingZone,
	shotMultiplier: number?
): FreeKickTrajectory
	local cleanAim = if aimDir.Magnitude > 1e-3 then aimDir.Unit else Vector3.new(0, 0.18, 1).Unit
	local clampedSpin = Vector2.new(
		math.clamp(spinOffset.X, -1.0, 1.0),
		math.clamp(spinOffset.Y, -1.0, 1.0)
	)
	local clampedPower = math.clamp(powerPercent, 0.1, 1.0)
	local accuracy = TIMING_ZONE_ACCURACY[timingZone] or 0.40
	local statMult = shotMultiplier or 1.0

	-- Section 4.5: Center contact (spinOffset.Magnitude < 0.15) produces an unpredictable Knuckleball
	local isKnuckle = clampedSpin.Magnitude < 0.15
	local classification: "CurveShot" | "DippingTopspin" | "LoftedChip" | "Knuckleball" = "CurveShot"
	if isKnuckle then
		classification = "Knuckleball"
	elseif math.abs(clampedSpin.X) >= math.abs(clampedSpin.Y) then
		classification = "CurveShot"
	elseif clampedSpin.Y > 0 then
		classification = "DippingTopspin"
	else
		classification = "LoftedChip"
	end

	local baseSpeed = (65.0 + (65.0 * clampedPower)) * statMult * (0.7 + (0.3 * accuracy))
	local loftY = math.clamp(cleanAim.Y + (-clampedSpin.Y * 0.22) + (0.18 * clampedPower), 0.05, 0.65)
	local launchDir = Vector3.new(cleanAim.X, loftY, cleanAim.Z).Unit

	-- Right vector perpendicular to launchDir for Magnus lateral curve force
	local rightVec = launchDir:Cross(Vector3.new(0, 1, 0))
	if rightVec.Magnitude < 1e-3 then
		rightVec = Vector3.new(1, 0, 0)
	else
		rightVec = rightVec.Unit
	end

	local magnusAccel = if isKnuckle
		then Vector3.zero
		else rightVec * (-clampedSpin.X * 42.0 * accuracy)

	local dippingAccel = if isKnuckle then -12.0 else (-clampedSpin.Y * 28.0 * accuracy)
	local knuckleAmp = if isKnuckle then (18.0 * clampedPower * accuracy) else 0.0

	return {
		initialVelocity = launchDir * baseSpeed,
		magnusLateralAccel = magnusAccel,
		dippingVerticalAccel = dippingAccel,
		isKnuckleball = isKnuckle,
		knuckleWobbleAmplitude = knuckleAmp,
		accuracyFactor = accuracy,
		shotClassification = classification,
	}
end

function FreeKickService.StartFreeKick(shooter: Player, spotPosition: Vector3, timeLimitSec: number?)
	local duration = timeLimitSec or 8.0
	activeShooterUserId = shooter.UserId
	activeSpotPosition = spotPosition
	activeFreeKickExpiresAt = os.clock() + duration

	BallService.SetPossessor(nil)
	BallService.SetBallPositionAndVelocity(spotPosition, Vector3.zero)

	local startEvent = Network.GetRemoteEvent(Network.Names.FreeKickStartEvent)
	startEvent:FireClient(shooter, spotPosition, duration)
end

function FreeKickService.SubmitFreeKick(
	player: Player,
	aimDir: Vector3,
	spinOffset: Vector2,
	powerPercent: number,
	timingZone: Types.FreeKickTimingZone
): FreeKickTrajectory?
	if activeShooterUserId ~= nil and activeShooterUserId ~= player.UserId then
		return nil
	end
	if activeShooterUserId ~= nil and os.clock() > activeFreeKickExpiresAt then
		activeShooterUserId = nil
		return nil
	end

	local cardCfg = RigAndCardService.GetEquippedCardConfig(player.UserId)
	local trajectory = FreeKickService.ComputeFreeKickTrajectory(
		aimDir,
		spinOffset,
		powerPercent,
		timingZone,
		cardCfg.statModifiers.shotMultiplier
	)

	activeShooterUserId = nil
	BallService.SetPossessor(nil)
	local ballState = BallService.GetBallState()
	local startPos = if activeSpotPosition.Magnitude > 0 then activeSpotPosition else ballState.position
	BallService.SetBallPositionAndVelocity(startPos, trajectory.initialVelocity)

	return trajectory
end

function FreeKickService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local submitEvent = Network.GetRemoteEvent(Network.Names.FreeKickSubmit)
	submitEvent.OnServerEvent:Connect(
		function(player: Player, aimDir: any, spinOffset: any, powerPercent: any, timingZone: any)
			if not Network.IsFiniteVector3(aimDir) then
				return
			end
			if typeof(spinOffset) ~= "Vector2" then
				return
			end
			if not Network.IsNumberInRange(powerPercent, 0.0, 1.0) then
				return
			end
			if timingZone ~= "Green" and timingZone ~= "Yellow" and timingZone ~= "Red" then
				return
			end
			FreeKickService.SubmitFreeKick(
				player,
				aimDir :: Vector3,
				spinOffset :: Vector2,
				powerPercent :: number,
				timingZone :: Types.FreeKickTimingZone
			)
		end
	)
end

return table.freeze(FreeKickService)
