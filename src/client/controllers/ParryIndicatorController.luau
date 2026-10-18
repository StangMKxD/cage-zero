--!strict
-- src/client/controllers/ParryIndicatorController.luau
-- Module 02: Connects Server ParryWindowTrigger to ParryPromptOverlay (0.35s shrinking ring prompt)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

local UIFolder = script.Parent.Parent:WaitForChild("ui")
local ParryPromptOverlay = require(UIFolder:WaitForChild("screens"):WaitForChild("ParryPromptOverlay"))

local isInitialized = false
local lastWindowBallId: string? = nil
local windowActiveUntil = 0

local ParryIndicatorController = {}

function ParryIndicatorController.IsParryWindowActive(): boolean
	return os.clock() <= windowActiveUntil
end

function ParryIndicatorController.GetLastWindowBallId(): string?
	return lastWindowBallId
end

function ParryIndicatorController.HandleParryWindow(ballId: string, windowDuration: number)
	local duration = if windowDuration > 0 then windowDuration else Constants.PARRY_WINDOW_DURATION_SEC
	lastWindowBallId = ballId
	windowActiveUntil = os.clock() + duration
	if type(ParryPromptOverlay.ShowPrompt) == "function" then
		ParryPromptOverlay.ShowPrompt(ballId, duration)
	end
end

function ParryIndicatorController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local triggerEvent = Network.GetRemoteEvent(Network.Names.ParryWindowTrigger)
	triggerEvent.OnClientEvent:Connect(function(ballId: string, windowDuration: number)
		ParryIndicatorController.HandleParryWindow(ballId, windowDuration)
	end)
end

return table.freeze(ParryIndicatorController)
