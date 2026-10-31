--!strict
-- src/client/init.client.luau
-- Client Bootstrapper: Network.Init -> R15AnimationController.Init -> CameraShiftLockController & InputController
-- R6AnimationController preserved as inert reference; R6 controller does not compete.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bootstrapStart = os.clock()
local TOTAL_BOOTSTRAP_BUDGET = 10.0

local remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for Shared")
local Shared = ReplicatedStorage:WaitForChild("Shared", remaining) :: Folder?
assert(Shared ~= nil, "[Client.Init] Shared folder timed out in ReplicatedStorage")

remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for Network")
local NetworkModule = Shared:WaitForChild("Network", remaining) :: ModuleScript?
assert(NetworkModule ~= nil, "[Client.Init] Network module timed out in Shared")

local Network = require(NetworkModule)

-- 1. Initialize Network client cache within total bootstrap budget (10s)
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before Network.Init")
Network.Init(remaining)

-- 2. Wait for character folder and R15AnimationController within remaining budget
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for character folder")
local CharacterFolder = script:WaitForChild("character", remaining) :: Folder?
assert(CharacterFolder ~= nil, "[Client.Init] character folder timed out in script")

remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for R15AnimationController")
local ControllerModule = CharacterFolder:WaitForChild("R15AnimationController", remaining) :: ModuleScript?
assert(ControllerModule ~= nil, "[Client.Init] R15AnimationController module timed out in character folder")

local R15AnimationController = require(ControllerModule)

-- 3. Initialize R15 Animation Controller within remaining budget
-- R6AnimationController preserved as inert reference; does not run concurrently.
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before R15AnimationController.Init")
R15AnimationController.Init(remaining)

local DribbleAnimModule = CharacterFolder:WaitForChild("DribbleAnimationController", remaining) :: ModuleScript?
if DribbleAnimModule and DribbleAnimModule:IsA("ModuleScript") then
	require(DribbleAnimModule).Init(remaining)
end

-- Option A Cleanup: R6ActionPoseController excised

-- 4. Initialize InputController (CameraShiftLockController disabled temporarily per Owner choice; normal Roblox camera)
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
if remaining > 0 then
	local ControllersFolder = script:FindFirstChild("controllers")
	if ControllersFolder and ControllersFolder:IsA("Folder") then
		-- CameraShiftLockController preserved as inert reference; not initialized (normal camera temporarily)

		require(ControllersFolder:WaitForChild("ShotController")).Init()
		-- Reverse-turn playback removed by Owner; normal locomotion owns direction.
		require(ControllersFolder:WaitForChild("KickHitboxDebugController")).Init()

		local InputCtrlModule = ControllersFolder:FindFirstChild("InputController")
		local dribblePresentation = ControllersFolder:FindFirstChild("DribblePresentationController")
		if dribblePresentation and dribblePresentation:IsA("ModuleScript") then
			require(dribblePresentation).Init()
		end
		if InputCtrlModule and InputCtrlModule:IsA("ModuleScript") then
			local InputController = require(InputCtrlModule)
			InputController.Init()
		end

		local SprintCtrlModule = ControllersFolder:FindFirstChild("SprintController")
		if SprintCtrlModule and SprintCtrlModule:IsA("ModuleScript") then
			local SprintController = require(SprintCtrlModule)
			SprintController.Init()
		end

		local AirMovementModule = ControllersFolder:FindFirstChild("AirMovementController")
		if AirMovementModule and AirMovementModule:IsA("ModuleScript") then
			local AirMovementController = require(AirMovementModule)
			AirMovementController.Init()
		end

		-- Option A Cleanup: TrainingHUD is inert reference material; not initialized
	end
end

-- 5. Initialize CameraPreviewController & MovementHeadingPreviewController (Studio-only prototype for Owner review)
task.spawn(function()
	local SharedConfigs = Shared:WaitForChild("configs", 5.0) :: Folder?
	local CamPreviewConfigModule = SharedConfigs and SharedConfigs:WaitForChild("CameraPreviewConfigs", 5.0) :: ModuleScript?
	if CamPreviewConfigModule and CamPreviewConfigModule:IsA("ModuleScript") then
		local CameraPreviewConfigs = require(CamPreviewConfigModule)
		if CameraPreviewConfigs.IsActiveInCurrentContext() then
			local ControllersFolder = script:WaitForChild("controllers", 5.0) :: Folder?
			if ControllersFolder and ControllersFolder:IsA("Folder") then
				local CamPreviewModule = ControllersFolder:WaitForChild("CameraPreviewController", 5.0) :: ModuleScript?
				local MovePreviewModule = ControllersFolder:WaitForChild("MovementHeadingPreviewController", 5.0) :: ModuleScript?
				if CamPreviewModule and CamPreviewModule:IsA("ModuleScript") and MovePreviewModule and MovePreviewModule:IsA("ModuleScript") then
					local CameraPreviewController = require(CamPreviewModule)
					local MovementHeadingPreviewController = require(MovePreviewModule)
					CameraPreviewController.Init()
					MovementHeadingPreviewController.Init()
				end
			end
		end
	end
end)
