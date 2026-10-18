--!strict
-- src/server/init.server.luau
-- MODULE 08: 08-integration-and-uat
-- Server Bootstrapper initializing Network and all Server-Authoritative Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local Services = script:WaitForChild("services")
local MatchService = require(Services:WaitForChild("MatchService"))

-- 1. Initialize all 12 RemoteEvents/RemoteFunctions
Network.Init()

-- 2. Initialize MatchService (which boots RigAndCardService, CagePhysicsService, BallService, ParryService, DuelEngineService, FreeKickService, EventManagerService, TraitAndThreadService, and TradeMarketService)
MatchService.Init()
