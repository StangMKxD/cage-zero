--!strict
-- src/server/services/TraitAndThreadService.luau
-- Module 06: Server-Authoritative Player Profiles, Gacha Summon (Pity 100), Battle Threads,
-- Cooldown-Gated Trait Stones, and Post-Match Mutated Gear Cash/EXP Multipliers.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))
local CardConfigs = require(Shared:WaitForChild("configs"):WaitForChild("CardConfigs"))
local ThreadConfigs = require(Shared:WaitForChild("configs"):WaitForChild("ThreadConfigs"))
local TraitConfigs = require(Shared:WaitForChild("configs"):WaitForChild("TraitConfigs"))

local Services = script.Parent
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

local profilesByUserId: { [number]: Types.PlayerProfileData } = {}
local traitCooldownUntilByUserId: { [number]: { [string]: number } } = {}
local isInitialized = false

local TraitAndThreadService = {}

function TraitAndThreadService.GetOrCreateProfile(userId: number): Types.PlayerProfileData
	local existing = profilesByUserId[userId]
	if existing then
		return existing
	end

	local starterThreadUid = "THREAD_" .. tostring(userId) .. "_STARTER"
	local starterTraitUid = "TRAIT_" .. tostring(userId) .. "_STARTER"

	local newProfile: Types.PlayerProfileData = {
		userId = userId,
		cash = 5000,
		level = 1,
		exp = 0,
		pityCounter = 0,
		equippedCardId = Constants.DEFAULT_CARD_ID,
		equippedThreadUid = starterThreadUid,
		equippedCelebrationId = "DeepBreathStance",
		ownedCards = { Constants.DEFAULT_CARD_ID, "Leon_TierB" },
		ownedThreads = {
			{
				threadUid = starterThreadUid,
				threadConfigId = "StreetHoodie_Common",
				rarity = "Common",
				maxTraitSlots = 1,
				equippedTraitIds = { "LaserGuidedPass" },
				mutation = nil,
			},
		},
		ownedTraits = {
			{
				traitUid = starterTraitUid,
				traitId = "LaserGuidedPass",
				acquiredAt = os.time(),
			},
		},
	}

	profilesByUserId[userId] = newProfile
	return newProfile
end

function TraitAndThreadService.FindOwnedThread(
	userId: number,
	threadUid: string?
): (Types.BattleThreadInstance?, number?)
	if not threadUid then
		return nil, nil
	end
	local profile = TraitAndThreadService.GetOrCreateProfile(userId)
	for idx, inst in ipairs(profile.ownedThreads) do
		if inst.threadUid == threadUid then
			return inst, idx
		end
	end
	return nil, nil
end

function TraitAndThreadService.FindOwnedTraitStone(
	userId: number,
	traitUidOrId: string
): (Types.TraitStoneInstance?, number?)
	local profile = TraitAndThreadService.GetOrCreateProfile(userId)
	for idx, stone in ipairs(profile.ownedTraits) do
		if stone.traitUid == traitUidOrId or stone.traitId == traitUidOrId then
			return stone, idx
		end
	end
	return nil, nil
end

-- Server-Authoritative Trait Activation with Mandatory Cooldown
function TraitAndThreadService.ActivateTrait(userId: number, traitId: string): (boolean, number)
	local traitDef = TraitConfigs.GetTraitConfig(traitId)
	if not traitDef then
		return false, 0
	end

	local profile = TraitAndThreadService.GetOrCreateProfile(userId)
	local equippedThread = TraitAndThreadService.FindOwnedThread(userId, profile.equippedThreadUid)
	if not equippedThread then
		return false, 0
	end

	local isEquippedInSlot = false
	for _, eqId in ipairs(equippedThread.equippedTraitIds) do
		if eqId == traitId then
			isEquippedInSlot = true
			break
		end
	end
	if not isEquippedInSlot then
		return false, 0
	end

	if not traitCooldownUntilByUserId[userId] then
		traitCooldownUntilByUserId[userId] = {}
	end
	local now = os.clock()
	local cooldownExpiresAt = traitCooldownUntilByUserId[userId][traitId] or 0
	if now < cooldownExpiresAt then
		return false, (cooldownExpiresAt - now)
	end

	traitCooldownUntilByUserId[userId][traitId] = now + traitDef.cooldownSec
	return true, traitDef.cooldownSec
end

function TraitAndThreadService.EquipItem(
	player: Player,
	category: Types.InventoryCategory,
	itemId: string,
	slotIndex: number?
): boolean
	local profile = TraitAndThreadService.GetOrCreateProfile(player.UserId)

	if category == "Card" then
		for _, ownedCardId in ipairs(profile.ownedCards) do
			if ownedCardId == itemId and CardConfigs.Cards[itemId] ~= nil then
				profile.equippedCardId = itemId
				RigAndCardService.EquipCardForPlayer(player, itemId)
				return true
			end
		end
		return false
	elseif category == "Thread" then
		local threadInst = TraitAndThreadService.FindOwnedThread(player.UserId, itemId)
		if threadInst then
			profile.equippedThreadUid = threadInst.threadUid
			return true
		end
		return false
	elseif category == "Trait" then
		local equippedThread = TraitAndThreadService.FindOwnedThread(player.UserId, profile.equippedThreadUid)
		local ownedStone = TraitAndThreadService.FindOwnedTraitStone(player.UserId, itemId)
		if not equippedThread or not ownedStone then
			return false
		end
		local slot = math.clamp(slotIndex or 1, 1, equippedThread.maxTraitSlots)
		equippedThread.equippedTraitIds[slot] = ownedStone.traitId
		return true
	elseif category == "Celebration" then
		profile.equippedCelebrationId = itemId
		return true
	end

	return false
