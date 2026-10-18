--!strict
-- src/client/ui/screens/MatchHUDScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Primary HUD in MATCH_MODE: Scoreboard, Countdown Timer, Dynamic Event Alert Banner, Stamina Bar (<15% Red Blink), Buff/Mistake Indicator, Skill & Trait Dock

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local MatchHUDScreen = {}

MatchHUDScreen.LOW_STAMINA_BLINK_THRESHOLD = 15

export type MatchHUDState = {
	visible: boolean,
	teamAScore: number,
	teamBScore: number,
	remainingSeconds: number,
	staminaPct: number,
	isStaminaBlinkingRed: boolean,
	eventBannerText: string,
	activeStatusBadge: string,
}

local state: MatchHUDState = {
	visible = false,
	teamAScore = 0,
	teamBScore = 0,
	remainingSeconds = 300,
	staminaPct = 100,
	isStaminaBlinkingRed = false,
	eventBannerText = "",
	activeStatusBadge = "READY",
}

local rootFrame: Frame? = nil
local scoreLabel: TextLabel? = nil
local eventBannerLabel: TextLabel? = nil
local staminaFillFrame: Frame? = nil
local statusBadgeLabel: TextLabel? = nil

function MatchHUDScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "MatchHUDScreen"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = state.visible

	local scoreboard = Instance.new("TextLabel")
	scoreboard.Name = "ScoreboardBanner"
	scoreboard.Size = UDim2.new(0, 360, 0, 54)
	scoreboard.Position = UDim2.new(0.5, -180, 0, 14)
	scoreboard.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	scoreboard.Font = UITheme.Fonts.Header
	scoreboard.TextColor3 = UITheme.Colors.TextPrimary
	scoreboard.TextSize = 22
	scoreboard.Text = "TEAM A 0 - 0 TEAM B | 05:00"
	UITheme.ApplyCornerAndStroke(scoreboard, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 2)
	scoreboard.Parent = frame
	scoreLabel = scoreboard

	local alertBanner = Instance.new("TextLabel")
	alertBanner.Name = "EventAlertBanner"
	alertBanner.Size = UDim2.new(0, 520, 0, 42)
	alertBanner.Position = UDim2.new(0.5, -260, 0, 76)
	alertBanner.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	alertBanner.Font = UITheme.Fonts.SubHeader
	alertBanner.TextColor3 = UITheme.Colors.AccentGold
	alertBanner.TextSize = 17
	alertBanner.Text = ""
	alertBanner.Visible = false
	UITheme.ApplyCornerAndStroke(alertBanner, UITheme.CornerRadius.Small, UITheme.Colors.AccentGold, 1.5)
	alertBanner.Parent = frame
	eventBannerLabel = alertBanner

	local staminaBg = Instance.new("Frame")
	staminaBg.Name = "StaminaBarContainer"
	staminaBg.Size = UDim2.new(0, 320, 0, 22)
	staminaBg.Position = UDim2.new(0.5, -160, 1, -48)
	staminaBg.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	UITheme.ApplyCornerAndStroke(staminaBg, UITheme.CornerRadius.Pill, UITheme.Colors.TextSecondary, 1.5)
	staminaBg.Parent = frame

	local staminaFill = Instance.new("Frame")
	staminaFill.Name = "StaminaFill"
	staminaFill.Size = UDim2.new(1, 0, 1, 0)
	staminaFill.BackgroundColor3 = UITheme.Colors.AccentEmerald
	staminaFill.BorderSizePixel = 0
	staminaFill.Parent = staminaBg
	staminaFillFrame = staminaFill

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name = "BuffOrMistakeBadge"
	statusLbl.Size = UDim2.new(0, 240, 0, 32)
	statusLbl.Position = UDim2.new(0.5, -120, 1, -88)
	statusLbl.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	statusLbl.Font = UITheme.Fonts.SubHeader
	statusLbl.TextColor3 = UITheme.Colors.AccentCyan
	statusLbl.TextSize = 14
	statusLbl.Text = state.activeStatusBadge
	UITheme.ApplyCornerAndStroke(statusLbl, UITheme.CornerRadius.Small, UITheme.Colors.AccentCyan, 1)
	statusLbl.Parent = frame
	statusBadgeLabel = statusLbl

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function MatchHUDScreen.SetVisible(visible: boolean)
	state.visible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function MatchHUDScreen.IsVisible(): boolean
	return state.visible
end

function MatchHUDScreen.UpdateScoreAndTimer(teamAScore: number, teamBScore: number, remainingSeconds: number)
	state.teamAScore = math.max(0, math.floor(teamAScore))
	state.teamBScore = math.max(0, math.floor(teamBScore))
	state.remainingSeconds = math.max(0, math.floor(remainingSeconds))

	local mins = math.floor(state.remainingSeconds / 60)
	local secs = state.remainingSeconds % 60
	if scoreLabel then
		scoreLabel.Text = string.format("TEAM A %d - %d TEAM B | %02d:%02d", state.teamAScore, state.teamBScore, mins, secs)
	end
end

function MatchHUDScreen.UpdateStamina(staminaPct: number)
	local clamped = math.clamp(staminaPct, 0, 100)
	state.staminaPct = clamped
	state.isStaminaBlinkingRed = clamped < MatchHUDScreen.LOW_STAMINA_BLINK_THRESHOLD

	if staminaFillFrame then
		staminaFillFrame.Size = UDim2.new(clamped / 100, 0, 1, 0)
		staminaFillFrame.BackgroundColor3 = if state.isStaminaBlinkingRed
			then UITheme.Colors.DangerRed
			else UITheme.Colors.AccentEmerald
	end
end

function MatchHUDScreen.ShowEventAlertBanner(bannerText: string)
	state.eventBannerText = bannerText
	if eventBannerLabel then
		eventBannerLabel.Text = bannerText
		eventBannerLabel.Visible = bannerText ~= ""
	end
end

function MatchHUDScreen.SetStatusBadge(statusText: string)
	state.activeStatusBadge = statusText
	if statusBadgeLabel then
		statusBadgeLabel.Text = statusText
	end
end

function MatchHUDScreen.GetState(): MatchHUDState
	return table.clone(state)
end

UIManager.RegisterScreen("MatchHUDScreen", MatchHUDScreen)

return MatchHUDScreen
