--!strict
-- src/client/ui/screens/LockerScreen.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- 3-Tab Locker Screen (Cards, Battle Threads with Trait Slots 1-2, Celebrations) + 360 Rig Preview

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)
local ToastNotification = require(script.Parent.Parent.components.ToastNotification)

local LockerScreen = {}

export type LockerTab = "Cards" | "BattleThreads" | "Celebrations"

local isVisible = false
local activeTab: LockerTab = "Cards"
local previewRotationYaw = 0
local equippedCardId = "Card_KaiserImpact"
local equippedThreadInstanceId = "ThreadInst_Default_1"
local equippedCelebrationId = "Celebration_KneeSlide"
local equippedTraitsByThread: { [string]: { [number]: string } } = {
	ThreadInst_Default_1 = {},
}
local rootFrame: Frame? = nil

function LockerScreen.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "LockerScreen"
	frame.Size = UDim2.new(1, -80, 1, -180)
	frame.Position = UDim2.new(0, 40, 0, 84)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentCyan, 1.5)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -32, 0, 44)
	header.Position = UDim2.new(0, 16, 0, 12)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.TextPrimary
	header.TextSize = 24
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "LOCKER & BATTLE THREAD TRAIT SOCKETS (NO BOOTS/CLEATS)"
	header.Parent = frame

	local tabs: { LockerTab } = { "Cards", "BattleThreads", "Celebrations" }
	for idx, tabName in ipairs(tabs) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = "Tab_" .. tabName
		tabBtn.Size = UDim2.new(0, 180, 0, 40)
		tabBtn.Position = UDim2.new(0, 16 + (idx - 1) * 192, 0, 62)
		tabBtn.BackgroundColor3 = UITheme.Colors.BackgroundElevated
		tabBtn.Font = UITheme.Fonts.SubHeader
		tabBtn.TextColor3 = UITheme.Colors.AccentCyan
		tabBtn.TextSize = 15
		tabBtn.Text = tabName
		UITheme.ApplyCornerAndStroke(tabBtn, UITheme.CornerRadius.Small, UITheme.Colors.AccentCyan, 1)
		tabBtn.Activated:Connect(function()
			LockerScreen.SwitchTab(tabName)
		end)
		tabBtn.Parent = frame
	end

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function LockerScreen.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function LockerScreen.IsVisible(): boolean
	return isVisible
end

function LockerScreen.SwitchTab(tab: LockerTab)
	activeTab = tab
end

function LockerScreen.GetActiveTab(): LockerTab
	return activeTab
end

function LockerScreen.RotatePreview(deltaYawDegrees: number): number
	previewRotationYaw = (previewRotationYaw + deltaYawDegrees) % 360
	return previewRotationYaw
end

function LockerScreen.EquipCard(cardId: string): boolean
	if not Network.IsNonEmptyString(cardId, 64) then
		return false
	end
	equippedCardId = cardId
	local remote = Network.GetRemoteEvent(Network.Events.InventoryEquipRequest)
	remote:FireServer("Card", cardId)
	ToastNotification.Show("Equipped Player Card: " .. cardId, "SUCCESS")
	return true
end

function LockerScreen.EquipBattleThread(threadInstanceId: string): boolean
	if not Network.IsNonEmptyString(threadInstanceId, 64) then
		return false
	end
	equippedThreadInstanceId = threadInstanceId
	if not equippedTraitsByThread[threadInstanceId] then
		equippedTraitsByThread[threadInstanceId] = {}
	end
	local remote = Network.GetRemoteEvent(Network.Events.InventoryEquipRequest)
	remote:FireServer("BattleThread", threadInstanceId)
	ToastNotification.Show("Equipped Battle Thread: " .. threadInstanceId, "SUCCESS")
	return true
end

function LockerScreen.SocketTraitIntoThread(threadInstanceId: string, slotIndex: number, traitId: string): boolean
	if not Network.IsNonEmptyString(threadInstanceId, 64) then
		return false
	end
	if slotIndex ~= 1 and slotIndex ~= 2 then
		return false
	end
	if not Network.IsNonEmptyString(traitId, 64) then
		return false
	end

	if not equippedTraitsByThread[threadInstanceId] then
		equippedTraitsByThread[threadInstanceId] = {}
	end
	equippedTraitsByThread[threadInstanceId][slotIndex] = traitId

	local remote = Network.GetRemoteEvent(Network.Events.InventoryEquipRequest)
	remote:FireServer("TraitSlot", threadInstanceId, slotIndex, traitId)
	ToastNotification.Show(string.format("Socketed %s into Slot %d", traitId, slotIndex), "SUCCESS")
	return true
end

function LockerScreen.UnsocketTraitFromThread(threadInstanceId: string, slotIndex: number): boolean
	if not Network.IsNonEmptyString(threadInstanceId, 64) then
		return false
	end
	if slotIndex ~= 1 and slotIndex ~= 2 then
		return false
	end

	if equippedTraitsByThread[threadInstanceId] then
		equippedTraitsByThread[threadInstanceId][slotIndex] = nil
	end

	local remote = Network.GetRemoteEvent(Network.Events.InventoryEquipRequest)
	remote:FireServer("TraitSlot", threadInstanceId, slotIndex, "")
	ToastNotification.Show(string.format("Removed Trait from Slot %d", slotIndex), "INFO")
	return true
end

function LockerScreen.EquipCelebration(celebrationId: string): boolean
	if not Network.IsNonEmptyString(celebrationId, 64) then
		return false
	end
	equippedCelebrationId = celebrationId
	local remote = Network.GetRemoteEvent(Network.Events.InventoryEquipRequest)
	remote:FireServer("Celebration", celebrationId)
	return true
end

function LockerScreen.GetEquipmentSnapshot(): {
	cardId: string,
	threadInstanceId: string,
	celebrationId: string,
	traitsInEquippedThread: { [number]: string },
}
	return {
		cardId = equippedCardId,
		threadInstanceId = equippedThreadInstanceId,
		celebrationId = equippedCelebrationId,
		traitsInEquippedThread = table.clone(equippedTraitsByThread[equippedThreadInstanceId] or {}),
	}
end

UIManager.RegisterScreen("LockerScreen", LockerScreen)

return LockerScreen
