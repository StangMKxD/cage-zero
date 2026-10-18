--!strict
-- src/client/ui/components/CooldownRingButton.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Reusable skill/trait cooldown button for MatchHUDScreen and ParryPromptOverlay

local UITheme = require(script.Parent.Parent.UITheme)

local CooldownRingButton = {}

export type CooldownButtonHandle = {
	Button: TextButton,
	SetCooldown: (remainingSeconds: number, durationSeconds: number) -> (),
	IsOnCooldown: () -> boolean,
}

function CooldownRingButton.Create(
	parent: Instance,
	buttonId: string,
	label: string,
	hotkeyText: string,
	onActivate: (() -> ())?
): CooldownButtonHandle
	local remaining = 0
	local totalDuration = 0

	local btn = Instance.new("TextButton")
	btn.Name = "CooldownBtn_" .. buttonId
	btn.Size = UDim2.new(0, 76, 0, 76)
	btn.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	btn.Font = UITheme.Fonts.SubHeader
	btn.TextColor3 = UITheme.Colors.TextPrimary
	btn.TextSize = 13
	btn.TextWrapped = true
	btn.Text = string.format("[%s]\n%s", hotkeyText, label)
	UITheme.ApplyCornerAndStroke(btn, UITheme.CornerRadius.Pill, UITheme.Colors.AccentCyan, 2)

	local cdOverlay = Instance.new("TextLabel")
	cdOverlay.Name = "CooldownOverlay"
	cdOverlay.Size = UDim2.new(1, 0, 1, 0)
	cdOverlay.BackgroundColor3 = UITheme.Colors.BackgroundPrimary
	cdOverlay.BackgroundTransparency = 0.35
	cdOverlay.Font = UITheme.Fonts.Mono
	cdOverlay.TextColor3 = UITheme.Colors.AccentGold
	cdOverlay.TextSize = 18
	cdOverlay.Text = ""
	cdOverlay.Visible = false
	UITheme.ApplyCornerAndStroke(cdOverlay, UITheme.CornerRadius.Pill, UITheme.Colors.AccentGold, 1.5)
	cdOverlay.Parent = btn

	btn.Activated:Connect(function()
		if remaining <= 0 and onActivate then
			onActivate()
		end
	end)

	btn.Parent = parent

	return {
		Button = btn,
		SetCooldown = function(remainingSeconds: number, durationSeconds: number)
			remaining = math.max(0, remainingSeconds)
			totalDuration = math.max(0, durationSeconds)
			if remaining > 0 then
				cdOverlay.Visible = true
				cdOverlay.Text = string.format("%.1fs", remaining)
			else
				cdOverlay.Visible = false
				cdOverlay.Text = ""
			end
		end,
		IsOnCooldown = function(): boolean
			return remaining > 0 and totalDuration > 0
		end,
	}
end

return CooldownRingButton