end

-- Computes Post-Match Cash & EXP using Mutated Gear multipliers (Zero in-match combat stat buffs!)
function TraitAndThreadService.ComputePostMatchReward(
	userId: number,
	baseCash: number,
	baseExp: number
): { cashEarned: number, expEarned: number, cashMultiplier: number, expMultiplier: number }
	local profile = TraitAndThreadService.GetOrCreateProfile(userId)
	local equippedThread = TraitAndThreadService.FindOwnedThread(userId, profile.equippedThreadUid)

	local cashMult = 1.0
	local expMult = 1.0
	if equippedThread and equippedThread.mutation then
		cashMult = math.clamp(
			equippedThread.mutation.cashMultiplier,
			Constants.MUTATION_CASH_MULTIPLIER_MIN,
			Constants.MUTATION_CASH_MULTIPLIER_MAX
		)
		expMult = math.clamp(
			equippedThread.mutation.expMultiplier,
			Constants.MUTATION_EXP_MULTIPLIER_MIN,
			Constants.MUTATION_EXP_MULTIPLIER_MAX
		)
	end

	local cashEarned = math.floor(baseCash * cashMult)
	local expEarned = math.floor(baseExp * expMult)
	profile.cash += cashEarned
	profile.exp += expEarned
	while profile.exp >= (profile.level * 1000) do
		profile.exp -= (profile.level * 1000)
		profile.level += 1
	end

	return {
		cashEarned = cashEarned,
		expEarned = expEarned,
		cashMultiplier = cashMult,
		expMultiplier = expMult,
	}
end

-- Server-Authoritative Gacha Summon (Tier S: 0.5%, Tier A: 9.5%, Tier B: 90%, Pity 100)
function TraitAndThreadService.SummonBanner(
	userId: number,
	bannerId: string,
	count: number
): { Types.ObtainedItem }
	local validCount = if count == 10 then 10 else 1
	local profile = TraitAndThreadService.GetOrCreateProfile(userId)
	local results: { Types.ObtainedItem } = {}

	for _ = 1, validCount do
		profile.pityCounter += 1
		local roll = math.random() * 100.0
		local isPityS = profile.pityCounter >= Constants.GACHA_PITY_LIMIT

		if bannerId == "TraitAndThreadBanner" then
			local uid = "THREAD_" .. HttpService:GenerateGUID(false)
			local mut: Types.MutationData? = nil
			if isPityS or roll <= 5.0 then
				mut = ThreadConfigs.MutationPresets.GoldenAura
				profile.pityCounter = 0
			end
			local newThread: Types.BattleThreadInstance = {
				threadUid = uid,
				threadConfigId = if mut then "PhantomCloak_Epic" else "CyberJacket_Rare",
				rarity = if mut then "Epic" else "Rare",
				maxTraitSlots = if mut then 2 else 1,
				equippedTraitIds = {},
				mutation = mut,
			}
			table.insert(profile.ownedThreads, newThread)
			table.insert(results, {
				itemUid = uid,
				category = "Thread",
				configId = newThread.threadConfigId,
				tierOrRarity = newThread.rarity,
			})
		else
			local tier: Types.CardTier = "B"
			local cardId = "Ronan_TierB"
			if isPityS or roll <= 0.5 then
				tier = "S"
				cardId = "Leon_TierS"
				profile.pityCounter = 0
			elseif roll <= 10.0 then
				tier = "A"
				cardId = "Ronan_TierA"
			end
			table.insert(profile.ownedCards, cardId)
			table.insert(results, {
				itemUid = "CARD_" .. HttpService:GenerateGUID(false),
				category = "Card",
				configId = cardId,
				tierOrRarity = tier,
			})
		end
	end

	return results
end

function TraitAndThreadService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local equipRemote = Network.GetRemoteEvent(Network.Names.InventoryEquipRequest)
	equipRemote.OnServerEvent:Connect(function(player: Player, category: any, itemId: any, slotIndex: any)
		if (category == "Card" or category == "Thread" or category == "Trait" or category == "Celebration")
			and Network.IsNonEmptyString(itemId, 64)
		then
			local slot = if type(slotIndex) == "number" then slotIndex else nil
			TraitAndThreadService.EquipItem(player, category :: Types.InventoryCategory, itemId :: string, slot)
		end
	end)

	local summonFn = Network.GetRemoteFunction(Network.Names.SummonRequest)
	summonFn.OnServerInvoke = function(player: Player, bannerId: any, count: any): { Types.ObtainedItem }
		local cleanBanner = if Network.IsNonEmptyString(bannerId, 64) then (bannerId :: string) else "StandardCardBanner"
		local cleanCount = if count == 10 then 10 else 1
		return TraitAndThreadService.SummonBanner(player.UserId, cleanBanner, cleanCount)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		traitCooldownUntilByUserId[player.UserId] = nil
	end)
end

return table.freeze(TraitAndThreadService)
