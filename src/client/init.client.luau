--!strict
-- src/client/init.client.luau
-- Client Bootstrap for Cage Zero (Module 00: Verifies Shared Constants & Network contract readiness)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

assert(Constants.ALLOW_PLAYER_AVATAR_MODELS == false, "[Client] Player avatar models must be disabled")
assert(Constants.ALLOW_BOOTS_OR_CLEATS_SYSTEM == false, "[Client] Boots/Cleats system must be disabled")
assert(Network.Definitions.BallActionRequest ~= nil, "[Client] Network definitions failed to load")
