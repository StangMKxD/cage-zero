--!strict
-- src/client/controllers/InputController.luau
-- Module 02: Client Input Handler for Pass (Q), Shoot (E), Sprint (LeftShift), and Parry (F)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local isInitialized = false
local InputController = {}

local function getAimDirection(): Vector3
	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer.Character and localPlayer.Character.PrimaryPart then
		return localPlayer.Character.PrimaryPart.CFrame.LookVector
	end
	local cam = Workspace.CurrentCamera
	if cam then
		return cam.CFrame.LookVector
	end
	return Vector3.new(0, 0, 1)
end

function InputController.RequestBallAction(actionType: Types.BallActionType, customAim: Vector3?)
	local aimDir = customAim or getAimDirection()
	local remote = Network.GetRemoteEvent(Network.Names.BallActionRequest)
	remote:FireServer(actionType, aimDir)
end

function InputController.RequestParryAttempt()
	local remote = Network.GetRemoteEvent(Network.Names.ParryAttemptRequest)
	remote:FireServer(os.clock())
end

function InputController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Q then
			InputController.RequestBallAction("Pass")
		elseif input.KeyCode == Enum.KeyCode.E then
			InputController.RequestBallAction("Shoot")
		elseif input.KeyCode == Enum.KeyCode.LeftShift then
			InputController.RequestBallAction("Sprint")
		elseif input.KeyCode == Enum.KeyCode.F then
			InputController.RequestParryAttempt()
		end
	end)
end

return table.freeze(InputController)
