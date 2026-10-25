--!strict
-- src/server/services/R15AvatarService.luau
-- Authoritative Server Spawner for Player Avatar R15 (ROBLOX Boy Body Baseline)
-- Applies canonical ROBLOX Boy limbs (Bundle 109) with normalized +30% height dimensions.
-- Strictly preserves each player's personal face, skin tones, clothing, hair, hats, and accessories.
-- Fail-closed identity readiness: never spawns blank avatar on description fetch failures.
-- Strict lifecycle integrity: RF-F21, RF-F23 safe character replacement and bounded backoff.
-- Edge cases resolved: separate activeRequestGeneration vs committedCharacterGeneration; dead-char check on failure.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local R15AvatarConfigs = require(Shared:WaitForChild("configs"):WaitForChild("R15AvatarConfigs"))

local activeRequestGeneration: { [number]: number } = {}
local committedCharacterGeneration: { [number]: number } = {}
local characterConnections: { [number]: { RBXScriptConnection } } = {}
local lastValidatedDescription: { [number]: HumanoidDescription } = {}
local retryAttempts: { [number]: number } = {}
local isInitialized = false

local R15AvatarService = {}

local function cleanupCharacterConnections(userId: number)
	local conns = characterConnections[userId]
	if conns then
		for _, conn in ipairs(conns) do
			conn:Disconnect()
		end
	end
	characterConnections[userId] = {}
end

local function getPrimaryFloor(): Part?
	local arena = Workspace:FindFirstChild("HexCageArena")
	if arena then
		local floor = arena:FindFirstChild("CageFloor")
		if floor and floor:IsA("Part") then
			return floor
		end
	end
	local directFloor = Workspace:FindFirstChild("CageFloor")
	if directFloor and directFloor:IsA("Part") then
		return directFloor
	end
	return nil
end

local function calculateSpawnCFrame(): CFrame
	local floor = getPrimaryFloor()
	if floor then
		local floorTopY = floor.Position.Y + (floor.Size.Y / 2)
		local spawnY = floorTopY + R15AvatarConfigs.SPAWN_HEIGHT_OFFSET
		return CFrame.new(0, spawnY, 0)
	end
	return CFrame.new(0, 4.5, 0)
end

