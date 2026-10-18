--!strict
-- src/server/services/TradeMarketService.luau
-- Module 06: P2P 2-Step Trade Window (LockOffer -> 3.0s Countdown -> ConfirmTrade) & Market Booth (6 Slots)
-- Enforces Atomic Transaction Lock & Anti-Dupe UID verification on the Server.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))
local Types = require(Shared:WaitForChild("Types"))

local Services = script.Parent
local TraitAndThreadService = require(Services:WaitForChild("TraitAndThreadService"))

local activeTradesById: { [string]: Types.TradeSessionData } = {}
local boothListingsByUserId: { [number]: { Types.BoothListingData } } = {}
local lockedItemUids: { [string]: string } = {} -- itemUid -> tradeId or listingId (Anti-Dupe Lock)
local atomicCommitLock: { [string]: boolean } = {}
local isInitialized = false

local TradeMarketService = {}

local function releaseTradeItemLocks(session: Types.TradeSessionData)
	for _, uid in ipairs(session.initiatorOfferUids) do
		if lockedItemUids[uid] == session.tradeId then
			lockedItemUids[uid] = nil
		end
	end
	for _, uid in ipairs(session.partnerOfferUids) do
		if lockedItemUids[uid] == session.tradeId then
			lockedItemUids[uid] = nil
		end
	end
end

local function verifyPlayerOwnsItemUid(userId: number, itemUid: string): ("Thread" | "Trait")?
	local threadInst = TraitAndThreadService.FindOwnedThread(userId, itemUid)
	if threadInst then
		return "Thread"
	end
	local traitInst = TraitAndThreadService.FindOwnedTraitStone(userId, itemUid)
	if traitInst and traitInst.traitUid == itemUid then
		return "Trait"
	end
	return nil
end

local function transferSingleItemUid(fromUserId: number, toUserId: number, itemUid: string): boolean
	local fromProfile = TraitAndThreadService.GetOrCreateProfile(fromUserId)
	local toProfile = TraitAndThreadService.GetOrCreateProfile(toUserId)

	local threadInst, threadIdx = TraitAndThreadService.FindOwnedThread(fromUserId, itemUid)
	if threadInst and threadIdx then
		table.remove(fromProfile.ownedThreads, threadIdx)
		if fromProfile.equippedThreadUid == itemUid then
			fromProfile.equippedThreadUid = nil
		end
		table.insert(toProfile.ownedThreads, threadInst)
		return true
	end

	local traitInst, traitIdx = TraitAndThreadService.FindOwnedTraitStone(fromUserId, itemUid)
	if traitInst and traitIdx and traitInst.traitUid == itemUid then
		table.remove(fromProfile.ownedTraits, traitIdx)
		table.insert(toProfile.ownedTraits, traitInst)
		return true
	end

	return false
end

function TradeMarketService.CreateTradeSession(initiatorUserId: number, partnerUserId: number): Types.TradeSessionData?
	if initiatorUserId == partnerUserId then
		return nil
	end
	local tradeId = "TRADE_" .. HttpService:GenerateGUID(false)
	local session: Types.TradeSessionData = {
		tradeId = tradeId,
		initiatorUserId = initiatorUserId,
		partnerUserId = partnerUserId,
		initiatorOfferUids = {},
		partnerOfferUids = {},
		initiatorLocked = false,
		partnerLocked = false,
		lockTimestamp = nil,
		initiatorConfirmed = false,
		partnerConfirmed = false,
		status = "Active",
	}
	activeTradesById[tradeId] = session
	return session
end

function TradeMarketService.GetTradeSession(tradeId: string): Types.TradeSessionData?
	return activeTradesById[tradeId]
end

