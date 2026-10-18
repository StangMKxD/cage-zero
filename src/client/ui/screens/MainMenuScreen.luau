--!strict
-- src/client/ui/screens/MainMenuScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Main Menu screen with Game Logo, Custom Rig Signature Pose preview, PLAY and SETTINGS buttons

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local MainMenuScreen = {}

local isVisible = true
local isSettingsOpen = false
local previewCardId = "Card_KaiserImpact"
local rootFrame: Frame? = nil

function MainMenuScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "MainMenuScreen"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundPrimary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible

	local title = Instance.new("TextLabel")
	title.Name = "GameLogo"
	title.Size = UDim2.new(0, 600, 0, 80)
	title.Position = UDim2.new(0.5, -300, 0.18, 0)
	title.BackgroundTransparency = 1
	title.Font = UITheme.Fonts.Header
	title.TextColor3 = UITheme.Colors.AccentCyan
	title.TextSize = 48
	title.Text = "CAGE: ZERO (360 HEX-CAGE)"
	title.Parent = frame

	local poseBanner = Instance.new("TextLabel")
	poseBanner.Name = "RigPosePreviewLabel"
	poseBanner.Size = UDim2.new(0, 440, 0, 36)
	poseBanner.Position = UDim2.new(0.5, -220, 0.32, 0)
	poseBanner.BackgroundTransparency = 1
	poseBanner.Font = UITheme.Fonts.Body
	poseBanner.TextColor3 = UITheme.Colors.TextSecondary
	poseBanner.TextSize = 16
	poseBanner.Text = "Custom Rig 1.15x Showcase: " .. previewCardId
	poseBanner.Parent = frame

	local playBtn = Instance.new("TextButton")
	playBtn.Name = "PlayButton"
	playBtn.Size = UDim2.new(0, 260, 0, 64)
	playBtn.Position = UDim2.new(0.5, -130, 0.55, 0)
	playBtn.BackgroundColor3 = UITheme.Colors.AccentCyan
	playBtn.Font = UITheme.Fonts.Header
	playBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	playBtn.TextSize = 24
	playBtn.Text = "PLAY"
	UITheme.ApplyCornerAndStroke(playBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 2)
	playBtn.Activated:Connect(function()
		MainMenuScreen.ClickPlay()
	end)
	playBtn.Parent = frame

	local settingsBtn = Instance.new("TextButton")
	settingsBtn.Name = "SettingsButton"
	settingsBtn.Size = UDim2.new(0, 260, 0, 50)
	settingsBtn.Position = UDim2.new(0.5, -130, 0.68, 0)
	settingsBtn.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	settingsBtn.Font = UITheme.Fonts.SubHeader
	settingsBtn.TextColor3 = UITheme.Colors.TextPrimary
	settingsBtn.TextSize = 18
	settingsBtn.Text = "SETTINGS"
	UITheme.ApplyCornerAndStroke(settingsBtn, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 1.5)
	settingsBtn.Activated:Connect(function()
		MainMenuScreen.ToggleSettings()
	end)
	settingsBtn.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function MainMenuScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function MainMenuScreen.IsVisible(): boolean
	return isVisible
end

function MainMenuScreen.ClickPlay()
	isSettingsOpen = false
	UIManager.SetMode("LOBBY_MODE")
end

function MainMenuScreen.ToggleSettings(): boolean
	isSettingsOpen = not isSettingsOpen
	return isSettingsOpen
end

UIManager.RegisterScreen("MainMenuScreen", MainMenuScreen)

return MainMenuScreen
