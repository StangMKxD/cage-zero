--!strict
-- src/client/controllers/InputController.luau
-- Module 02: Client Input Handler (Option A Cleanup Baseline)
-- Restores standard Roblox locomotion; legacy Plan 02/03 continuous action bindings excised.

local Players = game:GetService("Players")

local CharacterFolder = script.Parent.Parent:WaitForChild("character")
-- CameraShiftLockController preserved as inert reference; disabled temporarily per Owner choice (normal camera)

local isInitialized = false
local InputController = {}

local charDiedConn: RBXScriptConnection? = nil

local function bindChar(char: Model)
	if charDiedConn then
		charDiedConn:Disconnect()
		charDiedConn = nil
	end

	local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if hum and hrp then
		-- Option A: Restore native Humanoid locomotion and jumping previously suppressed by legacy gameplay
		hum.UseJumpPower = true
		hum.JumpPower = 50
		hum.JumpHeight = 7.2
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		charDiedConn = hum.Died:Connect(function()
			-- Character died cleanup
		end)
	end
end

function InputController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	if localPlayer.Character then
		bindChar(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(bindChar)

	-- CameraShiftLockController preserved as inert reference; not initialized (normal camera temporarily)
end

return table.freeze(InputController)
