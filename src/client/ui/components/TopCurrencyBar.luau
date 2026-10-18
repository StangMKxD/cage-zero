--!strict
-- src/client/ui/components/TopCurrencyBar.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Top HUD bar in LOBBY_MODE displaying Cash, Level, EXP, and Mutated Gear Bonus

local UITheme = require(script.Parent.Parent.UITheme)

local TopCurrencyBar = {}

export type CurrencyBarState = {
	visible: boolean,
	cash: number,
	level: number,
	exp: number,
	cashBonusPct: number,
	expBonusPct: number,
}

local currentState: CurrencyBarState = {
	visible = false,
	cash = 0,
	level = 1,
	exp = 0,
	cashBonusPct = 0,
	expBonusPct = 0,
}

local rootFrame: Frame? = nil
local cashLabel: TextLabel? = nil
local levelLabel: TextLabel? = nil
local bonusLabel: TextLabel? = nil

function TopCurrencyBar.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "TopCurrencyBar"
	frame.Size = UDim2.new(1, -40, 0, 52)
	frame.Position = UDim2.new(0, 20, 0, 12)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = currentState.visible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Medium, UITheme.Colors.AccentCyan, 1.5)

	local cashTxt = Instance.new("TextLabel")
	cashTxt.Name = "CashLabel"
	cashTxt.Size = UDim2.new(0.33, 0, 1, 0)
	cashTxt.Position = UDim2.new(0, 16, 0, 0)
	cashTxt.BackgroundTransparency = 1
	cashTxt.Font = UITheme.Fonts.SubHeader
	cashTxt.TextColor3 = UITheme.Colors.AccentGold
	cashTxt.TextSize = 18
	cashTxt.TextXAlignment = Enum.TextXAlignment.Left
	cashTxt.Text = string.format("CASH: $%d", currentState.cash)
	cashTxt.Parent = frame

	local lvlTxt = Instance.new("TextLabel")
	lvlTxt.Name = "LevelLabel"
	lvlTxt.Size = UDim2.new(0.33, 0, 1, 0)
	lvlTxt.Position = UDim2.new(0.33, 0, 0, 0)
	lvlTxt.BackgroundTransparency = 1
	lvlTxt.Font = UITheme.Fonts.SubHeader
	lvlTxt.TextColor3 = UITheme.Colors.TextPrimary
	lvlTxt.TextSize = 18
	lvlTxt.Text = string.format("LVL %d (%d EXP)", currentState.level, currentState.exp)
	lvlTxt.Parent = frame

	local mutTxt = Instance.new("TextLabel")
	mutTxt.Name = "MutatedBonusLabel"
	mutTxt.Size = UDim2.new(0.33, -16, 1, 0)
	mutTxt.Position = UDim2.new(0.66, 0, 0, 0)
	mutTxt.BackgroundTransparency = 1
	mutTxt.Font = UITheme.Fonts.Body
	mutTxt.TextColor3 = UITheme.Colors.AccentEmerald
	mutTxt.TextSize = 15
	mutTxt.TextXAlignment = Enum.TextXAlignment.Right
	mutTxt.Text = string.format("MUTATED BONUS: +%d%% CASH / +%d%% EXP", currentState.cashBonusPct, currentState.expBonusPct)
	mutTxt.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	cashLabel = cashTxt
	levelLabel = lvlTxt
	bonusLabel = mutTxt
	return frame
end

function TopCurrencyBar.SetVisible(visible: boolean)
	currentState.visible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function TopCurrencyBar.UpdateCurrency(cash: number, level: number, exp: number, cashBonusMultiplier: number?, expBonusMultiplier: number?)
	currentState.cash = math.max(0, math.floor(cash))
	currentState.level = math.max(1, math.floor(level))
	currentState.exp = math.max(0, math.floor(exp))
	currentState.cashBonusPct = math.floor(((cashBonusMultiplier or 0) * 100) + 0.5)
	currentState.expBonusPct = math.floor(((expBonusMultiplier or 0) * 100) + 0.5)

	if cashLabel then
		cashLabel.Text = string.format("CASH: $%d", currentState.cash)
	end
	if levelLabel then
		levelLabel.Text = string.format("LVL %d (%d EXP)", currentState.level, currentState.exp)
	end
	if bonusLabel then
		bonusLabel.Text = string.format("MUTATED BONUS: +%d%% CASH / +%d%% EXP", currentState.cashBonusPct, currentState.expBonusPct)
	end
end

function TopCurrencyBar.GetState(): CurrencyBarState
	return table.clone(currentState)
end

return TopCurrencyBar
