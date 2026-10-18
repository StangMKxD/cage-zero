--!strict
-- src/server/services/ParryService.luau
-- Module 02: Split-Second Defender Parry System (<= 5.0 Studs, 0.35s Window, 0.50s Miss Recovery)
-- Rule 6: Parry NEVER triggers the 1v1 Choice Duel screen; timing is verified 100% Server-side via os.clock().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

local Services = script.Parent
local BallService = require(Services:WaitForChild("BallService"))

export typeDefenderParryState = {
	windowStartTime: number,
	windowExpiresAt: number,
	ballId: string,
	consumed: boolean,
	missedRecoveryUntil: number,
}

local parryStateByUserId: { [number]: typeDefenderParryState } = {}
local isInitialized = false

local ParryService = {}

local function getOrCreateParryState(userId: number): typeDefenderParryState
	local st = parryStateByUserId[userId]
	if st then
		return st
	end
	local newState: typeDefenderParryState = {
		windowStartTime = 0,
		windowExpiresAt = 0,
		ballId = "BALL_01",
		consumed = true,
		missedRecoveryUntil = 0,
	}
	parryStateByUserId[userId] = newState
	return newState
end

function ParryService.IsInMissedSlideRecovery(userId: number): boolean
	local st = getOrCreateParryState(userId)
	return os.clock() < st.missedRecoveryUntil
end

function ParryService.TriggerMissedSlideRecovery(userId: number)
	local st = getOrCreateParryState(userId)
	st.missedRecoveryUntil = os.clock() + Constants.PARRY_MISS_RECOVERY_SEC
end

-- Opens a 0.35s Parry window for a defender when a passed/shot ball enters their 5 Studs intercept radius
function ParryService.OpenParryWindowForDefender(defender: Player, ballId: string?): boolean
	local userId = defender.UserId
	local st = getOrCreateParryState(userId)
	local now = os.clock()

	if now < st.missedRecoveryUntil then
		return false
	end

	st.windowStartTime = now
	st.windowExpiresAt = now + Constants.PARRY_WINDOW_DURATION_SEC
	st.ballId = ballId or "BALL_01"
	st.consumed = false

	local triggerEvent = Network.GetRemoteEvent(Network.Names.ParryWindowTrigger)
	triggerEvent:FireClient(defender, st.ballId, Constants.PARRY_WINDOW_DURATION_SEC)
	return true
end

-- Evaluates a defender's Parry attempt strictly using Server os.clock() (never trusting clientTimestamp)
function ParryService.EvaluateParryAttempt(defender: Player, _clientTimestamp: number?): (boolean, string)
	local userId = defender.UserId
	local st = getOrCreateParryState(userId)
	local now = os.clock()

	if now < st.missedRecoveryUntil then
		return false, "OnRecoveryCooldown"
	end

	local ballState = BallService.GetBallState()
	if ballState.possessorUserId ~= nil then
		st.missedRecoveryUntil = now + Constants.PARRY_MISS_RECOVERY_SEC
		return false, "BallAlreadyPossessed"
	end

	if not st.consumed and now >= st.windowStartTime and now <= st.windowExpiresAt then
		st.consumed = true
		BallService.SetPossessor(userId, 0)
		return true, "PerfectParry"
	end

	-- Early or Late press triggers 0.50s MissedSlideRecovery penalty (Mistake Mechanic)
	st.consumed = true
	st.missedRecoveryUntil = now + Constants.PARRY_MISS_RECOVERY_SEC
	return false, "MissedTiming"
end

function ParryService.ScanPassingBallForParryTriggers()
	local ballState = BallService.GetBallState()
	-- Parry only triggers when the ball is loose and moving after a pass/shot
	if ballState.possessorUserId ~= nil or ballState.velocity.Magnitude < 12.0 then
		return
	end

	if ballState.laserGuidedPassActive then
		-- Laser Guided Pass curves around defenders (Trait guarantee)
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.UserId ~= ballState.lastKickerUserId then
			local playerTeam = BallService.GetPlayerTeamSide(player.UserId)
			if ballState.lastKickTeam == nil or playerTeam ~= ballState.lastKickTeam then
				local char = player.Character
				if char and char.PrimaryPart then
					local dist = (char.PrimaryPart.Position - ballState.position).Magnitude
					if dist <= Constants.PARRY_INTERCEPT_RADIUS_STUDS then
						local st = getOrCreateParryState(player.UserId)
						if st.consumed or os.clock() > st.windowExpiresAt then
							ParryService.OpenParryWindowForDefender(player, ballState.ballId)
						end
					end
				end
			end
		end
	end
end

function ParryService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local parryAttemptEvent = Network.GetRemoteEvent(Network.Names.ParryAttemptRequest)
	parryAttemptEvent.OnServerEvent:Connect(function(player: Player, clientTimestamp: any)
		local ts = if type(clientTimestamp) == "number" then clientTimestamp else 0
		ParryService.EvaluateParryAttempt(player, ts)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		parryStateByUserId[player.UserId] = nil
	end)
end

return table.freeze(ParryService)
