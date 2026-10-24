--!strict
-- src/server/init.server.luau
-- MODULE 01: 01-cage-physics (chained onto MODULE 00: 00-bootstrap-and-rig)
-- Server Bootstrapper: Network.Init(10.0) -> CagePhysicsService.Init() -> RigAndCardService.Init()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local Services = script:WaitForChild("services")
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))
local RigAndCardService = require(Services:WaitForChild("RigAndCardService"))
local BallService = require(Services:WaitForChild("BallService"))
local SkillMoveService = require(Services:WaitForChild("SkillMoveService"))

-- 1. Initialize all RemoteEvents/RemoteFunctions with deadline budget (10s)
Network.Init(10.0)

-- 2. Initialize CagePhysicsService (builds Workspace.HexCageArena + CageFloor and retires temporary Module 00 fixtures without touching Baseplate)
CagePhysicsService.Init()
CagePhysicsService.RetireBootstrapFixtures(Workspace)

-- 3. Initialize RigAndCardService (Single Custom R6 lifecycle spawning on Workspace.HexCageArena.CageFloor)
RigAndCardService.Init()

-- 4. Initialize BallService (Module 02: Server-authoritative match ball, possession, movement & continuous football actions)
BallService.Init()

-- 5. Initialize SkillMoveService (Module 03: Server-authoritative 5 Skill Moves, 3 Slots & Defense)
SkillMoveService.Init()
