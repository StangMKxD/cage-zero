--!strict
-- src/server/services/MatchService.luau
-- MODULE 08: 08-integration-and-uat
-- Server-Authoritative Match Loop orchestrating Lobby -> Pre-Match Position Select -> Hex-Cage Match -> 90s Dynamic Events -> Goal Scoring -> Post-Match Mutated Reward Breakdown

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

local CagePhysicsService = require(script.Parent.CagePhysicsService)
local BallService = require(script.Parent.BallService)
local ParryService = require(script.Parent.ParryService)
local DuelEngineService = require(script.Parent.DuelEngineService)
local FreeKickService = require(script.Parent.FreeKickService)
local EventManagerService = require(script.Parent.EventManagerService)
local TraitAndThreadService = require(script.Parent.TraitAndThreadService)
local RigAndCardService = require(script.Parent.RigAndCardService)
local TradeMarketService = require(script.Parent.TradeMarketService)

local MatchService = {}

MatchService.DEFAULT_MATCH_DURATION_SECONDS = 300.0
MatchService.BASE_WIN_CASH = 200
MatchService.BASE_WIN_EXP = 300
MatchService.BASE_LOSS_CASH = 100
MatchService.BASE_LOSS_EXP = 150

export type MatchPhase = "LOBBY" | "PRE_MATCH" | "IN_PROGRESS" | "COMPLETED"

export type MatchSession = {
	matchId: string,
	mode: string,
	phase: MatchPhase,
	teamAUserIds: { number },
	teamBUserIds: { number },
	playerRoles: { [number]: Types.PlayerRole },
	playerGoals: { [number]: number },
	teamAScore: number,
	teamBScore: number,
	remainingSeconds: number,
	ballId: string,
	mvpUserId: number?,
	rewardsByPlayer: {
		[number]: {
			baseCash: number,
			bonusCash: number,
			totalCash: number,
			baseExp: number,
			bonusExp: number,
			totalExp: number,
		},
	},
}

local activeMatches: { [string]: MatchSession } = {}
local nextMatchCounter = 0
local isInitialized = false

function MatchService.CreateMatchSession(
	mode: string,
	teamAUserIds: { number },
	teamBUserIds: { number },
	durationSeconds: number?
): MatchSession
	nextMatchCounter += 1
	local matchId = string.format("Match_%d", nextMatchCounter)

	local playerRoles: { [number]: Types.PlayerRole } = {}
	local playerGoals: { [number]: number } = {}

	for idx, userId in ipairs(teamAUserIds) do
		local defaultRole: Types.PlayerRole = if idx == 1
			then "Forward"
			elseif idx == 2 then "Midfielder"
			else "Defender"
		playerRoles[userId] = defaultRole
		playerGoals[userId] = 0
		TraitAndThreadService.GetOrCreateProfile(userId)
	end

	for idx, userId in ipairs(teamBUserIds) do
		local defaultRole: Types.PlayerRole = if idx == 1
			then "Forward"
			elseif idx == 2 then "Midfielder"
			else "Defender"
		playerRoles[userId] = defaultRole
		playerGoals[userId] = 0
		TraitAndThreadService.GetOrCreateProfile(userId)
	end

	local session: MatchSession = {
		matchId = matchId,
		mode = mode,
		phase = "PRE_MATCH",
		teamAUserIds = table.clone(teamAUserIds),
		teamBUserIds = table.clone(teamBUserIds),
		playerRoles = playerRoles,
		playerGoals = playerGoals,
		teamAScore = 0,
		teamBScore = 0,
		remainingSeconds = durationSeconds or MatchService.DEFAULT_MATCH_DURATION_SECONDS,
		ballId = "MatchBall_" .. matchId,
		mvpUserId = nil,
		rewardsByPlayer = {},
	}

	activeMatches[matchId] = session
	return session
end

function MatchService.AssignPlayerRole(matchId: string, userId: number, role: Types.PlayerRole): boolean
	local session = activeMatches[matchId]
	if not session then
		return false
	end
	if role ~= "Forward" and role ~= "Midfielder" and role ~= "Defender" then
		return false
	end

	session.playerRoles[userId] = role
	return true
end

function MatchService.StartMatch(matchId: string): boolean
	local session = activeMatches[matchId]
	if not session or session.phase == "IN_PROGRESS" then
		return false
	end

	session.phase = "IN_PROGRESS"
	session.teamAScore = 0
	session.teamBScore = 0

	-- Spawn ball at center of Hex-Cage
	BallService.SpawnBall(session.ballId, Vector3.new(0, 4, 0))
	EventManagerService.ResetMatchEvents()

	return true
