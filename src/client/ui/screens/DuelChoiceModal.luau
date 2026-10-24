--!strict
-- src/client/ui/screens/DuelChoiceModal.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- 1v1 Tactical Choice Modal (0.8s / 0.45s timer, 5 Role Choices, OUT OF SHOOTING ZONE lock on Snap Shot, Red Padlock icon on Mistake)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local DuelChoiceModal = {}

export type ChoiceButtonUIState = {
	choice: Types.ChoiceAction,
	isLocked: boolean,
	lockReason: "MISTAKE" | "OUT_OF_SHOOTING_ZONE" | "NONE",
	badgeText: string,
	showRedPadlockIcon: boolean,
}

local isVisible = false
local activeDuelId: string? = nil
local activeRole: Types.PlayerRole = "Forward"
local activeTimeLimit = 0.8
local choiceButtonStates: { [Types.ChoiceAction]: ChoiceButtonUIState } = {}
local activeSelectCallback: ((Types.ChoiceAction) -> ())? = nil
local lastWinnerUserId: number? = nil
local lastAppliedBuff: string? = nil
local rootFrame: Frame? = nil

function DuelChoiceModal.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "DuelChoiceModal"
	frame.Size = UDim2.new(0, 740, 0, 260)
	frame.Position = UDim2.new(0.5, -370, 0.62, -130)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentGold, 2)

	local timerLbl = Instance.new("TextLabel")
	timerLbl.Name = "DuelTimerBar"
	timerLbl.Size = UDim2.new(1, -32, 0, 36)
	timerLbl.Position = UDim2.new(0, 16, 0, 12)
	timerLbl.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	timerLbl.Font = UITheme.Fonts.Mono
	timerLbl.TextColor3 = UITheme.Colors.AccentGold
	timerLbl.TextSize = 18
	timerLbl.Text = string.format("1v1 DUEL WINDOW: %.2fs", activeTimeLimit)
	UITheme.ApplyCornerAndStroke(timerLbl, UITheme.CornerRadius.Small, UITheme.Colors.AccentGold, 1)
	timerLbl.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function DuelChoiceModal.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function DuelChoiceModal.IsVisible(): boolean
	return isVisible
end

function DuelChoiceModal.OpenModal(
	_duelId: string,
	_role: Types.PlayerRole,
	_availableChoices: { Types.ChoiceAction },
	_lockedChoices: { [Types.ChoiceAction]: boolean },
	_timeLimit: number,
	_onSelectCallback: (Types.ChoiceAction) -> (),
	_isOutOfShootingZone: boolean?
)
	-- Retired per Q22 / Spec 02: Choice Duel modal route disabled
	DuelChoiceModal.SetVisible(false)
end

DuelChoiceModal.IsRetired = true

function DuelChoiceModal.ClickChoice(choice: Types.ChoiceAction): boolean
	local btnState = choiceButtonStates[choice]
	if not btnState or btnState.isLocked then
		return false
	end

	if activeSelectCallback then
		activeSelectCallback(choice)
	end
	return true
end

function DuelChoiceModal.ShowResultAndClose(
	duelId: string,
	winnerUserId: number,
	_cutsceneAnimId: string,
	appliedBuff: string
)
	if activeDuelId == duelId or activeDuelId == nil then
		lastWinnerUserId = winnerUserId
		lastAppliedBuff = appliedBuff
		activeDuelId = nil
		activeSelectCallback = nil
		DuelChoiceModal.SetVisible(false)
		UIManager.CloseOverlay("DuelChoiceModal")
	end
end

function DuelChoiceModal.GetChoiceButtonState(choice: Types.ChoiceAction): ChoiceButtonUIState?
	return choiceButtonStates[choice]
end

function DuelChoiceModal.GetModalSnapshot(): {
	isVisible: boolean,
	duelId: string?,
	role: Types.PlayerRole,
	timeLimit: number,
	lastWinnerUserId: number?,
	lastAppliedBuff: string?,
}
	return {
		isVisible = isVisible,
		duelId = activeDuelId,
		role = activeRole,
		timeLimit = activeTimeLimit,
		lastWinnerUserId = lastWinnerUserId,
		lastAppliedBuff = lastAppliedBuff,
	}
end

UIManager.RegisterScreen("DuelChoiceModal", DuelChoiceModal)

return DuelChoiceModal
