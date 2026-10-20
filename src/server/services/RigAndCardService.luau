--!strict
-- src/server/services/RigAndCardService.luau
-- Module 00 (run-02 Fixed):
-- [FIX-M00-01] Sets Humanoid.AutomaticScalingEnabled = false, stores scales as Attributes (no NumberValue double-scaling),
--              and scales Motor6D.C0 by Part0 scale and Motor6D.C1 by Part1 scale so Neck/Head never detach.
-- [FIX-M00-02] Auto-respawns Custom Rig on Humanoid.Died (2.0s delay). Inventory gameplay listener decoupled per Module 00 scope.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local CardConfigs = require(Shared:WaitForChild("configs"):WaitForChild("CardConfigs"))

export type RigPartSpec = {
	name: string,
	size: Vector3,
	parentName: string?,
	jointName: string?,
	c0: CFrame?,
	c1: CFrame?,
	canCollide: boolean,
	transparency: number,
}

local R6_PART_SPECS: { RigPartSpec } = table.freeze({
	{
		name = "HumanoidRootPart",
		size = Vector3.new(2.0, 2.0, 1.0),
		parentName = nil,
		jointName = nil,
		c0 = nil,
		c1 = nil,
		canCollide = false,
		transparency = 1,
	},
	{
		name = "Torso",
		size = Vector3.new(2.0, 2.0, 1.0),
		parentName = "HumanoidRootPart",
		jointName = "RootJoint",
		c0 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		c1 = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		canCollide = true,
		transparency = 0,
	},
	{
		name = "Head",
		size = Vector3.new(2.0, 1.0, 1.0),
		parentName = "Torso",
		jointName = "Neck",
		c0 = CFrame.new(0, 1.0, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		c1 = CFrame.new(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0),
		canCollide = false,
		transparency = 0,
	},
	{
		name = "Right Arm",
		size = Vector3.new(1.0, 2.0, 1.0),
		parentName = "Torso",
		jointName = "Right Shoulder",
		c0 = CFrame.new(1.0, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		c1 = CFrame.new(-0.5, 0.5, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		canCollide = false,
		transparency = 0,
	},
	{
		name = "Left Arm",
		size = Vector3.new(1.0, 2.0, 1.0),
		parentName = "Torso",
		jointName = "Left Shoulder",
		c0 = CFrame.new(-1.0, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		c1 = CFrame.new(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		canCollide = false,
		transparency = 0,
	},
	{
		name = "Right Leg",
		size = Vector3.new(1.0, 2.0, 1.0),
		parentName = "Torso",
		jointName = "Right Hip",
		c0 = CFrame.new(1.0, -1.0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		c1 = CFrame.new(0.5, 1.0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0),
		canCollide = false,
		transparency = 0,
	},
	{
		name = "Left Leg",
		size = Vector3.new(1.0, 2.0, 1.0),
		parentName = "Torso",
		jointName = "Left Hip",
		c0 = CFrame.new(-1.0, -1.0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		c1 = CFrame.new(-0.5, 1.0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
		canCollide = false,
		transparency = 0,
	},
})

local playerEquippedCardByUserId: { [number]: string } = {}
local playerListeners: { [number]: { RBXScriptConnection } } = {}
local characterConnections: { [number]: { RBXScriptConnection } } = {}
local playerGeneration: { [number]: number } = {}
local isInitialized = false

local RigAndCardService = {}

local function scaleCFrameOffset(baseCFrame: CFrame, scaleVec: Vector3): CFrame
	local pos = baseCFrame.Position
	local rot = baseCFrame.Rotation
	local scaledPos = Vector3.new(pos.X * scaleVec.X, pos.Y * scaleVec.Y, pos.Z * scaleVec.Z)
	return CFrame.new(scaledPos) * rot
end

local function lockAnimeFaceOnHead(head: BasePart)
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("Decal") then
			child:Destroy()
		end
	end
	local animeFace = Instance.new("Decal")
	animeFace.Name = "AnimeFaceDecal"
	animeFace.Face = Enum.NormalId.Front
	animeFace.Texture = Constants.ANIME_FACE_DECAL_ID
	animeFace.Parent = head
end

function RigAndCardService.CreateOrGetTemplate(): Model
	local existing = ServerStorage:FindFirstChild(Constants.CUSTOM_RIG_MODEL_NAME)
	if existing and existing:IsA("Model") then
		return existing
	end

	local template = Instance.new("Model")
	template.Name = Constants.CUSTOM_RIG_MODEL_NAME
	template:SetAttribute("IsStandardCustomRig", true)
	template:SetAttribute("UsesPlayerAvatar", false)
	template:SetAttribute("RigProfile", Constants.RIG_PROFILE)
	template:SetAttribute("RigSchemaVersion", Constants.RIG_SCHEMA_VERSION)
	template:SetAttribute("AnimeFaceLocked", true)

	local partsByName: { [string]: Part } = {}

	for _, spec in ipairs(R6_PART_SPECS) do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Size = spec.size
		part.Anchored = false
		part.CanCollide = spec.canCollide
		part.Transparency = spec.transparency
		part.Massless = (spec.name ~= "HumanoidRootPart")
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part:SetAttribute("BaseSize", spec.size)

		if spec.name == "HumanoidRootPart" then
			part.CFrame = CFrame.new(0, 5, 0)
		elseif spec.name == "Head" then
			local mesh = Instance.new("SpecialMesh")
			mesh.Name = "Mesh"
			mesh.MeshType = Enum.MeshType.Head
			mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
			mesh.Parent = part
			lockAnimeFaceOnHead(part)
		end

		part.Parent = template
		partsByName[spec.name] = part
	end

	for _, spec in ipairs(R6_PART_SPECS) do
		if spec.parentName and spec.jointName and spec.c0 and spec.c1 then
			local part0 = partsByName[spec.parentName]
			local part1 = partsByName[spec.name]
			if part0 and part1 then
				local motor = Instance.new("Motor6D")
				motor.Name = spec.jointName
				motor.Part0 = part0
				motor.Part1 = part1
				motor.C0 = spec.c0
				motor.C1 = spec.c1
				motor:SetAttribute("BaseC0", spec.c0)
				motor:SetAttribute("BaseC1", spec.c1)
				motor.Parent = if spec.name == "Torso" then partsByName["HumanoidRootPart"] else partsByName["Torso"]
				part1.CFrame = part0.CFrame * spec.c0 * spec.c1:Inverse()
			end
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.AutomaticScalingEnabled = false
	humanoid.HipHeight = Constants.DEFAULT_HIP_HEIGHT
	humanoid:SetAttribute("BaseHipHeight", Constants.DEFAULT_HIP_HEIGHT)
	humanoid.Parent = template

	local animator = Instance.new("Animator")
	animator.Name = "Animator"
	animator.Parent = humanoid

	template.PrimaryPart = partsByName["HumanoidRootPart"]
	template.Parent = ServerStorage

	return template
end

function RigAndCardService.BuildStandardCustomRig(characterName: string): Model
	local template = RigAndCardService.CreateOrGetTemplate()
	local cloned = template:Clone()
	cloned.Name = characterName
	cloned:SetAttribute("IsStandardCustomRig", true)
	cloned:SetAttribute("UsesPlayerAvatar", false)
	cloned:SetAttribute("RigProfile", Constants.RIG_PROFILE)
	cloned:SetAttribute("RigSchemaVersion", Constants.RIG_SCHEMA_VERSION)
	cloned:SetAttribute("AnimeFaceLocked", true)
	cloned.PrimaryPart = cloned:FindFirstChild("HumanoidRootPart") :: BasePart
	local clonedHum = cloned:FindFirstChildOfClass("Humanoid")
	if clonedHum then
		clonedHum.AutomaticScalingEnabled = false
		clonedHum.RigType = Enum.HumanoidRigType.R6
	end
	return cloned
end

function RigAndCardService.ApplyCardScale(rigModel: Model, cardId: string?): boolean
	local isCustomRig = rigModel:GetAttribute("IsStandardCustomRig") == true
	if not isCustomRig then
		return false
	end

	local cardConfig = CardConfigs.GetCardConfig(cardId)
	local scaleCfg = cardConfig.rigScale
	local clampedHeight = math.clamp(
		scaleCfg.heightScale,
		Constants.MIN_HEIGHT_SCALE,
		Constants.MAX_HEIGHT_SCALE
	)
	local clampedWidth = math.clamp(scaleCfg.widthScale, 0.85, 1.15)
	local clampedDepth = math.clamp(scaleCfg.depthScale, 0.85, 1.15)
	local clampedHead = math.clamp(scaleCfg.headScale, 0.85, 1.15)

	local bodyScaleVec = Vector3.new(clampedWidth, clampedHeight, clampedDepth)
	local headScaleVec = Vector3.new(clampedHead, clampedHead, clampedHead)

	local function getScaleVecForPart(part: BasePart?): Vector3
		if part and part.Name == "Head" then
			return headScaleVec
		end
		return bodyScaleVec
	end

	for _, inst in ipairs(rigModel:GetDescendants()) do
		if inst:IsA("BasePart") then
			local baseSizeAttr = inst:GetAttribute("BaseSize")
			local baseSize = if typeof(baseSizeAttr) == "Vector3" then baseSizeAttr else inst.Size
			if typeof(baseSizeAttr) ~= "Vector3" then
				inst:SetAttribute("BaseSize", baseSize)
			end

			local partScale = getScaleVecForPart(inst)
			inst.Size = Vector3.new(
				baseSize.X * partScale.X,
				baseSize.Y * partScale.Y,
				baseSize.Z * partScale.Z
			)
		elseif inst:IsA("Motor6D") then
			local baseC0Attr = inst:GetAttribute("BaseC0")
			local baseC1Attr = inst:GetAttribute("BaseC1")
			local baseC0 = if typeof(baseC0Attr) == "CFrame" then baseC0Attr else inst.C0
			local baseC1 = if typeof(baseC1Attr) == "CFrame" then baseC1Attr else inst.C1
			if typeof(baseC0Attr) ~= "CFrame" then
				inst:SetAttribute("BaseC0", baseC0)
			end
			if typeof(baseC1Attr) ~= "CFrame" then
				inst:SetAttribute("BaseC1", baseC1)
			end
			-- [FIX-M00-01] Scale C0 by Part0's scale and C1 by Part1's scale so Neck.C1 uses headScaleVec
			inst.C0 = scaleCFrameOffset(baseC0, getScaleVecForPart(inst.Part0))
			inst.C1 = scaleCFrameOffset(baseC1, getScaleVecForPart(inst.Part1))
		end
	end

	local humanoid = rigModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutomaticScalingEnabled = false
		humanoid.RigType = Enum.HumanoidRigType.R6
		humanoid:SetAttribute("BodyHeightScale", clampedHeight)
		humanoid:SetAttribute("BodyWidthScale", clampedWidth)
		humanoid:SetAttribute("BodyDepthScale", clampedDepth)
		humanoid:SetAttribute("HeadScale", clampedHead)
		humanoid:SetAttribute("BodyProportionScale", scaleCfg.proportionScale)
		humanoid:SetAttribute("BodyTypeScale", 0)
		local baseHipHeightAttr = humanoid:GetAttribute("BaseHipHeight")
		local baseHipHeight = if typeof(baseHipHeightAttr) == "number" then baseHipHeightAttr else Constants.DEFAULT_HIP_HEIGHT
		humanoid.HipHeight = baseHipHeight * clampedHeight
	end

	rigModel:SetAttribute("EquippedCardId", cardConfig.cardId)
	rigModel:SetAttribute("ArchetypeName", cardConfig.archetypeName)
	rigModel:SetAttribute("CardTier", cardConfig.tier)
	rigModel:SetAttribute("HeightScale", clampedHeight)
	rigModel:SetAttribute("WidthScale", clampedWidth)

	return true
end

function RigAndCardService.GetStandingHeight(rigModel: Model): number
	local leftLeg = rigModel:FindFirstChild("Left Leg") :: BasePart?
	local hrp = rigModel:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = rigModel:FindFirstChildOfClass("Humanoid")
	local legHeight = if leftLeg then leftLeg.Size.Y else 2.0
	local hrpHeight = if hrp then hrp.Size.Y else 2.0
	local hipHeight = if hum then hum.HipHeight else Constants.DEFAULT_HIP_HEIGHT
	return legHeight + (hrpHeight / 2) + hipHeight
end

local function resolveInstanceByPath(pathStr: string): Instance?
	local parts = string.split(pathStr, ".")
	local current: Instance? = nil
	local startIndex = 1
	if parts[1] == "Workspace" or parts[1] == "workspace" then
		current = Workspace
		startIndex = 2
	elseif parts[1] == "ReplicatedStorage" then
		current = ReplicatedStorage
		startIndex = 2
	elseif parts[1] == "ServerStorage" then
		current = ServerStorage
		startIndex = 2
	else
		current = game:FindFirstChild(parts[1])
		startIndex = 2
	end

	for i = startIndex, #parts do
		if not current then
			return nil
		end
		current = current:FindFirstChild(parts[i])
	end
	return current
end

local function validateFloorPart(inst: Instance, pathName: string): (boolean, string?)
	if not inst:IsA("BasePart") then
		return false, string.format("Instance at %s is a %s, expected BasePart", pathName, inst.ClassName)
	end
	local part = inst :: BasePart
	if not part.Anchored then
		return false, string.format("Floor %s is unanchored (Anchored = false)", pathName)
	end
	if not part.CanCollide then
		return false, string.format("Floor %s is non-collidable (CanCollide = false)", pathName)
	end
	if not part.CanQuery then
		return false, string.format("Floor %s has spatial queries disabled (CanQuery = false)", pathName)
	end
	if part.Size.X < 4.0 or part.Size.Z < 4.0 or part.Size.Y < 0.1 then
		return false, string.format("Floor %s size (%.1f, %.1f, %.1f) is insufficient for rig footprint support (min 4x0.1x4)", pathName, part.Size.X, part.Size.Y, part.Size.Z)
	end
	return true, nil
end

function RigAndCardService.GetPrimaryFloor(): BasePart
	-- 1. Try explicit PRIMARY_FLOOR_PATH
	local primaryInst = resolveInstanceByPath(Constants.PRIMARY_FLOOR_PATH)
	if primaryInst ~= nil then
		local isValid, reason = validateFloorPart(primaryInst, Constants.PRIMARY_FLOOR_PATH)
		if isValid then
			return primaryInst :: BasePart
		else
			error(string.format("[RigAndCardService] Primary floor at %s is invalid: %s", Constants.PRIMARY_FLOOR_PATH, tostring(reason)))
		end
	end

	-- 2. Try explicit FALLBACK_FLOOR_PATH if primary does not exist
	local fallbackInst = resolveInstanceByPath(Constants.FALLBACK_FLOOR_PATH)
	if fallbackInst ~= nil then
		local isValid, reason = validateFloorPart(fallbackInst, Constants.FALLBACK_FLOOR_PATH)
		if isValid then
			return fallbackInst :: BasePart
		else
			error(string.format("[RigAndCardService] Fallback floor at %s is invalid: %s", Constants.FALLBACK_FLOOR_PATH, tostring(reason)))
		end
	end

	-- 3. In Module 00 bootstrap on a blank place (neither primary nor fallback exists), create approved BootstrapTestFloor fixture
	local floor = Instance.new("Part")
	floor.Name = "BootstrapTestFloor"
	floor.Size = Constants.BOOTSTRAP_FLOOR_SIZE
	floor.CFrame = CFrame.new(Constants.BOOTSTRAP_FLOOR_POSITION)
	floor.Anchored = true
	floor.CanCollide = true
	floor.CanQuery = true
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Material = Enum.Material.SmoothPlastic
	floor.Color = Color3.fromRGB(50, 50, 50)
	floor.Parent = Workspace

	local isValid, reason = validateFloorPart(floor, "Workspace.BootstrapTestFloor")
	assert(isValid, string.format("[RigAndCardService] Newly created BootstrapTestFloor failed validation: %s", tostring(reason)))

	local spawnInst = resolveInstanceByPath(Constants.PRIMARY_SPAWN_PATH)
	if not spawnInst then
		local spawnLoc = Instance.new("SpawnLocation")
		spawnLoc.Name = "BootstrapSpawnLocation"
		spawnLoc.Size = Vector3.new(6, 0.2, 6)
		spawnLoc.CFrame = CFrame.new(0, 0.1, 0)
		spawnLoc.Anchored = true
		spawnLoc.CanCollide = false
		spawnLoc.Enabled = true
		spawnLoc.Duration = 0
		spawnLoc.Parent = Workspace
	end

	return floor
end

local function calculateSpawnCFrame(floor: BasePart, previousChar: Model?, scaleHeight: number): CFrame
	local isFloorValid, floorReason = validateFloorPart(floor, floor.Name)
	if not isFloorValid then
		error(string.format("[RigAndCardService] Cannot calculate spawn CFrame: floor %s is invalid: %s", floor.Name, tostring(floorReason)))
	end

	local clampedScaleHeight = math.clamp(
		scaleHeight,
		Constants.MIN_HEIGHT_SCALE,
		Constants.MAX_HEIGHT_SCALE
	)
	local halfX = floor.Size.X / 2
	local halfZ = floor.Size.Z / 2
	local rigFootprintMargin = 2.0

	-- Compute bounding extent in world Y to guarantee ray starts above and shoots past the floor even if oriented
	local halfHeightExtent = (math.abs(floor.CFrame.RightVector.Y) * floor.Size.X + math.abs(floor.CFrame.UpVector.Y) * floor.Size.Y + math.abs(floor.CFrame.LookVector.Y) * floor.Size.Z) / 2
	local rayTopY = floor.Position.Y + halfHeightExtent + 20.0
	local rayLength = (halfHeightExtent * 2) + 40.0

	local function tryCandidate(candX: number, candZ: number, candidateLabel: string): (CFrame?, string?)
		local rayOrigin = Vector3.new(candX, rayTopY, candZ)
		local rayDirection = Vector3.new(0, -rayLength, 0)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = { floor }

		local rayResult = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
		if not rayResult then
			return nil, string.format("%s: raycast from Y=%.1f downwards did not intersect floor %s", candidateLabel, rayOrigin.Y, floor.Name)
		end

		if rayResult.Instance ~= floor and not rayResult.Instance:IsDescendantOf(floor) then
			return nil, string.format("%s: raycast hit instance %s instead of target floor %s", candidateLabel, rayResult.Instance.Name, floor.Name)
		end

		-- Verify hit surface normal faces upward (upright support surface, normal.Y >= 0.70)
		if rayResult.Normal.Y < 0.70 then
			return nil, string.format("%s: surface normal Y (%.2f) is too steep to support rig (requires >= 0.70)", candidateLabel, rayResult.Normal.Y)
		end

		-- Verify hit point is within floor footprint margin in floor local coordinates (supports oriented/tilted floors)
		local hitLocalPos = floor.CFrame:PointToObjectSpace(rayResult.Position)
		if math.abs(hitLocalPos.X) > (halfX - rigFootprintMargin) then
			return nil, string.format("%s: candidate hit local X (%.2f) exceeds half-width margin (%.2f)", candidateLabel, math.abs(hitLocalPos.X), halfX - rigFootprintMargin)
		end
		if math.abs(hitLocalPos.Z) > (halfZ - rigFootprintMargin) then
			return nil, string.format("%s: candidate hit local Z (%.2f) exceeds half-depth margin (%.2f)", candidateLabel, math.abs(hitLocalPos.Z), halfZ - rigFootprintMargin)
		end

		local floorTopY = rayResult.Position.Y
		local leftLegHeight = 2.0 * clampedScaleHeight
		local hrpHeight = 2.0 * clampedScaleHeight
		local hipHeight = Constants.DEFAULT_HIP_HEIGHT * clampedScaleHeight
		local standingHeight = leftLegHeight + (hrpHeight / 2) + hipHeight
		local spawnClearance = 0.05
		local spawnY = floorTopY + standingHeight + spawnClearance

		return CFrame.new(candX, spawnY, candZ), nil
	end

	local rejectionReasons: { string } = {}

	-- Candidate 1: Previous character position ONLY IF STILL ALIVE and within floor bounds
	if previousChar and previousChar.PrimaryPart then
		local prevHum = previousChar:FindFirstChildOfClass("Humanoid")
		local isAlive = prevHum ~= nil and prevHum.Health > 0 and prevHum:GetState() ~= Enum.HumanoidStateType.Dead
		if isAlive and previousChar.PrimaryPart.Position.Y >= (floor.Position.Y - 5) then
			local result, rejectReason = tryCandidate(previousChar.PrimaryPart.Position.X, previousChar.PrimaryPart.Position.Z, "PreviousAliveChar")
			if result then
				return result
			elseif rejectReason then
				table.insert(rejectionReasons, rejectReason)
			end
		else
			table.insert(rejectionReasons, "PreviousAliveChar: character is dead, missing Humanoid, or below floor")
		end
	end

	-- Candidate 2: Primary spawn path location if available
	local spawnInst = resolveInstanceByPath(Constants.PRIMARY_SPAWN_PATH)
	if spawnInst then
		local spawnPart: BasePart? = if spawnInst:IsA("BasePart")
			then spawnInst
			elseif spawnInst:IsA("Model") then spawnInst.PrimaryPart
			else nil
		if spawnPart then
			local result, rejectReason = tryCandidate(spawnPart.Position.X, spawnPart.Position.Z, "PrimarySpawnLocation")
			if result then
				return result
			elseif rejectReason then
				table.insert(rejectionReasons, rejectReason)
			end
		else
			table.insert(rejectionReasons, "PrimarySpawnLocation: instance is not a BasePart or Model with PrimaryPart")
		end
	end

	-- Candidate 3: Center of floor
	local centerResult, centerRejectReason = tryCandidate(floor.Position.X, floor.Position.Z, "FloorCenter")
	if centerResult then
		return centerResult
	elseif centerRejectReason then
		table.insert(rejectionReasons, centerRejectReason)
	end

	error(string.format(
		"[RigAndCardService] Unable to find valid spawn location on primary floor %s. Rejection log:\n  - %s",
		floor.Name,
		table.concat(rejectionReasons, "\n  - ")
	))
end

function RigAndCardService.SpawnCustomRigForPlayer(player: Player, cardId: string?): Model
	local userId = player.UserId
	local nextGen = (playerGeneration[userId] or 0) + 1
	playerGeneration[userId] = nextGen
	local thisGen = nextGen

	-- Disconnect previous character connections for this user (separate from player listeners)
	local existingConns = characterConnections[userId]
	if existingConns then
		for _, conn in ipairs(existingConns) do
			conn:Disconnect()
		end
		characterConnections[userId] = {}
	else
		characterConnections[userId] = {}
	end

	local selectedCardId = cardId or playerEquippedCardByUserId[userId] or Constants.DEFAULT_CARD_ID
	playerEquippedCardByUserId[userId] = selectedCardId

	local previousChar = player.Character
	local floor = RigAndCardService.GetPrimaryFloor()
	local cardConfig = CardConfigs.GetCardConfig(selectedCardId)
	local spawnCFrame = calculateSpawnCFrame(floor, previousChar, cardConfig.rigScale.heightScale)

	local customRig = RigAndCardService.BuildStandardCustomRig(player.Name)
	RigAndCardService.ApplyCardScale(customRig, selectedCardId)

	if customRig.PrimaryPart then
		customRig:PivotTo(spawnCFrame)
	end

	-- Died connection with generation race guard
	local humanoid = customRig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local diedConn = humanoid.Died:Connect(function()
			task.delay(2.0, function()
				if player.Parent ~= nil and playerGeneration[userId] == thisGen then
					RigAndCardService.SpawnCustomRigForPlayer(player, playerEquippedCardByUserId[userId])
				end
			end)
		end)
		table.insert(characterConnections[userId], diedConn)
	end

	-- Out-of-bounds fall detection
	local hrp = customRig.PrimaryPart
	if hrp then
		local fallConn: RBXScriptConnection? = nil
		local RunService = game:GetService("RunService")
		fallConn = RunService.Heartbeat:Connect(function()
			if not customRig.Parent or playerGeneration[userId] ~= thisGen then
				if fallConn then
					fallConn:Disconnect()
				end
				return
			end
			if hrp.Position.Y < (floor.Position.Y - 50) then
				if fallConn then
					fallConn:Disconnect()
				end
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
				end
			end
		end)
		if fallConn then
			table.insert(characterConnections[userId], fallConn)
		end
	end

	customRig.Parent = Workspace
	player.Character = customRig

	if previousChar and previousChar ~= customRig then
		previousChar:Destroy()
	end

	return customRig
end

function RigAndCardService.EquipCardForPlayer(player: Player, cardId: string): boolean
	if CardConfigs.Cards[cardId] == nil then
		return false
	end
	local cardConfig = CardConfigs.GetCardConfig(cardId)
	playerEquippedCardByUserId[player.UserId] = cardConfig.cardId

	local currentChar = player.Character
	if currentChar and currentChar:GetAttribute("IsStandardCustomRig") == true then
		return RigAndCardService.ApplyCardScale(currentChar, cardConfig.cardId)
	end

	RigAndCardService.SpawnCustomRigForPlayer(player, cardConfig.cardId)
	return true
end

function RigAndCardService.GetEquippedCardId(userId: number): string
	return playerEquippedCardByUserId[userId] or Constants.DEFAULT_CARD_ID
end

function RigAndCardService.GetEquippedCardConfig(userId: number): CardConfigs.PlayerCardConfig
	local cardId = RigAndCardService.GetEquippedCardId(userId)
	return CardConfigs.GetCardConfig(cardId)
end

local function onPlayerAdded(player: Player)
	local userId = player.UserId
	playerEquippedCardByUserId[userId] = Constants.DEFAULT_CARD_ID
	playerListeners[userId] = {}
	characterConnections[userId] = {}

	local charAddedConn = player.CharacterAdded:Connect(function(character: Model)
		if character:GetAttribute("IsStandardCustomRig") ~= true then
			task.defer(function()
				if player.Parent ~= nil and player.Character == character then
					RigAndCardService.SpawnCustomRigForPlayer(player, playerEquippedCardByUserId[userId])
				end
			end)
		end
	end)
	table.insert(playerListeners[userId], charAddedConn)

	RigAndCardService.SpawnCustomRigForPlayer(player, Constants.DEFAULT_CARD_ID)
end

local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	playerGeneration[userId] = (playerGeneration[userId] or 0) + 1

	local charConns = characterConnections[userId]
	if charConns then
		for _, conn in ipairs(charConns) do
			conn:Disconnect()
		end
		characterConnections[userId] = nil
	end

	local pListeners = playerListeners[userId]
	if pListeners then
		for _, conn in ipairs(pListeners) do
			conn:Disconnect()
		end
		playerListeners[userId] = nil
	end

	playerEquippedCardByUserId[userId] = nil
	playerGeneration[userId] = nil
end

function RigAndCardService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.CharacterAutoLoads = false

	-- Ensure R6 template and primary floor exist
	RigAndCardService.CreateOrGetTemplate()
	RigAndCardService.GetPrimaryFloor()

	-- Note: InventoryEquipRequest handler is deferred to Phase 2 per Module 00 scope.
	-- Server fixture / EquipCardForPlayer API is used for preset testing.

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, existingPlayer)
	end
end

return table.freeze(RigAndCardService)
