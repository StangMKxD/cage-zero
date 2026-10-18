--!strict
-- src/client/ui/components/ItemCardSlot.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Reusable item slot for Player Cards, Battle Threads, Trait Stones, and Celebrations

local UITheme = require(script.Parent.Parent.UITheme)

local ItemCardSlot = {}

export type ItemSlotProps = {
	itemId: string,
	title: string,
	subtitle: string,
	rarityOrTier: string,
	isEquipped: boolean,
	isMutated: boolean,
	traitSlotCount: number?,
	onSelect: ((string) -> ())?,
}

function ItemCardSlot.Create(parent: Instance, props: ItemSlotProps): TextButton
	local borderColor = UITheme.GetRarityColor(props.rarityOrTier)
	local button = Instance.new("TextButton")
	button.Name = "ItemSlot_" .. props.itemId
	button.Size = UDim2.new(0, 160, 0, 190)
	button.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	button.BorderSizePixel = 0
	button.Text = ""
	UITheme.ApplyCornerAndStroke(button, UITheme.CornerRadius.Medium, borderColor, if props.isEquipped then 3 else 1.5)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -16, 0, 44)
	titleLabel.Position = UDim2.new(0, 8, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UITheme.Fonts.SubHeader
	titleLabel.TextColor3 = UITheme.Colors.TextPrimary
	titleLabel.TextSize = 15
	titleLabel.TextWrapped = true
	titleLabel.Text = props.title
	titleLabel.Parent = button

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Subtitle"
	subLabel.Size = UDim2.new(1, -16, 0, 36)
	subLabel.Position = UDim2.new(0, 8, 0, 58)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = UITheme.Fonts.Body
	subLabel.TextColor3 = borderColor
	subLabel.TextSize = 13
	subLabel.TextWrapped = true
	subLabel.Text = props.subtitle
	subLabel.Parent = button

	if props.isMutated then
		local mutatedBadge = Instance.new("TextLabel")
		mutatedBadge.Name = "MutatedBadge"
		mutatedBadge.Size = UDim2.new(1, -16, 0, 24)
		mutatedBadge.Position = UDim2.new(0, 8, 0, 102)
		mutatedBadge.BackgroundColor3 = UITheme.Colors.AccentGold
		mutatedBadge.Font = UITheme.Fonts.SubHeader
		mutatedBadge.TextColor3 = UITheme.Colors.BackgroundPrimary
		mutatedBadge.TextSize = 12
		mutatedBadge.Text = "MUTATED (+CASH/EXP)"
		UITheme.ApplyCornerAndStroke(mutatedBadge, UITheme.CornerRadius.Small, UITheme.Colors.AccentGold, 1)
		mutatedBadge.Parent = button
	end

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusBadge"
	statusLabel.Size = UDim2.new(1, -16, 0, 28)
	statusLabel.Position = UDim2.new(0, 8, 1, -36)
	statusLabel.BackgroundColor3 = if props.isEquipped then UITheme.Colors.AccentEmerald else UITheme.Colors.BackgroundSecondary
	statusLabel.Font = UITheme.Fonts.SubHeader
	statusLabel.TextColor3 = if props.isEquipped then UITheme.Colors.BackgroundPrimary else UITheme.Colors.TextSecondary
	statusLabel.TextSize = 13
	statusLabel.Text = if props.isEquipped then "EQUIPPED" else "EQUIP"
	UITheme.ApplyCornerAndStroke(statusLabel, UITheme.CornerRadius.Small, borderColor, 1)
	statusLabel.Parent = button

	button.Activated:Connect(function()
		if props.onSelect then
			props.onSelect(props.itemId)
		end
	end)

	button.Parent = parent
	return button
end

return ItemCardSlot
