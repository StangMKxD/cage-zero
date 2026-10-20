--!strict
-- src/client/init.client.luau
-- MODULE 00: 00-bootstrap-and-rig
-- Client Bootstrapper initializing Network and R6AnimationController (Custom R6)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local bootstrapStart = os.clock()
local TOTAL_BOOTSTRAP_BUDGET = 10.0

local remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for Shared")
local Shared = ReplicatedStorage:WaitForChild("Shared", remaining) :: Folder?
assert(Shared ~= nil, "[Client.Init] Shared folder timed out in ReplicatedStorage")

remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for Network")
local NetworkModule = Shared:WaitForChild("Network", remaining) :: ModuleScript?
assert(NetworkModule ~= nil, "[Client.Init] Network module timed out in Shared")

local Network = require(NetworkModule)

-- 1. Initialize Network client cache within total bootstrap budget (10s)
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before Network.Init")
Network.Init(remaining)

-- 2. Wait for character folder and R6AnimationController within remaining budget
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for character folder")
local CharacterFolder = script:WaitForChild("character", remaining) :: Folder?
assert(CharacterFolder ~= nil, "[Client.Init] character folder timed out in script")

remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before waiting for R6AnimationController")
local ControllerModule = CharacterFolder:WaitForChild("R6AnimationController", remaining) :: ModuleScript?
assert(ControllerModule ~= nil, "[Client.Init] R6AnimationController module timed out in character folder")

local R6AnimationController = require(ControllerModule)

-- 3. Initialize R6 Animation Controller within remaining budget
remaining = TOTAL_BOOTSTRAP_BUDGET - (os.clock() - bootstrapStart)
assert(remaining > 0, "[Client.Init] Bootstrap deadline exhausted before R6AnimationController.Init")
R6AnimationController.Init(remaining)
