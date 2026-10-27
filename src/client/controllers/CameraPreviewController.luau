--!strict
-- src/client/controllers/CameraPreviewController.luau
-- Prototype Camera Controller: Scriptable Free Orbit Camera + ShiftLock Reticle (< · >) + Pointer Capture
-- Governed by RF02-CAMERA-PREVIEW Hand-Off Contract (CP01..CP04)

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local currentCamera = Workspace.CurrentCamera

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigsFolder = Shared:WaitForChild("configs")
local CameraPreviewConfigs = require(ConfigsFolder:WaitForChild("CameraPreviewConfigs"))

local CameraPreviewController = {}

local isInitialized = false
local isActive = false
local isCursorLocked = false

-- Camera rotation state (in radians)
local currentYaw: number = 0.0
local currentPitch: number = math.rad(CameraPreviewConfigs.Camera.DefaultPitchDeg)
local currentDistance: number = CameraPreviewConfigs.Camera.Distance
local targetDistance: number = CameraPreviewConfigs.Camera.Distance

-- Connections and cleanup holders
local renderStepName = "CameraPreviewRenderStep"
local isRenderBound = false
local connections: { RBXScriptConnection } = {}

-- Reticle UI references
local reticleGui: ScreenGui? = nil

-- Character tracking
local currentCharacter: Model? = nil
local currentRootPart: BasePart? = nil
local currentHumanoid: Humanoid? = nil

local function getRaycastParams(character: Model?): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filterList: { Instance } = {}
	if character then
		table.insert(filterList, character)
	end
	local previewRigs = Workspace:FindFirstChild("PreviewRigs")
	if previewRigs then
		table.insert(filterList, previewRigs)
	end
	params.FilterDescendantsInstances = filterList
	return params
end

local function setCursorLock(locked: boolean)
	isCursorLocked = locked
	if locked and isActive then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		if reticleGui then
			reticleGui.Enabled = true
		end
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if reticleGui then
			reticleGui.Enabled = false
		end
	end
end

local function isInteractingWithUI(): boolean
	if GuiService.MenuIsOpen then
		return true
	end
	if UserInputService:GetFocusedTextBox() ~= nil then
		return true
	end
	return false
end

local function createChevronArm(
	parent: GuiObject,
	name: string,
	pos: UDim2,
	rotationDeg: number,
	length: number,
	thickness: number,
	color: Color3,
	strokeColor: Color3
): Frame
	local arm = Instance.new("Frame")
	arm.Name = name
	arm.Size = UDim2.fromOffset(length, thickness)
	arm.AnchorPoint = Vector2.new(0.5, 0.5)
	arm.Position = pos
	arm.Rotation = rotationDeg
	arm.BackgroundColor3 = color
	arm.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = arm

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = arm

	arm.Parent = parent
	return arm
end

local function createReticleGui()
	if reticleGui then
		reticleGui:Destroy()
		reticleGui = nil
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui", 5.0) :: PlayerGui?
	if not playerGui then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "CameraPreviewReticleGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.Enabled = false

	local reticleCfg = CameraPreviewConfigs.Reticle
	local container = Instance.new("Frame")
	container.Name = "ReticleContainer"
	container.Size = UDim2.fromOffset(64, 48)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = gui

	-- 1. Center Dot
	local dot = Instance.new("Frame")
	dot.Name = "CenterDot"
	dot.Size = UDim2.fromOffset(reticleCfg.DotSize, reticleCfg.DotSize)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.BackgroundColor3 = reticleCfg.DotColor
	dot.BorderSizePixel = 0

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	local dotStroke = Instance.new("UIStroke")
	dotStroke.Color = reticleCfg.StrokeColor
	dotStroke.Thickness = 1
	dotStroke.Transparency = 0.4
	dotStroke.Parent = dot
	dot.Parent = container

	-- 2. Left Chevron: <
	-- Upper arm of left chevron
	createChevronArm(
		container,
		"LeftChevronTop",
		UDim2.new(0.5, -12, 0.5, -5),
		-40,
		reticleCfg.ArmLength,
		reticleCfg.ArmThickness,
		reticleCfg.ChevronColor,
		reticleCfg.StrokeColor
	)
	-- Lower arm of left chevron
	createChevronArm(
		container,
		"LeftChevronBottom",
		UDim2.new(0.5, -12, 0.5, 5),
		40,
		reticleCfg.ArmLength,
		reticleCfg.ArmThickness,
		reticleCfg.ChevronColor,
		reticleCfg.StrokeColor
	)

	-- 3. Right Chevron: >
	-- Upper arm of right chevron
	createChevronArm(
		container,
		"RightChevronTop",
		UDim2.new(0.5, 12, 0.5, -5),
		40,
		reticleCfg.ArmLength,
		reticleCfg.ArmThickness,
		reticleCfg.ChevronColor,
		reticleCfg.StrokeColor
	)
	-- Lower arm of right chevron
	createChevronArm(
		container,
		"RightChevronBottom",
		UDim2.new(0.5, 12, 0.5, 5),
		-40,
		reticleCfg.ArmLength,
		reticleCfg.ArmThickness,
		reticleCfg.ChevronColor,
		reticleCfg.StrokeColor
	)

	gui.Parent = playerGui
	reticleGui = gui
