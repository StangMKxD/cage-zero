--!strict
-- src/client/character/R15AnimationController.luau
-- Client R15 Animation & Character Lifecycle Controller
-- Tracks native R15 Animator and Humanoid lifecycle with strict generation and invalidation gates (RF-F22).
-- Edge case resolved: rejects character ~= LocalPlayer.Character BEFORE generation increment/invalidation.
-- No custom Idle/locomotion pose authoring (reserved for subsequent Owner-directed stage).

local Players = game:GetService("Players")

local isInitialized = false
local currentCharacter: Model? = nil
local currentHumanoid: Humanoid? = nil
local currentAnimator: Animator? = nil
local characterGeneration: number = 0
local activeConnections: { RBXScriptConnection } = {}

local R15AnimationController = {}

local function cleanupConnections()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)
end

local function invalidateCharacterState()
	cleanupConnections()
	currentCharacter = nil
	currentHumanoid = nil
	currentAnimator = nil
end

local function onCharacterRemoving(character: Model)
	if character == currentCharacter then
		invalidateCharacterState()
	end
end

local function onCharacterAdded(character: Model)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	-- Edge Case (3): Reject mismatched or non-current character BEFORE generation increment or invalidation!
	-- If a delayed existingChar task runs after CharacterAdded already replaced it,
	-- or character is already removed, do not touch characterGeneration or invalidate the newer character!
	if localPlayer.Character ~= character or not character:IsDescendantOf(game) then
		return
	end

	characterGeneration += 1
	local thisGen = characterGeneration

	-- Invalidate previous character state immediately upon new character arriving
	invalidateCharacterState()
	currentCharacter = character

	-- Yield to find Humanoid within bounded timeout
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?

	-- Post-yield generation and hierarchy verification (RF-F22)
	if characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid
		or not humanoid:IsDescendantOf(character) then
		return
	end

	-- Yield to find Animator within bounded timeout
	local animator = humanoid:WaitForChild("Animator", 10) :: Animator?

	-- Post-yield generation and hierarchy verification (RF-F22)
	if characterGeneration ~= thisGen
		or localPlayer.Character ~= character
		or not character:IsDescendantOf(game)
		or not humanoid:IsDescendantOf(character)
		or not animator
		or not animator:IsDescendantOf(humanoid) then
		return
	end

	-- Successfully validated both Humanoid and Animator for this active generation
	currentHumanoid = humanoid
	currentAnimator = animator

	-- Configure native locomotion responsiveness
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

	-- Invalidate on Humanoid death (RF-F22)
	local diedConn = humanoid.Died:Connect(function()
		if characterGeneration == thisGen then
			-- Invalidate on death so IsR15Ready() returns false during death/respawn window
			currentAnimator = nil
			currentHumanoid = nil
		end
	end)
	table.insert(activeConnections, diedConn)
end

function R15AnimationController.Init(timeoutBudget: number?)
	if isInitialized then
		return
	end
	isInitialized = true

	local localPlayer = Players.LocalPlayer
	assert(localPlayer ~= nil, "[R15AnimationController] LocalPlayer required for initialization")

	localPlayer.CharacterAdded:Connect(onCharacterAdded)
	localPlayer.CharacterRemoving:Connect(onCharacterRemoving)

	-- RF-F22: Capture local character BEFORE task.spawn to avoid mutable reads inside delayed closure
	local existingChar = localPlayer.Character
	if existingChar and existingChar:IsDescendantOf(game) then
		task.spawn(function()
			onCharacterAdded(existingChar)
		end)
	end
end

function R15AnimationController.GetAnimator(): Animator?
	if R15AnimationController.IsR15Ready() then
		return currentAnimator
	end
	return nil
end

function R15AnimationController.GetHumanoid(): Humanoid?
	if R15AnimationController.IsR15Ready() then
		return currentHumanoid
	end
	return nil
end

function R15AnimationController.GetCharacter(): Model?
	if R15AnimationController.IsR15Ready() then
		return currentCharacter
	end
	return nil
end

function R15AnimationController.IsR15Ready(): boolean
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return false
	end

	local char = currentCharacter
	local hum = currentHumanoid
	local anim = currentAnimator

	if not char or not hum or not anim then
		return false
	end

	-- Strict validity checks (RF-F22):
	-- 1. Character matches LocalPlayer.Character and is descendant of game/Workspace
	-- 2. Humanoid is descendant of Character, is alive (Health > 0), and is RigType R15
	-- 3. Animator is descendant of Humanoid
	if char ~= localPlayer.Character or not char:IsDescendantOf(game) then
		return false
	end

	if not hum:IsDescendantOf(char) or hum.RigType ~= Enum.HumanoidRigType.R15 or hum.Health <= 0 then
		return false
	end

	if not anim:IsDescendantOf(hum) then
		return false
	end

	return true
end

return table.freeze(R15AnimationController)
