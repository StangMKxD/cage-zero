--!strict
-- Pure sprint speed state: cardinal/diagonal input and brief turn deceleration.
local Config = require(script.Parent.configs.SprintConfigs)
local Actions=require(script.Parent.configs.FootballActionConfigs)
local Rules = {}

export type State = {
	forward: number, lateral: number, direction: Vector3, turnOrigin: Vector3,
	lastMovingAt: number, penaltyUntil: number, penaltySpeed: number, speed: number, reverseSeq: number, facing: Vector3, facingAt: number,
}

function Rules.IsAxis(value: any): boolean
	return value == -1 or value == 0 or value == 1
end

function Rules.BaseSpeed(forward: number, lateral: number): number
	return if forward ~= 0 and lateral ~= 0 then Config.DIAGONAL_SPEED else Config.SPRINT_SPEED
end

function Rules.New(): State
	return {forward = 0, lateral = 0, direction = Vector3.zero, turnOrigin = Vector3.zero,
		lastMovingAt = -math.huge, penaltyUntil = 0, penaltySpeed = Config.SPRINT_SPEED,
		speed = Config.SPRINT_SPEED, reverseSeq=0, facing=Vector3.zero, facingAt=0}
end

function Rules.SetDirection(state: State, forward: number, lateral: number, now: number)
	local direction = Vector3.new(lateral, 0, -forward)
	if direction.Magnitude == 0 then return end
	direction = direction.Unit
	local recent = now - state.lastMovingAt <= Config.TURN_MEMORY_SEC
	if not recent then
		state.penaltyUntil, state.penaltySpeed = 0, Config.SPRINT_SPEED
		state.turnOrigin = Vector3.zero
		state.speed = Rules.BaseSpeed(forward, lateral)
	elseif state.direction.Magnitude > 0 then
		local angle = math.deg(math.acos(math.clamp(state.direction:Dot(direction), -1, 1)))
		local changed = angle > 0.1
		if changed and now < state.penaltyUntil and state.turnOrigin.Magnitude > 0 then
			-- SA/SD arrive as separate key events; retain the origin of this brief turn.
			angle = math.max(angle, math.deg(math.acos(math.clamp(state.turnOrigin:Dot(direction), -1, 1))))
		end
		local cap = if angle >= 134.9 then Config.REVERSE_SPEED
			elseif angle >= 44.9 then Config.DIAGONAL_SPEED else nil
		if changed and cap then
			if angle>=Actions.TurnAngleDeg then state.reverseSeq+=1 end
			if now >= state.penaltyUntil then state.turnOrigin = state.direction end
			-- Smaller turns cannot erase an already active reverse penalty.
			state.penaltySpeed = if now < state.penaltyUntil then math.min(cap, state.penaltySpeed) else cap
			state.penaltyUntil = now + Config.TURN_HOLD_SEC
		end
	end
	state.forward, state.lateral, state.direction = forward, lateral, direction
	state.lastMovingAt = now
	local target = Rules.BaseSpeed(forward, lateral)
	if now < state.penaltyUntil then target = math.min(target, state.penaltySpeed) end
	state.speed = math.min(state.speed, target)
end

function Rules.Advance(state: State, now: number, dt: number): number
	state.lastMovingAt = now -- A held key remains recent even without new network intents.
	local target = Rules.BaseSpeed(state.forward, state.lateral)
	if now < state.penaltyUntil then target = math.min(target, state.penaltySpeed) end
	state.speed = math.min(target, state.speed + Config.RECOVERY_PER_SEC * math.clamp(dt, 0, 0.1))
	return state.speed
end


