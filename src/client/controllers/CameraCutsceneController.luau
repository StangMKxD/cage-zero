--!strict
-- src/client/controllers/CameraCutsceneController.luau
-- Module 04: Low-Angle Anime Slow-Motion Duel Win Cutscenes (0.6s, Zero-Drift Camera Offset) & Goal Celebrations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local CUTSCENE_DURATION_SEC = 0.60
local currentCameraOffset = CFrame.identity
local cutsceneRemainingSec = 0.0
local lastPlayedCutsceneAnimId: string? = nil
local lastCelebrationAnimId: string? = nil
local isInitialized = false

local CameraCutsceneController = {
	CUTSCENE_DURATION_SEC = CUTSCENE_DURATION_SEC,
}

function CameraCutsceneController.PlayDuelWinCutscene(winnerUserId: number, cutsceneAnimId: string, _appliedBuff: string?)
	lastPlayedCutsceneAnimId = cutsceneAnimId
	cutsceneRemainingSec = CUTSCENE_DURATION_SEC

	local winnerPlayer = Players:GetPlayerByUserId(winnerUserId)
	if winnerPlayer and winnerPlayer.Character then
		winnerPlayer.Character:SetAttribute("LastDuelWinAnim", cutsceneAnimId)
		winnerPlayer.Character:SetAttribute("EyeGlowActive", true)
		task.delay(CUTSCENE_DURATION_SEC, function()
			if winnerPlayer.Character then
				winnerPlayer.Character:SetAttribute("EyeGlowActive", false)
			end
		end)
	end
end

function CameraCutsceneController.PlayGoalCelebration(userId: number, celebrationAnimId: string)
	lastCelebrationAnimId = celebrationAnimId
	local player = Players:GetPlayerByUserId(userId)
	if player and player.Character then
		player.Character:SetAttribute("ActiveCelebrationAnim", celebrationAnimId)
	end
end

function CameraCutsceneController.GetLastCutsceneAnimId(): string?
	return lastPlayedCutsceneAnimId
end

function CameraCutsceneController.GetLastCelebrationAnimId(): string?
	return lastCelebrationAnimId
end

function CameraCutsceneController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Zero-Drift Camera Cutscene Loop (per MEM-FIX-0003)
	RunService.RenderStepped:Connect(function(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam then
			return
		end

		-- Always strip previous frame's offset first to prevent floating-point camera drift
		cam.CFrame = cam.CFrame * currentCameraOffset:Inverse()

		if cutsceneRemainingSec > 0 then
			cutsceneRemainingSec = math.max(0.0, cutsceneRemainingSec - dt)
			local alpha = cutsceneRemainingSec / CUTSCENE_DURATION_SEC
			currentCameraOffset = CFrame.new(0, -1.2 * alpha, -2.5 * alpha)
				* CFrame.Angles(math.rad(8 * alpha), 0, math.rad(3 * alpha))
			cam.CFrame = cam.CFrame * currentCameraOffset
		else
			currentCameraOffset = CFrame.identity
		end
	end)

	local resultEvent = Network.GetRemoteEvent(Network.Names.DuelResultEvent)
	resultEvent.OnClientEvent:Connect(
		function(_duelId: string, winnerUserId: number, cutsceneAnimId: string, appliedBuff: string?)
			CameraCutsceneController.PlayDuelWinCutscene(winnerUserId, cutsceneAnimId, appliedBuff)
		end
	)
end

return table.freeze(CameraCutsceneController)
