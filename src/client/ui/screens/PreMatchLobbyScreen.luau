--!strict
-- src/client/ui/screens/PreMatchLobbyScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Pre-Match Position Select (Forward, Midfielder, Defender) with Choice Deck Preview & READY button

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Types = require(Shared:WaitForChild("Types"))
local ChoiceConfigs = require(Shared:WaitForChild("configs"):WaitForChild("ChoiceConfigs"))

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local PreMatchLobbyScreen = {}

local isVisible = false
local selectedRole: Types.PlayerRole = "Forward"
local isReady = false
local rootFrame: Frame? = nil
local roleLabel: TextLabel? = nil

function PreMatchLobbyScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "PreMatchLobbyScreen"
	frame.Size = UDim2.new(1, -80, 1, -180)
	frame.Position = UDim2.new(0, 40, 0, 84)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentCyan, 1.5)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 44)
	header.Position = UDim2.new(0, 16, 0, 16)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.TextPrimary
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "PRE-MATCH TACTICAL POSITION SELECT"
	header.Parent = frame

	local roles: { Types.PlayerRole } = { "Forward", "Midfielder", "Defender" }
	for idx, role in ipairs(roles) do
		local roleBtn = Instance.new("TextButton")
		roleBtn.Name = "RoleBtn_" .. role
		roleBtn.Size = UDim2.new(0.28, 0, 0, 56)
		roleBtn.Position = UDim2.new((idx - 1) * 0.3 + 0.04, 0, 0, 76)
		roleBtn.BackgroundColor3 = UITheme.Colors.BackgroundElevated
		roleBtn.Font = UITheme.Fonts.SubHeader
		roleBtn.TextColor3 = UITheme.Colors.AccentCyan
		roleBtn.TextSize = 18
		roleBtn.Text = string.upper(role)
		UITheme.ApplyCornerAndStroke(roleBtn, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 1.5)

		roleBtn.Activated:Connect(function()
			PreMatchLobbyScreen.SelectRole(role)
		end)
		roleBtn.Parent = frame
	end

	local previewLbl = Instance.new("TextLabel")
	previewLbl.Name = "ChoicePreviewLabel"
	previewLbl.Size = UDim2.new(0.9, 0, 0, 100)
	previewLbl.Position = UDim2.new(0.05, 0, 0, 152)
	previewLbl.BackgroundColor3 = UITheme.Colors.BackgroundPrimary
	previewLbl.Font = UITheme.Fonts.Body
	previewLbl.TextColor3 = UITheme.Colors.TextPrimary
	previewLbl.TextSize = 15
	previewLbl.TextWrapped = true
	previewLbl.Text = "ROLE: " .. selectedRole .. " | 5-Choice Tactical Deck Loaded"
	UITheme.ApplyCornerAndStroke(previewLbl, UITheme.CornerRadius.Medium, UITheme.Colors.AccentGold, 1)
	previewLbl.Parent = frame
	roleLabel = previewLbl

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyButton"
	readyBtn.Size = UDim2.new(0, 260, 0, 58)
	readyBtn.Position = UDim2.new(0.5, -130, 1, -78)
	readyBtn.BackgroundColor3 = UITheme.Colors.AccentEmerald
	readyBtn.Font = UITheme.Fonts.Header
	readyBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	readyBtn.TextSize = 22
	readyBtn.Text = "READY FOR CAGE MATCH"
	UITheme.ApplyCornerAndStroke(readyBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 2)
	readyBtn.Activated:Connect(function()
		PreMatchLobbyScreen.ClickReady()
	end)
	readyBtn.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function PreMatchLobbyScreen.SetVisible(visible: boolean)
	isVisible = visible
	if not visible then
		isReady = false
	end
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function PreMatchLobbyScreen.IsVisible(): boolean
	return isVisible
end

function PreMatchLobbyScreen.SelectRole(role: Types.PlayerRole): { Types.ChoiceAction }
	selectedRole = role
	local choices = ChoiceConfigs.GetChoicesForRole(role)
	if roleLabel then
		roleLabel.Text = string.format("ROLE: %s | Choices: %s", role, table.concat(choices, ", "))
	end
	return choices
end

function PreMatchLobbyScreen.GetSelectedRole(): Types.PlayerRole
	return selectedRole
end

function PreMatchLobbyScreen.ClickReady()
	isReady = true
	UIManager.SetMode("MATCH_MODE")
end

function PreMatchLobbyScreen.IsReady(): boolean
	return isReady
end

UIManager.RegisterScreen("PreMatchLobbyScreen", PreMatchLobbyScreen)

return PreMatchLobbyScreen
