--!strict
-- src/server/services/RigAndCardService.luau
-- Module 00 (run-02 Fixed):
-- [FIX-M00-01] Sets Humanoid.AutomaticScalingEnabled = false, stores scales as Attributes (no NumberValue double-scaling),
--              and scales Motor6D.C0 by Part0 scale and Motor6D.C1 by Part1 scale so Neck/Head never detach.
-- [FIX-M00-02] Auto-respawns Custom Rig on Humanoid.Died (2.0s delay) and connects InventoryEquipRequest for "Card".

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
}

local R15_PART_SPECS: { RigPartSpec } = table.freeze({
	{
		name = "HumanoidRootPart",
		size = Vector3.new(2.0, 2.0, 1.0),
		parentName = nil,
		jointName = nil,
		c0 = nil,
		c1 = nil,
	},
	{
		name = "LowerTorso",
		size = Vector3.new(2.0, 0.4, 1.0),
		parentName = "HumanoidRootPart",
		jointName = "Root",
		c0 = CFrame.new(0, -0.8, 0),
		c1 = CFrame.new(0, 0, 0),
	},
	{
		name = "UpperTorso",
		size = Vector3.new(2.0, 1.6, 1.0),
		parentName = "LowerTorso",
		jointName = "Waist",
		c0 = CFrame.new(0, 0.2, 0),
		c1 = CFrame.new(0, -0.8, 0),
	},
	{
		name = "Head",
		size = Vector3.new(1.2, 1.2, 1.2),
		parentName = "UpperTorso",
		jointName = "Neck",
		c0 = CFrame.new(0, 0.8, 0),
		c1 = CFrame.new(0, -0.6, 0),
	},
	{
		name = "LeftUpperArm",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "UpperTorso",
		jointName = "LeftShoulder",
		c0 = CFrame.new(-1.5, 0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "LeftLowerArm",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "LeftUpperArm",
		jointName = "LeftElbow",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "LeftHand",
		size = Vector3.new(1.0, 0.4, 1.0),
		parentName = "LeftLowerArm",
		jointName = "LeftWrist",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.2, 0),
	},
	{
		name = "RightUpperArm",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "UpperTorso",
		jointName = "RightShoulder",
		c0 = CFrame.new(1.5, 0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "RightLowerArm",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "RightUpperArm",
		jointName = "RightElbow",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "RightHand",
		size = Vector3.new(1.0, 0.4, 1.0),
		parentName = "RightLowerArm",
		jointName = "RightWrist",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.2, 0),
	},
	{
		name = "LeftUpperLeg",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "LowerTorso",
		jointName = "LeftHip",
		c0 = CFrame.new(-0.5, -0.2, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "LeftLowerLeg",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "LeftUpperLeg",
		jointName = "LeftKnee",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "LeftFoot",
		size = Vector3.new(1.0, 0.4, 1.0),
		parentName = "LeftLowerLeg",
		jointName = "LeftAnkle",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.2, 0),
	},
	{
		name = "RightUpperLeg",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "LowerTorso",
		jointName = "RightHip",
		c0 = CFrame.new(0.5, -0.2, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "RightLowerLeg",
		size = Vector3.new(1.0, 0.8, 1.0),
		parentName = "RightUpperLeg",
		jointName = "RightKnee",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.4, 0),
	},
	{
		name = "RightFoot",
		size = Vector3.new(1.0, 0.4, 1.0),
		parentName = "RightLowerLeg",
		jointName = "RightAnkle",
		c0 = CFrame.new(0, -0.4, 0),
		c1 = CFrame.new(0, 0.2, 0),
	},
})

local playerEquippedCardByUserId: { [number]: string } = {}
local playerConnections: { [number]: { RBXScriptConnection } } = {}
local isInitialized = false

local RigAndCardService = {}

local function scaleCFrameOffset(baseCFrame: CFrame, scaleVec: Vector3): CFrame
	local pos = baseCFrame.Position
	local scaledPos = Vector3.new(pos.X * scaleVec.X, pos.Y * scaleVec.Y, pos.Z * scaleVec.Z)
	return (baseCFrame - pos) + scaledPos
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

