--!strict
-- src/client/controllers/DuelUIController.luau
-- Module 03: Connects DuelStartEvent & DuelResultEvent to DuelChoiceModal and UIManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local UIFolder = script.Parent.Parent:WaitForChild("ui")
local UIManager = require(UIFolder:WaitForChild("UIManager"))
local DuelChoiceModal = require(UIFolder:WaitForChild("screens"):WaitForChild("DuelChoiceModal"))

local currentDuelId: string? = nil
local isInitialized = false

local DuelUIController = {}

function DuelUIController.SubmitChoice(choiceId: string): boolean
	if currentDuelId == nil then
		return false
	end
	local submitRemote = Network.GetRemoteEvent(Network.Names.DuelChoiceSubmit)
	submitRemote:FireServer(currentDuelId, choiceId)
	return true
end

function DuelUIController.GetActiveDuelId(): string?
	return currentDuelId
end

function DuelUIController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local startEvent = Network.GetRemoteEvent(Network.Names.DuelStartEvent)
	startEvent.OnClientEvent:Connect(
		function(
			duelId: string,
			role: Types.DuelRole,
			availableChoices: { string },
			lockedChoices: { string },
			timeLimit: number
		)
			currentDuelId = duelId
			if type(DuelChoiceModal.OpenModal) == "function" then
				DuelChoiceModal.OpenModal(duelId, role, availableChoices, lockedChoices, timeLimit, function(choiceId: string)
					DuelUIController.SubmitChoice(choiceId)
				end)
			end
			if type(UIManager.OpenOverlay) == "function" then
				UIManager.OpenOverlay("DuelChoiceModal")
			end
		end
	)

	local resultEvent = Network.GetRemoteEvent(Network.Names.DuelResultEvent)
	resultEvent.OnClientEvent:Connect(
		function(duelId: string, winnerUserId: number, cutsceneAnimId: string, appliedBuff: string?)
			if currentDuelId == duelId then
				currentDuelId = nil
			end
			if type(DuelChoiceModal.ShowResultAndClose) == "function" then
				DuelChoiceModal.ShowResultAndClose(duelId, winnerUserId, cutsceneAnimId, appliedBuff)
			end
			if type(UIManager.CloseOverlay) == "function" then
				UIManager.CloseOverlay("DuelChoiceModal")
			end
		end
	)
end

return table.freeze(DuelUIController)
