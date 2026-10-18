--!strict
-- src/client/ui/screens/FreeKickOverlay.luau
-- MODULE 07: 07-ui-navigation-and-screens
-- Set-Piece / Free-Kick Overlay: Trajectory Line, Spin Cursor on Ball Icon, and 2-Tap Timed Power Bar

local UITheme = require(script.Parent.Parent.UITheme)
local UIManager = require(script.Parent.Parent.UIManager)

local FreeKickOverlay = {}

local isVisible = false
local activeSpotPosition = Vector3.zero
local activeTimeLimit = 5.0
local spinCursor = Vector2.zero
local lockedPowerPct = 0.85
local lockedAccuracyOffset = 0.0
local onSubmitHandler: ((Vector3, Vector2, number, number) -> ())? = nil
local rootFrame: Frame? = nil

function FreeKickOverlay.Mount(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "FreeKickOverlay"
	frame.Size = UDim2.new(0, 480, 0, 220)
	frame.Position = UDim2.new(0.5, -240, 0.68, -110)
	frame.BackgroundColor3 = UITheme.Colors.BackgroundSecondary
	frame.BorderSizePixel = 0
	frame.Visible = isVisible
	UITheme.ApplyCornerAndStroke(frame, UITheme.CornerRadius.Large, UITheme.Colors.AccentCyan, 2)

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -24, 0, 36)
	header.Position = UDim2.new(0, 12, 0, 10)
	header.BackgroundTransparency = 1
	header.Font = UITheme.Fonts.Header
	header.TextColor3 = UITheme.Colors.AccentCyan
	header.TextSize = 18
	header.Text = "FREE KICK: SPIN CURSOR & 2-TAP TIMED POWER BAR"
	header.Parent = frame

	local barFrame = Instance.new("Frame")
	barFrame.Name = "TimedPowerBar"
	barFrame.Size = UDim2.new(1, -40, 0, 32)
	barFrame.Position = UDim2.new(0, 20, 0, 120)
	barFrame.BackgroundColor3 = UITheme.Colors.BackgroundElevated
	UITheme.ApplyCornerAndStroke(barFrame, UITheme.CornerRadius.Small, UITheme.Colors.AccentGold, 1.5)
	barFrame.Parent = frame

	frame.Parent = parent
	rootFrame = frame
	return frame
end

function FreeKickOverlay.SetVisible(visible: boolean)
	isVisible = visible
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function FreeKickOverlay.IsVisible(): boolean
	return isVisible
end

function FreeKickOverlay.OpenOverlay(
	spotPosition: Vector3,
	timeLimit: number,
	onSubmitCallback: (Vector3, Vector2, number, number) -> ()
)
	activeSpotPosition = spotPosition
	activeTimeLimit = timeLimit
	spinCursor = Vector2.zero
	lockedPowerPct = 0.85
	lockedAccuracyOffset = 0.0
	onSubmitHandler = onSubmitCallback
	FreeKickOverlay.SetVisible(true)
	UIManager.OpenOverlay("FreeKickOverlay")
end

function FreeKickOverlay.SetSpinCursor(spinX: number, spinY: number): Vector2
	spinCursor = Vector2.new(math.clamp(spinX, -1, 1), math.clamp(spinY, -1, 1))
	return spinCursor
end

function FreeKickOverlay.SubmitTwoTapShot(
	aimDirection: Vector3,
	powerPct: number,
	accuracyOffset: number
)
	lockedPowerPct = math.clamp(powerPct, 0.1, 1.0)
	lockedAccuracyOffset = math.clamp(accuracyOffset, -1.0, 1.0)
	if onSubmitHandler then
		onSubmitHandler(aimDirection, spinCursor, lockedPowerPct, lockedAccuracyOffset)
	end
end

function FreeKickOverlay.CloseOverlay()
	onSubmitHandler = nil
	FreeKickOverlay.SetVisible(false)
	UIManager.CloseOverlay("FreeKickOverlay")
end

function FreeKickOverlay.GetOverlaySnapshot(): {
	isVisible: boolean,
	spotPosition: Vector3,
	timeLimit: number,
	spinCursor: Vector2,
}
	return {
		isVisible = isVisible,
		spotPosition = activeSpotPosition,
		timeLimit = activeTimeLimit,
		spinCursor = spinCursor,
	}
end

UIManager.RegisterScreen("FreeKickOverlay", FreeKickOverlay)

return FreeKickOverlay
