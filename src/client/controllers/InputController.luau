--!strict
-- src/client/controllers/InputController.luau
-- Module 02: Client Input Handler (Option A Cleanup Baseline)
-- Restores standard Roblox locomotion; respects authoritative higher-jump configuration.
-- Governed by: docs/plan/phase-01-gameplay-demo/release-first/assets/dribble-receive-HANDOFF.md (Owner Additive Scope)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local JumpConfigs = require(Shared:WaitForChild("configs"):WaitForChild("JumpConfigs"))

local isInitialized = false
local InputController = {}

local charDiedConn: RBXScriptConnection? = nil
local activeCharGen: number = 0

local function bindChar(char: Model)
	activeCharGen += 1
	local thisGen = activeCharGen

	if charDiedConn then
		charDiedConn:Disconnect()
		charDiedConn = nil
	end

	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?

	-- Post-yield generation and hierarchy verification
	if activeCharGen ~= thisGen or not char:IsDescendantOf(game) then
		return
	end

	if hum and hrp then
		-- Authoritative higher-jump configuration (JumpConfigs.JUMP_POWER)
		hum.UseJumpPower = true
		hum.JumpPower = JumpConfigs.JUMP_POWER
		hum.JumpHeight = JumpConfigs.EXPECTED_APEX_HEIGHT
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		charDiedConn = hum.Died:Connect(function()
			if activeCharGen == thisGen then
				-- Character died cleanup
			end
		end)
	end
end

function InputController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	if localPlayer.Character and localPlayer.Character:IsDescendantOf(game) then
		bindChar(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(bindChar)
end

return table.freeze(InputController)