function Rules.ObserveFacing(state: State, facing: Vector3, now: number)
 local flat=Vector3.new(facing.X,0,facing.Z)
 if flat.Magnitude<0.1 then return end
 flat=flat.Unit
 if state.facing.Magnitude>0 and now-state.facingAt<=Actions.MouseTurnWindowSec then
  local angle=math.deg(math.acos(math.clamp(state.facing:Dot(flat),-1,1)))
  if angle>=Actions.MouseTurnAngleDeg then
   state.reverseSeq+=1;state.penaltyUntil=now+Config.TURN_HOLD_SEC
   state.penaltySpeed=Config.REVERSE_SPEED;state.speed=math.min(state.speed,Config.REVERSE_SPEED)
   state.facing=flat;state.facingAt=now
  end
 else state.facing=flat;state.facingAt=now end
end

return table.freeze(Rules)

--[========[
Previous sprint rules retained.
--!strict
-- Pure sprint speed state: cardinal/diagonal input and brief turn deceleration.
local Config = require(script.Parent.configs.SprintConfigs)
local Rules = {}

export type State = {
	forward: number, lateral: number, direction: Vector3, turnOrigin: Vector3,
	lastMovingAt: number, penaltyUntil: number, penaltySpeed: number, speed: number,
}

function Rules.IsAxis(value: any): boolean
	return value == -1 or value == 0 or value == 1
end

function Rules.BaseSpeed(forward: number, lateral: number): number
	return if forward ~= 0 and lateral ~= 0 then Config.DIAGONAL_SPEED else Config.SPRINT_SPEED
end

function Rules.New(): State
	return {forward = 0, lateral = 0, direction = Vector3.zero, turnOrigin = Vector3.zero,
		lastMovingAt = -math.huge, penaltyUntil = 0, penaltySpeed = Config.SPRINT_SPEED,
		speed = Config.SPRINT_SPEED}
end

function Rules.SetDirection(state: State, forward: number, lateral: number, now: number)
	local direction = Vector3.new(lateral, 0, -forward)
	if direction.Magnitude == 0 then return end
	direction = direction.Unit
	local recent = now - state.lastMovingAt <= Config.TURN_MEMORY_SEC
	if not recent then
		state.penaltyUntil, state.penaltySpeed = 0, Config.SPRINT_SPEED
		state.turnOrigin = Vector3.zero
		state.speed = Rules.BaseSpeed(forward, lateral)
	elseif state.direction.Magnitude > 0 then
		local angle = math.deg(math.acos(math.clamp(state.direction:Dot(direction), -1, 1)))
		local changed = angle > 0.1
		if changed and now < state.penaltyUntil and state.turnOrigin.Magnitude > 0 then
			-- SA/SD arrive as separate key events; retain the origin of this brief turn.
			angle = math.max(angle, math.deg(math.acos(math.clamp(state.turnOrigin:Dot(direction), -1, 1))))
		end
		local cap = if angle >= 134.9 then Config.REVERSE_SPEED
			elseif angle >= 44.9 then Config.DIAGONAL_SPEED else nil
		if changed and cap then
			if now >= state.penaltyUntil then state.turnOrigin = state.direction end
			-- Smaller turns cannot erase an already active reverse penalty.
			state.penaltySpeed = if now < state.penaltyUntil then math.min(cap, state.penaltySpeed) else cap
			state.penaltyUntil = now + Config.TURN_HOLD_SEC
		end
	end
	state.forward, state.lateral, state.direction = forward, lateral, direction
	state.lastMovingAt = now
	local target = Rules.BaseSpeed(forward, lateral)
	if now < state.penaltyUntil then target = math.min(target, state.penaltySpeed) end
	state.speed = math.min(state.speed, target)
end

function Rules.Advance(state: State, now: number, dt: number): number
	state.lastMovingAt = now -- A held key remains recent even without new network intents.
	local target = Rules.BaseSpeed(state.forward, state.lateral)
	if now < state.penaltyUntil then target = math.min(target, state.penaltySpeed) end
	state.speed = math.min(target, state.speed + Config.RECOVERY_PER_SEC * math.clamp(dt, 0, 0.1))
	return state.speed
end

return table.freeze(Rules)

]========]