end

function MatchService.RecordGoal(matchId: string, scoringTeam: "TeamA" | "TeamB", scorerUserId: number?): boolean
	local session = activeMatches[matchId]
	if not session or session.phase ~= "IN_PROGRESS" then
		return false
	end

	if scoringTeam == "TeamA" then
		session.teamAScore += 1
	else
		session.teamBScore += 1
	end

	if scorerUserId and session.playerGoals[scorerUserId] ~= nil then
		session.playerGoals[scorerUserId] += 1
	end

	-- Reset ball to center of Hex-Cage after goal
	BallService.SpawnBall(session.ballId, Vector3.new(0, 4, 0))
	return true
end

function MatchService.StepMatch(matchId: string, dt: number, nowTime: number?): {
	phase: MatchPhase,
	goalScoredBy: ("TeamA" | "TeamB")?,
	activeEventId: Types.MatchEventId?,
}
	local session = activeMatches[matchId]
	if not session then
		return {
			phase = "LOBBY",
			goalScoredBy = nil,
			activeEventId = nil,
		}
	end

	if session.phase ~= "IN_PROGRESS" then
		return {
			phase = session.phase,
			goalScoredBy = nil,
			activeEventId = EventManagerService.GetActiveEventId(),
		}
	end

	-- 1. Step Dynamic Match Event Clock (rotates every 90s)
	local activeEventId = EventManagerService.StepMatchClock(dt, nowTime)

	-- 2. Step Ball Physics & Hex-Cage Rebound
	local ballState = BallService.StepBallPhysics(session.ballId, dt)
	local goalScoredBy: ("TeamA" | "TeamB")? = nil

	if ballState then
		local goalCheck = CagePhysicsService.CheckGoalScored(ballState.position)
		if goalCheck then
			goalScoredBy = goalCheck
			MatchService.RecordGoal(matchId, goalCheck, ballState.ownerUserId)
		end
	end

	-- 3. Step Match Countdown Timer
	session.remainingSeconds = math.max(0, session.remainingSeconds - math.max(0, dt))
	if session.remainingSeconds <= 0 then
		MatchService.CompleteMatch(matchId)
	end

	return {
		phase = session.phase,
		goalScoredBy = goalScoredBy,
		activeEventId = activeEventId,
	}
end

function MatchService.CompleteMatch(matchId: string): MatchSession?
	local session = activeMatches[matchId]
	if not session then
		return nil
	end

	session.phase = "COMPLETED"
	EventManagerService.EndCurrentEvent()

	-- Determine winning team and MVP
	local isTeamAWinner = session.teamAScore >= session.teamBScore
	local winningTeam = if isTeamAWinner then session.teamAUserIds else session.teamBUserIds
	local bestGoals = -1
	local mvpUserId: number? = winningTeam[1]

	for userId, goals in pairs(session.playerGoals) do
		if goals > bestGoals then
			bestGoals = goals
			mvpUserId = userId
		end
	end
	session.mvpUserId = mvpUserId

	-- Calculate Post-Match Rewards with Mutated Thread Multipliers
	for _, userId in ipairs(session.teamAUserIds) do
		local baseCash = if isTeamAWinner then MatchService.BASE_WIN_CASH else MatchService.BASE_LOSS_CASH
		local baseExp = if isTeamAWinner then MatchService.BASE_WIN_EXP else MatchService.BASE_LOSS_EXP
		session.rewardsByPlayer[userId] = TraitAndThreadService.ComputePostMatchReward(userId, baseCash, baseExp)
	end

	for _, userId in ipairs(session.teamBUserIds) do
		local baseCash = if not isTeamAWinner then MatchService.BASE_WIN_CASH else MatchService.BASE_LOSS_CASH
		local baseExp = if not isTeamAWinner then MatchService.BASE_WIN_EXP else MatchService.BASE_LOSS_EXP
		session.rewardsByPlayer[userId] = TraitAndThreadService.ComputePostMatchReward(userId, baseCash, baseExp)
	end

	return session
end

function MatchService.GetMatchSession(matchId: string): MatchSession?
	return activeMatches[matchId]
end

function MatchService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	RigAndCardService.Init()
	CagePhysicsService.Init()
	BallService.Init()
	ParryService.Init()
	DuelEngineService.Init()
	FreeKickService.Init()
	EventManagerService.Init()
	TraitAndThreadService.Init()
	TradeMarketService.Init()
end

return MatchService
