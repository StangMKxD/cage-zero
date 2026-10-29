--!strict
-- Rebase only an authoritatively controlled ball into the carrier's current render
-- frame. Never changes server ball state, grants possession, or predicts a free ball.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("configs"):WaitForChild("DribbleConfigs"))
local DribbleActionConfigs = require(Shared:WaitForChild("configs"):WaitForChild("DribbleActionConfigs"))
local Geometry = require(Shared:WaitForChild("DribbleGeometryHelper"))
local Constants = require(Shared:WaitForChild("Constants"))
local Controller = {}
local STEP = "CageZeroDribblePresentation"
local initialized = false
local displayedBall: BasePart? = nil

local function release()
	local ball = displayedBall
	if ball and ball.Parent then
		local position = ball:GetAttribute("BallPosition")
		if typeof(position) == "Vector3" then
			ball.CFrame = CFrame.new(position) * ball.CFrame.Rotation
		end
	end
	displayedBall = nil
end

function Controller.Step()
	local ball = Workspace:FindFirstChild(Constants.BALL_PART_NAME or "CageMatchBall")
	if not ball or not ball:IsA("BasePart") or ball:GetAttribute("BallState") ~= "Possessed" then
		release()
		return
	end
	local owner = ball:GetAttribute("PossessorUserId")
	local player = if typeof(owner) == "number" then Players:GetPlayerByUserId(owner) else nil
	local char = player and player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local pose = ball:GetAttribute("DribbleVisualPose")
	local stamp = ball:GetAttribute("DribbleVisualTime")
	local age = if typeof(stamp) == "number" then Workspace:GetServerTimeNow() - stamp else math.huge
	if not root or not root:IsA("BasePart") or not hum or hum.Health <= 0
		or hum.FloorMaterial == Enum.Material.Air or char:GetAttribute("IsBallCarrier") ~= true
		or ball:GetAttribute("DribbleVisualOwner") ~= owner or typeof(pose) ~= "CFrame"
		or age < -0.05 or age > Config.VISUAL_SNAPSHOT_MAX_AGE then
		release()
		return
	end
	local authoritative = ball:GetAttribute("BallPosition")
	if typeof(authoritative) ~= "Vector3" then
		release()
		return
	end
	-- The server already chose a safe arc/flank. Preserve that offset, rebase its
	-- carrier frame, then check the *current* root/cage again after translation.
	local rebased = root.CFrame * pose
	local target = Vector3.new(rebased.X, authoritative.Y, rebased.Z)
	local isGoalMode = char:GetAttribute("GoalDribbleActive") == true
	local minSep = if isGoalMode then DribbleActionConfigs.GOAL_CARRIER_SEPARATION else nil
	local safe = Geometry.ResolveBodyCage(root.Position, root.Position, target, target,
		Vector3.zero, Vector3.zero, 0, root.CFrame.LookVector, minSep)
	ball.CFrame = CFrame.new(safe) * rebased.Rotation
	displayedBall = ball
end

function Controller.Init()
	if initialized then return end
	initialized = true
	-- Run after character movement/camera and replicated part presentation.
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Last.Value, Controller.Step)
end

function Controller.Destroy()
	if not initialized then return end
	initialized = false
	RunService:UnbindFromRenderStep(STEP)
	release()
end

return Controller
