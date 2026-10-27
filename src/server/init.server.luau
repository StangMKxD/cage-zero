--!strict
-- src/server/init.server.luau
-- Server Bootstrapper: Network.Init(10.0) -> CagePhysicsService.Init() -> R15AvatarService.Init() -> BallService.Init() -> SprintService.Init() -> JumpService.Init()
-- RigAndCardService preserved as inert reference; R6 spawner does not run concurrently.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))

local Services = script:WaitForChild("services")
local CagePhysicsService = require(Services:WaitForChild("CagePhysicsService"))
local R15AvatarService = require(Services:WaitForChild("R15AvatarService"))
local BallService = require(Services:WaitForChild("BallService"))
local SprintService = require(Services:WaitForChild("SprintService"))
local JumpService = require(Services:WaitForChild("JumpService"))
-- Option A Cleanup: SkillMoveService excised; RigAndCardService preserved as inert reference

-- 1. Initialize all RemoteEvents/RemoteFunctions with deadline budget (10s)
Network.Init(10.0)

-- 2. Initialize CagePhysicsService (builds Workspace.HexCageArena + CageFloor and retires temporary Module 00 fixtures without touching Baseplate)
CagePhysicsService.Init()
CagePhysicsService.RetireBootstrapFixtures(Workspace)

-- 3. Initialize R15AvatarService (Authoritative Player Avatar R15 lifecycle spawning on CageFloor)
-- RigAndCardService preserved as inert reference; R6 spawner does not run concurrently.
R15AvatarService.Init()

-- 4. Initialize BallService (Module 02: Server-authoritative match ball, continuous football physics)
BallService.Init()

-- 5. Initialize SprintService (Authoritative sprint speed validation and state replication)
SprintService.Init()

-- 6. Initialize JumpService (Authoritative jump flight envelope and liftoff yaw validation)
JumpService.Init()
