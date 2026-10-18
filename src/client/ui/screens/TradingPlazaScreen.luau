--!strict
-- src/client/ui/screens/TradingPlazaScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Market Booth UI (6 Slots) and 2-Step P2P Trade Window (1. Lock Offer -> 3s Countdown -> 2. Confirm Trade)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)
local ToastNotification = require(script.Parent.Parent.components.ToastNotification)

local TradingPlazaScreen = {}

TradingPlazaScreen.MAX_BOOTH_SLOTS = 6
TradingPlazaScreen.LOCK_COUNTDOWN_SECONDS = 3.0

local isVisible = false
local rootFrame: Frame? = nil
local currentTradeSessionId: string? = nil
local offerLockedAt: number? = nil
local isOfferLocked = false
local isTradeConfirmed = false

function TradingPlazaScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "TradingPlazaScreen"
	frame.Size = UDim2.new(1, -80, 1, -180)
	frame.Position = UDim2.new(0, 40, 0, 84)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentPurple, 1.5)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 44)
	header.Position = UDim2.new(0, 16, 0, 14)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.TextPrimary
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "TRADING PLAZA: 6-SLOT MARKET BOOTH & 2-STEP P2P TRADE"
	header.Parent = frame

	local lockBtn = Instance.new("TextButton")
	lockBtn.Name = "LockOfferButton"
	lockBtn.Size = UDim2.new(0, 220, 0, 50)
	lockBtn.Position = UDim2.new(0.5, -230, 1, -72)
	lockBtn.BackgroundColor3 = UITheme.Colors.AccentGold
	lockBtn.Font = UITheme.Fonts.SubHeader
	lockBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	lockBtn.TextSize = 16
	lockBtn.Text = "1. LOCK OFFER"
	UITheme.ApplyCornerAndStroke(lockBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	lockBtn.Activated:Connect(function()
		if currentTradeSessionId then
			TradingPlazaScreen.ClickLockOffer(currentTradeSessionId, os.clock())
		end
	end)
	lockBtn.Parent = frame

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmTradeButton"
	confirmBtn.Size = UDim2.new(0, 220, 0, 50)
	confirmBtn.Position = UDim2.new(0.5, 10, 1, -72)
	confirmBtn.BackgroundColor3 = UITheme.Colors.AccentEmerald
	confirmBtn.Font = UITheme.Fonts.SubHeader
	confirmBtn.TextColor3 = UITheme.Colors.BackgroundPrimary
	confirmBtn.TextSize = 16
	confirmBtn.Text = "2. CONFIRM TRADE (3s)"
	UITheme.ApplyCornerAndStroke(confirmBtn, UITheme.CornerRadius.Medium, UITheme.Colors.TextPrimary, 1.5)
	confirmBtn.Activated:Connect(function()
		if currentTradeSessionId then
			TradingPlazaScreen.ClickConfirmTrade(currentTradeSessionId, os.clock())
		end
	end)
	confirmBtn.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function TradingPlazaScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function TradingPlazaScreen.IsVisible(): boolean
	return isVisible
end

function TradingPlazaScreen.ListBoothItem(slotIndex: number, itemCategory: "Card" | "Thread" | "Trait", itemId: string, priceCash: number): boolean
	if slotIndex < 1 or slotIndex > TradingPlazaScreen.MAX_BOOTH_SLOTS then
		return false
	end
	if priceCash <= 0 then
		return false
	end
	local remote = Network.GetRemoteEvent(Network.Events.BoothListingAction)
	remote:FireServer("LIST", {
		slotIndex = slotIndex,
		itemCategory = itemCategory,
		itemId = itemId,
		priceCash = priceCash,
	})
	return true
end

function TradingPlazaScreen.OpenTradeSession(sessionId: string)
	currentTradeSessionId = sessionId
	offerLockedAt = nil
	isOfferLocked = false
	isTradeConfirmed = false
end

function TradingPlazaScreen.ClickLockOffer(sessionId: string, nowTime: number?): boolean
	local timestamp = nowTime or os.clock()
	currentTradeSessionId = sessionId
	isOfferLocked = true
	isTradeConfirmed = false
	offerLockedAt = timestamp

	local remote = Network.GetRemoteEvent(Network.Events.TradeSessionAction)
	remote:FireServer("LOCK_OFFER", { sessionId = sessionId })
	ToastNotification.Show("Offer Locked! Wait 3.0s before Confirm Trade.", "INFO")
	return true
end

function TradingPlazaScreen.CanConfirmTrade(nowTime: number?): boolean
	if not isOfferLocked or offerLockedAt == nil then
		return false
	end
	local timestamp = nowTime or os.clock()
	return (timestamp - offerLockedAt) >= TradingPlazaScreen.LOCK_COUNTDOWN_SECONDS
end

function TradingPlazaScreen.ClickConfirmTrade(sessionId: string, nowTime: number?): boolean
	if currentTradeSessionId ~= sessionId then
		return false
	end
	if not TradingPlazaScreen.CanConfirmTrade(nowTime) then
		ToastNotification.Show("Wait 3.0 seconds after locking offer before confirming!", "WARNING")
		return false
	end

	isTradeConfirmed = true
	local remote = Network.GetRemoteEvent(Network.Events.TradeSessionAction)
	remote:FireServer("CONFIRM_TRADE", { sessionId = sessionId })
	ToastNotification.Show("Trade Confirmed!", "SUCCESS")
	return true
end

UIManager.RegisterScreen("TradingPlazaScreen", TradingPlazaScreen)

return TradingPlazaScreen