function RigAndCardService.BuildStandardCustomR15Rig(characterName: string): Model
	local template = ServerStorage:FindFirstChild(Constants.CUSTOM_RIG_MODEL_NAME)
	if template and template:IsA("Model") then
		local cloned = template:Clone()
		cloned.Name = characterName
		cloned:SetAttribute("IsStandardCustomRig", true)
		cloned:SetAttribute("UsesPlayerAvatar", false)
		cloned:SetAttribute("AnimeFaceLocked", true)
		local clonedHum = cloned:FindFirstChildOfClass("Humanoid")
		if clonedHum then
			clonedHum.AutomaticScalingEnabled = false
		end
		return cloned
	end

	local rigModel = Instance.new("Model")
	rigModel.Name = characterName
	rigModel:SetAttribute("IsStandardCustomRig", true)
	rigModel:SetAttribute("UsesPlayerAvatar", false)
	rigModel:SetAttribute("AnimeFaceLocked", true)

	local partsByName: { [string]: Part } = {}

	for _, spec in ipairs(R15_PART_SPECS) do
		local part = Instance.new("Part")
		part.Name = spec.name
		part.Size = spec.size
		part.Anchored = false
		part.CanCollide = (spec.name == "HumanoidRootPart" or spec.name == "LowerTorso" or spec.name == "UpperTorso")
		part.Massless = (spec.name ~= "HumanoidRootPart")
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part:SetAttribute("BaseSize", spec.size)

		if spec.name == "HumanoidRootPart" then
			part.Transparency = 1
			part.CFrame = CFrame.new(0, 5, 0)
		elseif spec.name == "Head" then
			lockAnimeFaceOnHead(part)
		end

		part.Parent = rigModel
		partsByName[spec.name] = part
	end

	for _, spec in ipairs(R15_PART_SPECS) do
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
				motor.Parent = part1
				part1.CFrame = part0.CFrame * spec.c0 * spec.c1:Inverse()
			end
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.RigType = Enum.HumanoidRigType.R15
	-- [FIX-M00-01] Disable AutomaticScalingEnabled so Roblox engine never double-scales on top of ApplyCardScale
	humanoid.AutomaticScalingEnabled = false
	humanoid.HipHeight = 2.0
	humanoid.Parent = rigModel

	local animator = Instance.new("Animator")
	animator.Name = "Animator"
	animator.Parent = humanoid

	rigModel.PrimaryPart = partsByName["HumanoidRootPart"]
	return rigModel
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
		humanoid:SetAttribute("BodyHeightScale", clampedHeight)
		humanoid:SetAttribute("BodyWidthScale", clampedWidth)
		humanoid:SetAttribute("BodyDepthScale", clampedDepth)
		humanoid:SetAttribute("HeadScale", clampedHead)
		humanoid:SetAttribute("BodyProportionScale", scaleCfg.proportionScale)
		humanoid:SetAttribute("BodyTypeScale", 0)
		humanoid.HipHeight = 2.0 * clampedHeight
	end

	rigModel:SetAttribute("EquippedCardId", cardConfig.cardId)
	rigModel:SetAttribute("ArchetypeName", cardConfig.archetypeName)
	rigModel:SetAttribute("CardTier", cardConfig.tier)
	rigModel:SetAttribute("HeightScale", clampedHeight)
	rigModel:SetAttribute("WidthScale", clampedWidth)

	return true
end

function RigAndCardService.SpawnCustomRigForPlayer(player: Player, cardId: string?): Model
	local selectedCardId = cardId or playerEquippedCardByUserId[player.UserId] or Constants.DEFAULT_CARD_ID
	playerEquippedCardByUserId[player.UserId] = selectedCardId

	local previousChar = player.Character
	local spawnCFrame = CFrame.new(0, 5, 0)
	if previousChar and previousChar.PrimaryPart then
		spawnCFrame = previousChar.PrimaryPart.CFrame
	end

	local customRig = RigAndCardService.BuildStandardCustomR15Rig(player.Name)
	RigAndCardService.ApplyCardScale(customRig, selectedCardId)

	if customRig.PrimaryPart then
		customRig:PivotTo(spawnCFrame)
	end

	-- [FIX-M00-02] Auto-respawn Custom Rig when Humanoid dies
	local humanoid = customRig:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local diedConn = humanoid.Died:Connect(function()
			task.delay(2.0, function()
				if player.Parent ~= nil then
					RigAndCardService.SpawnCustomRigForPlayer(player, playerEquippedCardByUserId[player.UserId])
				end
			end)
		end)
		if not playerConnections[player.UserId] then
			playerConnections[player.UserId] = {}
		end
		table.insert(playerConnections[player.UserId], diedConn)
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
	playerEquippedCardByUserId[player.UserId] = Constants.DEFAULT_CARD_ID
	playerConnections[player.UserId] = {}

	local charAddedConn = player.CharacterAdded:Connect(function(character: Model)
		if character:GetAttribute("IsStandardCustomRig") ~= true then
			task.defer(function()
				if player.Parent ~= nil and player.Character == character then
					RigAndCardService.SpawnCustomRigForPlayer(player, playerEquippedCardByUserId[player.UserId])
				end
			end)
		end
	end)
	table.insert(playerConnections[player.UserId], charAddedConn)

	RigAndCardService.SpawnCustomRigForPlayer(player, Constants.DEFAULT_CARD_ID)
end

local function onPlayerRemoving(player: Player)
	local conns = playerConnections[player.UserId]
	if conns then
		for _, conn in ipairs(conns) do
			conn:Disconnect()
		end
		playerConnections[player.UserId] = nil
	end
	playerEquippedCardByUserId[player.UserId] = nil
end

function RigAndCardService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.CharacterAutoLoads = false

	-- [FIX-M00-02] Connect InventoryEquipRequest for Card equips
	local equipEvent = Network.GetRemoteEvent(Network.Names.InventoryEquipRequest)
	equipEvent.OnServerEvent:Connect(function(player: Player, category: any, itemId: any)
		if category == "Card" and Network.IsNonEmptyString(itemId, 64) then
			if CardConfigs.Cards[itemId] ~= nil then
				RigAndCardService.EquipCardForPlayer(player, itemId)
			end
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, existingPlayer in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, existingPlayer)
	end
end

return table.freeze(RigAndCardService)
