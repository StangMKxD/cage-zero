--!strict
-- src/client/ui/screens/PostMatchSummaryScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Post-Match Summary Screen: MVP Celebration, Scoreboard, Reward Breakdown (Base + Mutated Bonus), Play Again & Return to Lobby

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local PostMatchSummaryScreen = {}

export type PostMatchSummaryData = {
	mvpPlayerName: string,
	mvpCelebrationId: string,
	teamAScore: number,
	teamBScore: number,
	baseCash: number,
	bonusCash: number,
	totalCash: number,
	baseExp: number,
	bonusExp: number,
	totalExp: number,
}

local isVisible = false
local currentSummary: PostMatchSummaryData = {
	mvpPlayerName = "Player1",
	mvpCelebrationId = "Celebration_KneeSlide",
	teamAScore = 0,
	teamBScore = 0,
	baseCash = 100,
	bonusCash = 0,
	totalCash = 100,
	baseExp = 150,
	bonusExp = 0,
	totalExp = 150,
}

local rootFrame: Frame? = nil
local breakdownLabel: TextLabel? = nil

function PostMatchSummaryScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "PostMatchSummaryScreen"
	frame.Size = UDim2.new(0, 760, 0, 460)
	frame.Position = UDim2.new(0.5, -380, 0.5, -230)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentGold, 2)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 48)
	header.Position = UDim2.new(0, 16, 0, 16)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.AccentGold
	header.TextSize = 26
	header.Text = "MATCH COMPLETE - MVP & REWARD BREAKDOWN"
	header.Parent = frame

	local rewardBox = Instance.new("TextLabel")
	rewardBox.Name = "RewardBreakdownLabel"
	rewardBox.Size = UDim2.new(1, -64, 0, 180)
	rewardBox.Position = UDim2.new(0, 32, 0, 96)
	rewardBox.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	rewardBox.Font = UITheme.Fonts.Mono
	rewardBox.TextColor3 = UITheme.Colors.TextPrimary
	rewardBox.TextSize = 16
	rewardBox.TextWrapped = true
	rewardBox.Text = ""
	UITheme.ApplyCornerAndStroke(rewardBox, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 1.5)
	rewardBox.Parent = frame
	breakdownLabel = rewardBox

	local playAgainBtn = Instance.new("TextButton")
	playAgainBtn.Name = "PlayAgainButton"
	playAgainBtn.Size = UDim2.new(0, 240, 0, 56)
	playAgainBtn.Position = UDim2.new(0.5, -260, 1, -80)
	playAgainBtn.BackgroundColor3 = UITheme.Colors.AccentEmerald
	playAgainBtn.Font = UITheme.Fonts.Header
	playAgainBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	playAgainBtn.TextSize = 20
	playAgainBtn.Text = "PLAY AGAIN"
	UITheme.ApplyCornerAndStroke(playAgainBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	playAgainBtn.Activated:Connect(function()
		PostMatchSummaryScreen.ClickPlayAgain()
	end)
	playAgainBtn.Parent = frame

	local returnLobbyBtn = Instance.new("TextButton")
	returnLobbyBtn.Name = "ReturnToLobbyButton"
	returnLobbyBtn.Size = UDim2.new(0, 240, 0, 56)
	returnLobbyBtn.Position = UDim2.new(0.5, 20, 1, -80)
	returnLobbyBtn.BackgroundColor3 = UITheme.Colors.AccentCyan
	returnLobbyBtn.Font = UITheme.Fonts.Header
	returnLobbyBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	returnLobbyBtn.TextSize = 20
	returnLobbyBtn.Text = "RETURN TO LOBBY"
	UITheme.ApplyCornerAndStroke(returnLobbyBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	returnLobbyBtn.Activated:Connect(function()
		PostMatchSummaryScreen.ClickReturnToLobby()
	end)
	returnLobbyBtn.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function PostMatchSummaryScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function PostMatchSummaryScreen.IsVisible(): boolean
	return isVisible
end

function PostMatchSummaryScreen.ShowSummary(summary: PostMatchSummaryData)
	currentSummary = table.clone(summary)
	if breakdownLabel then
		breakdownLabel.Text = string.format(
			"MVP: %s (%s)\nSCORE: %d - %d\nCASH: %d Base + %d Mutated Bonus = %d Total\nEXP: %d Base + %d Mutated Bonus = %d Total",
			summary.mvpPlayerName,
			summary.mvpCelebrationId,
			summary.teamAScore,
			summary.teamBScore,
			summary.baseCash,
			summary.bonusCash,
			summary.totalCash,
			summary.baseExp,
			summary.bonusExp,
			summary.totalExp
		)
	end

	PostMatchSummaryScreen.SetVisible(true)
	UIManager.OpenOverlay("PostMatchSummaryScreen")
end

function PostMatchSummaryScreen.ClickPlayAgain()
	PostMatchSummaryScreen.SetVisible(false)
	UIManager.NavigateToScreen("PreMatchLobbyScreen")
end

function PostMatchSummaryScreen.ClickReturnToLobby()
	PostMatchSummaryScreen.SetVisible(false)
	UIManager.SetMode("LOBBY_MODE")
end

function PostMatchSummaryScreen.GetSummaryData(): PostMatchSummaryData
	return table.clone(currentSummary)
end

UIManager.RegisterScreen("PostMatchSummaryScreen", PostMatchSummaryScreen)

return PostMatchSummaryScreen
