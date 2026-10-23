--!strict
-- src/client/controllers/CameraShiftLockController.luau
-- Authoritative Client-Side Camera Shift Lock & Character Orientation Controller
-- Adapted from FootballSandbox (.sandbox/prototype3) per HANDOFF Contract §7.4
-- Source reference: prototype3/client/FootballClient.client.luau:822-867,1064,1698-1720,2286-2328

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local CameraShiftLockController = {}

local isInitialized = false
local shiftLockEnabled = Constants.AUTO_SHIFTLOCK_DEFAULT ~= false
local localPlayer = Players.LocalPlayer

-- Locked rotation states managed across actions (priority order)
local isSliding = false
local slideLockDir = Vector3.new(0, 0, 1)

local isAirborneLocked = false
local jumpCommitDir = Vector3.new(0, 0, 1)

local renderConn: RBXScriptConnection? = nil
local inputConn: RBXScriptConnection? = nil
local menuOpenConn: RBXScriptConnection? = nil
local menuCloseConn: RBXScriptConnection? = nil
local focusLostConn: RBXScriptConnection? = nil
local focusGainedConn: RBXScriptConnection? = nil

-- Change callbacks (for HUD indicator updates)
local stateChangeCallbacks: { (enabled: boolean) -> () } = {}

function CameraShiftLockController.IsEnabled(): boolean
	return shiftLockEnabled
end

function CameraShiftLockController.OnStateChanged(callback: (enabled: boolean) -> ())
	table.insert(stateChangeCallbacks, callback)
end

local function notifyStateChanged()
	for _, cb in ipairs(stateChangeCallbacks) do
		pcall(cb, shiftLockEnabled)
	end
end

function CameraShiftLockController.SetShiftLockState(enabled: boolean)
	shiftLockEnabled = enabled
	local char = localPlayer and localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if not enabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		if hum and not isSliding and not isAirborneLocked then
			hum.AutoRotate = true
		end
	else
		if not GuiService.MenuIsOpen and UserInputService:GetFocusedTextBox() == nil then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		if hum and not isSliding and not isAirborneLocked then
			hum.AutoRotate = false
		end
	end
	notifyStateChanged()
end

function CameraShiftLockController.Toggle()
	CameraShiftLockController.SetShiftLockState(not shiftLockEnabled)
end

-- Rotation priority setters called by InputController
function CameraShiftLockController.SetSlideLock(active: boolean, lockDir: Vector3?)
	isSliding = active
	if lockDir and lockDir.Magnitude > 1e-3 then
		slideLockDir = Vector3.new(lockDir.X, 0, lockDir.Z).Unit
	end
end

function CameraShiftLockController.SetAirborneJumpLock(active: boolean, commitDir: Vector3?)
	isAirborneLocked = active
	if commitDir and commitDir.Magnitude > 1e-3 then
		jumpCommitDir = Vector3.new(commitDir.X, 0, commitDir.Z).Unit
	end
end

function CameraShiftLockController.IsAirborneLocked(): boolean
	return isAirborneLocked
end

function CameraShiftLockController.IsSlideLocked(): boolean
	return isSliding
end

function CameraShiftLockController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	if not localPlayer then
		localPlayer = Players.LocalPlayer
	end

	-- Menu listeners: release mouse when Roblox menu opens, re-lock when closed
	menuOpenConn = GuiService.MenuOpened:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)

	menuCloseConn = GuiService.MenuClosed:Connect(function()
		if shiftLockEnabled and UserInputService:GetFocusedTextBox() == nil then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end)

	-- Window focus listeners
	focusLostConn = UserInputService.WindowFocusReleased:Connect(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)

	focusGainedConn = UserInputService.WindowFocused:Connect(function()
		if shiftLockEnabled and not GuiService.MenuIsOpen and UserInputService:GetFocusedTextBox() == nil then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end)

	-- Key toggle bindings: L, LeftAlt, RightAlt (Shift keys are reserved for Sprint!)
	inputConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if UserInputService:GetFocusedTextBox() ~= nil then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftAlt then
			CameraShiftLockController.Toggle()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Re-center mouse lock on click if active
			if shiftLockEnabled and not GuiService.MenuIsOpen and UserInputService:GetFocusedTextBox() == nil then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end
	end)

	-- Single Authoritative Camera & Rotation Update Loop (RenderStepped)
	renderConn = RunService.RenderStepped:Connect(function(dt: number)
		local char = localPlayer and localPlayer.Character
		if not char then
			return
		end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hum or not hrp or hum.Health <= 0 then
			return
		end

		-- Frame-rate independent smoothing alpha based on 0.18 @ 60fps
		local targetAlpha = 1 - (1 - Constants.SHIFTLOCK_SMOOTHING_ALPHA) ^ math.clamp(dt * 60, 0.1, 4.0)

		-- Maintain Mouse Lock
		if shiftLockEnabled and not GuiService.MenuIsOpen and UserInputService:GetFocusedTextBox() == nil then
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		end

		-- ROTATION PRIORITY CHAIN (HANDOFF §7.4):
		-- 1. Slide: lock facing strictly along slideLockDir
		-- 2. ShiftLock ON: yaw follows camera horizontal look vector (grounded or airborne)
		-- 3. ShiftLock OFF: native Humanoid.AutoRotate = true (fluid steering)
		if isSliding then
			hum.AutoRotate = false
			local curPos = hrp.Position
			hrp.CFrame = CFrame.lookAt(curPos, curPos + slideLockDir)
			hum.CameraOffset = hum.CameraOffset:Lerp(Constants.SHIFTLOCK_SHOULDER_OFFSET, targetAlpha)
		elseif shiftLockEnabled then
			hum.AutoRotate = false
			local cam = Workspace.CurrentCamera
			if cam then
				local camLook = cam.CFrame.LookVector
				local flatLook = Vector3.new(camLook.X, 0, camLook.Z)
				if flatLook.Magnitude > 0.001 then
					local curPos = hrp.Position
					hrp.CFrame = CFrame.lookAt(curPos, curPos + flatLook)
				end
			end
			hum.CameraOffset = hum.CameraOffset:Lerp(Constants.SHIFTLOCK_SHOULDER_OFFSET, targetAlpha)
		else
			-- Shift Lock OFF: restore native behavior
			hum.AutoRotate = true
			hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.zero, targetAlpha)
		end
	end)
end

function CameraShiftLockController.Cleanup()
	if renderConn then renderConn:Disconnect(); renderConn = nil end
	if inputConn then inputConn:Disconnect(); inputConn = nil end
	if menuOpenConn then menuOpenConn:Disconnect(); menuOpenConn = nil end
	if menuCloseConn then menuCloseConn:Disconnect(); menuCloseConn = nil end
	if focusLostConn then focusLostConn:Disconnect(); focusLostConn = nil end
	if focusGainedConn then focusGainedConn:Disconnect(); focusGainedConn = nil end
	table.clear(stateChangeCallbacks)
	isInitialized = false
end

return CameraShiftLockController
