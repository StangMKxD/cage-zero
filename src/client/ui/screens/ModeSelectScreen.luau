--!strict
-- src/client/ui/screens/ModeSelectScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Mode selection screen in LOBBY_MODE (3v3 Hex-Cage, 4v4 Pro, 1v1v1 King of Cage)

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local ModeSelectScreen = {}

export type CageGameMode = "3v3_HEX_CAGE" | "4v4_PRO" | "1v1v1_KING_OF_CAGE"

local GAME_MODES: { { id: CageGameMode, title: string, desc: string } } = {
	{
		id = "3v3_HEX_CAGE",
		title = "3v3 HEX-CAGE",
		desc = "Standard 3v3 No-Out-Of-Bounds Cage Match with 90s Dynamic Events",
	},
	{
		id = "4v4_PRO",
		title = "4v4 PRO LEAGUE",
		desc = "Competitive 4v4 Tactical Cage Match with Full Position Choices",
	},
	{
		id = "1v1v1_KING_OF_CAGE",
		title = "1v1v1 KING OF CAGE",
		desc = "Three-Way Sudden-Duel Cage Showdown",
	},
}

local isVisible = false
local selectedMode: CageGameMode = "3v3_HEX_CAGE"
local rootFrame: Frame? = nil

function ModeSelectScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "ModeSelectScreen"
	frame.Size = UDim2.new(1, -80, 1, -180)
	frame.Position = UDim2.new(0, 40, 0, 84)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentCyan, 1.5)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 48)
	header.Position = UDim2.new(0, 16, 0, 16)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.TextPrimary
	header.TextSize = 26
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "SELECT CAGE MODE"
	header.Parent = frame

	for idx, modeInfo in ipairs(GAME_MODES) do
		local card = Instance.new("TextButton")
		card.Name = "ModeCard_" .. modeInfo.id
		card.Size = UDim2.new(0.3, -16, 0, 260)
		card.Position = UDim2.new((idx - 1) * 0.33 + 0.02, 0, 0, 90)
		card.BackgroundColor3 = UITheme.Colors.BackgroundElevated
		card.Font = UITheme.Fonts.SubHeader
		card.TextColor3 = UITheme.Colors.TextPrimary
		card.TextSize = 20
		card.TextWrapped = true
		card.Text = modeInfo.title .. "\n\n" .. modeInfo.desc
		UITheme.ApplyCornerAndStroke(card, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 2)

		card.Activated:Connect(function()
			ModeSelectScreen.SelectMode(modeInfo.id)
		end)
		card.Parent = frame
	end

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function ModeSelectScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function ModeSelectScreen.IsVisible(): boolean
	return isVisible
end

function ModeSelectScreen.SelectMode(modeId: CageGameMode)
	selectedMode = modeId
	UIManager.NavigateToScreen("PreMatchLobbyScreen")
end

function ModeSelectScreen.GetSelectedMode(): CageGameMode
	return selectedMode
end

UIManager.RegisterScreen("ModeSelectScreen", ModeSelectScreen)

return ModeSelectScreen