end

local function onCameraUpdate(_dt: number)
	if not isActive then
		return
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	-- Enforce Scriptable camera so PlayerModule cannot override it
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Enforce cursor lock and invisible mouse icon every frame while actively locked
	-- This completely prevents the OS mouse from slipping to a second monitor!
	if isCursorLocked then
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
		if UserInputService.MouseIconEnabled ~= false then
			UserInputService.MouseIconEnabled = false
		end
	end

	if not currentRootPart or not currentRootPart.Parent then
		return
	end

	local cfg = CameraPreviewConfigs.Camera
	local focusPos = currentRootPart.Position + Vector3.new(0, cfg.FocusHeightOffset, 0)

	-- Compute view rotation matrix (Yaw around Y, Pitch around X)
	local rotCFrame = CFrame.Angles(0, currentYaw, 0) * CFrame.Angles(currentPitch, 0, 0)

	-- Smooth zoom interpolation towards target distance
	local distDiff = targetDistance - currentDistance
	if math.abs(distDiff) > 0.01 then
		currentDistance = currentDistance + distDiff * math.clamp(_dt * 15.0, 0, 1)
	else
		currentDistance = targetDistance
	end

	-- Desired camera position in world space
	local localCamOffset = Vector3.new(cfg.FocusSideOffset, 0, currentDistance)
	local desiredCamPos = focusPos + rotCFrame:VectorToWorldSpace(localCamOffset)

	-- Bounded local occlusion query against arena walls / roof
	local raycastParams = getRaycastParams(currentCharacter)
	local rayDir = desiredCamPos - focusPos
	local rayDist = rayDir.Magnitude

	local finalCamPos = desiredCamPos
	if rayDist > 0.001 then
		local hit = Workspace:Raycast(focusPos, rayDir, raycastParams)
		if hit then
			local hitDist = math.max(cfg.MinDistance, hit.Distance - cfg.CollisionMargin)
			finalCamPos = focusPos + rayDir.Unit * hitDist
		end
	end

	camera.CFrame = CFrame.lookAt(finalCamPos, focusPos)
	camera.Focus = CFrame.new(focusPos)
end

local function onInputChanged(input: InputObject, gameProcessed: boolean)
	if not isActive then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if isCursorLocked and not gameProcessed then
			local cfg = CameraPreviewConfigs.Camera
			local deltaX = input.Delta.X
			local deltaY = input.Delta.Y

			currentYaw = (currentYaw - deltaX * cfg.MouseSensitivityX) % (math.pi * 2)

			local minPitchRad = math.rad(cfg.MinPitchDeg)
			local maxPitchRad = math.rad(cfg.MaxPitchDeg)
			currentPitch = math.clamp(currentPitch - deltaY * cfg.MouseSensitivityY, minPitchRad, maxPitchRad)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		if not isInteractingWithUI() then
			local cfg = CameraPreviewConfigs.Camera
			local scrollDelta = input.Position.Z
			targetDistance = math.clamp(targetDistance - scrollDelta * cfg.ZoomStep, cfg.MinDistance, cfg.MaxDistance)
		end
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if not isActive then
		return
	end

	-- Toggle cursor lock on LeftAlt / RightAlt (Shift reserved for Sprint per Owner Override 2026-10-26)
	if not gameProcessed and (input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt) then
		if not isInteractingWithUI() then
			setCursorLock(not isCursorLocked)
			return
		end
	end

	-- When user clicks into the game window, capture cursor!
	-- This ensures we DO NOT steal/trap mouse while user is using another application or monitor!
	if not isCursorLocked then
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2 then
			if not isInteractingWithUI() then
				setCursorLock(true)
			end
		end
	end
