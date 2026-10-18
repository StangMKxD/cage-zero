--!strict
-- src/client/ui/UITheme.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Cyber-Underground Cage Football Theme Tokens & Instance Helpers

local UITheme = {}

UITheme.Colors = {
	BackgroundPrimary = Color3.fromRGB(12, 14, 20),
	BackgroundSecondary = Color3.fromRGB(20, 24, 34),
	BackgroundElevated = Color3.fromRGB(30, 36, 52),
	AccentCyan = Color3.fromRGB(0, 225, 255),
	AccentGold = Color3.fromRGB(255, 195, 35),
	AccentCrimson = Color3.fromRGB(255, 55, 75),
	AccentEmerald = Color3.fromRGB(45, 230, 130),
	AccentPurple = Color3.fromRGB(185, 90, 255),
	TextPrimary = Color3.fromRGB(245, 248, 255),
	TextSecondary = Color3.fromRGB(165, 175, 195),
	TextMuted = Color3.fromRGB(100, 110, 130),
	LockedOverlay = Color3.fromRGB(40, 15, 20),
	DangerRed = Color3.fromRGB(255, 40, 40),
}

UITheme.Fonts = {
	Header = Enum.Font.GothamBlack,
	SubHeader = Enum.Font.GothamBold,
	Body = Enum.Font.GothamMedium,
	Mono = Enum.Font.Code,
}

UITheme.CornerRadius = {
	Small = UDim.new(0, 6),
	Medium = UDim.new(0, 10),
	Large = UDim.new(0, 16),
	Pill = UDim.new(1, 0),
}

UITheme.RarityColors = {
	Common = Color3.fromRGB(170, 180, 195),
	Rare = Color3.fromRGB(45, 160, 255),
	Epic = Color3.fromRGB(185, 85, 255),
	Mutated = Color3.fromRGB(255, 195, 35),
	S = Color3.fromRGB(255, 195, 35),
	A = Color3.fromRGB(185, 85, 255),
	B = Color3.fromRGB(45, 160, 255),
}

function UITheme.GetRarityColor(rarityOrTier: string): Color3
	return (UITheme.RarityColors :: { [string]: Color3 })[rarityOrTier] or UITheme.Colors.AccentCyan
end

function UITheme.ApplyCornerAndStroke(frame: GuiObject, radius: UDim, strokeColor: Color3, thickness: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = thickness or 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
end

return UITheme
