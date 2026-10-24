--!strict
-- src/client/controllers/DuelUIController.luau
-- Module 03: Connects DuelStartEvent & DuelResultEvent to DuelChoiceModal and UIManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

local currentDuelId: string? = nil
local isInitialized = false

local DuelUIController = {}

function DuelUIController.SubmitChoice(_choiceId: string): boolean
	-- Retired per Q22 / Spec 02
	return false
end

function DuelUIController.GetActiveDuelId(): string?
	return currentDuelId
end

function DuelUIController.Init()
	-- Retired per Q22 / Spec 02: DuelStartEvent & DuelResultEvent listeners disabled
	isInitialized = true
end

DuelUIController.IsRetired = true

return table.freeze(DuelUIController)