function TradeMarketService.HandleTradeAction(
	userId: number,
	tradeId: string,
	action: Types.TradeActionType,
	itemUid: string?,
	nowOverride: number?
): (boolean, string)
	local session = activeTradesById[tradeId]
	if not session or session.status == "Completed" or session.status == "Cancelled" then
		return false, "InvalidSession"
	end
	if userId ~= session.initiatorUserId and userId ~= session.partnerUserId then
		return false, "NotParticipant"
	end

	local now = nowOverride or os.clock()

	if action == "Cancel" then
		session.status = "Cancelled"
		releaseTradeItemLocks(session)
		return true, "Cancelled"
	elseif action == "AddItem" then
		if not itemUid or not Network.IsNonEmptyString(itemUid, 64) then
			return false, "InvalidItemUid"
		end
		-- Anti-Dupe Lock: reject if itemUid is already locked in any trade or booth
		if lockedItemUids[itemUid] ~= nil then
			return false, "ItemAlreadyLocked"
		end
		if verifyPlayerOwnsItemUid(userId, itemUid) == nil then
			return false, "ItemNotOwned"
		end

		lockedItemUids[itemUid] = tradeId
		if userId == session.initiatorUserId then
			table.insert(session.initiatorOfferUids, itemUid)
		else
			table.insert(session.partnerOfferUids, itemUid)
		end

		-- Changing items immediately resets Lock & Confirm states for BOTH players (Section 4.7 Rule)
		session.initiatorLocked = false
		session.partnerLocked = false
		session.initiatorConfirmed = false
		session.partnerConfirmed = false
		session.lockTimestamp = nil
		session.status = "Active"
		return true, "ItemAddedAndLocksReset"
	elseif action == "LockOffer" then
		if userId == session.initiatorUserId then
			session.initiatorLocked = true
		else
			session.partnerLocked = true
		end
		if session.initiatorLocked and session.partnerLocked then
			session.lockTimestamp = now
			session.status = "Locked"
		end
		return true, "OfferLocked"
	elseif action == "ConfirmTrade" then
		if not (session.initiatorLocked and session.partnerLocked) or session.lockTimestamp == nil then
			return false, "BothMustLockFirst"
		end
		-- Mandatory 3.0s countdown after both players lock offers
		if (now - session.lockTimestamp) < Constants.TRADE_CONFIRM_COUNTDOWN_SEC then
			return false, "CountdownNotElapsed"
		end

		if userId == session.initiatorUserId then
			session.initiatorConfirmed = true
		else
			session.partnerConfirmed = true
		end

		if session.initiatorConfirmed and session.partnerConfirmed then
			if atomicCommitLock[tradeId] then
				return false, "CommitInProgress"
			end
			atomicCommitLock[tradeId] = true

			-- Verify ownership of all offered UIDs before atomic swap
			for _, uid in ipairs(session.initiatorOfferUids) do
				if verifyPlayerOwnsItemUid(session.initiatorUserId, uid) == nil then
					session.status = "Cancelled"
					releaseTradeItemLocks(session)
					atomicCommitLock[tradeId] = nil
					return false, "OwnershipVerificationFailed"
				end
			end
			for _, uid in ipairs(session.partnerOfferUids) do
				if verifyPlayerOwnsItemUid(session.partnerUserId, uid) == nil then
					session.status = "Cancelled"
					releaseTradeItemLocks(session)
					atomicCommitLock[tradeId] = nil
					return false, "OwnershipVerificationFailed"
				end
			end

			for _, uid in ipairs(session.initiatorOfferUids) do
				transferSingleItemUid(session.initiatorUserId, session.partnerUserId, uid)
			end
			for _, uid in ipairs(session.partnerOfferUids) do
				transferSingleItemUid(session.partnerUserId, session.initiatorUserId, uid)
			end

			session.status = "Completed"
			releaseTradeItemLocks(session)
			atomicCommitLock[tradeId] = nil
			return true, "TradeCompleted"
		end

		return true, "ConfirmedWaitingPartner"
	end

	return false, "UnknownAction"
end

function TradeMarketService.CreateBoothListing(
	sellerUserId: number,
	itemUid: string,
	priceCash: number
): (Types.BoothListingData?, string)
	if priceCash <= 0 or lockedItemUids[itemUid] ~= nil then
		return nil, "InvalidPriceOrItemLocked"
	end
	local category = verifyPlayerOwnsItemUid(sellerUserId, itemUid)
	if not category then
		return nil, "ItemNotOwned"
	end

	if not boothListingsByUserId[sellerUserId] then
		boothListingsByUserId[sellerUserId] = {}
	end
	if #boothListingsByUserId[sellerUserId] >= Constants.MAX_BOOTH_SLOTS then
		return nil, "BoothFull"
	end

	local listingId = "BOOTH_" .. HttpService:GenerateGUID(false)
	lockedItemUids[itemUid] = listingId
	local listing: Types.BoothListingData = {
		listingId = listingId,
		sellerUserId = sellerUserId,
		itemUid = itemUid,
		category = category,
		priceCash = math.floor(priceCash),
	}
	table.insert(boothListingsByUserId[sellerUserId], listing)
	return listing, "Listed"
end

function TradeMarketService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local tradeRemote = Network.GetRemoteEvent(Network.Names.TradeActionRequest)
	tradeRemote.OnServerEvent:Connect(function(player: Player, tradeId: any, action: any, itemUid: any)
		if not Network.IsNonEmptyString(tradeId, 64) then
			return
		end
		if action ~= "AddItem" and action ~= "LockOffer" and action ~= "ConfirmTrade" and action ~= "Cancel" then
			return
		end
		local cleanUid = if Network.IsNonEmptyString(itemUid, 64) then (itemUid :: string) else nil
		TradeMarketService.HandleTradeAction(
			player.UserId,
			tradeId :: string,
			action :: Types.TradeActionType,
			cleanUid,
			nil
		)
	end)
end

return table.freeze(TradeMarketService)