end

local function setupCharacter(char: Model)
	currentCharacter = char
	currentRootPart = char:WaitForChild("HumanoidRootPart", 5.0) :: BasePart?
	currentHumanoid = char:WaitForChild("Humanoid", 5.0) :: Humanoid?

	if currentRootPart and currentYaw == 0.0 then
		-- Initialize camera yaw behind character on first load
		local _, rootYaw, _ = currentRootPart.CFrame:ToOrientation()
		currentYaw = rootYaw
	end

	if currentHumanoid then
		-- Hide player name and health display above head per Owner direction
		currentHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		currentHumanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

		table.insert(
			connections,
			currentHumanoid.Died:Connect(function()
				setCursorLock(false)
			end)
		)
	end
end

function CameraPreviewController.GetCameraYaw(): number
	return currentYaw
end

function CameraPreviewController.GetCameraPitch(): number
	return currentPitch
end

function CameraPreviewController.GetCameraCFrame(): CFrame
	local camera = Workspace.CurrentCamera
	return camera and camera.CFrame or CFrame.identity
end

function CameraPreviewController.IsActive(): boolean
	return isActive
end

function CameraPreviewController.IsCursorLocked(): boolean
	return isCursorLocked
end

function CameraPreviewController.SetCursorLock(locked: boolean)
	setCursorLock(locked)
end

function CameraPreviewController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	if not CameraPreviewConfigs.IsActiveInCurrentContext() then
		return
	end

	isActive = true

	createReticleGui()

	-- Take authoritative control of CurrentCamera
	currentCamera = Workspace.CurrentCamera
	if currentCamera then
		currentCamera.CameraType = Enum.CameraType.Scriptable
	end

	-- Bind render step for smooth camera tracking and continuous lock clamping
	if not isRenderBound then
		RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value, onCameraUpdate)
		isRenderBound = true
	end

	-- Input listeners
	table.insert(connections, UserInputService.InputChanged:Connect(onInputChanged))
	table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))

	-- Context listeners: Immediately release cursor when window loses focus (e.g. user moves to second monitor)
	table.insert(
		connections,
		UserInputService.WindowFocusReleased:Connect(function()
			setCursorLock(false)
		end)
	)

	-- Release when Roblox menu opens, re-capture when menu closes
	table.insert(
		connections,
		GuiService.MenuOpened:Connect(function()
			setCursorLock(false)
		end)
	)
	table.insert(
		connections,
		GuiService.MenuClosed:Connect(function()
			-- User closed menu back in Roblox window
			setCursorLock(true)
		end)
	)

	-- Release when typing in chat/textboxes
	table.insert(
		connections,
		UserInputService.TextBoxFocused:Connect(function()
			setCursorLock(false)
		end)
	)
	table.insert(
		connections,
		UserInputService.TextBoxFocusReleased:Connect(function()
			setCursorLock(true)
		end)
	)

	-- Character setup and respawn handling
	if localPlayer.Character then
		setupCharacter(localPlayer.Character)
	end
	table.insert(
		connections,
		localPlayer.CharacterAdded:Connect(function(newChar)
			setupCharacter(newChar)
		end)
	)

	-- NOTE: Do NOT immediately trap cursor on startup if Roblox does not have active interaction!
	-- Cursor will be captured when the user clicks inside the viewport.
end

function CameraPreviewController.Cleanup()
	isActive = false

	if isRenderBound then
		RunService:UnbindFromRenderStep(renderStepName)
		isRenderBound = false
	end

	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)

	if reticleGui then
		reticleGui:Destroy()
		reticleGui = nil
	end

	setCursorLock(false)

	-- Restore native camera
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if currentHumanoid then
			camera.CameraSubject = currentHumanoid
		end
	end

	currentCharacter = nil
	currentRootPart = nil
	currentHumanoid = nil
	isInitialized = false
end

return CameraPreviewController
