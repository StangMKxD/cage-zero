--!strict
-- src/client/ui/components/NavigationDock.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Bottom 5-button navigation dock in LOBBY_MODE (Play, Locker, Summon, Trade, Training)

local UITheme = require(script.Parent.Parent.UITheme)

local NavigationDock = {}

export type NavTabId = "ModeSelectScreen" | "LockerScreen" | "SummonGachaScreen" | "TradingPlazaScreen" | "TrainingMode"

local NAV_BUTTONS: { { id: NavTabId, label: string } } = {
	{ id = "ModeSelectScreen", label = "PLAY MATCH" },
	{ id = "LockerScreen", label = "LOCKER" },
	{ id = "SummonGachaScreen", label = "SUMMON" },
	{ id = "TradingPlazaScreen", label = "TRADE PLAZA" },
	{ id = "TrainingMode", label = "TRAINING" },
}

local isVisible = false
local activeTab: NavTabId = "ModeSelectScreen"
local rootFrame: Frame? = nil
local onNavigateCallback: ((NavTabId) -> ())? = nil

function NavigationDock.SetNavigationHandler(callback: (NavTabId) -> ())
	onNavigateCallback = callback
end

function NavigationDock.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "NavigationDock"
	frame.Size = UDim2.new(0, 720, 0, 60)
	frame.Position = UDim2.new(0.5, -360, 1, -76)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentCyan, 1.5)

	for index, item in ipairs(NAV_BUTTONS) do
		local btn = Instance.new("TextButton")
		btn.Name = "Nav_" .. item.id
		btn.Size = UDim2.new(0.2, -12, 1, -12)
		btn.Position = UDim2.new((index - 1) * 0.2, 6, 0, 6)
		btn.BackgroundColor3 = if item.id == activeTab then UITheme.Colors.AccentCyan else UITheme.Colors.BackgroundElevated
		btn.Font = UITheme.Fonts.SubHeader
		btn.TextColor3 = if item.id == activeTab then UITheme.Colors.BackgroundPrimary else UITheme.Colors.TextPrimary
		btn.TextSize = 14
		btn.Text = item.label
		UITheme.ApplyCornerAndStroke(btn, UITheme.CornerRadius.Small, UITheme.Colors.AccentCyan, 1)

		btn.Activated:Connect(function()
			NavigationDock.SelectTab(item.id)
		end)

		btn.Parent = frame
	end

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function NavigationDock.SelectTab(tabId: NavTabId)
	activeTab = tabId
	if onNavigateCallback then
		onNavigateCallback(tabId)
	end
end

function NavigationDock.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function NavigationDock.IsVisible(): boolean
	return isVisible
end

function NavigationDock.GetActiveTab(): NavTabId
	return activeTab
end

return NavigationDock
