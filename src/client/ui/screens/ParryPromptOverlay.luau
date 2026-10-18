--!strict
-- src/client/ui/screens/ParryPromptOverlay.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- 0.35s Shrinking Ring Overlay with [F] PARRY Prompt (Does NOT interrupt play with a 1v1 Duel modal)

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local ParryPromptOverlay = {}

ParryPromptOverlay.DEFAULT_DURATION_SECONDS = 0.35

local isVisible = false
local activeBallId: string? = nil
local activeDuration = 0.35
local promptOpenedAt = 0
local rootFrame: Frame? = nil

function ParryPromptOverlay.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "ParryPromptOverlay"
	frame.Size = UDim2.new(0, 180, 0, 180)
	frame.Position = UDim2.new(0.5, -90, 0.45, -90)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	frame.BackgroundTransparency = 0.25
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Pill, UITheme.Colors.AccentCyan, 3)

	local promptText = Instance.new("TextLabel")
	promptText.Name = "ParryHotkeyLabel"
	promptText.Size = UDim2.new(1, 0, 1, 0)
	promptText.BackgroundTransparency = 1
	promptText.Font = UITheme.Fonts.Header
	promptText.TextColor3 = UITheme.Colors.AccentCyan
	promptText.TextSize = 22
	promptText.Text = "[F] PARRY\n(0.35s)"
	promptText.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function ParryPromptOverlay.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function ParryPromptOverlay.IsVisible(): boolean
	return isVisible
end

function ParryPromptOverlay.ShowPrompt(ballId: string, duration: number?)
	activeBallId = ballId
	activeDuration = duration or ParryPromptOverlay.DEFAULT_DURATION_SECONDS
	promptOpenedAt = os.clock()
	ParryPromptOverlay.SetVisible(true)
	UIManager.OpenOverlay("ParryPromptOverlay")
end

function ParryPromptOverlay.HidePrompt()
	activeBallId = nil
	ParryPromptOverlay.SetVisible(false)
	UIManager.CloseOverlay("ParryPromptOverlay")
end

function ParryPromptOverlay.GetRemainingRingRatio(nowTime: number?): number
	if not isVisible or activeDuration <= 0 then
		return 0
	end
	local timestamp = nowTime or os.clock()
	local elapsed = math.max(0, timestamp - promptOpenedAt)
	return math.clamp(1 - (elapsed / activeDuration), 0, 1)
end

function ParryPromptOverlay.GetActiveBallId(): string?
	return activeBallId
end

UIManager.RegisterScreen("ParryPromptOverlay", ParryPromptOverlay)

return ParryPromptOverlay
