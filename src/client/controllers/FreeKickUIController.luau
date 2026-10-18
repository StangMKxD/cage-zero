--!strict
-- src/client/controllers/FreeKickUIController.luau
-- Module 04: Client Controller for FC27 Set-Piece Aiming, Ball Spin Selector & 2-Tap Timed Power Bar

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local UIFolder = script.Parent.Parent:WaitForChild("ui")
local UIManager = require(UIFolder:WaitForChild("UIManager"))
local FreeKickOverlay = require(UIFolder:WaitForChild("screens"):WaitForChild("FreeKickOverlay"))

local isInitialized = false
local FreeKickUIController = {}

function FreeKickUIController.EvaluateTimingZone(cursorPositionNormalized: number): Types.FreeKickTimingZone
	local distFromOptimal = math.abs(cursorPositionNormalized - 0.82)
	if distFromOptimal <= 0.07 then
		return "Green"
	elseif distFromOptimal <= 0.18 then
		return "Yellow"
	end
	return "Red"
end

function FreeKickUIController.SubmitShot(
	aimDir: Vector3,
	spinOffset: Vector2,
	powerPercent: number,
	timingZone: Types.FreeKickTimingZone
)
	local submitRemote = Network.GetRemoteEvent(Network.Names.FreeKickSubmit)
	submitRemote:FireServer(aimDir, spinOffset, powerPercent, timingZone)
	if type(FreeKickOverlay.CloseOverlay) == "function" then
		FreeKickOverlay.CloseOverlay()
	end
	if type(UIManager.CloseOverlay) == "function" then
		UIManager.CloseOverlay("FreeKickOverlay")
	end
end

function FreeKickUIController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local startEvent = Network.GetRemoteEvent(Network.Names.FreeKickStartEvent)
	startEvent.OnClientEvent:Connect(function(spotPosition: Vector3, timeLimit: number)
		if type(FreeKickOverlay.OpenOverlay) == "function" then
			FreeKickOverlay.OpenOverlay(spotPosition, timeLimit, function(aimDir, spinOffset, powerPercent, timingZone)
				FreeKickUIController.SubmitShot(aimDir, spinOffset, powerPercent, timingZone)
			end)
		end
		if type(UIManager.OpenOverlay) == "function" then
			UIManager.OpenOverlay("FreeKickOverlay")
		end
	end)
end

return table.freeze(FreeKickUIController)
