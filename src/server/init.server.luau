--!strict
-- src/server/init.server.luau
-- MODULE 00: 00-bootstrap-and-rig
-- Server Bootstrapper initializing Network and RigAndCardService (Custom R6)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local Services = script:WaitForChild("services")
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

-- 1. Initialize all 12 RemoteEvents/RemoteFunctions with deadline budget (10s)
Network.Init()

-- 2. Initialize RigAndCardService (Single Custom R6 lifecycle)
RigAndCardService.Init()
