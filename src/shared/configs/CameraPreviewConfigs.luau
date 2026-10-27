--!strict
-- src/shared/configs/CameraPreviewConfigs.luau
-- Prototype Configuration for Owner Camera Preview: Free Orbit View + Center Reticle + Direction-Latch Movement
-- Governed by RF02-CAMERA-PREVIEW Hand-Off Contract (CP01..CP04)

local RunService = game:GetService("RunService")

export type CameraSettings = {
	Distance: number,
	MinDistance: number,
	MaxDistance: number,
	ZoomStep: number,
	FocusHeightOffset: number,
	FocusSideOffset: number,
	DefaultPitchDeg: number,
	MinPitchDeg: number,
	MaxPitchDeg: number,
	MouseSensitivityX: number,
	MouseSensitivityY: number,
	OcclusionRadius: number,
	CollisionMargin: number,
}

export type ReticleSettings = {
	ChevronColor: Color3,
	DotColor: Color3,
	StrokeColor: Color3,
	DotSize: number,
	ArmLength: number,
	ArmThickness: number,
	ApexOffset: number,
}

export type MovementSettings = {
	Enabled: boolean,
	FaceReticleGrounded: boolean,
	GroundedFacingDeadbandRad: number,
	TurnSmoothingEnabled: boolean,
	FacingTurnSpeedRadPerSec: number,
	TurnSpeedDipEnabled: boolean,
	TurnSpeedDipMinFactor: number,
	TurnSpeedDipThresholdDeg: number,
}

local CameraPreviewConfigs = {}

-- Prototype is Studio-only by default; production/public games keep native camera
CameraPreviewConfigs.STUDIO_ONLY = true

CameraPreviewConfigs.Camera = table.freeze({
	Distance = 12.0,
	MinDistance = 3.0,
	MaxDistance = 35.0,
	ZoomStep = 2.0,
	FocusHeightOffset = 4.2,
	FocusSideOffset = 0.0,
	DefaultPitchDeg = 12.0,
	MinPitchDeg = -70.0,
	MaxPitchDeg = 80.0,
	MouseSensitivityX = 0.003,
	MouseSensitivityY = 0.003,
	OcclusionRadius = 0.5,
	CollisionMargin = 0.25,
}) :: CameraSettings

-- Styled to match Owner requested ShiftLock-style pure white reticle: < · >
CameraPreviewConfigs.Reticle = table.freeze({
	ChevronColor = Color3.fromRGB(255, 255, 255),
	DotColor = Color3.fromRGB(255, 255, 255),
	StrokeColor = Color3.fromRGB(0, 0, 0),
	DotSize = 6,
	ArmLength = 14,
	ArmThickness = 3.5,
	ApexOffset = 18,
}) :: ReticleSettings

CameraPreviewConfigs.Movement = table.freeze({
	Enabled = true,
	FaceReticleGrounded = false, -- 360° Analog Locomotion: character faces travel direction, not reticle
	GroundedFacingDeadbandRad = 0.001,
	TurnSmoothingEnabled = true,
	FacingTurnSpeedRadPerSec = 20.0, -- rad/s: ~1145 deg/s for fluid analog-stick turns
	TurnSpeedDipEnabled = true, -- Sharp turns temporarily dip speed to reflect body inertia
	TurnSpeedDipMinFactor = 0.65, -- Dips to 65% on full 180° turn and smoothly accelerates
	TurnSpeedDipThresholdDeg = 30.0, -- Turns <= 30° do not lose any speed
}) :: MovementSettings

function CameraPreviewConfigs.IsActiveInCurrentContext(): boolean
	if CameraPreviewConfigs.STUDIO_ONLY then
		return RunService:IsStudio()
	end
	return true
end

return table.freeze(CameraPreviewConfigs)