function R15AvatarService.SpawnAvatarForPlayer(player: Player, isRetry: boolean?): Model?
	local userId = player.UserId

	-- Edge Case 1: Separate request generation from committed character generation
	local thisRequest = (activeRequestGeneration[userId] or 0) + 1
	activeRequestGeneration[userId] = thisRequest

	if not isRetry then
		retryAttempts[userId] = 0
	end

	-- RF-F21: Do NOT disconnect previous character connections at spawn entry!
	-- Previous character's lifecycle and respawn handlers remain active until replacement is fully validated.

	-- 1. Fetch user's own HumanoidDescription (yielding call)
	local desc: HumanoidDescription? = nil
	local okDesc, fetchedDesc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
	end)

	-- RF-F21: Generation check after description fetch yield
	if activeRequestGeneration[userId] ~= thisRequest or not player:IsDescendantOf(Players) then
		return nil
	end

	if okDesc and fetchedDesc and fetchedDesc:IsA("HumanoidDescription") then
		desc = fetchedDesc
	elseif lastValidatedDescription[userId] then
		-- Safe fallback: reuse last validated avatar description on transient fetch failures
		desc = lastValidatedDescription[userId]:Clone()
		warn(string.format("[R15AvatarService] Identity fetch failed for %s (%d); reusing last validated description", player.Name, userId))
	else
		-- RF-F23: Initial fetch failed with no cached description. Apply bounded backoff retry.
		local attempt = (retryAttempts[userId] or 0) + 1
		retryAttempts[userId] = attempt
		if attempt <= R15AvatarConfigs.MAX_ACQUISITION_RETRIES then
			local backoffSec = R15AvatarConfigs.RETRY_BASE_DELAY_SEC * attempt
			warn(string.format("[R15AvatarService] Identity fetch failed for %s (%d); retry %d/%d in %.1fs",
				player.Name, userId, attempt, R15AvatarConfigs.MAX_ACQUISITION_RETRIES, backoffSec))
			task.delay(backoffSec, function()
				if player:IsDescendantOf(Players) and activeRequestGeneration[userId] == thisRequest then
					R15AvatarService.SpawnAvatarForPlayer(player, true)
				end
			end)
			return nil
		else
			-- Explicit non-gameplay failure state: never spawn blank gameplay avatar
			warn(string.format("[R15AvatarService] Identity fetch exhausted all %d retries for %s (%d); entering explicit non-gameplay state (no blank avatar)",
				R15AvatarConfigs.MAX_ACQUISITION_RETRIES, player.Name, userId))
			return nil
		end
	end

	-- 2. Apply canonical ROBLOX Boy body limbs and normalize scales (+30% height, width/depth 1.0)
	local validDesc = R15AvatarConfigs.ApplyBoyBodyAndNormalize(desc :: HumanoidDescription)

	-- 3. Create R15 Humanoid Model from description (yielding call)
	local okModel, charModel = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(validDesc, Enum.HumanoidRigType.R15)
	end)

	-- RF-F21: Generation check after model creation yield; cleanup superseded candidate if stale
	if activeRequestGeneration[userId] ~= thisRequest or not player:IsDescendantOf(Players) then
		if okModel and charModel and charModel:IsA("Model") then
			charModel:Destroy()
		end
		return nil
	end

	-- 4. Validation before replacing previous character
	local humanoid: Humanoid? = nil
	local rootPart: BasePart? = nil

	if okModel and charModel and charModel:IsA("Model") then
		humanoid = charModel:FindFirstChildOfClass("Humanoid")
		rootPart = charModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	end

	if not okModel or not charModel or not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 or not rootPart then
		if okModel and charModel and charModel:IsA("Instance") then
			charModel:Destroy()
		end

		-- Edge Case 2: Only retain existing character if it is genuinely ALIVE and in Workspace!
		-- Dead old characters (e.g. during respawn) must NOT shortcircuit bounded retry.
		local existingChar = player.Character
		local existingHum = existingChar and existingChar:FindFirstChildOfClass("Humanoid")
		local isExistingAlive = existingHum ~= nil
			and existingHum.Health > 0
			and existingChar:IsDescendantOf(Workspace)

		if isExistingAlive then
			warn(string.format("[R15AvatarService] Candidate model validation failed for %s (%d); retaining existing alive character", player.Name, userId))
			return nil
		end

		-- RF-F23: First join or respawn candidate model creation failed. Apply bounded backoff retry.
		local attempt = (retryAttempts[userId] or 0) + 1
		retryAttempts[userId] = attempt
		if attempt <= R15AvatarConfigs.MAX_ACQUISITION_RETRIES then
			local backoffSec = R15AvatarConfigs.RETRY_BASE_DELAY_SEC * attempt
			warn(string.format("[R15AvatarService] Candidate model creation failed for %s (%d); retry %d/%d in %.1fs",
				player.Name, userId, attempt, R15AvatarConfigs.MAX_ACQUISITION_RETRIES, backoffSec))
			task.delay(backoffSec, function()
				if player:IsDescendantOf(Players) and activeRequestGeneration[userId] == thisRequest then
					R15AvatarService.SpawnAvatarForPlayer(player, true)
				end
			end)
			return nil
		else
			warn(string.format("[R15AvatarService] Model creation exhausted all %d retries for %s (%d); entering explicit non-gameplay state",
				R15AvatarConfigs.MAX_ACQUISITION_RETRIES, player.Name, userId))
			return nil
		end
	end

	-- 5. RF-F21 COMMIT GATE: Candidate model is 100% valid and verified for active request
	-- Safe character replacement: disconnect previous connections and commit cache ONLY now
	cleanupCharacterConnections(userId)
	lastValidatedDescription[userId] = validDesc:Clone()
	retryAttempts[userId] = 0

	-- Edge Case 1: Advance committed character generation token for the new character
	local thisCommitGen = (committedCharacterGeneration[userId] or 0) + 1
	committedCharacterGeneration[userId] = thisCommitGen

	charModel.Name = player.Name
	charModel:SetAttribute("IsR15PlayerAvatar", true)
	charModel:SetAttribute("AvatarUserId", userId)
	charModel:SetAttribute("RigType", "R15")
	charModel:SetAttribute("BodyPackage", "ROBLOX Boy")

	-- 6. Position model on CageFloor
	local spawnCFrame = calculateSpawnCFrame()
	charModel:PivotTo(spawnCFrame)

	-- 7. Destroy previous character only after new model is fully validated and positioned
	local previousChar = player.Character
	if previousChar then
		previousChar:Destroy()
	end

	-- 8. Parent model to Workspace and assign player.Character
	charModel.Parent = Workspace
	player.Character = charModel

	-- 9. Configure Humanoid properties
	humanoid.DisplayName = player.DisplayName
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
	humanoid.WalkSpeed = 16
	humanoid.HipHeight = R15AvatarConfigs.CANONICAL_HIP_HEIGHT

	-- 10. Bind respawn lifecycle on death to committed character generation token
	local diedConn = humanoid.Died:Connect(function()
		task.wait(R15AvatarConfigs.RESPAWN_DELAY_SEC)
		if player:IsDescendantOf(Players) and committedCharacterGeneration[userId] == thisCommitGen then
			R15AvatarService.SpawnAvatarForPlayer(player)
		end
	end)
	table.insert(characterConnections[userId], diedConn)

	return charModel
end

local function onPlayerAdded(player: Player)
	R15AvatarService.SpawnAvatarForPlayer(player)
end

local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	activeRequestGeneration[userId] = nil
	committedCharacterGeneration[userId] = nil
	lastValidatedDescription[userId] = nil
	retryAttempts[userId] = nil
	cleanupCharacterConnections(userId)
end

function R15AvatarService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Ensure Roblox native character auto-loads is disabled (we control the R15 spawn lifecycle)
	Players.CharacterAutoLoads = false

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			onPlayerAdded(player)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return table.freeze(R15AvatarService)
