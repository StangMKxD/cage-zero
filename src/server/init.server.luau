--!strict
-- src/server/init.server.luau
-- Server Bootstrap for Cage Zero (Module 00: Initializes Network Remotes and RigAndCardService)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local Services = script:WaitForChild("services")
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))

Network.InitServer()
RigAndCardService.Init()
