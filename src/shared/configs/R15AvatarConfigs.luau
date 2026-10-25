--!strict
-- src/shared/configs/R15AvatarConfigs.luau
-- Canonical normalization configs and dimension specifications for Player Avatar R15
-- Body Package Target: Official ROBLOX Boy (Bundle ID: 109) for all players
-- Keeps each player's own face, skin/body colors, clothing, hair, hats, and accessories.
-- Height Steering: +30% taller standard body height (~6.71 studs target) for all players.

local R15AvatarConfigs = {}

-- Official ROBLOX Boy Bundle Details (Resolved from AssetService:GetBundleDetailsAsync(109))
R15AvatarConfigs.BOY_BUNDLE_ID = 109
R15AvatarConfigs.BOY_BUNDLE_NAME = "ROBLOX Boy"
R15AvatarConfigs.BOY_BODY_PARTS = table.freeze({
	Torso = 376532000,     -- ROBLOX Boy Torso (Asset)
	LeftArm = 376530220,   -- ROBLOX Boy Left Arm (Asset)
	RightArm = 376531012,  -- ROBLOX Boy Right Arm (Asset)
	LeftLeg = 376531300,   -- ROBLOX Boy Left Leg (Asset)
	RightLeg = 376531703,  -- ROBLOX Boy Right Leg (Asset)
})

-- Canonical scale normalizations (equal description scale numbers across all players)
-- HeightScale = 1.391 delivers exactly 6.708 studs (~6.71 studs, +30.0% physical body height from 5.158 baseline)
-- while preserving HeadScale = 1.0 for natural head/hat proportions and unchanged width/depth (1.0).
R15AvatarConfigs.CANONICAL_SCALES = table.freeze({
	HeightScale = 1.391,
	WidthScale = 1.0,
	DepthScale = 1.0,
	HeadScale = 1.0,
	BodyTypeScale = 0.0,
	ProportionScale = 0.0,
})

-- Canonical contact, root, and measured body geometry (excluding accessories)
R15AvatarConfigs.CANONICAL_ROOT_SIZE = Vector3.new(2.0, 2.782, 1.0)
R15AvatarConfigs.CANONICAL_HIP_HEIGHT = 2.792
R15AvatarConfigs.CANONICAL_BODY_WIDTH = 3.459
R15AvatarConfigs.CANONICAL_BODY_HEIGHT = 6.708
R15AvatarConfigs.CANONICAL_BODY_DEPTH = 1.366
R15AvatarConfigs.RESPAWN_DELAY_SEC = 2.0
R15AvatarConfigs.SPAWN_HEIGHT_OFFSET = 4.45

-- Authoritative acquisition retry & fallback policy (RF-F23)
R15AvatarConfigs.MAX_ACQUISITION_RETRIES = 3
R15AvatarConfigs.RETRY_BASE_DELAY_SEC = 2.0

-- Standard R15 body parts list (15 mesh parts + HumanoidRootPart)
R15AvatarConfigs.R15_BODY_PARTS = table.freeze({
	"HumanoidRootPart",
	"UpperTorso",
	"LowerTorso",
	"Head",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
})

-- Applies canonical ROBLOX Boy body limbs while strictly preserving the player's personal identity
function R15AvatarConfigs.ApplyBoyBodyAndNormalize(description: HumanoidDescription): HumanoidDescription
	-- 1. Apply canonical ROBLOX Boy limb and torso assets
	description.Torso = R15AvatarConfigs.BOY_BODY_PARTS.Torso
	description.LeftArm = R15AvatarConfigs.BOY_BODY_PARTS.LeftArm
	description.RightArm = R15AvatarConfigs.BOY_BODY_PARTS.RightArm
	description.LeftLeg = R15AvatarConfigs.BOY_BODY_PARTS.LeftLeg
	description.RightLeg = R15AvatarConfigs.BOY_BODY_PARTS.RightLeg

	-- 2. Normalize body scaling to canonical +30% height baseline (Width/Depth/Head preserved at 1.0)
	description.HeightScale = R15AvatarConfigs.CANONICAL_SCALES.HeightScale
	description.WidthScale = R15AvatarConfigs.CANONICAL_SCALES.WidthScale
	description.DepthScale = R15AvatarConfigs.CANONICAL_SCALES.DepthScale
	description.HeadScale = R15AvatarConfigs.CANONICAL_SCALES.HeadScale
	description.BodyTypeScale = R15AvatarConfigs.CANONICAL_SCALES.BodyTypeScale
	description.ProportionScale = R15AvatarConfigs.CANONICAL_SCALES.ProportionScale

	-- Note: description.Head, Face, Shirt, Pants, GraphicTShirt, Accessories, and BodyColors
	-- are intentionally preserved untouched from the player's own avatar description.
	return description
end

-- Backward compatibility alias
R15AvatarConfigs.NormalizeDescription = R15AvatarConfigs.ApplyBoyBodyAndNormalize

return table.freeze(R15AvatarConfigs)
