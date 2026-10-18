--!strict
-- src/client/ui/screens/SummonGachaScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Gacha Summon UI (Tier S: 0.5%, Tier A: 9.5%, Tier B: 90%, Pity 0/100, Summon x1 & x10)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local SummonGachaScreen = {}

export type BannerType = "SummonCard" | "SummonThread"

SummonGachaScreen.DISPLAY_RATES = {
	TierS = "0.5%",
	TierA = "9.5%",
	TierB = "90.0%",
	PityCap = 100,
}

local isVisible = false
local activeBanner: BannerType = "SummonCard"
local pityCounter = 0
local rootFrame: Frame? = nil
local pityLabel: TextLabel? = nil

function SummonGachaScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "SummonGachaScreen"
	frame.Size = UDim2.new(1, -80, 1, -180)
	frame.Position = UDim2.new(0, 40, 0, 84)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentGold, 1.5)

	local header = Instance.new("TextLabel")
	header.Name = "BannerHeader"
	header.Size = UDim2.new(1, -32, 0, 48)
	header.Position = UDim2.new(0, 16, 0, 16)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.AccentGold
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "CAGE SUMMON BANNER (Tier S: 0.5% | Tier A: 9.5% | Tier B: 90%)"
	header.Parent = frame

	local pityTxt = Instance.new("TextLabel")
	pityTxt.Name = "PityCounterLabel"
	pityTxt.Size = UDim2.new(0, 260, 0, 36)
	pityTxt.Position = UDim2.new(0, 16, 0, 72)
	pityTxt.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	pityTxt.Font = UITheme.Fonts.Mono
	pityTxt.TextColor3 = UITheme.Colors.AccentCyan
	pityTxt.TextSize = 16
	pityTxt.Text = string.format("PITY COUNTER: %d / 100", pityCounter)
	UITheme.ApplyCornerAndStroke(pityTxt, UITheme.CornerRadius.Small, UITheme.Colors.AccentCyan, 1)
	pityTxt.Parent = frame
	pityLabel = pityTxt

	local x1Btn = Instance.new("TextButton")
	x1Btn.Name = "SummonX1Button"
	x1Btn.Size = UDim2.new(0, 220, 0, 56)
	x1Btn.Position = UDim2.new(0.5, -240, 1, -84)
	x1Btn.BackgroundColor3 = UITheme.Colors.AccentCyan
	x1Btn.Font = UITheme.Fonts.Header
	x1Btn.TextColor3 = UITheme.Colors.BackgroundPrimary
	x1Btn.TextSize = 20
	x1Btn.Text = "SUMMON x1"
	UITheme.ApplyCornerAndStroke(x1Btn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	x1Btn.Activated:Connect(function()
		SummonGachaScreen.RequestSummon(activeBanner, 1)
	end)
	x1Btn.Parent = frame

	local x10Btn = Instance.new("TextButton")
	x10Btn.Name = "SummonX10Button"
	x10Btn.Size = UDim2.new(0, 220, 0, 56)
	x10Btn.Position = UDim2.new(0.5, 20, 1, -84)
	x10Btn.BackgroundColor3 = UITheme.Colors.AccentGold
	x10Btn.Font = UITheme.Fonts.Header
	x10Btn.TextColor3 = UITheme.Colors.BackgroundPrimary
	x10Btn.TextSize = 20
	x10Btn.Text = "SUMMON x10"
	UITheme.ApplyCornerAndStroke(x10Btn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	x10Btn.Activated:Connect(function()
		SummonGachaScreen.RequestSummon(activeBanner, 10)
	end)
	x10Btn.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function SummonGachaScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function SummonGachaScreen.IsVisible(): boolean
	return isVisible
end

function SummonGachaScreen.SelectBanner(banner: BannerType)
	activeBanner = banner
end

function SummonGachaScreen.SetPityCounter(newPity: number)
	pityCounter = math.clamp(math.floor(newPity), 0, 100)
	if pityLabel then
		pityLabel.Text = string.format("PITY COUNTER: %d / 100", pityCounter)
	end
end

function SummonGachaScreen.GetPityCounter(): number
	return pityCounter
end

function SummonGachaScreen.RequestSummon(banner: BannerType, pullCount: number): boolean
	if pullCount ~= 1 and pullCount ~= 10 then
		return false
	end
	local remote = Network.GetRemoteEvent(Network.Events.GachaSummonRequest)
	remote:FireServer(banner, pullCount)
	return true
end

UIManager.RegisterScreen("SummonGachaScreen", SummonGachaScreen)

return SummonGachaScreen
