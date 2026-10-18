--!strict
-- src/shared/configs/EventConfigs.luau
-- Module 05: Configuration & Deterministic Sync Math for the 3 Dynamic Match Events
-- Strictly limited to: PillarLockdown, BlackoutVoid, and FavelaAlley.

local Constants = require(script.Parent.Parent.Constants)
local Types = require(script.Parent.Parent.Types)

export type PedestrianTrack = {
	pedestrianId: string,
	startPos: Vector3,
	endPos: Vector3,
	cycleDurationSec: number,
	hitboxRadius: number,
	restitution: number,
}

export type EventDefinition = {
	eventType: Types.MatchEventType,
	displayName: string,
	warningLeadSec: number,
	activeDurationSec: number,
}

local EventRotation: { Types.MatchEventType } = table.freeze({
	"PillarLockdown",
	"BlackoutVoid",
	"FavelaAlley",
})

local Definitions: { [Types.MatchEventType]: EventDefinition } = table.freeze({
	PillarLockdown = table.freeze({
		eventType = "PillarLockdown" :: Types.MatchEventType,
		displayName = "Pillar Lockdown",
		warningLeadSec = Constants.PILLAR_WARNING_LEAD_SEC, -- 1.5s
		activeDurationSec = Constants.MATCH_EVENT_DURATION_SEC, -- 40s
	}),
	BlackoutVoid = table.freeze({
		eventType = "BlackoutVoid" :: Types.MatchEventType,
		displayName = "The Blackout Void",
		warningLeadSec = 1.5,
		activeDurationSec = Constants.MATCH_EVENT_DURATION_SEC, -- 40s
	}),
	FavelaAlley = table.freeze({
		eventType = "FavelaAlley" :: Types.MatchEventType,
		displayName = "Favela Alleyway",
		warningLeadSec = 1.5,
		activeDurationSec = Constants.MATCH_EVENT_DURATION_SEC, -- 40s
	}),
})

local StrategicPillarSets: { { Vector3 } } = table.freeze({
	table.freeze({
		Vector3.new(-22, 14, -45),
		Vector3.new(22, 14, 45),
		Vector3.new(0, 14, 0),
	}),
	table.freeze({
		Vector3.new(-26, 14, 35),
		Vector3.new(26, 14, -35),
		Vector3.new(0, 14, -62),
	}),
})

local FavelaPedestrianTracks: { PedestrianTrack } = table.freeze({
	table.freeze({
		pedestrianId = "Pedestrian_1",
		startPos = Vector3.new(-58, 3, -32),
		endPos = Vector3.new(58, 3, -32),
		cycleDurationSec = 12.0,
		hitboxRadius = 3.0,
		restitution = 1.00,
	}),
	table.freeze({
		pedestrianId = "Pedestrian_2",
		startPos = Vector3.new(58, 3, 0),
		endPos = Vector3.new(-58, 3, 0),
		cycleDurationSec = 10.0,
		hitboxRadius = 3.0,
		restitution = 1.00,
	}),
	table.freeze({
		pedestrianId = "Pedestrian_3",
		startPos = Vector3.new(-58, 3, 32),
		endPos = Vector3.new(58, 3, 32),
		cycleDurationSec = 14.0,
		hitboxRadius = 3.0,
		restitution = 1.00,
	}),
})

local EventConfigs = {
	IntervalSec = Constants.MATCH_EVENT_INTERVAL_SEC, -- 90s
	DurationSec = Constants.MATCH_EVENT_DURATION_SEC, -- 40s
	PillarWarningLeadSec = Constants.PILLAR_WARNING_LEAD_SEC, -- 1.5s
	PillarSize = Vector3.new(6, 28, 6),
	PillarRestitution = 1.00,
	EventRotation = EventRotation,
	Definitions = Definitions,
	StrategicPillarSets = StrategicPillarSets,
	FavelaPedestrianTracks = FavelaPedestrianTracks,
}

-- Deterministic ping-pong waypoint interpolation so Server and Client compute identical NPC coordinates
function EventConfigs.ComputePedestrianPosition(trackIndex: number, elapsedSec: number): Vector3
	local track = FavelaPedestrianTracks[trackIndex]
	if not track then
		return Vector3.zero
	end
	local cycle = math.max(1.0, track.cycleDurationSec)
	local phase = ( math.max(0.0, elapsedSec) / cycle ) % 2.0
	local alpha = if phase <= 1.0 then phase else (2.0 - phase)
	return track.startPos:Lerp(track.endPos, alpha)
end

return table.freeze(EventConfigs)
